table 50617 "Opti Week Pattern Header"
{
    Caption = 'Week Pattern';
    DataClassification = CustomerContent;
    LookupPageId = "Opti Week Pattern List";
    DrillDownPageId = "Opti Week Pattern List";

    fields
    {

        field(1; "Week Pattern Code"; Code[20])
        {
            Caption = 'Week Pattern Code';
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
        field(40; "Week Hash"; Text[64])
        {
            Caption = 'Week Hash';
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
        key(PK; "Week Pattern Code")
        {
            Clustered = true;
        }

        key(DescriptionKey; Description)
        {
        }

        key(PatternHash; "Week Hash")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown;
        "Week Pattern Code",
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

    procedure ApplyWeekPattern(var TempWeekPatternDialog: Record "Opti Week Pattern Dialog" temporary)
    var
        WeekPatternLine: Record "Opti Week Pattern Line";
        WeekdayNo: Integer;
        Day_TimeSLotsID: Integer;
    begin
        TestField("Week Pattern Code");
        TempWeekPatternDialog.Reset();
        if TempWeekPatternDialog.IsEmpty() then
            Error(NoWeekPatternLinesErr);

        // Replace only the weekday relations of this capacity pattern.
        // Reusable Time Slots and Day Patterns remain in the database.
        WeekPatternLine.SetRange("Week Pattern Code", "Week Pattern Code");
        WeekPatternLine.DeleteAll(true);

        for WeekdayNo := 1 to 7 do begin
            Day_TimeSLotsID := GetOrCreateDay_TimeSlots(TempWeekPatternDialog, WeekdayNo);
            if Day_TimeSLotsID <> 0 then
                InsertWeekPatternLine(WeekdayNo, Day_TimeSLotsID);
        end;

        rec."Week Hash" := CalculateWeekHash(rec);
        rec.Modify(true);
    end;

    local procedure GetOrCreateDay_TimeSlots(var TempWeekPatternDialog: Record "Opti Week Pattern Dialog" temporary; WeekdayNo: Integer) Day_TimeSLotsID: Integer
    var
        Day_TimeSlotsHeader: Record "Opti Day-TimeSlots Header";
        TimeSlot: Record "Opti Time Slot";
        TempTimeSlot: Record "Opti Time Slot" temporary;
        Day_TimeSlotLine: Record "Opti Day-TimeSlot Line";
        EntryNo: Integer;
        DayPatternHash: Text[64];
        GeneratedDayPatternDescriptionLbl: Label 'Generated day pattern %1';
    begin
        TempWeekPatternDialog.Reset();
        TempWeekPatternDialog.SetCurrentKey("Weekday No.", "Start Time", "End Time", "Idle Time", "Entry No.");
        TempWeekPatternDialog.SetRange("Weekday No.", WeekdayNo);
        if not TempWeekPatternDialog.FindSet() then
            exit(0);
        repeat
            TempWeekPatternDialog.ValidateInput();
            TimeSlot.Get(TimeSlot.GetOrCreateTimeSlotID(TempWeekPatternDialog."Start Time", TempWeekPatternDialog."End Time", TempWeekPatternDialog."Idle Time"));
            EntryNo += 1;
            TempTimeSlot.TransferFields(TimeSlot);
            TempTimeSlot.insert();
        until TempWeekPatternDialog.Next() = 0;

        DayPatternHash := CalculateDayPatternHash(TempTimeSlot);
        Day_TimeSlotsHeader.SetRange("Pattern Hash", DayPatternHash);
        if Day_TimeSlotsHeader.FindFirst() then
            exit(Day_TimeSlotsHeader."Day Time SLot Header ID");

        Day_TimeSlotsHeader.Init();
        Day_TimeSlotsHeader.Description :=
            CopyStr(StrSubstNo(GeneratedDayPatternDescriptionLbl, CopyStr(DayPatternHash, 1, 8)), 1, MaxStrLen(Day_TimeSlotsHeader.Description));
        Day_TimeSlotsHeader.Insert(true);
        TempTimeSlot.Reset();
        TempTimeSlot.SetCurrentKey("Start Time", "End Time", "Idle Time", "Time Slot ID");

        if TempTimeSlot.FindSet() then
            repeat
                Day_TimeSlotLine.Init();
                Day_TimeSlotLine."Day Time SLot Header ID" := Day_TimeSlotsHeader."Day Time SLot Header ID";
                Day_TimeSlotLine."Day Time SLot Line No." := 0;
                Day_TimeSlotLine."Time Slot ID" := TempTimeSlot."Time Slot ID";

                Day_TimeSlotLine.Insert(true);
            until TempTimeSlot.Next() = 0;
        Day_TimeSlotsHeader.RecalculatePattern();
        exit(Day_TimeSlotsHeader."Day Time SLot Header ID");
    end;

    local procedure CalculateDayPatternHash(var TempTimeSlotBuffer: Record "Opti Time Slot" temporary): Text[64]
    var
        CryptographyManagement: Codeunit "Cryptography Management";
        HashAlgorithm: Option MD5,SHA1,SHA256,SHA384,SHA512;
        HashInput: Text;
        GeneratedHash: Text;
    begin
        TempTimeSlotBuffer.Reset();
        TempTimeSlotBuffer.SetCurrentKey("Start Time", "End Time", "Idle Time", "Time Slot ID");
        if TempTimeSlotBuffer.FindSet() then
            repeat
                if HashInput <> '' then
                    HashInput += '|';
                HashInput +=
                    StrSubstNo(
                        '%1;%2;%3;%4',
                        FormatTimeForHash(TempTimeSlotBuffer."Start Time"),
                        FormatTimeForHash(TempTimeSlotBuffer."End Time"),
                        Format(TempTimeSlotBuffer."Idle Time", 0, 9),
                        Format(TempTimeSlotBuffer."Time Slot ID", 0, 9));
            until TempTimeSlotBuffer.Next() = 0;

        if HashInput = '' then
            exit('');
        GeneratedHash := CryptographyManagement.GenerateHash(HashInput, HashAlgorithm::SHA256);
        exit(CopyStr(GeneratedHash, 1, 64));
    end;

    local procedure FormatTimeForHash(Value: Time): Text
    begin
        exit(Format(Value, 0, '<Hours24,2><Minutes,2><Seconds,2><Second dec.>'));
    end;

    local procedure InsertWeekPatternLine(WeekdayNo: Integer; DayPatternID: Integer)
    var
        WeekPatternLine: Record "Opti Week Pattern Line";
        Day_TimeSlots: Record "Opti Day-TimeSlots Header";
    begin
        Day_TimeSlots.Get(DayPatternID);
        WeekPatternLine.Init();
        WeekPatternLine."Week Pattern Code" := "Week Pattern Code";
        WeekPatternLine.Validate("Weekday No.", WeekdayNo);
        WeekPatternLine.Validate("Day Pattern ID", DayPatternID);
        WeekPatternLine.Insert(true);
    end;

    procedure CalculateWeekHash(var WkPatternHdr: record "Opti Week Pattern Header") WeekHash: Text[64]
    var
        WeekPatternLine: Record "Opti Week Pattern Line";
        CryptographyManagement: Codeunit "Cryptography Management";
        HashAlgorithm: Option MD5,SHA1,SHA256,SHA384,SHA512;
        HashInput: Text;
        TotalMinutes: Integer;
        NumberOfTimeSlots: Integer;
    begin
        WkPatternHdr.TestField("Week Pattern Code");
        WeekPatternLine.SetRange("Week Pattern Code", WkPatternHdr."Week Pattern Code");
        WeekPatternLine.SetCurrentKey("Week Pattern Code", "Weekday No.");

        if WeekPatternLine.FindSet() then
            repeat
                WeekPatternLine.CalcFields("Working Minutes", "No. of Time Slots", "Day Pattern Hash");
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

        WkPatternHdr."Total Minutes" := TotalMinutes;
        WkPatternHdr."Total Hours" := TotalMinutes / 60;
        WkPatternHdr."No. of Time Slots" := NumberOfTimeSlots;

        if HashInput <> '' then
            "WeekHash" := CryptographyManagement.GenerateHash(HashInput, HashAlgorithm::SHA256);
    end;

    var
        NoWeekPatternLinesErr:
        Label 'Enter at least one time slot for the week pattern.';

}