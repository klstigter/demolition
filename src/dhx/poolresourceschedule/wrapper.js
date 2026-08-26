var scheduler_here; // global variable for dhx Scheduler
var resourceBlockVisible = false; // true only for a new event
var bcPlanningVisible = false;    // show only for existing events

// Resource filter toolbar state (top-left of the timeline grid). null -> unfiltered;
// the filter button is still shown so the user can open the filter dialog, it just has
// no reset (✕) button and no filter details to show on hover. Mirrors the pattern used
// in src/dhx/projectschedule/wrapper.js (Job/Job Task filter), adapted to a single
// Resource No. since this scheduler's context is resource capacity, not job/task.
var _resFilterInfo = null; // { resNo, resName, periodFrom, periodTo, skillFilter }

// Collapse/expand-all state for the tree timeline's folder rows. Toggled by the icon at
// the top-left of the grid — mirrors _allTasksCollapsed / ToggleCollapseExpandAll in
// src/dhx/ganttdemo2/wrapper.js and _allSectionsCollapsed in src/dhx/projectschedule/wrapper.js.
var _allSectionsCollapsed = false;

// -------------------------------------------------------
// Loading overlay - shown while a full data (re)load is in progress. Same look/lifecycle
// as _loadingOverlay in src/dhx/ganttdemo2/wrapper.js and src/dhx/projectschedule/wrapper.js:
// created once in BOOT (earliest point this add-in's JS runs), shown again at the start of
// every full reload entry point (Init/RefreshTimeline), hidden once that reload cycle's own
// render is done (LoadData for the initial Init->LoadData sequence, RefreshTimeline for
// subsequent reloads).
// -------------------------------------------------------
var _loadingOverlay = null;
var _loadingSafetyTimer = null;

function _createResLoadingOverlay(host) {
    if (_loadingOverlay) return;

    var style = document.createElement("style");
    style.textContent = [
        "#res-loading-overlay {",
        "  position:absolute; inset:0; z-index:100000;",
        "  display:none; align-items:center; justify-content:center;",
        "  background:rgba(255,255,255,0.35);",
        "}",
        "#res-loading-overlay .rlo-box {",
        "  background:#fff; border:1px solid #d8d8d8; border-radius:6px;",
        "  box-shadow:0 6px 24px rgba(0,0,0,0.25);",
        "  padding:18px 26px; width:170px; text-align:center;",
        "  font:13px/1.4 'Segoe UI', Tahoma, sans-serif;",
        "}",
        "#res-loading-overlay .rlo-bar {",
        "  height:16px; border:1px solid #2f6fdb; border-radius:2px; overflow:hidden;",
        "  margin-bottom:10px; background:#fff;",
        "}",
        "#res-loading-overlay .rlo-bar-fill {",
        "  height:100%; width:200%;",
        "  background-image: repeating-linear-gradient(-55deg, #2f6fdb 0 8px, #eaf1fd 8px 16px);",
        "  animation: rlo-slide 0.9s linear infinite;",
        "}",
        "@keyframes rlo-slide { from { transform: translateX(-50%); } to { transform: translateX(0%); } }",
        "#res-loading-overlay .rlo-title { color:#2f6fdb; font-weight:700; font-size:16px; letter-spacing:1px; }",
        "#res-loading-overlay .rlo-sub { color:#8a8a8a; margin-top:2px; }"
    ].join("\n");
    document.head.appendChild(style);

    var overlay = document.createElement("div");
    overlay.id = "res-loading-overlay";
    overlay.innerHTML =
        '<div class="rlo-box">' +
            '<div class="rlo-bar"><div class="rlo-bar-fill"></div></div>' +
            '<div class="rlo-title">LOADING</div>' +
            '<div class="rlo-sub">Please wait...</div>' +
        '</div>';

    if (!host.style.position) host.style.position = "relative";
    host.appendChild(overlay);
    _loadingOverlay = overlay;
}

function _showResLoading() {
    if (!_loadingOverlay) return;
    _loadingOverlay.style.display = "flex";
    // Safety fallback: never let the overlay get stuck forever if a reload cycle's hide
    // call is never reached (e.g. an error earlier in the AL load sequence).
    if (_loadingSafetyTimer) clearTimeout(_loadingSafetyTimer);
    _loadingSafetyTimer = setTimeout(_hideResLoading, 180000);
}

