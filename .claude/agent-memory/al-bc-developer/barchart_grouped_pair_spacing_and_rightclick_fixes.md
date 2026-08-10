---
name: barchart-grouped-pair-spacing-and-rightclick-fixes
description: Live barchart (src/dhx/barchart/wrapper.js) grouped/clustered bar spacing technique, legend hit-testing bug fix, and context-menu listener-leak fix - all 2026-08-10
metadata:
  type: project
---

**Grouped/clustered bar spacing has NO DHTMLX config option - confirmed by direct grep of
suite.js.** `TextScale.point()`/`_getAxisPoint()` position every category strictly uniformly by
index (`index / max`), and `Bar._setDefaults` gives every bar series a single fixed `barWidth`
(30px default, this file never overrides it). So a 14-category "day-pair" trick (categories
"<Wkd>|Capacity"/"<Wkd>|Requested", see [[dhtmlx-suite-chart-api]]) always renders with a UNIFORM
gap between every adjacent bar - no way to make the within-day gap smaller than the between-day
gap using chart config alone. `Stacker` (suite.js's own multi-series-stack class) also has no
`seriesShift` method, so DHTMLX's native side-by-side clustering (via `Bar.seriesShift`, used for
multiple UNSTACKED series sharing a category) does NOT apply to stacked series - only one
`Stacker` instance is ever created per `Chart.setConfig()` call, so two independent stacked-bar
groups per category isn't natively supported either.

**Fix implemented: `ApplyDayPairSpacing()`, a new post-render DOM patch** (same established
technique as `RenderChart`'s pre-existing `ApplySeriesBorders`/`RenderDayGroupRow`) that pulls each
day's 2 bars together toward their own pair-CENTER (left untouched - native ticks are already
evenly spaced by index, so a pair's center is already evenly spaced across days with no shift
needed) via `p.setAttribute("transform", "translate(dx,0)")` on every series' `<path>` at that
flat category index, plus shifting the matching axis `<text>` tick by the same `dx`. Freed-up
space from tightening the pair automatically becomes extra between-day gap - no separate "outer
gap" tuning needed. Constants `PAIR_INNER_GAP_PX` (2) / `BAR_WIDTH_PX` (30, MUST be kept in sync
with any future `barWidth` config change - nothing in the DOM exposes it to read back). Must run
BEFORE `RenderDayGroupRow` in `SchedulePostRenderPatches` (RenderDayGroupRow derives its own layout
from the CURRENT tick x positions). Ticks are queried via `:scope > text.scale-text` (direct
children only) - a plain descendant query would also match `RenderDayGroupRow`'s own previously-
injected nested day-name texts (same class) if it hasn't removed them yet on this pass, throwing
off the count.

**Regression this shipped, then fixed same pass: native "Capacity"/"Requested" tick labels
overlap once pairs are tight** (~16px label slot vs ~50px+ word width) - fixed by changing
`textTemplate` to return just the first letter (`"C"`/`"R"`) instead of the full word. This also
matches standard grouped-bar-chart convention (one category label per GROUP, handled by
`RenderDayGroupRow`'s Mon/Tue/... row - not a repeated sub-label per bar); color (Capacity bars
read blue/green-dominant, Requested read orange-dominant) plus the right-click drilldown carry the
rest of the distinction. Verified via `getBBox()` on all 14 ticks post-fix: zero overlaps, ~10-11px
label width against a 32px slot.

**Legend hit-testing gap - real, systemic, pre-existing bug, root-caused via live probe (not
guessed):** `getBBox()` + `getScreenCTM()`/`elementFromPoint()` against the real rendered chart
showed EVERY legend entry's bbox-CENTER point resolves to the outer `<svg>`, not the
`.legend-item` `<g>` itself - the swatch `<rect>` and `<text>` glyphs only cover PART of the
item's own bbox under default SVG `pointer-events:visiblePainted`, so a click/right-click in the
gap between them (or the vertical margin around the glyph ink) silently falls through. Reproduced
on all 7 legend entries, fresh page load, zero prior interaction - this is why legend right-click
(and, incidentally, left-click hide/show, though nobody had reported that one) failed. Fixed with
`ApplyLegendHitArea()`: inserts an invisible full-bbox `<rect fill="transparent">` with
`style.pointerEvents = "all"` as each `.legend-item`'s FIRST child (paints behind swatch/text, SVG
paint order = DOM order). Standard SVG technique for a fully-transparent-but-clickable overlay.

**Context-menu listener leak - real bug, confirmed root cause, fixed.** Original
`ShowContextMenu`/`HideContextMenu` registered 4 dismiss listeners (`click`/`contextmenu`/
`scroll`/`keydown`) on `document` with `{once:true}` and never tracked/removed them explicitly.
`{once:true}` only self-removes when THAT event type fires - a rapid run of right-clicks with no
intervening left-click/scroll/Escape leaves every prior invocation's `click`/`scroll`/`keydown`
listeners permanently attached (only `contextmenu` self-cleaned, since each new right-click's own
event bubbles to `document` and fires the old one) - unbounded growth. Fixed by tracking the
current handler set in a module var (`contextMenuDismissHandlers`) and explicitly
`removeEventListener`-ing it at the START of every `HideContextMenu()` call (which
`ShowContextMenu` now always calls first, before creating anything new) - caps attached listeners
at exactly one, regardless of dismiss path.

**Verification methodology gotcha (important for next session): a monkey-patched
`document.addEventListener`/`removeEventListener` (used to count listener adds/removes for the
leak-fix verification) left a REAL, PERMANENT mutation on the live iframe document object -
persists beyond the `evaluate()` call since `doc` is a live DOM reference, not a copy. A
SUBSEQUENT real right-click in that SAME long-lived page session then failed to show "Show Data"
at all - looked like a real regression (and WAS reported up as one by the coordinator based on a
user complaint), but reproducing the identical click on a FRESH page reload (no monkey-patching)
worked correctly, as did a 5-click real sequential mixed bar+legend test on that fresh load. Root
cause of the single failure was never fully pinned down (possibly the monkey-patch interfering
with some later internal listener registration) but is clearly a test-scaffolding artifact of
THIS debugging session, not a defect in the shipped code - confirmed by two independent clean
tests passing. **How to apply:** never trust an in-session listener-count instrumentation result
without also re-verifying the actual user-facing behavior via a plain `browser_click` on a FRESH
page load afterward - don't leave `document.addEventListener` monkey-patched on a page you're
about to continue testing normally on.

**Also relevant:** [[dhtmlx-suite-chart-api]] for the underlying Chart/Bar/Stacker/TextScale API
facts this fix was built against. [[mark_markedonly_pagerun_controladdin_broken]] and
[[project_skillcapacitychart_true_capacity_fix]] for other barchart drilldown work on the same
page (50692)/codeunit (50662).
