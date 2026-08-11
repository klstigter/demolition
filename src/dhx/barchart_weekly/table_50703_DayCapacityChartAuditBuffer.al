table 50703 "Day Capacity Chart Audit Buf"
{
    TableType = Temporary;
    Caption = 'Day Capacity Chart Audit Buffer';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Line No."; Integer)
        {
            DataClassification = ToBeClassified;
            Caption = 'Line No.';
        }
        field(2; Day; Date)
        {
            DataClassification = ToBeClassified;
            Caption = 'Day';
        }
        field(3; "Day Name"; Text[10])
        {
            DataClassification = ToBeClassified;
            Caption = 'Day Name';
        }
        field(4; "Bar Type"; Enum "Day Capacity Chart Bar Type")
        {
            DataClassification = ToBeClassified;
            Caption = 'Bar Type';
        }
        field(5; Segment; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Segment';
        }
        field(10; Value; Decimal)
        {
            DataClassification = ToBeClassified;
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
