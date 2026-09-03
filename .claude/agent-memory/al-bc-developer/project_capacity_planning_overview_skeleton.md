---
name: project_capacity_planning_overview_skeleton
description: Capacity Planning Overview add-in — steps 1-5 done and live-verified (skeleton, section-2 Scheduler timeline, shortage/coverage stats header w/ team-scoped (not company-wide) availability engine + 2-row labeled grid, capacity-vs-requested daily bars); full plan and remaining steps
metadata:
  type: project
---

Step 1 of the Capacity Planning Overview build (full multi-step plan at
`C:\Users\Ahmad\.claude\plans\composed-crunching-valiant.md`) is done: AL skeleton wired
end-to-end, controladdin `DHXCapacityPlanningOverviewAddin`, page 50722, Workorder Card action.
See git history for that step's details (superseded below).

**Update 2026-09-02: step 3 (codeunit 50604 CPO_* region) + part of step 2 (section 2 real
rendering) done and live-verified.**

**Objects/files changed:**
- `src\codeunit\codeunit_50604_DHXDataHandler.al` — new `CPO_*` region appended at the end of
  the file (after `ReqAssign_RejectSequence`, before the closing `}`), comment-banner style
  matching the file's existing `ReqAssign_`/`SkillResScheduler_` convention (this file does NOT
  use actual `#region`/`#endregion` pragmas anywhere, just banner comments).
  - `procedure CPO_BuildPlanningDataJson(WorkOrderNo: Code[20]; AnchorDate: Date): Text` — public
    entry point. Builds `workOrder` {no, description, plannedStartDate, plannedEndDate},
    `workdays` (every calendar day, weekends included, from Planned Start Date-3 to Planned End
    Date+3 inclusive — falls back to a small AnchorDate±window if either planned date is 0D or
    the Work Order doesn't resolve), and `woLines` (one object per Day Planning row with
    `"Work Order No." = WorkOrderNo`, via `SetLoadFields` + `SetRange`).
  - `local procedure CPO_BuildWoLineObj` — sequenceKey mirrors ReqAssign's exact pipe-joined
    shape (`"Job No.|Job Task No.|Skill|Sequence No."`).
  - `local procedure CPO_BuildDateRangeArray` — deliberately NOT
    `ReqAssign_BuildWorkdayIndexMap` (which skips weekends) — a new every-calendar-day builder,
    reusing the existing (local) `ReqAssign_FormatIsoDate` helper for ISO formatting.
