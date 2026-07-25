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
        field(50602; "Duplicate Id"; Integer)
        {
            DataClassification = ToBeClassified;
            InitValue = 1;
        }
        field(50604; "Requested Hours"; Decimal)
        {
            Editable = false;
            fieldclass = FlowField;
            calcformula = sum("Day Planning"."Assigned Hours" where("Assigned Resource No." = field("Resource No."),
              "Plan Date" = field("Date")));
        }
        field(50605; Type; Enum "Res. Capacity Entry Type")
        {
            DataClassification = SystemMetadata;
        }
        field(50606; "Absence Reason Code"; Code[10])
        {
            DataClassification = ToBeClassified;
            TableRelation = "Cause of Absence";
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