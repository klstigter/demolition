controladdin DHXCapacityPlanningDashboardAddin
{
    // Role Center tile variant of DHXCapacityPlanningOverviewAddin (page 50722) - Sections 1/3/4
    // only (no Section 2 - there is no single "inspected Work Order" context on a Role Center).
    // Sized for a tile inside the Role Center's own content column, not a full modal - shorter/
    // narrower than page 50722's own 1150/1800 (no Section 2's own up-to-400px allowance needed).
    RequestedHeight = 780;
    MinimumHeight = 360;
    VerticalShrink = true;
    VerticalStretch = true;

    // Root-caused via direct inspection of BC's own shipped client bundle (2026-09-08, see this
    // add-in's project memory for the full writeup): Role Center "Normal"/Insights section row
    // placement is a FIXED grid keyed only on (a) how many parts are in the section and (b) the
    // browser's raw viewport width vs. hard breakpoints at 1921px/1367px/1025px - 3+ parts always
    // get 1/3 width (>=1921px) or 1/2 (1367-1921px) or 1/1 (<=1025px); the client NEVER reads
    // RequestedWidth/MinimumWidth/HorizontalStretch/HorizontalShrink to make that decision -
    // confirmed live via getBoundingClientRect() that this tile's cell was 782px wide at a 2560px
    // viewport despite MinimumWidth=1400 declared here. A prior attempt at using MinimumWidth as a
    // "hard floor" to force a row-break was based on a coincidental correlation (it happened to
    // wrap at exactly one tested viewport width, 1920px, one pixel under the 3-column breakpoint)
    // and is not real - reverted back to realistic values. There is NO AL-level property that
    // controls Role Center row placement; forcing this tile onto a guaranteed full-width row at
    // every viewport width would require reducing the Insights section to exactly one part (see
    // this add-in's project memory for the full option comparison) - out of scope for this add-in
    // alone. These values only affect the add-in's own sizing WITHIN whatever cell width the
    // client's grid assigns it.
    RequestedWidth = 1600;
    MinimumWidth = 700;
    HorizontalStretch = true;
    HorizontalShrink = true;

    // Reuses src/dhx/capacity_planning_overview's own component class/stylesheet BY PATH (no
    // duplication - see capacityPlanningDashboard.js's own doc comment for why this is a thin
    // subclass, not a copy) - only capacityPlanningDashboard.js/wrapper.js/startupScript.js/
    // style.css (the dashboard-only yellow-tile override) live in this folder. Load order:
    // vendor libs, then the BASE component class (capacityPlanningOverview.js - must come before
    // the subclass, which extends it), then the subclass, then wrapper.js last (references the
    // CapacityPlanningDashboard class at BOOT time).
    Scripts =
        'src/dhx/dhtmlxscheduler.js',
        'src/dhx/suite.js',
        'src/dhx/GlobalFunction.js',
        'src/dhx/capacity_planning_overview/capacityPlanningOverview.js',
        'src/dhx/capacity_planning_dashboard/capacityPlanningDashboard.js',
        'src/dhx/capacity_planning_dashboard/wrapper.js';

    StartupScript = 'src/dhx/capacity_planning_dashboard/startupScript.js';

    // Shared style.css loaded first, this folder's own style.css last so its yellow-tile overrides
    // win (see that file's own doc comment).
    StyleSheets =
        'src/dhx/dhtmlxscheduler.css',
        'src/dhx/suite.css',
        'src/dhx/capacity_planning_overview/style.css',
        'src/dhx/capacity_planning_dashboard/style.css';

    procedure SetPlanningData(PlanningDataJsonTxt: Text);
    procedure SetColors(ColorsJsonTxt: Text);
    // Page Background Task pagination - same mechanism as page 50722's own (see
    // capacity_planning_overview's identical procedures' own doc comments for the full design).
    procedure AppendOtherWorkOrderData(OtherWorkOrderDataJsonTxt: Text);
    procedure NotifyOtherWorkOrderDataTaskPending();
    procedure StopOtherWorkOrderDataPolling();

    event ControlReady();
    // Declared for parity with the base class's own wiring (inherited, unused code paths only -
    // Section 2/the Confirm button are removed client-side, see capacityPlanningDashboard.js) -
    // never actually raised in normal use on this tile, since workOrderSequences[] is always empty
    // (AL never sends a real "workOrder"), but kept so no inherited base-class code path can ever
    // throw calling an undeclared controladdin event.
    event OnRescheduleWorkOrder(DayShift: Integer; PayloadJsonTxt: Text);
    event OnRequestCapacityLookup(FilterJsonTxt: Text);
    event OnSequenceChipClick(PayloadJsonTxt: Text);
    event OnDaysToShowChanged(NumberOfDays: Integer);
    event OnPollOtherWorkOrderDataResult();
}
