---
name: project_cpo_work_order_table_removal_migration
description: Capacity Planning Overview (page 50722) — 2026-09-10 migration off the deleted table 50608 "Work Order" onto Job Task's composite key (Job No.+Job Task No.); JSON contract kept the "workOrderNo" field name but now carries a pipe-joined composite. Read alongside [[project_cpo_cross_wo_scope_fix]] before touching this add-in again.
metadata:
  type: project
---

**Context:** table 50608 "Work Order" and its API page 50697 were deleted from the extension -
every field Work Order used to carry (Order Intake No., Deadline Date, Placeholder Date, Closed*,
PlannedStartDate/PlannedEndDate, etc.) was already transferred onto `tableext_50605_JobTask.al`
("Job Task ext"). Job Task's primary key is COMPOSITE ("Job No." + "Job Task No."), unlike Work
Order's old single-field "Work Order No." key. Table 50610 "Day Planning" also has no "Work Order
No." field any more - it only carries "Job No." + "Job Task No." to identify its parent (it does
still have an unrelated, still-valid "Order Intake No." field, field 55 - not to be confused with
the deleted "Work Order No." field; do not conflate the two).

This left the CPO_ region of `codeunit_50604_DHXDataHandler.al` (page 50722 "Capacity Planning
Overview" and its background-task companion `codeunit_50722_CPOBGOtherWorkOrderData.al`)
half-migrated and non-compiling: `CPO_BuildPlanningDataJson` declared `JobTask: Record "Job Task"`
but called `.Get(WorkOrderNo)` (wrong arity) and read the non-existent `JobTask."Work Order No."`;
`CPO_BuildPlanningDataJson_Paged`/`CPO_BuildOtherWorkOrderLinesJson_ForKeys` still declared
`WorkOrder: Record "Work Order"` outright.

**The hard part:** a single `WorkOrderNo: Code[20]` can no longer identify "which one work
order/job task is inspected" once the key is composite. Fixed by threading `JobNo`/`JobTaskNo` as
a PAIR everywhere that identifier used to flow:

- `page_50722_CapacityPlanningOverview.al`: `GWorkOrderNo: Code[20]` global -> `GJobNo`/`GJobTaskNo`
  pair. Public entry point `SetWorkOrderNo(pWorkOrderNo: Code[20])` renamed to
  `SetJobTask(pJobNo: Code[20]; pJobTaskNo: Code[20])`. Every read site updated: `RefreshData`'s
  blank-guard, `PersistReschedule`'s blank-guard, `EnqueueOtherWorkOrderDataBackgroundTask`'s
  `TaskParameters`.
  **ENTRY-POINT GAP (still true after this migration, flagging for whoever touches this next):**
  `SetJobTask` (formerly `SetWorkOrderNo`) has NO live caller anywhere in the codebase. Its only
  caller was `src/page/Pag50662.WorkorderCard.al.allowtoremove.txt`, already marked for removal.
  Nobody currently opens page 50722 with a resolved Job/Task - it was only fixed for
  signature/correctness, not wired to any new UI (explicitly out of scope when this note was
  written - do not assume it's dead code to delete, and do not invent a new caller without asking).
- `codeunit_50722_CPOBGOtherWorkOrderData.al`'s `OnRun`: `TaskParameters` dictionary's single
  `'WorkOrderNo'` text key split into `'JobNo'`/`'JobTaskNo'` keys. `GetParam`'s own
  missing-key-returns-'' fallback is load-bearing: page 50724 "Capacity Planning Dashboard" reuses
  this SAME background codeunit (see [[project_cpo_cross_wo_scope_fix]]-adjacent doc comment on
  `CPO_BuildDashboardDataJson_Paged`) and its own enqueue call was deliberately left UNTOUCHED
  (still adds a now-unread `'WorkOrderNo'` key, out of this task's scope since
  `capacity_planning_dashboard` wasn't supposed to be touched beyond forced compile fixes) - it
  still works because `GetParam('JobNo')`/`GetParam('JobTaskNo')` both silently resolve to `''`
  when those keys are simply absent, which is exactly the "nothing excluded, whole company" blank
  semantics that tile always wanted. If you ever clean up page 50724, swap that stale key for
  clarity (not required for correctness).
- `codeunit_50604_DHXDataHandler.al` CPO_ region signatures, all changed from a single
  `WorkOrderNo: Code[20]` to a `JobNo: Code[20]; JobTaskNo: Code[20]` pair (matching the naming/
  order `CPO_ScanOtherWorkOrderGroups` already used before this migration):
  - `CPO_BuildPlanningDataJson(JobNo, JobTaskNo, NumberOfDays)` - was genuinely broken pre-fix (see
    above), not just half-done cosmetically. `Job` lookup for `project.description` untouched.
  - `CPO_BuildPlanningDataJson_Paged(JobNo, JobTaskNo, NumberOfDays, MaxOtherLines, var
    RemainingGroupKeys)`.
  - `CPO_BuildOtherWorkOrderLinesJson_ForKeys(JobNo, JobTaskNo, StartDate, EndDate,
    RemainingGroupKeysJson)` - USED to re-derive JobNo/JobTaskNo via `WorkOrder.Get(WorkOrderNo)`;
    now takes them straight from the caller (which already has them from its own TaskParameters) -
    no lookup needed any more, simpler than before.
  - `CPO_BuildOtherWorkOrderLinesForGroups(JobNo, JobTaskNo, StartDate, EndDate, var
    WantedGroupKeys)` - dropped the `WorkOrderNo` param it used to carry ALONGSIDE its own
    pre-existing `JobNo`/`JobTaskNo` params (it already had all three; the WorkOrderNo one was
    redundant once `CPO_BuildDayPlanningLineObj` stopped needing it, see below).
  - `CPO_BuildDayPlanningLineObj(var DayPlanning, InspectedJobNo, InspectedJobTaskNo)` - dropped
    its `InspectedWorkOrderNo` param entirely (it already had `InspectedJobNo`/`InspectedJobTaskNo`
    alongside it pre-migration). The `'workOrderNo'` JSON tag is now built DIRECTLY from
    `DayPlanning."Job No." + '|' + DayPlanning."Job Task No."` - no more "normalize to the inspected
    WO's real No. when Job/Task matches, else use a raw (sometimes-blank) field" override logic,
    because Day Planning's Job No./Job Task No. are its own real, ALWAYS-populated identifying
    fields (Pass 1/Pass 3 already filter by them directly) - the old override existed only to work
    around the old "Work Order No."/"Order Intake No." field sometimes being blank on a genuine
    line, which structurally cannot happen to Job No./Job Task No. `InspectedJobNo`/
    `InspectedJobTaskNo` are kept as parameters (call-site symmetry with Pass 1/Pass 3's own
    scoping above) but are no longer read inside this procedure's body - intentional, not an
    oversight.
  - `CPO_ScanOtherWorkOrderGroups` and `CPO_BuildDashboardDataJson_Paged` signatures were NOT
    touched (per explicit scope) - the dashboard variant still passes blank `''`/`''` for
    job/task, and its call into `CPO_BuildOtherWorkOrderLinesForGroups` only needed one blank arg
    dropped (3 blanks -> 2) to match that function's new 2-param identity pair, not a behavior
    change.
  - The old "if JobNo blank, fall back to filtering Day Planning by 'Order Intake No.' =
    WorkOrderNo" branch (both in `CPO_BuildPlanningDataJson` and `..._Paged`) was REMOVED, not
    ported - it was already unreachable in practice (only ran inside `if JobTaskFound`, which now
    structurally guarantees JobNo is non-blank since it's one of the two values that resolved the
    `JobTask.Get(JobNo, JobTaskNo)` call), and there is no longer any other single identifier to
    fall back to even if it were reachable.

**JSON-CONTRACT DECISION for `capacityPlanningOverview.js`: chose option (a), NOT (b).** Kept the
JSON field NAMED `workOrderNo` (and `workOrder.no` on the header object) - did NOT rename it or
touch any of its `===`/`!==` comparison call sites (`dailyCapacityRequestData`,
`workOrderAssignmentState`, `skillDaySummary`/`taskDaySummary`/`sequenceDayLines` - all still
compare `line.workOrderNo` against `this.db.workOrder.no` unchanged). Instead, AL now populates
that SAME field with a pipe-joined `"JobNo|JobTaskNo"` composite string, on both the header object
and every `dayPlanningLines[]` line - the same idiom this codeunit already used for
`GroupKeyTxt`/`SeqKeyTxt` (and the JS file's own `aggregateRequests()`/tree-summary keys). Because
plain string equality doesn't care whether the string is a real document number or a composite key,
every filtering behavior [[project_cpo_cross_wo_scope_fix]] describes (Section 1/2/3's "Requested"
bar scoped to the inspected item, Section 4 scoped to "every other one") is untouched, byte-for-byte
identical to before this migration - only the AL-side value construction changed, not the JS-side
matching logic. Rejected (b) (rename the field/JS variable throughout) as unnecessary diff/risk for
zero behavioral gain.

**One real, deliberate JS change was still needed - purely cosmetic, not structural:** the title
bar (`applyPlanningData`, `'Workorder ' + this.db.workOrder.no + ...'`) is the ONE place
`workOrder.no` is user-VISIBLE rather than just compared. Left as the raw composite, a user would
see `"Workorder DWO0008|0001-0010 | <description>"` - the pipe reads as a rendering glitch. Fixed
by `.replace('|', ' / ')` at that ONE render call site only - does not touch the stored value used
by any comparison elsewhere in the file.

**Compile status:** `al_compile` (onlyErrors) confirms zero errors in all three in-scope files
(`codeunit_50604_DHXDataHandler.al`, `page_50722_CapacityPlanningOverview.al`,
`codeunit_50722_CPOBGOtherWorkOrderData.al`). Six pre-existing errors remain elsewhere in the repo
(`page_50655_OrderIntakeCard.al`'s "Work Order Sub" page reference, `Pag50639.DayPlanningPattern.al`
reading `JobTask."Work Order No."`/`"Planned Start Date"`/`"Planned End Date"` - the space'd/old
field names, not the ext's no-space `PlannedStartDate`/`PlannedEndDate`) - confirmed present before
AND after this session's edits, same root cause (the Work Order table removal) but a DIFFERENT
feature area, explicitly out of scope for this task. Not published/Playwright-verified (user
standing preference - save tokens, verify manually; see feedback_skip_publish_verification_on_request).

**If asked to touch this add-in again:** read [[project_cpo_cross_wo_scope_fix]] FIRST for the
Section 1/2/3/4 scoping model (still 100% accurate - only the identity TYPE changed, not which
lines belong to which section), then this note for the composite-key mechanics. Do not reintroduce
a single `WorkOrderNo`-shaped identifier anywhere in this add-in's own AL or JS - Job Task's key is
composite, permanently, and every place that used to carry one Code[20] now needs the JobNo/
JobTaskNo pair kept together.
