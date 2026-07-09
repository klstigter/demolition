pageextension 50701 MyExtension extends "Work Order Lines"
{
    layout
    {
        // Add changes to page layout here
        addafter(Quantity)
        {
            field(Depth; Rec.Depth)
            {
                ApplicationArea = All;
            }
            field(Diameter; Rec.Diameter)
            {
                ApplicationArea = All;
            }
        }
        addafter("Item Price")
        {
            field(Price; Rec.Price)
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