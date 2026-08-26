// ============================================================
// DHX Scheduler (Resource+Capacity) - "Resource Scheduler (New)"
// Left panel: Skill > Resource tree (treetimeline, like poolresourceschedule).
// Right panel: Capacity bars + Day Planning bars (Requested/Assigned progress
// split, like projectschedule's event_bar_text technique) merged client-side
// so Show/Hide Capacity / Show/Hide Day Planning toggle instantly without an
// AL round trip (like src/dhx/resourceschedule/wrapper.js's allEvents/
// allCapacity split).
// ============================================================

var scheduler_here;
var allDayPlanningEvents = [];   // raw events from LoadData (type: 'DayPlanning')
var allCapacityEvents = [];      // raw events from LoadCapacity (type: 'capacity')
var showDayPlanning = true;
var showCapacity = true;
var timelineHourStep = 3;         // hours between marks on the timeline scale; overridable via SetTimelineHourStep (AL setup)
var timelineStartHour = 0;        // start of the visible daily window (0 = midnight); overridable via SetTimelineHourRange
var timelineEndHour = 24;         // end of the visible daily window (24 = midnight); overridable via SetTimelineHourRange
var hideNoEventResources = false; // Hide/Show no event resources toggle - see SetHideNoEventResources
var _rawTreeSections = null;      // last unfiltered Skill>Resource tree received from AL (Init/RefreshTimeline)
var _allSectionsCollapsed = false;
var _resFilterInfo = null; // { resNo, resName, periodFrom, periodTo, skillFilter }

// -------------------------------------------------------
// Loading overlay - same look/lifecycle as poolresourceschedule/projectschedule:
// created in BOOT, shown at the start of every full (re)load, hidden once that
// cycle's own render is done.
// -------------------------------------------------------
var _loadingOverlay = null;
var _loadingSafetyTimer = null;

function _createResLoadingOverlay(host) {
    if (_loadingOverlay) return;
    var style = document.createElement("style");
    style.textContent = [
        "#rc-loading-overlay {",
        "  position:absolute; inset:0; z-index:100000;",
        "  display:none; align-items:center; justify-content:center;",
        "  background:rgba(255,255,255,0.35);",
        "}",
        "#rc-loading-overlay .rlo-box {",
        "  background:#fff; border:1px solid #d8d8d8; border-radius:6px;",
        "  box-shadow:0 6px 24px rgba(0,0,0,0.25);",
        "  padding:18px 26px; width:170px; text-align:center;",
        "  font:13px/1.4 'Segoe UI', Tahoma, sans-serif;",
        "}",
        "#rc-loading-overlay .rlo-bar {",
        "  height:16px; border:1px solid #2f6fdb; border-radius:2px; overflow:hidden;",
        "  margin-bottom:10px; background:#fff;",
        "}",
        "#rc-loading-overlay .rlo-bar-fill {",
        "  height:100%; width:200%;",
        "  background-image: repeating-linear-gradient(-55deg, #2f6fdb 0 8px, #eaf1fd 8px 16px);",
        "  animation: rlo-slide 0.9s linear infinite;",
        "}",
        "@keyframes rlo-slide { from { transform: translateX(-50%); } to { transform: translateX(0%); } }",
        "#rc-loading-overlay .rlo-title { color:#2f6fdb; font-weight:700; font-size:16px; letter-spacing:1px; }",
        "#rc-loading-overlay .rlo-sub { color:#8a8a8a; margin-top:2px; }"
    ].join("\n");
    document.head.appendChild(style);

    var overlay = document.createElement("div");
    overlay.id = "rc-loading-overlay";
    overlay.innerHTML =
        '<div class="rlo-box">' +
            '<div class="rlo-bar"><div class="rlo-bar-fill"></div></div>' +
            '<div class="rlo-title">LOADING</div>' +
            '<div class="rlo-sub">Please wait...</div>' +
        '</div>';

    if (!host.style.position) host.style.position = "relative";
    host.appendChild(overlay);
    _loadingOverlay = overlay;
}

function _showResLoading() {
    if (!_loadingOverlay) return;
    _loadingOverlay.style.display = "flex";
    if (_loadingSafetyTimer) clearTimeout(_loadingSafetyTimer);
    _loadingSafetyTimer = setTimeout(_hideResLoading, 180000);
}

function _hideResLoading() {
    if (_loadingOverlay) _loadingOverlay.style.display = "none";
    if (_loadingSafetyTimer) { clearTimeout(_loadingSafetyTimer); _loadingSafetyTimer = null; }
}

