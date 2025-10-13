pageextension 50607 "DDSIAJobProjectManagerRC" extends "Job Project Manager RC"
{
    layout
    {
        // Add changes to page layout here        
    }

    actions
    {
        // Add changes to page actions here
        addafter(RecurringJobJournals)
        {
            action("VisualPlanning")
            {
                ApplicationArea = All;
                Caption = 'Visual Planning';
                RunObject = codeunit "Job Planning Line Handler";
            }
        }
        addafter("Resource Registers")
        {
            action("VisualPlanningRes")
            {
                ApplicationArea = All;
                Caption = 'Visual Planning';
                RunObject = codeunit "Resource DayPilot Handler";
            }
        }

    }

    var
        myInt: Integer;
}