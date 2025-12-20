pageextension 50601 "Job Card Opti" extends "Job Card"
{
    layout
    {
        // Add changes to page layout here
    }

    actions
    {
        // Add changes to page actions here
        addbefore("Resource &Allocated per Job")
        {
            action("Planning Lines Board")
            {
                ApplicationArea = All;
                Image = ResourcePlanning;
                Caption = 'Planning Lines Board';

                trigger OnAction()
                var
                    JobMgt: Codeunit "Job Planning Line Handler";
                begin
                    JobMgt.OpentaskSchedulerFromJob(Rec);
                end;
            }
        }
    }

    var
    //myInt: Integer;
}