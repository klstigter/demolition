tableextension 50602 "Opti Job" extends Job
{
    fields
    {
        // Add changes to table fields here
        field(50600; "Opti Job View Type"; Enum "Opti Job View Type")
        {
            Caption = 'Job View Type';
            DataClassification = CustomerContent;
        }
        field(50601; "Opti Non Active"; Boolean)
        {
            Caption = 'Non Active';
            DataClassification = CustomerContent;
        }
        field(50602; "Opti Project Type"; Code[20])
        {
            Caption = 'Project Type';
            DataClassification = CustomerContent;
            TableRelation = "Opti Project Type Opt.";
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