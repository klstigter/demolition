tableextension 50606 "Opti ResCapacityEntry" extends "Res. Capacity Entry"
{
    fields
    {
        // Add changes to table fields here
        field(50600; "Opti Start Time"; Time)
        {
            Caption = 'Start Time';
            DataClassification = CustomerContent;
        }
        field(50601; "Opti End Time"; Time)
        {
            Caption = 'End Time';
            DataClassification = CustomerContent;
        }
        field(50602; "Opti Duplicate Id"; Integer)
        {
            Caption = 'Duplicate Id';
            DataClassification = CustomerContent;
            InitValue = 1;
        }
        field(50603; "Opti Assigned Hours"; Decimal)
        {
            Caption = 'Assigned Hours';
            Editable = false;
            fieldclass = FlowField;
            calcformula = sum("Opti Day Planning"."Assigned Hours" where("Assigned Resource No." = field("Resource No."),
              "Plan Date" = field("Date")));
        }
        field(50604; "Opti Requested Hours"; Decimal)
        {
            Caption = 'Requested Hours';
            Editable = false;
            fieldclass = FlowField;
            calcformula = sum("Opti Day Planning"."Requested Hours" where("Requested Resource No." = field("Resource No."),
              "Plan Date" = field("Date")));
        }
        field(50605; "Opti Type"; Enum "Opti Res. Capacity Entry Type")
        {
            Caption = 'Type';
            DataClassification = CustomerContent;
        }
        field(50606; "Opti Absence Reason Code"; Code[10])
        {
            Caption = 'Absence Reason Code';
            DataClassification = CustomerContent;
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