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
        field(10; "Table ID"; Integer)
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