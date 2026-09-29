---
name: project_cpo_dashboard_weekperiod_nav_2026-09-29
description: Page 50724 dashboard tile switched from free-text Days-to-show to a week-period nav bar (2026-09-29)
metadata:
  type: project
---

Capacity Planning Dashboard tile (page 50724) replaced its old free-text "Days to show" input with
a week-period bar (Previous/Today/Next/Refresh buttons + a label) - JS side done separately, this
covers the AL side.

- Controladdin `DHXCapacityPlanningDashboardAddin`
  (src/dhx/capacity_planning_dashboard/DHXCapacityPlanningDashboardAddin.ControlAddin.al): added
  `procedure SetPeriodLabel(PeriodLabelTxt: Text)` and parameterless events
  `OnRefreshClicked/OnPreviousClicked/OnTodayClicked/OnNextClicked`. Removed
  `OnDaysToShowChanged(NumberOfDays: Integer)` (that event still exists, unrelated, on the sibling
  controladdin `DHXCapacityPlanningOverviewAddin` used by page 50722 - page 50722 was NOT touched).
- Page 50724: `DaysToShow`/`DefaultDaysToShow`/`EnsureDaysToShow` replaced by a single
  `PeriodStartDate: Date` var (the week's Monday), set via `CalcDate('<-CW>', Today())` on
  ControlReady and OnTodayClicked, +/-7 on OnPreviousClicked/OnNextClicked. `RefreshData` now calls
  `CPO_BuildDashboardDataJson(PeriodStartDate, 7)` and then
  `CurrPage.DhxCpoDash.SetPeriodLabel(VisualDefaultSettings.FormatWeekPeriodText(PeriodStartDate))`
  - passed directly, no extra label wrapper (mirrors src/dhx/barchart_weekly's own page_50692/50708
  usage, not the `WeeklyPeriodLabelLbl`-wrapped usage seen in page_50695/barchart_daily/page_50705).
- Codeunit 50604 `CPO_BuildDashboardDataJson` signature changed from `(NumberOfDays: Integer)` to
  `(StartDate: Date; NumberOfDays: Integer)` - `StartDate` no longer implicitly `Today()`. Page
  50724 is confirmed the only .al caller (grepped repo-wide before changing it).
- Note: `CalcDate('<-CW>', Today())` was used here per explicit instruction, even though
  src/dhx/barchart_weekly's own `CalcMonday` helper deliberately avoids `<-CW>` (computes Monday via
  `Date2DWY` instead, to not depend on company/regional week-start setup) - if this tile's week
  start ever looks wrong on a non-Monday-start locale, that regional dependency is the likely cause;
  consider switching to the `Date2DWY`-based approach for consistency.
- Compiled clean (al_compile, onlyErrors) after a `force=true` symbol re-download - the first
  compile attempt threw phantom "ControlAddIn ... is missing" / "UserControl does not contain a
  definition" errors on files that were syntactically fine; this matches the known
  [[al_compile_stale_cache_quirk]] pattern. Not published/browser-verified this session (explicitly
  out of scope).
