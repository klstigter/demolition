// ============================================================================
// Day Planning Sequence - control add-in wrapper.
// Ports the visual/UX shape of KLAAS/SequenceGenerator (SequenceGenerator37) onto a DHTMLX
// Scheduler Timeline view embedded as a BC FastTab. Unlike the demo, this add-in holds NO
// client-side data model of its own - BC (via codeunit "Day Planning Sequence Mgt.") is the sole
// source of truth for every Day Planning line and for the Sequence No./thread algorithm. This
// file is presentation + event-raising only:
//   - renders the timeline (one row per (Job No., Job Task No., Skill, Sequence No.) thread),
//   - renders the "New sequence" modal and "Modify sequence" slide-in panel,
//   - raises OnCreateSequence / OnModifySequence / OnEventChanged / OnEventDeleted /
//     OnEventDblClick back to AL, and re-renders whatever AL sends back via Init/LoadData/
//     RefreshTimeline.
// JS/DOM idioms (BOOT, loading overlay, ParseJSonTxt, InvokeExtensibilityMethod calls,
// try/catch/finally around data loads) mirror src/dhx/projectschedule/wrapper.js.
// ============================================================================

var dps_currentTimelineSpanDays = 0;  // days currently applied to the timeline view's x_size; 0 = not yet configured
var dps_showContext = false;       // true only when hosted by standalone page 50712: Project No./Task No. columns + "Filter applied" icon (the card part hides both)
var dps_filterInfo = null;         // {job, task, skill, resource} filter expressions last pushed by AL (SetFilterInfo)
var dps_scheduler_ready = false; // true once scheduler.init() has run
var dps_isRefreshing = false;      // guard: true while a full AL-driven reload is being applied,
                                    // so onEventChanged/onEventDeleted fired by that reload's own
                                    // scheduler.parse()/clearAll() churn don't re-raise events to AL
var dps_sections = [];             // last section list pushed by AL (raw objects incl. extra props)
var dps_sectionsByKey = {};        // key -> section object, for quick lookup (Modify-panel prefill)
var dps_skills = [];               // [{code, description, color}]
var dps_templates = [];            // [{code, description, activeWeekdays: "1|2|3|4|5"}]
var dps_selectedSectionKey = null;
var dps_eventExclusionsDraft = {}; // New sequence dialog: same, for its own exclude-day grid
var dps_holidays = {};              // { "YYYY-MM-DD": "Description" } - Base Calendar day-off/
                                     // public-holiday exceptions, same source + shape as
                                     // src/dhx/ganttdemo2/wrapper.js's _ganttHolidays

var ISO_WEEKDAYS = [["Mon", 1], ["Tue", 2], ["Wed", 3], ["Thu", 4], ["Fri", 5], ["Sat", 6], ["Sun", 7]];

// -------------------------------------------------------
// Loading overlay - see style.css #dps-loading-overlay for the look. Same lifecycle as the other
// add-ins in this app: created once in BOOT, shown at the start of every full reload
// (Init/LoadData for the first cycle, RefreshTimeline for subsequent ones), hidden once that
// cycle's own render is done.
// -------------------------------------------------------
var _dpsLoadingOverlay = null;
var _dpsLoadingSafetyTimer = null;

function _createDpsLoadingOverlay(host) {
    if (_dpsLoadingOverlay) return;
    var overlay = document.createElement("div");
    overlay.id = "dps-loading-overlay";
    overlay.innerHTML =
        '<div class="dps-lo-box">' +
            '<div class="dps-lo-bar"><div class="dps-lo-bar-fill"></div></div>' +
            '<div class="dps-lo-title">LOADING</div>' +
        '</div>';
    host.appendChild(overlay);
    _dpsLoadingOverlay = overlay;
}

function _showDpsLoading() {
    if (!_dpsLoadingOverlay) return;
    _dpsLoadingOverlay.style.display = "flex";
    if (_dpsLoadingSafetyTimer) clearTimeout(_dpsLoadingSafetyTimer);
    _dpsLoadingSafetyTimer = setTimeout(_hideDpsLoading, 180000);
}

function _hideDpsLoading() {
    if (_dpsLoadingOverlay) _dpsLoadingOverlay.style.display = "none";
    if (_dpsLoadingSafetyTimer) { clearTimeout(_dpsLoadingSafetyTimer); _dpsLoadingSafetyTimer = null; }
}

// Defensive JSON parser - tolerant of AL StrSubstNo-built JSON-ish text (same as
// src/dhx/projectschedule/wrapper.js's ParseJSonTxt).
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
        console.log("Day Planning Sequence: invalid JSON", e, jsonText);
        return false;
    }
    return parsed || (Array.isArray(parsed) ? [] : {});
}

function $id(id) { return document.getElementById(id); }

// -------------------------------------------------------
// BOOT - startupScript.js calls this once, builds the DOM, configures the scheduler, then
// announces ControlReady to AL. AL's ControlReady trigger only fires after this returns, so
// Init()/LoadData() (called from that trigger) are always safe to assume scheduler.init() ran.
// -------------------------------------------------------
window.BOOT = function () {
    try {
        var host = document.getElementById("controlAddIn");
        host.style.width = "100%";
        host.style.height = "100%";
        host.style.margin = "0";
        host.style.padding = "0";
        host.style.position = "relative";

        if (!window.scheduler || typeof scheduler.createTimelineView !== "function") {
            var errDiv = document.createElement("div");
            errDiv.className = "dps-error";
            errDiv.textContent = "DHTMLX Scheduler Timeline is not available in this build.";
            host.appendChild(errDiv);
            Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("ControlReady", []);
            return;
        }

        buildDom(host);
        _createDpsLoadingOverlay(host);
        _showDpsLoading();

        configureScheduler();
        attachScaleInteraction();
        wireToolbarAndPanels();

        _hideDpsLoading();

        Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("ControlReady", []);
    } catch (e) {
        console.log("Day Planning Sequence BOOT error:", e);
        Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("ControlReady", []);
    }
};

function buildDom(host) {
    var root = document.createElement("div");
    root.id = "dps-root";
    root.innerHTML =
        '<div id="dps-toolbar">' +
            '<span id="dpsFilterSlot"></span>' +
            '<button type="button" class="dps-btn" id="dpsModifyBtn">Modify sequence</button>' +
            '<button type="button" class="dps-btn dps-primary" id="dpsNewBtn">New sequence</button>' +
        '</div>' +
        '<div id="dps-stage">' +
            '<div id="dps-scheduler-card">' +
                '<style id="dpsSequenceHighlight"></style>' +
                '<div id="dps_scheduler_here" class="dhx_cal_container"></div>' +
            '</div>' +
            '<aside class="dps-sidepanel" id="dpsSequencePanel">' +
                '<div class="dps-panelbody">' +
                    '<div class="dps-sequence-header">' +
                        '<div class="dps-sequence-heading">' +
                            '<div class="dps-paneltitle" id="dpsModifyCaption">Modify Sequence</div>' +
                            '<p id="dpsSelectSequenceHint" hidden>Select a Sequence in the overview above.</p>' +
                            '<fieldset class="dps-range-weekdays" id="dpsRangeWeekdays" hidden><legend>Exclude weekdays</legend>' +
                                ISO_WEEKDAYS.map(function (pair) {
                                    return '<label><input type="checkbox" value="' + pair[1] + '"> ' + pair[0] + '</label>';
                                }).join("") +
                            '</fieldset>' +
                        '</div>' +
                    '<div id="dpsRangeStep">' +
                        '<div class="dps-sequence-options">' +
                            '<div id="dpsOperationGrid" role="group" aria-label="Sequence action">' +
                            '<table aria-label="Add and Delete options">' +
                                '<thead><tr><th scope="col">Action</th><th scope="col" aria-label="Select action"></th></tr></thead>' +
                                '<tbody><tr><th scope="row">Add Time Slots</th>' +
                                    sequenceOperationCell("add", "requested", "Add Time Slots") +
                                '</tr><tr><th scope="row">Delete Time Slots</th>' +
                                    sequenceOperationCell("delete", "requested", "Delete Time Slots") +
                                '</tr></tbody>' +
                            '</table>' +
                            '<table aria-label="Modify options">' +
                                '<thead><tr><th colspan="2" scope="colgroup">Action</th><th scope="col">Requested</th><th scope="col">Assigned</th></tr></thead>' +
                                '<tbody><tr><th rowspan="2" scope="rowgroup">Modify</th><th scope="row">Time Slots</th>' +
                                    sequenceOperationCell("times", "requested", "Modify Requested Time Slots", true) +
                                    sequenceOperationCell("times", "assigned", "Modify Assigned Time Slots") +
                                '</tr><tr><th scope="row">Resource</th>' +
                                    sequenceOperationCell("resource", "requested", "Change Requested Resource") +
                                    sequenceOperationCell("resource", "assigned", "Change Assigned Resource") +
                                '</tr></tbody>' +
                            '</table>' +
                            '</div>' +
                            '<div class="dps-field" id="dpsTemplateField" hidden><label for="dpsSeqTemplate">Work-Hour Template</label><select id="dpsSeqTemplate"></select></div>' +
                            '<div class="dps-field" id="dpsResourceField" hidden><label for="dpsResourceNo">Resource No.</label>' +
                                '<div class="dps-resource-lookup"><input id="dpsResourceNo" type="text" readonly><button id="dpsLookupResource" type="button" class="dps-btn" aria-label="Select Resource">…</button></div>' +
                            '</div>' +
                    '<details id="dpsWeekPatternDetails" hidden>' +
                        '<summary>Week Pattern</summary>' +
                        '<table id="dpsWeekPattern"><thead><tr><th scope="col">Weekday</th><th scope="col">Start Time</th><th scope="col">End Time</th><th scope="col">Idle Time (min)</th></tr></thead><tbody></tbody></table>' +
                    '</details>' +
                            '<p id="dpsRangeHint" aria-live="polite"></p>' +
                        '</div>' +
                    '</div>' +
                    '<button type="button" class="dps-btn" id="dpsClosePanel" aria-label="Close Modify Sequence">&times;</button>' +
                    '</div>' +
                        '<div class="dps-date-selector" id="dpsDateSelector" hidden>' +
                        '<div id="dpsRangeTimeline" class="dps-range-timeline" role="group" aria-label="Time Slot dates"></div>' +
                        '</div>' +
                '</div>' +
                '<div class="dps-panelactions dps-selection-footer">' +
                    '<div id="dpsDateSelection" hidden>' +
                        '<span id="dpsDateCount" aria-live="polite"></span>' +
                        '<button type="button" class="dps-btn" id="dpsClearDates">Reset Selection</button>' +
                        '<span id="dpsSelectionStatus" role="status"></span>' +
                        '<span id="dpsExecuteStatus" class="dps-execute-status" role="status"></span>' +
                    '</div>' +
                    '<button type="button" class="dps-btn" id="dpsCancelPanel">Cancel</button>' +
                    '<button type="button" class="dps-btn dps-primary" id="dpsApplySequence" disabled>Execute</button>' +
                '</div>' +
            '</aside>' +
            '<aside class="dps-sidepanel" id="dpsLinesDialog">' +
                '<div class="dps-panelhead">' +
                    '<div class="dps-paneltitle">New sequence</div>' +
                    '<button type="button" class="dps-btn" id="dpsCloseLinesDialog" aria-label="Close New Sequence">&times;</button>' +
                '</div>' +
                '<div class="dps-panelbody">' +
                    '<div class="dps-field" id="dpsNewProjectField" hidden><label for="dpsNewProject">Project No.</label><div><input id="dpsNewProject" readonly><button type="button" class="dps-btn" id="dpsPickProject" aria-label="Look up Project">…</button></div></div>' +
                    '<div class="dps-field" id="dpsNewTaskField" hidden><label for="dpsNewTask">Task No.</label><div><input id="dpsNewTask" readonly><button type="button" class="dps-btn" id="dpsPickTask" aria-label="Look up Project Task">…</button></div></div>' +
                    '<div class="dps-field"><label>Skill</label><select id="dpsEventSkill"></select></div>' +
                    '<div class="dps-field"><label>Work-Hour Template</label><select id="dpsEventTemplate"></select></div>' +
                    '<div class="dps-field"><label>Exclude days</label><div class="dps-exclude-grid" id="dpsEventExcludeDays"></div></div>' +
                    '<div class="dps-field"><label>Start Date</label><input type="date" lang="en-GB" id="dpsEventStartDate"></div>' +
                    '<div class="dps-field"><label>End Date</label><input type="date" lang="en-GB" id="dpsEventEndDate"></div>' +
                '</div>' +
                '<div class="dps-status" id="dpsCreateStatus"></div>' +
                '<div class="dps-panelactions">' +
                    '<button type="button" class="dps-btn" id="dpsCancelLines">Cancel</button>' +
                    '<button type="button" class="dps-btn dps-primary" id="dpsCreateLines">Create</button>' +
                '</div>' +
            '</aside>' +
        '</div>' +
        '<div class="dps-tooltip" id="dpsTooltip"></div>';
    host.appendChild(root);
}

