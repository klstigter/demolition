page 50600 "Schedule Board"
{
    PageType = Card; //userControlHost;
    ApplicationArea = All;
    UsageCategory = Tasks;
    Caption = 'Project Planning Lines';

    layout
    {
        area(content)
        {
            usercontrol(DayPilotScheduler; "DayPilotSchedulerAddIn")
            {
                ApplicationArea = All;

                trigger ControlReady()
                begin
                    CurrPage.DayPilotScheduler.Init(StartDate);
                    CurrPage.DayPilotScheduler.LoadData(ResourceTxt, EventTxt, StartDate, Days);
                end;

                trigger OnBookingChanged(bookingJson: Text)
                var
                    JobPlanningLineHandler: Codeunit "Job Planning Line Handler";
                begin
                    clear(JobPlanningLineHandler);
                    JobPlanningLineHandler.Bookingchanged(bookingJson);
                end;

                trigger OnBookingCreated(bookingJson: Text)
                var
                    Resource: Record Resource;
                    JobPlanningLineHandler: Codeunit "Job Planning Line Handler";
                    NewBubbleHtml: Text;
                    NewId: Text;
                    NewText: Text;

                    ResourceSelectionPage: page "Resource Selection";
                    SelectedResourcesJsonTxt: text;
                    NewEventJsonArray: JsonArray;
                    NewEventTok: JsonToken;

                    id: Text;
                    txt: Text;
                    resourceTxt: Text;
                    bubbleHtml: Text;
                    startDt: DateTime;
                    endDt: DateTime;
                    Parts: List of [Text];
                    JobNo: Code[20];
                    TaskNo: Code[20];

                    i: Integer;
                begin
                    clear(JobPlanningLineHandler);
                    JobPlanningLineHandler.GetEventValues(bookingJson,
                                                        id,
                                                        txt,
                                                        bubbleHtml,
                                                        startDt,
                                                        endDt,
                                                        resourceTxt);
                    Parts := resourceTxt.Split('|');
                    Evaluate(JobNo, Parts.Get(1));
                    Evaluate(TaskNo, Parts.Get(2));
                    if TaskNo = '' then
                        Error('Please select time period on Task row');

                    Clear(ResourceSelectionPage);
                    ResourceSelectionPage.LookupMode(true);
                    ResourceSelectionPage.SetPageVar(JobNo, TaskNo, startDt, endDt);
                    if ResourceSelectionPage.RunModal() = Action::LookupOK then begin
                        ResourceSelectionPage.GetSelection(SelectedResourcesJsonTxt);
                        if SelectedResourcesJsonTxt = '' then
                            SelectedResourcesJsonTxt := '[]';
                        if JobPlanningLineHandler.BookingCreated2(SelectedResourcesJsonTxt, NewEventJsonArray) then begin
                            // Loop event in NewEventJsonArray, create DayPilot Event in the loop
                            for i := 0 to NewEventJsonArray.Count() - 1 do begin
                                NewEventJsonArray.Get(i, NewEventTok);
                                NewEventTok.WriteTo(bookingJson);
                                // Notify JS of the result                    
                                CurrPage.DayPilotScheduler.OnBookingCreatedFeedback(bookingJson);
                            end;
                        end;
                    end;
                    //>>                  
                end;

                trigger OnEventRightClicked(bookingJson: Text)
                var
                    JObPlanningLine: Record "Job Planning Line";
                    JobPlanningLineHandler: Codeunit "Job Planning Line Handler";

                    EventOptionsQst: Label '&Edit Description,&Delete';
                    Selection: Integer;
                    DefaultOption: Integer;

                    id: Text;
                    txt: Text;
                    resource: Text;
                    bubbleHtml: Text;
                    startDt: DateTime;
                    endDt: DateTime;
                    Parts: List of [Text];
                    JobNo: Code[20];
                    TaskNo: Code[20];
                    LineNo: Integer;
                begin
                    DefaultOption := 1;
                    Selection := StrMenu(EventOptionsQst, DefaultOption);
                    if Selection = 0 then
                        exit;

                    //<< get orig property
                    JobPlanningLineHandler.GetEventValues(bookingJson,
                                                        id,
                                                        txt,
                                                        bubbleHtml,
                                                        startDt,
                                                        endDt,
                                                        resource);

                    Parts := id.Split('|');
                    Evaluate(JobNo, Parts.Get(1));
                    Evaluate(taskNo, Parts.Get(2));
                    Evaluate(LineNo, Parts.Get(3));
                    //>>

                    case Selection of
                        1:
                            CurrPage.DayPilotScheduler.EditEventDescription(bookingJson);
                        2:
                            begin
                                if JObPlanningLine.Get(JobNo, TaskNo, LineNo) then
                                    if JObPlanningLine.Delete(true) then
                                        CurrPage.DayPilotScheduler.deleteEventById(id);
                            end;
                    end;
                end;

                trigger OnAfterEditDescription(bookingJson: Text)
                var
                    JobPlanningLineHandler: Codeunit "Job Planning Line Handler";
                begin
                    JobPlanningLineHandler.EditDescription(bookingJson);
                end;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(RefreshDayPilot)
            {
                Caption = 'Refresh Board';
                ApplicationArea = All;

                trigger OnAction()
                begin
                    CurrPage.DayPilotScheduler.RefreshDayPilot();
                end;
            }

            action(DayPilotDataChecked)
            {
                Caption = 'Data check';
                ApplicationArea = All;
                trigger OnAction()
                begin
                    CurrPage.DayPilotScheduler.DataCheck();
                    Message('Open Developer mode to read the DayPilot Data');
                end;
            }

            action(DayPilotRemoveAllEvents)
            {
                Caption = 'Remove All Events';
                ApplicationArea = All;
                trigger OnAction()
                var
                    ConfLbl: Label 'All events will remove';
                begin
                    if not confirm(ConfLbl) then
                        exit;
                    CurrPage.DayPilotScheduler.RemoveAllEvents();
                end;
            }

        }
    }

    var
        ResourceTxt: Text;
        EventTxt: Text;
        StartDate: Text;
        Days: Integer;

    procedure SetResoucesAndEventJsonTxt(pResourceTxt: Text;
                                         pEventTxt: Text;
                                         pStartDate: Text;
                                         pDays: Integer)
    begin
        ResourceTxt := pResourceTxt;
        EventTxt := pEventTxt;
        StartDate := pStartDate;
        Days := pDays;
    end;
}