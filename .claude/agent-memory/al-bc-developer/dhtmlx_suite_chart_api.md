---
name: dhtmlx-suite-chart-api
description: Verified DHTMLX Suite 9.x Chart control API facts (grepped from suite.js) — used to build the DHXBarChartAddin proof-of-concept that replaces BC's native BusinessChart on one page
metadata:
  type: project
---

Added 2026-08-04: `src/dhx/barchart/` is a new DHTMLX Suite Chart control add-in
(`DHXBarChartAddin`) proving out a grouped/clustered bar chart as an alternative to
BC's native `BusinessChart` add-in, which [[native-businesschart-usage]] documents as
having NO per-series colour API (2-measure charts always render as two adjacent greys
under the M365 palette). New page 50692 "Requested vs Capacity Skl Dhx"
(`src/dhx/barchart/page_50692_RequestedVsCapacitySkillsDhx.al`, Caption "Requested vs
Capacity (Skills) dhtmlx") is a close clone of page 50690, swapping the
`usercontrol(BusinessChart; BusinessChart)` for `usercontrol(DhxBarChart;
DHXBarChartAddin)` — no `BusinessChartMgt` codeunit involved, JSON built by hand from
`Buffer` via `JsonObject`/`JsonArray`.

**Verified DHTMLX Suite 9.x Chart API** (grepped directly from `src/dhx/suite.js`,
2.2MB minified-but-not-obfuscated webpack bundle — variable/property names are intact,
only whitespace/comments are stripped; do NOT guess this API from memory, grep it):
- Global namespace is `window.dhx` (confirmed via the file's own UMD footer:
  `if (window.dhx){ window.dhx_legacy = dhx; ... }` at the top, `window.dhx = dhx_legacy`
  fallback logic at the bottom `~line 53579`). Chart class is `dhx.Chart`, constructor
  `new dhx.Chart(node, config)` (`node` = a real mounted DOM element for immediate
  render, or `null` to defer — base-app-style code elsewhere in suite.js uses
  `new window.dhx[name](null, config)` for the deferred form).
- `config.type = "bar"` registers the vertical-bar series factory (`bar: Bar_1.default`
  in the chart-type factory map, ~line 13899). `"xbar"` is the horizontal variant.
- `config.data` = plain array of row objects, one row per category, each row has one
  field per series (whatever field name each series' `value` points at) plus an `id`.
- `config.series` = array of `{ id, value, label, color }`. **`color` is fully
  controllable per series** — `Chart.setConfig()` only falls back to
  `getDefaultColor(seriesIndex)` (a 12-colour palette, `defaultColors` array ~line 1810,
  starts `#2A9D8F` teal / `#78586F` mauve / `#E76F51` orange...) when `color` is left
  unset; an explicit `color` always wins. This is the entire reason DHTMLX was chosen
  over BusinessChart for this proof-of-concept.
- `config.scales = { bottom: { type: "text", text: "categoryFieldName" }, left: {
  type: "numeric" } }` — **the `"text"` scale type reads the category field name from
  `config.text`, NOT `config.value`.** This was gotten wrong in the first pass of this
  page (used `value` by analogy with series' `value` field) and caused a real, shipped
  bug: `TextScale.prototype._setDefaults` (suite.js ~line 36023-36032) does
  `this.locator = locator(config.text);` — with `value` set instead of `text`,
  `config.text` is `undefined`, and `locator(undefined)` returns the library's built-in
  fallback `() => ""` (see `locator()`, ~line 1830-1840: `if (!value) return () => ""`).
  Every data row then resolves to the SAME blank category (`""`), so
  `TextScale.point()`'s `this._axis.steps.indexOf(value)` matches every row at the same
  index — all categories collapse onto (effectively) one x-slot, producing exactly the
  symptom reported live: one real cluster plus garbled/ghost bars with heights that don't
  match any real row, most of the plot area empty. **Confirmed by actually executing
  the real `suite.js` in a jsdom harness** (not just reading the source) — see the
  root-cause verification note below. `left`/`right`/numeric scales are unaffected by
  this — they don't take a `text`/`value` field at all, they aggregate y-values from
  every series attached to them via `chart.getPoints()`.
- **Legend text comes from `series[].label`, NOT `series[].name`** — confirmed by
  reading `Legend.prototype._getData()`'s plain (non-treeMap) branch (~line 13508-13524):
  `text = label && typeof label === "function" ? label(...) : label || value`. Also
  requires `config.legend = { series: [seriesId, ...] }` (an explicit array of the
  `series[].id` values) — `Legend`'s constructor only builds `$seriesInfo` when
  `legendConfig.series` is set (`Chart.setConfig`, ~line 13167-13171), so without it the
  legend silently renders nothing for a plain bar/line chart. (There IS a `serie.name ||
  serie.id` fallback at ~line 13481, but that's inside the `treeSeries`/treemap-specific
  branch, not the one a regular multi-series bar chart hits — don't be misled by it.)
- Multiple non-stacked `"bar"` series sharing the same scale render side-by-side
  (clustered) automatically — `Bar.prototype.seriesShift(shift)` exists specifically so
  the scale/stacker layer can offset each series' bars from center; no separate
  "grouped" chart type or manual x-offset math is needed, just register N `"bar"` series
  with `stacked` left falsy.
- Click handling: `chartInstance.events.on("serieClick", function(id, value) {...})` —
  `.events` is a public property (`this.events = new EventSystem(...)` set directly on
  the instance in the constructor, same pattern as other Suite widgets e.g.
  `filter.events.on("change", ...)`). Fired from `Bar._getForm()`'s per-point `onclick`
  handler (~line 14330): `id` = the clicked data row's `id` field, `value` = the
  clicked series' `config.value` (i.e. the field name, not the label) — NOT a
  JsonObject/point payload the way BusinessChart's `DataPointClicked(Point: JsonObject)`
  event works, so don't assume the same shape when wiring `OnDataPointClicked`.
- `Chart.prototype.setConfig()` (public, called internally by the constructor too)
  rebuilds series/scales/legend from a config, but does **NOT** touch `this.data`
  (data is parsed only in the constructor path, `this.data.parse(config.data)`). Given
  that ambiguity, `src/dhx/barchart/wrapper.js`'s `RenderChart()` sidesteps it entirely
  by destroying (`chartInstance.destructor()`) and reconstructing a brand-new
  `dhx.Chart` on every `LoadData()` call rather than trying to mutate an existing
  instance's data in place — safer, and matches this project's established "wipe and
  rebuild" DOM convention (e.g. `BuildResourcePanel` in
  `src/dhx/resourceschedule/wrapper.js`).

**Root-cause verification technique (established 2026-08-04, use again for any future
DHTMLX/suite.js rendering bug before trusting a source-read alone):** grep-reading
minified-but-unobfuscated suite.js is good enough to find candidate config shapes, but
is NOT sufficient to trust blind — this exact page shipped with a wrong scale-config key
(`value` instead of `text`) despite a careful grep-based first pass, because nothing
about reading the source alone surfaces which config key silently no-ops vs. throws. The
reliable way to actually prove a `dhx.Chart` config renders correctly: set up a throwaway
Node + `jsdom` harness (`npm install jsdom` in a scratch folder, NOT inside this repo),
stub `global.window`/`global.document` from a `JSDOM` instance before `require()`-ing
`suite.js` (the file's UMD wrapper reads a bare `window` global at module-load time, line
12: `if (window.dhx){...}`, so `window` must exist before requiring it), stub
`HTMLCanvasElement.prototype.getContext` (suite.js calls a real 2D context to resolve
point-marker colours via `getRgbaFromColor`, which jsdom doesn't implement without the
native `canvas` package — a tiny fake with `fillStyle`/`fillRect`/`getImageData` is
enough), then actually `new dhx.Chart(container, config)` with the EXACT config JSON the
AL/JS pipeline produces and inspect `chart._series[id].dataReady()` (raw per-row
`[x,y,id,...]` tuples) and `chart._scales.bottom._axis.steps` (after calling
`scaleReady(sizes)`) directly — these are plain-object outputs, no real SVG/layout needed,
so jsdom's lack of layout engine doesn't get in the way. Getting full `<path>` SVG output
to actually appear in the DOM requires driving the library's async
mount/resize/paint scheduling (didn't fully chase this — not needed once the raw
scale/series data was proven correct), but `ScaleSeria._calckFinalPoints(width, height)`
can be called directly for pixel-level (x_px, y_px) confirmation without any DOM commit
at all, which is what actually proved this fix.

**Legend DOM structure** (added 2026-08-10, grepped directly from `src/dhx/suite.js`, used to
build `ApplyLegendSwatchBorders` in `src/dhx/barchart/wrapper.js`, a post-render patch that red-
borders legend swatches for series with their own de-duped `border`-flavored legend slot):
- `Legend.prototype.paint()` (~line 13330-13439) renders the whole legend as one
  `<g aria-label="Legend">` wrapper. Each entry inside it is a `<g class="legend-item ...">
  role="button" aria-label="Show chart <label>"` (or `"Hide chart <label>"` once toggled off via
  click — `getLegendAriaAttrs`, ~line 13332), containing a `<text class="start-text legend-text">`
  whose rendered `textContent` (via a child `<tspan>` from `verticalCenteredText()`, ~line 1949)
  equals that entry's `label` — and a swatch shape from `legendShape()` (~line 35684).
- Swatch shape defaults to `<rect class="figure ...">` (`class="figure with-stroke"` when a stroke
  colour is set, else `"figure "`) — `Legend`'s own `defaults` object (~line 13274) sets
  `form: "rect"` and nothing in this project's chart config (`RenderChart`'s `legend` block) ever
  overrides `form`, so every legend built here uses the rect swatch, not circle/line.
- `Legend.prototype._getData()`'s plain-series branch (~line 13508-13524, the one a regular
  multi-series bar/line chart hits — not the `treeSeries`/pie/scale branches) builds one legend
  entry per id in `config.legend.$seriesInfo` (itself built from `config.legend.series`, the
  explicit id array — see the "Legend text comes from series[].label" bullet above), in that same
  array order — so DOM order of `.legend-item` groups matches `config.legend.series` order 1:1.
  BUT matching swatches by rendered label text (not DOM index) is more robust and is what
  `ApplyLegendSwatchBorders` actually does, since the whole point of the upstream label-based
  de-dup (`RenderChart`'s `legend.series` builder) is that every legend entry's label is already
  guaranteed unique.
- SVG shapes ignore the CSS `border` property — only `stroke`/`stroke-width` (as attributes OR
  inline `style.stroke`, which always wins over `legendShape`'s own `stroke="none"` presentation
  attribute default) actually paints an outline on a `<rect>`/`<circle>`. Confirmed by reading
  `forms.rect` (~line 35641-35652) directly — it sets `stroke`/`stroke-width` attributes, never
  a `border`-anything, on the swatch `<rect>` it returns.

**How to apply:** If DHTMLX Suite Chart is used for another chart type (line, area, pie,
scatter, treeMap...) on a future page, re-grep `suite.js` for that specific chart type's
factory/config shape rather than assuming it matches `"bar"` — `Chart.setConfig()`'s
per-type `switch (serieConfig.type)` block (~line 13109-13134) shows `"pie"`-family and
`"scatter"` need different default-colour fields (`pointColor` for scatter, no
color-defaulting shown at all for pie in that switch) and `"treeMap"` has a completely
separate legend code path (`legendType`/`treeSeries`, see above) — don't assume the bar
chart's `series[].color`/`label`/`legend.series` recipe carries over unchanged.
