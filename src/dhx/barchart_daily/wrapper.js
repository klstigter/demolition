// ============================================================
// State
// ============================================================
var chartContainer;         // DOM element reference (readiness flag)
var chartInstance = null;   // current dhx.Chart instance (recreated on every LoadData)

// Latest render input, kept around so the right-click "Show Data" handler can resolve a clicked
// bar's <path> index back to the Skill Code (or the synthetic 'CAPACITY' marker) it belongs to -
// every series here still has exactly one bar (<path>) per category, so a <path>'s index within
// ITS OWN series group IS the category index directly, regardless of which series the click
// actually landed on - CAPACITY's own 4 stacked segments, the single shared "Requested - Assigned"
// series every skill bar's bottom segment belongs to, or one of the per-skill "<Skill> -
// Unassigned" series (see codeunit 50608's AddCapacitySegmentSeries/AddRequestedAssignedSeries/
// AddSkillUnassignedSeries). ResolveBarSegmentFromEvent's `.closest('g[aria-label^="chart s"]')`
// always resolves to the specific group the clicked <path> is actually IN, not merely the first
// one in the document, so no per-series day/2-style index math is needed here (unlike the live
// barchart, which stacks 2 bars per weekday and needs a day/2 + even-odd split - see
// src/dhx/barchart_weekly/wrapper.js's own ResolveBarSegmentFromEvent).
var lastCategories = [];
var lastFontColors = []; // stashed by RenderChart for ApplyLegendTextColors' per-item text-colour pass - see fontColors' own declaration comment in RenderChart.
var contextMenuEl = null; // the current "Show Data" right-click popup, if one is open (see ShowContextMenu/HideContextMenu)
var contextMenuDismissHandlers = null; // {click,contextmenu,scroll,keydown} currently attached to
// document for dismissing the open "Show Data" popup, or null if none attached - see ShowContextMenu/
// HideContextMenu for why this is tracked explicitly instead of relying on {once:true} self-removal.

var seriesBorderObserver = null; // MutationObserver that keeps ApplySeriesBorders' <path> stroke
// patches in sync with dhx.Chart's OWN repaint passes - see that function's own comment for why a
// single requestAnimationFrame after construction is not sufficient here. (Named seriesBorderObserver,
// not barColorObserver, since 2026-08-19: every bar segment now gets its real colour from a true
// per-series `color` in the chart config itself - see RenderChart's own comment on the `s.color`
// contract - so the DOM-patch fill-override pass this observer used to ALSO drive was retired as
// dead weight, leaving only the border-stroke pass.)
var lastSeriesDefs = []; // stashed by RenderChart for ApplySeriesBorders' border pass - see that var's own comment in src/dhx/barchart_weekly/wrapper.js for the equivalent.
var lastSeries = [];     // ditto - the series actually handed to dhx.Chart (ids/colors), needed to scope each border to its own `g[aria-label="chart s<N>"]` group.

var lastChartData = null; // the raw chartData object last passed to RenderChart, stashed so
// CorrectLegendTopOverflowIfNeeded (see ScheduleLegendPatches) can trigger a corrective re-render
// with a larger legend.size without the caller needing to keep its own reference around.
var lastLegendSize = 40;  // the config.legend.size actually used by the most recent RenderChart
// call - 40 is suite.js's own default reserved top margin when legend.size is left unset (Legend.
// scaleReady, suite.js ~13317). CorrectLegendTopOverflowIfNeeded reads this to compute how much
// MORE space is needed rather than assuming the un-corrected default every time.

var lastRenderedWidth = 0; // chartContainer.clientWidth at the time of the most recent RenderChart
// call - see the BOOT ResizeObserver's own comment for why this is needed: dhx.Chart's own internal
// ResizeObserver repaints bars/scales when the container resizes, but does NOT recompute the
// legend's row-wrap decision against the new width (confirmed live 2026-09-07: BC's role-center
// flex layout can settle into its FINAL column width - e.g. a 3-column-vs-2-column split - only
// AFTER this control add-in has already done its first paint at whatever transient width the DOM
// had at that moment, and the legend keeps wrapping against that stale width forever after,
// visually bleeding past chartContainer's own right edge into a neighbouring role-center panel).

var legendPatchObserver = null; // MutationObserver mirroring src/dhx/barchart_weekly/wrapper.js's
// own repaint-reactive SchedulePostRenderPatches (see that file's BOOT comment for the full
// reasoning this is ported from). Reapplies ApplyLegendTextColors + the legend top-overflow
// correction on EVERY dhx.Chart repaint, not just the first construction. This is NOT optional
// polish: dhx.Chart's own internal ResizeObserver settle pass does a FULL vdom rebuild of the
// chart's SVG (fresh <text> nodes, no inline style/colour) sometime shortly after construction -
// confirmed live via Playwright (2026-09-07) that a one-shot rAF tied only to the initial
// RenderChart call (this file's original design) reliably loses that race: whatever a single
// post-construction pass applied would get silently wiped by that later repaint, with nothing
// left to re-apply it - same reasoning ApplySeriesBorders' own seriesBorderObserver already
// documents for the unrelated border-stroke problem below. (This file previously also rotated
// each legend label -90deg here - retired 2026-09-07 in favour of a plain horizontal legend
// matching src/dhx/barchart_weekly/wrapper.js's own appearance; the repaint-reactive machinery
// stays, since un-rotated legend items can still row-wrap and clip the same way Weekly's do.)
var pendingLegendPatchFrame = null;

