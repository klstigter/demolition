tableextension 50603 "Resource Opt" extends Resource
{
    fields
    {
        // Add changes to table fields here
        field(50600; "Pool Resource No."; Code[20])
        {
            DataClassification = ToBeClassified;
            tablerelation = Resource;
        }
    }

    keys
    {
        // Add changes to keys here
    }

    fieldgroups
    {
        addlast(DropDown; "Resource Group No.")
        {
        }
    }

    var

}