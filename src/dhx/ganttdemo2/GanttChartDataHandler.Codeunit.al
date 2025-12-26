codeunit 50613 "GanttChartDataHandler"
{
    procedure GetJobTasksAsJson() JsonText: Text
    var
        JobTask: Record "Job Task";
        JsonArray: JsonArray;
        JsonObject: JsonObject;
    begin
        if JobTask.FindSet() then
            repeat
                JsonObject := CreateJobTaskJsonObject(JobTask);
                JsonArray.Add(JsonObject);
            until JobTask.Next() = 0;

        JsonArray.WriteTo(JsonText);
    end;

    procedure GetJobTasksAsJson(JobNo: Code[20]) JsonText: Text
    var
        JobTask: Record "Job Task";
        JsonArray: JsonArray;
        JsonObject: JsonObject;
    begin
        JobTask.SetRange("Job No.", JobNo);
        if JobTask.FindSet() then
            repeat
                JsonObject := CreateJobTaskJsonObject(JobTask);
                JsonArray.Add(JsonObject);
            until JobTask.Next() = 0;

        JsonArray.WriteTo(JsonText);
    end;

    local procedure CreateJobTaskJsonObject(JobTask: Record "Job Task") JsonObject: JsonObject
    var
        Duration: Integer;
        StartDateText: Text;
        StartEndText: Text;
        ConstraintDateText: Text;
        SchedulingTypeText: Text;
    begin
        repairStartdate(JobTask);
        // Generate unique ID from Job No. and Job Task No.
        JsonObject.Add('id', Format(JobTask."Job No.") + '-' + Format(JobTask."Job Task No."));


        // Task description
        JsonObject.Add('text', JobTask.Description);

        // Start date (format: dd-MM-yyyy)
        if JobTask.PlannedStartDate <> 0D then
            StartDateText := FormatDate(JobTask.PlannedStartDate)
        else
            StartDateText := '';
        JsonObject.Add('start_date', StartDateText);

        if JobTask.PlannedEndDate <> 0D then
            StartEndText := FormatDate(JobTask.PlannedEndDate)
        else
            StartEndText := '';
        JsonObject.Add('end_date', StartEndText);


        // Duration (calculated from start and end dates)
        Duration := JobTask.CalculateDuration();
        JsonObject.Add('duration', Duration);

        // BC bindings
        JsonObject.Add('bcJobNo', JobTask."Job No.");
        JsonObject.Add('bcJobTaskNo', JobTask."Job Task No.");

        // Scheduling type (convert enum to text)
        SchedulingTypeText := GetSchedulingTypeText(JobTask."Scheduling Type");
        JsonObject.Add('schedulingType', SchedulingTypeText);

        // Constraint type and date (placeholder values - customize as needed)
        // You can add custom fields to Job Task table if you need to store constraint info
        JsonObject.Add('constraint_type', '');  // e.g., 'fnlt' (Finish No Later Than)

        if JobTask.PlannedEndDate <> 0D then
            ConstraintDateText := FormatDate(JobTask.PlannedEndDate)
        else
            ConstraintDateText := '';
        JsonObject.Add('constraint_date', ConstraintDateText);
    end;

    local procedure FormatDate(InputDate: Date) FormattedDate: Text
    begin
        if InputDate = 0D then
            exit('');

        FormattedDate := Format(InputDate, 0, '<Day>-<Month>-<Year4>');
    end;



    local procedure GetSchedulingTypeText(SchedulingType: Enum schedulingType) SchedulingTypeText: Text
    begin
        case SchedulingType of
            SchedulingType::FixedDuration:
                SchedulingTypeText := 'fixed_duration';
            SchedulingType::FixedUnits:
                SchedulingTypeText := 'fixed_units';
            SchedulingType::FixedWork:
                SchedulingTypeText := 'fixed_work';
            else
                SchedulingTypeText := '';
        end;
    end;

    local procedure repairStartdate(var JobTask: Record "Job Task")
    var
        Job: Record Job;
    begin
        if Job.Get(JobTask."Job No.") then begin
            JobTask.PlannedStartDate := Job."Starting Date";
            JobTask.PlannedEndDate := Job."Ending Date";
            if (jobtask.PlannedEndDate = 0D) and (JobTask.PlannedStartDate <> 0D) then
                JobTask.PlannedEndDate := CalcDate('+90D', JobTask.PlannedStartDate);
            JobTask.Modify()
        end;
    end;

    procedure GetResourcesAsJson() JsonText: Text
    var
        Resource: Record Resource;
        JsonArray: JsonArray;
        JsonObject: JsonObject;
    begin
        if Resource.FindSet() then
            repeat
                JsonObject.Add('key', 'RES-' + Resource."No.");
                JsonObject.Add('label', Resource.Name + ' (' + Resource."No." + ')');
                JsonArray.Add(JsonObject);
                Clear(JsonObject);
            until Resource.Next() = 0;

        JsonArray.WriteTo(JsonText);
    end;

    procedure GetVendorsAsJson() JsonText: Text
    var
        Vendor: Record Vendor;
        JsonArray: JsonArray;
        JsonObject: JsonObject;
    begin
        if Vendor.FindSet() then
            repeat
                JsonObject.Add('key', 'VEN-' + Vendor."No.");
                JsonObject.Add('label', Vendor.Name + ' (Vendor ' + Vendor."No." + ')');
                JsonArray.Add(JsonObject);
                Clear(JsonObject);
            until Vendor.Next() = 0;

        JsonArray.WriteTo(JsonText);
    end;

    procedure GetResourcesAndVendorsAsJson() JsonText: Text
    var
        Resource: Record Resource;
        Vendor: Record Vendor;
        JsonArray: JsonArray;
        JsonObject: JsonObject;
    begin
        // Add all resources
        if Resource.FindSet() then
            repeat
                JsonObject.Add('key', 'RES-' + Resource."No.");
                JsonObject.Add('label', Resource.Name + ' (' + Resource."No." + ')');
                JsonArray.Add(JsonObject);
                Clear(JsonObject);
            until Resource.Next() = 0;

        // Add all vendors
        if Vendor.FindSet() then
            repeat
                JsonObject.Add('key', 'VEN-' + Vendor."No.");
                JsonObject.Add('label', Vendor.Name + ' (Vendor ' + Vendor."No." + ')');
                JsonArray.Add(JsonObject);
                Clear(JsonObject);
            until Vendor.Next() = 0;

        JsonArray.WriteTo(JsonText);
    end;

    procedure GetDayTasksAsJson() JsonText: Text
    var
        DayTask: Record "Day Tasks";
        JsonArray: JsonArray;
        JsonObject: JsonObject;
    begin
        if DayTask.FindSet() then
            repeat
                JsonObject := CreateDayTaskJsonObject(DayTask);
                JsonArray.Add(JsonObject);
            until DayTask.Next() = 0;

        JsonArray.WriteTo(JsonText);
    end;

    procedure GetDayTasksAsJson(JobNo: Code[20]) JsonText: Text
    var
        DayTask: Record "Day Tasks";
        JsonArray: JsonArray;
        JsonObject: JsonObject;
    begin
        DayTask.SetRange("Job No.", JobNo);
        if DayTask.FindSet() then
            repeat
                JsonObject := CreateDayTaskJsonObject(DayTask);
                JsonArray.Add(JsonObject);
            until DayTask.Next() = 0;

        JsonArray.WriteTo(JsonText);
    end;

    procedure GetDayTasksAsJson(JobNo: Code[20]; JobTaskNo: Code[20]) JsonText: Text
    var
        DayTask: Record "Day Tasks";
        JsonArray: JsonArray;
        JsonObject: JsonObject;
    begin
        DayTask.SetRange("Job No.", JobNo);
        DayTask.SetRange("Job Task No.", JobTaskNo);
        if DayTask.FindSet() then
            repeat
                JsonObject := CreateDayTaskJsonObject(DayTask);
                JsonArray.Add(JsonObject);
            until DayTask.Next() = 0;

        JsonArray.WriteTo(JsonText);
    end;

    local procedure CreateDayTaskJsonObject(DayTask: Record "Day Tasks") JsonObject: JsonObject
    var
        WorkDateText: Text;
        StartTimeText: Text;
        EndTimeText: Text;
        ResourceId: Text;
        TypeText: Text;
    begin
        // SystemId as unique ID
        JsonObject.Add('id', Format(DayTask.SystemId));

        // Day Task identifiers
        JsonObject.Add('dayNo', DayTask."Day No.");
        JsonObject.Add('dayLineNo', DayTask.DayLineNo);
        JsonObject.Add('jobNo', DayTask."Job No.");
        JsonObject.Add('jobTaskNo', DayTask."Job Task No.");
        JsonObject.Add('jobPlanningLineNo', DayTask."Job Planning Line No.");

        // Date and time information
        if DayTask."Start Planning Date" <> 0D then
            WorkDateText := FormatDate(DayTask."Start Planning Date")
        else
            WorkDateText := '';
        JsonObject.Add('work_date', WorkDateText);

        StartTimeText := FormatTime(DayTask."Start Time");
        JsonObject.Add('start_time', StartTimeText);

        EndTimeText := FormatTime(DayTask."End Time");
        JsonObject.Add('end_time', EndTimeText);

        JsonObject.Add('hours', DayTask."Working Hours");

        // Resource/Vendor information
        ResourceId := GetResourceId(DayTask);
        JsonObject.Add('resource_id', ResourceId);

        TypeText := GetDayTaskTypeText(DayTask.Type);
        JsonObject.Add('type', TypeText);

        JsonObject.Add('vendorNo', DayTask."Vendor No.");
    end;

    local procedure FormatTime(InputTime: Time) FormattedTime: Text
    begin
        if InputTime = 0T then
            exit('');
        FormattedTime := DelChr(Format(InputTime, 0, '<Hours24,2>:<Minutes>:<Seconds,2>'), '<>', '');
    end;

    local procedure GetResourceId(DayTask: Record "Day Tasks") ResourceId: Text
    begin
        if DayTask."No." <> '' then begin
            case DayTask.Type of
                DayTask.Type::Resource:
                    ResourceId := 'RES-' + DayTask."No.";
                DayTask.Type::Item:
                    ResourceId := 'ITEM-' + DayTask."No.";
                DayTask.Type::"G/L Account":
                    ResourceId := 'GL-' + DayTask."No.";
                else
                    ResourceId := 'UNASSIGNED';
            end;
        end else
            ResourceId := 'UNASSIGNED';
    end;

    local procedure GetDayTaskTypeText(DayTaskType: Enum "Job Planning Line Type") TypeText: Text
    begin
        case DayTaskType of
            DayTaskType::Resource:
                TypeText := 'Resource';
            DayTaskType::Item:
                TypeText := 'Item';
            DayTaskType::"G/L Account":
                TypeText := 'G/L Account';
            DayTaskType::Text:
                TypeText := 'Text';
            else
                TypeText := '';
        end;
    end;

}


