var scheduler_here; // global variable for dhx Scheduler
var resourceBlockVisible = false; // true only for a new event
var bcPlanningVisible = false;    // show only for existing events
var timelineHourStep = 3;         // hours between marks on the timeline scale; overridable via SetTimelineHourStep (AL setup)
var timelineStartHour = 0;        // start of the visible daily window (0 = midnight); overridable via SetTimelineHourRange
var timelineEndHour = 24;         // end of the visible daily window (24 = midnight); overridable via SetTimelineHourRange

// Job/Job Task filter toolbar state (top-left of the timeline grid).
// null -> unfiltered; the filter (▽) button is still shown so the user can open the
// filter dialog, it just has no reset (✕) button and no filter details to show on hover.
// Mirrors the { job, task, periodFrom, periodTo } shape used by the Gantt resource-panel
// filter info (src/dhx/ganttdemo2/wrapper.js: _resourceFilterInfo / SetResourcePanelFilterInfo).
var _taskFilterInfo = null;

// Collapse/expand-all state for the tree timeline's folder rows (Job/Job Task
// sections). Toggled by the icon at the top-left of the grid — mirrors
// _allTasksCollapsed / ToggleCollapseExpandAll in src/dhx/ganttdemo2/wrapper.js.
var _allSectionsCollapsed = false;

// -------------------------------------------------------
// Loading overlay - shown while a full data (re)load is in progress. Same
// look/lifecycle as _loadingOverlay in src/dhx/ganttdemo2/wrapper.js: created
// once in BOOT (earliest point this add-in's JS runs), shown again at the
// start of every full reload entry point (Init/RefreshTimeline), hidden once
// that reload cycle's own render is done (LoadData for the initial
// Init->LoadData sequence, RefreshTimeline for subsequent reloads).
// -------------------------------------------------------
var _loadingOverlay = null;
var _loadingSafetyTimer = null;

// -------------------------------------------------------
// Part B pagination: bounded poll for the "remaining sections" background task result. AL fetches
// the first ~50-row page synchronously and enqueues a Page Background Task for the rest (see page
// 50621's EnqueueSectionsBackgroundTask); the fetched JSON is stashed in plain page vars from
// OnPageBackgroundTaskCompleted - this poll loop is what actually pulls it into the control add-in,
// via a normal JS-initiated synchronous trigger (OnPollSectionsResult), which AL answers by calling
// AppendSections itself - from a normal call stack, not the background-task completion - if
// something is pending. Bounded (not indefinite), exact same 500ms/60-attempt shape as
// src/dhx/ganttdemo2/wrapper.js's NotifyResourcePanelTaskPending/_resourcePanelPollTimer.
// -------------------------------------------------------
var _sectionsPollTimer = null;
var _sectionsPollAttempts = 0;
var SECTIONS_POLL_INTERVAL_MS = 500;
var SECTIONS_POLL_MAX_ATTEMPTS = 60; // 60 x 500ms = 30s generous ceiling

function NotifySectionsTaskPending() {
    try {
        if (_sectionsPollTimer) {
            clearInterval(_sectionsPollTimer);
            _sectionsPollTimer = null;
        }
        _sectionsPollAttempts = 0;
        _sectionsPollTimer = setInterval(function () {
            _sectionsPollAttempts++;
            if (_sectionsPollAttempts > SECTIONS_POLL_MAX_ATTEMPTS) {
                clearInterval(_sectionsPollTimer);
                _sectionsPollTimer = null;
                return;
            }
            try {
                Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("OnPollSectionsResult", []);
            } catch (e) {
                console.error("OnPollSectionsResult poll failed:", e);
            }
        }, SECTIONS_POLL_INTERVAL_MS);
    } catch (e) {
        console.error("NotifySectionsTaskPending failed:", e);
    }
}
window.NotifySectionsTaskPending = NotifySectionsTaskPending;

// Called by AL (from the OnPollSectionsResult trigger handler, via AppendSections) once a pending
// result was actually delivered - stops the poll burst early instead of waiting out the full
// timeout.
function StopSectionsPolling() {
    if (_sectionsPollTimer) {
        clearInterval(_sectionsPollTimer);
        _sectionsPollTimer = null;
    }
}
window.StopSectionsPolling = StopSectionsPolling;

function _createTskLoadingOverlay(host) {
    if (_loadingOverlay) return;

    var style = document.createElement("style");
    style.textContent = [
        "#tsk-loading-overlay {",
        "  position:absolute; inset:0; z-index:100000;",
        "  display:none; align-items:center; justify-content:center;",
        "  background:rgba(255,255,255,0.35);",
        "}",
        "#tsk-loading-overlay .tlo-box {",
        "  background:#fff; border:1px solid #d8d8d8; border-radius:6px;",
        "  box-shadow:0 6px 24px rgba(0,0,0,0.25);",
        "  padding:18px 26px; width:170px; text-align:center;",
        "  font:13px/1.4 'Segoe UI', Tahoma, sans-serif;",
        "}",
        "#tsk-loading-overlay .tlo-bar {",
        "  height:16px; border:1px solid #2f6fdb; border-radius:2px; overflow:hidden;",
        "  margin-bottom:10px; background:#fff;",
        "}",
        "#tsk-loading-overlay .tlo-bar-fill {",
        "  height:100%; width:200%;",
        "  background-image: repeating-linear-gradient(-55deg, #2f6fdb 0 8px, #eaf1fd 8px 16px);",
        "  animation: tlo-slide 0.9s linear infinite;",
        "}",
        "@keyframes tlo-slide { from { transform: translateX(-50%); } to { transform: translateX(0%); } }",
        "#tsk-loading-overlay .tlo-title { color:#2f6fdb; font-weight:700; font-size:16px; letter-spacing:1px; }",
        "#tsk-loading-overlay .tlo-sub { color:#8a8a8a; margin-top:2px; }"
    ].join("\n");
    document.head.appendChild(style);

    var overlay = document.createElement("div");
    overlay.id = "tsk-loading-overlay";
    overlay.innerHTML =
        '<div class="tlo-box">' +
            '<div class="tlo-bar"><div class="tlo-bar-fill"></div></div>' +
            '<div class="tlo-title">LOADING</div>' +
            '<div class="tlo-sub">Please wait...</div>' +
        '</div>';

    if (!host.style.position) host.style.position = "relative";
    host.appendChild(overlay);
    _loadingOverlay = overlay;
}

function _showTskLoading() {
    if (!_loadingOverlay) return;
    _loadingOverlay.style.display = "flex";
    // Safety fallback: never let the overlay get stuck forever if a reload cycle's hide
    // call is never reached (e.g. an error earlier in the AL load sequence).
    if (_loadingSafetyTimer) clearTimeout(_loadingSafetyTimer);
    _loadingSafetyTimer = setTimeout(_hideTskLoading, 180000);
}

function _hideTskLoading() {
    if (_loadingOverlay) _loadingOverlay.style.display = "none";
    if (_loadingSafetyTimer) { clearTimeout(_loadingSafetyTimer); _loadingSafetyTimer = null; }
}

//<< Inject CSS to hide default tabs : Day, Week, Month **** 2025.12.24
// Toggle helpers
function SetDefaultTabsVisible(visible) {
  var root = document.getElementById("scheduler_here");
  if (!root) return;
  if (visible) {
    root.classList.remove("dhx-hide-default-tabs");
  } else {
    root.classList.add("dhx-hide-default-tabs");
  }
}
//>>

