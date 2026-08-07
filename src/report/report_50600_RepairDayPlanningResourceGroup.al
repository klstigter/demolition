report 50600 "RepairData"
{
    Permissions = tabledata "Day Planning" = rm,
                  tabledata "Res. Capacity Entry" = rimd;
    UsageCategory = Administration;
    ApplicationArea = All;
    Caption = 'Repair Data';
    ProcessingOnly = true;

    dataset
    {

    }

    trigger OnPreReport()
    begin
        // Test utility for the barchart's "fulfilled day" collapse (codeunit 50662's
        // CalcDaySegments) - converts 30% of 4 Aug 2026's currently-assigned Day Planning lines
        // back to Requested, so that day is deliberately left NOT fulfilled.
        MakeAssignedBackToRequested(20260804D, 30);
    end;

    /// <summary>
    /// Converts a Percentage% sample of the currently-ASSIGNED Day Planning lines on PlanDate
    /// back to "Requested" (unassigned) status - i.e. clears the assignment so those lines once
    /// again count as outstanding demand instead of fulfilled demand. Selection is the first
    /// SampleCount lines in primary-key order (deterministic, not random) so a given
    /// PlanDate/Percentage pair always produces the same, reproducible result for testing.
    /// Uses Validate("Assigned Resource No.", '') per line - matching table 50610's own
    /// OnValidate cascade, which also zeroes "Assigned Hours" - rather than a raw field wipe, so
    /// the resulting rows are indistinguishable from a line that was simply never assigned.
    /// </summary>
    procedure MakeAssignedBackToRequested(PlanDate: Date; Percentage: Decimal)
    var
        DayPlanning: Record "Day Planning";
        TotalCount: Integer;
        SampleCount: Integer;
        ProcessedCount: Integer;
    begin
        DayPlanning.SetRange("Plan Date", PlanDate);
        DayPlanning.SetFilter("Assigned Resource No.", '<>%1', '');
        TotalCount := DayPlanning.Count();
        SampleCount := Round(TotalCount * Percentage / 100, 1, '=');

        if DayPlanning.FindSet() then
            repeat
                if ProcessedCount < SampleCount then begin
                    DayPlanning.Validate("Assigned Resource No.", '');
                    DayPlanning.Modify(true);
                    ProcessedCount += 1;
                end;
            until DayPlanning.Next() = 0;

        Message(RepairResultMsg, ProcessedCount, TotalCount, PlanDate);
    end;

    var
        RepairResultMsg: Label 'Unassigned %1 of %2 Day Planning line(s) on %3, converting them back to Requested.';
}
