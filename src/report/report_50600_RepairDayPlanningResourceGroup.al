report 50600 "RepairData"
{
    Permissions = tabledata "Day Planning" = rimd,
                  tabledata Resource = rimd,
                  tabledata "Res. Capacity Entry" = rimd,
                  tabledata "Work-Hour Template" = r,
                  tabledata "Base Calendar" = rimd,
                  tabledata "Base Calendar Change" = rimd,
                  tabledata "Demo Data Log Entry" = rimd,
                  tabledata "Job Planning Line" = rimd,
                  tabledata "Job Ledger Invoice Link" = rimd,
                  tabledata "Job Usage Link" = rim,
                  tabledata "Sales Invoice Line" = r,
                  tabledata "Sales Invoice Header" = r,
                  tabledata "Job Ledger Entry" = r;
    UsageCategory = Administration;
    ApplicationArea = All;
    Caption = 'Repair Data';
    ProcessingOnly = true;

    dataset
    {

    }

    trigger OnPreReport()
    var
        CreateDemoDataCU: Codeunit "Create Demo Data";
        LogEntry: Record "Demo Data Log Entry";
        CalendarCode: Code[10];
        CountBefore: Integer;
        CountAfter: Integer;
        n: Integer;
    begin
        // n := BackfillInvoiceJobLedgerEntryNo();
        // Message('Finished. %1 "Job Ledger Invoice Link" record(s) updated with their posted invoice''s Job Ledger Entry No.', n);
        n := RefreshJobPlanningLineUnitPrice();
        Message('Finished. %1 Job Planning Line(s) had their Unit Price refreshed from Resource No.', n);
    end;

    // Backfill: "Job Ledger Invoice Link"."Invoice Job Ledger Entry No." (field 20) is
    // normally kept current by codeunit 50603's UpdateJobLedgerInvoiceLinkOnAfterPostSalesDoc
    // subscriber, but that only fires for invoices posted AFTER the subscriber was added -
    // Posted Sales Invoices that already existed before then never triggered it. This sweeps
    // every distinct Job Planning Line referenced by "Job Ledger Invoice Link", resolves its
    // posted Sale entry the same way the subscriber does, and updates all matching link rows.
    //
    // Chain: Job Planning Line."Job Contract Entry No." -> matching Posted Sales Invoice Line
    // (same field) -> its Document No./Posting Date -> Job Ledger Entry (Entry Type = Sale,
    // matching Job No./Job Task No./Document No./Posting Date).
    local procedure BackfillInvoiceJobLedgerEntryNo(): Integer
    var
        JobLedgerInvoiceLink: Record "Job Ledger Invoice Link";
        TempJobPlanningLineKey: Record "Job Planning Line" temporary;
        JobPlanningLine: Record "Job Planning Line";
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        JobLedgerEntry: Record "Job Ledger Entry";
        n: Integer;
    begin
        // Pass 1: collect the distinct (Job No., Job Task No., Line No.) keys of every Job
        // Planning Line referenced by "Job Ledger Invoice Link".
        if JobLedgerInvoiceLink.FindSet() then
            repeat
                if not TempJobPlanningLineKey.Get(JobLedgerInvoiceLink."Job No.", JobLedgerInvoiceLink."Job Task No.", JobLedgerInvoiceLink."Invoice Job Planning Line No.") then begin
                    TempJobPlanningLineKey.Init();
                    TempJobPlanningLineKey."Job No." := JobLedgerInvoiceLink."Job No.";
                    TempJobPlanningLineKey."Job Task No." := JobLedgerInvoiceLink."Job Task No.";
                    TempJobPlanningLineKey."Line No." := JobLedgerInvoiceLink."Invoice Job Planning Line No.";
                    TempJobPlanningLineKey.Insert();
                end;
            until JobLedgerInvoiceLink.Next() = 0;

        // Pass 2: for each distinct Job Planning Line, resolve its posted Sale entry and
        // update every "Job Ledger Invoice Link" row that shares it.
        if TempJobPlanningLineKey.FindSet() then
            repeat
                if JobPlanningLine.Get(TempJobPlanningLineKey."Job No.", TempJobPlanningLineKey."Job Task No.", TempJobPlanningLineKey."Line No.") then
                    if JobPlanningLine."Job Contract Entry No." <> 0 then begin
                        SalesInvoiceLine.SetCurrentKey("Job Contract Entry No.");
                        SalesInvoiceLine.SetRange("Job Contract Entry No.", JobPlanningLine."Job Contract Entry No.");
                        if SalesInvoiceLine.FindFirst() then
                            if SalesInvoiceHeader.Get(SalesInvoiceLine."Document No.") then begin
                                JobLedgerEntry.SetRange("Job No.", JobPlanningLine."Job No.");
                                JobLedgerEntry.SetRange("Job Task No.", JobPlanningLine."Job Task No.");
                                JobLedgerEntry.SetRange("Entry Type", JobLedgerEntry."Entry Type"::Sale);
                                JobLedgerEntry.SetRange("Document No.", SalesInvoiceLine."Document No.");
                                JobLedgerEntry.SetRange("Posting Date", SalesInvoiceHeader."Posting Date");
                                if JobLedgerEntry.FindFirst() then begin
                                    JobLedgerInvoiceLink.SetRange("Job No.", JobPlanningLine."Job No.");
                                    JobLedgerInvoiceLink.SetRange("Job Task No.", JobPlanningLine."Job Task No.");
                                    JobLedgerInvoiceLink.SetRange("Invoice Job Planning Line No.", JobPlanningLine."Line No.");
                                    if JobLedgerInvoiceLink.FindSet(true) then
                                        repeat
                                            JobLedgerInvoiceLink."Invoice Job Ledger Entry No." := JobLedgerEntry."Entry No.";
                                            JobLedgerInvoiceLink.Modify();
                                            n += 1;
                                        until JobLedgerInvoiceLink.Next() = 0;
                                end;
                            end;
                    end;
            until TempJobPlanningLineKey.Next() = 0;
        exit(n);
    end;

    // Backfill: refresh Unit Price on Job Planning Lines referenced by "Job Ledger Invoice
    // Link" (grouped Billable lines created by codeunit 50607), re-resolving it from the
    // line's own Resource No. via BC's standard price engine - useful if resource prices
    // changed after the lines were originally created. Scoped to lines NOT YET invoiced
    // ("Job Ledger Invoice Link"."Invoice Job Ledger Entry No." = 0, per explicit
    // instruction) - never touch price on a line whose posted Sales Invoice already exists,
    // since the financial transaction has already happened.
    //
    // Uses FindPriceAndDiscount(CalledByFieldNo) - the same procedure Job Planning Line's
    // own "No." field OnValidate calls - rather than re-Validate("No.", ...), so only price/
    // discount are recalculated; Description, Unit of Measure, and other fields derived from
    // "No." are left untouched.
    local procedure RefreshJobPlanningLineUnitPrice(): Integer
    var
        JobLedgerInvoiceLink: Record "Job Ledger Invoice Link";
        TempJobPlanningLineKey: Record "Job Planning Line" temporary;
        JobPlanningLine: Record "Job Planning Line";
        n: Integer;
    begin
        // Pass 1: collect the distinct (Job No., Job Task No., Line No.) keys of every Job
        // Planning Line referenced by a not-yet-invoiced "Job Ledger Invoice Link" row.
        JobLedgerInvoiceLink.SetRange("Invoice Job Ledger Entry No.", 0);
        if JobLedgerInvoiceLink.FindSet() then
            repeat
                if not TempJobPlanningLineKey.Get(JobLedgerInvoiceLink."Job No.", JobLedgerInvoiceLink."Job Task No.", JobLedgerInvoiceLink."Invoice Job Planning Line No.") then begin
                    TempJobPlanningLineKey.Init();
                    TempJobPlanningLineKey."Job No." := JobLedgerInvoiceLink."Job No.";
                    TempJobPlanningLineKey."Job Task No." := JobLedgerInvoiceLink."Job Task No.";
                    TempJobPlanningLineKey."Line No." := JobLedgerInvoiceLink."Invoice Job Planning Line No.";
                    TempJobPlanningLineKey.Insert();
                end;
            until JobLedgerInvoiceLink.Next() = 0;

        // Pass 2: for each, re-resolve Unit Price/discount from the current Resource No.
        if TempJobPlanningLineKey.FindSet() then
            repeat
                if JobPlanningLine.Get(TempJobPlanningLineKey."Job No.", TempJobPlanningLineKey."Job Task No.", TempJobPlanningLineKey."Line No.") then
                    if (JobPlanningLine.Type = JobPlanningLine.Type::Resource) and (JobPlanningLine."No." <> '') then begin
                        // InitRoundingPrecisions() populates the rounding-precision globals
                        // FindPriceAndDiscount's own price/amount conversions depend on
                        // (e.g. ConvertAmountToLCY's Round() call). Normal page usage
                        // primes these earlier in the record's lifecycle; calling
                        // FindPriceAndDiscount directly here (outside that lifecycle) skips
                        // that priming, leaving precision at 0 and causing a runtime error
                        // ("ROUND parameter 2... permitted range is from 1 to...").
                        JobPlanningLine.InitRoundingPrecisions();
                        JobPlanningLine.FindPriceAndDiscount(JobPlanningLine.FieldNo("No."));
                        JobPlanningLine.Modify(true);
                        n += 1;
                    end;
            until TempJobPlanningLineKey.Next() = 0;
        exit(n);
    end;
}