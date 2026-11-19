pageextension 50625 "Opti User Setup" extends "User Setup"
{
    layout
    {
        addlast(Control1)
        {
            field("Opti Planning Type"; Rec."Opti Planning Type")
            {
                Caption = 'Planning Type';
                ApplicationArea = All;
                ToolTip = 'Specifies the planning type for this user.';
            }
        }
    }
}
