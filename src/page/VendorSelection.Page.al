page 50604 "DDSIA Vendor Selection"
{
    PageType = List;
    SourceTable = "DDSIA Vendor Selection";
    ApplicationArea = All;
    Editable = false;
    Caption = 'Vendor Selection';

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Vendor ID"; Rec."Vendor ID")
                {
                    ApplicationArea = All;
                }
                field("Vendor Name"; Rec."Vendor Name")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}