var scheduler_here; // global variable for dhx Scheduler

function ParseJSonTxt(jsonText) {
    // Parse input safely (supports JSON string or object)
    let parsed;

    // Helper: normalize common JS-literal to JSON (quotes keys, replaces single quotes)
    const toJsonString = (s) => {
        return s
            .replace(/'/g, '"')                         // single -> double quotes
            .replace(/([{,]\s*)([a-zA-Z_]\w*)(\s*:)/g, '$1"$2"$3'); // quote unquoted keys
    };

    try {
        if (typeof jsonText === "string") {
            try {
                parsed = JSON.parse(jsonText); // proper JSON
            } catch {
                // Try to normalize JS-literal to JSON
                const normalized = toJsonString(jsonText);
                parsed = JSON.parse(normalized);
            }
        } else {
            parsed = jsonText; // already an object
        }
    } catch (e) {
        console.error("Invalid JSON for dataelements:", e, jsonText);
        return;
    }
    return parsed;
}

function Init(dataelements,EarliestPlanningDate) {
    // Parse input safely (supports JSON string or object)
    let parsed = ParseJSonTxt(dataelements);
    if (!parsed) {
        return;
    }

    // Validate shape: expect { data: [...] }
    var elements = Array.isArray(parsed?.data) ? parsed.data : [];
    if (elements.length === 0) {
        console.warn("No sections found in dataelements.data. y_unit will be empty.");
    }

    //console.log("elements:", elements);

    var div = document.getElementById("controlAddIn");
    // Ensure full fill
    div.style.width = "100%";
    div.style.height = "100%";
    div.style.margin = "0";
    div.style.padding = "0";
    div.style.background = "lightgrey";

    var scheduler_element = document.createElement("div");
    scheduler_element.id = "scheduler_here";
    scheduler_element.name = "scheduler_here";
    scheduler_element.style.width = "100%";
    scheduler_element.style.height = "100%";
    div.appendChild(scheduler_element);
    scheduler_here = scheduler_element;

    // Check library
    if (typeof scheduler === "undefined") {
        console.error("DHX scheduler library (dhtmlxscheduler.js) not found. Please include it in ControlAddIn Scripts.");
        return;
    }

    scheduler.plugins({
        timeline: true,
        treetimeline: true
    });
    scheduler.locale.labels.timeline_tab = "Timeline";
    scheduler.locale.labels.section_custom="Section";
    scheduler.config.details_on_create=true;
    scheduler.config.details_on_dblclick=true;

    // Start weeks on Monday
    scheduler.config.start_on_monday = true;

    // Top title for the timeline tab (show week period)
    const weekTitleFmt = scheduler.date.date_to_str("%d %M %Y");
    scheduler.templates.timeline_date = function (start, end) {
        // end is exclusive; subtract 1 day
        const endIncl = scheduler.date.add(end, -1, "day");
        return "Week date from " + weekTitleFmt(start) + " to " + weekTitleFmt(endIncl);
    };

    // //===============
    // //Configuration
    // //===============	

    // scheduler.createTimelineView({
    //     section_autoheight: false,
    //     name:	"timeline",
    //     x_unit:	"minute",
    //     x_date:	"%H:%i",
    //     x_step:	30,
    //     x_size: 24,
    //     x_start: 16,
    //     x_length:	48,
    //     y_unit: elements,
    //     y_property:	"section_id",
    //     render: "tree",
    //     folder_events_available: true,
    //     dy:60
    // });
    
    //=============== 
    // Configuration: weekly timeline with second scale (hours)
    //===============
    // scheduler.createTimelineView({
    //     section_autoheight: false,
    //     name: "timeline",
    //     // main scale: days
    //     x_unit: "day",
    //     x_step: 1,
    //     x_size: 7,               // 7 days
    //     x_date: "%D %d %M",      // e.g. Mon 01 Dec
    //     scale_height: 60,        // header height to fit two scales
    //     y_unit: elements,
    //     y_property: "section_id",
    //     render: "tree",
    //     folder_events_available: true,
    //     dy: 60
    // });

    // // Align the timeline to the start of the week for any date shown
    // scheduler.date.timeline_start = function (date) {
    //     return scheduler.date.week_start(date);
    // };

    scheduler.createTimelineView({
        name: "timeline",
        x_unit: "hour",
        x_date: "%H",
        x_step: 3, 
        x_size: (8 * 7),
        x_length: (8 * 7), // must match x_size
        event_dy: 60,
        resize_events: true,
        y_unit: elements,
        y_property: "section_id",
        render: "tree",
        scale_height: 60,
        second_scale: {
            x_unit: "day",
            x_date: "%D %d %M",
            // x_step: 10,
            // x_size: (10 * 7) 
        }
    });
    scheduler.date.timeline_start = scheduler.date.day_start;

    
    //===============
    //Data loading
    //===============
    scheduler.config.lightbox.sections=[	
        {name:"description", height:60, map_to:"text", type:"textarea" , focus:true},
        {name:"custom", height:30, type:"timeline", options:null , map_to:"section_id" }, //type should be the same as name of the tab
        {name:"time", height:72, type:"time", map_to:"auto"}
    ];
    
    //console.log("EarliestPlanningDate: ",EarliestPlanningDate);
    scheduler.init('scheduler_here', EarliestPlanningDate, "timeline"); //new Date(2025,10,5)

    // Attach resize event
    scheduler.attachEvent("onEventChanged", function(id, ev){
        console.log("Event changed:", id, ev);
        
        // Capture event data after resize/drag
        var eventData = {
            id: id,
            text: ev.text,
            start_date: ev.start_date,
            end_date: ev.end_date,
            section_id: ev.section_id
        };
        
        // Send to BC
        Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("OnEventChanged", [id, JSON.stringify(eventData)]);
    });

    // Notify BC 
    Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("OnAfterInit",[]);
}

function LoadData(eventsJson) {
    console.log("LoadData called with:", eventsJson);

    if (!scheduler_here) {
        console.warn("scheduler not initialized. Call Init() first.");
        return;
    }

    try {
        if (typeof scheduler === "undefined") {
            console.error("DHX Scheduler library not loaded. Cannot load data.");
            return;
        }
        
        scheduler.clearAll();
        scheduler.parse(eventsJson);

    } catch (err) {
        console.error("Unexpected error in LoadData:", err);
    }
}

function UpdateEventId(EventIdsJsonTxt) {
    console.log("UpdateEventId called with:", EventIdsJsonTxt);
    /*
    EventIdsJsonTxt = 
    {
        "OldEventId": "OldEventId",
        "NewEventId": "NewEventId",
    }
    */
   // Be tolerant to trailing commas in the incoming JSON
    if (typeof EventIdsJsonTxt === "string") {
        EventIdsJsonTxt = EventIdsJsonTxt.replace(/,\s*([}\]])/g, "$1");
    }

    const payload = ParseJSonTxt(EventIdsJsonTxt);
    if (!payload) {
        alert("UpdateEventId: invalid JSON");
        return;
    }

    const oldId = payload.OldEventId;
    const newId = payload.NewEventId;

    if (oldId == null || newId == null) {
        alert("UpdateEventId: OldEventId/NewEventId are required");
        return;
    }
    if (String(oldId) === String(newId)) {
        alert("UpdateEventId: ids are identical; nothing to change");
        return;
    }
    if (typeof scheduler === "undefined") {
        alert("UpdateEventId: scheduler not initialized");
        return;
    }

    const ev = scheduler.getEvent(oldId);
    if (!ev) {
        alert("UpdateEventId: event not found for OldEventId: " + oldId);
        return;
    }
    if (scheduler.getEvent(newId)) {
        alert("UpdateEventId: an event with NewEventId already exists: " + newId);
        return;
    }

    // Official way to remap an event id
    scheduler.changeEventId(oldId, newId);
    scheduler.updateEvent(newId);

    // Notify BC (optional)
    Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("OnAfterEventIdUpdated", [oldId, newId]);
}
