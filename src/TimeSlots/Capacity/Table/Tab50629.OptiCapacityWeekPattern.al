table 50629 "Opti Capacity Week Pattern Hdr"
{
    Caption = 'Capacity Week Pattern';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Capacity Week Pattern ID"; Integer)
        {
            Caption = 'Capacity Week Pattern ID';
            AutoIncrement = true;
            Editable = false;
        }
        field(10; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(20; "Pattern Hash"; Text[64])
        {
            Caption = 'Pattern Hash';
            Editable = false;
        }
        field(50; "No. of Active Days"; Integer)
        {
            Caption = 'No. of Active Days';
            Editable = false;
        }
        field(90; "Total Minutes"; Integer)
        {
            Caption = 'Total Minutes';
            Editable = false;
        }
        field(100; "Total Hours"; Decimal)
        {
            Caption = 'Total Hours';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(110; "No. of Time Slots"; Integer)
        {
            Caption = 'No. of Time Slots';
            Editable = false;
        }

    }

    keys
    {
        key(PK; "Capacity Week Pattern ID")
        {
            Clustered = true;
        }

        key(PatternHashKey; "Pattern Hash")
        {
        }

    }

    // procedure ApplyWeekPattern(var TempWeekPatternBuffer: Record "Opti Week Pattern Buffer" temporary)
    // var
    //     WeekPatternLine: Record "Opti Week Pattern Line";
    //     WeekdayNo: Integer;
    //     DayPatternID: Integer;
    // begin
    //     TestField("Week Pattern Code");

    //     TempWeekPatternBuffer.Reset();

    //     if TempWeekPatternBuffer.IsEmpty() then
    //         Error(NoWeekPatternLinesErr);


    //     for WeekdayNo := 1 to 7 do begin
    //         DayPatternID :=
    //             GetOrCreateDayPattern(
    //                 TempWeekPatternBuffer,
    //                 WeekdayNo);

    //         if DayPatternID <> 0 then
    //             InsertWeekPatternDay(
    //                 WeekdayNo,
    //                 DayPatternID);
    //     end;

    //     RecalculateWeekPattern();
    // end;

    local procedure GetOrCreateDayPattern(var TempWeekPatternBuffer: Record "Opti Week Pattern Dialog" temporary; WeekdayNo: Integer): Integer
    var
        Day_TimeSlotHeader: Record "Opti Day-TimeSlots Header";
        TimeSlot: Record "Opti Time Slot";
        TempTimeSlotBuffer: Record "Opti Time Slot" temporary;
        Day_TimeSlotLine: Record "Opti Day-TimeSlot Line";
        EntryNo: Integer;
        DayPatternHash: Text[64];
        GeneratedDayPatternDescriptionLbl: Label 'Generated day pattern %1';
    begin
        TempWeekPatternBuffer.Reset();
        TempWeekPatternBuffer.SetCurrentKey(
            "Weekday No.",
            "Start Time",
            "End Time",
            "Idle Time",
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
            //TempTimeSlotBuffer."Entry No." := EntryNo;
            TempTimeSlotBuffer."Time Slot ID" := TimeSlot."Time Slot ID";
            TempTimeSlotBuffer."Start Time" := TimeSlot."Start Time";
            TempTimeSlotBuffer."End Time" := TimeSlot."End Time";
            TempTimeSlotBuffer."Idle Time" := TimeSlot."Idle Time";
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
            "Idle Time",
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

    local procedure CalculateDayPatternHash(var TempTimeSlotBuffer: Record "Opti Time Slot" temporary): Text[64]
    var
        Day_TimeSlotsHeader: Record "Opti Day-TimeSlots Header";
        CryptographyManagement: Codeunit "Cryptography Management";
        HashAlgorithm: Option MD5,SHA1,SHA256,SHA384,SHA512;
        HashInput: Text;
        GeneratedHash: Text;
    begin
        TempTimeSlotBuffer.Reset();
        //Day_TimeSlotsHeader.calculateHash(TempTimeSlotBuffer, Day_TimeSlotsHeader."Total Working Minutes", Day_TimeSlotsHeader."No. of Time Slots");
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
        DayPattern: Record "Opti Day-TimeSlots Header";
    begin
        DayPattern.Get(DayPatternID);
        WeekPatternDay.Init();
        //WeekPatternDay."Week Pattern Code" :=
        //    "Week Pattern Code";

        WeekPatternDay.Validate(
            "Weekday No.",
            WeekdayNo);

        WeekPatternDay.Validate(
            "Day Pattern ID",
            DayPatternID);

        WeekPatternDay.Insert(true);
    end;

    procedure RecalculateWeekPattern(var WeekPatternLine: Record "Opti Capacity Week Pattern Ln")
    var
        TotalMinutes: Integer;
        NumberOfTimeSlots: Integer;
    begin
        "Pattern Hash" :=
            CalcHashCode(WeekPatternLine, TotalMinutes, NumberOfTimeSlots);
        "Total Minutes" := TotalMinutes;
        "Total Hours" := TotalMinutes / 60;
        "No. of Time Slots" := NumberOfTimeSlots;
        Modify(true);
    end;

    procedure CalcHashCode(var WeekPatternLine: Record "Opti Capacity Week Pattern Ln"; var TotalMinutes: Integer; var NumberOfTimeSlots: Integer) GeneratedHash: Text;
    var
        CryptographyManagement: Codeunit "Cryptography Management";
        HashAlgorithm: Option MD5,SHA1,SHA256,SHA384,SHA512;
        HashInput: Text;
    begin
        totalMinutes := 0;
        numberOfTimeSlots := 0;
        WeekPatternLine.SetCurrentKey("Day Pattern ID");

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

        if HashInput = '' then
            Clear("Pattern Hash")
        else begin
            GeneratedHash :=
                CryptographyManagement.GenerateHash(
                    HashInput,
                    HashAlgorithm::SHA256);
        end;
    end;


    procedure DeleteForWeek("ResourceNo": Code[20]; "Week Start Date": Date);
    begin

    end;

}
