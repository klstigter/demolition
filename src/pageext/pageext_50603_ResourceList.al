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
            field("External Resource"; Rec."External Resource")
            {
                ApplicationArea = All;
            }
            field("Is Pool"; Rec."Is Pool")
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
            field("Team Leader"; Rec."Team Leader")
            {
                ApplicationArea = All;
            }
            field("Team Leader Name"; Rec."Team Leader Name")
            {
                ApplicationArea = All;
            }

        }
    }

    actions
    {
        // Add changes to page actions here
        addafter("&Prices")
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
        }
        addafter("Units of Measure_Promoted")
        {
            actionref("Schedule (Visual) actionref"; "Schedule (Visual)") { }
            actionref("DayPlannings (Visual) actionref"; "DayPlannings (Visual)") { }
        }
    }

    var
        myInt: Integer;
}