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
                    // 2026-09-04: real persistence, replacing what used to be a stub (first a
                    // blocking Message() dialog, then nothing at all - see PersistReschedule's own
                    // doc comment). DayShift itself is unused now (sent as 0) - section 2's drag
                    // moved from one shared woAnchor to, eventually, each INDIVIDUAL Day Planning
                    // occurrence having its own independent day-index, so a single flat DayShift can
                    // no longer describe the whole reschedule; PayloadJsonTxt now carries the real
                    // data, one {job,task,skill,sequenceNo,fromDate,shift} entry per occurrence that
                    // actually moved.
                    PersistReschedule(PayloadJsonTxt);
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
    /// Persists a confirmed reschedule (JS's Confirm changes button - capacityPlanningOverview.js's
    /// confirmChanges/bindConfirmButton) by shifting each INDIVIDUALLY-moved Day Planning
    /// OCCURRENCE's own "Plan Date" forward/backward by ITS OWN shift amount, in calendar days.
    /// This is v1 - "just shift Plan Date" (explicit user decision, 2026-09-04) - it does not
    /// attempt to replicate the JS side's workday-offset (idxWork) placement logic server-side, and
    /// does not re-check resource/capacity availability at the new date; both are documented,
    /// deliberate scope cuts for a first working version, not oversights.
    ///
    /// PayloadJsonTxt shape: {"shifts":[{"job":"...","task":"...","skill":"...","sequenceNo":N,
    /// "fromDate":"yyyy-MM-dd","shift":N},...]} - one entry per individual OCCURRENCE that actually
    /// moved (capacityPlanningOverview.js only includes an occurrence here if its own day-index
    /// differs from its natural, never-moved position; dragging one bar in section 2 no longer
    /// moves any other occurrence, even of the SAME sequence - see that file's own
    /// occurrenceAnchors doc comment for why sequence-row granularity still wasn't fine enough).
    /// `fromDate` is what narrows Job/Task/Skill/SequenceNo (which alone can match SEVERAL lines,
    /// one per occurrence) down to the ONE line that was actually at that date when the user
    /// dragged it - without it, this would shift every occurrence of the sequence by the same
    /// amount again, exactly the bug this replaced. Each entry's job/task/skill/sequenceNo already
    /// come from workOrderSequences[], itself built (codeunit 50604) scoped to exactly this WO's own
    /// Day Planning rows - no separate Job No./Job Task No. re-derivation from the Work Order header
    /// is needed here.
    ///
    /// Runs entirely inside this one trigger call (implicit transaction) - if Validate("Plan Date",
    /// ...) errors on any row (e.g. outside the Job Task's own date range), the whole reschedule
    /// rolls back and the error surfaces natively; no partial-success handling in this v1.
    /// RefreshData() at the end re-pushes the now-persisted state as a fresh payload, which resets
    /// every occurrence's anchor override on the JS side - the persisted dates become the new
    /// baseline for the NEXT reschedule, so a shift is always relative to what's actually in the
    /// database, never compounding across multiple confirms.
    /// </summary>
    local procedure PersistReschedule(PayloadJsonTxt: Text)
    var
        DayPlanning: Record "Day Planning";
        PayloadJObj: JsonObject;
        ShiftsJArr: JsonArray;
        ShiftJToken: JsonToken;
        ShiftJObj: JsonObject;
        FieldJToken: JsonToken;
        JobNo: Code[20];
        JobTaskNo: Code[20];
        SkillCode: Code[20];
        SequenceNoInt: Integer;
        ToSequenceNoInt: Integer;
        HasToSequenceNo: Boolean;
        FromDateTxt: Text;
        FromDate: Date;
        FromYear: Integer;
        FromMonth: Integer;
        FromDay: Integer;
        ShiftDays: Integer;
        AnyShiftApplied: Boolean;
    begin
        if (GWorkOrderNo = '') or (PayloadJsonTxt = '') then
            exit;
        if not PayloadJObj.ReadFrom(PayloadJsonTxt) then
            exit;
        if not PayloadJObj.Get('shifts', FieldJToken) then
            exit;
        ShiftsJArr := FieldJToken.AsArray();

        foreach ShiftJToken in ShiftsJArr do begin
            ShiftJObj := ShiftJToken.AsObject();
            JobNo := ''; JobTaskNo := ''; SkillCode := ''; SequenceNoInt := 0; ShiftDays := 0;
            FromDateTxt := ''; FromDate := 0D; ToSequenceNoInt := 0; HasToSequenceNo := false;

            if ShiftJObj.Get('job', FieldJToken) then
                JobNo := CopyStr(FieldJToken.AsValue().AsText(), 1, MaxStrLen(JobNo));
            if ShiftJObj.Get('task', FieldJToken) then
                JobTaskNo := CopyStr(FieldJToken.AsValue().AsText(), 1, MaxStrLen(JobTaskNo));
            if ShiftJObj.Get('skill', FieldJToken) then
                SkillCode := CopyStr(FieldJToken.AsValue().AsText(), 1, MaxStrLen(SkillCode));
            // Always a JSON number (capacityPlanningOverview.js sends Number(seq.sequenceNo) || 0,
            // never the '' fallback used elsewhere in that file for display) - matches Day
            // Planning's own "Sequence No." field (Integer, blank/unset = 0), no string/number
            // branching needed here.
            if ShiftJObj.Get('sequenceNo', FieldJToken) then
                SequenceNoInt := FieldJToken.AsValue().AsInteger();
            // "yyyy-MM-dd" (cpoFormatDateOnly, JS-side) - parsed via explicit Y/M/D substrings
            // + DMY2Date rather than Evaluate(Date,...), which is locale-sensitive without an
            // explicit format code; this way is unambiguous regardless of user/server locale.
            if ShiftJObj.Get('fromDate', FieldJToken) then begin
                FromDateTxt := FieldJToken.AsValue().AsText();
                if StrLen(FromDateTxt) = 10 then
                    if Evaluate(FromYear, CopyStr(FromDateTxt, 1, 4)) and Evaluate(FromMonth, CopyStr(FromDateTxt, 6, 2))
                        and Evaluate(FromDay, CopyStr(FromDateTxt, 9, 2))
                    then
                        FromDate := DMY2Date(FromDay, FromMonth, FromYear);
            end;
            if ShiftJObj.Get('shift', FieldJToken) then
                ShiftDays := FieldJToken.AsValue().AsInteger();
            // Optional - only present when this occurrence was also dragged onto a DIFFERENT
            // sequence row client-side (moveOccurrenceToSequence/pendingSequenceMoves, 2026-09-04:
            // "move single day planning from sequence 2 into sequence 1"). `sequenceNo` above still
            // identifies the record to find (its TRUE current Sequence No. in BC); this is only the
            // NEW value to assign it.
            if ShiftJObj.Get('toSequenceNo', FieldJToken) then begin
                ToSequenceNoInt := FieldJToken.AsValue().AsInteger();
                HasToSequenceNo := ToSequenceNoInt <> SequenceNoInt;
            end;

            if (JobNo <> '') and (JobTaskNo <> '') and (FromDate <> 0D) and ((ShiftDays <> 0) or HasToSequenceNo) then begin
                DayPlanning.Reset();
                DayPlanning.SetRange("Job No.", JobNo);
                DayPlanning.SetRange("Job Task No.", JobTaskNo);
                DayPlanning.SetRange(Skill, SkillCode);
                DayPlanning.SetRange("Sequence No.", SequenceNoInt);
                DayPlanning.SetRange("Plan Date", FromDate);
                if DayPlanning.FindSet(true) then
                    repeat
                        if HasToSequenceNo then
                            DayPlanning.Validate("Sequence No.", ToSequenceNoInt);
                        if ShiftDays <> 0 then
                            DayPlanning.Validate("Plan Date", DayPlanning."Plan Date" + ShiftDays);
                        DayPlanning.Modify(true);
                        AnyShiftApplied := true;
                    until DayPlanning.Next() = 0;
            end;
        end;

        if AnyShiftApplied then
            RefreshData();
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
