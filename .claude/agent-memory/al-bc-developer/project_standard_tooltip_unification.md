---
name: project_standard_tooltip_unification
description: Single-Day-Planning-line hover tooltip unified across DHX add-ins (2026-09-11) - which folders got the standard-tooltip-* structure, which were excluded and why, and the shared AL field-naming convention added to codeunit 50604
metadata:
  type: project
---

2026-09-11: every DHX add-in's hover tooltip for a SINGLE table "Day Planning" line was unified to
one shared HTML structure/CSS class set, ported from the reference `requestTooltipHtml`/
`assignmentTooltipHtml` in `src/dhx/request_assignment/wrapper.js` (+ `standard-tooltip-*` CSS in
that folder's `style.css`, ~line 2717-2825).

**Reference structure** (3 blocks): `.standard-tooltip-context` (Job/Task `<table>`, rows are
`<th>Job</th><td>{no}</td><td>{description}</td>` / same for Task) → `.standard-tooltip-head`
(Skill/Sqnc/weekday+ISO-week/date) → `.standard-tooltip-table` (Request vs Assigned columns, Time +
Resource rows, `.standard-tooltip-different` class on Assigned cell when times differ). Each add-in
keeps its OWN shell/positioning class (e.g. `.request-detail-tooltip`, `.cpo-event-tip`,
`.dhtmlXTooltip.tooltip`) - only inner content classes are shared/ported, since each folder has its
own independent style.css (no cross-folder shared stylesheet except explicit subclass-by-path
cases, e.g. capacity_planning_dashboard loading capacity_planning_overview's style.css).

**Unified (in scope):**
- `request_assignment` - also fixed a self-inconsistency: `requestTooltipHtml` was missing the
  `<th>Job</th>`/`<th>Task</th>` cells `assignmentTooltipHtml` already had; added to match.
- `capacity_planning_overview` (page 50722) - `eventTooltipHtml(ev)` in
  `capacityPlanningOverview.js`, shared by section 2 (real Scheduler events) AND section 4's chip
  cells (`attachTreeChipTooltip`/`dplTooltipEvent` - a chip = one real Day Planning line). Shell
  `.cpo-event-tip` widened to 285-390px (NOT `.cpo-daily-summary-tip`, the aggregate day-summary
  tooltip sharing the same base rule - deliberately excluded/untouched). `capacity_planning_dashboard`
  (page 50724) inherits this fix for free (explicit JS subclass of capacityPlanningOverview.js,
  loads its style.css by path) but currently has NO reachable single-line tooltip of its own -
  Section 2 doesn't exist on the dashboard tile and Section 4's chips aren't rendered there
  (`attachTreeChipTooltip()` is never called - see that file's own doc comment).
- `dayplanning_sequence` (page 50711) - `showSlotTooltip`/`standardTooltipHtml` in wrapper.js (bar =
  one Day Planning line, per that file's own comment). `showSectionTooltip` (row/sequence
  aggregate: min/max date across many lines) stays excluded, untouched, same shell/element.
- `projectschedule` - `scheduler.templates.tooltip_text` in wrapper.js. Single tooltip, no branches.
- `resourceschedule` - `scheduler.templates.tooltip_text`, DayPlanning branch only (`ev.id` NOT
  starting `"cap_"`); the synthetic `"cap_"` availability/capacity branch is excluded
  (resource-level capacity-slot concept) and kept its own short `.dhx-tt` table (grid narrowed from
  4 to 2 columns since Assigned/Requested columns were dropped from just that branch).
- `resourceschedule_with_capacity` (page 50706) - `scheduler.templates.tooltip_text`, DayPlanning
  branch only (`ev.type !== "capacity"`); the "capacity" branch stays excluded/untouched. This
  add-in had NO tooltip CSS at all before this change (relied on unstyled default DOM) - CSS is
  injected via a `<style>` template literal in wrapper.js itself (not style.css), so the new rules
  were added there too, matching the file's existing convention.

**Explicitly excluded (confirmed by reading code, not assumed):**
- `barchart_daily`/`barchart_weekly` - use dhx.Chart's own generic built-in tooltip (`.dhx_tooltip`)
  for aggregate hours-vs-capacity bar segments; comment literally says "This add-in has no [custom
  tooltip DOM]". No single-line tooltip exists here at all.
- `ganttdemo2` (page 50620 "Gantt Demo DHX 2" - name says "Demo" but is LIVE/searchable,
  UsageCategory=Administration, NOT dead code) - every tooltip is aggregate/unrelated: Gantt task
  bars = one whole Job Task span (`gantt.templates.tooltip_text`, many DP lines), the
  `.gantt_resource_marker` hover shows up to 8 MATCHING Day Planning rows for a resource+date combo
  (resource/capacity-slot aggregate), dependency-link hover, and a "Filter applied:" info bubble.
  None are single-line.
- `poolresourceschedule` (page 50600) - `tooltip_text`'s `"DayPlanning_0"/"DayPlanning_1"` branch IS
  single-line-shaped but is DEAD CODE: `WithDayPlanning` is hardcoded `false`/`False` at EVERY call
  site across the whole codebase (`GetYUnitElementsJSON_Pool`, `GetYUnitElementsJSON_Resource` via
  `GetDayPlanningAsResourcesAndEventsJSon_Resource(...)`), so AL never actually sends such events.
  Left untouched - unreachable code, not worth unifying until someone re-enables it. The "capacity"
  branch stays excluded regardless (capacity-slot).
- `res_scheduler_weekly_factbox` - `tooltip: false` in its scheduler config; no tooltip renders here
  at all.
- `orderintakekanban` - operates on "DayPlanning Order Intake" (a DIFFERENT table/enum, not table
  50610 "Day Planning" itself); also has zero tooltip code regardless.
- `color_picker`/`richtext`/vendored libs (suite.js, dhtmlxscheduler.js, dhtmlxgantt.js, kanban.js) -
  not add-ins with Day Planning content.

**AL changes (codeunit_50604_DHXDataHandler.al)** - new fields added to existing JSON builders,
following the SAME field-naming convention `ReqAssign_BuildDayTaskLineObj` already established
(`'projectName'`/`'taskName'` for Job/Job Task Description, threaded via
`JobDescCache: Dictionary of [Code[20], Text]` / `JobTaskDescCache: Dictionary of [Text, Text]`
var params to avoid one `Job.Get()`/`JobTask.Get()` per row):
- `CPO_BuildDayPlanningLineObj` (+ `CPO_BuildOtherWorkOrderLinesForGroups` and all 3 top-level
  callers: `CPO_BuildPlanningDataJson`, `CPO_BuildPlanningDataJson_Paged`,
  `CPO_BuildOtherWorkOrderLinesJson_ForKeys`) - added `'projectName'`/`'taskName'`.
- `GetYUnitElementsJSON_Project` (both overloads) and `GetYUnitElementsJSON_Project_Paged` -
  `'skill'`/`TEMPJobTasks` (Job Task cache) already existed; added `'job'`/`'jobDescription'`
  (new `JobDescCache`)/`'task'`/`'taskDescription'` (free, from existing `TEMPJobTasks.Description`)/
  `'sequenceNo'`.
- `ResScheduler_AddEvent` (+ both its callers, the 1-param dead-but-compiling
  `ResScheduler_BuildEventsJson(ResourceFilter: Text)` overload and the live 5-param one) - gained
  new params `DayPlanningRec: Record "Day Planning"` + the two cache Dictionaries; added
  `'job'`/`'jobDescription'`/`'task'`/`'taskDescription'`/`'skill'`/`'sequenceNo'`.
- `SkillResScheduler_BuildDayPlanningJson` and `ResGroupResScheduler_BuildDayPlanningJson` (both
  called live from page 50706, toggled by view mode) - `'skill'`/`'job_no'`/`'job_task_no'` already
  existed (snake_case, unlike the newer camelCase fields); added `'jobDescription'`/
  `'taskDescription'`/`'sequenceNo'`.
- `codeunit_50695_DayPlanningSequenceMgt.al`'s `BuildSectionsAndEventsJson` - added
  `'job'`/`'jobDescription'`/`'task'`/`'taskDescription'`/`'sequenceNo'`/`'assignedStartTime'`/
  `'assignedEndTime'`/`'assignedResourceNo'` to each EventObj (Job/JobTask description looked up
  ONCE per call, not cached-per-line, since this page is always scoped to one [JobNo, JobTaskNo]
  pair).

Full build clean (`al_compile`/`al_build`, 0 errors/warnings) after these changes. All edited JS
files also passed `node -c` syntax checks (AL's compiler doesn't touch .js files at all).

**Judgment calls worth knowing:** dropped extra columns/rows some add-ins already had beyond the
reference's own 2-row Request/Assigned table (e.g. projectschedule's old separate Resource No./
Resource Name/Idle Minutes/Hours rows, CPO's old "Amount" column) in favor of literal structural
parity with the reference, per the task's own "consistent look and feel" priority over
"minimalism". Where an add-in's own data genuinely has a concept the reference doesn't (e.g.
projectschedule/resourceschedule_with_capacity's real "Requested Resource" field, vs.
request_assignment's Request side never having a resource concept at all), populated the cell with
real data instead of forcing a hardcoded "—" for its own sake.
