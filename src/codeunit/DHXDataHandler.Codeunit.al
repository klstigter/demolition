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

    procedure GetYUnitElementsJSON(AnchorDate: Date;
                                   StartDate: Date;
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
        _DummyEndDate: Date;
    begin
        PlanninJsonTxt := '';
        //Marking Job based on Day Tasks within the given date range
        Daytask.SetCurrentKey("Start Planning Date", "Start Time");
        Daytask.SetRange("Start Planning Date", StartDate, EndDate);
        Daytask.SetFilter("Job No.", '<>%1', ''); //Exclude blank Job Nos
        Daytask.SetFilter("Job Task No.", '<>%1', ''); //Exclude blank task Nos
        Daytask.SetFilter("Job Planning Line No.", '<>%1', 0); //Exclude blank Planning Line Nos
        //Daytask.SetRange(Type, Daytask.Type::Resource);
        if Daytask.FindSet() then begin
            repeat
                Jobs.Get(Daytask."Job No.");
                Jobs.Mark(true);

                JobTasks.Get(Daytask."Job No.", Daytask."Job Task No.");
                JobTasks.Mark(true);

                // create event data
                if AnchorDate = 0D then
                    CountToWeekNumber(Daytask."Start Planning Date", WeekTemp);

                GetStartEndTxt(Daytask, StartDateTxt, EndDateTxt);
                Clear(PlanningObject);
                PlanningObject.Add('id', Daytask."Job No." + '|' + Daytask."Job Task No." + '|' + Format(Daytask."Job Planning Line No.") + '|' + Format(Daytask."Day No.") + '|' + Format(Daytask."DayLineNo"));
                PlanningObject.Add('start_date', StartDateTxt);
                PlanningObject.Add('end_date', EndDateTxt);
                PlanningObject.Add('text', Daytask.Description);
                PlanningObject.Add('section_id', Daytask."Job No." + '|' + Daytask."Job Task No." + '|' + Format(Daytask."Job Planning Line No."));
                PlanningArray.Add(PlanningObject);
                PlanningArray.WriteTo(PlanninJsonTxt);
            until Daytask.Next() = 0;

            if AnchorDate = 0D then begin
                WeekTemp.Reset();
                WeekTemp.SetCurrentKey("Column 3 Amt.");
                WeekTemp.FindSet();
                if WeekTemp.FindLast() then begin
                    EarliestPlanningDate := DWY2Date(1, WeekTemp."Column 2 Amt.", WeekTemp."Column 1 Amt.");
                end;
            end else
                GetWeekPeriodDates(AnchorDate, EarliestPlanningDate, _DummyEndDate);
        end;

        JobTasks.MarkedOnly := true;
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
                    StartDateTxt := ToSessionDateTimeTxt(DayTask."Start Planning Date", DayTask."Start Time");
                    EndDateTxt := ToSessionDateTimeTxt(DayTask."Start Planning Date", DayTask."End Time");
                end;
            (DayTask."Start Time" <> 0T) and (DayTask."End Time" = 0T):
                begin
                    StartDateTxt := ToSessionDateTimeTxt(DayTask."Start Planning Date", DayTask."Start Time");
                    EndDateTxt := Format(DayTask."Start Planning Date", 0, '<Year4>-<Month,2>-<Day,2>') + ' 23:59:59';
                end;
            (DayTask."Start Time" = 0T) and (DayTask."End Time" <> 0T):
                begin
                    StartDateTxt := Format(DayTask."Start Planning Date", 0, '<Year4>-<Month,2>-<Day,2>') + ' 00:00';
                    EndDateTxt := ToSessionDateTimeTxt(DayTask."Start Planning Date", DayTask."End Time");
                end;
            (DayTask."Start Time" = 0T) and (DayTask."End Time" = 0T):
                begin
                    StartDateTxt := Format(DayTask."Start Planning Date", 0, '<Year4>-<Month,2>-<Day,2>') + ' 00:00';
                    EndDateTxt := Format(DayTask."Start Planning Date", 0, '<Year4>-<Month,2>-<Day,2>') + ' 23:59:59';
                end;
        end;
    end;

    local procedure ToSessionDateTimeTxt(UtcDate: Date; UtcTime: Time): Text
    var
        IsoTxt: Text;
        UtcDT: DateTime;
        LocalDate: Date;
        LocalTime: Time;
    begin
        // Build a UTC DateTime and let AL convert it to the session time zone
        IsoTxt := Format(UtcDate, 0, '<Year4>-<Month,2>-<Day,2>') + 'T' + Format(UtcTime) + 'Z';
        if not Evaluate(UtcDT, IsoTxt) then
            Error('Invalid UTC date/time: %1 %2', UtcDate, UtcTime);

        LocalDate := DT2Date(UtcDT); // converted to current user's time zone
        LocalTime := DT2Time(UtcDT);

        exit(Format(LocalDate, 0, '<Year4>-<Month,2>-<Day,2>') + ' ' + Format(LocalTime));
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

    procedure GetEventDataFromEventId(EventId: Text; var EventDataJsonTxt: Text): Boolean
    var
        DayTask: record "Day Tasks";
        EventIdParts: List of [Text];
        JobNo: Code[20];
        TaskNo: Code[20];
        PlanningLineNo: Integer;
        DayNo: Integer;
        DayLineNo: Integer;
        rtv: Boolean;
        RefreshLbl: label '{"id": "%1", "text": "%2", "start_date": "%3", "end_date": "%4", "section_id": "%5", "resource_id": "%6", "resource_name": "%7"}';
    begin
        // EventId format: JobNo|TaskNo|PlanningLineNo|DayNo|DayLineNo
        EventIdParts := EventId.Split('|');
        JobNo := EventIdParts.Get(1);
        TaskNo := EventIdParts.Get(2);
        Evaluate(PlanningLineNo, EventIdParts.Get(3));
        Evaluate(DayNo, EventIdParts.Get(4));
        Evaluate(DayLineNo, EventIdParts.Get(5));
        rtv := DayTask.Get(DayNo, DayLineNo, JobNo, TaskNo, PlanningLineNo);
        if rtv then begin
            /**
            * Refresh a single event's data without reloading all events.
            * Accepts a JSON string or object. Updates only fields present.
            * Optionally upserts (adds) the event if it doesn't exist.
            *
            * Example payload:
            * {
            *   "id": "evt-123",
            *   "text": "Updated name",
            *   "start_date": "2025-12-23T08:00:00Z",
            *   "end_date": "2025-12-23T12:00:00Z",
            *   "section_id": "R-001",
            *   "resource_id": "RES-10",
            *   "resource_name": "Excavator A"
            * }
            */
            EventDataJsonTxt := StrSubstNo(RefreshLbl,
                                EventId,
                                DayTask.Description,
                                ToSessionDateTimeTxt(DayTask."Start Planning Date", DayTask."Start Time"),
                                ToSessionDateTimeTxt(DayTask."Start Planning Date", DayTask."End Time"),
                                DayTask."Job No." + '|' + DayTask."Job Task No." + '|' + Format(DayTask."Job Planning Line No."),
                                DayTask."No.",
                                DayTask.Description);
        end;
        exit(rtv);
    end;

    procedure onEventAdded(EventData: Text; var UpdateEventIdJsonTxt: Text): Boolean
    var
        Task: record "Job Task";
        PlanningLine: record "Job Planning Line";
        DayTask: record "Day Tasks";
        Res: record Resource;
        EventJSonObj: JsonObject;
        JToken: JsonToken;
        SectionIdParts: List of [Text];
        JobNo: Code[20];
        TaskNo: Code[20];
        PlannigLineNo: Integer;
        DayNo: Integer;
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
        _DateTime: DateTime;
        _DateTimeUserZone: DateTime;
        JsonLbl: Label '{"OldEventId": "%1", "NewEventId": "%2|%3|%4|%5|%6"}';
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
        evaluate(PlannigLineNo, SectionIdParts.Get(3));
        PlanningLine.Get(JobNo, TaskNo, PlannigLineNo);

        EventJSonObj.Get('id', JToken);
        old_eventid := JToken.AsValue().AsText();

        EventJSonObj.Get('start_date', JToken);
        Evaluate(_DateTime, JToken.AsValue().AsText());
        _DateTimeUserZone := ConvertToUserTimeZone(_DateTime);
        PlanningDate := DT2Date(_DateTimeUserZone);
        StartTime := DT2Time(_DateTimeUserZone);
        Evaluate(DayNo, Format(PlanningDate, 0, '<Year4><Month,2><Day,2>'));

        EventJSonObj.Get('end_date', JToken);
        Evaluate(_DateTime, JToken.AsValue().AsText());
        _DateTimeUserZone := ConvertToUserTimeZone(_DateTime);
        EndPlanningDate := DT2Date(_DateTimeUserZone);
        EndTime := DT2Time(_DateTimeUserZone);

        // EventJSonObj.Get('text', JToken);
        // Desc := JToken.AsValue().AsText();

        EventJSonObj.Get('resource_id', JToken);
        Res.Get(JToken.AsValue().AsText().ToUpper());

        LineNo := 10000;
        DayTask.SetRange("Job No.", JobNo);
        DayTask.SetRange("Job Task No.", TaskNo);
        DayTask.SetRange("Job Planning Line No.", PlannigLineNo);
        DayTask.SetRange("Day No.", DayNo);
        if DayTask.FindLast() then
            LineNo := DayTask.DayLineNo + 10000;

        DayTask.Init();
        DayTask."Day No." := DayNo;
        DayTask."DayLineNo" := LineNo;
        DayTask."Job No." := JobNo;
        DayTask."Job Task No." := TaskNo;
        DayTask."Job Planning Line No." := PlannigLineNo;

        DayTask.Type := PlanningLine.Type::Resource;
        DayTask."No." := Res."No.";
        DayTask."Start Planning Date" := PlanningDate;
        DayTask."Start Time" := StartTime;
        DayTask."End Time" := EndTime;
        DayTask.Description := Res.Name;
        UpdateEventIdJsonTxt := StrSubstNo(JsonLbl,
                                            old_eventid,
                                            DayTask."Job No.",
                                            DayTask."Job Task No.",
                                            Format(DayTask."Job Planning Line No."),
                                            format(DayTask."Day No."),
                                            format(DayTask."DayLineNo"));
        rtv := DayTask.Insert();
        exit(rtv);
    end;

    procedure OnEventChanged(EventId: Text;
                             EventData: Text;
                             var UpdateEventID: Boolean;
                             var OldDayTask_forUpdate: record "Day Tasks";
                             var NewDayTask_forUpdate: record "Day Tasks")
    var
        OldTask: record "Job Task";
        NewTask: record "Job Task";
        OldPlanningLIne: record "Job Planning Line";
        NewPlanningLIne: record "Job Planning Line";
        OldDayTask: record "Day Tasks";
        DayTaskCheck: record "Day Tasks";

        EventJSonObj: JsonObject;
        JToken: JsonToken;
        EventIdParts: List of [Text];
        NewSectionParts: List of [Text];
        Old_JobNo: Text;
        Old_TaskNo: Text;
        Old_PlanningLineNo: Integer;
        Old_DayNo: Integer;
        Old_DayLineNo: Integer;
        New_JobNo: Text;
        New_TaskNo: Text;
        New_PlanningLineNo: Integer;
        New_DayNo: Integer;
        New_DayLineNo: Integer;
        _Date: Date;
        _Time: Time;
        _DateTime: DateTime;
        _DateTimeUserZone: DateTime;
    begin
        //Message('Event ' + eventId + ' changed: ' + eventData);
        /*        
        sift left / right:
            eventId = JOB00010|1020|10000|20251201|10000
            eventData = 
                {
                    "id":"JOB00010|1020|10000|20251201|10000",
                    "text":"Vacant Resource",
                    "start_date":"2025-11-05T05:00:00.000Z",
                    "end_date":"2025-11-06T04:00:00.000Z",
                    "section_id":"JOB00010|1020|10000"
                }
        sift up / down
            eventId = JOB00010|1020|10000|20251201|10000
            eventData = 
                {
                    "id":"JOB00010|1020|10000|20251201|10000",
                    "text":"Vacant Resource",
                    "start_date":"2025-11-05T05:00:00.000Z",
                    "end_date":"2025-11-06T04:00:00.000Z",
                    "section_id":"JOB00010|1030|10000"
                }
        */
        // get old record
        EventIdParts := eventId.Split('|');
        Old_JobNo := EventIdParts.Get(1);
        Old_TaskNo := EventIdParts.Get(2);
        Evaluate(Old_PlanningLineNo, EventIdParts.Get(3));
        Evaluate(Old_DayNo, EventIdParts.Get(4));
        Evaluate(Old_DayLineNo, EventIdParts.Get(5));
        OldTask.Get(Old_JobNo, Old_TaskNo);
        OldPlanningLIne.Get(Old_JobNo, Old_TaskNo, Old_PlanningLineNo);
        OldDayTask.Get(Old_DayNo, Old_DayLineNo, Old_JobNo, Old_TaskNo, Old_PlanningLineNo);

        EventJSonObj.ReadFrom(EventData);

        EventJSonObj.Get('section_id', JToken);
        NewSectionParts := JToken.AsValue().AsText().Split('|');
        New_JobNo := NewSectionParts.Get(1);
        New_TaskNo := NewSectionParts.Get(2);
        Evaluate(New_PlanningLineNo, NewSectionParts.Get(3));
        NewTask.Get(New_JobNo, New_TaskNo);
        NewPlanningLIne.Get(New_JobNo, New_TaskNo, New_PlanningLineNo);

        //Get Startdate as new dayno
        EventJSonObj.Get('start_date', JToken);
        //Covert _Date + _Time into Datetime var, after that extract Date part again to get the correct date in user's timezone
        Evaluate(_DateTime, JToken.AsValue().AsText());
        _DateTimeUserZone := ConvertToUserTimeZone(_DateTime);
        _Date := DT2Date(_DateTimeUserZone);
        Evaluate(New_DayNo, Format(_Date, 0, '<Year4><Month,2><Day,2>'));

        UpdateEventID := false;
        OldDayTask_forUpdate := OldDayTask;
        if OldPlanningLIne.RecordId <> NewPlanningLIne.RecordId then begin
            //sift up / down within different task
            if not DayTaskCheck.Get(New_DayNo, Old_DayLineNo, New_JobNo, New_TaskNo, New_PlanningLineNo) then
                OldDayTask.Rename(New_DayNo, Old_DayLineNo, New_JobNo, New_TaskNo, New_PlanningLineNo)
            else begin
                DayTaskCheck.SetCurrentKey("Job No.", "Job Task No.", "Job Planning Line No.", "Day No.", "DayLineNo");
                DayTaskCheck.SetRange("Job No.", New_JobNo);
                DayTaskCheck.SetRange("Job Task No.", New_TaskNo);
                DayTaskCheck.SetRange("Job Planning Line No.", New_PlanningLineNo);
                DayTaskCheck.SetRange("Day No.", New_DayNo);
                if DayTaskCheck.FindLast() then
                    OldDayTask.Rename(New_DayNo, DayTaskCheck."DayLineNo" + 10000, New_JobNo, New_TaskNo, New_PlanningLineNo)
                else
                    OldDayTask.Rename(New_DayNo, 10000, New_JobNo, New_TaskNo, New_PlanningLineNo);
            end;
            NewDayTask_forUpdate := OldDayTask;
            UpdateEventID := true;
        end;

        //sift left / right to same task
        EventJSonObj.Get('start_date', JToken);
        Evaluate(_DateTime, JToken.AsValue().AsText());
        _DateTimeUserZone := ConvertToUserTimeZone(_DateTime);
        OldDayTask."Start Planning Date" := DT2Date(_DateTimeUserZone);
        OldDayTask."Start Time" := DT2Time(_DateTimeUserZone);

        EventJSonObj.Get('end_date', JToken);
        Evaluate(_DateTime, JToken.AsValue().AsText());
        _DateTimeUserZone := ConvertToUserTimeZone(_DateTime);
        OldDayTask."End Time" := DT2Time(_DateTimeUserZone);

        EventJSonObj.Get('text', JToken);
        OldDayTask.Description := JToken.AsValue().AsText();

        OldDayTask.Modify();

        if UpdateEventID then
            UpdateEventID(OldDayTask_forUpdate, NewDayTask_forUpdate);
    end;

    procedure UpdateEventID(OldDayTask: Record "Day Tasks"; NewDayTask: Record "Day Tasks"): Text
    var
        rtv: text;
        JsonLbl: Label '{"OldEventId": "%1|%2|%3|%4|%5", "NewEventId": "%6|%7|%8|%9|%10"}';
    begin
        rtv := StrSubstNo(JsonLbl,
                         OldDayTask."Job No.",
                         OldDayTask."Job Task No.",
                         Format(OldDayTask."Job Planning Line No."),
                         Format(OldDayTask."Day No."),
                         Format(OldDayTask."DayLineNo"),
                         NewDayTask."Job No.",
                         NewDayTask."Job Task No.",
                         Format(NewDayTask."Job Planning Line No."),
                         Format(NewDayTask."Day No."),
                         Format(NewDayTask."DayLineNo"));
        exit(rtv);
    end;

    procedure ConvertToUserTimeZone(UtcDateTime: DateTime): DateTime
    var
        TypeHelper: Codeunit "Type Helper";
        TimeZoneOffset: Duration;
        localDateTime: DateTime;
    begin
        // Get the current user's time zone offset as a Duration (in milliseconds)
        if not TypeHelper.GetUserTimezoneOffset(TimeZoneOffset) then begin
            // Handle the case where the offset couldn't be determined (e.g., set a default or raise an error)
            // For this example, we default to 0 (UTC)
            TimeZoneOffset := 0;
        end;

        // Add the offset to the UTC DateTime to get the local DateTime
        localDateTime := utcDateTime + TimeZoneOffset;

        exit(localDateTime);
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
        JobPlanningLines.SetRange("Job No.", JobNo);
        JobPlanningLines.SetRange("Job Task No.", TaskNo);
        JobPlanningLines.SetRange("Line No.", PlanningLineNo);
        if JobPlanningLines.FindFirst() then begin
            Clear(JobPlanningLineCard);
            JobPlanningLineCard.SetTableView(JobPlanningLines);
            JobPlanningLineCard.SetRecord(JobPlanningLines);
            JobPlanningLineCard.RunModal();
            possibleChanges := true
        end else begin
            possibleChanges := false;
            Message('Job Planning Line not found for Event ID: %1', eventId);
        end;
    end;

    procedure GetDayTaskAsResourcesAndEventsJSon(TimeLineJSon: Text; var ResouecesJSon: Text; var EventsJSon: Text): Boolean
    var
        TimeLineJSonObj: JsonObject;
        JToken: JsonToken;
        _DateTime: DateTime;
        _DateTimeUserZone: DateTime;
        StartDate: Date;
        EndDate: Date;
        EarliestPlanningDate: date;
    begin
        //Message('Under development: Refreshing Timeline with TimeLineJSon: %1', TimeLineJSon);
        //exit(false);
        /*
        {"mode":"timeline","start":"2025-12-14T17:00:00.000Z","end":"2025-12-21T17:00:00.000Z"}
        */
        TimeLineJSonObj.ReadFrom(TimeLineJSon);

        TimeLineJSonObj.Get('start', JToken);
        Evaluate(_DateTime, JToken.AsValue().AsText());
        _DateTimeUserZone := ConvertToUserTimeZone(_DateTime);
        StartDate := DT2Date(_DateTimeUserZone);

        TimeLineJSonObj.Get('end', JToken);
        Evaluate(_DateTime, JToken.AsValue().AsText());
        _DateTimeUserZone := ConvertToUserTimeZone(_DateTime);
        EndDate := DT2Date(_DateTimeUserZone);

        ResouecesJSon := GetYUnitElementsJSON(StartDate,
                                            StartDate,
                                            EndDate,
                                            EventsJSon,
                                            EarliestPlanningDate);
        exit((EventsJSon <> '') and (ResouecesJSon <> ''));
    end;

}