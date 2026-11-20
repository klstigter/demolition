table 50687 "Register Absence"
{
    Caption = 'Register Absence';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Line No."; Integer)
        {
            Caption = 'Line No.';
            DataClassification = SystemMetadata;
        }
        field(2; "Resource No."; Code[20])
        {
            Caption = 'Resource No.';
            DataClassification = CustomerContent;
            TableRelation = Resource;
        }
        field(3; Date; Date)
        {
            Caption = 'Date';
            DataClassification = CustomerContent;
        }
        field(4; "Absence Reason Code"; Code[10])
        {
            Caption = 'Absence Reason Code';
            DataClassification = CustomerContent;
            TableRelation = "Cause of Absence";
        }
        field(5; Hours; Decimal)
        {
            Caption = 'Hours';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 2;
            BlankZero = true;
        }
        field(6; "Existing Capacity"; Decimal)
        {
            Caption = 'Existing Capacity';
            Editable = false;
            FieldClass = FlowField;
            // Deliberately sums BOTH Capacity and Absence rows (no Type filter) so this shows
            // the NET remaining capacity for the date - Capacity minus anything already posted
            // as Absence - not just whether a Capacity row exists at all. This is what makes
            // the Post-time "<= 0" check (codeunit 50686) correctly block a resource that has
            // no remaining capacity left, instead of only blocking one with none whatsoever.
            CalcFormula = sum("Res. Capacity Entry".Capacity
                where("Resource No." = field("Resource No."),
                      Date = field(Date)));
            DecimalPlaces = 0 : 5;
            BlankZero = true;
        }
    }

    keys
    {
        key(PK; "Line No.")
        {
            Clustered = true;
        }
    }
}
