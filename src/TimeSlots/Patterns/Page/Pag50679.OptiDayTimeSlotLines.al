page 50679 "Opti Day TimeSlot Lines"
{
    PageType = ListPart;
    SourceTable = "Opti Day-TimeSlot Line";
    Caption = 'Time Slots';
    ApplicationArea = All;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = true;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Line No."; Rec."Day-TimeSLot Line No.")
                {
                    ApplicationArea = All;
                    Visible = false;
                    ToolTip = 'Specifies the internal line number.';
                }
                field("Time Slot ID"; Rec."Time Slot No.")
                {
                    ApplicationArea = All;
                    Visible = false;
                    ToolTip = 'Specifies the internal time-slot ID.';
                }
                field("Start Time"; Rec."Start Time")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the start time.';
                }
                field("End Time"; Rec."End Time")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the end time.';
                }
                field("Rest Minutes"; Rec."Rest Minutes")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the rest time in minutes.';
                }
                field("Working Minutes"; Rec."Working Minutes")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the resulting working time in minutes.';
                }
                field("Working Hours"; Rec."Working Hours")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the resulting working time in hours.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Add_TimeSlot)
            {
                ApplicationArea = All;
                Caption = 'Add Time Slot';
                Image = NewLine;
                ToolTip = 'Adds a time slot to the current day pattern.';

                trigger OnAction()
                begin
                    AddTimeSlot();
                end;
            }
        }
    }

    local procedure AddTimeSlot()
    var
        DayPattern: Record "Opti Day-TimeSlots Header";
        DayPatternLine: Record "Opti Day-TimeSlot Line";
        TimeSlotInput: Page "Opti Time Slot";
        DayPatternID: Integer;
        TimeSlotID: Integer;
    begin
        DayPatternID := GetDayPatternID();

        if TimeSlotInput.RunModal() <> Action::OK then
            exit;

        TimeSlotID := TimeSlotInput.GetTimeSlotID();

        if TimeSlotID = 0 then
            Error(TimeSlotNotCreatedErr);

        DayPatternLine.LockTable();

        DayPatternLine.Init();
        DayPatternLine."Day-TimeSLots Header No." := DayPatternID;
        DayPatternLine."Day-TimeSLot Line No." :=
            DayPatternLine.GetNextLineNo(DayPatternID);
        DayPatternLine."Time Slot No." := TimeSlotID;
        DayPatternLine.Insert(true);

        DayPattern.Get(DayPatternID);
        DayPattern.RecalculatePattern();
        CurrPage.Update(false);
    end;

    local procedure GetDayPatternID(): Integer
    var
        DayPatternID: Integer;
        CurrentFilterGroup: Integer;
    begin
        CurrentFilterGroup := Rec.FilterGroup();

        Rec.FilterGroup(4);

        if Rec.GetFilter("Day-TimeSLots Header No.") = '' then begin
            Rec.FilterGroup(CurrentFilterGroup);
            Error(DayPatternNotSelectedErr);
        end;

        DayPatternID := Rec.GetRangeMin("Day-TimeSLots Header No.");

        Rec.FilterGroup(CurrentFilterGroup);

        if DayPatternID = 0 then
            Error(DayPatternNotSelectedErr);

        exit(DayPatternID);
    end;



    var
        DayPatternNotSelectedErr:
            Label 'A day pattern must be created before a time slot can be added.';

        TimeSlotNotCreatedErr:
            Label 'The time slot could not be found or created.';
}