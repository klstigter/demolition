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
                  tabledata "Job Ledger Entry" = r,
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
        n := BackfillJobTaskProgress();
        Message('Finished. %1 Job Task(s) had their Progress %% filled with a random value.', n);
    end;

    // Backfill: "Job Task".Progress (%) (field 50601) is only meaningful on actual Posting
    // rows, not Total/Begin-Total/End-Total header rows, and defaults to 0 ("not filled") per
    // its own MinValue=0/MaxValue=100 definition. This sweeps every Posting Job Task still at
    // Progress = 0 and fills it with a random 0-100 value, so pre-existing demo data (created
    // before Progress was ever populated by the demo generator) gets caught up without a full
    // "Create Demo Data" regeneration.
    local procedure BackfillJobTaskProgress(): Integer
    var
        JobTask: Record "Job Task";
        n: Integer;
    begin
        JobTask.SetRange("Job Task Type", JobTask."Job Task Type"::Posting);
        JobTask.SetRange(Progress, 0);
        if JobTask.FindSet(true) then
            repeat
                JobTask.Progress := Random(101) - 1; // Random(101) yields 1..101, so -1 gives 0..100 inclusive
                JobTask.Modify();
                n += 1;
            until JobTask.Next() = 0;
        exit(n);
    end;
}