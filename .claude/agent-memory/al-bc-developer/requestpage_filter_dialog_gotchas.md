---
name: report-requestpage-filter-dialog-pattern
description: AL language gotchas when converting a StandardDialog Page+Temp-table filter popup to a Report(ProcessingOnly+UseRequestPage)-only picker, plus the confirmed real pattern for multi-select filter lookups on Text-bound requestpage fields (Page variable + SetSelectionFilter + Codeunit 46, NOT bare PAGE.RunModal(0, Record)).
metadata:
  type: feedback
---

When replacing a `Page (StandardDialog) + Temporary table` filter-picker pair with a `Report` that has no real dataset (dummy dataitem + `CurrReport.Break()`, `ProcessingOnly = true`, `UseRequestPage = true`) so the RequestPage is the only UI ever shown — two things differ from the page/table pattern and are NOT obvious until you actually compile:

1. **`Report.RunModal()` returns void (type `None`), unlike `Page.RunModal()` which returns `Action`.**
   `if SomeReport.RunModal() = Action::OK then` fails with `AL0175 Operator '=' cannot be applied to operands of type 'None' and 'Action'`. There is no return-value way to detect OK vs Cancel on a report. Fix: give the report a `Confirmed: Boolean` global, set it from the requestpage's own `trigger OnQueryClosePage(CloseAction: Action): Boolean` (`Confirmed := CloseAction = Action::OK;`), and expose a public `procedure IsConfirmed(): Boolean`. Caller pattern becomes:
   ```al
   FilterDlg.SetFilter(...);
   FilterDlg.RunModal();
   if FilterDlg.IsConfirmed() then begin
       FilterDlg.GetFilter(...);
       ...
   end;
   ```

2. **Dynamic `TableRelation ... where(OtherField = field(X))` does not resolve when the field is bound to a plain report/page global variable instead of a Rec/table field.**
   The old temp-table field could do `TableRelation = "Job Task"."Job Task No." where("Job No." = field("Job No."))` because both fields lived on the same Rec. Moving the picker fields to bare requestpage globals (`field(fldJobTaskNo; JobTaskNoFilter)`, no `SourceTable`) and writing the same dynamic where-clause — whether referencing the sibling by variable name (`field(JobNoFilter)`) or by control name (`field(fldJobNo)`) — both fail with `AL0186 Reference 'X' in application object '' does not exist`. `field()` in a TableRelation where-clause only binds to sibling fields of a Rec-backed table, never to requestpage/report globals. Fix: drop the dynamic where-clause (plain `TableRelation = "Job Task"."Job Task No."`) and accept an unscoped lookup as a tradeoff — do NOT try to reintroduce OnLookup-based manual scoping unless actually needed, see point 3.