// -------------------------------------------------------
// BOOT in startupScript.js calls this to build DOM and trigger ControlReady
// -------------------------------------------------------
window.BOOT = function() {
  try {    
    //<< Inject CSS to hide default tabs : Day, Week, Month **** 2025.12.24
    //only hides when root has the class dhx-hide-default-tabs
    const style = document.createElement("style");
    style.textContent = `
    /* Hide all built-in tabs (Day/Week/Month/Timeline) */
    #scheduler_here.dhx-hide-default-tabs .dhx_cal_tab { 
        display: none !important; 
    }

    /* Hide navigation buttons */
    #scheduler_here.dhx-hide-default-tabs .dhx_cal_prev_button,
    #scheduler_here.dhx-hide-default-tabs .dhx_cal_next_button,
    #scheduler_here.dhx-hide-default-tabs .dhx_cal_today_button {
        display: none !important;
    }

    /* Show only the date title and align it to the center */
    #scheduler_here.dhx-hide-default-tabs .dhx_cal_date {
        left: 50% !important;
        transform: translateX(-50%);
        margin: 0 !important;
        text-align: center !important;
    }

    /* Hide the entire header area to remove blank space */
    #scheduler_here .dhx_cal_navline {
        display: none !important;
    }

    /* Tree folder/parent labels - remove bold and use black color */
    .dhx_matrix_scell.folder,
    .dhx_matrix_scell.folder div,
    .dhx_scell_level0,
    .dhx_scell_level1,
    .dhx_scell_level2 {
        font-weight: normal !important;
        color: #000000 !important;
        text-transform: none !important;
        text-align: left !important;
    }

    /* Ensure all tree labels use normal font weight and black color */
    .dhx_matrix_scell {
        font-weight: normal !important;
        color: #000000 !important;
        text-transform: none !important;
        text-align: left !important;
    }

    /* Event styling: Day Planning bar, 3-part Requested/Assigned split.
       Colors are CSS custom properties so AL can override them at runtime
       (see SetBarColors below) — the values here are just defaults used
       until/unless AL sends different ones from setup. */
    #scheduler_here {
        --dp-color-envelope: #1B3A6B;
        --dp-color-envelope-border: #14294D;
        --dp-color-assigned: #548235; /* source of truth: AL codeunit 50609 "Color Constants Opti." AssColorTok */
        --dp-color-requested: #6FCF97; /* unrelated to codeunit 50609's skill palette - see ev.requested_color below */
        /* Default 3-part split (Assigned/Requested both valid and different) — overridable
           at runtime from Task Scheduler Setup's "Assigned High (%)"/"Requested High (%)"
           via SetBarColors below. Defaults stay 80/20 even when setup has no override. */
        --dp-height-assigned: 80%;
        --dp-height-requested: 20%;
        /* dp-bar-font-color (NOT --bar-font-color/"Daily Optimizer Setup"."Bar Font Color" -
           this scheduler has no Capacity bar of its own, so every bar here is skill-bearing and
           text/border colour comes exclusively from per-skill overrides injected by
           SetSkillFontBorderColors below, keyed to the "pts-skill-<token>" class added in
           event_class). This var is only the fallback default for a skill with no per-skill
           colour resolved (blank Skill, or codeunit 50609's own BarFontColorTok fallback). */
        --dp-bar-font-color: #000000;
    }

    /* Outer bar = envelope (earliest..latest of Requested/Assigned) — solid dark blue base.
       border-color default here is overridden per-skill via the injected "pts-skill-<token>"
       rules from SetSkillFontBorderColors (higher specificity, added later in <head>). */
    .dhx_cal_event.event-DayPlanning,
    .dhx_cal_event_line.event-DayPlanning,
    .dhx_event_line.event-DayPlanning {
        background: var(--dp-color-envelope) !important;
        border-color: var(--dp-color-envelope-border) !important;
        font-size: 14px !important;
        padding: 0 !important;
    }

    /* Wrapper filling the whole bar; positions the two inner strips + label */
    .dp-bar-wrap {
        position: relative;
        width: 100%;
        height: 100%;
        overflow: hidden;
    }

    /* Top strip: Assigned start/end sub-range. Height is --dp-height-assigned (default
       80%) of the envelope when both Assigned and Requested are valid and different
       (the 3-part case in event_bar_text below) — Requested gets the rest. Only
       applies to that 3-part split; the single full-height case overrides via inline
       style. */
    .dp-bar-assigned {
        position: absolute;
        top: 0;
        height: var(--dp-height-assigned);
        background: var(--dp-color-assigned) !important;
    }

    /* Bottom strip: Requested start/end sub-range (--dp-height-requested, default 20% —
       see .dp-bar-assigned above) */
    .dp-bar-requested {
        position: absolute;
        bottom: 0;
        height: var(--dp-height-requested);
        background: var(--dp-color-requested) !important;
    }

    /* Left-aligned label on top of both strips - keeps the Skill portion of the text
       visible first when the bar is too narrow for the full "<Skill> | <Resource>" text. */
    .dp-bar-label {
        position: absolute;
        inset: 0;
        display: flex;
        align-items: center;
        justify-content: flex-start;
        color: var(--dp-bar-font-color);
        font-size: 12px;
        white-space: nowrap;
        overflow: hidden;
        text-overflow: ellipsis;
        pointer-events: none;
        text-shadow: 0 0 2px rgba(0,0,0,0.7);
        z-index: 2;
        padding-left: 4px;
        text-align: left;
        min-width: 0;
    }

    /* ── Right-click context menu ─────────────────────────────── */
    #dhx-ctx-menu {
        position: fixed;
        z-index: 99999;
        background: #fff;
        border: 1px solid #c8c8c8;
        border-radius: 4px;
        box-shadow: 0 4px 12px rgba(0,0,0,0.18);
        padding: 4px 0;
        min-width: 190px;
        font-family: "Segoe UI", sans-serif;
        font-size: 13px;
        user-select: none;
    }
    #dhx-ctx-menu.hidden { display: none; }
    .dhx-ctx-item {
        display: flex;
        align-items: center;
        gap: 8px;
        padding: 7px 14px;
        cursor: pointer;
        color: #333;
        white-space: nowrap;
    }
    .dhx-ctx-item:hover { background: #f0f4ff; color: #1a56db; }
    .dhx-ctx-item.ctx-cancel { color: #c00; }
    .dhx-ctx-item.ctx-cancel:hover { background: #fff0f0; }
    .dhx-ctx-separator {
        height: 1px;
        background: #e0e0e0;
        margin: 4px 0;
    }
    .dhx-ctx-icon {
        width: 16px;
        height: 16px;
        display: inline-flex;
        align-items: center;
        justify-content: center;
        flex-shrink: 0;
    }

    /* ── Job/Job Task filter toolbar (top-left of the timeline grid) ─── */
    #scheduler_here {
        position: relative;
    }
    #tsk-filter-toolbar {
        position: absolute;
        top: 6px;
        left: 34px;
        z-index: 70;
        display: flex;
        align-items: center;
        gap: 4px;
    }
    /* Collapse/Expand-all toggle icon — sits left of the filter toolbar, same
       overlay approach (a DOM sibling of the scheduler's own markup, so it
       survives internal re-renders). */
    #tsk-collapseall-icon {
        position: absolute;
        top: 6px;
        left: 6px;
        z-index: 71;
        display: inline-flex;
        align-items: center;
        justify-content: center;
        width: 22px;
        height: 22px;
        padding: 0;
        border: none;
        border-radius: 50%;
        background: #5f6368;
        cursor: pointer;
    }
    #tsk-collapseall-icon:hover {
        background: #2f8bfb;
    }
    #tsk-collapseall-icon:active {
        background: #1f6fe0;
    }
    /* Fixed body-level tooltip popup (never clipped by the grid's overflow:hidden) —
       same styling as the Gantt resource-panel filter tooltip for visual consistency. */
    #tsk-filter-tooltip-popup {
        display: none;
        position: fixed;
        background: #ffffff;
        color: #23272A;
        border: 1px solid #4a6fa5;
        border-radius: 5px;
        padding: 8px 12px;
        font-size: 12px;
        font-weight: normal;
        white-space: nowrap;
        z-index: 999999;
        box-shadow: 0 3px 10px rgba(0,0,0,0.25);
        min-width: 180px;
        pointer-events: none;
    }
    `;
    document.head.appendChild(style);
    //>>

    var div = document.getElementById("controlAddIn");
    // Ensure full fill
    div.style.width = "100%";
    div.style.height = "100%";
    div.style.margin = "0";
    div.style.padding = "0";
    div.style.background = "lightgrey";

    // Show immediately — earliest point this add-in's own JS runs, well before
    // ControlReady/Init/LoadData ever fire.
    _createTskLoadingOverlay(div);
    _showTskLoading();

    var scheduler_element = document.createElement("div");
    scheduler_element.id = "scheduler_here";
    scheduler_element.name = "scheduler_here";
    scheduler_element.style.width = "100%";
    scheduler_element.style.height = "100%";
    div.appendChild(scheduler_element);
    scheduler_element.classList.add("dhx-hide-default-tabs"); //**** 2025.12.24
    scheduler_here = scheduler_element;

    // Check library
    if (typeof scheduler === "undefined") {
        console.error("DHX scheduler library (dhtmlxscheduler.js) not found. Please include it in ControlAddIn Scripts.");
        return;
    }

    scheduler.plugins({
        timeline: true,
        treetimeline: true,
        tooltip: true,
    });

    // GLOBAL (not per-view) scheduler config, read internally as e.config.preserve_scale_length
    // by the timeline column-search loop. Without it, that loop stops once it exhausts its
    // initial (un-adjusted-for-ignores) date range, landing short of x_size DISPLAYED columns
    // whenever ignore_timeline is skipping a large share of hours (e.g. a narrow start/end
    // window) — it needs to keep extending the search range until it actually finds x_size
    // non-ignored columns, not just x_size raw ticks.
    scheduler.config.preserve_scale_length = true;

    // All Day Planning bars share the "event-DayPlanning" base class; the 3-part
    // Requested/Assigned split is drawn by event_text below, not by vacant/assigned color.
    // "pts-skill-<token>" is added so SetSkillFontBorderColors' injected per-skill <style>
    // rules (text colour + border colour) can target this specific bar's skill.
    scheduler.templates.event_class = function(start, end, ev) {
        return "event-DayPlanning pts-skill-" + safeCssToken(ev.skill);
    };

    // Compacts (not just hides) hour columns outside [timelineStartHour, timelineEndHour)
    // on the "timeline" view — a documented dhtmlx extension point: defining
    // scheduler.ignore_<viewname> makes that view's column-generation give ignored
    // columns zero width, unlike a CSS-based hide which would leave empty gaps.
    // Reads the live module-level vars, so it stays correct across RecreateTimelineView
    // calls without needing to be redefined.
    scheduler.ignore_timeline = function(date) {
        var h = date.getHours();
        return (h < timelineStartHour) || (h >= timelineEndHour);
    };

    function escapeHtml(text) {
        return String(text || "")
            .replace(/&/g, "&amp;")
            .replace(/</g, "&lt;")
            .replace(/>/g, "&gt;");
    }

    function parseHHmmToMinutes(str) {
        if (!str) return null;
        var parts = String(str).split(':');
        if (parts.length < 2) return null;
        var h = parseInt(parts[0], 10), m = parseInt(parts[1], 10);
        if (isNaN(h) || isNaN(m)) return null;
        return h * 60 + m;
    }

    // A time value is "valid" only when both its Start and End are set (<> 0T on the AL
    // side, which serializes to a non-empty "HH:mm" string; missing/zero comes through blank).
    //
    // Renders the bar as:
    //  - Requested and Assigned both valid and DIFFERENT  -> 3 parts: full-width dark-blue
    //    envelope (start..end = earliest..latest of the two) + light-blue top-half strip for
    //    the Assigned sub-range + green bottom-half strip for the Requested sub-range.
    //  - Requested and Assigned both valid and EQUAL       -> 1 part: Assigned only, full height
    //    (same period, nothing to compare).
    //  - Only Assigned valid                                -> 1 part: Assigned only, full height.
    //  - Only Requested valid                                -> 1 part: Requested only, full height.
    //  - Neither valid                                       -> no strip, plain envelope + label.
    scheduler.templates.event_bar_text = function(start, end, ev) {
        var totalMin = (end - start) / 60000;
        var label = escapeHtml(ev.text);
        if (!(totalMin > 0)) {
            return '<div class="dp-bar-wrap"><div class="dp-bar-label">' + label + '</div></div>';
        }

        var envStartMin = start.getHours() * 60 + start.getMinutes();

        var assignedStartMin = parseHHmmToMinutes(ev.start_time_assigned);
        var assignedEndMin = parseHHmmToMinutes(ev.end_time_assigned);
        var assignedValid = (assignedStartMin !== null) && (assignedEndMin !== null);

        var requestedStartMin = parseHHmmToMinutes(ev.start_time_requested);
        var requestedEndMin = parseHHmmToMinutes(ev.end_time_requested);
        var requestedValid = (requestedStartMin !== null) && (requestedEndMin !== null);

        var sameRange = assignedValid && requestedValid &&
            (assignedStartMin === requestedStartMin) && (assignedEndMin === requestedEndMin);

        // colorOverride: an event's own resolved per-skill color (ev.requested_color, set by
        // AL's ResolveRequestedColor - see codeunit "DHX Data Handler") applied as an inline
        // !important style so it wins over the CSS "--dp-color-requested" rule (itself
        // !important - see the .dp-bar-requested rule above), which stays in place as the
        // fallback for a blank/unresolved color (no Skill Code on the row).
        function segmentHtml(cls, segStartMin, segEndMin, fullHeight, colorOverride) {
            var left = Math.max(0, Math.min(100, ((segStartMin - envStartMin) / totalMin) * 100));
            var width = Math.max(0, Math.min(100 - left, ((segEndMin - segStartMin) / totalMin) * 100));
            var extra = fullHeight ? ' top:0; bottom:auto; height:100%;' : '';
            var colorStyle = colorOverride ? ' background:' + colorOverride + ' !important;' : '';
            return '<div class="' + cls + '" style="left:' + left + '%; width:' + width + '%;' + extra + colorStyle + '"></div>';
        }

        var segmentsHtml = "";
        if (assignedValid && requestedValid && !sameRange) {
            segmentsHtml += segmentHtml('dp-bar-assigned', assignedStartMin, assignedEndMin, false);
            segmentsHtml += segmentHtml('dp-bar-requested', requestedStartMin, requestedEndMin, false, ev.requested_color);
        } else if (sameRange || assignedValid) {
            segmentsHtml += segmentHtml('dp-bar-assigned', assignedStartMin, assignedEndMin, true);
        } else if (requestedValid) {
            segmentsHtml += segmentHtml('dp-bar-requested', requestedStartMin, requestedEndMin, true, ev.requested_color);
        }

        return '<div class="dp-bar-wrap">' + segmentsHtml +
               '<div class="dp-bar-label">' + label + '</div></div>';
    };

    // Custom tooltip template
    scheduler.templates.tooltip_text = function(start, end, ev) {
        var formatDateOnly = scheduler.date.date_to_str("%d-%m-%Y");
        var formatTimeOnly = scheduler.date.date_to_str("%H:%i");
        // Parse event ID: "JobNo|JobTaskNo|DayNo|DayLineNo"
        var dayNo = "";
        var dayLineNo = "";
        var jobNo = "";
        var jobTaskNo = "";
        var resno = "";
        var resname = "";
        var vendorname = ev.details || "";
        
        if (ev.id) {
            var parts = String(ev.id).split('|');
            if (parts.length >= 5) {
                jobNo = parts[0] || "";
                jobTaskNo = parts[1] || "";
                dayNo = parts[2] || "";
                dayLineNo = parts[3] || "";
                resno = parts[4] || "";
                resname = parts[5] || "";
            }
        }
        
        var assignedStartTime = ev.start_time_assigned || "";
        var assignedEndTime = ev.end_time_assigned || "";
        var assignedNonWorkingMin = (ev.non_working_minutes_assigned !== undefined && ev.non_working_minutes_assigned !== null) ? ev.non_working_minutes_assigned : "";
        var assignedHours = (ev.assigned_hours !== undefined && ev.assigned_hours !== null) ? ev.assigned_hours : "";
        var reqResNo = ev.requested_resource_no || "";
        var reqResName = ev.requested_resource_name || "";
        var reqStartTime = ev.start_time_requested || "";
        var reqEndTime = ev.end_time_requested || "";
        var reqNonWorkingMin = (ev.non_working_minutes_requested !== undefined && ev.non_working_minutes_requested !== null) ? ev.non_working_minutes_requested : "";
        var reqHours = (ev.requested_hours !== undefined && ev.requested_hours !== null) ? ev.requested_hours : "";

        var html = '<div class="dhx-tt">';
        html += '<div class="dhx-tt-res">DayPlanning: ' + (ev.text || "") + '</div>';
        html += '<div class="dhx-tt-date">Daylineno: ' + dayLineNo + ' &nbsp;|&nbsp; Date: ' + formatDateOnly(start) + '</div>';

        html += '<div class="dhx-tt-table">';
        html += '<div class="dhx-tt-th"></div><div class="dhx-tt-th">Assigned</div><div class="dhx-tt-th">Requested</div>';
        html += '<div class="dhx-tt-label">Resource No.</div><div class="dhx-tt-val">' + resno + '</div><div class="dhx-tt-val">' + reqResNo + '</div>';
        html += '<div class="dhx-tt-label">Resource Name</div><div class="dhx-tt-val">' + resname + '</div><div class="dhx-tt-val">' + reqResName + '</div>';
        html += '<div class="dhx-tt-label">Start Time</div><div class="dhx-tt-val">' + assignedStartTime + '</div><div class="dhx-tt-val">' + reqStartTime + '</div>';
        html += '<div class="dhx-tt-label">End Time</div><div class="dhx-tt-val">' + assignedEndTime + '</div><div class="dhx-tt-val">' + reqEndTime + '</div>';
        html += '<div class="dhx-tt-label">Idle (Minutes)</div><div class="dhx-tt-val">' + assignedNonWorkingMin + '</div><div class="dhx-tt-val">' + reqNonWorkingMin + '</div>';
        html += '<div class="dhx-tt-label">Hours</div><div class="dhx-tt-val">' + assignedHours + '</div><div class="dhx-tt-val">' + reqHours + '</div>';
        html += '</div>';

        html += '</div>';
        return html;
    };

    scheduler.locale.labels.timeline_tab = "Timeline";
    scheduler.locale.labels.section_custom="Section";
    scheduler.config.details_on_create=true;
    scheduler.config.details_on_dblclick=false; // Disable opening lightbox on double click

    // Start weeks on Monday
    scheduler.config.start_on_monday = true;

    // Top title for the timeline tab (show week period)
    const weekTitleFmt = scheduler.date.date_to_str("%d %M %Y");
    scheduler.templates.timeline_date = function (start, end) {
        // end is exclusive; subtract 1 day
        const endIncl = scheduler.date.add(end, -1, "day");
        return "Week date from " + weekTitleFmt(start) + " to " + weekTitleFmt(endIncl);
    };

    scheduler.date.timeline_start = function(date){
        return scheduler.date.week_start(date); // respects start_on_monday
    };
    
    scheduler.config.lightbox.sections=[	
        {name:"description", height:60, map_to:"text", type:"textarea" , focus:true},
        {name:"custom", height:30, type:"timeline", options:null , map_to:"section_id" }, //type should be the same as name of the tab
        {name:"time", height:72, type:"time", map_to:"auto"},
        // << NEW: resource picker block >>
        {name:"resource", height:80, type:"resourcePicker", map_to:"resource_id"},
        // NEW: BC Planning (visible for existing)
        {name:"bcPlanning", height:50, type:"bcPlanning", map_to:"bc_dummy"}
    ];

    // Add a custom button to the lightbox to open a BC page
    // - Clicking it will raise an event to AL without closing the lightbox
    // Labels
    scheduler.locale.labels.section_bcPlanning = "BC Planning";
    scheduler.locale.labels.planning_line_btn = "Planning Line";
    scheduler.locale.labels.open_resource_btn = "Get Resource";

    // === NEW: BC Planning block (button inside section, never in footer) ===
    scheduler.form_blocks.bcPlanning = {
        render: function () {
            return (
                '<div class="bc-planning" style="padding:6px 12px;' + (bcPlanningVisible ? '' : 'display:none;') + '">' +
                    '<div style="margin:6px 0;">' +
                        '<button type="button" id="btnPlanningLine" class="dhx_btn">' +
                            (scheduler.locale.labels.planning_line_btn || 'Planning Line') +
                        '</button>' +
                    '</div>' +
                '</div>'
            );
        },
        set_value: function (node, value, ev) {
            // toggle visibility per event type
            node.style.display = bcPlanningVisible ? '' : 'none';

            var btn = node.querySelector('#btnPlanningLine');
            if (btn && !btn._wired) {
                btn._wired = true;
                btn.addEventListener('click', function (e) {
                    e.preventDefault();
                    e.stopPropagation();
                    var lbId = scheduler.getState().lightbox_id;
                    var cur = lbId ? scheduler.getEvent(lbId) : null;
                    var payload = cur ? {
                        id: lbId,
                        text: cur.text,
                        start_date: cur.start_date,
                        end_date: cur.end_date,
                        section_id: cur.section_id,
                        resource_id: cur.resource_id || '',
                        resource_name: cur.resource_name || ''
                    } : {};
                    console.log('Planning Line button clicked for event:', lbId, payload);
                    Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('OnPlanningLineClick', [String(lbId || ''), JSON.stringify(payload)]);
                });
            }
        },
        get_value: function (node, ev) {
            // no data to persist from this section
            return ev.text;
        },
        focus: function (node) {}
    };

    // Custom lightbox form block
    scheduler.form_blocks.resourcePicker = {
        render: function () {
            return (
                '<div class="resource-picker" style="padding:6px 12px;' + (resourceBlockVisible ? '' : 'display:none;') + '">' +
                    '<div style="margin:6px 0;">' +
                        '<label style="width:120px;display:inline-block;">Resource Id</label>' +
                        '<input type="text" id="resource_id_input" style="width:220px;">' +
                        '<button type="button" id="btnGetResource" style="margin-left:8px;">' +
                            (scheduler.locale.labels.get_resource_btn || "Get Resource") +
                        '</button>' +
                    '</div>' +
                    '<div style="margin:6px 0;">' +
                        '<label style="width:120px;display:inline-block;">Resource Name</label>' +
                        '<input type="text" id="resource_name_input" style="width:220px;">' +
                    '</div>' +
                '</div>'
            );
        },
        set_value: function (node, value, ev) {
            // keep current visibility
            node.style.display = resourceBlockVisible ? '' : 'none';
            var idInput = node.querySelector('#resource_id_input');
            var nameInput = node.querySelector('#resource_name_input');
            if (idInput) idInput.value = ev.resource_id || '';
            if (nameInput) nameInput.value = ev.resource_name || '';

            var btn = node.querySelector('#btnGetResource');
            if (btn && !btn._wired) {
                btn._wired = true;
                btn.addEventListener('click', function () {
                    var lbId = scheduler.getState().lightbox_id;
                    var cur = lbId ? scheduler.getEvent(lbId) : null;
                    var payload = cur ? {
                        id: cur.id,
                        text: cur.text,
                        start_date: cur.start_date,
                        end_date: cur.end_date,
                        section_id: cur.section_id,
                        resource_id: idInput?.value || cur.resource_id || '',
                        resource_name: nameInput?.value || cur.resource_name || ''
                    } : {};
                    Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("OnOpenResourcePage", [lbId || "", JSON.stringify(payload)]);
                });
            }
        },
        get_value: function (node, ev) {
            var idInput = node.querySelector('#resource_id_input');
            var nameInput = node.querySelector('#resource_name_input');
            ev.resource_id = idInput ? idInput.value : '';
            ev.resource_name = nameInput ? nameInput.value : '';
            return ev.resource_id; // saved into map_to ("resource_id")
        },
        focus: function (node) {
            var idInput = node.querySelector('#resource_id_input');
            if (idInput) idInput.focus();
        }
    };

    scheduler.config.drag_create = true;

    // //console.log("EarliestPlanningDate: ",EarliestPlanningDate);
    // scheduler.init('scheduler_here');

    // ***** events triger block

    // Custom event registration for section double-click
    scheduler.attachEvent("onSectionDblClick", function(sectionId, label, viewdate) {
        // Get the current view period (start and end dates)
        var state = scheduler.getState();
        var periodStartDate = state.min_date;
        var periodEndDate = state.max_date;
        
        // Optional: Get all events in this section within the current view period
        var eventsInSection = scheduler.getEvents(periodStartDate, periodEndDate).filter(function(ev) {
            return ev.section_id === sectionId;
        });
        
        // Create payload with section info and period dates
        var payload = {
            sectionId: sectionId,
            label: label,
            viewdate: viewdate,
            periodStart: periodStartDate.toISOString(),
            periodEnd: periodEndDate.toISOString(),
            eventCount: eventsInSection.length
        };
        
        Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("OnSectionDblClick", [sectionId, label, JSON.stringify(payload)]);
    });

    // DOM handler to fire the custom event
    (function wireSectionDblClick() {
        var root = document.getElementById("scheduler_here");
        if (!root) return;

        root.addEventListener("dblclick", function(e) {
            // Find the label cell and row
            var sectionCell = e.target.closest(".dhx_matrix_scell");
            var sectionRow = e.target.closest(".dhx_timeline_label_row");        
            if (sectionCell && sectionRow) {
                // Get the sectionId from the row's data-row-id attribute
                var sectionId = sectionRow.getAttribute("data-row-id") || "";
                // Get the label from the cell
                var label = sectionCell.textContent.trim();
                var viewdate = scheduler.getState().date;
                scheduler.callEvent("onSectionDblClick", [sectionId, label, viewdate]);
                e.stopPropagation();
                e.preventDefault();
            }
        });
    })();

    //<<<<< Left-right navigation bottons click event
    (function wireTimelineArrows() {
        function notify() {
            var st = scheduler.getState();
            var payload = {
                mode: st.mode,
                start: new Date(st.min_date).toISOString(),
                end: new Date(st.max_date).toISOString()
            };
            Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("OnTimelineNavigate", [JSON.stringify(payload)]);
        }

        var root = document.getElementById("scheduler_here");
        if (root && !root._navWired) {
            root._navWired = true;
            // Delegate so it survives header re-renders
            root.addEventListener("click", function (e) {
                if (e.target.closest(".dhx_cal_prev_button")) {
                    setTimeout(notify, 0);
                } else if (e.target.closest(".dhx_cal_next_button")) {
                    setTimeout(notify, 0);
                }
            });
        }
    })();
    //>>

    scheduler.attachEvent("onDblClick", function (id, ev){
        console.log("Event onDblClick:", id, ev);
        
        // Capture event data after resize/drag
        var eventData = {
            id: id,
            text: ev.text,
            start_date: ev.start_date,
            end_date: ev.end_date,
            section_id: ev.section_id
        };        
        
        // Send to BC
        Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("OnEventDblClick", [id, JSON.stringify(eventData)]);

        // Block default lightbox opening
        return false;
    });

    // After the lightbox is built, toggle resource block and footer button
    scheduler.attachEvent("onLightbox", function (id) {
        // Apply section visibility after DOM exists
        var res = document.querySelector(".dhx_cal_light .resource-picker");
        if (res) res.style.display = resourceBlockVisible ? "" : "none";

        var bc = document.querySelector(".dhx_cal_light .bc-planning");
        if (bc) bc.style.display = bcPlanningVisible ? "" : "none";
    });

    // Mark events created from the UI (drag-create) - unchanged from before: the temp event
    // is left in the data store as-is here, so it renders immediately as a normal draft bar
    // on the timeline while the user is still mid-interaction, before any lightbox decision
    // is made.
    scheduler.attachEvent("onEventCreated", function (id) {
        var ev = scheduler.getEvent(id);
        if (ev) ev._isNewForLightbox = true;
        return true;
    });

    // New event creation (drag-create on the timeline) is handled entirely by BC now - the
    // Day Planning Card (page 50668), not the native DHTMLX lightbox. onBeforeLightbox (not
    // onEventCreated) is the right interception point: it can cancel just the LIGHTBOX while
    // leaving the draft event/bar drawn on the timeline exactly where the user dragged it -
    // that draft stays visible for as long as the BC Card is open, and only disappears once
    // RefreshSchedule() (called from AL after the Card closes, Save or Cancel either way)
    // does its normal scheduler.clearAll() + reparse-from-BC cycle: on Save the real saved
    // event takes its place, on Cancel nothing new comes back and the draft is simply gone -
    // no separate "delete the draft" step needed on either path.
    //
    // start_date/end_date of the drag both get sent - AL uses start_date for Plan Date and
    // prefills Start/End Time Requested from the drag's own start/end clock time (the user can
    // still change either on the Card). The drag is still constrained to a single day by
    // construction: only the Plan Date comes from start_date, so a drag that happens to cross
    // midnight simply has its end time's DATE component ignored, not its time-of-day.
    scheduler.attachEvent("onBeforeLightbox", function (id) {
        var ev = scheduler.getEvent(id);
        var isNew = !!(ev && ev._isNewForLightbox);

        if (isNew) {
            var sectionId = ev.section_id || '';
            var startDateIso = ev.start_date ? new Date(ev.start_date).toISOString() : '';
            var endDateIso = ev.end_date ? new Date(ev.end_date).toISOString() : '';
            if (sectionId && startDateIso) {
                Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("OnDragCreateDayPlanning", [sectionId, startDateIso, endDateIso]);
            }
            return false; // cancel the lightbox only - the draft bar stays on the timeline
        }

        resourceBlockVisible = false;
        bcPlanningVisible = true;
        return true;
    });

    scheduler.attachEvent("onAfterLightbox", function(){
        var id = scheduler.getState().lightbox_id;
        var ev = id ? scheduler.getEvent(id) : null;
        if (ev) delete ev._isNewForLightbox;
        resourceBlockVisible = false;
        bcPlanningVisible = false;
        var res = document.querySelector(".dhx_cal_light .resource-picker");
        if (res) res.style.display = "none";
        var bc = document.querySelector(".dhx_cal_light .bc-planning");
        if (bc) bc.style.display = "none";
    });

    // Attach resize event
    scheduler.attachEvent("onEventChanged", function(id, ev){
        if (ev) delete ev._isNewForLightbox; // new event is no longer "new"

        // Validate same-day event
        var s = ev && ev.start_date ? new Date(ev.start_date) : null;
        var e = ev && ev.end_date ? new Date(ev.end_date) : null;
        if (s && e) {
            var sameDay = s.getFullYear() === e.getFullYear() &&
                        s.getMonth() === e.getMonth() &&
                        s.getDate() === e.getDate();
            if (!sameDay) {
                alert("Start date and end date must be on the same day.");
                // Remove the just-created event to effectively cancel the add
                if (typeof scheduler !== "undefined") {
                    scheduler.deleteEvent(id, true);
                }
                return false;
            }
        }

        console.log("Event changed:", id, ev);

        // Capture event data after resize/drag
        var eventData = {
            id: id,
            text: ev.text,
            start_date: ev.start_date,
            end_date: ev.end_date,
            section_id: ev.section_id
        };

        // Also reset after closing the lightbox (Cancel or Save)
        scheduler.attachEvent("onAfterLightbox", function(){
            var id = scheduler.getState().lightbox_id;
            var ev = id ? scheduler.getEvent(id) : null;
            if (ev) delete ev._isNewForLightbox;
            resourceBlockVisible = false;
            var n = document.querySelector(".dhx_cal_light .resource-picker");
            if (n) n.style.display = "none";
        });
        
        // Send to BC
        Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("OnEventChanged", [id, JSON.stringify(eventData)]);
    });

    scheduler.attachEvent("onEventAdded", function(id,ev){
        if (ev) delete ev._isNewForLightbox;   // <— important

        // Validate same-day event
        var s = ev && ev.start_date ? new Date(ev.start_date) : null;
        var e = ev && ev.end_date ? new Date(ev.end_date) : null;
        if (s && e) {
            var sameDay = s.getFullYear() === e.getFullYear() &&
                        s.getMonth() === e.getMonth() &&
                        s.getDate() === e.getDate();
            if (!sameDay) {
                alert("Start date and end date must be on the same day.");
                // Remove the just-created event to effectively cancel the add
                if (typeof scheduler !== "undefined") {
                    scheduler.deleteEvent(id, true);
                }
                return false;
            }
        }

        console.log("New Event:", ev);
        
        // Capture event data after resize/drag
        var eventData = {
            id: id,
            text: ev.text,
            start_date: ev.start_date,
            end_date: ev.end_date,
            section_id: ev.section_id,
            resource_id: ev.resource_id || '',
            resource_name: ev.resource_name || ''
        };
        
        // Send to BC
        Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("onEventAdded", [id,JSON.stringify(eventData)]);
        return true;
    });
    // ***** end of events triger block

    // Tell AL we are safe to call now
    Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("ControlReady", []);

  } catch (e) {
    console.warn("BOOT warning:", e);
  }
}

