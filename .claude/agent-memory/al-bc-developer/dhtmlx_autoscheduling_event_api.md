---
name: dhtmlx-autoscheduling-event-api
description: Confirmed event names/signatures for DHTMLX Gantt's auto_scheduling plugin, grepped from the bundled src/dhx/dhtmlxgantt.js — needed whenever wrapper.js must react to constraint/dependency-driven date recalculation.
metadata:
  type: project
---

The bundled `src/dhx/dhtmlxgantt.js` (minified) exposes these auto_scheduling plugin events, confirmed by grepping the actual source (not just DHTMLX public docs, which can drift from the bundled version):

- `onBeforeAutoSchedule`, `onAfterAutoSchedule` — fire once per full recalculation pass.
  `onAfterAutoSchedule` signature: `(sourceTaskIds, updatedTaskIds)`. The 2nd arg is the array of task ids the engine actually changed the dates of — confirmed by reading `applyProjectPlan()`/`iterateTasks()` in the engine, which build exactly this id array (`l.push(a.id)` whenever `a.start_date` changes) and return it as the same array passed to `callEvent("onAfterAutoSchedule", [n, thatArray])`.
- `onBeforeTaskAutoSchedule`, `onAfterTaskAutoSchedule` — fire per-task. `onAfterTaskAutoSchedule` signature: `(task, newStartDate, link|null, relatedTask|null)`.
- `onAutoScheduleCircularLink`, `onAutoScheduleConflict`, `onAutoScheduleNoConverge` — diagnostic/edge-case events.

Critical behavioral detail: the engine's internal scheduling paths mutate the task object directly BEFORE firing any event — specifically `a.start_date = c; a.end_date = e.calculateEndDate(a);` — so by the time any of the above events fire, `end_date` is already the raw EXCLUSIVE boundary (DHTMLX's own semantics: the calendar-day boundary AFTER the last occupied day). Any custom end-of-day normalization applied elsewhere (see [[gantt_wrapper_normalize_task_bar_dates]]) needs to be re-applied inside one of these handlers, or it gets silently overwritten whenever auto_scheduling recalculates a constrained/dependent task (SNET/SNLT/FNET/FNLT or link-driven).

**Why:** A user-reported bug (task "1080 - Snag List Resolution", active SNET constraint) showed the Gantt bar's right edge stopping at the start of its end-date column instead of filling it — happened only on constrained/dependent tasks, not on plain load or drag, because `onTaskLoading`/`onAfterTaskDrag` normalization ran but nothing hooked the auto_scheduling recalculation pass that runs after/independently of those.

**How to apply:** When wrapper.js needs to react to constraint- or link-driven date changes (not just load/drag), attach to `onAfterAutoSchedule` and iterate `updatedTaskIds` via `gantt.getTask(id)` + `gantt.refreshTask(id)` — this is simpler and more complete than hooking the per-task `onAfterTaskAutoSchedule` variant. Grep for exact signatures again if the bundled `dhtmlxgantt.js` is ever upgraded, since these are internal/undocumented-in-places APIs verified against this specific bundled build, not guaranteed stable across DHTMLX versions.
