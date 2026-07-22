table 50614 "Time Slot"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Integer"; Integer)
        {
            Caption = 'Integer';
            MinValue = 1;
        }
        field(2; "Day No."; Enum "Time Slot Day")
        {
            Caption = 'Day No.';
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
            Editable = false;
        }
        field(10; "Start Time"; Time)
        {
            Caption = 'Start Time';

            trigger OnValidate()
            begin
                RecalculateHours();
            end;
        }
        field(20; "End Time"; Time)
        {
            Caption = 'End Time';

            trigger OnValidate()
            begin
                RecalculateHours();
            end;
        }
        field(30; "Non Working Minutes"; Integer)
        {
            Caption = 'Non Working Minutes';
            MinValue = 0;

            trigger OnValidate()
            begin
                RecalculateHours();
            end;
        }
        field(40; Hours; Decimal)
        {
            Caption = 'Hours';
            DecimalPlaces = 0 : 2;
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Integer", "Day No.", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Integer", "Day No.", "Start Time", "End Time", "Non Working Minutes", Hours, "Line No.")
        {
        }
    }

    trigger OnInsert()
    begin
        if "Integer" = 0 then
            "Integer" := 1;

        if "Line No." = 0 then
            "Line No." := GetNextLineNo("Integer", "Day No.");

        RecalculateHours();
    end;

    local procedure GetNextLineNo(IntegerNo: Integer; DayNo: Enum "Time Slot Day"): Integer
    var
        TimeSlot: Record "Time Slot";
    begin
        TimeSlot.SetRange("Integer", IntegerNo);
        TimeSlot.SetRange("Day No.", DayNo);

        if TimeSlot.FindLast() then
            exit(TimeSlot."Line No." + 10000);

        exit(10000);
    end;

    local procedure RecalculateHours()
    var
        WorkingMinutes: Integer;
    begin
        if ("Start Time" = 0T) or ("End Time" = 0T) then begin
            Hours := 0;
            exit;
        end;

        if "End Time" < "Start Time" then
            Error('End Time must be greater than or equal to Start Time.');

        WorkingMinutes := ("End Time" - "Start Time") div 60000;
        WorkingMinutes := WorkingMinutes - "Non Working Minutes";

        if WorkingMinutes < 0 then
            WorkingMinutes := 0;

        Hours := WorkingMinutes / 60;
    end;

    procedure GetWorkingHours(TimeSlotNo: Integer): Text[250]
    var
        DayIndex: Integer;
        WorkingHoursText: Text[250];
    begin
        for DayIndex := 1 to 7 do begin
            if DayIndex > 1 then
                WorkingHoursText += '|';

            WorkingHoursText += GetWorkingHoursForDay(TimeSlotNo, GetDayNoByIndex(DayIndex));
        end;

        exit(WorkingHoursText);
    end;

    procedure CreateTimeSlots(WorkHourTemplateCode: Code[20]) NewTimeSlotNo: Integer
    var
        WorkHourTemplate: Record "Work-Hour Template";
        TimeSlotNo: Integer;
    begin
        if WorkHourTemplateCode = '' then
            Error('Work-Hour Template must have a value.');

        WorkHourTemplate.Get(WorkHourTemplateCode);

        TimeSlotNo := GetNewTimeSlotNo();
        InsertTimeSlotLinesFromTemplate(TimeSlotNo, WorkHourTemplate);

        NewTimeSlotNo := ResolveTimeSlotSet(TimeSlotNo);
    end;

    procedure CloneTimeSlotSet(SourceTimeSlotNo: Integer): Integer
    var
        SourceTimeSlot: Record "Time Slot";
        TargetTimeSlot: Record "Time Slot";
        NewTimeSlotNo: Integer;
    begin
        if SourceTimeSlotNo = 0 then
            exit(0);

        SourceTimeSlot.SetRange("Integer", SourceTimeSlotNo);
        if not SourceTimeSlot.FindSet() then
            exit(0);

        NewTimeSlotNo := GetNewTimeSlotNo();
        repeat
            TargetTimeSlot.Init();
            TargetTimeSlot.Validate("Integer", NewTimeSlotNo);
            TargetTimeSlot.Validate("Day No.", SourceTimeSlot."Day No.");
            TargetTimeSlot.Validate("Start Time", SourceTimeSlot."Start Time");
            TargetTimeSlot.Validate("End Time", SourceTimeSlot."End Time");
            TargetTimeSlot.Validate("Non Working Minutes", SourceTimeSlot."Non Working Minutes");
            TargetTimeSlot.Insert(true);
            TargetTimeSlot.Hours := SourceTimeSlot.Hours;
            TargetTimeSlot.Modify(false);
        until SourceTimeSlot.Next() = 0;

        exit(NewTimeSlotNo);
    end;

    procedure ResolveTimeSlotSet(TimeSlotNo: Integer): Integer
    var
        CanonicalCombination: Text;
        CanonicalHash: Code[100];
        ExistingTimeSlotNo: Integer;
    begin
        CanonicalCombination := BuildCanonicalCombinationFromTimeSlotNo(TimeSlotNo);
        if CanonicalCombination = '' then
            exit(TimeSlotNo);

        CanonicalHash := GetCanonicalHash(CanonicalCombination);
        ExistingTimeSlotNo := FindExistingTimeSlotNoByHash(CanonicalHash, CanonicalCombination, TimeSlotNo);
        if ExistingTimeSlotNo <> 0 then begin
            DeleteTimeSlotSet(TimeSlotNo);
            exit(ExistingTimeSlotNo);
        end;

        RegisterCanonicalIndex(CanonicalHash, CanonicalCombination, TimeSlotNo);
        exit(TimeSlotNo);
    end;

    procedure DeleteTimeSlotSet(TimeSlotNo: Integer)
    var
        TimeSlot: Record "Time Slot";
        TimeSlotCanonicalIndex: Record "Time Slot Canonical Index";
    begin
        TimeSlot.SetRange("Integer", TimeSlotNo);
        TimeSlot.DeleteAll();

        TimeSlotCanonicalIndex.SetRange("Time Slot No.", TimeSlotNo);
        TimeSlotCanonicalIndex.DeleteAll();
    end;

    local procedure InsertTimeSlotLinesFromTemplate(TimeSlotNo: Integer; WorkHourTemplate: Record "Work-Hour Template")
    var
        TimeSlot: Record "Time Slot";
        DayIndex: Integer;
        DayHours: Decimal;
    begin

        for DayIndex := 1 to 7 do begin
            DayHours := GetTemplateHoursForDay(WorkHourTemplate, DayIndex);
            if DayHours > 0 then begin
                TimeSlot.Init();
                TimeSlot.Validate("Integer", TimeSlotNo);
                TimeSlot.Validate("Day No.", GetDayNoByIndex(DayIndex));
                TimeSlot.Validate("Start Time", WorkHourTemplate."Default Start Time");
                TimeSlot.Validate("End Time", WorkHourTemplate."Default End Time");
                TimeSlot.Validate("Non Working Minutes", WorkHourTemplate."Non Working Minutes");
                TimeSlot.Insert(true);

                // Keep the per-weekday hours from the template.
                TimeSlot.Hours := DayHours;
                TimeSlot.Modify(false);
            end;
        end;
    end;

    procedure GetNewTimeSlotNo(): Integer
    var
        TimeSlot: Record "Time Slot";
    begin
        if TimeSlot.FindLast() then
            exit(TimeSlot."Integer" + 1);

        exit(1);
    end;

    local procedure GetWorkingHoursForDay(TimeSlotNo: Integer; DayNo: Enum "Time Slot Day"): Text[30]
    var
        TimeSlot: Record "Time Slot";
        TotalHours: Decimal;
    begin
        TimeSlot.SetRange("Integer", TimeSlotNo);
        TimeSlot.SetRange("Day No.", DayNo);
        if not TimeSlot.FindSet() then
            exit('-');

        repeat
            TotalHours += TimeSlot.Hours;
        until TimeSlot.Next() = 0;

        exit(Format(TotalHours));
    end;

    local procedure GetDayNoByIndex(DayIndex: Integer): Enum "Time Slot Day"
    begin
        case DayIndex of
            1:
                exit("Day No."::Monday);
            2:
                exit("Day No."::Tuesday);
            3:
                exit("Day No."::Wednesday);
            4:
                exit("Day No."::Thursday);
            5:
                exit("Day No."::Friday);
            6:
                exit("Day No."::Saturday);
            7:
                exit("Day No."::Sunday);
        end;

        exit("Day No."::Monday);
    end;

    local procedure GetTemplateHoursForDay(WorkHourTemplate: Record "Work-Hour Template"; DayIndex: Integer): Decimal
    begin
        case DayIndex of
            1:
                exit(WorkHourTemplate.Monday);
            2:
                exit(WorkHourTemplate.Tuesday);
            3:
                exit(WorkHourTemplate.Wednesday);
            4:
                exit(WorkHourTemplate.Thursday);
            5:
                exit(WorkHourTemplate.Friday);
            6:
                exit(WorkHourTemplate.Saturday);
            7:
                exit(WorkHourTemplate.Sunday);
        end;

        exit(0);
    end;

    local procedure BuildCanonicalCombinationFromTimeSlotNo(TimeSlotNo: Integer): Text
    var
        TimeSlot: Record "Time Slot";
        CanonicalCombination: Text;
    begin
        TimeSlot.SetCurrentKey("Integer", "Day No.", "Start Time", "End Time", "Non Working Minutes", Hours, "Line No.");
        TimeSlot.SetRange("Integer", TimeSlotNo);
        if TimeSlot.FindSet() then
            repeat
                CanonicalCombination += BuildCanonicalLine(
                    TimeSlot."Day No.".AsInteger(),
                    TimeToMinutes(TimeSlot."Start Time"),
                    TimeToMinutes(TimeSlot."End Time"),
                    TimeSlot."Non Working Minutes",
                    TimeSlot.Hours) + ';';
            until TimeSlot.Next() = 0;

        exit(CanonicalCombination);
    end;

    local procedure FindExistingTimeSlotNoByHash(CanonicalHash: Code[100]; CanonicalCombination: Text; ExcludeTimeSlotNo: Integer): Integer
    var
        TimeSlotCanonicalIndex: Record "Time Slot Canonical Index";
    begin
        TimeSlotCanonicalIndex.SetRange("Hash Key", CanonicalHash);
        if TimeSlotCanonicalIndex.FindSet() then
            repeat
                if (TimeSlotCanonicalIndex."Time Slot No." <> ExcludeTimeSlotNo)
                   and CanonicalIndexMatches(TimeSlotCanonicalIndex, CanonicalCombination)
                   and TimeSlotSetExists(TimeSlotCanonicalIndex."Time Slot No.") then
                    exit(TimeSlotCanonicalIndex."Time Slot No.");
            until TimeSlotCanonicalIndex.Next() = 0;

        exit(0);
    end;

    local procedure RegisterCanonicalIndex(CanonicalHash: Code[100]; CanonicalCombination: Text; TimeSlotNo: Integer)
    var
        TimeSlotCanonicalIndex: Record "Time Slot Canonical Index";
    begin
        TimeSlotCanonicalIndex.SetRange("Time Slot No.", TimeSlotNo);
        TimeSlotCanonicalIndex.DeleteAll();

        TimeSlotCanonicalIndex.Init();
        TimeSlotCanonicalIndex."Hash Key" := CanonicalHash;
        TimeSlotCanonicalIndex."Canonical Combination" := CopyStr(CanonicalCombination, 1, MaxStrLen(TimeSlotCanonicalIndex."Canonical Combination"));
        TimeSlotCanonicalIndex."Canonical Length" := StrLen(CanonicalCombination);
        WriteCanonicalBlob(TimeSlotCanonicalIndex, CanonicalCombination);
        TimeSlotCanonicalIndex."Time Slot No." := TimeSlotNo;
        TimeSlotCanonicalIndex.Insert(true);
    end;

    local procedure CanonicalIndexMatches(var TimeSlotCanonicalIndex: Record "Time Slot Canonical Index"; CanonicalCombination: Text): Boolean
    begin
        if TimeSlotCanonicalIndex."Canonical Length" <> StrLen(CanonicalCombination) then
            exit(false);

        exit(ReadCanonicalBlob(TimeSlotCanonicalIndex) = CanonicalCombination);
    end;

    local procedure WriteCanonicalBlob(var TimeSlotCanonicalIndex: Record "Time Slot Canonical Index"; CanonicalCombination: Text)
    var
        CanonicalOutStream: OutStream;
    begin
        Clear(TimeSlotCanonicalIndex."Canonical Combination Blob");
        TimeSlotCanonicalIndex."Canonical Combination Blob".CreateOutStream(CanonicalOutStream, TextEncoding::UTF8);
        CanonicalOutStream.WriteText(CanonicalCombination);
    end;

    local procedure ReadCanonicalBlob(var TimeSlotCanonicalIndex: Record "Time Slot Canonical Index"): Text
    var
        CanonicalInStream: InStream;
        CanonicalChunk: Text;
        CanonicalText: Text;
    begin
        if not TimeSlotCanonicalIndex."Canonical Combination Blob".HasValue() then
            exit(TimeSlotCanonicalIndex."Canonical Combination");

        TimeSlotCanonicalIndex.CalcFields("Canonical Combination Blob");
        TimeSlotCanonicalIndex."Canonical Combination Blob".CreateInStream(CanonicalInStream, TextEncoding::UTF8);

        while not CanonicalInStream.EOS do begin
            CanonicalInStream.ReadText(CanonicalChunk);
            CanonicalText += CanonicalChunk;
        end;

        exit(CanonicalText);
    end;

    local procedure TimeSlotSetExists(TimeSlotNo: Integer): Boolean
    var
        TimeSlot: Record "Time Slot";
    begin
        TimeSlot.SetRange("Integer", TimeSlotNo);
        exit(TimeSlot.FindFirst());
    end;

    local procedure BuildCanonicalLine(DayIndex: Integer; StartMinutes: Integer; EndMinutes: Integer; NonWorkingMinutes: Integer; HoursValue: Decimal): Text
    begin
        exit(
            Format(DayIndex, 0, '<Integer>') + '|' +
            Format(StartMinutes, 0, '<Integer>') + '|' +
            Format(EndMinutes, 0, '<Integer>') + '|' +
            Format(NonWorkingMinutes, 0, '<Integer>') + '|' +
            Format(Round(HoursValue * 100, 1, '='), 0, '<Integer>'));
    end;

    local procedure TimeToMinutes(TimeValue: Time): Integer
    begin
        exit((TimeValue - 0T) div 60000);
    end;

    local procedure GetCanonicalHash(CanonicalCombination: Text): Code[100]
    var
        CryptographyManagement: Codeunit "Cryptography Management";
        HashAlgorithm: Option MD5,SHA1,SHA256,SHA384,SHA512;
    begin
        exit(CopyStr(CryptographyManagement.GenerateHash(CanonicalCombination, HashAlgorithm::SHA256), 1, 100));
    end;

}