// Called from AL (setup-driven) to override the Day Planning bar colors defined
// as CSS custom properties above. colorsJson keys: envelope, envelopeBorder,
// assigned, requested — any key can be omitted to keep that color's default.
function SetBarColors(colorsJson) {
    try {
        var colors = ParseJSonTxt(colorsJson) || {};
        var root = document.getElementById("scheduler_here");
        if (!root) return;
        if (colors.envelope) root.style.setProperty("--dp-color-envelope", colors.envelope);
        if (colors.envelopeBorder) root.style.setProperty("--dp-color-envelope-border", colors.envelopeBorder);
        if (colors.assigned) root.style.setProperty("--dp-color-assigned", colors.assigned);
        if (colors.requested) root.style.setProperty("--dp-color-requested", colors.requested);
        // 3-part bar split (Assigned/Requested both valid and different) — from Task
        // Scheduler Setup's "Assigned High (%)"/"Requested High (%)". Left at their CSS
        // defaults (80%/20%) whenever setup doesn't override them (0/blank).
        if (colors.assignedHeight) root.style.setProperty("--dp-height-assigned", colors.assignedHeight + "%");
        if (colors.requestedHeight) root.style.setProperty("--dp-height-requested", colors.requestedHeight + "%");
        // Text/border colour is per-skill now (see SetSkillFontBorderColors below) - this
        // scheduler has no Capacity bar of its own, so there is no longer any bar here that
        // should read "Daily Optimizer Setup"."Bar Font Color"/GetBarFontColor.
    } catch (e) {
        console.warn("SetBarColors: invalid colorsJson", colorsJson, e);
    }
}