// -------------------------------------------------------
// Scheduler configuration - Timeline view, 2-hour cells, 06:00-18:00 visible window, weekend
// column highlighting, native lightbox disabled (all editing goes through the custom panels
// above). Geometry mirrors the demo (SequenceGenerator37-app.js: configureScheduler).
// -------------------------------------------------------
function configureScheduler() {
    scheduler.plugins({ timeline: true });

    scheduler.config.drag_create = true;   // drag on a row's empty cells creates one Day Planning line
                                            // for that row's Skill/Sequence No. (onEventAdded below)
    scheduler.config.dblclick_create = false; // creation is drag-only; the default double-click-on-empty-cell
                                               // create would make a bar with a temp id that has no "|" parts
    scheduler.config.drag_move = true;
    scheduler.config.drag_resize = true;
    scheduler.config.details_on_create = false;
    scheduler.config.details_on_dblclick = false;
    scheduler.config.event_duration = 60;
    scheduler.config.auto_end_date = true;
    scheduler.config.start_on_monday = true;

    scheduler.xy.scale_height = 34;
    scheduler.xy.min_event_height = 16;
    scheduler.xy.bar_height = 16;

    scheduler.serverList("sections", []);

    dps_currentTimelineSpanDays = 31;
    scheduler.createTimelineView(buildTimelineViewConfig(dps_currentTimelineSpanDays));
    applyDayScaleWeekTemplate();

    // Keep only the working-time cells 06-18, per spec's compact timeline window.
    scheduler.ignore_timeline = function (date) {
        var hour = date.getHours();
        return hour < 6 || hour >= 18;
    };

    scheduler.templates.event_class = function (start, end, event) {
        return "dps-event dps-skill-" + safeCssToken(event.skill);
    };
    scheduler.templates.event_bar_text = function (start, end, event) {
        return event.text || "";
    };

    scheduler.attachEvent("onEventChanged", function (id, ev) {
        if (dps_isRefreshing) return true;

        var sameDay = ev.start_date.getFullYear() === ev.end_date.getFullYear() &&
            ev.start_date.getMonth() === ev.end_date.getMonth() &&
            ev.start_date.getDate() === ev.end_date.getDate();
        if (!sameDay) {
            alert("Start time and end time must be on the same day.");
            return false;
        }

        var eventData = {
            id: id,
            text: ev.text,
            start_date: ev.start_date,
            end_date: ev.end_date,
            section_id: ev.section_id
        };
        Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("OnEventChanged", [String(id), JSON.stringify(eventData)]);
        return true;
    });

    // At the end of a drag-create this DHTMLX build calls showLightbox (not onEventAdded) for the
    // new bar - same as src/dhx/projectschedule - so onBeforeLightbox is the interception point.
    scheduler.attachEvent("onEventCreated", function (id) {
        var ev = scheduler.getEvent(id);
        if (ev) ev._isNewForLightbox = true;
        return true;
    });

    scheduler.attachEvent("onBeforeLightbox", function (id) {
        var ev = scheduler.getEvent(id);
        if (ev && ev._isNewForLightbox) {
            delete ev._isNewForLightbox;
            dpsHandleNewBar(id, ev);
        }
        return false;
    });

    function dpsHandleNewBar(id, ev) {
        if (dps_isRefreshing) return true;

        var sameDay = ev.start_date.getFullYear() === ev.end_date.getFullYear() &&
            ev.start_date.getMonth() === ev.end_date.getMonth() &&
            ev.start_date.getDate() === ev.end_date.getDate();
        if (!sameDay) {
            alert("Start time and end time must be on the same day.");
            dps_isRefreshing = true;
            scheduler.deleteEvent(id);
            dps_isRefreshing = false;
            return true;
        }

        var keyParts = String(ev.section_id).split("|");
        var section = dps_sectionsByKey[ev.section_id] || {};
        var hours = (ev.end_date - ev.start_date) / 3600000;
        var msg = "Create a new Day Planning?\n\n" +
            "Job: " + (keyParts[0] || "—") + "\n" +
            "Task: " + (keyParts[1] || "—") + "\n" +
            "Skill: " + (keyParts[2] || section.skill || "—") + "\n" +
            "Sequence No.: " + (keyParts[3] || "—") + "\n" +
            "Date: " + ev.start_date.toLocaleDateString(undefined, { weekday: "long", day: "2-digit", month: "short", year: "numeric" }) + "\n" +
            "Time: " + dpsPad2(ev.start_date.getHours()) + ":" + dpsPad2(ev.start_date.getMinutes()) +
            "–" + dpsPad2(ev.end_date.getHours()) + ":" + dpsPad2(ev.end_date.getMinutes()) +
            " (" + (Math.round(hours * 100) / 100) + " h)";
        if (!confirm(msg)) {
            dps_isRefreshing = true;
            scheduler.deleteEvent(id);
            dps_isRefreshing = false;
            return true;
        }

        var eventData = {
            start_date: ev.start_date,
            end_date: ev.end_date,
            section_id: ev.section_id
        };
        Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("OnEventCreated", [JSON.stringify(eventData)]);
        return true;
    }

    scheduler.attachEvent("onEventDeleted", function (id) {
        if (dps_isRefreshing) return true;
        Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("OnEventDeleted", [String(id)]);
        return true;
    });

    scheduler.attachEvent("onDblClick", function (id, e) {
        if (String(id).indexOf("|") < 0) return false; // not yet saved (temp id) - nothing to open
        var ev = scheduler.getEvent(id);
        var payload = ev ? {
            id: id,
            start_date: ev.start_date,
            end_date: ev.end_date,
            section_id: ev.section_id,
            text: ev.text
        } : { id: id };
        Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("OnEventDblClick", [String(id), JSON.stringify(payload)]);
        return false; // never open the native lightbox
    });

    scheduler.init("dps_scheduler_here", new Date(), "timeline");
    dps_scheduler_ready = true;
}

// -------------------------------------------------------
// Timeline view config, extracted so it can be rebuilt with a different x_size once the real
// earliest/latest Plan Date span is known (see resizeTimelineSpan) - configureScheduler() itself
// only knows a placeholder 31-day span at BOOT time, before any AL data has loaded yet.
// -------------------------------------------------------
function dpsRowLabel(key, label, section) {
    var sectionKey = (section && section.key) || key;
    return '<div class="dps-row-label' + dpsHlClass(sectionKey) + '" data-section-key="' + escapeHtmlAttr(sectionKey) + '">' + escapeHtml(label) + '</div>';
}

// Rows (sections) holding the Day Planning lines the page was opened for - see SetHighlightedSections.
var dps_highlightKeys = {};
function dpsHlClass(sectionKey) {
    return dps_highlightKeys[sectionKey] ? " dps-hl" : "";
}

function buildTimelineViewConfig(spanDays) {
    return {
        name: "timeline",
        render: "bar",
        dx: dps_showContext ? 340 : 190,
        columns: (dps_showContext ? [
            { label: "Project No.", width: 70, template: function (obj) { return dpsRowLabel(obj.key, obj.jobNo, obj); } },
            { label: "Task No.", width: 100, template: function (obj) { return dpsRowLabel(obj.key, obj.jobTaskNo, obj); } }
        ] : []).concat([
            { label: "Skill", width: dps_showContext ? 100 : 120, template: function (obj) { return dpsRowLabel(obj.key, obj.skill, obj); } },
            { label: "Sequence No.", width: 70, template: function (obj) { return dpsRowLabel(obj.key, obj.sequenceNo, obj); } }
        ]),

        x_unit: "hour",
        x_step: 2,
        x_start: 0,
        x_size: 12 * spanDays,
        x_length: 12,
        x_date: "%H",

        y_unit: scheduler.serverList("sections"),
        y_property: "section_id",

        dy: 28,
        section_autoheight: false,

        scrollable: true,
        scroll_position: new Date(new Date().setHours(6, 0, 0, 0)),
        column_width: 38,

        second_scale: {
            x_unit: "day",
            x_date: "%D %d %M"
        }
    };
}

// -------------------------------------------------------
// Resize the upper timeline to the loaded data, within a 12-calendar-month window.
function resizeTimelineSpan(earliestDateValue, latestDateValue) {
    var MIN_SPAN_DAYS = 31;
    // A Period To filter pins the end exactly (no buffer), so the last day shown is the filtered one.
    var BUFFER_DAYS = (dps_filterInfo && dps_filterInfo.periodTo) ? 0 : 7;
    var MS_PER_DAY = 24 * 60 * 60 * 1000;

    var start = toDateOrNull(earliestDateValue);
    var end = toDateOrNull(latestDateValue);

    var spanDays = MIN_SPAN_DAYS;
    if (start && end) {
        var diffDays = Math.round((end.getTime() - start.getTime()) / MS_PER_DAY) + 1; // inclusive of both ends
        var anniversary = new Date(start.getTime());
        anniversary.setFullYear(start.getFullYear() + 1);
        if (anniversary.getMonth() !== start.getMonth()) anniversary.setDate(0);
        var maxDays = Math.round((anniversary.getTime() - start.getTime()) / MS_PER_DAY);
        spanDays = Math.min(maxDays, Math.max(MIN_SPAN_DAYS, diffDays + BUFFER_DAYS));
    }

    if (spanDays === dps_currentTimelineSpanDays) return;
    dps_currentTimelineSpanDays = spanDays;
    scheduler.createTimelineView(buildTimelineViewConfig(spanDays));
    applyDayScaleWeekTemplate();
}

