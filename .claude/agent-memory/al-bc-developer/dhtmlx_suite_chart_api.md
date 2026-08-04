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
- `config.scales = { bottom: { type: "text", value: "categoryFieldName" }, left: {
  type: "numeric" } }` — the `"text"` scale type reads `value` as the field name on each
  data row to use as the category label (`TextScale.point()`/`scaleReady()` build an
  ordinal axis from `this._data.map(this.locator)`, where `locator(config.value)` is
  `obj => obj[value]`, ~line 1830-1840 and ~line 35967-36030).
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

**How to apply:** If DHTMLX Suite Chart is used for another chart type (line, area, pie,
scatter, treeMap...) on a future page, re-grep `suite.js` for that specific chart type's
factory/config shape rather than assuming it matches `"bar"` — `Chart.setConfig()`'s
per-type `switch (serieConfig.type)` block (~line 13109-13134) shows `"pie"`-family and
`"scatter"` need different default-colour fields (`pointColor` for scatter, no
color-defaulting shown at all for pie in that switch) and `"treeMap"` has a completely
separate legend code path (`legendType`/`treeSeries`, see above) — don't assume the bar
chart's `series[].color`/`label`/`legend.series` recipe carries over unchanged.
