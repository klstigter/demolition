page 50644 "Res. Asgmt. Job Matrix"
{
    PageType = ListPart;
    SourceTable = Job;
    Caption = 'Project';
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(JobRows)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the project number.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    Caption = 'Project Name';
                    ToolTip = 'Specifies the project description.';
                }
                field(MonText; MonText)
                {
                    ApplicationArea = All;
                    CaptionClass = MonCaption;
                    Editable = false;
                    ToolTip = 'Total day tasks | Tasks with resource assigned on Monday.';

                    trigger OnAssistEdit()
                    begin
                        SelectedDate := WeekMonDate;
                        CurrPage.Update(false);
                    end;
                }
                field(TueText; TueText)
                {
                    ApplicationArea = All;
                    CaptionClass = TueCaption;
                    Editable = false;
                    ToolTip = 'Total day tasks | Tasks with resource assigned on Tuesday.';

                    trigger OnAssistEdit()
                    begin
                        SelectedDate := WeekTueDate;
                        CurrPage.Update(false);
                    end;
                }
                field(WedText; WedText)
                {
                    ApplicationArea = All;
                    CaptionClass = WedCaption;
                    Editable = false;
                    ToolTip = 'Total day tasks | Tasks with resource assigned on Wednesday.';

                    trigger OnAssistEdit()
                    begin
                        SelectedDate := WeekWedDate;
                        CurrPage.Update(false);
                    end;
                }
                field(ThuText; ThuText)
                {
                    ApplicationArea = All;
                    CaptionClass = ThuCaption;
                    Editable = false;
                    ToolTip = 'Total day tasks | Tasks with resource assigned on Thursday.';

                    trigger OnAssistEdit()
                    begin
                        SelectedDate := WeekThuDate;
                        CurrPage.Update(false);
                    end;
                }
                field(FriText; FriText)
                {
                    ApplicationArea = All;
                    CaptionClass = FriCaption;
                    Editable = false;
                    ToolTip = 'Total day tasks | Tasks with resource assigned on Friday.';

                    trigger OnAssistEdit()
                    begin
                        SelectedDate := WeekFriDate;
                        CurrPage.Update(false);
                    end;
                }
                field(SatText; SatText)
                {
                    ApplicationArea = All;
                    CaptionClass = SatCaption;
                    Editable = false;
                    ToolTip = 'Total day tasks | Tasks with resource assigned on Saturday.';

                    trigger OnAssistEdit()
                    begin
                        SelectedDate := WeekSatDate;
                        CurrPage.Update(false);
                    end;
                }
                field(SunText; SunText)
                {
                    ApplicationArea = All;
                    CaptionClass = SunCaption;
                    Editable = false;
                    ToolTip = 'Total day tasks | Tasks with resource assigned on Sunday.';

                    trigger OnAssistEdit()
                    begin
                        SelectedDate := WeekSunDate;
                        CurrPage.Update(false);
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        CalcWeekCounts();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        CalcWeekCounts();
        CurrPage.Update(false);
    end;

    var
        WeekMonDate: Date;
        WeekTueDate: Date;
        WeekWedDate: Date;
        WeekThuDate: Date;
        WeekFriDate: Date;
        WeekSatDate: Date;
        WeekSunDate: Date;
        SelectedDate: Date;
        MonCaption: Text[30];
        TueCaption: Text[30];
        WedCaption: Text[30];
        ThuCaption: Text[30];
        FriCaption: Text[30];
        SatCaption: Text[30];
        SunCaption: Text[30];
        WeekHeader: Text[250];
        MonText: Text[30];
        TueText: Text[30];
        WedText: Text[30];
        ThuText: Text[30];
        FriText: Text[30];
        SatText: Text[30];
        SunText: Text[30];
        DateFilter: Date;

    procedure GetWeekHeader(): Text[250]
    begin
        if WeekMonDate = 0D then
            CalcWeekDates();
        exit(WeekHeader);
    end;

    procedure GetSelectedDate(): Date
    begin
        exit(SelectedDate);
    end;

    procedure SetFilters(NewDateFilter: Date; NewProjectFilter: Code[20])
    begin
        SelectedDate := 0D;  // reset cell selection when filters are re-applied
        DateFilter := NewDateFilter;
        if DateFilter = 0D then
            DateFilter := Today;
        CalcWeekDates();
        Rec.Reset();
        Rec.FilterGroup(2);
        if NewProjectFilter <> '' then
            Rec.SetRange("No.", NewProjectFilter);
        Rec.FilterGroup(0);
        CurrPage.Update(false);
    end;

    procedure GetCurrentJobNo(): Code[20]
    begin
        exit(Rec."No.");
    end;

    procedure GetWeekDateFrom(): Date
    begin
        if WeekMonDate = 0D then
            CalcWeekDates();
        exit(WeekMonDate);
    end;

    procedure GetWeekDateTo(): Date
    begin
        if WeekSunDate = 0D then
            CalcWeekDates();
        exit(WeekSunDate);
    end;

    local procedure CalcWeekDates()
    var
        DayOfWeek: Integer;
    begin
        if DateFilter = 0D then
            DateFilter := Today;
        DayOfWeek := Date2DWY(DateFilter, 1); // 1=Monday, 7=Sunday
        WeekMonDate := DateFilter - (DayOfWeek - 1);
        WeekTueDate := WeekMonDate + 1;
        WeekWedDate := WeekMonDate + 2;
        WeekThuDate := WeekMonDate + 3;
        WeekFriDate := WeekMonDate + 4;
        WeekSatDate := WeekMonDate + 5;
        WeekSunDate := WeekMonDate + 6;
        MonCaption := 'Mon, ' + Format(WeekMonDate, 0, '<Day,2>-<Month,2>-<Year,2>');
        TueCaption := 'Tue, ' + Format(WeekTueDate, 0, '<Day,2>-<Month,2>-<Year,2>');
        WedCaption := 'Wed, ' + Format(WeekWedDate, 0, '<Day,2>-<Month,2>-<Year,2>');
        ThuCaption := 'Thu, ' + Format(WeekThuDate, 0, '<Day,2>-<Month,2>-<Year,2>');
        FriCaption := 'Fri, ' + Format(WeekFriDate, 0, '<Day,2>-<Month,2>-<Year,2>');
        SatCaption := 'Sat, ' + Format(WeekSatDate, 0, '<Day,2>-<Month,2>-<Year,2>');
        SunCaption := 'Sun, ' + Format(WeekSunDate, 0, '<Day,2>-<Month,2>-<Year,2>');
        WeekHeader := MonCaption + '  |  ' + TueCaption + '  |  ' + WedCaption + '  |  ' + ThuCaption + '  |  ' + FriCaption + '  |  ' + SatCaption + '  |  ' + SunCaption;
    end;

    local procedure CalcWeekCounts()
    begin
        if WeekMonDate = 0D then
            CalcWeekDates();
        MonText := CalcDayText(Rec."No.", WeekMonDate);
        TueText := CalcDayText(Rec."No.", WeekTueDate);
        WedText := CalcDayText(Rec."No.", WeekWedDate);
        ThuText := CalcDayText(Rec."No.", WeekThuDate);
        FriText := CalcDayText(Rec."No.", WeekFriDate);
        SatText := CalcDayText(Rec."No.", WeekSatDate);
        SunText := CalcDayText(Rec."No.", WeekSunDate);
    end;

    local procedure CalcDayText(JobNo: Code[20]; DayDate: Date): Text[30]
    var
        DayTask: Record "Day Tasks";
        TotalCount: Integer;
        WithResourceCount: Integer;
    begin
        if (DayDate = 0D) or (JobNo = '') then
            exit('');
        DayTask.SetRange("Job No.", JobNo);
        DayTask.SetRange("Task Date", DayDate);
        TotalCount := DayTask.Count();
        if TotalCount = 0 then
            exit('');
        DayTask.SetFilter("No.", '<>%1', '');
        WithResourceCount := DayTask.Count();
        exit(Format(TotalCount) + ' | ' + Format(WithResourceCount));
    end;
}
