table 50616 "Opti Time Slot Canonical Index"
{
    Caption = 'Time Slot Canonical Index';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'Entry No.';
            AutoIncrement = true;
        }
        field(2; "Hash Key"; Code[100])
        {
            DataClassification = SystemMetadata;
            Caption = 'Hash Key';
        }
        field(3; "Canonical Combination"; Text[2048])
        {
            DataClassification = SystemMetadata;
            Caption = 'Canonical Combination';
        }
        field(4; "Time Slot No."; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'Time Slot No.';
        }
        field(5; "Canonical Length"; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'Canonical Length';
        }
        field(6; "Canonical Combination Blob"; Blob)
        {
            DataClassification = SystemMetadata;
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
