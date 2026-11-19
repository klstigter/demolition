pageextension 50601 "Job Card Opti" extends "Job Card"
{
    layout
    {
        // Add changes to page layout here
        addafter("Sell-to Customer Name")
        {
            field("Opti Non Active"; Rec."Opti Non Active")
            {
                ApplicationArea = All;
                Caption = 'Non Active';
                ToolTip = 'Indicates that the job is not active.';
            }
        }
    }

    actions
    {
        // Add changes to page actions here
        addbefore("Resource &Allocated per Job")
        {

        }
    }

    var
    //myInt: Integer;
}