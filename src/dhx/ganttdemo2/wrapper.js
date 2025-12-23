// =======================================================
// DHTMLX Gantt ControlAddIn - Business Central (SaaS)
// Structure:
//   1) BOOT()  - runs once: create DOM, configure gantt, gantt.init, raise ControlReady
//   2) LoadProject(start,end) - runs many times: set range, parse/load data, render
//   3) SetColumnVisibility(...) - user settings: hide/show columns
//   4) Undo/Redo/AddMarker - helpers
// =======================================================

var gantt_here = null;
var _queuedColumnArgs = null;
var _booted = false;

// -------------------------------------------------------
// 1) BOOT (run once)
// -------------------------------------------------------
window.BOOT = function() {
	if (_booted) return;
   _booted = true;
  try {
    // Host element created by BC
    var host = document.getElementById("controlAddIn") || document.body;
    host.style.width = "100%";
    host.style.height = "100%";
    host.style.margin = "0";
    host.style.padding = "0";
    host.style.background = "lightgrey";

    // Create gantt container inside host
    var el = document.getElementById("gantt_here");
    if (!el) {
      el = document.createElement("div");
      el.id = "gantt_here";
      el.style.width = "100%";
      el.style.height = "100%";
      el.style.boxSizing = "border-box";
      host.appendChild(el);
    }
    gantt_here = el;

    if (typeof gantt === "undefined") {
      console.error("DHX Gantt library not found. Ensure dhtmlxgantt.js is loaded in the ControlAddIn.");
      return;
    }

    // -------- DHTMLX PLUGINS --------
    gantt.plugins({
      auto_scheduling: true,
      marker: true,
      undo: true,
      resource: true
    });

    // Safe defaults (prevents task_height undefined in some layouts)
    gantt.config.row_height = gantt.config.row_height || 34;
    gantt.config.task_height = gantt.config.task_height || 16;

    // -------- WEEKEND HIGHLIGHT --------
    gantt.templates.scale_cell_class = function (date) {
      return (date.getDay() === 0 || date.getDay() === 6) ? "weekend" : "";
    };
    gantt.templates.timeline_cell_class = function (item, date) {
      return (date.getDay() === 0 || date.getDay() === 6) ? "weekend" : "";
    };

    // -------- TASK TYPE CLASS (CSS hook) --------
    gantt.templates.task_class = function (start, end, task) {
      return task.schedulingType || "";
    };

    // -------- WORK TIME --------
    gantt.config.work_time = true;
    gantt.config.min_column_width = 55;

    // -------- DATE FORMAT (matches your demo strings) --------
    gantt.config.date_format = "%d-%m-%Y";

    // -------- EDITORS --------
    var textEditor = { type: "text", map_to: "text" };
    var dateEditor = { type: "date", map_to: "start_date", min: new Date(2023, 0, 1), max: new Date(2025, 0, 1) };
    var durationEditor = { type: "number", map_to: "duration", min: 0, max: 100 };

    var constraintTypeEditor = {
      type: "select", map_to: "constraint_type", options: [
        { key: "asap", label: gantt.locale.labels.asap },
        { key: "alap", label: gantt.locale.labels.alap },
        { key: "snet", label: gantt.locale.labels.snet },
        { key: "snlt", label: gantt.locale.labels.snlt },
        { key: "fnet", label: gantt.locale.labels.fnet },
        { key: "fnlt", label: gantt.locale.labels.fnlt },
        { key: "mso", label: gantt.locale.labels.mso },
        { key: "mfo", label: gantt.locale.labels.mfo }
      ]
    };
    var constraintDateEditor = { type: "date", map_to: "constraint_date", min: new Date(2023, 0, 1), max: new Date(2025, 0, 1) };

    // -------- GRID SETTINGS --------
    gantt.config.grid_width = 250;
    gantt.config.grid_resize = true;

    // -------- COLUMNS --------
    gantt.config.columns = [
      { name: "text", tree: true, resize: false, width: 150, editor: textEditor },
      { name: "start_date", align: "center", resize: false, width: 150, editor: dateEditor },
      { name: "duration", align: "center", resize: false, width: 80, editor: durationEditor },
      {
        name: "constraint_type", align: "center", width: 110,
        template: function (task) { return gantt.locale.labels[gantt.getConstraintType(task)]; },
        resize: false, editor: constraintTypeEditor
      },
      {
        name: "constraint_date", align: "center", width: 120,
        template: function (task) {
          var ct = gantt.config.constraint_types;
          if (task.constraint_date && task.constraint_type !== ct.ASAP && task.constraint_type !== ct.ALAP) {
            return gantt.templates.task_date(task.constraint_date);
          }
          return "";
        },
        resize: false, editor: constraintDateEditor
      },
      { name: "schedulingType", label: "Task Type", resize: false, width: 90 },
      { name: "add", resize: false, width: 44 }
    ];

    // -------- LIGHTBOX --------
    gantt.config.lightbox.sections = [
      { name: "description", height: 38, map_to: "text", type: "textarea", focus: true },
      { name: "constraint", type: "constraint" },
      {
        name: "schedulingType",
        height: 22,
        map_to: "schedulingType",
        type: "select",
        options: [
          { key: "fixed_duration", label: "Fixed Duration" },
          { key: "fixed_units", label: "Fixed Units" },
          { key: "fixed_work", label: "Fixed Work" }
        ]
      },
      { name: "time", type: "duration", map_to: "auto" }
    ];
    gantt.config.lightbox.project_sections = gantt.config.lightbox.sections;

    // Server list (used by constraint/lightbox in some setups)
    gantt.serverList("schedulingTypes", [
      { key: "fixed_duration", label: "Fixed Duration" },
      { key: "fixed_units", label: "Fixed Units" },
      { key: "fixed_work", label: "Fixed Work" }
    ]);

    // -------- EVENTS (BC callback) --------
    gantt.attachEvent("onAfterTaskUpdate", function (id, task) {
      try {
        Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("OnTaskUpdated", [id, task.schedulingType, task.start_date, task.duration]);
      } catch (e) {
        // ignore if event not wired yet
      }
    });

    // -------- RESOURCE SECTION (kept from your demo) --------
    // Datastores
    var resourcesStore = gantt.createDatastore({
      name: "resources",
      initItem: function (item) { item.id = item.key || gantt.uid(); return item; }
    });
    var tasksStore = gantt.getDatastore("task");
    tasksStore.attachEvent("onStoreUpdated", function () { resourcesStore.refresh(); });

    function calculateResourceLoad(tasks, scale) {
      var step = scale.unit;
      var timegrid = {};
      for (var i = 0; i < tasks.length; i++) {
        var t = tasks[i];
        var d = gantt.date[step + "_start"](new Date(t.start_date));
        while (d < t.end_date) {
          var date = d;
          d = gantt.date.add(d, 1, step);
          if (!gantt.isWorkTime({ date: date, task: t })) continue;
          var ts = date.valueOf();
          timegrid[ts] = (timegrid[ts] || 0) + 8; // dummy 8h/day
        }
      }
      var out = [];
      for (var ts2 in timegrid) {
        var start = new Date(+ts2);
        var end = gantt.date.add(start, 1, step);
        out.push({ start_date: start, end_date: end, value: timegrid[ts2] });
      }
      return out;
    }

    var renderResourceLine = function (resource, timeline) {
      var tasks = gantt.getTaskBy("user", resource.id);
      var timetable = calculateResourceLoad(tasks, timeline.getScale());
      var row = document.createElement("div");
      for (var i = 0; i < timetable.length; i++) {
        var day = timetable[i];
        var sizes = timeline.getItemPosition(resource, day.start_date, day.end_date);
        var cell = document.createElement("div");
        cell.className = (day.value <= 8) ? "gantt_resource_marker gantt_resource_marker_ok" : "gantt_resource_marker gantt_resource_marker_overtime";
        cell.style.cssText = [
          "left:" + sizes.left + "px",
          "width:" + sizes.width + "px",
          "position:absolute",
          "height:" + (gantt.config.row_height - 1) + "px",
          "top:" + sizes.top + "px",
          "text-align:center",
          "font-weight:600"
        ].join(";");
        cell.innerHTML = day.value;
        row.appendChild(cell);
      }
      return row;
    };
    var resourceLayers = [renderResourceLine, "taskBg"];

    var mainGridConfig = { columns: gantt.config.columns };
    var resourcePanelConfig = {
      columns: [
        { name: "name", label: "Name", template: function (r) { return r.label; } },
        {
          name: "workload", label: "Workload", template: function (r) {
            var tasks = gantt.getTaskBy("user", r.id);
            var total = 0;
            for (var i = 0; i < tasks.length; i++) total += (tasks[i].duration || 0);
            return (total * 8) + "";
          }
        }
      ]
    };

    gantt.config.layout = {
      css: "gantt_container",
      rows: [
        {
          cols: [
            { view: "grid", group: "grids", config: mainGridConfig, scrollY: "scrollVer" },
            { resizer: true, width: 1, group: "vertical" },
            { view: "timeline", id: "timeline", scrollX: "scrollHor", scrollY: "scrollVer" },
            { view: "scrollbar", id: "scrollVer", group: "vertical" }
          ]
        },
        { resizer: true, width: 1 },
        {
          config: resourcePanelConfig,
          cols: [
            { view: "grid", id: "resourceGrid", group: "grids", bind: "resources", scrollY: "resourceVScroll" },
            { resizer: true, width: 1, group: "vertical" },
            { view: "timeline", id: "resourceTimeline", bind: "resources", bindLinks: null, layers: resourceLayers, scrollX: "scrollHor", scrollY: "resourceVScroll" },
            { view: "scrollbar", id: "resourceVScroll", group: "vertical" }
          ]
        },
        { view: "scrollbar", id: "scrollHor" }
      ]
    };

    // Resource CSS
    (function injectResourceCSS() {
      var css = ""
        + ".gantt_resource_marker{ border-radius:4px; color:#fff; }"
        + ".gantt_resource_marker_ok{ background:#21b36c; }"
        + ".gantt_resource_marker_overtime{ background:#e74c3c; }";
      var s = document.createElement("style");
      s.textContent = css;
      document.head.appendChild(s);
    })();

    // Optional debug red border on tasks
    (function injectDebugCSS() {
      var s = document.createElement("style");
      s.textContent = ".gantt_task_bar{ border:2px solid red !important; }";
      document.head.appendChild(s);
    })();

    // ✅ ENGINE INIT (once)
    gantt.init("gantt_here");

    // Seed demo resources (optional; replace later with BC)
    resourcesStore.parse([
      { key: "0", label: "N/A" },
      { key: "1", label: "John" },
      { key: "2", label: "Mike" },
      { key: "3", label: "Anna" }
    ]);

    // Apply queued column settings if AL called too early
    if (_queuedColumnArgs) {
      _applyColumnSettings(_queuedColumnArgs);
      _queuedColumnArgs = null;
    }

    // ✅ Tell AL we are safe to call now
    Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("ControlReady", []);

  } catch (e) {
    console.warn("BOOT warning:", e);
  }
}

