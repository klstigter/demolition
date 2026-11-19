page 50604 "Opti Object Selection"
{
    PageType = List;
    SourceTable = "Opti Object Selection";
    ApplicationArea = All;
    Editable = false;
    Caption = 'Object Selection';

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Objectr ID"; Rec."Object ID")
                {
                    ToolTip = 'Specifies the value of the Objectr ID field.';
                    ApplicationArea = All;
                }
                field("Object Name"; Rec."Object Name")
                {
                    ToolTip = 'Specifies the value of the Object Name field.';
                    ApplicationArea = All;
                }
            }
        }
    }
}