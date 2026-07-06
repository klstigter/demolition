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
        n: Integer;
    begin
        //<< create code here
        n := RepairDayPlanningPoolResourceNo();
        //>>
        Message('Finished. %1 record(s) repaired.', n);
    end;

    local procedure RepairDayPlanningPoolResourceNo(): Integer
    var
        DayPlanning: Record "Day Planning";
        Resource: Record Resource;
        ResourceNo: Code[20];
        NewPoolResNo: Code[20];
        n: Integer;
    begin
        // Assigned Resource No. is more dominant than Requested Resource No.: if it is filled,
        // the Pool Resource No. follows it; otherwise it follows Requested Resource No.
        if DayPlanning.FindSet(true) then
            repeat
                if DayPlanning."Assigned Resource No." <> '' then
                    ResourceNo := DayPlanning."Assigned Resource No."
                else
                    ResourceNo := DayPlanning."Requested Resource No.";

                if ResourceNo = '' then
                    NewPoolResNo := ''
                else
                    if Resource.Get(ResourceNo) then
                        NewPoolResNo := Resource."Pool Resource No."
                    else
                        NewPoolResNo := '';

                if DayPlanning."Pool Resource No." <> NewPoolResNo then begin
                    DayPlanning."Pool Resource No." := NewPoolResNo;
                    DayPlanning.Modify();
                    n += 1;
                end;
            until DayPlanning.Next() = 0;
        exit(n);
    end;

    var
    //myInt: Integer;
}