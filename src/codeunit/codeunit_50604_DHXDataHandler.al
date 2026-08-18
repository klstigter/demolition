codeunit 50604 "DHX Data Handler"
{
    trigger OnRun()
    begin

    end;

    var

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

    procedure GetYUnitElementsJSON_Project(AnchorDate: Date;
                                   StartDate: Date;
                                   EndDate: Date;
                                   ResourceFilter: Text;
                                   var PlanninJsonTxt: Text;
                                   var EarliestPlanningDate: Date): Text
    var
        dummyTxt: text;
    begin
        exit(GetYUnitElementsJSON_Project(AnchorDate, StartDate, EndDate, ResourceFilter, dummyTxt, dummyTxt, PlanninJsonTxt, EarliestPlanningDate));
    end;

    procedure GetYUnitElementsJSON_Project(AnchorDate: Date;
                               StartDate: Date;
                               EndDate: Date;
                               JobFilter: Text;
                               JobTaskFilter: Text;
                               var PlanninJsonTxt: Text;
                               var EarliestPlanningDate: Date): Text
    var
        dummyTxt: text;

    begin
        exit(GetYUnitElementsJSON_Project(AnchorDate, StartDate, EndDate, dummyTxt, JobFilter, JobTaskFilter, PlanninJsonTxt, EarliestPlanningDate));
    end;

    procedure GetYUnitElementsJSON_Project(AnchorDate: Date;
                                   StartDate: Date;
                                   EndDate: Date;
                                   ResourceFilter: Text;
                                   JobFilter: Text;
                                   JobTaskFilter: Text;
                                   var PlanninJsonTxt: Text;
                                   var EarliestPlanningDate: Date): Text
    var
        JobTasks: Record "Job Task";
        TEMPJobTasks: Record "Job Task" temporary;
        //PlanningLine: Record "Job Task";
        DayPlanning: Record "Day Planning";
        WeekTemp: record "Aging Band Buffer" temporary;
        Resource: record Resource;
        Ven: Record Vendor;
        Job: Record Job;

        ResNo: Code[20];
        ResName: Text;
        ReqResName: Text;
        CurrentJobNo: Code[20];

        JobObject, TaskObject, PlanningLineObject : JsonObject;
        ChildrenArray, ChildrenArray2 : JsonArray;
        StackArr: array[50] of JsonArray;
        StackObj: array[50] of JsonObject;
        StackIndent: array[50] of Integer;
        StackDepth: Integer;
        TaskLeaf: JsonObject;
        HeadingNode: JsonObject;
        FreshArr: JsonArray;   // Used to reliably reset StackArr elements (Clear on array elements is unreliable)
        PlanningObject, Root : JsonObject;
        PlanningArray, DataArray : JsonArray;
        OutText: Text;

        StartDateTxt: Text;
        EndDateTxt: Text;
        _DummyEndDate: Date;
        DetailsLabel: Label '%1 - %2|%3 - %4|%5 - %6';

        HasAssigned: Boolean;
        HasRequested: Boolean;
        AssignedStartTime: Time;
        AssignedEndTime: Time;
        RequestedStartTime: Time;
        RequestedEndTime: Time;
        EnvelopeStartTime: Time;
        EnvelopeEndTime: Time;
    begin
        PlanninJsonTxt := '';
        //Marking Job based on Day Plannings within the given date range
        DayPlanning.SetCurrentKey("Plan Date", "Start Time Assigned");
        DayPlanning.SetRange("Plan Date", StartDate, EndDate);
        if JobFilter <> '' then
            DayPlanning.SetFilter("Job No.", JobFilter)
        else
            DayPlanning.SetFilter("Job No.", '<>%1', ''); //Exclude blank Job Nos
        if jobTaskFilter <> '' then
            DayPlanning.SetFilter("Job Task No.", jobTaskFilter)
        else
            DayPlanning.SetFilter("Job Task No.", '<>%1', ''); //Exclude blank task Nos
        if ResourceFilter <> '' then
            DayPlanning.Setfilter("Assigned Resource No.", ResourceFilter);
        //DayPlanning.SetRange(Type, DayPlanning.Type::Resource);
        if DayPlanning.FindSet() then begin
            repeat
                JobTasks.Get(DayPlanning."Job No.", DayPlanning."Job Task No.");
                TEMPJobTasks := JobTasks;
                if not tempjobtasks.get(jobTasks."Job No.", jobTasks."Job Task No.") then begin
                    TEMPJobTasks.insert();
                end;

                // resource data
                clear(Resource);
                ResNo := '';
                ResName := '';
                if Resource.Get(DayPlanning."Assigned Resource No.") then begin
                    ResNo := Resource."No.";
                    ResName := Resource.Name;
                end;

                // requested resource data
                Clear(Resource);
                ReqResName := '';
                if DayPlanning."Requested Resource No." <> '' then
                    if Resource.Get(DayPlanning."Requested Resource No.") then
                        ReqResName := Resource.Name;
                // create event data
                if AnchorDate = 0D then
                    CountToWeekNumber(DayPlanning."Plan Date", WeekTemp);

                // Envelope = earliest start / latest end across the Assigned and Requested
                // time sub-ranges for this Plan Date, so the bar spans both strips drawn by
                // wrapper.js. Missing bounds on a side that has data fall back to the
                // start/end of day, same convention as GetStartEndTxt(DayPlanning...) below.
                HasAssigned := (DayPlanning."Start Time Assigned" <> 0T) or (DayPlanning."End Time Assigned" <> 0T);
                HasRequested := (DayPlanning."Start Time Requested" <> 0T) or (DayPlanning."End Time Requested" <> 0T);

                if HasAssigned then begin
                    if DayPlanning."Start Time Assigned" <> 0T then
                        AssignedStartTime := DayPlanning."Start Time Assigned"
                    else
                        AssignedStartTime := 000000T;
                    if DayPlanning."End Time Assigned" <> 0T then
                        AssignedEndTime := DayPlanning."End Time Assigned"
                    else
                        AssignedEndTime := 235959T;
                end;

                if HasRequested then begin
                    if DayPlanning."Start Time Requested" <> 0T then
                        RequestedStartTime := DayPlanning."Start Time Requested"
                    else
                        RequestedStartTime := 000000T;
                    if DayPlanning."End Time Requested" <> 0T then
                        RequestedEndTime := DayPlanning."End Time Requested"
                    else
                        RequestedEndTime := 235959T;
                end;

                if HasAssigned and HasRequested then begin
                    if AssignedStartTime < RequestedStartTime then
                        EnvelopeStartTime := AssignedStartTime
                    else
                        EnvelopeStartTime := RequestedStartTime;
                    if AssignedEndTime > RequestedEndTime then
                        EnvelopeEndTime := AssignedEndTime
                    else
                        EnvelopeEndTime := RequestedEndTime;
                end else if HasAssigned then begin
                    EnvelopeStartTime := AssignedStartTime;
                    EnvelopeEndTime := AssignedEndTime;
                end else if HasRequested then begin
                    EnvelopeStartTime := RequestedStartTime;
                    EnvelopeEndTime := RequestedEndTime;
                end else begin
                    // Neither side has data: fall back to the whole day so a Day Planning
                    // with no times at all still renders as an all-day bar.
                    EnvelopeStartTime := 000000T;
                    EnvelopeEndTime := 235959T;
                end;

                StartDateTxt := ToSessionDateTimeTxt(DayPlanning."Plan Date", EnvelopeStartTime);
                EndDateTxt := ToSessionDateTimeTxt(DayPlanning."Plan Date", EnvelopeEndTime);
                Clear(PlanningObject);
                PlanningObject.Add('id', DayPlanning."Job No." + '|' +
                                         DayPlanning."Job Task No." + '|' +
                                         Format(DayPlanning."Plan Date") + '|' +
                                         Format(DayPlanning."Day Line No.") + '|' +
                                         ResNo + '|' +
                                         ResName);
                PlanningObject.Add('start_date', StartDateTxt);
                PlanningObject.Add('end_date', EndDateTxt);
                //if DayPlanning.Description <> '' then
                //    PlanningObject.Add('text', DayPlanning.Description)
                //else
                if DayPlanning."Assigned Resource No." <> '' then begin
                    if ResName <> '' then
                        PlanningObject.Add('text', ResName)
                    else
                        PlanningObject.Add('text', DayPlanning.Description);
                end else
                    PlanningObject.Add('text', DayPlanning."Job No." + '|' + DayPlanning."Job Task No." + ' (vacant)');

                PlanningObject.Add('section_id', DayPlanning."Job No." + '|' + DayPlanning."Job Task No.");
                // if ResNo <> '' then begin
                //     if DayPlanning."Vendor No." <> '' then
                //         PlanningObject.Add('color', 'grey')
                //     else
                //         PlanningObject.Add('color', 'green');
                // end else begin // no resource assigned
                //     if DayPlanning."Vendor No." <> '' then
                //         PlanningObject.Add('color', 'grey')
                //     else
                //         PlanningObject.Add('color', 'green');
                // end;
                if not Ven.Get(DayPlanning."Vendor No.") then
                    Clear(Ven);
                PlanningObject.Add('details', Ven.Name);
                // StrSubstNo(DetailsLabel, Ven."No.", Ven.Name
                // , DayPlanning."Job No.", Jobs.Description
                // , DayPlanning."Job Task No.", JobTasks.Description));

                PlanningObject.Add('non_working_minutes_assigned', DayPlanning."Non Working Minutes Assigned");
                PlanningObject.Add('assigned_hours', DayPlanning."Assigned Hours");
                PlanningObject.Add('requested_resource_no', DayPlanning."Requested Resource No.");
                PlanningObject.Add('requested_resource_name', ReqResName);
                if DayPlanning."Start Time Assigned" <> 0T then
                    PlanningObject.Add('start_time_assigned', Format(DayPlanning."Start Time Assigned", 0, '<Hours24,2>:<Minutes,2>'))
                else
                    PlanningObject.Add('start_time_assigned', '');
                if DayPlanning."End Time Assigned" <> 0T then
                    PlanningObject.Add('end_time_assigned', Format(DayPlanning."End Time Assigned", 0, '<Hours24,2>:<Minutes,2>'))
                else
                    PlanningObject.Add('end_time_assigned', '');
                if DayPlanning."Start Time Requested" <> 0T then
                    PlanningObject.Add('start_time_requested', Format(DayPlanning."Start Time Requested", 0, '<Hours24,2>:<Minutes,2>'))
                else
                    PlanningObject.Add('start_time_requested', '');
                if DayPlanning."End Time Requested" <> 0T then
                    PlanningObject.Add('end_time_requested', Format(DayPlanning."End Time Requested", 0, '<Hours24,2>:<Minutes,2>'))
                else
                    PlanningObject.Add('end_time_requested', '');
                PlanningObject.Add('non_working_minutes_requested', DayPlanning."Non Working Minutes Requested");
                PlanningObject.Add('requested_hours', DayPlanning."Requested Hours");

                PlanningArray.Add(PlanningObject);
                PlanningArray.WriteTo(PlanninJsonTxt);
            until DayPlanning.Next() = 0;

            if AnchorDate = 0D then begin
                WeekTemp.Reset();
                WeekTemp.SetCurrentKey("Column 3 Amt.");
                WeekTemp.FindSet();
                if WeekTemp.FindLast() then
                    EarliestPlanningDate := DWY2Date(1, WeekTemp."Column 2 Amt.", WeekTemp."Column 1 Amt.")
                else
                    EarliestPlanningDate := Today();
            end else
                GetWeekPeriodDates(AnchorDate, EarliestPlanningDate, _DummyEndDate);
        end else
            EarliestPlanningDate := Today();

        // Rebuild ancestor hierarchy: for every posting task in TEMPJobTasks that has
        // indentation > 0, walk up the real Job Task table and insert every missing
        // Begin-Total / Heading ancestor so the Y-axis tree mirrors Page 1 structure.
        AddAncestorsToTemp(TEMPJobTasks);

        if TEMPJobTasks.FindSet() then begin
            Clear(DataArray);
            CurrentJobNo := '';
            StackDepth := 0;
            repeat
                // One JobObject per unique Job No. — start a new one when the job changes
                if TEMPJobTasks."Job No." <> CurrentJobNo then begin
                    if CurrentJobNo <> '' then begin
                        // Flush remaining stack for the previous job
                        while StackDepth > 0 do begin
                            StackObj[StackDepth].Add('children', StackArr[StackDepth + 1]);
                            StackArr[StackDepth].Add(StackObj[StackDepth]);
                            StackDepth -= 1;
                        end;
                        JobObject.Add('children', StackArr[1]);
                        DataArray.Add(JobObject);
                    end;
                    CurrentJobNo := TEMPJobTasks."Job No.";
                    Clear(JobObject);
                    Clear(FreshArr);
                    StackArr[1] := FreshArr;
                    StackDepth := 0;
                    JobObject.Add('key', CurrentJobNo);
                    if Job.Get(CurrentJobNo) then
                        JobObject.Add('label', StrSubstNo('%1 - %2', CurrentJobNo, Job.Description))
                    else
                        JobObject.Add('label', CurrentJobNo);
                    JobObject.Add('open', true);
                end;

                // Pop stack entries whose indentation >= current task's indentation
                // Note: BC AL does not short-circuit 'and', so StackIndent[StackDepth]
                // would be evaluated even when StackDepth=0 (index 0 = out of bounds).
                // Use a nested if+break instead.
                while StackDepth > 0 do begin
                    if StackIndent[StackDepth] < TEMPJobTasks.Indentation then
                        break;
                    StackObj[StackDepth].Add('children', StackArr[StackDepth + 1]);
                    StackArr[StackDepth].Add(StackObj[StackDepth]);
                    StackDepth -= 1;
                end;

                if TEMPJobTasks."Job Task Type" = TEMPJobTasks."Job Task Type"::Posting then begin
                    // Leaf: add directly to the active level's children array
                    Clear(TaskLeaf);
                    TaskLeaf.Add('key', TEMPJobTasks."Job No." + '|' + TEMPJobTasks."Job Task No.");
                    TaskLeaf.Add('label', StrSubstNo('%1 - %2', TEMPJobTasks."Job Task No.", TEMPJobTasks.Description));
                    StackArr[StackDepth + 1].Add(TaskLeaf);
                end else if (TEMPJobTasks."Job Task Type" = TEMPJobTasks."Job Task Type"::"End-Total") or
                            (TEMPJobTasks."Job Task Type" = TEMPJobTasks."Job Task Type"::Total) then begin
                    // End-Total and Total are accounting markers — not visual nodes, skip them
                end else begin
                    // Heading / Begin-Total: push a new nesting level onto the stack
                    // Use a local variable (HeadingNode) instead of clearing the array element directly,
                    // because Clear() on JsonObject array elements is unreliable in BC AL.
                    if StackDepth < 49 then begin
                        StackDepth += 1;
                        Clear(HeadingNode);
                        HeadingNode.Add('key', TEMPJobTasks."Job No." + '|' + TEMPJobTasks."Job Task No.");
                        HeadingNode.Add('label', StrSubstNo('%1 - %2', TEMPJobTasks."Job Task No.", TEMPJobTasks.Description));
                        HeadingNode.Add('open', true);
                        StackObj[StackDepth] := HeadingNode;
                        Clear(FreshArr);
                        StackArr[StackDepth + 1] := FreshArr;
                        StackIndent[StackDepth] := TEMPJobTasks.Indentation;
                    end;
                end;
            until TEMPJobTasks.Next() = 0;
            // Flush the last job
            if CurrentJobNo <> '' then begin
                while StackDepth > 0 do begin
                    StackObj[StackDepth].Add('children', StackArr[StackDepth + 1]);
                    StackArr[StackDepth].Add(StackObj[StackDepth]);
                    StackDepth -= 1;
                end;
                JobObject.Add('children', StackArr[1]);
                DataArray.Add(JobObject);
            end;
            Clear(Root);
            Root.Add('data', DataArray);

            // Write JSON to text
            Root.WriteTo(OutText);
            exit(OutText);
        end;
        exit('');
    end;

    // Iteratively adds all ancestor Begin-Total / Heading tasks for every task in
    // TEMPJobTasks that has Indentation > 0.  A snapshot is taken each pass so
    // we never modify the table while iterating it.  The loop repeats until a full
    // pass produces no new insertions, which handles arbitrary nesting depth.
    local procedure AddAncestorsToTemp(var TEMPJobTasks: Record "Job Task" temporary)
    var
        JobTaskReal: Record "Job Task";
        TempSnapshot: Record "Job Task" temporary;
        NewAncestorAdded: Boolean;
    begin
        repeat
            NewAncestorAdded := false;

            // Snapshot the current contents of TEMPJobTasks
            TempSnapshot.Reset();
            TempSnapshot.DeleteAll();
            TEMPJobTasks.Reset();
            if TEMPJobTasks.FindSet() then
                repeat
                    TempSnapshot := TEMPJobTasks;
                    TempSnapshot.Insert();
                until TEMPJobTasks.Next() = 0;

            // For each task with indentation > 0, find its direct parent heading
            if TempSnapshot.FindSet() then
                repeat
                    if TempSnapshot.Indentation > 0 then begin
                        // Direct parent = last Begin-Total or Heading before this task
                        // at exactly Indentation - 1.  Exclude Posting, End-Total, Total
                        // so that closing markers are never treated as parent nodes.
                        JobTaskReal.Reset();
                        JobTaskReal.SetRange("Job No.", TempSnapshot."Job No.");
                        JobTaskReal.SetFilter("Job Task Type", '<>%1&<>%2&<>%3',
                            JobTaskReal."Job Task Type"::Posting,
                            JobTaskReal."Job Task Type"::"End-Total",
                            JobTaskReal."Job Task Type"::Total);
                        JobTaskReal.SetFilter("Job Task No.", '<%1', TempSnapshot."Job Task No.");
                        JobTaskReal.SetRange("Indentation", TempSnapshot.Indentation - 1);
                        if JobTaskReal.FindLast() then
                            if not TEMPJobTasks.Get(JobTaskReal."Job No.", JobTaskReal."Job Task No.") then begin
                                TEMPJobTasks := JobTaskReal;
                                TEMPJobTasks.Insert();
                                NewAncestorAdded := true;
                            end;
                    end;
                until TempSnapshot.Next() = 0;
        until not NewAncestorAdded;
    end;

    /// <summary>
    /// Validates that every event's section_id in PlanninJsonTxt has a matching key in ResourceJSONTxt.
    /// ResourceJSONTxt  = {"data":[{key:"J001", children:[{key:"J001|T001"},...]},...]}
    /// PlanninJsonTxt   = [{section_id:"J001|T001", ...},...]
    /// Shows an error message listing all unmatched section IDs.
    /// </summary>
    procedure ValidateSchedulerSectionMatch(ResourceJSONTxt: Text; PlanninJsonTxt: Text)
    var
        RootObj: JsonObject;
        DataArr: JsonArray;
        JobToken, EventToken : JsonToken;
        EventObj: JsonObject;
        SectionToken: JsonToken;
        SectionKeys: Dictionary of [Text, Boolean];
        MissingIds: List of [Text];
        SectionId: Text;
        ErrorMsg: Text;
        MissingId: Text;
    begin
        // ── 1. Collect all section keys at any depth from ResourceJSONTxt ──────
        if ResourceJSONTxt = '' then
            exit;
        if not RootObj.ReadFrom(ResourceJSONTxt) then
            exit;
        if not RootObj.Get('data', JobToken) then
            exit;
        DataArr := JobToken.AsArray();
        CollectSectionKeys(DataArr, SectionKeys);

        // ── 2. Check every event's section_id against collected keys ──────────
        if PlanninJsonTxt = '' then
            exit;
        if not DataArr.ReadFrom(PlanninJsonTxt) then
            exit;
        foreach EventToken in DataArr do begin
            EventObj := EventToken.AsObject();
            if EventObj.Get('section_id', SectionToken) then begin
                SectionId := SectionToken.AsValue().AsText();
                if not SectionKeys.ContainsKey(SectionId) then
                    if not MissingIds.Contains(SectionId) then
                        MissingIds.Add(SectionId);
            end;
        end;

        // ── 3. Report mismatches ───────────────────────────────────────────────
        if MissingIds.Count = 0 then
            exit;

        ErrorMsg := StrSubstNo('DHTMLX Scheduler: %1 event(s) have unmatched section_id:\', MissingIds.Count);
        foreach MissingId in MissingIds do
            ErrorMsg += '  • ' + MissingId + '\';
        ErrorMsg += 'These events will not appear in the scheduler. Check that the job task exists and is of type Posting.';
        Message(ErrorMsg);
    end;

    local procedure CollectSectionKeys(Nodes: JsonArray; var Keys: Dictionary of [Text, Boolean])
    var
        NodeToken: JsonToken;
        NodeObj: JsonObject;
        KeyToken: JsonToken;
        ChildToken: JsonToken;
        ChildArr: JsonArray;
    begin
        foreach NodeToken in Nodes do begin
            NodeObj := NodeToken.AsObject();
            if NodeObj.Get('key', KeyToken) then
                if not Keys.ContainsKey(KeyToken.AsValue().AsText()) then
                    Keys.Add(KeyToken.AsValue().AsText(), true);
            if NodeObj.Get('children', ChildToken) then begin
                ChildArr := ChildToken.AsArray();
                CollectSectionKeys(ChildArr, Keys);
            end;
        end;
    end;

    local procedure GetVendorNoFromDayPlanning(FromDate: Date; ToDate: Date; ResNo: Code[20]): Text
    var
        DayPlanning: record "Day Planning";
        VendorNo: Text;
        rtv: Text;
    begin
        rtv := '';
        DayPlanning.SetRange("Plan Date", FromDate, ToDate);
        DayPlanning.SetRange("Assigned Resource No.", ResNo);
        DayPlanning.Setfilter("Vendor No.", '<>%1', '');
        if DayPlanning.FindFirst() then
            rtv := DayPlanning."Resource Group No." + '|' + DayPlanning."Assigned Resource No." + '|' + DayPlanning."Vendor No."
        else begin
            DayPlanning.Setfilter("Vendor No.", '');
            if DayPlanning.FindFirst() then
                rtv := DayPlanning."Resource Group No." + '|' + DayPlanning."Assigned Resource No." + '|' + DayPlanning."Vendor No.";
        end;
        exit(rtv);
    end;

    local procedure GetPoolNoFromDayPlanning(FromDate: Date; ToDate: Date; ResNo: Code[20]): Text
    var
        DayPlanning: record "Day Planning";
        PoolNo: Text;
        rtv: Text;
    begin
        rtv := '';
        DayPlanning.SetRange("Plan Date", FromDate, ToDate);
        DayPlanning.SetRange("Assigned Resource No.", ResNo);
        DayPlanning.Setfilter("Assigned Pool Resource No.", '<>%1', '');
        if DayPlanning.FindFirst() then
            rtv := DayPlanning."Resource Group No." + '|' + DayPlanning."Assigned Resource No." + '|' + DayPlanning."Assigned Pool Resource No."
        else begin
            DayPlanning.Setfilter("Assigned Pool Resource No.", '');
            if DayPlanning.FindFirst() then
                rtv := DayPlanning."Resource Group No." + '|' + DayPlanning."Assigned Resource No." + '|' + DayPlanning."Assigned Pool Resource No.";
        end;
        exit(rtv);
    end;

    procedure GetYUnitElementsJSON_Resource(AnchorDate: Date;
                                   StartDate: Date;
                                   EndDate: Date;
                                   WithDayPlanning: Boolean;
                                   var PlanninJsonTxt: Text;
                                   var EarliestPlanningDate: Date): Text
    var
        ResCap: Record "Res. Capacity Entry";
        Ven: Record Vendor;
        WeekTemp: record "Aging Band Buffer" temporary;
        TempResGroup: record "Resource Group" temporary;
        TempVendor: record "Aging Band Buffer" temporary;
        ResourceTemp: Record Resource temporary;
        TempVen: record Vendor temporary;
        DateRec: Record Date;
        DayPlanning: record "Day Planning";
        Resource: Record Resource;
        Job: Record Job;
        Task: Record "Job Task";

        ResCapQry: Query "Capacity Per Day Per Resource";

        GroupResObject, InternalExternalObject, ResourceObject : JsonObject;
        GroupChildrenArray, InternalExternalChildrenArray : JsonArray;
        PlanningObject, Root : JsonObject;
        PlanningArray, DataArray : JsonArray;
        OutText: Text;

        ResNo: Code[20];
        VenNo: Code[20];
        section_id: Text;
        New_section_id: Text;
        StartDateTxt: Text;
        EndDateTxt: Text;
        DummyEndDate: Date;
        DetailsLabel: Label '%1 - %2|%3 - %4|%5 - %6';
    begin
        PlanninJsonTxt := '';
        //Marking Job based on Day Plannings within the given date range
        WeekTemp.Reset();
        WeekTemp.DeleteAll();

        DateRec.SetRange("Period Type", DateRec."Period Type"::Date);
        DateRec.SetRange("Period Start", StartDate, EndDate);
        if DateRec.findset then
            Repeat
                //Add Event of Capacity                
                ResCapQry.SetRange(Date_filter, DateRec."Period Start"); // -> change with query to sum total capacity per day per resource
                if ResCapQry.Open() then begin
                    while ResCapQry.Read() do begin
                        ResCap.Get(ResCapQry.Entry_No);
                        GetStartEndTxt(ResCap, ResCapQry.Capacity, StartDateTxt, EndDateTxt);
                        Clear(PlanningObject);
                        section_id := ResCap."Resource Group No." + '|' + ResCap."Resource No.";
                        PlanningObject.Add('id', Format(ResCap."Entry No."));
                        PlanningObject.Add('start_date', StartDateTxt);
                        PlanningObject.Add('end_date', EndDateTxt);
                        PlanningObject.Add('text', 'capacity');
                        if WithDayPlanning then begin
                            New_section_id := GetVendorNoFromDayPlanning(StartDate, EndDate, ResCap."Resource No."); //move into seciton id with DayPlanning source no. and posibility has a vendor
                            if New_section_id = '' then begin
                                if not Resource.Get(ResCap."Resource No.") then
                                    Clear(Resource);
                                section_id := section_id + '|' + Resource."Vendor No.";
                            end else
                                section_id := New_section_id;
                        end else begin
                            if not Resource.Get(ResCap."Resource No.") then
                                Clear(Resource);
                            section_id := section_id + '|' + Resource."Vendor No.";
                        end;
                        PlanningObject.Add('section_id', section_id);
                        PlanningObject.Add('type', 'capacity');
                        PlanningObject.Add('color', '#D9F0F2');

                        PlanningArray.Add(PlanningObject);

                        if AnchorDate = 0D then
                            CountToWeekNumber(ResCap."Date", WeekTemp);
                    end;
                    ResCapQry.Close();
                end;

                //Add Event of DayPlanning
                if WithDayPlanning then begin
                    DayPlanning.setrange("Plan Date", DateRec."Period Start");
                    if DayPlanning.findset then
                        repeat
                            if not Job.Get(DayPlanning."Job No.") then
                                Clear(Job);
                            if not Task.Get(DayPlanning."Job No.", DayPlanning."Job Task No.") then
                                Clear(Task);
                            ResNo := DayPlanning."Assigned Resource No.";
                            if not Resource.Get(ResNo) then
                                Clear(Resource);
                            Clear(PlanningObject);
                            PlanningObject.Add('id', DayPlanning."Job No." + '|' +
                                                    DayPlanning."Job Task No." + '|' +
                                                    Format(DayPlanning."Plan Date") + '|' +
                                                    Format(DayPlanning."Day Line No."));
                            PlanningObject.Add('start_date', StartDateTxt);
                            PlanningObject.Add('end_date', EndDateTxt);
                            if DayPlanning.Description <> '' then
                                PlanningObject.Add('text', DayPlanning.Description)
                            else
                                if DayPlanning."Assigned Resource No." <> '' then
                                    PlanningObject.Add('text', Resource.Name)
                                else
                                    PlanningObject.Add('text', 'vacant');
                            PlanningObject.Add('section_id', DayPlanning."Resource Group No." + '|' + ResNo + '|' + DayPlanning."Vendor No.");
                            if not Ven.Get(DayPlanning."Vendor No.") then
                                Clear(Ven);
                            PlanningObject.Add('details', StrSubstNo(DetailsLabel, Ven."No.", Ven.Name
                                                                                     , DayPlanning."Job No.", Job.Description
                                                                                     , DayPlanning."Job Task No.", Task.Description));
                            if DayPlanning."Vendor No." = '' then begin
                                PlanningObject.Add('color', 'green');
                                PlanningObject.Add('type', 'DayPlanning_0');
                            end else begin
                                PlanningObject.Add('color', 'grey');
                                PlanningObject.Add('type', 'DayPlanning_1');
                            end;

                            PlanningArray.Add(PlanningObject);
                        until DayPlanning.next = 0;
                end;

            until DateRec.Next() = 0;

        if AnchorDate = 0D then begin
            WeekTemp.Reset();
            WeekTemp.SetCurrentKey("Column 3 Amt.");
            WeekTemp.FindSet();
            if WeekTemp.FindLast() then
                EarliestPlanningDate := DWY2Date(1, WeekTemp."Column 2 Amt.", WeekTemp."Column 1 Amt.")
            else
                EarliestPlanningDate := Today();
        end else
            GetWeekPeriodDates(AnchorDate, EarliestPlanningDate, DummyEndDate);

        PlanningArray.WriteTo(PlanninJsonTxt);

        //DownloadResourceTempToExcel(ResourceTemp); // For testing purposes

        GetUniqueResGroupFromCapacity(TempResGroup, WithDayPlanning, StartDate, EndDate);
        if TempResGroup.FindSet() then begin
            Clear(DataArray);
            repeat
                // 1. Resource Group
                Clear(GroupResObject);
                GroupResObject.Add('key', TempResGroup."No." + '||Group');
                GroupResObject.Add('label', TempResGroup.Name);
                GroupResObject.Add('category', 'Group');
                GroupResObject.Add('open', true);
                Clear(GroupChildrenArray);

                if WithDayPlanning then begin
                    // 2. Internal / Vendor
                    GetUniqueVendorsFromDayPlannings(TempVendor, TempResGroup."No.", StartDate, EndDate);
                    if TempVendor.FindSet() then
                        repeat
                            VenNo := TempVendor."Currency Code";
                            Clear(InternalExternalObject);
                            InternalExternalObject.Add('key', TempResGroup."No." + '||' + VenNo + '|Vendor');
                            InternalExternalObject.Add('category', 'Vendor');
                            if VenNo = '' then
                                InternalExternalObject.Add('label', 'Internal')
                            else begin
                                Ven.Get(VenNo);
                                InternalExternalObject.Add('label', Ven.Name);
                            end;
                            InternalExternalObject.Add('open', true);
                            GroupChildrenArray.Add(InternalExternalObject);
                            Clear(InternalExternalChildrenArray);

                            // 3. Resource                            
                            ResourceTemp.Reset();
                            ResourceTemp.Deleteall;
                            GetUniqueResFromCapacity(ResourceTemp, TempResGroup."No.", VenNo, StartDate, EndDate);
                            ResourceTemp.Setrange("Vendor No.", VenNo);
                            if ResourceTemp.FindSet() then
                                repeat
                                    Clear(ResourceObject);
                                    ResourceObject.Add('key', TempResGroup."No." + '|' + ResourceTemp."No." + '|' + VenNo);
                                    ResourceObject.Add('label', ResourceTemp.Name);
                                    ResourceObject.Add('category', 'Resource');
                                    InternalExternalChildrenArray.Add(ResourceObject);
                                until ResourceTemp.Next() = 0;
                            InternalExternalObject.Add('children', InternalExternalChildrenArray);

                        until TempVendor.Next() = 0;
                    GroupResObject.Add('children', GroupChildrenArray);
                    DataArray.Add(GroupResObject);
                end else begin
                    // Vendor and Resource
                    GetUniqueResFromCapacity(ResourceTemp, TempVen, TempResGroup."No.", StartDate, EndDate);
                    if TempVen.FindSet() then
                        repeat
                            // 2. Vendor
                            Clear(InternalExternalObject);
                            InternalExternalObject.Add('key', TempResGroup."No." + '||' + TempVen."No." + '|Vendor');
                            InternalExternalObject.Add('category', 'Vendor');
                            InternalExternalObject.Add('label', TempVen.Name);
                            InternalExternalObject.Add('open', true);
                            GroupChildrenArray.Add(InternalExternalObject);
                            Clear(InternalExternalChildrenArray);

                            // 3. Resource
                            ResourceTemp.SetRange("Vendor No.", TempVen."No.");
                            if ResourceTemp.FindSet() then begin
                                repeat
                                    if not Resource.Get(ResourceTemp."No.") then
                                        Clear(Resource);
                                    Clear(ResourceObject);
                                    ResourceObject.Add('key', TempResGroup."No." + '|' + ResourceTemp."No." + '|' + Resource."Vendor No.");
                                    ResourceObject.Add('label', ResourceTemp.Name);
                                    ResourceObject.Add('category', 'Resource');
                                    InternalExternalChildrenArray.Add(ResourceObject);
                                until ResourceTemp.Next() = 0;
                                InternalExternalObject.Add('children', InternalExternalChildrenArray);
                            end;

                        until TempVen.Next() = 0;
                    GroupResObject.Add('children', GroupChildrenArray);
                    DataArray.Add(GroupResObject);
                end;
            until TempResGroup.Next() = 0;
        end;

        Clear(Root);
        Root.Add('data', DataArray);

        // Write JSON to text
        Root.WriteTo(OutText);
        exit(OutText);
    end;


    procedure GetYUnitElementsJSON_Pool(AnchorDate: Date;
                                   StartDate: Date;
                                   EndDate: Date;
                                   WithDayPlanning: Boolean;
                                   var PlanninJsonTxt: Text;
                                   var EarliestPlanningDate: Date;
                                   ResourceFilter: Text;
                                   ResourceNameFilter: Text;
                                   SkillFilter: Text): Text
    var
        ResCap: Record "Res. Capacity Entry";
        PoolRes: Record Resource;
        WeekTemp: record "Aging Band Buffer" temporary;
        TempResGroup: record "Resource Group" temporary;
        TempPoolRes: record "Aging Band Buffer" temporary;
        ResourceTemp: Record Resource temporary;
        TempPool: record Resource temporary;
        DayPlanning: record "Day Planning";
        Job: Record Job;
        Task: Record "Job Task";

        ResCapQry: Query "Capacity Per Day Per Resource";

        GroupResObject, InternalExternalObject, ResourceObject : JsonObject;
        GroupChildrenArray, InternalExternalChildrenArray : JsonArray;
        PlanningObject, Root : JsonObject;
        PlanningArray, DataArray : JsonArray;
        OutText: Text;

        ResNo: Code[20];
        PoolNo: Code[20];
        section_id: Text;
        New_section_id: Text;
        StartDateTxt: Text;
        EndDateTxt: Text;
        DummyEndDate: Date;
        DetailsLabel: Label '%1 - %2|%3 - %4|%5 - %6';
    begin
        PlanninJsonTxt := '';
        //Marking Job based on Day Plannings within the given date range
        WeekTemp.Reset();
        WeekTemp.DeleteAll();

        //Add Events of Capacity for the whole period in a single query pass (was: one query open/close per calendar day).
        ResCapQry.SetRange(Date_filter, StartDate, EndDate);
        if ResourceFilter <> '' then
            ResCapQry.SetRange(Resource_No__Filter, ResourceFilter);
        if ResCapQry.Open() then begin
            while ResCapQry.Read() do begin
                ResCap.Get(ResCapQry.Entry_No);
                GetStartEndTxt(ResCap, ResCapQry.Capacity, StartDateTxt, EndDateTxt);
                Clear(PlanningObject);
                section_id := ResCap."Resource Group No." + '|' + ResCap."Resource No.";
                PlanningObject.Add('id', Format(ResCap."Entry No."));
                PlanningObject.Add('start_date', StartDateTxt);
                PlanningObject.Add('end_date', EndDateTxt);
                PlanningObject.Add('text', 'capacity');
                // Day Planning path disabled for now — Capacity-only page 50600 always passes WithDayPlanning = false. Restore by uncommenting + re-enabling the page's Show/Hide Day Planning actions.
                /*
                if WithDayPlanning then begin
                    if not Resource.Get(ResCap."Resource No.") then
                        Clear(Resource);
                    New_section_id := GetPoolNoFromDayPlanning(StartDate, EndDate, ResCap."Resource No."); //move into seciton id with DayPlanning source no. and posibility has a vendor
                    if New_section_id = '' then begin
                        if Resource."Pool Resource No." = '' then
                            section_id := section_id + '|' + Resource."Pool Resource No." + '|Pool'
                        else
                            section_id := section_id + '|' + Resource."Pool Resource No." + '|Resource';
                    end else begin
                        if Resource."Pool Resource No." = '' then
                            section_id := New_section_id + '|Pool'
                        else
                            section_id := New_section_id + '|Resource';
                    end;
                end else begin
                */
                // Pool Resource No. now comes straight off the query's joined Resource column
                // (see query_50604_CapacityPerDayPerResource.al) instead of a per-row
                // Resource.Get() here - this loop runs once per capacity-entry row for the
                // whole week, so that Get() was the dominant cost in this page's load time.
                section_id := section_id + '|' + ResCapQry.Pool_Resource_No_;
                /*
                end;
                */
                PlanningObject.Add('section_id', section_id);
                PlanningObject.Add('type', 'capacity');
                PlanningObject.Add('color', '#D9F0F2');

                PlanningArray.Add(PlanningObject);

                if AnchorDate = 0D then
                    CountToWeekNumber(ResCap."Date", WeekTemp);
            end;
            ResCapQry.Close();
        end;

        // Day Planning path disabled for now — Capacity-only page 50600 always passes WithDayPlanning = false. Restore by uncommenting + re-enabling the page's Show/Hide Day Planning actions.
        /*
        //Add Events of DayPlanning for the whole period in a single pass
        if WithDayPlanning then begin
            DayPlanning.SetRange("Task Date", StartDate, EndDate);
            if DayPlanning.findset then
                repeat
                    if not Job.Get(DayPlanning."Job No.") then
                        Clear(Job);
                    if not Task.Get(DayPlanning."Job No.", DayPlanning."Job Task No.") then
                        Clear(Task);
                    ResNo := DayPlanning."Assigned Resource No.";
                    if not Resource.Get(ResNo) then
                        Clear(Resource);
                    Clear(PlanningObject);
                    PlanningObject.Add('id', DayPlanning."Job No." + '|' +
                                            DayPlanning."Job Task No." + '|' +
                                            Format(DayPlanning."Task Date") + '|' +
                                            Format(DayPlanning."Day Line No."));
                    GetStartEndTxt(DayPlanning, StartDateTxt, EndDateTxt);
                    PlanningObject.Add('start_date', StartDateTxt);
                    PlanningObject.Add('end_date', EndDateTxt);
                    if DayPlanning.Description <> '' then
                        PlanningObject.Add('text', DayPlanning.Description)
                    else
                        if DayPlanning."Assigned Resource No." <> '' then
                            PlanningObject.Add('text', Resource.Name)
                        else
                            PlanningObject.Add('text', 'vacant');

                    section_id := DayPlanning."Resource Group No." + '|' + ResNo + '|' + DayPlanning."Assigned Pool Resource No.";
                    if Resource."Pool Resource No." = '' then begin
                        if DayPlanning."Assigned Pool Resource No." = '' then
                            section_id := section_id + '|Pool'
                        else
                            section_id := section_id + '|Resource'
                    end else
                        section_id := section_id + '|Resource';
                    PlanningObject.Add('section_id', section_id);

                    if not PoolRes.Get(DayPlanning."Assigned Pool Resource No.") then
                        Clear(PoolRes);
                    PlanningObject.Add('details', StrSubstNo(DetailsLabel, PoolRes."No.", PoolRes.Name
                                                                             , DayPlanning."Job No.", Job.Description
                                                                             , DayPlanning."Job Task No.", Task.Description));
                    if DayPlanning."Assigned Resource No." = '' then begin
                        PlanningObject.Add('color', '#3367D1'); //Blue BC Selection
                        PlanningObject.Add('type', 'DayPlanning_0');
                    end else begin
                        PlanningObject.Add('color', '#E9E9E9'); //grey BC
                        PlanningObject.Add('type', 'DayPlanning_1');
                    end;


                    PlanningArray.Add(PlanningObject);
                until DayPlanning.next = 0;
        end;
        */

        if AnchorDate = 0D then begin
            WeekTemp.Reset();
            WeekTemp.SetCurrentKey("Column 3 Amt.");
            WeekTemp.FindSet();
            if WeekTemp.FindLast() then
                EarliestPlanningDate := DWY2Date(1, WeekTemp."Column 2 Amt.", WeekTemp."Column 1 Amt.")
            else
                EarliestPlanningDate := Today();
        end else
            GetWeekPeriodDates(AnchorDate, EarliestPlanningDate, DummyEndDate);

        PlanningArray.WriteTo(PlanninJsonTxt);

        //DownloadResourceTempToExcel(ResourceTemp); // For testing purposes

        GetUniqueResGroupFromCapacity(TempResGroup, WithDayPlanning, StartDate, EndDate);
        if TempResGroup.FindSet() then begin
            Clear(DataArray);
            repeat
                // 1. Resource Group
                Clear(GroupResObject);
                GroupResObject.Add('key', TempResGroup."No." + '||Group');
                GroupResObject.Add('label', TempResGroup.Name);
                GroupResObject.Add('category', 'Group');
                GroupResObject.Add('open', true);
                Clear(GroupChildrenArray);

                // Day Planning path disabled for now — Capacity-only page 50600 always passes WithDayPlanning = false. Restore by uncommenting + re-enabling the page's Show/Hide Day Planning actions.
                /*
                if WithDayPlanning then begin
                    // 2. Internal / Pool Resource
                    GetUniquePoolFromDayPlannings(ResourceTemp, TempPool, TempResGroup."No.", StartDate, EndDate);
                    TempPool.Setcurrentkey("Pool Resource No.", "No.");
                    if TempPool.FindSet() then
                        repeat
                            // 2. Pool/Vendor
                            Clear(InternalExternalObject);
                            InternalExternalObject.Add('key', TempResGroup."No." + '|' + TempPool."No." + '|' + TempPool."Pool Resource No." + '|Pool');
                            if TempPool."Pool Resource No." = '' then begin
                                InternalExternalObject.Add('category', 'Resource');
                            end else begin

                                InternalExternalObject.Add('category', 'Pool');
                            end;
                            InternalExternalObject.Add('label', TempPool.Name);
                            InternalExternalObject.Add('open', true);
                            GroupChildrenArray.Add(InternalExternalObject);
                            Clear(InternalExternalChildrenArray);

                            // 3. Resource
                            ResourceTemp.SetRange("Pool Resource No.", TempPool."No.");
                            if ResourceTemp.FindSet() then begin
                                repeat
                                    if not Resource.Get(ResourceTemp."No.") then
                                        Clear(Resource);
                                    Clear(ResourceObject);
                                    ResourceObject.Add('key', TempResGroup."No." + '|' + Resource."No." + '|' + ResourceTemp."Pool Resource No." + '|Resource');
                                    ResourceObject.Add('label', ResourceTemp.Name);
                                    ResourceObject.Add('category', 'Resource');
                                    InternalExternalChildrenArray.Add(ResourceObject);
                                until ResourceTemp.Next() = 0;
                                InternalExternalObject.Add('children', InternalExternalChildrenArray);
                            end;

                        until TempPool.Next() = 0;
                    GroupResObject.Add('children', GroupChildrenArray);
                    DataArray.Add(GroupResObject);
                end else begin
                */
                // Vendor and Resource
                GetUniqueResFromCapacity_Pool(ResourceTemp, TempPool, TempResGroup."No.", StartDate, EndDate, ResourceFilter, ResourceNameFilter, SkillFilter);
                TempPool.Setcurrentkey("Pool Resource No.", "No.");
                if TempPool.FindSet() then
                    repeat
                        // 3. Resource — build the leaf list first so we know whether this Pool/Vendor
                        // node has anything to show before adding it (empty nodes are skipped entirely).
                        Clear(InternalExternalChildrenArray);
                        ResourceTemp.SetRange("Pool Resource No.", TempPool."No.");
                        if ResourceTemp.FindSet() then
                            repeat
                                // ResourceTemp."Pool Resource No." is already populated by
                                // GetUniqueResFromCapacity_Pool above - re-fetching it via
                                // Resource.Get() here was a redundant full-table read on every
                                // resource in the tree (the single biggest contributor to this
                                // page's slow weekly load).
                                Clear(ResourceObject);
                                ResourceObject.Add('key', TempResGroup."No." + '|' + ResourceTemp."No." + '|' + ResourceTemp."Pool Resource No.");
                                ResourceObject.Add('label', ResourceTemp.Name);
                                ResourceObject.Add('category', 'Resource');
                                InternalExternalChildrenArray.Add(ResourceObject);
                            until ResourceTemp.Next() = 0;

                        if InternalExternalChildrenArray.Count > 0 then begin
                            // 2. Vendor/Pool node
                            Clear(InternalExternalObject);
                            //InternalExternalObject.Add('key', TempResGroup."No." + '||' + TempPool."No." + '|Pool');
                            if TempPool."Pool Resource No." = '' then begin
                                InternalExternalObject.Add('key', TempResGroup."No." + '|' + TempPool."No." + '|');
                                InternalExternalObject.Add('category', 'Resource');
                            end else begin
                                InternalExternalObject.Add('key', TempResGroup."No." + '|' + TempPool."No." + '|' + TempPool."Pool Resource No." + '|Pool');
                                InternalExternalObject.Add('category', 'Pool');
                            end;
                            InternalExternalObject.Add('label', TempPool.Name);
                            InternalExternalObject.Add('open', true);
                            InternalExternalObject.Add('children', InternalExternalChildrenArray);
                            GroupChildrenArray.Add(InternalExternalObject);
                        end;

                    until TempPool.Next() = 0;

                if GroupChildrenArray.Count > 0 then begin
                    GroupResObject.Add('children', GroupChildrenArray);
                    DataArray.Add(GroupResObject);
                end;
            /*
            end;
            */
            until TempResGroup.Next() = 0;
        end;

        Clear(Root);
        Root.Add('data', DataArray);

        // Write JSON to text
        Root.WriteTo(OutText);
        exit(OutText);
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

    local procedure GetStartEndTxt(JobPlaningLine: Record "Job Task";
                                   var StartDateTxt: Text;
                                   var EndDateTxt: Text)
    var
    begin
        StartDateTxt := '';
        EndDateTxt := '';
        case true of
            (JobPlaningLine."PlannedStartDate" <> 0D) and (JobPlaningLine."Start Time" <> 0T):
                StartDateTxt := Format(JobPlaningLine."PlannedStartDate", 0, '<Year4>-<Month,2>-<Day,2>') + ' ' + Format(JobPlaningLine."Start Time");
            (JobPlaningLine."PlannedStartDate" <> 0D) and (JobPlaningLine."Start Time" = 0T):
                StartDateTxt := Format(JobPlaningLine."PlannedStartDate", 0, '<Year4>-<Month,2>-<Day,2>') + ' 00:00';
            (JobPlaningLine."PlannedStartDate" = 0D) and (JobPlaningLine."Start Time" <> 0T),
            (JobPlaningLine."PlannedStartDate" = 0D) and (JobPlaningLine."Start Time" = 0T):
                StartDateTxt := '';
        end;

        case true of
            (JobPlaningLine."PlannedEndDate" = 0D) and (JobPlaningLine."End Time" <> 0T):
                EndDateTxt := Format(JobPlaningLine."PlannedStartDate", 0, '<Year4>-<Month,2>-<Day,2>') + ' ' + Format(JobPlaningLine."End Time");
            (JobPlaningLine."PlannedEndDate" <> 0D) and (JobPlaningLine."End Time" <> 0T):
                EndDateTxt := Format(JobPlaningLine."PlannedEndDate", 0, '<Year4>-<Month,2>-<Day,2>') + ' ' + Format(JobPlaningLine."End Time");
            (JobPlaningLine."PlannedEndDate" = 0D) and (JobPlaningLine."End Time" = 0T):
                EndDateTxt := Format(JobPlaningLine."PlannedStartDate", 0, '<Year4>-<Month,2>-<Day,2>') + ' 00:00';
            (JobPlaningLine."PlannedEndDate" <> 0D) and (JobPlaningLine."End Time" = 0T):
                EndDateTxt := Format(JobPlaningLine."PlannedEndDate", 0, '<Year4>-<Month,2>-<Day,2>') + ' 00:00';
        end;
    end;

    procedure GetStartEndTxt(DayPlanning: Record "Day Planning";
                                   var StartDateTxt: Text;
                                   var EndDateTxt: Text)
    var
    begin
        StartDateTxt := '';
        EndDateTxt := '';
        if DayPlanning."Plan Date" = 0D then
            exit;

        case true of
            (DayPlanning."Start Time Assigned" <> 0T) and (DayPlanning."End Time Assigned" <> 0T):
                begin
                    StartDateTxt := ToSessionDateTimeTxt(DayPlanning."Plan Date", DayPlanning."Start Time Assigned");
                    EndDateTxt := ToSessionDateTimeTxt(DayPlanning."Plan Date", DayPlanning."End Time Assigned");
                end;
            (DayPlanning."Start Time Assigned" <> 0T) and (DayPlanning."End Time Assigned" = 0T):
                begin
                    StartDateTxt := ToSessionDateTimeTxt(DayPlanning."Plan Date", DayPlanning."Start Time Assigned");
                    EndDateTxt := Format(DayPlanning."Plan Date", 0, '<Year4>-<Month,2>-<Day,2>') + ' 23:59:59';
                end;
            (DayPlanning."Start Time Assigned" = 0T) and (DayPlanning."End Time Assigned" <> 0T):
                begin
                    StartDateTxt := Format(DayPlanning."Plan Date", 0, '<Year4>-<Month,2>-<Day,2>') + ' 00:00';
                    EndDateTxt := ToSessionDateTimeTxt(DayPlanning."Plan Date", DayPlanning."End Time Assigned");
                end;
            (DayPlanning."Start Time Assigned" = 0T) and (DayPlanning."End Time Assigned" = 0T):
                begin
                    StartDateTxt := Format(DayPlanning."Plan Date", 0, '<Year4>-<Month,2>-<Day,2>') + ' 00:00';
                    EndDateTxt := Format(DayPlanning."Plan Date", 0, '<Year4>-<Month,2>-<Day,2>') + ' 23:59:59';
                end;
        end;
    end;

    procedure GetStartEndTxt(ResCap: Record "Res. Capacity Entry";
                                   Capacity: Decimal;
                                   var StartDateTxt: Text;
                                   var EndDateTxt: Text)
    var
        tm: Time;
        endTm: Time;
        StartDateTime: DateTime;
        EndDateTime: DateTime;
        CapacityDuration: Duration;
    begin
        StartDateTxt := '';
        EndDateTxt := '';
        if ResCap."Date" = 0D then
            exit;

        // Trust the stored Start Time as-is: the demo generator anchors capacity entries at
        // midnight (000000T) by design (see GetRandomDailyCapacity in codeunit_50602), so 0T is
        // now a legitimate real value here, not a "blank/unset" sentinel — forcing it to 070000T
        // silently shifted every midnight-anchored entry's displayed start 7 hours later than what
        // was actually stored (e.g. a 15h entry stored as 00:00-15:00 rendered as 07:00-15:00).
        tm := ResCap."Start Time";

        // Convert start date and time to DateTime
        StartDateTime := CreateDateTime(ResCap."Date", tm);
        StartDateTxt := ToSessionDateTimeTxt(ResCap."Date", tm);

        // Prefer the End Time already stored on the record instead of recomputing it from the
        // Capacity value passed in - that recomputation is what produced wrong tooltips (e.g.
        // "08:00 -> 08:05") whenever the passed-in Capacity didn't match what the record's own
        // Start/End actually represented (e.g. a per-day-per-resource query value).
        //
        // Not every caller can supply a real End Time though: a few callers (the resource
        // scheduler week/capacity views) build a synthetic, temporary Res. Capacity Entry that
        // aggregates several real entries into one block (summed Capacity, earliest Start Time)
        // and deliberately leave End Time blank because there is no single stored End Time for an
        // aggregate. For those, fall back to the original Capacity-duration math - same as the
        // "if tm = 0T" fallback pattern used for Start Time above, just applied to End Time.
        endTm := ResCap."End Time";
        if endTm <> 0T then
            EndDateTime := CreateDateTime(ResCap."Date", endTm)
        else begin
            // Calculate capacity as duration in milliseconds
            // Capacity is in hours, so: hours * 60 minutes * 60 seconds * 1000 milliseconds
            CapacityDuration := Capacity * 60 * 60 * 1000;
            EndDateTime := StartDateTime + CapacityDuration;
        end;

        // Extract date and time from end datetime and convert to session timezone text
        EndDateTxt := ToSessionDateTimeTxt(DT2Date(EndDateTime), DT2Time(EndDateTime));
    end;

    local procedure ToSessionDateTimeTxt(UtcDate: Date; UtcTime: Time): Text
    var
        IsoTxt: Text;
        UtcDT: DateTime;
        LocalDate: Date;
        LocalTime: Time;
        FormattedTime: Text;
    begin
        // Build a UTC DateTime and let AL convert it to the session time zone
        FormattedTime := Format(UtcTime, 0, '<Hours24,2>:<Minutes,2>:<Seconds,2>');
        IsoTxt := Format(UtcDate, 0, '<Year4>-<Month,2>-<Day,2>') + ' ' + DelChr(FormattedTime, '<', ' ');  //+ 'Z';
        if not Evaluate(UtcDT, IsoTxt) then
            Error('Invalid UTC date/time: %1 %2 from text value %3', UtcDate, UtcTime, IsoTxt);

        LocalDate := DT2Date(UtcDT); // converted to current user's time zone
        LocalTime := DT2Time(UtcDT);

        // Explicit 24-hour format, matching the pattern used above for FormattedTime: a bare
        // Format(LocalTime) uses the session's regional format, which can render 12-hour with an
        // AM/PM suffix (e.g. "3:00:00 PM") depending on locale. DHTMLX's scheduler.parse() expects
        // a strict 24-hour "yyyy-MM-dd HH:mm:ss" string and can silently misparse an AM/PM string
        // instead of erroring, which was producing wrong/truncated-looking event bars regardless of
        // how correct the underlying Start/End Time values were.
        exit(Format(LocalDate, 0, '<Year4>-<Month,2>-<Day,2>') + ' ' + Format(LocalTime, 0, '<Hours24,2>:<Minutes,2>:<Seconds,2>'));
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

    procedure GetYearPeriodDates(CurrentDate: Date; var StartDate: Date; var EndDate: Date)
    begin
        StartDate := CalcDate('<-CY>', CurrentDate);
        EndDate := CalcDate('<CY>', CurrentDate)
    end;

    procedure GetMonthPeriodDates(CurrentDate: Date; var StartDate: Date; var EndDate: Date)
    begin
        StartDate := CalcDate('<-CM>', CurrentDate);
        EndDate := CalcDate('<CM>', CurrentDate)
    end;

    procedure GetEventDataFromEventId(EventId: Text; var EventDataJsonTxt: Text): Boolean
    var
        DayPlanning: record "Day Planning";
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
        rtv := DayPlanning.Get(JobNo, TaskNo, DayLineNo);
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
                                DayPlanning.Description,
                                ToSessionDateTimeTxt(DayPlanning."Plan Date", DayPlanning."Start Time Assigned"),
                                ToSessionDateTimeTxt(DayPlanning."Plan Date", DayPlanning."End Time Assigned"),
                                DayPlanning."Job No." + '|' + DayPlanning."Job Task No.",
                                DayPlanning."Assigned Resource No.",
                                DayPlanning.Description)
        end;
        exit(rtv);
    end;

    procedure onEventAdded(EventData: Text; var UpdateEventIdJsonTxt: Text): Boolean
    var
        Task: record "Job Task";
        PlanningLine: record "Job Task";
        DayPlanning: record "Day Planning";
        Res: record Resource;
        DailyOptimizerSetup: Record "Daily Optimizer Setup";
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
        NoDefaultSkillErr: Label 'Cannot create a Day Planning line from the scheduler: no Skill context is available for this drag-and-drop event, and "Daily Optimizer Setup"."Default Skill" is not set. Configure a Default Skill before assigning resources this way.';
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
        DayPlanning.SetRange("Job No.", JobNo);
        DayPlanning.SetRange("Job Task No.", TaskNo);
        DayPlanning.SetRange("Plan Date", PlanningDate);
        if DayPlanning.FindLast() then
            LineNo := DayPlanning."Day Line No." + 10000;

        DayPlanning.Init();
        DayPlanning."Plan Date" := PlanningDate;
        DayPlanning."Day Line No." := LineNo;
        DayPlanning."Job No." := JobNo;
        DayPlanning."Job Task No." := TaskNo;

        // Validate the resource first (CheckResourceHasSkill confirms it has *a* skill) - its own
        // OnValidate auto-fills Skill with the resource's first skill as a side effect. Only fall
        // back to "Daily Optimizer Setup"."Default Skill" if that left Skill blank (i.e. don't
        // override a skill the resource already validated as holding) - this drag-and-drop
        // payload carries no Skill context of its own (see the sample JSON shape in the comment
        // above), so blank is possible. DailyOptimizerSetup.Get() is deliberately INSIDE this
        // check, not called upfront, since Skill is rarely actually blank here - no need for the
        // extra SQL round-trip on the common path.
        DayPlanning.Validate("Assigned Resource No.", Res."No.");
        if DayPlanning.Skill = '' then begin
            DailyOptimizerSetup.Get();
            if DailyOptimizerSetup."Default Skill" = '' then
                Error(NoDefaultSkillErr);
            DayPlanning.Validate(Skill, DailyOptimizerSetup."Default Skill");
        end;
        DayPlanning."Start Time Assigned" := StartTime;
        DayPlanning."End Time Assigned" := EndTime;
        DayPlanning.Description := Res.Name;
        UpdateEventIdJsonTxt := StrSubstNo(JsonLbl,
                                            old_eventid,
                                            DayPlanning."Job No.",
                                            DayPlanning."Job Task No.",
                                            format(DayPlanning."Plan Date"),
                                            format(DayPlanning."Day Line No."));
        rtv := DayPlanning.Insert(true);
        exit(rtv);
    end;

    procedure OnEventChanged_Resource(EventId: Text;
                             EventData: Text;
                             var DateRef: Date)
    var
        OldTask: record "Job Task";
        OldPlanningLIne: record "Job Task";
        OldDayPlanning: record "Day Planning";
        OldResource: record Resource;
        OldVendor: Record Vendor;

        ResourceCheck: record Resource;
        VendorCheck: record Vendor;

        EventJSonObj: JsonObject;
        JToken: JsonToken;
        EventIdParts: List of [Text];
        NewSectionParts: List of [Text];
        NewResNo: Text;
        NewResource: record Resource;
        NewVenNo: Text;
        NewVendor: Record Vendor;

        OldJobNo: Text;
        OldTaskNo: Text;
        OldPlanningLineNo: Integer;
        OldDayNo: Integer;
        OldDayLineNo: Integer;

        //_Date: Date;
        _Time: Time;
        _DateTime: DateTime;
        _DateTimeUserZone: DateTime;
    begin
        //**** New Code: modification of event follow BC Resource Capacity, not belong to dhtml scheduler
        EventJSonObj.ReadFrom(EventData);
        //Get Startdate as new dayno
        EventJSonObj.Get('start_date', JToken);
        //Covert _Date + _Time into Datetime var, after that extract Date part again to get the correct date in user's timezone
        Evaluate(_DateTime, JToken.AsValue().AsText());
        _DateTimeUserZone := ConvertToUserTimeZone(_DateTime);
        DateRef := DT2Date(_DateTimeUserZone);

        //**** OLD Code: *****
        // // New Section/Element id
        // EventJSonObj.ReadFrom(EventData);
        // EventJSonObj.Get('section_id', JToken);
        // NewSectionParts := JToken.AsValue().AsText().Split('|');
        // NewResNo := NewSectionParts.Get(2);
        // if not NewResource.Get(NewResNo) then begin
        //     NewResource.Init;
        //     NewResource."No." := NewResNo;
        // end;
        // NewVenNo := NewSectionParts.Get(3);
        // if not NewVendor.Get(NewVenNo) then begin
        //     NewVendor.Init;
        //     NewVendor."No." := NewVenNo;
        // end;

        // // get old record
        // EventIdParts := eventId.Split('|');
        // OldJobNo := EventIdParts.Get(1);
        // OldTaskNo := EventIdParts.Get(2);
        // Evaluate(OldPlanningLineNo, EventIdParts.Get(3));
        // Evaluate(OldDayNo, EventIdParts.Get(4));
        // Evaluate(OldDayLineNo, EventIdParts.Get(5));
        // OldTask.Get(OldJobNo, OldTaskNo);
        // OldPlanningLIne.Get(OldJobNo, OldTaskNo, OldPlanningLineNo);
        // OldDayPlanning.Get(OldDayNo, OldDayLineNo, OldJobNo, OldTaskNo, OldPlanningLineNo);
        // if not OldResource.Get(OldDayPlanning."No.") then begin
        //     OldResource.Init;
        //     OldResource."No." := OldDayPlanning."No.";
        // end;
        // if not OldVendor.Get(OldDayPlanning."Vendor No.") then begin
        //     OldVendor.Init;
        //     OldVendor."No." := OldDayPlanning."Vendor No.";
        // end;


        // //*****


        // //Get Startdate as new dayno
        // EventJSonObj.Get('start_date', JToken);
        // //Covert _Date + _Time into Datetime var, after that extract Date part again to get the correct date in user's timezone
        // Evaluate(_DateTime, JToken.AsValue().AsText());
        // _DateTimeUserZone := ConvertToUserTimeZone(_DateTime);
        // DateRef := DT2Date(_DateTimeUserZone);

        // if OldResource.RecordId <> NewResource.RecordId then begin
        //     //sift up / down within different task
        //     if ResourceCheck.Get(NewResource."No.") then begin
        //         OldDayPlanning."No." := NewResource."No.";
        //         OldDayPlanning.Modify();
        //     end;
        // end;

        // if OldVendor.RecordId <> NewVendor.RecordId then begin
        //     //sift up / down within different task
        //     if VendorCheck.Get(NewVendor."No.") then begin
        //         OldDayPlanning."Vendor No." := NewVendor."No.";
        //         OldDayPlanning.Modify();
        //     end;
        // end;

        // //sift left / right to same task
        // EventJSonObj.Get('start_date', JToken);
        // Evaluate(_DateTime, JToken.AsValue().AsText());
        // _DateTimeUserZone := ConvertToUserTimeZone(_DateTime);
        // OldDayPlanning."Task Date" := DT2Date(_DateTimeUserZone);
        // OldDayPlanning."Start Time" := DT2Time(_DateTimeUserZone);

        // EventJSonObj.Get('end_date', JToken);
        // Evaluate(_DateTime, JToken.AsValue().AsText());
        // _DateTimeUserZone := ConvertToUserTimeZone(_DateTime);
        // OldDayPlanning."End Time" := DT2Time(_DateTimeUserZone);

        // EventJSonObj.Get('text', JToken);
        // OldDayPlanning.Description := JToken.AsValue().AsText();

        // OldDayPlanning.Modify();

    end;

    procedure OnEventChanged_Project(EventId: Text;
                             EventData: Text;
                             var UpdateEventID: Boolean;
                             var OldDayPlanning_forUpdate: record "Day Planning";
                             var NewDayPlanning_forUpdate: record "Day Planning")
    var
        OldTask: record "Job Task";
        NewTask: record "Job Task";
        OldPlanningLIne: record "Job Task";
        NewPlanningLIne: record "Job Task";
        OldDayPlanning: record "Day Planning";
        DayPlanningCheck: record "Day Planning";

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
        New_Date: Date;
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
        OldDayPlanning.Get(Old_JobNo, Old_TaskNo, Old_DayLineNo);

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
        New_Date := DT2Date(_DateTimeUserZone);
        Evaluate(New_DayNo, Format(New_Date, 0, '<Year4><Month,2><Day,2>'));

        UpdateEventID := false;
        OldDayPlanning_forUpdate := OldDayPlanning;
        if OldPlanningLIne.RecordId <> NewPlanningLIne.RecordId then begin
            //sift up / down within different task
            // PK is now (Job No., Job Task No., Day Line No.) — check if target slot is free.
            if not DayPlanningCheck.Get(New_JobNo, New_TaskNo, Old_DayLineNo) then
                OldDayPlanning.Rename(New_JobNo, New_TaskNo, Old_DayLineNo)
            else begin
                // Slot taken: find max DayLineNo for the target task and append after it.
                DayPlanningCheck.SetRange("Job No.", New_JobNo);
                DayPlanningCheck.SetRange("Job Task No.", New_TaskNo);
                if DayPlanningCheck.FindLast() then
                    OldDayPlanning.Rename(New_JobNo, New_TaskNo, DayPlanningCheck."Day Line No." + 10000)
                else
                    OldDayPlanning.Rename(New_JobNo, New_TaskNo, 10000);
            end;
            NewDayPlanning_forUpdate := OldDayPlanning;
            UpdateEventID := true;
        end;

        //sift left / right to same task
        EventJSonObj.Get('start_date', JToken);
        Evaluate(_DateTime, JToken.AsValue().AsText());
        _DateTimeUserZone := ConvertToUserTimeZone(_DateTime);
        OldDayPlanning."Plan Date" := DT2Date(_DateTimeUserZone);
        OldDayPlanning."Start Time Assigned" := DT2Time(_DateTimeUserZone);

        EventJSonObj.Get('end_date', JToken);
        Evaluate(_DateTime, JToken.AsValue().AsText());
        _DateTimeUserZone := ConvertToUserTimeZone(_DateTime);
        OldDayPlanning."End Time Assigned" := DT2Time(_DateTimeUserZone);

        EventJSonObj.Get('text', JToken);
        OldDayPlanning.Description := JToken.AsValue().AsText();

        OldDayPlanning.Modify();

        if UpdateEventID then
            UpdateEventID(OldDayPlanning_forUpdate, NewDayPlanning_forUpdate);
    end;

    procedure UpdateEventID(OldDayPlanning: Record "Day Planning"; NewDayPlanning: Record "Day Planning"): Text
    var
        rtv: text;
        JsonLbl: Label '{"OldEventId": "%1|%2|%3|%4|%5", "NewEventId": "%6|%7|%8|%9|%10"}';
    begin
        rtv := StrSubstNo(JsonLbl,
                         OldDayPlanning."Job No.",
                         OldDayPlanning."Job Task No.",
                         Format(OldDayPlanning."Plan Date"),
                         Format(OldDayPlanning."Day Line No."),
                         NewDayPlanning."Job No.",
                         NewDayPlanning."Job Task No.",
                         Format(NewDayPlanning."Plan Date"),
                         Format(NewDayPlanning."Day Line No."));
        exit(rtv);
    end;

    /// <summary>
    /// Opens the "Day Planning Card" (page 50668) as a brand-new, NOT-YET-INSERTED record,
    /// pre-filled with Job No./Job Task No. (from SectionId, format "JobNo|JobTaskNo" - same
    /// key format the Task Scheduler's tree leaves and events already use), Plan Date (the
    /// DATE portion of StartDateIso, an ISO datetime string from the drag-create gesture's
    /// start instant - parsed/timezone-converted the same way OnEventChanged_Project above
    /// does for its own start_date), and Start/End Time Requested (the TIME portions of
    /// StartDateIso/EndDateIso respectively). Only StartDateIso's DATE is used for Plan Date;
    /// a Day Planning is inherently single-day, so EndDateIso's date component (if the drag
    /// happened to cross midnight) is discarded - only its time-of-day is kept.
    ///
    /// Three earlier attempts at "phantom new record, never Insert()'d" all failed, confirmed
    /// live against a Job Task that already has real Day Planning history:
    ///   1. Page.RunModal(ObjectId, Record-with-FilterGroup(2)-only) - opened blank (filters
    ///      were never applied to the page's own query at all).
    ///   2. A Page VARIABLE's SetTableView(Record-with-FilterGroup(2))+RunModal() - opened, but
    ///      blank AND NOT EDITABLE (browsing an empty result set, not New mode).
    ///   3. Init() + direct field assignment (Job No./Job Task No./a "guaranteed free" Day Line
    ///      No. via GetNextDayLineNo()), never Insert()'d, passed straight to RunModal - this
    ///      looked right, but RunModal(ObjectId, Record) turned out to always navigate to the
    ///      nearest EXISTING row for whatever key was given rather than opening a genuinely
    ///      blank one when ANY rows already exist for that Job No./Job Task No. - confirmed via
    ///      the BC MCP tool: the Card silently showed a real, pre-existing Day Planning (real
    ///      Skill/Resource/Plan Date, none of which this procedure ever set) instead of the
    ///      blank new one intended. There is no "force New mode" switch for RunModal(ObjectId,
    ///      Record) - that only happens via the framework's own "+ New" action internals, which
    ///      calling this procedure doesn't go through.
    ///
    /// So: skip the phantom-record games entirely. Insert a REAL row (with a guaranteed-free
    /// Day Line No. computed directly here, not via table 50610's own GetNextDayLineNo() -
    /// deliberately not reused after attempt 3 called it and still got redirected to a
    /// colliding existing row; computing it inline removes any doubt about what's actually
    /// running), open the Card on that now-unambiguous key (RunModal has exactly one row to
    /// find), and delete it again if the user didn't confirm the page with OK - the standard
    /// "insert real, delete on cancel" idiom, more predictable here than fighting RunModal's
    /// new-vs-navigate ambiguity.
    /// </summary>
    procedure DragCreateDayPlanningCard(SectionId: Text; StartDateIso: Text; EndDateIso: Text)
    var
        NewDayPlanning: Record "Day Planning";
        LastDayPlanning: Record "Day Planning";
        SectionParts: List of [Text];
        JobNo: Code[20];
        JobTaskNo: Code[20];
        PlanDate: Date;
        _DateTime: DateTime;
        _DateTimeUserZone: DateTime;
        _EndDateTime: DateTime;
        _EndDateTimeUserZone: DateTime;
        NewDayLineNo: Integer;
    begin
        SectionParts := SectionId.Split('|');
        if SectionParts.Count() < 2 then
            exit;
        JobNo := CopyStr(SectionParts.Get(1), 1, MaxStrLen(JobNo));
        JobTaskNo := CopyStr(SectionParts.Get(2), 1, MaxStrLen(JobTaskNo));
        if (JobNo = '') or (JobTaskNo = '') then
            exit;

        if not Evaluate(_DateTime, StartDateIso) then
            exit;
        _DateTimeUserZone := ConvertToUserTimeZone(_DateTime);
        PlanDate := DT2Date(_DateTimeUserZone);

        LastDayPlanning.Reset();
        LastDayPlanning.SetRange("Job No.", JobNo);
        LastDayPlanning.SetRange("Job Task No.", JobTaskNo);
        if LastDayPlanning.FindLast() then
            NewDayLineNo := LastDayPlanning."Day Line No." + 10000
        else
            NewDayLineNo := 10000;

        NewDayPlanning.Init();
        NewDayPlanning."Job No." := JobNo;
        NewDayPlanning."Job Task No." := JobTaskNo;
        NewDayPlanning."Day Line No." := NewDayLineNo;
        NewDayPlanning."Plan Date" := PlanDate;
        NewDayPlanning."Start Time Requested" := DT2Time(_DateTimeUserZone);
        if (EndDateIso <> '') and Evaluate(_EndDateTime, EndDateIso) then begin
            _EndDateTimeUserZone := ConvertToUserTimeZone(_EndDateTime);
            NewDayPlanning."End Time Requested" := DT2Time(_EndDateTimeUserZone);
        end;
        NewDayPlanning.Insert(true);
        Commit();

        if Page.RunModal(Page::"Day Planning Card Opt", NewDayPlanning) <> Action::LookupOK then
            if NewDayPlanning.Get(JobNo, JobTaskNo, NewDayLineNo) then
                NewDayPlanning.Delete(true);
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

    procedure GetEventData(EventDataJsonTxt: Text;
                          var EventId: Text;
                          var StartDateTxt: Text;
                          var EndDateTxt: Text;
                          var SectionId: Text;
                          var pText: Text;
                          var Type: Text)
    var
        EventJSonObj: JsonObject;
        JToken: JsonToken;
    begin
        EventJSonObj.ReadFrom(EventDataJsonTxt);

        EventJSonObj.Get('id', JToken);
        EventId := JToken.AsValue().AsText();

        EventJSonObj.Get('start_date', JToken);
        StartDateTxt := JToken.AsValue().AsText();

        EventJSonObj.Get('end_date', JToken);
        EndDateTxt := JToken.AsValue().AsText();

        EventJSonObj.Get('section_id', JToken);
        SectionId := JToken.AsValue().AsText();

        EventJSonObj.Get('text', JToken);
        pText := JToken.AsValue().AsText();

        EventJSonObj.Get('type', JToken);
        Type := JToken.AsValue().AsText();
    end;

    procedure OpenCapacity(eventId: Text; DateRef: Date)
    var
        ResCap: record "Res. Capacity Entry";
        ResNo: Code[20];
        startDate, endDate : Date;
        ResCapEntryNo: Integer;
        InvalidEvent: label 'Invalid Event ID for Resource Capacity Entry: %1';
        ResNotFound: label 'Resource Capacity Entry not found for Event ID: %1';
    begin
        if not Evaluate(ResCapEntryNo, eventId) then
            Error(InvalidEvent, eventId);
        if ResCap.Get(ResCapEntryNo) then begin
            GetWeekPeriodDates(DateRef, startDate, endDate);
            ResNo := ResCap."Resource No.";
            ResCap.SetRange("Resource No.", ResNo);
            ResCap.SetRange("Date", startDate, endDate);
            Page.RunModal(0, ResCap);
        end else
            Error(ResNotFound, eventId);
    end;

    procedure OpenDayPlanning(eventId: Text): Date
    var
        DayPlanning: Record "Day Planning";
        DayPlannings: page "Day Plannings";
        EventIDList: List of [Text];
        JobNo: Code[20];
        TaskNo: Code[20];
        //PlanningLineNo: Integer;
        TaskDay: Date;
        DayLineNo: Integer;
        DateOfDayPlanning: Date;
        MsgLbl: Label 'Day planning not found for Event ID: %1';
    begin
        DateOfDayPlanning := 0D;
        EventIDList := eventId.Split('|');
        JobNo := EventIDList.Get(1);
        TaskNo := EventIDList.Get(2);
        Evaluate(TaskDay, EventIDList.Get(3));
        Evaluate(DayLineNo, EventIDList.Get(4));
        DayPlanning.SetRange("Plan Date", TaskDay);
        //DayPlanning.SetRange("DayLineNo", DayLineNo);
        DayPlanning.SetRange("Job No.", JobNo);
        DayPlanning.SetRange("Job Task No.", TaskNo);
        if DayPlanning.FindFirst() then begin
            DateOfDayPlanning := DayPlanning."Plan Date";
            Clear(DayPlannings);
            DayPlannings.SetTableView(DayPlanning);
            DayPlannings.RunModal();
        end else
            Message(MsgLbl, eventId);
        exit(DateOfDayPlanning);
    end;

    /// <summary>
    /// Opens the DHX Resource Scheduler filtered to the Assigned Resource No. of the day
    /// planning line linked to the given event ID (format: JobNo|JobTaskNo|DayNo|DayLineNo|ResNo|ResName).
    /// Used by the right-click context menu "Open Resource Scheduler (assigned)" on an event.
    /// </summary>
    procedure OpenResourceSchedulerAssigned(eventId: Text)
    var
        DayPlanning: Record "Day Planning";
        ResScheduler: Page "DHX Resource Scheduler";
        EventIDList: List of [Text];
        JobNo: Code[20];
        TaskNo: Code[20];
        DayLineNo: Integer;
        MsgLbl: Label 'Day planning not found for Event ID: %1';
    begin
        EventIDList := eventId.Split('|');
        JobNo := EventIDList.Get(1);
        TaskNo := EventIDList.Get(2);
        Evaluate(DayLineNo, EventIDList.Get(4));
        if DayPlanning.Get(JobNo, TaskNo, DayLineNo) then begin
            if DayPlanning."Assigned Resource No." <> '' then begin
                ResScheduler.SetResourceFilter(DayPlanning."Assigned Resource No.");
                ResScheduler.RunModal();
            end;
        end else
            Message(MsgLbl, eventId);
    end;

    /// <summary>
    /// Opens the DHX Resource Scheduler filtered to the Requested Resource No. of the day
    /// planning line linked to the given event ID (format: JobNo|JobTaskNo|DayNo|DayLineNo|ResNo|ResName).
    /// Used by the right-click context menu "Open Resource Scheduler (Requested)" on an event.
    /// </summary>
    procedure OpenResourceSchedulerRequested(eventId: Text)
    var
        DayPlanning: Record "Day Planning";
        ResScheduler: Page "DHX Resource Scheduler";
        EventIDList: List of [Text];
        JobNo: Code[20];
        TaskNo: Code[20];
        DayLineNo: Integer;
        MsgLbl: Label 'Day planning not found for Event ID: %1';
    begin
        EventIDList := eventId.Split('|');
        JobNo := EventIDList.Get(1);
        TaskNo := EventIDList.Get(2);
        Evaluate(DayLineNo, EventIDList.Get(4));
        if DayPlanning.Get(JobNo, TaskNo, DayLineNo) then begin
            if DayPlanning."Requested Resource No." <> '' then begin
                ResScheduler.SetResourceFilter(DayPlanning."Requested Resource No.");
                ResScheduler.RunModal();
            end;
        end else
            Message(MsgLbl, eventId);
    end;

    /// <summary>
    /// Opens the standard Resource Card filtered to the Requested Resource No. of the day
    /// planning line linked to the given event ID (format: JobNo|JobTaskNo|DayNo|DayLineNo|ResNo|ResName).
    /// Used by the right-click context menu "Open Requested Resource Card" on an event.
    /// </summary>
    procedure OpenRequestedResourceCard(eventId: Text)
    var
        DayPlanning: Record "Day Planning";
        Resource: Record Resource;
        EventIDList: List of [Text];
        JobNo: Code[20];
        TaskNo: Code[20];
        DayLineNo: Integer;
        MsgLbl: Label 'Day planning not found for Event ID: %1';
    begin
        EventIDList := eventId.Split('|');
        JobNo := EventIDList.Get(1);
        TaskNo := EventIDList.Get(2);
        Evaluate(DayLineNo, EventIDList.Get(4));
        if DayPlanning.Get(JobNo, TaskNo, DayLineNo) then begin
            if DayPlanning."Requested Resource No." <> '' then begin
                Resource.SetFilter("No.", DayPlanning."Requested Resource No.");
                Page.RunModal(Page::"Resource Card", Resource);
            end;
        end else
            Message(MsgLbl, eventId);
    end;

    /// <summary>
    /// Opens the standard Resource Card filtered to the Assigned Resource No. of the day
    /// planning line linked to the given event ID (format: JobNo|JobTaskNo|DayNo|DayLineNo|ResNo|ResName).
    /// Used by the right-click context menu "Open Assigned Resource Card" on an event.
    /// </summary>
    procedure OpenAssignedResourceCard(eventId: Text)
    var
        DayPlanning: Record "Day Planning";
        Resource: Record Resource;
        EventIDList: List of [Text];
        JobNo: Code[20];
        TaskNo: Code[20];
        DayLineNo: Integer;
        MsgLbl: Label 'Day planning not found for Event ID: %1';
    begin
        EventIDList := eventId.Split('|');
        JobNo := EventIDList.Get(1);
        TaskNo := EventIDList.Get(2);
        Evaluate(DayLineNo, EventIDList.Get(4));
        if DayPlanning.Get(JobNo, TaskNo, DayLineNo) then begin
            if DayPlanning."Assigned Resource No." <> '' then begin
                Resource.SetFilter("No.", DayPlanning."Assigned Resource No.");
                Page.RunModal(Page::"Resource Card", Resource);
            end;
        end else
            Message(MsgLbl, eventId);
    end;

    procedure OpenResourceCard(SectionId: Text)
    var
        Resource: Record Resource;
        ResGroup: record "Resource Group";
        EventIDList: List of [Text];
        ResNo: Code[20];
        GroupNo: Code[20];
        Group, Restxt, VanOrPool : Text;
    begin
        // Implementation to open the Resource Card based on SectionId
        // SectionId = ResourceGroupNo|ResourceNo
        EventIDList := SectionId.Split('|');
        Group := EventIDList.Get(1);
        Restxt := EventIDList.Get(2);
        VanOrPool := EventIDList.Get(3);
        if Restxt <> '' then begin
            Resource.SetFilter("No.", Restxt);
            Page.RunModal(Page::"Resource Card", Resource);
        end else
            if Group <> '' then begin
                ResGroup.SetFilter("No.", GroupNo);
                Page.RunModal(0, ResGroup);
            end;

        // case true of
        //     (EventIDList.Get(1) <> '') and (EventIDList.Get(2) <> ''):
        //         begin
        //             ResNo := EventIDList.Get(2);
        //             Resource.SetRange("No.", ResNo);
        //             Page.RunModal(Page::"Resource Card", Resource);
        //         end;
        //     (EventIDList.Get(1) <> '') and (EventIDList.Get(2) = ''):
        //         begin
        //             GroupNo := EventIDList.Get(1);
        //             ResGroup.SetRange("No.", GroupNo);
        //             Page.RunModal(0, ResGroup);
        //         end;
        // end;
    end;

    procedure GetStartEndDatesFromTimeLineJSon(TimeLineJSon: Text; var StartDate: Date; var EndDate: Date)
    var
        TimeLineJSonObj: JsonObject;
        JToken: JsonToken;
        _DateTime: DateTime;
        _DateTimeUserZone: DateTime;
    begin
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
    end;

    procedure GetDayPlanningAsResourcesAndEventsJSon_Project(TimeLineJSon: Text; ResourceFilter: Text; var ResouecesJSon: Text; var EventsJSon: Text): Boolean
    var
        StartDate: Date;
        EndDate: Date;
        EarliestPlanningDate: date;
        Rtv: Boolean;
    begin
        //Message('Under development: Refreshing Timeline with TimeLineJSon: %1', TimeLineJSon);
        //exit(false);
        /*
        {"mode":"timeline","start":"2025-12-14T17:00:00.000Z","end":"2025-12-21T17:00:00.000Z"}
        */
        GetStartEndDatesFromTimeLineJSon(TimeLineJSon, StartDate, EndDate);
        Rtv := GetDayPlanningAsResourcesAndEventsJSon_Project_StartEnd(StartDate,
                                                            EndDate,
                                                            ResourceFilter,
                                                            ResouecesJSon,
                                                            EventsJSon,
                                                            EarliestPlanningDate);
        exit(Rtv);
    end;

    procedure GetDayPlanningAsResourcesAndEventsJSon_Project_StartEnd(StartDate: Date;
                                                                  EndDate: Date;
                                                                  ResourceFilter: Text;
                                                                  var ResouecesJSon: Text;
                                                                  var EventsJSon: Text;
                                                                  var EarliestPlanningDate: date): Boolean
    var
        TimeLineJSonObj: JsonObject;
        JToken: JsonToken;
        _DateTime: DateTime;
        _DateTimeUserZone: DateTime;
    begin
        ResouecesJSon := GetYUnitElementsJSON_Project(StartDate,
                                            StartDate,
                                            EndDate,
                                            ResourceFilter,
                                            EventsJSon,
                                            EarliestPlanningDate);
        exit((EventsJSon <> '') and (ResouecesJSon <> ''));
    end;

    procedure GetDayPlanningAsResourcesAndEventsJSon_Project_StartEnd(StartDate: Date;
                                                                  EndDate: Date;
                                                                  JobFilter: Text;
                                                                  JobTaskFilter: Text;
                                                                  var ResouecesJSon: Text;
                                                                  var EventsJSon: Text;
                                                                  var EarliestPlanningDate: date): Boolean
    var
        TimeLineJSonObj: JsonObject;
        JToken: JsonToken;
        _DateTime: DateTime;
        _DateTimeUserZone: DateTime;
    begin
        ResouecesJSon := GetYUnitElementsJSON_Project(StartDate,
                                            StartDate,
                                            EndDate,
                                            JobFilter,
                                            JobTaskFilter,
                                            EventsJSon,
                                            EarliestPlanningDate);
        exit((EventsJSon <> '') and (ResouecesJSon <> ''));
    end;

    procedure GetDayPlanningAsResourcesAndEventsJSon_Resource(TimeLineJSon: Text;
                                                          WithDayPlanning: Boolean;
                                                          var ResouecesJSon: Text;
                                                          var EventsJSon: Text): Boolean
    var
        StartDate: Date;
        EndDate: Date;
        EarliestPlanningDate: date;
        Rtv: Boolean;
    begin
        //Message('Under development: Refreshing Timeline with TimeLineJSon: %1', TimeLineJSon);
        //exit(false);
        /*
        {"mode":"timeline","start":"2025-12-14T17:00:00.000Z","end":"2025-12-21T17:00:00.000Z"}
        */
        GetStartEndDatesFromTimeLineJSon(TimeLineJSon, StartDate, EndDate);
        Rtv := GetDayPlanningAsResourcesAndEventsJSon_Resource_StartEnd(StartDate,
                                                            EndDate,
                                                            WithDayPlanning,
                                                            ResouecesJSon,
                                                            EventsJSon,
                                                            EarliestPlanningDate);
        exit(Rtv);
    end;

    procedure GetDayPlanningAsResourcesAndEventsJSon_Resource_StartEnd(StartDate: Date;
                                                                   EndDate: Date;
                                                                   WithDayPlanning: Boolean;
                                                                   var ResouecesJSon: Text;
                                                                   var EventsJSon: Text;
                                                                   var EarliestPlanningDate: date): Boolean
    var
        TimeLineJSonObj: JsonObject;
        JToken: JsonToken;
        _DateTime: DateTime;
        _DateTimeUserZone: DateTime;
    begin
        ResouecesJSon := GetYUnitElementsJSON_Resource(StartDate,
                                            StartDate,
                                            EndDate,
                                            WithDayPlanning,
                                            EventsJSon,
                                            EarliestPlanningDate);
        exit((EventsJSon <> '') and (ResouecesJSon <> ''));
    end;

    procedure GetDayPlanningAsResourcesAndEventsJSon_Pool_StartEnd(StartDate: Date;
                                                                   EndDate: Date;
                                                                   WithDayPlanning: Boolean;
                                                                   var ResouecesJSon: Text;
                                                                   var EventsJSon: Text;
                                                                   var EarliestPlanningDate: date;
                                                                   ResourceFilter: Text;
                                                                   ResourceNameFilter: Text;
                                                                   SkillFilter: Text): Boolean
    var
        TimeLineJSonObj: JsonObject;
        JToken: JsonToken;
        _DateTime: DateTime;
        _DateTimeUserZone: DateTime;
    begin
        ResouecesJSon := GetYUnitElementsJSON_Pool(StartDate,
                                            StartDate,
                                            EndDate,
                                            WithDayPlanning,
                                            EventsJSon,
                                            EarliestPlanningDate,
                                            ResourceFilter,
                                            ResourceNameFilter,
                                            SkillFilter);
        exit((EventsJSon <> '') and (ResouecesJSon <> ''));
    end;

    procedure DownloadResourceTempToExcel(var ResourceTemp: Record CustomRecordBuffer temporary)
    var
        ExcelBuffer: Record "Excel Buffer" temporary;
        Resource: Record Resource;
        Vendor: Record Vendor;
        RowNo: Integer;
        FileName: Text;
    begin
        if not ResourceTemp.FindSet() then
            exit;

        // Clear Excel Buffer
        ExcelBuffer.Reset();
        ExcelBuffer.DeleteAll();

        // Add Headers
        RowNo := 1;
        ExcelBuffer.NewRow();
        ExcelBuffer.AddColumn('Resource Group No.', false, '', true, false, false, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Resource No.', false, '', true, false, false, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Resource Name', false, '', true, false, false, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Vendor No.', false, '', true, false, false, '', ExcelBuffer."Cell Type"::Text);
        ExcelBuffer.AddColumn('Vendor Name', false, '', true, false, false, '', ExcelBuffer."Cell Type"::Text);

        // Add Data Rows
        ResourceTemp.Reset();
        if ResourceTemp.FindSet() then begin
            repeat
                RowNo += 1;
                ExcelBuffer.NewRow();
                ExcelBuffer.AddColumn(ResourceTemp."Code 1", false, '', false, false, false, '', ExcelBuffer."Cell Type"::Text);
                ExcelBuffer.AddColumn(ResourceTemp."Code 2", false, '', false, false, false, '', ExcelBuffer."Cell Type"::Text);

                // Get Resource Name
                if Resource.Get(ResourceTemp."Code 2") then
                    ExcelBuffer.AddColumn(Resource.Name, false, '', false, false, false, '', ExcelBuffer."Cell Type"::Text)
                else
                    ExcelBuffer.AddColumn('', false, '', false, false, false, '', ExcelBuffer."Cell Type"::Text);

                ExcelBuffer.AddColumn(ResourceTemp."Code 3", false, '', false, false, false, '', ExcelBuffer."Cell Type"::Text);

                // Get Vendor Name
                if (ResourceTemp."Code 3" <> '') and Vendor.Get(ResourceTemp."Code 3") then
                    ExcelBuffer.AddColumn(Vendor.Name, false, '', false, false, false, '', ExcelBuffer."Cell Type"::Text)
                else
                    ExcelBuffer.AddColumn('', false, '', false, false, false, '', ExcelBuffer."Cell Type"::Text);
            until ResourceTemp.Next() = 0;
        end;

        // Create Excel file
        FileName := 'ResourceSchedule_' + Format(CurrentDateTime, 0, '<Year4><Month,2><Day,2>_<Hours24,2><Minutes,2><Seconds,2>') + '.xlsx';
        ExcelBuffer.CreateNewBook('Resource Schedule');
        ExcelBuffer.WriteSheet('Resource Schedule', CompanyName, UserId);
        ExcelBuffer.CloseBook();
        ExcelBuffer.OpenExcel();
    end;

    procedure GetUniqueResFromCapacity(var TempRes: record "Resource" temporary;
                                       ResGroupNo: Code[20];
                                       VendorNo: Code[20];
                                       StartDate: Date;
                                       EndDate: Date)
    var
        Res: record Resource;
        DayPlannings: record "Day Planning";
        UniqueResQry: Query "Unique Resource in Capacity";
        ResNo: Code[20];
    begin
        // Clear the temporary table
        TempRes.Reset();
        TempRes.DeleteAll();

        // Open the query - it automatically groups by VendorNo giving unique values
        //if VendorNo = '' then begin
        UniqueResQry.SetRange(EntryDateFilter, StartDate, EndDate);
        UniqueResQry.SetRange(Resource_Group_No_, ResGroupNo);
        if UniqueResQry.Open() then begin
            while UniqueResQry.Read() do begin
                ResNo := UniqueResQry.Resource_No_;
                if GetVendorNoFromDayPlanning(StartDate, EndDate, ResNo) = '' then
                    //if <> '' then it does not create section, because it will meet on below next block of codes with DayPlanning source no. and posibility has a vendor
                    if not TempRes.Get(ResNo) then begin
                        TempRes.Init();
                        TempRes."No." := ResNo;
                        if Res.Get(ResNo) then begin
                            TempRes.Name := Res.Name;
                            TempRes."Vendor No." := Res."Vendor No.";
                        end else begin
                            TempRes.Name := 'Vacant';
                            TempRes."Vendor No." := '';
                        end;
                        TempRes.Insert();
                    end;
            end;
            UniqueResQry.Close();
        end;
        //end;

        DayPlannings.SetRange("Plan Date", StartDate, EndDate);
        DayPlannings.SetRange("Resource Group No.", ResGroupNo);
        DayPlannings.SetRange("Vendor No.", VendorNo);
        if DayPlannings.FindSet() then
            repeat
                ResNo := DayPlannings."Assigned Resource No.";
                if not TempRes.Get(ResNo) then begin
                    TempRes.Init();
                    TempRes."No." := ResNo;
                    if Res.Get(ResNo) then begin
                        TempRes.Name := Res.Name;
                        TempRes."Vendor No." := Res."Vendor No.";
                    end else begin
                        TempRes.Name := 'Vacant';
                        TempRes."Vendor No." := '';
                    end;
                    TempRes.Insert();
                end;
            until DayPlannings.Next() = 0;

    end;

    procedure GetUniqueResFromCapacity(var TempRes: record "Resource" temporary;
                                       var TempVen: record Vendor temporary;
                                       ResGroupNo: Code[20];
                                       StartDate: Date;
                                       EndDate: Date)
    var
        Res: record Resource;
        Vendor: Record Vendor;
        UniqueResQry: Query "Unique Resource in Capacity";
        ResNo: Code[20];
        VenNo: Code[20];
    begin
        // Clear the temporary table
        TempRes.Reset();
        TempRes.DeleteAll();

        TempVen.Reset();
        TempVen.DeleteAll();

        // Open the query - it automatically groups by VendorNo giving unique values
        UniqueResQry.SetRange(EntryDateFilter, StartDate, EndDate);
        UniqueResQry.SetRange(Resource_Group_No_, ResGroupNo);
        if UniqueResQry.Open() then begin
            while UniqueResQry.Read() do begin
                VenNo := '';
                ResNo := UniqueResQry.Resource_No_;
                TempRes.Init();
                TempRes."No." := ResNo;
                if Res.Get(ResNo) then begin
                    TempRes.Name := Res.Name;
                    if res."Vendor No." <> '' then
                        VenNo := res."Vendor No.";
                end;
                TempRes."Vendor No." := VenNo;
                if TempRes.Insert() then;
                if Not TempVen.Get(VenNo) then begin
                    TempVen.Init();
                    TempVen."No." := VenNo;
                    if not Vendor.Get(VenNo) then
                        TempVen.Name := 'Internal'
                    else
                        TempVen.Name := Vendor.Name;
                    TempVen.Insert();
                end;
            end;
            UniqueResQry.Close();
        end;
    end;

    procedure GetUniqueResFromCapacity_Pool(var TempRes: record "Resource" temporary;
                                       ResGroupNo: Code[20];
                                       PoolNo: Code[20];
                                       StartDate: Date;
                                       EndDate: Date)
    var
        Res: record Resource;
        DayPlannings: record "Day Planning";
        UniqueResQry: Query "Unique Resource in Capacity";
        ResNo: Code[20];
    begin
        // Clear the temporary table
        TempRes.Reset();
        TempRes.DeleteAll();

        // Open the query - it automatically groups by Pool Resource giving unique values
        UniqueResQry.SetRange(EntryDateFilter, StartDate, EndDate);
        UniqueResQry.SetRange(Resource_Group_No_, ResGroupNo);
        if UniqueResQry.Open() then begin
            while UniqueResQry.Read() do begin
                ResNo := UniqueResQry.Resource_No_;
                if GetPoolNoFromDayPlanning(StartDate, EndDate, ResNo) = '' then
                    //if <> '' then it does not create section, because it will meet on below next block of codes with DayPlanning source no. and posibility has a vendor
                    if not TempRes.Get(ResNo) then begin
                        TempRes.Init();
                        TempRes."No." := ResNo;
                        if Res.Get(ResNo) then begin
                            TempRes.Name := Res.Name;
                            TempRes."Pool Resource No." := Res."Pool Resource No.";
                        end else begin
                            TempRes.Name := 'Vacant';
                            TempRes."Pool Resource No." := '';
                        end;
                        TempRes.Insert();
                    end;
            end;
            UniqueResQry.Close();
        end;

        DayPlannings.SetRange("Plan Date", StartDate, EndDate);
        DayPlannings.SetRange("Resource Group No.", ResGroupNo);
        DayPlannings.SetRange("Assigned Pool Resource No.", PoolNo);
        if DayPlannings.FindSet() then
            repeat
                ResNo := DayPlannings."Assigned Resource No.";
                if not TempRes.Get(ResNo) then begin
                    TempRes.Init();
                    TempRes."No." := ResNo;
                    if Res.Get(ResNo) then begin
                        TempRes.Name := Res.Name;
                        TempRes."Pool Resource No." := Res."Pool Resource No.";
                    end else begin
                        TempRes.Name := 'Vacant';
                        TempRes."Pool Resource No." := '';
                    end;
                    TempRes.Insert();
                end;
            until DayPlannings.Next() = 0;

    end;

    procedure GetUniqueResFromCapacity_Pool(var TempRes: record "Resource" temporary;
                                       var TempPoolRes: record Resource temporary;
                                       ResGroupNo: Code[20];
                                       StartDate: Date;
                                       EndDate: Date;
                                       ResourceFilter: Text;
                                       ResourceNameFilter: Text;
                                       SkillFilter: Text)
    var
        Res: record Resource;
        ResListQry: Query "Resource List Sections";
        ResNo: Code[20];
        PoolNo: Code[20];
    begin
        // Clear the temporary table
        TempRes.Reset();
        TempRes.DeleteAll();

        TempPoolRes.Reset();
        TempPoolRes.DeleteAll();

        // Two sequential passes over the same query variable - the include decision is now
        // pushed down into the query filters instead of an in-loop OR check.
        // Pass 1: Mandatory Schedulling resources - always shown, unconditional, no date/capacity filter.
        // Pass 2: non-mandatory resources - only shown if they have at least one capacity entry in range.
        // Mandatory Schedulling is mutually exclusive between the two passes, so there's no
        // duplicate-row risk and no need to check TempRes.Get() before deciding to include a row
        // (the defensive TempRes.Insert() guard below still protects against unexpected dupes).

        // Pass 1 - mandatory resources (unconditional)
        ResListQry.SetRange(Resource_Group_No_Filter, ResGroupNo);
        ResListQry.SetRange(MandatoryFilter, true);
        if ResListQry.Open() then begin
            while ResListQry.Read() do begin
                ResNo := ResListQry.No_;
                if ResourceMatchesNoFilter(ResNo, ResourceFilter) and
                   ResourceMatchesNameFilter(ResNo, ResourceNameFilter) and
                   ResourceMatchesSkillFilter(ResNo, SkillFilter)
                then begin
                    PoolNo := '';
                    TempRes.Init();
                    TempRes."No." := ResNo;
                    TempRes.Name := ResListQry.Name;
                    if ResListQry.Pool_Resource_No_ <> '' then
                        PoolNo := ResListQry.Pool_Resource_No_;
                    TempRes."Pool Resource No." := PoolNo;
                    if TempRes.Insert() then;

                    if PoolNo = '' then
                        PoolNo := TempRes."No.";
                    if Not TempPoolRes.Get(PoolNo) then begin
                        TempPoolRes.Init();
                        TempPoolRes."No." := PoolNo;
                        if Res.Get(PoolNo) then begin
                            TempPoolRes.Name := Res.Name;
                            TempPoolRes."Pool Resource No." := Res."Pool Resource No.";
                        end;
                        TempPoolRes.Insert();
                    end;
                end;
            end;
            ResListQry.Close();
        end;

        // Pass 2 - non-mandatory resources, gated on having at least one capacity entry in range
        ResListQry.SetRange(Resource_Group_No_Filter, ResGroupNo);
        ResListQry.SetRange(MandatoryFilter, false);
        ResListQry.SetRange(EntryDateFilter, StartDate, EndDate);
        ResListQry.SetFilter(CapacityEntryCount, '>0');
        if ResListQry.Open() then begin
            while ResListQry.Read() do begin
                ResNo := ResListQry.No_;
                if ResourceMatchesNoFilter(ResNo, ResourceFilter) and
                   ResourceMatchesNameFilter(ResNo, ResourceNameFilter) and
                   ResourceMatchesSkillFilter(ResNo, SkillFilter)
                then begin
                    PoolNo := '';
                    TempRes.Init();
                    TempRes."No." := ResNo;
                    TempRes.Name := ResListQry.Name;
                    if ResListQry.Pool_Resource_No_ <> '' then
                        PoolNo := ResListQry.Pool_Resource_No_;
                    TempRes."Pool Resource No." := PoolNo;
                    if TempRes.Insert() then;

                    if PoolNo = '' then
                        PoolNo := TempRes."No.";
                    if Not TempPoolRes.Get(PoolNo) then begin
                        TempPoolRes.Init();
                        TempPoolRes."No." := PoolNo;
                        if Res.Get(PoolNo) then begin
                            TempPoolRes.Name := Res.Name;
                            TempPoolRes."Pool Resource No." := Res."Pool Resource No.";
                        end;
                        TempPoolRes.Insert();
                    end;
                end;
            end;
            ResListQry.Close();
        end;
    end;

    procedure GetUniqueResGroupFromCapacity(var TempResGroup: record "Resource Group" temporary; WithDayPlanning: Boolean; StartDate: Date; EndDate: Date)
    var
        ResGroup: record "Resource Group";
        UniqueGroupQry: Query "Unique Group in Capacity";
        UniqueDayPlanningResGroupQry: Query "Unique ResGrp in DayPlannings";
        MandatoryRes: Record Resource;
        ResGroupNo: Code[20];

    begin
        // Clear the temporary table
        TempResGroup.Reset();
        TempResGroup.DeleteAll();

        // Open the query - it automatically groups by VendorNo giving unique values
        UniqueGroupQry.SetRange(EntryDateFilter, StartDate, EndDate);
        if UniqueGroupQry.Open() then begin
            while UniqueGroupQry.Read() do begin
                ResGroupNo := UniqueGroupQry.Resource_Group_No_;
                if not TempResGroup.Get(ResGroupNo) then begin
                    TempResGroup.Init();
                    TempResGroup."No." := ResGroupNo;
                    if ResGroup.Get(ResGroupNo) then
                        TempResGroup.Name := ResGroup.Name
                    else
                        TempResGroup.Name := 'No Group';
                    TempResGroup.Insert();
                end;
            end;
            UniqueGroupQry.Close();
        end;

        // "Mandatory Schedulling" resources must always render, even with zero capacity entries
        // in the visible range, so make sure their Resource Group node is included as well - a
        // group made up entirely of otherwise-empty mandatory resources would never appear here
        // (query "Unique Group in Capacity" above only returns groups that have capacity entries).
        MandatoryRes.SetRange("Mandatory Schedulling", true);
        if MandatoryRes.FindSet() then
            repeat
                ResGroupNo := MandatoryRes."Resource Group No.";
                if not TempResGroup.Get(ResGroupNo) then begin
                    TempResGroup.Init();
                    TempResGroup."No." := ResGroupNo;
                    if ResGroup.Get(ResGroupNo) then
                        TempResGroup.Name := ResGroup.Name
                    else
                        TempResGroup.Name := 'No Group';
                    TempResGroup.Insert();
                end;
            until MandatoryRes.Next() = 0;

        if WithDayPlanning then begin
            UniqueDayPlanningResGroupQry.SetRange(TaskDateFilter, StartDate, EndDate);
            if UniqueDayPlanningResGroupQry.Open() then begin
                while UniqueDayPlanningResGroupQry.Read() do begin
                    ResGroupNo := UniqueDayPlanningResGroupQry.Resource_Group_No_;
                    if not TempResGroup.Get(ResGroupNo) then begin
                        TempResGroup.Init();
                        TempResGroup."No." := ResGroupNo;
                        if ResGroup.Get(ResGroupNo) then
                            TempResGroup.Name := ResGroup.Name
                        else
                            TempResGroup.Name := 'No Group';
                        TempResGroup.Insert();
                    end;
                end;
                UniqueDayPlanningResGroupQry.Close();
            end;
        end;
    end;

    procedure GetUniqueVendorsFromDayPlannings(var TempRecord: record "Aging Band Buffer" temporary;
                                           ResGroupNo: Code[20];
                                           StartDate: Date;
                                           EndDate: Date)
    var
        TempRes: record "Resource" temporary;
        TempVen: record Vendor temporary;
        UniqueVendorsQuery: Query "Unique Vend in Day Plannings";
        Vendor: Record Vendor;
        VendorNo: Code[20];
    begin
        // Clear the temporary table
        TempRecord.Reset();
        TempRecord.DeleteAll();

        // Open the query - it automatically groups by VendorNo giving unique values
        UniqueVendorsQuery.SetRange(TaskDateFilter, StartDate, EndDate);
        UniqueVendorsQuery.SetRange(Resource_Group_No_Filter, ResGroupNo);
        if UniqueVendorsQuery.Open() then begin
            while UniqueVendorsQuery.Read() do begin
                VendorNo := UniqueVendorsQuery.VendorNo;
                if VendorNo <> '' then begin
                    // Get vendor details and add to temporary table
                    if Vendor.Get(VendorNo) then begin
                        if not TempRecord.Get(VendorNo) then begin
                            TempRecord.Init();
                            TempRecord."Currency Code" := VendorNo;
                            TempRecord.Insert();
                        end;
                    end;
                end else begin
                    if not TempRecord.Get(VendorNo) then begin
                        TempRecord.Init();
                        TempRecord."Currency Code" := VendorNo;
                        TempRecord.Insert();
                    end;
                end;
            end;
            UniqueVendorsQuery.Close();
        end;

        // find Unique Vendor From Resource Capacity
        GetUniqueResFromCapacity(TempRes,
                                TempVen,
                                ResGroupNo,
                                StartDate,
                                EndDate);
        if TempVen.FindSet() then
            repeat
                VendorNo := TempVen."No.";
                if VendorNo <> '' then begin
                    // Get vendor details and add to temporary table
                    if Vendor.Get(VendorNo) then begin
                        if not TempRecord.Get(VendorNo) then begin
                            TempRecord.Init();
                            TempRecord."Currency Code" := VendorNo;
                            TempRecord.Insert();
                        end;
                    end;
                end else begin
                    if not TempRecord.Get(VendorNo) then begin
                        TempRecord.Init();
                        TempRecord."Currency Code" := VendorNo;
                        TempRecord.Insert();
                    end;
                end;
            until TempVen.Next() = 0;

        if not TempRecord.Get('') then begin
            TempRecord.Init();
            TempRecord."Currency Code" := '';
            TempRecord.Insert();
        end;

    end;

    procedure GetUniquePoolFromDayPlannings(var TempResource: record "Resource" temporary;
                                        var TempPoolRes: record Resource temporary;
                                        ResGroupNo: Code[20];
                                        StartDate: Date;
                                        EndDate: Date)
    var
        DayPlanning: Record "Day Planning";
        DayPlanningCheck: Record "Day Planning";
        Res: record Resource;
        TempRes: record "Resource" temporary;
        TempPool: record Resource temporary;
        ResNo: Code[20];
        PoolNo: Code[20];
        VacantLbl: label '_VACANT_0000';
        VacantNo: Text;
        AllowInsert: boolean;
    begin
        // Clear the temporary table
        TempResource.Reset();
        TempResource.DeleteAll();

        TempPoolRes.Reset();
        TempPoolRes.DeleteAll();

        VacantNo := VacantLbl;

        DayPlanning.SetRange("Plan Date", StartDate, EndDate);
        DayPlanning.SetRange("Resource Group No.", ResGroupNo);
        if DayPlanning.FindSet() then
            repeat
                PoolNo := '';
                ResNo := DayPlanning."Assigned Resource No.";
                //if not TempResource.Get(ResNo) then begin
                if not Res.Get(ResNo) then
                    Clear(Res);
                if (ResNo <> '') and (Res."Pool Resource No." <> '') then begin
                    if not TempResource.Get(ResNo) then begin
                        TempResource.Init();
                        TempResource."No." := ResNo;
                        TempResource.Name := Res.Name;
                        PoolNo := Res."Pool Resource No.";
                        TempResource."Pool Resource No." := PoolNo;
                        TempResource.Insert();
                    end;
                end else begin
                    if (ResNo = '') and (DayPlanning."Assigned Pool Resource No." <> '') then begin
                        VacantNo := IncStr(VacantNo);
                        TempResource.Reset();
                        TempResource.Setfilter("No.", '*VACANT*');
                        TempResource.SetRange("Pool Resource No.", DayPlanning."Assigned Pool Resource No.");
                        if not TempResource.FindSet() then begin
                            TempResource.Init();
                            TempResource."No." := VacantNo;
                            TempResource.Name := 'Vacant';
                            TempResource."Pool Resource No." := DayPlanning."Assigned Pool Resource No.";
                            TempResource.Insert();
                        end;
                        TempResource.Reset();
                    end;
                end; //>>2026.02.10

                // Create Parent
                if PoolNo = '' then
                    PoolNo := ResNo; //TempRes."No.";
                if Not TempPoolRes.Get(PoolNo) then begin
                    //<<2026.02.10
                    AllowInsert := true;
                    if PoolNo = '' then begin
                        DayPlanningCheck.SetRange("Plan Date", StartDate, EndDate);
                        DayPlanningCheck.SetRange("Resource Group No.", ResGroupNo);
                        DayPlanningCheck.SetRange("Assigned Resource No.", '');
                        DayPlanningCheck.Setrange("Assigned Pool Resource No.", '');
                        AllowInsert := DayPlanningCheck.FindFirst();
                    end;
                    //>>
                    if AllowInsert then begin
                        TempPoolRes.Init();
                        TempPoolRes."No." := PoolNo;
                        if Res.Get(PoolNo) then begin
                            TempPoolRes.Name := Res.Name;
                            TempPoolRes."Pool Resource No." := Res."Pool Resource No.";
                        end else
                            TempPoolRes.Name := 'Vacant';
                        TempPoolRes.Insert();
                    end;
                end;
            //end;
            until DayPlanning.Next() = 0;



        // // Open the query - it automatically groups by VendorNo giving unique values
        // UniquePoolQuery.SetRange(TaskDateFilter, StartDate, EndDate);
        // UniquePoolQuery.SetRange(Resource_Group_No_Filter, ResGroupNo);
        // if UniquePoolQuery.Open() then begin
        //     while UniquePoolQuery.Read() do begin
        //         PoolNo := UniquePoolQuery.PoolResNo;
        //         if PoolNo <> '' then begin
        //             // Get vendor details and add to temporary table
        //             if PoolRes.Get(PoolNo) then begin
        //                 if not TempRecord.Get(PoolNo) then begin
        //                     TempRecord.Init();
        //                     TempRecord."Currency Code" := PoolNo;
        //                     TempRecord.Insert();
        //                 end;
        //             end;
        //         end else begin
        //             if not TempRecord.Get(PoolNo) then begin
        //                 TempRecord.Init();
        //                 TempRecord."Currency Code" := PoolNo;
        //                 TempRecord.Insert();
        //             end;
        //         end;
        //     end;
        //     UniquePoolQuery.Close();
        // end;

        // find Unique Pool From Resource Capacity
        // Note: this whole GetUniquePoolFromDayPlannings procedure is currently dead code -
        // its only caller (the WithDayPlanning branch in GetYUnitElementsJSON_Pool) is
        // commented out - so '' (no resource filter) is passed through unconditionally here.
        GetUniqueResFromCapacity_Pool(TempRes,
                                TempPool,
                                ResGroupNo,
                                StartDate,
                                EndDate,
                                '',
                                '',
                                '');
        if TempPool.FindSet() then
            repeat
                if Not TempPoolRes.Get(TempPool."No.") then begin
                    TempPoolRes.Init();
                    TempPoolRes."No." := TempPool."No.";
                    if Res.Get(TempPool."No.") then begin
                        TempPoolRes.Name := Res.Name;
                        TempPoolRes."Pool Resource No." := Res."Pool Resource No.";
                    end else
                        TempPoolRes.Name := 'Vacant';
                    TempPoolRes.Insert();
                end;

                TempRes.SetRange("Pool Resource No.", TempPool."No.");
                if TempRes.FindSet() then
                    repeat
                        if Not TempResource.Get(TempRes."No.") then begin
                            TempResource.Init();
                            TempResource."No." := TempRes."No.";
                            if Res.Get(TempRes."No.") then begin
                                TempResource.Name := Res.Name;
                                TempResource."Pool Resource No." := Res."Pool Resource No.";
                            end;
                            TempResource.Insert();
                        end;
                    until TempRes.Next() = 0;

            until TempPool.Next() = 0;

        // if not TempRecord.Get('') then begin
        //     TempRecord.Init();
        //     TempRecord."Currency Code" := '';
        //     TempRecord.Insert();
        // end;

    end;

    // =========================================================
    // Resource Scheduler – JSON builder procedures
    // Moved from DHX Resource Scheduler page for generic reuse.
    // =========================================================

    procedure ResScheduler_BuildResourcesJson(ResourceFilter: Text; ResourceNameFilter: Text; SkillFilter: Text): Text
    var
        Res: Record Resource;
        JArray: JsonArray;
        JObj: JsonObject;
        JRoot: JsonObject;
        Result: Text;
    begin
        Res.Reset();
        if ResourceFilter <> '' then
            Res.SetFilter("No.", ResourceFilter)
        else
            Res.SetFilter("No.", '<>%1', '');
        if ResourceNameFilter <> '' then
            Res.SetFilter(Name, ResourceNameFilter);
        if Res.FindSet() then
            repeat
                if ResourceMatchesSkillFilter(Res."No.", SkillFilter) then begin
                    Clear(JObj);
                    JObj.Add('id', Res."No.");
                    JObj.Add('name', Res.Name);
                    JObj.Add('group', Res."Resource Group No.");
                    JArray.Add(JObj);
                end;
            until Res.Next() = 0;
        Clear(JRoot);
        JRoot.Add('data', JArray);
        JRoot.WriteTo(Result);
        exit(Result);
    end;

    procedure ResScheduler_BuildEventsJson(ResourceFilter: Text): Text
    var
        DayPlanning: Record "Day Planning";
        StarDateTimeStr: Text;
        EndDateTimeStr: Text;
        ReqStartDateTimeStr: Text;
        ReqEndDateTimeStr: Text;
        JArray: JsonArray;
        JRoot: JsonObject;
        Result: Text;
        eventColor: Text;
    begin
        DayPlanning.Reset();
        if ResourceFilter <> '' then
            DayPlanning.SetFilter("Assigned Resource No.", ResourceFilter)
        else
            DayPlanning.SetFilter("Assigned Resource No.", '<>%1', '');
        if DayPlanning.FindSet() then
            repeat
                GetStartEndTxt(DayPlanning, StarDateTimeStr, EndDateTimeStr);
                if (StarDateTimeStr <> '') and (EndDateTimeStr <> '') then begin
                    eventColor := ResScheduler_GetResourceColor(DayPlanning."Assigned Resource No.", 'DayPlanning');
                    GetReqStartEndTxt(DayPlanning, ReqStartDateTimeStr, ReqEndDateTimeStr);
                    ResScheduler_AddEvent(
                        JArray,
                        Format(DayPlanning.RecordId),
                        DayPlanning."Assigned Resource No.",
                        eventColor,
                        StarDateTimeStr,
                        EndDateTimeStr,
                        DayPlanning.Description,
                        'DayPlanning',
                        ReqStartDateTimeStr,
                        ReqEndDateTimeStr);
                end;
            until DayPlanning.Next() = 0;
        Clear(JRoot);
        JRoot.Add('data', JArray);
        JRoot.WriteTo(Result);
        exit(Result);
    end;

    procedure ResScheduler_AddEvent(var JArray: JsonArray; RecordId: Text; ResourceId: Text; Classname: Text; StartDate: Text; EndDate: Text; EventText: Text; pType: Text; ReqStartDate: Text; ReqEndDate: Text)
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
        JObj.Add('type', pType);
        if ReqStartDate <> '' then
            JObj.Add('req_start', ReqStartDate);
        if ReqEndDate <> '' then
            JObj.Add('req_end', ReqEndDate);
        JArray.Add(JObj);
    end;

    local procedure GetReqStartEndTxt(DayPlanning: Record "Day Planning"; var ReqStartDateTxt: Text; var ReqEndDateTxt: Text)
    begin
        ReqStartDateTxt := '';
        ReqEndDateTxt := '';
        if DayPlanning."Plan Date" = 0D then
            exit;
        if DayPlanning."Start Time Requested" <> 0T then
            ReqStartDateTxt := ToSessionDateTimeTxt(DayPlanning."Plan Date", DayPlanning."Start Time Requested");
        if DayPlanning."End Time Requested" <> 0T then
            ReqEndDateTxt := ToSessionDateTimeTxt(DayPlanning."Plan Date", DayPlanning."End Time Requested");
    end;

    procedure ResScheduler_BuildCapacityJson(ResourceFilter: Text): Text
    var
        ResCap: Record "Res. Capacity Entry";
        TempResCap: Record "Res. Capacity Entry" temporary;
        WeekMonday: Date;
        WeekFriday: Date;
        DayOfWeek: Integer;
        JArray: JsonArray;
        JObj: JsonObject;
        JRoot: JsonObject;
        Result: Text;
        StartDateTimeStr: Text;
        EndDateTimeStr: Text;
        LastResNo: Code[20];
        LastDate: Date;
        AggStartTime: Time;
        AggCapacity: Decimal;
    begin
        DayOfWeek := Date2DWY(Today(), 1);
        WeekMonday := Today() - (DayOfWeek - 1);
        WeekFriday := CalcDate('<+4D>', WeekMonday);

        ResCap.Reset();
        ResCap.SetCurrentKey("Resource No.", "Date");
        ResCap.SetRange("Date", WeekMonday, WeekFriday);
        if ResourceFilter <> '' then
            ResCap.SetFilter("Resource No.", ResourceFilter)
        else
            ResCap.SetFilter("Resource No.", '<>%1', '');

        LastResNo := '';
        LastDate := 0D;
        AggStartTime := 0T;
        AggCapacity := 0;

        if ResCap.FindSet() then
            repeat
                if (ResCap."Resource No." <> LastResNo) or (ResCap."Date" <> LastDate) then begin
                    // Emit previous accumulated group
                    if (LastResNo <> '') and (AggCapacity > 0) then begin
                        TempResCap.Init();
                        TempResCap."Resource No." := LastResNo;
                        TempResCap."Date" := LastDate;
                        TempResCap."Start Time" := AggStartTime;
                        GetStartEndTxt(TempResCap, AggCapacity, StartDateTimeStr, EndDateTimeStr);
                        if (StartDateTimeStr <> '') and (EndDateTimeStr <> '') then begin
                            Clear(JObj);
                            JObj.Add('resource_id', LastResNo);
                            JObj.Add('start_date', StartDateTimeStr);
                            JObj.Add('end_date', EndDateTimeStr);
                            JObj.Add('classname', ResScheduler_GetResourceColor(LastResNo, 'capacity'));
                            JObj.Add('type', 'capacity');
                            JArray.Add(JObj);
                        end;
                    end;
                    // Start new group
                    LastResNo := ResCap."Resource No.";
                    LastDate := ResCap."Date";
                    AggStartTime := ResCap."Start Time";
                    AggCapacity := ResCap.Capacity;
                end else begin
                    // Same resource+date: accumulate capacity hours, keep earliest start time
                    AggCapacity += ResCap.Capacity;
                    if (ResCap."Start Time" <> 0T) then
                        if (AggStartTime = 0T) or (ResCap."Start Time" < AggStartTime) then
                            AggStartTime := ResCap."Start Time";
                end;
            until ResCap.Next() = 0;

        // Flush the last group
        if (LastResNo <> '') and (AggCapacity > 0) then begin
            TempResCap.Init();
            TempResCap."Resource No." := LastResNo;
            TempResCap."Date" := LastDate;
            TempResCap."Start Time" := AggStartTime;
            GetStartEndTxt(TempResCap, AggCapacity, StartDateTimeStr, EndDateTimeStr);
            if (StartDateTimeStr <> '') and (EndDateTimeStr <> '') then begin
                Clear(JObj);
                JObj.Add('resource_id', LastResNo);
                JObj.Add('start_date', StartDateTimeStr);
                JObj.Add('end_date', EndDateTimeStr);
                JObj.Add('classname', ResScheduler_GetResourceColor(LastResNo, 'capacity'));
                JObj.Add('type', 'capacity');
                JArray.Add(JObj);
            end;
        end;

        Clear(JRoot);
        JRoot.Add('data', JArray);
        JRoot.WriteTo(Result);
        exit(Result);
    end;

    // Tests whether the resource identified by pResourceNo matches an (optional) Name
    // filter. Used wherever a resource-name filter needs to be applied against a table
    // that only holds the resource's No. (e.g. Day Planning, Res. Capacity Entry) rather
    // than a Record Resource being enumerated directly. Blank filter always matches.
    local procedure ResourceMatchesNameFilter(pResourceNo: Code[20]; ResourceNameFilter: Text): Boolean
    var
        Res: Record Resource;
    begin
        if ResourceNameFilter = '' then
            exit(true);
        Res.SetRange("No.", pResourceNo);
        Res.SetFilter(Name, ResourceNameFilter);
        exit(not Res.IsEmpty());
    end;

    // Standard-filter match on Resource No. (wildcards/ranges/OR-lists/exclusions), not an
    // exact-equality check — a user-entered filter like "DRM*" or "A..M" must work the same
    // way here as it does on the Name side (ResourceMatchesNameFilter above).
    local procedure ResourceMatchesNoFilter(pResourceNo: Code[20]; ResourceFilter: Text): Boolean
    var
        Res: Record Resource;
    begin
        if ResourceFilter = '' then
            exit(true);
        Res.SetRange("No.", pResourceNo);
        Res.SetFilter("No.", ResourceFilter);
        exit(not Res.IsEmpty());
    end;

    // Standard-filter match on the resource's assigned Skill Code(s), via table "Resource
    // Skill" (Type = Resource, "No." = the resource, "Skill Code" = the skill). A resource
    // can have multiple skill assignments, so this checks for existence of at least one
    // matching row rather than equality on a single field. Blank filter always matches,
    // same not-blank convention as ResourceMatchesNoFilter/ResourceMatchesNameFilter above.
    local procedure ResourceMatchesSkillFilter(pResourceNo: Code[20]; SkillFilter: Text): Boolean
    var
        ResourceSkill: Record "Resource Skill";
    begin
        if SkillFilter = '' then
            exit(true);
        ResourceSkill.SetRange(Type, ResourceSkill.Type::Resource);
        ResourceSkill.SetRange("No.", pResourceNo);
        ResourceSkill.SetFilter("Skill Code", SkillFilter);
        exit(not ResourceSkill.IsEmpty());
    end;

    procedure ResScheduler_GetResourceColor(pResourceNo: Code[20]; pColorType: Text): Text
    var
        ResColor: Record "Planning Color Opt.";
        FallbackColors: array[4] of Text;
        ColorHash: Integer;
        i: Integer;
        ColorValue: Text;
    begin
        FallbackColors[1] := 'blue';
        FallbackColors[2] := 'green';
        FallbackColors[3] := 'violet';
        FallbackColors[4] := 'yellow';
        if ResColor.Get(ResColor.Type::"Resource Scheduler", pResourceNo, '', '') then begin
            case pColorType of
                'DayPlanning':
                    ColorValue := ResColor."Day Planning";
                'capacity':
                    ColorValue := ResColor."Capacity";
            end;
            if ColorValue <> '' then
                exit(ColorValue);
        end;
        ColorHash := 0;
        for i := 1 to StrLen(pResourceNo) do
            ColorHash += pResourceNo[i];
        exit(FallbackColors[(ColorHash mod 4) + 1]);
    end;

    // =========================================================
    // Date-range overloads – load only data for the visible period.
    // Called when the scheduler view changes (Today/Prev/Next/
    // Day/Week/Month buttons).
    // =========================================================

    procedure ResScheduler_BuildEventsJson(ResourceFilter: Text; StartDate: Date; EndDate: Date; ResourceNameFilter: Text; SkillFilter: Text): Text
    var
        DayPlanning: Record "Day Planning";
        StarDateTimeStr: Text;
        EndDateTimeStr: Text;
        ReqStartDateTimeStr: Text;
        ReqEndDateTimeStr: Text;
        JArray: JsonArray;
        JRoot: JsonObject;
        Result: Text;
        eventColor: Text;
    begin
        DayPlanning.Reset();
        if (StartDate <> 0D) and (EndDate <> 0D) then
            DayPlanning.SetRange("Plan Date", StartDate, EndDate);
        if ResourceFilter <> '' then
            DayPlanning.SetFilter("Assigned Resource No.", ResourceFilter)
        else
            DayPlanning.SetFilter("Assigned Resource No.", '<>%1', '');
        if DayPlanning.FindSet() then
            repeat
                if ResourceMatchesNameFilter(DayPlanning."Assigned Resource No.", ResourceNameFilter) and
                   ResourceMatchesSkillFilter(DayPlanning."Assigned Resource No.", SkillFilter)
                then begin
                    GetStartEndTxt(DayPlanning, StarDateTimeStr, EndDateTimeStr);
                    if (StarDateTimeStr <> '') and (EndDateTimeStr <> '') then begin
                        eventColor := ResScheduler_GetResourceColor(DayPlanning."Assigned Resource No.", 'DayPlanning');
                        GetReqStartEndTxt(DayPlanning, ReqStartDateTimeStr, ReqEndDateTimeStr);
                        ResScheduler_AddEvent(
                            JArray,
                            Format(DayPlanning.RecordId),
                            DayPlanning."Assigned Resource No.",
                            eventColor,
                            StarDateTimeStr,
                            EndDateTimeStr,
                            DayPlanning.Description,
                            'DayPlanning',
                            ReqStartDateTimeStr,
                            ReqEndDateTimeStr);
                    end;
                end;
            until DayPlanning.Next() = 0;
        Clear(JRoot);
        JRoot.Add('data', JArray);
        JRoot.WriteTo(Result);
        exit(Result);
    end;

    procedure ResScheduler_BuildCapacityJson(ResourceFilter: Text; StartDate: Date; EndDate: Date; ResourceNameFilter: Text; SkillFilter: Text): Text
    var
        ResCap: Record "Res. Capacity Entry";
        TempResCap: Record "Res. Capacity Entry" temporary;
        JArray: JsonArray;
        JObj: JsonObject;
        JRoot: JsonObject;
        Result: Text;
        StartDateTimeStr: Text;
        EndDateTimeStr: Text;
        LastResNo: Code[20];
        LastDate: Date;
        AggStartTime: Time;
        AggCapacity: Decimal;
    begin
        ResCap.Reset();
        ResCap.SetCurrentKey("Resource No.", "Date");
        if (StartDate <> 0D) and (EndDate <> 0D) then
            ResCap.SetRange("Date", StartDate, EndDate);
        if ResourceFilter <> '' then
            ResCap.SetFilter("Resource No.", ResourceFilter)
        else
            ResCap.SetFilter("Resource No.", '<>%1', '');

        LastResNo := '';
        LastDate := 0D;
        AggStartTime := 0T;
        AggCapacity := 0;

        if ResCap.FindSet() then
            repeat
                // Rows for a resource that fails the Name/Skill filter are skipped entirely, as
                // if they were never returned by the recordset — this keeps the group-by-Resource
                // No./Date accumulation below correct without needing those fields on the table.
                if ResourceMatchesNameFilter(ResCap."Resource No.", ResourceNameFilter) and
                   ResourceMatchesSkillFilter(ResCap."Resource No.", SkillFilter)
                then
                    if (ResCap."Resource No." <> LastResNo) or (ResCap."Date" <> LastDate) then begin
                        if (LastResNo <> '') and (AggCapacity > 0) then begin
                            TempResCap.Init();
                            TempResCap."Resource No." := LastResNo;
                            TempResCap."Date" := LastDate;
                            TempResCap."Start Time" := AggStartTime;
                            GetStartEndTxt(TempResCap, AggCapacity, StartDateTimeStr, EndDateTimeStr);
                            if (StartDateTimeStr <> '') and (EndDateTimeStr <> '') then begin
                                Clear(JObj);
                                JObj.Add('resource_id', LastResNo);
                                JObj.Add('start_date', StartDateTimeStr);
                                JObj.Add('end_date', EndDateTimeStr);
                                JObj.Add('classname', ResScheduler_GetResourceColor(LastResNo, 'capacity'));
                                JObj.Add('type', 'capacity');
                                JArray.Add(JObj);
                            end;
                        end;
                        LastResNo := ResCap."Resource No.";
                        LastDate := ResCap."Date";
                        AggStartTime := ResCap."Start Time";
                        AggCapacity := ResCap.Capacity;
                    end else begin
                        AggCapacity += ResCap.Capacity;
                        if (ResCap."Start Time" <> 0T) then
                            if (AggStartTime = 0T) or (ResCap."Start Time" < AggStartTime) then
                                AggStartTime := ResCap."Start Time";
                    end;
            until ResCap.Next() = 0;

        if (LastResNo <> '') and (AggCapacity > 0) then begin
            TempResCap.Init();
            TempResCap."Resource No." := LastResNo;
            TempResCap."Date" := LastDate;
            TempResCap."Start Time" := AggStartTime;
            GetStartEndTxt(TempResCap, AggCapacity, StartDateTimeStr, EndDateTimeStr);
            if (StartDateTimeStr <> '') and (EndDateTimeStr <> '') then begin
                Clear(JObj);
                JObj.Add('resource_id', LastResNo);
                JObj.Add('start_date', StartDateTimeStr);
                JObj.Add('end_date', EndDateTimeStr);
                JObj.Add('classname', ResScheduler_GetResourceColor(LastResNo, 'capacity'));
                JObj.Add('type', 'capacity');
                JArray.Add(JObj);
            end;
        end;

        Clear(JRoot);
        JRoot.Add('data', JArray);
        JRoot.WriteTo(Result);
        exit(Result);
    end;

    procedure OpenJobTaskCard(sectionId: Text)
    var
        JobTask: Record "Job Task";
        EventIdParts: List of [Text];
        JobNo: Code[20];
        TaskNo: Code[20];
    begin
        EventIdParts := sectionId.Split('|');
        JobNo := EventIdParts.Get(1);
        TaskNo := EventIdParts.Get(2);
        JobTask.Get(JobNo, TaskNo);
        PAGE.Run(PAGE::"Opti Job Task Card", JobTask);
    end;

    /// <summary>
    /// Opens the Opti Job Task Card from an event ID (format: JobNo|TaskNo|...).
    /// Used by the right-click context menu "Open Task" on an event.
    /// </summary>
    procedure OpenJobTaskCardFromEventId(eventId: Text)
    var
        JobTask: Record "Job Task";
        Parts: List of [Text];
        JobNo: Code[20];
        TaskNo: Code[20];
    begin
        Parts := eventId.Split('|');
        if Parts.Count < 2 then
            exit;
        JobNo := Parts.Get(1);
        TaskNo := Parts.Get(2);
        if JobTask.Get(JobNo, TaskNo) then
            PAGE.Run(PAGE::"Opti Job Task Card", JobTask)
        else
            Message('Job Task not found for event ID: %1', eventId);
    end;

    /// <summary>
    /// Opens DHX Scheduler (Project) filtered to the job task linked to the event.
    /// Used by the right-click context menu "Open Day Planning Visual".
    /// </summary>
    procedure OpenDayPlanningVisual(eventId: Text)
    var
        DayPlanningScheduler: Page "DHX Scheduler (Project)";
        Parts: List of [Text];
        JobNo: Code[20];
        TaskNo: Code[20];
    begin
        Parts := eventId.Split('|');
        if Parts.Count < 2 then
            exit;
        JobNo := Parts.Get(1);
        TaskNo := Parts.Get(2);
        DayPlanningScheduler.SetJobTaskFilter(JobNo, TaskNo);
        DayPlanningScheduler.RunModal();
    end;

    /// <summary>
    /// Opens the Resource Day Plannings page filtered to resources assigned to the
    /// job task linked to the given event ID.
    /// Used by the right-click context menu "Show Job Resources".
    /// </summary>
    procedure ShowJobResourcesForEvent(eventId: Text)
    var
        DayPlanning: Record "Day Planning";
        Parts: List of [Text];
        JobNo: Code[20];
        TaskNo: Code[20];
        TaskDay: Date;
        DayLineNo: Integer;
    begin
        Parts := eventId.Split('|');
        if Parts.Count < 4 then
            exit;
        JobNo := Parts.Get(1);
        TaskNo := Parts.Get(2);
        Evaluate(TaskDay, Parts.Get(3));
        Evaluate(DayLineNo, Parts.Get(4));
        DayPlanning.SetRange("Job No.", JobNo);
        DayPlanning.SetRange("Job Task No.", TaskNo);
        DayPlanning.SetRange("Plan Date", TaskDay);
        PAGE.Run(PAGE::"Resource Day Plannings", DayPlanning);
    end;

    // =========================================================
    // Resource Scheduler (New) – "resourceschedule_with_capacity" add-in
    // (page 50706 "DHX Scheduler (Resource+Capacity)"). JSON builder
    // procedures for the Skill > Resource tree and the combined
    // Capacity + Day Planning (Requested/Assigned) events. Kept in its
    // own region, prefixed "SkillResScheduler_", separate from the
    // Pool ("GetYUnitElementsJSON_Pool"/...) and Project-specific
    // procedures elsewhere in this codeunit - same "generic reuse in
    // this shared data handler" convention already established by the
    // "ResScheduler_" region above (moved here from the DHX Resource
    // Scheduler page).
    // =========================================================

    /// <summary>
    /// True when ResNo should be excluded from the Skill/Resource tree - either a blank-name
    /// placeholder resource, or a resource referenced as a Skill Code's "Invoice Resource No."
    /// (a stand-in for the skill itself on invoice preparation, not a real worker - see
    /// tableextension 50609 "Opt. Skill Code").
    /// </summary>
    local procedure SkillResScheduler_IsPlaceholderResource(ResNo: Code[20]; var Res: Record Resource): Boolean
    var
        SkillCode: Record "Skill Code";
    begin
        if not Res.Get(ResNo) then
            exit(true);
        if Res.Name = '' then
            exit(true);
        SkillCode.SetRange("Invoice Resource No.", ResNo);
        exit(not SkillCode.IsEmpty());
    end;

    /// <summary>
    /// The Skill Code a resource is grouped under in the tree - the first (lowest Skill Code)
    /// "Resource Skill" row for that resource. Returns '' when the resource has no skill
    /// assigned at all (bucketed under the "No Skill Assigned" node by the caller).
    /// </summary>
    local procedure SkillResScheduler_GetPrimarySkill(ResNo: Code[20]): Code[20]
    var
        ResourceSkill: Record "Resource Skill";
    begin
        ResourceSkill.SetRange(Type, ResourceSkill.Type::Resource);
        ResourceSkill.SetRange("No.", ResNo);
        if ResourceSkill.FindFirst() then
            exit(ResourceSkill."Skill Code");
        exit('');
    end;

    /// <summary>
    /// Records one (ResNo, SkillVal) pair into all three combined-lookup structures at once -
    /// shared by every source SkillResScheduler_BuildCombinedSkillLookup feeds from ("Resource
    /// Skill" registrations, the Assigned-side query, the Requested-side AL loop), so the
    /// add/dedupe logic (ContainsKey guards, List.Contains dedupe before adding) exists exactly
    /// once instead of once per source.
    /// </summary>
    local procedure SkillResScheduler_AddCombinedSkillPair(ResNo: Code[20]; SkillVal: Code[20]; var CombinedSkills: Dictionary of [Text, Boolean]; var ResourceHasAny: Dictionary of [Code[20], Boolean]; var ResourceSkillsMap: Dictionary of [Code[20], List of [Code[20]]])
    var
        CompositeKey: Text;
        SkillListForRes: List of [Code[20]];
    begin
        CompositeKey := ResNo + '|' + SkillVal;
        if not CombinedSkills.ContainsKey(CompositeKey) then
            CombinedSkills.Add(CompositeKey, true);
        if not ResourceHasAny.ContainsKey(ResNo) then
            ResourceHasAny.Add(ResNo, true);
        if ResourceSkillsMap.ContainsKey(ResNo) then
            SkillListForRes := ResourceSkillsMap.Get(ResNo)
        else
            Clear(SkillListForRes);
        if not SkillListForRes.Contains(SkillVal) then
            SkillListForRes.Add(SkillVal);
        ResourceSkillsMap.Set(ResNo, SkillListForRes);
    end;

    /// <summary>
    /// Builds the combined tree-membership lookup shared by SkillResScheduler_BuildTreeJson and
    /// SkillResScheduler_BuildCapacityJson: a resource belongs on a Skill branch if EITHER it has
    /// a "Resource Skill" master-data registration for that skill, OR a Day Planning row actually
    /// exists tagging that resource with that skill. The Day-Planning side is sourced from TWO
    /// fully independent, structurally identical plain AL loops over "Day Planning" - unlike
    /// RowResourceNo's "Assigned if set, else Requested" resolution used elsewhere in this codeunit
    /// (e.g. SkillResScheduler_BuildDayPlanningJson, for bar placement), tree membership is NOT
    /// mutually exclusive between the two: Source 2 contributes an (Assigned Resource No., Skill)
    /// pair for every row with an Assigned Resource, and Source 3 contributes a (Requested Resource
    /// No., Skill) pair for every row with a Requested Resource - independently of whether that
    /// same row also has an Assigned Resource. A row with both set to two different resources (a
    /// confirmed real scenario) therefore grows a skill branch for each resource. The two sources
    /// naturally overlap when Assigned = Requested on the same row (both contribute the same pair)
    /// - harmless, since SkillResScheduler_AddCombinedSkillPair dedupes via ContainsKey/
    /// List.Contains checks. Blank-skill Day Planning rows are excluded from both sources via each
    /// loop's own SetFilter below, so they can't manufacture a spurious tree branch; that case is
    /// handled separately via the "No Skill Assigned" bucket (ResourceHasAny).
    ///
    /// CombinedSkills is keyed by composite "<Resource No.>|<Skill Code>" (mirrors the tree's leaf
    /// key format) for O(1) single-pair membership tests. ResourceHasAny is keyed by plain
    /// Resource No. and answers "does this resource have ANY skill entry at all" - used to decide
    /// "No Skill Assigned" bucket membership without re-deriving it from CombinedSkills.
    /// ResourceSkillsMap is keyed by plain Resource No. and holds each resource's distinct
    /// combined skill list (needed by SkillResScheduler_BuildCapacityJson/EmitCapacityEvents to
    /// enumerate which skill branches to duplicate a Capacity bar onto - a Dictionary keyed by
    /// composite text like CombinedSkills can't be enumerated by "all skills for one resource").
    ///
    /// RegisteredSkills is keyed by the same composite "<Resource No.>|<Skill Code>" format as
    /// CombinedSkills, but only ever populated from Source 1 ("Resource Skill" master-data
    /// registrations) - never from Sources 2/3 (Day-Planning-observed pairs). It lets a caller
    /// distinguish, for a given (resource, skill) pair that IS in CombinedSkills, whether that
    /// membership is backed by an actual registration or exists purely because of Day Planning
    /// data (used by SkillResScheduler_BuildTreeJson to flag the latter case with a " (*)" label
    /// suffix).
    ///
    /// Deliberately not cached across calls (rebuilt fresh every time it's called) - this
    /// codeunit doesn't hold cross-call state anywhere else and this migration shouldn't
    /// introduce that; each caller builds its own copy.
    ///
    /// StartDate/EndDate scope Sources 2 and 3 (the Day-Planning-derived sources) to the caller's
    /// displayed week, same "Plan Date" range convention as SkillResScheduler_BuildDayPlanningJson/
    /// SkillResScheduler_BuildCapacityJson - both a performance win (Day Planning can be a large
    /// table; scanning the whole thing on every tree rebuild is wasteful) and a correctness fix
    /// (tree membership naturally stays in sync with whatever week is on screen, since the tree is
    /// rebuilt on every Prev/Next/Today/Refresh/filter-change). Source 1 (Resource Skill master
    /// data) is NEVER date-filtered - it has no date of its own and always reflects current
    /// registrations regardless of which week is displayed.
    /// </summary>
    local procedure SkillResScheduler_BuildCombinedSkillLookup(var CombinedSkills: Dictionary of [Text, Boolean]; var ResourceHasAny: Dictionary of [Code[20], Boolean]; var ResourceSkillsMap: Dictionary of [Code[20], List of [Code[20]]]; var RegisteredSkills: Dictionary of [Text, Boolean]; StartDate: Date; EndDate: Date)
    var
        ResourceSkill: Record "Resource Skill";
        AssignedDP: Record "Day Planning";
        RequestedDP: Record "Day Planning";
    begin
        Clear(CombinedSkills);
        Clear(ResourceHasAny);
        Clear(ResourceSkillsMap);
        Clear(RegisteredSkills);

        // Source 1: "Resource Skill" master-data registrations - never date-filtered (see header comment).
        ResourceSkill.SetRange(Type, ResourceSkill.Type::Resource);
        if ResourceSkill.FindSet() then
            repeat
                SkillResScheduler_AddCombinedSkillPair(ResourceSkill."No.", ResourceSkill."Skill Code", CombinedSkills, ResourceHasAny, ResourceSkillsMap);
                if not RegisteredSkills.ContainsKey(ResourceSkill."No." + '|' + ResourceSkill."Skill Code") then
                    RegisteredSkills.Add(ResourceSkill."No." + '|' + ResourceSkill."Skill Code", true);
            until ResourceSkill.Next() = 0;

        // Source 2: Day Planning rows with an Assigned Resource - independent of Source 3 (see this
        // procedure's header comment), same shape as Source 3 just filtered on the other resource field.
        // Scoped to the caller's displayed week (see header comment).
        AssignedDP.Reset();
        if (StartDate <> 0D) and (EndDate <> 0D) then
            AssignedDP.SetRange("Plan Date", StartDate, EndDate);
        AssignedDP.SetFilter("Assigned Resource No.", '<>%1', '');
        AssignedDP.SetFilter(Skill, '<>%1', '');
        if AssignedDP.FindSet() then
            repeat
                SkillResScheduler_AddCombinedSkillPair(AssignedDP."Assigned Resource No.", AssignedDP.Skill, CombinedSkills, ResourceHasAny, ResourceSkillsMap);
            until AssignedDP.Next() = 0;

        // Source 3: Day Planning rows with a Requested Resource - independent of Source 2, so a
        // row that has BOTH an Assigned and a (different) Requested Resource contributes a skill
        // pair for each (see this procedure's header comment). Scoped to the caller's displayed
        // week (see header comment).
        RequestedDP.Reset();
        if (StartDate <> 0D) and (EndDate <> 0D) then
            RequestedDP.SetRange("Plan Date", StartDate, EndDate);
        RequestedDP.SetFilter("Requested Resource No.", '<>%1', '');
        RequestedDP.SetFilter(Skill, '<>%1', '');
        if RequestedDP.FindSet() then
            repeat
                SkillResScheduler_AddCombinedSkillPair(RequestedDP."Requested Resource No.", RequestedDP.Skill, CombinedSkills, ResourceHasAny, ResourceSkillsMap);
            until RequestedDP.Next() = 0;
    end;

    /// <summary>
    /// Extracts the plain Resource "No." from a composite tree/section key ("<No.>|<SkillCode>"
    /// or "<No.>|~NOSKILL~"). Falls back to returning the input unchanged if it isn't composite,
    /// so callers stay safe against any legacy plain-key value. Callers must still guard against
    /// "SKILL|..." folder-node keys themselves before calling this.
    /// </summary>
    procedure SkillResScheduler_ExtractResourceNo(SectionId: Text): Code[20]
    var
        Parts: List of [Text];
        ResNo: Code[20];
    begin
        Parts := SectionId.Split('|');
        if Parts.Count() >= 1 then
            ResNo := CopyStr(Parts.Get(1), 1, MaxStrLen(ResNo))
        else
            ResNo := CopyStr(SectionId, 1, MaxStrLen(ResNo));
        exit(ResNo);
    end;

    /// <summary>
    /// Builds the left-panel tree: one top-level node per Skill Code, with the resources
    /// registered for that skill as leaf children - a resource registered for multiple skills
    /// appears once per skill branch. Resources with no skill assigned are grouped under a
    /// trailing "No Skill Assigned" node - omitted entirely when SkillFilter is set, since a
    /// specific skill filter can never match a resource that has none. Skill/Resource nodes with
    /// no (matching) children are omitted entirely, same convention as GetYUnitElementsJSON_Pool.
    /// Leaf key is the composite "<Resource No.>|<Skill Code>" (or "<Resource No.>|~NOSKILL~"),
    /// so a Day Planning/Capacity bar's section_id can target the specific skill row it belongs
    /// on (see SkillResScheduler_ExtractResourceNo for turning this back into a plain Resource
    /// No.); event resource_id stays the plain Resource No. for tooltip/lookup purposes. Skill
    /// node key is "SKILL|" + Skill Code, which can never collide with a composite leaf key.
    ///
    /// A leaf's label gets a trailing " (*)" suffix (e.g. "Arnoud Wolthuis (*)") when that
    /// resource's membership on this specific Skill branch comes ONLY from Day Planning data
    /// (Sources 2/3 of SkillResScheduler_BuildCombinedSkillLookup) with no matching "Resource
    /// Skill" master-data registration (Source 1) for that exact skill - i.e. the resource is
    /// doing work outside their registered skill set, a setup-data gap worth flagging visually.
    /// No suffix when the resource IS registered for that skill. The trailing "No Skill Assigned"
    /// bucket is unaffected - those resources have zero skill entries at all, so there is no
    /// registered/unregistered distinction to make there.
    ///
    /// StartDate/EndDate scope the Day-Planning-derived portion of tree membership (Sources 2/3 of
    /// SkillResScheduler_BuildCombinedSkillLookup) to the caller's displayed week - branches that
    /// only exist because of a Day Planning row outside that week will not appear. Resource
    /// Skill-registered branches (Source 1) are unaffected by StartDate/EndDate and remain always
    /// present regardless of week.
    /// </summary>
    procedure SkillResScheduler_BuildTreeJson(ResourceFilter: Text; SkillFilter: Text; StartDate: Date; EndDate: Date): Text
    var
        SkillCode: Record "Skill Code";
        Res: Record Resource;
        TempResourceOfSkill: Record Resource temporary;
        TempNoSkillResource: Record Resource temporary;
        CombinedSkills: Dictionary of [Text, Boolean];
        ResourceHasAny: Dictionary of [Code[20], Boolean];
        UnusedResourceSkillsMap: Dictionary of [Code[20], List of [Code[20]]];
        RegisteredSkills: Dictionary of [Text, Boolean];
        SkillObj: JsonObject;
        ResObj: JsonObject;
        ChildrenArray: JsonArray;
        DataArray: JsonArray;
        Root: JsonObject;
        OutText: Text;
    begin
        // Tree membership = "Resource Skill" registrations UNION skills observed on Day Planning
        // rows - see SkillResScheduler_BuildCombinedSkillLookup's header comment. The per-resource
        // skill-list output (UnusedResourceSkillsMap) is only needed by
        // SkillResScheduler_BuildCapacityJson, not here. RegisteredSkills IS used here - it lets
        // leaf labels distinguish an actual "Resource Skill" registration from a branch the
        // resource only appears on because of Day Planning data (see the " (*)" convention noted
        // below in the leaf-building block).
        SkillResScheduler_BuildCombinedSkillLookup(CombinedSkills, ResourceHasAny, UnusedResourceSkillsMap, RegisteredSkills, StartDate, EndDate);

        if SkillFilter = '' then begin
            Res.Reset();
            if ResourceFilter <> '' then
                Res.SetFilter("No.", ResourceFilter)
            else
                Res.SetFilter("No.", '<>%1', '');
            if Res.FindSet() then
                repeat
                    if not SkillResScheduler_IsPlaceholderResource(Res."No.", Res) then
                        if not ResourceHasAny.ContainsKey(Res."No.") then begin
                            TempNoSkillResource := Res;
                            TempNoSkillResource.Insert();
                        end;
                until Res.Next() = 0;
        end;

        SkillCode.Reset();
        if SkillFilter <> '' then
            SkillCode.SetFilter(Code, SkillFilter);
        if SkillCode.FindSet() then
            repeat
                Clear(ChildrenArray);
                TempResourceOfSkill.Reset();
                TempResourceOfSkill.DeleteAll();
                Res.Reset();
                if ResourceFilter <> '' then
                    Res.SetFilter("No.", ResourceFilter)
                else
                    Res.SetFilter("No.", '<>%1', '');
                if Res.FindSet() then
                    repeat
                        if not SkillResScheduler_IsPlaceholderResource(Res."No.", Res) then
                            if CombinedSkills.ContainsKey(Res."No." + '|' + SkillCode.Code) then begin
                                Clear(ResObj);
                                ResObj.Add('key', Res."No." + '|' + SkillCode.Code);
                                // " (*)" flags a resource that appears on this skill branch ONLY
                                // because of Day Planning data, with no matching "Resource Skill"
                                // registration - a setup-data gap worth surfacing to the user.
                                if RegisteredSkills.ContainsKey(Res."No." + '|' + SkillCode.Code) then
                                    ResObj.Add('label', Res.Name)
                                else
                                    ResObj.Add('label', Res.Name + ' (*)');
                                ResObj.Add('category', 'Resource');
                                ChildrenArray.Add(ResObj);
                            end;
                    until Res.Next() = 0;

                if ChildrenArray.Count() > 0 then begin
                    Clear(SkillObj);
                    SkillObj.Add('key', 'SKILL|' + SkillCode.Code);
                    if SkillCode.Description <> '' then
                        SkillObj.Add('label', SkillCode.Description)
                    else
                        SkillObj.Add('label', SkillCode.Code);
                    SkillObj.Add('category', 'Skill');
                    SkillObj.Add('open', true);
                    SkillObj.Add('children', ChildrenArray);
                    DataArray.Add(SkillObj);
                end;
            until SkillCode.Next() = 0;

        // Trailing "No Skill Assigned" node
        if TempNoSkillResource.FindSet() then begin
            Clear(ChildrenArray);
            repeat
                Clear(ResObj);
                ResObj.Add('key', TempNoSkillResource."No." + '|~NOSKILL~');
                ResObj.Add('label', TempNoSkillResource.Name);
                ResObj.Add('category', 'Resource');
                ChildrenArray.Add(ResObj);
            until TempNoSkillResource.Next() = 0;

            Clear(SkillObj);
            SkillObj.Add('key', 'SKILL|~NOSKILL~');
            SkillObj.Add('label', 'No Skill Assigned');
            SkillObj.Add('category', 'Skill');
            SkillObj.Add('open', true);
            SkillObj.Add('children', ChildrenArray);
            DataArray.Add(SkillObj);
        end;

        Clear(Root);
        Root.Add('data', DataArray);
        Root.WriteTo(OutText);
        exit(OutText);
    end;

    /// <summary>
    /// Emits one Capacity JSON event per skill branch the resource appears on in the tree -
    /// ResSkills is the resource's combined skill set (Resource Skill registrations UNION
    /// Day-Planning-observed skills, see SkillResScheduler_BuildCombinedSkillLookup), passed in
    /// by the caller rather than re-queried here, since it was already built once at the top of
    /// SkillResScheduler_BuildCapacityJson. SkillFilter-restricted when set (a plain code-value
    /// match against each candidate skill, same semantics as the old "Resource Skill" table
    /// filter check it replaces). Falls back to a single "~NOSKILL~" bucket entry when ResSkills
    /// is empty, mirroring SkillResScheduler_BuildTreeJson's convention - but only when
    /// SkillFilter is blank, since a specific skill filter can never match a no-skill resource.
    /// Shared by both flush sites (mid-loop resource/date change and end-of-loop) in
    /// SkillResScheduler_BuildCapacityJson below.
    /// </summary>
    local procedure SkillResScheduler_EmitCapacityEvents(var JArray: JsonArray; ResNo: Code[20]; CapDate: Date; StartTxt: Text; EndTxt: Text; Hours: Decimal; SkillFilter: Text; var ResSkills: List of [Code[20]])
    var
        TempSkillFilterCheck: Record "Skill Code" temporary;
        JObj: JsonObject;
        SkillVal: Code[20];
        AnyEmitted: Boolean;
    begin
        foreach SkillVal in ResSkills do begin
            if SkillFilter <> '' then begin
                TempSkillFilterCheck.Reset();
                TempSkillFilterCheck.DeleteAll();
                TempSkillFilterCheck.Init();
                TempSkillFilterCheck.Code := SkillVal;
                TempSkillFilterCheck.Insert();
                TempSkillFilterCheck.SetFilter(Code, SkillFilter);
                if TempSkillFilterCheck.IsEmpty() then
                    continue;
            end;

            Clear(JObj);
            JObj.Add('id', 'CAP|' + ResNo + '|' + Format(CapDate, 0, '<Year4><Month,2><Day,2>') + '|' + SkillVal);
            JObj.Add('resource_id', ResNo);
            JObj.Add('section_id', ResNo + '|' + SkillVal);
            JObj.Add('start_date', StartTxt);
            JObj.Add('end_date', EndTxt);
            JObj.Add('text', 'Capacity');
            JObj.Add('classname', 'event-capacity');
            JObj.Add('type', 'capacity');
            JObj.Add('hours', Hours);
            JArray.Add(JObj);
            AnyEmitted := true;
        end;

        if (not AnyEmitted) and (SkillFilter = '') then begin
            Clear(JObj);
            JObj.Add('id', 'CAP|' + ResNo + '|' + Format(CapDate, 0, '<Year4><Month,2><Day,2>') + '|~NOSKILL~');
            JObj.Add('resource_id', ResNo);
            JObj.Add('section_id', ResNo + '|~NOSKILL~');
            JObj.Add('start_date', StartTxt);
            JObj.Add('end_date', EndTxt);
            JObj.Add('text', 'Capacity');
            JObj.Add('classname', 'event-capacity');
            JObj.Add('type', 'capacity');
            JObj.Add('hours', Hours);
            JArray.Add(JObj);
        end;
    end;

    /// <summary>
    /// True when at least one skill in SkillList satisfies SkillFilter's filter expression (via a
    /// throwaway temporary "Skill Code" table so full BC filter syntax - "A|B", ranges, "<>X" -
    /// works against an in-memory list rather than a real query). Blank SkillFilter always
    /// matches, same not-blank convention as ResourceMatchesNoFilter/ResourceMatchesSkillFilter.
    /// Used by SkillResScheduler_BuildCapacityJson to decide whether a resource's Res. Capacity
    /// Entry rows should be aggregated at all when a SkillFilter is active, sourced from the same
    /// combined (Resource Skill UNION Day-Planning-observed) skill set the tree uses - not just
    /// "Resource Skill" registrations, so a Capacity row for a resource that only has a skill via
    /// Day Planning still passes when SkillFilter targets that skill.
    /// </summary>
    local procedure SkillResScheduler_SkillListMatchesFilter(var SkillList: List of [Code[20]]; SkillFilter: Text): Boolean
    var
        TempSkillFilterCheck: Record "Skill Code" temporary;
        SkillVal: Code[20];
    begin
        if SkillFilter = '' then
            exit(true);
        foreach SkillVal in SkillList do begin
            if not TempSkillFilterCheck.Get(SkillVal) then begin
                TempSkillFilterCheck.Init();
                TempSkillFilterCheck.Code := SkillVal;
                TempSkillFilterCheck.Insert();
            end;
        end;
        TempSkillFilterCheck.SetFilter(Code, SkillFilter);
        exit(not TempSkillFilterCheck.IsEmpty());
    end;

    /// <summary>
    /// Aggregated Capacity events (one bar per Resource/Date, summed Capacity, earliest Start
    /// Time - same aggregation as ResScheduler_BuildCapacityJson) but always tagged with a
    /// fixed classname/type so the bar renders in the dedicated "Capacity" color regardless of
    /// which resource it belongs to (ResScheduler_GetResourceColor's per-resource hash color
    /// does not satisfy the "3 distinct, clearly different colors" requirement here). Res.
    /// Capacity Entry has no Skill field of its own, so SkillFilter is applied per-row against
    /// each resource's combined skill set (Resource Skill registrations UNION Day-Planning-
    /// observed skills - built once up front via SkillResScheduler_BuildCombinedSkillLookup, same
    /// lookup SkillResScheduler_BuildTreeJson uses) rather than a table filter - non-matching rows
    /// are simply never aggregated/emitted, which is safe because the aggregation state
    /// (LastResNo/LastDate/AggCapacity) is only ever touched for rows that pass the check, so a
    /// run of matching rows for the same resource/date still flushes correctly when the next
    /// matching row differs. Each flush passes the resource's own skill list on to
    /// SkillResScheduler_EmitCapacityEvents, which duplicates the Capacity bar onto every branch
    /// in that list (SkillFilter-restricted there too) - including Day-Planning-only branches, so
    /// e.g. a resource registered only for DELIVER but with an ELEKTR Day Planning still gets its
    /// Capacity bar duplicated onto both the Delivery Service and Elektrisch tree rows.
    /// </summary>
    procedure SkillResScheduler_BuildCapacityJson(ResourceFilter: Text; SkillFilter: Text; StartDate: Date; EndDate: Date): Text
    var
        ResCap: Record "Res. Capacity Entry";
        TempResCap: Record "Res. Capacity Entry" temporary;
        CombinedSkills: Dictionary of [Text, Boolean];
        ResourceHasAny: Dictionary of [Code[20], Boolean];
        ResourceSkillsMap: Dictionary of [Code[20], List of [Code[20]]];
        UnusedRegisteredSkills: Dictionary of [Text, Boolean];
        CurrentResSkills: List of [Code[20]];
        JArray: JsonArray;
        JRoot: JsonObject;
        Result: Text;
        StartDateTimeStr: Text;
        EndDateTimeStr: Text;
        LastResNo: Code[20];
        LastDate: Date;
        LastResSkills: List of [Code[20]];
        AggStartTime: Time;
        AggCapacity: Decimal;
    begin
        // Combined per-resource skill set - same union rule as the tree (see
        // SkillResScheduler_BuildCombinedSkillLookup). Rebuilt fresh here rather than shared with
        // SkillResScheduler_BuildTreeJson's call, same "no cross-call caching" convention as the
        // rest of this codeunit. UnusedRegisteredSkills (registered-vs-observed distinction) is
        // only needed by SkillResScheduler_BuildTreeJson's leaf-label " (*)" flag, not here -
        // this procedure already gets what it needs from ResourceSkillsMap.
        SkillResScheduler_BuildCombinedSkillLookup(CombinedSkills, ResourceHasAny, ResourceSkillsMap, UnusedRegisteredSkills, StartDate, EndDate);

        ResCap.Reset();
        ResCap.SetCurrentKey("Resource No.", "Date");
        if (StartDate <> 0D) and (EndDate <> 0D) then
            ResCap.SetRange("Date", StartDate, EndDate);
        if ResourceFilter <> '' then
            ResCap.SetFilter("Resource No.", ResourceFilter)
        else
            ResCap.SetFilter("Resource No.", '<>%1', '');

        LastResNo := '';
        LastDate := 0D;
        AggStartTime := 0T;
        AggCapacity := 0;

        if ResCap.FindSet() then
            repeat
                if ResourceSkillsMap.ContainsKey(ResCap."Resource No.") then
                    CurrentResSkills := ResourceSkillsMap.Get(ResCap."Resource No.")
                else
                    Clear(CurrentResSkills);
                if SkillResScheduler_SkillListMatchesFilter(CurrentResSkills, SkillFilter) then
                if (ResCap."Resource No." <> LastResNo) or (ResCap."Date" <> LastDate) then begin
                    if (LastResNo <> '') and (AggCapacity > 0) then begin
                        TempResCap.Init();
                        TempResCap."Resource No." := LastResNo;
                        TempResCap."Date" := LastDate;
                        TempResCap."Start Time" := AggStartTime;
                        GetStartEndTxt(TempResCap, AggCapacity, StartDateTimeStr, EndDateTimeStr);
                        if (StartDateTimeStr <> '') and (EndDateTimeStr <> '') then
                            SkillResScheduler_EmitCapacityEvents(JArray, LastResNo, LastDate, StartDateTimeStr, EndDateTimeStr, AggCapacity, SkillFilter, LastResSkills);
                    end;
                    LastResNo := ResCap."Resource No.";
                    LastDate := ResCap."Date";
                    LastResSkills := CurrentResSkills;
                    AggStartTime := ResCap."Start Time";
                    AggCapacity := ResCap.Capacity;
                end else begin
                    AggCapacity += ResCap.Capacity;
                    if (ResCap."Start Time" <> 0T) then
                        if (AggStartTime = 0T) or (ResCap."Start Time" < AggStartTime) then
                            AggStartTime := ResCap."Start Time";
                end;
            until ResCap.Next() = 0;

        if (LastResNo <> '') and (AggCapacity > 0) then begin
            TempResCap.Init();
            TempResCap."Resource No." := LastResNo;
            TempResCap."Date" := LastDate;
            TempResCap."Start Time" := AggStartTime;
            GetStartEndTxt(TempResCap, AggCapacity, StartDateTimeStr, EndDateTimeStr);
            if (StartDateTimeStr <> '') and (EndDateTimeStr <> '') then
                SkillResScheduler_EmitCapacityEvents(JArray, LastResNo, LastDate, StartDateTimeStr, EndDateTimeStr, AggCapacity, SkillFilter, LastResSkills);
        end;

        Clear(JRoot);
        JRoot.Add('data', JArray);
        JRoot.WriteTo(Result);
        exit(Result);
    end;

    /// <summary>
    /// "HH:mm" text for a Time value, blank when 0T (used by the JS-side progress-split
    /// segment math). Built via explicit zero-padding rather than the "<Hours24,2>" custom
    /// format placeholder - that placeholder space-pads single-digit hours/minutes here (e.g.
    /// "08:00" comes back as " 8:00"), which the JS-side parseHHmm expects zero-padded.
    /// </summary>
    local procedure SkillResScheduler_FormatHHmm(pTime: Time): Text
    var
        HourTxt: Text;
        MinuteTxt: Text;
    begin
        if pTime = 0T then
            exit('');
        HourTxt := Format(pTime, 0, '<Hours24>');
        MinuteTxt := Format(pTime, 0, '<Minutes>');
        exit(PadStr('', 2 - StrLen(HourTxt), '0') + HourTxt + ':' + PadStr('', 2 - StrLen(MinuteTxt), '0') + MinuteTxt);
    end;

    /// <summary>
    /// One event per Day Planning row (Plan Date within [StartDate,EndDate]) placed on the
    /// Assigned Resource's row (falling back to the Requested Resource's row when nothing is
    /// assigned yet - so an unassigned request is still visible on the intended resource).
    /// The bar's start_date/end_date is the envelope (earliest..latest) of whichever of
    /// Assigned/Requested have both a Start and End Time set; the raw "HH:mm" Assigned/
    /// Requested times are carried separately (start_time_assigned/end_time_assigned/
    /// start_time_requested/end_time_requested) for the JS event_bar_text template to render
    /// as two proportional sub-segments inside the bar - same technique as projectschedule's
    /// wrapper.js (see that file's event_bar_text/segmentHtml). SkillFilter is applied directly
    /// against Day Planning's own "Skill" field (a table filter, not a per-resource lookup like
    /// Capacity's - Day Planning is skill-tagged per row, independent of whichever skill(s) the
    /// Assigned/Requested resource happens to carry). The bar's section_id targets the specific
    /// composite tree row for the row resource's Skill (the row's own Skill when set, else that
    /// resource's primary skill via SkillResScheduler_GetPrimarySkill, else "~NOSKILL~" - the
    /// tree always has a branch for the row's own Skill now, since this same row is one of the
    /// rows SkillResScheduler_BuildCombinedSkillLookup's Source 2/3 loops scanned to build that
    /// branch) - resource_id stays the plain Resource No.
    /// </summary>
    procedure SkillResScheduler_BuildDayPlanningJson(ResourceFilter: Text; SkillFilter: Text; JobNoFilter: Text; JobTaskNoFilter: Text; StartDate: Date; EndDate: Date): Text
    var
        DayPlanning: Record "Day Planning";
        Res: Record Resource;
        RequestedRes: Record Resource;
        JArray: JsonArray;
        JObj: JsonObject;
        JRoot: JsonObject;
        Result: Text;
        RowResourceNo: Code[20];
        AssignedResName: Text;
        RequestedResName: Text;
        AssignedValid: Boolean;
        RequestedValid: Boolean;
        EnvStartDateTime: DateTime;
        EnvEndDateTime: DateTime;
        AssignedStartDT: DateTime;
        AssignedEndDT: DateTime;
        RequestedStartDT: DateTime;
        RequestedEndDT: DateTime;
        EnvStartTxt: Text;
        EnvEndTxt: Text;
        EventText: Text;
        EffectiveSkill: Code[20];
    begin
        DayPlanning.Reset();
        if (StartDate <> 0D) and (EndDate <> 0D) then
            DayPlanning.SetRange("Plan Date", StartDate, EndDate);
        if SkillFilter <> '' then
            DayPlanning.SetFilter(Skill, SkillFilter);
        if JobNoFilter <> '' then
            DayPlanning.SetFilter("Job No.", JobNoFilter);
        if JobTaskNoFilter <> '' then
            DayPlanning.SetFilter("Job Task No.", JobTaskNoFilter);
        if DayPlanning.FindSet() then
            repeat
                RowResourceNo := DayPlanning."Assigned Resource No.";
                if RowResourceNo = '' then
                    RowResourceNo := DayPlanning."Requested Resource No.";
                if RowResourceNo <> '' then
                    if (ResourceFilter = '') or ResourceMatchesNoFilter(RowResourceNo, ResourceFilter) then begin
                        AssignedValid := (DayPlanning."Start Time Assigned" <> 0T) and (DayPlanning."End Time Assigned" <> 0T);
                        RequestedValid := (DayPlanning."Start Time Requested" <> 0T) and (DayPlanning."End Time Requested" <> 0T);

                        Clear(EnvStartDateTime);
                        Clear(EnvEndDateTime);
                        if AssignedValid then begin
                            AssignedStartDT := CreateDateTime(DayPlanning."Plan Date", DayPlanning."Start Time Assigned");
                            AssignedEndDT := CreateDateTime(DayPlanning."Plan Date", DayPlanning."End Time Assigned");
                            EnvStartDateTime := AssignedStartDT;
                            EnvEndDateTime := AssignedEndDT;
                        end;
                        if RequestedValid then begin
                            RequestedStartDT := CreateDateTime(DayPlanning."Plan Date", DayPlanning."Start Time Requested");
                            RequestedEndDT := CreateDateTime(DayPlanning."Plan Date", DayPlanning."End Time Requested");
                            if (EnvStartDateTime = 0DT) or (RequestedStartDT < EnvStartDateTime) then
                                EnvStartDateTime := RequestedStartDT;
                            if (EnvEndDateTime = 0DT) or (RequestedEndDT > EnvEndDateTime) then
                                EnvEndDateTime := RequestedEndDT;
                        end;
                        if (EnvStartDateTime = 0DT) or (EnvEndDateTime = 0DT) then begin
                            EnvStartDateTime := CreateDateTime(DayPlanning."Plan Date", 000000T);
                            EnvEndDateTime := CreateDateTime(DayPlanning."Plan Date", 235959T);
                        end;

                        EnvStartTxt := ToSessionDateTimeTxt(DT2Date(EnvStartDateTime), DT2Time(EnvStartDateTime));
                        EnvEndTxt := ToSessionDateTimeTxt(DT2Date(EnvEndDateTime), DT2Time(EnvEndDateTime));

                        AssignedResName := '';
                        if DayPlanning."Assigned Resource No." <> '' then
                            if Res.Get(DayPlanning."Assigned Resource No.") then
                                AssignedResName := Res.Name;
                        RequestedResName := '';
                        if DayPlanning."Requested Resource No." <> '' then
                            if RequestedRes.Get(DayPlanning."Requested Resource No.") then
                                RequestedResName := RequestedRes.Name;

                        EventText := DayPlanning.Description;
                        if EventText = '' then
                            if AssignedResName <> '' then
                                EventText := AssignedResName
                            else
                                if RequestedResName <> '' then
                                    EventText := RequestedResName
                                else
                                    EventText := 'Day Planning';

                        // The tree now always has a branch for whatever skill this Day Planning
                        // row actually carries (this row is one of the rows query "Res Skill Day
                        // Planning List" scans), so the old "is the resource registered for this
                        // skill" gate (SkillResScheduler_ResolveRowSkill/HasSkill) is no longer
                        // needed - just use the row's own Skill, falling back to the resource's
                        // primary skill only when the row itself has no Skill set at all.
                        EffectiveSkill := DayPlanning.Skill;
                        if EffectiveSkill = '' then
                            EffectiveSkill := SkillResScheduler_GetPrimarySkill(RowResourceNo);
                        if EffectiveSkill = '' then
                            EffectiveSkill := '~NOSKILL~';

                        Clear(JObj);
                        JObj.Add('id', Format(DayPlanning.RecordId));
                        JObj.Add('resource_id', RowResourceNo);
                        JObj.Add('section_id', RowResourceNo + '|' + EffectiveSkill);
                        JObj.Add('start_date', EnvStartTxt);
                        JObj.Add('end_date', EnvEndTxt);
                        JObj.Add('text', EventText);
                        JObj.Add('classname', 'event-DayPlanning');
                        JObj.Add('type', 'DayPlanning');
                        JObj.Add('start_time_assigned', SkillResScheduler_FormatHHmm(DayPlanning."Start Time Assigned"));
                        JObj.Add('end_time_assigned', SkillResScheduler_FormatHHmm(DayPlanning."End Time Assigned"));
                        JObj.Add('start_time_requested', SkillResScheduler_FormatHHmm(DayPlanning."Start Time Requested"));
                        JObj.Add('end_time_requested', SkillResScheduler_FormatHHmm(DayPlanning."End Time Requested"));
                        JObj.Add('assigned_resource_no', DayPlanning."Assigned Resource No.");
                        JObj.Add('assigned_resource_name', AssignedResName);
                        JObj.Add('assigned_hours', DayPlanning."Assigned Hours");
                        JObj.Add('requested_resource_no', DayPlanning."Requested Resource No.");
                        JObj.Add('requested_resource_name', RequestedResName);
                        JObj.Add('requested_hours', DayPlanning."Requested Hours");
                        JObj.Add('skill', DayPlanning.Skill);
                        JObj.Add('job_no', DayPlanning."Job No.");
                        JObj.Add('job_task_no', DayPlanning."Job Task No.");
                        JArray.Add(JObj);
                    end;
            until DayPlanning.Next() = 0;

        Clear(JRoot);
        JRoot.Add('data', JArray);
        JRoot.WriteTo(Result);
        exit(Result);
    end;

    /// <summary>
    /// Opens the single Day Planning record behind a "Resource Scheduler (New)" event bar, as
    /// its own Card - NOT the "Day Plannings" list page (page 50630) that the shared
    /// OpenDayPlanning procedure above opens for the other schedulers (that list-filtered-to-
    /// one-row approach is what OpenDayPlanning's own callers expect and must keep working
    /// unchanged; this add-in's own right-click/double-click just needs a genuine single-record
    /// card, confirmed live - the list view read as "open all, not just this one" to the user).
    /// Unlike OpenDayPlanning (which parses a "JobNo|TaskNo|Date|LineNo" event ID), this add-in's
    /// events use Format(RecordId) as their ID (see SkillResScheduler_BuildDayPlanningJson), so
    /// the record is looked up directly via RecordId instead - same technique as page
    /// "DHX Resource Scheduler"'s OnEventDoubleClick.
    /// </summary>
    procedure SkillResScheduler_OpenDayPlanningByEventId(EventId: Text)
    var
        DayPlanning: Record "Day Planning";
        RecRef: RecordRef;
        RecId: RecordId;
    begin
        if not Evaluate(RecId, EventId) then begin
            Message('Day planning not found for Event ID: %1', EventId);
            exit;
        end;
        if not RecRef.Get(RecId) then begin
            Message('Day planning not found for Event ID: %1', EventId);
            exit;
        end;
        RecRef.SetTable(DayPlanning);
        Page.Run(Page::"Day Planning Card Opt", DayPlanning);
    end;

    /// <summary>
    /// Opens the Resource Capacity page for the resource/week behind a "Resource Scheduler
    /// (New)" Capacity bar. Event ID format: "CAP|ResourceNo|YYYYMMDD" (see
    /// SkillResScheduler_BuildCapacityJson) - the aggregated bar has no single underlying
    /// "Res. Capacity Entry" (it can sum several rows for the same day), so this filters by
    /// resource + week instead of looking up one entry, mirroring OpenCapacity's own filter.
    /// </summary>
    procedure SkillResScheduler_OpenCapacityByEventId(EventId: Text)
    var
        ResCap: Record "Res. Capacity Entry";
        Parts: List of [Text];
        DatePart: Text;
        ResNo: Code[20];
        RowDate: Date;
        StartDate: Date;
        EndDate: Date;
        Y: Integer;
        M: Integer;
        D: Integer;
    begin
        Parts := EventId.Split('|');
        if Parts.Count() < 3 then
            exit;
        ResNo := CopyStr(Parts.Get(2), 1, MaxStrLen(ResNo));
        DatePart := Parts.Get(3);
        if StrLen(DatePart) <> 8 then
            exit;
        if not Evaluate(Y, CopyStr(DatePart, 1, 4)) then
            exit;
        if not Evaluate(M, CopyStr(DatePart, 5, 2)) then
            exit;
        if not Evaluate(D, CopyStr(DatePart, 7, 2)) then
            exit;
        RowDate := DMY2Date(D, M, Y);
        GetWeekPeriodDates(RowDate, StartDate, EndDate);
        ResCap.SetRange("Resource No.", ResNo);
        ResCap.SetRange("Date", StartDate, EndDate);
        Page.RunModal(0, ResCap);
    end;

    /// <summary>
    /// Opens the Job Task for the single Day Planning bar behind an event right-click - looks
    /// the record up via RecordId (same technique as SkillResScheduler_OpenDayPlanningByEventId),
    /// then opens its Job Task via Page::"Job Task List - Project" (PageType=List, SourceTable=
    /// "Job Task", no restrictive SourceTableView, CardPageID = "Opti Job Task Card"), the same
    /// target SkillResScheduler_OpenTasksForResource below uses, for consistency between the
    /// event-bar and resource-row "Open Task" actions.
    /// </summary>
    procedure SkillResScheduler_OpenTaskByEventId(EventId: Text)
    var
        DayPlanning: Record "Day Planning";
        JobTask: Record "Job Task";
        RecRef: RecordRef;
        RecId: RecordId;
    begin
        if not Evaluate(RecId, EventId) then
            exit;
        if not RecRef.Get(RecId) then
            exit;
        RecRef.SetTable(DayPlanning);
        if JobTask.Get(DayPlanning."Job No.", DayPlanning."Job Task No.") then
            Page.Run(Page::"Job Task List - Project", JobTask);
    end;

    /// <summary>
    /// Opens the Resource Card for the single Day Planning bar behind an event right-click -
    /// Assigned Resource No. if set, else Requested Resource No. (same "Assigned-else-Requested"
    /// resolution used elsewhere in this codeunit, e.g. RowResourceNo in
    /// SkillResScheduler_BuildDayPlanningJson - matches which resource's ROW this bar is already
    /// sitting on, so opening "the resource" from here is unambiguous). Delegates to the existing
    /// SkillResScheduler_OpenResourceCard(ResNo: Text) once the resource is resolved.
    /// </summary>
    procedure SkillResScheduler_OpenResourceByEventId(EventId: Text)
    var
        DayPlanning: Record "Day Planning";
        RecRef: RecordRef;
        RecId: RecordId;
        ResNo: Code[20];
    begin
        if not Evaluate(RecId, EventId) then
            exit;
        if not RecRef.Get(RecId) then
            exit;
        RecRef.SetTable(DayPlanning);
        ResNo := DayPlanning."Assigned Resource No.";
        if ResNo = '' then
            ResNo := DayPlanning."Requested Resource No.";
        SkillResScheduler_OpenResourceCard(ResNo);
    end;

    /// <summary>Opens the Resource Card for a Resource No. (tree leaf / event resource_id).</summary>
    procedure SkillResScheduler_OpenResourceCard(ResNo: Text)
    var
        Res: Record Resource;
    begin
        if StrLen(ResNo) > MaxStrLen(Res."No.") then
            exit;
        if Res.Get(CopyStr(ResNo, 1, MaxStrLen(Res."No."))) then
            Page.Run(Page::"Resource Card", Res);
    end;

    /// <summary>Opens the Resource Skills list filtered to a Resource No. (tree leaf right-click).</summary>
    procedure SkillResScheduler_OpenResourceSkills(ResNo: Text)
    var
        ResourceSkill: Record "Resource Skill";
    begin
        if StrLen(ResNo) > MaxStrLen(ResourceSkill."No.") then
            exit;
        ResourceSkill.SetRange(Type, ResourceSkill.Type::Resource);
        ResourceSkill.SetRange("No.", CopyStr(ResNo, 1, MaxStrLen(ResourceSkill."No.")));
        Page.Run(0, ResourceSkill);
    end;

    /// <summary>
    /// Opens the "Day Plannings" LIST (deliberately a list here, unlike
    /// SkillResScheduler_OpenDayPlanningByEventId's single-record Card - this is a resource-row
    /// right-click meant to show everything for that resource in the active week, not one bar)
    /// for every Day Planning where the resource is EITHER the Requested Resource No. OR the
    /// Assigned Resource No., within [StartDate, EndDate]. SetRange/SetFilter always AND
    /// together across different fields, so a cross-field OR needs two separate filtered passes
    /// marking into the same (non-temporary) record variable - Mark() persists across filter
    /// changes on the same variable, so the two passes safely accumulate into one marked set.
    ///
    /// Opened via Page.Run(ObjectId, Record), NOT SetTableView()+RunModal() - confirmed live
    /// that SetTableView() only captures field-based SetRange/SetFilter conditions into a filter
    /// STRING, which cannot express an arbitrary marked-RecordId set (there is no filter syntax
    /// for "these exact records"), so it silently dropped the Mark()/MarkedOnly() state and the
    /// list came back empty. Page.Run(ObjectId, Record) is the documented, correct way to open a
    /// page bound to a live, marked record variable.
    /// </summary>
    procedure SkillResScheduler_OpenDayPlanningsForResource(ResNo: Text; StartDate: Date; EndDate: Date)
    var
        DayPlanning: Record "Day Planning";
        ResNoCode: Code[20];
    begin
        if StrLen(ResNo) > MaxStrLen(ResNoCode) then
            exit;
        ResNoCode := CopyStr(ResNo, 1, MaxStrLen(ResNoCode));

        DayPlanning.Reset();
        if (StartDate <> 0D) and (EndDate <> 0D) then
            DayPlanning.SetRange("Plan Date", StartDate, EndDate);
        DayPlanning.SetRange("Assigned Resource No.", ResNoCode);
        if DayPlanning.FindSet() then
            repeat
                DayPlanning.Mark(true);
            until DayPlanning.Next() = 0;

        DayPlanning.SetRange("Assigned Resource No.");
        DayPlanning.SetRange("Requested Resource No.", ResNoCode);
        if DayPlanning.FindSet() then
            repeat
                DayPlanning.Mark(true);
            until DayPlanning.Next() = 0;

        DayPlanning.SetRange("Requested Resource No.");
        DayPlanning.MarkedOnly(true);
        Page.Run(Page::"Day Plannings", DayPlanning);
    end;

    /// <summary>
    /// Opens the Job Task LIST for every DISTINCT (Job No., Job Task No.) pair referenced by a Day
    /// Planning row where the given resource is EITHER the Assigned Resource No. OR the Requested
    /// Resource No., within [StartDate, EndDate] - the resource-row right-click "Open Task" action,
    /// one level up from SkillResScheduler_OpenDayPlanningsForResource (which shows the Day Planning
    /// lines themselves; this shows the Job Tasks those lines belong to). Reuses the same
    /// Mark()/MarkedOnly() two-pass OR technique as OpenDayPlanningsForResource for the Day Planning
    /// side, then marks the corresponding Job Task records - deduped via a temporary Job Task record
    /// keyed on (Job No., Job Task No.), since the same task can be referenced by multiple Day
    /// Planning rows across the week - and opens them via Page::"Job Task List - Project"
    /// (PageType=List, SourceTable="Job Task", no restrictive SourceTableView, CardPageID =
    /// "Opti Job Task Card"), the same target SkillResScheduler_OpenTaskByEventId above uses, so
    /// multiple distinct Job Tasks marked here render as a list on the same page a single task
    /// would open to from an event bar.
    /// </summary>
    procedure SkillResScheduler_OpenTasksForResource(ResNo: Text; StartDate: Date; EndDate: Date)
    var
        DayPlanning: Record "Day Planning";
        JobTask: Record "Job Task";
        TempJobTaskKey: Record "Job Task" temporary;
        ResNoCode: Code[20];
    begin
        if StrLen(ResNo) > MaxStrLen(ResNoCode) then
            exit;
        ResNoCode := CopyStr(ResNo, 1, MaxStrLen(ResNoCode));

        DayPlanning.Reset();
        if (StartDate <> 0D) and (EndDate <> 0D) then
            DayPlanning.SetRange("Plan Date", StartDate, EndDate);
        DayPlanning.SetRange("Assigned Resource No.", ResNoCode);
        if DayPlanning.FindSet() then
            repeat
                DayPlanning.Mark(true);
            until DayPlanning.Next() = 0;

        DayPlanning.SetRange("Assigned Resource No.");
        DayPlanning.SetRange("Requested Resource No.", ResNoCode);
        if DayPlanning.FindSet() then
            repeat
                DayPlanning.Mark(true);
            until DayPlanning.Next() = 0;

        DayPlanning.SetRange("Requested Resource No.");
        DayPlanning.MarkedOnly(true);
        if DayPlanning.FindSet() then
            repeat
                if not TempJobTaskKey.Get(DayPlanning."Job No.", DayPlanning."Job Task No.") then begin
                    TempJobTaskKey.Init();
                    TempJobTaskKey."Job No." := DayPlanning."Job No.";
                    TempJobTaskKey."Job Task No." := DayPlanning."Job Task No.";
                    TempJobTaskKey.Insert();
                    if JobTask.Get(DayPlanning."Job No.", DayPlanning."Job Task No.") then
                        JobTask.Mark(true);
                end;
            until DayPlanning.Next() = 0;

        JobTask.MarkedOnly(true);
        Page.Run(Page::"Job Task List - Project", JobTask);
    end;

    /// <summary>
    /// Opens the standard Res. Capacity Entry list (page 0 = the table's own default page, same
    /// target SkillResScheduler_OpenCapacityByEventId above already uses for a Capacity-bar
    /// right-click) filtered to a single Resource No. and [StartDate, EndDate] - the resource-row
    /// right-click equivalent of SkillResScheduler_OpenDayPlanningsForResource, but simpler since
    /// Res. Capacity Entry has only one resource field (no Assigned/Requested OR to reconcile),
    /// so a plain SetRange pair is enough - no Mark()/MarkedOnly() needed here.
    /// </summary>
    procedure SkillResScheduler_ShowCapacityForResource(ResNo: Text; StartDate: Date; EndDate: Date)
    var
        ResCap: Record "Res. Capacity Entry";
        ResNoCode: Code[20];
    begin
        if StrLen(ResNo) > MaxStrLen(ResNoCode) then
            exit;
        ResNoCode := CopyStr(ResNo, 1, MaxStrLen(ResNoCode));

        ResCap.SetRange("Resource No.", ResNoCode);
        if (StartDate <> 0D) and (EndDate <> 0D) then
            ResCap.SetRange("Date", StartDate, EndDate);
        Page.RunModal(0, ResCap);
    end;
}