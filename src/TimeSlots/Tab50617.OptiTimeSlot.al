table 50617 "Opti Time Slot"
{
    Caption = 'Time Slot';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Time Slot ID"; Integer)
        {
            Caption = 'Time Slot ID';
            AutoIncrement = true;
            Editable = false;
        }
        field(10; "Start Time"; Time)
        {
            Caption = 'Start Time';

            trigger OnValidate()
            begin
                UpdateCalculatedFields();
            end;
        }
        field(20; "End Time"; Time)
        {
            Caption = 'End Time';

            trigger OnValidate()
            begin
                UpdateCalculatedFields();
            end;
        }
        field(30; "Rest Minutes"; Integer)
        {
            Caption = 'Rest Minutes';
            MinValue = 0;

            trigger OnValidate()
            begin
                UpdateCalculatedFields();
            end;
        }
        field(40; "Working Minutes"; Integer)
        {
            Caption = 'Working Minutes';
            Editable = false;
        }
        field(50; "Working Hours"; Decimal)
        {
            Caption = 'Working Hours';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(60; "Time Slot Hash"; Text[64])
        {
            Caption = 'Time Slot Hash';
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Time Slot ID")
        {
            Clustered = true;
        }

        key(TimeSlotHash; "Time Slot Hash")
        {
            Unique = true;
        }

        key(TimeSlotDefinition; "Start Time", "End Time", "Rest Minutes")
        {
            Unique = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown;
        "Start Time",
            "End Time",
            "Rest Minutes",
            "Working Hours")
        {
        }
    }

    trigger OnInsert()
    begin
        UpdateCalculatedFields();
        TestRequiredFields();
    end;

    trigger OnModify()
    begin
        UpdateCalculatedFields();
        TestRequiredFields();
    end;

    procedure GetOrCreateTimeSlot(
        StartTime: Time;
        EndTime: Time;
        RestMinutes: Integer): Integer
    var
        TimeSlot: Record "Opti Time Slot";
        SlotHash: Text[64];
    begin
        SlotHash := GenerateTimeSlotHash(
            StartTime,
            EndTime,
            RestMinutes);

        TimeSlot.SetCurrentKey("Time Slot Hash");
        TimeSlot.SetRange("Time Slot Hash", SlotHash);

        if TimeSlot.FindFirst() then begin
            // Defensive verification of the actual source fields.
            if (TimeSlot."Start Time" = StartTime) and
               (TimeSlot."End Time" = EndTime) and
               (TimeSlot."Rest Minutes" = RestMinutes)
            then
                exit(TimeSlot."Time Slot ID");
        end;

        TimeSlot.Init();
        TimeSlot."Start Time" := StartTime;
        TimeSlot."End Time" := EndTime;
        TimeSlot."Rest Minutes" := RestMinutes;
        TimeSlot.Insert(true);

        exit(TimeSlot."Time Slot ID");
    end;

    procedure GenerateTimeSlotHash(
        StartTime: Time;
        EndTime: Time;
        RestMinutes: Integer): Text[64]
    var
        CryptographyManagement: Codeunit "Cryptography Management";
        HashInput: Text;
        GeneratedHash: Text;
    begin
        HashInput := CreateCanonicalHashInput(
            StartTime,
            EndTime,
            RestMinutes);

        GeneratedHash :=
            CryptographyManagement.GenerateHash(
                HashInput,
                2); // SHA256

        exit(CopyStr(GeneratedHash, 1, 64));
    end;

    procedure GetCanonicalHashInput(): Text
    begin
        exit(
            CreateCanonicalHashInput(
                "Start Time",
                "End Time",
                "Rest Minutes"));
    end;

    local procedure UpdateCalculatedFields()
    begin
        ValidateTimeSlot();
        CalculateWorkingTime();
        CalculateTimeSlotHash();
    end;

    local procedure TestRequiredFields()
    begin
        TestField("Start Time");
        TestField("End Time");
        TestField("Time Slot Hash");
    end;

    local procedure ValidateTimeSlot()
    var
        GrossMinutes: Integer;
    begin
        if ("Start Time" = 0T) or ("End Time" = 0T) then
            exit;

        GrossMinutes := CalculateGrossMinutes();

        if "Rest Minutes" >= GrossMinutes then
            Error(
                RestTooLongErr,
                "Rest Minutes",
                GrossMinutes);
    end;

    local procedure CalculateWorkingTime()
    var
        GrossMinutes: Integer;
    begin
        if ("Start Time" = 0T) or ("End Time" = 0T) then begin
            "Working Minutes" := 0;
            "Working Hours" := 0;
            exit;
        end;

        GrossMinutes := CalculateGrossMinutes();

        "Working Minutes" := GrossMinutes - "Rest Minutes";
        "Working Hours" := "Working Minutes" / 60;
    end;

    local procedure CalculateTimeSlotHash()
    begin
        if ("Start Time" = 0T) or ("End Time" = 0T) then begin
            Clear("Time Slot Hash");
            exit;
        end;

        "Time Slot Hash" :=
            GenerateTimeSlotHash(
                "Start Time",
                "End Time",
                "Rest Minutes");
    end;

    local procedure CreateCanonicalHashInput(
        StartTime: Time;
        EndTime: Time;
        RestMinutes: Integer): Text
    begin
        exit(
            StrSubstNo(
                '%1|%2|%3',
                FormatTimeForHash(StartTime),
                FormatTimeForHash(EndTime),
                Format(RestMinutes, 0, 9)));
    end;

    local procedure FormatTimeForHash(Value: Time): Text
    begin
        exit(
            Format(
                Value,
                0,
                '<Hours24,2><Minutes,2><Seconds,2><Second dec.>'));
    end;

    local procedure CalculateGrossMinutes(): Integer
    var
        SlotDuration: Duration;
    begin
        if "End Time" > "Start Time" then
            SlotDuration := "End Time" - "Start Time"
        else
            SlotDuration :=
                (235959.999T - "Start Time") +
                ("End Time" - 000000T) +
                1;

        exit(Round(SlotDuration / 60000, 1, '='));
    end;

    procedure CalculateWorkingMinutes(
            StartTime: Time;
            EndTime: Time;
            RestMinutes: Integer): Integer
    var
        GrossMinutes: Integer;
    begin
        GrossMinutes := CalculateGrossMinutes(StartTime, EndTime);

        exit(GrossMinutes - RestMinutes);
    end;

    procedure ValidateTimeSlotDefinition(
        StartTime: Time;
        EndTime: Time;
        RestMinutes: Integer)
    var
        GrossMinutes: Integer;
    begin
        if RestMinutes < 0 then
            Error(RestMinutesNegativeErr);

        GrossMinutes := CalculateGrossMinutes(StartTime, EndTime);

        if RestMinutes >= GrossMinutes then
            Error(
                RestTooLongErr,
                RestMinutes,
                GrossMinutes);
    end;

    local procedure CalculateGrossMinutes(
        StartTime: Time;
        EndTime: Time): Integer
    var
        SlotDuration: Duration;
    begin
        if EndTime > StartTime then
            SlotDuration := EndTime - StartTime
        else
            SlotDuration :=
                (235959.999T - StartTime) +
                (EndTime - 000000T) +
                1;

        exit(Round(SlotDuration / 60000, 1, '='));
    end;

    var
        RestMinutesNegativeErr: Label 'Rest Minutes cannot be negative.';
        RestTooLongErr: Label 'Rest minutes %1 must be less than the total duration of %2 minutes.';

    procedure Recalculate()
    begin
        UpdateCalculatedFields();
    end;


}
