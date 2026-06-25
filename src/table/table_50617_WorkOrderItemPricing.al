table 50617 "Work Order Item Pricing"
{
    Caption = 'Work Order Item Pricing';
    DataClassification = CustomerContent;
    LookupPageId = "Work Order Item Pricing";
    DrillDownPageId = "Work Order Item Pricing";

    fields
    {
        field(1; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            DataClassification = CustomerContent;
            TableRelation = Item."No.";

            trigger OnValidate()
            var
                Item: Record Item;
            begin
                if "Item No." = '' then begin
                    Description := '';
                    exit;
                end;
                Item.Get("Item No.");
                if Description = '' then
                    Description := Item.Description;
            end;
        }
        field(2; "Sales Type"; Enum "WO Item Price Sales Type")
        {
            Caption = 'Sales Type';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                "Sales Code" := '';
            end;
        }
        field(3; "Sales Code"; Code[20])
        {
            Caption = 'Sales Code';
            DataClassification = CustomerContent;
            TableRelation =
                if ("Sales Type" = const(Customer)) Customer."No."
                else if ("Sales Type" = const("Customer Price Group")) "Customer Price Group".Code;
        }
        field(4; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
            DataClassification = CustomerContent;
        }
        field(5; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            DataClassification = CustomerContent;
            TableRelation = Currency.Code;
        }
        field(6; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            DataClassification = CustomerContent;
            TableRelation = "Unit of Measure".Code;
        }
        field(7; "Minimum Quantity"; Decimal)
        {
            Caption = 'Minimum Quantity';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(8; "Unit Price"; Decimal)
        {
            Caption = 'Unit Price';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(9; "Ending Date"; Date)
        {
            Caption = 'Ending Date';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if ("Ending Date" <> 0D) and ("Starting Date" <> 0D) and ("Ending Date" < "Starting Date") then
                    Error(EndingDateBeforeStartErr, FieldCaption("Ending Date"), FieldCaption("Starting Date"));
            end;
        }
        field(10; Description; Text[100])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "Item No.", "Sales Type", "Sales Code", "Starting Date", "Currency Code", "Unit of Measure Code", "Minimum Quantity")
        {
            Clustered = true;
        }
        key(SalesCode; "Sales Type", "Sales Code", "Item No.")
        {
        }
    }

    var
        EndingDateBeforeStartErr: Label '%1 cannot be before %2.', Comment = '%1 = Ending Date caption, %2 = Starting Date caption';
}