function _hideResLoading() {
    if (_loadingOverlay) _loadingOverlay.style.display = "none";
    if (_loadingSafetyTimer) { clearTimeout(_loadingSafetyTimer); _loadingSafetyTimer = null; }
}

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
        display: none !important;
    }

    /* Hide the entire header area to remove blank space */
    #scheduler_here .dhx_cal_navline {
        display: none !important;
    }

    /* Background color for parent/folder rows in timeline */
    
    /******* Style for Group category cells */
    .timeline-group-row {
        background-color: #E9E9E9 !important;
    }

    .timeline-group-row .dhx_matrix_cell {
        background-color: #E9E9E9 !important;
    }

    .dhx_matrix_scell.folder.group-category,
    .dhx_matrix_scell.folder.group-category .dhx_scell_level0,
    .dhx_matrix_scell.folder.group-category .dhx_scell_level1,
    .dhx_matrix_scell.folder.group-category .dhx_scell_level2,
    .dhx_matrix_scell.folder.group-category .dhx_scell_name {
        background-color: #E9E9E9 !important;
        color: black !important;
        font-weight: normal !important;
        text-transform: none !important;
    }

    .dhx_matrix_scell.folder.group-category {
        background-color: #E9E9E9 !important;
        font-weight: normal;
        text-transform: none !important;
    }
    
    /***** Style for Vendor category parent cells in the left column (label area) */
    /* Style parent row cells in the event area (timeline data cells) */
    .timeline-parent-row .dhx_matrix_cell {
        background-color: #E9E9E9 !important;
    }

    .dhx_matrix_scell.folder.vendor-category,
    .dhx_matrix_scell.folder.vendor-category .dhx_scell_level0,
    .dhx_matrix_scell.folder.vendor-category .dhx_scell_level1,
    .dhx_matrix_scell.folder.vendor-category .dhx_scell_level2,
    .dhx_matrix_scell.folder.vendor-category .dhx_scell_name {
        background-color: #E9E9E9 !important;
        color: black !important;
        font-weight: normal !important;
        text-transform: none !important;
    }

    /* Style for Vendor category parent cells in the left column */
    .dhx_matrix_scell.folder.vendor-category {
        background-color: #E9E9E9 !important;
        font-weight: normal;
        text-transform: none !important;
    }

    /* Style for Resource category cells - with extra indentation */
    .timeline-resource-row {
        background-color: white !important;
    }

    .timeline-resource-row .dhx_matrix_cell {
        background-color: white !important;
    }

    .dhx_matrix_scell.resource-category,
    .dhx_matrix_scell.resource-category .dhx_scell_name {
        padding-left: 15px !important;
        background-color: white !important;
        color: black !important;
        font-weight: normal !important;
    }

    
    /* ********* */

    /* Set all event text color to black */
    /* ************************
    .dhx_cal_event,
    .dhx_cal_event_line,
    .dhx_event_line,
    .dhx_cal_event .dhx_title,
    .dhx_cal_event .dhx_body {
        color: black !important;        
    }
    ************************ */

    /* Setup-driven bar colors (overridden at runtime by SetBarColors via
       root.style.setProperty on #scheduler_here - see SetBarColors below). SetBarColors is now
       ALWAYS called unconditionally, sending both colors.capacity and colors.capacityBorder
       (resolved via AL codeunit 50609 "Visual Default Settings"'s GetCapacitySegmentColors/
       GetCapacityBorderColor, overridable via "Daily Optimizer Setup"), so these CSS values only
       ever render as fallbacks - kept in sync with resourceschedule_with_capacity's own defaults
       (CapacityColorTok/CapacityBorderColorTok) for consistency across the two capacity-bearing
       pages. */
    #scheduler_here {
        --cap-color: #2E75B6;
        --cap-color-border: #C97F16;
        --bar-font-color: #000000;
    }

    /* Event styling per type */
    /* Capacity events */
    .dhx_cal_event.event-capacity,
    .dhx_cal_event_line.event-capacity,
    .dhx_event_line.event-capacity,
    .dhx_cal_event.event-capacity .dhx_title,
    .dhx_cal_event.event-capacity .dhx_body {
        color: var(--bar-font-color) !important;
        font-size: 14px !important;
        background-color: var(--cap-color) !important;
        border-color: var(--cap-color-border) !important;
    }

    /* Vacancy events */
    .dhx_cal_event.event-vacancy,
    .dhx_cal_event_line.event-vacancy,
    .dhx_event_line.event-vacancy,
    .dhx_cal_event.event-vacancy .dhx_title,
    .dhx_cal_event.event-vacancy .dhx_body {
        color: var(--bar-font-color) !important;
        font-size: 14px !important;
        /*
        background-color: #FFF3CD !important;
        border-color: #FFC107 !important;
        */
    }

    /* DayPlanning_0 events */
    .dhx_cal_event.event-DayPlanning_0,
    .dhx_cal_event_line.event-DayPlanning_0,
    .dhx_event_line.event-DayPlanning_0,
    .dhx_cal_event.event-DayPlanning_0 .dhx_title,
    .dhx_cal_event.event-DayPlanning_0 .dhx_body {
        color: var(--bar-font-color) !important;
        font-size: 14px !important;
        /*
        background-color: #D1ECF1 !important;
        border-color: #17A2B8 !important;
        */
    }

    /* DayPlanning_1 events */
    .dhx_cal_event.event-DayPlanning_1,
    .dhx_cal_event_line.event-DayPlanning_1,
    .dhx_event_line.event-DayPlanning_1,
    .dhx_cal_event.event-DayPlanning_1 .dhx_title,
    .dhx_cal_event.event-DayPlanning_1 .dhx_body {
        color: var(--bar-font-color) !important;
        font-size: 14px !important;
        /*
        background-color: #F8D7DA !important;
        border-color: #DC3545 !important;
        */
    }


    /* ── Resource filter toolbar (top-left of the timeline grid) ─── */
    #scheduler_here {
        position: relative;
    }
    #res-filter-toolbar {
        position: absolute;
        top: 6px;
        left: 34px;
        z-index: 70;
        display: flex;
        align-items: center;
        gap: 4px;
    }
    /* Collapse/Expand-all toggle icon — sits left of the filter toolbar, same overlay
       approach (a DOM sibling of the scheduler's own markup, so it survives internal
       re-renders). */
    #res-collapseall-icon {
        position: absolute;
        top: 6px;
        left: 6px;
        z-index: 71;
        display: inline-flex;
        align-items: center;
        justify-content: center;
        width: 22px;
        height: 22px;
        padding: 0;
        border: none;
        border-radius: 50%;
        background: #5f6368;
        cursor: pointer;
    }
    #res-collapseall-icon:hover {
        background: #2f8bfb;
    }
    #res-collapseall-icon:active {
        background: #1f6fe0;
    }
    /* Fixed body-level tooltip popup (never clipped by the grid's overflow:hidden) */
    #res-filter-tooltip-popup {
        display: none;
        position: fixed;
        background: #ffffff;
        color: #23272A;
        border: 1px solid #4a6fa5;
        border-radius: 5px;
        padding: 8px 12px;
        font-size: 12px;
        font-weight: normal;
        white-space: nowrap;
        z-index: 999999;
        box-shadow: 0 3px 10px rgba(0,0,0,0.25);
        min-width: 180px;
        pointer-events: none;
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

    // Show immediately — earliest point this add-in's own JS runs, well before
    // ControlReady/Init/LoadData ever fire.
    _createResLoadingOverlay(div);
    _showResLoading();

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
    
    // Apply CSS class based on event type
    scheduler.templates.event_class = function(start, end, ev) {
        var typeClass = "";
        if (ev.type === "capacity") {
            typeClass = "event-capacity";
        } else if (ev.type === "vacancy") {
            typeClass = "event-vacancy";
        } else if (ev.type === "DayPlanning_0") {
            typeClass = "event-DayPlanning_0";
        } else if (ev.type === "DayPlanning_1") {
            typeClass = "event-DayPlanning_1";
        }
        return typeClass;
    };
    
    // Custom tooltip template
    scheduler.templates.tooltip_text = function(start, end, ev) {
        var formatDateOnly = scheduler.date.date_to_str("%d-%m-%Y");
        var formatTimeOnly = scheduler.date.date_to_str("%H:%i");
        
        // Parse event Details: "Vendor|Job|Task"
        var vendor = "";
        var jobNo = "";
        var jobTaskNo = "";
        
        if (ev.details) {
            var parts = String(ev.details).split('|');
            if (parts.length >= 3) {
                vendor = parts[0] || "";
                jobNo = parts[1] || "";
                jobTaskNo = parts[2] || "";                
            }
        }

        var html = "";
        if (ev.type === "capacity") {
            html = '<div class="dhx-tt">';
            html += '<div class="dhx-tt-res">Capacity: ' + (ev.text || "") + '</div>';
            html += '<div class="dhx-tt-date">' + formatDateOnly(start) + '</div>';
            html += '<div class="dhx-tt-table">';
            html += '<div class="dhx-tt-label">Start Time:</div><div class="dhx-tt-val">' + formatTimeOnly(start) + '</div>';
            html += '<div class="dhx-tt-label">End Time:</div><div class="dhx-tt-val">' + formatTimeOnly(end) + '</div>';
            html += '<div class="dhx-tt-label">Capacity entry no.:</div><div class="dhx-tt-val">' + (ev.id || "") + '</div>';
            html += '</div></div>';
        } else if (ev.type === "DayPlanning_0" || ev.type === "DayPlanning_1" || ev.type === "vacancy") {
            html = '<div class="dhx-tt">';
            html += '<div class="dhx-tt-res">DayPlanning: ' + (ev.text || "") + '</div>';
            html += '<div class="dhx-tt-date">' + formatDateOnly(start) + '</div>';
            html += '<div class="dhx-tt-table">';
            html += '<div class="dhx-tt-label">Start Time:</div><div class="dhx-tt-val">' + formatTimeOnly(start) + '</div>';
            html += '<div class="dhx-tt-label">End Time:</div><div class="dhx-tt-val">' + formatTimeOnly(end) + '</div>';
            html += '<div class="dhx-tt-label">Project:</div><div class="dhx-tt-val">' + jobNo + '</div>';
            html += '<div class="dhx-tt-label">Task:</div><div class="dhx-tt-val">' + jobTaskNo + '</div>';
            html += '<div class="dhx-tt-label">Pool no.:</div><div class="dhx-tt-val">' + vendor + '</div>';
            html += '<div class="dhx-tt-label">Dayno|DayLineNo:</div><div class="dhx-tt-val">' + (ev.id || "") + '</div>';
            html += '</div></div>';
        }
        return html;
    };
    
    scheduler.locale.labels.timeline_tab = "Timeline";
    scheduler.locale.labels.section_custom="Section";
    scheduler.config.details_on_create=true;
    scheduler.config.details_on_dblclick=false; // Disable opening lightbox on double click

    // Start weeks on Monday
    scheduler.config.start_on_monday = true;

    // // Top title for the timeline tab (hide week period header)
    // scheduler.templates.timeline_date = function (start, end) {
    //     return ""; // Return empty string to hide the header
    // };

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
    // First JS call of the initial load cycle (ControlReady -> Init -> LoadData) — make sure
    // the overlay is showing even if BOOT's own earliest-show got missed for some reason.
    // Hidden at the end of LoadData(), the true last step of that cycle.
    _showResLoading();

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
    // scheduler.config.header = ["date"];

    // Create timeline view (always with a valid y_unit array)    
    RecreateTimelineView(elements);

    scheduler.init('scheduler_here', EarliestPlanningDate, "timeline");

    // Wire the Resource filter toolbar now that scheduler DOM exists
    setupFilterToolbar();

    // Wire the Collapse/Expand All icon now that the tree timeline exists
    setupCollapseAllToggle();

    // Notify BC
    Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("OnAfterInit", []);
}