3. **RETRACTED (again) — the "`PAGE.RunModal(0, Record)` then hand the record to Codeunit 46" pattern previously recorded here was ALSO wrong, and this time it was confirmed wrong by the user in live testing, not just by reasoning.** It compiles cleanly (Codeunit 46 "SelectionFilterManagement" really does expose `GetSelectionFilterForJob`/`GetSelectionFilterForJobTask`/`GetSelectionFilterForResource`, all confirmed via `al_symbolsearch`), but at runtime it produced garbage (e.g. multi-selecting Job "10000" + "DJB0005" and clicking OK yielded the field text `"..PR00030"` — not a valid filter). **Root cause: `PAGE.RunModal(0, Record)` does NOT write a filter reflecting the user's Ctrl/Shift-marked rows onto the passed record variable.** It only gives you back whatever single record/filter state the record var already had. The marked-selection filter only gets attached to a record variable via a dedicated `SetSelectionFilter(var Record)` call — confirmed via every actual multi-select site already shipping in this codebase (`pageext_50608_JobPlanningLines.al`, `pageext_50622_JobLedgerEntries.al`, `page_50617/50607/50632_JobTaskList*.al`, `Pag50640/Pag50601/Pag50609`'s own `GetSelectionFilter()` helper procedures, `pageext_50603_ResourceList.al`'s `GetSelectionFilter()` bare call feeding `ResScheduler.SetResourceFilter(...)`), which ALL call `CurrPage.SetSelectionFilter(RecVar)` before doing anything with the marked set.
   **Correct, verified-compiling pattern** for wiring a multi-select `OnLookup` on a Text-bound (non-Rec) requestpage/report field, when you're OUTSIDE the target list page (so `CurrPage` isn't available): declare an explicit `Page "Xxx List"` variable, seed it with `SetTableView(RecordVar)`, call `.LookupMode(true)`, then `.RunModal()`; on `Action::LookupOK`, call `.SetSelectionFilter(RecordVar)` **on that same page variable** (this is the part the previous pass was missing) to get the marked-rows filter written onto the record, THEN hand that record to the Codeunit 46 `GetSelectionFilterForXxx` wrapper to compact it into ranges/OR-lists:
   ```al
   trigger OnLookup(var Text: Text): Boolean
   var
       Job: Record Job;
       JobList: Page "Job List";
       SelectionFilterManagement: Codeunit SelectionFilterManagement;
   begin
       Job.SetFilter("No.", JobNoFilter);
       JobList.SetTableView(Job);
       JobList.LookupMode(true);
       if JobList.RunModal() = Action::LookupOK then begin
           JobList.SetSelectionFilter(Job);
           Text := SelectionFilterManagement.GetSelectionFilterForJob(Job);
           exit(true);
       end;
       exit(false);
   end;
   ```
   `SetSelectionFilter` is a genuine `Page`-type method (not a `CurrPage`-only keyword) — calling it on an external page variable after `RunModal()` returns compiled cleanly (`al_build`, zero errors/warnings) and matches the documented "run a list page as a picker from code, then pull results off the same variable" idiom (same family as `Page.GetRecord()`). Note this mechanism is keyed to the table's PRIMARY KEY field the `GetSelectionFilterForXxx` wrapper targets — for a field that is NOT the primary key (e.g. Resource "Name"), there is no proven-working way to reuse this, and the safest choice is to drop the multi-select `OnLookup`/`TableRelation` entirely for that field rather than guess again.

Applied in report 50608 "Task Scheduler Filter" and report 50609 "Resource Scheduler Filter" (`src/report/report_50608_TaskSchedulerFilter.al`, `src/report/report_50609_ResourceSchedulerFilter.al`), replacing the deleted page 50681/50682 + table 50622/50623 pairs. See also [[al_compile_stale_cache_quirk]] for the separate al_compile-vs-al_build trust issue encountered in the same kind of session.

4. **When a table has no dedicated `Codeunit 46 "SelectionFilterManagement".GetSelectionFilterForXxx` wrapper (confirmed via `al_symbolsearch` — as of this pass there are ~44, keyed to specific tables like Resource/Job/Customer/Item etc., none for "Skill Code"), the codeunit's generic RecordRef-based overload is a safe, proven fallback:**
   `procedure GetSelectionFilter(var TempRecRef: RecordRef; SelectionFieldID: Integer): Text` — same underlying doc text as the dedicated wrappers ("Get a filter for the selected field from a provided record. Ranges will be used inside the filter where possible"). Used for the Skill field added to report 50609: after `SkillCodeList.SetSelectionFilter(SkillCode)` (same as the dedicated-wrapper pattern above), do `RecRef.GetTable(SkillCode); Text := SelectionFilterManagement.GetSelectionFilter(RecRef, SkillCode.FieldNo(Code));`. Confirmed compiling via `al_build`. Only reach for this generic overload when the field being filtered is the table's actual primary key (matches the same constraint the dedicated wrappers have) — for Skill Code that's the single-field PK `Code`.
   Also confirmed: this project has TWO pages named "Skill Codes" — the real base-app list page (`Microsoft.Service.Setup` namespace, plain non-temporary `SourceTable = "Skill Code"`, safe to use as a `SetTableView`/`LookupMode` picker) and this project's own `Page 50646 "Opti Skill Codes"` (`src/page/Pag50646.OptiSkillCodes.al`), which has `SourceTableTemporary = true` and only ever populates via its own `SetTempSkill()` procedure — running that one standalone via `SetTableView`/`LookupMode` against a real (non-temp) `Record "Skill Code"` would open an empty list. Always use the base-app page for this pattern, not the project's temp-table variant, unless you first call its `SetTempSkill`.
   Also: table "Resource Skill" keys the resource by field **`No.`** (Code[20]), not "Resource No." — don't guess field names on tables you haven't symbol-searched; `Type` is `Enum "Resource Skill Type"::Resource` for resource-type skill assignments, `"Skill Code"` (Code[10]) is the skill being checked.
