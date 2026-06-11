page 50619 "DHX Resource Scheduler"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Tasks;
    Caption = 'Resource Scheduler';

    layout
    {
        area(content)
        {
            group(DisplayOptions)
            {
                Caption = '';
                ShowCaption = false;

                field(ShowDayPlanningFld; ShowDayPlanning)
                {
                    ApplicationArea = All;
                    Caption = 'Show Day Planning';
                    trigger OnValidate()
                    begin
                        CurrPage.DhxScheduler.SetShowDayPlanning(ShowDayPlanning);
                    end;
                }
                field(ShowCapacityFld; ShowCapacity)
                {
                    ApplicationArea = All;
                    Caption = 'Show Capacity';
                    trigger OnValidate()
                    begin
                        CurrPage.DhxScheduler.SetShowCapacity(ShowCapacity);
                    end;
                }
            }
            usercontrol(DhxScheduler; DHXResourceScheduleAddin)
            {
                ApplicationArea = All;

                #region Init and Load Data on Control Ready

                trigger ControlReady()
                begin
                    AnchorDate := Today();
                    if CurrentStartDate <> 0D then
                        AnchorDate := CurrentStartDate;
                    CurrPage.DhxScheduler.Init(BuildResourcesJson(), AnchorDate);
                end;

                trigger OnAfterInit()
                var
                    DHXHandler: Codeunit "DHX Data Handler";
                begin
                    DHXHandler.GetWeekPeriodDates(AnchorDate, CurrentStartDate, CurrentEndDate);
                    CurrPage.DhxScheduler.LoadData(BuildEventsJson(CurrentStartDate, CurrentEndDate));
                    CurrPage.DhxScheduler.LoadCapacity(BuildCapacityJson(CurrentStartDate, CurrentEndDate));
                end;

                trigger OnDateRangeChanged(StartDate: Text; EndDate: Text)
                var
                    SD: Date;
                    ED: Date;
                    Y: Integer;
                    M: Integer;
                    D: Integer;
                begin
                    if (StrLen(StartDate) >= 10) and (StrLen(EndDate) >= 10) then begin
                        Evaluate(Y, CopyStr(StartDate, 1, 4));
                        Evaluate(M, CopyStr(StartDate, 6, 2));
                        Evaluate(D, CopyStr(StartDate, 9, 2));
                        SD := DMY2Date(D, M, Y);
                        Evaluate(Y, CopyStr(EndDate, 1, 4));
                        Evaluate(M, CopyStr(EndDate, 6, 2));
                        Evaluate(D, CopyStr(EndDate, 9, 2));
                        ED := DMY2Date(D, M, Y);
                        if (SD <> 0D) and (ED <> 0D) then begin
                            CurrentStartDate := SD;
                            CurrentEndDate := ED;
                            CurrPage.DhxScheduler.ReloadData(
                                BuildEventsJson(CurrentStartDate, CurrentEndDate),
                                BuildCapacityJson(CurrentStartDate, CurrentEndDate));
                        end;
                    end;
                end;

                trigger OnEventDoubleClick(EventId: Text; ResourceId: Text)
                var
                    DayPlanningRec: record "Day Planning";
                    RecRef: RecordRef;
                    RecId: RecordId;
                begin
                    if Evaluate(RecId, EventId) then begin
                        RecRef.Get(RecId);
                        RecRef.SetTable(DayPlanningRec);
                        Page.Run(Page::"Day Plannings", DayPlanningRec);
                    end else begin
                        DayPlanningRec.SetFilter("Assigned Resource No.", ResourceId);
                        Page.Run(Page::"Day Plannings", DayPlanningRec);
                    end;
                end;

                trigger OnResourceDoubleClick(ResourceId: Text)
                var
                    ResRec: Record Resource;
                begin
                    if ResRec.Get(ResourceId) then
                        Page.Run(Page::"Resource Card", ResRec);
                end;

                trigger OnEventContextMenu(EventId: Text; action: Text; PeriodStart: Text; PeriodEnd: Text; payloadJson: Text)
                var
                    DayPlanningRec: record "Day Planning";
                    ResRec: Record Resource;
                    ResCapacity: Page "Resource Capacity";
                    DayPlanningList: page "Day Plannings";
                    RecRef: RecordRef;
                    RecId: RecordId;
                    Payload: JsonObject;
                    EventDataToken: JsonToken;
                    EventDataObj: JsonObject;
                    ResourceIdToken: JsonToken;
                    EventTypeToken: JsonToken;
                    EventType: Text;
                    ResourceId: Text;
                    Y: Integer;
                    M: Integer;
                    D: Integer;
                    DT1: Date;
                    DT2: Date;
                begin
                    // Parse eventType and resource_id from payloadJson
                    if Payload.ReadFrom(payloadJson) then begin
                        if Payload.Get('eventType', EventTypeToken) then
                            EventType := EventTypeToken.AsValue().AsText();
                        if Payload.Get('eventData', EventDataToken) then begin
                            EventDataObj := EventDataToken.AsObject();
                            if EventDataObj.Get('resource_id', ResourceIdToken) then
                                ResourceId := ResourceIdToken.AsValue().AsText();
                        end;
                    end;

                    // Parse period dates (YYYY-MM-DD)
                    if StrLen(PeriodStart) >= 10 then begin
                        Evaluate(Y, CopyStr(PeriodStart, 1, 4));
                        Evaluate(M, CopyStr(PeriodStart, 6, 2));
                        Evaluate(D, CopyStr(PeriodStart, 9, 2));
                        DT1 := DMY2Date(D, M, Y);
                    end;
                    if StrLen(PeriodEnd) >= 10 then begin
                        Evaluate(Y, CopyStr(PeriodEnd, 1, 4));
                        Evaluate(M, CopyStr(PeriodEnd, 6, 2));
                        Evaluate(D, CopyStr(PeriodEnd, 9, 2));
                        DT2 := DMY2Date(D, M, Y);
                    end;

                    case action of
                        'OpenResource':
                            // Only fired for DayPlanning events (hidden for capacity in JS)
                            if ResRec.Get(ResourceId) then
                                Page.Run(Page::"Resource Card", ResRec);
                        'OpenDayPlanning':
                            begin
                                message('ResourceId = %1, DT1 = %2, DT2 = %3', ResourceId, DT1, DT2);
                                DayPlanningRec.SetRange("Assigned Resource No.", ResourceId);
                                DayPlanningRec.SetRange("Task Date", DT1, DT2);
                                DayPlanningList.SetTableView(DayPlanningRec);
                                DayPlanningList.Run();
                            end;
                        'OpenCapacity':
                            begin
                                ResRec.SetRange("No.", ResourceId);
                                ResCapacity.ResourceFilter(ResRec.GetFilter("No."));
                                ResCapacity.SetTableView(ResRec);
                                ResCapacity.Run();
                            end;
                    end;
                end;

                trigger OnResourceContextMenu(ResourceId: Text; action: Text; PeriodStart: Text; PeriodEnd: Text; payloadJson: Text)
                var
                    ResRec: Record Resource;
                    DayPlannings: record "Day Planning";
                    DayPlanningList: page "Day Plannings";
                    ResCapacity: Page "Resource Capacity";
                    DT1: Date;
                    DT2: Date;
                begin
                    Evaluate(DT1, PeriodStart);
                    Evaluate(DT2, PeriodEnd);
                    case action of
                        'OpenResource':
                            begin
                                if ResRec.Get(ResourceId) then
                                    Page.Run(Page::"Resource Card", ResRec);
                            end;
                        'OpenDayPlanning':
                            begin
                                //message('exec OpenDayPlanning, parameter ResourceId: %1, PeriodStart: %2, PeriodEnd: %3', ResourceId, PeriodStart, PeriodEnd);
                                DayPlannings.SetRange("Assigned Resource No.", ResourceId);
                                DayPlannings.SetRange("Task Date", DT1, DT2);
                                DayPlanningList.SetTableView(DayPlannings);
                                DayPlanningList.Run();
                            end;
                        'OpenCapacity':
                            begin
                                //message('exec OpenCapacity, parameter ResourceId: %1, PeriodStart: %2, PeriodEnd: %3', ResourceId, PeriodStart, PeriodEnd);
                                ResRec.Setrange("No.", ResourceId);
                                ResCapacity.ResourceFilter(ResRec.GetFilter("No."));
                                ResCapacity.SetTableView(ResRec);
                                ResCapacity.Run();
                            end;
                    end;
                end;

                #endregion Init and Load Data on Control Ready


            }
        }
    }

    actions
    {
        area(Processing)
        {
            action("Resource Capacities")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Resource Capacities';
                RunObject = page "Resource Capacity";
                Image = Capacities;
            }
            action("Scheduler Resfresh")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Refresh';
                Image = Refresh;
                trigger OnAction()
                var
                    DHXHandler: Codeunit "DHX Data Handler";
                begin
                    if (CurrentStartDate = 0D) or (CurrentEndDate = 0D) then
                        DHXHandler.GetWeekPeriodDates(AnchorDate, CurrentStartDate, CurrentEndDate);
                    CurrPage.DhxScheduler.ReloadData(
                        BuildEventsJson(CurrentStartDate, CurrentEndDate),
                        BuildCapacityJson(CurrentStartDate, CurrentEndDate));
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                actionref(Category_Process_01; "Resource Capacities") { }
                actionref(Category_Process_02; "Scheduler Resfresh") { }
            }
        }
    }

    trigger OnOpenPage()
    begin
        ShowDayPlanning := true;
        ShowCapacity := true;
    end;

    var
        AnchorDate: Date;
        ResourceFilter: Text;
        ShowDayPlanning: Boolean;
        ShowCapacity: Boolean;
        CurrentStartDate: Date;
        CurrentEndDate: Date;

    local procedure BuildResourcesJson(): Text
    var
        DHXHandler: Codeunit "DHX Data Handler";
    begin
        exit(DHXHandler.ResScheduler_BuildResourcesJson(ResourceFilter));
    end;

    local procedure BuildEventsJson(StartDate: Date; EndDate: Date): Text
    var
        DHXHandler: Codeunit "DHX Data Handler";
    begin
        exit(DHXHandler.ResScheduler_BuildEventsJson(ResourceFilter, StartDate, EndDate));
    end;

    local procedure BuildCapacityJson(StartDate: Date; EndDate: Date): Text
    var
        DHXHandler: Codeunit "DHX Data Handler";
    begin
        exit(DHXHandler.ResScheduler_BuildCapacityJson(ResourceFilter, StartDate, EndDate));
    end;

    local procedure GetResourceColor(pResourceNo: Code[20]; pColorType: Text): Text
    var
        DHXHandler: Codeunit "DHX Data Handler";
    begin
        exit(DHXHandler.ResScheduler_GetResourceColor(pResourceNo, pColorType));
    end;

    procedure SetResourceFilter(pResourceFilter: Text)
    begin
        ResourceFilter := pResourceFilter;
    end;

    procedure SetResourceFilter(pResourceFilter: Text; pStartDateOfWeek: Date; pEndDateOfWeek: Date)
    begin
        ResourceFilter := pResourceFilter;
        CurrentStartDate := pStartDateOfWeek;
        CurrentEndDate := pEndDateOfWeek;
    end;
}