---
name: project-dailyoptimizer
description: Key facts about the DailyOptimizer extension — object ranges, architecture, active development areas
metadata:
  type: project
---

**Extension:** DailyOptimizer (app version 28.0.0.0), publisher Optimizers, app.json `application` field still declares 26.0.0.0 / `runtime` 15.0 (legacy, left over from the "convert to v.28" commit 703df22 which only bumped the app's own `version` + added `preprocessorSymbols: ["BC28"]` — did not bump `application`/`runtime`). NoImplicitWith enabled.

**ID Range:** 50600–60700 (custom objects). DateEngine demo objects occupy 60001–60016 (hand-rolled, non-BC-Test-framework harness under `src/dhx/ganttdemo2/DateEngine/` — ignore as a pattern). Test codeunits added 2026-06-16: 60020 "Day Planning Creation Tests", 60021 "Day Planning Test Runner" in `test/`.

**Core domain:** Project/resource scheduling on top of standard BC Jobs/Job Tasks. Key custom tables (current names, post-rename — memory previously had stale "Day Tasks"/"Day Task Generator" names, corrected 2026-06-16):
- `Day Planning` (table 50610) — daily task assignments per Job/Job Task, PK is (Job No., Job Task No., Day Line No.)
- `Day Planning Pattern` (table 50607) — pattern record (date range + Day 1..7 weekday checkboxes + work-hour template) expanded into Day Planning lines
- `Daily Optimizer Setup` (table 50605) — singleton, `"Base Calendar"` field (TableRelation to standard `Base Calendar`) is required by `ExpectedWeekDay` in codeunit 50610

**Key codeunits:**
- 50610 `Day Plannings Mgt.` — `CreateDayPlanning(DayPlanningPattern: Record "Day Planning Pattern")` expands a pattern into Day Planning records. TestField on "Work-Hour Template" runs BEFORE the `case true of` validation block, so a blank Work-Hour Template raises the platform TestField error, not the custom "Work-Hour Template must be specified" text in that same case block (dead branch for that specific scenario).
- 50612 `General Planning Utilities` — `DateToInteger`, capacity/fulfillment calc helpers
- 50613/50614/50615 — Gantt chart data/page/update handlers (DHTMLX integration)
- 50617 `DayPlanning Period Sync Mgt.` (file still named `codeunit_50617_DayPlanningPeriodSyncMgt.al` under `src/dhx/ganttdemo2/`) — preview + apply Day Planning date shifts when Job Task period changes

**Why:** Planning and scheduling ISV solution using DHTMLX Gantt/Scheduler controls embedded in BC pages.
**How to apply:** When adding features, check these codeunits first before touching page/table triggers. See [[dailyoptimizer-test-framework-setup]] before adding any new `[Test]` codeunits.