// createTimelineView resets templates.timeline_second_scale_date and timeline_scale_label on every call, so this must be re-applied after each one.
function applyDayScaleWeekTemplate() {
    // Row-level class as a second route to the same shading (see .dps-hl-row in style.css).
    scheduler.templates.timeline_row_class = function (section) {
        var key = section && section.key;
        return dpsHlClass(key).replace("dps-hl", "dps-hl-row") +
            (key && key === dps_selectedSectionKey ? " dps-active-sequence" : "");
    };
    scheduler.templates.timeline_cell_class = function (evs, date, section) {
        var key = (section && section.key) || section;
        return dpsDayOffClass(date, "-cell") + dpsHlClass(key);
    };
    scheduler.templates.timeline_scalex_class = function (date) {
        return dpsIsoWeekNumber(date) % 2 ? "dps-week-band-odd" : "";
    };
    scheduler.templates.timeline_second_scalex_class = function () { return ""; };
    var formatDate = scheduler.date.date_to_str("%D %d %M");
    var weekRenderQueued = false;
    scheduler.templates.timeline_second_scale_date = function (date) {
        var week = dpsIsoWeekNumber(date);
        if (!weekRenderQueued) {
            weekRenderQueued = true;
            requestAnimationFrame(function () {
                weekRenderQueued = false;
                renderOverviewWeekBands();
            });
        }
        return '<span class="dps-day-label dps-week-band-' + (week % 2 ? "odd" : "even") +
            '" data-week="' + week + '">' + escapeHtml(formatDate(date)) + '</span>';
    };
}

function renderOverviewWeekBands() {
    var overview = $id("dps_scheduler_here");
    if (!overview) return;
    overview.querySelectorAll(".dps-overview-weeks").forEach(function (row) { row.remove(); });
    var groups = new Map();
    overview.querySelectorAll(".dhx_second_scale_bar .dps-day-label").forEach(function (label) {
        var cell = label.parentElement;
        var cells = groups.get(cell.parentElement) || [];
        cells.push(cell);
        groups.set(cell.parentElement, cells);
    });
    groups.forEach(function (cells, header) {
        var row = document.createElement("div");
        row.className = "dps-overview-weeks";
        var band;
        var previousWeek;
        var rightEdge = 0;
        cells.forEach(function (cell) {
            var week = Number(cell.firstElementChild.dataset.week);
            var left = cell.offsetLeft;
            if (week !== previousWeek || Math.abs(left - rightEdge) > 1) {
                band = document.createElement("span");
                band.className = "dps-week-band dps-week-band-" + (week % 2 ? "odd" : "even");
                band.textContent = "Week " + week;
                band.style.left = left + "px";
                row.appendChild(band);
            }
            rightEdge = left + cell.offsetWidth;
            band.style.width = (rightEdge - parseFloat(band.style.left)) + "px";
            previousWeek = week;
        });
        header.classList.add("dps-overview-week-host");
        header.appendChild(row);
    });
}

function toDateOrNull(v) {
    if (!v) return null;
    var d = (v instanceof Date) ? v : new Date(v);
    return isNaN(d.getTime()) ? null : d;
}

function escapeHtml(txt) {
    return String(txt == null ? "" : txt)
        .replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
}
function escapeHtmlAttr(txt) {
    return escapeHtml(txt).replace(/"/g, "&quot;");
}
function safeCssToken(txt) {
    return String(txt == null ? "" : txt).replace(/[^a-zA-Z0-9_-]/g, "_");
}

// -------------------------------------------------------
// Row-label click (open Modify panel for that row) + hover tooltip (row = sequence summary,
// bar = single Day Planning line). Mirrors the demo's attachScaleInteraction.
// -------------------------------------------------------
function attachScaleInteraction() {
    var root = $id("dps_scheduler_here");
    if (!root) return;

    root.addEventListener("click", function (e) {
        var label = e.target.closest(".dps-row-label");
        if (label) {
            selectOverviewSequence(label.getAttribute("data-section-key"));
            return;
        }
        var bar = e.target.closest(".dhx_cal_event_line,.dhx_cal_event_clear");
        if (!bar) return;
        var id = bar.getAttribute("event_id") || bar.dataset.eventId;
        var slot = id != null && scheduler.getEvent(id);
        if (slot && dps_sectionsByKey[slot.section_id])
            selectOverviewSequence(slot.section_id);
    });

    root.addEventListener("mousemove", function (e) {
        var eventNode = e.target.closest(".dhx_cal_event_line,.dhx_cal_event_clear");
        if (eventNode) {
            var eventId = eventNode.getAttribute("event_id") || eventNode.dataset.eventId;
            if (eventId != null) {
                var ev = scheduler.getEvent(eventId);
                if (ev) { showSlotTooltip(ev, e.clientX, e.clientY); return; }
            }
        }
        var label = e.target.closest(".dps-row-label");
        if (label) {
            var section = dps_sectionsByKey[label.getAttribute("data-section-key")];
            if (section) { showSectionTooltip(section, e.clientX, e.clientY); return; }
        }
        hideTooltip();
    });

    root.addEventListener("mouseleave", hideTooltip);
}

function showSectionTooltip(section, x, y) {
    var t = $id("dpsTooltip");
    t.innerHTML =
        '<div class="dps-tooltip-head">' + escapeHtml(section.skillDescription) + ' &middot; Seq ' + escapeHtml(section.sequenceNo) + '</div>' +
        '<div class="dps-tooltip-body">' +
            '<div class="dps-tooltip-row"><div class="dps-tooltip-label">First date</div><div class="dps-tooltip-value">' + escapeHtml(section.minDate) + '</div></div>' +
            '<div class="dps-tooltip-row"><div class="dps-tooltip-label">Last date</div><div class="dps-tooltip-value">' + escapeHtml(section.maxDate) + '</div></div>' +
        '</div>';
    positionTooltip(t, x, y);
}

/// <summary>Single-line tooltip number cell: em-dash when the value is missing, otherwise rounded to 2 decimals + unit.</summary>
function ttNum(v, unit) {
    if (v === undefined || v === null || v === "") return "\u2014";
    return (Math.round(Number(v) * 100) / 100) + unit;
}

function dpsPad2(n) {
    return String(n).padStart(2, "0");
}

/// <summary>Parses an "HH:MM" string into minutes-since-midnight, or null if unparseable - used
/// so the Request-vs-Assigned tooltip comparison is done on numeric values instead of comparing
/// formatted display strings (a string compare flags a difference on things like a stray
/// character while missing nothing extra; more importantly here it also risks false positives
/// from formatting drift between the two independently-built strings even when the underlying
/// times match).</summary>
function dpsParseHHMM(text) {
    if (!text) return null;
    // AL's Format(...,'<Hours24,2>') space-pads single-digit hours (" 7:00"), not zero-pads -
    // trim before matching so that doesn't fail the regex and fall through to null.
    var m = /^(\d{1,2}):(\d{2})$/.exec(String(text).trim());
    if (!m) return null;
    return (parseInt(m[1], 10) * 60) + parseInt(m[2], 10);
}

/// <summary>ISO-8601 week number - ported verbatim from src/dhx/request_assignment/wrapper.js's own isoWeekNumber (the reference implementation, see standardTooltipHtml's own doc comment).</summary>
function dpsIsoWeekNumber(dateValue) {
    var date = dateValue instanceof Date ? new Date(dateValue) : new Date(dateValue);
    if (isNaN(date.getTime())) return "";
    var utcDate = new Date(Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()));
    var day = utcDate.getUTCDay() || 7;
    utcDate.setUTCDate(utcDate.getUTCDate() + 4 - day);
    var yearStart = new Date(Date.UTC(utcDate.getUTCFullYear(), 0, 1));
    return Math.ceil((((utcDate - yearStart) / 86400000) + 1) / 7);
}

/// <summary>
/// Standard single-Day-Planning-line hover tooltip (2026-09-11, standard-tooltip unification - see
/// this add-in's project memory) - structure/CSS class names ported from the reference
/// implementation, src/dhx/request_assignment/wrapper.js's requestTooltipHtml/
/// assignmentTooltipHtml, so every DHX add-in shows the same "Job and Task" table / Skill+Sqnc+
/// weekday+date head / Request-vs-Assigned Time+Resource table for a single line. This page is
/// always scoped to one Job Task (see codeunit 50695's own BuildSectionsAndEventsJson doc comment)
/// but the Job/Task table is kept anyway per this feature's own instructions - full structural
/// parity everywhere it's technically possible to populate, not trimmed for being contextually
/// redundant.
/// </summary>
function standardTooltipHtml(ev) {
    var reqTime = dpsPad2(ev.start_date.getHours()) + ":" + dpsPad2(ev.start_date.getMinutes()) +
        "–" + dpsPad2(ev.end_date.getHours()) + ":" + dpsPad2(ev.end_date.getMinutes());
    var assignedTimeKnown = !!(ev.assignedStartTime && ev.assignedEndTime);
    var assignedTime = assignedTimeKnown ? (ev.assignedStartTime + "–" + ev.assignedEndTime) : "—";
    var timeDiffers = assignedTimeKnown &&
        (dpsParseHHMM(ev.assignedStartTime) !== (ev.start_date.getHours() * 60 + ev.start_date.getMinutes()) ||
            dpsParseHHMM(ev.assignedEndTime) !== (ev.end_date.getHours() * 60 + ev.end_date.getMinutes()));
    var weekday = ev.start_date.toLocaleDateString(undefined, { weekday: "long" });
    var shortDate = ev.start_date.toLocaleDateString(undefined, { month: "short", day: "2-digit", year: "numeric" });

    return (
        '<div class="dps-standard-tooltip">' +
        '<div class="standard-tooltip-context">' +
            '<div class="standard-tooltip-context-title">Job and Task</div>' +
            '<table class="standard-tooltip-table standard-tooltip-context-table"><tbody>' +
                '<tr><td>' + escapeHtml(ev.job || "—") + '</td><td>' + escapeHtml(ev.jobDescription || "—") + '</td></tr>' +
                '<tr><td>' + escapeHtml(ev.task || "—") + '</td><td>' + escapeHtml(ev.taskDescription || "—") + '</td></tr>' +
            '</tbody></table>' +
        '</div>' +
        '<div class="standard-tooltip-head">' +
            '<div class="standard-tooltip-title">Skill: ' + escapeHtml(ev.skill || "—") + '</div>' +
            '<div class="standard-tooltip-detail">Sqnc ' + escapeHtml(ev.sequenceNo != null ? ev.sequenceNo : "—") + '</div>' +
            '<div class="standard-tooltip-detail">' + escapeHtml(weekday) + ' (wk ' + dpsIsoWeekNumber(ev.start_date) + ')</div>' +
            '<div class="standard-tooltip-detail">' + escapeHtml(shortDate) + '</div>' +
            '<div class="standard-tooltip-detail">Status: ' + escapeHtml(ev.planStatus || "—") + '</div>' +
        '</div>' +
        '<table class="standard-tooltip-table"><thead><tr><th></th><th>Request</th><th>Assigned</th></tr></thead><tbody>' +
            '<tr><th>Time</th><td>' + escapeHtml(reqTime) + '</td><td class="' + (timeDiffers ? "standard-tooltip-different" : "") + '">' + escapeHtml(assignedTime) + '</td></tr>' +
            '<tr><th>Hours</th><td>' + escapeHtml(ttNum(ev.requestedHours, " h")) + '</td><td>' + escapeHtml(ttNum(ev.assignedHours, " h")) + '</td></tr>' +
            '<tr><th>Idle</th><td>' + escapeHtml(ttNum(ev.requestedIdleMinutes, " min")) + '</td><td>' + escapeHtml(ttNum(ev.assignedIdleMinutes, " min")) + '</td></tr>' +
            '<tr><th>Resource</th><td>' + escapeHtml(ev.requestedResourceNo || "—") + '</td><td>' + escapeHtml(ev.assignedResourceNo || "—") + '</td></tr>' +
        '</tbody></table>' +
        '</div>'
    );
}

function showSlotTooltip(ev, x, y) {
    var t = $id("dpsTooltip");
    t.innerHTML = standardTooltipHtml(ev);
    positionTooltip(t, x, y);
}

