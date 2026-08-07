// ============================================================
// State
// ============================================================
var chartContainer;         // DOM element reference (readiness flag)
var chartInstance = null;   // current dhx.Chart instance (recreated on every LoadData)

// Latest render inputs, kept around so a resize-triggered re-application (see
// SchedulePostRenderPatches) can redraw the post-render patches without needing a fresh
// LoadData call - dhx.Chart itself repaints on container resize (via suite.js's own internal
// resizer()/ResizeObserver, observing a sentinel node it creates fresh inside chartContainer on
// every RenderChart call), which would otherwise silently wipe these patches.
var lastSeriesDefs = [];
var lastSeries = [];
var lastDayLabels = [];
var pendingPatchFrame = null;
var chartMutationObserver = null; // set up once in BOOT; disconnected/reconnected around our own patch writes

// Distinct, fixed colours per series ordinal — DHTMLX Suite's Chart lets us set
// series.color explicitly (see Chart.setConfig / BaseSeria._setDefaults in suite.js),
// unlike BC's native BusinessChart add-in which has no colour API at all and just
// hands Highcharts a fixed M365 palette (see the comment block in
// src/page/page_50690_RequestedVsCapacitySkills.al around line 169-183). That is the
// whole reason this DHTMLX proof-of-concept exists, so we always assign an explicit
// colour per series here rather than relying on the library's own default palette.
var SERIES_COLOR_PALETTE = ["#2A9D8F", "#E76F51", "#11A3D0", "#E5A910", "#985F99", "#78586F"];

