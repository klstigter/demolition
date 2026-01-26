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
        addafter(Control1906609707)
        {
            part(ResourceSkillsFactbox; "Resource Skills FactBox Part")
            {
                ApplicationArea = All;
                Caption = 'Resource Skills';
                SubPageLink = Type = const(Resource), "No." = field("No.");
            }
            part(DayTasksFactbox; "Day Tasks FactBox")
            {
                ApplicationArea = All;
                Caption = 'Day Tasks';
                SubPageLink = Type = const(Resource), "No." = field("No.");
            }
        }
    }

    actions
    {
        modify("S&kills")
        {
            Visible = false;
        }
        modify("S&kills_Promoted")
        {
            Visible = false;
        }

        // Add changes to page actions here
        addafter("Units of Measure")
        {
            action("S&kills_Custom")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'S&kills';
                Image = Skills;
                RunObject = Page "Resource Skills";
                RunPageLink = Type = const(Resource),
                                "No." = field("No.");
                ToolTip = 'View the assignment of skills to the resource. You can use skill codes to allocate skilled resources to service items or items that need special skills for servicing.';
            }
        }

        addafter(CreateTimeSheets_Promoted)
        {
            actionref("S&kills_Promoted_custom"; "S&kills_Custom")
            {
            }
        }
    }

    var
        myInt: Integer;
}