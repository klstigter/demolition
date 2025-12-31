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
var resourcesStore = null;
var dayTasksStore = null;

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

    function InstallDayTaskEvents() {
      if (window._dayTaskEventsInstalled) return;
      window._dayTaskEventsInstalled = true;

      gantt.$root.addEventListener("dblclick", function (e) {
        const el = e.target.closest(".daytask-line");
        if (!el) return;

        e.preventDefault();
        e.stopPropagation();

        el.classList.add("daytask-line");
        el.setAttribute("data-task-id", task.id);
        el.setAttribute("data-daytask-id", dayTask.id);

        const dayTaskId = el.dataset.daytaskId;
        if (!dayTaskId) return;

        // 🔁 call BC
        if (window.BC_OnDayTaskDblClick) {
          window.BC_OnDayTaskDblClick(dayTaskId);
        }
      });

      gantt.$root.addEventListener("click", function (e) {
        const el = e.target.closest(".daytask-line");
        if (!el) return;

        e.stopPropagation();

        const dayTaskId = el.dataset.daytaskId;
        highlightDayTask(el); // optional visual
      });
    }

    function InstallResourceMarkerCustomTooltipsForDayTasks() {
      if (document._rmCustomTooltipInstalled) return;
      document._rmCustomTooltipInstalled = true;

      document.addEventListener("mousemove", function (e) {
        const marker = e.target.closest?.(".gantt_resource_marker");
        if (!marker) return;

        const resId = marker.getAttribute("data-resource-id");
        const workDate = marker.getAttribute("data-work-date"); // YYYY-MM-DD
        const hoursTxt = (marker.textContent || "").trim();

        if (!resId || !workDate) {
          _showCustomTooltip(e, `<b>Marker</b><br/>${hoursTxt || "?"}h`);
          return;
        }

        // Collect matching DayTasks across all tasks (resource view)
        const all = window.dayTasksByTask || {};
        const matches = [];
        for (const taskId in all) {
          const list = all[taskId] || [];
          for (let i = 0; i < list.length; i++) {
            const x = list[i];
            if (x.resource_id === resId && x.work_date === workDate) matches.push(x);
          }
        }

        if (!matches.length) {
          _showCustomTooltip(
            e,
            `<b>${resId}</b><br/>Date: ${workDate}<br/>Marker: ${hoursTxt}h<br/><i>No DayTasks</i>`
          );
          return;
        }

        const total = matches.reduce((s, x) => s + (Number(x.hours) || 0), 0);
        const lines = matches.slice(0, 8).map(x => {
          const st = String(x.start_time || "").trim();
          const et = String(x.end_time || "").trim();
          const label = x.task || (x.jobNo + "-" + x.jobTaskNo) || "-";
          return `${label} • ${x.hours || 0}h • ${st}-${et}`;
        }).join("<br/>");

        _showCustomTooltip(
          e,
          `<b>${resId}</b><br/>
          Date: ${workDate}<br/>
          Marker: ${hoursTxt}h<br/>
          DayTasks total: ${total}h<hr style="border:0;border-top:1px solid rgba(255,255,255,0.15);margin:6px 0"/>
          ${lines}${matches.length > 8 ? "<br/>…" : ""}`
        );
      }, true);

      document.addEventListener("mouseleave", function () {
        _hideCustomTooltip();
      }, true);

      document.addEventListener("mouseout", function (e) {
        const marker = e.target.closest?.(".gantt_resource_marker");
        if (!marker) return;
        if (!marker.contains(e.relatedTarget)) _hideCustomTooltip();
      }, true);
    }

    // -------- DHTMLX PLUGINS --------
    gantt.plugins({
      auto_scheduling: true,
      marker: true,
      undo: true,
      resource: true,
      tooltip: true
    });
    

    // Safe defaults (prevents task_height undefined in some layouts)
    gantt.config.row_height = gantt.config.row_height || 30;
    gantt.config.task_height = gantt.config.task_height || 13;

      // keep your parsing format for task dates
    gantt.config.date_format = "%Y-%m-%d";
    gantt.config.xml_date = "%Y-%m-%d";

    // scale header
    gantt.config.scales = [
      {
        unit: "week",
        step: 1,
        format: function (date) {
          
          const months = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"];
          const MMM = months[date.getMonth()];
          const week = gantt.date.date_to_str("%W")(date);
          const year = gantt.date.date_to_str("%Y")(date);
          
          return   MMM + " " + year + " - " + "wk " + week;   // e.g. W49 2025
        },
        css: function (date) {
          const week = parseInt(gantt.date.date_to_str("%W")(date), 10);
          return (week % 2 === 0) ? "week-even" : "week-odd";
        }
      },
      {
        unit: "day",
        step: 1,
        format: function (date) {
          return gantt.date.date_to_str("%D %d")(date); // Mon 01 Dec
          //return gantt.date.date_to_str("%D %d %M")(date); // Mon 01 Dec
        }
      }
    ];
    
    //mapping resource property and daytasks resource property
    gantt.config.resource_property = "resource_id";


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

        // -------- EDITORS --------
    var textEditor = { type: "text", map_to: "text" };
    var dateEditor = { type: "date", map_to: "start_date"};
    var durationEditor = { type: "number", map_to: "duration", min: 0 };
    var progressEditor = { type: "number", map_to: "progress", min: 0, max: 100 };
    var INDENT_PAD = 14; // pixels per indent step

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
    var constraintDateEditor = { type: "date", map_to: "constraint_date" };

    // -------- GRID SETTINGS --------
    gantt.config.grid_width = 250;
    gantt.config.grid_resize = true;

    // -------- COLUMNS --------
    gantt.config.columns = [
      { name: "text", tree: true, resize: false, width: 250, editor: textEditor },
      { name: "progress", label: "%", align: "center", resize: false, width: 60,
        editor: progressEditor,
          template: function (task) { var p = task.progress || 0; return Math.round(p * 100) + "%";}          // DHTMLX uses 0..1 normally
      },
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
    
    gantt.attachEvent("onAfterTaskUpdate", function (id, task) {
      if (typeof task.progress === "number" && task.progress > 1) {
        task.progress = Math.max(0, Math.min(task.progress, 100)) / 100;
      }
    });

    gantt.templates.grid_row_class = function (start, end, task) {
      return task.bold ? "bc-row-bold" : "";
    };
/*
    gantt.templates.task_class = function (start, end, task) {
      if (task.bold) return ""; // bold=true => no special border color
      var indent = task.indent || 0;
      var lvl = Math.max(0, Math.min(indent, 6)); // clamp to 0..6
      return "bc-bar-border bc-indent-" + lvl;
    };
*/
    gantt.templates.tooltip_text = function(start, end, task) {
      let constraintText = "—";

      if (task.constraint_type) {
        if (task.constraint_date) {
          constraintText =
            `${task.constraint_type} (${gantt.templates.date_grid(task.constraint_date)})`;
        } else {
          constraintText = task.constraint_type;
        }
      }

      return `
        <b>Job: ${task.bcJobNo || "-"}<br/>
        Task: ${task.bcJobTaskNo || "-"}<br/>
        <hr/>
        Constraint: ${constraintText}
      `;
    };



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


    gantt.attachEvent("onTaskDblClick", function (id, ev) {
      try {
        var task = gantt.getTask(id);
        var eventData = {
          id: id,
          text: task.text,
          start_date: task.start_date,
          end_date: task.end_date,
          parent: task.parent,
          schedulingType: task.schedulingType,
          constraint_type: task.constraint_type,
          constraint_date: task.constraint_date,
          // Your BC binding fields if present:
          bcRecordId: task.bcRecordId,
          bcTableNo: task.bcTableNo,
          bcDocumentNo: task.bcDocumentNo
        };

        Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("onTaskDblClick", [
          String(id),
          JSON.stringify(eventData)
        ]);
      } catch (e) {
        console.error("onTaskDblClick failed:", e);
      }
      return false; // keep blocking lightbox if you want
    });

    // -------- EVENTS (BC callback) --------
    gantt.attachEvent("onAfterTaskUpdate", function (id, task) {
      try {
        var fmt = gantt.date.date_to_str(gantt.config.date_format);

        var payload = {
          id: String(id),

          // ✅ BC bindings
          bcJobNo: task.bcJobNo || "",
          bcJobTaskNo: task.bcJobTaskNo || "",

          // Planning fields
          text: task.text || "",
          start_date: task.start_date ? fmt(task.start_date) : null,
          end_date: task.end_date ? fmt(task.end_date) : null,
          duration: task.duration || 0,
          schedulingType: task.schedulingType || "",

          constraint_type: task.constraint_type || "",
          constraint_date: task.constraint_date ? fmt(task.constraint_date) : null
        };

        Microsoft.Dynamics.NAV.InvokeExtensibilityMethod(
          "OnJobTaskUpdated",
          [ JSON.stringify(payload) ]
        );
      } catch (e) {
        // ignore if not wired yet
      }
    });

    //add event to existing standard DHTMLX task store to refresh resources on task changes
    var tasksStore = gantt.getDatastore("task");
    tasksStore.attachEvent("onStoreUpdated", function () { resourcesStore.refresh(); });

    // Datastores
    resourcesStore = gantt.createDatastore({
      name: "resources",
      initItem: function (item) { item.id = item.key || gantt.uid(); return item; }
    });

    // DayTasks datastore (your BC Day Tasks table)
    dayTasksStore = gantt.createDatastore({
      name: "daytasks",
      initItem: function (item) {
        // unique key for upsert: JobNo|JobTaskNo|WorkDate|ResourceNo
        item.id = item.id || item.key || gantt.uid();
        return item;
      }
    });

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

    // Apply queued column settings if AL called too early
    if (_queuedColumnArgs) {
      _applyColumnSettings(_queuedColumnArgs);
      _queuedColumnArgs = null;
    }
    
    console.log("tooltip ext:", gantt.ext && (gantt.ext.tooltip || gantt.ext.tooltips));
    
    InstallDayTaskLayer();   // ✅ install once
    InstallDayTaskEvents(); // ✅ install once
    InstallResourceMarkerCustomTooltipsForDayTasks();


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
  //gantt.addMarker({ start_date: gantt.config.project_start, text: "project start" });
  //gantt.addMarker({ start_date: gantt.config.project_end, text: "project end" });

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

// =======================================================
// UPPER PART (Gantt) - Data functions (AL -> JS)
// =======================================================

function _tryParseJson(txt) {
  if (txt == null) return null;
  if (typeof txt === "object") return txt; // already parsed
  var s = String(txt).trim();
  if (!s) return null;
  try {
    return JSON.parse(s);
  } catch (e) {
    console.error("JSON parse failed:", e, s);
    return null;
  }
}

function _normalizeId(obj) {
  return obj?.id ?? obj?.Id ?? obj?.task_id ?? obj?.TaskId ?? obj?.link_id ?? obj?.LinkId ?? null;
}

// Converts incoming date values to a JS Date using your gantt.config.date_format (%d-%m-%Y)
// Accepts: "dd-mm-yyyy" OR ISO strings OR Date objects
function _toGanttDate(v) {
  if (!v) return null;
  if (v instanceof Date) return v;

  // If already a number timestamp
  if (typeof v === "number") {
    var dNum = new Date(v);
    return isNaN(dNum.getTime()) ? null : dNum;
  }

  var s = String(v).trim();
  if (!s) return null;

  // try gantt parser first (dd-mm-yyyy)
  try {
    var parser = gantt.date.str_to_date(gantt.config.date_format);
    var d1 = parser(s);
    if (d1 && !isNaN(d1.getTime())) return d1;
  } catch (_) {}

  // fallback: Date can parse ISO
  var d2 = new Date(s);
  return isNaN(d2.getTime()) ? null : d2;
}

function _applyTaskPatch(targetTask, patch) {
  // Update only provided fields (partial update)
  for (var k in patch) {
    if (!Object.prototype.hasOwnProperty.call(patch, k)) continue;
    if (k === "id" || k === "Id") continue;

    // Normalize dates
    if (k === "start_date" || k === "end_date" || k === "constraint_date" || k === "deadline") {
      var d = _toGanttDate(patch[k]);
      if (d) targetTask[k] = d;
      else if (patch[k] === null) targetTask[k] = null;
      continue;
    }

    targetTask[k] = patch[k];
  }
}

// -------------------------------------------------------
// Full load (tasks + links) from BC
// AL calls: LoadProjectData(ProjectJsonTxt)
// -------------------------------------------------------

function ClearData(projectJsonTxt) {
  gantt.clearAll();
  gantt.render();
}
function LoadProjectData(projectJsonTxt) {
 

  function validateConstraintsBeforeParse(tasks) {
  const ct = gantt.config.constraint_types || {};
  const keys = Object.keys(ct);
  const bad = [];

  tasks.forEach(t => {
    if (t.constraint_type !== undefined && t.constraint_type !== null) {
      const label = ct[t.constraint_type];
      if (typeof label !== "string") {
        bad.push({
          id: t.id,
          constraint_type: t.constraint_type,
          typeofConstraintType: typeof t.constraint_type,
          label,
          availableKeysSample: keys.slice(0, 20)
        });
      }
    }
  });

  if (bad.length) {
    console.warn("BAD constraint mapping BEFORE parse:", bad);
  }
} 
  

  try {
    if (!gantt_here || typeof gantt === "undefined" || !gantt.$root) {
      console.warn("LoadProjectData called before BOOT/init");
      return;
    }

    var payload = _tryParseJson(projectJsonTxt);
    if (!payload) {
      console.warn("LoadProjectData: empty payload");
      gantt.clearAll();
      gantt.render();
      return;
    }
    

    // ✅ accept array payload = tasks[]
    if (Array.isArray(payload)) {
      payload = { tasks: payload, links: [] };
    }

    var tasks = payload.tasks || payload.data || payload.Tasks || payload.Data || [];
    var links = payload.links || payload.Links || [];

    // Optional: project range in payload
    if (payload.project_start) gantt.config.project_start = _toGanttDate(payload.project_start) || gantt.config.project_start;
    if (payload.project_end) gantt.config.project_end = _toGanttDate(payload.project_end) || gantt.config.project_end;

    // Clear existing
    gantt.clearAll();

    // Parse new
    gantt.parse({ data: tasks, links: links });

    // Render once
    gantt.render();
    if (gantt.setSizes) gantt.setSizes();
    if (gantt.resetLayout) gantt.resetLayout();
    Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("OnProjectDataLoaded", [
      String(tasks.length),
      String(links.length)
    ]);
  } catch (e) {
    console.error("LoadProjectData failed:", e);
  }
}

// -------------------------------------------------------
// Upsert a single task (partial update)
// AL calls: UpsertTask(TaskJsonTxt, true)
// -------------------------------------------------------
function UpsertTask(taskJsonTxt, upsertIfMissing = false) {
  try {
    if (!gantt_here || typeof gantt === "undefined" || !gantt.$root) {
      console.warn("UpsertTask called before BOOT/init");
      return;
    }

    var patch = _tryParseJson(taskJsonTxt);
    if (!patch) return;

    var id = _normalizeId(patch);
    if (id == null) {
      console.warn("UpsertTask: missing id", patch);
      return;
    }

    var exists = gantt.isTaskExists(id);
    if (!exists) {
      if (!upsertIfMissing) return;

      // Ensure dates are proper Date objects if provided
      if (patch.start_date) patch.start_date = _toGanttDate(patch.start_date);
      if (patch.end_date) patch.end_date = _toGanttDate(patch.end_date);
      if (patch.constraint_date) patch.constraint_date = _toGanttDate(patch.constraint_date);
      if (patch.deadline) patch.deadline = _toGanttDate(patch.deadline);

      // parent is optional; gantt.addTask(task, parentId)
      var parentId = patch.parent ?? 0;
      gantt.addTask(patch, parentId);

      return;
    }

    var task = gantt.getTask(id);
    _applyTaskPatch(task, patch);
    gantt.updateTask(id);
  } catch (e) {
    console.error("UpsertTask failed:", e, taskJsonTxt);
  }
}

// -------------------------------------------------------
// Delete task
// AL calls: DeleteTask(TaskId)
// -------------------------------------------------------
function DeleteTask(taskId) {
  try {
    if (!gantt_here || typeof gantt === "undefined" || !gantt.$root) return;
    if (taskId == null) return;
    var id = String(taskId);
    if (gantt.isTaskExists(id)) gantt.deleteTask(id);
  } catch (e) {
    console.error("DeleteTask failed:", e, taskId);
  }
}

// -------------------------------------------------------
// Upsert dependency link
// AL calls: UpsertLink(LinkJsonTxt, true)
// Link shape: { id, source, target, type, lag? }
// -------------------------------------------------------
function UpsertLink(linkJsonTxt, upsertIfMissing = false) {
  try {
    if (!gantt_here || typeof gantt === "undefined" || !gantt.$root) {
      console.warn("UpsertLink called before BOOT/init");
      return;
    }

    var patch = _tryParseJson(linkJsonTxt);
    if (!patch) return;

    var id = _normalizeId(patch);
    if (id == null) {
      console.warn("UpsertLink: missing id", patch);
      return;
    }

    // DHTMLX Gantt link existence check
    var exists = !!gantt.getLink(id); // will throw if missing in some builds
    if (!exists) {
      if (!upsertIfMissing) return;
      gantt.addLink(patch);
      return;
    }

    var link = gantt.getLink(id);
    for (var k in patch) {
      if (!Object.prototype.hasOwnProperty.call(patch, k)) continue;
      if (k === "id" || k === "Id") continue;
      link[k] = patch[k];
    }
    gantt.updateLink(id);
  } catch (e) {
    // Some builds throw on getLink when missing; handle add in that case
    try {
      var patch2 = _tryParseJson(linkJsonTxt);
      if (!patch2) return;
      if (upsertIfMissing) gantt.addLink(patch2);
    } catch (_) {}
  }
}

// -------------------------------------------------------
// Delete link
// AL calls: DeleteLink(LinkId)
// -------------------------------------------------------
function DeleteLink(linkId) {
  try {
    if (!gantt_here || typeof gantt === "undefined" || !gantt.$root) return;
    if (linkId == null) return;
    var id = String(linkId);
    // deleteLink exists in Gantt
    gantt.deleteLink(id);
  } catch (e) {
    console.error("DeleteLink failed:", e, linkId);
  }
}

function calculateResourceLoad(resource, scale) {
  var step = scale.unit; // day
  var timegrid = {};
  var all = dayTasksStore ? dayTasksStore.getItems() : [];

  for (var i = 0; i < all.length; i++) {
    var dt = all[i];
    if (!dt) continue;

    if (String(dt.resource_id || "") !== String(resource.id || "")) continue;

    var d = _toGanttDate(dt.work_date);
    if (!d) continue;

    var dayStart = gantt.date.day_start(new Date(d));
    if (!gantt.isWorkTime({ date: dayStart })) continue;

    var ts = dayStart.valueOf();

    // IMPORTANT: hours must be a number
    var h = Number(dt.hours || 0);
    timegrid[ts] = (timegrid[ts] || 0) + h;
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
  var timetable = calculateResourceLoad(resource, timeline.getScale());
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

    // ✅ double click → call BC

    cell.dataset.resourceId = resource.id;
    cell.dataset.workDate = gantt.date.date_to_str("%Y-%m-%d")(day.start_date);
    cell.style.cursor = "pointer";

    cell.addEventListener("dblclick", function (e) {
      e.preventDefault();
      e.stopPropagation();
      
      Microsoft.Dynamics.NAV.InvokeExtensibilityMethod(
        "OpenResourceLoadDay",
        [this.dataset.resourceId, this.dataset.workDate]
      );

      return false;
    }, true); // <-- capture phase helps if gantt stops bubbling

    
    row.appendChild(cell);
  }
  return row;
};
var resourceLayers = [renderResourceLine, "taskBg"];

function LoadResourcesData(resourcesJsonTxt) {
  
  try {
    var payload = _tryParseJson(resourcesJsonTxt);
    if (!payload) return;

    var items = payload;
    if (!Array.isArray(items)) {
      items = payload.resources || payload.Resources || [];
    }

    // ✅ Create the resource datastore ONCE (first time this function is called)
    if (!window.resourcesStore) {
      window.resourcesStore = gantt.createDatastore({
        name: "resources",
        type: "treeDatastore",
        initItem: function (item) {
          // keep it flat
          item.parent = item.parent || 0;
        }
      });
    }

    // ✅ Convert your BC format {key,label} -> DHTMLX format {id,text}
    var mapped = items.map(function (r) {
      return {
        id: r.id || r.key,        // accept both
        text: r.text || r.label   // accept both
      };
    });

    resourcesStore.clearAll();
    resourcesStore.parse(items);

    resourcesStore.refresh();
    gantt.render();
  } catch (e) {
    console.error("LoadResourcesData failed:", e);
  }
}
window.LoadResourcesData = LoadResourcesData;

function LoadDayTasksData(dayTasksJsonTxt) {
  try {
    if (!dayTasksStore) {
      console.warn("LoadDayTasksData: dayTasksStore not ready yet");
      return;
    }


    var items = _tryParseJson(dayTasksJsonTxt);
    if (!items) return;
    if (!Array.isArray(items)) {
      items = items.daytasks || items.dayTasks || items.DayTasks || [];
    }

    // ✅ rebuild index every load
    window.dayTasksByTask = Object.create(null);

    // IMPORTANT:
    // daytask.task MUST match gantt task.id (planning-line level)
    for (var i = 0; i < items.length; i++) {
      var x = items[i];
      var taskId = x.task;

      if (!taskId) continue;

      if (!window.dayTasksByTask[taskId]) {
        window.dayTasksByTask[taskId] = [];
      }

      window.dayTasksByTask[taskId].push(x);
    }

    // Replace all
    if (dayTasksStore.clearAll) dayTasksStore.clearAll();
    dayTasksStore.parse(items);
    // Force repaint of resource timeline/grid
    if (resourcesStore) resourcesStore.refresh();
    gantt.render();
    if (gantt.setSizes) gantt.setSizes();
  } catch (e) {
    console.error("LoadDayTasksData failed:", e);
  }
}
window.LoadDayTasksData = LoadDayTasksData;


function UpsertDayTask(dayTaskJsonTxt, upsertIfMissing = true) {
  try {
    var patch = _tryParseJson(dayTaskJsonTxt);
    if (!patch) return;

    var id = patch.id || patch.Id || patch.key || null;

    if (!id) {
      // build stable id if BC didn’t send one
      id = [
        patch.bcJobNo || "",
        patch.bcJobTaskNo || "",
        patch.work_date || "",
        patch.resource_id || ""
      ].join("|");
      patch.id = id;
    }

    var exists = !!dayTasksStore.getItem(id);
    if (!exists) {
      if (!upsertIfMissing) return;
      dayTasksStore.addItem(patch);
    } else {
      var current = dayTasksStore.getItem(id);
      for (var k in patch) {
        if (!Object.prototype.hasOwnProperty.call(patch, k)) continue;
        current[k] = patch[k];
      }
      dayTasksStore.updateItem(id, current);
    }

    resourcesStore.refresh();
    gantt.render();
  } catch (e) {
    console.error("UpsertDayTask failed:", e, dayTaskJsonTxt);
  }
}
window.UpsertDayTask = UpsertDayTask;

function DeleteDayTask(dayTaskId) {
  try {
    if (!dayTaskId) return;
    var id = String(dayTaskId);
    if (dayTasksStore.getItem(id)) {
      dayTasksStore.deleteItem(id);
      resourcesStore.refresh();
      gantt.render();
    }
  } catch (e) {
    console.error("DeleteDayTask failed:", e, dayTaskId);
  }
}
window.DeleteDayTask = DeleteDayTask;


function InstallDayTaskLayer() {
  if (window._dayTaskLayerInstalled) return;
  window._dayTaskLayerInstalled = true;

  gantt.addTaskLayer(function (task) {
    const lines = (window.dayTasksByTask && window.dayTasksByTask[task.id]) || null;
    console.log("Layer:", task.id, "daytasks:", lines?.length || 0);

    if (!lines || !lines.length) return false;

    const container = document.createElement("div");

    // stack multiple per day (and per resource) so you can see all of them
    const stackSlot = Object.create(null);

    for (let i = 0; i < lines.length; i++) {
      const l = lines[i];
      if (!l.work_date) continue;

      const from = gantt.date.parseDate(l.work_date, "%Y-%m-%d");
      const to = gantt.date.add(from, 1, "day");
      const pos = gantt.getTaskPosition(task, from, to);
      if (!pos || pos.width <= 0) continue;

      const key = l.work_date + "|" + (l.resource_id || "");
      const slot = stackSlot[key] || 0;
      stackSlot[key] = slot + 1;

      const el = document.createElement("div");
      el.className = "daytask-line";
       // ✅ ADD THESE 2 (and keep task.id as the key)
      el.setAttribute("data-task-id", task.id);
      el.setAttribute("data-daytask-id", l.id);
      
      el.style.left = (pos.left + 1) + "px";
      el.style.width = Math.max(4, pos.width - 2) + "px";
      el.style.top = (pos.top + 4 + slot * 10) + "px";
      el.style.height = "8px";

      //el.title = (l.resource_id || "") + " • " + (l.hours || 0) + "h";

      container.appendChild(el);
    }

    return container;
  });
}

function highlightDayTask(el) {
  document
    .querySelectorAll(".daytask-line.selected")
    .forEach(x => x.classList.remove("selected"));

  el.classList.add("selected");
}

function _ensureCustomTooltip() {
  let el = document.getElementById("bc_daytask_tooltip");
  if (el) return el;

  el = document.createElement("div");
  el.id = "bc_daytask_tooltip";
  el.style.position = "fixed";
  el.style.zIndex = "999999";
  el.style.display = "none";
  el.style.pointerEvents = "none";
  el.style.maxWidth = "420px";
  el.style.padding = "8px 10px";
  el.style.borderRadius = "6px";
  el.style.background = "#111";
  el.style.color = "#fff";
  el.style.fontSize = "12px";
  el.style.lineHeight = "1.3";
  el.style.boxShadow = "0 4px 16px rgba(0,0,0,0.35)";
  el.style.whiteSpace = "normal";

  document.body.appendChild(el);
  return el;
}

function _showCustomTooltip(e, html) {
  const tip = _ensureCustomTooltip();
  tip.innerHTML = html;

  // position near mouse, keep inside viewport
  const pad = 12;
  const vw = window.innerWidth;
  const vh = window.innerHeight;

  tip.style.display = "block";
  tip.style.left = "0px";
  tip.style.top = "0px";

  // measure after display
  const w = tip.offsetWidth;
  const h = tip.offsetHeight;

  let x = e.clientX + pad;
  let y = e.clientY + pad;

  if (x + w > vw - 8) x = Math.max(8, vw - w - 8);
  if (y + h > vh - 8) y = Math.max(8, vh - h - 8);

  tip.style.left = x + "px";
  tip.style.top = y + "px";
}

function _hideCustomTooltip() {
  const tip = document.getElementById("bc_daytask_tooltip");
  if (tip) tip.style.display = "none";
}


