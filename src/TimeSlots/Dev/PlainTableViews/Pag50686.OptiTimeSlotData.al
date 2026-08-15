page 50686 "Opti Time Slot Data"
{
    PageType = List;
    SourceTable = "Opti Time Slot";
    Caption = 'Opti Time Slot Data';
    ApplicationArea = All;
    UsageCategory = Administration;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Time Slot ID"; Rec."Time Slot ID")
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
                field("Time Slot Hash"; Rec."Time Slot Hash")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}