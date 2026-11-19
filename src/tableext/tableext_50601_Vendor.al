tableextension 50601 "Opti Vendor" extends Vendor
{
    fields
    {
        // Add changes to table fields here
        field(50600; "Opti Planning Vendor id"; Integer)
        {
            Caption = 'Planning Vendor id';
            DataClassification = CustomerContent;
        }
        field(50601; "Opti Planning Vendor Name"; Text[250])
        {
            Caption = 'Planning Vendor Name';
            DataClassification = CustomerContent;
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