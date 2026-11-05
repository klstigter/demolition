report 50600 "RepairData"
{
    Permissions = tabledata "Day Planning" = rimd,
                  tabledata "Res. Capacity Entry" = rimd,
                  tabledata Resource = rim,
                  tabledata Vendor = r,
                  tabledata "Resource Skill" = rim,
                  tabledata "Skill Code" = r,
                  tabledata "Job Task" = rimd,
                  tabledata Job = rimd;
    UsageCategory = Administration;
    ApplicationArea = All;
    Caption = 'Repair Data';
    ProcessingOnly = true;

    dataset
    {

    }

    trigger OnPreReport()
    begin
        RecalculateDayPlanningHours();
    end;

    local procedure RecalculateDayPlanningHours()
    var
        DayPlanning: Record "Day Planning";
        OldRequested: Decimal;
        OldAssigned: Decimal;
        OldRealized: Decimal;
        Counter: Integer;
    begin
        // Hours depend only on start/end times and Non Working Minutes. Modify(false) so no trigger runs.
        if DayPlanning.FindSet(true) then
            repeat
                OldRequested := DayPlanning."Requested Hours";
                OldAssigned := DayPlanning."Assigned Hours";
                OldRealized := DayPlanning."Realized Hours";
                DayPlanning.CalculateWorkingHours();
                if (OldRequested <> DayPlanning."Requested Hours") or
                   (OldAssigned <> DayPlanning."Assigned Hours") or
                   (OldRealized <> DayPlanning."Realized Hours")
                then begin
                    DayPlanning.Modify(false);
                    Counter += 1;
                end;
            until DayPlanning.Next() = 0;
        Message('%1 Day Planning line(s) recalculated.', Counter);
    end;



}