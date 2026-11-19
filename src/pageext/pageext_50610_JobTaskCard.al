pageextension 50610 "Opti DDSIA Job Task Card" extends "Job Task Card"
{
    layout
    {
        // Add changes to page layout here
        addafter(Description)
        {
            field("Opti Non Active"; Rec."Opti Non Active")
            {
                ApplicationArea = All;
                Caption = 'Non Active';
                ToolTip = 'Indicates that the job task is not active.';
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