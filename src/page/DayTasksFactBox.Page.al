page 50634 "Day Tasks FactBox"
{
    Caption = 'Day Tasks';
    PageType = CardPart;
    UsageCategory = Lists;
    ApplicationArea = All;
    SourceTable = "Day Tasks";

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Day No."; Rec."Day No.")
                {
                    ApplicationArea = All;
                }
                field("DayLine No."; Rec.DayLineNo)
                {
                    ApplicationArea = All;
                }
                field("Task Date"; Rec."Task Date")
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
                field("Description"; Rec.Description)
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}