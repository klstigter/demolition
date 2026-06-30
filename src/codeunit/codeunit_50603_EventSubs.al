codeunit 50603 "EventSubs"
{
    Permissions = tabledata "Res. Ledger Entry" = rm,
                  tabledata "Job Ledger Entry" = rm,
                  tabledata "Day Planning" = m;

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

    // After Sales Invoice is posted: move Qty. Transferred to Invoice → Qty. Invoiced
    // and record the Posted Sales Invoice No. + Line No. on each Day Planning line.
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnAfterPostSalesDoc', '', false, false)]
    local procedure UpdateDayPlanningAfterSalesInvoicePost(
        var SalesHeader: Record "Sales Header";
        var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        SalesShptHdrNo: Code[20];
        RetRcpHdrNo: Code[20];
        SalesInvHdrNo: Code[20];
        SalesCrMemoHdrNo: Code[20])
    var
        DayPlanning: Record "Day Planning";
    begin
        if SalesHeader."Document Type" <> SalesHeader."Document Type"::Invoice then
            exit;
        if SalesInvHdrNo = '' then
            exit;

        DayPlanning.SetRange("Sales Invoice No.", SalesHeader."No.");
        DayPlanning.SetFilter("Qty. Transferred to Invoice", '>0');
        if not DayPlanning.FindSet(true) then
            exit;

        repeat
            DayPlanning."Qty. Invoiced" += DayPlanning."Qty. Transferred to Invoice";
            DayPlanning."Qty. Transferred to Invoice" := 0;
            DayPlanning."Posted Sales Invoice No." := SalesInvHdrNo;
            DayPlanning."Posted Sales Invoice Line No." := DayPlanning."Sales Invoice Line No.";
            DayPlanning.Modify();
        until DayPlanning.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Line", 'OnBeforeVATRoundingAdjustment', '', false, false)]
    local procedure DayPlanning_OnDeleteSalesLine(var SalesLine: Record "Sales Line"; StatusCheckSuspended: Boolean; var RequiresVATRoundingAdjustment: Boolean)
    var
        DayPlanning: Record "Day Planning";
    begin
        if (SalesLine."Job No." <> '') and (SalesLine."Job Task No." <> '') and (SalesLine."Day Planning Line No." <> 0) then
            if DayPlanning.Get(SalesLine."Job No.", SalesLine."Job Task No.", SalesLine."Day Planning Line No.") then begin
                DayPlanning."Qty. Transferred to Invoice" := 0;
                DayPlanning."Sales Invoice No." := '';
                DayPlanning."Sales Invoice Line No." := 0;
                DayPlanning.Modify();
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
