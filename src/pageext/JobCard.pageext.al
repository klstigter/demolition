pageextension 50601 "DDSIA Job Card" extends "Job Card"
{
    layout
    {
        // Add changes to page layout here
        addafter("Sell-to Customer Name")
        {
            field("Vendor No."; Rec."Vendor No.")
            {
                ApplicationArea = All;
            }
            field("Vendor Name"; Rec."Vendor Name")
            {
                ApplicationArea = All;
            }
        }
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