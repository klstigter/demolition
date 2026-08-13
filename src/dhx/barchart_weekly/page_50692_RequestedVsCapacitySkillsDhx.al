page 50692 "Requested vs Capacity Weekly"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = ReportsAndAnalysis;
    Caption = 'Weekly Requested/Capacity';

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
            field(PeriodLabelCtrl; PeriodLabelText + ' (' + Day1Text + ' - ' + Day7Text + ')')
            {
                ApplicationArea = All;
                Caption = 'Period';
                Editable = false;
                ToolTip = 'Specifies the month, year, and ISO week number of the displayed period.';
            }
            group(Filters)
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

                    trigger OnShowSegmentData(SegmentId: Text; BarType: Text; DayIndex: Integer; WholeWeek: Boolean)
                    begin
                        SkillCapacityAnalysisMgt.ShowSegmentData(SegmentId, BarType, PeriodStartDate, DayIndex, WholeWeek);
                    end;
                }
            }
        }

        area(FactBoxes)
        {
            part(AuditDataPart; "Day Capacity Chart Audit")
            {
                ApplicationArea = All;
                Caption = 'Chart Audit Trail';
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
    begin
        RefreshChart();
        RefreshAuditBuffer();
    end;

    // The chart is now a genuinely multi-series stacked chart (two bars per weekday - "Capacity"
    // and "Requested" - each a stack of Assigned/Internal/External/per-skill segments) built
    // entirely by codeunit 50662's BuildDayCapacityChartData, which already returns the exact
    // JSON shape (categories/series with name/values/color/[border]/stacked keys) that
    // src/dhx/barchart_weekly/wrapper.js' RenderChart expects. This page only supplies the current
    // filters (period, Resource No.) and forwards the resulting JSON string straight to
    // CurrPage.DhxBarChart.LoadData - it builds no JSON of its own. No scenario/what-if override
    // concept exists - the chart always shows actual/existing data for the displayed week.
    local procedure RefreshChart()
    var
        ChartDataJson: Text;
    begin
        if not ChartReady then
            exit;

        ChartDataJson := SkillCapacityAnalysisMgt.BuildDayCapacityChartData(PeriodStartDate);
        CurrPage.DhxBarChart.LoadData(ChartDataJson);
    end;

    /// <summary>
    /// Keeps the "Chart Audit Trail" factbox in sync with the chart data - same
    /// PeriodStartDate input, same codeunit 50662 shared per-day
    /// computation, so the factbox always shows exactly the numbers behind the chart. Called
    /// unconditionally (not gated by ChartReady like RefreshChart) since it is pure AL/factbox
    /// logic with no dependency on the DhxBarChart usercontrol having finished loading in the
    /// browser - it must run on the very first OnOpenPage pass, not just once ControlReady fires.
    /// </summary>
    local procedure RefreshAuditBuffer()
    var
        AuditBuffer: Record "Day Capacity Chart Audit Buf" temporary;
    begin
        SkillCapacityAnalysisMgt.BuildDayCapacityAuditBuffer(AuditBuffer, PeriodStartDate);
        CurrPage.AuditDataPart.Page.LoadData(AuditBuffer);
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
}
