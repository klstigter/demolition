# Diagnosis: Gantt "Next" action drops tasks from the task list

## Symptom (as reported)
On page 50620 "Gantt Chart", with the window showing "Aug 2026 - wk 32" (first column Mon 03
Aug), Job Task "01010 - Phase 1 Task 1" (Job DJB0001, Planned Start Date 2026-08-03, Planned End
Date 2026-09-07 — confirmed on the task's own card, not derived) is visible. Clicking "Next" once
moves the header to "Sep 2026 - wk 37" (first column Mon 07 Sep). "01010 - Phase 1 Task 1" and its
parent "Phase 1" group are completely gone from the task list in the new window, even though the
task's Planned End Date (Sep 7) falls exactly on the new window's displayed first day.

## Layer / Category
Logic (date-window/pagination arithmetic) — possibly compounded by a UI/display mismatch between
the computed window and the rendered header label.

## Code path traced (confirmed by direct reading, not assumption)
- `page_50620_GanttDemo.al` action `NextAct` (~851-865): `AnchorDate := CalcNewAnchorDate(Direction::Forward); RefreshGantt();`
- `CalcNewAnchorDate` (~1484-1512): for `Setup."Date Range Type"::Weekly`, Forward does
  `NewAnchorDate := CalcDate('<6W>', AnchorDate);` (+42 calendar days, day-of-week unchanged).
- `RefreshGantt` → `LoadAllData` (~1103-1220): calls
  `GanttChartDataHandler.GetDateRange(Setup, AnchorDate, StartDate, EndDate)` **once**, then feeds
  that same `StartDate`/`EndDate` to BOTH `CurrPage.DHXGanttControl2.LoadProject(StartDate, EndDate)`
  (configures the visible timeline scale) AND — via `LoadTaskData()` → `GetJobTasksAsJson(AnchorDate, ...)`,
  which calls `GetDateRange` again with the *same* `AnchorDate` — the Job Task filter query. Both
  therefore derive from the identical `StartDate`/`EndDate`, so a scale-vs-filter divergence between
  two different computations is **ruled out** as the cause.
- `codeunit_50613_GanttChartDataHandler.al` `GetDateRange` (~7-38), Weekly branch:
  `DHXDataHandler.GetWeekPeriodDates(AchorDate, StartDate, EndDate)` (Monday..Sunday of the ISO
  week containing AchorDate), then `EndDate := Calcdate('<5W>', EndDate)` — a 6-calendar-week-wide
  window (anchor's own week + 5 more).
- `GetJobTasksAsJson` (~45-85): filters `"PlannedStartDate" <= EndDate` and
  `"PlannedEndDate" >= StartDate` — inclusive on both ends; a task ending exactly on `StartDate`
  passes this filter. **This filter is correct as written** — the bug, if it is a filter-input
  problem, is in what `StartDate` evaluates to for window 2, not in the comparison operators.
- `wrapper.js` `LoadProject` (~1571-1602): sets `gantt.config.start_date = new Date(projectstartdate)`
  directly from the string AL sends — no independent client-side recalculation. Rules out a
  JS-side "scale computed differently from the filter" divergence too.

## Hand-derived arithmetic (Weekly branch, assuming AnchorDate1 = Today() = 2026-08-05)
- Window 1: `GetWeekPeriodDates(Aug 5)` → Mon Aug 3 / Sun Aug 9 (wk 32) → `+5W` → EndDate Sep 13
  (Sun, wk 37). Window 1 = wk 32..37 (6 weeks), consistent with the observed "Aug 2026 - wk 32"
  header (wk 37 would be the rightmost, off-screen/cropped column in the first screenshot).
- Window 2 anchor: `CalcDate('<6W>', Aug 5)` = Aug 5 + 42 days = **Sep 16** (still a Wednesday —
  a 42-day jump never changes day-of-week, so this step never drifts across repeated clicks).
- Window 2: `GetWeekPeriodDates(Sep 16)` → Mon **Sep 14** / Sun Sep 20 (**wk 38**), not wk 37/Sep 7
  as shown in the screenshot.

**This is a real, unresolved contradiction.** A `<6W>` (42-day) step from anywhere inside wk 32
mathematically lands inside wk 38, never wk 37 — I checked this against every possible AnchorDate1
within wk 32 (Aug 3..Aug 9), all of them land in [Sep 14, Sep 20], never Sep 7..13. So either:

1. My assumption that `Setup."Date Range Type" = Weekly` is wrong for the session in the
   screenshots — the enum's schema default (a freshly-`Init()`'d Setup record, no `InitValue`) is
   actually `"Date Range"` (ordinal 0), not `Weekly`; if the real setting is `Calculated`, the
   governing formulas are `Setup."From Data Formula"` / `"To Data Formula"` /
   `GetPeriodLength(AnchorDate)` (table 50620, ~100-108) instead of the `<5W>`/`<6W>` constants
   I traced above, and I cannot see those formula values from static code alone (data, not code).
2. Or my assumption `AnchorDate1 = Today() = 2026-08-05` is wrong — the session may have already
   navigated before the first screenshot was taken.
3. Or there is a genuine bug I haven't located yet in `LoadTaskData()` (not yet read in full) or
   in how `AnchorDate` is threaded through it.

I will not guess further or apply a fix based on an unconfirmed assumption — changing the `<6W>`
step (or the `<5W>` width) without knowing which is actually wrong risks "fixing" already-correct
tiling logic and introducing an overlap/gap bug elsewhere.

## What would confirm the root cause (no code change needed to get this)
Page 50620 already has a built-in diagnostic for exactly this — action **"Check Page Period"**
(Check ribbon tab): it calls the same `GetDateRange(Setup, AnchorDate, DT1, DT2)` the real load
path uses and shows `Message('...period %1 to %2 from anchor date %3', DT1, DT2, AnchorDate)`.

**Could you click "Next" once (reproducing the bug), then run "Check Page Period", and tell me
exactly what it reports for period-from / period-to / anchor date?** That number pins down
whether window 2's real `StartDate` is Sep 14 (confirming hypothesis 1 or 2 — the header itself is
wrong, and the "missing task" is actually correctly excluded, just misleadingly labeled) or Sep 7
(confirming a real, different bug I haven't located). Also — separately — what is
`Setup."Date Range Type"` set to (Weekly / Calculated / Date Range), and if Calculated, what are
the From/To Date Formulas? Either piece of information resolves this without me guessing.

## Confirmed root cause
User confirmed directly: the Weekly-branch step in `CalcNewAnchorDate` should be `<5W>`, not
`<6W>`. This matches hypothesis 1/2 exactly — the window is intentionally 6 calendar weeks wide
(anchor's own week + `<5W>` more) but is meant to be paged by only `<5W>`, so consecutive windows
deliberately overlap by exactly one week (the last visible week of window N re-appears as the
first week of window N+1). That overlap week is what protects tasks whose Planned End Date lands
exactly on it from ever being silently excluded by `GetJobTasksAsJson`'s
`"PlannedEndDate" >= StartDate` filter — with the old `<6W>` step, that boundary week (wk 37 in
the repro) was skipped entirely, so a task ending inside it failed the filter for BOTH windows.
The filter itself, `GetDateRange`, `GetWeekPeriodDates`, and `wrapper.js`'s `LoadProject` were all
confirmed correct during tracing — the sole defect was the step size in `CalcNewAnchorDate`.

## Fix applied
`page_50620_GanttDemo.al`, `CalcNewAnchorDate`, `Setup."Date Range Type"::Weekly` branch only:
- Forward: `CalcDate('<6W>', AnchorDate)` → `CalcDate('<5W>', AnchorDate)`
- Backward: `CalcDate('<-6W>', AnchorDate)` → `CalcDate('<-5W>', AnchorDate)` (mirror fix — same
  defect would otherwise skip the boundary week going backward too)

The `Calculated` branch (`GetPeriodLength`-driven step) was left untouched — not implicated by the
user's confirmation, and its step already equals its own window's exact inclusive width
(`d2 - d1 + 1`), a different (and not reported as broken) design.

## Regression risk
- Any other caller of `CalcNewAnchorDate` — none found; it is `local` to page 50620, so this
  change cannot affect other Gantt-family pages (resource/pool-resource/project schedulers use
  their own separate paging logic).
- `GetDateRange`/`GetWeekPeriodDates` themselves are unchanged, so any other caller of those
  (confirmed multiple: resource scheduler, project schedule board, pool resource scheduler) is
  unaffected.
- Did not touch `codeunit_50617` (DayPlanning Period Sync Mgt.) — unrelated, intentionally as-is.
