page 50621 "DHX Schedule Board"
{
    PageType = Card; //userControlHost;
    ApplicationArea = All;
    UsageCategory = Tasks;
    Caption = 'Project Planning Lines (DHX)';

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
                    startDate: Date;
                    endDate: Date;
                    EarliestPlanningDate: Date;
                    PlanninJsonTxt: Text;
                    ResourceJSONTxt: Text;
                begin
                    //DHXDataHandler.GetOneYearPeriodDates(Today(), startDate, endDate);
                    DHXDataHandler.GetWeekPeriodDates(Today(), startDate, endDate);
                    ResourceJSONTxt := DHXDataHandler.GetYUnitElementsJSON(Today(), startDate, endDate, PlanninJsonTxt, EarliestPlanningDate);
                    CurrPage.DhxScheduler.Init(ResourceJSONTxt, EarliestPlanningDate);
                    CurrPage.DhxScheduler.LoadData(PlanninJsonTxt);
                end;

                #endregion Init and Load Data on Control Ready

                #region Event Double Click

                trigger OnEventDblClick(eventId: Text; eventData: Text)
                var
                    DHXDataHandler: Codeunit "DHX Data Handler";
                    PossibleChanges: Boolean;
                    newEventData: Text;
                begin
                    DHXDataHandler.OpenJobPlanningLineCard(eventId, PossibleChanges);
                    // Get the latest data after possible changes in day tasks
                    if PossibleChanges then begin
                        if DHXDataHandler.GetEventDataFromEventId(eventId, newEventData) then
                            CurrPage.DhxScheduler.RefreshEventData(newEventData); //update event ID
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
                    UpdateEventID: Boolean;
                    OldDayTask_forUpdate: record "Day Tasks";
                    NewDayTask_forUpdate: record "Day Tasks";
                begin
                    DHXDataHandler.OnEventChanged(eventId,
                                                  eventData,
                                                  UpdateEventID,
                                                  OldDayTask_forUpdate,
                                                  NewDayTask_forUpdate);
                    if UpdateEventID then
                        CurrPage.DhxScheduler.UpdateEventId(DHXDataHandler.UpdateEventID(OldDayTask_forUpdate, NewDayTask_forUpdate)); //update event ID
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
                begin
                    if DHXDataHandler.GetDayTaskAsResourcesAndEventsJSon(NavigateJson, ResourceJSONTxt, EventsJsonTxt) then
                        CurrPage.DhxScheduler.RefreshTimeline(ResourceJSONTxt, EventsJsonTxt); //TODO: pass resourcesJson and eventsJson
                end;
                #endregion Timeline Navigate
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ShowDefaultTabs)
            {
                Caption = 'Show/Hide Day-Week-Month buttons';
                ApplicationArea = All;
                trigger OnAction()
                begin
                    ShowDefaultTabs := not ShowDefaultTabs;
                    CurrPage.DhxScheduler.SetDefaultTabsVisible(ShowDefaultTabs);
                end;
            }

            action(TodayAct)
            {
                Caption = 'Today';
                ApplicationArea = All;
                Image = Position;
                trigger OnAction()
                begin
                    Message('Under Development: Today button clicked');
                end;
            }
            action(PreviousAct)
            {
                Caption = 'Previous';
                ApplicationArea = All;
                Image = PreviousSet;
                trigger OnAction()
                begin
                    Message('Under Development: Previous button clicked');
                end;
            }
            action(NextAct)
            {
                Caption = 'Next';
                ApplicationArea = All;
                Image = NextSet;
                trigger OnAction()
                begin
                    Message('Under Development: Next button clicked');
                end;
            }
        }

        area(Promoted)
        {
            group("DateNav")
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

}