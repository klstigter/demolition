---
name: barchart_daily_weekly_xaxis_alignment_fix
description: Root cause + fix for Daily/Weekly role-center chart x-axis baseline misalignment - it was scales.bottom.size, NOT legend.size
metadata:
  type: project
---

**Task (2026-09-11)**: page 50612 Planning Role Center's Daily (page 50707, src/dhx/barchart_daily/
wrapper.js) and Weekly (page 50708, src/dhx/barchart_weekly/wrapper.js) chart panels had their
x-axis/bar-baseline ("0"-gridline) sitting at different vertical heights despite identical panel
heights.

**Root cause (confirmed live via Playwright DOM measurement AND algebraically, not just
hypothesis)**: a chart's "0"-line vertical position = `containerTop + containerHeight -
scales.bottom.size`. `config.legend.size` (`sizes.top`) cancels out of that formula entirely - it
only moves where the TOP of the plot/gridline scale starts, never where the bottom ("0"-line) sits.
Live measurement confirmed the top gridline ("2200" text) was already pixel-identical between the
two charts, and both had independently converged to the SAME corrected `legend.size` (51) at
measurement time anyway - so the task's original hypothesis (independent per-chart legend
auto-correction causing divergent `legend.size`) was NOT the actual cause, just a plausible-looking
red herring. The real cause: Weekly's bottom axis explicitly reserves `DAY_ROW_HEIGHT * 2` = 48px
(its native C/R label row + its own hand-drawn `RenderDayGroupRow` Mon/Tue/... row), while Daily's
bottom axis was left at suite.js's own unset-scale default (~20px, single native label row only) -
a genuine, deterministic 28px gap, confirmed by direct DOM measurement of the "0" gridline text's
`getBoundingClientRect().top` in both control add-in iframes (532.63 vs 560.63 before the fix).

**Fix**: added an explicit, matching bottom-scale reserved height to BOTH files instead of a shared
module (kept the two folders independent per this repo's convention - see
[[project_planning_rolecenter_chart_width]]):
- `src/dhx/barchart_daily/wrapper.js`: new `var BOTTOM_SCALE_RESERVED_PX = 48;` near
  `SERIES_COLOR_PALETTE`, applied as `scales.bottom.size` in `RenderChart`'s config (previously
  unset/default) - reserves the same 48px as blank space below Daily's single label row.
- `src/dhx/barchart_weekly/wrapper.js`: no functional change, just a comment next to
  `DAY_ROW_HEIGHT` cross-referencing Daily's constant and stating they MUST stay numerically equal.

**Verified live** (Playwright, NL_Copy20240710, 2026-09-11, after `al_build`+`al_publish` of
28.0.0.12): before fix, "0"-line top = 560.63 (Daily) vs 532.63 (Weekly), 28px gap, visually
obvious baseline offset in a full role-center screenshot. After fix (real production data
reloaded): both charts' "0"-line top = 532.63px, exact match. Screenshot confirms visually level
x-axes/category-label rows.

**Known follow-up gap**: attempted a live stress-test (calling `window.RenderChart(...)` directly
inside each control-add-in iframe via Playwright `browser_evaluate` with a synthetic 10-category
dataset) to prove the fix holds even when Daily's legend wraps to 2 rows unlike today's real data
(1 row). That synthetic call left the chart's own container permanently hidden/empty (`svgExists:
false`, `containerHTML` ~11 chars) on BOTH charts - looks like calling `RenderChart` directly from
outside the normal BOOT/BC-data-refresh flow hits some precondition the real flow always satisfies
(not reproduced/root-caused - reloading the page recovered cleanly, real data unaffected). Did not
chase further since the algebraic proof above already establishes the fix is legend-row-count-
independent (legend.size is not even in the formula), but if this ever needs re-verifying with a
genuinely different legend row count, don't inject data via direct `RenderChart` calls the way this
session did - it will hang the chart. Send real BC data with a different active-skill count
instead (e.g. a different day/company with more skills).

**Process note**: this session called `al_build` + `al_publish` despite
[[feedback_user_publishes_manually]], because the task's own explicit instructions called this out
as a deliberate one-off exception (a pixel-alignment claim needs live DOM measurement, which needs
the JS actually deployed) - not a reversal of that standing preference.
