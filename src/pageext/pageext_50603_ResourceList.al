pageextension 50603 "Opt ResourceList" extends "Resource List"
{
    layout
    {
        // Add changes to page layout here
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
            action("Daytasks (Visual)")
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    DaytaskScheduler: page "DHX Scheduler (Project)";
                begin
                    DaytaskScheduler.SetResourceFilter(GetSelectionFilter());
                    DaytaskScheduler.RunModal();
                end;
            }
        }
        addafter("Units of Measure_Promoted")
        {
            actionref("Schedule (Visual) actionref"; "Schedule (Visual)") { }
            actionref("Daytasks (Visual) actionref"; "Daytasks (Visual)") { }
        }
    }

    var
        myInt: Integer;
}