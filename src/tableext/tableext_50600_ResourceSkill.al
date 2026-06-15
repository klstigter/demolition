tableextension 50600 "ResourceSkill opt." extends "Resource Skill"
{
    fields
    {
        // Add changes to table fields here
        field(50600; "Prefered"; Boolean)
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