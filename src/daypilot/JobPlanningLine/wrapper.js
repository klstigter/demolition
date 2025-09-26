var dp; // global variable for DayPilot Scheduler

function Init(StartDate) {
    console.log("function Init() fired. with startdate: ", StartDate);
    console.log("getWeekStart(StartDate): ", getWeekStart(StartDate));

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

        onEventRightClick: async function(args) {
            console.log("Right click on event:", args.e);

            // You can access event data like:
            // args.e.data.id, args.e.data.text, etc.
            // Call BC Control Add-in event
            Microsoft.Dynamics.NAV.InvokeExtensibilityMethod(
                "OnEventRightClicked",
                [JSON.stringify(args.e.data)]
            );
            // Optionally, prevent default context menu
            args.preventDefault();
        },
        onEventMoved: async args => {
            console.log("Event moved:", args.e.data);
            Microsoft.Dynamics.NAV.InvokeExtensibilityMethod(
                "OnBookingChanged",
                [JSON.stringify(args.e.data)]
            );
        },
        onEventResized: async args => {
            console.log("Event resized:", args.e.data);
            Microsoft.Dynamics.NAV.InvokeExtensibilityMethod(
                "OnBookingChanged",
                [JSON.stringify(args.e.data)]
            );
        },
        onTimeRangeSelected: async args =>  {
            console.log("Time range selected:", args);

            // exit if less or equal one hour
            // Get the time difference in milliseconds
            var durationMillis = args.end.getTime() - args.start.getTime();

            // 1 hour in milliseconds
            var oneHourMillis = 60 * 60 * 1000;

            // Check if the duration is less than or equal to 1 hour
            if (durationMillis <= oneHourMillis) return;

            // // Prompt the user for text input
            // var defaultText = "New Project Planning Line";
            // var bookingText = prompt('Enter Project Planning Line text: ${defaultText}, after that resource need to be selected', defaultText);
            // if (!bookingText) return; // User cancelled

            var defaultText = "New Project Planning Line";
            var newEvent = {
                id: DayPilot.guid(),
                text: defaultText,
                start: args.start,
                end: args.end,
                resource: args.resource,
                bubbleHtml: defaultText
            };
            
            Microsoft.Dynamics.NAV.InvokeExtensibilityMethod(
                "OnBookingCreated",
                [JSON.stringify(newEvent)]
            ); //=> BC will push feedback by function OnBookingCreatedFeedback(rtv, bookingJson) for event creation
        }
    });
    dp.init();

    // Notify BC 
    Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("OnAfterInit",[]);
}

function LoadData(resourcesJson, eventsJson, StartDate, Days) {
    if (!dp) {
        console.warn("Scheduler not initialized. Call Init() first.");
        return;
    }

    // console.log("Supply data for Resources: ", JSON.parse(resourcesJson));
    // console.log("Supply data for Events: ", JSON.parse(eventsJson));
    // console.log("Supply data for startDate: ", StartDate);
    // console.log("Supply data for days: ", Days);
    
    // dp.events.list = [];
    // dp.resources = [];
    // dp.update();
    // console.log("Remove all events and resources");

    dp.update({
        resources: JSON.parse(resourcesJson),
        events: JSON.parse(eventsJson),
        startDate: getWeekStart(StartDate),
        scrollTo: StartDate,
        days: 14 //2 weeks
    });

    // const focusDate = typeof StartDate === "string" ? new Date(StartDate) : StartDate;
    // dp.scrollTo(DayPilot.Date.fromDate(focusDate));
    
    console.log("dp after LoadData function");
    console.log("dp.events.list: ", dp.events.list);
    console.log("dp.resources: ", dp.resources);
    console.log("dp.startDate: ", dp.startDate);
    console.log("dp.days: ", dp.days);
}

//#999 : delete function getWeekStart(date)

function RefreshDayPilot()
{
    console.log("Start refresh DayPilot");
    dp.update();
    console.log("dp.update() executed");
}

function DataCheck()
{
    console.log("dp.events.list: ", dp.events.list);
    console.log("dp.resources: ", dp.resources);
    console.log("dp.startDate: ", dp.startDate);
    console.log("dp.days: ", dp.days);
}

function RemoveAllEvents()
{
    dp.events.list = [];
    dp.update();
    console.log("dp.events.list = []; + dp.update(); executed");
}

function OnBookingCreatedFeedback(bookingJson){
    dp.events.add(JSON.parse(bookingJson));
    dp.update();
}

function deleteEventById(eventId) {
    dp.events.remove(eventId);
    dp.update(); // Optionally, redraws the scheduler
}

function EditEventDescription(eventsJson){
    // Parse the JSON string to a JavaScript array
    var event_data = JSON.parse(eventsJson);
    console.log("event_data: ", event_data);

    var eventId = event_data.id;
    const idx = dp.events.list.findIndex(ev => ev.id === eventId);
    if (idx > -1) {
        var inputText = "Input new Description";
        var newText = prompt('Enter Project Planning Line text:', inputText);
        
        // Modify Description
        dp.events.list[idx].text = newText;

        // Modify bubbleHTML
        const originalHtml = dp.events.list[idx].bubbleHtml;
        const newRow = '<tr><td>Desc</td><td>:nbsp;' + newText + '</td></tr>';
        const updatedHtml = originalHtml.replace(/<tr><td>Desc<\/td><td>.*?<\/td><\/tr>/, newRow);
        dp.events.list[idx].bubbleHtml = updatedHtml;
        
        // const match = dp.events.list[idx].bubbleHtml.match(/<tr><td>Desc<\/td><td>.*?<\/td><\/tr>/);
        // if (match) {
        //     console.log(match[0]); // Output: <tr><td>Desc</td><td>:nbsp;XXXXXX</td></tr>
        // } else {
        //     console.log("Desc row not found");
        // }

        dp.update();

        // Notify BC 
        console.log("JSON.stringify(event): ",JSON.stringify(dp.events.list[idx]));    
        Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("OnAfterEditDescription",[JSON.stringify(dp.events.list[idx])]);
    }
    else {
        console.log("Event not found.");
    }
    
}