pageextension 50605 "ResourceCard Opti" extends "Resource Card"
{
    layout
    {
        // Add changes to page layout here
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
        addafter(Invoicing)
        {
            group(Purchase)
            {
                field("Vendor No."; Rec."Vendor No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the vendor number associated with the resource.';
                }
                field("Pool Resource No."; Rec."Pool Resource No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the pool resource number associated with the resource.';
                }
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