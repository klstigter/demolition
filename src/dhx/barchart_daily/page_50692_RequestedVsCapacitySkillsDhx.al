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
        WeeklyFlag := true;
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

        // Stashed for RefreshChart, which needs the same period end date to compute the CAPACITY
        // bar's Assigned/Free split (GetCapacityAssignedFreeSplit) - kept as its own page var
        // rather than recomputed there so the WeeklyFlag branch above stays the single source of
        // truth for "what period is currently displayed".
        CapacityPeriodEndDate := PeriodEndDate;
        SkillCapacityAnalysisMgt.BuildSkillBuffer(Buffer, ResourceNoFilter, PeriodStartDate, PeriodEndDate, '');
        CurrPage.DataPart.Page.LoadData(Buffer, ResourceNoFilter, PeriodStartDate, PeriodEndDate);
        RefreshChart();
    end;

    // SERIES COLOURS - the native BusinessChart version of this page (formerly
    // src/page/page_50690_RequestedVsCapacitySkills.al) was superseded by this DHTMLX page and
    // removed; its long comment used to explain a "phantom Variance measure" workaround needed
    // because BusinessChart's fixed palette put Requested Hours and Capacity on adjacent grey
    // slots. That workaround does not apply here: the DHTMLX Suite Chart add-in lets every
    // series carry its own explicit colour (wrapper.js' RenderChart honours each series def's own
    // `color`), so there is no fixed-palette grey-collision problem.
    //
    // Every bar is now a true 2-segment stack, no flat single-value series left at all:
    //   - CAPACITY: Assigned Internal/External + Free Capacity Internal/External (4 series,
    //     unchanged from the previous round - see AddCapacitySegmentSeries), 0 on every skill row.
    //   - Each SKILL: Requested-Assigned (green, ONE series shared across every skill - see
    //     AddRequestedAssignedSeries) at the bottom, that skill's own Unassigned portion (that
    //     skill's own colour, ONE series PER skill since the colour varies - see
    //     AddSkillUnassignedSeries) on top. Together they always sum to that skill's total
    //     Requested Hours - the "distribute the day's Assigned Hours into the daily chart" ask:
    //     Weekly's per-day Requested bar already shows one flat green "Assigned" block at the
    //     bottom of the whole stack (see codeunit 50662's BuildDayCapacityChartData doc comment on
    //     why that block is a day-level combined total, not per-skill); Daily's per-SKILL-bar
    //     layout has no day-level block to put that in, so each skill's own bar carries its own
    //     Assigned/Unassigned split instead - same total height, same green, same underlying rows.
    //   - CAPACITY's own Assigned-Internal/External figures still come from
    //     GetCapacityAssignedFreeSplit (resource calendar capacity), a DIFFERENT source from the
    //     skills' Requested-Assigned figures (Day Planning Requested Hours bucketed by fulfillment
    //     status) - they only coincidentally share the same green AssignedColor token, never the
    //     same numbers.
    //
    // Per-bar legend swatch colours ("colors"/ColorsArray, feeding wrapper.js's data-driven
    // legend - see that file's own RenderChart comment) are unchanged in spirit: each skill row's
    // entry is "Skill Code"."Bar Color"-or-palette (codeunit 50608's GetSkillBarColor - the SAME
    // colour reused for that skill's own Unassigned segment, so the swatch always matches the
    // visible top segment), the CAPACITY row's is the Free Capacity blue. All *Values arrays stay
    // index-aligned with CategoriesArray - 0 everywhere a segment doesn't apply, matching codeunit
    // 50662's own "0 on the bar this segment doesn't belong to" convention.
    local procedure RefreshChart()
    var
        ChartData: JsonObject;
        CategoriesArray: JsonArray;
        SeriesArray: JsonArray;
        ColorsArray: JsonArray;
        FontColorsArray: JsonArray;
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
        Clear(AssInternalValues);
        Clear(AssExternalValues);
        Clear(CapInternalValues);
        Clear(CapExternalValues);
        Clear(RequestedAssignedValues);
        Clear(SkillCodeList);

        SkillCapacityAnalysisMgt.GetCapacitySegmentColors(AssignedColorHex, CapacityColorHex, ExternalBorderColorHex);
        SkillCapacityAnalysisMgt.BuildSkillAssignedUnassignedSplit(ResourceNoFilter, PeriodStartDate, CapacityPeriodEndDate, AssignedHoursPerSkill, UnassignedHoursPerSkill);

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
                    SkillCapacityAnalysisMgt.GetCapacityAssignedFreeSplit(PeriodStartDate, CapacityPeriodEndDate, AssignedInternal, AssignedExternal, CapacityInternal, CapacityExternal);
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

        // One Unassigned series per active skill - a second pass over Buffer per skill to build
        // each series' own 0-elsewhere value array (skill counts are tiny, a handful at most, so
        // this O(skills x rows) pass is negligible - see codeunit 50608's own doc comment on why
        // the Unassigned segment can't share a single series the way the Assigned one does).
        // SkillPaletteIndex is reset and re-walked in the SAME order SkillCodeList was built in
        // (the loop above), so GetSkillBarColor returns the IDENTICAL colour here as it did for
        // that skill's own ColorsArray/legend entry above - same palette-index sequence in, same
        // colour out.
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
        // Matches page 50691's own independently-declared 'CAPACITY' Label (see codeunit 50608's
        // BuildSkillBuffer doc comment for why this literal is intentionally duplicated rather
        // than shared - keep in sync if it ever changes).
        CapacitySkillCodeLbl: Label 'CAPACITY', Locked = true;
}
