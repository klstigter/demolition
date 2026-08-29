table 50621 "Opti Day-TimeSlot Line"
{
    Caption = 'Day Pattern Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Day-TimeSLots Header No."; Integer)
        {
            Caption = 'Day Pattern No.';
            TableRelation = "Opti Day-TimeSlots Header"."Day-TimeSLots Header No.";
        }
        field(10; "Day-TimeSLot Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(20; "Time Slot No."; Integer)
        {
            Caption = 'Time Slot No.';
            TableRelation = "Opti Time Slot"."Time Slot No.";
            Editable = false;
        }
        field(30; "Start Time"; Time)
        {
            Caption = 'Start Time';
            FieldClass = FlowField;
            CalcFormula =
                lookup("Opti Time Slot"."Start Time"
                    where("Time Slot No." = field("Time Slot No.")));
            Editable = false;
        }
        field(40; "End Time"; Time)
        {
            Caption = 'End Time';
            FieldClass = FlowField;
            CalcFormula =
                lookup("Opti Time Slot"."End Time"
                    where("Time Slot No." = field("Time Slot No.")));
            Editable = false;
        }
        field(50; "Rest Minutes"; Integer)
        {
            Caption = 'Rest Minutes';
            FieldClass = FlowField;
            CalcFormula =
                lookup("Opti Time Slot"."Idle Time"
                    where("Time Slot No." = field("Time Slot No.")));
            Editable = false;
        }
        field(60; "Working Minutes"; Integer)
        {
            Caption = 'Working Minutes';
            FieldClass = FlowField;
            CalcFormula =
                lookup("Opti Time Slot"."Working Minutes"
                    where("Time Slot No." = field("Time Slot No.")));
            Editable = false;
        }
        field(70; "Working Hours"; Decimal)
        {
            Caption = 'Working Hours';
            FieldClass = FlowField;
            CalcFormula =
                lookup("Opti Time Slot"."Working Hours"
                    where("Time Slot No." = field("Time Slot No.")));
            DecimalPlaces = 0 : 5;
            Editable = false;
        }

    }

    keys
    {
        key(PK; "Day-TimeSLots Header No.", "Day-TimeSLot Line No.")
        {
            Clustered = true;
        }

        key(TimeSlotKey; "Day-TimeSLots Header No.", "Time Slot No.")
        {
            Unique = true;
        }
    }

    trigger OnInsert()
    begin
        TestField("Day-TimeSLots Header No.");
        TestField("Time Slot No.");

        if "Day-TimeSLot Line No." = 0 then
            "Day-TimeSLot Line No." := GetNextLineNo("Day-TimeSLots Header No.");
    end;

    procedure GetNextLineNo(Day_TimeSLotHdrID: Integer): Integer
    var
        DayTimeSlotLine: Record "Opti Day-TimeSlot Line";
    begin
        DayTimeSlotLine.SetRange(
            "Day-TimeSLots Header No.",
            Day_TimeSLotHdrID);

        if DayTimeSlotLine.FindLast() then
            exit(DayTimeSlotLine."Day-TimeSLot Line No." + 10000);

        exit(10000);
    end;
}