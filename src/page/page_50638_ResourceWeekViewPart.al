page 50638 "Resource Week View Part"
{
    PageType = Card;
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
                field("Total Week Hours"; Rec."Total Week Hours")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies total hours for the week.';
                    Style = Strong;
                }
                field("Monday Hours"; Rec."Monday Hours")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies hours on Monday.';
                    StyleExpr = WeekdayStyle;
                }
                field("Tuesday Hours"; Rec."Tuesday Hours")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies hours on Tuesday.';
                    StyleExpr = WeekdayStyle;
                }
                field("Wednesday Hours"; Rec."Wednesday Hours")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies hours on Wednesday.';
                    StyleExpr = WeekdayStyle;
                }
                field("Thursday Hours"; Rec."Thursday Hours")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies hours on Thursday.';
                    StyleExpr = WeekdayStyle;
                }
                field("Friday Hours"; Rec."Friday Hours")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies hours on Friday.';
                    StyleExpr = WeekdayStyle;
                }
                field("Saturday Hours"; Rec."Saturday Hours")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies hours on Saturday.';
                    StyleExpr = WeekendStyle;
                }
                field("Sunday Hours"; Rec."Sunday Hours")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies hours on Sunday.';
                    StyleExpr = WeekendStyle;
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
                ToolTip = 'View all day tasks for this resource and week.';

                trigger OnAction()
                var
                    DayTask: Record "Day Tasks";
                    WeekStart: Date;
                    WeekEnd: Date;
                begin
                    if rec."Job No." = '' then begin
                        Message('No resource assigned for this job task.');
                        exit;
                    end;

                    WeekStart := GetWeekStartFromYearWeek(Rec.Year, Rec."Week No.");
                    WeekEnd := CalcDate('<+6D>', WeekStart);
                    DayTask.Reset();
                    if rec."Resource No." <> '' then
                        DayTask.SetRange("No.", Rec."Resource No.");
                    if rec."Skill Code" <> '' then
                        DayTask.SetRange("Skill", Rec."Skill Code");
                    DayTask.SetRange("Job No.", Rec."Job No.");
                    DayTask.SetRange("Job Task No.", Rec."Job Task No.");
                    DayTask.SetRange("Task Date", WeekStart, WeekEnd);
                    Page.Run(Page::"Day Tasks", DayTask);
                end;
            }
            action(OpenSkills)
            {
                ApplicationArea = All;
                Caption = 'Show Skills';
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
            action("Day Tasks (Visual)")
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
        TaskId: Integer;

    trigger OnAfterGetRecord()
    var
        Resource: Record Resource;
    begin
        WeekdayStyle := 'Standard';
        WeekendStyle := 'Subordinate';

        // Get Resource Name
        if Resource.Get(Rec."Resource No.") then
            ResourceName := Resource.Name
        else
            ResourceName := '';
    end;

    procedure SetContext(NewJobNo: Code[20]; NewJobTaskNo: Code[20])
    begin
        JobNo := NewJobNo;
        JobTaskNo := NewJobTaskNo;
        Rec.DeleteAll();
        LoadData();
        CurrPage.Update(false);
    end;

    local procedure LoadData()
    begin
        if (JobNo = '') or (JobTaskNo = '') then
            exit;
        Rec.FillSummary(JobNo, JobTaskNo);
    end;

    local procedure GetWeekStartFromYearWeek(YearValue: Integer; WeekNo: Integer): Date
    var
        Jan4: Date;
        Week1Monday: Date;
    begin
        Exit(DWY2Date(1, WeekNo, YearValue));
    end;
}
