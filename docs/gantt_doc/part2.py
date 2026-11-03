from .lib import *


def build(st):
    # ------------------------------------------------------------------ 7
    h1(st, "7. JSON contracts (what AL builds, what JS expects)")
    h2(st, "7.1 Task (codeunit 50613 CreateJobTaskJsonObject -> LoadProjectData)")
    p(st, "`LoadProjectData` accepts an array of tasks (or `{tasks, links}`). One object per Job Task:")
    table(st, ["Field", "Source in BC", "Used by JS for"], [
        ["id", "'JobNo|JobTaskNo'", "DHTMLX task id; mapped back to the Job Task by Split('|') in every trigger."],
        ["text", "Posting: 'JobTaskNo - Description', otherwise Description", "Row label and bar text. The prefix is stripped again before saving (see 13.1)."],
        ["start_date", "Effective start (VisualBarStartDate, else Constraint Calc. - Start Date)", "Bar start, ISO yyyy-mm-dd."],
        ["duration", "End - Start + 1 recomputed (NOT Job Task.Duration)", "Inclusive day count; end_date = start + duration (exclusive)."],
        ["bcJobNo / bcJobTaskNo", "Job No. / Job Task No.", "Echoed back in events; used by menus and filters."],
        ["schedulingType", "'fixed_duration' / 'fixed_work' / ''", "CSS class on the bar, Task Type column, lightbox select."],
        ["bcConstraintType / bcConstraintDate / bcMaxDuration", "Job Task constraint fields (empty unless Constraint Date set)", "Task tooltip rows only. Separate from DHTMLX's own constraint_* keys."],
        ["progress", "Progress / 100", "Progress fill (JS also accepts 0-100 and converts)."],
        ["color", "GetGanttTaskBarColor (Posting) or ...NonPosting", "task.color; progressColor derived in JS."],
        ["indentation / bold / open / parent", "Indentation; Job Task Type <> Posting; true for non-Posting; parent task id", "Tree: parent is looked up from an array keyed by indentation (ParentJobTaskId); non-Posting rows are expanded, bold and read-only."],
    ], [0.22, 0.38, 0.4], mono_cols=(0,), bold_first=False)
    h2(st, "7.2 Dependency link (codeunit 50616 GetLinksAsJson -> LoadLinksData)")
    table(st, ["Field", "Meaning"], [
        ["id", "Composite id built from source/target/type (unique, reconstructable)."],
        ["source / target", "Task ids ('JobNo|TaskNo'); both must belong to the same job."],
        ["type", "'0' Finish-to-Start, '1' Start-to-Start, '2' Finish-to-Finish, '3' Start-to-Finish."],
        ["lag", "Lag (Days)."],
    ], [0.2, 0.8], mono_cols=(0,), bold_first=False)
    h2(st, "7.3 Day Planning (codeunit 50613 BuildDayPlanningJsonObject -> LoadDayPlanningsData)")
    p(st, "One object per Day Planning record. About 610 bytes each. The 'Request' variant (`CreateDayPlanningJsonObjectRequest`) is used for undated requests and sets "
          "`work_date = placeholder_date = the Job Task's Placeholder Date` and `plan_status = 'Request'`.")
    table(st, ["Field", "Meaning"], [
        ["id", "Day Planning SystemId (unique store key)."],
        ["task / jobNo / jobTaskNo", "'JobNo-JobTaskNo' (dash, informational), and the two keys; the task index uses jobNo + '|' + jobTaskNo to match the DHTMLX task id."],
        ["dayNo / dayLineNo", "Plan Date and Day Line No. (primary key part)."],
        ["work_date / placeholder_date", "ISO date shown in the panel / placeholder date for undated requests."],
        ["start_time / end_time / hours", "Assigned times; hours = Assigned Hours if not zero else Requested Hours (this is the number drawn in the marker)."],
        ["requested_* / assigned_*", "start_time, end_time, idle_minutes, hours for both sides (tooltip table)."],
        ["resource_id", "'RES-' + Assigned Resource No., else 'RES-' + Requested Resource No., else 'RES-' (unassigned row '- NONE -')."],
        ["type / vendorNo", "'Resource'; vendor number or 'null'."],
        ["plan_status", "Request (In Request), Assigned (In Progress), Rejected, Accepted."],
        ["work_order_no / skill / sequence_no", "Order Intake No., Skill, Sequence No."],
    ], [0.27, 0.73], mono_cols=(0,), bold_first=False)
    h2(st, "7.4 Resource, holiday and background-task result")
    table(st, ["Payload", "Shape"], [
        ["Resource", "[{ key: 'RES-<No>', label: 'Name (No)' }] plus a leading '- NONE -' entry (key 'RES-') for unassigned work. Stored with id = key."],
        ["Holiday", "[{ date: 'yyyy-mm-dd', description, type:'holiday' }] - Mon-Fri non-working days only (weekends are shaded by JS)."],
        ["Background task result", "Dictionary: resourcesJson, dayPlanningsJson, dayPlanningsHasMore ('true'/'false'), dayPlanningsNextCursor (keyset cursor 'pass|job|task|line')."],
        ["Resource filter", "{ job, task, periodFrom, periodTo } - JS state mirrored into AL by GetResourceFilter / OnResourceFilterRetrieved."],
        ["Task update (browser -> AL)", "{ id, bcJobNo, bcJobTaskNo, text, start_date, end_date (exclusive), duration, schedulingType, constraint_type, constraint_date }."],
    ], [0.25, 0.75], mono_cols=(0,), bold_first=False)

    # ------------------------------------------------------------------ 8
    h1(st, "8. How the data is built in AL (codeunit 50613)")
    h2(st, "8.1 GetDateRange - the visible window")
    p(st, "Every load and every report starts from `GetDateRange(GanttSetup, AnchorDate, StartDate, EndDate)`:")
    table(st, ["Date Range Type", "Start", "End"], [
        ["Date Range", "Setup 'From Date'", "Setup 'To Date'"],
        ["Weekly", "Monday of AnchorDate's week", "Sunday of that week + 4 weeks (5 weeks in total)"],
        ["Calculated", "CalcDate(From Data Formula, AnchorDate)", "CalcDate(To Data Formula, AnchorDate). Both formulas are mandatory (TestField)."],
    ], [0.22, 0.38, 0.4], bold_first=False)
    p(st, "If End is blank it becomes 31-12-9999; if Start > End then End := Start. `AnchorDate` is a page variable that Previous/Today/Next change.")
    h2(st, "8.2 GetJobTasksAsJson - the task tree")
    numbered(st, [
        "Reads the per-user setup; Job No. filter = page JobFilter if set, else the setup's 'Job No. Filter'; plus the optional Job Task filter.",
        "Opens **two** server-side filtered cursors on Job Task: (1) tasks whose Planned/Visual-bar dates overlap the window, (2) tasks whose persisted 'Constraint Calc. - Start/End Date' overlap the window.",
        "**Merge-joins** the two cursors in primary-key order (CompareJobTaskKey); a row in both is processed once. This avoids scanning the whole Job Task table.",
        "Skips 'Total' and 'End-Total' rows; `GetEffectivePeriod` picks Planned dates if both set, else the constraint-derived dates; rows with no valid period or out of window are skipped.",
        "`CreateJobTaskJsonObject` writes the object (7.1). The hierarchy is built with an array `ParentJobTaskId[Indentation+1]` that is reset on every new Job No.",
    ])
    h2(st, "8.3 Resources and Day Plannings")
    bullets(st, [
        "**GetResourcesAsJson(Anchor, Job, Task)** collects the distinct resources used by the Day Plannings in the window (Query 'Day Planning Used Resources' plus the undated-request pass), then emits only those resources (plus '- NONE -').",
        "**GetDayPlanningsAsJson(..., Cursor, PageSize, HasMore, NextCursor)** is the paged variant: keyset paging on the primary key (Job No., Job Task No., Day Line No.) in pass 1 (dated rows in the window) and pass 2 (In Request rows with blank Plan Date whose Job Task Placeholder Date is in the window). Each call resumes with `Find('>')` after the cursor key - no rescanning.",
        "**GetDayPlanningsByJobTaskAsJson / GetResourcesByJobTaskAsJson** (task-scoped panel) use a Query joined on the list of 'JobNo|JobTaskNo' keys of the task and its children.",
        "**GetChangedDayPlanningsAsJson** returns only rows with SystemModifiedAt > a timestamp plus their resources (incremental refresh, section 14.4). It returns false when the counts show a delete or a move in/out of scope.",
        "**GetHolidaysAsJson** uses the Base Calendar from Daily Optimizer Setup and Calendar Management (IsNonworkingDay), skipping Sat/Sun.",
    ])

    # ------------------------------------------------------------------ 9
    h1(st, "9. The task panel (task list + timeline)")
    p(st, "The task panel is the upper layout row: a **grid** (left) and a **timeline** (right) that share one vertical scrollbar (`scrollVer`), with a horizontal scrollbar (`scrollHor`) shared with the resource timeline so both panels scroll together in time.")
    h2(st, "9.1 Rows and bars")
    bullets(st, [
        "Rows are the Job Tasks of the window, indented by Indentation. Non-Posting rows (headings) are bold, expanded by default, **read-only** and drawn as thin baseline-style bars. Posting rows are the editable, slimmer rectangular bars.",
        "Bar label = `text`; progress fill shows the percentage; bar colour = setup colour (Posting vs non-Posting), progress colour = darker shade or the setup override.",
        "Tasks that have at least one **Request** Day Planning get `bc-task-bold`; Request Day Plannings with a placeholder date draw a **black overlay bar** (`.bc-req-bar`) at that date on the task row (`_renderRequestBars`, re-run after every render and during drag).",
        "Weekends and holidays are shaded in the header and body; the weekly header alternates two tints.",
        "Dependency links are arrows; hover shows From/To/Type/Lag; drawing a link raises OnLinkCreated, deleting raises OnLinkDeleted.",
    ])
    h2(st, "9.2 Date handling rules (important)")
    bullets(st, [
        "DHTMLX `end_date` is **exclusive** (start + duration days). BC dates are **inclusive**. AL subtracts one day on the way in (`CalcDate('<-1D>')` in UpdateJobTaskFromJson); JS subtracts one day for tooltips and for the Show Resources/Summary period.",
        "`_normalizeTaskBarDates` forces `start_date` to 00:00:00 after load, drag, edit and auto-scheduling so bars start exactly on a day boundary. It deliberately leaves end_date alone: an earlier version stamped 23:59:59 on end_date and made bars overshoot by one day.",
        "`LoadProject` sets `auto_scheduling.schedule_on_parse:false`. The visible window changes on every Previous/Next, so an on-load auto-schedule would pull ASAP tasks to the window start. Auto-scheduling still works for interactive drag/link changes.",
        "`gantt.silent()` wraps data loads so that parse/render does not fire per-task update events at BC.",
    ])
    h2(st, "9.3 Header features")
    bullets(st, [
        "**Collapse/Expand all** icon (two SVGs) in the 'Task name' header toggles `$open` for every task.",
        "**Funnel filter button** (injected after the icon by `_updateGanttFilterToolbar`): grey when no filter, blue when filtered; hover popup shows 'Job = ..., Task = ..., period'; click raises OnGanttFilterIconClick. A red (x) appears when filtered and raises OnGanttClearTaskFilter.",
        "A **MutationObserver** (`_installGanttFilterToolbarWatcher`) re-injects the buttons if DHTMLX re-renders the header (for example when the panel resizer is dragged) and wipes them.",
    ])

    # ------------------------------------------------------------------ 10
    h1(st, "10. The resource panel")
    h2(st, "10.1 Layout: two stacked rows sharing one time axis")
    p(st, "`RecreateGanttLayout(show)` writes `gantt.config.layout`. With the panel it has two rows: the task row (gravity 2) and the resource row (gravity 1) separated by a resizer; "
          "the resource row contains a **grid** (`resourceGrid`, columns 'Name' and 'Total Hours') and a **timeline** (`resourceTimeline`) both **bound to the datastore `resources`**, "
          "plus their own vertical scrollbar `resourceVScroll`. Both timelines use the single `scrollHor`, so scrolling in time moves both panels. "
          "Without the panel the layout contains only the task row. `gantt.resetLayout()` applies a changed layout and then `_restoreTaskFocusAfterReload()` re-anchors the last clicked task.")
    h2(st, "10.2 Panel state on the AL side")
    table(st, ["Page variable", "Meaning"], [
        ["ResourcePanelFlag", "True while the panel is visible. False after ControlReady (panel starts hidden)."],
        ["ResourcePanelJobNo / JobTaskNo / ChildTaskIds / From / To", "Task scope when the panel was opened from a task ('Show Job Resources'). Empty = unfiltered 'Default' mode."],
        ["CurrentResourcePanelFilterJsonString", "JSON copy of the JS-side filter; used by Add Day Planning and the Day Plannings action. Can lag (async), so reload logic uses the native variables instead."],
        ["ResourcePanelTaskId / ResourcePanelTaskRunning", "Id of the newest background task and a busy flag (new requests are dropped while a chunk chain is running)."],
        ["PendingResourcesJson / PendingDayPlanningsJson / PendingResultAvailable / PendingDayPlanningsHasMore / NextCursor / IsFirstChunk", "A delivered-but-not-yet-pushed background result."],
        ["ResourcePanelChunkJobFilter / JobTaskFilter / AnchorDate", "Scope snapshot so a multi-chunk load keeps one consistent scope even if the user changes filters meanwhile."],
    ], [0.4, 0.6], mono_cols=(0,), bold_first=False)
    h2(st, "10.3 Two scopes")
    table(st, ["Mode", "Opened by", "Content", "How it is loaded"], [
        ["Filtered (task scope)", "Left click on a task bar, menu 'Show Job Resources', reload after a task drag", "Resources and Day Plannings of the clicked task and its children for the view window", "Built **synchronously** in the page (EnqueueFilteredResourcePanelReload) - the scope is small. LoadResourcesData + LoadDayPlanningsData(json, true, false)."],
        ["Default (all)", "Action 'Show Resource Panel', red (x) reset, any refresh while the panel is visible", "All resources/Day Plannings in the window and Job/Job Task filter", "**Chunk 0 synchronously** (resources + first 5000 Day Plannings). If HasMore, the next chunks run as Page Background Tasks (section 11)."],
    ], [0.14, 0.25, 0.28, 0.33], bold_first=True)
    h2(st, "10.4 How the timeline is drawn (renderResourceLine)")
    p(st, "The resource timeline does not use DHTMLX's built-in resource histogram. It registers a **custom layer** `renderResourceLine(resource, timeline)` that returns one absolutely positioned `<div>` row per resource:")
    numbered(st, [
        "`calculateResourceLoad(resource, scale)` sums `hours` per calendar day for that resource, ignoring 'Request' rows and non-working days (`gantt.isWorkTime`).",
        "For every day with load a cell is created at `timeline.getItemPosition(resource, dayStart, dayEnd)`. **Green** (`gantt_resource_marker_ok`) when the day total is <= 8 hours, **red** (`_overtime`) when above 8.",
        "The hours are centred in the cell. A **count badge** (top-left) appears when more than one Day Planning falls on that resource/day.",
        "If a Request exists on the same day as a planned cell, a **black 6 px bar** is added at the bottom of that cell.",
        "Days that have only Request Day Plannings get a **grey** box (`gantt_resource_marker_request`) with the requested hours and a badge if several.",
        "Each cell carries `data-resource-id`, `data-work-date`, `data-plan-status` and `data-id-list` (pipe-separated Day Planning ids). These data attributes drive tooltips, double-click and the context menu.",
        "Double-click on a cell raises **OpenResourceLoadDay** (resource, date, status, id list).",
    ])
    note(st, "The left grid 'Total Hours' column sums `hours` of all loaded Day Plannings of that resource (Request rows included, because `hours` falls back to Requested Hours). "
             "The per-cell value excludes Request rows. The two numbers are therefore not expected to match when Requests exist.")
    h2(st, "10.5 Header controls")
    bullets(st, [
        "When a task scope is active, `_updateResourceHeaderTooltip` adds a blue **(i)** button (hover popup: 'Filter applied: Job = ..., Task = ..., period') and a red **(x)** button to the 'Total Hours' header.",
        "Clicking (x) raises **OnResetResourceFilter**: AL clears the scope and reloads the unfiltered panel. The call is serialised with `_resourcePanelInvokeStart/End`.",
        "`SetResourcePanelFilterInfo`, `ClearResourceFilter` and `GetResourceFilter` maintain and report `_resourceFilterInfo`.",
    ])
    h2(st, "10.6 Hover tooltips")
    bullets(st, [
        "**Day marker** hover: table of all Day Plannings of that resource/day with Requested and Assigned Start/End/Idle/Hours (client-side, from DayPlanningsByTask).",
        "**Resource name** hover: Statistic/Value table (skills, Total Day Plannings, Requested Hours, Assigned Hours, Capacity Hours) computed in AL (`ResScheduler_BuildSectionStatsJson`) for the visible period, cached 30 s per resource.",
    ])

    # ------------------------------------------------------------------ 11
    h1(st, "11. Background-task pipeline and the poll loop")
    p(st, "Large Day Planning tables made a single synchronous load block the page, so chunks beyond the first are built by **Page Background Tasks** (codeunit 50713 'Gantt BG Resource Panel Data'), "
          "which run in a separate read-only session. BC forbids calling the control add-in from `OnPageBackgroundTaskCompleted`, so a small poll loop in JS pulls the result.")
    flow(st, [
        ("AL: EnqueueNextDefaultResourcePanelDayPlanningChunk(cursor)", "CurrPage.EnqueueBackgroundTask(codeunit 50713, params: Mode, filters, DayPlanningCursor, DayPlanningPageSize)"),
        ("AL: CurrPage.DHXGanttControl2.NotifyResourcePanelTaskPending()", "JS starts a bounded poll burst: first tick 400 ms, then every 1.5 s, at most 20 ticks"),
        ("Codeunit 50713 OnRun builds the chunk", "GetDayPlanningsAsJson(... cursor ...) -> SetBackgroundTaskResult(resourcesJson, dayPlanningsJson, hasMore, nextCursor)"),
        ("AL: OnPageBackgroundTaskCompleted", "Only stores the result in page variables (cannot touch the add-in). Ignores results whose TaskId is not the newest."),
        ("JS poll tick: InvokeExtensibilityMethod('OnPollResourcePanelResult')", "Guarded by _resourcePanelInvokeStart so ticks never overlap other panel calls"),
        ("AL: OnPollResourcePanelResult", "If a result is pending: LoadResourcesData, LoadDayPlanningsData(json, isFirst, hasMore); if HasMore enqueue the next chunk, else StopResourcePanelPolling"),
    ])
    h2(st, "11.1 Why each safeguard exists")
    table(st, ["Safeguard", "Reason"], [
        ["_resourcePanelInvokeInFlight (JS)", "BC's call bridge does not block JS while a call is outstanding. A second InvokeExtensibilityMethod before the first returns wedges the queue and every later call hangs ('Working on it...')."],
        ["ResourcePanelTaskRunning (AL)", "EnqueueBackgroundTask has no cancel. Rapid clicking piled up concurrent full-table reads and slowed the whole environment, so new requests are dropped while one runs."],
        ["TaskId comparison", "A superseded task still completes server-side; its result is discarded if its TaskId is not the newest."],
        ["Chunk scope snapshot", "Keeps all chunks of one load on the same filters/AnchorDate."],
        ["Bounded polling (20 ticks)", "Never poll forever on an idle page; each new chunk restarts a fresh burst."],
        ["Synchronous chunk 0", "A background task costs about 0.8 s (session start + polling) while the query itself is about 0.1 s for ~800 records; the first chunk and the whole task-scoped load therefore run in the page."],
    ], [0.3, 0.7], bold_first=True)

    # ------------------------------------------------------------------ 12
    h1(st, "12. Right-click menus, clicks and double-clicks")
    p(st, "There are **four** context menus plus click/double-click behaviours. All menus close when the mouse leaves them, on click elsewhere, on Escape, and hide hover tooltips while open.")
    h2(st, "12.1 Task row / task bar menu")
    p(st, "Opened by DHTMLX `onContextMenu` on a task. Built by `_showContextMenu`.")
    table(st, ["Menu item", "JS function -> event", "What happens in BC"], [
        ["Summary", "_ctxShowSummary -> OnShowSummaryForTask", "Opens page 'Summary View' loaded for the Job/Job Task (LoadDataSet) without the job/task columns."],
        ["Show Job Resources", "_ctxShowResources -> OnShowResourcesForTask", "Shows the resource panel scoped to the task and its descendants for the view window; stores the scope in ResourcePanelJobNo/TaskNo/ChildTaskIds; loads synchronously; header (i)/(x) buttons appear."],
        ["Show Task", "_ctxOpenTask -> onTaskDblClick", "Opens the Job Task card (Opti Job Task Card for Project view, Job Task Card - Resource for Resource view)."],
        ["Show Day Planning", "_ctxOpenDayPlanning -> onOpenDayPlanning", "Opens 'Day Plannings' filtered by Job No., Job Task No. and the task's visual bar period."],
        ["Show Task Scheduler", "_ctxOpenDayPlanningVisual -> onOpenDayPlanningVisual", "Opens the visual scheduler page 'DHX Scheduler (Project)' for the Job/Task."],
        ["Add Filter", "_ctxAddFilter -> OnGanttContextAddFilter", "Sets JobFilter/JobTaskFilter from the row (for a parent row, a 'min..max' Job Task No. range covering its subtree) and runs RefreshGantt; no dialog."],
        ["Cancel", "-", "Closes the menu."],
    ], [0.17, 0.3, 0.53], mono_cols=(1,), bold_first=True)
    h2(st, "12.2 Resource name menu (right-click a name in the resource grid)")
    table(st, ["Item", "Event", "Purpose"], [
        ["Resource Calendar", "onOpenResourceScheduler", "Asks which week of the current Gantt period (StrMenu 'W45: 02-11-2026 - 08-11-2026, ...') and opens 'Resource Scheduler - Calendar' for that resource and week."],
        ["Show Resource Card", "OnResourceDblClick", "Opens the Resource Card (only for RES- ids)."],
    ], [0.22, 0.25, 0.53], mono_cols=(1,), bold_first=True)
    h2(st, "12.3 Day marker menu (right-click a green/red/grey marker)")
    table(st, ["Item", "Event", "Purpose"], [
        ["Open Day Plannings", "OpenResourceLoadDay", "Opens 'Day Plannings' for that resource and day. Filters: Job/Task of the Day Plannings behind the marker (from the id list, if any), Plan Date = the day, and an **OR group** (FilterGroup(-1)) on Assigned Resource No. = X **or** Requested Resource No. = X (pool resources for VEN- ids). On close, the panel is refreshed only if the data changed (14.4)."],
        ["Open Sequences", "OpenSequences", "Opens 'Day Planning Sequence' for the Job Task of the first Day Planning, for the Gantt period, highlighting the sequence rows of every Day Planning behind the marker and the sibling Request/Assigned lines of the same resource and day. Modal; same conditional refresh on close."],
    ], [0.2, 0.2, 0.6], mono_cols=(1,), bold_first=True)
    note(st, "Why FilterGroup(-1)? In AL, filters on different fields inside group -1 are combined with OR, while all other groups are combined with AND. "
             "The marker may show a resource either as the **assigned** or as the **requested** one, so the Day Plannings behind it match when *either* field equals the resource. "
             "A plain SetRange on one field would hide the other half. FilterGroup(0) afterwards restores the normal group; the group -1 filters remain active (and are not visible in the page's filter pane).")
    h2(st, "12.4 Empty resource timeline cell menu")
    table(st, ["Item", "Event", "Purpose"], [
        ["Add Day Planning", "onAddDayPlanning", "Computes the clicked day (gantt.dateFromPos) and resource row from the mouse position. AL creates a new Day Planning in status 'In Request' for that resource/date (RES- validates the requested resource; VEN- the vendor), applies the Work-Hour Template (default times, non-working minutes, working hours), takes Job/Job Task from the panel filter, opens 'Day Planning Card - New Record' and on OK validates and inserts it, then reloads (RefreshGantt)."],
    ], [0.2, 0.2, 0.6], mono_cols=(1,), bold_first=True)
    h2(st, "12.5 Left click and double-click")
    table(st, ["Gesture", "Behaviour"], [
        ["Left click on a task bar", "Records `_lastClickedTaskId` and runs the same logic as 'Show Job Resources' (opens/refreshes the task-scoped panel). Ignored right after a drag and when the click is on the progress handle or a grid row."],
        ["Double-click on a task row/bar", "onTaskDblClick -> opens the Job Task card; DHTMLX lightbox is suppressed."],
        ["Double-click on a day marker", "OpenResourceLoadDay (same as 'Open Day Plannings')."],
        ["Double-click on a resource name", "OnResourceDblClick -> Resource Card."],
        ["Click on the collapse/expand icon", "Collapses or expands every task."],
        ["Drag a bar / its handles", "Move or resize the task, drag the progress handle, or drag from a bar end to another bar to create a link (section 13)."],
    ], [0.3, 0.7], bold_first=True)
