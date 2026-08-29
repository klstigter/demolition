table 50619 "Opti Day-TimeSlots Header"
{
    Caption = 'Day Pattern';
    DataClassification = CustomerContent;
    LookupPageId = "Opti Day-TimeSlots Hdr List";
    DrillDownPageId = "Opti Day-TimeSlots Hdr List";

    fields
    {
        field(1; "Day-TimeSLots Header No."; Integer)
        {
            Caption = 'Day-TimeSlots Header No.';
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
        key(PK; "Day-TimeSLots Header No.")
        {
            Clustered = true;
        }

        key(PatternHash; "Pattern Hash")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Day-TimeSLots Header No.", Description, "Total Working Hours")
        {
        }
    }

    procedure RecalculatePattern()
    var
        TempTimeSlot: Record "Opti Time Slot" temporary;
        TotalWorkingMinutes: Integer;
        NumberOfTimeSlots: Integer;
    begin
        TestField("Day-TimeSLots Header No.");

        fillTempTimeSlot("Day-TimeSLots Header No.", TotalWorkingMinutes, NumberOfTimeSlots, TempTimeSlot);
        "Total Working Minutes" := TotalWorkingMinutes;
        "Total Working Hours" := TotalWorkingMinutes / 60;
        "No. of Time Slots" := NumberOfTimeSlots;
        "Pattern Hash" := CalculateHash(tempTimeSlot);
        Modify(true);
    end;

    procedure FillTempTimeSlot("Day-TimeSLots Header No.": Integer; var TotalWorkingMinutes: Integer;
        var NumberOfTimeSlots: Integer; var TempTimeSlotBuffer: Record "Opti Time Slot" temporary)
    var
        TimeSlot: Record "Opti Time Slot";
        DayTimeSlotLines: Record "Opti Day-TimeSlot Line";
    begin
        DayTimeSlotLines.SetRange("Day-TimeSLots Header No.", "Day-TimeSLots Header No."); // Replace with: DayTimeSlotLines.SetRange("Day-TimeSLots Header No.", "Day-TimeSLots Header No.");
        TotalWorkingMinutes := 0;
        NumberOfTimeSlots := 0;
        if DayTimeSlotLines.FindSet() then
            repeat
                TimeSlot.Get(DayTimeSlotLines."Time Slot No.");

                TempTimeSlotBuffer.Init();
                TempTimeSlotBuffer."Time Slot No." := TimeSlot."Time Slot No.";
                TempTimeSlotBuffer."Start Time" := TimeSlot."Start Time";
                TempTimeSlotBuffer."End Time" := TimeSlot."End Time";
                TempTimeSlotBuffer."Idle Time" := TimeSlot."Idle Time";
                TempTimeSlotBuffer.Insert();

                TotalWorkingMinutes += TimeSlot."Working Minutes";
                NumberOfTimeSlots += 1;
            until DayTimeSlotLines.Next() = 0;
    end;

    procedure CalculateHash(var TempTimeSlotBuffer: Record "Opti Time Slot" temporary) GeneratedHash: Text;
    var
        EntryNo: Integer;
        CryptographyManagement: Codeunit "Cryptography Management";
        HashAlgorithm: Option MD5,SHA1,SHA256,SHA384,SHA512;
        HashInput: Text;
    begin
        TempTimeSlotBuffer.SetCurrentKey("Start Time", "End Time", "Idle Time", "Time Slot No.");
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
                        Format(TempTimeSlotBuffer."Time Slot No.", 0, 9));
            until TempTimeSlotBuffer.Next() = 0;

        if HashInput = '' then
            Clear("Pattern Hash")
        else begin
            GeneratedHash :=
                CryptographyManagement.GenerateHash(
                    HashInput,
                    HashAlgorithm::SHA256);
        end;
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