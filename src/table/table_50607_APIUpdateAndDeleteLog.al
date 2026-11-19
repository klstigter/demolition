// API Integeration for Exposing API Pages
table 50607 "Update and Delete Log Opti"
{
    DataClassification = SystemMetadata;
    Caption = 'Update and Delete Log';

    fields
    {
        field(1; "Entry No."; Integer)
        {
            DataClassification = SystemMetadata;
            AutoIncrement = true;
        }
        field(5; Action; enum "Opti Upd. Del. Log Action")
        {
            DataClassification = SystemMetadata;
        }
        field(10; "Record SystemId"; Guid)
        {
            DataClassification = SystemMetadata;
        }
        field(18; EntitySetName; Text[100])
        {
            DataClassification = SystemMetadata;
        }
        field(20; "Table No."; Integer)
        {
            DataClassification = SystemMetadata;
        }
        field(21; "Field No."; Integer)
        {
            DataClassification = SystemMetadata;
        }
        field(30; "Old Value"; Text[100])
        {
            DataClassification = CustomerContent;
        }
        field(31; "New Value"; Text[100])
        {
            DataClassification = CustomerContent;
        }
        field(40; "Modified At"; DateTime)
        {
            DataClassification = SystemMetadata;
        }
        field(50; "Synchronized At"; DateTime)
        {
            DataClassification = SystemMetadata;
        }
        field(60; Status; enum "Opti Upd. Del. Log Status")
        {
            DataClassification = SystemMetadata;
        }
        field(70; "API Field Name"; Text[150])
        {
            DataClassification = SystemMetadata;
            Caption = 'API Field Name';
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
        if Status <> xRec.Status then
            if Status = Status::Synchronized then
                "Synchronized At" := CurrentDateTime()
            else
                "Synchronized At" := 0DT;
    end;

    trigger OnDelete()
    begin
        testfield(Status, Status::Synchronized);
    end;

    trigger OnRename()
    begin
    end;

}