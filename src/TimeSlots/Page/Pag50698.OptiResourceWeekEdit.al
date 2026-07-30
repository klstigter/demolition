page 50698 "Opti Resource Week Edit"
{
    Caption = 'Edit Resource Capacity Week';
    PageType = Worksheet;
    SourceTable = "Opti Week Capacity Slot";
    DelayedInsert = true;
    SourceTableTemporary = true;
    ApplicationArea = All;
    UsageCategory = None;

    InsertAllowed = false;
    ModifyAllowed = true;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(Week)
            {
                Caption = 'Resource and Week';

                field(SelectedResourceNo; SelectedResourceNo)
                {
                    ApplicationArea = All;
                    Caption = 'Resource No.';
                    Editable = false;
                    TableRelation = Resource."No.";
                }

                field(SelectedWeekStartDate; SelectedWeekStartDate)
                {
                    ApplicationArea = All;
                    Caption = 'Week Start Date';
                    Editable = false;
                }

                field(SelectedWeekEndDate; SelectedWeekEndDate)
                {
                    ApplicationArea = All;
                    Caption = 'Week End Date';
                    Editable = false;
                }
            }

            repeater(TimeSlots)
            {
                field("Capacity Date"; Rec."Capacity Date")
                {
                    ApplicationArea = All;
                    Editable = false;
                }

                field("Weekday Name"; Rec."Weekday Name")
                {
                    ApplicationArea = All;
                    Caption = 'Weekday';
                    Editable = false;
                }

                field("Entry Type"; Rec."Entry Type")
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        UpdateWorkingTime();
                    end;
                }

                field("Start Time"; Rec."Start Time")
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        UpdateWorkingTime();
                    end;
                }

                field("End Time"; Rec."End Time")
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        UpdateWorkingTime();
                    end;
                }

                field("Rest Minutes"; Rec."Rest Minutes")
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        UpdateWorkingTime();
                    end;
                }

                field("Working Hours"; Rec."Working Hours")
                {
                    ApplicationArea = All;
                    Editable = false;
                }

                field("Capacity Hours"; Rec."Capacity Hours")
                {
                    ApplicationArea = All;
                    Editable = false;
                }

                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }

                field(Manual; Rec.Manual)
                {
                    ApplicationArea = All;
                    Editable = false;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(AddMondayEntry)
            {
                ApplicationArea = All;
                Caption = 'Add Monday';
                Image = New;

                trigger OnAction()
                begin
                    AddEntryForDate(SelectedWeekStartDate);
                end;
            }

            action(AddTuesdayEntry)
            {
                ApplicationArea = All;
                Caption = 'Add Tuesday';
                Image = New;

                trigger OnAction()
                begin
                    AddEntryForDate(SelectedWeekStartDate + 1);
                end;
            }

            action(AddWednesdayEntry)
            {
                ApplicationArea = All;
                Caption = 'Add Wednesday';
                Image = New;

                trigger OnAction()
                begin
                    AddEntryForDate(SelectedWeekStartDate + 2);
                end;
            }

            action(AddThursdayEntry)
            {
                ApplicationArea = All;
                Caption = 'Add Thursday';
                Image = New;

                trigger OnAction()
                begin
                    AddEntryForDate(SelectedWeekStartDate + 3);
                end;
            }

            action(AddFridayEntry)
            {
                ApplicationArea = All;
                Caption = 'Add Friday';
                Image = New;

                trigger OnAction()
                begin
                    AddEntryForDate(SelectedWeekStartDate + 4);
                end;
            }

            action(AddSaturdayEntry)
            {
                ApplicationArea = All;
                Caption = 'Add Saturday';
                Image = New;

                trigger OnAction()
                begin
                    AddEntryForDate(SelectedWeekStartDate + 5);
                end;
            }

            action(AddSundayEntry)
            {
                ApplicationArea = All;
                Caption = 'Add Sunday';
                Image = New;

                trigger OnAction()
                begin
                    AddEntryForDate(SelectedWeekStartDate + 6);
                end;
            }

            action(DeleteEntry)
            {
                ApplicationArea = All;
                Caption = 'Delete Entry';
                Image = Delete;
                ToolTip = 'Delete the complete capacity entry belonging to the selected time slot.';

                trigger OnAction()
                begin
                    DeleteCapacityEntry();
                end;
            }
        }

        area(Promoted)
        {
            actionref(AddMondayEntryPromoted; AddMondayEntry)
            {
            }

            actionref(AddTuesdayEntryPromoted; AddTuesdayEntry)
            {
            }

            actionref(AddWednesdayEntryPromoted; AddWednesdayEntry)
            {
            }

            actionref(AddThursdayEntryPromoted; AddThursdayEntry)
            {
            }

            actionref(AddFridayEntryPromoted; AddFridayEntry)
            {
            }

            actionref(DeleteEntryPromoted; DeleteEntry)
            {
            }
        }
    }

    trigger OnModifyRecord(): Boolean
    begin
        SaveTimeSlotRow();
        exit(true);
    end;

    var
        SelectedResourceNo: Code[20];
        SelectedWeekStartDate: Date;
        SelectedWeekEndDate: Date;

        DeleteCapacityEntryQst:
            Label 'Do you want to delete the complete capacity entry for %1?';

        StartAndEndTimeRequiredErr:
            Label 'Start Time and End Time must be entered.';

        EndBeforeStartErr:
            Label 'End Time must be after Start Time.';

    procedure SetWeek(
        ResourceNo: Code[20];
        WeekStartDate: Date)
    begin
        SelectedResourceNo := ResourceNo;
        SelectedWeekStartDate := WeekStartDate;
        SelectedWeekEndDate := WeekStartDate + 6;

        BuildWeekLines();
    end;

    local procedure AddEntryForDate(CapacityDate: Date)
    var
        NextEntryNo: Integer;
    begin
        if (SelectedResourceNo = '') or
           (CapacityDate = 0D)
        then
            exit;

        NextEntryNo := GetNextBufferEntryNo();

        Rec.Init();
        Rec."Entry No." := NextEntryNo;
        Rec."Day No." := Date2DWY(CapacityDate, 1);
        Rec."Slot Line No." := NextEntryNo;
        Rec."Resource No." := SelectedResourceNo;
        Rec."Capacity Date" := CapacityDate;
        Rec."Weekday Name" := GetWeekdayName(CapacityDate);
        Rec."Entry Type" := Rec."Entry Type"::Normal;
        Rec.Manual := true;
        Rec.Insert();

        CurrPage.Update(false);
    end;

    local procedure GetNextBufferEntryNo(): Integer
    var
        WeekCapacitySlot: Record "Opti Week Capacity Slot" temporary;
    begin
        WeekCapacitySlot.Copy(Rec, true);
        WeekCapacitySlot.Reset();
        WeekCapacitySlot.SetRange("Day No.", rec."Day No.");
        WeekCapacitySlot.SetCurrentKey("Entry No.");

        if WeekCapacitySlot.FindLast() then
            exit(WeekCapacitySlot."Entry No." + 1);

        exit(1);
    end;

    local procedure UpdateWorkingTime()
    var
        GrossDuration: Duration;
    begin
        Rec."Working Minutes" := 0;
        Rec."Working Hours" := 0;
        Rec."Capacity Hours" := 0;

        if (Rec."Start Time" = 0T) or
           (Rec."End Time" = 0T)
        then
            exit;

        if Rec."End Time" <= Rec."Start Time" then
            Error(EndBeforeStartErr);

        GrossDuration :=
            CreateDateTime(
                Rec."Capacity Date",
                Rec."End Time") -
            CreateDateTime(
                Rec."Capacity Date",
                Rec."Start Time");

        Rec."Working Minutes" :=
            Round(GrossDuration / 60000, 1, '=') -
            Rec."Rest Minutes";

        if Rec."Working Minutes" < 0 then
            Rec."Working Minutes" := 0;

        Rec."Working Hours" :=
            Rec."Working Minutes" / 60;

        Rec."Capacity Hours" :=
            GetSlotCapacityHours(
                Rec."Entry Type",
                Rec."Working Hours");
    end;

    local procedure SaveTimeSlotRow()
    var
        CapacityEntry: Record "Opti Capacity Entry";
        DayTimeSlotHeader: Record "Opti Day Time Slots Header";
        DayTimeSlotLine: Record "Opti Day TimeSlot Line";
        TimeSlot: Record "Opti Time Slot";
        TimeSlotId: Integer;
        DayTimeSlotHeaderId: Integer;
        CapacityEntryLineNo: Integer;
    begin

        if (Rec."Start Time" = 0T) or
           (Rec."End Time" = 0T)
        then
            Error(StartAndEndTimeRequiredErr);

        UpdateWorkingTime();

        TimeSlotId :=
            GetOrCreateTimeSlot(
                Rec."Start Time",
                Rec."End Time",
                Rec."Rest Minutes");

        /*
        Existing physical capacity entry:
        update the related time-slot line.
        */
        if Rec."Capacity Entry Line No." <> 0 then begin
            if not CapacityEntry.Get(
                Rec."Resource No.",
                Rec."Capacity Date",
                Rec."Capacity Entry Line No.")
            then
                exit;

            CapacityEntry."Entry Type" := Rec."Entry Type";
            CapacityEntry.Description := Rec.Description;
            CapacityEntry."Capacity Hours" := Rec."Capacity Hours";
            CapacityEntry.Manual := true;
            CapacityEntry.Modify(true);

            DayTimeSlotLine.Reset();
            DayTimeSlotLine.SetRange(
                "Day Time Slot Header ID",
                CapacityEntry."Day Time Slot Header ID");

            if DayTimeSlotLine.FindFirst() then begin
                DayTimeSlotLine."Time Slot ID" := TimeSlotId;
                DayTimeSlotLine.Modify(true);

                Rec."Slot Line No." := DayTimeSlotLine."Day Time Slot Line No.";
            end;

            Rec."Time Slot ID" := TimeSlotId;
            exit;
        end;

        /*
        New physical capacity entry:
        create a header containing this single time-slot line.
        */
        DayTimeSlotHeader.Init();
        DayTimeSlotHeader.Description := Rec.Description;
        DayTimeSlotHeader.Insert(true);

        DayTimeSlotHeaderId :=
            DayTimeSlotHeader."Day Time Slot Header ID";

        DayTimeSlotLine.Init();
        DayTimeSlotLine."Day Time Slot Header ID" :=
            DayTimeSlotHeaderId;
        DayTimeSlotLine."Day Time Slot Line No." := 10000;
        DayTimeSlotLine."Time Slot ID" := TimeSlotId;
        DayTimeSlotLine.Insert(true);

        CapacityEntryLineNo :=
            GetNextCapacityEntryLineNo(
                Rec."Resource No.",
                Rec."Capacity Date");

        CapacityEntry.Init();
        CapacityEntry."Resource No." := Rec."Resource No.";
        CapacityEntry."Capacity Date" := Rec."Capacity Date";
        CapacityEntry."Line No." := CapacityEntryLineNo;
        CapacityEntry."Entry Type" := Rec."Entry Type";
        CapacityEntry."Day Time Slot Header ID" :=
            DayTimeSlotHeaderId;
        CapacityEntry.Description := Rec.Description;
        CapacityEntry."Capacity Hours" := Rec."Capacity Hours";
        CapacityEntry.Manual := true;
        CapacityEntry.Insert(true);

        Rec."Capacity Entry Line No." := CapacityEntryLineNo;
        Rec."Slot Line No." := DayTimeSlotLine."Day Time Slot Line No.";
        Rec."Time Slot ID" := TimeSlotId;
    end;

    local procedure GetOrCreateTimeSlot(
        StartTime: Time;
        EndTime: Time;
        RestMinutes: Integer): Integer
    var
        TimeSlot: Record "Opti Time Slot";
    begin
        TimeSlot.Reset();
        TimeSlot.SetRange("Start Time", StartTime);
        TimeSlot.SetRange("End Time", EndTime);
        TimeSlot.SetRange("Rest Minutes", RestMinutes);

        if TimeSlot.FindFirst() then
            exit(TimeSlot."Time Slot ID");

        TimeSlot.Init();
        TimeSlot.Validate("Start Time", StartTime);
        TimeSlot.Validate("End Time", EndTime);
        TimeSlot.Validate("Rest Minutes", RestMinutes);
        TimeSlot.Insert(true);

        exit(TimeSlot."Time Slot ID");
    end;

    local procedure GetNextCapacityEntryLineNo(
        ResourceNo: Code[20];
        CapacityDate: Date): Integer
    var
        CapacityEntry: Record "Opti Capacity Entry";
    begin
        CapacityEntry.Reset();
        CapacityEntry.SetRange(
            "Resource No.",
            ResourceNo);
        CapacityEntry.SetRange(
            "Capacity Date",
            CapacityDate);

        if CapacityEntry.FindLast() then
            exit(CapacityEntry."Line No." + 10000);

        exit(10000);
    end;

    local procedure BuildWeekLines()
    var
        CapacityEntry: Record "Opti Capacity Entry";
        DayTimeSlotLine: Record "Opti Day TimeSlot Line";
        TimeSlot: Record "Opti Time Slot";
        EntryNo: Integer;
    begin
        Rec.Reset();
        Rec.DeleteAll();

        if (SelectedResourceNo = '') or
           (SelectedWeekStartDate = 0D)
        then
            exit;

        CapacityEntry.Reset();
        CapacityEntry.SetCurrentKey(
            "Resource No.",
            "Capacity Date");

        CapacityEntry.SetRange(
            "Resource No.",
            SelectedResourceNo);

        CapacityEntry.SetRange(
            "Capacity Date",
            SelectedWeekStartDate,
            SelectedWeekEndDate);

        if CapacityEntry.FindSet() then
            repeat
                DayTimeSlotLine.Reset();
                DayTimeSlotLine.SetRange(
                    "Day Time Slot Header ID",
                    CapacityEntry."Day Time Slot Header ID");

                if DayTimeSlotLine.FindSet() then
                    repeat
                        if TimeSlot.Get(
                            DayTimeSlotLine."Time Slot ID")
                        then begin
                            EntryNo += 1;

                            InsertBufferLine(
                                EntryNo,
                                CapacityEntry,
                                DayTimeSlotLine,
                                TimeSlot);
                        end;
                    until DayTimeSlotLine.Next() = 0;
            until CapacityEntry.Next() = 0;

        Rec.Reset();
        Rec.SetCurrentKey(
            "Capacity Date",
            "Start Time",
            "Entry No.");

        if Rec.FindFirst() then;

        CurrPage.Update(false);
    end;

    local procedure InsertBufferLine(
        EntryNo: Integer;
        CapacityEntry: Record "Opti Capacity Entry";
        DayTimeSlotLine: Record "Opti Day TimeSlot Line";
        TimeSlot: Record "Opti Time Slot")
    begin
        Rec.Init();

        Rec."Entry No." := EntryNo;

        Rec."Day No." :=
            Date2DWY(
                CapacityEntry."Capacity Date",
                1);

        Rec."Slot Line No." := EntryNo;


        Rec."Resource No." :=
            CapacityEntry."Resource No.";

        Rec."Capacity Date" :=
            CapacityEntry."Capacity Date";

        Rec."Weekday Name" :=
            GetWeekdayName(
                CapacityEntry."Capacity Date");

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

        Rec."Capacity Hours" :=
            GetSlotCapacityHours(
                CapacityEntry."Entry Type",
                TimeSlot."Working Hours");

        Rec.Description :=
            CapacityEntry.Description;

        Rec.Manual :=
            CapacityEntry.Manual;

        Rec.Insert();
    end;

    local procedure DeleteCapacityEntry()
    var
        CapacityEntry: Record "Opti Capacity Entry";
    begin
        if (Rec."Resource No." = '') or
           (Rec."Capacity Date" = 0D) or
           (Rec."Capacity Entry Line No." = 0)
        then
            exit;

        if not CapacityEntry.Get(
            Rec."Resource No.",
            Rec."Capacity Date",
            Rec."Capacity Entry Line No.")
        then
            exit;

        if not Confirm(
            DeleteCapacityEntryQst,
            false,
            CapacityEntry."Capacity Date")
        then
            exit;

        CapacityEntry.Delete(true);

        BuildWeekLines();
    end;

    local procedure GetSlotCapacityHours(
        EntryType: Enum "Opti Capacity Entry Type";
        WorkingHours: Decimal): Decimal
    begin
        case EntryType of
            EntryType::Normal,
            EntryType::Additional:
                exit(WorkingHours);

            EntryType::Absence:
                exit(-WorkingHours);
        end;

        exit(0);
    end;

    local procedure GetWeekdayName(
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


}