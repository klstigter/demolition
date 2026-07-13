pageextension 50626 "Skill Codes Opt." extends "Skill Codes"
{
    layout
    {
        addafter(Description)
        {
            field("Invoice Resource No."; Rec."Invoice Resource No.")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the resource that should be used when invoicing usage recorded under this skill.';
            }
        }
    }
}