function positionTooltip(t, x, y) {
    t.style.display = "block";
    var r = t.getBoundingClientRect();
    t.style.left = Math.min(x + 12, window.innerWidth - r.width - 8) + "px";
    t.style.top = Math.min(y + 12, window.innerHeight - r.height - 8) + "px";
}
function hideTooltip() {
    var t = $id("dpsTooltip");
    if (t) t.style.display = "none";
}

// -------------------------------------------------------
// Toolbar + panel/dialog wiring
// -------------------------------------------------------
function wireToolbarAndPanels() {
    $id("dpsModifyBtn").onclick = openModifySequence;
    $id("dpsNewBtn").onclick = openLinesDialog;

    $id("dpsClosePanel").onclick = closeSequencePanel;
    $id("dpsCancelPanel").onclick = closeSequencePanel;
    $id("dpsApplySequence").onclick = applySequence;
    $id("dpsDateSelector").onkeydown = function (event) {
        if (event.key !== "Enter" || event.repeat ||
            event.target.closest("button[data-month-direction], input[type=checkbox]")) return;
        if (!hasCompletedSequenceDraft()) return;
        if (dps_rangeDraftEnd && !validSequenceRange()) return;
        event.preventDefault();
        addSequenceSelection();
        var count = dps_modifySlots ? dps_selectedSlots.size : dps_selectedDates.size;
        $id("dpsSelectionStatus").textContent = count
            ? "Selection saved."
            : dps_originalDates.size
                ? "Dates saved. No matches for this action in the current Sequence."
                : "Selection cleared.";
    };
    $id("dpsRangeWeekdays").onchange = function (event) {
        var weekday = Number(event.target.value);
        if (event.target.checked) dps_rangeExclusions[weekday] = true;
        else delete dps_rangeExclusions[weekday];
        updateSequenceRange();
    };
    $id("dpsOperationGrid").onchange = function (event) {
        var choice = event.target;
        if (!choice.checked || choice.name !== "dpsOperation") return;
        dps_operation = choice.value;
        dps_planningSide = choice.dataset.side;
        if (dps_operation === "times") renderSequenceWeekPattern();
        updateSequenceOptions();
    };
    $id("dpsLookupResource").onclick = function () {
        Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("OnLookupSequenceResource", []);
    };
    $id("dpsWeekPattern").oninput = updateExecuteState;
    $id("dpsSeqTemplate").onchange = updateSequenceRange;
    $id("dpsClearDates").onclick = function () {
        clearSequenceDraft();
        dps_originalDates.clear();
        dps_savedWeekdaySkips.clear();
        dps_excludedSlots.clear();
        refreshCommittedSelection();
    };
    var timeline = $id("dpsRangeTimeline");
    timeline.onmousemove = function (event) {
        if (!event.shiftKey || !isAwaitingSequenceEnd()) { setSequenceHoverDate(""); return; }
        var day = event.target.closest("[data-date]");
        setSequenceHoverDate(day ? day.dataset.date : "");
    };
    document.addEventListener("keyup", function (event) {
        if (event.key === "Shift") setSequenceHoverDate("");
    });
    timeline.onmouseleave = function () { setSequenceHoverDate(""); };
    timeline.onclick = function (event) {
        var month = event.target.closest("button[data-month-direction]");
        if (month) {
            extendSequenceTimeline(Number(month.dataset.monthDirection));
            return;
        }
        var slot = event.target.closest("button[data-slot-id]");
        var day = event.target.closest("[data-date]");
        if (event.ctrlKey && (slot || day)) setSequenceDateMode(true);
        if (event.ctrlKey && dps_modifySlots) {
            if (slot) {
                if (!dps_draftSlots.delete(slot.dataset.slotId)) dps_draftSlots.add(slot.dataset.slotId);
            } else if (day) {
                toggleSequenceDaySlots(day.dataset.date);
            }
            updateSequenceRange();
            return;
        }
        if (!day) return;
        if (!event.ctrlKey) {
            if (!event.shiftKey && validSequenceRange()) setSequenceDateMode(true);
            setSequenceDateMode(false);
        }
        selectSequenceDate(day.dataset.date, event.shiftKey);
    };
    $id("dpsCloseLinesDialog").onclick = closeLinesDialog;
    $id("dpsCancelLines").onclick = closeLinesDialog;
    $id("dpsCreateLines").onclick = createLines;
    $id("dpsPickProject").onclick = function () {
        Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("OnLookupNewSequenceContext", [false, ""]);
    };
    $id("dpsPickTask").onclick = function () {
        var project = $id("dpsNewProject").value;
        if (project) Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("OnLookupNewSequenceContext", [true, project]);
    };
    $id("dpsEventTemplate").onchange = function () {
        renderExcludeGrid("dpsEventExcludeDays", dps_eventExclusionsDraft, $id("dpsEventTemplate").value);
        fillDatesFromTemplate($id("dpsEventTemplate").value, false);
    };

    document.addEventListener("keydown", function (e) {
        if (e.key === "Escape") { hideTooltip(); closeSequencePanel(); closeLinesDialog(); }
    });
}

function activeWeekdaySet(templateCode) {
    var tmpl = dps_templates.find(function (t) { return t.code === templateCode; });
    var allowed = {};
    if (!tmpl || !tmpl.activeWeekdays) return allowed;
    tmpl.activeWeekdays.split("|").forEach(function (w) {
        var n = parseInt(w, 10);
        if (!isNaN(n)) allowed[n] = true;
    });
    return allowed;
}

function renderExcludeGrid(targetId, draftSet, templateCode) {
    var allowed = activeWeekdaySet(templateCode);
    var host = $id(targetId);
    host.innerHTML = ISO_WEEKDAYS.map(function (pair) {
        var name = pair[0], wd = pair[1];
        var enabled = !!allowed[wd];
        var excluded = !!draftSet[wd];
        return '<button type="button" class="dps-daytoggle' + (excluded ? ' dps-excluded' : '') + '" data-wd="' + wd + '"' + (enabled ? "" : " disabled") + '>' + name + '</button>';
    }).join("");
    host.querySelectorAll(".dps-daytoggle:not(:disabled)").forEach(function (btn) {
        btn.addEventListener("click", function () {
            var wd = Number(btn.dataset.wd);
            if (draftSet[wd]) delete draftSet[wd]; else draftSet[wd] = true;
            renderExcludeGrid(targetId, draftSet, templateCode);
        });
    });
}

function excludedWeekdaysCsv(draftSet) {
    return Object.keys(draftSet).sort(function (a, b) { return a - b; }).join(",");
}

function populateSelect(selectId, items, placeholderText) {
    var sel = $id(selectId);
    var html = placeholderText ? '<option value="">' + escapeHtml(placeholderText) + '</option>' : '';
    html += items.map(function (it) {
        return '<option value="' + escapeHtmlAttr(it.code) + '">' + escapeHtml(it.description || it.code) + '</option>';
    }).join("");
    sel.innerHTML = html;
}

// ---- Modify sequence panel ----
var dps_hoverDate = "";
var dps_modifySlots = false;
var dps_selectedSlots = new Set();
var dps_draftSlots = new Set();
var dps_slotsById = new Map();
var dps_occupiedDates = new Set();

function sequenceOperationCell(operation, side, label, checked) {
    return '<td class="dps-operation-cell"><label title="' + label + '">' +
        '<input type="radio" name="dpsOperation" value="' + operation + '" data-side="' + side +
        '" aria-label="' + label + '"' + (checked ? ' checked' : '') + '></label></td>';
}

var dps_operation = "times";
var dps_planningSide = "requested";

function updateSequenceOptions() {
    var action = dps_operation;
    if (dps_modifySlots !== (action !== "add")) keepCompletedSequenceDraft();
    dps_hoverDate = "";
    dps_modifySlots = action !== "add";
    $id("dpsTemplateField").hidden = action !== "add";
    $id("dpsResourceField").hidden = action !== "resource";
    $id("dpsWeekPatternDetails").hidden = action !== "times";
    refreshCommittedSelection();
}

function SetSequenceResource(resourceNo) {
    $id("dpsResourceNo").value = resourceNo;
    updateExecuteState();
}

function renderSequenceWeekPattern() {
    var section = dps_sectionsByKey[dps_selectedSectionKey];
    var patterns = section && section.weekPattern;
    var weekdays = patterns && patterns[dps_planningSide];
    $id("dpsWeekPattern").tBodies[0].innerHTML = ISO_WEEKDAYS.map(function (pair) {
        var values = (weekdays && weekdays[pair[1]]) || ["", "", ""];
        return '<tr data-weekday="' + pair[1] + '"><th scope="row">' + pair[0] + '</th>' +
            '<td><input type="time" aria-label="' + pair[0] + ' Start Time" value="' + escapeHtmlAttr(sequenceTimeInputValue(values[0])) + '"></td>' +
            '<td><input type="time" aria-label="' + pair[0] + ' End Time" value="' + escapeHtmlAttr(sequenceTimeInputValue(values[1])) + '"></td>' +
            '<td><input type="number" min="0" step="1" aria-label="' + pair[0] + ' Idle minutes" value="' + escapeHtmlAttr(values[2]) + '"></td></tr>';
    }).join("");
}

function sequenceTimeInputValue(value) {
    var time = String(value || "").trim();
    if (/^\d:/.test(time)) time = "0" + time;
    return time.slice(0, 5);
}

function eligibleAddDates() {
    var weekdays = activeWeekdaySet($id("dpsSeqTemplate").value);
    var today = isoDateOnly(new Date());
    return Array.from(dps_selectedDates).filter(function (date) {
        return date >= today && weekdays[new Date(date + "T12:00:00").getDay() || 7] && !dps_holidays[date];
    }).sort();
}

function secondsSinceMidnight(value) {
    var parts = value.split(":").map(Number);
    return parts[0] * 3600 + parts[1] * 60 + (parts[2] || 0);
}

function readSequenceWeekPattern() {
    var requiredDays = new Set(Array.from(dps_selectedSlots, function (id) {
        return dps_slotsById.get(id).start_date.getDay() || 7;
    }));
    var pattern = {};
    var valid = true;
    $id("dpsWeekPattern").querySelectorAll("tbody tr").forEach(function (row) {
        var weekday = Number(row.dataset.weekday);
        if (!requiredDays.has(weekday)) return;
        var inputs = row.querySelectorAll("input");
        var start = inputs[0].value;
        var end = inputs[1].value;
        var idle = Number(inputs[2].value);
        var startSeconds = secondsSinceMidnight(start);
        var endSeconds = secondsSinceMidnight(end);
        if (!start || !end || startSeconds === 0 || !Number.isInteger(idle) ||
            idle < 0 || idle >= Math.floor((endSeconds - startSeconds) / 60))
            valid = false;
        pattern[weekday] = {
            start: start.length === 5 ? start + ":00" : start,
            end: end.length === 5 ? end + ":00" : end,
            idle: idle
        };
    });
    return valid && Object.keys(pattern).length === requiredDays.size ? pattern : null;
}

