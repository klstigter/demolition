pageextension 50603 "Opt ResourceList" extends "Resource List"
{
    layout
    {
        // Add changes to page layout here
        addafter(Type)
        {
            field("Pool Resource No."; Rec."Pool Resource No.")
            {
                ApplicationArea = All;
            }
            field("Vendor No."; Rec."Vendor No.")
            {
                ApplicationArea = All;
            }
            field("Is Pool"; Rec."Is Pool")
            {
                ApplicationArea = All;
            }
            field("Is Pool Member"; Rec."Is Pool Member")
            {
                ApplicationArea = All;
            }
            field("Is External"; Rec."Is External")
            {
                ApplicationArea = All;
            }
            field("Is Foreman"; Rec."Is Foreman")
            {
                ApplicationArea = All;
            }
            field("Mandatory Schedulling"; Rec."Mandatory Schedulling")
            {
                ApplicationArea = All;
            }
            field("Default Foreman"; Rec."Default Foreman")
            {
                ApplicationArea = All;
            }
            field("Default Foreman Name"; Rec."Default Foreman Name")
            {
                ApplicationArea = All;
            }

        }
    }

    actions
    {
        // Add changes to page actions here
        addafter("&Resource")
        {
            action("Schedule (Visual)")
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    ResScheduler: page "DHX Resource Scheduler";
                begin
                    ResScheduler.SetResourceFilter(GetSelectionFilter());
                    ResScheduler.RunModal();
                end;
            }
            action("DayPlannings (Visual)")
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    DayPlanningScheduler: page "DHX Scheduler (Project)";
                begin
                    DayPlanningScheduler.SetResourceFilter(GetSelectionFilter());
                    DayPlanningScheduler.RunModal();
                end;
            }
            action("Capacity (Visual)")
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    ResScheduler: page "DHX Scheduler (Pool Resource)";
                begin
                    //ResScheduler.SetResourceFilter(Rec."No.");
                    ResScheduler.RunModal();
                end;
            }
            action("Set Capacity Opt")
            {
                ApplicationArea = Jobs;
                Caption = '&Set Capacity';
                RunObject = Page "Resource Capacity Settings Opt";
                RunPageLink = "No." = field("No.");
                ToolTip = 'Change the capacity of the resource, such as a technician.';
            }
            action("Absence")
            {
                ApplicationArea = All;
                Caption = 'Absence';
                Image = Absence;
                RunObject = page "Resource Absence List";
                RunPageLink = "Resource No." = field("No."), Type = const(Absence);
                ToolTip = 'View and register absence entries for this resource.';
            }


        }
        addafter("Ledger E&ntries_Promoted")
        {
            Group(Capacity)
            {
                Caption = 'Capacity';
                ShowAs = SplitButton;
                Image = Planning;
                actionref("Set Capacity Opt actionref"; "Set Capacity Opt") { }
                actionref("Absence_actionref"; "Absence") { }
                actionref("Resource &Capacity_actionref"; "Resource &Capacity") { }
            }
            Group(Visuals)
            {
                Caption = 'Planning';
                ShowAs = SplitButton;
                Image = Planning;
                actionref("Schedule (Visual) actionref"; "Schedule (Visual)") { }
                actionref("DayPlannings (Visual) actionref"; "DayPlannings (Visual)") { }
                actionref("Capacity actionref"; "Capacity (Visual)") { }
            }
        }
    }

    var
        myInt: Integer;
}