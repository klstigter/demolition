codeunit 50617 "DayPlanning Period Sync Mgt."
{
    // Shared across every helper procedure invoked from a single CalculateChanges() call so its
    // internal Base Calendar / Work-Hour Template memoization (see codeunit 50610's gCalendarLoaded/
    // gCachedWorkHourTemplateCode) is only populated once per reschedule, not once per candidate date
    // or per resource.
    var
        DayPlanningMgt: Codeunit "Day Plannings Mgt.";

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
    /// Cascading: for every resource that has a matching "Day Planning Pattern" for this Job
    /// Task, its existing DayPlanning rows are redistributed onto that pattern's active days
    /// within NewStart..NewEnd (see RedistributeUsingPattern) — rows are reused/moved
    /// (Plan Date only), never deleted or recreated. For every other resource (no matching
    /// pattern), the previous flat offset/clamp + cascade logic applies unchanged (see
    /// MapRowsUsingNaiveCascade / CalculateNaiveNewDate): every existing DayPlanning date is
    /// first mapped to a "naive" target date, then distinct naive targets are walked in
    /// chronological order and pushed forward onto the next active day whenever the naive
    /// target lands on an inactive day OR would otherwise land on/before the previous entry's
    /// already-adjusted date — this push is deliberately forward-only and unbounded: if an
    /// off-day collision would need to go past NewEnd, it does, and ExtendJobTaskEndDateIfNeeded
    /// stretches the Job Task's own Planned End Date to cover the overshoot instead of clamping
    /// DayPlanning dates backward. For the Right-Bar-Reduced and Left-Bar-Reduced scenarios
    /// specifically, an overflowing row is never combined onto another row's date while a free
    /// active work day still exists within NewStart..NewEnd: MapRowsUsingNaiveCascade first
    /// searches for the nearest unoccupied active day (backward from NewEnd for Right-Bar-Reduced,
    /// forward from NewStart for Left-Bar-Reduced) before falling back to collapsing onto the
    /// naive boundary date — that collapse remains as a last resort only, used when no free
    /// active day remains anywhere in the range. The Shift scenario is unaffected by this change:
    /// its per-row offset is constant, so distinct original dates never naively collide with one
    /// another in the first place.
    /// </summary>
    procedure CalculateChanges(JobNo: Code[20]; JobTaskNo: Code[20]; OldStart: Date; OldEnd: Date; NewStart: Date; NewEnd: Date; var TempPreviewBuffer: Record "DayPlanning Sync PreviewBuff" temporary): Boolean
    var
        DayPlanning: Record "Day Planning";
        JobTask: Record "Job Task";
        DailyOptimizerSetup: Record "Daily Optimizer Setup";
        DayPlanningPattern: Record "Day Planning Pattern";
        EffectiveWorkHourTemplate: Code[20];
        EntryNo: Integer;
        NewDate: Date;
        CandidateDate: Date;
        ResourceList: List of [Code[20]];
        ResourceNo: Code[20];
        RowNewDateMap: Dictionary of [Integer, Date];
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

        // ── Per resource, decide pattern-based redistribution vs. naive+cascade fallback,
        // and populate RowNewDateMap (Day Line No. -> new Plan Date) for every affected row.
        // Row-level (not date-level) keys are required here because two different resources
        // can legitimately follow two different patterns even when their existing rows share
        // the same original Plan Date. ──────────────────────────────────────────────────
        GetAffectedResources(JobNo, JobTaskNo, OldStart, OldEnd, ResourceList);
        foreach ResourceNo in ResourceList do
            if FindMatchingDayPlanningPattern(JobNo, JobTaskNo, ResourceNo, DayPlanningPattern) then
                RedistributeUsingPattern(JobNo, JobTaskNo, ResourceNo, OldStart, OldEnd, NewStart, NewEnd, DayPlanningPattern."Work-Hour Template", RowNewDateMap)
            else
                MapRowsUsingNaiveCascade(JobNo, JobTaskNo, ResourceNo, OldStart, OldEnd, NewStart, NewEnd, EffectiveWorkHourTemplate, RowNewDateMap);

        // ── Build the preview buffer for every affected DayPlanning row, using each row's
        // own Day Line No. to look up its redistributed/cascaded final date. ─────────────
        DayPlanning.SetRange("Job No.", JobNo);
        DayPlanning.SetRange("Job Task No.", JobTaskNo);
        DayPlanning.SetRange("Plan Date", OldStart, OldEnd);
        if DayPlanning.FindSet() then
            repeat
                if RowNewDateMap.ContainsKey(DayPlanning."Day Line No.") then begin
                    NewDate := RowNewDateMap.Get(DayPlanning."Day Line No.");
                    if NewDate <> DayPlanning."Plan Date" then begin
                        EntryNo += 1;
                        TempPreviewBuffer.Init();
                        TempPreviewBuffer."Entry No." := EntryNo;
                        TempPreviewBuffer."Job No." := DayPlanning."Job No.";
                        TempPreviewBuffer."Job Task No." := DayPlanning."Job Task No.";
                        TempPreviewBuffer."Day Line No." := DayPlanning."Day Line No.";
                        TempPreviewBuffer."Old Task Date" := DayPlanning."Plan Date";
                        TempPreviewBuffer."New Task Date" := NewDate;
                        TempPreviewBuffer."Day Name" := Format(NewDate, 0, '<Weekday Text>');
                        TempPreviewBuffer."Old Day Name" := Format(DayPlanning."Plan Date", 0, '<Weekday Text>');
                        TempPreviewBuffer."Resource No." := DayPlanning."Assigned Resource No.";
                        TempPreviewBuffer.Description := DayPlanning.Description;
                        // By construction every redistributed/cascaded date is an active day,
                        // so this is always Work-day now — off-day collisions are resolved
                        // automatically rather than left for the user to classify/opt out of.
                        TempPreviewBuffer."Day Type" := "DayPlanning Date Type"::"Work-day";
                        TempPreviewBuffer."Convert to DayPlanning" := true;
                        TempPreviewBuffer."Is New Record" := false;
                        TempPreviewBuffer.Insert();
                    end;
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
    /// Returns DateToSnap unchanged if it's already an active work day (per JobTask's own
    /// "Work Hour Template" if set, else Daily Optimizer Setup's "Work hour Template", checked
    /// against the mandatory Base Calendar) - otherwise walks forward day by day until it finds
    /// one. Used to keep a Job Task's Planned End Date from ever landing on a non-working day:
    /// the boundary enlarges forward to the next workday rather than staying stuck on a holiday.
    /// </summary>
    procedure SnapForwardToWorkDay(JobTask: Record "Job Task"; DateToSnap: Date): Date
    var
        DailyOptimizerSetup: Record "Daily Optimizer Setup";
        EffectiveWorkHourTemplate: Code[20];
    begin
        if DateToSnap = 0D then
            exit(DateToSnap);
        DailyOptimizerSetup.Get();
        DailyOptimizerSetup.TestField("Base Calendar");
        EffectiveWorkHourTemplate := JobTask."Work Hour Template";
        if EffectiveWorkHourTemplate = '' then
            EffectiveWorkHourTemplate := DailyOptimizerSetup."Work hour Template";
        while not DayPlanningMgt.IsActiveWorkDay(EffectiveWorkHourTemplate, DateToSnap) do
            DateToSnap += 1;
        exit(DateToSnap);
    end;

    /// <summary>
    /// Resolves the effective Work-Hour Template for a Job Task: its own "Work Hour Template" if
    /// set, else Daily Optimizer Setup's "Work hour Template". Mirrors the inline resolution
    /// already duplicated in CalculateChanges and SnapForwardToWorkDay - added here as a separate
    /// procedure rather than refactoring those two (both are part of the tested reschedule-cascade
    /// logic) so page 50662's manual "New Date" edit has a Job-Task-record-shaped entry point to
    /// call without touching that logic.
    /// </summary>
    procedure ResolveEffectiveWorkHourTemplate(JobTask: Record "Job Task"): Code[20]
    var
        DailyOptimizerSetup: Record "Daily Optimizer Setup";
        EffectiveWorkHourTemplate: Code[20];
    begin
        DailyOptimizerSetup.Get();
        DailyOptimizerSetup.TestField("Base Calendar");

        EffectiveWorkHourTemplate := JobTask."Work Hour Template";
        if EffectiveWorkHourTemplate = '' then
            EffectiveWorkHourTemplate := DailyOptimizerSetup."Work hour Template";
        exit(EffectiveWorkHourTemplate);
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
    /// Collects the distinct "Assigned Resource No." values (blank included) among the
    /// DayPlanning rows for JobNo/JobTaskNo currently sitting in OldStart..OldEnd. Each
    /// resource is redistributed independently in CalculateChanges (pattern-based or naive
    /// cascade) since two resources on the same Job Task can legitimately follow two different
    /// patterns even when their existing rows share the same original Plan Date.
    /// </summary>
    local procedure GetAffectedResources(JobNo: Code[20]; JobTaskNo: Code[20]; OldStart: Date; OldEnd: Date; var ResourceList: List of [Code[20]])
    var
        DayPlanning: Record "Day Planning";
    begin
        Clear(ResourceList);
        DayPlanning.SetRange("Job No.", JobNo);
        DayPlanning.SetRange("Job Task No.", JobTaskNo);
        DayPlanning.SetRange("Plan Date", OldStart, OldEnd);
        if DayPlanning.FindSet() then
            repeat
                if not ResourceList.Contains(DayPlanning."Assigned Resource No.") then
                    ResourceList.Add(DayPlanning."Assigned Resource No.");
            until DayPlanning.Next() = 0;
    end;

    /// <summary>
    /// Looks up the "Day Planning Pattern" for JobNo/JobTaskNo/ResourceNo (a blank ResourceNo
    /// matches a skill-based pattern that itself has a blank "Resource No."). Returns false
    /// when no pattern exists or the match has no "Work-Hour Template" set, in which case the
    /// caller falls back to the naive offset/clamp cascade for that resource's rows.
    /// </summary>
    local procedure FindMatchingDayPlanningPattern(JobNo: Code[20]; JobTaskNo: Code[20]; ResourceNo: Code[20]; var DayPlanningPattern: Record "Day Planning Pattern"): Boolean
    begin
        DayPlanningPattern.SetRange("Job No.", JobNo);
        DayPlanningPattern.SetRange("Job Task No.", JobTaskNo);
        DayPlanningPattern.SetRange("Resource No.", ResourceNo);
        DayPlanningPattern.SetFilter("Work-Hour Template", '<>%1', '');
        exit(DayPlanningPattern.FindFirst());
    end;

    /// <summary>
    /// Walks every calendar day in RangeStart..RangeEnd and collects the ones that are active
    /// per WorkHourTemplateCode + the mandatory Base Calendar (via "Day Plannings Mgt."'s
    /// IsActiveWorkDay), in chronological order.
    /// </summary>
    local procedure GetActiveDaysInRange(WorkHourTemplateCode: Code[20]; RangeStart: Date; RangeEnd: Date; var ActiveDays: List of [Date])
    var
        D: Date;
    begin
        Clear(ActiveDays);
        D := RangeStart;
        while D <= RangeEnd do begin
            if DayPlanningMgt.IsActiveWorkDay(WorkHourTemplateCode, D) then
                ActiveDays.Add(D);
            D += 1;
        end;
    end;

    /// <summary>
    /// Redistributes one resource's existing DayPlanning rows (chronological by current Plan
    /// Date) onto that resource's pattern-derived active days within NewStart..NewEnd
    /// (chronological), matched 1:1 by position — reusing/moving each row's Plan Date only, the
    /// row itself (Day Line No.) is never deleted or recreated. If there are more rows than
    /// active days found within NewStart..NewEnd, the active-day window is extended one day at a
    /// time past NewEnd (still gated by IsActiveWorkDay) until every row has a target — the Job
    /// Task's own Planned End Date is what should stretch to cover the overshoot (see
    /// ExtendJobTaskEndDateIfNeeded), not the DayPlanning rows collapsing to fit inside a fixed
    /// boundary. The forward search is bounded to a safety limit (~3 years past NewEnd); if that
    /// limit is hit (e.g. a template with no active weekday at all) the previous "collapse onto
    /// the last found active day" behavior is used as an absolute last resort so a row is never
    /// left unmapped or dropped.
    /// </summary>
    local procedure RedistributeUsingPattern(JobNo: Code[20]; JobTaskNo: Code[20]; ResourceNo: Code[20]; OldStart: Date; OldEnd: Date; NewStart: Date; NewEnd: Date; WorkHourTemplateCode: Code[20]; var RowNewDateMap: Dictionary of [Integer, Date])
    var
        DayPlanning: Record "Day Planning";
        ActiveDays: List of [Date];
        RowLineNos: List of [Integer];
        Idx: Integer;
        TargetDate: Date;
        ExtendDate: Date;
        SafetyLimitDate: Date;
    begin
        GetActiveDaysInRange(WorkHourTemplateCode, NewStart, NewEnd, ActiveDays);

        DayPlanning.SetCurrentKey("Plan Date");
        DayPlanning.SetRange("Job No.", JobNo);
        DayPlanning.SetRange("Job Task No.", JobTaskNo);
        DayPlanning.SetRange("Assigned Resource No.", ResourceNo);
        DayPlanning.SetRange("Plan Date", OldStart, OldEnd);
        if DayPlanning.FindSet() then
            repeat
                RowLineNos.Add(DayPlanning."Day Line No.");
            until DayPlanning.Next() = 0;

        // More rows than active days found within NewStart..NewEnd: keep extending the search
        // forward past NewEnd (bounded to a safety limit) instead of collapsing surplus rows
        // onto the last active day already found.
        if RowLineNos.Count() > ActiveDays.Count() then begin
            SafetyLimitDate := NewEnd + 1100; // ~3 years, guards against a template with no active weekday ever
            ExtendDate := NewEnd + 1;
            while (ActiveDays.Count() < RowLineNos.Count()) and (ExtendDate <= SafetyLimitDate) do begin
                if DayPlanningMgt.IsActiveWorkDay(WorkHourTemplateCode, ExtendDate) then
                    ActiveDays.Add(ExtendDate);
                ExtendDate += 1;
            end;
        end;

        for Idx := 1 to RowLineNos.Count() do begin
            if ActiveDays.Count() = 0 then
                TargetDate := NewEnd // extreme edge case: no active day in scope, hard-clamp rather than drop the row
            else
                if Idx <= ActiveDays.Count() then
                    TargetDate := ActiveDays.Get(Idx)
                else
                    TargetDate := ActiveDays.Get(ActiveDays.Count()); // safety limit hit: last-resort collapse onto the last one found
            RowNewDateMap.Add(RowLineNos.Get(Idx), TargetDate);
        end;
    end;

    /// <summary>
    /// Searches RangeStart..RangeEnd (backward from RangeEnd toward RangeStart when
    /// SearchBackward = true, else forward from RangeStart toward RangeEnd) for the nearest date
    /// that is both an active work day (per WorkHourTemplateCode) and not already spoken for —
    /// i.e. not in OccupiedDates (dates held by DayPlanning rows for this resource/task that are
    /// staying at their own original date) nor in ClaimedDates (dates already assigned to another
    /// overflowing row earlier in this same MapRowsUsingNaiveCascade pass). Used by the
    /// Right-Bar-Reduced / Left-Bar-Reduced branches of Pass 2 to spread overflowing rows onto
    /// free space instead of combining them onto the naive boundary date. Returns false when no
    /// such date exists anywhere in the range, in which case the caller falls back to the
    /// original collapse-onto-boundary behavior.
    /// </summary>
    local procedure FindNearestFreeActiveDate(RangeStart: Date; RangeEnd: Date; SearchBackward: Boolean; WorkHourTemplateCode: Code[20]; var OccupiedDates: List of [Date]; var ClaimedDates: List of [Date]; var FoundDate: Date): Boolean
    var
        D: Date;
    begin
        if SearchBackward then begin
            D := RangeEnd;
            while D >= RangeStart do begin
                if DayPlanningMgt.IsActiveWorkDay(WorkHourTemplateCode, D) and not OccupiedDates.Contains(D) and not ClaimedDates.Contains(D) then begin
                    FoundDate := D;
                    exit(true);
                end;
                D -= 1;
            end;
        end else begin
            D := RangeStart;
            while D <= RangeEnd do begin
                if DayPlanningMgt.IsActiveWorkDay(WorkHourTemplateCode, D) and not OccupiedDates.Contains(D) and not ClaimedDates.Contains(D) then begin
                    FoundDate := D;
                    exit(true);
                end;
                D += 1;
            end;
        end;
        exit(false);
    end;

    /// <summary>
    /// Naive offset/clamp + cascade fallback for one resource's rows (used when no matching Day
    /// Planning Pattern exists for that resource). Mirrors the original CalculateChanges Pass
    /// 1/Pass 2 logic, scoped to ResourceNo, but keyed by Day Line No. (not Plan Date) so results
    /// can be merged safely with pattern-based results computed for other resources that share
    /// the same original dates. Deliberately forward-only and unbounded for the Shift scenario
    /// fallback path: if pushing a candidate forward to the next active day would cross NewEnd,
    /// it keeps going past NewEnd rather than clamping back — the Job Task's own Planned End Date
    /// is what stretches to cover the overshoot (see ExtendJobTaskEndDateIfNeeded), not the
    /// DayPlanning rows that get forced backward to fit inside a boundary.
    ///
    /// For the Right-Bar-Reduced and Left-Bar-Reduced scenarios (detected here from the
    /// OldStart/OldEnd/NewStart/NewEnd relationship, the same way CalculateNaiveNewDate does),
    /// every row in OldDates is by construction an overflowing row that CalculateNaiveNewDate
    /// clamped onto the boundary date — before accepting that clamp, Pass 2 now searches for a
    /// free active day within NewStart..NewEnd (see FindNearestFreeActiveDate) so overflowing
    /// rows spread onto unoccupied work days rather than combining onto the same date. Combining
    /// is kept as a last-resort fallback, unchanged, for when no free day remains.
    /// </summary>
    local procedure MapRowsUsingNaiveCascade(JobNo: Code[20]; JobTaskNo: Code[20]; ResourceNo: Code[20]; OldStart: Date; OldEnd: Date; NewStart: Date; NewEnd: Date; WorkHourTemplateCode: Code[20]; var RowNewDateMap: Dictionary of [Integer, Date])
    var
        DayPlanning: Record "Day Planning";
        NaiveDate: Date;
        CandidateDate: Date;
        PrevNaiveDate: Date;
        PrevAdjustedDate: Date;
        OldDates: List of [Date];
        OldDateItem: Date;
        NaiveDateMap: Dictionary of [Date, Date];
        AdjustedDateMap: Dictionary of [Date, Date];
        SeenDates: List of [Date];
        OccupiedDates: List of [Date];
        ClaimedDates: List of [Date];
        IsRightBarReduced: Boolean;
        IsLeftBarReduced: Boolean;
    begin
        // Scenario detection mirrors CalculateNaiveNewDate's own branch conditions — this
        // procedure has no other way to know which of the three scenarios (1.1/1.2/1.3) is
        // currently active, since CalculateNaiveNewDate is deliberately stateless per-date.
        IsRightBarReduced := (OldStart = NewStart) and (NewEnd < OldEnd);
        IsLeftBarReduced := (OldStart <> NewStart) and (OldEnd = NewEnd) and (NewStart > OldStart);

        // ── Pass 1 — naive target per distinct original date for this resource. Dates whose
        // naive target equals their own original date are unmoved and therefore still "occupy"
        // that date — tracked in OccupiedDates so Pass 2's free-space search never reassigns an
        // overflowing row onto a date another row already keeps. ──────────────────────────────
        DayPlanning.SetCurrentKey("Plan Date");
        DayPlanning.SetRange("Job No.", JobNo);
        DayPlanning.SetRange("Job Task No.", JobTaskNo);
        DayPlanning.SetRange("Assigned Resource No.", ResourceNo);
        DayPlanning.SetRange("Plan Date", OldStart, OldEnd);
        if DayPlanning.FindSet() then
            repeat
                if not SeenDates.Contains(DayPlanning."Plan Date") then begin
                    SeenDates.Add(DayPlanning."Plan Date");
                    NaiveDate := CalculateNaiveNewDate(DayPlanning."Plan Date", OldStart, OldEnd, NewStart, NewEnd);
                    if NaiveDate <> DayPlanning."Plan Date" then begin
                        NaiveDateMap.Add(DayPlanning."Plan Date", NaiveDate);
                        OldDates.Add(DayPlanning."Plan Date");
                    end else
                        OccupiedDates.Add(DayPlanning."Plan Date");
                end;
            until DayPlanning.Next() = 0;

        // ── Pass 2 — cascade-adjust each naive target. Right-Bar-Reduced/Left-Bar-Reduced
        // overflowing rows try free-space placement first; every other scenario (Shift) keeps
        // the original push-forward-onto-next-active-day cascade unchanged. ───────────────────
        PrevNaiveDate := 0D;
        PrevAdjustedDate := 0D;
        foreach OldDateItem in OldDates do begin
            NaiveDate := NaiveDateMap.Get(OldDateItem);

            if (IsRightBarReduced or IsLeftBarReduced) then begin
                // Prefer spreading this overflowing row onto a free active day within
                // NewStart..NewEnd (backward from NewEnd for Right-Bar-Reduced, forward from
                // NewStart for Left-Bar-Reduced) rather than combining it onto the naive
                // boundary date.
                if not FindNearestFreeActiveDate(NewStart, NewEnd, IsRightBarReduced, WorkHourTemplateCode, OccupiedDates, ClaimedDates, CandidateDate) then begin
                    // No free active day left anywhere in the range — fall back to the original
                    // collapse-onto-boundary behavior (accepted as a last resort).
                    if (PrevNaiveDate <> 0D) and (NaiveDate = PrevNaiveDate) then
                        CandidateDate := PrevAdjustedDate
                    else begin
                        if (PrevAdjustedDate <> 0D) and (NaiveDate <= PrevAdjustedDate) then
                            CandidateDate := PrevAdjustedDate + 1
                        else
                            CandidateDate := NaiveDate;
                        while not DayPlanningMgt.IsActiveWorkDay(WorkHourTemplateCode, CandidateDate) do
                            CandidateDate += 1;
                    end;
                end;
            end else begin
                if (PrevNaiveDate <> 0D) and (NaiveDate = PrevNaiveDate) then
                    // Same naive target as the previous distinct date — deliberately collapse
                    // onto the same final date, already validated as active by the previous
                    // iteration. (Shift scenario only: its constant per-row offset means this
                    // branch is not expected to trigger in practice, but is kept for parity
                    // with the original logic.)
                    CandidateDate := PrevAdjustedDate
                else begin
                    if (PrevAdjustedDate <> 0D) and (NaiveDate <= PrevAdjustedDate) then
                        CandidateDate := PrevAdjustedDate + 1
                    else
                        CandidateDate := NaiveDate;
                    while not DayPlanningMgt.IsActiveWorkDay(WorkHourTemplateCode, CandidateDate) do
                        CandidateDate += 1;
                end;
            end;

            AdjustedDateMap.Add(OldDateItem, CandidateDate);
            ClaimedDates.Add(CandidateDate);
            PrevNaiveDate := NaiveDate;
            PrevAdjustedDate := CandidateDate;
        end;

        // ── Map every row of this resource back to its distinct date's adjusted target. ──
        DayPlanning.SetRange("Plan Date", OldStart, OldEnd);
        if DayPlanning.FindSet() then
            repeat
                if AdjustedDateMap.ContainsKey(DayPlanning."Plan Date") then
                    RowNewDateMap.Add(DayPlanning."Day Line No.", AdjustedDateMap.Get(DayPlanning."Plan Date"));
            until DayPlanning.Next() = 0;
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
        if (MaxNewDate <> 0D) and (MaxNewDate > JobTask.PlannedEndDate) then begin
            JobTask.PlannedEndDate := MaxNewDate;
            JobTask.CalculateDuration();
        end;
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
                    DayPlanning."Plan Date" := TempPreviewBuffer."New Task Date";
                    DayPlanning."Day Line No." := DayPlanning.GetNextDayLineNo(
                        TempPreviewBuffer."New Task Date",
                        TempPreviewBuffer."Job No.",
                        TempPreviewBuffer."Job Task No.");
                    DayPlanning.Insert();
                end else
                    if DayPlanning.Get(TempPreviewBuffer."Job No.", TempPreviewBuffer."Job Task No.", TempPreviewBuffer."Day Line No.") then begin
                        DayPlanning."Plan Date" := TempPreviewBuffer."New Task Date";
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
        if not CalculateChanges(JobTask."Job No.", JobTask."Job Task No.", OldStart, OldEnd, JobTask.PlannedStartDate, JobTask.PlannedEndDate, TempPreviewBuffer) then begin
            if not SkipJobTaskModify then
                JobTask.Modify(true);
            exit(true);
        end;
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
                    DayPlanning."Plan Date" := TempPreviewBuffer."New Task Date";
                    DayPlanning."Day Line No." := DayPlanning.GetNextDayLineNo(
                        TempPreviewBuffer."New Task Date",
                        TempPreviewBuffer."Job No.",
                        TempPreviewBuffer."Job Task No.");
                    DayPlanning.Insert();
                end else
                    if DayPlanning.Get(TempPreviewBuffer."Job No.", TempPreviewBuffer."Job Task No.", TempPreviewBuffer."Day Line No.") then begin
                        DayPlanning."Plan Date" := TempPreviewBuffer."New Task Date";
                        DayPlanning.Modify();
                    end;
            until TempPreviewBuffer.Next() = 0;
        TempPreviewBuffer.SetRange("Convert to DayPlanning");
    end;
}
