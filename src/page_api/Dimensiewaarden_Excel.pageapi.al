page 50602 Dimensiewaarden_Excel
{
    PageType = API;
    APIPublisher = 'Wycliffe';
    APIGroup = 'salesForce';
    APIVersion = 'v2.0';
    EntityName = 'dimension';
    EntitySetName = 'dimensions';
    DelayedInsert = true;
    SourceTable = "Dimension Value";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(dimensionCode; Rec."Dimension Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for the dimension.';
                }
                field(code; Rec.Code)
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for the dimension value.';
                }
                field(name; Rec.Name)
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies a descriptive name for the dimension value.';
                }
                field(dimensionValueType; Rec."Dimension Value Type")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the purpose of the dimension value.';
                }

                field(blocked; Rec.Blocked)
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies that the related record is blocked from being posted in transactions, for example a customer that is declared insolvent or an item that is placed in quarantine.';
                }
            }
        }
    }
}