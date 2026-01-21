tableextension 50606 "ResCapacityEntry Opt" extends "Res. Capacity Entry"
{
    fields
    {
        // Add changes to table fields here
        field(50600; "Start Time"; Time)
        {
            DataClassification = ToBeClassified;
        }
        field(50601; "End Time"; Time)
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