function safeCssToken(txt) {
    return String(txt == null ? "" : txt).replace(/[^a-zA-Z0-9_-]/g, "_");
}

// AL-callable: SetSkillFontBorderColors - applies per-skill bar text/border colour (codeunit
// 50609 "Visual Default Settings"' GetSkillFontColor/GetSkillBorderColor, via codeunit 50604
// "DHX Data Handler"'s BuildSkillFontBorderColorsJson) by injecting one CSS rule pair per skill,
// keyed to the "pts-skill-<token>" class event_class adds to every Day Planning bar above.
// skillsJson shape: [{code, fontColor, borderColor}, ...].
function SetSkillFontBorderColors(skillsJson) {
    try {
        var skills = ParseJSonTxt(skillsJson) || [];
        var css = skills.map(function (s) {
            var token = safeCssToken(s.code);
            // Full "border" shorthand, not just "border-color": these classes have no
            // border-width/border-style anywhere in dhtmlxscheduler.css's own defaults, so a bare
            // border-color rule renders no visible border at all (default border-style is "none").
            return ".pts-skill-" + token + " .dp-bar-label{color:" + (s.fontColor || "#000000") + "!important;}\n" +
                ".dhx_cal_event.event-DayPlanning.pts-skill-" + token + "," +
                ".dhx_cal_event_line.event-DayPlanning.pts-skill-" + token + "," +
                ".dhx_event_line.event-DayPlanning.pts-skill-" + token +
                "{border:1px solid " + (s.borderColor || "#14294D") + "!important;}";
        }).join("\n");
        var styleEl = document.getElementById("pts-skill-colors");
        if (!styleEl) {
            styleEl = document.createElement("style");
            styleEl.id = "pts-skill-colors";
            document.head.appendChild(styleEl);
        }
        styleEl.textContent = css;
    } catch (e) {
        console.warn("SetSkillFontBorderColors: invalid skillsJson", skillsJson, e);
    }
}