// ═══════════════════════════════════════════════════════════════
// Collapse/Expand All (folder rows of the tree timeline)
// ═══════════════════════════════════════════════════════════════
function setupCollapseAllToggle() {
    var root = document.getElementById('scheduler_here');
    if (!root || root._collapseAllWired) return;
    root._collapseAllWired = true;

    var btn = document.createElement('button');
    btn.id = 'res-collapseall-icon';
    btn.type = 'button';
    _renderCollapseAllIcon(btn);
    btn.addEventListener('click', function (e) {
        e.stopPropagation();
        ToggleCollapseExpandAllSections();
    });

    root.appendChild(btn);
}

function _renderCollapseAllIcon(btn) {
    var collapsed = _allSectionsCollapsed;
    btn.title = collapsed ? 'Expand All' : 'Collapse All';
    btn.innerHTML = collapsed
        ? '<svg viewBox="0 0 24 24" width="13" height="13" fill="none" stroke="#fff" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round"><path d="M15 3h6v6M9 21H3v-6M21 3l-7 7M3 21l7-7"/></svg>'
        : '<svg viewBox="0 0 24 24" width="13" height="13" fill="none" stroke="#fff" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round"><path d="M4 14h6v6M20 10h-6V4M14 10l7-7M10 14l-7 7"/></svg>';
}

