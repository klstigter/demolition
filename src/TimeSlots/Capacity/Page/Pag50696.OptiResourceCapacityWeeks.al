page 50696 "Opti Resource Capacity Weeks"
{
    Caption = 'Resource Capacity by Week';
    PageType = List;
    SourceTable = "Opti Resource Capacity Week";
    ApplicationArea = All;
    UsageCategory = Documents;

    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Weeks)
            {
                field("Resource No."; Rec."Resource No.")
                {
                    ApplicationArea = All;
                }

                field("Week No."; Rec."Week No.")
                {
                    ApplicationArea = All;
                }

                field("Week Year"; Rec."Week Year")
                {
                    ApplicationArea = All;
                }

                field("Week Start Date"; Rec."Week Start Date")
                {
                    ApplicationArea = All;
                }

                field("Week End Date"; Rec."Week End Date")
                {
                    ApplicationArea = All;
                }

                field("Effective Pattern Hash"; Rec."Capacity Pattern Hash")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the effective SHA-256 hash of the current resource week capacity composition.';
                }

                field("Effective Week Pattern ID"; Rec."Capacity Week Pattern ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the persistent effective week pattern linked to this resource week.';
                }
                field("Monday Capacity"; Rec."Monday Capacity")
                {
                    ApplicationArea = All;
                }

                field("Tuesday Capacity"; Rec."Tuesday Capacity")
                {
                    ApplicationArea = All;
                }

                field("Wednesday Capacity"; Rec."Wednesday Capacity")
                {
                    ApplicationArea = All;
                }

                field("Thursday Capacity"; Rec."Thursday Capacity")
                {
                    ApplicationArea = All;
                }

                field("Friday Capacity"; Rec."Friday Capacity")
                {
                    ApplicationArea = All;
                }

                field("Saturday Capacity"; Rec."Saturday Capacity")
                {
                    ApplicationArea = All;
                }

                field("Sunday Capacity"; Rec."Sunday Capacity")
                {
                    ApplicationArea = All;
                }

            }
            part(CapacityDialogs; "Opti Week Capacity Dialogs")
            {
                ApplicationArea = All;
                SubPageLink = "Resource No." = field("Resource No."),
                                 "Week Start Date" = field("Week Start Date");
            }

        }
    }

    actions
    {
        area(Processing)
        {
            action(OpenWeekPattern)
            {
                ApplicationArea = All;
                Caption = 'Week Patterns';
                Image = Calendar;
                ToolTip = 'Open the week pattern list.';

                trigger OnAction()
                begin
                    Page.Run(Page::"Opti Week Pattern List");
                end;
            }

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
            // action(EditWeek)
            // {
            //     //action(EditWeek)

            //     ApplicationArea = All;
            //     Caption = 'Edit Week';
            //     Image = EditLines;
            //     ToolTip = 'Edit the capacity time slots for the selected resource and week.';

            //     trigger OnAction()
            //     var
            //         ResourceWeekEdit: Page "Opti Resource Week Edit";
            //     begin
            //         Rec.TestField("Resource No.");
            //         Rec.TestField("Week Start Date");

            //         ResourceWeekEdit.SetWeek(
            //             Rec."Resource No.",
            //             Rec."Week Start Date");
            //         ResourceWeekEdit.LookupMode := true;
            //         ResourceWeekEdit.RunModal();

            //         CurrPage.Update(false);

            //         CurrPage.CapacitySlots.Page.SetWeek(
            //             Rec."Resource No.",
            //             Rec."Week Start Date");
            //     end;
            // }


            action(ExportToExcel)
            {
                ApplicationArea = All;
                Caption = 'Export to Excel';
                Image = Export;
                ToolTip = 'Export the resource capacity data to an Excel file.';

                trigger OnAction()
                begin
                    Report.RunModal(
                        Report::"Opti Res Capacity To Excel", true, false);
                end;
            }

        }
        area(Navigation)
        {

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

            action(OpenWeekPattern2)
            {
                ApplicationArea = All;
                Caption = '50617 Week Pattern Header';
                Image = List;

                trigger OnAction()
                begin
                    Page.Run(Page::"Opti Week Pattern Data");
                end;
            }

            // action(OpenTimeSlotBuffer)
            // {
            //     ApplicationArea = All;
            //     Caption = 'Time Slot Buffer';
            //     Image = List;
            //     visible = false;

            //     trigger OnAction()
            //     begin
            //         Page.Run(Page::"Opti Time Slot Buffer Data");
            //     end;
            // }
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
            // action(capacityEntry)
            // {
            //     ApplicationArea = All;
            //     Caption = '50627 Capacity Entry';
            //     Image = List;

            //     trigger OnAction()
            //     begin
            //         Page.Run(Page::"Opti Capacity Entry");
            //     end;
            // }
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
        area(Promoted)
        {
            actionref(OpenWeekPatternPromoted; OpenWeekPattern)
            {
            }
            actionref(CreateResourceCapacityPromoted; CreateResourceCapacity)
            {
            }
            // actionref(EditWeekPromoted; EditWeek)
            // {
            // }
            actionref(ExportToExcelPromoted; ExportToExcel)
            {
            }
        }
    }
    trigger OnAfterGetCurrRecord()
    begin
        currpage.CapacityDialogs.page.LoadData(Rec."Resource No.", Rec."Week Start Date");
    end;

}