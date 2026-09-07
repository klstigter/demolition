page 50708 "Requested vs Capacity Weekly P"
{
    PageType = CardPart;
    ApplicationArea = All;
    Caption = 'Weekly';
    RefreshOnActivate = true;

    /// <summary>
    /// Role-Center-embeddable variant of page 50692 "Requested vs Capacity Weekly". Page 50692 is
    /// PageType = Card, which cannot be declared as a Role Center part() - BC only allows
    /// CardPart/ListPart/ListPlus there - so this page exists purely to host the same stacked
    /// chart as a compact dashboard tile. It reuses Codeunit "Skill Capacity Analysis Mgt."
    /// (BuildDayCapacityChartData) and the same DHXBarChartAddin control add-in as page 50692 -
    /// this page builds no chart JSON of its own, it only forwards the codeunit's result, exactly
    /// like page 50692 does. No FactBoxes area (the audit-trail factbox is skipped) and no
    /// Resource No. filter, to keep the tile compact.
    /// </summary>

    layout
    {
        area(Content)
        {
            // Bare usercontrol - deliberately NOT wrapped in a captioned group()/field() the way
            // this page used to be (see git history). With this part now living in its own
            // dedicated 50%-width group() on page 50612 "Planning Role Center" alongside a sibling
            // group() for the Daily part, a plain BC field/group in the SAME layout as this
            // usercontrol was constraining the usercontrol's own rendered width - confirmed live
            // 2026-09-07 (chart rendered narrow with blank space to its right, while the Period
            // field/"Requested Hours vs Capacity" caption above it DID span the full column). Making
            // the usercontrol the page's ONLY content lets it become the sole grid-worthy element so
            // it can actually stretch to fill the group's width. The period label and section title
            // that used to render here via BC's own field/group caption are now rendered BY
            // wrapper.js itself (see RenderChart/UpdateHeader there), fed via the 'periodLabel'/
            // 'title' keys merged into the codeunit's own ChartData JSON in RefreshChart below - not
            // part of the DHTMLX chart's own SVG/legend, just plain HTML positioned above the chart
            // container inside this add-in's own DOM.
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

                trigger OnShowSegmentData(SegmentId: Text; BarType: Text; DayIndex: Integer; WholeWeek: Boolean)
                begin
                    SkillCapacityAnalysisMgt.ShowSegmentData(SegmentId, BarType, PeriodStartDate, DayIndex, WholeWeek);
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
                ToolTip = 'Recalculate the chart for the current week.';

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
    /// Returns the Monday of the ISO week containing ADate. Same technique as page 50692's own
    /// CalcMonday - deliberately computed via Date2DWY's weekday component (1 = Monday .. 7 =
    /// Sunday) rather than a "CW" date formula, so the result does not depend on company/regional
    /// week-start settings.
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
    begin
        RefreshChart();
    end;

    // Forwards Codeunit "Skill Capacity Analysis Mgt.".BuildDayCapacityChartData's JSON, same as
    // page 50692's own RefreshChart - no chart JSON is assembled from scratch here - but then
    // parses it back into a JsonObject to merge in 'periodLabel'/'title' before handing it to
    // wrapper.js. Those two keys are consumed only by THIS part's own header rendering (see
    // UpdateHeader in wrapper.js, and the layout() area's own comment above for why they moved out
    // of AL) - page 50692 never sends them, so its own native BC Period field/group Caption stays
    // exactly as it was, unaffected by this page's change.
    local procedure RefreshChart()
    var
        ChartData: JsonObject;
        ChartDataJson: Text;
    begin
        if not ChartReady then
            exit;

        ChartDataJson := SkillCapacityAnalysisMgt.BuildDayCapacityChartData(PeriodStartDate);
        ChartData.ReadFrom(ChartDataJson);
        ChartData.Add('periodLabel', PeriodLabelText + ' (' + Day1Text + ' - ' + Day7Text + ')');
        ChartData.Add('title', RequestedVsCapacityTitleLbl);
        ChartData.WriteTo(ChartDataJson);
        CurrPage.DhxBarChart.LoadData(ChartDataJson);
    end;

    var
        SkillCapacityAnalysisMgt: Codeunit "Skill Capacity Analysis Mgt.";
        PeriodStartDate: Date;
        ChartReady: Boolean;
        PeriodLabelText: Text[50];
        Day1Text: Text[20];
        Day7Text: Text[20];
        PeriodLabelLbl: Label '%1 %2 - wk %3', Comment = '%1 = abbreviated month, %2 = year, %3 = ISO week number';
        DayLabelLbl: Label '%1 %2', Comment = '%1 = abbreviated weekday, %2 = day of month';
        // Sent as ChartData's 'title' key in RefreshChart - see the layout() area's own comment for
        // why this now renders inside wrapper.js's own DOM instead of as this page's group(Filters)
        // Caption.
        RequestedVsCapacityTitleLbl: Label 'Requested Hours vs Capacity';
}