// Bottom-axis "day group" row (see RenderDayGroupRow) - kept as named constants since the
// geometry math has to agree with the `bottom` scale's own `textPadding`/`size` config below.
var CATEGORY_DELIMITER = "|";       // matches codeunit 50662's CategoryDelimiterTok
var BOTTOM_TEXT_PADDING = 12;       // matches scales.bottom.textPadding in RenderChart
var DAY_ROW_HEIGHT = 24;            // px reserved for EACH of the 2 bottom-axis rows
// Matches the native plot area's own gridlines (suite.css: `.grid-line{stroke:var(--dhx-color-
// gray-100)}`, no explicit stroke-width -> browser default of 1px) rather than a bold black line,
// so the day-group row's grid reads as part of the same chart instead of a heavier overlay.
var DAY_GROUP_BORDER_COLOR = "var(--dhx-color-gray-100)";
var DAY_GROUP_BORDER_WIDTH = 1;
// Lighter than DAY_GROUP_BORDER_COLOR itself (suite.css has no gray shade lighter than gray-100)
// so the gray-100 divider lines still read against it instead of blending into plain white.
var DAY_GROUP_BACKGROUND_COLOR = "#f7f7f7";

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

        // dhx.Chart repaints its whole SVG - discarding every post-render DOM patch applied below
        // (series borders, the day-group row) - for more reasons than just a
        // container resize: confirmed live (via Playwright against the actual BC web client) that
        // a repaint can also follow shortly after the FIRST successful patch pass with no size
        // change involved at all, most likely BC's own factbox/page layout still settling. A
        // MutationObserver watching for the library replacing its own tick/legend/bar elements is
        // a direct signal of "a repaint just happened, reapply now" rather than inferring it from
        // a proxy like container size - childList+subtree catches the library's node
        // teardown/rebuild; disconnect/reconnect around our OWN writes below (see
        // SchedulePostRenderPatches) stops that from re-triggering itself in a loop.
        if (typeof MutationObserver !== "undefined") {
            chartMutationObserver = new MutationObserver(function() {
                if (chartInstance) SchedulePostRenderPatches();
            });
            chartMutationObserver.observe(chartContainer, { childList: true, subtree: true });
        }
        // Kept as a defense-in-depth second signal: a resize that only repositions existing
        // elements (attribute changes, no node add/remove) wouldn't trip the MutationObserver
        // above, but would still invalidate the day-group row's cached tick x-positions.
        if (typeof ResizeObserver !== "undefined") {
            new ResizeObserver(function() {
                if (chartInstance) SchedulePostRenderPatches();
            }).observe(chartContainer);
        }

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
    var dayLabels   = (chartData && Array.isArray(chartData.dayLabels))  ? chartData.dayLabels  : [];

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
        // For the same reason each category must stay UNIQUE per bar even though only part of
        // it is shown: TextScale.point() positions a bar by `steps.indexOf(categoryValue)`
        // (see suite.js), so two bars sharing identical category text would collapse onto the
        // same x-slot. Categories therefore arrive as "<Wkd>|Capacity"/"<Wkd>|Requested"
        // (CATEGORY_DELIMITER-joined, still unique per bar) and textTemplate below strips the
        // "<Wkd>|" prefix so the tick only ever shows "Capacity"/"Requested" - the weekday
        // itself is rendered separately by RenderDayGroupRow from chartData.dayLabels.
        //
        // Bottom axis labels are kept horizontal (no scaleRotate) per spec. size is set to fit
        // both the native "Capacity"/"Requested" row and RenderDayGroupRow's extra day-name row
        // stacked directly underneath it (DAY_ROW_HEIGHT each) - the library's own flat-20px
        // default (see suite.js's base Scale class) only ever accounted for a single line.
        scales: {
            bottom: {
                type: "text", text: "category", textPadding: BOTTOM_TEXT_PADDING, size: DAY_ROW_HEIGHT * 2,
                textTemplate: function(item) {
                    var s = String(item);
                    var i = s.indexOf(CATEGORY_DELIMITER);
                    return i >= 0 ? s.slice(i + 1) : s;
                }
            },
            left:   { type: "numeric" }
        },
        // De-duplicated by label - two series can share a display name (e.g. codeunit 50662's
        // "Assigned" internal/external halves, same colour, stacked apart so the external half
        // can carry its own red border) without producing two identical-looking legend rows;
        // only the FIRST series with a given label is listed here, later ones with the same
        // label still render in the stack, just not as their own legend entry.
        legend: {
            series: (function() {
                var seenLabels = {};
                return series.filter(function(s) {
                    if (seenLabels[s.label]) return false;
                    seenLabels[s.label] = true;
                    return true;
                }).map(function(s) { return s.id; });
            })(),
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

    // Stash for SchedulePostRenderPatches - both this call's own first application below AND
    // any later resize-triggered re-application (see the ResizeObserver set up in BOOT) read
    // from these rather than from RenderChart's local closure, since a resize can fire long
    // after this specific call has returned.
    lastSeriesDefs = seriesDefs;
    lastSeries = series;
    lastDayLabels = dayLabels;

    // Two post-render DOM patches for things dhx.Chart's own config has no option for:
    //   - ApplySeriesBorders: Bar series has no stroke/outline option (suite.js's Bar._getForm()
    //     only ever sets `fill` on the rendered <path>) - the Excel spec's red-outlined
    //     "External" segment is a CSS stroke pass keyed off each bordered series' fill colour.
    //   - RenderDayGroupRow: the bottom "text" scale has no multi-level/grouped category concept
    //     (suite.js's Scale classes only ever paint one row of ticks) - the merged per-weekday
    //     header row is hand-drawn from the already-rendered tick positions.
    // Both mutate/append DOM directly rather than going through chart config, so
    // SchedulePostRenderPatches (not just this one call) is what keeps them alive across the
    // resize-triggered repaints described in BOOT's ResizeObserver comment.
    SchedulePostRenderPatches();

    // Bar click -> BC (mirrors OnEventDoubleClick's InvokeExtensibilityMethod pattern
    // used throughout src/dhx/resourceschedule/wrapper.js). id is the Skill Code we
    // set as each data row's "id"/"category" above.
    chartInstance.events.on("serieClick", function(id) {
        try {
            Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("OnDataPointClicked", [String(id)]);
        } catch (e) { /* ignore */ }
    });
}

// Schedules (de-duplicated - a burst of mutation/resize signals collapses to one pass) a single
// frame-deferred re-application of all three post-render patches. requestAnimationFrame is what
// makes the timing safe: per spec, a frame's entire MutationObserver microtask queue and
// ResizeObserver batch (every observer, including both ours and dhx.Chart's own internal one) is
// fully resolved and painted BEFORE any rAF callback for that frame runs - so by the time this
// fires, whatever repaint triggered it has already happened, with nothing left to undo these
// patches afterward. The MutationObserver is disconnected for the duration of the writes below
// and reconnected immediately after, so appending our own day-group-row (itself a mutation)
// can't re-trigger this same scheduler in a loop.
function SchedulePostRenderPatches() {
    if (pendingPatchFrame) return;
    pendingPatchFrame = requestAnimationFrame(function() {
        pendingPatchFrame = null;
        if (!chartContainer) return;
        if (chartMutationObserver) chartMutationObserver.disconnect();
        ApplySeriesBorders(lastSeriesDefs, lastSeries);
        RenderDayGroupRow(lastDayLabels);
        if (chartMutationObserver) chartMutationObserver.observe(chartContainer, { childList: true, subtree: true });
    });
}

