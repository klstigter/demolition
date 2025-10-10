table 50601 "DDSIA Object Selection"
{
    ReplicateData = false;
    TableType = Temporary;
    LookupPageId = "DDSIA Object Selection";
    DrillDownPageId = "DDSIA Object Selection";

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