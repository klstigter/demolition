---
name: project_cpo_dashboard_section4_flatten
description: Capacity Planning Dashboard (page 50724) — 2026-09-11 Section 4 simplification (flat Skill-only list, no Job/Task drilldown/Expand-Collapse) backed by new SQL-aggregated query 50713, replacing the paginated per-line CPO_BuildDashboardDataJson_Paged. Page 50722/capacity_planning_overview untouched.
metadata:
  type: project
---

**Scope of this change:** ONLY page 50724 "Capacity Planning Dashboard" (Role Center tile),
controladdin `DHXCapacityPlanningDashboardAddin`, and `src/dhx/capacity_planning_dashboard/*`
(`capacityPlanningDashboard.js` subclass, `wrapper.js`, `style.css`), plus additive changes to
shared codeunit 50604 "DHX Data Handler" and a new Query object. Page 50722 "Capacity Planning
Overview" and everything under `src/dhx/capacity_planning_overview/` (the shared base class
`capacityPlanningOverview.js`, `codeunit_50722_CPOBGOtherWorkOrderData.al`, that page's own
pagination/RefreshData) are 100% UNCHANGED — that page's Section 4 still has its full
Skill->Job/Task->Sequence drilldown with Expand/Exp. to Task/Collapse, per
[[project_capacity_planning_overview_skeleton]]/[[project_cpo_cross_wo_scope_fix]].

**What changed on the dashboard tile:** Section 4 (the tree below the "Hours overview" bars) went
from a 3-level Skill->Job/Task->Sequence drilldown tree (with Expand/Exp. to Task/Collapse buttons)
to a FLAT list of Skills only — no Job/Task columns, no expand/collapse, no per-sequence chips. The
3 toolbar buttons (`#cpo-expand-all`/`#cpo-expand-to-task`/`#cpo-collapse-all`, rendered inside
Section 3's own `.cpo-daily-chart-total-actions` div by the SHARED base class's
`renderCapacityBars`) are removed via a dashboard-only override that calls `super.renderCapacityBars()`
then strips that div — required on every render, not just once, since the base method rebuilds
`host.innerHTML` from scratch every refresh.