// Applies a CSS stroke to every rendered bar <path> of a series that requested a `border`
// colour AND actually has a nonzero value for that category (e.g. codeunit 50662's red-outlined
// external half of "Assigned") - a zero-value stacked segment still paints as a real (if
// invisible-height) <path> at its baseline, so stroking it unconditionally left a persistent red
// hairline sitting at y=0 on every bar with no external data at all, drowning out the real
// signal instead of highlighting it. The fill itself stays solid, same visual weight as every
// other series - only the stroke is special-cased here, not the fill.
//
// Bar <path>s are matched by scoping to that series' own `g[aria-label="chart s<N>"]` wrapper
// (suite.js's Bar.paint sets this aria-label from the series' own `value`/id - see
// Bar.prototype.paint in suite.js) rather than by `path[fill="..."]` - two DIFFERENT series can
// legitimately share one fill colour (the "Assigned" internal/external halves both use
// AssColorTok), so a fill-only selector would incorrectly grab the OTHER series' bars too. Paths
// render in the same left-to-right category order as `s.values`, so the two can be walked in
// lockstep by index.
//
// The legend swatch is deliberately left plain (no stroke), even for a label like "Assigned"
// whose external half IS bordered on the bars themselves: the legend entry is always the FIRST
// series with that label (see RenderChart's legend.series de-dup), i.e. the internal/unbordered
// half - matching that swatch to it is correct, and a fill-colour-based swatch match would have
// wrongly styled it to look like the (different, later-declared) external half instead.
//
// Idempotent - safe to call again on every repaint (see SchedulePostRenderPatches).
function ApplySeriesBorders(seriesDefs, series) {
    seriesDefs.forEach(function(s, sIdx) {
        if (s && s.border && series[sIdx]) {
            var values = Array.isArray(s.values) ? s.values : [];
            var paths = chartContainer.querySelectorAll('g[aria-label="chart ' + series[sIdx].id + '"] path');
            paths.forEach(function(p, pIdx) {
                if (values[pIdx]) {
                    p.style.stroke = s.border;
                    p.style.strokeWidth = "1.5px";
                }
            });
        }
    });
}

// Creates an SVG element (SVG needs its own namespace - plain document.createElement won't
// render inside an <svg>) and applies the given attributes.
function SvgEl(tag, attrs) {
    var el = document.createElementNS("http://www.w3.org/2000/svg", tag);
    for (var key in attrs) {
        el.setAttribute(key, attrs[key]);
    }
    return el;
}

