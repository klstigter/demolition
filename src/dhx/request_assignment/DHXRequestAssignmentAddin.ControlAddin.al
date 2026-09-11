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
    // Hover/tooltip popup colours - codeunit 50609's GetTooltipBackgroundColor/
    // GetTooltipFontColor, applied to every custom hover-popup shell in style.css
    // (.sequence-drag-tooltip/.assignment-detail-tooltip/.resource-skill-warning-tooltip/
    // .request-detail-tooltip). See wrapper.js's SetColors.
    procedure SetColors(ColorsJsonTxt: Text);
    // Work-Hour Templates for the "Modify sequence" panel (see OnModifySequence below) - same
    // codeunit 50695 "Day Planning Sequence Mgt."/BuildTemplatesJson JSON shape page 50711's own
    // ControlReady sends to DHXDayPlanningSequenceAddin.Init. Called once from page 50710's
    // ControlReady, separately from SetPlanningData, since the template list doesn't change on a
    // Refresh/Reset reload the way the planning data does. Skills are NOT loaded this way - every
    // Day Task Line already carries its own "requiredSkill" (see wrapper.js's sequenceRows), so
    // there's no need for a separate skills payload the way page 50711 needs one for its "New
    // sequence" dialog's Skill dropdown (this board's "Modify sequence" panel never lets the user
    // change skill, only template/dates/excluded-days).
    procedure SetTemplates(TemplatesJsonTxt: Text);
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
    // Raised by the "Modify sequence" context-menu item on a Sequences-tree row - payload
    // { "jobNo", "jobTaskNo", "skill", "sequenceNo", "template", "excludedWeekdays" (CSV),
    // "startDate", "endDate" }, same shape as page 50711's own OnModifySequence plus jobNo/
    // jobTaskNo (this board isn't scoped to a single Job/Task the way the Job Task Card is - see
    // wrapper.js's applySequenceModification). Regenerates the whole sequence thread in place via
    // codeunit 50695 "Day Planning Sequence Mgt."'s RegenerateSequence (see page 50710's trigger).
    event OnModifySequence(PayloadJsonTxt: Text);
    // Raised by the "Open Card" context-menu item on a request row or an assignment bar. LineId is
    // the dayTaskLine's id ("JobNo|JobTaskNo|DayLineNo", see wrapper.js's findLine /
    // assignmentLineFromPointerTarget) - unlike the other events above, this is the raw id string,
    // not a JSON payload, since there's nothing else to carry.
    event OnOpenDayPlanningCard(LineId: Text);
    // Raised by the "Open Capacity" context-menu item on a resource's capacity slot background bar.
    // ResourceId is the Resource No.; StartDateTxt/EndDateTxt are "yyyy-MM-dd" text (see wrapper.js's
    // dateOnlyKey) taken directly from the board's currently-displayed planning horizon bounds
    // (allPlanningLines()[0].date .. getGlobalSelectionEndDate()) - the same range shown by the
    // toolbar's "N of M Day Task Lines in horizon" label / "Select until" date input. No week
    // resolution happens AL-side anymore; ReqAssign_OpenCapacity just filters by resource + range.
    event OnOpenCapacity(ResourceId: Text; StartDateTxt: Text; EndDateTxt: Text);
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
