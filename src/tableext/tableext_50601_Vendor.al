tableextension 50601 "Vendor Ext" extends Vendor
{
    fields
    {
        // Add changes to table fields here
        field(50600; "Planning Vendor id"; Integer)
        {
            DataClassification = ToBeClassified;
        }
        field(50601; "Planning Vendor Name"; Text[250])
        {
            DataClassification = ToBeClassified;
            Editable = false;
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
    //myInt: Integer;
}