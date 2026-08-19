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
                    startDate: Date;
                    endDate: Date;
                    EarliestPlanningDate: Date;
                    PlanninJsonTxt: Text;
                    ResourceJSONTxt: Text;
                    ColorsJsonTxt: Text;
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
                    if jobFilter <> '' then
                        DHXDataHandler.GetDayPlanningAsResourcesAndEventsJSon_Project_StartEnd(
                            startDate, endDate, jobFilter, JobTaskFilter,
                            ResourceJSONTxt, PlanninJsonTxt, EarliestPlanningDate)
                    else begin
                        ResourceJSONTxt := DHXDataHandler.GetYUnitElementsJSON_Project(Today(), startDate, endDate, ResourceFilter, PlanninJsonTxt, EarliestPlanningDate);
                        DHXDataHandler.ValidateSchedulerSectionMatch(ResourceJSONTxt, PlanninJsonTxt);
                    end;
                    HasSetup := DayPlanningBarSetup.Get(UserId);
                    if HasSetup and (DayPlanningBarSetup."Timeline Hour Step" > 0) then
                        CurrPage.DhxScheduler.SetTimelineHourStep(DayPlanningBarSetup."Timeline Hour Step");
                    if HasSetup and (DayPlanningBarSetup."Timeline End Hour" > 0) then
                        CurrPage.DhxScheduler.SetTimelineHourRange(DayPlanningBarSetup."Timeline Start Hour", DayPlanningBarSetup."Timeline End Hour");
                    if GuiAllowed() then
                        Window.Update(1, 'Rendering...');
                    CurrPage.DhxScheduler.Init(ResourceJSONTxt, EarliestPlanningDate);
                    if HasSetup then
                        if (DayPlanningBarSetup."Envelope Color" <> '') or
                           (DayPlanningBarSetup."Envelope Border Color" <> '') or
                           (DayPlanningBarSetup."Assigned Color" <> '') or
                           (DayPlanningBarSetup."Requested Color" <> '') or
                           (DayPlanningBarSetup."Assigned High (%)" > 0) or
                           (DayPlanningBarSetup."Requested High (%)" > 0)
                        then begin
                            ColorsJsonTxt := StrSubstNo('{"envelope":"%1","envelopeBorder":"%2","assigned":"%3","requested":"%4","assignedHeight":%5,"requestedHeight":%6}',
                                DayPlanningBarSetup."Envelope Color",
                                DayPlanningBarSetup."Envelope Border Color",
                                DayPlanningBarSetup."Assigned Color",
                                DayPlanningBarSetup."Requested Color",
                                DayPlanningBarSetup."Assigned High (%)",
                                DayPlanningBarSetup."Requested High (%)");
                            CurrPage.DhxScheduler.SetBarColors(ColorsJsonTxt);
                        end;
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
                    Window: Dialog;
                    LoadingLbl: Label 'Loading Task Scheduler data...\n#1######################';
                begin
                    if GuiAllowed() then
                        Window.Open(LoadingLbl);
                    if GuiAllowed() then
                        Window.Update(1, 'Day Plannings...');
                    if DHXDataHandler.GetDayPlanningAsResourcesAndEventsJSon_Project(NavigateJson, ResourceFilter, ResourceJSONTxt, EventsJsonTxt) then begin
                        DHXDataHandler.GetStartEndDatesFromTimeLineJSon(NavigateJson, startDate, endDate);
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

    var
        DHXDataHandler: Codeunit "DHX Data Handler";
        ShowDefaultTabs: Boolean;
        AnchorDate: Date;
        ResourceFilter: Text;
        jobFilter: Text;
        JobTaskFilter: Text;

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
        if jobFilter <> '' then
            DHXDataHandler.GetDayPlanningAsResourcesAndEventsJSon_Project_StartEnd(startDate,
                                                                          endDate,
                                                                          jobFilter,
                                                                          JobTaskFilter,
                                                                          ResourceJSONTxt,
                                                                          EventsJsonTxt,
                                                                          EarliestPlanningDate)
        else
            DHXDataHandler.GetDayPlanningAsResourcesAndEventsJSon_Project_StartEnd(startDate,
                                                                          endDate,
                                                                          ResourceFilter,
                                                                          ResourceJSONTxt,
                                                                          EventsJsonTxt,
                                                                          EarliestPlanningDate);
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