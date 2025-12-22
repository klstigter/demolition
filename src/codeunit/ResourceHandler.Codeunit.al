codeunit 50600 "Resource DayPilot Handler"
{
    trigger OnRun()
    begin
        GetResourceAndEventsPerTask();
    end;

    var
    //myInt: Integer;

    procedure GetResourceAndEventsFromBCResource(var ResourceTxt: Text; var EventTxt: Text; StartDate: Text)
    var
        Res: Record Resource;
        JobPlaningLine: record "Job Planning Line";
        JobPlanningLineHandler: codeunit "Job Planning Line Handler";

        JsonArray: JsonArray;
        JobObject: JsonObject;
        TasksArray: JsonArray;
        TaskObject: JsonObject;

        EventObj: JsonObject;
        EventArray: JsonArray;

        DT: Date;
        DT1: Date;
        DT2: Date;
        _Date: Date;
        _Time: Time;
        Parts: List of [Text];
    begin
        Res.Reset();
        Res.SetRange(Blocked, false);
        Res.Reset();
        if Res.FindSet() then begin
            repeat
                Clear(JobObject);
                JobObject.Add('name', Res."No." + ' - ' + Res.Name);
                JobObject.Add('id', Res."No.");
                JsonArray.Add(JobObject);
            until Res.Next() = 0;

            /**/
            //Create Events from Job Planning Lines with type resource in scope of 2 weeks from startdate param
            Parts := StartDate.Split('T');
            Evaluate(_Date, Parts.Get(1));
            //Evaluate(_Time, Parts.Get(2));
            //DT := CreateDateTime(_Date, _Time);
            JobPlaningLine.Reset();
            JobPlaningLine.SetRange(Type, JobPlaningLine.Type::Resource);
            DT := CalcDate('<-1W>', _Date);
            JobPlaningLine.SetFilter("Start Planning Date", '>=%1', DT);
            DT := CalcDate('<2W>', _Date);
            JobPlaningLine.SetFilter("End Planning Date", '<=%1', DT);
            if JobPlaningLine.findset then
                repeat
                    Clear(EventObj);
                    EventObj.Add('id', JobPlaningLine."Job No." + '|' + JobPlaningLine."Job Task No." + '|' + format(JobPlaningLine."Line No."));
                    EventObj.Add('text', JobPlaningLine.Description);
                    EventObj.Add('start', JobPlanningLineHandler.GetTaskDateTime(JobPlaningLine."Start Planning Date", JobPlaningLine."Start Time", false));
                    DT := JobPlaningLine."Start Planning Date";
                    if JobPlaningLine."End Planning Date" <> 0D then
                        DT := JobPlaningLine."End Planning Date";
                    EventObj.Add('end', JobPlanningLineHandler.GetTaskDateTime(DT, JobPlaningLine."End Time", true));
                    EventObj.Add('resource', JobPlaningLine."No.");
                    EventObj.Add('bubbleHtml', JobPlanningLineHandler.CreateBubbleHtmlFromPlanningLine(JobPlaningLine));

                    EventObj.Add('deleteDisabled', true);
                    EventObj.Add('resizeDisabled', true);
                    EventObj.Add('moveDisabled', true);

                    EventArray.Add(EventObj);

                until JobPlaningLine.Next() = 0;
            /**/
        end;

        JsonArray.WriteTo(ResourceTxt);
        EventArray.WriteTo(EventTxt);
    end;

    procedure GetResourceAndEventsPerTask()
    var
        Res: Record Resource;
        Job: record Job;
        Task: record "Job Task";
        Task2: record "Job Task";
        JobPlaningLine: record "Job Planning Line";
        ResCap: Record "Res. Capacity Entry";
        TempDateVar: Record Date temporary;

        JobPlanningLineHandler: codeunit "Job Planning Line Handler";

        ResourceBoard: Page "Resources Board";

        ResObject: JsonObject;
        ResJsonArray: JsonArray;

        JobObject: JsonObject;
        JobJsonArray: JsonArray;

        TaskObject: JsonObject;
        TasksJsonArray: JsonArray;

        EventObj: JsonObject;
        EventArray: JsonArray;

        ResourceTxt: Text;
        EventTxt: Text;
        Days: Integer;
        StartDate: Text;
        DT: date;
        _T: Time;
    begin
        /*
        Rows structure:
            Resource
                Project
                    Task
        */
        Clear(EventArray);
        Res.Reset();
        Res.SetRange(Blocked, false);
        Res.Reset();
        if Res.FindSet() then
            repeat
                // Rows - Resource Level
                Clear(ResObject);
                ResObject.Add('id', '1|' + Res."No."); //Level Resource
                ResObject.Add('name', Res."No." + ' - ' + Res.Name);
                ResObject.Add('expanded', true);

                // Rows - Project Level                
                if GetProjectByResource(Res."No.", Job) then begin
                    Clear(JobJsonArray);
                    repeat
                        Clear(JobObject);
                        JobObject.Add('id', '2|' + Res."No." + '|' + Job."No."); //Level Project
                        JobObject.Add('name', Job."No." + ' - ' + Job.Description);
                        JobObject.Add('expanded', true);

                        // Rows - Task Level
                        if GetTaskByResourceAndProject(Res."No.", Job."No.", Task) then begin
                            Clear(TasksJsonArray);
                            repeat
                                Clear(TaskObject);
                                TaskObject.Add('id', '3|' + Res."No." + '|' + Job."No." + '|' + Task."Job Task No."); //Level Task
                                TaskObject.Add('name', Task."Job Task No." + ' - ' + Task.Description);
                                TasksJsonArray.Add(TaskObject);

                                //Task Marked for event creation
                                Task2 := Task;
                                Task2.Find();
                                Task2.Mark(true);
                            until Task.Next() = 0;
                        end;
                        JobObject.Add('children', TasksJsonArray);
                        JobJsonArray.Add(JobObject);
                    until Job.Next() = 0;

                    ResObject.Add('children', JobJsonArray);
                end;

                ResJsonArray.Add(ResObject);
            until Res.Next() = 0;

        //<< Create event from Job Planning Line
        TempDateVar.Reset();
        TempDateVar.DeleteAll();
        Task2.MarkedOnly := true;
        if Task2.FindSet() then
            repeat
                JobPlaningLine.SetRange("Job No.", Task2."Job No.");
                JobPlaningLine.SetRange("Job Task No.", Task2."Job Task No.");
                JobPlaningLine.SetRange(Type, JobPlaningLine.Type::Resource);
                JobPlaningLine.SetFilter("Start Planning Date", '<>%1', 0D);
                JobPlaningLine.SetFilter("No.", '<>%1', '');
                if JobPlaningLine.FindSet() then
                    repeat
                        //Manage days
                        if JobPlaningLine."Start Planning Date" <> 0D then
                            if not TempDateVar.Get(TempDateVar."Period Type"::Date, JobPlaningLine."Start Planning Date") then begin
                                TempDateVar.Init();
                                TempDateVar."Period Type" := TempDateVar."Period Type"::Date;
                                TempDateVar."Period Start" := JobPlaningLine."Start Planning Date";
                                TempDateVar.Insert();
                            end;
                        if JobPlaningLine."End Planning Date" <> 0D then
                            if not TempDateVar.Get(TempDateVar."Period Type"::Date, JobPlaningLine."End Planning Date") then begin
                                TempDateVar.Init();
                                TempDateVar."Period Type" := TempDateVar."Period Type"::Date;
                                TempDateVar."Period Start" := JobPlaningLine."End Planning Date";
                                TempDateVar.Insert();
                            end;

                        Clear(EventObj);
                        EventObj.Add('id', JobPlaningLine."Job No." + '|' + JobPlaningLine."Job Task No." + '|' + format(JobPlaningLine."Line No."));
                        EventObj.Add('text', JobPlaningLine.Description);
                        EventObj.Add('start', JobPlanningLineHandler.GetTaskDateTime(JobPlaningLine."Start Planning Date", JobPlaningLine."Start Time", false));
                        DT := JobPlaningLine."Start Planning Date";
                        if JobPlaningLine."End Planning Date" <> 0D then
                            DT := JobPlaningLine."End Planning Date";
                        EventObj.Add('end', JobPlanningLineHandler.GetTaskDateTime(DT, JobPlaningLine."End Time", true));
                        EventObj.Add('resource', '3|' + JobPlaningLine."No." + '|' + JobPlaningLine."Job No." + '|' + JobPlaningLine."Job Task No.");
                        EventObj.Add('bubbleHtml', JobPlanningLineHandler.CreateBubbleHtmlFromPlanningLine(JobPlaningLine));

                        EventObj.Add('deleteDisabled', true);
                        EventObj.Add('resizeDisabled', true);
                        EventObj.Add('moveDisabled', true);

                        EventArray.Add(EventObj);
                    until JobPlaningLine.Next() = 0;
            until Task2.Next() = 0;
        //>>

        TempDateVar.Reset();
        Days := TempDateVar.Count + 7;
        TempDateVar.FindFirst();
        StartDate := Format(TempDateVar."Period Start", 0, '<Year4>-<Month,2>-<Day,2>');

        // Create event from Resource Capacity based on above date range
        if Res.FindSet() then
            repeat
                ResCap.SetRange("Resource No.", Res."No.");
                ResCap.SetFilter(Date, '<>%1&%2..%3', 0D, TempDateVar."Period Start", CalcDate('<' + format(Days) + 'D>', TempDateVar."Period Start"));
                ResCap.SetFilter(Capacity, '<>%1', 0);
                if ResCap.FindSet() then
                    repeat
                        Clear(EventObj);
                        EventObj.Add('id', Res."No." + '|' + format(ResCap."Entry No."));
                        EventObj.Add('text', StrSubstNo('Cap: %1 hours', ResCap.Capacity));
                        Evaluate(_T, '08:00');
                        EventObj.Add('start', JobPlanningLineHandler.GetTaskDateTime(ResCap.Date, _T, false));
                        Evaluate(_T, '17:00');
                        EventObj.Add('end', JobPlanningLineHandler.GetTaskDateTime(ResCap.Date, _T, true));
                        EventObj.Add('resource', '1|' + Res."No.");
                        EventObj.Add('bubbleHtml', 'Resource Capacity');

                        EventObj.Add('deleteDisabled', true);
                        EventObj.Add('resizeDisabled', true);
                        EventObj.Add('moveDisabled', true);
                        EventObj.Add('barColor', 'red');

                        EventArray.Add(EventObj);
                    until ResCap.Next() = 0;
            until Res.Next() = 0;

        ResJsonArray.WriteTo(ResourceTxt);
        EventArray.WriteTo(EventTxt);

        Clear(ResourceBoard);
        ResourceBoard.SetResoucesAndEventJsonTxt(ResourceTxt, EventTxt, StartDate, Days);
        ResourceBoard.RunModal();
    end;

    local procedure GetProjectByResource(ResourceNo: Code[20]; var Job: record Job): Boolean
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        Job.Reset();
        JobPlanningLine.SetRange(Type, JobPlanningLine.Type::Resource);
        JobPlanningLine.SetRange("No.", ResourceNo);
        if JobPlanningLine.FindSet() then
            repeat
                Job.Get(JobPlanningLine."Job No.");
                Job.Mark(true);
            until JobPlanningLine.Next() = 0;
        Job.MarkedOnly := true;
        exit(Job.FindSet());
    end;

    local procedure GetTaskByResourceAndProject(ResourceNo: Code[20]; JobNo: Code[20]; var Task: record "Job Task"): Boolean
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        Task.Reset();
        JobPlanningLine.SetRange(Type, JobPlanningLine.Type::Resource);
        JobPlanningLine.SetRange("Job No.", JobNo);
        JobPlanningLine.SetRange("No.", ResourceNo);
        if JobPlanningLine.FindSet() then
            repeat
                Task.Get(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.");
                Task.Mark(true);
            until JobPlanningLine.Next() = 0;
        Task.MarkedOnly := true;
        exit(Task.FindSet());
    end;

}