var resdp; // global variable for DayPilot Scheduler

function ResInit(StartDate, StartDateTimeStr, EndDateTimeStr) {
    console.log("Resource Selection - function Init() fired. with startdate: ", StartDate);
    console.log("Resource Selection - getWeekStart(StartDate): ", getWeekStart(StartDate));

    var div = document.getElementById("controlAddIn");
    // Ensure full fill
    div.style.width = "100%";
    div.style.height = "100%";
    div.style.margin = "0";
    div.style.padding = "0";
    div.style.background = "lightgrey";

    var dp_element = document.createElement("div");
    dp_element.id = "resdp";
    dp_element.name = "resdp";
    dp_element.style.width = "100%";
    dp_element.style.height = "100%";
    div.appendChild(dp_element);

    // Create a single range object
    const range = {
        start: new DayPilot.Date(StartDateTimeStr),
        end: new DayPilot.Date(EndDateTimeStr)
    };
    console.log("Resource Selection - range: ", range);

    // Initialize DayPilot Scheduler and register events (moved from LoadData)    
    resdp = new DayPilot.Scheduler("resdp", {
        startDate: getWeekStart(StartDate),
        scrollTo: StartDate,
        scale: "Hour", //"Week", //"Day",        
        days: 14, //365,
        // cellGroupBy: "Day", //"Month",
        timeHeaders: [
            { groupBy: "Week"}, // top header: Week {W}, dddd, d MMMM yyyy
            { groupBy: "Day", format: "d MMM yyyy" },             // second header: Day
            { groupBy: "Hour", format: "HH:mm" }               // bottom header: Hour
        ],        
        // businessBeg: 8,   // start of business hours (8 AM)
        // businessEnd: 17,  // end of business hours (5 PM)
        // showNonBusiness: false, // hides non-business hours        
        showToolTip: true,
        treeEnabled: true,
        dynamicLoading: false,
        rowClickHandling: "Select",
        heightSpec: "Parent100Pct",        

        onRowSelect: (args) => {
            if (window.console) {
                Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("onRowSelect",[]); //[JSON.stringify(args)]
            }
        },
        // onBeforeCellRender: args => {
        //     if (args.cell.start.getDayOfWeek() === 6 || args.cell.start.getDayOfWeek() === 0) {
        //         args.cell.backColor = "#d9ead3";
        //     }
        // },
        onBeforeCellRender: args => {
            if (args.cell.start >= range.start && args.cell.start < range.end) {
                console.log("Resource Selection - args: ", args);
                args.cell.backColor = "yellow";
            }
        },

    });
    resdp.init();

    // Notify BC 
    Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("OnAfterInit",[]);
}

function ResLoadData(resourcesJson, eventsJson, StartDate, Days) {
    if (!resdp) {
        console.warn("Scheduler for Resources not initialized. Call Init() first.");
        return;
    }

    console.log("Resource Selection - Supply data for Resources: ", resourcesJson && resourcesJson.trim() ? JSON.parse(resourcesJson) : []);
    console.log("Resource Selection - Supply data for Events: ", eventsJson && eventsJson.trim() ? JSON.parse(eventsJson) : []);
    console.log("Resource Selection - Supply data for startDate: ", StartDate);
    console.log("Resource Selection - Supply data for days: ", Days);
    console.log("Resource Selection - Start update resources and events");

    resdp.update({
        resources: resourcesJson && resourcesJson.trim() ? JSON.parse(resourcesJson) : [], //JSON.parse(resourcesJson),
        events: eventsJson && eventsJson.trim() ? JSON.parse(eventsJson) : [], //JSON.parse(eventsJson),
        startDate: getWeekStart(StartDate),
        scrollTo: StartDate,
        days: Days
    });
    
    console.log("Resource Selection - resdp after LoadData function");
    console.log("Resource Selection - resdp.events.list: ", resdp.events.list);
    console.log("Resource Selection - resdp.resources: ", resdp.resources);
    console.log("Resource Selection - resdp.startDate: ", resdp.startDate);
    console.log("Resource Selection - resdp.days: ", resdp.days);
}

function GetSelectedResources()
{
    // Notify BC 
    Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("onRowSelected",[JSON.stringify(resdp.rows.selection.get())]);        
}