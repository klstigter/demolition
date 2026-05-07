page 50656 "Order Intake Sub Card"
{
    PageType = ListPart;
    SourceTable = "Order Intake Line Opt.";
    DelayedInsert = true;
    AutoSplitKey = true;

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
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
                }
                field("Resource Name"; Rec."Resource Name")
                {
                    ApplicationArea = All;
                }
                field(Skill; Rec.Skill)
                {
                    ApplicationArea = All;
                }
            }
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