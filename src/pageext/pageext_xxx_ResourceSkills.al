pageextension 50607 "ResourceSkills Opt." extends "Resource Skills"
{
    layout
    {
        // Add changes to page layout here
        addafter("Skill Code")
        {
            field(Prefered; Rec.Prefered)
            {
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