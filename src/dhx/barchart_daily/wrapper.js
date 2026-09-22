// ============================================================
// State
// ============================================================
var chartContainer;         // DOM element reference (readiness flag)
var chartInstance = null;   // current dhx.Chart instance (recreated on every LoadData)

// Latest render inputs, kept around so a resize-triggered re-application (see
// SchedulePostRenderPatches) can redraw the post-render patches without needing a fresh LoadData
// call - dhx.Chart itself repaints on container resize (via suite.js's own internal
// resizer()/ResizeObserver), which would otherwise silently wipe these patches. Ported 2026-09-22
// from src/dhx/barchart_weekly/wrapper.js's own state/patch pipeline, alongside the redesign of
// this chart from one-bar-per-skill (+ a synthetic CAPACITY bar) to a Capacity/Requested ("C"/"R")
// bar PAIR per skill, grouped the same way Weekly groups a day's own C/R pair - see RenderChart's
// own comment for the full category/series shape.
var lastSeriesDefs = [];
var lastSeries = [];
var lastSkillLabels = []; // parallel to the skill-pair grouping in "categories" - one entry per
// skill (in the same order as its C/R pair), used by RenderSkillGroupRow to draw the merged
// group-header row. Unlike src/dhx/barchart_weekly/wrapper.js's dayLabels/dayIndices pair, Skill
// Code is already a safe, non-locale-dependent string - see codeunit 50608's own doc comment - so
// there is no separate round-trip "indices" array here: ResolveBarSegmentFromEvent below resolves
// a bar click straight to its own category TEXT (which already carries the real Skill Code), not
// to a positional index that would need translating back.
var lastChartData = null; // the raw chartData object last passed to RenderChart, stashed so
// CorrectLegendTopOverflowIfNeeded (see SchedulePostRenderPatches) can trigger a corrective
// re-render with a larger legend.size without needing to reconstruct chartData's shape from the
// other already-stashed lastXxx arrays.
var lastLegendSize = 40;  // the config.legend.size actually used by the most recent RenderChart
// call - 40 is suite.js's own default reserved top margin when legend.size is left unset (Legend.
// scaleReady, suite.js ~13317). CorrectLegendTopOverflowIfNeeded reads this to compute how much
// MORE space is needed rather than assuming the un-corrected default every time.
var pendingPatchFrame = null;
var lastRenderedWidth = 0; // chartContainer.clientWidth at the time of the most recent RenderChart
// call - see the BOOT ResizeObserver's own comment for why this is needed: dhx.Chart's own internal
// ResizeObserver repaints bars/scales when the container resizes, but does NOT recompute the
// legend's row-wrap decision against the new width (confirmed live 2026-09-07: BC's role-center
// flex layout can settle into its FINAL column width - e.g. a 3-column-vs-2-column split - only
// AFTER this control add-in has already done its first paint at whatever transient width the DOM
// had at that moment, and the legend keeps wrapping against that stale width forever after,
// visually bleeding past chartContainer's own right edge into a neighbouring role-center panel).
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
// NOTE: this is a separate, currently-dead generic-series fallback palette - intentionally
// distinct from AL codeunit 50609 "Color Constants Opti."'s skill-bar 5-colour palette. Do not
// "fix" these into matching each other.
var SERIES_COLOR_PALETTE = ["#2A9D8F", "#E76F51", "#11A3D0", "#E5A910", "#985F99", "#78586F"];

// Bottom-axis "skill group" row (see RenderSkillGroupRow) - kept as named constants since the
// geometry math has to agree with the `bottom` scale's own `textPadding`/`size` config below.
// Ported 1:1 from src/dhx/barchart_weekly/wrapper.js's own CATEGORY_DELIMITER/BOTTOM_TEXT_PADDING/
// DAY_ROW_HEIGHT/BOTTOM_SCALE_RESERVED_PX/DAY_GROUP_* constants (renamed "day" -> "skill").
var CATEGORY_DELIMITER = "|";       // matches codeunit 50608's CategoryDelimiterTok
var BOTTOM_TEXT_PADDING = 12;       // matches scales.bottom.textPadding in RenderChart
var SKILL_ROW_HEIGHT = 24;          // px height of EACH of the 2 bottom-axis rows this chart draws
// (native "C"/"R" row + RenderSkillGroupRow's own hand-drawn Skill Code row).
//
// BOTTOM_SCALE_RESERVED_PX MUST stay numerically equal to src/dhx/barchart_weekly/wrapper.js's own
// BOTTOM_SCALE_RESERVED_PX (also 90, unchanged by this redesign - that file is out of scope) -
// confirmed live via Playwright (2026-09-11, re-confirmed 2026-09-17) that a chart's "0"-line/
// bar-baseline vertical position is `containerTop + containerHeight - scales.bottom.size`,
// independent of legend.size, so keeping this total reserved bottom height equal to Weekly's is
// what keeps the two role-center panels' x-axes aligned. This chart's own 2 rows (SKILL_ROW_HEIGHT
// each = 48px) only need half of the reserved 90px - the remaining 42px renders as blank space
// below the Skill Code row, same "leftover blank space" convention Weekly's own comment documents
// (previously the other way around, when THIS chart alone needed extra room for rotated labels -
// see CATEGORY_LABEL_ROTATE_DEG's own retirement note below).
var BOTTOM_SCALE_RESERVED_PX = 90;
// Matches the native plot area's own gridlines (suite.css: `.grid-line{stroke:var(--dhx-color-
// gray-100)}`, no explicit stroke-width -> browser default of 1px) rather than a bold black line,
// so the skill-group row's grid reads as part of the same chart instead of a heavier overlay.
var SKILL_GROUP_BORDER_COLOR = "var(--dhx-color-gray-100)";
var SKILL_GROUP_BORDER_WIDTH = 1;
// Lighter than SKILL_GROUP_BORDER_COLOR itself (suite.css has no gray shade lighter than gray-100)
// so the gray-100 divider lines still read against it instead of blending into plain white.
var SKILL_GROUP_BACKGROUND_COLOR = "#f7f7f7";

