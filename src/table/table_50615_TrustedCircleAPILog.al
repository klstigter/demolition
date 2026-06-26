table 50615 "TrustedCircle API Log"
{
    DataClassification = CustomerContent;
    Caption = 'TrustedCircle API Log';

    fields
    {
        field(1; "Entry No."; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Entry No.';
        }
        field(10; Description; Text[100])
        {
            DataClassification = CustomerContent;
            Caption = 'Description';
        }
        field(20; "Method"; Option)
        {
            DataClassification = CustomerContent;
            Caption = 'Method';
            OptionMembers = GET,POST,PUT,PATCH,DELETE,HEAD,OPTIONS;
            OptionCaption = 'GET,POST,PUT,PATCH,DELETE,HEAD,OPTIONS';
        }
        field(30; "Endpoint URL"; Text[250])
        {
            DataClassification = CustomerContent;
            Caption = 'Endpoint URL';
        }
        field(40; "Request Payload"; Blob)
        {
            DataClassification = CustomerContent;
            Caption = 'Request Payload';
        }
        field(41; "Response Payload"; Blob)
        {
            DataClassification = CustomerContent;
            Caption = 'Response Payload';
        }
        field(50; "Response Code"; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Response Code';
        }
        field(60; "Created At"; DateTime)
        {
            DataClassification = CustomerContent;
            Caption = 'Created At';
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
