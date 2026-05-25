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
                field("Total Week Hours"; Rec."Total Week Hours")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies total hours for the week.';
                    Style = Strong;
                    trigger OnDrillDown()
                    begin
                        DrillDown2DayTaks(0);
                    end;
                }
                field("Monday Hours"; Rec."Monday Hours")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies hours on Monday.';
                    StyleExpr = WeekdayStyle;
                    trigger OnDrillDown()
                    begin
                        DrillDown2DayTaks(1);
                    end;
                }
                field("Tuesday Hours"; Rec."Tuesday Hours")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies hours on Tuesday.';
                    StyleExpr = WeekdayStyle;
                    trigger OnDrillDown()
                    begin
                        DrillDown2DayTaks(2);
                    end;
                }
                field("Wednesday Hours"; Rec."Wednesday Hours")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies hours on Wednesday.';
                    StyleExpr = WeekdayStyle;
                    trigger OnDrillDown()
                    begin
                        DrillDown2DayTaks(3);
                    end;
                }
                field("Thursday Hours"; Rec."Thursday Hours")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies hours on Thursday.';
                    StyleExpr = WeekdayStyle;
                    trigger OnDrillDown()
                    begin
                        DrillDown2DayTaks(4);
                    end;
                }
                field("Friday Hours"; Rec."Friday Hours")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies hours on Friday.';
                    StyleExpr = WeekdayStyle;
                    trigger OnDrillDown()
                    begin
                        DrillDown2DayTaks(5);
                    end;
                }
                field("Saturday Hours"; Rec."Saturday Hours")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies hours on Saturday.';
                    StyleExpr = WeekendStyle;
                    trigger OnDrillDown()
                    begin
                        DrillDown2DayTaks(6);
                    end;
                }
                field("Sunday Hours"; Rec."Sunday Hours")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies hours on Sunday.';
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
                        DayTask.SetRange("Assigned Resource No.", Rec."Resource No.");
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
    end;

    local procedure LoadData()
    begin
        if (JobNo = '') or (JobTaskNo = '') then
            exit;
        Rec.FillSummary(JobNo, JobTaskNo);
        Rec.SetRange("Week No.", Date2DWY(Today(), 2));
        CurrPage.Update(false);
    end;

    local procedure GetWeekStartFromYearWeek(YearValue: Integer; WeekNo: Integer): Date
    var
        Jan4: Date;
        Week1Monday: Date;
    begin
        Exit(DWY2Date(1, WeekNo, YearValue));
    end;

    local procedure DrillDown2DayTaks(WeekDayNo: Integer)
    var
        Pg: Page "Day Tasks";
        Rc: Record "Day Tasks";
        WeekFilter: Text;
    begin
        if WeekDayNo = 0 then begin
            WeekFilter := StrSubstNo('%1..%2', Format(DWY2Date(1, rec."Week No.", rec.Year)), Format(DWY2Date(7, rec."Week No.", rec.Year)));
            rc.SetFilter("Task Date", WeekFilter);
        end else
            rc.SetRange("Task Date", DWY2Date(WeekDayNo, rec."Week No.", rec.Year));

        // rc.FilterGroup(2);
        // if ShowJob then
        rc.SetRange("Job No.", Rec."Job No.");
        // if ShowJobTask then
        Rc.SetRange("Job Task No.", Rec."Job Task No.");
        // if ShowResource then
        rc.SetRange("Assigned Resource No.", Rec."Resource No.");
        // if ShowSkillCode then
        rc.SetRange("Skill", Rec."Skill Code");
        // rc.FilterGroup(0);
        PG.SetTableView(Rc);

        // pg.SetColumsVisible(ShowJob, ShowJobTask, ShowResource, ShowSkillCode);
        Pg.Run();
    end;
}
