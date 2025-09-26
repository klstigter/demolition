controladdin DayPilotResourceAddIn
{
    RequestedHeight = 1500;
    MinimumHeight = 600;
    VerticalShrink = true;
    VerticalStretch = true;

    RequestedWidth = 1800;
    MinimumWidth = 700;
    HorizontalStretch = true;
    HorizontalShrink = true;

    Scripts =
        'src\daypilot\Resource\wrapper.js',
        'src\daypilot\GlobalFunction.js',
        'src\daypilot\daypilot-all.min.js';

    StartupScript = 'src\daypilot\Resource\startupScript.js';

    StyleSheets = 'src\daypilot\main.css';

    event ControlReady();

    procedure Init(StartDate: Text);
    procedure LoadData(resourcesJson: Text; eventsJson: Text; StartDate: Text; Days: Integer);
    procedure DisableCell(resourceId: Text; StartDateTimeStr: Text; EndDateTimeStr: Text)
}