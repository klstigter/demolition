table 50616 "Time Slot Canonical Index"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
        }
        field(2; "Hash Key"; Code[100])
        {
            Caption = 'Hash Key';
        }
        field(3; "Canonical Combination"; Text[2048])
        {
            Caption = 'Canonical Combination';
        }
        field(4; "Time Slot No."; Integer)
        {
            Caption = 'Time Slot No.';
        }
        field(5; "Canonical Length"; Integer)
        {
            Caption = 'Canonical Length';
        }
        field(6; "Canonical Combination Blob"; Blob)
        {
            Caption = 'Canonical Combination Blob';
            SubType = Memo;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Hash Key")
        {
        }
        key(Key3; "Time Slot No.")
        {
        }
    }
}
