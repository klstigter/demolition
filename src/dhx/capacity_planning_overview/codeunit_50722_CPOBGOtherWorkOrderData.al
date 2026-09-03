codeunit 50722 "CPO BG Other WO Data"
{
    // Page Background Task target for page 50722 "Capacity Planning Overview"'s Section 4/cross-
    // Work-Order pagination (see the shared local procedure EnqueueOtherWorkOrderDataBackgroundTask
    // there, called from RefreshData). Modeled directly on src/dhx/request_assignment/
    // codeunit_50721_ReqAssignBGDayTaskLines.al's identical safe-delivery pattern: runs in its own
    // read-only session/transaction on the same server instance - reads only, no writes - so the
    // remainder of a paginated Capacity Planning Overview load (every whole Skill+Job No.+Job Task
    // No. group past the first page - see codeunit "DHX Data Handler"'s
    // CPO_BuildPlanningDataJson_Paged) can be built off the interactive request path and pushed
    // into the control add-in only once ready.
    //
    // 'RemainingGroupKeys' here is always the JSON array of "Skill|JobNo|JobTaskNo" strings
    // produced by the paged call's own pagination decision (CPO_BuildPlanningDataJson_Paged's out
    // parameter) - a concrete list of the specific whole groups still pending, never the page's
    // original (already-fully-handled) MaxOtherLines cutoff - so a single plain
    // CPO_BuildOtherWorkOrderLinesJson_ForKeys call finishes ALL of them in one shot; no further
    // pagination is needed once off the blocking UI thread.
    trigger OnRun()
    var
        DHXDataHandler: Codeunit "DHX Data Handler";
        TaskParameters: Dictionary of [Text, Text];
        Result: Dictionary of [Text, Text];
        WorkOrderNo: Code[20];
        RemainingGroupKeys: Text;
        StartDate: Date;
        EndDate: Date;
        OtherWorkOrderDataJson: Text;
    begin
        TaskParameters := Page.GetBackgroundParameters();

        WorkOrderNo := CopyStr(GetParam(TaskParameters, 'WorkOrderNo'), 1, MaxStrLen(WorkOrderNo));
        RemainingGroupKeys := GetParam(TaskParameters, 'RemainingGroupKeys');
        EvaluateDateParam(TaskParameters, 'StartDate', StartDate);
        EvaluateDateParam(TaskParameters, 'EndDate', EndDate);

        if RemainingGroupKeys <> '' then
            OtherWorkOrderDataJson := DHXDataHandler.CPO_BuildOtherWorkOrderLinesJson_ForKeys(WorkOrderNo, StartDate, EndDate, RemainingGroupKeys);
        // RemainingGroupKeys = '' means nothing was actually pending when this task was enqueued -
        // leave OtherWorkOrderDataJson blank rather than re-building anything.

        Result.Add('otherWorkOrderDataJson', OtherWorkOrderDataJson);
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
        // "YYYY-MM-DD" text, built by the page via Format(..., 0, '<Year4>-<Month,2>-<Day,2>') -
        // same convention as codeunit 50721's identical helper.
        DateText := GetParam(TaskParameters, ParamName);
        if DateText <> '' then
            Evaluate(DateValue, DateText);
    end;
}
