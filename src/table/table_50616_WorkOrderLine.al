table 50616 "Work Order Line"
{
    Caption = 'Work Order Line';
    DataClassification = CustomerContent;
    LookupPageId = "Work Order Lines";
    DrillDownPageId = "Work Order Lines";

    fields
    {
        field(1; "Work Order No."; Code[20])
        {
            Caption = 'Work Order No.';
            DataClassification = CustomerContent;
            TableRelation = "Work Order"."Work Order No.";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
            DataClassification = CustomerContent;
        }
        field(20; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            DataClassification = CustomerContent;
            TableRelation = Item."No.";

            trigger OnValidate()
            var
                Item: Record Item;
                WOItemPriceCalc: Codeunit "WO Item Price Calc.";
            begin
                if "Item No." = '' then begin
                    Description := '';
                    "Item Price" := 0;
                    Amount := 0;
                    exit;
                end;
                Item.Get("Item No.");
                Description := Item.Description;
                // Start from the item's base unit price, then try to find a better price
                "Item Price" := Item."Unit Price";
                WOItemPriceCalc.GetBestPrice(Rec);
                CalcAmount();
            end;
        }
        field(30; Description; Text[100])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
        }
        field(40; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            var
                WOItemPriceCalc: Codeunit "WO Item Price Calc.";
            begin
                if "Item No." <> '' then
                    WOItemPriceCalc.GetBestPrice(Rec);
                CalcAmount();
            end;
        }
        field(50; Depth; Decimal)
        {
            Caption = 'Depth';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
        }
        field(60; Diameter; Decimal)
        {
            Caption = 'Diameter';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
        }
        field(70; "Item Price"; Decimal)
        {
            Caption = 'Item Price';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                price := Depth * "Item Price";
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
        field(80; Amount; Decimal)
        {
            Caption = 'Amount';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Work Order No.", "Line No.")
        {
            Clustered = true;
        }
    }

    trigger OnInsert()
    begin
        if "Line No." = 0 then
            "Line No." := GetNextLineNo();
    end;

    local procedure GetNextLineNo(): Integer
    var
        WorkOrderLine: Record "Work Order Line";
    begin
        WorkOrderLine.SetRange("Work Order No.", "Work Order No.");
        if WorkOrderLine.FindLast() then
            exit(WorkOrderLine."Line No." + 10000);
        exit(10000);
    end;

    local procedure CalcAmount()
    begin
        Amount := Quantity * "Price";
    end;
}
