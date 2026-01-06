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
    event OnEventDblClick(eventId: Text; eventData: Text);
    event OnEventChanged(eventId: Text; eventData: Text);
    event OnAfterEventIdUpdated(oldid: Text; newid: Text);
    event onEventAdded(eventId: Text; eventData: Text);
    event OnOpenResourcePage(lightboxId: Text; eventData: Text);
    event OnPlanningLineClick(Id: Text; EventJson: Text);
    event OnTimelineNavigate(NavigateJson: Text);
    event OnSectionDblClick(sectionId: Text; label: Text; viewdate: Text);

    procedure Init(elements: Text; EarliestPlanningDate: Date);
    procedure LoadData(EventTxt: Text);
    procedure UpdateEventId(EventIdsJsonTxt: Text);
    procedure SetLightboxEventValues(lightboxId: Text; ResourceId: Text; ResourceName: Text);
    procedure RefreshTimeline(resourcesJson: Text; eventsJson: Text; DateAnchor: Date);
    procedure RefreshEventData(eventData: Text);
    procedure SetDefaultTabsVisible(Visible: Boolean);
}