// Gap (px) between a skill's own Capacity/Requested bars once pulled tight together - see
// ApplySkillPairSpacing. Kept small but nonzero so the two bars still read as two distinct shapes
// instead of visually fusing into one block.
var PAIR_INNER_GAP_PX = 2;
// Reassigned on every RenderChart call from AL's "Daily Optimizer Setup"."Bar Width (px) - Bar
// Chart" (codeunit 50609 "Visual Default Settings"' GetDailyBarChartWidth), falling back to 50 if
// chartData.barWidth wasn't sent or is falsy (this chart's own historical default - wider than
// suite.js's own Bar default of 30px, see Bar.prototype._setDefaults). Kept as a module-level
// variable (not a fixed constant, matching src/dhx/barchart_weekly/wrapper.js's own BAR_WIDTH_PX)
// because ApplySkillPairSpacing computes bar-center offsets from it and nothing in the rendered
// DOM exposes barWidth directly to read back.
var BAR_WIDTH_PX = 50;

// Reinstated 2026-09-22 (explicit user request, live screenshot) after being retired earlier the
// same session: even sitting in its own horizontal group-header row (RenderSkillGroupRow), up to
// ~11 Skill Codes read as a cramped, hard-to-scan flat row once bars narrow enough - tilting the
// label -45deg (same angle/direction the old one-bar-per-skill layout used, see the removed
// CATEGORY_LABEL_ROTATE_DEG this replaces) reads more cleanly. Applied by hand via an SVG
// `transform="rotate(...)"` on each label in RenderSkillGroupRow (there is no suite.js native
// `scaleRotate` option for a hand-drawn row like this one - that config only applies to the
// library's own scale tick text). Negative so labels read bottom-left to top-right (ascending),
// matching the old constant's own documented reasoning.
var SKILL_LABEL_ROTATE_DEG = -45;

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
// therefore hides headerEl entirely whenever BOTH keys are absent AND showToolbar is falsy, so
// this header stays fully inert (no blank row, no reserved space) on page 50681 - only page 50707
// (which now sends both keys plus showToolbar - see that page's RefreshChart) ever shows it.
//
// headerEl is a single flex ROW (2026-09-16, per user request to match one highlighted bar in
// their mockup screenshot rather than a title/period block stacked above a separate toolbar row):
// the title+period text sits in its own textColEl column on the left, and BuildToolbar's buttons
// (see below) are appended directly into headerEl as a second flex child on the right - one row,
// not two. (The yellow highlight in that mockup was only the user's own screenshot annotation
// marking which area to change, not a requested background colour - no background is set here.)
// ============================================================
function BuildHeader(addin) {
    var headerEl = document.createElement("div");
    headerEl.id = "dhx-barchart-headerinfo";
    headerEl.setAttribute("data-dhx-header", "true");
    headerEl.style.cssText = "flex:0 0 auto;display:none;flex-direction:row;align-items:center;" +
        "justify-content:space-between;gap:8px;padding:6px 8px;border-left:3px solid #2A9D8F;";

    var textColEl = document.createElement("div");
    textColEl.id = "dhx-barchart-textcol";
    textColEl.setAttribute("data-dhx-header", "true");
    textColEl.style.cssText = "display:flex;flex-direction:column;min-width:0;";

    // Title FIRST (top of the column) - bold, deliberately not matching BC's own plain
    // group-caption typography.
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

    textColEl.appendChild(titleEl);
    textColEl.appendChild(periodEl);
    headerEl.appendChild(textColEl);

    BuildToolbar(headerEl);

    addin.appendChild(headerEl);
}

