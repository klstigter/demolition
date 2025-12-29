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
                Page.Run(Page::"Job Task Card - Project", JobTask);
            JobTask."Job View Type"::Resource:
                Page.Run(Page::"Job Task Card - Resource", JobTask);
            else
                Error('Unknown Job View Type for Job Task %1 %2', JobNo, JobTaskNo);
        end;
    end;

    procedure OpenJobTaskCardModal(JobNo: Code[20]; JobTaskNo: Code[20]): Boolean
    var
        JobTask: Record "Job Task";
    begin
        if not JobTask.Get(JobNo, JobTaskNo) then
            Error('Job Task %1 %2 not found', JobNo, JobTaskNo);

        case JobTask."Job View Type" of
            JobTask."Job View Type"::Project:
                exit(Page.RunModal(Page::"Job Task Card - Project", JobTask) = Action::OK);
            JobTask."Job View Type"::Resource:
                exit(Page.RunModal(Page::"Job Task Card - Resource", JobTask) = Action::OK);
            else
                Error('Unknown Job View Type for Job Task %1 %2', JobNo, JobTaskNo);
        end;
    end;
}
