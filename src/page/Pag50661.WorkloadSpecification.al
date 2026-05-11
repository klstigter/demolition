page 50661 "Workorder Cap. Req. Subfrm"
{
    Caption = 'Workorder Capacity Request Subfrm';
    PageType = ListPart;
    SourceTable = "Workorder Capacity Request";
    ApplicationArea = All;
    SourceTableView = sorting("Workorder No.", "Line No.");

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Line No."; Rec."Line No.")
                {
                    ApplicationArea = All;
                    Visible = true;
                }
                field("Sequence No."; Rec."Sequence No.")
                {
                    ApplicationArea = All;
                }
                field("Resource No."; Rec."Resource No.")
                {
                    ApplicationArea = All;
                }
                field("Resource Group Code"; Rec."Resource Group Code")
                {
                    ApplicationArea = All;
                }
                field("Skill Code"; Rec."Skill Code")
                {
                    ApplicationArea = All;
                }
                field("Amount of Resources"; Rec."Amount of Resources")
                {
                    ApplicationArea = All;
                }
                field(Quantity; Rec.Hours)
                {
                    ApplicationArea = All;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }
                field(Mandatory; Rec.Mandatory)
                {
                    ApplicationArea = All;
                }

            }
        }
    }
}