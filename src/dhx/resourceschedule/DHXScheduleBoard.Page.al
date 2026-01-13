page 50619 "DHX Scheduler (Resource)"
{
    PageType = Card; //userControlHost;
    ApplicationArea = All;
    UsageCategory = Tasks;
    Caption = 'Resource Planning Lines (DHX)';

    layout
    {
        area(content)
        {
            usercontrol(DhxScheduler; "DHXResourceScheduleAddin")
            {
                ApplicationArea = All;

                #region Init and Load Data on Control Ready

                trigger ControlReady()
                var
                    startDate: Date;
                    endDate: Date;
                    EarliestPlanningDate: Date;
                    PlanninJsonTxt: Text;
                    ResourceJSONTxt: Text;
                begin
                    //DHXDataHandler.GetOneYearPeriodDates(Today(), startDate, endDate);
                    DHXDataHandler.GetWeekPeriodDates(Today(), startDate, endDate);
                    ResourceJSONTxt := DHXDataHandler.GetYUnitElementsJSON_Resource(Today(), startDate, endDate, false, PlanninJsonTxt, EarliestPlanningDate);
                    CurrPage.DhxScheduler.Init(ResourceJSONTxt, EarliestPlanningDate);
                    CurrPage.DhxScheduler.LoadData(PlanninJsonTxt);
                    AnchorDate := startDate;
                end;

                #endregion Init and Load Data on Control Ready

                #region Section doubleclick

                trigger OnSectionDblClick(sectionId: Text; sectionData: Text; viewdate: Text)
                var
                    DHXDataHandler: Codeunit "DHX Data Handler";
                    PossibleChanges: Boolean;
                    newEventData: Text;
                    _DateTime: Datetime;
                    _DateTimeUserZone: Datetime;
                    StartDate: Date;
                begin
                    //View Date: 2025-12-21T17:00:00.000Z
                    DHXDataHandler.OpenResourceCard(sectionId);
                    // Refresh the schedule after possible changes
                    Evaluate(_DateTime, viewdate);
                    _DateTimeUserZone := DHXDataHandler.ConvertToUserTimeZone(_DateTime);
                    StartDate := DT2Date(_DateTimeUserZone);
                    AnchorDate := StartDate;
                    RefreshSchedule(ShowHideDayTasks);
                end;

                #endregion Section doubleclick

                #region Event Double Click

                trigger OnEventDblClick(eventId: Text; eventData: Text)
                var
                    DateRef: Date;
                    evId, StartDateTxt, EndDateTxt, SectionId, pText, Type : Text;
                begin
                    //Message('Event double clicked with eventData: %1 , eventId = %2', eventData, eventId);
                    DHXDataHandler.GetEventData(eventData, evId, StartDateTxt, EndDateTxt, SectionId, pText, Type);
                    case Type of
                        'capacity':
                            begin
                                DateRef := DHXDataHandler.OpenCapacity(eventId); //DHXDataHandler.OpenDayTask(eventId);
                                if DateRef <> 0D then begin
                                    AnchorDate := DateRef;
                                    RefreshSchedule(ShowHideDayTasks);
                                end;
                            end;
                        'daytask':
                            begin
                                DateRef := DHXDataHandler.OpenDayTask(eventId);
                                if DateRef <> 0D then begin
                                    AnchorDate := DateRef;
                                    RefreshSchedule(ShowHideDayTasks);
                                end;
                            end;
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

                #region Event Changes
                trigger OnEventChanged(eventId: Text; eventData: Text)
                var
                    DHXDataHandler: Codeunit "DHX Data Handler";
                    DateRef: Date;
                begin
                    DHXDataHandler.OnEventChanged_Resource(eventId,
                                                  eventData,
                                                  DateRef);
                    AnchorDate := DateRef;
                    RefreshSchedule(ShowHideDayTasks);
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
                    JobPlanningLines: record "Job Planning Line";
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
                begin
                    if DHXDataHandler.GetDayTaskAsResourcesAndEventsJSon_Resource(NavigateJson, False, ResourceJSONTxt, EventsJsonTxt) then begin
                        DHXDataHandler.GetStartEndDatesFromTimeLineJSon(NavigateJson, startDate, endDate);
                        CurrPage.DhxScheduler.RefreshTimeline(ResourceJSONTxt, EventsJsonTxt, startDate); //TODO: pass resourcesJson and eventsJson
                        AnchorDate := startDate;
                    end;
                end;
                #endregion Timeline Navigate
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
                    RefreshSchedule(ShowHideDayTasks);
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
                    RefreshSchedule(ShowHideDayTasks);
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
                    RefreshSchedule(ShowHideDayTasks);
                end;
            }

            action(Refresh)
            {
                Caption = 'Refresh';
                ApplicationArea = All;
                Image = Refresh;
                trigger OnAction()
                begin
                    RefreshSchedule(ShowHideDayTasks);
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
                        RefreshSchedule(ShowHideDayTasks);
                    end;
                end;
            }

            group(Daytask)
            {
                Caption = 'Day Tasks';
                action(ShowDayTask)
                {
                    ApplicationArea = All;
                    Caption = 'Show Day Tasks';
                    Image = AddWatch;
                    trigger OnAction()
                    begin
                        ShowHideDayTasks := true;
                        RefreshSchedule(ShowHideDayTasks);
                    end;
                }
                action(HideDayTask)
                {
                    ApplicationArea = All;
                    Caption = 'Hide Day Tasks';
                    Image = RemoveContacts;
                    trigger OnAction()
                    begin
                        ShowHideDayTasks := false;
                        RefreshSchedule(ShowHideDayTasks);
                    end;
                }
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
                actionref("Refresh_filter"; Refresh) { }
                actionref("Show_DayTask"; ShowDayTask) { }
                actionref("Hide_DayTask"; HideDayTask) { }
            }
        }
    }

    var
        DHXDataHandler: Codeunit "DHX Data Handler";
        ShowDefaultTabs: Boolean;
        AnchorDate: Date;
        ShowHideDayTasks: Boolean;

    local procedure RefreshSchedule(WithDayTask: Boolean)
    var
        DHXDataHandler: Codeunit "DHX Data Handler";
        startDate: Date;
        endDate: Date;
        ResourceJSONTxt: Text;
        EventsJsonTxt: Text;
        EarliestPlanningDate: Date;
    begin
        DHXDataHandler.GetWeekPeriodDates(AnchorDate, startDate, endDate);
        DHXDataHandler.GetDayTaskAsResourcesAndEventsJSon_Resource_StartEnd(startDate,
                                                                      endDate,
                                                                      WithDayTask,
                                                                      ResourceJSONTxt,
                                                                      EventsJsonTxt,
                                                                      EarliestPlanningDate);
        CurrPage.DhxScheduler.RefreshTimeline(ResourceJSONTxt, EventsJsonTxt, startDate);
    end;

}