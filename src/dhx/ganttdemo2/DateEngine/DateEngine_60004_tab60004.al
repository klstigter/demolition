table 60004 "Date Span Test Result"
{
    Caption = 'Date Span Test Result';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
            AutoIncrement = true;
        }

        field(2; "Run DateTime"; DateTime)
        {
            Caption = 'Run At';
            DataClassification = SystemMetadata;
        }

        field(3; "Scenario Code"; Code[50])
        {
            Caption = 'Scenario Code';
            DataClassification = SystemMetadata;
        }

        field(4; "Scenario Description"; Text[100])
        {
            Caption = 'Scenario Description';
            DataClassification = SystemMetadata;
        }

        field(5; "Passed"; Boolean)
        {
            Caption = 'Passed';
            DataClassification = SystemMetadata;
        }

        field(6; "Message"; Text[250])
        {
            Caption = 'Message';
            DataClassification = SystemMetadata;
        }

        field(7; "Duration (ms)"; Integer)
        {
            Caption = 'Duration (ms)';
            DataClassification = SystemMetadata;
        }
        field(8; "Is Header"; Boolean)
        {
            Caption = 'Is Header';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }

        key(Key1; "Run DateTime", "Scenario Code")
        {
        }
    }
}
