page 50698 "Opti Resource Week Edit"
{
    PageType = Worksheet;
    SourceTable = "Opti Week Capacity Dialog";
    DelayedInsert = true;
    SourceTableTemporary = true;
    ApplicationArea = All;
    UsageCategory = None;

    InsertAllowed = false;
    ModifyAllowed = true;
    DeleteAllowed = false;
    caption = 'Edit Resource Capacity Week';
    DataCaptionExpression = this.GetPageCaption();


    layout
    {
        area(Content)
        {
            group(Week)
            {
                Caption = 'Resource and Week';
                showCaption = false;

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

                field("Rest Minutes"; Rec."Idle Time")
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
                field(DayTimeSlotLineNo; Rec.DayTimeSlotLineNo)
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(DayTimeSlotHeaderID; Rec."Day-TimeSlots Header No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Time Slot ID"; Rec."Time Slot No.")
                {
                    ApplicationArea = All;
                    Editable = false;
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
                    rec.AddEntryForDate(SelectedWeekStartDate, selectedResourceNo);
                end;
            }

            action(AddTuesdayEntry)
            {
                ApplicationArea = All;
                Caption = 'Add Tuesday';
                Image = New;

                trigger OnAction()
                begin
                    rec.AddEntryForDate(SelectedWeekStartDate + 1, selectedResourceNo);
                end;
            }

            action(AddWednesdayEntry)
            {
                ApplicationArea = All;
                Caption = 'Add Wednesday';
                Image = New;

                trigger OnAction()
                begin
                    rec.AddEntryForDate(SelectedWeekStartDate + 2, selectedResourceNo);
                end;
            }

            action(AddThursdayEntry)
            {
                ApplicationArea = All;
                Caption = 'Add Thursday';
                Image = New;

                trigger OnAction()
                begin
                    rec.AddEntryForDate(SelectedWeekStartDate + 3, selectedResourceNo);
                end;
            }

            action(AddFridayEntry)
            {
                ApplicationArea = All;
                Caption = 'Add Friday';
                Image = New;

                trigger OnAction()
                begin
                    rec.AddEntryForDate(SelectedWeekStartDate + 4, selectedResourceNo);
                end;
            }

            action(AddSaturdayEntry)
            {
                ApplicationArea = All;
                Caption = 'Add Saturday';
                Image = New;

                trigger OnAction()
                begin
                    rec.AddEntryForDate(SelectedWeekStartDate + 5, selectedResourceNo);
                end;
            }

            action(AddSundayEntry)
            {
                ApplicationArea = All;
                Caption = 'Add Sunday';
                Image = New;

                trigger OnAction()
                begin
                    rec.AddEntryForDate(SelectedWeekStartDate + 6, selectedResourceNo);
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

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = action::LookupOK then begin
            rec.ApplyWeekPatternDialog()
        end;
        exit(true);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        TryFindTimeSlotId();
        exit(true);
    end;

    var
        SelectedResourceNo: Code[20];
        SelectedWeekStartDate: Date;
        SelectedWeekEndDate: Date;
        DeleteCapacityEntryQst: Label 'Do you want to delete the complete capacity entry for %1?';
        StartAndEndTimeRequiredErr: Label 'Start Time and End Time must be entered.';
        EndBeforeStartErr: Label 'End Time must be after Start Time.';

    procedure SetWeek(ResourceNo: Code[20]; WeekStartDate: Date)
    var
        SlotsQry: Query "Opti Week Capacity Slots Qry";
        EntryNo: Integer;
    begin
        SelectedResourceNo := ResourceNo;
        SelectedWeekStartDate := WeekStartDate;
        SelectedWeekEndDate := WeekStartDate + 6;
        Rec.Reset();
        Rec.DeleteAll();

        SlotsQry.SetRange(ResourceNo, ResourceNo);
        SlotsQry.SetRange(WeekStartDate, WeekStartDate);

        SlotsQry.Open();
        while SlotsQry.Read() do begin
            EntryNo += 1;

            Rec.Init();
            Rec."Day No." := SlotsQry.WeekdayNo;
            Rec."Entry No." := EntryNo;
            Rec."Weekday Name" := SlotsQry.WeekdayName;
            Rec."Week No." := SlotsQry.WeekNo;
            Rec."Week Year" := SlotsQry.WeekYear;
            Rec."Capacity Date" := DWY2Date(SlotsQry.WeekdayNo, SlotsQry.WeekNo, SlotsQry.WeekYear);
            Rec."Start Time" := SlotsQry.StartTime;
            Rec."End Time" := SlotsQry.EndTime;
            Rec."Idle Time" := SlotsQry.IdleTime;
            Rec."Working Minutes" := SlotsQry.WorkingMinutes;
            Rec."Working Hours" := SlotsQry.WorkingHours;
            Rec."Resource No." := ResourceNo;
            Rec."Week Start Date" := WeekStartDate;
            rec."Time Slot No." := SlotsQry.TimeSlotNo;
            rec.DayTimeSlotLineNo := SlotsQry.DayTimeSlotLineNo;
            rec."Day-TimeSlots Header No." := SlotsQry.DayTimeSlotHeaderNo;
            rec."Capacity Hours" := slotsQry.WorkingHours;
            Rec.Insert();
        end;
        SlotsQry.Close();

        CurrPage.Update(false);
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
            CreateDateTime(Rec."Capacity Date", Rec."End Time") -
            CreateDateTime(Rec."Capacity Date", Rec."Start Time");

        Rec."Working Minutes" := Round(GrossDuration / 60000, 1, '=') - Rec."Idle Time";

        if Rec."Working Minutes" < 0 then
            Rec."Working Minutes" := 0;

        Rec."Working Hours" := Rec."Working Minutes" / 60;

    end;

    local procedure TryFindTimeSlotId()
    var
        //CapacityEntry: Record "Opti Capacity Entry";
        DayTimeSlotHeader: Record "Opti Day-TimeSlots Header";
        DayTimeSlotLine: Record "Opti Day-TimeSlot Line";
        TimeSlot: Record "Opti Time Slot";
        DayTimeSlotHeaderId: Integer;
        CapacityEntryLineNo: Integer;
    begin

        if (Rec."Start Time" = 0T) or
           (Rec."End Time" = 0T)
        then
            Error(StartAndEndTimeRequiredErr);


        rec."Time Slot No." := TimeSlot.GetTimeSlotID(Rec."Start Time", Rec."End Time", Rec."Idle Time");

        // /*
        // Existing physical capacity entry:
        // update the related time-slot line.
        // */
        // if Rec."Capacity Entry Line No." <> 0 then begin
        //     if not CapacityEntry.Get(
        //         Rec."Resource No.",
        //         Rec."Capacity Date",
        //         Rec."Capacity Entry Line No.")
        //     then
        //         exit;

        //     CapacityEntry."Entry Type" := Rec."Entry Type";
        //     CapacityEntry.Description := Rec.Description;
        //     CapacityEntry."Capacity Hours" := Rec."Capacity Hours";
        //     CapacityEntry.Manual := true;
        //     CapacityEntry."Source Week Pattern ID" := 0;
        //     Clear(CapacityEntry."Source Week Pattern Hash");
        //     CapacityEntry.Modify(true);

        //     DayTimeSlotLine.Reset();
        //     DayTimeSlotLine.SetRange(
        //         "Day Time Slot Header ID",
        //         CapacityEntry."Day Time Slot Header ID");

        //     if DayTimeSlotLine.FindFirst() then begin
        //         DayTimeSlotLine."Time Slot ID" := TimeSlotId;
        //         DayTimeSlotLine.Modify(true);
        //     end;

        //     Rec."Time Slot ID" := TimeSlotId;
        //     exit;
        // end;

        // /*
        // New physical capacity entry:
        // create a header containing this single time-slot line.
        // */
        // DayTimeSlotHeader.Init();
        // DayTimeSlotHeader.Description := Rec.Description;
        // DayTimeSlotHeader.Insert(true);

        // DayTimeSlotHeaderId :=
        //     DayTimeSlotHeader."Day Time Slot Header ID";

        // DayTimeSlotLine.Init();
        // DayTimeSlotLine."Day Time Slot Header ID" :=
        //     DayTimeSlotHeaderId;
        // DayTimeSlotLine."Day Time Slot Line No." := 0;
        // DayTimeSlotLine."Time Slot ID" := TimeSlotId;
        // DayTimeSlotLine.Insert(true);

        // CapacityEntryLineNo :=
        //     GetNextCapacityEntryLineNo(
        //         Rec."Resource No.",
        //         Rec."Capacity Date");

        // CapacityEntry.Init();
        // CapacityEntry."Resource No." := Rec."Resource No.";
        // CapacityEntry."Capacity Date" := Rec."Capacity Date";
        // CapacityEntry."Line No." := CapacityEntryLineNo;
        // CapacityEntry."Entry Type" := Rec."Entry Type";
        // CapacityEntry."Day Time Slot Header ID" :=
        //     DayTimeSlotHeaderId;
        // CapacityEntry.Description := Rec.Description;
        // CapacityEntry."Capacity Hours" := Rec."Capacity Hours";
        // CapacityEntry.Manual := true;
        // CapacityEntry."Source Week Pattern ID" := 0;
        // Clear(CapacityEntry."Source Week Pattern Hash");
        // CapacityEntry.Insert(true);

        // Rec."Capacity Entry Line No." := CapacityEntryLineNo;
        // Rec."Time Slot ID" := TimeSlotId;
    end;


    local procedure GetNextCapacityEntryLineNo(
        ResourceNo: Code[20];
        CapacityDate: Date): Integer
    var
    //CapacityEntry: Record "Opti Capacity Entry";
    begin
        //CapacityEntry.Reset();
        //CapacityEntry.SetRange(
        //    "Resource No.",
        //    ResourceNo);
        //CapacityEntry.SetRange(
        //    "Capacity Date",
        //    CapacityDate);

        //if CapacityEntry.FindLast() then
        //    exit(CapacityEntry."Line No." + 10000);

        //exit(10000);
    end;

    local procedure BuildWeekLines()
    var
        //CapacityEntry: Record "Opti Capacity Entry";
        DayTimeSlotLine: Record "Opti Day-TimeSlot Line";
        TimeSlot: Record "Opti Time Slot";
        EntryNo: Integer;
    begin
        // Rec.Reset();
        // Rec.DeleteAll();

        // if (SelectedResourceNo = '') or
        //    (SelectedWeekStartDate = 0D)
        // then
        //     exit;

        // CapacityEntry.Reset();
        // CapacityEntry.SetCurrentKey(
        //     "Resource No.",
        //     "Capacity Date");

        // CapacityEntry.SetRange(
        //     "Resource No.",
        //     SelectedResourceNo);

        // CapacityEntry.SetRange(
        //     "Capacity Date",
        //     SelectedWeekStartDate,
        //     SelectedWeekEndDate);

        // if CapacityEntry.FindSet() then
        //     repeat
        //         DayTimeSlotLine.Reset();
        //         DayTimeSlotLine.SetRange(
        //             "Day Time Slot Header ID",
        //             CapacityEntry."Day Time Slot Header ID");

        //         if DayTimeSlotLine.FindSet() then
        //             repeat
        //                 if TimeSlot.Get(
        //                     DayTimeSlotLine."Time Slot ID")
        //                 then begin
        //                     EntryNo += 1;

        //                     InsertBufferLine(
        //                         EntryNo,
        //                         CapacityEntry,
        //                         DayTimeSlotLine,
        //                         TimeSlot);
        //                 end;
        //             until DayTimeSlotLine.Next() = 0;
        //     until CapacityEntry.Next() = 0;

        // Rec.Reset();
        // Rec.SetCurrentKey(
        //     "Capacity Date",
        //     "Start Time",
        //     "Entry No.");

        // if Rec.FindFirst() then;

        // CurrPage.Update(false);
    end;

    local procedure InsertBufferLine(
        EntryNo: Integer;
        //CapacityEntry: Record "Opti Capacity Entry";
        DayTimeSlotLine: Record "Opti Day-TimeSlot Line";
        TimeSlot: Record "Opti Time Slot")
    begin
        Rec.Init();

        Rec."Entry No." := EntryNo;

        // Rec."Day No." :=
        //     Date2DWY(
        //         CapacityEntry."Capacity Date",
        //         1);

        // Rec."Slot Line No." := EntryNo;


        // Rec."Resource No." :=
        //     CapacityEntry."Resource No.";

        // Rec."Capacity Date" :=
        //     CapacityEntry."Capacity Date";

        // Rec."Weekday Name" :=
        //     GetWeekdayName(
        //         CapacityEntry."Capacity Date");

        // Rec."Capacity Entry Line No." :=
        //     CapacityEntry."Line No.";

        // Rec."Entry Type" :=
        //     CapacityEntry."Entry Type";

        Rec."Time Slot No." :=
            TimeSlot."Time Slot No.";

        Rec."Start Time" :=
            TimeSlot."Start Time";

        Rec."End Time" :=
            TimeSlot."End Time";

        Rec."Idle Time" :=
            TimeSlot."Idle Time";

        Rec."Working Minutes" :=
            TimeSlot."Working Minutes";

        Rec."Working Hours" :=
            TimeSlot."Working Hours";

        // Rec."Capacity Hours" :=
        //     GetSlotCapacityHours(
        //         CapacityEntry."Entry Type",
        //         TimeSlot."Working Hours");

        // Rec.Description :=
        //     CapacityEntry.Description;

        // Rec.Manual :=
        //     CapacityEntry.Manual;

        Rec.Insert();
    end;

    local procedure DeleteCapacityEntry()
    var
    //CapacityEntry: Record "Opti Capacity Entry";
    begin
        if (Rec."Resource No." = '') or
           (Rec."Capacity Date" = 0D) or
           (Rec."Capacity Entry Line No." = 0)
        then
            exit;

        // if not CapacityEntry.Get(
        //     Rec."Resource No.",
        //     Rec."Capacity Date",
        //     Rec."Capacity Entry Line No.")
        // then
        //     exit;

        // if not Confirm(
        //     DeleteCapacityEntryQst,
        //     false,
        //     CapacityEntry."Capacity Date")
        // then
        //     exit;

        // CapacityEntry.Delete(true);

        BuildWeekLines();
    end;




    Local Procedure GetPageCaption(): Text[100]
    begin
        exit('Edit ' + Format(SelectedResourceNo) + ' - Week ' + Format(date2DWY(SelectedWeekStartDate, 2)) + ' ' + Format(date2DWY(SelectedWeekStartDate, 3)));
    end;


}