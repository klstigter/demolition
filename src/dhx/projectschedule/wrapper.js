var scheduler_here; // global variable for dhx Scheduler
var resourceBlockVisible = false; // true only for a new event
var bcPlanningVisible = false;    // show only for existing events

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
    
    scheduler.date.timeline_start = function(date){
        return scheduler.date.week_start(date); // respects start_on_monday
    };
    
    //===============
    //Data loading
    //===============
    scheduler.config.lightbox.sections=[	
        {name:"description", height:60, map_to:"text", type:"textarea" , focus:true},
        {name:"custom", height:30, type:"timeline", options:null , map_to:"section_id" }, //type should be the same as name of the tab
        {name:"time", height:72, type:"time", map_to:"auto"},
        // << NEW: resource picker block >>
        {name:"resource", height:80, type:"resourcePicker", map_to:"resource_id"},
        // NEW: BC Planning (visible for existing)
        {name:"bcPlanning", height:50, type:"bcPlanning", map_to:"bc_dummy"}
    ];

    // Add a custom button to the lightbox to open a BC page
    // - Clicking it will raise an event to AL without closing the lightbox
    // Labels
    scheduler.locale.labels.section_bcPlanning = "BC Planning";
    scheduler.locale.labels.planning_line_btn = "Planning Line";
    scheduler.locale.labels.open_resource_btn = "Get Resource";

    // === NEW: BC Planning block (button inside section, never in footer) ===
    scheduler.form_blocks.bcPlanning = {
        render: function () {
            return (
                '<div class="bc-planning" style="padding:6px 12px;' + (bcPlanningVisible ? '' : 'display:none;') + '">' +
                    '<div style="margin:6px 0;">' +
                        '<button type="button" id="btnPlanningLine" class="dhx_btn">' +
                            (scheduler.locale.labels.planning_line_btn || 'Planning Line') +
                        '</button>' +
                    '</div>' +
                '</div>'
            );
        },
        set_value: function (node, value, ev) {
            // toggle visibility per event type
            node.style.display = bcPlanningVisible ? '' : 'none';

            var btn = node.querySelector('#btnPlanningLine');
            if (btn && !btn._wired) {
                btn._wired = true;
                btn.addEventListener('click', function (e) {
                    e.preventDefault();
                    e.stopPropagation();
                    var lbId = scheduler.getState().lightbox_id;
                    var cur = lbId ? scheduler.getEvent(lbId) : null;
                    var payload = cur ? {
                        id: lbId,
                        text: cur.text,
                        start_date: cur.start_date,
                        end_date: cur.end_date,
                        section_id: cur.section_id,
                        resource_id: cur.resource_id || '',
                        resource_name: cur.resource_name || ''
                    } : {};
                    console.log('Planning Line button clicked for event:', lbId, payload);
                    Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('OnPlanningLineClick', [String(lbId || ''), JSON.stringify(payload)]);
                });
            }
        },
        get_value: function (node, ev) {
            // no data to persist from this section
            return ev.text;
        },
        focus: function (node) {}
    };

    // Custom lightbox form block
    scheduler.form_blocks.resourcePicker = {
        render: function () {
            return (
                '<div class="resource-picker" style="padding:6px 12px;' + (resourceBlockVisible ? '' : 'display:none;') + '">' +
                    '<div style="margin:6px 0;">' +
                        '<label style="width:120px;display:inline-block;">Resource Id</label>' +
                        '<input type="text" id="resource_id_input" style="width:220px;">' +
                        '<button type="button" id="btnGetResource" style="margin-left:8px;">' +
                            (scheduler.locale.labels.get_resource_btn || "Get Resource") +
                        '</button>' +
                    '</div>' +
                    '<div style="margin:6px 0;">' +
                        '<label style="width:120px;display:inline-block;">Resource Name</label>' +
                        '<input type="text" id="resource_name_input" style="width:220px;">' +
                    '</div>' +
                '</div>'
            );
        },
        set_value: function (node, value, ev) {
            // keep current visibility
            node.style.display = resourceBlockVisible ? '' : 'none';
            var idInput = node.querySelector('#resource_id_input');
            var nameInput = node.querySelector('#resource_name_input');
            if (idInput) idInput.value = ev.resource_id || '';
            if (nameInput) nameInput.value = ev.resource_name || '';

            var btn = node.querySelector('#btnGetResource');
            if (btn && !btn._wired) {
                btn._wired = true;
                btn.addEventListener('click', function () {
                    var lbId = scheduler.getState().lightbox_id;
                    var cur = lbId ? scheduler.getEvent(lbId) : null;
                    var payload = cur ? {
                        id: cur.id,
                        text: cur.text,
                        start_date: cur.start_date,
                        end_date: cur.end_date,
                        section_id: cur.section_id,
                        resource_id: idInput?.value || cur.resource_id || '',
                        resource_name: nameInput?.value || cur.resource_name || ''
                    } : {};
                    Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("OnOpenResourcePage", [lbId || "", JSON.stringify(payload)]);
                });
            }
        },
        get_value: function (node, ev) {
            var idInput = node.querySelector('#resource_id_input');
            var nameInput = node.querySelector('#resource_name_input');
            ev.resource_id = idInput ? idInput.value : '';
            ev.resource_name = nameInput ? nameInput.value : '';
            return ev.resource_id; // saved into map_to ("resource_id")
        },
        focus: function (node) {
            var idInput = node.querySelector('#resource_id_input');
            if (idInput) idInput.focus();
        }
    };

    scheduler.config.drag_create = true;

    //console.log("EarliestPlanningDate: ",EarliestPlanningDate);
    scheduler.init('scheduler_here', EarliestPlanningDate, "timeline"); //new Date(2025,10,5)

    // After the lightbox is built, toggle resource block and footer button
    scheduler.attachEvent("onLightbox", function (id) {
        // Apply section visibility after DOM exists
        var res = document.querySelector(".dhx_cal_light .resource-picker");
        if (res) res.style.display = resourceBlockVisible ? "" : "none";

        var bc = document.querySelector(".dhx_cal_light .bc-planning");
        if (bc) bc.style.display = bcPlanningVisible ? "" : "none";
    });

    // Mark events created from the UI
    scheduler.attachEvent("onEventCreated", function (id) {
        var ev = scheduler.getEvent(id);
        if (ev) ev._isNewForLightbox = true;
        return true;
    });

    // Before opening the lightbox: show for new, hide for existing
    // scheduler.attachEvent("onBeforeLightbox", function (id) {
    //     var ev = scheduler.getEvent(id);

    //     // New event => show resource block, hide Planning Line
    //     resourceBlockVisible = !!(ev && ev._isNewForLightbox);

    //     // Only toggle the resource block visibility. Do NOT modify buttons_left/right.
    //     var n = document.querySelector(".dhx_cal_light .resource-picker");
    //     if (n) n.style.display = resourceBlockVisible ? "" : "none";

    //     return true;
    // });
    scheduler.attachEvent("onBeforeLightbox", function (id) {
        var ev = scheduler.getEvent(id);
        var isNew = !!(ev && ev._isNewForLightbox);
        resourceBlockVisible = isNew;
        bcPlanningVisible = !isNew;
        return true;
    });

    scheduler.attachEvent("onAfterLightbox", function(){
        var id = scheduler.getState().lightbox_id;
        var ev = id ? scheduler.getEvent(id) : null;
        if (ev) delete ev._isNewForLightbox;
        resourceBlockVisible = false;
        bcPlanningVisible = false;
        var res = document.querySelector(".dhx_cal_light .resource-picker");
        if (res) res.style.display = "none";
        var bc = document.querySelector(".dhx_cal_light .bc-planning");
        if (bc) bc.style.display = "none";
    });

    // Attach resize event
    scheduler.attachEvent("onEventChanged", function(id, ev){
        if (ev) delete ev._isNewForLightbox; // new event is no longer "new"

        console.log("Event changed:", id, ev);
        
        // Capture event data after resize/drag
        var eventData = {
            id: id,
            text: ev.text,
            start_date: ev.start_date,
            end_date: ev.end_date,
            section_id: ev.section_id
        };

        // Also reset after closing the lightbox (Cancel or Save)
        scheduler.attachEvent("onAfterLightbox", function(){
            var id = scheduler.getState().lightbox_id;
            var ev = id ? scheduler.getEvent(id) : null;
            if (ev) delete ev._isNewForLightbox;
            resourceBlockVisible = false;
            var n = document.querySelector(".dhx_cal_light .resource-picker");
            if (n) n.style.display = "none";
        });
        
        // Send to BC
        Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("OnEventChanged", [id, JSON.stringify(eventData)]);
    });

    scheduler.attachEvent("onEventAdded", function(id,ev){
        if (ev) delete ev._isNewForLightbox;   // <— important
        console.log("New Event:", ev);
        
        // Capture event data after resize/drag
        var eventData = {
            id: id,
            text: ev.text,
            start_date: ev.start_date,
            end_date: ev.end_date,
            section_id: ev.section_id,
            resource_id: ev.resource_id || '',
            resource_name: ev.resource_name || ''
        };
        
        // Send to BC
        Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("onEventAdded", [id,JSON.stringify(eventData)]);
        return true;
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

// Allow AL to update fields of the currently opened lightbox event
// Example input:
//   {
//     "text": "New description",
//     "section_id": "1010",
//     "start_date": "2025-11-07T19:25:00Z",
//     "end_date": "2025-11-08T11:55:00Z"
//   }
function SetLightboxEventValues(valuesJsonTxt, ResourceId, ResourceName) {
    console.log("SetLightboxEventValues called with:", valuesJsonTxt, ResourceId, ResourceName);

    // valuesJsonTxt is optional; only use it if it’s an object
    var values = ParseJSonTxt(valuesJsonTxt);

    if (typeof scheduler === "undefined") return;

    var lbId = scheduler.getState().lightbox_id;
    if (!lbId) return;

    var ev = scheduler.getEvent(lbId);
    if (!ev) return;

    // Apply optional fields from JSON
    if (values && typeof values === "object") {
        if ("text" in values) ev.text = values.text;
        if ("section_id" in values) ev.section_id = values.section_id;
        if (values.start_date) ev.start_date = new Date(values.start_date);
        if (values.end_date) ev.end_date = new Date(values.end_date);
    }

    // Always use the arguments to set resource fields
    if (ResourceId != null) ev.resource_id = ResourceId;
    if (ResourceName != null) {
        ev.resource_name = ResourceName;
        // keep event description in sync with resource name
        ev.text = ResourceName;
    }

    // Update inputs in the open lightbox UI from the arguments
    var box = document.querySelector(".dhx_cal_light");
    if (box) {
        var idInput = box.querySelector('#resource_id_input');
        var nameInput = box.querySelector('#resource_name_input');
        if (idInput && ResourceId != null) idInput.value = ResourceId;
        if (nameInput && ResourceName != null) nameInput.value = ResourceName;
    }

    // Also update the built-in "description" section so Save uses new text
    try {
        var descSection = scheduler.formSection && scheduler.formSection("description");
        if (descSection && typeof descSection.setValue === "function") {
            descSection.setValue(ev.text || "");
        }
    } catch (e) {
        // ignore if lightbox not open or API unavailable
    }

    scheduler.updateEvent(lbId);
}