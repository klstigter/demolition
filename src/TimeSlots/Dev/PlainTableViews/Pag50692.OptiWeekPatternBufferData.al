page 50692 "Opti Week Pattern Buffer Data"
{
    PageType = List;
    SourceTable = "Opti Week Pattern Dialog";
    Caption = 'Opti Week Pattern Buffer Data';
    ApplicationArea = All;
    UsageCategory = Administration;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                }
                field("Weekday No."; Rec."Weekday No.")
                {
                    ApplicationArea = All;
                }
                field("Weekday Name"; Rec."Weekday Name")
                {
                    ApplicationArea = All;
                }
                field("Start Time"; Rec."Start Time")
                {
                    ApplicationArea = All;
                }
                field("End Time"; Rec."End Time")
                {
                    ApplicationArea = All;
                }
                field("Rest Minutes"; Rec."Idle Time")
                {
                    ApplicationArea = All;
                }
                field("Working Minutes"; Rec."Working Minutes")
                {
                    ApplicationArea = All;
                }
                field("Working Hours"; Rec."Working Hours")
                {
                    ApplicationArea = All;
                }
                field("Time Slot ID"; Rec."Time Slot ID")
                {
                    ApplicationArea = All;
                }
                field("Time Slot Hash"; Rec."Time Slot Hash")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}