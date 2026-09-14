---
name: project_cpo_perf_fix_2026-09-14
description: Capacity Planning Overview (page 50722) RefreshData perf fix - CalcCapacitySplit per-day uncached scan + CPO_BuildResourcesArray N*M lookups fixed; older shortage-engine memory is stale
metadata:
  type: project
---

**Context:** [[project_capacity_planning_overview_skeleton]] describes an older "simple per-skill
CPO_CalcSkillAvailability" shortage engine (CPO_BuildStatsRowsArray/CPO_BuildCapacityBarsObj/
CPO_BuildTreeNodesArray/CPO_BuildTreeCellsObj) - **none of those procedures exist anymore.**
`codeunit_50604_DHXDataHandler.al`'s own CPO_ region header (~line 6493) documents an explicit
2026-09-02/03 architecture pivot: AL now just emits a flat payload (skills[]/resources[]/
baseCapacity/externalFree[]/groups[]/dayPlanningLines[]/workOrderSequences[]) and a ported
client-side max-flow engine (capacityPlanningOverview.js) computes shortage/coverage/the tree
itself. Any future perf or correctness work on this add-in should read the CURRENT code
(CPO_BuildPlanningDataJson_Paged, the real RefreshData() entry point) rather than trust the older
memory's procedure names.

**Perf investigation (2026-09-14, page 50722 slow-to-open / "reduced functionality" warning) found
two real server-side costs and fixed both, JSON-contract-safe (no field renamed/added/
restructured):**

1. **`CalcCapacitySplit` (`src/dhx/barchart_weekly/codeunit_50662_SkillCapacityAnalysisMgt.al`)
   was an uncached, company-wide "Res. Capacity Entry" FindSet filtered to a SINGLE Date, called
   once per calendar day from `CPO_BuildDailyCapacityArray`'s day loop (up to "Days to show" days,
   default 30) - unlike the sibling `GDayPlanningBuf`/`EnsureDayPlanningBuffer` pattern, which
   already buffers the whole date range once. Fixed by adding an analogous
   `GResCapacityBuf`/`EnsureResCapacityBuffer` buffer (loaded once per range from inside
   `EnsureDayPlanningBuffer` itself, since every caller already invokes that with the same
   DateFrom/DateTo it later loops CalcCapacitySplit over); `CalcCapacitySplit` now reads the
   buffer instead of the physical table. Cuts N per-day company-wide scans down to 1 per
   RefreshData call.

2. **`CPO_BuildResourcesArray` (`codeunit_50604_DHXDataHandler.al`)** had a second loop doing
   `ResourceOrder.Count() * ActiveSkillList.Count()` individual `ResourceSkill.IsEmpty()` round
   trips (one per resource-skill pair) - cheap when ActiveSkillList was WorkOrder-scoped, but the
   2026-09-03 cross-WO pivot made ActiveSkillList the UNION of every skill demanded company-wide in
   the visible window, so this could be thousands of round trips. Fixed: one `FindSet()` per
   resource (Type+No. only, no skill filter) into a `Dictionary of [Code[20], Boolean]`, then
   filtered/ordered against ActiveSkillList in memory - same output order/content, O(resources)
   round trips instead of O(resources*skills).

**Confirmed NOT a concern (deliberately left alone):**
- `CPO_ScanOtherWorkOrderGroups`/`CPO_BuildOtherWorkOrderLinesForGroups` full company-wide,
  date-bounded (not Job/Task-scoped) "Day Planning" scans, done twice (cheap pre-scan + expensive
  paginated build) - this is an EXPLICIT, documented, user-accepted tradeoff (own code comments:
  "the user explicitly accepted a slower page load for this correctness") tied to the Pass-3
  cross-WO-scope fix - not touched, don't "fix" this without asking first.
- Pass 1+Pass 2 double-scan of the inspected Job Task's own Day Planning lines - bounded to one
  Job Task's own rows, trivial at scale, left alone.
- `CPO_BuildGroupsArray`'s `ActiveSkillList x GroupSkill` nested loop - pure in-memory AL `List`
  iteration, no DB round trips; the "O(lines²) tree building" concern from the OLD memory doesn't
  apply to the current replacement (CPO_BuildTreeNodesArray/CPO_BuildTreeCellsObj are gone).
- `CPO_BuildDayPlanningLineObj` already caches Job/Job Task description lookups via
  JobDescCache/JobTaskDescCache - no fix needed.

Compiled clean (al_compile, onlyErrors=true) after both fixes; not built/published/verified live
per explicit instruction to stop at compile - user verifies manually.