// Sets open/closed on every folder node of the tree timeline (recursively, via the
// y_unit_original tree the treetimeline plugin keeps internally) and forces a redraw.
// Same idea as gantt.eachTask(...)+gantt.render() in src/dhx/ganttdemo2/wrapper.js's
// ToggleCollapseExpandAll, adapted to the dhtmlx Scheduler's tree API
// (_getArrayToDisplay flattens y_unit_original into the visible y_unit; onOptionsLoad
// is what the library itself fires after a folder toggle to trigger the matching
// re-render). Mirrors ToggleCollapseExpandAllSections in src/dhx/projectschedule/wrapper.js.
function ToggleCollapseExpandAllSections() {
    if (typeof scheduler === "undefined" || !scheduler.matrix || !scheduler.matrix.timeline ||
        !scheduler.matrix.timeline.y_unit_original) {
        return;
    }

    _allSectionsCollapsed = !_allSectionsCollapsed;
    var open = !_allSectionsCollapsed;

    (function setOpen(nodes) {
        for (var i = 0; i < nodes.length; i++) {
            if (nodes[i].children) {
                nodes[i].open = open;
                setOpen(nodes[i].children);
            }
        }
    })(scheduler.matrix.timeline.y_unit_original);

    scheduler.matrix.timeline.y_unit = scheduler._getArrayToDisplay(scheduler.matrix.timeline.y_unit_original);
    scheduler.callEvent("onOptionsLoad", []);

    var btn = document.getElementById('res-collapseall-icon');
    if (btn) _renderCollapseAllIcon(btn);
}

