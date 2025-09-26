var dp; // global variable for DayPilot Scheduler

function Init(StartDate) {
    console.log("Resource - function Init() fired. with startdate: ", StartDate);
    console.log("Resource - getWeekStart(StartDate): ", getWeekStart(StartDate));

    var div = document.getElementById("controlAddIn");
    // Ensure full fill
    div.style.width = "100%";
    div.style.height = "100%";
    div.style.margin = "0";
    div.style.padding = "0";
    div.style.background = "lightgrey";

    var dp_element = document.createElement("div");
    dp_element.id = "dp";
    dp_element.name = "dp";
    dp_element.style.width = "100%";
    dp_element.style.height = "100%";
    div.appendChild(dp_element);

    // Initialize DayPilot Scheduler and register events (moved from LoadData)    
    dp = new DayPilot.Scheduler("dp", {
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
        heightSpec: "Parent100Pct",        
        onBeforeCellRender: args => {
            args.cell.backColor = "white";
        },
        
    });
    dp.init();

    // Notify BC 
    Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("OnAfterInit",[]);
}

function LoadData(resourcesJson, eventsJson, StartDate, Days) {
    if (!dp) {
        console.warn("DayPilot Scheduler for Resource not initialized. Call Init() first.");
        return;
    }

    // console.log("Resource - Supply data for Resources: ", JSON.parse(resourcesJson));
    // console.log("Resource - Supply data for Events: ", JSON.parse(eventsJson));
    // console.log("Resource - Supply data for startDate: ", StartDate);
    // console.log("Resource - Supply data for days: ", Days);
    
    // dp.events.list = [];
    // dp.resources = [];
    // dp.update();
    // console.log("Resource - Remove all events and resources");

    dp.update({
        resources: JSON.parse(resourcesJson),
        events: JSON.parse(eventsJson),
        startDate: getWeekStart(StartDate),
        scrollTo: StartDate,
        days: Days
    });

    // const focusDate = typeof StartDate === "string" ? new Date(StartDate) : StartDate;
    // dp.scrollTo(DayPilot.Date.fromDate(focusDate));
    
    console.log("Resource - dp after LoadData function");
    console.log("Resource - dp.events.list: ", dp.events.list);
    console.log("Resource - dp.resources: ", dp.resources);
    console.log("Resource - dp.startDate: ", dp.startDate);
    console.log("Resource - dp.days: ", dp.days);
}

// function DisableCell(resourceId, StartDateTimeStr, EndDateTimeStr)
// {
//     console.log("Resource - resourceId: ", resourceId);
    
//     // Create a single range object
//     const range = {
//         start: new DayPilot.Date(StartDateTimeStr),
//         end: new DayPilot.Date(EndDateTimeStr)
//     };
//     console.log("Resource - range: ", range);

//     var row = dp.rows.find(function(row) { return row.id === resourceId; });
//     console.log("Resource - row: ", row);    
//     if (!row) return;    
//     row.cells.all().forEach(function(cell) {        
//         if (cell.start >= range.start && cell.start < range.end) {
//             console.log("Resource - cell: ", cell);
//             console.log("Resource - cell.backColor: ", cell.backColor);
//             // cell.disabled = true;
//             // cell.backColor = "lightgrey"; // Optional: visual feedback
//             // cell.html = "Booked";  // Optional: label
//         }
//     });
//     row.update(); // Re-render the row
// }

function DisableCell(resourceId, StartDateTimeStr, EndDateTimeStr) {
    const rangeStart = DayPilot.Date.parse(StartDateTimeStr);
    const rangeEnd = DayPilot.Date.parse(EndDateTimeStr);

    dp.onBeforeCellRender = function(args) {
        // Debugging logs
        console.log("args.row.id:", args.row.id, "resourceId:", resourceId);
        console.log("args.cell.start:", args.cell.start.toString(), "rangeStart:", rangeStart.toString(), "rangeEnd:", rangeEnd.toString());

        if (args.row.id === resourceId &&
            args.cell.start >= rangeStart &&
            args.cell.start < rangeEnd) 
        {
            console.log("Cell matched for coloring.", args);
            args.cell.backColor = "yellow";
            // Optionally for CSS
            // args.cell.cssClass = "cell-yellow";
        }
    };

    dp.update();
}