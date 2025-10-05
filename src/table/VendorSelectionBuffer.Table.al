table 50601 "DDSIA Vendor Selection"
{
    ReplicateData = false;
    TableType = Temporary;
    LookupPageId = "DDSIA Vendor Selection";
    DrillDownPageId = "DDSIA Vendor Selection";

    fields
    {
        field(1; "Vendor ID"; Integer) { }
        field(2; "Vendor Name"; Text[250]) { }
    }

    keys
    {
        key(Key1; "Vendor ID")
        {
            Clustered = true;
        }
    }
}