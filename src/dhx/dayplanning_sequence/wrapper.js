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
var dps_scheduler_ready = false;   // true once scheduler.init() has run
var dps_isRefreshing = false;      // guard: true while a full AL-driven reload is being applied,
                                    // so onEventChanged/onEventDeleted fired by that reload's own
                                    // scheduler.parse()/clearAll() churn don't re-raise events to AL
var dps_sections = [];             // last section list pushed by AL (raw objects incl. extra props)
var dps_sectionsByKey = {};        // key -> section object, for quick lookup (Modify-panel prefill)
var dps_skills = [];               // [{code, description, color}]
var dps_templates = [];            // [{code, description, activeWeekdays: "1|2|3|4|5"}]
var dps_selectedSectionKey = null;
var dps_exclusionsDraft = {};      // Modify panel: Set-like map of excluded ISO weekday numbers
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
            '<button type="button" class="dps-btn" id="dpsModifyBtn">Modify sequence</button>' +
            '<button type="button" class="dps-btn dps-primary" id="dpsNewBtn">New sequence</button>' +
        '</div>' +
        '<div id="dps-stage">' +
            '<aside class="dps-sidepanel" id="dpsSequencePanel">' +
                '<div class="dps-panelhead">' +
                    '<div class="dps-paneltitle">Modify sequence</div>' +
                    '<button type="button" class="dps-btn" id="dpsClosePanel">&times;</button>' +
                '</div>' +
                '<div class="dps-panelbody">' +
                    '<div class="dps-info"><div class="dps-lbl">Skill / Sequence</div><div class="dps-val" id="dpsInfoSkillSeq"></div></div>' +
                    '<div class="dps-field"><label>Work-Hour Template</label><select id="dpsSeqTemplate"></select></div>' +
                    '<div class="dps-field"><label>Exclude days</label><div class="dps-exclude-grid" id="dpsExcludeDays"></div></div>' +
                    '<div class="dps-field"><label>Start Date</label><input type="date" id="dpsSeqStart"></div>' +
                    '<div class="dps-field"><label>End Date</label><input type="date" id="dpsSeqEnd"></div>' +
                '</div>' +
                '<div class="dps-panelactions">' +
                    '<button type="button" class="dps-btn" id="dpsCancelPanel">Cancel</button>' +
                    '<button type="button" class="dps-btn dps-primary" id="dpsApplySequence">Apply</button>' +
                '</div>' +
            '</aside>' +
            '<div id="dps-scheduler-card">' +
                '<div id="dps_scheduler_here" class="dhx_cal_container"></div>' +
            '</div>' +
        '</div>' +
        '<div class="dps-dialog-backdrop" id="dpsLinesDialog">' +
            '<div class="dps-dialog">' +
                '<div class="dps-panelhead">' +
                    '<div class="dps-paneltitle">New sequence</div>' +
                    '<button type="button" class="dps-btn" id="dpsCloseLinesDialog">&times;</button>' +
                '</div>' +
                '<div class="dps-panelbody">' +
                    '<div class="dps-field"><label>Skill</label><select id="dpsEventSkill"></select></div>' +
                    '<div class="dps-field"><label>Work-Hour Template</label><select id="dpsEventTemplate"></select></div>' +
                    '<div class="dps-field"><label>Exclude days</label><div class="dps-exclude-grid" id="dpsEventExcludeDays"></div></div>' +
                    '<div class="dps-field"><label>Start Date</label><input type="date" id="dpsEventStartDate"></div>' +
                    '<div class="dps-field"><label>End Date</label><input type="date" id="dpsEventEndDate"></div>' +
                '</div>' +
                '<div class="dps-status" id="dpsCreateStatus"></div>' +
                '<div class="dps-panelactions">' +
                    '<button type="button" class="dps-btn" id="dpsCancelLines">Cancel</button>' +
                    '<button type="button" class="dps-btn dps-primary" id="dpsCreateLines">Create</button>' +
                '</div>' +
            '</div>' +
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

    scheduler.config.drag_create = false;  // no ad-hoc bar creation by drag; new bars only via
                                            // "New sequence" (GenerateSequence) or "Modify
                                            // sequence" (RegenerateSequence) batch operations
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

    // Keep only the working-time cells 06-18, per spec's compact timeline window.
    scheduler.ignore_timeline = function (date) {
        var hour = date.getHours();
        return hour < 6 || hour >= 18;
    };

    scheduler.templates.timeline_cell_class = function (evs, date) {
        return dpsDayOffClass(date, "-cell");
    };
    scheduler.templates.timeline_scalex_class = function (date) {
        return dpsDayOffClass(date, "-scale");
    };
    scheduler.templates.timeline_second_scalex_class = function (date) {
        return dpsDayOffClass(date, "-scale");
    };

    scheduler.templates.timeline_scale_label = function (key, label, section) {
        var sectionKey = (section && section.key) || key;
        return '<div class="dps-row-label" data-section-key="' + escapeHtmlAttr(sectionKey) + '">' + escapeHtml(label) + '</div>';
    };

    scheduler.templates.event_class = function (start, end, event) {
        return "dps-event dps-skill-" + safeCssToken(event.skill);
    };
    scheduler.templates.event_bar_text = function (start, end, event) {
        return event.text || "";
    };

    scheduler.attachEvent("onBeforeLightbox", function () { return false; });

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

    scheduler.attachEvent("onEventDeleted", function (id) {
        if (dps_isRefreshing) return true;
        Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("OnEventDeleted", [String(id)]);
        return true;
    });

    scheduler.attachEvent("onDblClick", function (id, e) {
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
function buildTimelineViewConfig(spanDays) {
    return {
        name: "timeline",
        render: "bar",
        dx: 190,

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
// Recomputes the timeline's total horizontal span (x_size) from the real earliest/latest Plan
// Date of whatever data was just loaded, so every existing Day Planning line for this Job
// No./Job Task No. is always reachable via the horizontal scroll bar - no fixed cap. Falls back
// to a 31-day minimum span (same as the original hard-coded default) when dates are missing or
// span less than that, so a task with little/no data still gets a reasonably sized timeline
// rather than a degenerate near-zero-width one. Adds a 7-day buffer past the latest date so the
// last bar isn't rendered flush against the scrollable edge. Re-invoking scheduler.
// createTimelineView with the same view name ("timeline") is DHTMLX's supported way to
// reconfigure an existing view at runtime - it does not lose the underlying "sections" DataStore
// (scheduler.serverList("sections"), already kept in sync separately by applySections's own
// scheduler.updateCollection call). Only actually rebuilds the view when the required span
// changed, since createTimelineView is not free and both Init and RefreshTimeline call this on
// every load.
// -------------------------------------------------------
function resizeTimelineSpan(earliestDateValue, latestDateValue) {
    var MIN_SPAN_DAYS = 31;
    var BUFFER_DAYS = 7;
    var MS_PER_DAY = 24 * 60 * 60 * 1000;

    var start = toDateOrNull(earliestDateValue);
    var end = toDateOrNull(latestDateValue);

    var spanDays = MIN_SPAN_DAYS;
    if (start && end) {
        var diffDays = Math.round((end.getTime() - start.getTime()) / MS_PER_DAY) + 1; // inclusive of both ends
        spanDays = Math.max(MIN_SPAN_DAYS, diffDays + BUFFER_DAYS);
    }

    if (spanDays === dps_currentTimelineSpanDays) return;
    dps_currentTimelineSpanDays = spanDays;
    scheduler.createTimelineView(buildTimelineViewConfig(spanDays));
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
        if (!label) return;
        dps_selectedSectionKey = label.getAttribute("data-section-key");
        openSequencePanel(dps_selectedSectionKey);
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

function showSlotTooltip(ev, x, y) {
    var t = $id("dpsTooltip");
    t.innerHTML =
        '<div class="dps-tooltip-head">' + escapeHtml(ev.skill) + '</div>' +
        '<div class="dps-tooltip-body">' +
            '<div class="dps-tooltip-row"><div class="dps-tooltip-label">Time</div><div class="dps-tooltip-value">' + escapeHtml(ev.text) + '</div></div>' +
        '</div>';
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
    $id("dpsModifyBtn").onclick = function () { openSequencePanel(dps_selectedSectionKey); };
    $id("dpsNewBtn").onclick = openLinesDialog;

    $id("dpsClosePanel").onclick = closeSequencePanel;
    $id("dpsCancelPanel").onclick = closeSequencePanel;
    $id("dpsApplySequence").onclick = applySequence;
    $id("dpsSeqTemplate").onchange = function () {
        renderExcludeGrid("dpsExcludeDays", dps_exclusionsDraft, $id("dpsSeqTemplate").value);
    };

    $id("dpsCloseLinesDialog").onclick = closeLinesDialog;
    $id("dpsCancelLines").onclick = closeLinesDialog;
    $id("dpsCreateLines").onclick = createLines;
    $id("dpsEventTemplate").onchange = function () {
        renderExcludeGrid("dpsEventExcludeDays", dps_eventExclusionsDraft, $id("dpsEventTemplate").value);
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
function openSequencePanel(sectionKey) {
    if (!sectionKey) return;
    var section = dps_sectionsByKey[sectionKey];
    if (!section) return;

    hideTooltip();
    dps_selectedSectionKey = sectionKey;
    dps_exclusionsDraft = {};

    $id("dpsInfoSkillSeq").textContent = (section.skillDescription || section.skill) + " · Seq " + section.sequenceNo;
    populateSelect("dpsSeqTemplate", dps_templates, null);
    $id("dpsSeqTemplate").value = ""; // per spec: no remembered template - user must (re)confirm
    renderExcludeGrid("dpsExcludeDays", dps_exclusionsDraft, "");
    $id("dpsSeqStart").value = section.minDate || "";
    $id("dpsSeqEnd").value = section.maxDate || "";

    $id("dpsSequencePanel").classList.add("dps-open");
}
function closeSequencePanel() {
    $id("dpsSequencePanel").classList.remove("dps-open");
}
function applySequence() {
    var section = dps_sectionsByKey[dps_selectedSectionKey];
    if (!section) return;

    var start = $id("dpsSeqStart").value;
    var end = $id("dpsSeqEnd").value;
    var templateCode = $id("dpsSeqTemplate").value;

    if (!start || !end || start > end) { alert("Start Date must be on or before End Date."); return; }
    if (!templateCode) { alert("Select a Work-Hour Template."); return; }

    var payload = {
        skill: section.skill,
        sequenceNo: section.sequenceNo,
        template: templateCode,
        excludedWeekdays: excludedWeekdaysCsv(dps_exclusionsDraft),
        startDate: start,
        endDate: end
    };

    closeSequencePanel();
    _showDpsLoading();
    Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("OnModifySequence", [JSON.stringify(payload)]);
}

// ---- New sequence dialog ----
function openLinesDialog() {
    populateSelect("dpsEventSkill", dps_skills, "Select skill...");
    populateSelect("dpsEventTemplate", dps_templates, "Select template...");
    $id("dpsEventSkill").value = "";
    $id("dpsEventTemplate").value = "";
    dps_eventExclusionsDraft = {};
    renderExcludeGrid("dpsEventExcludeDays", dps_eventExclusionsDraft, "");

    var tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    $id("dpsEventStartDate").value = isoDateOnly(tomorrow);
    $id("dpsEventEndDate").value = "";

    $id("dpsCreateStatus").textContent = "";
    $id("dpsLinesDialog").classList.add("dps-open");
}
function closeLinesDialog() {
    $id("dpsLinesDialog").classList.remove("dps-open");
}
function createLines() {
    var skillCode = $id("dpsEventSkill").value;
    var templateCode = $id("dpsEventTemplate").value;
    var start = $id("dpsEventStartDate").value;
    var end = $id("dpsEventEndDate").value;

    if (!skillCode) { alert("Select a Skill."); return; }
    if (!templateCode) { alert("Select a Work-Hour Template."); return; }
    if (!start || !end || start > end) { alert("Start Date must be on or before End Date."); return; }

    var payload = {
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
function isoDateOnly(d) {
    var y = d.getFullYear(), m = String(d.getMonth() + 1).padStart(2, "0"), day = String(d.getDate()).padStart(2, "0");
    return y + "-" + m + "-" + day;
}

// -------------------------------------------------------
// AL-callable procedures (Init / LoadData / RefreshTimeline)
// -------------------------------------------------------
function Init(sectionsJson, skillsJson, templatesJson, earliestDate, latestDate) {
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
        var status = $id("dpsCreateStatus");
        if (status) status.textContent = "";
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

function applySections(sections) {
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

    var mapped = sections.map(function (s) { return { key: s.key, label: s.label }; });
    scheduler.updateCollection("sections", mapped);

    if (dps_selectedSectionKey && !dps_sectionsByKey[dps_selectedSectionKey]) {
        dps_selectedSectionKey = null;
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
