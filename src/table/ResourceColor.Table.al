table 50600 "Resource Color Opt."
{
    DataClassification = ToBeClassified;
    Caption = 'Resource Color';
    LookupPageId = "Resource Color opt";
    DrillDownPageId = "Resource Color opt";

    fields
    {
        field(1; "Resource No."; Code[20])
        {
            DataClassification = ToBeClassified;
        }
        field(10; "Day Task"; Text[30])
        {
            DataClassification = ToBeClassified;
        }
        field(20; "Capacity"; Text[30])
        {
            DataClassification = ToBeClassified;
        }
    }

    keys
    {
        key(Key1; "Resource No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        // Add changes to field groups here
    }

    var
        myInt: Integer;

    trigger OnInsert()
    begin

    end;

    trigger OnModify()
    begin

    end;

    trigger OnDelete()
    begin

    end;

    trigger OnRename()
    begin

    end;

}