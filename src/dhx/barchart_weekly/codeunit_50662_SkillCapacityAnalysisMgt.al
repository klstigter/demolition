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

    /// <summary>
    /// Builds the Requested Hours (per skill) / Capacity (single aggregate) buffer for the
    /// supplied filters. DateFromFilter/DateToFilter are optional; blank means "no filter".
    /// </summary>
    procedure BuildSkillBuffer(var Buffer: Record "Skill Req. vs Capacity Buffer" temporary; DateFromFilter: Date; DateToFilter: Date)
    var
        DayPlanning: Record "Day Planning";
        DateRc: Record Date;
        WkDayNo: Integer;
        BarType: Enum "Day Capacity Chart Bar Type";
    begin
        Buffer.Reset();
        Buffer.DeleteAll();
        DateRc.setrange("Period Type", DateRc."Period Type"::Date);
        DateRc.setrange("Period Start", DateFromFilter, DateToFilter);
        DateRc.findset();
        repeat
            this.CalcFiltersDayPlanning(DayPlanning, DateRc."Period Start");
            WkDayNo := Date2DWY(DateRc."Period Start", 1);
            repeat
                dayplanning.setrange(Skill, dayplanning.skill);
                dayplanning.CalcSums("Requested Hours");
                insertBufferLine(Buffer, BarType::Requested, dayplanning.skill, WkDayNo, dayplanning."Requested Hours");
                if dayplanning.FindLast() then;
                dayplanning.setrange(Skill);
            until DayPlanning.Next() = 0;
            this.CalcFreeCapacity(Buffer, DateRc."Period Start");
        until DateRc.next() = 0;
        Buffer.Reset();
        if Buffer.FindFirst() then;
    end;

    local procedure CalcFiltersDayPlanning(var DayPlanning: Record "Day Planning"; DateFilter: Date)
    begin
        DayPlanning.Reset();
        DayPlanning.SetCurrentKey("Plan Date", Skill, "Assigned Resource No.");
        DayPlanning.SetFilter("Assigned Resource No.", '=%1', '');
        DayPlanning.SetRange("Plan Date", DateFilter);
    end;

    /// <summary>
    /// Sums "Res. Capacity Entry".Capacity for the given Resource No. / Date range filters,
    /// using the same partial-range logic as ApplyDayPlanningFilters. Deliberately has no
    /// Skill Code parameter - capacity is a resource/date total, not a per-skill figure.
    /// </summary>
    local procedure CalcFreeCapacity(var Buffer: Record "Skill Req. vs Capacity Buffer" temporary; DateFilter: Date): Decimal
    var
        ResCapacityEntry: Record "Res. Capacity Entry";
        DayPlan: Record "Day Planning";
        TempResource: Record Resource temporary;
        Resource: Record Resource;
        WkDayNo: Integer;
        FreeCapacity: Decimal;
        TotalFreeCapacity: array[2] of Decimal;
        TotalAssigned: Decimal;
        BarType: Enum "Day Capacity Chart Bar Type";
        External: Boolean;
    begin
        WkDayNo := Date2DWY(DateFilter, 1);
        ResCapacityEntry.SetLoadFields("Resource No.");
        ResCapacityEntry.SetRange(Date, DateFilter);
        if resCapacityEntry.FindSet() then
            repeat
                if Not TempResource.Get(ResCapacityEntry."Resource No.") then begin
                    TempResource."No." := ResCapacityEntry."Resource No.";
                    tempResource.Insert();
                end;
            until ResCapacityEntry.Next() = 0;
        DayPlan.SetLoadFields("Plan Date", "Assigned Resource No.", "Assigned Hours");
        DayPlan.SetRange("Assigned Resource No.", '<>%1', '');
        dayPlan.SetRange("Plan Date", DateFilter);
        if dayPlan.FindSet() then
            repeat
                if not tempResource.Get(dayPlan."Assigned Resource No.") then begin
                    tempResource."No." := dayPlan."Assigned Resource No.";
                    tempResource.Insert();
                end;
            until dayPlan.Next() = 0;
        if tempResource.FindSet() then
            repeat
                resource.Get(tempResource."No.");
                External := resource."Is External" OR Resource."Is Pool" OR Resource."Is Pool Member";
                tempResource.calcfields("Assigned Hours", "Capacity");
                FreeCapacity := tempResource."Capacity" - tempResource."Assigned Hours";
                If FreeCapacity < 0 then
                    freeCapacity := 0;
                if FreeCapacity <> 0 then
                    if External then
                        TotalFreeCapacity[1] += FreeCapacity
                    else
                        TotalFreeCapacity[2] += FreeCapacity;
                if tempResource."Assigned Hours" <> 0 then
                    TotalAssigned += tempResource."Assigned Hours";
            until tempResource.Next() = 0;

        if TotalFreeCapacity[1] <> 0 then
            InsertBufferLine(Buffer, BarType::Capacity, ExternalSegmentTok, WkDayNo, TotalFreeCapacity[1]);
        if TotalFreeCapacity[2] <> 0 then
            InsertBufferLine(Buffer, BarType::Capacity, InternalSegmentTok, WkDayNo, TotalFreeCapacity[2]);
        if TotalAssigned <> 0 then begin
            InsertBufferLine(Buffer, BarType::Capacity, 'Assigned', WkDayNo, TotalAssigned);
            InsertBufferLine(Buffer, BarType::Requested, 'Assigned', WkDayNo, TotalAssigned);
        end;

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
    /// Each category is a stack of series segments, bottom to top: "Assigned Capacity -
    /// Internal"/"Assigned Capacity - External", then "Free Capacity - Internal"/"Free Capacity -
    /// External" (Capacity bar only - see CalcCapacitySplit), then one internal/external pair per
    /// Skill Code that has at least one unassigned ("Assigned Resource No." = '') Day Planning row
    /// with nonzero Requested Hours somewhere in the period. Every segment is declared as an
    /// internal/external SERIES PAIR (an "internal" series with plain fill/no border, then an
    /// "external" series with the same fill colour but a red border, so an external portion is
    /// visually provable at a glance; declared immediately after its own internal half so it
    /// stacks directly on top of it - wrapper.js stacking (suite.js's Stacker.dataReady)
    /// accumulates each series' baseline from the PREVIOUS series in declaration order). Each of
    /// the four Assigned/free-capacity series has its own distinct series name, so each renders
    /// its own legend entry (wrapper.js's legend only collapses series that SHARE a name - see
    /// its own header comment - which now only happens among the internal/external halves of a
    /// given skill's segment pair, not here). Which BAR each pair is allowed to actually split on
    /// differs by segment:
    ///   - "Assigned Capacity - Internal"/"Assigned Capacity - External": the Capacity bar keeps
    ///                  the real internal/external split (via CalcAssignedSplit). The Requested
    ///                  bar deliberately COLLAPSES this to a single plain total - the internal
    ///                  series gets the combined (internal + external) value, the external series
    ///                  is always 0 - so the Requested bar's Assigned block never shows a red
    ///                  border.
    ///   - "Free Capacity - Internal"/"Free Capacity - External": Capacity-bar-only, unchanged -
    ///                  see below.
    ///   - Skill segments: Requested-bar-only, and use the same collapse as Assigned - the
    ///                  internal series gets the combined (internal + external) value for that
    ///                  skill/day, the external series is always 0.
    /// Net effect: the CAPACITY bar always shows its full Internal/External breakdown (both the
    /// Assigned split and the free-capacity split below); the REQUESTED bar never shows an
    /// Internal/External distinction anywhere - every segment on it (Assigned, each skill) is a
    /// single plain-coloured block carrying a combined total, with its paired "external" series
    /// always 0.
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
        IncludedDay: array[7] of Boolean;
        SkillCode: Code[20];
        WeekdayIndex: Integer;
        CurrDate: Date;
        AssInternalD: Decimal;
        AssExternalD: Decimal;
        CapInternalD: Decimal;
        CapExternalD: Decimal;
        SkillPaletteIdx: Integer;
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
        Clear(AssInternalValues);
        Clear(AssExternalValues);
        Clear(CapInternalValues);
        Clear(CapExternalValues);
        for WeekdayIndex := 1 to 7 do begin
            CurrDate := PeriodStartDate + (WeekdayIndex - 1);

            CalcDaySegments(CurrDate, ActiveSkillList, AssInternalD, AssExternalD, CapInternalD, CapExternalD, OneDaySkillInternalValues, OneDaySkillExternalValues);

            IncludedDay[WeekdayIndex] := DayHasAnyChartData(AssInternalD, AssExternalD, CapInternalD, CapExternalD, ActiveSkillList, OneDaySkillInternalValues, OneDaySkillExternalValues);
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

            // Capacity bar keeps its own Internal/External split. Requested bar collapses the
            // Assigned segment to a single plain total - no Internal/External distinction - so
            // the Internal series carries the combined total and the External series is always 0,
            // rendering as one plain-coloured block with no red border.
            AssInternalValues.Add(AssInternalD);
            AssInternalValues.Add(AssInternalD + AssExternalD);
            AssExternalValues.Add(AssExternalD);
            AssExternalValues.Add(0);

            // Free capacity (Internal/External) is a Capacity-bar-only concept - Capacity bar
            // value, then 0 for the Requested bar position (the mirror image of how skill
            // segments below are 0 on the Capacity bar position).
            CapInternalValues.Add(CapInternalD);
            CapInternalValues.Add(0);
            CapExternalValues.Add(CapExternalD);
            CapExternalValues.Add(0);

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

        AddChartSeries(SeriesArray, AssInternalSeriesNameLbl, AssInternalValues, AssColorTok, '');
        AddChartSeries(SeriesArray, AssExternalSeriesNameLbl, AssExternalValues, AssColorTok, ExternalBorderColorTok);
        AddChartSeries(SeriesArray, CapInternalSeriesNameLbl, CapInternalValues, CapacityColorTok, '');
        AddChartSeries(SeriesArray, CapExternalSeriesNameLbl, CapExternalValues, CapacityColorTok, ExternalBorderColorTok);

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
            AddChartSeries(SeriesArray, SkillCode, SkillInternalValues, GetSkillSeriesColor(SkillCode, SkillPaletteIdx), '');
            AddChartSeries(SeriesArray, SkillCode, SkillExternalValues, GetSkillSeriesColor(SkillCode, SkillPaletteIdx), ExternalBorderColorTok);
            SkillPaletteIdx += 1;
        end;

        ChartData.Add('categories', CategoriesArray);
        ChartData.Add('dayLabels', DayLabelsArray);
        ChartData.Add('dayIndices', DayIndicesArray);
        ChartData.Add('series', SeriesArray);
        ChartData.WriteTo(ChartDataJson);
    end;

    /// <summary>
    /// True if PlanDate's segment values carry ANY nonzero data anywhere - Assigned (internal or
    /// external), free Capacity (internal or external), or any active skill's requested hours
    /// (internal or external) - used by BuildDayCapacityChartData to decide whether that day gets
    /// its own category pair/values at all. Deliberately NOT used by BuildDayCapacityAuditBuffer,
    /// which always shows all 7 days by design (see its own doc comment).
    /// </summary>
    local procedure DayHasAnyChartData(AssignedInternal: Decimal; AssignedExternal: Decimal; CapacityInternal: Decimal; CapacityExternal: Decimal; var ActiveSkillList: List of [Code[20]]; var SkillInternalValues: Dictionary of [Code[20], Decimal]; var SkillExternalValues: Dictionary of [Code[20], Decimal]): Boolean
    var
        SkillCode: Code[20];
    begin
        if (AssignedInternal <> 0) or (AssignedExternal <> 0) or (CapacityInternal <> 0) or (CapacityExternal <> 0) then
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
    /// bar, free Internal/External capacity is always 0 on the Requested bar - they still get a
    /// row). Skills outside BuildActiveSkillList's result get no rows at all, matching the
    /// chart's own behavior. Rows are inserted in the same left-to-right order as the chart's
    /// bars: for each weekday Monday..Sunday, first the Capacity bar's rows ("Assigned" combined
    /// total, then free "Internal"/"External" capacity, then each active skill's 0-valued pair),
    /// then the Requested bar's rows ("Assigned" combined total, 0-valued "Internal"/"External",
    /// then each active skill's own combined total on the first row and 0 on the second) - the
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
        LineNo: Integer;
    begin
        Buffer.Reset();
        Buffer.DeleteAll();

        EnsureDayPlanningBuffer(PeriodStartDate, PeriodStartDate + 6);

        BuildActiveSkillList(ActiveSkillList);

        LineNo := 0;
        for WeekdayIndex := 1 to 7 do begin
            CurrDate := PeriodStartDate + (WeekdayIndex - 1);

            CalcDaySegments(CurrDate, ActiveSkillList, AssignedInternal, AssignedExternal, CapacityInternal, CapacityExternal, SkillInternalValues, SkillExternalValues);

            // Capacity bar: "Assigned" carries the day's combined (internal+external) assigned
            // hours, "Internal"/"External" carry TRUE free calendar capacity (Res. Capacity Entry
            // net of Assigned Hours - see CalcCapacitySplit), skills are always 0 (skills never
            // appear on the Capacity bar).
            LineNo += 1;
            InsertAuditLine(Buffer, LineNo, CurrDate, Enum::"Day Capacity Chart Bar Type"::Capacity, AssignedSegmentTok, AssignedInternal + AssignedExternal);
            LineNo += 1;
            InsertAuditLine(Buffer, LineNo, CurrDate, Enum::"Day Capacity Chart Bar Type"::Capacity, InternalSegmentTok, CapacityInternal);
            LineNo += 1;
            InsertAuditLine(Buffer, LineNo, CurrDate, Enum::"Day Capacity Chart Bar Type"::Capacity, ExternalSegmentTok, CapacityExternal);
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
    local procedure CalcDaySegments(PlanDate: Date; var ActiveSkillList: List of [Code[20]]; var AssignedInternal: Decimal; var AssignedExternal: Decimal; var CapacityInternal: Decimal; var CapacityExternal: Decimal; var SkillInternalValues: Dictionary of [Code[20], Decimal]; var SkillExternalValues: Dictionary of [Code[20], Decimal])
    var
        SkillCode: Code[20];
        SkillInternalD: Decimal;
        SkillExternalD: Decimal;
    begin
        Clear(SkillInternalValues);
        Clear(SkillExternalValues);

        CalcAssignedSplit(PlanDate, AssignedInternal, AssignedExternal);
        CalcCapacitySplit(PlanDate, CapacityInternal, CapacityExternal);

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
        DayPlanning.SetLoadFields("Plan Date", Skill, "Assigned Resource No.", "Assigned Hours", "Requested Hours", "Requested Resource No.");
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
    end;

    /// <summary>
    /// Determines which Skill Codes get their own chart series: any skill with at least one
    /// unassigned ("Assigned Resource No." = '') Day Planning row whose "Requested Hours" sum
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
        GDayPlanningBuf.SetRange("Assigned Resource No.", '');
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
        GDayPlanningBuf.SetFilter("Assigned Resource No.", '<>%1', '');
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
    /// barchart_daily page it alone serves. Caller must have already ensured GDayPlanningBuf is
    /// loaded for a range covering PlanDate.
    /// </summary>
    local procedure CalcCapacitySplit(PlanDate: Date; var InternalCapacity: Decimal; var ExternalCapacity: Decimal)
    var
        ResCapacityEntry: Record "Res. Capacity Entry";
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
            GDayPlanningBuf.SetFilter("Assigned Resource No.", '<>%1', '');
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
                    if External then
                        ExternalCapacity += FreeCapacity
                    else
                        InternalCapacity += FreeCapacity;
                end;
        end;
    end;

    /// <summary>
    /// Splits "Requested Hours" for unassigned ("Assigned Resource No." = '') Day Planning rows
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
        GDayPlanningBuf.SetRange("Assigned Resource No.", '');
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
    /// declared below, e.g. AssInternalSeriesNameLbl/CapExternalSeriesNameLbl, or a bare Skill
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
            AssInternalSeriesNameLbl, AssExternalSeriesNameLbl:
                ShowAssignedCapacitySegment(SegmentId, BarType, DateFrom, DateTo, WholeWeek);
            CapInternalSeriesNameLbl, CapExternalSeriesNameLbl:
                ShowFreeCapacitySegment(SegmentId, DateFrom, DateTo);
            else
                ShowSkillSegment(SegmentId, DateFrom, DateTo);
        end;
    end;

    /// <summary>
    /// Drilldown for "Assigned Capacity - Internal"/"External". Day Planning has no field storing
    /// the assigned resource's own "Is External" flag, so the classified resource set is computed
    /// first (BuildAssignedResourceSet) and then turned into a plain "Assigned Resource No." OR
    /// filter (BuildCodeOrFilter - same helper/pattern already used by page 50704's own
    /// Internal/External OnDrillDown) before opening "Day Plannings".
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
    /// The Internal/External classification only applies when UseClassification is true - true
    /// for WholeWeek (legend) clicks and for a click on the CAPACITY bar's own Assigned segment,
    /// both of which represent this series' real, always-classified identity. A click on the
    /// REQUESTED bar's Assigned segment is the one exception: per BuildDayCapacityChartData's own
    /// doc comment, that segment is a deliberately collapsed combined total (the "external" series
    /// is always 0 there), so its drilldown shows ALL assigned rows for that day regardless of the
    /// assigned resource's Is External flag - matching what the plotted number actually represents.
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
        UseClassification := WholeWeek or (BarType = CapacityBarTypeTok);

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
        DayPlanning.SetLoadFields("Assigned Resource No.");
        DayPlanning.SetRange("Plan Date", DateFrom, DateTo);
        DayPlanning.SetFilter("Assigned Resource No.", '<>%1', '');
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
    /// </summary>
    local procedure ShowFreeCapacitySegment(SegmentId: Text; DateFrom: Date; DateTo: Date)
    var
        ResCapacityEntry: Record "Res. Capacity Entry";
        DateResourceList: List of [Code[20]];
        UnionResourceList: List of [Code[20]];
        SeenResources: Dictionary of [Code[20], Boolean];
        ClassifyExternal: Boolean;
        CurrDate: Date;
        ResourceNo: Code[20];
        ResourceNoFilterText: Text;
    begin
        ClassifyExternal := (SegmentId = CapExternalSeriesNameLbl);

        EnsureDayPlanningBuffer(DateFrom, DateTo);

        CurrDate := DateFrom;
        while CurrDate <= DateTo do begin
            Clear(DateResourceList);
            GetFreeCapacityResourcesForDate(CurrDate, ClassifyExternal, DateResourceList);
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
    /// that day's Day Planning Assigned Hours, floored at 0) on PlanDate whose Resource."Is
    /// External" matches ClassifyExternal - the same computation as CalcCapacitySplit, but
    /// collecting the contributing resource numbers instead of summing their totals. Kept as its
    /// own procedure (deliberately not refactored to share CalcCapacitySplit's body) so this new
    /// drilldown path cannot accidentally change the chart's own totals. Reads/relies on the
    /// shared GDayPlanningBuf being already loaded for a range covering PlanDate - caller
    /// (ShowFreeCapacitySegment) calls EnsureDayPlanningBuffer first.
    /// </summary>
    local procedure GetFreeCapacityResourcesForDate(PlanDate: Date; ClassifyExternal: Boolean; var ResourceNoList: List of [Code[20]])
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
            GDayPlanningBuf.SetFilter("Assigned Resource No.", '<>%1', '');
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
                    if Resource."Is External" = ClassifyExternal then
                        ResourceNoList.Add(ResourceNo);
        end;
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
        DayPlanning.SetRange("Assigned Resource No.", '');
        DayPlanning.SetRange(Skill, CopyStr(SkillCode, 1, MaxStrLen(DayPlanning.Skill)));
        Page.Run(Page::"Day Plannings", DayPlanning);
    end;

    /// <summary>
    /// Returns the colour to use for SkillCode's series. If the "Skill Code" record has a
    /// non-blank "Bar Color" override, that takes precedence; otherwise cycles through a fixed
    /// 5-colour palette for skill series beyond the fixed Assigned/Internal/External ones, so any
    /// number of active skills always gets a colour.
    /// </summary>
    local procedure GetSkillSeriesColor(SkillCode: Code[20]; PaletteIndex: Integer): Text
    var
        SkillCodeRec: Record "Skill Code";
        Palette: array[5] of Text[10];
        BarColor: Text;
    begin
        if SkillCodeRec.Get(SkillCode) then begin
            BarColor := SkillCodeRec."Bar Color".Trim();
            if BarColor <> '' then
                exit(BarColor);
        end;

        Palette[1] := '#C55A11';
        Palette[2] := '#ED7D31';
        Palette[3] := '#F4B183';
        Palette[4] := '#F8CBAD';
        Palette[5] := '#FBE5D6';
        exit(Palette[(PaletteIndex mod 5) + 1]);
    end;

    /// <summary>
    /// Appends one series object (name/values/color/[border]/stacked) to SeriesArray, matching
    /// the exact JSON contract src/dhx/barchart_weekly/wrapper.js's RenderChart expects. BorderHex may
    /// be blank to omit the optional "border" key.
    /// </summary>
    local procedure AddChartSeries(var SeriesArray: JsonArray; SeriesName: Text; Values: List of [Decimal]; ColorHex: Text; BorderHex: Text)
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
        AssInternalSeriesNameLbl: Label 'Assigned Capacity - Internal';
        AssExternalSeriesNameLbl: Label 'Assigned Capacity - External';
        CapInternalSeriesNameLbl: Label 'Free Capacity - Internal';
        CapExternalSeriesNameLbl: Label 'Free Capacity - External';
        FreeCapacityCategoryLbl: Label 'Capacity';
        RequestedCategoryLbl: Label 'Requested';
        CategoryDelimiterTok: Label '|', Locked = true;
        AssColorTok: Label '#548235', Locked = true;
        CapacityColorTok: Label '#2E75B6', Locked = true;
        ExternalBorderColorTok: Label '#FF0000', Locked = true;
        AssignedSegmentTok: Label 'Assigned', Locked = true;
        InternalSegmentTok: Label 'Internal', Locked = true;
        ExternalSegmentTok: Label 'External', Locked = true;
        CapSegmentPrefixLbl: Label 'Cap. ';
        ReqSegmentPrefixLbl: Label 'Req. ';
        NoSkillSegmentLbl: Label '(No Skill)';
        CapacityBarTypeTok: Label 'Capacity', Locked = true;
        NoMatchingDataMsg: Label 'No records match this chart segment.';
}
