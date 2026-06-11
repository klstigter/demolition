pageextension 50605 "ResourceCard Opti" extends "Resource Card"
{
    layout
    {
        // Add changes to page layout here
        addafter("Personal Data")
        {
            part("Resource Day Plannings"; "Resource Day Plannings")
            {
                ApplicationArea = All;
                SubPageView = sorting("Task Date", "Day Line No.");
                SubPageLink = "Assigned Resource No." = field("No.");
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
                field("Is Pool"; Rec."Is Pool")
                {
                    ApplicationArea = All;
                    ToolTip = 'Indicates whether the resource is a pool resource.';
                }
                field("Is Foreman"; Rec."Is Foreman")
                {
                    ApplicationArea = All;
                    ToolTip = 'Indicates whether the resource is a foreman.';
                }
                field("External Resource"; Rec."External Resource")
                {
                    ApplicationArea = All;
                }
                field("Team Leader"; Rec."Team Leader")
                {
                    ApplicationArea = All;
                }
                field("Team Leader Name"; Rec."Team Leader Name")
                {
                    ApplicationArea = All;
                }
                field("Mandatory Schedulling"; Rec."Mandatory Schedulling")
                {
                    ApplicationArea = All;
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
            part(DayPlanningsFactbox; "Day Plannings FactBox")
            {
                ApplicationArea = All;
                Caption = 'Day Plannings';
                SubPageLink = "Assigned Resource No." = field("No.");
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
            action("Day Plannings (Visual)")
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    ResScheduler: page "DHX Resource Scheduler";
                begin
                    ResScheduler.SetResourceFilter(Rec."No.");
                    ResScheduler.RunModal();
                end;
            }
        }

        addafter(CreateTimeSheets_Promoted)
        {
            actionref("S&kills_Promoted_custom"; "S&kills_Custom")
            {
            }
            actionref("Day Plannings (Visual) actionref"; "Day Plannings (Visual)") { }
        }
    }

    var
        myInt: Integer;
}