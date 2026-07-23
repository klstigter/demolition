page 50638 "Resource Week View Part"
{
    PageType = ListPart;
    SourceTable = "Summary Weekly";
    SourceTableTemporary = true;
    Caption = 'Resource Week View';
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(Year; Rec.Year)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the year.';
                    Visible = false;
                }
                field("Week No."; Rec."Week No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the ISO week number.';
                }
                field("Skill Code"; Rec."Skill Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the skill code.';
                }
                field("Resource No."; Rec."Resource No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the resource number.';
                }
                field("Resource Name"; ResourceName)
                {
                    ApplicationArea = All;
                    Caption = 'Resource Name';
                    ToolTip = 'Specifies the resource name.';
                    Editable = false;
                    Visible = false;
                }
                field(TotalPair; TotalPair)
                {
                    ApplicationArea = All;
                    Caption = 'Total';
                    ToolTip = 'Requested | Assigned hours for the week.';
                    Style = Strong;
                    trigger OnDrillDown()
                    begin
                        DrillDown2DayTaks(0);
                    end;
                }
                field(MondayPair; MondayPair)
                {
                    ApplicationArea = All;
                    Caption = 'Monday';
                    ToolTip = 'Requested | Assigned hours on Monday.';
                    StyleExpr = WeekdayStyle;
                    trigger OnDrillDown()
                    begin
                        DrillDown2DayTaks(1);
                    end;
                }
                field(TuesdayPair; TuesdayPair)
                {
                    ApplicationArea = All;
                    Caption = 'Tuesday';
                    ToolTip = 'Requested | Assigned hours on Tuesday.';
                    StyleExpr = WeekdayStyle;
                    trigger OnDrillDown()
                    begin
                        DrillDown2DayTaks(2);
                    end;
                }
                field(WednesdayPair; WednesdayPair)
                {
                    ApplicationArea = All;
                    Caption = 'Wednesday';
                    ToolTip = 'Requested | Assigned hours on Wednesday.';
                    StyleExpr = WeekdayStyle;
                    trigger OnDrillDown()
                    begin
                        DrillDown2DayTaks(3);
                    end;
                }
                field(ThursdayPair; ThursdayPair)
                {
                    ApplicationArea = All;
                    Caption = 'Thursday';
                    ToolTip = 'Requested | Assigned hours on Thursday.';
                    StyleExpr = WeekdayStyle;
                    trigger OnDrillDown()
                    begin
                        DrillDown2DayTaks(4);
                    end;
                }
                field(FridayPair; FridayPair)
                {
                    ApplicationArea = All;
                    Caption = 'Friday';
                    ToolTip = 'Requested | Assigned hours on Friday.';
                    StyleExpr = WeekdayStyle;
                    trigger OnDrillDown()
                    begin
                        DrillDown2DayTaks(5);
                    end;
                }
                field(SaturdayPair; SaturdayPair)
                {
                    ApplicationArea = All;
                    Caption = 'Saturday';
                    ToolTip = 'Requested | Assigned hours on Saturday.';
                    StyleExpr = WeekendStyle;
                    trigger OnDrillDown()
                    begin
                        DrillDown2DayTaks(6);
                    end;
                }
                field(SundayPair; SundayPair)
                {
                    ApplicationArea = All;
                    Caption = 'Sunday';
                    ToolTip = 'Requested | Assigned hours on Sunday.';
                    StyleExpr = WeekendStyle;
                    trigger OnDrillDown()
                    begin
                        DrillDown2DayTaks(7);
                    end;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(PreviousWeek)
            {
                ApplicationArea = All;
                Caption = 'Previous';
                Image = PreviousRecord;
                ToolTip = 'Go to the previous week.';

                trigger OnAction()
                var
                    WeekStart: Date;
                begin
                    WeekStart := CalcDate('<-1W>', DWY2Date(1, CurrentWeekNo, CurrentYear));
                    CurrentWeekNo := Date2DWY(WeekStart, 2);
                    CurrentYear := Date2DWY(WeekStart, 3);
                    ApplyWeekFilter();
                end;
            }
            action(TodayWeek)
            {
                ApplicationArea = All;
                Caption = 'Today';
                Image = Calendar;
                ToolTip = 'Go to the current week.';

                trigger OnAction()
                begin
                    CurrentWeekNo := Date2DWY(Today(), 2);
                    CurrentYear := Date2DWY(Today(), 3);
                    ApplyWeekFilter();
                end;
            }
            action(NextWeek)
            {
                ApplicationArea = All;
                Caption = 'Next';
                Image = NextRecord;
                ToolTip = 'Go to the next week.';

                trigger OnAction()
                var
                    WeekStart: Date;
                begin
                    WeekStart := CalcDate('<+1W>', DWY2Date(1, CurrentWeekNo, CurrentYear));
                    CurrentWeekNo := Date2DWY(WeekStart, 2);
                    CurrentYear := Date2DWY(WeekStart, 3);
                    ApplyWeekFilter();
                end;
            }
            action(ShowDayPlannings)
            {
                ApplicationArea = All;
                Caption = 'Show Day Plannings';
                Image = TaskList;
                ToolTip = 'View all day plannings for this resource and week.';

                trigger OnAction()
                var
                    DayPlanning: Record "Day Planning";
                    WeekStart: Date;
                    WeekEnd: Date;
                begin
                    if rec."Job No." = '' then begin
                        Message('No resource assigned for this job task.');
                        exit;
                    end;

                    WeekStart := GetWeekStartFromYearWeek(Rec.Year, Rec."Week No.");
                    WeekEnd := CalcDate('<+6D>', WeekStart);
                    DayPlanning.Reset();
                    if rec."Resource No." <> '' then
                        DayPlanning.SetRange("Assigned Resource No.", Rec."Resource No.");
                    if rec."Skill Code" <> '' then
                        DayPlanning.SetRange("Skill", Rec."Skill Code");
                    DayPlanning.SetRange("Job No.", Rec."Job No.");
                    DayPlanning.SetRange("Job Task No.", Rec."Job Task No.");
                    DayPlanning.SetRange("Task Date", WeekStart, WeekEnd);
                    Page.Run(Page::"Day Plannings", DayPlanning);
                end;
            }
            action(OpenSkills)
            {
                ApplicationArea = All;
                Caption = 'Resource Skills';
                Image = Skills;
                ToolTip = 'Open the skills card for this resource.';

                trigger OnAction()
                var
                    ResourceSkillsPage: Page "Resource Skills";
                    ResourceSkill: record "Resource Skill";
                    Type: enum "Resource Skill Type";
                begin
                    Rec.testfield("Skill Code");
                    ResourceSkill.Setrange(Type, Type::Resource);
                    ResourceSkill.SetRange("Skill Code", Rec."Skill Code");
                    ResourceSkillsPage.SetTableView(ResourceSkill);
                    ResourceSkillsPage.Run();
                end;
            }
            action("Day Plannings (Visual)")
            {
                ApplicationArea = All;
                Image = Capacities;
                trigger OnAction()
                var
                    ResScheduler: page "DHX Resource Scheduler";
                begin
                    rec.testfield("Resource No.");
                    ResScheduler.SetResourceFilter(Rec."Resource No.");
                    ResScheduler.RunModal();
                end;
            }
            action(OpenResourceCard)
            {
                ApplicationArea = All;
                Caption = 'Resource Card';
                Image = Resource;
                ToolTip = 'Open the resource card.';

                trigger OnAction()
                var
                    Resource: Record Resource;
                    WeekStart: Date;
                    WeekEnd: Date;
                begin
                    if Resource.Get(Rec."Resource No.") then begin
                        WeekStart := GetWeekStartFromYearWeek(Rec.Year, Rec."Week No.");
                        WeekEnd := CalcDate('<+6D>', WeekStart);
                        Resource.setrange("Date Filter", WeekStart, WeekEnd);
                        Page.Run(Page::"Resource Card", Resource);
                    end;
                end;
            }
            action(Refresh)
            {
                ApplicationArea = All;
                Caption = 'Refresh';
                Image = Refresh;
                ToolTip = 'Refresh the resource week view data.';

                trigger OnAction()
                begin
                    LoadData();
                end;
            }
        }
    }

    var
        JobNo: Code[20];
        JobTaskNo: Code[20];
        WeekdayStyle: Text;
        WeekendStyle: Text;
        ResourceName: Text[100];
        CurrentWeekNo: Integer;
        CurrentYear: Integer;
        TotalPair: Text;
        MondayPair: Text;
        TuesdayPair: Text;
        WednesdayPair: Text;
        ThursdayPair: Text;
        FridayPair: Text;
        SaturdayPair: Text;
        SundayPair: Text;

    trigger OnAfterGetRecord()
    var
        Resource: Record Resource;
    begin
        WeekdayStyle := 'Standard';
        WeekendStyle := 'Subordinate';

        if Resource.Get(Rec."Resource No.") then
            ResourceName := Resource.Name
        else
            ResourceName := '';

        TotalPair := FormatPair(Rec."Total Requested Hours", Rec."Total Assigned Hours");
        MondayPair := FormatPair(Rec."Monday Requested Hours", Rec."Monday Assigned Hours");
        TuesdayPair := FormatPair(Rec."Tuesday Requested Hours", Rec."Tuesday Assigned Hours");
        WednesdayPair := FormatPair(Rec."Wednesday Requested Hours", Rec."Wednesday Assigned Hours");
        ThursdayPair := FormatPair(Rec."Thursday Requested Hours", Rec."Thursday Assigned Hours");
        FridayPair := FormatPair(Rec."Friday Requested Hours", Rec."Friday Assigned Hours");
        SaturdayPair := FormatPair(Rec."Saturday Requested Hours", Rec."Saturday Assigned Hours");
        SundayPair := FormatPair(Rec."Sunday Requested Hours", Rec."Sunday Assigned Hours");
    end;

    procedure SetContext(NewJobNo: Code[20]; NewJobTaskNo: Code[20])
    begin
        JobNo := NewJobNo;
        JobTaskNo := NewJobTaskNo;
        CurrentWeekNo := Date2DWY(Today(), 2);
        CurrentYear := Date2DWY(Today(), 3);
        Rec.DeleteAll();
        LoadData();
    end;

    local procedure LoadData()
    begin
        if (JobNo = '') or (JobTaskNo = '') then
            exit;
        Rec.Reset();
        Rec.DeleteAll();
        Rec.FillSummary(JobNo, JobTaskNo);
        ApplyWeekFilter();
    end;

    local procedure ApplyWeekFilter()
    begin
        Rec.Reset();
        Rec.SetRange("Week No.", CurrentWeekNo);
        Rec.SetRange(Year, CurrentYear);
        CurrPage.Update(false);
    end;

    local procedure GetWeekStartFromYearWeek(YearValue: Integer; WeekNo: Integer): Date
    begin
        Exit(DWY2Date(1, WeekNo, YearValue));
    end;

    local procedure DrillDown2DayTaks(WeekDayNo: Integer)
    var
        Pg: Page "Day Plannings";
        Rc: Record "Day Planning";
        WeekFilter: Text;
        ReqHours: Decimal;
        AssHours: Decimal;
        FilterType: Integer;
    begin
        case WeekDayNo of
            0:
                begin
                    ReqHours := Rec."Total Requested Hours";
                    AssHours := Rec."Total Assigned Hours";
                end;
            1:
                begin
                    ReqHours := Rec."Monday Requested Hours";
                    AssHours := Rec."Monday Assigned Hours";
                end;
            2:
                begin
                    ReqHours := Rec."Tuesday Requested Hours";
                    AssHours := Rec."Tuesday Assigned Hours";
                end;
            3:
                begin
                    ReqHours := Rec."Wednesday Requested Hours";
                    AssHours := Rec."Wednesday Assigned Hours";
                end;
            4:
                begin
                    ReqHours := Rec."Thursday Requested Hours";
                    AssHours := Rec."Thursday Assigned Hours";
                end;
            5:
                begin
                    ReqHours := Rec."Friday Requested Hours";
                    AssHours := Rec."Friday Assigned Hours";
                end;
            6:
                begin
                    ReqHours := Rec."Saturday Requested Hours";
                    AssHours := Rec."Saturday Assigned Hours";
                end;
            7:
                begin
                    ReqHours := Rec."Sunday Requested Hours";
                    AssHours := Rec."Sunday Assigned Hours";
                end;
        end;

        if (ReqHours = 0) and (AssHours = 0) then
            exit;

        if (ReqHours <> 0) and (AssHours <> 0) then begin
            FilterType := StrMenu('Requested,Assigned', 0, 'Open Day Plannings for:');
            if FilterType = 0 then
                exit;
        end else
            if ReqHours <> 0 then
                FilterType := 1
            else
                FilterType := 2;

        if WeekDayNo = 0 then begin
            WeekFilter := StrSubstNo('%1..%2', Format(DWY2Date(1, Rec."Week No.", Rec.Year)), Format(DWY2Date(7, Rec."Week No.", Rec.Year)));
            Rc.SetFilter("Task Date", WeekFilter);
        end else
            Rc.SetRange("Task Date", DWY2Date(WeekDayNo, Rec."Week No.", Rec.Year));

        Rc.SetRange("Job No.", Rec."Job No.");
        Rc.SetRange("Job Task No.", Rec."Job Task No.");

        if FilterType = 1 then
            Rc.SetRange("Requested Resource No.", Rec."Resource No.")
        else
            Rc.SetRange("Assigned Resource No.", Rec."Resource No.");

        if Rec."Skill Code" <> '' then
            Rc.SetRange("Skill", Rec."Skill Code");

        Pg.SetTableView(Rc);
        Pg.Run();
    end;

    local procedure FormatPair(ReqHours: Decimal; AssHours: Decimal): Text
    begin
        if (ReqHours = 0) and (AssHours = 0) then
            exit('');
        exit(FormatHours(ReqHours) + ' | ' + FormatHours(AssHours));
    end;

    local procedure FormatHours(Hours: Decimal): Text
    begin
        if Hours = 0 then
            exit('–');
        exit(Format(Hours));
    end;
}
