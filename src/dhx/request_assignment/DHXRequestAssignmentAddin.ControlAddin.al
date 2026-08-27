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
}
