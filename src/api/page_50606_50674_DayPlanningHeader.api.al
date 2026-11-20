page 50674 "DayPlanning Header Opt"
{
    PageType = API;
    Caption = 'DayPlanning Header API';
    APIPublisher = 'BC365Optimizer';
    APIGroup = 'Planning';
    APIVersion = 'v1.0';
    EntityName = 'CreateDayPlanning';
    EntitySetName = 'CreateDayPlannings';
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
            part(dayPlanningLines; "DayPlanning Line Opt")
            {
                EntityName = 'dayPlanningLine';
                EntitySetName = 'dayPlanningLines';
                SubPageLink = "Job No." = field("Job No."),
                              "Job Task No." = field("Job Task No.");
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        GlobalSessionVar: Codeunit "Global Session Var Opt.";
    begin
        // BC binds the first nested line once before the header insert (phantom insert) - lines skip while pending
        GlobalSessionVar.SetHeaderInsertPending(true);
        GlobalSessionVar.ResetDayPlanningTemp();
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        JobTask: Record "Job Task";
        GlobalSessionVar: Codeunit "Global Session Var Opt.";
    begin
        GlobalSessionVar.SetHeaderInsertPending(false);

        // Validate the referenced Job Task exists before accepting any day planning lines
        if not JobTask.Get(Rec."Job No.", Rec."Job Task No.") then
            Error('Job Task ''%1 / %2'' does not exist. Create the Job Task in Business Central first.', Rec."Job No.", Rec."Job Task No.");

        // Copy real Job Task data into the temp Rec so SubPageLink fields are correct
        Rec.TransferFields(JobTask, false);
        // Skip Job Task.OnInsert for this temp insert: it writes real Job Task Dimension rows
        BindSubscription(SkipTempJobTaskInsert);
        exit(true); // insert into temp table so the nested part can resolve its SubPageLink
    end;

    var
        SkipTempJobTaskInsert: Codeunit "Skip Temp Job Task Insert Opt."; // page-level: must stay bound until BC inserts after OnInsertRecord

    local procedure GetPostresult(): Text
    var
        DayPlanningTemp: Record "Day Planning" temporary;
        GlobalSessionVar: Codeunit "Global Session Var Opt.";
        ResultJson: JsonObject;
        LinesArray: JsonArray;
        LineJson: JsonObject;
        ResultText: Text;
        ErrLbl: Label 'The day planning Temp record must be temporary.';
    begin
        if not DayPlanningTemp.IsTemporary then
            Error(ErrLbl);

        GlobalSessionVar.GetDayPlanningTemp(DayPlanningTemp);
        DayPlanningTemp.Reset();
        if DayPlanningTemp.FindSet() then
            repeat
                Clear(LineJson);
                LineJson.Add('systemId', DayPlanningTemp.SystemId);
                LineJson.Add('taskDate', Format(DayPlanningTemp."Plan Date", 0, '<Year4>-<Month,2>-<Day,2>'));
                LineJson.Add('dayLineNo', DayPlanningTemp."Day Line No.");
                LineJson.Add('jobNo', DayPlanningTemp."Job No.");
                LineJson.Add('jobTaskNo', DayPlanningTemp."Job Task No.");
                LineJson.Add('assignedResourceNo', DayPlanningTemp."Assigned Resource No.");
                LineJson.Add('description', DayPlanningTemp.Description);
                LineJson.Add('skill', DayPlanningTemp."Skill");
                LineJson.Add('planStatus', Format(DayPlanningTemp."Plan Status"));
                LineJson.Add('startTimeAssigned', Format(DayPlanningTemp."Start Time Assigned", 0, '<Hours24,2>:<Minutes,2>:<Seconds,2>'));
                LineJson.Add('endTimeAssigned', Format(DayPlanningTemp."End Time Assigned", 0, '<Hours24,2>:<Minutes,2>:<Seconds,2>'));
                LineJson.Add('assignedHours', DayPlanningTemp."Assigned Hours");
                LineJson.Add('requestedHours', DayPlanningTemp."Requested Hours");
                LinesArray.Add(LineJson);
            until DayPlanningTemp.Next() = 0;

        ResultJson.Add('DayPlanningLines', LinesArray);
        ResultJson.WriteTo(ResultText);
        exit(ResultText);
    end;

}