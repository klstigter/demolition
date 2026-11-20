codeunit 50721 "ReqAssign BG Day Task Lines"
{
    // Page Background Task target for page 50710 "DHX Request Assignment Board"'s Part B.2/B.3
    // pagination (see the shared local procedure EnqueueDayTaskLinesBackgroundTask there, called
    // from RefreshPlanningData). Modeled directly on src/dhx/ganttdemo2/
    // codeunit_50713_GanttBGResourcePanelData.al's and src/dhx/projectschedule/
    // codeunit_50720_TaskSchedulerBGSections.al's safe delivery pattern: runs in its own read-only
    // session/transaction on the same server instance - reads only, no writes - so the remainder
    // of a paginated Request/Assignment Board load (every whole sequenceKey group past the first
    // page - see codeunit "DHX Data Handler"'s ReqAssign_BuildPlanningDataJson_Paged) can be built
    // off the interactive request path and pushed into the control add-in only once ready.
    //
    // 'RemainingSequenceKeys' here is always the JSON array of sequenceKey strings produced by the
    // paged call's own pagination decision (ReqAssign_BuildDayTaskLinesJson_Paged's out
    // parameter) - a concrete list of the specific whole sequenceKey groups still pending, never
    // the page's original (already-fully-handled) MaxLines cutoff - so a single plain
    // ReqAssign_BuildDayTaskLinesJson_ForKeys call finishes ALL of them in one shot; no further
    // pagination is needed once off the blocking UI thread.
    trigger OnRun()
    var
        DHXDataHandler: Codeunit "DHX Data Handler";
        TaskParameters: Dictionary of [Text, Text];
        Result: Dictionary of [Text, Text];
        RemainingSequenceKeys: Text;
        StartDate: Date;
        EndDate: Date;
        DayTaskLinesJson: Text;
    begin
        TaskParameters := Page.GetBackgroundParameters();

        RemainingSequenceKeys := GetParam(TaskParameters, 'RemainingSequenceKeys');
        EvaluateDateParam(TaskParameters, 'StartDate', StartDate);
        EvaluateDateParam(TaskParameters, 'EndDate', EndDate);

        if RemainingSequenceKeys <> '' then
            DayTaskLinesJson := DHXDataHandler.ReqAssign_BuildDayTaskLinesJson_ForKeys(StartDate, EndDate, RemainingSequenceKeys);
        // RemainingSequenceKeys = '' means nothing was actually pending when this task was
        // enqueued - leave DayTaskLinesJson blank rather than re-building anything.

        Result.Add('dayTaskLinesJson', DayTaskLinesJson);
        Page.SetBackgroundTaskResult(Result);
    end;

    local procedure GetParam(TaskParameters: Dictionary of [Text, Text]; ParamName: Text): Text
    begin
        if TaskParameters.ContainsKey(ParamName) then
            exit(TaskParameters.Get(ParamName));
        exit('');
    end;

    local procedure EvaluateDateParam(TaskParameters: Dictionary of [Text, Text]; ParamName: Text; var DateValue: Date)
    var
        DateText: Text;
    begin
        DateText := GetParam(TaskParameters, ParamName);
        // "YYYY-MM-DD" text, built by the page via Format(..., 0, '<Year4>-<Month,2>-<Day,2>') -
        // same convention as codeunit 50713's/50720's identical helper.
        if DateText <> '' then
            Evaluate(DateValue, DateText);
    end;
}
