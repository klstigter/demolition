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
    Scripts = 'src\dhx\dhtmlxgantt.js',
              'src\dhx\ganttdemo2\wrapper.js';

    StyleSheets = 'src/dhx/dhtmlxgantt.css',
                  'src/dhx/ganttdemo2/style.css';

    StartupScript = 'src\dhx\ganttdemo2\startupScript.js';

    event ControlReady();
    event OnAfterInit();
    event onTaskDblClick(eventId: Text; eventData: Text);
    event onOpenDayTask(taskId: Text; eventData: Text);
    event onOpenDayTaskVisual(taskId: Text; eventData: Text);
    event OnJobTaskUpdated(eventData: Text);
    event OpenResourceLoadDay(resourceId: Text; workDate: Text);
    event OnLinkCreated(linkData: Text);
    event OnLinkDeleted(linkData: Text);
    event OnShowResourcesForTask(taskId: Text; childrenJson: Text; periodFrom: Text; periodTo: Text);
    event OnResourceDblClick(resourceId: Text);

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
    procedure LoadDayTasksData(dayTasksJsonTxt: Text);
    procedure ClearData();
    procedure RenderGantt();
    procedure GetGanttData();
    procedure SetResourcePanelVisibility(resource_toggle: Boolean);
    procedure UpsertLink(linkJsonTxt: Text);
    procedure DeleteLink(linkId: Text);
    procedure LoadLinksData(linksJsonTxt: Text);
}