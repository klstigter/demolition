page 50682 "Opti Day-TimeSlots Hdr List"
{
    PageType = List;
    SourceTable = "Opti Day-TimeSlots Header";
    Caption = 'Day Patterns';
    ApplicationArea = All;
    UsageCategory = Administration;
    CardPageId = "Opti Day-TimeSlots Hdr Card";
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(DayPatterns)
            {
                field("Day Pattern ID"; Rec."Day Time SLot Header ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the internal day pattern ID.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the description of the day pattern.';
                }
                field("No. of Time Slots"; Rec."No. of Time Slots")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of time slots.';
                }
                field("Total Working Hours"; Rec."Total Working Hours")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the total number of working hours.';
                }
                field("Pattern Hash"; Rec."Pattern Hash")
                {
                    ApplicationArea = All;
                    Visible = false;
                    ToolTip = 'Specifies the technical hash of the day pattern.';
                }
            }
        }
    }
}