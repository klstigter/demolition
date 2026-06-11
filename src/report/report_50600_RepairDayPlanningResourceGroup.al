report 50600 "RepairData"
{
    Permissions = tabledata "Day Planning" = rimd,
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
        DayPlanning: Record "Day Planning";
        n: Integer;
    begin
        //<< create code here
        JobTask.SetRange("Job Task Type", JobTask."Job Task Type"::Posting);
        if JobTask.FindSet(true) then
            repeat
                // JobTask.Progress := 30 + Random(41) - 1;
                // JobTask.Modify(true);
                //n += 1;

                DayPlanning.SetRange("Job No.", JobTask."Job No.");
                DayPlanning.SetRange("Job Task No.", JobTask."Job Task No.");
                DayPlanning.Setfilter("Task Date", '<>%1', 0D);
                if DayPlanning.FindSet() then
                    repeat
                        DayPlanning."Plan Status" := DayPlanning."Plan Status"::Inprogress;
                        DayPlanning.Modify(true);
                        n += 1;
                    until DayPlanning.Next() = 0;
            until JobTask.Next() = 0;
        //>>
        Message('Finished. %1 record(s) repaired.', n);
    end;

    var
    //myInt: Integer;
}