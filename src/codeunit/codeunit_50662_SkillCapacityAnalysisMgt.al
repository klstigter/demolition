codeunit 50662 "Skill Capacity Analysis Mgt."
{
    /// <summary>
    /// Aggregates Day Planning requested hours and resource capacity per Skill Code.
    ///
    /// Requested Hours are grouped by the Day Planning line's own "Skill" field.
    ///
    /// Capacity is NOT summed per line: the Day Planning "Capacity" FlowField is a daily
    /// total for the (Assigned Resource No., Plan Date) pair, so it is calculated once per
    /// DISTINCT pair. That single daily capacity value is then added - undivided - to EVERY
    /// skill the resource holds (Resource Skill, Type = Resource). Example: resource A has
    /// skills Design and Drawing and a daily capacity of 8, then Design gets +8 and
    /// Drawing gets +8.
    /// </summary>

    /// <summary>
    /// Builds the per-skill Requested Hours / Capacity buffer for the supplied filters.
    /// All filter parameters are optional; blank / 0D means "no filter".
    /// </summary>
    procedure BuildSkillBuffer(var Buffer: Record "Skill Req. vs Capacity Buffer" temporary; ResourceNoFilter: Code[20]; DateFromFilter: Date; DateToFilter: Date; SkillCodeFilter: Code[10])
    var
        DayPlanning: Record "Day Planning";
        ResourceSkill: Record "Resource Skill";
        RequestedHoursPerSkill: Dictionary of [Code[10], Decimal];
        CapacityPerSkill: Dictionary of [Code[10], Decimal];
        ProcessedResourceDates: Dictionary of [Text, Boolean];
        SkillCodes: List of [Code[10]];
        SkillCode: Code[10];
        ResourceDateKey: Text;
        DayCapacity: Decimal;
    begin
        Buffer.Reset();
        Buffer.DeleteAll();

        ApplyDayPlanningFilters(DayPlanning, ResourceNoFilter, DateFromFilter, DateToFilter, SkillCodeFilter);

        if DayPlanning.FindSet() then
            repeat
                // 1) Requested Hours belong to the skill recorded on the line itself.
                AddToTotals(RequestedHoursPerSkill, CopyStr(DayPlanning.Skill, 1, MaxStrLen(SkillCode)), DayPlanning."Requested Hours");

                // 2) Capacity: once per distinct (Assigned Resource No., Plan Date) pair,
                //    duplicated undivided onto every skill the resource holds.
                if DayPlanning."Assigned Resource No." <> '' then begin
                    ResourceDateKey := StrSubstNo('%1|%2', DayPlanning."Assigned Resource No.", Format(DayPlanning."Plan Date", 0, 9));
                    if not ProcessedResourceDates.ContainsKey(ResourceDateKey) then begin
                        ProcessedResourceDates.Add(ResourceDateKey, true);

                        DayPlanning.CalcFields(Capacity);
                        DayCapacity := DayPlanning.Capacity;

                        ResourceSkill.Reset();
                        ResourceSkill.SetRange(Type, ResourceSkill.Type::Resource);
                        ResourceSkill.SetRange("No.", DayPlanning."Assigned Resource No.");
                        if ResourceSkill.FindSet() then
                            repeat
                                AddToTotals(CapacityPerSkill, ResourceSkill."Skill Code", DayCapacity);
                            until ResourceSkill.Next() = 0;
                    end;
                end;
            until DayPlanning.Next() = 0;

        // 3) Union of both accumulators, narrowed to the Skill Code filter when one is set.
        SkillCodes := RequestedHoursPerSkill.Keys();
        foreach SkillCode in CapacityPerSkill.Keys() do
            if not SkillCodes.Contains(SkillCode) then
                SkillCodes.Add(SkillCode);

        foreach SkillCode in SkillCodes do
            if (SkillCodeFilter = '') or (SkillCode = SkillCodeFilter) then
                InsertBufferLine(Buffer, SkillCode, GetTotal(RequestedHoursPerSkill, SkillCode), GetTotal(CapacityPerSkill, SkillCode));

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

    local procedure InsertBufferLine(var Buffer: Record "Skill Req. vs Capacity Buffer" temporary; SkillCode: Code[10]; RequestedHours: Decimal; Capacity: Decimal)
    var
        SkillCodeRec: Record "Skill Code";
    begin
        Buffer.Init();
        Buffer."Skill Code" := SkillCode;
        if SkillCodeRec.Get(SkillCode) then
            Buffer.Description := SkillCodeRec.Description;
        Buffer."Requested Hours" := RequestedHours;
        Buffer.Capacity := Capacity;
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
}
