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

    // trigger OnPreReport()
    // var
    //     Daytasks: Record "Day Tasks";
    //     n: Integer;
    // begin
    //     Daytasks.SetFilter("No.", '<>%1', '');
    //     if Daytasks.FindSet() then begin
    //         repeat
    //             Daytasks."Data Owner" := Daytasks."Data Owner"::"ProjectManager";
    //             Daytasks.Modify();
    //         until Daytasks.Next() = 0;
    //     end;

    //     Daytasks.SetRange("No.", '');
    //     if Daytasks.FindSet() then begin
    //         repeat
    //             n += 1;
    //             if (n mod 2) = 0 then begin
    //                 Daytasks."Data Owner" := Daytasks."Data Owner"::"ProjectManager";
    //                 Daytasks.Modify();
    //             end;
    //         until Daytasks.Next() = 0;
    //     end;

    //     Message('finished updating records');
    // end;

    trigger OnPreReport()
    var
        JobTask: Record "Job Task";
        Prefix: Text;
        Fixed: Integer;
    begin
        // Repair description accumulation caused by GanttChartDataHandler prepending
        // "TaskNo - " to the Gantt text field, which was then saved back to Description.
        // Example: "2010 - 2010 - 2010 - Spare Parts Procurement" → "Spare Parts Procurement"
        JobTask.SetRange("Job Task Type", JobTask."Job Task Type"::Posting);
        if JobTask.FindSet(true) then
            repeat
                Prefix := JobTask."Job Task No." + ' - ';
                // Strip all accumulated copies of the prefix
                while CopyStr(JobTask.Description, 1, StrLen(Prefix)) = Prefix do begin
                    JobTask.Description := CopyStr(JobTask.Description, StrLen(Prefix) + 1, MaxStrLen(JobTask.Description));
                    Fixed += 1;
                end;
                JobTask.Modify();
            until JobTask.Next() = 0;

        Message('Finished. %1 description(s) repaired.', Fixed);
    end;

    var
    //myInt: Integer;
}