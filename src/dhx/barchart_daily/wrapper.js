// ============================================================
// State
// ============================================================
var chartContainer;         // DOM element reference (readiness flag)
var chartInstance = null;   // current dhx.Chart instance (recreated on every LoadData)

// Latest render input, kept around so the right-click "Show Data" handler can resolve a clicked
// bar's <path> index back to the Skill Code (or the synthetic 'CAPACITY' marker) it belongs to -
// this chart has exactly one series/one bar per category, so a <path>'s index within its series
// group IS the category index directly (unlike the live barchart, which stacks 2 bars per weekday
// and needs a day/2 + even-odd split - see src/dhx/barchart_daily/wrapper.js's ResolveBarSegmentFromEvent).
var lastCategories = [];
var contextMenuEl = null; // the current "Show Data" right-click popup, if one is open (see ShowContextMenu/HideContextMenu)
var contextMenuDismissHandlers = null; // {click,contextmenu,scroll,keydown} currently attached to
// document for dismissing the open "Show Data" popup, or null if none attached - see ShowContextMenu/
// HideContextMenu for why this is tracked explicitly instead of relying on {once:true} self-removal.

var barColorObserver = null; // MutationObserver that keeps ApplyBarColorOverrides' <path> fill
// patches in sync with dhx.Chart's OWN repaint passes - see that function's own comment for why a
// single requestAnimationFrame after construction is not sufficient here.

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

        // Right-click "Show Data" - registered ONCE here on chartContainer itself (not per
        // RenderChart call) since chartContainer persists across every LoadData/RenderChart call
        // (RenderChart only ever clears/rebuilds its INNER content via innerHTML = "" - see
        // RenderChart's own comment) - a per-render listener would stack duplicates on every
        // refresh. Delegates to ResolveBarSegmentFromEvent/ResolveLegendSegmentFromEvent so a
        // single handler covers both a single bar AND the legend entry; when neither resolves
        // (click landed on empty background/axis), the event is left alone so the browser's
        // native context menu still shows, same as before this feature existed.
        chartContainer.addEventListener("contextmenu", function(e) {
            var barHit = ResolveBarSegmentFromEvent(e);
            if (barHit) {
                e.preventDefault();
                ShowContextMenu(e.clientX, e.clientY, function() {
                    try {
                        Microsoft.Dynamics.NAV.InvokeExtensibilityMethod(
                            "OnShowSegmentData",
                            [barHit.segmentId, false]
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
                            ["", true]
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
// Build/replace the grouped (clustered, non-stacked) vertical bar chart.
//
// chartData shape (see LoadData below):
//   { categories: ["SKILL1","SKILL2",...],
//     series: [ { name: "Requested Hours", values: [decimal,...] } ],
//     colors: ["#RRGGBB", "", ...] }  (optional, parallel to categories - blank/absent entry
//                                      means that category's bar keeps the default series colour
//                                      - see ApplyBarColorOverrides' own comment)
//
// Each built `data` row also carries a `barColor` field - the same resolved colour
// ApplyBarColorOverrides paints that row's bar with (override, or the default series colour when
// there is none). This drives the legend, which is configured as `legend: { values: { text:
// "category", color: "barColor" } }` - one item per category/bar rather than per series - so the
// legend's swatches always match the bars. See the comments next to that config below, and next
// to the chartInstance.events.detach("toggleSeries") call, for why the legend is data-driven here
// and why left-click on a legend item is deliberately a no-op as a result.
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
    var barColors   = (chartData && Array.isArray(chartData.colors))    ? chartData.colors     : [];

    // One data row per category ("id" doubles as the click-handler's row identifier —
    // dhx.Chart's bar click handler fires with (id, seriesValueField), see suite.js
    // Bar._getForm()'s onclick wiring), one field per series (s0, s1, ...).
    var data = categories.map(function(cat, idx) {
        var row = { id: String(cat), category: String(cat) };
        seriesDefs.forEach(function(s, sIdx) {
            var values = (s && Array.isArray(s.values)) ? s.values : [];
            row["s" + sIdx] = (values[idx] !== undefined && values[idx] !== null) ? values[idx] : 0;
        });
        // Same resolved colour ApplyBarColorOverrides applies to this row's bar - see the
        // shape-comment above RenderChart for why this exists (drives the data-driven legend).
        row.barColor = barColors[idx] || SERIES_COLOR_PALETTE[0];
        return row;
    });

    var series = seriesDefs.map(function(s, sIdx) {
        return {
            id:    "s" + sIdx,
            value: "s" + sIdx,
            label: (s && s.name) ? s.name : ("Series " + (sIdx + 1)),
            color: SERIES_COLOR_PALETTE[sIdx % SERIES_COLOR_PALETTE.length]
        };
    });

    var config = {
        type: "bar",
        data: data,
        series: series,
        // NOTE: the "text" scale's category field name comes from `text`, NOT `value`
        // (confirmed by reading suite.js's TextScale._setDefaults: `this.locator =
        // locator(config.text)`). `value` on a scale config is a no-op for the "text"
        // type — using it here previously made every row resolve to the same blank (""),
        // collapsing all categories onto the same x-slot and producing garbled/ghost bars.
        scales: {
            bottom: { type: "text", text: "category" },
            left:   { type: "numeric" }
        },
        // Data-driven legend (one item per category/bar, via suite.js Legend._getData's
        // `config.values` branch - see suite.js ~line 13462) instead of the default series-driven
        // legend (one item per series). This chart only ever has one series ("Requested Hours"),
        // so a series-driven legend would show exactly one flat swatch - wrong once individual
        // bars carry their own "Skill Code"."Bar Color" override. `barColor` is the field added
        // to each `data` row above.
        legend: {
            values: { text: "category", color: "barColor" },
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

    // The legend above is now data-driven (one item per category, via legend.values) rather than
    // series-driven, so the library's own "click a legend item to hide/show" wiring resolves
    // incorrectly for this chart's shape: Legend's onclick fires the toggleSeries event as
    // (item.id, config.values) - see suite.js ~line 13287 - and since config.values is a truthy
    // object, Chart._initEvents' toggleSeries handler (suite.js ~line 13199) always takes its
    // "pieLike" branch and toggles the chart's ONE series ("s0") active/inactive, regardless of
    // WHICH category's legend item was actually clicked (Bar/ScaleSeria's inherited toggle() -
    // suite.js ~line 5250 - ignores the id argument entirely). That means clicking any single
    // skill's legend swatch would blank out EVERY bar, and clicking again (any item) brings
    // everything back - a confusing bait-and-switch that has nothing to do with the item that was
    // actually clicked. Rather than try to reimplement per-category show/hide, left-click on a
    // legend item is deliberately made a no-op by detaching the chart's own toggleSeries listener
    // entirely. Right-click "Show Data" on the legend (ResolveLegendSegmentFromEvent) is
    // unaffected - it is wired through our own contextmenu delegate on chartContainer, not
    // through this event.
    chartInstance.events.detach("toggleSeries");

    // Stash for the right-click "Show Data" handler (ResolveBarSegmentFromEvent) - see
    // lastCategories' own declaration comment. Read from here rather than this call's local
    // `categories` closure so a later click always resolves against whatever is CURRENTLY
    // rendered, not whatever was rendered when BOOT first ran.
    lastCategories = categories;

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
    ApplyBarColorOverrides(barColors);

    // Bar click -> BC (mirrors OnEventDoubleClick's InvokeExtensibilityMethod pattern
    // used throughout src/dhx/resourceschedule/wrapper.js). id is the Skill Code we
    // set as each data row's "id"/"category" above.
    chartInstance.events.on("serieClick", function(id) {
        try {
            Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("OnDataPointClicked", [String(id)]);
        } catch (e) { /* ignore */ }
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

// Overrides individual bars' fill colour per "Skill Code"."Bar Color" (codeunit 50608's
// GetSkillBarColor), on top of the one flat SERIES_COLOR_PALETTE colour dhx.Chart already
// painted the whole "Requested Hours" series with. dhx.Chart's Bar series (suite.js) only
// exposes a single `fill` per SERIES, not per data point/category, so there is no config-level
// way to ask for this - instead this walks the already-rendered SVG bars directly and sets
// each <path>'s `fill` attribute (which paint() set inline, not via CSS, so an attribute
// override here always wins with no specificity fight - confirmed there is no competing CSS rule
// for `.seria path` fill in suite.css either).
//
// barColors is parallel to `categories`/`lastCategories` (blank/undefined entry = leave that
// bar at its default series colour). Relies on the same "path index within its `g[aria-label^=
// "chart s"]` group == category index" ordering documented on ResolveBarSegmentFromEvent below.
//
// WHY A SINGLE requestAnimationFrame WAS NOT ENOUGH (root cause of the "no per-skill colour shows
// at all" bug, fixed here 2026-08-11): suite.js's Chart constructor deliberately paints its FIRST
// pass at width=0/height=0 ("using zero values ensure that widget will not attempt to render self
// in the hidden state") and only paints its REAL geometry once its own internal ResizeObserver
// (see suite.js's `resizer()` helper, mounted as a hidden child of the chart root) reports the
// container's true size. That second, real-geometry paint is an async signal with no guaranteed
// ordering against a single requestAnimationFrame scheduled right after `new dhx.Chart(...)`, and
// when it lands, the library's own vdom patch resets every <path>'s `fill` attribute straight
// back to the series' configured default - silently wiping out whatever override a one-shot rAF
// had already applied to the earlier, degenerate (width=0) paint. That is exactly why every bar
// rendered at the flat default colour with no per-skill override visible, regardless of "Skill
// Code"."Bar Color" - a single rAF either ran before the real paths existed (no-op) or got
// overwritten moments later by the real-geometry repaint.
//
// Fix: watch chartContainer for ANY DOM mutation (not just resize) via MutationObserver and
// reapply the overrides every time one lands, guarded by `applying` so our own attribute writes
// don't re-trigger themselves. This stays correct no matter how many repaint passes dhx.Chart
// performs or what triggers them (initial layout settle, or a later real resize e.g. the user
// resizing the browser window or the FactBox pane) - not just the very first one.
function ApplyBarColorOverrides(barColors) {
    if (barColorObserver) {
        barColorObserver.disconnect();
        barColorObserver = null;
    }
    if (!chartContainer || !barColors.length) return;

    var applying = false;

    function paintOverrides() {
        var group = chartContainer.querySelector('g[aria-label^="chart s"]');
        if (!group) return;
        applying = true;
        var paths = group.querySelectorAll("path");
        paths.forEach(function(pathEl, idx) {
            var override = barColors[idx];
            if (override && pathEl.getAttribute("fill") !== override) {
                pathEl.setAttribute("fill", override);
            }
        });
        applying = false;
    }

    requestAnimationFrame(paintOverrides);

    if (typeof MutationObserver !== "undefined") {
        barColorObserver = new MutationObserver(function() {
            if (applying) return;
            requestAnimationFrame(paintOverrides);
        });
        barColorObserver.observe(chartContainer, {
            childList: true,
            subtree: true,
            attributes: true,
            attributeFilter: ["fill"]
        });
    }
}

// ============================================================
// Right-click "Show Data" - single bar and legend entry
// ============================================================

// Resolves a right-click target to the specific BAR it landed on - i.e. one category (Skill Code,
// or the synthetic 'CAPACITY' marker), since this chart has exactly one series and exactly one
// bar per category (no per-day stacking, unlike the live barchart - see lastCategories' own
// declaration comment). Bars paint their <path>s into a `g[aria-label="chart s0"]` wrapper
// (suite.js's Bar.paint sets this aria-label from the series' own id - same mechanism the live
// barchart's wrapper.js relies on), in the same left-to-right order as `lastCategories`, so the
// clicked <path>'s index within that group IS the category index directly. Returns null when the
// click did not land on a bar at all (empty background, axis, legend - see
// ResolveLegendSegmentFromEvent for the legend case).
function ResolveBarSegmentFromEvent(e) {
    var pathEl = e.target.closest ? e.target.closest("path") : null;
    if (!pathEl) return null;
    var group = pathEl.closest('g[aria-label^="chart s"]');
    if (!group) return null;

    var paths = Array.prototype.slice.call(group.querySelectorAll("path"));
    var pIdx = paths.indexOf(pathEl);
    if (pIdx < 0 || pIdx >= lastCategories.length) return null;

    return { segmentId: lastCategories[pIdx] };
}

// Resolves a right-click target to the LEGEND entry. This chart only ever has one series
// ("Requested Hours"), so there is nothing to identify beyond "the legend was clicked" - the AL
// side (codeunit 50608's ShowSegmentData) treats a legend click as "every skill bar combined",
// the closest analog to the live barchart's "whole week instead of one day" broadening (there is
// no day axis here to broaden along - see that procedure's own doc comment for the full
// reasoning). Matches the live barchart wrapper.js's `.legend-item` DOM shape.
function ResolveLegendSegmentFromEvent(e) {
    var item = e.target.closest ? e.target.closest(".legend-item") : null;
    if (!item) return null;
    return {};
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
// left-click/scroll/Escape (exactly "right-click several different bars in a row") leaves every
// prior invocation's "click"/"scroll"/"keydown" listeners permanently attached to `document` (only
// "contextmenu" self-cleaned, since each NEW right-click's own contextmenu event bubbles to
// `document` and fires the previous one) - unbounded growth, one full set per right-click, which is
// what made the page feel like it was hanging after clicking around for a while. Same root cause
// and fix as src/dhx/barchart_daily/wrapper.js's HideContextMenu (fixed there first). Explicit tracking +
// removal in HideContextMenu (called at the START of every ShowContextMenu, not just on dismissal)
// caps this at exactly one attached set, always.
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
