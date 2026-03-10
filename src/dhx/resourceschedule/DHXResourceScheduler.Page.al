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

        }

        area(Promoted)
        {

        }
    }

    var
        ResourceFilter: Text;

    local procedure BuildResourcesJson(): Text
    var
        Res: record Resource;

        JArray: JsonArray;
        JObj: JsonObject;
        JRoot: JsonObject;
        Result: Text;
    begin
        // loop over Resource record and add each as { id, name, group }
        Res.Reset();
        if ResourceFilter <> '' then
            Res.SetFilter("No.", ResourceFilter);
        if Res.FindSet() then
            repeat
                Clear(JObj);
                JObj.Add('id', Res."No.");
                JObj.Add('name', Res.Name);
                JObj.Add('group', Res."Resource Group No.");
                JArray.Add(JObj);
            until Res.Next() = 0;

        Clear(JRoot);
        JRoot.Add('data', JArray);
        JRoot.WriteTo(Result);
        exit(Result);
    end;

    local procedure BuildEventsJson(): Text
    var
        DayTask: record "Day Tasks";
        DHXHandler: codeunit "DHX Data Handler";
        StarDateTimeStr: Text;
        EndDateTimeStr: Text;
        JArray: JsonArray;
        JObj: JsonObject;
        JRoot: JsonObject;
        Result: Text;
        eventColor: Text;
        eventColorTrack: Integer;
    begin
        // loop over Day Tasks and add each event
        DayTask.Reset();
        DayTask.Setrange(Type, DayTask.Type::Resource);
        if ResourceFilter <> '' then
            DayTask.SetFilter("No.", ResourceFilter)
        else
            DayTask.SetFilter("No.", '<>%1', '');
        if DayTask.FindSet() then
            repeat
                eventColorTrack += 1;
                case eventColorTrack of
                    1:
                        eventColor := 'blue';
                    2:
                        eventColor := 'green';
                    3:
                        eventColor := 'violet';
                end;
                DHXHandler.GetStartEndTxt(DayTask, StarDateTimeStr, EndDateTimeStr);
                AddEvent(JArray,
                            format(DayTask.RecordId), // Using RecId as unique event ID
                            DayTask."No.",
                            eventColor,
                            StarDateTimeStr,
                            EndDateTimeStr,
                            DayTask.Description);
                if eventColorTrack = 3 then
                    eventColorTrack := 0;
            until DayTask.Next() = 0;

        Clear(JRoot);
        JRoot.Add('data', JArray);
        JRoot.WriteTo(Result);
        exit(Result);
    end;

    local procedure AddEvent(var JArray: JsonArray; RecordId: Text; ResourceId: Text; Classname: Text; StartDate: Text; EndDate: Text; EventText: Text)
    var
        JObj: JsonObject;
    begin
        Clear(JObj);
        JObj.Add('id', RecordId);
        JObj.Add('resource_id', ResourceId);
        JObj.Add('classname', Classname);
        JObj.Add('start_date', StartDate);
        JObj.Add('end_date', EndDate);
        JObj.Add('text', EventText);
        JArray.Add(JObj);
    end;

    procedure SetResourceFilter(pResourceFilter: Text)
    begin
        ResourceFilter := pResourceFilter;
    end;
}