function updateExecuteState() {
    var action = dps_operation;
    var reason = "";
    if (!dps_sectionsByKey[dps_selectedSectionKey]) {
        reason = "Select a Sequence.";
    } else if (!dps_pickDates && (dps_rangeDraftStart || dps_rangeDraftEnd) && !validSequenceRange()) {
        reason = "Choose a valid Start Date and End Date.";
    } else if (hasCompletedSequenceDraft()) {
        reason = "Execute will include your current selection.";
    } else if (action === "add") {
        if (!$id("dpsSeqTemplate").value) reason = "Choose a Work-Hour Template.";
        else if (!eligibleAddDates().length) {
            var today = isoDateOnly(new Date());
            var emptyDates = Array.from(dps_selectedDates);
            if (!dps_originalDates.size) reason = "Select dates to add Time Slots.";
            else if (Array.from(dps_originalDates).every(function (date) { return date < today; }))
                reason = "All " + dps_originalDates.size + " selected dates are in the past. Select empty dates from today onward.";
            else if (!emptyDates.length) reason = "All selected dates already have Time Slots.";
            else if (emptyDates.every(function (date) { return date < today; }))
                reason = "The selected dates from today onward already have Time Slots.";
            else reason = "None of the selected empty dates from today onward match the Work-Hour Template and calendar.";
        }
    } else if (!dps_selectedSlots.size) {
        reason = "Select at least one existing Time Slot.";
    } else if (action === "resource") {
        if (!$id("dpsResourceNo").value) reason = "Choose a Resource No.";
    } else if (action === "times" && !readSequenceWeekPattern()) {
        reason = "Open Week Pattern and enter valid start, end, and idle times for each selected weekday.";
    }

    $id("dpsExecuteStatus").textContent = reason;
    $id("dpsApplySequence").disabled = Boolean(reason) && !hasCompletedSequenceDraft();
}

var dps_rangeDraftStart = "";
var dps_rangeDraftEnd = "";
var dps_pickDates = false;
var dps_selectedDates = new Set();
var dps_draftDates = new Set();
var dps_originalDates = new Set();
var dps_excludedSlots = new Map();
var dps_savedWeekdaySkips = new Set();
var dps_draftWeekdaySkips = new Set();
var dps_rangeExclusions = { 6: true, 7: true };

function clearSequenceDraft() {
    dps_rangeExclusions = { 6: true, 7: true };
    dps_draftDates.clear();
    dps_draftWeekdaySkips.clear();
    dps_draftSlots.clear();
    dps_hoverDate = "";
    dps_rangeDraftStart = "";
    dps_rangeDraftEnd = "";
}

function isSequenceSlotPicked(id) {
    return dps_selectedSlots.has(id) !== dps_draftSlots.has(id);
}

function toggleSequenceDaySlots(date) {
    var ids = Array.from(dps_slotsById.keys()).filter(function (id) {
        return isoDateOnly(dps_slotsById.get(id).start_date) === date;
    });
    var pick = !ids.every(isSequenceSlotPicked);
    ids.forEach(function (id) {
        if (dps_selectedSlots.has(id) === pick) dps_draftSlots.delete(id);
        else dps_draftSlots.add(id);
    });
}

function hasCompletedSequenceDraft() {
    return Boolean(dps_draftDates.size || dps_draftSlots.size || validSequenceRange());
}

function keepCompletedSequenceDraft() {
    if (hasCompletedSequenceDraft()) addSequenceSelection();
}

function addSequenceSelection() {
    if (dps_draftDates.size || dps_draftSlots.size) {
        if (dps_modifySlots) {
            var visibleDates = new Set();
            dps_slotsById.forEach(function (slot) { visibleDates.add(isoDateOnly(slot.start_date)); });
            dps_draftDates.forEach(function (date) {
                if (!visibleDates.has(date)) dps_originalDates.add(date);
            });
            var touchedDates = new Set();
            dps_draftSlots.forEach(function (id) {
                var slot = dps_slotsById.get(id);
                if (!slot) return;
                var date = isoDateOnly(slot.start_date);
                touchedDates.add(date);
                if (dps_selectedSlots.has(id)) dps_excludedSlots.set(id, date);
                else {
                    dps_excludedSlots.delete(id);
                    dps_originalDates.add(date);
                }
            });
            var includedDates = new Set();
            dps_slotsById.forEach(function (slot, id) {
                if (!dps_excludedSlots.has(id)) includedDates.add(isoDateOnly(slot.start_date));
            });
            touchedDates.forEach(function (date) {
                if (!includedDates.has(date)) dps_originalDates.delete(date);
            });
        } else {
            dps_draftDates.forEach(function (date) {
                if (dps_originalDates.delete(date)) clearSlotExclusions(date);
                else dps_originalDates.add(date);
            });
        }
    }
    dps_draftWeekdaySkips.forEach(function (date) { dps_savedWeekdaySkips.add(date); });
    if (validSequenceRange())
        sequenceRangeDates(true).forEach(function (date) { dps_savedWeekdaySkips.add(date); });
    dps_originalDates.forEach(function (date) { dps_savedWeekdaySkips.delete(date); });
    if (validSequenceRange()) {
        sequenceRangeDates().forEach(function (date) {
            dps_originalDates.add(date);
            dps_savedWeekdaySkips.delete(date);
            clearSlotExclusions(date);
        });
    }

    clearSequenceDraft();
    refreshCommittedSelection();
}

function clearSlotExclusions(date) {
    dps_excludedSlots.forEach(function (excludedDate, id) {
        if (excludedDate === date) dps_excludedSlots.delete(id);
    });
}

function refreshCommittedSelection() {
    dps_selectedDates = new Set(dps_originalDates);
    dps_selectedSlots.clear();
    dps_slotsById.clear();
    var section = dps_sectionsByKey[dps_selectedSectionKey];
    var dates = section && section.weekPattern && section.weekPattern.occupiedDates;
    dps_occupiedDates = new Set(dates || []);
    dps_occupiedDates.forEach(function (date) { dps_selectedDates.delete(date); });
    scheduler.getEvents().forEach(function (slot) {
        if (slot.section_id !== dps_selectedSectionKey) return;
        var date = isoDateOnly(slot.start_date);
        var id = String(slot.id);
        dps_slotsById.set(id, slot);
        dps_occupiedDates.add(date);
        dps_selectedDates.delete(date);
        if (dps_originalDates.has(date) && !dps_excludedSlots.has(id)) dps_selectedSlots.add(id);
    });
    updateSequenceRange();
}

function sequenceRangeDates(excludedOnly) {
    var dates = new Set();
    var day = new Date(dps_rangeDraftStart + "T12:00:00");
    var last = new Date(dps_rangeDraftEnd + "T12:00:00");
    while (day <= last) {
        var excluded = isRangeWeekdayExcluded(day, dps_rangeExclusions);
        if (excluded === Boolean(excludedOnly))
            dates.add(isoDateOnly(day));
        day.setDate(day.getDate() + 1);
    }
    return dates;
}

function setSequenceDateMode(pickDates) {
    if (pickDates && !dps_pickDates) {
        if (validSequenceRange()) {
            var range = sequenceRangeDates();
            sequenceRangeDates(true).forEach(function (date) { dps_draftWeekdaySkips.add(date); });

            if (dps_modifySlots) {
                range.forEach(function (date) { dps_draftDates.add(date); });
                dps_slotsById.forEach(function (slot, id) {
                    if (range.has(isoDateOnly(slot.start_date))) {
                        if (dps_selectedSlots.has(id)) dps_draftSlots.delete(id);
                        else dps_draftSlots.add(id);
                    }
                });
            } else {
                range.forEach(function (date) {
                    if (dps_originalDates.has(date)) dps_draftDates.delete(date);
                    else dps_draftDates.add(date);
                });
            }
        }
        dps_rangeDraftStart = "";
        dps_rangeDraftEnd = "";
        dps_hoverDate = "";
    }
    dps_pickDates = pickDates;
    updateSequenceRange();
}
var dps_rangeStart = "";
var dps_rangeEnd = "";
var dps_extendedStart = "";
var dps_extendedEnd = "";

function extendSequenceTimeline(direction) {
    var section = dps_sectionsByKey[dps_selectedSectionKey];
    if (!section) return;

    if (direction < 0) {
        var first = new Date(dps_rangeStart + "T12:00:00");
        first.setMonth(first.getMonth() - 1);
        dps_extendedStart = isoDateOnly(first);
        dps_extendedEnd = dps_rangeEnd;
        renderSequenceRange(section);
        ensureSequenceRangeVisible(dps_extendedStart);
    } else {
        var next = new Date(dps_rangeEnd + "T12:00:00");
        next.setDate(next.getDate() + 1);
        dps_extendedEnd = isoDateOnly(next);
        dps_extendedStart = dps_rangeStart;
        renderSequenceRange(section);
        ensureSequenceRangeVisible(dps_extendedEnd);
    }
}

function validSequenceRange() {
    var start = dps_rangeDraftStart;
    var end = dps_rangeDraftEnd;
    return Boolean(start && end && start <= end);
}

function isAwaitingSequenceEnd() {
    return !dps_pickDates && Boolean(dps_rangeDraftStart && !dps_rangeDraftEnd);
}

function selectSequenceDate(date, finishRange) {
    if (dps_pickDates) {
        if (!dps_draftDates.delete(date)) dps_draftDates.add(date);
        updateSequenceRange();
        return;
    }

    dps_hoverDate = "";
    if (finishRange !== false && dps_rangeDraftStart) {
        dps_rangeDraftEnd = date;
        if (date < dps_rangeDraftStart) {
            dps_rangeDraftEnd = dps_rangeDraftStart;
            dps_rangeDraftStart = date;
        }
    } else {
        dps_rangeDraftStart = date;
        dps_rangeDraftEnd = "";
    }
    updateSequenceRange();
}

function isRangeWeekdayExcluded(date, exclusions) {
    return Boolean(exclusions && exclusions[date.getDay() || 7]);
}

function updateSequenceRange() {
    $id("dpsSelectionStatus").textContent = "";
    var start = dps_rangeDraftStart;
    var end = dps_rangeDraftEnd;
    var valid = validSequenceRange();
    var hint = "Click a start date. Shift + hover to preview, Shift + click to end. Ctrl + click to toggle. Enter to save.";
    if (start && end && !valid) hint = "End Date must be on or after Start Date.";
    var count = new Set([...dps_originalDates, ...dps_savedWeekdaySkips]).size;
    var affected = dps_selectedSlots.size;
    var actionSummary = (dps_operation === "delete" ? "Delete " : "Modify ") +
        affected + (affected === 1 ? " Time Slot" : " Time Slots");
    if (!dps_modifySlots) {
        var eligible = eligibleAddDates().length;
        actionSummary = $id("dpsSeqTemplate").value
            ? "Add Time Slots on " + eligible + (eligible === 1 ? " date" : " dates")
            : "Choose a Work-Hour Template to see how many dates can be added";
    }
    $id("dpsRangeHint").textContent = hint;
    $id("dpsDateCount").textContent = count + (count === 1 ? " date selected" : " dates selected") + " · " + actionSummary;
    var hasDraft = hasCompletedSequenceDraft() || Boolean(start || end);
    $id("dpsClearDates").disabled = count === 0 && !hasDraft;
    var weekdays = $id("dpsRangeWeekdays");
    weekdays.querySelectorAll("input").forEach(function (input) {
        input.checked = Boolean(dps_rangeExclusions[input.value]);
    });
    updateExecuteState();
    paintSequenceSelection();
}

function setSequenceHoverDate(date) {
    if (date === dps_hoverDate) return;
    dps_hoverDate = date;
    paintSequenceSelection();
}