// ═══════════════════════════════════════════════════════════════
// Resource filter toolbar (top-left of the timeline grid)
// ═══════════════════════════════════════════════════════════════
// Default: only the (funnel) filter button is shown -> click opens the BC filter popup
// (Resource No.). Once AL applies a filter (dialog closed with OK, not Cancel), a (✕)
// reset button appears next to it and hovering the filter button shows what's applied.
// Clicking (✕) clears the filter back to the default state.
function setupFilterToolbar() {
    var root = document.getElementById('scheduler_here');
    if (!root || root._filterToolbarWired) return;
    root._filterToolbarWired = true;

    var toolbar = document.createElement('div');
    toolbar.id = 'res-filter-toolbar';
    root.appendChild(toolbar);

    _updateResFilterToolbar();
}

function _positionResFilterTooltip(e) {
    var popup = document.getElementById('res-filter-tooltip-popup');
    if (!popup) return;
    var left = e.clientX + 12;
    var top = e.clientY + 12;
    var popupW = popup.offsetWidth || 200;
    var popupH = popup.offsetHeight || 60;
    if (left + popupW > window.innerWidth) left = e.clientX - popupW - 12;
    if (top + popupH > window.innerHeight) top = e.clientY - popupH - 12;
    popup.style.left = left + 'px';
    popup.style.top = top + 'px';
}

