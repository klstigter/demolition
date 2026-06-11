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
var DayPlanningsStore = null;
var _isRefreshing = false;
var _resourceFilterInfo = null; // { job, task, periodFrom, periodTo }
var _ganttHolidays = {}; // { "YYYY-MM-DD": "Description", ... } loaded from BC Base Calendar
var skipTrigger_OnJobTaskUpdated = false;

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

    // ah: function hide due to DayPlanning-line class is created during hover on DayPlanning
    // function InstallDayPlanningEvents() {
    //   if (window._DayPlanningEventsInstalled) return;
    //   window._DayPlanningEventsInstalled = true;

    //   gantt.$root.addEventListener("dblclick", function (e) {
    //     debugger;
    //     const el = e.target.closest(".DayPlanning-line");
    //     if (!el) return;

    //     e.preventDefault();
    //     e.stopPropagation();

    //     const DayPlanningId = el.getAttribute("data-DayPlanning-id")||el.dataset.DayPlanningId;
    //     if (!DayPlanningId) return;

    //     // 🔁 call BC
    //     if (window.BC_OnDayPlanningDblClick) {
    //       window.BC_OnDayPlanningDblClick(DayPlanningId);
    //     }
    //   });

    //   gantt.$root.addEventListener("click", function (e) {
    //     const el = e.target.closest(".DayPlanning-line");
    //     if (!el) return;

    //     e.stopPropagation();

    //     const DayPlanningId = el.dataset.DayPlanningId;
    //     highlightDayPlanning(el); // optional visual
    //   });
    // }

    function InstallResourceMarkerCustomTooltipsForDayPlannings() {
      if (document._rmCustomTooltipInstalled) return;
      document._rmCustomTooltipInstalled = true;

      document.addEventListener("mousemove", function (e) {
        const marker = e.target.closest?.(".gantt_resource_marker");
        if (!marker) return;

        const resId = marker.dataset.resourceId;
        const workDate = marker.dataset.workDate;
        const hoursTxt = (marker.textContent || "").trim();

        if (!resId || !workDate) {
          _showCustomTooltip(e, `<b>Marker</b><br/>${hoursTxt || "?"}h`);
          return;
        }

        const all = window.DayPlanningsByTask || {};
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
            `<b>${resId}</b><br/>Date: ${workDate}<br/>Marker: ${hoursTxt}h<br/><i>No DayPlannings</i>`
          );
          return;
        }

        const total = matches.reduce((s, x) => s + (Number(x.hours) || 0), 0);
        const lines = matches.slice(0, 8).map(x => {
          const st = String(x.start_time || "").trim();
          const et = String(x.end_time || "").trim();
          const label = x.task || (x.jobNo + "-" + x.jobTaskNo) || "-";
          const statusTag = x.plan_status === "Request"
            ? ` <span style="background:#909090;color:#fff;border-radius:3px;padding:0 4px;font-size:10px">Request</span>`
            : "";
          const woTag = x.work_order_no ? ` WO:${x.work_order_no}` : "";
          const phTag = x.placeholder_date ? ` (placeholder: ${x.placeholder_date})` : "";
          return `${label}${statusTag}${woTag} • ${x.hours || 0}h • ${st}-${et}${phTag}`;
        }).join("<br/>");

        _showCustomTooltip(
          e,
          `<b>${resId}</b><br/>
          Date: ${workDate}<br/>
          Marker: ${hoursTxt}h<br/>
          DayPlannings total: ${total}h
          <hr style="border:0;border-top:1px solid rgba(255,255,255,0.15);margin:6px 0"/>
          ${lines}${matches.length > 8 ? "<br/>…" : ""}`
        );
      }, true);

      document.addEventListener("mouseout", function (e) {
        const marker = e.target.closest?.(".gantt_resource_marker");
        if (!marker) return;
        if (!marker.contains(e.relatedTarget)) _hideCustomTooltip();
      }, true);
    }

    function InstallResourceGridDblClick() {
      if (document._resGridDblClickInstalled) return;
      document._resGridDblClickInstalled = true;

      document.addEventListener("dblclick", function (e) {
        var cell = e.target.closest(".res-name-cell");
        if (!cell) return;
        e.preventDefault();
        e.stopPropagation();
        var resourceId = cell.getAttribute("data-rid") || "";
        if (!resourceId) return;
        Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("OnResourceDblClick", [resourceId]);
      }, true);
    }

    function InstallResourceGridContextMenu() {
      if (document._resGridContextMenuInstalled) return;
      document._resGridContextMenuInstalled = true;

      var menuCss = [
        "position:fixed",
        "z-index:99999",
        "background:#fff",
        "border:1px solid #ccc",
        "border-radius:4px",
        "box-shadow:2px 4px 12px rgba(0,0,0,0.2)",
        "padding:4px 0",
        "min-width:170px",
        "display:none",
        "font:13px/1.4 sans-serif",
        "cursor:default"
      ].join(";");

      // ── Resource name menu ──
      var menu = document.createElement("div");
      menu.style.cssText = menuCss;
      var currentResourceId = "";

      // ── DayPlanning marker menu ──
      var markerMenu = document.createElement("div");
      markerMenu.style.cssText = menuCss;
      var currentMarkerResourceId = "";
      var currentMarkerWorkDate = "";

      function makeItem(parentMenu, label, onClick) {
        var item = document.createElement("div");
        item.textContent = label;
        item.style.cssText = "padding:7px 18px;white-space:nowrap";
        item.addEventListener("mouseenter", function () { item.style.background = "#e8f0fe"; });
        item.addEventListener("mouseleave", function () { item.style.background = ""; });
        item.addEventListener("mousedown", function (e) {
          e.preventDefault();
          e.stopPropagation();
          hideMenus();
          onClick();
        }, true);
        parentMenu.appendChild(item);
      }

      makeItem(menu, "Resource Scheduler", function () {
        Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("onOpenResourceScheduler", [
          currentResourceId
        ]);
      });
      makeItem(menu, "Show Message 2", function () {
        alert("Message 2 — Resource: " + currentResourceId);
      });

      makeItem(markerMenu, "Open Day Plannings", function () {
        Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("OpenResourceLoadDay", [
          currentMarkerResourceId,
          currentMarkerWorkDate
        ]);
      });

      // ── Empty resource timeline cell menu ──
      var emptyMenu = document.createElement("div");
      emptyMenu.style.cssText = menuCss;
      var RightClickedResourceId = "";
      var RightClickedWorkDate   = "";

      makeItem(emptyMenu, "Add Day Planning", function () {
        if (!RightClickedResourceId || !RightClickedWorkDate) return;
        Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("onAddDayPlanning", [
          RightClickedResourceId,
          RightClickedWorkDate
        ]);
      });

      function hideMenus() {
        menu.style.display = "none";
        markerMenu.style.display = "none";
        emptyMenu.style.display = "none";
      }

      function positionMenu(m, x, y) {
        m.style.left = x + "px";
        m.style.top  = y + "px";
        m.style.display = "block";
        var rect = m.getBoundingClientRect();
        if (rect.right  > window.innerWidth)  m.style.left = Math.max(0, x - rect.width)  + "px";
        if (rect.bottom > window.innerHeight) m.style.top  = Math.max(0, y - rect.height) + "px";
      }

      document.body.appendChild(menu);
      document.body.appendChild(markerMenu);
      document.body.appendChild(emptyMenu);

      // Right-click on a resource name cell, a DayPlanning marker, or an empty timeline cell
      document.addEventListener("contextmenu", function (e) {
        var resCell    = e.target.closest(".res-name-cell");
        var markerCell = e.target.closest(".gantt_resource_marker");

        // Detect empty resource timeline cell (click lands on timeline bg, not a marker)
        var emptyCell = null;
        if (!resCell && !markerCell) {
          try {
            var rtView = gantt.$ui && gantt.$ui.getView && gantt.$ui.getView("resourceTimeline");
            if (rtView && rtView.$task_data && rtView.$task_data.contains(e.target)) {
              emptyCell = e.target;
            }
          } catch (_) {}
        }

        if (!resCell && !markerCell && !emptyCell) { hideMenus(); return; }
        e.preventDefault();
        e.stopPropagation();
        hideMenus();

        if (markerCell) {
          currentMarkerResourceId = markerCell.dataset.resourceId || "";
          currentMarkerWorkDate   = markerCell.dataset.workDate   || "";
          positionMenu(markerMenu, e.clientX, e.clientY);
        } else if (emptyCell) {
          try {
            var rtView2  = gantt.$ui.getView("resourceTimeline");
            var rect     = rtView2.$task_data.getBoundingClientRect();
            var scroll   = gantt.getScrollState();
            var x        = e.clientX - rect.left + (scroll ? scroll.x : 0);
            var clickDate = gantt.dateFromPos ? gantt.dateFromPos(x) : null;
            if (!clickDate) { return; }
            clickDate = gantt.date.day_start(clickDate);
            var fmt = gantt.date.date_to_str("%Y-%m-%d");
            RightClickedWorkDate = fmt(clickDate);

            var resScrollTop = rtView2.$task_data.scrollTop || 0;
            var relY     = e.clientY - rect.top + resScrollTop;
            var rowIndex = Math.floor(relY / (gantt.config.row_height || 30));
            var resources = resourcesStore ? resourcesStore.getItems() : [];
            var resource  = (rowIndex >= 0 && rowIndex < resources.length) ? resources[rowIndex] : null;
            RightClickedResourceId = resource ? String(resource.id) : "";
            positionMenu(emptyMenu, e.clientX, e.clientY);
          } catch (_) {}
        } else {
          currentResourceId = resCell.getAttribute("data-rid") || "";
          positionMenu(menu, e.clientX, e.clientY);
        }
      }, true);

      // Click or Escape anywhere → hide all menus
      document.addEventListener("mousedown", function (e) {
        if (!menu.contains(e.target) && !markerMenu.contains(e.target) && !emptyMenu.contains(e.target)) hideMenus();
      }, true);
      document.addEventListener("keydown", function (e) {
        if (e.key === "Escape") hideMenus();
      });
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
    
    //mapping resource property and DayPlannings resource property
    gantt.config.resource_property = "resource_id";


    // -------- WEEKEND + HOLIDAY HIGHLIGHT --------
    var _dateFmt = gantt.date.date_to_str("%Y-%m-%d");
    gantt.templates.scale_cell_class = function (date) {
      var d = date.getDay();
      if (d === 0 || d === 6) return "weekend";
      if (_ganttHolidays[_dateFmt(date)]) return "holiday";
      return "";
    };
    gantt.templates.timeline_cell_class = function (item, date) {
      var d = date.getDay();
      if (d === 0 || d === 6) return "weekend";
      if (_ganttHolidays[_dateFmt(date)]) return "holiday";
      return "";
    };

    // -------- TASK TYPE CLASS (CSS hook) --------
    gantt.templates.task_class = function (start, end, task) {
      var cls = task.schedulingType || "";
      if (window.requestJobTaskSet && window.requestJobTaskSet[task.id]) {
        cls = (cls ? cls + " " : "") + "bc-task-bold";
      }
      return cls;
    };

    // -------- PROGRESS TEXT ON TASK BAR --------
    gantt.templates.progress_text = function (start, end, task) {
      var p = task.progress || 0;
      var pct = Math.round(p * 100);
      return pct > 0 ? pct + "" : "";
    };

    // Normalize BC progress (0-100 → 0-1) and move color off task.color.
    // IMPORTANT: do NOT set task.color here.
    // When task.color is truthy, DHTMLX adds the gantt_task_inline_color CSS class and
    // sets --dhx-gantt-task-background as an inline style on the outer wrapper.
    // For project/parent tasks the auto_scheduling plugin creates TWO inner bars
    // (gantt_task_line_planned + gantt_task_line_actual), both with a .gantt_project
    // CSS class that re-declares --dhx-gantt-task-background → project-green.
    // That conflict produces the striped appearance.
    // Instead we store the color in task._bcColor and emit --bc-bar / --bc-prog
    // via task_style, which DHTMLX never touches.
    gantt.attachEvent("onTaskLoading", function (task) {
      if (typeof task.progress === "number" && task.progress > 1) {
        task.progress = Math.min(task.progress, 100) / 100;
      }
      // Use DHTMLX native task.color / task.progressColor.
      // task.color  → DHTMLX sets --dhx-gantt-task-background as inline style on the outer wrapper.
      // task.progressColor → DHTMLX sets style.backgroundColor directly on .gantt_task_progress.
      if (!task.color) {
        task.color = "#3b8ef0";
      }
      task.progressColor = _darkenHex(task.color, 0.60);
      return true;
    });

    // -------- PROGRESS BAR ON TASK BARS --------
    gantt.config.show_progress = true;

    // -------- WORK TIME --------
    // Keep work_time OFF so that `duration` is always calendar days (matching BC's Integer Duration field).  
    // With work_time=true, DHTMLX interprets duration as
    // working days, which stretches the bar length whenever a drag crosses weekends.
    gantt.config.work_time = false;
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
    // expand state is driven by the 'open' field on each task JSON sent from BC

    // -------- COLUMNS --------
    gantt.config.columns = [
      { name: "text", tree: true, resize: false, width: 250, editor: textEditor },
      { name: "progress", label: "%", align: "center", resize: false, width: 60,
        editor: progressEditor,
          template: function (task) { var p = task.progress || 0; return Math.round(p * 100) + "%"; }
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
        Period: ${task.start_date ? gantt.templates.date_grid(task.start_date) : "-"} - ${task.end_date ? gantt.templates.date_grid(task.end_date) : "-"}<br/>
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


    // -------- CONTEXT MENU (right-click) --------
    (function injectContextMenuCSS() {
      var s = document.createElement("style");
      s.textContent = [
        "#gantt-ctx-menu{",
        "  position:fixed;z-index:99999;",
        "  background:#fff;border:1px solid #d0d0d0;",
        "  border-radius:6px;box-shadow:0 4px 16px rgba(0,0,0,.18);",
        "  min-width:170px;padding:4px 0;font:13px/1.4 Segoe UI,sans-serif;",
        "  user-select:none;",
        "}",
        "#gantt-ctx-menu .ctx-item{",
        "  display:flex;align-items:center;gap:10px;",
        "  padding:8px 18px;cursor:pointer;color:#222;",
        "  transition:background .12s;",
        "}",
        "#gantt-ctx-menu .ctx-item:hover{ background:#f0f4ff; color:#1a56db; }",
        "#gantt-ctx-menu .ctx-item.ctx-cancel{ color:#888; }",
        "#gantt-ctx-menu .ctx-item.ctx-cancel:hover{ background:#fafafa; color:#555; }",
        "#gantt-ctx-menu .ctx-sep{",
        "  height:1px;background:#eee;margin:4px 0;",
        "}",
        "#gantt-ctx-menu .ctx-icon{ font-size:15px; width:18px; text-align:center; }"
      ].join("\n");
      document.head.appendChild(s);
    })();

    // Helper: build & show context menu at (x,y) for task id
    window._ganttCtxTaskId = null;
    function _showContextMenu(x, y, taskId) {
      _hideContextMenu();
      window._ganttCtxTaskId = taskId;

      var menu = document.createElement("div");
      menu.id = "gantt-ctx-menu";

      var items = [
        { label: "Summary",              icon: "&#x1F4C4;", cls: "ctx-show-summary" },
        { label: "Show Job Resources",   icon: "&#x1F465;", cls: "ctx-show-resources" },
        { sep: true },
        { label: "Open Task",            icon: "&#x1F4CB;", cls: "ctx-open-task" },
        { label: "Open DayPlanning",         icon: "&#x1F4C5;", cls: "ctx-open-DayPlanning" },
        { label: "Open DayPlanning Visual",  icon: "&#x1F4C5;", cls: "ctx-open-DayPlanningvisual" },
        { sep: true },
        { label: "Cancel",               icon: "&#x2715;",  cls: "ctx-cancel" }
      ];

      items.forEach(function(item) {
        if (item.sep) {
          var sep = document.createElement("div");
          sep.className = "ctx-sep";
          menu.appendChild(sep);
          return;
        }
        var el = document.createElement("div");
        el.className = "ctx-item " + item.cls;
        el.innerHTML = '<span class="ctx-icon">' + item.icon + '</span>' + item.label;
        el.addEventListener("mousedown", function(e) { e.stopPropagation(); });
        el.addEventListener("click", function() {
          _hideContextMenu();
          if (item.cls === "ctx-show-summary") _ctxShowSummary(taskId);
          if (item.cls === "ctx-show-resources") _ctxShowResources(taskId);
          if (item.cls === "ctx-open-task")      _ctxOpenTask(taskId);
          if (item.cls === "ctx-open-DayPlanning")   _ctxOpenDayPlanning(taskId);
          if (item.cls === "ctx-open-DayPlanningvisual")   _ctxOpenDayPlanningVisual(taskId);
          // cancel: just close
        });
        menu.appendChild(el);
      });

      document.body.appendChild(menu);

      // Position: keep within viewport
      var vw = window.innerWidth, vh = window.innerHeight;
      var mw = menu.offsetWidth || 180, mh = menu.offsetHeight || 140;
      menu.style.left = (x + mw > vw ? vw - mw - 6 : x) + "px";
      menu.style.top  = (y + mh > vh ? vh - mh - 6 : y) + "px";
    }

    function _hideContextMenu() {
      var old = document.getElementById("gantt-ctx-menu");
      if (old) old.parentNode.removeChild(old);
      window._ganttCtxTaskId = null;
    }

    // Close on any outside click
    document.addEventListener("mousedown", function(e) {
      var menu = document.getElementById("gantt-ctx-menu");
      if (menu && !menu.contains(e.target)) _hideContextMenu();
    }, true);

    // Close on scroll / Escape
    document.addEventListener("keydown", function(e) {
      if (e.key === "Escape") _hideContextMenu();
    }, true);

    // Open Task — same logic as dblclick
    function _ctxOpenTask(id) {
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
          bcRecordId: task.bcRecordId,
          bcTableNo: task.bcTableNo,
          bcDocumentNo: task.bcDocumentNo
        };
        Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("onTaskDblClick", [
          String(id),
          JSON.stringify(eventData)
        ]);
      } catch (e) {
        console.error("_ctxOpenTask failed:", e);
      }
    }

    // Show Summary — open summary panel for this task
    function _ctxShowSummary(id) {
      try {
        var fmt = gantt.date.date_to_str("%Y-%m-%d");
        var task = gantt.getTask(id);
        var periodFrom = task && task.start_date ? fmt(task.start_date) : "";
        var periodTo   = task && task.end_date   ? fmt(task.end_date)   : "";

        // Collect direct children of this task
        var children = [];
        gantt.eachTask(function(child) {
          children.push({
            id: String(child.id),
            text: child.text || "",
            bcJobNo: child.bcJobNo || "",
            bcJobTaskNo: child.bcJobTaskNo || "",
            start_date: child.start_date ? fmt(child.start_date) : "",
            end_date: child.end_date ? fmt(child.end_date) : ""
          });
        }, id);
        var childrenJson = JSON.stringify(children);

        Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("OnShowSummaryForTask", [ String(id), childrenJson, periodFrom, periodTo ]);
      } catch (e) {
        console.error("_ctxShowSummary failed:", e);
      }
    }

    // Show Resources — open resource panel filtered to this task's Day Planning resources
    function _ctxShowResources(id) {
      try {
        var fmt = gantt.date.date_to_str("%Y-%m-%d");
        var task = gantt.getTask(id);
        var periodFrom = task && task.start_date ? fmt(task.start_date) : "";
        var periodTo   = task && task.end_date   ? fmt(task.end_date)   : "";

        // Collect direct children of this task
        var children = [];
        gantt.eachTask(function(child) {
          children.push({
            id: String(child.id),
            text: child.text || "",
            bcJobNo: child.bcJobNo || "",
            bcJobTaskNo: child.bcJobTaskNo || "",
            start_date: child.start_date ? fmt(child.start_date) : "",
            end_date: child.end_date ? fmt(child.end_date) : ""
          });
        }, id);
        var childrenJson = JSON.stringify(children);

        Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("OnShowResourcesForTask", [ String(id), childrenJson, periodFrom, periodTo ]);
      } catch (e) {
        console.error("_ctxShowResources failed:", e);
      }
    }

    // Open DayPlanning — BC event for day-task card
    function _ctxOpenDayPlanning(id) {
      try {
        var task = gantt.getTask(id);
        var eventData = {
          id: id,
          bcJobNo: task.bcJobNo || "",
          bcJobTaskNo: task.bcJobTaskNo || "",
          bcRecordId: task.bcRecordId || "",
          bcTableNo: task.bcTableNo || "",
          bcDocumentNo: task.bcDocumentNo || ""
        };
        Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("onOpenDayPlanning", [
          String(id),
          JSON.stringify(eventData)
        ]);
      } catch (e) {
        console.error("_ctxOpenDayPlanning failed:", e);
      }
    }

        // Open DayPlanning — BC event for day-task card
    function _ctxOpenDayPlanningVisual(id) {
      try {
        var task = gantt.getTask(id);
        var eventData = {
          id: id,
          bcJobNo: task.bcJobNo || "",
          bcJobTaskNo: task.bcJobTaskNo || "",
          bcRecordId: task.bcRecordId || "",
          bcTableNo: task.bcTableNo || "",
          bcDocumentNo: task.bcDocumentNo || ""
        };
        Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("onOpenDayPlanningVisual", [
          String(id),
          JSON.stringify(eventData)
        ]);
      } catch (e) {
        console.error("_ctxOpenDayPlanningVisual failed:", e);
      }
    }
    // Attach right-click event
    gantt.attachEvent("onContextMenu", function(id, linkId, e) {
      if (!id) return false; // no task clicked — let browser default
      e.preventDefault();
      _showContextMenu(e.clientX, e.clientY, id);
      return true;
    });

    // -------- LINK HOVER TOOLTIP --------
    gantt.attachEvent("onGanttReady", function() {
      var _currentLinkId = null;
      var _currentLinkHtml = "";

      gantt.$root.addEventListener("mouseover", function(e) {
        // link_id attribute lives on .gantt_task_link (the outer container)
        var linkEl = e.target.closest ? e.target.closest(".gantt_task_link") : null;
        if (!linkEl) {
          if (_currentLinkId) { _currentLinkId = null; _hideCustomTooltip(); }
          return;
        }

        var linkId = linkEl.getAttribute("link_id");
        if (!linkId || !gantt.isLinkExists(linkId)) return;
        if (linkId === _currentLinkId) return; // already showing for this link

        _currentLinkId = linkId;
        var link = gantt.getLink(linkId);
        var sourceTask = gantt.isTaskExists(link.source) ? gantt.getTask(link.source) : null;
        var targetTask = gantt.isTaskExists(link.target) ? gantt.getTask(link.target) : null;

        var typeMap = {
          "0": "Finish \u2192 Start",
          "1": "Start \u2192 Start",
          "2": "Finish \u2192 Finish",
          "3": "Start \u2192 Finish"
        };
        var typeLabel = typeMap[String(link.type)] || ("Type " + link.type);

        _currentLinkHtml =
          "<b>Dependency</b>" +
          "<hr style='margin:4px 0;border:none;border-top:1px solid #555'/>" +
          "From: <b>" + (sourceTask ? sourceTask.text : link.source) + "</b><br/>" +
          "To: &nbsp;&nbsp;&nbsp;<b>" + (targetTask ? targetTask.text : link.target) + "</b><br/>" +
          "Type: " + typeLabel;
        if (link.lag) _currentLinkHtml += "<br/>Lag: " + link.lag + " day(s)";

        _showCustomTooltip(e, _currentLinkHtml);
      }, true);

      gantt.$root.addEventListener("mousemove", function(e) {
        if (!_currentLinkId) return;
        var linkEl = e.target.closest ? e.target.closest(".gantt_task_link") : null;
        if (linkEl) {
          _showCustomTooltip(e, _currentLinkHtml); // reposition tooltip with cursor
        } else {
          _currentLinkId = null;
          _hideCustomTooltip();
        }
      }, true);

      // mouseleave on the gantt root clears any dangling tooltip
      gantt.$root.addEventListener("mouseleave", function() {
        _currentLinkId = null;
        _hideCustomTooltip();
      }, true);
    });

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
    // _dragInProgress is true from the moment onAfterTaskDrag fires until a
    // short timeout clears it. This suppresses ALL onAfterTaskUpdate calls
    // that originate from the drag itself OR from auto-scheduling cascades
    // (dependent tasks with different IDs that would otherwise each open
    // their own BC popup).
    var _dragInProgress = false;

    // _reloadInProgress is true while LoadProjectData is running a gantt.silent()
    // reload. gantt.silent() defers events and flushes them synchronously when
    // the block exits, which can fire onAfterTaskUpdate for every reloaded task
    // (even though the data came from BC, not from a user edit). Without this
    // guard, each of those phantom updates would re-open the period-sync popup.
    var _reloadInProgress = false;

    // ── Drag: redraw request overlay bars in real-time as the task moves ─────
    gantt.attachEvent("onTaskDrag", function (id, mode, task, original) {
      _renderRequestBars();
      return true;
    });

    // ── Drag: send OnJobTaskUpdated exactly once per drag operation ──────────
    gantt.attachEvent("onAfterTaskDrag", function (id, mode, e) {
      var task = gantt.getTask(id);
      // Block ALL onAfterTaskUpdate calls while drag + auto-scheduling settle.
      _dragInProgress = true;
      setTimeout(function () { _dragInProgress = false; }, 300);
      // Redraw overlay bars to their final position after the drag snaps
      _renderRequestBars();
      try {
        var fmt = gantt.date.date_to_str(gantt.config.date_format);
        var payload = {
          id: String(id),
          bcJobNo: task.bcJobNo || "",
          bcJobTaskNo: task.bcJobTaskNo || "",
          text: task.text || "",
          start_date: task.start_date ? fmt(task.start_date) : null,
          end_date: task.end_date ? fmt(task.end_date) : null,
          duration: task.duration || 0,
          schedulingType: task.schedulingType || "",
          constraint_type: task.constraint_type || "",
          constraint_date: task.constraint_date ? fmt(task.constraint_date) : null
        };
        debugger;
        if (!skipTrigger_OnJobTaskUpdated)
        { 
            Microsoft.Dynamics.NAV.InvokeExtensibilityMethod(
              "OnJobTaskUpdated",
              [ JSON.stringify(payload) ]
            );
        } else {
          skipTrigger_OnJobTaskUpdated = false; // reset for next time
        }
      } catch (e) { /* ignore */ }
      return true;
    });

    // ── Non-drag saves (lightbox, inline edit) ────────────────────────────────
    gantt.attachEvent("onAfterTaskUpdate", function (id, task) {
      // Suppress updates from a drag cascade OR from a BC-triggered reload.
      if (_dragInProgress || _reloadInProgress) return;
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
        debugger;
        if (!skipTrigger_OnJobTaskUpdated)
        {
            Microsoft.Dynamics.NAV.InvokeExtensibilityMethod(
              "OnJobTaskUpdated",
              [ JSON.stringify(payload) ]
            );
        } else {
          skipTrigger_OnJobTaskUpdated = false; // reset for next time
        }
      } catch (e) {
        // ignore if not wired yet
      }
    });

    // -------- LINK EVENTS (BC callback) --------
    gantt.attachEvent("onAfterLinkAdd", function (id, link) {
      try {
        var payload = {
          id:     String(id),
          source: String(link.source || ""),
          target: String(link.target || ""),
          type:   String(link.type   || "0"),
          lag:    Number(link.lag    || 0)
        };
        Microsoft.Dynamics.NAV.InvokeExtensibilityMethod(
          "OnLinkCreated",
          [ JSON.stringify(payload) ]
        );
      } catch (e) {
        console.error("OnLinkCreated callback failed:", e);
      }
    });

    gantt.attachEvent("onAfterLinkDelete", function (id, link) {
      try {
        var payload = {
          id:     String(id),
          source: String(link.source || ""),
          target: String(link.target || ""),
          type:   String(link.type   || "0"),
          lag:    Number(link.lag    || 0)
        };
        Microsoft.Dynamics.NAV.InvokeExtensibilityMethod(
          "OnLinkDeleted",
          [ JSON.stringify(payload) ]
        );
      } catch (e) {
        console.error("OnLinkDeleted callback failed:", e);
      }
    });

    // Datastores
    resourcesStore = gantt.createDatastore({
      name: "resources",
      initItem: function (item) { item.id = item.key || gantt.uid(); return item; }
    });

    // DayPlannings datastore (your BC Day Plannings table)
    DayPlanningsStore = gantt.createDatastore({
      name: "DayPlannings",
      initItem: function (item) {
        // unique key for upsert: JobNo|JobTaskNo|WorkDate|ResourceNo
        item.id = item.id || item.key || gantt.uid();
        return item;
      }
    });

    // Note: Resource refresh is handled explicitly by BC, not by auto-events

    // Note: Layout will be created dynamically in RecreateGanttLayout()

    // Resource CSS
    (function injectResourceCSS() {
      var css = ""
        + ".gantt_resource_marker{ border-radius:4px; color:#fff; }"
        + ".gantt_resource_marker_ok{ background:#21b36c; }"
        + ".gantt_resource_marker_overtime{ background:#e74c3c; }"
        + ".gantt_resource_marker_request{ background:#909090 !important; border:1px solid #666 !important; opacity:0.9; }"
        /* ── Panel header: black background, white bold font ── */
        + ".gantt_grid_scale { background:#000 !important; }"
        + ".gantt_grid_head_cell { color:#fff !important; font-weight:bold !important; border-color:#333 !important; }"
        + ".gantt_grid_head_cell .gantt_grid_head_add { color:#fff !important; }"
        /* resource panel header */
        + ".gantt_resource_grid .gantt_grid_scale { background:#000 !important; }"
        + ".gantt_resource_grid .gantt_grid_head_cell { color:#fff !important; font-weight:bold !important; border-color:#333 !important; }"
        /* ── Resource filter info icon ── */
        + ".res-filter-icon { display:inline-block; margin-left:5px; cursor:pointer; font-size:13px; color:#adf; opacity:0.85; vertical-align:middle; }"
        + ".res-filter-icon:hover { opacity:1; }"
        /* ── Fixed body-level tooltip (never clipped by overflow:hidden) ── */
        + "#res-filter-tooltip-popup { display:none; position:fixed; background:#1a1a2e; color:#e0e0e0; border:1px solid #4a6fa5; border-radius:5px; padding:8px 12px; font-size:12px; font-weight:normal; white-space:nowrap; z-index:999999; box-shadow:0 3px 10px rgba(0,0,0,0.5); min-width:180px; pointer-events:none; }";
      var s = document.createElement("style");
      s.textContent = css;
      document.head.appendChild(s);
    })();

    // -------- BAR AND PROGRESS STYLING --------
    // DHTMLX native rendering:
    //   task.color      → DHTMLX sets --dhx-gantt-task-background as inline style on the outer wrapper div.
    //   task.progressColor → DHTMLX calls el.style.backgroundColor = task.progressColor directly.
    //
    // Problem with project/parent tasks (auto_scheduling plugin):
    //   DHTMLX renders TWO inner divs inside the outer wrapper:
    //     .gantt_task_line_planned  (5px bracket bar)
    //     .gantt_task_line_actual   (8px bar, opacity 0.3)
    //   Both have the .gantt_project CSS class which RE-DECLARES
    //   --dhx-gantt-task-background: var(--dhx-gantt-project-background) [green]
    //   on the inner element itself → overrides inheritance from parent → stripes.
    //
    // Fix: force .gantt_task_line_actual to inherit the custom property from its
    //   parent (where DHTMLX already set it via inline style from task.color).
    //   CSS !important on custom properties works in all modern browsers.
    (function injectBarCSS() {
      var s = document.createElement("style");
      s.textContent = [
        /* ── Project/parent task solid-bar fix ─────────────────────────────── */
        /* Hide the thin 5px bracket bar */
        ".gantt_task_line_planned { display: none !important; }",

        /* Make the actual bar full-height, fully opaque, and inherit the color
           the outer wrapper already has set as inline style via task.color */
        ".gantt_task_line.gantt_task_line_actual {",
        "  opacity: 1 !important;",
        "  top: 0 !important;",
        "  height: 100% !important;",
        "  --dhx-gantt-task-background: inherit !important;",
        "}",

        /* ── Progress fill cosmetics ────────────────────────────────────────── */
        /* task.progressColor is applied by DHTMLX via el.style.backgroundColor */
        /* Thin white separator at progress boundary */
        ".gantt_task_progress { border-right: 2px solid rgba(255,255,255,0.55); box-sizing: border-box; }",

        /* Clip fill inside bar corners */
        ".gantt_task_progress_wrapper { overflow: hidden; border-radius: inherit; height: 100%; }",

        /* Drag handle */
        ".gantt_task_progress_drag { background: rgba(255,255,255,0.90); width: 6px; border-radius: 2px; bottom: 4px; margin-left: -3px; box-shadow: 0 0 3px rgba(0,0,0,0.45); }"
      ].join("\n");
      document.head.appendChild(s);
    })();

    // ✅ ENGINE INIT (once) - layout will be set dynamically
    // Initial layout with resource panel visible
    RecreateGanttLayout(true);
    gantt.init("gantt_here");

    // ── Placeholder-date bar: injected directly into $task_data on every render ──────────────────
    // (addTaskLayer wrapper approach was unreliable; direct DOM injection is simpler and guaranteed)
    // NOTE: _renderRequestBars() is called from onGanttRender below

    // Apply queued column settings if AL called too early
    if (_queuedColumnArgs) {
      _applyColumnSettings(_queuedColumnArgs);
      _queuedColumnArgs = null;
    }
    
    console.log("tooltip ext:", gantt.ext && (gantt.ext.tooltip || gantt.ext.tooltips));
    
    //InstallDayPlanningLayer();   // ✅ install once
    //InstallDayPlanningEvents(); // ✅ install once //ah: the function is hide, see on top lines
    InstallResourceMarkerCustomTooltipsForDayPlannings(); // ✅ install once
    InstallResourceGridDblClick(); // ✅ install once
    InstallResourceGridContextMenu(); // ✅ install once

    // ✅ Update resource panel header tooltip + Request bar overlays after every render
    gantt.attachEvent("onGanttRender", function() {
      _updateResourceHeaderTooltip();
      _renderRequestBars();
    });

    // ✅ Tell AL we are safe to call now
    Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("ControlReady", []);

  } catch (e) {
    console.warn("BOOT warning:", e);
  }
}

