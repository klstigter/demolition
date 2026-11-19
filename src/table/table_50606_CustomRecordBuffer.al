table 50606 "Opti CustomRecordBuffer"
{
    Caption = 'CustomRecordBuffer';
    ReplicateData = false;
    TableType = Temporary;

    fields
    {
        field(1; "Code 1"; Code[20]) { DataClassification = SystemMetadata; }
        field(2; "Code 2"; Code[20]) { DataClassification = SystemMetadata; }
        field(3; "Code 3"; Code[20]) { DataClassification = SystemMetadata; }
    }

    keys
    {
        key(Key1; "Code 1", "Code 2", "Code 3")
        {
            Clustered = true;
        }
    }
}