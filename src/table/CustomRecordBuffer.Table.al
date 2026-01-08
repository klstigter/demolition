table 50606 "CustomRecordBuffer"
{
    ReplicateData = false;
    TableType = Temporary;

    fields
    {
        field(1; "Code 1"; Code[20]) { }
        field(2; "Code 2"; Code[20]) { }
        field(3; "Code 3"; Code[20]) { }
    }

    keys
    {
        key(Key1; "Code 1", "Code 2", "Code 3")
        {
            Clustered = true;
        }
    }
}