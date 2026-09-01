page 50710 "DHX Request Assignment Board"
{
    PageType = Card; //userControlHost;
    ApplicationArea = All;
    UsageCategory = Tasks;
    Caption = 'Request and Assignment Board';

    layout
    {
        area(content)
        {
            usercontrol(DhxScheduler; DHXRequestAssignmentAddin)
            {
                ApplicationArea = All;

                trigger ControlReady()
                begin
                    RefreshPlanningData();
                end;

                trigger OnAcceptSequence(PayloadJsonTxt: Text)
                var
                    DHXDataHandler: Codeunit "DHX Data Handler";
                begin
                    // JS already applied its own optimistic update for the whole-sequence drop -
                    // this is the only point where that drop actually persists (confirmed product
                    // decision - see codeunit 50604's ReqAssign_AcceptSequence doc comment). No
                    // need to push data back to the control afterwards.
                    DHXDataHandler.ReqAssign_AcceptSequence(PayloadJsonTxt);
                end;

                trigger OnRejectSequence(PayloadJsonTxt: Text)
                var
                    DHXDataHandler: Codeunit "DHX Data Handler";
                begin
                    // JS already discards its provisional state on reject - nothing was ever
                    // persisted, so this is a no-op/optional-logging stub on the AL side too.
                    DHXDataHandler.ReqAssign_RejectSequence(PayloadJsonTxt);
                end;

                trigger OnAssignDayTaskLine(PayloadJsonTxt: Text)
                var
                    DHXDataHandler: Codeunit "DHX Data Handler";
                begin
                    DHXDataHandler.ReqAssign_AssignDayTaskLine(PayloadJsonTxt);
                end;

                trigger OnMoveAssignment(PayloadJsonTxt: Text)
                var
                    DHXDataHandler: Codeunit "DHX Data Handler";
                begin
                    DHXDataHandler.ReqAssign_MoveAssignment(PayloadJsonTxt);
                end;

                trigger OnResizeAssignment(PayloadJsonTxt: Text)
                var
                    DHXDataHandler: Codeunit "DHX Data Handler";
                begin
                    DHXDataHandler.ReqAssign_ResizeAssignment(PayloadJsonTxt);
                end;

                trigger OnUnassignDayTaskLine(PayloadJsonTxt: Text)
                var
                    DHXDataHandler: Codeunit "DHX Data Handler";
                begin
                    DHXDataHandler.ReqAssign_UnassignDayTaskLine(PayloadJsonTxt);
                end;

                trigger OnRequestReset()
                begin
                    // In-canvas "Reset assignments" button - the ported wrapper.js discards all
                    // unsaved client-side state itself before raising this event; the AL side's
                    // only job is to hand back a completely fresh payload, same as Refresh.
                    RefreshPlanningData();
                end;

                #region Background-loaded remaining Day Task Lines (Part B pagination)

                /// <summary>
                /// JS-initiated poll (wrapper.js's bounded interval, started by
                /// NotifyDayTaskLinesTaskPending) asking "is a background-task result ready yet?".
                /// This is a normal synchronous trigger call, unlike OnPageBackgroundTaskCompleted -
                /// so calling CurrPage.DhxScheduler.* from here is safe (confirmed live via codeunit
                /// 50713's/50720's identical pattern for the Gantt/Task Scheduler add-ins: it is NOT
                /// safe from the background-task completion trigger itself).
                /// </summary>
                trigger OnPollDayTaskLinesResult()
                begin
                    if not PendingDayTaskLinesResultAvailable then
                        exit;

                    PendingDayTaskLinesResultAvailable := false;
                    if PendingDayTaskLinesJson <> '' then
                        CurrPage.DhxScheduler.AppendDayTaskLines(PendingDayTaskLinesJson);
                    Clear(PendingDayTaskLinesJson);
                    CurrPage.DhxScheduler.StopDayTaskLinesPolling();
                end;

                #endregion Background-loaded remaining Day Task Lines (Part B pagination)
            }
        }
    }

    // actions
    // {
    //     area(Processing)
    //     {
    //         action(Refresh)
    //         {
    //             Caption = 'Refresh';
    //             ApplicationArea = All;
    //             Image = Refresh;
    //             trigger OnAction()
    //             begin
    //                 RefreshPlanningData();
    //             end;
    //         }
    //     }

    //     area(Promoted)
    //     {
    //         group(Category_Process)
    //         {
    //             Caption = 'Process';
    //             actionref(Refresh_Promoted; Refresh) { }
    //         }
    //     }
    // }

    /// <summary>
    /// Default 30-workday window: StartDate is the Monday of the current week, and EndDate is
    /// the date of the 30th workday counted from that Monday inclusive.
    /// </summary>
    local procedure GetDefaultWindow(var StartDate: Date; var EndDate: Date)
    var
        CurDate: Date;
        WorkdaysCounted: Integer;
    begin
        StartDate := Today() - (Date2DWY(Today(), 1) - 1);
        CurDate := StartDate;
        WorkdaysCounted := 1;

        while WorkdaysCounted < 30 do begin
            CurDate += 1;
            if IsWorkday(CurDate) then
                WorkdaysCounted += 1;
        end;

        EndDate := CurDate;
    end;

    local procedure IsWorkday(D: Date): Boolean
    begin
        // Date2DWY(.., 1) returns the day number within the week, 1=Monday .. 7=Sunday.
        exit(Date2DWY(D, 1) < 6);
    end;

    /// <summary>
    /// Fires when a Page Background Task enqueued via EnqueueDayTaskLinesBackgroundTask finishes.
    /// TaskId is compared against DayTaskLinesTaskId (overwritten by every new enqueue) so a
    /// result from a superseded reload is discarded - same TaskId-based staleness check as
    /// codeunit 50713's Gantt resource-panel flow and page 50621's Task Scheduler sections flow.
    /// Unlike those two, this page has no Next/Prev/filter navigation yet (RefreshPlanningData
    /// always rebuilds the same current-week-plus-30-workday window) - so the TaskId check alone
    /// is a sufficient staleness guard here; there is no separate "did the displayed period/filter
    /// move on" re-check to duplicate.
    /// </summary>
    trigger OnPageBackgroundTaskCompleted(TaskId: Integer; Results: Dictionary of [Text, Text])
    begin
        if TaskId <> DayTaskLinesTaskId then
            exit;

        // NOTE: does NOT call CurrPage.DhxScheduler.* here - confirmed live that BC Server rejects
        // any control add-in callback issued directly from this trigger (see codeunit 50713's/
        // codeunit 50720's identical comment for the Gantt/Task Scheduler add-ins). Stash into a
        // plain AL var instead; OnPollDayTaskLinesResult (JS-initiated, via wrapper.js's bounded
        // poll loop kicked off by NotifyDayTaskLinesTaskPending) is what actually pushes this into
        // the control add-in, from a normal synchronous call stack.
        if Results.ContainsKey('dayTaskLinesJson') then
            PendingDayTaskLinesJson := Results.Get('dayTaskLinesJson');
        PendingDayTaskLinesResultAvailable := (PendingDayTaskLinesJson <> '') and (PendingDayTaskLinesJson <> '[]');
    end;

    trigger OnPageBackgroundTaskError(TaskId: Integer; ErrorCode: Text; ErrorText: Text; ErrorCallStack: Text; var IsHandled: Boolean)
    var
        DayTaskLinesLoadErrorNotification: Notification;
    begin
        if TaskId <> DayTaskLinesTaskId then
            exit;

        IsHandled := true;
        // A notification is allowed here (unlike a raw Message/UI render) - surface the failure
        // without blocking the board; the first page already rendered successfully.
        DayTaskLinesLoadErrorNotification.Message := StrSubstNo('Loading the remaining Request/Assignment Board data failed: %1', ErrorText);
        DayTaskLinesLoadErrorNotification.Send();
    end;

    var
        DayTaskLinesTaskId: Integer; // TaskId of the most recently enqueued day-task-lines background task; OnPageBackgroundTaskCompleted/Error discard any result whose TaskId doesn't match (superseded by a later reload)
        PendingDayTaskLinesJson: Text; // set by OnPageBackgroundTaskCompleted, delivered into the control add-in by OnPollDayTaskLinesResult (see that trigger's comment for why the split is necessary)
        PendingDayTaskLinesResultAvailable: Boolean;

    /// <summary>
    /// Shared rebuild-and-push routine - the single place that calls
    /// ReqAssign_BuildPlanningDataJson_Paged and SetPlanningData. Called by ControlReady, the
    /// Refresh action, and the OnRequestReset trigger (the in-canvas "Reset assignments" button) -
    /// all three want the exact same fresh current-week-plus-30-workday payload, so none of them
    /// duplicate this logic themselves.
    ///
    /// Only the first DayTaskLinesPageSize-worth of whole sequenceKey groups is built and rendered
    /// synchronously here (Part B.2) - cuts the client-side JSON.parse/model-build/DHTMLX-ingest
    /// cost for first paint on the ~7,000-row real dataset this board can carry; whatever whole
    /// sequenceKey groups didn't fit are fetched off the interactive request path by
    /// EnqueueDayTaskLinesBackgroundTask and appended once ready (OnPollDayTaskLinesResult ->
    /// AppendDayTaskLines) - a no-op enqueue when everything already fit on the first page.
    /// </summary>
    local procedure RefreshPlanningData()
    var
        DHXDataHandler: Codeunit "DHX Data Handler";
        StartDate: Date;
        EndDate: Date;
        Window: Dialog;
        LoadingLbl: Label 'Loading Gantt data...\n#1######################';
        PlanningDataJson: Text;
        RemainingSequenceKeys: Text;
        DayTaskLinesPageSize: Integer;
    begin
        GetDefaultWindow(StartDate, EndDate);

        if GuiAllowed() then
            Window.Open(LoadingLbl);

        // ~1,200 dayTaskLines (~17% of the measured 7,004-row real dataset) - large enough that the
        // visible "Sequences" tree and near-term timeline are immediately populated and
        // interactive, small enough to cut the client-side parse/model-build/DHTMLX-ingest cost for
        // first paint by roughly 5-6x. See docs/RequestAssignmentBoard-Performance-
        // PageBackgroundTask-Enhancement.pdf's Verification section for the measured before/after.
        DayTaskLinesPageSize := 1200;
        PlanningDataJson := DHXDataHandler.ReqAssign_BuildPlanningDataJson_Paged(StartDate, EndDate, DayTaskLinesPageSize, RemainingSequenceKeys);

        if GuiAllowed() then
            Window.Update(1, 'Rendering...');
        CurrPage.DhxScheduler.SetPlanningData(PlanningDataJson);

        EnqueueDayTaskLinesBackgroundTask(StartDate, EndDate, RemainingSequenceKeys);

        if GuiAllowed() then
            Window.Close();
    end;

    /// <summary>
    /// Enqueues codeunit "ReqAssign BG Day Task Lines" to build whatever whole sequenceKey groups
    /// didn't fit on the first paginated page (RemainingSequenceKeys) - a no-op when
    /// RemainingSequenceKeys is blank (the whole window already fit). Returns immediately;
    /// OnPageBackgroundTaskCompleted applies the result once ready, via OnPollDayTaskLinesResult's
    /// poll delivery.
    /// </summary>
    local procedure EnqueueDayTaskLinesBackgroundTask(pStartDate: Date; pEndDate: Date; RemainingSequenceKeys: Text)
    var
        TaskParameters: Dictionary of [Text, Text];
        NewTaskId: Integer;
    begin
        if RemainingSequenceKeys = '' then
            exit; // everything already fit on the first page - nothing to background-load

        TaskParameters.Add('StartDate', Format(pStartDate, 0, '<Year4>-<Month,2>-<Day,2>'));
        TaskParameters.Add('EndDate', Format(pEndDate, 0, '<Year4>-<Month,2>-<Day,2>'));
        TaskParameters.Add('RemainingSequenceKeys', RemainingSequenceKeys);

        CurrPage.EnqueueBackgroundTask(NewTaskId, Codeunit::"ReqAssign BG Day Task Lines", TaskParameters, 30000, PageBackgroundTaskErrorLevel::Warning);
        DayTaskLinesTaskId := NewTaskId;
        PendingDayTaskLinesResultAvailable := false; // any earlier not-yet-delivered result is now stale
        CurrPage.DhxScheduler.NotifyDayTaskLinesTaskPending(); // (re)start wrapper.js's bounded poll loop - normal synchronous call, safe here
    end;
}
