page 50722 "Capacity Planning Overview"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Tasks;
    // Blank on purpose - the control add-in's own JS renders its title bar (cpo-top-title,
    // sourced from workOrder.no/description in the payload); a non-blank Caption here would
    // duplicate it as a second native BC heading above the add-in.
    Caption = '';
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(content)
        {
            usercontrol(DhxCpo; DHXCapacityPlanningOverviewAddin)
            {
                ApplicationArea = All;

                trigger ControlReady()
                begin
                    EnsureDaysToShow();
                    RefreshData();
                end;

                // JS-owned "Days to show" control (rendered inside the DHTMLX component itself,
                // not a native AL field) - per the project's non-negotiable single-JS-component
                // architecture, this add-in binds exactly one control add-in, so any input that
                // affects what gets rendered belongs INSIDE that one JS component, not bolted onto
                // the AL page around it. Raised whenever the user changes the input; AL just
                // rebuilds the payload with the new day count and pushes it back via
                // SetPlanningData - the JSON payload's own "daysToShow" key (see
                // CPO_BuildPlanningDataJson) is what keeps the JS input's displayed value in sync
                // with whatever AL actually used (initial default, or after Reset position).
                trigger OnDaysToShowChanged(NumberOfDays: Integer)
                begin
                    if NumberOfDays <= 0 then
                        NumberOfDays := DefaultDaysToShow;
                    DaysToShow := NumberOfDays;
                    RefreshData();
                end;

                trigger OnRescheduleWorkOrder(DayShift: Integer; PayloadJsonTxt: Text)
                begin
                    // Stub only - real transactional Validate("Plan Date", ...) loop over the WO's
                    // Day Planning lines comes in a later step of the implementation plan. For now
                    // just prove the round-trip fires.
                    Message('Reschedule stub: shift=%1', DayShift);
                end;

                trigger OnRequestCapacityLookup(FilterJsonTxt: Text)
                begin
                    // Stub - CPO_BuildCapacityLookupJson wiring comes in a later step.
                end;

                trigger OnSequenceChipClick(PayloadJsonTxt: Text)
                begin
                    // Stub - resolving the specific Day Planning line and opening "Day Plannings"
                    // filtered to it comes in a later step.
                end;

                #region Background-loaded remaining other-Work-Order data (Section 4 pagination)

                /// <summary>
                /// JS-initiated poll (wrapper.js's bounded interval, started by
                /// NotifyOtherWorkOrderDataTaskPending) asking "is a background-task result ready
                /// yet?". This is a normal synchronous trigger call, unlike
                /// OnPageBackgroundTaskCompleted - so calling CurrPage.DhxCpo.* from here is safe
                /// (confirmed live via codeunit 50721's identical pattern for the Request/
                /// Assignment Board: it is NOT safe from the background-task completion trigger
                /// itself).
                /// </summary>
                trigger OnPollOtherWorkOrderDataResult()
                begin
                    if not PendingOtherWorkOrderDataAvailable then
                        exit;

                    PendingOtherWorkOrderDataAvailable := false;
                    if PendingOtherWorkOrderDataJson <> '' then
                        CurrPage.DhxCpo.AppendOtherWorkOrderData(PendingOtherWorkOrderDataJson);
                    Clear(PendingOtherWorkOrderDataJson);
                    CurrPage.DhxCpo.StopOtherWorkOrderDataPolling();
                end;

                #endregion Background-loaded remaining other-Work-Order data (Section 4 pagination)
            }
        }
    }

    /// <summary>
    /// Fires when a Page Background Task enqueued via EnqueueOtherWorkOrderDataBackgroundTask
    /// finishes. TaskId is compared against OtherWorkOrderDataTaskId (overwritten by every new
    /// enqueue) so a result from a superseded reload (Days-to-show change, Reset position) is
    /// discarded - same TaskId-based staleness check as codeunit 50721's Request/Assignment Board
    /// flow.
    /// </summary>
    trigger OnPageBackgroundTaskCompleted(TaskId: Integer; Results: Dictionary of [Text, Text])
    begin
        if TaskId <> OtherWorkOrderDataTaskId then
            exit;

        // NOTE: does NOT call CurrPage.DhxCpo.* here - confirmed live (via codeunit 50721's
        // identical comment) that BC Server rejects any control add-in callback issued directly
        // from this trigger. Stash into a plain AL var instead; OnPollOtherWorkOrderDataResult
        // (JS-initiated, via wrapper.js's bounded poll loop kicked off by
        // NotifyOtherWorkOrderDataTaskPending) is what actually pushes this into the control
        // add-in, from a normal synchronous call stack.
        if Results.ContainsKey('otherWorkOrderDataJson') then
            PendingOtherWorkOrderDataJson := Results.Get('otherWorkOrderDataJson');
        PendingOtherWorkOrderDataAvailable := (PendingOtherWorkOrderDataJson <> '') and (PendingOtherWorkOrderDataJson <> '[]');
    end;

    trigger OnPageBackgroundTaskError(TaskId: Integer; ErrorCode: Text; ErrorText: Text; ErrorCallStack: Text; var IsHandled: Boolean)
    var
        OtherWorkOrderDataLoadErrorNotification: Notification;
    begin
        if TaskId <> OtherWorkOrderDataTaskId then
            exit;

        IsHandled := true;
        // A notification is allowed here (unlike a raw Message/UI render) - surface the failure
        // without blocking the add-in; the first page (this WO's own data + the first
        // MaxOtherLines-worth of other-Work-Order groups) already rendered successfully.
        OtherWorkOrderDataLoadErrorNotification.Message := StrSubstNo('Loading the remaining Capacity Planning Overview data failed: %1', ErrorText);
        OtherWorkOrderDataLoadErrorNotification.Send();
    end;

    var
        GWorkOrderNo: Code[20];
        DaysToShow: Integer;
        OtherWorkOrderDataTaskId: Integer; // TaskId of the most recently enqueued other-work-order-data background task; OnPageBackgroundTaskCompleted/Error discard any result whose TaskId doesn't match (superseded by a later reload)
        PendingOtherWorkOrderDataJson: Text; // set by OnPageBackgroundTaskCompleted, delivered into the control add-in by OnPollOtherWorkOrderDataResult (see that trigger's comment for why the split is necessary)
        PendingOtherWorkOrderDataAvailable: Boolean;

    /// <summary>Default "Days to show" (Today() .. Today()+29) - matches this repo's other DHX
    /// add-ins' own "Next 30 workdays"-style default window length convention.</summary>
    local procedure DefaultDaysToShow(): Integer
    begin
        exit(30);
    end;

    /// <summary>
    /// Filter-setter-before-RunModal, following the same pattern as "Gantt Demo DHX 2"'s
    /// SetJobFilter/"DHX Scheduler (Project)"'s SetJobTaskFilter - the launching action on the
    /// Workorder Card calls this before RunModal(), no bound SourceTable on this page.
    /// </summary>
    procedure SetWorkOrderNo(pWorkOrderNo: Code[20])
    begin
        GWorkOrderNo := pWorkOrderNo;
    end;

    local procedure EnsureDaysToShow()
    begin
        if DaysToShow <= 0 then
            DaysToShow := DefaultDaysToShow;
    end;

    /// <summary>
    /// Single shared rebuild-and-push routine, mirroring RefreshPlanningData/RefreshSchedule in
    /// the sibling add-ins - called by ControlReady and the Days-to-show field. Builds the real
    /// payload via codeunit 50604's CPO_BuildPlanningDataJson_Paged (workOrder header + a
    /// Today()-anchored calendar-day window, DaysToShow long + this WO's own Day Planning lines in
    /// full + only the first CPOOtherWorkOrderGroupsPageSize-worth of whole other-Work-Order
    /// Skill/Job/Task groups).
    ///
    /// Only the first page's worth of OTHER Work Orders' data is built and rendered synchronously
    /// here (Page Background Task pagination, 2026-09-03 - explicit user request: "the system takes
    /// a long time to generate the JSON and load it into DHTMLX ... get the first 50 records, and
    /// the remaining will background process") - cuts the client-side JSON.parse/model-build/
    /// DHTMLX-ingest cost for first paint on a company-wide dataset that can be huge; whatever
    /// whole groups didn't fit are fetched off the interactive request path by
    /// EnqueueOtherWorkOrderDataBackgroundTask and appended once ready
    /// (OnPollOtherWorkOrderDataResult -> AppendOtherWorkOrderData) - a no-op enqueue when
    /// everything already fit on the first page. Modeled directly on page 50710 "DHX Request
    /// Assignment Board"'s own RefreshPlanningData/EnqueueDayTaskLinesBackgroundTask pattern.
    /// </summary>
    local procedure RefreshData()
    var
        DHXDataHandler: Codeunit "DHX Data Handler";
        PlanningDataJson: Text;
        RemainingGroupKeys: Text;
        OtherWorkOrderGroupsPageSize: Integer;
    begin
        if GWorkOrderNo = '' then
            exit;

        // 50 whole Skill+Job No.+Job Task No. groups - the exact figure the user asked for
        // ("get the first 50 records"). Large enough that Section 4's tree is immediately
        // populated with real chip data for the near-term/most-relevant groups, small enough to
        // cut the client-side parse/model-build/DHTMLX-ingest cost for first paint on a
        // company-wide "every other Work Order in this window" dataset that can otherwise be huge.
        OtherWorkOrderGroupsPageSize := 50;
        PlanningDataJson := DHXDataHandler.CPO_BuildPlanningDataJson_Paged(GWorkOrderNo, DaysToShow, OtherWorkOrderGroupsPageSize, RemainingGroupKeys);
        CurrPage.DhxCpo.SetPlanningData(PlanningDataJson);

        EnqueueOtherWorkOrderDataBackgroundTask(RemainingGroupKeys);
    end;

    /// <summary>
    /// Enqueues codeunit "CPO BG Other WO Data" to build whatever whole Skill+Job No.+Job Task No.
    /// groups didn't fit on RefreshData's first paginated page (RemainingGroupKeys) - a no-op when
    /// RemainingGroupKeys is blank (everything already fit on the first page). Returns immediately;
    /// OnPageBackgroundTaskCompleted applies the result once ready, via OnPollOtherWorkOrderDataResult's
    /// poll delivery.
    /// </summary>
    local procedure EnqueueOtherWorkOrderDataBackgroundTask(RemainingGroupKeys: Text)
    var
        TaskParameters: Dictionary of [Text, Text];
        NewTaskId: Integer;
        StartDate: Date;
        EndDate: Date;
    begin
        if RemainingGroupKeys = '' then
            exit; // everything already fit on the first page - nothing to background-load

        StartDate := Today();
        EndDate := StartDate + DaysToShow - 1;

        TaskParameters.Add('WorkOrderNo', GWorkOrderNo);
        TaskParameters.Add('StartDate', Format(StartDate, 0, '<Year4>-<Month,2>-<Day,2>'));
        TaskParameters.Add('EndDate', Format(EndDate, 0, '<Year4>-<Month,2>-<Day,2>'));
        TaskParameters.Add('RemainingGroupKeys', RemainingGroupKeys);

        CurrPage.EnqueueBackgroundTask(NewTaskId, Codeunit::"CPO BG Other WO Data", TaskParameters, 30000, PageBackgroundTaskErrorLevel::Warning);
        OtherWorkOrderDataTaskId := NewTaskId;
        PendingOtherWorkOrderDataAvailable := false; // any earlier not-yet-delivered result is now stale
        CurrPage.DhxCpo.NotifyOtherWorkOrderDataTaskPending(); // (re)start wrapper.js's bounded poll loop - normal synchronous call, safe here
    end;
}
