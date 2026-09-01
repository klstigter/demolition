controladdin DHXRequestAssignmentAddin
{
    RequestedHeight = 1400;
    MinimumHeight = 700;
    VerticalShrink = true;
    VerticalStretch = true;

    RequestedWidth = 1800;
    MinimumWidth = 900;
    HorizontalStretch = true;
    HorizontalShrink = true;

    // Shared libs reused as-is (same convention as poolresourceschedule/projectschedule/
    // resourceschedule_with_capacity) - only wrapper.js/style.css/startupScript.js are specific
    // to this new add-in. The JS-side port of the Request/Assignment Planner is being built
    // separately against these exact file paths and against the exact procedure/event contract
    // below - do not rename.
    Scripts =
        'src/dhx/dhtmlxscheduler.js',
        'src/dhx/GlobalFunction.js',
        'src/dhx/request_assignment/wrapper.js';

    StartupScript = 'src/dhx/request_assignment/startupScript.js';

    StyleSheets =
        'src/dhx/dhtmlxscheduler.css',
        'src/dhx/request_assignment/style.css';

    procedure SetPlanningData(PlanningDataJsonTxt: Text);
    // Part B.2/B.3 pagination - appends a background-loaded remainder of "dayTaskLines" (whole
    // sequenceKey groups that didn't fit RefreshPlanningData's first synchronous page) into the
    // already-rendered board in place. See wrapper.js's AppendDayTaskLines: .push()es the parsed
    // batch into the existing dayTaskLines array and calls rebuildRequestTree()/renderAll() once
    // for the merged set - never routes through SetPlanningData's full-reset path.
    procedure AppendDayTaskLines(DayTaskLinesJsonTxt: Text);
    // Companion to OnPollDayTaskLinesResult below - called right after every day-task-lines
    // background task is enqueued (a normal synchronous AL call, not from the completion trigger)
    // so JS knows to (re)start its bounded poll loop. Same shape as ganttdemo2's
    // NotifyResourcePanelTaskPending / projectschedule's NotifySectionsTaskPending.
    procedure NotifyDayTaskLinesTaskPending();
    // Called once a pending background-task result was actually delivered into the control
    // add-in, so JS can stop its poll burst early instead of waiting out the full timeout.
    procedure StopDayTaskLinesPolling();

    event ControlReady();
    event OnAcceptSequence(PayloadJsonTxt: Text);
    event OnRejectSequence(PayloadJsonTxt: Text);
    event OnAssignDayTaskLine(PayloadJsonTxt: Text);
    event OnMoveAssignment(PayloadJsonTxt: Text);
    event OnResizeAssignment(PayloadJsonTxt: Text);
    event OnUnassignDayTaskLine(PayloadJsonTxt: Text);
    // Raised by the in-canvas "Reset assignments" button. In the source demo this button calls an
    // undefined function and throws/no-ops; the ported wrapper.js fixes it to discard all
    // unsaved client-side state and ask AL for a fresh SetPlanningData load instead - see page
    // 50710's OnRequestReset trigger.
    event OnRequestReset();
    // JS-initiated poll asking "is a background-task result ready yet?" (see page 50710's
    // OnPollDayTaskLinesResult / EnqueueDayTaskLinesBackgroundTask, and codeunit "ReqAssign BG Day
    // Task Lines") - a normal synchronous trigger call, so AL answering it with
    // CurrPage.DhxScheduler.AppendDayTaskLines is safe, unlike from OnPageBackgroundTaskCompleted
    // itself. Same shape as ganttdemo2's OnPollResourcePanelResult / projectschedule's
    // OnPollSectionsResult.
    event OnPollDayTaskLinesResult();
}
