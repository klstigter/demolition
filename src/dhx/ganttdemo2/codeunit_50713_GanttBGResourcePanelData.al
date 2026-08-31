codeunit 50713 "Gantt BG Resource Panel Data"
{
    // Page Background Task target for page 50620 "Gantt Demo DHX 2"'s resource panel (see
    // EnqueueFilteredResourcePanelReload/EnqueueDefaultResourcePanelReload there). Runs in its own
    // read-only session/transaction on the same server instance - reads only, no writes - so the
    // resource-panel JSON (resources + day plannings) can be built off the interactive request
    // path and pushed into the control add-in only once ready, instead of blocking the Gantt UI
    // while it's assembled.
    //
    // Two scopes, chosen by the 'Mode' input parameter:
    //  - 'Filtered': resources/day plannings scoped to one Job Task + its children (right-click
    //     "Show Job Resources", or a stored-filter reload after drag/drop). Built via
    //     GanttChartDataHandler's Query-based GetDayPlanningsByJobTaskAsJson/
    //     GetResourcesByJobTaskAsJson - a single pass over "Day Planning" per call, no per-Job-Task
    //     round trips. Job Tasks are identified by "JobNo|JobTaskNo" key strings (not Record marks
    //     - marks set on the page's interactive session don't exist in this session).
    //  - 'Default': the unfiltered resource panel (all resources / day plannings for the visible
    //     Gantt period and current Job/Job Task filter), reusing the existing GetResourcesAsJson/
    //     GetDayPlanningsAsJson procedures unchanged.
    //
    // Either LoadResources or LoadDayPlannings (or both) can be requested independently, so a
    // caller that only needs one half (e.g. ShowResourcePanel only wants resources) doesn't pay for
    // building the other.
    trigger OnRun()
    var
        GanttChartDataHandler: Codeunit "GanttChartDataHandler";
        TaskParameters: Dictionary of [Text, Text];
        Result: Dictionary of [Text, Text];
        Mode: Text;
        LoadResources: Boolean;
        LoadDayPlannings: Boolean;
        ResourcesJson: Text;
        DayPlanningsJson: Text;
        JobTaskKeysText: Text;
        JobTaskKeys: List of [Text];
        FromDate: Date;
        ToDate: Date;
        JobFilter: Text;
        JobTaskFilter: Text;
        AnchorDate: Date;
    begin
        TaskParameters := Page.GetBackgroundParameters();

        Mode := GetParam(TaskParameters, 'Mode');
        LoadResources := GetParam(TaskParameters, 'LoadResources') = 'true';
        LoadDayPlannings := GetParam(TaskParameters, 'LoadDayPlannings') = 'true';

        case Mode of
            'Filtered':
                begin
                    JobTaskKeysText := GetParam(TaskParameters, 'JobTaskKeys');
                    if JobTaskKeysText <> '' then
                        JobTaskKeys := JobTaskKeysText.Split(';');
                    EvaluateDateParam(TaskParameters, 'FromDate', FromDate);
                    EvaluateDateParam(TaskParameters, 'ToDate', ToDate);

                    if LoadResources then
                        ResourcesJson := GanttChartDataHandler.GetResourcesByJobTaskAsJson(JobTaskKeys, FromDate, ToDate);
                    if LoadDayPlannings then
                        DayPlanningsJson := GanttChartDataHandler.GetDayPlanningsByJobTaskAsJson(JobTaskKeys, FromDate, ToDate);
                end;
            'Default':
                begin
                    JobFilter := GetParam(TaskParameters, 'JobFilter');
                    JobTaskFilter := GetParam(TaskParameters, 'JobTaskFilter');
                    EvaluateDateParam(TaskParameters, 'AnchorDate', AnchorDate);

                    if LoadResources then
                        ResourcesJson := GanttChartDataHandler.GetResourcesAsJson();
                    if LoadDayPlannings then
                        DayPlanningsJson := GanttChartDataHandler.GetDayPlanningsAsJson(AnchorDate, JobFilter, JobTaskFilter);
                end;
        end;

        Result.Add('resourcesJson', ResourcesJson);
        Result.Add('dayPlanningsJson', DayPlanningsJson);
        Page.SetBackgroundTaskResult(Result);
    end;

    local procedure GetParam(TaskParameters: Dictionary of [Text, Text]; ParamName: Text): Text
    var
        Value: Text;
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
        // same plain Evaluate() already used for this exact format elsewhere on page 50620
        // (e.g. OnShowResourcesForTask's periodFrom/periodTo parsing).
        if DateText <> '' then
            Evaluate(DateValue, DateText);
    end;
}