function _updateResFilterToolbar() {
    var toolbar = document.getElementById('res-filter-toolbar');
    if (!toolbar) return;
    toolbar.innerHTML = '';

    var popup = document.getElementById('res-filter-tooltip-popup');
    if (!popup) {
        popup = document.createElement('div');
        popup.id = 'res-filter-tooltip-popup';
        document.body.appendChild(popup);
    }

    var fi = _resFilterInfo;

    popup.innerHTML = '';
    var titleEl = document.createElement('b');
    titleEl.textContent = fi ? 'Filter applied:' : 'Click to filter by Resource';
    popup.appendChild(titleEl);
    if (fi) {
        if (fi.resNo || fi.resName) {
            popup.appendChild(document.createElement('br'));
            popup.appendChild(document.createTextNode('Resource = ' + (fi.resNo || '(any)') + (fi.resName ? (' - ' + fi.resName) : '')));
        }
        if (fi.skillFilter) {
            popup.appendChild(document.createElement('br'));
            popup.appendChild(document.createTextNode('Skill = ' + fi.skillFilter));
        }
        if (fi.periodFrom || fi.periodTo) {
            popup.appendChild(document.createElement('br'));
            popup.appendChild(document.createTextNode('Period: ' + (fi.periodFrom || '') + ' to ' + (fi.periodTo || '')));
        }
    }

    // (funnel) Filter button — always visible; opens the BC filter popup
    var filterBtn = document.createElement('button');
    filterBtn.className = 'res-filter-icon';
    filterBtn.innerHTML =
        '<svg viewBox="0 0 24 24" width="13" height="13" style="vertical-align:middle;">' +
            '<path d="M3 4h18l-7.2 8.6v6.4l-3.6 1.8v-8.2z" fill="#fff"/>' +
        '</svg>';
    filterBtn.style.cssText = 'background:' + (fi ? '#1a73e8' : '#5f6368') +
        ';border:none;border-radius:50%;width:22px;height:22px;line-height:22px;' +
        'text-align:center;padding:0;cursor:pointer;vertical-align:middle;display:inline-block;';

    filterBtn.addEventListener('mouseenter', function (e) {
        popup.style.display = 'block';
        _positionResFilterTooltip(e);
    });
    filterBtn.addEventListener('mousemove', function (e) {
        _positionResFilterTooltip(e);
    });
    filterBtn.addEventListener('mouseleave', function () {
        popup.style.display = 'none';
    });
    filterBtn.addEventListener('click', function (e) {
        e.stopPropagation();
        popup.style.display = 'none';
        Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('OnResourceFilterIconClick', []);
    });

    toolbar.appendChild(filterBtn);

    // (✕) Reset button — only shown once a filter is applied
    if (fi) {
        var resetBtn = document.createElement('button');
        resetBtn.className = 'res-filter-reset';
        resetBtn.title = 'Click to Reset Filter';
        resetBtn.textContent = '✕';
        resetBtn.style.cssText = 'background:#c0392b;border:none;border-radius:50%;width:22px;height:22px;' +
            'line-height:22px;text-align:center;padding:0;cursor:pointer;font-size:13px;font-weight:700;' +
            'color:#fff;vertical-align:middle;display:inline-block;';

        resetBtn.addEventListener('click', function (e) {
            e.stopPropagation();
            popup.style.display = 'none';
            Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('OnClearResourceFilter', []);
        });

        toolbar.appendChild(resetBtn);
    }
}

// Called by AL after a filter is applied (dialog closed with OK) or after any schedule
// refresh, to keep the toolbar/tooltip in sync. All three filter args blank means "not
// filtered" — a Skill-only (or Name-only) filter with a blank Resource No. must still
// count as "applied" (bug: previously only resNo was checked, so filtering by Skill
// alone left the toolbar showing its default/unfiltered state).
function SetResourceFilterInfo(resNo, resName, periodFrom, periodTo, skillFilter) {
    if (!resNo && !resName && !skillFilter) {
        _resFilterInfo = null;
    } else {
        _resFilterInfo = {
            resNo: resNo || '',
            resName: resName || '',
            periodFrom: periodFrom || '',
            periodTo: periodTo || '',
            skillFilter: skillFilter || ''
        };
    }
    _updateResFilterToolbar();
}

