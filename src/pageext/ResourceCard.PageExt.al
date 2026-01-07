pageextension 50605 "ResourceCard Opti" extends "Resource Card"
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
        addafter("Personal Data")
        {
            part("Resource Day Tasks"; "Resource Day Tasks")
            {
                ApplicationArea = All;
                SubPageView = sorting("Day No.", DayLineNo) where(Type = const(Resource));
                SubPageLink = "No." = field("No.");
                UpdatePropagation = Both;
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