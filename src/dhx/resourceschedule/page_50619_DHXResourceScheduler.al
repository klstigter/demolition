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

                field(ShowDayTaskFld; ShowDayTask)
                {
                    ApplicationArea = All;
                    Caption = 'Show Day Task';
                    trigger OnValidate()
                    begin
                        CurrPage.DhxScheduler.SetShowDayTask(ShowDayTask);
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
                    CurrPage.DhxScheduler.Init(BuildResourcesJson(), Today());
                end;

                trigger OnAfterInit()
                var
                    DHXHandler: Codeunit "DHX Data Handler";
                begin
                    DHXHandler.GetWeekPeriodDates(Today(), CurrentStartDate, CurrentEndDate);
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
                    DayTaskRec: record "Day Tasks";
                    RecRef: RecordRef;
                    RecId: RecordId;
                begin
                    if Evaluate(RecId, EventId) then begin
                        RecRef.Get(RecId);
                        RecRef.SetTable(DayTaskRec);
                        Page.Run(Page::"Day Tasks", DayTaskRec);
                    end else begin
                        DayTaskRec.SetFilter("No.", ResourceId);
                        Page.Run(Page::"Day Tasks", DayTaskRec);
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
                    DayTaskRec: record "Day Tasks";
                    ResRec: Record Resource;
                    ResCapacity: Page "Resource Capacity";
                    DayTaskList: page "Day Tasks";
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
                            // Only fired for daytask events (hidden for capacity in JS)
                            if ResRec.Get(ResourceId) then
                                Page.Run(Page::"Resource Card", ResRec);
                        'OpenDayTask':
                            begin
                                message('ResourceId = %1, DT1 = %2, DT2 = %3', ResourceId, DT1, DT2);
                                DayTaskRec.SetRange("No.", ResourceId);
                                DayTaskRec.SetRange("Task Date", DT1, DT2);
                                DayTaskList.SetTableView(DayTaskRec);
                                DayTaskList.Run();
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
                    Daytasks: record "Day Tasks";
                    DayTaskList: page "Day Tasks";
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
                        'OpenDayTask':
                            begin
                                //message('exec OpenDayTask, parameter ResourceId: %1, PeriodStart: %2, PeriodEnd: %3', ResourceId, PeriodStart, PeriodEnd);
                                Daytasks.SetRange("No.", ResourceId);
                                Daytasks.SetRange("Task Date", DT1, DT2);
                                DayTaskList.SetTableView(Daytasks);
                                DayTaskList.Run();
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
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                actionref(Category_Process_01; "Resource Capacities") { }
            }
        }
    }

    trigger OnOpenPage()
    begin
        ShowDayTask := true;
        ShowCapacity := true;
    end;

    var
        ResourceFilter: Text;
        ShowDayTask: Boolean;
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
}