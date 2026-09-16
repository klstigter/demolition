---
name: project_daily_chart_mandatory_split_mirror_2026-09-16
description: Daily "Requested vs Capacity" chart's CAPACITY bar recomposed to mirror Weekly's Assigned-combined + External-Mandatory split (2026-09-16)
metadata:
  type: project
---

Mirrored Weekly's (page 50692, codeunit 50662) two earlier same-session fixes onto Daily
(pages 50681/50707, codeunit 50608 "SkillCapacityAnalysisMgt.v1"): Assigned Capacity is now
ONE combined series (no Internal/External split, no border) instead of two, and Free Capacity -
External is now split into a Mandatory portion (own color, no border) and a non-mandatory portion
(red border, declared LAST so it stays topmost in the stack).

**Why:** user compared the two charts side-by-side for the same date and found Daily still had
the old bug (2 Assigned series with a red border on the External half) that had already been
fixed on Weekly, plus Daily's Free Capacity - External wasn't split out to show mandatory-
scheduled external capacity separately.

**How to apply:**
- Codeunit 50662 `GetCapacitySplitForRange` (weekly) is now a 2-line wrapper over a new
  `GetCapacitySplitForRangeWithMandatory` (5 out-params incl. `CapacityExternalMandatory`) - the
  wrapper folds mandatory back into External so its 3 existing scheduler-page callers
  (projectschedule/50621, resourceschedule_with_capacity/50706, poolresourceschedule/50600) see
  byte-identical totals. Never change `GetCapacitySplitForRange`'s own signature/behavior again -
  add new callers against the `...WithMandatory` variant instead.
- Codeunit 50662 also gained `GetCapacityMandatoryColor(): Text`, a thin forward to codeunit
  50609's own same-named getter - added so codeunit 50608 (Daily) can go through 50662 rather
  than calling 50609 directly, matching this codebase's established forwarding convention (see
  [[project_colorconstants_codeunit_50609]]).
- Codeunit 50608's `GetCapacityAssignedFreeSplit` gained a `CapacityExternalMandatory` out-param
  (safe - only called by pages 50681/50707) and now calls `GetCapacitySplitForRangeWithMandatory`
  directly (not the folded wrapper), since Daily needs the mandatory portion exposed separately.
- Codeunit 50608's `AddCapacitySegmentSeries` signature changed: `AssInternalValues`/
  `AssExternalValues` collapsed into one `AssignedValues`; gained `CapExternalMandatoryValues` and
  a `CapacityMandatoryColor` param. Old labels `AssInternalSeriesNameLbl`/`AssExternalSeriesNameLbl`
  ('Assigned Capacity - Internal'/'- External') removed (were unused elsewhere), replaced with
  `AssignedCapacitySeriesNameLbl` ('Assigned Capacity') and `CapExternalMandatorySeriesNameLbl`
  ('Free Capacity - External (Mandatory)') - text must stay identical to codeunit 50662's own same
  labels (a documented convention in this file).
- Pages 50681 and 50707's `RefreshChart` are near-duplicate loops - both got the identical
  mechanical edit (combine Assigned, add CapExternalMandatoryValues, fetch
  `GetCapacityMandatoryColor()`, update the `AddCapacitySegmentSeries` call).
- Daily's `ShowSegmentData`/`ShowCapacitySegment` drilldown needed NO changes - it routes purely on
  SegmentId ('CAPACITY' marker vs. skill code) with no per-series discrimination, unlike Weekly's
  drilldown which does discriminate Internal/External/Mandatory. wrapper.js (src/dhx/barchart_daily)
  is also fully generic (series color/border driven entirely by the JSON payload's `s.color`/
  `s.border` keys) - confirmed no JS changes were needed either.
- Totals-equivalence check: both charts' CAPACITY bar totals for one day trace back to the exact
  same `CalcDaySegments`/`CalcCapacitySplit` computation in codeunit 50662 - Daily via
  `GetCapacitySplitForRangeWithMandatory`, Weekly via its own direct `CalcDaySegments` loop in
  `BuildDayCapacityChartData`. No structural divergence found in code (same EnsureDayPlanningBuffer
  buffering, same date-range handling) - the user-reported ~2200 vs ~3400 mismatch for the same
  Wednesday could not be fully verified without live data; if it persists after this fix, suspect
  `EnsureDayPlanningBuffer`'s caching/buffer-reuse behavior across the two charts' different call
  patterns (Daily calls per-row inside a Buffer loop; Weekly calls once per weekday in its own
  loop) rather than a further coloring/labeling issue.
