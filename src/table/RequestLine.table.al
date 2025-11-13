table 50605 "Request Line"
{
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Request No."; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Request No.';
        }
        field(2; "Line No."; Integer)
        {
            DataClassification = ToBeClassified;
            Caption = 'Line No.';
        }
    }

    keys
    {
        key(Key1; "Request No.", "Line No.")
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