// Distinct, fixed colours per series ordinal — DHTMLX Suite's Chart lets us set
// series.color explicitly (see Chart.setConfig / BaseSeria._setDefaults in suite.js),
// unlike BC's native BusinessChart add-in which has no colour API at all and just
// hands Highcharts a fixed M365 palette (see the comment block in
// src/page/page_50690_RequestedVsCapacitySkills.al around line 169-183). That is the
// whole reason this DHTMLX proof-of-concept exists, so we always assign an explicit
// colour per series here rather than relying on the library's own default palette.
// NOTE: this is a separate, currently-dead generic-series fallback palette - intentionally
// distinct from AL codeunit 50609 "Color Constants Opti."'s skill-bar 5-colour palette. Do not
// "fix" these into matching each other.
var SERIES_COLOR_PALETTE = ["#2A9D8F", "#E76F51", "#11A3D0", "#E5A910", "#985F99", "#78586F"];

// ============================================================
// Header (title + period line) - plain HTML rendered above chartContainer, replacing the
// field(PeriodLabelCtrl)/group(Filters) Caption that page 50707 "Requested vs Capacity Daily P"
// used to render via its own AL page layout (see that page's own layout() area comment for the
// full reasoning: those BC-rendered elements were constraining this control's own width once it
// stopped being the page's only content). Order is Title -> "Period: <value>" -> (dhx.Chart's own
// legend, valign:"top", inside chartContainer below this) -> plot - confirmed 2026-09-07.
//
// Deliberately styled DISTINCT from BC's own field-caption/FastTab-caption look (an accent-barred
// title instead of a plain bold line, a single muted "Period: ..." line instead of a stacked
// grey-caption-over-value pair) - a round-1 version of this header used the stacked
// caption-over-value BC-field look and the user could not visually tell it apart from an actual
// BC field, even though it was already a plain DOM element with no BC control wrapping it. Both
// elements also carry a `data-dhx-header` marker attribute for unambiguous DOM inspection (a real
// BC field/group would carry BC's own smart-*/control-* wrapper classes/attributes, never this
// one).
//
// This wrapper.js file is SHARED with page 50681 "Requested vs Capacity Daily" (the live,
// standalone, PageType=Card version of this chart - see DHXBarChartAddin_daily's own Scripts
// property) - that page keeps its OWN field(PeriodLabelCtrl)/group(Filters) Caption in its AL
// layout, untouched, and never sends 'periodLabel'/'title' in its ChartData JSON. UpdateHeader
// therefore hides headerEl entirely whenever BOTH keys are absent, so this header stays fully
// inert (no blank label row, no reserved space) on page 50681 - only page 50707 (which now DOES
// send both keys - see that page's RefreshChart) ever shows it.
// ============================================================
function BuildHeader(addin) {
    var headerEl = document.createElement("div");
    headerEl.id = "dhx-barchart-headerinfo";
    headerEl.setAttribute("data-dhx-header", "true");
    headerEl.style.cssText = "flex:0 0 auto;padding:4px 4px 8px 8px;display:none;border-left:3px solid #2A9D8F;";

    // Title FIRST (top of the header) - accent-barred (via headerEl's own border-left above) and
    // bold, deliberately not matching BC's own plain group-caption typography.
    var titleEl = document.createElement("div");
    titleEl.id = "dhx-barchart-title";
    titleEl.setAttribute("data-dhx-header", "true");
    titleEl.style.cssText = "font-size:14px;line-height:18px;font-weight:700;color:#242424;";

    // Period SECOND, directly below the title - a single "Period: <value>" line (no separate
    // small-caps label row) in a muted, smaller, italic style so it reads as a subtitle, not a BC
    // field value.
    var periodEl = document.createElement("div");
    periodEl.id = "dhx-barchart-period-value";
    periodEl.setAttribute("data-dhx-header", "true");
    periodEl.style.cssText = "font-size:12px;line-height:16px;font-style:italic;color:#5f6368;margin-top:2px;";

    headerEl.appendChild(titleEl);
    headerEl.appendChild(periodEl);
    addin.appendChild(headerEl);
}

// Called at the top of every RenderChart - see BuildHeader's own comment for why hiding headerEl
// entirely (rather than just leaving values blank) is what keeps this a no-op on page 50681, which
// never sends either key.
function UpdateHeader(chartData) {
    var headerEl = document.getElementById("dhx-barchart-headerinfo");
    if (!headerEl) return;

    var periodLabel = (chartData && chartData.periodLabel) ? String(chartData.periodLabel) : "";
    var title = (chartData && chartData.title) ? String(chartData.title) : "";

    if (!periodLabel && !title) {
        headerEl.style.display = "none";
        return;
    }
    headerEl.style.display = "";

    var titleEl = document.getElementById("dhx-barchart-title");
    if (titleEl) {
        titleEl.style.display = title ? "" : "none";
        titleEl.textContent = title;
    }

    var periodEl = document.getElementById("dhx-barchart-period-value");
    if (periodEl) {
        periodEl.style.display = periodLabel ? "" : "none";
        // Single "Period: <value>" line - PeriodLabelText already arrives as e.g. "Daily: Mon 07
        // Sep 2026" (see page 50707's own DailyPeriodLabelLbl), so this is deliberately prefixed
        // with "Period: " rather than repeating/duplicating that "Daily:" wording.
        periodEl.textContent = "Period: " + periodLabel;
    }
}

