page 50630 "Day Tasks"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "Day Tasks";
    Caption = 'Day Tasks';
    //Editable = false;
    DelayedInsert = true;
    layout
    {
        area(Content)
        {
            Group(JobFilter)

            {
                Caption = 'Filters';
                Visible = ShowFIlters;
                field("Job No. Filter"; GetTableViewFilter(rec.FieldNo("Job No.")))
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the job number to filter on.';
                    Visible = Not ShowJob;
                    Editable = false;
                }
                field("Job Task No. Filter"; GetTableViewFilter(rec.FieldNo("Job Task No.")))
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the job task number to filter on.';
                    Visible = Not ShowJobTask;
                    Editable = false;
                }
                field("No. Filter"; GetTableViewFilter(rec.FieldNo("No.")))
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the task date to filter on.';
                    Visible = Not ShowResource;
                    Editable = false;
                }
                field("Skill Filter"; GetTableViewFilter(rec.FieldNo("Skill")))
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the skill to filter on.';
                    Visible = Not ShowSkill;
                    Editable = false;
                }
                field("Plan Status Filter"; GetTableViewFilter(rec.FieldNo("Plan Status")))
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the planning status to filter on.';
                    Visible = Not ShowPlanStatus;
                    Editable = false;
                }

            }
            repeater(Lines)
            {
                field("Job No."; Rec."Job No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the job number.';
                    Visible = SHowJob;
                }
                field("Job Task No."; Rec."Job Task No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the job task number.';
                    Visible = ShowJobTask;
                }
                field(DayLineNo; Rec."Day Line No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the line number for this day task.';
                    StyleExpr = StyleStr;
                    visible = false;
                }
                field("Plan Status"; Rec."Plan Status")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the planning status of this day task.';
                    StyleExpr = StyleStr;
                }

                field("Task Date"; Rec."Task Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the day number in the sequence.';
                    StyleExpr = StyleStr;

                }

                field("Data Owner"; Rec."Data Owner")
                {
                    Caption = 'Data Owner';
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the type of planning line.';
                    StyleExpr = StyleStr;
                    Visible = false;
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of the resource, item, or G/L account.';
                    StyleExpr = StyleStr;
                    Visible = ShowResource;
                }
                field(skill; Rec.skill)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the skill associated with the resource.';
                    StyleExpr = StyleStr;
                    Visible = ShowSkill;
                }
                field("Assigned Hours"; Rec."Assigned Hours")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of requested hours for this day task, calculated automatically based on start and end times.';
                    Editable = true;
                    StyleExpr = StyleStr;
                }
                field("Requested Hours"; Rec."Requested Hours")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of requested hours for this day task, calculated automatically based on start and end times.';
                    Editable = false;
                    StyleExpr = StyleStr;
                }
                field("Total Assigned Hours"; TotAssignedHours)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the total number of assigned hours for this day task, calculated automatically based on all related day tasks.';
                    Editable = false;
                    StyleExpr = StyleStr;
                    trigger OnDrillDown()
                    var
                        DayTask: Page "Day Tasks";
                        DayTaskRec: Record "Day Tasks";
                    begin

                        if rec."No." = '' then
                            exit;
                        DayTaskRec.setrange("No.", Rec."No.");
                        DayTaskRec.SetRange("Task Date", Rec."Task Date");
                        DayTask.SetTableView(DayTaskRec);
                        DayTask.RunModal();
                    end;
                }
                field(Capacity; Rec.Capacity)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the capacity available for this day task.';
                    Editable = false;
                    StyleExpr = StyleStr;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the unit of measure code.';
                    StyleExpr = StyleStr;
                    Visible = false;
                }
                field("Start Time Assigned"; Rec."Start Time Assigned")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the start time for this day.';
                    StyleExpr = StyleStr;
                }
                field("End Time Assigned"; Rec."End Time Assigned")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the end time for this day.';
                    StyleExpr = StyleStr;
                }
                field("Start Time Requested"; Rec."Start Time Requested")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the start time for this day task.';
                    StyleExpr = StyleStr;
                }
                field("End Time Requested"; Rec."End Time Requested")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the end time for this day task.';
                    StyleExpr = StyleStr;
                }
                field("Non Working Hours"; Rec."Non Working Minutes")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of non-working hours in a 24-hour period for this day task.';
                    StyleExpr = StyleStr;
                }

                field(Fulfilled; StyleStr)
                {
                    ApplicationArea = All;
                    ToolTip = 'Indicates whether the day task has fulfilled the required capacity.';
                    Editable = false;
                }
                field("Resource Group No."; Rec."Resource Group No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the resource group number.';
                    StyleExpr = StyleStr;
                }
                field("Pool Resource No."; Rec."Pool Resource No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the pool resource number.';
                    StyleExpr = StyleStr;
                }
                field("Pool Resource Name"; Rec."Pool Resource Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the pool resource name.';
                    Editable = false;
                    StyleExpr = StyleStr;
                }

                field("Vendor No."; Rec."Vendor No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the vendor number.';
                    StyleExpr = StyleStr;
                }
                field("Vendor Name"; Rec."Vendor Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the vendor name.';
                    StyleExpr = StyleStr;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the description.';
                    StyleExpr = StyleStr;
                }
                field("Team Leader"; Rec."Team Leader")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the team leader for this day task.';
                }
                field(Leader; Rec.Leader)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the leader for this day task.';
                }
                field("Work Type Code"; Rec."Work Type Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the work type code.';
                    StyleExpr = StyleStr;
                }
                field(Depth; Rec.Depth)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the depth.';
                    StyleExpr = StyleStr;
                }
                field(IsBoor; Rec.IsBoor)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies if this is a boor line.';
                    StyleExpr = StyleStr;
                }
                field("Worked Hours"; Rec."Worked Hours")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the actual worked hours for this day task.';
                    Editable = true;
                    StyleExpr = StyleStr;
                }


            }
        }
        area(FactBoxes)
        {
            part(DayTaskInfo; "Day Task Information FactBox")
            {
                ApplicationArea = All;
                SubPageLink = "Task Date" = field("Task Date"),
                              "Day Line No." = field("Day Line No."),
                              "Job No." = field("Job No."),
                              "Job Task No." = field("Job Task No.");
            }
            part(ResourceSkills; "Resource Skills FactBox Part")
            {
                ApplicationArea = All;
                Caption = 'Resource Skills';
                SubPageLink = Type = const(Resource), "No." = field("No.");
            }
            part(ResourceCapacity; "Res. Capacity FactBox Part")
            {
                ApplicationArea = All;
                Caption = 'Resource Capacity';
                SubPageLink = "Resource No." = field("No."),
                              Date = field("Task Date");
            }
        }
    }

    actions
    {
        area(Processing)
        {

            action(RefreshDayPlanning)
            {
                ApplicationArea = All;
                Caption = 'Refresh Day Planning';
                ToolTip = 'Refreshes the day planning lines.';
                Image = Refresh;
                Visible = false;
                trigger OnAction()
                begin
                    CurrPage.Update(false);
                end;
            }
        }
    }
    var
        StyleOpt: option None,Standard,StandardAccent,Strong,StrongAccent,Attention,AttentionAccent,Favorable,Unfavorable,Ambiguous,Subordinate;
        StyleStr: text;
        GenUtilties: Codeunit "General Planning Utilities";
        TotAssignedHours: Decimal;
        SHowJob: Boolean;
        ShowJobTask: Boolean;
        ShowResource: Boolean;
        ShowSkill: Boolean;
        ShowPlanStatus: Boolean;
        ShowFIlters: Boolean;

    trigger OnInit()
    begin
        ShowJob := true;
        ShowJobTask := true;
        ShowResource := true;
        ShowSkill := true;
    end;

    trigger OnOpenPage()
    begin

    end;

    trigger OnAfterGetRecord()
    begin
        this.CalculateStyle();
        GetTotalAssignedHours();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        this.CalculateStyle();
        GetTotalAssignedHours();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        if not ShowJob then
            Rec."Job No." := GetTableViewFilter(rec.FieldNo("Job No."));
        if not ShowJobTask then
            Rec."Job Task No." := GetTableViewFilter(rec.FieldNo("Job Task No."));
        if not ShowResource then
            Rec."No." := GetTableViewFilter(rec.FieldNo("No."));
        if not ShowSkill then
            Rec.Skill := GetTableViewFilter(rec.FieldNo("Skill"));

    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean

    var
        DayNo: Integer;
    begin
        rec."Day Line No." := rec.GetNextDayLineNo(rec."Task Date", rec."Job No.", rec."Job Task No.");
        rec.TestField("No.");
        exit(true);
    end;

    local procedure CalculateStyle()
    begin
        rec.CalcFields(Capacity, "Total Assigned Hours");
        case true of
            rec."No." = '':
                StyleOpt := StyleOpt::StrongAccent;
            rec.Capacity = 0:
                StyleOpt := StyleOpt::Unfavorable;
            (this.TotAssignedHours < rec.Capacity) and (rec."Assigned Hours" > 0):
                StyleOpt := StyleOpt::StandardAccent;
            (this.TotAssignedHours > rec.Capacity):
                StyleOpt := StyleOpt::Attention;
            rec."Capacity Fully Utilized":
                StyleOpt := StyleOpt::Subordinate;
        end;
        StyleStr := Format(StyleOpt);
    end;

    procedure GetTotalAssignedHours(): Decimal
    begin
        if rec."No." = '' then
            TotAssignedHours := 0
        else begin
            rec.CalcFields("Total Assigned Hours");
            TotAssignedHours := Rec."Total Assigned Hours";
        end;

    end;

    procedure SetColumsVisible(pShowJob: Boolean; pShowJobTask: Boolean; pShowResource: Boolean; pShowSkill: Boolean; pShowPlanStatus: Boolean);
    begin
        ShowJob := not pShowJob;
        ShowJobTask := not pShowJobTask;
        ShowResource := not pShowResource;
        ShowSkill := not pShowSkill;
        ShowPlanStatus := not pShowPlanStatus;
        ShowFIlters := True;
    end;

    local procedure GetTableViewFilter(FieldNo: Integer) fieldFilter: text
    begin
        rec.FilterGroup(2);
        case FieldNo of
            rec.FieldNo("Job No."):
                fieldFilter := Rec.GetFilter("Job No.");
            rec.FieldNo("Job Task No."):
                fieldFilter := Rec.GetFilter("Job Task No.");
            rec.FieldNo("No."):
                fieldFilter := Rec.GetFilter("No.");
            rec.FieldNo("Skill"):
                fieldFilter := Rec.GetFilter("Skill");
        end;
        rec.FilterGroup(0);
        if fieldFilter = '''''' then
            fieldFilter := '';
    end;
}
