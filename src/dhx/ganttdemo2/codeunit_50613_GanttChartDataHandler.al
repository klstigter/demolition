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
    begin
        exit(GetJobTasksAsJson(AchorDate, pJobFilter, ''));
    end;

    procedure GetJobTasksAsJson(AchorDate: Date; pJobFilter: Text; pJobTaskFilter: Text) JsonText: Text
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
        if pJobTaskFilter <> '' then
            JobTask.SetFilter("Job Task No.", pJobTaskFilter);
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

    // Returns only resources assigned to the given Job Task via Day Plannings.
    // Falls back to all resources if no Day Planning assignments exist.
    /// <summary>
    /// Returns day planning JSON for all job tasks in the marked set, filtered to FromDate..ToDate.
    /// Used to reload only the relevant events in the resource panel when the user
    /// right-clicks a task in the Gantt → Show Job Resources.
    /// </summary>
    procedure GetDayPlanningsByJobTaskAsJson(var JobTask: Record "Job Task"; FromDate: Date; ToDate: Date) JsonText: Text
    var
        DayPlanning: Record "Day Planning";
        JsonArray: JsonArray;
        JsonObject: JsonObject;
    begin
        if not JobTask.FindSet() then begin
            JsonArray.WriteTo(JsonText);
            exit;
        end;
        repeat
            DayPlanning.Reset();
            DayPlanning.SetRange("Job No.", JobTask."Job No.");
            DayPlanning.SetRange("Job Task No.", JobTask."Job Task No.");
            if (FromDate <> 0D) and (ToDate <> 0D) then
                DayPlanning.SetRange("Work Date", FromDate, ToDate)
            else
                if FromDate <> 0D then
                    DayPlanning.SetFilter("Work Date", '>=%1', FromDate)
                else
                    if ToDate <> 0D then
                        DayPlanning.SetFilter("Work Date", '<=%1', ToDate);
            if DayPlanning.FindSet() then
                repeat
                    JsonObject := CreateDayPlanningJsonObject(DayPlanning);
                    JsonArray.Add(JsonObject);
                until DayPlanning.Next() = 0;
        until JobTask.Next() = 0;
        JsonArray.WriteTo(JsonText);
    end;

    procedure GetResourcesByJobTaskAsJson(var JobTask: Record "Job Task"; FromDate: Date; ToDate: Date) JsonText: Text
    var
        DayPlanning: Record "Day Planning";
        Resource: Record Resource;
        JsonArray: JsonArray;
        JsonObject: JsonObject;
        ResourceNos: List of [Code[20]];
        ResNo: Code[20];
    begin
        // Collect distinct Resource No. values from Day Plannings for this Job Task
        if not JobTask.FindSet() then
            exit;
        repeat
            DayPlanning.SetRange("Job No.", JobTask."Job No.");
            DayPlanning.SetRange("Job Task No.", JobTask."Job Task No.");
            if (FromDate <> 0D) and (ToDate <> 0D) then
                DayPlanning.SetRange("Work Date", FromDate, ToDate)
            else
                if FromDate <> 0D then
                    DayPlanning.SetFilter("Work Date", '>=%1', FromDate)
                else
                    if ToDate <> 0D then
                        DayPlanning.SetFilter("Work Date", '<=%1', ToDate);
            if DayPlanning.FindSet() then
                repeat
                    if DayPlanning."Plan Status" = DayPlanning."Plan Status"::"In Request" then begin
                        if (DayPlanning."Requested Resource No." <> '') and (not ResourceNos.Contains(DayPlanning."Requested Resource No.")) then
                            ResourceNos.Add(DayPlanning."Requested Resource No.");
                    end else begin
                        if (DayPlanning."Assigned Resource No." <> '') and (not ResourceNos.Contains(DayPlanning."Assigned Resource No.")) then
                            ResourceNos.Add(DayPlanning."Assigned Resource No.");
                    end;
                until DayPlanning.Next() = 0;
        until JobTask.Next() = 0;

        // If no Day Planning assignments found, return empty list (only the - NONE - placeholder).
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

    procedure GetDayPlanningsAsJson(StartData: date) JsonText: Text
    var
        DayPlanning: Record "Day Planning";
        JsonArray: JsonArray;
        JsonObject: JsonObject;
    begin
        exit(GetDayPlanningsAsJson(StartData, '', ''));
    end;

    procedure GetDayPlanningsAsJson(AnchorDate: date; JobNo: Code[20]) JsonText: Text
    var
        DayPlanning: Record "Day Planning";
        JsonArray: JsonArray;
        JsonObject: JsonObject;
    begin
        exit(GetDayPlanningsAsJson(AnchorDate, JobNo, ''));
    end;

    procedure GetDayPlanningsAsJson(AnchorDate: date; JobNo: Code[20]; JobTaskNo: Code[20]) JsonText: Text
    var
        GanttSetup: Record "Gantt Chart Setup";
        DayPlanning: Record "Day Planning";
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
            DayPlanning.SetRange("Job No.", JobNo);
        if JobTaskNo <> '' then
            DayPlanning.SetRange("Job Task No.", JobTaskNo);
        if AnchorDate <> 0D then
            DayPlanning.Setrange("Work Date", StartDate, EndDate);

        if DayPlanning.FindSet() then
            repeat
                JsonObject := CreateDayPlanningJsonObject(DayPlanning);
                JsonArray.Add(JsonObject);
            until DayPlanning.Next() = 0;

        // --- Second pass: Request day plannings with blank Task Date but Work Order Placeholder Date in range ---
        DayPlanning.Reset();
        if JobNo <> '' then
            DayPlanning.SetRange("Job No.", JobNo);
        if JobTaskNo <> '' then
            DayPlanning.SetRange("Job Task No.", JobTaskNo);
        DayPlanning.SetRange("Plan Status", DayPlanning."Plan Status"::"In Request");
        DayPlanning.SetRange("Work Date", 0D);
        DayPlanning.SetFilter("Work Order No.", '<>%1', '');
        if DayPlanning.FindSet() then
            repeat
                if WorkOrder.Get(DayPlanning."Work Order No.") then
                    if (WorkOrder."Placeholder Date" >= StartDate) and (WorkOrder."Placeholder Date" <= EndDate) then begin
                        JsonObject := CreateDayPlanningJsonObjectRequest(DayPlanning, WorkOrder."Placeholder Date");
                        JsonArray.Add(JsonObject);
                    end;
            until DayPlanning.Next() = 0;

        JsonArray.WriteTo(JsonText);
    end;

    local procedure CreateDayPlanningJsonObject(DayPlanning: Record "Day Planning") JsonObject: JsonObject
    var
        WorkDateText: Text;
        StartTimeText: Text;
        EndTimeText: Text;
        ResourceId: Text;
        PlanStatusText: Text;
    begin
        // SystemId as unique ID
        JsonObject.Add('id', Format(DayPlanning.SystemId));
        JsonObject.Add('task', Format(DayPlanning."Job No.") + '-' + Format(DayPlanning."Job Task No."));
        // Day Planning identifiers
        JsonObject.Add('dayNo', DayPlanning."Work Date");
        JsonObject.Add('dayLineNo', DayPlanning."Day Line No.");
        JsonObject.Add('jobNo', DayPlanning."Job No.");
        JsonObject.Add('jobTaskNo', DayPlanning."Job Task No.");

        // Date and time information
        if DayPlanning."Work Date" <> 0D then
            WorkDateText := FormatDate(DayPlanning."Work Date")
        else
            WorkDateText := '';
        JsonObject.Add('work_date', WorkDateText);
        JsonObject.Add('placeholder_date', '');

        StartTimeText := FormatTime(DayPlanning."Start Time Assigned");
        JsonObject.Add('start_time', StartTimeText);

        EndTimeText := FormatTime(DayPlanning."End Time Assigned");
        JsonObject.Add('end_time', EndTimeText);

        if DayPlanning."Assigned Resource No." <> '' then
            JsonObject.Add('hours', DayPlanning."Assigned Hours")
        else
            JsonObject.Add('hours', DayPlanning."Requested Hours");

        // Resource/Vendor information
        ResourceId := GetResourceId(DayPlanning);
        JsonObject.Add('resource_id', ResourceId);

        JsonObject.Add('type', 'Resource');

        if DayPlanning."Vendor No." <> '' then
            JsonObject.Add('vendorNo', DayPlanning."Vendor No.")
        else
            JsonObject.Add('vendorNo', 'null');

        // Plan status
        case DayPlanning."Plan Status" of
            DayPlanning."Plan Status"::"In Request":
                PlanStatusText := 'Request';
            DayPlanning."Plan Status"::"In Progress":
                PlanStatusText := 'Planned';
            DayPlanning."Plan Status"::Rejected:
                PlanStatusText := 'Rejected';
            DayPlanning."Plan Status"::Accepted:
                PlanStatusText := 'Accepted';
            else
                PlanStatusText := '';
        end;
        JsonObject.Add('plan_status', PlanStatusText);
        JsonObject.Add('work_order_no', DayPlanning."Work Order No.");
    end;

    local procedure CreateDayPlanningJsonObjectRequest(DayPlanning: Record "Day Planning"; PlaceholderDate: Date) JsonObject: JsonObject
    var
        StartTimeText: Text;
        EndTimeText: Text;
        ResourceId: Text;
    begin
        // Use SystemId as ID (no Task Date so no collision with normal records)
        JsonObject.Add('id', Format(DayPlanning.SystemId));
        JsonObject.Add('task', Format(DayPlanning."Job No.") + '-' + Format(DayPlanning."Job Task No."));
        JsonObject.Add('dayNo', DayPlanning."Work Date");
        JsonObject.Add('dayLineNo', DayPlanning."Day Line No.");
        JsonObject.Add('jobNo', DayPlanning."Job No.");
        JsonObject.Add('jobTaskNo', DayPlanning."Job Task No.");

        // Use Work Order Placeholder Date as display date
        JsonObject.Add('work_date', FormatDate(PlaceholderDate));
        JsonObject.Add('placeholder_date', FormatDate(PlaceholderDate));

        StartTimeText := FormatTime(DayPlanning."Start Time Assigned");
        JsonObject.Add('start_time', StartTimeText);

        EndTimeText := FormatTime(DayPlanning."End Time Assigned");
        JsonObject.Add('end_time', EndTimeText);

        JsonObject.Add('hours', DayPlanning."Requested Hours");

        ResourceId := GetResourceId(DayPlanning);
        JsonObject.Add('resource_id', ResourceId);

        JsonObject.Add('type', 'Resource');

        if DayPlanning."Vendor No." <> '' then
            JsonObject.Add('vendorNo', DayPlanning."Vendor No.")
        else
            JsonObject.Add('vendorNo', 'null');

        JsonObject.Add('plan_status', 'Request');
        JsonObject.Add('work_order_no', DayPlanning."Work Order No.");
    end;

    local procedure FormatTime(InputTime: Time) FormattedTime: Text
    begin
        if InputTime = 0T then
            exit('');
        FormattedTime := DelChr(Format(InputTime, 0, '<Hours24,2>:<Minutes,2>:<Seconds,2>'), '<>', '');
    end;

    local procedure GetResourceId(DayPlanning: Record "Day Planning") ResourceId: Text
    begin
        if DayPlanning."Assigned Resource No." <> '' then
            ResourceId := 'RES-' + DayPlanning."Assigned Resource No."
        else
            if DayPlanning."Requested Resource No." <> '' then
                ResourceId := 'RES-' + DayPlanning."Requested Resource No."
            else
                ResourceId := 'RES-'; //UNASSIGNED
    end;

    local procedure GetDayPlanningTypeText(DayPlanningType: Enum "Job Planning Line Type") TypeText: Text
    begin
        case DayPlanningType of
            DayPlanningType::Resource:
                TypeText := 'Resource';
            DayPlanningType::Item:
                TypeText := 'Item';
            DayPlanningType::"G/L Account":
                TypeText := 'G/L Account';
            DayPlanningType::Text:
                TypeText := 'Text';
            else
                TypeText := '';
        end;
    end;

    /// <summary>
    /// Returns non-working days from the Base Calendar configured in "Daily Optimizer Setup"
    /// as a JSON array: [{ "date": "YYYY-MM-DD", "description": "...", "type": "holiday" }, ...]
    /// Uses the standard Calendar Management codeunit which handles one-off, annual recurring,
    /// and weekly recurring entries automatically.
    /// Weekend days (Sat/Sun) are excluded — they are already shaded by the JS side.
    /// </summary>
    procedure GetHolidaysAsJson(StartDate: Date; EndDate: Date) JsonText: Text
    var
        DailyOptimizerSetup: Record "Daily Optimizer Setup";
        BaseCalendar: Record "Base Calendar";
        CalendarMgt: Codeunit "Calendar Management";
        CustomizedCalendarChange: Record "Customized Calendar Change";
        JsonArray: JsonArray;
        JsonObject: JsonObject;
        CurrentDate: Date;
    begin
        if not DailyOptimizerSetup.FindFirst() then begin
            JsonArray.WriteTo(JsonText);
            exit;
        end;
        if DailyOptimizerSetup."Base Calendar" = '' then begin
            JsonArray.WriteTo(JsonText);
            exit;
        end;
        if not BaseCalendar.Get(DailyOptimizerSetup."Base Calendar") then begin
            JsonArray.WriteTo(JsonText);
            exit;
        end;

        // SetSource loads all Base Calendar Change entries into the codeunit cache once.
        // IsNonworkingDay then reuses the cache for every date — no repeated DB reads.
        CalendarMgt.SetSource(BaseCalendar, CustomizedCalendarChange);

        CurrentDate := StartDate;
        while CurrentDate <= EndDate do begin
            if CalendarMgt.IsNonworkingDay(CurrentDate, CustomizedCalendarChange) then
                // Skip Sat (6) / Sun (7) — the Gantt JS already shades weekends.
                // Only emit Mon–Fri non-working days (public holidays, day-off entries).
                if not (Date2DWY(CurrentDate, 1) in [6, 7]) then begin
                    Clear(JsonObject);
                    JsonObject.Add('date', FormatDate(CurrentDate));
                    JsonObject.Add('description', CustomizedCalendarChange.Description);
                    JsonObject.Add('type', 'holiday');
                    JsonArray.Add(JsonObject);
                end;
            CurrentDate := CalcDate('<+1D>', CurrentDate);
        end;

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


