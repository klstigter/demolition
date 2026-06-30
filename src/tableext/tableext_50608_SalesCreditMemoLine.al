tableextension 50608 "Sales Cr.Memo Line Opt." extends "Sales Cr.Memo Line"
{
    fields
    {
        // Add changes to table fields here
        field(50600; "Day Planning Line No."; Integer)
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
    //myInt: Integer;
}