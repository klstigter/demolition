table 50703 "Opti Day Cap. Chart Audit Buf"
{
    TableType = Temporary;
    Caption = 'Day Capacity Chart Audit Buffer';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Line No."; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'Line No.';
        }
        field(2; Day; Date)
        {
            DataClassification = SystemMetadata;
            Caption = 'Day';
        }
        field(3; "Day Name"; Text[10])
        {
            DataClassification = SystemMetadata;
            Caption = 'Day Name';
        }
        field(4; "Bar Type"; Enum "Opti Day Cap. Chart Bar Type")
        {
            DataClassification = SystemMetadata;
            Caption = 'Bar Type';
        }
        field(5; Segment; Code[20])
        {
            DataClassification = SystemMetadata;
            Caption = 'Segment';
        }
        field(10; Value; Decimal)
        {
            DataClassification = SystemMetadata;
            Caption = 'Value';
            DecimalPlaces = 0 : 2;
        }
    }

    keys
    {
        key(PK; "Line No.")
        {
            Clustered = true;
        }
    }
}
