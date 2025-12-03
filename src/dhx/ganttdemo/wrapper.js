var gantt_here; // global variable for DHX GanttChart

function Init() {
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

    // Minimal configuration and safe init
    try {
        gantt.config.xml_date = "%Y-%m-%d %H:%i";
        gantt.config.server_utc = false; // keep local times; don't auto-convert to UTC
        gantt.config.start_on_monday = true; // align weeks Mon–Sun and ISO week numbers
        // Ensure marker plugin is enabled
        if (gantt.plugins) gantt.plugins({ marker: true, undo: true });
        gantt.config.show_markers = true;
        gantt.config.undo = true; // enable undo/redo
        gantt.config.drag_links = true; // allow drawing relations

        // // Working time: show only 08:00–17:00 and hide non-working time
        // gantt.config.work_time = true;
        // gantt.config.skip_off_time = true; // collapses non-working hours in the scale
        // // Define working hours for all days
        // gantt.setWorkTime({ hours: [8, 17] });
        // // Optional: mark Saturday/Sunday as non-working
        // gantt.setWorkTime({ day: 6, hours: false }); // Saturday
        // gantt.setWorkTime({ day: 0, hours: false }); // Sunday

        gantt.config.scales = [
            { unit: "year", step: 1, format: "%Y" },
            { unit: "week", step: 1, format: (date) => {
                    const weekStr = gantt.date.date_to_str("%W")(date); // ISO week number
                    return `Week-${weekStr}`;
                } },
            { unit: "day", step: 1, format: "%d-%M" },
            // { unit: "hour", step: 1, hours: [8, 17], format: "%H:%i" }
        ];

        // ===== Alternating week background =====
        function isoWeekNumber(d) {
            const x = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()));
            const day = x.getUTCDay() || 7; // Mon..Sun => 1..7
            x.setUTCDate(x.getUTCDate() + 4 - day);
            const y0 = new Date(Date.UTC(x.getUTCFullYear(), 0, 1));
            return Math.floor(((x - y0) / 86400000 + 1) / 7);
        }

        // Apply class to scale cells (header) and timeline cells (body)
        gantt.templates.scale_cell_class = function(date){
            return (isoWeekNumber(date) % 2 === 0) ? "week-even" : "week-odd";
        };
        gantt.templates.timeline_cell_class = function(task, date){
            return (isoWeekNumber(date) % 2 === 0) ? "week-even" : "week-odd";
        };

        // Strong CSS so theme can’t override
        (function ensureWeekStripeCss(){
            if (document.getElementById("week-stripes-css")) return;
            const style = document.createElement("style");
            style.id = "week-stripes-css";
            style.textContent = `
                /* header */
                .gantt_scale_cell.week-even { background:#dfe9ff !important; color:#0b3d91 !important; background-image:none !important; }
                .gantt_scale_cell.week-odd  { background:#ffffff !important; color:#1a1a1a !important; background-image:none !important; }

                /* timeline body */
                .gantt_task_bg .gantt_task_cell.week-even,
                .gantt_task_cell.week-even,
                .gantt_row_cell.week-even { background:#e6f0ff !important; }

                .gantt_task_bg .gantt_task_cell.week-odd,
                .gantt_task_cell.week-odd,
                .gantt_row_cell.week-odd  { background:#fff !important; }

                /* Optional: thin separator for week transitions */
                .gantt_scale_cell.week-even,
                .gantt_scale_cell.week-odd { box-shadow: inset -1px 0 0 #c0c6d9 !important; }
                .gantt_row_cell.week-even,
                .gantt_row_cell.week-odd  { box-shadow: inset -1px 0 0 #d0d6ea !important; }
            `;
            document.head.appendChild(style);
        })();

        gantt.config.min_column_width = 50;

        if (!gantt._initialized) {
            gantt.init("gantt_here");

            // (function addUndoToolbar(){
            //     if (document.getElementById("gantt-undo-toolbar")) return;
            //     gantt_here.style.position = "relative";
            //     const bar = document.createElement("div");
            //     bar.id = "gantt-undo-toolbar";
            //     bar.style.position = "absolute";
            //     bar.style.top = "6px";
            //     bar.style.right = "6px";
            //     bar.style.zIndex = "10";
            //     bar.innerHTML = '<button type="button" id="btnUndo">Undo</button>' +
            //                     '<button type="button" id="btnRedo">Redo</button>';
            //     gantt_here.appendChild(bar);
            //     document.getElementById("btnUndo").onclick = () => gantt.undo();
            //     document.getElementById("btnRedo").onclick = () => gantt.redo();
            // })();

            gantt._initialized = true;

            // // Listen for drag/shift/move and save updates
            // gantt.attachEvent("onTaskDrag", function(id, mode, task, original, e){
            //     // mode: "move","resize","progress"
            //     Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("OnTaskDrag", [
            //         id, mode, JSON.stringify(task), JSON.stringify(original)
            //     ]);
            //     return true; // allow drag
            // });

            // Fired after user changes task (drop completed)
            gantt.attachEvent("onAfterTaskUpdate", function(id, /*item*/) {
                var current = gantt.getTask(id);
                var toStr = gantt.date.date_to_str(gantt.config.xml_date); // local string

                var payload = {
                    id: String(current.id),
                    text: current.text,
                    start_date: toStr(current.start_date), // e.g. "2025-12-03 00:00"
                    end_date: toStr(current.end_date),
                    progress: current.progress,
                    duration: current.duration,
                    parent: current.parent
                };

                Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("OnAfterTaskUpdate", [
                    id, JSON.stringify(payload)
                ]);
            });

            // // Generic change (programmatic or user)
            // gantt.attachEvent("onTaskChanged", function(id, task){
            //     Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("OnTaskChanged", [
            //         id, JSON.stringify(task)
            //     ]);
            // });

            // Undo event -> signal back to BC
            if (gantt.config.undo) {

                function extractActionTaskId(action){
                    if(!action) return "";
                    if (action.id) return String(action.id);
                    if (action.task && action.task.id) return String(action.task.id);
                    if (action.obj && action.obj.id) return String(action.obj.id);
                    if (Array.isArray(action.tasks)){
                        for (var i=0;i<action.tasks.length;i++){
                            var t = action.tasks[i];
                            var tid = (t && t.id) ? t.id : t;
                            if (tid) return String(tid);
                        }
                    }
                    if (Array.isArray(action.commands)){
                        for (var j=0;j<action.commands.length;j++){
                            var c = action.commands[j];
                            if (c.oldValue && c.oldValue.id) return String(c.oldValue.id);
                            if (c.value && c.value.id) return String(c.value.id);
                        }
                    }
                    return "";
                }

                function buildPayloadFromRaw(raw, actionType){
                    var toStr = gantt.date.date_to_str(gantt.config.xml_date);
                    if(!raw){
                        return {
                            id: "",
                            text: "",
                            start_date: "",
                            end_date: "",
                            progress: 0,
                            duration: 0,
                            parent: "",
                            missingTask: true,
                            actionType
                        };
                    }
                    return {
                        id: String(raw.id),
                        text: raw.text || "",
                        start_date: raw.start_date ? toStr(raw.start_date) : "",
                        end_date: raw.end_date ? toStr(raw.end_date) : "",
                        progress: raw.progress || 0,
                        duration: raw.duration || 0,
                        parent: raw.parent || "",
                        actionType
                    };
                }

                gantt.attachEvent("onAfterUndo", function(action){
                    // Determine the task id
                    var taskId = extractActionTaskId(action);
                    var cmd = Array.isArray(action && action.commands) ? action.commands[0] : null;

                    // For an update, after undo the state becomes oldValue
                    // For a delete undo (i.e. undo of remove) the task reappears -> use current gantt task
                    // For undo of create, the task disappears -> oldValue usually empty, mark missing
                    var rawAfterUndo = null;

                    if (cmd && cmd.entity === "task") {
                        if (cmd.type === "update") {
                            rawAfterUndo = cmd.oldValue; // revert to oldValue
                        } else if (cmd.type === "remove") {
                            // undo of remove => task restored -> current gantt state
                            if (taskId && gantt.isTaskExists(taskId)) rawAfterUndo = gantt.getTask(taskId);
                        } else if (cmd.type === "add" || cmd.type === "create") {
                            // undo of create => task deleted now
                            rawAfterUndo = null;
                        } else {
                            // fallback try current
                            if (taskId && gantt.isTaskExists(taskId)) rawAfterUndo = gantt.getTask(taskId);
                        }
                    } else {
                        // No command details; try current task
                        if (taskId && gantt.isTaskExists(taskId)) rawAfterUndo = gantt.getTask(taskId);
                    }

                    var payload = buildPayloadFromRaw(rawAfterUndo, action && action.type);
                    if (!rawAfterUndo && taskId) payload.id = taskId; // keep id even if missing
                    //console.log("OnAfterUndo payload:", payload);
                    Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("OnAfterUndo", [
                        payload.id, JSON.stringify(payload)
                    ]);
                });

                gantt.attachEvent("onAfterRedo", function(action){
                    var taskId = extractActionTaskId(action);
                    var cmd = Array.isArray(action && action.commands) ? action.commands[0] : null;

                    // Redo reapplies the command:
                    // For update redo => new value state
                    // For redo of remove => task removed -> missing
                    // For redo of create => task created -> current gantt task
                    var rawAfterRedo = null;

                    if (cmd && cmd.entity === "task") {
                        if (cmd.type === "update") {
                            rawAfterRedo = cmd.value; // apply new value
                        } else if (cmd.type === "remove") {
                            // task removed now
                            rawAfterRedo = null;
                        } else if (cmd.type === "add" || cmd.type === "create") {
                            // task exists now
                            if (taskId && gantt.isTaskExists(taskId)) rawAfterRedo = gantt.getTask(taskId);
                            else rawAfterRedo = cmd.value;
                        } else {
                            if (taskId && gantt.isTaskExists(taskId)) rawAfterRedo = gantt.getTask(taskId);
                        }
                    } else {
                        if (taskId && gantt.isTaskExists(taskId)) rawAfterRedo = gantt.getTask(taskId);
                    }

                    var payload = buildPayloadFromRaw(rawAfterRedo, action && action.type);
                    if (!rawAfterRedo && taskId) payload.id = taskId;
                    //console.log("OnAfterRedo payload:", payload);
                    Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("OnAfterRedo", [
                        payload.id, JSON.stringify(payload)
                    ]);
                });
            }

        } else {
            gantt.render();
        }
    } catch (e) {
        console.warn("gantt.init/render warning:", e);
    }

    // Notify BC 
    Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("OnAfterInit",[]);
}

