---
name: project_planning_rolecenter_chart_width
description: Empirical findings on how BC's role-center flex-grid actually sizes side-by-side CardParts (page 50612), and the fix applied for the Daily/Weekly chart blank-space + legend-bleed bugs
metadata:
  type: project
---

**Task**: page 50612 "Planning Role Center" had two CardParts (page 50707 Daily / page 50708
Weekly, each hosting a DHTMLX bar chart) side by side in `area(rolecenter)`, leaving a large blank
area on wide screens (~2200px+) instead of each filling ~50%.

**Empirical finding (live via Playwright, NL_Copy20240710, 2026-09-07)**: control add-in
`RequestedWidth`/`MinimumWidth` have **ZERO effect** on how BC's role-center flex-grid splits width
between sibling CardParts. Tested RequestedWidth 900 -> 1100 -> unchanged, MinimumWidth 400 -> 1000
-> unchanged: rendered width stayed byte-identical (662.984px, `flex-basis: calc(33.3333% -
42px)`). Two un-grouped CardParts in `area(rolecenter)` always get class
`ms-nav-layout-flex-cell-column-max-3` (a FIXED 3-column CSS grid, evidently a platform breakpoint
tied to viewport/content width, not to anything in AL) - with only 2 real parts, the 3rd slot's
worth of space (1/3 of the row) renders as blank. This is a genuine BC web-client platform layout
behavior, not something exposed via any control add-in width property.

**What DOES change the split**: wrapping CardParts in an AL `group()` inside `area(rolecenter)`.
Wrapping BOTH parts in ONE group made the group itself just another "column" item (picked up
`column-max-2` at the OUTER grid level, `flex-basis: 50%` of the row) - but with only 1 group
present, it only claimed half the row, making the blank space WORSE (~1010px blank at 2200px
viewport vs ~705px un-grouped). Fix: wrap EACH part in its OWN separate `group()` (two groups) -
final layout in `src/page/RoleCenter/RoleCenter_50612_PlanningRoleCenter.al`.

**Regression this caused**: at the narrower per-part width, the Daily chart's legend row
(`src/dhx/barchart_daily/wrapper.js`) visually bled/overlapped into the Weekly panel's legend -
NOT a DOM box overlap, but the chart's own SVG legend row-wrapping against a STALE width from its
first paint (before BC's role-center flex layout had settled to its final column split), with no
`overflow:hidden` boundary to contain the bleed. Fixed in both
`src/dhx/barchart_daily/wrapper.js` and `src/dhx/barchart_weekly/wrapper.js`:
1. `overflow:hidden` added to both the `controlAddIn` host div and `#dhx-barchart-container` (hard
   containment boundary, defense-in-depth).
2. A new `lastRenderedWidth` module var (set at the top of every real `RenderChart` call) lets the
   existing BOOT `ResizeObserver` tell a genuine width change (>2px) apart from a same-size DOM
   mutation - a genuine width change now forces a full `RenderChart(lastChartData, lastLegendSize)`
   rebuild (so the legend's row-wrap math runs against the CURRENT real width), instead of only the
   previous legend-text-color/top-overflow patch pass.

**Verification status as of this session's end**: change compiles cleanly (`al_compile` succeeded)
and builds (`Optimizers_DailyOptimizer_28.0.0.12.app`) but was **NOT published or live-verified**
this session - see [[feedback_user_publishes_manually]], the user took over publishing mid-session.
Whoever picks this up next should publish, then re-run the same Playwright live-DOM check (resize
to ~2200x1000, inspect `.control-addin-form` rects/computed `flex-basis` inside the page's iframe,
confirm no legend bleed at the Daily/Weekly boundary) before considering this closed.

**app.json version**: bumped 28.0.0.11 -> 28.0.0.12 partway through this session specifically to
rule out BC web-client metadata caching as a confound while comparing RequestedWidth test values
live (same version number across those particular tests, so that non-effect finding above should
be treated as fairly reliable but not 100% cache-proof - re-verify RequestedWidth's inertness again
if it ever becomes load-bearing for a future fix).