// ============================================================
// BOOT – called by startupScript.js
// ============================================================
window.BOOT = function() {
    try {
        var addin = document.getElementById("controlAddIn");
        // overflow:hidden on BOTH the add-in host and the chart container is a deliberate hard
        // boundary: whatever causes the legend (or any future chart element) to compute its own
        // width wrong, nothing can ever visually bleed past this panel's own box into a
        // neighbouring role-center panel again - defense-in-depth alongside the real-width
        // re-render fix below (lastRenderedWidth), not a substitute for it.
        // display:flex/flex-direction:column (2026-09-07) so headerEl (see BuildHeader) and
        // chartContainer stack vertically and SHARE this box's fixed height, instead of both
        // independently claiming height:100% and overlapping - chartContainer's own flex:1 1 auto +
        // min-height:0 (below) is what lets it shrink to "whatever's left after headerEl" rather
        // than overflowing.
        addin.style.cssText = "width:100%;height:100%;margin:0;padding:0;overflow:hidden;display:flex;flex-direction:column;";

        BuildHeader(addin);

        chartContainer = document.createElement("div");
        chartContainer.id = "dhx-barchart-container";
        // flex:1 1 auto + min-height:0 (not height:100%, which would ignore headerEl's own height
        // and force an overflow now that addin is a flex column) - see addin.style.cssText's own
        // comment.
        chartContainer.style.cssText = "width:100%;flex:1 1 auto;min-height:0;overflow:hidden;";
        addin.appendChild(chartContainer);

        // ---- Check library ----
        if (typeof dhx === "undefined" || !dhx.Chart) {
            console.error("DHTMLX Suite library (suite.js) not found. Please include it in ControlAddIn Scripts.");
            return;
        }

        // ---- Render an empty chart so the control has something to show immediately ----
        RenderChart({ categories: [], series: [] });

        // See legendPatchObserver's own declaration comment for why this repaint-reactive
        // reapplication is required, not just a one-shot pass at construction time - ported from
        // src/dhx/barchart_weekly/wrapper.js's own BOOT, which established this same pattern first.
        // childList+subtree catches dhx.Chart's internal repaint (a full node teardown/rebuild);
        // disconnect/reconnect around our OWN writes (see ScheduleLegendPatches) stops that from
        // re-triggering itself in a loop.
        if (typeof MutationObserver !== "undefined") {
            legendPatchObserver = new MutationObserver(function() {
                if (chartInstance) ScheduleLegendPatches();
            });
            legendPatchObserver.observe(chartContainer, { childList: true, subtree: true });
        }
        // Two-tier resize handling. A resize that only repositions existing elements (attribute
        // changes, no node add/remove) wouldn't trip the MutationObserver above, but could still
        // change how many rows the legend wraps onto - so ANY resize at minimum re-runs
        // ScheduleLegendPatches (defense-in-depth, same reasoning as
        // src/dhx/barchart_weekly/wrapper.js's own BOOT). But a genuine WIDTH change needs more
        // than that: dhx.Chart's own internal ResizeObserver repaints bars/scales for a resize, but
        // does NOT recompute the legend's horizontal row-wrap decision against the new width - it
        // keeps whatever wrap it decided on at construction. Confirmed live 2026-09-07: BC's
        // role-center flex layout can settle into its FINAL column width only AFTER this control
        // add-in's first paint (e.g. changing from a 3-column to a 2-column split once the page
        // finishes laying out), and the legend kept wrapping against that earlier, stale width -
        // all 8-ish legend items tried to stay on one row and ran off chartContainer's own right
        // edge into the neighbouring panel (the overflow:hidden above stops the visual bleed, but
        // the legend was still measuring itself wrong). Fix: track the container width the chart
        // was last actually built against (lastRenderedWidth, set in RenderChart) and force a real
        // RenderChart rebuild - not just a patch pass - whenever the container's current width has
        // genuinely moved (a couple of px of tolerance for sub-pixel layout noise), so the legend's
        // row-wrap math always runs against the CURRENT real width.
        if (typeof ResizeObserver !== "undefined") {
            new ResizeObserver(function() {
                if (!chartInstance || !chartContainer) return;
                var currentWidth = chartContainer.clientWidth;
                if (Math.abs(currentWidth - lastRenderedWidth) > 2) {
                    RenderChart(lastChartData, lastLegendSize);
                } else {
                    ScheduleLegendPatches();
                }
            }).observe(chartContainer);
        }

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
// Build/replace the vertical bar chart. Grouped (clustered, non-stacked) by default; switches to
// a stacked layout when any series requests it - true for every category now (see codeunit
// 50608's AddCapacitySegmentSeries/AddRequestedAssignedSeries/AddSkillUnassignedSeries: the
// CAPACITY bar's 4 Assigned/Free Capacity segments, and every SKILL bar's own 2-segment
// Assigned/Unassigned stack) - same opt-in mechanism as src/dhx/barchart_weekly/wrapper.js's own
// RenderChart.
//
// chartData shape (see LoadData below):
//   { categories: ["SKILL1","SKILL2","CAPACITY",...],
//     series: [ { name: "Requested - Assigned", values: [decimal,...],
//                 color: "#RRGGBB" (optional, else SERIES_COLOR_PALETTE rotation),
//                 stacked: true (optional; any series requesting it stacks the whole chart),
//                 border: "#RRGGBB" (optional outline colour for e.g. an "External" segment) },
//               { name: "SKILL1 - Unassigned", values: [decimal,...], color: "#RRGGBB" } ],
//     colors: ["#RRGGBB", "", ...] }  (optional, parallel to categories - purely a legend-swatch
//                                      colour per category now - see the `data`-row comment below
//                                      and codeunit 50608's GetSkillBarColor/GetCapacitySegmentColors)
//
// Every category is now a true stack of exactly 2 (a SKILL bar: shared Assigned + that skill's
// own Unassigned) or 4 (the CAPACITY bar: Assigned/Free Capacity Internal/External) series, and
// every OTHER series carries 0 at any category it doesn't apply to (invisible, zero-height stack
// segment - same "0 elsewhere" convention codeunit 50662 already documents for its own weekly
// chart) - so a category's visible bar height is always just the sum of its own real segments,
// nothing borrowed from a shared flat series the way the old single "Requested Hours" series
// used to work (retired 2026-08-19 once every bar became a real multi-segment stack).
//
// Each built `data` row also carries a `barColor` field - purely a legend-swatch colour now (see
// the `legend` config below); it no longer drives any bar's actual fill (that now comes straight
// from each series' own `color` in the chart config - see the `series` mapping below and
// ApplySeriesBorders' own comment on why the old DOM-patch fill-override pass was retired
// alongside the flat series it existed to recolour). This drives the legend, which is configured
// as `legend: { values: { text: "category", color: "barColor" } }` - one item per category/bar
// rather than per series - so the legend's swatches always match each bar's own representative
// colour (that skill's own colour, or the CAPACITY bar's Free Capacity blue). See the comments
// next to that config below, and next to the chartInstance.events.detach("toggleSeries") call,
// for why the legend is data-driven here and why left-click on a legend item is deliberately a
// no-op as a result.
//
// The chart is fully torn down and rebuilt on every call rather than mutated in
// place — dhx.Chart's data/scales/series are cheapest to reason about as a clean
// rebuild (mirrors this project's existing "wipe and rebuild" convention, e.g.
// BuildResourcePanel in src/dhx/resourceschedule/wrapper.js).
// ============================================================
// Applies "Daily Optimizer Setup"."Tooltip Background Color"/"Tooltip Font Color" (via codeunit
// 50609's GetTooltipBackgroundColor/GetTooltipFontColor, sent as chartData.tooltipBg/
// chartData.tooltipFont) to dhx.Chart's own built-in hover tooltip (shown when hovering a bar -
// suite.js's generic ".dhx_tooltip"/".dhx_tooltip__text" classes, themed dark-grey/white by
// default via suite.css's --dhx-tooltip-background-dark/--dhx-color-white). This add-in has no
// dedicated style.css of its own (only suite.css is loaded - see the ControlAddin's
// StyleSheets), so the override is injected here instead of added to a stylesheet file.
// Idempotent - reuses the same <style> element across every RenderChart call instead of
// appending a new one each time.
var _tooltipStyleEl = null;
function ApplyTooltipColors(backgroundColorHex, fontColorHex) {
    if (!backgroundColorHex && !fontColorHex) return;
    if (!_tooltipStyleEl) {
        _tooltipStyleEl = document.createElement("style");
        document.head.appendChild(_tooltipStyleEl);
    }
    var bg = backgroundColorHex || "#ffffff";
    var font = fontColorHex || "#000000";
    _tooltipStyleEl.textContent =
        ".dhx_tooltip{ background-color:" + bg + " !important; }" +
        ".dhx_tooltip__text{ color:" + font + " !important; }";
}

function RenderChart(chartData, legendSizeOverride, isCorrectivePass) {
    if (!chartContainer) return;

    ApplyTooltipColors(chartData && chartData.tooltipBg, chartData && chartData.tooltipFont);
    UpdateHeader(chartData);

    lastChartData = chartData;
    // See lastRenderedWidth's own declaration comment and the BOOT ResizeObserver - stashed here,
    // at the START of every real build, so a later resize can tell whether the container has
    // ACTUALLY moved since this chart was built (vs. some other DOM mutation with no size change).
    lastRenderedWidth = chartContainer.clientWidth;

    if (!isCorrectivePass) {
        // Hidden until ScheduleLegendPatches' completion callback confirms the legend actually
        // fits (or, if not, until the corrective re-render it triggers finishes) - without this,
        // a container that needs correcting would otherwise flash the clipped first-pass layout
        // for one frame before growing to its corrected size. A corrective pass (isCorrectivePass)
        // is a nested RenderChart call from within that same still-hidden window, so it must NOT
        // re-hide (which would just extend the same hidden window, harmlessly, but there's nothing
        // to hide FROM at that point).
        chartContainer.style.visibility = "hidden";
    }

    // See getDefaultMargin/Legend.scaleReady in suite.js (~13250-13268, ~13317): legend.size is
    // the ONLY thing that controls how much top margin the library reserves for the legend
    // (sizes.top) - the legend's own local position within that reserved band (Legend.paint's
    // positionY) is independent of it. CorrectLegendTopOverflowIfNeeded exploits exactly this:
    // bumping legend.size by the measured overflow shifts the whole legend down by that same
    // amount, cancelling the clip with no need to replicate the library's own row-wrap math.
    var legendSize = legendSizeOverride || 40;
    lastLegendSize = legendSize;

    var categories = (chartData && Array.isArray(chartData.categories)) ? chartData.categories : [];
    var seriesDefs  = (chartData && Array.isArray(chartData.series))     ? chartData.series     : [];
    var barColors   = (chartData && Array.isArray(chartData.colors))    ? chartData.colors     : [];
    // Per-category legend TEXT colour (codeunit 50609's GetSkillFontColor, one per skill row -
    // blank/default black for the CAPACITY row - see the AL side's RefreshChart). Applied in
    // ApplyLegendTextColors below, index-aligned with categories/legend items (both are built in
    // the same Buffer row order).
    var fontColors  = (chartData && Array.isArray(chartData.fontColors)) ? chartData.fontColors : [];

    // One data row per category ("id" doubles as the click-handler's row identifier —
    // dhx.Chart's bar click handler fires with (id, seriesValueField), see suite.js
    // Bar._getForm()'s onclick wiring), one field per series (s0, s1, ...).
    var data = categories.map(function(cat, idx) {
        var row = { id: String(cat), category: String(cat) };
        seriesDefs.forEach(function(s, sIdx) {
            var values = (s && Array.isArray(s.values)) ? s.values : [];
            row["s" + sIdx] = (values[idx] !== undefined && values[idx] !== null) ? values[idx] : 0;
        });
        // Legend-swatch colour only - see the shape-comment above RenderChart for why this no
        // longer drives any bar's actual fill.
        row.barColor = barColors[idx] || SERIES_COLOR_PALETTE[0];
        return row;
    });

    // A series carries its own explicit `color` when the caller wants a fixed palette instead
    // of the generic SERIES_COLOR_PALETTE rotation (e.g. the CAPACITY bar's Assigned/Free Capacity
    // segments, which must render Weekly's exact green/blue tokens - see codeunit 50608's
    // AddCapacitySegmentSeries) - same `s.color` contract src/dhx/barchart_weekly/wrapper.js
    // already uses.
    var series = seriesDefs.map(function(s, sIdx) {
        var seriesDef = {
            id:    "s" + sIdx,
            value: "s" + sIdx,
            label: (s && s.name) ? s.name : ("Series " + (sIdx + 1)),
            color: (s && s.color) ? s.color : SERIES_COLOR_PALETTE[sIdx % SERIES_COLOR_PALETTE.length]
        };
        if (s && s.stacked) {
            seriesDef.stacked = true;
        }
        return seriesDef;
    });
    // Any series requesting `stacked` switches the WHOLE chart to a stacked layout (suite.js
    // reads `stacked` per-series but a mixed stacked/unstacked chart within one config is not a
    // shape this chart needs) - matches src/dhx/barchart_weekly/wrapper.js's own isStacked flag.
    // Every category is a genuine multi-segment stack now (a SKILL bar: shared "Requested -
    // Assigned" + that skill's own "Unassigned"; the CAPACITY bar: its own 4 Assigned/Free
    // Capacity segments - see codeunit 50608's AddRequestedAssignedSeries/AddSkillUnassignedSeries/
    // AddCapacitySegmentSeries) - every OTHER series still carries 0 at any category it doesn't
    // apply to, contributing no visible height there, same "0 elsewhere" convention as before.
    var isStacked = seriesDefs.some(function(s) { return s && s.stacked; });
    if (isStacked) {
        series.forEach(function(s) { s.stacked = true; });
    }

    var config = {
        type: "bar",
        data: data,
        series: series,
        // Wider than suite.js's own Bar default (30px, see Bar.prototype._setDefaults) - with
        // only a handful of categories per day, 30px left large empty gaps either side of each
        // bar; widened so bars read as the dominant shape and gaps stay proportionate. Sourced
        // from AL's "Daily Optimizer Setup"."Bar Width (px) - Bar Chart" (codeunit 50609 "Visual
        // Default Settings"' GetDailyBarChartWidth), falling back to 50 (matching that codeunit's
        // own DefaultDailyBarWidthPx) if the setup field wasn't sent or is falsy - same defensive
        // style as categories/seriesDefs/barColors above.
        barWidth: (chartData && chartData.barWidth) ? chartData.barWidth : 50,
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
        // legend (one item per series). This chart has many series now (each skill's own
        // Assigned/Unassigned pair, CAPACITY's own 4 segments) - a series-driven legend would show
        // one swatch per SEGMENT (e.g. two separate "SKILL1 - Unassigned"/"Requested - Assigned"
        // entries for one bar), not one per bar - `barColor` (see the `data` row above) gives each
        // bar exactly one representative swatch instead.
        legend: {
            values: { text: "category", color: "barColor" },
            halign: "right",
            valign: "top",
            // Explicit reserved top margin - see legendSize's own comment above, and
            // MeasureLegendTopOverflow's root-cause writeup below. Left at the library's own
            // default (40) on a normal first pass; bumped by CorrectLegendTopOverflowIfNeeded on a
            // corrective re-render when that default wasn't enough room for however many rows this
            // chart's legend items actually wrap onto - same fix as src/dhx/barchart_weekly/
            // wrapper.js's own legend.size.
            size: legendSize
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
    // "pieLike" branch and toggles exactly ONE series ("s0", whichever series that happens to be -
    // it never looks at which category's legend item was actually clicked (Bar/ScaleSeria's
    // inherited toggle() - suite.js ~line 5250 - ignores the id argument entirely). That means
    // clicking any single skill's legend swatch would blank out that one series' segment on EVERY
    // bar it appears in, and clicking again (any item) brings it back - a confusing bait-and-switch
    // that has nothing to do with the item that was actually clicked. Rather than try to
    // reimplement per-category show/hide, left-click on a legend item is deliberately made a no-op
    // by detaching the chart's own toggleSeries listener entirely. Right-click "Show Data" on the
    // legend (ResolveLegendSegmentFromEvent) is unaffected - it is wired through our own
    // contextmenu delegate on chartContainer, not through this event.
    chartInstance.events.detach("toggleSeries");

    // Stash for the right-click "Show Data" handler (ResolveBarSegmentFromEvent) - see
    // lastCategories' own declaration comment. Read from here rather than this call's local
    // `categories` closure so a later click always resolves against whatever is CURRENTLY
    // rendered, not whatever was rendered when BOOT first ran.
    lastCategories = categories;
    lastFontColors = fontColors;
    // Stash for ApplySeriesBorders - both this call's own first application below AND any later
    // repaint-triggered re-application (see that function's own MutationObserver) need
    // seriesDefs/series to know which series carry a `border` colour (the CAPACITY bar's
    // "External" segments), mirroring src/dhx/barchart_weekly/wrapper.js's lastSeriesDefs/
    // lastSeries.
    lastSeriesDefs = seriesDefs;
    lastSeries = series;

    // Plain horizontal legend (same appearance as src/dhx/barchart_weekly/wrapper.js's own legend
    // - no rotation, matching that file's own ApplyLegendSwatchBorders-driven per-item colour
    // approach) - ApplyLegendTextColors below applies each legend item's own text colour, and
    // ScheduleLegendPatches keeps the reserved top margin correct for however many rows the
    // (unrotated) legend items actually wrap onto. Not just the initial pass - see
    // legendPatchObserver's own declaration comment for why this has to be repaint-reactive, not a
    // single one-shot call tied only to this specific RenderChart invocation.
    ScheduleLegendPatches();
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

// Applies each legend item's own text colour (codeunit 50609's GetSkillFontColor) to the plain,
// un-rotated <text class="legend-text"> the library already renders - one legend item per
// category/bar (data-driven legend, see RenderChart's own `legend.values` config), in the same
// order lastFontColors was built in. Deferred one frame past chart construction: dhx.Chart paints
// its SVG synchronously in practice, but querying immediately after `new dhx.Chart(...)` is
// fragile if that ever changes, so this waits a frame rather than assuming paint order.
//
// Previously also rotated each label -90deg here (retired 2026-09-07 - see legendPatchObserver's
// own comment for why): a plain horizontal legend matching src/dhx/barchart_weekly/wrapper.js's
// own appearance is simpler and doesn't need the rotated label's on-screen-height-is-the-original-
// text's-width accounting MeasureLegendTopOverflow used to have to compensate for.
//
// onDone (optional) is invoked after the colour pass completes, still inside that same deferred
// frame - ScheduleLegendPatches uses it to measure/self-correct the legend's reserved top space
// (see MeasureLegendTopOverflow/CorrectLegendTopOverflowIfNeeded below) once this function's own
// DOM writes have landed.
function ApplyLegendTextColors(onDone) {
    requestAnimationFrame(function() {
        if (!chartContainer) { if (onDone) onDone(); return; }
        var legendTexts = chartContainer.querySelectorAll(".legend-text");
        legendTexts.forEach(function(textEl, idx) {
            if (lastFontColors[idx]) {
                textEl.style.fill = lastFontColors[idx];
            }
        });
        if (onDone) onDone();
    });
}

// Measures how many px the legend's own top edge renders ABOVE the chart's <svg> top edge - i.e.
// clipped, since the SVG's default overflow behaviour never paints content above its own viewport.
// Root cause (confirmed by reading suite.js): the legend is painted inside a <g transform=
// "translate(sizes.left, sizes.top)"> (ComposeLayer.toVDOM, suite.js ~35544-35546), so the
// legend's local y=0 sits at global y = sizes.top (the reserved top margin, ~50px by default for
// a "top" legend - Legend.scaleReady, suite.js ~13317). Legend.paint's own positionY (suite.js
// ~13385-13389) is `-margin - yPadding - figureWidth/2`, where yPadding grows by `itemPadding+2`
// (22px) every time the row-wrap check (suite.js ~13357) wraps to a new legend row. With enough
// legend items to wrap even once, positionY comfortably outruns the ~50px reserved band, so the
// FIRST row's text renders at a global y at or below 0 - clipped - while later rows (pushed
// further down by their own yPadding) land safely inside the reserved band - exactly the "top row
// cut off, lower row fine" pattern, same root cause as src/dhx/barchart_weekly/wrapper.js's own
// legend. Returns 0 (never negative) when nothing is clipped.
function MeasureLegendTopOverflow() {
    if (!chartContainer) return 0;
    var svgEl = chartContainer.querySelector("svg");
    var legendGroup = chartContainer.querySelector('g[aria-label="Legend"]');
    if (!svgEl || !legendGroup) return 0;
    var svgRect = svgEl.getBoundingClientRect();
    var legendRect = legendGroup.getBoundingClientRect();
    var overflow = svgRect.top - legendRect.top;
    return overflow > 0 ? overflow : 0;
}

// Triggers a corrective re-render with a larger config.legend.size when the legend is clipped -
// see legendSize's own comment in RenderChart for why bumping size by precisely the measured
// overflow (plus a small buffer for sub-pixel/font-metric rounding) is mathematically enough to
// cancel the clip: size only shifts the whole legend down (global), it never changes the legend's
// own internal layout, so the previously-clipped region moves by exactly as much extra room as we
// reserve. Self-limiting rather than flag-guarded (same design as src/dhx/barchart_weekly/
// wrapper.js's own CorrectLegendTopOverflowIfNeeded, and for the same reason: with a persistent
// repaint-reactive scheduler - see legendPatchObserver's own comment - there is no single "the
// corrective render" call to flag as exempt, since ANY render, corrective or not, can be repainted
// again later by dhx.Chart's own internal settle pass): a 1px tolerance (measurement noise) plus a
// generous size cap (400px) means that once a correction has actually fixed the clip, this becomes
// a no-op on every later call, including the repaint the correction's own RenderChart call
// triggers and any genuine later resize.
function CorrectLegendTopOverflowIfNeeded() {
    var overflow = MeasureLegendTopOverflow();
    if (overflow <= 1 || lastLegendSize >= 400) return false;
    var newSize = lastLegendSize + Math.ceil(overflow) + 4;
    RenderChart(lastChartData, newSize, true);
    return true;
}

// Schedules (de-duplicated - a burst of mutation/resize signals collapses to one pass) a single
// frame-deferred re-application of ApplyLegendTextColors + the legend top-overflow correction. See
// legendPatchObserver's own declaration comment for why this has to be repaint-reactive at all
// (dhx.Chart's internal settle-repaint silently wipes any per-item colour a prior pass applied,
// and can change how many rows the legend wraps onto, leaving legend.size mismatched against
// whatever DID end up rendering). The observer is disconnected for the duration of the writes
// below and reconnected immediately after, so our own DOM writes (colour styles, and - if
// CorrectLegendTopOverflowIfNeeded fires - a full chart teardown/rebuild) can't re-trigger this
// same scheduler in a loop; mirrors src/dhx/barchart_weekly/wrapper.js's own
// SchedulePostRenderPatches exactly.
function ScheduleLegendPatches() {
    if (pendingLegendPatchFrame) return;
    pendingLegendPatchFrame = requestAnimationFrame(function() {
        pendingLegendPatchFrame = null;
        if (!chartContainer) return;
        if (legendPatchObserver) legendPatchObserver.disconnect();
        ApplyLegendTextColors(function() {
            var corrected = CorrectLegendTopOverflowIfNeeded();
            if (legendPatchObserver) legendPatchObserver.observe(chartContainer, { childList: true, subtree: true });
            // If a correction just fired, its own nested RenderChart call already scheduled
            // another ScheduleLegendPatches pass (via its own RenderChart tail) to verify/reveal
            // once that corrected render has ALSO had its colours re-applied - don't reveal a
            // still-hidden, not-yet-coloured container early.
            if (!corrected && chartContainer) chartContainer.style.visibility = "";
        });
    });
}

// Applies a CSS stroke to any bordered series' bars with a nonzero value for that category -
// ported from src/dhx/barchart_weekly/wrapper.js's ApplySeriesBorders (see that function's own
// comment for the full reasoning: Bar series has no stroke/outline config option, and a
// zero-value stacked segment still paints a real, if invisible-height, <path> at its baseline, so
// the stroke is only applied when that category's own value is actually nonzero). Scoped
// per-series by aria-label rather than by fill colour, since two different series can
// legitimately share one fill colour (the CAPACITY bar's Assigned Internal/External halves both
// use the same green).
//
// Currently only the CAPACITY bar's "External" segments (Assigned/Free Capacity, codeunit 50608's
// AddCapacitySegmentSeries) ever request a border - the per-skill Assigned/Unassigned segments
// (AddRequestedAssignedSeries/AddSkillUnassignedSeries) deliberately do NOT: that red-outline
// convention is specifically for the Internal/External capacity-SOURCE distinction, not the
// Assigned/Unassigned fulfillment-STATUS distinction added alongside this function - but this
// stays fully generic so any future bordered series works with no JS change.
//
// This used to be paired with a second "fill override" DOM patch (retired 2026-08-19, once every
// bar segment - skill Assigned/Unassigned, CAPACITY's 4 segments - got a real per-series `color`
// in the chart config itself, so no bar was still relying on a flat default series colour that
// needed overriding after the fact - see RenderChart's own comment on the `s.color` contract and
// on why the old single "Requested Hours" series was removed entirely). Keeping that DOM patch
// would now be actively wrong, not just redundant: it always targeted the FIRST
// `g[aria-label^="chart s"]` group under the old "exactly one series, N categories" chart shape,
// which no longer holds now that every category has its own dedicated series pair/quad - it would
// force-repaint whatever series happens to render first with an unrelated category's colour.
//
// WHY A SINGLE requestAnimationFrame IS NOT ENOUGH (same root cause originally diagnosed for the
// retired fill-override pass, fixed here 2026-08-11): suite.js's Chart constructor deliberately
// paints its FIRST pass at width=0/height=0 ("using zero values ensure that widget will not
// attempt to render self in the hidden state") and only paints its REAL geometry once its own
// internal ResizeObserver (see suite.js's `resizer()` helper, mounted as a hidden child of the
// chart root) reports the container's true size. That second, real-geometry paint is an async
// signal with no guaranteed ordering against a single requestAnimationFrame scheduled right after
// `new dhx.Chart(...)`, and when it lands, the library's own vdom patch repaints every <path>
// fresh - silently wiping out whatever stroke a one-shot rAF had already applied to the earlier,
// degenerate (width=0) paint.
//
// Fix: watch chartContainer for ANY DOM mutation (not just resize) via MutationObserver and
// reapply the stroke every time one lands, guarded by `applying` so our own style writes don't
// re-trigger themselves. This stays correct no matter how many repaint passes dhx.Chart performs
// or what triggers them (initial layout settle, or a later real resize e.g. the user resizing the
// browser window or the FactBox pane) - not just the very first one.
function ApplySeriesBorders(seriesDefs, series) {
    if (seriesBorderObserver) {
        seriesBorderObserver.disconnect();
        seriesBorderObserver = null;
    }
    if (!chartContainer) return;

    var applying = false;

    function paintBorders() {
        applying = true;
        (seriesDefs || []).forEach(function(s, sIdx) {
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
        applying = false;
    }

    requestAnimationFrame(paintBorders);

    if (typeof MutationObserver !== "undefined") {
        seriesBorderObserver = new MutationObserver(function() {
            if (applying) return;
            requestAnimationFrame(paintBorders);
        });
        seriesBorderObserver.observe(chartContainer, {
            childList: true,
            subtree: true
        });
    }
}

// ============================================================
// Right-click "Show Data" - single bar and legend entry
// ============================================================

// Resolves a right-click target to the specific BAR it landed on - i.e. one category (Skill Code,
// or the synthetic 'CAPACITY' marker) - since every series here still has exactly one bar per
// category (no per-day stacking, unlike the live barchart - see lastCategories' own declaration
// comment). Bars paint their <path>s into a `g[aria-label="chart s<N>"]` wrapper per series
// (suite.js's Bar.paint sets this aria-label from the series' own id - same mechanism the live
// barchart's wrapper.js relies on); `.closest(...)` always resolves to whichever series group the
// clicked <path> actually belongs to - the shared "Requested - Assigned" series or one skill's own
// "Unassigned" series for a click on a SKILL bar, or one of the CAPACITY bar's own 4 stacked
// Assigned/Free Capacity segments for a click on that bar - in the same left-to-right order as
// `lastCategories` either way, so the clicked <path>'s index within THAT group IS the category
// index directly. The returned segmentId is always just the CATEGORY text ("CAPACITY" or a Skill
// Code), never which specific stacked segment was clicked - codeunit 50608's ShowSegmentData
// already treats any click on a given bar identically regardless of which of its own segments was
// clicked, so no finer-grained segment identification is needed here. Returns null when the click
// did not land on a bar at all (empty background, axis, legend - see ResolveLegendSegmentFromEvent
// for the legend case).
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

// Resolves a right-click target to the LEGEND entry. The legend here is data-driven per
// CATEGORY, not per series (see RenderChart's own `legend.values` config), so - same as before
// this chart grew per-skill Assigned/Unassigned segments - there is nothing to identify beyond
// "the legend was clicked" - the AL side (codeunit 50608's ShowSegmentData) treats a legend click
// as "every skill bar combined", the closest analog to the live barchart's "whole week instead of
// one day" broadening (there is no day axis here to broaden along - see that procedure's own doc
// comment for the full reasoning). Matches the live barchart wrapper.js's `.legend-item` DOM shape.
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
