table 50622 "Opti Day Pattern Line"
{
    Caption = 'Day Pattern Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Day Pattern ID"; Integer)
        {
            Caption = 'Day Pattern ID';
            TableRelation = "Opti Day Pattern"."Day Pattern ID";
        }
        field(10; "Line No."; Integer)
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
                lookup("Opti Time Slot"."Rest Minutes"
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
        key(PK; "Day Pattern ID", "Line No.")
        {
            Clustered = true;
        }

        key(TimeSlotKey; "Day Pattern ID", "Time Slot ID")
        {
            Unique = true;
        }
    }

    trigger OnInsert()
    begin
        TestField("Day Pattern ID");
        TestField("Time Slot ID");

        if "Line No." = 0 then
            "Line No." := GetNextLineNo();
    end;

    procedure GetNextLineNo(): Integer
    var
        DayPatternLine: Record "Opti Day Pattern Line";
    begin
        DayPatternLine.SetRange(
            "Day Pattern ID",
            "Day Pattern ID");

        if DayPatternLine.FindLast() then
            exit(DayPatternLine."Line No." + 10000);

        exit(10000);
    end;
}