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
        Daytasks: Record "Day Tasks";
        n: Integer;
    begin
        Daytasks.SetFilter("No.", '<>%1', '');
        if Daytasks.FindSet() then begin
            repeat
                Daytasks."Data Owner" := Daytasks."Data Owner"::"ProjectManager";
                Daytasks.Modify();
            until Daytasks.Next() = 0;
        end;

        Daytasks.SetRange("No.", '');
        if Daytasks.FindSet() then begin
            repeat
                n += 1;
                if (n mod 2) = 0 then begin
                    Daytasks."Data Owner" := Daytasks."Data Owner"::"ProjectManager";
                    Daytasks.Modify();
                end;
            until Daytasks.Next() = 0;
        end;

        Message('finished updating records');
    end;

    var
    //myInt: Integer;
}