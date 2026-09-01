codeunit 50720 "Task Scheduler BG Sections"
{
    // Page Background Task target for page 50621 "DHX Scheduler (Project)" - see the shared local
    // procedure EnqueuePaginatedSectionsLoad there (called from ControlReady/RefreshSchedule/
    // OnTimelineNavigate). Modeled directly on src/dhx/ganttdemo2/codeunit_50713_GanttBGResourcePanelData.al's
    // safe delivery pattern: runs in its own read-only session/transaction on the same server
    // instance - reads only, no writes - so the remainder of a paginated Task Scheduler load (every
    // Job past the first ~50-row page, see codeunit "DHX Data Handler"'s
    // GetYUnitElementsJSON_Project_Paged) can be built off the interactive request path and pushed
    // into the control add-in only once ready.
    //
    // 'JobFilter' here is always the RemainingJobFilter text produced by the paged call's
    // pagination decision - a concrete "JobA|JobB|..." OR-filter of the specific Jobs still
    // pending, never the original page-level Job filter (blank/wildcard) - so a single plain
    // (non-paged) GetYUnitElementsJSON_Project call finishes ALL of them in one shot; no further
    // pagination is needed once off the blocking UI thread. ResourceFilter/JobTaskFilter are
    // carried through unchanged from whichever of the two page-level filter modes (Resource-only,
    // or Job/Job Task) was active for the page that enqueued this task.
    trigger OnRun()
    var
        DHXDataHandler: Codeunit "DHX Data Handler";
        TaskParameters: Dictionary of [Text, Text];
        Result: Dictionary of [Text, Text];
        ResourceFilter: Text;
        JobFilter: Text;
        JobTaskFilter: Text;
        StartDate: Date;
        EndDate: Date;
        EarliestPlanningDate: Date;
        SectionsJson: Text;
        EventsJson: Text;
    begin
        TaskParameters := Page.GetBackgroundParameters();

        ResourceFilter := GetParam(TaskParameters, 'ResourceFilter');
        JobFilter := GetParam(TaskParameters, 'JobFilter');
        JobTaskFilter := GetParam(TaskParameters, 'JobTaskFilter');
        EvaluateDateParam(TaskParameters, 'StartDate', StartDate);
        EvaluateDateParam(TaskParameters, 'EndDate', EndDate);

        if JobFilter <> '' then
            SectionsJson := DHXDataHandler.GetYUnitElementsJSON_Project(StartDate, StartDate, EndDate,
                ResourceFilter, JobFilter, JobTaskFilter, EventsJson, EarliestPlanningDate);
        // JobFilter = '' means nothing was actually pending when this task was enqueued - leave
        // both results blank rather than re-building the whole (already-delivered) first page.

        Result.Add('sectionsJson', SectionsJson);
        Result.Add('eventsJson', EventsJson);
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
        // same convention as codeunit 50713's identical helper.
        if DateText <> '' then
            Evaluate(DateValue, DateText);
    end;
}
