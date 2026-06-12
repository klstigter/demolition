page 50622 "Resource Day Plannings"
{
    PageType = ListPart;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "Day Planning";
    Caption = 'Resource Day Plannings';

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field("Day No."; Rec."Day No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the day number in the sequence.';
                    Caption = 'Day No.';
                }
                field("No."; Rec."Assigned Resource No.")
                {
                    ApplicationArea = All;
                }
                field("Pattern Line No."; Rec."Pattern Line No.")
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
                    ToolTip = 'Specifies the plan status of the day planning.';
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
                field(DayLineNo; Rec."Day Line No.")
                {
                    ApplicationArea = All;
                }
                field("Job No."; Rec."Job No.")
                {
                    ApplicationArea = All;
                }
                field("Job Task No."; Rec."Job Task No.")
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
                    ToolTip = 'Specifies the start time for this day planning.';
                }
                field("End Time Requested"; Rec."End Time Requested")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the end time for this day planning.';
                }
                field("Description"; Rec."Description")
                {
                    ApplicationArea = All;
                }
                field("Team Leader"; Rec."Team Leader")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the team leader for this day planning.';
                }
                field(Leader; Rec.Leader)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the leader for this day planning.';
                }
                field("Work Order No."; Rec."Work Order No.")
                {
                    ApplicationArea = All;
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
        DayPlanningRec: Record "Day Planning";
        ResourceNo: Code[20];
        NewDate: Date;
        DayLineNo: Integer;
    begin
        // Get the No. from the SubPageLink filter (FilterGroup 4)
        Rec.FilterGroup(4);
        if Rec.GetFilter("Assigned Resource No.") <> '' then
            ResourceNo := Rec.GetRangeMin("Assigned Resource No.");
        Rec.FilterGroup(0);

        if ResourceNo <> '' then
            Rec."Assigned Resource No." := ResourceNo;

        NewDate := Today();
        DayLineNo := 10000;
        DayPlanningRec.SetRange("Task Date", NewDate);
        if DayPlanningRec.FindLast() then
            DayLineNo := DayPlanningRec."Day Line No." + 10000;

        Rec."Task Date" := NewDate;
        Rec."Day Line No." := DayLineNo;
    end;

}