page 50705 "Skill Hours Summary"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "Summary Weekly";
    SourceTableTemporary = true;
    Editable = false;
    ShowFilter = false;
    Caption = 'Skill Hours Summary';

    /// <summary>
    /// Standalone "requested hours per skill per day" view. Deliberately independent of page 50626
    /// "Summary View" (which is reference/template only and must not be modified) - this page owns
    /// its own data-loading (straight from "Day Planning", grouped by Skill Code/Year/Week No, same
    /// shape as page 50626's Resource-less/Job-less rows) and its own period navigation, modeled on
    /// the Previous/Today/Next + Period label pattern used by page 50695 "Capacity Overview".
    /// Always shows Requested Hours (never Assigned) - there is no toggle, this page has exactly one
    /// display mode.
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
                    ToolTip = 'Specifies the currently displayed period. The grid always shows the full ISO week (Monday-Sunday) that contains this day.';
                }
            }
            repeater(Summary)
            {
                field("Skill Code"; Rec."Skill Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the skill code.';
                }
                field(Year; Rec.Year)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the year.';
                }
                field("Week No."; Rec."Week No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the ISO week number.';
                }
                field(TotalHours; Rec."Total Requested Hours")
                {
                    ApplicationArea = All;
                    Caption = 'Total';
                    ToolTip = 'Specifies total requested hours for the week.';

                    trigger OnDrillDown()
                    begin
                        DrillDownDay(0);
                    end;
                }
                field(MondayHours; Rec."Monday Requested Hours")
                {
                    ApplicationArea = All;
                    Caption = 'Monday';
                    ToolTip = 'Specifies requested hours on Monday.';

                    trigger OnDrillDown()
                    begin
                        DrillDownDay(1);
                    end;
                }
                field(TuesdayHours; Rec."Tuesday Requested Hours")
                {
                    ApplicationArea = All;
                    Caption = 'Tuesday';
                    ToolTip = 'Specifies requested hours on Tuesday.';

                    trigger OnDrillDown()
                    begin
                        DrillDownDay(2);
                    end;
                }
                field(WednesdayHours; Rec."Wednesday Requested Hours")
                {
                    ApplicationArea = All;
                    Caption = 'Wednesday';
                    ToolTip = 'Specifies requested hours on Wednesday.';

                    trigger OnDrillDown()
                    begin
                        DrillDownDay(3);
                    end;
                }
                field(ThursdayHours; Rec."Thursday Requested Hours")
                {
                    ApplicationArea = All;
                    Caption = 'Thursday';
                    ToolTip = 'Specifies requested hours on Thursday.';

                    trigger OnDrillDown()
                    begin
                        DrillDownDay(4);
                    end;
                }
                field(FridayHours; Rec."Friday Requested Hours")
                {
                    ApplicationArea = All;
                    Caption = 'Friday';
                    ToolTip = 'Specifies requested hours on Friday.';

                    trigger OnDrillDown()
                    begin
                        DrillDownDay(5);
                    end;
                }
                field(SaturdayHours; Rec."Saturday Requested Hours")
                {
                    ApplicationArea = All;
                    Caption = 'Saturday';
                    ToolTip = 'Specifies requested hours on Saturday.';

                    trigger OnDrillDown()
                    begin
                        DrillDownDay(6);
                    end;
                }
                field(SundayHours; Rec."Sunday Requested Hours")
                {
                    ApplicationArea = All;
                    Caption = 'Sunday';
                    ToolTip = 'Specifies requested hours on Sunday.';

                    trigger OnDrillDown()
                    begin
                        DrillDownDay(7);
                    end;
                }
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
                    ToolTip = 'Move the displayed period back one week.';

                    trigger OnAction()
                    begin
                        PeriodDate := PeriodDate - 7;
                        RefreshPeriod();
                    end;
                }
                action(TodayAction)
                {
                    ApplicationArea = All;
                    Caption = 'Today';
                    Image = Calculate;
                    ToolTip = 'Jump to the period that contains today''s date.';

                    trigger OnAction()
                    begin
                        PeriodDate := Today();
                        RefreshPeriod();
                    end;
                }
                action(NextAction)
                {
                    ApplicationArea = All;
                    Caption = 'Next';
                    Image = NextRecord;
                    ToolTip = 'Move the displayed period forward one week.';

                    trigger OnAction()
                    begin
                        PeriodDate := PeriodDate + 7;
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
        if PeriodDate = 0D then
            PeriodDate := Today();
        RefreshPeriod();
    end;

    /// <summary>
    /// Sets the Job No./Job Task No. scope for this view. Mirrors the filtering context used by
    /// page 50626 "Summary View"'s LoadDataSet(JobNo, JobTaskNo) overload - same scope, only the
    /// display shape differs. Call before Run().
    /// </summary>
    procedure LoadContext(pJobNoFilter: Code[20]; pJobTaskNoFilter: Code[20])
    begin
        JobNoFilter := pJobNoFilter;
        JobTaskNoFilter := pJobTaskNoFilter;
    end;

    local procedure RefreshPeriod()
    var
        WeekStartDate: Date;
        WeekEndDate: Date;
        WeekNo: Integer;
        YearNo: Integer;
        Day1Text: Text[20];
        Day7Text: Text[20];
    begin
        WeekStartDate := CalcMonday(PeriodDate);
        WeekEndDate := WeekStartDate + 6;
        WeekNo := Date2DWY(WeekStartDate, 2);
        YearNo := Date2DWY(WeekStartDate, 3);
        Day1Text := FormatDayText(WeekStartDate);
        Day7Text := FormatDayText(WeekEndDate);
        PeriodLabelText := CopyStr(StrSubstNo(WeeklyPeriodLabelLbl, Format(WeekStartDate, 0, '<Month Text,3>'), YearNo, WeekNo, Day1Text, Day7Text), 1, MaxStrLen(PeriodLabelText));
        BuildSkillHoursGrid(WeekStartDate, WeekEndDate);
        CurrPage.Update(false);
    end;

    /// <summary>
    /// Returns the Monday of the ISO week containing ADate. Same weekday-index approach as page
    /// 50695 "Capacity Overview"'s CalcMonday, so results don't depend on regional week-start
    /// settings.
    /// </summary>
    local procedure CalcMonday(ADate: Date): Date
    var
        WeekDayNo: Integer;
    begin
        WeekDayNo := Date2DWY(ADate, 1);
        exit(ADate - (WeekDayNo - 1));
    end;

    local procedure FormatDayText(DayDate: Date): Text[20]
    begin
        exit(StrSubstNo(DayLabelLbl, Format(DayDate, 0, '<Weekday Text,3>'), Format(DayDate, 0, '<Day,2>')));
    end;

    /// <summary>
    /// Scans "Day Planning" directly (not via table 50612's Fill/Scan helpers, so page 50626 stays
    /// untouched) for the current Job No./Job Task No. scope and the current period's Monday..Sunday
    /// range, and groups Requested Hours by Skill Code/Year/Week No - Resource, Job and Job Task are
    /// deliberately collapsed (left blank in the key), same collapsing idea as page 50626's
    /// GroupByDataSet when ShowResource/ShowJob/ShowJobTask are off.
    /// </summary>
    local procedure BuildSkillHoursGrid(WeekStartDate: Date; WeekEndDate: Date)
    var
        DayPlanning: Record "Day Planning";
        DayIndex: Integer;
        YearValue: Integer;
        WeekNoValue: Integer;
    begin
        Rec.Reset();
        Rec.DeleteAll();

        DayPlanning.SetRange("Plan Date", WeekStartDate, WeekEndDate);
        if JobNoFilter <> '' then
            DayPlanning.SetRange("Job No.", JobNoFilter);
        if JobTaskNoFilter <> '' then
            DayPlanning.SetRange("Job Task No.", JobTaskNoFilter);
        if not DayPlanning.FindSet() then
            exit;

        repeat
            YearValue := Date2DWY(DayPlanning."Plan Date", 3);
            WeekNoValue := Date2DWY(DayPlanning."Plan Date", 2);
            DayIndex := Date2DWY(DayPlanning."Plan Date", 1);

            if not Rec.Get('', DayPlanning.Skill, '', '', YearValue, WeekNoValue) then begin
                Rec.Init();
                Rec."Skill Code" := DayPlanning.Skill;
                Rec.Year := YearValue;
                Rec."Week No." := WeekNoValue;
                Rec.Insert();
            end;
            AddRequestedHours(DayIndex, DayPlanning."Requested Hours");
            Rec.Modify();
        until DayPlanning.Next() = 0;
    end;

    local procedure AddRequestedHours(DayIndex: Integer; Hours: Decimal)
    begin
        case DayIndex of
            1:
                Rec."Monday Requested Hours" += Hours;
            2:
                Rec."Tuesday Requested Hours" += Hours;
            3:
                Rec."Wednesday Requested Hours" += Hours;
            4:
                Rec."Thursday Requested Hours" += Hours;
            5:
                Rec."Friday Requested Hours" += Hours;
            6:
                Rec."Saturday Requested Hours" += Hours;
            7:
                Rec."Sunday Requested Hours" += Hours;
        end;
        Rec."Total Requested Hours" += Hours;
    end;

    /// <summary>
    /// Opens "Day Plannings" filtered to the clicked cell: the row's Skill Code, the current
    /// Job No./Job Task No. scope, and either the whole period (Total column, WeekDayNo = 0) or one
    /// specific weekday within it.
    /// </summary>
    local procedure DrillDownDay(WeekDayNo: Integer)
    var
        DayPlanning: Record "Day Planning";
        WeekStartDate: Date;
    begin
        WeekStartDate := CalcMonday(DWY2Date(1, Rec."Week No.", Rec.Year));
        if WeekDayNo = 0 then
            DayPlanning.SetRange("Plan Date", WeekStartDate, WeekStartDate + 6)
        else
            DayPlanning.SetRange("Plan Date", WeekStartDate + (WeekDayNo - 1));

        if JobNoFilter <> '' then
            DayPlanning.SetRange("Job No.", JobNoFilter);
        if JobTaskNoFilter <> '' then
            DayPlanning.SetRange("Job Task No.", JobTaskNoFilter);
        DayPlanning.SetRange(Skill, Rec."Skill Code");

        Page.Run(Page::"Day Plannings", DayPlanning);
    end;

    var
        JobNoFilter: Code[20];
        JobTaskNoFilter: Code[20];
        PeriodDate: Date;
        PeriodLabelText: Text[80];
        WeeklyPeriodLabelLbl: Label 'Weekly: %1 %2 - wk %3 (%4 - %5)', Comment = '%1 = abbreviated month, %2 = year, %3 = ISO week number, %4 = period start day text, %5 = period end day text';
        DayLabelLbl: Label '%1 %2', Comment = '%1 = abbreviated weekday, %2 = day of month';
}
