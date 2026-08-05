table 50622 "Skill Req. vs Capacity Buffer"
{
    TableType = Temporary;
    Caption = 'Skill Requested vs Capacity Buffer';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Skill Code"; Code[10])
        {
            DataClassification = ToBeClassified;
            Caption = 'Skill Code';
            TableRelation = "Skill Code";
        }
        field(2; Description; Text[100])
        {
            DataClassification = ToBeClassified;
            Caption = 'Description';
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
        key(PK; "Skill Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Skill Code", Description)
        {
        }
    }
}
