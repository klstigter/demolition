controladdin DHXResourceCapacityScheduleAddin
{
    RequestedHeight = 1500;
    MinimumHeight = 600;
    VerticalShrink = true;
    VerticalStretch = true;

    RequestedWidth = 1800;
    MinimumWidth = 700;
    HorizontalStretch = true;
    HorizontalShrink = true;

    // Shared libs reused as-is (same convention as poolresourceschedule/projectschedule) -
    // only wrapper.js/style.css/startupScript.js are specific to this new add-in.
    Scripts =
        'src/dhx/dhtmlxscheduler.js',
        'src/dhx/GlobalFunction.js',
        'src/dhx/resourceschedule_with_capacity/wrapper.js';

    StartupScript = 'src/dhx/resourceschedule_with_capacity/startupScript.js';

    StyleSheets =
        'src/dhx/dhtmlxscheduler.css',
        'src/dhx/resourceschedule_with_capacity/style.css';

    event ControlReady();
    event OnAfterInit();
    event OnEventDblClick(eventId: Text; eventData: Text);
    event OnSectionDblClick(sectionId: Text; label: Text; viewdate: Text);
    event OnTimelineNavigate(NavigateJson: Text);
    event OnEventsNotMatch(EventIdsJsonTxt: Text);
    event OnGetAllEvents(EventIdsJsonTxt: Text);
    event OnGetAllSections(EventIdsJsonTxt: Text);
    event OnEventContextMenu(eventId: Text; action: Text; payloadJson: Text);
    event OnSectionContextMenu(sectionId: Text; action: Text; payloadJson: Text);
    event OnFilterIconClick();
    event OnClearResourceFilter();

    procedure Init(elements: Text; EarliestPlanningDate: Date);
    procedure SetBarColors(colorsJson: Text);
    procedure SetTimelineHourStep(hourStep: Integer);
    procedure SetTimelineHourRange(startHour: Integer; endHour: Integer);
    procedure LoadData(EventTxt: Text);
    procedure LoadCapacity(CapacityTxt: Text);
    procedure RefreshTimeline(resourcesJson: Text; eventsJson: Text; capacityJson: Text; DateAnchor: Date);
    procedure SetShowDayPlanning(pShow: Boolean);
    procedure SetShowCapacity(pShow: Boolean);
    procedure SetHideNoEventResources(pHide: Boolean);
    procedure get_events_not_match_with_section();
    procedure getAllEvents();
    procedure getAllSections();
    procedure SetResourceFilterInfo(resNo: Text; resName: Text; periodFrom: Text; periodTo: Text; skillFilter: Text);
}
