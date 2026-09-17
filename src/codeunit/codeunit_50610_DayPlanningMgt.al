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
    /// Classifies TheDate into "Work-day" / "Weekend" / "Public-Holiday", splitting back out the
    /// two checks IsActiveWorkDay combines into a single boolean - for callers that need to know
    /// WHICH kind of non-working day it is, not just active/inactive. Used by page 50662's manual
    /// "New Date" edit, to re-derive "Day Type" after the user types a date in directly.
    /// </summary>
    procedure ClassifyDate(WorkHourTemplateCode: Code[20]; TheDate: Date): Enum "DayPlanning Date Type"
    begin
        EnsureCalendarLoadedForActiveWorkDayCheck();

        if not IsWeekdayActiveInTemplate(WorkHourTemplateCode, Date2DWY(TheDate, 1)) then
            exit("DayPlanning Date Type"::Weekend);

        if gCalendarMgt.IsNonworkingDay(TheDate, gCalCustomizedCalendarChange) then
            exit("DayPlanning Date Type"::"Public-Holiday");

        exit("DayPlanning Date Type"::"Work-day");
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
        // The primary key sorts by Day Line No., not Plan Date, so FindFirst/FindLast would
        // otherwise return the row with the lowest/highest Day Line No. instead of the
        // earliest/latest Plan Date. Use the Plan Date key explicitly.
        DayPlannings.SetCurrentKey("Job No.", "Job Task No.", "Plan Date");
        DayPlannings.SetRange("Job No.", JobNo);
        if JobTaskNo <> '' then
            DayPlannings.SetRange("Job Task No.", JobTaskNo);
        if DayPlannings.FindFirst() then
            StartDate := DayPlannings."Plan Date";
        if DayPlannings.FindLast() then
            EndDate := DayPlannings."Plan Date";
    end;

}
