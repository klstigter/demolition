page 50701 "Opti Week Pattern Line Data"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "Opti Week Pattern Line";

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {

                field("Week Pattern ID"; Rec."Week Pattern Code")
                {
                    ToolTip = 'Specifies the value of the Week Pattern ID field.', Comment = '%';
                }
                field("Weekday No."; Rec."Weekday No.")
                {
                    ToolTip = 'Specifies the internal weekday number.';
                }
                field("Day Pattern ID"; Rec."Day Pattern ID")
                {
                    ToolTip = 'Specifies the internal day-pattern ID.';
                }
                field("Weekday Name"; Rec."Weekday Name")
                {
                    ToolTip = 'Specifies the weekday.';
                }
                field("Day Pattern Description"; Rec."Day Pattern Description")
                {
                    ToolTip = 'Specifies the daily time-slot pattern used for this weekday.';
                }
                field("Working Minutes"; Rec."Working Minutes")
                {
                    ToolTip = 'Specifies the value of the Working Minutes field.', Comment = '%';
                }
                field("Working Hours"; Rec."Working Hours")
                {
                    ToolTip = 'Specifies the total working hours for the weekday.';
                }
                field("No. of Time Slots"; Rec."No. of Time Slots")
                {
                    ToolTip = 'Specifies how many time slots are included for the weekday.';
                }
                field("Day Pattern Hash"; Rec."Day Pattern Hash")
                {
                    ToolTip = 'Specifies the technical hash of the day pattern.';
                }


            }
        }
        area(Factboxes)
        {

        }
    }

    actions
    {
        area(Processing)
        {
            action(ActionName)
            {

                trigger OnAction()
                begin

                end;
            }
        }
    }
}