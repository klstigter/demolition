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
        RepairAssignedPlanStatus();
    end;

    local procedure RepairAssignedPlanStatus()
    var
        DayPlanning: Record "Day Planning";
        Counter: Integer;
    begin
        // Day Plannings with Assigned Hours <> 0 must be "In Progress". Modify(false) so no trigger runs.
        DayPlanning.SetFilter("Assigned Hours", '<>0');
        DayPlanning.SetFilter("Plan Status", '<>%1', DayPlanning."Plan Status"::"In Progress");
        if DayPlanning.FindSet(true) then
            repeat
                DayPlanning."Plan Status" := DayPlanning."Plan Status"::"In Progress";
                DayPlanning.Modify(false);
                Counter += 1;
            until DayPlanning.Next() = 0;
        Message('%1 Day Planning line(s) set to In Progress.', Counter);
    end;



}