function Init(dataelements, EarliestPlanningDate) {
    // First JS call of the initial load cycle (ControlReady -> Init -> LoadData) — make sure
    // the overlay is showing even if BOOT's own earliest-show got missed for some reason.
    // Hidden at the end of LoadData(), the true last step of that cycle.
    _showTskLoading();

    // Parse input safely (supports JSON string or object)
    let parsed = ParseJSonTxt(dataelements);
    // Always use an array for y_unit, even if empty
    var elements = (parsed && Array.isArray(parsed.data)) ? parsed.data : [];
    if (!Array.isArray(elements)) elements = [];

    // If no sections, inject a dummy "No Data" section
    if (elements.length === 0) {
        elements = [{
            key: "nodata",
            label: "No Data"
        }];
    }

    // Remove existing timeline view if it exists (prevents duplicate view error)
    if (scheduler.matrix && scheduler.matrix.timeline) {
        scheduler.deleteView && scheduler.deleteView("timeline");
        delete scheduler.matrix.timeline;
    }

    // Defensive: set header to avoid DOM warnings if hiding tabs
    scheduler.config.header = ["date"];

    // Create timeline view (always with a valid y_unit array)
    RecreateTimelineView(elements);

    var anchorDate = applyTimelineStartHour(EarliestPlanningDate);
    scheduler.init('scheduler_here', anchorDate, "timeline");

    // Wire right-click context menu now that scheduler DOM exists
    setupContextMenu();

    // Wire the Job/Job Task filter toolbar now that scheduler DOM exists
    setupFilterToolbar();

    // Wire the Collapse/Expand All icon now that the tree timeline exists
    setupCollapseAllToggle();

    // Notify BC
    Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("OnAfterInit", []);
}

function LoadData(eventsJson) {
    console.log("LoadData called with:", eventsJson);
    if (!scheduler_here) {
        console.warn("scheduler not initialized. Call Init() first.");
        return;
    }

    try {
        if (typeof scheduler === "undefined") {
            console.error("DHX Scheduler library not loaded. Cannot load data.");
            return;
        }

        scheduler.clearAll();

        // Always parse and validate events array
        let parsedEvents = ParseJSonTxt(eventsJson);
        let events = [];
        if (parsedEvents) {
            if (Array.isArray(parsedEvents.data)) {
                events = parsedEvents.data;
            } else if (Array.isArray(parsedEvents)) {
                events = parsedEvents;
            }
        }
        if (!Array.isArray(events)) events = [];
        if (events.length > 0) {
            scheduler.parse(events); // load events into scheduler
        }

    } catch (err) {
        console.error("Unexpected error in LoadData:", err);
    } finally {
        // True last step of the initial load cycle (ControlReady -> Init -> LoadData) —
        // always hide, even if parsing threw, so the overlay never gets stuck.
        _hideTskLoading();
    }
}