// ============================================================
// Toolbar (Refresh/Previous/Today/Next) - plain HTML buttons rendered above chartContainer,
// replacing the BC action bar (RefreshAction/PreviousAction/TodayAction/NextAction) page 50707
// "Requested vs Capacity Daily P" used to expose via its own actions() area, now retired: BC
// collapses a CardPart's action bar into a hidden "..." overflow menu once it's embedded in a
// Role Center (confirmed via screenshot - the user had to open a dropdown to find these), so
// rendering them as buttons INSIDE this add-in's own DOM keeps them always visible instead.
//
// Same opt-in mechanic as BuildHeader/UpdateHeader above, and for the same reason: this wrapper.js
// file is SHARED with page 50681 "Requested vs Capacity Daily" (see BuildHeader's own comment),
// which keeps its OWN BC action bar (never collapsed there - only a CardPart embedded in a Role
// Center collapses it) and never sends 'showToolbar' in its ChartData JSON. UpdateToolbar therefore
// hides toolbarEl whenever that key is absent/false, so this toolbar stays fully inert on page
// 50681 - only page 50707 (which now sends 'showToolbar': true - see that page's RefreshChart) ever
// shows it. Called by BuildHeader as a child of headerEl (one shared flex row with the title/period
// text - see BuildHeader's own comment), with its own visibility still driven purely by
// 'showToolbar', independent of headerEl's periodLabel/title presence check.
//
// Each button invokes a new, parameterless control add-in event (OnRefreshClicked/OnPreviousClicked/
// OnTodayClicked/OnNextClicked) via Microsoft.Dynamics.NAV.InvokeExtensibilityMethod - same
// call/try-catch pattern as the contextmenu "Show Data" handler in BOOT below. Page 50707's own
// usercontrol() trigger bodies for these events call the exact same local procedures
// (RefreshData/RefreshPeriod with PeriodStartDate -+ 1) its now-removed BC actions used to call -
// only the UI trigger moved, not the underlying round-trip or logic.
// ============================================================
function BuildToolbar(parentEl) {
    var toolbarEl = document.createElement("div");
    toolbarEl.id = "dhx-barchart-toolbar";
    toolbarEl.setAttribute("data-dhx-header", "true");
    toolbarEl.style.cssText = "flex:0 0 auto;display:none;gap:6px;";

    function addButton(id, label, eventName) {
        var btn = document.createElement("button");
        btn.id = id;
        btn.type = "button";
        btn.textContent = label;
        btn.style.cssText = "font-size:12px;line-height:16px;padding:3px 10px;" +
            "border:1px solid #c8c8c8;border-radius:3px;background:#ffffff;color:#242424;cursor:pointer;";
        btn.addEventListener("click", function() {
            try {
                Microsoft.Dynamics.NAV.InvokeExtensibilityMethod(eventName, []);
            } catch (err) { /* ignore */ }
        });
        toolbarEl.appendChild(btn);
    }

    addButton("dhx-barchart-btn-refresh", "Refresh", "OnRefreshClicked");
    addButton("dhx-barchart-btn-previous", "◀ Previous", "OnPreviousClicked");
    addButton("dhx-barchart-btn-today", "Today", "OnTodayClicked");
    addButton("dhx-barchart-btn-next", "Next ▶", "OnNextClicked");

    parentEl.appendChild(toolbarEl);
}

// Called at the top of every RenderChart alongside UpdateHeader - shows/hides the toolbar purely
// off chartData.showToolbar (deliberately NOT tied to UpdateHeader's own periodLabel/title presence
// check - see BuildToolbar's own comment), so this stays a no-op on page 50681, which never sends
// any of these keys.
function UpdateToolbar(chartData) {
    var toolbarEl = document.getElementById("dhx-barchart-toolbar");
    if (!toolbarEl) return;
    toolbarEl.style.display = (chartData && chartData.showToolbar) ? "flex" : "none";
}

