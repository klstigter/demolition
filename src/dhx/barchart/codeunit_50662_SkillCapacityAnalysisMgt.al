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
    /// ready to hand straight to CurrPage.DhxBarChart.LoadData. Covers Monday..Friday only
    /// (PeriodStartDate is expected to already be a Monday, same convention as the page's own
    /// PeriodStartDate) - two categories per weekday ("<Wkd>|Capacity" / "<Wkd>|Requested",
    /// left-to-right, Capacity first - still unique per bar for DHTMLX's positioning, but
    /// wrapper.js's textTemplate strips the "<Wkd>|" prefix for display), with the weekday name
    /// ALSO carried separately in the top-level "dayLabels" array (one entry per day, same
    /// order) so wrapper.js can render it as its own merged row spanning that day's 2 bars.
    /// Each category is a stack of series segments, bottom to top: "Assigned" (internal half,
    /// then external half), then one internal/external pair per Skill Code that has at least one
    /// unassigned ("Assigned Resource No." = '') Day Planning row with nonzero Requested Hours
    /// somewhere in the period. Every segment follows the same internal/external pattern:
    ///   - internal half: plain fill, no border.
    ///   - external half: same fill colour as its own internal half (same legend swatch -
    ///                  wrapper.js's legend only lists the FIRST series with a given label, so
    ///                  the two halves collapse to one entry) but with a red border, so the
    ///                  external portion of that category is visually provable at a glance.
    ///                  Declared immediately after its own internal half, so it stacks directly
    ///                  on top of it - wrapper.js stacking (suite.js's Stacker.dataReady)
    ///                  accumulates each series' baseline from the PREVIOUS series in declaration
    ///                  order, so a later-declared series ends up further from the axis.
    /// "Assigned" (both halves) is identical on both the Capacity and Requested bar for that day.
    /// Skill segments (both halves) are only ever nonzero on the Requested bar (0 on the Capacity
    /// bar). There is no separate free-capacity "Internal"/"External" series - a day's remaining
    /// (unassigned) capacity is not represented on this chart at all, only assigned/requested
    /// hours are.
    /// </summary>
    procedure BuildDayCapacityChartData(PeriodStartDate: Date) ChartDataJson: Text
    var
        ChartData: JsonObject;
        CategoriesArray: JsonArray;
        DayLabelsArray: JsonArray;
        SeriesArray: JsonArray;
        AssInternalValues: List of [Decimal];
        AssExternalValues: List of [Decimal];
        SkillInternalValues: List of [Decimal];
        SkillExternalValues: List of [Decimal];
        ActiveSkillList: List of [Code[20]];
        OneDaySkillInternalValues: Dictionary of [Code[20], Decimal];
        OneDaySkillExternalValues: Dictionary of [Code[20], Decimal];
        AllDaySkillInternalValues: Dictionary of [Text, Decimal];
        AllDaySkillExternalValues: Dictionary of [Text, Decimal];
        SkillCode: Code[20];
        WeekdayIndex: Integer;
        CurrDate: Date;
        AssInternalD: Decimal;
        AssExternalD: Decimal;
        SkillPaletteIdx: Integer;
    begin
        EnsureDayPlanningBuffer(PeriodStartDate, PeriodStartDate + 4);

        // Each category is "<Wkd>|Capacity" / "<Wkd>|Requested" - still unique per bar (the
        // DHTMLX "text" scale positions each bar by looking up its own category value, so
        // duplicate values across different days would collapse those bars onto the same x-slot
        // - see wrapper.js's RenderChart comment) - but wrapper.js's textTemplate strips
        // everything up to and including the "|" for display, so the tick only ever shows
        // "Capacity"/"Requested". The weekday itself is ALSO carried separately in "dayLabels"
        // (one entry per day, same left-to-right order) so wrapper.js can render its own merged
        // row spanning that day's 2 bars, without parsing weekday text back out of a category.
        Clear(CategoriesArray);
        Clear(DayLabelsArray);
        for WeekdayIndex := 1 to 5 do begin
            CurrDate := PeriodStartDate + (WeekdayIndex - 1);
            CategoriesArray.Add(FormatWeekdayShort(CurrDate) + CategoryDelimiterTok + FreeCapacityCategoryLbl);
            CategoriesArray.Add(FormatWeekdayShort(CurrDate) + CategoryDelimiterTok + RequestedCategoryLbl);
            DayLabelsArray.Add(FormatWeekdayShort(CurrDate));
        end;

        BuildActiveSkillList(ActiveSkillList);

        Clear(AssInternalValues);
        Clear(AssExternalValues);
        for WeekdayIndex := 1 to 5 do begin
            CurrDate := PeriodStartDate + (WeekdayIndex - 1);

            CalcDaySegments(CurrDate, ActiveSkillList, AssInternalD, AssExternalD, OneDaySkillInternalValues, OneDaySkillExternalValues);

            // Capacity bar value, then Requested bar value - both halves of Assigned are
            // identical on both bars, same as the old single "Assigned" series was.
            AssInternalValues.Add(AssInternalD);
            AssInternalValues.Add(AssInternalD);
            AssExternalValues.Add(AssExternalD);
            AssExternalValues.Add(AssExternalD);

            // Stash this day's per-skill values (keyed by weekday+skill) so the per-skill series
            // loop below can reuse them instead of recomputing via CalcDaySegments again - AL has
            // no array-of-Dictionary type, so a single Dictionary keyed by a composite Text key
            // stands in for a per-weekday array of dictionaries.
            foreach SkillCode in ActiveSkillList do begin
                AllDaySkillInternalValues.Set(Format(WeekdayIndex) + '|' + SkillCode, OneDaySkillInternalValues.Get(SkillCode));
                AllDaySkillExternalValues.Set(Format(WeekdayIndex) + '|' + SkillCode, OneDaySkillExternalValues.Get(SkillCode));
            end;
        end;

        AddChartSeries(SeriesArray, AssSeriesNameLbl, AssInternalValues, AssColorTok, '');
        AddChartSeries(SeriesArray, AssSeriesNameLbl, AssExternalValues, AssColorTok, ExternalBorderColorTok);

        SkillPaletteIdx := 0;
        foreach SkillCode in ActiveSkillList do begin
            Clear(SkillInternalValues);
            Clear(SkillExternalValues);
            for WeekdayIndex := 1 to 5 do begin
                SkillInternalValues.Add(0); // Capacity bar - skills never appear there.
                SkillInternalValues.Add(AllDaySkillInternalValues.Get(Format(WeekdayIndex) + '|' + SkillCode));
                SkillExternalValues.Add(0);
                SkillExternalValues.Add(AllDaySkillExternalValues.Get(Format(WeekdayIndex) + '|' + SkillCode));
            end;
            AddChartSeries(SeriesArray, SkillCode, SkillInternalValues, GetSkillSeriesColor(SkillPaletteIdx), '');
            AddChartSeries(SeriesArray, SkillCode, SkillExternalValues, GetSkillSeriesColor(SkillPaletteIdx), ExternalBorderColorTok);
            SkillPaletteIdx += 1;
        end;

        ChartData.Add('categories', CategoriesArray);
        ChartData.Add('dayLabels', DayLabelsArray);
        ChartData.Add('series', SeriesArray);
        ChartData.WriteTo(ChartDataJson);
    end;

    /// <summary>
    /// Builds a flat audit trail of the "Day Capacity Chart Audit Buffer" - one row per number
    /// that appears anywhere in the stacked chart built by BuildDayCapacityChartData, including
    /// 0-valued rows for the "other" bar type's segments (skills are always 0 on the Capacity
    /// bar - they still get a row). Skills outside BuildActiveSkillList's result get no rows at
    /// all, matching the chart's own behavior. Rows are inserted in the same left-to-right order
    /// as the chart's bars: for each weekday Monday..Friday, first the Capacity bar's rows
    /// (Assigned-Internal, Assigned-External, then each active skill's Internal/External pair),
    /// then the Requested bar's rows in the same segment order. A skill's Internal and External
    /// rows share the same Segment text (the bare Skill Code) - only "Bar Type" + row position
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
        LineNo: Integer;
    begin
        Buffer.Reset();
        Buffer.DeleteAll();

        EnsureDayPlanningBuffer(PeriodStartDate, PeriodStartDate + 4);

        BuildActiveSkillList(ActiveSkillList);

        LineNo := 0;
        for WeekdayIndex := 1 to 5 do begin
            CurrDate := PeriodStartDate + (WeekdayIndex - 1);

            CalcDaySegments(CurrDate, ActiveSkillList, AssignedInternal, AssignedExternal, SkillInternalValues, SkillExternalValues);

            // Capacity bar: Assigned-Internal/Assigned-External carry the day's assigned-hours
            // split, skills are always 0 (skills never appear on the Capacity bar).
            LineNo += 1;
            InsertAuditLine(Buffer, LineNo, CurrDate, Enum::"Day Capacity Chart Bar Type"::Capacity, InternalSegmentTok, AssignedInternal);
            LineNo += 1;
            InsertAuditLine(Buffer, LineNo, CurrDate, Enum::"Day Capacity Chart Bar Type"::Capacity, ExternalSegmentTok, AssignedExternal);
            foreach SkillCode in ActiveSkillList do begin
                LineNo += 1;
                InsertAuditLine(Buffer, LineNo, CurrDate, Enum::"Day Capacity Chart Bar Type"::Capacity, SkillCode, 0);
                LineNo += 1;
                InsertAuditLine(Buffer, LineNo, CurrDate, Enum::"Day Capacity Chart Bar Type"::Capacity, SkillCode, 0);
            end;

            // Requested bar: Assigned-Internal/Assigned-External carry the same split as the
            // Capacity bar, each skill carries its own unassigned-Requested-Hours Internal/
            // External split.
            LineNo += 1;
            InsertAuditLine(Buffer, LineNo, CurrDate, Enum::"Day Capacity Chart Bar Type"::Requested, InternalSegmentTok, AssignedInternal);
            LineNo += 1;
            InsertAuditLine(Buffer, LineNo, CurrDate, Enum::"Day Capacity Chart Bar Type"::Requested, ExternalSegmentTok, AssignedExternal);
            foreach SkillCode in ActiveSkillList do begin
                LineNo += 1;
                InsertAuditLine(Buffer, LineNo, CurrDate, Enum::"Day Capacity Chart Bar Type"::Requested, SkillCode, SkillInternalValues.Get(SkillCode));
                LineNo += 1;
                InsertAuditLine(Buffer, LineNo, CurrDate, Enum::"Day Capacity Chart Bar Type"::Requested, SkillCode, SkillExternalValues.Get(SkillCode));
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
    /// CalcAssignedSplit) plus, for each active skill, its unassigned-Requested-Hours split by
    /// "Requested Resource No." (via CalcUnassignedSkillRequestedSplit) for ONE weekday. Reads
    /// from the shared GDayPlanningBuf (see EnsureDayPlanningBuffer) - callers must have already
    /// ensured it is loaded for a range covering PlanDate.
    /// </summary>
    local procedure CalcDaySegments(PlanDate: Date; var ActiveSkillList: List of [Code[20]]; var AssignedInternal: Decimal; var AssignedExternal: Decimal; var SkillInternalValues: Dictionary of [Code[20], Decimal]; var SkillExternalValues: Dictionary of [Code[20], Decimal])
    var
        SkillCode: Code[20];
        SkillInternalD: Decimal;
        SkillExternalD: Decimal;
    begin
        Clear(SkillInternalValues);
        Clear(SkillExternalValues);

        CalcAssignedSplit(PlanDate, AssignedInternal, AssignedExternal);

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
        if GDayPlanningBuf.FindSet() then
            repeat
                if GDayPlanningBuf."Assigned Resource No." <> '' then
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
    /// Cycles through a fixed 5-colour palette for skill series beyond the fixed Assigned/Internal/
    /// External ones, so any number of active skills always gets a colour.
    /// </summary>
    local procedure GetSkillSeriesColor(PaletteIndex: Integer): Text
    var
        Palette: array[5] of Text[10];
    begin
        Palette[1] := '#C55A11';
        Palette[2] := '#ED7D31';
        Palette[3] := '#F4B183';
        Palette[4] := '#F8CBAD';
        Palette[5] := '#FBE5D6';
        exit(Palette[(PaletteIndex mod 5) + 1]);
    end;

    /// <summary>
    /// Appends one series object (name/values/color/[border]/stacked) to SeriesArray, matching
    /// the exact JSON contract src/dhx/barchart/wrapper.js's RenderChart expects. BorderHex may
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
        AssSeriesNameLbl: Label 'Assigned';
        FreeCapacityCategoryLbl: Label 'Capacity';
        RequestedCategoryLbl: Label 'Requested';
        CategoryDelimiterTok: Label '|', Locked = true;
        AssColorTok: Label '#548235', Locked = true;
        ExternalBorderColorTok: Label '#FF0000', Locked = true;
        AssignedSegmentTok: Label 'Assigned', Locked = true;
        InternalSegmentTok: Label 'Internal', Locked = true;
        ExternalSegmentTok: Label 'External', Locked = true;
        CapSegmentPrefixLbl: Label 'Cap. ';
        ReqSegmentPrefixLbl: Label 'Req. ';
        NoSkillSegmentLbl: Label '(No Skill)';
}
