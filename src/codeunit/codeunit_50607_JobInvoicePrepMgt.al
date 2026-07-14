codeunit 50607 "Job Planning Lines Prep. Mgt."
{
    // Day-Planning-to-JobPlanning (Release 1).
    //
    // Turns posted, not-yet-linked resource usage into billable Job Planning Lines,
    // summarized per Skill's "Invoice Resource No.", and records one "Job Ledger Invoice
    // Link" row per included usage entry for traceability.
    //
    // Driven from Day Planning, not Job Ledger Entry: "Day Planning".Posted = true is the
    // authoritative signal that a Day Planning row has been posted into a Job Ledger
    // Entry, and "Day Planning"."Job Entry No." (field 151) is where codeunit 50603
    // "Event Subs."'s UpdateDayPlanningAfterJobLedgEntryInsert recorded that Job Ledger
    // Entry's Entry No. at posting time. Pass 1 below therefore loops Day Planning
    // (SetRange Job No./Job Task No./Posted = true) and reads "Job Entry No." directly -
    // including into "Job Ledger Invoice Link"."Job Ledger Entry No." - rather than looping
    // Job Ledger Entry independently and relying on an unenforced coincidental equality
    // between the two. The matching Job Ledger Entry is still fetched (via
    // JobLedgerEntry.Get("Day Planning"."Job Entry No.")) purely to read Quantity/UOM and
    // to scope the feature to resource usage (Entry Type = Usage, Type = Resource); do not
    // reintroduce a Job-Ledger-Entry-driven candidate loop.
    //
    // Design decisions (Release 1, left open by the design doc):
    //   - Grouping key = Job No. + Job Task No. + Skill's Invoice Resource No. + Unit of
    //     Measure Code. NOT grouped by Unit Price - Unit Price is resolved once per group
    //     via standard resource price logic (Job Planning Line's own field-validation
    //     order), exactly as a manual planning-line entry would resolve it.
    //   - Only Day Planning rows that have actually been posted to a Job Ledger Entry
    //     (Posted = true, "Job Entry No." <> 0) are candidates; if the Job Ledger Entry
    //     they point to can no longer be found (data-integrity edge case, shouldn't happen)
    //     that row is silently skipped rather than error'ing the whole batch. Usage posted
    //     through some other route with no Day Planning row behind it is out of scope for
    //     this feature.
    //   - Two-pass processing: pass 1 resolves every candidate's Skill -> Invoice Resource
    //     No. and builds the grouping (no database writes at all). The per-group entry lists
    //     are accumulated as a Dictionary of [Text, List of [Integer]] - each group's
    //     "Job Entry No." values stay typed Integers end-to-end, with no Format/Split/
    //     Evaluate round-trip through Text. To avoid any List reference-aliasing across
    //     groups (Dictionary.Get() on a List-valued entry must not be assumed to hand back
    //     something you can mutate in place and have it stick), every touch of a group's
    //     list follows the explicit Get-mutate-Set-back idiom: Get() the List into a local
    //     variable, mutate the local copy, then Set() it back into the dictionary - never
    //     rely on in-place mutation persisting. This is safe regardless of List's value/
    //     reference assignment semantics in a given AL version. So a missing
    //     "Invoice Resource No." on any Skill in play raises Error() before anything is
    //     written. Pass 2 then creates the Job Planning Lines and Job Ledger Invoice Link
    //     rows. Since no COMMIT() is issued anywhere in this codeunit, a runtime error
    //     during pass 2 rolls back the whole run via BC's ambient transaction (the caller's
    //     page action) - all-or-nothing without needing an explicit transaction wrapper.
    Permissions = tabledata "Job Ledger Entry" = r,
                  tabledata "Day Planning" = r,
                  tabledata "Skill Code" = r,
                  tabledata "Job" = r,
                  tabledata "Job Planning Line" = rim,
                  tabledata "Job Ledger Invoice Link" = ri,
                  tabledata "Job Usage Link" = rim;

    trigger OnRun()
    begin
    end;

    var
        DailyOptimizerSetup: record "Daily Optimizer Setup";

    /// <summary>
    /// Prepares billable Job Planning Lines from posted, not-yet-linked Day Planning
    /// resource usage for the given Job (optionally scoped to one Job Task).
    /// </summary>
    /// <param name="ProcessedCount">Out: number of Day Planning rows successfully grouped into a Project Planning Line.</param>
    /// <param name="AlreadyLinkedCount">Out: number of rows skipped because a Job Ledger Invoice Link already exists for them.</param>
    /// <param name="NotPostedCount">Out: number of rows skipped because they are not (yet) posted to a Job Ledger Entry.</param>
    /// <param name="SkippedOtherCount">Out: number of rows skipped for other reasons (Job Ledger Entry not found, or not Usage/Resource).</param>
    /// <returns>The number of Job Planning Lines created.</returns>
    procedure PrepareJobPlanningLines(JobNo: Code[20]; JobTaskNo: Code[20]; var ProcessedCount: Integer; var AlreadyLinkedCount: Integer; var NotPostedCount: Integer; var SkippedOtherCount: Integer) LinesCreated: Integer
    var
        DayPlanning: Record "Day Planning";
    begin
        DayPlanning.SetRange("Job No.", JobNo);
        if JobTaskNo <> '' then
            DayPlanning.SetRange("Job Task No.", JobTaskNo);
        DayPlanning.SetRange(Posted, true);
        exit(PrepareJobPlanningLinesFromDayPlanning(DayPlanning, ProcessedCount, AlreadyLinkedCount, NotPostedCount, SkippedOtherCount));
    end;

    /// <summary>
    /// Prepares billable Job Planning Lines from a caller-supplied, already-filtered Day
    /// Planning recordset - e.g. a multi-selection on the Day Plannings list page. Unlike
    /// PrepareJobPlanningLines(JobNo, JobTaskNo), which sweeps every posted Day Planning row
    /// for the Job/Job Task, this only considers the rows present in SelectedDayPlanning.
    /// </summary>
    /// <param name="ProcessedCount">Out: number of Day Planning rows successfully grouped into a Project Planning Line.</param>
    /// <param name="AlreadyLinkedCount">Out: number of rows skipped because a Job Ledger Invoice Link already exists for them.</param>
    /// <param name="NotPostedCount">Out: number of rows skipped because they are not (yet) posted to a Job Ledger Entry.</param>
    /// <param name="SkippedOtherCount">Out: number of rows skipped for other reasons (Job Ledger Entry not found, or not Usage/Resource).</param>
    /// <returns>The number of Job Planning Lines created.</returns>
    procedure PrepareJobPlanningLinesForSelection(var SelectedDayPlanning: Record "Day Planning"; var ProcessedCount: Integer; var AlreadyLinkedCount: Integer; var NotPostedCount: Integer; var SkippedOtherCount: Integer) LinesCreated: Integer
    begin
        exit(PrepareJobPlanningLinesFromDayPlanning(SelectedDayPlanning, ProcessedCount, AlreadyLinkedCount, NotPostedCount, SkippedOtherCount));
    end;

    /// <summary>
    /// Single-batch counterpart to PrepareJobPlanningLines/PrepareJobPlanningLinesForSelection,
    /// called from codeunit 50608's subscriber on native codeunit "Job Post-Line"'s
    /// OnBeforeInsertPlLineFromLedgEntry event - i.e. when a user runs the STANDARD
    /// "Transfer To Planning Lines" action on Job Ledger Entries that trace back to Day
    /// Planning. Reads Skill directly off the Job Ledger Entry (field "Skill", populated at
    /// posting time) rather than looking it up via Day Planning, and reuses the same
    /// grouping/CreateJobPlanningLine Pass 2 as the Day-Planning-driven path.
    /// </summary>
    /// <param name="AlreadyLinkedCount">Out: number of entries skipped because a Job Ledger Invoice Link already exists for them.</param>
    /// <param name="ProcessedCount">Out: number of entries successfully grouped into a Job Planning Line.</param>
    /// <returns>The number of Job Planning Lines created.</returns>
    procedure PrepareJobPlanningLinesFromJobLedgerEntry(var JobLedgerEntry: Record "Job Ledger Entry";
                                                    var JobPlanningLine: Record "Job Planning Line";
                                                    var AlreadyLinkedCount: Integer;
                                                    var ProcessedCount: Integer) LinesCreated: Integer
    var
        JobLedgerInvoiceLink: Record "Job Ledger Invoice Link";
        SkillCodeRec: Record "Skill Code";
        SkillCode: Code[20];
        InvoiceResNo: Code[20];
        GroupKey: Text;
        GroupHours: Dictionary of [Text, Decimal];
        GroupJobNo: Dictionary of [Text, Code[20]];
        GroupJobTaskNo: Dictionary of [Text, Code[20]];
        GroupInvoiceResNo: Dictionary of [Text, Code[20]];
        GroupUOM: Dictionary of [Text, Code[10]];
        GroupEntryNos: Dictionary of [Text, List of [Integer]];
        EntrySkillCode: Dictionary of [Integer, Code[20]];
        GroupKeys: List of [Text];
        TempEmptyIntList: List of [Integer];
        TempIntList: List of [Integer];
        NoSkillOnDayPlanningErr: Label 'Day Planning %1/%2/%3 has no Skill assigned. Cannot prepare project planning lines.', Comment = '%1 = Job No., %2 = Job Task No., %3 = Day Line No.';
        SkillCodeNotFoundErr: Label 'Skill Code %1 no longer exists. Cannot prepare project planning lines.', Comment = '%1 = Skill Code';
        NoInvoiceResourceErr: Label 'Skill %1 has no Invoice Resource No. defined on the Skill Code setup. Set one before preparing project planning lines.', Comment = '%1 = Skill Code';
    begin
        if JobLedgerEntry.FindSet() then
            repeat
                if JobLedgerInvoiceLink.Get(JobLedgerEntry."Entry No.") then
                    AlreadyLinkedCount += 1
                else begin
                    if (JobLedgerEntry."Entry Type" = JobLedgerEntry."Entry Type"::Usage) and
                        (JobLedgerEntry.Type = JobLedgerEntry.Type::Resource)
                    then begin
                        SkillCode := JobLedgerEntry.Skill;
                        if SkillCode = '' then begin
                            DailyOptimizerSetup.Get();
                            if DailyOptimizerSetup."Default Skill" = '' then
                                Error(NoSkillOnDayPlanningErr, JobLedgerEntry."Job No.", JobLedgerEntry."Job Task No.", JobLedgerEntry."Opt. DayPlanning Line No.");
                            SkillCode := DailyOptimizerSetup."Default Skill";
                        end;

                        if not SkillCodeRec.Get(SkillCode) then
                            Error(SkillCodeNotFoundErr, SkillCode);

                        InvoiceResNo := SkillCodeRec."Invoice Resource No.";
                        if InvoiceResNo = '' then
                            Error(NoInvoiceResourceErr, SkillCode);

                        GroupKey := StrSubstNo('%1|%2|%3|%4',
                            JobLedgerEntry."Job No.", JobLedgerEntry."Job Task No.",
                            InvoiceResNo, JobLedgerEntry."Unit of Measure Code");

                        if not GroupHours.ContainsKey(GroupKey) then begin
                            GroupHours.Add(GroupKey, 0);
                            GroupJobNo.Add(GroupKey, JobLedgerEntry."Job No.");
                            GroupJobTaskNo.Add(GroupKey, JobLedgerEntry."Job Task No.");
                            GroupInvoiceResNo.Add(GroupKey, InvoiceResNo);
                            GroupUOM.Add(GroupKey, JobLedgerEntry."Unit of Measure Code");
                            Clear(TempEmptyIntList);
                            GroupEntryNos.Add(GroupKey, TempEmptyIntList);
                            GroupKeys.Add(GroupKey);
                        end;

                        GroupHours.Set(GroupKey, GroupHours.Get(GroupKey) + JobLedgerEntry.Quantity);
                        TempIntList := GroupEntryNos.Get(GroupKey);
                        TempIntList.Add(JobLedgerEntry."Entry No.");
                        GroupEntryNos.Set(GroupKey, TempIntList);

                        if not EntrySkillCode.ContainsKey(JobLedgerEntry."Entry No.") then
                            EntrySkillCode.Add(JobLedgerEntry."Entry No.", SkillCode);

                        ProcessedCount += 1;
                    end;
                end;
            until JobLedgerEntry.Next() = 0;

        // ── Pass 2: create one Job Planning Line + Link rows per group. ────────────────
        foreach GroupKey in GroupKeys do begin
            CreateJobPlanningLine(
                GroupJobNo.Get(GroupKey), GroupJobTaskNo.Get(GroupKey),
                GroupInvoiceResNo.Get(GroupKey), GroupUOM.Get(GroupKey), GroupHours.Get(GroupKey),
                GroupEntryNos.Get(GroupKey), EntrySkillCode, JobPlanningLine);
            LinesCreated += 1;
        end;

        exit(LinesCreated);
    end;

    /// <summary>
    /// Core Pass 1/Pass 2 logic shared by PrepareJobPlanningLines and
    /// PrepareJobPlanningLinesForSelection. Operates on whatever recordset the caller has
    /// already filtered into DayPlanning - it only calls FindSet()/Next() on it, it does
    /// not apply any SetRange of its own. ProcessedCount/AlreadyLinkedCount/NotPostedCount/
    /// SkippedOtherCount are out-counters explaining why each candidate row was or was not
    /// included, for a caller-facing breakdown message (see FormatResultMessage).
    /// </summary>
    local procedure PrepareJobPlanningLinesFromDayPlanning(var DayPlanning: Record "Day Planning"; var ProcessedCount: Integer; var AlreadyLinkedCount: Integer; var NotPostedCount: Integer; var SkippedOtherCount: Integer) LinesCreated: Integer
    var
        JobLedgerEntry: Record "Job Ledger Entry";
        JobLedgerInvoiceLink: Record "Job Ledger Invoice Link";
        SkillCodeRec: Record "Skill Code";
        CreatedJobPlanningLine: Record "Job Planning Line";
        GroupHours: Dictionary of [Text, Decimal];
        GroupJobNo: Dictionary of [Text, Code[20]];
        GroupJobTaskNo: Dictionary of [Text, Code[20]];
        GroupInvoiceResNo: Dictionary of [Text, Code[20]];
        GroupUOM: Dictionary of [Text, Code[10]];
        GroupEntryNos: Dictionary of [Text, List of [Integer]];
        EntrySkillCode: Dictionary of [Integer, Code[20]];
        GroupKeys: List of [Text];
        TempEmptyIntList: List of [Integer];
        TempIntList: List of [Integer];
        GroupKey: Text;
        SkillCode: Code[20];
        InvoiceResNo: Code[20];
        NoSkillOnDayPlanningErr: Label 'Day Planning %1/%2/%3 has no Skill assigned. Cannot prepare project planning lines.', Comment = '%1 = Job No., %2 = Job Task No., %3 = Day Line No.';
        SkillCodeNotFoundErr: Label 'Skill Code %1 no longer exists. Cannot prepare project planning lines.', Comment = '%1 = Skill Code';
        NoInvoiceResourceErr: Label 'Skill %1 has no Invoice Resource No. defined on the Skill Code setup. Set one before preparing project planning lines.', Comment = '%1 = Skill Code';
    begin
        // ── Pass 1: gather candidates, resolve Skill -> Invoice Resource No., group. ────
        // No database writes happen in this pass, so a missing Invoice Resource No.
        // Error()s out before any Job Planning Line/Link row is ever created.
        // Driven from Day Planning (Posted = true), not Job Ledger Entry - see the
        // top-of-file comment for why "Job Ledger Entry No." is sourced from
        // "Day Planning"."Job Entry No." (field 151) rather than JobLedgerEntry."Entry No.".
        //
        // DayPlanning is caller-supplied and already filtered (either by JobNo/JobTaskNo/
        // Posted via PrepareJobPlanningLines, or by the caller's own selection via
        // PrepareJobPlanningLinesForSelection). The explicit Posted/"Job Entry No." check below
        // is defense-in-depth for the selection path, where a user could have selected rows
        // that aren't actually posted yet - those are silently skipped, same "not a
        // qualifying candidate" semantics used elsewhere in this procedure.
        if DayPlanning.FindSet() then
            repeat
                if DayPlanning.Posted and (DayPlanning."Job Entry No." <> 0) then begin
                    if JobLedgerInvoiceLink.Get(DayPlanning."Job Entry No.") then
                        AlreadyLinkedCount += 1
                    else
                        if JobLedgerEntry.Get(DayPlanning."Job Entry No.") then begin
                            if (JobLedgerEntry."Entry Type" = JobLedgerEntry."Entry Type"::Usage) and
                               (JobLedgerEntry.Type = JobLedgerEntry.Type::Resource)
                            then begin
                                SkillCode := DayPlanning.Skill;
                                if SkillCode = '' then
                                    Error(NoSkillOnDayPlanningErr, DayPlanning."Job No.", DayPlanning."Job Task No.", DayPlanning."Day Line No.");

                                if not SkillCodeRec.Get(SkillCode) then
                                    Error(SkillCodeNotFoundErr, SkillCode);

                                InvoiceResNo := SkillCodeRec."Invoice Resource No.";
                                if InvoiceResNo = '' then
                                    Error(NoInvoiceResourceErr, SkillCode);

                                GroupKey := StrSubstNo('%1|%2|%3|%4',
                                    DayPlanning."Job No.", DayPlanning."Job Task No.",
                                    InvoiceResNo, JobLedgerEntry."Unit of Measure Code");

                                if not GroupHours.ContainsKey(GroupKey) then begin
                                    GroupHours.Add(GroupKey, 0);
                                    GroupJobNo.Add(GroupKey, DayPlanning."Job No.");
                                    GroupJobTaskNo.Add(GroupKey, DayPlanning."Job Task No.");
                                    GroupInvoiceResNo.Add(GroupKey, InvoiceResNo);
                                    GroupUOM.Add(GroupKey, JobLedgerEntry."Unit of Measure Code");
                                    Clear(TempEmptyIntList);
                                    GroupEntryNos.Add(GroupKey, TempEmptyIntList);
                                    GroupKeys.Add(GroupKey);
                                end;

                                GroupHours.Set(GroupKey, GroupHours.Get(GroupKey) + JobLedgerEntry.Quantity);
                                TempIntList := GroupEntryNos.Get(GroupKey);
                                TempIntList.Add(DayPlanning."Job Entry No.");
                                GroupEntryNos.Set(GroupKey, TempIntList);

                                if not EntrySkillCode.ContainsKey(DayPlanning."Job Entry No.") then
                                    EntrySkillCode.Add(DayPlanning."Job Entry No.", SkillCode);

                                ProcessedCount += 1;
                            end else
                                SkippedOtherCount += 1;
                        end else
                            SkippedOtherCount += 1;
                end else
                    NotPostedCount += 1;
            until DayPlanning.Next() = 0;

        // ── Pass 2: create one Job Planning Line + Link rows per group. ────────────────
        foreach GroupKey in GroupKeys do begin
            CreateJobPlanningLine(
                GroupJobNo.Get(GroupKey), GroupJobTaskNo.Get(GroupKey),
                GroupInvoiceResNo.Get(GroupKey), GroupUOM.Get(GroupKey), GroupHours.Get(GroupKey),
                GroupEntryNos.Get(GroupKey), EntrySkillCode, CreatedJobPlanningLine);
            LinesCreated += 1;
        end;

        exit(LinesCreated);
    end;

    /// <summary>
    /// TryFunction wrapper around PrepareJobPlanningLines, for callers that process several
    /// (Job No., Job Task No.) pairs in one batch (e.g. a multi-selection on the Day
    /// Plannings list) and want one failing pair (typically "Skill has no Invoice Resource
    /// No.") to be caught and reported per-pair instead of aborting the whole batch.
    /// A failure here only rolls back the database changes made by THIS call - AL's Try
    /// mechanism establishes its own checkpoint, so pairs already successfully processed
    /// earlier in the same batch are unaffected. Note that the Try mechanism only rolls
    /// back DATABASE changes, not the ProcessedCount/AlreadyLinkedCount/NotPostedCount/
    /// SkippedOtherCount counters accumulated up to the point of failure - callers should
    /// still report those on failure (they describe what happened before the error).
    /// </summary>
    [TryFunction]
    procedure TryPrepareJobPlanningLines(JobNo: Code[20]; JobTaskNo: Code[20]; var LinesCreated: Integer; var ProcessedCount: Integer; var AlreadyLinkedCount: Integer; var NotPostedCount: Integer; var SkippedOtherCount: Integer)
    begin
        LinesCreated := PrepareJobPlanningLines(JobNo, JobTaskNo, ProcessedCount, AlreadyLinkedCount, NotPostedCount, SkippedOtherCount);
    end;

    /// <summary>
    /// TryFunction wrapper around PrepareJobPlanningLinesForSelection, for callers that
    /// process several (Job No., Job Task No.) pairs from one multi-selection in a single
    /// batch and want one failing pair (typically "Skill has no Invoice Resource No.") to be
    /// caught and reported per-pair instead of aborting the whole batch. See
    /// TryPrepareJobPlanningLines's remarks for the Try/rollback semantics (including how the
    /// counters survive a failed Try), which apply here identically.
    /// </summary>
    [TryFunction]
    procedure TryPrepareJobPlanningLinesForSelection(var SelectedDayPlanning: Record "Day Planning"; var LinesCreated: Integer; var ProcessedCount: Integer; var AlreadyLinkedCount: Integer; var NotPostedCount: Integer; var SkippedOtherCount: Integer)
    begin
        LinesCreated := PrepareJobPlanningLinesForSelection(SelectedDayPlanning, ProcessedCount, AlreadyLinkedCount, NotPostedCount, SkippedOtherCount);
    end;

    /// <summary>
    /// Builds the shared, human-readable breakdown message for a PrepareJobPlanningLines(...)/
    /// PrepareJobPlanningLinesForSelection(...) run: how many Job Planning Lines were created,
    /// and - unlike a bare line count - why any candidate Day Planning rows were excluded
    /// (already linked / not yet posted / not eligible resource usage). Both page callers
    /// use this so the message text is defined once. Lines are separated with "\", which
    /// Message()/Error() render as a line break in the dialog.
    /// </summary>
    procedure FormatResultMessage(LinesCreated: Integer; ProcessedCount: Integer; AlreadyLinkedCount: Integer; NotPostedCount: Integer; SkippedOtherCount: Integer) ResultText: Text
    var
        ProcessedLbl: Label '%1 record(s) processed into %2 Project Planning Line(s).', Comment = '%1 = records processed, %2 = Project Planning Lines created';
        AlreadyLinkedLbl: Label '%1 record(s) already in a Project Planning Line.', Comment = '%1 = record count';
        NotPostedLbl: Label '%1 record(s) have not been posted into Job Ledger Entries yet.', Comment = '%1 = record count';
        SkippedOtherLbl: Label '%1 record(s) skipped (not eligible resource usage).', Comment = '%1 = record count';
        NothingToProcessLbl: Label 'No records to process.';
    begin
        if (ProcessedCount = 0) and (AlreadyLinkedCount = 0) and (NotPostedCount = 0) and (SkippedOtherCount = 0) then
            exit(NothingToProcessLbl);

        ResultText := StrSubstNo(ProcessedLbl, ProcessedCount, LinesCreated);
        if AlreadyLinkedCount > 0 then
            ResultText += '\' + StrSubstNo(AlreadyLinkedLbl, AlreadyLinkedCount);
        if NotPostedCount > 0 then
            ResultText += '\' + StrSubstNo(NotPostedLbl, NotPostedCount);
        if SkippedOtherCount > 0 then
            ResultText += '\' + StrSubstNo(SkippedOtherLbl, SkippedOtherCount);

        exit(ResultText);
    end;

    /// <summary>
    /// Creates one Job Planning Line for the group, plus a "Job Ledger Invoice Link" row per
    /// included entry for this feature's own traceability. Also dual-writes a standard BC
    /// "Job Usage Link" row per entry (Job No./Job Task No./Line No. = the new planning
    /// line, Entry No. = the usage entry), gated by the Job's own "Apply Usage Link" flag,
    /// exactly like native BC gates its automatic Job Usage Link creation. This keeps the
    /// base-app Job Ledger Entries page's "Show Linked Project Planning Lines" action
    /// working for usage entries this feature processed, not just our own custom link table.
    /// The Job record is fetched once per group (same Job for the whole call), not once per
    /// entry inside the loop.
    ///
    /// JobPlanningLine is an out-parameter: it returns the created, fully-inserted line so
    /// callers that need it (e.g. PrepareJobPlanningLinesFromJobLedgerEntry, for the native
    /// "Transfer To Planning Lines" integration) can propagate it back to their own caller.
    /// If Pass 2 creates more than one line (more than one group), the LAST one created wins
    /// - by that point every line is already fully inserted regardless, so this is purely
    /// informational for the caller, not a hand-off of further work.
    /// </summary>
    local procedure CreateJobPlanningLine(JobNo: Code[20]; JobTaskNo: Code[20]; InvoiceResNo: Code[20]; UOMCode: Code[10]; Hours: Decimal; EntryNos: List of [Integer]; var EntrySkillCode: Dictionary of [Integer, Code[20]]; var JobPlanningLine: Record "Job Planning Line")
    var
        Job: Record Job;
        JobLedgerInvoiceLink: Record "Job Ledger Invoice Link";
        JobUsageLink: Record "Job Usage Link";
        EntryNo: Integer;
    begin
        Job.Get(JobNo);

        // Field-validation order deliberately mirrors what a user would do typing a new
        // line manually on the Job Planning Lines page, so BC's own price-resolution logic
        // (resource price list / job price group / work type, etc.) runs exactly as it
        // would for a manual entry.
        JobPlanningLine.Init();
        JobPlanningLine."Job No." := JobNo;
        JobPlanningLine."Job Task No." := JobTaskNo;
        JobPlanningLine."Line No." := GetNextJobPlanningLineNo(JobNo, JobTaskNo);
        JobPlanningLine.Insert(true);

        JobPlanningLine.Validate("Line Type", JobPlanningLine."Line Type"::Billable);
        JobPlanningLine.Validate(Type, JobPlanningLine.Type::Resource);
        JobPlanningLine.Validate("No.", InvoiceResNo);
        if JobPlanningLine."Unit of Measure Code" <> UOMCode then
            JobPlanningLine.Validate("Unit of Measure Code", UOMCode);
        JobPlanningLine.Validate(Quantity, Hours);
        JobPlanningLine."Usage Link" := true;
        JobPlanningLine.Modify(true);

        foreach EntryNo in EntryNos do begin
            JobLedgerInvoiceLink.Init();
            JobLedgerInvoiceLink."Job Ledger Entry No." := EntryNo;
            JobLedgerInvoiceLink."Job No." := JobPlanningLine."Job No.";
            JobLedgerInvoiceLink."Job Task No." := JobPlanningLine."Job Task No.";
            JobLedgerInvoiceLink."Invoice Job Planning Line No." := JobPlanningLine."Line No.";
            JobLedgerInvoiceLink."Skill Code" := EntrySkillCode.Get(EntryNo);
            JobLedgerInvoiceLink.Insert(true);

            if JobPlanningLine."Usage Link" then
                if not JobUsageLink.Get(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.", JobPlanningLine."Line No.", EntryNo) then begin
                    JobUsageLink.Init();
                    JobUsageLink."Job No." := JobPlanningLine."Job No.";
                    JobUsageLink."Job Task No." := JobPlanningLine."Job Task No.";
                    JobUsageLink."Line No." := JobPlanningLine."Line No.";
                    JobUsageLink."Entry No." := EntryNo;
                    JobUsageLink.Insert(true);
                end;
        end;
    end;

    local procedure GetNextJobPlanningLineNo(JobNo: Code[20]; JobTaskNo: Code[20]): Integer
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        JobPlanningLine.SetRange("Job No.", JobNo);
        JobPlanningLine.SetRange("Job Task No.", JobTaskNo);
        if JobPlanningLine.FindLast() then;
        exit(JobPlanningLine."Line No." + 10000);
    end;
}
