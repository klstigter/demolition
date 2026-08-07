report 50600 "RepairData"
{
    Permissions = tabledata "Day Planning" = rm,
                  tabledata "Res. Capacity Entry" = rimd,
                  tabledata Resource = rim,
                  tabledata Vendor = r;
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
        // added LAST so it always stacks topmost, see BuildDayCapacityChartData). Reclassifying
        // existing Internal resources (MakeInternalResourcesExternal) only redistributes whatever
        // small leftover free-capacity pool already existed between the Internal/External
        // buckets - confirmed live it stayed a barely-visible sliver (9-17 hours against a
        // 1600-hour axis) because most of the week's real capacity is already consumed by real
        // assignments. A dedicated resource with its OWN large block of unassigned capacity
        // guarantees a properly visible External segment regardless of how the rest of the
        // week's data happens to look.
        CreateExternalCapacityForWeek(20260803D, 300);
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
    /// has real, clearly-visible nonzero data to render - always via the dedicated EXTDEMO
    /// resource (created on first use), never a real demo resource that might already carry its
    /// own assignments and eat into the added capacity. Sets "Vendor No."/"Is External" via direct
    /// field assignment rather than Validate() - Resource's own "Is External" OnValidate (tableext
    /// 50603) pops up an interactive Vendor picker whenever "Vendor No." is blank, which would
    /// hang this non-interactive repair run. Upserts per (resource, date) - re-running with a
    /// different HoursPerDay updates the existing entries to the new value instead of leaving them
    /// stuck at whatever an earlier run used.
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
        UpdatedCount: Integer;
    begin
        // Always the dedicated EXTDEMO resource, never "whichever Is External resource happens
        // to exist first" - a real demo resource like DRE001 usually already carries its own
        // assignments, which would eat into whatever capacity this adds and undercut the whole
        // point of a guaranteed, clearly-visible free-capacity block.
        if not Resource.Get(ExternalDemoResourceNoTok) then begin
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
            if ResCapacityEntry.FindFirst() then begin
                // Upsert, not skip - a previous run at a smaller HoursPerDay (e.g. the original
                // 8) would otherwise silently stay at that old value forever.
                ResCapacityEntry.Capacity := HoursPerDay;
                ResCapacityEntry.Modify(true);
                UpdatedCount += 1;
            end else begin
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

        Message(ExternalCapacityResultMsg, CreatedCount, UpdatedCount, Resource."No.", WeekStartDate);
    end;

    /// <summary>
    /// Flips a Percentage% sample of resources currently classified "Internal" (Resource."Is
    /// External" = false) over to "Is External" = true, so codeunit 50662's Internal/External
    /// capacity split (CalcCapacitySplit/CalcAssignedSplit) has real, sizeable External data to
    /// render on every weekday - not just a barely-visible sliver, and not concentrated onto
    /// whichever single resource happens to carry most of the week's hours. Sampling is done
    /// PER WEEKDAY independently (30% of Monday's distinct Internal resources, 30% of Tuesday's,
    /// etc., unioned - a resource already picked on an earlier day is not re-picked/re-counted on
    /// a later one) rather than 30% of resources active ANYWHERE in the week, because that
    /// whole-week version let one heavily-loaded resource (e.g. active mainly on a single day)
    /// dominate the sample and skew the result almost entirely onto that one day. "Is External" is
    /// a Resource master-data flag, not a per-week one, so this change is NOT scoped to
    /// WeekStartDate's week only - it affects that resource's classification everywhere (past and
    /// future dates alike), same as flipping it by hand on the Resource Card would. Selection
    /// within each day is the first DaySampleCount resources in primary-key order (deterministic,
    /// not random) for reproducible test results. Sets "Vendor No."/"Is External" via direct field
    /// assignment rather than Validate() - Resource's own "Is External" OnValidate (tableext
    /// 50603) pops up an interactive Vendor picker whenever "Vendor No." is blank, which would
    /// hang this non-interactive repair run.
    /// </summary>
    procedure MakeInternalResourcesExternal(WeekStartDate: Date; Percentage: Decimal)
    var
        DayPlanning: Record "Day Planning";
        Resource: Record Resource;
        TempSelectedResource: Record Resource temporary;
        TempDayInternalResource: Record Resource temporary;
        Vendor: Record Vendor;
        DayOffset: Integer;
        EntryDate: Date;
        DaySampleCount: Integer;
        DayProcessedCount: Integer;
        FlippedCount: Integer;
    begin
        for DayOffset := 0 to 4 do begin
            EntryDate := WeekStartDate + DayOffset;

            Clear(TempDayInternalResource);
            TempDayInternalResource.Reset();
            TempDayInternalResource.DeleteAll();

            DayPlanning.SetLoadFields("Assigned Resource No.");
            DayPlanning.SetRange("Plan Date", EntryDate);
            DayPlanning.SetFilter("Assigned Resource No.", '<>%1', '');
            if DayPlanning.FindSet() then
                repeat
                    if not TempSelectedResource.Get(DayPlanning."Assigned Resource No.") then
                        if not TempDayInternalResource.Get(DayPlanning."Assigned Resource No.") then
                            if Resource.Get(DayPlanning."Assigned Resource No.") then
                                if not Resource."Is External" then begin
                                    TempDayInternalResource := Resource;
                                    TempDayInternalResource.Insert();
                                end;
                until DayPlanning.Next() = 0;

            DaySampleCount := Round(TempDayInternalResource.Count() * Percentage / 100, 1, '=');
            DayProcessedCount := 0;

            TempDayInternalResource.Reset();
            if TempDayInternalResource.FindSet() then
                repeat
                    if DayProcessedCount < DaySampleCount then begin
                        TempSelectedResource := TempDayInternalResource;
                        TempSelectedResource.Insert();
                        DayProcessedCount += 1;
                    end;
                until TempDayInternalResource.Next() = 0;
        end;

        Vendor.FindFirst();

        TempSelectedResource.Reset();
        if TempSelectedResource.FindSet() then
            repeat
                Resource.Get(TempSelectedResource."No.");
                if Resource."Vendor No." = '' then
                    Resource."Vendor No." := Vendor."No.";
                Resource."Is External" := true;
                Resource.Modify();
                FlippedCount += 1;
            until TempSelectedResource.Next() = 0;

        Message(InternalToExternalResultMsg, FlippedCount, WeekStartDate);
    end;

    var
        RepairResultMsg: Label 'Unassigned %1 of %2 Day Planning line(s) on %3, converting them back to Requested.';
        ExternalCapacityResultMsg: Label 'Created %1 and updated %2 Res. Capacity Entry day(s) for External resource %3, week starting %4.';
        ExternalDemoResourceNoTok: Label 'EXTDEMO', Locked = true;
        ExternalDemoResourceNameTxt: Label 'External Demo Resource';
        InternalToExternalResultMsg: Label 'Flipped %1 Internal resource(s) (sampled per weekday) to External, week starting %2.';
}
