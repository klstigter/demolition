page 50628 "Resource Skills FactBox Part"
{
    PageType = ListPart;
    SourceTable = "Resource Skill";
    Caption = 'Resource Skills';
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Skills)
            {
                field("Skill Code"; Rec."Skill Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the skill code.';
                }
                field("Assigned From"; Rec."Assigned From")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies where the skill was assigned from.';
                }
            }
        }
    }
}
