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
            action("PushToPlanningIntegration")
            {
                ApplicationArea = Jobs;
                Caption = 'Push to Planning Integration';
                Image = LinkWeb;
                ToolTip = 'Submit project, Tasks, and Planning Lines into Planning Integration system.';

                trigger OnAction()
                var
                    RestMgt: Codeunit "DDSIA Rest API Mgt.";
                begin
                    RestMgt.PushProjectToPlanningIntegration(Rec, false);
                end;
            }
            action("DownloadJsonRequest")
            {
                ApplicationArea = Jobs;
                Caption = 'Download JSon Request text';
                Image = LinkWeb;
                ToolTip = 'Download JSon Request text for Planning Integration system.';

                trigger OnAction()
                var
                    RestMgt: Codeunit "DDSIA Rest API Mgt.";
                begin
                    RestMgt.PushProjectToPlanningIntegration(Rec, true);
                end;
            }
        }
        addafter("Job Task &Lines_Promoted")
        {
            actionref("Planning Lines Board Promoted"; "Planning Lines Board")
            {
            }
            actionref("PushToPlanningIntegration Promoted"; "PushToPlanningIntegration")
            {
            }
            actionref("DownloadJsonRequest Promoted"; "DownloadJsonRequest")
            {
            }
        }
    }

    var
        myInt: Integer;
}