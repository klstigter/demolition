controladdin DHXCapacityPlanningOverviewAddin
{
    // RequestedHeight covers the WORST case (every section at its own MAX clamp: section 1 fixed
    // ~104px + section 2 capped 400px + section 3 ~180px + section 4 capped 420px + ~40px chrome
    // = ~1150px) so a data-rich Work Order's section 4 never gets silently clipped below the
    // control's own bottom edge with no way to reach it (confirmed live: with #cpo-root's
    // page-level scroll intentionally removed - see that CSS's own comment on why - a 12+ row
    // Work Order's section 4 was cut off entirely once total content exceeded a too-small
    // RequestedHeight, unlike a too-TALL one, which only wasted blank space, never hid content).
    // MinimumHeight stays low + VerticalShrink=true so a SMALL Work Order (few rows) still shrinks
    // down naturally instead of leaving dead space - only section 2/4's OWN boxes
    // (.cpo-wo-scheduler-host/.cpo-central-tree-host) scroll internally when THEIR OWN content
    // exceeds their own cap, matching the reference; this control-level height is just about
    // making sure nothing is clipped before those per-section scrollbars even get a chance to work.
    RequestedHeight = 1150;
    MinimumHeight = 420;
    VerticalShrink = true;
    VerticalStretch = true;

    RequestedWidth = 1800;
    MinimumWidth = 900;
    HorizontalStretch = true;
    HorizontalShrink = true;

    // Shared vendor libs reused as-is (same convention as request_assignment/projectschedule/
    // ganttdemo2 etc.) - only capacityPlanningOverview.js/wrapper.js/style.css/startupScript.js
    // are specific to this new add-in. Vendor libs first, then our component class (before
    // wrapper.js, which references the CapacityPlanningOverview class at BOOT time), then
    // wrapper.js itself last.
    Scripts =
        'src/dhx/dhtmlxscheduler.js',
        'src/dhx/suite.js',
        'src/dhx/GlobalFunction.js',
        'src/dhx/capacity_planning_overview/capacityPlanningOverview.js',
        'src/dhx/capacity_planning_overview/wrapper.js';

    StartupScript = 'src/dhx/capacity_planning_overview/startupScript.js';

    StyleSheets =
        'src/dhx/dhtmlxscheduler.css',
        'src/dhx/suite.css',
        'src/dhx/capacity_planning_overview/style.css';

    procedure SetPlanningData(PlanningDataJsonTxt: Text);
    procedure SetColors(ColorsJsonTxt: Text);
    procedure LoadCapacityLookup(CapacityLookupJsonTxt: Text);
    // Page Background Task pagination (2026-09-03) - appends a background-loaded remainder of
    // "dayPlanningLines"/"groups" (whole Skill+Job No.+Job Task No. groups that didn't fit
    // RefreshData's first synchronous page) into the already-rendered add-in in place. See
    // capacityPlanningOverview.js's appendOtherWorkOrderData: merges the parsed batch into
    // this.db.dayPlanningLines/groups and re-renders sections 1/3/4 (their shortage/coverage math
    // depends on the now-more-complete company-wide data) - never routes through SetPlanningData's
    // full-reset path. Same shape as request_assignment's AppendDayTaskLines.
    procedure AppendOtherWorkOrderData(OtherWorkOrderDataJsonTxt: Text);
    // Companion to OnPollOtherWorkOrderDataResult below - called right after every
    // other-work-order-data background task is enqueued (a normal synchronous AL call, not from
    // the completion trigger) so JS knows to (re)start its bounded poll loop. Same shape as
    // request_assignment's NotifyDayTaskLinesTaskPending.
    procedure NotifyOtherWorkOrderDataTaskPending();
    // Called once a pending background-task result was actually delivered into the control
    // add-in, so JS can stop its poll burst early instead of waiting out the full timeout.
    procedure StopOtherWorkOrderDataPolling();

    event ControlReady();
    // Drag AND click-to-relocate in the WO scheduler / tree+grid both funnel into this one event.
    event OnRescheduleWorkOrder(DayShift: Integer; PayloadJsonTxt: Text);
    event OnRequestCapacityLookup(FilterJsonTxt: Text);
    event OnSequenceChipClick(PayloadJsonTxt: Text);
    // JS-owned "Days to show" input (bindDaysToShowInput in capacityPlanningOverview.js) - lives
    // inside this one component per the single-JS-component architecture, not a native AL field.
    event OnDaysToShowChanged(NumberOfDays: Integer);
    // JS-initiated poll asking "is a background-task result ready yet?" (see page 50722's
    // OnPollOtherWorkOrderDataResult / EnqueueOtherWorkOrderDataBackgroundTask, and codeunit "CPO
    // BG Other WO Data") - a normal synchronous trigger call, so AL answering it with
    // CurrPage.DhxCpo.AppendOtherWorkOrderData is safe, unlike from OnPageBackgroundTaskCompleted
    // itself. Same shape as request_assignment's OnPollDayTaskLinesResult.
    event OnPollOtherWorkOrderDataResult();
}
