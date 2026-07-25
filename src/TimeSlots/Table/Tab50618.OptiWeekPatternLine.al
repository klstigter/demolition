table 50618 "Opti Week Pattern Line"
{
    Caption = 'Week Pattern Day';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Week Pattern ID"; Integer)
        {
            Caption = 'Week Pattern ID';
            TableRelation = "Opti Week Pattern Header"."Week Pattern ID";
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
        field(20; "Day Pattern ID"; Integer)
        {
            Caption = 'Day Pattern ID';
            TableRelation = "Opti Day Time Slots Header"."Day Time SLot Header ID";
        }
        field(30; "Weekday Name"; Text[20])
        {
            Caption = 'Weekday';
            Editable = false;
        }
        field(40; "Day Pattern Description"; Text[100])
        {
            Caption = 'Day Pattern Description';
            FieldClass = FlowField;
            CalcFormula =
                lookup("Opti Day Time Slots Header".Description
                    where("Day Time SLot Header ID" = field("Day Pattern ID")));
            Editable = false;
        }
        field(50; "Working Minutes"; Integer)
        {
            Caption = 'Working Minutes';
            FieldClass = FlowField;
            CalcFormula =
                lookup("Opti Day Time Slots Header"."Total Working Minutes"
                    where("Day Time SLot Header ID" = field("Day Pattern ID")));
            Editable = false;
        }
        field(60; "Working Hours"; Decimal)
        {
            Caption = 'Working Hours';
            FieldClass = FlowField;
            CalcFormula =
                lookup("Opti Day Time Slots Header"."Total Working Hours"
                    where("Day Time SLot Header ID" = field("Day Pattern ID")));
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(70; "No. of Time Slots"; Integer)
        {
            Caption = 'No. of Time Slots';
            FieldClass = FlowField;
            CalcFormula =
                lookup("Opti Day Time Slots Header"."No. of Time Slots"
                    where("Day Time SLot Header ID" = field("Day Pattern ID")));
            Editable = false;
        }
        field(80; "Day Pattern Hash"; Text[64])
        {
            Caption = 'Day Pattern Hash';
            FieldClass = FlowField;
            CalcFormula =
                lookup("Opti Day Time Slots Header"."Pattern Hash"
                    where("Day Time SLot Header ID" = field("Day Pattern ID")));
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Week Pattern ID", "Weekday No.")
        {
            Clustered = true;
        }

        key(DayPatternKey; "Day Pattern ID")
        {
        }
    }

    trigger OnInsert()
    begin
        TestField("Week Pattern ID");
        TestField("Weekday No.");
        TestField("Day Pattern ID");

        SetWeekdayName();
    end;

    trigger OnModify()
    begin
        TestField("Week Pattern ID");
        TestField("Weekday No.");
        TestField("Day Pattern ID");

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