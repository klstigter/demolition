pageextension 50610 "DDSIA Job Task Card" extends "Job Task Card"
{
    layout
    {
        // Add changes to page layout here
        addbefore("Job Task No.")
        {
            field("Job No."; Rec."Job No.")
            {
                ApplicationArea = Jobs;
                ToolTip = 'Specifies the number of the related project.';
                trigger OnAssistEdit()
                var
                    Job: Record Job;
                begin
                    if Page.RunModal(0, Job) = Action::LookupOK then begin
                        Rec.Validate("Job No.", JOb."No.");
                    end
                end;
            }
        }
    }

    actions
    {
        // Add changes to page actions here
    }

    var
    //myInt: Integer;
}