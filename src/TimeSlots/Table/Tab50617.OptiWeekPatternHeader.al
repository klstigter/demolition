table 50617 "Opti Week Pattern Header"
{
    Caption = 'Week Pattern';
    DataClassification = CustomerContent;
    LookupPageId = "Opti Week Pattern List";
    DrillDownPageId = "Opti Week Pattern List";

    fields
    {
        field(1; "Week Pattern ID"; Integer)
        {
            Caption = 'Week Pattern ID';
            AutoIncrement = true;
            Editable = false;
        }
        field(10; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(20; "Total Minutes"; Integer)
        {
            Caption = 'Total Minutes';
            Editable = false;
        }
        field(30; "Total Hours"; Decimal)
        {
            Caption = 'Total Hours';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(40; "Pattern Hash"; Text[64])
        {
            Caption = 'Pattern Hash';
            Editable = false;
        }
        field(50; "No. of Time Slots"; Integer)
        {
            Caption = 'No. of Time Slots';
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Week Pattern ID")
        {
            Clustered = true;
        }

        key(DescriptionKey; Description)
        {
        }

        key(PatternHash; "Pattern Hash")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown;
        "Week Pattern ID",
            Description,
            "Total Hours")
        {
        }
    }

    trigger OnDelete()
    var
        Confirmed: Boolean;
    begin
        // Later, delete the related capacity pattern day/slot records here.
        Confirmed := true;
    end;

    procedure ApplyWeekPattern(
    var TempWeekPatternBuffer: Record "Opti Week Pattern Buffer" temporary)
    var
        WeekPatternLine: Record "Opti Week Pattern Line";
        WeekdayNo: Integer;
        DayPatternID: Integer;
    begin
        TestField("Week Pattern ID");

        TempWeekPatternBuffer.Reset();

        if TempWeekPatternBuffer.IsEmpty() then
            Error(NoWeekPatternLinesErr);

        // Replace only the weekday relations of this capacity pattern.
        // Reusable Time Slots and Day Patterns remain in the database.
        WeekPatternLine.SetRange(
            "Week Pattern ID",
            "Week Pattern ID");
        WeekPatternLine.DeleteAll(true);

        for WeekdayNo := 1 to 7 do begin
            DayPatternID :=
                GetOrCreateDayPattern(
                    TempWeekPatternBuffer,
                    WeekdayNo);

            if DayPatternID <> 0 then
                InsertWeekPatternDay(
                    WeekdayNo,
                    DayPatternID);
        end;

        RecalculateWeekPattern();
    end;

    local procedure GetOrCreateDayPattern(
    var TempWeekPatternBuffer: Record "Opti Week Pattern Buffer" temporary;
    WeekdayNo: Integer): Integer
    var
        Day_TimeSlotHeader: Record "Opti Day Time Slots Header";
        TimeSlot: Record "Opti Time Slot";
        TempTimeSlotBuffer: Record "Opti Time Slot Buffer" temporary;
        Day_TimeSlotLine: Record "Opti Day TimeSlot Line";
        EntryNo: Integer;
        DayPatternHash: Text[64];
        GeneratedDayPatternDescriptionLbl: Label 'Generated day pattern %1';
    begin
        TempWeekPatternBuffer.Reset();
        TempWeekPatternBuffer.SetCurrentKey(
            "Weekday No.",
            "Start Time",
            "End Time",
            "Rest Minutes",
            "Entry No.");

        TempWeekPatternBuffer.SetRange(
            "Weekday No.",
            WeekdayNo);

        if not TempWeekPatternBuffer.FindSet() then
            exit(0);

        repeat
            TempWeekPatternBuffer.ValidateInput();

            TimeSlot.Get(
                TempWeekPatternBuffer.ResolveTimeSlot());

            EntryNo += 1;

            TempTimeSlotBuffer.Init();
            TempTimeSlotBuffer."Entry No." := EntryNo;
            TempTimeSlotBuffer."Time Slot ID" := TimeSlot."Time Slot ID";
            TempTimeSlotBuffer."Start Time" := TimeSlot."Start Time";
            TempTimeSlotBuffer."End Time" := TimeSlot."End Time";
            TempTimeSlotBuffer."Rest Minutes" := TimeSlot."Rest Minutes";
            TempTimeSlotBuffer."Working Minutes" := TimeSlot."Working Minutes";
            TempTimeSlotBuffer."Working Hours" := TimeSlot."Working Hours";
            TempTimeSlotBuffer."Time Slot Hash" := TimeSlot."Time Slot Hash";
            TempTimeSlotBuffer.Insert();
        until TempWeekPatternBuffer.Next() = 0;

        DayPatternHash := CalculateDayPatternHash(TempTimeSlotBuffer);

        Day_TimeSlotHeader.SetRange("Pattern Hash", DayPatternHash);
        if Day_TimeSlotHeader.FindFirst() then
            exit(Day_TimeSlotHeader."Day Time SLot Header ID");

        Day_TimeSlotHeader.Init();
        Day_TimeSlotHeader.Description :=
            CopyStr(
                StrSubstNo(
                    GeneratedDayPatternDescriptionLbl,
                    CopyStr(DayPatternHash, 1, 8)),
                1,
                MaxStrLen(Day_TimeSlotHeader.Description));

        Day_TimeSlotHeader.Insert(true);
        TempTimeSlotBuffer.Reset();
        TempTimeSlotBuffer.SetCurrentKey(
            "Start Time",
            "End Time",
            "Rest Minutes",
            "Time Slot ID");

        if TempTimeSlotBuffer.FindSet() then
            repeat
                Day_TimeSlotLine.Init();
                Day_TimeSlotLine."Day Time SLot Header ID" := Day_TimeSlotHeader."Day Time SLot Header ID";
                Day_TimeSlotLine."Day Time SLot Line No." := 0;
                Day_TimeSlotLine."Time Slot ID" := TempTimeSlotBuffer."Time Slot ID";

                Day_TimeSlotLine.Insert(true);
            until TempTimeSlotBuffer.Next() = 0;

        Day_TimeSlotHeader.RecalculatePattern();

        exit(Day_TimeSlotHeader."Day Time SLot Header ID");
    end;

    local procedure CalculateDayPatternHash(
    var TempTimeSlotBuffer: Record "Opti Time Slot Buffer" temporary): Text[64]
    var
        CryptographyManagement: Codeunit "Cryptography Management";
        HashAlgorithm: Option MD5,SHA1,SHA256,SHA384,SHA512;
        HashInput: Text;
        GeneratedHash: Text;
    begin
        TempTimeSlotBuffer.Reset();
        TempTimeSlotBuffer.SetCurrentKey(
            "Start Time",
            "End Time",
            "Rest Minutes",
            "Time Slot ID");

        if TempTimeSlotBuffer.FindSet() then
            repeat
                if HashInput <> '' then
                    HashInput += '|';

                HashInput +=
                    StrSubstNo(
                        '%1;%2;%3;%4',
                        FormatTimeForHash(TempTimeSlotBuffer."Start Time"),
                        FormatTimeForHash(TempTimeSlotBuffer."End Time"),
                        Format(TempTimeSlotBuffer."Rest Minutes", 0, 9),
                        Format(TempTimeSlotBuffer."Time Slot ID", 0, 9));
            until TempTimeSlotBuffer.Next() = 0;

        if HashInput = '' then
            exit('');

        GeneratedHash :=
            CryptographyManagement.GenerateHash(
                HashInput,
                HashAlgorithm::SHA256);

        exit(CopyStr(GeneratedHash, 1, 64));
    end;

    local procedure FormatTimeForHash(Value: Time): Text
    begin
        exit(
            Format(
                Value,
                0,
                '<Hours24,2><Minutes,2><Seconds,2><Second dec.>'));
    end;

    local procedure InsertWeekPatternDay(
        WeekdayNo: Integer;
        DayPatternID: Integer)
    var
        WeekPatternDay: Record "Opti Week Pattern Line";
        DayPattern: Record "Opti Day Time Slots Header";
    begin
        DayPattern.Get(DayPatternID);
        WeekPatternDay.Init();
        WeekPatternDay."Week Pattern ID" :=
            "Week Pattern ID";

        WeekPatternDay.Validate(
            "Weekday No.",
            WeekdayNo);

        WeekPatternDay.Validate(
            "Day Pattern ID",
            DayPatternID);

        WeekPatternDay.Insert(true);
    end;

    procedure RecalculateWeekPattern()
    var
        WeekPatternLine: Record "Opti Week Pattern Line";
        CryptographyManagement: Codeunit "Cryptography Management";
        HashAlgorithm: Option MD5,SHA1,SHA256,SHA384,SHA512;
        HashInput: Text;
        GeneratedHash: Text;
        TotalMinutes: Integer;
        NumberOfTimeSlots: Integer;
    begin
        TestField("Week Pattern ID");

        WeekPatternLine.SetRange(
            "Week Pattern ID",
            "Week Pattern ID");

        WeekPatternLine.SetCurrentKey(
            "Week Pattern ID",
            "Weekday No.");

        if WeekPatternLine.FindSet() then
            repeat
                WeekPatternLine.CalcFields(
                    "Working Minutes",
                    "No. of Time Slots",
                    "Day Pattern Hash");

                TotalMinutes += WeekPatternLine."Working Minutes";
                NumberOfTimeSlots += WeekPatternLine."No. of Time Slots";

                if HashInput <> '' then
                    HashInput += '|';

                HashInput +=
                    StrSubstNo(
                        '%1;%2',
                        Format(WeekPatternLine."Weekday No.", 0, 9),
                        WeekPatternLine."Day Pattern Hash");
            until WeekPatternLine.Next() = 0;

        "Total Minutes" := TotalMinutes;
        "Total Hours" := TotalMinutes / 60;
        "No. of Time Slots" := NumberOfTimeSlots;

        if HashInput = '' then
            Clear("Pattern Hash")
        else begin
            GeneratedHash :=
                CryptographyManagement.GenerateHash(
                    HashInput,
                    HashAlgorithm::SHA256);

            "Pattern Hash" :=
                CopyStr(
                    GeneratedHash,
                    1,
                    MaxStrLen("Pattern Hash"));
        end;

        Modify(true);
    end;

    var
        NoWeekPatternLinesErr:
        Label 'Enter at least one time slot for the week pattern.';

}