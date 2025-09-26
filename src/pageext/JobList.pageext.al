pageextension 50602 "DDSIA Job List" extends "Job List"
{
    layout
    {
        // Add changes to page layout here
    }

    actions
    {
        // Add changes to page actions here
        addafter("Job Task &Lines")
        {
            action("Planning Lines Board")
            {
                ApplicationArea = Jobs;
                Caption = 'Planning Lines Board';
                Image = ResourcePlanning;
                ToolTip = 'Plan how you want to set up your planning information. In this window you can specify "Project Planning Line" per Task.';

                trigger OnAction()
                var
                    JobMgt: Codeunit "Job Planning Line Handler";
                begin
                    JobMgt.OpenTaskSchedulerAllJob();
                end;
            }
        }
        addafter("Job Task &Lines_Promoted")
        {
            actionref("Planning Lines Board Promoted"; "Planning Lines Board")
            {
            }
        }
    }

    var
        myInt: Integer;
}