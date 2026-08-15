table 50621 "Opti Day-TimeSlot Line"
{
    Caption = 'Day Pattern Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Day Time SLot Header ID"; Integer)
        {
            Caption = 'Day Pattern ID';
            TableRelation = "Opti Day-TimeSlots Header"."Day Time SLot Header ID";
        }
        field(10; "Day Time SLot Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(20; "Time Slot ID"; Integer)
        {
            Caption = 'Time Slot ID';
            TableRelation = "Opti Time Slot"."Time Slot ID";
            Editable = false;
        }
        field(30; "Start Time"; Time)
        {
            Caption = 'Start Time';
            FieldClass = FlowField;
            CalcFormula =
                lookup("Opti Time Slot"."Start Time"
                    where("Time Slot ID" = field("Time Slot ID")));
            Editable = false;
        }
        field(40; "End Time"; Time)
        {
            Caption = 'End Time';
            FieldClass = FlowField;
            CalcFormula =
                lookup("Opti Time Slot"."End Time"
                    where("Time Slot ID" = field("Time Slot ID")));
            Editable = false;
        }
        field(50; "Rest Minutes"; Integer)
        {
            Caption = 'Rest Minutes';
            FieldClass = FlowField;
            CalcFormula =
                lookup("Opti Time Slot"."Idle Time"
                    where("Time Slot ID" = field("Time Slot ID")));
            Editable = false;
        }
        field(60; "Working Minutes"; Integer)
        {
            Caption = 'Working Minutes';
            FieldClass = FlowField;
            CalcFormula =
                lookup("Opti Time Slot"."Working Minutes"
                    where("Time Slot ID" = field("Time Slot ID")));
            Editable = false;
        }
        field(70; "Working Hours"; Decimal)
        {
            Caption = 'Working Hours';
            FieldClass = FlowField;
            CalcFormula =
                lookup("Opti Time Slot"."Working Hours"
                    where("Time Slot ID" = field("Time Slot ID")));
            DecimalPlaces = 0 : 5;
            Editable = false;
        }

    }

    keys
    {
        key(PK; "Day Time SLot Header ID", "Day Time SLot Line No.")
        {
            Clustered = true;
        }

        key(TimeSlotKey; "Day Time SLot Header ID", "Time Slot ID")
        {
            Unique = true;
        }
    }

    trigger OnInsert()
    begin
        TestField("Day Time SLot Header ID");
        TestField("Time Slot ID");

        if "Day Time SLot Line No." = 0 then
            "Day Time SLot Line No." := GetNextLineNo("Day Time SLot Header ID");
    end;

    procedure GetNextLineNo(Day_TimeSLotHdrID: Integer): Integer
    var
        DayTimeSlotLine: Record "Opti Day-TimeSlot Line";
    begin
        DayTimeSlotLine.SetRange(
            "Day Time SLot Header ID",
            Day_TimeSLotHdrID);

        if DayTimeSlotLine.FindLast() then
            exit(DayTimeSlotLine."Day Time SLot Line No." + 10000);

        exit(10000);
    end;
}