var gantt_here; // global variable for DHX GanttChart

function Init(projectstartdate, projectenddate) {
    //console.log("function Init() fired. with no params");

    var div = document.getElementById("controlAddIn") || document.body;
    // Ensure full fill
    div.style.width = "100%";
    div.style.height = "100%";
    div.style.margin = "0";
    div.style.padding = "0";
    div.style.background = "lightgrey";

    // Create / reuse gantt container
    var gantt_element = document.getElementById("gantt_here");
    if (!gantt_element) {
        gantt_element = document.createElement("div");
        gantt_element.id = "gantt_here";
        gantt_element.name = "gantt_here";
        gantt_element.style.width = "100%";
        gantt_element.style.height = "100%";
        gantt_element.style.boxSizing = "border-box";
        div.appendChild(gantt_element);
    }
    gantt_here = gantt_element;

    // Check library
    if (typeof gantt === "undefined") {
        console.error("DHX Gantt library (dhtmlxgantt.js) not found. Please include it in ControlAddIn Scripts.");
        return;
    }

    try {

        // *********** paste demo from portal here ***********
        gantt.plugins({
			auto_scheduling: true,
			marker: true,
			undo: true,
			resource: true // AH-20251218
		});

		gantt.templates.scale_cell_class = function (date) {
			if (date.getDay() == 0 || date.getDay() == 6) {
				return "weekend";
			}
		};
		gantt.templates.timeline_cell_class = function (item, date) {
			if (date.getDay() == 0 || date.getDay() == 6) {
				return "weekend";
			}
		};

		gantt.templates.task_class = function(start, end, task) {
			return task.schedulingType;  // e.g. 'fixed_duration', 'fixed_units', 'fixed_work'
		};

		gantt.config.work_time = true;
		gantt.config.min_column_width = 55;
		gantt.config.project_start = new Date(2024, 2, 1);
		gantt.config.project_end = new Date(2024, 3, 3);
		gantt.config.auto_scheduling = {
			enabled: true,
			show_constraints: true,
			schedule_from_end: false,
			apply_constraints: true,
			project_constraint: true
		};

	
		gantt.addMarker({
			start_date: gantt.config.project_start,
			text: "project start"
		});

		gantt.addMarker({
			start_date: gantt.config.project_end,
			text: "project end"
		});
		
		gantt.config.date_format = "%d-%m-%Y";

		gantt.attachEvent("onBeforeTaskDrag", function(id, mode, e){
			var t = gantt.getTask(id);
			var projectStart = gantt.config.project_start;
			var projectEnd   = gantt.config.project_end;

			// allow drag only if current task is within bounds (start guard)
			var end = gantt.calculateEndDate(t);
			if (t.start_date < projectStart || end > projectEnd) {
				gantt.message({ text: "Task must stay within project start and end", type: "error" });
				return false; // cancel starting the drag
			}
			return true;
		});

		// While dragging, clamp to bounds so it visually can’t cross
		gantt.attachEvent("onTaskDrag", function(id, mode, task, original, e){
			var projectStart = gantt.config.project_start;
			var projectEnd   = gantt.config.project_end;

			if (mode === gantt.config.drag_mode.move || mode === gantt.config.drag_mode.resize){
				// clamp start
				if (task.start_date < projectStart) {
					var dur = gantt.calculateDuration(task);
					task.start_date = new Date(projectStart);
					task.end_date = gantt.date.add(projectStart, dur, "day");
				}
				// clamp end
				var end = gantt.calculateEndDate(task);
				if (end > projectEnd) {
					var dur = gantt.calculateDuration(task);
					// shift left so end hits projectEnd
					task.start_date = gantt.date.add(projectEnd, -dur, "day");
					task.end_date = new Date(projectEnd);
				}
			}
		});

		gantt.attachEvent("onAfterTaskUpdate", function(id, task) {
			Microsoft.Dynamics.NAV.InvokeExtensibilityMethod(
				"OnTaskUpdated",
				[id, task.schedulingType, task.start_date, task.duration]
			);
		});


		// Final guard: block commit if bounds are violated by any change
		gantt.attachEvent("onBeforeTaskChanged", function(id, mode, task, original){
			
			//Add Task Type start
			if(task.Type === "fixed_work") {
				task.duration = task.work / task.units;
			}
			//Add Task Type end
			var projectStart = gantt.config.project_start;
			var projectEnd   = gantt.config.project_end;
			var start = task.start_date;
			var end   = gantt.calculateEndDate(task);
			if (start < projectStart || end > projectEnd) {
				gantt.message({ text: "Task must stay within project start and end", type: "error" });
				return false;
			}
			return true;
		});

		// **************

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

		gantt.config.grid_width = 250;      // initial width (optional)
		gantt.config.grid_resize = true;    // <-- user can drag to change width
		
		gantt.config.columns = [
			{ name: "text", tree: true, width: '*', resize: false, width: 150, editor: textEditor },
			{ name: "start_date", align: "center", resize: false, width: 150, editor: dateEditor },
			{ name: "duration", align: "center",resize: false, width: 80,  editor: durationEditor },
			{
				name: "constraint_type", align: "center", width: 110, template: function (task) {
					return gantt.locale.labels[gantt.getConstraintType(task)];
				}, resize: false, editor: constraintTypeEditor
			},
			{
				name: "constraint_date", align: "center", width: 120, template: function (task) {
					var constraintTypes = gantt.config.constraint_types;

					if (task.constraint_date && task.constraint_type != constraintTypes.ASAP && task.constraint_type != constraintTypes.ALAP) {
						return gantt.templates.task_date(task.constraint_date);
					}
					return "";
				}, resize: false, editor: constraintDateEditor
			},
			{name: "schedulingType", label: "Task Type", resize: false, width: 90}, //ADD Takstype
			{ name: "add",resize: false, width: 44 }
			

		];


		gantt.config.lightbox.sections = [
			{ name: "description", height: 38, map_to: "text", type: "textarea", focus: true },
			{ name: "constraint", type: "constraint" },
			// 🔽 ADD Takstype
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
			// 🔼 END ADD Takstype
			{ name: "time", type: "duration", map_to: "auto" },
			
		];
		gantt.config.lightbox.project_sections = [
			{ name: "description", height: 38, map_to: "text", type: "textarea", focus: true },
			{ name: "constraint", type: "constraint" },
			// 🔽 ADD Takstype
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
			// 🔼 END ADD Takstype
			{ name: "time", type: "duration", map_to: "auto" },
			
		];

		gantt.attachEvent("onAfterTaskAutoSchedule", function (task, new_date, link, predecessor) {
			var projectStart = gantt.config.project_start;
			var projectEnd   = gantt.config.project_end;

			// If auto-schedule moved task outside bounds, clamp and update
			var start = task.start_date;
			var end   = gantt.calculateEndDate(task);

			if (start < projectStart) {
				var dur = gantt.calculateDuration(task);
				task.start_date = new Date(projectStart);
				task.end_date   = gantt.date.add(projectStart, dur, "day");
				gantt.updateTask(task.id);
				gantt.message({ text: "Adjusted to project start", type: "warning" });
			} else if (end > projectEnd) {
				var dur = gantt.calculateDuration(task);
				task.start_date = gantt.date.add(projectEnd, -dur, "day");
				task.end_date   = new Date(projectEnd);
				gantt.updateTask(task.id);
				gantt.message({ text: "Adjusted to project end", type: "warning" });
			}

			// existing logging
			var reason = predecessor ? predecessor.text : gantt.locale.labels[gantt.getConstraintType(task)];
			console.log("<b>" + task.text + "</b> rescheduled to " + gantt.templates.task_date(new_date) + " due to <b>" + reason + "</b>");
		});

		gantt.serverList("schedulingTypes", [
			{ key: "fixed_duration", label: "Fixed Duration" },
			{ key: "fixed_units", label: "Fixed Units" },
			{ key: "fixed_work", label: "Fixed Work" }
		]);

		gantt.message({ text: "Project is scheduled as soon as possible starting from the project start date", expire: -1 });
		gantt.message({ text: "The constraints affect the task scheduling", expire: -1 });


		//<< AH-20251218 Resource Management
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
					timegrid[ts] = (timegrid[ts] || 0) + 8; // dummy: 8h/day
				}
			}
			var out = [];
			for (var ts in timegrid) {
				var start = new Date(+ts);
				var end = gantt.date.add(start, 1, step);
				out.push({ start_date: start, end_date: end, value: timegrid[ts] });
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
				var el = document.createElement("div");
				el.className = (day.value <= 8)
					? "gantt_resource_marker gantt_resource_marker_ok"
					: "gantt_resource_marker gantt_resource_marker_overtime";
				el.style.cssText = [
					"left:" + sizes.left + "px",
					"width:" + sizes.width + "px",
					"position:absolute",
					"height:" + (gantt.config.row_height - 1) + "px",
					"line-height:" + sizes.height + "px",
					"top:" + sizes.top + "px",
					"text-align:center",
					"font-weight:600"
				].join(";");
				el.innerHTML = day.value;
				row.appendChild(el);
			}
			return row;
		};
		var resourceLayers = [ renderResourceLine, "taskBg" ];

		// Different headers for task grid vs resource grid
		var mainGridConfig = { columns: gantt.config.columns };
		var resourcePanelConfig = {
			columns: [
				{ name: "name", label: "Name", template: function (r) { return r.label; } },
				{ name: "workload", label: "Workload", template: function (r) {
					var tasks = gantt.getTaskBy("user", r.id);
					var total = 0;
					for (var i = 0; i < tasks.length; i++) total += (tasks[i].duration || 0);
					return (total * 8) + "";
				} }
			]
		};

		// Replace previous resourceGrid/resourceTimeline layout
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

		// Datastores
		var resourcesStore = gantt.createDatastore({
			name: "resources",
			initItem: function (item) { item.id = item.key || gantt.uid(); return item; }
		});
		var tasksStore = gantt.getDatastore("task");
		tasksStore.attachEvent("onStoreUpdated", function () { resourcesStore.refresh(); });

		// Style for resource workload cells
		(function injectResourceCSS(){
			var css = `
			.gantt_resource_marker{ border-radius:4px; color:#fff; }
			.gantt_resource_marker_ok{ background:#21b36c; }
			.gantt_resource_marker_overtime{ background:#e74c3c; }
			`;
			var s = document.createElement("style"); s.textContent = css; document.head.appendChild(s);
		})();
		//>>

		// ******* INIT and LOAD DATA *******
		gantt.init("gantt_here");
		// DEBUG: inject CSS from JS
		var style = document.createElement("style");
		style.innerHTML = `
			.gantt_task_bar {
				border: 2px solid red !important;
			}
		`;
		document.head.appendChild(style);

		//<< AH-20251218 Resource
		resourcesStore.parse([
            { key: "0", label: "N/A" },
            { key: "1", label: "John" },
            { key: "2", label: "Mike" },
            { key: "3", label: "Anna" }
        ]);
		//>>

		gantt.parse({
			data: [
				{ id: 1, text: "Project #1", type: "project", progress: 0.6, open: true,schedulingType: "fixed_duration" },
				{ id: 2, text: "Task #1", start_date: "02-04-2023", duration: "5", parent: "1", progress: 1, open: true,schedulingType: "fixed_units"	 },
				{ id: 3, text: "Task #2", start_date: "03-04-2023", type: "project", parent: "1", progress: 0.5, open: true,schedulingType: "fixed_work" },
				{ id: 4, text: "Task #3", start_date: "02-04-2023", type: "project", duration: "6", parent: "1", progress: 0.8, open: true,schedulingType: "fixed_work" },
				{ id: 5, text: "Task #4", type: "project", parent: "1", progress: 0.2, open: true,schedulingType: "fixed_work" },
				{ id: 6, text: "Final milestone", start_date: "15-04-2023", type: "milestone", parent: "1", progress: 0, open: true,schedulingType: "fixed_work" },
				{ id: 7, text: "Task #2.1", start_date: "03-04-2023", duration: "2", parent: "3", progress: 1, open: true,schedulingType: "fixed_work" },
				{ id: 8, text: "Task #2.2", start_date: "06-04-2023", duration: "3", parent: "3", progress: 0.8, open: true,schedulingType: "fixed_work" },
				{ id: 9, text: "Task #2.3", start_date: "10-04-2023", duration: "4", constraint_date: "12-03-2024", constraint_type: "snet", parent: "3", progress: 0.2, open: true,schedulingType: "fixed_work" },
				{ id: 10, text: "Task #2.4", start_date: "10-04-2023", duration: "4", constraint_date: "15-03-2024", constraint_type: "snlt", parent: "3", progress: 0, open: true,schedulingType: "fixed_work" },
				{ id: 11, text: "Task #2.5", start_date: "10-04-2023", duration: "4", constraint_date: "05-03-2024", constraint_type: "mso", parent: "3", progress: 0, open: true,schedulingType: "fixed_work" },
				{ id: 12, text: "Task #3.1", start_date: "25-04-2023", duration: "2", parent: "4", progress: 1, open: true,schedulingType: "fixed_work" },
				{ id: 13, text: "Task #3.2", start_date: "25-04-2023", duration: "3", constraint_type: "alap", parent: "4", progress: 0.8, open: true,schedulingType: "fixed_work" },
				{ id: 14, text: "Task #3.3", start_date: "10-04-2023", duration: "4", constraint_date: "19-03-2024", constraint_type: "fnet", parent: "4", progress: 0.2, open: true,schedulingType: "fixed_work" },
				{ id: 15, text: "Task #3.4", start_date: "10-04-2023", duration: "4", constraint_date: "15-03-2024", constraint_type: "fnlt", parent: "4", progress: 0, open: true,schedulingType: "fixed_work" },
				{ id: 16, text: "Task #3.5", start_date: "10-04-2023", duration: "4", constraint_date: "12-03-2024", constraint_type: "mfo", parent: "4", progress: 0, open: true,schedulingType: "fixed_work" },
				{ id: 17, text: "Task #4.1", start_date: "02-04-2023", duration: "4", parent: "5", progress: 0.5, open: true,schedulingType: "fixed_work" },
				{ id: 18, text: "Task #4.2", start_date: "02-04-2023", duration: "4", parent: "5", progress: 0.1, open: true,schedulingType: "fixed_work" },
				{ id: 19, text: "Mediate milestone", start_date: "14-04-2023", type: "milestone", parent: "5", progress: 0, open: true,schedulingType: "fixed_work" }
			],
			links: [
				{ id: "1", source: "3", target: "5", type: "0" },
				{ id: "2", source: "5", target: "6", type: "0" },
				{ id: "3", source: "7", target: "8", type: "0" },
				{ id: "4", source: "8", target: "9", type: "0" },
				{ id: "5", source: "9", target: "10", type: "0" },
				{ id: "6", source: "10", target: "11", type: "0" },
				{ id: "7", source: "12", target: "13", type: "0" },
				{ id: "8", source: "13", target: "14", type: "0" },
				{ id: "9", source: "14", target: "15", type: "0" },
				{ id: "10", source: "15", target: "16", type: "0" },
			]
		});
        // *********** end of demo from portal here ***********

		//<< AH-20251218 Resource
		(function assignDummyOwners(){
			var owners = ["1","2","3"]; // John, Mike, Anna from resourcesStore
			gantt.batchUpdate(function(){
				gantt.eachTask(function(t){
					if (t.type === "project" || t.type === "milestone") return;
					if (!t.user) t.user = owners[(t.id - 1) % owners.length];
				});
			});
			resourcesStore.refresh();
			gantt.refreshData();
		})();
		//>>

    } catch (e) {
        console.warn("gantt.init/render warning:", e);
    }

    // Notify BC 
    Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("OnAfterInit",[]);
}

function Undo() {
	gantt.undo();
}

function Redo() {
    gantt.redo();
}

function AddMarker(datestr, text) {
    if (!datestr) {
        console.warn("AddMarker: missing date string");
        return;
    }

    var parseISO = gantt.date.str_to_date("%Y-%m-%d"); // local time parse
    var date = parseISO(String(datestr).trim());

    if (!date || isNaN(date.getTime())) {
        console.warn("AddMarker: invalid date string, expected yyyy-mm-dd ->", datestr);
        return;
    }
    var id = gantt.addMarker({
        start_date: date,
        text: text
		// css: "project-boundary"
    });
    gantt.showDate(date); // ensure the date is in view
    gantt.updateMarker(id);
	gantt.renderMarkers();
    console.log("Marker added on " + date.toDateString() + " with text: " + text + ", id: " + id);
}