- `src\dhx\capacity_planning_overview\page_50722_CapacityPlanningOverview.al` — added
  `WOAnchorDate: Date` global + `local procedure EnsureAnchorDate()` (re-Gets the Work Order,
  sets `WOAnchorDate := "Planned Start Date"`; simply re-fetches every call rather than a
  one-shot guard — a single Get() is cheap). Called from both `ControlReady` and
  `ResetPositionAct` before `RefreshData()`. `RefreshData()` now calls
  `DHXDataHandler.CPO_BuildPlanningDataJson(GWorkOrderNo, WOAnchorDate)` (local var
  `DHXDataHandler: Codeunit "DHX Data Handler"` declared inside the procedure, matching page
  50710's calling convention) instead of the old hand-written placeholder JSON string.
- `src\dhx\capacity_planning_overview\capacityPlanningOverview.js` — real
  `applyPlanningData`/`renderScheduler`: builds a plain DHTMLX Scheduler day-granularity
  timeline (global `scheduler` singleton, same convention as `projectschedule/wrapper.js` —
  NOT `Scheduler.getSchedulerInstance()`, which is only needed when >1 concurrent instance is
  required, e.g. `request_assignment`'s two simultaneous panels). One section per distinct
  `sequenceKey` in `woLines`, one read-only bar per Day Planning line labelled
  `"<assignedHours>/<requestedHours>h"`. Read-only (`drag_create/move/resize=false`,
  `details_on_dblclick/create=false`). Guards DHTMLX's "duplicate view" error via the same
  `deleteView('timeline') + delete matrix.timeline` dance `projectschedule/wrapper.js`'s `Init()`
  uses, since `ControlReady` and `ResetPositionAct` can both re-render the same live scheduler
  instance in one page session — confirmed live this pattern works correctly on repeat
  (Reset Position re-render produced identical correct output, no new console errors).
- `src\dhx\capacity_planning_overview\style.css` — `.cpo-scheduler-container` (400px height,
  flex:1, min-height 400px) added alongside the existing `.cpo-top-title`/`#cpo-root`.

**Two real DHTMLX bugs found and fixed live (both easy to hit again in future DHTMLX Scheduler
work in this repo — worth remembering):**
1. `scheduler.createTimelineView(...)` throws `"scheduler.createTimelineView is not
   implemented"` unless `scheduler.plugins({ timeline: true })` is called first. Both
   `projectschedule` and `request_assignment` already do this (the latter via
   `sch.plugins({timeline:true, treetimeline:true})`) — this add-in's first cut initially missed
   it. Fix: call `scheduler.plugins({ timeline: true })` as the first line of the render function,
   before any `createTimelineView` call; safe to call again on every re-render (no-op if already
   loaded).
2. Omitting `render: 'bar'` in `createTimelineView`'s config makes DHTMLX default to its
   "matrix" mode — cells show a bare numeric EVENT COUNT (e.g. "1") instead of the actual event
   bar with its `text`. Confirmed live: without `render: 'bar'`, three real "0/8h" events all
   rendered as three cells just showing "1". Fix: explicitly set `render: 'bar'` for any
   plain (non-tree) bar-per-cell timeline.

**Live verification (2026-09-02, `NL_Copy20240710`, company "CRONUS NL"):** Work Order
**DWO0008** ("Snag List Resolution") was picked because it has 3 real Day Planning lines
(job 10000/task 1080, skill ELEKTR, 8h/day on 2026-09-08/09/10, all `assignedHours=0`,
`planStatus="In Request"`) — richer than most other seeded WOs in this company, which mostly
carry a single line. Note: this WO's "Planned Start Date"/"Planned End Date" are BOTH 0D in this
company (CRONUS NL) even though the `mcp__ah_bc_mcp` OData connector's default company shows
non-blank planned dates for a same-numbered WO — the MCP connector's default company is a
DIFFERENT company than "CRONUS NL" (probably one of HQ_IT/UK_HQ/HQ_DE/HQ_DK/HQ_FR/HQ_AT, seen in
the standing company-switcher 401-probe baseline noise) — don't assume MCP-tool WorkOrder field
values match what a live CRONUS NL Playwright session will show for the same No.; the blank
planned dates correctly triggered this code's AnchorDate-fallback window (14 days,
2026-08-30..2026-09-12), which is itself expected/correct behavior per spec, not a bug.

Confirmed via fresh page load (not just an in-session JS patch): title renders
"Workorder DWO0008 | Snag List Resolution", one section row "10000 1080 ELEKTR", three purple
"0/8h" bars on the correct dates (08/09/10 Sep). Reset Position round-trip re-renders identically
with no duplicate-view error and no new console errors. Console errors throughout: 7, all
pre-existing baseline noise (1x graph.microsoft.com photo 404 + 6x company-switcher 401s, same
pattern as [[barchart_suitecss_404_transient_not_regression]] and the step-1 skeleton smoke
test) — zero new errors from this add-in's JS.

**Update 2026-09-02 (later same day): steps 4 (shortage/coverage engine) + 5 (capacity-vs-requested
daily bars) done and live-verified against the same DWO0008.**

**Step 4 — `src\codeunit\codeunit_50604_DHXDataHandler.al`, CPO_* region:**
- `CPO_BuildPlanningDataJson` now also accumulates, in the SAME pass that already builds
  `woLines` (no second DayPlanning query): `TotalRequestedByDate` (Dictionary of [Date,Decimal],
  keyed straight off `DayPlanning."Plan Date"` — this total already IS the day-level
  Requested-across-all-skills figure, so no per-skill bucket is needed for the aggregate) and
  `ActiveSkillList` (distinct non-blank Skill values this WO demands).
- New `local procedure CPO_CalcSkillAvailability(SkillCode; WorkOrderNo; StartDate; EndDate; var
  AvailableByDate: Dictionary of [Date, Decimal])`: resources holding SkillCode via
  `Record "Resource Skill"` (`SetRange(Type, Type::Resource); SetRange("Skill Code", SkillCode)`
  — exact pattern already used elsewhere in this same codeunit, e.g.
  `ResourceMatchesSkillFilter` ~line 3639). For each resource (deduped via a
  `Dictionary of [Code[20], Boolean]` SeenResources set, same idiom codeunit 50662's
  `BuildAssignedResourceSet` uses): sums `"Res. Capacity Entry".Capacity` per Date in range
  (`SetRange("Resource No.", ...); SetRange(Date, StartDate, EndDate)`), MINUS
  `"Day Planning"."Assigned Hours"` per `"Plan Date"` where `"Assigned Resource No."` = that
  resource, `Assigned = true`, and `SetFilter("Work Order No.", '<>%1', WorkOrderNo)` — that
  `<>` filter naturally also captures blank/not-yet-assigned-to-any-WO lines as "other" demand,
  per spec. Whole-window reads per resource (not day-by-day queried), so cost scales with
  resource-pool size × 1, not × window length.
- New `local procedure CPO_BuildStatsRowsArray(StartDate; EndDate; var TotalRequestedByDate; var
  TotalAvailableByDate): JsonArray` — one `{date, coveragePct, shortageHours, hasDemand}` entry
  per calendar day. `hasDemand := Requested > 0`; when false, `coveragePct`/`shortageHours` both
  0 but the JS MUST key off `hasDemand` (not treat 0 as "fully covered") — mirrors the reference
  prototype's em-dash "outside" days. `CoveragePct := Round(100 * Available / Requested, 1)` —
  `Round(x, 1)` with precision **1** rounds to the nearest whole percent, matching the plan's
  "round(...)" spec (easy to misread as "1 decimal place" — it's not, precision=1 means nearest
  integer).
- `CPO_BuildPlanningDataJson`'s combined payload now also has `RootObj.Add('statsRows',
  StatsRowsArr)`.
- **Live numeric sanity check (confirmed correct, not a bug):** DWO0008's 3 lines (8h/day
  ELEKTR, 08-10 Sep) rendered coveragePct = 6100%/5700%/7100%, not ~100%. This is CORRECT given
  the "simple, no multi-skill optimizer" formula the plan explicitly chose: `CPO_CalcSkillAvailability`
  sums capacity across **every** resource holding the skill company-wide, and this demo company's
  ELEKTR skill has **101** resources (confirmed via `mcp__ah_bc_mcp__List_ResourceSkills_PAG50672`
  filter `skillCode eq 'ELEKTR'`, though note that MCP connector's default company differs from
  the live-tested `CRONUS NL` per [[project_capacity_planning_overview_skeleton]]'s own earlier
  note — still a valid order-of-magnitude sanity check since it confirms this demo dataset seeds
  large per-skill resource pools generally). A large resource pool's total daily capacity dwarfing
  one WO's 8h/day demand is an expected, by-design consequence of comparing one WO's demand
  against the WHOLE company's resource pool for that skill — not a double-counting bug. Flag this
  to the user if huge percentages look surprising in a demo.
- **Untested against real data:** DWO0008 had no OTHER Work Order's competing Day Planning
  assignments to exercise the `"Work Order No." <> WorkOrderNo` subtraction with a nonzero
  result — the code path ran without error (0-competing-demand is the common case and works
  fine), but the subtraction's actual effect on a real conflict was not observed live. Worth a
  follow-up spot-check if a WO with genuine competing demand is ever identified in this company.

**Step 5 — `src\dhx\barchart_weekly\codeunit_50662_SkillCapacityAnalysisMgt.al`:**
- New `procedure BuildDayCapacityChartDataForRange(StartDate: Date; EndDate: Date): Text` — a
  near-duplicate of the existing `BuildDayCapacityChartData`, generalized from the fixed
  Monday..Sunday `array[7]` structure to `List of [Boolean]`/1-based DayIndex loop over
  `[StartDate, EndDate]` of any length. Reuses `EnsureDayPlanningBuffer`/`BuildActiveSkillList`/
  `CalcDaySegments`/`DayHasAnyChartData`/`AddChartSeries`/the same color-resolution helpers
  verbatim — same JSON shape/keys/segment contract (Assigned Internal/External, Free Capacity
  Internal/External, per-skill Internal/External pairs, same Capacity-bar-keeps-split /
  Requested-bar-collapses-to-total rule). `dayIndices` in the output is a 1-based index into the
  caller's own `[StartDate,EndDate]` span (not a 1..7 weekday number) — a caller needing the real
  Date must re-derive it as `StartDate + (dayIndex - 1)`.
- **Important caveat inherited from the base procedure and NOT worked around:**
  `DayHasAnyChartData` still omits any day with zero segment data anywhere from `categories`/
  `dayLabels`/`dayIndices`/every series' `values` — a day is either fully present (2 value
  slots) or fully absent (no slot at all), never a zero-padded slot. The JS side (see below) has
  to reconstruct full day-for-day alignment itself via the `dayIndices` lookup; it does NOT come
  for free from this procedure's output.
- `codeunit_50604_DHXDataHandler.al`'s `CPO_BuildPlanningDataJson` now also calls a new `local
  procedure CPO_BuildCapacityBarsObj(StartDate; EndDate): JsonObject` (parses
  `SkillCapacityAnalysisMgt.BuildDayCapacityChartDataForRange`'s Text result back into a
  `JsonObject` via `.ReadFrom`, so it nests as `RootObj.Add('capacityBars', ...)` — a real nested
  object, not a JSON-string-inside-JSON) into the SAME combined payload, per the plan's
  single-payload requirement — no second round-trip from the page.

**JS — `src\dhx\capacity_planning_overview\capacityPlanningOverview.js` (both steps 4 and 5):**
- `applyPlanningData` now calls `renderScheduler` FIRST, then `renderStatsHeader`, then
  `renderCapacityBars` — deliberate order: sections 1 and 3 both measure section 2's ACTUAL live
  DOM via a new `measureSchedulerLayout()` helper (`.dhx_matrix_scell` for the row-header sidebar
  width, `.dhx_matrix_cell` for one day's real pixel width) rather than guessing a static pixel
  value — this is what gets pixel-perfect column alignment across all 3 sections, confirmed live
  (screenshot: day-column centers for 30 Aug through 12 Sep line up across the stats header, the
  scheduler's own date scale, and the capacity-bar day columns). `renderScheduler`'s
  `createTimelineView` config also gained `column_width: 60` (same DHTMLX config key
  `request_assignment/wrapper.js` already uses) so the day-cell width is deterministic instead of
  DHTMLX's default container-width/day-count auto-sizing.
- `renderStatsHeader(json)`: renders `json.statsRows` as a plain flex row (`.cpo-stats-header` >
  `.cpo-stats-row` > spacer + one `.cpo-stats-cell` per day), 2 lines per demand cell
  ("NN%"/"+Xh shortage"), color-classed `cpo-stats-ok`/`-warning`/`-critical` by coveragePct
  threshold (>=100/50-99/<50), `.cpo-stats-outside` em-dash cell when `hasDemand` is false.
- `renderCapacityBars(json)`: renders `json.capacityBars` as `.cpo-capacity-bars` >
  `.cpo-daily-chart-row` > spacer + one `.cpo-daily-chart-day` PER ENTRY IN `json.workdays` (the
  full calendar-day array shared with sections 1/2) — **not** per entry in `capacityBars`, since
  that array only carries the subset of days `DayHasAnyChartData` found nonzero (see caveat
  above); a day absent from `capacityBars.dayIndices` renders as an empty 0h/0h column instead of
  being skipped, which is what keeps this section's day columns 1:1 with sections 1/2's day
  columns above it. Builds a `posByDayIndex` lookup (`dayIndices[pos] -> pos`) to map
  `workdays[k]` (`k` 0-based) to `capacityBars.series[].values[2*pos]` (Capacity-bar value) /
  `[2*pos+1]` (Requested-bar value) for `pos = posByDayIndex[k+1]`. Looks series up BY NAME
  (`'Assigned Capacity - Internal'` etc.) rather than by array position, and for skill series
  keeps only the first-seen occurrence per name (the Internal half — the External half is always
  0 on both bar positions per codeunit 50662's own collapse rule, so it's dead weight to render).
  Segment colors come straight from each series' own `color` (already resolved via codeunit
  50609's `GetSkillBarColor`/`GetCapacitySegmentColors`, not hardcoded) — border colors are NOT
  yet applied (a minor follow-up if the external/red-border convention matters here later).
  CSS classes `cpo-daily-chart-*` intentionally mirror the reference prototype's own
  `daily-chart-day/-bars/-col/-label/-bar-area/-stack/-segment` naming (DHTMLXtempv112-app.js's
  `renderDailyCapacityRequestChart`, ~L612-663), just cpo-prefixed.

**Real CSS bug found and fixed live (worth remembering for any future multi-section stacked
control add-in in this repo):** `.cpo-scheduler-container`'s `flex: 1 1 auto` let section 2
greedily consume ALL of `#cpo-root`'s spare vertical space (measured live: grew to 474px instead
of its intended 400px), silently pushing section 3 mostly past whatever fixed-height/
overflow:hidden box BC's control-add-in host gives the page — confirmed via DOM inspection
(`page.frames()` + `$eval`) that section 3's HTML was 100% correct (real segment `height:Npx`
divs, real hour totals) but only its date-label row was visually reachable; the bars and value
row were clipped below the fold with ZERO console errors to signal it. Fix: changed
`.cpo-scheduler-container` to `flex: 0 0 400px` (fixed, matching sections 1/3's own `flex:0 0
auto`) and added `overflow-y: auto` to `#cpo-root` so if sections 1+2+3's combined natural height
ever exceeds whatever the host gives, the page scrolls instead of silently clipping. **Lesson:**
a DHTMLX Scheduler pane sized via `flex:1 1 auto` inside a taller flex column will happily eat
space needed by sibling sections below it, with no visible error — always give it a fixed
`flex:0 0 <px>` when other content must render after it in the same column, not a growing
flex-basis.

**Console errors both times (steps 4 and 5, plus a Reset Position round-trip after step 5):**
consistently 7, all pre-existing baseline noise (1x `graph.microsoft.com` photo 404 + 6x
company-switcher 401s for HQ_DE/HQ_FR/UK_HQ/HQ_DK/HQ_AT/HQ_IT) — same pattern as
[[barchart_suitecss_404_transient_not_regression]]. Zero new errors from this add-in's JS/CSS at
any point across both steps.

**Not yet built** (later plan steps): section 4 tree+chip grid, the real transactional
reschedule (`Confirm()`+`Validate()` loop — currently still a `Message()` stub), capacity-lookup
modal wiring, sequence-chip → Day Plannings navigation, scroll-sync (needs section 4 first), and
color wiring (`applyColors` is still a no-op — note steps 4/5 DID wire real colors into their own
sections via codeunit 50609, so this remaining no-op is specifically about `SetColors`/palette
push from the page trigger, not section-level color resolution in general).

**Update 2026-09-02 (later same day): correctness fix — `CPO_CalcSkillAvailability`'s resource
pool is now PROJECT-TEAM-SCOPED, not company-wide.** The step-4 company-wide version (every
resource holding the skill anywhere, per `Resource Skill`) produced meaningless 5700%-7100%
coverage for DWO0008 against this demo's ~101-resource ELEKTR pool — flagged by the user as
needing a fix before continuing.

**Corrected formula (`src\codeunit\codeunit_50604_DHXDataHandler.al`,
`CPO_CalcSkillAvailability`, now takes `JobNo`/`JobTaskNo` params computed in
`CPO_BuildPlanningDataJson` from `WorkOrder."Project No."`/`"Project Task No."`):** the resource
UNIVERSE for a skill/day is no longer "every company resource holding SkillCode" — it's now
"resources already on THIS WORK ORDER'S PROJECT TEAM" ∩ "resources holding SkillCode", where
project-team membership = distinct non-blank `"Day Planning"."Assigned Resource No."` across
**every** Day Planning line whose `"Job No."`/`"Job Task No."` match this WO's own Project
No./Project Task No. (`WorkOrder."Project No."`/`"Project Task No."` — table 50608's own
CalcFormulas already key Planned Start/End Date off these two fields against `"Job Task"`) —
scoped to the whole project task, not just this one WO (a Job Task can host multiple Work
Orders), and deliberately NOT filtered by `Plan Status` or `Assigned` (a requested-but-not-yet-
assigned line's resource still counts as "on the team"). For each such team member, `Resource
Skill` (`Type=Resource`, `"No."`=resource, `"Skill Code"`=SkillCode, checked via
`SetRange`+`IsEmpty()`, not `Get()` — primary key field order on this base-app table wasn't
verified) gates whether they contribute; the existing capacity-sum (`Res. Capacity Entry`) and
other-WO-assigned-hours-subtraction (`"Day Planning"."Assigned Hours"` where
`"Work Order No." <> WorkOrderNo`) logic is UNCHANGED once a resource qualifies. A skill/day with
zero qualifying team resources now legitimately shows `Available=0` (missing-key-is-0, same
convention as before) — this is an intended "no one on this team has this skill yet" shortage
signal, not a fallback or an error.

**Live re-verification (2026-09-02, same DWO0008/CRONUS NL/NL_Copy20240710):** coverage now shows
**0%** / **"+8h shortage"** (row 1) and **"8h" / "caused by WO"** (row 2) for all three real-demand
days (08/09/10 Sep) — confirmed CORRECT, not a bug: spot-checked live via page 50630 "Day
Plannings" filtered to Job No.=10000/Job Task No.=1080 (this WO's own project) — **every single
Day Planning line on this project, across all its Elektrisch/Molder sequences, has a blank
"Assigned Resource No." and Plan Status = "In Request"** (0.00 Assigned Hours everywhere). This
demo project genuinely has nobody assigned yet, so the project-team resource pool is empty and 0%
is the exactly-right answer — a real, non-demo project with actual team assignments would show a
meaningful (non-zero, non-thousands-of-percent) coverage number instead. **Caveat for a future
pass:** this dataset's "no one assigned yet" state means the OTHER-WO-assigned-hours subtraction
branch (competing demand from a different WO) still has not been exercised against a nonzero
result in this company — same untested caveat carried over from the step-4 note, now doubly true
since even the team-membership branch itself has only been proven against an empty-team case so
far. If a project with actual resource assignments is ever found in this company, worth a
follow-up spot-check of a real nonzero coverage number.

**Same pass — Section 1 gained a row-label column + a second stats row** (previously it was a
single unlabeled row of cells, with no left-hand sidebar — user flagged this was missing
entirely). `capacityPlanningOverview.js`'s `renderStatsHeader` now renders TWO `.cpo-stats-row`
divs (mirrors the reference prototype's `createWorkOrderSummaryScheduler`,
`DHTMLXtempv112-app.js` ~L211-253, which has the identical two fixed section labels/values, just
implemented there as a synthetic DHTMLX Scheduler timeline instead of this add-in's plain-HTML
approach): a `.cpo-stats-label` div (fixed width = `layout.rowHeaderWidth`, same value the
existing spacer already used, so it lines up with section 2's own row-header sidebar) followed by
that row's day cells. **Exact label text (per explicit user correction — do not use the
reference's own internal hyphenated `label:` string):** row 1 = "Calculated conclusion", row 2 =
"Current position shortage" (no hyphen). Row 1 reuses the existing `coveragePct`/`shortageHours`
fields (now also says "no shortage" instead of "+0h shortage" when `shortageHours=0`, matching the
reference's exact three-state text). Row 2 is NOT a second AL calculation — it reuses the SAME
`shortageHours` value already in `statsRows`, rendered as its own labeled row ("Xh" bold +
"caused by WO"/"no shortage" small text, colored ok/warning/critical at 0h / ≤8h / >8h — mirroring
the reference's `wo-short-good/-small/-bad` thresholds). Both rows render "–"/"outside" for
`hasDemand=false` days. No new AL/JSON field was needed for this — `statsRows` shape is unchanged,
only the JS rendering changed. New CSS: `.cpo-stats-label` (fixed-width flex-shrink:0 label box)
and `.cpo-stats-row2` (top border) in `src\dhx\capacity_planning_overview\style.css`. Verified
live via `document.getElementById('cpo-stats-header').innerText` (not just a screenshot) — exact
text confirmed matches spec for both rows across all outside/demand days.

**Tooling note:** `al_publish` in this environment needs `projectPath` (folder containing
app.json), NOT `appPath` (a direct .app file path) — passing `appPath` alone fails with
"ProjectPath is required when AppPath is not specified" even though the tool schema allows either.
`skipBuild: true` + `projectPath` after a separate `al_build` call is the working combination
(this contradicts the earlier [[al_publish_invalid_uri_tooling_bug]] memory's "fails regardless of
params" framing — that may have been a different, session-specific failure mode; this session's
failure was cleanly parameter-shaped, not an opaque URI error, and resolved immediately by
switching to `projectPath`).

**Update 2026-09-02 (later same day): Fix 1 (section 2's duplicate date-header row) and section 4
(the tree+chip panel) both done and live-verified on the same DWO0008/CRONUS NL/NL_Copy20240710.**

**Fix 1 — root cause and actual fix, `src\dhx\capacity_planning_overview\style.css`:** The
"Required DOM elements are missing... scheduler.config.header is not specified" console log this
pass investigated turned out to be a RED HERRING, not the actual cause — traced the exact
condition in the vendored `src\dhx\dhtmlxscheduler.js` (`this.config.header||y(this.$container)||
(this.config.header=...)`): since `configureBaseScheduler` already sets `s.config.header = []`
(an empty array, which is *truthy* in JS), that `||` chain short-circuits and the default-header
fallback this log message describes NEVER actually runs for either of this add-in's Scheduler
instances — the log is misleading/unrelated. The REAL cause: `scheduler.init()`
unconditionally appends a `.dhx_cal_header` container div (`c.render()` in the same vendor code,
right alongside the nav-bar and `.dhx_cal_data` grid) for EVERY Scheduler instance regardless of
`scale_height`, and the timeline extension renders its actual day-scale row INTO that container —
`scale_height: 0` in `createTimelineView`'s config was not sufficient to suppress this live
(confirmed: the config was already correctly set before this pass touched anything). Fix: CSS-
forced hide, `display:none!important; height:0!important` on `.dhx_cal_header`/`.dhx_scale_bar`,
scoped strictly to `#cpo-wo-scheduler` (section 2) — same class of problem
`projectschedule/wrapper.js`'s own `.dhx-hide-default-tabs` CSS technique solves for its navline,
just applied unconditionally here (not toggled via a class) since section 2 must ALWAYS hide its
own header, unlike projectschedule's conditional tab visibility. Live-verified: the shared date
row (30 Aug...12 Sep) now renders exactly once, directly above section 2's "10000 1080 ELEKTR" row
— no duplicate. The same CSS rule was proactively also scoped to `#cpo-central-tree` (section 4,
built this same pass) since it sets `scale_height: 0` for an identical reason and would very likely
hit the identical DHTMLX quirk — confirmed live no duplicate header appeared there either.

**Section 4 (tree+chip panel) — AL, `src\codeunit\codeunit_50604_DHXDataHandler.al`, CPO_* region:**
`CPO_BuildPlanningDataJson` now also collects, in the SAME single DayPlanning FindSet pass that
already builds `woLines`/`TotalRequestedByDate` (no second query): nine parallel `List of [Text]`/
`List of [Decimal]` "TreeLine*" accumulators (one entry per real Day Planning line with a
non-blank Skill — same blank-Skill exclusion `ActiveSkillList` already uses, since a Skill tree
node can't represent unclassified demand). Two new local procedures consume these AFTER the main
loop (kept as flat primitive Lists WHILE accumulating, not nested JsonObject/JsonArray, per a
deliberate house rule established this pass — see below):
- `CPO_BuildTreeNodesArray` → `treeNodes`: nested `Skill → Job/Task detail → Sequence` (3 levels,
  NOT the 2 the instructions' example literally named — a 3rd "sequence" leaf level is required
  because a single Skill+Job/Task combo can have multiple distinct Sequence Nos, same
  `sequenceKey` grouping `woLines`/section 2 already use). Every node carries `key`/`section_id`
  (identical value, prefixed `skill:`/`detail:`/`sequence:`) + `label`/`type` + context
  (`skill`/`jobNo`/`jobTaskNo`/`sequenceKey`). Skill and detail nodes additionally carry `open:
  true` and `dayTotals` (an ISO-date-keyed `{assignedHours, requestedHours}` object, built by the
  new `CPO_BuildDayTotalsObj` helper — a linear scan of the same TreeLine* lists, filtered to that
  node's Skill, or Skill+JobNo+JobTaskNo when `MatchJobTask=true`). Sequence (leaf) nodes carry
  no `dayTotals`/`children` at all (chip data lives in the separate `treeCells` payload instead).
- `CPO_BuildTreeCellsObj` → `treeCells`: `{ sequenceKey: { isoDate: [ {lineId, assignedHours,
  requestedHours, assignedResourceNo}, ... ] } }` — one chip object per REAL Day Planning line
  (never aggregated), so a leaf cell with multiple lines on the same day legitimately gets an
  array with >1 entry.

**Deliberate house rule established this pass (documented in both new procedures' own doc
comments, worth remembering for ANY future nested-JSON AL work in this codeunit):** never
`.Get()` an already-`.Add()`-ed JsonArray/JsonObject back out of its parent to append more items
into it later — this codeunit's own existing convention (every `RootObj.Add(...)` call
elsewhere) is to fully assemble a child bottom-up FIRST, then `Add()` it to its parent exactly
ONCE. Both new tree procedures follow a strict two-pass shape to honor this: pass 1 collects
ordered-distinct key lists via `List.Contains()`-based dedup (same idiom `ActiveSkillList` already
uses elsewhere in this file), pass 2 does nested linear scans (`for i := 1 to List.Count()`) over
those tiny per-WO Lists to group and build each JsonObject/JsonArray completely before adding it
once — O(lines²)-ish cost but trivially cheap at this feature's scale (one Work Order's own lines,
not a company-wide scan).

**Section 4 — JS, `src\dhx\capacity_planning_overview\capacityPlanningOverview.js`:** A THIRD real
DHTMLX Scheduler timeline instance (`this.centralTreeScheduler`, `Scheduler.getSchedulerInstance()`
— same multi-instance convention sections 1/2 already use), `render: 'tree'` +
`s.plugins({timeline:true, treetimeline:true})`, `y_unit: json.treeNodes` passed straight through
with NO client-side re-shaping (AL already emits the exact `{key, section_id, label, open,
children}` shape the treetimeline plugin needs). Deliberately followed
`projectschedule/wrapper.js`'s own proven `RecreateTimelineView` config shape (`folder_dy`,
`y_property:'section_id'`, `cell_template: true`) rather than the reference prototype's
`createCentralScheduler`, which additionally uses a `columns:[{label,width,template}]` left-header
feature this repo's own proven pattern doesn't exercise anywhere — NOT ported, kept as plain
`label` strings per node instead (matches section 2's own convention). `centraltree_cell_value`
branches on `section.type`: `'sequence'` renders one small `<span class="cpo-tree-chip">` per chip
in `json.treeCells[sequenceKey][isoDate]` (never merged, even when >1 — confirmed the per-day
array shape works exactly as intended, one solid-blue square per real Day Planning line), native
`title=` attribute for a trivial hover tooltip (no new tooltip system built, per the instruction
that section 4 tooltips beyond section 2's trivial pattern were out of scope this pass);
`'skill'`/`'detail'` render one `cpo-tree-summary-cell` heat-gradient div using
`self.treeNodeIndex[section.key].dayTotals[iso]` (a new `buildTreeNodeIndex(json)` method flattens
`treeNodes` into a flat `key -> node` lookup once per `applyPlanningData` call) and the same
`skillColorFor` gradient technique section 2's `event_bar_text` already uses. New
`applyCentralTreeHeight` sizes `#cpo-central-tree` proportional to the INITIAL visible row count
(walks the tree respecting each node's `open` flag) — NOT recomputed on every Expand/Collapse click
(the container's own `overflow-y:auto` is the fallback for an over-height fully-expanded tree).

**Expand/Exp. to Task/Collapse wiring** — `bindHierarchyButtons()` (previously a no-op stub) now
calls a new `setTreeOpenState(skillOpen, detailOpen)`, which ports
`projectschedule/wrapper.js`'s own `ToggleCollapseExpandAllSections` technique VERBATIM (mutate the
`open` flag on `s.matrix.centraltree.y_unit_original`'s nodes recursively, re-derive the flattened
`y_unit` via `s._getArrayToDisplay(...)`, fire `s.callEvent('onOptionsLoad', [])` to force a
redraw) rather than re-calling `createTimelineView`/`init` — this is the exact pattern already
proven live elsewhere in this repo, not a new invention. Expand = `(true,true)`, "Exp. to Task" =
`(true,false)` (shows skill+detail summary rows, hides per-line sequence chip rows), Collapse =
`(false,false)` (skill rows only). **All three confirmed live** via Playwright on DWO0008: Collapse
→ only "ELEKTR" row visible (chevron collapsed); Expand → full 3-level tree restored (ELEKTR →
10000 1080 → SeqNo 1, with 3 chip cells on 08/09/10 Sep); Exp. to Task → ELEKTR expanded but
"10000 1080" collapsed (SeqNo row hidden, chevron on the detail row shows collapsed state) — exact
intended semantics for all three buttons, not just "doesn't crash."

**Live full-page screenshot (all 4 sections stacked, DWO0008):** title "Workorder DWO0008 | Snag
List Resolution"; section 1's two-row stats header (unchanged from the prior pass); section 2's
"10000 1080 ELEKTR" row with three "0/8h" bars directly under the SAME date row as section 1 (no
duplicate — Fix 1 confirmed); section 3's daily capacity/request bar chart with Expand/Exp. to
Task/Collapse buttons (unchanged); section 4's new tree — ELEKTR skill row (solid blue "8h" heat
cells on 08/09/10 Sep — solid blue, not a partial gradient, is CORRECT: assigned=0/requested=8
means 0% coverage, so the gradient renders 100% "color"-side, same as section 2's own "0/8h" bars
already do, not a bug), "10000 1080" detail row (same "8h" cells, aggregated one level up), "SeqNo
1" leaf row (one small chip per day, matching the 3 real Day Planning lines).

**Console errors throughout this pass** (initial load, Collapse click, Expand click, Exp. to Task
click): consistently 7, all pre-existing baseline noise (1x `graph.microsoft.com` photo 404 + 6x
company-switcher 401s for UK_HQ/HQ_DK/HQ_IT/HQ_FR/HQ_AT/HQ_DE) — same pattern as
[[barchart_suitecss_404_transient_not_regression]]. Zero new errors from this pass's AL/JS/CSS at
any point.

**Remaining gaps / follow-ups worth flagging (none blocking, none built this pass — explicitly
out of scope per this pass's own instructions):**
- Section 4's day-cell click-to-relocate (drag-reschedule) is unwired — `s.config.drag_move =
  false` deliberately, same read-only posture as section 1/3.
- The shared Capacity lookup modal (`OnRequestCapacityLookup` stub in page 50722) is still
  unbuilt.
- No scroll-sync between sections 3 and 4 — their day columns line up pixel-for-pixel via the same
  shared `ROW_LABEL_WIDTH`/`COLUMN_WIDTH` constants, but scrolling one horizontally does not move
  the other (each has its own independent `overflow` container).
- Section 4 tooltips are the browser's native `title=` attribute only (no custom positioned
  tooltip div like section 2's `#cpo-event-tip`) — intentionally trivial per this pass's scope.
- `applyColors`/`showCapacityModal` are both still no-op placeholders (unchanged from before this
  pass) — this remaining gap is specifically the page-level `SetColors`/palette-push trigger, not
  section-level color resolution (section 4 DOES use real per-skill colors via `skillColorFor`,
  same as sections 2/3).
- Not spot-checked this pass: a leaf cell with genuinely >1 chip in the same day (this WO's data
  only ever has exactly 1 Day Planning line per sequenceKey+day) — the `treeCells` array-per-day
  shape was built and reasoned to handle this correctly, but has not been visually confirmed
  against real multi-chip data in this company.

**Update 2026-09-02 (same day, follow-up pass): column-width misalignment between sections 1/2/4
(real Scheduler) and section 3 (plain HTML) found and fixed — root cause required TWO attempts.**

**Symptom (user-reported from a live screenshot):** section 1/2's real DHTMLX Scheduler day
columns (config `column_width: CapacityPlanningOverview.COLUMN_WIDTH`, i.e. 60) rendered visibly
WIDER on screen than section 3's plain-HTML day divs (`style="width:60px"` inline). Same constant,
different actual rendered pixel width.

**First attempt (WRONG, corrected before publishing further) — do not repeat:** hypothesized that
adding `scrollable: true` to sections 1/2/4's `createTimelineView` config (matching
`request_assignment/wrapper.js`'s own two Scheduler instances, which align pixel-perfect with each
other) would make DHTMLX honor `column_width` literally — based on a real code path found in the
vendored `dhtmlxscheduler.js` (`if(this.scrollable&&this.column_width>0){var
p=this.column_width*E.displayed;p>f&&(f=p,...)}`). Published and re-measured live: **zero effect**
— columns still rendered exactly 157px, byte-for-byte identical to before. Root cause of why this
didn't work: that code branch only WIDENS the computed content width when the configured
`column_width*dayCount` (`p`) is GREATER than the container's own natural width (`f`) — i.e. it's
designed to let genuinely-overflowing content scroll instead of getting squeezed, never the
reverse. This add-in's host divs are always `width:100%`-wide (far wider than 60px×14 days≈840px),
so `p>f` is always false and the branch never fires — `scrollable:true` is a true no-op in this
scenario. Confirmed live via `request_assignment`'s own actual host div — its Scheduler panels sit
in a narrower fixed-width split-pane, so ITS content genuinely overflows and `scrollable:true`
does real work there; that precondition doesn't hold for this add-in's full-width sections.
**Lesson for future DHTMLX layout work in this repo:** `scrollable:true` only forces a config
value to be honored when the container is narrower than that value implies — it does nothing when
the container is wider (which is the common case for a full-width dashboard section).

**Actual root cause (confirmed via `browser_evaluate` measuring real live DOM, not just reading
minified vendor source):** DHTMLX's `column_width` config is genuinely just an initial hint;
whenever the host's own CSS gives it more width than `column_width * dayCount`, DHTMLX
auto-stretches every day column to fill the ENTIRE available container width, ignoring the
configured pixel value outright. `dx` (row-header sidebar width) is NOT subject to this — it
renders at the literal configured value every time (measured live: `.dhx_matrix_scell` width was
exactly 200px = ROW_LABEL_WIDTH, matching config exactly). Since sections 1/2/4 are all THREE real
Scheduler instances sharing the identical host width (`width:100%`) and identical day count, they
all independently auto-stretch to the exact SAME pixel width as each other "for free" — the ONLY
real misalignment was ever between {1,2,4} (auto-stretched, measured 157px against a 2417px-wide
host / 14 days) and {3} (plain HTML, literal 60px inline style).

**Actual fix applied, `src\dhx\capacity_planning_overview\capacityPlanningOverview.js`:**
Reinstated a scoped runtime-measurement step (the SAME idea the file's own history calls
`measureSchedulerLayout()`, deliberately narrowed to just the one value that's actually
unreliable): new `measureColumnWidth()` method reads
`document.querySelector('#cpo-wo-scheduler .dhx_matrix_cell')` (falling back to
`#cpo-wo-summary .dhx_matrix_cell`) via `getBoundingClientRect().width`, falling back to the
`COLUMN_WIDTH` constant only if no cell exists yet (e.g. zero workdays). `applyPlanningData` now
calls `this.measuredColumnWidth = this.measureColumnWidth()` AFTER `renderWoSummaryScheduler`/
`renderWoScheduler` (section 2 must have painted real cells first) and BEFORE `renderCapacityBars`
— re-measured on every call (not cached across Work Orders), since day count — and therefore the
auto-stretched width — can differ between WOs. `renderCapacityBars` now sizes its day divs from
`this.measuredColumnWidth` (a local `columnWidth` const, closed over by the `perDay.map` callback)
instead of `CapacityPlanningOverview.COLUMN_WIDTH` directly — `ROW_LABEL_WIDTH` stayed a literal
constant everywhere (confirmed reliable, unlike `column_width`). Section 4 needed NO special
handling — it's itself a Scheduler instance and self-aligns with sections 1/2 automatically (same
host width/day count -> same DHTMLX auto-stretch result), confirmed by the same live measurement.
The ineffective `scrollable: true` lines were removed from all three `createTimelineView` calls
(confirmed inert, left in would only mislead a future reader) and the misleading doc comments that
had credited them were corrected.

**Live-measured pixel offsets, before vs after (DWO0008, first 5 day columns via
`browser_evaluate` reading real `getBoundingClientRect()` off `.dhx_matrix_cell`/
`.cpo-daily-chart-day`, not just visual inspection):**
- Before (both the original build AND after the failed `scrollable:true` attempt — byte-identical
  in both cases): sections 1/2/4 (`.dhx_matrix_cell`) all measured `left:200,right:357,width:157`
  for column 1, `357/514/157` for column 2, etc. (all three Scheduler instances already agreed with
  EACH OTHER); section 3 (`.cpo-daily-chart-day`) measured `left:200,right:260,width:60` for column
  1, `260/320/60` for column 2 — a 97px/column drift against sections 1/2/4.
- After (measureColumnWidth fix): all FOUR sections (`.dhx_matrix_cell` on all three Scheduler
  instances AND `.cpo-daily-chart-day` on section 3) measured byte-identical —
  `left:200,right:357,width:157` for column 1, `357/514/157` for column 2, `514/671/157` for column
  3, etc., through all 5 columns checked — confirmed pixel-perfect, not just "same configured
  constant."

**Console errors throughout this follow-up pass** (both the failed `scrollable:true` attempt and
the actual fix): consistently 7, same pre-existing baseline noise as every prior pass in this file
— zero new errors from either change.
