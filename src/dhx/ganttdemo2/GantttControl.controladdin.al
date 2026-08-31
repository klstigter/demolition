controladdin "DHX Gantt Control 2"
{
    RequestedHeight = 1500;
    MinimumHeight = 600;
    VerticalShrink = true;
    VerticalStretch = true;

    RequestedWidth = 1800;
    MinimumWidth = 700;
    HorizontalStretch = true;
    HorizontalShrink = true;
    Scripts = 'src/dhx/dhtmlxgantt.js',
              'src/dhx/ganttdemo2/wrapper.js';

    StyleSheets = 'src/dhx/dhtmlxgantt.css',
                  'src/dhx/ganttdemo2/style.css';

    StartupScript = 'src/dhx/ganttdemo2/startupScript.js';

    event ControlReady();
    event OnAfterInit();
    event onTaskDblClick(eventId: Text; eventData: Text);
    event onOpenDayPlanning(taskId: Text; eventData: Text);
    event onOpenDayPlanningVisual(taskId: Text; eventData: Text);
    event OnJobTaskUpdated(eventData: Text);
    event OpenResourceLoadDay(resourceId: Text; taskDate: Text; planStatus: Text; idList: Text);
    event OnLinkCreated(linkData: Text);
    event OnLinkDeleted(linkData: Text);
    event OnShowResourcesForTask(taskId: Text; childrenJson: Text; periodFrom: Text; periodTo: Text);
    event OnShowSummaryForTask(taskId: Text; childrenJson: Text; periodFrom: Text; periodTo: Text);
    event OnResourceDblClick(resourceId: Text);
    event onOpenResourceScheduler(resourceId: Text);
    event OnResetResourceFilter();
    event onAddDayPlanning(resourceId: Text; taskDate: Text);
    event OnResourceFilterRetrieved(filterJson: Text);
    event OnGanttFilterIconClick();
    event OnGanttClearTaskFilter();
    event OnGanttContextAddFilter(jobNo: Text; jobTaskNo: Text);
    // Added for the async resource-panel background-task pipeline (page 50620): live testing
    // confirmed BC Server rejects any CurrPage.DHXGanttControl2.<Method>() call issued directly
    // from OnPageBackgroundTaskCompleted/OnPageBackgroundTaskError ("attempted to issue a client
    // callback on an Automation object... not supported... disallowed callback was issued from
    // the OnPageBackgroundTaskCompleted or OnPageBackgroundTaskError trigger") - those triggers
    // may only touch plain AL data (Notifications included) once returned from the read-only
    // background session, never the control add-in directly. wrapper.js polls this event on a
    // light interval; the page's handler pushes any pending background-task result into the
    // control add-in from THIS normal, JS-initiated synchronous call instead - the same call
    // shape every other CurrPage.DHXGanttControl2.* call in this file already uses successfully.
    event OnPollResourcePanelResult();

    procedure LoadProject(projectstartdate: date; projectenddate: date);
    procedure Undo();
    procedure Redo();
    procedure AddMarker(datestr: Text; text: Text);
    procedure RefreshEventData(eventData: Text);
    procedure LoadProjectData(jsonText: Text);
    procedure SetColumnVisibility(
        ShowStartDate: Boolean;
        ShowDuration: Boolean;
        ShowTaskType: Boolean
    );
    procedure LoadResourcesData(resourcesJsonTxt: Text);
    procedure LoadDayPlanningsData(DayPlanningsJsonTxt: Text);
    procedure ClearData();
    procedure RenderGantt(skipTrigger_OnJobTaskUpdated: Boolean);
    procedure GetGanttData();
    procedure SetResourcePanelVisibility(resource_toggle: Boolean);
    procedure SetResourcePanelFilterInfo(jobNo: Text; taskNo: Text; periodFrom: Text; periodTo: Text);
    procedure ClearResourceFilter();
    procedure UpsertLink(linkJsonTxt: Text);
    procedure DeleteLink(linkId: Text);
    procedure LoadLinksData(linksJsonTxt: Text);
    procedure LoadHolidaysData(holidaysJsonTxt: Text);
    procedure GetResourceFilter();
    procedure SetGanttTaskFilterInfo(jobNo: Text; taskNo: Text; periodFrom: Text; periodTo: Text);
    procedure SetBarFontColor(fontColorHex: Text);
    procedure SetDayOffColors(weekendColorHex: Text; holidayColorHex: Text);
    // Companion to OnPollResourcePanelResult above - called right after every resource-panel
    // background task is enqueued (a normal synchronous AL call, not from the completion trigger)
    // so JS knows to (re)start its bounded poll loop instead of polling forever on every page.
    procedure NotifyResourcePanelTaskPending();
    // Called once a pending background-task result was actually delivered into the control
    // add-in, so JS can stop its poll burst early instead of waiting out the full timeout.
    procedure StopResourcePanelPolling();
}