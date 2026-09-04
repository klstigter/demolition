controladdin DHXDayPlanningSequenceAddin
{
    RequestedHeight = 620;
    MinimumHeight = 380;
    VerticalShrink = true;
    VerticalStretch = true;

    RequestedWidth = 1200;
    MinimumWidth = 600;
    HorizontalStretch = true;
    HorizontalShrink = true;

    Scripts =
        'src/dhx/dhtmlxscheduler.js',
        'src/dhx/GlobalFunction.js',
        'src/dhx/dayplanning_sequence/wrapper.js';

    StartupScript = 'src/dhx/dayplanning_sequence/startupScript.js';

    StyleSheets =
        'src/dhx/dhtmlxscheduler.css',
        'src/dhx/dayplanning_sequence/style.css';

    event ControlReady();
    event OnCreateSequence(payloadJson: Text);
    event OnModifySequence(payloadJson: Text);
    event OnEventChanged(eventId: Text; eventData: Text);
    event OnEventDeleted(eventId: Text);
    event OnEventDblClick(eventId: Text; eventData: Text);

    procedure Init(sectionsJson: Text; skillsJson: Text; templatesJson: Text; earliestDate: Date; latestDate: Date);
    procedure LoadData(eventsJson: Text);
    procedure RefreshTimeline(sectionsJson: Text; eventsJson: Text; anchorDate: Date; latestDate: Date);
    procedure LoadHolidaysData(holidaysJsonTxt: Text);
    procedure SetDayOffColors(weekendColorHex: Text; holidayColorHex: Text);
}
