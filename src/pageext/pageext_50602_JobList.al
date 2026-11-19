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
            action("Opti Planning Lines")
            {
                ApplicationArea = Jobs;
                Caption = 'Project Planning Lines';
                Image = ResourcePlanning;
                ToolTip = 'Show project planning lines in context of project no.';

                trigger OnAction()
                var
                    JobPlanningLine: Record "Job Task";
                begin
                    JobPlanningLine.SetRange("Job No.", Rec."No.");
                    Page.RunModal(0, JobPlanningLine);
                end;
            }
        }
        addafter("Job Task &Lines_Promoted")
        {
            actionref("Opti Job Planning Lines Promoted"; "Opti Planning Lines")
            {
            }
        }
    }

    trigger OnOpenPage()
    var
        myInt: Integer;
    begin
        Rec.SetFilter("Opti Job View Type", '<>%1', Rec."Opti Job View Type"::"Resource");
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec."Opti Job View Type" := Rec."Opti Job View Type"::Project;
    end;

    var
    //myInt: Integer;
}