page 50621 "DHX Scheduler (Project)"
{
    PageType = Card; //userControlHost;
    ApplicationArea = All;
    UsageCategory = Tasks;
    Caption = 'Task Scheduler';

    layout
    {
        area(content)
        {
            usercontrol(DhxScheduler; "DHXProjectScheduleAddin")
            {
                ApplicationArea = All;

                #region Init and Load Data on Control Ready

                trigger ControlReady()
                var
                    DayPlanningBarSetup: Record "Task Scheduler Setup";
                    DailyOptimizerSetup: Record "Daily Optimizer Setup";
                    SkillCapacityAnalysisMgt: Codeunit "Skill Capacity Analysis Mgt.";
                    startDate: Date;
                    endDate: Date;
                    EarliestPlanningDate: Date;
                    PlanninJsonTxt: Text;
                    ResourceJSONTxt: Text;
                    ColorsJsonTxt: Text;
                    AssignedColorHex: Text;
                    CapacityColorHex: Text;
                    ExternalBorderColorHex: Text;
                    HasSetup: Boolean;
                    Window: Dialog;
                    LoadingLbl: Label 'Loading Task Scheduler data...\n#1######################';
                begin
                    // Control add-in JS calls only actually run in the browser once this whole AL
                    // trigger returns to the client, so this native Dialog is what can show progress
                    // while the JSON payload below is being built server-side (mirrors LoadAllData in
                    // src/dhx/ganttdemo2/page_50620_GanttDemo.al).
                    if GuiAllowed() then
                        Window.Open(LoadingLbl);

                    //DHXDataHandler.GetOneYearPeriodDates(Today(), startDate, endDate);
                    DHXDataHandler.GetWeekPeriodDates(Today(), startDate, endDate);
                    if GuiAllowed() then
                        Window.Update(1, 'Day Plannings...');
                    // Loads only the first ~50-row page of sections/events synchronously (see
                    // LoadSchedulerSectionsPaginated) - any remaining Jobs are fetched by a Page
                    // Background Task and appended once ready (OnPollSectionsResult/AppendSections).
                    LoadSchedulerSectionsPaginated(startDate, endDate, ResourceJSONTxt, PlanninJsonTxt, EarliestPlanningDate);
                    if jobFilter = '' then
                        DHXDataHandler.ValidateSchedulerSectionMatch(ResourceJSONTxt, PlanninJsonTxt);
                    HasSetup := DayPlanningBarSetup.Get(UserId);
                    if HasSetup and (DayPlanningBarSetup."Timeline Hour Step" > 0) then
                        CurrPage.DhxScheduler.SetTimelineHourStep(DayPlanningBarSetup."Timeline Hour Step");
                    if HasSetup and (DayPlanningBarSetup."Timeline End Hour" > 0) then
                        CurrPage.DhxScheduler.SetTimelineHourRange(DayPlanningBarSetup."Timeline Start Hour", DayPlanningBarSetup."Timeline End Hour");
                    if GuiAllowed() then
                        Window.Update(1, 'Rendering...');
                    CurrPage.DhxScheduler.Init(ResourceJSONTxt, EarliestPlanningDate);
                    // Envelope/Assigned/Height colors now come from the company-wide "Daily
                    // Optimizer Setup" singleton (table 50605), not the per-user "Task Scheduler
                    // Setup" - the old "Requested Color" flat field is gone entirely; requested
                    // segments are now colored per-skill (see codeunit "DHX Data Handler"'s
                    // ResolveRequestedColor, wired into each event's own "requested_color" JSON
                    // field), with the CSS "--dp-color-requested" default as the fallback when an
                    // event has no resolved color.
                    // Boolean-context Get() - a bare "DailyOptimizerSetup.Get();" statement
                    // throws a runtime error if the singleton row doesn't exist yet (it's only
                    // ever created lazily, the first time someone opens page 50654's OnOpenPage -
                    // there's no install-time seeding), unlike this same call used in an "if"
                    // condition, which just leaves DailyOptimizerSetup blank/Init()'d on a miss -
                    // exactly what's wanted here since every field read below already tolerates
                    // blank (SetBarColors' per-key guards, GetCapacitySegmentColors' own fallback).
                    if DailyOptimizerSetup.Get() then;
                    // Assigned color is resolved via GetCapacitySegmentColors so this page always
                    // matches the Daily/Weekly bar-chart tiles' default (#548235), instead of
                    // silently falling back to wrapper.js's own (previously mismatched) CSS
                    // default whenever "Daily Optimizer Setup" is entirely blank. SetBarColors is
                    // now always called unconditionally - every property write inside it is
                    // individually guarded against blank values, so sending blanks for
                    // Envelope/EnvelopeBorder/Heights when the setup record doesn't exist is a
                    // safe no-op per key.
                    SkillCapacityAnalysisMgt.GetCapacitySegmentColors(AssignedColorHex, CapacityColorHex, ExternalBorderColorHex);
                    ColorsJsonTxt := StrSubstNo('{"envelope":"%1","envelopeBorder":"%2","assigned":"%3","assignedHeight":%4,"requestedHeight":%5}',
                        DailyOptimizerSetup."Envelope Color",
                        DailyOptimizerSetup."Envelope Border Color",
                        AssignedColorHex,
                        DailyOptimizerSetup."Assigned High (%)",
                        DailyOptimizerSetup."Requested High (%)");
                    CurrPage.DhxScheduler.SetBarColors(ColorsJsonTxt);
                    // This scheduler has no separate Capacity bar/event of its own - every bar is
                    // a Day Planning bar and therefore always skill-bearing, so bar text/border
                    // colour is driven entirely per-skill (never via "Daily Optimizer
                    // Setup"."Bar Font Color"/GetBarFontColor - the "fontColor" key removed from
                    // ColorsJsonTxt above accordingly). See wrapper.js's
                    // SetSkillFontBorderColors/event_class for the per-skill application.
                    CurrPage.DhxScheduler.SetSkillFontBorderColors(DHXDataHandler.BuildSkillFontBorderColorsJson());
                    CurrPage.DhxScheduler.LoadData(PlanninJsonTxt);
                    CurrPage.DhxScheduler.SetTaskFilterInfo(jobFilter, JobTaskFilter, Format(startDate, 0, '<Year4>-<Month,2>-<Day,2>'), Format(endDate, 0, '<Year4>-<Month,2>-<Day,2>'));
                    AnchorDate := startDate;

                    if GuiAllowed() then
                        Window.Close();
                end;

                #endregion Init and Load Data on Control Ready

                #region Section doubleclick

                trigger OnSectionDblClick(sectionId: Text; sectionLabel: Text; SectionData: Text)
                var
                    DHXDataHandler: Codeunit "DHX Data Handler";
                    PossibleChanges: Boolean;
                    newEventData: Text;
                begin
                    DHXDataHandler.OpenJobTaskCard(sectionId);
                    RefreshSchedule();
                end;

                #endregion Section doubleclick

                #region Event Double Click

                trigger OnEventDblClick(eventId: Text; eventData: Text)
                var
                    DateRef: Date;
                begin
                    DateRef := DHXDataHandler.OpenDayPlanning(eventId);
                    if DateRef <> 0D then begin
                        AnchorDate := DateRef;
                        RefreshSchedule();
                    end;
                end;

                #endregion Event Double Click

                #region new event added

                trigger onEventAdded(eventId: Text; eventData: Text)
                var
                    DHXDataHandler: Codeunit "DHX Data Handler";
                    UpdateEventIdJsonTxt: Text;
                begin
                    if DHXDataHandler.onEventAdded(eventData, UpdateEventIdJsonTxt) then
                        CurrPage.DhxScheduler.UpdateEventId(UpdateEventIdJsonTxt); //update event ID
                end;

                trigger OnOpenResourcePage(lightboxId: Text; eventData: Text)
                var
                    Res: record Resource;
                begin
                    if page.RunModal(0, Res) = Action::LookupOK then begin
                        //Update the lightbox event's section_id to the selected Resource's ID
                        CurrPage.DhxScheduler.SetLightboxEventValues(lightboxId, Res."No.", Res.Name);
                    end;
                end;

                #endregion new event added

                #region Drag-create new Day Planning (BC Card, not the native DHTMLX lightbox)

                // Fired by wrapper.js as soon as a drag-create gesture completes - the native
                // lightbox is cancelled (per the user's requirement to always use the BC Day
                // Planning Card instead), while the temp DHTMLX draft bar is left on the
                // timeline until RefreshSchedule() below replaces it with the real bar (or
                // removes it, if the Card was cancelled), so onEventAdded above is effectively
                // dead for the drag-create path now (left in place since other code may still
                // reference it; not this add-in's scope to remove). startDateIso's DATE portion
                // sets Plan Date; both startDateIso/endDateIso's TIME portions prefill Start/End
                // Time Requested on the Card. The drag is still constrained to a single day by
                // construction: only startDateIso's date is ever used as the Plan Date, so a
                // drag that crosses midnight doesn't create a multi-day record.
                trigger OnDragCreateDayPlanning(sectionId: Text; startDateIso: Text; endDateIso: Text)
                begin
                    DHXDataHandler.DragCreateDayPlanningCard(sectionId, startDateIso, endDateIso);
                    RefreshSchedule();
                end;

                #endregion Drag-create new Day Planning

                #region Event Changes
                trigger OnEventChanged(eventId: Text; eventData: Text)
                var
                    DHXDataHandler: Codeunit "DHX Data Handler";
                    UpdateEventID: Boolean;
                    OldDayPlanning_forUpdate: record "Day Planning";
                    NewDayPlanning_forUpdate: record "Day Planning";
                begin
                    DHXDataHandler.OnEventChanged_Project(eventId,
                                                  eventData,
                                                  UpdateEventID,
                                                  OldDayPlanning_forUpdate,
                                                  NewDayPlanning_forUpdate);
                    if UpdateEventID then
                        CurrPage.DhxScheduler.UpdateEventId(DHXDataHandler.UpdateEventID(OldDayPlanning_forUpdate, NewDayPlanning_forUpdate)); //update event ID
                end;

                trigger OnAfterEventIdUpdated(oldid: Text; newid: Text)
                begin
                    Message('Event ID updated from %1 to %2', oldid, newid);
                end;
                #endregion

                #region Button Planning Line Click

                trigger OnPlanningLineClick(Id: Text; EventJson: Text)
                var
                    JobPlanningLinesPage: page "Job Planning Lines";
                    JobPlanningLines: record "Job Task";
                    EventIDList: List of [Text];
                    JObNo: Code[20];
                    TaskNo: Code[20];
                    PlanningLineNo: Integer;
                begin
                    EventIDList := id.Split('|');
                    JObNo := EventIDList.Get(1);
                    TaskNo := EventIDList.Get(2);
                    Evaluate(PlanningLineNo, EventIDList.Get(3));
                    JobPlanningLines.Setrange("Job No.", JobNo);
                    JobPlanningLines.Setrange("Job Task No.", TaskNo);
                    if JobPlanningLines.findset then;
                    page.RunModal(0, JobPlanningLines);

                    //Message('Planning line clicked with ID: %1, Job No: %2, Task No: %3, Planning Line No: %4', Id, JObNo, TaskNo, PlanningLineNo);
                end;

                #endregion Button Planning Line Click

                #region Timeline Navigate
                trigger OnTimelineNavigate(NavigateJson: Text)
                var
                    DHXDataHandler: Codeunit "DHX Data Handler";
                    ResourceJSONTxt: Text;
                    EventsJsonTxt: Text;
                    StartDate: Date;
                    EndDate: Date;
                    EarliestPlanningDate: Date;
                    Window: Dialog;
                    LoadingLbl: Label 'Loading Task Scheduler data...\n#1######################';
                begin
                    if GuiAllowed() then
                        Window.Open(LoadingLbl);
                    if GuiAllowed() then
                        Window.Update(1, 'Day Plannings...');
                    DHXDataHandler.GetStartEndDatesFromTimeLineJSon(NavigateJson, startDate, endDate);
                    // Same paginated fetch + background enqueue as ControlReady/RefreshSchedule -
                    // see LoadSchedulerSectionsPaginated. Preserves the original "only refresh if
                    // both JSONs came back non-empty" guard below.
                    LoadSchedulerSectionsPaginated(startDate, endDate, ResourceJSONTxt, EventsJsonTxt, EarliestPlanningDate);
                    if (ResourceJSONTxt <> '') and (EventsJsonTxt <> '') then begin
                        if GuiAllowed() then
                            Window.Update(1, 'Rendering...');
                        CurrPage.DhxScheduler.RefreshTimeline(ResourceJSONTxt, EventsJsonTxt, startDate); //TODO: pass resourcesJson and eventsJson
                        AnchorDate := startDate;
                    end;
                    if GuiAllowed() then
                        Window.Close();
                end;
                #endregion Timeline Navigate

                #region Cek Data

                trigger OnEventsNotMatch(EventIdsJsonTxt: Text)
                begin
                    Message(EventIdsJsonTxt);
                end;

                trigger OnGetAllEvents(EventIdsJsonTxt: Text)
                begin
                    Message('All Events: %1', EventIdsJsonTxt);
                end;

                trigger OnGetAllSections(SectionIdsJsonTxt: Text)
                begin
                    Message('All Sections: %1', SectionIdsJsonTxt);
                end;

                #endregion Cek Data

                #region Context Menu

                trigger OnEventContextMenu(eventId: Text; action: Text; payloadJson: Text)
                begin
                    case action of
                        'ShowJobResources':
                            DHXDataHandler.ShowJobResourcesForEvent(eventId);
                        'OpenTask':
                            DHXDataHandler.OpenJobTaskCardFromEventId(eventId);
                        'OpenDayPlanning':
                            begin
                                DHXDataHandler.OpenDayPlanning(eventId);
                                RefreshSchedule();
                            end;
                        'OpenDayPlanningCard':
                            DHXDataHandler.OpenDayPlanningCard(eventId);
                        'OpenDayPlanningVisual':
                            DHXDataHandler.OpenDayPlanningVisual(eventId);
                        'OpenResourceSchedulerAssigned':
                            DHXDataHandler.OpenResourceSchedulerAssigned(eventId);
                        'OpenResSchedulerTimeline':
                            DHXDataHandler.OpenResSchedulerTimeline(eventId);
                        'OpenResourceSchedulerRequested':
                            DHXDataHandler.OpenResourceSchedulerRequested(eventId);
                        'OpenRequestedResourceCard':
                            DHXDataHandler.OpenRequestedResourceCard(eventId);
                        'OpenAssignedResourceCard':
                            DHXDataHandler.OpenAssignedResourceCard(eventId);
                    end;
                end;

                trigger OnSectionContextMenu(sectionId: Text; action: Text; payloadJson: Text)
                begin
                    case action of
                        'OpenTask':
                            DHXDataHandler.OpenJobTaskCard(sectionId);
                        'ShowMessage1':
                            Message('message 1 from scheduller');
                        'ShowMessage2':
                            Message('message 2 from scheduller');
                    end;
                end;

                #endregion Context Menu

                #region Task Filter Toolbar

                trigger OnFilterIconClick()
                var
                    FilterDlg: Report "Task Scheduler Filter";
                    NewJobNo: Text;
                    NewJobTaskNo: Text;
                begin
                    FilterDlg.SetFilter(jobFilter, JobTaskFilter);
                    FilterDlg.RunModal();
                    if FilterDlg.IsConfirmed() then begin
                        FilterDlg.GetFilter(NewJobNo, NewJobTaskNo);
                        jobFilter := NewJobNo;
                        JobTaskFilter := NewJobTaskNo;
                        RefreshSchedule();
                    end;
                end;

                trigger OnClearTaskFilter()
                begin
                    jobFilter := '';
                    JobTaskFilter := '';
                    RefreshSchedule();
                end;

                #endregion Task Filter Toolbar

                #region Background-loaded remaining sections (Part B pagination)

                /// <summary>
                /// JS-initiated poll (wrapper.js's bounded interval, started by
                /// NotifySectionsTaskPending) asking "is a background-task result ready yet?".
                /// This is a normal synchronous trigger call, unlike OnPageBackgroundTaskCompleted -
                /// so calling CurrPage.DhxScheduler.* from here is safe (confirmed live via codeunit
                /// 50713's identical pattern for the Gantt add-in: it is NOT safe from the
                /// completion trigger itself).
                /// </summary>
                trigger OnPollSectionsResult()
                begin
                    if not PendingResultAvailable then
                        exit;

                    PendingResultAvailable := false;
                    if (PendingSectionsJson <> '') or (PendingEventsJson <> '') then
                        CurrPage.DhxScheduler.AppendSections(PendingSectionsJson, PendingEventsJson);
                    Clear(PendingSectionsJson);
                    Clear(PendingEventsJson);
                    CurrPage.DhxScheduler.StopSectionsPolling();
                end;

                #endregion Background-loaded remaining sections (Part B pagination)
            }
        }
    }

    actions
    {
        area(Processing)
        {
            // action(ShowDefaultTabs)
            // {
            //     Caption = 'Show/Hide DHTMLX buttons';
            //     ApplicationArea = All;
            //     trigger OnAction()
            //     begin
            //         ShowDefaultTabs := not ShowDefaultTabs;
            //         CurrPage.DhxScheduler.SetDefaultTabsVisible(ShowDefaultTabs);
            //     end;
            // }

            action(TodayAct)
            {
                Caption = 'Today';
                ApplicationArea = All;
                Image = Position;
                trigger OnAction()
                begin
                    AnchorDate := Today();
                    RefreshSchedule();
                end;
            }
            action(PreviousAct)
            {
                Caption = 'Previous';
                ApplicationArea = All;
                Image = PreviousSet;
                trigger OnAction()
                begin
                    AnchorDate := CalcDate('<-1W>', AnchorDate);
                    RefreshSchedule();
                end;
            }
            action(NextAct)
            {
                Caption = 'Next';
                ApplicationArea = All;
                Image = NextSet;
                trigger OnAction()
                begin
                    AnchorDate := CalcDate('<1W>', AnchorDate);
                    RefreshSchedule();
                end;
            }
            action(ExecEventsNotMatch)
            {
                Caption = 'Get Events Not Matching Sections';
                ApplicationArea = All;
                Image = "Event";

                trigger OnAction()
                begin
                    CurrPage.DhxScheduler.get_events_not_match_with_section();
                end;
            }

            action(ExecGetAllEvents)
            {
                Caption = 'Get All Events';
                ApplicationArea = All;
                Image = Task;

                trigger OnAction()
                begin
                    CurrPage.DhxScheduler.getAllEvents();
                end;
            }

            action(ExecGetAllSections)
            {
                Caption = 'Get All Sections';
                ApplicationArea = All;
                Image = Resource;

                trigger OnAction()
                begin
                    CurrPage.DhxScheduler.getAllSections();
                end;
            }

            action(DateLookup)
            {
                Caption = 'Go to Date';
                ApplicationArea = All;
                Image = GoTo;
                trigger OnAction()
                var
                    DateRec: record Date;
                    DateSelectorPage: page "Date Lookup";
                    SelectedDate: Date;
                begin
                    DateSelectorPage.LookupMode := true;
                    if DateSelectorPage.RunModal() = Action::LookupOK then begin
                        DateSelectorPage.GetRecord(DateRec);
                        SelectedDate := DateRec."Period Start";
                        AnchorDate := SelectedDate;
                        RefreshSchedule();
                    end;
                end;
            }
        }

        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Date Navigation', Comment = 'Record list will filtered based on date';

                actionref("Prev_filter"; PreviousAct) { }
                actionref("Today_filter"; Todayact) { }
                actionref("Next_filter"; Nextact) { }
            }
        }
    }

    /// <summary>
    /// Fires when a Page Background Task enqueued via EnqueueSectionsBackgroundTask finishes.
    /// TaskId is compared against SectionsTaskId (overwritten by every new enqueue) so a result
    /// from a superseded reload - e.g. the user already clicked Next again before an earlier
    /// task completed - is discarded, same TaskId-based staleness check as codeunit 50713's Gantt
    /// resource-panel flow (page 50620). On top of that, the period/filter the task was actually
    /// enqueued for (BGPending*) is re-checked against the page's CURRENT AnchorDate/jobFilter/
    /// JobTaskFilter/ResourceFilter before promoting the result - the extra belt-and-braces check
    /// requested for this feature, whose promote-on-completion mechanics mirror (mechanics only,
    /// not its speculative Prev/Next prefetch idea - see feedback_bg_task_prefetch_overhead.md)
    /// the parked codeunit 50714 "Gantt BG Prefetch Task Data" (branch save_gantt).
    /// </summary>
    trigger OnPageBackgroundTaskCompleted(TaskId: Integer; Results: Dictionary of [Text, Text])
    var
        CurrentEffResourceFilter: Text;
        CurrentEffJobFilter: Text;
        CurrentEffJobTaskFilter: Text;
    begin
        if TaskId <> SectionsTaskId then
            exit;

        if jobFilter <> '' then begin
            CurrentEffResourceFilter := '';
            CurrentEffJobFilter := jobFilter;
            CurrentEffJobTaskFilter := JobTaskFilter;
        end else begin
            CurrentEffResourceFilter := ResourceFilter;
            CurrentEffJobFilter := '';
            CurrentEffJobTaskFilter := '';
        end;

        if (BGPendingStartDate <> AnchorDate) or
           (BGPendingResourceFilter <> CurrentEffResourceFilter) or
           (BGPendingJobFilter <> CurrentEffJobFilter) or
           (BGPendingJobTaskFilter <> CurrentEffJobTaskFilter)
        then
            exit; // stale - the displayed period/filter moved on since this task was enqueued

        // NOTE: does NOT call CurrPage.DhxScheduler.* here - confirmed live that BC Server rejects
        // any control add-in callback issued directly from this trigger (see codeunit 50713's
        // identical comment for the Gantt add-in). Stash into plain AL vars instead;
        // OnPollSectionsResult (JS-initiated, via wrapper.js's bounded poll loop kicked off by
        // NotifySectionsTaskPending) is what actually pushes this into the control add-in, from a
        // normal synchronous call stack.
        if Results.ContainsKey('sectionsJson') then
            PendingSectionsJson := Results.Get('sectionsJson');
        if Results.ContainsKey('eventsJson') then
            PendingEventsJson := Results.Get('eventsJson');
        PendingResultAvailable := (PendingSectionsJson <> '') or (PendingEventsJson <> '');
    end;

    trigger OnPageBackgroundTaskError(TaskId: Integer; ErrorCode: Text; ErrorText: Text; ErrorCallStack: Text; var IsHandled: Boolean)
    var
        SectionsLoadErrorNotification: Notification;
    begin
        if TaskId <> SectionsTaskId then
            exit;

        IsHandled := true;
        // A notification is allowed here (unlike a raw Message/UI render) - surface the failure
        // without blocking the Task Scheduler; the first page already rendered successfully.
        SectionsLoadErrorNotification.Message := StrSubstNo('Loading the remaining Task Scheduler sections failed: %1', ErrorText);
        SectionsLoadErrorNotification.Send();
    end;

    var
        DHXDataHandler: Codeunit "DHX Data Handler";
        ShowDefaultTabs: Boolean;
        AnchorDate: Date;
        ResourceFilter: Text;
        jobFilter: Text;
        JobTaskFilter: Text;
        SectionsTaskId: Integer; // TaskId of the most recently enqueued sections background task; OnPageBackgroundTaskCompleted/Error discard any result whose TaskId doesn't match (superseded by a later reload)
        PendingSectionsJson: Text; // set by OnPageBackgroundTaskCompleted, delivered into the control add-in by OnPollSectionsResult (see that trigger's comment for why the split is necessary)
        PendingEventsJson: Text;
        PendingResultAvailable: Boolean;
        BGPendingStartDate: Date; // AnchorDate/filters the in-flight SectionsTaskId was enqueued for, set by EnqueueSectionsBackgroundTask; compared against the CURRENT page state in OnPageBackgroundTaskCompleted before promoting a result
        BGPendingResourceFilter: Text;
        BGPendingJobFilter: Text;
        BGPendingJobTaskFilter: Text;

    /// <summary>
    /// Shared by ControlReady/RefreshSchedule/OnTimelineNavigate: fetches the first ~50-row page
    /// of sections/events for the given period (synchronous - what the caller renders immediately)
    /// via GetYUnitElementsJSON_Project_Paged, then enqueues a Page Background Task for whatever
    /// Jobs didn't fit (see EnqueueSectionsBackgroundTask) - a no-op enqueue when everything already
    /// fit on the first page. Applies the same Resource-filter-only vs Job/Job-Task-filter mutual
    /// exclusivity the page's non-paginated calls already used (never both at once).
    /// </summary>
    local procedure LoadSchedulerSectionsPaginated(pStartDate: Date; pEndDate: Date; var ResourceJSONTxt: Text; var PlanninJsonTxt: Text; var EarliestPlanningDate: Date)
    var
        DHXDataHandlerLocal: Codeunit "DHX Data Handler";
        RemainingJobFilter: Text;
        EffResourceFilter: Text;
        EffJobFilter: Text;
        EffJobTaskFilter: Text;
        SectionsPageSize: Integer;
    begin
        if jobFilter <> '' then begin
            EffResourceFilter := '';
            EffJobFilter := jobFilter;
            EffJobTaskFilter := JobTaskFilter;
        end else begin
            EffResourceFilter := ResourceFilter;
            EffJobFilter := '';
            EffJobTaskFilter := '';
        end;

        SectionsPageSize := 50; // user-approved literal first-N-sections pagination size
        ResourceJSONTxt := DHXDataHandlerLocal.GetYUnitElementsJSON_Project_Paged(pStartDate, pStartDate, pEndDate,
            EffResourceFilter, EffJobFilter, EffJobTaskFilter, SectionsPageSize, PlanninJsonTxt, EarliestPlanningDate, RemainingJobFilter);

        EnqueueSectionsBackgroundTask(pStartDate, pEndDate, EffResourceFilter, EffJobFilter, EffJobTaskFilter, RemainingJobFilter);
    end;

    /// <summary>
    /// Enqueues codeunit "Task Scheduler BG Sections" to build whatever Jobs didn't fit on the
    /// first paginated page (RemainingJobFilter) - a no-op when RemainingJobFilter is blank (the
    /// whole period already fit). Returns immediately; OnPageBackgroundTaskCompleted applies the
    /// result once ready, via OnPollSectionsResult's poll delivery.
    /// </summary>
    local procedure EnqueueSectionsBackgroundTask(pStartDate: Date; pEndDate: Date; pResourceFilter: Text; pJobFilter: Text; pJobTaskFilter: Text; RemainingJobFilter: Text)
    var
        TaskParameters: Dictionary of [Text, Text];
        NewTaskId: Integer;
    begin
        if RemainingJobFilter = '' then
            exit; // everything already fit on the first page - nothing to background-load

        TaskParameters.Add('ResourceFilter', pResourceFilter);
        TaskParameters.Add('JobFilter', RemainingJobFilter);
        TaskParameters.Add('JobTaskFilter', pJobTaskFilter);
        TaskParameters.Add('StartDate', Format(pStartDate, 0, '<Year4>-<Month,2>-<Day,2>'));
        TaskParameters.Add('EndDate', Format(pEndDate, 0, '<Year4>-<Month,2>-<Day,2>'));

        CurrPage.EnqueueBackgroundTask(NewTaskId, Codeunit::"Task Scheduler BG Sections", TaskParameters, 30000, PageBackgroundTaskErrorLevel::Warning);
        SectionsTaskId := NewTaskId;
        BGPendingStartDate := pStartDate;
        BGPendingResourceFilter := pResourceFilter;
        BGPendingJobFilter := pJobFilter; // the PAGE-level filter scope this task was enqueued for (not RemainingJobFilter) - used for the staleness check in OnPageBackgroundTaskCompleted
        BGPendingJobTaskFilter := pJobTaskFilter;
        PendingResultAvailable := false; // any earlier not-yet-delivered result is now stale
        CurrPage.DhxScheduler.NotifySectionsTaskPending(); // (re)start wrapper.js's bounded poll loop - normal synchronous call, safe here
    end;

    local procedure RefreshSchedule()
    var
        DHXDataHandler: Codeunit "DHX Data Handler";
        startDate: Date;
        endDate: Date;
        ResourceJSONTxt: Text;
        EventsJsonTxt: Text;
        EarliestPlanningDate: Date;
        Window: Dialog;
        LoadingLbl: Label 'Loading Task Scheduler data...\n#1######################';
    begin
        if GuiAllowed() then
            Window.Open(LoadingLbl);

        DHXDataHandler.GetWeekPeriodDates(AnchorDate, startDate, endDate);
        if GuiAllowed() then
            Window.Update(1, 'Day Plannings...');
        // Same paginated fetch + background enqueue as ControlReady/OnTimelineNavigate - see
        // LoadSchedulerSectionsPaginated.
        LoadSchedulerSectionsPaginated(startDate, endDate, ResourceJSONTxt, EventsJsonTxt, EarliestPlanningDate);
        if GuiAllowed() then
            Window.Update(1, 'Rendering...');
        CurrPage.DhxScheduler.RefreshTimeline(ResourceJSONTxt, EventsJsonTxt, startDate);
        CurrPage.DhxScheduler.SetTaskFilterInfo(jobFilter, JobTaskFilter, Format(startDate, 0, '<Year4>-<Month,2>-<Day,2>'), Format(endDate, 0, '<Year4>-<Month,2>-<Day,2>'));

        if GuiAllowed() then
            Window.Close();
    end;

    procedure SetResourceFilter(pResourceFilter: Text)
    begin
        ResourceFilter := pResourceFilter;
    end;

    procedure SetJobTaskFilter(pJobFilter: Text; pJobTaskFilter: Text)
    begin
        jobFilter := pJobFilter;
        JobTaskFilter := pJobTaskFilter;
    end;

}