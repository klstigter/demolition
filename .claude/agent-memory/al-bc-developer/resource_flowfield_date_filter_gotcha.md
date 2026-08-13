---
name: resource-flowfield-date-filter-gotcha
description: Resource."Capacity"/"Assigned Hours" FlowFields require the record's own "Date Filter" FlowFilter set before calcfields(), or they silently sum ALL dates ever
metadata:
  type: feedback
---

The standard `Resource."Capacity"` FlowField and the custom `Resource."Assigned Hours"` FlowField
(tableext_50603_Resource.al field 50610) both have `CalcFormula` filters like
`WHERE(..., Date = FIELD("Date Filter"))`. If you `calcfields()` on a Resource record (e.g. a
`TempResource` built just to hold a "No." for lookup) without first setting `"Date Filter"` via
`SetRange`, the FlowField silently sums **all dates in history**, not the single day you intended.
This is a real, easy-to-miss bug pattern in this codebase - `codeunit_50662_SkillCapacityAnalysisMgt.al`'s
dead/orphaned `CalcFreeCapacity`/`BuildSkillBuffer` procedures have exactly this bug (never fixed,
since they're unused by any live page).

**Why:** Discovered while implementing the true-capacity fix for the "Requested Hours vs Capacity"
bar chart (2026-08, branch `BarChart-Capca-versus-Requested`). The standard Capacity Overview
codeunit (`codeunit_50694_CapacityOverviewMgt.al`) avoids this entirely by reading
`"Res. Capacity Entry"` directly with a plain `SetRange(Date, ...)` instead of going through the
Resource FlowFields - confirmed this is the correct/established pattern for per-day capacity math
in this codebase.

**How to apply:** Whenever building per-day (or per-date-range) resource capacity/assigned-hours
logic, either (a) set `"Date Filter"` explicitly on the Resource record before `calcfields()`, or
(b) prefer reading `"Res. Capacity Entry"` / `"Day Planning"` directly with `SetRange(Date/"Plan Date", ...)`
and summing in AL - the latter is what `codeunit_50694_CapacityOverviewMgt.al` does and what the new
`CalcCapacitySplit` procedure in `codeunit_50662_SkillCapacityAnalysisMgt.al` now does too. Don't
copy `CalcFreeCapacity`'s pattern without adding the Date Filter fix.
