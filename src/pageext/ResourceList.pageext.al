pageextension 50603 "Resource List Opti" extends "Resource List"
{
    layout
    {
        // Add changes to page layout here
        addafter(Name)
        {
            field("Planning Resource Id"; Rec."Planning Resource Id")
            {
                ApplicationArea = All;
                Editable = false;
            }
            field("Planning Vendor Id"; Rec."Planning Vendor Id")
            {
                ApplicationArea = All;
                Editable = false;
            }
        }
    }

    actions
    {
        // // Add changes to page actions here
        // addafter(Statistics)
        // {
        //     action("Resources Board")
        //     {
        //         ApplicationArea = Jobs;
        //         Caption = 'Visual Planning';
        //         Image = ResourcePlanning;
        //         ToolTip = 'Show Resources by "Project Planning Line"';

        //         trigger OnAction()
        //         var
        //             ResMgt: Codeunit "Resource DayPilot Handler";
        //         begin
        //             ResMgt.GetResourceAndEventsPerTask();
        //         end;
        //     }
        // }
        // addafter(Statistics_Promoted)
        // {
        //     actionref("Resources Board Promoted"; "Resources Board")
        //     {
        //     }
        // }
    }

    var
        myInt: Integer;
}