// Draws the "day of week" header row spanning each weekday's 2 bars (Capacity + Requested),
// directly underneath the native "Capacity"/"Requested" tick labels, plus a grid of borders
// around both rows - matching page 50692's spec: a two-tier bottom axis, top tier = per-bar
// Capacity/Requested label (native, via textTemplate above), bottom tier = one merged label per
// weekday. dhx.Chart's bottom "text" scale has no built-in concept of grouped/multi-level
// categories (suite.js's Scale classes only ever paint one row of ticks), so this row is drawn
// entirely by hand from the ALREADY-RENDERED tick positions rather than through any chart
// config. Idempotent - safe to call again on every repaint (see SchedulePostRenderPatches):
// removes any group it previously appended before drawing a fresh one, so a resize storm can
// never stack duplicates.
function RenderDayGroupRow(dayLabels) {
    var axisGroup = chartContainer.querySelector('g[aria-label^="x-axis"]');
    if (!axisGroup) return;

    var existing = axisGroup.querySelector(".day-group-row");
    if (existing) existing.remove();
    var existingBg = axisGroup.querySelector(".day-group-bg");
    if (existingBg) existingBg.remove();

    if (!dayLabels || !dayLabels.length) return;

    var ticks = axisGroup.querySelectorAll("text.scale-text");
    if (ticks.length !== dayLabels.length * 2) return; // shape mismatch - bail rather than misdraw

    var xs = [];
    for (var t = 0; t < ticks.length; t++) {
        xs.push(parseFloat(ticks[t].getAttribute("x")));
    }
    var tickY = parseFloat(ticks[0].getAttribute("y"));
    var step = xs[1] - xs[0];
    if (!step) return; // degenerate layout (e.g. a single category) - nothing sane to draw

    // Reconstruct the bottom axis's own local y=0 line (suite.js's bottom() sets every
    // tick's y to `height + textPadding`, see SvgScales.bottom in suite.js) so the new rows
    // stack directly beneath it in the SAME local coordinate space as the existing ticks -
    // no need to read any DOM transform/bounding box.
    var axisY = tickY - BOTTOM_TEXT_PADDING;
    var row2Y = axisY + DAY_ROW_HEIGHT + BOTTOM_TEXT_PADDING;
    var leftEdge = xs[0] - step / 2;
    var rightEdge = xs[xs.length - 1] + step / 2;

    // The background fill MUST be painted BEHIND the native "Capacity"/"Requested" tick text
    // (siblings within axisGroup, already there before this function ever runs) - SVG has no
    // z-index, paint order is DOM order, so an opaque fill appended normally (last = on top)
    // would silently cover that text instead of sitting behind it. insertBefore(...,
    // firstChild) is the one line standing between "background tint" and "row 1 text vanishes".
    var bgRect = SvgEl("rect", {
        "class": "day-group-bg",
        x: leftEdge, y: axisY, width: rightEdge - leftEdge, height: DAY_ROW_HEIGHT * 2,
        fill: DAY_GROUP_BACKGROUND_COLOR, stroke: DAY_GROUP_BORDER_COLOR, "stroke-width": DAY_GROUP_BORDER_WIDTH
    });
    axisGroup.insertBefore(bgRect, axisGroup.firstChild);

    // Everything else (row divider, dividers, day-name text) is unfilled strokes/text that never
    // covers the native ticks, so it stays appended normally (on top, where it needs to be
    // visible over the background).
    var group = SvgEl("g", { "class": "day-group-row" });

    group.appendChild(SvgEl("line", {
        x1: leftEdge, x2: rightEdge, y1: axisY + DAY_ROW_HEIGHT, y2: axisY + DAY_ROW_HEIGHT,
        stroke: DAY_GROUP_BORDER_COLOR, "stroke-width": DAY_GROUP_BORDER_WIDTH
    }));
    // Top row: one divider between every bar (Capacity | Requested | Capacity | ...).
    for (var k = 0; k < xs.length - 1; k++) {
        var dividerX = (xs[k] + xs[k + 1]) / 2;
        group.appendChild(SvgEl("line", {
            x1: dividerX, x2: dividerX, y1: axisY, y2: axisY + DAY_ROW_HEIGHT,
            stroke: DAY_GROUP_BORDER_COLOR, "stroke-width": DAY_GROUP_BORDER_WIDTH
        }));
    }
    // Bottom row: one divider between each WEEKDAY pair only (not between a day's own
    // Capacity/Requested bars, since those share the same merged day-name cell).
    for (var d = 0; d < dayLabels.length - 1; d++) {
        var pairBoundaryX = (xs[d * 2 + 1] + xs[d * 2 + 2]) / 2;
        group.appendChild(SvgEl("line", {
            x1: pairBoundaryX, x2: pairBoundaryX, y1: axisY + DAY_ROW_HEIGHT, y2: axisY + DAY_ROW_HEIGHT * 2,
            stroke: DAY_GROUP_BORDER_COLOR, "stroke-width": DAY_GROUP_BORDER_WIDTH
        }));
    }
    // One merged day-name label per weekday, centered over its own pair of bars.
    for (var i = 0; i < dayLabels.length; i++) {
        var midX = (xs[i * 2] + xs[i * 2 + 1]) / 2;
        var dayText = SvgEl("text", { x: midX, y: row2Y, "text-anchor": "middle", "class": "scale-text" });
        dayText.textContent = String(dayLabels[i]);
        group.appendChild(dayText);
    }

    axisGroup.appendChild(group);
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
