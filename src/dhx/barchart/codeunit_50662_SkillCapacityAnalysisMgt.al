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
        Buffer."Skill Code" := SkillCode;
        if SkillCodeRec.Get(SkillCode) then
            Buffer.Description := SkillCodeRec.Description;
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
        Buffer."Skill Code" := CapacitySkillCodeTok;
        Buffer.Description := CapacityDescriptionTxt;
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
    /// Builds the JSON payload for the stacked "Capacity vs Requested" chart on page 50692,
    /// ready to hand straight to CurrPage.DhxBarChart.LoadData. Covers Monday..Friday only
    /// (PeriodStartDate is expected to already be a Monday, same convention as the page's own
    /// PeriodStartDate) - two categories per weekday ("<Wkd> Capacity" / "<Wkd> Requested"),
    /// each a stack of series segments:
    ///   - "Assigned" : Assigned Hours for the day (optionally narrowed to ResourceNoFilter).
    ///                  Identical value on BOTH the Capacity and Requested bar for that day.
    ///   - "Internal"/"External": split of (Capacity - Assigned) for the day's Res. Capacity Entry
    ///                  / Day Planning rows by the resource's "Is External" flag. Only ever
    ///                  nonzero on the Capacity bar (0 on the Requested bar). Not clamped to
    ///                  zero - a legitimately over-assigned day shows a negative segment.
    ///   - one series per Skill Code that has at least one unassigned ("Assigned Resource No." =
    ///                  '') Day Planning row with nonzero Requested Hours somewhere in the period.
    ///                  Only ever nonzero on the Requested bar (0 on the Capacity bar).
    ///
    /// ScenarioNo (0..5) "collapses" the first ScenarioNo weekdays (Monday = weekday 1) to an
    /// Assigned-only bar on both sides: their Internal/External/skill segments are forced to 0
    /// while Assigned itself is left untouched - simulating days that are already
    /// closed/committed and no longer open for planning. Range validation is the caller's
    /// responsibility (page 50692 validates 0..5 on its Scenario field before calling here).
    /// </summary>
    procedure BuildDayCapacityChartData(PeriodStartDate: Date; ResourceNoFilter: Code[20]; ScenarioNo: Integer) ChartDataJson: Text
    var
        ChartData: JsonObject;
        CategoriesArray: JsonArray;
        SeriesArray: JsonArray;
        AssValues: List of [Decimal];
        InternalValues: List of [Decimal];
        ExternalValues: List of [Decimal];
        SkillValues: List of [Decimal];
        ActiveSkillList: List of [Code[20]];
        OneDaySkillValues: Dictionary of [Code[20], Decimal];
        AllDaySkillValues: Dictionary of [Text, Decimal];
        SkillCode: Code[20];
        WeekdayIndex: Integer;
        CurrDate: Date;
        IsClosedDay: Boolean;
        AssD: Decimal;
        InternalFreeD: Decimal;
        ExternalFreeD: Decimal;
        SkillPaletteIdx: Integer;
    begin
        Clear(CategoriesArray);
        for WeekdayIndex := 1 to 5 do begin
            CurrDate := PeriodStartDate + (WeekdayIndex - 1);
            CategoriesArray.Add(FormatWeekdayShort(CurrDate) + FreeCapacityCategorySuffixLbl);
            CategoriesArray.Add(FormatWeekdayShort(CurrDate) + RequestedCategorySuffixLbl);
        end;

        BuildActiveSkillList(ActiveSkillList, PeriodStartDate, PeriodStartDate + 4);

        Clear(AssValues);
        Clear(InternalValues);
        Clear(ExternalValues);
        for WeekdayIndex := 1 to 5 do begin
            CurrDate := PeriodStartDate + (WeekdayIndex - 1);
            IsClosedDay := WeekdayIndex <= ScenarioNo;

            CalcDaySegments(CurrDate, ResourceNoFilter, IsClosedDay, ActiveSkillList, AssD, InternalFreeD, ExternalFreeD, OneDaySkillValues);

            // Capacity bar value, then Requested bar value - Assigned is identical on both.
            AssValues.Add(AssD);
            AssValues.Add(AssD);
            InternalValues.Add(InternalFreeD);
            InternalValues.Add(0);
            ExternalValues.Add(ExternalFreeD);
            ExternalValues.Add(0);

            // Stash this day's per-skill values (keyed by weekday+skill) so the per-skill series
            // loop below can reuse them instead of recomputing via CalcDaySegments again - AL has
            // no array-of-Dictionary type, so a single Dictionary keyed by a composite Text key
            // stands in for a per-weekday array of dictionaries.
            foreach SkillCode in ActiveSkillList do
                AllDaySkillValues.Set(Format(WeekdayIndex) + '|' + SkillCode, OneDaySkillValues.Get(SkillCode));
        end;

        AddChartSeries(SeriesArray, AssSeriesNameLbl, AssValues, AssColorTok, '');
        AddChartSeries(SeriesArray, InternalSeriesNameLbl, InternalValues, InternalColorTok, '');
        AddChartSeries(SeriesArray, ExternalSeriesNameLbl, ExternalValues, ExternalColorTok, ExternalBorderColorTok);

        SkillPaletteIdx := 0;
        foreach SkillCode in ActiveSkillList do begin
            Clear(SkillValues);
            for WeekdayIndex := 1 to 5 do begin
                SkillValues.Add(0); // Capacity bar - skills never appear there.
                SkillValues.Add(AllDaySkillValues.Get(Format(WeekdayIndex) + '|' + SkillCode));
            end;
            AddChartSeries(SeriesArray, SkillCode, SkillValues, GetSkillSeriesColor(SkillPaletteIdx), '');
            SkillPaletteIdx += 1;
        end;

        ChartData.Add('categories', CategoriesArray);
        ChartData.Add('series', SeriesArray);
        ChartData.WriteTo(ChartDataJson);
    end;

    /// <summary>
    /// Builds a flat audit trail of the "Day Capacity Chart Audit Buffer" - one row per number
    /// that appears anywhere in the stacked chart built by BuildDayCapacityChartData, including
    /// 0-valued rows for segments collapsed by ScenarioNo and 0-valued rows for the "other" bar
    /// type's segments (Internal/External are always 0 on the Requested bar, skills are always 0
    /// on the Capacity bar - they still get a row). Skills outside BuildActiveSkillList's result
    /// get no rows at all, matching the chart's own behavior. Rows are inserted in the same
    /// left-to-right order as the chart's bars: for each weekday Monday..Friday, first the
    /// Capacity bar's rows (Assigned, Internal, External, then each active skill), then the
    /// Requested bar's rows in the same segment order. Shares CalcDaySegments with
    /// BuildDayCapacityChartData so the two views can never drift apart.
    /// </summary>
    procedure BuildDayCapacityAuditBuffer(var Buffer: Record "Day Capacity Chart Audit Buf" temporary; PeriodStartDate: Date; ResourceNoFilter: Code[20]; ScenarioNo: Integer)
    var
        ActiveSkillList: List of [Code[20]];
        SkillValues: Dictionary of [Code[20], Decimal];
        SkillCode: Code[20];
        WeekdayIndex: Integer;
        CurrDate: Date;
        IsClosedDay: Boolean;
        AssignedValue: Decimal;
        InternalFree: Decimal;
        ExternalFree: Decimal;
        LineNo: Integer;
    begin
        Buffer.Reset();
        Buffer.DeleteAll();

        BuildActiveSkillList(ActiveSkillList, PeriodStartDate, PeriodStartDate + 4);

        LineNo := 0;
        for WeekdayIndex := 1 to 5 do begin
            CurrDate := PeriodStartDate + (WeekdayIndex - 1);
            IsClosedDay := WeekdayIndex <= ScenarioNo;

            CalcDaySegments(CurrDate, ResourceNoFilter, IsClosedDay, ActiveSkillList, AssignedValue, InternalFree, ExternalFree, SkillValues);

            // Capacity bar: Assigned/Internal/External carry the free-capacity values, skills are
            // always 0 (skills never appear on the Capacity bar).
            LineNo += 1;
            InsertAuditLine(Buffer, LineNo, CurrDate, Enum::"Day Capacity Chart Bar Type"::Capacity, AssignedSegmentTok, AssignedValue);
            LineNo += 1;
            InsertAuditLine(Buffer, LineNo, CurrDate, Enum::"Day Capacity Chart Bar Type"::Capacity, InternalSegmentTok, InternalFree);
            LineNo += 1;
            InsertAuditLine(Buffer, LineNo, CurrDate, Enum::"Day Capacity Chart Bar Type"::Capacity, ExternalSegmentTok, ExternalFree);
            foreach SkillCode in ActiveSkillList do begin
                LineNo += 1;
                InsertAuditLine(Buffer, LineNo, CurrDate, Enum::"Day Capacity Chart Bar Type"::Capacity, SkillCode, 0);
            end;

            // Requested bar: Assigned carries the same value as the Capacity bar, Internal/External
            // are always 0, skills carry their unassigned-Requested-Hours values.
            LineNo += 1;
            InsertAuditLine(Buffer, LineNo, CurrDate, Enum::"Day Capacity Chart Bar Type"::Requested, AssignedSegmentTok, AssignedValue);
            LineNo += 1;
            InsertAuditLine(Buffer, LineNo, CurrDate, Enum::"Day Capacity Chart Bar Type"::Requested, InternalSegmentTok, 0);
            LineNo += 1;
            InsertAuditLine(Buffer, LineNo, CurrDate, Enum::"Day Capacity Chart Bar Type"::Requested, ExternalSegmentTok, 0);
            foreach SkillCode in ActiveSkillList do begin
                LineNo += 1;
                InsertAuditLine(Buffer, LineNo, CurrDate, Enum::"Day Capacity Chart Bar Type"::Requested, SkillCode, SkillValues.Get(SkillCode));
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
    /// the Assigned/Internal/External/per-skill values for ONE weekday, with the IsClosedDay
    /// (Scenario) collapse already applied internally: when IsClosedDay is true, InternalFree,
    /// ExternalFree, and every entry in SkillValues are forced to 0 while AssignedValue is left
    /// untouched - matching the collapse behavior every caller needs identically.
    /// </summary>
    local procedure CalcDaySegments(PlanDate: Date; ResourceNoFilter: Code[20]; IsClosedDay: Boolean; var ActiveSkillList: List of [Code[20]]; var AssignedValue: Decimal; var InternalFree: Decimal; var ExternalFree: Decimal; var SkillValues: Dictionary of [Code[20], Decimal])
    var
        InternalCapacityD: Decimal;
        ExternalCapacityD: Decimal;
        InternalAssignedD: Decimal;
        ExternalAssignedD: Decimal;
        SkillCode: Code[20];
    begin
        Clear(SkillValues);

        AssignedValue := CalcAssignedHoursForDate(PlanDate, ResourceNoFilter);
        CalcCapacitySplit(PlanDate, ResourceNoFilter, InternalCapacityD, ExternalCapacityD);
        CalcAssignedSplit(PlanDate, ResourceNoFilter, InternalAssignedD, ExternalAssignedD);

        InternalFree := InternalCapacityD - InternalAssignedD;
        ExternalFree := ExternalCapacityD - ExternalAssignedD;

        if IsClosedDay then begin
            InternalFree := 0;
            ExternalFree := 0;
            foreach SkillCode in ActiveSkillList do
                SkillValues.Set(SkillCode, 0);
        end else
            foreach SkillCode in ActiveSkillList do
                SkillValues.Set(SkillCode, CalcUnassignedSkillRequestedHours(PlanDate, SkillCode));
    end;

    /// <summary>
    /// Determines which Skill Codes get their own chart series: any skill with at least one
    /// unassigned ("Assigned Resource No." = '') Day Planning row whose "Requested Hours" sum
    /// across the whole period is nonzero. Deliberately not the full Skill Code master list
    /// (unlike BuildSkillBuffer) - a skill with nothing requested in this period simply gets no
    /// series/bar segment at all.
    /// </summary>
    local procedure BuildActiveSkillList(var ActiveSkillList: List of [Code[20]]; DateFrom: Date; DateTo: Date)
    var
        DayPlanning: Record "Day Planning";
        SkillTotals: Dictionary of [Code[20], Decimal];
        SkillCode: Code[20];
        CurrentValue: Decimal;
    begin
        Clear(ActiveSkillList);

        DayPlanning.Reset();
        DayPlanning.SetLoadFields(Skill, "Requested Hours");
        DayPlanning.SetRange("Plan Date", DateFrom, DateTo);
        DayPlanning.SetRange("Assigned Resource No.", '');
        if DayPlanning.FindSet() then
            repeat
                if DayPlanning.Skill <> '' then begin
                    CurrentValue := 0;
                    if SkillTotals.ContainsKey(DayPlanning.Skill) then
                        CurrentValue := SkillTotals.Get(DayPlanning.Skill);
                    SkillTotals.Set(DayPlanning.Skill, CurrentValue + DayPlanning."Requested Hours");
                end;
            until DayPlanning.Next() = 0;

        foreach SkillCode in SkillTotals.Keys() do
            if SkillTotals.Get(SkillCode) <> 0 then
                ActiveSkillList.Add(SkillCode);
    end;

    local procedure CalcAssignedHoursForDate(PlanDate: Date; ResourceNoFilter: Code[20]): Decimal
    var
        DayPlanning: Record "Day Planning";
    begin
        DayPlanning.Reset();
        DayPlanning.SetRange("Plan Date", PlanDate);
        if ResourceNoFilter <> '' then
            DayPlanning.SetRange("Assigned Resource No.", ResourceNoFilter);
        DayPlanning.CalcSums("Assigned Hours");
        exit(DayPlanning."Assigned Hours");
    end;

    /// <summary>
    /// Splits the day's Assigned Hours (same rows CalcAssignedHoursForDate sums) into Internal /
    /// External buckets by the assigned resource's "Is External" flag. Rows with a blank
    /// "Assigned Resource No." cannot be classified and are skipped (in practice Assigned Hours
    /// is only ever populated once a resource is assigned).
    /// </summary>
    local procedure CalcAssignedSplit(PlanDate: Date; ResourceNoFilter: Code[20]; var InternalAssigned: Decimal; var ExternalAssigned: Decimal)
    var
        DayPlanning: Record "Day Planning";
        Resource: Record Resource;
    begin
        InternalAssigned := 0;
        ExternalAssigned := 0;

        Resource.SetLoadFields("Is External");

        DayPlanning.Reset();
        DayPlanning.SetLoadFields("Assigned Resource No.", "Assigned Hours");
        DayPlanning.SetRange("Plan Date", PlanDate);
        if ResourceNoFilter <> '' then
            DayPlanning.SetRange("Assigned Resource No.", ResourceNoFilter);
        if DayPlanning.FindSet() then
            repeat
                if DayPlanning."Assigned Resource No." <> '' then
                    if Resource.Get(DayPlanning."Assigned Resource No.") then begin
                        if Resource."Is External" then
                            ExternalAssigned += DayPlanning."Assigned Hours"
                        else
                            InternalAssigned += DayPlanning."Assigned Hours";
                    end;
            until DayPlanning.Next() = 0;
    end;

    /// <summary>
    /// Splits the day's "Res. Capacity Entry".Capacity into Internal / External buckets by each
    /// entry's resource "Is External" flag.
    /// </summary>
    local procedure CalcCapacitySplit(PlanDate: Date; ResourceNoFilter: Code[20]; var InternalCapacity: Decimal; var ExternalCapacity: Decimal)
    var
        ResCapacityEntry: Record "Res. Capacity Entry";
        Resource: Record Resource;
    begin
        InternalCapacity := 0;
        ExternalCapacity := 0;

        Resource.SetLoadFields("Is External");

        ResCapacityEntry.Reset();
        ResCapacityEntry.SetLoadFields("Resource No.", Capacity);
        ResCapacityEntry.SetRange(Date, PlanDate);
        if ResourceNoFilter <> '' then
            ResCapacityEntry.SetRange("Resource No.", ResourceNoFilter);
        if ResCapacityEntry.FindSet() then
            repeat
                if Resource.Get(ResCapacityEntry."Resource No.") then begin
                    if Resource."Is External" then
                        ExternalCapacity += ResCapacityEntry.Capacity
                    else
                        InternalCapacity += ResCapacityEntry.Capacity;
                end;
            until ResCapacityEntry.Next() = 0;
    end;

    /// <summary>
    /// Sum of "Requested Hours" for unassigned ("Assigned Resource No." = '') Day Planning rows
    /// on PlanDate for the given Skill. Deliberately ignores any Resource No. filter - unassigned
    /// lines have no assigned resource to filter on (see the procedure doc comment on
    /// BuildDayCapacityChartData / the caller's spec).
    /// </summary>
    local procedure CalcUnassignedSkillRequestedHours(PlanDate: Date; SkillCode: Code[20]): Decimal
    var
        DayPlanning: Record "Day Planning";
    begin
        DayPlanning.Reset();
        DayPlanning.SetRange("Plan Date", PlanDate);
        DayPlanning.SetRange("Assigned Resource No.", '');
        DayPlanning.SetRange(Skill, SkillCode);
        DayPlanning.CalcSums("Requested Hours");
        exit(DayPlanning."Requested Hours");
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
        CapacitySkillCodeTok: Label 'CAPACITY', Locked = true;
        CapacityDescriptionTxt: Label 'Capacity';
        AssSeriesNameLbl: Label 'Assigned';
        InternalSeriesNameLbl: Label 'Internal';
        ExternalSeriesNameLbl: Label 'External';
        FreeCapacityCategorySuffixLbl: Label ' Capacity';
        RequestedCategorySuffixLbl: Label ' Requested';
        AssColorTok: Label '#548235', Locked = true;
        InternalColorTok: Label '#8EA9DB', Locked = true;
        ExternalColorTok: Label '#B4C6E7', Locked = true;
        ExternalBorderColorTok: Label '#FF0000', Locked = true;
        AssignedSegmentTok: Label 'Assigned', Locked = true;
        InternalSegmentTok: Label 'Internal', Locked = true;
        ExternalSegmentTok: Label 'External', Locked = true;
}