// -------------------------------------------------------
// Request-DayPlanning bar overlay — rendered directly into $task_data after each gantt render
// -------------------------------------------------------
function _renderRequestBars() {
  try {
    if (!window.DayPlanningsByTask) return;

    // Resolve $task_data container (handles both simple and multi-view layouts)
    var container = gantt.$task_data
      || (gantt.$ui && gantt.$ui.getView("timeline") && gantt.$ui.getView("timeline").$task_data);
    if (!container) return;

    // Remove bars from previous render
    var old = container.querySelectorAll(".bc-req-bar");
    for (var i = 0; i < old.length; i++) {
      old[i].parentNode && old[i].parentNode.removeChild(old[i]);
    }

    gantt.eachTask(function (task) {
      var dtList = window.DayPlanningsByTask[task.id];
      if (!dtList || !dtList.length) return;

      var taskPos = gantt.getTaskPosition(task, task.start_date, task.end_date);
      if (!taskPos) return;

      var seenDate = Object.create(null);
      for (var i = 0; i < dtList.length; i++) {
        var dt = dtList[i];
        if (dt.plan_status !== "Request" || !dt.placeholder_date) continue;
        if (seenDate[dt.placeholder_date]) continue;
        seenDate[dt.placeholder_date] = true;

        var pd = gantt.date.parseDate(dt.placeholder_date, "%Y-%m-%d");
        if (!pd) continue;
        var pdEnd = gantt.date.add(new Date(pd.valueOf()), 1, "day");

        var pos = gantt.getTaskPosition(task, pd, pdEnd);
        if (!pos) continue;

        var el = document.createElement("div");
        el.className = "bc-req-bar";
        el.style.position = "absolute";
        el.style.left    = pos.left + "px";
        el.style.top     = taskPos.top + "px";
        el.style.width   = Math.max(pos.width, 6) + "px";
        el.style.height  = taskPos.height + "px";
        el.style.background    = "rgba(0,0,0,0.85)";
        el.style.borderRadius  = "3px";
        el.style.pointerEvents = "none";
        el.style.zIndex        = "10";
        container.appendChild(el);
      }
    });
  } catch (e) {
    console.warn("_renderRequestBars:", e);
  }
}

