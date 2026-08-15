page 50665 "Opti Week Pattern Card"
{
    PageType = Card;
    SourceTable = "Opti Week Pattern Header";
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

                field("Week Pattern ID"; Rec."Week Pattern Code")
                {
                    ToolTip = 'Specifies the internal ID of the week pattern.';
                }
                field(Description; Rec.Description)
                {
                    ToolTip = 'Specifies a description of the week pattern.';
                }

                group(Statistics)
                {
                    showcaption = false;

                    field("No. of Time Slots"; Rec."No. of Time Slots")
                    {
                        ToolTip = 'Specifies the number of time slots included in the week pattern.';
                    }
                    field("Total Hours"; Rec."Total Hours")
                    {
                        ToolTip = 'Specifies the total number of working hours in the weekly week pattern.';
                    }
                    field("Total Minutes"; Rec."Total Minutes")
                    {
                        ToolTip = 'Specifies the total number of working minutes in the weekly week pattern.';
                    }

                }
            }
            part(DayPatternDialog; "Opti Week Pattern Dialog Sub")
            {
                ApplicationArea = All;
                Caption = 'Daily';

                //SubPageLink = "Week Pattern Code" = field("Week Pattern Code");
                UpdatePropagation = Both;
            }

            part(DailyPatterns; "Opti Week Pattern Lines")
            {
                ApplicationArea = All;
                Caption = 'Pattern';

                SubPageLink = "Week Pattern Code" = field("Week Pattern Code");
                UpdatePropagation = Both;
            }
            group(Technical)
            {
                Caption = 'Technical';

                field("Pattern Hash"; Rec."Week Hash")
                {
                    ToolTip = 'Specifies the SHA-256 hash of the complete weekly week pattern.';
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
                Caption = 'Edit Pattern';
                Image = EditLines;
                ToolTip = 'Opens the weekly time-slot pattern for entry or editing.';

                trigger OnAction()
                begin
                    RunDialogAndApply();
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

    trigger OnafterGetCurrRecord()
    var
        TempWeekPatternBuffer: Record "Opti Week Pattern Dialog" temporary;
    begin
        FillTempWeekPatternBuffer(TempWeekPatternBuffer);
        CurrPage.DayPatternDialog.page.LoadDataSet(TempWeekPatternBuffer);
    end;

    local procedure RunDialogAndApply()
    var
        WeekPatternDialog: Page "Opti Week Pattern Dialog";
        TempWeekPatternBuffer: Record "Opti Week Pattern Dialog" temporary;
    begin

        FillTempWeekPatternBuffer(TempWeekPatternBuffer);
        WeekPatternDialog.SetWeekPatternID(Rec."Week Pattern Code");
        WeekPatternDialog.LoadDataSet(TempWeekPatternBuffer);
        if WeekPatternDialog.RunModal() <> Action::OK then
            exit;
        WeekPatternDialog.GetBuffer(TempWeekPatternBuffer);

        Rec.ApplyWeekPattern(TempWeekPatternBuffer);
        CurrPage.Update(false);
    end;

    local procedure FillTempWeekPatternBuffer(var TempWeekPatternBuffer: Record "Opti Week Pattern Dialog" temporary)
    var
        WeekPatternLine: Record "Opti Week Pattern Line";
        Day_TimeSlotLine: Record "Opti Day-TimeSlot Line";
        TimeSlot: Record "Opti Time Slot";
        EntryNo: Integer;
    begin
        TempWeekPatternBuffer.Reset();
        TempWeekPatternBuffer.DeleteAll();

        WeekPatternLine.SetRange("Week Pattern Code", Rec."Week Pattern Code");
        if WeekPatternLine.FindSet() then
            repeat
                Day_TimeSlotLine.Reset();
                Day_TimeSlotLine.SetRange("Day Time SLot Header ID", WeekPatternLine."Day Pattern ID");
                if Day_TimeSlotLine.FindSet() then
                    repeat
                        TimeSlot.Get(Day_TimeSlotLine."Time Slot ID");
                        EntryNo += 10000;
                        TempWeekPatternBuffer.Init();
                        TempWeekPatternBuffer."Entry No." := EntryNo;
                        TempWeekPatternBuffer.Validate("Weekday No.", WeekPatternLine."Weekday No.");
                        TempWeekPatternBuffer.Validate("Start Time", TimeSlot."Start Time");
                        TempWeekPatternBuffer.Validate("End Time", TimeSlot."End Time");
                        TempWeekPatternBuffer.Validate("Idle Time", TimeSlot."Idle Time");
                        TempWeekPatternBuffer.Insert();
                    until Day_TimeSlotLine.Next() = 0;
            until WeekPatternLine.Next() = 0;
    end;
}