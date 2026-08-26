page 50707 "Requested vs Capacity Daily P"
{
    PageType = CardPart;
    ApplicationArea = All;
    Caption = 'Daily';
    RefreshOnActivate = true;

    /// <summary>
    /// Role-Center-embeddable variant of page 50681 "Requested vs Capacity Daily". Page 50681 is
    /// PageType = Card, which cannot be declared as a Role Center part() - BC only allows
    /// CardPart/ListPart/ListPlus there - so this page exists purely to host the same chart as a
    /// compact dashboard tile. It reuses Codeunit "SkillCapacityAnalysisMgt.v1" (BuildSkillBuffer/
    /// GetSkillBarColor) and the same DHXBarChartAddin_daily control add-in as page 50681 - no
    /// aggregation logic is reimplemented here, only the JSON-assembly loop that page 50681 itself
    /// already does locally (the codeunit does the actual data work in both places).
    ///
    /// Unlike page 50681 (which defaults to Weekly mode via its WeeklyFlag toggle - a pre-existing
    /// quirk of that page, left untouched), this part is intentionally Daily-only: no
    /// WeeklyFlag/SetToWeekly/SetToDaily concept exists here at all, so it always shows a single
    /// day and matches its "Daily" caption. There is no Resource No. filter and no FactBoxes area,
    /// to keep the tile compact.
    /// </summary>

    layout
    {
        area(Content)
        {
            field(PeriodLabelCtrl; PeriodLabelText)
            {
                ApplicationArea = All;
                Caption = 'Period';
                Editable = false;
                ToolTip = 'Specifies the currently displayed day.';
            }
            group(Filters)
            {
                Caption = 'Requested Hours vs Capacity';

                usercontrol(DhxBarChart; DHXBarChartAddin_daily)
                {
                    ApplicationArea = All;

                    trigger ControlReady()
                    begin
                        ChartReady := true;
                        RefreshChart();
                    end;

                    trigger OnDataPointClicked(SkillCode: Text)
                    begin
                    end;

                    trigger OnShowSegmentData(SegmentId: Text; WholeChart: Boolean)
                    begin
                        SkillCapacityAnalysisMgt.ShowSegmentData(SegmentId, WholeChart, ResourceNoFilter, PeriodStartDate, PeriodStartDate);
                    end;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(RefreshAction)
            {
                ApplicationArea = All;
                Caption = 'Refresh';
                Image = Refresh;
                ToolTip = 'Recalculate the chart for the current day.';

                trigger OnAction()
                begin
                    RefreshData();
                end;
            }
            action(PreviousAction)
            {
                ApplicationArea = All;
                Caption = 'Previous';
                Image = PreviousRecord;
                ToolTip = 'Move to the previous day.';

                trigger OnAction()
                begin
                    PeriodStartDate := PeriodStartDate - 1;
                    RefreshPeriod();
                end;
            }
            action(TodayAction)
            {
                ApplicationArea = All;
                Caption = 'Today';
                Image = Calculate;
                ToolTip = 'Jump to today.';

                trigger OnAction()
                begin
                    SetPeriodToToday();
                    RefreshPeriod();
                end;
            }
            action(NextAction)
            {
                ApplicationArea = All;
                Caption = 'Next';
                Image = NextRecord;
                ToolTip = 'Move to the next day.';

                trigger OnAction()
                begin
                    PeriodStartDate := PeriodStartDate + 1;
                    RefreshPeriod();
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        SetPeriodToToday();
        RefreshPeriod();
    end;

    local procedure SetPeriodToToday()
    begin
        PeriodStartDate := Today();
    end;

    local procedure RefreshPeriod()
    begin
        PeriodLabelText := CopyStr(StrSubstNo(DailyPeriodLabelLbl, FormatFullDayText(PeriodStartDate)), 1, MaxStrLen(PeriodLabelText));
        RefreshData();
    end;

    local procedure FormatFullDayText(ADate: Date): Text
    begin
        exit(Format(ADate, 0, '<Weekday Text,3> <Day,2> <Month Text,3> <Year4>'));
    end;

    local procedure RefreshData()
    begin
        SkillCapacityAnalysisMgt.BuildSkillBuffer(Buffer, ResourceNoFilter, PeriodStartDate, PeriodStartDate, '');
        RefreshChart();
    end;

    // Same JSON-assembly shape as page 50681's own RefreshChart (see that page's own doc comment
    // for the full breakdown - kept in sync here deliberately): CAPACITY's 4 stacked
    // Assigned/Free-Capacity segments (unchanged from the previous round), plus every SKILL bar
    // now split into 2 stacked segments - a shared "Requested - Assigned" green series at the
    // bottom (that skill's Requested Hours with an Assigned Resource) and that skill's own
    // Unassigned series on top (its own colour, same as its legend swatch), instead of one flat
    // "Requested Hours" bar. No aggregation happens here for the flat totals; Buffer is already
    // fully aggregated by BuildSkillBuffer above - only the Assigned/Unassigned split
    // (BuildSkillAssignedUnassignedSplit) and the CAPACITY split (GetCapacityAssignedFreeSplit)
    // are computed fresh. This part is always Daily-only (PeriodStartDate is both the range's
    // start and end - see this page's own doc comment), so both splits are always called for a
    // single day, never a range.
    local procedure RefreshChart()
    var
        ChartData: JsonObject;
        CategoriesArray: JsonArray;
        SeriesArray: JsonArray;
        ColorsArray: JsonArray;
        AssInternalValues: JsonArray;
        AssExternalValues: JsonArray;
        CapInternalValues: JsonArray;
        CapExternalValues: JsonArray;
        RequestedAssignedValues: JsonArray;
        SkillUnassignedValues: JsonArray;
        SkillCodeList: List of [Code[10]];
        AssignedHoursPerSkill: Dictionary of [Code[10], Decimal];
        UnassignedHoursPerSkill: Dictionary of [Code[10], Decimal];
        ChartDataJson: Text;
        SkillPaletteIndex: Integer;
        AssignedInternal: Decimal;
        AssignedExternal: Decimal;
        CapacityInternal: Decimal;
        CapacityExternal: Decimal;
        AssignedColorHex: Text;
        CapacityColorHex: Text;
        ExternalBorderColorHex: Text;
        UnassignedColorHex: Text;
        IsCapacityRow: Boolean;
        RowSkillCode: Code[10];
        LoopSkillCode: Code[10];
        RowValue: Decimal;
    begin
        if not ChartReady then
            exit;

        Clear(CategoriesArray);
        Clear(ColorsArray);
        Clear(AssInternalValues);
        Clear(AssExternalValues);
        Clear(CapInternalValues);
        Clear(CapExternalValues);
        Clear(RequestedAssignedValues);
        Clear(SkillCodeList);

        SkillCapacityAnalysisMgt.GetCapacitySegmentColors(AssignedColorHex, CapacityColorHex, ExternalBorderColorHex);
        SkillCapacityAnalysisMgt.BuildSkillAssignedUnassignedSplit(ResourceNoFilter, PeriodStartDate, PeriodStartDate, AssignedHoursPerSkill, UnassignedHoursPerSkill);

        Buffer.Reset();
        if Buffer.FindSet() then
            repeat
                IsCapacityRow := Buffer."No." = CapacitySkillCodeLbl;
                CategoriesArray.Add(Buffer."No.");

                if IsCapacityRow then begin
                    ColorsArray.Add(CapacityColorHex);
                    SkillCapacityAnalysisMgt.GetCapacityAssignedFreeSplit(PeriodStartDate, PeriodStartDate, AssignedInternal, AssignedExternal, CapacityInternal, CapacityExternal);
                    RequestedAssignedValues.Add(0);
                end else begin
                    RowSkillCode := CopyStr(Buffer."No.", 1, 10);
                    SkillCodeList.Add(RowSkillCode);
                    ColorsArray.Add(SkillCapacityAnalysisMgt.GetSkillBarColor(RowSkillCode, SkillPaletteIndex));
                    SkillPaletteIndex += 1;
                    AssignedInternal := 0;
                    AssignedExternal := 0;
                    CapacityInternal := 0;
                    CapacityExternal := 0;
                    if AssignedHoursPerSkill.ContainsKey(RowSkillCode) then
                        RequestedAssignedValues.Add(AssignedHoursPerSkill.Get(RowSkillCode))
                    else
                        RequestedAssignedValues.Add(0);
                end;

                AssInternalValues.Add(AssignedInternal);
                AssExternalValues.Add(AssignedExternal);
                CapInternalValues.Add(CapacityInternal);
                CapExternalValues.Add(CapacityExternal);
            until Buffer.Next() = 0;

        SkillCapacityAnalysisMgt.AddCapacitySegmentSeries(SeriesArray, AssInternalValues, AssExternalValues, CapInternalValues, CapExternalValues, AssignedColorHex, CapacityColorHex, ExternalBorderColorHex);
        SkillCapacityAnalysisMgt.AddRequestedAssignedSeries(SeriesArray, RequestedAssignedValues, AssignedColorHex);

        // One Unassigned series per active skill - see page 50681's own RefreshChart for why this
        // is a second per-skill pass over Buffer, and why re-walking SkillPaletteIndex from 0 in
        // the SAME order SkillCodeList was built in reproduces the identical GetSkillBarColor
        // result as that skill's own ColorsArray/legend entry above.
        SkillPaletteIndex := 0;
        foreach LoopSkillCode in SkillCodeList do begin
            Clear(SkillUnassignedValues);
            Buffer.Reset();
            if Buffer.FindSet() then
                repeat
                    if CopyStr(Buffer."No.", 1, 10) = LoopSkillCode then begin
                        if UnassignedHoursPerSkill.ContainsKey(LoopSkillCode) then
                            RowValue := UnassignedHoursPerSkill.Get(LoopSkillCode)
                        else
                            RowValue := 0;
                    end else
                        RowValue := 0;
                    SkillUnassignedValues.Add(RowValue);
                until Buffer.Next() = 0;

            UnassignedColorHex := SkillCapacityAnalysisMgt.GetSkillBarColor(LoopSkillCode, SkillPaletteIndex);
            SkillCapacityAnalysisMgt.AddSkillUnassignedSeries(SeriesArray, LoopSkillCode, SkillUnassignedValues, UnassignedColorHex);
            SkillPaletteIndex += 1;
        end;

        ChartData.Add('categories', CategoriesArray);
        ChartData.Add('series', SeriesArray);
        ChartData.Add('colors', ColorsArray);
        ChartData.Add('barWidth', VisualDefaultSettings.GetDailyBarChartWidth());

        ChartData.WriteTo(ChartDataJson);
        CurrPage.DhxBarChart.LoadData(ChartDataJson);
    end;

    var
        Buffer: Record "Skill Req. vs Capacity Buffer" temporary;
        SkillCapacityAnalysisMgt: Codeunit "SkillCapacityAnalysisMgt.v1";
        VisualDefaultSettings: Codeunit "Visual Default Settings";
        ResourceNoFilter: Code[20];
        PeriodStartDate: Date;
        ChartReady: Boolean;
        PeriodLabelText: Text[80];
        DailyPeriodLabelLbl: Label 'Daily: %1', Comment = '%1 = full date text';
        // Matches page 50681's own independently-declared 'CAPACITY' Label (see codeunit 50608's
        // BuildSkillBuffer doc comment for why this literal is intentionally duplicated rather
        // than shared - keep in sync if it ever changes).
        CapacitySkillCodeLbl: Label 'CAPACITY', Locked = true;
}
