table 50622 "Skill Req. vs Capacity Buffer"
{
    TableType = Temporary;
    Caption = 'Skill Requested vs Capacity Buffer';
    DataClassification = ToBeClassified;

    fields
    {

        field(1; "Bar Type"; Enum "Day Capacity Chart Bar Type")
        {
            DataClassification = ToBeClassified;
            Caption = 'Bar Type';
        }
        field(2; "No."; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Skill Code';

        }
        field(3; "Week Day No."; Integer)
        {
            DataClassification = ToBeClassified;
            Caption = 'Week Day No.';
        }
        field(10; "Requested Hours"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Requested Hours';
            DecimalPlaces = 0 : 2;
        }
    }

    keys
    {
        key(PK; "Bar Type", "No.", "Week Day No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", "Week Day No.", "Requested Hours")
        {
        }

    }
}
