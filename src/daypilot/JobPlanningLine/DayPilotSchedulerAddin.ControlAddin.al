controladdin "DayPilotSchedulerAddIn"
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
        'src\daypilot\JobPlanningLine\wrapper.js',
        'src\daypilot\GlobalFunction.js',
        'src\daypilot\daypilot-all.min.js';

    StartupScript = 'src\daypilot\JobPlanningLine\startupScript.js';

    StyleSheets = 'src\daypilot\main.css';

    event OnBookingChanged(bookingJson: Text);
    event OnBookingCreated(bookingJson: Text);
    event OnEventRightClicked(bookingJson: Text);
    event ControlReady();
    event OnAfterInit();
    event OnAfterEditDescription(bookingJson: Text);

    procedure Init(StartDate: Text);
    procedure LoadData(resourcesJson: Text; eventsJson: Text; StartDate: Text; Days: Integer);
    procedure OnBookingCreatedFeedback(bookingJson: Text);
    procedure deleteEventById(eventId: Text);
    procedure EditEventDescription(eventsJson: Text);
    procedure RefreshDayPilot();
    procedure DataCheck();
    procedure RemoveAllEvents();
}