// Called at the top of every RenderChart - see BuildHeader's own comment for why hiding headerEl
// entirely (rather than just leaving values blank) is what keeps this a no-op on page 50681, which
// never sends any of periodLabel/title/showToolbar. headerEl is now a single row shared with the
// toolbar (see BuildHeader's own comment) so its own show/hide also has to account for showToolbar,
// not just periodLabel/title - otherwise a chart that only ever sent showToolbar (hypothetically)
// would never reveal the row at all.
function UpdateHeader(chartData) {
    var headerEl = document.getElementById("dhx-barchart-headerinfo");
    if (!headerEl) return;

    var periodLabel = (chartData && chartData.periodLabel) ? String(chartData.periodLabel) : "";
    var title = (chartData && chartData.title) ? String(chartData.title) : "";
    var showToolbar = !!(chartData && chartData.showToolbar);

    if (!periodLabel && !title && !showToolbar) {
        headerEl.style.display = "none";
        return;
    }
    headerEl.style.display = "flex";

    var textColEl = document.getElementById("dhx-barchart-textcol");
    if (textColEl) textColEl.style.display = (periodLabel || title) ? "flex" : "none";

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

        BuildHeader(addin); // also builds the toolbar as headerEl's own child - see BuildHeader's own comment

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

        // dhx.Chart repaints its whole SVG - discarding every post-render DOM patch applied below
        // (series borders, the skill-group row, legend swatch borders) - for more reasons than
        // just a container resize (confirmed live via Playwright: a repaint can follow shortly
        // after the FIRST successful patch pass with no size change involved, most likely BC's own
        // factbox/page layout still settling). A MutationObserver watching for the library
        // replacing its own tick/legend/bar elements is a direct signal of "a repaint just
        // happened, reapply now" - disconnect/reconnect around our OWN writes below (see
        // SchedulePostRenderPatches) stops that from re-triggering itself in a loop. Ported 2026-
        // 09-22 from src/dhx/barchart_weekly/wrapper.js's own BOOT (this file previously used a
        // narrower, series-borders-only MutationObserver - see git history - now consolidated into
        // the same single-observer pipeline Weekly already established).
        if (typeof MutationObserver !== "undefined") {
            chartMutationObserver = new MutationObserver(function() {
                if (chartInstance) SchedulePostRenderPatches();
            });
            chartMutationObserver.observe(chartContainer, { childList: true, subtree: true });
        }
        // Two-tier resize handling - see src/dhx/barchart_weekly/wrapper.js's own BOOT comment for
        // the full reasoning (ported here unchanged): dhx.Chart's internal ResizeObserver repaints
        // bars/scales on resize but does NOT recompute the legend's row-wrap decision against the
        // new width, so a genuine width change needs a full RenderChart rebuild, not just a patch
        // pass.
        if (typeof ResizeObserver !== "undefined") {
            new ResizeObserver(function() {
                if (!chartInstance || !chartContainer) return;
                var currentWidth = chartContainer.clientWidth;
                if (Math.abs(currentWidth - lastRenderedWidth) > 2) {
                    RenderChart(lastChartData, lastLegendSize);
                } else {
                    SchedulePostRenderPatches();
                }
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
                            [legendHit.seriesName, true]
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
// Build/replace the vertical bar chart - stacked, grouped in Capacity/Requested PAIRS per Skill
// Code (redesigned 2026-09-22, replacing the old one-bar-per-skill + synthetic CAPACITY-bar
// layout - mirrors src/dhx/barchart_weekly/wrapper.js's own per-day C/R pair shape, grouped by
// Skill Code here instead of by weekday).
//
// chartData shape (see LoadData below):
//   { categories: ["SKILL1|Capacity","SKILL1|Requested","SKILL2|Capacity",...],
//     skillLabels: ["SKILL1","SKILL2",...],  (one entry per skill, same order as its C/R pair)
//     series: [ { name: "Assigned Capacity", values: [decimal,...],
//                 color: "#RRGGBB", stacked: true,
//                 border: "#RRGGBB" (optional outline colour, e.g. the red "External" segment),
//                 fontColor: "#RRGGBB" (optional per-skill legend TEXT colour) },
//               ... ] }
//
// Every category is a stack: the "Capacity" bar carries the 4 shared Assigned/Free-Capacity
// segments (nonzero only at that skill's own Capacity slot, 0 elsewhere - see codeunit 50608's
// AddCapacitySegmentSeries), the "Requested" bar carries the shared "Requested - Assigned" segment
// plus that skill's own "Unassigned" segment (nonzero only at that skill's own Requested slot, 0
// elsewhere - AddRequestedAssignedSeries/AddSkillUnassignedSeries) - same "0 elsewhere" stacked-
// series convention codeunit 50662 already documents for its own weekly chart.
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
    UpdateToolbar(chartData);

    lastChartData = chartData;
    // See lastRenderedWidth's own declaration comment and the BOOT ResizeObserver - stashed here,
    // at the START of every real build, so a later resize can tell whether the container has
    // ACTUALLY moved since this chart was built (vs. some other DOM mutation with no size change).
    lastRenderedWidth = chartContainer.clientWidth;

    if (!isCorrectivePass) {
        // Hidden until SchedulePostRenderPatches' first settled pass confirms the legend actually
        // fits (or, if not, until the corrective re-render it triggers finishes) - without this, a
        // container that needs correcting would otherwise flash the clipped first-pass layout
        // before growing to its corrected size. A corrective pass (isCorrectivePass) is a nested
        // RenderChart call from within that same still-hidden window, so it must NOT re-hide.
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

    // Reassigned on every call (see this var's own declaration comment) - must happen before
    // `config` is built below (config.barWidth reads it) and before ApplySkillPairSpacing runs
    // (scheduled via SchedulePostRenderPatches further down), since that function derives its
    // pair-centering math from whatever this module-level variable currently holds.
    BAR_WIDTH_PX = (chartData && chartData.barWidth) ? chartData.barWidth : 50;

    var categories  = (chartData && Array.isArray(chartData.categories))  ? chartData.categories  : [];
    var seriesDefs   = (chartData && Array.isArray(chartData.series))     ? chartData.series      : [];
    var skillLabels  = (chartData && Array.isArray(chartData.skillLabels)) ? chartData.skillLabels : [];

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
    // of the generic SERIES_COLOR_PALETTE rotation - see codeunit 50608's AddCapacitySegmentSeries/
    // AddSkillUnassignedSeries.
    var series = seriesDefs.map(function(s, sIdx) {
        var seriesDef = {
            id:    "s" + sIdx,
            value: "s" + sIdx,
            label: (s && s.name) ? s.name : ("Series " + (sIdx + 1)),
            color: (s && s.color) ? s.color : SERIES_COLOR_PALETTE[sIdx % SERIES_COLOR_PALETTE.length]
        };
        // Any series requesting `stacked` switches the whole chart to a stacked layout (suite.js
        // reads `stacked` per-series - a mixed stacked/unstacked chart is not a shape this chart
        // needs, so one flag covers all series - see isStacked below).
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
        // Kept in sync with BAR_WIDTH_PX (see its own comment) - ApplySkillPairSpacing derives its
        // pair-centering math from that constant, so this value can't drift from it.
        barWidth: BAR_WIDTH_PX,
        // NOTE: the "text" scale's category field name comes from `text`, NOT `value`
        // (confirmed by reading suite.js's TextScale._setDefaults: `this.locator =
        // locator(config.text)`). `value` on a scale config is a no-op for the "text"
        // type — using it here previously made every row resolve to the same blank (""),
        // collapsing all categories onto the same x-slot and producing garbled/ghost bars.
        // For the same reason each category must stay UNIQUE per bar even though only part of
        // it is shown: TextScale.point() positions a bar by `steps.indexOf(categoryValue)`, so
        // two bars sharing identical category text would collapse onto the same x-slot.
        // Categories therefore arrive as "<SkillCode>|Capacity"/"<SkillCode>|Requested"
        // (CATEGORY_DELIMITER-joined, still unique per bar) and textTemplate below strips the
        // "<SkillCode>|" prefix so the tick only ever shows a single "C"/"R" letter - the skill
        // code itself is rendered separately by RenderSkillGroupRow from chartData.skillLabels.
        //
        // Bottom axis labels are kept horizontal (no scaleRotate - see CATEGORY_LABEL_ROTATE_DEG's
        // own retirement note above). size is set to fit both the native "C"/"R" row and
        // RenderSkillGroupRow's extra skill-code row stacked directly underneath it
        // (SKILL_ROW_HEIGHT each).
        scales: {
            bottom: {
                type: "text", text: "category", textPadding: BOTTOM_TEXT_PADDING, size: BOTTOM_SCALE_RESERVED_PX,
                // Single-letter "C"/"R", not the full "Capacity"/"Requested" word: once
                // ApplySkillPairSpacing (below) pulls a skill's 2 bars edge-to-edge tight (total
                // pair width is just BAR_WIDTH_PX*2 + PAIR_INNER_GAP_PX), the full words no longer
                // fit at that width - matches src/dhx/barchart_weekly/wrapper.js's own textTemplate
                // for the identical reason.
                textTemplate: function(item) {
                    var s = String(item);
                    var i = s.indexOf(CATEGORY_DELIMITER);
                    var full = i >= 0 ? s.slice(i + 1) : s;
                    return full.charAt(0);
                }
            },
            left:   { type: "numeric" }
        },
        // Series-driven legend, de-duplicated by label (2026-09-22, replacing the old per-category/
        // bar "colors"/barColor-driven data legend - a category-driven legend no longer makes
        // sense once each category is only half a skill's story, its Capacity OR Requested bar).
        // Matches src/dhx/barchart_weekly/wrapper.js's own `legend.series` config exactly - see
        // that file's own comment for why de-dup-by-label is needed (this chart currently has no
        // series sharing a label, but the same convention is kept for consistency/future-proofing).
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
            valign: "top",
            // Explicit reserved top margin - see legendSize's own comment above. Left at the
            // library's own default (40) on a normal first pass; bumped by
            // CorrectLegendTopOverflowIfNeeded on a corrective re-render when that default wasn't
            // enough room for however many rows this chart's legend items actually wrap onto.
            size: legendSize
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
    lastSkillLabels = skillLabels;
    // Stash for ResolveBarSegmentFromEvent - a later right-click always resolves against whatever
    // is CURRENTLY rendered, not whatever was rendered when BOOT first ran.
    lastCategories = categories;

    // Post-render DOM patches for things dhx.Chart's own config has no option for - see
    // src/dhx/barchart_weekly/wrapper.js's own RenderChart/SchedulePostRenderPatches comments for
    // the full reasoning behind each (ApplySeriesBorders/ApplyLegendSwatchBorders/
    // ApplyLegendHitArea/RenderSkillGroupRow, plus the legend top-overflow self-correction) - all
    // ported here 2026-09-22 alongside the C/R bar-pair redesign.
    SchedulePostRenderPatches();

    // Bar click -> BC (mirrors OnEventDoubleClick's InvokeExtensibilityMethod pattern
    // used throughout src/dhx/resourceschedule/wrapper.js). id is the category text
    // ("<SkillCode>|Capacity"/"<SkillCode>|Requested") we set as each data row's "id" above.
    chartInstance.events.on("serieClick", function(id) {
        try {
            Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("OnDataPointClicked", [String(id)]);
        } catch (e) { /* ignore */ }
    });
}

// Schedules (de-duplicated - a burst of mutation/resize signals collapses to one pass) a single
// frame-deferred re-application of all post-render patches. Ported 2026-09-22 from
// src/dhx/barchart_weekly/wrapper.js's own SchedulePostRenderPatches (see that function's own
// comment for the full requestAnimationFrame-timing reasoning) - replaces this file's previous,
// narrower ScheduleLegendPatches/seriesBorderObserver pair with the same single consolidated
// pipeline Weekly already uses.
function SchedulePostRenderPatches() {
    if (pendingPatchFrame) return;
    pendingPatchFrame = requestAnimationFrame(function() {
        pendingPatchFrame = null;
        if (!chartContainer) return;
        if (chartMutationObserver) chartMutationObserver.disconnect();
        // ApplySkillPairSpacing MUST run before RenderSkillGroupRow - the latter derives its own
        // layout (skill-name centers, divider positions, background box) from whatever the bottom
        // axis ticks' CURRENT x positions are, so it needs to see the tightened/pair-shifted
        // positions, not the native evenly-spaced ones. The other two patches don't care about bar
        // x position.
        ApplySkillPairSpacing();
        ApplySeriesBorders(lastSeriesDefs, lastSeries);
        ApplyLegendSwatchBorders(lastSeriesDefs, lastSeries);
        ApplyLegendHitArea();
        RenderSkillGroupRow(lastSkillLabels);
        if (chartMutationObserver) chartMutationObserver.observe(chartContainer, { childList: true, subtree: true });

        // Legend top-clip self-correction runs LAST (after ApplyLegendHitArea, which can slightly
        // grow the legend's own bbox with its invisible hit-rects) so the measurement below
        // reflects the legend's truly final DOM shape for this pass. Safe to run on every repaint:
        // the correction is self-limiting, so once already corrected it becomes a cheap no-op
        // measurement most passes.
        var corrected = CorrectLegendTopOverflowIfNeeded();
        if (!corrected && chartContainer) chartContainer.style.visibility = "";
    });
}

// Measures how many px the legend's own top edge renders ABOVE the chart's <svg> top edge - i.e.
// clipped, since the SVG's default overflow behaviour never paints content above its own viewport.
// See src/dhx/barchart_weekly/wrapper.js's own MeasureLegendTopOverflow for the full root-cause
// writeup (identical mechanism, ported unchanged). Returns 0 (never negative) when nothing is
// clipped.
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
// see legendSize's own comment in RenderChart, and src/dhx/barchart_weekly/wrapper.js's own
// CorrectLegendTopOverflowIfNeeded for the full reasoning (ported unchanged).
function CorrectLegendTopOverflowIfNeeded() {
    var overflow = MeasureLegendTopOverflow();
    if (overflow <= 1 || lastLegendSize >= 400) return false;
    var newSize = lastLegendSize + Math.ceil(overflow) + 4;
    RenderChart(lastChartData, newSize, true);
    return true;
}

// Pulls each skill's 2 bars (Capacity + Requested) tightly together around their own shared
// pair-center, so they read as one packed side-by-side pair with a clearly larger gap before the
// next skill's pair - per spec (a standard grouped/clustered bar chart look). Ported 1:1 from
// src/dhx/barchart_weekly/wrapper.js's own ApplyDayPairSpacing (see that function's own comment for
// the full reasoning: dhx.Chart's bottom "text" scale has no per-category spacing option, so this
// is a post-render pixel patch) - renamed "day" -> "skill" only, logic unchanged.
function ApplySkillPairSpacing() {
    var axisGroup = chartContainer.querySelector('g[aria-label^="x-axis"]');
    if (!axisGroup) return;

    // `:scope > text.scale-text` (DIRECT children only) - deliberately NOT a plain descendant
    // query, for the same reason src/dhx/barchart_weekly/wrapper.js's own ApplyDayPairSpacing uses
    // it: this runs BEFORE RenderSkillGroupRow, so a previous `.skill-group-row` (nesting its OWN
    // `text.scale-text` labels one level deeper) must not be counted here.
    var ticks = axisGroup.querySelectorAll(":scope > text.scale-text");
    var pairCount = Math.floor(ticks.length / 2);
    if (pairCount < 1 || ticks.length % 2 !== 0) return; // odd tick count - shape mismatch, bail rather than misdraw

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
    // stays visually aligned.
    var seriesGroups = chartContainer.querySelectorAll('g[aria-label^="chart s"]');
    seriesGroups.forEach(function(group) {
        var paths = group.querySelectorAll("path");
        paths.forEach(function(p, i) {
            if (dx[i] === undefined) return;
            p.setAttribute("transform", "translate(" + dx[i] + ",0)");
        });
    });

    // Shift the native "C"/"R" tick labels to match, so each stays centered under its own
    // (now-moved) bar. Mutating the SAME <text> elements' x attribute in place (not replacing
    // them) is what lets RenderSkillGroupRow, which runs right after this, pick up the new
    // positions just by re-querying the same selector.
    ticks.forEach(function(t, i) {
        if (dx[i] === undefined) return;
        var x = parseFloat(t.getAttribute("x"));
        t.setAttribute("x", x + dx[i]);
    });
}

// Applies a CSS stroke to every rendered bar <path> of a series that requested a `border`
// colour AND actually has a nonzero value for that category - ported 1:1 from
// src/dhx/barchart_weekly/wrapper.js's own ApplySeriesBorders (see that function's own comment for
// the full reasoning: a zero-value stacked segment still paints as a real, if invisible-height,
// <path> at its baseline, so stroking it unconditionally would leave a persistent hairline on
// every bar with no data for that series at all). Currently only the Capacity bar's "External"
// segment (codeunit 50608's AddCapacitySegmentSeries) requests a border, but this stays fully
// generic so any future bordered series works with no JS change.
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
// LEGEND SWATCH, plus each per-skill series' own legend TEXT colour (codeunit 50608's
// GetSkillFontColor, sent as that series' own "fontColor" - see AddSkillUnassignedSeries) - ported
// 1:1 from src/dhx/barchart_weekly/wrapper.js's own ApplyLegendSwatchBorders (see that function's
// own comment for the full suite.js Legend.paint() internals this relies on, and why ownership is
// re-derived from `series` here via GetLegendOwnerIndexByLabel rather than trusted from the DOM).
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

        if (ownerDef && ownerDef.fontColor) {
            textEl.style.fill = ownerDef.fontColor;
        } else {
            textEl.style.fill = "";
        }
    });
}

// First-occurrence-by-label ownership - MUST mirror RenderChart's own `legend.series` de-dup
// filter exactly. Ported 1:1 from src/dhx/barchart_weekly/wrapper.js's own
// GetLegendOwnerIndexByLabel - factored out so the right-click legend resolver below
// (ResolveLegendSegmentFromEvent) reuses the exact same ownership rule instead of re-deriving a
// second, potentially-drifting copy of it.
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

// Widens each legend entry's actually-clickable area to its FULL bounding box - ported 1:1 from
// src/dhx/barchart_weekly/wrapper.js's own ApplyLegendHitArea (see that function's own comment for
// the full live-probe root-cause writeup: the swatch/text glyphs only cover PART of a legend
// item's own bbox under default SVG hit-testing, so clicks/right-clicks landing in the gaps
// between them silently fall through).
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

// Resolves a right-click target to the specific stacked BAR it landed on - i.e. one category
// (a Skill Code's own "Capacity" or "Requested" bar), not one specific segment within it, since
// codeunit 50608's ShowSegmentData already treats any click on a given bar identically regardless
// of which of its own stacked segments was actually clicked. Bars paint their <path>s into a
// `g[aria-label="chart s<N>"]` wrapper per series (suite.js's Bar.paint sets this aria-label from
// the series' own id); `.closest(...)` always resolves to whichever series group the clicked
// <path> actually belongs to, and every series' own <path> list is index-aligned with `categories`
// (one <path> per category, always, even a 0-height one - the "0 elsewhere" stacked-series
// convention) - so the clicked <path>'s index within its OWN group directly indexes into
// lastCategories, giving back the exact "<SkillCode>|Capacity"/"<SkillCode>|Requested" category
// text codeunit 50608's ShowSegmentData expects. This is the SAME direct-index lookup this file
// used before the C/R bar-pair redesign (it already worked correctly for one bar per category);
// the pair grouping does not change this - it only changes what the resolved category text itself
// looks like, so no day/2-style even/odd math (as src/dhx/barchart_weekly/wrapper.js's own
// ResolveBarSegmentFromEvent needs, since ITS AL-side signature takes BarType as a separate
// parameter) is needed here. Returns null when the click did not land on a bar at all (empty
// background, axis, legend - see ResolveLegendSegmentFromEvent for the legend case).
var lastCategories = [];
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

// Resolves a right-click target to a LEGEND entry, identified by its rendered label text (same
// series-driven legend as src/dhx/barchart_weekly/wrapper.js - see that file's own
// ResolveLegendSegmentFromEvent). Ported here 2026-09-22 to replace this chart's old data-driven
// (per-category) legend resolver, which only ever returned an empty {} - now that the legend is
// series-driven, a legend click genuinely identifies ONE series (a Capacity segment, the shared
// Requested-Assigned series, or one skill's own Unassigned series), which codeunit 50608's
// ShowSegmentData needs to decide which "whole chart" drilldown to broaden to.
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

// Draws the "Skill Code" header row spanning each skill's 2 bars (Capacity + Requested), directly
// underneath the native "C"/"R" tick labels, plus a grid of borders around both rows - ported 1:1
// from src/dhx/barchart_weekly/wrapper.js's own RenderDayGroupRow (renamed "day" -> "skill" only,
// logic unchanged - see that function's own comment for the full reasoning: dhx.Chart's bottom
// "text" scale has no built-in concept of grouped/multi-level categories, so this row is drawn
// entirely by hand from the ALREADY-RENDERED tick positions). Idempotent - safe to call again on
// every repaint (see SchedulePostRenderPatches).
function RenderSkillGroupRow(skillLabels) {
    var axisGroup = chartContainer.querySelector('g[aria-label^="x-axis"]');
    if (!axisGroup) return;

    var existing = axisGroup.querySelector(".skill-group-row");
    if (existing) existing.remove();
    var existingBg = axisGroup.querySelector(".skill-group-bg");
    if (existingBg) existingBg.remove();

    if (!skillLabels || !skillLabels.length) return;

    var ticks = axisGroup.querySelectorAll("text.scale-text");
    if (ticks.length !== skillLabels.length * 2) return; // shape mismatch - bail rather than misdraw

    var xs = [];
    for (var t = 0; t < ticks.length; t++) {
        xs.push(parseFloat(ticks[t].getAttribute("x")));
    }
    var tickY = parseFloat(ticks[0].getAttribute("y"));
    var step = xs[1] - xs[0];
    if (!step) return; // degenerate layout (e.g. a single category) - nothing sane to draw

    // Reconstruct the bottom axis's own local y=0 line (suite.js's bottom() sets every
    // tick's y to `height + textPadding`) so the new rows stack directly beneath it in the SAME
    // local coordinate space as the existing ticks - no need to read any DOM transform/bounding box.
    var axisY = tickY - BOTTOM_TEXT_PADDING;
    var row2Y = axisY + SKILL_ROW_HEIGHT + BOTTOM_TEXT_PADDING;
    var leftEdge = xs[0] - step / 2;
    var rightEdge = xs[xs.length - 1] + step / 2;

    // The background fill MUST be painted BEHIND the native "C"/"R" tick text (siblings within
    // axisGroup, already there before this function ever runs) - SVG has no z-index, paint order
    // is DOM order, so an opaque fill appended normally (last = on top) would silently cover that
    // text instead of sitting behind it. insertBefore(..., firstChild) is the one line standing
    // between "background tint" and "row 1 text vanishes".
    var bgRect = SvgEl("rect", {
        "class": "skill-group-bg",
        x: leftEdge, y: axisY, width: rightEdge - leftEdge, height: SKILL_ROW_HEIGHT * 2,
        fill: SKILL_GROUP_BACKGROUND_COLOR, stroke: SKILL_GROUP_BORDER_COLOR, "stroke-width": SKILL_GROUP_BORDER_WIDTH
    });
    axisGroup.insertBefore(bgRect, axisGroup.firstChild);

    // Everything else (row divider, dividers, skill-code text) is unfilled strokes/text that never
    // covers the native ticks, so it stays appended normally (on top, where it needs to be
    // visible over the background).
    var group = SvgEl("g", { "class": "skill-group-row" });

    group.appendChild(SvgEl("line", {
        x1: leftEdge, x2: rightEdge, y1: axisY + SKILL_ROW_HEIGHT, y2: axisY + SKILL_ROW_HEIGHT,
        stroke: SKILL_GROUP_BORDER_COLOR, "stroke-width": SKILL_GROUP_BORDER_WIDTH
    }));
    // Top row: one divider between every bar (Capacity | Requested | Capacity | ...).
    for (var k = 0; k < xs.length - 1; k++) {
        var dividerX = (xs[k] + xs[k + 1]) / 2;
        group.appendChild(SvgEl("line", {
            x1: dividerX, x2: dividerX, y1: axisY, y2: axisY + SKILL_ROW_HEIGHT,
            stroke: SKILL_GROUP_BORDER_COLOR, "stroke-width": SKILL_GROUP_BORDER_WIDTH
        }));
    }
    // Bottom row: one divider between each SKILL pair only (not between a skill's own
    // Capacity/Requested bars, since those share the same merged skill-code cell).
    for (var d = 0; d < skillLabels.length - 1; d++) {
        var pairBoundaryX = (xs[d * 2 + 1] + xs[d * 2 + 2]) / 2;
        group.appendChild(SvgEl("line", {
            x1: pairBoundaryX, x2: pairBoundaryX, y1: axisY + SKILL_ROW_HEIGHT, y2: axisY + SKILL_ROW_HEIGHT * 2,
            stroke: SKILL_GROUP_BORDER_COLOR, "stroke-width": SKILL_GROUP_BORDER_WIDTH
        }));
    }
    // One merged skill-code label per skill, centered over its own pair of bars, tilted
    // SKILL_LABEL_ROTATE_DEG around that same center point - rotating in place (rather than
    // anchoring the pivot at an edge) keeps the label's on-screen center close to where a reader's
    // eye already expects it (still roughly under its own bar pair), rather than shifting the whole
    // label sideways just because it's now diagonal.
    for (var i = 0; i < skillLabels.length; i++) {
        var midX = (xs[i * 2] + xs[i * 2 + 1]) / 2;
        var skillText = SvgEl("text", {
            x: midX, y: row2Y, "text-anchor": "middle", "class": "scale-text",
            transform: "rotate(" + SKILL_LABEL_ROTATE_DEG + " " + midX + " " + row2Y + ")"
        });
        skillText.textContent = String(skillLabels[i]);
        group.appendChild(skillText);
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
