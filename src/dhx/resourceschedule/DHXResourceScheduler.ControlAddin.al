controladdin DHXResourceScheduleAddin
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
        'src\dhx\resourceschedule\wrapper.js';

    StartupScript = 'src\dhx\resourceschedule\startupScript.js';

    StyleSheets =
        'src\dhx\dhtmlxscheduler.css',
        'src\dhx\resourceschedule\style.css';

    event ControlReady();
    event OnAfterInit();
    event OnEventDoubleClick(EventId: Text; ResourceId: Text);

    procedure Init(elements: Text; EarliestPlanningDate: Date);
    procedure LoadData(EventTxt: Text);

}