page 50651 "Daytask Order Intake Opt."
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "Daytask Order Intake Opt.";
    Caption = 'Daytask Order Intake';
    SourceTableView = sorting("Daytask Date")
                      order(ascending);

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Daytask Date"; Rec."Daytask Date")
                {
                    ApplicationArea = All;
                }
                field("Daytask Start"; Rec."Daytask Start")
                {
                    ApplicationArea = All;
                }
                field("Daytask End"; Rec."Daytask End")
                {
                    ApplicationArea = All;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }
                field("Resource No."; Rec."Resource No.")
                {
                    ApplicationArea = All;
                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field("Resource Name"; Rec."Resource Name")
                {
                    ApplicationArea = All;
                }
                field("Skill"; Rec."Skill")
                {
                    ApplicationArea = All;
                }
                field("Status"; Rec."Status")
                {
                    ApplicationArea = All;
                }
            }
        }
        area(Factboxes)
        {

        }
    }

    actions
    {
        area(Processing)
        {
            action(ActionName)
            {

                trigger OnAction()
                begin

                end;
            }
        }
    }
}