function paintSequenceSelection() {
    var start = dps_rangeDraftStart;
    var end = dps_rangeDraftEnd;
    var hovering = isAwaitingSequenceEnd() && dps_hoverDate;
    var first = hovering && dps_hoverDate < start ? dps_hoverDate : start;
    var last = hovering ? (dps_hoverDate < start ? start : dps_hoverDate) : end;
    var hasRange = Boolean(first && last && first <= last);
    var previewStartOnly = isAwaitingSequenceEnd() && !hovering;
    var eligibleDates = !dps_modifySlots && $id("dpsSeqTemplate").value ? new Set(eligibleAddDates()) : null;

    var savedStart = "";
    if (dps_modifySlots) dps_originalDates.forEach(function (date) {
        if (!savedStart || date < savedStart) savedStart = date;
    });
    var pickingSlots = dps_modifySlots && dps_pickDates;
    var daySlots = new Map();
    if (dps_modifySlots) dps_slotsById.forEach(function (slot, id) {
        var date = isoDateOnly(slot.start_date);
        var state = daySlots.get(date) || { total: 0, picked: 0, saved: 0, draft: false, removal: false };
        var saved = dps_selectedSlots.has(id);
        var draft = dps_draftSlots.has(id);
        state.total++;
        if (isSequenceSlotPicked(id)) state.picked++;
        if (saved) state.saved++;
        if (draft && saved) state.removal = true;
        if (draft && !saved) state.draft = true;
        daySlots.set(date, state);
    });
    $id("dpsRangeTimeline").querySelectorAll("button[data-date]").forEach(function (day) {
        var date = day.dataset.date;
        var selected = dps_selectedDates.has(date);
        var inRange = hasRange && date >= first && date <= last;
        var preview = !dps_modifySlots && (dps_draftDates.has(date) || (!dps_pickDates &&
            (hasRange ? inRange : date === start)));
        var state = daySlots.get(date);
        var removal = dps_pickDates && !dps_modifySlots && dps_originalDates.has(date) && preview;
        if (dps_modifySlots) {
            selected = Boolean(state && state.saved);
            preview = Boolean(state && (state.draft || (!pickingSlots && (inRange || (previewStartOnly && date === start)) &&
                !isRangeWeekdayExcluded(new Date(date + "T12:00:00"), dps_rangeExclusions))));
            removal = Boolean(pickingSlots && state && state.removal && !state.picked);
        }
        // A pending removal replaces the saved highlight until Add Selection is clicked.
        var pressed = String(!removal && (selected || (preview && !hovering)));
        if (pickingSlots && state)
            pressed = state.picked === state.total ? "true" : (state.picked ? "mixed" : "false");
        day.setAttribute("aria-pressed", pressed);
        var weekdaySkipped = !selected && (
            (inRange && !dps_pickDates && isRangeWeekdayExcluded(new Date(date + "T12:00:00"), dps_rangeExclusions)) ||
            (!preview && (dps_draftWeekdaySkips.has(date) || dps_savedWeekdaySkips.has(date))));
        day.classList.toggle("dps-occupied-pick", !removal &&
            (weekdaySkipped || (!dps_modifySlots && dps_occupiedDates.has(date) && (preview || dps_originalDates.has(date)))));
        var savedDate = dps_modifySlots && dps_originalDates.has(date) && !removal;
        day.classList.toggle("dps-saved-date", savedDate);
        day.classList.toggle("dps-saved-date-start", savedDate && date === savedStart);
        day.classList.toggle("dps-date-frozen", selected && !removal);
        day.classList.toggle("dps-template-skips", selected && eligibleDates && !eligibleDates.has(date));
        day.classList.toggle("dps-selection-removal", removal);
        day.classList.toggle("dps-range-preview", preview && !removal);
        day.classList.toggle("dps-hover-date", Boolean(hovering && preview));
        day.classList.toggle("dps-range-start", preview && date === first);
        day.classList.toggle("dps-range-end", preview && hasRange && date === last);
    });
    $id("dpsRangeTimeline").querySelectorAll("button[data-slot-id]").forEach(function (slot) {
        var id = slot.dataset.slotId;
        var saved = dps_modifySlots && dps_selectedSlots.has(id);
        var date = slot.closest(".dps-picker-day-cell").dataset.date;
        var draft = dps_modifySlots && (dps_draftSlots.has(id) || (!dps_pickDates &&
            ((hasRange && date >= first && date <= last) || (previewStartOnly && date === start)) &&
            !isRangeWeekdayExcluded(new Date(date + "T12:00:00"), dps_rangeExclusions)));
        slot.classList.toggle("dps-slot-saved", saved);
        slot.classList.toggle("dps-selection-removal", dps_pickDates && saved && draft);
        slot.classList.toggle("dps-slot-draft", draft);
        slot.classList.toggle("dps-hover-slot", Boolean((hovering || previewStartOnly) && draft));
        slot.setAttribute("aria-pressed", String(dps_pickDates ? saved !== draft : saved || (draft && !hovering)));
        slot.tabIndex = dps_modifySlots && dps_pickDates ? 0 : -1;
    });
}

function ensureSequenceRangeVisible(value) {
    if (!value) return;
    if (value < dps_rangeStart || value > dps_rangeEnd)
        renderSequenceRange(dps_sectionsByKey[dps_selectedSectionKey]);
    var timeline = $id("dpsRangeTimeline");
    var day = timeline.querySelector('button[data-date="' + value + '"]');
    if (day && timeline.clientWidth) {
        var left = day.getBoundingClientRect().left - timeline.getBoundingClientRect().left + timeline.scrollLeft;
        if (left < timeline.scrollLeft || left + day.offsetWidth > timeline.scrollLeft + timeline.clientWidth)
            timeline.scrollLeft = left - timeline.clientWidth / 2;
    }
}

function renderSequenceRange(section) {
    dps_hoverDate = "";
    var timeline = $id("dpsRangeTimeline");
    timeline.replaceChildren();
    if (!section) return;

    var range = [section.minDate, section.maxDate, dps_extendedStart, dps_extendedEnd,
        dps_rangeDraftStart, dps_rangeDraftEnd]
        .concat(Array.from(dps_originalDates), Array.from(dps_draftDates),
            Array.from(dps_savedWeekdaySkips), Array.from(dps_draftWeekdaySkips)).filter(Boolean).sort();
    var first = range[0] || isoDateOnly(new Date());
    var last = range[range.length - 1] || first;
    var firstMonth = new Date(first.slice(0, 7) + "-01T12:00:00");
    var lastMonth = new Date(last.slice(0, 7) + "-01T12:00:00");
    if (firstMonth.getTime() === lastMonth.getTime()) lastMonth.setMonth(lastMonth.getMonth() + 1);
    dps_rangeStart = isoDateOnly(firstMonth);
    var endOfLastMonth = new Date(lastMonth);
    endOfLastMonth.setMonth(endOfLastMonth.getMonth() + 1, 0);
    dps_rangeEnd = isoDateOnly(endOfLastMonth);

    refreshCommittedSelection();
    var slotsByDate = new Map();
    dps_slotsById.forEach(function (slot) {
        var key = isoDateOnly(slot.start_date);
        var slots = slotsByDate.get(key) || [];
        slots.push(slot);
        slotsByDate.set(key, slots);
    });

    var months = document.createDocumentFragment();
    months.appendChild(sequenceMonthButton(-1));
    var date = new Date(firstMonth);
    var calendar = document.createElement("div");
    calendar.className = "dps-picker-calendar";
    months.appendChild(calendar);
    var monthHeading;
    var weekHeading;
    var dayColumn = 1;
    while (date <= endOfLastMonth) {
        var week = dpsIsoWeekNumber(date);
        if (date.getDate() === 1) {
            monthHeading = document.createElement("div");
            monthHeading.className = "dps-range-month-title";
            monthHeading.textContent = date.toLocaleDateString(undefined, { month: "long", year: "numeric" });
            monthHeading.style.gridRow = "1";
            monthHeading.style.gridColumnStart = dayColumn;
            calendar.appendChild(monthHeading);
        }
        if (dayColumn === 1 || date.getDay() === 1) {
            weekHeading = document.createElement("div");
            weekHeading.className = "dps-picker-week-title dps-week-band-" + (week % 2 ? "odd" : "even");
            weekHeading.textContent = "Week " + week;
            weekHeading.style.gridRow = "2";
            weekHeading.style.gridColumnStart = dayColumn;
            calendar.appendChild(weekHeading);
        }
        monthHeading.style.gridColumnEnd = dayColumn + 1;
        weekHeading.style.gridColumnEnd = dayColumn + 1;
        var day = document.createElement("button");
        day.type = "button";
        day.className = "dps-range-day" + (week % 2 ? " dps-week-odd" : " dps-week-even");
        if (date.getDay() === 1) day.classList.add("dps-week-start");
        var dayOffClass = dpsDayOffClass(date, "-picker");
        if (dayOffClass) day.classList.add(dayOffClass);
        day.dataset.date = isoDateOnly(date);
        var slots = slotsByDate.get(day.dataset.date) || [];
        var hiddenOccupancy = !slots.length && dps_occupiedDates.has(day.dataset.date);
        var label = date.toLocaleDateString(undefined, { dateStyle: "full" });
        var times = slots.map(function (slot) {
            var format = { hour: "2-digit", minute: "2-digit", hour12: false };
            return slot.start_date.toLocaleTimeString(undefined, format) + "–" +
                slot.end_date.toLocaleTimeString(undefined, format);
        });
        var dayOff = dayOffClass === "weekend-picker" ? "Weekend" : dps_holidays[day.dataset.date];
        day.title = label + " · Week " + week + (dayOff ? " · " + dayOff : "") + (times.length ? " · " + times.join(", ") : hiddenOccupancy ? " · Existing Time Slot outside the current view" : " · No Time Slots");
        day.setAttribute("aria-label", day.title);
        var number = document.createElement("span");
        number.className = "dps-range-date-number";
        number.textContent = date.getDate();
        day.appendChild(number);
        var cell = document.createElement("div");
        cell.className = "dps-picker-day-cell";
        cell.dataset.date = day.dataset.date;
        cell.appendChild(day);
        var markers = document.createElement("div");
        markers.className = "dps-picker-slot-markers";
        slots.forEach(function (slot, index) {
            var marker = document.createElement("button");
            marker.type = "button";
            marker.className = "dps-range-slot";
            marker.dataset.slotId = String(slot.id);
            marker.title = label + " · " + times[index];
            marker.setAttribute("aria-label", marker.title);
            marker.style.backgroundColor = section.color || "#008c83";
            markers.appendChild(marker);
        });
        if (hiddenOccupancy) {
            var hiddenMarker = document.createElement("span");
            hiddenMarker.className = "dps-range-slot dps-hidden-slot";
            hiddenMarker.style.backgroundColor = section.color || "#008c83";
            hiddenMarker.setAttribute("aria-hidden", "true");
            markers.appendChild(hiddenMarker);
        }
        cell.appendChild(markers);
        cell.style.gridRow = "3";
        cell.style.gridColumn = dayColumn++;
        calendar.appendChild(cell);
        date.setDate(date.getDate() + 1);
    }

    months.appendChild(sequenceMonthButton(1));
    timeline.appendChild(months);
    updateSequenceRange();
}

function sequenceMonthButton(direction) {
    var button = document.createElement("button");
    button.type = "button";
    button.className = "dps-btn dps-add-month";
    button.dataset.monthDirection = String(direction);
    button.textContent = direction < 0 ? "← Add Month" : "Add Month →";
    button.setAttribute("aria-label", direction < 0 ? "Add previous month" : "Add next month");
    return button;
}

function setSequencePane(paneId) {
    ["dpsSequencePanel", "dpsLinesDialog"].forEach(function (id) {
        $id(id).classList.toggle("dps-open", id === paneId);
    });
    renderSequenceOverview();
}

