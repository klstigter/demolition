report 50600 "RepairData"
{
    Permissions = tabledata "Day Planning" = rim,
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
        // Monday (20260803D) had 0 Requested Hours anywhere this week, so it had no data at all
        // (both bars empty) and no active skill series to show. Seeds it with DESIGN demand
        // first, so BalanceCapacityToRequested below has an actual Requested total to be
        // proportional against instead of treating "0 Requested" as already-balanced.
        CreateSkillDemand(20260803D, 'DESIGN', 300);

        // Brings each day's Capacity bar (= total Assigned Hours, see codeunit 50662) up to
        // roughly the same magnitude as that day's Requested bar (= total unassigned Requested
        // Hours), so the two bars read as comparable instead of Capacity being a near-invisible
        // sliver next to a full Requested bar.
        BalanceCapacityToRequested(20260803D, 100);
        BalanceCapacityToRequested(20260805D, 100);
        BalanceCapacityToRequested(20260806D, 100);
        BalanceCapacityToRequested(20260807D, 100);

        // Previously used one-off calls, kept for reuse rather than re-run automatically:
        // MakeAssignedBackToRequested(20260804D, 30);
        // CreateExternalCapacityForWeek(20260803D, 300);
        // MakeInternalResourcesExternal(20260803D, 30);
        // UndoMakeInternalResourcesExternal();
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
    ///
    /// Flipping "Is External" alone is often invisible on the chart: CalcCapacitySplit and
    /// CalcAssignedSplit both key off the SAME resource, so a fully-loaded resource's own
    /// capacity and its own assigned hours move from the Internal bucket to the External bucket
    /// together, netting ~0 change in ExternalFree (= ExternalCapacity - ExternalAssigned). To
    /// actually prove the external context out - real, visible movement on the Capacity bar's
    /// External segment - each flipped resource's Res. Capacity Entry for the day it was sampled
    /// on is topped up (via BoostExternalCapacityForResource) to Percentage% above its own
    /// Assigned Hours that day, so it contributes real spare External capacity instead of a wash.
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
                        BoostExternalCapacityForResource(TempDayInternalResource."No.", EntryDate, Percentage);
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

    /// <summary>
    /// Undoes the contamination left behind by a past manual run of MakeInternalResourcesExternal
    /// (or an equivalent direct-field-assignment flip), which set Resource."Is External" := true on
    /// resources without checking whether they were already classified "Is Pool" or "Is Pool
    /// Member" - a combination tableext 50603's own OnValidate triggers treat as mutually exclusive
    /// and would never allow through Validate(). Finds the contaminated set dynamically via
    /// SetRange (NOT a hardcoded resource list), so it is safe to re-run: once the sandbox is clean,
    /// both FindSet calls simply find 0 records.
    ///
    /// Clears "Is External" via DIRECT FIELD ASSIGNMENT, not Validate("Is External", false). Field
    /// 50604's OnValidate else-branch (the "set to false" path) also wipes "Vendor No.", "Pool
    /// Resource No.", "Is Pool", AND "Is Pool Member" as a side effect - going through Validate()
    /// here would destroy the exact Pool/Pool Member classification this procedure exists to
    /// restore. Direct assignment mirrors how the original contamination bug itself worked, undoing
    /// only the one flag that was wrongly set.
    ///
    /// Vendor No. is handled differently per group, based on live-data investigation:
    /// - "Is Pool" resources: Vendor No. is left AS-IS. Each carries its own legitimate,
    ///   pre-existing pool vendor (e.g. DRP001 -> DRV001), never touched by the original
    ///   MakeInternalResourcesExternal run because it only ever sets Vendor No. when blank.
    /// - "Is Pool Member" resources: Vendor No. is explicitly CLEARED back to ''. A genuine Pool
    ///   Member always has a blank Vendor No. (table 50603's own "Is Pool Member" OnValidate always
    ///   clears it), so a non-blank value here is contamination, not real data - confirmed live,
    ///   where every contaminated Pool Member resource carried the identical Vendor No. "10000"
    ///   (Vendor.FindFirst()'s result from the original repair run), not a per-resource value.
    /// </summary>
    procedure UndoMakeInternalResourcesExternal()
    var
        Resource: Record Resource;
        FixedPoolCount: Integer;
        FixedPoolMemberCount: Integer;
    begin
        Resource.SetRange("Is External", true);
        Resource.SetRange("Is Pool", true);
        if Resource.FindSet(true) then
            repeat
                Resource."Is External" := false;
                Resource.Modify();
                FixedPoolCount += 1;
            until Resource.Next() = 0;

        Resource.Reset();
        Resource.SetRange("Is External", true);
        Resource.SetRange("Is Pool Member", true);
        if Resource.FindSet(true) then
            repeat
                Resource."Is External" := false;
                Resource."Vendor No." := '';
                Resource.Modify();
                FixedPoolMemberCount += 1;
            until Resource.Next() = 0;

        Message(UndoInternalToExternalResultMsg, FixedPoolCount, FixedPoolMemberCount);
    end;

    /// <summary>
    /// Tops up ResourceNo's Res. Capacity Entry for EntryDate so its Capacity is at least
    /// BoostPercentage% above its own Assigned Hours that day - giving it real spare capacity to
    /// contribute to CalcCapacitySplit's External bucket once flipped, instead of a wash against
    /// CalcAssignedSplit's matching Assigned-hours move. No-op if the resource has no assigned
    /// hours that day (nothing to headroom above) or already has enough capacity.
    /// </summary>
    local procedure BoostExternalCapacityForResource(ResourceNo: Code[20]; EntryDate: Date; BoostPercentage: Decimal)
    var
        DayPlanning: Record "Day Planning";
        ResCapacityEntry: Record "Res. Capacity Entry";
        LastResCapacityEntry: Record "Res. Capacity Entry";
        AssignedHoursSum: Decimal;
        TargetCapacity: Decimal;
    begin
        DayPlanning.SetRange("Plan Date", EntryDate);
        DayPlanning.SetRange("Assigned Resource No.", ResourceNo);
        DayPlanning.CalcSums("Assigned Hours");
        AssignedHoursSum := DayPlanning."Assigned Hours";
        if AssignedHoursSum = 0 then
            exit;

        TargetCapacity := Round(AssignedHoursSum * (1 + BoostPercentage / 100), 0.01, '=');

        ResCapacityEntry.SetRange("Resource No.", ResourceNo);
        ResCapacityEntry.SetRange(Date, EntryDate);
        if ResCapacityEntry.FindFirst() then begin
            if ResCapacityEntry.Capacity < TargetCapacity then begin
                ResCapacityEntry.Capacity := TargetCapacity;
                ResCapacityEntry.Modify(true);
            end;
        end else begin
            ResCapacityEntry.Init();
            ResCapacityEntry."Resource No." := ResourceNo;
            ResCapacityEntry.Date := EntryDate;
            ResCapacityEntry.Capacity := TargetCapacity;

            LastResCapacityEntry.Reset();
            if LastResCapacityEntry.FindLast() then
                ResCapacityEntry."Entry No." := LastResCapacityEntry."Entry No." + 1
            else
                ResCapacityEntry."Entry No." := 1;

            ResCapacityEntry.Insert(true);
        end;
    end;

    /// <summary>
    /// Creates a single unassigned Day Planning line on PlanDate for SkillCode with the given
    /// Requested Hours, so codeunit 50662's BuildActiveSkillList picks up SkillCode as an active
    /// series again if it had none this week (a skill with 0 unassigned Requested Hours anywhere
    /// in the period gets no chart series or legend entry at all), and PlanDate gets a Requested
    /// total for BalanceCapacityToRequested to be proportional against instead of treating a
    /// genuinely empty day as already-balanced. Reuses an existing Job No./Job Task No. from
    /// whichever Day Planning row happens to be first in primary-key order - PlanDate itself may
    /// have no rows at all yet (that is the whole reason this procedure exists), so there is
    /// nothing local on that date to reuse from; this repair report only ever targets test/demo
    /// data, so which real job the synthetic line nominally belongs to is not significant.
    /// </summary>
    procedure CreateSkillDemand(PlanDate: Date; SkillCode: Code[20]; RequestedHours: Decimal)
    var
        DayPlanning: Record "Day Planning";
        TemplateDayPlanning: Record "Day Planning";
    begin
        DayPlanning.Reset();
        DayPlanning.SetFilter("Job No.", '<>%1', '');
        if not DayPlanning.FindFirst() then
            exit;
        TemplateDayPlanning := DayPlanning;

        DayPlanning.Init();
        DayPlanning."Job No." := TemplateDayPlanning."Job No.";
        DayPlanning."Job Task No." := TemplateDayPlanning."Job Task No.";
        DayPlanning."Plan Date" := PlanDate;
        DayPlanning.GetNextDayLineNo();
        DayPlanning.Skill := SkillCode;
        DayPlanning."Requested Hours" := RequestedHours;
        DayPlanning.Insert();

        Message(CreateSkillDemandResultMsg, RequestedHours, SkillCode, PlanDate);
    end;

    /// <summary>
    /// Tops up PlanDate's total Assigned Hours (the sum codeunit 50662's CalcAssignedSplit feeds
    /// into the Capacity bar) to roughly TargetPercentage% of that same day's total unassigned
    /// Requested Hours (the sum that feeds the Requested bar's skill segments), by inserting a
    /// single new, already-assigned Day Planning line for the gap - never by touching existing
    /// unassigned lines, which would shrink the Requested bar while growing the Capacity bar
    /// instead of bringing the two closer together. No-op if PlanDate has 0 Requested Hours (0
    /// Capacity is already "proportional" to 0 Requested) or Assigned Hours already meets the
    /// target. Reuses an existing Job No./Job Task No./Skill from one of PlanDate's own rows (so
    /// the synthetic line reads as part of the same project context) and the first Internal
    /// resource found (deliberately not External - this is about Capacity/Requested magnitude,
    /// not the separate Internal/External split MakeInternalResourcesExternal already covers).
    /// </summary>
    procedure BalanceCapacityToRequested(PlanDate: Date; TargetPercentage: Decimal)
    var
        DayPlanning: Record "Day Planning";
        TemplateDayPlanning: Record "Day Planning";
        Resource: Record Resource;
        TotalRequestedD: Decimal;
        TotalAssignedD: Decimal;
        TargetAssignedD: Decimal;
        GapD: Decimal;
    begin
        DayPlanning.SetRange("Plan Date", PlanDate);
        DayPlanning.SetRange("Assigned Resource No.", '');
        DayPlanning.CalcSums("Requested Hours");
        TotalRequestedD := DayPlanning."Requested Hours";
        if TotalRequestedD = 0 then
            exit;

        DayPlanning.Reset();
        DayPlanning.SetRange("Plan Date", PlanDate);
        DayPlanning.CalcSums("Assigned Hours");
        TotalAssignedD := DayPlanning."Assigned Hours";

        TargetAssignedD := Round(TotalRequestedD * TargetPercentage / 100, 1, '=');
        GapD := TargetAssignedD - TotalAssignedD;
        if GapD <= 0 then
            exit;

        DayPlanning.Reset();
        DayPlanning.SetRange("Plan Date", PlanDate);
        DayPlanning.SetFilter("Job No.", '<>%1', '');
        if not DayPlanning.FindFirst() then
            exit;
        TemplateDayPlanning := DayPlanning;

        Resource.SetRange("Is External", false);
        if not Resource.FindFirst() then
            exit;

        DayPlanning.Init();
        DayPlanning."Job No." := TemplateDayPlanning."Job No.";
        DayPlanning."Job Task No." := TemplateDayPlanning."Job Task No.";
        DayPlanning."Plan Date" := PlanDate;
        DayPlanning.GetNextDayLineNo();
        DayPlanning."Assigned Resource No." := Resource."No.";
        DayPlanning."Assigned Hours" := GapD;
        DayPlanning."Requested Hours" := GapD;
        DayPlanning.Skill := TemplateDayPlanning.Skill;
        DayPlanning.Insert();

        Message(BalanceCapacityResultMsg, PlanDate, GapD, TotalAssignedD + GapD, TotalRequestedD);
    end;

    var
        RepairResultMsg: Label 'Unassigned %1 of %2 Day Planning line(s) on %3, converting them back to Requested.';
        ExternalCapacityResultMsg: Label 'Created %1 and updated %2 Res. Capacity Entry day(s) for External resource %3, week starting %4.';
        ExternalDemoResourceNoTok: Label 'EXTDEMO', Locked = true;
        ExternalDemoResourceNameTxt: Label 'External Demo Resource';
        InternalToExternalResultMsg: Label 'Flipped %1 Internal resource(s) (sampled per weekday) to External, week starting %2.';
        UndoInternalToExternalResultMsg: Label 'Cleared "Is External" on %1 Pool resource(s) and %2 Pool Member resource(s) (Vendor No. also cleared on the latter).';
        BalanceCapacityResultMsg: Label 'Added %2 Assigned Hours on %1 (now %3 total), to match %4 Requested Hours.';
        CreateSkillDemandResultMsg: Label 'Created %1 unassigned Requested Hours for skill %2 on %3.';
}
