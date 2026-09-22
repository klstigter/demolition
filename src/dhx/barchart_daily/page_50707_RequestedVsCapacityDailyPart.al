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

                // JS-rendered toolbar replacements for the retired BC RefreshAction/PreviousAction/
                // TodayAction/NextAction actions (see this page's own former actions() area, and
                // wrapper.js's BuildToolbar/UpdateToolbar) - BC collapses a CardPart's action bar into
                // a hidden "..." overflow menu once it's embedded in a Role Center, so those actions
                // are now buttons rendered directly inside the add-in's own DOM instead (opt-in via
                // the 'showToolbar' key this page's RefreshChart sends). Each trigger calls the exact
                // same local procedure(s) the corresponding retired action used to call - only the UI
                // trigger moved, not the underlying logic.
                trigger OnRefreshClicked()
                begin
                    RefreshData();
                end;

                trigger OnPreviousClicked()
                begin
                    PeriodStartDate := PeriodStartDate - 1;
                    RefreshPeriod();
                end;

                trigger OnTodayClicked()
                begin
                    SetPeriodToToday();
                    RefreshPeriod();
                end;

                trigger OnNextClicked()
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
    // for the full C/R bar-pair breakdown - kept in sync here deliberately). No aggregation
    // happens here for the flat totals; Buffer is already fully aggregated by BuildSkillBuffer
    // above - only the Assigned/Unassigned split (BuildSkillAssignedUnassignedSplit) and each
    // skill's own resource-scoped Capacity split (GetSkillCapacityAssignedFreeSplit) are computed
    // fresh. This part is always Daily-only (PeriodStartDate is both the range's start and end -
    // see this page's own doc comment), so both splits are always called for a single day, never
    // a range.
    local procedure RefreshChart()
    var
        ChartData: JsonObject;
        CategoriesArray: JsonArray;
        SkillLabelsArray: JsonArray;
        SeriesArray: JsonArray;
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
        UnassignedFontColorHex: Text;
        RowSkillCode: Code[10];
        LoopSkillCode: Code[10];
        RowValue: Decimal;
    begin
        if not ChartReady then
            exit;

        Clear(CategoriesArray);
        Clear(SkillLabelsArray);
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
                RowSkillCode := CopyStr(Buffer."No.", 1, 10);
                SkillCodeList.Add(RowSkillCode);
                SkillLabelsArray.Add(RowSkillCode);

                CategoriesArray.Add(RowSkillCode + CategoryDelimiterTok + CapacityCategoryLbl);
                CategoriesArray.Add(RowSkillCode + CategoryDelimiterTok + RequestedCategoryLbl);

                // "C" slot - this skill's own resource-scoped Capacity split.
                SkillCapacityAnalysisMgt.GetSkillCapacityAssignedFreeSplit(RowSkillCode, PeriodStartDate, PeriodStartDate, AssignedInternal, AssignedExternal, CapacityInternal, CapacityExternal, CapacityExternalMandatory);
                AssignedValues.Add(AssignedInternal + AssignedExternal);
                CapInternalValues.Add(CapacityInternal);
                CapExternalMandatoryValues.Add(CapacityExternalMandatory);
                CapExternalValues.Add(CapacityExternal);
                RequestedAssignedValues.Add(0);

                // "R" slot - unchanged Requested-Assigned/Unassigned skill-demand split.
                AssignedValues.Add(0);
                CapInternalValues.Add(0);
                CapExternalMandatoryValues.Add(0);
                CapExternalValues.Add(0);
                if AssignedHoursPerSkill.ContainsKey(RowSkillCode) then
                    RequestedAssignedValues.Add(AssignedHoursPerSkill.Get(RowSkillCode))
                else
                    RequestedAssignedValues.Add(0);
            until Buffer.Next() = 0;

        SkillCapacityAnalysisMgt.AddCapacitySegmentSeries(SeriesArray, AssignedValues, CapInternalValues, CapExternalMandatoryValues, CapExternalValues, AssignedColorHex, CapacityColorHex, CapacityMandatoryColorHex, ExternalBorderColorHex);
        SkillCapacityAnalysisMgt.AddRequestedAssignedSeries(SeriesArray, RequestedAssignedValues, AssignedColorHex);

        // One Unassigned series per skill - see page 50681's own RefreshChart for why this is a
        // second per-skill pass over Buffer, and why re-walking SkillPaletteIndex from 0 in the
        // SAME order SkillCodeList was built in reproduces the identical GetSkillBarColor result.
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
                    SkillUnassignedValues.Add(0); // "C" slot - skills never appear on the Capacity bar.
                    SkillUnassignedValues.Add(RowValue); // "R" slot.
                until Buffer.Next() = 0;

            UnassignedColorHex := SkillCapacityAnalysisMgt.GetSkillBarColor(LoopSkillCode, SkillPaletteIndex);
            UnassignedBorderColorHex := VisualDefaultSettings.GetSkillBorderColor(LoopSkillCode, SkillPaletteIndex);
            UnassignedFontColorHex := VisualDefaultSettings.GetSkillFontColor(LoopSkillCode);
            SkillCapacityAnalysisMgt.AddSkillUnassignedSeries(SeriesArray, LoopSkillCode, SkillUnassignedValues, UnassignedColorHex, UnassignedBorderColorHex, UnassignedFontColorHex);
            SkillPaletteIndex += 1;
        end;

        ChartData.Add('categories', CategoriesArray);
        ChartData.Add('skillLabels', SkillLabelsArray);
        ChartData.Add('series', SeriesArray);
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
        // Opt-in flag for wrapper.js's own JS-rendered Refresh/Previous/Today/Next toolbar (see
        // BuildToolbar/UpdateToolbar there) - sent ONLY by this page's RefreshChart, never by page
        // 50681's (the standalone Card page sharing this same control add-in/wrapper.js), so the
        // toolbar stays hidden there. Same opt-in mechanism as 'periodLabel' above.
        ChartData.Add('showToolbar', true);
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
        // Matches codeunit 50608's own CategoryDelimiterTok/CapacityCategoryLbl (and page 50681's
        // own independently-declared copies) text-for-text - keep in sync if it ever changes. See
        // this procedure's (RefreshChart's) own doc comment for the category-string shape.
        CategoryDelimiterTok: Label '|', Locked = true;
        CapacityCategoryLbl: Label 'Capacity';
        RequestedCategoryLbl: Label 'Requested';
}
