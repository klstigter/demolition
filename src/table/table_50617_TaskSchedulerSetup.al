table 50617 "Task Scheduler Setup"
{
    DataClassification = CustomerContent;
    Caption = 'Task Scheduler Setup';

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
            DataClassification = CustomerContent;
        }
        field(10; "Envelope Color"; Text[20])
        {
            Caption = 'Envelope Color';
            DataClassification = CustomerContent;
        }
        field(20; "Envelope Border Color"; Text[20])
        {
            Caption = 'Envelope Border Color';
            DataClassification = CustomerContent;
        }
        field(30; "Assigned Color"; Text[20])
        {
            Caption = 'Assigned Color';
            DataClassification = CustomerContent;
        }
        field(40; "Requested Color"; Text[20])
        {
            Caption = 'Requested Color';
            DataClassification = CustomerContent;
        }
        field(50; "Timeline Hour Step"; Integer)
        {
            Caption = 'Timeline Hour Step';
            DataClassification = CustomerContent;
        }
        field(60; "Timeline Start Hour"; Integer)
        {
            Caption = 'Timeline Start Hour';
            DataClassification = CustomerContent;
        }
        field(70; "Timeline End Hour"; Integer)
        {
            Caption = 'Timeline End Hour';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }
}
