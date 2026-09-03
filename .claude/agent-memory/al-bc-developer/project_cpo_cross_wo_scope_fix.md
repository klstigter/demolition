---
name: project_cpo_cross_wo_scope_fix
description: Capacity Planning Overview (page 50722) — 2026-09-03 fix making dayPlanningLines[]/groups[] span all Work Orders in the visible date window while keeping each section correctly scoped; supersedes the older project_capacity_planning_overview_skeleton note's WO-only-scoped data model
metadata:
  type: project
---

**Context:** [[project_capacity_planning_overview_skeleton]] describes the original build (steps
1-5) using the now-superseded simple "sum team capacity minus other-WO-assigned-hours" formula.
That was later REPLACED (per the codeunit's own "ARCHITECTURE PIVOT (2026-09-02)" comment at the
top of the CPO_ region in `codeunit_50604_DHXDataHandler.al`) by a near-verbatim port of a
reference prototype's client-side max-flow shortage engine
(`src\dhx\capacity_planning_overview\capacityPlanningOverview.js` -
`maxFlowDay`/`evaluateWO`/`currentPositionShortage`) - AL's job shrank to building one JSON payload
(`skills[]`/`resources[]`/`baseCapacity`/`externalFree[]`/`groups[]`/`dayPlanningLines[]`/
`workOrderSequences[]`) shaped like the reference's own mock data, and JS computes everything else.
No memory entry documented that pivot by name before this one.

**This session's fix (2026-09-03):** the user found that `dayPlanningLines[]`/`groups[]` were
STILL scoped to only the inspected Work Order (`SetRange("Work Order No.", WorkOrderNo)`), so
opening the overview for a small WO (e.g. DWO0008, ~24h demand) had zero visibility into
competing demand from any OTHER Work Order (any Job) sharing the same resource pool in the same
visible window. Original ask was "broaden the invisible demand only, keep Section 2/4 WO-scoped" -
mid-task the user corrected this to: **Section 4 (Skill->Job/Task->Sequence tree) must ITSELF
visibly render ALL OTHER Work Orders' data in the window, EXCLUDING the inspected WO** (Section 2
keeps showing only the inspected WO). Their exact words: "section 3 for DWO0008 but section 4 for
all day planning data in days time frame except DWO0008" - and they explicitly accepted a slower
page load (company-wide, date-bounded scan every refresh) for this correctness.

**Final design (`codeunit_50604_DHXDataHandler.al`, `CPO_BuildPlanningDataJson`):**
- Pass 1 (unchanged in shape): `SetRange("Work Order No.", WorkOrderNo)` - still builds
  `dayPlanningLines[]` entries for the inspected WO's own lines, `ActiveSkillList`, and
  `SeqOrder`/`Seq*` (-> `workOrderSequences[]`, Section 2 - untouched, still WO-only).
- **REMOVED** from Pass 1: the old `GroupOrder`/`GroupSkill`/`GroupJobNo`/`GroupJobTaskNo`/
  `GroupDescription` dedup (used to feed `groups[]` from the inspected WO's own data - no longer
  correct).
- **NEW Pass 3:** a second, company-wide `Record "Day Planning"` query -
  `SetFilter("Work Order No.", '<>%1', WorkOrderNo)` + `SetFilter(Skill, '<>%1', '')` +
  `SetRange("Plan Date", StartDate, EndDate)` (same `SetLoadFields` list as Pass 1, plus
  `"Work Order No."` itself) - appends every qualifying line into the SAME `dayPlanningLines[]`
  array, folds new skills into `ActiveSkillList` (broadens `skills[]`/`resources[]`/
  `externalFree[]` too - safe, see below), and populates the SAME `GroupOrder`/`GroupSkill`/etc.
  Lists (repurposed, not renamed) so `groups[]` is now built EXCLUSIVELY from other-WOs' data via
  a new `OtherSkillList` (skills seen only in Pass 3 - narrower than the broadened
  `ActiveSkillList`, used only so Section 4 doesn't render an empty skill header for a skill only
  the inspected WO uses).
- `CPO_BuildDayPlanningLineObj` gained a `'workOrderNo'` field (`DayPlanning."Work Order No."`) -
  now load-bearing since `dayPlanningLines[]` mixes two WOs' rows in one array.

**Why broadening `ActiveSkillList`/`resources[]`/`externalFree[]` is safe for the inspected WO's
own shortage number:** `evaluateWO`/`currentPositionShortage` in the JS only ever compute a
BEFORE/AFTER delta (`maxFlowDay` called twice with the identical resource+skill graph, differing
only in the inspected WO's own `workOrderExtra` demand term) - any foreign-skill resources/demand
present identically in both calls cancels out in the subtraction. Verified by reading
`evaluateWO`/`currentPositionShortage`/`currentPositionSkillShortage` directly
(`capacityPlanningOverview.js` ~L421-475) before relying on this.

**A necessary, scope-conflicting JS change was also required** (the original task said "read-only,
don't edit the JS file" - that held until the Section-4 correction revealed a real structural
conflict): Section 3 (`capParts`/`dailyCapacityRequestData`, the "Capacity vs Requested" bars) has
ZERO WO-scoping of its own - it reads `this.db.dayPlanningLines` and buckets purely by day+skill,
no job/task/WO filter at all. Once `dayPlanningLines[]` carries both WOs' rows, Section 3's
"Requested" bar would silently become company-wide too unless given something to filter on. Fix
applied in `capacityPlanningOverview.js`:
- `dailyCapacityRequestData()`'s demand loop: added `if (line.workOrderNo !== woNo) return;`
  (`woNo = this.db.workOrder && this.db.workOrder.no`) - keeps ONLY the "Requested" bar scoped to
  the inspected WO. `capParts()`'s `assigned`/`freeInt` total (the capacity side) was deliberately
  LEFT UNFILTERED - a resource committed to another WO that day is genuinely unavailable, so that
  side was already correctly company-wide by design before this change.
- `workOrderAssignmentState` (Section 2): added `line.workOrderNo === woNo` to its filter - guards
  against a coincidental Job/Task/Skill/SequenceNo collision between the inspected WO and another
  WO now sharing the same array.
- `skillDaySummary`/`taskDaySummary`/`sequenceDayLines` (Section 4): added the OPPOSITE check
  (`line.workOrderNo !== woNo`, or in `sequenceDayLines`'s single-expression filter, `!==`) for the
  same collision-guard reason, mirrored.

**If asked to touch this add-in again:** `groups[]`/`OtherSkillList` = "all other WOs in window",
`workOrderSequences[]`/`SeqOrder` = "inspected WO only" (Section 2), `dayPlanningLines[]` = BOTH
mixed together and disambiguated purely by the `workOrderNo` tag on each line object - do not
assume any of the three JSON arrays is single-purpose without re-checking which JS function reads
which, since this is the second time this exact file's scope got corrected mid-task.

Compile/build/publish all succeeded clean (zero errors, zero warnings) against
`NL_Copy20240710`/tenant `a60762e1-df10-4e4b-8f44-174c51589110` on 2026-09-03. Not yet
Playwright-verified live (user said they'd verify).
