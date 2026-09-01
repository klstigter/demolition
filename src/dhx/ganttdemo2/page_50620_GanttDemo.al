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
                    // Panel starts hidden - set this BEFORE LoadAllData() so its resource-panel
                    // dispatch (see LoadAllData) sees ResourcePanelFlag = false and doesn't enqueue
                    // any background task at all on initial open. Nothing is shown until the user
                    // clicks "Show Resource Panel" or a task bar, so there is nothing to fetch yet.
                    ResourcePanelFlag := false;
                    LoadAllData();
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
                    Clear(ResourcePanelChildTaskIds);

                    // Parse Job No. and Job Task No. from the composite task id ("JobNo|JobTaskNo")
                    EventIDList := taskId.Split('|');
                    if EventIDList.Count() >= 2 then begin
                        JobNo := CopyStr(EventIDList.Get(1), 1, 20);
                        JobTaskNo := CopyStr(EventIDList.Get(2), 1, 20);
                    end;

                    // Parse childrenJson to get Job No. and Job Task No. of each child task in
                    // scope. Record.Mark() is no longer used here - the background task below
                    // takes plain "JobNo|JobTaskNo" key text (marks wouldn't survive into its
                    // separate session anyway) - JobTask.Get() is kept purely as a validity check
                    // so only real child tasks make it into ResourcePanelChildTaskIds.
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
                                            ResourcePanelChildTaskIds.Add(ChildJobNo + '|' + ChildJobTaskNo);
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

                    // Persist the panel's scope in plain AL page vars - these (not the JS
                    // round-tripped CurrentResourcePanelFilterJsonString) are what LoadAllData/
                    // ReloadResourcePanelFromStoredFilter read on later reloads. The JS round trip
                    // (SetResourcePanelFilterInfo -> GetResourceFilter -> OnResourceFilterRetrieved)
                    // is async and was confirmed live to sometimes not have landed yet by the time a
                    // reload runs, leaving CurrentResourcePanelFilterJsonString blank/stale and
                    // silently emptying the resource panel. Native AL vars are set synchronously here
                    // so reloads can never race against them.
                    ResourcePanelJobNo := JobNo;
                    ResourcePanelJobTaskNo := JobTaskNo;
                    ResourcePanelFromDate := FromDate;
                    ResourcePanelToDate := ToDate;

                    // Pass filter context for the header tooltip (display only from here on)
                    CurrPage.DHXGanttControl2.SetResourcePanelFilterInfo(JobNo, JobTaskNo, Format(FromDate, 0, '<Year4>-<Month,2>-<Day,2>'), Format(ToDate, 0, '<Year4>-<Month,2>-<Day,2>'));

                    // Load resources and day plannings filtered to this task (and its children) -
                    // async via a Page Background Task; returns immediately, and
                    // OnPageBackgroundTaskCompleted pushes the result in once ready.
                    EnqueueFilteredResourcePanelReload(FromDate, ToDate);

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
                                DayPlanning.SetRange("Plan Date", JobTask.PlannedStartDate, JobTask.PlannedEndDate);
                            (JobTask.PlannedStartDate = 0D) and (JobTask.PlannedEndDate <> 0D):
                                DayPlanning.Setfilter("Plan Date", '..%1', JobTask.PlannedEndDate);
                            (JobTask.PlannedStartDate <> 0D) and (JobTask.PlannedEndDate = 0D):
                                DayPlanning.Setfilter("Plan Date", '%1..', JobTask.PlannedStartDate);
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
                    TypeHelper: Codeunit "Type Helper";
                    PreviewWasCancelledByUser: Boolean;
                    PreviewCancelledMsg: Text;
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
                    // (OnClosePage fires on the preview page, Applied stays false) - flagged
                    // via PreviewWasCancelledByUser - or for an unrelated hard failure (invalid
                    // JSON, Job Task not found). Only the former offers the user a choice to
                    // still update the Job Task's own Planned Start/End Date without the
                    // Day Planning changes; any other failure just reverts, as before.
                    if not GantUpdatedata.UpdateJobTaskFromJson(eventData, PreviewWasCancelledByUser) then begin
                        if PreviewWasCancelledByUser then begin
                            // AL Label literals do NOT treat \n as a newline escape (it leaves a
                            // stray literal "n" behind) - TypeHelper.CRLFSeparator() is the correct
                            // way to insert a real line break into a Confirm/Message string.
                            PreviewCancelledMsg :=
                                'You closed the DayPlanning Period Change Preview without clicking Apply Changes, so the proposed Day Planning updates will not be saved.' +
                                TypeHelper.CRLFSeparator() + TypeHelper.CRLFSeparator() +
                                'Do you still want to update this task''s Planned Start Date and Planned End Date to match what you dragged in the Gantt chart?' +
                                TypeHelper.CRLFSeparator() + TypeHelper.CRLFSeparator() +
                                'Choose No to revert the task bar to its original size.';
                            if Confirm(PreviewCancelledMsg, false) then
                                if not GantUpdatedata.TryApplyPlannedDatesOnly(eventData) then
                                    Message(GetLastErrorText());
                        end;

                        PreviewCancelled := true; // absorb the RenderGantt re-entry event
                        LoadTaskData();
                        LoadLinkData();
                        if not ReloadResourcePanelFromStoredFilter() then
                            LoadDayPlanningData();
                        if ResourcePanelFlag then
                            CurrPage.DHXGanttControl2.SetResourcePanelVisibility(true);
                        CurrPage.DHXGanttControl2.RenderGantt(true); // force full re-render to reset task positions
                        exit;
                    end;

                    // Success path. UpdateJobTaskFromJson can silently correct the dropped
                    // date server-side - e.g. SnapForwardToWorkDay pushes a dragged end date
                    // that landed on a weekend/holiday forward to the next active workday - and
                    // that corrected PlannedEndDate is what actually got persisted, not the raw
                    // dropped position DHTMLX is still showing client-side. Without reloading
                    // task data here, the bar stays visually stuck on the day-off until the
                    // user manually clicks Refresh Data. Mirror the cancellation branch above:
                    // reload task + link data and force a re-render (RenderGantt(true) suppresses
                    // the resulting onAfterTaskUpdate re-entry, same as that branch) so the bar
                    // snaps to its true, server-confirmed position immediately.
                    PreviewCancelled := true; // absorb the RenderGantt re-entry event below
                    LoadTaskData();
                    LoadLinkData();
                    // Reload the resource panel to match the just-updated task - async in both
                    // branches (each just enqueues a Page Background Task and returns). No task
                    // filter active and the panel isn't even shown -> nothing to fetch.
                    if not ReloadResourcePanelFromStoredFilter() then
                        if ResourcePanelFlag then
                            LoadDayPlanningData();
                    if ResourcePanelFlag then
                        CurrPage.DHXGanttControl2.SetResourcePanelVisibility(true);
                    CurrPage.DHXGanttControl2.RenderGantt(true);
                end;

                trigger OpenResourceLoadDay(ResourceId: Text; pTaskDate: Text; pPlanStatus: Text; pIdList: Text)
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
                    Evaluate(WorkDt, pTaskDate);
                    DayPlanning.SetRange("Plan Date", WorkDt);
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

                trigger onAddDayPlanning(resourceId: Text; TaskDate: Text)
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
                    Evaluate(WorkDt, TaskDate); // expects YYYY-MM-DD
                    Prefix := CopyStr(resourceId, 1, 4);
                    ResourceCode := CopyStr(resourceId, 5, MaxStrLen(ResourceCode));
                    DayPlanning.Init();
                    DayPlanning."Plan Date" := WorkDt;
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
                        DayPlanning.TestField("Plan Date");

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
                    ResScheduler: page "Resource Scheduler - Calendar";
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
                    // and reload all resources + all day plannings driven by the default Gantt
                    // context. Enqueues a background task and returns immediately;
                    // OnPageBackgroundTaskCompleted populates the panel once ready.
                    ClearResourcePanelFilter();
                    EnqueueDefaultResourcePanelReload(true, true);
                end;

                trigger OnResourceFilterRetrieved(filterJson: Text)
                begin
                    CurrentResourcePanelFilterJsonString := filterJson;
                end;

                /// <summary>
                /// JS-initiated poll (wrapper.js's bounded interval, started by
                /// NotifyResourcePanelTaskPending) asking "is a background-task result ready
                /// yet?". This is a normal synchronous trigger call, unlike
                /// OnPageBackgroundTaskCompleted - so calling CurrPage.DHXGanttControl2.* from
                /// here is safe (confirmed live: it is NOT safe from the completion trigger
                /// itself - see that trigger's comment).
                /// </summary>
                trigger OnPollResourcePanelResult()
                begin
                    if not PendingResultAvailable then
                        exit;

                    PendingResultAvailable := false;
                    if PendingResourcesJson <> '' then
                        CurrPage.DHXGanttControl2.LoadResourcesData(PendingResourcesJson);
                    if PendingDayPlanningsJson <> '' then
                        CurrPage.DHXGanttControl2.LoadDayPlanningsData(PendingDayPlanningsJson);
                    Clear(PendingResourcesJson);
                    Clear(PendingDayPlanningsJson);
                    CurrPage.DHXGanttControl2.StopResourcePanelPolling();
                end;

                #region Task Filter Toolbar

                trigger OnGanttFilterIconClick()
                var
                    FilterDlg: Report "Task Scheduler Filter";
                    NewJobNo: Text;
                    NewJobTaskNo: Text;
                begin
                    FilterDlg.SetFilter(JobFilter, JobTaskFilter);
                    FilterDlg.RunModal();
                    if FilterDlg.IsConfirmed() then begin
                        FilterDlg.GetFilter(NewJobNo, NewJobTaskNo);
                        JobFilter := NewJobNo;
                        JobTaskFilter := NewJobTaskNo;
                        RefreshGantt();
                    end;
                end;

                trigger OnGanttClearTaskFilter()
                begin
                    JobFilter := '';
                    JobTaskFilter := '';
                    RefreshGantt();
                end;

                /// <summary>
                /// Fired by the task list's right-click "Add Filter" menu item - unlike
                /// OnGanttFilterIconClick above, this applies the right-clicked row's own Job
                /// No./Job Task No. directly, with no "Task Scheduler Filter" dialog: the user
                /// already picked the task by right-clicking it, so there is nothing left to ask.
                /// </summary>
                //TODO restore this trigger when the Gantt JS control supports it
                // trigger OnGanttContextAddFilter(jobNo: Text; jobTaskNo: Text)
                // begin
                //     if jobNo = '' then
                //         exit;
                //     JobFilter := jobNo;
                //     JobTaskFilter := jobTaskNo;
                //     RefreshGantt();
                // end;

                #endregion
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
                    JsonTxt := GanttChartDataHandler.GetDayPlanningsAsJson(AnchorDate, JobFilterUsed, '');
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
                            DayPlanning.SetRange("Plan Date", DT1, DT2);
                            DayPlanning.SetFilter("Job No.", PanelJobNo);
                            DayPlanning.SetFilter("Job Task No.", PanelTaskNo);
                            page.Run(Page::"Day Plannings", DayPlanning);
                            exit;
                        end;
                    end;

                    DayPlanning.SetRange("Plan Date", DT1, DT2);
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
                    // Show the panel immediately (empty) - resources are populated asynchronously
                    // once the background task below completes (OnPageBackgroundTaskCompleted).
                    ResourcePanelFlag := true;
                    CurrPage.DHXGanttControl2.SetResourcePanelVisibility(true);
                    ClearResourcePanelFilter(); // clear any existing filter context when manually showing the panel, to avoid confusion
                    EnqueueDefaultResourcePanelReload(true, true);
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

    /// <summary>
    /// Fires when a Page Background Task enqueued via EnqueueFilteredResourcePanelReload/
    /// EnqueueDefaultResourcePanelReload finishes. TaskId is compared against ResourcePanelTaskId
    /// (overwritten by every new enqueue) so a result from a superseded reload - e.g. the user
    /// clicked Previous/Next again before an earlier task completed - is silently discarded
    /// instead of clobbering the panel with stale-scope data.
    /// </summary>
    trigger OnPageBackgroundTaskCompleted(TaskId: Integer; Results: Dictionary of [Text, Text])
    begin
        if TaskId <> ResourcePanelTaskId then
            exit;

        // NOTE: does NOT call CurrPage.DHXGanttControl2.* here - confirmed live that BC Server
        // rejects any control add-in callback issued directly from this trigger ("attempted to
        // issue a client callback on an Automation object... disallowed callback was issued from
        // the OnPageBackgroundTaskCompleted or OnPageBackgroundTaskError trigger"). Stash the
        // result in plain AL vars instead; the OnPollResourcePanelResult trigger (JS-initiated,
        // via wrapper.js's bounded poll loop kicked off by NotifyResourcePanelTaskPending) is what
        // actually pushes this into the control add-in, from a normal synchronous call stack.
        if Results.ContainsKey('resourcesJson') then
            PendingResourcesJson := Results.Get('resourcesJson');
        if Results.ContainsKey('dayPlanningsJson') then
            PendingDayPlanningsJson := Results.Get('dayPlanningsJson');
        PendingResultAvailable := true;
    end;

    trigger OnPageBackgroundTaskError(TaskId: Integer; ErrorCode: Text; ErrorText: Text; ErrorCallStack: Text; var IsHandled: Boolean)
    var
        ResourcePanelLoadErrorNotification: Notification;
    begin
        if TaskId <> ResourcePanelTaskId then
            exit;

        IsHandled := true;
        // A notification is allowed here (unlike a raw Message/UI render) - surface the failure
        // without blocking the Gantt.
        ResourcePanelLoadErrorNotification.Message := StrSubstNo('Loading Gantt resource panel data failed: %1', ErrorText);
        ResourcePanelLoadErrorNotification.Send();
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
        ResourcePanelChildTaskIds: List of [Text]; // each entry "JobNo|JobTaskNo", populated in OnShowResourcesForTask; read by BuildResourcePanelJobTaskKeysText to build the background task's JobTaskKeys parameter
        ResourcePanelJobNo: Code[20];
        ResourcePanelJobTaskNo: Code[20];
        ResourcePanelFromDate: Date;
        ResourcePanelToDate: Date;
        ResourcePanelTaskId: Integer; // TaskId of the most recently enqueued resource-panel background task; OnPageBackgroundTaskCompleted/Error discard any result whose TaskId doesn't match (superseded by a later reload)
        PendingResourcesJson: Text; // set by OnPageBackgroundTaskCompleted, delivered into the control add-in by OnPollResourcePanelResult (see that trigger's comment for why the split is necessary)
        PendingDayPlanningsJson: Text;
        PendingResultAvailable: Boolean;

    local procedure ClearResourcePanelFilter()
    begin
        CurrentResourcePanelFilterJsonString := '';
        Clear(ResourcePanelChildTaskIds);
        ResourcePanelJobNo := '';
        ResourcePanelJobTaskNo := '';
        ResourcePanelFromDate := 0D;
        ResourcePanelToDate := 0D;
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
        SkillCapacityAnalysisMgt: Codeunit "Skill Capacity Analysis Mgt.";
        VisualDefaultSettings: Codeunit "Visual Default Settings";
        StartDate: Date;
        EndDate: Date;
        Window: Dialog;
        LoadingLbl: Label 'Loading Gantt data...\n#1######################';
    begin
        // Control add-in JS calls (LoadProject/RenderGantt/etc.) only actually execute in the
        // browser once this whole AL trigger returns to the client — so a JS-side overlay can't
        // paint while the AL calls below are still building large JSON payloads. This native
        // Dialog is what can actually show progress while that server-side work is happening.
        if GuiAllowed() then
            Window.Open(LoadingLbl);

        // Text/caption color for every task bar's on-bar label - "Daily Optimizer Setup"."Bar
        // Font Color" via codeunit 50609's GetBarFontColor (forwarded through codeunit 50662,
        // same as the scheduler pages' fontColor JSON key). Called every LoadAllData (both
        // ControlReady and RefreshGantt funnel through here), mirroring how the scheduler pages
        // re-send SetBarColors on every ControlReady. Does NOT affect gantt_tooltip text.
        CurrPage.DHXGanttControl2.SetBarFontColor(SkillCapacityAnalysisMgt.GetBarFontColor());

        // "Daily Optimizer Setup"."Weekend Color"/"Holiday Color" via codeunit 50609's
        // GetWeekendColor/GetHolidayColor - same call-every-LoadAllData convention as
        // SetBarFontColor above, so a setup change takes effect on the next refresh too.
        CurrPage.DHXGanttControl2.SetDayOffColors(VisualDefaultSettings.GetWeekendColor(), VisualDefaultSettings.GetHolidayColor());

        // "Daily Optimizer Setup"."GTB *" fields (codeunit 50609's GetGanttTaskBar* getters) - global
        // defaults for every Gantt task bar's box/text (border colour, progress-fill colour,
        // on-bar font colour/size, bar height). Layered underneath any per-task/per-task-type fill
        // override (codeunit 50613's own Color.Get resolution for "color") exactly like "GTB Color"
        // already is. Same call-every-LoadAllData convention as SetBarFontColor/SetDayOffColors above,
        // so a setup change takes effect on the next refresh too.
        CurrPage.DHXGanttControl2.SetGanttTaskBarDefaults(
            VisualDefaultSettings.GetGanttTaskBarBorderColor(),
            VisualDefaultSettings.GetGanttTaskBarProgressColor(),
            VisualDefaultSettings.GetGanttTaskBarFontColor(),
            VisualDefaultSettings.GetGanttTaskBarFontSize(),
            VisualDefaultSettings.GetGanttTaskBarHeight());

        GanttChartDataHandler.GetDateRange(Setup, AnchorDate, StartDate, EndDate);

        // Keep the filter-toolbar icon/tooltip (funnel + reset) in sync with the current
        // Job No./Job Task No. filter and visible period. Both ControlReady() and RefreshGantt()
        // funnel through this procedure, so this single call site covers user-driven filter
        // changes (OnGanttFilterIconClick/OnGanttClearTaskFilter) as well as the external
        // SetJobFilter/SetJobTaskFilter entry points (their callers invoke Gantt.RunModal()/Run()
        // right after, which lands on OnOpenPage -> ControlReady -> LoadAllData).
        CurrPage.DHXGanttControl2.SetGanttTaskFilterInfo(JobFilter, JobTaskFilter, Format(StartDate, 0, '<Year4>-<Month,2>-<Day,2>'), Format(EndDate, 0, '<Year4>-<Month,2>-<Day,2>'));

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

        CurrPage.DHXGanttControl2.GetResourceFilter(); // keeps the JS-side tooltip filter in sync; NOT used to decide the branch below (see ResourcePanelJobNo/JobTaskNo)

        // Resource-panel data (resources + Day Plannings) is not fetched synchronously here -
        // it isn't even visible until the panel is shown (see ControlReady/ShowResourcePanel),
        // so building/sending it eagerly on every LoadAllData was pure waste, and the underlying
        // "Day Planning" table is large enough that doing so blocked the whole page. Instead this
        // just kicks off a Page Background Task and returns immediately;
        // OnPageBackgroundTaskCompleted pushes the JSON into the control add-in once it's ready.
        // Read the panel's scope from the native AL vars set synchronously in
        // OnShowResourcesForTask/ReloadResourcePanelFromStoredFilter - NOT from
        // CurrentResourcePanelFilterJsonString, which depends on an async JS round trip
        // (SetResourcePanelFilterInfo -> GetResourceFilter -> OnResourceFilterRetrieved) that was
        // confirmed live to sometimes not have landed yet by the time this procedure runs, leaving
        // that string blank/stale and silently emptying the resource panel on Refresh Data.
        if (ResourcePanelJobNo <> '') and (ResourcePanelJobTaskNo <> '') then begin
            if GuiAllowed() then
                Window.Update(1, 'Resources && Day Plannings (loading in background)...');
            EnqueueFilteredResourcePanelReload(ResourcePanelFromDate, ResourcePanelToDate);
        end else
            if ResourcePanelFlag then begin
                if GuiAllowed() then
                    Window.Update(1, 'Resources && Day Plannings (loading in background)...');
                EnqueueDefaultResourcePanelReload(Setup."Load Resources", Setup."Load Day Plannings");
            end;

        // Finalize: render and reset refresh flag
        if GuiAllowed() then
            Window.Update(1, 'Rendering...');
        if ResourcePanelFlag then
            CurrPage.DHXGanttControl2.SetResourcePanelVisibility(true);
        CurrPage.DHXGanttControl2.RenderGantt(false);

        if GuiAllowed() then
            Window.Close();
    end;

    /// <summary>
    /// Converts a Boolean to the literal "true"/"false" text codeunit 50713's GetParam-based flag
    /// checks expect. Deliberately not Format() - Format(Boolean) returns the localized "Yes"/"No"
    /// caption, not "true"/"false".
    /// </summary>
    local procedure BoolToParamText(Value: Boolean): Text
    begin
        if Value then
            exit('true');
        exit('false');
    end;

    /// <summary>
    /// Builds the ';'-delimited "JobNo|JobTaskNo" key list (one entry per Job Task) that the
    /// background codeunit's Filtered mode needs, from the panel's stored scope
    /// (ResourcePanelJobNo/JobTaskNo + ResourcePanelChildTaskIds, populated in
    /// OnShowResourcesForTask). Returns '' when no task-filter scope is currently active.
    /// </summary>
    local procedure BuildResourcePanelJobTaskKeysText(): Text
    var
        Keys: Text;
        ChildTaskId: Text;
    begin
        if (ResourcePanelJobNo = '') or (ResourcePanelJobTaskNo = '') then
            exit('');

        Keys := ResourcePanelJobNo + '|' + ResourcePanelJobTaskNo;
        foreach ChildTaskId in ResourcePanelChildTaskIds do
            Keys += ';' + ChildTaskId;
        exit(Keys);
    end;

    /// <summary>
    /// Enqueues a Page Background Task that loads resources + day plannings scoped to one Job Task
    /// and its children (right-click "Show Job Resources", or a stored-filter reload after
    /// drag/drop) - see codeunit 50713 "Gantt BG Resource Panel Data", Filtered mode. Returns
    /// immediately; OnPageBackgroundTaskCompleted pushes the result into the control add-in once
    /// ready. A no-op when no task-filter scope is active.
    /// </summary>
    local procedure EnqueueFilteredResourcePanelReload(pFromDate: Date; pToDate: Date)
    var
        TaskParameters: Dictionary of [Text, Text];
        NewTaskId: Integer;
        JobTaskKeysText: Text;
    begin
        JobTaskKeysText := BuildResourcePanelJobTaskKeysText();
        if JobTaskKeysText = '' then
            exit;

        TaskParameters.Add('Mode', 'Filtered');
        TaskParameters.Add('LoadResources', 'true');
        TaskParameters.Add('LoadDayPlannings', 'true');
        TaskParameters.Add('JobTaskKeys', JobTaskKeysText);
        TaskParameters.Add('FromDate', Format(pFromDate, 0, '<Year4>-<Month,2>-<Day,2>'));
        TaskParameters.Add('ToDate', Format(pToDate, 0, '<Year4>-<Month,2>-<Day,2>'));

        CurrPage.EnqueueBackgroundTask(NewTaskId, Codeunit::"Gantt BG Resource Panel Data", TaskParameters, 30000, PageBackgroundTaskErrorLevel::Warning);
        ResourcePanelTaskId := NewTaskId;
        PendingResultAvailable := false; // any earlier not-yet-delivered result is now stale
        CurrPage.DHXGanttControl2.NotifyResourcePanelTaskPending(); // (re)start wrapper.js's bounded poll loop - normal synchronous call, safe here
    end;

    /// <summary>
    /// Enqueues a Page Background Task that loads the unfiltered resource panel (all resources /
    /// day plannings for the current Job/Job Task filter and visible Gantt period) - see codeunit
    /// 50713 "Gantt BG Resource Panel Data", Default mode. Either half can be requested on its own
    /// (e.g. ShowResourcePanel only wants resources). Returns immediately; a no-op when neither
    /// half is requested.
    /// </summary>
    local procedure EnqueueDefaultResourcePanelReload(pLoadResources: Boolean; pLoadDayPlannings: Boolean)
    var
        TaskParameters: Dictionary of [Text, Text];
        NewTaskId: Integer;
        JobFilterUsed: Text;
    begin
        if not (pLoadResources or pLoadDayPlannings) then
            exit;

        if pLoadDayPlannings then begin
            // Preserve the original LoadDayPlanningData fallback: default to the Gantt Chart
            // Setup's own "Job No. Filter" when no page-level JobFilter is active yet, and persist
            // it back into JobFilter so later reloads (RefreshGantt, etc.) keep using it
            // deterministically.
            JobFilterUsed := setup."Job No. Filter";
            if JobFilter <> '' then
                JobFilterUsed := JobFilter
            else
                if JobFilterUsed <> '' then
                    JobFilter := JobFilterUsed;
        end;

        TaskParameters.Add('Mode', 'Default');
        // NOTE: deliberately NOT Format(pLoadResources) - AL's default Boolean format is
        // localized "Yes"/"No" (confirmed live: codeunit 50713's `= 'true'` comparison silently
        // evaluated false for every call, so neither half ever loaded), not "true"/"false".
        TaskParameters.Add('LoadResources', BoolToParamText(pLoadResources));
        TaskParameters.Add('LoadDayPlannings', BoolToParamText(pLoadDayPlannings));
        TaskParameters.Add('JobFilter', JobFilter);
        TaskParameters.Add('JobTaskFilter', JobTaskFilter);
        TaskParameters.Add('AnchorDate', Format(AnchorDate, 0, '<Year4>-<Month,2>-<Day,2>'));

        CurrPage.EnqueueBackgroundTask(NewTaskId, Codeunit::"Gantt BG Resource Panel Data", TaskParameters, 30000, PageBackgroundTaskErrorLevel::Warning);
        ResourcePanelTaskId := NewTaskId;
        PendingResultAvailable := false; // any earlier not-yet-delivered result is now stale
        CurrPage.DHXGanttControl2.NotifyResourcePanelTaskPending(); // (re)start wrapper.js's bounded poll loop - normal synchronous call, safe here
    end;

    local procedure ReloadResourcePanelFromStoredFilter(): Boolean
    var
        JobTask: Record "Job Task";
    begin
        // Read from the native AL vars (set synchronously in OnShowResourcesForTask), not from
        // CurrentResourcePanelFilterJsonString - see the comment on ResourcePanelJobNo's
        // declaration and in LoadAllData for why that JSON string is unreliable here.
        if (ResourcePanelJobNo = '') or (ResourcePanelJobTaskNo = '') then
            exit(false);

        if not JobTask.Get(ResourcePanelJobNo, ResourcePanelJobTaskNo) then
            exit(false);

        // The stored period was captured when the resource panel was last opened for this task
        // and goes stale the moment the task (and its Day Plannings) are moved by a drag/apply -
        // re-derive the range from the Job Task's current Planned Start/End Date instead, and
        // persist it back into the native vars (not just pushed to JS) so the NEXT reload
        // (e.g. a plain Refresh Data click) also uses the fresh period deterministically.
        ResourcePanelFromDate := JobTask.PlannedStartDate;
        ResourcePanelToDate := JobTask.PlannedEndDate;

        CurrPage.DHXGanttControl2.SetResourcePanelFilterInfo(ResourcePanelJobNo, ResourcePanelJobTaskNo,
            Format(JobTask.PlannedStartDate, 0, '<Year4>-<Month,2>-<Day,2>'),
            Format(JobTask.PlannedEndDate, 0, '<Year4>-<Month,2>-<Day,2>'));
        CurrPage.DHXGanttControl2.GetResourceFilter();

        // Re-marking each child task is no longer needed here - ResourcePanelChildTaskIds (the
        // same list populated in OnShowResourcesForTask) already carries the panel's child scope
        // as plain "JobNo|JobTaskNo" keys, exactly what BuildResourcePanelJobTaskKeysText needs;
        // Record marks wouldn't survive into the background task's separate session anyway.
        // Enqueue only - returns immediately, OnPageBackgroundTaskCompleted applies the result.
        EnqueueFilteredResourcePanelReload(JobTask.PlannedStartDate, JobTask.PlannedEndDate);
        exit(true);
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

    /// <summary>
    /// Enqueues the unfiltered/default resource-panel background load with Day Plannings only
    /// (resources unaffected). EnqueueDefaultResourcePanelReload itself applies the "Job No.
    /// Filter" fallback (was inlined here before this became a background-task enqueue).
    /// </summary>
    local procedure LoadDayPlanningData()
    begin
        EnqueueDefaultResourcePanelReload(false, true);
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
        ConstraintDateTxt: Text;
        SchedulingTypeTxt: Text;
        Description: Text[100];
        StartDate: Date;
        EndDate: Date;
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
        Year: Integer;
        Month: Integer;
        Day: Integer;
        Parts: List of [Text];
    begin
        // Accepts  YYYY-MM-DD  (ISO format used by dhtmlx, gantt.config.date_format = "%Y-%m-%d")
        if DateText = '' then
            exit(0D);

        Parts := DateText.Split('-');
        if Parts.Count <> 3 then
            exit(0D);

        if not Evaluate(Year, Parts.Get(1)) then exit(0D);
        if not Evaluate(Month, Parts.Get(2)) then exit(0D);
        if not Evaluate(Day, Parts.Get(3)) then exit(0D);

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
                        // Step must match GetDateRange's Weekly-branch window width (anchor's own
                        // week + <5W> more, in codeunit 50613) - not one week wider. Was <-6W>,
                        // which overshot the window by a full week: e.g. a window anchored in wk 32
                        // (spanning wk 32..37) would jump Previous to wk 25 instead of wk 26,
                        // silently skipping wk 26 - the mirror image of the Forward bug below.
                        NewAnchorDate := CalcDate('<-5W>', AnchorDate);
                    Setup."Date Range Type"::Calculated:
                        begin
                            forDt := StrSubstNo('<-%1D>', setup.GetPeriodLength(AnchorDate));
                            NewAnchorDate := CalcDate(forDt, AnchorDate);
                        end;
                End;
            Direction::Forward:
                Case Setup."Date Range Type" of
                    Setup."Date Range Type"::Weekly:
                        // Step must match GetDateRange's Weekly-branch window width (anchor's own
                        // week + <5W> more, in codeunit 50613) - not one week wider. Was <6W>: a
                        // window anchored in wk 32 spans wk 32..37, so the next window must be
                        // reachable by a <5W> step to land back on wk 37 (deliberately re-showing
                        // the boundary week so a task whose Planned End Date falls in it - e.g. one
                        // ending exactly on the new window's first day - is never silently dropped
                        // from the task list). <6W> jumped straight to wk 38, skipping wk 37 in the
                        // task-filter query (GetJobTasksAsJson's PlannedEndDate >= StartDate) even
                        // though the header still looked plausible.
                        NewAnchorDate := CalcDate('<5W>', AnchorDate);
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
