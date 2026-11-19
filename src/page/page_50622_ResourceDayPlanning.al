page 50622 "Opti Resource Day Plannings"
{
    PageType = ListPart;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "Opti Day Planning";
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
                    ToolTip = 'Specifies the value of the No. field.';
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
                    ToolTip = 'Specifies the value of the Data Owner field.';
                    Caption = 'Data Owner';
                }
                field("Vendor No."; Rec."Vendor No.")
                {
                    ToolTip = 'Specifies the value of the Vendor No. field.';
                    ApplicationArea = All;
                }
                field("Task Date"; Rec."Plan Date")
                {
                    ToolTip = 'Specifies the value of the Task Date field.';
                    ApplicationArea = All;
                    Caption = 'Plan Date';
                }
                field(DayLineNo; Rec."Day Line No.")
                {
                    ToolTip = 'Specifies the value of the Day Line No field.';
                    ApplicationArea = All;
                }
                field("Job No."; Rec."Job No.")
                {
                    ToolTip = 'Specifies the value of the Job No. field.';
                    ApplicationArea = All;
                }
                field("Job Task No."; Rec."Job Task No.")
                {
                    ToolTip = 'Specifies the value of the Job Task No. field.';
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
                field("Start Time Assigned"; Rec."Start Time Assigned")
                {
                    ToolTip = 'Specifies the value of the Start Time Assigned field.';
                    ApplicationArea = All;
                }
                field("End Time Assigned"; Rec."End Time Assigned")
                {
                    ToolTip = 'Specifies the value of the End Time Assigned field.';
                    ApplicationArea = All;
                }
                field("Start Time Realized"; Rec."Start Time Realized")
                {
                    ToolTip = 'Specifies the value of the Start Time Realized field.';
                    ApplicationArea = All;
                }
                field("End Time Realized"; Rec."End Time Realized")
                {
                    ToolTip = 'Specifies the value of the End Time Realized field.';
                    ApplicationArea = All;
                }
                field("Description"; Rec."Description")
                {
                    ToolTip = 'Specifies the value of the Description field.';
                    ApplicationArea = All;
                }
                field("Requested Leader"; Rec."Requested Leader")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the leader for this day planning.';
                }
                field("Requested Team Leader"; Rec."Requested Team Leader")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the team leader for this day planning.';
                }
                field("Assigned Leader"; Rec."Assigned Leader")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the leader for this day planning.';
                }
                field("Assigned Team Leader"; Rec."Assigned Team Leader")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the team leader for this day planning.';
                }
                field("Work Order No."; Rec."Order Intake No.")
                {
                    ToolTip = 'Specifies the value of the Work Order No. field.';
                    ApplicationArea = All;
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
        DayPlanningRec: Record "Opti Day Planning";
        DailyOptimizerSetup: Record "Opti Daily Optimizer Setup";
        ResourceNo: Code[20];
        NewDate: Date;
        DayLineNo: Integer;
        NoDefaultSkillErr: Label 'Cannot create a Day Planning line here: this subpage has no Skill context of its own, and "Daily Optimizer Setup"."Default Skill" is not set. Configure a Default Skill before assigning resources this way.';
    begin
        // Get the No. from the SubPageLink filter (FilterGroup 4)
        Rec.FilterGroup(4);
        if Rec.GetFilter("Assigned Resource No.") <> '' then
            ResourceNo := Rec.GetRangeMin("Assigned Resource No.");
        Rec.FilterGroup(0);

        NewDate := Today();
        DayLineNo := 10000;
        DayPlanningRec.SetRange("Plan Date", NewDate);
        if DayPlanningRec.FindLast() then
            DayLineNo := DayPlanningRec."Day Line No." + 10000;

        Rec."Plan Date" := NewDate;
        Rec."Day Line No." := DayLineNo;
        if ResourceNo <> '' then begin
            // No Skill field/column exists on this subpage. Validate the resource first (its own
            // OnValidate auto-fills Skill with the resource's first skill) - only fall back to
            // "Daily Optimizer Setup"."Default Skill" if that left Skill blank (don't override a
            // skill the resource already validated as holding). DailyOptimizerSetup.Get() is
            // deliberately INSIDE this check, not called upfront - no SQL round-trip on the common
            // path where the resource's own skill already covers it.
            Rec.Validate("Assigned Resource No.", ResourceNo);
            if Rec.Skill = '' then begin
                DailyOptimizerSetup.Get();
                if DailyOptimizerSetup."Default Skill" = '' then
                    Error(NoDefaultSkillErr);
                Rec.Validate(Skill, DailyOptimizerSetup."Default Skill");
            end;
        end;
    end;

}