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
    event OnResourceDoubleClick(ResourceId: Text);
    event OnDateRangeChanged(StartDate: Text; EndDate: Text);
    event OnEventContextMenu(EventId: Text; action: Text; PeriodStart: Text; PeriodEnd: Text; payloadJson: Text);
    event OnResourceContextMenu(ResourceId: Text; action: Text; PeriodStart: Text; PeriodEnd: Text; payloadJson: Text);

    procedure Init(elements: Text; EarliestPlanningDate: Date);
    procedure LoadData(EventTxt: Text);
    procedure LoadCapacity(CapacityTxt: Text);
    procedure ReloadData(EventTxt: Text; CapacityTxt: Text);
    procedure SetShowDayTask(pShow: Boolean);
    procedure SetShowCapacity(pShow: Boolean);

}