function renderSequenceOverview() {
    if (!dps_scheduler_ready) return;
    var timeline = scheduler.matrix.timeline;
    var scroll = timeline.getScrollPosition();
    scheduler.setSizes();
    timeline.scrollTo(scroll.left);
    var overview = $id("dps_scheduler_here");
    var data = overview.querySelector(".dhx_timeline_data_wrapper");
    if (data) data.scrollTop = scroll.top;
}

function syncOverviewSequenceMarker() {
    var style = $id("dpsSequenceHighlight");
    if (!style) return;
    style.textContent = dps_selectedSectionKey
        ? '#dps_scheduler_here .dps-row-label[data-section-key="' + CSS.escape(String(dps_selectedSectionKey)) +
            '"] { box-shadow: inset 0 0 0 2px #2457d6; background: #dce9ff !important; }'
        : "";
}

function selectOverviewSequence(sectionKey) {
    if (!dps_sectionsByKey[sectionKey] || sectionKey === dps_selectedSectionKey) return;
    if ($id("dpsSequencePanel").classList.contains("dps-open")) {
        keepCompletedSequenceDraft();
        openSequencePanel(sectionKey, true);
        return;
    }
    dps_selectedSectionKey = sectionKey;
    syncOverviewSequenceMarker();
    refreshCommittedSelection();
    renderSequenceOverview();
}

function openModifySequence() {
    if (dps_sectionsByKey[dps_selectedSectionKey]) {
        openSequencePanel(dps_selectedSectionKey);
        return;
    }
    if (dps_sections.length === 1) {
        openSequencePanel(dps_sections[0].key);
        return;
    }
    if (!dps_sections.length) {
        alert("There are no Sequences to modify.");
        return;
    }

    showSequencePrompt();
}

function showSequencePrompt() {
    hideTooltip();
    $id("dpsModifyCaption").textContent = "Modify Sequence";
    $id("dpsSelectSequenceHint").hidden = false;
    $id("dpsRangeStep").hidden = true;
    $id("dpsRangeWeekdays").hidden = true;
    $id("dpsDateSelector").hidden = true;
    $id("dpsDateSelection").hidden = true;
    $id("dpsWeekPatternDetails").hidden = true;
    $id("dpsApplySequence").hidden = true;
    $id("dpsExecuteStatus").textContent = "";
    setSequencePane("dpsSequencePanel");
}

function openSequencePanel(sectionKey, switchingSequence) {
    if (!sectionKey) return;
    var section = dps_sectionsByKey[sectionKey];
    if (!section) return;

    hideTooltip();
    dps_selectedSectionKey = sectionKey;
    syncOverviewSequenceMarker();
    $id("dpsSelectSequenceHint").hidden = true;
    $id("dpsModifyCaption").textContent = "Modify Sequence · " +
        (section.skillDescription || section.skill) + " · Seq " + section.sequenceNo;
    var template = $id("dpsSeqTemplate").value;
    populateSelect("dpsSeqTemplate", dps_templates, "Select template...");
    $id("dpsSeqTemplate").value = dps_templates.some(function (item) { return item.code === template; }) ? template : "";
    if (!switchingSequence) {
        clearSequenceDraft();
        dps_extendedStart = "";
        dps_extendedEnd = "";
        setSequenceDateMode(false);
    }
    refreshCommittedSelection();
    $id("dpsRangeStep").hidden = false;
    $id("dpsRangeWeekdays").hidden = false;
    $id("dpsDateSelector").hidden = false;
    $id("dpsDateSelection").hidden = false;
    $id("dpsApplySequence").hidden = false;
    renderSequenceWeekPattern();
    updateSequenceOptions();
    renderSequenceRange(section);
    setSequencePane("dpsSequencePanel");
    $id("dpsRangeTimeline").scrollLeft = 0;
    var selectedDates = dps_modifySlots
        ? Array.from(dps_selectedSlots).map(function (id) {
            return isoDateOnly(dps_slotsById.get(id).start_date);
        })
        : Array.from(dps_selectedDates);
    ensureSequenceRangeVisible(selectedDates.sort()[0]);
}
function closeSequencePanel() {
    if ($id("dpsSequencePanel").classList.contains("dps-open")) setSequencePane(null);
}
var dps_pendingAdd = null;

function applySequence() {
    keepCompletedSequenceDraft();
    updateExecuteState();
    if ($id("dpsApplySequence").disabled) return;
    var action = dps_operation;
    if (action === "delete" && !confirm("Delete " + dps_selectedSlots.size + " selected Day Planning lines?")) return;
    var dates = {};
    dps_selectedSlots.forEach(function (id) {
        dates[id] = isoDateOnly(dps_slotsById.get(id).start_date);
    });
    var payload = {
        action: action,
        assigned: dps_planningSide === "assigned",
        section: dps_selectedSectionKey,
        template: $id("dpsSeqTemplate").value,
        resource: $id("dpsResourceNo").value,
        dates: action === "add" ? Array.from(dps_selectedDates).sort() : [],
        lines: dates,
        pattern: action === "times" ? readSequenceWeekPattern() : {}
    };
    dps_pendingAdd = action === "add" ? { section: payload.section, dates: new Set(payload.dates) } : null;
    $id("dpsExecuteStatus").textContent = "Sending changes to Business Central…";
    try {
        Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("OnExecuteSequence", [JSON.stringify(payload)]);
    } catch (error) {
        dps_pendingAdd = null;
        console.error("Sequence Execute failed:", error);
        $id("dpsExecuteStatus").textContent = "Could not send changes to Business Central.";
    }
}

function SequenceExecuted() {
    if ($id("dpsSequencePanel").classList.contains("dps-open"))
        $id("dpsSelectionStatus").textContent = "Changes applied.";
}

// ---- New sequence dialog ----
function SetNewSequenceContext(projectNo, taskNo) {
    $id("dpsNewProject").value = projectNo;
    $id("dpsNewTask").value = taskNo;
    $id("dpsPickTask").disabled = !projectNo;
}

function openLinesDialog() {
    $id("dpsNewProjectField").hidden = !dps_showContext;
    $id("dpsNewTaskField").hidden = !dps_showContext;
    if (dps_showContext) {
        var section = dps_sectionsByKey[dps_selectedSectionKey];
        SetNewSequenceContext(section ? section.jobNo : "", section ? section.jobTaskNo : "");
    }
    populateSelect("dpsEventSkill", dps_skills, "Select skill...");
    populateSelect("dpsEventTemplate", dps_templates, "Select template...");
    $id("dpsEventSkill").value = dps_defaultSkill;
    $id("dpsEventTemplate").value = dps_defaultTemplate;
    // value only sticks if the option exists; fall back to the placeholder
    if ($id("dpsEventSkill").value !== dps_defaultSkill) $id("dpsEventSkill").value = "";
    if ($id("dpsEventTemplate").value !== dps_defaultTemplate) $id("dpsEventTemplate").value = "";
    dps_eventExclusionsDraft = {};
    renderExcludeGrid("dpsEventExcludeDays", dps_eventExclusionsDraft, $id("dpsEventTemplate").value);

    fillDatesFromTemplate($id("dpsEventTemplate").value, true);

    $id("dpsCreateStatus").textContent = "";
    setSequencePane("dpsLinesDialog");
}
function closeLinesDialog() {
    if ($id("dpsLinesDialog").classList.contains("dps-open")) setSequencePane(null);
}
function createLines() {
    var skillCode = $id("dpsEventSkill").value;
    var templateCode = $id("dpsEventTemplate").value;
    var start = $id("dpsEventStartDate").value;
    var end = $id("dpsEventEndDate").value;

    var projectNo = $id("dpsNewProject").value;
    var taskNo = $id("dpsNewTask").value;
    if (dps_showContext && (!projectNo || !taskNo)) { alert("Select a Project No. and Task No."); return; }
    if (!skillCode) { alert("Select a Skill."); return; }
    if (!templateCode) { alert("Select a Work-Hour Template."); return; }
    if (!start || !end || start > end) { alert("Start Date must be on or before End Date."); return; }

    var payload = {
        jobNo: projectNo,
        jobTaskNo: taskNo,
        skill: skillCode,
        template: templateCode,
        excludedWeekdays: excludedWeekdaysCsv(dps_eventExclusionsDraft),
        startDate: start,
        endDate: end
    };

    $id("dpsCreateStatus").textContent = "Creating...";
    _showDpsLoading();
    Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("OnCreateSequence", [JSON.stringify(payload)]);
}
// Start = today; End = the Nth active day counting from today, N = number of active weekdays
// (Mon..Sun) in the template. Blank template: clears both (force) or leaves them untouched.
function fillDatesFromTemplate(templateCode, force) {
    if (!templateCode) {
        if (force) { $id("dpsEventStartDate").value = ""; $id("dpsEventEndDate").value = ""; }
        return;
    }
    if (!force && $id("dpsEventStartDate").value) return;
    var active = activeWeekdaySet(templateCode);
    var n = Object.keys(active).length;
    var d = new Date();
    $id("dpsEventStartDate").value = isoDateOnly(d);
    var counted = 0;
    while (n > 0) {
        if (active[d.getDay() || 7]) { counted++; if (counted === n) break; }
        d.setDate(d.getDate() + 1);
    }
    $id("dpsEventEndDate").value = isoDateOnly(d);
}
function isoDateOnly(d) {
    var y = d.getFullYear(), m = String(d.getMonth() + 1).padStart(2, "0"), day = String(d.getDate()).padStart(2, "0");
    return y + "-" + m + "-" + day;
}

// -------------------------------------------------------
// AL-callable procedures (Init / LoadData / RefreshTimeline)
// -------------------------------------------------------
// Called from AL before Init by the standalone page 50712 only; rebuilds the view so the extra columns apply.
function SetShowContext(show) {
    dps_showContext = !!show;
    if (!dps_scheduler_ready) return;
    scheduler.createTimelineView(buildTimelineViewConfig(dps_currentTimelineSpanDays));
    applyDayScaleWeekTemplate();
}

// Called from AL (page 50712) with a JSON array of section keys to shade light yellow. Call
// before Init/RefreshTimeline so the next render picks it up.
function SetHighlightedSections(keysJson) {
    dps_highlightKeys = {};
    (ParseJSonTxt(keysJson) || []).forEach(function (k) { dps_highlightKeys[k] = true; });
    if (dps_scheduler_ready) scheduler.render();
    dpsApplyRowHighlight();
}

// The library's row/cell class templates do not reach the data rows here, so tag the row elements
// (.dhx_matrix_line[data-section-id]) directly - now and whenever the timeline re-renders/scrolls.
var dps_hlObserver = null;
function dpsApplyRowHighlight() {
    var root = $id("dps_scheduler_here");
    if (!root) return;
    if (!dps_hlObserver) {
        dps_hlObserver = new MutationObserver(function () { dpsTagRows(root); });
        dps_hlObserver.observe(root, { childList: true, subtree: true });
    }
    dpsTagRows(root);
}
function dpsTagRows(root) {
    var lines = root.querySelectorAll(".dhx_matrix_line[data-section-id]");
    for (var i = 0; i < lines.length; i++) {
        var on = !!dps_highlightKeys[lines[i].getAttribute("data-section-id")];
        if (lines[i].classList.contains("dps-hl-row") !== on) lines[i].classList.toggle("dps-hl-row", on);
    }
}

var dps_defaultSkill = "";
var dps_defaultTemplate = "";
function SetNewSequenceDefaults(skillCode, templateCode) {
    dps_defaultSkill = skillCode || "";
    dps_defaultTemplate = templateCode || "";
}

