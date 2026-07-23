codeunit 50680 "Delete Incorrect Day Planning"
{
    trigger OnRun()
    var
        DayPlanning: Record "Day Planning";
        JobTask: Record "Job Task";
        ConfirmLbl: Label 'This will permanently delete unposted Day Planning lines that are missing a Skill or fall outside their Job Task''s planned date range.\n\nContinue?';
        NothingLbl: Label 'No incorrect Day Planning lines found.';
        DoneLbl: Label 'Done. %1 incorrect Day Planning line(s) deleted.';
        DeletedCount: Integer;
    begin
        if not Confirm(ConfirmLbl, false) then
            exit;

        // Posted lines are financially settled and must never be touched by this cleanup.
        DayPlanning.SetRange(Posted, false);
        if DayPlanning.FindSet(true) then
            repeat
                if IsIncorrect(DayPlanning, JobTask) then begin
                    DayPlanning.Delete(false);
                    DeletedCount += 1;
                    // Commit periodically: at large demo-data volume this can match/delete a very
                    // large number of rows, so it must not run as one giant transaction/lock.
                    if DeletedCount mod 1000 = 0 then
                        Commit();
                end;
            until DayPlanning.Next() = 0;

        if DeletedCount = 0 then
            Message(NothingLbl)
        else
            Message(DoneLbl, DeletedCount);
    end;

    local procedure IsIncorrect(var DayPlanning: Record "Day Planning"; var JobTask: Record "Job Task"): Boolean
    begin
        // Skill is mandatory on every Day Planning line.
        if DayPlanning.Skill = '' then
            exit(true);

        if (DayPlanning."Job No." = '') or (DayPlanning."Job Task No." = '') then
            exit(false);

        if not JobTask.Get(DayPlanning."Job No.", DayPlanning."Job Task No.") then
            exit(false); // orphan Job Task link is out of scope for this cleanup

        if (JobTask.PlannedStartDate <> 0D) and (DayPlanning."Task Date" < JobTask.PlannedStartDate) then
            exit(true);
        if (JobTask.PlannedEndDate <> 0D) and (DayPlanning."Task Date" > JobTask.PlannedEndDate) then
            exit(true);

        exit(false);
    end;
}
