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
    event OnEventCreated(eventData: Text);
    event OnEventDeleted(eventId: Text);
    event OnEventDblClick(eventId: Text; eventData: Text);
    event OnFilterIconClick();
    event OnClearFilter();

    procedure Init(sectionsJson: Text; skillsJson: Text; templatesJson: Text; earliestDate: Date; latestDate: Date);
    // Standalone page 50712 only: shows Project No./Task No. columns and the "Filter applied" icon.
    procedure SetShowContext(show: Boolean);
    // Standalone page 50712 only: JSON array of section keys (rows) to shade light yellow.
    procedure SetHighlightedSections(keysJson: Text);
    // Default Skill / Work-Hour Template pre-selected when "New sequence" opens (part 50711).
    procedure SetNewSequenceDefaults(skillCode: Text; templateCode: Text);
    procedure LoadData(eventsJson: Text);
    procedure RefreshTimeline(sectionsJson: Text; eventsJson: Text; anchorDate: Date; latestDate: Date);
    procedure LoadHolidaysData(holidaysJsonTxt: Text);
    procedure SetDayOffColors(weekendColorHex: Text; holidayColorHex: Text);
    // Hover/tooltip popup colours - codeunit 50609's GetTooltipBackgroundColor/
    // GetTooltipFontColor, applied to .dps-tooltip (style.css). Same convention as
    // SetDayOffColors above.
    procedure SetTooltipColors(backgroundColorHex: Text; fontColorHex: Text);
    // Standalone page 50712 only: active Job/Task/Skill/Resource filter text, for the filter icon state.
    procedure SetFilterInfo(jobFilter: Text; jobTaskFilter: Text; skillFilter: Text; resourceFilter: Text; periodFrom: Text; periodTo: Text);
}
