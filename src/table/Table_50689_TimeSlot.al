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
        TimeSlot: Record "Time Slot";
        WorkHourTemplate: Record "Work-Hour Template";
        DayIndex: Integer;
        TimeSlotNo: Integer;
        DayHours: Decimal;
    begin
        if WorkHourTemplateCode = '' then
            Error('Work-Hour Template must have a value.');

        WorkHourTemplate.Get(WorkHourTemplateCode);

        TimeSlotNo := GetNewTimeSlotNo();
        TimeSlot.SetRange("Integer", TimeSlotNo);
        TimeSlot.DeleteAll();

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

        NewTimeSlotNo := TimeSlotNo;
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
}
