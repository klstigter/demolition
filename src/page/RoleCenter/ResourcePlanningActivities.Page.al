page 50614 "Resource Planning Activities"
{
    Caption = 'Resource Planning';
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
                field("Projects (Resource)"; Rec.ProjectCount(gViewType::Resource, Today(), false))
                {
                    Caption = 'Project';
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Some tooltip';
                    trigger OnDrillDown()
                    var
                        myInt: Integer;
                    begin
                        myInt := Rec.ProjectCount(gViewType::Resource, Today(), true);
                    end;
                }
                field("Project Tasks (Resource)"; Rec.TaskCount(gViewType::Resource, Today(), false))
                {
                    Caption = 'Task';
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Some tooltip';
                    trigger OnDrillDown()
                    var
                        myInt: Integer;
                    begin
                        myInt := Rec.TaskCount(gViewType::Resource, Today(), true);
                    end;
                }
            }
            cuegroup("Tomorrow")
            {
                field("Projects tomorrow (Resource)"; Rec.ProjectCount(gViewType::Resource, CalcDate('<1D>', Today()), false))
                {
                    Caption = 'Project';
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Some tooltip';
                    trigger OnDrillDown()
                    var
                        myInt: Integer;
                    begin
                        myInt := Rec.ProjectCount(gViewType::Resource, CalcDate('<1D>', Today()), true);
                    end;
                }
                field("Project Tasks tomorrow(Resource)"; Rec.TaskCount(gViewType::Resource, CalcDate('<1D>', Today()), false))
                {
                    Caption = 'Task';
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Some tooltip';
                    trigger OnDrillDown()
                    var
                        myInt: Integer;
                    begin
                        myInt := Rec.TaskCount(gViewType::Resource, CalcDate('<1D>', Today()), true);
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