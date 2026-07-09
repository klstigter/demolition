tableextension 50701 "Work Order Line Ext. Opt." extends "Work Order Line"
{
    fields
    {
        // Add changes to table fields here
        field(50; Depth; Decimal)
        {
            Caption = 'Depth';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                CalcAmount();
            end;
        }
        field(60; Diameter; Decimal)
        {
            Caption = 'Diameter';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                CalcAmount();
            end;
        }
        field(71; "Price"; Decimal)
        {
            Caption = 'Price';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                CalcAmount();
            end;
        }
    }

    keys
    {
        // Add changes to keys here
    }

    fieldgroups
    {
        // Add changes to field groups here
    }

    var
        myInt: Integer;

    local procedure CalcAmount()
    begin
        Amount := Rec.Quantity * Rec."Price";
    end;
}