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
                field("Task Date"; Rec."Plan Date")
                {
                    ApplicationArea = All;
                    Caption = 'Plan Date';
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
                    ApplicationArea = All;
                }
                field("End Time Assigned"; Rec."End Time Assigned")
                {
                    ApplicationArea = All;
                }
                field("Start Time Realized"; Rec."Start Time Realized")
                {
                    ApplicationArea = All;
                }
                field("End Time Realized"; Rec."End Time Realized")
                {
                    ApplicationArea = All;
                }
                field("Description"; Rec."Description")
                {
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
        DailyOptimizerSetup: Record "Daily Optimizer Setup";
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