page 50634 "Opti Day Plannings FactBox"
{
    Caption = 'Day Plannings';
    PageType = CardPart;
    UsageCategory = None; // avoid appear in the list of searchbox
    ApplicationArea = All;
    SourceTable = "Opti Day Planning";

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Task Date"; Rec."Plan Date")
                {
                    ToolTip = 'Specifies the value of the Task Date field.';
                    ApplicationArea = All;
                    Caption = 'Plan Date';
                }
                field("DayLine No."; Rec."Day Line No.")
                {
                    ToolTip = 'Specifies the value of the Day Line No. field.';
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
                    ToolTip = 'Specifies the value of the Data Owner field.';
                    Caption = 'Data Owner';
                }
                field("Work Order No."; Rec."Order Intake No.")
                {
                    ToolTip = 'Specifies the value of the Work Order No. field.';
                    ApplicationArea = All;
                }
                field("Start Time"; Rec."Start Time Assigned")
                {
                    ToolTip = 'Specifies the value of the Start Time field.';
                    ApplicationArea = All;
                }
                field("End Time"; Rec."End Time Assigned")
                {
                    ToolTip = 'Specifies the value of the End Time field.';
                    ApplicationArea = All;
                }
                field("Description"; Rec.Description)
                {
                    ToolTip = 'Specifies the value of the Description field.';
                    ApplicationArea = All;
                }
                field("Requested Leader"; Rec."Requested Leader")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the leader for this day task.';
                }
                field("Requested Team Leader"; Rec."Requested Team Leader")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the team leader for this day task.';
                }
                field("Assigned Leader"; Rec."Assigned Leader")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the assigned leader for this day task.';
                }
                field("Assigned Team Leader"; Rec."Assigned Team Leader")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the assigned team leader for this day task.';
                }
                field("Project Manager Status"; Rec."Project Manager Status")
                {
                    ToolTip = 'Specifies the value of the Project Manager Status field.';
                    ApplicationArea = All;
                }
                field("Planner Status"; Rec."Planner Status")
                {
                    ToolTip = 'Specifies the value of the Planner Status field.';
                    ApplicationArea = All;
                }
                field("Vendor Status"; Rec."Vendor Status")
                {
                    ToolTip = 'Specifies the value of the Vendor Status field.';
                    ApplicationArea = All;
                }
                field("Approved Project Manager"; Rec."Approved Project Manager")
                {
                    ToolTip = 'Specifies the value of the Approved Project Manager field.';
                    ApplicationArea = All;
                }

            }
        }
    }
}