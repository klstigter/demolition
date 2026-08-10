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
var lastDayIndices = []; // parallel to lastDayLabels - raw 1..7 weekday index per included day (see codeunit 50662's "dayIndices"), used by the right-click "Show Data" handler to recover a real Date.
var pendingPatchFrame = null;
var contextMenuEl = null; // the current "Show Data" right-click popup, if one is open (see ShowContextMenu/HideContextMenu)
var chartMutationObserver = null; // set up once in BOOT; disconnected/reconnected around our own patch writes
var contextMenuDismissHandlers = null; // {click,contextmenu,scroll,keydown} currently attached to
// document for dismissing the open "Show Data" popup, or null if none attached - see ShowContextMenu/
// HideContextMenu for why this is tracked explicitly instead of relying on {once:true} self-removal.

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

// Gap (px) between a weekday's own Capacity/Requested bars once pulled tight together - see
// ApplyDayPairSpacing. Kept small but nonzero so the two bars still read as two distinct shapes
// instead of visually fusing into one block.
var PAIR_INNER_GAP_PX = 2;
// Matches Bar's own suite.js default (`Bar.prototype._setDefaults`: `barWidth: 30`) - this file's
// chart config never overrides `barWidth` (confirmed via grep), so this constant must be kept in
// sync if that ever changes. Needed here because ApplyDayPairSpacing computes bar-center offsets
// from it; nothing in the rendered DOM exposes barWidth directly to read back.
var BAR_WIDTH_PX = 30;

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

        // Right-click "Show Data" - registered ONCE here on chartContainer itself (not per
        // RenderChart call) since chartContainer persists across every LoadData/RenderChart call
        // (RenderChart only ever clears/rebuilds its INNER content via innerHTML = "" - see
        // RenderChart's own comment) - a per-render listener would stack duplicates on every
        // refresh. Delegates to ResolveBarSegmentFromEvent/ResolveLegendSegmentFromEvent so a
        // single handler covers both a stacked-bar segment AND a legend entry; when neither
        // resolves (click landed on empty background/axis), the event is left alone so the
        // browser's native context menu still shows, same as before this feature existed.
        chartContainer.addEventListener("contextmenu", function(e) {
            var barHit = ResolveBarSegmentFromEvent(e);
            if (barHit) {
                e.preventDefault();
                ShowContextMenu(e.clientX, e.clientY, function() {
                    try {
                        Microsoft.Dynamics.NAV.InvokeExtensibilityMethod(
                            "OnShowSegmentData",
                            [barHit.seriesName, barHit.barType, barHit.dayIndex, false]
                        );
                    } catch (err) { /* ignore */ }
                });
                return;
            }

            var legendHit = ResolveLegendSegmentFromEvent(e);
            if (legendHit) {
                e.preventDefault();
                ShowContextMenu(e.clientX, e.clientY, function() {
                    try {
                        Microsoft.Dynamics.NAV.InvokeExtensibilityMethod(
                            "OnShowSegmentData",
                            [legendHit.seriesName, "", 0, true]
                        );
                    } catch (err) { /* ignore */ }
                });
            }
        });

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
    var dayIndices  = (chartData && Array.isArray(chartData.dayIndices)) ? chartData.dayIndices : [];

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
                // Single-letter "C"/"R", not the full "Capacity"/"Requested" word: once
                // ApplyDayPairSpacing (below) pulls a day's 2 bars edge-to-edge tight (see its own
                // comment - total pair width is just BAR_WIDTH_PX*2 + PAIR_INNER_GAP_PX, ~62px, so
                // ~16px per bar's own label slot), the full words no longer fit and visibly overlap
                // into "CapReqiuested" - confirmed live via Playwright after the first pass of this
                // change. A single letter fits the tight slot; the color split (Capacity bars read
                // blue/green-dominant, Requested bars orange-dominant - see SERIES_COLOR_PALETTE)
                // plus the "Show Data" drilldown carry the rest of the distinction. This also
                // matches how reference grouped/clustered bar charts are conventionally labelled -
                // one category label per GROUP (handled by RenderDayGroupRow's Mon/Tue/... row
                // below), not a repeated sub-label on every bar within it.
                textTemplate: function(item) {
                    var s = String(item);
                    var i = s.indexOf(CATEGORY_DELIMITER);
                    var full = i >= 0 ? s.slice(i + 1) : s;
                    return full.charAt(0);
                }
            },
            left:   { type: "numeric" }
        },
        // De-duplicated by label - two series can share a display name (e.g. codeunit 50662's
        // per-skill internal/external halves, both named after the Skill Code, same colour,
        // stacked apart so the external half can carry its own red border) without producing two
        // identical-looking legend rows; only the FIRST series with a given label is listed here,
        // later ones with the same label still render in the stack, just not as their own legend
        // entry. The Assigned/free-capacity segments each use their own distinct series name
        // (e.g. "Assigned Capacity - Internal" vs "Assigned Capacity - External") specifically so
        // they do NOT collapse here and each gets its own legend entry.
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
    lastDayIndices = dayIndices;

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
        // ApplyDayPairSpacing MUST run before RenderDayGroupRow - the latter derives its own layout
        // (day-name centers, divider positions, background box) from whatever the bottom axis ticks'
        // CURRENT x positions are, so it needs to see the tightened/pair-shifted positions, not the
        // native evenly-spaced ones. The other two patches don't care about bar x position.
        ApplyDayPairSpacing();
        ApplySeriesBorders(lastSeriesDefs, lastSeries);
        ApplyLegendSwatchBorders(lastSeriesDefs, lastSeries);
        ApplyLegendHitArea();
        RenderDayGroupRow(lastDayLabels);
        if (chartMutationObserver) chartMutationObserver.observe(chartContainer, { childList: true, subtree: true });
    });
}

