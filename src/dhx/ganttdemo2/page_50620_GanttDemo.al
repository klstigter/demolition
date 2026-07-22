page 50620 "Gantt Demo DHX 2"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'Gantt Demo';
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(content)
        {
            // controladdin syntax: controladdin(<ControlId>; <ControlAddInName>)
            usercontrol(DHXGanttControl2; "DHX Gantt Control 2")
            {
                ApplicationArea = All;
                // Height/Width can be adjusted if needed
                trigger OnAfterInit()
                begin
                    setup.EnsureUserRecord();
                    setup.get(UserId);

                end;

                trigger ControlReady()

                begin
                    setup.EnsureUserRecord();
                    setup.get(UserId);
                    LoadAllData();
                    ResourcePanelFlag := false;
                    CurrPage.DHXGanttControl2.SetResourcePanelVisibility(ResourcePanelFlag);
                end;

                trigger onTaskDblClick(eventId: Text; eventData: Text)
                var
                    DHXDataHandler: Codeunit "DHX Data Handler";
                    PossibleChanges: Boolean;
                    newEventData: Text;
                    EventIDList: List of [Text];
                    JobNo: Code[20];
                    TaskNo: Code[20];
                begin
                    EventIDList := eventId.Split('|');
                    JobNo := EventIDList.Get(1);
                    TaskNo := EventIDList.Get(2);
                    PageHandler.OpenJobTaskCard(JobNo, TaskNo);
                    // Get the latest data after possible changes in day plannings
                    if PossibleChanges then begin
                        if DHXDataHandler.GetEventDataFromEventId(eventId, newEventData) then
                            CurrPage.DHXGanttControl2.RefreshEventData(newEventData); //update event ID
                    end;
                end;

                trigger OnShowSummaryForTask(taskId: Text; childrenJson: Text; periodFrom: Text; periodTo: Text)
                var
                    SummaryPage: Page "Summary View";
                    EventIDList: List of [Text];
                    JobNo: Code[20];
                    JobTaskNo: Code[20];
                    FromDate: Date;
                    ToDate: Date;
                begin
                    //message('taskId: %1, childrenJson: %2, periodFrom: %3, periodTo: %4', taskId, childrenJson, periodFrom, periodTo);
                    /*
                    taskId: JOB001|2, 
                    childrenJson: 
                        [
                            {"id":"JOB001|2010","text":"2010 - Spare Parts Procurement","bcJobNo":"JOB001","bcJobTaskNo":"2010","start_date":"2026-05-26","end_date":"2026-06-05"},
                            {"id":"JOB001|2020","text":"2020 - Remove old and install new parts","bcJobNo":"JOB001","bcJobTaskNo":"2020","start_date":"2026-05-27","end_date":"2026-05-29"},
                            {"id":"JOB001|2030","text":"2030 - Cat and bodywork","bcJobNo":"JOB001","bcJobTaskNo":"2030","start_date":"2026-05-28","end_date":"2026-06-04"}
                        ], 
                    periodFrom: 2026-05-25, 
                    periodTo: 2026-06-06
                    */
                    // Parse Job No. and Job Task No. from the composite task id ("JobNo|JobTaskNo")
                    EventIDList := taskId.Split('|');
                    if EventIDList.Count() >= 2 then begin
                        JobNo := CopyStr(EventIDList.Get(1), 1, 20);
                        JobTaskNo := CopyStr(EventIDList.Get(2), 1, 20);
                    end;
                    SummaryPage.LoadDataSet(JobNo, JobTaskNo);
                    SummaryPage.SetJobAndJobTaskVisibility(False);
                    SummaryPage.Run();
                end;

                trigger OnShowResourcesForTask(taskId: Text; childrenJson: Text; periodFrom: Text; periodTo: Text)
                var
                    JobTask: Record "Job Task";
                    EventIDList: List of [Text];
                    JobNo: Code[20];
                    JobTaskNo: Code[20];
                    FromDate: Date;
                    ToDate: Date;
                    ChildrenArray: JsonArray;
                    ChildToken: JsonToken;
                    ChildObj: JsonObject;
                    IdToken: JsonToken;
                    ChildIdTxt: Text;
                    ChildIdParts: List of [Text];
                    ChildJobNo: Code[20];
                    ChildJobTaskNo: Code[20];
                begin
                    // Parse Job No. and Job Task No. from the composite task id ("JobNo|JobTaskNo")
                    EventIDList := taskId.Split('|');
                    if EventIDList.Count() >= 2 then begin
                        JobNo := CopyStr(EventIDList.Get(1), 1, 20);
                        JobTaskNo := CopyStr(EventIDList.Get(2), 1, 20);
                        if JobTask.Get(JobNo, JobTaskNo) then
                            JobTask.Mark(true);
                    end;

                    // Parse childrenJson to get Job No. and Job Task No., after that marking on JobTask
                    if (childrenJson <> '') and (childrenJson <> '[]') then
                        if ChildrenArray.ReadFrom(childrenJson) then
                            foreach ChildToken in ChildrenArray do begin
                                ChildObj := ChildToken.AsObject();
                                if ChildObj.Get('id', IdToken) then begin
                                    ChildIdTxt := IdToken.AsValue().AsText();
                                    ChildIdParts := ChildIdTxt.Split('|');
                                    if ChildIdParts.Count() >= 2 then begin
                                        ChildJobNo := CopyStr(ChildIdParts.Get(1), 1, 20);
                                        ChildJobTaskNo := CopyStr(ChildIdParts.Get(2), 1, 20);
                                        if JobTask.Get(ChildJobNo, ChildJobTaskNo) then
                                            JobTask.Mark(true);
                                    end;
                                end;
                            end;

                    // Parse period dates (format: YYYY-MM-DD from JS)
                    if periodFrom <> '' then
                        Evaluate(FromDate, periodFrom);
                    if periodTo <> '' then
                        Evaluate(ToDate, periodTo);

                    // Show the resource panel
                    ResourcePanelFlag := true;
                    CurrPage.DHXGanttControl2.SetResourcePanelVisibility(true);

                    // Pass filter context for the header tooltip
                    CurrPage.DHXGanttControl2.SetResourcePanelFilterInfo(JobNo, JobTaskNo, Format(FromDate, 0, '<Year4>-<Month,2>-<Day,2>'), Format(ToDate, 0, '<Year4>-<Month,2>-<Day,2>'));

                    // Load resources and day plannings filtered to this task (and its children)
                    LoadFilteredResourcesAndDayPlannings(JobTask, FromDate, ToDate);

                    CurrPage.DHXGanttControl2.GetResourceFilter(); // Get the active resource filter and saved it into global page var
                end;

                trigger onOpenDayPlanning(taskId: Text; eventData: Text)
                var
                    JobTask: Record "Job Task";
                    JsonObj: JsonObject;
                    JsonToken: JsonToken;
                    JobNo: Code[20];
                    JobTaskNo: Code[20];
                    DayPlanning: Record "Day Planning";
                    EventIDList: List of [Text];
                begin
                    // Parse bcJobNo / bcJobTaskNo from eventData JSON
                    if JsonObj.ReadFrom(eventData) then begin
                        if JsonObj.Get('bcJobNo', JsonToken) then
                            JobNo := CopyStr(JsonToken.AsValue().AsText(), 1, MaxStrLen(JobNo));
                        if JsonObj.Get('bcJobTaskNo', JsonToken) then
                            JobTaskNo := CopyStr(JsonToken.AsValue().AsText(), 1, MaxStrLen(JobTaskNo));
                    end;

                    // Fallback: try splitting legacy id format "JobNo|JobTaskNo"
                    if (JobNo = '') and taskId.Contains('|') then begin
                        EventIDList := taskId.Split('|');
                        JobNo := CopyStr(EventIDList.Get(1), 1, MaxStrLen(JobNo));
                        JobTaskNo := CopyStr(EventIDList.Get(2), 1, MaxStrLen(JobTaskNo));
                    end;

                    if JobNo <> '' then
                        DayPlanning.SetRange("Job No.", JobNo);
                    if JobTaskNo <> '' then
                        DayPlanning.SetRange("Job Task No.", JobTaskNo);
                    if (JobNo <> '') and (JobTaskNo <> '') then begin
                        JobTask.Get(JobNo, JobTaskNo);
                        case true of
                            (JobTask.PlannedStartDate <> 0D) and (JobTask.PlannedEndDate <> 0D):
                                DayPlanning.SetRange("Work Date", JobTask.PlannedStartDate, JobTask.PlannedEndDate);
                            (JobTask.PlannedStartDate = 0D) and (JobTask.PlannedEndDate <> 0D):
                                DayPlanning.Setfilter("Work Date", '..%1', JobTask.PlannedEndDate);
                            (JobTask.PlannedStartDate <> 0D) and (JobTask.PlannedEndDate = 0D):
                                DayPlanning.Setfilter("Work Date", '%1..', JobTask.PlannedStartDate);
                        end;

                    end;
                    Page.Run(Page::"Day Plannings", DayPlanning);
                end;

                trigger onOpenDayPlanningVisual(taskId: Text; eventData: Text)
                var
                    JsonObj: JsonObject;
                    JsonToken: JsonToken;
                    JobNo: Code[20];
                    JobTaskNo: Code[20];
                    DayPlanning: Record "Day Planning";
                    EventIDList: List of [Text];
                    DayPlanningScheduler: page "DHX Scheduler (Project)";
                begin
                    // Parse bcJobNo / bcJobTaskNo from eventData JSON
                    if JsonObj.ReadFrom(eventData) then begin
                        if JsonObj.Get('bcJobNo', JsonToken) then
                            JobNo := CopyStr(JsonToken.AsValue().AsText(), 1, MaxStrLen(JobNo));
                        if JsonObj.Get('bcJobTaskNo', JsonToken) then
                            JobTaskNo := CopyStr(JsonToken.AsValue().AsText(), 1, MaxStrLen(JobTaskNo));
                    end;

                    // Fallback: try splitting legacy id format "JobNo|JobTaskNo"
                    if (JobNo = '') and taskId.Contains('|') then begin
                        EventIDList := taskId.Split('|');
                        JobNo := CopyStr(EventIDList.Get(1), 1, MaxStrLen(JobNo));
                        JobTaskNo := CopyStr(EventIDList.Get(2), 1, MaxStrLen(JobTaskNo));
                    end;

                    if JobNo <> '' then
                        DayPlanning.SetRange("Job No.", JobNo);
                    if JobTaskNo <> '' then
                        DayPlanning.SetRange("Job Task No.", JobTaskNo);

                    DayPlanningScheduler.SetJobTaskFilter(JobNo, JobTaskNo);
                    DayPlanningScheduler.Run();
                end;

                trigger OnJobTaskUpdated(eventData: Text)
                var
                    GantUpdatedata: Codeunit "Gantt Update Data";
                begin
                    // Guard: RenderGantt(true) suppresses only the first onAfterTaskUpdate
                    // in JS; a second event (e.g. from auto-scheduling cascade) still fires
                    // and would re-open the preview. PreviewCancelled absorbs that re-entry.
                    if PreviewCancelled then begin
                        PreviewCancelled := false;
                        exit;
                    end;

                    // UpdateJobTaskFromJson returns false when the user closed the
                    // DayPlanning Period Sync Preview popup without clicking Apply Changes
                    // (OnClosePage fires on the preview page, Applied stays false).
                    // In that case reload task + link data so the Gantt bar reverts to
                    // the original DB position instead of staying at the dragged spot.
                    if not GantUpdatedata.UpdateJobTaskFromJson(eventData) then begin
                        PreviewCancelled := true; // absorb the RenderGantt re-entry event
                        LoadTaskData();
                        LoadLinkData();
                        LoadDayPlanningData();
                        CurrPage.DHXGanttControl2.RenderGantt(true); // force full re-render to reset task positions
                        exit;
                    end;
                    LoadDayPlanningData();
                end;

                trigger OpenResourceLoadDay(ResourceId: Text; pWorkDate: Text; pPlanStatus: Text; pIdList: Text)
                var
                    DayPlanning: Record "Day Planning";
                    WorkDt: Date;
                    Tp: array[2] of text;
                    IdList: List of [Text];
                    IdText: Text;
                    SysId: Guid;
                    JobNos: List of [Text];
                    JobTaskNos: List of [Text];
                    JobNoFilter: Text;
                    JobTaskNoFilter: Text;
                begin
                    // Step 1: build Job No. and Job Task No. filter strings from pIdList
                    if pIdList <> '' then begin
                        IdList := pIdList.Split('|');
                        foreach IdText in IdList do
                            if Evaluate(SysId, IdText) then begin
                                DayPlanning.Reset();
                                if DayPlanning.GetBySystemId(SysId) then begin
                                    if not JobNos.Contains(DayPlanning."Job No.") then
                                        JobNos.Add(DayPlanning."Job No.");
                                    if not JobTaskNos.Contains(DayPlanning."Job Task No.") then
                                        JobTaskNos.Add(DayPlanning."Job Task No.");
                                end;
                            end;
                        foreach IdText in JobNos do begin
                            if JobNoFilter <> '' then JobNoFilter += '|';
                            JobNoFilter += IdText;
                        end;
                        foreach IdText in JobTaskNos do begin
                            if JobTaskNoFilter <> '' then JobTaskNoFilter += '|';
                            JobTaskNoFilter += IdText;
                        end;
                    end;

                    // Step 2: apply all filters (date, resource, plan status, job/task from idList)
                    tp[1] := CopyStr(ResourceId, 1, 4);
                    tp[2] := CopyStr(ResourceId, 5);
                    DayPlanning.Reset();
                    if JobNoFilter <> '' then
                        DayPlanning.SetFilter("Job No.", JobNoFilter)
                    else if JobFilter <> '' then
                        DayPlanning.SetFilter("Job No.", JobFilter);
                    if JobTaskNoFilter <> '' then
                        DayPlanning.SetFilter("Job Task No.", JobTaskNoFilter);
                    Evaluate(WorkDt, pWorkDate);
                    DayPlanning.SetRange("Work Date", WorkDt);
                    if pPlanStatus = 'Request' then begin
                        if tp[1] = 'RES-' then
                            DayPlanning.SetRange("Requested Resource No.", tp[2]);
                        if tp[1] = 'VEN-' then
                            DayPlanning.SetRange("Vendor No.", tp[2]);
                    end else begin
                        if tp[1] = 'RES-' then
                            DayPlanning.SetRange("Assigned Resource No.", tp[2]);
                        if tp[1] = 'VEN-' then
                            DayPlanning.SetRange("Vendor No.", tp[2]);
                    end;
                    Page.RunModal(Page::"Day Plannings", DayPlanning);
                    RefreshGantt();
                end;

                trigger OnLinkCreated(linkData: Text)
                begin
                    // Fired from dhtmlx when user draws a new dependency arrow
                    if not LinkHandler.UpsertLinkFromJson(linkData) then
                        Message('Failed to save link. Please check the link data.');
                end;

                trigger OnLinkDeleted(linkData: Text)
                begin
                    // Fired from dhtmlx when user removes a dependency arrow
                    LinkHandler.DeleteLinkFromJson(linkData);
                end;

                trigger OnResourceDblClick(resourceId: Text)
                var
                    Resource: Record Resource;
                    ResourceCode: Code[20];
                begin
                    if not resourceId.StartsWith('RES-') then exit;
                    ResourceCode := CopyStr(resourceId, 5, MaxStrLen(ResourceCode));
                    if Resource.Get(ResourceCode) then
                        Page.Run(Page::"Resource Card", Resource);
                end;

                trigger onAddDayPlanning(resourceId: Text; workDate: Text)
                var
                    DayPlanning: Record "Day Planning";
                    WorkHourTemplate: record "Work-Hour Template";
                    DayPlanningCard: Page "Day Planning Card - New Record";
                    WorkDt: Date;
                    Prefix: Text[4];
                    ResourceCode: Code[20];
                    IsTemp: Boolean;
                    FilterJson: JsonObject;
                    FilterToken: JsonToken;
                    FilterJobNo: Code[20];
                    FilterJobTaskNo: Code[20];
                    FilterFromDate: Date;
                    FilterToDate: Date;
                begin
                    Evaluate(WorkDt, workDate); // expects YYYY-MM-DD
                    Prefix := CopyStr(resourceId, 1, 4);
                    ResourceCode := CopyStr(resourceId, 5, MaxStrLen(ResourceCode));
                    DayPlanning.Init();
                    DayPlanning."Work Date" := WorkDt;
                    if Prefix = 'RES-' then begin
                        // Validate("Requested Resource No.", ...) can Error() (e.g. the resource
                        // has no Skill assigned - see table_50610's mandatory-skill check). Wrapped
                        // in a TryFunction + friendly Message() rather than letting that raw error
                        // propagate through the Gantt JS bridge, same "if not X then Message(...)"
                        // surfacing convention already used by OnLinkCreated (UpsertLinkFromJson)
                        // above in this same page. Underlying validation/blocking behavior is
                        // unchanged - the drop is still refused, just with a clean message instead
                        // of an unhandled error.
                        if not TryValidateRequestedResourceNo(DayPlanning, ResourceCode) then begin
                            Message('Cannot add this Day Planning: %1', GetLastErrorText());
                            exit;
                        end;
                    end else
                        if Prefix = 'VEN-' then
                            DayPlanning.Validate("Vendor No.", ResourceCode);
                    DayPlanning."Plan Status" := DayPlanning."Plan Status"::"In Request";
                    if OptiSetup."Work hour Template" <> '' then begin
                        WorkHourTemplate.Get(OptiSetup."Work hour Template");
                        DayPlanning."Non Working Minutes Assigned" := WorkHourTemplate."Non Working Minutes";
                        DayPlanning.Validate("Start Time Requested", WorkHourTemplate."Default Start Time");
                        DayPlanning.Validate("End Time Requested", WorkHourTemplate."Default End Time");
                        DayPlanning."Requested Hours" := WorkHourTemplate."Working Hours";
                    end;
                    if CurrentResourcePanelFilterJsonString <> '' then
                        if FilterJson.ReadFrom(CurrentResourcePanelFilterJsonString) then begin
                            // Extract filter fields stored by SetResourcePanelFilterInfo: { job, task, periodFrom, periodTo }
                            if FilterJson.Get('job', FilterToken) then
                                FilterJobNo := CopyStr(FilterToken.AsValue().AsText(), 1, MaxStrLen(FilterJobNo));
                            if FilterJson.Get('task', FilterToken) then
                                FilterJobTaskNo := CopyStr(FilterToken.AsValue().AsText(), 1, MaxStrLen(FilterJobTaskNo));
                            if FilterJson.Get('periodFrom', FilterToken) then
                                Evaluate(FilterFromDate, FilterToken.AsValue().AsText());
                            if FilterJson.Get('periodTo', FilterToken) then
                                Evaluate(FilterToDate, FilterToken.AsValue().AsText());

                            DayPlanning.Validate("Job No.", FilterJobNo);
                            DayPlanning.Validate("Job Task No.", FilterJobTaskNo);
                        end;

                    DayPlanning.CalculateWorkingHours();
                    Clear(DayPlanningCard);
                    DayPlanningCard.LookupMode(true);
                    DayPlanningCard.SetNewRecordToSave(DayPlanning);
                    if DayPlanningCard.RunModal() = Action::LookupOK then begin
                        DayPlanningCard.GetRecord(DayPlanning);
                        DayPlanning.TestField("Job No.");
                        DayPlanning.TestField("Job Task No.");
                        DayPlanning.TestField("Work Date");

                        if DayPlanning."Plan Status" = DayPlanning."Plan Status"::"In Progress" then begin
                            DayPlanning.TestField("Assigned Resource No.");
                            DayPlanning.TestField("Assigned Hours");
                            DayPlanning.TestField("Start Time Assigned");
                            DayPlanning.TestField("End Time Assigned");
                        end;

                        DayPlanning.CheckDayPlanningDateInProjectTaskRange();
                        DayPlanning.GetNextDayLineNo();
                        DayPlanning.Insert(true);
                    end;
                    RefreshGantt();
                end;

                trigger onOpenResourceScheduler(resourceId: Text)
                var
                    ResScheduler: page "DHX Resource Scheduler";
                    DHXDataHandler: Codeunit "DHX Data Handler";
                    TextList: List of [Text];
                    ResNo: Code[20];
                    GanttStart: Date;
                    GanttEnd: Date;
                    WeekStart: Date;
                    WeekEnd: Date;
                    WeekStartDate: List of [Date];
                    WeekEndDate: List of [Date];
                    OptionString: Text;
                    OptionItem: Text;
                    Selection: Integer;
                    WeekIdx: Integer;
                begin
                    if StrPos(resourceId, '-') = 0 then begin
                        Message('Invalid resource ID format: %1, resource ID should be in the format "TYPE-ID", ex. RES-1234', resourceId);
                        exit;
                    end;
                    TextList := resourceId.Split('-');
                    Evaluate(ResNo, TextList.Get(2)); // expects format like "RES-1234"

                    // Derive the active Gantt period from current setup and anchor date
                    GanttChartDataHandler.GetDateRange(Setup, AnchorDate, GanttStart, GanttEnd);

                    // Build week lists by walking the Gantt period week by week
                    DHXDataHandler.GetWeekPeriodDates(GanttStart, WeekStart, WeekEnd);
                    while WeekStart <= GanttEnd do begin
                        WeekStartDate.Add(WeekStart);
                        WeekEndDate.Add(WeekEnd);
                        WeekStart := CalcDate('<1W>', WeekStart);
                        WeekEnd := CalcDate('<1W>', WeekEnd);
                    end;

                    if WeekStartDate.Count() = 0 then begin
                        Message('No weeks found in the current Gantt period (%1 – %2).', GanttStart, GanttEnd);
                        exit;
                    end;

                    // Build dynamic option string using actual calendar week numbers: "W09: 24-02-2026 – 01-03-2026, ..."
                    for WeekIdx := 1 to WeekStartDate.Count() do begin
                        OptionItem := StrSubstNo('W%1: %2 – %3',
                            Format(Date2DWY(WeekStartDate.Get(WeekIdx), 2), 0, '<Integer,2>'),
                            Format(WeekStartDate.Get(WeekIdx), 0, '<Day,2>-<Month,2>-<Year4>'),
                            Format(WeekEndDate.Get(WeekIdx), 0, '<Day,2>-<Month,2>-<Year4>'));
                        if OptionString <> '' then
                            OptionString += ',';
                        OptionString += OptionItem;
                    end;

                    // Standard BC popup for option selection (returns 0 on cancel)
                    Selection := StrMenu(OptionString, 1, 'Select a week to open the Resource Scheduler');
                    if Selection = 0 then
                        exit;

                    ResScheduler.SetResourceFilter(ResNo, WeekStartDate.Get(Selection), WeekEndDate.Get(Selection));
                    ResScheduler.Run();
                end;

                trigger OnResetResourceFilter()
                begin
                    // User clicked the (ℹ) button — clear the task-based resource filter
                    // and reload all resources + all day plannings driven by the default Gantt context.
                    ClearResourcePanelFilter();
                    LoadResourceData();
                    LoadDayPlanningData();
                end;

                trigger OnResourceFilterRetrieved(filterJson: Text)
                begin
                    CurrentResourcePanelFilterJsonString := filterJson;
                end;
            }
        }

    }

    actions
    {
        area(Processing)
        {
            action(GetJsonTasks)
            {
                Caption = 'Get JSON Tasks Data';
                Image = View;
                ApplicationArea = All;

                trigger OnAction()
                var
                    JsonTxt: Text;
                    tempblob: Codeunit "Temp Blob";
                    instream: InStream;
                    outstream: OutStream;
                    va: variant;
                begin
                    JsonTxt := GanttChartDataHandler.GetJobTasksAsJson(AnchorDate, JobFilter);
                    tempblob.CreateOutStream(outstream);
                    outstream.WriteText(JsonTxt);
                    tempblob.CreateInStream(instream);
                    va := 'data.json';
                    DownloadFromStream(instream, 'JobTasksGanttData.json', '', 'application/json', va);
                end;
            }
            action(GetJsonResources)
            {
                Caption = 'Get JSON Resources Data';
                Image = View;
                ApplicationArea = All;

                trigger OnAction()
                var
                    JsonTxt: Text;
                    tempblob: Codeunit "Temp Blob";
                    instream: InStream;
                    outstream: OutStream;
                    va: variant;
                begin
                    JsonTxt := GanttChartDataHandler.GetResourcesAsJson();
                    tempblob.CreateOutStream(outstream);
                    outstream.WriteText(JsonTxt);
                    tempblob.CreateInStream(instream);
                    va := 'data.json';
                    DownloadFromStream(instream, 'JobTasksGanttData.json', '', 'application/json', va);
                end;
            }
            action(GetJsonDayPlannings)
            {
                Caption = 'Get JSON Day Plannings Data';
                Image = View;
                ApplicationArea = All;

                trigger OnAction()
                var
                    JsonTxt: Text;
                    tempblob: Codeunit "Temp Blob";
                    instream: InStream;
                    outstream: OutStream;
                    va: variant;
                    JobFilterUsed: Text;
                begin
                    JobFilterUsed := setup."Job No. Filter";
                    if JobFilter <> '' then
                        JobFilterUsed := JobFilter; // override with global filter if set
                    JsonTxt := GanttChartDataHandler.GetDayPlanningsAsJson(Setup."From Date", JobFilterUsed, '');
                    tempblob.CreateOutStream(outstream);
                    outstream.WriteText(JsonTxt);
                    tempblob.CreateInStream(instream);
                    va := 'data.json';
                    DownloadFromStream(instream, 'JobTasksGanttData.json', '', 'application/json', va);
                end;
            }
            action(GanttSettings)
            {
                Caption = 'Gantt Settings';
                Image = Setup;
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Page.Run(Page::"Gantt Chart Setup");
                    setup.get(UserId);
                    CurrPage.DHXGanttControl2.SetColumnVisibility(
                     Setup."Show Start Date",
                     Setup."Show Duration",
                     Setup."Show Task Type");
                    CurrPage.DHXGanttControl2.LoadProject(Setup."From Date", Setup."To Date");
                    CurrPage.Update(false); // reapply settings after close
                end;
            }
            action(Undo)
            {
                ApplicationArea = All;
                Caption = 'Undo';
                Image = Undo;
                trigger OnAction()
                begin
                    CurrPage.DHXGanttControl2.Undo();
                end;
            }

            action(Redo)
            {
                ApplicationArea = All;
                Caption = 'Redo';
                Image = Redo;
                trigger OnAction()
                begin
                    CurrPage.DHXGanttControl2.Redo();
                end;
            }
            action("AddMarker")
            {
                ApplicationArea = All;
                Caption = 'Add Marker';
                Image = Add;
                trigger OnAction()
                begin
                    CurrPage.DHXGanttControl2.AddMarker('2024-06-15', 'New Marker');
                end;
            }
            action("RefreshData")
            {
                ApplicationArea = All;
                Caption = 'Refresh Data';
                Image = Refresh;
                trigger OnAction()
                begin
                    RefreshGantt();
                end;
            }
        }

        area(Navigation)
        {
            action(Summary)
            {
                Caption = 'Summary';
                Image = BusinessRelation;
                ApplicationArea = All;

                trigger OnAction()
                var
                    SummaryPage: Page "Summary View";
                    Direction: Option Forward,Backward;
                    DT1: Date;
                    DT2: Date;
                begin
                    GanttChartDataHandler.GetDateRange(Setup, AnchorDate, DT1, DT2);
                    SummaryPage.LoadDataSet(StrSubstNo('%1..%2', DT1, DT2));
                    SummaryPage.SetDefaultView();
                    SummaryPage.Run();
                end;
            }
            action(DayTaks)
            {
                Caption = 'Day Plannings';
                ApplicationArea = All;
                image = AbsenceCalendar;

                trigger OnAction()
                var
                    DayPlanning: Record "Day Planning";
                    Direction: Option Forward,Backward;
                    DT1: Date;
                    DT2: Date;
                    PanelJson: JsonObject;
                    PanelToken: JsonToken;
                    PanelJobNo: Code[20];
                    PanelTaskNo: Code[20];
                    PanelFromDate: Date;
                    PanelToDate: Date;
                begin
                    GanttChartDataHandler.GetDateRange(Setup, AnchorDate, DT1, DT2);

                    if (CurrentResourcePanelFilterJsonString <> '') and
                       PanelJson.ReadFrom(CurrentResourcePanelFilterJsonString) then begin
                        if PanelJson.Get('job', PanelToken) then
                            PanelJobNo := CopyStr(PanelToken.AsValue().AsText(), 1, MaxStrLen(PanelJobNo));
                        if PanelJson.Get('task', PanelToken) then
                            PanelTaskNo := CopyStr(PanelToken.AsValue().AsText(), 1, MaxStrLen(PanelTaskNo));
                        if PanelJson.Get('periodFrom', PanelToken) then
                            Evaluate(PanelFromDate, PanelToken.AsValue().AsText());
                        if PanelJson.Get('periodTo', PanelToken) then
                            Evaluate(PanelToDate, PanelToken.AsValue().AsText());

                        if (PanelJobNo <> '') and (PanelTaskNo <> '') then begin
                            if PanelFromDate <> 0D then DT1 := PanelFromDate;
                            if PanelToDate <> 0D then DT2 := PanelToDate;
                            DayPlanning.SetRange("Work Date", DT1, DT2);
                            DayPlanning.SetFilter("Job No.", PanelJobNo);
                            DayPlanning.SetFilter("Job Task No.", PanelTaskNo);
                            page.Run(Page::"Day Plannings", DayPlanning);
                            exit;
                        end;
                    end;

                    DayPlanning.SetRange("Work Date", DT1, DT2);
                    if JobFilter <> '' then
                        DayPlanning.SetFilter("Job No.", JobFilter);
                    page.Run(Page::"Day Plannings", DayPlanning);
                end;
            }
            action(projects)
            {
                Caption = 'Projects';
                ApplicationArea = All;
                image = Task;

                trigger OnAction()
                var
                    job: Record "Job";
                    Pg: Page "Opti Job List";
                    Direction: Option Forward,Backward;
                    DT1: Date;
                    DT2: Date;
                begin
                    //GanttChartDataHandler.GetDateRange(Setup, AnchorDate, DT1, DT2);
                    //jobTask.SetFilter("Planning Date Filter", '%1..%2', DT1, DT2);
                    //jobTask.SetAutoCalcFields("Total Day Plannings");
                    //jobTask.SetFilter("Total Day Plannings", '>0');
                    //if JobFilter <> '' then
                    job.SetFilter("No.", JobFilter);
                    if job.FindSet() then;
                    Job.setrange("No.");
                    pg.SetRecord(job);
                    pg.Run();
                end;
            }

            action(projectTasks)
            {
                Caption = 'Project Tasks';
                ApplicationArea = All;
                image = Task;

                trigger OnAction()
                var
                    jobTask: Record "Job Task";
                    DT1: Date;
                    DT2: Date;
                begin
                    GanttChartDataHandler.GetDateRange(Setup, AnchorDate, DT1, DT2);
                    jobTask.SetFilter(PlannedStartDate, '<=%1', DT2);
                    jobTask.SetFilter(PlannedEndDate, '>=%1', DT1);
                    jobTask.SetFilter("Job Task Type", '<>%1&<>%2',
                        jobTask."Job Task Type"::"End-Total",
                        jobTask."Job Task Type"::Total);
                    if JobFilter <> '' then
                        jobTask.SetFilter("Job No.", JobFilter);
                    page.Run(Page::"Job Task List - Project", jobTask);
                end;
            }

            action(ShowResourcePanel)
            {
                Caption = 'Show Resource Panel';
                ApplicationArea = All;
                Image = Resource;
                Visible = not ResourcePanelFlag;

                trigger OnAction()
                begin
                    ResourcePanelFlag := true;
                    CurrPage.DHXGanttControl2.SetResourcePanelVisibility(true);
                    ClearResourcePanelFilter(); // clear any existing filter context when manually showing the panel, to avoid confusion
                    LoadResourceData();
                end;
            }
            action(HideResourcePanel)
            {
                Caption = 'Hide Resource Panel';
                ApplicationArea = All;
                Image = Resource;
                Visible = ResourcePanelFlag;

                trigger OnAction()
                begin
                    ResourcePanelFlag := false;
                    CurrPage.DHXGanttControl2.SetResourcePanelVisibility(false);
                end;
            }

            action(TodayAct)
            {
                Caption = 'Today';
                ApplicationArea = All;
                Image = Position;
                Visible = ShowPreviousNext;
                trigger OnAction()
                begin
                    AnchorDate := Today();
                    RefreshGantt();
                end;
            }
            action(PreviousAct)
            {
                Caption = 'Previous';
                ApplicationArea = All;
                Image = PreviousSet;
                Visible = ShowPreviousNext;

                trigger OnAction()
                var
                    forDt: text;
                    Direction: Option Forward,Backward;
                begin
                    AnchorDate := CalcNewAnchorDate(Direction::Backward);
                    RefreshGantt();
                end;
            }

            action(NextAct)
            {
                Caption = 'Next';
                ApplicationArea = All;
                Image = NextSet;
                Visible = ShowPreviousNext;
                trigger OnAction()
                var
                    forDt: text;
                    Direction: Option Forward,Backward;
                begin
                    AnchorDate := CalcNewAnchorDate(Direction::Forward);
                    RefreshGantt();
                end;
            }
            action(CheckGanttDataAct)
            {
                Caption = 'Check Gantt Data';
                ApplicationArea = All;
                Image = Check;

                trigger OnAction()
                begin
                    CurrPage.DHXGanttControl2.GetGanttData();
                end;
            }
            action(CheckPagePeriod)
            {
                Caption = 'Check Page Period';
                ApplicationArea = All;
                Image = Check;

                trigger OnAction()
                Var
                    DT1: Date;
                    DT2: Date;
                begin
                    GanttChartDataHandler.GetDateRange(Setup, AnchorDate, DT1, DT2);
                    Message('Checking Gantt data integrity for period %1 to %2 from anchor date %3', DT1, DT2, AnchorDate);
                end;
            }
            action(CheckResourcvePanelFilter)
            {
                Caption = 'Check Resource Panel Filter';
                ApplicationArea = All;
                Image = Check;

                trigger OnAction()
                begin
                    CurrPage.DHXGanttControl2.GetResourceFilter();
                    Message('Current Resource Panel Filter JSON: %1', CurrentResourcePanelFilterJsonString);
                end;
            }
            action(ShowResourcesForTask)
            {
                Caption = 'Show Resources for Task';
                ApplicationArea = All;
                Image = ResourcePlanning;
                Visible = false; // triggered via right-click only

                trigger OnAction()
                begin
                    // Intentionally empty; invoked programmatically via OnShowResourcesForTask event
                end;
            }
            action(TestClearData)
            {
                Caption = 'Clear Gantt Data';
                ApplicationArea = All;
                Image = RemoveLine;

                trigger OnAction()
                begin
                    CurrPage.DHXGanttControl2.ClearData();
                end;
            }
        }
        area(Reporting)
        {
            action(DayResourceDetail)
            {
                Caption = 'Day Resource Detail';
                ApplicationArea = All;
                Image = Report;
                trigger OnAction()
                var
                    DayResourceDetails: Report "Day Resource Details";
                    StartDate: Date;
                    EndDate: Date;
                begin
                    GanttChartDataHandler.GetDateRange(Setup, AnchorDate, StartDate, EndDate);
                    DayResourceDetails.SetDataViewDateRange(StartDate, EndDate);
                    DayResourceDetails.Run();
                end;
            }
            action(DayPlanningsDetail)
            {
                Caption = 'Day Overview';
                ApplicationArea = All;
                Image = Report;
                trigger OnAction()
                var
                    DayPlanningDetails: Report "Day Planning Details";
                    StartDate: Date;
                    EndDate: Date;
                begin
                    GanttChartDataHandler.GetDateRange(Setup, AnchorDate, StartDate, EndDate);
                    DayPlanningDetails.SetDataViewDateRange(StartDate, EndDate);
                    DayPlanningDetails.Run();
                end;
            }
            action(DayPlanningsWeekOverview)
            {
                Caption = 'Week Overview';
                ApplicationArea = All;
                Image = Report;
                trigger OnAction()
                var
                    DayPlanning: Report "DayPlanning";
                    StartDate: Date;
                    EndDate: Date;
                begin
                    GanttChartDataHandler.GetDateRange(Setup, AnchorDate, StartDate, EndDate);
                    DayPlanning.SetDataViewDateRange(StartDate, EndDate);
                    DayPlanning.Run();
                end;
            }// Placeholder for any future reports related to the Gantt data
            action(DailyCapacityBalanceReport)
            {
                Caption = 'Daily Capacity Balance Report';
                ApplicationArea = All;
                Image = Report;
                trigger OnAction()
                var
                    CapacityBalance: Report "Daily Capacity Balance Report";
                    StartDate: Date;
                    EndDate: Date;
                begin
                    GanttChartDataHandler.GetDateRange(Setup, AnchorDate, StartDate, EndDate);
                    CapacityBalance.SetDataViewDateRange(StartDate, EndDate);
                    CapacityBalance.Run();
                end;
            }
        }


        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Actions';
                actionref(GanttSettings_ref; GanttSettings) { }
                actionref("UodoPromoted"; Undo) { }
                actionref("RedoPromoted"; Redo) { }
                actionref("AddMarkerPromoted"; AddMarker) { }
                actionref(TestClearDataRef; TestClearData) { }
                actionref("RefreshDataPromoted"; RefreshData) { }
                actionref("Prev_filter"; PreviousAct) { }
                actionref("Today_filter"; Todayact) { }
                actionref("Next_filter"; Nextact) { }

            }
            group(Category_Category4)
            {
                Caption = 'Export';
                actionref(GetJsonTasks_ref; GetJsonTasks) { }
                actionref(GetJsonResources_ref; GetJsonResources) { }
                actionref(GetJsonDayPlannings_ref; GetJsonDayPlannings) { }
            }
            group(Category_Category5)
            {
                Caption = 'Related';
                actionref(Summary_ref; Summary) { }
                actionref(DayTaks_ref; DayTaks) { }
                actionref(Projects_ref; projects) { }
                actionref(ProjectTasks_ref; projectTasks) { }
                actionref("ShowResPanel"; ShowResourcePanel) { }
                actionref("HideResPanel"; HideResourcePanel) { }
            }
            group(Check)
            {
                Caption = 'Check';
                actionref(CheckGanttData; CheckGanttDataAct) { }
                actionref(CheckPagePeriodAct; CheckPagePeriod) { }
                actionref(CheckResourcePanelFilter; CheckResourcvePanelFilter) { }
            }
            Group(Reports)
            {
                Caption = 'Reports';
                actionref(DayResourceDetail_ref; DayResourceDetail) { }
                actionref(DayPlanningsDetail_ref; DayPlanningsDetail) { }
                actionref(DayPlanningsOverview_ref; DayPlanningsWeekOverview) { }
                actionref(DailyCapacityBalanceReport_ref; DailyCapacityBalanceReport) { }
            }
        }
    }

    trigger OnOpenPage()
    begin
        OptiSetup.Get();
        Setup.Get(UserId);
        AnchorDate := Today();
        ResourcePanelFlag := true;
        ShowPreviousNext := not (Setup."Date Range Type" = Setup."Date Range Type"::"Date Range");
    end;

    var
        Setup: Record "Gantt Chart Setup";
        OptiSetup: Record "Daily Optimizer Setup";
        AnchorDate: Date;
        ToggleAutoScheduling: Boolean;
        PageHandler: Codeunit "Gantt BC Page Handler";
        general: Codeunit "General Planning Utilities";
        GanttChartDataHandler: Codeunit "GanttChartDataHandler";
        LinkHandler: Codeunit "Gantt Chart Link Handler";
        ShowPreviousNext: Boolean;
        ResourcePanelFlag: Boolean;
        JobFilter: Text;
        JobTaskFilter: Text;
        CurrentResourcePanelFilterJsonString: Text;
        PreviewCancelled: Boolean;

    local procedure ClearResourcePanelFilter()
    begin
        CurrentResourcePanelFilterJsonString := '';
        CurrPage.DHXGanttControl2.ClearResourceFilter();
    end;

    [TryFunction]
    local procedure TryValidateRequestedResourceNo(var DayPlanning: Record "Day Planning"; ResourceCode: Code[20])
    begin
        DayPlanning.Validate("Requested Resource No.", ResourceCode);
    end;

    procedure RefreshGantt()
    begin
        CurrPage.DHXGanttControl2.ClearData();
        Setup.Get(UserId);
        LoadAllData();
    end;

    procedure SetJobFilter(pJobFilter: Text)
    begin
        JobFilter := pJobFilter;
    end;

    procedure SetJobTaskFilter(pJobFilter: Text; pJobTaskFilter: Text)
    begin
        JobFilter := pJobFilter;
        JobTaskFilter := pJobTaskFilter;
    end;

    local procedure LoadAllData()
    var
        GanttChartDataHandler: Codeunit "GanttChartDataHandler";
        StartDate: Date;
        EndDate: Date;
        LoadWithOutResourcePanelFilter: Boolean;
        FilterJson: JsonObject;
        FilterToken: JsonToken;
        FilterJobNo: Code[20];
        FilterJobTaskNo: Code[20];
        FilterFromDate: Date;
        FilterToDate: Date;
        JobTask: Record "Job Task";
        Window: Dialog;
        LoadingLbl: Label 'Loading Gantt data...\n#1######################';
    begin
        // Control add-in JS calls (LoadProject/RenderGantt/etc.) only actually execute in the
        // browser once this whole AL trigger returns to the client — so a JS-side overlay can't
        // paint while the AL calls below are still building large JSON payloads. This native
        // Dialog is what can actually show progress while that server-side work is happening.
        if GuiAllowed() then
            Window.Open(LoadingLbl);

        GanttChartDataHandler.GetDateRange(Setup, AnchorDate, StartDate, EndDate);

        // Set project range first
        CurrPage.DHXGanttControl2.LoadProject(StartDate, EndDate);

        // Load holiday/non-working days from Base Calendar
        if GuiAllowed() then
            Window.Update(1, 'Holidays...');
        LoadHolidaysData(StartDate, EndDate);

        // Apply column settings
        CurrPage.DHXGanttControl2.SetColumnVisibility(
            Setup."Show Start Date",
            Setup."Show Duration",
            Setup."Show Task Type"
        );

        // Load data in optimal sequence
        if setup."Load Job Tasks" then begin
            if GuiAllowed() then
                Window.Update(1, 'Job Tasks...');
            LoadTaskData();
        end;

        // Load dependency links after tasks
        if GuiAllowed() then
            Window.Update(1, 'Links...');
        LoadLinkData();

        CurrPage.DHXGanttControl2.GetResourceFilter(); // triggers OnResourceFilterRetrieved where we decide whether to apply the stored filter or load all resources
        LoadWithOutResourcePanelFilter := true;
        if CurrentResourcePanelFilterJsonString <> '' then
            if FilterJson.ReadFrom(CurrentResourcePanelFilterJsonString) then begin
                // Extract filter fields stored by SetResourcePanelFilterInfo: { job, task, periodFrom, periodTo }
                if FilterJson.Get('job', FilterToken) then
                    FilterJobNo := CopyStr(FilterToken.AsValue().AsText(), 1, MaxStrLen(FilterJobNo));
                if FilterJson.Get('task', FilterToken) then
                    FilterJobTaskNo := CopyStr(FilterToken.AsValue().AsText(), 1, MaxStrLen(FilterJobTaskNo));
                if FilterJson.Get('periodFrom', FilterToken) then
                    Evaluate(FilterFromDate, FilterToken.AsValue().AsText());
                if FilterJson.Get('periodTo', FilterToken) then
                    Evaluate(FilterToDate, FilterToken.AsValue().AsText());

                // Only apply the stored filter when both job and task are present
                if (FilterJobNo <> '') and (FilterJobTaskNo <> '') then begin
                    LoadWithOutResourcePanelFilter := false;

                    // // Re-apply the header tooltip so the (ℹ) button stays visible after refresh
                    // CurrPage.DHXGanttControl2.SetResourcePanelFilterInfo(
                    //     FilterJobNo, FilterJobTaskNo,
                    //     Format(FilterFromDate, 0, '<Year4>-<Month,2>-<Day,2>'),
                    //     Format(FilterToDate, 0, '<Year4>-<Month,2>-<Day,2>'));

                    // Mark the single task then load filtered resources + day plannings
                    JobTask.Reset();
                    JobTask.SetRange("Job No.", FilterJobNo);
                    JobTask.SetRange("Job Task No.", FilterJobTaskNo);
                    if JobTask.FindFirst() then
                        JobTask.Mark(true);
                    if GuiAllowed() then
                        Window.Update(1, 'Resources && Day Plannings...');
                    LoadFilteredResourcesAndDayPlannings(JobTask, FilterFromDate, FilterToDate);
                end;
            end;

        if LoadWithOutResourcePanelFilter then begin
            if setup."Load Resources" and ResourcePanelFlag then begin
                if GuiAllowed() then
                    Window.Update(1, 'Resources...');
                LoadResourceData();
            end;

            if setup."Load Day Plannings" then begin
                if GuiAllowed() then
                    Window.Update(1, 'Day Plannings...');
                LoadDayPlanningData();
            end;
        end;

        // Finalize: render and reset refresh flag
        if GuiAllowed() then
            Window.Update(1, 'Rendering...');
        CurrPage.DHXGanttControl2.RenderGantt(false);

        if GuiAllowed() then
            Window.Close();
    end;

    /// <summary>
    /// Loads resources and day plannings filtered to the marked JobTask records within the given period.
    /// Callers are responsible for marking the relevant Job Task records before calling this procedure.
    /// </summary>
    local procedure LoadFilteredResourcesAndDayPlannings(var pJobTask: Record "Job Task"; pFromDate: Date; pToDate: Date)
    var
        GanttDataHandler: Codeunit "GanttChartDataHandler";
        JsonTxtResource: Text;
    begin
        pJobTask.MarkedOnly := true;
        if pJobTask.FindSet() then;
        JsonTxtResource := GanttDataHandler.GetResourcesByJobTaskAsJson(pJobTask, pFromDate, pToDate);
        if JsonTxtResource <> '' then
            CurrPage.DHXGanttControl2.LoadResourcesData(JsonTxtResource);

        pJobTask.MarkedOnly := true;
        if pJobTask.FindSet() then;
        CurrPage.DHXGanttControl2.LoadDayPlanningsData(
            GanttDataHandler.GetDayPlanningsByJobTaskAsJson(pJobTask, pFromDate, pToDate));
    end;

    local procedure LoadTaskData()
    var
        GanttChartDataHandler: Codeunit "GanttChartDataHandler";
        JsonTxtTasks: Text;
    begin
        JsonTxtTasks := GanttChartDataHandler.GetJobTasksAsJson(AnchorDate, JobFilter, JobTaskFilter);
        if JsonTxtTasks <> '' then begin
            CurrPage.DHXGanttControl2.LoadProjectData(JsonTxtTasks);
            if setup."Download Data for Inspection" and GuiAllowed then
                if Confirm('Gantt Setting for %1 is enabled. Do you want to download the project task data for inspection purposes?', false, setup.FieldCaption("Download Data for Inspection")) then
                    GanttChartDataHandler.DownloadJsonTextData(JsonTxtTasks, 'GanttProjectTaskData.json');
        end;
    end;

    local procedure LoadResourceData()
    var
        GanttChartDataHandler: Codeunit "GanttChartDataHandler";
        JsonTxtResource: Text;
        tempblob: Codeunit "Temp Blob";
        instream: InStream;
        outstream: OutStream;
        va: variant;
    begin
        JsonTxtResource := GanttChartDataHandler.GetResourcesAsJson();
        if JsonTxtResource <> '' then begin
            CurrPage.DHXGanttControl2.LoadResourcesData(JsonTxtResource);
            if setup."Download Data for Inspection" and GuiAllowed then
                if Confirm('Gantt Setting for %1 is enabled. Do you want to download the resources data for inspection purposes?', false, setup.FieldCaption("Download Data for Inspection")) then
                    GanttChartDataHandler.DownloadJsonTextData(JsonTxtResource, 'GanttResourcesData.json');
        end;
    end;

    local procedure LoadDayPlanningData()
    var
        GanttChartDataHandler: Codeunit "GanttChartDataHandler";
        JsonTxtDayPlannings: Text;
        JobFilterUsed: Text;
    begin
        JobFilterUsed := setup."Job No. Filter";
        if JobFilter <> '' then
            JobFilterUsed := JobFilter // override with global filter if set
        else
            if JobFilterUsed <> '' then
                JobFilter := JobFilterUsed;
        JsonTxtDayPlannings := GanttChartDataHandler.GetDayPlanningsAsJson(AnchorDate, JobFilter, JobTaskFilter);
        if JsonTxtDayPlannings <> '' then
            CurrPage.DHXGanttControl2.LoadDayPlanningsData(JsonTxtDayPlannings);
    end;

    local procedure LoadLinkData()
    var
        JsonTxtLinks: Text;
        JobFilterUsed: Text;
    begin
        JobFilterUsed := setup."Job No. Filter";
        if JobFilter <> '' then
            JobFilterUsed := JobFilter; // override with global filter if set
        JsonTxtLinks := LinkHandler.GetLinksAsJson(JobFilterUsed);
        // Always send to JS — even '[]' clears stale arrows after refresh
        CurrPage.DHXGanttControl2.LoadLinksData(JsonTxtLinks);
    end;

    local procedure LoadHolidaysData(StartDate: Date; EndDate: Date)
    var
        GanttChartDataHandler: Codeunit "GanttChartDataHandler";
        JsonTxtHolidays: Text;
    begin
        JsonTxtHolidays := GanttChartDataHandler.GetHolidaysAsJson(StartDate, EndDate);
        CurrPage.DHXGanttControl2.LoadHolidaysData(JsonTxtHolidays);
    end;

    procedure OnJobTaskUpdated(TaskJson: Text)
    var
        JobTask: Record "Job Task";
        JsonObj: JsonObject;
        JsonToken: JsonToken;
        JobNo: Code[20];
        JobTaskNo: Code[20];
        StartDateTxt: Text;
        EndDateTxt: Text;
        DurationTxt: Text;
        ConstraintDateTxt: Text;
        SchedulingTypeTxt: Text;
        Description: Text[100];
        StartDate: Date;
        EndDate: Date;
        Duration: Integer;
        ConstraintDate: Date;
    begin
        // Parse the JSON
        if not JsonObj.ReadFrom(TaskJson) then
            Error('Invalid JSON format');

        // Extract BC bindings
        if JsonObj.Get('id', JsonToken) then begin
            JobNo := CopyStr(JsonToken.AsValue().AsText().Split('|').Get(1), 1, MaxStrLen(JobNo));
            JobTaskNo := CopyStr(JsonToken.AsValue().AsText().Split('|').Get(2), 1, MaxStrLen(JobTaskNo));
        end else
            Error('id. missing in JSON');

        if not JobTask.Get(JobNo, JobTaskNo) then
            exit;

        // Extract and update Description
        if JsonObj.Get('text', JsonToken) then begin
            Description := CopyStr(JsonToken.AsValue().AsText(), 1, MaxStrLen(Description));
            // Strip the "TaskNo - " display prefix added by GanttChartDataHandler to prevent accumulation
            if CopyStr(Description, 1, StrLen(JobTask."Job Task No.") + 3) = JobTask."Job Task No." + ' - ' then
                Description := CopyStr(Description, StrLen(JobTask."Job Task No.") + 4, MaxStrLen(Description));
            if JobTask.Description <> Description then
                JobTask.Description := Description;
        end;

        // Extract and update Start Date (format: dd-MM-yyyy)
        if JsonObj.Get('start_date', JsonToken) then begin
            StartDateTxt := JsonToken.AsValue().AsText();
            if StartDateTxt <> '' then begin
                StartDate := ParseDate(StartDateTxt);
                if JobTask.PlannedStartDate <> StartDate then
                    JobTask.PlannedStartDate := StartDate;
            end;
        end;

        // Extract and update Start Date (format: dd-MM-yyyy)
        if JsonObj.Get('end_date', JsonToken) then begin
            EndDateTxt := JsonToken.AsValue().AsText();
            if EndDateTxt <> '' then begin
                EndDate := ParseDate(EndDateTxt);
                if JobTask.PlannedEndDate <> EndDate then
                    JobTask.PlannedEndDate := EndDate;
            end;
        end;

        // Extract and update Duration
        if JsonObj.Get('duration', JsonToken) then begin
            Duration := JsonToken.AsValue().AsInteger();
            if (JobTask.PlannedStartDate <> 0D) and (Duration > 0) then begin
                JobTask.PlannedEndDate := JobTask.PlannedStartDate + Duration;
            end;
        end;

        // Extract and update Scheduling Type
        if JsonObj.Get('schedulingType', JsonToken) then begin
            SchedulingTypeTxt := JsonToken.AsValue().AsText();
            case SchedulingTypeTxt of
                'fixed_duration':
                    JobTask."Scheduling Type" := JobTask."Scheduling Type"::FixedDuration;
                // 'fixed_units':
                //     JobTask."Scheduling Type" := JobTask."Scheduling Type"::FixedUnits;
                'fixed_work':
                    JobTask."Scheduling Type" := JobTask."Scheduling Type"::FixedWork;
            end;
        end;

        // Extract constraint date if needed
        if JsonObj.Get('constraint_date', JsonToken) then begin
            ConstraintDateTxt := JsonToken.AsValue().AsText();
            if ConstraintDateTxt <> '' then
                ConstraintDate := ParseDate(ConstraintDateTxt);
            // Add logic to handle constraint date if you have a field for it
        end;

        // Save the changes
        JobTask.Modify(true);
    end;

    local procedure ParseDate(DateText: Text) ParsedDate: Date
    var
        Day: Integer;
        Month: Integer;
        Year: Integer;
        DayTxt: Text;
        MonthTxt: Text;
        YearTxt: Text;
        DashPos1: Integer;
        DashPos2: Integer;
    begin
        if DateText = '' then
            exit(0D);

        // Parse format: dd-MM-yyyy
        DashPos1 := StrPos(DateText, '-');
        if DashPos1 = 0 then
            exit(0D);

        DayTxt := CopyStr(DateText, 1, DashPos1 - 1);
        DateText := CopyStr(DateText, DashPos1 + 1);

        DashPos2 := StrPos(DateText, '-');
        if DashPos2 = 0 then
            exit(0D);

        MonthTxt := CopyStr(DateText, 1, DashPos2 - 1);
        YearTxt := CopyStr(DateText, DashPos2 + 1);

        Evaluate(Day, DayTxt);
        Evaluate(Month, MonthTxt);
        Evaluate(Year, YearTxt);

        ParsedDate := DMY2Date(Day, Month, Year);
    end;

    local procedure CalcNewAnchorDate(Direction: Option Forward,Backward): date
    var
        forDt: text;
        NewAnchorDate: Date;
    begin
        case Direction of
            Direction::Backward:
                Case Setup."Date Range Type" of
                    Setup."Date Range Type"::Weekly:
                        NewAnchorDate := CalcDate('<-6W>', AnchorDate);
                    Setup."Date Range Type"::Calculated:
                        begin
                            forDt := StrSubstNo('<-%1D>', setup.GetPeriodLength(AnchorDate));
                            NewAnchorDate := CalcDate(forDt, AnchorDate);
                        end;
                End;
            Direction::Forward:
                Case Setup."Date Range Type" of
                    Setup."Date Range Type"::Weekly:
                        NewAnchorDate := CalcDate('<6W>', AnchorDate);
                    Setup."Date Range Type"::Calculated:
                        begin
                            forDt := StrSubstNo('<%1D>', setup.GetPeriodLength(AnchorDate));
                            NewAnchorDate := CalcDate(forDt, AnchorDate);
                        end;
                End;
        end;
        exit(newAnchorDate);
    end;

}
