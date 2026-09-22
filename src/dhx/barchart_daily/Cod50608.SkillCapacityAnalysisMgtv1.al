codeunit 50608 "SkillCapacityAnalysisMgt.v1"
{
    /// <summary>
    /// Aggregates Day Planning requested hours per Skill Code, for the "Requested vs Capacity
    /// Daily" chart family (pages 50661/50681/50707).
    ///
    /// Requested Hours are grouped by the Day Planning line's own "Skill" field. One buffer row
    /// is produced per "Skill Code" MASTER record (optionally narrowed by SkillCodeFilter to a
    /// single one), not merely per skill code that happens to appear on a filtered Day Planning
    /// line - so a skill with zero matching lines still shows up, at 0, instead of silently
    /// disappearing from the chart/factbox.
    ///
    /// REDESIGN (2026-09-22): the chart used to render one bar per Skill Code MASTER record plus a
    /// single synthetic "CAPACITY" aggregate bar (company-wide, skill-agnostic, summed straight
    /// from "Res. Capacity Entry"). That synthetic row is gone. Every skill now gets a
    /// Capacity/Requested ("C"/"R") BAR PAIR of its own, mirroring src/dhx/barchart_weekly's own
    /// per-day C/R pair shape (see codeunit 50662's BuildDayCapacityChartData) - grouped by Skill
    /// Code here instead of by weekday. The "R" bar is unchanged in substance (that skill's
    /// Requested Hours, split into a shared "Requested - Assigned" bottom segment and that skill's
    /// own "Unassigned" top segment - see BuildSkillAssignedUnassignedSplit/
    /// AddRequestedAssignedSeries/AddSkillUnassignedSeries). The "C" bar is new: per the user's own
    /// mockup annotation, "the capacity bar is per respective resource (not skill)" - each skill's
    /// own C bar shows the SAME 4-segment Assigned Capacity/Free Capacity Internal/External
    /// (Mandatory)/External split codeunit 50662's weekly chart shows, scoped to only the
    /// resources who hold that skill (via the "Resource Skill" table) instead of every resource
    /// company-wide - see GetSkillCapacityAssignedFreeSplit below. A resource holding multiple
    /// skills legitimately contributes to each of those skills' own C bars; that is expected, not
    /// double-counting to avoid.
    ///
    /// This buffer (BuildSkillBuffer) itself still only carries the flat per-skill "Requested
    /// Hours" total feeding the factbox list (page 50661) - the C/R bar-pair JSON is assembled
    /// separately in each page's own RefreshChart (see that procedure's own doc comment for the
    /// exact category/series shape), reusing this buffer purely to enumerate "every configured
    /// Skill Code, even at 0" and each one's flat Requested Hours total, same as before.
    /// </summary>

    /// <summary>
    /// Builds the per-skill Requested Hours buffer for the supplied filters (feeds page 50661's
    /// factbox list AND is walked again by each page's own RefreshChart to enumerate skills for
    /// the chart). All filter parameters are optional; blank / 0D means "no filter".
    /// </summary>
    procedure BuildSkillBuffer(var Buffer: Record "Skill Req. vs Capacity Buffer" temporary; ResourceNoFilter: Code[20]; DateFromFilter: Date; DateToFilter: Date; SkillCodeFilter: Code[10])
    var
        DayPlanning: Record "Day Planning";
        SkillCodeRec: Record "Skill Code";
        RequestedHoursPerSkill: Dictionary of [Code[10], Decimal];
        AssignedHoursPerSkill: Dictionary of [Code[10], Decimal];
        UnassignedHoursPerSkill: Dictionary of [Code[10], Decimal];
        SkillCode: Code[10];
        AssignedInternal: Decimal;
        AssignedExternal: Decimal;
        CapacityInternal: Decimal;
        CapacityExternal: Decimal;
        CapacityExternalMandatory: Decimal;
    begin
        Buffer.Reset();
        Buffer.DeleteAll();

        ApplyDayPlanningFilters(DayPlanning, ResourceNoFilter, DateFromFilter, DateToFilter, SkillCodeFilter);

        if DayPlanning.FindSet() then
            repeat
                // Requested Hours belong to the skill recorded on the line itself.
                AddToTotals(RequestedHoursPerSkill, CopyStr(DayPlanning.Skill, 1, MaxStrLen(SkillCode)), DayPlanning."Requested Hours");
            until DayPlanning.Next() = 0;

        // Same "Assigned Hours" split the chart's own "R" bar (AddRequestedAssignedSeries) uses -
        // computed once here (not per row below) so every skill's buffer line reuses one shared
        // pass, matching this procedure's own single-pass/Dictionary convention.
        BuildSkillAssignedUnassignedSplit(ResourceNoFilter, DateFromFilter, DateToFilter, AssignedHoursPerSkill, UnassignedHoursPerSkill);

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
                // Same per-skill-resource-set capacity split the chart's own "C" bar uses
                // (GetSkillCapacityAssignedFreeSplit forwards to codeunit 50662's shared
                // GDayPlanningBuf/GResCapacityBuf temp buffers, already loaded for this exact date
                // range by the time each page's own RefreshChart calls it again right after this
                // procedure - so this is a cheap Dictionary lookup, not a second physical scan).
                GetSkillCapacityAssignedFreeSplit(SkillCode, DateFromFilter, DateToFilter, AssignedInternal, AssignedExternal, CapacityInternal, CapacityExternal, CapacityExternalMandatory);
                InsertBufferLine(
                    Buffer, SkillCode, GetTotal(RequestedHoursPerSkill, SkillCode),
                    AssignedInternal + AssignedExternal,
                    CapacityInternal + CapacityExternal + CapacityExternalMandatory,
                    GetTotal(AssignedHoursPerSkill, SkillCode));
            until SkillCodeRec.Next() = 0;

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

    local procedure InsertBufferLine(var Buffer: Record "Skill Req. vs Capacity Buffer" temporary; SkillCode: Code[10]; RequestedHours: Decimal; CapacityAssigned: Decimal; CapacityFree: Decimal; AssignedHours: Decimal)
    begin
        Buffer.Init();
        Buffer."No." := SkillCode;
        Buffer."Requested Hours" := RequestedHours;
        Buffer."Capacity Assigned" := CapacityAssigned;
        Buffer."Capacity Free" := CapacityFree;
        Buffer."Assigned Hours" := AssignedHours;
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
    /// codeunit's GetSkillBarColor for the actual "Bar Color"-override/5-colour-palette logic, now
    /// the single authoritative copy shared with codeunit 50662's own GetSkillSeriesColor twin.
    /// </summary>
    procedure GetSkillBarColor(SkillCode: Code[10]; PaletteIndex: Integer): Text
    var
        ColorConstants: Codeunit "Visual Default Settings";
    begin
        exit(ColorConstants.GetSkillBarColor(SkillCode, PaletteIndex));
    end;

    /// <summary>
    /// Resolves a chart segment back to the real "Day Planning"/"Res. Capacity Entry" records it
    /// was built from, and opens the matching standard list page pre-filtered to exactly that
    /// record set. Called from page 50681/50707's OnShowSegmentData usercontrol trigger, itself
    /// fired by wrapper.js's right-click "Show Data" context menu on either:
    ///   - a single BAR SEGMENT (WholeChart = false) - SegmentId is that bar's own category text,
    ///     "&lt;SkillCode&gt;|Capacity" or "&lt;SkillCode&gt;|Requested" (CategoryDelimiterTok-joined,
    ///     matching the exact category string each page's own RefreshChart builds), split back
    ///     into SkillCode + bar-type text here. A "Requested" bar click keeps the pre-existing
    ///     ShowSkillSegment behaviour (that skill's own Day Planning rows). A "Capacity" bar click
    ///     opens "Res. Capacity Entries" for that skill's OWN resource set instead of a
    ///     company-wide total (ShowSkillCapacitySegment - "Resource Skill" table membership, per
    ///     the user's own mockup annotation "the capacity bar is per respective resource (not
    ///     skill)" - see GetSkillCapacityAssignedFreeSplit's own doc comment).
    ///   - a LEGEND entry (WholeChart = true) - SegmentId is that series' own name (one of the 4
    ///     fixed Capacity segment name Labels below, the shared RequestedAssignedSeriesNameLbl, or
    ///     a per-skill "&lt;Skill&gt; - Unassigned" name), matching codeunit 50662's own
    ///     series-driven legend convention (ported into wrapper.js alongside this C/R bar-pair
    ///     redesign). A Requested-side series broadens to every skill's Day Planning rows
    ///     (ShowAllSkillsSegment, unchanged from before this redesign). A Capacity-side series
    ///     (IsCapacitySeriesName) broadens to every resource's Res. Capacity Entries for the
    ///     period (ShowAllCapacitySegment) - the closest sensible "whole chart" analog now that
    ///     Capacity has no single company-wide bar of its own to broaden from.
    /// This chart has no per-day breakdown at all - every bar already aggregates the whole
    /// displayed period - so DateFromFilter/DateToFilter are simply the page's own currently
    /// displayed period (always a concrete range, never blank), passed straight through.
    /// </summary>
    procedure ShowSegmentData(SegmentId: Text; WholeChart: Boolean; ResourceNoFilter: Code[20]; DateFromFilter: Date; DateToFilter: Date)
    var
        SkillCode: Code[10];
        SkillCodeText: Text;
        BarTypeText: Text;
        DelimPos: Integer;
    begin
        if WholeChart then begin
            if IsCapacitySeriesName(SegmentId) then
                ShowAllCapacitySegment(ResourceNoFilter, DateFromFilter, DateToFilter)
            else
                ShowAllSkillsSegment(ResourceNoFilter, DateFromFilter, DateToFilter);
            exit;
        end;

        DelimPos := StrPos(SegmentId, CategoryDelimiterTok);
        if DelimPos = 0 then
            exit; // malformed/stale click payload - nothing sane to open.

        SkillCodeText := CopyStr(SegmentId, 1, DelimPos - 1);
        SkillCode := CopyStr(SkillCodeText, 1, MaxStrLen(SkillCode));
        BarTypeText := CopyStr(SegmentId, DelimPos + 1);

        if BarTypeText = CapacityCategoryLbl then
            ShowSkillCapacitySegment(SkillCode, ResourceNoFilter, DateFromFilter, DateToFilter)
        else
            ShowSkillSegment(SkillCode, ResourceNoFilter, DateFromFilter, DateToFilter);
    end;

    /// <summary>
    /// True when SegmentId is one of the 4 fixed Capacity-bar segment names, as opposed to the
    /// shared "Requested - Assigned" series or a per-skill "&lt;Skill&gt; - Unassigned" series -
    /// used by ShowSegmentData to pick which "whole chart" drilldown a legend click broadens to.
    /// </summary>
    local procedure IsCapacitySeriesName(SegmentId: Text): Boolean
    begin
        exit((SegmentId = AssignedCapacitySeriesNameLbl) or (SegmentId = CapInternalSeriesNameLbl) or (SegmentId = CapExternalSeriesNameLbl) or (SegmentId = CapExternalMandatorySeriesNameLbl));
    end;

    /// <summary>
    /// Drilldown for a single skill's "R" (Requested) bar - unchanged from before this redesign:
    /// that skill's own Day Planning rows for the current Resource No./period filters.
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
    /// Drilldown for a single skill's "C" (Capacity) bar - opens "Res. Capacity Entries" for the
    /// period, filtered to the resource set that holds SkillCode (via the "Resource Skill" table),
    /// further narrowed by ResourceNoFilter when set. Replaces the old company-wide
    /// ShowCapacitySegment now that the synthetic CAPACITY bar/marker is gone - see this
    /// codeunit's own header doc comment.
    /// </summary>
    local procedure ShowSkillCapacitySegment(SkillCode: Code[10]; ResourceNoFilter: Code[20]; DateFromFilter: Date; DateToFilter: Date)
    var
        ResCapacityEntry: Record "Res. Capacity Entry";
        ResourceSkill: Record "Resource Skill";
        ResourceNoFilterText: Text;
    begin
        ResourceSkill.Reset();
        ResourceSkill.SetRange(Type, ResourceSkill.Type::Resource);
        ResourceSkill.SetRange("Skill Code", SkillCode);
        if ResourceNoFilter <> '' then
            ResourceSkill.SetRange("No.", ResourceNoFilter);
        ResourceSkill.SetLoadFields("No.");
        if ResourceSkill.FindSet() then
            repeat
                if ResourceNoFilterText = '' then
                    ResourceNoFilterText := ResourceSkill."No."
                else
                    ResourceNoFilterText += '|' + ResourceSkill."No.";
            until ResourceSkill.Next() = 0;

        if ResourceNoFilterText = '' then begin
            Message(NoMatchingDataMsg);
            exit;
        end;

        ResCapacityEntry.Reset();
        ResCapacityEntry.SetFilter("Resource No.", ResourceNoFilterText);
        ResCapacityEntry.SetRange(Date, DateFromFilter, DateToFilter);
        Page.Run(Page::"Res. Capacity Entries", ResCapacityEntry);
    end;

    /// <summary>
    /// Drilldown for a click on any of the 4 Capacity-segment LEGEND entries (WholeChart = true) -
    /// broadens to every resource's Res. Capacity Entries for the period/Resource No. filter, the
    /// closest "whole chart" analog to a single skill's own C bar now that there is no
    /// company-wide CAPACITY bar to broaden from.
    /// </summary>
    local procedure ShowAllCapacitySegment(ResourceNoFilter: Code[20]; DateFromFilter: Date; DateToFilter: Date)
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
    /// Drilldown for the Requested-side legend entries (WholeChart = true) - see ShowSegmentData's
    /// own doc comment for why this is the chosen "whole" analog. A plain SetFilter(Skill,
    /// '&lt;&gt;%1', '') suffices (no resource classification/Mark() idiom needed, unlike the live
    /// barchart's Internal/External segments) since Skill is a plain Day Planning field.
    /// Unchanged from before this redesign.
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

    /// <summary>
    /// Returns SkillCode's own resource-scoped Assigned/Free Capacity split, Internal/External/
    /// External-Mandatory, for that skill's "C" bar - the resources contributing are only those
    /// holding SkillCode (via "Resource Skill"), not every resource company-wide. Thin forward to
    /// Codeunit "Skill Capacity Analysis Mgt." (50662, the Weekly chart's own management codeunit)
    /// - see that codeunit's GetSkillCapacitySplitForRangeWithMandatory for the actual
    /// per-skill-resource-set computation - rather than reimplementing the Internal/External/
    /// Mandatory classification here, so the two charts' numbers can never drift apart. Replaces
    /// the old company-wide GetCapacityAssignedFreeSplit (removed 2026-09-22 alongside the
    /// synthetic CAPACITY bar it fed - see this codeunit's own header doc comment); its only 2
    /// callers (pages 50681/50707) now call this per-skill procedure once per skill instead.
    /// </summary>
    procedure GetSkillCapacityAssignedFreeSplit(SkillCode: Code[10]; PlanDateFrom: Date; PlanDateTo: Date; var AssignedInternal: Decimal; var AssignedExternal: Decimal; var CapacityInternal: Decimal; var CapacityExternal: Decimal; var CapacityExternalMandatory: Decimal)
    begin
        SkillCapacityAnalysisMgtWeekly.GetSkillCapacitySplitForRangeWithMandatory(SkillCode, PlanDateFrom, PlanDateTo, AssignedInternal, AssignedExternal, CapacityInternal, CapacityExternal, CapacityExternalMandatory);
    end;

    /// <summary>
    /// Returns the same Assigned/Free-Capacity colour tokens src/dhx/barchart_weekly's stacked
    /// chart uses (green Assigned, blue Free Capacity, red External border) so every skill's own
    /// "C" bar's stacked segments always match Weekly's exact tokens, never a locally hardcoded
    /// copy. Forwards through Codeunit "Skill Capacity Analysis Mgt." (50662) rather than calling
    /// codeunit "Color Constants Opti." (50609) directly - 50662's own GetCapacitySegmentColors is
    /// itself now just a thin forward to 50609, so the resolved values are identical either way.
    /// </summary>
    procedure GetCapacitySegmentColors(var AssignedColor: Text; var CapacityColor: Text; var ExternalBorderColor: Text)
    begin
        SkillCapacityAnalysisMgtWeekly.GetCapacitySegmentColors(AssignedColor, CapacityColor, ExternalBorderColor);
    end;

    /// <summary>
    /// Returns the fill colour for the "Free Capacity - External (Mandatory)" segment. Forwards
    /// through Codeunit "Skill Capacity Analysis Mgt." (50662) rather than calling codeunit
    /// "Visual Default Settings" (50609) directly, same convention as GetCapacitySegmentColors
    /// above.
    /// </summary>
    procedure GetCapacityMandatoryColor(): Text
    begin
        exit(SkillCapacityAnalysisMgtWeekly.GetCapacityMandatoryColor());
    end;

    /// <summary>
    /// Appends the "C" bar's 4 stacked segments to SeriesArray, matching wrapper.js's series JSON
    /// contract (name/values/color/[border]/stacked). Stacking order - Assigned, then Free
    /// Internal, then Free External Mandatory, then Free External non-mandatory declared LAST -
    /// puts the red-bordered non-mandatory segment on top of the stack with nothing above it, same
    /// reasoning as codeunit 50662's own BuildDayCapacityChartData: the purpose is for the planner
    /// to see there is external resource that is not mandatory-scheduled and needs attention,
    /// hence it must be visible at the top of the bar.
    /// Each *Values array must already be index-aligned with the chart's CategoriesArray (0 at
    /// every "R" slot, the real split only at that same skill's own "C" slot - see each page's own
    /// RefreshChart). Colours are passed in (not re-fetched here) so a caller only calls
    /// GetCapacitySegmentColors/GetCapacityMandatoryColor once regardless of how many skills it
    /// loops over.
    /// </summary>
    procedure AddCapacitySegmentSeries(var SeriesArray: JsonArray; AssignedValues: JsonArray; CapInternalValues: JsonArray; CapExternalMandatoryValues: JsonArray; CapExternalValues: JsonArray; AssignedColor: Text; CapacityColor: Text; CapacityMandatoryColor: Text; ExternalBorderColor: Text)
    begin
        AddSeries(SeriesArray, AssignedCapacitySeriesNameLbl, AssignedValues, AssignedColor, '', '');
        AddSeries(SeriesArray, CapInternalSeriesNameLbl, CapInternalValues, CapacityColor, '', '');
        AddSeries(SeriesArray, CapExternalMandatorySeriesNameLbl, CapExternalMandatoryValues, CapacityMandatoryColor, '', '');
        AddSeries(SeriesArray, CapExternalSeriesNameLbl, CapExternalValues, CapacityColor, ExternalBorderColor, '');
    end;

    /// <summary>
    /// Appends one series object (name/values/color/[border]/[fontColor]/stacked) to SeriesArray,
    /// matching the exact JSON contract wrapper.js's RenderChart expects (same shape codeunit
    /// 50662's own AddChartSeries builds for the Weekly chart). BorderHex/FontColorHex may be
    /// blank to omit the optional "border"/"fontColor" keys. FontColorHex (added 2026-09-22
    /// alongside the series-driven legend port from codeunit 50662's wrapper.js) is consumed by
    /// wrapper.js's ApplyLegendSwatchBorders for each per-skill series' own legend TEXT colour -
    /// only ever passed for the per-skill Unassigned series below, never for the shared/Capacity
    /// segments (which have no Skill of their own).
    /// </summary>
    local procedure AddSeries(var SeriesArray: JsonArray; SeriesName: Text; Values: JsonArray; ColorHex: Text; BorderHex: Text; FontColorHex: Text)
    var
        SeriesObj: JsonObject;
    begin
        SeriesObj.Add('name', SeriesName);
        SeriesObj.Add('values', Values);
        SeriesObj.Add('color', ColorHex);
        if BorderHex <> '' then
            SeriesObj.Add('border', BorderHex);
        if FontColorHex <> '' then
            SeriesObj.Add('fontColor', FontColorHex);
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
    /// CalcUnassignedSkillRequestedSplit's own row population exactly). This feeds ONLY the "R"
    /// bar's own 2-segment split - the "C" bar's own Assigned/Free figures come from a completely
    /// different source (GetSkillCapacityAssignedFreeSplit, true resource calendar capacity) and
    /// only coincidentally share the same green AssignedColor token, never the same numbers.
    ///
    /// One bulk pass (not one query per skill) - mirrors BuildSkillBuffer's own single-pass/
    /// Dictionary-accumulation shape (AddToTotals), just accumulating into two Dictionaries
    /// instead of one. Callers pass the SAME (ResourceNoFilter, DateFromFilter, DateToFilter)
    /// their own BuildSkillBuffer call used, or the two totals will disagree.
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
    /// skill's "R" bar stack (green, same AssignedColor token as GetCapacitySegmentColors/the "C"
    /// bar's own Assigned segments): each skill's own Requested Hours total is split into how much
    /// of it already has an Assigned Resource (this series) vs how much is still Unassigned (see
    /// AddSkillUnassignedSeries). ONE shared series across every skill (not one per skill) because
    /// the Assigned colour never varies by skill - only the Unassigned segment on top does, which
    /// is why that one needs its own series per skill. Values must be 0 at every "C" slot - that
    /// slot's own Assigned figure comes from a different, unrelated source
    /// (GetSkillCapacityAssignedFreeSplit) and is carried entirely by AddCapacitySegmentSeries' own
    /// series instead.
    /// </summary>
    procedure AddRequestedAssignedSeries(var SeriesArray: JsonArray; Values: JsonArray; AssignedColor: Text)
    begin
        AddSeries(SeriesArray, RequestedAssignedSeriesNameLbl, Values, AssignedColor, '', '');
    end;

    /// <summary>
    /// Appends one SKILL's own "Unassigned" segment series - the portion of that skill's
    /// Requested Hours still without an Assigned Resource, stacked directly on top of the shared
    /// Assigned series (AddRequestedAssignedSeries, declared first so it sits at the bottom) in
    /// that same skill's own colour (the exact same GetSkillBarColor(SkillCode, PaletteIndex)
    /// value the caller already used for that skill's group-row/legend colouring, so everything
    /// stays visually consistent). Values must be 0 everywhere except this skill's own "R" slot -
    /// one dedicated series per skill, unlike the shared Assigned series above, precisely because
    /// this colour DOES vary per skill.
    ///
    /// BorderColor is that same skill's own resolved border colour (codeunit 50609 "Visual
    /// Default Settings"' GetSkillBorderColor, via the caller). Pass '' to omit (no visible
    /// border), same convention as AddRequestedAssignedSeries above. FontColorHex (added
    /// 2026-09-22, codeunit 50609's GetSkillFontColor via the caller) is this skill's own legend
    /// TEXT colour, applied by wrapper.js's ApplyLegendSwatchBorders to this series' own de-duped
    /// legend entry - see AddSeries' own doc comment.
    /// </summary>
    procedure AddSkillUnassignedSeries(var SeriesArray: JsonArray; SkillCode: Code[10]; Values: JsonArray; UnassignedColor: Text; BorderColor: Text; FontColorHex: Text)
    begin
        AddSeries(SeriesArray, StrSubstNo(SkillUnassignedSeriesNameLbl, SkillCode), Values, UnassignedColor, BorderColor, FontColorHex);
    end;

    var
        SkillCapacityAnalysisMgtWeekly: Codeunit "Skill Capacity Analysis Mgt.";
        // Matches codeunit 50662's own CategoryDelimiterTok/FreeCapacityCategoryLbl text-for-text,
        // and each page's own independently-declared copies (CategoryDelimiterTok/
        // CapacityCategoryLbl/RequestedCategoryLbl in pages 50681/50707 - see their own RefreshChart)
        // - keep in sync if it ever changes. Each page's own RefreshChart builds category strings
        // as "<SkillCode>" + CategoryDelimiterTok + ("Capacity"/"Requested"), and ShowSegmentData
        // above splits them back apart the same way; only the "Capacity" side needs its own copy
        // here (BarTypeText <> CapacityCategoryLbl is treated as "Requested").
        CategoryDelimiterTok: Label '|', Locked = true;
        CapacityCategoryLbl: Label 'Capacity';
        AssignedCapacitySeriesNameLbl: Label 'Assigned Capacity';
        CapInternalSeriesNameLbl: Label 'Free Capacity - Internal';
        CapExternalSeriesNameLbl: Label 'Free Capacity - External';
        CapExternalMandatorySeriesNameLbl: Label 'Free Capacity - External (Mandatory)';
        // Skill-bar Assigned/Unassigned series names - see AddRequestedAssignedSeries/
        // AddSkillUnassignedSeries's own doc comments for why Assigned is one shared series but
        // Unassigned is one per skill.
        RequestedAssignedSeriesNameLbl: Label 'Requested - Assigned';
        SkillUnassignedSeriesNameLbl: Label '%1 - Unassigned', Comment = '%1 = Skill Code';
        NoMatchingDataMsg: Label 'No records match this chart segment.';
}