// Defensive JSON parser
function ParseJSonTxt(jsonText) {
    let parsed;
    const toJsonString = (s) => {
        return s
            .replace(/'/g, '"')
            .replace(/([{,]\s*)([a-zA-Z_]\w*)(\s*:)/g, '$1"$2"$3');
    };
    try {
        if (typeof jsonText === "string") {
            try {
                parsed = JSON.parse(jsonText);
            } catch {
                const normalized = toJsonString(jsonText);
                parsed = JSON.parse(normalized);
            }
        } else if (typeof jsonText === "object" && jsonText !== null) {
            parsed = jsonText;
        }
    } catch (e) {
        console.log("Invalid JSON for dataelements:", e, jsonText);
        return false;
    }
    return parsed;
}

function UpdateEventId(EventIdsJsonTxt) {
    console.log("UpdateEventId called with:", EventIdsJsonTxt);
    /*
    EventIdsJsonTxt = 
    {
        "OldEventId": "OldEventId",
        "NewEventId": "NewEventId",
    }
    */
   // Be tolerant to trailing commas in the incoming JSON
    if (typeof EventIdsJsonTxt === "string") {
        EventIdsJsonTxt = EventIdsJsonTxt.replace(/,\s*([}\]])/g, "$1");
    }

    const payload = ParseJSonTxt(EventIdsJsonTxt);
    if (!payload) {
        alert("UpdateEventId: invalid JSON");
        return;
    }

    const oldId = payload.OldEventId;
    const newId = payload.NewEventId;

    if (oldId == null || newId == null) {
        alert("UpdateEventId: OldEventId/NewEventId are required");
        return;
    }
    if (String(oldId) === String(newId)) {
        alert("UpdateEventId: ids are identical; nothing to change");
        return;
    }
    if (typeof scheduler === "undefined") {
        alert("UpdateEventId: scheduler not initialized");
        return;
    }

    const ev = scheduler.getEvent(oldId);
    if (!ev) {
        alert("UpdateEventId: event not found for OldEventId: " + oldId);
        return;
    }
    if (scheduler.getEvent(newId)) {
        alert("UpdateEventId: an event with NewEventId already exists: " + newId);
        return;
    }

    // Official way to remap an event id
    scheduler.changeEventId(oldId, newId);
    scheduler.updateEvent(newId);
    
    // Notify BC (optional)
    Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("OnAfterEventIdUpdated", [oldId, newId]);
}

// Allow AL to update fields of the currently opened lightbox event
// Example input:
//   {
//     "text": "New description",
//     "section_id": "1010",
//     "start_date": "2025-11-07T19:25:00Z",
//     "end_date": "2025-11-08T11:55:00Z"
//   }
function SetLightboxEventValues(valuesJsonTxt, ResourceId, ResourceName) {
    console.log("SetLightboxEventValues called with:", valuesJsonTxt, ResourceId, ResourceName);

    // valuesJsonTxt is optional; only use it if it’s an object
    var values = ParseJSonTxt(valuesJsonTxt);

    if (typeof scheduler === "undefined") return;

    var lbId = scheduler.getState().lightbox_id;
    if (!lbId) return;

    var ev = scheduler.getEvent(lbId);
    if (!ev) return;

    // Apply optional fields from JSON
    if (values && typeof values === "object") {
        if ("text" in values) ev.text = values.text;
        if ("section_id" in values) ev.section_id = values.section_id;
        if (values.start_date) ev.start_date = new Date(values.start_date);
        if (values.end_date) ev.end_date = new Date(values.end_date);
    }

    // Always use the arguments to set resource fields
    if (ResourceId != null) ev.resource_id = ResourceId;
    if (ResourceName != null) {
        ev.resource_name = ResourceName;
        // keep event description in sync with resource name
        ev.text = ResourceName;
    }

    // Update inputs in the open lightbox UI from the arguments
    var box = document.querySelector(".dhx_cal_light");
    if (box) {
        var idInput = box.querySelector('#resource_id_input');
        var nameInput = box.querySelector('#resource_name_input');
        if (idInput && ResourceId != null) idInput.value = ResourceId;
        if (nameInput && ResourceName != null) nameInput.value = ResourceName;
    }

    // Also update the built-in "description" section so Save uses new text
    try {
        var descSection = scheduler.formSection && scheduler.formSection("description");
        if (descSection && typeof descSection.setValue === "function") {
            descSection.setValue(ev.text || "");
        }
    } catch (e) {
        // ignore if lightbox not open or API unavailable
    }

    scheduler.updateEvent(lbId);
}

function RefreshTimeline(resourcesJson, eventsJson, dateAnchor) {
    console.log("resourcesJson:", resourcesJson);
    console.log("eventsJson:", eventsJson);

    // Self-contained full reload cycle (sections + events + view in one shot) — show at the
    // start, hide in the finally below so it never gets stuck even if something throws.
    _showTskLoading();

    try {
        //debugger;
        // 1) Parse and update sections (y_unit)
        var resources = ParseJSonTxt(resourcesJson);
        var sections = (resources && Array.isArray(resources.data)) ? resources.data : [];
        if (!Array.isArray(sections)) sections = [];

        // If no sections, inject a dummy "No Data" section
        let onlyNoData = false;
        if (sections.length === 0) {
            sections = [{ key: "nodata", label: "No Data" }];
            onlyNoData = true;
        }

        RecreateTimelineView(sections);

        // 2) Reload events
        scheduler.clearAll();
        let parsedEvents = ParseJSonTxt(eventsJson);
        let events = [];
        if (!onlyNoData && parsedEvents) {
            if (Array.isArray(parsedEvents.data)) {
                events = parsedEvents.data;
            } else if (Array.isArray(parsedEvents)) {
                events = parsedEvents;
            }
        }
        if (!Array.isArray(events)) events = [];

        scheduler.parse(events);

        // 3) Move view to the week containing dateAnchor (if provided)
        let anchor = null;
        if (dateAnchor) {
            if (dateAnchor instanceof Date) {
                anchor = dateAnchor;
            } else if (typeof dateAnchor === "number") {
                anchor = new Date(dateAnchor); // epoch ms
            } else if (typeof dateAnchor === "string") {
                let d = new Date(dateAnchor);  // ISO or BC string
                if (!isNaN(d)) anchor = d;
            }
        }
        let viewDate = anchor ? scheduler.date.week_start(anchor) : scheduler.getState().date;
        viewDate = applyTimelineStartHour(viewDate);
        scheduler.setCurrentView(viewDate, "timeline");
        //scheduler.updateView("timeline"); // <-- force full refresh

    } catch (e) {
        console.error("RefreshTimeline failed:", e);
    } finally {
        _hideTskLoading();
    }
}

// Called from AL (setup-driven) to override the hour interval shown on the timeline
// scale (default 3h, i.e. "00 03 06 09 12 15 18 21..."). Always keeps ~7 days visible,
// regardless of step, by recomputing the column count from total hours / step. Must be
// called (if at all) BEFORE Init(), since RecreateTimelineView() reads this at build time.
function SetTimelineHourStep(hourStep) {
    var step = parseInt(hourStep, 10);
    timelineHourStep = (step > 0) ? step : 3;
}

// Called from AL (setup-driven) to restrict the timeline to a daily window, e.g.
// 07:00-19:00, instead of the full 24h day. Works together with scheduler.ignore_timeline
// (above) which does the actual compacting. Must be called (if at all) BEFORE Init(),
// same ordering requirement as SetTimelineHourStep. Invalid/out-of-range input is
// ignored and the full-day default (0-24) is kept.
function SetTimelineHourRange(startHour, endHour) {
    var s = parseInt(startHour, 10);
    var e = parseInt(endHour, 10);
    if (isNaN(s) || isNaN(e) || s < 0 || e > 24 || s >= e) return;
    timelineStartHour = s;
    timelineEndHour = e;
}

// Returns a copy of dateObj with the time set to timelineStartHour:00:00. Keeping the
// scale's anchor aligned to timelineStartHour (rather than midnight) is what makes the
// visible window start exactly there every day, provided timelineHourStep evenly divides
// 24 (e.g. 1,2,3,4,6,8,12) — with a non-divisor step the daily start still drifts, since
// that's an inherent property of fixed-interval hour stepping, not something this can fix.
function applyTimelineStartHour(dateObj) {
    var d = new Date(dateObj);
    d.setHours(timelineStartHour, 0, 0, 0);
    return d;
}

function RecreateTimelineView(sections) {
    // Remove existing timeline view if it exists
    if (scheduler.matrix && scheduler.matrix.timeline) {
        if (typeof scheduler.deleteView === "function") {
            scheduler.deleteView("timeline");
        }
        delete scheduler.matrix.timeline;
    }

    // 7 days visible at once, within the configured daily window (full day by default).
    var windowHours = Math.max(1, timelineEndHour - timelineStartHour);
    var columnsPerDay = Math.ceil(windowHours / timelineHourStep);
    var visibleColumns = Math.max(1, columnsPerDay * 7);

    // Recreate timeline view with new sections
    scheduler.createTimelineView({
        name: "timeline",
        x_unit: "hour",
        x_date: "%H",
        x_step: timelineHourStep,
        x_size: visibleColumns,
        x_length: visibleColumns,
        dy: 20,
        event_dy: 20,
        folder_dy: 20,  // Height for parent/folder rows
        section_autoheight: false,
        resize_events: true,
        y_unit: sections,
        y_property: "section_id",
        render: "tree",
        scale_height: 40,
        second_scale: {
            x_unit: "day",
            x_date: "%D %d %M"
        }
    });
}