// ============================================================
// BOOT - called by startupScript.js
// ============================================================
window.BOOT = function () {
    try {
        var style = document.createElement("style");
        style.textContent = `
        /* Hide built-in tabs/nav - same as sibling add-ins */
        #scheduler_here.dhx-hide-default-tabs .dhx_cal_tab { display: none !important; }
        #scheduler_here .dhx_cal_navline { display: none !important; }

        /* Tree row coloring: Skill (folder) rows vs Resource (leaf) rows */
        .timeline-skill-row { background-color: #E9E9E9 !important; }
        .timeline-skill-row .dhx_matrix_cell { background-color: #E9E9E9 !important; }
        .dhx_matrix_scell.folder.skill-category,
        .dhx_matrix_scell.folder.skill-category .dhx_scell_level0,
        .dhx_matrix_scell.folder.skill-category .dhx_scell_level1,
        .dhx_matrix_scell.folder.skill-category .dhx_scell_name {
            background-color: #E9E9E9 !important;
            color: black !important;
            font-weight: 600 !important;
            text-transform: none !important;
        }
        .timeline-resource-row { background-color: white !important; }
        .timeline-resource-row .dhx_matrix_cell { background-color: white !important; }
        .dhx_matrix_scell.resource-category,
        .dhx_matrix_scell.resource-category .dhx_scell_name {
            padding-left: 15px !important;
            background-color: white !important;
            color: black !important;
            font-weight: normal !important;
        }

        /* ── Capacity bars: matches Daily/Weekly's Capacity color default (CapacityColorTok in AL
           codeunit 50609 "Visual Default Settings", resolved via GetCapacitySegmentColors and
           always sent as colors.capacity by ControlReady) - see --cap-color-border below for the
           still-distinct border accent. --cap-color-border (#C97F16) is overridable via "Daily
           Optimizer Setup"."Capacity Border Color" (codeunit 50609's GetCapacityBorderColor),
           sent as colors.capacityBorder by ControlReady - this CSS value is only the fallback for
           when that field is blank/the setup singleton doesn't exist yet ── */
        #scheduler_here { --cap-color: #2E75B6; --cap-color-border: #C97F16; --bar-font-color: #000000; }
        .dhx_cal_event.event-capacity,
        .dhx_cal_event_line.event-capacity,
        .dhx_event_line.event-capacity {
            background: var(--cap-color) !important;
            border: 1px solid var(--cap-color-border) !important;
            color: var(--bar-font-color) !important;
            font-size: 12px !important;
        }

        /* ── Day Planning bars: dark envelope + Assigned (light blue) / Requested (green)
           proportional sub-segments - directly adapted from projectschedule's technique ── */
        #scheduler_here {
            --dp-color-envelope: #1B3A6B;
            --dp-color-envelope-border: #14294D;
            --dp-color-assigned: #548235; /* source of truth: AL codeunit 50609 "Color Constants Opti." AssColorTok */
            --dp-color-requested: #6FCF97; /* unrelated to codeunit 50609's skill palette - see ev.requested_color below */
            --dp-height-assigned: 50%;
            --dp-height-requested: 50%;
        }
        .dhx_cal_event.event-DayPlanning,
        .dhx_cal_event_line.event-DayPlanning,
        .dhx_event_line.event-DayPlanning {
            background: var(--dp-color-envelope) !important;
            border: 1px solid var(--dp-color-envelope-border) !important;
            font-size: 12px !important;
            padding: 0 !important;
        }
        .dp-bar-wrap { position: relative; width: 100%; height: 100%; overflow: hidden; }
        .dp-bar-assigned { position: absolute; top: 0; height: var(--dp-height-assigned); background: var(--dp-color-assigned) !important; }
        .dp-bar-requested { position: absolute; bottom: 0; height: var(--dp-height-requested); background: var(--dp-color-requested) !important; }
        .dp-bar-label {
            position: absolute; inset: 0; display: flex; align-items: center; justify-content: flex-start;
            color: var(--bar-font-color); font-size: 11px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis;
            pointer-events: none; text-shadow: 0 0 2px rgba(0,0,0,0.7); z-index: 2;
            padding-left: 4px; text-align: left; min-width: 0;
        }

        /* ── Right-click context menu (same mechanism as pool/project) ── */
        #dhx-ctx-menu {
            position: fixed; z-index: 99999; background: #fff; border: 1px solid #c8c8c8;
            border-radius: 4px; box-shadow: 0 4px 12px rgba(0,0,0,0.18); padding: 4px 0;
            min-width: 190px; font-family: "Segoe UI", sans-serif; font-size: 13px; user-select: none;
        }
        #dhx-ctx-menu.hidden { display: none; }
        .dhx-ctx-item { display: flex; align-items: center; gap: 8px; padding: 7px 14px; cursor: pointer; color: #333; white-space: nowrap; }
        .dhx-ctx-item:hover { background: #f0f4ff; color: #1a56db; }
        .dhx-ctx-item.ctx-cancel { color: #c00; }
        .dhx-ctx-item.ctx-cancel:hover { background: #fff0f0; }
        .dhx-ctx-separator { height: 1px; background: #e0e0e0; margin: 4px 0; }
        .dhx-ctx-icon { width: 16px; height: 16px; display: inline-flex; align-items: center; justify-content: center; flex-shrink: 0; }

        /* ── Filter toolbar (top-left) + Collapse-all icon - exact positioning convention
           established this session: collapse-all at left:6px, filter toolbar at left:34px ── */
        #scheduler_here { position: relative; }
        #res-filter-toolbar { position: absolute; top: 6px; left: 34px; z-index: 70; display: flex; align-items: center; gap: 4px; }
        #res-collapseall-icon {
            position: absolute; top: 6px; left: 6px; z-index: 71;
            display: inline-flex; align-items: center; justify-content: center;
            width: 22px; height: 22px; padding: 0; border: none; border-radius: 50%;
            background: #5f6368; cursor: pointer;
        }
        #res-collapseall-icon:hover { background: #2f8bfb; }
        #res-collapseall-icon:active { background: #1f6fe0; }
        #res-filter-tooltip-popup {
            display: none; position: fixed; background: #ffffff; color: #23272A;
            border: 1px solid #4a6fa5; border-radius: 5px; padding: 8px 12px; font-size: 12px;
            font-weight: normal; white-space: nowrap; z-index: 999999;
            box-shadow: 0 3px 10px rgba(0,0,0,0.25); min-width: 180px; pointer-events: none;
        }

        /* ── Hover tooltip (dhtmlXTooltip) - black/white, tabular ── */
        .dhtmlXTooltip.tooltip { background: #000000 !important; color: #ffffff !important; border: none !important; }
        .dhx-tt { min-width: 220px; font-family: inherit; font-size: 12px; line-height: 1.5; color: #f0f0f0; }
        .dhx-tt-res { font-weight: 700; font-size: 13px; margin-bottom: 1px; color: #ffffff; }
        .dhx-tt-date { color: #aaaaaa; font-size: 11px; margin-bottom: 6px; white-space: nowrap; }
        .dhx-tt-table { display: grid; grid-template-columns: 110px 1fr 1fr; gap: 2px 10px; margin-top: 4px; }
        .dhx-tt-th { font-weight: 700; color: #ffffff; border-bottom: 1px solid #444; padding-bottom: 2px; }
        .dhx-tt-label { color: #cfcfcf; font-weight: 700; padding: 1px 0; }
        .dhx-tt-val { font-weight: 400; color: #ffffff; padding: 1px 0; }
        `;
        document.head.appendChild(style);

        var div = document.getElementById("controlAddIn");
        div.style.width = "100%";
        div.style.height = "100%";
        div.style.margin = "0";
        div.style.padding = "0";
        div.style.background = "lightgrey";

        _createResLoadingOverlay(div);
        _showResLoading();

        var scheduler_element = document.createElement("div");
        scheduler_element.id = "scheduler_here";
        scheduler_element.name = "scheduler_here";
        scheduler_element.style.width = "100%";
        scheduler_element.style.height = "100%";
        div.appendChild(scheduler_element);
        scheduler_element.classList.add("dhx-hide-default-tabs");
        scheduler_here = scheduler_element;

        if (typeof scheduler === "undefined") {
            console.error("DHX scheduler library (dhtmlxscheduler.js) not found.");
            return;
        }

        scheduler.plugins({ timeline: true, treetimeline: true, tooltip: true });

        // DHTMLX does NOT automatically turn the JSON "classname" field into a CSS class on
        // the rendered bar - it must be returned from scheduler.templates.event_class (same
        // requirement in poolresourceschedule/projectschedule/resourceschedule's own
        // wrapper.js). Without this, the event-capacity/event-DayPlanning color rules above
        // never actually apply and bars fall back to DHTMLX's default blue.
        scheduler.templates.event_class = function (start, end, ev) {
            return ev.classname || "";
        };

        scheduler.config.preserve_scale_length = true;
        scheduler.config.drag_create = false;
        scheduler.config.details_on_dblclick = false;
        scheduler.config.start_on_monday = true;
        scheduler.date.timeline_start = function (date) { return scheduler.date.week_start(date); };

        // Compacts (not just hides) hour columns outside [timelineStartHour, timelineEndHour)
        // on the "timeline" view - reads the live module-level vars, so it stays correct
        // across RecreateTimelineView calls without needing to be redefined.
        scheduler.ignore_timeline = function (date) {
            var h = date.getHours();
            return (h < timelineStartHour) || (h >= timelineEndHour);
        };

        // Progress-split segment renderer for Day Planning bars (adapted verbatim from
        // projectschedule's wrapper.js event_bar_text/segmentHtml). Capacity bars just get
        // the plain escaped label (default look, distinct orange background from CSS above).
        scheduler.templates.event_bar_text = function (start, end, ev) {
            var label = escapeRcHtml(ev.text);
            if (ev.type !== "DayPlanning") return label;

            var totalMin = (end - start) / 60000;
            if (!(totalMin > 0)) {
                return '<div class="dp-bar-wrap"><div class="dp-bar-label">' + label + '</div></div>';
            }
            var envStartMin = start.getHours() * 60 + start.getMinutes();

            var assignedStartMin = parseRcHHmm(ev.start_time_assigned);
            var assignedEndMin = parseRcHHmm(ev.end_time_assigned);
            var assignedValid = (assignedStartMin !== null) && (assignedEndMin !== null);

            var requestedStartMin = parseRcHHmm(ev.start_time_requested);
            var requestedEndMin = parseRcHHmm(ev.end_time_requested);
            var requestedValid = (requestedStartMin !== null) && (requestedEndMin !== null);

            var sameRange = assignedValid && requestedValid &&
                (assignedStartMin === requestedStartMin) && (assignedEndMin === requestedEndMin);

            // colorOverride: an event's own resolved per-skill color (ev.requested_color, set by
            // AL's ResolveRequestedColor - see codeunit "DHX Data Handler") applied as an inline
            // !important style so it wins over the CSS "--dp-color-requested" rule (itself
            // !important - see .dp-bar-requested above), which stays in place as the fallback
            // for a blank/unresolved color (no Skill Code on the row).
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

            return '<div class="dp-bar-wrap">' + segmentsHtml + '<div class="dp-bar-label">' + label + '</div></div>';
        };

        // Hover tooltip - branches by bar type (adapted from projectschedule's side-by-side
        // Assigned/Requested table for DayPlanning; a simple resource/date/hours block for
        // Capacity, matching poolresourceschedule's capacity tooltip content).
        scheduler.templates.tooltip_text = function (start, end, ev) {
            var formatDateOnly = scheduler.date.date_to_str("%d-%m-%Y");
            var formatTimeOnly = scheduler.date.date_to_str("%H:%i");
            if (ev.type === "capacity") {
                var html = '<div class="dhx-tt">';
                html += '<div class="dhx-tt-table" style="grid-template-columns:110px 1fr;">';
                html += '<div class="dhx-tt-label">Capacity</div><div class="dhx-tt-val">' + escapeRcHtml(ev.resource_id || "") + '</div>';
                html += '<div class="dhx-tt-label">Date</div><div class="dhx-tt-val">' + formatDateOnly(start) + '</div>';
                html += '<div class="dhx-tt-label">Capacity (h)</div><div class="dhx-tt-val">' + (ev.hours != null ? ev.hours : '') + '</div>';
                html += '<div class="dhx-tt-label">Start Time</div><div class="dhx-tt-val">' + formatTimeOnly(start) + '</div>';
                html += '<div class="dhx-tt-label">End Time</div><div class="dhx-tt-val">' + formatTimeOnly(end) + '</div>';
                html += '</div></div>';
                return html;
            }

            var html = '<div class="dhx-tt">';
            html += '<div class="dhx-tt-res">Day Planning: ' + escapeRcHtml(ev.text || "") + '</div>';
            html += '<div class="dhx-tt-table" style="grid-template-columns:110px 1fr;">';
            html += '<div class="dhx-tt-label">Date</div><div class="dhx-tt-val">' + formatDateOnly(start) + '</div>';
            html += '<div class="dhx-tt-label">Job</div><div class="dhx-tt-val">' + escapeRcHtml(ev.job_no || "") + '</div>';
            html += '<div class="dhx-tt-label">Task</div><div class="dhx-tt-val">' + escapeRcHtml(ev.job_task_no || "") + '</div>';
            html += '</div>';
            html += '<div class="dhx-tt-table" style="margin-top:6px;">';
            html += '<div class="dhx-tt-th"></div><div class="dhx-tt-th">Assigned</div><div class="dhx-tt-th">Requested</div>';
            html += '<div class="dhx-tt-label">Resource No.</div><div class="dhx-tt-val">' + escapeRcHtml(ev.assigned_resource_no || "") + '</div><div class="dhx-tt-val">' + escapeRcHtml(ev.requested_resource_no || "") + '</div>';
            html += '<div class="dhx-tt-label">Resource Name</div><div class="dhx-tt-val">' + escapeRcHtml(ev.assigned_resource_name || "") + '</div><div class="dhx-tt-val">' + escapeRcHtml(ev.requested_resource_name || "") + '</div>';
            html += '<div class="dhx-tt-label">Start Time</div><div class="dhx-tt-val">' + (ev.start_time_assigned || "") + '</div><div class="dhx-tt-val">' + (ev.start_time_requested || "") + '</div>';
            html += '<div class="dhx-tt-label">End Time</div><div class="dhx-tt-val">' + (ev.end_time_assigned || "") + '</div><div class="dhx-tt-val">' + (ev.end_time_requested || "") + '</div>';
            html += '<div class="dhx-tt-label">Hours</div><div class="dhx-tt-val">' + (ev.assigned_hours != null ? ev.assigned_hours : "") + '</div><div class="dhx-tt-val">' + (ev.requested_hours != null ? ev.requested_hours : "") + '</div>';
            html += '</div></div>';
            return html;
        };

        // Double-click an event bar -> AL opens the underlying Day Planning / Capacity record.
        scheduler.attachEvent("onDblClick", function (id, e) {
            var eventdata = scheduler.getEvent(id);
            if (!eventdata) return false;
            var eventData = {
                id: id,
                text: eventdata.text,
                start_date: eventdata.start_date,
                end_date: eventdata.end_date,
                section_id: eventdata.section_id,
                type: eventdata.type || ''
            };
            Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("OnEventDblClick", [id, JSON.stringify(eventData)]);
            return false;
        });

        // Double-click a tree row label -> AL opens the Resource Card (Skill rows no-op, see
        // page trigger OnSectionDblClick). Same DOM-detection technique as pool/project.
        (function wireSectionDblClick() {
            var root = document.getElementById("scheduler_here");
            if (!root) return;
            root.addEventListener("dblclick", function (e) {
                var sectionCell = e.target.closest(".dhx_matrix_scell");
                var sectionRow = e.target.closest(".dhx_timeline_label_row");
                if (sectionCell && sectionRow) {
                    var sectionId = sectionRow.getAttribute("data-row-id") || "";
                    var label = sectionCell.textContent.trim();
                    var viewdate = scheduler.getState().date;
                    Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("OnSectionDblClick", [sectionId, label, String(viewdate)]);
                    e.stopPropagation();
                    e.preventDefault();
                }
            });
        })();

        // Prev/Next navigation arrows -> AL reloads for the new week.
        (function wireTimelineArrows() {
            function notify() {
                var st = scheduler.getState();
                var payload = { mode: st.mode, start: new Date(st.min_date).toISOString(), end: new Date(st.max_date).toISOString() };
                Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("OnTimelineNavigate", [JSON.stringify(payload)]);
            }
            var root = document.getElementById("scheduler_here");
            if (root && !root._navWired) {
                root._navWired = true;
                root.addEventListener("click", function (e) {
                    if (e.target.closest(".dhx_cal_prev_button") || e.target.closest(".dhx_cal_next_button")) {
                        setTimeout(notify, 0);
                    }
                });
            }
        })();

        Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("ControlReady", []);
    } catch (e) {
        console.warn("BOOT warning:", e);
    }
};

