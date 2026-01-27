tableextension 50602 "Job Ext" extends Job
{
    fields
    {
        // Add changes to table fields here
        field(50600; "Job View Type"; Enum "Job View Type")
        {
            DataClassification = ToBeClassified;
        }
        field(50601; "Non Active"; Boolean)
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