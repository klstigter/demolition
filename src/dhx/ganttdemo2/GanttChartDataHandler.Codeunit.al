codeunit 50613 "GanttChartDataHandler"
{
    var
        GenUtils: Codeunit "General Planning Utilities";
        ParentJobTaskId: array[10] of Text;

    procedure GetDateRange(GanttSetup: Record "Gantt Chart Setup";
                           AchorDate: Date;
                           var StartDate: Date;
                           var EndDate: Date)
    var
        DHXDataHandler: Codeunit "DHX Data Handler";
    begin
        case GanttSetup."Date Range Type" of
            GanttSetup."Date Range Type"::"Date Range":
                begin
                    StartDate := GanttSetup."From Date";
                    EndDate := GanttSetup."To Date";
                end;
            GanttSetup."Date Range Type"::Weekly:
                begin
                    DHXDataHandler.GetWeekPeriodDates(AchorDate, StartDate, EndDate);
                    // x 5 weeks
                    EndDate := Calcdate('<5W>', EndDate);
                end;
            GanttSetup."Date Range Type"::Calculated:
                begin
                    GanttSetup.TestField("From Data Formula");
                    GanttSetup.TestField("To Data Formula");
                    StartDate := CalcDate(GanttSetup."From Data Formula", AchorDate);
                    EndDate := CalcDate(GanttSetup."To Data Formula", AchorDate);
                end;
        end;
        if EndDate = 0D then
            EndDate := DMY2Date(31, 12, 9999); // Far future date
        if StartDate > EndDate then
            EndDate := StartDate;
    end;

    procedure GetJobTasksAsJson(AchorDate: Date) JsonText: Text //StartDate: Date; JobNo: Code[20]
    var
        GanttSetup: Record "Gantt Chart Setup";
        JobTask: Record "Job Task";
        StartDate: Date;
        EndDate: Date;
        JsonArray: JsonArray;
        JsonObject: JsonObject;
        JobNoFilter: Code[20];
        OldJobNo: Code[20];
        OffsetDays: Integer;
        Skip: Boolean;
        Job: Record Job;
    begin
        GanttSetup.Get(UserId);
        JobNoFilter := GanttSetup."Job No. Filter";
        if JobNoFilter <> '' then
            JobTask.SetFilter("Job No.", JobNoFilter);
        GetDateRange(GanttSetup, AchorDate, StartDate, EndDate);
        JobTask.SetFilter("PlannedStartDate", '<=%1', EndDate);
        JobTask.SetFilter("PlannedEndDate", '>=%1', StartDate); // to exclude blank references
        if JobTask.FindSet() then
            repeat
                if OldJobNo <> JobTask."Job No." then begin
                    OldJobNo := JobTask."Job No.";
                    clear(ParentJobTaskId);
                end;
                Skip := (JobTask."Job Task Type" = JobTask."Job Task Type"::"End-Total") or
                     (JobTask."Job Task Type" = JobTask."Job Task Type"::"Total");
                if not skip then begin
                    JsonObject := CreateJobTaskJsonObject(JobTask);
                    JsonArray.Add(JsonObject);
                end;
            until JobTask.Next() = 0;

        JsonArray.WriteTo(JsonText);
    end;

    local procedure CreateJobTaskJsonObject(JobTask: Record "Job Task") JsonObject: JsonObject
    var
        StartDateText: Text;
        StartEndText: Text;
        ConstraintDateText: Text;
        SchedulingTypeText: Text;
    begin

        // Generate unique ID from Job No. and Job Task No.
        JsonObject.Add('id', Format(JobTask."Job No.") + '|' + Format(JobTask."Job Task No."));

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
        //JsonObject.Add('end_date', StartEndText);

        JsonObject.Add('duration', JobTask.Duration);

        // BC bindings
        JsonObject.Add('bcJobNo', JobTask."Job No.");
        JsonObject.Add('bcJobTaskNo', JobTask."Job Task No.");

        // Scheduling type (convert enum to text)
        SchedulingTypeText := GetSchedulingTypeText(JobTask."Scheduling Type");
        JsonObject.Add('schedulingType', SchedulingTypeText);

        //if JobTask."Constraint Type" <> JobTask."Constraint Type"::None then begin
        JsonObject.Add('constraint_type', GenUtils.MapConstraintTypeToDhtmlx(JobTask."Constraint Type"));  // e.g., 'fnlt' (Finish No Later Than)

        if JobTask."Constraint Type" <> JobTask."Constraint Type"::None then begin
            if JobTask."Constraint Date" <> 0D then begin
                ConstraintDateText := FormatDate(JobTask."Constraint Date");
                JsonObject.Add('constraint_date', ConstraintDateText);
            end;
            if JobTask."Constraint Is Hard" then
                JsonObject.Add('constraint_is_hard', JobTask."Constraint Is Hard");
        end;

        if JobTask."Deadline Date" <> 0D then
            JsonObject.Add('deadline', FormatDate(JobTask."Deadline Date"));

        JsonObject.Add('progress', JobTask."Progress");

        JsonObject.Add('indentation', JobTask.Indentation);
        JsonObject.Add('bold', JobTask."Job Task Type" <> jobtask."Job Task Type"::Posting);
        IF JobTask."Job Task Type" <> JobTask."Job Task Type"::Posting THEN
            ParentJobTaskId[JobTask.Indentation + 2] := Format(JobTask."Job No.") + '-' + Format(JobTask."Job Task No.");

        JsonObject.Add('parent', ParentJobTaskId[JobTask.Indentation + 1]);
    end;

    local procedure FormatDate(InputDate: Date) FormattedDate: Text
    begin
        if InputDate = 0D then
            exit('');

        FormattedDate := Format(InputDate, 0, '<Year4>-<Month,2>-<Day,2>');
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

    local procedure repairStartdate(var JobTask: Record "Job Task"; OffsetDays: Integer)
    var
        Job: Record Job;
    begin
        if Job.Get(JobTask."Job No.") then begin
            IF Job."Starting Date" <> 0D THEN
                JobTask.PlannedStartDate := CalcDate(Format(OffsetDays) + 'D', Job."Starting Date");
            JobTask.PlannedEndDate := Job."Ending Date";
            //if (jobtask.PlannedEndDate = 0D) and (JobTask.PlannedStartDate <> 0D) then
            JobTask.PlannedEndDate := CalcDate(Format(30 - OffsetDays) + 'D', JobTask.PlannedStartDate);
            JobTask."Scheduling Type" := schedulingType::FixedDuration;
            JobTask.CalculateDuration();
            JobTask.Modify()
        end;
    end;

    procedure GetResourcesAsJson() JsonText: Text
    var
        Resource: Record Resource;
        JsonArray: JsonArray;
        JsonObject: JsonObject;
    begin
        GetEmptyResourceAsJson(JsonArray);
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
        GetEmptyVendorAsJson(JsonArray);
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
        GetEmptyResourceAsJson(JsonArray);
        // Add all resources
        if Resource.FindSet() then
            repeat
                JsonObject.Add('key', 'RES-' + Resource."No.");
                JsonObject.Add('label', Resource.Name + ' (' + Resource."No." + ')');
                JsonArray.Add(JsonObject);
                Clear(JsonObject);
            until Resource.Next() = 0;
        GetEmptyVendorAsJson(JsonArray);
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

    procedure GetEmptyResourceAsJson(var JsonArray: JsonArray)
    var
        Resource: Record Resource;
        Vendor: Record Vendor;
        JsonObject: JsonObject;
    begin
        // Add all resources
        JsonObject.Add('key', 'RES-' + '');
        JsonObject.Add('label', ' - NONE - ');
        JsonArray.Add(JsonObject);
    end;

    procedure GetEmptyVendorAsJson(var JsonArray: JsonArray)
    var
        Resource: Record Resource;
        Vendor: Record Vendor;
        JsonObject: JsonObject;
    begin
        // Add all vendors
        JsonObject.Add('key', 'VEN-' + '');
        JsonObject.Add('label', ' (Vendor - - ) ');
        JsonArray.Add(JsonObject);
    end;

    procedure GetDayTasksAsJson(StartData: date) JsonText: Text
    var
        DayTask: Record "Day Tasks";
        JsonArray: JsonArray;
        JsonObject: JsonObject;
    begin
        exit(GetDayTasksAsJson(StartData, '', ''));
    end;

    procedure GetDayTasksAsJson(AnchorDate: date; JobNo: Code[20]) JsonText: Text
    var
        DayTask: Record "Day Tasks";
        JsonArray: JsonArray;
        JsonObject: JsonObject;
    begin
        exit(GetDayTasksAsJson(AnchorDate, JobNo, ''));
    end;

    procedure GetDayTasksAsJson(AnchorDate: date; JobNo: Code[20]; JobTaskNo: Code[20]) JsonText: Text
    var
        GanttSetup: Record "Gantt Chart Setup";
        DayTask: Record "Day Tasks";
        StartDate: Date;
        EndDate: Date;
        JsonArray: JsonArray;
        JsonObject: JsonObject;
        JsonArray_Task: JsonArray;
        JsonObject_Task: JsonObject;
    begin
        GanttSetup.Get(UserId);
        GetDateRange(GanttSetup, AnchorDate, StartDate, EndDate);
        if JobNo <> '' then
            DayTask.SetRange("Job No.", JobNo);
        if JobTaskNo <> '' then
            DayTask.SetRange("Job Task No.", JobTaskNo);
        if AnchorDate <> 0D then
            DayTask.Setrange("Day No.", GENUTILS.DateToInteger(StartDate), GENUTILS.DateToInteger(EndDate));

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
        JsonObject.Add('task', Format(DayTask."Job No.") + '-' + Format(DayTask."Job Task No."));
        // Day Task identifiers
        JsonObject.Add('dayNo', DayTask."Day No.");
        JsonObject.Add('dayLineNo', DayTask.DayLineNo);
        JsonObject.Add('jobNo', DayTask."Job No.");
        JsonObject.Add('jobTaskNo', DayTask."Job Task No.");
        JsonObject.Add('jobPlanningLineNo', DayTask."Job Planning Line No.");

        // Date and time information
        if DayTask."Task Date" <> 0D then
            WorkDateText := FormatDate(DayTask."Task Date")
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

        if daytask."Vendor No." <> '' then
            JsonObject.Add('vendorNo', DayTask."Vendor No.")
        else
            JsonObject.Add('vendorNo', 'null');
    end;

    local procedure FormatTime(InputTime: Time) FormattedTime: Text
    begin
        if InputTime = 0T then
            exit('');
        FormattedTime := DelChr(Format(InputTime, 0, '<Hours24,2>:<Minutes,2>:<Seconds,2>'), '<>', '');
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


