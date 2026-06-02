codeunit 50617 "DayTask Period Sync Mgt."
{
    /// <summary>
    /// Entry point called from "Gantt Update Data" when a Job Task planned period changes.
    /// Calculates impacted DayTask records and opens a preview popup for user confirmation.
    /// No database changes occur before the user clicks Apply Changes.
    /// </summary>
    procedure ShowPreview(var JobTask: Record "Job Task"; JobNo: Code[20]; JobTaskNo: Code[20]; OldStart: Date; OldEnd: Date; NewStart: Date; NewEnd: Date): Boolean
    var
        TempPreviewBuffer: Record "DayTask Sync Preview Buffer" temporary;
        PreviewPage: Page "DayTask Period Sync Preview";
    begin
        // Calculate impacted DayTask records (buffer may be empty when no Day Tasks are linked).
        // Always open the preview page so the user can confirm or cancel the period change.
        if (OldStart = 0D) or (OldEnd = 0D) or (NewStart = 0D) or (NewEnd = 0D) then
            exit(true); // No valid dates to compare, skip preview and apply changes directly.

        CalculateChanges(JobNo, JobTaskNo, OldStart, OldEnd, NewStart, NewEnd, TempPreviewBuffer);

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
    procedure CalculateChanges(JobNo: Code[20]; JobTaskNo: Code[20]; OldStart: Date; OldEnd: Date; NewStart: Date; NewEnd: Date; var TempPreviewBuffer: Record "DayTask Sync Preview Buffer" temporary): Boolean
    var
        DayTask: Record "Day Tasks";
        EntryNo: Integer;
        NewDate: Date;
        ChangeDays: Integer;
    begin
        TempPreviewBuffer.Reset();
        TempPreviewBuffer.DeleteAll();

        DayTask.SetRange("Job No.", JobNo);
        DayTask.SetRange("Job Task No.", JobTaskNo);
        DayTask.SetRange("Task Date", OldStart, OldEnd);
        if not DayTask.FindSet() then
            exit(false);

        repeat
            NewDate := DayTask."Task Date";
            ChangeDays := 0;

            // ── 1.1  Shift Left / Right ─────────────────────────────────────────────
            // Both boundary dates moved → shift every DayTask by the same offset.
            if (OldStart <> NewStart) and (OldEnd <> NewEnd) then begin
                ChangeDays := NewStart - OldStart; // negative = left, positive = right
                NewDate := DayTask."Task Date" + ChangeDays;
            end

            // ── 1.2  Enlarge / Reduce Right Bar ─────────────────────────────────────
            // Only end date changed → tasks that now fall beyond the new end must move.
            else if (OldStart = NewStart) and (OldEnd <> NewEnd) then begin
                // Scenario A – Right bar enlarged: no action needed.
                // Scenario B – Right bar reduced: clamp tasks that exceed the new end.
                if (NewEnd < OldEnd) and (DayTask."Task Date" > NewEnd) then
                    NewDate := NewEnd;
            end

            // ── 1.3  Enlarge / Reduce Left Bar ──────────────────────────────────────
            // Only start date changed → tasks that now fall before the new start must move.
            else if (OldStart <> NewStart) and (OldEnd = NewEnd) then begin
                // Scenario A – Left bar reduced (shifted right):
                //   push tasks that are before the new start forward by ChangeDays.
                if (NewStart > OldStart) and (DayTask."Task Date" < NewStart) then begin
                    ChangeDays := NewStart - OldStart; // positive
                    NewDate := DayTask."Task Date" + ChangeDays;
                    // Must not exceed the (unchanged) end date.
                    if NewDate > NewEnd then
                        NewDate := NewEnd;
                end;
                // Scenario B – Left bar enlarged: no action needed.
            end;

            // Add to preview buffer only when the date actually changes.
            if NewDate <> DayTask."Task Date" then begin
                EntryNo += 1;
                TempPreviewBuffer.Init();
                TempPreviewBuffer."Entry No." := EntryNo;
                TempPreviewBuffer."Job No." := DayTask."Job No.";
                TempPreviewBuffer."Job Task No." := DayTask."Job Task No.";
                TempPreviewBuffer."Day Line No." := DayTask."Day Line No.";
                TempPreviewBuffer."Old Task Date" := DayTask."Task Date";
                TempPreviewBuffer."New Task Date" := NewDate;
                TempPreviewBuffer."Resource No." := DayTask."Assigned Resource No.";
                TempPreviewBuffer.Description := DayTask.Description;
                TempPreviewBuffer.Insert();
            end;
        until DayTask.Next() = 0;

        exit(not TempPreviewBuffer.IsEmpty());
    end;

    /// <summary>
    /// Applies the confirmed date changes from the preview buffer to the actual DayTask records.
    /// Called from the "Apply Changes" action on the preview page.
    /// Issues a Commit() at the end so the Gantt chart data is immediately consistent.
    /// </summary>
    procedure ApplyChanges(var JobTask: Record "Job Task"; var TempPreviewBuffer: Record "DayTask Sync Preview Buffer")
    var
        DayTask: Record "Day Tasks";
    begin
        // Save the Job Task period change first, then update DayTask records.
        JobTask.Modify(true);

        TempPreviewBuffer.Reset();
        if TempPreviewBuffer.FindSet() then
            repeat
                if DayTask.Get(TempPreviewBuffer."Job No.", TempPreviewBuffer."Job Task No.", TempPreviewBuffer."Day Line No.") then begin
                    DayTask."Task Date" := TempPreviewBuffer."New Task Date";
                    DayTask.Modify();
                end;
            until TempPreviewBuffer.Next() = 0;

        Commit();
    end;

    /// <summary>
    /// Shared entry point for handling a Job Task period change from any source (Gantt or page OnValidate).
    /// When SkipJobTaskModify = TRUE the preview only updates DayTask records; the page is responsible
    /// for persisting the JobTask. When FALSE the original Gantt behaviour applies (Modify + Commit).
    /// If no DayTask records are affected and SkipJobTaskModify = TRUE, returns TRUE immediately
    /// without opening any dialog. Returns FALSE when the user cancels the preview.
    /// </summary>
    procedure HandleJobTaskPeriodChange(var JobTask: Record "Job Task"; OldStart: Date; OldEnd: Date; SkipJobTaskModify: Boolean): Boolean
    var
        TempPreviewBuffer: Record "DayTask Sync Preview Buffer" temporary;
        PreviewPage: Page "DayTask Period Sync Preview";
    begin
        if not CalculateChanges(JobTask."Job No.", JobTask."Job Task No.", OldStart, OldEnd, JobTask.PlannedStartDate, JobTask.PlannedEndDate, TempPreviewBuffer) then
            if SkipJobTaskModify then
                exit(true); // No DayTasks affected; the calling page handles the JobTask persist.

        PreviewPage.SetPreviewData(TempPreviewBuffer);
        PreviewPage.SetJobTask(JobTask);
        PreviewPage.SetSkipJobTaskModify(SkipJobTaskModify);
        PreviewPage.RunModal();
        exit(PreviewPage.WasApplied());
    end;

    /// <summary>
    /// Updates DayTask dates from the preview buffer without calling JobTask.Modify or Commit.
    /// Used when the calling page manages the full transaction (SkipJobTaskModify = TRUE path).
    /// </summary>
    procedure ApplyChangesOnly(var TempPreviewBuffer: Record "DayTask Sync Preview Buffer")
    var
        DayTask: Record "Day Tasks";
    begin
        TempPreviewBuffer.Reset();
        if TempPreviewBuffer.FindSet() then
            repeat
                if DayTask.Get(TempPreviewBuffer."Job No.", TempPreviewBuffer."Job Task No.", TempPreviewBuffer."Day Line No.") then begin
                    DayTask."Task Date" := TempPreviewBuffer."New Task Date";
                    DayTask.Modify();
                end;
            until TempPreviewBuffer.Next() = 0;
    end;
}
