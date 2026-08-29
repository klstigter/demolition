table 50630 "Opti Capacity Week Pattern Ln"
{
    Caption = 'Capacity Week Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Effective Week Pattern ID"; Integer)
        {
            Caption = 'Effective Week Pattern ID';
            TableRelation = "Opti Capacity Week Pattern Hdr"."Capacity Week Pattern ID";
        }
        field(10; "Weekday No."; Integer)
        {
            Caption = 'Weekday No.';
            MinValue = 1;
            MaxValue = 7;

            trigger OnValidate()
            begin
                SetWeekdayName();
            end;
        }
        field(20; "Weekday Name"; Text[20])
        {
            Caption = 'Weekday';
            Editable = false;
        }
        field(30; "Day-TimeSlots ID"; Integer)
        {
            Caption = 'Day Pattern ID';
            TableRelation = "Opti Day-TimeSlots Header"."Day-TimeSLots Header No.";
        }
        field(40; "Day Effective Hash"; Text[64])
        {
            Caption = 'Day Effective Hash';
            Editable = false;
        }
        field(50; "Entry Count"; Integer)
        {
            Caption = 'Entry Count';
            Editable = false;
        }
        field(60; "Capacity Hours"; Decimal)
        {
            Caption = 'Capacity Hours';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(70; "Working Minutes"; Integer)
        {
            Caption = 'Working Minutes';
            FieldClass = FlowField;
            CalcFormula =
                lookup("Opti Day-TimeSlots Header"."Total Working Minutes"
                    where("Day-TimeSLots Header No." = field("Day-TimeSlots ID")));
            Editable = false;
        }
        field(80; "Working Hours"; Decimal)
        {
            Caption = 'Working Hours';
            FieldClass = FlowField;
            CalcFormula =
                lookup("Opti Day-TimeSlots Header"."Total Working Hours"
                    where("Day-TimeSLots Header No." = field("Day-TimeSlots ID")));
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(90; "No. of Time Slots"; Integer)
        {
            Caption = 'No. of Time Slots';
            FieldClass = FlowField;
            CalcFormula =
                lookup("Opti Day-TimeSlots Header"."No. of Time Slots"
                    where("Day-TimeSLots Header No." = field("Day-TimeSlots ID")));
            Editable = false;
        }
        field(100; "Day Pattern Hash"; Text[64])
        {
            Caption = 'Day Pattern Hash';
            FieldClass = FlowField;
            CalcFormula =
                lookup("Opti Day-TimeSlots Header"."Pattern Hash"
                    where("Day-TimeSLots Header No." = field("Day-TimeSlots ID")));
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Effective Week Pattern ID", "Weekday No.")
        {
            Clustered = true;
        }

        key(DayPatternKey; "Day-TimeSlots ID")
        {
        }
    }

    trigger OnInsert()
    begin
        TestField("Effective Week Pattern ID");
        TestField("Weekday No.");

        SetWeekdayName();
    end;

    trigger OnModify()
    begin
        TestField("Effective Week Pattern ID");
        TestField("Weekday No.");

        SetWeekdayName();
    end;

    local procedure SetWeekdayName()
    begin
        case "Weekday No." of
            1:
                "Weekday Name" := MondayLbl;
            2:
                "Weekday Name" := TuesdayLbl;
            3:
                "Weekday Name" := WednesdayLbl;
            4:
                "Weekday Name" := ThursdayLbl;
            5:
                "Weekday Name" := FridayLbl;
            6:
                "Weekday Name" := SaturdayLbl;
            7:
                "Weekday Name" := SundayLbl;
            else
                Clear("Weekday Name");
        end;
    end;

    var
        MondayLbl: Label 'Monday';
        TuesdayLbl: Label 'Tuesday';
        WednesdayLbl: Label 'Wednesday';
        ThursdayLbl: Label 'Thursday';
        FridayLbl: Label 'Friday';
        SaturdayLbl: Label 'Saturday';
        SundayLbl: Label 'Sunday';
}
