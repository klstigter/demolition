table 50624 "Opti Resource Capacity"
{
    Caption = 'Resource Capacity';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Resource No."; Code[20])
        {
            Caption = 'Resource No.';
            TableRelation = Resource."No.";
        }

        field(2; "Capacity Date"; Date)
        {
            Caption = 'Capacity Date';
        }

        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
            Editable = false;
        }

        field(10; "Entry Type"; enum "Opti Capacity Entry Type")
        {
            Caption = 'Entry Type';

        }

        field(20; "Day Time Slot Header ID"; Integer)
        {
            Caption = 'Day Time Slot ID';
            TableRelation = "Opti Day Time Slots Header"."Day Time Slot Header ID";
        }

        field(30; Description; Text[100])
        {
            Caption = 'Description';
        }

        field(40; "Working Minutes"; Integer)
        {
            Caption = 'Working Minutes';
            FieldClass = FlowField;
            CalcFormula = lookup("Opti Day Time Slots Header"."Total Working Minutes"
                where("Day Time Slot Header ID" = field("Day Time Slot Header ID")));
            Editable = false;
        }

        field(50; "Working Hours"; Decimal)
        {
            Caption = 'Working Hours';
            FieldClass = FlowField;
            CalcFormula = lookup("Opti Day Time Slots Header"."Total Working Hours"
                where("Day Time Slot Header ID" = field("Day Time Slot Header ID")));
            DecimalPlaces = 0 : 5;
            Editable = false;
        }

        field(60; Manual; Boolean)
        {
            Caption = 'Manual';
        }
    }

    keys
    {
        key(PK; "Resource No.", "Capacity Date", "Line No.")
        {
            Clustered = true;
        }

        key(ResourceDate; "Resource No.", "Capacity Date")
        {
        }
    }

    trigger OnInsert()
    begin
        if "Line No." = 0 then
            "Line No." := GetNextLineNo("Resource No.", "Capacity Date");
    end;

    procedure GetNextLineNo(ResourceNo: Code[20]; CapacityDate: Date): Integer
    var
        ResourceCapacity: Record "Opti Resource Capacity";
    begin
        ResourceCapacity.Reset();
        ResourceCapacity.SetRange("Resource No.", ResourceNo);
        ResourceCapacity.SetRange("Capacity Date", CapacityDate);

        if ResourceCapacity.FindLast() then
            exit(ResourceCapacity."Line No." + 10000);

        exit(10000);
    end;


}
