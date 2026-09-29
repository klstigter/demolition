page 50695 "Capacity Overview"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = ReportsAndAnalysis;
    Caption = 'Capacity Overview';

    /// <summary>
    /// Steps a "current period" (always a Monday..Sunday week) via the Previous/Today/Next
    /// actions, shows a read-only Filter FastTab describing that period (label + one text
    /// control per weekday), and hosts the Capacity Overview Matrix part (page 50696), which is
    /// rebuilt from codeunit 50694 every time the period changes.
    /// </summary>

    layout
    {
        area(Content)
        {
            group(PeriodFastTab)
            {
                Caption = 'Filter';

                field(PeriodLabelCtrl; PeriodLabelText)
                {
                    ApplicationArea = All;
                    Caption = 'Period';
                    Editable = false;
                    ToolTip = 'Specifies the currently displayed period - a week (with its Monday-Sunday range) in Weekly view, or a single date in Daily view.';
                }
            }
            part(MatrixPart; "Capacity Overview Matrix")
            {
                ApplicationArea = All;
                Caption = 'Capacity Overview';
            }
        }
    }

    actions
    {
        area(Processing)
        {
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
                    ToolTip = 'Switch the overview to a weekly aggregate view (Monday through Sunday).';

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
                    ToolTip = 'Switch the overview to a single-day view.';

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
        PeriodEndDate: Date;
        VisualDefaultSettings: Codeunit "Visual Default Settings";
    begin
        if WeeklyFlag then
            PeriodEndDate := PeriodStartDate + 6
        else
            PeriodEndDate := PeriodStartDate;

        if WeeklyFlag then
            PeriodLabelText := CopyStr(StrSubstNo(WeeklyPeriodLabelLbl, VisualDefaultSettings.FormatWeekPeriodText(PeriodStartDate)), 1, MaxStrLen(PeriodLabelText))
        else
            PeriodLabelText := CopyStr(StrSubstNo(DailyPeriodLabelLbl, FormatFullDayText(PeriodStartDate)), 1, MaxStrLen(PeriodLabelText));

        CapacityOverviewMgt.BuildSkillCodeList(SkillCodeList);
        CurrPage.MatrixPart.Page.LoadPeriod(SkillCodeList, PeriodStartDate, PeriodEndDate);
    end;

    local procedure FormatFullDayText(ADate: Date): Text
    begin
        exit(Format(ADate, 0, '<Weekday Text,3> <Day,2> <Month Text,3> <Year4>'));
    end;

    var
        CapacityOverviewMgt: Codeunit "Capacity Overview Mgt.";
        SkillCodeList: List of [Code[20]];
        WeeklyFlag: Boolean;
        PeriodStartDate: Date;
        PeriodLabelText: Text[80];
        WeeklyPeriodLabelLbl: Label 'Weekly: %1', Comment = '%1 = standard week period text, e.g. "wk 39 (Mon, 21 Sep 2026 - Sun, 27 Sep 2026)"';
        DailyPeriodLabelLbl: Label 'Daily: %1', Comment = '%1 = full date text';
}
