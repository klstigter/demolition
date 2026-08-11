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

    /// <summary>
    /// Resolves a chart segment - identified by SegmentId (a bare Skill Code, or the literal
    /// CapacitySkillCodeTok 'CAPACITY' marker used for the synthetic aggregate row - see
    /// BuildSkillBuffer's own doc comment) plus its click origin - back to the real "Day
    /// Planning"/"Res. Capacity Entry" records that number was built from, and opens the matching
    /// standard list page pre-filtered to exactly that record set. Called from page 50681's
    /// OnShowSegmentData usercontrol trigger, itself fired by wrapper.js's right-click "Show Data"
    /// context menu on either:
    ///   - a single BAR (WholeChart = false) - that one skill's Day Planning rows, or, for the
    ///     CAPACITY bar, that period's Res. Capacity Entry rows. Uses the exact same filter logic
    ///     already used by page 50661's "Requested Hours" OnDrillDown, so the two drilldown
    ///     entry points (factbox field vs. chart right-click) can never disagree.
    ///   - the LEGEND entry (WholeChart = true, SegmentId ignored) - this chart has exactly ONE
    ///     series ("Requested Hours"), so there is no single narrower segment to broaden from the
    ///     way the live barchart's legend click broadens a classified series from one day to the
    ///     whole week. The closest analog here is broadening from one skill to every skill: all
    ///     Day Planning rows with a non-blank Skill for the current Resource No./period filters -
    ///     the combined rows behind every skill bar at once. The CAPACITY bar is deliberately
    ///     excluded from this - its number comes from a different source table
    ///     ("Res. Capacity Entry") and is not itself part of the skill breakdown the legend
    ///     generalizes over.
    /// This chart has no per-day breakdown at all - every bar already aggregates the whole
    /// displayed period - so, unlike the live barchart's ShowSegmentData, there is no
    /// DayIndex/BarType to resolve a date range from; DateFromFilter/DateToFilter are simply the
    /// page's own currently displayed period (always a concrete Monday..Sunday range, never
    /// blank), passed straight through.
    /// </summary>
    procedure ShowSegmentData(SegmentId: Text; WholeChart: Boolean; ResourceNoFilter: Code[20]; DateFromFilter: Date; DateToFilter: Date)
    begin
        if WholeChart then begin
            ShowAllSkillsSegment(ResourceNoFilter, DateFromFilter, DateToFilter);
            exit;
        end;

        if SegmentId = CapacitySkillCodeTok then
            ShowCapacitySegment(ResourceNoFilter, DateFromFilter, DateToFilter)
        else
            ShowSkillSegment(CopyStr(SegmentId, 1, 10), ResourceNoFilter, DateFromFilter, DateToFilter);
    end;

    /// <summary>
    /// Drilldown for a single skill bar - mirrors page 50661's "Requested Hours" OnDrillDown
    /// non-CAPACITY branch exactly (same fields, same filters), just reached from the chart's
    /// right-click menu instead of a factbox field click.
    /// </summary>
    local procedure ShowSkillSegment(SkillCode: Code[10]; ResourceNoFilter: Code[20]; DateFromFilter: Date; DateToFilter: Date)
    var
        DayPlanning: Record "Day Planning";
    begin
        DayPlanning.Reset();
        DayPlanning.SetRange(Skill, SkillCode);
        if ResourceNoFilter <> '' then
            DayPlanning.SetRange("Assigned Resource No.", ResourceNoFilter);
        DayPlanning.SetRange("Plan Date", DateFromFilter, DateToFilter);
        Page.Run(Page::"Day Plannings", DayPlanning);
    end;

    /// <summary>
    /// Drilldown for the synthetic CAPACITY bar - mirrors page 50661's "Requested Hours"
    /// OnDrillDown CAPACITY branch exactly (same fields, same filters, no Skill involved - capacity
    /// is a resource/date concept, not a per-skill one).
    /// </summary>
    local procedure ShowCapacitySegment(ResourceNoFilter: Code[20]; DateFromFilter: Date; DateToFilter: Date)
    var
        ResCapacityEntry: Record "Res. Capacity Entry";
    begin
        ResCapacityEntry.Reset();
        if ResourceNoFilter <> '' then
            ResCapacityEntry.SetRange("Resource No.", ResourceNoFilter);
        ResCapacityEntry.SetRange(Date, DateFromFilter, DateToFilter);
        Page.Run(Page::"Res. Capacity Entries", ResCapacityEntry);
    end;

    /// <summary>
    /// Drilldown for the legend entry (WholeChart = true) - see ShowSegmentData's own doc comment
    /// for why this is the chosen "whole" analog. A plain SetFilter(Skill, '&lt;&gt;%1', '')
    /// suffices (no resource classification/Mark() idiom needed, unlike the live barchart's
    /// Internal/External segments) since Skill is a plain Day Planning field.
    /// </summary>
    local procedure ShowAllSkillsSegment(ResourceNoFilter: Code[20]; DateFromFilter: Date; DateToFilter: Date)
    var
        DayPlanning: Record "Day Planning";
    begin
        DayPlanning.Reset();
        DayPlanning.SetFilter(Skill, '<>%1', '');
        if ResourceNoFilter <> '' then
            DayPlanning.SetRange("Assigned Resource No.", ResourceNoFilter);
        DayPlanning.SetRange("Plan Date", DateFromFilter, DateToFilter);
        Page.Run(Page::"Day Plannings", DayPlanning);
    end;

    var
        CapacitySkillCodeTok: Label 'CAPACITY', Locked = true;
        CapacityDescriptionTxt: Label 'Capacity';
}
