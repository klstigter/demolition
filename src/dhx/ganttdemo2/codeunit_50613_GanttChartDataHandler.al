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
        JobTaskByPlanned: Record "Job Task";
        JobTaskByConstraint: Record "Job Task";
        JobTask: Record "Job Task";
        StartDate: Date;
        EndDate: Date;
        EffectiveStartDate: Date;
        EffectiveEndDate: Date;
        JsonArray: JsonArray;
        JsonObject: JsonObject;
        JobNoFilter: Code[20];
        OldJobNo: Code[20];
        Skip: Boolean;
        HasPlannedRow: Boolean;
        HasConstraintRow: Boolean;
        KeyCompare: Integer;
        FromConstraintRow: Boolean;
    begin
        GanttSetup.Get(UserId);
        JobNoFilter := GanttSetup."Job No. Filter";
        if pJobFilter <> '' then
            JobNoFilter := pJobFilter;
        GetDateRange(GanttSetup, AchorDate, StartDate, EndDate);

        // Two independently server-side-filtered cursors, merge-joined below in primary-key
        // (Job No., Job Task No.) order - NOT a single unfiltered FindSet() over the whole table.
        // Cursor 1: tasks whose own Planned dates overlap the visible window (original behavior).
        if JobNoFilter <> '' then
            JobTaskByPlanned.SetFilter("Job No.", JobNoFilter);
        if pJobTaskFilter <> '' then
            JobTaskByPlanned.SetFilter("Job Task No.", pJobTaskFilter);
        JobTaskByPlanned.SetFilter("PlannedStartDate", '<=%1', EndDate);
        JobTaskByPlanned.SetFilter("PlannedEndDate", '>=%1', StartDate);

        // Cursor 2: tasks whose persisted constraint-derived period ("Constraint Calc. - Start/End
        // Date", kept up to date by UpdateConstraintCalcDates in tableext 50605) overlaps the
        // visible window. Mirrors Cursor 1's shape exactly, now that the constraint math is
        // precomputed at write time instead of on every read - bounded by how many tasks actually
        // use constraint scheduling, NOT by overall Job Task table size.
        if JobNoFilter <> '' then
            JobTaskByConstraint.SetFilter("Job No.", JobNoFilter);
        if pJobTaskFilter <> '' then
            JobTaskByConstraint.SetFilter("Job Task No.", pJobTaskFilter);
        JobTaskByConstraint.SetFilter("Constraint Calc. - Start Date", '<=%1', EndDate);
        JobTaskByConstraint.SetFilter("Constraint Calc. - End Date", '>=%1', StartDate);

        HasPlannedRow := JobTaskByPlanned.FindSet();
        HasConstraintRow := JobTaskByConstraint.FindSet();

        while HasPlannedRow or HasConstraintRow do begin
            // Merge-join: both cursors are already ordered by primary key, so at each step take
            // whichever current row sorts first. A row satisfying BOTH filters (valid Planned
            // dates AND a populated constraint) appears in both cursors - KeyCompare = 0 dedupes
            // it to a single processing pass via the Planned-dates cursor and advances both.
            if HasPlannedRow and HasConstraintRow then
                KeyCompare := CompareJobTaskKey(JobTaskByPlanned, JobTaskByConstraint)
            else
                if HasPlannedRow then KeyCompare := -1 else KeyCompare := 1;

            FromConstraintRow := KeyCompare > 0;
            if FromConstraintRow then
                JobTask := JobTaskByConstraint
            else
                JobTask := JobTaskByPlanned;

            if OldJobNo <> JobTask."Job No." then begin
                OldJobNo := JobTask."Job No.";
                clear(ParentJobTaskId);
            end;
            Skip := (JobTask."Job Task Type" = JobTask."Job Task Type"::"End-Total") or
                 (JobTask."Job Task Type" = JobTask."Job Task Type"::"Total");
            if not Skip then begin
                // GetEffectivePeriod is now a plain field pick (no date math - see below), so this
                // re-check is cheap. Still needed: a row can have BOTH complete-but-out-of-window
                // Planned dates (fails Cursor 1) AND an in-window Constraint Calc period (passes
                // Cursor 2) - GetEffectivePeriod always prefers real Planned dates when both are
                // set, so without this guard such a row would slip through via Cursor 2 and then
                // render at its out-of-window Planned position instead of being excluded.
                GetEffectivePeriod(JobTask, EffectiveStartDate, EffectiveEndDate);
                if (EffectiveStartDate = 0D) or (EffectiveEndDate = 0D) or
                   (EffectiveStartDate > EndDate) or (EffectiveEndDate < StartDate)
                then
                    Skip := true;
            end;
            if not skip then begin
                JsonObject := CreateJobTaskJsonObject(JobTask);
                JsonArray.Add(JsonObject);
            end;

            if KeyCompare = 0 then begin
                HasPlannedRow := JobTaskByPlanned.Next() <> 0;
                HasConstraintRow := JobTaskByConstraint.Next() <> 0;
            end else
                if FromConstraintRow then
                    HasConstraintRow := JobTaskByConstraint.Next() <> 0
                else
                    HasPlannedRow := JobTaskByPlanned.Next() <> 0;
        end;

        JsonArray.WriteTo(JsonText);
    end;

    /// <summary>
    /// Compares two Job Task records by primary key (Job No., Job Task No.) for the merge-join
    /// in GetJobTasksAsJson. Returns -1 if A sorts before B, 0 if equal, 1 if A sorts after B.
    /// </summary>
    local procedure CompareJobTaskKey(A: Record "Job Task"; B: Record "Job Task") Result: Integer
    begin
        if A."Job No." < B."Job No." then exit(-1);
        if A."Job No." > B."Job No." then exit(1);
        if A."Job Task No." < B."Job Task No." then exit(-1);
        if A."Job Task No." > B."Job Task No." then exit(1);
        exit(0);
    end;

    /// <summary>
    /// Resolves the effective Start/Finish period used to place a Job Task's bar on the Gantt.
    /// When both PlannedStartDate and PlannedEndDate are populated, they are used unchanged.
    /// Otherwise falls back to the persisted "Constraint Calc. - Start/End Date" fields (tableext
    /// 50605), which UpdateConstraintCalcDates keeps up to date whenever "Constraint Type"/
    /// "Constraint Date"/"Max Duration" change - the constraint math itself no longer happens
    /// here, this is now a plain field pick. Those calc fields are already 0D/0D when the
    /// constraint isn't fully populated, so no source is available and the caller excludes the row.
    /// </summary>
    local procedure GetEffectivePeriod(JobTask: Record "Job Task"; var EffectiveStartDate: Date; var EffectiveEndDate: Date)
    begin
        if (JobTask.PlannedStartDate <> 0D) and (JobTask.PlannedEndDate <> 0D) then begin
            EffectiveStartDate := JobTask.PlannedStartDate;
            EffectiveEndDate := JobTask.PlannedEndDate;
        end else begin
            EffectiveStartDate := JobTask."Constraint Calc. - Start Date";
            EffectiveEndDate := JobTask."Constraint Calc. - End Date";
        end;
    end;

    local procedure CreateJobTaskJsonObject(JobTask: Record "Job Task") JsonObject: JsonObject
    var
        Color: record "Planning Color Opt.";
        VisualDefaultSettings: Codeunit "Visual Default Settings";
        ColorTxt: Text;
        StartDateText: Text;
        StartEndText: Text;
        ConstraintDateText: Text;
        SchedulingTypeText: Text;
        Codevar: Code[20];
        GanttDuration: Integer;
        EffectiveStartDate: Date;
        EffectiveEndDate: Date;
        ConstraintTypeText: Text;
    begin

        GetEffectivePeriod(JobTask, EffectiveStartDate, EffectiveEndDate);

        JsonObject.Add('id', Format(JobTask."Job No.") + '|' + Format(JobTask."Job Task No."));
        JsonObject.Add('text', (JobTask."Job Task Type" = JobTask."Job Task Type"::Posting ? JobTask."Job Task No." + ' - ' : '') + JobTask.Description);
        // Start date (format: dd-MM-yyyy)
        if EffectiveStartDate <> 0D then
            StartDateText := FormatDate(EffectiveStartDate)
        else
            StartDateText := '';
        JsonObject.Add('start_date', StartDateText);

        // Deliberately NOT JobTask.Duration - that stored field can go stale relative to
        // PlannedStartDate/PlannedEndDate (e.g. a task whose dates were reshuffled by a path
        // that doesn't call CalculateDuration() afterward), and DHTMLX's own "duration" is an
        // INCLUSIVE day count (end_date = start_date + duration, exclusive) - the same "+1"
        // formula CalculateDuration() itself uses (tableext 50605: PlannedEndDate -
        // PlannedStartDate + 1). Recomputing it fresh here from the two dates guarantees the
        // rendered bar can never desync from what the task's own card shows, regardless of
        // whether the stored Duration field happens to be in sync.
        // EffectiveStartDate/EffectiveEndDate fall back to the constraint-derived period when
        // Planned dates aren't both populated (see GetEffectivePeriod).
        if (EffectiveStartDate <> 0D) and (EffectiveEndDate <> 0D) then
            GanttDuration := EffectiveEndDate - EffectiveStartDate + 1
        else
            GanttDuration := JobTask.Duration;
        JsonObject.Add('duration', GanttDuration);
        JsonObject.Add('bcJobNo', JobTask."Job No.");
        JsonObject.Add('bcJobTaskNo', JobTask."Job Task No.");
        SchedulingTypeText := GetSchedulingTypeText(JobTask."Scheduling Type");
        JsonObject.Add('schedulingType', SchedulingTypeText);

        // "Constraint Type" always carries a value (InitValue = ASAP - see tableext 50605's
        // UpdateConstraintCalcDates comment), so it isn't a reliable "is a constraint populated"
        // signal on its own. Gate on "Constraint Date" instead, same as the rest of the constraint
        // logic does. Format() on an enum returns its Caption (human-readable text), not its Name.
        // NOTE: bcConstraintType/bcConstraintDate/bcMaxDuration are distinct from DHTMLX's own
        // built-in constraint_type/constraint_date auto-scheduling keys used elsewhere in this
        // pipeline (codeunit 50616, wrapper.js) - do not conflate the two.
        if JobTask."Constraint Date" <> 0D then
            ConstraintTypeText := Format(JobTask."Constraint Type")
        else
            ConstraintTypeText := '';
        JsonObject.Add('bcConstraintType', ConstraintTypeText);
        JsonObject.Add('bcConstraintDate', FormatDate(JobTask."Constraint Date"));
        JsonObject.Add('bcMaxDuration', JobTask."Max Duration");

        JsonObject.Add('progress', JobTask."Progress" / 100); // Convert percentage to a value between 0 and 1

        // Starting seed colour for every task bar, before the task-type/per-task overrides below
        // run - "Daily Optimizer Setup"."GTB Color" via codeunit 50609's GetGanttTaskBarColor for
        // Posting Job Tasks, or "Daily Optimizer Setup"."GTB Color (non posting)" via that
        // codeunit's GetGanttTaskBarColorNonPosting for every other Job Task Type, each falling
        // back to that codeunit's own built-in default when unset. The progressColor (darker
        // shade, or "Daily Optimizer Setup"."GTB Progress Color" when set) is derived in JS from
        // this value - see wrapper.js's onTaskLoading/_gtbProgressOverride.
        if JobTask."Job Task Type" = JobTask."Job Task Type"::Posting then
            ColorTxt := VisualDefaultSettings.GetGanttTaskBarColor()
        else
            ColorTxt := VisualDefaultSettings.GetGanttTaskBarColorNonPosting();
        // Check setting color for project task type.
        if evaluate(Codevar, Format(JobTask."Job Task Type")) then
            if Color.Get(Color.Type::"Project Task Type", Codevar, '', '') then
                if Color.Task <> '' then
                    ColorTxt := Color.Task;
        // setting color on Task is mandatory.
        if Color.Get(Color.Type::Task, JobTask."Job Task No.", JobTask."Job No.") then
            if Color.Task <> '' then
                ColorTxt := Color.Task;

        JsonObject.Add('color', ColorTxt);

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
    /// <summary>
    /// Returns day planning JSON for the given "JobNo|JobTaskNo" keys (one entry per Job Task,
    /// same convention as page 50620's ResourcePanelChildTaskIds), filtered to FromDate..ToDate.
    /// Single pass over a Query on "Day Planning" - replaces the previous var-Record/marked-set
    /// signature, whose per-Job-Task FindSet() loop was an N+1 round trip against a huge table.
    /// Plain Text keys (not Record marks) also make this callable from a Page Background Task's
    /// own read-only session, where marks set on the interactive session's Record don't exist.
    /// </summary>
    procedure GetDayPlanningsByJobTaskAsJson(JobTaskKeys: List of [Text]; FromDate: Date; ToDate: Date) JsonText: Text
    var
        DayPlanningByJobTaskQry: Query "Day Planning By Job Task";
        JsonArray: JsonArray;
        JobNoFilterText: Text;
        JobTaskNoFilterText: Text;
        PairSet: List of [Text];
    begin
        if JobTaskKeys.Count() = 0 then begin
            JsonArray.WriteTo(JsonText);
            exit;
        end;

        BuildJobTaskKeyFilters(JobTaskKeys, JobNoFilterText, JobTaskNoFilterText, PairSet);
        if (JobNoFilterText = '') or (JobTaskNoFilterText = '') then begin
            JsonArray.WriteTo(JsonText);
            exit;
        end;

        DayPlanningByJobTaskQry.SetFilter(JobNoFilter, JobNoFilterText);
        DayPlanningByJobTaskQry.SetFilter(JobTaskNoFilter, JobTaskNoFilterText);
        ApplyPlanDateFilter(DayPlanningByJobTaskQry, FromDate, ToDate);

        if DayPlanningByJobTaskQry.Open() then begin
            while DayPlanningByJobTaskQry.Read() do
                // The two OR-lists above are independent (all distinct Job Nos | all distinct Job
                // Task Nos across the requested keys), so a row could in principle satisfy both
                // without being one of the actual requested pairs - re-check against the exact
                // key set before including it. Cheap in-memory check, no extra DB round trip.
                if PairSet.Contains(DayPlanningByJobTaskQry.JobNo + '|' + DayPlanningByJobTaskQry.JobTaskNo) then
                    JsonArray.Add(BuildDayPlanningJsonObject(
                        DayPlanningByJobTaskQry.SystemId, DayPlanningByJobTaskQry.JobNo, DayPlanningByJobTaskQry.JobTaskNo,
                        DayPlanningByJobTaskQry.PlanDate, DayPlanningByJobTaskQry.DayLineNo, DayPlanningByJobTaskQry.StartTimeAssigned,
                        DayPlanningByJobTaskQry.EndTimeAssigned, DayPlanningByJobTaskQry.StartTimeRequested, DayPlanningByJobTaskQry.EndTimeRequested,
                        DayPlanningByJobTaskQry.AssignedHours, DayPlanningByJobTaskQry.RequestedHours, DayPlanningByJobTaskQry.NonWorkingMinutesAssigned,
                        DayPlanningByJobTaskQry.NonWorkingMinutesRequested, DayPlanningByJobTaskQry.AssignedResourceNo, DayPlanningByJobTaskQry.RequestedResourceNo,
                        DayPlanningByJobTaskQry.VendorNo, DayPlanningByJobTaskQry.PlanStatus, DayPlanningByJobTaskQry.WorkOrderNo));
            DayPlanningByJobTaskQry.Close();
        end;

        JsonArray.WriteTo(JsonText);
    end;

    /// <summary>
    /// Returns the distinct resources assigned/requested (per row's Plan Status) across the given
    /// "JobNo|JobTaskNo" keys, filtered to FromDate..ToDate. Reuses the same single Query pass as
    /// GetDayPlanningsByJobTaskAsJson above - distinct-resource collection now happens in memory
    /// (List.Contains against an already-fetched row set) instead of via a second per-Job-Task
    /// FindSet() loop.
    /// </summary>
    procedure GetResourcesByJobTaskAsJson(JobTaskKeys: List of [Text]; FromDate: Date; ToDate: Date) JsonText: Text
    var
        DayPlanningByJobTaskQry: Query "Day Planning By Job Task";
        Resource: Record Resource;
        PlanStatusHelper: Enum "Plan Status";
        JsonArray: JsonArray;
        JsonObject: JsonObject;
        ResourceNos: List of [Code[20]];
        ResNo: Code[20];
        JobNoFilterText: Text;
        JobTaskNoFilterText: Text;
        PairSet: List of [Text];
        RowResourceNo: Code[20];
    begin
        if JobTaskKeys.Count() = 0 then
            exit;

        BuildJobTaskKeyFilters(JobTaskKeys, JobNoFilterText, JobTaskNoFilterText, PairSet);
        if (JobNoFilterText = '') or (JobTaskNoFilterText = '') then
            exit;

        DayPlanningByJobTaskQry.SetFilter(JobNoFilter, JobNoFilterText);
        DayPlanningByJobTaskQry.SetFilter(JobTaskNoFilter, JobTaskNoFilterText);
        ApplyPlanDateFilter(DayPlanningByJobTaskQry, FromDate, ToDate);

        if DayPlanningByJobTaskQry.Open() then begin
            while DayPlanningByJobTaskQry.Read() do
                if PairSet.Contains(DayPlanningByJobTaskQry.JobNo + '|' + DayPlanningByJobTaskQry.JobTaskNo) then begin
                    if DayPlanningByJobTaskQry.PlanStatus = PlanStatusHelper::"In Request" then
                        RowResourceNo := DayPlanningByJobTaskQry.RequestedResourceNo
                    else
                        RowResourceNo := DayPlanningByJobTaskQry.AssignedResourceNo;
                    if (RowResourceNo <> '') and (not ResourceNos.Contains(RowResourceNo)) then
                        ResourceNos.Add(RowResourceNo);
                end;
            DayPlanningByJobTaskQry.Close();
        end;

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

    /// <summary>
    /// Parses "JobNo|JobTaskNo" key strings into the two AL '|' OR-lists used to filter the
    /// "Day Planning By Job Task" query, plus PairSet - the exact set of requested keys, used by
    /// callers to re-check each returned row (the two OR-lists are independent, so alone they can
    /// over-match a cross combination that was never actually requested).
    /// </summary>
    local procedure BuildJobTaskKeyFilters(JobTaskKeys: List of [Text]; var JobNoFilterText: Text; var JobTaskNoFilterText: Text; var PairSet: List of [Text])
    var
        DistinctJobNos: List of [Text];
        DistinctJobTaskNos: List of [Text];
        KeyText: Text;
        Parts: List of [Text];
        JobNoValue: Code[20];
        JobTaskNoValue: Code[20];
    begin
        foreach KeyText in JobTaskKeys do begin
            Parts := KeyText.Split('|');
            if Parts.Count() = 2 then begin
                JobNoValue := CopyStr(Parts.Get(1), 1, MaxStrLen(JobNoValue));
                JobTaskNoValue := CopyStr(Parts.Get(2), 1, MaxStrLen(JobTaskNoValue));
                if (JobNoValue <> '') and (JobTaskNoValue <> '') then begin
                    PairSet.Add(JobNoValue + '|' + JobTaskNoValue);
                    if not DistinctJobNos.Contains(JobNoValue) then
                        DistinctJobNos.Add(JobNoValue);
                    if not DistinctJobTaskNos.Contains(JobTaskNoValue) then
                        DistinctJobTaskNos.Add(JobTaskNoValue);
                end;
            end;
        end;

        foreach KeyText in DistinctJobNos do begin
            if JobNoFilterText <> '' then
                JobNoFilterText += '|';
            JobNoFilterText += KeyText;
        end;
        foreach KeyText in DistinctJobTaskNos do begin
            if JobTaskNoFilterText <> '' then
                JobTaskNoFilterText += '|';
            JobTaskNoFilterText += KeyText;
        end;
    end;

    local procedure ApplyPlanDateFilter(var DayPlanningByJobTaskQry: Query "Day Planning By Job Task"; FromDate: Date; ToDate: Date)
    begin
        if (FromDate <> 0D) and (ToDate <> 0D) then
            DayPlanningByJobTaskQry.SetRange(PlanDateFilter, FromDate, ToDate)
        else
            if FromDate <> 0D then
                DayPlanningByJobTaskQry.SetFilter(PlanDateFilter, '>=%1', FromDate)
            else
                if ToDate <> 0D then
                    DayPlanningByJobTaskQry.SetFilter(PlanDateFilter, '<=%1', ToDate);
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
            DayPlanning.SetFilter("Job No.", JobNo);
        if JobTaskNo <> '' then
            DayPlanning.SetFilter("Job Task No.", JobTaskNo);
        if AnchorDate <> 0D then
            DayPlanning.Setrange("Plan Date", StartDate, EndDate);

        if DayPlanning.FindSet() then
            repeat
                JsonObject := CreateDayPlanningJsonObject(DayPlanning);
                JsonArray.Add(JsonObject);
            until DayPlanning.Next() = 0;

        // --- Second pass: Request day plannings with blank Task Date but Work Order Placeholder Date in range ---
        DayPlanning.Reset();
        if JobNo <> '' then
            DayPlanning.SetFilter("Job No.", JobNo);
        if JobTaskNo <> '' then
            DayPlanning.SetFilter("Job Task No.", JobTaskNo);
        DayPlanning.SetRange("Plan Status", DayPlanning."Plan Status"::"In Request");
        DayPlanning.SetRange("Plan Date", 0D);
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
    begin
        exit(BuildDayPlanningJsonObject(
            DayPlanning.SystemId, DayPlanning."Job No.", DayPlanning."Job Task No.", DayPlanning."Plan Date",
            DayPlanning."Day Line No.", DayPlanning."Start Time Assigned", DayPlanning."End Time Assigned",
            DayPlanning."Start Time Requested", DayPlanning."End Time Requested", DayPlanning."Assigned Hours",
            DayPlanning."Requested Hours", DayPlanning."Non Working Minutes Assigned", DayPlanning."Non Working Minutes Requested",
            DayPlanning."Assigned Resource No.", DayPlanning."Requested Resource No.", DayPlanning."Vendor No.",
            DayPlanning."Plan Status", DayPlanning."Work Order No."));
    end;

    /// <summary>
    /// Shared JSON-shape builder behind CreateDayPlanningJsonObject (Record-based, used by the
    /// existing synchronous GetDayPlanningsAsJson) and GetDayPlanningsByJobTaskAsJson's Query-based
    /// path below - takes raw field values instead of a Record so it works identically whether the
    /// caller is iterating a "Day Planning" Record or a "Day Planning By Job Task" Query cursor.
    /// Field set/JSON keys are unchanged from the original Record-only implementation - this is a
    /// perf rewrite of how rows are fetched, not a change to the wire format wrapper.js depends on.
    /// </summary>
    local procedure BuildDayPlanningJsonObject(
        SystemIdValue: Guid;
        JobNoValue: Code[20];
        JobTaskNoValue: Code[20];
        PlanDateValue: Date;
        DayLineNoValue: Integer;
        StartTimeAssignedValue: Time;
        EndTimeAssignedValue: Time;
        StartTimeRequestedValue: Time;
        EndTimeRequestedValue: Time;
        AssignedHoursValue: Decimal;
        RequestedHoursValue: Decimal;
        NonWorkingMinutesAssignedValue: Integer;
        NonWorkingMinutesRequestedValue: Integer;
        AssignedResourceNoValue: Code[20];
        RequestedResourceNoValue: Code[20];
        VendorNoValue: Code[20];
        PlanStatusValue: Enum "Plan Status";
        WorkOrderNoValue: Code[20]) JsonObject: JsonObject
    var
        WorkDateText: Text;
        ResourceId: Text;
        PlanStatusText: Text;
    begin
        // SystemId as unique ID
        JsonObject.Add('id', Format(SystemIdValue));
        JsonObject.Add('task', Format(JobNoValue) + '-' + Format(JobTaskNoValue));
        // Day Planning identifiers
        JsonObject.Add('dayNo', PlanDateValue);
        JsonObject.Add('dayLineNo', DayLineNoValue);
        JsonObject.Add('jobNo', JobNoValue);
        JsonObject.Add('jobTaskNo', JobTaskNoValue);

        // Date and time information
        if PlanDateValue <> 0D then
            WorkDateText := FormatDate(PlanDateValue)
        else
            WorkDateText := '';
        JsonObject.Add('work_date', WorkDateText);
        JsonObject.Add('placeholder_date', '');

        JsonObject.Add('start_time', FormatTime(StartTimeAssignedValue));
        JsonObject.Add('end_time', FormatTime(EndTimeAssignedValue));

        if AssignedResourceNoValue <> '' then
            JsonObject.Add('hours', AssignedHoursValue)
        else
            JsonObject.Add('hours', RequestedHoursValue);

        // Requested vs Assigned detail, both sides, for the resource-marker hover tooltip's
        // "Requested"/"Assigned" column groups (see InstallResourceMarkerCustomTooltipsForDayPlannings
        // in wrapper.js) - unlike 'start_time'/'end_time'/'hours' above (Assigned-only, kept for
        // other existing JS callers), these always carry both sides regardless of Plan Status.
        JsonObject.Add('requested_start_time', FormatTime(StartTimeRequestedValue));
        JsonObject.Add('requested_end_time', FormatTime(EndTimeRequestedValue));
        JsonObject.Add('requested_idle_minutes', NonWorkingMinutesRequestedValue);
        JsonObject.Add('requested_hours', RequestedHoursValue);
        JsonObject.Add('assigned_start_time', FormatTime(StartTimeAssignedValue));
        JsonObject.Add('assigned_end_time', FormatTime(EndTimeAssignedValue));
        JsonObject.Add('assigned_idle_minutes', NonWorkingMinutesAssignedValue);
        JsonObject.Add('assigned_hours', AssignedHoursValue);

        // Resource/Vendor information
        ResourceId := GetResourceId(AssignedResourceNoValue, RequestedResourceNoValue);
        JsonObject.Add('resource_id', ResourceId);

        JsonObject.Add('type', 'Resource');

        if VendorNoValue <> '' then
            JsonObject.Add('vendorNo', VendorNoValue)
        else
            JsonObject.Add('vendorNo', 'null');

        // Plan status
        case PlanStatusValue of
            PlanStatusValue::"In Request":
                PlanStatusText := 'Request';
            PlanStatusValue::"In Progress":
                PlanStatusText := 'Assigned';
            PlanStatusValue::Rejected:
                PlanStatusText := 'Rejected';
            PlanStatusValue::Accepted:
                PlanStatusText := 'Accepted';
            else
                PlanStatusText := '';
        end;
        JsonObject.Add('plan_status', PlanStatusText);
        JsonObject.Add('work_order_no', WorkOrderNoValue);
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
        JsonObject.Add('dayNo', DayPlanning."Plan Date");
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

        JsonObject.Add('requested_start_time', FormatTime(DayPlanning."Start Time Requested"));
        JsonObject.Add('requested_end_time', FormatTime(DayPlanning."End Time Requested"));
        JsonObject.Add('requested_idle_minutes', DayPlanning."Non Working Minutes Requested");
        JsonObject.Add('requested_hours', DayPlanning."Requested Hours");
        JsonObject.Add('assigned_start_time', FormatTime(DayPlanning."Start Time Assigned"));
        JsonObject.Add('assigned_end_time', FormatTime(DayPlanning."End Time Assigned"));
        JsonObject.Add('assigned_idle_minutes', DayPlanning."Non Working Minutes Assigned");
        JsonObject.Add('assigned_hours', DayPlanning."Assigned Hours");

        ResourceId := GetResourceId(DayPlanning."Assigned Resource No.", DayPlanning."Requested Resource No.");
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

    local procedure GetResourceId(AssignedResourceNo: Code[20]; RequestedResourceNo: Code[20]) ResourceId: Text
    begin
        if AssignedResourceNo <> '' then
            ResourceId := 'RES-' + AssignedResourceNo
        else
            if RequestedResourceNo <> '' then
                ResourceId := 'RES-' + RequestedResourceNo
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


