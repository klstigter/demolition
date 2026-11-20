table 50601 "Object Selection"
{
    ReplicateData = false;
    TableType = Temporary;
    LookupPageId = "Object Selection";
    DrillDownPageId = "Object Selection";

    fields
    {
        field(1; "Object ID"; Integer) { }
        field(2; "Object Name"; Text[250]) { }
    }

    keys
    {
        key(Key1; "Object ID")
        {
            Clustered = true;
        }
    }
}