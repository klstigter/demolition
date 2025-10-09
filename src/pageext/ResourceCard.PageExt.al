pageextension 50605 "DDSIAResourceCard" extends "Resource Card"
{
    layout
    {
        // Add changes to page layout here
        addafter("Search Name")
        {
            field("Planning Resource Id"; Rec."Planning Resource Id")
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
        myInt: Integer;
}