codeunit 50608 "SkillCapacityAnalysisMgt.v1"
{
    /// <summary>
    /// Aggregates Day Planning requested hours per Skill Code and total resource capacity.
    ///
    /// Requested Hours are grouped by the Day Planning line's own "Skill" field. One buffer row
    /// is produced per "Skill Code" MASTER record (optionally narrowed by SkillCodeFilter to a
    /// single one), not merely per skill code that happens to appear on a filtered Day Planning
    /// line - so a skill with zero matching lines still shows up, at 0, instead of silently
    /// disappearing from the chart/factbox.
    ///
    /// Capacity is NOT derived from Day Planning at all. The previous design summed the Day
    /// Planning "Capacity" FlowField once per distinct (Assigned Resource No., Plan Date) pair
    /// and duplicated that single daily total, undivided, onto every skill the resource holds.
    /// That both skewed the per-skill numbers (a resource's whole-day capacity copy-pasted
    /// onto every skill they hold is not "capacity to do skill X") and silently ignored any
    /// resource/date pair that had no Day Planning row yet - e.g. dates only touched by the
    /// "Res. Capacity Entry" repair report (report 50600), which never showed up here because
    /// this codeunit never read "Res. Capacity Entry" directly.
    ///
    /// Instead, Capacity is now a single aggregate figure read directly from
    /// "Res. Capacity Entry" for the Resource No. / Date range filters (the Skill Code filter
    /// is deliberately ignored for this total - capacity is a resource/date concept, not a
    /// per-skill one, even when the user has narrowed the Requested Hours rows to one skill).
    /// The buffer has a single generic value field, "Requested Hours" - there is no separate
    /// Capacity field/column anymore. That aggregate capacity total is appended as a single
    /// synthetic buffer row with "Skill Code" = 'CAPACITY' and its total stored directly in
    /// "Requested Hours", so the chart/factbox show exactly one bar/row per skill category plus
    /// one capacity reference bar/row - never a paired Requested/Capacity bar per category.
    /// </summary>

    /// <summary>
    /// Builds the Requested Hours (per skill) / Capacity (single aggregate) buffer for the
    /// supplied filters. All filter parameters are optional; blank / 0D means "no filter".
    /// </summary>
    procedure BuildSkillBuffer(var Buffer: Record "Skill Req. vs Capacity Buffer" temporary; ResourceNoFilter: Code[20]; DateFromFilter: Date; DateToFilter: Date; SkillCodeFilter: Code[10])
    var
        DayPlanning: Record "Day Planning";
        SkillCodeRec: Record "Skill Code";
        RequestedHoursPerSkill: Dictionary of [Code[10], Decimal];
        SkillCode: Code[10];
    begin
        Buffer.Reset();
        Buffer.DeleteAll();

        ApplyDayPlanningFilters(DayPlanning, ResourceNoFilter, DateFromFilter, DateToFilter, SkillCodeFilter);

        if DayPlanning.FindSet() then
            repeat
                // Requested Hours belong to the skill recorded on the line itself.
                AddToTotals(RequestedHoursPerSkill, CopyStr(DayPlanning.Skill, 1, MaxStrLen(SkillCode)), DayPlanning."Requested Hours");
            until DayPlanning.Next() = 0;

        // One row per "Skill Code" MASTER record - not per skill actually found on a Day
        // Planning line - so every configured skill shows (at 0 if it has no matching lines)
        // instead of silently disappearing. Matches codeunit 50694's BuildSkillCodeList on the
        // Capacity Overview page. SkillCodeFilter (when set) narrows this to a single master
        // record, same as it always narrowed ApplyDayPlanningFilters above.
        SkillCodeRec.Reset();
        if SkillCodeFilter <> '' then
            SkillCodeRec.SetRange(Code, SkillCodeFilter);
        if SkillCodeRec.FindSet() then
            repeat
                SkillCode := CopyStr(SkillCodeRec.Code, 1, MaxStrLen(SkillCode));
                InsertBufferLine(Buffer, SkillCode, GetTotal(RequestedHoursPerSkill, SkillCode));
            until SkillCodeRec.Next() = 0;

        // Single aggregate Capacity row, always appended (even when 0) so the chart/factbox
        // consistently show the reference bar/row. Deliberately ignores SkillCodeFilter.
        InsertCapacityLine(Buffer, CalcAggregateCapacity(ResourceNoFilter, DateFromFilter, DateToFilter));

        Buffer.Reset();
        if Buffer.FindFirst() then;
    end;

    local procedure ApplyDayPlanningFilters(var DayPlanning: Record "Day Planning"; ResourceNoFilter: Code[20]; DateFromFilter: Date; DateToFilter: Date; SkillCodeFilter: Code[10])
    begin
        DayPlanning.Reset();
        DayPlanning.SetCurrentKey("Plan Date", "Assigned Resource No.", "Start Time Assigned");

        if ResourceNoFilter <> '' then
            DayPlanning.SetRange("Assigned Resource No.", ResourceNoFilter);

        case true of
            (DateFromFilter <> 0D) and (DateToFilter <> 0D):
                DayPlanning.SetRange("Plan Date", DateFromFilter, DateToFilter);
            DateFromFilter <> 0D:
                DayPlanning.SetFilter("Plan Date", '>=%1', DateFromFilter);
            DateToFilter <> 0D:
                DayPlanning.SetFilter("Plan Date", '<=%1', DateToFilter);
        end;

        if SkillCodeFilter <> '' then
            DayPlanning.SetRange(Skill, SkillCodeFilter);
    end;

    /// <summary>
    /// Sums "Res. Capacity Entry".Capacity for the given Resource No. / Date range filters,
    /// using the same partial-range logic as ApplyDayPlanningFilters. Deliberately has no
    /// Skill Code parameter - capacity is a resource/date total, not a per-skill figure.
    /// </summary>
    local procedure CalcAggregateCapacity(ResourceNoFilter: Code[20]; DateFromFilter: Date; DateToFilter: Date): Decimal
    var
        ResCapacityEntry: Record "Res. Capacity Entry";
    begin
        ResCapacityEntry.Reset();

        if ResourceNoFilter <> '' then
            ResCapacityEntry.SetRange("Resource No.", ResourceNoFilter);

        case true of
            (DateFromFilter <> 0D) and (DateToFilter <> 0D):
                ResCapacityEntry.SetRange(Date, DateFromFilter, DateToFilter);
            DateFromFilter <> 0D:
                ResCapacityEntry.SetFilter(Date, '>=%1', DateFromFilter);
            DateToFilter <> 0D:
                ResCapacityEntry.SetFilter(Date, '<=%1', DateToFilter);
        end;

        ResCapacityEntry.CalcSums(Capacity);
        exit(ResCapacityEntry.Capacity);
    end;

    local procedure InsertBufferLine(var Buffer: Record "Skill Req. vs Capacity Buffer" temporary; SkillCode: Code[10]; RequestedHours: Decimal)
    var
        SkillCodeRec: Record "Skill Code";
    begin
        Buffer.Init();
        Buffer."No." := SkillCode;
        Buffer."Requested Hours" := RequestedHours;
        Buffer.Insert();
    end;

    /// <summary>
    /// Inserts the single synthetic "CAPACITY" row that carries the aggregate resource
    /// capacity total (see the codeunit doc comment) directly in "Requested Hours" - the buffer
    /// has no separate Capacity field. Its Skill Code is a literal marker, not a real
    /// "Skill Code" table entry, so the Description is set literally instead of routed through
    /// a table lookup. Page 50691's Requested Hours OnDrillDown special-cases this same
    /// literal - keep both in sync if it ever changes.
    /// </summary>
    local procedure InsertCapacityLine(var Buffer: Record "Skill Req. vs Capacity Buffer" temporary; CapacityTotal: Decimal)
    begin
        Buffer.Init();
        Buffer."No." := CapacitySkillCodeTok;
        Buffer."Requested Hours" := CapacityTotal;
        Buffer.Insert();
    end;

    local procedure AddToTotals(var Totals: Dictionary of [Code[10], Decimal]; SkillCode: Code[10]; ValueToAdd: Decimal)
    var
        CurrentValue: Decimal;
    begin
        if SkillCode = '' then
            exit;

        if Totals.ContainsKey(SkillCode) then
            CurrentValue := Totals.Get(SkillCode);

        Totals.Set(SkillCode, CurrentValue + ValueToAdd);
    end;

    local procedure GetTotal(var Totals: Dictionary of [Code[10], Decimal]; SkillCode: Code[10]): Decimal
    begin
        if Totals.ContainsKey(SkillCode) then
            exit(Totals.Get(SkillCode));

        exit(0);
    end;

    var
        CapacitySkillCodeTok: Label 'CAPACITY', Locked = true;
        CapacityDescriptionTxt: Label 'Capacity';
}
