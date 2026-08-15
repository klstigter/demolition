page 50678 "Opti Week Pattern List"
{
    PageType = List;
    SourceTable = "Opti Week Pattern Header";
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
                field("Capacity Pattern ID"; Rec."Week Pattern Code")
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
        area(Promoted)
        {
            actionref(CreateResourceCapacityPromoted; CreateResourceCapacity)
            {
            }
        }
    }
}