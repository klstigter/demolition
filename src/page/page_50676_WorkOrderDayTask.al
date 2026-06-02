page 50676 "Work Order Day Tasks"
{
    PageType = ListPart;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "Day Tasks";
    Caption = 'Work Order Day Tasks';

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field("Job No."; Rec."Job No.")
                {
                    ApplicationArea = All;
                }
                field("Job Task No."; Rec."Job Task No.")
                {
                    ApplicationArea = All;
                }
                field(DayLineNo; Rec."Day Line No.")
                {
                    ApplicationArea = All;
                }
                field("Work Order No."; Rec."Work Order No.")
                {
                    ApplicationArea = All;
                }
                field("Day No."; Rec."Day No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the day number in the sequence.';
                    Caption = 'Day No.';
                }
                field(Skill; Rec.Skill)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the skill required for this day task.';
                }
                field("No."; Rec."Assigned Resource No.")
                {
                    ApplicationArea = All;
                }
                field("Resource Group No."; Rec."Resource Group No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the resource group number.';
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
                field("Vendor No."; Rec."Vendor No.")
                {
                    ApplicationArea = All;
                }
                field("Task Date"; Rec."Task Date")
                {
                    ApplicationArea = All;
                }
                field("Start Time Assigned"; Rec."Start Time Assigned")
                {
                    ApplicationArea = All;
                }
                field("End Time Assigned"; Rec."End Time Assigned")
                {
                    ApplicationArea = All;
                }
                field("Start Time Requested"; Rec."Start Time Requested")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the start time for this day task.';
                }
                field("End Time Requested"; Rec."End Time Requested")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the end time for this day task.';
                }
                field("Description"; Rec."Description")
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

    // actions
    // {
    //     area(Processing)
    //     {
    //         action(ActionName)
    //         {

    //             trigger OnAction()
    //             begin

    //             end;
    //         }
    //     }
    // }

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        WorkOrder: Record "Work Order";
        DayTaskRec: Record "Day Tasks";
        WorkOrderNo: Code[20];
        NewDate: Date;
        DayLineNo: Integer;
    begin
        // Get the No. from the SubPageLink filter (FilterGroup 4)
        Rec.FilterGroup(4);
        if Rec.GetFilter("Work Order No.") <> '' then
            WorkOrderNo := Rec.GetRangeMin("Work Order No.");
        Rec.FilterGroup(0);

        if WorkOrderNo <> '' then
            Rec."Work Order No." := WorkOrderNo;

        Rec.Testfield("Work Order No.");
        WorkOrder.Get(Rec."Work Order No.");
        WorkOrder.TestField("Project No.");
        Rec."Job No." := WorkOrder."Project No.";
        WorkOrder.TestField("Project Task No.");
        Rec."Job Task No." := WorkOrder."Project Task No.";

        DayLineNo := 10000;
        DayTaskRec.SetRange("Job No.", Rec."Job No.");
        DayTaskRec.SetRange("Job Task No.", Rec."Job Task No.");
        if DayTaskRec.FindLast() then
            DayLineNo := DayTaskRec."Day Line No." + 10000;
        Rec."Day Line No." := DayLineNo;
    end;

}