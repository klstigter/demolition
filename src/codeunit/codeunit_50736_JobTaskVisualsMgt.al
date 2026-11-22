codeunit 50736 "Opti Job Task Visuals Mgt."
{
    /// <summary>
    /// Marks the resources assigned (via Day Planning) to the given project task.
    /// </summary>
    procedure MarkTaskResources(JobNo: Code[20]; JobTaskNo: Code[20]; var Resource: Record Resource)
    var
        DayPlanning: Record "Opti Day Planning";
        Marked: List of [Code[20]];
    begin
        Resource.Reset();
        Resource.ClearMarks();
        DayPlanning.SetRange("Job No.", JobNo);
        DayPlanning.SetRange("Job Task No.", JobTaskNo);
        DayPlanning.SetFilter("Assigned Resource No.", '<>%1', '');
        DayPlanning.SetLoadFields("Assigned Resource No.");
        if DayPlanning.FindSet() then
            repeat
                if not Marked.Contains(DayPlanning."Assigned Resource No.") then begin
                    Marked.Add(DayPlanning."Assigned Resource No.");
                    if Resource.Get(DayPlanning."Assigned Resource No.") then
                        Resource.Mark(true);
                end;
            until DayPlanning.Next() = 0;
    end;
}
