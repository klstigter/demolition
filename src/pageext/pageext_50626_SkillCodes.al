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
            field("Bar Color"; Rec."Bar Color")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the color of the bar that is used to represent this skill in the Bar chart.';
            }
        }
    }
}
