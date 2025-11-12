page 50613 "Project Planning Activities"
{
    Caption = 'Project Planning';
    PageType = CardPart;
    RefreshOnActivate = true;
    SourceTable = "DDSIA PLanning Cue";
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

        // Rec.Setrange("Date Filter", WorkDate());
        // Rec.Setrange("Date Filter2", CalcDate('<1D>', WorkDate()));
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