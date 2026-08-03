---
name: native-businesschart-usage
description: Verified facts about BC's native System.Visualization Business Chart API + why the Skills analysis page uses factboxes for its side-by-side layout
metadata:
  type: project
---

This app has ONE page built on BC's native chart control instead of DHTMLX: page 50690
"Requested vs Capacity (Skills)". Everything else visual in this repo is DHTMLX — do not
mix the two on one page.

**Why:** the user explicitly asked for the native `Business Chart` control (Business Manager
Role Center "Insights" styling) for this analysis page, not DHTMLX.

**How to apply / verified API facts** (all confirmed via `al_symbolsearch` + decompiling
`Microsoft_Base Application_*.app` → `src/HelpAndChartWrapper.Page.al`,
`src/System/OtherCapabilities/Chart/BusinessChartBuffer.Table.al`,
`src/Projects/Project/Analysis/JobChartMgt.Codeunit.al` — see [[project-dailyoptimizer]]'s
decompile-technique note):

- `ControlAddIn BusinessChart` (namespace `System.Integration`) has exactly 4 events:
  `AddInReady()`, `Refresh()`, `DataPointClicked(Point: JsonObject)`,
  `DataPointDoubleClicked(Point: JsonObject)`. None are mandatory to handle.
- `Codeunit "Business Chart"` (`System.Visualization`) call order:
  `Initialize()` → `SetXDimension(Caption; Enum "Business Chart Data Type")` →
  `AddMeasure(Caption; Value: Variant; Enum "Business Chart Data Type"; Enum "Business Chart Type")`
  (one per series) → per row `AddDataRowWithXDimension(Text)` + `SetValue(MeasureName|Index; XAxisIndex; Value)`
  → `Update(CurrPage.<usercontrol>)`.
- `AddMeasure`'s 2nd `Variant` parameter is just an opaque per-measure drill-down tag —
  `Business Chart Impl.` only stores it in `MeasureNameToValueMap` and never sends it to the
  client. Base app passes `1,2,3` in `JobChartMgt` but plain `''` in `TimeSheetChartMgt` /
  `SalesbyCustGrpChartMgt`. It is NOT the value, NOT the index, and has NO effect on rendering.
- `Initialize()` is a **full reset** (`DataTable.Clear`, `Columns.Clear`, `ClearMeasures`,
  `Clear(MeasureNameToValueMap)`), so calling a Refresh routine repeatedly cannot accumulate or
  duplicate measures. `AddDataColumn` is called internally by `SetXDimension`/`AddMeasure`, so
  callers must NOT call it themselves for measures.

**SERIES COLOURS ARE NOT CONTROLLABLE — and 2-measure charts render as two greys.**
The add-in JS (`Microsoft_System Application_*.app` → `addin/src/Resources/BusinessChart/js/
BusinessChartAddIn.js`) sets `colors: createPalette()` on the Highcharts 9.1.1 chart and its
`getSeries()` never emits a per-series `color`, so Highcharts assigns `palette[i]` to series `i`
in `AddMeasure` registration order. Under the M365 theme (`useModena365Theme()` =
`document.body.classList.contains('theme-m365')`) the palette starts
`[0] 80% Ash grey, [1] 80% Ash grey 50%, [2] teal, [3] aqua, [4] pale aqua, [5] YELLOW, [6] GREEN,
[7] red, [8] blue…`. A chart with exactly two measures therefore always looks monochrome grey.
Base-app charts look coloured only because they register **3+** measures and reach teal at [2].
Grepping `Business Chart`/`Business Chart Buffer`/the add-in for "color" returns zero hits — the
ONLY lever is a series' ordinal position, which would require phantom measures (each one costs a
junk legend entry). If a page genuinely needs specific colours, use DHTMLX instead.
- `XAxisIndex` in `SetValue` is **0-based** (base app's `SetJobChartValue` starts `Index` at 0).
- Enum members: `"Business Chart Data Type"::String|Integer|Decimal|DateTime` (no `Text`);
  clustered bars are `"Business Chart Type"::Column` (17 = Pie, 11 = StackedColumn).
- Name collision trap: a page global `BusinessChart: Codeunit "Business Chart"` clashes with a
  `usercontrol(BusinessChart; BusinessChart)` on the same page. Name the codeunit variable
  something else (page 50690 uses `BusinessChartMgt`) and keep the control named `BusinessChart`
  so `CurrPage.BusinessChart` reads naturally.

**Layout deviation worth knowing:** the brief asked for a "two-column group" holding the chart
and the data ListPart. A Card page's `area(content)` groups always stack VERTICALLY in the web
client (`grid`/`GridLayout = Columns` is ignored there), so the ListPart was put in
`area(FactBoxes)` instead — that is the only reliable way to get chart-left / table-right on a
Card page. `CurrPage.DataPart.Page.LoadData(...)` works identically from a factbox part.
