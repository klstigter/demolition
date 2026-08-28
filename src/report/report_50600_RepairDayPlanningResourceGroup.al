report 50600 "RepairData"
{
    Permissions = tabledata "Day Planning" = rim,
                  tabledata "Res. Capacity Entry" = rimd,
                  tabledata Resource = rim,
                  tabledata Vendor = r,
                  tabledata "Resource Skill" = rim,
                  tabledata "Skill Code" = r;
    UsageCategory = Administration;
    ApplicationArea = All;
    Caption = 'Repair Data';
    ProcessingOnly = true;

    dataset
    {

    }

    trigger OnPreReport()
    begin
        //RepairAssignedFieldOnAllDayPlannings();
        RepairSequenceNoOnAllDayPlannings();
    end;

    /// <summary>
    /// Recomputes the Assigned field (DA1-T128) for every existing Day Planning line from its 5
    /// underlying legacy fields ("Plan Date", "Assigned Resource No.", "Start Time Assigned",
    /// "End Time Assigned", "Assigned Hours") via AssignedCheck() - a one-time backfill for rows
    /// that existed before the Assigned field was added and therefore still carry its default
    /// (false) regardless of what those 5 fields actually say. Only writes rows whose computed
    /// value differs from what is already stored, so this is cheap and safe to re-run. Commits
    /// in batches, same pattern as the other bulk-repair procedures in this report.
    /// </summary>
    procedure RepairAssignedFieldOnAllDayPlannings()
    var
        DayPlanning: Record "Day Planning";
        OldAssigned: Boolean;
        TotalCount: Integer;
        RepairedCount: Integer;
        SinceLastCommit: Integer;
        CommitBatchSize: Integer;
    begin
        CommitBatchSize := 1000;

        DayPlanning.SetLoadFields("Plan Date", "Assigned Resource No.", "Start Time Assigned", "End Time Assigned", "Assigned Hours", Assigned);
        if DayPlanning.FindSet(true) then
            repeat
                TotalCount += 1;
                OldAssigned := DayPlanning.Assigned;
                DayPlanning.AssignedCheck();
                if DayPlanning.Assigned <> OldAssigned then begin
                    DayPlanning.Modify();
                    RepairedCount += 1;
                    SinceLastCommit += 1;
                    if SinceLastCommit >= CommitBatchSize then begin
                        Commit();
                        SinceLastCommit := 0;
                    end;
                end;
            until DayPlanning.Next() = 0;

        Message(RepairAssignedFieldResultMsg, RepairedCount, TotalCount);
    end;

    /// <summary>
    /// Deterministically (re)builds "Sequence No." (DA1-T??? Day Planning Sequence) across ALL
    /// existing Day Planning lines with a non-blank Skill, by looping them in
    /// [Job No., Job Task No., Skill, Plan Date] order and calling Codeunit "Day Planning
    /// Sequence Mgt.".CalcSequence on each - the exact same collision-avoidance logic table 50610's
    /// own OnInsert/OnModify triggers already use, just re-run in a stable order across every
    /// existing row instead of relying on insert/modify order. No separate/bespoke algorithm is
    /// implemented here. This repo's "Job No.","Job Task No.","Plan Date","Day Line No." key
    /// (Rec1) is close but doesn't include Skill, so an inline SetCurrentKey with a Skill-aware
    /// ordering is used instead of touching the table's key list. Commits in batches, same pattern
    /// as RepairAssignedFieldOnAllDayPlannings above.
    /// </summary>
    procedure RepairSequenceNoOnAllDayPlannings()
    var
        DayPlanning: Record "Day Planning";
        DayPlanningSequenceMgt: Codeunit "Day Planning Sequence Mgt.";
        OldSequenceNo: Integer;
        TotalCount: Integer;
        RepairedCount: Integer;
        SinceLastCommit: Integer;
        CommitBatchSize: Integer;
    begin
        CommitBatchSize := 1000;

        DayPlanning.SetCurrentKey("Job No.", "Job Task No.", Skill, "Plan Date");
        DayPlanning.SetFilter(Skill, '<>%1', '');
        if DayPlanning.FindSet(true) then
            repeat
                TotalCount += 1;
                OldSequenceNo := DayPlanning."Sequence No.";
                DayPlanningSequenceMgt.CalcSequence(DayPlanning);
                if DayPlanning."Sequence No." <> OldSequenceNo then begin
                    DayPlanning.Modify();
                    RepairedCount += 1;
                    SinceLastCommit += 1;
                    if SinceLastCommit >= CommitBatchSize then begin
                        Commit();
                        SinceLastCommit := 0;
                    end;
                end;
            until DayPlanning.Next() = 0;

        Message(RepairSequenceNoResultMsg, RepairedCount, TotalCount);
    end;

    var
        RepairAssignedFieldResultMsg: Label 'Recomputed the Assigned field on %1 of %2 Day Planning line(s) from their underlying legacy fields.';
        RepairSequenceNoResultMsg: Label 'Recomputed the Sequence No. field on %1 of %2 Day Planning line(s) with a Skill.';
}
