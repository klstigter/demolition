table 50625 "Opti Time Slot Buffer"
{
    Caption = 'Time Slot Buffer';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(10; "Time Slot ID"; Integer)
        {
            Caption = 'Time Slot ID';
        }
        field(20; "Start Time"; Time)
        {
            Caption = 'Start Time';
        }
        field(30; "End Time"; Time)
        {
            Caption = 'End Time';
        }
        field(40; "Rest Minutes"; Integer)
        {
            Caption = 'Rest Minutes';
            MinValue = 0;
        }
        field(50; "Working Minutes"; Integer)
        {
            Caption = 'Working Minutes';
            Editable = false;
        }
        field(60; "Working Hours"; Decimal)
        {
            Caption = 'Working Hours';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(70; "Time Slot Hash"; Text[64])
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

        key(TimeOrder;
        "Start Time",
            "End Time",
            "Rest Minutes",
            "Time Slot ID")
        {
        }
    }

    procedure Recalculate()
    var
        TimeSlot: Record "Opti Time Slot";
    begin
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



    var
        StartTimeRequiredErr:
            Label 'Start Time must have a value.';

        EndTimeRequiredErr:
            Label 'End Time must have a value.';

        RestMinutesNegativeErr:
            Label 'Rest Minutes cannot be negative.';
}