table 50661 "DayTask Sync Preview Buffer"
{
    Caption = 'DayTask Sync Preview Buffer';
    DataClassification = SystemMetadata;
    TableType = Temporary;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'Entry No.';
        }
        field(2; "Job No."; Code[20])
        {
            DataClassification = SystemMetadata;
            Caption = 'Job No.';
        }
        field(3; "Job Task No."; Code[20])
        {
            DataClassification = SystemMetadata;
            Caption = 'Job Task No.';
        }
        field(4; "Day Line No."; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'Day Line No.';
        }
        field(5; "Old Task Date"; Date)
        {
            DataClassification = SystemMetadata;
            Caption = 'Current Date';
        }
        field(6; "New Task Date"; Date)
        {
            DataClassification = SystemMetadata;
            Caption = 'New Date';
        }
        field(7; "Resource No."; Code[20])
        {
            DataClassification = SystemMetadata;
            Caption = 'Resource';
        }
        field(8; Description; Text[100])
        {
            DataClassification = SystemMetadata;
            Caption = 'Description';
        }
        field(9; "Day Type"; Enum "DayTask Date Type")
        {
            DataClassification = SystemMetadata;
            Caption = 'Day Type';
        }
        field(10; "Convert to DayTask"; Boolean)
        {
            DataClassification = SystemMetadata;
            Caption = 'Convert to DayTask';
            InitValue = true;
        }
        field(11; "Is New Record"; Boolean)
        {
            DataClassification = SystemMetadata;
            Caption = 'Is New Record';
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
    }
}
