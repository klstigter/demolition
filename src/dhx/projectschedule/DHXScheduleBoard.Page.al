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

                trigger ControlReady()
                var
                    startDate: Date;
                    endDate: Date;
                    EarliestPlanningDate: Date;
                    PlanninJsonTxt: Text;
                    ResourceJSONTxt: Text;
                begin
                    DHXDataHandler.GetOneYearPeriodDates(Today(), startDate, endDate);
                    ResourceJSONTxt := DHXDataHandler.GetYUnitElementsJSON(startDate, endDate, PlanninJsonTxt, EarliestPlanningDate);
                    CurrPage.DhxScheduler.Init(ResourceJSONTxt, EarliestPlanningDate);
                    CurrPage.DhxScheduler.LoadData(PlanninJsonTxt);
                end;

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
                    OldPlanningLine_forUpdate: record "Job Planning Line";
                    NewPlanningLine_forUpdate: record "Job Planning Line";
                begin
                    DHXDataHandler.OnEventChanged(eventId,
                                                  eventData,
                                                  UpdateEventID,
                                                  OldPlanningLine_forUpdate,
                                                  NewPlanningLine_forUpdate);
                    if UpdateEventID then
                        CurrPage.DhxScheduler.UpdateEventId(DHXDataHandler.UpdateEventID(OldPlanningLine_forUpdate, NewPlanningLine_forUpdate)); //update event ID
                end;

                trigger OnAfterEventIdUpdated(oldid: Text; newid: Text)
                begin
                    Message('Event ID updated from %1 to %2', oldid, newid);
                end;
                #endregion

            }
        }
    }

    actions
    {
        area(Processing)
        {

        }
    }

    var
        DHXDataHandler: Codeunit "DHX Data Handler";

}