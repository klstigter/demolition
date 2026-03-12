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
                begin
                    CurrPage.DhxScheduler.LoadData(BuildEventsJson());
                    CurrPage.DhxScheduler.LoadCapacity(BuildCapacityJson());
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

    trigger OnOpenPage()
    begin
        ShowDayTask := true;
        ShowCapacity := true;
    end;

    var
        ResourceFilter: Text;
        ShowDayTask: Boolean;
        ShowCapacity: Boolean;

    local procedure BuildResourcesJson(): Text
    var
        DHXHandler: Codeunit "DHX Data Handler";
    begin
        exit(DHXHandler.ResScheduler_BuildResourcesJson(ResourceFilter));
    end;

    local procedure BuildEventsJson(): Text
    var
        DHXHandler: Codeunit "DHX Data Handler";
    begin
        exit(DHXHandler.ResScheduler_BuildEventsJson(ResourceFilter));
    end;

    local procedure AddEvent(var JArray: JsonArray; RecordId: Text; ResourceId: Text; Classname: Text; StartDate: Text; EndDate: Text; EventText: Text; pType: Text)
    var
        DHXHandler: Codeunit "DHX Data Handler";
    begin
        DHXHandler.ResScheduler_AddEvent(JArray, RecordId, ResourceId, Classname, StartDate, EndDate, EventText, pType);
    end;

    local procedure BuildCapacityJson(): Text
    var
        DHXHandler: Codeunit "DHX Data Handler";
    begin
        exit(DHXHandler.ResScheduler_BuildCapacityJson(ResourceFilter));
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