function escapeRcHtml(s) {
    if (s === undefined || s === null) return "";
    return String(s).replace(/[&<>"]/g, function (c) {
        return { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" }[c];
    });
}

function parseRcHHmm(txt) {
    if (!txt) return null;
    var parts = String(txt).split(":");
    if (parts.length < 2) return null;
    var h = parseInt(parts[0], 10), m = parseInt(parts[1], 10);
    if (isNaN(h) || isNaN(m)) return null;
    return h * 60 + m;
}

function ParseRcJsonTxt(txt) {
    if (!txt) return null;
    if (typeof txt === "object") return txt;
    try { return JSON.parse(txt); } catch (e) { return null; }
}

function RcArrayFrom(parsed) {
    if (!parsed) return [];
    if (Array.isArray(parsed.data)) return parsed.data;
    if (Array.isArray(parsed)) return parsed;
    return [];
}

// Returns a copy of dateObj with the time set to timelineStartHour:00:00, so the
// visible window starts exactly there every day (when timelineHourStep evenly divides
// the window).
function applyTimelineStartHour(dateObj) {
    var d = new Date(dateObj);
    d.setHours(timelineStartHour, 0, 0, 0);
    return d;
}

// ============================================================
// Tree timeline (Skill > Resource) - same shape/config as poolresourceschedule's
// RecreateTimelineView, adapted category names (Skill/Resource instead of
// Group/Pool/Vendor/Resource).
// ============================================================
function RecreateTimelineView(sections) {
    if (scheduler.matrix && scheduler.matrix.timeline) {
        if (typeof scheduler.deleteView === "function") scheduler.deleteView("timeline");
        delete scheduler.matrix.timeline;
    }
    var windowHours = Math.max(1, timelineEndHour - timelineStartHour);
    var columnsPerDay = Math.ceil(windowHours / timelineHourStep);
    var visibleColumns = Math.max(1, columnsPerDay * 7);

    scheduler.createTimelineView({
        name: "timeline",
        x_unit: "hour",
        x_date: "%H",
        x_step: timelineHourStep,
        x_size: visibleColumns,
        x_length: visibleColumns,
        dy: 20,
        event_dy: 20,
        folder_dy: 20,
        section_autoheight: false,
        resize_events: true,
        y_unit: sections,
        y_property: "section_id",
        render: "tree",
        scale_height: 40,
        second_scale: { x_unit: "day", x_date: "%D %d %M" }
    });

    scheduler.templates.timeline_row_class = function (section) {
        if (section.category === 'Skill') return "timeline-skill-row";
        if (section.category === 'Resource') return "timeline-resource-row";
        return "";
    };
    scheduler.templates.timeline_scaley_class = function (key, label, section) {
        if (section && section.category === 'Skill') return "skill-category";
        if (section && section.category === 'Resource') return "resource-category";
        return "";
    };
}

// ============================================================
// Hide/Show no event resources - purely client-side tree pruning, no AL round trip.
// "Has events" always checks the FULL underlying dataset (allDayPlanningEvents +
// allCapacityEvents), independent of the separate showDayPlanning/showCapacity bar
// visibility toggles - a resource with only Capacity events stays visible even while
// Day Planning bars are hidden, and vice versa, matching the requirement literally
// ("do not have any events (Capacity or Day Planning)").
// ============================================================

// Returns a pruned copy of the Skill>Resource tree containing only Resource leaves
// that have >=1 event, and only Skill folders that still have >=1 remaining child -
// same "omit empty parent" convention SkillResScheduler_BuildTreeJson already uses
// AL-side. Nodes without a children array (e.g. the "No Data" placeholder) pass
// through unfiltered - they are not Skill folders.
function _applyNoEventResourceFilter(sections) {
    if (!hideNoEventResources || !sections) return sections;

    var resourcesWithEvents = {};
    allDayPlanningEvents.forEach(function (ev) { if (ev.section_id) resourcesWithEvents[ev.section_id] = true; });
    allCapacityEvents.forEach(function (ev) { if (ev.section_id) resourcesWithEvents[ev.section_id] = true; });

    var filtered = [];
    for (var i = 0; i < sections.length; i++) {
        var node = sections[i];
        if (!node.children) {
            filtered.push(node);
            continue;
        }
        var keptChildren = node.children.filter(function (child) {
            return !!resourcesWithEvents[child.key];
        });
        if (keptChildren.length > 0) {
            var clonedSkill = {};
            for (var k in node) {
                if (Object.prototype.hasOwnProperty.call(node, k)) clonedSkill[k] = node[k];
            }
            clonedSkill.children = keptChildren;
            filtered.push(clonedSkill);
        }
    }
    return filtered;
}

// The tree sections to actually render right now: _rawTreeSections with the no-event
// filter applied (if active), falling back to the "No Data" placeholder if filtering
// removes everything.
function _currentTreeSections() {
    var result = _applyNoEventResourceFilter(_rawTreeSections);
    if (!result || result.length === 0) result = [{ key: "nodata", label: "No Data" }];
    return result;
}

// Rebuilds the tree view in place - no AL round trip, nothing about the underlying
// data changed, only which rows are shown - preserving the currently active view
// date. Same recreate-view-then-reparse-events sequence RefreshTimeline uses for a
// full reload (RecreateTimelineView before RefreshEvents before setCurrentView).
function _rebuildTreeInPlace() {
    if (typeof scheduler === "undefined" || !scheduler.matrix || !scheduler.matrix.timeline) return;
    var viewDate = scheduler.getState().date;
    RecreateTimelineView(_currentTreeSections());
    RefreshEvents();
    scheduler.setCurrentView(viewDate, "timeline");
}

// ============================================================
// AL-callable: SetHideNoEventResources - instant client-side toggle
// ============================================================
function SetHideNoEventResources(pHide) {
    hideNoEventResources = !!pHide;
    _rebuildTreeInPlace();
}

// ============================================================
// AL-callable: Init(elementsJson, EarliestPlanningDate)
// ============================================================
function Init(elementsJson, EarliestPlanningDate) {
    _showResLoading();
    var parsed = ParseRcJsonTxt(elementsJson);
    var sections = RcArrayFrom(parsed);
    if (sections.length === 0) sections = [{ key: "nodata", label: "No Data" }];

    // hideNoEventResources is always false this early (LoadCapacity/LoadData haven't run
    // yet, so there is no event data to filter against) - _currentTreeSections() is a
    // no-op here, but going through it keeps this the single code path that ever builds
    // the tree, so a stray SetHideNoEventResources(true) call before Init can't leave
    // _rawTreeSections/the rendered tree out of sync.
    _rawTreeSections = sections;
    RecreateTimelineView(_currentTreeSections());
    scheduler.init('scheduler_here', applyTimelineStartHour(EarliestPlanningDate), "timeline");

    setupCollapseAllToggle();
    setupFilterToolbar();
    setupContextMenu();

    Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("OnAfterInit", []);
}

// ============================================================
// AL-callable: LoadData(eventsJson) - Day Planning events
// ============================================================
function LoadData(eventsJson) {
    try {
        allDayPlanningEvents = RcArrayFrom(ParseRcJsonTxt(eventsJson));
        RefreshEvents();
    } catch (e) {
        console.error("LoadData error:", e);
    } finally {
        // True last step of the initial load cycle (ControlReady -> Init -> LoadCapacity -> LoadData).
        _hideResLoading();
    }
}

// ============================================================
// AL-callable: LoadCapacity(capacityJson) - Capacity events
// ============================================================
function LoadCapacity(capacityJson) {
    try {
        allCapacityEvents = RcArrayFrom(ParseRcJsonTxt(capacityJson));
        RefreshEvents();
    } catch (e) {
        console.error("LoadCapacity error:", e);
    }
}

// Merge the two channels client-side, respecting the Show/Hide toggles, then repaint.
function RefreshEvents() {
    if (typeof scheduler === "undefined") return;
    scheduler.clearAll();
    var merged = [];
    if (showDayPlanning) merged = merged.concat(allDayPlanningEvents);
    if (showCapacity) merged = merged.concat(allCapacityEvents);
    if (merged.length > 0) scheduler.parse(merged);
}

// ============================================================
// AL-callable: SetBarColors - apply setup-driven Day Planning bar colors/split
// ============================================================
function SetBarColors(colorsJson) {
    try {
        var colors = ParseRcJsonTxt(colorsJson) || {};
        var root = document.getElementById("scheduler_here");
        if (!root) return;
        if (colors.envelope) root.style.setProperty("--dp-color-envelope", colors.envelope);
        root.style.setProperty("--dp-color-envelope-border", colors.envelopeBorder || "transparent");
        if (colors.assigned) root.style.setProperty("--dp-color-assigned", colors.assigned);
        if (colors.requested) root.style.setProperty("--dp-color-requested", colors.requested);
        if (colors.capacity) root.style.setProperty("--cap-color", colors.capacity);
        // "capacityBorder" is sent by page 50706's ControlReady (via codeunit 50609's
        // GetCapacityBorderColor, "Daily Optimizer Setup"."Capacity Border Color"). Guarded like
        // every other optional key here so a blank/absent value keeps the CSS "--cap-color-border"
        // default (#C97F16, set in BOOT's injected stylesheet above) instead of unconditionally
        // clobbering it to "transparent".
        if (colors.capacityBorder) root.style.setProperty("--cap-color-border", colors.capacityBorder);
        // Assigned/Requested split - from Resource Scheduler Setup's "Assigned High (%)"/
        // "Requested High (%)". Left at their CSS default (50%/50%) whenever setup doesn't
        // override them (0/blank).
        if (colors.assignedHeight) root.style.setProperty("--dp-height-assigned", colors.assignedHeight + "%");
        if (colors.requestedHeight) root.style.setProperty("--dp-height-requested", colors.requestedHeight + "%");
        // "fontColor" is sent by page 50706's ControlReady (via codeunit 50609's
        // GetBarFontColor, "Daily Optimizer Setup"."Bar Font Color") - applies uniformly to every
        // bar's on-bar label text (Day Planning's .dp-bar-label AND the Capacity event's own
        // color rule above, which previously had its own distinct hardcoded "#3a2600"). Does NOT
        // affect hover/tooltip text - that stays on its own separate hardcoded colors.
        if (colors.fontColor) root.style.setProperty("--bar-font-color", colors.fontColor);
    } catch (e) {
        console.warn("SetBarColors: invalid colorsJson", colorsJson, e);
    }
}

// Called from AL (setup-driven) to override the hour interval shown on the timeline
// scale (default 3h). Must be called (if at all) BEFORE Init(), since
// RecreateTimelineView() reads this at build time.
function SetTimelineHourStep(hourStep) {
    var step = parseInt(hourStep, 10);
    timelineHourStep = (step > 0) ? step : 3;
}

// Called from AL (setup-driven) to restrict the timeline to a daily window, e.g.
// 07:00-19:00, instead of the full 24h day. Works together with scheduler.ignore_timeline
// above. Must be called (if at all) BEFORE Init(), same ordering requirement as
// SetTimelineHourStep. Invalid/out-of-range input is ignored and the full-day default
// (0-24) is kept.
function SetTimelineHourRange(startHour, endHour) {
    var s = parseInt(startHour, 10);
    var e = parseInt(endHour, 10);
    if (isNaN(s) || isNaN(e) || s < 0 || e > 24 || s >= e) return;
    timelineStartHour = s;
    timelineEndHour = e;
}

// ============================================================
// AL-callable: SetShowDayPlanning / SetShowCapacity - instant client-side toggle
// ============================================================
function SetShowDayPlanning(pShow) {
    showDayPlanning = !!pShow;
    RefreshEvents();
}
function SetShowCapacity(pShow) {
    showCapacity = !!pShow;
    RefreshEvents();
}

// ============================================================
// AL-callable: RefreshTimeline(resourcesJson, eventsJson, capacityJson, dateAnchor)
// Full reload cycle (tree + both event channels + view date) - used by Prev/Next/
// Today/Refresh/filter-applied on the AL side.
// ============================================================
function RefreshTimeline(resourcesJson, eventsJson, capacityJson, dateAnchor) {
    _showResLoading();
    try {
        var sections = RcArrayFrom(ParseRcJsonTxt(resourcesJson));
        var onlyNoData = false;
        if (sections.length === 0) { sections = [{ key: "nodata", label: "No Data" }]; onlyNoData = true; }

        // Event arrays updated BEFORE the tree is built, so _currentTreeSections()'s
        // no-event filter (if active) reflects this week's fresh data, not the previous
        // week's - hideNoEventResources can stay on across Prev/Next/Today/Refresh.
        allDayPlanningEvents = onlyNoData ? [] : RcArrayFrom(ParseRcJsonTxt(eventsJson));
        allCapacityEvents = onlyNoData ? [] : RcArrayFrom(ParseRcJsonTxt(capacityJson));

        _rawTreeSections = sections;
        RecreateTimelineView(_currentTreeSections());
        RefreshEvents();

        var anchor = null;
        if (dateAnchor) {
            if (dateAnchor instanceof Date) anchor = dateAnchor;
            else if (typeof dateAnchor === "number") anchor = new Date(dateAnchor);
            else if (typeof dateAnchor === "string") { var d = new Date(dateAnchor); if (!isNaN(d)) anchor = d; }
        }
        var viewDate = anchor ? scheduler.date.week_start(anchor) : scheduler.getState().date;
        viewDate = applyTimelineStartHour(viewDate);
        scheduler.setCurrentView(viewDate, "timeline");
    } catch (e) {
        console.error("RefreshTimeline failed:", e);
    } finally {
        _hideResLoading();
    }
}

// ═══════════════════════════════════════════════════════════════
// Collapse/Expand All (folder rows of the tree timeline)
// ═══════════════════════════════════════════════════════════════
function setupCollapseAllToggle() {
    var root = document.getElementById('scheduler_here');
    if (!root || root._collapseAllWired) return;
    root._collapseAllWired = true;

    var btn = document.createElement('button');
    btn.id = 'res-collapseall-icon';
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

    var btn = document.getElementById('res-collapseall-icon');
    if (btn) _renderCollapseAllIcon(btn);
}

// ═══════════════════════════════════════════════════════════════
// Resource/Skill filter toolbar (top-left of the timeline grid)
// ═══════════════════════════════════════════════════════════════
function setupFilterToolbar() {
    var root = document.getElementById('scheduler_here');
    if (!root || root._filterToolbarWired) return;
    root._filterToolbarWired = true;

    var toolbar = document.createElement('div');
    toolbar.id = 'res-filter-toolbar';
    root.appendChild(toolbar);

    _updateResFilterToolbar();
}

function _positionResFilterTooltip(e) {
    var popup = document.getElementById('res-filter-tooltip-popup');
    if (!popup) return;
    var left = e.clientX + 12;
    var top = e.clientY + 12;
    var popupW = popup.offsetWidth || 200;
    var popupH = popup.offsetHeight || 60;
    if (left + popupW > window.innerWidth) left = e.clientX - popupW - 12;
    if (top + popupH > window.innerHeight) top = e.clientY - popupH - 12;
    popup.style.left = left + 'px';
    popup.style.top = top + 'px';
}

function _updateResFilterToolbar() {
    var toolbar = document.getElementById('res-filter-toolbar');
    if (!toolbar) return;
    toolbar.innerHTML = '';

    var popup = document.getElementById('res-filter-tooltip-popup');
    if (!popup) {
        popup = document.createElement('div');
        popup.id = 'res-filter-tooltip-popup';
        document.body.appendChild(popup);
    }

    var fi = _resFilterInfo;
    popup.innerHTML = '';
    var titleEl = document.createElement('b');
    titleEl.textContent = fi ? 'Filter applied:' : 'Click to filter by Resource/Skill';
    popup.appendChild(titleEl);
    if (fi) {
        if (fi.resNo || fi.resName) {
            popup.appendChild(document.createElement('br'));
            popup.appendChild(document.createTextNode('Resource = ' + (fi.resNo || '(any)') + (fi.resName ? (' - ' + fi.resName) : '')));
        }
        if (fi.skillFilter) {
            popup.appendChild(document.createElement('br'));
            popup.appendChild(document.createTextNode('Skill = ' + fi.skillFilter));
        }
        if (fi.periodFrom || fi.periodTo) {
            popup.appendChild(document.createElement('br'));
            popup.appendChild(document.createTextNode('Period: ' + (fi.periodFrom || '') + ' to ' + (fi.periodTo || '')));
        }
    }

    var filterBtn = document.createElement('button');
    filterBtn.className = 'res-filter-icon';
    filterBtn.innerHTML =
        '<svg viewBox="0 0 24 24" width="13" height="13" style="vertical-align:middle;">' +
            '<path d="M3 4h18l-7.2 8.6v6.4l-3.6 1.8v-8.2z" fill="#fff"/>' +
        '</svg>';
    filterBtn.style.cssText = 'background:' + (fi ? '#1a73e8' : '#5f6368') +
        ';border:none;border-radius:50%;width:22px;height:22px;line-height:22px;' +
        'text-align:center;padding:0;cursor:pointer;vertical-align:middle;display:inline-block;';

    filterBtn.addEventListener('mouseenter', function (e) { popup.style.display = 'block'; _positionResFilterTooltip(e); });
    filterBtn.addEventListener('mousemove', function (e) { _positionResFilterTooltip(e); });
    filterBtn.addEventListener('mouseleave', function () { popup.style.display = 'none'; });
    filterBtn.addEventListener('click', function (e) {
        e.stopPropagation();
        popup.style.display = 'none';
        Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('OnFilterIconClick', []);
    });
    toolbar.appendChild(filterBtn);

    if (fi) {
        var resetBtn = document.createElement('button');
        resetBtn.className = 'res-filter-reset';
        resetBtn.title = 'Click to Reset Filter';
        resetBtn.textContent = '✕';
        resetBtn.style.cssText = 'background:#c0392b;border:none;border-radius:50%;width:22px;height:22px;' +
            'line-height:22px;text-align:center;padding:0;cursor:pointer;font-size:13px;font-weight:700;' +
            'color:#fff;vertical-align:middle;display:inline-block;';
        resetBtn.addEventListener('click', function (e) {
            e.stopPropagation();
            popup.style.display = 'none';
            Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('OnClearResourceFilter', []);
        });
        toolbar.appendChild(resetBtn);
    }
}

// Called by AL after a filter is applied/cleared or any refresh, to keep the toolbar/tooltip in sync.
function SetResourceFilterInfo(resNo, resName, periodFrom, periodTo, skillFilter) {
    if (!resNo && !resName && !skillFilter) {
        _resFilterInfo = null;
    } else {
        _resFilterInfo = { resNo: resNo || '', resName: resName || '', periodFrom: periodFrom || '', periodTo: periodTo || '', skillFilter: skillFilter || '' };
    }
    _updateResFilterToolbar();
}

// ═══════════════════════════════════════════════════════════════
// Right-click context menu - events and tree row labels
// ═══════════════════════════════════════════════════════════════
function setupContextMenu() {
    var root = document.getElementById('scheduler_here');
    if (!root || root._ctxWired) return;
    root._ctxWired = true;

    var menu = document.getElementById('dhx-ctx-menu');
    if (!menu) {
        menu = document.createElement('div');
        menu.id = 'dhx-ctx-menu';
        menu.className = 'hidden';
        document.body.appendChild(menu);
    }
    menu.innerHTML =
        '<div class="dhx-ctx-item" data-action="OpenDayPlanning">' +
            '<span class="dhx-ctx-icon">&#128197;</span>Open Day Planning</div>' +
        '<div class="dhx-ctx-item" data-action="OpenCapacity">' +
            '<span class="dhx-ctx-icon">&#128202;</span>Open Capacity</div>' +
        '<div class="dhx-ctx-item" data-action="OpenTask">' +
            '<span class="dhx-ctx-icon">&#128203;</span>Open Task</div>' +
        '<div class="dhx-ctx-item" data-action="OpenResource">' +
            '<span class="dhx-ctx-icon">&#128100;</span>Open Resource</div>' +
        '<div class="dhx-ctx-separator"></div>' +
        '<div class="dhx-ctx-item" data-action="OpenResourceCard">' +
            '<span class="dhx-ctx-icon">&#128100;</span>Open Resource Card</div>' +
        '<div class="dhx-ctx-item" data-action="OpenResourceSkills">' +
            '<span class="dhx-ctx-icon">&#127942;</span>Open Resource Skills</div>' +
        '<div class="dhx-ctx-item" data-action="OpenDayPlannings">' +
            '<span class="dhx-ctx-icon">&#128198;</span>Open Day Plannings</div>' +
        '<div class="dhx-ctx-item" data-action="OpenTask">' +
            '<span class="dhx-ctx-icon">&#128203;</span>Open Task</div>' +
        '<div class="dhx-ctx-item" data-action="ShowCapacity">' +
            '<span class="dhx-ctx-icon">&#128202;</span>Show Capacity</div>' +
        '<div class="dhx-ctx-separator"></div>' +
        '<div class="dhx-ctx-item ctx-cancel" data-action="Cancel">' +
            '<span class="dhx-ctx-icon">&#10005;</span>Cancel</div>';

    var _ctxTarget = null; // { type:'event'|'section', id, subtype:'capacity'|'DayPlanning'|'Skill'|'Resource' }

    function showMenu(x, y, target) {
        _ctxTarget = target;
        var isEvent = target.type === 'event';
        var isCapacityEvent = isEvent && target.subtype === 'capacity';
        var isDayPlanningEvent = isEvent && target.subtype !== 'capacity';
        var isSkillSection = !isEvent && target.subtype === 'Skill';
        var isResourceSection = !isEvent && target.subtype === 'Resource';

        // There are TWO menu items with data-action="OpenTask" (one for Day Planning event
        // bars, one for the resource-row section - see setupContextMenu's innerHTML comment).
        // querySelector() only ever returns the first DOM match, so a plain
        // menu.querySelector('[data-action="OpenTask"]') call would collide between the two
        // and leave one of them stuck. querySelectorAll()+index disambiguates by DOM order
        // (event-bar item first, resource-row item second) instead.
        var ctxOpenTaskItems = menu.querySelectorAll('[data-action="OpenTask"]');

        menu.querySelector('[data-action="OpenDayPlanning"]').style.display = isDayPlanningEvent ? '' : 'none';
        menu.querySelector('[data-action="OpenCapacity"]').style.display = isCapacityEvent ? '' : 'none';
        if (ctxOpenTaskItems[0]) ctxOpenTaskItems[0].style.display = isDayPlanningEvent ? '' : 'none';
        menu.querySelector('[data-action="OpenResource"]').style.display = isDayPlanningEvent ? '' : 'none';
        menu.querySelector('[data-action="OpenResourceCard"]').style.display = isResourceSection ? '' : 'none';
        menu.querySelector('[data-action="OpenResourceSkills"]').style.display = isResourceSection ? '' : 'none';
        menu.querySelector('[data-action="OpenDayPlannings"]').style.display = isResourceSection ? '' : 'none';
        if (ctxOpenTaskItems[1]) ctxOpenTaskItems[1].style.display = isResourceSection ? '' : 'none';
        menu.querySelector('[data-action="ShowCapacity"]').style.display = isResourceSection ? '' : 'none';

        if (isSkillSection) { hideMenu(); return; } // no menu items apply to a Skill row

        menu.className = '';
        var menuW = 210, menuH = 200;
        var left = (x + menuW > window.innerWidth) ? window.innerWidth - menuW - 4 : x;
        var top = (y + menuH > window.innerHeight) ? window.innerHeight - menuH - 4 : y;
        menu.style.left = left + 'px';
        menu.style.top = top + 'px';
    }

    function hideMenu() {
        menu.className = 'hidden';
        _ctxTarget = null;
    }

    menu.addEventListener('click', function (e) {
        var item = e.target.closest('.dhx-ctx-item');
        if (!item) return;
        var action = item.getAttribute('data-action');
        if (action && action !== 'Cancel' && _ctxTarget) {
            var payload = JSON.stringify({ action: action, type: _ctxTarget.type, id: _ctxTarget.id });
            if (_ctxTarget.type === 'event') {
                Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('OnEventContextMenu', [_ctxTarget.id, action, payload]);
            } else {
                Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('OnSectionContextMenu', [_ctxTarget.id, action, payload]);
            }
        }
        hideMenu();
        e.stopPropagation();
    });

    document.addEventListener('click', function (e) { if (!menu.contains(e.target)) hideMenu(); });
    document.addEventListener('scroll', hideMenu, true);
    document.addEventListener('keydown', function (e) { if (e.key === 'Escape') hideMenu(); });

    root.addEventListener('contextmenu', function (e) {
        e.preventDefault();
        e.stopPropagation();

        var eventEl = e.target.closest('[event_id]') || e.target.closest('.dhx_cal_event_line') || e.target.closest('.dhx_cal_event');
        if (eventEl) {
            var evId = eventEl.getAttribute('event_id') || eventEl.getAttribute('data-event-id') || '';
            var ev = (evId && scheduler.getEvent) ? scheduler.getEvent(evId) : null;
            showMenu(e.clientX, e.clientY, { type: 'event', id: evId || '', subtype: ev ? ev.type : '' });
            return;
        }

        var sectionRow = e.target.closest('.dhx_timeline_label_row') || e.target.closest('[data-row-id]');
        if (sectionRow) {
            var sectionId = sectionRow.getAttribute('data-row-id') || '';
            var subtype = sectionId.indexOf('SKILL|') === 0 ? 'Skill' : 'Resource';
            showMenu(e.clientX, e.clientY, { type: 'section', id: sectionId, subtype: subtype });
            return;
        }

        hideMenu();
    });
}

// ═══════════════════════════════════════════════════════════════
// Diagnostics (audit) actions - copied verbatim from poolresourceschedule/
// projectschedule's wrapper.js (same mechanism, generic enough to reuse as-is).
// ═══════════════════════════════════════════════════════════════
function get_events_not_match_with_section() {
    var invalidEvents = [];
    var sectionsMap = {};
    if (scheduler.matrix && scheduler.matrix.timeline && Array.isArray(scheduler.matrix.timeline.y_unit)) {
        scheduler.matrix.timeline.y_unit.forEach(function (section) { sectionsMap[section.key] = true; });
    }
    if (scheduler.getEvents) {
        var allEvents = scheduler.getEvents();
        allEvents.forEach(function (event) { if (!sectionsMap[event.section_id]) invalidEvents.push(event); });
    }
    Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('OnEventsNotMatch', [JSON.stringify(invalidEvents)]);
}

function getAllEvents() {
    var allEvents = [];
    if (scheduler.getEvents) allEvents = scheduler.getEvents();
    Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('OnGetAllEvents', [JSON.stringify(allEvents)]);
}

function getAllSections() {
    var allSections = [];
    if (scheduler.matrix && scheduler.matrix.timeline && Array.isArray(scheduler.matrix.timeline.y_unit)) {
        allSections = scheduler.matrix.timeline.y_unit;
    }
    Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('OnGetAllSections', [JSON.stringify(allSections)]);
}
