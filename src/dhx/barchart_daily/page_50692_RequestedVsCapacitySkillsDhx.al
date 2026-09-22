page 50681 "Requested vs Capacity Daily"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = ReportsAndAnalysis;
    Caption = 'Daily Requested/Capacity';

    /// <summary>
    /// The date range is now a "current period" (always a Monday..Sunday week) stepped via the
    /// Previous/Today/Next actions - matching page 50695 "Capacity Overview"'s pattern - rather
    /// than free-text Date From/Date To fields. The Skill Code filter field was removed too: it
    /// only ever narrowed the chart/factbox down to one already-visible category, which the user
    /// can do just as well by reading the chart, so it was redundant chrome. Resource No. is the
    /// only remaining filter.
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
                ToolTip = 'Specifies the currently displayed period - a week (with its Monday-Sunday range) in Weekly view, or a single date in Daily view.';
            }
            // field(ResourceNoFilterCtrl; ResourceNoFilter)
            // {
            //     ApplicationArea = All;
            //     Caption = 'Resource No.';
            //     TableRelation = Resource;
            //     ToolTip = 'Specifies the resource to analyze. Leave blank to include all resources.';

            //     trigger OnValidate()
            //     begin
            //         RefreshData();
            //     end;
            // }
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
                        if WeeklyFlag then
                            SkillCapacityAnalysisMgt.ShowSegmentData(SegmentId, WholeChart, ResourceNoFilter, PeriodStartDate, PeriodStartDate + 6)
                        else
                            SkillCapacityAnalysisMgt.ShowSegmentData(SegmentId, WholeChart, ResourceNoFilter, PeriodStartDate, PeriodStartDate);
                    end;
                }
            }
        }

        area(FactBoxes)
        {
            part(DataPart; "SkillReq. vs CapacityPart v1")
            {
                ApplicationArea = All;
                Caption = 'Requested vs Capacity per Skill';
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
                ToolTip = 'Recalculate the chart and the data list for the current filters.';

                trigger OnAction()
                begin
                    RefreshData();
                end;
            }
            group(PeriodNavigation)
            {
                Caption = 'Period';

                action(PreviousAction)
                {
                    ApplicationArea = All;
                    Caption = 'Previous';
                    Image = PreviousRecord;
                    ToolTip = 'Move the displayed period back one step - a week in Weekly view, a day in Daily view.';

                    trigger OnAction()
                    begin
                        if WeeklyFlag then
                            PeriodStartDate := PeriodStartDate - 7
                        else
                            PeriodStartDate := PeriodStartDate - 1;
                        RefreshPeriod();
                    end;
                }
                action(TodayAction)
                {
                    ApplicationArea = All;
                    Caption = 'Today';
                    Image = Calculate;
                    ToolTip = 'Jump to the period that contains today''s date - the current week in Weekly view, or today in Daily view.';

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
                    ToolTip = 'Move the displayed period forward one step - a week in Weekly view, a day in Daily view.';

                    trigger OnAction()
                    begin
                        if WeeklyFlag then
                            PeriodStartDate := PeriodStartDate + 7
                        else
                            PeriodStartDate := PeriodStartDate + 1;
                        RefreshPeriod();
                    end;
                }

                action(SetToWeekly)
                {
                    Caption = 'Set to Weekly';
                    ApplicationArea = All;
                    Image = AddWatch;
                    Visible = not WeeklyFlag;
                    ToolTip = 'Switch the chart to a weekly aggregate view (Monday through Sunday).';

                    trigger OnAction()
                    begin
                        WeeklyFlag := true;
                        SetPeriodToToday();
                        RefreshPeriod();
                    end;
                }
                action(SetToDaily)
                {
                    Caption = 'Set to Daily';
                    ApplicationArea = All;
                    Image = DataEntry;
                    Visible = WeeklyFlag;
                    ToolTip = 'Switch the chart to a single-day view.';

                    trigger OnAction()
                    begin
                        WeeklyFlag := false;
                        SetPeriodToToday();
                        RefreshPeriod();
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(RefreshAction_Promoted; RefreshAction)
                {
                }
                actionref(PreviousAction_Promoted; PreviousAction)
                {
                }
                actionref(TodayAction_Promoted; TodayAction)
                {
                }
                actionref(NextAction_Promoted; NextAction)
                {
                }
                actionref(SetToWeekly_Promoted; SetToWeekly)
                {
                }
                actionref(SetToDaily_Promoted; SetToDaily)
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        // Defaults to Daily (matches this page's own "Daily Requested/Capacity" Caption and the
        // Planning Role Center's Daily panel, which always shows a single-day period) - previously
        // opened in Weekly mode instead, a pre-existing quirk that made this page's own "Period"
        // field show a week range on open while its caption/the role center both said "Daily".
        // WeeklyFlag := true fixed here 2026-09-07; SetToWeekly/SetToDaily actions still let the
        // user switch modes freely after open.
        WeeklyFlag := false;
        SetPeriodToToday();
        RefreshPeriod();
    end;

    local procedure SetPeriodToToday()
    begin
        if WeeklyFlag then
            PeriodStartDate := CalcMonday(Today())
        else
            PeriodStartDate := Today();
    end;

    /// <summary>
    /// Returns the Monday of the ISO week containing ADate. Deliberately computed via
    /// Date2DWY's weekday component (1 = Monday .. 7 = Sunday) rather than a "CW" date formula,
    /// so the result does not depend on company/regional week-start settings.
    /// </summary>
    local procedure CalcMonday(ADate: Date): Date
    var
        WeekDayNo: Integer;
    begin
        WeekDayNo := Date2DWY(ADate, 1);
        exit(ADate - (WeekDayNo - 1));
    end;

    local procedure RefreshPeriod()
    var
        WeekNo: Integer;
        YearNo: Integer;
    begin
        if WeeklyFlag then begin
            WeekNo := Date2DWY(PeriodStartDate, 2);
            YearNo := Date2DWY(PeriodStartDate, 3);
            Day1Text := FormatDayText(PeriodStartDate);
            Day7Text := FormatDayText(PeriodStartDate + 6);
            PeriodLabelText := CopyStr(StrSubstNo(WeeklyPeriodLabelLbl, Format(PeriodStartDate, 0, '<Month Text,3>'), YearNo, WeekNo, Day1Text, Day7Text), 1, MaxStrLen(PeriodLabelText));
        end else
            PeriodLabelText := CopyStr(StrSubstNo(DailyPeriodLabelLbl, FormatFullDayText(PeriodStartDate)), 1, MaxStrLen(PeriodLabelText));

        RefreshData();
    end;

    local procedure FormatDayText(DayDate: Date): Text[20]
    begin
        exit(StrSubstNo(DayLabelLbl, Format(DayDate, 0, '<Weekday Text,3>'), Format(DayDate, 0, '<Day,2>')));
    end;

    local procedure FormatFullDayText(ADate: Date): Text
    begin
        exit(Format(ADate, 0, '<Weekday Text,3> <Day,2> <Month Text,3> <Year4>'));
    end;

    local procedure RefreshData()
    var
        PeriodEndDate: Date;
    begin
        if WeeklyFlag then
            PeriodEndDate := PeriodStartDate + 6
        else
            PeriodEndDate := PeriodStartDate;

        // Stashed for RefreshChart, which needs the same period end date to compute each skill's
        // own "C" bar Assigned/Free split (GetSkillCapacityAssignedFreeSplit) - kept as its own
        // page var rather than recomputed there so the WeeklyFlag branch above stays the single
        // source of truth for "what period is currently displayed".
        CapacityPeriodEndDate := PeriodEndDate;
        SkillCapacityAnalysisMgt.BuildSkillBuffer(Buffer, ResourceNoFilter, PeriodStartDate, PeriodEndDate, '');
        CurrPage.DataPart.Page.LoadData(Buffer, ResourceNoFilter, PeriodStartDate, PeriodEndDate);
        RefreshChart();
    end;

    // SERIES/CATEGORY SHAPE (redesigned 2026-09-22, replacing the old single-bar-per-skill +
    // synthetic CAPACITY-bar layout): every Skill Code MASTER record now gets its own C(apacity)/
    // R(equested) bar PAIR, mirroring src/dhx/barchart_weekly's own per-day C/R pair shape (see
    // codeunit 50662's BuildDayCapacityChartData) - grouped by Skill Code here instead of by
    // weekday. Category strings are "<SkillCode>|Capacity" / "<SkillCode>|Requested"
    // (CategoryDelimiterTok-joined, still unique per bar for DHTMLX's positioning - wrapper.js's
    // textTemplate strips the "<SkillCode>|" prefix so the tick only shows "C"/"R"), with the
    // skill code ALSO carried separately in the top-level "skillLabels" array (one entry per
    // skill, same order) so wrapper.js can render its own merged group-header row spanning that
    // skill's 2 bars (RenderSkillGroupRow, ported from wrapper.js's own RenderDayGroupRow). Every
    // configured Skill Code master record gets a pair (even at 0, matching Buffer's own "show
    // every skill" behavior) - unlike Weekly's per-day chart, there is no "only nonzero" filtering
    // here.
    //
    // Each category is a stack of series segments:
    //   - "R" (Requested) bar: shared "Requested - Assigned" (green, ONE series across every
    //     skill - AddRequestedAssignedSeries) at the bottom, that skill's own "Unassigned" portion
    //     (that skill's own colour, ONE series PER skill - AddSkillUnassignedSeries) on top.
    //     Together they sum to that skill's total Requested Hours. 0 at every "C" slot.
    //   - "C" (Capacity) bar: Assigned Capacity (ONE combined series per skill, no border) + Free
    //     Capacity Internal, Free Capacity - External (Mandatory, no border), Free Capacity -
    //     External non-mandatory (red border, declared last so it stays topmost - see
    //     AddCapacitySegmentSeries) - 4 shared series total (one "C"-slot value per skill, 0 at
    //     every "R" slot). UNLIKE the old company-wide CAPACITY bar, these 4 values are now
    //     computed PER SKILL (GetSkillCapacityAssignedFreeSplit - resources holding that skill
    //     only, via "Resource Skill" - per the user's own mockup annotation "the capacity bar is
    //     per respective resource (not skill)"), not once for the whole chart. A resource holding
    //     multiple skills legitimately contributes to each of those skills' own totals.
    //   - A skill's own "C"-bar Assigned/Free figures (GetSkillCapacityAssignedFreeSplit, true
    //     resource calendar capacity) are a DIFFERENT source from that same skill's "R"-bar
    //     Requested-Assigned figures (Day Planning Requested Hours bucketed by fulfillment status)
    //     - they only coincidentally share the same green AssignedColor token, never the same
    //     numbers.
    //
    // Legend is now SERIES-driven (wrapper.js's RenderChart, dedup by label - matching codeunit
    // 50662's own Weekly chart legend convention) instead of the old per-category/bar
    // "colors"/ColorsArray-driven legend - a category-driven legend no longer makes sense once
    // each category is only half a skill's story (its Capacity OR Requested bar, not the whole
    // skill). Per-skill legend TEXT colour is now carried on that skill's own Unassigned series
    // ("fontColor", codeunit 50608's GetSkillFontColor via AddSkillUnassignedSeries) instead of a
    // separate top-level "fontColors" array - see AddSeries' own doc comment.
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
        SkillCapacityAnalysisMgt.BuildSkillAssignedUnassignedSplit(ResourceNoFilter, PeriodStartDate, CapacityPeriodEndDate, AssignedHoursPerSkill, UnassignedHoursPerSkill);

        Buffer.Reset();
        if Buffer.FindSet() then
            repeat
                RowSkillCode := CopyStr(Buffer."No.", 1, 10);
                SkillCodeList.Add(RowSkillCode);
                SkillLabelsArray.Add(RowSkillCode);

                CategoriesArray.Add(RowSkillCode + CategoryDelimiterTok + CapacityCategoryLbl);
                CategoriesArray.Add(RowSkillCode + CategoryDelimiterTok + RequestedCategoryLbl);

                // "C" slot - this skill's own resource-scoped Capacity split.
                SkillCapacityAnalysisMgt.GetSkillCapacityAssignedFreeSplit(RowSkillCode, PeriodStartDate, CapacityPeriodEndDate, AssignedInternal, AssignedExternal, CapacityInternal, CapacityExternal, CapacityExternalMandatory);
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

        // One Unassigned series per skill - a second pass over Buffer per skill to build each
        // series' own 0-elsewhere value array (skill counts are tiny, a handful at most, so this
        // O(skills x rows) pass is negligible). SkillPaletteIndex is reset and re-walked in the
        // SAME order SkillCodeList was built in (the loop above), so GetSkillBarColor returns the
        // IDENTICAL colour here as any other palette-index-driven lookup for that same skill.
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
        // Hover/tooltip popup colours for dhx.Chart's own built-in hover tooltip (shown when
        // hovering a bar) - codeunit 50609's GetTooltipBackgroundColor/GetTooltipFontColor. See
        // wrapper.js's RenderChart for how these two keys are applied.
        ChartData.Add('tooltipBg', VisualDefaultSettings.GetTooltipBackgroundColor());
        ChartData.Add('tooltipFont', VisualDefaultSettings.GetTooltipFontColor());

        ChartData.WriteTo(ChartDataJson);
        CurrPage.DhxBarChart.LoadData(ChartDataJson);
    end;

    var
        Buffer: Record "Skill Req. vs Capacity Buffer" temporary;
        SkillCapacityAnalysisMgt: Codeunit "SkillCapacityAnalysisMgt.v1";
        VisualDefaultSettings: Codeunit "Visual Default Settings";
        WeeklyFlag: Boolean;
        ResourceNoFilter: Code[20];
        PeriodStartDate: Date;
        CapacityPeriodEndDate: Date;
        ChartReady: Boolean;
        PeriodLabelText: Text[80];
        Day1Text: Text[20];
        Day7Text: Text[20];
        WeeklyPeriodLabelLbl: Label 'Weekly: %1 %2 - wk %3 (%4 - %5)', Comment = '%1 = abbreviated month, %2 = year, %3 = ISO week number, %4 = period start day text, %5 = period end day text';
        DailyPeriodLabelLbl: Label 'Daily: %1', Comment = '%1 = full date text';
        DayLabelLbl: Label '%1 %2', Comment = '%1 = abbreviated weekday, %2 = day of month';
        // Matches codeunit 50608's own CategoryDelimiterTok/CapacityCategoryLbl (and page 50707's
        // own independently-declared copies) text-for-text - keep in sync if it ever changes. See
        // this procedure's (RefreshChart's) own doc comment for the category-string shape.
        CategoryDelimiterTok: Label '|', Locked = true;
        CapacityCategoryLbl: Label 'Capacity';
        RequestedCategoryLbl: Label 'Requested';
}
