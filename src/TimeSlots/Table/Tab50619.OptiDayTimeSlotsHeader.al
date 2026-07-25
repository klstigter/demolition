table 50619 "Opti Day Time Slots Header"
{
    Caption = 'Day Pattern';
    DataClassification = CustomerContent;
    LookupPageId = "Opti Day Time Slots Hdr List";
    DrillDownPageId = "Opti Day Time Slots Hdr List";

    fields
    {
        field(1; "Day Time SLot Header ID"; Integer)
        {
            Caption = 'Day Time Slot Header ID';
            AutoIncrement = true;
            Editable = false;
        }
        field(10; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(20; "Total Working Minutes"; Integer)
        {
            Caption = 'Total Working Minutes';
            Editable = false;
        }
        field(30; "Total Working Hours"; Decimal)
        {
            Caption = 'Total Working Hours';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(40; "No. of Time Slots"; Integer)
        {
            Caption = 'No. of Time Slots';
            Editable = false;
        }
        field(50; "Pattern Hash"; Text[64])
        {
            Caption = 'Pattern Hash';
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Day Time SLot Header ID")
        {
            Clustered = true;
        }

        key(PatternHash; "Pattern Hash")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown;
        "Day Time SLot Header ID",
            Description,
            "Total Working Hours")
        {
        }
    }

    procedure RecalculatePattern()
    var
        DayTimeSlotLines: Record "Opti Day TimeSlot Line";
        TimeSlot: Record "Opti Time Slot";
        TempTimeSlotBuffer: Record "Opti Time Slot Buffer" temporary;
        CryptographyManagement: Codeunit "Cryptography Management";
        HashAlgorithm: Option MD5,SHA1,SHA256,SHA384,SHA512;
        HashInput: Text;
        GeneratedHash: Text;
        EntryNo: Integer;
        TotalWorkingMinutes: Integer;
        NumberOfTimeSlots: Integer;
    begin
        TestField("Day Time SLot Header ID");

        DayTimeSlotLines.SetRange("Day Time SLot Header ID", "Day Time SLot Header ID");

        if DayTimeSlotLines.FindSet() then
            repeat
                TimeSlot.Get(DayTimeSlotLines."Time SLot ID");

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

                TotalWorkingMinutes += TimeSlot."Working Minutes";
                NumberOfTimeSlots += 1;
            until DayTimeSlotLines.Next() = 0;

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

        "Total Working Minutes" := TotalWorkingMinutes;
        "Total Working Hours" := TotalWorkingMinutes / 60;
        "No. of Time Slots" := NumberOfTimeSlots;

        Modify(true);
    end;

    local procedure FormatTimeForHash(Value: Time): Text
    begin
        exit(
            Format(
                Value,
                0,
                '<Hours24,2><Minutes,2><Seconds,2><Second dec.>'));
    end;
}