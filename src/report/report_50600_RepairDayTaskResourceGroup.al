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
        JOb: Record Job;
        JobTask: Record "Job Task";
    begin
        JOb.Reset;
        if JOb.FindSet() then begin
            repeat
                if JOb."Person Responsible" = '' then begin
                    JOb."Person Responsible" := 'ASSIA';
                    JOb.Modify();
                end;
            until JOb.Next() = 0;
        end;

        JobTask.Reset;
        JobTask.SetRange("Job Task Type", JobTask."Job Task Type"::Posting);
        if JobTask.FindSet() then begin
            repeat
                if JobTask."Project Manager" = '' then begin
                    Job.Get(JobTask."Job No.");
                    JobTask."Project Manager" := Job."Person Responsible";
                    JobTask.Modify();
                end;
            until JobTask.Next() = 0;
        end;

        Message('finished updating records');
    end;

    var
    //myInt: Integer;
}