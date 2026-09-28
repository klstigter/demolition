page 50675 "DayPlanning Line Opt"
{
    // Dedicated PageType = API subpage for DayPlanning Lines.
    // Must be PageType = API (not ListPart) so BC does not auto-initialize
    PageType = API;
    APIPublisher = 'BC365Optimizer';
    APIGroup = 'Planning';
    APIVersion = 'v1.0';
    EntityName = 'dayPlanningLine';
    EntitySetName = 'dayPlanningLines';
    SourceTable = "Day Planning";
    ODataKeyFields = SystemId;
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field(systemId; Rec.SystemId)
                {
                    Caption = 'System Id';
                    Editable = false;
                }
                field(jobNo_; Rec."Job No.")
                {
                    Caption = 'No.';
                }
                field(jobTaskNo_; Rec."Job Task No.")
                {
                    Caption = 'Task No.';
                }
                field(dayLineNo_; Rec."Day Line No.")
                {
                    Caption = 'Day Line No.';
                }
                field(taskDate; Rec."Plan Date")
                {
                    Caption = 'Plan Date';
                }
                field(requestedResourceNo; Rec."Requested Resource No.")
                {
                    Caption = 'Requested Resource No.';
                }
                field(assignedResourceNo; Rec."Assigned Resource No.")
                {
                    Caption = 'Assigned Resource No.';
                }
                field(description; Rec.Description)
                {
                    Caption = 'Description';
                }
                field(skill; Rec."Skill")
                {
                    Caption = 'Skill';
                }
                field(planStatus; Rec."Plan Status")
                {
                    ApplicationArea = All;
                }
                field(startTimeRequested; Rec."Start Time Requested")
                {
                    Caption = 'Start Time Requested';
                }
                field(endTimeRequested; Rec."End Time Requested")
                {
                    Caption = 'End Time Requested';
                }
                field(nonWorkingMinutesRequested; Rec."Non Working Minutes Requested")
                {
                    Caption = 'Non Working Minutes Requested';
                }
                field(startTimeAssigned; Rec."Start Time Assigned")
                {
                    Caption = 'Start Time Assigned';
                }
                field(endTimeAssigned; Rec."End Time Assigned")
                {
                    Caption = 'End Time Assigned';
                }
                field(nonWorkingMinutesAssigned; Rec."Non Working Minutes Assigned")
                {
                    Caption = 'Non Working Minutes Assigned';
                }
                field(requestedHours; Rec."Requested Hours")
                {
                    ApplicationArea = All;
                }
                field(assignedHours; Rec."Assigned Hours")
                {
                    ApplicationArea = All;
                }

                field(startTimeRealized; Rec."Start Time Realized") { }
                field(endTimeRealized; Rec."End Time Realized") { }
                field(realizedHours; Rec."Realized Hours") { }

                field(workedHours; Rec."Worked Hours")
                {
                    ApplicationArea = All;
                }
                field(dataOwner; Rec."Data Owner")
                {
                    Caption = 'Data Owner';
                }
                field(requestedLeader; Rec."Requested Leader")
                {
                    ApplicationArea = All;
                }
                field(requestedTeamLeader; Rec."Requested Team Leader")
                {
                    ApplicationArea = All;
                }
                field(assignedLeader; Rec."Assigned Leader")
                {
                    ApplicationArea = All;
                }
                field(assignedTeamLeader; Rec."Assigned Team Leader")
                {
                    ApplicationArea = All;
                }
                field(orderIntakeNo; Rec."Order Intake No.")
                {
                    ApplicationArea = All;
                }
                field(sequenceNo; Rec."Sequence No.")
                {
                    ApplicationArea = All;
                }
            }
        }
    }




    trigger OnOpenPage()
    var
        ErrLbl: Label 'You must specify a Job No. and Job Task No. filter to access day planning lines.';
    begin
        // Prevent unfiltered access — caller must supply a Job No. and Job Task No. filter.
        // When used as a nested subpage, BC injects the SubPageLink filter automatically.
        if (Rec.GetFilter(SystemId) = '') and
           (Rec.GetFilter("Job No.") = '') and
           (Rec.GetFilter("Job Task No.") = '')
        then
            Error(ErrLbl);
        GlobalSessionVar.ResetDayPlanningTemp();
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        TempLine: Record "Day Planning" temporary;
        ExistingLine: Record "Day Planning";
        NewLine: Record "Day Planning";
        DailyOptimizerSetup: Record "Daily Optimizer Setup";
        JobTask: record "Job Task";
        NextLineNo: Integer;
        HeaderMismatchErr: Label 'Day Planning line Job No. %1 / Job Task No. %2 does not match the header Job No. %3 / Job Task No. %4.';
        NoDefaultSkillErr: Label 'Cannot insert this Day Planning line: no Skill was submitted, and "Daily Optimizer Setup"."Default Skill" is not set. Configure a Default Skill, or submit a Skill value.';
    begin
        // Step 1: snapshot ALL incoming API data FIRST, before Rec is touched
        TempLine.Copy(Rec);
        if GlobalSessionVar.IsHeaderInsertPending() then
            exit(false); // phantom pre-header bind of the first line - the real deep-insert pass follows

        // Line must belong to the header's Job / Job Task (SubPageLink filters on Rec)
        if (TempLine."Job No." <> Rec.GetFilter("Job No.")) or (TempLine."Job Task No." <> Rec.GetFilter("Job Task No.")) then
            Error(HeaderMismatchErr, TempLine."Job No.", TempLine."Job Task No.", Rec.GetFilter("Job No."), Rec.GetFilter("Job Task No."));

        // Build the real record in a separate variable - leave the page Rec (framework state) untouched
        NewLine.Init();
        NewLine."Job No." := TempLine."Job No.";
        NewLine."Job Task No." := TempLine."Job Task No.";
        if TempLine."Day Line No." <> 0 then
            NextLineNo := TempLine."Day Line No."
        else begin
            ExistingLine.Reset();
            ExistingLine.SetRange("Job No.", NewLine."Job No.");
            ExistingLine.SetRange("Job Task No.", NewLine."Job Task No.");
            if ExistingLine.FindLast() then
                NextLineNo := ExistingLine."Day Line No." + 10000
            else
                NextLineNo := 10000;
        end;
        NewLine."Day Line No." := NextLineNo;

        // Apply incoming payload — TempLine always holds the API-submitted values
        NewLine."Plan Date" := TempLine."Plan Date";
        // Validate (not a raw assignment) so CheckResourceHasSkill runs - an external API caller
        // could otherwise push any Resource/Skill combo straight past validation.
        NewLine.Validate("Assigned Resource No.", TempLine."Assigned Resource No.");
        NewLine.Description := TempLine.Description;
        NewLine."Plan Status" := TempLine."Plan Status";
        NewLine."Start Time Assigned" := TempLine."Start Time Assigned";
        NewLine.validate("End Time Assigned", TempLine."End Time Assigned");
        NewLine."Requested Hours" := TempLine."Requested Hours";
        NewLine."Worked Hours" := TempLine."Worked Hours";
        NewLine."Data Owner" := TempLine."Data Owner";
        NewLine."Requested Team Leader" := TempLine."Requested Team Leader";
        NewLine."Assigned Team Leader" := TempLine."Assigned Team Leader";
        NewLine."Requested Leader" := TempLine."Requested Leader";
        NewLine."Assigned Leader" := TempLine."Assigned Leader";
        NewLine."Order Intake No." := TempLine."Order Intake No.";
        // Validate, applied AFTER "Assigned Resource No." above: the Skill field's own OnValidate
        // cross-checks that the now-assigned resource actually holds this specific skill
        // (SkillRes.Get(Type::Resource, "Assigned Resource No.", Skill)), which is the real
        // resource<->skill match check - CheckResourceHasSkill above only confirms the resource
        // has *a* skill, not this one. If the caller submitted no Skill at all, fall back to
        // "Daily Optimizer Setup"."Default Skill" (Get() only happens here, not called upfront -
        // no SQL round-trip when the caller already supplied one) - hard error when no default is
        // configured either, same convention as codeunit 50604's onEventAdded.
        if TempLine."Skill" <> '' then
            NewLine.Validate("Skill", TempLine."Skill")
        else begin
            DailyOptimizerSetup.Get();
            if DailyOptimizerSetup."Default Skill" = '' then
                Error(NoDefaultSkillErr);
            NewLine.Validate("Skill", DailyOptimizerSetup."Default Skill");
        end;

        JobTask.Get(NewLine."Job No.", NewLine."Job Task No.");
        JobTask.Testfield("Job Task Type", JobTask."Job Task Type"::Posting);

        NewLine.Insert(true);

        GlobalSessionVar.SetDayPlanningTemp(NewLine); // stash the inserted line in a global temp table for retrieval by the parent header API

        // BC must NOT insert again
        exit(false);
    end;

    var
        GlobalSessionVar: Codeunit "Global Session Var Opt.";
}