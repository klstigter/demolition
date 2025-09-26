pageextension 50603 "DDSIA Resource List" extends "Resource List"
{
    layout
    {
        // Add changes to page layout here
    }

    actions
    {
        // Add changes to page actions here
        addafter(Statistics)
        {
            action("Resources Board")
            {
                ApplicationArea = Jobs;
                Caption = 'Resources Board';
                Image = ResourcePlanning;
                ToolTip = 'Show Resources by "Project Planning Line"';

                trigger OnAction()
                var
                    ResMgt: Codeunit "Resource DayPilot Handler";
                begin
                    ResMgt.GetResourceAndEventsPerTask();
                end;
            }
        }
        addafter(Statistics_Promoted)
        {
            actionref("Resources Board Promoted"; "Resources Board")
            {
            }
        }
    }

    var
        myInt: Integer;
}