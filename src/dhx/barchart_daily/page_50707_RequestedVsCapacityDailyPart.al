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

    // Same JSON-assembly shape as page 50681's own RefreshChart - one series ("Requested Hours"),
    // one bar per Skill Code plus the synthetic "CAPACITY" reference bar, per-bar colour overrides
    // via Codeunit "SkillCapacityAnalysisMgt.v1".GetSkillBarColor. No aggregation happens here;
    // Buffer is already fully aggregated by BuildSkillBuffer above.
    local procedure RefreshChart()
    var
        ChartData: JsonObject;
        CategoriesArray: JsonArray;
        SeriesArray: JsonArray;
        RequestedSeries: JsonObject;
        RequestedValues: JsonArray;
        ColorsArray: JsonArray;
        ChartDataJson: Text;
        SkillPaletteIndex: Integer;
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
                ColorsArray.Add(SkillCapacityAnalysisMgt.GetSkillBarColor(CopyStr(Buffer."No.", 1, 10), SkillPaletteIndex));
                SkillPaletteIndex += 1;
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
        ResourceNoFilter: Code[20];
        PeriodStartDate: Date;
        ChartReady: Boolean;
        PeriodLabelText: Text[80];
        RequestedHoursMeasureTxt: Label 'Requested Hours';
        DailyPeriodLabelLbl: Label 'Daily: %1', Comment = '%1 = full date text';
}
