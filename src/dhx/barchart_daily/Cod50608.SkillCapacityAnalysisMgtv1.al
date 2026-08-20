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
    /// Returns the colour to use for SkillCode's bar on the daily chart - kept public because
    /// other code (codeunit 50604 "DHX Data Handler"'s ResolveRequestedColor) calls it
    /// cross-codeunit. Thin forward to codeunit "Color Constants Opti." (50609) - see that
    /// codeunit's GetSkillBarColor for the actual "Bar Color"-override/5-colour-palette/
    /// CAPACITY-marker-blank logic, now the single authoritative copy shared with codeunit
    /// 50662's own GetSkillSeriesColor twin.
    /// </summary>
    procedure GetSkillBarColor(SkillCode: Code[10]; PaletteIndex: Integer): Text
    var
        ColorConstants: Codeunit "Color Constants Opti.";
    begin
        exit(ColorConstants.GetSkillBarColor(SkillCode, PaletteIndex));
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
    /// Returns PlanDateFrom..PlanDateTo's Assigned/Free Capacity split, Internal/External, so the
    /// CAPACITY reference bar can render the same stacked Assigned/Free breakdown as
    /// src/dhx/barchart_weekly's per-day chart instead of a single flat aggregate. Delegates
    /// entirely to Codeunit "Skill Capacity Analysis Mgt." (the Weekly chart's own management
    /// codeunit) - see that codeunit's GetCapacitySplitForRange - rather than reimplementing the
    /// Internal/External classification here, so the two charts' numbers can never drift apart.
    /// </summary>
    procedure GetCapacityAssignedFreeSplit(PlanDateFrom: Date; PlanDateTo: Date; var AssignedInternal: Decimal; var AssignedExternal: Decimal; var CapacityInternal: Decimal; var CapacityExternal: Decimal)
    begin
        SkillCapacityAnalysisMgtWeekly.GetCapacitySplitForRange(PlanDateFrom, PlanDateTo, AssignedInternal, AssignedExternal, CapacityInternal, CapacityExternal);
    end;

    /// <summary>
    /// Returns the same Assigned/Free-Capacity colour tokens src/dhx/barchart_weekly's stacked
    /// chart uses (green Assigned, blue Free Capacity, red External border) so the CAPACITY bar's
    /// stacked segments (and its legend swatch, painted with CapacityColor as the bar's single
    /// representative colour) always match Weekly's exact tokens, never a locally hardcoded copy.
    /// Forwards through Codeunit "Skill Capacity Analysis Mgt." (50662) rather than calling
    /// codeunit "Color Constants Opti." (50609) directly - 50662's own GetCapacitySegmentColors is
    /// itself now just a thin forward to 50609, so the resolved values are identical either way;
    /// going through 50662 is the smaller/lower-churn change since this call site already existed.
    /// </summary>
    procedure GetCapacitySegmentColors(var AssignedColor: Text; var CapacityColor: Text; var ExternalBorderColor: Text)
    begin
        SkillCapacityAnalysisMgtWeekly.GetCapacitySegmentColors(AssignedColor, CapacityColor, ExternalBorderColor);
    end;

    /// <summary>
    /// Appends the CAPACITY bar's 4 stacked segments (Assigned Internal/External, Free Capacity
    /// Internal/External) to SeriesArray, matching wrapper.js's series JSON contract (name/values/
    /// color/[border]/stacked - same shape codeunit 50662's own AddChartSeries builds for the
    /// Weekly chart). Each *Values array must already be index-aligned with the chart's
    /// CategoriesArray (0 at every non-CAPACITY row, the real split only at the CAPACITY row) -
    /// see page 50681/50707's own RefreshChart for how those are built. Colours are passed in
    /// (not re-fetched here) so a caller that also needs them for the CAPACITY row's legend swatch
    /// (see GetCapacitySegmentColors) only calls that once.
    /// </summary>
    procedure AddCapacitySegmentSeries(var SeriesArray: JsonArray; AssInternalValues: JsonArray; AssExternalValues: JsonArray; CapInternalValues: JsonArray; CapExternalValues: JsonArray; AssignedColor: Text; CapacityColor: Text; ExternalBorderColor: Text)
    begin
        AddSeries(SeriesArray, AssInternalSeriesNameLbl, AssInternalValues, AssignedColor, '');
        AddSeries(SeriesArray, AssExternalSeriesNameLbl, AssExternalValues, AssignedColor, ExternalBorderColor);
        AddSeries(SeriesArray, CapInternalSeriesNameLbl, CapInternalValues, CapacityColor, '');
        AddSeries(SeriesArray, CapExternalSeriesNameLbl, CapExternalValues, CapacityColor, ExternalBorderColor);
    end;

    local procedure AddSeries(var SeriesArray: JsonArray; SeriesName: Text; Values: JsonArray; ColorHex: Text; BorderHex: Text)
    var
        SeriesObj: JsonObject;
    begin
        SeriesObj.Add('name', SeriesName);
        SeriesObj.Add('values', Values);
        SeriesObj.Add('color', ColorHex);
        if BorderHex <> '' then
            SeriesObj.Add('border', BorderHex);
        SeriesObj.Add('stacked', true);
        SeriesArray.Add(SeriesObj);
    end;

    /// <summary>
    /// Splits each Skill Code's demand into an Assigned bucket and an Unassigned bucket, using
    /// the SAME two fields/concepts codeunit "Skill Capacity Analysis Mgt." (weekly chart) uses
    /// for its own day-level Assigned/Requested split (CalcAssignedSplit / the doc comment on
    /// BuildDayCapacityChartData) - NOT both drawn from "Requested Hours". Assigned is
    /// "Assigned Hours" (only ever populated once a resource is actually assigned, same as
    /// CalcAssignedSplit sums with no extra "Assigned Resource No." filter needed); Unassigned is
    /// "Requested Hours" on rows with a blank "Assigned Resource No." (matches
    /// CalcUnassignedSkillRequestedSplit's own row population exactly). Summing
    /// AssignedHoursPerSkill across every skill for one date reproduces the exact same total the
    /// weekly chart's Assigned Capacity segment shows for that date - same rows, same field, just
    /// grouped by Skill here instead of collapsed to one day-level figure there. Because Assigned
    /// Hours and Requested Hours are different fields that can diverge per row, a skill's
    /// AssignedHoursPerSkill + UnassignedHoursPerSkill no longer necessarily sums back to that
    /// skill's flat "Requested Hours" buffer-row total (page 50691's factbox) - that's expected,
    /// not a bug: the factbox still shows pure Requested Hours, the chart now shows how much of
    /// that demand is actually assigned-capacity vs still-outstanding-request.
    ///
    /// Deliberately NOT folded into the "Skill Req. vs Capacity Buffer" table itself - matching
    /// this codeunit's own doc comment on why that buffer's shape/meaning stays a single flat
    /// "Requested Hours" per row (page 50691's factbox list still shows that flat total,
    /// unchanged) - this is a chart-only concern, computed as its own parallel lookup, same
    /// pattern GetCapacityAssignedFreeSplit/GetCapacitySegmentColors already established for the
    /// CAPACITY row's own split. Callers pass the SAME (ResourceNoFilter, DateFromFilter,
    /// DateToFilter) their own BuildSkillBuffer call used, or the two totals will disagree.
    ///
    /// One bulk pass (not one query per skill) - mirrors BuildSkillBuffer's own single-pass/
    /// Dictionary-accumulation shape (AddToTotals), just accumulating into two Dictionaries
    /// instead of one.
    /// </summary>
    procedure BuildSkillAssignedUnassignedSplit(ResourceNoFilter: Code[20]; DateFromFilter: Date; DateToFilter: Date; var AssignedHoursPerSkill: Dictionary of [Code[10], Decimal]; var UnassignedHoursPerSkill: Dictionary of [Code[10], Decimal])
    var
        DayPlanning: Record "Day Planning";
        SkillCode: Code[10];
    begin
        Clear(AssignedHoursPerSkill);
        Clear(UnassignedHoursPerSkill);

        ApplyDayPlanningFilters(DayPlanning, ResourceNoFilter, DateFromFilter, DateToFilter, '');
        if DayPlanning.FindSet() then
            repeat
                SkillCode := CopyStr(DayPlanning.Skill, 1, MaxStrLen(SkillCode));
                if DayPlanning."Assigned Resource No." <> '' then
                    AddToTotals(AssignedHoursPerSkill, SkillCode, DayPlanning."Assigned Hours")
                else
                    AddToTotals(UnassignedHoursPerSkill, SkillCode, DayPlanning."Requested Hours");
            until DayPlanning.Next() = 0;
    end;

    /// <summary>
    /// Appends the single shared "Requested - Assigned" series that sits at the BOTTOM of every
    /// SKILL bar's stack (green, same AssignedColor token as GetCapacitySegmentColors/the
    /// CAPACITY bar's own Assigned segments) - the "distribute Assigned Hours into the daily
    /// chart" feature requested against the flat-CAPACITY-bar work above: each skill's own
    /// Requested Hours total is now split into how much of it already has an Assigned Resource
    /// (this series) vs how much is still Unassigned (see AddSkillUnassignedSeries). ONE shared
    /// series across every skill category (not one per skill) because the Assigned colour never
    /// varies by skill - only the Unassigned segment on top does, which is why that one needs its
    /// own series per skill. Values must be 0 on the CAPACITY row - that row's own Assigned figure
    /// comes from a different, unrelated source (GetCapacityAssignedFreeSplit reads resource
    /// calendar capacity, not Day Planning Requested Hours - see codeunit 50662's own
    /// CalcAssignedSplit) and is carried entirely by AddCapacitySegmentSeries' own series instead.
    /// </summary>
    procedure AddRequestedAssignedSeries(var SeriesArray: JsonArray; Values: JsonArray; AssignedColor: Text)
    begin
        AddSeries(SeriesArray, RequestedAssignedSeriesNameLbl, Values, AssignedColor, '');
    end;

    /// <summary>
    /// Appends one SKILL's own "Unassigned" segment series - the portion of that skill's
    /// Requested Hours still without an Assigned Resource, stacked directly on top of the shared
    /// Assigned series (AddRequestedAssignedSeries, declared first so it sits at the bottom) in
    /// that same skill's own colour (the exact same GetSkillBarColor(SkillCode, PaletteIndex)
    /// value the caller already used for that row's "colors"/legend-swatch entry, so the swatch
    /// and this visible top segment always match - same colour continuity CAPACITY's own legend
    /// swatch/segment colours already have). Values must be 0 everywhere except this skill's own
    /// category index - one dedicated series per skill, unlike the shared Assigned series above,
    /// precisely because this colour DOES vary per skill.
    /// </summary>
    procedure AddSkillUnassignedSeries(var SeriesArray: JsonArray; SkillCode: Code[10]; Values: JsonArray; UnassignedColor: Text)
    begin
        AddSeries(SeriesArray, StrSubstNo(SkillUnassignedSeriesNameLbl, SkillCode), Values, UnassignedColor, '');
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
        SkillCapacityAnalysisMgtWeekly: Codeunit "Skill Capacity Analysis Mgt.";
        CapacitySkillCodeTok: Label 'CAPACITY', Locked = true;
        CapacityDescriptionTxt: Label 'Capacity';
        // Must stay text-identical to codeunit 50662's own AssInternalSeriesNameLbl/
        // AssExternalSeriesNameLbl/CapInternalSeriesNameLbl/CapExternalSeriesNameLbl - see
        // AddCapacitySegmentSeries's own doc comment for why these aren't fetched from that
        // codeunit directly (only its colour tokens are - series names are cosmetic legend/
        // right-click-menu text, not a "must never drift" numeric value).
        AssInternalSeriesNameLbl: Label 'Assigned Capacity - Internal';
        AssExternalSeriesNameLbl: Label 'Assigned Capacity - External';
        CapInternalSeriesNameLbl: Label 'Free Capacity - Internal';
        CapExternalSeriesNameLbl: Label 'Free Capacity - External';
        // Skill-bar Assigned/Unassigned series names - see AddRequestedAssignedSeries/
        // AddSkillUnassignedSeries's own doc comments for why Assigned is one shared series but
        // Unassigned is one per skill.
        RequestedAssignedSeriesNameLbl: Label 'Requested - Assigned';
        SkillUnassignedSeriesNameLbl: Label '%1 - Unassigned', Comment = '%1 = Skill Code';
}
