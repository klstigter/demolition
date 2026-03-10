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

    local procedure BuildResourcesJson(): Text
    var
        JArray: JsonArray;
        JObj: JsonObject;
        JRoot: JsonObject;
        Result: Text;
    begin
        // TODO: Replace this dummy data with real BC Resource table query
        // e.g. loop over Resource record and add each as { id, name, group }

        Clear(JObj);
        JObj.Add('id', 'R001');
        JObj.Add('name', 'Ahmad Hassan');
        JObj.Add('group', 'Team A');
        JArray.Add(JObj);
        Clear(JObj);
        JObj.Add('id', 'R002');
        JObj.Add('name', 'Sarah Johnson');
        JObj.Add('group', 'Team A');
        JArray.Add(JObj);
        Clear(JObj);
        JObj.Add('id', 'R003');
        JObj.Add('name', 'Mike Peters');
        JObj.Add('group', 'Team B');
        JArray.Add(JObj);
        Clear(JObj);
        JObj.Add('id', 'R004');
        JObj.Add('name', 'Emma Wilson');
        JObj.Add('group', 'Team B');
        JArray.Add(JObj);
        Clear(JObj);
        JObj.Add('id', 'R005');
        JObj.Add('name', 'Tom Baker');
        JObj.Add('group', 'Team C');
        JArray.Add(JObj);
        Clear(JObj);
        JObj.Add('id', 'R006');
        JObj.Add('name', 'Lisa Chang');
        JObj.Add('group', 'Team C');
        JArray.Add(JObj);

        Clear(JRoot);
        JRoot.Add('data', JArray);
        JRoot.WriteTo(Result);
        exit(Result);
    end;

    local procedure BuildEventsJson(): Text
    var
        JArray: JsonArray;
        JObj: JsonObject;
        JRoot: JsonObject;
        Result: Text;
    begin
        // TODO: Replace this dummy data with real BC data
        // e.g. loop over Job Planning Lines / Day Tasks and add each event

        // Team A - Ahmad Hassan (R001)
        AddEvent(JArray, 101, 'R001', 'blue', '2026-03-09 08:00', '2026-03-09 12:00', 'Site Inspection');
        AddEvent(JArray, 102, 'R001', 'green', '2026-03-10 13:00', '2026-03-10 17:00', 'Demolition Planning');
        AddEvent(JArray, 103, 'R001', 'violet', '2026-03-11 09:00', '2026-03-11 11:00', 'Safety Briefing');
        // Team A - Sarah Johnson (R002)
        AddEvent(JArray, 201, 'R002', 'yellow', '2026-03-09 07:00', '2026-03-09 15:00', 'Equipment Setup');
        AddEvent(JArray, 202, 'R002', 'green', '2026-03-11 10:00', '2026-03-11 14:00', 'Concrete Breaking');
        AddEvent(JArray, 203, 'R002', 'blue', '2026-03-12 08:00', '2026-03-12 16:00', 'Wall Removal');
        // Team B - Mike Peters (R003)
        AddEvent(JArray, 301, 'R003', 'violet', '2026-03-09 06:00', '2026-03-09 10:00', 'Crane Operation');
        AddEvent(JArray, 302, 'R003', 'blue', '2026-03-10 08:00', '2026-03-10 12:00', 'Debris Removal');
        AddEvent(JArray, 303, 'R003', 'yellow', '2026-03-13 09:00', '2026-03-13 17:00', 'Excavation');
        // Team B - Emma Wilson (R004)
        AddEvent(JArray, 401, 'R004', 'green', '2026-03-10 07:00', '2026-03-10 11:00', 'Structural Survey');
        AddEvent(JArray, 402, 'R004', 'violet', '2026-03-11 13:00', '2026-03-11 18:00', 'Report Writing');
        AddEvent(JArray, 403, 'R004', 'blue', '2026-03-14 08:00', '2026-03-14 12:00', 'Client Meeting');
        // Team C - Tom Baker (R005)
        AddEvent(JArray, 501, 'R005', 'yellow', '2026-03-09 09:00', '2026-03-09 13:00', 'Machine Maintenance');
        AddEvent(JArray, 502, 'R005', 'green', '2026-03-12 10:00', '2026-03-12 15:00', 'Pipe Cutting');
        AddEvent(JArray, 503, 'R005', 'blue', '2026-03-13 08:00', '2026-03-13 12:00', 'Welding Work');
        // Team C - Lisa Chang (R006)
        AddEvent(JArray, 601, 'R006', 'violet', '2026-03-10 06:00', '2026-03-10 10:00', 'Waste Sorting');
        AddEvent(JArray, 602, 'R006', 'yellow', '2026-03-11 07:00', '2026-03-11 11:00', 'Hazmat Disposal');
        AddEvent(JArray, 603, 'R006', 'green', '2026-03-14 13:00', '2026-03-14 17:00', 'Site Cleanup');

        Clear(JRoot);
        JRoot.Add('data', JArray);
        JRoot.WriteTo(Result);
        exit(Result);
    end;

    local procedure AddEvent(var JArray: JsonArray; EventId: Integer; ResourceId: Text; Classname: Text; StartDate: Text; EndDate: Text; EventText: Text)
    var
        JObj: JsonObject;
    begin
        Clear(JObj);
        JObj.Add('id', EventId);
        JObj.Add('resource_id', ResourceId);
        JObj.Add('classname', Classname);
        JObj.Add('start_date', StartDate);
        JObj.Add('end_date', EndDate);
        JObj.Add('text', EventText);
        JArray.Add(JObj);
    end;
}