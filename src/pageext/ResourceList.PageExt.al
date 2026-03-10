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
            action("Day Tasks (Visual)")
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
        }
        addafter("Units of Measure_Promoted")
        {
            actionref("Day Tasks (Visual) actionref"; "Day Tasks (Visual)") { }
        }
    }

    var
        myInt: Integer;
}