page 50634 "Day Tasks FactBox"
{
    Caption = 'Day Tasks';
    PageType = CardPart;
    UsageCategory = None; // avoid appear in the list of searchbox
    ApplicationArea = All;
    SourceTable = "Day Tasks";

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Task Date"; Rec."Task Date")
                {
                    ApplicationArea = All;
                }
                field("DayLine No."; Rec."Day Line No.")
                {
                    ApplicationArea = All;
                }
                field("Day No."; Rec."Day No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the day number in the sequence.';
                    Caption = 'Day No.';
                }
                field("Plan Status"; Rec."Plan Status")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the plan status of the day task.';
                }
                field("Data Owner"; Rec."Data Owner")
                {
                    Caption = 'Data Owner';
                }
                field("Work Order No."; Rec."Work Order No.")
                {
                    ApplicationArea = All;
                }
                field("Start Time"; Rec."Start Time Assigned")
                {
                    ApplicationArea = All;
                }
                field("End Time"; Rec."End Time Assigned")
                {
                    ApplicationArea = All;
                }
                field("Description"; Rec.Description)
                {
                    ApplicationArea = All;
                }
                field("Team Leader"; Rec."Team Leader")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the team leader for this day task.';
                }
                field(Leader; Rec.Leader)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the leader for this day task.';
                }
            }
        }
    }
}