// -------------------------------------------------------
// 2) LoadProject (AL -> JS)
//    NOTE: Do NOT call gantt.init() here.
// -------------------------------------------------------
function LoadProject(projectstartdate, projectenddate) {
  
	gantt.clearAll(); 
  // If you pass BC dates as strings, adapt parsing here.
  // For now, keep demo range if input missing.
  if (projectstartdate) {
    try { gantt.config.project_start = new Date(projectstartdate); } catch (e) {}
  }
  if (projectenddate) {
    try { gantt.config.project_end = new Date(projectenddate); } catch (e) {}
  }

  gantt.config.auto_scheduling = {
    enabled: true,
    show_constraints: true,
    schedule_from_end: false,
    apply_constraints: true,
    project_constraint: true
  };

  // Markers for project bounds
  gantt.addMarker({ start_date: gantt.config.project_start, text: "project start" });
  gantt.addMarker({ start_date: gantt.config.project_end, text: "project end" });

  // Demo data (replace later with BC payload)
  
    gantt.parse({
      data: [
        { id: 1, text: "Project #1", type: "project", progress: 0.6, open: true, schedulingType: "fixed_duration" },
        { id: 2, text: "Task #1", start_date: "02-04-2023", duration: 5, parent: 1, progress: 1, open: true, schedulingType: "fixed_units" },
        { id: 3, text: "Task #2", start_date: "03-04-2023", type: "project", parent: 1, progress: 0.5, open: true, schedulingType: "fixed_work" }
      ],
      links: []
    });

  //gantt.render();
  //if (gantt.setSizes) gantt.setSizes();

    setTimeout(function () {
    gantt.render();
    if (gantt.setSizes) gantt.setSizes();
    if (gantt.resetLayout) gantt.resetLayout();
  }, 0);
}

