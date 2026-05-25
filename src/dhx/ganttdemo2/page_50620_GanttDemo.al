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
                    // Get the latest data after possible changes in day tasks
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
                    SummaryPage.Runmodal();
                end;

                trigger OnShowResourcesForTask(taskId: Text; childrenJson: Text; periodFrom: Text; periodTo: Text)
                var
                    JobTask: Record "Job Task";
                    EventIDList: List of [Text];
                    JobNo: Code[20];
                    JobTaskNo: Code[20];
                    GanttDataHandler: Codeunit "GanttChartDataHandler";
                    JsonTxtResource: Text;
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

                    // Load only resources assigned to this task via Day Tasks within the period
                    JobTask.MarkedOnly := True;
                    if JobTask.FindSet() then;
                    JsonTxtResource := GanttDataHandler.GetResourcesByJobTaskAsJson(JobTask, FromDate, ToDate);
                    if JsonTxtResource <> '' then
                        CurrPage.DHXGanttControl2.LoadResourcesData(JsonTxtResource);

                    // Reload day task events filtered to only this task (and its children) so the
                    // resource panel timeline shows the correct events instead of all job tasks.
                    JobTask.MarkedOnly := True;
                    if JobTask.FindSet() then;
                    CurrPage.DHXGanttControl2.LoadDayTasksData(
                        GanttDataHandler.GetDayTasksByJobTaskAsJson(JobTask, FromDate, ToDate));
                end;

                trigger onOpenDayTask(taskId: Text; eventData: Text)
                var
                    JobTask: Record "Job Task";
                    JsonObj: JsonObject;
                    JsonToken: JsonToken;
                    JobNo: Code[20];
                    JobTaskNo: Code[20];
                    DayTask: Record "Day Tasks";
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
                        DayTask.SetRange("Job No.", JobNo);
                    if JobTaskNo <> '' then
                        DayTask.SetRange("Job Task No.", JobTaskNo);
                    if (JobNo <> '') and (JobTaskNo <> '') then begin
                        JobTask.Get(JobNo, JobTaskNo);
                        case true of
                            (JobTask.PlannedStartDate <> 0D) and (JobTask.PlannedEndDate <> 0D):
                                DayTask.SetRange("Task Date", JobTask.PlannedStartDate, JobTask.PlannedEndDate);
                            (JobTask.PlannedStartDate = 0D) and (JobTask.PlannedEndDate <> 0D):
                                DayTask.Setfilter("Task Date", '..%1', JobTask.PlannedEndDate);
                            (JobTask.PlannedStartDate <> 0D) and (JobTask.PlannedEndDate = 0D):
                                DayTask.Setfilter("Task Date", '%1..', JobTask.PlannedStartDate);
                        end;

                    end;
                    Page.Run(Page::"Day Tasks", DayTask);
                end;

                trigger onOpenDayTaskVisual(taskId: Text; eventData: Text)
                var
                    JsonObj: JsonObject;
                    JsonToken: JsonToken;
                    JobNo: Code[20];
                    JobTaskNo: Code[20];
                    DayTask: Record "Day Tasks";
                    EventIDList: List of [Text];
                    DaytaskScheduler: page "DHX Scheduler (Project)";
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
                        DayTask.SetRange("Job No.", JobNo);
                    if JobTaskNo <> '' then
                        DayTask.SetRange("Job Task No.", JobTaskNo);

                    DaytaskScheduler.SetJobTaskFilter(JobNo, JobTaskNo);
                    DaytaskScheduler.RunModal();
                end;

                trigger OnJobTaskUpdated(eventData: Text)
                var
                    GantUpdatedata: Codeunit "Gantt Update Data";
                begin
                    // UpdateJobTaskFromJson returns false when the user closed the
                    // DayTask Period Sync Preview popup without clicking Apply Changes
                    // (OnClosePage fires on the preview page, Applied stays false).
                    // In that case reload task + link data so the Gantt bar reverts to
                    // the original DB position instead of staying at the dragged spot.
                    if not GantUpdatedata.UpdateJobTaskFromJson(eventData) then begin
                        LoadTaskData();
                        LoadLinkData();
                        LoadDayTaskData();
                        CurrPage.DHXGanttControl2.RenderGantt();
                        exit;
                    end;
                    LoadDayTaskData();
                end;

                trigger OpenResourceLoadDay(ResourceId: Text; pWorkDate: Text)
                var
                    DayTask: Record "Day Tasks";
                    WorkDt: Date;
                    Tp: array[2] of text;
                begin
                    Evaluate(WorkDt, pWorkDate); // expects YYYY-MM-DD
                    tp[1] := CopyStr(ResourceId, 1, 4);
                    tp[2] := CopyStr(ResourceId, 5);
                    DayTask.SetRange("Task Date", WorkDt);
                    if JobFilter <> '' then
                        DayTask.SetFilter("Job No.", JobFilter);
                    if tp[1] = 'RES-' then
                        DayTask.SetRange("Assigned Resource No.", tp[2]);
                    if tp[1] = 'VEN-' then
                        DayTask.SetRange("Vendor No.", tp[2]);
                    Page.Run(Page::"Day Tasks", DayTask);
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
                begin
                    Message('Resource: %1', resourceId);
                end;

                trigger onAddDayTask(resourceId: Text; workDate: Text)
                var
                    DayTask: Record "Day Tasks";
                    DayTaskCard: Page "Day Task Card - New Record";
                    WorkDt: Date;
                    Prefix: Text[4];
                    ResourceCode: Code[20];
                    IsTemp: Boolean;
                begin
                    Evaluate(WorkDt, workDate); // expects YYYY-MM-DD
                    Prefix := CopyStr(resourceId, 1, 4);
                    ResourceCode := CopyStr(resourceId, 5, MaxStrLen(ResourceCode));
                    DayTask.Init();
                    DayTask."Task Date" := WorkDt;
                    if Prefix = 'RES-' then
                        DayTask.Validate("Assigned Resource No.", ResourceCode)
                    else
                        if Prefix = 'VEN-' then
                            DayTask.Validate("Vendor No.", ResourceCode);

                    Clear(DayTaskCard);
                    DayTaskCard.LookupMode(true);
                    DayTaskCard.SetNewRecordToSave(DayTask);
                    if DayTaskCard.RunModal() = Action::LookupOK then begin
                        DayTaskCard.GetRecord(DayTask);
                        DayTask.TestField("Job No.");
                        DayTask.TestField("Job Task No.");
                        DayTask.TestField("Task Date");
                        DayTask.GetNextDayLineNo();
                        DayTask.Insert();
                        RefreshGantt();
                    end;
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
                    ResScheduler.RunModal();
                end;

                trigger OnResetResourceFilter()
                begin
                    // User clicked the (ℹ) button — clear the task-based resource filter
                    // and reload all resources + all day tasks driven by the default Gantt context.
                    CurrPage.DHXGanttControl2.ClearResourceFilter();
                    LoadResourceData();
                    LoadDayTaskData();
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
            action(GetJsonDayTasks)
            {
                Caption = 'Get JSON Day Tasks Data';
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
                    JsonTxt := GanttChartDataHandler.GetDayTasksAsJson(Setup."From Date", JobFilterUsed, '');
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
                    Page.RunModal(Page::"Gantt Chart Setup");
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
                Caption = 'Day Tasks';
                ApplicationArea = All;
                image = AbsenceCalendar;

                trigger OnAction()
                var
                    DayTask: Record "Day Tasks";
                    Direction: Option Forward,Backward;
                    DT1: Date;
                    DT2: Date;
                begin
                    GanttChartDataHandler.GetDateRange(Setup, AnchorDate, DT1, DT2);
                    DayTask.SetRange("Task Date", DT1, DT2);
                    if JobFilter <> '' then
                        DayTask.SetFilter("Job No.", JobFilter);
                    page.RunModal(Page::"Day Tasks", DayTask);
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
                    //jobTask.SetAutoCalcFields("Total Day Tasks");
                    //jobTask.SetFilter("Total Day Tasks", '>0');
                    //if JobFilter <> '' then
                    job.SetFilter("No.", JobFilter);
                    if job.FindSet() then;
                    Job.setrange("No.");
                    pg.SetRecord(job);
                    pg.RunModal();
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
                    Direction: Option Forward,Backward;
                    DT1: Date;
                    DT2: Date;
                begin
                    GanttChartDataHandler.GetDateRange(Setup, AnchorDate, DT1, DT2);
                    jobTask.SetFilter("Planning Date Filter", '%1..%2', DT1, DT2);
                    jobTask.SetAutoCalcFields("Total Day Tasks");
                    jobTask.SetFilter("Total Day Tasks", '>0');
                    if JobFilter <> '' then
                        jobTask.SetFilter("Job No.", JobFilter);
                    page.RunModal(Page::"Job Task List - Project", jobTask);
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
                    CurrPage.DHXGanttControl2.ClearResourceFilter(); // no task filter when opening from toolbar
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
            action(DayTasksDetail)
            {
                Caption = 'Day Tasks Detail';
                ApplicationArea = All;
                Image = Report;
                trigger OnAction()
                var
                    DayTaskDetails: Report "Day Task Details";
                    StartDate: Date;
                    EndDate: Date;
                begin
                    GanttChartDataHandler.GetDateRange(Setup, AnchorDate, StartDate, EndDate);
                    DayTaskDetails.SetDataViewDateRange(StartDate, EndDate);
                    DayTaskDetails.RunModal();
                end;
            }
            action(DayTasksOverview)
            {
                Caption = 'Day Tasks Overview';
                ApplicationArea = All;
                Image = Report;
                trigger OnAction()
                var
                    DayTask: Report "DayTask";
                    StartDate: Date;
                    EndDate: Date;
                begin
                    GanttChartDataHandler.GetDateRange(Setup, AnchorDate, StartDate, EndDate);
                    daytask.SetDataViewDateRange(StartDate, EndDate);
                    DayTask.RunModal();
                end;
            }// Placeholder for any future reports related to the Gantt data
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
                actionref(GetJsonDayTasks_ref; GetJsonDayTasks) { }
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
            }
            Group(Reports)
            {
                Caption = 'Reports';
                actionref(DayTasksDetail_ref; DayTasksDetail) { }
                actionref(DayTasksOverview_ref; DayTasksOverview) { }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Setup.Get(UserId);
        AnchorDate := Today();
        ResourcePanelFlag := true;
        ShowPreviousNext := not (Setup."Date Range Type" = Setup."Date Range Type"::"Date Range");
    end;

    var
        AnchorDate: Date;
        ToggleAutoScheduling: Boolean;
        PageHandler: Codeunit "Gantt BC Page Handler";
        general: Codeunit "General Planning Utilities";
        Setup: Record "Gantt Chart Setup";
        GanttChartDataHandler: Codeunit "GanttChartDataHandler";
        LinkHandler: Codeunit "Gantt Chart Link Handler";
        ShowPreviousNext: Boolean;
        ResourcePanelFlag: Boolean;
        JobFilter: Text;

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

    local procedure LoadAllData()
    var
        GanttChartDataHandler: Codeunit "GanttChartDataHandler";
        StartDate: Date;
        EndDate: Date;
    begin
        GanttChartDataHandler.GetDateRange(Setup, AnchorDate, StartDate, EndDate);

        // Set project range first
        CurrPage.DHXGanttControl2.LoadProject(StartDate, EndDate);

        // Load holiday/non-working days from Base Calendar
        LoadHolidaysData(StartDate, EndDate);

        // Apply column settings
        CurrPage.DHXGanttControl2.SetColumnVisibility(
            Setup."Show Start Date",
            Setup."Show Duration",
            Setup."Show Task Type"
        );

        // Load data in optimal sequence
        if setup."Load Job Tasks" then
            LoadTaskData();

        // Load dependency links after tasks
        LoadLinkData();

        if setup."Load Resources" and ResourcePanelFlag then
            LoadResourceData();

        if setup."Load Day Tasks" then
            LoadDayTaskData();

        // Finalize: render and reset refresh flag
        CurrPage.DHXGanttControl2.RenderGantt();
    end;

    local procedure LoadTaskData()
    var
        GanttChartDataHandler: Codeunit "GanttChartDataHandler";
        JsonTxtTasks: Text;
    begin
        JsonTxtTasks := GanttChartDataHandler.GetJobTasksAsJson(AnchorDate, JobFilter);
        if JsonTxtTasks <> '' then
            CurrPage.DHXGanttControl2.LoadProjectData(JsonTxtTasks);
    end;

    local procedure LoadResourceData()
    var
        GanttChartDataHandler: Codeunit "GanttChartDataHandler";
        JsonTxtResource: Text;
    begin
        JsonTxtResource := GanttChartDataHandler.GetResourcesAsJson();
        if JsonTxtResource <> '' then
            CurrPage.DHXGanttControl2.LoadResourcesData(JsonTxtResource);
    end;

    local procedure LoadDayTaskData()
    var
        GanttChartDataHandler: Codeunit "GanttChartDataHandler";
        JsonTxtDayTasks: Text;
        JobFilterUsed: Text;
    begin
        JobFilterUsed := setup."Job No. Filter";
        if JobFilter <> '' then
            JobFilterUsed := JobFilter // override with global filter if set
        else
            if JobFilterUsed <> '' then
                JobFilter := JobFilterUsed;
        JsonTxtDayTasks := GanttChartDataHandler.GetDayTasksAsJson(AnchorDate, JobFilter);
        if JsonTxtDayTasks <> '' then
            CurrPage.DHXGanttControl2.LoadDayTasksData(JsonTxtDayTasks);
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
