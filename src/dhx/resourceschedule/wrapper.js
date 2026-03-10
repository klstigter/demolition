// ============================================================
// Dummy data – replace with AL-provided data in production
// ============================================================
var DUMMY_RESOURCES = [
    { id: "R001", name: "Ahmad Hassan",   group: "Team A" },
    { id: "R002", name: "Sarah Johnson",  group: "Team A" },
    { id: "R003", name: "Mike Peters",    group: "Team B" },
    { id: "R004", name: "Emma Wilson",    group: "Team B" },
    { id: "R005", name: "Tom Baker",      group: "Team C" },
    { id: "R006", name: "Lisa Chang",     group: "Team C" }
];

var DUMMY_EVENTS = [
    // Team A – Ahmad Hassan (R001)
    { id:101, resource_id:"R001", classname:"blue",   start_date:"2026-03-09 08:00", end_date:"2026-03-09 12:00", text:"Site Inspection" },
    { id:102, resource_id:"R001", classname:"green",  start_date:"2026-03-10 13:00", end_date:"2026-03-10 17:00", text:"Demolition Planning" },
    { id:103, resource_id:"R001", classname:"violet", start_date:"2026-03-11 09:00", end_date:"2026-03-11 11:00", text:"Safety Briefing" },
    // Team A – Sarah Johnson (R002)
    { id:201, resource_id:"R002", classname:"yellow", start_date:"2026-03-09 07:00", end_date:"2026-03-09 15:00", text:"Equipment Setup" },
    { id:202, resource_id:"R002", classname:"green",  start_date:"2026-03-11 10:00", end_date:"2026-03-11 14:00", text:"Concrete Breaking" },
    { id:203, resource_id:"R002", classname:"blue",   start_date:"2026-03-12 08:00", end_date:"2026-03-12 16:00", text:"Wall Removal" },
    // Team B – Mike Peters (R003)
    { id:301, resource_id:"R003", classname:"violet", start_date:"2026-03-09 06:00", end_date:"2026-03-09 10:00", text:"Crane Operation" },
    { id:302, resource_id:"R003", classname:"blue",   start_date:"2026-03-10 08:00", end_date:"2026-03-10 12:00", text:"Debris Removal" },
    { id:303, resource_id:"R003", classname:"yellow", start_date:"2026-03-13 09:00", end_date:"2026-03-13 17:00", text:"Excavation" },
    // Team B – Emma Wilson (R004)
    { id:401, resource_id:"R004", classname:"green",  start_date:"2026-03-10 07:00", end_date:"2026-03-10 11:00", text:"Structural Survey" },
    { id:402, resource_id:"R004", classname:"violet", start_date:"2026-03-11 13:00", end_date:"2026-03-11 18:00", text:"Report Writing" },
    { id:403, resource_id:"R004", classname:"blue",   start_date:"2026-03-14 08:00", end_date:"2026-03-14 12:00", text:"Client Meeting" },
    // Team C – Tom Baker (R005)
    { id:501, resource_id:"R005", classname:"yellow", start_date:"2026-03-09 09:00", end_date:"2026-03-09 13:00", text:"Machine Maintenance" },
    { id:502, resource_id:"R005", classname:"green",  start_date:"2026-03-12 10:00", end_date:"2026-03-12 15:00", text:"Pipe Cutting" },
    { id:503, resource_id:"R005", classname:"blue",   start_date:"2026-03-13 08:00", end_date:"2026-03-13 12:00", text:"Welding Work" },
    // Team C – Lisa Chang (R006)
    { id:601, resource_id:"R006", classname:"violet", start_date:"2026-03-10 06:00", end_date:"2026-03-10 10:00", text:"Waste Sorting" },
    { id:602, resource_id:"R006", classname:"yellow", start_date:"2026-03-11 07:00", end_date:"2026-03-11 11:00", text:"Hazmat Disposal" },
    { id:603, resource_id:"R006", classname:"green",  start_date:"2026-03-14 13:00", end_date:"2026-03-14 17:00", text:"Site Cleanup" }
];

// ============================================================
// State
// ============================================================
var scheduler_here;          // DOM element reference (readiness flag)
var allResources  = [];      // [ { id, name, group } ]
var allEvents     = [];      // [ { id, resource_id, classname, start_date, end_date, text } ]
var checkedResources = {};   // { resourceId: true|false }

// ============================================================
// BOOT – called by startupScript.js
// ============================================================
window.BOOT = function() {
    try {
        // ---- Outer layout: flex row ----
        var addin = document.getElementById("controlAddIn");
        addin.style.cssText = "width:100%;height:100%;margin:0;padding:0;display:flex;flex-direction:row;overflow:hidden;";

        // Left: resource selection panel
        var leftPanel = document.createElement("div");
        leftPanel.id = "resource-panel";
        addin.appendChild(leftPanel);

        // Right: scheduler panel
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
        scheduler.config.details_on_create     = true;
        scheduler.config.details_on_dblclick   = true;
        scheduler.config.start_on_monday       = true;

        scheduler.templates.event_class = function(start, end, ev) {
            return ev.classname || "";
        };

        // ---- Load dummy data ----
        allResources = DUMMY_RESOURCES.slice();
        allEvents    = DUMMY_EVENTS.slice();
        allResources.forEach(function(r) { checkedResources[r.id] = true; });

        // ---- Build resource selection panel ----
        BuildResourcePanel(leftPanel);

        // ---- Init scheduler – week view, week of 2026-03-09 ----
        scheduler.init("scheduler_here", new Date(2026, 2, 9), "week");

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
            rRow.appendChild(rLabel);
            container.appendChild(rRow);
        });
    });
}

// ============================================================
// Re-parse only events for currently checked resources
// ============================================================
function RefreshSchedulerEvents() {
    if (typeof scheduler === "undefined") return;
    scheduler.clearAll();
    var filtered = allEvents.filter(function(ev) {
        return !!checkedResources[ev.resource_id];
    });
    if (filtered.length > 0) {
        scheduler.parse(filtered);
    }
}

// ============================================================
// AL-callable: Init(elementsJson, startDate)
//   elementsJson – JSON string: { data: [ { id, name, group }, … ] }
//                  pass empty string "" to keep dummy resources
//   startDate    – BC Date (passed as epoch ms or ISO string)
// ============================================================
function Init(elementsJson, startDate) {
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