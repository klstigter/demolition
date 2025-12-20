table 50602 "Incoming Check"
{
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            DataClassification = ToBeClassified;
        }
        field(10; "Date Time"; DateTime)
        {
            DataClassification = ToBeClassified;
        }
        field(20; "Blob Data"; Blob)
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

    procedure GetLastEntryNo()
    var
        data: Record "Incoming Check";
    begin
        data.Reset();
        if data.FindLast() then
            Rec."Entry No." := data."Entry No." + 1
        else
            Rec."Entry No." := 1;
    end;
}