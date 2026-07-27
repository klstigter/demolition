table 50623 "Opti Week Pattern Buffer"
{
    Caption = 'Week Pattern Buffer';
    DataClassification = CustomerContent;
    tabletype = Temporary;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
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
        field(30; "Start Time"; Time)
        {
            Caption = 'Start Time';

            trigger OnValidate()
            begin
                Recalculate();
            end;
        }
        field(40; "End Time"; Time)
        {
            Caption = 'End Time';

            trigger OnValidate()
            begin
                Recalculate();
            end;
        }
        field(50; "Rest Minutes"; Integer)
        {
            Caption = 'Rest Minutes';
            MinValue = 0;

            trigger OnValidate()
            begin
                Recalculate();
            end;
        }
        field(60; "Working Minutes"; Integer)
        {
            Caption = 'Working Minutes';
            Editable = false;
        }
        field(70; "Working Hours"; Decimal)
        {
            Caption = 'Working Hours';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(80; "Time Slot ID"; Integer)
        {
            Caption = 'Time Slot ID';
            TableRelation = "Opti Time Slot"."Time Slot ID";
            Editable = false;
        }
        field(90; "Time Slot Hash"; Text[64])
        {
            Caption = 'Time Slot Hash';
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }

        key(WeekdayTimeOrder;
        "Weekday No.",
            "Start Time",
            "End Time",
            "Rest Minutes",
            "Entry No.")
        {
        }
    }

    trigger OnInsert()
    begin
        if "Entry No." = 0 then
            "Entry No." := GetNextEntryNo();

        SetWeekdayName();

        if ("Start Time" <> 0T) and ("End Time" <> 0T) then
            Recalculate();
    end;

    trigger OnModify()
    begin
        SetWeekdayName();

        if ("Start Time" <> 0T) and ("End Time" <> 0T) then
            Recalculate();
    end;

    procedure Recalculate()
    var
        TimeSlot: Record "Opti Time Slot";
    begin
        ClearResolvedTimeSlot();

        if ("Start Time" = 0T) or ("End Time" = 0T) then begin
            ClearCalculatedFields();
            exit;
        end;

        ValidateInput();

        "Working Minutes" :=
            TimeSlot.CalculateWorkingMinutes(
                "Start Time",
                "End Time",
                "Rest Minutes");

        "Working Hours" := "Working Minutes" / 60;

        "Time Slot Hash" :=
            TimeSlot.GenerateTimeSlotHash(
                "Start Time",
                "End Time",
                "Rest Minutes");
    end;

    procedure ValidateInput()
    var
        TimeSlot: Record "Opti Time Slot";
    begin
        TestField("Weekday No.");

        if "Start Time" = 0T then
            Error(StartTimeRequiredErr);

        if "End Time" = 0T then
            Error(EndTimeRequiredErr);

        if "Rest Minutes" < 0 then
            Error(RestMinutesNegativeErr);

        TimeSlot.ValidateTimeSlotDefinition(
            "Start Time",
            "End Time",
            "Rest Minutes");
    end;

    procedure ResolveTimeSlot(): Integer
    var
        TimeSlot: Record "Opti Time Slot";
    begin
        ValidateInput();

        "Time Slot ID" :=
            TimeSlot.GetOrCreateTimeSlot(
                "Start Time",
                "End Time",
                "Rest Minutes");

        exit("Time Slot ID");
    end;

    procedure ClearCalculatedFields()
    begin
        Clear("Working Minutes");
        Clear("Working Hours");
        Clear("Time Slot Hash");
    end;

    procedure ClearResolvedTimeSlot()
    begin
        Clear("Time Slot ID");
    end;

    local procedure GetNextEntryNo(): Integer
    var
        WeekPatternBuffer: Record "Opti Week Pattern Buffer";
    begin
        if WeekPatternBuffer.FindLast() then
            exit(WeekPatternBuffer."Entry No." + 10000);

        exit(10000);
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

        StartTimeRequiredErr:
            Label 'Start Time must have a value.';

        EndTimeRequiredErr:
            Label 'End Time must have a value.';

        RestMinutesNegativeErr:
            Label 'Rest Minutes cannot be negative.';
}