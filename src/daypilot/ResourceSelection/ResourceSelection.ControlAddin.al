controladdin "ResourceSelectionAddIn"
{
    RequestedHeight = 350;
    MinimumHeight = 300;
    VerticalShrink = true;
    VerticalStretch = true;

    RequestedWidth = 700;
    MinimumWidth = 300;
    HorizontalStretch = true;
    HorizontalShrink = true;

    Scripts =
        'src\daypilot\ResourceSelection\wrapper.js',
        'src\daypilot\GlobalFunction.js',
        'src\daypilot\daypilot-all.min.js';

    StartupScript = 'src\daypilot\ResourceSelection\startupScript.js';

    StyleSheets = 'src\daypilot\main.css';

    event ResControlReady();
    event OnAfterInit();
    event onRowSelect();
    event onRowSelected(ResourcesJsonTxt: Text);

    procedure ResInit(StartDate: Text; StartDateTimeStr: Text; EndDateTimeStr: Text);
    procedure ResLoadData(resourcesJson: Text; eventsJson: Text; StartDate: Text; Days: Integer);
    procedure GetSelectedResources();
}