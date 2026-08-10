// ============================================================
// State
// ============================================================
var chartContainer;         // DOM element reference (readiness flag)
var chartInstance = null;   // current dhx.Chart instance (recreated on every LoadData)

// Latest render input, kept around so the right-click "Show Data" handler can resolve a clicked
// bar's <path> index back to the Skill Code (or the synthetic 'CAPACITY' marker) it belongs to -
// this chart has exactly one series/one bar per category, so a <path>'s index within its series
// group IS the category index directly (unlike the live barchart, which stacks 2 bars per weekday
// and needs a day/2 + even-odd split - see src/dhx/barchart/wrapper.js's ResolveBarSegmentFromEvent).
var lastCategories = [];
var contextMenuEl = null; // the current "Show Data" right-click popup, if one is open (see ShowContextMenu/HideContextMenu)
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
//     series: [ { name: "Requested Hours", values: [decimal,...] },
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
// and fix as src/dhx/barchart/wrapper.js's HideContextMenu (fixed there first). Explicit tracking +
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
