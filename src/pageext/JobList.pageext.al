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
        }
        addafter("Job Task &Lines_Promoted")
        {
            actionref("Job Planning Lines Promoted"; "Planning Lines")
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