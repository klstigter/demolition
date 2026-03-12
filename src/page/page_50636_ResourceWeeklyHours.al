page 50636 "Resource Weekly Hours"
{
    PageType = List;
    SourceTable = "Resource Weekly Hours";
    SourceTableTemporary = true;
    Caption = 'Resource Weekly Hours';
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
                field("Week No."; Rec."Week No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the ISO week number.';
                }
                field(Year; Rec.Year)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the year.';
                }
                field("Monday Hours"; Rec."Monday Hours")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies total hours on Monday.';
                    StyleExpr = WeekdayStyle;
                }
                field("Tuesday Hours"; Rec."Tuesday Hours")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies total hours on Tuesday.';
                    StyleExpr = WeekdayStyle;
                }
                field("Wednesday Hours"; Rec."Wednesday Hours")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies total hours on Wednesday.';
                    StyleExpr = WeekdayStyle;
                }
                field("Thursday Hours"; Rec."Thursday Hours")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies total hours on Thursday.';
                    StyleExpr = WeekdayStyle;
                }
                field("Friday Hours"; Rec."Friday Hours")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies total hours on Friday.';
                    StyleExpr = WeekdayStyle;
                }
                field("Saturday Hours"; Rec."Saturday Hours")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies total hours on Saturday.';
                    StyleExpr = WeekendStyle;
                }
                field("Sunday Hours"; Rec."Sunday Hours")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies total hours on Sunday.';
                    StyleExpr = WeekendStyle;
                }
                field("Total Week Hours"; Rec."Total Week Hours")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies total hours for the entire week.';
                    Style = Strong;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ShowDayTasks)
            {
                ApplicationArea = All;
                Caption = 'Show Day Tasks';
                Image = TaskList;
                ToolTip = 'View all day tasks for this week.';

                trigger OnAction()
                var
                    DayTask: Record "Day Tasks";
                    WeekStart: Date;
                    WeekEnd: Date;
                begin
                    WeekStart := GetWeekStartFromYearWeek(Rec.Year, Rec."Week No.");
                    WeekEnd := CalcDate('<+6D>', WeekStart);
                    DayTask.Reset();
                    DayTask.SetRange("No.", Rec."Resource No.");
                    DayTask.SetRange("Job No.", Rec."Job No.");
                    DayTask.SetRange("Job Task No.", Rec."Job Task No.");
                    DayTask.SetRange("Task Date", WeekStart, WeekEnd);
                    Page.Run(Page::"Day Tasks", DayTask);
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
                begin
                    if Resource.Get(Rec."Resource No.") then
                        Page.Run(Page::"Resource Card", Resource);
                end;
            }
            action(OpenJobTaskCard)
            {
                ApplicationArea = All;
                Caption = 'Job Task Card';
                Image = Task;
                ToolTip = 'Open the job task card.';

                trigger OnAction()
                var
                    JobTask: Record "Job Task";
                begin
                    if JobTask.Get(Rec."Job No.", Rec."Job Task No.") then
                        Page.Run(Page::"Job Task Card", JobTask);
                end;
            }
        }
    }

    var
        WeekdayStyle: Text;
        WeekendStyle: Text;

    trigger OnAfterGetRecord()
    begin
        WeekdayStyle := 'Standard';
        WeekendStyle := 'Subordinate';
    end;

    local procedure GetWeekStartFromYearWeek(YearValue: Integer; WeekNo: Integer): Date
    var
        Jan4: Date;
        Week1Monday: Date;
    begin
        // ISO 8601: Week 1 is the week with Jan 4th
        Jan4 := DMY2Date(4, 1, YearValue);
        Week1Monday := CalcDate(StrSubstNo('<-%1D>', Date2DWY(Jan4, 1) - 1), Jan4);
        exit(CalcDate(StrSubstNo('<+%1W>', WeekNo - 1), Week1Monday));
    end;

    procedure LoadData(ResourceNo: Code[20]; JobNo: Code[20]; JobTaskNo: Code[20])
    begin
        Rec.FillBuffer(ResourceNo, JobNo, JobTaskNo);
    end;
}
