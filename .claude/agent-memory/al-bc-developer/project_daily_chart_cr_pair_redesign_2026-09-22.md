---
name: project-daily-chart-cr-pair-redesign-2026-09-22
description: barchart_daily "Requested vs Capacity Daily" chart family redesigned from 1-bar-per-skill+synthetic CAPACITY bar to a per-skill Capacity/Requested bar pair (2026-09-22)
metadata:
  type: project
---

Redesigned src/dhx/barchart_daily (pages 50661/50681/50707, codeunit 50608 "SkillCapacityAnalysisMgt.v1", wrapper.js) so every Skill Code gets its own Capacity("C")/Requested("R") bar PAIR, mirroring src/dhx/barchart_weekly's per-day C/R pair shape (see codeunit 50662's BuildDayCapacityChartData) but grouped by Skill Code instead of weekday. The old synthetic company-wide "CAPACITY" bar/marker (CapacitySkillCodeTok, InsertCapacityLine, CalcAggregateCapacity, GetCapacityAssignedFreeSplit) is fully removed from barchart_daily.

**Why**: user's own mockup annotation said "the capacity bar is per respective resource (not skill)" - each skill's own C bar must show the true resource-calendar Assigned/Free-Internal/Free-External-Mandatory/Free-External split, scoped to only the resources holding that skill (via "Resource Skill" table), not a company-wide total. A resource holding multiple skills legitimately contributes to each of those skills' own C bars.

**Key new pieces**:
- codeunit 50662 (barchart_weekly, the one file touched outside barchart_daily) gained `GetSkillCapacitySplitForRangeWithMandatory(SkillCode, DateFrom, DateTo, ...)` + local `BuildResourceSetForSkill`/`CalcAssignedSplitForResourceSet`/`CalcCapacitySplitForResourceSet` - resource-set-filtered twins of the existing `CalcAssignedSplit`/`CalcCapacitySplit`, reusing the shared `GDayPlanningBuf`/`GResCapacityBuf` temp buffers (no per-skill physical table scan).
- codeunit 50608 got a thin forwarding wrapper `GetSkillCapacityAssignedFreeSplit(SkillCode, ...)` calling the above (replaces the old company-wide `GetCapacityAssignedFreeSplit`, only 2 callers, both rewritten).
- `ShowSegmentData` rewritten: bar clicks pass the full category text ("<SkillCode>|Capacity"/"<SkillCode>|Requested") as SegmentId, split via `StrPos`/`CopyStr` on the `|` delimiter; legend clicks pass the clicked SERIES' own name as SegmentId (legend switched from category/barColor-driven to series-driven, matching Weekly). New local `ShowSkillCapacitySegment`/`ShowAllCapacitySegment`/`IsCapacitySeriesName`.
- wrapper.js: ported Weekly's whole post-render-patch pipeline (SchedulePostRenderPatches/chartMutationObserver, ApplySeriesBorders, ApplyLegendSwatchBorders+GetLegendOwnerIndexByLabel, ApplyLegendHitArea, ResolveLegendSegmentFromEvent) plus a renamed `RenderSkillGroupRow`/`ApplySkillPairSpacing` (1:1 ports of RenderDayGroupRow/ApplyDayPairSpacing). Dropped the old data-driven legend (`legend.values`+`row.barColor`+`chartInstance.events.detach("toggleSeries")`) and the -45deg `CATEGORY_LABEL_ROTATE_DEG` rotation (skill code text now lives in the RenderSkillGroupRow group-header row, same as Weekly's plain day-name row).
- `ResolveBarSegmentFromEvent` was deliberately NOT given Weekly's day/2-style even/odd pairing math - Daily's AL-side `ShowSegmentData` signature takes one combined SegmentId text (not separate BarType/dayIndex params like Weekly's), so returning `lastCategories[pIdx]` directly (unchanged from the pre-redesign code) is sufficient and simpler.
- `BOTTOM_SCALE_RESERVED_PX` kept at 90 (unchanged, must stay numerically equal to Weekly's own constant for role-center x-axis alignment - Weekly's wrapper.js is out of scope so this couldn't be revisited even though Daily's own 2 rows now only need 48px).

**Judgment call flagged to user, needs live visual check**: dropped the diagonal label rotation now that skill codes render in their own horizontal group-header row (matching Weekly). With up to ~11 skills x 2 bars = ~22 tightly-packed bars, long Skill Codes could still overlap in that row at default bar width - not verified live (publish/browser forbidden this session per [[feedback_skip_publish_verification_on_request]]).

See also [[dhx_barchart_two_versions]] (barchart_daily/barchart_weekly are both live, not dupes) and [[dhx_daily_weekly_xaxis_alignment_fix]] for prior BOTTOM_SCALE_RESERVED_PX history.
