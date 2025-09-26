codeunit 50601 "Job Planning Line Handler"
{

    [EventSubscriber(ObjectType::Table, Database::"Job Planning Line", 'OnBeforeOnRename', '', false, false)]
    local procedure OnBeforeOnRename(var JobPlanningLine: Record "Job Planning Line"; var IsHandled: Boolean)
    begin
        IsHandled := true; //Allow rename Job Planning Line
    end;

    procedure OpentaskSchedulerFromJob(Job: record Job)
    var
        task: record "Job Task";
        JobPlaningLine: Record "Job Planning Line";
        TempDateVar: Record Date temporary;
        ScheduleBoard: page "Schedule Board";
        TaskArray: JsonArray;
        TaskObj: JsonObject;
        ResourceTxt: Text;
        EventArray: JsonArray;
        EventObj: JsonObject;
        EventTxt: Text;
        DT2: Date;
        StartDate: Text;
        Days: Integer;
    begin
        task.CalcFields("Start Date", "End Date");
        task.SetRange("Job No.", Job."No.");
        task.SetRange("Job Task Type", task."Job Task Type"::Posting);
        task.SetFilter("Start Date", '<>%1', 0D);
        task.SetFilter("End Date", '<>%1', 0D);
        task.FindSet(); //show error if no records

        // Create Planning Resources + events
        Clear(TaskArray);
        Clear(EventArray);
        TempDateVar.Reset();
        TempDateVar.DeleteAll();
        repeat
            // Resources
            Clear(TaskObj);
            TaskObj.Add('id', task."Job No." + '|' + task."Job Task No.");
            TaskObj.Add('name', task."Job Task No." + ' - ' + task.Description);
            TaskArray.Add(TaskObj);

            /*
            {
                "id":"dc125b26-7ed7-5283-609a-22866ef12639",
                "text":"New Booking",
                "start":"2025-01-01T09:00:00",
                "end":"2025-01-01T12:00:00",
                "resource":"B",
                "bubbleHtml":"New Booking"}
            */

            // Events            
            JobPlaningLine.SetRange("Job No.", task."Job No.");
            JobPlaningLine.SetRange("Job Task No.", task."Job Task No.");
            if JobPlaningLine.findset then
                repeat
                    Clear(EventObj);

                    //Manage days
                    if JobPlaningLine."Planning Date" <> 0D then
                        if not TempDateVar.Get(TempDateVar."Period Type"::Date, JobPlaningLine."Planning Date") then begin
                            TempDateVar.Init();
                            TempDateVar."Period Type" := TempDateVar."Period Type"::Date;
                            TempDateVar."Period Start" := JobPlaningLine."Planning Date";
                            TempDateVar.Insert();
                        end;
                    if JobPlaningLine."End Planning Date" <> 0D then
                        if not TempDateVar.Get(TempDateVar."Period Type"::Date, JobPlaningLine."End Planning Date") then begin
                            TempDateVar.Init();
                            TempDateVar."Period Type" := TempDateVar."Period Type"::Date;
                            TempDateVar."Period Start" := JobPlaningLine."End Planning Date";
                            TempDateVar.Insert();
                        end;

                    EventObj.Add('id', task."Job No." + '|' + task."Job Task No." + '|' + format(JobPlaningLine."Line No."));
                    EventObj.Add('text', JobPlaningLine.Description);
                    EventObj.Add('start', GetTaskDateTime(JobPlaningLine."Planning Date", JobPlaningLine."Start Time", false));
                    DT2 := JobPlaningLine."Planning Date";
                    if JobPlaningLine."End Planning Date" <> 0D then
                        DT2 := JobPlaningLine."End Planning Date";
                    EventObj.Add('end', GetTaskDateTime(DT2, JobPlaningLine."End Time", true));
                    EventObj.Add('resource', task."Job No." + '|' + task."Job Task No.");
                    EventObj.Add('bubbleHtml', CreateBubbleHtmlFromPlanningLine(JobPlaningLine));
                    EventArray.Add(EventObj);
                until JobPlaningLine.Next() = 0;
        until task.Next() = 0;

        TempDateVar.Reset();
        Days := TempDateVar.Count + 1;
        TempDateVar.FindFirst();
        StartDate := Format(TempDateVar."Period Start", 0, '<Year4>-<Month,2>-<Day,2>');
        TaskArray.WriteTo(ResourceTxt);
        EventArray.WriteTo(EventTxt);

        Clear(ScheduleBoard);
        ScheduleBoard.SetResoucesAndEventJsonTxt(ResourceTxt, EventTxt, StartDate, Days);
        ScheduleBoard.RunModal();
    end;

    procedure OpenTaskSchedulerAllJob()
    var
        Jobs: Record Job;
        JobTasks: Record "Job Task";
        JobPlaningLine: Record "Job Planning Line";
        TempDateVar: Record Date temporary;

        ScheduleBoard: page "Schedule Board";

        JsonArray: JsonArray;
        JobObject: JsonObject;
        TasksArray: JsonArray;
        TaskObject: JsonObject;

        EventObj: JsonObject;
        EventArray: JsonArray;

        DT: Date;
        DT1: Date;
        DT2: Date;
        ResourceTxt: Text;
        EventTxt: Text;
        Days: Integer;
        StartDate: Text;
        i: Integer;
    begin
        Jobs.Reset();
        if Jobs.FindSet() then begin
            repeat
                JobTasks.SetRange("Job No.", Jobs."No.");
                JobTasks.SetRange("Job Task Type", JobTasks."Job Task Type"::Posting);
                if JobTasks.FindSet() then begin
                    Clear(JobObject);
                    JobObject.Add('name', Jobs."No." + ' - ' + Jobs.Description);
                    JobObject.Add('id', Jobs."No." + '|');
                    JobObject.Add('expanded', true);

                    Clear(TasksArray);
                    repeat
                        Clear(TaskObject);
                        TaskObject.Add('name', JobTasks."Job Task No." + ' - ' + JobTasks.Description);
                        TaskObject.Add('id', Jobs."No." + '|' + JobTasks."Job Task No.");
                        TasksArray.Add(TaskObject);
                    until JobTasks.Next() = 0;

                    JobObject.Add('children', TasksArray);
                    JsonArray.Add(JobObject);
                end;
            until Jobs.Next() = 0;
        end;

        /**/
        //Create Events from JOb Planning Lines
        TempDateVar.Reset();
        TempDateVar.DeleteAll();
        JobPlaningLine.Reset();
        JobPlaningLine.SetFilter("Start Time", '<>%1', 0T);
        JobPlaningLine.SetFilter("End Time", '<>%1', 0T);
        if JobPlaningLine.findset then
            repeat
                i += 1;
                Clear(EventObj);
                //Manage days
                if JobPlaningLine."Planning Date" <> 0D then
                    if not TempDateVar.Get(TempDateVar."Period Type"::Date, JobPlaningLine."Planning Date") then begin
                        TempDateVar.Init();
                        TempDateVar."Period Type" := TempDateVar."Period Type"::Date;
                        TempDateVar."Period Start" := JobPlaningLine."Planning Date";
                        TempDateVar.Insert();
                    end;
                if JobPlaningLine."End Planning Date" <> 0D then
                    if not TempDateVar.Get(TempDateVar."Period Type"::Date, JobPlaningLine."End Planning Date") then begin
                        TempDateVar.Init();
                        TempDateVar."Period Type" := TempDateVar."Period Type"::Date;
                        TempDateVar."Period Start" := JobPlaningLine."End Planning Date";
                        TempDateVar.Insert();
                    end;

                EventObj.Add('id', JobPlaningLine."Job No." + '|' + JobPlaningLine."Job Task No." + '|' + format(JobPlaningLine."Line No."));
                EventObj.Add('text', JobPlaningLine.Description);
                EventObj.Add('start', GetTaskDateTime(JobPlaningLine."Planning Date", JobPlaningLine."Start Time", false));
                DT := JobPlaningLine."Planning Date";
                if JobPlaningLine."End Planning Date" <> 0D then
                    DT := JobPlaningLine."End Planning Date";
                EventObj.Add('end', GetTaskDateTime(DT, JobPlaningLine."End Time", true));
                EventObj.Add('resource', JobPlaningLine."Job No." + '|' + JobPlaningLine."Job Task No.");
                EventObj.Add('bubbleHtml', CreateBubbleHtmlFromPlanningLine(JobPlaningLine));

                if (i mod 2) = 0 then
                    EventObj.Add('barColor', 'red')
                else
                    EventObj.Add('barColor', 'blue');

                EventArray.Add(EventObj);

            until JobPlaningLine.Next() = 0;
        /**/

        TempDateVar.Reset();
        TempDateVar.FindFirst();
        DT1 := TempDateVar."Period Start";
        StartDate := Format(DT1, 0, '<Year4>-<Month,2>-<Day,2>');
        TempDateVar.FindLast();
        DT2 := TempDateVar."Period Start";
        Days := (DT2 - DT1) + 2;

        JsonArray.WriteTo(ResourceTxt);
        EventArray.WriteTo(EventTxt);

        Clear(ScheduleBoard);
        ScheduleBoard.SetResoucesAndEventJsonTxt(ResourceTxt, EventTxt, StartDate, Days);
        ScheduleBoard.RunModal();
    end;

    procedure DownloadJsonText(JsonText: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        InStr: InStream;
        CekFile: Text;
    begin
        Clear(TempBlob);
        if JsonText = '' then
            Error('%1 is empty', CekFile);
        CekFile := 'Resource.txt';
        TempBlob.CreateOutStream(OutStr);
        OutStr.WriteText(JsonText);
        TempBlob.CreateInStream(InStr);
        DownloadFromStream(InStr, '', '', '', CekFile);
    end;

    procedure CreateBubbleHtmlFromPlanningLine(JobPlaningLine: Record "Job Planning Line"): Text
    var
        html: Text;
    begin
        html := '<table>';
        html += '<tr><td>Project No.</td><td>:&nbsp;' + JobPlaningLine."Job No." + '</td></tr>';
        html += '<tr><td>Task No.</td><td>:&nbsp;' + JobPlaningLine."Job Task No." + '</td></tr>';
        html += '<tr><td>Desc</td><td>:&nbsp;' + JobPlaningLine.Description + '</td></tr>';
        html += '<tr><td>Start - End</td><td>:&nbsp;' + GetStartEndTxt(JobPlaningLine) + '</td></tr>';
        html += '</table>';
        exit(html);
    end;

    procedure ReplaceBubbleHtmlAndId(var bookingJson: Text; newBubbleHtml: Text; NewId: text; NewText: Text)
    var
        jsonObj: JsonObject;
    begin
        jsonObj.ReadFrom(bookingJson);

        // Remove old property if it exists
        if jsonObj.Contains('bubbleHtml') then begin
            jsonObj.Remove('bubbleHtml');
            // Add new property
            jsonObj.Add('bubbleHtml', newBubbleHtml);
        end;
        if jsonObj.Contains('id') then begin
            jsonObj.Remove('id');
            // Add new property
            jsonObj.Add('id', NewId);
        end;

        if jsonObj.Contains('text') then begin
            jsonObj.Remove('text');
            // Add new property
            jsonObj.Add('text', NewText);
        end else
            jsonObj.Add('text', NewText);

        // Convert back to string
        jsonObj.WriteTo(bookingJson);
    end;

    local procedure GetStartEndTxt(JobPlaningLine: Record "Job Planning Line"): Text
    var
        rtv: Text;
    begin
        case true of
            (JobPlaningLine."Planning Date" <> 0D) and (JobPlaningLine."Start Time" <> 0T):
                rtv := Format(CreateDateTime(JobPlaningLine."Planning Date", JobPlaningLine."Start Time"));
            (JobPlaningLine."Planning Date" <> 0D) and (JobPlaningLine."Start Time" = 0T):
                rtv := Format(JobPlaningLine."Planning Date") + ' 00:00:00';
            (JobPlaningLine."Planning Date" = 0D) and (JobPlaningLine."Start Time" <> 0T),
            (JobPlaningLine."Planning Date" = 0D) and (JobPlaningLine."Start Time" = 0T):
                rtv := '';
        end;

        case true of
            (JobPlaningLine."End Planning Date" = 0D) and (JobPlaningLine."End Time" <> 0T):
                rtv += ' - ' + Format(CreateDateTime(JobPlaningLine."Planning Date", JobPlaningLine."End Time"));
            (JobPlaningLine."End Planning Date" <> 0D) and (JobPlaningLine."End Time" <> 0T):
                rtv += ' - ' + Format(CreateDateTime(JobPlaningLine."End Planning Date", JobPlaningLine."End Time"));
            (JobPlaningLine."End Planning Date" = 0D) and (JobPlaningLine."End Time" = 0T):
                rtv += ' - ' + Format(JobPlaningLine."Planning Date") + ' 00:00:00';
            (JobPlaningLine."End Planning Date" <> 0D) and (JobPlaningLine."End Time" = 0T):
                rtv += ' - ' + Format(JobPlaningLine."End Planning Date") + ' 00:00:00';
        end;

        exit(rtv);
    end;

    procedure GetTaskDateTime(DT: Date; TM: time; endTime: Boolean): Text
    var
        ErrLbl: Label 'Invalid date submitted = 0D';
    begin
        if DT = 0D then
            Error(ErrLbl);
        if TM = 0T then begin
            if not endTime then
                exit(Format(DT, 0, '<Year4>-<Month,2>-<Day,2>') + 'T00:00:00')
            else
                exit(Format(DT, 0, '<Year4>-<Month,2>-<Day,2>') + 'T23:59:59');
        end;
        exit(Format(DT, 0, '<Year4>-<Month,2>-<Day,2>') + 'T' + format(TM, 0, '<Hours24,2><Filler Character,0>:<Minutes,2>:<Seconds,2>'));
    end;

    /*
    Booking changed: 
    {
    "id":"PR00010|220",
     "text":"Delivery",
     "start":"2025-06-04T03:00:00",
     "end":"2025-06-04T03:00:00.001",
     "resource":"PR00010|220",
     "bubbleHtml":"Delivery"
     }
    */
    procedure Bookingchanged(bookingJson: Text)
    var
        JobTask: record "Job Task";
        JobPlanningLine: record "Job Planning Line";
        JobPlanningLineCheck: record "Job Planning Line";
        id: Text;
        txt: Text;
        resource: Text;
        bubbleHtml: Text;
        startDt: DateTime;
        endDt: DateTime;
        Parts: List of [Text];
        JobNo: Code[20];
        TaskNo: Code[20];
        TaskNo2: Code[20];
        LineNo: Integer;
        NewLineNo: Integer;
    begin
        //Message('Booking changed: %1', bookingJson);

        GetEventValues(bookingJson,
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

        Parts := resource.Split('|');
        Evaluate(taskNo2, Parts.Get(2));

        JobPlanningLine.Get(JobNo, TaskNo, LineNo);
        if taskNo <> taskNo2 then begin
            //Check planning line based on JobNo, taskNo2, LineNo
            if not JobPlanningLineCheck.Get(JobNo, taskNo2, LineNo) then
                JobPlanningLine.Rename(JobNo, taskNo2, LineNo)
            else begin
                NewLineNo := 10000;
                JobPlanningLineCheck.Reset();
                JobPlanningLineCheck.SetRange("Job No.", JobNo);
                JobPlanningLineCheck.SetRange("Job Task No.", taskNo2);
                if JobPlanningLineCheck.FindLast() then
                    NewLineNo := JobPlanningLineCheck."Line No.";
                NewLineNo += 10000;
                JobPlanningLine.Rename(JobNo, taskNo2, NewLineNo);
            end;
            JobPlanningLine.Get(JobNo, TaskNo2, LineNo);
        end;
        JobPlanningLine."Planning Date" := DT2Date(startDt);
        JobPlanningLine."Start Time" := DT2Time(startDt);
        JobPlanningLine."End Planning Date" := DT2Date(endDt);
        JobPlanningLine."End Time" := DT2Time(endDT);
        JobPlanningLine.Modify();
    end;

    procedure BookingCreated(bookingJson: Text;
                             ResNo: Code[20];
                             var NewBubbleHtml: Text;
                             var NewId: Text;
                             NewText: Text): Boolean
    var
        JobTask: record "Job Task";
        JobPlanningLine: record "Job Planning Line";
        rtv: Boolean;
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
        rtv := false;

        GetEventValues(bookingJson,
                       id,
                       txt,
                       bubbleHtml,
                       startDt,
                       endDt,
                       resource);

        if resource <> '' then begin
            Parts := resource.Split('|');
            Evaluate(JobNo, Parts.Get(1));
            Evaluate(taskNo, Parts.Get(2));
            JobTask.Get(JobNo, TaskNo);
            JobPlanningLine.Setrange("Job No.", JobNo);
            JobPlanningLine.SetRange("Job Task No.", TaskNo);
            LineNo := 10000;
            if JobPlanningLine.FindLast() then
                LineNo := JobPlanningLine."Line No.";
            LineNo += 10000;
            JobPlanningLine.Init();
            JobPlanningLine."Job No." := JobNo;
            JobPlanningLine."Job Task No." := TaskNo;
            JobPlanningLine."Line No." := LineNo;
            JobPlanningLine."Job Task No." := TaskNo;
            JobPlanningLine."Line Type" := JobPlanningLine."Line Type"::"Both Budget and Billable";
            JobPlanningLine.Description := NewText;
            JobPlanningLine."Planning Date" := DT2Date(startDt);
            JobPlanningLine."Start Time" := DT2Time(startDt);
            JobPlanningLine."End Time" := DT2Time(endDt);
            JobPlanningLine.Type := JobPlanningLine.Type::Resource;
            JobPlanningLine."No." := ResNo;
            if JobPlanningLine.Insert() then begin
                rtv := true;
                NewId := JobPlanningLine."Job No." + '|' + JobPlanningLine."Job Task No." + '|' + format(JobPlanningLine."Line No.");
                NewBubbleHtml := CreateBubbleHtmlFromPlanningLine(JobPlanningLine);
            end;
        end;

        exit(rtv);
    end;

    procedure BookingCreated2(bookingArrayJson: Text; var NewEventJsonArray: JsonArray): Boolean
    var
        JobTask: record "Job Task";
        JobPlanningLine: record "Job Planning Line";
        JobPlanningLineHandler: Codeunit "Job Planning Line Handler";

        InArr: JsonArray;
        EventObj: JsonObject;
        Tok, EventIdTok, resourceTok, txtTok, startTxtTok, endTxtTok : JsonToken;
        i: Integer;

        rtv: Boolean;
        id: Text;
        txt: Text;
        resource: Text;
        bubbleHtml: Text;
        startTxt: Text;
        startDt: DateTime;
        endTxt: Text;
        endDt: DateTime;
        ResNo: Code[20];
        Parts: List of [Text];
        _Date: Date;
        _Time: Time;

        JobNo: Code[20];
        TaskNo: Code[20];
        LineNo: Integer;
    begin
        Clear(NewEventJsonArray);
        rtv := false;
        if not InArr.ReadFrom(bookingArrayJson) then
            Error('Invalid JSON');
        for i := 0 to InArr.Count() - 1 do begin
            InArr.Get(i, Tok);
            if Tok.IsObject() and Tok.AsObject().Get('id', EventIdTok) then begin
                id := EventIdTok.AsValue().AsText();
                Parts := id.Split('|');
                Evaluate(JobNo, Parts.Get(1));
                Evaluate(taskNo, Parts.Get(2));
                Evaluate(ResNo, Parts.Get(3));

                Tok.AsObject().Get('resource', resourceTok);
                resource := resourceTok.AsValue().AsText();

                Tok.AsObject().Get('text', txtTok);
                txt := txtTok.AsValue().AsText();

                Tok.AsObject().Get('start', startTxtTok);
                startTxt := startTxtTok.AsValue().AsText();
                Parts := startTxt.Split('T');
                Evaluate(_Date, Parts.Get(1));
                Evaluate(_Time, Parts.Get(2));
                startDt := CreateDateTime(_Date, _Time);

                Tok.AsObject().Get('end', endTxtTok);
                endTxt := endTxtTok.AsValue().AsText();
                Parts := endTxt.Split('T');
                Evaluate(_Date, Parts.Get(1));
                Evaluate(_Time, Parts.Get(2));
                endDt := CreateDateTime(_Date, _Time);

                JobTask.Get(JobNo, TaskNo);
                JobPlanningLine.Setrange("Job No.", JobNo);
                JobPlanningLine.SetRange("Job Task No.", TaskNo);
                LineNo := 10000;
                if JobPlanningLine.FindLast() then
                    LineNo := JobPlanningLine."Line No.";
                LineNo += 10000;
                JobPlanningLine.Init();
                JobPlanningLine."Job No." := JobNo;
                JobPlanningLine."Job Task No." := TaskNo;
                JobPlanningLine."Line No." := LineNo;
                JobPlanningLine."Job Task No." := TaskNo;
                JobPlanningLine."Line Type" := JobPlanningLine."Line Type"::"Both Budget and Billable";
                JobPlanningLine.Description := txt;
                JobPlanningLine."Planning Date" := DT2Date(startDt);
                JobPlanningLine."Start Time" := DT2Time(startDt);
                JobPlanningLine."End Time" := DT2Time(endDt);
                JobPlanningLine.Type := JobPlanningLine.Type::Resource;
                JobPlanningLine."No." := ResNo;
                if JobPlanningLine.Insert() then begin
                    rtv := true;
                    // Create EventJson, add into NewEventJsonArray
                    Clear(EventObj);
                    EventObj.Add('id', JobPlanningLine."Job No." + '|' + JobPlanningLine."Job Task No." + '|' + Format(JobPlanningLine."Line No.")); //now we know Line No.
                    EventObj.Add('text', JobPlanningLine.Description);
                    EventObj.Add('start', JobPlanningLineHandler.GetTaskDateTime(JobPlanningLine."Planning Date", JobPlanningLine."Start Time", false));
                    _Date := JobPlanningLine."Planning Date";
                    if JobPlanningLine."End Planning Date" <> 0D then
                        _Date := JobPlanningLine."End Planning Date";
                    EventObj.Add('end', JobPlanningLineHandler.GetTaskDateTime(_Date, JobPlanningLine."End Time", true));
                    EventObj.Add('resource', JobPlanningLine."Job No." + '|' + JobPlanningLine."Job Task No.");
                    EventObj.Add('bubbleHtml', CreateBubbleHtmlFromPlanningLine(JobPlanningLine));
                    NewEventJsonArray.Add(EventObj);
                end;
            end;
        end;

        exit(rtv);
    end;

    procedure EditDescription(bookingJson: Text)
    var
        JobPlanningLine: record "Job Planning Line";

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
        Message(bookingJson);
        GetEventValues(bookingJson,
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
        if JobPlanningLine.Get(JobNo, TaskNo, LineNo) then begin
            JobPlanningLine.Description := txt;
            JobPlanningLine.Modify();
        end;
    end;

    procedure GetEventValues(bookingJson: Text;
                            var id: Text;
                            var txt: Text;
                            var bubbleHtml: Text;
                            var startDt: DateTime;
                            var endDt: DateTime;
                            var resource: Text)
    var
        obj: JsonObject;
        tok: JsonToken;
        startTxt: Text;
        endTxt: Text;
        Parts: List of [Text];
        _Date: date;
        _Time: Time;
    begin
        id := '';
        txt := '';
        bubbleHtml := '';
        startDt := 0DT;
        endDt := 0DT;
        resource := '';

        if not obj.ReadFrom(bookingJson) then
            Error('Invalid JSON');

        if obj.Get('id', tok) then
            id := tok.AsValue().AsText();

        if obj.Get('text', tok) then
            txt := tok.AsValue().AsText();

        if obj.Get('resource', tok) then
            resource := tok.AsValue().AsText();

        if obj.Get('bubbleHtml', tok) then
            bubbleHtml := tok.AsValue().AsText();

        if obj.Get('start', tok) then begin
            startTxt := tok.AsValue().AsText();
            Parts := startTxt.Split('T');
            Evaluate(_Date, Parts.Get(1));
            Evaluate(_Time, Parts.Get(2));
            startDt := CreateDateTime(_Date, _Time);
        end;

        if obj.Get('end', tok) then begin
            endTxt := tok.AsValue().AsText();
            Parts := endTxt.Split('T');
            Evaluate(_Date, Parts.Get(1));
            Evaluate(_Time, Parts.Get(2));
            endDt := CreateDateTime(_Date, _Time);
        end;
    end;

}