// ═══════════════════════════════════════════════════════════════
// Right-click context menu for Events and Sections
// ═══════════════════════════════════════════════════════════════
function setupContextMenu() {
    // ── Build the menu DOM once ──────────────────────────────────
    var root = document.getElementById('scheduler_here');
    if (!root || root._ctxWired) return;
    root._ctxWired = true;

    var menu = document.createElement('div');
    menu.id = 'dhx-ctx-menu';
    menu.className = 'hidden';
    menu.innerHTML =
        '<div class="dhx-ctx-item" data-action="OpenDayPlanning">' +
            '<span class="dhx-ctx-icon">&#128197;</span>Open Day Planning</div>' +
        '<div class="dhx-ctx-item" data-action="OpenDayPlanningCard">' +
            '<span class="dhx-ctx-icon">&#128211;</span>Open Day Planning Card</div>' +
        '<div class="dhx-ctx-separator"></div>' +
        '<div class="dhx-ctx-item" data-action="OpenTask">' +
            '<span class="dhx-ctx-icon">&#128196;</span>Open Job Task Card</div>' +
        '<div class="dhx-ctx-item" data-action="ShowJobResources">' +
            '<span class="dhx-ctx-icon">&#128100;</span>Open Job Task Resources</div>' +
        '<div class="dhx-ctx-item" data-action="OpenDayPlanningVisual">' +
            '<span class="dhx-ctx-icon">&#128248;</span>Open Job Task Scheduler</div>' +
        '<div class="dhx-ctx-separator"></div>' +
        '<div class="dhx-ctx-item" data-action="OpenResSchedulerTimeline">' +
            '<span class="dhx-ctx-icon">&#128101;</span>Open Resource Scheduler (Timeline)</div>' +
        '<div class="dhx-ctx-separator"></div>' +
        '<div class="dhx-ctx-item" data-action="OpenResourceSchedulerAssigned">' +
            '<span class="dhx-ctx-icon">&#128101;</span>Open Resource Scheduler (assigned)</div>' +        
        '<div class="dhx-ctx-item" data-action="OpenResourceSchedulerRequested">' +
            '<span class="dhx-ctx-icon">&#128101;</span>Open Resource Scheduler (Requested)</div>' +
        '<div class="dhx-ctx-item" data-action="OpenAssignedResourceCard">' +
            '<span class="dhx-ctx-icon">&#128100;</span>Open Resource Card (assigned)</div>' +
        '<div class="dhx-ctx-item" data-action="OpenRequestedResourceCard">' +
            '<span class="dhx-ctx-icon">&#128100;</span>Open Resource Card (Requested)</div>' +
        '<div class="dhx-ctx-separator"></div>' +
        '<div class="dhx-ctx-item ctx-cancel" data-action="Cancel">' +
            '<span class="dhx-ctx-icon">&#10005;</span>Cancel</div>';
    document.body.appendChild(menu);

    var _ctxTarget = null; // { type: 'event'|'section', id: string, eventData: object|null }

    function showMenu(x, y, target) {
        _ctxTarget = target;
        // Show/hide ShowJobResources only when clicking an event
        menu.querySelector('[data-action="ShowJobResources"]').style.display =
            (target.type === 'event') ? '' : 'none';
        // Show DayPlanning actions only for events
        menu.querySelector('[data-action="OpenDayPlanning"]').style.display =
            (target.type === 'event') ? '' : 'none';
        menu.querySelector('[data-action="OpenDayPlanningCard"]').style.display =
            (target.type === 'event') ? '' : 'none';
        menu.querySelector('[data-action="OpenDayPlanningVisual"]').style.display =
            (target.type === 'event') ? '' : 'none';
        menu.querySelector('[data-action="OpenResourceSchedulerAssigned"]').style.display =
            (target.type === 'event') ? '' : 'none';
        menu.querySelector('[data-action="OpenResSchedulerTimeline"]').style.display =
            (target.type === 'event') ? '' : 'none';
        menu.querySelector('[data-action="OpenResourceSchedulerRequested"]').style.display =
            (target.type === 'event') ? '' : 'none';
        menu.querySelector('[data-action="OpenRequestedResourceCard"]').style.display =
            (target.type === 'event') ? '' : 'none';
        menu.querySelector('[data-action="OpenAssignedResourceCard"]').style.display =
            (target.type === 'event') ? '' : 'none';

        menu.className = '';
        // Keep inside viewport
        var menuW = 200, menuH = 180;
        var left = (x + menuW > window.innerWidth)  ? window.innerWidth  - menuW - 4 : x;
        var top  = (y + menuH > window.innerHeight) ? window.innerHeight - menuH - 4 : y;
        menu.style.left = left + 'px';
        menu.style.top  = top  + 'px';
    }

    function hideMenu() {
        menu.className = 'hidden';
        _ctxTarget = null;
    }

    // ── Menu item click ─────────────────────────────────────────
    menu.addEventListener('click', function(e) {
        var item = e.target.closest('.dhx-ctx-item');
        if (!item) return;
        var action = item.getAttribute('data-action');
        if (action && action !== 'Cancel' && _ctxTarget) {
            var payload = JSON.stringify({
                action:    action,
                type:      _ctxTarget.type,
                id:        _ctxTarget.id,
                eventData: _ctxTarget.eventData || null
            });
            if (_ctxTarget.type === 'event') {
                Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('OnEventContextMenu',
                    [_ctxTarget.id, action, payload]);
            } else {
                Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('OnSectionContextMenu',
                    [_ctxTarget.id, action, payload]);
            }
        }
        hideMenu();
        e.stopPropagation();
    });

    // ── Dismiss on outside click or scroll ──────────────────────
    document.addEventListener('click',     function(e) { if (!menu.contains(e.target)) hideMenu(); });
    document.addEventListener('scroll',    hideMenu, true);
    document.addEventListener('keydown',   function(e) { if (e.key === 'Escape') hideMenu(); });

    // ── Wire contextmenu on the scheduler container ─────────────
    root.addEventListener('contextmenu', function(e) {
            e.preventDefault();
            e.stopPropagation();

            // ── Check: clicked on an event? ──────────────────────
            var eventEl = e.target.closest('[event_id]') ||
                          e.target.closest('.dhx_cal_event_line') ||
                          e.target.closest('.dhx_cal_event');
            if (eventEl) {
                var evId = eventEl.getAttribute('event_id') || eventEl.getAttribute('data-event-id') || '';
                var ev   = (evId && scheduler.getEvent) ? scheduler.getEvent(evId) : null;
                var evData = ev ? {
                    id:         ev.id,
                    text:       ev.text,
                    section_id: ev.section_id,
                    start_date: ev.start_date ? ev.start_date.toISOString() : '',
                    end_date:   ev.end_date   ? ev.end_date.toISOString()   : ''
                } : null;
                showMenu(e.clientX, e.clientY, { type: 'event', id: evId || '', eventData: evData });
                return;
            }

            // ── Check: clicked on a section label row? ───────────
            var sectionRow = e.target.closest('.dhx_timeline_label_row') ||
                             e.target.closest('[data-row-id]');
            if (sectionRow) {
                var sectionId = sectionRow.getAttribute('data-row-id') || '';
                showMenu(e.clientX, e.clientY, { type: 'section', id: sectionId, eventData: null });
                return;
            }

            // Clicked elsewhere — dismiss any open menu
            hideMenu();
        });
}

// ═══════════════════════════════════════════════════════════════
// Job/Job Task filter toolbar (top-left of the timeline grid)
// ═══════════════════════════════════════════════════════════════
// Default: only the (▽) filter button is shown -> click opens the BC filter popup
// (Job No. / Job Task No.). Once AL applies a filter (dialog closed with OK, not
// Cancel), a (✕) reset button appears next to it and hovering the filter button
// shows what's applied. Clicking (✕) clears the filter back to the default state.
function setupFilterToolbar() {
    var root = document.getElementById('scheduler_here');
    if (!root || root._filterToolbarWired) return;
    root._filterToolbarWired = true;

    var toolbar = document.createElement('div');
    toolbar.id = 'tsk-filter-toolbar';
    root.appendChild(toolbar);

    _updateTaskFilterToolbar();
}

// ═══════════════════════════════════════════════════════════════
// Collapse/Expand All (folder rows of the tree timeline)
// ═══════════════════════════════════════════════════════════════
function setupCollapseAllToggle() {
    var root = document.getElementById('scheduler_here');
    if (!root || root._collapseAllWired) return;
    root._collapseAllWired = true;

    var btn = document.createElement('button');
    btn.id = 'tsk-collapseall-icon';
    btn.type = 'button';
    _renderCollapseAllIcon(btn);
    btn.addEventListener('click', function (e) {
        e.stopPropagation();
        ToggleCollapseExpandAllSections();
    });

    root.appendChild(btn);
}

function _renderCollapseAllIcon(btn) {
    var collapsed = _allSectionsCollapsed;
    btn.title = collapsed ? 'Expand All' : 'Collapse All';
    btn.innerHTML = collapsed
        ? '<svg viewBox="0 0 24 24" width="13" height="13" fill="none" stroke="#fff" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round"><path d="M15 3h6v6M9 21H3v-6M21 3l-7 7M3 21l7-7"/></svg>'
        : '<svg viewBox="0 0 24 24" width="13" height="13" fill="none" stroke="#fff" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round"><path d="M4 14h6v6M20 10h-6V4M14 10l7-7M10 14l-7 7"/></svg>';
}

// Sets open/closed on every folder node of the tree timeline (recursively,
// via the y_unit_original tree the treetimeline plugin keeps internally) and
// forces a redraw. Same idea as gantt.eachTask(...)+gantt.render() in
// src/dhx/ganttdemo2/wrapper.js's ToggleCollapseExpandAll, adapted to the
// dhtmlx Scheduler's tree API (_getArrayToDisplay flattens y_unit_original
// into the visible y_unit; onOptionsLoad is what the library itself fires
// after a folder toggle to trigger the matching re-render).
function ToggleCollapseExpandAllSections() {
    if (typeof scheduler === "undefined" || !scheduler.matrix || !scheduler.matrix.timeline ||
        !scheduler.matrix.timeline.y_unit_original) {
        return;
    }

    _allSectionsCollapsed = !_allSectionsCollapsed;
    var open = !_allSectionsCollapsed;

    (function setOpen(nodes) {
        for (var i = 0; i < nodes.length; i++) {
            if (nodes[i].children) {
                nodes[i].open = open;
                setOpen(nodes[i].children);
            }
        }
    })(scheduler.matrix.timeline.y_unit_original);

    scheduler.matrix.timeline.y_unit = scheduler._getArrayToDisplay(scheduler.matrix.timeline.y_unit_original);
    scheduler.callEvent("onOptionsLoad", []);

    var btn = document.getElementById('tsk-collapseall-icon');
    if (btn) _renderCollapseAllIcon(btn);
}

