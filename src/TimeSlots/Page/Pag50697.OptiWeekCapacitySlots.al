page 50697 "Opti Week Capacity Slots"
{
    Caption = 'Capacity Time Slots';
    PageType = ListPart;
    SourceTable = "Opti Week Capacity Slot";
    SourceTableTemporary = true;
    ApplicationArea = All;
    Editable = false;
    insertAllowed = false;
    modifyAllowed = false;
    deleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Slots)
            {
                field("Weekday Name"; Rec."Weekday Name")
                {
                    ApplicationArea = All;
                }

                field("Capacity Date"; Rec."Capacity Date")
                {
                    ApplicationArea = All;
                }

                field("Entry Type"; Rec."Entry Type")
                {
                    ApplicationArea = All;
                }

                field("Start Time"; Rec."Start Time")
                {
                    ApplicationArea = All;
                }

                field("End Time"; Rec."End Time")
                {
                    ApplicationArea = All;
                }

                field("Rest Minutes"; Rec."Rest Minutes")
                {
                    ApplicationArea = All;
                }

                field("Working Hours"; Rec."Working Hours")
                {
                    ApplicationArea = All;
                }

                field("Capacity Hours"; Rec."Capacity Hours")
                {
                    ApplicationArea = All;
                }

                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(AddCapacityEntry)
            {
                ApplicationArea = All;
                Caption = 'Add Capacity Entry';
                Image = NewLine;
                ToolTip =
                    'Add additional capacity or an absence for the selected resource and date.';

                trigger OnAction()
                begin
                    AddManualCapacityEntry();
                end;
            }
        }
    }

    procedure SetWeek(
       ResourceNo: Code[20];
       WeekStartDate: Date)
    begin
        if (ResourceNo = '') or (WeekStartDate = 0D) then begin
            Rec.Reset();
            Rec.DeleteAll();
            CurrPage.Update(false);
            exit;
        end;

        LoadWeek(ResourceNo, WeekStartDate);
        CurrPage.Update(false);
    end;

    local procedure LoadWeek(
    ResourceNo: Code[20];
    WeekStartDate: Date)
    var
        DayNo: Integer;
        CapacityDate: Date;
    begin
        Rec.Reset();
        Rec.DeleteAll();

        for DayNo := 1 to 7 do begin
            CapacityDate := WeekStartDate + DayNo - 1;

            if not InsertTimeSlotRows(
                ResourceNo,
                CapacityDate,
                DayNo)
            then
                InsertEmptyDayRow(
                    ResourceNo,
                    CapacityDate,
                    DayNo);
        end;

        Rec.Reset();
        Rec.SetCurrentKey("Day No.", "Slot Line No.");

        if not Rec.IsEmpty() then
            Rec.FindFirst();
    end;

    local procedure InsertEmptyDayRow(
    ResourceNo: Code[20];
    CapacityDate: Date;
    DayNo: Integer)
    begin
        Rec.Init();
        Rec."Day No." := DayNo;
        Rec."Slot Line No." := 0;
        Rec."Row Type" := Rec."Row Type"::Day;
        Rec."Resource No." := ResourceNo;
        Rec."Capacity Date" := CapacityDate;
        Rec."Weekday Name" :=
            CopyStr(
                Format(CapacityDate, 0, '<Weekday Text>'),
                1,
                MaxStrLen(Rec."Weekday Name"));
        Rec.Insert();
    end;

    local procedure InsertTimeSlotRows(
    ResourceNo: Code[20];
    CapacityDate: Date;
    DayNo: Integer): Boolean
    var
        CapacityEntry: Record "Opti Capacity Entry";
        DayTimeSlotLine: Record "Opti Day TimeSlot Line";
        TimeSlot: Record "Opti Time Slot";
        SlotLineNo: Integer;
        Inserted: Boolean;
    begin
        CapacityEntry.Reset();
        CapacityEntry.SetRange("Resource No.", ResourceNo);
        CapacityEntry.SetRange("Capacity Date", CapacityDate);

        if CapacityEntry.FindSet() then
            repeat
                DayTimeSlotLine.Reset();
                DayTimeSlotLine.SetRange(
                    "Day Time Slot Header ID",
                    CapacityEntry."Day Time Slot Header ID");

                if DayTimeSlotLine.FindSet() then
                    repeat
                        TimeSlot.Get(DayTimeSlotLine."Time Slot ID");

                        SlotLineNo += 10000;

                        Rec.Init();
                        Rec."Day No." := DayNo;
                        Rec."Slot Line No." := SlotLineNo;
                        Rec."Row Type" := Rec."Row Type"::"Time Slot";
                        Rec."Resource No." := ResourceNo;
                        Rec."Capacity Date" := CapacityDate;
                        Rec."Weekday Name" :=
                            CopyStr(
                                Format(CapacityDate, 0, '<Weekday Text>'),
                                1,
                                MaxStrLen(Rec."Weekday Name"));
                        Rec."Capacity Entry Line No." :=
                            CapacityEntry."Line No.";
                        Rec."Entry Type" :=
                            CapacityEntry."Entry Type";
                        Rec."Time Slot ID" :=
                            TimeSlot."Time Slot ID";
                        Rec."Start Time" :=
                            TimeSlot."Start Time";
                        Rec."End Time" :=
                            TimeSlot."End Time";
                        Rec."Rest Minutes" :=
                            TimeSlot."Rest Minutes";
                        Rec."Working Minutes" :=
                            TimeSlot."Working Minutes";
                        Rec."Working Hours" :=
                            TimeSlot."Working Hours";
                        Rec.Description :=
                            CapacityEntry.Description;

                        case CapacityEntry."Entry Type" of
                            CapacityEntry."Entry Type"::Normal,
                            CapacityEntry."Entry Type"::Additional:
                                Rec."Capacity Hours" :=
                                    TimeSlot."Working Hours";

                            CapacityEntry."Entry Type"::Absence:
                                Rec."Capacity Hours" :=
                                    -TimeSlot."Working Hours";
                        end;

                        Rec.Insert();
                        Inserted := true;
                    until DayTimeSlotLine.Next() = 0;
            until CapacityEntry.Next() = 0;

        exit(Inserted);
    end;

    local procedure AddManualCapacityEntry()
    var
        CapacityEntry: Record "Opti Capacity Entry";
        CapacityEntryDialog: Page "Opti Capacity Entry Dialog";
        EntryType: Enum "Opti Capacity Entry Type";
        EntryDescription: Text[100];
        StartTime: Time;
        EndTime: Time;
        RestMinutes: Integer;
    begin
        Rec.TestField("Resource No.");
        Rec.TestField("Capacity Date");

        if CapacityEntryDialog.RunModal() <> Action::OK then
            exit;

        CapacityEntryDialog.GetValues(
            EntryType,
            EntryDescription,
            StartTime,
            EndTime,
            RestMinutes);

        CapacityEntry.InsertManualEntry(
            Rec."Resource No.",
            Rec."Capacity Date",
            EntryType,
            EntryDescription,
            StartTime,
            EndTime,
            RestMinutes);

        CurrPage.Update(false);
    end;
}