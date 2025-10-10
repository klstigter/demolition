tableextension 50602 "DDSIAUserSetup" extends "User Setup"
{
    fields
    {
        // Add changes to table fields here
        field(50600; "Planning User ID"; Integer)
        {
            DataClassification = ToBeClassified;
        }
        field(50601; "Planning User Name"; Text[250])
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