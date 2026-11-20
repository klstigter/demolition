pageextension 50625 "User Setup Opt." extends "User Setup"
{
    layout
    {
        addlast(Control1)
        {
            field("Planning Type"; Rec."Planning Type")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the planning type for this user.';
            }
        }
    }
}
