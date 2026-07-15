codeunit 50603 "EventSubs"
{
    Permissions = tabledata "Res. Ledger Entry" = rm,
                  tabledata "Job Ledger Entry" = rm,
                  tabledata "Day Planning" = rm,
                  tabledata "Job Ledger Invoice Link" = rimd,
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
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnAfterPostSalesDoc', '', false, false)]
    local procedure UpdateJobLedgerInvoiceLinkOnAfterPostSalesDoc(var SalesHeader: Record "Sales Header"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; SalesShptHdrNo: Code[20]; RetRcpHdrNo: Code[20]; SalesInvHdrNo: Code[20]; SalesCrMemoHdrNo: Code[20]; CommitIsSuppressed: Boolean; InvtPickPutaway: Boolean; var CustLedgerEntry: Record "Cust. Ledger Entry"; WhseShip: Boolean; WhseReceiv: Boolean; PreviewMode: Boolean)
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        JobPlanningLine: Record "Job Planning Line";
        JobLedgerEntry: Record "Job Ledger Entry";
        JobLedgerInvoiceLink: Record "Job Ledger Invoice Link";
    begin
        if SalesInvHdrNo = '' then
            exit;
        if not SalesInvoiceHeader.Get(SalesInvHdrNo) then
            exit;

        SalesInvoiceLine.SetRange("Document No.", SalesInvHdrNo);
        SalesInvoiceLine.SetFilter("Job Contract Entry No.", '<>%1', 0);
        if not SalesInvoiceLine.FindSet() then
            exit;

        repeat
            JobPlanningLine.SetCurrentKey("Job Contract Entry No.");
            JobPlanningLine.SetRange("Job Contract Entry No.", SalesInvoiceLine."Job Contract Entry No.");
            if JobPlanningLine.FindFirst() then begin
                JobLedgerEntry.SetRange("Job No.", JobPlanningLine."Job No.");
                JobLedgerEntry.SetRange("Job Task No.", JobPlanningLine."Job Task No.");
                JobLedgerEntry.SetRange("Entry Type", JobLedgerEntry."Entry Type"::Sale);
                JobLedgerEntry.SetRange("Document No.", SalesInvHdrNo);
                JobLedgerEntry.SetRange("Posting Date", SalesInvoiceHeader."Posting Date");
                if JobLedgerEntry.FindFirst() then begin
                    JobLedgerInvoiceLink.SetRange("Job No.", JobPlanningLine."Job No.");
                    JobLedgerInvoiceLink.SetRange("Job Task No.", JobPlanningLine."Job Task No.");
                    JobLedgerInvoiceLink.SetRange("Invoice Job Planning Line No.", JobPlanningLine."Line No.");
                    if JobLedgerInvoiceLink.FindSet(true) then
                        repeat
                            JobLedgerInvoiceLink."Invoice Job Ledger Entry No." := JobLedgerEntry."Entry No.";
                            JobLedgerInvoiceLink.Modify();
                        until JobLedgerInvoiceLink.Next() = 0;
                end;
            end;
        until SalesInvoiceLine.Next() = 0;
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
