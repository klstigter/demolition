report 50600 "RepairData"
{
    Permissions = tabledata "Day Planning" = rim,
                  tabledata "Res. Capacity Entry" = rimd,
                  tabledata Resource = rim,
                  tabledata Vendor = r,
                  tabledata "Resource Skill" = rim,
                  tabledata "Skill Code" = r,
                  tabledata "Job Task" = rim;
    UsageCategory = Administration;
    ApplicationArea = All;
    Caption = 'Repair Data';
    ProcessingOnly = true;

    dataset
    {

    }

    trigger OnPreReport()
    begin
        RepairDayPlanning();
    end;

    local procedure RepairDayPlanning()
    var
        DayPlanning: Record "Day Planning";
        FixedCount: Integer;
    begin
        DayPlanning.Reset();
        if DayPlanning.findset() then
            repeat
                DayPlanning.CalculateWorkingHours();
                DayPlanning.Modify();
                FixedCount += 1;
            until DayPlanning.next() = 0;
        message('%1 Day Planning records repaired.', FixedCount);
    end;
}
