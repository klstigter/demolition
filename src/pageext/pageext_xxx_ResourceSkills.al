pageextension 50607 "Opti ResourceSkills" extends "Resource Skills"
{
    layout
    {
        // Add changes to page layout here
        addafter("Skill Code")
        {
            field("Opti Prefered"; Rec."Opti Prefered")
            {
                Caption = 'Prefered';
                ToolTip = 'Specifies the value of the Prefered field.';
                ApplicationArea = All;
            }
        }
    }

    actions
    {
        // Add changes to page actions here
    }

    var
        myInt: Integer;
}