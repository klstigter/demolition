from .lib import *


def build(st):
    # ------------------------------------------------------------------ 13
    h1(st, "13. Editing flows: from the browser back into Business Central")
    h2(st, "13.1 Dragging or resizing a task bar")
    p(st, "Dragging moves the whole task (Scenario: shift), dragging the right edge changes the end, the left edge changes the start. Non-Posting (heading) rows are read-only.")
    numbered(st, [
        "JS `onAfterTaskDrag`: blocks follow-up update events for 300 ms, normalises start_date, repaints, and raises **OnJobTaskUpdated** with the JSON payload (end_date is DHTMLX's exclusive end).",
        "AL trigger `OnJobTaskUpdated` calls `Gantt Update Data.UpdateJobTaskFromJson`. It reads the Job Task, captures the old Visual Bar Start/End, then applies each field: text (the 'TaskNo - ' prefix is stripped), start_date, end_date (**minus one day**), duration, schedulingType.",
        "If the end date changed it is **snapped forward to the next working day** (`SnapForwardToWorkDay`: Work-Hour Template + Base Calendar) so a bar can never end on a weekend/holiday.",
        "If the period changed, `HandleJobTaskPeriodChange` -> `CalculateChanges` works out which Day Plannings must move, and opens the **'DayPlanning Period Sync Preview'** page. Nothing is written until the user clicks **Apply Changes**.",
        "On Apply, `ApplyChanges` extends the Job Task end if a cascade overshoots, `JobTask.Modify`, moves or inserts Day Plannings, and `Commit`s. The page then reloads tasks + links + the resource panel and calls `RenderGantt(true)`.",
        "If the user closes the preview without applying, the page offers a Confirm: update **only** the Job Task planned dates (`TryApplyPlannedDatesOnly`, no Day Planning is touched) or revert the bar. Either way the page reloads so the bar returns to the true server position.",
    ])
    h3(st, "Period-sync scenarios (codeunit 50617 CalculateChanges)")
    table(st, ["Scenario", "Condition", "Effect on Day Plannings"], [
        ["1.1 Shift left/right", "OldStart <> NewStart and OldEnd <> NewEnd", "Every Day Planning moves by the same offset; active-day rules and collisions are resolved forward-only."],
        ["1.2 Right bar change", "Start same, End changed", "Enlarged: new entries for new active days. Reduced: overflowing rows are moved to the nearest free active day, backward from the new end."],
        ["1.3 Left bar change", "Start changed, End same", "Mirror of 1.2 (forward from the new start)."],
    ], [0.2, 0.3, 0.5], bold_first=True)
    p(st, "Active days come from the Job Task's Work-Hour Template (else the setup's template) and the Base Calendar (mandatory). Resources with a matching 'Day Planning Pattern' are redistributed onto the pattern's active days; others use the naive offset + forward cascade. Rows are reused (Plan Date only), never deleted/recreated.")
    h2(st, "13.2 Inline cell edit and lightbox")
    p(st, "Editing the text, start date, duration, progress or constraint cells (or the lightbox) fires `onAfterTaskUpdate`, which raises the same **OnJobTaskUpdated** event and follows the same path. "
          "Events caused by data loads (`_reloadInProgress`) or by drag cascades (`_dragInProgress`) are ignored so BC is not called for changes that came from BC itself.")
    h2(st, "13.3 Dependency links")
    bullets(st, [
        "Drawing a link between two bars raises OnLinkCreated; AL `UpsertLinkFromJson` stores it in table 'BCG Gantt Task Link' (key Job No., Source, Target, Link Type) with Lag (Days). Cross-job links and self-links are rejected (the page shows 'Failed to save link').",
        "Deleting an arrow raises OnLinkDeleted; AL `DeleteLinkFromJson` deletes the record.",
        "Links are loaded for the Job filter (or all jobs when none) on every refresh and always sent, even as '[]', so removed arrows disappear.",
    ])
    h2(st, "13.4 Add Day Planning, Undo, Redo, Add Marker")
    bullets(st, [
        "**Add Day Planning** (empty resource cell menu): see 12.4. On success it ends with a full `RefreshGantt()`.",
        "**Undo / Redo** (ribbon): call `gantt.undo()` / `gantt.redo()` on the DHTMLX undo stack (the undo plugin is enabled). Behaviour is DHTMLX's; it was not separately verified against BC persistence.",
        "**Add Marker**: adds a vertical marker via `AddMarker(date, text)`. The ribbon action currently passes a fixed demo value ('2024-06-15', 'New Marker').",
    ])

    # ------------------------------------------------------------------ 14
    h1(st, "14. Refresh and navigation: Refresh Data, Previous, Today, Next")
    h2(st, "14.1 RefreshGantt - the full reload")
    code(st, """
procedure RefreshGantt()
begin
    CurrPage.DHXGanttControl2.ClearData();   // JS: _isRefreshing := true; clear indexes, stores, tasks, links
    Setup.Get(UserId);                       // pick up Gantt Settings changes
    LoadAllData();                           // section 4.2 ... ends with RenderGantt(false)
end;""")
    p(st, "In JS, `ClearData` refuses to run twice in parallel (`_isRefreshing`). While the flag is set, `LoadResourcesData`/`LoadDayPlanningsData` only fill the stores and skip their own render. "
          "`RenderGantt` is the single paint: it calls `store.refresh()` (forces bound views to re-read), `gantt.render()`, `_restoreTaskFocusAfterReload()` (showTask/selectTask on the last clicked task), then clears `_isRefreshing` and hides the overlay.")
    h2(st, "14.2 Previous / Today / Next")
    p(st, "These three actions are visible only when `ShowPreviousNext` is true, i.e. when the Date Range Type is **not** the fixed 'Date Range'. They only change **AnchorDate** and then call `RefreshGantt()`:")
    table(st, ["Action", "New AnchorDate", "Notes"], [
        ["Today", "Today()", "Re-centres the window on the current date."],
        ["Previous", "Weekly: AnchorDate - 5 weeks. Calculated: AnchorDate - (length of the window in days).", "Step equals the window width, so windows tile with no gap or overlap."],
        ["Next", "Weekly: + 5 weeks. Calculated: + window length.", "Window length = (To formula date - From formula date + 1), from GetPeriodLength."],
    ], [0.15, 0.5, 0.35], bold_first=True)
    p(st, "What shifts with the window: the time scale (`LoadProject` resets project_start/end), the task query (only tasks overlapping the new window are loaded), holidays, links, "
          "and the resource panel (the panel period follows the displayed period; a task-scoped panel is rebuilt for the new period, and a default panel reloads for the new window). "
          "Because the window changes on every click, `schedule_on_parse` is disabled so loading never auto-schedules tasks against a moving boundary. "
          "Right and left movement in the *timeline* itself (horizontal scrollbar) does not call AL: the whole window is already loaded.")
    h2(st, "14.3 Everything that triggers a full RefreshGantt")
    table(st, ["Trigger", "Why a full reload"], [
        ["Refresh Data, Today, Previous, Next", "New data window or user request."],
        ["Gantt Settings closed (RunModal)", "Reload with the saved settings (period, loads, columns, filter)."],
        ["Funnel filter applied/cleared, 'Add Filter'", "Task query changes."],
        ["Add Day Planning saved", "New row added (still a full reload)."],
        ["Task drag (OnJobTaskUpdated)", "Not RefreshGantt: reloads tasks + links + resource panel and RenderGantt(true) (13.1)."],
        ["Day Plannings / Sequences closed", "Not RefreshGantt any more (14.4)."],
    ], [0.38, 0.62], bold_first=False)
    h2(st, "14.4 After the Day Plannings / Sequences page is closed")
    p(st, "Previously both flows ended with a full `RefreshGantt()` (about 3.2 s on the test data) even when nothing changed. Now:")
    numbered(st, [
        "Before opening the sub page, AL takes a **fingerprint**: the number of Day Plannings in the visible window (plus undated requests) and their latest `SystemModifiedAt` (`GetDayPlanningFingerprint`).",
        "After the page closes, `RefreshResourcePanelIfChanged` takes it again. **Unchanged: nothing is sent and nothing is rendered.**",
        "Changed, Default-mode panel, no chunk load running: `GetChangedDayPlanningsAsJson` returns only the records modified after the old timestamp (and their resources) provided that `BeforeCount + created = AfterCount`; the JS `ApplyDayPlanningChanges` patches the store and the two indexes and renders **once**.",
        "Otherwise (a delete, a record moved in/out of the period, a task-scoped panel, a chunk chain still running): the resource panel alone is reloaded (stored-filter reload or default reload). Tasks, links and holidays are never reloaded.",
    ])
    table(st, ["Measured (834 Day Plannings, NL_Test)", "Before", "After"], [
        ["Close with no change", "about 3.2 s (full reload)", "no work"],
        ["Close after editing one Day Planning", "about 3.2 s", "about 0.35 - 0.46 s"],
        ["Result check", "-", "store, task index, request set and resource count identical to a full Refresh Data (0 differences)"],
    ], [0.45, 0.25, 0.3], bold_first=False)

    # ------------------------------------------------------------------ 15
    h1(st, "15. Gantt Settings and what each setting changes")
    p(st, "Action **Gantt Settings** opens page 50650 (card on table 50620 'Gantt Chart Setup', one row per user, created on first use) modally. When it closes, the page runs `RefreshGantt()`, so every change is visible immediately.")
    table(st, ["Setting", "Effect on the Gantt"], [
        ["Job No. Filter", "Default Job filter for tasks, links and Day Plannings (overridden by the page-level filter from the funnel / Add Filter). Blank = all jobs."],
        ["Date Range Type = Date Range", "Fixed window From Date..To Date. Previous/Today/Next are hidden."],
        ["Date Range Type = Calculated", "Window = CalcDate(From Date Formula, Anchor) .. CalcDate(To Date Formula, Anchor). Default '-CW' .. 'CW+4W'. Navigation steps by the window length."],
        ["Date Range Type = Weekly", "Anchor's week plus 4 more weeks (5 weeks). Navigation steps 5 weeks."],
        ["Load Job Tasks", "When off, LoadTaskData is skipped: no task bars (links and panel still follow their own flags)."],
        ["Load Resources", "Passed as pLoadResources to the default panel reload (resource rows)."],
        ["Load Day Plannings", "Passed as pLoadDayPlannings to the default panel reload (markers and request overlays)."],
        ["Show Start Date / Show Duration / Show Task Type", "Grid column switches sent via SetColumnVisibility. See the argument-mapping caveat in section 17."],
        ["Download Data for Inspection", "After loading tasks, offers to download the task JSON (GanttProjectTaskData.json) for troubleshooting."],
    ], [0.3, 0.7], bold_first=True)
    h2(st, "15.1 Company-wide visual settings (Daily Optimizer Setup)")
    p(st, "These are not in the Gantt Settings page but are re-applied on every LoadAllData, so a change takes effect on the next refresh:")
    table(st, ["Setting (via codeunit 50609 getters)", "JS call", "Effect"], [
        ["Bar Font Color / GTB Font Color", "SetBarFontColor, SetGanttTaskBarDefaults", "Text colour of on-bar labels (CSS --bar-font-color)."],
        ["Weekend Color / Holiday Color", "SetDayOffColors", "Shading of weekend and holiday columns."],
        ["GTB Color / GTB Color (non posting)", "task JSON 'color'", "Fill of Posting vs heading bars."],
        ["GTB Border Color / Progress Color / Font Size / Height", "SetGanttTaskBarDefaults", "Bar border, progress fill (blank = auto darker), label size, bar height (gantt.config.task_height)."],
        ["Tooltip Background / Font Color", "SetTooltipColors", "All hover popups."],
        ["Base Calendar", "LoadHolidaysData", "Non-working days shaded as holidays; also used by period sync."],
        ["Work hour Template", "-", "Default times for Add Day Planning and active days for period sync."],
    ], [0.34, 0.26, 0.4], bold_first=False)

    # ------------------------------------------------------------------ 16
    h1(st, "16. Page 50620 actions: purpose of every menu entry")
    p(st, "The ribbon is built from `area(Processing)`, `area(Navigation)`, `area(Reporting)` and the `area(Promoted)` layout. Direct promoted entries are flat buttons; the others are grouped as **Export**, **Related**, **Check**, **Reports**.")
    table(st, ["Action (caption)", "Group", "What it does"], [
        ["Gantt Settings", "flat", "Opens the Gantt Settings card modally, then RefreshGantt()."],
        ["Undo / Redo", "flat", "gantt.undo() / gantt.redo()."],
        ["Add Marker", "flat", "Adds a vertical marker (fixed demo date/text)."],
        ["Clear Gantt Data", "flat", "Calls ClearData(): empties tasks, links and stores in the browser (no reload; use Refresh Data to bring data back)."],
        ["Refresh Data", "flat", "RefreshGantt(): full reload of the current window."],
        ["Previous / Today / Next", "flat", "Move AnchorDate and reload (section 14.2). Hidden for a fixed 'Date Range'."],
        ["Get JSON Tasks / Resources / Day Plannings Data", "Export", "Download the corresponding JSON payload as a file (same builders as the Gantt uses) - useful to inspect what is sent to the add-in."],
        ["Summary", "Related", "Opens 'Summary View' for the visible period."],
        ["Day Plannings", "Related", "Opens 'Day Plannings' for the visible period; when a task-scoped resource panel is active it uses that Job/Task/period, otherwise the Job filter."],
        ["Projects", "Related", "Opens 'Opti Job List' filtered by the Job filter."],
        ["Project Tasks", "Related", "Opens 'Job Task List - Project' for tasks overlapping the window (excluding Total/End-Total), filtered by the Job filter."],
        ["Show Resource Panel / Hide Resource Panel", "Related", "Show: sets ResourcePanelFlag, shows the (empty) panel, clears any task scope and loads the default panel. Hide: hides the panel (no data is discarded)."],
        ["Check Gantt Data", "Check", "JS alert with project_start/project_end (diagnostic)."],
        ["Check Page Period", "Check", "Message with the computed start/end for the anchor date."],
        ["Check Resource Panel Filter", "Check", "Fetches the JS-side filter and shows its JSON."],
        ["Show Resources for Task", "hidden", "Placeholder; the real work is done by the right-click event OnShowResourcesForTask."],
        ["Day Resource Detail", "Reports", "Report 'Day Resource Details' for the visible period."],
        ["Day Overview", "Reports", "Report 'Day Planning Details' for the visible period."],
        ["Week Overview", "Reports", "Report 'DayPlanning' (week overview) for the visible period."],
        ["Daily Capacity Balance Report", "Reports", "Report 'Daily Capacity Balance Report' for the visible period."],
    ], [0.3, 0.1, 0.6], bold_first=True)
    h2(st, "16.1 Other interactions that are not ribbon actions")
    bullets(st, [
        "**Funnel filter / (x)** in the 'Task name' header: filter dialog ('Task Scheduler Filter' report page, Job No. and Job Task No.) / clear.",
        "**Collapse/expand all** icon in the 'Task name' header.",
        "**Red (x) in the resource header**: reset the task scope and reload the unfiltered panel.",
        "**Hover**: task tooltip, link tooltip, marker tooltip, resource statistics.",
        "**Resizers** between task and resource panels and between grid and timeline (the filter buttons self-heal after a resize).",
    ])

    # ------------------------------------------------------------------ 17
    h1(st, "17. Known quirks and observations")
    p(st, "Found while reading the code; none of them were changed as part of this document. They are listed so maintainers are not surprised.")
    table(st, ["Observation", "Detail / consequence"], [
        ["SetColumnVisibility argument mismatch", "The AL procedure declares 3 parameters (ShowStartDate, ShowDuration, ShowTaskType) but the JS function takes 5 (start, duration, constraint type, constraint date, task type). With 3 arguments the third value lands on 'constraint type' and the last two are undefined, which hides the 'Task Type' and 'constraint date' columns. Align the signatures if the 'Show Task Type' switch is expected to control the Task Type column."],
        ["RefreshEventData has no JS implementation", "Declared in the add-in and called from onTaskDblClick only when `PossibleChanges` is true, but that variable is never set, so the branch is dead code."],
        ["OnProjectDataLoaded is not a declared event", "LoadProjectData calls InvokeExtensibilityMethod('OnProjectDataLoaded', ...) although the add-in declares no such event; the call has no AL handler."],
        ["Unused JS helpers", "UpsertTask, DeleteTask, UpsertDayPlanning, DeleteDayPlanning, highlightDayPlanning exist in wrapper.js but are not declared as add-in procedures, so AL cannot call them (UpsertDayPlanning is superseded by ApplyDayPlanningChanges)."],
        ["Leftover `debugger;` statements", "onAfterTaskDrag and onAfterTaskUpdate contain `debugger;` lines, which pause execution if the browser dev tools are open."],
        ["Legacy AL procedure OnJobTaskUpdated", "A page procedure of the same name as the trigger exists at the end of the page file (older direct JobTask update); the trigger is the live path."],
        ["Add Marker uses fixed values", "The ribbon action always adds '2024-06-15' / 'New Marker'."],
        ["Add Day Planning refreshes everything", "onAddDayPlanning still ends with RefreshGantt() instead of an incremental update."],
        ["Total Hours vs cell hours", "The grid total includes Request hours; the day cells exclude them (10.4)."],
        ["Unassigned work", "Day Plannings with no resource are grouped under the '- NONE -' row (resource id 'RES-')."],
    ], [0.3, 0.7], bold_first=True)

    # ------------------------------------------------------------------ 18
    h1(st, "18. Performance design and measurements")
    h2(st, "18.1 What was optimised")
    bullets(st, [
        "**No full reload after Day Planning sub pages**: fingerprint + incremental patch (14.4).",
        "**First chunk synchronous**: avoids the ~0.8 s background-task start-up and poll latency; only later chunks use the background task.",
        "**Keyset paging**: each chunk resumes from the last primary key instead of re-scanning all rows (the old Skip method was O(n) per chunk, O(n squared) overall). Chunk size 5000.",
        "**Parse each chunk once, render once**: the old code re-parsed the whole accumulated array on every chunk and called gantt.render() per chunk.",
        "**First poll after 400 ms** instead of 1.5 s.",
        "**Filtered panel built in the page**: scope is small, so no background task.",
    ])
    h2(st, "18.2 Measured on the NL_Test sandbox (834 Day Plannings, 118 resources)")
    table(st, ["Operation", "Before", "After"], [
        ["Close Day Plannings, no change", "~3.2 s", "0 (nothing sent)"],
        ["Close Day Plannings, one record edited", "~3.2 s", "~0.35 - 0.46 s"],
        ["Right-click task > Show Job Resources", "~0.94 s", "~0.35 s"],
        ["Reset to the full panel", "~1.7 s", "~1.0 s"],
        ["Server time to build 834 Day Plannings", "-", "~58 ms (22 ms resources)"],
        ["Client gantt.render() with the panel", "-", "~26 ms"],
        ["Fixed cost per background chunk (9 chunks of ~100 rows)", "-", "~0.6 s each (so use large chunks)"],
    ], [0.5, 0.2, 0.3], bold_first=False)
    h2(st, "18.3 Remaining hot spots to watch with large data")
    bullets(st, [
        "**Payload size**: about 610 bytes per Day Planning (fields are partly duplicated, e.g. start_time and assigned_start_time). At tens of thousands of records the transfer dominates; trimming fields would help but wrapper.js reads many of them.",
        "**renderResourceLine** loops over *all* Day Plannings for every resource cell (several nested scans per cell). Cost grows with resources x days x Day Plannings. An index by resource and date (built once per render) would make it linear.",
        "**'Total Hours' column** also scans all Day Plannings per resource row.",
        "**Marker tooltip** scans DayPlanningsByTask on every mouse move over a marker.",
        "**Full RefreshGantt** remains the cost of Refresh Data, Previous/Next/Today, filter changes and Add Day Planning.",
    ])

    # ------------------------------------------------------------------ 19
    h1(st, "Appendix A. wrapper.js function index")
    p(st, "Line numbers are approximate (they shift as the file changes). 'Nested' functions live inside BOOT().")
    A = [
        ["_resourcePanelInvokeStart / End", "36 / 41", "Acquire/release the single in-flight slot for panel round trips."],
        ["_createLoadingOverlay / _showGanttLoading / _hideGanttLoading", "69 / 114 / 124", "Build, show (with 180 s safety timer) and hide the LOADING overlay."],
        ["BOOT", "132", "One-time initialisation (section 6)."],
        ["InstallResourceMarkerCustomTooltipsForDayPlannings (nested)", "198", "Marker hover tooltip table."],
        ["InstallResourceGridDblClick (nested)", "327", "Resource name double-click -> OnResourceDblClick."],
        ["InstallResourceNameHoverTooltip (nested)", "345", "Resource statistics tooltip with 30 s cache; defines window.SetResourceStats."],
        ["InstallResourceGridContextMenu (nested)", "396", "Resource name / marker / empty-cell context menus."],
        ["_showContextMenu / _hideContextMenu (nested)", "949 / 1005", "Task context menu build/close."],
        ["_ctxOpenTask, _ctxShowSummary, _ctxShowResources, _ctxOpenDayPlanning, _ctxOpenDayPlanningVisual, _ctxAddFilter (nested)", "1032-1178", "Menu item handlers; each builds its argument JSON and calls InvokeExtensibilityMethod."],
        ["_stripJobTaskNoPrefix / _findRootAncestorTask (nested)", "866 / 876", "Tooltip helpers (task description without 'No - ', job description = root ancestor)."],
        ["_renderRequestBars", "1664", "Draw black overlay bars for Request Day Plannings with a placeholder date."],
        ["RecreateGanttLayout", "1722", "Layout with/without the resource panel; resetLayout; restore focus."],
        ["LoadProject", "1827", "Set window and auto-scheduling config; show overlay."],
        ["RenderGantt", "1884", "Final render of a reload cycle."],
        ["_restoreTaskFocusAfterReload", "1939", "showTask/selectTask on the last clicked task."],
        ["SetColumnVisibility / _applyColumnSettings / _setColumnHidden", "1972-1993", "Apply column switches (queued until init)."],
        ["Undo / Redo / ToggleCollapseExpandAll / AddMarker", "2007-2024", "Simple actions."],
        ["_tryParseJson / _normalizeId", "2041 / 2054", "Safe JSON parse; id extraction tolerant of key names."],
        ["_normalizeTaskBarDates", "2112", "start_date to midnight (end_date untouched)."],
        ["_darkenHex", "2121", "Darker shade for progress colour (hex, rgb or any CSS colour via canvas)."],
        ["_toGanttDate / _applyTaskPatch", "2162 / 2187", "Date conversion; partial task update."],
        ["ClearData", "2210", "Begin full reload."],
        ["LoadProjectData", "2243", "Load tasks (silent)."],
        ["UpsertTask / DeleteTask / UpsertLink / DeleteLink", "2343-2449", "Single-item patch helpers (links only are in the add-in contract)."],
        ["LoadLinksData", "2466", "Load all links."],
        ["calculateResourceLoad", "2496", "Hours per resource per working day (Requests excluded)."],
        ["renderResourceLine", "2530", "Custom resource timeline row renderer (10.4)."],
        ["LoadResourcesData", "2729", "Replace resource rows."],
        ["LoadDayPlanningsData", "2777", "Chunk-aware Day Planning load."],
        ["NotifyResourcePanelTaskPending / _scheduleResourcePanelPoll / _runResourcePanelPoll / StopResourcePanelPolling", "2880-2950", "Poll loop (section 11)."],
        ["UpsertDayPlanning / ApplyDayPlanningChanges / DeleteDayPlanning", "2952-3070", "Single patch / incremental batch patch / delete."],
        ["highlightDayPlanning", "3121", "Legacy selection highlight (unused)."],
        ["_ensureCustomTooltip / _showCustomTooltip / _hideCustomTooltip / _hideAllTooltips", "3129-3196", "Shared body-level tooltip."],
        ["GetGanttData", "3198", "Diagnostic alert."],
        ["SetResourcePanelVisibility", "3202", "Layout toggle."],
        ["SetResourcePanelFilterInfo / GetResourceFilter / ClearResourceFilter", "3221-3241", "Panel filter state."],
        ["_updateResourceHeaderTooltip / _positionResFilterTooltip", "3243 / 3331", "(i) and (x) buttons and popup."],
        ["SetGanttTaskFilterInfo", "3357", "Task-list filter state."],
        ["SetBarFontColor / SetDayOffColors / SetGanttTaskBarDefaults / SetTooltipColors", "3377-3438", "Visual settings."],
        ["_installGanttFilterToolbarWatcher / _updateGanttFilterToolbar / _positionGanttFilterTooltip / _escHtml", "3457-3606", "Funnel/(x) buttons, MutationObserver self-heal, helpers."],
        ["LoadHolidaysData", "3618", "Holiday map + re-render."],
    ]
    table(st, ["Function", "Line", "Purpose"], A, [0.45, 0.1, 0.45], mono_cols=(0,), bold_first=False)

    h1(st, "Appendix B. Page 50620 procedures and triggers")
    table(st, ["Name", "Kind", "Purpose"], [
        ["OnOpenPage", "page trigger", "Load setup, AnchorDate := Today, ShowPreviousNext."],
        ["ControlReady / OnAfterInit", "add-in trigger", "Start the first load (panel hidden)."],
        ["OnPageBackgroundTaskCompleted / OnPageBackgroundTaskError", "page trigger", "Stash background results / show a Notification on failure."],
        ["RefreshGantt", "procedure", "Full reload (14.1)."],
        ["SetJobFilter / SetJobTaskFilter", "procedure", "Let other pages open the Gantt pre-filtered."],
        ["LoadAllData", "local", "The load sequence (4.2)."],
        ["LoadTaskData / LoadLinkData / LoadHolidaysData / LoadDayPlanningData", "local", "One-call wrappers around the data handler + add-in call."],
        ["EnqueueFilteredResourcePanelReload", "local", "Task-scoped panel, built synchronously."],
        ["EnqueueDefaultResourcePanelReload", "local", "Default panel: chunk 0 synchronous, rest queued."],
        ["EnqueueNextDefaultResourcePanelDayPlanningChunk", "local", "Queue chunk N via cursor."],
        ["ReloadResourcePanelFromStoredFilter", "local", "Re-derive the period and reload the task-scoped panel (uses native vars)."],
        ["BuildResourcePanelJobTaskKeysText", "local", "';' separated 'JobNo|JobTaskNo' list for the scope."],
        ["GetDayPlanningFingerprint / RefreshResourcePanelIfChanged", "local", "Change detection and conditional incremental refresh (14.4)."],
        ["ClearResourcePanelFilter", "local", "Reset scope variables and the JS filter."],
        ["CalcNewAnchorDate", "local", "Previous/Next anchor maths."],
        ["TryValidateRequestedResourceNo", "TryFunction", "Friendly error for Add Day Planning."],
        ["ParseDate / OnJobTaskUpdated (procedure)", "local / legacy", "ISO date parser; legacy direct update."],
        ["ResourcePanelDayPlanningChunkPageSize / BoolToParamText", "local", "Chunk size (5000) / 'true' & 'false' text (Format(Boolean) would give localised Yes/No)."],
    ], [0.46, 0.14, 0.4], mono_cols=(0,), bold_first=False)

    h1(st, "Appendix C. Troubleshooting guide")
    table(st, ["Symptom", "Where to look"], [
        ["Gantt stays on LOADING", "A JS error before RenderGantt; the overlay hides itself after 180 s. Open dev tools console and look for 'LoadProjectData failed' or 'BOOT warning'."],
        ["'Working on it...' never clears", "Two panel round trips overlapped. Check `_resourcePanelInvokeInFlight` and that every InvokeExtensibilityMethod for the panel uses the 5-argument callback form."],
        ["Resource panel empty after refresh", "Panel scope variables (ResourcePanelJobNo/TaskNo) vs flag; a background task result discarded by TaskId; Setup 'Load Resources/Day Plannings' off."],
        ["Bars shifted by one day", "Exclusive vs inclusive end date (9.2); check end_date handling and `_normalizeTaskBarDates`."],
        ["Bars jump to the window start on load", "auto_scheduling.schedule_on_parse must be false (LoadProject)."],
        ["Task update fires twice / popup loops", "`_dragInProgress` / `_reloadInProgress` / `skipTrigger_OnJobTaskUpdated` / `PreviewCancelled` guards."],
        ["Filter buttons disappear after resizing", "MutationObserver watcher; check it is installed (`_ganttFilterToolbarWatcherInstalled`)."],
        ["Marker tooltip shows 'No DayPlannings'", "DayPlanningsByTask not rebuilt (first chunk not delivered) or the Day Plannings are Request rows with placeholder dates."],
        ["Slow after closing Day Plannings", "Fingerprint changed and the fallback path ran (delete/move) - check the count rule in GetChangedDayPlanningsAsJson."],
        ["Columns do not match Gantt Settings", "SetColumnVisibility argument mismatch (section 17)."],
    ], [0.3, 0.7], bold_first=True)

    h1(st, "Appendix D. Glossary")
    table(st, ["Term", "Meaning"], [
        ["Control add-in", "A BC extension point that hosts custom HTML/JS in an iframe on a page."],
        ["DHTMLX Gantt", "Third-party JavaScript Gantt component (dhtmlxgantt.js)."],
        ["Datastore", "DHTMLX data container (resourcesStore, DayPlanningsStore) that views can be bound to."],
        ["Layout / view", "DHTMLX layout tree of grid, timeline, scrollbar and resizer views."],
        ["Task panel / resource panel", "Upper task grid+timeline / lower resource grid+timeline."],
        ["Day Planning", "BC record: a planned (requested or assigned) resource block on a date for a Job Task."],
        ["Request (grey/black)", "Day Planning in status 'In Request'; shown grey, excluded from the day load, and as a black bar when it shares a day with planned work or has a placeholder date."],
        ["AnchorDate", "Page variable the visible window is calculated from."],
        ["Fingerprint", "Count + latest SystemModifiedAt used to detect changes after a sub page closes."],
        ["Keyset cursor", "'pass|JobNo|JobTaskNo|DayLineNo' - where the next chunk resumes."],
        ["Page Background Task", "BC mechanism running a codeunit in a separate read-only session and returning a result dictionary."],
        ["FilterGroup(-1)", "AL filter group whose field filters are combined with OR."],
    ], [0.25, 0.75], bold_first=True)
