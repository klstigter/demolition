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
    event OnEventDblClick(eventId: Text; eventData: Text);

    procedure LoadProject(projectstartdate: date; projectenddate: date);
    procedure Undo();
    procedure Redo();
    procedure AddMarker(datestr: Text; text: Text);
    procedure RefreshEventData(eventData: Text);


    procedure SetColumnVisibility(
        ShowStartDate: Boolean;
        ShowDuration: Boolean;
        ShowConstraintType: Boolean;
        ShowConstraintDate: Boolean;
        ShowTaskType: Boolean
    );
}