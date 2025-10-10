page 50604 "DDSIA Object Selection"
{
    PageType = List;
    SourceTable = "DDSIA Object Selection";
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
                    ApplicationArea = All;
                }
                field("Object Name"; Rec."Object Name")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}