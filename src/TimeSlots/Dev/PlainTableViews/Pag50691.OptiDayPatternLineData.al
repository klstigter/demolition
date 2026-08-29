page 50691 "Opti Day TimeSlot Line Data"
{
    PageType = List;
    SourceTable = "Opti Day-TimeSlot Line";
    Caption = 'Opti Day Pattern Line Data';
    ApplicationArea = All;
    UsageCategory = Administration;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Day Pattern ID"; Rec."Day-TimeSLots Header No.")
                {
                    ApplicationArea = All;
                }
                field("Line No."; Rec."Day-TimeSLot Line No.")
                {
                    ApplicationArea = All;
                }
                field("Time Slot ID"; Rec."Time Slot No.")
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
                field("Rest Minutes"; Rec."Rest Minutes")
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
            }
        }
    }
}