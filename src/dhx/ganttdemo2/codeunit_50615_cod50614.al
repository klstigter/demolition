codeunit 50615 "Gantt Update Data"
{
    procedure UpdateJobTaskFromJson(JsonText: Text): Boolean
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
                            d := JsonValue.AsDate();
                            if d <> JobTask."PlannedEndDate" then
                                JobTask.validate("PlannedEndDate", d);
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

        if not JobTask.Modify(true) then
            exit(false);

        // Synchronise DayTask dates whenever the planned period changed
        NewStartDate := JobTask.PlannedStartDate;
        NewEndDate := JobTask.PlannedEndDate;
        if (NewStartDate <> 0D) or (NewEndDate <> 0D) then
            if (NewStartDate <> OldStartDate) or (NewEndDate <> OldEndDate) then
                SyncDayTaskDates(JobNo, JobTaskNo, NewStartDate, NewEndDate);

        exit(true);
    end;

    /// <summary>
    /// Clamps every DayTask for (JobNo, JobTaskNo) into the new [NewStart, NewEnd] window.
    ///
    /// Rule:
    ///   DayTask.TaskDate less than NewStart - move to NewStart (or next working day)
    ///   DayTask.TaskDate greater than NewEnd - move to NewEnd (or prev working day)
    ///   Otherwise - keep as-is
    /// </summary>
    local procedure SyncDayTaskDates(JobNo: Code[20]; JobTaskNo: Code[20]; NewStart: Date; NewEnd: Date)
    var
        DayTask: Record "Day Tasks";
        DayTaskMgt: Codeunit "Day Tasks Mgt.";
        TargetDate: Date;
    begin
        DayTask.SetRange("Job No.", JobNo);
        DayTask.SetRange("Job Task No.", JobTaskNo);
        if not DayTask.FindSet(true) then
            exit;

        repeat
            TargetDate := DayTask."Task Date";

            // Clamp below
            if (NewStart <> 0D) and (TargetDate < NewStart) then
                TargetDate := FindNextWorkingDay(NewStart, NewEnd, DayTaskMgt);

            // Clamp above
            if (NewEnd <> 0D) and (TargetDate > NewEnd) then
                TargetDate := FindPrevWorkingDay(NewEnd, NewStart, DayTaskMgt);

            if TargetDate <> DayTask."Task Date" then begin
                DayTask."Task Date" := TargetDate;
                DayTask.Modify();
            end;
        until DayTask.Next() = 0;
    end;

    /// <summary>
    /// Returns the first working day on or after AnchorDate, not exceeding MaxDate.
    /// Returns AnchorDate itself if it is already a working day.
    /// Returns AnchorDate unchanged if no working day found within range (caller handles edge case).
    /// </summary>
    local procedure FindNextWorkingDay(AnchorDate: Date; MaxDate: Date; var DayTaskMgt: Codeunit "Day Tasks Mgt."): Date
    var
        Candidate: Date;
    begin
        Candidate := AnchorDate;
        while Candidate <= MaxDate do begin
            if DayTaskMgt.CheckIsWorkingDay(Candidate) then
                exit(Candidate);
            Candidate := CalcDate('<+1D>', Candidate);
        end;
        exit(AnchorDate); // fallback – AnchorDate even if not a working day
    end;

    /// <summary>
    /// Returns the last working day on or before AnchorDate, not before MinDate.
    /// Returns AnchorDate itself if it is already a working day.
    /// </summary>
    local procedure FindPrevWorkingDay(AnchorDate: Date; MinDate: Date; var DayTaskMgt: Codeunit "Day Tasks Mgt."): Date
    var
        Candidate: Date;
    begin
        Candidate := AnchorDate;
        while Candidate >= MinDate do begin
            if DayTaskMgt.CheckIsWorkingDay(Candidate) then
                exit(Candidate);
            Candidate := CalcDate('<-1D>', Candidate);
        end;
        exit(AnchorDate); // fallback
    end;

    local procedure ConvertSchedulingType(value: text) schedulingType: Enum "schedulingType"
    begin
        case value of
            'fixed_duration':
                exit(schedulingType::FixedDuration);
            'fixed_units':
                exit(schedulingType::FixedUnits);
            'fixed_work':
                exit(schedulingType::FixedWork);
            else
                exit(schedulingType::FixedDuration);
        end;
    end;

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
}
