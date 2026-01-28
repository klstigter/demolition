page 50613 "Project Planning Activities"
{
    Caption = 'Project Planning';
    PageType = CardPart;
    RefreshOnActivate = true;
    SourceTable = "PLanning Cue";
    ShowFilter = false;

    layout
    {
        area(Content)
        {
            cuegroup("Today")
            {
                field(Projects; Rec.ProjectCount(gViewType::Project, Today(), false))
                {
                    Caption = 'Project';
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Some tooltip';

                    trigger OnDrillDown()
                    var
                        myInt: Integer;
                    begin
                        myInt := Rec.ProjectCount(gViewType::Project, Today(), true)
                    end;
                }
                field("Project Tasks"; Rec.TaskCount(gViewType::Project, Today(), false))
                {
                    Caption = 'Task';
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Some tooltip';
                    trigger OnDrillDown()
                    var
                        myInt: Integer;
                    begin
                        myInt := Rec.TaskCount(gViewType::Project, Today(), true)
                    end;
                }
                field("Capacity (Today)"; Rec."Capacity (Today)")
                {
                    Caption = 'Capacity';
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Capacity for today.';
                }
                field("Daytask (Today)"; Rec."Daytask (Today)")
                {
                    Caption = 'Daytask';
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Number of day tasks for today.';
                }
            }
            cuegroup("Tomorrow")
            {
                field(ProjectsTomorrow; Rec.ProjectCount(gViewType::Project, CalcDate('<1D>', Today()), false))
                {
                    Caption = 'Project';
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Some tooltip';
                    trigger OnDrillDown()
                    var
                        myInt: Integer;
                    begin
                        myInt := Rec.ProjectCount(gViewType::Project, CalcDate('<1D>', Today()), true);
                    end;
                }
                field("ProjectTomorrow"; Rec.TaskCount(gViewType::Project, CalcDate('<1D>', Today()), false))
                {
                    Caption = 'Task';
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Some tooltip';
                    trigger OnDrillDown()
                    var
                        myInt: Integer;
                    begin
                        myInt := Rec.TaskCount(gViewType::Project, CalcDate('<1D>', Today()), true);
                    end;
                }
                field("Capacity (Tomorrow)"; Rec."Capacity (Tomorrow)")
                {
                    Caption = 'Capacity';
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Capacity for tomorrow.';
                }
                field("Daytask (Tomorrow)"; Rec."Daytask (Tomorrow)")
                {
                    Caption = 'Daytask';
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Number of day tasks for tomorrow.';
                }
            }

            cuegroup("Active")
            {
                field(Projects_Active; Rec.Projects)
                {
                    Caption = 'Project';
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Project count including all active projects.';
                }
                field("Tasks_Active"; Rec."Project Tasks")
                {
                    Caption = 'Task';
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Project Task count including all active project tasks.';
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;

        Rec.Setrange("Date Filter", Today());
        Rec.Setrange("Date Filter2", CalcDate('<1D>', Today()));
    end;

    trigger OnAfterGetRecord()
    begin

    end;

    trigger OnAfterGetCurrRecord()
    begin

    end;

    trigger OnInit()
    begin

    end;

    var
        gViewType: enum "Job View Type";



}