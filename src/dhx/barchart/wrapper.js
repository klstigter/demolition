// ============================================================
// State
// ============================================================
var chartContainer;         // DOM element reference (readiness flag)
var chartInstance = null;   // current dhx.Chart instance (recreated on every LoadData)

// Distinct, fixed colours per series ordinal — DHTMLX Suite's Chart lets us set
// series.color explicitly (see Chart.setConfig / BaseSeria._setDefaults in suite.js),
// unlike BC's native BusinessChart add-in which has no colour API at all and just
// hands Highcharts a fixed M365 palette (see the comment block in
// src/page/page_50690_RequestedVsCapacitySkills.al around line 169-183). That is the
// whole reason this DHTMLX proof-of-concept exists, so we always assign an explicit
// colour per series here rather than relying on the library's own default palette.
var SERIES_COLOR_PALETTE = ["#2A9D8F", "#E76F51", "#11A3D0", "#E5A910", "#985F99", "#78586F"];

// ============================================================
// BOOT – called by startupScript.js
// ============================================================
window.BOOT = function() {
    try {
        var addin = document.getElementById("controlAddIn");
        addin.style.cssText = "width:100%;height:100%;margin:0;padding:0;";

        chartContainer = document.createElement("div");
        chartContainer.id = "dhx-barchart-container";
        chartContainer.style.cssText = "width:100%;height:100%;";
        addin.appendChild(chartContainer);

        // ---- Check library ----
        if (typeof dhx === "undefined" || !dhx.Chart) {
            console.error("DHTMLX Suite library (suite.js) not found. Please include it in ControlAddIn Scripts.");
            return;
        }

        // ---- Render an empty chart so the control has something to show immediately ----
        RenderChart({ categories: [], series: [] });

        Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("ControlReady", []);

    } catch (e) {
        console.warn("BOOT warning:", e);
    }
};

// ============================================================
// Build/replace the vertical bar chart - grouped (clustered) by default, or stacked when a
// series requests it.
//
// chartData shape (see LoadData below):
//   { categories: ["SKILL1","SKILL2",...],
//     series: [ { name: "Requested Hours", values: [decimal,...],
//                 color: "#RRGGBB" (optional, else SERIES_COLOR_PALETTE rotation),
//                 stacked: true (optional; any series requesting it stacks the whole chart),
//                 border: "#RRGGBB" (optional outline colour, e.g. the Excel spec's red
//                         "External" segment) },
//               { name: "Capacity",        values: [decimal,...] } ] }
//
// The chart is fully torn down and rebuilt on every call rather than mutated in
// place — dhx.Chart's data/scales/series are cheapest to reason about as a clean
// rebuild (mirrors this project's existing "wipe and rebuild" convention, e.g.
// BuildResourcePanel in src/dhx/resourceschedule/wrapper.js).
// ============================================================
function RenderChart(chartData) {
    if (!chartContainer) return;

    var categories = (chartData && Array.isArray(chartData.categories)) ? chartData.categories : [];
    var seriesDefs  = (chartData && Array.isArray(chartData.series))     ? chartData.series     : [];

    // One data row per category ("id" doubles as the click-handler's row identifier —
    // dhx.Chart's bar click handler fires with (id, seriesValueField), see suite.js
    // Bar._getForm()'s onclick wiring), one field per series (s0, s1, ...).
    var data = categories.map(function(cat, idx) {
        var row = { id: String(cat), category: String(cat) };
        seriesDefs.forEach(function(s, sIdx) {
            var values = (s && Array.isArray(s.values)) ? s.values : [];
            row["s" + sIdx] = (values[idx] !== undefined && values[idx] !== null) ? values[idx] : 0;
        });
        return row;
    });

    // A series carries its own explicit `color` when the caller wants a fixed palette instead
    // of the generic SERIES_COLOR_PALETTE rotation - see page 50692's stacked Ass/Internal/
    // External/skill chart for the first caller that does this.
    var series = seriesDefs.map(function(s, sIdx) {
        var seriesDef = {
            id:    "s" + sIdx,
            value: "s" + sIdx,
            label: (s && s.name) ? s.name : ("Series " + (sIdx + 1)),
            color: (s && s.color) ? s.color : SERIES_COLOR_PALETTE[sIdx % SERIES_COLOR_PALETTE.length]
        };
        // Any series requesting `stacked` switches the whole chart to a stacked layout (suite.js
        // reads `stacked` per-series - see Stacker/serieConfig.stacked in suite.js - but a mixed
        // stacked/unstacked chart is not a shape any caller needs, so one flag covers all series).
        if (s && s.stacked) {
            seriesDef.stacked = true;
        }
        return seriesDef;
    });
    var isStacked = seriesDefs.some(function(s) { return s && s.stacked; });
    if (isStacked) {
        series.forEach(function(s) { s.stacked = true; });
    }

    var config = {
        type: "bar",
        data: data,
        series: series,
        // NOTE: the "text" scale's category field name comes from `text`, NOT `value`
        // (confirmed by reading suite.js's TextScale._setDefaults: `this.locator =
        // locator(config.text)`). `value` on a scale config is a no-op for the "text"
        // type — using it here previously made every row resolve to the same blank (""),
        // collapsing all categories onto the same x-slot and producing garbled/ghost bars.
        //
        // scaleRotate: -45 — with many categories (e.g. 10 "<Wkd> Capacity"/"<Wkd> Requested"
        // labels on the stacked chart) the default horizontal text overlaps into unreadable
        // run-together labels. suite.js's bottom-axis renderer (see `bottom()` in suite.js)
        // natively supports rotating scale text via this config key — reusing the library's
        // own rotation support here, unlike RotateLegendLabel below which is a post-render CSS
        // hack for something the library has no config option for at all. Negative = same
        // counter-clockwise direction as RotateLegendLabel's `rotate(-90deg)` below, just a
        // shallower 45° angle: each label pivots at its tick (bottom-right of the text) and
        // reads diagonally up-and-to-the-right (north-east), not straight up.
        //
        // size: 80 — Scale's own default reserved space for a bottom/top axis is a flat 20px
        // (see `this.config.size = this.config.size || 20 + ...` in suite.js's base Scale
        // class), sized for a single line of HORIZONTAL text. Rotating does not grow that
        // reservation automatically (scaleRotate only changes the SVG transform, not the layout
        // math), so without an explicit larger `size` the rotated labels would be clipped by the
        // plot area. 80 fits the longest label ("Mon Requested" etc, ~13 chars) at 45°
        // (vertical extent = sin(45°) * text length, well under a full 90° rotation's need).
        scales: {
            bottom: { type: "text", text: "category", scaleRotate: -45, textPadding: 12, size: 80 },
            left:   { type: "numeric" }
        },
        legend: {
            series: series.map(function(s) { return s.id; }),
            halign: "right",
            valign: "top"
        }
    };

    if (chartInstance) {
        try { chartInstance.destructor(); } catch (e) { /* ignore */ }
        chartInstance = null;
    }
    chartContainer.innerHTML = "";

    chartInstance = new dhx.Chart(chartContainer, config);

    // dhx.Chart's Legend has no built-in rotation/orientation option (see suite.js's Legend
    // class - halign/valign/direction only, no angle). Rotating the "Requested Hours" label to
    // read vertically, bottom-to-top, tucked into the top-right corner is done here as a
    // post-render CSS transform on the legend's own SVG <text> node instead. transform-box:
    // fill-box + transform-origin: 0% 100% pins the rotation pivot to the text's own bottom-left
    // corner, so it stays anchored roughly where the library placed it and the rotated text
    // extends upward from there - "left-bottom to right-top" reading direction. This does NOT
    // reserve extra layout space for the now-taller-than-wide rotated label (the library's own
    // margin math in getDefaultMargin/scaleReady only ever knew about the pre-rotation
    // horizontal size), so at extreme container sizes it may sit closer to the plot area than a
    // native vertical-legend option would.
    RotateLegendLabel();

    // dhx.Chart's Bar series has no config-level stroke/outline option (confirmed by reading
    // suite.js's Bar._getForm(): the rendered <path> only ever gets `fill`, never `stroke`,
    // from series config). The Excel spec's red-outlined "External" segment is therefore
    // applied the same way RotateLegendLabel above handles what the library's config can't do
    // - a post-render CSS pass, this time keyed off each bordered series' own fill colour
    // rather than a class/ref (the library's internal point refs are not a stable public API
    // to key off of).
    ApplySeriesBorders(seriesDefs, series);

    // Bar click -> BC (mirrors OnEventDoubleClick's InvokeExtensibilityMethod pattern
    // used throughout src/dhx/resourceschedule/wrapper.js). id is the Skill Code we
    // set as each data row's "id"/"category" above.
    chartInstance.events.on("serieClick", function(id) {
        try {
            Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("OnDataPointClicked", [String(id)]);
        } catch (e) { /* ignore */ }
    });
}

