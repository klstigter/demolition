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
    /// Unlike page 50681 (which supports a Weekly mode via its WeeklyFlag toggle, defaulting to
    /// Daily on open since 2026-09-07 - see that page's own OnOpenPage comment), this part is
    /// intentionally Daily-only: no WeeklyFlag/SetToWeekly/SetToDaily concept exists here at all,
    /// so it always shows a single day and matches its "Daily" caption. There is no Resource No.
    /// filter and no FactBoxes area,
    /// to keep the tile compact.
    /// </summary>

    layout
    {
        area(Content)
        {
            // Bare usercontrol - deliberately NOT wrapped in a captioned group()/field() the way
            // this page used to be (see git history). With this part now living in its own
            // dedicated 50%-width group() on page 50612 "Planning Role Center" alongside a sibling
            // group() for the Weekly part, a plain BC field/group in the SAME layout as this
            // usercontrol was constraining the usercontrol's own rendered width - confirmed live
            // 2026-09-07 (chart rendered narrow with blank space to its right, while the Period
            // field/"Requested Hours vs Capacity" caption above it DID span the full column). Making
            // the usercontrol the page's ONLY content lets it become the sole grid-worthy element so
            // it can actually stretch to fill the group's width. The period label and section title
            // that used to render here via BC's own field/group caption are now rendered BY
            // wrapper.js itself (see RenderChart/UpdateHeader there), fed via the 'periodLabel'/
            // 'title' keys added to ChartData in RefreshChart below - not part of the DHTMLX chart's
            // own SVG/legend, just plain HTML positioned above the chart container inside this
            // add-in's own DOM.
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
    // Assigned/Free-Capacity segments (Assigned Capacity combined + Free Internal/External
    // (Mandatory)/External non-mandatory - 2026-09-16, matches page 50692's weekly chart), plus
    // every SKILL bar now split into 2 stacked segments - a shared "Requested - Assigned" green series at the
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
        FontColorsArray: JsonArray;
        AssignedValues: JsonArray;
        CapInternalValues: JsonArray;
        CapExternalMandatoryValues: JsonArray;
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
        CapacityExternalMandatory: Decimal;
        AssignedColorHex: Text;
        CapacityColorHex: Text;
        CapacityMandatoryColorHex: Text;
        ExternalBorderColorHex: Text;
        UnassignedColorHex: Text;
        UnassignedBorderColorHex: Text;
        IsCapacityRow: Boolean;
        RowSkillCode: Code[10];
        LoopSkillCode: Code[10];
        RowValue: Decimal;
    begin
        if not ChartReady then
            exit;

        Clear(CategoriesArray);
        Clear(ColorsArray);
        Clear(FontColorsArray);
        Clear(AssignedValues);
        Clear(CapInternalValues);
        Clear(CapExternalMandatoryValues);
        Clear(CapExternalValues);
        Clear(RequestedAssignedValues);
        Clear(SkillCodeList);

        SkillCapacityAnalysisMgt.GetCapacitySegmentColors(AssignedColorHex, CapacityColorHex, ExternalBorderColorHex);
        CapacityMandatoryColorHex := SkillCapacityAnalysisMgt.GetCapacityMandatoryColor();
        SkillCapacityAnalysisMgt.BuildSkillAssignedUnassignedSplit(ResourceNoFilter, PeriodStartDate, PeriodStartDate, AssignedHoursPerSkill, UnassignedHoursPerSkill);

        Buffer.Reset();
        if Buffer.FindSet() then
            repeat
                IsCapacityRow := Buffer."No." = CapacitySkillCodeLbl;
                CategoriesArray.Add(Buffer."No.");

                if IsCapacityRow then begin
                    ColorsArray.Add(CapacityColorHex);
                    // CAPACITY is not a skill (blank per GetSkillFontColor/GetSkillBorderColor's
                    // own convention) - GetDefaultBarFontColor() is codeunit 50609's raw literal
                    // default, NOT GetBarFontColor()/"Daily Optimizer Setup"."Bar Font Color"
                    // (that setting is reserved for the two scheduler-timeline add-ins' actual
                    // Capacity bar/event, not this chart tile's CAPACITY category).
                    FontColorsArray.Add(VisualDefaultSettings.GetDefaultBarFontColor());
                    SkillCapacityAnalysisMgt.GetCapacityAssignedFreeSplit(PeriodStartDate, PeriodStartDate, AssignedInternal, AssignedExternal, CapacityInternal, CapacityExternal, CapacityExternalMandatory);
                    RequestedAssignedValues.Add(0);
                end else begin
                    RowSkillCode := CopyStr(Buffer."No.", 1, 10);
                    SkillCodeList.Add(RowSkillCode);
                    ColorsArray.Add(SkillCapacityAnalysisMgt.GetSkillBarColor(RowSkillCode, SkillPaletteIndex));
                    FontColorsArray.Add(VisualDefaultSettings.GetSkillFontColor(RowSkillCode));
                    SkillPaletteIndex += 1;
                    AssignedInternal := 0;
                    AssignedExternal := 0;
                    CapacityInternal := 0;
                    CapacityExternal := 0;
                    CapacityExternalMandatory := 0;
                    if AssignedHoursPerSkill.ContainsKey(RowSkillCode) then
                        RequestedAssignedValues.Add(AssignedHoursPerSkill.Get(RowSkillCode))
                    else
                        RequestedAssignedValues.Add(0);
                end;

                AssignedValues.Add(AssignedInternal + AssignedExternal);
                CapInternalValues.Add(CapacityInternal);
                CapExternalMandatoryValues.Add(CapacityExternalMandatory);
                CapExternalValues.Add(CapacityExternal);
            until Buffer.Next() = 0;

        SkillCapacityAnalysisMgt.AddCapacitySegmentSeries(SeriesArray, AssignedValues, CapInternalValues, CapExternalMandatoryValues, CapExternalValues, AssignedColorHex, CapacityColorHex, CapacityMandatoryColorHex, ExternalBorderColorHex);
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
            UnassignedBorderColorHex := VisualDefaultSettings.GetSkillBorderColor(LoopSkillCode, SkillPaletteIndex);
            SkillCapacityAnalysisMgt.AddSkillUnassignedSeries(SeriesArray, LoopSkillCode, SkillUnassignedValues, UnassignedColorHex, UnassignedBorderColorHex);
            SkillPaletteIndex += 1;
        end;

        ChartData.Add('categories', CategoriesArray);
        ChartData.Add('series', SeriesArray);
        ChartData.Add('colors', ColorsArray);
        ChartData.Add('fontColors', FontColorsArray);
        ChartData.Add('barWidth', VisualDefaultSettings.GetDailyBarChartWidth());
        // Rendered by wrapper.js as plain HTML above the chart container (see UpdateHeader there) -
        // replaces the BC field(PeriodLabelCtrl)/group(Filters) caption this page used to carry in
        // its own layout() - see the layout() area's own comment for why those moved out of AL.
        // Sends the raw date text (FormatFullDayText), NOT PeriodLabelText - wrapper.js's own
        // UpdateHeader already prefixes this with "Period: " itself, and PeriodLabelText carries
        // its own "Daily: " prefix (see DailyPeriodLabelLbl), so sending PeriodLabelText here would
        // render the redundant "Period: Daily: Mon 07 Sep 2026" instead of "Period: Mon 07 Sep
        // 2026".
        ChartData.Add('periodLabel', FormatFullDayText(PeriodStartDate));
        ChartData.Add('title', RequestedVsCapacityTitleLbl);
        // Hover/tooltip popup colours for dhx.Chart's own built-in hover tooltip - codeunit
        // 50609's GetTooltipBackgroundColor/GetTooltipFontColor. See wrapper.js's RenderChart.
        ChartData.Add('tooltipBg', VisualDefaultSettings.GetTooltipBackgroundColor());
        ChartData.Add('tooltipFont', VisualDefaultSettings.GetTooltipFontColor());

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
        // Sent as ChartData's 'title' key in RefreshChart - see the layout() area's own comment for
        // why this now renders inside wrapper.js's own DOM instead of as this page's group(Filters)
        // Caption.
        RequestedVsCapacityTitleLbl: Label 'Requested Hours vs Capacity';
        // Matches page 50681's own independently-declared 'CAPACITY' Label (see codeunit 50608's
        // BuildSkillBuffer doc comment for why this literal is intentionally duplicated rather
        // than shared - keep in sync if it ever changes).
        CapacitySkillCodeLbl: Label 'CAPACITY', Locked = true;
}
