page 50685 "Opti Week Pattern Lines"
{
    PageType = ListPart;
    SourceTable = "Opti Week Pattern Line";
    Caption = 'Daily Patterns';
    ApplicationArea = All;

    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Days)
            {
                field("Weekday No."; Rec."Weekday No.")
                {
                    ApplicationArea = All;
                    Visible = false;
                    ToolTip = 'Specifies the internal weekday number.';
                }
                field("Weekday Name"; Rec."Weekday Name")
                {
                    ApplicationArea = All;
                    Caption = 'Weekday';
                    ToolTip = 'Specifies the weekday.';
                }
                field("Day Pattern Description"; Rec."Day Pattern Description")
                {
                    ApplicationArea = All;
                    Caption = 'Day Pattern';
                    ToolTip = 'Specifies the daily time-slot pattern used for this weekday.';
                }
                field("Working Hours"; Rec."Working Hours")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the total working hours for the weekday.';
                }
                field("No. of Time Slots"; Rec."No. of Time Slots")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies how many time slots are included for the weekday.';
                }
                field("Day Pattern ID"; Rec."Day Pattern ID")
                {
                    ApplicationArea = All;
                    Visible = false;
                    ToolTip = 'Specifies the internal day-pattern ID.';
                }
                field("Day Pattern Hash"; Rec."Day Pattern Hash")
                {
                    ApplicationArea = All;
                    Visible = false;
                    ToolTip = 'Specifies the technical hash of the day pattern.';
                }
            }
        }
    }
}