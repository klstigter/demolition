---
name: project-dailyoptimizer
description: Key facts about the DailyOptimizer extension — object ranges, architecture, active development areas
metadata:
  type: project
---

**Extension:** DailyOptimizer (v28.0.0.0), publisher Optimizers, BC application 26.0.0.0, runtime 15.0, NoImplicitWith enabled, BC28 preprocessor symbol.

**ID Range:** 50600–60700 (custom objects), DateEngine objects 60001–60016.

**Core domain:** Project/resource scheduling on top of standard BC Jobs/Job Tasks. Key custom tables:
- `Day Tasks` (50610) — daily task assignments per Job/Job Task, PK is (Job No., Job Task No., Day Line No.)
- `DayTask Sync Preview Buffer` (50661) — temporary table for preview of date changes
- `Day Task Generator` (50607) — temporary table for bulk DayTask creation

**Active feature area (as of 2026-06-08):** "Daytask Week Pattern" — `Job Task` ext field 50610 `"Daytask Week Pattern"` (Code[20]) stores pipe-delimited weekday numbers (e.g. `1|2|3|4|5`). Used in `codeunit 50617 "DayTask Period Sync Mgt."` to filter which days get new DayTask records when a Job Task period is enlarged.

**Key codeunits:**
- 50613 `Gantt Chart Data Handler` — loads Gantt JSON
- 50614 `Gantt BC Page Handler` — opens Job Task cards from Gantt
- 50615 `Gantt Update Data` — processes Gantt bar drag/resize JSON
- 50617 `DayTask Period Sync Mgt.` — preview + apply DayTask date shifts when Job Task period changes
- 50610 `Day Tasks Mgt.` — bulk DayTask creation from generator

**Why:** Planning and scheduling ISV solution using DHTMLX Gantt/Scheduler controls embedded in BC pages.
**How to apply:** When adding features, check these codeunits first before touching page/table triggers.
