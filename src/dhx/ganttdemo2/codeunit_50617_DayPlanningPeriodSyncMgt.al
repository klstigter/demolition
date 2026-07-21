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
    ///
    /// Active-day resolution: the Work-Hour Template used to decide which weekdays are
    /// active is the Job Task's own "Work Hour Template" if set, else Daily Optimizer
    /// Setup's "Work hour Template". "Base Calendar" on Daily Optimizer Setup is mandatory —
    /// this errors (via "Day Plannings Mgt.".IsActiveWorkDay's TestField) rather than
    /// silently skipping calendar checks when it's blank.
    ///
    /// Cascading: every existing DayPlanning date is first mapped to a "naive" target date
    /// using the same flat offset/clamp arithmetic as before (CalculateNaiveNewDate). Those
    /// naive dates are then walked in chronological order and pushed forward, one distinct
    /// original date at a time, onto the next active day whenever the naive target lands on
    /// an inactive day (per the resolved Work-Hour Template / Base Calendar) OR would
    /// otherwise land on/before the previous entry's already-adjusted date — so a push
    /// caused by one off-day collision carries forward through the rest of the sequence
    /// instead of only correcting the single colliding date. Naive dates that were already
    /// identical to each other (e.g. several DayPlanning rows clamped onto the same new end
    /// date when a task is shortened) are deliberately kept collapsed onto the same final
    /// date rather than being spread out — only genuinely distinct target dates get pushed
    /// apart from one another.
    /// </summary>
    procedure CalculateChanges(JobNo: Code[20]; JobTaskNo: Code[20]; OldStart: Date; OldEnd: Date; NewStart: Date; NewEnd: Date; var TempPreviewBuffer: Record "DayPlanning Sync PreviewBuff" temporary): Boolean
    var
        DayPlanning: Record "Day Planning";
        JobTask: Record "Job Task";
        DailyOptimizerSetup: Record "Daily Optimizer Setup";
        DayPlanningMgt: Codeunit "Day Plannings Mgt.";
        EffectiveWorkHourTemplate: Code[20];
        EntryNo: Integer;
        NewDate: Date;
        CandidateDate: Date;
        NaiveDate: Date;
        PrevNaiveDate: Date;
        PrevAdjustedDate: Date;
        OldDates: List of [Date];
        OldDateItem: Date;
        NaiveDateMap: Dictionary of [Date, Date];
        AdjustedDateMap: Dictionary of [Date, Date];
    begin
        TempPreviewBuffer.Reset();
        TempPreviewBuffer.DeleteAll();

        // ── Resolve the effective Work-Hour Template and mandatory Base Calendar ──────
        DailyOptimizerSetup.Get();
        DailyOptimizerSetup.TestField("Base Calendar");

        EffectiveWorkHourTemplate := '';
        if JobTask.Get(JobNo, JobTaskNo) then
            EffectiveWorkHourTemplate := JobTask."Work Hour Template";
        if EffectiveWorkHourTemplate = '' then
            EffectiveWorkHourTemplate := DailyOptimizerSetup."Work hour Template";

        // ── Pass 1 — compute the naive (flat offset/clamp) target date for every
        // distinct original Task Date in range, exactly as the old scenario logic did. ──
        DayPlanning.SetCurrentKey("Work Date");
        DayPlanning.SetRange("Job No.", JobNo);
        DayPlanning.SetRange("Job Task No.", JobTaskNo);
        DayPlanning.SetRange("Work Date", OldStart, OldEnd);
        if DayPlanning.FindSet() then
            repeat
                if not NaiveDateMap.ContainsKey(DayPlanning."Work Date") then begin
                    NaiveDate := CalculateNaiveNewDate(DayPlanning."Work Date", OldStart, OldEnd, NewStart, NewEnd);
                    if NaiveDate <> DayPlanning."Work Date" then begin
                        NaiveDateMap.Add(DayPlanning."Work Date", NaiveDate);
                        OldDates.Add(DayPlanning."Work Date");
                    end;
                end;
            until DayPlanning.Next() = 0;

        // ── Pass 2 — walk the distinct original dates in chronological order and
        // cascade-adjust each naive target onto the next active day. ──────────────────
        PrevNaiveDate := 0D;
        PrevAdjustedDate := 0D;
        foreach OldDateItem in OldDates do begin
            NaiveDate := NaiveDateMap.Get(OldDateItem);

            if (PrevNaiveDate <> 0D) and (NaiveDate = PrevNaiveDate) then
                // Same naive target as the previous distinct date (e.g. both clamped onto
                // the same new end date) — deliberately collapse onto the same final date,
                // already validated as active by the previous iteration.
                CandidateDate := PrevAdjustedDate
            else begin
                if (PrevAdjustedDate <> 0D) and (NaiveDate <= PrevAdjustedDate) then
                    CandidateDate := PrevAdjustedDate + 1
                else
                    CandidateDate := NaiveDate;
                while not DayPlanningMgt.IsActiveWorkDay(EffectiveWorkHourTemplate, CandidateDate) do
                    CandidateDate += 1;
            end;

            AdjustedDateMap.Add(OldDateItem, CandidateDate);
            PrevNaiveDate := NaiveDate;
            PrevAdjustedDate := CandidateDate;
        end;

        // ── Pass 3 — build the preview buffer for every affected DayPlanning row,
        // using each row's Task Date to look up its cascaded final date. ─────────────
        DayPlanning.SetRange("Work Date", OldStart, OldEnd);
        if DayPlanning.FindSet() then
            repeat
                if AdjustedDateMap.ContainsKey(DayPlanning."Work Date") then begin
                    NewDate := AdjustedDateMap.Get(DayPlanning."Work Date");

                    EntryNo += 1;
                    TempPreviewBuffer.Init();
                    TempPreviewBuffer."Entry No." := EntryNo;
                    TempPreviewBuffer."Job No." := DayPlanning."Job No.";
                    TempPreviewBuffer."Job Task No." := DayPlanning."Job Task No.";
                    TempPreviewBuffer."Day Line No." := DayPlanning."Day Line No.";
                    TempPreviewBuffer."Old Task Date" := DayPlanning."Work Date";
                    TempPreviewBuffer."New Task Date" := NewDate;
                    TempPreviewBuffer."Day Name" := Format(NewDate, 0, '<Weekday Text>');
                    TempPreviewBuffer."Resource No." := DayPlanning."Assigned Resource No.";
                    TempPreviewBuffer.Description := DayPlanning.Description;
                    // By construction every cascaded date is an active day (Pass 2 only
                    // ever advances onto one), so this is always Work-day now — off-day
                    // collisions are resolved automatically rather than left for the user
                    // to classify/opt out of.
                    TempPreviewBuffer."Day Type" := "DayPlanning Date Type"::"Work-day";
                    TempPreviewBuffer."Convert to DayPlanning" := true;
                    TempPreviewBuffer."Is New Record" := false;
                    TempPreviewBuffer.Insert();
                end;
            until DayPlanning.Next() = 0;

        // ── Scenario A – Right bar enlarged: generate new DayPlanning entries ──────
        // Walk every calendar day in the newly added range (OldEnd+1 .. NewEnd) and add
        // an entry for each active day (per the resolved Work-Hour Template + mandatory
        // Base Calendar) — inactive days are simply skipped, not shown for opt-out,
        // consistent with Pass 3 now only ever surfacing active days.
        if (OldStart = NewStart) and (NewEnd > OldEnd) then begin
            CandidateDate := OldEnd + 1;
            while CandidateDate <= NewEnd do begin
                if DayPlanningMgt.IsActiveWorkDay(EffectiveWorkHourTemplate, CandidateDate) then begin
                    EntryNo += 1;
                    TempPreviewBuffer.Init();
                    TempPreviewBuffer."Entry No." := EntryNo;
                    TempPreviewBuffer."Job No." := JobNo;
                    TempPreviewBuffer."Job Task No." := JobTaskNo;
                    TempPreviewBuffer."Day Line No." := 0;      // 0 = new DayPlanning (no existing record)
                    TempPreviewBuffer."Old Task Date" := 0D;    // no previous date
                    TempPreviewBuffer."New Task Date" := CandidateDate;
                    TempPreviewBuffer."Day Name" := Format(CandidateDate, 0, '<Weekday Text>');
                    TempPreviewBuffer."Resource No." := '';
                    TempPreviewBuffer.Description := '';
                    TempPreviewBuffer."Day Type" := "DayPlanning Date Type"::"Work-day";
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
    /// Computes the flat-offset/clamp target date for a single original Task Date, per the
    /// same scenario rules the old (pre-cascade) implementation used. This is deliberately
    /// pure/stateless — it has no knowledge of active days or other DayPlanning rows; that's
    /// layered on top by CalculateChanges' Pass 2 cascade walk.
    /// </summary>
    local procedure CalculateNaiveNewDate(TaskDate: Date; OldStart: Date; OldEnd: Date; NewStart: Date; NewEnd: Date) NewDate: Date
    var
        ChangeDays: Integer;
    begin
        NewDate := TaskDate;

        // ── 1.1  Shift Left / Right ──────────────────────────────────────────────
        // Both boundary dates moved → shift every DayPlanning by the same offset.
        if (OldStart <> NewStart) and (OldEnd <> NewEnd) then begin
            ChangeDays := NewStart - OldStart; // negative = left, positive = right
            NewDate := TaskDate + ChangeDays;
        end

        // ── 1.2  Enlarge / Reduce Right Bar ──────────────────────────────────────
        // Only end date changed → tasks that now fall beyond the new end must move.
        else if (OldStart = NewStart) and (OldEnd <> NewEnd) then begin
            // Scenario A – Right bar enlarged: existing records unchanged (new
            //              DayPlanning entries are generated separately).
            // Scenario B – Right bar reduced: clamp tasks that exceed the new end.
            if (NewEnd < OldEnd) and (TaskDate > NewEnd) then
                NewDate := NewEnd;
        end

        // ── 1.3  Enlarge / Reduce Left Bar ───────────────────────────────────────
        // Only start date changed → tasks before the new start must move.
        else if (OldStart <> NewStart) and (OldEnd = NewEnd) then
            // Scenario A – Left bar reduced (shifted right):
            if (NewStart > OldStart) and (TaskDate < NewStart) then begin
                ChangeDays := NewStart - OldStart;
                NewDate := TaskDate + ChangeDays;
                if NewDate > NewEnd then
                    NewDate := NewEnd;
            end;
        // Scenario B – Left bar enlarged: no action needed (falls through, NewDate = TaskDate).
    end;

    /// <summary>
    /// Returns the latest "New Task Date" among preview buffer rows still flagged for
    /// conversion (i.e. rows the user has not unchecked). Rows with "Convert to DayPlanning"
    /// = false are excluded because they are never applied to DayPlanning by ApplyChanges/
    /// ApplyChangesOnly, so they must not influence the Job Task's end-date extension either.
    /// </summary>
    local procedure GetMaxNewTaskDate(var TempPreviewBuffer: Record "DayPlanning Sync PreviewBuff" temporary): Date
    var
        MaxDate: Date;
    begin
        TempPreviewBuffer.Reset();
        TempPreviewBuffer.SetRange("Convert to DayPlanning", true);
        if TempPreviewBuffer.FindSet() then
            repeat
                if TempPreviewBuffer."New Task Date" > MaxDate then
                    MaxDate := TempPreviewBuffer."New Task Date";
            until TempPreviewBuffer.Next() = 0;
        TempPreviewBuffer.SetRange("Convert to DayPlanning");
        exit(MaxDate);
    end;

    /// <summary>
    /// Guards against the Pass 2 cascade walk in CalculateChanges pushing a DayPlanning's
    /// final date past the originally-requested NewEnd (no clamp-back exists there when an
    /// off-day collision forces a date forward). Extends the Job Task's Planned Ending Date
    /// to match the latest applied "New Task Date" so the task's own planned range always
    /// fully covers the DayPlanning dates it owns. Deliberately end-date only — no symmetric
    /// Start Date extension.
    /// </summary>
    local procedure ExtendJobTaskEndDateIfNeeded(var JobTask: Record "Job Task"; var TempPreviewBuffer: Record "DayPlanning Sync PreviewBuff" temporary)
    var
        MaxNewDate: Date;
    begin
        MaxNewDate := GetMaxNewTaskDate(TempPreviewBuffer);
        if (MaxNewDate <> 0D) and (MaxNewDate > JobTask.PlannedEndDate) then
            JobTask.PlannedEndDate := MaxNewDate;
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
        ExtendJobTaskEndDateIfNeeded(JobTask, TempPreviewBuffer);

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
                    DayPlanning."Work Date" := TempPreviewBuffer."New Task Date";
                    DayPlanning."Day Line No." := DayPlanning.GetNextDayLineNo(
                        TempPreviewBuffer."New Task Date",
                        TempPreviewBuffer."Job No.",
                        TempPreviewBuffer."Job Task No.");
                    DayPlanning.Insert();
                end else
                    if DayPlanning.Get(TempPreviewBuffer."Job No.", TempPreviewBuffer."Job Task No.", TempPreviewBuffer."Day Line No.") then begin
                        DayPlanning."Work Date" := TempPreviewBuffer."New Task Date";
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
                    DayPlanning."Work Date" := TempPreviewBuffer."New Task Date";
                    DayPlanning."Day Line No." := DayPlanning.GetNextDayLineNo(
                        TempPreviewBuffer."New Task Date",
                        TempPreviewBuffer."Job No.",
                        TempPreviewBuffer."Job Task No.");
                    DayPlanning.Insert();
                end else
                    if DayPlanning.Get(TempPreviewBuffer."Job No.", TempPreviewBuffer."Job Task No.", TempPreviewBuffer."Day Line No.") then begin
                        DayPlanning."Work Date" := TempPreviewBuffer."New Task Date";
                        DayPlanning.Modify();
                    end;
            until TempPreviewBuffer.Next() = 0;
        TempPreviewBuffer.SetRange("Convert to DayPlanning");
    end;
}
