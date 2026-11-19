tableextension 50600 "Opti ResourceSkill" extends "Resource Skill"
{
    fields
    {
        // Add changes to table fields here
        field(50600; "Opti Prefered"; Boolean)
        {
            Caption = 'Prefered';
            DataClassification = CustomerContent;
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