// Part B pagination: appends a background-loaded remainder (Jobs that didn't fit on the first
// synchronous ~50-row page) into the already-rendered timeline IN PLACE - modeled directly on
// ToggleCollapseExpandAllSections above (same y_unit_original mutation + _getArrayToDisplay +
// onOptionsLoad("onOptionsLoad") sequence, proven to redraw the tree without a full deleteView/
// scheduler.init reset). sectionsJson is the same {"data":[{key,label,open,children},...]} shape
// Init/RefreshTimeline already use (one entry per Job); eventsJson is the same plain JSON array of
// event objects LoadData/RefreshTimeline already use. Deliberately does NOT go through
// RecreateTimelineView/Init/RefreshTimeline - those are full-reset paths this pagination feature
// exists to avoid. scheduler.parse() is additive by design, so no clearAll() is needed for the
// event half either.
function AppendSections(sectionsJson, eventsJson) {
    try {
        if (typeof scheduler === "undefined" || !scheduler.matrix || !scheduler.matrix.timeline ||
            !scheduler.matrix.timeline.y_unit_original) {
            return;
        }

        var parsedSections = ParseJSonTxt(sectionsJson);
        var newJobNodes = (parsedSections && Array.isArray(parsedSections.data)) ? parsedSections.data : [];
        if (!Array.isArray(newJobNodes)) newJobNodes = [];

        if (newJobNodes.length > 0) {
            // Drop the "No Data" placeholder node (injected by Init/RefreshTimeline whenever the
            // first page came back with zero sections) before appending the real Jobs.
            var existing = scheduler.matrix.timeline.y_unit_original.filter(function (n) {
                return n.key !== "nodata";
            });
            scheduler.matrix.timeline.y_unit_original = existing.concat(newJobNodes);
            scheduler.matrix.timeline.y_unit = scheduler._getArrayToDisplay(scheduler.matrix.timeline.y_unit_original);
            scheduler.callEvent("onOptionsLoad", []);
        }

        var parsedEvents = ParseJSonTxt(eventsJson);
        var newEvents = [];
        if (parsedEvents) {
            if (Array.isArray(parsedEvents.data)) {
                newEvents = parsedEvents.data;
            } else if (Array.isArray(parsedEvents)) {
                newEvents = parsedEvents;
            }
        }
        if (!Array.isArray(newEvents)) newEvents = [];
        if (newEvents.length > 0) {
            scheduler.parse(newEvents);
        }
    } catch (e) {
        console.error("AppendSections failed:", e);
    }
}
window.AppendSections = AppendSections;

function _positionTskFilterTooltip(e) {
    var popup = document.getElementById('tsk-filter-tooltip-popup');
    if (!popup) return;
    var left = e.clientX + 12;
    var top = e.clientY + 12;
    // Keep inside viewport
    var popupW = popup.offsetWidth || 200;
    var popupH = popup.offsetHeight || 60;
    if (left + popupW > window.innerWidth) left = e.clientX - popupW - 12;
    if (top + popupH > window.innerHeight) top = e.clientY - popupH - 12;
    popup.style.left = left + 'px';
    popup.style.top = top + 'px';
}

function _updateTaskFilterToolbar() {
    var toolbar = document.getElementById('tsk-filter-toolbar');
    if (!toolbar) return;
    toolbar.innerHTML = '';

    // Ensure fixed tooltip popup exists in body (never clipped by overflow:hidden)
    var popup = document.getElementById('tsk-filter-tooltip-popup');
    if (!popup) {
        popup = document.createElement('div');
        popup.id = 'tsk-filter-tooltip-popup';
        document.body.appendChild(popup);
    }

    var fi = _taskFilterInfo;

    // Build tooltip content without innerHTML string-building (user-controlled values)
    popup.innerHTML = '';
    var titleEl = document.createElement('b');
    titleEl.textContent = fi ? 'Filter applied:' : 'Click to filter by Job / Job Task';
    popup.appendChild(titleEl);
    if (fi) {
        if (fi.job) {
            popup.appendChild(document.createElement('br'));
            popup.appendChild(document.createTextNode('Job = ' + fi.job));
        }
        if (fi.task) {
            popup.appendChild(document.createElement('br'));
            popup.appendChild(document.createTextNode('Task = ' + fi.task));
        }
        if (fi.periodFrom || fi.periodTo) {
            popup.appendChild(document.createElement('br'));
            popup.appendChild(document.createTextNode('Period: ' + (fi.periodFrom || '') + ' to ' + (fi.periodTo || '')));
        }
    }

    // (funnel) Filter button — always visible; opens the BC filter popup.
    // Inline SVG (self-contained, no network fetch — a BC control add-in can't rely on
    // internet access at runtime) instead of an external icon asset.
    var filterBtn = document.createElement('button');
    filterBtn.className = 'tsk-filter-icon';
    filterBtn.innerHTML =
        '<svg viewBox="0 0 24 24" width="13" height="13" style="vertical-align:middle;">' +
            '<path d="M3 4h18l-7.2 8.6v6.4l-3.6 1.8v-8.2z" fill="#fff"/>' +
        '</svg>';
    filterBtn.style.cssText = 'background:' + (fi ? '#1a73e8' : '#5f6368') +
        ';border:none;border-radius:50%;width:22px;height:22px;line-height:22px;' +
        'text-align:center;padding:0;cursor:pointer;vertical-align:middle;display:inline-block;';

    filterBtn.addEventListener('mouseenter', function (e) {
        popup.style.display = 'block';
        _positionTskFilterTooltip(e);
    });
    filterBtn.addEventListener('mousemove', function (e) {
        _positionTskFilterTooltip(e);
    });
    filterBtn.addEventListener('mouseleave', function () {
        popup.style.display = 'none';
    });
    filterBtn.addEventListener('click', function (e) {
        e.stopPropagation();
        popup.style.display = 'none';
        Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('OnFilterIconClick', []);
    });

    toolbar.appendChild(filterBtn);

    // (✕) Reset button — only shown once a filter is applied
    if (fi) {
        var resetBtn = document.createElement('button');
        resetBtn.className = 'tsk-filter-reset';
        resetBtn.title = 'Click to Reset Filter';
        resetBtn.textContent = '✕'; // ✕
        resetBtn.style.cssText = 'background:#c0392b;border:none;border-radius:50%;width:22px;height:22px;' +
            'line-height:22px;text-align:center;padding:0;cursor:pointer;font-size:13px;font-weight:700;' +
            'color:#fff;vertical-align:middle;display:inline-block;';

        resetBtn.addEventListener('click', function (e) {
            e.stopPropagation();
            popup.style.display = 'none';
            Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('OnClearTaskFilter', []);
        });

        toolbar.appendChild(resetBtn);
    }
}

// Called by AL after a filter is applied (dialog closed with OK) or after any
// schedule refresh, to keep the toolbar/tooltip in sync. jobNo/taskNo both blank
// means "not filtered" — same convention as SetResourcePanelFilterInfo in
// src/dhx/ganttdemo2/wrapper.js.
function SetTaskFilterInfo(jobNo, taskNo, periodFrom, periodTo) {
    if (!jobNo && !taskNo) {
        _taskFilterInfo = null;
    } else {
        _taskFilterInfo = {
            job: jobNo || '',
            task: taskNo || '',
            periodFrom: periodFrom || '',
            periodTo: periodTo || ''
        };
    }
    _updateTaskFilterToolbar();
}

// Called by AL to explicitly clear the filter display (parity with ClearResourceFilter
// in the Gantt wrapper) — not required by the click-to-reset flow above (which goes
// through OnClearTaskFilter -> AL -> SetTaskFilterInfo with blanks) but kept for AL
// call sites that want to reset the icon without a round trip through RefreshSchedule.
function ClearTaskFilterInfo() {
    _taskFilterInfo = null;
    _updateTaskFilterToolbar();
}

function get_events_not_match_with_section() {
    var invalidEvents = [];
    var sectionsMap = {};
    if (scheduler.matrix && scheduler.matrix.timeline && Array.isArray(scheduler.matrix.timeline.y_unit)) {
        scheduler.matrix.timeline.y_unit.forEach(function(section) {
            sectionsMap[section.key] = true;
        });
    }
    if (scheduler.getEvents) {
        var allEvents = scheduler.getEvents();
        allEvents.forEach(function(event) {
            if (!sectionsMap[event.section_id]) {
                invalidEvents.push(event);
            }
        });
    }
    Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('OnEventsNotMatch', [JSON.stringify(invalidEvents)]);
}

function getAllEvents() {
    var allEvents = [];
    if (scheduler.getEvents) {
        allEvents = scheduler.getEvents();
    }
    Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('OnGetAllEvents', [JSON.stringify(allEvents)]);
}

function getAllSections() {
    var allSections = [];
    if (scheduler.matrix && scheduler.matrix.timeline && Array.isArray(scheduler.matrix.timeline.y_unit)) {
        allSections = scheduler.matrix.timeline.y_unit;
    }
    Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('OnGetAllSections', [JSON.stringify(allSections)]);
}

