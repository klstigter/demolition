// ============================================================
// State
// ============================================================
var scheduler_here;          // DOM element reference (readiness flag)
var allResources  = [];      // [ { id, name, group } ]
var allEvents     = [];      // [ { id, resource_id, classname, start_date, end_date, text, type } ]
var allCapacity   = [];      // [ { resource_id, start_date, end_date } ]
var checkedResources = {};   // { resourceId: true|false }
var showDayTask      = true;    // controlled by BC toggle
var showCapacity     = true;    // controlled by BC toggle
var _initInProgress  = true;    // suppresses onViewChange during Init()

// ============================================================
// BOOT – called by startupScript.js
// ============================================================
window.BOOT = function() {
    try {
        // ---- Inject context-menu CSS ----
        (function() {
            var s = document.createElement('style');
            s.textContent =
                '#dhx-ctx-menu{position:fixed;z-index:99999;background:#fff;border:1px solid #c8c8c8;' +
                'border-radius:4px;box-shadow:0 4px 12px rgba(0,0,0,.18);padding:4px 0;min-width:190px;' +
                'font-family:"Segoe UI",sans-serif;font-size:13px;user-select:none;}' +
                '#dhx-ctx-menu.hidden{display:none;}' +
                '.dhx-ctx-item{display:flex;align-items:center;gap:8px;padding:7px 14px;cursor:pointer;color:#333;white-space:nowrap;}' +
                '.dhx-ctx-item:hover{background:#f0f4ff;color:#1a56db;}' +
                '.dhx-ctx-item.ctx-cancel{color:#c00;}' +
                '.dhx-ctx-item.ctx-cancel:hover{background:#fff0f0;}' +
                '.dhx-ctx-separator{height:1px;background:#e0e0e0;margin:4px 0;}' +
                '.dhx-ctx-icon{width:16px;height:16px;display:inline-flex;align-items:center;justify-content:center;flex-shrink:0;}';
            document.head.appendChild(s);
        })();

        // ---- Outer layout: flex row ----
        var addin = document.getElementById("controlAddIn");
        addin.style.cssText = "width:100%;height:100%;margin:0;padding:0;display:flex;flex-direction:row;overflow:hidden;";

        // Left: resource selection panel
        var leftPanel = document.createElement("div");
        leftPanel.id = "resource-panel";
        addin.appendChild(leftPanel);

        // Centre: scheduler panel
        var rightPanel = document.createElement("div");
        rightPanel.id = "scheduler-panel";
        addin.appendChild(rightPanel);

        // ---- Scheduler container (DHTMLX requires these inner divs) ----
        var sched = document.createElement("div");
        sched.id = "scheduler_here";
        sched.className = "dhx_cal_container";
        sched.style.cssText = "width:100%;height:100%;";
        sched.innerHTML =
            '<div class="dhx_cal_navline">' +
                '<div class="dhx_cal_prev_button"></div>' +
                '<div class="dhx_cal_next_button"></div>' +
                '<div class="dhx_cal_today_button"></div>' +
                '<div class="dhx_cal_date"></div>' +
                '<div class="dhx_cal_tab" data-tab="day"></div>' +
                '<div class="dhx_cal_tab" data-tab="week"></div>' +
                '<div class="dhx_cal_tab" data-tab="month"></div>' +
            '</div>' +
            '<div class="dhx_cal_header"></div>' +
            '<div class="dhx_cal_data"></div>';
        rightPanel.appendChild(sched);
        scheduler_here = sched;

        // ---- Check library ----
        if (typeof scheduler === "undefined") {
            console.error("DHX scheduler library (dhtmlxscheduler.js) not found. Please include it in ControlAddIn Scripts.");
            return;
        }

        // ---- Plugins ----
        scheduler.plugins({ tooltip: true });

        scheduler.config.cascade_event_display = true;
        scheduler.config.start_on_monday       = true;
        scheduler.config.dblclick_create       = false; // no new event on empty-area dblclick
        scheduler.config.details_on_dblclick   = false; // prevent lightbox on dblclick
        scheduler.config.icons_select          = [];   // remove details/edit/delete icons on event click

        // Single click → suppress expansion / lightbox / selection highlight
        scheduler.attachEvent("onClick", function(id, e) {
            return false;
        });

        // Double-click on an event → fire BC trigger
        // Synthetic capacity-only events (id starts with "cap_") are skipped.
        scheduler.attachEvent("onDblClick", function(id, e) {
            if (String(id).indexOf("cap_") === 0) return false;
            var ev = scheduler.getEvent(id);
            if (!ev) return false;
            var resourceId = (ev.resource_id) ? String(ev.resource_id) : "";
            Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("OnEventDoubleClick", [String(id), resourceId]);
            return false; // prevent lightbox from opening
        });

        scheduler.templates.event_class = function(start, end, ev) {
            return ev.classname || "";
        };

        // Custom tooltip content: Resource, Date, Capacity times, DayTask times
        scheduler.templates.tooltip_text = function(start, end, ev) {
            var resId   = String(ev.resource_id || "");
            var resName = resId;
            for (var ri = 0; ri < allResources.length; ri++) {
                if (String(allResources[ri].id) === resId) { resName = allResources[ri].name; break; }
            }

            var evDate  = (start instanceof Date) ? start : ToDate(start);
            var cap     = null;
            if (evDate) {
                for (var ci = 0; ci < allCapacity.length; ci++) {
                    var c = allCapacity[ci];
                    if (String(c.resource_id) !== resId) continue;
                    var cs = ToDate(c.start_date);
                    if (cs && cs.toDateString() === evDate.toDateString()) { cap = c; break; }
                }
            }

            var months = ["January","February","March","April","May","June",
                          "July","August","September","October","November","December"];
            var dateStr = evDate ? (evDate.getDate() + " " + months[evDate.getMonth()] + " " + evDate.getFullYear()) : "";

            function fmt(dt) {
                var d = (dt instanceof Date) ? dt : ToDate(dt);
                if (!d) return "—";
                return ("0" + d.getHours()).slice(-2) + ":" + ("0" + d.getMinutes()).slice(-2);
            }

            var html = '<div class="dhx-tt">';
            html += '<div class="dhx-tt-res">' + resName + '</div>';
            html += '<div class="dhx-tt-date">' + dateStr + '</div>';

            if (cap) {
                html += '<div class="dhx-tt-section">Capacity</div>';
                html += '<div class="dhx-tt-rows">';
                html += '<div class="dhx-tt-row"><span>Start:</span><span>' + fmt(cap.start_date) + '</span></div>';
                html += '<div class="dhx-tt-row"><span>End:</span><span>' + fmt(cap.end_date) + '</span></div>';
                html += '</div>';
            }

            var isAvailable = String(ev.id).indexOf("cap_") === 0;
            if (!isAvailable) {
                var dayStart = null, dayEnd = null, taskLabels = [];
                for (var ei = 0; ei < allEvents.length; ei++) {
                    var e2 = allEvents[ei];
                    if (String(e2.resource_id) !== resId) continue;
                    var es = ToDate(e2.start_date);
                    if (!es || !evDate || es.toDateString() !== evDate.toDateString()) continue;
                    var ee = ToDate(e2.end_date);
                    if (!dayStart || es < dayStart) dayStart = es;
                    if (!dayEnd   || ee > dayEnd)   dayEnd   = ee;
                    if (e2.text) taskLabels.push(e2.text);
                }
                if (dayStart) {
                    html += '<div class="dhx-tt-section">DayTask</div>';
                    html += '<div class="dhx-tt-rows">';
                    html += '<div class="dhx-tt-row"><span>Start:</span><span>' + fmt(dayStart) + '</span></div>';
                    html += '<div class="dhx-tt-row"><span>End:</span><span>' + fmt(dayEnd) + '</span></div>';
                    if (taskLabels.length)
                        html += '<div class="dhx-tt-row"><span>Task:</span><span>' + taskLabels.join(", ") + '</span></div>';
                    html += '</div>';
                }
            }

            html += '</div>';
            return html;
        };

        // Progress overlay: dark background = capacity, white segments = each task,
        // red-orange segment = overtime portion beyond capacity end
        scheduler.templates.event_text = function(start, end, ev) {
            if (ev._segments && ev._segments.length > 0) {
                var html = '<div class="ev-progress-wrap">';
                ev._segments.forEach(function(seg) {
                    if (parseFloat(seg.fillPct) > 0) {
                        html += '<div class="ev-task-fill" style="top:' + seg.offsetPct + '%;height:' + seg.fillPct + '%"></div>';
                    }
                });
                if (ev._overflow_pct && parseFloat(ev._overflow_pct) > 0) {
                    html += '<div class="ev-overtime-fill" style="top:' + ev._cap_end_pct + '%;height:' + ev._overflow_pct + '%"></div>';
                }
                html += '<span class="ev-label">' + (ev._task_text || '') + '</span>';
                html += '</div>';
                return html;
            }
            return ev.text || '';
        };

        // ---- Load dummy data ----
        allResources = [];
        allEvents    = [];
        allCapacity  = [];
        allResources.forEach(function(r) { checkedResources[r.id] = true; });

        // ---- Build resource selection panel ----
        BuildResourcePanel(leftPanel);

        // ---- Fire OnDateRangeChanged when user navigates (Today/Prev/Next/Day/Week/Month) ----
        scheduler.attachEvent("onViewChange", function(new_mode, new_date) {
            if (_initInProgress) return;
            var state    = scheduler.getState();
            var startStr = FmtDateStr(state.min_date);
            var endDate  = new Date(state.max_date.getTime() - 86400000); // max_date is exclusive
            var endStr   = FmtDateStr(endDate);
            Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("OnDateRangeChanged", [startStr, endStr]);
        });

        // ---- Init scheduler – week view, week of 2026-03-09 ----
        scheduler.init("scheduler_here", new Date(2026, 2, 9), "week");

        // ---- Wire right-click context menu ----
        setupContextMenu();

        // ---- Show all events ----
        RefreshSchedulerEvents();

        Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("ControlReady", []);

    } catch (e) {
        console.warn("BOOT warning:", e);
    }
};

