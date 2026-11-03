from .lib import *


def build(st):
    # ------------------------------------------------------------------ 1
    h1(st, "1. Purpose, scope and file inventory")
    p(st, "This document explains, in detail, how Business Central page **50620 'Gantt Demo DHX 2'** works together with the control "
          "add-in **'DHX Gantt Control 2'**, its JavaScript wrapper (**wrapper.js**) and the **DHTMLX Gantt** component "
          "(**dhtmlxgantt.js**). It follows the data from the moment the page opens, through the control add-in, into the JavaScript, and into "
          "the DHTMLX widgets, and then follows user interaction back from the browser into AL triggers.")
    p(st, "It is written for developers who need to maintain or extend the Gantt, and for consultants who need to understand what each menu, "
          "button and setting does and what is happening behind it.")
    h2(st, "1.1 What the page does")
    bullets(st, [
        "Shows **Job Tasks** (Job No. + Job Task No.) as a hierarchical task list with a timeline of task bars (the **task panel**).",
        "Shows **resources** and their **Day Plannings** per day in a second panel under the Gantt (the **resource panel**): hours per resource per day, "
        "requested (grey) versus assigned (green/red) load.",
        "Lets the user drag/resize task bars (which updates the Job Task planned dates and, after a preview, the dependent Day Plannings), draw dependency links, "
        "and open the related BC pages (Job Task card, Day Plannings, Sequences, Resource card, Resource calendar, Task Scheduler, Summary).",
        "Supports a configurable visible period (per-user 'Gantt Settings') and Previous / Today / Next navigation.",
    ])
    h2(st, "1.2 Source files")
    table(st, ["File", "Lines", "Role"], [
        ["src/dhx/ganttdemo2/page_50620_GanttDemo.al", "~2000", "The BC page. Hosts the usercontrol, implements every trigger raised by the add-in, owns the actions/ribbon, the page state (AnchorDate, filters, panel flags) and the background-task plumbing."],
        ["src/dhx/ganttdemo2/GantttControl.controladdin.al", "95", "Control add-in definition: scripts, styles, startup script, the 22 events and 29 procedures that form the AL/JS contract."],
        ["src/dhx/ganttdemo2/wrapper.js", "~3650", "All client-side logic. BOOT() configures DHTMLX; the rest are AL-callable functions, renderers, event handlers and helpers."],
        ["src/dhx/ganttdemo2/startupScript.js", "1", "Single line: BOOT(). Runs when BC has loaded the add-in scripts."],
        ["src/dhx/ganttdemo2/style.css", "322", "Gantt look and feel: weekend/holiday shading, bar styles, collapse icon, tooltips, bold rows."],
        ["src/dhx/dhtmlxgantt.js / .css", "vendor", "The DHTMLX Gantt library (with auto_scheduling, marker, undo, resource and tooltip plugins used here)."],
        ["codeunit_50613_GanttChartDataHandler.al", "~1170", "Builds every JSON payload sent to the add-in: tasks, resources, day plannings (paged and incremental), holidays; GetDateRange."],
        ["codeunit_50615_GanttUpdateData.al", "263", "Applies a dragged/edited task from the browser back to the Job Task (UpdateJobTaskFromJson, ApplyPlannedDatesOnly)."],
        ["codeunit_50616_GanttChartLinkHandler.al", "409", "CRUD of dependency links (table 'BCG Gantt Task Link') and constraint helpers."],
        ["codeunit_50617_DayPlanningPeriodSyncMgt.al", "600", "When a task period changes: computes which Day Plannings move, shows the preview page, applies the move."],
        ["codeunit_50713_GanttBGResourcePanelData.al", "147", "Page Background Task that builds resource panel JSON off the interactive session."],
        ["codeunit_50614_GanttBCPageHandler.al", "36", "Opens the correct Job Task card by 'Job View Type'."],
        ["page_50650_GanttChartSetup.al + table 50620", "123", "'Gantt Settings' card and its per-user setup table."],
        ["page_50662 / table_50661", "-", "DayPlanning Period Sync Preview page and its temporary buffer table."],
    ], [0.38, 0.07, 0.55], mono_cols=(0,), bold_first=False)

    # ------------------------------------------------------------------ 2
    h1(st, "2. Architecture overview")
    layers(st)
    p(st, "The control add-in is an iframe inside the BC web client. BC executes the scripts listed in the add-in definition inside that iframe. "
          "Because **wrapper.js is a classic script (not a module)**, every top-level `function` it declares becomes a global and is therefore callable "
          "from AL as `CurrPage.DHXGanttControl2.<Name>(...)` as long as the same name is declared as a `procedure` in the control add-in file. "
          "In the other direction, JavaScript raises AL triggers with `Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('<EventName>', [args])`; the page "
          "implements each one as `trigger <EventName>(...)` under `usercontrol(DHXGanttControl2; ...)`.")
    h2(st, "2.1 Three rules of this integration")
    numbered(st, [
        "**All data is JSON text.** AL builds Text payloads (JsonArray/JsonObject.WriteTo) and passes them to JS; JS parses with `_tryParseJson` and feeds DHTMLX. "
        "Inbound edits travel the other way as JSON strings in a single Text argument.",
        "**Ids are composite strings.** A Job Task is `JobNo|JobTaskNo` (pipe), a resource is `RES-<No>`, a Day Planning id is the record SystemId. "
        "Because the DHTMLX task id equals the BC key, a task event can be mapped back to a Job Task with `Split('|')` and no lookup table.",
        "**Add-in calls are not allowed from background-task completion triggers.** BC rejects any `CurrPage.<control>.X()` issued from "
        "OnPageBackgroundTaskCompleted/Error. The solution is a JS-driven poll (section 11) that pulls pending results through a normal synchronous trigger.",
    ])
    h2(st, "2.2 End-to-end data flow (read path)")
    flow(st, [
        ("1. Page 50620 OnOpenPage", "Loads/creates the per-user 'Gantt Chart Setup', sets AnchorDate := Today."),
        ("2. Add-in loads, startupScript.js -> BOOT()", "Builds DOM, configures DHTMLX, gantt.init, installs handlers, raises ControlReady."),
        ("3. ControlReady trigger -> LoadAllData()", "Sends colours/settings, LoadProject, LoadHolidaysData, SetColumnVisibility, LoadProjectData (tasks), LoadLinksData."),
        ("4. Resource panel (only when visible)", "Chunk 0 built synchronously; further chunks via Page Background Task + JS poll."),
        ("5. RenderGantt()", "Refreshes the datastores, one gantt.render(), restores focus on the last clicked task, hides the loading overlay."),
    ])
    h2(st, "2.3 End-to-end data flow (write path)")
    flow(st, [
        ("User action in the browser", "Drag/resize a bar, edit a cell, draw/delete a link, right-click menu, double-click."),
        ("DHTMLX event handler in BOOT()", "onAfterTaskDrag / onAfterTaskUpdate / onAfterLinkAdd / onAfterLinkDelete / onContextMenu / onTaskDblClick ..."),
        ("InvokeExtensibilityMethod('<Event>', [json])", "Serialises the payload (ids, ISO dates, durations)."),
        ("AL trigger on page 50620", "Calls the matching codeunit (Gantt Update Data, Link Handler, Period Sync) or opens a BC page."),
        ("Reload what changed", "Only the affected part is re-sent (tasks+links, or just the resource panel) and rendered."),
    ])

    # ------------------------------------------------------------------ 3
    h1(st, "3. The control add-in definition (the AL/JS contract)")
    p(st, "File: `GantttControl.controladdin.al` (control add-in **'DHX Gantt Control 2'**). It has no logic; it is the interface that both sides code against.")
    h2(st, "3.1 Properties")
    table(st, ["Property", "Value", "Meaning"], [
        ["RequestedHeight / MinimumHeight", "1500 / 600", "The add-in asks for a tall area because the resource panel is stacked under the task panel; VerticalStretch/Shrink let BC fit it to the window."],
        ["RequestedWidth / MinimumWidth", "1800 / 700", "Wide timeline; HorizontalStretch/Shrink adapt to the window."],
        ["Scripts", "dhtmlxgantt.js, wrapper.js", "Order matters: the library first, then the wrapper that uses the global `gantt` object."],
        ["StyleSheets", "dhtmlxgantt.css, style.css", "Library skin first, then BC-specific overrides."],
        ["StartupScript", "startupScript.js", "Contains only `BOOT();`. BC runs it when the add-in frame is ready."],
    ], [0.27, 0.2, 0.53], mono_cols=(1,))
    h2(st, "3.2 Events: browser -> AL (22)")
    p(st, "Each event is raised from wrapper.js and handled by a trigger of the same name on page 50620.")
    table(st, ["Event", "Arguments", "Raised when / what the AL trigger does"], [
        ["ControlReady", "-", "End of BOOT(). Page sets ResourcePanelFlag := false, calls LoadAllData() then SetResourcePanelVisibility."],
        ["OnAfterInit", "-", "Raised by BC after the add-in is created. Ensures the per-user setup record exists (setup.EnsureUserRecord / Get)."],
        ["onTaskDblClick", "eventId, eventData", "Double-click on a task row/bar, or menu 'Show Task'. Splits the id and opens the Job Task card via codeunit 50614 (card depends on 'Job View Type')."],
        ["onOpenDayPlanning", "taskId, eventData", "Menu 'Show Day Planning'. Opens page 'Day Plannings' filtered to the Job/Task and the bar's visual period."],
        ["onOpenDayPlanningVisual", "taskId, eventData", "Menu 'Show Task Scheduler'. Opens page 'DHX Scheduler (Project)' for the Job/Task."],
        ["OnJobTaskUpdated", "eventData (JSON)", "A task bar was dragged/resized or edited. Calls Gantt Update Data.UpdateJobTaskFromJson, shows the Day Planning period-sync preview, then reloads tasks/links/panel (section 13)."],
        ["OpenResourceLoadDay", "resourceId, taskDate, planStatus, idList", "Double-click or menu 'Open Day Plannings' on a resource-panel day marker. Opens Day Plannings for that resource/day, then refreshes the panel only if data changed."],
        ["OpenSequences", "idList", "Menu 'Open Sequences' on a marker. Opens page 'Day Planning Sequence' with the related sequence rows highlighted (modal), then refreshes the panel if data changed."],
        ["OnLinkCreated / OnLinkDeleted", "linkData (JSON)", "User drew or removed a dependency arrow. Stored/removed by Gantt Chart Link Handler (UpsertLinkFromJson / DeleteLinkFromJson)."],
        ["OnShowResourcesForTask", "taskId, childrenJson, periodFrom, periodTo", "Task-bar left click or menu 'Show Job Resources'. Builds the task-scope (task + children), shows the resource panel and loads it."],
        ["OnShowSummaryForTask", "taskId, childrenJson, periodFrom, periodTo", "Menu 'Summary'. Opens page 'Summary View' for the Job/Task."],
        ["OnResourceDblClick", "resourceId", "Double-click or menu 'Show Resource Card' on a resource name. Opens the Resource Card."],
        ["OnResourceHover", "resourceId", "Mouse over a resource name. Computes per-resource statistics for the visible period and returns them via SetResourceStats."],
        ["onOpenResourceScheduler", "resourceId", "Menu 'Resource Calendar'. Lets the user pick a week (StrMenu) then opens 'Resource Scheduler - Calendar' for that resource/week."],
        ["OnResetResourceFilter", "-", "Red (x) next to the resource-panel header. Clears the task scope and reloads the unfiltered panel."],
        ["onAddDayPlanning", "resourceId, taskDate", "Menu 'Add Day Planning' on an empty resource-timeline cell. Pre-fills a new Day Planning (resource, date, work-hour template) and opens the card."],
        ["OnResourceFilterRetrieved", "filterJson", "Answer to GetResourceFilter: stores the JS-side filter JSON in CurrentResourcePanelFilterJsonString."],
        ["OnGanttFilterIconClick", "-", "Funnel icon in the 'Task name' header. Opens the 'Task Scheduler Filter' dialog; applies Job/Job Task filter and refreshes."],
        ["OnGanttClearTaskFilter", "-", "Red (x) next to the funnel. Clears JobFilter/JobTaskFilter and refreshes."],
        ["OnGanttContextAddFilter", "jobNo, jobTaskNo", "Menu 'Add Filter' on a task row. Applies that row's Job/Task (range for parents) as the filter, no dialog."],
        ["OnPollResourcePanelResult", "-", "Poll tick (section 11). Pushes any pending background-task result into the add-in and chains the next chunk."],
    ], [0.26, 0.19, 0.55], mono_cols=(0,), bold_first=False)
    h2(st, "3.3 Procedures: AL -> browser (29)")
    table(st, ["Procedure", "Arguments", "JS function and purpose"], [
        ["LoadProject", "start, end (Date)", "LoadProject(): sets gantt.config.project_start/end and start_date/end_date = visible window; configures auto_scheduling (schedule_on_parse:false). Shows the loading overlay."],
        ["LoadProjectData", "jsonText", "LoadProjectData(): clears tasks/links, gantt.parse({data,links}) inside gantt.silent(); sets the _reloadInProgress guard."],
        ["LoadLinksData", "linksJsonTxt", "Adds every dependency link (silently), then renders."],
        ["LoadHolidaysData", "holidaysJsonTxt", "Fills _ganttHolidays {date: description}; re-renders so holiday shading appears."],
        ["LoadResourcesData", "resourcesJsonTxt", "resourcesStore.clearAll()+parse(); renders unless a full refresh is in progress."],
        ["LoadDayPlanningsData", "json, IsFirstChunk, HasMore", "Builds DayPlanningsByTask/requestJobTaskSet indexes and parses the chunk into DayPlanningsStore; renders on the last chunk."],
        ["ApplyDayPlanningChanges", "changedJson, resourcesJson", "Incremental patch of only the changed Day Plannings after a sub page closes; renders once."],
        ["ClearData", "-", "Starts a full reload: sets _isRefreshing, clears indexes, stores, tasks, links."],
        ["RenderGantt", "skipTrigger", "Final step of every reload: refresh stores, gantt.render(), restore focus, reset _isRefreshing, hide overlay."],
        ["SetColumnVisibility", "ShowStartDate, ShowDuration, ShowTaskType", "Shows/hides grid columns (see the argument-mapping caveat in section 17)."],
        ["SetResourcePanelVisibility", "toggle", "RecreateGanttLayout(toggle): swaps the layout with/without the resource panel."],
        ["SetResourcePanelFilterInfo / ClearResourceFilter / GetResourceFilter", "job, task, from, to", "Maintain _resourceFilterInfo (shown in the header tooltip) and report it back via OnResourceFilterRetrieved."],
        ["SetGanttTaskFilterInfo", "job, task, from, to", "Maintains _ganttTaskFilterInfo and updates the funnel/(x) buttons in the task-name header."],
        ["SetBarFontColor / SetDayOffColors / SetGanttTaskBarDefaults / SetTooltipColors", "colours / sizes", "Apply per-company visual settings as CSS custom properties and gantt.config.task_height."],
        ["SetResourceStats", "resourceId, statsJson", "Caches statistics for the resource-name hover tooltip."],
        ["UpsertLink / DeleteLink", "json / id", "Add-in helpers to patch a single link."],
        ["Undo / Redo / AddMarker", "- / date,text", "gantt.undo(), gantt.redo(), and add a vertical date marker."],
        ["GetGanttData", "-", "JS alert showing project_start/project_end (diagnostic)."],
        ["NotifyResourcePanelTaskPending / StopResourcePanelPolling", "-", "Start/stop the bounded poll loop for background-task results."],
        ["RefreshEventData", "eventData", "Declared in AL but has no JavaScript implementation; only referenced from dead code (section 17)."],
    ], [0.27, 0.2, 0.53], mono_cols=(0,), bold_first=False)

    # ------------------------------------------------------------------ 4
    h1(st, "4. Lifecycle: from opening the page to the first picture")
    h2(st, "4.1 Step by step")
    numbered(st, [
        "**Page opens** (`OnOpenPage`). `OptiSetup.Get()` reads Daily Optimizer Setup. The per-user `Gantt Chart Setup` row is read or created (default: Calculated range, "
        "From formula '-CW', To formula 'CW+4W', all three Load flags true). `AnchorDate := Today()`, `ShowPreviousNext` is true unless the range type is a fixed 'Date Range'.",
        "**BC creates the add-in iframe** and loads dhtmlxgantt.js, wrapper.js (top-level code only declares variables/functions), the CSS files, then runs startupScript.js.",
        "**`BOOT()`** (wrapper.js:132) runs once (`_booted` guard): creates the host and `#gantt_here` containers, shows the loading overlay, checks the library, "
        "installs plugins and configuration, defines templates/columns/lightbox/menus/events, creates the two datastores, builds the layout with `RecreateGanttLayout(true)`, "
        "calls `gantt.init('gantt_here')`, installs the document-level tooltip/menu watchers, and finally raises **ControlReady**.",
        "**`ControlReady` trigger** sets `ResourcePanelFlag := false` (panel starts hidden so nothing is fetched for it), runs `LoadAllData()` and then hides the resource panel layout.",
        "**`LoadAllData()`** (section 4.2) sends visual settings, the period, holidays, column settings, tasks, links and calls `RenderGantt(false)`.",
        "**`RenderGantt`** calls `gantt.render()` once, hides the overlay. The user sees the task panel.",
    ])
    h2(st, "4.2 LoadAllData() in order")
    p(st, "`LoadAllData` is the single procedure behind first open, Refresh Data, Previous/Today/Next, Gantt Settings and filter changes. The order is deliberate:")
    table(st, ["#", "AL call", "JS function", "Why here"], [
        ["1", "SetBarFontColor(GetBarFontColor)", "SetBarFontColor", "Text colour of bar labels (CSS variable --bar-font-color)."],
        ["2", "SetDayOffColors(weekend, holiday)", "SetDayOffColors", "Colours of .weekend/.holiday cells (--gantt-weekend-color/--gantt-holiday-color)."],
        ["3", "SetGanttTaskBarDefaults(border, progress, font, size, height)", "SetGanttTaskBarDefaults", "Global bar look: border colour, progress colour override, font, gantt.config.task_height."],
        ["4", "SetTooltipColors(bg, font)", "SetTooltipColors", "Hover popups (task tooltip, marker tooltip, filter popups)."],
        ["5", "GetDateRange(Setup, AnchorDate, Start, End)", "-", "Resolves the visible window from the setup record (section 8.1)."],
        ["6", "SetGanttTaskFilterInfo(JobFilter, JobTaskFilter, start, end)", "SetGanttTaskFilterInfo", "Funnel/(x) state in the task-name header."],
        ["7", "LoadProject(Start, End)", "LoadProject", "Sets project_start/end and the displayed time scale window; shows the overlay."],
        ["8", "LoadHolidaysData(Start, End)", "LoadHolidaysData", "Base Calendar non-working days for shading."],
        ["9", "SetColumnVisibility(...)", "SetColumnVisibility", "Applies the setup's column switches."],
        ["10", "LoadTaskData() when 'Load Job Tasks'", "LoadProjectData", "The task tree (codeunit 50613.GetJobTasksAsJson)."],
        ["11", "LoadLinkData()", "LoadLinksData", "Dependency arrows."],
        ["12", "GetResourceFilter()", "GetResourceFilter", "Keeps the JS-side filter copy in sync (not used for branching)."],
        ["13", "Resource panel branch", "see section 10", "If a task scope is stored: SetResourcePanelFilterInfo + filtered reload; else if the panel is visible: default reload."],
        ["14", "SetResourcePanelVisibility(true) when visible", "RecreateGanttLayout", "Layout with the resource panel."],
        ["15", "RenderGantt(false)", "RenderGantt", "The one real paint; ends the refresh cycle."],
    ], [0.04, 0.34, 0.2, 0.42], mono_cols=(1, 2), bold_first=False)
    note(st, "A native `Dialog` ('Loading Gantt data... Job Tasks... Links...') is shown during LoadAllData. Control add-in calls only execute in the browser after the "
             "whole AL trigger returns, so a JS overlay cannot paint while the server is still building JSON; the Dialog is the only live progress indicator in that window.")

    # ------------------------------------------------------------------ 5
    h1(st, "5. wrapper.js global variables and flags")
    p(st, "These are the module-level variables at the top of wrapper.js (and a few that are created later). Understanding them explains most of the control flow.")
    table(st, ["Variable", "Type / initial", "Purpose and where it is used"], [
        ["gantt_here", "DOM element / null", "The #gantt_here container DHTMLX renders into. Used as the 'initialised' test by almost every AL-callable function (`!gantt_here || !gantt.$root` -> ignore the call)."],
        ["_booted", "bool / false", "Makes BOOT() idempotent."],
        ["_queuedColumnArgs", "array / null", "If AL calls SetColumnVisibility before init finished, the args wait here and are applied right after gantt.init."],
        ["resourcesStore", "DHTMLX datastore", "Rows of the resource panel (`{key,label}` -> id=key). Bound to the resource grid and timeline ('bind: resources')."],
        ["DayPlanningsStore", "DHTMLX datastore", "All loaded Day Plannings (one item per Day Planning). Read by the resource renderer, 'Total Hours' column and tooltips."],
        ["window.DayPlanningsByTask", "map taskId -> [DayPlanning]", "Index used to draw the black request bars on task bars and to find a task's Day Plannings. Rebuilt on the first chunk, appended on later chunks, patched by ApplyDayPlanningChanges."],
        ["window.requestJobTaskSet", "map taskId -> true", "Tasks that have at least one Request Day Planning; makes the task bar bold (class bc-task-bold)."],
        ["_isRefreshing", "bool / false", "True between ClearData() and RenderGantt(). While true, the Load* functions skip their own gantt.render() so the full cycle paints once."],
        ["_resourceFilterInfo", "{job,task,periodFrom,periodTo} / null", "Task-scope of the resource panel; drives the blue (i)/red (x) buttons and tooltip in the panel header."],
        ["_resourcePanelInvokeInFlight", "bool", "Serialises the three round trips into the panel (task-bar click, reset button, poll). A second call while one is outstanding would wedge BC's call queue ('Working on it...')."],
        ["_ganttTaskFilterInfo", "object / null", "Job/Job Task filter of the task list; drives the funnel and (x) buttons in the 'Task name' header."],
        ["_ganttHolidays", "map date -> text", "Non-working Mon-Fri days from the Base Calendar; used by scale_cell_class/timeline_cell_class."],
        ["_gtbProgressOverride", "string", "Setup colour for the progress fill. Empty = derive a darker shade of the bar colour per task (`_darkenHex(color, 0.60)`)."],
        ["skipTrigger_OnJobTaskUpdated", "bool / false", "RenderGantt(true) sets it so the next programmatic task update does not raise OnJobTaskUpdated again (prevents a save loop)."],
        ["_allTasksCollapsed", "bool / false", "State of the collapse/expand-all icon in the 'Task name' header."],
        ["_lastClickedTaskId", "id / null", "Last task bar clicked. After a reload, `_restoreTaskFocusAfterReload()` calls showTask/selectTask so the view returns to it."],
        ["_loadingOverlay / _loadingSafetyTimer", "DOM / timer", "The LOADING overlay and its 180 s safety timeout (never stay stuck if RenderGantt is not reached)."],
        ["_dragInProgress", "bool (BOOT scope)", "True 300 ms after a drag; blocks the onAfterTaskUpdate events produced by the drag itself or by auto-scheduling cascades."],
        ["_reloadInProgress", "bool (BOOT scope)", "True while LoadProjectData runs (and 500 ms after); blocks phantom onAfterTaskUpdate events from a data load."],
        ["_resourcePanelPollTimer / Attempts / Active", "timer / int / bool", "State of the bounded poll loop that fetches background-task results."],
        ["RESOURCE_PANEL_POLL_INTERVAL_MS / _FIRST_MS / _MAX_ATTEMPTS", "1500 / 400 / 20", "Poll cadence: first tick after 400 ms, then every 1.5 s, at most 20 ticks (about 30 s) per burst."],
        ["_filterToolbarWatcherBusy", "bool", "Re-entrancy guard of the MutationObserver that re-injects filter buttons."],
        ["resourceLayers", "[renderResourceLine, 'taskBg']", "Layers of the resource timeline: the custom renderer plus the standard background grid."],
    ], [0.27, 0.2, 0.53], mono_cols=(0,), bold_first=False)

    # ------------------------------------------------------------------ 6
    h1(st, "6. BOOT() in detail")
    p(st, "`window.BOOT` (wrapper.js lines 132-1659) is one long function that runs once. It is easiest to read as the following blocks, in source order.")
    h2(st, "6.1 Host and container creation (lines 132-163)")
    p(st, "Finds BC's host element (`#controlAddIn`, or `document.body`), sizes it 100%x100%, creates `#gantt_here` inside it, builds the loading overlay "
          "(`_createLoadingOverlay`) and shows it immediately - this is the earliest moment any JS runs, long before the first AL call. If the DHTMLX library is "
          "missing it logs an error and stops.")
    h2(st, "6.2 Local installer functions (lines 198-554)")
    p(st, "These nested functions are defined first and executed at the end of BOOT (each guarded so it installs once per document):")
    table(st, ["Function", "Purpose"], [
        ["InstallResourceMarkerCustomTooltipsForDayPlannings", "Document-level mousemove/mouseout capture on `.gantt_resource_marker`. On hover it looks up every Day Planning in `DayPlanningsByTask` with the same resource_id and work_date and shows a tooltip table (Project, Task, Status, Skill, Seq, Requested Start/End/Idle/Hours, Assigned Start/End/Idle/Hours; first 8 rows). Resource label comes from resourcesStore."],
        ["InstallResourceGridDblClick", "Double-click on a `.res-name-cell` raises OnResourceDblClick (opens the Resource Card)."],
        ["InstallResourceNameHoverTooltip", "On hover over a resource name it asks AL (OnResourceHover) for statistics once per 30 s per resource; AL answers with SetResourceStats, rendered as a Statistic/Value table (skills, total Day Plannings, requested/assigned/capacity hours)."],
        ["InstallResourceGridContextMenu", "Builds three body-level menus and the capture-phase contextmenu handler: (a) resource name menu, (b) marker menu, (c) empty-cell menu (section 12). Also closes menus on mouse leave, click elsewhere and Escape."],
    ], [0.34, 0.66], mono_cols=(0,), bold_first=False)
    h2(st, "6.3 DHTMLX plugins and global configuration (lines 557-610)")
    bullets(st, [
        "`gantt.plugins({auto_scheduling, marker, undo, resource, tooltip})`: auto-scheduling (dependency/constraint recalculation while dragging), vertical date markers, Undo/Redo, resource views, hover tooltips.",
        "`row_height` default 30, `task_height` default 13 (overridden later by SetGanttTaskBarDefaults).",
        "`date_format = xml_date = '%Y-%m-%d'`: ISO dates everywhere between AL and JS.",
        "`scales`: two header rows - **week** ('wk 45 (Mon, 02 Nov 2026 - Sun, 08 Nov 2026)', alternating week-even/week-odd CSS) and **day** ('Mon 02').",
        "`resource_property = 'resource_id'`: the Day Planning field that links a Day Planning to a resource row.",
        "`work_time = false`, `min_column_width = 55`: durations are calendar days (matches BC's Integer Duration); with work_time=true dragging across a weekend would stretch bars.",
    ])
    h2(st, "6.4 Templates and loading hook (lines 611-692)")
    table(st, ["Hook", "What it does"], [
        ["templates.scale_cell_class / timeline_cell_class", "Adds `weekend` (Sat/Sun) or `holiday` (in _ganttHolidays) to header and body cells; colours come from CSS variables."],
        ["templates.task_class", "Adds the scheduling type class, `bc-task-bold` when the task has Request Day Plannings (requestJobTaskSet), `bc-baseline-bar` for non-Posting tasks (task.bold) and `bc-posting-thin-bar` for Posting tasks."],
        ["templates.progress_text", "Shows the progress percentage (as a number) on the bar when above 0."],
        ["onTaskLoading", "Runs for every task parsed: normalises progress 0-100 -> 0-1; sets task.color (default #3b8ef0) and task.progressColor; makes non-Posting tasks `readonly`; calls `_normalizeTaskBarDates`. Colour is deliberately not stored elsewhere because task.color is DHTMLX's native hook."],
    ], [0.32, 0.68], mono_cols=(0,), bold_first=False)
    h2(st, "6.5 Columns, editors, collapse-all, tooltip (lines 703-890)")
    bullets(st, [
        "**Editors**: text (description), date (start), number (duration, 0+), number (progress 0-100), select (constraint type: asap, alap, snet, snlt, fnet, fnlt, mso, mfo), date (constraint date).",
        "**Columns** (`gantt.config.columns`): `text` (tree, 250 px, with the collapse/expand-all SVG icon in its header), `progress` (%), `start_date`, `duration`, `constraint_type`, `constraint_date`, `schedulingType` ('Task Type'), `add` (+ button). Visibility is controlled by SetColumnVisibility.",
        "**onGridHeaderClick** toggles ToggleCollapseExpandAll() when the icon is clicked (sets `$open` on every task and re-renders).",
        "**grid_row_class** makes non-Posting rows bold (`bc-row-bold`).",
        "**tooltip_text** builds the task hover tooltip: Job and Task table (job description = the top-level ancestor row), Period (start and inclusive end = DHTMLX exclusive end minus one day), and optional constraint rows (Constraint, Constraint Date, Max Duration) from the BC business-constraint fields (`bcConstraintType`, `bcConstraintDate`, `bcMaxDuration`).",
    ])
    h2(st, "6.6 Lightbox (lines 892-917)")
    p(st, "The DHTMLX edit dialog sections: description (textarea), constraint, scheduling type (Fixed Duration / Fixed Units / Fixed Work), time (duration). "
          "The page also blocks the default lightbox on double-click (`onTaskDblClick` returns false) because BC's own Job Task card is opened instead.")
    h2(st, "6.7 Task context menu and click handlers (lines 919-1235)")
    p(st, "`_showContextMenu(x, y, taskId)` builds the right-click menu on a task row/bar. `onContextMenu` shows it, `onTaskClick` turns a left click on a bar "
          "into 'Show Job Resources'. The menu items and the AL behind each are described in section 12.")
    h2(st, "6.8 Link tooltip, drag and update events (lines 1237-1485)")
    table(st, ["Event", "Behaviour"], [
        ["onGanttReady", "Installs mouseover/mousemove/mouseleave listeners on `gantt.$root` to show a Dependency tooltip (From, To, Type FS/SS/FF/SF, Lag)."],
        ["onTaskDblClick", "Raises onTaskDblClick(id, JSON) to open the Job Task card; returns false to block the lightbox."],
        ["onTaskDrag", "While dragging, redraws the black placeholder-date overlay bars (`_renderRequestBars`)."],
        ["onAfterTaskDrag", "Sets `_dragInProgress` for 300 ms, re-normalises start_date, `gantt.refreshTask`, redraws overlays, then raises **OnJobTaskUpdated** with {id, bcJobNo, bcJobTaskNo, text, start_date, end_date, duration, schedulingType, constraint_*} unless skipTrigger_OnJobTaskUpdated is set."],
        ["onAfterTaskUpdate", "Same payload for non-drag edits (lightbox, inline cell editor). Ignored while `_dragInProgress` or `_reloadInProgress`."],
        ["onAfterAutoSchedule", "After the engine recalculated dates for dependent tasks, re-pins start_date to midnight for the touched tasks."],
        ["onAfterLinkAdd / onAfterLinkDelete", "Raise OnLinkCreated / OnLinkDeleted with {id, source, target, type, lag}."],
    ], [0.25, 0.75], mono_cols=(0,), bold_first=False)
    h2(st, "6.9 Datastores, CSS injection, layout and init (lines 1524-1659)")
    numbered(st, [
        "`gantt.createDatastore({name:'resources'})` and `({name:'DayPlannings'})` with `initItem` that assigns ids (resource id = `item.key`; Day Planning id = `item.id`).",
        "Style injection: resource marker colours (`gantt_resource_marker_ok` green, `_overtime` red, `_request` grey), header colours matching BC list headers, filter-icon and tooltip popup styles, and the bar fix that hides DHTMLX's thin planned bracket and forces the actual bar solid.",
        "`RecreateGanttLayout(true)` then `gantt.init('gantt_here')` - the only gantt.init call in the program.",
        "Apply queued column settings; run the four Install* functions and `_installGanttFilterToolbarWatcher()`.",
        "`onGanttRender`: after every render re-injects the resource-header buttons, the task-header filter buttons and the request overlay bars.",
        "`InvokeExtensibilityMethod('ControlReady', [])` - tells AL that calls are now safe.",
    ])
