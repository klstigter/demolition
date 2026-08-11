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

        SkillCapacityAnalysisMgt.BuildSkillBuffer(Buffer, ResourceNoFilter, PeriodStartDate, PeriodEndDate, '');
        CurrPage.DataPart.Page.LoadData(Buffer, ResourceNoFilter, PeriodStartDate, PeriodEndDate);
        RefreshChart();
    end;

    // SERIES COLOURS - the native BusinessChart version of this page (formerly
    // src/page/page_50690_RequestedVsCapacitySkills.al) was superseded by this DHTMLX page and
    // removed; its long comment used to explain a "phantom Variance measure" workaround needed
    // because BusinessChart's fixed palette put Requested Hours and Capacity on adjacent grey
    // slots. That workaround does not apply here: the DHTMLX Suite Chart add-in lets every
    // series carry its own explicit colour (wrapper.js' RenderChart assigns
    // SERIES_COLOR_PALETTE[seriesIndex]), so there is no fixed-palette grey-collision problem.
    //
    // Table 50622 no longer has a separate Capacity field/column - codeunit 50662 now returns
    // the aggregate capacity total directly in "Requested Hours" on the synthetic "CAPACITY"
    // buffer row, alongside each real skill's own Requested Hours total on its own row. So a
    // single series built from Buffer."Requested Hours" already covers both: one bar per skill
    // category plus one capacity reference bar, never a paired Requested/Capacity bar per
    // category. wrapper.js' RenderChart renders however many series it is given (s0, s1, ...),
    // so dropping down to one series here needs no JS changes.
    //
    // Per-bar colour overrides: each category's bar can now be recoloured individually via
    // "Skill Code"."Bar Color" (codeunit 50608's GetSkillBarColor), independent of the single
    // series colour above. The optional top-level "colors" array carries one entry per
    // CategoriesArray/RequestedValues row (blank = no override, keep the series colour) - see
    // wrapper.js' ApplyBarColorOverrides for how these are applied client-side.
    local procedure RefreshChart()
    var
        ChartData: JsonObject;
        CategoriesArray: JsonArray;
        SeriesArray: JsonArray;
        RequestedSeries: JsonObject;
        RequestedValues: JsonArray;
        ColorsArray: JsonArray;
        ChartDataJson: Text;
    begin
        if not ChartReady then
            exit;

        Clear(CategoriesArray);
        Clear(RequestedValues);
        Clear(ColorsArray);

        Buffer.Reset();
        if Buffer.FindSet() then
            repeat
                CategoriesArray.Add(Buffer."No.");
                RequestedValues.Add(Buffer."Requested Hours");
                ColorsArray.Add(SkillCapacityAnalysisMgt.GetSkillBarColor(CopyStr(Buffer."No.", 1, 10)));
            until Buffer.Next() = 0;

        RequestedSeries.Add('name', RequestedHoursMeasureTxt);
        RequestedSeries.Add('values', RequestedValues);

        SeriesArray.Add(RequestedSeries);

        ChartData.Add('categories', CategoriesArray);
        ChartData.Add('series', SeriesArray);
        ChartData.Add('colors', ColorsArray);

        ChartData.WriteTo(ChartDataJson);
        CurrPage.DhxBarChart.LoadData(ChartDataJson);
    end;

    var
        Buffer: Record "Skill Req. vs Capacity Buffer" temporary;
        SkillCapacityAnalysisMgt: Codeunit "SkillCapacityAnalysisMgt.v1";
        WeeklyFlag: Boolean;
        ResourceNoFilter: Code[20];
        PeriodStartDate: Date;
        ChartReady: Boolean;
        PeriodLabelText: Text[80];
        Day1Text: Text[20];
        Day7Text: Text[20];
        RequestedHoursMeasureTxt: Label 'Requested Hours';
        WeeklyPeriodLabelLbl: Label 'Weekly: %1 %2 - wk %3 (%4 - %5)', Comment = '%1 = abbreviated month, %2 = year, %3 = ISO week number, %4 = period start day text, %5 = period end day text';
        DailyPeriodLabelLbl: Label 'Daily: %1', Comment = '%1 = full date text';
        DayLabelLbl: Label '%1 %2', Comment = '%1 = abbreviated weekday, %2 = day of month';
}