// -------------------------------------------------------
// 3) Column Visibility (AL -> JS)
// -------------------------------------------------------
function SetColumnVisibility(showStartDate, showDuration, showConstraintType, showConstraintDate, showTaskType) {
  var args = [showStartDate, showDuration, showConstraintType, showConstraintDate, showTaskType];
     if (!gantt_here || typeof gantt === "undefined" || !gantt.$root) {
    _queuedColumnArgs = args;
    return;
  }
  _applyColumnSettings(args);
}

function _applyColumnSettings(args) {
  _setColumnHidden("start_date", !args[0]);
  _setColumnHidden("duration", !args[1]);
  _setColumnHidden("constraint_type", !args[2]);
  _setColumnHidden("constraint_date", !args[3]);
  _setColumnHidden("schedulingType", !args[4]);

  gantt.render();
  if (gantt.setSizes) gantt.setSizes();
  if (gantt.resetLayout) gantt.resetLayout();
}

function _setColumnHidden(name, hidden) {
  var cols = gantt.config.columns || [];
  for (var i = 0; i < cols.length; i++) {
    if (cols[i] && cols[i].name === name) {
      cols[i].hide = hidden;
      cols[i].hidden = hidden;
      return;
    }
  }
}

// -------------------------------------------------------
// 4) Other exposed procedures (AL -> JS)
// -------------------------------------------------------
function Undo() { gantt.undo() }
function Redo() { gantt.redo() }

function AddMarker(datestr, text) {
  if (!datestr) return;

  var parseISO = gantt.date.str_to_date("%Y-%m-%d");
  var date = parseISO(String(datestr).trim());
  if (!date || isNaN(date.getTime())) return;

  var id = gantt.addMarker({ start_date: date, text: text });
  gantt.showDate(date);
  gantt.updateMarker(id);
  gantt.renderMarkers();
}
