report 50600 "RepairData"
{
    Permissions = tabledata "Day Tasks" = rimd,
                  tabledata Resource = rimd,
                  tabledata "Res. Capacity Entry" = rimd;
    UsageCategory = Administration;
    ApplicationArea = All;
    Caption = 'Repair Data';
    ProcessingOnly = true;

    dataset
    {

    }

    trigger OnPreReport()
    var
        JobTask: Record "Job Task";
        n: Integer;
    begin
        //<< create code here
        JobTask.SetRange("Job Task Type", JobTask."Job Task Type"::Posting);
        if JobTask.FindSet(true) then
            repeat
                JobTask.Progress := 30 + Random(41) - 1;
                JobTask.Modify(true);
                n += 1;
            until JobTask.Next() = 0;
        //>>
        Message('Finished. %1 record(s) repaired.', n);
    end;

    var
    //myInt: Integer;
}