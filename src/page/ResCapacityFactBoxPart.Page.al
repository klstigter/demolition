page 50629 "Res. Capacity FactBox Part"
{
    PageType = ListPart;
    SourceTable = "Res. Capacity Entry";
    Caption = 'Resource Capacity';
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(CapacityList)
            {
                field(Date; Rec.Date)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the date.';
                }
                field(Capacity; Rec.Capacity)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the capacity.';
                }
            }
        }
    }
}
