var scheduler_here; // global variable for dhx Scheduler
var resourceBlockVisible = false; // true only for a new event
var bcPlanningVisible = false;    // show only for existing events

//<< Inject CSS to hide default tabs : Day, Week, Month **** 2025.12.24
// Toggle helpers
function SetDefaultTabsVisible(visible) {
  var root = document.getElementById("scheduler_here");
  if (!root) return;
  if (visible) {
    root.classList.remove("dhx-hide-default-tabs");
  } else {
    root.classList.add("dhx-hide-default-tabs");
  }
}
//>>

// -------------------------------------------------------
// BOOT in startupScript.js calls this to build DOM and trigger ControlReady
// -------------------------------------------------------
window.BOOT = function() {
  try {    
    //<< Inject CSS to hide default tabs : Day, Week, Month **** 2025.12.24
    //only hides when root has the class dhx-hide-default-tabs
    const style = document.createElement("style");
    style.textContent = `
    /* Hide all built-in tabs (Day/Week/Month/Timeline) */
    #scheduler_here.dhx-hide-default-tabs .dhx_cal_tab { 
        display: none !important; 
    }

    /* Hide navigation buttons */
    #scheduler_here.dhx-hide-default-tabs .dhx_cal_prev_button,
    #scheduler_here.dhx-hide-default-tabs .dhx_cal_next_button,
    #scheduler_here.dhx-hide-default-tabs .dhx_cal_today_button {
        display: none !important;
    }

    /* Show only the date title and align it to the center */
    #scheduler_here.dhx-hide-default-tabs .dhx_cal_date {
        left: 50% !important;
        transform: translateX(-50%);
        margin: 0 !important;
        text-align: center !important;
    }
    `;
    document.head.appendChild(style);
    //>>

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
    scheduler_element.classList.add("dhx-hide-default-tabs"); //**** 2025.12.24
    scheduler_here = scheduler_element;

    // Check library
    if (typeof scheduler === "undefined") {
        console.error("DHX scheduler library (dhtmlxscheduler.js) not found. Please include it in ControlAddIn Scripts.");
        return;
    }

    scheduler.plugins({
        timeline: true,
        treetimeline: true,
        tooltip: true,
    });
    
    // Custom tooltip template
    scheduler.templates.tooltip_text = function(start, end, ev) {
        var formatDateOnly = scheduler.date.date_to_str("%d-%m-%Y");
        var formatTimeOnly = scheduler.date.date_to_str("%H:%i");
        
        // // Parse event ID: "JobNo|JobTaskNo|PlanningLineNo|DayNo|DayLineNo"
        // var dayNo = "";
        // var dayLineNo = "";
        // var jobNo = "";
        // var jobTaskNo = "";
        // var planningLineNo = "";
        
        // if (ev.id) {
        //     var parts = String(ev.id).split('|');
        //     if (parts.length >= 5) {
        //         jobNo = parts[0] || "";
        //         jobTaskNo = parts[1] || "";
        //         planningLineNo = parts[2] || "";
        //         dayNo = parts[3] || "";
        //         dayLineNo = parts[4] || "";
        //     }
        // }

        var html = "";
        if (ev.type === "capacity") {
            html = "<b>Event:</b> " + (ev.text || "") + "<br/>" +
                   "<b>Date:</b> " + formatDateOnly(start) + "<br/>" +
                   "<b>Start Time:</b> " + formatTimeOnly(start) + "<br/>" +
                   "<b>End Time:</b> " + formatTimeOnly(end) + "<br/>" +                                      
                   "<b>Capacity entry no.:</b> " + (ev.id || "") + "<br/>";
        } else if (ev.type === "daytask" || ev.type === "vacancy") {
            // var parts = String(ev.section_id).split('|');
            // var vendor_no = "";
            // if (parts.length >= 3) {
            //     vendor_no = parts[2] || "";
            // }
            var vendor_name = ev.details || "";
            html = "<b>Event:</b> " + (ev.text || "") + "<br/>" +
                   "<b>Date:</b> " + formatDateOnly(start) + "<br/>" +
                   "<b>Start Time:</b> " + formatTimeOnly(start) + "<br/>" +
                   "<b>End Time:</b> " + formatTimeOnly(end) + "<br/>" +                                      
                   "<b>Dayno|DayLineNo:</b> " + (ev.id || "") + "<br/>" +
                   "<b>vendor no.:</b> " + vendor_name;
        }
        return html;
    };
    
    scheduler.locale.labels.timeline_tab = "Timeline";
    scheduler.locale.labels.section_custom="Section";
    scheduler.config.details_on_create=true;
    scheduler.config.details_on_dblclick=false; // Disable opening lightbox on double click

    // Start weeks on Monday
    scheduler.config.start_on_monday = true;

    // Top title for the timeline tab (show week period)
    const weekTitleFmt = scheduler.date.date_to_str("%d %M %Y");
    scheduler.templates.timeline_date = function (start, end) {
        // end is exclusive; subtract 1 day
        const endIncl = scheduler.date.add(end, -1, "day");
        return "Week date from " + weekTitleFmt(start) + " to " + weekTitleFmt(endIncl);
    };

    scheduler.date.timeline_start = function(date){
        return scheduler.date.week_start(date); // respects start_on_monday
    };

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

    scheduler.config.drag_create = false; //false = prevent creating new events by lightbox

    // //console.log("EarliestPlanningDate: ",EarliestPlanningDate);
    // scheduler.init('scheduler_here');

    // ***** events triger block

    // Custom event registration for section double-click
    scheduler.attachEvent("onSectionDblClick", function(sectionId, label, viewdate) {
        Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("OnSectionDblClick", [sectionId, label, viewdate]);
    });

    // DOM handler to fire the custom event
    (function wireSectionDblClick() {
        var root = document.getElementById("scheduler_here");
        if (!root) return;

        root.addEventListener("dblclick", function(e) {
            // Find the label cell and row
            var sectionCell = e.target.closest(".dhx_matrix_scell");
            var sectionRow = e.target.closest(".dhx_timeline_label_row");        
            if (sectionCell && sectionRow) {
                // Get the sectionId from the row's data-row-id attribute
                var sectionId = sectionRow.getAttribute("data-row-id") || "";
                // Get the label from the cell
                var label = sectionCell.textContent.trim();
                var viewdate = scheduler.getState().date;
                scheduler.callEvent("onSectionDblClick", [sectionId, label, viewdate]);
                e.stopPropagation();
                e.preventDefault();
            }
        });
    })();
    
    //<<<<< Left-right navigation bottons click event
    (function wireTimelineArrows() {
        function notify() {
            var st = scheduler.getState();
            var payload = {
                mode: st.mode,
                start: new Date(st.min_date).toISOString(),
                end: new Date(st.max_date).toISOString()
            };
            Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("OnTimelineNavigate", [JSON.stringify(payload)]);
        }

        var root = document.getElementById("scheduler_here");
        if (root && !root._navWired) {
            root._navWired = true;
            // Delegate so it survives header re-renders
            root.addEventListener("click", function (e) {
                if (e.target.closest(".dhx_cal_prev_button")) {
                    setTimeout(notify, 0);
                } else if (e.target.closest(".dhx_cal_next_button")) {
                    setTimeout(notify, 0);
                }
            });
        }
    })();
    //>>

    scheduler.attachEvent("onDblClick", function (id, ev){
        console.log("Event onDblClick:", id, ev);
        
        // Get the actual event data from scheduler
        var eventdata = scheduler.getEvent(id);
        if (!eventdata) return false;
        
        // Capture event data
        var eventData = {
            id: id,
            text: eventdata.text,
            start_date: eventdata.start_date,
            end_date: eventdata.end_date,
            section_id: eventdata.section_id,
            type: eventdata.type || ''
        };        
        
        // Send to BC
        Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("OnEventDblClick", [id, JSON.stringify(eventData)]);

        // Block default lightbox opening
        return false;
    });

    //<< Skip using lightbox
    // // After the lightbox is built, toggle resource block and footer button
    // scheduler.attachEvent("onLightbox", function (id) {
    //     // Apply section visibility after DOM exists
    //     var res = document.querySelector(".dhx_cal_light .resource-picker");
    //     if (res) res.style.display = resourceBlockVisible ? "" : "none";

    //     var bc = document.querySelector(".dhx_cal_light .bc-planning");
    //     if (bc) bc.style.display = bcPlanningVisible ? "" : "none";
    // });

    // // Mark events created from the UI
    // scheduler.attachEvent("onEventCreated", function (id) {
    //     var ev = scheduler.getEvent(id);
    //     if (ev) ev._isNewForLightbox = true;
    //     return true;
    // });
    
    // scheduler.attachEvent("onBeforeLightbox", function (id) {
    //     var ev = scheduler.getEvent(id);
    //     var isNew = !!(ev && ev._isNewForLightbox);
    //     resourceBlockVisible = isNew;
    //     bcPlanningVisible = !isNew;
    //     return true;
    // });

    // scheduler.attachEvent("onAfterLightbox", function(){
    //     var id = scheduler.getState().lightbox_id;
    //     var ev = id ? scheduler.getEvent(id) : null;
    //     if (ev) delete ev._isNewForLightbox;
    //     resourceBlockVisible = false;
    //     bcPlanningVisible = false;
    //     var res = document.querySelector(".dhx_cal_light .resource-picker");
    //     if (res) res.style.display = "none";
    //     var bc = document.querySelector(".dhx_cal_light .bc-planning");
    //     if (bc) bc.style.display = "none";
    // });
    //>>

    // Attach resize event
    scheduler.attachEvent("onEventChanged", function(id, ev){
        if (ev) delete ev._isNewForLightbox; // new event is no longer "new"

        // Validate same-day event
        var s = ev && ev.start_date ? new Date(ev.start_date) : null;
        var e = ev && ev.end_date ? new Date(ev.end_date) : null;
        if (s && e) {
            var sameDay = s.getFullYear() === e.getFullYear() &&
                        s.getMonth() === e.getMonth() &&
                        s.getDate() === e.getDate();
            if (!sameDay) {
                alert("Start date and end date must be on the same day.");
                // Remove the just-created event to effectively cancel the add
                if (typeof scheduler !== "undefined") {
                    scheduler.deleteEvent(id, true);
                }
                return false;
            }
        }

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

        // Validate same-day event
        var s = ev && ev.start_date ? new Date(ev.start_date) : null;
        var e = ev && ev.end_date ? new Date(ev.end_date) : null;
        if (s && e) {
            var sameDay = s.getFullYear() === e.getFullYear() &&
                        s.getMonth() === e.getMonth() &&
                        s.getDate() === e.getDate();
            if (!sameDay) {
                alert("Start date and end date must be on the same day.");
                // Remove the just-created event to effectively cancel the add
                if (typeof scheduler !== "undefined") {
                    scheduler.deleteEvent(id, true);
                }
                return false;
            }
        }

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
    // ***** end of events triger block

    // Tell AL we are safe to call now
    Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("ControlReady", []);

  } catch (e) {
    console.warn("BOOT warning:", e);
  }
}

function Init(dataelements, EarliestPlanningDate) {
    // Parse input safely (supports JSON string or object)
    let parsed = ParseJSonTxt(dataelements);
    // Always use an array for y_unit, even if empty
    var elements = (parsed && Array.isArray(parsed.data)) ? parsed.data : [];
    if (!Array.isArray(elements)) elements = [];

    // If no sections, inject a dummy "No Data" section
    if (elements.length === 0) {
        elements = [{
            key: "nodata",
            label: "No Data"
        }];
    }

    // Remove existing timeline view if it exists (prevents duplicate view error)
    if (scheduler.matrix && scheduler.matrix.timeline) {
        scheduler.deleteView && scheduler.deleteView("timeline");
        delete scheduler.matrix.timeline;
    }

    // Defensive: set header to avoid DOM warnings if hiding tabs
    scheduler.config.header = ["date"];

    // Create timeline view (always with a valid y_unit array)    
    RecreateTimelineView(elements);

    scheduler.init('scheduler_here', EarliestPlanningDate, "timeline");

    // Notify BC
    Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("OnAfterInit", []);
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

        // Always parse and validate events array
        let parsedEvents = ParseJSonTxt(eventsJson);
        let events = [];
        if (parsedEvents) {
            if (Array.isArray(parsedEvents.data)) {
                events = parsedEvents.data;
            } else if (Array.isArray(parsedEvents)) {
                events = parsedEvents;
            }
        }
        if (!Array.isArray(events)) events = [];
        if (events.length > 0) {
            scheduler.parse(events); // load events into scheduler
        }
        
    } catch (err) {
        console.error("Unexpected error in LoadData:", err);
    }
}

// Defensive JSON parser
function ParseJSonTxt(jsonText) {
    let parsed;
    const toJsonString = (s) => {
        return s
            .replace(/'/g, '"')
            .replace(/([{,]\s*)([a-zA-Z_]\w*)(\s*:)/g, '$1"$2"$3');
    };
    try {
        if (typeof jsonText === "string") {
            try {
                parsed = JSON.parse(jsonText);
            } catch {
                const normalized = toJsonString(jsonText);
                parsed = JSON.parse(normalized);
            }
        } else if (typeof jsonText === "object" && jsonText !== null) {
            parsed = jsonText;
        }
    } catch (e) {
        console.log("Invalid JSON for dataelements:", e, jsonText);
        return false;
    }
    return parsed;
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

function RefreshTimeline(resourcesJson, eventsJson, dateAnchor) {
    console.log("resourcesJson:", resourcesJson);
    console.log("eventsJson:", eventsJson);

    try {
        // 1) Parse and update sections (y_unit)
        var resources = ParseJSonTxt(resourcesJson);
        var sections = (resources && Array.isArray(resources.data)) ? resources.data : [];
        if (!Array.isArray(sections)) sections = [];

        // If no sections, inject a dummy "No Data" section
        let onlyNoData = false;
        if (sections.length === 0) {
            sections = [{ key: "nodata", label: "No Data" }];
            onlyNoData = true;
        }

        RecreateTimelineView(sections);

        // 2) Reload events
        scheduler.clearAll();
        let parsedEvents = ParseJSonTxt(eventsJson);
        let events = [];
        if (!onlyNoData && parsedEvents) {
            if (Array.isArray(parsedEvents.data)) {
                events = parsedEvents.data;
            } else if (Array.isArray(parsedEvents)) {
                events = parsedEvents;
            }
        }
        if (!Array.isArray(events)) events = [];

        scheduler.parse(events);

        // 3) Move view to the week containing dateAnchor (if provided)
        let anchor = null;
        if (dateAnchor) {
            if (dateAnchor instanceof Date) {
                anchor = dateAnchor;
            } else if (typeof dateAnchor === "number") {
                anchor = new Date(dateAnchor); // epoch ms
            } else if (typeof dateAnchor === "string") {
                let d = new Date(dateAnchor);  // ISO or BC string
                if (!isNaN(d)) anchor = d;
            }
        }
        let viewDate = anchor ? scheduler.date.week_start(anchor) : scheduler.getState().date;
        scheduler.setCurrentView(viewDate, "timeline");
        //scheduler.updateView("timeline"); // <-- force full refresh

    } catch (e) {
        console.error("RefreshTimeline failed:", e);
    }
}

function RecreateTimelineView(sections) {
    // Remove existing timeline view if it exists
    if (scheduler.matrix && scheduler.matrix.timeline) {
        if (typeof scheduler.deleteView === "function") {
            scheduler.deleteView("timeline");
        }
        delete scheduler.matrix.timeline;
    }

    // Recreate timeline view with new sections
    scheduler.createTimelineView({
        name: "timeline",
        x_unit: "hour",
        x_date: "%H",
        x_step: 3,
        x_size: (8 * 7),
        x_length: (8 * 7),
        dy: 30,
        event_dy: 30,
        section_autoheight: false,
        resize_events: true,
        y_unit: sections,
        y_property: "section_id",
        render: "tree",
        scale_height: 60,
        second_scale: {
            x_unit: "day",
            x_date: "%D %d %M"
        }
    });
}

