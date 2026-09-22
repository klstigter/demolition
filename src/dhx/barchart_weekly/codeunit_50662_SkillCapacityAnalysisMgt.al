codeunit 50662 "Skill Capacity Analysis Mgt."
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

    local procedure CalcFiltersDayPlanning(var DayPlanning: Record "Day Planning"; DateFilter: Date)
    begin
        DayPlanning.Reset();
        DayPlanning.SetCurrentKey("Plan Date", Skill, "Assigned Resource No.");
        DayPlanning.SetRange(Assigned, false);
        DayPlanning.SetRange("Plan Date", DateFilter);
    end;

    local procedure InsertBufferLine(var Buffer: Record "Skill Req. vs Capacity Buffer" temporary; BarType: Enum "Day Capacity Chart Bar Type"; Code: Code[20]; WkdayNo: Integer; Hours: Decimal)
    begin
        Buffer.Init();
        Buffer."Bar Type" := BarType;
        Buffer."No." := Code;
        Buffer."Week Day No." := WkdayNo;
        Buffer."Segment" := BuildSegmentLabel(BarType, Code);
        Buffer."Requested Hours" := Hours;
        Buffer.Insert();
    end;

    /// <summary>
    /// Builds a self-describing "Cap. X"/"Req. X" label for the "Skill Req. vs Capacity Buffer"
    /// table's "Segment" field - "No." alone is ambiguous once exported flat (e.g. to Excel):
    /// 'Assigned' is inserted under BOTH bar types (see CalcFreeCapacity) and, without the hidden
    /// "Bar Type" column, reads as an unexplained duplicate; a blank Skill Code (an unassigned Day
    /// Planning line with no Skill set) reads as an unexplained blank row. Both are still shown -
    /// not dropped - just labelled clearly instead of relabelled away, matching this codeunit's
    /// broader "show at 0/blank rather than silently disappearing" approach elsewhere.
    /// </summary>
    local procedure BuildSegmentLabel(BarType: Enum "Day Capacity Chart Bar Type"; SkillCode: Code[20]): Text[30]
    var
        Prefix: Text[10];
        NameText: Text[20];
    begin
        case BarType of
            BarType::Capacity:
                Prefix := CapSegmentPrefixLbl;
            BarType::Requested:
                Prefix := ReqSegmentPrefixLbl;
        end;

        if SkillCode = '' then
            NameText := NoSkillSegmentLbl
        else
            NameText := SkillCode;

        exit(Prefix + NameText);
    end;



    /// <summary>
    /// Builds the JSON payload for the stacked "Capacity vs Requested" chart on page 50692,
    /// ready to hand straight to CurrPage.DhxBarChart.LoadData. Covers the full Monday..Sunday
    /// period (PeriodStartDate is expected to already be a Monday, same convention as the page's own
    /// PeriodStartDate) - two categories per weekday ("<Wkd>|Capacity" / "<Wkd>|Requested",
    /// left-to-right, Capacity first - still unique per bar for DHTMLX's positioning, but
    /// wrapper.js's textTemplate strips the "<Wkd>|" prefix for display), with the weekday name
    /// ALSO carried separately in the top-level "dayLabels" array (one entry per day, same
    /// order) so wrapper.js can render it as its own merged row spanning that day's 2 bars.
    /// Each category is a stack of series segments, bottom to top: "Assigned Capacity" (a single
    /// combined series - see below), then "Free Capacity - Internal", then "Free Capacity -
    /// External (Mandatory)", then "Free Capacity - External" (Capacity bar only - see
    /// CalcCapacitySplit; the non-mandatory External segment is declared LAST/topmost on purpose -
    /// see the Mandatory-split note below - so its red border always sits on the bar's outer edge),
    /// then one internal/external pair per Skill Code
    /// that has at least one unassigned (Assigned = false) Day Planning row with nonzero Requested
    /// Hours somewhere in the period. The Free Capacity and skill segments are each declared as an
    /// internal/external SERIES PAIR (an "internal" series with plain fill/no border, then an
    /// "external" series with the same fill colour but a red border, so an external portion is
    /// visually provable at a glance; declared immediately after its own internal half so it
    /// stacks directly on top of it - wrapper.js stacking (suite.js's Stacker.dataReady)
    /// accumulates each series' baseline from the PREVIOUS series in declaration order). Each
    /// series has its own distinct series name, so each renders its own legend entry (wrapper.js's
    /// legend only collapses series that SHARE a name - see its own header comment - which now
    /// only happens among the internal/external halves of a given skill's segment pair, not here).
    /// Which BAR each segment is allowed to actually split on differs by segment:
    ///   - "Assigned Capacity": ALWAYS a single plain-coloured series carrying the combined
    ///                  (internal + external) total, on BOTH the Capacity and Requested bar - no
    ///                  Internal/External split, no border, exactly one legend entry. (This is a
    ///                  deliberate simplification vs. this procedure's own earlier behavior and vs.
    ///                  its range-generalized twin BuildDayCapacityChartDataForRange, which still
    ///                  keeps the Capacity bar's real internal/external split - see that
    ///                  procedure's own doc comment; do not port this change there.)
    ///   - "Free Capacity - Internal"/"Free Capacity - External"/"Free Capacity - External
    ///                  (Mandatory)": Capacity-bar-only, unchanged - see below.
    ///   - Skill segments: Requested-bar-only, and use the same collapse-to-a-combined-total
    ///                  convention as Assigned - the internal series gets the combined (internal +
    ///                  external) value for that skill/day, the external series is always 0.
    /// Net effect: the CAPACITY bar shows Assigned Capacity as one plain block plus its full
    /// Free Capacity Internal/External breakdown; the REQUESTED bar never shows an Internal/
    /// External distinction anywhere - every segment on it (Assigned, each skill) is a single
    /// plain-coloured block carrying a combined total (skill segments still via a paired
    /// always-0 "external" series for legend/stacking mechanics; Assigned Capacity has no such
    /// pair at all anymore).
    /// "Free Capacity - Internal"/"Free Capacity - External" are TRUE calendar capacity read
    /// directly from "Res. Capacity Entry" (matching the standard Resource Capacity Matrix page -
    /// see CalcCapacitySplit), net of that same day's Assigned Hours ("free" capacity), split
    /// purely by the capacity-holding resource's own "Is External" flag. They are named/coloured
    /// separately from the Assigned series (own colour, the "External" half gets the same
    /// red-border convention) and are ONLY ever nonzero on the Capacity bar (0 on the Requested
    /// bar) - so a Capacity bar's total height reads as Assigned + remaining free capacity for
    /// that day, independent of whatever Day Planning rows happen to exist yet (e.g. a day with
    /// real resource-calendar capacity but no Day Planning assignments yet still shows its full
    /// capacity, not near-zero).
    /// "Free Capacity - External" is itself further split by the capacity-holding resource's
    /// "Mandatory Schedulling" flag (2026-09-16, this chart only - see CalcCapacitySplit's own doc
    /// comment): "Free Capacity - External" keeps carrying only the NON-mandatory portion and its
    /// existing red border, while a separate "Free Capacity - External (Mandatory)" series carries
    /// the mandatory portion using its OWN configurable fill colour (Codeunit 50609's
    /// GetCapacityMandatoryColor, overridable via "Daily Optimizer Setup"."Free Capacity-Mandatory
    /// Color" - defaults to the same hex as regular Free Capacity today, but independently
    /// overridable) with NO border (plain, like Internal).
    /// Both stack on the Capacity bar exactly like the plain Internal/External split did before,
    /// except "Free Capacity - External (Mandatory)" is declared BEFORE (i.e. stacks below) the
    /// non-mandatory "Free Capacity - External" series, so the red-bordered non-mandatory segment
    /// always ends up topmost on the Capacity bar with nothing stacked above it.
    /// Skill segments (both halves) are only ever nonzero on the Requested bar (0 on the Capacity
    /// bar), and per the collapse above, only the internal half is ever actually nonzero there.
    ///
    /// DYNAMIC DAY INCLUSION: a weekday's 2 category slots (Capacity + Requested) are only added
    /// to "categories"/"dayLabels" - and that day's values only appended to every series' "values"
    /// list - when the day has ANY nonzero data across ANY segment (Assigned internal/external,
    /// free Capacity internal/external, or any active skill's requested internal/external), per
    /// DayHasAnyChartData. A day with zero everywhere (typically a non-working Saturday/Sunday,
    /// but the check is uniform across all 7 weekdays - it is not a weekend special case) is
    /// omitted entirely, not rendered as an empty/zero-height bar pair - this keeps the chart from
    /// wasting horizontal space on blank columns. All value lists stay index-aligned with
    /// "categories" by skipping the same days in the same order (see the IncludedDay array below).
    /// This ONLY affects this chart - BuildDayCapacityAuditBuffer deliberately keeps showing all 7
    /// days, including empty ones, for audit-trail completeness (see its own doc comment).
    /// wrapper.js's RenderChart/RenderDayGroupRow already build purely off the received arrays'
    /// actual lengths, so a shorter-than-7-day payload needs no frontend change.
    /// </summary>
    procedure BuildDayCapacityChartData(PeriodStartDate: Date) ChartDataJson: Text
    var
        ChartData: JsonObject;
        CategoriesArray: JsonArray;
        DayLabelsArray: JsonArray;
        DayIndicesArray: JsonArray;
        SeriesArray: JsonArray;
        AssignedValues: List of [Decimal];
        CapInternalValues: List of [Decimal];
        CapExternalValues: List of [Decimal];
        CapExternalMandatoryValues: List of [Decimal];
        SkillInternalValues: List of [Decimal];
        SkillExternalValues: List of [Decimal];
        ActiveSkillList: List of [Code[20]];
        OneDaySkillInternalValues: Dictionary of [Code[20], Decimal];
        OneDaySkillExternalValues: Dictionary of [Code[20], Decimal];
        AllDaySkillInternalValues: Dictionary of [Text, Decimal];
        AllDaySkillExternalValues: Dictionary of [Text, Decimal];
        IncludedDay: array[7] of Boolean;
        SkillCode: Code[20];
        WeekdayIndex: Integer;
        CurrDate: Date;
        AssInternalD: Decimal;
        AssExternalD: Decimal;
        CapInternalD: Decimal;
        CapExternalD: Decimal;
        CapExternalMandatoryD: Decimal;
        SkillPaletteIdx: Integer;
        AssignedColorHex: Text;
        CapacityColorHex: Text;
        ExternalBorderColorHex: Text;
        CapacityMandatoryColorHex: Text;
        ColorConstants: Codeunit "Visual Default Settings";
    begin
        EnsureDayPlanningBuffer(PeriodStartDate, PeriodStartDate + 6);

        BuildActiveSkillList(ActiveSkillList);

        // Each category is "<Wkd>|Capacity" / "<Wkd>|Requested" - still unique per bar (the
        // DHTMLX "text" scale positions each bar by looking up its own category value, so
        // duplicate values across different days would collapse those bars onto the same x-slot
        // - see wrapper.js's RenderChart comment) - but wrapper.js's textTemplate strips
        // everything up to and including the "|" for display, so the tick only ever shows
        // "Capacity"/"Requested". The weekday itself is ALSO carried separately in "dayLabels"
        // (one entry per day, same left-to-right order) so wrapper.js can render its own merged
        // row spanning that day's 2 bars, without parsing weekday text back out of a category.
        // Both arrays - and every series' values list below - only ever gain entries for a day
        // that DayHasAnyChartData finds nonzero (see this procedure's own doc comment); a
        // skipped day contributes no categories/dayLabels/values entries at all, not a zero pair.
        Clear(CategoriesArray);
        Clear(DayLabelsArray);
        Clear(DayIndicesArray);
        Clear(AssignedValues);
        Clear(CapInternalValues);
        Clear(CapExternalValues);
        Clear(CapExternalMandatoryValues);
        for WeekdayIndex := 1 to 7 do begin
            CurrDate := PeriodStartDate + (WeekdayIndex - 1);

            CalcDaySegments(CurrDate, ActiveSkillList, AssInternalD, AssExternalD, CapInternalD, CapExternalD, CapExternalMandatoryD, OneDaySkillInternalValues, OneDaySkillExternalValues);

            IncludedDay[WeekdayIndex] := DayHasAnyChartData(AssInternalD, AssExternalD, CapInternalD, CapExternalD, CapExternalMandatoryD, ActiveSkillList, OneDaySkillInternalValues, OneDaySkillExternalValues);
            if not IncludedDay[WeekdayIndex] then
                continue; // zero everywhere for this day - omit its category pair and every series value entirely.

            CategoriesArray.Add(FormatWeekdayShort(CurrDate) + CategoryDelimiterTok + FreeCapacityCategoryLbl);
            CategoriesArray.Add(FormatWeekdayShort(CurrDate) + CategoryDelimiterTok + RequestedCategoryLbl);
            DayLabelsArray.Add(FormatWeekdayShort(CurrDate));
            // Parallel to DayLabelsArray (same index, same "only included days" skipping) but
            // carries the raw 1..7 WeekdayIndex instead of display text - wrapper.js's right-click
            // "Show Data" handler (see ResolveBarSegmentFromEvent) needs this to hand a real day
            // back to ShowSegmentData, since a locale-formatted 3-letter weekday name is not a safe
            // round-trip key (FormatWeekdayShort uses "<Weekday Text,3>", which is locale-dependent).
            DayIndicesArray.Add(WeekdayIndex);

            // Page 50692's Assigned Capacity segment is ALWAYS a single combined (internal +
            // external) total on BOTH bar positions - no Internal/External split anywhere on this
            // chart (unlike BuildDayCapacityChartDataForRange's twin, which still keeps the
            // Capacity-bar split - see that procedure's own doc comment). One series, one legend
            // entry, plain AssignedColorHex fill, no border.
            AssignedValues.Add(AssInternalD + AssExternalD);
            AssignedValues.Add(AssInternalD + AssExternalD);

            // Free capacity (Internal/External) is a Capacity-bar-only concept - Capacity bar
            // value, then 0 for the Requested bar position (the mirror image of how skill
            // segments below are 0 on the Capacity bar position).
            CapInternalValues.Add(CapInternalD);
            CapInternalValues.Add(0);
            CapExternalValues.Add(CapExternalD);
            CapExternalValues.Add(0);
            CapExternalMandatoryValues.Add(CapExternalMandatoryD);
            CapExternalMandatoryValues.Add(0);

            // Stash this day's per-skill values (keyed by weekday+skill) so the per-skill series
            // loop below can reuse them instead of recomputing via CalcDaySegments again - AL has
            // no array-of-Dictionary type, so a single Dictionary keyed by a composite Text key
            // stands in for a per-weekday array of dictionaries. Only stashed for included days -
            // the per-skill loop below skips excluded days via IncludedDay and never looks these up.
            foreach SkillCode in ActiveSkillList do begin
                AllDaySkillInternalValues.Set(Format(WeekdayIndex) + '|' + SkillCode, OneDaySkillInternalValues.Get(SkillCode));
                AllDaySkillExternalValues.Set(Format(WeekdayIndex) + '|' + SkillCode, OneDaySkillExternalValues.Get(SkillCode));
            end;
        end;

        ColorConstants.GetCapacitySegmentColors(AssignedColorHex, CapacityColorHex, ExternalBorderColorHex);
        CapacityMandatoryColorHex := ColorConstants.GetCapacityMandatoryColor();
        AddChartSeries(SeriesArray, AssignedCapacitySeriesNameLbl, AssignedValues, AssignedColorHex, '', '');
        AddChartSeries(SeriesArray, CapInternalSeriesNameLbl, CapInternalValues, CapacityColorHex, '', '');
        AddChartSeries(SeriesArray, CapExternalMandatorySeriesNameLbl, CapExternalMandatoryValues, CapacityMandatoryColorHex, '', '');
        AddChartSeries(SeriesArray, CapExternalSeriesNameLbl, CapExternalValues, CapacityColorHex, ExternalBorderColorHex, '');

        SkillPaletteIdx := 0;
        foreach SkillCode in ActiveSkillList do begin
            Clear(SkillInternalValues);
            Clear(SkillExternalValues);
            for WeekdayIndex := 1 to 7 do begin
                if not IncludedDay[WeekdayIndex] then
                    continue; // stays index-aligned with CategoriesArray - excluded days get no entry at all.

                SkillInternalValues.Add(0); // Capacity bar - skills never appear there.
                // Requested bar: collapse to a single plain total (no Internal/External
                // distinction) - the Internal series carries the combined value, the External
                // series is always 0.
                SkillInternalValues.Add(
                    AllDaySkillInternalValues.Get(Format(WeekdayIndex) + '|' + SkillCode) +
                    AllDaySkillExternalValues.Get(Format(WeekdayIndex) + '|' + SkillCode));
                SkillExternalValues.Add(0);
                SkillExternalValues.Add(0);
            end;
            // SkillInternalValues is the series that actually carries this skill's nonzero
            // values (the Requested bar's combined total - see the comment above) and is
            // declared FIRST, so it's the one that owns this skill's de-duped legend entry
            // (see wrapper.js's GetLegendOwnerIndexByLabel) - both its own bar border AND its
            // legend swatch border/text colour resolve from here. SkillExternalValues stays
            // 0 everywhere by design (see above), so its own border (unchanged, ExternalBorderColorHex)
            // never actually paints and it never owns a legend slot.
            AddChartSeries(SeriesArray, SkillCode, SkillInternalValues, GetSkillSeriesColor(SkillCode, SkillPaletteIdx), GetSkillSeriesBorderColor(SkillCode, SkillPaletteIdx), GetSkillSeriesFontColor(SkillCode));
            AddChartSeries(SeriesArray, SkillCode, SkillExternalValues, GetSkillSeriesColor(SkillCode, SkillPaletteIdx), ExternalBorderColorHex, '');
            SkillPaletteIdx += 1;
        end;

        ChartData.Add('categories', CategoriesArray);
        ChartData.Add('dayLabels', DayLabelsArray);
        ChartData.Add('dayIndices', DayIndicesArray);
        ChartData.Add('series', SeriesArray);
        ChartData.Add('barWidth', ColorConstants.GetWeeklyBarChartWidth());
        // Hover/tooltip popup colours for dhx.Chart's own built-in hover tooltip (shown when
        // hovering a bar) - codeunit 50609's GetTooltipBackgroundColor/GetTooltipFontColor,
        // forwarded through this codeunit's own ColorConstants alias. See
        // src/dhx/barchart_weekly/wrapper.js's RenderChart for how these two keys are applied.
        ChartData.Add('tooltipBg', ColorConstants.GetTooltipBackgroundColor());
        ChartData.Add('tooltipFont', ColorConstants.GetTooltipFontColor());
        ChartData.WriteTo(ChartDataJson);
    end;

    /// <summary>
    /// Range-generalized twin of BuildDayCapacityChartData for the Capacity Planning Overview
    /// add-in (page 50722, controladdin DHXCapacityPlanningOverviewAddin, codeunit 50604's
    /// CPO_BuildPlanningDataJson - Section 3) - identical JSON shape/keys, identical segment
    /// definitions (Assigned Internal/External, Free Capacity Internal/External, per-skill
    /// Internal/External pairs), and the identical Capacity-bar-keeps-split /
    /// Requested-bar-collapses-to-a-single-total rule (see that procedure's own doc comment for
    /// the full contract - unchanged here, not re-invented), but loops every calendar day in
    /// [StartDate, EndDate] instead of always a fixed Monday..Sunday week - a Work Order's own
    /// visible window is an arbitrary caller-supplied span, not a calendar week. Reuses
    /// EnsureDayPlanningBuffer/BuildActiveSkillList/CalcDaySegments/DayHasAnyChartData/
    /// AddChartSeries/the same color-resolution helpers as BuildDayCapacityChartData - no new
    /// categorization invented for this caller. DayIndex here is 1-based across the whole
    /// [StartDate,EndDate] span (not a 1..7 weekday number) - "dayIndices" in the returned JSON
    /// carries that same 1-based span index, so a caller that needs the real Date back must
    /// re-derive it as StartDate + (dayIndex - 1), mirroring how BuildDayCapacityChartData's own
    /// "dayIndices" is a raw 1..7 weekday index rather than a formatted date.
    /// </summary>
    procedure BuildDayCapacityChartDataForRange(StartDate: Date; EndDate: Date) ChartDataJson: Text
    var
        ChartData: JsonObject;
        CategoriesArray: JsonArray;
        DayLabelsArray: JsonArray;
        DayIndicesArray: JsonArray;
        SeriesArray: JsonArray;
        AssInternalValues: List of [Decimal];
        AssExternalValues: List of [Decimal];
        CapInternalValues: List of [Decimal];
        CapExternalValues: List of [Decimal];
        SkillInternalValues: List of [Decimal];
        SkillExternalValues: List of [Decimal];
        ActiveSkillList: List of [Code[20]];
        OneDaySkillInternalValues: Dictionary of [Code[20], Decimal];
        OneDaySkillExternalValues: Dictionary of [Code[20], Decimal];
        AllDaySkillInternalValues: Dictionary of [Text, Decimal];
        AllDaySkillExternalValues: Dictionary of [Text, Decimal];
        IncludedDay: List of [Boolean];
        SkillCode: Code[20];
        DayIndex: Integer;
        DayCount: Integer;
        CurrDate: Date;
        AssInternalD: Decimal;
        AssExternalD: Decimal;
        CapInternalD: Decimal;
        CapExternalD: Decimal;
        DummyCapExternalMandatoryD: Decimal;
        SkillPaletteIdx: Integer;
        AssignedColorHex: Text;
        CapacityColorHex: Text;
        ExternalBorderColorHex: Text;
        ColorConstants: Codeunit "Visual Default Settings";
        IsIncluded: Boolean;
    begin
        Clear(ChartDataJson);
        if EndDate < StartDate then
            exit;

        EnsureDayPlanningBuffer(StartDate, EndDate);

        BuildActiveSkillList(ActiveSkillList);

        Clear(CategoriesArray);
        Clear(DayLabelsArray);
        Clear(DayIndicesArray);
        Clear(AssInternalValues);
        Clear(AssExternalValues);
        Clear(CapInternalValues);
        Clear(CapExternalValues);
        Clear(IncludedDay);

        DayCount := EndDate - StartDate + 1;
        CurrDate := StartDate;
        for DayIndex := 1 to DayCount do begin
            CalcDaySegments(CurrDate, ActiveSkillList, AssInternalD, AssExternalD, CapInternalD, CapExternalD, DummyCapExternalMandatoryD, OneDaySkillInternalValues, OneDaySkillExternalValues);

            IsIncluded := DayHasAnyChartData(AssInternalD, AssExternalD, CapInternalD, CapExternalD, DummyCapExternalMandatoryD, ActiveSkillList, OneDaySkillInternalValues, OneDaySkillExternalValues);
            IncludedDay.Add(IsIncluded);
            if IsIncluded then begin
                CategoriesArray.Add(FormatWeekdayShort(CurrDate) + CategoryDelimiterTok + FreeCapacityCategoryLbl);
                CategoriesArray.Add(FormatWeekdayShort(CurrDate) + CategoryDelimiterTok + RequestedCategoryLbl);
                DayLabelsArray.Add(FormatWeekdayShort(CurrDate));
                DayIndicesArray.Add(DayIndex);

                AssInternalValues.Add(AssInternalD);
                AssInternalValues.Add(AssInternalD + AssExternalD);
                AssExternalValues.Add(AssExternalD);
                AssExternalValues.Add(0);

                CapInternalValues.Add(CapInternalD);
                CapInternalValues.Add(0);
                CapExternalValues.Add(CapExternalD);
                CapExternalValues.Add(0);

                foreach SkillCode in ActiveSkillList do begin
                    AllDaySkillInternalValues.Set(Format(DayIndex) + '|' + SkillCode, OneDaySkillInternalValues.Get(SkillCode));
                    AllDaySkillExternalValues.Set(Format(DayIndex) + '|' + SkillCode, OneDaySkillExternalValues.Get(SkillCode));
                end;
            end;

            CurrDate += 1;
        end;

        ColorConstants.GetCapacitySegmentColors(AssignedColorHex, CapacityColorHex, ExternalBorderColorHex);
        AddChartSeries(SeriesArray, AssInternalSeriesNameLbl, AssInternalValues, AssignedColorHex, '', '');
        AddChartSeries(SeriesArray, AssExternalSeriesNameLbl, AssExternalValues, AssignedColorHex, ExternalBorderColorHex, '');
        AddChartSeries(SeriesArray, CapInternalSeriesNameLbl, CapInternalValues, CapacityColorHex, '', '');
        AddChartSeries(SeriesArray, CapExternalSeriesNameLbl, CapExternalValues, CapacityColorHex, ExternalBorderColorHex, '');

        SkillPaletteIdx := 0;
        foreach SkillCode in ActiveSkillList do begin
            Clear(SkillInternalValues);
            Clear(SkillExternalValues);
            for DayIndex := 1 to DayCount do begin
                if not IncludedDay.Get(DayIndex) then
                    continue; // stays index-aligned with CategoriesArray - excluded days get no entry at all.

                SkillInternalValues.Add(0); // Capacity bar - skills never appear there.
                SkillInternalValues.Add(
                    AllDaySkillInternalValues.Get(Format(DayIndex) + '|' + SkillCode) +
                    AllDaySkillExternalValues.Get(Format(DayIndex) + '|' + SkillCode));
                SkillExternalValues.Add(0);
                SkillExternalValues.Add(0);
            end;
            AddChartSeries(SeriesArray, SkillCode, SkillInternalValues, GetSkillSeriesColor(SkillCode, SkillPaletteIdx), GetSkillSeriesBorderColor(SkillCode, SkillPaletteIdx), GetSkillSeriesFontColor(SkillCode));
            AddChartSeries(SeriesArray, SkillCode, SkillExternalValues, GetSkillSeriesColor(SkillCode, SkillPaletteIdx), ExternalBorderColorHex, '');
            SkillPaletteIdx += 1;
        end;

        ChartData.Add('categories', CategoriesArray);
        ChartData.Add('dayLabels', DayLabelsArray);
        ChartData.Add('dayIndices', DayIndicesArray);
        ChartData.Add('series', SeriesArray);
        ChartData.Add('barWidth', ColorConstants.GetWeeklyBarChartWidth());
        ChartData.WriteTo(ChartDataJson);
    end;

    /// <summary>
    /// Public entry point for OTHER add-ins that need this codeunit's own real per-day capacity
    /// split (Assigned/Free x Internal/External via CalcAssignedSplit/CalcCapacitySplit) without
    /// duplicating it - added 2026-09-08 for src/dhx/capacity_planning_overview (codeunit 50604's
    /// CPO_BuildDailyCapacityArray, feeding Section 3's "Hours overview" capacity total). Bug that
    /// prompted this (reported live, flagged "dangerous"): that add-in's own Section 3 was
    /// approximating total capacity client-side as `resources.length * 8h` (a flat headcount
    /// guess, and on top of that scoped to a small per-skill-capped resource subset - see
    /// CPO_BuildResourcesArray's own doc comment on ApplyPerSkillCap), which could read a small
    /// fraction of this codeunit's own real, Res.-Capacity-Entry-backed total for the same day/
    /// company (confirmed live: 408h, later 1798h, against a real ~2038h) - callers wanting a
    /// number that actually matches the Weekly/Daily Insights parts must go through THIS same
    /// computation, not re-derive their own. Caller must call PrepareDailyCapacityBuffer once for
    /// the whole display window before any GetDailyCapacitySplit calls (mirrors this codeunit's
    /// own BuildDayCapacityChartData(ForRange) doing the same before their own per-day loops).
    /// </summary>
    procedure PrepareDailyCapacityBuffer(StartDate: Date; EndDate: Date)
    begin
        EnsureDayPlanningBuffer(StartDate, EndDate);
    end;

    /// <summary>
    /// Returns ONE day's real Assigned/Free capacity split, Internal vs External by the
    /// capacity/assignment-holding resource's own "Is External" flag - identical numbers to what
    /// BuildDayCapacityChartData(ForRange)'s own Capacity bar plots for that day (CalcAssignedSplit
    /// + CalcCapacitySplit - see those procedures' own doc comments for the full reasoning: true
    /// "Res. Capacity Entry" data, company-wide, not a flat per-resource-count approximation).
    /// Caller must have already called PrepareDailyCapacityBuffer for a range covering PlanDate.
    /// </summary>
    procedure GetDailyCapacitySplit(PlanDate: Date; var AssignedInternal: Decimal; var AssignedExternal: Decimal; var FreeInternal: Decimal; var FreeExternal: Decimal)
    var
        FreeExternalMandatory: Decimal;
    begin
        CalcAssignedSplit(PlanDate, AssignedInternal, AssignedExternal);
        CalcCapacitySplit(PlanDate, FreeInternal, FreeExternal, FreeExternalMandatory);
        // Fold the mandatory/non-mandatory split (2026-09-16, page 50692's weekly chart only)
        // back into the plain External total so CPO/Dashboard's Section 3 totals are unaffected.
        FreeExternal += FreeExternalMandatory;
    end;

    /// <summary>
    /// True if PlanDate's segment values carry ANY nonzero data anywhere - Assigned (internal or
    /// external), free Capacity (internal, external, or external-mandatory), or any active
    /// skill's requested hours (internal or external) - used by BuildDayCapacityChartData to
    /// decide whether that day gets its own category pair/values at all. A day whose ONLY nonzero
    /// figure is the mandatory-external free-capacity split is still included, not dropped.
    /// Deliberately NOT used by BuildDayCapacityAuditBuffer, which always shows all 7 days by
    /// design (see its own doc comment).
    /// </summary>
    local procedure DayHasAnyChartData(AssignedInternal: Decimal; AssignedExternal: Decimal; CapacityInternal: Decimal; CapacityExternal: Decimal; CapacityExternalMandatory: Decimal; var ActiveSkillList: List of [Code[20]]; var SkillInternalValues: Dictionary of [Code[20], Decimal]; var SkillExternalValues: Dictionary of [Code[20], Decimal]): Boolean
    var
        SkillCode: Code[20];
    begin
        if (AssignedInternal <> 0) or (AssignedExternal <> 0) or (CapacityInternal <> 0) or (CapacityExternal <> 0) or (CapacityExternalMandatory <> 0) then
            exit(true);

        foreach SkillCode in ActiveSkillList do
            if (SkillInternalValues.Get(SkillCode) <> 0) or (SkillExternalValues.Get(SkillCode) <> 0) then
                exit(true);

        exit(false);
    end;

    /// <summary>
    /// Builds a flat audit trail of the "Day Capacity Chart Audit Buffer" - one row per number
    /// that appears anywhere in the stacked chart built by BuildDayCapacityChartData, including
    /// 0-valued rows for the "other" bar type's segments (skills are always 0 on the Capacity
    /// bar, free Internal/External/External-Mandatory capacity is always 0 on the Requested bar -
    /// they still get a row). Skills outside BuildActiveSkillList's result get no rows at all,
    /// matching the chart's own behavior. Rows are inserted in the same left-to-right order as the
    /// chart's bars: for each weekday Monday..Sunday, first the Capacity bar's rows ("Assigned"
    /// combined total, then free "Internal"/"External"/"External (Mandatory)" capacity, then each
    /// active skill's 0-valued pair), then the Requested bar's rows ("Assigned" combined total,
    /// 0-valued "Internal"/"External"/"External (Mandatory)", then each active skill's own
    /// combined total on the first row and 0 on the second) - the
    /// Requested bar never carries an Internal/External distinction anywhere, matching the
    /// chart's own collapse (see BuildDayCapacityChartData); "Assigned" was already a single
    /// combined-total row on both bar types before that collapse and stays that way unchanged.
    /// A skill's Internal and External rows share the same Segment text (the bare Skill Code) - only "Bar Type" + row position
    /// distinguish them, same as how page 50704's drilldown already treats any "Skill Code"
    /// segment as one group regardless of which half it came from. Shares CalcDaySegments with
    /// BuildDayCapacityChartData so the two views can never drift apart.
    /// </summary>
    procedure BuildDayCapacityAuditBuffer(var Buffer: Record "Day Capacity Chart Audit Buf" temporary; PeriodStartDate: Date)
    var
        ActiveSkillList: List of [Code[20]];
        SkillInternalValues: Dictionary of [Code[20], Decimal];
        SkillExternalValues: Dictionary of [Code[20], Decimal];
        SkillCode: Code[20];
        WeekdayIndex: Integer;
        CurrDate: Date;
        AssignedInternal: Decimal;
        AssignedExternal: Decimal;
        CapacityInternal: Decimal;
        CapacityExternal: Decimal;
        CapacityExternalMandatory: Decimal;
        LineNo: Integer;
    begin
        Buffer.Reset();
        Buffer.DeleteAll();

        EnsureDayPlanningBuffer(PeriodStartDate, PeriodStartDate + 6);

        BuildActiveSkillList(ActiveSkillList);

        LineNo := 0;
        for WeekdayIndex := 1 to 7 do begin
            CurrDate := PeriodStartDate + (WeekdayIndex - 1);

            CalcDaySegments(CurrDate, ActiveSkillList, AssignedInternal, AssignedExternal, CapacityInternal, CapacityExternal, CapacityExternalMandatory, SkillInternalValues, SkillExternalValues);

            // Capacity bar: "Assigned" carries the day's combined (internal+external) assigned
            // hours, "Internal"/"External"/"External (Mandatory)" carry TRUE free calendar
            // capacity (Res. Capacity Entry net of Assigned Hours - see CalcCapacitySplit), skills
            // are always 0 (skills never appear on the Capacity bar).
            LineNo += 1;
            InsertAuditLine(Buffer, LineNo, CurrDate, Enum::"Day Capacity Chart Bar Type"::Capacity, AssignedSegmentTok, AssignedInternal + AssignedExternal);
            LineNo += 1;
            InsertAuditLine(Buffer, LineNo, CurrDate, Enum::"Day Capacity Chart Bar Type"::Capacity, InternalSegmentTok, CapacityInternal);
            LineNo += 1;
            InsertAuditLine(Buffer, LineNo, CurrDate, Enum::"Day Capacity Chart Bar Type"::Capacity, ExternalSegmentTok, CapacityExternal);
            LineNo += 1;
            InsertAuditLine(Buffer, LineNo, CurrDate, Enum::"Day Capacity Chart Bar Type"::Capacity, ExternalMandatorySegmentTok, CapacityExternalMandatory);
            foreach SkillCode in ActiveSkillList do begin
                LineNo += 1;
                InsertAuditLine(Buffer, LineNo, CurrDate, Enum::"Day Capacity Chart Bar Type"::Capacity, SkillCode, 0);
                LineNo += 1;
                InsertAuditLine(Buffer, LineNo, CurrDate, Enum::"Day Capacity Chart Bar Type"::Capacity, SkillCode, 0);
            end;

            // Requested bar: "Assigned" carries the same combined total as the Capacity bar,
            // "Internal"/"External" free capacity is always 0 (it never appears on the Requested
            // bar), and each skill's Internal/External split is collapsed to a single combined
            // total on the first row with the second row always 0 - the Requested bar never
            // shows an Internal/External distinction anywhere, matching the chart's own collapse.
            LineNo += 1;
            InsertAuditLine(Buffer, LineNo, CurrDate, Enum::"Day Capacity Chart Bar Type"::Requested, AssignedSegmentTok, AssignedInternal + AssignedExternal);
            LineNo += 1;
            InsertAuditLine(Buffer, LineNo, CurrDate, Enum::"Day Capacity Chart Bar Type"::Requested, InternalSegmentTok, 0);
            LineNo += 1;
            InsertAuditLine(Buffer, LineNo, CurrDate, Enum::"Day Capacity Chart Bar Type"::Requested, ExternalSegmentTok, 0);
            LineNo += 1;
            InsertAuditLine(Buffer, LineNo, CurrDate, Enum::"Day Capacity Chart Bar Type"::Requested, ExternalMandatorySegmentTok, 0);
            foreach SkillCode in ActiveSkillList do begin
                LineNo += 1;
                InsertAuditLine(Buffer, LineNo, CurrDate, Enum::"Day Capacity Chart Bar Type"::Requested, SkillCode, SkillInternalValues.Get(SkillCode) + SkillExternalValues.Get(SkillCode));
                LineNo += 1;
                InsertAuditLine(Buffer, LineNo, CurrDate, Enum::"Day Capacity Chart Bar Type"::Requested, SkillCode, 0);
            end;
        end;
    end;

    local procedure InsertAuditLine(var Buffer: Record "Day Capacity Chart Audit Buf" temporary; LineNo: Integer; PlanDate: Date; BarType: Enum "Day Capacity Chart Bar Type"; Segment: Code[20]; Value: Decimal)
    begin
        Buffer.Init();
        Buffer."Line No." := LineNo;
        Buffer.Day := PlanDate;
        Buffer."Day Name" := CopyStr(FormatWeekdayShort(PlanDate), 1, MaxStrLen(Buffer."Day Name"));
        Buffer."Bar Type" := BarType;
        Buffer.Segment := Segment;
        Buffer.Value := Value;
        Buffer.Insert();
    end;

    /// <summary>
    /// Shared per-day computation used by both BuildDayCapacityChartData and
    /// BuildDayCapacityAuditBuffer so the chart and its audit trail can never drift apart. Returns
    /// the day's Assigned Hours split by the assigned resource's "Is External" flag (via
    /// CalcAssignedSplit), the day's TRUE free calendar capacity split the same way (via
    /// CalcCapacitySplit - "Res. Capacity Entry" net of that day's Assigned Hours, NOT Day
    /// Planning "Assigned Hours" reused a second time), plus, for each active skill, its
    /// unassigned-Requested-Hours split by "Requested Resource No." (via
    /// CalcUnassignedSkillRequestedSplit) for ONE weekday. Reads from the shared GDayPlanningBuf
    /// (see EnsureDayPlanningBuffer) - callers must have already ensured it is loaded for a range
    /// covering PlanDate.
    /// </summary>
    local procedure CalcDaySegments(PlanDate: Date; var ActiveSkillList: List of [Code[20]]; var AssignedInternal: Decimal; var AssignedExternal: Decimal; var CapacityInternal: Decimal; var CapacityExternal: Decimal; var CapacityExternalMandatory: Decimal; var SkillInternalValues: Dictionary of [Code[20], Decimal]; var SkillExternalValues: Dictionary of [Code[20], Decimal])
    var
        SkillCode: Code[20];
        SkillInternalD: Decimal;
        SkillExternalD: Decimal;
    begin
        Clear(SkillInternalValues);
        Clear(SkillExternalValues);

        CalcAssignedSplit(PlanDate, AssignedInternal, AssignedExternal);
        CalcCapacitySplit(PlanDate, CapacityInternal, CapacityExternal, CapacityExternalMandatory);

        foreach SkillCode in ActiveSkillList do begin
            CalcUnassignedSkillRequestedSplit(PlanDate, SkillCode, SkillInternalD, SkillExternalD);
            SkillInternalValues.Set(SkillCode, SkillInternalD);
            SkillExternalValues.Set(SkillCode, SkillExternalD);
        end;
    end;

    /// <summary>
    /// Loads GDayPlanningBuf (the codeunit-level shared TEMPORARY buffer - see its var
    /// declaration) with a copy of DateFrom..DateTo's Day Planning rows if it is not already
    /// holding that exact range, so the per-weekday/per-skill computations in
    /// CalcDaySegments/CalcAssignedSplit/CalcUnassignedSkillRequestedSplit/BuildActiveSkillList
    /// can aggregate purely from this in-memory buffer (Reset()+SetRange()+FindSet() against a
    /// temporary table is an in-process scan, not a SQL round-trip) instead of re-querying the
    /// physical table once per weekday/skill - and so BuildDayCapacityChartData and
    /// BuildDayCapacityAuditBuffer, called back-to-back for the same period by page 50692's
    /// RefreshData, share ONE physical read instead of one each. GDayPlanningBuf is a
    /// codeunit-instance-level (not table-level) buffer: safe across this codeunit's lifetime on
    /// one page, not shared between different pages/sessions.
    /// </summary>
    local procedure EnsureDayPlanningBuffer(DateFrom: Date; DateTo: Date)
    var
        DayPlanning: Record "Day Planning";
    begin
        if GBufferLoaded and (GBufferDateFrom = DateFrom) and (GBufferDateTo = DateTo) then
            exit;

        GDayPlanningBuf.Reset();
        GDayPlanningBuf.DeleteAll();
        DayPlanning.Reset();
        DayPlanning.SetLoadFields("Plan Date", Skill, "Assigned Resource No.", "Assigned Hours", "Requested Hours", "Requested Resource No.", Assigned);
        DayPlanning.SetRange("Plan Date", DateFrom, DateTo);
        if DayPlanning.FindSet() then
            repeat
                GDayPlanningBuf := DayPlanning;
                GDayPlanningBuf.Insert();
            until DayPlanning.Next() = 0;
        GDayPlanningBuf.Reset();

        GBufferDateFrom := DateFrom;
        GBufferDateTo := DateTo;
        GBufferLoaded := true;

        EnsureResCapacityBuffer(DateFrom, DateTo);
    end;

    /// <summary>
    /// Loads GResCapacityBuf (codeunit-instance-level shared TEMPORARY buffer, same idiom as
    /// GDayPlanningBuf/EnsureDayPlanningBuffer immediately above) with a copy of DateFrom..DateTo's
    /// "Res. Capacity Entry" rows if it is not already holding that exact range - so
    /// CalcCapacitySplit can aggregate purely from this in-memory buffer instead of re-querying the
    /// physical table once per calendar day (see GResCapacityBuf's own var doc comment for the perf
    /// history). Called from EnsureDayPlanningBuffer itself (always invoked with the identical
    /// DateFrom/DateTo every caller here already passes it), so no caller needs a second
    /// range-tracking call of its own.
    /// </summary>
    local procedure EnsureResCapacityBuffer(DateFrom: Date; DateTo: Date)
    var
        ResCapacityEntry: Record "Res. Capacity Entry";
    begin
        if GResCapBufferLoaded and (GResCapBufferDateFrom = DateFrom) and (GResCapBufferDateTo = DateTo) then
            exit;

        GResCapacityBuf.Reset();
        GResCapacityBuf.DeleteAll();
        ResCapacityEntry.Reset();
        ResCapacityEntry.SetLoadFields("Resource No.", Date, Capacity);
        ResCapacityEntry.SetRange(Date, DateFrom, DateTo);
        if ResCapacityEntry.FindSet() then
            repeat
                GResCapacityBuf := ResCapacityEntry;
                GResCapacityBuf.Insert();
            until ResCapacityEntry.Next() = 0;
        GResCapacityBuf.Reset();

        GResCapBufferDateFrom := DateFrom;
        GResCapBufferDateTo := DateTo;
        GResCapBufferLoaded := true;
    end;

    /// <summary>
    /// Determines which Skill Codes get their own chart series: any skill with at least one
    /// unassigned (Assigned = false) Day Planning row whose "Requested Hours" sum
    /// across the whole period is nonzero. Deliberately not the full Skill Code master list
    /// (unlike BuildSkillBuffer) - a skill with nothing requested in this period simply gets no
    /// series/bar segment at all. Reads from the shared GDayPlanningBuf (see
    /// EnsureDayPlanningBuffer) - caller must have already ensured it is loaded. Resets
    /// GDayPlanningBuf's filters before returning (cheap - it is a temporary/in-memory table, not
    /// a SQL round-trip), so the next function to use the shared buffer always starts from a
    /// clean, unfiltered record.
    /// </summary>
    local procedure BuildActiveSkillList(var ActiveSkillList: List of [Code[20]])
    var
        SkillTotals: Dictionary of [Code[20], Decimal];
        SkillCode: Code[20];
        CurrentValue: Decimal;
    begin
        Clear(ActiveSkillList);

        GDayPlanningBuf.Reset();
        GDayPlanningBuf.SetRange(Assigned, false);
        if GDayPlanningBuf.FindSet() then
            repeat
                if GDayPlanningBuf.Skill <> '' then begin
                    CurrentValue := 0;
                    if SkillTotals.ContainsKey(GDayPlanningBuf.Skill) then
                        CurrentValue := SkillTotals.Get(GDayPlanningBuf.Skill);
                    SkillTotals.Set(GDayPlanningBuf.Skill, CurrentValue + GDayPlanningBuf."Requested Hours");
                end;
            until GDayPlanningBuf.Next() = 0;
        GDayPlanningBuf.Reset();

        foreach SkillCode in SkillTotals.Keys() do
            if SkillTotals.Get(SkillCode) <> 0 then
                ActiveSkillList.Add(SkillCode);
    end;

    /// <summary>
    /// Splits the day's Assigned Hours into Internal / External buckets by the assigned
    /// resource's "Is External" flag. Rows with a blank "Assigned Resource No." cannot be
    /// classified and are skipped (in practice Assigned Hours is only ever populated once a
    /// resource is assigned). Reads from the shared GDayPlanningBuf (see EnsureDayPlanningBuffer)
    /// - caller must have already ensured it is loaded. Resets GDayPlanningBuf's filters before
    /// returning (cheap - temporary/in-memory table), so the next function to use the shared
    /// buffer always starts from a clean, unfiltered record.
    /// </summary>
    local procedure CalcAssignedSplit(PlanDate: Date; var InternalAssigned: Decimal; var ExternalAssigned: Decimal)
    var
        Resource: Record Resource;
    begin
        InternalAssigned := 0;
        ExternalAssigned := 0;

        Resource.SetLoadFields("Is External");

        GDayPlanningBuf.Reset();
        GDayPlanningBuf.SetRange("Plan Date", PlanDate);
        GDayPlanningBuf.SetRange(Assigned, true);
        if GDayPlanningBuf.FindSet() then
            repeat
                if Resource.Get(GDayPlanningBuf."Assigned Resource No.") then begin
                    if Resource."Is External" then
                        ExternalAssigned += GDayPlanningBuf."Assigned Hours"
                    else
                        InternalAssigned += GDayPlanningBuf."Assigned Hours";
                end;
            until GDayPlanningBuf.Next() = 0;
        GDayPlanningBuf.Reset();
    end;

    /// <summary>
    /// Splits TRUE calendar capacity for PlanDate into Internal / External buckets, matching what
    /// the standard Resource Capacity Matrix page shows (see codeunit 50694's own
    /// "Res. Capacity Entry" read) - NOT Day Planning "Assigned Hours" reused a second time (that
    /// was the root cause of the Capacity bar rendering near-zero whenever Day Planning
    /// assignments for a day hadn't been made yet, even though the resource's real calendar
    /// capacity for that day was nonzero). Deliberately reads "Res. Capacity Entry" directly with
    /// a plain SetRange(Date, PlanDate) rather than via the Resource."Capacity"/"Assigned Hours"
    /// FlowFields - those FlowFields' CalcFormula filters on the Resource record's own
    /// "Date Filter" FlowFilter field, which a temporary/short-lived Resource record used purely
    /// to calcfields() never has set, so calcfields would silently sum ALL dates instead of just
    /// PlanDate. Each resource's free capacity is Capacity (that day's "Res. Capacity Entry" sum,
    /// which itself may be split across several entries - see the "Duplicate Id" field) minus
    /// that same day's Assigned Hours (read from the shared GDayPlanningBuf - see
    /// EnsureDayPlanningBuffer - so this needs no second physical Day Planning query), floored at
    /// 0, then bucketed the same way CalcAssignedSplit buckets Assigned Hours: by the
    /// capacity-holding resource's "Is External" flag alone. Pool and Pool Member resources are
    /// deliberately NOT treated as External here - this is an intentional, documented divergence
    /// from the legacy/dead CalcFreeCapacity procedure elsewhere in this codeunit, which still
    /// folds "Is Pool"/"Is Pool Member" into its own External classification for the old
    /// barchart_daily page it alone serves. Caller must have already ensured GDayPlanningBuf/
    /// GResCapacityBuf are loaded for a range covering PlanDate (EnsureDayPlanningBuffer loads
    /// both together - see its own doc comment).
    ///
    /// PERF (2026-09-14): reads from the shared GResCapacityBuf in-memory buffer (see
    /// EnsureResCapacityBuffer) instead of a fresh "Res. Capacity Entry" FindSet filtered to just
    /// PlanDate - the old per-call physical query meant a caller looping this once per day over an
    /// N-day window (page 50722's RefreshData path, via PrepareDailyCapacityBuffer/
    /// GetDailyCapacitySplit) paid N separate company-wide table scans instead of one. Same filter
    /// semantics (Date = PlanDate, no other criteria) - only the source (buffer vs physical table)
    /// changed.
    ///
    /// 3-WAY SPLIT (2026-09-16): the External bucket is further divided by the capacity-holding
    /// resource's own "Mandatory Schedulling" flag (table extension field, unrelated original
    /// feature reused here purely as a classifier) into ExternalCapacity (non-mandatory) and
    /// ExternalCapacity_mandatory (mandatory). This 3-way split is only ever surfaced on page
    /// 50692's weekly chart (BuildDayCapacityChartData) - every other caller of this procedure
    /// (via CalcDaySegments) adds the mandatory bucket straight back into the plain External total
    /// before returning, so they see byte-identical numbers to before this change.
    /// </summary>
    local procedure CalcCapacitySplit(PlanDate: Date; var InternalCapacity: Decimal; var ExternalCapacity: Decimal; var ExternalCapacity_mandatory: Decimal)
    var
        Resource: Record Resource;
        ResourceCapacityTotals: Dictionary of [Code[20], Decimal];
        ResourceAssignedTotals: Dictionary of [Code[20], Decimal];
        ResourceNo: Code[20];
        CapacityTotal: Decimal;
        AssignedTotal: Decimal;
        FreeCapacity: Decimal;
        External: Boolean;
    begin
        InternalCapacity := 0;
        ExternalCapacity := 0;
        ExternalCapacity_mandatory := 0;

        GResCapacityBuf.Reset();
        GResCapacityBuf.SetRange(Date, PlanDate);
        if GResCapacityBuf.FindSet() then
            repeat
                CapacityTotal := 0;
                if ResourceCapacityTotals.ContainsKey(GResCapacityBuf."Resource No.") then
                    CapacityTotal := ResourceCapacityTotals.Get(GResCapacityBuf."Resource No.");
                ResourceCapacityTotals.Set(GResCapacityBuf."Resource No.", CapacityTotal + GResCapacityBuf.Capacity);
            until GResCapacityBuf.Next() = 0;
        GResCapacityBuf.Reset();

        if ResourceCapacityTotals.Keys().Count > 0 then begin
            GDayPlanningBuf.Reset();
            GDayPlanningBuf.SetRange("Plan Date", PlanDate);
            GDayPlanningBuf.SetRange(Assigned, true);
            if GDayPlanningBuf.FindSet() then
                repeat
                    AssignedTotal := 0;
                    if ResourceAssignedTotals.ContainsKey(GDayPlanningBuf."Assigned Resource No.") then
                        AssignedTotal := ResourceAssignedTotals.Get(GDayPlanningBuf."Assigned Resource No.");
                    ResourceAssignedTotals.Set(GDayPlanningBuf."Assigned Resource No.", AssignedTotal + GDayPlanningBuf."Assigned Hours");
                until GDayPlanningBuf.Next() = 0;
            GDayPlanningBuf.Reset();
        end;

        foreach ResourceNo in ResourceCapacityTotals.Keys() do begin
            CapacityTotal := ResourceCapacityTotals.Get(ResourceNo);
            AssignedTotal := 0;
            if ResourceAssignedTotals.ContainsKey(ResourceNo) then
                AssignedTotal := ResourceAssignedTotals.Get(ResourceNo);

            FreeCapacity := CapacityTotal - AssignedTotal;
            if FreeCapacity < 0 then
                FreeCapacity := 0;
            if FreeCapacity <> 0 then
                if Resource.Get(ResourceNo) then begin
                    External := Resource."Is External";
                    if External then begin
                        if Resource."Mandatory Schedulling" then
                            ExternalCapacity_mandatory += FreeCapacity
                        else
                            ExternalCapacity += FreeCapacity;
                    end else
                        InternalCapacity += FreeCapacity;
                end;
        end;
    end;

    /// <summary>
    /// Per-skill twin of GetCapacitySplitForRangeWithMandatory below - same Assigned/Free x
    /// Internal/External/Mandatory computation, scoped to only the resources who hold SkillCode
    /// via the "Resource Skill" table (Type = Resource, "No." = Resource No., "Skill Code" =
    /// SkillCode), instead of every resource company-wide. Added 2026-09-22 for
    /// src/dhx/barchart_daily's per-skill Capacity ("C") bar: per the user's own mockup
    /// annotation, "the capacity bar is per respective resource (not skill)" - i.e. a skill's own
    /// C bar shows the SAME 4-segment Assigned/Free-Internal/Free-External-Mandatory/
    /// Free-External split this codeunit's own week-level Capacity bar shows, just filtered down
    /// to the resource set holding that skill. A resource holding multiple skills legitimately
    /// contributes to each of those skills' own totals - expected, not double-counting to avoid
    /// (each skill's C bar answers "how much capacity do SkillCode-qualified resources have",
    /// independently of whatever other skills those same resources might also hold).
    ///
    /// Reuses the exact same classification rules CalcAssignedSplit/CalcCapacitySplit use ("Is
    /// External" for Internal/External, "Mandatory Schedulling" for the External split) via their
    /// own resource-set-filtered twins (CalcAssignedSplitForResourceSet/
    /// CalcCapacitySplitForResourceSet immediately below) so the two charts can never classify a
    /// resource differently. Reads from the shared GDayPlanningBuf/GResCapacityBuf temp buffers
    /// (EnsureDayPlanningBuffer/EnsureResCapacityBuffer) - no per-skill physical "Res. Capacity
    /// Entry"/"Day Planning" table scan, matching this codeunit's existing perf convention (see
    /// EnsureDayPlanningBuffer's own doc comment); the Daily chart calls this once per skill per
    /// render, so a physical scan per skill would multiply the same N-day company-wide read
    /// N-skills times.
    /// </summary>
    procedure GetSkillCapacitySplitForRangeWithMandatory(SkillCode: Code[10]; DateFrom: Date; DateTo: Date; var AssignedInternal: Decimal; var AssignedExternal: Decimal; var CapacityInternal: Decimal; var CapacityExternal: Decimal; var CapacityExternalMandatory: Decimal)
    var
        ResourceSet: Dictionary of [Code[20], Boolean];
        CurrDate: Date;
        DayAssignedInternal: Decimal;
        DayAssignedExternal: Decimal;
        DayCapacityInternal: Decimal;
        DayCapacityExternal: Decimal;
        DayCapacityExternalMandatory: Decimal;
    begin
        AssignedInternal := 0;
        AssignedExternal := 0;
        CapacityInternal := 0;
        CapacityExternal := 0;
        CapacityExternalMandatory := 0;

        if DateTo < DateFrom then
            exit;

        BuildResourceSetForSkill(SkillCode, ResourceSet);
        if ResourceSet.Keys().Count = 0 then
            exit; // no resource holds this skill - nothing to sum.

        EnsureDayPlanningBuffer(DateFrom, DateTo);

        CurrDate := DateFrom;
        while CurrDate <= DateTo do begin
            CalcAssignedSplitForResourceSet(CurrDate, ResourceSet, DayAssignedInternal, DayAssignedExternal);
            CalcCapacitySplitForResourceSet(CurrDate, ResourceSet, DayCapacityInternal, DayCapacityExternal, DayCapacityExternalMandatory);
            AssignedInternal += DayAssignedInternal;
            AssignedExternal += DayAssignedExternal;
            CapacityInternal += DayCapacityInternal;
            CapacityExternal += DayCapacityExternal;
            CapacityExternalMandatory += DayCapacityExternalMandatory;
            CurrDate += 1;
        end;
    end;

    /// <summary>
    /// Collects the distinct Resource Nos. registered against SkillCode in "Resource Skill"
    /// (Type = Resource) - the resource set GetSkillCapacitySplitForRangeWithMandatory scopes its
    /// Assigned/Free Capacity computation to.
    /// </summary>
    local procedure BuildResourceSetForSkill(SkillCode: Code[10]; var ResourceSet: Dictionary of [Code[20], Boolean])
    var
        ResourceSkill: Record "Resource Skill";
    begin
        Clear(ResourceSet);
        ResourceSkill.Reset();
        ResourceSkill.SetRange(Type, ResourceSkill.Type::Resource);
        ResourceSkill.SetRange("Skill Code", SkillCode);
        ResourceSkill.SetLoadFields("No.");
        if ResourceSkill.FindSet() then
            repeat
                if not ResourceSet.ContainsKey(ResourceSkill."No.") then
                    ResourceSet.Add(ResourceSkill."No.", true);
            until ResourceSkill.Next() = 0;
    end;

    /// <summary>
    /// Resource-set-filtered twin of CalcAssignedSplit above - identical logic/classification,
    /// just skips any "Assigned Resource No." not in ResourceSet.
    /// </summary>
    local procedure CalcAssignedSplitForResourceSet(PlanDate: Date; var ResourceSet: Dictionary of [Code[20], Boolean]; var InternalAssigned: Decimal; var ExternalAssigned: Decimal)
    var
        Resource: Record Resource;
    begin
        InternalAssigned := 0;
        ExternalAssigned := 0;

        Resource.SetLoadFields("Is External");

        GDayPlanningBuf.Reset();
        GDayPlanningBuf.SetRange("Plan Date", PlanDate);
        GDayPlanningBuf.SetRange(Assigned, true);
        if GDayPlanningBuf.FindSet() then
            repeat
                if ResourceSet.ContainsKey(GDayPlanningBuf."Assigned Resource No.") then
                    if Resource.Get(GDayPlanningBuf."Assigned Resource No.") then begin
                        if Resource."Is External" then
                            ExternalAssigned += GDayPlanningBuf."Assigned Hours"
                        else
                            InternalAssigned += GDayPlanningBuf."Assigned Hours";
                    end;
            until GDayPlanningBuf.Next() = 0;
        GDayPlanningBuf.Reset();
    end;

    /// <summary>
    /// Resource-set-filtered twin of CalcCapacitySplit above - identical logic/classification,
    /// just skips any "Resource No." not in ResourceSet when accumulating capacity/assigned
    /// totals.
    /// </summary>
    local procedure CalcCapacitySplitForResourceSet(PlanDate: Date; var ResourceSet: Dictionary of [Code[20], Boolean]; var InternalCapacity: Decimal; var ExternalCapacity: Decimal; var ExternalCapacity_mandatory: Decimal)
    var
        Resource: Record Resource;
        ResourceCapacityTotals: Dictionary of [Code[20], Decimal];
        ResourceAssignedTotals: Dictionary of [Code[20], Decimal];
        ResourceNo: Code[20];
        CapacityTotal: Decimal;
        AssignedTotal: Decimal;
        FreeCapacity: Decimal;
    begin
        InternalCapacity := 0;
        ExternalCapacity := 0;
        ExternalCapacity_mandatory := 0;

        GResCapacityBuf.Reset();
        GResCapacityBuf.SetRange(Date, PlanDate);
        if GResCapacityBuf.FindSet() then
            repeat
                if ResourceSet.ContainsKey(GResCapacityBuf."Resource No.") then begin
                    CapacityTotal := 0;
                    if ResourceCapacityTotals.ContainsKey(GResCapacityBuf."Resource No.") then
                        CapacityTotal := ResourceCapacityTotals.Get(GResCapacityBuf."Resource No.");
                    ResourceCapacityTotals.Set(GResCapacityBuf."Resource No.", CapacityTotal + GResCapacityBuf.Capacity);
                end;
            until GResCapacityBuf.Next() = 0;
        GResCapacityBuf.Reset();

        if ResourceCapacityTotals.Keys().Count > 0 then begin
            GDayPlanningBuf.Reset();
            GDayPlanningBuf.SetRange("Plan Date", PlanDate);
            GDayPlanningBuf.SetRange(Assigned, true);
            if GDayPlanningBuf.FindSet() then
                repeat
                    if ResourceSet.ContainsKey(GDayPlanningBuf."Assigned Resource No.") then begin
                        AssignedTotal := 0;
                        if ResourceAssignedTotals.ContainsKey(GDayPlanningBuf."Assigned Resource No.") then
                            AssignedTotal := ResourceAssignedTotals.Get(GDayPlanningBuf."Assigned Resource No.");
                        ResourceAssignedTotals.Set(GDayPlanningBuf."Assigned Resource No.", AssignedTotal + GDayPlanningBuf."Assigned Hours");
                    end;
                until GDayPlanningBuf.Next() = 0;
            GDayPlanningBuf.Reset();
        end;

        foreach ResourceNo in ResourceCapacityTotals.Keys() do begin
            CapacityTotal := ResourceCapacityTotals.Get(ResourceNo);
            AssignedTotal := 0;
            if ResourceAssignedTotals.ContainsKey(ResourceNo) then
                AssignedTotal := ResourceAssignedTotals.Get(ResourceNo);

            FreeCapacity := CapacityTotal - AssignedTotal;
            if FreeCapacity < 0 then
                FreeCapacity := 0;
            if FreeCapacity <> 0 then
                if Resource.Get(ResourceNo) then
                    if Resource."Is External" then begin
                        if Resource."Mandatory Schedulling" then
                            ExternalCapacity_mandatory += FreeCapacity
                        else
                            ExternalCapacity += FreeCapacity;
                    end else
                        InternalCapacity += FreeCapacity;
        end;
    end;

    /// <summary>
    /// Splits "Requested Hours" for unassigned (Assigned = false) Day Planning rows
    /// on PlanDate for the given Skill into Internal / External buckets by the line's OWN
    /// "Requested Resource No." - a preferred/target resource a planner can set on a line before
    /// it is formally assigned (table 50610's own field 27), independent of "Assigned Resource
    /// No.". Unlike the actual assignment, this field CAN be set on an otherwise-unassigned line,
    /// so it is the only available signal for "is this specific pocket of unassigned demand
    /// destined for an external resource" - a blank "Requested Resource No." (no preference set
    /// yet) counts as Internal, the same default an ordinary, not-yet-targeted request would
    /// read as. Deliberately ignores any Resource No. filter - unassigned lines have no assigned
    /// resource to filter on (see the procedure doc comment on BuildDayCapacityChartData / the
    /// caller's spec). Reads from the shared GDayPlanningBuf (see EnsureDayPlanningBuffer) -
    /// caller must have already ensured it is loaded. Resets GDayPlanningBuf's filters before
    /// returning (cheap - temporary/in-memory table), so the next function to use the shared
    /// buffer always starts from a clean, unfiltered record.
    /// </summary>
    local procedure CalcUnassignedSkillRequestedSplit(PlanDate: Date; SkillCode: Code[20]; var InternalRequested: Decimal; var ExternalRequested: Decimal)
    var
        Resource: Record Resource;
    begin
        InternalRequested := 0;
        ExternalRequested := 0;

        Resource.SetLoadFields("Is External");

        GDayPlanningBuf.Reset();
        GDayPlanningBuf.SetRange("Plan Date", PlanDate);
        GDayPlanningBuf.SetRange(Assigned, false);
        GDayPlanningBuf.SetRange(Skill, SkillCode);
        if GDayPlanningBuf.FindSet() then
            repeat
                if (GDayPlanningBuf."Requested Resource No." <> '') and Resource.Get(GDayPlanningBuf."Requested Resource No.") and Resource."Is External" then
                    ExternalRequested += GDayPlanningBuf."Requested Hours"
                else
                    InternalRequested += GDayPlanningBuf."Requested Hours";
            until GDayPlanningBuf.Next() = 0;
        GDayPlanningBuf.Reset();
    end;

    local procedure FormatWeekdayShort(ADate: Date): Text
    begin
        exit(Format(ADate, 0, '<Weekday Text,3>'));
    end;

    /// <summary>
    /// Joins Values into a single '|'-delimited OR filter string suitable for SetFilter - same
    /// helper/pattern as page 50704's own local BuildCodeOrFilter. No filter-character escaping is
    /// attempted (matching that existing precedent): Resource No./Skill Code values in this system
    /// are plain alphanumeric identifiers, not user-authored text, so this is a pragmatic, low-risk
    /// choice consistent with the rest of this codebase rather than a general-purpose filter
    /// builder.
    /// </summary>
    local procedure BuildCodeOrFilter(var Values: List of [Code[20]]): Text
    var
        Value: Code[20];
        FilterText: Text;
    begin
        foreach Value in Values do
            if FilterText = '' then
                FilterText := Value
            else
                FilterText += '|' + Value;
        exit(FilterText);
    end;

    /// <summary>
    /// Resolves a chart segment - identified by SegmentId (one of the fixed series-name Labels
    /// declared below, e.g. AssignedCapacitySeriesNameLbl/CapExternalSeriesNameLbl, or a bare Skill
    /// Code for a per-skill series) plus its click origin - back to the real "Day Planning"/
    /// "Res. Capacity Entry" records that number was built from, and opens the matching standard
    /// list page ("Day Plannings"/"Res. Capacity Entries") pre-filtered to exactly that record
    /// set. Called from page 50692's OnShowSegmentData usercontrol trigger, itself fired by
    /// wrapper.js's right-click "Show Data" context menu on either:
    ///   - an individual stacked-bar SEGMENT (WholeWeek = false, BarType = "Capacity"/"Requested",
    ///     DayIndex = 1..7) - that one day's slice of that segment, or
    ///   - a LEGEND entry (WholeWeek = true, BarType/DayIndex ignored) - that segment's total
    ///     across the whole displayed Monday..Sunday period (PeriodStartDate.. +6).
    /// DayIndex is the raw 1..7 weekday index (see BuildDayCapacityChartData's "dayIndices" JSON
    /// array) - NOT a locale-formatted weekday name - so the actual Date is always recomputed here
    /// from the page's own PeriodStartDate rather than trusting anything parsed back out of
    /// display text.
    /// </summary>
    procedure ShowSegmentData(SegmentId: Text; BarType: Text; PeriodStartDate: Date; DayIndex: Integer; WholeWeek: Boolean)
    var
        DateFrom: Date;
        DateTo: Date;
    begin
        if WholeWeek then begin
            DateFrom := PeriodStartDate;
            DateTo := PeriodStartDate + 6;
        end else begin
            if (DayIndex < 1) or (DayIndex > 7) then
                exit; // malformed/stale click payload - nothing sane to open.
            DateFrom := PeriodStartDate + (DayIndex - 1);
            DateTo := DateFrom;
        end;

        case SegmentId of
            AssInternalSeriesNameLbl, AssExternalSeriesNameLbl, AssignedCapacitySeriesNameLbl:
                ShowAssignedCapacitySegment(SegmentId, BarType, DateFrom, DateTo, WholeWeek);
            CapInternalSeriesNameLbl, CapExternalSeriesNameLbl, CapExternalMandatorySeriesNameLbl:
                ShowFreeCapacitySegment(SegmentId, DateFrom, DateTo);
            else
                ShowSkillSegment(SegmentId, DateFrom, DateTo);
        end;
    end;

    /// <summary>
    /// Drilldown for the Assigned Capacity segment. Day Planning has no field storing the assigned
    /// resource's own "Is External" flag, so the classified resource set is computed first
    /// (BuildAssignedResourceSet) and then turned into a plain "Assigned Resource No." OR filter
    /// (BuildCodeOrFilter - same helper/pattern already used by page 50704's own Internal/External
    /// OnDrillDown) before opening "Day Plannings".
    ///
    /// Deliberately NOT the Mark()+MarkedOnly()+Page.Run() idiom this drilldown originally used:
    /// confirmed live (via Playwright against the actual BC web client) that Page.Run() invoked
    /// from THIS call path - a control add-in event trigger (OnShowSegmentData), itself fired via
    /// wrapper.js's Microsoft.Dynamics.NAV.InvokeExtensibilityMethod - always opens the target page
    /// at a fresh bookmarked URL rather than as an in-session page-stack push. Plain SetRange/
    /// SetFilter field filters survive that round-trip (they serialize straight into the URL/
    /// bookmark), but Record.Mark()'s in-memory marked-list does not, so MarkedOnly(true) always
    /// resolved to zero rows here even though AnyMarked had been true moments earlier in the same
    /// call - the list opened but was always empty. A plain OR-filter has no such boundary to cross.
    ///
    /// SegmentId = AssignedCapacitySeriesNameLbl is page 50692's own (weekly chart) single combined
    /// Assigned Capacity series - BuildDayCapacityChartData no longer emits an Internal/External
    /// split on either bar (see that procedure's own doc comment), so UseClassification is always
    /// false for this SegmentId regardless of WholeWeek/BarType, and every matching Day Planning
    /// row opens with no Is External filtering. AssInternalSeriesNameLbl/AssExternalSeriesNameLbl
    /// are kept here only for any caller still emitting the legacy split (e.g.
    /// BuildDayCapacityChartDataForRange, currently unused - see its own doc comment); for those,
    /// the Internal/External classification only applies when UseClassification is true - true for
    /// WholeWeek (legend) clicks and for a click on the CAPACITY bar's own Assigned segment, both of
    /// which represent this series' real, always-classified identity. A click on the REQUESTED
    /// bar's Assigned segment is the one exception: that segment is a deliberately collapsed
    /// combined total (the "external" series is always 0 there), so its drilldown shows ALL
    /// assigned rows for that day regardless of the assigned resource's Is External flag - matching
    /// what the plotted number actually represents.
    /// </summary>
    local procedure ShowAssignedCapacitySegment(SegmentId: Text; BarType: Text; DateFrom: Date; DateTo: Date; WholeWeek: Boolean)
    var
        DayPlanning: Record "Day Planning";
        ResourceNoList: List of [Code[20]];
        ClassifyExternal: Boolean;
        UseClassification: Boolean;
        ResourceNoFilterText: Text;
    begin
        ClassifyExternal := (SegmentId = AssExternalSeriesNameLbl);
        UseClassification := (SegmentId <> AssignedCapacitySeriesNameLbl) and (WholeWeek or (BarType = CapacityBarTypeTok));

        BuildAssignedResourceSet(DateFrom, DateTo, ClassifyExternal, not UseClassification, ResourceNoList);
        if ResourceNoList.Count() = 0 then begin
            Message(NoMatchingDataMsg);
            exit;
        end;

        ResourceNoFilterText := BuildCodeOrFilter(ResourceNoList);

        DayPlanning.Reset();
        DayPlanning.SetRange("Plan Date", DateFrom, DateTo);
        DayPlanning.SetFilter("Assigned Resource No.", ResourceNoFilterText);
        Page.Run(Page::"Day Plannings", DayPlanning);
    end;

    /// <summary>
    /// Collects the distinct "Assigned Resource No." values with at least one Day Planning row in
    /// DateFrom..DateTo. When AnyClassification is false, only resources whose Resource."Is
    /// External" matches ClassifyExternal are kept - a resource's Is External is a constant
    /// resource-level property (not date-dependent), so this classification is exact, unlike the
    /// free-capacity equivalent below (see GetFreeCapacityResourcesForDate's own comment).
    /// </summary>
    local procedure BuildAssignedResourceSet(DateFrom: Date; DateTo: Date; ClassifyExternal: Boolean; AnyClassification: Boolean; var ResourceNoList: List of [Code[20]])
    var
        DayPlanning: Record "Day Planning";
        Resource: Record Resource;
        SeenResources: Dictionary of [Code[20], Boolean];
    begin
        Clear(ResourceNoList);
        Resource.SetLoadFields("Is External");

        DayPlanning.Reset();
        DayPlanning.SetLoadFields("Assigned Resource No.", Assigned);
        DayPlanning.SetRange("Plan Date", DateFrom, DateTo);
        DayPlanning.SetRange(Assigned, true);
        if DayPlanning.FindSet() then
            repeat
                if not SeenResources.ContainsKey(DayPlanning."Assigned Resource No.") then begin
                    SeenResources.Add(DayPlanning."Assigned Resource No.", true);
                    if AnyClassification then
                        ResourceNoList.Add(DayPlanning."Assigned Resource No.")
                    else
                        if Resource.Get(DayPlanning."Assigned Resource No.") and (Resource."Is External" = ClassifyExternal) then
                            ResourceNoList.Add(DayPlanning."Assigned Resource No.");
                end;
            until DayPlanning.Next() = 0;
    end;

    /// <summary>
    /// Drilldown for "Free Capacity - Internal"/"External" - always uses the segment's true
    /// classified meaning regardless of BarType (this series is only ever nonzero on the Capacity
    /// bar in the first place - see BuildDayCapacityChartData). For each day in DateFrom..DateTo,
    /// recomputes which resources actually contributed nonzero free capacity of the requested
    /// classification that day (GetFreeCapacityResourcesForDate, mirroring CalcCapacitySplit),
    /// unions those resource numbers across the whole range (deduplicated), and opens "Res.
    /// Capacity Entries" filtered to Date in DateFrom..DateTo AND "Resource No." in that union (via
    /// BuildCodeOrFilter - same helper/pattern page 50704's own OnDrillDown already uses).
    ///
    /// Deliberately NOT Mark()+MarkedOnly()+Page.Run() (this drilldown's original implementation):
    /// confirmed live (via Playwright against the actual BC web client) that Page.Run() invoked
    /// from THIS call path - a control add-in event trigger (OnShowSegmentData), itself fired via
    /// wrapper.js's Microsoft.Dynamics.NAV.InvokeExtensibilityMethod - always opens the target page
    /// at a fresh bookmarked URL rather than as an in-session page-stack push. Plain SetRange/
    /// SetFilter field filters survive that round-trip (they serialize straight into the URL/
    /// bookmark), but Record.Mark()'s in-memory marked-list does not, so MarkedOnly(true) always
    /// resolved to zero rows here even though marking itself had found matching entries - the list
    /// opened but was always empty. A plain OR-filter has no such boundary to cross.
    ///
    /// Unioning across the whole range (rather than re-filtering per day, which is what Mark() did)
    /// means a resource that only had free capacity on ONE day of DateFrom..DateTo can now also
    /// bring in its entries from days where it had none (capacity fully assigned that day,
    /// contributing 0) - already a documented, accepted imprecision of this same drilldown for
    /// WholeWeek (legend) clicks even before this fix (every row the aggregate was built from is
    /// still shown, just also a few same-resource/other-day rows that net to 0). For a single-day
    /// bar-segment click DateFrom = DateTo, so the union has exactly one day's terms and this is
    /// precision-identical to the old per-day Mark() loop.
    ///
    /// 3-WAY CLASSIFICATION (2026-09-16): SegmentId now maps to one of FOUR classifications (see
    /// the local Classification option below) rather than a plain external/internal boolean -
    /// CapExternalSeriesNameLbl narrows to NON-mandatory external resources only (mandatory ones
    /// now belong to CapExternalMandatorySeriesNameLbl's own segment - see CalcCapacitySplit's own
    /// doc comment on the 3-way split), and CapExternalMandatorySeriesNameLbl resolves to mandatory
    /// external resources only. ShowFreeCapacitySegmentForDate below deliberately bypasses this
    /// SegmentId mapping (it calls ShowFreeCapacitySegmentByClassification directly with
    /// Classification::ExternalAny) so its own caller (CPO's Section 3, which has no concept of
    /// "mandatory") keeps seeing External as a whole, unnarrowed, exactly as before this change.
    /// </summary>
    local procedure ShowFreeCapacitySegment(SegmentId: Text; DateFrom: Date; DateTo: Date)
    var
        Classification: Option Internal,ExternalAny,ExternalMandatory,ExternalNonMandatory;
    begin
        case SegmentId of
            CapInternalSeriesNameLbl:
                Classification := Classification::Internal;
            CapExternalMandatorySeriesNameLbl:
                Classification := Classification::ExternalMandatory;
            else // CapExternalSeriesNameLbl
                Classification := Classification::ExternalNonMandatory;
        end;
        ShowFreeCapacitySegmentByClassification(Classification, DateFrom, DateTo);
    end;

    /// <summary>
    /// Shared implementation behind ShowFreeCapacitySegment (SegmentId-based, narrows External to
    /// mandatory/non-mandatory) and ShowFreeCapacitySegmentForDate (plain Internal/External-as-a-
    /// whole, for the CPO caller that has no "mandatory" concept) - unions the matching resources
    /// across DateFrom..DateTo (see this procedure's own history/comments above on why a plain
    /// OR-filter replaced the old Mark()+MarkedOnly()+Page.Run() idiom) and opens "Res. Capacity
    /// Entries" filtered to them.
    /// </summary>
    local procedure ShowFreeCapacitySegmentByClassification(Classification: Option Internal,ExternalAny,ExternalMandatory,ExternalNonMandatory; DateFrom: Date; DateTo: Date)
    var
        ResCapacityEntry: Record "Res. Capacity Entry";
        DateResourceList: List of [Code[20]];
        UnionResourceList: List of [Code[20]];
        SeenResources: Dictionary of [Code[20], Boolean];
        CurrDate: Date;
        ResourceNo: Code[20];
        ResourceNoFilterText: Text;
    begin
        EnsureDayPlanningBuffer(DateFrom, DateTo);

        CurrDate := DateFrom;
        while CurrDate <= DateTo do begin
            Clear(DateResourceList);
            GetFreeCapacityResourcesForDate(CurrDate, Classification, DateResourceList);
            foreach ResourceNo in DateResourceList do
                if not SeenResources.ContainsKey(ResourceNo) then begin
                    SeenResources.Add(ResourceNo, true);
                    UnionResourceList.Add(ResourceNo);
                end;
            CurrDate += 1;
        end;

        if UnionResourceList.Count() = 0 then begin
            Message(NoMatchingDataMsg);
            exit;
        end;

        ResourceNoFilterText := BuildCodeOrFilter(UnionResourceList);

        ResCapacityEntry.Reset();
        ResCapacityEntry.SetRange(Date, DateFrom, DateTo);
        ResCapacityEntry.SetFilter("Resource No.", ResourceNoFilterText);
        Page.Run(Page::"Res. Capacity Entries", ResCapacityEntry);
    end;

    /// <summary>
    /// Returns the Resource No.s with nonzero TRUE free capacity (Res. Capacity Entry sum minus
    /// that day's Day Planning Assigned Hours, floored at 0) on PlanDate matching Classification
    /// (Internal / any External / mandatory-External-only / non-mandatory-External-only - see
    /// ResourceMatchesClassification) - the same computation as CalcCapacitySplit, but collecting
    /// the contributing resource numbers instead of summing their totals. Kept as its own
    /// procedure (deliberately not refactored to share CalcCapacitySplit's body) so this drilldown
    /// path cannot accidentally change the chart's own totals. Reads/relies on the shared
    /// GDayPlanningBuf being already loaded for a range covering PlanDate - caller
    /// (ShowFreeCapacitySegmentByClassification) calls EnsureDayPlanningBuffer first.
    /// </summary>
    local procedure GetFreeCapacityResourcesForDate(PlanDate: Date; Classification: Option Internal,ExternalAny,ExternalMandatory,ExternalNonMandatory; var ResourceNoList: List of [Code[20]])
    var
        ResCapacityEntry: Record "Res. Capacity Entry";
        Resource: Record Resource;
        ResourceCapacityTotals: Dictionary of [Code[20], Decimal];
        ResourceAssignedTotals: Dictionary of [Code[20], Decimal];
        ResourceNo: Code[20];
        CapacityTotal: Decimal;
        AssignedTotal: Decimal;
        FreeCapacity: Decimal;
    begin
        ResCapacityEntry.SetLoadFields("Resource No.", Capacity);
        ResCapacityEntry.SetRange(Date, PlanDate);
        if ResCapacityEntry.FindSet() then
            repeat
                CapacityTotal := 0;
                if ResourceCapacityTotals.ContainsKey(ResCapacityEntry."Resource No.") then
                    CapacityTotal := ResourceCapacityTotals.Get(ResCapacityEntry."Resource No.");
                ResourceCapacityTotals.Set(ResCapacityEntry."Resource No.", CapacityTotal + ResCapacityEntry.Capacity);
            until ResCapacityEntry.Next() = 0;

        if ResourceCapacityTotals.Keys().Count > 0 then begin
            GDayPlanningBuf.Reset();
            GDayPlanningBuf.SetRange("Plan Date", PlanDate);
            GDayPlanningBuf.SetRange(Assigned, true);
            if GDayPlanningBuf.FindSet() then
                repeat
                    AssignedTotal := 0;
                    if ResourceAssignedTotals.ContainsKey(GDayPlanningBuf."Assigned Resource No.") then
                        AssignedTotal := ResourceAssignedTotals.Get(GDayPlanningBuf."Assigned Resource No.");
                    ResourceAssignedTotals.Set(GDayPlanningBuf."Assigned Resource No.", AssignedTotal + GDayPlanningBuf."Assigned Hours");
                until GDayPlanningBuf.Next() = 0;
            GDayPlanningBuf.Reset();
        end;

        foreach ResourceNo in ResourceCapacityTotals.Keys() do begin
            CapacityTotal := ResourceCapacityTotals.Get(ResourceNo);
            AssignedTotal := 0;
            if ResourceAssignedTotals.ContainsKey(ResourceNo) then
                AssignedTotal := ResourceAssignedTotals.Get(ResourceNo);
            FreeCapacity := CapacityTotal - AssignedTotal;
            if FreeCapacity < 0 then
                FreeCapacity := 0;
            if FreeCapacity <> 0 then
                if Resource.Get(ResourceNo) then
                    if ResourceMatchesClassification(Resource, Classification) then
                        ResourceNoList.Add(ResourceNo);
        end;
    end;

    /// <summary>
    /// True if Resource matches Classification (Internal / any External / mandatory-External-only
    /// / non-mandatory-External-only), keyed off "Is External" plus, for the two External
    /// sub-classifications, "Mandatory Schedulling" - shared by GetFreeCapacityResourcesForDate so
    /// its classification logic stays in exactly one place.
    /// </summary>
    local procedure ResourceMatchesClassification(var Resource: Record Resource; Classification: Option Internal,ExternalAny,ExternalMandatory,ExternalNonMandatory): Boolean
    begin
        case Classification of
            Classification::Internal:
                exit(not Resource."Is External");
            Classification::ExternalAny:
                exit(Resource."Is External");
            Classification::ExternalMandatory:
                exit(Resource."Is External" and Resource."Mandatory Schedulling");
            Classification::ExternalNonMandatory:
                exit(Resource."Is External" and not Resource."Mandatory Schedulling");
        end;
    end;

    /// <summary>
    /// Public entry point for callers outside this codeunit's own chart-JSON round trip (currently
    /// codeunit 50604's CPO_ShowCapacityBarSegment, Section 3 of the Capacity Planning Overview/
    /// Dashboard add-ins, src/dhx/capacity_planning_overview) that need this SAME "Free Capacity"
    /// drilldown (true "Res. Capacity Entry" calendar capacity, net of that day's Assigned Hours,
    /// classified Internal/External - see CalcCapacitySplit/GetFreeCapacityResourcesForDate) for
    /// exactly ONE calendar day, addressed by an explicit ClassifyExternal boolean rather than by
    /// matching this codeunit's own SegmentId Label text (CapInternalSeriesNameLbl/
    /// CapExternalSeriesNameLbl are private - and that caller's own JSON payload never carries them
    /// in the first place, since Section 3's bars are no longer built from this codeunit's own
    /// chart data - see that add-in's own architecture-pivot doc comment). Delegates straight to
    /// ShowFreeCapacitySegmentByClassification with DateFrom = DateTo = PlanDate and Classification
    /// Internal/ExternalAny - deliberately bypassing ShowFreeCapacitySegment's own SegmentId-based
    /// mandatory/non-mandatory narrowing (2026-09-16, added only for page 50692's own weekly chart
    /// drilldown - see that procedure's doc comment): CPO's Section 3 has no "mandatory" concept,
    /// so ClassifyExternal = true must keep resolving to External as a whole (mandatory OR
    /// non-mandatory), exactly as before that change.
    /// </summary>
    procedure ShowFreeCapacitySegmentForDate(ClassifyExternal: Boolean; PlanDate: Date)
    var
        Classification: Option Internal,ExternalAny,ExternalMandatory,ExternalNonMandatory;
    begin
        if ClassifyExternal then
            Classification := Classification::ExternalAny
        else
            Classification := Classification::Internal;
        ShowFreeCapacitySegmentByClassification(Classification, PlanDate, PlanDate);
    end;

    /// <summary>
    /// Drilldown for a per-skill segment - the simple case: "Skill" is a plain Day Planning field,
    /// so a direct SetRange suffices (no resource-set resolution needed), matching the existing
    /// drilldown pattern already used by page 50696's DrillDownColumn. Skill segments are only
    /// ever nonzero on the Requested bar for unassigned rows (see
    /// CalcUnassignedSkillRequestedSplit), so the filter is unconditionally "Assigned Resource
    /// No." = '' regardless of which BarType the click actually originated from.
    /// </summary>
    local procedure ShowSkillSegment(SkillCode: Text; DateFrom: Date; DateTo: Date)
    var
        DayPlanning: Record "Day Planning";
    begin
        DayPlanning.Reset();
        DayPlanning.SetRange("Plan Date", DateFrom, DateTo);
        DayPlanning.SetRange(Assigned, false);
        DayPlanning.SetRange(Skill, CopyStr(SkillCode, 1, MaxStrLen(DayPlanning.Skill)));
        Page.Run(Page::"Day Plannings", DayPlanning);
    end;

    /// <summary>
    /// Returns the colour to use for SkillCode's series. Thin forward to codeunit "Color
    /// Constants Opti." (50609) - see that codeunit's GetSkillBarColor for the actual "Bar
    /// Color"-override/5-colour-palette logic, now the single authoritative copy shared with
    /// codeunit 50608's own GetSkillBarColor and codeunit 50604's ResolveRequestedColor. SkillCode
    /// is truncated to Code[10] before the call - see GetSkillBarColor's own doc comment for why
    /// this is a safe truncation, not a real loss of precision.
    /// </summary>
    local procedure GetSkillSeriesColor(SkillCode: Code[20]; PaletteIndex: Integer): Text
    var
        ColorConstants: Codeunit "Visual Default Settings";
    begin
        exit(ColorConstants.GetSkillBarColor(CopyStr(SkillCode, 1, 10), PaletteIndex));
    end;

    /// <summary>
    /// Returns the font/text colour to use for SkillCode's series/legend entry. Thin forward to
    /// codeunit "Visual Default Settings" (50609)'s GetSkillFontColor - same Code[20]->Code[10]
    /// truncation convention as GetSkillSeriesColor above.
    /// </summary>
    local procedure GetSkillSeriesFontColor(SkillCode: Code[20]): Text
    var
        ColorConstants: Codeunit "Visual Default Settings";
    begin
        exit(ColorConstants.GetSkillFontColor(CopyStr(SkillCode, 1, 10)));
    end;

    /// <summary>
    /// Returns the border colour to use for SkillCode's series/legend swatch. Thin forward to
    /// codeunit "Visual Default Settings" (50609)'s GetSkillBorderColor - same Code[20]->Code[10]
    /// truncation convention as GetSkillSeriesColor above. PaletteIndex must be the SAME value
    /// passed to GetSkillSeriesColor for this skill so an unconfigured skill's border falls back
    /// to that same skill's own already-resolved fill colour, not a different palette slot.
    /// </summary>
    local procedure GetSkillSeriesBorderColor(SkillCode: Code[20]; PaletteIndex: Integer): Text
    var
        ColorConstants: Codeunit "Visual Default Settings";
    begin
        exit(ColorConstants.GetSkillBorderColor(CopyStr(SkillCode, 1, 10), PaletteIndex));
    end;

    /// <summary>
    /// Returns one day's (PlanDate's) Assigned/Free Capacity split, Internal/External, plus the
    /// sum of all days in [DateFrom..DateTo] - the same per-day computation
    /// BuildDayCapacityChartData uses for the Capacity bar's 4 stacked segments (CalcAssignedSplit/
    /// CalcCapacitySplit via CalcDaySegments), just summed across a caller-supplied range instead
    /// of always Monday..Sunday. Exists so src/dhx/barchart_daily's single-flat-bar CAPACITY
    /// reference can show the identical Assigned/Free Internal/External breakdown (and, via
    /// GetCapacitySegmentColors below, the identical colours) as this codeunit's own stacked
    /// weekly chart, without duplicating CalcAssignedSplit/CalcCapacitySplit's logic in a second
    /// codeunit. ActiveSkillList is passed as an empty, throwaway list - CalcDaySegments' per-skill
    /// loop then does nothing, since callers of this procedure only ever want the Assigned/Free
    /// totals, never a per-skill breakdown (Daily's per-skill bars already have their own, simpler
    /// flat-value source - see codeunit 50608's BuildSkillBuffer). DateFrom = DateTo is the normal
    /// single-day case; a wider range (e.g. Daily's own week-aggregate mode) sums every day in it.
    /// Thin wrapper over GetCapacitySplitForRangeWithMandatory (2026-09-16) - folds that
    /// procedure's separate CapacityExternalMandatory out-param straight back into the plain
    /// CapacityExternal total here, so this procedure's own external behaviour stays byte-identical
    /// to before the mandatory/non-mandatory split existed. Existing callers (the 3 scheduler pages
    /// - projectschedule/50621, resourceschedule_with_capacity/50706, poolresourceschedule/50600 -
    /// plus barchart_daily's own pre-2026-09-16 usage) must keep seeing this folded total; do NOT
    /// change this procedure's signature or behaviour - add new callers against
    /// GetCapacitySplitForRangeWithMandatory instead.
    /// </summary>
    procedure GetCapacitySplitForRange(DateFrom: Date; DateTo: Date; var AssignedInternal: Decimal; var AssignedExternal: Decimal; var CapacityInternal: Decimal; var CapacityExternal: Decimal)
    var
        CapacityExternalMandatory: Decimal;
    begin
        GetCapacitySplitForRangeWithMandatory(DateFrom, DateTo, AssignedInternal, AssignedExternal, CapacityInternal, CapacityExternal, CapacityExternalMandatory);
        // The mandatory/non-mandatory external split (2026-09-16, page 50692's weekly chart and,
        // since this session, barchart_daily's own CAPACITY reference bar) is added straight back
        // into the plain External total here so THIS procedure's remaining callers (the 3
        // scheduler pages) see byte-identical totals to before the split existed.
        CapacityExternal += CapacityExternalMandatory;
    end;

    /// <summary>
    /// Same computation as GetCapacitySplitForRange above, but keeps the Free Capacity - External
    /// total split into its non-mandatory and Mandatory Schedulling portions instead of folding
    /// them back together - added 2026-09-16 so src/dhx/barchart_daily's CAPACITY reference bar can
    /// show its own "Free Capacity - External (Mandatory)" segment, matching page 50692's weekly
    /// chart. GetCapacitySplitForRange is now a thin wrapper over this procedure - see its own doc
    /// comment. Only barchart_daily (via codeunit 50608's GetCapacityAssignedFreeSplit) should call
    /// this directly; the 3 scheduler pages keep using the folded GetCapacitySplitForRange.
    /// </summary>
    procedure GetCapacitySplitForRangeWithMandatory(DateFrom: Date; DateTo: Date; var AssignedInternal: Decimal; var AssignedExternal: Decimal; var CapacityInternal: Decimal; var CapacityExternal: Decimal; var CapacityExternalMandatory: Decimal)
    var
        ActiveSkillList: List of [Code[20]];
        SkillInternalValues: Dictionary of [Code[20], Decimal];
        SkillExternalValues: Dictionary of [Code[20], Decimal];
        CurrDate: Date;
        DayAssignedInternal: Decimal;
        DayAssignedExternal: Decimal;
        DayCapacityInternal: Decimal;
        DayCapacityExternal: Decimal;
        DayCapacityExternalMandatory: Decimal;
    begin
        AssignedInternal := 0;
        AssignedExternal := 0;
        CapacityInternal := 0;
        CapacityExternal := 0;
        CapacityExternalMandatory := 0;

        EnsureDayPlanningBuffer(DateFrom, DateTo);

        CurrDate := DateFrom;
        while CurrDate <= DateTo do begin
            CalcDaySegments(CurrDate, ActiveSkillList, DayAssignedInternal, DayAssignedExternal, DayCapacityInternal, DayCapacityExternal, DayCapacityExternalMandatory, SkillInternalValues, SkillExternalValues);
            AssignedInternal += DayAssignedInternal;
            AssignedExternal += DayAssignedExternal;
            CapacityInternal += DayCapacityInternal;
            CapacityExternal += DayCapacityExternal;
            CapacityExternalMandatory += DayCapacityExternalMandatory;
            CurrDate += 1;
        end;
    end;

    /// <summary>
    /// Returns this codeunit's own effective Assigned/Free-Capacity/ExternalBorder colours. Thin
    /// forward to codeunit "Color Constants Opti." (50609) - kept here (same name/signature) so
    /// existing callers - currently src/dhx/barchart_daily's CAPACITY reference bar (via that
    /// codeunit's own forwarding call) and all three scheduler pages (projectschedule/50621,
    /// resourceschedule_with_capacity/50706, poolresourceschedule/50600), which all call this
    /// procedure directly from their ControlReady triggers - need zero changes.
    /// </summary>
    procedure GetCapacitySegmentColors(var AssignedColor: Text; var CapacityColor: Text; var ExternalBorderColor: Text)
    var
        ColorConstants: Codeunit "Visual Default Settings";
    begin
        ColorConstants.GetCapacitySegmentColors(AssignedColor, CapacityColor, ExternalBorderColor);
    end;

    /// <summary>
    /// Returns the Capacity event/bar's own border colour for the two live scheduler-timeline
    /// pages (resourceschedule_with_capacity/50706, poolresourceschedule/50600) - a different
    /// setting from GetCapacitySegmentColors' ExternalBorderColor above, which only affects the
    /// Daily/Weekly bar charts. Thin forward to codeunit "Visual Default Settings" (50609), same
    /// shape as GetCapacitySegmentColors above.
    /// </summary>
    procedure GetCapacityBorderColor(): Text
    var
        ColorConstants: Codeunit "Visual Default Settings";
    begin
        exit(ColorConstants.GetCapacityBorderColor());
    end;

    /// <summary>
    /// Returns the fill colour for the "Free Capacity - External (Mandatory)" segment (2026-09-16)
    /// - the mandatory-scheduled portion of Free Capacity - External, split out from the plain
    /// non-mandatory segment on both this chart (page 50692) and, since this session,
    /// src/dhx/barchart_daily's own CAPACITY reference bar. Thin forward to codeunit "Visual
    /// Default Settings" (50609)'s own GetCapacityMandatoryColor, same shape as
    /// GetCapacitySegmentColors/GetCapacityBorderColor above - added so barchart_daily's codeunit
    /// 50608 can go through this codeunit for the colour, matching its own documented convention
    /// of forwarding through 50662 rather than calling 50609 directly (see its own
    /// GetCapacitySegmentColors forward).
    /// </summary>
    procedure GetCapacityMandatoryColor(): Text
    var
        ColorConstants: Codeunit "Visual Default Settings";
    begin
        exit(ColorConstants.GetCapacityMandatoryColor());
    end;

    /// <summary>
    /// Returns the text/caption colour used on every event bar's on-bar label across the Gantt
    /// chart, the scheduler timeline pages (resourceschedule_with_capacity/50706,
    /// poolresourceschedule/50600, projectschedule/50621), and the Day Planning bar's label. Thin
    /// forward to codeunit "Visual Default Settings" (50609), same shape as
    /// GetCapacityBorderColor above.
    /// </summary>
    procedure GetBarFontColor(): Text
    var
        ColorConstants: Codeunit "Visual Default Settings";
    begin
        exit(ColorConstants.GetBarFontColor());
    end;

    /// <summary>
    /// Appends one series object (name/values/color/[border]/[fontColor]/stacked) to SeriesArray,
    /// matching the exact JSON contract src/dhx/barchart_weekly/wrapper.js's RenderChart expects.
    /// BorderHex/FontColorHex may be blank to omit the optional "border"/"fontColor" keys.
    /// FontColorHex is consumed by wrapper.js's ApplyLegendSwatchBorders (per-skill legend TEXT
    /// colour, codeunit 50609's GetSkillFontColor - reuses that function's existing de-dup-aware
    /// legend-ownership lookup, the same one already applies each skill's border to its legend
    /// swatch) - only ever passed for the per-skill series below, never for the shared Assigned/
    /// Capacity segments (which have no Skill of their own).
    /// </summary>
    local procedure AddChartSeries(var SeriesArray: JsonArray; SeriesName: Text; Values: List of [Decimal]; ColorHex: Text; BorderHex: Text; FontColorHex: Text)
    var
        SeriesObj: JsonObject;
        ValuesArray: JsonArray;
        Val: Decimal;
    begin
        Clear(ValuesArray);
        foreach Val in Values do
            ValuesArray.Add(Val);

        SeriesObj.Add('name', SeriesName);
        SeriesObj.Add('values', ValuesArray);
        SeriesObj.Add('color', ColorHex);
        if BorderHex <> '' then
            SeriesObj.Add('border', BorderHex);
        if FontColorHex <> '' then
            SeriesObj.Add('fontColor', FontColorHex);
        SeriesObj.Add('stacked', true);

        SeriesArray.Add(SeriesObj);
    end;

    var
        // Codeunit-instance-level cache for the current period's Day Planning rows - see
        // EnsureDayPlanningBuffer. Deliberately `temporary`: Reset()+SetRange()+FindSet() against
        // it is an in-process scan, not a SQL round-trip, so every consumer below can freely
        // re-filter it without repeated database queries. Every procedure that filters
        // GDayPlanningBuf resets its filters (Reset()) before returning, so the buffer is always
        // handed back clean/unfiltered for the next caller; none of these procedures call each
        // other while mid-iteration over GDayPlanningBuf, so there is no re-entrancy risk from
        // sharing one Record instance.
        GDayPlanningBuf: Record "Day Planning" temporary;
        GBufferDateFrom: Date;
        GBufferDateTo: Date;
        GBufferLoaded: Boolean;
        // Codeunit-instance-level cache for the current period's "Res. Capacity Entry" rows - see
        // EnsureResCapacityBuffer. Added as a perf fix (2026-09-14, Capacity Planning Overview
        // slow-load investigation): CalcCapacitySplit used to re-query this table, company-wide,
        // filtered to a single Date, on EVERY call - with no caching across days, unlike
        // GDayPlanningBuf's own already-buffered per-range load immediately above. A caller
        // looping one day at a time over an N-day window (BuildDayCapacityChartDataForRange /
        // page 50722's own PrepareDailyCapacityBuffer+GetDailyCapacitySplit loop) therefore paid N
        // separate company-wide physical scans instead of ONE.
        GResCapacityBuf: Record "Res. Capacity Entry" temporary;
        GResCapBufferDateFrom: Date;
        GResCapBufferDateTo: Date;
        GResCapBufferLoaded: Boolean;
        AssInternalSeriesNameLbl: Label 'Assigned Capacity - Internal';
        AssExternalSeriesNameLbl: Label 'Assigned Capacity - External';
        AssignedCapacitySeriesNameLbl: Label 'Assigned Capacity';
        CapInternalSeriesNameLbl: Label 'Free Capacity - Internal';
        CapExternalSeriesNameLbl: Label 'Free Capacity - External';
        CapExternalMandatorySeriesNameLbl: Label 'Free Capacity - External (Mandatory)';
        FreeCapacityCategoryLbl: Label 'Capacity';
        RequestedCategoryLbl: Label 'Requested';
        CategoryDelimiterTok: Label '|', Locked = true;
        AssignedSegmentTok: Label 'Assigned', Locked = true;
        InternalSegmentTok: Label 'Internal', Locked = true;
        ExternalSegmentTok: Label 'External', Locked = true;
        ExternalMandatorySegmentTok: Label 'External (Mandatory)', Locked = true;
        CapSegmentPrefixLbl: Label 'Cap. ';
        ReqSegmentPrefixLbl: Label 'Req. ';
        NoSkillSegmentLbl: Label '(No Skill)';
        CapacityBarTypeTok: Label 'Capacity', Locked = true;
        NoMatchingDataMsg: Label 'No records match this chart segment.';
}
