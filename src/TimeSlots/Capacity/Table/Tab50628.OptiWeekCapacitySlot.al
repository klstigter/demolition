table 50628 "Opti Week Capacity Dialog"
{
    Caption = 'Week Capacity Slot';
    DataClassification = CustomerContent;
    TableType = Temporary;

    fields
    {
        field(1; "Day No."; Integer)
        {
            Caption = 'Day No.';
        }
        field(2; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }

        field(3; "Slot Line No."; Integer)
        {
            Caption = 'Slot Line No.';
        }

        field(4; "Capacity Date"; Date)
        {
            Caption = 'Capacity Date';
        }

        field(5; "Week Year"; Integer)
        {
            Caption = 'Week Year';
        }
        field(6; "Week No."; Integer)
        {
            Caption = 'Week No.';
        }
        field(7; "Weekday Name"; Text[20])
        {
            Caption = 'Weekday';
        }

        field(8; "Capacity Entry Line No."; Integer)
        {
            Caption = 'Capacity Entry Line No.';
        }

        field(9; "Entry Type"; Enum "Opti Capacity Entry Type")
        {
            Caption = 'Entry Type';
        }

        field(20; "Time Slot ID"; Integer)
        {
            Caption = 'Time Slot ID';
        }

        field(30; "Start Time"; Time)
        {
            Caption = 'Start Time';
        }

        field(40; "End Time"; Time)
        {
            Caption = 'End Time';
        }

        field(50; "Idle Time"; Integer)
        {
            Caption = 'Idle Times';
        }

        field(60; "Working Minutes"; Integer)
        {
            Caption = 'Working Minutes';
        }

        field(70; "Working Hours"; Decimal)
        {
            Caption = 'Working Hours';
            DecimalPlaces = 0 : 5;
        }

        field(80; "Capacity Hours"; Decimal)
        {
            Caption = 'Capacity Hours';
            DecimalPlaces = 0 : 5;
        }

        field(90; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(100; "Manual"; Boolean)
        {
            Caption = 'Manual';
        }
        field(110; "Resource No."; Code[20])
        {
            Caption = 'Resource No.';
        }

        field(120; "Week Start Date"; Date)
        {
            Caption = 'Week Start Date';
        }


    }

    keys
    {
        key(PK; "Day No.", "Entry No.")
        {
            Clustered = true;
        }

        key(DateTime; "Capacity Date", "Start Time", "Entry No.")
        {
        }
    }
}