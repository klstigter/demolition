/// <summary>
/// Pre Daytask Generator (Codeunit 50617)
///
/// Core generation engine for the "Generate pre Daytasks" feature.
/// Responsibilities:
///   1. Validate the request buffer supplied by the dialog page.
///   2. Build the list of target dates (Fixed / DateRange / Recurring).
///   3. Apply weekday filters and Base Calendar non-working-day rules.
///   4. Apply the recurrence interval for Recurring mode.
///   5. Derive start/end times from the Work-Hour Template.
///   6. Insert N lines per date (one per resource slot) into
///      table 50608 "Order Intake Line Opt.", all linked via "Document No.".
///   7. Report the number of lines created.
///
/// Caller pattern (from Order Intake Card):
///   PreDaytaskGen.GenerateLines(RequestBuf, Rec."No.");
/// </summary>
codeunit 50617 "Pre Daytask Generator"
{
    // ──────────────────────────────────────────────────────────────────────────
    // Public API
    // ──────────────────────────────────────────────────────────────────────────

    /// <summary>
    /// Validate, calculate dates, and insert pre-Daytask lines for the given
    /// Order Intake document.
    /// </summary>
    /// <param name="RequestBuf">The fully populated request buffer from the dialog page.</param>
    /// <param name="DocumentNo">The Order Intake header No. lines are linked to.</param>
    /// <returns>Total number of lines created.</returns>
    procedure GenerateLines(var RequestBuf: Record "Pre Daytask Request Buf."; DocumentNo: Code[20]): Integer
    var
        DateList: List of [Date];
        CandidateDate: Date;
        LineNo: Integer;
        LinesCreated: Integer;
        ResourceIdx: Integer;
    begin
        // 1. Validate all user-supplied parameters
        ValidateRequest(RequestBuf);

        // 2. Build the list of target dates within the From/To Date range
        BuildDateList(RequestBuf, DateList);

        if DateList.Count() = 0 then
            Error(NoDatesTxt);

        // 3. Resolve start/end times — template overrides zero-valued times
        EnsureWorkTimes(RequestBuf);

        // 4. Get the next available line number for this document
        LineNo := GetNextLineNo(DocumentNo);
        LinesCreated := 0;

        // 5. For each date, create one line per resource slot
        foreach CandidateDate in DateList do
            for ResourceIdx := 1 to RequestBuf."No. of Resources" do begin
                CreateOrderIntakeLine(
                    DocumentNo,
                    CandidateDate,
                    RequestBuf."Daytask Start",
                    RequestBuf."Daytask End",
                    RequestBuf.Skill,
                    RequestBuf.Description,
                    LineNo
                );
                LineNo += 10000;
                LinesCreated += 1;
            end;

        exit(LinesCreated);
    end;

    /// <summary>
    /// Public validation entry-point so the dialog page can pre-check the
    /// request before closing with OK.
    /// </summary>
    procedure ValidateRequest(RequestBuf: Record "Pre Daytask Request Buf.")
    begin
        if RequestBuf."Start Date" = 0D then
            Error(ErrNoStartDateTxt);
        if RequestBuf."End Date" = 0D then
            Error(ErrNoEndDateTxt);
        if RequestBuf."Start Date" > RequestBuf."End Date" then
            Error(ErrDateOrderTxt);
        if not AnyDaySelected(RequestBuf) then
            Error(ErrNoDaySelectedTxt);

        // Start must be before End when both are set
        if (RequestBuf."Daytask Start" <> 0T) and (RequestBuf."Daytask End" <> 0T) then
            if RequestBuf."Daytask Start" >= RequestBuf."Daytask End" then
                Error(ErrTimeOrderTxt);
    end;

    // ──────────────────────────────────────────────────────────────────────────
    // Date-list builder
    // ──────────────────────────────────────────────────────────────────────────

    /// <summary>
    /// Builds the complete list of candidate dates for line generation.
    ///
    /// Iterates every day in [Start Date, End Date], keeping dates that
    /// match the selected weekdays, pass the Base Calendar check, and
    /// (when Recurrence Interval > 1) fall on the correct interval slot.
    /// </summary>
    local procedure BuildDateList(RequestBuf: Record "Pre Daytask Request Buf."; var DateList: List of [Date])
    var
        CandidateDate: Date;
    begin
        CandidateDate := RequestBuf."Start Date";
        while CandidateDate <= RequestBuf."End Date" do begin
            if IsSelectedDay(CandidateDate, RequestBuf) then
                if IsInInterval(CandidateDate, RequestBuf) then
                    if PassesCalendarCheck(CandidateDate, RequestBuf) then
                        DateList.Add(CandidateDate);
            CandidateDate := CalcDate('<+1D>', CandidateDate);
        end;
    end;

    // ──────────────────────────────────────────────────────────────────────────
    // Weekday helpers
    // ──────────────────────────────────────────────────────────────────────────

    /// <summary>
    /// Returns true when at least one weekday checkbox is ticked.
    /// </summary>
    local procedure AnyDaySelected(RequestBuf: Record "Pre Daytask Request Buf."): Boolean
    begin
        exit(
            RequestBuf.Monday or RequestBuf.Tuesday or RequestBuf.Wednesday or
            RequestBuf.Thursday or RequestBuf.Friday or RequestBuf.Saturday or
            RequestBuf.Sunday
        );
    end;

    /// <summary>
    /// Returns true when the given date falls on a weekday that the user selected.
    /// Date2DWY( , 1): 1=Monday, 2=Tuesday, ..., 7=Sunday.
    /// </summary>
    local procedure IsSelectedDay(CheckDate: Date; RequestBuf: Record "Pre Daytask Request Buf."): Boolean
    begin
        case Date2DWY(CheckDate, 1) of
            1:
                exit(RequestBuf.Monday);
            2:
                exit(RequestBuf.Tuesday);
            3:
                exit(RequestBuf.Wednesday);
            4:
                exit(RequestBuf.Thursday);
            5:
                exit(RequestBuf.Friday);
            6:
                exit(RequestBuf.Saturday);
            7:
                exit(RequestBuf.Sunday);
        end;
        exit(false);
    end;

    // ──────────────────────────────────────────────────────────────────────────
    // Recurrence-interval filter
    // ──────────────────────────────────────────────────────────────────────────

    /// <summary>
    /// Returns true when the candidate date falls within the correct
    /// recurrence slot relative to RequestBuf."Start Date".
    ///
    /// Daily   – include dates where (CheckDate - StartDate) mod Interval = 0.
    /// Weekly  – include dates whose ISO week index (relative to start week)
    ///           mod Interval = 0.
    /// Monthly – include dates whose month index (relative to start month)
    ///           mod Interval = 0.
    ///
    /// Interval = 1 always returns true (every occurrence).
    /// </summary>
    local procedure IsInInterval(CheckDate: Date; RequestBuf: Record "Pre Daytask Request Buf."): Boolean
    var
        Interval: Integer;
        DayDiff: Integer;
    begin
        Interval := RequestBuf."Recurrence Interval";
        if Interval <= 1 then
            exit(true); // Interval 1 = every matching occurrence

        case RequestBuf.Recurrence of
            RequestBuf.Recurrence::Daily:
                begin
                    // Count calendar days from StartDate.
                    // DayDiff mod Interval = 0 → this is a valid slot.
                    DayDiff := CheckDate - RequestBuf."Start Date";
                    exit(DayDiff mod Interval = 0);
                end;

            RequestBuf.Recurrence::Weekly:
                // Calculate the week index (0-based) relative to the start week
                // and check if it is a valid slot.
                exit(GetWeekIndex(CheckDate, RequestBuf."Start Date") mod Interval = 0);

            RequestBuf.Recurrence::Monthly:
                // Calculate the month index (0-based) relative to the start month.
                exit(GetMonthIndex(CheckDate, RequestBuf."Start Date") mod Interval = 0);
        end;

        exit(true); // fallback — should not be reached
    end;

    /// <summary>
    /// Returns the week index of CheckDate relative to the week containing
    /// StartDate (0 = same week, 1 = next week, …).
    /// Uses ISO-style Monday-anchored weeks, robust across year boundaries.
    /// </summary>
    local procedure GetWeekIndex(CheckDate: Date; StartDate: Date): Integer
    var
        MondayOfStart: Date;
        MondayOfCheck: Date;
    begin
        // Monday of the week containing StartDate
        MondayOfStart := StartDate - (Date2DWY(StartDate, 1) - 1);
        // Monday of the week containing CheckDate
        MondayOfCheck := CheckDate - (Date2DWY(CheckDate, 1) - 1);
        exit((MondayOfCheck - MondayOfStart) div 7);
    end;

    /// <summary>
    /// Returns the month index of CheckDate relative to StartDate's month
    /// (0 = same month, 1 = next month, …).
    /// </summary>
    local procedure GetMonthIndex(CheckDate: Date; StartDate: Date): Integer
    var
        CheckYear: Integer;
        CheckMonth: Integer;
        StartYear: Integer;
        StartMonth: Integer;
    begin
        CheckYear := Date2DMY(CheckDate, 3);
        CheckMonth := Date2DMY(CheckDate, 2);
        StartYear := Date2DMY(StartDate, 3);
        StartMonth := Date2DMY(StartDate, 2);
        exit((CheckYear * 12 + CheckMonth) - (StartYear * 12 + StartMonth));
    end;

    // ──────────────────────────────────────────────────────────────────────────
    // Base Calendar / working-day helpers
    // ──────────────────────────────────────────────────────────────────────────

    /// <summary>
    /// Returns true when the date passes the "Skip Non-Working Days" gate.
    /// Skipping is only applied when the flag is true; when false every date
    /// that matches the weekday selection is accepted.
    /// </summary>
    local procedure PassesCalendarCheck(CheckDate: Date; RequestBuf: Record "Pre Daytask Request Buf."): Boolean
    begin
        if not RequestBuf."Skip Non-Working Days" then
            exit(true);
        exit(IsWorkingDay(CheckDate, RequestBuf."Base Calendar"));
    end;

    /// <summary>
    /// Returns true when the given date is a working day according to the
    /// Base Calendar (or Mon-Fri if no calendar is configured).
    ///
    /// Uses CalendarManagement.SetSource(Variant) to load the Base Calendar
    /// into a Customized Calendar Change buffer, then calls IsNonworkingDay.
    /// </summary>
    local procedure IsWorkingDay(CheckDate: Date; BaseCalendarCode: Code[10]): Boolean
    var
        BaseCalRec: Record "Base Calendar";
        CalMgt: Codeunit "Calendar Management";
        CustomCalChange: Record "Customized Calendar Change";
    begin
        if BaseCalendarCode = '' then
            // Fall back to Mon-Fri when no calendar is configured
            exit(Date2DWY(CheckDate, 1) in [1 .. 5]);

        if not BaseCalRec.Get(BaseCalendarCode) then
            exit(Date2DWY(CheckDate, 1) in [1 .. 5]);

        // SetSource loads the Base Calendar into the Customized Calendar Change buffer
        CalMgt.SetSource(BaseCalRec, CustomCalChange);
        exit(not CalMgt.IsNonworkingDay(CheckDate, CustomCalChange));
    end;

    // ──────────────────────────────────────────────────────────────────────────
    // Work-time resolver
    // ──────────────────────────────────────────────────────────────────────────

    /// <summary>
    /// If start/end times are still 0T (not set by the user) but a
    /// Work-Hour Template is specified, re-read the template defaults.
    /// This guards against the case where the template was cleared after
    /// the time fields were populated.
    /// </summary>
    local procedure EnsureWorkTimes(var RequestBuf: Record "Pre Daytask Request Buf.")
    var
        WHTemplate: Record "Work-Hour Template";
    begin
        if (RequestBuf."Daytask Start" = 0T) or (RequestBuf."Daytask End" = 0T) then
            if RequestBuf."Work-Hour Template" <> '' then
                if WHTemplate.Get(RequestBuf."Work-Hour Template") then begin
                    if RequestBuf."Daytask Start" = 0T then
                        RequestBuf."Daytask Start" := WHTemplate."Default Start Time";
                    if RequestBuf."Daytask End" = 0T then
                        RequestBuf."Daytask End" := WHTemplate."Default End Time";
                end;
    end;

    // ──────────────────────────────────────────────────────────────────────────
    // Line-number helper
    // ──────────────────────────────────────────────────────────────────────────

    /// <summary>
    /// Returns the next available line number for the given document.
    /// Line numbers are multiples of 10000, consistent with BC standard tables.
    /// </summary>
    local procedure GetNextLineNo(DocumentNo: Code[20]): Integer
    var
        OrderLine: Record "Order Intake Line Opt.";
    begin
        OrderLine.SetRange("Document No.", DocumentNo);
        if OrderLine.FindLast() then
            exit(OrderLine."Line No." + 10000);
        exit(10000);
    end;

    // ──────────────────────────────────────────────────────────────────────────
    // Record writer
    // ──────────────────────────────────────────────────────────────────────────

    /// <summary>
    /// Inserts a single "Order Intake Line Opt." record.
    /// All fields are set from caller parameters so that the codeunit is the
    /// sole owner of insert logic (single-responsibility principle).
    /// </summary>
    local procedure CreateOrderIntakeLine(
        DocumentNo: Code[20];
        TaskDate: Date;
        StartTime: Time;
        EndTime: Time;
        SkillCode: Code[20];
        TaskDescription: Text[100];
        LineNo: Integer)
    var
        OrderLine: Record "Order Intake Line Opt.";
    begin
        OrderLine.Init();
        OrderLine."Document No." := DocumentNo;
        OrderLine."Line No." := LineNo;
        OrderLine."Daytask Date" := TaskDate;
        OrderLine."Daytask Start" := StartTime;
        OrderLine."Daytask End" := EndTime;
        OrderLine.Skill := SkillCode;
        OrderLine.Description := TaskDescription;
        OrderLine.Insert(true);
    end;

    // ──────────────────────────────────────────────────────────────────────────
    // Error message labels
    // ──────────────────────────────────────────────────────────────────────────

    var
        NoDatesTxt: Label 'No dates could be generated with the selected criteria. Please review the scheduling settings.';
        ErrNoStartDateTxt: Label 'Please specify a From Date.';
        ErrNoEndDateTxt: Label 'Please specify a To Date.';
        ErrDateOrderTxt: Label 'From Date must be earlier than or equal to To Date.';
        ErrNoDaySelectedTxt: Label 'Please select at least one work day.';
        ErrTimeOrderTxt: Label 'Start Time must be earlier than End Time.';
}
