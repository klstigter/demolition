table 50601 "Opti Object Selection"
{
    Caption = 'Object Selection';
    ReplicateData = false;
    TableType = Temporary;
    LookupPageId = "Opti Object Selection";
    DrillDownPageId = "Opti Object Selection";

    fields
    {
        field(1; "Object ID"; Integer) { DataClassification = SystemMetadata; }
        field(2; "Object Name"; Text[250]) { DataClassification = SystemMetadata; }
    }

    keys
    {
        key(Key1; "Object ID")
        {
            Clustered = true;
        }
    }
}