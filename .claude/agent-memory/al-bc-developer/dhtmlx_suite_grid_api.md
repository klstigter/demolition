---
name: dhtmlx-suite-grid-api
description: Verified DHTMLX Suite 9.3.7 Grid control API facts (grepped from suite.js) - used to build the pivot-style "Chart Audit Trail" FactBox (page 50704, src/dhx/res_scheduler_weekly_factbox)
metadata:
  type: project
---

Added 2026-08-20: `src/dhx/res_scheduler_weekly_factbox/` is a new DHTMLX Suite **Grid**
control add-in (`DHXGridFactboxAddin`) replacing page 50704's old flat AL repeater with a
pivot-style grid (label column + one Requested/Assigned/Sub Total group per weekday + Grand
Total). This is the first use of Suite's Grid widget in this codebase - [[dhtmlx-suite-chart-api]]
covers the Chart widget, verified the same way (grep suite.js directly, don't trust public docs
blindly since this bundle's version may differ).

**Verified DHTMLX Suite 9.3.7 Grid API** (grepped directly from `src/dhx/suite.js`):
- `window.dhx.Grid` is NOT the raw `Grid` class (module 108) - the actual export (confirmed by
  tracing the webpack entry point: bootstrap calls `__webpack_require__(129)`, which does
  `module.exports = __webpack_require__(139)`, and module 139 - the real top-level export table -
  has `exports.Grid = ts_grid_1.ProGrid` from module 63/257) is `ProGrid`, a thin wrapper
  (suite.js ~line 50522) whose constructor picks `TreeGrid` (if `config.type==="tree"` or
  `config.group`) or plain `ExtendedGrid` (module 114, itself `extends Grid_1.Grid` from module
  108) and then does `core_1.extendComponent(this, component)` - copying every property/method
  from the real underlying instance onto itself. Net effect: `new dhx.Grid(container, config)`
  behaves exactly like the real `Grid`/`ExtendedGrid` class for every API below - `.events`,
  `.data`, `.destructor()`, `.paint()`, `.setColumns()` all just work, no extra indirection needed
  in caller code.
- **Multi-row GROUPED headers**: each column's `header` property is an ARRAY, one entry per
  header row, e.g. `header: [{text:"Monday", colspan:3}, {text:"Requested"}]` for the first
  column of a 3-column day group, then `header: [{}, {text:"Assigned"}]` / `header: [{}, {text:
  "Sub Total"}]` for the other two (empty `{}` at row 0 - hidden under the first column's
  colspan). Confirmed via TWO separate code paths, not just the Excel exporter (which also uses
  this shape but could have been export-only): (1) `countColumns` (suite.js ~line 1354-1423,
  called from the Grid class's own render setup) normalizes every column's `header` array up to
  the tallest column's row count, padding short arrays with blank `{text:""}` entries - so a
  column needing only ONE header row (this grid's "label"/"Grand Total" columns) can declare a
  single-entry array with `rowspan:2` and let the normalizer auto-pad row 2; (2) the REAL
  (non-export) header-cell renderer (suite.js ~line 21938, inside the resizer-grip sizing logic)
  reads `column.header[0].colspan` directly to decide how many columns the resize handle spans.
- **Frozen/pinned columns**: `config.leftSplit = N` (or `config.splitAt`, an alias - Grid
  constructor does `config.leftSplit = config.leftSplit || config.splitAt`, suite.js ~line 18248)
  pins the first N columns while the rest scroll horizontally. `config.rightSplit` is the mirror
  for pinning trailing columns. Used here as `leftSplit: 1` to pin the row-label column.
- **Cell click**: `grid.events.on("cellClick", function(row, col, e) {...})` - NOT a coordinate/
  DOM-hit-testing callback like the Chart widget's `serieClick` (see
  [[dhtmlx-suite-chart-api]]'s legend/segment resolvers, which need DOM lookups because Chart's
  click event only carries a bare id). Grid's `handleMouse`/`getHandlers` (suite.js ~line
  6136-6168) locates the clicked DOM cell, then resolves it straight back to the real DATA row
  object (`row`, from `conf.data`/`conf.$data`) and the real COLUMN CONFIG object (`col`, from
  `conf.filteredColumns`) before firing - so a click handler can read `row.id`/custom row
  properties and `col.id` directly, no querySelector needed. Other mouse events follow the same
  `(row, col, e)` shape: `cellMouseOver`, `cellMouseDown`, `cellDblClick`, `cellRightClick`
  (`GridEvents` enum, suite.js ~line 1116 area).
- **Per-cell display formatting**: `column.template = function(value, row, column) { return
  htmlString; }` - confirmed as a real, live (not export-only) rendering hook via multiple call
  sites (suite.js ~lines 1579, 18926, 18971, 23090). Used here to format numbers to 2 decimals and
  to render an intentional blank (not "0.00") for a skill row's "Assigned" cell, since that figure
  is always a meaningless 0 (no per-skill assigned-hours tracking exists in codeunit 50662 - see
  that codeunit's own `CalcAssignedSplit` doc comment).
- Constructor teardown/rebuild convention: same as the Chart widget - `gridInstance.destructor()`
  then a fresh `new dhx.Grid(...)` on every `LoadData()` call, matching this project's established
  "wipe and rebuild" pattern (`RenderChart` in `src/dhx/barchart_weekly/wrapper.js`,
  `BuildResourcePanel` in `src/dhx/resourceschedule/wrapper.js`).

**How to apply:** If DHTMLX Suite Grid is used again elsewhere in this codebase (e.g. a real
editable/sortable/filterable grid rather than this read-only pivot), re-grep suite.js for the
specific config keys needed (editing, sorting, filtering, row/column drag-reorder all have their
own dedicated config surfaces not covered above) rather than assuming the public dhtmlx docs match
this exact 9.3.7 Professional bundle - the ONE deviation already found here (the real export being
`ProGrid`, not the raw `Grid` class) shows this bundle's wiring can differ from what a class name
alone would suggest.