// ============================================================
// Build the left resource-selection panel
// ============================================================
function BuildResourcePanel(container) {
    container.innerHTML = "";

    // Header
    var hdr = document.createElement("div");
    hdr.className = "rp-header";
    hdr.textContent = "Resources";
    container.appendChild(hdr);

    // Group resources by group field
    var groups = {};
    var groupOrder = [];
    allResources.forEach(function(r) {
        var g = r.group || "—";
        if (!groups[g]) { groups[g] = []; groupOrder.push(g); }
        groups[g].push(r);
    });

    groupOrder.forEach(function(groupName) {
        var members = groups[groupName];

        // Group row
        var gRow = document.createElement("div");
        gRow.className = "rp-group";

        var gCb = document.createElement("input");
        gCb.type = "checkbox";
        gCb.className = "rp-group-cb";
        gCb.checked = members.every(function(r) { return checkedResources[r.id]; });

        gCb.addEventListener("change", function() {
            members.forEach(function(r) { checkedResources[r.id] = gCb.checked; });
            // sync child checkboxes
            gRow.parentElement.querySelectorAll(".rp-resource-cb[data-group='" + groupName + "']").forEach(function(cb) {
                cb.checked = gCb.checked;
            });
            RefreshSchedulerEvents();
        });

        gRow.appendChild(gCb);
        var gLabel = document.createElement("span");
        gLabel.className = "rp-group-label";
        gLabel.textContent = groupName;
        gRow.appendChild(gLabel);
        container.appendChild(gRow);

        // Resource rows
        members.forEach(function(res) {
            var rRow = document.createElement("div");
            rRow.className = "rp-resource";

            var rCb = document.createElement("input");
            rCb.type = "checkbox";
            rCb.className = "rp-resource-cb";
            rCb.checked = !!checkedResources[res.id];
            rCb.dataset.resourceId = res.id;
            rCb.dataset.group = groupName;

            rCb.addEventListener("change", function() {
                checkedResources[res.id] = rCb.checked;
                // update group checkbox state
                var allChecked = members.every(function(r) { return checkedResources[r.id]; });
                var anyChecked = members.some(function(r)  { return checkedResources[r.id]; });
                gCb.checked       = allChecked;
                gCb.indeterminate = !allChecked && anyChecked;
                RefreshSchedulerEvents();
            });

            rRow.appendChild(rCb);
            var rLabel = document.createElement("span");
            rLabel.className = "rp-resource-label";
            rLabel.textContent = res.name;
            // Double-click on resource name → open Resource Card in BC
            (function(resourceId) {
                rLabel.addEventListener("dblclick", function(e) {
                    e.stopPropagation();
                    Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("OnResourceDoubleClick", [String(resourceId)]);
                });
            })(res.id);
            rRow.appendChild(rLabel);
            container.appendChild(rRow);
        });
    });
}