function LoadData(ganttdata) {
    if (!gantt_here) {
        console.warn("gantt not initialized. Call Init() first.");
        return;
    }

    // --- BEGIN: load logic requested by user ---
    try {
        if (typeof gantt === "undefined") {
            console.error("DHX Gantt library not loaded. Cannot load data.");
            return;
        }

        var tasks = [];
        var links = [];
        var markers = []; // <- NEW

        if (!ganttdata || ganttdata === "") {
            console.warn("LoadData called with empty ganttdata. No tasks to load.");
        } else {
            // Attempt to parse incoming JSON string.
            // AL usually passes a JSON string; handle common shapes:
            // - tasksJson: '[ {...}, {...} ]'
            // - wrapped: '{ "data":[...], "links":[...] }'
            try {
                var parsed = JSON.parse(ganttdata);

                if (Array.isArray(parsed)) {
                    tasks = parsed;
                } else if (parsed && Array.isArray(parsed.data)) {
                    tasks = parsed.data;
                    if (Array.isArray(parsed.links)) links = parsed.links;
                    if (Array.isArray(parsed.markers)) markers = parsed.markers; // <- NEW
                } else {
                    // single object representing one task -> wrap into array
                    tasks = [parsed];
                }
            } catch (firstErr) {
                // Sometimes AL may pass a quoted string; try an extra parse attempt
                try {
                    var maybe = JSON.parse(ganttdata.replace(/^\u0022|"\u0024/g, ''));
                    if (Array.isArray(maybe)) tasks = maybe;
                    else if (maybe && Array.isArray(maybe.data)) {
                        tasks = maybe.data;
                        if (Array.isArray(maybe.links)) links = maybe.links;
                        if (Array.isArray(maybe.markers)) markers = maybe.markers; // <- NEW
                    } else tasks = [maybe];
                } catch (secondErr) {
                    console.error("Failed to parse ganttdata JSON. Incoming data:", ganttdata);
                    console.error("Parse errors:", firstErr, secondErr);
                    return;
                }
            }
        }

        // Build parse payload
        var payload = { data: tasks };
        if (links && links.length > 0) payload.links = links;

        // Clear and load
        try {
            gantt.clearAll();
            gantt.parse(payload);
            
            // Ensure boundary markers container (start/end + custom)
            window.__boundaryMarkers ||= { start: null, end: null, custom: [] };

            // Remove old boundary markers
            if (__boundaryMarkers.start) { try { gantt.deleteMarker(__boundaryMarkers.start); } catch(_) {} __boundaryMarkers.start = null; }
            if (__boundaryMarkers.end)   { try { gantt.deleteMarker(__boundaryMarkers.end); }   catch(_) {} __boundaryMarkers.end   = null; }

            // Remove previously added custom markers
            if (Array.isArray(__boundaryMarkers.custom) && __boundaryMarkers.custom.length) {
                __boundaryMarkers.custom.forEach(function(mid){
                    try { gantt.deleteMarker(mid); } catch(_) {}
                });
                __boundaryMarkers.custom = [];
            } else if (!Array.isArray(__boundaryMarkers.custom)) {
                __boundaryMarkers.custom = [];
            }

            // Find earliest start and latest end from loaded tasks
            let min = null, max = null;
            gantt.eachTask(function(task){
                const s = task.start_date;
                const e = task.end_date || s;
                if (!min || s < min) min = s;
                if (!max || e > max) max = e;
            });

            // Make the visible range full ISO weeks (Mon..Sun) that wrap the data
            if (min && max) {
                const startWeek = gantt.date.week_start(min); // Monday of min week
                const endWeek = gantt.date.add(gantt.date.week_start(max), 1, "week"); // Monday after max week
                gantt.config.start_date = startWeek;
                gantt.config.end_date = endWeek;

                // __boundaryMarkers.start = gantt.addMarker({
                //     start_date: min,
                //     text: "PROJECT START",
                //     css: "project-boundary-start"
                // });
                // __boundaryMarkers.end = gantt.addMarker({
                //     start_date: max,
                //     text: "PROJECT END",
                //     css: "project-boundary-end"
                // });

                // Ensure styles
                (function ensureBoundaryCss(){
                    if (document.getElementById("boundary-css")) return;
                    const style = document.createElement("style");
                    style.id = "boundary-css";
                    style.textContent = `
                        .gantt_marker.project-boundary-start,
                        .gantt_marker.project-boundary-end { background: rgba(245, 35, 63, 0.35); }
                        .project-boundary-start .gantt_marker_content,
                        .project-boundary-end .gantt_marker_content {
                            background:#f5a623; color:#fff; padding:2px 6px; border-radius:3px; font-weight:600;
                        }
                    `;
                    document.head.appendChild(style);
                })();
            } else {
                // Fallback: show the current week completely when no tasks
                const today = new Date();
                const startWeek = gantt.date.week_start(today);
                const endWeek = gantt.date.add(startWeek, 1, "week");
                gantt.config.start_date = startWeek;
                gantt.config.end_date = endWeek;
            }

            // <- NEW: Add markers from payload (markers array)
            if (markers && markers.length) {
                const strToDate = gantt.date.str_to_date(gantt.config.xml_date);
                markers.forEach(function(m){
                    let dt = m.start_date || m.date;
                    if (typeof dt === "string") {
                        try { dt = strToDate(dt); } catch(_) { dt = null; }
                    }
                    if (!(dt instanceof Date) || isNaN(dt)) return;

                    const cfg = {
                        start_date: dt,
                        text: m.text || "",
                        css: m.css || "", // respect payload css, e.g., "project-boundary-end"
                        title: m.title || undefined
                    };
                    console.log("cfg from payload: ", cfg);
                    const markerId = gantt.addMarker(cfg);
                    __boundaryMarkers.custom.push(markerId);
                });
            }

        } catch (e) {
            console.error("Error while parsing/clearing gantt data:", e);
            return;
        }

        // Optionally center on first task start date
        if (tasks.length > 0 && tasks[0].start_date) {
            var sd = new Date(tasks[0].start_date);
            if (!isNaN(sd)) {
                try { gantt.showDate(sd); } catch (e) { /* ignore showDate issues */ }
            }
        }

        try { gantt.render(); } catch (e) { console.warn("gantt.render warning:", e); }

        //console.log("LoadData completed. Tasks loaded:", tasks.length, "Links loaded:", (links||[]).length);
    } catch (err) {
        console.error("Unexpected error in LoadData:", err);
    }
    // --- END: load logic ---
}

function Undo() {
    gantt.undo();
}

function Redo() {
    gantt.redo();
}