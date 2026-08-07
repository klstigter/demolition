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
    procedure BuildSkillBuffer(var Buffer: Record "Skill Req. vs Capacity Buffer" temporary; DateFromFilter: Date; DateToFilter: Date; SkillCodeFilter: Code[10])
    var
        DayPlanning: Record "Day Planning";
        SkillCodeRec: Record "Skill Code";
        DateRc: Record Date;
        SkillCode: Code[10];
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
        Code: Code[20];
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
        Buffer."Requested Hours" := Hours;
        Buffer.Insert();
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
    procedure BuildDayCapacityChartData(PeriodStartDate: Date) ChartDataJson: Text
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

            CalcDaySegments(CurrDate, ActiveSkillList, AssD, InternalFreeD, ExternalFreeD, OneDaySkillValues);

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
    procedure BuildDayCapacityAuditBuffer(var Buffer: Record "Day Capacity Chart Audit Buf" temporary; PeriodStartDate: Date)
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

            CalcDaySegments(CurrDate, ActiveSkillList, AssignedValue, InternalFree, ExternalFree, SkillValues);

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
    local procedure CalcDaySegments(PlanDate: Date; var ActiveSkillList: List of [Code[20]]; var AssignedValue: Decimal; var InternalFree: Decimal; var ExternalFree: Decimal; var SkillValues: Dictionary of [Code[20], Decimal])
    var
        InternalCapacityD: Decimal;
        ExternalCapacityD: Decimal;
        InternalAssignedD: Decimal;
        ExternalAssignedD: Decimal;
        SkillCode: Code[20];
    begin
        Clear(SkillValues);

        AssignedValue := CalcAssignedHoursForDate(PlanDate);
        CalcCapacitySplit(PlanDate, InternalCapacityD, ExternalCapacityD);
        CalcAssignedSplit(PlanDate, InternalAssignedD, ExternalAssignedD);

        InternalFree := InternalCapacityD - InternalAssignedD;
        ExternalFree := ExternalCapacityD - ExternalAssignedD;

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

    local procedure CalcAssignedHoursForDate(PlanDate: Date): Decimal
    var
        DayPlanning: Record "Day Planning";
    begin
        DayPlanning.Reset();
        DayPlanning.SetRange("Plan Date", PlanDate);
        DayPlanning.CalcSums("Assigned Hours");
        exit(DayPlanning."Assigned Hours");
    end;

    /// <summary>
    /// Splits the day's Assigned Hours (same rows CalcAssignedHoursForDate sums) into Internal /
    /// External buckets by the assigned resource's "Is External" flag. Rows with a blank
    /// "Assigned Resource No." cannot be classified and are skipped (in practice Assigned Hours
    /// is only ever populated once a resource is assigned).
    /// </summary>
    local procedure CalcAssignedSplit(PlanDate: Date; var InternalAssigned: Decimal; var ExternalAssigned: Decimal)
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
    local procedure CalcCapacitySplit(PlanDate: Date; var InternalCapacity: Decimal; var ExternalCapacity: Decimal)
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
