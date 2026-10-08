table 50607 "Update and Delete Log Opti"
{
    DataClassification = ToBeClassified;
    Caption = 'Update and Delete Log';

    fields
    {
        field(1; "Entry No."; Integer)
        {
            DataClassification = ToBeClassified;
            AutoIncrement = true;
        }
        field(5; Action; enum "Update and Delete Log Action")
        {
            DataClassification = ToBeClassified;
        }
        field(10; "Record SystemId"; Guid)
        {
            DataClassification = ToBeClassified;
        }
        field(18; EntitySetName; Text[100])
        {
            DataClassification = ToBeClassified;
        }
        field(20; "Table No."; Integer)
        {
            DataClassification = ToBeClassified;
        }
        field(21; "Field No."; Integer)
        {
            DataClassification = ToBeClassified;
        }
        field(30; "Old Value"; Text[100])
        {
            DataClassification = ToBeClassified;
        }
        field(31; "New Value"; Text[100])
        {
            DataClassification = ToBeClassified;
        }
        field(40; "Modified At"; DateTime)
        {
            DataClassification = ToBeClassified;
        }
        field(50; "Synchronized At"; DateTime)
        {
            DataClassification = ToBeClassified;
        }
        field(60; Status; enum "Update and Delete Log Status")
        {
            DataClassification = ToBeClassified;
        }
        field(70; "API Field Name"; Text[150])
        {
            DataClassification = ToBeClassified;
            Caption = 'API Field Name';
        }

    }

    keys
    {
        key(Key1; "Entry No.")
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