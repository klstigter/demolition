table 50607 "Update and Delete Log Opti"
{
    DataClassification = ToBeClassified;
    Caption = 'Update and Delete Log';

    fields
    {
        field(1; "Entry No."; Integer)
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

    procedure GetNextEntryNo(): Integer
    begin
        if not Rec.FindLast() then
            exit(1);
        exit(Rec."Entry No." + 1);
    end;

}