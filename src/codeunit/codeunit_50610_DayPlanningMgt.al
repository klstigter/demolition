codeunit 50610 "Day Plannings Mgt."
{
    var
        GeneralUtil: Codeunit "General Planning Utilities";
        WorkHoursTemplate: Record "Work-Hour Template";
        // ── Memoized state for IsActiveWorkDay(), shared across many calls on the same
        // codeunit instance (e.g. one per candidate date while cascading a period-change
        // reschedule) — mirrors the EnsureBaseCalendarLoaded() memoization convention used
        // in codeunit_50602_CreateDemoData.al, so the Base Calendar/exceptions are only
        // loaded once per instance instead of once per candidate date.
        gCalendarLoaded: Boolean;
        gCalCustomizedCalendarChange: Record "Customized Calendar Change";
        gCalendarMgt: Codeunit "Calendar Management";
        gCachedWorkHourTemplateCode: Code[20];
        gCachedWorkHourTemplate: Record "Work-Hour Template";
        gCachedWorkHourTemplateFound: Boolean;

    procedure CreateDayPlanning()
    var
        JobTask: Record "Job Task";
        ConfirmMsg: Label 'This will delete all existing day planning lines and recreate them from Job Task. Do you want to continue?';
    begin
        if not Confirm(ConfirmMsg, false) then
            exit;

        ClearDayPlanningLines();

        if JobTask.FindSet() then
            repeat
                Message('under construction');
            //CreateDayPlanning(JobTask, false);
            until JobTask.Next() = 0;

        Message('Day planning lines have been successfully created.');
    end;

    procedure CreateDayPlanning(DayPlanningPattern: Record "Day Planning Pattern")
    begin
        CreateDayPlanning(DayPlanningPattern, true)
    end;

    local procedure CreateDayPlanning(DayPlanningPattern: Record "Day Planning Pattern"; DoDeleteAll: Boolean)
    var
        JobTask: Record "Job Task";
        DayPlannings: Record "Day Planning";
        StartDate: Date;
        EndDate: Date;
        NewTaskDate: Date;
        TaskWkDay: Integer;
        n: Integer;
        StartDateTime: DateTime;
        EndDateTime: DateTime;
        DayNo: Integer;
        DayStartTime: Time;
        DayEndTime: Time;
        NonWorkingHours: Decimal;
        Counter: Integer;
        HasOverlap: Boolean;
    begin
        DayPlanningPattern.TestField("Work-Hour Template");
        case true of
            (DayPlanningPattern."Resource No." = '') and
            (DayPlanningPattern.SkillsRequired = ''):
                error('Skills Required must be specified');
            DayPlanningPattern."Work-Hour Template" = '':
                error('Work-Hour Template must be specified');
            DayPlanningPattern."Start Date" = 0D:
                Error('Planned Start Date must be specified');
            DayPlanningPattern."End Date" = 0D:
                Error('Planned End Date must be specified');
            (DayPlanningPattern."Start Time" = 0T) or (DayPlanningPattern."End Time" = 0T):
                Error('Start Time and End Time must be specified');
            (DayPlanningPattern."Vendor No." <> ''):
                begin
                    DayPlanningPattern."Quantity of Lines" := 1;
                    DayPlanningPattern.Modify(false);
                end;
        end;
        //TODO: refactor?
        //if DayPlanningGenerator.StartEndLimitations(true) then
        //    exit;
        WorkHoursTemplate.get(DayPlanningPattern."Work-Hour Template");
        // Get the start and end dates
        StartDate := DayPlanningPattern."Start Date";
        if DayPlanningPattern."End Date" <> 0D then
            EndDate := DayPlanningPattern."End Date"
        else
            EndDate := StartDate;

        // If no valid date range, skip
        if (StartDate = 0D) then
            exit;

        // Delete existing day planning lines for this job planning line
        if not DoDeleteAll then begin
            DayPlannings.SetRange("Job No.", DayPlanningPattern."Job No.");
            DayPlannings.SetRange("Job Task No.", DayPlanningPattern."Job Task No.");
            DayPlannings.DeleteAll();
        end;
        // Create day planning lines for each day in the range
        NewTaskDate := StartDate;

        while NewTaskDate <= EndDate do begin
            // Check if this day is a working day in the template
            if ExpectedWeekDay(DayPlanningPattern, NewTaskDate) then begin

                Clear(DayPlannings);
                DayNo := GeneralUtil.DateToInteger(NewTaskDate);
                DayPlannings."Work Date" := NewTaskDate;
                DayPlannings."Day Line No." := DayPlannings.GetNextDayLineNo(NewTaskDate, DayPlanningPattern."Job No.", DayPlanningPattern."Job Task No.");
                DayPlannings."Job No." := DayPlanningPattern."Job No.";
                DayPlannings."Job Task No." := DayPlanningPattern."Job Task No.";
                DayPlannings."Pattern Line No." := DayPlanningPattern."Line No.";
                DayPlannings."Work Order No." := DayPlanningPattern."Work Order No.";

                // Calculate start and end times for this day
                if DayPlanningPattern."Start Time" <> 0T then
                    DayStartTime := DayPlanningPattern."Start Time"
                else
                    DayStartTime := WorkHoursTemplate."Default Start Time";
                if DayPlanningPattern."End Time" <> 0T then
                    DayEndTime := DayPlanningPattern."End Time"
                else
                    DayEndTime := WorkHoursTemplate."Default End Time";
                if DayPlanningPattern."Non Working Minutes" <> 0 then
                    NonWorkingHours := DayPlanningPattern."Non Working Minutes"
                else
                    NonWorkingHours := WorkHoursTemplate."Non Working Minutes";

                DayPlannings."Start Time Assigned" := DayStartTime;
                DayPlannings."End Time Assigned" := DayEndTime;
                DayPlannings."Start Time Requested" := DayStartTime;
                DayPlannings."End Time Requested" := DayEndTime;
                DayPlannings.VALIDATE("Non Working Minutes Assigned", NonWorkingHours);

                // Copy other fields from job planning line
                DayPlannings."Assigned Resource No." := DayPlanningPattern."Resource No.";
                // Calculate working hours
                DayPlannings."Requested Hours" := DayPlanningPattern."Requested Hours";

                //DayPlannings.Description := DayPlanningGenerator.Description;
                //DayPlannings."Unit of Measure Code" := JobTask."Unit of Measure Code";
                DayPlannings.Skill := DayPlanningPattern.SkillsRequired;
                //DayPlannings."Work Type Code" := JobTask."Work Type Code";
                DayPlannings."Vendor No." := DayPlanningPattern."Vendor No.";
                //DayPlannings.Depth := DayPlanningGenerator.Depth;
                //DayPlannings.IsBoor := DayPlanningGenerator.Isboor;

                // Calculate quantity for this day (proportional distribution)
                if CheckMayChange(DayPlannings) then
                    if DayPlannings.Insert(true) then
                        Counter += 1;
                for n := 2 to DayPlanningPattern."Quantity of Lines" do begin
                    DayPlannings."Day Line No." := n * 10000;
                    if CheckMayChange(DayPlannings) then
                        if DayPlannings.Insert(true) then
                            Counter += 1;
                end;
            end;
            NewTaskDate := CalcDate('<+1D>', NewTaskDate);
        END;

        //Update Job Task Start - End Date
        JobTask.Get(DayPlanningPattern."Job No.", DayPlanningPattern."Job Task No.");
        DayPlannings.Reset();
        DayPlannings.SetCurrentKey("Work Date");
        DayPlannings.SetRange("Job No.", JobTask."Job No.");
        DayPlannings.SetRange("Job Task No.", JobTask."Job Task No.");
        if DayPlannings.FindFirst() then
            StartDate := DayPlannings."Work Date";
        if DayPlannings.FindLast() then
            EndDate := DayPlannings."Work Date";

        EnsureJobTaskCoversDate(JobTask, StartDate);
        EnsureJobTaskCoversDate(JobTask, EndDate);

        Message('%1 day planning lines created for Job %2, Task %3.', Counter, DayPlanningPattern."Job No.", DayPlanningPattern."Job Task No.");
    END;

    /// <summary>
    /// Ensures the Job Task's Planned Starting/Ending Date range fully covers TaskDate - extends
    /// PlannedStartDate backward and/or PlannedEndDate forward as needed, then persists. This is
    /// the same extend-to-cover pattern CreateDayPlanning already applied inline for its own
    /// generated date range; extracted here so other single-date callers (e.g. "Day Planning"
    /// table's own "Task Date" OnValidate) don't have to re-derive it.
    /// </summary>
    procedure EnsureJobTaskCoversDate(var JobTask: Record "Job Task"; TaskDate: Date)
    begin
        if TaskDate = 0D then
            exit;
        if (JobTask.PlannedStartDate = 0D) or (TaskDate < JobTask.PlannedStartDate) then
            JobTask.PlannedStartDate := TaskDate;
        if (JobTask.PlannedEndDate = 0D) or (TaskDate > JobTask.PlannedEndDate) then
            JobTask.Validate(PlannedEndDate, TaskDate);
        JobTask.Modify();
    end;

    local procedure CheckMayChange(NewDayPlanning: Record "Day Planning"): Boolean
    var
        DayPlanning: Record "Day Planning";
    begin
        if DayPlanning.Get(NewDayPlanning."Job No.", NewDayPlanning."Job Task No.", NewDayPlanning."Day Line No.") then
            Exit(not DayPlanning."Manual Modified");
        exit(true);

    end;


    local procedure ClearDayPlanningLines()
    var
        JobDayPlanningLine: Record "Day Planning Pattern";
    begin
        JobDayPlanningLine.DeleteAll();
    end;

    /// <summary>
    /// Replaces the old Day 1..Day 7 boolean-driven weekday check — active-days are now resolved
    /// entirely from DayPlanningGenerator."Work-Hour Template" via IsActiveWorkDay, which already
    /// folds the mandatory Daily Optimizer Setup "Base Calendar" exception check in unconditionally.
    /// The old OffOnWeekEndAndPublicHoliday parameter is dropped: the sole call site (CreateDayPlanning,
    /// above) always passed true ("honour the calendar"), and IsActiveWorkDay has no way to express a
    /// "false"/ignore-calendar mode once the calendar check is folded into it, so preserving the
    /// parameter would only be a dead no-op. Behavior for the one real caller is unchanged.
    /// </summary>
    local procedure ExpectedWeekDay(DayPlanningGenerator: Record "Day Planning Pattern"; NewTaskDate: Date): Boolean
    begin
        exit(IsActiveWorkDay(DayPlanningGenerator."Work-Hour Template", NewTaskDate));
    end;

    /// <summary>
    /// Work-Hour-Template-aware active/working day check, shared by any caller that needs
    /// to know whether a given date is a valid day to schedule work on — used by ExpectedWeekDay
    /// above (Day Planning Pattern expansion) and by "DayPlanning Period Sync Mgt." (codeunit 50617)
    /// when rescheduling Day Planning lines around a Job Task period change.
    /// A day is active when BOTH:
    ///  - the resolved Work-Hour Template has hours > 0 for that weekday (blank template code
    ///    = every weekday is treated as active, matching this codeunit's existing default when no
    ///    weekday pattern is supplied), AND
    ///  - the mandatory Daily Optimizer Setup "Base Calendar" does not mark the date as a
    ///    non-working day/exception (public holiday, custom day off, weekly recurring
    ///    weekend marker, etc.).
    /// "Base Calendar" is mandatory (TestField) — this errors rather than silently skipping the
    /// calendar check when it's blank.
    /// </summary>
    procedure IsActiveWorkDay(WorkHourTemplateCode: Code[20]; TheDate: Date): Boolean
    begin
        EnsureCalendarLoadedForActiveWorkDayCheck();

        if not IsWeekdayActiveInTemplate(WorkHourTemplateCode, Date2DWY(TheDate, 1)) then
            exit(false);

        exit(not gCalendarMgt.IsNonworkingDay(TheDate, gCalCustomizedCalendarChange));
    end;

    /// <summary>
    /// Resolves whether a given ISO weekday number (1=Monday..7=Sunday, matching Date2DWY(D,1))
    /// is an active/working weekday according to WorkHourTemplateCode's Monday..Sunday hours fields
    /// (hours > 0 = active). Blank template code = every weekday treated as active. Used by
    /// IsActiveWorkDay (date-based check).
    /// </summary>
    local procedure IsWeekdayActiveInTemplate(WorkHourTemplateCode: Code[20]; DayOfWeek: Integer): Boolean
    var
        ActiveWeekDay: Boolean;
    begin
        ActiveWeekDay := true;
        if WorkHourTemplateCode <> '' then begin
            EnsureWorkHourTemplateLoadedForActiveWorkDayCheck(WorkHourTemplateCode);
            if gCachedWorkHourTemplateFound then
                case DayOfWeek of
                    1:
                        ActiveWeekDay := gCachedWorkHourTemplate.Monday > 0;
                    2:
                        ActiveWeekDay := gCachedWorkHourTemplate.Tuesday > 0;
                    3:
                        ActiveWeekDay := gCachedWorkHourTemplate.Wednesday > 0;
                    4:
                        ActiveWeekDay := gCachedWorkHourTemplate.Thursday > 0;
                    5:
                        ActiveWeekDay := gCachedWorkHourTemplate.Friday > 0;
                    6:
                        ActiveWeekDay := gCachedWorkHourTemplate.Saturday > 0;
                    7:
                        ActiveWeekDay := gCachedWorkHourTemplate.Sunday > 0;
                end;
        end;
        exit(ActiveWeekDay);
    end;

    /// <summary>
    /// Builds the "1|2|4|"-style text for Day Planning Pattern's "Week Pattern" field, derived from
    /// WorkHourTemplateCode's weekday hours via IsWeekdayActiveInTemplate (same helper IsActiveWorkDay
    /// uses) rather than re-deriving weekday-hours access separately. A blank/unresolvable template
    /// code yields the full "1|2|3|4|5|6|7" (blank = every day active, matching IsWeekdayActiveInTemplate's
    /// own default). Called from Day Planning Pattern's "Work-Hour Template" OnValidate.
    /// </summary>
    procedure GetActiveWeekdaysText(WorkHourTemplateCode: Code[20]): Code[13]
    var
        Pattern: Text;
        DayOfWeek: Integer;
    begin
        for DayOfWeek := 1 to 7 do
            if IsWeekdayActiveInTemplate(WorkHourTemplateCode, DayOfWeek) then
                Pattern += Format(DayOfWeek) + '|';
        if Pattern <> '' then
            Pattern := CopyStr(Pattern, 1, StrLen(Pattern) - 1);
        exit(CopyStr(Pattern, 1, 13));
    end;

    local procedure EnsureCalendarLoadedForActiveWorkDayCheck()
    var
        OptimizerSetup: Record "Daily Optimizer Setup";
        BaseCalendar: Record "Base Calendar";
    begin
        if gCalendarLoaded then
            exit;
        OptimizerSetup.Get();
        OptimizerSetup.TestField("Base Calendar");
        BaseCalendar.Get(OptimizerSetup."Base Calendar");
        gCalendarMgt.SetSource(BaseCalendar, gCalCustomizedCalendarChange);
        gCalendarLoaded := true;
    end;

    local procedure EnsureWorkHourTemplateLoadedForActiveWorkDayCheck(WorkHourTemplateCode: Code[20])
    begin
        if gCachedWorkHourTemplateCode = WorkHourTemplateCode then
            exit;
        gCachedWorkHourTemplateCode := WorkHourTemplateCode;
        gCachedWorkHourTemplateFound := gCachedWorkHourTemplate.Get(WorkHourTemplateCode);
    end;

    procedure GetDateRange(JobNo: Code[20]; var StartDate: Date; var EndDate: Date)
    begin
        GetDateRange(JobNo, '', StartDate, EndDate);
    end;

    procedure GetDateRange(JobNo: Code[20]; JobTaskNo: Code[20]; var StartDate: Date; var EndDate: Date)
    var
        DayPlannings: Record "Day Planning";
    begin
        StartDate := 0D;
        EndDate := 0D;
        DayPlannings.SetRange("Job No.", JobNo);
        if JobTaskNo <> '' then
            DayPlannings.SetRange("Job Task No.", JobTaskNo);
        if DayPlannings.FindFirst() then
            StartDate := DayPlannings."Work Date";
        if DayPlannings.FindLast() then
            EndDate := DayPlannings."Work Date";
    end;

}