// ============================================================
// Re-parse events for checked resources.
// Groups all day-tasks by resource+date so each resource produces
// AT MOST ONE scheduler event per day (prevents intra-resource
// cascade). Multiple tasks on the same day become separate fill
// segments inside the single capacity block.
// ============================================================
function RefreshSchedulerEvents() {
    if (typeof scheduler === "undefined") return;
    scheduler.clearAll();

    var filtered = showDayTask ? allEvents.filter(function(ev) {
        return !!checkedResources[ev.resource_id];
    }) : [];

    var consumedCap = {};

    // --- Step 1: group tasks by resource_id + date ---
    var groups = {};      // key -> { resource_id, date, tasks[], firstEv }
    var groupOrder = [];  // preserves insertion order
    filtered.forEach(function(ev) {
        var d = ToDate(ev.start_date);
        if (!d) return;
        var key = String(ev.resource_id) + "|" + d.toDateString();
        if (!groups[key]) {
            groups[key] = { resource_id: String(ev.resource_id), date: d, tasks: [], firstEv: ev };
            groupOrder.push(key);
        }
        var ts = ToDate(ev.start_date);
        var te = ToDate(ev.end_date);
        if (ts && te) groups[key].tasks.push({ start: ts, end: te, text: ev.text || "" });
    });

    // --- Step 2: merge each group with its capacity entry ---
    var merged = [];
    groupOrder.forEach(function(key) {
        var g = groups[key];

        var startTimes = g.tasks.map(function(t) { return t.start.getTime(); });
        var earliestMs = Math.min.apply(null, startTimes);

        // Find the capacity entry for this resource+date (only when showCapacity is on)
        var cap = null;
        if (!showCapacity) { /* skip capacity lookup */ }
        else for (var i = 0; i < allCapacity.length; i++) {
            var c = allCapacity[i];
            if (String(c.resource_id) !== g.resource_id) continue;
            var cStart = ToDate(c.start_date);
            var cEnd   = ToDate(c.end_date);
            if (!cStart || !cEnd) continue;
            if (cStart.toDateString() === g.date.toDateString() &&
                cStart.getTime() <= earliestMs) {
                cap = { start: cStart, end: cEnd, classname: c.classname || "", idx: i };
                break;
            }
        }

        if (cap) {
            consumedCap[cap.idx] = true;

            // Block spans cap.start → max(cap.end, latest task end)
            var endTimes   = g.tasks.map(function(t) { return t.end.getTime(); });
            var latestMs   = Math.max.apply(null, endTimes);
            var blockStart = cap.start;
            var blockEnd   = new Date(Math.max(cap.end.getTime(), latestMs));
            var totalMs    = blockEnd.getTime() - blockStart.getTime();

            // One fill segment per task
            var segments = [];
            g.tasks.forEach(function(t) {
                var segStartMs    = Math.max(t.start.getTime(), blockStart.getTime());
                var segEndInCapMs = Math.min(t.end.getTime(), cap.end.getTime());
                var offsetPct = totalMs > 0 ? ((segStartMs - blockStart.getTime()) / totalMs * 100).toFixed(1) : "0.0";
                var fillPct   = totalMs > 0 ? (Math.max(0, segEndInCapMs - segStartMs) / totalMs * 100).toFixed(1) : "0.0";
                segments.push({ offsetPct: offsetPct, fillPct: fillPct });
            });

            // Overtime: tasks extending past cap.end
            var capEndPct   = totalMs > 0 ? ((cap.end.getTime() - blockStart.getTime()) / totalMs * 100).toFixed(1) : "100.0";
            var overflowMs  = Math.max(0, latestMs - cap.end.getTime());
            var overflowPct = totalMs > 0 ? (overflowMs / totalMs * 100).toFixed(1) : "0.0";

            var labels = g.tasks.map(function(t) { return t.text; }).filter(Boolean).join(" \u00b7 ");

            merged.push(Object.assign({}, g.firstEv, {
                start_date:    blockStart,
                end_date:      blockEnd,
                classname:     cap.classname,
                _segments:     segments,
                _cap_end_pct:  capEndPct,
                _overflow_pct: overflowPct,
                _task_text:    labels
            }));

        } else {
            // No capacity: merge all tasks for this resource+day into one block
            var allStartMs2 = g.tasks.map(function(t) { return t.start.getTime(); });
            var allEndMs2   = g.tasks.map(function(t) { return t.end.getTime(); });
            var labels2     = g.tasks.map(function(t) { return t.text; }).filter(Boolean).join(" \u00b7 ");
            merged.push(Object.assign({}, g.firstEv, {
                start_date: new Date(Math.min.apply(null, allStartMs2)),
                end_date:   new Date(Math.max.apply(null, allEndMs2)),
                text:       labels2
            }));
        }
    });

    // --- Step 3: Available blocks for capacity entries with no day task ---
    // Build set of resource+date combos covered by tasks to suppress extra blocks
    var taskSlots = {};
    groupOrder.forEach(function(key) {
        var g = groups[key];
        taskSlots[g.resource_id + "|" + g.date.toDateString()] = true;
    });

    if (showCapacity) {
        allCapacity.forEach(function(c, i) {
            if (consumedCap[i]) return;
            if (!checkedResources[c.resource_id]) return;
            var cStart = ToDate(c.start_date);
            if (showDayTask && cStart && taskSlots[String(c.resource_id) + "|" + cStart.toDateString()]) return;
            merged.push({
                id:          "cap_" + i,
                resource_id: c.resource_id,
                classname:   (c.classname ? c.classname + " " : "") + "cap-available",
                start_date:  c.start_date,
                end_date:    c.end_date,
                text:        "Available",
                type:        "capacity"
            });
        });
    }

    if (merged.length > 0) scheduler.parse(merged);

    // Adjust the visible hour range based on earliest event start.
    // Defer by one tick so scheduler finishes parsing before we update config.
    setTimeout(AdjustFirstHour, 0);
}