// Pulls each weekday's 2 bars (Capacity + Requested) tightly together around their own shared
// pair-center, so they read as one packed side-by-side pair with a clearly larger gap before the
// next weekday's pair - per spec (a standard grouped/clustered bar chart look). dhx.Chart's bottom
// "text" scale has NO per-category spacing option - confirmed by direct grep of suite.js:
// `TextScale.point()`/`_getAxisPoint()` position every category strictly uniformly by index
// (`index / max`), and `Bar._setDefaults` gives every bar a fixed `barWidth` (30px here, no
// per-series override) - so the native render always has the SAME gap between every adjacent pair
// of bars, Mon-Capacity-to-Mon-Requested exactly as wide as Mon-Requested-to-Tue-Capacity. There is
// no chart-config knob for this; the fix is a post-render pixel patch, same established technique
// as RenderDayGroupRow below.
//
// The pair CENTER is deliberately left untouched at its native position - since native ticks are
// uniformly spaced by index, a pair's center ((tick[2k]+tick[2k+1])/2) is ALREADY evenly spaced
// across k with no shift needed. Only the two bars WITHIN a pair move (symmetrically toward/apart
// from that fixed center), which means the freed-up space automatically becomes extra gap BETWEEN
// pairs with no separate "outer gap" tuning required.
//
// Idempotent across repaints (not within one already-shifted DOM without an intervening repaint -
// see BOOT's comment on why this never happens in practice): a dhx.Chart repaint always redraws
// fresh, natively evenly-spaced ticks/paths first (this is the only thing that ever resets them),
// and SchedulePostRenderPatches only ever runs once per repaint (rAF-batched), so this always reads
// a fresh native baseline before shifting it.
function ApplyDayPairSpacing() {
    var axisGroup = chartContainer.querySelector('g[aria-label^="x-axis"]');
    if (!axisGroup) return;

    // `:scope > text.scale-text` (DIRECT children only) - deliberately NOT a plain descendant
    // query. This function runs BEFORE RenderDayGroupRow in SchedulePostRenderPatches, so on any
    // pass where a previous `.day-group-row` (RenderDayGroupRow's own injected group, which nests
    // its OWN `text.scale-text` day-name labels one level deeper inside axisGroup) hasn't been
    // removed yet, a plain descendant query would also match those and throw the count off. Direct
    // children only is exactly what the native per-bar ticks always are, regardless of timing.
    var ticks = axisGroup.querySelectorAll(":scope > text.scale-text");
    var pairCount = Math.floor(ticks.length / 2);
    if (pairCount < 1 || ticks.length % 2 !== 0) return; // odd tick count - shape mismatch, bail rather than misdraw (mirrors RenderDayGroupRow's own guard)

    var half = (BAR_WIDTH_PX + PAIR_INNER_GAP_PX) / 2;
    var dx = []; // dx[flatCategoryIndex] = pixel shift for that category's bar(s)/tick

    for (var k = 0; k < pairCount; k++) {
        var xA = parseFloat(ticks[k * 2].getAttribute("x"));
        var xB = parseFloat(ticks[k * 2 + 1].getAttribute("x"));
        var center = (xA + xB) / 2;
        dx[k * 2] = (center - half) - xA;
        dx[k * 2 + 1] = (center + half) - xB;
    }

    // Every series shares the same category x-positions when stacked (which all of this chart's
    // series are) - shift ALL series' bars at a given category index by the SAME dx so the stack
    // stays visually aligned. Same `g[aria-label="chart s<N>"] path` shape ApplySeriesBorders/
    // ResolveBarSegmentFromEvent already rely on; paths render in the same left-to-right category
    // order as dx, so index-for-index alignment holds.
    var seriesGroups = chartContainer.querySelectorAll('g[aria-label^="chart s"]');
    seriesGroups.forEach(function(group) {
        var paths = group.querySelectorAll("path");
        paths.forEach(function(p, i) {
            if (dx[i] === undefined) return;
            p.setAttribute("transform", "translate(" + dx[i] + ",0)");
        });
    });

    // Shift the native "Capacity"/"Requested" tick labels to match, so each stays centered under
    // its own (now-moved) bar. Mutating the SAME <text> elements' x attribute in place (not
    // replacing them) is what lets RenderDayGroupRow, which runs right after this, pick up the new
    // positions just by re-querying the same selector.
    ticks.forEach(function(t, i) {
        if (dx[i] === undefined) return;
        var x = parseFloat(t.getAttribute("x"));
        t.setAttribute("x", x + dx[i]);
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
// This function only ever touches the BARS. The legend swatch is a separate concern, handled by
// ApplyLegendSwatchBorders below: for a label shared by a bordered series (e.g. codeunit 50662's
// per-skill segments, where the external half IS bordered on the bars themselves), the legend
// entry is always the FIRST series with that label (see RenderChart's legend.series de-dup), i.e.
// the internal/unbordered half - so that swatch correctly stays plain. But a series whose label is
// NOT shared with any earlier series (e.g. "Assigned Capacity - External", which has its own
// distinct, non-deduped legend slot) genuinely owns its legend entry, and that swatch DOES need
// the border - see ApplyLegendSwatchBorders' own de-dup-aware matching for how it tells the two
// cases apart.
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

// Applies the same red-outline convention as ApplySeriesBorders, but to a bordered series' own
// LEGEND SWATCH - only when that series genuinely owns its own de-duped legend slot (e.g. the now-
// distinct "Assigned Capacity - External"/"Free Capacity - External" entries), never for a series
// whose label was suppressed by RenderChart's legend.series de-dup (every per-skill segment's
// external half, which always shares its label with an earlier, unbordered internal series - see
// the comment on ApplySeriesBorders above). Re-derives that SAME first-occurrence-by-label
// ownership rule from `series` here rather than trusting anything already in the DOM, since the
// only DOM signal available (a `<g class="legend-item">`'s rendered label text, see below) can't
// by itself distinguish "this label has no earlier owner" from "it does".
//
// suite.js's Legend.prototype.paint() (verified by direct grep, suite.js ~13330-13439) renders
// each legend entry as `<g class="legend-item" aria-label="Show/Hide chart <label>">` containing a
// `<text class="start-text legend-text">` (whose rendered textContent - via a child <tspan>, see
// verticalCenteredText ~line 1949 - equals the series' own `label`, unique per entry precisely
// because of the de-dup upstream) and a swatch shape from `legendShape()` (suite.js ~35684, class
// "figure", defaulting to a `<rect class="figure ...">` since `config.legend.form` is never set
// here and Legend's own defaults ~line 13274 default `form` to "rect"). Matching swatches by that
// rendered label text (not DOM index) is what lets this stay correct regardless of how many
// series were filtered out ahead of any given legend entry.
//
// SVG shapes ignore the CSS `border` property entirely - only `stroke`/`stroke-width` paints
// visibly on a `<rect>`/`<circle>`, which is also exactly what ApplySeriesBorders already uses for
// the bars themselves, so the swatch is styled the same way for visual consistency (an inline
// `style.stroke` write always wins over the shape's own default `stroke="none"` presentation
// attribute set by legendShape/forms.rect, no !important needed).
//
// Idempotent - safe to call again on every repaint (see SchedulePostRenderPatches): swatches are
// plain style writes (no elements appended), and the non-bordered branch below explicitly clears
// any stale stroke rather than just skipping the element, though in practice dhx.Chart tears down
// and repaints the whole legend from scratch on every call anyway (see RenderChart's
// chartContainer.innerHTML = "" reset), so no swatch DOM node actually survives across calls.
function ApplyLegendSwatchBorders(seriesDefs, series) {
    if (!chartContainer) return;
    var legendGroup = chartContainer.querySelector('g[aria-label="Legend"]');
    if (!legendGroup) return;

    var legendOwnerIndexByLabel = GetLegendOwnerIndexByLabel(series);

    var items = legendGroup.querySelectorAll(".legend-item");
    items.forEach(function(item) {
        var textEl = item.querySelector(".legend-text");
        var swatch = item.querySelector(".figure");
        if (!textEl || !swatch) return;

        var ownerIdx = legendOwnerIndexByLabel[textEl.textContent];
        var ownerDef = (ownerIdx !== undefined) ? seriesDefs[ownerIdx] : null;

        if (ownerDef && ownerDef.border) {
            swatch.style.stroke = ownerDef.border;
            swatch.style.strokeWidth = "1.5px";
        } else {
            swatch.style.stroke = "";
            swatch.style.strokeWidth = "";
        }
    });
}

// First-occurrence-by-label ownership - MUST mirror RenderChart's own `legend.series` de-dup
// filter exactly, or a skill segment's external half could wrongly be treated as owning a legend
// slot it never actually got. Factored out of ApplyLegendSwatchBorders (its original, only caller)
// so the right-click legend resolver below (ResolveLegendSegmentFromEvent) reuses the exact same
// ownership rule instead of re-deriving a second, potentially-drifting copy of it.
function GetLegendOwnerIndexByLabel(series) {
    var seenLabels = {};
    var ownerIndexByLabel = {};
    (series || []).forEach(function(s, sIdx) {
        if (!s || seenLabels[s.label]) return;
        seenLabels[s.label] = true;
        ownerIndexByLabel[s.label] = sIdx;
    });
    return ownerIndexByLabel;
}

// Widens each legend entry's actually-clickable area to its FULL bounding box. Confirmed via a live
// probe (getBBox() + getScreenCTM()/elementFromPoint() against the real rendered chart, all 7 legend
// entries on this chart) that the bbox CENTER point of every single `.legend-item` resolves to the
// outer `<svg>`, not the `.legend-item` `<g>` itself, under default SVG hit-testing
// (pointer-events:visiblePainted, the UA default): the swatch `<rect>` and the `<text>` glyphs only
// cover PART of the item's own bbox (the gap between the swatch and the text, plus the vertical
// margin above/below the actual glyph ink, are unpainted and therefore NOT hit-testable) - so a
// click/right-click landing anywhere in those gaps silently falls through to whatever is behind the
// legend instead of reaching the item. This is a real, systemic gap (reproduced on every legend
// entry, on a fresh page load, before any other interaction) and is the confirmed root cause of
// "legend right-click does not work at all" - not a targeting bug in ResolveLegendSegmentFromEvent
// itself, which was already correct.
//
// Fix: insert an invisible full-bbox `<rect>` as each item's FIRST child (so it paints BEHIND the
// swatch/text - SVG has no z-index, paint order is DOM order - and never visually covers them) with
// `pointer-events:all`, the standard SVG technique for making a fully transparent shape still
// hit-testable regardless of the default visiblePainted rule. This widens the clickable area to the
// item's whole visual footprint for BOTH the native left-click hide/show toggle (bonus fix, not
// requested but a strict improvement, no behavior change for clicks that already worked) and this
// file's own right-click "Show Data" resolution (ResolveLegendSegmentFromEvent), without touching
// either's existing logic.
//
// Idempotent - safe to call again on every repaint (see SchedulePostRenderPatches): removes any hit
// rect it previously added before inserting a fresh one, though in practice (same as
// ApplyLegendSwatchBorders) dhx.Chart tears down and repaints the whole legend from scratch on every
// call anyway, so no old node actually survives across calls regardless.
function ApplyLegendHitArea() {
    if (!chartContainer) return;
    var legendGroup = chartContainer.querySelector('g[aria-label="Legend"]');
    if (!legendGroup) return;

    var items = legendGroup.querySelectorAll(".legend-item");
    items.forEach(function(item) {
        var existing = item.querySelector(".legend-hit-area");
        if (existing) existing.remove();

        var bbox;
        try { bbox = item.getBBox(); } catch (e) { return; }
        if (!bbox || !bbox.width || !bbox.height) return;

        var hitRect = SvgEl("rect", {
            "class": "legend-hit-area",
            x: bbox.x, y: bbox.y, width: bbox.width, height: bbox.height,
            fill: "transparent"
        });
        hitRect.style.pointerEvents = "all";
        item.insertBefore(hitRect, item.firstChild);
    });
}

// ============================================================
// Right-click "Show Data" - bar segments and legend entries
// ============================================================

// Resolves a right-click target to the specific stacked BAR SEGMENT it landed on - i.e. one
// (series, day) pair, not "the bar" as a whole, since a single bar is a stack of up to several
// independently-clickable segments (e.g. the Capacity bar's Assigned-Internal/External and
// Free-Capacity-Internal/External pieces). Reuses the exact same DOM shape ApplySeriesBorders
// already relies on: each series paints its own <path> per bar into a
// `g[aria-label="chart s<N>"]` wrapper (suite.js's Bar.paint sets that aria-label from the
// series' own id - see ApplySeriesBorders' header comment), and those <path>s render in the same
// left-to-right order as that series' own `values`/`categories` - so the clicked <path>'s index
// within ITS OWN group's <path> list is the category/day index, without needing any pixel-math
// hit-testing. Categories arrive as day-pairs (index 0/1 = day 0's Capacity/Requested bars, 2/3 =
// day 1's, ...), so day index = floor(pathIndex / 2) and BarType = even/odd - matching codeunit
// 50662's BuildDayCapacityChartData category-building order exactly. Returns null when the click
// did not land on a bar segment at all (empty background, axis, legend - see
// ResolveLegendSegmentFromEvent for the legend case).
function ResolveBarSegmentFromEvent(e) {
    var pathEl = e.target.closest ? e.target.closest("path") : null;
    if (!pathEl) return null;
    var group = pathEl.closest('g[aria-label^="chart s"]');
    if (!group) return null;

    var ariaLabel = group.getAttribute("aria-label") || "";
    var m = /^chart s(\d+)$/.exec(ariaLabel);
    if (!m) return null;
    var sIdx = parseInt(m[1], 10);
    if (sIdx < 0 || sIdx >= lastSeriesDefs.length) return null;

    var paths = Array.prototype.slice.call(group.querySelectorAll("path"));
    var pIdx = paths.indexOf(pathEl);
    if (pIdx < 0) return null;

    var dayIdx = Math.floor(pIdx / 2);
    if (dayIdx < 0 || dayIdx >= lastDayIndices.length) return null;

    return {
        seriesName: lastSeriesDefs[sIdx].name,
        barType: (pIdx % 2 === 0) ? "Capacity" : "Requested",
        dayIndex: lastDayIndices[dayIdx]
    };
}

// Resolves a right-click target to a LEGEND entry, identified purely by its rendered label text
// (same DOM shape/reasoning ApplyLegendSwatchBorders already uses - see that function's own
// comment for the suite.js Legend.paint() internals this relies on). A legend click always means
// "this segment across the WHOLE displayed week", so - unlike a bar-segment click - no day/BarType
// resolution happens here; ShowSegmentData on the AL side treats WholeWeek=true as using this
// series' own true/classified identity regardless of which bar it happens to also render on.
function ResolveLegendSegmentFromEvent(e) {
    var item = e.target.closest ? e.target.closest(".legend-item") : null;
    if (!item) return null;
    var textEl = item.querySelector(".legend-text");
    if (!textEl) return null;

    var ownerIndexByLabel = GetLegendOwnerIndexByLabel(lastSeries);
    var ownerIdx = ownerIndexByLabel[textEl.textContent];
    if (ownerIdx === undefined || !lastSeriesDefs[ownerIdx]) return null;

    return { seriesName: lastSeriesDefs[ownerIdx].name };
}

// Removes both the popup element AND (critically) whatever dismiss-listener set is currently
// attached to `document`, if any - see contextMenuDismissHandlers' own declaration comment. Always
// removing the SAME handler references that were actually added (tracked explicitly, not via
// {once:true} self-cleanup) is what guarantees at most one listener set is ever live at a time,
// regardless of which path triggered the dismissal (menu-item click, outside click, scroll, Escape,
// or - critically - ShowContextMenu itself calling this again to clear the PREVIOUS menu before
// opening a new one).
//
// Bug fixed here (2026-08-10): the original implementation registered its 4 dismiss listeners with
// `{once:true}` and never tracked/removed them explicitly. `{once:true}` only self-removes a
// listener when THAT SPECIFIC event type fires - a rapid run of right-clicks with no intervening
// left-click/scroll/Escape (exactly "right-click several different bar segments in a row" from the
// bug report) leaves every prior invocation's "click"/"scroll"/"keydown" listeners permanently
// attached to `document` (only "contextmenu" self-cleaned, since each NEW right-click's own
// contextmenu event bubbles to `document` and fires the previous one) - unbounded growth, one full
// set per right-click, which is what made the page feel like it was hanging after clicking around
// for a while. Explicit tracking + removal in HideContextMenu (called at the START of every
// ShowContextMenu, not just on dismissal) caps this at exactly one attached set, always.
function HideContextMenu() {
    if (contextMenuDismissHandlers) {
        document.removeEventListener("click", contextMenuDismissHandlers.click);
        document.removeEventListener("contextmenu", contextMenuDismissHandlers.contextmenu);
        document.removeEventListener("scroll", contextMenuDismissHandlers.scroll, { capture: true });
        document.removeEventListener("keydown", contextMenuDismissHandlers.keydown);
        contextMenuDismissHandlers = null;
    }
    if (contextMenuEl && contextMenuEl.parentNode) {
        contextMenuEl.parentNode.removeChild(contextMenuEl);
    }
    contextMenuEl = null;
}

// Builds and shows the single-item "Show Data" popup at the given viewport coordinates
// (clientX/clientY - matches the contextmenu event's own coordinate space, so no offset math is
// needed against chartContainer's bounding box). onShowData is invoked with no arguments when the
// user clicks the item; the menu is dismissed either way as soon as the user clicks/right-clicks/
// scrolls anywhere else or presses Escape. Dismiss listeners are registered on a deferred
// setTimeout(...,0) so the SAME right-click that opened the menu doesn't immediately close it again
// via event bubbling to `document`.
function ShowContextMenu(clientX, clientY, onShowData) {
    HideContextMenu(); // always clears any previous menu AND its dismiss-listener set first - see HideContextMenu's own comment for why this is the actual fix, not just cosmetic cleanup

    contextMenuEl = document.createElement("div");
    contextMenuEl.style.cssText =
        "position:fixed;z-index:9999;min-width:140px;padding:4px 0;" +
        "background:#ffffff;border:1px solid var(--dhx-color-gray-100,#e0e0e0);" +
        "border-radius:4px;box-shadow:0 2px 8px rgba(0,0,0,0.2);" +
        "font-family:inherit;font-size:13px;" +
        "left:" + clientX + "px;top:" + clientY + "px;";

    var item = document.createElement("div");
    item.textContent = "Show Data";
    item.style.cssText = "padding:6px 14px;cursor:pointer;color:#222;";
    item.addEventListener("mouseenter", function() { item.style.background = "#f0f0f0"; });
    item.addEventListener("mouseleave", function() { item.style.background = "transparent"; });
    item.addEventListener("click", function(evt) {
        evt.stopPropagation();
        HideContextMenu();
        onShowData();
    });
    contextMenuEl.appendChild(item);
    document.body.appendChild(contextMenuEl);

    setTimeout(function() {
        var handlers = {
            click: function() { HideContextMenu(); },
            contextmenu: function() { HideContextMenu(); },
            scroll: function() { HideContextMenu(); },
            keydown: function(evt) { if (evt.key === "Escape") HideContextMenu(); }
        };
        contextMenuDismissHandlers = handlers;
        document.addEventListener("click", handlers.click);
        document.addEventListener("contextmenu", handlers.contextmenu);
        document.addEventListener("scroll", handlers.scroll, { capture: true });
        document.addEventListener("keydown", handlers.keydown);
    }, 0);
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
