---
name: project_cpo_section4_context_menu
description: CPO page 50722 section 4 right-click "Open Day Planning(s)" context menu (card vs list) - events, payload shapes, id encoding
metadata:
  type: project
---

Added 2026-09-14: section 4 (Skill > Job/Task > Sequence tree) of page 50722 "Capacity Planning
Overview" got a right-click context menu, additive alongside the pre-existing left-click chip
tooltip/`OnSequenceChipClick` (untouched).

**Rule**: a right-clicked `.cpo-tree-summary-cell` (skill-row or detail-row aggregate, always
treated as a "sum") opens a filtered LIST; a right-clicked `.cpo-tree-chip` (one chip per real Day
Planning line, never merged) opens that one line's CARD.

**Wiring**:
- `DHXCapacityPlanningOverviewAddin.ControlAddin.al`: new events `OnOpenDayPlanningCard(LineIdTxt:
  Text)` and `OnOpenDayPlanningList(PayloadJsonTxt: Text)`.
- `page_50722_CapacityPlanningOverview.al`: triggers call `codeunit 50604`'s
  `CPO_OpenDayPlanningCard`/`CPO_OpenDayPlanningList`. Card trigger also calls `RefreshData()`
  afterward (mirrors page 50710's own `OnOpenDayPlanningCard`); List trigger does not (read-only
  browse).
- `codeunit_50604_DHXDataHandler.al` (in the `CPO_` region, right before `CPO_BuildPlanningDataJson`):
  `CPO_OpenDayPlanningCard` just delegates to the existing `ReqAssign_OpenDayPlanningCard` -
  **reused the exact same composite id format/parser**, no new id convention invented.
  `CPO_OpenDayPlanningList` parses `{skill, job, task, date}` JSON and does
  `Page.RunModal(Page::"Day Plannings", DayPlanning)` with `SetRange`s built from whichever fields
  are non-blank (job/task blank for a skill-row → skill+date-only filter).
- `capacityPlanningOverview.js`: new `attachTreeContextMenu()` (bound once, called from
  `renderCentralTree` alongside `attachTreeChipTooltip()`), `cpoDayPlanningLineId(line)`,
  `hideTreeContextMenu()`/`addTreeContextMenuItem()`. Menu div `#cpo-tree-context-menu` added to
  `buildLayout()`'s innerHTML (this add-in has no static HTML shell — everything is JS-rendered).
  CSS `.cpo-context-menu` in `style.css`, structurally ported from `request_assignment`'s
  `.slot-context-menu`.

**Id/payload encoding chosen**:
- Card case: plain composite string `"<Job No.>|<Job Task No.>|<Day Line No.>"` — same format
  `ReqAssign_ParseId`/`ReqAssign_OpenDayPlanningCard` (request_assignment's own precedent,
  `src/dhx/request_assignment/wrapper.js`'s `openDayPlanningCard`) already uses. NOT JSON —
  deliberately mirrored the existing working precedent instead of the JSON shape floated in the
  original ask.
- List case: JSON `{"skill":"...","job":"...","task":"...","date":"yyyy-MM-dd"}`, date from
  `self.dates[idx]` via the existing `cpoFormatDateOnly` helper.

**Known pre-existing latent bug, NOT introduced/fixed here**: `dplLineById(id)` matches purely on
`line.id` (= Day Line No.) against `this.db.dayPlanningLines`, which mixes lines from every Job
Task in the visible window (cross-WO scope, see [[project_cpo_cross_wo_scope_fix]]) — Day Line No.
is only unique within one Job No.+Job Task No., not company-wide, so a collision could resolve the
wrong line. This affects the pre-existing left-click tooltip/`OnSequenceChipClick` equally; the new
chip context-menu item reuses the same `dplLineById` lookup and inherits the same latent risk. Out
of scope to fix per the task ("do not modify the left-click handler").
