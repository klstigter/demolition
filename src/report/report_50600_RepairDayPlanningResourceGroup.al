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
                  tabledata "Job Usage Link" = rim,
                  tabledata "Sales Invoice Line" = r,
                  tabledata "Sales Invoice Header" = r,
                  tabledata "Job Ledger Entry" = rm,
                  tabledata "Skill Code" = r,
                  tabledata "Job Task" = rm;
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
        n := RepairInvoiceResourceNo();
        Message('Finished. %1 Job Ledger Entry(s) had their Invoice Resource No. repaired.', n);
    end;

    // Repair: "Job Ledger Entry"."Invoice Resource No." (field 50621) is copied from
    // "Skill Code"."Invoice Resource No." (field 50609) at posting time by EventSubs
    // (codeunit 50603), the same lookup "Daytask Journal-Post" (codeunit 50660) does when
    // building the Job Journal Line. For day-planning-sourced entries where it was either
    // never populated or has drifted out of sync with the Skill Code's current value, this
    // re-applies the Skill Code lookup so posted history matches current setup.
    local procedure RepairInvoiceResourceNo(): Integer
    var
        JobLedgerEntry: Record "Job Ledger Entry";
        SkillCode: Record "Skill Code";
        n: Integer;
    begin
        JobLedgerEntry.SetFilter("Opt. DayPlanning Line No.", '<>0');
        JobLedgerEntry.SetFilter(Skill, '<>%1', '');
        if JobLedgerEntry.FindSet(true) then
            repeat
                if SkillCode.Get(JobLedgerEntry.Skill) then
                    if JobLedgerEntry."Invoice Resource No." <> SkillCode."Invoice Resource No." then begin
                        JobLedgerEntry."Invoice Resource No." := SkillCode."Invoice Resource No.";
                        JobLedgerEntry.Modify();
                        n += 1;
                    end;
            until JobLedgerEntry.Next() = 0;
        exit(n);
    end;
}