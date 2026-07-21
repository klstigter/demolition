codeunit 50603 "EventSubs"
{
    Permissions = tabledata "Res. Ledger Entry" = rm,
                  tabledata "Job Ledger Entry" = rm,
                  tabledata "Day Planning" = rm,
                  tabledata "Job Usage Link" = rd,
                  tabledata "Sales Invoice Header" = r,
                  tabledata "Sales Invoice Line" = r,
                  tabledata "Job Planning Line" = r;

    trigger OnRun()
    begin
    end;

    // ─────────────────────────────────────────────────────────────────────────
    // Day Planning traceability: copy "Opt. DayPlanning Date" and "Opt. DayPlanning Line No."
    // from the Job Journal Line into the Job Ledger Entry (all types) and, when
    // the line type is Resource, also into the already-inserted Res. Ledger Entry.
    //
    // Sequence inside "Job Jnl.-Post Line" (codeunit 1012):
    //   1. If Type = Resource → Res. Ledger Entry is inserted first;
    //      its Entry No. is stored in JobLedgEntry."Ledger Entry No."
    //   2. OnBeforeJobLedgEntryInsert fires ← we act here
    //   3. Job Ledger Entry is inserted
    //
    // Using Modify() on Res. Ledger Entry is safe because we are still inside
    // the same database transaction; no commit has occurred yet.
    // ─────────────────────────────────────────────────────────────────────────
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Job Jnl.-Post Line", 'OnBeforeJobLedgEntryInsert', '', false, false)]
    local procedure CopyDayPlanningFieldsOnBeforeJobLedgEntryInsert(var JobLedgerEntry: Record "Job Ledger Entry"; JobJournalLine: Record "Job Journal Line")
    var
        ResLedgEntry: Record "Res. Ledger Entry";
    begin
        // ── Job Ledger Entry ──────────────────────────────────────────────────
        JobLedgerEntry."Opt. DayPlanning Date" := JobJournalLine."Opt. DayPlanning Date";
        JobLedgerEntry."Opt. DayPlanning Line No." := JobJournalLine."Opt. DayPlanning Line No.";
        JobLedgerEntry.Skill := JobJournalLine.Skill;
        JobLedgerEntry."Invoice Resource No." := JobJournalLine."Invoice Resource No.";

        // ── Res. Ledger Entry (Resource lines only) ───────────────────────────
        // "Ledger Entry No." on the job entry = Entry No. of the already-inserted
        // Res. Ledger Entry. Modify it before the job entry is committed.
        if (JobJournalLine.Type = JobJournalLine.Type::Resource) and
           (JobLedgerEntry."Ledger Entry No." <> 0) then
            if ResLedgEntry.Get(JobLedgerEntry."Ledger Entry No.") then begin
                ResLedgEntry."Opt. DayPlanning Date" := JobJournalLine."Opt. DayPlanning Date";
                ResLedgEntry."Opt. DayPlanning Line No." := JobJournalLine."Opt. DayPlanning Line No.";
                ResLedgEntry.Modify();
            end;
    end;

    // ─────────────────────────────────────────────────────────────────────────
    // After the Job Ledger Entry is inserted (Entry No. is now known),
    // mark the originating Day Planning as Posted and record the ledger entry nos.
    // ─────────────────────────────────────────────────────────────────────────
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Job Jnl.-Post Line", 'OnAfterJobLedgEntryInsert', '', false, false)]
    local procedure UpdateDayPlanningAfterJobLedgEntryInsert(var JobLedgerEntry: Record "Job Ledger Entry"; JobJournalLine: Record "Job Journal Line")
    var
        DayPlanning: Record "Day Planning";
    begin
        if (JobJournalLine."Opt. DayPlanning Date" = 0D) or (JobJournalLine."Opt. DayPlanning Line No." = 0) then
            exit;

        if not DayPlanning.Get(
            JobJournalLine."Job No.",
            JobJournalLine."Job Task No.",
            JobJournalLine."Opt. DayPlanning Line No.")
        then
            exit;

        DayPlanning.Posted := true;
        DayPlanning."Job Entry No." := JobLedgerEntry."Entry No.";
        if JobJournalLine.Type = JobJournalLine.Type::Resource then
            DayPlanning."Resource Entry No." := JobLedgerEntry."Ledger Entry No.";
        DayPlanning.Modify();
    end;

    // Day-Planning-to-Invoice (Release 1): when a generated invoice planning line is
    // deleted (BC's own delete logic already allowed it - we react after the fact and
    // never fight standard BC delete logic here), drop the matching Job Ledger Invoice
    // Link rows so the underlying usage entries become invoiceable again on the next
    // "Prepare Invoice Lines" run.
    [EventSubscriber(ObjectType::Table, Database::"Job Planning Line", 'OnAfterDeleteEvent', '', false, false)]
    local procedure JobPlanningLine_OnAfterDeleteEvent(var Rec: Record "Job Planning Line"; RunTrigger: Boolean)
    var
        JobUsageLink: Record "Job Usage Link";
    begin
        if Rec.IsTemporary() then
            exit;

        // Also drop any standard "Job Usage Link" rows pointing at this line (created by
        // codeunit 50607's dual-write, or by the JobUsageLink_OnAfterInsertEvent sync
        // subscriber below) - once the line is gone, these would otherwise be orphaned,
        // pointing at a Line No. that no longer exists.
        JobUsageLink.SetRange("Job No.", Rec."Job No.");
        JobUsageLink.SetRange("Job Task No.", Rec."Job Task No.");
        JobUsageLink.SetRange("Line No.", Rec."Line No.");
        JobUsageLink.DeleteAll(false);
    end;

    // Day-Planning-to-Invoice (Release 1): when a Job Planning Line is transferred to a
    // Sales Invoice and that invoice is posted, standard BC creates a new Job Ledger Entry
    // (Entry Type = Sale) for it. codeunit "Sales-Post"'s OnAfterPostSalesDoc fires once
    // everything from this posting run exists - the Posted Sales Invoice AND that Sale
    // entry - so this is the reliable point to correlate them (unlike table 1022 "Job
    // Planning Line Invoice", whose own "Job Ledger Entry No." field was found to go stale:
    // its owning row can be deleted and re-inserted by a different part of native posting
    // logic after the value is written).
    //
    // Chain (confirmed by decompiling base app source): "Sales Invoice Line"."Job Contract
    // Entry No." (field 1002, copied from Sales Line during posting) matches "Job Planning
    // Line"."Job Contract Entry No." (field 1030) - this is the SAME cross-reference native
    // code itself uses (see SalesLine.Table.al's own OnValidate logic:
    // JobPlanningLine.SetCurrentKey("Job Contract Entry No.");
    // JobPlanningLine.SetRange("Job Contract Entry No.", ...)). Once the originating Job
    // Planning Line is known, the resulting Job Ledger Entry is found by Entry Type = Sale,
    // Document No. = the posted invoice's own No., Posting Date = its Posting Date.


    // Vendor No. able to fill in if resource is pool
    [EventSubscriber(ObjectType::Table, Database::"Resource", 'OnAfterValidateEvent', 'Vendor No.', false, false)]
    local procedure Table_Resource_OnAfterValidateEvent(var Rec: Record Resource; xRec: Record Resource; CurrFieldNo: Integer)
    var
        Res: Record Resource;
        IsExternal: Boolean;
    begin
        IsExternal := (Rec."Vendor No." <> '') and (Rec."Pool Resource No." = '');
        Rec."Is External" := IsExternal;
        Rec.Modify();
        // update "External Resource" = true for all member if this resource is a pool
        if Rec."No." = Rec."Pool Resource No." then begin
            Res.SetRange("Pool Resource No.", Rec."No.");
            Res.SetFilter("No.", '<>%1', Rec."No.");
            if Res.FindSet() then
                Res.ModifyAll("Is Pool Member", true);
        end;
    end;
}
