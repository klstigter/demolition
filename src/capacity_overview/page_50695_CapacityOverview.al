page 50710 "Capacity Overview"
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

                field(PeriodLabelCtrl; PeriodLabelText + ' (' + Day1Text + ' - ' + Day7Text + ')')
                {
                    ApplicationArea = All;
                    Caption = 'Period';
                    Editable = false;
                    ToolTip = 'Specifies the month, year, and ISO week number of the displayed period.';
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
        PeriodEndDate: Date;
        WeekNo: Integer;
        YearNo: Integer;
    begin
        PeriodEndDate := PeriodStartDate + 6;
        WeekNo := Date2DWY(PeriodStartDate, 2);
        YearNo := Date2DWY(PeriodStartDate, 3);

        PeriodLabelText := StrSubstNo(PeriodLabelLbl, Format(PeriodStartDate, 0, '<Month Text,3>'), YearNo, WeekNo);

        Day1Text := FormatDayText(PeriodStartDate);
        Day2Text := FormatDayText(PeriodStartDate + 1);
        Day3Text := FormatDayText(PeriodStartDate + 2);
        Day4Text := FormatDayText(PeriodStartDate + 3);
        Day5Text := FormatDayText(PeriodStartDate + 4);
        Day6Text := FormatDayText(PeriodStartDate + 5);
        Day7Text := FormatDayText(PeriodStartDate + 6);

        CapacityOverviewMgt.BuildSkillCodeList(SkillCodeList);
        CurrPage.MatrixPart.Page.LoadPeriod(SkillCodeList, PeriodStartDate, PeriodEndDate);
    end;

    local procedure FormatDayText(DayDate: Date): Text[20]
    begin
        exit(StrSubstNo(DayLabelLbl, Format(DayDate, 0, '<Weekday Text,3>'), Format(DayDate, 0, '<Day,2>')));
    end;

    var
        CapacityOverviewMgt: Codeunit "Capacity Overview Mgt.";
        SkillCodeList: List of [Code[20]];
        PeriodStartDate: Date;
        PeriodLabelText: Text[50];
        Day1Text: Text[20];
        Day2Text: Text[20];
        Day3Text: Text[20];
        Day4Text: Text[20];
        Day5Text: Text[20];
        Day6Text: Text[20];
        Day7Text: Text[20];
        PeriodLabelLbl: Label '%1 %2 - wk %3', Comment = '%1 = abbreviated month, %2 = year, %3 = ISO week number';
        DayLabelLbl: Label '%1 %2', Comment = '%1 = abbreviated weekday, %2 = day of month';
}
