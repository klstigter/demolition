pageextension 50610 "DDSIA Job Task Card" extends "Job Task Card"
{
    layout
    {
        // Add changes to page layout here
        addafter(Description)
        {
            field("Non Active"; Rec."Non Active")
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