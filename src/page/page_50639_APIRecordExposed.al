// API Integeration for Exposing API Pages
page 50639 "API Record Exposed Opti"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "API Record Exposed Opti";

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field("API Page No."; Rec."API Page No.")
                {
                    ApplicationArea = All;
                }
                field("API Page Name"; Rec."API Page Name")
                {
                    ApplicationArea = All;
                }
                field("Table ID"; Rec."Table ID")
                {
                    ApplicationArea = All;
                }
                field("Table Name"; Rec."Table Name")
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