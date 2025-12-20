tableextension 50603 "Resource Ext" extends Resource
{
    fields
    {
        // Add changes to table fields here
        field(50600; "Planning Resource Id"; Integer)
        {
            DataClassification = ToBeClassified;
        }
        field(50601; "Planning Vendor Id"; Integer)
        {
            DataClassification = ToBeClassified;
        }
    }

    keys
    {
        // Add changes to keys here
    }

    fieldgroups
    {
        // Add changes to field groups here
    }

    var
        myInt: Integer;
}