// ============================================================
// Shrink the Y-axis so it starts at the earliest event hour
// (across both day-tasks and capacities currently in allEvents
// and allCapacity for checked resources).
// Falls back to first_hour = 0 when there are no visible events.
// Month view is skipped – it has no scrollable hour axis.
// ============================================================
function AdjustFirstHour() {
    if (!scheduler_here) return;
    var state = scheduler.getState ? scheduler.getState() : {};
    if (state.mode === 'month') return;

    var minHour = null;

    // Scan daytask events for checked resources
    allEvents.forEach(function(ev) {
        if (!checkedResources[ev.resource_id]) return;
        var d = ToDate(ev.start_date);
        if (!d) return;
        var h = d.getHours();
        if (minHour === null || h < minHour) minHour = h;
    });

    // Scan capacity entries for checked resources
    allCapacity.forEach(function(c) {
        if (!checkedResources[c.resource_id]) return;
        var d = ToDate(c.start_date);
        if (!d) return;
        var h = d.getHours();
        if (minHour === null || h < minHour) minHour = h;
    });

    var newFirst = (minHour !== null) ? minHour : 0;

    // Only re-render when the value actually changes to avoid loops
    if (scheduler.config.first_hour !== newFirst) {
        scheduler.config.first_hour = newFirst;
        scheduler.updateView();
    }
}

