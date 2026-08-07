# Bug Diagnosis — Day Plannings disappear from Gantt Resource Panel after drag/resize

**Date:** 2026-08-07
**Severity:** Medium
**Status:** Fixed

## Symptom

On the Gantt Addin page (`page 50620 "Gantt Demo DHX 2"`), when the Resource Panel is open scoped
to a task (opened via right-click → "Show Resources for Task" on a summary/phase task), dragging a
task bar left/right or resizing it causes some Day Planning entries to disappear from the Resource
Panel. Clicking "Refresh Data" does not restore them. Closing and reopening the whole page does
restore them.

**Reproducibility:** Specific condition — only reproduces when the Resource Panel is currently
scoped to a summary task that has child tasks (i.e. was opened via `OnShowResourcesForTask` on a
task with children), and only after a subsequent task-bar drag/resize fires `OnJobTaskUpdated`.

## Layer and category

- **Layer:** Data scope / Logic (marked-record set lost across an event round-trip)
- **Category:** Stale/incomplete filter re-application after a client-driven update event

## Hypotheses

| Priority | Root cause | Probability | Evidence for/against |
|---|---|---|---|
| 1 | `ReloadResourcePanelFromStoredFilter` (page 50620, lines 1273–1310) only marks the single stored Job No./Job Task No. and reloads Day Plannings for it — but the panel's original data set (from `OnShowResourcesForTask`, lines 89–149) was built by marking the parent **and every child task** from the client-supplied `childrenJson`. The stored filter JSON (via `SetResourcePanelFilterInfo`) only ever carries one Job No./Job Task No. pair, so the children marks are unrecoverable once a drag/resize triggers the reload path. | HIGH | Confirmed by reading both trigger bodies; `GetDayPlanningsByJobTaskAsJson`/`GetResourcesByJobTaskAsJson` (codeunit 50613, lines 204–291) iterate only over `JobTask.FindSet()` with `MarkedOnly = true`, i.e. exactly what got marked. Day Planning rows live on leaf tasks, not summary tasks, so a reload that only marks the summary task returns few/no rows for it — the previously-shown child-task entries vanish. |
| 2 | Stale `periodFrom`/`periodTo` window excluding the moved task's new dates | LOW | Already fixed — line 1299–1305 explicitly re-derives the period from `JobTask.PlannedStartDate/PlannedEndDate` before reloading, with a code comment describing this exact prior fix. Ruled out. |
| 3 | Missing `CurrPage.Update()`/render after reload causing a stale client-side cache | LOW | `RenderGantt(true)` is called unconditionally after every reload branch in `OnJobTaskUpdated` (line 271), so the client is told to re-render with whatever was just sent — consistent with "Refresh Data doesn't fix it" (refresh takes the same code path and sends the same incomplete set) rather than a stale cache that a repaint would fix. |

## Confirmed root cause

`OnShowResourcesForTask` (page 50620, lines 89–149) marks the right-clicked task **and all of its
children** (parsed from the `childrenJson` the DHTMLX client already computed) before calling
`LoadFilteredResourcesAndDayPlannings`, so the initial Resource Panel shows Day Plannings belonging
to every child leaf task under the summary.

`SetResourcePanelFilterInfo` only persists a single `job`/`task` pair into
`CurrentResourcePanelFilterJsonString` (line 143) — it has no way to remember which children were
part of that original scope.

When a task bar is later dragged/resized, `OnJobTaskUpdated` (line 229) calls
`ReloadResourcePanelFromStoredFilter` (lines 1273–1310) to keep the panel in sync. That procedure
re-reads the stored single job/task pair, does `JobTask.Get(FilterJobNo, FilterJobTaskNo)` and
`JobTask.Mark(true)` for **only that one record**, then calls `LoadFilteredResourcesAndDayPlannings`
again. Since Day Planning rows are attached to leaf tasks and the summary task itself typically has
none of its own, the reloaded JSON silently drops every Day Planning that belongs to a child task —
exactly the entries the user just saw.

