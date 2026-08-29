table 50628 "Opti Week Capacity Dialog"
{
    Caption = 'Week Capacity Slot';
    DataClassification = CustomerContent;
    TableType = Temporary;

    fields
    {
        field(1; "Day No."; Integer)
        {
            Caption = 'Day No.';
        }
        field(2; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }

        field(3; "Slot Line No."; Integer)
        {
            Caption = 'Slot Line No.';
        }

        field(4; "Capacity Date"; Date)
        {
            Caption = 'Capacity Date';
        }

        field(5; "Week Year"; Integer)
        {
            Caption = 'Week Year';
        }
        field(6; "Week No."; Integer)
        {
            Caption = 'Week No.';
        }
        field(7; "Weekday Name"; Text[20])
        {
            Caption = 'Weekday';
        }

        field(8; "Capacity Entry Line No."; Integer)
        {
            Caption = 'Capacity Entry Line No.';
        }

        field(9; "Entry Type"; Enum "Opti Capacity Entry Type")
        {
            Caption = 'Entry Type';
        }

        field(20; "Time Slot No."; Integer)
        {
            Caption = 'Time Slot No.';
            tableRelation = "Opti Time Slot"."Time Slot No.";
        }
        field(21; "DayTimeSlotLineNo"; Integer)
        {
            Caption = 'Day-TimeSlots ID';
            tableRelation = "Opti Day-TimeSlot Line"."Day-TimeSLot Line No." WHERE("Day-TimeSLots Header No." = FIELD("Day-TimeSlots Header No."));
        }
        field(22; "Day-TimeSlots Header No."; Integer)
        {
            Caption = 'Day-TimeSlots Header ID';
            tableRelation = "Opti Day-TimeSlots Header"."Day-TimeSLots Header No.";
        }

        field(30; "Start Time"; Time)
        {
            Caption = 'Start Time';
        }

        field(40; "End Time"; Time)
        {
            Caption = 'End Time';
        }

        field(50; "Idle Time"; Integer)
        {
            Caption = 'Idle Times';
        }

        field(60; "Working Minutes"; Integer)
        {
            Caption = 'Working Minutes';
        }

        field(70; "Working Hours"; Decimal)
        {
            Caption = 'Working Hours';
            DecimalPlaces = 0 : 5;
        }

        field(80; "Capacity Hours"; Decimal)
        {
            Caption = 'Capacity Hours';
            DecimalPlaces = 0 : 5;
        }

        field(90; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(100; "Manual"; Boolean)
        {
            Caption = 'Manual';
        }
        field(110; "Resource No."; Code[20])
        {
            Caption = 'Resource No.';
        }

        field(120; "Week Start Date"; Date)
        {
            Caption = 'Week Start Date';
        }
    }

    keys
    {
        key(PK; "Day No.", "Entry No.")
        {
            Clustered = true;
        }

        key(DateTime; "Capacity Date", "Start Time", "Entry No.")
        {
        }
    }

    procedure GetNextBufferEntryNo(CapacityDate: Date): Integer
    var
        WeekCapacitySlot: Record "Opti Week Capacity Dialog" temporary;
        DayNo: Integer;
    begin
        WeekCapacitySlot.Copy(Rec, true);
        WeekCapacitySlot.Reset();

        DayNo := Date2DWY(CapacityDate, 1);
        WeekCapacitySlot.SetRange("Day No.", DayNo);

        WeekCapacitySlot.SetCurrentKey("Entry No.");

        if WeekCapacitySlot.FindLast() then
            exit(WeekCapacitySlot."Entry No." + 1);

        exit(1);
    end;

    procedure AddEntryForDate(CapacityDate: Date; ResourceNo: Code[20])
    var
        NextEntryNo: Integer;
    begin
        if (ResourceNo = '') or (CapacityDate = 0D) then
            exit;

        NextEntryNo := rec.GetNextBufferEntryNo(CapacityDate);

        Rec.Init();
        Rec."Entry No." := NextEntryNo;
        Rec."Day No." := Date2DWY(CapacityDate, 1);
        Rec."Slot Line No." := NextEntryNo;
        Rec."Resource No." := ResourceNo;
        Rec."Capacity Date" := CapacityDate;
        Rec."Weekday Name" := GetWeekdayName(CapacityDate);
        Rec."Entry Type" := Rec."Entry Type"::Normal;
        Rec.Manual := true;
        Rec.Insert();

    end;

    procedure GetWeekdayName(
   CapacityDate: Date): Text[20]
    begin
        case Date2DWY(CapacityDate, 1) of
            1:
                exit('Monday');
            2:
                exit('Tuesday');
            3:
                exit('Wednesday');
            4:
                exit('Thursday');
            5:
                exit('Friday');
            6:
                exit('Saturday');
            7:
                exit('Sunday');
        end;

        exit('');
    end;

    Procedure ApplyWeekPatternDialog()
    var
        DayNo: Integer;
    begin
        rec.Reset();
        rec.SetCurrentKey("Day No.", "Entry No.");
        for dayNo := 1 to 7 do begin
            rec.setrange("Day No.", DayNo);
            CheckTimeSlot(DayNo);
            if DayNo <> rec."Day No." then begin
                DayNo := rec."Day No.";
                rec.CheckDay_TimeSlots();
            end;
        end;
        CheckDay_TimeSlots();
        CheckCapacity_WeekPattern();
        CheckResource_Capacity();
    end;

    Procedure CheckTimeSlot(DayNo: Integer)
    var
        TimeSlot: Record "Opti Time Slot";
    begin
        if rec.FindSet() then
            repeat
                rec."Time Slot No." := Timeslot.GetOrCreateTimeSlotID(Rec."Start Time", Rec."End Time", Rec."Idle Time");
                if rec."Time Slot No." <> xrec."Time Slot No." then
                    rec.Modify();
            until rec.Next() = 0;
    end;

    procedure CheckDay_TimeSlots()
    var
        DayTimeSlotsHeader: Record "Opti Day-TimeSlots Header";
        TempTimeSlotBuffer: Record "Opti Time Slot" temporary;
        TimeSlot: Record "Opti Time Slot";
        DayHash: Text[64];
    begin
        if rec.FindSet() then
            repeat
                TimeSlot.Get(rec."Time Slot No.");
                TempTimeSlotBuffer.Init();
                TempTimeSlotBuffer."Time Slot No." := TimeSlot."Time Slot No.";
                TempTimeSlotBuffer."Start Time" := TimeSlot."Start Time";
                TempTimeSlotBuffer."End Time" := TimeSlot."End Time";
                TempTimeSlotBuffer."Idle Time" := TimeSlot."Idle Time";
                TempTimeSlotBuffer.Insert();
            until rec.Next() = 0;
        DayHash := DayTimeSlotsHeader.CalculateHash(TempTimeSlotBuffer);
        dayTimeSlotsHeader.SetRange("Pattern Hash", DayHash);
        if not DayTimeSlotsHeader.FindFirst() then begin
            DayTimeSlotsHeader.Init();
            DayTimeSlotsHeader.Description := 'Generated day pattern ' + CopyStr(DayHash, 1, 8);
            DayTimeSlotsHeader.Insert(true);
        end;
    end;

    Procedure CheckCapacity_WeekPattern()
    var
        CapacityWeekPtnHeader: Record "Opti Capacity Week Pattern Hdr";
        CapacityWeekPtnLine: Record "Opti Capacity Week Pattern Ln";
    begin
    end;

    Procedure CheckResource_Capacity()
    begin

    end;


}