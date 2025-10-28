tableextension 50604 "DDSIAItem" extends Item
{
    fields
    {
        // Add changes to table fields here
        field(50600; "Planning Product Id"; Integer)
        {
            DataClassification = ToBeClassified;
        }
        field(50601; "Planning Product Name"; Text[100])
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
        myInt: Integer;
}