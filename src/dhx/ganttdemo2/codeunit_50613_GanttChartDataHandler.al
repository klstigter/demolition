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

    procedure GetJobTasksAsJson(AchorDate: Date; pJobFilter: Text) JsonText: Text //StartDate: Date; JobNo: Code[20]
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
        if pJobFilter <> '' then
            JobNoFilter := pJobFilter;
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
        Color: record "Planning Color Opt.";
        ColorTxt: Text;
        StartDateText: Text;
        StartEndText: Text;
        ConstraintDateText: Text;
        SchedulingTypeText: Text;
        Codevar: Code[20];
    begin

        JsonObject.Add('id', Format(JobTask."Job No.") + '|' + Format(JobTask."Job Task No."));
        JsonObject.Add('text', (JobTask."Job Task Type" = JobTask."Job Task Type"::Posting ? JobTask."Job Task No." + ' - ' : '') + JobTask.Description);
        // Start date (format: dd-MM-yyyy)
        if JobTask.PlannedStartDate <> 0D then
            StartDateText := FormatDate(JobTask.PlannedStartDate)
        else
            StartDateText := '';
        JsonObject.Add('start_date', StartDateText);
        JsonObject.Add('duration', JobTask.Duration);
        JsonObject.Add('bcJobNo', JobTask."Job No.");
        JsonObject.Add('bcJobTaskNo', JobTask."Job Task No.");
        SchedulingTypeText := GetSchedulingTypeText(JobTask."Scheduling Type");
        JsonObject.Add('schedulingType', SchedulingTypeText);

        JsonObject.Add('progress', JobTask."Progress" / 100); // Convert percentage to a value between 0 and 1

        // TODO: Replace with a real color field from Job Task or a setup/color table.
        // For now, send a dummy color so the Gantt task bar and progress fill are colored.
        // When you have a "Color" field (e.g., Job."Color" or a Job Color setup), replace this line:
        //   JsonObject.Add('color', Job."Color");
        // The progressColor (darker shade) is automatically derived in JS from this value.
        ColorTxt := '#3b8ef0';
        // Check setting color for project task type.
        if evaluate(Codevar, Format(JobTask."Job Task Type")) then
            if Color.Get(Color.Type::"Project Task Type", Codevar, '', '') then
                if Color.Task <> '' then
                    ColorTxt := Color.Task;
        // setting color on Task is mandatory.
        if Color.Get(Color.Type::Task, JobTask."Job Task No.", JobTask."Job No.") then
            if Color.Task <> '' then
                ColorTxt := Color.Task;

        JsonObject.Add('color', ColorTxt); // dummy: blue. Replace with real BC field later.

        JsonObject.Add('indentation', JobTask.Indentation);
        JsonObject.Add('bold', JobTask."Job Task Type" <> jobtask."Job Task Type"::Posting);
        IF JobTask."Job Task Type" <> JobTask."Job Task Type"::Posting THEN begin
            ParentJobTaskId[JobTask.Indentation + 2] := Format(JobTask."Job No.") + '|' + Format(JobTask."Job Task No.");
            JsonObject.Add('open', true); // tell DHTMLX to render this parent row expanded
        end;
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
            //TODO
            // SchedulingType::FixedUnits:
            //     SchedulingTypeText := 'fixed_units';
            SchedulingType::FixedWork:
                SchedulingTypeText := 'fixed_work';
            else
                SchedulingTypeText := '';
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

    // Returns only resources assigned to the given Job Task via Day Tasks.
    // Falls back to all resources if no Day Task assignments exist.
    /// <summary>
    /// Returns day task JSON for all job tasks in the marked set, filtered to FromDate..ToDate.
    /// Used to reload only the relevant events in the resource panel when the user
    /// right-clicks a task in the Gantt → Show Job Resources.
    /// </summary>
    procedure GetDayTasksByJobTaskAsJson(var JobTask: Record "Job Task"; FromDate: Date; ToDate: Date) JsonText: Text
    var
        DayTask: Record "Day Tasks";
        JsonArray: JsonArray;
        JsonObject: JsonObject;
    begin
        if not JobTask.FindSet() then begin
            JsonArray.WriteTo(JsonText);
            exit;
        end;
        repeat
            DayTask.Reset();
            DayTask.SetRange("Job No.", JobTask."Job No.");
            DayTask.SetRange("Job Task No.", JobTask."Job Task No.");
            if (FromDate <> 0D) and (ToDate <> 0D) then
                DayTask.SetRange("Task Date", FromDate, ToDate)
            else
                if FromDate <> 0D then
                    DayTask.SetFilter("Task Date", '>=%1', FromDate)
                else
                    if ToDate <> 0D then
                        DayTask.SetFilter("Task Date", '<=%1', ToDate);
            if DayTask.FindSet() then
                repeat
                    JsonObject := CreateDayTaskJsonObject(DayTask);
                    JsonArray.Add(JsonObject);
                until DayTask.Next() = 0;
        until JobTask.Next() = 0;
        JsonArray.WriteTo(JsonText);
    end;

    procedure GetResourcesByJobTaskAsJson(var JobTask: Record "Job Task"; FromDate: Date; ToDate: Date) JsonText: Text
    var
        DayTask: Record "Day Tasks";
        Resource: Record Resource;
        JsonArray: JsonArray;
        JsonObject: JsonObject;
        ResourceNos: List of [Code[20]];
        ResNo: Code[20];
    begin
        // Collect distinct Resource No. values from Day Tasks for this Job Task
        if not JobTask.FindSet() then
            exit;
        repeat
            DayTask.SetRange("Job No.", JobTask."Job No.");
            DayTask.SetRange("Job Task No.", JobTask."Job Task No.");
            if (FromDate <> 0D) and (ToDate <> 0D) then
                DayTask.SetRange("Task Date", FromDate, ToDate)
            else
                if FromDate <> 0D then
                    DayTask.SetFilter("Task Date", '>=%1', FromDate)
                else
                    if ToDate <> 0D then
                        DayTask.SetFilter("Task Date", '<=%1', ToDate);
            if DayTask.FindSet() then
                repeat
                    if (DayTask."Assigned Resource No." <> '') and (not ResourceNos.Contains(DayTask."Assigned Resource No.")) then
                        ResourceNos.Add(DayTask."Assigned Resource No.");
                until DayTask.Next() = 0;
        until JobTask.Next() = 0;

        // If no Day Task assignments found, return empty list (only the - NONE - placeholder).
        // "Show/Hide Resource Panel" button will reload all resources when user wants to see everything.
        if ResourceNos.Count() = 0 then begin
            GetEmptyResourceAsJson(JsonArray);
            JsonArray.WriteTo(JsonText);
            if GuiAllowed then
                Message('No resources assigned to this task. Showing empty resource list. Click "Show/Hide Resource Panel" to view all resources.');
            exit;
        end;

        GetEmptyResourceAsJson(JsonArray);
        foreach ResNo in ResourceNos do begin
            if Resource.Get(ResNo) then begin
                JsonObject.Add('key', 'RES-' + Resource."No.");
                JsonObject.Add('label', Resource.Name + ' (' + Resource."No." + ')');
                JsonArray.Add(JsonObject);
                Clear(JsonObject);
            end;
        end;

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
        WorkOrder: Record "Work Order";
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
            DayTask.Setrange("Task Date", StartDate, EndDate);

        if DayTask.FindSet() then
            repeat
                JsonObject := CreateDayTaskJsonObject(DayTask);
                JsonArray.Add(JsonObject);
            until DayTask.Next() = 0;

        // --- Second pass: Request day tasks with blank Task Date but Work Order Placeholder Date in range ---
        DayTask.Reset();
        if JobNo <> '' then
            DayTask.SetRange("Job No.", JobNo);
        if JobTaskNo <> '' then
            DayTask.SetRange("Job Task No.", JobTaskNo);
        DayTask.SetRange("Plan Status", DayTask."Plan Status"::Inrequest);
        DayTask.SetRange("Task Date", 0D);
        DayTask.SetFilter("Work Order No.", '<>%1', '');
        if DayTask.FindSet() then
            repeat
                if WorkOrder.Get(DayTask."Work Order No.") then
                    if (WorkOrder."Placeholder Date" >= StartDate) and (WorkOrder."Placeholder Date" <= EndDate) then begin
                        JsonObject := CreateDayTaskJsonObjectRequest(DayTask, WorkOrder."Placeholder Date");
                        JsonArray.Add(JsonObject);
                    end;
            until DayTask.Next() = 0;

        JsonArray.WriteTo(JsonText);
    end;

    local procedure CreateDayTaskJsonObject(DayTask: Record "Day Tasks") JsonObject: JsonObject
    var
        WorkDateText: Text;
        StartTimeText: Text;
        EndTimeText: Text;
        ResourceId: Text;
        PlanStatusText: Text;
    begin
        // SystemId as unique ID
        JsonObject.Add('id', Format(DayTask.SystemId));
        JsonObject.Add('task', Format(DayTask."Job No.") + '-' + Format(DayTask."Job Task No."));
        // Day Task identifiers
        JsonObject.Add('dayNo', DayTask."Task Date");
        JsonObject.Add('dayLineNo', DayTask."Day Line No.");
        JsonObject.Add('jobNo', DayTask."Job No.");
        JsonObject.Add('jobTaskNo', DayTask."Job Task No.");

        // Date and time information
        if DayTask."Task Date" <> 0D then
            WorkDateText := FormatDate(DayTask."Task Date")
        else
            WorkDateText := '';
        JsonObject.Add('work_date', WorkDateText);
        JsonObject.Add('placeholder_date', '');

        StartTimeText := FormatTime(DayTask."Start Time Assigned");
        JsonObject.Add('start_time', StartTimeText);

        EndTimeText := FormatTime(DayTask."End Time Assigned");
        JsonObject.Add('end_time', EndTimeText);

        if DayTask."Assigned Resource No." <> '' then
            JsonObject.Add('hours', DayTask."Assigned Hours")
        else
            JsonObject.Add('hours', DayTask."Requested Hours");

        // Resource/Vendor information
        ResourceId := GetResourceId(DayTask);
        JsonObject.Add('resource_id', ResourceId);

        JsonObject.Add('type', 'Resource');

        if DayTask."Vendor No." <> '' then
            JsonObject.Add('vendorNo', DayTask."Vendor No.")
        else
            JsonObject.Add('vendorNo', 'null');

        // Plan status
        case DayTask."Plan Status" of
            DayTask."Plan Status"::Inrequest:
                PlanStatusText := 'Request';
            DayTask."Plan Status"::Inprogress:
                PlanStatusText := 'Planned';
            DayTask."Plan Status"::Rejected:
                PlanStatusText := 'Rejected';
            DayTask."Plan Status"::Accepted:
                PlanStatusText := 'Accepted';
            else
                PlanStatusText := '';
        end;
        JsonObject.Add('plan_status', PlanStatusText);
        JsonObject.Add('work_order_no', DayTask."Work Order No.");
    end;

    local procedure CreateDayTaskJsonObjectRequest(DayTask: Record "Day Tasks"; PlaceholderDate: Date) JsonObject: JsonObject
    var
        StartTimeText: Text;
        EndTimeText: Text;
        ResourceId: Text;
    begin
        // Use SystemId as ID (no Task Date so no collision with normal records)
        JsonObject.Add('id', Format(DayTask.SystemId));
        JsonObject.Add('task', Format(DayTask."Job No.") + '-' + Format(DayTask."Job Task No."));
        JsonObject.Add('dayNo', DayTask."Task Date");
        JsonObject.Add('dayLineNo', DayTask."Day Line No.");
        JsonObject.Add('jobNo', DayTask."Job No.");
        JsonObject.Add('jobTaskNo', DayTask."Job Task No.");

        // Use Work Order Placeholder Date as display date
        JsonObject.Add('work_date', FormatDate(PlaceholderDate));
        JsonObject.Add('placeholder_date', FormatDate(PlaceholderDate));

        StartTimeText := FormatTime(DayTask."Start Time Assigned");
        JsonObject.Add('start_time', StartTimeText);

        EndTimeText := FormatTime(DayTask."End Time Assigned");
        JsonObject.Add('end_time', EndTimeText);

        JsonObject.Add('hours', DayTask."Requested Hours");

        ResourceId := GetResourceId(DayTask);
        JsonObject.Add('resource_id', ResourceId);

        JsonObject.Add('type', 'Resource');

        if DayTask."Vendor No." <> '' then
            JsonObject.Add('vendorNo', DayTask."Vendor No.")
        else
            JsonObject.Add('vendorNo', 'null');

        JsonObject.Add('plan_status', 'Request');
        JsonObject.Add('work_order_no', DayTask."Work Order No.");
    end;

    local procedure FormatTime(InputTime: Time) FormattedTime: Text
    begin
        if InputTime = 0T then
            exit('');
        FormattedTime := DelChr(Format(InputTime, 0, '<Hours24,2>:<Minutes,2>:<Seconds,2>'), '<>', '');
    end;

    local procedure GetResourceId(DayTask: Record "Day Tasks") ResourceId: Text
    begin
        if DayTask."Assigned Resource No." <> '' then begin
            ResourceId := 'RES-' + DayTask."Assigned Resource No.";
        end else
            ResourceId := 'RES-'; //UNASSIGNED
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

    /// <summary>
    /// Returns non-working days from the Base Calendar configured in "Daily Optimizer Setup"
    /// as a JSON array: [{ "date": "YYYY-MM-DD", "description": "...", "type": "holiday" }, ...]
    /// Recurring entries are expanded for every year within StartDate..EndDate.
    /// </summary>
    procedure GetHolidaysAsJson(StartDate: Date; EndDate: Date) JsonText: Text
    var
        DailyOptimizerSetup: Record "Daily Optimizer Setup";
        BaseCalendarChange: Record "Base Calendar Change";
        JsonArray: JsonArray;
        JsonObject: JsonObject;
        CalCode: Code[10];
        HolidayDate: Date;
        Year: Integer;
    begin
        if not DailyOptimizerSetup.FindFirst() then begin
            JsonArray.WriteTo(JsonText);
            exit;
        end;
        CalCode := DailyOptimizerSetup."Base Calendar";
        if CalCode = '' then begin
            JsonArray.WriteTo(JsonText);
            exit;
        end;

        BaseCalendarChange.SetRange("Base Calendar Code", CalCode);
        BaseCalendarChange.SetRange(Nonworking, true);
        // Skip Weekly Recurring entries (weekday patterns) — they are already handled by the JS weekend check.
        // Include: Annual Recurring (1) = holiday same day/month every year, and non-recurring (0) = one-off dates.
        BaseCalendarChange.SetFilter("Recurring System", '%1|%2',
            BaseCalendarChange."Recurring System"::" ",
            BaseCalendarChange."Recurring System"::"Annual Recurring");
        if BaseCalendarChange.FindSet() then
            repeat
                if BaseCalendarChange."Recurring System" = BaseCalendarChange."Recurring System"::"Annual Recurring" then begin
                    // Expand annual entry for each year in the requested range
                    for Year := Date2DMY(StartDate, 3) to Date2DMY(EndDate, 3) do begin
                        HolidayDate := DMY2Date(
                            Date2DMY(BaseCalendarChange.Date, 1),
                            Date2DMY(BaseCalendarChange.Date, 2),
                            Year);
                        if (HolidayDate >= StartDate) and (HolidayDate <= EndDate) then begin
                            Clear(JsonObject);
                            JsonObject.Add('date', FormatDate(HolidayDate));
                            JsonObject.Add('description', BaseCalendarChange.Description);
                            JsonObject.Add('type', 'holiday');
                            JsonArray.Add(JsonObject);
                        end;
                    end;
                end else begin
                    // Non-recurring: use the exact date
                    if (BaseCalendarChange.Date >= StartDate) and (BaseCalendarChange.Date <= EndDate) then begin
                        Clear(JsonObject);
                        JsonObject.Add('date', FormatDate(BaseCalendarChange.Date));
                        JsonObject.Add('description', BaseCalendarChange.Description);
                        JsonObject.Add('type', 'holiday');
                        JsonArray.Add(JsonObject);
                    end;
                end;
            until BaseCalendarChange.Next() = 0;

        JsonArray.WriteTo(JsonText);
    end;

    procedure DownloadJsonTextData(pJsonText: Text; FileName: Text)
    var
        tempblob: Codeunit "Temp Blob";
        instream: InStream;
        outstream: OutStream;
        va: variant;
    begin
        if pJsonText <> '' then begin
            // Download the JSON to a file for inspection
            tempblob.CreateOutStream(outstream);
            outstream.WriteText(pJsonText);
            tempblob.CreateInStream(instream);
            va := FileName;
            DownloadFromStream(instream, FileName, '', 'application/json', va);
        end;
    end;

}


