---
name: standarddialog-action-ok-convention
description: This app's StandardDialog pages return Action::OK on their built-in OK button, not Action::LookupOK - confirmed from page 50657's own doc'd caller pattern
metadata:
  type: project
---

`PageType = StandardDialog` pages in this codebase close with **`Action::OK`**, not
`Action::LookupOK`, when the user clicks the auto-generated OK button. Confirmed from
`src/page/page_50657_GeneratePreDaytasks.al`'s own header-comment caller pattern
(`if GenerateDlg.RunModal() = Action::OK then begin ... end;`) and its
`OnQueryClosePage(CloseAction: Action): Boolean` trigger (`if CloseAction = Action::OK
then exit(true);`) - this is the only pre-existing StandardDialog page in the app, so it
is the established precedent.

`Action::LookupOK` is instead what this app's many *List/Card page-as-lookup* patterns
return (e.g. `ResourceList.RunModal() = Action::LookupOK`, `Pg.RunModal() =
Action::LookupOK` throughout `src/page/Pag50626.SummaryView.al`,
`src/report/report_50609_ResourceSchedulerFilter.al`, etc.) - those are ordinary
List/Card pages being run modally as a lookup, not StandardDialog pages.

**Why this matters:** a naive port of the "lookup dialog" `Action::LookupOK` pattern onto
a new StandardDialog page (e.g. page 50709 "Color Picker Lookup",
[[dhtmlx-suite-colorpicker-api]]) will silently never match - the OK button always
returns `Action::OK` on a StandardDialog, so gating on `Action::LookupOK` makes the
"OK" path unreachable (looks like Cancel always wins).

**How to apply:** any future `PageType = StandardDialog` page's caller must check
`RunModal() = Action::OK`, not `Action::LookupOK`.
