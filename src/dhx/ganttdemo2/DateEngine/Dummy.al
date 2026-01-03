table 61290 MyTable
{
    DataClassification = ToBeClassified;

    fields
    {
        field(1; MyField; Integer)
        {
            DataClassification = ToBeClassified;

        }
        field(2; MyTextField; Text[100])
        {
            DataClassification = ToBeClassified;

        }
    }

    keys
    {
        key(Key1; MyField)
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
        message('Record inserted with MyField=%1 and MyTextField=%2', MyField, MyTextField);
    end;

    trigger OnModify()
    begin
        Message('test');
    end;

    trigger OnDelete()
    begin

    end;

    trigger OnRename()
    begin

    end;

}