pageextension 50611 "ItemList Opti" extends "Item List"
{
    layout
    {
        // Add changes to page layout here
        addafter("No.")
        {
            field("Planning Product Id"; Rec."Planning Product Id")
            {
                ApplicationArea = All;
            }
            field("Planning Product Name"; Rec."Planning Product Name")
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