"Refresh Data" doesn't help because it calls `RefreshGantt` → `LoadAllData`, which follows the same
stored-filter branch (lines 1195–1226) and hits the identical single-task marking. Closing and
reopening the page creates a fresh page instance where `CurrentResourcePanelFilterJsonString`
resets to `''`, so the panel falls back to the unfiltered/all-day-planning load path — which is why
that "fixes" it.

## Proposed fix

Make the panel's stored filter remember the full scope (parent + children), not just one task, so
both the initial load and every later reload (drag/resize, Refresh Data) operate on the same marked
set:

- Extend the JSON persisted by `SetResourcePanelFilterInfo`/`CurrentResourcePanelFilterJsonString`
  to include the list of child Job Task Nos. that were marked in `OnShowResourcesForTask` (the
  `childrenJson` the client already sends has this).
- Update `ReloadResourcePanelFromStoredFilter` to mark the parent **and** every child task No. from
  that stored list before calling `LoadFilteredResourcesAndDayPlannings`, instead of marking only
  the single parent.
- No change needed to `GetDayPlanningsByJobTaskAsJson`/`GetResourcesByJobTaskAsJson` — they already
  correctly honor whatever is marked.

This is scoped to page 50620's two procedures (`OnShowResourcesForTask` write side,
`ReloadResourcePanelFromStoredFilter` read side) plus the JSON shape they share; no table or event
publisher changes required.

## Regression risk

- Panels opened for a task with **no** children (a plain leaf task) must keep working exactly as
  today — the fix must not change behavior when there's nothing to add to the marked set.
- `OnResetResourceFilter` (clears the panel back to "all resources") and manually toggling
  Show/Hide Resource Panel must remain unaffected — they don't go through the stored-filter path.
- The JSON schema change must stay backward-compatible with `LoadAllData`'s existing parse of
  `job`/`task`/`periodFrom`/`periodTo` (lines 1195–1226), which also needs to pick up the children
  list for the same reason (it hits the same "only children of the moved task disappear" bug on a
  page-load-time reapplication of the filter, e.g. after `GanttSettings` closes).

## Tests required

- **Happy path:** Right-click a summary task with 2+ child tasks → "Show Resources for Task" (all
  children's Day Plannings visible) → drag/resize one child's bar → all originally-visible Day
  Plannings, including the other untouched children's, are still shown.
- **Adjacent:** Right-click a plain leaf task (no children) → "Show Resources for Task" → drag/
  resize that task's own bar → its Day Plannings still show correctly (this path already works
  today; confirm the fix doesn't regress it).
- **Edge case:** Drag/resize a child task until its Planned Start/End Date moves outside the
  summary parent's own rolled-up period — confirm the reloaded panel still includes that child's
  Day Plannings (tests that the period re-derivation added for hypothesis #2 and the children-marking
  fix for #1 compose correctly).

## Skills Evidencing

| Field | Value |
|---|---|
| Skill loaded | bc-al-bug-fix |
| Symptom | Day Planning entries disappear from Gantt Resource Panel after task bar drag/resize; Refresh Data doesn't restore them; close+reopen does |
| Layer | Data scope / Logic |
| Root cause | `ReloadResourcePanelFromStoredFilter` (page 50620) marks only the single stored parent Job Task, losing the child-task marks that were part of the panel's original scope, so child tasks' Day Plannings drop out of every subsequent reload |
| Fix applied | Added `ResourcePanelChildTaskIds` page var; populated in `OnShowResourcesForTask`, re-marked in `ReloadResourcePanelFromStoredFilter` and `LoadAllData`, cleared in `ClearResourcePanelFilter` |
| Diagnosis doc | docs\GanttResourcePanel-ChildTaskLoss-diagnosis.md |
| Tests defined | 3 (manual verification — see Tests required above) |
