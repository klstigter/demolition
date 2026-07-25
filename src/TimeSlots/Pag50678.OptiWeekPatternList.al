page 50678 "Opti Week Pattern List"
{
    PageType = List;
    SourceTable = "Opti Week Pattern";
    Caption = 'Week Patterns';
    ApplicationArea = All;
    UsageCategory = Administration;
    CardPageId = "Opti Week Pattern Card";

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Capacity Pattern ID"; Rec."Week Pattern ID")
                {
                    ToolTip = 'Specifies the internal ID of the capacity pattern.';
                }
                field(Description; Rec.Description)
                {
                    ToolTip = 'Specifies a description of the capacity pattern.';
                }
                field("Total Hours"; Rec."Total Hours")
                {
                    ToolTip = 'Specifies the total capacity in hours.';
                }
                field("No. of Time Slots"; Rec."No. of Time Slots")
                {
                    ToolTip = 'Specifies the number of time slots in the pattern.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {

            action(Open_Week_Pattern)
            {
                ApplicationArea = All;
                Caption = 'Open Week Pattern';
                Image = EditLines;
                ToolTip = 'Opens the selected week pattern.';

                trigger OnAction()
                begin
                    Rec.TestField("Week Pattern ID");
                    Page.RunModal(Page::"Opti Week Pattern Card", Rec);
                end;
            }
            action(DeleteAllPatternData)
            {
                ApplicationArea = All;
                Caption = 'Delete All Pattern Data';
                ToolTip = 'Deletes all week patterns, day patterns, time slots, and their related lines.';
                Image = DeleteAll;

                trigger OnAction()
                var
                    PatternCleanup: Codeunit "Opti Hash Times Cleanup";
                    DeleteAllPatternDataQst: Label 'Do you want to delete all Opti week patterns, day patterns, and time slots? This action cannot be undone.';
                    PatternDataDeletedMsg: Label 'All Opti pattern data has been deleted.';
                begin
                    if not Confirm(DeleteAllPatternDataQst, false) then
                        exit;

                    PatternCleanup.DeleteAllPatternData();

                    CurrPage.Update(false);

                    Message(PatternDataDeletedMsg);
                end;
            }
        }

        area(Navigation)
        {
            group(TestData)
            {
                Caption = 'Test Data';
                Image = ViewDetails;

                action(OpenTimeSlots)
                {
                    ApplicationArea = All;
                    Caption = 'Time Slots';
                    Image = List;

                    trigger OnAction()
                    begin
                        Page.Run(Page::"Opti Time Slot Data");
                    end;
                }

                action(OpenDayPatternLines)
                {
                    ApplicationArea = All;
                    Caption = 'Day Pattern Lines';
                    Image = List;

                    trigger OnAction()
                    begin
                        Page.Run(Page::"Opti Day Pattern Line Data");
                    end;
                }

                action(OpenDayPatterns)
                {
                    ApplicationArea = All;
                    Caption = 'Day Patterns';
                    Image = List;

                    trigger OnAction()
                    begin
                        Page.Run(Page::"Opti Day Pattern Data");
                    end;
                }

                action(OpenWeekPatternLines)
                {
                    ApplicationArea = All;
                    Caption = 'Week Pattern Lines';
                    Image = List;

                    trigger OnAction()
                    begin
                        Page.Run(Page::"Opti Week Pattern Data");
                    end;
                }

                action(OpenTimeSlotBuffer)
                {
                    ApplicationArea = All;
                    Caption = 'Time Slot Buffer';
                    Image = List;
                    visible = false;

                    trigger OnAction()
                    begin
                        Page.Run(Page::"Opti Time Slot Buffer Data");
                    end;
                }
                action(OpenWeekPatternBuffer)
                {
                    ApplicationArea = All;
                    Caption = 'Week Pattern Buffer';
                    Image = List;
                    visible = false;

                    trigger OnAction()
                    begin
                        Page.Run(Page::"Opti Week Pattern Buffer Data");
                    end;
                }

            }
        }

        area(Promoted)
        {
            actionref(AddTimeSlotPromoted; AddTimeSlot)
            {
            }
            actionref(Open_Week_Pattern_Promoted; Open_Week_Pattern)
            {
            }
        }
    }
}