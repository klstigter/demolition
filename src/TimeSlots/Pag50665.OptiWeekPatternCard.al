page 50665 "Opti Week Pattern Card"
{
    PageType = Card;
    SourceTable = "Opti Week Pattern";
    Caption = 'Week Pattern';
    ApplicationArea = All;
    UsageCategory = None;


    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field("Capacity Pattern ID"; Rec."Week Pattern ID")
                {
                    ToolTip = 'Specifies the internal ID of the capacity pattern.';
                }
                field(Description; Rec.Description)
                {
                    ToolTip = 'Specifies a description of the capacity pattern.';
                }

                group(Capacity)
                {
                    showcaption = false;

                    field("No. of Time Slots"; Rec."No. of Time Slots")
                    {
                        ToolTip = 'Specifies the number of time slots included in the capacity pattern.';
                    }
                    field("Total Hours"; Rec."Total Hours")
                    {
                        ToolTip = 'Specifies the total number of working hours in the weekly capacity pattern.';
                    }
                    field("Total Minutes"; Rec."Total Minutes")
                    {
                        ToolTip = 'Specifies the total number of working minutes in the weekly capacity pattern.';
                    }

                }
            }
            part(DailyPatterns; "Opti Week Pattern Lines")
            {
                ApplicationArea = All;
                Caption = 'Daily Patterns';

                SubPageLink = "Capacity Pattern ID" = field("Week Pattern ID");
                UpdatePropagation = Both;
            }
            group(Technical)
            {
                Caption = 'Technical';

                field("Pattern Hash"; Rec."Pattern Hash")
                {
                    ToolTip = 'Specifies the SHA-256 hash of the complete weekly capacity pattern.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {

            action(Edit_Week_Pattern)
            {
                ApplicationArea = All;
                Caption = 'Edit Week Pattern';
                Image = EditLines;
                ToolTip = 'Opens the weekly time-slot pattern for entry or editing.';

                trigger OnAction()
                begin
                    OpenWeekPattern();
                end;
            }
        }

        area(Promoted)
        {
            actionref(Edit_Week_Pattern_Promoted; Edit_Week_Pattern)
            {
            }
        }
    }

    local procedure OpenWeekPattern()
    var
        WeekPatternInput: Page "Opti Week Pattern Dialog";
        TempWeekPatternBuffer: Record "Opti Week Pattern Buffer" temporary;
    begin
        CurrPage.SaveRecord();

        LoadExistingWeekPattern(TempWeekPatternBuffer);

        WeekPatternInput.SetCapacityPatternID(
            Rec."Week Pattern ID");

        WeekPatternInput.LoadBuffer(
            TempWeekPatternBuffer);

        if WeekPatternInput.RunModal() <> Action::OK then
            exit;

        WeekPatternInput.GetBuffer(
            TempWeekPatternBuffer);

        Rec.ApplyWeekPattern(
            TempWeekPatternBuffer);

        CurrPage.Update(false);
    end;

    local procedure LoadExistingWeekPattern(
    var TempWeekPatternBuffer: Record "Opti Week Pattern Buffer" temporary)
    var
        CapacityPatternDay: Record "Opti Week Pattern Line";
        DayPatternLine: Record "Opti Day Pattern Line";
        TimeSlot: Record "Opti Time Slot";
        EntryNo: Integer;
    begin
        TempWeekPatternBuffer.Reset();
        TempWeekPatternBuffer.DeleteAll();

        CapacityPatternDay.SetRange(
            "Capacity Pattern ID",
            Rec."Week Pattern ID");

        if CapacityPatternDay.FindSet() then
            repeat
                DayPatternLine.Reset();
                DayPatternLine.SetRange(
                    "Day Pattern ID",
                    CapacityPatternDay."Day Pattern ID");

                if DayPatternLine.FindSet() then
                    repeat
                        TimeSlot.Get(
                            DayPatternLine."Time Slot ID");

                        EntryNo += 10000;

                        TempWeekPatternBuffer.Init();
                        TempWeekPatternBuffer."Entry No." := EntryNo;

                        TempWeekPatternBuffer.Validate(
                            "Weekday No.",
                            CapacityPatternDay."Weekday No.");

                        TempWeekPatternBuffer.Validate(
                            "Start Time",
                            TimeSlot."Start Time");

                        TempWeekPatternBuffer.Validate(
                            "End Time",
                            TimeSlot."End Time");

                        TempWeekPatternBuffer.Validate(
                            "Rest Minutes",
                            TimeSlot."Rest Minutes");

                        TempWeekPatternBuffer.Insert();
                    until DayPatternLine.Next() = 0;
            until CapacityPatternDay.Next() = 0;
    end;
}