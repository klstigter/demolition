page 50724 "Capacity Planning Dashboard"
{
    // Role Center tile - embeds DHXCapacityPlanningDashboardAddin (Sections 1/3/4 only, no single
    // inspected Work Order - see that controladdin's own capacityPlanningDashboard.js doc comment).
    // CardPart, not Card, so page 50612 "Planning Role Center" can embed it directly as a part().
    PageType = CardPart;
    ApplicationArea = All;
    Caption = '';
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(content)
        {
            usercontrol(DhxCpoDash; DHXCapacityPlanningDashboardAddin)
            {
                ApplicationArea = All;

                trigger ControlReady()
                begin
                    EnsureDaysToShow();
                    SendColors();
                    RefreshData();
                end;

                // JS-owned "Days to show" input, inherited unchanged from the base component - see
                // page 50722's own identical trigger doc comment.
                trigger OnDaysToShowChanged(NumberOfDays: Integer)
                begin
                    if NumberOfDays <= 0 then
                        NumberOfDays := DefaultDaysToShow;
                    DaysToShow := NumberOfDays;
                    RefreshData();
                end;

                trigger OnRescheduleWorkOrder(DayShift: Integer; PayloadJsonTxt: Text)
                begin
                    // Never actually raised in normal use - there is no Confirm-changes button on
                    // this tile (capacityPlanningDashboard.js removes it from the DOM, and
                    // workOrderSequences[] is always empty so there is nothing to reschedule
                    // anyway) - declared only so no inherited base-class code path can throw
                    // calling an undeclared controladdin event. See page 50722's own
                    // PersistReschedule for what a real implementation would look like if this
                    // tile ever needed one.
                end;

                trigger OnRequestCapacityLookup(FilterJsonTxt: Text)
                begin
                    // Stub - same as page 50722's own (CPO_BuildCapacityLookupJson wiring comes in
                    // a later step, shared across both pages).
                end;

                trigger OnSequenceChipClick(PayloadJsonTxt: Text)
                begin
                    // Stub - same as page 50722's own.
                end;

                #region Background-loaded remaining other-Work-Order data (Section 4 pagination)

                /// <summary>
                /// JS-initiated poll - identical pattern to page 50722's own
                /// OnPollOtherWorkOrderDataResult (see that trigger's own doc comment for why the
                /// completion trigger itself can't call the control add-in directly).
                /// </summary>
                trigger OnPollOtherWorkOrderDataResult()
                begin
                    if not PendingOtherWorkOrderDataAvailable then
                        exit;

                    PendingOtherWorkOrderDataAvailable := false;
                    if PendingOtherWorkOrderDataJson <> '' then
                        CurrPage.DhxCpoDash.AppendOtherWorkOrderData(PendingOtherWorkOrderDataJson);
                    Clear(PendingOtherWorkOrderDataJson);
                    CurrPage.DhxCpoDash.StopOtherWorkOrderDataPolling();
                end;

                #endregion Background-loaded remaining other-Work-Order data (Section 4 pagination)
            }
        }
    }

    /// <summary>
    /// Same TaskId-staleness-guarded pattern as page 50722's own identical trigger - see that
    /// page's own doc comment for the full reasoning (BC Server rejects a control add-in callback
    /// issued directly from this trigger).
    /// </summary>
    trigger OnPageBackgroundTaskCompleted(TaskId: Integer; Results: Dictionary of [Text, Text])
    begin
        if TaskId <> OtherWorkOrderDataTaskId then
            exit;

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
        OtherWorkOrderDataLoadErrorNotification.Message := StrSubstNo('Loading the remaining Capacity Planning Dashboard data failed: %1', ErrorText);
        OtherWorkOrderDataLoadErrorNotification.Send();
    end;

    var
        DaysToShow: Integer;
        OtherWorkOrderDataTaskId: Integer;
        PendingOtherWorkOrderDataJson: Text;
        PendingOtherWorkOrderDataAvailable: Boolean;

    local procedure DefaultDaysToShow(): Integer
    begin
        exit(30);
    end;

    local procedure EnsureDaysToShow()
    begin
        if DaysToShow <= 0 then
            DaysToShow := DefaultDaysToShow;
    end;

    /// <summary>Same tooltip-color channel as page 50722's own SendColors - see that procedure's own doc comment.</summary>
    local procedure SendColors()
    var
        VisualDefaultSettings: Codeunit "Visual Default Settings";
        ColorsJsonTxt: Text;
    begin
        ColorsJsonTxt := StrSubstNo('{"tooltipBg":"%1","tooltipFont":"%2"}',
            VisualDefaultSettings.GetTooltipBackgroundColor(),
            VisualDefaultSettings.GetTooltipFontColor());
        CurrPage.DhxCpoDash.SetColors(ColorsJsonTxt);
    end;

    /// <summary>
    /// Shared rebuild-and-push routine - builds the real payload via codeunit 50604's
    /// CPO_BuildDashboardDataJson_Paged (company-wide, no single Work Order - see that procedure's
    /// own doc comment) and pushes it via SetPlanningData, then enqueues the background task for
    /// whatever whole Skill+Job No.+Job Task No. groups didn't fit the first synchronous page - same
    /// 50-group page size and same pagination mechanism as page 50722's own RefreshData.
    /// </summary>
    local procedure RefreshData()
    var
        DHXDataHandler: Codeunit "DHX Data Handler";
        PlanningDataJson: Text;
        RemainingGroupKeys: Text;
        OtherWorkOrderGroupsPageSize: Integer;
    begin
        OtherWorkOrderGroupsPageSize := 50;
        PlanningDataJson := DHXDataHandler.CPO_BuildDashboardDataJson_Paged(DaysToShow, OtherWorkOrderGroupsPageSize, RemainingGroupKeys);
        CurrPage.DhxCpoDash.SetPlanningData(PlanningDataJson);

        EnqueueOtherWorkOrderDataBackgroundTask(RemainingGroupKeys);
    end;

    /// <summary>
    /// Enqueues codeunit "CPO BG Other WO Data" (REUSED as-is from src/dhx/
    /// capacity_planning_overview - see that codeunit's own doc comment; it already tolerates a
    /// blank WorkOrderNo, so no new background-task codeunit is needed for this tile) with a blank
    /// WorkOrderNo - a no-op when RemainingGroupKeys is blank (everything already fit).
    /// </summary>
    local procedure EnqueueOtherWorkOrderDataBackgroundTask(RemainingGroupKeys: Text)
    var
        TaskParameters: Dictionary of [Text, Text];
        NewTaskId: Integer;
        StartDate: Date;
        EndDate: Date;
    begin
        if RemainingGroupKeys = '' then
            exit;

        StartDate := Today();
        EndDate := StartDate + DaysToShow - 1;

        TaskParameters.Add('WorkOrderNo', '');
        TaskParameters.Add('StartDate', Format(StartDate, 0, '<Year4>-<Month,2>-<Day,2>'));
        TaskParameters.Add('EndDate', Format(EndDate, 0, '<Year4>-<Month,2>-<Day,2>'));
        TaskParameters.Add('RemainingGroupKeys', RemainingGroupKeys);

        CurrPage.EnqueueBackgroundTask(NewTaskId, Codeunit::"CPO BG Other WO Data", TaskParameters, 30000, PageBackgroundTaskErrorLevel::Warning);
        OtherWorkOrderDataTaskId := NewTaskId;
        PendingOtherWorkOrderDataAvailable := false;
        CurrPage.DhxCpoDash.NotifyOtherWorkOrderDataTaskPending();
    end;
}
