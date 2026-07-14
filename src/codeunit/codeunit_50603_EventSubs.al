codeunit 50603 "EventSubs"
{
    Permissions = tabledata "Res. Ledger Entry" = rm,
                  tabledata "Job Ledger Entry" = rm,
                  tabledata "Day Planning" = rm,
                  tabledata "Job Ledger Invoice Link" = rimd,
                  tabledata "Job Usage Link" = rd;

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

    // Transfer "Day Planning Line No." from Sales Line to Sales Invoice Line during posting
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnBeforeSalesInvLineInsert', '', false, false)]
    local procedure CopyDayPlanningLineNoToSalesInvLine(var SalesInvLine: Record "Sales Invoice Line"; SalesLine: Record "Sales Line")
    begin
        SalesInvLine."Day Planning Line No." := SalesLine."Day Planning Line No.";
    end;

    // Transfer "Day Planning Line No." from Sales Line to Sales Cr.Memo Line during posting.
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnBeforeSalesCrMemoLineInsert', '', false, false)]
    local procedure CopyDayPlanningLineNoToSalesCrMemoLine(var SalesCrMemoLine: Record "Sales Cr.Memo Line"; SalesLine: Record "Sales Line")
    begin
        SalesCrMemoLine."Day Planning Line No." := SalesLine."Day Planning Line No.";
    end;

    // Day-Planning-to-Invoice (Release 1): when a generated invoice planning line is
    // deleted (BC's own delete logic already allowed it - we react after the fact and
    // never fight standard BC delete logic here), drop the matching Job Ledger Invoice
    // Link rows so the underlying usage entries become invoiceable again on the next
    // "Prepare Invoice Lines" run.
    [EventSubscriber(ObjectType::Table, Database::"Job Planning Line", 'OnAfterDeleteEvent', '', false, false)]
    local procedure JobPlanningLine_OnAfterDeleteEvent(var Rec: Record "Job Planning Line"; RunTrigger: Boolean)
    var
        JobLedgerInvoiceLink: Record "Job Ledger Invoice Link";
        JobUsageLink: Record "Job Usage Link";
    begin
        if Rec.IsTemporary() then
            exit;

        JobLedgerInvoiceLink.SetRange("Job No.", Rec."Job No.");
        JobLedgerInvoiceLink.SetRange("Job Task No.", Rec."Job Task No.");
        JobLedgerInvoiceLink.SetRange("Invoice Job Planning Line No.", Rec."Line No.");
        JobLedgerInvoiceLink.DeleteAll(false);

        // Also drop any standard "Job Usage Link" rows pointing at this line (created by
        // codeunit 50607's dual-write, or by the JobUsageLink_OnAfterInsertEvent sync
        // subscriber below) - once the line is gone, these would otherwise be orphaned,
        // pointing at a Line No. that no longer exists.
        JobUsageLink.SetRange("Job No.", Rec."Job No.");
        JobUsageLink.SetRange("Job Task No.", Rec."Job Task No.");
        JobUsageLink.SetRange("Line No.", Rec."Line No.");
        JobUsageLink.DeleteAll(false);
    end;

    // Day-Planning-to-Invoice (Release 1): generic sync from ANY code path that creates a
    // standard "Job Usage Link" row for a Day-Planning-originated Job Ledger Entry - not
    // just codeunit 50607's own dual-write (see its CreateInvoicePlanningLine). This also
    // catches native BC's "Job Transfer To Planning Lines" report (the "Transfer To
    // Planning Lines" action on the base-app Job Ledger Entries page), which populates
    // "Job Usage Link" through the same standard mechanism whenever Job."Apply Usage Link"
    // is enabled - and any other current/future native flow that does the same. Without
    // this, a Job Ledger Entry sent straight to a planning line via that native action would
    // never get a "Job Ledger Invoice Link" row, so codeunit 50607's own duplicate-check
    // (JobLedgerInvoiceLink.Get(...)) wouldn't know it's already linked, risking a later
    // double-invoice, and report 50606/page 50681 would have no traceability row to find.
    //
    // Re-entrancy: codeunit 50607's CreateInvoicePlanningLine inserts the "Job Ledger
    // Invoice Link" row FIRST, then the "Job Usage Link" row SECOND (same JobPlanningLine/
    // EntryNo in both), so when this subscriber fires off that second insert,
    // JobLedgerInvoiceLink.Get(Rec."Entry No.") already succeeds and matches exactly -
    // the update branch below is a safe no-op in that case, not a conflicting write.
    [EventSubscriber(ObjectType::Table, Database::"Job Usage Link", 'OnAfterInsertEvent', '', false, false)]
    local procedure JobUsageLink_OnAfterInsertEvent(var Rec: Record "Job Usage Link"; RunTrigger: Boolean)
    var
        JobLedgerEntry: Record "Job Ledger Entry";
        JobLedgerInvoiceLink: Record "Job Ledger Invoice Link";
        DayPlanning: Record "Day Planning";
    begin
        if Rec.IsTemporary() then
            exit;
        if not JobLedgerEntry.Get(Rec."Entry No.") then
            exit;
        if JobLedgerEntry."Opt. DayPlanning Line No." = 0 then
            exit;

        if JobLedgerInvoiceLink.Get(Rec."Entry No.") then begin
            // Already linked (normally a harmless no-op match against codeunit 50607's own
            // dual-write in the same transaction - see remark above). If it points at a
            // DIFFERENT Job Planning Line than what "Job Usage Link" now says (e.g. native
            // "Transfer To Planning Lines" reused/retargeted a different existing planning
            // line), update it to match, so our own traceability table never goes stale.
            if (JobLedgerInvoiceLink."Job No." <> Rec."Job No.") or
               (JobLedgerInvoiceLink."Job Task No." <> Rec."Job Task No.") or
               (JobLedgerInvoiceLink."Invoice Job Planning Line No." <> Rec."Line No.")
            then begin
                JobLedgerInvoiceLink."Job No." := Rec."Job No.";
                JobLedgerInvoiceLink."Job Task No." := Rec."Job Task No.";
                JobLedgerInvoiceLink."Invoice Job Planning Line No." := Rec."Line No.";
                JobLedgerInvoiceLink.Modify();
            end;
        end else begin
            JobLedgerInvoiceLink.Init();
            JobLedgerInvoiceLink."Job Ledger Entry No." := Rec."Entry No.";
            JobLedgerInvoiceLink."Job No." := Rec."Job No.";
            JobLedgerInvoiceLink."Job Task No." := Rec."Job Task No.";
            JobLedgerInvoiceLink."Invoice Job Planning Line No." := Rec."Line No.";
            if DayPlanning.Get(JobLedgerEntry."Job No.", JobLedgerEntry."Job Task No.", JobLedgerEntry."Opt. DayPlanning Line No.") then
                JobLedgerInvoiceLink."Skill Code" := DayPlanning.Skill;
            JobLedgerInvoiceLink.Insert();
        end;
    end;

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
