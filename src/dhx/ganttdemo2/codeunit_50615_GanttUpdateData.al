codeunit 50615 "Gantt Update Data"
{
    procedure UpdateJobTaskFromJson(JsonText: Text; var PreviewCancelledByUser: Boolean): Boolean
    var
        JobTask: Record "Job Task";
        JsonObject: JsonObject;
        JsonToken: JsonToken;
        JobNo: Code[20];
        JobTaskNo: Code[20];
        Description: Text[100];
        JsonKey: text;
        JsonValue: JsonValue;
        D: Date;
        SchedulingType: Enum "schedulingType";
        ganttConstraintType: Enum "Gantt Constraint Type";
        OldStartDate: Date;
        OldEndDate: Date;
        NewStartDate: Date;
        NewEndDate: Date;
        DayPlanningPeriodSyncMgt: Codeunit "DayPlanning Period Sync Mgt.";
    begin
        if not JsonObject.ReadFrom(JsonText) then
            exit(false);

        if JsonObject.Get('bcJobNo', JsonToken) then
            JobNo := CopyStr(JsonToken.AsValue().AsCode(), 1, MaxStrLen(JobNo));

        if JsonObject.Get('bcJobTaskNo', JsonToken) then
            JobTaskNo := CopyStr(JsonToken.AsValue().AsCode(), 1, MaxStrLen(JobTaskNo));

        if not JobTask.Get(JobNo, JobTaskNo) then
            exit(false);

        // Capture old dates before any changes
        OldStartDate := JobTask.PlannedStartDate;
        OldEndDate := JobTask.PlannedEndDate;

        foreach JsonKey in JsonObject.Keys do begin
            JsonObject.Get(JsonKey, JsonToken);
            JsonValue := JsonToken.AsValue();
            if not JsonValue.IsNull() then
                case JsonKey of
                    'id':
                        ; // Ignore ID field
                    'bcJobNo':
                        JobNo := JsonValue.AsCode();
                    'bcJobTaskNo':
                        begin
                            JobTask.get(JobNo, JobTaskNo);
                            JobTaskNo := JsonToken.AsValue().AsCode();
                        end;
                    'text':
                        begin
                            Description := CopyStr(JsonValue.AsText(), 1, MaxStrLen(Description));
                            // GanttChartDataHandler prefixes Posting tasks with "TaskNo - " for display
                            // (e.g. "2010 - Spare Parts Procurement"). Strip that prefix here so it is
                            // never written back to Description, preventing the accumulation bug.
                            if CopyStr(Description, 1, StrLen(JobTask."Job Task No.") + 3) = JobTask."Job Task No." + ' - ' then
                                Description := CopyStr(Description, StrLen(JobTask."Job Task No.") + 4, MaxStrLen(Description));
                            JobTask.Description := Description;
                        end;
                    'start_date':
                        begin
                            d := JsonValue.AsDate();
                            if d <> JobTask."PlannedStartDate" then
                                JobTask."PlannedStartDate" := d;
                        end;
                    'end_date':
                        begin
                            d := CalcDate('<-1D>', JsonValue.AsDate());
                            if d <> JobTask."PlannedEndDate" then
                                JobTask."PlannedEndDate" := d;
                        end;
                    'duration':
                        begin
                            // Duration is in days
                            if JsonValue.AsInteger() <> JobTask."Duration" then begin
                                JobTask.validate("Duration", JsonValue.AsInteger());
                            end;
                        end;
                    'schedulingType':
                        begin
                            SchedulingType := ConvertSchedulingType(JsonValue.AsText());
                            if SchedulingType.AsInteger() <> JobTask."Scheduling Type".AsInteger() then begin
                                JobTask.validate("Scheduling Type", SchedulingType);
                            end;
                        end;
                end;
        end;

        // Read new dates from the in-memory JobTask BEFORE any Modify call.
        // JobTask.Modify() is deferred: it only happens when the user confirms (or
        // immediately when no DayPlanning records are affected).
        NewStartDate := JobTask.PlannedStartDate;
        NewEndDate := JobTask.PlannedEndDate;

        // The requested new end date must never land on a non-working day (holiday/weekend):
        // snap it forward to the next active workday before it's used anywhere downstream
        // (HandleJobTaskPeriodChange/CalculateChanges, the Scenario A new-entry walk, and the
        // no-DayPlanning-affected fallback below). Only when the end date is actually being
        // changed by this operation - an unrelated left-only drag must not touch an
        // already-existing boundary that wasn't part of this operation.
        if (NewEndDate <> 0D) and (NewEndDate <> OldEndDate) then begin
            NewEndDate := DayPlanningPeriodSyncMgt.SnapForwardToWorkDay(JobTask, NewEndDate);
            JobTask.PlannedEndDate := NewEndDate;
            JobTask.CalculateDuration();
        end;

        if ((NewStartDate <> 0D) or (NewEndDate <> 0D)) and
           ((NewStartDate <> OldStartDate) or (NewEndDate <> OldEndDate)) then begin
            // Period changed: open preview page. Returns FALSE if user cancelled
            // → neither JobTask nor DayPlanning records are written to the database.
            if DayPlanningPeriodSyncMgt.HandleJobTaskPeriodChange(JobTask, OldStartDate, OldEndDate, false) then begin
                // Re-read to get the latest record timestamp/values. When DayPlanning rows were
                // affected, HandleJobTaskPeriodChange already ran ApplyChanges (Modify + Commit)
                // - including ExtendJobTaskEndDateIfNeeded, which can raise PlannedEndDate beyond
                // NewEndDate to cover a cascade overshoot. Only fall back to writing NewStartDate/
                // NewEndDate ourselves when that path did NOT already persist them (i.e. no
                // DayPlanning rows were affected, so HandleJobTaskPeriodChange returned early
                // without ever calling ApplyChanges) - and never shrink PlannedEndDate back down,
                // which would silently re-introduce the very out-of-scope DayPlanning rows the
                // extension was there to prevent.
                JobTask.Get(JobTask."Job No.", JobTask."Job Task No.");
                if (JobTask.PlannedStartDate <> NewStartDate) or (JobTask.PlannedEndDate < NewEndDate) then begin
                    if JobTask.PlannedStartDate <> NewStartDate then
                        JobTask.PlannedStartDate := NewStartDate;
                    if JobTask.PlannedEndDate < NewEndDate then
                        JobTask.PlannedEndDate := NewEndDate;
                    JobTask.Duration := JobTask.PlannedEndDate - JobTask.PlannedStartDate + 1;
                    JobTask.Modify();
                end;
            end else begin
                PreviewCancelledByUser := true;
                exit(false);
            end;
        end else begin
            // No period change: save immediately for other field changes (description, etc.)
            if not JobTask.Modify(true) then
                exit(false);
        end;

        exit(true);
    end;

    /// <summary>
    /// Persists only the Job Task's Planned Start/End Date from a dhtmlx drag/resize payload,
    /// deliberately bypassing DayPlanning Period Sync entirely - no DayPlanning record is
    /// read, moved, or created. Used when the user closed the DayPlanning Period Change
    /// Preview without clicking Apply Changes but still wants the task's own planned period
    /// to reflect the drag.
    /// </summary>
    procedure ApplyPlannedDatesOnly(JsonText: Text): Boolean
    var
        JobTask: Record "Job Task";
        DayPlanning: Record "Day Planning";
        JsonObject: JsonObject;
        JsonToken: JsonToken;
        JobNo: Code[20];
        JobTaskNo: Code[20];
        JsonKey: Text;
        JsonValue: JsonValue;
        D: Date;
    begin
        if not JsonObject.ReadFrom(JsonText) then
            exit(false);

        if JsonObject.Get('bcJobNo', JsonToken) then
            JobNo := CopyStr(JsonToken.AsValue().AsCode(), 1, MaxStrLen(JobNo));
        if JsonObject.Get('bcJobTaskNo', JsonToken) then
            JobTaskNo := CopyStr(JsonToken.AsValue().AsCode(), 1, MaxStrLen(JobTaskNo));

        if not JobTask.Get(JobNo, JobTaskNo) then
            exit(false);

        foreach JsonKey in JsonObject.Keys do begin
            JsonObject.Get(JsonKey, JsonToken);
            JsonValue := JsonToken.AsValue();
            if not JsonValue.IsNull() then
                case JsonKey of
                    'start_date':
                        begin
                            D := JsonValue.AsDate();
                            if D <> JobTask.PlannedStartDate then
                                JobTask.PlannedStartDate := D;
                        end;
                    'end_date':
                        begin
                            D := CalcDate('<-1D>', JsonValue.AsDate());
                            if D <> JobTask.PlannedEndDate then
                                JobTask.PlannedEndDate := D;
                        end;
                end;
        end;

        // Since the user just declined the DayPlanning Period Change Preview's cascade
        // (Apply Changes was not clicked), no existing Day Planning row may be relocated
        // here. If the new Planned Start/End Date period would leave any existing Day
        // Planning row's Plan Date outside that period, it would become silently orphaned
        // - stranded outside the task's own planned period with no record of it. Refuse to
        // save in that case instead of leaving Day Planning data inconsistent.
        if (JobTask.PlannedStartDate <> 0D) and (JobTask.PlannedEndDate <> 0D) then begin
            DayPlanning.SetRange("Job No.", JobTask."Job No.");
            DayPlanning.SetRange("Job Task No.", JobTask."Job Task No.");
            DayPlanning.SetFilter("Plan Date", '<%1|>%2', JobTask.PlannedStartDate, JobTask.PlannedEndDate);
            if DayPlanning.FindFirst() then
                Error(DayPlanningOutOfRangeErr, JobTask.PlannedStartDate, JobTask.PlannedEndDate, DayPlanning."Plan Date");
        end;

        JobTask.CalculateDuration();
        exit(JobTask.Modify(true));
    end;

    /// <summary>
    /// TryFunction wrapper around ApplyPlannedDatesOnly so callers can catch the
    /// Day Planning out-of-range Error() via GetLastErrorText() instead of having it
    /// abort the caller outright.
    /// </summary>
    [TryFunction]
    procedure TryApplyPlannedDatesOnly(JsonText: Text)
    begin
        ApplyPlannedDatesOnly(JsonText);
    end;

    // Related to Duration / Progress
    local procedure ConvertSchedulingType(value: text) schedulingType: Enum "schedulingType"
    begin
        case value of
            'fixed_duration':
                exit(schedulingType::FixedDuration);
            //TODO: re-enable when we support Fixed Units scheduling type in the UI
            // 'fixed_units':
            //     exit(schedulingType::FixedUnits);
            'fixed_work':
                exit(schedulingType::FixedWork);
            else
                exit(schedulingType::FixedDuration);
        end;
    end;

    // Related to start -end date
    local procedure ConvertConstraint_type(value: text) ganttConstraintType: Enum "Gantt Constraint Type"
    begin
        case value of
            '':
                exit(ganttConstraintType::None);
            'must_start_on':
                exit(ganttConstraintType::"Must Start On");
            'must_finish_on':
                exit(ganttConstraintType::"Must Finish On");
            'start_no_earlier_than':
                exit(ganttConstraintType::"Start No Earlier Than");
            'start_no_later_than':
                exit(ganttConstraintType::"Start No Later Than");
            'finish_no_earlier_than':
                exit(ganttConstraintType::"Finish No Earlier Than");
            'finish_no_later_than':
                exit(ganttConstraintType::"Finish No Later Than");
        end;
    end;

    var
        DayPlanningOutOfRangeErr: Label 'Cannot update the Planned Start Date and Planned End Date to %1..%2 because a Day Planning entry exists on %3, which would fall outside that period. Use Apply Changes in the DayPlanning Period Change Preview instead so the affected Day Planning entries can be relocated.';
}
