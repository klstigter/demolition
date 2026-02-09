codeunit 50611 "Job Task Indent"
{
    procedure IndentJobTasks(var JobTask: Record "Job Task")
    var
        JobTaskToIndent: Record "Job Task";
        IndentLevel: Integer;
        JobNo: Code[20];
        TasksUpdated: Integer;
    begin
        if not Confirm('This will update the indentation for all job tasks in job %1. Do you want to continue?', false, JobTask."Job No.") then
            exit;

        JobNo := JobTask."Job No.";
        IndentLevel := 0;
        TasksUpdated := 0;

        JobTaskToIndent.SetRange("Job No.", JobNo);
        JobTaskToIndent.SetCurrentKey("Job No.", "Job Task No.");
        if JobTaskToIndent.FindSet() then
            repeat
                case JobTaskToIndent."Job Task Type" of
                    JobTaskToIndent."Job Task Type"::"Begin-Total",
                    JobTaskToIndent."Job Task Type"::Heading:
                        begin
                            JobTaskToIndent.Indentation := IndentLevel;
                            JobTaskToIndent.Modify();
                            IndentLevel := IndentLevel + 1;
                            TasksUpdated := TasksUpdated + 1;
                        end;
                    JobTaskToIndent."Job Task Type"::"End-Total",
                    JobTaskToIndent."Job Task Type"::Total:
                        begin
                            if IndentLevel > 0 then
                                IndentLevel := IndentLevel - 1;
                            JobTaskToIndent.Indentation := IndentLevel;
                            JobTaskToIndent.Modify();
                            TasksUpdated := TasksUpdated + 1;
                        end;
                    JobTaskToIndent."Job Task Type"::Posting:
                        begin
                            JobTaskToIndent.Indentation := IndentLevel;
                            JobTaskToIndent.Modify();
                            TasksUpdated := TasksUpdated + 1;
                        end;
                end;
            until JobTaskToIndent.Next() = 0;

        Message('%1 job tasks have been indented.', TasksUpdated);
    end;

    procedure IndentAllJobTasks()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
    begin
        if not Confirm('This will update the indentation for all job tasks in all jobs. Do you want to continue?', false) then
            exit;

        if Job.FindSet() then
            repeat
                JobTask.SetRange("Job No.", Job."No.");
                if JobTask.FindFirst() then
                    IndentJobTasks(JobTask);
            until Job.Next() = 0;
    end;
}
