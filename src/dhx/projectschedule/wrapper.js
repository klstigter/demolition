var scheduler_here; // global variable for dhx Scheduler

function Init(dataelements) {
    // Parse input safely (supports JSON string or object)
    let parsed;

    // Helper: normalize common JS-literal to JSON (quotes keys, replaces single quotes)
    const toJsonString = (s) => {
        return s
            .replace(/'/g, '"')                         // single -> double quotes
            .replace(/([{,]\s*)([a-zA-Z_]\w*)(\s*:)/g, '$1"$2"$3'); // quote unquoted keys
    };

    try {
        if (typeof dataelements === "string") {
            try {
                parsed = JSON.parse(dataelements); // proper JSON
            } catch {
                // Try to normalize JS-literal to JSON
                const normalized = toJsonString(dataelements);
                parsed = JSON.parse(normalized);
            }
        } else {
            parsed = dataelements; // already an object
        }
    } catch (e) {
        console.error("Invalid JSON for dataelements:", e, dataelements);
        return;
    }

    // Validate shape: expect { data: [...] }
    var elements = Array.isArray(parsed?.data) ? parsed.data : [];
    if (elements.length === 0) {
        console.warn("No sections found in dataelements.data. y_unit will be empty.");
    }

    console.log("elements:", elements);

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
    scheduler.createTimelineView({
        section_autoheight: false,
        name: "timeline",
        // main scale: days
        x_unit: "day",
        x_step: 1,
        x_size: 7,               // 7 days
        x_date: "%D %d %M",      // e.g. Mon 01 Dec
        scale_height: 60,        // header height to fit two scales
        y_unit: elements,
        y_property: "section_id",
        render: "tree",
        folder_events_available: true,
        dy: 60
    });

    // Align the timeline to the start of the week for any date shown
    scheduler.date.timeline_start = function (date) {
        return scheduler.date.week_start(date);
    };
    
    //===============
    //Data loading
    //===============
    scheduler.config.lightbox.sections=[	
        {name:"description", height:60, map_to:"text", type:"textarea" , focus:true},
        {name:"custom", height:30, type:"timeline", options:null , map_to:"section_id" }, //type should be the same as name of the tab
        {name:"time", height:72, type:"time", map_to:"auto"}
    ];
    
    scheduler.init('scheduler_here',new Date(2022,5,30),"timeline");

    // Notify BC 
    Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("OnAfterInit",[]);
    
    //LAGI
        
}

function LoadData(eventsJson) {
    if (!scheduler_here) {
        console.warn("scheduler not initialized. Call Init() first.");
        return;
    }

    try {
        if (typeof scheduler === "undefined") {
            console.error("DHX Scheduler library not loaded. Cannot load data.");
            return;
        }

        //var parsed = JSON.parse(eventsJson);
        scheduler.clearAll();
        //scheduler.parse(parsed);
        scheduler.parse([
            {"id":2,"start_date":"2022-06-30 13:40","end_date":"2022-06-30 19:40","text":"Task A-89411","section_id":"20"},
            {"id":3,"start_date":"2022-06-30 11:40","end_date":"2022-06-30 13:30","text":"Task A-64168","section_id":"20"},
            {"id":4,"start_date":"2022-06-30 09:25","end_date":"2022-06-30 12:10","text":"Task A-46598","section_id":"40"},
            {"id":6,"start_date":"2022-06-30 13:45","end_date":"2022-06-30 15:05","text":"Task B-44864","section_id":"40"},
            {"id":7,"start_date":"2022-06-30 16:30","end_date":"2022-06-30 18:00","text":"Task B-46558","section_id":40},
            {"id":8,"start_date":"2022-06-30 18:30","end_date":"2022-06-30 20:00","text":"Task B-45564","section_id":40},
            {"id":9,"start_date":"2022-06-30 08:35","end_date":"2022-06-30 11:35","text":"Task C-32421","section_id":"20"},
            {"id":10,"start_date":"2022-06-30 14:30","end_date":"2022-06-30 16:45","text":"Task C-14244","section_id":"50"},
            {"id":11,"start_date":"2022-06-30 12:00","end_date":"2022-06-30 15:00","text":"Task D-52688","section_id":"70"},
            {"id":12,"start_date":"2022-06-30 10:45","end_date":"2022-06-30 14:20","text":"Task D-46588","section_id":"60"},
            {"id":13,"start_date":"2022-06-30 13:25","end_date":"2022-06-30 17:40","text":"Task D-12458","section_id":"60"},
            {"section_id":"90","start_date":"2022-06-30 11:55","end_date":"2022-06-30 16:30","text":"New event 90 | id=14","$new":"true","id":14},
            {"section_id":"60","start_date":"2022-06-30 08:40","end_date":"2022-06-30 12:50","text":"New event 60 | id=18","$new":"true","id":18},
            {"section_id":"60","start_date":"2022-06-30 18:20","end_date":"2022-06-30 19:20","text":"New event 60 | id=19","$new":"true","id":19},
            {"section_id":"70","start_date":"2022-06-30 10:40","end_date":"2022-06-30 12:20","text":"New event 70 | id=20","$new":"true","id":20},
            {"section_id":"70","start_date":"2022-06-30 15:35","end_date":"2022-06-30 19:00","text":"New event 70 | id=21","$new":"true","id":21},
            {"section_id":"60","start_date":"2022-06-30 08:30","end_date":"2022-06-30 09:20","text":"New event 60 | id=22","$new":"true","id":22},
            {"section_id":"20","start_date":"2025-11-29 09:05","end_date":"2025-11-29 11:20","text":"New event 20 | id=23","$new":"true","id":23},
            {"section_id":"40","start_date":"2025-11-24 08:15","end_date":"2025-11-24 14:15","text":"New event 40 | id=24","$new":"true","id":24},
            {"section_id":"80","start_date":"2025-11-24 09:50","end_date":"2025-11-24 15:15","text":"New event 80 | id=25","$new":"true","id":25},
            {"section_id":"40","start_date":"2025-11-24 11:35","end_date":"2025-11-24 18:55","text":"New event 40 | id=26","$new":"true","id":26}]);

    } catch (err) {
        console.error("Unexpected error in LoadData:", err);
    }
}
