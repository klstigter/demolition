report 50600 "RepairData"
{
    Permissions = tabledata "Day Planning" = rm,
                  tabledata "Res. Capacity Entry" = rimd,
                  tabledata Resource = rim;
    UsageCategory = Administration;
    ApplicationArea = All;
    Caption = 'Repair Data';
    ProcessingOnly = true;

    dataset
    {

    }

    trigger OnPreReport()
    begin
        // Test utility for the barchart's "External" segment (codeunit 50662 - the series is now
        // added LAST so it always stacks topmost, see BuildDayCapacityChartData): the live period
        // had zero External data anywhere, so nothing was actually on screen to verify the
        // top-stacking/legend-border changes against. Ensures free (unassigned) External capacity
        // exists on every weekday of the given week.
        CreateExternalCapacityForWeek(20260803D, 8);

        // Previously used one-off calls, kept for reuse rather than re-run automatically:
        // MakeAssignedBackToRequested(20260804D, 30);
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

    /// <summary>
    /// Ensures free (unassigned) External Res. Capacity Entry hours exist on every weekday
    /// (Mon..Fri) of the week starting WeekStartDate, so codeunit 50662's "External" chart series
    /// has real nonzero data to render. Reuses the first existing "Is External" resource if one
    /// exists; otherwise creates one. Sets "Vendor No."/"Is External" via direct field assignment
    /// rather than Validate() - Resource's own "Is External" OnValidate (tableext 50603) pops up
    /// an interactive Vendor picker whenever "Vendor No." is blank, which would hang this
    /// non-interactive repair run. Idempotent per (resource, date) - skips days that already have
    /// an entry for the resource, so re-running does not create duplicates.
    /// </summary>
    procedure CreateExternalCapacityForWeek(WeekStartDate: Date; HoursPerDay: Decimal)
    var
        Resource: Record Resource;
        Vendor: Record Vendor;
        ResCapacityEntry: Record "Res. Capacity Entry";
        LastResCapacityEntry: Record "Res. Capacity Entry";
        DayOffset: Integer;
        EntryDate: Date;
        CreatedCount: Integer;
    begin
        Resource.SetRange("Is External", true);
        if not Resource.FindFirst() then begin
            Vendor.FindFirst();
            Resource.Init();
            Resource."No." := ExternalDemoResourceNoTok;
            Resource.Name := ExternalDemoResourceNameTxt;
            Resource.Type := Resource.Type::Person;
            Resource."Vendor No." := Vendor."No.";
            Resource."Is External" := true;
            Resource.Insert(true);
        end;

        for DayOffset := 0 to 4 do begin
            EntryDate := WeekStartDate + DayOffset;
            ResCapacityEntry.SetRange("Resource No.", Resource."No.");
            ResCapacityEntry.SetRange(Date, EntryDate);
            if not ResCapacityEntry.FindFirst() then begin
                ResCapacityEntry.Init();
                ResCapacityEntry."Resource No." := Resource."No.";
                ResCapacityEntry.Date := EntryDate;
                ResCapacityEntry.Capacity := HoursPerDay;

                LastResCapacityEntry.Reset();
                if LastResCapacityEntry.FindLast() then
                    ResCapacityEntry."Entry No." := LastResCapacityEntry."Entry No." + 1
                else
                    ResCapacityEntry."Entry No." := 1;

                ResCapacityEntry.Insert(true);
                CreatedCount += 1;
            end;
        end;

        Message(ExternalCapacityResultMsg, CreatedCount, Resource."No.", WeekStartDate);
    end;

    var
        RepairResultMsg: Label 'Unassigned %1 of %2 Day Planning line(s) on %3, converting them back to Requested.';
        ExternalCapacityResultMsg: Label 'Created %1 new Res. Capacity Entry day(s) for External resource %2, week starting %3.';
        ExternalDemoResourceNoTok: Label 'EXTDEMO', Locked = true;
        ExternalDemoResourceNameTxt: Label 'External Demo Resource';
}