// ============================================================
// AL-callable: SetBarColors - apply setup-driven Capacity bar color/border. This page is
// Capacity-only (see the "Capacity-only mode for now" comment on the DayPlanning action
// group in page_50600_DHXSchedulePoolResource.al) - no Envelope/Assigned/Requested keys
// are read here since nothing on this page renders those bar types. Same idiom as
// src/dhx/resourceschedule_with_capacity/wrapper.js's own SetBarColors (per-key guards,
// tolerant JSON parse).
// ============================================================
function SetBarColors(colorsJson) {
    try {
        var colors = ParseJSonTxt(colorsJson) || {};
        var root = document.getElementById("scheduler_here");
        if (!root) return;
        if (colors.capacity) root.style.setProperty("--cap-color", colors.capacity);
        if (colors.capacityBorder) root.style.setProperty("--cap-color-border", colors.capacityBorder);
        // "fontColor" is sent by page 50600's ControlReady (via codeunit 50609's
        // GetBarFontColor, "Daily Optimizer Setup"."Bar Font Color") - applies uniformly to every
        // bar's on-bar label text (Capacity/Vacancy/DayPlanning_0/DayPlanning_1 event types
        // above). Does NOT affect hover/tooltip text.
        if (colors.fontColor) root.style.setProperty("--bar-font-color", colors.fontColor);
    } catch (e) {
        console.warn("SetBarColors: invalid colorsJson", colorsJson, e);
    }
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
    } finally {
        // True last step of the initial load cycle (ControlReady -> Init -> LoadData) —
        // always hide, even if parsing threw, so the overlay never gets stuck.
        _hideResLoading();
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

    // Self-contained full reload cycle (sections + events + view in one shot) — show at the
    // start, hide in the finally below so it never gets stuck even if something throws.
    _showResLoading();

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
    } finally {
        _hideResLoading();
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
        dy: 20,
        event_dy: 20,   // Height for event rows
        folder_dy: 20,  // Height for parent/folder rows
        section_autoheight: false,
        resize_events: true,
        y_unit: sections,
        y_property: "section_id",
        render: "tree",
        scale_height: 40,
        second_scale: {
            x_unit: "day",
            x_date: "%D %d %M"
        }
    });

    // Customize parent row background color for event area
    scheduler.templates.timeline_row_class = function(section, date) {
        // Check section category and return appropriate class
        if (section.category === 'Vendor' || section.category === 'Pool') {
            return "timeline-parent-row";
        }
        if (section.category === 'Group') {
            return "timeline-group-row";
        }
        if (section.category === 'Resource') {
            return "timeline-resource-row";
        }
        return "";
    };

    // Customize label cell class for left column
    scheduler.templates.timeline_scaley_class = function(key, label, section) {
        // Check section category and return appropriate class
        if (section && (section.category === 'Vendor' || section.category === 'Pool')) {
            return "vendor-category";
        }
        if (section && section.category === 'Group') {
            return "group-category";
        }
        if (section && section.category === 'Resource') {
            return "resource-category";
        }
        return "";
    };

}

function get_events_not_match_with_section() {
    // get all events that has section_id not in the current sections
    var invalidEvents = [];
    var sectionsMap = {};
    if (scheduler.matrix && scheduler.matrix.timeline && Array.isArray(scheduler.matrix.timeline.y_unit)) {
        scheduler.matrix.timeline.y_unit.forEach(function(section) {
            sectionsMap[section.key] = true;
        });
    }

    if (scheduler.getEvents) {
        var allEvents = scheduler.getEvents();
        allEvents.forEach(function(event) {
            if (!sectionsMap[event.section_id]) {
                invalidEvents.push(event);
            }
        });
    }

    Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('OnEventsNotMatch', [JSON.stringify(invalidEvents)]);
    // return invalidEvents;
}

function getAllEvents() {
    var allEvents = [];
    if (scheduler.getEvents) {
        allEvents = scheduler.getEvents();
    }
    
    Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('OnGetAllEvents', [JSON.stringify(allEvents)]);
}

function getAllSections() {
    var allSections = [];
    if (scheduler.matrix && scheduler.matrix.timeline && Array.isArray(scheduler.matrix.timeline.y_unit)) {
        allSections = scheduler.matrix.timeline.y_unit;
    }
    Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('OnGetAllSections', [JSON.stringify(allSections)]);
}