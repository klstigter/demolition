page 50681 "Req. vs Capacity Skl Dhx v1"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = ReportsAndAnalysis;
    Caption = 'Skill Requested/Capacity';

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
            group(Filters)
            {
                Caption = 'Filters';

                field(PeriodLabelCtrl; PeriodLabelText + ' (' + Day1Text + ' - ' + Day7Text + ')')
                {
                    ApplicationArea = All;
                    Caption = 'Period';
                    Editable = false;
                    ToolTip = 'Specifies the month, year, and ISO week number of the displayed period.';
                }
                field(ResourceNoFilterCtrl; ResourceNoFilter)
                {
                    ApplicationArea = All;
                    Caption = 'Resource No.';
                    TableRelation = Resource;
                    ToolTip = 'Specifies the resource to analyze. Leave blank to include all resources.';

                    trigger OnValidate()
                    begin
                        RefreshData();
                    end;
                }
            }

            group(ChartGroup)
            {
                Caption = 'Requested Hours vs Capacity';

                usercontrol(DhxBarChart; DHXBarChartAddin)
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
                }
            }
        }

        area(FactBoxes)
        {
            part(DataPart; "Skill Req. vs Capacity Part")
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
                    ToolTip = 'Move the displayed period back by one week.';

                    trigger OnAction()
                    begin
                        PeriodStartDate := PeriodStartDate - 7;
                        RefreshPeriod();
                    end;
                }
                action(TodayAction)
                {
                    ApplicationArea = All;
                    Caption = 'Today';
                    Image = Calculate;
                    ToolTip = 'Jump to the week that contains today''s date.';

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
                    ToolTip = 'Move the displayed period forward by one week.';

                    trigger OnAction()
                    begin
                        PeriodStartDate := PeriodStartDate + 7;
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
        PeriodStartDate := CalcMonday(Today());
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
        WeekNo := Date2DWY(PeriodStartDate, 2);
        YearNo := Date2DWY(PeriodStartDate, 3);

        PeriodLabelText := StrSubstNo(PeriodLabelLbl, Format(PeriodStartDate, 0, '<Month Text,3>'), YearNo, WeekNo);

        Day1Text := FormatDayText(PeriodStartDate);
        Day7Text := FormatDayText(PeriodStartDate + 6);

        RefreshData();
    end;

    local procedure FormatDayText(DayDate: Date): Text[20]
    begin
        exit(StrSubstNo(DayLabelLbl, Format(DayDate, 0, '<Weekday Text,3>'), Format(DayDate, 0, '<Day,2>')));
    end;

    local procedure RefreshData()
    var
        PeriodEndDate: Date;
    begin
        PeriodEndDate := PeriodStartDate + 6;
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
    local procedure RefreshChart()
    var
        ChartData: JsonObject;
        CategoriesArray: JsonArray;
        SeriesArray: JsonArray;
        RequestedSeries: JsonObject;
        RequestedValues: JsonArray;
        ChartDataJson: Text;
    begin
        if not ChartReady then
            exit;

        Clear(CategoriesArray);
        Clear(RequestedValues);

        Buffer.Reset();
        if Buffer.FindSet() then
            repeat
                CategoriesArray.Add(Buffer."Skill Code");
                RequestedValues.Add(Buffer."Requested Hours");
            until Buffer.Next() = 0;

        RequestedSeries.Add('name', RequestedHoursMeasureTxt);
        RequestedSeries.Add('values', RequestedValues);

        SeriesArray.Add(RequestedSeries);

        ChartData.Add('categories', CategoriesArray);
        ChartData.Add('series', SeriesArray);

        ChartData.WriteTo(ChartDataJson);
        CurrPage.DhxBarChart.LoadData(ChartDataJson);
    end;

    var
        Buffer: Record "Skill Req. vs Capacity Buffer" temporary;
        SkillCapacityAnalysisMgt: Codeunit "Skill Capacity Analysis Mgt.";
        ResourceNoFilter: Code[20];
        PeriodStartDate: Date;
        ChartReady: Boolean;
        PeriodLabelText: Text[50];
        Day1Text: Text[20];
        Day7Text: Text[20];
        RequestedHoursMeasureTxt: Label 'Requested Hours';
        PeriodLabelLbl: Label '%1 %2 - wk %3', Comment = '%1 = abbreviated month, %2 = year, %3 = ISO week number';
        DayLabelLbl: Label '%1 %2', Comment = '%1 = abbreviated weekday, %2 = day of month';
}
