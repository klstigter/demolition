codeunit 50603 "EventSubs"
{
    Permissions = tabledata "Res. Ledger Entry" = rm,
                  tabledata "Job Ledger Entry" = rm,
                  tabledata "Day Tasks" = m;

    trigger OnRun()
    begin
    end;

    // ─────────────────────────────────────────────────────────────────────────
    // Day Task traceability: copy "Opt. Daytask Date" and "Opt. Daytask Line No."
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
    local procedure CopyDaytaskFieldsOnBeforeJobLedgEntryInsert(var JobLedgerEntry: Record "Job Ledger Entry"; JobJournalLine: Record "Job Journal Line")
    var
        ResLedgEntry: Record "Res. Ledger Entry";
    begin
        // ── Job Ledger Entry ──────────────────────────────────────────────────
        JobLedgerEntry."Opt. Daytask Date" := JobJournalLine."Opt. Daytask Date";
        JobLedgerEntry."Opt. Daytask Line No." := JobJournalLine."Opt. Daytask Line No.";

        // ── Res. Ledger Entry (Resource lines only) ───────────────────────────
        // "Ledger Entry No." on the job entry = Entry No. of the already-inserted
        // Res. Ledger Entry. Modify it before the job entry is committed.
        if (JobJournalLine.Type = JobJournalLine.Type::Resource) and
           (JobLedgerEntry."Ledger Entry No." <> 0) then
            if ResLedgEntry.Get(JobLedgerEntry."Ledger Entry No.") then begin
                ResLedgEntry."Opt. Daytask Date" := JobJournalLine."Opt. Daytask Date";
                ResLedgEntry."Opt. Daytask Line No." := JobJournalLine."Opt. Daytask Line No.";
                ResLedgEntry.Modify();
            end;
    end;

    // ─────────────────────────────────────────────────────────────────────────
    // After the Job Ledger Entry is inserted (Entry No. is now known),
    // mark the originating Day Task as Posted and record the ledger entry nos.
    // ─────────────────────────────────────────────────────────────────────────
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Job Jnl.-Post Line", 'OnAfterJobLedgEntryInsert', '', false, false)]
    local procedure UpdateDayTaskAfterJobLedgEntryInsert(var JobLedgerEntry: Record "Job Ledger Entry"; JobJournalLine: Record "Job Journal Line")
    var
        DayTask: Record "Day Tasks";
    begin
        if (JobJournalLine."Opt. Daytask Date" = 0D) or (JobJournalLine."Opt. Daytask Line No." = 0) then
            exit;

        if not DayTask.Get(
            JobJournalLine."Job No.",
            JobJournalLine."Job Task No.",
            JobJournalLine."Opt. Daytask Line No.")
        then
            exit;

        DayTask.Posted := true;
        DayTask."Job Entry No." := JobLedgerEntry."Entry No.";
        if JobJournalLine.Type = JobJournalLine.Type::Resource then
            DayTask."Resource Entry No." := JobLedgerEntry."Ledger Entry No.";
        DayTask.Modify();
    end;

    // Vendor No. able to fill in if resource is pool
    [EventSubscriber(ObjectType::Table, Database::"Resource", 'OnAfterValidateEvent', 'Vendor No.', false, false)]
    local procedure Table_Resource_OnAfterValidateEvent(var Rec: Record Resource; xRec: Record Resource; CurrFieldNo: Integer)
    var
        Res: Record Resource;
        Extrnl: Boolean;
    begin
        Extrnl := Rec."Vendor No." <> '';
        Rec."External Resource" := Extrnl;
        Rec.Modify();
        // update "External Resource" = true for all member if this resource is a pool
        if Rec."No." = Rec."Pool Resource No." then begin
            Res.SetRange("Pool Resource No.", Rec."No.");
            Res.SetFilter("No.", '<>%1', Rec."No.");
            if Res.FindSet() then
                Res.ModifyAll("External Resource", Extrnl);
        end;
    end;
}