**New Query 50713 "Day Planning Skill Day Hours"** (`src/query/query_50713_DayPlanningSkillDayHours.al`)
— `Day Planning` grouped by `Skill` + `Plan Date` (filters `SkillFilter`/`PlanDateFilter`), `Sum("Requested
Hours")`/`Sum("Assigned Hours")` computed in SQL. Next free query ID at the time was 50713 (highest
existing was 50712 "Day Planning By Job Task"; 50600-50609 are also taken — always re-grep
`^query \d+` under `src/query/` before reusing a number, don't trust this note forever).

**New codeunit 50604 procedures (CPO_ region, appended where `CPO_BuildDashboardDataJson_Paged`
used to be — that procedure was DELETED, not left dead, since it had exactly one caller (page
50724) and that caller now calls something else; confirmed via full-repo grep before deleting):**
- `local procedure CPO_RunSkillDayHoursQuery(StartDate; EndDate; var ActiveSkillList; var
  SkillDayHoursArr: JsonArray; var DayPlanningLinesArr: JsonArray)` — runs the query ONCE and
  builds BOTH shapes a caller needs from it (no double query execution, no JSON-text round trip).
- `procedure CPO_BuildDashboardSkillHoursJson(StartDate; EndDate): Text` — the user-specified lean
  shape: `{"skillDayHours":[{skill,date,requested,assigned},...],"skills":[{code,color,textColor,
  border,dark,light},...]}`. `skills[]` reuses the existing shared `CPO_BuildSkillsArray` helper
  (same one page 50722 uses) fed by the query's distinct-skill list — this is how skill
  ORDER/COLORS are preserved without `groups[]` (which is no longer sent at all for this tile).
- `procedure CPO_BuildDashboardDataJson(NumberOfDays): Text` — the FULL replacement payload page
  50724 now calls: `daysToShow`/`startDate`/`endDate`/`workdays` (unchanged builders), `skills[]`/
  `resources[]` (`ApplyPerSkillCap=false`)/`baseCapacity`/`externalFree[]`/`dailyCapacity[]` (all
  UNCHANGED separate builders — `CPO_BuildResourcesArray`/`CPO_BuildExternalFreeArray`/
  `CPO_BuildDailyCapacityArray` — Section 3's capacity side was explicitly out of scope), plus the
  new `dayPlanningLines[]`/`skillDayHours[]` from `CPO_RunSkillDayHoursQuery`, plus an always-empty
  `workOrderSequences[]` (parity with the old procedure — there is no Section 2 on this tile).

**JUDGMENT CALL — why `dayPlanningLines[]` is STILL sent (not just `skillDayHours[]`):** Section
3's `dailyCapacityRequestData()` (shared `capacityPlanningOverview.js`, NOT touched — explicit
scope constraint) reads `this.db.dayPlanningLines` for its "Requested" bar's per-skill breakdown,
and that function's own code was off-limits to edit. Since it only ever SUMS
`requestedHours`/`assignedHours` per skill+day (never reads job/task/sequenceNo/id/workOrderNo on
this tile), `dayPlanningLines[]` is now populated with ONE PRE-AGGREGATED ROW PER (Skill, Plan
Date) — same field names (`requestDate`/`requestedSkill`/`requestedHours`/`assignedHours`) as the
old per-line shape, built in the SAME query pass as `skillDayHours[]` — instead of one row per real
Day Planning line. This produces byte-identical `request`/`unassignedBySkill` sums to before. The
ONE narrow, documented exception: that function's `assignedRequest` used to sum
`Math.min(requestedHours, assignedHours)` PER LINE; with one aggregated row per skill+day it
becomes `Math.min(sum requested, sum assigned)` for the whole day — these two only differ when one
individual Day Planning line is itself over-assigned (Assigned Hours > Requested Hours on that one
line) while a DIFFERENT line for the same skill+day is under-assigned on the same day. Flagged, not
silently accepted — see the doc comment on `CPO_BuildDashboardDataJson` itself.

**JS changes — `src/dhx/capacity_planning_dashboard/capacityPlanningDashboard.js`:**
- `applyPlanningData` override now also clears a new `this._dashSkillDayIndex` cache BEFORE calling
  `super.applyPlanningData()` (must happen before, since super's own call chain ends by calling
  the now-overridden `renderCentralTree`, which reads that cache).
- `renderCapacityBars(json)` — new thin override: `super.renderCapacityBars(json)` then removes
  `.cpo-daily-chart-total-actions` from `#cpo-capacity-bars`. The base class's `bindHierarchyButtons()`
  still runs first (inside super) and briefly wires the buttons before they're removed — harmless,
  not worth a separate override to prevent.
- `buildCentralSections()` — overridden to return flat `{key,section_id,label,skill,type:'skill'}`
  nodes from `this.skills` (NOT `this.db.groups`, which AL no longer sends for this tile).
- `dashSkillDayIndex()` (new) / `skillDaySummary(skill, idx)` (overridden) — O(1) lookup built
  once per render from `this.db.skillDayHours`, replacing the base class's
  `treeSummaryIndex()`/`skillDaySummary()` which scanned `dayPlanningLines[]`.
- `centralTreeLeftColumnHtml(o)` — overridden to a single `.cpo-dash-skill-cell` div instead of the
  base's 3-span `.cpo-central-left-grid`.
- `renderCentralTree(json)` — WHOLE-METHOD override (the base method isn't decomposable into a
  smaller hook — its `columns[]` header/cell-value template are inline in one `createTimelineView`
  call). Same Scheduler plugins/config/teardown/height-sync calls as the base; only real diffs: a
  single "Skill" column, `centraltree_cell_value` only has the flat-skill branch (no
  'detail'/'sequence' cases can occur), and `attachTreeChipTooltip()` is NOT called (no
  `.cpo-tree-chip` elements exist on this tile any more — no sequence leaf rows).

**CSS — `src/dhx/capacity_planning_dashboard/style.css`:** new `.cpo-dash-central-left-header`/
`.cpo-dash-skill-cell` classes (flat single-column layout) rather than reusing the shared
`.cpo-central-left-grid` (a 3-column `176px 92px 92px` CSS grid) with only 1 populated cell, which
would leave dead blank grid space on the right instead of a clean single-column row.

**Pagination/background-task removal (page 50724, controladdin, wrapper.js):** Removed entirely
for this tile — `EnqueueOtherWorkOrderDataBackgroundTask` procedure, `OnPollOtherWorkOrderDataResult`/
`OnPageBackgroundTaskCompleted`/`OnPageBackgroundTaskError` triggers and their backing vars
(`OtherWorkOrderDataTaskId`/`PendingOtherWorkOrderDataJson`/`PendingOtherWorkOrderDataAvailable`)
from the page; `AppendOtherWorkOrderData`/`NotifyOtherWorkOrderDataTaskPending`/
`StopOtherWorkOrderDataPolling` procedures + `OnPollOtherWorkOrderDataResult` event from the
controladdin declaration; the matching `window.*` functions + poll-timer vars from `wrapper.js`.
The shared background codeunit "CPO BG Other WO Data" (`codeunit_50722_CPOBGOtherWorkOrderData.al`)
and its `CPO_BuildOtherWorkOrderLinesJson_ForKeys`/`CPO_ScanOtherWorkOrderGroups`/
`CPO_BuildOtherWorkOrderLinesForGroups`/`CPO_BuildGroupsArray` in codeunit 50604 were NOT touched —
confirmed via grep they're still exclusively used by page 50722's own `CPO_BuildPlanningDataJson_Paged`.

**Compile/build status (2026-09-11):** `al_compile`/`al_build` both clean, zero errors, zero new
warnings (pre-existing AL0640 XML-doc-comment warnings elsewhere in the 7000+-line codeunit file,
at lines 3989-6023, unrelated to this change). Per standing user preference
([[feedback_no_publish_when_told]]/[[feedback_skip_publish_verification_on_request]]), NOT
published or Playwright-verified this session — user verifies manually.

**If asked to touch this tile again:** Section 4 is now permanently flat/Skill-only by design (not
a temporary simplification) — don't reintroduce Job/Task drilldown here without being asked; that
behavior lives on page 50722 only. Section 3's `dayPlanningLines[]` consumption
(`dailyCapacityRequestData()`, shared base class) is still technically "only needs skill+day
aggregates" per its own doc comment — a real, still-unclaimed future optimization opportunity, but
explicitly out of scope both in the original CPO work and in this pass.
