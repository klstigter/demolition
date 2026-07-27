report 50600 "RepairData"
{
    Permissions = tabledata "Day Planning" = rimd,
                  tabledata Resource = rimd,
                  tabledata "Res. Capacity Entry" = rimd,
                  tabledata "Work-Hour Template" = r,
                  tabledata "Base Calendar" = rimd,
                  tabledata "Base Calendar Change" = rimd,
                  tabledata "Demo Data Log Entry" = rimd,
                  tabledata "Job Planning Line" = rimd,
                  tabledata "Job Usage Link" = rim,
                  tabledata "Sales Invoice Line" = r,
                  tabledata "Sales Invoice Header" = r,
                  tabledata "Job Ledger Entry" = rm,
                  tabledata "Skill Code" = r,
                  tabledata "Job Task" = rm;
    UsageCategory = Administration;
    ApplicationArea = All;
    Caption = 'Repair Data';
    ProcessingOnly = true;

    dataset
    {

    }

    trigger OnPreReport()
    var
        CreateDemoDataCU: Codeunit "Create Demo Data";
        LogEntry: Record "Demo Data Log Entry";
        CalendarCode: Code[10];
        CountBefore: Integer;
        CountAfter: Integer;
        n: Integer;
    begin
        n := RepairDayPlanningFulfillment();
        Message('Finished. %1 Day Planning record(s) had their Hours/Capacity Fully Utilized fields repaired.', n);
    end;

    // Repair: "Day Planning"."Assigned Hours" (field 80), "Requested Hours" (field 65),
    // "Realized Hours" (field 85) and "Capacity Fully Utilized" (field 120) used to be
    // calculated by codeunit 50612 "General Planning Utilities".DayPlanningFulFillment by
    // summing working minutes across ALL other Day Planning records sharing the same
    // resource and plan date, inflating these fields with other overlapping records' hours.
    // That cross-record aggregation was removed so each Day Planning record now reflects
    // only its own working minutes. Existing records were saved with the old, inflated
    // values, so this recalculates and persists the corrected values via CalculateWorkingHours().
    local procedure RepairDayPlanningFulfillment(): Integer
    var
        DayPlanning: Record "Day Planning";
        OldRequestedHours: Decimal;
        OldAssignedHours: Decimal;
        OldRealizedHours: Decimal;
        OldCapacityFullyUtilized: Boolean;
        n: Integer;
    begin
        if DayPlanning.FindSet(true) then
            repeat
                OldRequestedHours := DayPlanning."Requested Hours";
                OldAssignedHours := DayPlanning."Assigned Hours";
                OldRealizedHours := DayPlanning."Realized Hours";
                OldCapacityFullyUtilized := DayPlanning."Capacity Fully Utilized";

                DayPlanning.CalculateWorkingHours();

                if (DayPlanning."Requested Hours" <> OldRequestedHours) or
                   (DayPlanning."Assigned Hours" <> OldAssignedHours) or
                   (DayPlanning."Realized Hours" <> OldRealizedHours) or
                   (DayPlanning."Capacity Fully Utilized" <> OldCapacityFullyUtilized)
                then begin
                    DayPlanning.Modify();
                    n += 1;
                end;
            until DayPlanning.Next() = 0;
        exit(n);
    end;
}