function Init(sectionsJson,skillsJson, templatesJson, earliestDate, latestDate) {
    try {
        applySections(ParseJSonTxt(sectionsJson) || []);
        dps_skills = ParseJSonTxt(skillsJson) || [];
        dps_templates = ParseJSonTxt(templatesJson) || [];
        resizeTimelineSpan(earliestDate, latestDate);
        scrollToDate(earliestDate);
    } catch (e) {
        console.log("Day Planning Sequence Init error:", e);
    }
}

function LoadData(eventsJson) {
    try {
        dps_isRefreshing = true;
        scheduler.clearAll();
        var events = ParseJSonTxt(eventsJson) || [];
        scheduler.parse(events, "json");
        scheduler.render();
    } catch (e) {
        console.log("Day Planning Sequence LoadData error:", e);
    } finally {
        dps_isRefreshing = false;
        _hideDpsLoading();
    }
}

function RefreshTimeline(sectionsJson, eventsJson, anchorDate, latestDate) {
    try {
        _showDpsLoading();
        dps_isRefreshing = true;
        applySections(ParseJSonTxt(sectionsJson) || []);
        resizeTimelineSpan(anchorDate, latestDate);
        scheduler.clearAll();
        var events = ParseJSonTxt(eventsJson) || [];
        scheduler.parse(events, "json");
        scrollToDate(anchorDate);
        scheduler.render();
        if (dps_pendingAdd) {
            var pending = dps_pendingAdd;
            dps_pendingAdd = null;
            var added = scheduler.getEvents().filter(function (slot) {
                return slot.section_id === pending.section && pending.dates.has(isoDateOnly(slot.start_date));
            }).sort(function (a, b) { return a.start_date - b.start_date; })[0];
            if (added && added.start_date < scheduler.getState().max_date)
                scheduler.matrix.timeline.scrollTo(added.start_date);
        }
        if ($id("dpsSequencePanel").classList.contains("dps-open") && dps_sectionsByKey[dps_selectedSectionKey]) {
            var rangeTimeline = $id("dpsRangeTimeline");
            var scrollLeft = rangeTimeline.scrollLeft;
            renderSequenceRange(dps_sectionsByKey[dps_selectedSectionKey]);
            rangeTimeline.scrollLeft = scrollLeft;
            renderSequenceWeekPattern();
        }
        var status = $id("dpsCreateStatus");
        if (status && status.textContent === "Creating...") {
            status.textContent = "";
            closeLinesDialog();
        }
    } catch (e) {
        console.log("Day Planning Sequence RefreshTimeline error:", e);
    } finally {
        dps_isRefreshing = false;
        _hideDpsLoading();
    }
}

// Called from AL (ControlReady/RefreshTimeline) - see src/dhx/ganttdemo2/wrapper.js's
// LoadHolidaysData for the identical shape/convention this mirrors.
// JSON: [{ "date": "2026-01-01", "description": "New Year", "type": "holiday" }, ...]
function LoadHolidaysData(holidaysJsonTxt) {
    dps_holidays = {};
    try {
        var data = ParseJSonTxt(holidaysJsonTxt) || [];
        data.forEach(function (h) {
            if (h.date) dps_holidays[h.date] = h.description || "Holiday";
        });
    } catch (e) {
        console.log("Day Planning Sequence LoadHolidaysData error:", e);
    }
    if (dps_scheduler_ready) scheduler.render();
    if ($id("dpsSequencePanel") && $id("dpsSequencePanel").classList.contains("dps-open"))
        updateSequenceRange();
}

function dpsDateFmt(date) {
    var y = date.getFullYear(), m = String(date.getMonth() + 1).padStart(2, "0"), d = String(date.getDate()).padStart(2, "0");
    return y + "-" + m + "-" + d;
}

// Same precedence as src/dhx/ganttdemo2/wrapper.js's scale_cell_class/timeline_cell_class:
// weekend (Sat/Sun) wins over a Base Calendar holiday/day-off entry on the same date.
function dpsDayOffClass(date, suffix) {
    var day = date.getDay();
    if (day === 0 || day === 6) return "weekend" + suffix;
    if (dps_holidays[dpsDateFmt(date)]) return "holiday" + suffix;
    return "";
}

// Called from AL (ControlReady) - applies "Daily Optimizer Setup"."Weekend Color"/"Holiday
// Color" (via codeunit 50609's GetWeekendColor/GetHolidayColor) to the weekend-cell/holiday-cell
// shading (see the matching var(--dps-weekend-color)/var(--dps-holiday-color) in style.css).
// Scoped to #dps-root only, same convention as src/dhx/ganttdemo2/wrapper.js's SetDayOffColors.
function SetDayOffColors(weekendColorHex, holidayColorHex) {
    var root = $id("dps-root");
    if (!root) return;
    if (weekendColorHex) root.style.setProperty("--dps-weekend-color", weekendColorHex);
    if (holidayColorHex) root.style.setProperty("--dps-holiday-color", holidayColorHex);
}

// Called from AL (ControlReady) - applies "Daily Optimizer Setup"."Tooltip Background Color"/
// "Tooltip Font Color" (via codeunit 50609's GetTooltipBackgroundColor/GetTooltipFontColor) to
// #dpsTooltip's background/text colour (see the matching var(--tooltip-bg-color)/
// var(--tooltip-font-color) in style.css's .dps-tooltip rule). Scoped to #dps-root (which
// #dpsTooltip is nested under - see buildLayout above), same convention as SetDayOffColors.
function SetTooltipColors(backgroundColorHex, fontColorHex) {
    var root = $id("dps-root");
    if (!root) return;
    if (backgroundColorHex) root.style.setProperty("--tooltip-bg-color", backgroundColorHex);
    if (fontColorHex) root.style.setProperty("--tooltip-font-color", fontColorHex);
}

function applySections(sections) {
    // Left list order: Job, Task, then Skill, then Sequence No. (AL sends them in first-date order).
    sections = sections.slice().sort(function (a, b) {
        return String(a.jobNo || "").localeCompare(String(b.jobNo || "")) ||
            String(a.jobTaskNo || "").localeCompare(String(b.jobTaskNo || "")) ||
            String(a.skill || "").localeCompare(String(b.skill || "")) ||
            (Number(a.sequenceNo) || 0) - (Number(b.sequenceNo) || 0);
    });
    dps_sections = sections;
    dps_sectionsByKey = {};

    var css = sections.map(function (s) {
        dps_sectionsByKey[s.key] = s;
        var token = safeCssToken(s.skill);
        // Full "border" shorthand, not just "border-color": .dhx_cal_event_line/.dhx_matrix_cell
        // have no border-width/border-style anywhere in dhtmlxscheduler.css's own defaults (only
        // border-radius), so a bare border-color rule renders no visible border at all (default
        // border-style is "none") - confirmed by grepping the vendor CSS before writing this fix.
        return ".dps-skill-" + token + "{background:" + (s.color || "#2457d6") + "!important;border:1px solid " + (s.borderColor || s.color || "#2457d6") + "!important;color:" + (s.fontColor || "#000000") + "!important;}";
    }).join("\n");
    var styleEl = $id("dps-skill-colors");
    if (!styleEl) {
        styleEl = document.createElement("style");
        styleEl.id = "dps-skill-colors";
        document.head.appendChild(styleEl);
    }
    styleEl.textContent = css;

    var mapped = sections.map(function (s) { return { key: s.key, label: s.label, jobNo: s.jobNo, jobTaskNo: s.jobTaskNo, skill: s.skillDescription || s.skill, sequenceNo: s.sequenceNo }; });
    scheduler.updateCollection("sections", mapped);

    if (dps_selectedSectionKey && !dps_sectionsByKey[dps_selectedSectionKey]) {
        dps_selectedSectionKey = null;
        syncOverviewSequenceMarker();
        refreshCommittedSelection();
        if ($id("dpsSequencePanel").classList.contains("dps-open"))
            showSequencePrompt();
    }

    updateFilterIndicator();
}

// Called from AL (page 50712 only) with the active filter expressions, after each data push.
function SetFilterInfo(jobFilter, jobTaskFilter, skillFilter, resourceFilter, periodFrom, periodTo) {
    dps_filterInfo = { job: jobFilter, task: jobTaskFilter, skill: skillFilter, resource: resourceFilter, periodFrom: periodFrom, periodTo: periodTo };
    updateFilterIndicator();
}

// Standard funnel filter button (same look/text as the Gantt / resource panels): hover shows the
// "Filter applied:" lines (+ period of the loaded sections), click raises OnFilterIconClick so AL
// opens the Job/Task/Skill/Resource filter dialog; the red X raises OnClearFilter (clears every filter, so all Day Planning lines are shown).
// Standalone page 50712 only (dps_showContext) - the card part stays scoped to its own task.
function updateFilterIndicator() {
    var slot = $id("dpsFilterSlot");
    if (!slot) return;
    slot.innerHTML = "";
    if (!dps_showContext) return;

    var fi = dps_filterInfo || {};
    var lines = [];
    if (fi.job) lines.push("Job = " + escapeHtml(fi.job));
    if (fi.task) lines.push("Task = " + escapeHtml(fi.task));
    if (fi.skill) lines.push("Skill = " + escapeHtml(fi.skill));
    if (fi.resource) lines.push("Resource = " + escapeHtml(fi.resource));
    // Period line: the filtered period when one is set, else the span of the loaded data
    var from = fi.periodFrom || dps_sections.map(function (s) { return s.minDate; }).sort()[0];
    var to = fi.periodTo || dps_sections.map(function (s) { return s.maxDate; }).sort().pop();
    if (lines.length && from && to) lines.push(escapeHtml(from) + " to " + escapeHtml(to));
    else if (fi.periodFrom || fi.periodTo) lines.push("Period = " + escapeHtml(fi.periodFrom || "...") + " to " + escapeHtml(fi.periodTo || "..."));
    var tipHtml = lines.length
        ? "<b>Filter applied:</b><br/>" + lines.join("<br/>")
        : "Click to filter by Job / Job Task / Skill / Resource";

    var btn = document.createElement("button");
    btn.type = "button";
    btn.className = "dps-filter-icon";
    btn.innerHTML = '<svg viewBox="0 0 24 24" width="12" height="12"><path d="M3 4h18l-7.2 8.6v6.4l-3.6 1.8v-8.2z" fill="#fff"/></svg>';
    btn.addEventListener("mouseenter", function (e) {
        var t = $id("dpsTooltip");
        t.innerHTML = '<div class="dps-standard-tooltip">' + tipHtml + '</div>';
        positionTooltip(t, e.clientX, e.clientY);
    });
    btn.addEventListener("mouseleave", hideTooltip);
    btn.addEventListener("click", function () {
        hideTooltip();
        Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("OnFilterIconClick", []);
    });
    slot.appendChild(btn);

    if (lines.length) {
        var reset = document.createElement("button");
        reset.type = "button";
        reset.className = "dps-filter-reset";
        reset.title = "Click to Reset Filter";
        reset.textContent = "✕";
        reset.addEventListener("click", function () {
            Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("OnClearFilter", []);
        });
        slot.appendChild(reset);
    }
}

function scrollToDate(dateValue) {
    if (!dateValue) return;
    var d = (dateValue instanceof Date) ? dateValue : new Date(dateValue);
    if (isNaN(d.getTime())) return;

    var scrollTarget = new Date(d);
    scrollTarget.setHours(6, 0, 0, 0);
    var view = scheduler.matrix && scheduler.matrix.timeline;
    if (view) view.scroll_position = scrollTarget;

    var focusDate = new Date(d);
    focusDate.setHours(0, 0, 0, 0);
    scheduler.setCurrentView(focusDate, "timeline");
}
