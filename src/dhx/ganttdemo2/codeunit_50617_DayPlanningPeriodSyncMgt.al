codeunit 50617 "DayPlanning Period Sync Mgt."
{
    /// <summary>
    /// Entry point called from "Gantt Update Data" when a Job Task planned period changes.
    /// Calculates impacted DayPlanning records and opens a preview popup for user confirmation.
    /// No database changes occur before the user clicks Apply Changes.
    /// </summary>
    procedure ShowPreview(var JobTask: Record "Job Task"; JobNo: Code[20]; JobTaskNo: Code[20]; OldStart: Date; OldEnd: Date; NewStart: Date; NewEnd: Date): Boolean
    var
        TempPreviewBuffer: Record "DayPlanning Sync PreviewBuff" temporary;
        PreviewPage: Page "DayPlanning PeriodSyncPreview";
    begin
        // Calculate impacted DayPlanning records (buffer may be empty when no Day Plannings are linked).
        // Always open the preview page so the user can confirm or cancel the period change.
        if (OldStart = 0D) or (OldEnd = 0D) or (NewStart = 0D) or (NewEnd = 0D) then
            exit(true); // No valid dates to compare, skip preview and apply changes directly.

        if not CalculateChanges(JobNo, JobTaskNo, OldStart, OldEnd, NewStart, NewEnd, TempPreviewBuffer) then
            exit(true); // No changes detected, skip preview and apply changes directly.

        PreviewPage.SetPreviewData(TempPreviewBuffer);
        PreviewPage.SetJobTask(JobTask);
        PreviewPage.RunModal();
        exit(PreviewPage.WasApplied());
    end;

    /// <summary>
    /// Detects the type of period change (Shift, Right Bar, Left Bar) and calculates
    /// new Task Dates per scenario spec. Populates TempPreviewBuffer with only affected records.
    /// Returns TRUE if at least one record is affected.
    ///
    /// Scenario 1.1 – Shift Left/Right:    OldStart <> NewStart AND OldEnd <> NewEnd
    /// Scenario 1.2 – Right Bar change:    OldStart = NewStart  AND OldEnd <> NewEnd
    /// Scenario 1.3 – Left Bar change:     OldStart <> NewStart AND OldEnd = NewEnd
    /// </summary>
    procedure CalculateChanges(JobNo: Code[20]; JobTaskNo: Code[20]; OldStart: Date; OldEnd: Date; NewStart: Date; NewEnd: Date; var TempPreviewBuffer: Record "DayPlanning Sync PreviewBuff" temporary): Boolean
    var
        DayPlanning: Record "Day Planning";
        JobTask: Record "Job Task";
        DailyOptimizerSetup: Record "Daily Optimizer Setup";
        BaseCalendar: Record "Base Calendar";
        CalendarMgt: Codeunit "Calendar Management";
        CustomizedCalendarChange: Record "Customized Calendar Change";
        EntryNo: Integer;
        NewDate: Date;
        ChangeDays: Integer;
        WeekPattern: Code[20];
        WeekPatternText: Text;
        CalendarLoaded: Boolean;
        CandidateDate: Date;
        DayOfWeek: Integer;
        PatternParts: List of [Text];
        PatternPart: Text;
        PatternDay: Integer;
        IsInPattern: Boolean;
        DateTypeVal: Enum "DayPlanning Date Type";
    begin
        TempPreviewBuffer.Reset();
        TempPreviewBuffer.DeleteAll();

        // ── Load Job Task Week Pattern ───────────────────────────────────────────
        // 1=Mon, 2=Tue, 3=Wed, 4=Thu, 5=Fri, 6=Sat, 7=Sun. Blank = all days.
        WeekPattern := '1|2|3|4|5|6|7';
        if JobTask.Get(JobNo, JobTaskNo) then
            if JobTask."DayPlanning Week Pattern" <> '' then
                WeekPattern := JobTask."DayPlanning Week Pattern";

        // ── Load Base Calendar for holiday classification ─────────────────────
        CalendarLoaded := false;
        if DailyOptimizerSetup.FindFirst() then
            if DailyOptimizerSetup."Base Calendar" <> '' then
                if BaseCalendar.Get(DailyOptimizerSetup."Base Calendar") then begin
                    CalendarMgt.SetSource(BaseCalendar, CustomizedCalendarChange);
                    CalendarLoaded := true;
                end;

        // ── Process existing DayPlanning records (shift / clamp) ─────────────────
        DayPlanning.SetRange("Job No.", JobNo);
        DayPlanning.SetRange("Job Task No.", JobTaskNo);
        DayPlanning.SetRange("Task Date", OldStart, OldEnd);
        if DayPlanning.FindSet() then
            repeat
                NewDate := DayPlanning."Task Date";
                ChangeDays := 0;

                // ── 1.1  Shift Left / Right ──────────────────────────────────────────
                // Both boundary dates moved → shift every DayPlanning by the same offset.
                if (OldStart <> NewStart) and (OldEnd <> NewEnd) then begin
                    ChangeDays := NewStart - OldStart; // negative = left, positive = right
                    NewDate := DayPlanning."Task Date" + ChangeDays;
                end

                // ── 1.2  Enlarge / Reduce Right Bar ──────────────────────────────────
                // Only end date changed → tasks that now fall beyond the new end must move.
                else if (OldStart = NewStart) and (OldEnd <> NewEnd) then begin
                    // Scenario A – Right bar enlarged: existing records unchanged.
                    //              New DayPlanning entries are generated below.
                    // Scenario B – Right bar reduced: clamp tasks that exceed the new end.
                    if (NewEnd < OldEnd) and (DayPlanning."Task Date" > NewEnd) then
                        NewDate := NewEnd;
                end

                // ── 1.3  Enlarge / Reduce Left Bar ───────────────────────────────────
                // Only start date changed → tasks before the new start must move.
                else if (OldStart <> NewStart) and (OldEnd = NewEnd) then begin
                    // Scenario A – Left bar reduced (shifted right):
                    if (NewStart > OldStart) and (DayPlanning."Task Date" < NewStart) then begin
                        ChangeDays := NewStart - OldStart;
                        NewDate := DayPlanning."Task Date" + ChangeDays;
                        if NewDate > NewEnd then
                            NewDate := NewEnd;
                    end;
                    // Scenario B – Left bar enlarged: no action needed.
                end;

                // Add to preview buffer only when the date actually changes.
                if NewDate <> DayPlanning."Task Date" then begin
                    // Classify the new date (Work-day / Weekend / Public-Holiday)
                    DayOfWeek := Date2DWY(NewDate, 1);
                    if DayOfWeek in [6, 7] then
                        DateTypeVal := "DayPlanning Date Type"::Weekend
                    else if CalendarLoaded and CalendarMgt.IsNonworkingDay(NewDate, CustomizedCalendarChange) then
                        DateTypeVal := "DayPlanning Date Type"::"Public-Holiday"
                    else
                        DateTypeVal := "DayPlanning Date Type"::"Work-day";

                    EntryNo += 1;
                    TempPreviewBuffer.Init();
                    TempPreviewBuffer."Entry No." := EntryNo;
                    TempPreviewBuffer."Job No." := DayPlanning."Job No.";
                    TempPreviewBuffer."Job Task No." := DayPlanning."Job Task No.";
                    TempPreviewBuffer."Day Line No." := DayPlanning."Day Line No.";
                    TempPreviewBuffer."Old Task Date" := DayPlanning."Task Date";
                    TempPreviewBuffer."New Task Date" := NewDate;
                    TempPreviewBuffer."Resource No." := DayPlanning."Assigned Resource No.";
                    TempPreviewBuffer.Description := DayPlanning.Description;
                    TempPreviewBuffer."Day Type" := DateTypeVal;
                    TempPreviewBuffer."Convert to DayPlanning" := true;
                    TempPreviewBuffer."Is New Record" := false;
                    TempPreviewBuffer.Insert();
                end;
            until DayPlanning.Next() = 0;

        // ── Scenario A – Right bar enlarged: generate new DayPlanning entries ──────
        // Walk every calendar day in the newly added range (OldEnd+1 .. NewEnd).
        // Only dates whose day-of-week matches the Job Task's "DayPlanning Week Pattern"
        // are included. All matched dates (including weekends / public holidays)
        // appear in the preview so the user can decide which ones to keep.
        if (OldStart = NewStart) and (NewEnd > OldEnd) then begin
            WeekPatternText := WeekPattern;
            CandidateDate := OldEnd + 1;
            while CandidateDate <= NewEnd do begin
                // Check whether this weekday is listed in the pattern
                DayOfWeek := Date2DWY(CandidateDate, 1);
                PatternParts := WeekPatternText.Split('|');
                IsInPattern := false;
                foreach PatternPart in PatternParts do
                    if Evaluate(PatternDay, PatternPart.Trim()) then
                        if PatternDay = DayOfWeek then
                            IsInPattern := true;

                if IsInPattern then begin
                    // Classify the candidate date
                    if DayOfWeek in [6, 7] then
                        DateTypeVal := "DayPlanning Date Type"::Weekend
                    else if CalendarLoaded and CalendarMgt.IsNonworkingDay(CandidateDate, CustomizedCalendarChange) then
                        DateTypeVal := "DayPlanning Date Type"::"Public-Holiday"
                    else
                        DateTypeVal := "DayPlanning Date Type"::"Work-day";

                    EntryNo += 1;
                    TempPreviewBuffer.Init();
                    TempPreviewBuffer."Entry No." := EntryNo;
                    TempPreviewBuffer."Job No." := JobNo;
                    TempPreviewBuffer."Job Task No." := JobTaskNo;
                    TempPreviewBuffer."Day Line No." := 0;      // 0 = new DayPlanning (no existing record)
                    TempPreviewBuffer."Old Task Date" := 0D;    // no previous date
                    TempPreviewBuffer."New Task Date" := CandidateDate;
                    TempPreviewBuffer."Resource No." := '';
                    TempPreviewBuffer.Description := '';
                    TempPreviewBuffer."Day Type" := DateTypeVal;
                    TempPreviewBuffer."Convert to DayPlanning" := true;
                    TempPreviewBuffer."Is New Record" := true;
                    TempPreviewBuffer.Insert();
                end;

                CandidateDate += 1;
            end;
        end;

        exit(not TempPreviewBuffer.IsEmpty());
    end;

    /// <summary>
    /// Applies the confirmed date changes from the preview buffer to the actual DayPlanning records.
    /// Called from the "Apply Changes" action on the preview page.
    /// Issues a Commit() at the end so the Gantt chart data is immediately consistent.
    /// </summary>
    procedure ApplyChanges(var JobTask: Record "Job Task"; var TempPreviewBuffer: Record "DayPlanning Sync PreviewBuff")
    var
        DayPlanning: Record "Day Planning";
    begin
        // Save the Job Task period change first, then update DayPlanning records.
        JobTask.Modify(true);

        TempPreviewBuffer.Reset();
        TempPreviewBuffer.SetRange("Convert to DayPlanning", true);
        if TempPreviewBuffer.FindSet() then
            repeat
                if TempPreviewBuffer."Is New Record" then begin
                    // Right bar enlarged – insert a new DayPlanning for this date.
                    DayPlanning.Init();
                    DayPlanning."Job No." := TempPreviewBuffer."Job No.";
                    DayPlanning."Job Task No." := TempPreviewBuffer."Job Task No.";
                    DayPlanning."Task Date" := TempPreviewBuffer."New Task Date";
                    DayPlanning."Day Line No." := DayPlanning.GetNextDayLineNo(
                        TempPreviewBuffer."New Task Date",
                        TempPreviewBuffer."Job No.",
                        TempPreviewBuffer."Job Task No.");
                    DayPlanning.Insert();
                end else
                    if DayPlanning.Get(TempPreviewBuffer."Job No.", TempPreviewBuffer."Job Task No.", TempPreviewBuffer."Day Line No.") then begin
                        DayPlanning."Task Date" := TempPreviewBuffer."New Task Date";
                        DayPlanning.Modify();
                    end;
            until TempPreviewBuffer.Next() = 0;
        TempPreviewBuffer.SetRange("Convert to DayPlanning");

        Commit();
    end;

    /// <summary>
    /// Shared entry point for handling a Job Task period change from any source (Gantt or page OnValidate).
    /// When SkipJobTaskModify = TRUE the preview only updates DayPlanning records; the page is responsible
    /// for persisting the JobTask. When FALSE the original Gantt behaviour applies (Modify + Commit).
    /// If no DayPlanning records are affected and SkipJobTaskModify = TRUE, returns TRUE immediately
    /// without opening any dialog. Returns FALSE when the user cancels the preview.
    /// </summary>
    procedure HandleJobTaskPeriodChange(var JobTask: Record "Job Task"; OldStart: Date; OldEnd: Date; SkipJobTaskModify: Boolean): Boolean
    var
        TempPreviewBuffer: Record "DayPlanning Sync PreviewBuff" temporary;
        PreviewPage: Page "DayPlanning PeriodSyncPreview";
    begin
        if not CalculateChanges(JobTask."Job No.", JobTask."Job Task No.", OldStart, OldEnd, JobTask.PlannedStartDate, JobTask.PlannedEndDate, TempPreviewBuffer) then
            exit(true);
        if SkipJobTaskModify then
            exit(true); // No DayPlannings affected; the calling page handles the JobTask persist.

        PreviewPage.SetPreviewData(TempPreviewBuffer);
        PreviewPage.SetJobTask(JobTask);
        PreviewPage.SetSkipJobTaskModify(SkipJobTaskModify);
        PreviewPage.RunModal();
        exit(PreviewPage.WasApplied());
    end;

    /// <summary>
    /// Updates DayPlanning dates from the preview buffer without calling JobTask.Modify or Commit.
    /// Used when the calling page manages the full transaction (SkipJobTaskModify = TRUE path).
    /// </summary>
    procedure ApplyChangesOnly(var TempPreviewBuffer: Record "DayPlanning Sync PreviewBuff")
    var
        DayPlanning: Record "Day Planning";
    begin
        TempPreviewBuffer.Reset();
        TempPreviewBuffer.SetRange("Convert to DayPlanning", true);
        if TempPreviewBuffer.FindSet() then
            repeat
                if TempPreviewBuffer."Is New Record" then begin
                    // Right bar enlarged – insert a new DayPlanning for this date.
                    DayPlanning.Init();
                    DayPlanning."Job No." := TempPreviewBuffer."Job No.";
                    DayPlanning."Job Task No." := TempPreviewBuffer."Job Task No.";
                    DayPlanning."Task Date" := TempPreviewBuffer."New Task Date";
                    DayPlanning."Day Line No." := DayPlanning.GetNextDayLineNo(
                        TempPreviewBuffer."New Task Date",
                        TempPreviewBuffer."Job No.",
                        TempPreviewBuffer."Job Task No.");
                    DayPlanning.Insert();
                end else
                    if DayPlanning.Get(TempPreviewBuffer."Job No.", TempPreviewBuffer."Job Task No.", TempPreviewBuffer."Day Line No.") then begin
                        DayPlanning."Task Date" := TempPreviewBuffer."New Task Date";
                        DayPlanning.Modify();
                    end;
            until TempPreviewBuffer.Next() = 0;
        TempPreviewBuffer.SetRange("Convert to DayPlanning");
    end;
}
