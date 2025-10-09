pageextension 50600 "DDSIA Job Planning Lines" extends "Job Planning Lines"
{
    layout
    {
        // Add changes to page layout here
        addafter("Planning Date")
        {
            field("End Planning Date"; Rec."End Planning Date")
            {
                ApplicationArea = All;
            }
            field("Start Time"; Rec."Start Time")
            {
                ApplicationArea = All;
            }
            field("End Time"; Rec."End Time")
            {
                ApplicationArea = All;
            }
        }
        addbefore("Document No.")
        {
            field("Vendor No."; Rec."Vendor No.")
            {
                ApplicationArea = All;
            }
            field("Vendor Name"; Rec."Vendor Name")
            {
                ApplicationArea = All;
            }
        }
    }

    actions
    {
        // Add changes to page actions here
    }

    var
    //myInt: Integer;
}