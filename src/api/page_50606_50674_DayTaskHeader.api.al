page 50674 "Daytask Header Opt"
{
    PageType = API;
    Caption = 'Daytask Header API';
    APIPublisher = 'BC365Optimizer';
    APIGroup = 'Planning';
    APIVersion = 'v1.0';
    EntityName = 'CreateDayTask';
    EntitySetName = 'CreateDayTasks';
    SourceTable = "Job Task";
    SourceTableTemporary = true;
    ODataKeyFields = "Job No.", "Job Task No.";
    DelayedInsert = true;
    InsertAllowed = true;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(jobNo_; Rec."Job No.")
                {
                    Caption = 'No.';
                }
                field(jobTaskNo_; Rec."Job Task No.")
                {
                    Caption = 'Task No.';
                }
                field(postResult; GetPostresult())
                {
                    Caption = 'Description';
                }
            }
            part(dayTaskLines; "Daytask Line Opt")
            {
                EntityName = 'DayTaskLine';
                EntitySetName = 'DayTaskLines';
                SubPageLink = "Job No." = field("Job No."),
                              "Job Task No." = field("Job Task No.");
            }
        }
    }

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        JobTask: Record "Job Task";
    begin
        // Validate the referenced Job Task exists before accepting any day task lines
        if not JobTask.Get(Rec."Job No.", Rec."Job Task No.") then
            Error('Job Task ''%1 / %2'' does not exist. Create the Job Task in Business Central first.', Rec."Job No.", Rec."Job Task No.");

        // Copy real Job Task data into the temp Rec so SubPageLink fields are correct
        Rec.TransferFields(JobTask, false);
        exit(true); // insert into temp table so the nested part can resolve its SubPageLink
    end;

    var

    local procedure GetPostresult(): Text
    var
        DayTaskTemp: Record "Day Tasks" temporary;
        GlobalSessionVar: Codeunit "Global Session Var Opt.";
        ResultJson: JsonObject;
        LinesArray: JsonArray;
        LineJson: JsonObject;
        ResultText: Text;
    begin
        if not DayTaskTemp.IsTemporary then
            Error('The Day Task Temp record must be temporary.');

        GlobalSessionVar.GetDayTaskTemp(DayTaskTemp);
        DayTaskTemp.Reset();
        if DayTaskTemp.FindSet() then
            repeat
                Clear(LineJson);
                LineJson.Add('systemId', DayTaskTemp.SystemId);
                LineJson.Add('taskDate', Format(DayTaskTemp."Task Date", 0, '<Year4>-<Month,2>-<Day,2>'));
                LineJson.Add('dayLineNo', DayTaskTemp."Day Line No.");
                LineJson.Add('jobNo', DayTaskTemp."Job No.");
                LineJson.Add('jobTaskNo', DayTaskTemp."Job Task No.");
                LineJson.Add('assignedResourceNo', DayTaskTemp."Assigned Resource No.");
                LineJson.Add('description', DayTaskTemp.Description);
                LineJson.Add('planStatus', Format(DayTaskTemp."Plan Status"));
                LineJson.Add('startTimeAssigned', Format(DayTaskTemp."Start Time Assigned", 0, '<Hours24,2>:<Minutes,2>:<Seconds,2>'));
                LineJson.Add('endTimeAssigned', Format(DayTaskTemp."End Time Assigned", 0, '<Hours24,2>:<Minutes,2>:<Seconds,2>'));
                LineJson.Add('assignedHours', DayTaskTemp."Assigned Hours");
                LineJson.Add('requestedHours', DayTaskTemp."Requested Hours");
                LinesArray.Add(LineJson);
            until DayTaskTemp.Next() = 0;

        ResultJson.Add('dayTaskLines', LinesArray);
        ResultJson.WriteTo(ResultText);
        exit(ResultText);
    end;

}