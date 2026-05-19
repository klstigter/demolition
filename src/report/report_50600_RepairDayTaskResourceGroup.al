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
        Res0: Record Resource;
        Res: Record Resource;
        n: Integer;
    begin
        Res0.SetFilter("Pool Resource No.", '<>%1', '');
        if Res0.FindSet() then
            repeat
                Res.Get(Res0."Pool Resource No.");
                if Res."Vendor No." <> '' then begin
                    Res0."External Resource" := true;
                    Res0.Modify();
                    n += 1;
                end;
            until Res0.Next() = 0;
        Message('Finished. %1 resource(s) repaired.', n);
    end;

    var
    //myInt: Integer;
}