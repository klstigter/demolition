page 50675 "DayPlanning Line Opt"
{
    // Dedicated PageType = API subpage for DayPlanning Lines.
    // Must be PageType = API (not ListPart) so BC does not auto-initialize
    PageType = API;
    APIPublisher = 'BC365Optimizer';
    APIGroup = 'Planning';
    APIVersion = 'v1.0';
    EntityName = 'DayPlanningLine';
    EntitySetName = 'DayPlanningLines';
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
                    Caption = 'Work Date';
                }
                field(no_; Rec."Assigned Resource No.")
                {
                    Caption = 'No.';
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
                field(startTimeAssigned; Rec."Start Time Assigned")
                {
                    Caption = 'Start Time Assigned';
                }
                field(endTimeAssigned; Rec."End Time Assigned")
                {
                    Caption = 'End Time Assigned';
                }
                field(requestedHours; Rec."Requested Hours")
                {
                    ApplicationArea = All;
                }
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
                field(workOrderNo; Rec."Work Order No.")
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
        DailyOptimizerSetup: Record "Daily Optimizer Setup";
        NextLineNo: Integer;
        GuidVar: Guid;
        ModifyRec: Boolean;
        NoDefaultSkillErr: Label 'Cannot insert this Day Planning line: no Skill was submitted, and "Daily Optimizer Setup"."Default Skill" is not set. Configure a Default Skill, or submit a Skill value.';
    begin
        // Step 1: snapshot ALL incoming API data FIRST, before Rec is touched
        TempLine.Copy(Rec);

        // Check if a line for the same DayPlanning already exists in this batch
        if ExistingLine.Get(TempLine."Job No.", TempLine."Job Task No.", TempLine."Day Line No.") then begin
            // Modify path: load existing PK into Rec; payload comes from TempLine (incoming)
            ModifyRec := true;
            Rec := ExistingLine;
        end else begin
            // Insert path: clear stale framework values and rebuild PK
            ModifyRec := false;
            Clear(Rec);
            Rec."Job No." := TempLine."Job No.";
            Rec."Job Task No." := TempLine."Job Task No.";
            if TempLine."Day Line No." <> 0 then
                NextLineNo := TempLine."Day Line No."
            else begin
                ExistingLine.Reset();
                ExistingLine.SetRange("Job No.", Rec."Job No.");
                ExistingLine.SetRange("Job Task No.", Rec."Job Task No.");
                if ExistingLine.FindLast() then
                    NextLineNo := ExistingLine."Day Line No." + 10000
                else
                    NextLineNo := 10000;
            end;
            Rec."Day Line No." := NextLineNo;
        end;

        // Apply incoming payload — TempLine always holds the API-submitted values
        Rec."Plan Date" := TempLine."Plan Date";
        // Validate (not a raw assignment) so CheckResourceHasSkill runs - an external API caller
        // could otherwise push any Resource/Skill combo straight past validation.
        Rec.Validate("Assigned Resource No.", TempLine."Assigned Resource No.");
        Rec.Description := TempLine.Description;
        Rec."Plan Status" := TempLine."Plan Status";
        Rec."Start Time Assigned" := TempLine."Start Time Assigned";
        Rec.validate("End Time Assigned", TempLine."End Time Assigned");
        Rec."Requested Hours" := TempLine."Requested Hours";
        Rec."Worked Hours" := TempLine."Worked Hours";
        Rec."Data Owner" := TempLine."Data Owner";
        Rec."Requested Team Leader" := TempLine."Requested Team Leader";
        Rec."Assigned Team Leader" := TempLine."Assigned Team Leader";
        Rec."Requested Leader" := TempLine."Requested Leader";
        Rec."Assigned Leader" := TempLine."Assigned Leader";
        Rec."Work Order No." := TempLine."Work Order No.";
        // Validate, applied AFTER "Assigned Resource No." above: the Skill field's own OnValidate
        // cross-checks that the now-assigned resource actually holds this specific skill
        // (SkillRes.Get(Type::Resource, "Assigned Resource No.", Skill)), which is the real
        // resource<->skill match check - CheckResourceHasSkill above only confirms the resource
        // has *a* skill, not this one. If the caller submitted no Skill at all, fall back to
        // "Daily Optimizer Setup"."Default Skill" (Get() only happens here, not called upfront -
        // no SQL round-trip when the caller already supplied one) - hard error when no default is
        // configured either, same convention as codeunit 50604's onEventAdded.
        if TempLine."Skill" <> '' then
            Rec.Validate("Skill", TempLine."Skill")
        else begin
            DailyOptimizerSetup.Get();
            if DailyOptimizerSetup."Default Skill" = '' then
                Error(NoDefaultSkillErr);
            Rec.Validate("Skill", DailyOptimizerSetup."Default Skill");
        end;

        if ModifyRec then
            Rec.Modify()
        else
            Rec.Insert(true);

        GlobalSessionVar.SetDayPlanningTemp(Rec); // stash the inserted/updated line in a global temp table for retrieval by the parent header API

        // BC must NOT insert again
        exit(false);
    end;

    var
        GlobalSessionVar: Codeunit "Global Session Var Opt.";
}