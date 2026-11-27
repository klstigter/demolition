report 50600 "RepairData"
{
    Permissions = tabledata "Default Dimension" = rd,
                  tabledata "Day Planning" = rimd,
                  tabledata "Res. Capacity Entry" = rimd,
                  tabledata Vendor = r,
                  tabledata Company = r,
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
    var
        Company: Record Company;
        DefaultDimension: Record "Default Dimension";
        DeletedCount: Integer;
        TotalDeleted: Integer;
        CompanyCount: Integer;
    begin
        if Company.FindSet() then
            repeat
                CompanyCount += 1;
                DefaultDimension.ChangeCompany(Company.Name);
                DefaultDimension.SetRange("No.", '');
                DeletedCount := DefaultDimension.Count();
                if DeletedCount > 0 then begin
                    DefaultDimension.DeleteAll(true);
                    TotalDeleted += DeletedCount;
                end;
            until Company.Next() = 0;
        Message('%1 Account Type Default Dimension(s) deleted across %2 company(ies).', TotalDeleted, CompanyCount);
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