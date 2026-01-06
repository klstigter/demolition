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
                                JobTask.validate("PlannedStartDate", d);
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
                    'constraint_type':
                        begin
                            ganttConstraintType := ConvertConstraint_type(JsonValue.AsText());
                            if ganttConstraintType.AsInteger() <> JobTask."Constraint Type".AsInteger() then begin
                                JobTask.validate("Constraint Type", ganttConstraintType);
                            end;
                        end;
                    'constraint_date':
                        begin
                            d := JsonValue.AsDate();
                            if d <> JobTask."Constraint Date" then
                                JobTask.validate("Constraint Date", d);
                        end;
                end;

        end;
        exit(JobTask.Modify(true));
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