// Applies a CSS stroke to every rendered bar <path> whose fill matches a series that requested
// a `border` colour (e.g. the Excel spec's red-outlined "External" segment). Deferred one frame
// past chart construction for the same reason as RotateLegendLabel below.
function ApplySeriesBorders(seriesDefs, series) {
    var borderedColors = [];
    seriesDefs.forEach(function(s, sIdx) {
        if (s && s.border && series[sIdx]) {
            borderedColors.push({ fill: series[sIdx].color, stroke: s.border });
        }
    });
    if (!borderedColors.length) return;

    requestAnimationFrame(function() {
        if (!chartContainer) return;
        borderedColors.forEach(function(entry) {
            var paths = chartContainer.querySelectorAll('path[fill="' + entry.fill + '"]');
            paths.forEach(function(p) {
                p.style.stroke = entry.stroke;
                p.style.strokeWidth = "1.5px";
            });
        });
    });
}

// Rotates every legend item's <text class="legend-text"> 90deg counter-clockwise so it reads
// bottom-to-top instead of left-to-right. Deferred one frame past chart construction: dhx.Chart
// paints its SVG synchronously in practice, but querying immediately after `new dhx.Chart(...)`
// is fragile if that ever changes, so this waits a frame rather than assuming paint order.
function RotateLegendLabel() {
    requestAnimationFrame(function() {
        if (!chartContainer) return;
        var legendTexts = chartContainer.querySelectorAll(".legend-text");
        legendTexts.forEach(function(textEl) {
            textEl.style.transformBox = "fill-box";
            textEl.style.transformOrigin = "0% 100%";
            textEl.style.transform = "rotate(-90deg)";
        });
    });
}

// ============================================================
// AL-callable: LoadData(chartDataJson)
//   chartDataJson – JSON string, see RenderChart's comment for the exact shape.
// ============================================================
function LoadData(chartDataJson) {
    try {
        var parsed = ParseJsonTxt(chartDataJson);
        if (!parsed) {
            console.warn("LoadData: could not parse JSON.");
            return;
        }
        RenderChart(parsed);
    } catch (e) {
        console.error("LoadData error:", e);
    }
}

// ============================================================
// Helpers
// ============================================================
function ParseJsonTxt(txt) {
    if (!txt) return null;
    if (typeof txt === "object") return txt;
    try { return JSON.parse(txt); } catch (e) { return null; }
}
