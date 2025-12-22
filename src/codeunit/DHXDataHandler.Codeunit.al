codeunit 50604 "DHX Data Handler"
{
    trigger OnRun()
    begin

    end;

    var
        myInt: Integer;

    //     '{' +
    //         '"data": [ ' +
    //             '{key:10, label:"Web Testing Dep.", open: true, children: [' +
    //             '    {key:20, label:"Elizabeth Taylor"},' +
    //             '    {key:30, label:"Managers", open: true, children: [' +
    //             '        {key:40, label:"John Williams"},' +
    //             '        {key:50, label:"David Miller"}' +
    //             '    ]},' +
    //             '    {key:60, label:"Linda Brown"},' +
    //             '    {key:70, label:"George Lucas"}' +
    //             ']},' +
    //             '{key:80, label:"Kate Moss"},' +
    //             '{key:90, label:"Dian Fossey"}' +
    //         ']' +
    //     '}';

    // for Event Data:
    // scheduler.parse([
    //     {"id":2,"start_date":"2022-06-30 13:40","end_date":"2022-06-30 19:40","text":"Task A-89411","section_id":"20"},
    //     {"id":3,"start_date":"2022-06-30 11:40","end_date":"2022-06-30 13:30","text":"Task A-64168","section_id":"20"},
    //     {"id":4,"start_date":"2022-06-30 09:25","end_date":"2022-06-30 12:10","text":"Task A-46598","section_id":"40"},
    //     {"id":6,"start_date":"2022-06-30 13:45","end_date":"2022-06-30 15:05","text":"Task B-44864","section_id":"40"},
    //     {"id":7,"start_date":"2022-06-30 16:30","end_date":"2022-06-30 18:00","text":"Task B-46558","section_id":40},
    //     {"id":8,"start_date":"2022-06-30 18:30","end_date":"2022-06-30 20:00","text":"Task B-45564","section_id":40},
    //     {"id":9,"start_date":"2022-06-30 08:35","end_date":"2022-06-30 11:35","text":"Task C-32421","section_id":"20"},
    //     {"id":10,"start_date":"2022-06-30 14:30","end_date":"2022-06-30 16:45","text":"Task C-14244","section_id":"50"},
    //     {"id":11,"start_date":"2022-06-30 12:00","end_date":"2022-06-30 15:00","text":"Task D-52688","section_id":"70"},
    //     {"id":12,"start_date":"2022-06-30 10:45","end_date":"2022-06-30 14:20","text":"Task D-46588","section_id":"60"},
    //     {"id":13,"start_date":"2022-06-30 13:25","end_date":"2022-06-30 17:40","text":"Task D-12458","section_id":"60"},
    //     {"section_id":"90","start_date":"2022-06-30 11:55","end_date":"2022-06-30 16:30","text":"New event 90 | id=14","$new":"true","id":14},
    //     {"section_id":"60","start_date":"2022-06-30 08:40","end_date":"2022-06-30 12:50","text":"New event 60 | id=18","$new":"true","id":18},
    //     {"section_id":"60","start_date":"2022-06-30 18:20","end_date":"2022-06-30 19:20","text":"New event 60 | id=19","$new":"true","id":19},
    //     {"section_id":"70","start_date":"2022-06-30 10:40","end_date":"2022-06-30 12:20","text":"New event 70 | id=20","$new":"true","id":20},
    //     {"section_id":"70","start_date":"2022-06-30 15:35","end_date":"2022-06-30 19:00","text":"New event 70 | id=21","$new":"true","id":21},
    //     {"section_id":"60","start_date":"2022-06-30 08:30","end_date":"2022-06-30 09:20","text":"New event 60 | id=22","$new":"true","id":22},
    //     {"section_id":"20","start_date":"2025-11-29 09:05","end_date":"2025-11-29 11:20","text":"New event 20 | id=23","$new":"true","id":23},
    //     {"section_id":"40","start_date":"2025-11-24 08:15","end_date":"2025-11-24 14:15","text":"New event 40 | id=24","$new":"true","id":24},
    //     {"section_id":"80","start_date":"2025-11-24 09:50","end_date":"2025-11-24 15:15","text":"New event 80 | id=25","$new":"true","id":25},
    //     {"section_id":"40","start_date":"2025-11-24 11:35","end_date":"2025-11-24 18:55","text":"New event 40 | id=26","$new":"true","id":26}]);

    procedure GetYUnitElementsJSON(StartDate: Date;
                                   EndDate: Date;
                                   var PlanninJsonTxt: Text;
                                   var EarliestPlanningDate: Date): Text
    var
        Jobs: Record Job;
        JobTasks: Record "Job Task";
        PlanningLine: Record "Job Planning Line";
        Daytask: Record "Day Tasks";
        WeekTemp: record "Aging Band Buffer" temporary;

        JobObject, TaskObject, PlanningLineObject : JsonObject;
        ChildrenArray, ChildrenArray2 : JsonArray;
        PlanningObject, Root : JsonObject;
        PlanningArray, DataArray : JsonArray;
        OutText: Text;

        StartDateTxt: Text;
        EndDateTxt: Text;
    begin
        PlanninJsonTxt := '';
        //Marking Job based on Day Tasks within the given date range
        Daytask.SetRange("Start Planning Date", StartDate, EndDate);
        Daytask.SetFilter("Job No.", '<>%1', ''); //Exclude blank Job Nos
        Daytask.SetFilter("Job Task No.", '<>%1', ''); //Exclude blank task Nos
        Daytask.SetRange(Type, Daytask.Type::Resource);
        if Daytask.FindSet() then begin
            repeat
                Jobs.Get(Daytask."Job No.");
                Jobs.Mark(true);
                // create event data
                CountToWeekNumber(Daytask."Start Planning Date", WeekTemp);
                GetStartEndTxt(Daytask, StartDateTxt, EndDateTxt);
                Clear(PlanningObject);
                PlanningObject.Add('id', Daytask."Job No." + '|' + Daytask."Job Task No." + '|' + Format(Daytask."Job Planning Line No.") + '|' + Format(Daytask."Day No."));
                PlanningObject.Add('start_date', StartDateTxt);
                PlanningObject.Add('end_date', EndDateTxt);
                PlanningObject.Add('text', Daytask.Description);
                PlanningObject.Add('section_id', Daytask."Job No." + '|' + Daytask."Job Task No." + '|' + Format(Daytask."Job Planning Line No."));
                PlanningArray.Add(PlanningObject);
                PlanningArray.WriteTo(PlanninJsonTxt);
            until Daytask.Next() = 0;

            WeekTemp.Reset();
            WeekTemp.SetCurrentKey("Column 3 Amt.");
            WeekTemp.FindSet();
            if WeekTemp.FindLast() then begin
                EarliestPlanningDate := DWY2Date(1, WeekTemp."Column 2 Amt.", WeekTemp."Column 1 Amt.");
            end;
        end;
        Jobs.MarkedOnly := true;
        if Jobs.FindSet() then begin
            Clear(DataArray);
            repeat
                JobTasks.SetRange("Job No.", Jobs."No.");
                JobTasks.SetRange("Job Task Type", JobTasks."Job Task Type"::Posting);

                Clear(JobObject);
                JobObject.Add('key', Jobs."No."); // string keys are fine
                JobObject.Add('label', StrSubstNo('%1 - %2', Jobs."No.", Jobs.Description));
                JobObject.Add('open', true);

                Clear(ChildrenArray);
                if JobTasks.FindSet() then begin
                    repeat
                        Clear(TaskObject);
                        TaskObject.Add('key', Jobs."No." + '|' + JobTasks."Job Task No.");
                        TaskObject.Add('label', StrSubstNo('%1 - %2', JobTasks."Job Task No.", JobTasks.Description));
                        ChildrenArray.Add(TaskObject);

                        // Now add children for this task (the Day Tasks)                        
                        Clear(ChildrenArray2);
                        PlanningLine.SetRange("Job No.", Jobs."No.");
                        PlanningLine.SetRange("Job Task No.", JobTasks."Job Task No.");
                        if PlanningLine.FindSet() then begin
                            repeat
                                Clear(PlanningLineObject);
                                PlanningLineObject.Add('key', Jobs."No." + '|' + JobTasks."Job Task No." + '|' + Format(PlanningLine."Line No."));
                                PlanningLineObject.Add('label', PlanningLine.Description);
                                ChildrenArray2.Add(PlanningLineObject);
                            until PlanningLine.Next() = 0;
                        end;
                        TaskObject.Add('children', ChildrenArray2);
                    until JobTasks.Next() = 0;
                end;
                JobObject.Add('children', ChildrenArray);
                DataArray.Add(JobObject);
            until Jobs.Next() = 0;
            Clear(Root);
            Root.Add('data', DataArray);

            // Write JSON to text
            Root.WriteTo(OutText);
            exit(OutText);
        end;
        exit('');
    end;

    local procedure CountToWeekNumber(DateToCount: Date; var WeekTemp: record "Aging Band Buffer" temporary)
    var
        yw: Code[6];
    begin
        if DateToCount = 0D then
            exit;
        yw := format(Date2DWY(DateToCount, 3)) + format(Date2DWY(DateToCount, 2));
        if not WeekTemp.Get(yw) then begin
            WeekTemp.Init();
            WeekTemp."Currency Code" := yw;
            WeekTemp."Column 1 Amt." := Date2DWY(DateToCount, 3); //Year
            WeekTemp."Column 2 Amt." := Date2DWY(DateToCount, 2); //Week No
            WeekTemp."Column 3 Amt." := 1;
            WeekTemp.Insert();
        end else begin
            WeekTemp."Column 3 Amt." += 1;
            WeekTemp.Modify();
        end;
    end;

    local procedure GetStartEndTxt(JobPlaningLine: Record "Job Planning Line";
                                   var StartDateTxt: Text;
                                   var EndDateTxt: Text)
    var
    begin
        StartDateTxt := '';
        EndDateTxt := '';
        case true of
            (JobPlaningLine."Start Planning Date" <> 0D) and (JobPlaningLine."Start Time" <> 0T):
                StartDateTxt := Format(JobPlaningLine."Start Planning Date", 0, '<Year4>-<Month,2>-<Day,2>') + ' ' + Format(JobPlaningLine."Start Time");
            (JobPlaningLine."Start Planning Date" <> 0D) and (JobPlaningLine."Start Time" = 0T):
                StartDateTxt := Format(JobPlaningLine."Start Planning Date", 0, '<Year4>-<Month,2>-<Day,2>') + ' 00:00';
            (JobPlaningLine."Start Planning Date" = 0D) and (JobPlaningLine."Start Time" <> 0T),
            (JobPlaningLine."Start Planning Date" = 0D) and (JobPlaningLine."Start Time" = 0T):
                StartDateTxt := '';
        end;

        case true of
            (JobPlaningLine."End Planning Date" = 0D) and (JobPlaningLine."End Time" <> 0T):
                EndDateTxt := Format(JobPlaningLine."Start Planning Date", 0, '<Year4>-<Month,2>-<Day,2>') + ' ' + Format(JobPlaningLine."End Time");
            (JobPlaningLine."End Planning Date" <> 0D) and (JobPlaningLine."End Time" <> 0T):
                EndDateTxt := Format(JobPlaningLine."End Planning Date", 0, '<Year4>-<Month,2>-<Day,2>') + ' ' + Format(JobPlaningLine."End Time");
            (JobPlaningLine."End Planning Date" = 0D) and (JobPlaningLine."End Time" = 0T):
                EndDateTxt := Format(JobPlaningLine."Start Planning Date", 0, '<Year4>-<Month,2>-<Day,2>') + ' 00:00';
            (JobPlaningLine."End Planning Date" <> 0D) and (JobPlaningLine."End Time" = 0T):
                EndDateTxt := Format(JobPlaningLine."End Planning Date", 0, '<Year4>-<Month,2>-<Day,2>') + ' 00:00';
        end;
    end;

    local procedure GetStartEndTxt(DayTask: Record "Day Tasks";
                                   var StartDateTxt: Text;
                                   var EndDateTxt: Text)
    var
    begin
        StartDateTxt := '';
        EndDateTxt := '';
        if DayTask."Start Planning Date" = 0D then
            exit;
        case true of
            (DayTask."Start Time" <> 0T) and (DayTask."End Time" <> 0T):
                begin
                    StartDateTxt := Format(DayTask."Start Planning Date", 0, '<Year4>-<Month,2>-<Day,2>') + ' ' + Format(DayTask."Start Time");
                    EndDateTxt := Format(DayTask."Start Planning Date", 0, '<Year4>-<Month,2>-<Day,2>') + ' ' + Format(DayTask."End Time");
                end;
            (DayTask."Start Time" <> 0T) and (DayTask."End Time" = 0T):
                begin
                    StartDateTxt := Format(DayTask."Start Planning Date", 0, '<Year4>-<Month,2>-<Day,2>') + ' ' + Format(DayTask."Start Time");
                    EndDateTxt := Format(DayTask."Start Planning Date", 0, '<Year4>-<Month,2>-<Day,2>') + ' 23:59:59';
                end;
            (DayTask."Start Time" = 0T) and (DayTask."End Time" <> 0T):
                begin
                    StartDateTxt := Format(DayTask."Start Planning Date", 0, '<Year4>-<Month,2>-<Day,2>') + ' 00:00';
                    EndDateTxt := Format(DayTask."Start Planning Date", 0, '<Year4>-<Month,2>-<Day,2>') + ' ' + Format(DayTask."End Time");
                end;
            (DayTask."Start Time" = 0T) and (DayTask."End Time" = 0T):
                begin
                    StartDateTxt := Format(DayTask."Start Planning Date", 0, '<Year4>-<Month,2>-<Day,2>') + ' 00:00';
                    EndDateTxt := Format(DayTask."Start Planning Date", 0, '<Year4>-<Month,2>-<Day,2>') + ' 23:59:59';
                end;
        end;
    end;

    procedure GetWeekPeriodDates(CurrentDate: Date; var StartDay: Date; var EndDay: Date)
    var
        WeekNo: Integer;
        YearNo: Integer;
    begin
        if CurrentDate = 0D then
            CurrentDate := Today();

        WeekNo := Date2DWY(CurrentDate, 2);
        YearNo := Date2DWY(CurrentDate, 3);

        StartDay := DWY2Date(1, WeekNo, YearNo); // Monday
        EndDay := DWY2Date(7, WeekNo, YearNo);   // Sunday
    end;

    procedure GetOneYearPeriodDates(CurrentDate: Date; var StartDate: Date; var EndDate: Date)
    begin
        StartDate := CalcDate('<-CY>', CurrentDate);
        EndDate := CalcDate('<CY>', CurrentDate)
    end;

    procedure onEventAdded(EventData: Text; var UpdateEventIdJsonTxt: Text): Boolean
    var
        Task: record "Job Task";
        PlanningLine: record "Job Planning Line";
        Res: record Resource;
        EventJSonObj: JsonObject;
        JToken: JsonToken;
        SectionIdParts: List of [Text];
        JobNo: Code[20];
        TaskNo: Code[20];
        LineNo: Integer;
        ResNo: Code[20];
        rtv: Boolean;
        old_eventid: Text;
        _Date: Date;
        _Time: Time;
        PlanningDate: Date;
        StartTime: Time;
        EndPlanningDate: Date;
        EndTime: Time;
        Desc: Text;
        JsonLbl: Label '{"OldEventId": "%1", "NewEventId": "%2|%3|%4"}';
    begin
        //Message('New Event Created with eventData = %2', eventData);
        /*
        eventData = 
        {
            "id":1765956958574,
            "text":"New event",
            "start_date":"2025-11-07T20:30:00.000Z",
            "end_date":"2025-11-08T23:00:00.000Z",
            "section_id":"JOB00010|1010",
            "resource_id":"HESSEL",
            "resource_name":"Hessel Wanders"
        }
        */
        EventJSonObj.ReadFrom(EventData);
        EventJSonObj.Get('section_id', JToken);
        SectionIdParts := JToken.AsValue().AsText().Split('|');
        JobNo := SectionIdParts.Get(1);
        TaskNo := SectionIdParts.Get(2);
        Task.Get(JobNo, TaskNo);

        EventJSonObj.Get('id', JToken);
        old_eventid := JToken.AsValue().AsText();

        EventJSonObj.Get('start_date', JToken);
        ParseIsoToDateTime(JToken.AsValue().AsText(), _Date, _Time);
        PlanningDate := _Date;
        StartTime := _Time;

        EventJSonObj.Get('end_date', JToken);
        ParseIsoToDateTime(JToken.AsValue().AsText(), _Date, _Time);
        EndPlanningDate := _Date;
        EndTime := _Time;

        // EventJSonObj.Get('text', JToken);
        // Desc := JToken.AsValue().AsText();

        EventJSonObj.Get('resource_id', JToken);
        Res.Get(JToken.AsValue().AsText().ToUpper());

        LineNo := 10000;
        PlanningLine.SetRange("Job No.", JobNo);
        PlanningLine.SetRange("Job Task No.", TaskNo);
        if PlanningLine.FindLast() then
            LineNo := PlanningLine."Line No." + 10000;

        PlanningLine.Init();
        PlanningLine."Job No." := JobNo;
        PlanningLine."Job Task No." := TaskNo;
        PlanningLine."Line No." := LineNo;
        PlanningLine.Type := PlanningLine.Type::Resource;
        PlanningLine."No." := Res."No.";
        PlanningLine."Start Planning Date" := PlanningDate;
        PlanningLine."Start Time" := StartTime;
        PlanningLine."End Planning Date" := EndPlanningDate;
        PlanningLine."End Time" := EndTime;
        PlanningLine.Description := Res.Name;
        UpdateEventIdJsonTxt := StrSubstNo(JsonLbl,
                                            old_eventid,
                                            PlanningLine."Job No.",
                                            PlanningLine."Job Task No.",
                                            Format(PlanningLine."Line No."));
        rtv := PlanningLine.Insert();
        exit(rtv);
    end;

    procedure OnEventChanged(EventId: Text;
                             EventData: Text;
                             var UpdateEventID: Boolean;
                             var OldPlanningLine_forUpdate: record "Job Planning Line";
                             var NewPlanningLine_forUpdate: record "Job Planning Line")
    var
        OldTask: record "Job Task";
        NewTask: record "Job Task";
        OldPlanningLine: record "Job Planning Line";
        PlanningLineCheck: record "Job Planning Line";

        EventJSonObj: JsonObject;
        JToken: JsonToken;
        EventIdParts: List of [Text];
        NewSectionParts: List of [Text];
        Old_JobNo: Text;
        Old_TaskNo: Text;
        Old_PlanningLineNo: Integer;
        New_JobNo: Text;
        New_TaskNo: Text;
        _Date: Date;
        _Time: Time;
    begin
        Message('Event ' + eventId + ' changed: ' + eventData);
        /*        
        sift left / right:
            eventId = JOB00010|1020|10000
            eventData = 
                {
                    "id":"JOB00010|1020|10000",
                    "text":"Vacant Resource",
                    "start_date":"2025-11-05T05:00:00.000Z",
                    "end_date":"2025-11-06T04:00:00.000Z",
                    "section_id":"JOB00010|1020"
                }
        sift up / down
            eventId = JOB00010|1020|10000
            eventData = 
                {
                    "id":"JOB00010|1020|10000",
                    "text":"Vacant Resource",
                    "start_date":"2025-11-05T05:00:00.000Z",
                    "end_date":"2025-11-06T04:00:00.000Z",
                    "section_id":"JOB00010|1030"
                }
        */
        // get old record
        EventIdParts := eventId.Split('|');
        Old_JobNo := EventIdParts.Get(1);
        Old_TaskNo := EventIdParts.Get(2);
        Evaluate(Old_PlanningLineNo, EventIdParts.Get(3));
        OldTask.Get(Old_JobNo, Old_TaskNo);
        OldPlanningLine.Get(Old_JobNo, Old_TaskNo, Old_PlanningLineNo);

        EventJSonObj.ReadFrom(EventData);

        EventJSonObj.Get('section_id', JToken);
        NewSectionParts := JToken.AsValue().AsText().Split('|');
        New_JobNo := NewSectionParts.Get(1);
        New_TaskNo := NewSectionParts.Get(2);
        NewTask.Get(New_JobNo, New_TaskNo);

        UpdateEventID := false;
        OldPlanningLine_forUpdate := OldPlanningLine;
        if OldTask.RecordId <> NewTask.RecordId then begin
            //sift up / down within different task
            if not PlanningLineCheck.Get(New_JobNo, New_TaskNo, Old_PlanningLineNo) then
                OldPlanningLine.Rename(New_JobNo, New_TaskNo, Old_PlanningLineNo)
            else begin
                PlanningLineCheck.SetRange("Job No.", New_JobNo);
                PlanningLineCheck.SetRange("Job Task No.", New_TaskNo);
                if PlanningLineCheck.FindLast() then
                    OldPlanningLine.Rename(New_JobNo, New_TaskNo, PlanningLineCheck."Line No." + 10000)
                else
                    OldPlanningLine.Rename(New_JobNo, New_TaskNo, 10000);
            end;
            NewPlanningLine_forUpdate := OldPlanningLine;
            UpdateEventID := true;
        end;

        //sift left / right to same task
        EventJSonObj.Get('start_date', JToken);
        ParseIsoToDateTime(JToken.AsValue().AsText(), _Date, _Time);
        OldPlanningLine."Start Planning Date" := _Date;
        OldPlanningLine."Start Time" := _Time;

        EventJSonObj.Get('end_date', JToken);
        ParseIsoToDateTime(JToken.AsValue().AsText(), _Date, _Time);
        OldPlanningLine."End Planning Date" := _Date;
        OldPlanningLine."End Time" := _Time;

        EventJSonObj.Get('text', JToken);
        OldPlanningLine.Description := JToken.AsValue().AsText();

        OldPlanningLine.Modify();

        if UpdateEventID then
            UpdateEventID(OldPlanningLine_forUpdate, NewPlanningLine_forUpdate);
    end;

    procedure UpdateEventID(OldPlanningLine: Record "Job Planning Line"; NewPlanningLine: Record "Job Planning Line"): Text
    var
        rtv: text;
        JsonLbl: Label '{"OldEventId": "%1|%2|%3", "NewEventId": "%4|%5|%6"}';
    begin
        rtv := StrSubstNo(JsonLbl,
                         OldPlanningLine."Job No.",
                         OldPlanningLine."Job Task No.",
                         Format(OldPlanningLine."Line No."),
                         NewPlanningLine."Job No.",
                         NewPlanningLine."Job Task No.",
                         Format(NewPlanningLine."Line No."));
        exit(rtv);
    end;

    procedure ParseIsoToDateTime(IsoTxt: Text; var OutDate: Date; var OutTime: Time)
    var
        dtTxt: Text;
        dt: DateTime;
    begin
        // Normalize: replace 'T' with space and remove trailing 'Z'
        dtTxt := IsoTxt.Replace('T', ' ');
        if dtTxt.EndsWith('Z') then
            dtTxt := CopyStr(dtTxt, 1, StrLen(dtTxt) - 1);

        // Evaluate into DateTime
        if not Evaluate(dt, dtTxt) then
            Error('Invalid datetime: %1', IsoTxt);

        // Extract Date and Time (in UTC as provided)
        OutDate := DT2Date(dt);
        OutTime := DT2Time(dt);
    end;

    procedure OpenJobPlanningLineCard(eventId: Text; var possibleChanges: Boolean)
    var
        JobPlanningLines: Record "Job Planning Line";
        JobPlanningLineCard: Page "Job Planning Line Card";
        EventIDList: List of [Text];
        JobNo: Code[20];
        TaskNo: Code[20];
        PlanningLineNo: Integer;
        DayTaskNo: Integer;
    begin
        // Implementation to open the Job Planning Line Card based on eventId
        //Message('Event Double Clicked with ID: %1', eventId);
        EventIDList := eventId.Split('|');
        JobNo := EventIDList.Get(1);
        TaskNo := EventIDList.Get(2);
        Evaluate(PlanningLineNo, EventIDList.Get(3));
        Evaluate(DayTaskNo, EventIDList.Get(4));
        if JobPlanningLines.Get(JobNo, TaskNo, PlanningLineNo) then begin
            Clear(JobPlanningLineCard);
            JobPlanningLineCard.SetTableView(JobPlanningLines);
            JobPlanningLineCard.RunModal();
            possibleChanges := true
        end else begin
            possibleChanges := false;
            Message('Job Planning Line not found for Event ID: %1', eventId);
        end;
    end;
}