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
        'src/dhx/dhtmlxscheduler.js',
        'src/dhx/GlobalFunction.js',
        'src/dhx/projectschedule/wrapper.js';

    StartupScript = 'src/dhx/projectschedule/startupScript.js';

    StyleSheets =
        'src/dhx/dhtmlxscheduler.css',
        'src/dhx/projectschedule/style.css';

    event ControlReady();
    event OnEventDblClick(eventId: Text; eventData: Text);
    event OnEventChanged(eventId: Text; eventData: Text);
    event OnAfterEventIdUpdated(oldid: Text; newid: Text);
    event onEventAdded(eventId: Text; eventData: Text);
    event OnDragCreateDayPlanning(sectionId: Text; startDateIso: Text; endDateIso: Text);
    event OnOpenResourcePage(lightboxId: Text; eventData: Text);
    event OnPlanningLineClick(Id: Text; EventJson: Text);
    event OnTimelineNavigate(NavigateJson: Text);
    event OnSectionDblClick(sectionId: Text; label: Text; viewdate: Text);
    event OnEventsNotMatch(EventIdsJsonTxt: Text);
    event OnGetAllEvents(EventIdsJsonTxt: Text);
    event OnGetAllSections(EventIdsJsonTxt: Text);
    event OnEventContextMenu(eventId: Text; action: Text; payloadJson: Text);
    event OnSectionContextMenu(sectionId: Text; action: Text; payloadJson: Text);
    event OnFilterIconClick();
    event OnClearTaskFilter();
    // JS-initiated poll asking "is a background-task result ready yet?" (see page 50621's
    // OnPollSectionsResult / EnqueueSectionsBackgroundTask, and codeunit "Task Scheduler BG
    // Sections") - a normal synchronous trigger call, so AL answering it with
    // CurrPage.DhxScheduler.AppendSections is safe, unlike from OnPageBackgroundTaskCompleted
    // itself. Same shape as ganttdemo2's OnPollResourcePanelResult.
    event OnPollSectionsResult();

    procedure Init(elements: Text; EarliestPlanningDate: Date);
    procedure LoadData(EventTxt: Text);
    procedure SetBarColors(colorsJson: Text);
    procedure SetSkillFontBorderColors(skillsJson: Text);
    procedure SetTimelineHourStep(hourStep: Integer);
    procedure SetTimelineHourRange(startHour: Integer; endHour: Integer);
    procedure UpdateEventId(EventIdsJsonTxt: Text);
    procedure SetLightboxEventValues(lightboxId: Text; ResourceId: Text; ResourceName: Text);
    procedure RefreshTimeline(resourcesJson: Text; eventsJson: Text; DateAnchor: Date);
    procedure RefreshEventData(eventData: Text);
    procedure SetDefaultTabsVisible(Visible: Boolean);
    procedure get_events_not_match_with_section();
    procedure getAllEvents();
    procedure getAllSections();
    procedure SetTaskFilterInfo(jobNo: Text; taskNo: Text; periodFrom: Text; periodTo: Text);
    // Appends a Page Background Task's remaining sections+events (Part B pagination) into the
    // already-rendered timeline in place - see wrapper.js's AppendSections, modeled on the
    // existing ToggleCollapseExpandAllSections in-place y_unit_original mutation pattern. Never
    // routes through RecreateTimelineView/Init/RefreshTimeline (those are full-reset paths).
    procedure AppendSections(sectionsJson: Text; eventsJson: Text);
    // Companion to OnPollSectionsResult above - called right after every sections background task
    // is enqueued (a normal synchronous AL call, not from the completion trigger) so JS knows to
    // (re)start its bounded poll loop instead of polling forever on every page. Same shape as
    // ganttdemo2's NotifyResourcePanelTaskPending.
    procedure NotifySectionsTaskPending();
    // Called once a pending background-task result was actually delivered into the control
    // add-in, so JS can stop its poll burst early instead of waiting out the full timeout.
    procedure StopSectionsPolling();
}