// -------------------------------------------------------
// Dynamic Layout Recreation (like scheduler's RecreateTimelineView)
// -------------------------------------------------------
function RecreateGanttLayout(showResourcePanel) {
  try {
    var mainGridConfig = { columns: gantt.config.columns };
    var resourcePanelConfig = {
      columns: [
        { name: "name", label: "Name", template: function (r) {
            var id = String(r.id || "").replace(/"/g, "&quot;");
            var label = r.text || r.label || "";
            return '<span class="res-name-cell" data-rid="' + id + '">' + label + '</span>';
          }
        },
        {
          name: "workload", label: "Total Hours", align: "center", template: function (r) {
            // Calculate total hours from DayPlanningsStore
            var total = 0;
            if (DayPlanningsStore) {
              var allDayPlannings = DayPlanningsStore.getItems();
              for (var i = 0; i < allDayPlannings.length; i++) {
                var dt = allDayPlannings[i];
                if (String(dt.resource_id || "") === String(r.id || "")) {
                  total += Number(dt.hours || 0);
                }
              }
            }
            return '<div style="text-align:center;width:100%;">' + total + 'h</div>';
          }
        }
      ]
    };

    if (showResourcePanel) {
      // Layout WITH resource panel
      gantt.config.layout = {
        css: "gantt_container",
        rows: [
          {
            cols: [
              { view: "grid", group: "grids", config: mainGridConfig, scrollY: "scrollVer" },
              { resizer: true, width: 1, group: "vertical" },
              { view: "timeline", id: "timeline", scrollX: "scrollHor", scrollY: "scrollVer" },
              { view: "scrollbar", id: "scrollVer", group: "vertical" }
            ],
            gravity: 2
          },
          { resizer: true, width: 1 },
          {
            config: resourcePanelConfig,
            cols: [
              { view: "grid", id: "resourceGrid", group: "grids", bind: "resources", scrollY: "resourceVScroll" },
              { resizer: true, width: 1, group: "vertical" },
              { view: "timeline", id: "resourceTimeline", bind: "resources", bindLinks: null, layers: resourceLayers, scrollX: "scrollHor", scrollY: "resourceVScroll" },
              { view: "scrollbar", id: "resourceVScroll", group: "vertical" }
            ],
            gravity: 1
          },
          { view: "scrollbar", id: "scrollHor" }
        ]
      };
    } else {
      // Layout WITHOUT resource panel
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
          { view: "scrollbar", id: "scrollHor" }
        ]
      };
    }

    // If gantt is already initialized, apply the new layout
    if (gantt.$root) {
      gantt.resetLayout();
    }

    console.log("Gantt layout recreated, resource panel:", showResourcePanel ? "visible" : "hidden");
  } catch (e) {
    console.error("RecreateGanttLayout failed:", e);
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

  // ✅ ADD THESE to strictly respect project boundaries
  gantt.config.start_date = gantt.config.project_start;
  gantt.config.end_date = gantt.config.project_end;
  gantt.config.fit_tasks = false; // Don't auto-expand timeline to fit tasks
  
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
// Finalize Refresh - Call this after all data is loaded
// -------------------------------------------------------
function RenderGantt(pskipTrigger_OnJobTaskUpdated) {
  try {  
    skipTrigger_OnJobTaskUpdated = pskipTrigger_OnJobTaskUpdated;
    if (!gantt_here || typeof gantt === "undefined" || !gantt.$root) {
      console.warn("RenderGantt: Gantt not initialized");
      return;
    }

    // Final render after all data loaded
    gantt.render();
    
    // Reset refresh flag
    _isRefreshing = false;
    
    console.log("Gantt render completed, refresh flag reset");
  } catch (e) {
    console.error("RenderGantt failed:", e);
    _isRefreshing = false;
  }
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

// Darkens a hex/rgb color string by the given factor (0=black, 1=original)
function _darkenHex(color, factor) {
  try {
    var r, g, b;
    var s = String(color).trim();

    // Handle rgb(...) or rgba(...)
    var rgbMatch = s.match(/rgba?\(\s*(\d+)[,\s]+(\d+)[,\s]+(\d+)/);
    if (rgbMatch) {
      r = parseInt(rgbMatch[1], 10);
      g = parseInt(rgbMatch[2], 10);
      b = parseInt(rgbMatch[3], 10);
    } else {
      // Handle 3 or 6 digit hex (optionally with #)
      var c = s.replace("#", "");
      if (c.length === 3) c = c[0]+c[0]+c[1]+c[1]+c[2]+c[2];
      if (/^[0-9a-fA-F]{6}/.test(c)) {
        r = parseInt(c.substr(0, 2), 16);
        g = parseInt(c.substr(2, 2), 16);
        b = parseInt(c.substr(4, 2), 16);
      } else {
        // Fallback: resolve any CSS color (named, hsl, etc.) via canvas
        var cv = document.createElement("canvas");
        cv.width = cv.height = 1;
        var ctx = cv.getContext("2d");
        ctx.fillStyle = s;
        ctx.fillRect(0, 0, 1, 1);
        var px = ctx.getImageData(0, 0, 1, 1).data;
        r = px[0]; g = px[1]; b = px[2];
      }
    }
    r = Math.round(r * factor);
    g = Math.round(g * factor);
    b = Math.round(b * factor);
    return "rgb(" + r + "," + g + "," + b + ")";
  } catch (e) {
    return "rgba(0,0,0,0.45)";
  }
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
  try {
    if (_isRefreshing) {
      console.warn("Refresh already in progress, skipping ClearData");
      return;
    }
    _isRefreshing = true; // Will be reset by RenderGantt()
    
    // Clear the DayPlannings index first
    if (window.DayPlanningsByTask) {
      window.DayPlanningsByTask = Object.create(null);
    }
    
    // Clear DayPlannings datastore
    if (DayPlanningsStore && DayPlanningsStore.clearAll) {
      DayPlanningsStore.clearAll();
    }
    
    // Clear resource datastore
    if (resourcesStore && resourcesStore.clearAll) {
      resourcesStore.clearAll();
    }
    
    // Clear main gantt tasks and links
    gantt.clearAll();
    
    console.log("ClearData completed, waiting for data load...");
  } catch (e) {
    console.error("ClearData failed:", e);
    _isRefreshing = false;
  }
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
      gantt.silent(function () {
        gantt.clearAll();
        gantt.render();
      });
      return;
    }

    // ✅ accept array payload = tasks[]
    if (Array.isArray(payload)) {
      payload = { tasks: payload, links: [] };
    }

    var tasks = payload.tasks || payload.data || payload.Tasks || payload.Data || [];
    var links = payload.links || payload.Links || [];

    // Optional: project range in payload
    if (payload.project_start)
      gantt.config.project_start = _toGanttDate(payload.project_start) || gantt.config.project_start;

    if (payload.project_end)
      gantt.config.project_end = _toGanttDate(payload.project_end) || gantt.config.project_end;

    // 🔇 SILENT LOAD (this is the key)
    // Set the reload guard BEFORE silent() so that any onAfterTaskUpdate events
    // deferred inside the block (and flushed synchronously on silent() exit)
    // are suppressed and do not trigger another OnJobTaskUpdated BC round-trip.
    _reloadInProgress = true;
    gantt.silent(function () {

      validateConstraintsBeforeParse(tasks);

      gantt.clearAll();
      gantt.parse({ data: tasks, links: links });

      // layout-related calls are also safe inside silent
      gantt.render();
      if (gantt.setSizes) gantt.setSizes();
      if (gantt.resetLayout) gantt.resetLayout();
    });
    // Deferred events from gantt.silent() fire synchronously at this point.
    // Use a 500 ms window (instead of 0) so that async auto-scheduling cascades
    // triggered by the subsequent LoadLinksData / RenderGantt calls are also
    // suppressed before the guard resets.
    setTimeout(function () { _reloadInProgress = false; }, 500);

    // 🔔 Notify BC AFTER load (no task updates fired)
    Microsoft.Dynamics.NAV.InvokeExtensibilityMethod(
      "OnProjectDataLoaded",
      [ String(tasks.length), String(links.length) ]
    );

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

// -------------------------------------------------------
// Load all links at once (BC -> JS)
// AL calls: LoadLinksData(LinksJsonTxt)
// Accepts: JSON array  [{ id, source, target, type, lag }, ...]
// -------------------------------------------------------
function LoadLinksData(linksJsonTxt) {
  try {
    if (!gantt_here || typeof gantt === "undefined" || !gantt.$root) {
      console.warn("LoadLinksData called before BOOT/init");
      return;
    }

    var links = _tryParseJson(linksJsonTxt);
    if (!links || !Array.isArray(links) || links.length === 0) return;

    gantt.silent(function () {
      links.forEach(function (link) {
        try {
          // Remove existing link with same id to avoid duplicates, then add fresh
          if (gantt.getLink && gantt.getLink(link.id)) {
            gantt.deleteLink(link.id);
          }
          gantt.addLink(link);
        } catch (e) {
          console.warn("LoadLinksData: failed to add link", link, e);
        }
      });
    });

    gantt.render();
  } catch (e) {
    console.error("LoadLinksData failed:", e);
  }
}

function calculateResourceLoad(resource, scale) {
  var step = scale.unit; // day
  var timegrid = {};
  var all = DayPlanningsStore ? DayPlanningsStore.getItems() : [];

  for (var i = 0; i < all.length; i++) {
    var dt = all[i];
    if (!dt) continue;

    if (String(dt.resource_id || "") !== String(resource.id || "")) continue;
    if (dt.plan_status === "Request") continue; // Request tasks shown as grey boxes, not counted in load

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

  // ── Build Request day-task map BEFORE the regular loop ───────────────────
  var requestDateMap = Object.create(null); // { dateStr: [dt,...] }
  if (DayPlanningsStore) {
    var allDTReq = DayPlanningsStore.getItems();
    for (var ri = 0; ri < allDTReq.length; ri++) {
      var rdt = allDTReq[ri];
      if (!rdt || !rdt.work_date || rdt.plan_status !== "Request") continue;
      if (String(rdt.resource_id || "") !== String(resource.id || "")) continue;
      var rdtDate = gantt.date.date_to_str("%Y-%m-%d")(
        _toGanttDate(rdt.work_date) || new Date(rdt.work_date)
      );
      if (!requestDateMap[rdtDate]) requestDateMap[rdtDate] = [];
      requestDateMap[rdtDate].push(rdt);
    }
  }
  // ── Track which Request dates got a planned cell rendered ─────────────────
  var requestDateHandled = Object.create(null); // { dateStr: true }

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
      "display:flex",
      "align-items:center",
      "justify-content:center",
      "font-weight:600",
      "position:absolute"
    ].join(";");

    // Count DayPlannings for this resource on this day
    var dayStr = gantt.date.date_to_str("%Y-%m-%d")(day.start_date);
    var dtCount = 0;
    if (DayPlanningsStore) {
      var allDT = DayPlanningsStore.getItems();
      for (var j = 0; j < allDT.length; j++) {
        var dt = allDT[j];
        if (String(dt.resource_id || "") !== String(resource.id || "")) continue;
        var dtDate = gantt.date.date_to_str("%Y-%m-%d")(
          _toGanttDate(dt.work_date) || new Date(dt.work_date)
        );
        if (dtDate === dayStr) dtCount++;
      }
    }

    // Hours label (centered)
    var hoursSpan = document.createElement("span");
    hoursSpan.textContent = day.value;
    cell.appendChild(hoursSpan);

    // Top-left badge: only when more than 1 DayPlanning
    if (dtCount > 1) {
      var badge = document.createElement("span");
      badge.textContent = dtCount;
      badge.style.cssText = [
        "position:absolute",
        "top:2px",
        "left:3px",
        "font-size:10px",
        "font-weight:700",
        "line-height:1",
        "background:rgba(0,0,0,0.25)",
        "color:#fff",
        "border-radius:8px",
        "padding:1px 4px",
        "pointer-events:none"
      ].join(";");
      cell.appendChild(badge);
    }

    // ── If a Request task exists on this same date → add black bar at bottom of THIS cell ──
    if (requestDateMap[dayStr]) {
      var blackBar = document.createElement("div");
      blackBar.style.cssText = [
        "position:absolute",
        "bottom:0",
        "left:0",
        "right:0",
        "height:6px",
        "background:#000000",
        "border-radius:0 0 3px 3px",
        "pointer-events:none"
      ].join(";");
      cell.appendChild(blackBar);
      requestDateHandled[dayStr] = true; // mark: this date already has a planned cell
    }

    cell.dataset.resourceId = resource.id;
    cell.dataset.workDate = dayStr;
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

  // ── Grey boxes ONLY for standalone Request tasks (no planned cell on that date) ───────────
  for (var rdateStr in requestDateMap) {
    if (requestDateHandled[rdateStr]) continue; // already handled by planned cell above

    var rfrom = gantt.date.parseDate(rdateStr, "%Y-%m-%d");
    if (!rfrom) continue;
    var rto = gantt.date.add(rfrom, 1, "day");
    var rsizes = timeline.getItemPosition(resource, rfrom, rto);
    if (!rsizes || rsizes.width <= 0) continue;

    var reqItems = requestDateMap[rdateStr];
    var reqHours = reqItems.reduce(function(s, x) { return s + (Number(x.hours) || 0); }, 0);

    var reqCell = document.createElement("div");
    reqCell.className = "gantt_resource_marker gantt_resource_marker_request";
    reqCell.style.cssText = [
      "left:" + rsizes.left + "px",
      "width:" + rsizes.width + "px",
      "position:absolute",
      "height:" + (gantt.config.row_height - 1) + "px",
      "top:" + rsizes.top + "px",
      "display:flex",
      "align-items:center",
      "justify-content:center",
      "font-weight:600"
    ].join(";");

    var reqHoursSpan = document.createElement("span");
    reqHoursSpan.textContent = reqHours > 0 ? reqHours : "";
    reqCell.appendChild(reqHoursSpan);

    // Badge: show count of Request tasks when more than 1 (same mechanism as planned cells)
    if (reqItems.length > 1) {
      var reqBadge = document.createElement("span");
      reqBadge.textContent = reqItems.length;
      reqBadge.style.cssText = [
        "position:absolute",
        "top:2px",
        "left:3px",
        "font-size:10px",
        "font-weight:700",
        "line-height:1",
        "background:rgba(0,0,0,0.25)",
        "color:#fff",
        "border-radius:8px",
        "padding:1px 4px",
        "pointer-events:none"
      ].join(";");
      reqCell.appendChild(reqBadge);
    }

    reqCell.dataset.resourceId = resource.id;
    reqCell.dataset.workDate = rdateStr;
    reqCell.dataset.isRequest = "1";
    reqCell.style.cursor = "pointer";

    reqCell.addEventListener("dblclick", function (e) {
      e.preventDefault();
      e.stopPropagation();
      Microsoft.Dynamics.NAV.InvokeExtensibilityMethod(
        "OpenResourceLoadDay",
        [this.dataset.resourceId, this.dataset.workDate]
      );
      return false;
    }, true);

    row.appendChild(reqCell);
  }
  // ── end Request grey boxes ────────────────────────────────────────────────
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

    // Only render if gantt is initialized and not in the middle of a refresh
    if (gantt.$root && !_isRefreshing) {
      gantt.render();
    }
  } catch (e) {
    console.error("LoadResourcesData failed:", e);
  }
}
window.LoadResourcesData = LoadResourcesData;

function LoadDayPlanningsData(DayPlanningsJsonTxt) {
  try {
    if (!DayPlanningsStore) {
      console.warn("LoadDayPlanningsData: DayPlanningsStore not ready yet");
      return;
    }


    var items = _tryParseJson(DayPlanningsJsonTxt);
    if (!items) return;
    if (!Array.isArray(items)) {
      items = items.DayPlannings || items.DayPlannings || items.DayPlannings || [];
    }

    // ✅ rebuild indexes every load
    window.DayPlanningsByTask = Object.create(null);
    window.requestJobTaskSet = Object.create(null); // task IDs that have ≥1 Request DayPlanning

    // Key = jobNo + "|" + jobTaskNo  →  matches gantt task.id exactly (pipe separator)
    // (AL DayPlanning.task field uses dash; gantt task.id uses pipe — must use jobNo/jobTaskNo fields)
    for (var i = 0; i < items.length; i++) {
      var x = items[i];
      var jNo  = x.jobNo  || "";
      var jtNo = x.jobTaskNo || "";
      if (!jNo && !jtNo) continue;
      var taskId = jNo + "|" + jtNo;

      if (!window.DayPlanningsByTask[taskId]) {
        window.DayPlanningsByTask[taskId] = [];
      }
      window.DayPlanningsByTask[taskId].push(x);

      if (x.plan_status === "Request") {
        window.requestJobTaskSet[taskId] = true;
      }
    }

    // Replace all
    if (DayPlanningsStore.clearAll) DayPlanningsStore.clearAll();
    DayPlanningsStore.parse(items);

    // addTaskLayer will now find the correct DayPlannings via task.id and render black bars
    if (gantt.$root && !_isRefreshing) {
      if (resourcesStore) {
        gantt.render(); // full render including resource panel
      } else {
        gantt.refreshData(); // refresh task bars only (resources not loaded yet)
      }
    }
  } catch (e) {
    console.error("LoadDayPlanningsData failed:", e);
  }
}
window.LoadDayPlanningsData = LoadDayPlanningsData;


function UpsertDayPlanning(DayPlanningJsonTxt, upsertIfMissing = true) {
  try {
    var patch = _tryParseJson(DayPlanningJsonTxt);
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

    var exists = !!DayPlanningsStore.getItem(id);
    if (!exists) {
      if (!upsertIfMissing) return;
      DayPlanningsStore.addItem(patch);
    } else {
      var current = DayPlanningsStore.getItem(id);
      for (var k in patch) {
        if (!Object.prototype.hasOwnProperty.call(patch, k)) continue;
        current[k] = patch[k];
      }
      DayPlanningsStore.updateItem(id, current);
    }

    resourcesStore.refresh();
    gantt.render();
  } catch (e) {
    console.error("UpsertDayPlanning failed:", e, DayPlanningJsonTxt);
  }
}
window.UpsertDayPlanning = UpsertDayPlanning;

function DeleteDayPlanning(DayPlanningId) {
  try {
    if (!DayPlanningId) return;
    var id = String(DayPlanningId);
    if (DayPlanningsStore.getItem(id)) {
      DayPlanningsStore.deleteItem(id);
      resourcesStore.refresh();
      gantt.render();
    }
  } catch (e) {
    console.error("DeleteDayPlanning failed:", e, DayPlanningId);
  }
}
window.DeleteDayPlanning = DeleteDayPlanning;


// function InstallDayPlanningLayer() {
//   if (window._DayPlanningLayerInstalled) return;
//   window._DayPlanningLayerInstalled = true;

//   gantt.addTaskLayer(function (task) {
//     const lines = (window.DayPlanningsByTask && window.DayPlanningsByTask[task.id]) || null;
//     console.log("Layer:", task.id, "DayPlannings:", lines?.length || 0);

//     if (!lines || !lines.length) return false;

//     const container = document.createElement("div");

//     // stack multiple per day (and per resource) so you can see all of them
//     const stackSlot = Object.create(null);

//     for (let i = 0; i < lines.length; i++) {
//       const l = lines[i];
//       if (!l.work_date) continue;

//       const from = gantt.date.parseDate(l.work_date, "%Y-%m-%d");
//       const to = gantt.date.add(from, 1, "day");
//       const pos = gantt.getTaskPosition(task, from, to);
//       if (!pos || pos.width <= 0) continue;

//       const key = l.work_date + "|" + (l.resource_id || "");
//       const slot = stackSlot[key] || 0;
//       stackSlot[key] = slot + 1;

//       const el = document.createElement("div");
//       el.className = "DayPlanning-line";
//        // ✅ ADD THESE 2 (and keep task.id as the key)
//       el.setAttribute("data-task-id", task.id);
//       el.setAttribute("data-DayPlanning-id", l.id);
      
//       el.style.left = (pos.left + 1) + "px";
//       el.style.width = Math.max(4, pos.width - 2) + "px";
//       el.style.top = (pos.top + 4 + slot * 10) + "px";
//       el.style.height = "8px";

//       el.title = (l.resource_id || "") + " • " + (l.hours || 0) + "h";

//       container.appendChild(el);
//     }

//     return container;
//   });
// }

function highlightDayPlanning(el) {
  document
    .querySelectorAll(".DayPlanning-line.selected")
    .forEach(x => x.classList.remove("selected"));

  el.classList.add("selected");
}

function _ensureCustomTooltip() {
  let el = document.getElementById("bc_DayPlanning_tooltip");
  if (el) return el;

  el = document.createElement("div");
  el.id = "bc_DayPlanning_tooltip";
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
  const tip = document.getElementById("bc_DayPlanning_tooltip");
  if (tip) tip.style.display = "none";
}

function GetGanttData() {
  alert('gantt.config.project_start: ' + gantt.config.project_start + '\ngantt.config.project_end: ' + gantt.config.project_end);
}

function SetResourcePanelVisibility(resource_toggle) {
  try {
    if (!gantt_here || typeof gantt === "undefined" || !gantt.$root) {
      console.warn("Gantt not initialized yet");
      return;
    }

    // Use the centralized layout recreation function
    RecreateGanttLayout(resource_toggle);
    
  } catch (e) {
    console.error("SetResourcePanelVisibility failed:", e);
  }
}

// -------------------------------------------------------
// Resource Panel Filter Info (AL -> JS)
// Called by BC to store the filter context shown in tooltip
// -------------------------------------------------------
function SetResourcePanelFilterInfo(jobNo, taskNo, periodFrom, periodTo) {  _resourceFilterInfo = {
    job: jobNo || "",
    task: taskNo || "",
    periodFrom: periodFrom || "",
    periodTo: periodTo || ""
  };
  _updateResourceHeaderTooltip();
}

// Called by BC to get the active resource filter info — result is sent back via OnResourceFilterRetrieved event
function GetResourceFilter() {
  Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('OnResourceFilterRetrieved', [JSON.stringify(_resourceFilterInfo || {})]);
}
window.GetResourceFilter = GetResourceFilter;

// Called by BC to clear the active resource filter and hide the (ℹ) button
function ClearResourceFilter() {
  _resourceFilterInfo = null;
  _updateResourceHeaderTooltip();
}
window.ClearResourceFilter = ClearResourceFilter;

function _updateResourceHeaderTooltip() {
  try {
    // DHTMLX Gantt layout gives the resource grid cell the class "resourceGrid_cell"
    // (derived from id: "resourceGrid" in the layout config)
    var cell = document.querySelector(".resourceGrid_cell .gantt_grid_head_workload")
            || document.querySelector(".resourceGrid_cell .gantt_grid_scale .gantt_grid_head_cell:last-child");
    if (!cell) {
      // DOM not ready yet (resetLayout() still in progress) — retry once after paint
      setTimeout(_updateResourceHeaderTooltip, 150);
      return;
    }

    // Remove any previously injected filter buttons
    cell.querySelectorAll(".res-filter-icon, .res-filter-reset").forEach(function(el) {
      el.parentNode.removeChild(el);
    });

    if (!_resourceFilterInfo) return;

    // Ensure fixed tooltip popup exists in body (never clipped by overflow:hidden)
    var popup = document.getElementById("res-filter-tooltip-popup");
    if (!popup) {
      popup = document.createElement("div");
      popup.id = "res-filter-tooltip-popup";
      document.body.appendChild(popup);
    }

    // Build tooltip HTML lines
    var fi = _resourceFilterInfo;
    var lines = ["<b>Filter applied:</b>"];
    if (fi.job) lines.push("Job = " + _escHtml(fi.job));
    if (fi.task) lines.push("Task = " + _escHtml(fi.task));
    if (fi.periodFrom || fi.periodTo)
      lines.push("Period: " + _escHtml(fi.periodFrom) + " to " + _escHtml(fi.periodTo));
    popup.innerHTML = lines.join("<br/>");

    // (ℹ) Info button — hover shows filter details, no click action
    var infoBtn = document.createElement("button");
    infoBtn.className = "res-filter-icon";
    infoBtn.textContent = "\u24d8"; // ℹ circled i
    infoBtn.style.cssText = "background:#1a73e8;border:none;border-radius:50%;width:20px;height:20px;line-height:20px;text-align:center;padding:0;margin-left:6px;cursor:default;font-size:13px;font-weight:700;color:#fff;vertical-align:middle;display:inline-block;"; 

    infoBtn.addEventListener("mouseenter", function(e) {
      popup.style.display = "block";
      _positionResFilterTooltip(e);
    });
    infoBtn.addEventListener("mousemove", function(e) {
      _positionResFilterTooltip(e);
    });
    infoBtn.addEventListener("mouseleave", function() {
      popup.style.display = "none";
    });

    // (✕) Reset button — hover shows "Click to Reset Filter", click resets
    var resetBtn = document.createElement("button");
    resetBtn.className = "res-filter-reset";
    resetBtn.title = "Click to Reset Filter";
    resetBtn.textContent = "\u2715"; // ✕
    resetBtn.style.cssText = "background:#c0392b;border:none;border-radius:50%;width:20px;height:20px;line-height:20px;text-align:center;padding:0;margin-left:4px;cursor:pointer;font-size:13px;font-weight:700;color:#fff;vertical-align:middle;display:inline-block;";

    resetBtn.addEventListener("click", function(e) {
      e.stopPropagation();
      popup.style.display = "none";
      Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("OnResetResourceFilter", []);
    });

    cell.appendChild(infoBtn);
    cell.appendChild(resetBtn);
  } catch (e) {
    console.error("_updateResourceHeaderTooltip failed:", e);
  }
}

function _positionResFilterTooltip(e) {
  var popup = document.getElementById("res-filter-tooltip-popup");
  if (!popup) return;
  var pad = 14;
  var vw = window.innerWidth;
  var vh = window.innerHeight;
  var w = popup.offsetWidth;
  var h = popup.offsetHeight;
  var x = e.clientX + pad;
  var y = e.clientY + pad;
  if (x + w > vw - 8) x = e.clientX - w - pad;
  if (y + h > vh - 8) y = e.clientY - h - pad;
  popup.style.left = x + "px";
  popup.style.top  = y + "px";
}

function _escHtml(str) {
  return String(str || "")
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

// -------------------------------------------------------
// LoadHolidaysData - called from BC with Base Calendar non-working days
// JSON: [{ "date": "2026-01-01", "description": "New Year", "type": "holiday" }, ...]
// -------------------------------------------------------
function LoadHolidaysData(holidaysJsonTxt) {
  _ganttHolidays = {};
  try {
    var data = JSON.parse(holidaysJsonTxt || "[]");
    if (Array.isArray(data)) {
      data.forEach(function(h) {
        if (h.date) _ganttHolidays[h.date] = h.description || "Holiday";
      });
    }
  } catch (e) {
    console.error("LoadHolidaysData parse error:", e);
  }
  // Re-render so the new highlighting takes effect immediately
  if (gantt && typeof gantt.render === "function") {
    gantt.render();
  }
}
window.LoadHolidaysData = LoadHolidaysData;