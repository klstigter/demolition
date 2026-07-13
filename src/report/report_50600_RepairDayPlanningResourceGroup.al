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
                  tabledata "Job Ledger Invoice Link" = r,
                  tabledata "Job Usage Link" = rim;
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
        n := BackfillJobUsageLinkFromInvoiceLink();
        Message('Finished. %1 "Job Usage Link" record(s) created.', n);
    end;


    // Backfill: every "Job Ledger Invoice Link" row should have a matching standard
    // "Job Usage Link" row (see codeunit 50607's dual-write in CreateInvoicePlanningLine),
    // but that dual-write only applies to rows created AFTER the fix was added - existing
    // "Job Ledger Invoice Link" rows from earlier in this feature's rollout have no
    // corresponding "Job Usage Link" row yet. This sweeps all of them and inserts what's
    // missing, mapped directly from "Job Ledger Invoice Link"'s own fields ("Job Ledger
    // Entry No." -> "Entry No.", "Invoice Job Planning Line No." -> "Line No.", plus Job
    // No./Job Task No.) - unconditional, no Job."Apply Usage Link" gate and no Day Planning
    // lookup, per explicit instruction.
    local procedure BackfillJobUsageLinkFromInvoiceLink(): Integer
    var
        JobLedgerInvoiceLink: Record "Job Ledger Invoice Link";
        JobUsageLink: Record "Job Usage Link";
        n: Integer;
    begin
        if JobLedgerInvoiceLink.FindSet() then
            repeat
                if not JobUsageLink.Get(JobLedgerInvoiceLink."Job No.", JobLedgerInvoiceLink."Job Task No.", JobLedgerInvoiceLink."Invoice Job Planning Line No.", JobLedgerInvoiceLink."Job Ledger Entry No.") then begin
                    JobUsageLink.Init();
                    JobUsageLink."Job No." := JobLedgerInvoiceLink."Job No.";
                    JobUsageLink."Job Task No." := JobLedgerInvoiceLink."Job Task No.";
                    JobUsageLink."Line No." := JobLedgerInvoiceLink."Invoice Job Planning Line No.";
                    JobUsageLink."Entry No." := JobLedgerInvoiceLink."Job Ledger Entry No.";
                    JobUsageLink.Insert(true);
                    n += 1;
                end;
            until JobLedgerInvoiceLink.Next() = 0;
        exit(n);
    end;
}