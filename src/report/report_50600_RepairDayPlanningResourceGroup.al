report 50600 "RepairData"
{
    Permissions = tabledata "Day Planning" = rim,
                  tabledata "Res. Capacity Entry" = rimd,
                  tabledata Resource = rim,
                  tabledata Vendor = r,
                  tabledata "Resource Skill" = rim,
                  tabledata "Skill Code" = r,
                  tabledata "Work Order" = r,
                  tabledata "Job Task" = rim;
    UsageCategory = Administration;
    ApplicationArea = All;
    Caption = 'Repair Data';
    ProcessingOnly = true;

    dataset
    {

    }

    trigger OnPreReport()
    begin
        RepairDurationOnAllJobTasks();
        RepairWorkingHoursOnAllDayPlannings();
    end;

    /// <summary>
    /// Recomputes Duration (tableextension 50605 "Job Task ext") for every Job Task with both
    /// PlannedStartDate and PlannedEndDate set - a one-time backfill for tasks left with a stale
    /// Duration by the CalculateDuration() bug fixed earlier this session (its case statement had
    /// no fallback for Scheduling Types other than FixedDuration/FixedWork - e.g. FixedUnits - so
    /// Duration was silently never recalculated for those). Only counts a row as repaired when the
    /// recomputed value actually differs from what's stored.
    /// </summary>
    procedure RepairDurationOnAllJobTasks()
    var
        JobTask: Record "Job Task";
        OldDuration: Integer;
        TotalCount: Integer;
        RepairedCount: Integer;
    begin
        JobTask.SetFilter(PlannedStartDate, '<>%1', 0D);
        JobTask.SetFilter(PlannedEndDate, '<>%1', 0D);
        if JobTask.FindSet(true) then
            repeat
                TotalCount += 1;
                OldDuration := JobTask.Duration;
                JobTask.CalculateDuration();
                if JobTask.Duration <> OldDuration then begin
                    JobTask.Modify();
                    RepairedCount += 1;
                end;
            until JobTask.Next() = 0;

        Message(RepairDurationResultMsg, RepairedCount, TotalCount);
    end;

    /// <summary>
    /// Recomputes "Assigned Hours", "Requested Hours", "Realized Hours", and "Capacity Fully
    /// Utilized" (all via CalculateWorkingHours()) plus "Assigned" (via AssignedCheck(), which
    /// depends on "Assigned Hours") on every existing Day Planning line - a one-time backfill for
    /// the CalculateRealizedWorkingHours() field-swap bug fixed in table 50610 this session (it
    /// wrote computed Realized hours into "Assigned Hours" instead of "Realized Hours", so
    /// "Realized Hours" was never once correctly populated anywhere, and "Assigned Hours" was
    /// silently corrupted whenever a line had both "Start Time Realized"/"End Time Realized" set).
    /// Fully recoverable with no data loss: the underlying time fields these are derived from were
    /// never touched by the bug, only their computed outputs were wrong. Deliberately does NOT use
    /// SetLoadFields - CalculateWorkingHours() routes through Codeunit "General Planning
    /// Utilities".DayPlanningFulFillment, whose full field dependencies aren't enumerated here, so
    /// partial field loading risks silently feeding it stale/blank values. Only counts a row as
    /// repaired when at least one of the four recomputed values actually changed. Commits in
    /// batches, same pattern as the other bulk-repair procedures in this report.
    /// </summary>
    procedure RepairWorkingHoursOnAllDayPlannings()
    var
        DayPlanning: Record "Day Planning";
        OldAssignedHours: Decimal;
        OldRequestedHours: Decimal;
        OldRealizedHours: Decimal;
        OldCapacityFullyUtilized: Boolean;
        OldAssigned: Boolean;
        TotalCount: Integer;
        RepairedCount: Integer;
        SinceLastCommit: Integer;
        CommitBatchSize: Integer;
    begin
        CommitBatchSize := 1000;

        if DayPlanning.FindSet(true) then
            repeat
                TotalCount += 1;
                OldAssignedHours := DayPlanning."Assigned Hours";
                OldRequestedHours := DayPlanning."Requested Hours";
                OldRealizedHours := DayPlanning."Realized Hours";
                OldCapacityFullyUtilized := DayPlanning."Capacity Fully Utilized";
                OldAssigned := DayPlanning.Assigned;

                DayPlanning.CalculateWorkingHours();
                DayPlanning.AssignedCheck();

                if (DayPlanning."Assigned Hours" <> OldAssignedHours) or (DayPlanning."Requested Hours" <> OldRequestedHours)
                   or (DayPlanning."Realized Hours" <> OldRealizedHours) or (DayPlanning."Capacity Fully Utilized" <> OldCapacityFullyUtilized)
                   or (DayPlanning.Assigned <> OldAssigned)
                then begin
                    DayPlanning.Modify();
                    RepairedCount += 1;
                    SinceLastCommit += 1;
                    if SinceLastCommit >= CommitBatchSize then begin
                        Commit();
                        SinceLastCommit := 0;
                    end;
                end;
            until DayPlanning.Next() = 0;

        Message(RepairWorkingHoursResultMsg, RepairedCount, TotalCount);
    end;

    var
        RepairAssignedFieldResultMsg: Label 'Recomputed the Assigned field on %1 of %2 Day Planning line(s) from their underlying legacy fields.';
        RepairSequenceNoResultMsg: Label 'Recomputed the Sequence No. field on %1 of %2 Day Planning line(s) with a Skill.';
        RepairWorkOrderNoResultMsg: Label 'Backfilled "Work Order No." on %1 Day Planning line(s) across %2 Work Order(s).';
        RepairJobTaskPlannedPeriodResultMsg: Label 'Widened PlannedStartDate/PlannedEndDate on %1 of %2 Job Task(s) to cover their existing Day Planning dates.';
        RepairDurationResultMsg: Label 'Recomputed Duration on %1 of %2 Job Task(s) with both Planned Start and End Date set.';
        RepairWorkingHoursResultMsg: Label 'Recomputed Assigned/Requested/Realized Hours (and Capacity Fully Utilized / Assigned) on %1 of %2 Day Planning line(s).';
}
