---
name: project-skillcapacitychart-true-capacity-fix
description: Skill Req./Cap. bar chart (page 50692) now sources its Capacity bar from real Res. Capacity Entry data, spans the full Mon-Sun week, and the old "Scenario" concept was removed as dead code
metadata:
  type: project
---

On branch `BarChart-Capca-versus-Requested` (2026-08-10), fixed the "Requested Hours vs Capacity"
bar chart on page 50692 "Requested vs Capacity Skl Dhx": the Capacity bar was wrongly sourced from
Day Planning "Assigned Hours" (via `CalcAssignedSplit` reused twice), causing it to render
near-zero on days before any Day Planning assignment existed even though real resource-calendar
capacity was nonzero that day (e.g. Monday flat 320 hrs via "Res. Capacity Entry", assignments only
starting Tuesday).

Fix, in `src/dhx/barchart/codeunit_50662_SkillCapacityAnalysisMgt.al`:
- Added `CalcCapacitySplit(PlanDate; var InternalCapacity; var ExternalCapacity)` - reads
  `"Res. Capacity Entry"` directly (SetRange Date), nets off that day's Assigned Hours from
  `GDayPlanningBuf`, floors at 0, buckets by resource `Is External`/pool flags. See
  [[resource-flowfield-date-filter-gotcha]] for why this reads the entry table directly instead of
  reusing the existing (buggy, unused) `CalcFreeCapacity` helper's calcfields approach.
- `CalcDaySegments` now returns `CapacityInternal`/`CapacityExternal` alongside the existing
  `AssignedInternal`/`AssignedExternal`. Both `BuildDayCapacityChartData` and
  `BuildDayCapacityAuditBuffer` were updated to add real "Internal"/"External" free-capacity
  series/rows (Capacity-bar-only, 0 on Requested bar) instead of duplicating the Assigned split.
- Chart period changed from Monday..Friday (5 days) to the full Monday..Sunday (7 days) per
  explicit user instruction mid-task ("we display existing data per week") - all `WeekdayIndex`
  loops now `1 to 7`, `EnsureDayPlanningBuffer` calls now span `PeriodStartDate .. PeriodStartDate + 6`.
- Removed dead "Scenario" concept entirely per explicit user instruction: page 50692's
  `CalcDefaultScenarioNo` procedure and `ScenarioRangeErr` label were unused (grepped, zero
  references) - deleted. Stale doc comments across both files referencing "ScenarioNo"/"Scenario
  field"/"filters (period, Resource No., Scenario)" were corrected. There is no scenario/what-if
  override anywhere in this chart - it always shows actual/existing data for the displayed week.

**Why:** User confirmed root cause and desired fix directly; the "Scenario" cleanup and 7-day
range were separate follow-up instructions relayed mid-task, both independently verifiable via grep
(zero live references to ScenarioNo/CalcDefaultScenarioNo anywhere in the codeunit or page before
removal).

**How to apply:** If asked to touch page 50692 or codeunit 50662 again, there is no
Scenario/ResourceNoFilter parameter on `BuildDayCapacityChartData`/`BuildDayCapacityAuditBuffer` -
they take only `PeriodStartDate`. The chart is always Monday..Sunday (7 days), not just weekdays.
Test coverage lives in `test/SkillCapacityChart.Test.Codeunit.al` (codeunit 60024) - 11 tests, all
passing as of this fix (verified via `al_run_tests`, not just compile).

**Follow-up (2026-08-10, same branch):** `BuildDayCapacityChartData` now DYNAMICALLY OMITS a
weekday's category pair (and every series' values-list entry for that day) when the day has zero
data everywhere (Assigned, free Capacity, and every active skill's requested hours all zero) - see
the new local `DayHasAnyChartData` helper and the `IncludedDay: array[7] of Boolean` gate in the
day loop. This does NOT apply to `BuildDayCapacityAuditBuffer` - that procedure still always shows
all 7 days by design (unchanged, per its own doc comment - audit trail wants 0-valued rows for
completeness). wrapper.js (`src/dhx/barchart/wrapper.js`) needed no change - `RenderChart`/
`RenderDayGroupRow` already build purely off the received `categories`/`dayLabels` arrays' actual
lengths, not a hardcoded 7/14. Test codeunit 60024 grew from 11 to 16 tests (3 new: empty days
omitted from a 7-day period, a skill-only-nonzero day still included, an all-empty period returns
empty categories/dayLabels with no error) plus the old
`GivenFullWeekPeriod_WhenBuildChartData_ThenSaturdayAndSundayBarsExist` test was REPLACED (renamed
`...ThenEmptyDaysAreOmitted`) since it asserted the now-opposite behavior. All 16 passing via
`al_run_tests` against environment `NL_Test` (tenant `a60762e1-df10-4e4b-8f44-174c51589110`, see
`.vscode/launch.json`).

**Follow-up (2026-08-10, same branch): Is-External-only rule finalized for `CalcCapacitySplit`.**
User made a deliberate, permanent decision: `CalcCapacitySplit` (the live chart's capacity-split
helper) now classifies Internal/External by `Resource."Is External"` ALONE - `"Is Pool"`/`"Is Pool
Member"` are explicitly NOT folded in, matching `CalcAssignedSplit`'s own classification. This is
an intentional divergence from the separate, dead/legacy `CalcFreeCapacity` procedure (same file,
~line 77-136, only used by `src/dhx/barchart_v1`'s old page) which still does the three-way
`Is External OR Is Pool OR Is Pool Member` and was explicitly left untouched - don't "fix" it to
match, and don't copy its OR logic into `CalcCapacitySplit` again. Line 689:
`External := Resource."Is External";` with no trailing comment. Test coverage: new test
`GivenPoolMemberResourceWithFreeCapacity_WhenBuildChartData_ThenBucketedAsInternal` (codeunit
60024) locks this in - a Pool Member resource's free capacity must land in the 'Internal' series,
not 'External'. Gotcha: table Resource's `"Is Pool"`/`"Is Pool Member"` fields have OnValidate
triggers (see `src/tableext/tableext_50603_Resource.al`) that pop an interactive
VenList.RunModal/ResList.RunModal lookup when set via `Validate()` - test helpers must always set
them via direct field assignment + `Modify()`, never `Validate()`. Codeunit 60024 now has 17 tests,
all passing (verified via `al_run_tests` against `NL_Test`); no pre-existing test needed its
expected values changed - none of them used Pool/Pool Member resources before this change.
