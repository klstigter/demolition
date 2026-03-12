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