// ============================================================
// AL-callable: Init(elementsJson, startDate)
//   elementsJson – JSON string: { data: [ { id, name, group }, … ] }
//                  pass empty string "" to keep dummy resources
//   startDate    – BC Date (passed as epoch ms or ISO string)
// ============================================================
function Init(elementsJson, startDate) {
    _initInProgress = true;
    try {
        var parsed = ParseJsonTxt(elementsJson);
        if (parsed && Array.isArray(parsed.data) && parsed.data.length > 0) {
            allResources = parsed.data;
            checkedResources = {};
            allResources.forEach(function(r) { checkedResources[r.id] = true; });
            var panel = document.getElementById("resource-panel");
            if (panel) BuildResourcePanel(panel);
        }

        var anchor = ToDate(startDate) || new Date();
        if (typeof scheduler !== "undefined") {
            scheduler.setCurrentView(anchor, "week");
        }
        RefreshSchedulerEvents();

        Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("OnAfterInit", []);
    } catch (e) {
        console.error("Init error:", e);
    }
    _initInProgress = false;
}

// ============================================================
// AL-callable: LoadCapacity(capacityJson)
//   capacityJson – JSON string: { data: [ { resource_id, start_date, end_date }, … ] }
//   Call after LoadData so events are re-merged immediately.
// ============================================================
function LoadCapacity(capacityJson) {
    if (!scheduler_here) {
        console.warn("LoadCapacity: scheduler not ready. Call Init first.");
        return;
    }
    try {
        var parsed = ParseJsonTxt(capacityJson);
        if (parsed) {
            if (Array.isArray(parsed.data)) {
                allCapacity = parsed.data;
            } else if (Array.isArray(parsed)) {
                allCapacity = parsed;
            }
        }
        RefreshSchedulerEvents();
    } catch (e) {
        console.error("LoadCapacity error:", e);
    }
}

