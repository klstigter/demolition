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

    Images = 'images/filter_image.png', 'images/Remove_Filter_image.png';
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
    event OnExecuteSequence(PayloadJson: Text);
    event OnLookupSequenceResource();
    event OnEventChanged(eventId: Text; eventData: Text);
    event OnEventCreated(eventData: Text);
    event OnEventDeleted(eventId: Text);
    event OnEventDblClick(eventId: Text; eventData: Text);
    // Right-click row/bar menu on page 50712.
    event OnOpenProject(jobNo: Text);
    event OnOpenProjectTask(jobNo: Text; jobTaskNo: Text);
    // Right-click bar menu (eventId = Day Planning event id).
    event OnBarOpenResource(eventId: Text);
    event OnBarOpenCapacity(eventId: Text);
    // "New sequence" dialog Requested Resource No. assist-edit (only shown when the page has a resource context).
    event OnLookupNewSequenceResource();
    event OnFilterIconClick();
    event OnClearFilter();
    // "New sequence" dialog Project No./Task No. assist-edit (isTask=false: Project lookup; true: Task lookup of projectNo).
    event OnLookupNewSequenceContext(isTask: Boolean; projectNo: Text);
    procedure SetNewSequenceContext(projectNo: Text; taskNo: Text);
    // Resource context of the page (blank = none): shows/pre-fills the dialog's Requested Resource No. field.
    procedure SetNewSequenceResourceContext(resourceNo: Text);
    procedure SetNewSequenceResource(resourceNo: Text);

    procedure SetSequenceResource(ResourceNo: Code[20]);
    procedure SequenceExecuted();
    procedure Init(sectionsJson: Text; skillsJson: Text; templatesJson: Text; earliestDate: Date; latestDate: Date);
    // Standalone page 50712 only: shows Project No./Task No. columns and the "Filter applied" icon.
    procedure SetShowContext(show: Boolean);
    // Standalone page 50712 only: JSON array of section keys (rows) to shade light yellow.
    procedure SetHighlightedSections(keysJson: Text);
    // Default Skill / Work-Hour Template pre-selected when "New sequence" opens (part 50711).
    procedure SetNewSequenceDefaults(skillCode: Text; templateCode: Text);
    // Standalone page 50712 only: opens the "New sequence" dialog right away, Project/Task pre-filled.
    procedure OpenNewSequence(jobNo: Text; jobTaskNo: Text);
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
