var gantt_here; // global variable for DHX GanttChart

function Init() {
    console.log("function Init() fired. with no params");

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
        gantt.config.scale_unit = "day";
        gantt.config.date_scale = "%d %M %Y";
        gantt.config.min_column_width = 50;

        if (!gantt._initialized) {
            gantt.init("gantt_here");
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

        console.log("LoadData completed. Tasks loaded:", tasks.length, "Links loaded:", (links||[]).length);
    } catch (err) {
        console.error("Unexpected error in LoadData:", err);
    }
    // --- END: load logic ---
}