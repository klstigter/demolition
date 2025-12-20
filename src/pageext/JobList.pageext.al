pageextension 50602 "Job List Opti" extends "Job List"
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
            action("Planning Lines")
            {
                ApplicationArea = Jobs;
                Caption = 'Project Planning Lines';
                Image = ResourcePlanning;
                ToolTip = 'Show project planning lines in context of project no.';

                trigger OnAction()
                var
                    JobPlanningLine: Record "Job Planning Line";
                begin
                    JobPlanningLine.SetRange("Job No.", Rec."No.");
                    Page.RunModal(0, JobPlanningLine);
                end;
            }

            action("Planning Lines Board")
            {
                ApplicationArea = Jobs;
                Caption = 'Visual Planning';
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
                    RestMgt: Codeunit "Rest API Mgt.";
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
                    RestMgt: Codeunit "Rest API Mgt.";
                begin
                    RestMgt.PushProjectToPlanningIntegration(Rec, true);
                end;
            }
        }
        addafter("Job Task &Lines_Promoted")
        {
            actionref("Job Planning Lines Promoted"; "Planning Lines")
            {
            }
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

    trigger OnOpenPage()
    var
        myInt: Integer;
    begin
        Rec.SetFilter("Job View Type", '<>%1', Rec."Job View Type"::"Resource");
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec."Job View Type" := Rec."Job View Type"::Project;
    end;

    var
    //myInt: Integer;
}