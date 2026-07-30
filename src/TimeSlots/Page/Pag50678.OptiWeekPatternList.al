page 50678 "Opti Week Pattern List"
{
    PageType = List;
    SourceTable = "Opti Week Pattern Header";
    Caption = 'Week Patterns Line';
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

            action(CreateResourceCapacity)
            {
                ApplicationArea = All;
                Caption = 'Create Resource Capacity';
                Image = CalculateCalendar;
                ToolTip = 'Create capacity dates and normal capacity entries for the selected resources and date range.';

                trigger OnAction()
                begin
                    Report.RunModal(
                        Report::"Opti Create Resource Capacity",
                        true,
                        false);
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
                    Caption = '50622 Time Slots';
                    Image = List;

                    trigger OnAction()
                    begin
                        Page.Run(Page::"Opti Time Slot Data");
                    end;
                }

                action(OpenDayPatternLines)
                {
                    ApplicationArea = All;
                    Caption = '50621 Day TimeSlot Lines';
                    Image = List;

                    trigger OnAction()
                    begin
                        Page.Run(Page::"Opti Day TimeSlot Line Data");
                    end;
                }
                action(WeekPatternHeader)
                {
                    ApplicationArea = All;
                    Caption = '50619 Day Time SLots Header';
                    Image = List;

                    trigger OnAction()
                    begin
                        Page.Run(Page::"Opti Day Time Slots Hdr Data");
                    end;
                }
                action(OpenDayPatterns)
                {
                    ApplicationArea = All;
                    Caption = '50618 week Pattern Line';
                    Image = List;

                    trigger OnAction()
                    begin
                        Page.Run(Page::"Opti Week Pattern Line Data");
                    end;
                }

                action(OpenWeekPattern)
                {
                    ApplicationArea = All;
                    Caption = '50617 Week Pattern Header';
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
                action(capacityEntry)
                {
                    ApplicationArea = All;
                    Caption = '50627 Capacity Entry';
                    Image = List;

                    trigger OnAction()
                    begin
                        Page.Run(Page::"Opti Capacity Entry");
                    end;
                }
                action(ResourceCapacityWeek)
                {
                    ApplicationArea = All;
                    Caption = '50626 Resource Capacity Week';
                    Image = List;

                    trigger OnAction()
                    var
                        cc: page "Opti Resource Capacity Week";
                    begin
                        cc.Run();
                    end;
                }
                action(EffectiveWeekPatternLine)
                {
                    ApplicationArea = All;
                    Caption = '50630 Effective Week Pattern Line';
                    Image = List;

                    trigger OnAction()
                    begin
                        Page.Run(Page::"Opti Eff WeekPattern Line Data");
                    end;
                }
                action(EffectiveWeekPattern)
                {
                    ApplicationArea = All;
                    Caption = '50629 Effective Week Pattern';
                    Image = List;

                    trigger OnAction()
                    begin
                        Page.Run(Page::"Opti Effctv WeekPattern Data");
                    end;
                }

                action(DeleteAllPatternData)
                {
                    ApplicationArea = All;
                    Caption = 'Delete All Pattern Data';
                    ToolTip = 'Deletes all week patterns, day patterns, time slots, and their related lines.';
                    Image = Delete;

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
        }

        area(Promoted)
        {
            actionref(CreateResourceCapacityPromoted; CreateResourceCapacity)
            {
            }
        }
    }
}