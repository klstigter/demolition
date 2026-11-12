codeunit 50614 "Gantt BC Page Handler"
{
    procedure OpenJobTaskCard(JobNo: Code[20]; JobTaskNo: Code[20])
    var
        JobTask: Record "Job Task";
    begin
        if not JobTask.Get(JobNo, JobTaskNo) then
            Error('Job Task %1 %2 not found', JobNo, JobTaskNo);

        case JobTask."Job View Type" of
            JobTask."Job View Type"::Project:
                Page.Run(Page::"Opti Job Task Card", JobTask);
            JobTask."Job View Type"::Resource:
                Page.Run(Page::"Job Task Card - Resource", JobTask);
            else
                Error('Unknown Job View Type for Job Task %1 %2', JobNo, JobTaskNo);
        end;
    end;

    /// Inserts a new Job Task (next free numeric Job Task No. + 10) and opens the Opti Job Task Card on it.
    /// Close acts as Cancel: if no Description was entered the new task is deleted again.
    /// Returns true if the task was kept.
    procedure OpenNewJobTaskCardModal(JobNo: Code[20]; SiblingTaskNo: Code[20]; BarStart: Date; BarEnd: Date): Boolean
    var
        JobTask: Record "Job Task";
        Existing: Record "Job Task";
        MaxNo: Integer;
        TaskNo: Integer;
        NewIndentation: Integer;
        Candidate: Code[20];
    begin
        // New task gets the same indentation as the row whose "+" was clicked
        if Existing.Get(JobNo, SiblingTaskNo) then
            NewIndentation := Existing.Indentation;
        Existing.Reset();
        Existing.SetRange("Job No.", JobNo);
        if Existing.FindSet() then
            repeat
                if Evaluate(TaskNo, Existing."Job Task No.") then
                    if TaskNo > MaxNo then
                        MaxNo := TaskNo;
            until Existing.Next() = 0;

        JobTask.Init();
        JobTask."Job No." := JobNo;
        // Gantt order = Job Task No. order and the parent comes from the rows before it, so the
        // new number must sort directly after the clicked row (clicked no. + '0'), before the
        // next task. Falls back to highest numeric no. + 10 if that slot is taken/unusable.
        JobTask."Job Task No." := Format(MaxNo + 10);
        if SiblingTaskNo <> '' then begin
            // No AL "<" comparison here: AL compares numeric-looking codes as numbers while the
            // database (and so the Gantt) orders them as text. "<clicked no.>0" is always the
            // very next key after the clicked one in text order, so only a collision matters.
            Existing.Reset();
            Candidate := CopyStr(SiblingTaskNo + '0', 1, MaxStrLen(Candidate));
            if (StrLen(SiblingTaskNo) < MaxStrLen(Candidate)) and not Existing.Get(JobNo, Candidate) then
                JobTask."Job Task No." := Candidate;
        end;
        JobTask."Job View Type" := JobTask."Job View Type"::Project;
        JobTask.Indentation := NewIndentation;
        JobTask.VisualBarStartDate := BarStart;
        JobTask.VisualBarEndDate := BarEnd;
        JobTask.CalculateDuration();
        JobTask.Insert(true);
        Commit();

        Page.RunModal(Page::"Opti Job Task Card", JobTask);

        JobTask.Get(JobTask."Job No.", JobTask."Job Task No.");
        if JobTask.Description = '' then begin
            JobTask.Delete(true);
            exit(false);
        end;
        exit(true);
    end;

    procedure OpenJobTaskCardModal(JobNo: Code[20]; JobTaskNo: Code[20]): Boolean
    var
        JobTask: Record "Job Task";
    begin
        if not JobTask.Get(JobNo, JobTaskNo) then
            Error('Job Task %1 %2 not found', JobNo, JobTaskNo);

        case JobTask."Job View Type" of
            JobTask."Job View Type"::Project:
                exit(Page.RunModal(Page::"Opti Job Task Card", JobTask) = Action::OK);
            JobTask."Job View Type"::Resource:
                exit(Page.RunModal(Page::"Job Task Card - Resource", JobTask) = Action::OK);
            else
                Error('Unknown Job View Type for Job Task %1 %2', JobNo, JobTaskNo);
        end;
    end;
}