// ============================================================
// AL-callable: LoadData(eventsJson)
//   eventsJson – JSON string: { data: [ { id, resource_id, classname,
//                                         start_date, end_date, text }, … ] }
// ============================================================
function LoadData(eventsJson) {
    if (!scheduler_here) {
        console.warn("LoadData: scheduler not ready. Call Init first.");
        return;
    }
    try {
        var parsed = ParseJsonTxt(eventsJson);
        if (parsed) {
            if (Array.isArray(parsed.data)) {
                allEvents = parsed.data;
            } else if (Array.isArray(parsed)) {
                allEvents = parsed;
            }
        }
        RefreshSchedulerEvents();
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

function ToDate(val) {
    if (!val) return null;
    if (val instanceof Date) return val;
    if (typeof val === "number") return new Date(val);
    var d = new Date(val);
    return isNaN(d) ? null : d;
}

function FmtDateStr(d) {
    return d.getFullYear() + '-' + ('0' + (d.getMonth() + 1)).slice(-2) + '-' + ('0' + d.getDate()).slice(-2);
}

// ============================================================
// AL-callable: ReloadData(eventsJson, capacityJson)
//   Combined single round-trip: updates both events and capacity,
//   then repaints the scheduler once.
// ============================================================
function ReloadData(eventsJson, capacityJson) {
    if (!scheduler_here) return;
    try {
        var parsedEv = ParseJsonTxt(eventsJson);
        if (parsedEv) {
            allEvents = Array.isArray(parsedEv.data) ? parsedEv.data
                      : Array.isArray(parsedEv)      ? parsedEv
                      : allEvents;
        }
        var parsedCap = ParseJsonTxt(capacityJson);
        if (parsedCap) {
            allCapacity = Array.isArray(parsedCap.data) ? parsedCap.data
                        : Array.isArray(parsedCap)      ? parsedCap
                        : allCapacity;
        }
        RefreshSchedulerEvents();
    } catch (e) {
        console.error("ReloadData error:", e);
    }
}

// ============================================================
// AL-callable: SetShowDayTask / SetShowCapacity
// ============================================================
function SetShowDayTask(pShow) {
    showDayTask = !!pShow;
    RefreshSchedulerEvents();
}

function SetShowCapacity(pShow) {
    showCapacity = !!pShow;
    RefreshSchedulerEvents();
}

// ============================================================
// Right-click context menu – events and resource panel
// ============================================================
function setupContextMenu() {
    // Build menu DOM once
    var menu = document.getElementById('dhx-ctx-menu');
    if (!menu) {
        menu = document.createElement('div');
        menu.id = 'dhx-ctx-menu';
        menu.className = 'hidden';
        document.body.appendChild(menu);
    }
    menu.innerHTML =
        '<div class="dhx-ctx-item" data-action="OpenResource">' +
            '<span class="dhx-ctx-icon">&#128196;</span>Resource</div>' +
        '<div class="dhx-ctx-separator"></div>' +
        '<div class="dhx-ctx-item" data-action="OpenDayTask">' +
            '<span class="dhx-ctx-icon">&#128172;</span>Daytask</div>' +
        '<div class="dhx-ctx-item" data-action="OpenCapacity">' +
            '<span class="dhx-ctx-icon">&#128172;</span>Capacity</div>' +
        '<div class="dhx-ctx-separator"></div>' +
        '<div class="dhx-ctx-item ctx-cancel" data-action="Cancel">' +
            '<span class="dhx-ctx-icon">&#10005;</span>Cancel</div>';

    var _ctxTarget = null;

    function showMenu(x, y, target) {
        _ctxTarget = target;
        //var openItem = menu.querySelector('[data-action="OpenResource"]');
        //if (openItem) openItem.style.display = (target.eventType === 'capacity') ? 'none' : '';
        menu.className = '';
        var menuW = 200, menuH = 170;
        var left = (x + menuW > window.innerWidth)  ? window.innerWidth  - menuW - 4 : x;
        var top  = (y + menuH > window.innerHeight) ? window.innerHeight - menuH - 4 : y;
        menu.style.left = left + 'px';
        menu.style.top  = top  + 'px';
    }

    function hideMenu() {
        menu.className = 'hidden';
        _ctxTarget = null;
    }

    // Wire menu-item clicks only once
    if (!menu._clickWired) {
        menu._clickWired = true;

        menu.addEventListener('click', function(e) {
            var item = e.target.closest('.dhx-ctx-item');
            if (!item) return;
            var action = item.getAttribute('data-action');
            if (action && action !== 'Cancel' && _ctxTarget) {
                var state = scheduler.getState ? scheduler.getState() : {};
                var periodStart, periodEnd;
                if (_ctxTarget.type === 'event') {
                    // Period = the single day the event sits on
                    var evDate = _ctxTarget.eventData && _ctxTarget.eventData.start_date
                        ? ToDate(_ctxTarget.eventData.start_date)
                        : null;
                    var dayStr = evDate ? FmtDateStr(evDate) : '';
                    periodStart = dayStr;
                    periodEnd   = dayStr;
                } else {
                    // Resource right-click → use the scheduler's visible period
                    periodStart = state.min_date ? FmtDateStr(state.min_date) : '';
                    var periodEndDate = state.max_date ? new Date(state.max_date.getTime() - 86400000) : null;
                    periodEnd = periodEndDate ? FmtDateStr(periodEndDate) : '';
                }
                var payload = JSON.stringify({
                    action:      action,
                    type:        _ctxTarget.type,
                    id:          _ctxTarget.id,
                    eventType:   _ctxTarget.eventType || '',
                    eventData:   _ctxTarget.eventData || null,
                    periodStart: periodStart,
                    periodEnd:   periodEnd
                });
                if (_ctxTarget.type === 'event') {
                    Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('OnEventContextMenu',
                        [_ctxTarget.id, action, periodStart, periodEnd, payload]);
                } else if (_ctxTarget.type === 'resource') {
                    Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('OnResourceContextMenu',
                        [_ctxTarget.id, action, periodStart, periodEnd, payload]);
                }
            }
            hideMenu();
            e.stopPropagation();
        });

        document.addEventListener('click',   function(e) { if (!menu.contains(e.target)) hideMenu(); });
        document.addEventListener('scroll',  hideMenu, true);
        document.addEventListener('keydown', function(e) { if (e.key === 'Escape') hideMenu(); });
    }

    // ── Scheduler events right-click ──────────────────────────
    var schedRoot = document.getElementById('scheduler_here');
    if (schedRoot && !schedRoot._ctxWired) {
        schedRoot._ctxWired = true;
        schedRoot.addEventListener('contextmenu', function(e) {
            e.preventDefault();
            e.stopPropagation();
            var eventEl = e.target.closest('[event_id]') ||
                          e.target.closest('.dhx_cal_event_line') ||
                          e.target.closest('.dhx_cal_event');
            if (eventEl) {
                var evId  = eventEl.getAttribute('event_id') || '';
                var ev    = (evId && scheduler && scheduler.getEvent) ? scheduler.getEvent(evId) : null;
                var evType = '';
                if (ev && ev.type) {
                    evType = String(ev.type);
                } else if (String(evId).indexOf('cap_') === 0) {
                    evType = 'capacity';
                } else {
                    evType = 'daytask';
                }
                var evData = ev ? {
                    id:          ev.id,
                    text:        ev.text,
                    resource_id: ev.resource_id,
                    type:        evType,
                    start_date:  ev.start_date instanceof Date ? ev.start_date.toISOString() : (ev.start_date || ''),
                    end_date:    ev.end_date   instanceof Date ? ev.end_date.toISOString()   : (ev.end_date   || '')
                } : null;
                showMenu(e.clientX, e.clientY, { type: 'event', id: evId, eventType: evType, eventData: evData });
                return;
            }
            hideMenu();
        });
    }

    // ── Resource panel right-click (delegation on static parent) ─
    var resPanel = document.getElementById('resource-panel');
    if (resPanel && !resPanel._ctxWired) {
        resPanel._ctxWired = true;
        resPanel.addEventListener('contextmenu', function(e) {
            e.preventDefault();
            e.stopPropagation();
            var resRow = e.target.closest('.rp-resource');
            if (resRow) {
                var cb = resRow.querySelector('.rp-resource-cb');
                var resourceId = cb ? (cb.dataset.resourceId || '') : '';
                var resName = '';
                for (var i = 0; i < allResources.length; i++) {
                    if (String(allResources[i].id) === resourceId) { resName = allResources[i].name; break; }
                }
                showMenu(e.clientX, e.clientY, {
                    type:      'resource',
                    id:        resourceId,
                    eventType: '',
                    eventData: { id: resourceId, name: resName }
                });
                return;
            }
            hideMenu();
        });
    }
}