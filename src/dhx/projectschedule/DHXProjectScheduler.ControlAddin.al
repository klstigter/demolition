controladdin DHXProjectScheduleAddin
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
        'src\dhx\dhtmlxscheduler.js',
        'src\dhx\GlobalFunction.js',
        'src\dhx\projectschedule\wrapper.js';

    StartupScript = 'src\dhx\projectschedule\startupScript.js';

    StyleSheets =
        'src\dhx\dhtmlxscheduler.css',
        'src\dhx\projectschedule\style.css';

    event ControlReady();

    procedure Init(elements: Text; EarliestPlanningDate: Date);
    procedure LoadData(EventTxt: Text);
}