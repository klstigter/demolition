codeunit 50604 "DHX Data Handler"
{
    trigger OnRun()
    begin

    end;

    var
        // Fallback "OK/assigned" status pill colours for the Request/Assignment Planner - no
        // equivalent named status-colour convention exists in codeunit 50609, so kept static.
        ReqAssignOkStatusBackgroundColorTok: Label '#DDF2E5', Locked = true;
        ReqAssignOkStatusTextColorTok: Label '#26613A', Locked = true;

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
        DayPlanningPrefetch: Record "Day Planning";
        WeekTemp: record "Aging Band Buffer" temporary;
        ResourcePrefetch: Record Resource;
        VendorPrefetch: Record Vendor;
        Job: Record Job;
        ResourceNameDict: Dictionary of [Code[20], Text]; // "No." -> Name, bulk-prefetched once (see ApplyProjectSchedulerDayPlanningFilters/BuildCodeOrFilter) instead of a Resource.Get() per Day Planning row
        VendorNameDict: Dictionary of [Code[20], Text]; // "No." -> Name, same bulk-prefetch idea for Vendor
        ResourceNoSet: List of [Code[20]];
        VendorNoSet: List of [Code[20]];

        ResNo: Code[20];
        ResName: Text;
        ReqResName: Text;
        VenName: Text;
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
        SkillColorDict: Dictionary of [Code[20], Text];
        NextSkillPaletteIndex: Integer;
    begin
        PlanninJsonTxt := '';
        //Marking Job based on Day Plannings within the given date range
        ApplyProjectSchedulerDayPlanningFilters(DayPlanning, StartDate, EndDate, ResourceFilter, JobFilter, jobTaskFilter);

        // Bulk-prefetch every Resource/Vendor referenced by this week's (filtered) Day Plannings
        // in ONE FindSet each, into an in-memory No.->Name dictionary - instead of the old
        // Resource.Get()/Resource.Get()/Vendor.Get() done per Day Planning row below (up to 3
        // single-record DB round trips per row). Uses a separate DayPlanningPrefetch cursor so it
        // doesn't disturb the main DayPlanning.FindSet() loop's own cursor further down.
        Clear(ResourceNameDict);
        Clear(VendorNameDict);
        Clear(ResourceNoSet);
        Clear(VendorNoSet);
        ApplyProjectSchedulerDayPlanningFilters(DayPlanningPrefetch, StartDate, EndDate, ResourceFilter, JobFilter, jobTaskFilter);
        if DayPlanningPrefetch.FindSet() then
            repeat
                if (DayPlanningPrefetch."Assigned Resource No." <> '') and not ResourceNoSet.Contains(DayPlanningPrefetch."Assigned Resource No.") then
                    ResourceNoSet.Add(DayPlanningPrefetch."Assigned Resource No.");
                if (DayPlanningPrefetch."Requested Resource No." <> '') and not ResourceNoSet.Contains(DayPlanningPrefetch."Requested Resource No.") then
                    ResourceNoSet.Add(DayPlanningPrefetch."Requested Resource No.");
                if (DayPlanningPrefetch."Vendor No." <> '') and not VendorNoSet.Contains(DayPlanningPrefetch."Vendor No.") then
                    VendorNoSet.Add(DayPlanningPrefetch."Vendor No.");
            until DayPlanningPrefetch.Next() = 0;
        if ResourceNoSet.Count() > 0 then begin
            ResourcePrefetch.Reset();
            ResourcePrefetch.SetFilter("No.", BuildCodeOrFilter(ResourceNoSet));
            if ResourcePrefetch.FindSet() then
                repeat
                    ResourceNameDict.Add(ResourcePrefetch."No.", ResourcePrefetch.Name);
                until ResourcePrefetch.Next() = 0;
        end;
        if VendorNoSet.Count() > 0 then begin
            VendorPrefetch.Reset();
            VendorPrefetch.SetFilter("No.", BuildCodeOrFilter(VendorNoSet));
            if VendorPrefetch.FindSet() then
                repeat
                    VendorNameDict.Add(VendorPrefetch."No.", VendorPrefetch.Name);
                until VendorPrefetch.Next() = 0;
        end;

        //DayPlanning.SetRange(Type, DayPlanning.Type::Resource);
        if DayPlanning.FindSet() then begin
            repeat
                // Job Task cache-first: skip the DB Get entirely once this Job Task has already
                // been seen this run (TEMPJobTasks is the in-memory cache being built here).
                if not TEMPJobTasks.Get(DayPlanning."Job No.", DayPlanning."Job Task No.") then begin
                    JobTasks.Get(DayPlanning."Job No.", DayPlanning."Job Task No.");
                    TEMPJobTasks := JobTasks;
                    TEMPJobTasks.insert();
                end;

                // resource data - from the bulk-prefetched dictionary above
                ResNo := '';
                ResName := '';
                if DayPlanning."Assigned Resource No." <> '' then
                    if ResourceNameDict.Get(DayPlanning."Assigned Resource No.", ResName) then
                        ResNo := DayPlanning."Assigned Resource No.";

                // requested resource data - same dictionary
                ReqResName := '';
                if DayPlanning."Requested Resource No." <> '' then
                    ResourceNameDict.Get(DayPlanning."Requested Resource No.", ReqResName);
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
                PlanningObject.Add('text', TaskSchedulerEventBarText(DayPlanning.Skill, ResName, ReqResName,
                    DayPlanning."Job No." + '|' + DayPlanning."Job Task No." + ' (vacant)'));

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
                VenName := '';
                if DayPlanning."Vendor No." <> '' then
                    VendorNameDict.Get(DayPlanning."Vendor No.", VenName);
                PlanningObject.Add('details', VenName);
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
                PlanningObject.Add('skill', DayPlanning.Skill);
                PlanningObject.Add('requested_color', ResolveRequestedColor(DayPlanning.Skill, SkillColorDict, NextSkillPaletteIndex));

                PlanningArray.Add(PlanningObject);
            until DayPlanning.Next() = 0;
            // Serialize once, after the loop, instead of re-serializing the whole (growing)
            // array on every single row - the final string is identical either way since only
            // the last write's result is ever read, but this cuts an O(n) redundant
            // re-serialization down to one write.
            PlanningArray.WriteTo(PlanninJsonTxt);

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

    // Adds every ancestor Begin-Total / Heading task for every task in TEMPJobTasks that has
    // Indentation > 0, with the SAME ancestor-insertion contract as before (direct parent = the
    // last Begin-Total/Heading row - never Posting/End-Total/Total - strictly before this task's
    // own Job Task No., at exactly Indentation - 1; repeated up the chain to the root), but
    // computed with a single sorted FindSet per distinct Job No. instead of a multi-pass
    // "repeat...until not NewAncestorAdded" outer loop that re-ran a fresh filtered FindLast()
    // query for every indented task on every pass. For each Job: one FindSet over that Job's own
    // Job Task list (primary-key order = Job Task No. ascending) is held in memory (AllJobTasksForJob),
    // and while walking it forward, LastAncestorAtLevel[Indentation+1] is kept up to date with the
    // most recently seen ancestor-eligible row at that indentation - the same "last row with a
    // smaller Job Task No." that FindLast() used to compute per task, now read off in O(1) as each
    // row is visited. ParentOfMap then holds every row's immediate parent (Job Task No. ->
    // parent's Job Task No.), and the originally-touched tasks are walked up that map to their
    // root, inserting every missing ancestor along the way - no repeated DB round trips at all.
    local procedure AddAncestorsToTemp(var TEMPJobTasks: Record "Job Task" temporary)
    var
        TouchedSnapshot: Record "Job Task" temporary;
        JobTaskReal: Record "Job Task";
        AllJobTasksForJob: Record "Job Task" temporary;
        DistinctJobNos: List of [Code[20]];
        JobNo: Code[20];
        ParentOfMap: Dictionary of [Code[20], Code[20]];
        // Dictionary, not a fixed-size array: a fixed array[60] (the original shape here) throws
        // "Index out of bounds" the moment any real Job Task's Indentation exceeds the array's
        // bound - confirmed live against CRONUS NL via the AL call stack pointing at this exact
        // line. A Dictionary has no such ceiling, so arbitrarily deep WBS nesting just works.
        LastAncestorAtLevel: Dictionary of [Integer, Code[20]];
        LastAncestorCode: Code[20];
        ToProcess: List of [Code[20]];
        StartKey: Code[20];
        CurrentKey: Code[20];
        ParentKey: Code[20];
    begin
        // Snapshot the originally-touched tasks (one in-memory pass, no query) and collect the
        // distinct Job Nos among them.
        TEMPJobTasks.Reset();
        if TEMPJobTasks.FindSet() then
            repeat
                TouchedSnapshot := TEMPJobTasks;
                TouchedSnapshot.Insert();
                if not DistinctJobNos.Contains(TEMPJobTasks."Job No.") then
                    DistinctJobNos.Add(TEMPJobTasks."Job No.");
            until TEMPJobTasks.Next() = 0;

        foreach JobNo in DistinctJobNos do begin
            AllJobTasksForJob.Reset();
            AllJobTasksForJob.DeleteAll();
            Clear(ParentOfMap);
            Clear(LastAncestorAtLevel);

            // Single sorted pass over this Job's own Job Task list - held in memory so every
            // ancestor lookup below is a Get()/dictionary lookup, never a fresh DB round trip.
            JobTaskReal.Reset();
            JobTaskReal.SetRange("Job No.", JobNo);
            if JobTaskReal.FindSet() then
                repeat
                    AllJobTasksForJob := JobTaskReal;
                    AllJobTasksForJob.Insert();

                    // Direct parent = the last ancestor-eligible row strictly before this one
                    // (i.e. seen earlier in this ascending walk), at exactly Indentation - 1 -
                    // same definition the old per-task FindLast() used.
                    if (JobTaskReal.Indentation > 0) and LastAncestorAtLevel.Get(JobTaskReal.Indentation, LastAncestorCode) then
                        ParentOfMap.Add(JobTaskReal."Job Task No.", LastAncestorCode);

                    // Ancestor-eligible = not Posting/End-Total/Total (closing markers are never
                    // parent nodes) - update this row's own level for rows seen after it.
                    if (JobTaskReal."Job Task Type" <> JobTaskReal."Job Task Type"::Posting) and
                       (JobTaskReal."Job Task Type" <> JobTaskReal."Job Task Type"::"End-Total") and
                       (JobTaskReal."Job Task Type" <> JobTaskReal."Job Task Type"::Total) then
                        LastAncestorAtLevel.Set(JobTaskReal.Indentation + 1, JobTaskReal."Job Task No.");
                until JobTaskReal.Next() = 0;

            // Every task of this Job that was originally touched, walked up its ancestor chain -
            // inserting every missing ancestor handles arbitrary nesting depth without an outer
            // "did anything change" loop, since the chain is fully resolved on first climb.
            Clear(ToProcess);
            TouchedSnapshot.Reset();
            TouchedSnapshot.SetRange("Job No.", JobNo);
            if TouchedSnapshot.FindSet() then
                repeat
                    ToProcess.Add(TouchedSnapshot."Job Task No.");
                until TouchedSnapshot.Next() = 0;

            foreach StartKey in ToProcess do begin
                CurrentKey := StartKey;
                while ParentOfMap.Get(CurrentKey, ParentKey) do begin
                    if TEMPJobTasks.Get(JobNo, ParentKey) then
                        break; // already present - its own ancestor chain was already fully resolved
                    if AllJobTasksForJob.Get(JobNo, ParentKey) then begin
                        TEMPJobTasks := AllJobTasksForJob;
                        TEMPJobTasks.Insert();
                    end;
                    CurrentKey := ParentKey;
                end;
            end;
        end;
    end;

    // Shared Day Planning filter setup for the Task Scheduler's weekly data window - one place
    // for the "Plan Date" range + Job/Job Task/Resource filters used by GetYUnitElementsJSON_Project,
    // its Resource/Vendor bulk-prefetch pass, and GetYUnitElementsJSON_Project_Paged, so the three
    // never drift out of sync with each other.
    local procedure ApplyProjectSchedulerDayPlanningFilters(var DayPlanningRec: Record "Day Planning"; StartDate: Date; EndDate: Date; ResourceFilter: Text; JobFilter: Text; JobTaskFilter: Text)
    begin
        DayPlanningRec.Reset();
        DayPlanningRec.SetCurrentKey("Plan Date", "Start Time Assigned");
        DayPlanningRec.SetRange("Plan Date", StartDate, EndDate);
        if JobFilter <> '' then
            DayPlanningRec.SetFilter("Job No.", JobFilter)
        else
            DayPlanningRec.SetFilter("Job No.", '<>%1', ''); //Exclude blank Job Nos
        if JobTaskFilter <> '' then
            DayPlanningRec.SetFilter("Job Task No.", JobTaskFilter)
        else
            DayPlanningRec.SetFilter("Job Task No.", '<>%1', ''); //Exclude blank task Nos
        if ResourceFilter <> '' then
            DayPlanningRec.SetFilter("Assigned Resource No.", ResourceFilter);
    end;

    // Joins a list of Code[20] values into a single AL OR-filter ("A|B|C") suitable for
    // SetFilter("No.", ...) - used to bulk-load a Resource/Vendor prefetch dictionary in one
    // FindSet instead of one Get() per distinct value.
    local procedure BuildCodeOrFilter(var Codes: List of [Code[20]]): Text
    var
        FilterTxt: Text;
        CodeVal: Code[20];
    begin
        foreach CodeVal in Codes do begin
            if FilterTxt <> '' then
                FilterTxt += '|';
            FilterTxt += CodeVal;
        end;
        exit(FilterTxt);
    end;

    /// <summary>
    /// Paginated sibling of GetYUnitElementsJSON_Project: builds the exact same Job-by-Job section
    /// tree + events for the given period/filters, but stops adding whole Jobs to the returned JSON
    /// once the running section-row count reaches MaxRows - always AT a Job boundary, never mid-job
    /// (a Job's own indented task tree is never split across the sync/async boundary; the first Job
    /// is always included even if it alone exceeds MaxRows). RemainingJobFilter comes back as an AL
    /// OR-filter ("JobA|JobB|...") of every Job No. NOT included in this page, ready to hand to a
    /// background task (see codeunit "Task Scheduler BG Sections") that finishes the rest via a
    /// plain GetYUnitElementsJSON_Project call scoped to just that filter.
    /// Reuses Part A's fixed AddAncestorsToTemp/prefetch technique in full (this is effectively a
    /// self-contained copy of GetYUnitElementsJSON_Project's assembly logic, kept separate rather
    /// than sharing code with it, so the already-verified byte-identical non-paged procedure is
    /// never put at risk by pagination-only changes here) - only the "where do we stop" bookkeeping
    /// at the very end (deciding which Jobs make the first page, and filtering the events
    /// accordingly) is new.
    /// </summary>
    procedure GetYUnitElementsJSON_Project_Paged(AnchorDate: Date;
                               StartDate: Date;
                               EndDate: Date;
                               ResourceFilter: Text;
                               JobFilter: Text;
                               JobTaskFilter: Text;
                               MaxRows: Integer;
                               var PlanninJsonTxt: Text;
                               var EarliestPlanningDate: Date;
                               var RemainingJobFilter: Text): Text
    var
        JobTasks: Record "Job Task";
        TEMPJobTasks: Record "Job Task" temporary;
        DayPlanning: Record "Day Planning";
        DayPlanningPrefetch: Record "Day Planning";
        WeekTemp: record "Aging Band Buffer" temporary;
        ResourcePrefetch: Record Resource;
        VendorPrefetch: Record Vendor;
        Job: Record Job;
        ResourceNameDict: Dictionary of [Code[20], Text];
        VendorNameDict: Dictionary of [Code[20], Text];
        ResourceNoSet: List of [Code[20]];
        VendorNoSet: List of [Code[20]];

        ResNo: Code[20];
        ResName: Text;
        ReqResName: Text;
        VenName: Text;
        CurrentJobNo: Code[20];

        JobObject, TaskObject, PlanningLineObject : JsonObject;
        ChildrenArray, ChildrenArray2 : JsonArray;
        StackArr: array[50] of JsonArray;
        StackObj: array[50] of JsonObject;
        StackIndent: array[50] of Integer;
        StackDepth: Integer;
        TaskLeaf: JsonObject;
        HeadingNode: JsonObject;
        FreshArr: JsonArray;
        PlanningObject, Root : JsonObject;
        PlanningArray, FilteredPlanningArray, DataArray : JsonArray;
        EventJobNos: List of [Code[20]]; // parallel to PlanningArray - EventJobNos.Get(i+1) is the Job No. for PlanningArray's i-th (0-based) element
        EvToken: JsonToken;
        EvIdx: Integer;
        OutText: Text;

        StartDateTxt: Text;
        EndDateTxt: Text;
        _DummyEndDate: Date;

        HasAssigned: Boolean;
        HasRequested: Boolean;
        AssignedStartTime: Time;
        AssignedEndTime: Time;
        RequestedStartTime: Time;
        RequestedEndTime: Time;
        EnvelopeStartTime: Time;
        EnvelopeEndTime: Time;
        SkillColorDict: Dictionary of [Code[20], Text];
        NextSkillPaletteIndex: Integer;

        JobRowCounts: Dictionary of [Code[20], Integer];
        JobOrder: List of [Code[20]];
        IncludedJobs: Dictionary of [Code[20], Boolean];
        IncludedJobsList: List of [Code[20]];
        RunningTotal: Integer;
        JN: Code[20];
    begin
        PlanninJsonTxt := '';
        RemainingJobFilter := '';
        if MaxRows <= 0 then
            MaxRows := 1; // always render at least the first Job's worth of sections

        ApplyProjectSchedulerDayPlanningFilters(DayPlanning, StartDate, EndDate, ResourceFilter, JobFilter, JobTaskFilter);

        // Same bulk Resource/Vendor prefetch as GetYUnitElementsJSON_Project (Part A) - see that
        // procedure's comment for why. Scoped to the FULL filtered period (not just the eventual
        // first page) since the main loop below still walks every matching Day Planning once, to
        // build TEMPJobTasks/row counts correctly - only the OUTPUT is paginated, not this scan.
        Clear(ResourceNameDict);
        Clear(VendorNameDict);
        Clear(ResourceNoSet);
        Clear(VendorNoSet);
        ApplyProjectSchedulerDayPlanningFilters(DayPlanningPrefetch, StartDate, EndDate, ResourceFilter, JobFilter, JobTaskFilter);
        if DayPlanningPrefetch.FindSet() then
            repeat
                if (DayPlanningPrefetch."Assigned Resource No." <> '') and not ResourceNoSet.Contains(DayPlanningPrefetch."Assigned Resource No.") then
                    ResourceNoSet.Add(DayPlanningPrefetch."Assigned Resource No.");
                if (DayPlanningPrefetch."Requested Resource No." <> '') and not ResourceNoSet.Contains(DayPlanningPrefetch."Requested Resource No.") then
                    ResourceNoSet.Add(DayPlanningPrefetch."Requested Resource No.");
                if (DayPlanningPrefetch."Vendor No." <> '') and not VendorNoSet.Contains(DayPlanningPrefetch."Vendor No.") then
                    VendorNoSet.Add(DayPlanningPrefetch."Vendor No.");
            until DayPlanningPrefetch.Next() = 0;
        if ResourceNoSet.Count() > 0 then begin
            ResourcePrefetch.Reset();
            ResourcePrefetch.SetFilter("No.", BuildCodeOrFilter(ResourceNoSet));
            if ResourcePrefetch.FindSet() then
                repeat
                    ResourceNameDict.Add(ResourcePrefetch."No.", ResourcePrefetch.Name);
                until ResourcePrefetch.Next() = 0;
        end;
        if VendorNoSet.Count() > 0 then begin
            VendorPrefetch.Reset();
            VendorPrefetch.SetFilter("No.", BuildCodeOrFilter(VendorNoSet));
            if VendorPrefetch.FindSet() then
                repeat
                    VendorNameDict.Add(VendorPrefetch."No.", VendorPrefetch.Name);
                until VendorPrefetch.Next() = 0;
        end;

        if DayPlanning.FindSet() then begin
            repeat
                if not TEMPJobTasks.Get(DayPlanning."Job No.", DayPlanning."Job Task No.") then begin
                    JobTasks.Get(DayPlanning."Job No.", DayPlanning."Job Task No.");
                    TEMPJobTasks := JobTasks;
                    TEMPJobTasks.insert();
                end;

                ResNo := '';
                ResName := '';
                if DayPlanning."Assigned Resource No." <> '' then
                    if ResourceNameDict.Get(DayPlanning."Assigned Resource No.", ResName) then
                        ResNo := DayPlanning."Assigned Resource No.";

                ReqResName := '';
                if DayPlanning."Requested Resource No." <> '' then
                    ResourceNameDict.Get(DayPlanning."Requested Resource No.", ReqResName);

                if AnchorDate = 0D then
                    CountToWeekNumber(DayPlanning."Plan Date", WeekTemp);

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
                PlanningObject.Add('text', TaskSchedulerEventBarText(DayPlanning.Skill, ResName, ReqResName,
                    DayPlanning."Job No." + '|' + DayPlanning."Job Task No." + ' (vacant)'));

                PlanningObject.Add('section_id', DayPlanning."Job No." + '|' + DayPlanning."Job Task No.");
                VenName := '';
                if DayPlanning."Vendor No." <> '' then
                    VendorNameDict.Get(DayPlanning."Vendor No.", VenName);
                PlanningObject.Add('details', VenName);

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
                PlanningObject.Add('skill', DayPlanning.Skill);
                PlanningObject.Add('requested_color', ResolveRequestedColor(DayPlanning.Skill, SkillColorDict, NextSkillPaletteIndex));

                PlanningArray.Add(PlanningObject);
                EventJobNos.Add(DayPlanning."Job No.");
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

        AddAncestorsToTemp(TEMPJobTasks);

        // Decide the page cutoff: count TEMPJobTasks rows per Job (the same rows the tree-build
        // below turns 1-for-1 into section nodes), then walk Jobs in their natural Job No. order
        // (matching the tree-build's own primary-key order) accumulating until MaxRows is
        // reached - the Job that pushes the total over the line is still fully included (never
        // split mid-job); every Job after it becomes RemainingJobFilter.
        TEMPJobTasks.Reset();
        if TEMPJobTasks.FindSet() then
            repeat
                if not JobRowCounts.ContainsKey(TEMPJobTasks."Job No.") then begin
                    JobRowCounts.Add(TEMPJobTasks."Job No.", 0);
                    JobOrder.Add(TEMPJobTasks."Job No.");
                end;
                JobRowCounts.Set(TEMPJobTasks."Job No.", JobRowCounts.Get(TEMPJobTasks."Job No.") + 1);
            until TEMPJobTasks.Next() = 0;

        RunningTotal := 0;
        foreach JN in JobOrder do
            if RunningTotal >= MaxRows then begin
                if RemainingJobFilter <> '' then
                    RemainingJobFilter += '|';
                RemainingJobFilter += JN;
            end else begin
                IncludedJobs.Add(JN, true);
                RunningTotal += JobRowCounts.Get(JN);
            end;

        // Events: only the included Jobs' events belong on this first page - the rest travel with
        // RemainingJobFilter to the background task.
        for EvIdx := 0 to PlanningArray.Count - 1 do begin
            PlanningArray.Get(EvIdx, EvToken);
            if IncludedJobs.ContainsKey(EventJobNos.Get(EvIdx + 1)) then
                FilteredPlanningArray.Add(EvToken);
        end;
        FilteredPlanningArray.WriteTo(PlanninJsonTxt);

        // Sections: identical stack-based tree-build to GetYUnitElementsJSON_Project, just scoped
        // to the included Jobs via a filter on TEMPJobTasks - so a page that fits within MaxRows
        // entirely (RemainingJobFilter = '') produces byte-identical output to the non-paged call.
        IncludedJobsList := IncludedJobs.Keys();
        if IncludedJobsList.Count() > 0 then
            TEMPJobTasks.SetFilter("Job No.", BuildCodeOrFilter(IncludedJobsList))
        else
            TEMPJobTasks.SetFilter("Job No.", '');

        if TEMPJobTasks.FindSet() then begin
            Clear(DataArray);
            CurrentJobNo := '';
            StackDepth := 0;
            repeat
                if TEMPJobTasks."Job No." <> CurrentJobNo then begin
                    if CurrentJobNo <> '' then begin
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

                while StackDepth > 0 do begin
                    if StackIndent[StackDepth] < TEMPJobTasks.Indentation then
                        break;
                    StackObj[StackDepth].Add('children', StackArr[StackDepth + 1]);
                    StackArr[StackDepth].Add(StackObj[StackDepth]);
                    StackDepth -= 1;
                end;

                if TEMPJobTasks."Job Task Type" = TEMPJobTasks."Job Task Type"::Posting then begin
                    Clear(TaskLeaf);
                    TaskLeaf.Add('key', TEMPJobTasks."Job No." + '|' + TEMPJobTasks."Job Task No.");
                    TaskLeaf.Add('label', StrSubstNo('%1 - %2', TEMPJobTasks."Job Task No.", TEMPJobTasks.Description));
                    StackArr[StackDepth + 1].Add(TaskLeaf);
                end else if (TEMPJobTasks."Job Task Type" = TEMPJobTasks."Job Task Type"::"End-Total") or
                            (TEMPJobTasks."Job Task Type" = TEMPJobTasks."Job Task Type"::Total) then begin
                    // skip closing markers
                end else begin
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
            Root.WriteTo(OutText);
            exit(OutText);
        end;
        exit('');
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
        ResScheduler: Page "Resource Scheduler - Calendar";
        EventIDList: List of [Text];
        JobNo: Code[20];
        TaskNo: Code[20];
        DayLineNo: Integer;
        MsgLbl: Label 'Day planning not found for Event ID: %1';
        NoAssignedResLbl: Label 'there is no Assigned resource no. on Day Planning';
    begin
        EventIDList := eventId.Split('|');
        JobNo := EventIDList.Get(1);
        TaskNo := EventIDList.Get(2);
        Evaluate(DayLineNo, EventIDList.Get(4));
        if DayPlanning.Get(JobNo, TaskNo, DayLineNo) then begin
            if DayPlanning."Assigned Resource No." <> '' then begin
                ResScheduler.SetResourceFilter(DayPlanning."Assigned Resource No.");
                ResScheduler.RunModal();
            end else
                Message(NoAssignedResLbl);
        end else
            Message(MsgLbl, eventId);
    end;

    /// <summary>
    /// Opens the DHX Scheduler - TimeLine (page 50706) filtered to the Skill of the day planning
    /// line linked to the given event ID (format: JobNo|JobTaskNo|DayNo|DayLineNo|ResNo|ResName).
    /// This is a Skill-only filter, independent of whether the row actually has an Assigned
    /// Resource - a Requested-only row (Assigned Resource No. blank) still opens, filtered to
    /// its Skill. Uses the Day Planning's own "Skill" field when set; otherwise falls back to the
    /// primary skill of the Assigned Resource No. (via SkillResScheduler_GetPrimarySkill) when
    /// there is one. Always opens the page - an unresolved Skill just means it opens unfiltered.
    /// Used by the right-click context menu "Open Res. Scheduler (Assigned) - Timeline" on an
    /// event.
    /// </summary>
    procedure OpenResSchedulerTimeline(eventId: Text)
    var
        DayPlanning: Record "Day Planning";
        ResCapacityScheduler: Page "DHX Scheduler - TimeLine";
        EventIDList: List of [Text];
        JobNo: Code[20];
        TaskNo: Code[20];
        DayLineNo: Integer;
        SkillCodeVal: Code[20];
        MsgLbl: Label 'Day planning not found for Event ID: %1';
    begin
        EventIDList := eventId.Split('|');
        JobNo := EventIDList.Get(1);
        TaskNo := EventIDList.Get(2);
        Evaluate(DayLineNo, EventIDList.Get(4));
        if DayPlanning.Get(JobNo, TaskNo, DayLineNo) then begin
            SkillCodeVal := DayPlanning.Skill;
            if (SkillCodeVal = '') and (DayPlanning."Assigned Resource No." <> '') then
                SkillCodeVal := SkillResScheduler_GetPrimarySkill(DayPlanning."Assigned Resource No.");
            ResCapacityScheduler.OpenSkillFiltered(SkillCodeVal);
            ResCapacityScheduler.RunModal();
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
        ResScheduler: Page "Resource Scheduler - Calendar";
        EventIDList: List of [Text];
        JobNo: Code[20];
        TaskNo: Code[20];
        DayLineNo: Integer;
        MsgLbl: Label 'Day planning not found for Event ID: %1';
        NoRequestedResLbl: Label 'there is no Requested resource no. on Day Planning';
    begin
        EventIDList := eventId.Split('|');
        JobNo := EventIDList.Get(1);
        TaskNo := EventIDList.Get(2);
        Evaluate(DayLineNo, EventIDList.Get(4));
        if DayPlanning.Get(JobNo, TaskNo, DayLineNo) then begin
            if DayPlanning."Requested Resource No." <> '' then begin
                ResScheduler.SetResourceFilter(DayPlanning."Requested Resource No.");
                ResScheduler.RunModal();
            end else
                Message(NoRequestedResLbl);
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
        NoRequestedResLbl: Label 'there is no Requested resource no. on Day Planning';
    begin
        EventIDList := eventId.Split('|');
        JobNo := EventIDList.Get(1);
        TaskNo := EventIDList.Get(2);
        Evaluate(DayLineNo, EventIDList.Get(4));
        if DayPlanning.Get(JobNo, TaskNo, DayLineNo) then begin
            if DayPlanning."Requested Resource No." <> '' then begin
                Resource.SetFilter("No.", DayPlanning."Requested Resource No.");
                Page.RunModal(Page::"Resource Card", Resource);
            end else
                Message(NoRequestedResLbl);
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
        NoAssignedResLbl: Label 'there is no Assigned resource no. on Day Planning';
    begin
        EventIDList := eventId.Split('|');
        JobNo := EventIDList.Get(1);
        TaskNo := EventIDList.Get(2);
        Evaluate(DayLineNo, EventIDList.Get(4));
        if DayPlanning.Get(JobNo, TaskNo, DayLineNo) then begin
            if DayPlanning."Assigned Resource No." <> '' then begin
                Resource.SetFilter("No.", DayPlanning."Assigned Resource No.");
                Page.RunModal(Page::"Resource Card", Resource);
            end else
                Message(NoAssignedResLbl);
        end else
            Message(MsgLbl, eventId);
    end;

    /// <summary>
    /// Opens the Day Planning Card (Opt) for the day planning line linked to the given event ID
    /// (format: JobNo|JobTaskNo|DayNo|DayLineNo|...).
    /// Used by the right-click context menu "Open Day Planning Card" on an event.
    /// </summary>
    procedure OpenDayPlanningCard(eventId: Text)
    var
        DayPlanning: Record "Day Planning";
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
        if DayPlanning.Get(JobNo, TaskNo, DayLineNo) then
            PAGE.Run(PAGE::"Day Planning Card Opt", DayPlanning)
        else
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
            DayPlanning.SetRange(Assigned, true);
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
        ColorConstants: Codeunit "Visual Default Settings";
        ColorHash: Integer;
        i: Integer;
        ColorValue: Text;
    begin
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
        exit(ColorConstants.GetResourceSchedulerFallbackColor(ColorHash));
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
            DayPlanning.SetRange(Assigned, true);
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
        AssignedDP.SetRange(Assigned, true);
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
    /// Resolves a Skill Code value to its display label: "Skill Code".Description when the
    /// record exists and has one, else the raw code (record exists but no Description, or the
    /// code doesn't resolve to a record at all), else '' when SkillCodeVal itself is blank.
    /// Shared by DayPlanningEventBarText and TaskSchedulerEventBarText so both the Resource
    /// Scheduler and Task Scheduler bars resolve Skill the same way.
    /// </summary>
    local procedure ResolveSkillLabel(SkillCodeVal: Code[20]): Text
    var
        SkillCode: Record "Skill Code";
    begin
        if SkillCodeVal = '' then
            exit('');
        if not SkillCode.Get(SkillCodeVal) then
            exit(SkillCodeVal);
        if SkillCode.Description <> '' then
            exit(SkillCode.Description);
        exit(SkillCode.Code);
    end;

    /// <summary>
    /// Task Scheduler (GetYUnitElementsJSON_Project) Day Planning bar text: "&lt;Skill&gt; |
    /// &lt;Resource Name&gt;" - Resource Name is dominantly the Assigned resource's name,
    /// falling back to the Requested resource's name when nothing is assigned yet. The " | "
    /// separator only appears when both halves are present; with no resource name at all the
    /// text is just the Skill label (no dangling " | "). Falls back to VacantFallback (the
    /// caller's "Job No.|Job Task No. (vacant)" text) only when NEITHER Skill nor a resource
    /// name is available, so a bar is never left with empty text.
    /// </summary>
    local procedure TaskSchedulerEventBarText(SkillCodeVal: Code[20]; AssignedResName: Text; RequestedResName: Text; VacantFallback: Text): Text
    var
        SkillLabel: Text;
        ResNameForText: Text;
    begin
        SkillLabel := ResolveSkillLabel(SkillCodeVal);
        if AssignedResName <> '' then
            ResNameForText := AssignedResName
        else
            ResNameForText := RequestedResName;

        if (SkillLabel <> '') and (ResNameForText <> '') then
            exit(SkillLabel + ' | ' + ResNameForText);
        if SkillLabel <> '' then
            exit(SkillLabel);
        if ResNameForText <> '' then
            exit(ResNameForText);
        exit(VacantFallback);
    end;

    /// <summary>
    /// Day Planning event bar text: "&lt;Skill&gt; | &lt;Job Task Description&gt;" - the Skill
    /// label is the row's own "Skill" field resolved through "Skill Code".Description (falling
    /// back to the raw code when the Skill Code record has no Description, or doesn't exist),
    /// and the Job Task Description comes from the "Job Task" record the row's "Job No."/"Job
    /// Task No." point at. Either half is dropped (no dangling " | ") when it can't be resolved,
    /// and when BOTH are unavailable this falls back to the old convention (row Description, then
    /// Assigned/Requested resource name, then a literal "Day Planning") so a bar is never left
    /// with empty text. Shared by SkillResScheduler_BuildDayPlanningJson and
    /// ResGroupResScheduler_BuildDayPlanningJson so both List-Type modes render bars identically.
    /// </summary>
    local procedure DayPlanningEventBarText(var DayPlanning: Record "Day Planning"; AssignedResName: Text; RequestedResName: Text): Text
    var
        JobTask: Record "Job Task";
        SkillLabel: Text;
        JobTaskDescription: Text;
    begin
        SkillLabel := ResolveSkillLabel(DayPlanning.Skill);

        if (DayPlanning."Job No." <> '') and (DayPlanning."Job Task No." <> '') then
            if JobTask.Get(DayPlanning."Job No.", DayPlanning."Job Task No.") then
                JobTaskDescription := JobTask.Description;

        if (SkillLabel <> '') and (JobTaskDescription <> '') then
            exit(SkillLabel + ' | ' + JobTaskDescription);
        if SkillLabel <> '' then
            exit(SkillLabel);
        if JobTaskDescription <> '' then
            exit(JobTaskDescription);

        if DayPlanning.Description <> '' then
            exit(DayPlanning.Description);
        if AssignedResName <> '' then
            exit(AssignedResName);
        if RequestedResName <> '' then
            exit(RequestedResName);
        exit('Day Planning');
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
        SkillColorDict: Dictionary of [Code[20], Text];
        NextSkillPaletteIndex: Integer;
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

                        EventText := DayPlanningEventBarText(DayPlanning, AssignedResName, RequestedResName);

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
                        JObj.Add('requested_color', ResolveRequestedColor(DayPlanning.Skill, SkillColorDict, NextSkillPaletteIndex));
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

    // =========================================================
    // Resource Scheduler (New) - "resourceschedule_with_capacity" add-in
    // (page 50706 "DHX Scheduler - TimeLine"). Alternate left-tree JSON
    // builders grouping by "Resource Group" (table 72) instead of Skill,
    // used when "Daily Optimizer Setup"."Resource Scheduler - List Type"
    // = "By Resource Group". Kept in its own region, prefixed
    // "ResGroupResScheduler_", mirroring the "SkillResScheduler_" region
    // above. Unlike Skill (a many-to-many relationship sourced from
    // "Resource Skill" registrations UNION Day-Planning-observed skills),
    // a Resource belongs to exactly one Resource Group via its own
    // "Resource Group No." field, so there is no combined-lookup
    // dictionary machinery, no "(*)" registered-vs-observed flag, and no
    // per-resource branch list to duplicate a Capacity bar onto - every
    // lookup here is a direct field read. The tree itself is master-data
    // driven (walks table 72 + each Resource's own field) and
    // deliberately NOT scoped to StartDate/EndDate, unlike the Skill
    // tree - a Resource Group with no Day Planning/Capacity activity in
    // the visible week still appears as long as it has at least one
    // matching Resource. The Open*/right-click procedures in the
    // "SkillResScheduler_" region above (OpenResourceCard,
    // OpenResourceSkills, OpenDayPlanningsForResource,
    // OpenTasksForResource, ShowCapacityForResource,
    // OpenDayPlanningByEventId, OpenCapacityByEventId, OpenTaskByEventId,
    // OpenResourceByEventId) and SkillResScheduler_ExtractResourceNo are
    // all reused as-is by page 50706 in Resource-Group mode - they only
    // operate on a plain Resource No./RecordId, never on the tree's
    // grouping scheme, so they need no Resource-Group counterpart.
    // =========================================================

    /// <summary>
    /// Resolves the Resource Group tree branch suffix for a Resource No. - that resource's own
    /// "Resource Group No." field when it is set AND resolves to an existing "Resource Group"
    /// record, else the sentinel "~NONE~" (unknown resource, blank field, or a Resource Group
    /// code that no longer exists) - same bucket rule as ResGroupResScheduler_BuildTreeJson's
    /// leading "None" node. Shared by
    /// ResGroupResScheduler_BuildCapacityJson and ResGroupResScheduler_BuildDayPlanningJson so a
    /// bar's section_id always matches the tree branch actually built for that resource.
    /// </summary>
    local procedure ResGroupResScheduler_GetSectionSuffix(ResNo: Code[20]): Code[20]
    var
        Res: Record Resource;
        ResGroup: Record "Resource Group";
    begin
        if not Res.Get(ResNo) then
            exit('~NONE~');
        if Res."Resource Group No." = '' then
            exit('~NONE~');
        if not ResGroup.Get(Res."Resource Group No.") then
            exit('~NONE~');
        exit(Res."Resource Group No.");
    end;

    /// <summary>
    /// Builds the left-panel tree grouped by "Resource Group" (table 72) instead of Skill - one
    /// top-level node per Resource Group record, with the Resources whose own "Resource Group
    /// No." field equals that group's "No." as leaf children. A Resource has exactly one
    /// Resource Group, so - unlike SkillResScheduler_BuildTreeJson - there is no combined
    /// registered/observed lookup and no " (*)" flag: membership is a direct field read.
    /// Resources with a blank "Resource Group No.", or one that does not resolve to an existing
    /// Resource Group record, are grouped under a leading "None" node - built and added first so
    /// it always sorts to the top of the tree, ahead of the per-Resource-Group nodes. Group/
    /// Resource nodes with no (matching) children are omitted entirely, same convention as
    /// SkillResScheduler_BuildTreeJson. This tree is master-data driven (walks table 72 + each
    /// Resource's own field) and is NOT scoped to a date range - a Resource Group with zero
    /// Day Planning/Capacity activity in the visible week still appears as long as it has at
    /// least one matching Resource.
    ///
    /// Leaf key is the composite "<Resource No.>|<Resource Group No.>" (or "<Resource No.>|
    /// ~NONE~" for the None bucket) - structurally parallel to the Skill tree's "<Resource No.>|
    /// <Skill Code>" leaf key, so SkillResScheduler_ExtractResourceNo (splits on '|', takes part
    /// 1) works unchanged on either key style. Group node key is "GROUP|" + Resource Group No.
    /// (or "GROUP|~NONE~"), which can never collide with a leaf key, mirroring the Skill tree's
    /// "SKILL|" prefix convention.
    ///
    /// SkillFilter (blank = no restriction) additionally requires each resource to match
    /// ResourceMatchesSkillFilter - i.e. have a "Resource Skill" registration for that Skill -
    /// same per-resource check used elsewhere in this codeunit (e.g. ResScheduler_BuildResourcesJson).
    /// This lets a caller like OpenResSchedulerTimeline narrow the Resource-Group tree
    /// down to just the resources carrying one specific Skill, while still grouping by Resource
    /// Group rather than forcing Skill mode.
    /// </summary>
    procedure ResGroupResScheduler_BuildTreeJson(ResourceFilter: Text; SkillFilter: Text): Text
    var
        ResGroup: Record "Resource Group";
        Res: Record Resource;
        TempNoGroupResource: Record Resource temporary;
        GroupObj: JsonObject;
        ResObj: JsonObject;
        ChildrenArray: JsonArray;
        DataArray: JsonArray;
        Root: JsonObject;
        OutText: Text;
    begin
        // Leading "None" node - blank "Resource Group No." or a code that no longer resolves to
        // an existing Resource Group record (e.g. the group was deleted after being assigned to
        // the resource). Built and added first so it always sorts to the top of the tree.
        Res.Reset();
        if ResourceFilter <> '' then
            Res.SetFilter("No.", ResourceFilter)
        else
            Res.SetFilter("No.", '<>%1', '');
        if Res.FindSet() then
            repeat
                if (not SkillResScheduler_IsPlaceholderResource(Res."No.", Res)) and ResourceMatchesSkillFilter(Res."No.", SkillFilter) then
                    if (Res."Resource Group No." = '') or (not ResGroup.Get(Res."Resource Group No.")) then begin
                        TempNoGroupResource := Res;
                        TempNoGroupResource.Insert();
                    end;
            until Res.Next() = 0;

        if TempNoGroupResource.FindSet() then begin
            Clear(ChildrenArray);
            repeat
                Clear(ResObj);
                ResObj.Add('key', TempNoGroupResource."No." + '|~NONE~');
                ResObj.Add('label', TempNoGroupResource.Name);
                ResObj.Add('category', 'Resource');
                ChildrenArray.Add(ResObj);
            until TempNoGroupResource.Next() = 0;

            Clear(GroupObj);
            GroupObj.Add('key', 'GROUP|~NONE~');
            GroupObj.Add('label', 'None');
            GroupObj.Add('category', 'Group');
            GroupObj.Add('open', true);
            GroupObj.Add('children', ChildrenArray);
            DataArray.Add(GroupObj);
        end;

        ResGroup.Reset();
        if ResGroup.FindSet() then
            repeat
                Clear(ChildrenArray);
                Res.Reset();
                Res.SetRange("Resource Group No.", ResGroup."No.");
                if ResourceFilter <> '' then
                    Res.SetFilter("No.", ResourceFilter);
                if Res.FindSet() then
                    repeat
                        if (not SkillResScheduler_IsPlaceholderResource(Res."No.", Res)) and ResourceMatchesSkillFilter(Res."No.", SkillFilter) then begin
                            Clear(ResObj);
                            ResObj.Add('key', Res."No." + '|' + ResGroup."No.");
                            ResObj.Add('label', Res.Name);
                            ResObj.Add('category', 'Resource');
                            ChildrenArray.Add(ResObj);
                        end;
                    until Res.Next() = 0;

                if ChildrenArray.Count() > 0 then begin
                    Clear(GroupObj);
                    GroupObj.Add('key', 'GROUP|' + ResGroup."No.");
                    GroupObj.Add('label', ResGroup.Name);
                    GroupObj.Add('category', 'Group');
                    GroupObj.Add('open', true);
                    GroupObj.Add('children', ChildrenArray);
                    DataArray.Add(GroupObj);
                end;
            until ResGroup.Next() = 0;

        Clear(Root);
        Root.Add('data', DataArray);
        Root.WriteTo(OutText);
        exit(OutText);
    end;

    /// <summary>
    /// Emits a single Capacity JSON event for one Resource/Date onto that resource's own
    /// Resource Group branch (or the "~NONE~" bucket) - the Resource Group tree's equivalent of
    /// SkillResScheduler_EmitCapacityEvents, simplified to a single emission per call since a
    /// resource belongs to exactly one Resource Group (no SkillFilter-style branch list to
    /// iterate/duplicate onto).
    /// </summary>
    local procedure ResGroupResScheduler_EmitCapacityEvent(var JArray: JsonArray; ResNo: Code[20]; CapDate: Date; StartTxt: Text; EndTxt: Text; Hours: Decimal)
    var
        JObj: JsonObject;
        SectionSuffix: Code[20];
    begin
        SectionSuffix := ResGroupResScheduler_GetSectionSuffix(ResNo);
        Clear(JObj);
        JObj.Add('id', 'CAP|' + ResNo + '|' + Format(CapDate, 0, '<Year4><Month,2><Day,2>') + '|' + SectionSuffix);
        JObj.Add('resource_id', ResNo);
        JObj.Add('section_id', ResNo + '|' + SectionSuffix);
        JObj.Add('start_date', StartTxt);
        JObj.Add('end_date', EndTxt);
        JObj.Add('text', 'Capacity');
        JObj.Add('classname', 'event-capacity');
        JObj.Add('type', 'capacity');
        JObj.Add('hours', Hours);
        JArray.Add(JObj);
    end;

    /// <summary>
    /// Aggregated Capacity events (one bar per Resource/Date, summed Capacity, earliest Start
    /// Time - same aggregation as SkillResScheduler_BuildCapacityJson) for the Resource Group
    /// tree. Each resource has exactly one Resource Group, so - unlike
    /// SkillResScheduler_BuildCapacityJson/SkillResScheduler_EmitCapacityEvents - there is no
    /// combined-skill lookup to pre-build and no branch list to duplicate a bar onto:
    /// section_id is resolved directly from the row resource's own "Resource Group No." field
    /// via ResGroupResScheduler_GetSectionSuffix.
    ///
    /// "Res. Capacity Entry" has no Skill field of its own, so SkillFilter (blank = no
    /// restriction) is applied per-row via ResourceMatchesSkillFilter against each row's own
    /// Resource No. - same convention SkillResScheduler_BuildCapacityJson uses, just without the
    /// combined-skill-set lookup since here a single Resource-Skill-registration check is enough.
    /// A non-matching row is simply never aggregated/emitted; safe because the aggregation state
    /// (LastResNo/LastDate/AggCapacity) is only ever touched for rows that pass the check.
    /// </summary>
    procedure ResGroupResScheduler_BuildCapacityJson(ResourceFilter: Text; SkillFilter: Text; StartDate: Date; EndDate: Date): Text
    var
        ResCap: Record "Res. Capacity Entry";
        TempResCap: Record "Res. Capacity Entry" temporary;
        JArray: JsonArray;
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
                if ResourceMatchesSkillFilter(ResCap."Resource No.", SkillFilter) then
                    if (ResCap."Resource No." <> LastResNo) or (ResCap."Date" <> LastDate) then begin
                        if (LastResNo <> '') and (AggCapacity > 0) then begin
                            TempResCap.Init();
                            TempResCap."Resource No." := LastResNo;
                            TempResCap."Date" := LastDate;
                            TempResCap."Start Time" := AggStartTime;
                            GetStartEndTxt(TempResCap, AggCapacity, StartDateTimeStr, EndDateTimeStr);
                            if (StartDateTimeStr <> '') and (EndDateTimeStr <> '') then
                                ResGroupResScheduler_EmitCapacityEvent(JArray, LastResNo, LastDate, StartDateTimeStr, EndDateTimeStr, AggCapacity);
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
            if (StartDateTimeStr <> '') and (EndDateTimeStr <> '') then
                ResGroupResScheduler_EmitCapacityEvent(JArray, LastResNo, LastDate, StartDateTimeStr, EndDateTimeStr, AggCapacity);
        end;

        Clear(JRoot);
        JRoot.Add('data', JArray);
        JRoot.WriteTo(Result);
        exit(Result);
    end;

    /// <summary>
    /// One event per Day Planning row (Plan Date within [StartDate,EndDate]) placed on the
    /// Assigned Resource's row (falling back to the Requested Resource's row when nothing is
    /// assigned yet), same envelope/bar-shape logic as SkillResScheduler_BuildDayPlanningJson -
    /// only the section_id computation differs: instead of the row's own Skill, the bar targets
    /// the row resource's own Resource Group branch (or "~NONE~") via
    /// ResGroupResScheduler_GetSectionSuffix, since Resource Group is a single-valued field on
    /// the resource rather than a per-row tag. There is no Resource-Group-filter equivalent of
    /// SkillFilter here - narrowing by group is done by collapsing/expanding the tree branch on
    /// the client, not via a server-side filter parameter.
    ///
    /// SkillFilter (blank = no restriction) is applied directly against Day Planning's own
    /// "Skill" field - a table filter, same as SkillResScheduler_BuildDayPlanningJson - so only
    /// rows tagged with the matching Skill are emitted, independent of which Resource Group the
    /// row's resource belongs to.
    /// </summary>
    procedure ResGroupResScheduler_BuildDayPlanningJson(ResourceFilter: Text; SkillFilter: Text; JobNoFilter: Text; JobTaskNoFilter: Text; StartDate: Date; EndDate: Date): Text
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
        SectionSuffix: Code[20];
        SkillColorDict: Dictionary of [Code[20], Text];
        NextSkillPaletteIndex: Integer;
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

                        EventText := DayPlanningEventBarText(DayPlanning, AssignedResName, RequestedResName);

                        SectionSuffix := ResGroupResScheduler_GetSectionSuffix(RowResourceNo);

                        Clear(JObj);
                        JObj.Add('id', Format(DayPlanning.RecordId));
                        JObj.Add('resource_id', RowResourceNo);
                        JObj.Add('section_id', RowResourceNo + '|' + SectionSuffix);
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
                        JObj.Add('requested_color', ResolveRequestedColor(DayPlanning.Skill, SkillColorDict, NextSkillPaletteIndex));
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
    /// Resolves the per-event "requested" segment color for a scheduler bar (projectschedule
    /// page 50621 and resourceschedule_with_capacity page 50706), reusing the exact same color
    /// source as the "Requested Hours vs Capacity" daily bar-chart factbox: the "Skill Code"
    /// master's own "Bar Color" override (tableext 50609, field 50600), falling back to
    /// codeunit "Color Constants Opti." (50609)'s fixed 5-color palette when blank - called
    /// cross-codeunit via its public GetSkillBarColor rather than duplicating the palette here.
    /// Codeunit 50609 is the single authoritative copy of this palette/lookup logic, also used
    /// (via thin forwarding wrappers) by codeunit 50662's GetSkillSeriesColor and codeunit
    /// 50608's own GetSkillBarColor - called directly here rather than through either of those
    /// forwards since this procedure already did its own palette-index/memoization bookkeeping
    /// and only ever needed the underlying single-color lookup.
    ///
    /// Each DISTINCT, non-blank skill code encountered while building ONE JSON payload gets its
    /// own palette slot, assigned in first-encountered order (mirrors codeunit 50662's
    /// SkillPaletteIdx loop) - the caller supplies SkillColorDict/NextPaletteIndex as fresh local
    /// variables for each JSON-build call, so numbering naturally resets per call rather than
    /// accumulating globally. A blank SkillCode resolves to a blank color so the caller omits
    /// the JSON key and the bar falls back to wrapper.js's own "--dp-color-requested" CSS
    /// default, instead of silently occupying a palette slot for "no skill".
    ///
    /// GetSkillBarColor's own parameter is Code[10] - narrower than Day Planning's "Skill" field
    /// (Code[20]) - but "Skill" has TableRelation = "Skill Code", whose master "Code" field is
    /// itself Code[10] (confirmed live via al_symbolsearch), so any value that ever validated
    /// successfully already fits within 10 characters; the CopyStr below is a safety truncation
    /// for already-valid data, not a real loss of precision.
    /// </summary>
    local procedure ResolveRequestedColor(SkillCode: Code[20]; var SkillColorDict: Dictionary of [Code[20], Text]; var NextPaletteIndex: Integer): Text
    var
        ColorConstants: Codeunit "Visual Default Settings";
        ResolvedColor: Text;
    begin
        if SkillCode = '' then
            exit('');
        if SkillColorDict.Get(SkillCode, ResolvedColor) then
            exit(ResolvedColor);
        ResolvedColor := ColorConstants.GetSkillBarColor(CopyStr(SkillCode, 1, 10), NextPaletteIndex);
        SkillColorDict.Add(SkillCode, ResolvedColor);
        NextPaletteIndex += 1;
        exit(ResolvedColor);
    end;

    /// <summary>
    /// Builds a {code, fontColor, borderColor} array - one entry per "Skill Code" - for the
    /// scheduler-timeline add-ins (projectschedule/50621, resourceschedule_with_capacity/50706,
    /// poolresourceschedule/50600) to apply per-skill bar text/border colour via a
    /// dynamically-injected per-skill &lt;style&gt; block, the same idiom
    /// src/dhx/dayplanning_sequence/codeunit_50695_DayPlanningSequenceMgt.al's
    /// BuildSectionsAndEventsJson already uses (embedding fontColor/borderColor per section)
    /// but as a standalone lookup array instead of embedded per-section/per-event JSON, since
    /// these add-ins' events aren't grouped into skill-named sections the way
    /// dayplanning_sequence's are. Shared by all three callers rather than duplicated per page,
    /// mirroring how ResolveRequestedColor above is already shared for the per-skill fill colour.
    /// Uses the same PaletteIndex-per-skill-code convention as ResolveRequestedColor/
    /// GetSkillBarColor so an unconfigured skill's border (falling back to GetSkillBorderColor's
    /// own fill-colour fallback) stays visually consistent with that same skill's already-resolved
    /// background colour elsewhere on the same page.
    /// </summary>
    procedure BuildSkillFontBorderColorsJson(): Text
    var
        SkillCodeRec: Record "Skill Code";
        ColorConstants: Codeunit "Visual Default Settings";
        SkillsArray: JsonArray;
        SkillObj: JsonObject;
        PaletteIndex: Integer;
        ResultTxt: Text;
    begin
        if SkillCodeRec.FindSet() then
            repeat
                Clear(SkillObj);
                SkillObj.Add('code', SkillCodeRec.Code);
                SkillObj.Add('fontColor', ColorConstants.GetSkillFontColor(SkillCodeRec.Code));
                SkillObj.Add('borderColor', ColorConstants.GetSkillBorderColor(SkillCodeRec.Code, PaletteIndex));
                SkillsArray.Add(SkillObj);
                PaletteIndex += 1;
            until SkillCodeRec.Next() = 0;
        SkillsArray.WriteTo(ResultTxt);
        exit(ResultTxt);
    end;

    // ================================================================================
    // "ReqAssign_" region - Request/Assignment Planner (page 50710 "DHX Request Assignment
    // Board", controladdin DHXRequestAssignmentAddin, src/dhx/request_assignment). Builds the
    // single combined JSON payload the JS-side port consumes (workdays/resources/dayTaskLines/
    // capacitySlots/skillColors/statusColors) and applies the seven drag-and-drop/accept-reject/
    // reset commit events it raises back. "Sequence" has no literal field anywhere - it is a distinct
    // (Job No., Job Task No., Skill) combination, keyed as "<Job No.>|<Job Task No.>|<Skill>" (see
    // sequenceKey below); a single day's bar ("Day Task Line") is keyed as
    // "<Job No.>|<Job Task No.>|<Day Line No.>" (see ReqAssign_ParseId), mirroring this codeunit's
    // existing pipe-joined EventId conventions used elsewhere (e.g. SkillResScheduler_*).
    // ================================================================================

    /// <summary>
    /// Builds the single combined JSON payload consumed by controladdin
    /// DHXRequestAssignmentAddin.SetPlanningData - one JsonObject with top-level arrays
    /// "workdays", "resources", "dayTaskLines", "capacitySlots", "skillColors" and a
    /// "statusColors" object. Called by page 50710's ControlReady and its shared
    /// RebuildAndSetPlanningData (Refresh action + OnRequestReset), all with a fresh 30-workday
    /// window starting at Today().
    ///
    /// "workdays" is the single authoritative 0-based-index list (every Mon-Fri date from
    /// StartDate to EndDate inclusive, as "yyyy-MM-dd" strings, in order) that BOTH
    /// dayTaskLines[].dayIndex and capacitySlots[].dayIndex reference - built once here
    /// (ReqAssign_BuildWorkdayIndexMap) and threaded into both builders below so they can never
    /// disagree about what index a given date maps to.
    /// </summary>
    procedure ReqAssign_BuildPlanningDataJson(StartDate: Date; EndDate: Date): Text
    var
        RootObj: JsonObject;
        StatusColorsObj: JsonObject;
        OkStatusObj: JsonObject;
        WorkdayIndexMap: Dictionary of [Date, Integer];
        WorkdaysArr: JsonArray;
        OutTxt: Text;
    begin
        ReqAssign_BuildWorkdayIndexMap(StartDate, EndDate, WorkdayIndexMap, WorkdaysArr);

        OkStatusObj.Add('backgroundColor', ReqAssignOkStatusBackgroundColorTok);
        OkStatusObj.Add('textColor', ReqAssignOkStatusTextColorTok);
        StatusColorsObj.Add('ok', OkStatusObj);

        RootObj.Add('workdays', WorkdaysArr);
        RootObj.Add('resources', ReqAssign_BuildResourcesJson());
        RootObj.Add('dayTaskLines', ReqAssign_BuildDayTaskLinesJson(StartDate, EndDate, WorkdayIndexMap));
        RootObj.Add('capacitySlots', ReqAssign_BuildCapacitySlotsJson(StartDate, EndDate, WorkdayIndexMap));
        RootObj.Add('skillColors', ReqAssign_BuildSkillColorsJson());
        RootObj.Add('statusColors', StatusColorsObj);
        // Part B.1 - the explicit 30-workday scope cutoff (see page 50710's GetDefaultWindow,
        // which computes this SAME EndDate). wrapper.js's defaultGlobalSelectionEndDate() used to
        // re-derive this by scanning ALL of dayTaskLines for distinct dates - a real hazard once
        // Part B.2 pagination means the client may only ever see a subset of dayTaskLines at once.
        // Sending it explicitly makes every later pagination decision safe by construction; the
        // scan-based derivation stays in wrapper.js only as a defensive fallback.
        RootObj.Add('scopeEndDate', ReqAssign_FormatIsoDate(EndDate));

        RootObj.WriteTo(OutTxt);
        exit(OutTxt);
    end;

    /// <summary>
    /// Paged variant of ReqAssign_BuildPlanningDataJson (Part B.2) - identical payload shape/keys,
    /// used by page 50710's synchronous first load. "resources"/"capacitySlots"/"workdays"/
    /// "skillColors"/"statusColors"/"scopeEndDate" are always sent in full (cheap - dozens/hundreds
    /// of entries, never the cost driver); only "dayTaskLines" is paginated, and only by whole
    /// sequenceKey GROUPS (see ReqAssign_BuildDayTaskLinesJson_Paged) - the group that crosses
    /// MaxLines is still included whole, since sequenceKey is the atomic unit wrapper.js's
    /// rebuildRequestTree()/pendingSequences/accept-reject/drag all operate on and must never see
    /// split across two loads. RemainingSequenceKeys (a JSON array of sequenceKey strings, blank ''
    /// if nothing remains) is what the caller threads into
    /// CurrPage.EnqueueBackgroundTask(Codeunit::"ReqAssign BG Day Task Lines", ...).
    /// </summary>
    procedure ReqAssign_BuildPlanningDataJson_Paged(StartDate: Date; EndDate: Date; MaxLines: Integer; var RemainingSequenceKeys: Text): Text
    var
        RootObj: JsonObject;
        StatusColorsObj: JsonObject;
        OkStatusObj: JsonObject;
        WorkdayIndexMap: Dictionary of [Date, Integer];
        WorkdaysArr: JsonArray;
        FirstPageLinesArr: JsonArray;
        OutTxt: Text;
    begin
        ReqAssign_BuildWorkdayIndexMap(StartDate, EndDate, WorkdayIndexMap, WorkdaysArr);

        OkStatusObj.Add('backgroundColor', ReqAssignOkStatusBackgroundColorTok);
        OkStatusObj.Add('textColor', ReqAssignOkStatusTextColorTok);
        StatusColorsObj.Add('ok', OkStatusObj);

        ReqAssign_BuildDayTaskLinesJson_Paged(StartDate, EndDate, WorkdayIndexMap, MaxLines, FirstPageLinesArr, RemainingSequenceKeys);

        RootObj.Add('workdays', WorkdaysArr);
        RootObj.Add('resources', ReqAssign_BuildResourcesJson());
        RootObj.Add('dayTaskLines', FirstPageLinesArr);
        RootObj.Add('capacitySlots', ReqAssign_BuildCapacitySlotsJson(StartDate, EndDate, WorkdayIndexMap));
        RootObj.Add('skillColors', ReqAssign_BuildSkillColorsJson());
        RootObj.Add('statusColors', StatusColorsObj);
        RootObj.Add('scopeEndDate', ReqAssign_FormatIsoDate(EndDate));

        RootObj.WriteTo(OutTxt);
        exit(OutTxt);
    end;

    /// <summary>
    /// Builds the "resources" array: every non-blocked Resource, with its registered skills
    /// ("Resource Skill" where Type=Resource, "No."=Resource No. - same filter shape used
    /// elsewhere in this codeunit, e.g. SkillResScheduler_BuildCombinedSkillLookup's Source 1).
    /// </summary>
    local procedure ReqAssign_BuildResourcesJson(): JsonArray
    var
        Res: Record Resource;
        ResSkill: Record "Resource Skill";
        ResourcesArr: JsonArray;
        SkillsArr: JsonArray;
        ResObj: JsonObject;
        MoreSkills: Boolean;
    begin
        // Part A perf fix - this was a genuine N+1 (a fresh ResSkill.SetRange/FindSet PER
        // resource). Both Res and "Resource Skill" are already scanned in their own primary-key
        // order (No.; Type/No./Skill Code) with no SetCurrentKey override, so after filtering
        // "Resource Skill" to Type=Resource, its rows are guaranteed contiguous per resource "No."
        // - a single merge-join pass over both single sorted FindSets (one prefetch, not one per
        // resource) replaces the old per-resource re-query, same "prefetch once, look up in one
        // pass" idiom already used by ReqAssign_BuildDayTaskLinesJson's JobDescCache/
        // JobTaskDescCache. Confirmed via grep that ReqAssign_* has no other N+1.
        ResSkill.SetRange(Type, ResSkill.Type::Resource);
        ResSkill.SetLoadFields("No.", "Skill Code");
        MoreSkills := ResSkill.FindSet();

        Res.SetLoadFields("No.", Name, Blocked);
        Res.SetRange(Blocked, false);
        if Res.FindSet() then
            repeat
                Clear(SkillsArr);
                // Catch the skill cursor up to (or past, if this resource has none) the current
                // resource - skill rows for a resource excluded above (Blocked) or with no
                // matching Res row at all are simply skipped over, never re-visited.
                while MoreSkills and (ResSkill."No." < Res."No.") do
                    MoreSkills := ResSkill.Next() <> 0;
                while MoreSkills and (ResSkill."No." = Res."No.") do begin
                    SkillsArr.Add(ResSkill."Skill Code");
                    MoreSkills := ResSkill.Next() <> 0;
                end;

                Clear(ResObj);
                ResObj.Add('key', Res."No.");
                ResObj.Add('label', Res.Name);
                ResObj.Add('skills', SkillsArr);
                ResourcesArr.Add(ResObj);
            until Res.Next() = 0;
        exit(ResourcesArr);
    end;

    /// <summary>
    /// Builds the "dayTaskLines" array: one entry per Day Planning row with "Plan Date" in
    /// [StartDate, EndDate] - any Job/Task/Skill, no pre-filtering (the JS side groups these into
    /// sequences/tree nodes client-side via sequenceKey). Job/Job Task descriptions are cached
    /// per-call (Dictionary keyed by Job No. / "Job No.|Job Task No.") since this can run over
    /// 1000+ rows for a 30-workday window and the same Job/Job Task repeats across many rows.
    ///
    /// dayIndex is resolved from the SAME WorkdayIndexMap the caller (ReqAssign_
    /// BuildPlanningDataJson) also threads into ReqAssign_BuildCapacitySlotsJson - both sides
    /// always agree on what index a given date maps to, since neither computes its own
    /// independent offset. A Plan Date that isn't itself a Mon-Fri date (not expected in normal
    /// data - Day Planning rows are only ever created on workdays - but not enforced at the table
    /// level either) resolves to -1 rather than being dropped, so the line itself is never lost.
    /// </summary>
    local procedure ReqAssign_BuildDayTaskLinesJson(StartDate: Date; EndDate: Date; var WorkdayIndexMap: Dictionary of [Date, Integer]): JsonArray
    var
        DayPlanning: Record "Day Planning";
        JobDescCache: Dictionary of [Code[20], Text];
        JobTaskDescCache: Dictionary of [Text, Text];
        LinesArr: JsonArray;
        SequenceKeyTxt: Text;
    begin
        DayPlanning.SetRange("Plan Date", StartDate, EndDate);
        DayPlanning.SetLoadFields("Job No.", "Job Task No.", "Day Line No.", "Plan Date", Skill,
            "Start Time Requested", "End Time Requested", "Start Time Assigned", "End Time Assigned",
            "Assigned Resource No.", "Sequence No.");
        if DayPlanning.FindSet() then
            repeat
                LinesArr.Add(ReqAssign_BuildDayTaskLineObj(DayPlanning, JobDescCache, JobTaskDescCache, WorkdayIndexMap, SequenceKeyTxt));
            until DayPlanning.Next() = 0;
        exit(LinesArr);
    end;

    /// <summary>
    /// Builds ONE "dayTaskLines" entry's JsonObject for a single already-loaded Day Planning row -
    /// the shared core behind ReqAssign_BuildDayTaskLinesJson (full/unpaged), ReqAssign_
    /// BuildDayTaskLinesJson_Paged (first page) and ReqAssign_BuildDayTaskLinesJson_ForKeys
    /// (background-task remainder, Part B.2/B.3) - extracted so all three build byte-for-byte
    /// identical line JSON for the same row instead of maintaining three copies of this logic.
    /// JobDescCache/JobTaskDescCache are threaded through by the caller so the per-Job/Job-Task
    /// description lookup stays cached across the whole call, not per-line. Also returns the
    /// line's own SequenceKeyTxt via var parameter - every paginating caller needs it for
    /// whole-sequence grouping/filtering; ReqAssign_BuildDayTaskLinesJson itself just discards it.
    /// </summary>
    local procedure ReqAssign_BuildDayTaskLineObj(var DayPlanning: Record "Day Planning"; var JobDescCache: Dictionary of [Code[20], Text]; var JobTaskDescCache: Dictionary of [Text, Text]; var WorkdayIndexMap: Dictionary of [Date, Integer]; var SequenceKeyTxt: Text): JsonObject
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        LineObj: JsonObject;
        ProjectName: Text;
        TaskName: Text;
        TaskCacheKey: Text;
        IdTxt: Text;
        ReqStart: Decimal;
        ReqDuration: Decimal;
        AssignedStart: Decimal;
        AssignedDuration: Decimal;
        DayIndex: Integer;
    begin
        if not JobDescCache.ContainsKey(DayPlanning."Job No.") then
            if Job.Get(DayPlanning."Job No.") then
                JobDescCache.Add(DayPlanning."Job No.", Job.Description)
            else
                JobDescCache.Add(DayPlanning."Job No.", '');
        ProjectName := JobDescCache.Get(DayPlanning."Job No.");

        TaskCacheKey := DayPlanning."Job No." + '|' + DayPlanning."Job Task No.";
        if not JobTaskDescCache.ContainsKey(TaskCacheKey) then
            if JobTask.Get(DayPlanning."Job No.", DayPlanning."Job Task No.") then
                JobTaskDescCache.Add(TaskCacheKey, JobTask.Description)
            else
                JobTaskDescCache.Add(TaskCacheKey, '');
        TaskName := JobTaskDescCache.Get(TaskCacheKey);

        IdTxt := DayPlanning."Job No." + '|' + DayPlanning."Job Task No." + '|' + Format(DayPlanning."Day Line No.");
        // Includes "Sequence No." (table 50610 field 9, codeunit 50695 "Day Planning
        // Sequence Mgt." owns its assignment) so two independent threads sharing the same
        // [Job No., Job Task No., Skill] - e.g. "Elektrisch - Seq 1" and "- Seq 2" from the
        // Day Planning Sequence add-in - render as separate rows here too, instead of
        // collapsing into one. Legacy rows still holding "Sequence No." = 0 (inserted
        // before this field existed and not yet repaired) will still collapse together
        // under "...|0" until report 50600 "RepairData"'s
        // RepairSequenceNoOnAllDayPlannings is run.
        SequenceKeyTxt := DayPlanning."Job No." + '|' + DayPlanning."Job Task No." + '|' + DayPlanning.Skill + '|' + Format(DayPlanning."Sequence No.");

        if DayPlanning."Start Time Requested" <> 0T then
            ReqStart := ReqAssign_TimeToDecimalHours(DayPlanning."Start Time Requested")
        else
            ReqStart := 0;

        if (DayPlanning."Start Time Requested" <> 0T) and (DayPlanning."End Time Requested" <> 0T) then begin
            ReqDuration := ReqAssign_TimeToDecimalHours(DayPlanning."End Time Requested") - ReqStart;
            if ReqDuration < 0 then
                ReqDuration := 0;
        end else
            ReqDuration := 0;

        if DayPlanning."Start Time Assigned" <> 0T then
            AssignedStart := ReqAssign_TimeToDecimalHours(DayPlanning."Start Time Assigned")
        else
            AssignedStart := ReqStart;

        if (DayPlanning."Start Time Assigned" <> 0T) and (DayPlanning."End Time Assigned" <> 0T) then begin
            AssignedDuration := ReqAssign_TimeToDecimalHours(DayPlanning."End Time Assigned") - AssignedStart;
            if AssignedDuration < 0 then
                AssignedDuration := 0;
        end else
            AssignedDuration := ReqDuration;

        if not WorkdayIndexMap.Get(DayPlanning."Plan Date", DayIndex) then
            DayIndex := -1;

        LineObj.Add('id', IdTxt);
        LineObj.Add('projectId', DayPlanning."Job No.");
        LineObj.Add('projectName', ProjectName);
        LineObj.Add('taskId', DayPlanning."Job Task No.");
        LineObj.Add('taskName', TaskName);
        LineObj.Add('sequenceKey', SequenceKeyTxt);
        LineObj.Add('sequenceNo', DayPlanning."Sequence No.");
        LineObj.Add('requiredSkill', DayPlanning.Skill);
        LineObj.Add('date', ReqAssign_FormatIsoDate(DayPlanning."Plan Date"));
        LineObj.Add('dayIndex', DayIndex);
        LineObj.Add('requestedStart', ReqStart);
        LineObj.Add('requestedDuration', ReqDuration);
        LineObj.Add('assignedStart', AssignedStart);
        LineObj.Add('assignedDuration', AssignedDuration);
        LineObj.Add('assignedResource', DayPlanning."Assigned Resource No.");
        LineObj.Add('sequenceAccepted', false);
        exit(LineObj);
    end;

    /// <summary>
    /// Paged variant of ReqAssign_BuildDayTaskLinesJson (Part B.2) - builds the same per-line JSON
    /// (via the shared ReqAssign_BuildDayTaskLineObj) for every Day Planning row in range, but only
    /// emits whole sequenceKey GROUPS into FirstPageLinesArr up to MaxLines lines - the group that
    /// crosses MaxLines is still included whole, since sequenceKey is the atomic grouping unit
    /// wrapper.js's rebuildRequestTree()/pendingSequences/accept-reject/drag all operate on and can
    /// never be split across two loads. Whatever whole sequenceKey groups didn't fit are returned as
    /// RemainingSequenceKeys - a JSON array of sequenceKey strings, blank '' when nothing remains -
    /// for codeunit "ReqAssign BG Day Task Lines" to build separately via ReqAssign_
    /// BuildDayTaskLinesJson_ForKeys.
    ///
    /// Two passes over "Day Planning": pass 1 reads only the key fields (Job No./Job Task No./
    /// Skill/Sequence No.) to decide grouping/order/page-membership ONCE, cheaply, before any
    /// per-line JSON is built; pass 2 builds the full line JSON but skips the (cheap, string-only)
    /// membership check first, so rows that don't land on the first page never pay for the Job/Job
    /// Task description lookups or decimal-hour conversions.
    /// </summary>
    local procedure ReqAssign_BuildDayTaskLinesJson_Paged(StartDate: Date; EndDate: Date; var WorkdayIndexMap: Dictionary of [Date, Integer]; MaxLines: Integer; var FirstPageLinesArr: JsonArray; var RemainingSequenceKeys: Text)
    var
        DayPlanning: Record "Day Planning";
        JobDescCache: Dictionary of [Code[20], Text];
        JobTaskDescCache: Dictionary of [Text, Text];
        SequenceKeyOrder: List of [Text];
        SeenKeys: Dictionary of [Text, Boolean];
        KeyLineCount: Dictionary of [Text, Integer];
        FirstPageKeys: Dictionary of [Text, Boolean];
        RemainingKeysArr: JsonArray;
        SequenceKeyTxt: Text;
        RunningTotal: Integer;
        PriorCount: Integer;
    begin
        DayPlanning.SetRange("Plan Date", StartDate, EndDate);

        // Pass 1: cheap pre-scan (key fields only) - establishes whole-sequence grouping order and
        // per-group line counts so the MaxLines cutoff below can never split a group.
        DayPlanning.SetLoadFields("Job No.", "Job Task No.", Skill, "Sequence No.");
        if DayPlanning.FindSet() then
            repeat
                SequenceKeyTxt := DayPlanning."Job No." + '|' + DayPlanning."Job Task No." + '|' + DayPlanning.Skill + '|' + Format(DayPlanning."Sequence No.");
                if not SeenKeys.ContainsKey(SequenceKeyTxt) then begin
                    SeenKeys.Add(SequenceKeyTxt, true);
                    SequenceKeyOrder.Add(SequenceKeyTxt);
                    KeyLineCount.Add(SequenceKeyTxt, 1);
                end else begin
                    // Dictionary has no in-place increment - Remove+Add is the portable way to
                    // overwrite an existing key's value (avoids relying on .Set(), not used
                    // elsewhere in this codebase).
                    PriorCount := KeyLineCount.Get(SequenceKeyTxt);
                    KeyLineCount.Remove(SequenceKeyTxt);
                    KeyLineCount.Add(SequenceKeyTxt, PriorCount + 1);
                end;
            until DayPlanning.Next() = 0;

        RunningTotal := 0;
        foreach SequenceKeyTxt in SequenceKeyOrder do
            if RunningTotal < MaxLines then begin
                FirstPageKeys.Add(SequenceKeyTxt, true);
                RunningTotal += KeyLineCount.Get(SequenceKeyTxt);
            end else
                RemainingKeysArr.Add(SequenceKeyTxt);

        if RemainingKeysArr.Count() > 0 then
            RemainingKeysArr.WriteTo(RemainingSequenceKeys)
        else
            RemainingSequenceKeys := '';

        // Pass 2: build each first-page line's full JSON via the shared per-line builder.
        DayPlanning.SetLoadFields("Job No.", "Job Task No.", "Day Line No.", "Plan Date", Skill,
            "Start Time Requested", "End Time Requested", "Start Time Assigned", "End Time Assigned",
            "Assigned Resource No.", "Sequence No.");
        if DayPlanning.FindSet() then
            repeat
                SequenceKeyTxt := DayPlanning."Job No." + '|' + DayPlanning."Job Task No." + '|' + DayPlanning.Skill + '|' + Format(DayPlanning."Sequence No.");
                if FirstPageKeys.ContainsKey(SequenceKeyTxt) then
                    FirstPageLinesArr.Add(ReqAssign_BuildDayTaskLineObj(DayPlanning, JobDescCache, JobTaskDescCache, WorkdayIndexMap, SequenceKeyTxt));
            until DayPlanning.Next() = 0;
    end;

    /// <summary>
    /// Companion to ReqAssign_BuildDayTaskLinesJson_Paged for the remainder Page Background Task
    /// (codeunit "ReqAssign BG Day Task Lines", Part B.3) - builds the same per-line JSON (again via
    /// the shared ReqAssign_BuildDayTaskLineObj), but only for Day Planning rows whose sequenceKey
    /// is one of RemainingSequenceKeysJson's JSON array of strings (as produced by ReqAssign_
    /// BuildDayTaskLinesJson_Paged's RemainingSequenceKeys out parameter). Rebuilds its own
    /// WorkdayIndexMap for the same [StartDate, EndDate] window - this runs in the background
    /// task's own session, so it cannot share the interactive session's Map instance, but
    /// ReqAssign_BuildWorkdayIndexMap is a pure function of [StartDate, EndDate] and always
    /// produces the identical Map either way (see ReqAssign_BuildPlanningDataJson's doc comment).
    /// Returns the resulting "dayTaskLines" JsonArray already serialized to Text (what the Page
    /// Background Task stashes into its result Dictionary and the control add-in's
    /// AppendDayTaskLines consumes) - '[]' when RemainingSequenceKeysJson is blank (a no-op call).
    /// Public (not local) - called from codeunit "ReqAssign BG Day Task Lines"'s OnRun and directly
    /// unit-testable on its own.
    /// </summary>
    procedure ReqAssign_BuildDayTaskLinesJson_ForKeys(StartDate: Date; EndDate: Date; RemainingSequenceKeysJson: Text): Text
    var
        DayPlanning: Record "Day Planning";
        JobDescCache: Dictionary of [Code[20], Text];
        JobTaskDescCache: Dictionary of [Text, Text];
        WorkdayIndexMap: Dictionary of [Date, Integer];
        WorkdaysArr: JsonArray;
        WantedKeys: Dictionary of [Text, Boolean];
        WantedKeysArr: JsonArray;
        KeyTok: JsonToken;
        LinesArr: JsonArray;
        SequenceKeyTxt: Text;
        OutTxt: Text;
    begin
        if RemainingSequenceKeysJson = '' then
            exit('[]');

        WantedKeysArr.ReadFrom(RemainingSequenceKeysJson);
        foreach KeyTok in WantedKeysArr do
            WantedKeys.Add(KeyTok.AsValue().AsText(), true);

        ReqAssign_BuildWorkdayIndexMap(StartDate, EndDate, WorkdayIndexMap, WorkdaysArr);

        DayPlanning.SetRange("Plan Date", StartDate, EndDate);
        DayPlanning.SetLoadFields("Job No.", "Job Task No.", "Day Line No.", "Plan Date", Skill,
            "Start Time Requested", "End Time Requested", "Start Time Assigned", "End Time Assigned",
            "Assigned Resource No.", "Sequence No.");
        if DayPlanning.FindSet() then
            repeat
                SequenceKeyTxt := DayPlanning."Job No." + '|' + DayPlanning."Job Task No." + '|' + DayPlanning.Skill + '|' + Format(DayPlanning."Sequence No.");
                if WantedKeys.ContainsKey(SequenceKeyTxt) then
                    LinesArr.Add(ReqAssign_BuildDayTaskLineObj(DayPlanning, JobDescCache, JobTaskDescCache, WorkdayIndexMap, SequenceKeyTxt));
            until DayPlanning.Next() = 0;

        LinesArr.WriteTo(OutTxt);
        exit(OutTxt);
    end;

    /// <summary>
    /// Builds the "capacitySlots" array from "Res. Capacity Entry" (+ its Start Time/End Time
    /// extension fields, tableext 50606) for Date in [StartDate, EndDate]. dayIndex is resolved
    /// from the SAME WorkdayIndexMap the caller (ReqAssign_BuildPlanningDataJson) also threads
    /// into ReqAssign_BuildDayTaskLinesJson - the two never disagree about what index a given
    /// date maps to, and 1000+ capacity rows each do an O(1) dictionary lookup instead of
    /// recomputing the offset per row. A capacity entry that falls on a weekend date (outside the
    /// map) is skipped - not expected in normal data, but defensive. A capacity entry generated
    /// from a Work Hour Template with a blank "Default Start Time" (see report 50661's
    /// SetCapacityOpt) has blank Start Time/End Time - those are skipped too rather than fed into
    /// ReqAssign_TimeToDecimalHours, which errors ("Subtracting an undefined (0T) time.") on 0T.
    /// </summary>
    local procedure ReqAssign_BuildCapacitySlotsJson(StartDate: Date; EndDate: Date; var WorkdayIndexMap: Dictionary of [Date, Integer]): JsonArray
    var
        ResCapacityEntry: Record "Res. Capacity Entry";
        SlotsArr: JsonArray;
        SlotObj: JsonObject;
        DayIndex: Integer;
    begin
        ResCapacityEntry.SetRange("Date", StartDate, EndDate);
        ResCapacityEntry.SetLoadFields("Resource No.", "Date", "Start Time", "End Time");
        if ResCapacityEntry.FindSet() then
            repeat
                if (ResCapacityEntry."Start Time" <> 0T) and (ResCapacityEntry."End Time" <> 0T) then
                    if WorkdayIndexMap.Get(ResCapacityEntry."Date", DayIndex) then begin
                        Clear(SlotObj);
                        SlotObj.Add('resourceId', ResCapacityEntry."Resource No.");
                        SlotObj.Add('dayIndex', DayIndex);
                        SlotObj.Add('start', ReqAssign_TimeToDecimalHours(ResCapacityEntry."Start Time"));
                        SlotObj.Add('end', ReqAssign_TimeToDecimalHours(ResCapacityEntry."End Time"));
                        SlotsArr.Add(SlotObj);
                    end;
            until ResCapacityEntry.Next() = 0;
        exit(SlotsArr);
    end;

    /// <summary>
    /// Single source of truth for the workday calendar: in one pass, precomputes Date -> 0-based-
    /// workday-index for every Mon-Fri date in [StartDate, EndDate] inclusive (weekend dates are
    /// simply absent from Map), AND builds the matching ordered "yyyy-MM-dd" JsonArray
    /// (WorkdaysArr) emitted as the payload's top-level "workdays" key. Building both from the
    /// same loop is deliberate - ReqAssign_BuildDayTaskLinesJson and
    /// ReqAssign_BuildCapacitySlotsJson both resolve their dayIndex from this one Map, so they can
    /// never disagree about what index a given date maps to (see ReqAssign_BuildPlanningDataJson).
    /// </summary>
    local procedure ReqAssign_BuildWorkdayIndexMap(StartDate: Date; EndDate: Date; var Map: Dictionary of [Date, Integer]; var WorkdaysArr: JsonArray)
    var
        CurDate: Date;
        Idx: Integer;
    begin
        Clear(Map);
        Idx := 0;
        CurDate := StartDate;
        while CurDate <= EndDate do begin
            if Date2DWY(CurDate, 1) < 6 then begin
                Map.Add(CurDate, Idx);
                WorkdaysArr.Add(ReqAssign_FormatIsoDate(CurDate));
                Idx += 1;
            end;
            CurDate += 1;
        end;
    end;

    /// <summary>
    /// Builds the "skillColors" array from "Skill Code". backgroundColor reuses the existing
    /// GetSkillBarColor convention (codeunit 50609 - "Bar Color" override else a 5-colour
    /// palette), same as this codeunit's own ResolveRequestedColor above. borderColor/textColor
    /// now reuse GetSkillBorderColor/GetSkillFontColor the same way (codeunit 50609 - Skill
    /// Code's own "Border Color"/"Font Color" override, else that codeunit's own hardcoded
    /// defaults - never "Daily Optimizer Setup"."Bar Font Color", which is reserved for the
    /// Capacity bar only). Previously these two stayed on static fallback constants
    /// (ReqAssignSkillBorderColorTok/ReqAssignSkillTextColorTok) because no per-skill Font/Border
    /// convention existed yet on codeunit 50609 - it does now, so every skill's Request
    /// Assignment Board bar/row-title actually reflects its own Skill Code setup instead of one
    /// fixed color for every skill.
    /// </summary>
    local procedure ReqAssign_BuildSkillColorsJson(): JsonArray
    var
        SkillCodeRec: Record "Skill Code";
        ColorConstants: Codeunit "Visual Default Settings";
        SkillColorsArr: JsonArray;
        SkillColorObj: JsonObject;
        PaletteIndex: Integer;
    begin
        if SkillCodeRec.FindSet() then
            repeat
                Clear(SkillColorObj);
                SkillColorObj.Add('skill', SkillCodeRec.Code);
                SkillColorObj.Add('backgroundColor', ColorConstants.GetSkillBarColor(SkillCodeRec.Code, PaletteIndex));
                SkillColorObj.Add('borderColor', ColorConstants.GetSkillBorderColor(SkillCodeRec.Code, PaletteIndex));
                SkillColorObj.Add('textColor', ColorConstants.GetSkillFontColor(SkillCodeRec.Code));
                SkillColorsArr.Add(SkillColorObj);
                PaletteIndex += 1;
            until SkillCodeRec.Next() = 0;
        exit(SkillColorsArr);
    end;

    /// <summary>
    /// Converts a Time-of-day value to decimal hours (e.g. 08:30:00 -> 8.5), for the
    /// dayTaskLines/capacitySlots decimal-hour fields (this feature's own convention - distinct
    /// from the rest of this codeunit's ToSessionDateTimeTxt/ConvertToUserTimeZone helpers, which
    /// build full ISO datetime strings for the DHTMLX Scheduler-style pages instead).
    ///
    /// Deliberately avoids "T - 0T" Time/Duration subtraction - live diagnostics on real
    /// production data (Job 10000/Task 1010/Day Line 500000, 2026-08-28) proved that idiom throws
    /// "Subtracting an undefined (0T) time." even for a plain, unambiguously non-blank T
    /// (07:00:00/16:00:00), independent of any 0T-blank guard at the call site - a genuine runtime
    /// quirk with this Time subtraction pattern on this environment, not a blank-value bug. This
    /// version does the conversion via Format()/Evaluate() on the individual clock components
    /// instead, so no Time arithmetic (and no literal 0T operand) is ever evaluated.
    /// </summary>
    local procedure ReqAssign_TimeToDecimalHours(T: Time): Decimal
    var
        HourPart: Integer;
        MinutePart: Integer;
        SecondPart: Integer;
    begin
        if T = 0T then
            exit(0);
        Evaluate(HourPart, Format(T, 0, '<Hours24>'));
        Evaluate(MinutePart, Format(T, 0, '<Minutes,2>'));
        Evaluate(SecondPart, Format(T, 0, '<Seconds,2>'));
        exit(HourPart + MinutePart / 60 + SecondPart / 3600);
    end;

    /// <summary>
    /// Converts decimal hours (e.g. 8.5) back to a Time-of-day value, for the six ReqAssign_*
    /// commit procedures below. Clamped to just before midnight rather than erroring on an
    /// out-of-range value from a malformed payload.
    ///
    /// Deliberately avoids "0T + Duration" arithmetic - live diagnostics on real production data
    /// proved the same runtime quirk documented on ReqAssign_TimeToDecimalHours above also fires
    /// on the reverse Time+Duration direction ("Adding to an undefined (0T) time.") whenever a
    /// literal/blank-valued 0T is one of the operands. This version builds the Time via
    /// Format()/Evaluate() on the individual clock components instead, so no Time arithmetic is
    /// ever evaluated.
    /// </summary>
    local procedure ReqAssign_DecimalHoursToTime(Hours: Decimal): Time
    var
        TotalMs: Integer;
        HourPart: Integer;
        MinutePart: Integer;
        SecondPart: Integer;
        TimeTxt: Text;
        ResultTime: Time;
    begin
        if Hours <= 0 then
            exit(0T);

        TotalMs := Round(Hours * 3600000, 1);
        if TotalMs > 86399999 then
            TotalMs := 86399999;

        HourPart := TotalMs div 3600000;
        MinutePart := (TotalMs mod 3600000) div 60000;
        SecondPart := (TotalMs mod 60000) div 1000;

        TimeTxt := StrSubstNo('%1:%2:%3', Format(HourPart).PadLeft(2, '0'), Format(MinutePart).PadLeft(2, '0'), Format(SecondPart).PadLeft(2, '0'));
        Evaluate(ResultTime, TimeTxt, 9);
        exit(ResultTime);
    end;

    local procedure ReqAssign_FormatIsoDate(D: Date): Text
    begin
        if D = 0D then
            exit('');
        exit(Format(D, 0, '<Year4>-<Month,2>-<Day,2>'));
    end;

    /// <summary>
    /// Parses a Day Task Line id ("<Job No.>|<Job Task No.>|<Day Line No.>") back into its parts
    /// so the caller can Day Planning.Get(JobNo, JobTaskNo, DayLineNo).
    /// </summary>
    local procedure ReqAssign_ParseId(IdTxt: Text; var JobNo: Code[20]; var JobTaskNo: Code[20]; var DayLineNo: Integer)
    var
        Parts: List of [Text];
    begin
        Parts := IdTxt.Split('|');
        JobNo := CopyStr(Parts.Get(1), 1, MaxStrLen(JobNo));
        JobTaskNo := CopyStr(Parts.Get(2), 1, MaxStrLen(JobTaskNo));
        Evaluate(DayLineNo, Parts.Get(3));
    end;

    /// <summary>
    /// Shared core behind ReqAssign_AssignDayTaskLine/ReqAssign_MoveAssignment/
    /// ReqAssign_ResizeAssignment/ReqAssign_AcceptSequence - always uses Validate() (never a
    /// direct field assignment) for "Assigned Resource No." and the assigned times, per this
    /// app's hard requirement that setting "Assigned Resource No." must go through Validate() to
    /// get its Resource Group/Vendor/Skill cascade (see table 50610's own OnValidate).
    /// </summary>
    local procedure ReqAssign_ApplyAssignment(var DayPlanning: Record "Day Planning"; ResourceId: Text; SetResource: Boolean; StartHour: Decimal; DurationHours: Decimal)
    begin
        if SetResource then
            DayPlanning.Validate("Assigned Resource No.", CopyStr(ResourceId, 1, MaxStrLen(DayPlanning."Assigned Resource No.")));
        DayPlanning.Validate("Start Time Assigned", ReqAssign_DecimalHoursToTime(StartHour));
        DayPlanning.Validate("End Time Assigned", ReqAssign_DecimalHoursToTime(StartHour + DurationHours));
        DayPlanning.Modify(true);
    end;

    /// <summary>
    /// Commits controladdin event OnAssignDayTaskLine - payload
    /// { "id", "resourceId", "startHour", "durationHours" }.
    /// </summary>
    procedure ReqAssign_AssignDayTaskLine(PayloadJsonTxt: Text)
    var
        PayloadObj: JsonObject;
        JToken: JsonToken;
        DayPlanning: Record "Day Planning";
        JobNo: Code[20];
        JobTaskNo: Code[20];
        DayLineNo: Integer;
        ResourceId: Text;
        StartHour: Decimal;
        DurationHours: Decimal;
    begin
        PayloadObj.ReadFrom(PayloadJsonTxt);
        PayloadObj.Get('id', JToken);
        ReqAssign_ParseId(JToken.AsValue().AsText(), JobNo, JobTaskNo, DayLineNo);
        PayloadObj.Get('resourceId', JToken);
        ResourceId := JToken.AsValue().AsText();
        PayloadObj.Get('startHour', JToken);
        StartHour := JToken.AsValue().AsDecimal();
        PayloadObj.Get('durationHours', JToken);
        DurationHours := JToken.AsValue().AsDecimal();

        if not DayPlanning.Get(JobNo, JobTaskNo, DayLineNo) then
            exit;
        ReqAssign_ApplyAssignment(DayPlanning, ResourceId, true, StartHour, DurationHours);
    end;

    /// <summary>
    /// Commits controladdin event OnMoveAssignment - identical payload/handling to
    /// ReqAssign_AssignDayTaskLine (resource and/or time changed on an already-assigned line); JS
    /// raises a distinct event name for "moved" vs. "newly assigned" but the AL-side persistence
    /// is the same.
    /// </summary>
    procedure ReqAssign_MoveAssignment(PayloadJsonTxt: Text)
    begin
        ReqAssign_AssignDayTaskLine(PayloadJsonTxt);
    end;

    /// <summary>
    /// Commits controladdin event OnResizeAssignment - payload { "id", "startHour",
    /// "durationHours" }, no "resourceId" - updates only the assigned times.
    /// </summary>
    procedure ReqAssign_ResizeAssignment(PayloadJsonTxt: Text)
    var
        PayloadObj: JsonObject;
        JToken: JsonToken;
        DayPlanning: Record "Day Planning";
        JobNo: Code[20];
        JobTaskNo: Code[20];
        DayLineNo: Integer;
        StartHour: Decimal;
        DurationHours: Decimal;
    begin
        PayloadObj.ReadFrom(PayloadJsonTxt);
        PayloadObj.Get('id', JToken);
        ReqAssign_ParseId(JToken.AsValue().AsText(), JobNo, JobTaskNo, DayLineNo);
        PayloadObj.Get('startHour', JToken);
        StartHour := JToken.AsValue().AsDecimal();
        PayloadObj.Get('durationHours', JToken);
        DurationHours := JToken.AsValue().AsDecimal();

        if not DayPlanning.Get(JobNo, JobTaskNo, DayLineNo) then
            exit;
        ReqAssign_ApplyAssignment(DayPlanning, '', false, StartHour, DurationHours);
    end;

    /// <summary>
    /// Commits controladdin event OnUnassignDayTaskLine - payload { "id" }. Validate()'d to blank
    /// so table 50610's own cascade (Resource Group No./Vendor No./Skill reset) still runs.
    /// </summary>
    procedure ReqAssign_UnassignDayTaskLine(PayloadJsonTxt: Text)
    var
        PayloadObj: JsonObject;
        JToken: JsonToken;
        DayPlanning: Record "Day Planning";
        JobNo: Code[20];
        JobTaskNo: Code[20];
        DayLineNo: Integer;
    begin
        PayloadObj.ReadFrom(PayloadJsonTxt);
        PayloadObj.Get('id', JToken);
        ReqAssign_ParseId(JToken.AsValue().AsText(), JobNo, JobTaskNo, DayLineNo);

        if not DayPlanning.Get(JobNo, JobTaskNo, DayLineNo) then
            exit;
        DayPlanning.Validate("Assigned Resource No.", '');
        DayPlanning.Validate("Start Time Assigned", 0T);
        DayPlanning.Validate("End Time Assigned", 0T);
        DayPlanning.Modify(true);
    end;

    /// <summary>
    /// Commits controladdin event OnAcceptSequence - payload { "sequenceKey", "resourceId",
    /// "lines": [ { "id", "startHour", "durationHours" }, ... ] }. This is the ONLY point where a
    /// whole-sequence drag-drop actually persists - confirmed product decision: the JS side keeps
    /// whole-sequence drops purely client-side/provisional until Accept fires. Every line in the
    /// payload shares the one target resourceId.
    /// </summary>
    procedure ReqAssign_AcceptSequence(PayloadJsonTxt: Text)
    var
        PayloadObj: JsonObject;
        LinesArr: JsonArray;
        LineTok: JsonToken;
        LineObj: JsonObject;
        JToken: JsonToken;
        DayPlanning: Record "Day Planning";
        JobNo: Code[20];
        JobTaskNo: Code[20];
        DayLineNo: Integer;
        ResourceId: Text;
        StartHour: Decimal;
        DurationHours: Decimal;
        i: Integer;
    begin
        PayloadObj.ReadFrom(PayloadJsonTxt);
        PayloadObj.Get('resourceId', JToken);
        ResourceId := JToken.AsValue().AsText();
        PayloadObj.Get('lines', JToken);
        LinesArr := JToken.AsArray();

        for i := 0 to LinesArr.Count() - 1 do begin
            LinesArr.Get(i, LineTok);
            LineObj := LineTok.AsObject();
            LineObj.Get('id', JToken);
            ReqAssign_ParseId(JToken.AsValue().AsText(), JobNo, JobTaskNo, DayLineNo);
            LineObj.Get('startHour', JToken);
            StartHour := JToken.AsValue().AsDecimal();
            LineObj.Get('durationHours', JToken);
            DurationHours := JToken.AsValue().AsDecimal();

            if DayPlanning.Get(JobNo, JobTaskNo, DayLineNo) then
                ReqAssign_ApplyAssignment(DayPlanning, ResourceId, true, StartHour, DurationHours);
        end;
    end;

    /// <summary>
    /// Commits controladdin event OnRejectSequence - payload { "sequenceKey" }. No table writes
    /// needed: JS already discards its provisional whole-sequence-drop state on reject (confirmed
    /// product decision, see ReqAssign_AcceptSequence's doc comment). Kept as a real procedure
    /// (rather than omitted) so the controladdin event contract stays symmetric with
    /// OnAcceptSequence, and as a seam for future audit logging if ever needed.
    /// </summary>
    procedure ReqAssign_RejectSequence(PayloadJsonTxt: Text)
    begin
    end;

    // ================================================================================
    // "CPO_" region - Capacity Planning Overview (page 50722 "Capacity Planning Overview",
    // controladdin DHXCapacityPlanningOverviewAddin, src/dhx/capacity_planning_overview).
    //
    // ARCHITECTURE PIVOT (2026-09-02, explicit user decision - see this add-in's project memory
    // for the full history): the earlier "simple per-skill capacity-vs-demand" shortage engine
    // (statsRows/treeNodes/treeCells/capacityBars, all computed HERE in AL) is REPLACED by a
    // near-verbatim port of the reference prototype's OWN client-side multi-skill max-flow engine
    // (capacityPlanningOverview.js's maxFlowDay/evaluateWO/currentPositionShortage - see
    // C:\Users\Ahmad\OneDrive\x\PROJECT\KLAAS\CPO_v131\DHTMLXtempv112-app.js). AL's job shrinks to
    // ONE thing: build a JSON payload shaped exactly like the reference's own mock
    // "window.DHTMLXPlannerData" global (DHTMLXtempv112-data.js) from real Business Central data -
    // skills[]/resources[]/baseCapacity/externalFree[]/groups[]/dayPlanningLines[]/
    // workOrderSequences[] - and hand it to the JS side to compute EVERYTHING else (shortage,
    // coverage, the daily capacity/request bars, the Skill->Job/Task->Sequence tree) exactly like
    // the reference does. This is a deliberate REVERSAL of the earlier "no max-flow optimizer"
    // decision, not an incremental improvement on top of it - the old statsRows/treeNodes/
    // treeCells/capacityBars procedures and the codeunit 50662 dependency they used are gone.
    //
    // CROSS-WORK-ORDER SCOPE (2026-09-03, explicit user correction/refinement - see this add-in's
    // project memory for the full history): "dayPlanningLines[]" is no longer scoped to just the
    // inspected Work Order - it now ALSO carries every OTHER Work Order's Day Planning demand
    // within the same visible [StartDate, EndDate] window, each line tagged with its own real
    // "workOrderNo". Per section: Section 1/2 (stats header + this WO's own scheduler) and
    // Section 3's own "Requested" bar stay about the INSPECTED Work Order specifically (Section
    // 3's underlying capacity/free totals were already legitimately company-wide before this
    // change - only its demand side needed a workOrderNo filter to stay WO-specific). Section 4
    // (Skill->Job/Task->Sequence tree, "groups[]") now shows "everything else going on in this
    // window" - i.e. every OTHER Work Order's demand, EXCLUDING the inspected one (see
    // CPO_BuildPlanningDataJson's own Pass 3 doc comment). This intentionally makes the page
    // slower to load (a company-wide, date-bounded scan every refresh) - the user explicitly
    // accepted that tradeoff for correctness.
    // ================================================================================

    /// <summary>
    /// Builds the single combined JSON payload consumed by controladdin
    /// DHXCapacityPlanningOverviewAddin.SetPlanningData for one Work Order - shaped as closely as
    /// possible to the reference prototype's own mock "window.DHTMLXPlannerData" object (see this
    /// procedure's own region-header doc comment above for why). The visible window is always
    /// Today()..Today()+NumberOfDays-1 (unchanged from before this pivot - still NOT anchored to
    /// the Work Order's own Planned Start/End Date, per the earlier explicit user instruction);
    /// "startDate" doubles as the reference's own implicit workday-offset anchor (offset 1 =
    /// StartDate itself, or the first workday at/after it - see CPO_ComputeWorkdayOffset), which
    /// is what lets the JS side's ported idxWork()/workOrderExtra() reconstruct each
    /// workOrderSequences[] occurrence's real calendar date without a separate anchor field.
    /// Safe to call with an unresolvable WorkOrderNo - returns a well-formed, empty-safe payload
    /// (no lines, empty skill/resource/group arrays) rather than erroring, since this runs from a
    /// page trigger with no user-facing error path.
    /// </summary>
    procedure CPO_BuildPlanningDataJson(WorkOrderNo: Code[20]; NumberOfDays: Integer): Text
    var
        WorkOrder: Record "Work Order";
        Job: Record Job;
        DayPlanning: Record "Day Planning";
        // Company-wide (minus WorkOrderNo), date-bounded query for Pass 3 below - see that pass's
        // own doc comment.
        OtherDayPlanning: Record "Day Planning";
        RootObj: JsonObject;
        ProjectObj: JsonObject;
        WorkOrderObj: JsonObject;
        DayPlanningLinesArr: JsonArray;
        ActiveSkillList: List of [Code[20]];
        // Skills seen ONLY in the "other Work Orders" pass (Pass 3 below) - a subset of
        // ActiveSkillList, used purely to drive CPO_BuildGroupsArray's own iteration so Section 4
        // does not render an empty skill header for a skill only WorkOrderNo itself demands.
        OtherSkillList: List of [Code[20]];
        // Group dedup (section 4 tree source data) - one entry per distinct Skill+Job No.+Job Task
        // No. combination, in first-seen order (parallel Lists, same "ordered-distinct via
        // Contains()" idiom this codeunit already uses elsewhere, e.g. ResolveRequestedColor's
        // SkillColorDict / the old CPO_BuildTreeNodesArray).
        // REPURPOSED (2026-09-03, explicit user correction - see this add-in's project memory):
        // used to be populated from WorkOrderNo's OWN lines in Pass 1; now populated EXCLUSIVELY
        // from Pass 3 below (every OTHER Work Order's demand in the same [StartDate, EndDate]
        // window) - Section 4 is "everything else going on in this window", NOT WorkOrderNo's own
        // tree (Section 2/workOrderSequences[] below already covers WorkOrderNo's own schedule).
        GroupOrder: List of [Text];
        GroupSkill: List of [Code[20]];
        GroupJobNo: List of [Code[20]];
        GroupJobTaskNo: List of [Code[20]];
        GroupDescription: List of [Text];
        // Sequence dedup (section 2 source data) - one entry per distinct Skill+Job No.+Job Task
        // No.+Sequence No. combination, in first-seen order. SeqOrder's 1-based position (via
        // CPO_IndexOfText) is reused as a compact numeric prefix for SeqOffsetKeyOrder/
        // SeqOffsetHours below, so those don't need to embed the full pipe-joined text key.
        SeqOrder: List of [Text];
        SeqSkill: List of [Code[20]];
        SeqJobNo: List of [Code[20]];
        SeqJobTaskNo: List of [Code[20]];
        SeqSequenceNo: List of [Integer];
        SeqLineNo: List of [Integer];
        // Per-(sequence, workday-offset) requested-hours accumulation - built in a SECOND pass
        // over the same Day Planning recordset (cheap - bounded to this one WO's own lines), since
        // it needs SeqOrder fully populated first to resolve each line's own sequence index.
        SeqOffsetKeyOrder: List of [Text];
        SeqOffsetHours: Dictionary of [Text, Decimal];
        // Populated by CPO_BuildResourcesArray (out param) - the skill-scoped, capped resource
        // pool "resources[]" is built from; reused by CPO_BuildExternalFreeArray so "externalFree"
        // stays commensurate with that same pool instead of a separate company-wide query.
        ResourcePool: List of [Code[20]];
        GroupKeyTxt: Text;
        SeqKeyTxt: Text;
        OffsetKeyTxt: Text;
        SeqIdx: Integer;
        WorkdayOffset: Integer;
        CurHours: Decimal;
        StartDate: Date;
        EndDate: Date;
        JobNo: Code[20];
        JobTaskNo: Code[20];
        WorkOrderFound: Boolean;
        OutTxt: Text;
    begin
        WorkOrderFound := WorkOrder.Get(WorkOrderNo);

        if WorkOrderFound then begin
            JobNo := WorkOrder."Project No.";
            JobTaskNo := WorkOrder."Project Task No.";
            WorkOrderObj.Add('no', WorkOrder."Work Order No.");
            // The Work Order's OWN description (e.g. "Snag List Resolution") - JS's title bar
            // uses this, NOT the parent Project's description (an earlier version of the JS
            // wrongly fell back to the project's description, which was misleading - e.g. showing
            // "Work Order Demo Data" instead of the WO's own text).
            WorkOrderObj.Add('description', WorkOrder.Description);
            // Unused by any ported reference function (grepped DHTMLXtempv112-app.js - neither
            // field is read anywhere), kept only as descriptive metadata mirroring the reference's
            // own mock shape - mapped from this WO's own Planned Start/End Date.
            WorkOrderObj.Add('notEarlierThan', ReqAssign_FormatIsoDate(WorkOrder."Planned Start Date"));
            WorkOrderObj.Add('notLaterThan', ReqAssign_FormatIsoDate(WorkOrder."Planned End Date"));
        end else begin
            WorkOrderObj.Add('no', WorkOrderNo);
            WorkOrderObj.Add('description', '');
            WorkOrderObj.Add('notEarlierThan', '');
            WorkOrderObj.Add('notLaterThan', '');
        end;

        if (JobNo <> '') and Job.Get(JobNo) then begin
            ProjectObj.Add('no', JobNo);
            ProjectObj.Add('description', Job.Description);
        end else begin
            ProjectObj.Add('no', JobNo);
            ProjectObj.Add('description', '');
        end;

        if NumberOfDays <= 0 then
            NumberOfDays := 30;
        StartDate := Today();
        EndDate := StartDate + NumberOfDays - 1;

        // Echoed back so the JS-owned "Days to show" input can sync its displayed value to
        // whatever AL actually used (initial default, or after Reset position).
        RootObj.Add('daysToShow', NumberOfDays);
        RootObj.Add('startDate', ReqAssign_FormatIsoDate(StartDate));
        RootObj.Add('endDate', ReqAssign_FormatIsoDate(EndDate));
        RootObj.Add('workdays', CPO_BuildDateRangeArray(StartDate, EndDate));

        if WorkOrderFound then begin
            DayPlanning.SetLoadFields("Job No.", "Job Task No.", "Day Line No.", Skill, "Sequence No.", Description,
                "Plan Date", Assigned, "Assigned Resource No.", "Requested Hours", "Assigned Hours",
                "Start Time Requested", "End Time Requested", "Start Time Assigned", "End Time Assigned",
                "Work Order No.");
            // Scoped by Job No./Job Task No. (this WO's own "Project No."/"Project Task No."),
            // NOT the "Work Order No." field (2026-09-03 bug fix - see this add-in's project
            // memory): confirmed live on DWO0008 that some of a Work Order's own Day Planning
            // Sequences (e.g. added via the Workorder Card's native "New sequence" button) can
            // carry a BLANK "Work Order No." field, even though they're genuinely this WO's own
            // data - the native "Day Planning Sequence" part on the Workorder Card itself only
            // ever filters by Job No./Job Task No., never by "Work Order No.", so CPO must match
            // that same semantics or it silently drops rows from Section 2 (and Pass 3 below then
            // wrongly re-adds them to Section 4 as if they were some OTHER Work Order's demand).
            // Falls back to the old "Work Order No." field filter only if this WO has no linked
            // Job at all (blank Project No.) - without SOME filter here, blank Job No./Job Task
            // No. would match every unassigned Day Planning line company-wide.
            if JobNo <> '' then begin
                DayPlanning.SetRange("Job No.", JobNo);
                DayPlanning.SetRange("Job Task No.", JobTaskNo);
            end else
                DayPlanning.SetRange("Work Order No.", WorkOrderNo);

            // ---- Pass 1: dayPlanningLines[] (WorkOrderNo's OWN lines) + distinct-key dedup
            // (skills/sequences - NOT groups, see Pass 3 below for why) ----
            if DayPlanning.FindSet() then
                repeat
                    DayPlanningLinesArr.Add(CPO_BuildDayPlanningLineObj(DayPlanning, WorkOrderNo, JobNo, JobTaskNo));

                    // A blank Skill is real (unclassified) demand but cannot be placed under any
                    // Skill tree node or matched to a resource pool - excluded from every
                    // skill-keyed structure below, same convention the pre-pivot code already used.
                    if DayPlanning.Skill <> '' then begin
                        if not ActiveSkillList.Contains(DayPlanning.Skill) then
                            ActiveSkillList.Add(DayPlanning.Skill);

                        SeqKeyTxt := DayPlanning.Skill + '|' + DayPlanning."Job No." + '|' + DayPlanning."Job Task No." + '|' + Format(DayPlanning."Sequence No.");
                        if not SeqOrder.Contains(SeqKeyTxt) then begin
                            SeqOrder.Add(SeqKeyTxt);
                            SeqSkill.Add(DayPlanning.Skill);
                            SeqJobNo.Add(DayPlanning."Job No.");
                            SeqJobTaskNo.Add(DayPlanning."Job Task No.");
                            SeqSequenceNo.Add(DayPlanning."Sequence No.");
                            SeqLineNo.Add(DayPlanning."Day Line No.");
                        end;
                    end;
                until DayPlanning.Next() = 0;

            // ---- Pass 2: per-line workday-offset -> requested-hours accumulation, now that
            // SeqOrder is fully populated (needed to resolve each line's own sequence index). ----
            if DayPlanning.FindSet() then
                repeat
                    if DayPlanning.Skill <> '' then begin
                        SeqKeyTxt := DayPlanning.Skill + '|' + DayPlanning."Job No." + '|' + DayPlanning."Job Task No." + '|' + Format(DayPlanning."Sequence No.");
                        SeqIdx := CPO_IndexOfText(SeqOrder, SeqKeyTxt);
                        if SeqIdx > 0 then begin
                            WorkdayOffset := CPO_ComputeWorkdayOffset(StartDate, DayPlanning."Plan Date");
                            if WorkdayOffset >= 1 then begin
                                OffsetKeyTxt := Format(SeqIdx) + '|' + Format(WorkdayOffset);
                                if not SeqOffsetKeyOrder.Contains(OffsetKeyTxt) then
                                    SeqOffsetKeyOrder.Add(OffsetKeyTxt);
                                CurHours := 0;
                                if SeqOffsetHours.ContainsKey(OffsetKeyTxt) then
                                    CurHours := SeqOffsetHours.Get(OffsetKeyTxt);
                                SeqOffsetHours.Set(OffsetKeyTxt, CurHours + DayPlanning."Requested Hours");
                            end;
                        end;
                    end;
                until DayPlanning.Next() = 0;

            // ---- Pass 3 (explicit user correction, 2026-09-03 - see this add-in's project
            // memory for the full history): append every OTHER Work Order's Day Planning demand
            // in this SAME [StartDate, EndDate] window into dayPlanningLines[], and build
            // groups[] (Section 4's own tree source) EXCLUSIVELY from this other-WOs data instead
            // of WorkOrderNo's own - in the user's own words, "section 3 for DWO0008 but section 4
            // for all day planning data in days time frame except DWO0008". Section 2
            // (workOrderSequences[] above) is untouched and still shows ONLY WorkOrderNo's own
            // schedule. Scoped ONLY by Plan Date in [StartDate, EndDate] and Skill <> '' (Pass 1's
            // own convention) and "Work Order No." <> WorkOrderNo - deliberately NOT further
            // scoped by Job No./Job Task No. overlap with WorkOrderNo's own combos, since the
            // user's own words name WorkOrderNo itself as the only exclusion. Company-wide but
            // date-bounded (~30 days typical) - the user explicitly accepted a slower page load
            // for this correctness, so no further paging/scoping is added.
            //
            // Every appended line also carries its own real "Work Order No." (see
            // CPO_BuildDayPlanningLineObj's 'workOrderNo') - now that dayPlanningLines[] holds
            // BOTH WorkOrderNo's own lines (Pass 1) and every other WO's lines (this pass), the
            // ported JS needs that tag to keep section 3's own "Requested" bar scoped to
            // WorkOrderNo and sections 2/4's own line-matching from ever mixing the two WOs'
            // rows together on a coincidental Job/Task/Skill/Sequence No. collision - see
            // capacityPlanningOverview.js's own doc comments at capParts/dailyCapacityRequestData/
            // workOrderAssignmentState/skillDaySummary/taskDaySummary/sequenceDayLines for the
            // matching JS-side change.
            OtherDayPlanning.SetLoadFields("Job No.", "Job Task No.", "Day Line No.", Skill, "Sequence No.", Description,
                "Plan Date", Assigned, "Assigned Resource No.", "Requested Hours", "Assigned Hours",
                "Start Time Requested", "End Time Requested", "Start Time Assigned", "End Time Assigned",
                "Work Order No.");
            // NOT filtered by "Work Order No." <> WorkOrderNo anymore (2026-09-03 bug fix - see
            // Pass 1's own doc comment above for the full reasoning): that field can be blank on
            // some of WorkOrderNo's OWN Day Planning Sequences, which then wrongly passed this
            // "<>" filter and leaked into Section 4 as if they were another Work Order's demand.
            // The real exclusion criterion must mirror Pass 1's own scoping - Job No./Job Task
            // No. equal to WorkOrderNo's own - checked in-code below (SetRange/SetFilter can only
            // AND conditions together, not express "NOT(JobNo=X AND TaskNo=Y)" as a single table
            // filter) rather than as a fourth SetRange here.
            OtherDayPlanning.SetFilter(Skill, '<>%1', '');
            OtherDayPlanning.SetRange("Plan Date", StartDate, EndDate);
            if OtherDayPlanning.FindSet() then
                repeat
                    // Skip this WO's own line (matched by Job No./Job Task No., regardless of its
                    // "Work Order No." field) - already covered by Pass 1 above.
                    if not ((JobNo <> '') and (OtherDayPlanning."Job No." = JobNo) and (OtherDayPlanning."Job Task No." = JobTaskNo)) then begin
                        DayPlanningLinesArr.Add(CPO_BuildDayPlanningLineObj(OtherDayPlanning, WorkOrderNo, JobNo, JobTaskNo));

                        if not ActiveSkillList.Contains(OtherDayPlanning.Skill) then
                            ActiveSkillList.Add(OtherDayPlanning.Skill);
                        if not OtherSkillList.Contains(OtherDayPlanning.Skill) then
                            OtherSkillList.Add(OtherDayPlanning.Skill);

                        GroupKeyTxt := OtherDayPlanning.Skill + '|' + OtherDayPlanning."Job No." + '|' + OtherDayPlanning."Job Task No.";
                        if not GroupOrder.Contains(GroupKeyTxt) then begin
                            GroupOrder.Add(GroupKeyTxt);
                            GroupSkill.Add(OtherDayPlanning.Skill);
                            GroupJobNo.Add(OtherDayPlanning."Job No.");
                            GroupJobTaskNo.Add(OtherDayPlanning."Job Task No.");
                            GroupDescription.Add(OtherDayPlanning.Description);
                        end;
                    end;
                until OtherDayPlanning.Next() = 0;
        end;

        RootObj.Add('project', ProjectObj);
        RootObj.Add('workOrder', WorkOrderObj);
        // ActiveSkillList is now the UNION of WorkOrderNo's own active skills (Pass 1) and every
        // other Work Order's active skills in this window (Pass 3) - broadening skills[]/
        // resources[]/externalFree[] this way is safe for WorkOrderNo's own shortage math
        // (evaluateWO/currentPositionShortage only ever measure a BEFORE/AFTER delta over the
        // identical resource+skill graph - see this add-in's project memory) and is required so
        // Section 4's now-broadened groups[] tree gets correct per-skill color metadata instead of
        // falling back to a generic default color for a skill only some OTHER Work Order uses.
        RootObj.Add('skills', CPO_BuildSkillsArray(ActiveSkillList));
        RootObj.Add('resources', CPO_BuildResourcesArray(ActiveSkillList, ResourcePool));
        // Flat per-resource-per-day hours, matching the reference's own flat "baseCapacity":8 -
        // this WO's own project team's actual Res. Capacity Entry values are not uniformly 8h in
        // every real BC company, but 8h/day is this codebase's standard full-time representative
        // value (matches "Daily Optimizer Setup" conventions elsewhere) and the reference's own
        // maxFlowDay only ever needs ONE flat number per resource per (non-weekend) day - not a
        // richer per-resource shape.
        RootObj.Add('baseCapacity', 8);
        // ResourcePool (out param from CPO_BuildResourcesArray above) is the SAME skill-scoped,
        // capped pool "resources[]" already carries - see CPO_BuildExternalFreeArray's own doc
        // comment for why externalFree must reuse it rather than querying company-wide.
        RootObj.Add('externalFree', CPO_BuildExternalFreeArray(ResourcePool, StartDate, EndDate));
        // OtherSkillList (NOT the broadened ActiveSkillList) - see that List's own doc comment.
        RootObj.Add('groups', CPO_BuildGroupsArray(OtherSkillList, GroupSkill, GroupJobNo, GroupJobTaskNo, GroupDescription));
        RootObj.Add('dayPlanningLines', DayPlanningLinesArr);
        RootObj.Add('workOrderSequences', CPO_BuildWorkOrderSequencesArray(SeqOrder, SeqSkill, SeqJobNo, SeqJobTaskNo, SeqSequenceNo, SeqLineNo, SeqOffsetKeyOrder, SeqOffsetHours));

        RootObj.WriteTo(OutTxt);
        exit(OutTxt);
    end;

    // ================================================================================
    // Page Background Task pagination (2026-09-03, explicit user request - "the system takes a
    // long time to generate the JSON and load it into DHTMLX ... get the first 50 records, and the
    // remaining will background process"). Modeled directly on codeunit "ReqAssign BG Day Task
    // Lines" / page 50710 "DHX Request Assignment Board"'s own pattern (ReqAssign_
    // BuildPlanningDataJson_Paged / ReqAssign_BuildDayTaskLinesJson_Paged / ReqAssign_
    // BuildDayTaskLinesJson_ForKeys) - same two-pass split, same atomic-group pagination unit idea,
    // same "cheap full pre-scan decides structure/paging, expensive per-line build is what's
    // actually paginated" shape.
    //
    // ONLY Pass 3 (every OTHER Work Order's demand, company-wide across the visible window) is
    // paginated - that is the actual "huge Day Planning data volume" bottleneck the user
    // identified. Pass 1/2 (the inspected Work Order's OWN data, feeding section 2/
    // workOrderSequences[]) stay exactly as they are in CPO_BuildPlanningDataJson above - bounded
    // to one Work Order's own lines, never the cost driver.
    //
    // The atomic pagination unit is a whole "group" - Skill+Job No.+Job Task No., the SAME
    // Skill/Job/Task combination Section 4's tree groups by (see CPO_BuildGroupsArray) - a group
    // is never split across the synchronous first page and the background remainder, so Section
    // 4's tree structure is always internally consistent at every point in the load.
    //
    // skills[]/resources[]/externalFree[]/groups[] (the TREE SKELETON - which skills and which
    // Job/Task groups exist) are built from a cheap key-fields-only scan that ALWAYS covers the
    // FULL window, never paginated - trivial cost even over a huge dayPlanningLines volume (a few
    // hundred distinct groups at most). Only the EXPENSIVE part - building each group's full
    // dayPlanningLines[] entries (Job/Job Task description lookups, time-to-decimal conversions,
    // per-line JSON) - is deferred for whatever groups don't fit MaxOtherLines. The practical
    // effect: Section 4's tree renders its full Skill/Job/Task skeleton immediately; the
    // Sequence-level leaf chips for later groups backfill once the background task delivers them.
    // Section 1/3's shortage/coverage numbers are correspondingly PROVISIONAL until that backfill
    // completes (capParts()'s company-wide "assigned" sum needs every group's real hours) - the
    // JS-side AppendOtherWorkOrderData (capacityPlanningOverview.js) re-runs the full shortage
    // recompute and re-renders sections 1/3/4 once the remainder arrives, correcting this.
    // ================================================================================

    /// <summary>
    /// Cheap, ALWAYS-full pre-scan (key fields only - no Job/Job Task description lookups, no time
    /// formatting) over every OTHER Work Order's Day Planning demand in [StartDate, EndDate] -
    /// establishes the complete distinct-group list/order/per-group line count (GroupOrder/
    /// GroupLineCount) and the complete active-skill lists (ActiveSkillList, the UNION also used by
    /// skills[]/resources[]/externalFree[]; OtherSkillList, this pass's own skills only - same two
    /// lists CPO_BuildPlanningDataJson's own Pass 3 already threads into CPO_BuildSkillsArray/
    /// CPO_BuildGroupsArray respectively). Never paginated - see this region's own header comment
    /// for why this is safe/cheap even over a huge dayPlanningLines volume. Same exclusion
    /// criterion as CPO_BuildPlanningDataJson's Pass 3 (Job No./Job Task No. match, not the
    /// unreliable "Work Order No." field - see that pass's own doc comment).
    /// </summary>
    local procedure CPO_ScanOtherWorkOrderGroups(JobNo: Code[20]; JobTaskNo: Code[20]; StartDate: Date; EndDate: Date; var ActiveSkillList: List of [Code[20]]; var OtherSkillList: List of [Code[20]]; var GroupOrder: List of [Text]; var GroupSkill: List of [Code[20]]; var GroupJobNo: List of [Code[20]]; var GroupJobTaskNo: List of [Code[20]]; var GroupDescription: List of [Text]; var GroupLineCount: Dictionary of [Text, Integer])
    var
        OtherDayPlanning: Record "Day Planning";
        GroupKeyTxt: Text;
        PriorCount: Integer;
    begin
        OtherDayPlanning.SetLoadFields("Job No.", "Job Task No.", Skill, Description);
        OtherDayPlanning.SetFilter(Skill, '<>%1', '');
        OtherDayPlanning.SetRange("Plan Date", StartDate, EndDate);
        if OtherDayPlanning.FindSet() then
            repeat
                if not ((JobNo <> '') and (OtherDayPlanning."Job No." = JobNo) and (OtherDayPlanning."Job Task No." = JobTaskNo)) then begin
                    if not ActiveSkillList.Contains(OtherDayPlanning.Skill) then
                        ActiveSkillList.Add(OtherDayPlanning.Skill);
                    if not OtherSkillList.Contains(OtherDayPlanning.Skill) then
                        OtherSkillList.Add(OtherDayPlanning.Skill);

                    GroupKeyTxt := OtherDayPlanning.Skill + '|' + OtherDayPlanning."Job No." + '|' + OtherDayPlanning."Job Task No.";
                    if not GroupLineCount.ContainsKey(GroupKeyTxt) then begin
                        GroupOrder.Add(GroupKeyTxt);
                        GroupSkill.Add(OtherDayPlanning.Skill);
                        GroupJobNo.Add(OtherDayPlanning."Job No.");
                        GroupJobTaskNo.Add(OtherDayPlanning."Job Task No.");
                        GroupDescription.Add(OtherDayPlanning.Description);
                        GroupLineCount.Add(GroupKeyTxt, 1);
                    end else begin
                        // Dictionary has no in-place increment - Remove+Add overwrites the existing
                        // value, same idiom ReqAssign_BuildDayTaskLinesJson_Paged already uses.
                        PriorCount := GroupLineCount.Get(GroupKeyTxt);
                        GroupLineCount.Remove(GroupKeyTxt);
                        GroupLineCount.Add(GroupKeyTxt, PriorCount + 1);
                    end;
                end;
            until OtherDayPlanning.Next() = 0;
    end;

    /// <summary>
    /// Expensive per-line JSON build (Job/Job Task description lookups, time-to-decimal
    /// conversions, via the shared CPO_BuildDayPlanningLineObj) for every OTHER Work Order's Day
    /// Planning row in [StartDate, EndDate] WHOSE Skill+Job No.+Job Task No. group is a key in
    /// WantedGroupKeys - shared by both CPO_BuildPlanningDataJson_Paged's own synchronous first
    /// page (WantedGroupKeys = the groups that fit MaxOtherLines) and
    /// CPO_BuildOtherWorkOrderLinesJson_ForKeys's background-task remainder (WantedGroupKeys =
    /// whatever didn't fit) - both build byte-for-byte identical line JSON for the same row instead
    /// of maintaining two copies of this logic.
    /// </summary>
    local procedure CPO_BuildOtherWorkOrderLinesForGroups(WorkOrderNo: Code[20]; JobNo: Code[20]; JobTaskNo: Code[20]; StartDate: Date; EndDate: Date; var WantedGroupKeys: Dictionary of [Text, Boolean]): JsonArray
    var
        OtherDayPlanning: Record "Day Planning";
        LinesArr: JsonArray;
        GroupKeyTxt: Text;
    begin
        OtherDayPlanning.SetLoadFields("Job No.", "Job Task No.", "Day Line No.", Skill, "Sequence No.", Description,
            "Plan Date", Assigned, "Assigned Resource No.", "Requested Hours", "Assigned Hours",
            "Start Time Requested", "End Time Requested", "Start Time Assigned", "End Time Assigned",
            "Work Order No.");
        OtherDayPlanning.SetFilter(Skill, '<>%1', '');
        OtherDayPlanning.SetRange("Plan Date", StartDate, EndDate);
        if OtherDayPlanning.FindSet() then
            repeat
                if not ((JobNo <> '') and (OtherDayPlanning."Job No." = JobNo) and (OtherDayPlanning."Job Task No." = JobTaskNo)) then begin
                    GroupKeyTxt := OtherDayPlanning.Skill + '|' + OtherDayPlanning."Job No." + '|' + OtherDayPlanning."Job Task No.";
                    if WantedGroupKeys.ContainsKey(GroupKeyTxt) then
                        LinesArr.Add(CPO_BuildDayPlanningLineObj(OtherDayPlanning, WorkOrderNo, JobNo, JobTaskNo));
                end;
            until OtherDayPlanning.Next() = 0;
        exit(LinesArr);
    end;

    /// <summary>
    /// Paged variant of CPO_BuildPlanningDataJson - see this region's own header comment for the
    /// full design. Identical payload shape/keys; skills[]/resources[]/externalFree[]/groups[] are
    /// always complete (cheap full pre-scan, CPO_ScanOtherWorkOrderGroups); dayPlanningLines[] gets
    /// the inspected Work Order's own lines in full (Pass 1, unchanged) plus only the first
    /// MaxOtherLines-worth of whole OTHER-Work-Order groups (Pass 3b, CPO_
    /// BuildOtherWorkOrderLinesForGroups). RemainingGroupKeys (a JSON array of "Skill|JobNo|
    /// JobTaskNo" strings, blank '' if nothing remains) is what the caller threads into
    /// CurrPage.EnqueueBackgroundTask(Codeunit::"CPO BG Other WO Data", ...).
    /// </summary>
    procedure CPO_BuildPlanningDataJson_Paged(WorkOrderNo: Code[20]; NumberOfDays: Integer; MaxOtherLines: Integer; var RemainingGroupKeys: Text): Text
    var
        WorkOrder: Record "Work Order";
        Job: Record Job;
        DayPlanning: Record "Day Planning";
        RootObj: JsonObject;
        ProjectObj: JsonObject;
        WorkOrderObj: JsonObject;
        DayPlanningLinesArr: JsonArray;
        FirstPageOtherLinesArr: JsonArray;
        LineTok: JsonToken;
        ActiveSkillList: List of [Code[20]];
        OtherSkillList: List of [Code[20]];
        GroupOrder: List of [Text];
        GroupSkill: List of [Code[20]];
        GroupJobNo: List of [Code[20]];
        GroupJobTaskNo: List of [Code[20]];
        GroupDescription: List of [Text];
        GroupLineCount: Dictionary of [Text, Integer];
        FirstPageGroupKeys: Dictionary of [Text, Boolean];
        RemainingGroupKeysArr: JsonArray;
        SeqOrder: List of [Text];
        SeqSkill: List of [Code[20]];
        SeqJobNo: List of [Code[20]];
        SeqJobTaskNo: List of [Code[20]];
        SeqSequenceNo: List of [Integer];
        SeqLineNo: List of [Integer];
        SeqOffsetKeyOrder: List of [Text];
        SeqOffsetHours: Dictionary of [Text, Decimal];
        ResourcePool: List of [Code[20]];
        GroupKeyTxt: Text;
        SeqKeyTxt: Text;
        OffsetKeyTxt: Text;
        SeqIdx: Integer;
        WorkdayOffset: Integer;
        CurHours: Decimal;
        RunningTotal: Integer;
        StartDate: Date;
        EndDate: Date;
        JobNo: Code[20];
        JobTaskNo: Code[20];
        WorkOrderFound: Boolean;
        OutTxt: Text;
    begin
        WorkOrderFound := WorkOrder.Get(WorkOrderNo);

        if WorkOrderFound then begin
            JobNo := WorkOrder."Project No.";
            JobTaskNo := WorkOrder."Project Task No.";
            WorkOrderObj.Add('no', WorkOrder."Work Order No.");
            WorkOrderObj.Add('description', WorkOrder.Description);
            WorkOrderObj.Add('notEarlierThan', ReqAssign_FormatIsoDate(WorkOrder."Planned Start Date"));
            WorkOrderObj.Add('notLaterThan', ReqAssign_FormatIsoDate(WorkOrder."Planned End Date"));
        end else begin
            WorkOrderObj.Add('no', WorkOrderNo);
            WorkOrderObj.Add('description', '');
            WorkOrderObj.Add('notEarlierThan', '');
            WorkOrderObj.Add('notLaterThan', '');
        end;

        if (JobNo <> '') and Job.Get(JobNo) then begin
            ProjectObj.Add('no', JobNo);
            ProjectObj.Add('description', Job.Description);
        end else begin
            ProjectObj.Add('no', JobNo);
            ProjectObj.Add('description', '');
        end;

        if NumberOfDays <= 0 then
            NumberOfDays := 30;
        StartDate := Today();
        EndDate := StartDate + NumberOfDays - 1;

        RootObj.Add('daysToShow', NumberOfDays);
        RootObj.Add('startDate', ReqAssign_FormatIsoDate(StartDate));
        RootObj.Add('endDate', ReqAssign_FormatIsoDate(EndDate));
        RootObj.Add('workdays', CPO_BuildDateRangeArray(StartDate, EndDate));

        if WorkOrderFound then begin
            // ---- Pass 1 + Pass 2: WorkOrderNo's OWN lines (section 2/workOrderSequences[]) -
            // byte-for-byte identical to CPO_BuildPlanningDataJson's own Pass 1/2, unchanged/
            // un-paginated (bounded to one Work Order's own lines, never the cost driver). ----
            DayPlanning.SetLoadFields("Job No.", "Job Task No.", "Day Line No.", Skill, "Sequence No.", Description,
                "Plan Date", Assigned, "Assigned Resource No.", "Requested Hours", "Assigned Hours",
                "Start Time Requested", "End Time Requested", "Start Time Assigned", "End Time Assigned",
                "Work Order No.");
            if JobNo <> '' then begin
                DayPlanning.SetRange("Job No.", JobNo);
                DayPlanning.SetRange("Job Task No.", JobTaskNo);
            end else
                DayPlanning.SetRange("Work Order No.", WorkOrderNo);

            if DayPlanning.FindSet() then
                repeat
                    DayPlanningLinesArr.Add(CPO_BuildDayPlanningLineObj(DayPlanning, WorkOrderNo, JobNo, JobTaskNo));

                    if DayPlanning.Skill <> '' then begin
                        if not ActiveSkillList.Contains(DayPlanning.Skill) then
                            ActiveSkillList.Add(DayPlanning.Skill);

                        SeqKeyTxt := DayPlanning.Skill + '|' + DayPlanning."Job No." + '|' + DayPlanning."Job Task No." + '|' + Format(DayPlanning."Sequence No.");
                        if not SeqOrder.Contains(SeqKeyTxt) then begin
                            SeqOrder.Add(SeqKeyTxt);
                            SeqSkill.Add(DayPlanning.Skill);
                            SeqJobNo.Add(DayPlanning."Job No.");
                            SeqJobTaskNo.Add(DayPlanning."Job Task No.");
                            SeqSequenceNo.Add(DayPlanning."Sequence No.");
                            SeqLineNo.Add(DayPlanning."Day Line No.");
                        end;
                    end;
                until DayPlanning.Next() = 0;

            if DayPlanning.FindSet() then
                repeat
                    if DayPlanning.Skill <> '' then begin
                        SeqKeyTxt := DayPlanning.Skill + '|' + DayPlanning."Job No." + '|' + DayPlanning."Job Task No." + '|' + Format(DayPlanning."Sequence No.");
                        SeqIdx := CPO_IndexOfText(SeqOrder, SeqKeyTxt);
                        if SeqIdx > 0 then begin
                            WorkdayOffset := CPO_ComputeWorkdayOffset(StartDate, DayPlanning."Plan Date");
                            if WorkdayOffset >= 1 then begin
                                OffsetKeyTxt := Format(SeqIdx) + '|' + Format(WorkdayOffset);
                                if not SeqOffsetKeyOrder.Contains(OffsetKeyTxt) then
                                    SeqOffsetKeyOrder.Add(OffsetKeyTxt);
                                CurHours := 0;
                                if SeqOffsetHours.ContainsKey(OffsetKeyTxt) then
                                    CurHours := SeqOffsetHours.Get(OffsetKeyTxt);
                                SeqOffsetHours.Set(OffsetKeyTxt, CurHours + DayPlanning."Requested Hours");
                            end;
                        end;
                    end;
                until DayPlanning.Next() = 0;

            // ---- Pass 3a: cheap, ALWAYS-full scan - complete skills/groups structure. ----
            CPO_ScanOtherWorkOrderGroups(JobNo, JobTaskNo, StartDate, EndDate, ActiveSkillList, OtherSkillList,
                GroupOrder, GroupSkill, GroupJobNo, GroupJobTaskNo, GroupDescription, GroupLineCount);

            // ---- Decide the first page's whole groups (greedy, in first-seen order) vs the
            // remainder - same greedy-until-MaxLines-exceeded shape as ReqAssign_
            // BuildDayTaskLinesJson_Paged's own cutoff. ----
            RunningTotal := 0;
            foreach GroupKeyTxt in GroupOrder do
                if RunningTotal < MaxOtherLines then begin
                    FirstPageGroupKeys.Add(GroupKeyTxt, true);
                    RunningTotal += GroupLineCount.Get(GroupKeyTxt);
                end else
                    RemainingGroupKeysArr.Add(GroupKeyTxt);

            if RemainingGroupKeysArr.Count() > 0 then
                RemainingGroupKeysArr.WriteTo(RemainingGroupKeys)
            else
                RemainingGroupKeys := '';

            // ---- Pass 3b: expensive per-line build, ONLY for the first page's groups. ----
            FirstPageOtherLinesArr := CPO_BuildOtherWorkOrderLinesForGroups(WorkOrderNo, JobNo, JobTaskNo, StartDate, EndDate, FirstPageGroupKeys);
            foreach LineTok in FirstPageOtherLinesArr do
                DayPlanningLinesArr.Add(LineTok.AsObject());
        end;

        RootObj.Add('project', ProjectObj);
        RootObj.Add('workOrder', WorkOrderObj);
        RootObj.Add('skills', CPO_BuildSkillsArray(ActiveSkillList));
        RootObj.Add('resources', CPO_BuildResourcesArray(ActiveSkillList, ResourcePool));
        RootObj.Add('baseCapacity', 8);
        RootObj.Add('externalFree', CPO_BuildExternalFreeArray(ResourcePool, StartDate, EndDate));
        // groups[] is the COMPLETE tree skeleton (every group, not just the first page) - see this
        // region's own header comment for why that's safe/cheap; only its LINES (chips) backfill.
        RootObj.Add('groups', CPO_BuildGroupsArray(OtherSkillList, GroupSkill, GroupJobNo, GroupJobTaskNo, GroupDescription));
        RootObj.Add('dayPlanningLines', DayPlanningLinesArr);
        RootObj.Add('workOrderSequences', CPO_BuildWorkOrderSequencesArray(SeqOrder, SeqSkill, SeqJobNo, SeqJobTaskNo, SeqSequenceNo, SeqLineNo, SeqOffsetKeyOrder, SeqOffsetHours));

        RootObj.WriteTo(OutTxt);
        exit(OutTxt);
    end;

    /// <summary>
    /// Page Background Task companion to CPO_BuildPlanningDataJson_Paged (called from codeunit "CPO
    /// BG Other WO Data"'s OnRun) - builds the SAME per-line JSON (via CPO_
    /// BuildOtherWorkOrderLinesForGroups/CPO_BuildDayPlanningLineObj) for only the OTHER Work
    /// Orders' groups named in RemainingGroupKeysJson (the paged builder's own RemainingGroupKeys
    /// out parameter). Runs in the background task's own session, so StartDate/EndDate are passed
    /// in explicitly (formatted text, parsed by the caller) rather than recomputed from
    /// NumberOfDays/Today() - avoids any midnight-boundary drift between the interactive session's
    /// window and the background session's own. Returns the resulting JSON array already
    /// serialized to Text (what the Page Background Task stashes into its result Dictionary and the
    /// control add-in's AppendOtherWorkOrderData consumes) - '[]' when RemainingGroupKeysJson is
    /// blank (a no-op call).
    /// </summary>
    procedure CPO_BuildOtherWorkOrderLinesJson_ForKeys(WorkOrderNo: Code[20]; StartDate: Date; EndDate: Date; RemainingGroupKeysJson: Text): Text
    var
        WorkOrder: Record "Work Order";
        WantedGroupKeys: Dictionary of [Text, Boolean];
        WantedGroupKeysArr: JsonArray;
        KeyTok: JsonToken;
        LinesArr: JsonArray;
        JobNo: Code[20];
        JobTaskNo: Code[20];
        OutTxt: Text;
    begin
        if RemainingGroupKeysJson = '' then
            exit('[]');

        if WorkOrder.Get(WorkOrderNo) then begin
            JobNo := WorkOrder."Project No.";
            JobTaskNo := WorkOrder."Project Task No.";
        end;

        WantedGroupKeysArr.ReadFrom(RemainingGroupKeysJson);
        foreach KeyTok in WantedGroupKeysArr do
            WantedGroupKeys.Add(KeyTok.AsValue().AsText(), true);

        LinesArr := CPO_BuildOtherWorkOrderLinesForGroups(WorkOrderNo, JobNo, JobTaskNo, StartDate, EndDate, WantedGroupKeys);
        LinesArr.WriteTo(OutTxt);
        exit(OutTxt);
    end;

    /// <summary>
    /// Caps the per-skill resource pool fed into the client-side max-flow engine
    /// (capacityPlanningOverview.js's maxFlowDay) - deliberately NOT "every company resource
    /// holding this skill" (this demo company alone was observed seeding 100+ resources for some
    /// skills, per this add-in's project memory). maxFlowDay's Edmonds-Karp-style augmenting-path
    /// search cost scales roughly with (resource count)^2 per day, and it is called from BOTH the
    /// section-1 cell templates AND evaluateWO/currentPositionShortage's own internal per-day
    /// loops - an uncapped pool would make the browser hang on this real demo data. 15 is a
    /// deliberate, PERFORMANCE-driven scoping choice, not a data-completeness compromise: the
    /// max-flow model's achievable coverage is capped by DEMAND, not supply (see this add-in's
    /// project memory for the full reasoning), so a smaller-than-total-but-non-empty resource pool
    /// still produces a meaningful, non-inflated percentage.
    /// </summary>
    local procedure CPO_MaxResourcesPerSkill(): Integer
    begin
        exit(15);
    end;

    /// <summary>
    /// Builds "skills[]" - one entry per distinct Skill this Work Order's project demands, colors
    /// resolved via codeunit 50609's existing GetSkillBarColor/GetSkillBorderColor/GetSkillFontColor
    /// (same PaletteIndex-increments-in-first-encountered-order convention as this codeunit's own
    /// ResolveRequestedColor) - no new color source invented. "dark"/"light" (used by the ported
    /// JS's gradient-fill chip/bar rendering) reuse the same border/fill pair every OTHER caller in
    /// this codeunit already treats as the "deep"/"light" tone for a skill, since no separate
    /// dark/light tint helper exists in codeunit 50609.
    /// </summary>
    local procedure CPO_BuildSkillsArray(var ActiveSkillList: List of [Code[20]]): JsonArray
    var
        ColorConstants: Codeunit "Visual Default Settings";
        SkillsArr: JsonArray;
        SkillObj: JsonObject;
        SkillCode: Code[20];
        PaletteIndex: Integer;
        FillColorTxt: Text;
        BorderColorTxt: Text;
    begin
        foreach SkillCode in ActiveSkillList do begin
            FillColorTxt := ColorConstants.GetSkillBarColor(CopyStr(SkillCode, 1, 10), PaletteIndex);
            BorderColorTxt := ColorConstants.GetSkillBorderColor(CopyStr(SkillCode, 1, 10), PaletteIndex);

            Clear(SkillObj);
            SkillObj.Add('code', SkillCode);
            SkillObj.Add('color', FillColorTxt);
            SkillObj.Add('textColor', ColorConstants.GetSkillFontColor(CopyStr(SkillCode, 1, 10)));
            SkillObj.Add('border', BorderColorTxt);
            SkillObj.Add('dark', BorderColorTxt);
            SkillObj.Add('light', FillColorTxt);
            SkillsArr.Add(SkillObj);
            PaletteIndex += 1;
        end;
        exit(SkillsArr);
    end;

    /// <summary>
    /// Builds "resources[]" - "name" is deliberately the resource's own "No." (NOT its friendly
    /// Name field): the reference's dayPlanningLines[].assignedResourceNo and resources[].name are
    /// the SAME join key throughout every ported function (resourceAssignedHours/
    /// resourceRemaining match on this value), and this add-in's own "Assigned Resource No." field
    /// is already the resource's No. - keeping "name" = No. preserves that join without a second
    /// display-name lookup.
    ///
    /// Pool scope: every resource holding ANY skill this WO's project demands (NOT project-team-
    /// scoped, unlike the pre-pivot engine's corrected formula) - deliberately broader, because the
    /// max-flow model's own achievable coverage is capped by demand, not supply (see this add-in's
    /// project memory for the full reasoning this pivot is based on), so a wider real supply pool
    /// is the CORRECT input now, not a bug risk like it was for the old simple formula. Capped at
    /// CPO_MaxResourcesPerSkill() new resources per skill (see that procedure's own doc comment)
    /// purely for client-side max-flow performance - a real, deliberate, documented gap, not a
    /// silent approximation.
    /// </summary>
    local procedure CPO_BuildResourcesArray(var ActiveSkillList: List of [Code[20]]; var ResourceOrder: List of [Code[20]]): JsonArray
    var
        ResourceSkill: Record "Resource Skill";
        ResourcesArr: JsonArray;
        ResourceObj: JsonObject;
        SkillsForResourceArr: JsonArray;
        SkillCode: Code[20];
        ResourceNo: Code[20];
        CountForSkill: Integer;
    begin
        foreach SkillCode in ActiveSkillList do begin
            CountForSkill := 0;
            ResourceSkill.Reset();
            ResourceSkill.SetLoadFields("No.");
            ResourceSkill.SetRange(Type, ResourceSkill.Type::Resource);
            ResourceSkill.SetRange("Skill Code", SkillCode);
            if ResourceSkill.FindSet() then
                repeat
                    if not ResourceOrder.Contains(ResourceSkill."No.") then begin
                        ResourceOrder.Add(ResourceSkill."No.");
                        CountForSkill += 1;
                    end;
                until (ResourceSkill.Next() = 0) or (CountForSkill >= CPO_MaxResourcesPerSkill());
        end;

        foreach ResourceNo in ResourceOrder do begin
            Clear(SkillsForResourceArr);
            foreach SkillCode in ActiveSkillList do begin
                ResourceSkill.Reset();
                ResourceSkill.SetRange(Type, ResourceSkill.Type::Resource);
                ResourceSkill.SetRange("No.", ResourceNo);
                ResourceSkill.SetRange("Skill Code", SkillCode);
                if not ResourceSkill.IsEmpty() then
                    SkillsForResourceArr.Add(SkillCode);
            end;

            Clear(ResourceObj);
            ResourceObj.Add('name', ResourceNo);
            ResourceObj.Add('skills', SkillsForResourceArr);
            ResourcesArr.Add(ResourceObj);
        end;
        exit(ResourcesArr);
    end;

    /// <summary>
    /// Builds "externalFree[]" - one entry per calendar day in [StartDate, EndDate], summing real
    /// "Res. Capacity Entry".Capacity for whichever of THIS payload's own already-built
    /// "resources[]" pool (ResourceOrder, as returned by CPO_BuildResourcesArray - the same
    /// skill-scoped, CPO_MaxResourcesPerSkill()-capped pool "internal" capacity is computed from,
    /// see capParts()/capacityPlanningOverview.js) also has a non-blank "Vendor No." (this
    /// codebase's existing external/subcontracted-resource marker, per tableext 50603).
    /// Deliberately NOT a separate, differently-scoped "every Resource company-wide with a Vendor
    /// No." query - an earlier version of this procedure queried ALL vendor-linked resources
    /// company-wide with no skill-relevance filter or cap, which inflated section 3's daily
    /// capacity totals into the hundreds of hours (confirmed live: ~822h/day against DWO0008,
    /// clearly disproportionate next to the internal pool's own capped 15*8=120h/day ceiling) -
    /// reusing the SAME already-capped resource list keeps "external" and "internal" capacity
    /// commensurate with each other, both scoped to resources actually relevant to this WO's own
    /// demanded skills. A day with no such resources or no capacity entries legitimately sums to 0
    /// (not fabricated).
    /// </summary>
    local procedure CPO_BuildExternalFreeArray(var ResourceOrder: List of [Code[20]]; StartDate: Date; EndDate: Date): JsonArray
    var
        ExtResource: Record Resource;
        ResCapacityEntry: Record "Res. Capacity Entry";
        ExternalArr: JsonArray;
        ByDate: Dictionary of [Date, Decimal];
        ResourceNo: Code[20];
        CurDate: Date;
        CurVal: Decimal;
    begin
        foreach ResourceNo in ResourceOrder do begin
            ExtResource.Reset();
            ExtResource.SetLoadFields("Vendor No.");
            if ExtResource.Get(ResourceNo) and (ExtResource."Vendor No." <> '') then begin
                ResCapacityEntry.Reset();
                ResCapacityEntry.SetLoadFields(Date, Capacity);
                ResCapacityEntry.SetRange("Resource No.", ResourceNo);
                ResCapacityEntry.SetRange(Date, StartDate, EndDate);
                if ResCapacityEntry.FindSet() then
                    repeat
                        CurVal := 0;
                        if ByDate.ContainsKey(ResCapacityEntry.Date) then
                            CurVal := ByDate.Get(ResCapacityEntry.Date);
                        ByDate.Set(ResCapacityEntry.Date, CurVal + ResCapacityEntry.Capacity);
                    until ResCapacityEntry.Next() = 0;
            end;
        end;

        CurDate := StartDate;
        while CurDate <= EndDate do begin
            CurVal := 0;
            if ByDate.ContainsKey(CurDate) then
                CurVal := ByDate.Get(CurDate);
            ExternalArr.Add(CurVal);
            CurDate += 1;
        end;
        exit(ExternalArr);
    end;

    /// <summary>
    /// Builds "groups[]" (section 4's tree source data) - one entry per distinct Skill, each with
    /// "details[]" = one entry per distinct Job No./Job Task No. that skill's demand touches. This
    /// is ALL the AL-side tree building needed now - the ported JS's own buildCentralSections()/
    /// skillDaySummary()/taskDaySummary()/sequenceDayLines() derive the rest (per-day summaries,
    /// the Sequence leaf level, per-line chip cells) CLIENT-SIDE straight from "groups" +
    /// "dayPlanningLines", exactly like the reference prototype does - the old
    /// CPO_BuildTreeNodesArray/CPO_BuildDayTotalsObj/CPO_BuildTreeCellsObj machinery this replaces
    /// is gone.
    ///
    /// CALLER CONTRACT CHANGED (2026-09-03, explicit user correction - see this add-in's project
    /// memory): the caller (CPO_BuildPlanningDataJson) now passes OtherSkillList/GroupSkill/
    /// GroupJobNo/GroupJobTaskNo/GroupDescription built from every OTHER Work Order's demand in
    /// the visible window (Pass 3), NOT the inspected WorkOrderNo's own data - Section 4 is
    /// "everything else going on in this window", per the user's own words. This procedure itself
    /// is unchanged; only what the caller feeds it changed.
    /// </summary>
    local procedure CPO_BuildGroupsArray(var ActiveSkillList: List of [Code[20]]; var GroupSkill: List of [Code[20]]; var GroupJobNo: List of [Code[20]]; var GroupJobTaskNo: List of [Code[20]]; var GroupDescription: List of [Text]): JsonArray
    var
        GroupsArr: JsonArray;
        GroupObj: JsonObject;
        DetailsArr: JsonArray;
        DetailObj: JsonObject;
        SkillCode: Code[20];
        i: Integer;
    begin
        foreach SkillCode in ActiveSkillList do begin
            Clear(DetailsArr);
            for i := 1 to GroupSkill.Count() do
                if GroupSkill.Get(i) = SkillCode then begin
                    Clear(DetailObj);
                    DetailObj.Add('job', GroupJobNo.Get(i));
                    DetailObj.Add('task', GroupJobTaskNo.Get(i));
                    DetailObj.Add('description', GroupDescription.Get(i));
                    DetailsArr.Add(DetailObj);
                end;

            Clear(GroupObj);
            GroupObj.Add('skill', SkillCode);
            GroupObj.Add('expanded', true);
            GroupObj.Add('details', DetailsArr);
            GroupsArr.Add(GroupObj);
        end;
        exit(GroupsArr);
    end;

    /// <summary>
    /// Linear-scan index-of over a List of [Text] (1-based, 0 if not found) - AL's List type has no
    /// built-in IndexOf; used by CPO_BuildPlanningDataJson's pass 2 to resolve a Day Planning
    /// line's own sequence position within SeqOrder. Cost is O(sequence count) per line, trivial at
    /// this feature's scale (one Work Order's own lines/sequences, never company-wide).
    /// </summary>
    local procedure CPO_IndexOfText(var TextList: List of [Text]; Value: Text): Integer
    var
        i: Integer;
    begin
        for i := 1 to TextList.Count() do
            if TextList.Get(i) = Value then
                exit(i);
        exit(0);
    end;

    /// <summary>
    /// Reverse of the ported JS's own idxWork(start,wd) (DHTMLXtempv112-app.js ~L150-154): given
    /// AnchorDate (always this payload's own StartDate - see CPO_BuildPlanningDataJson's doc
    /// comment) and a real TargetDate, returns the 1-based workday-offset "wd" such that
    /// idxWork(dayIndex(AnchorDate), wd) lands back on TargetDate - i.e. workdays are counted from
    /// the first workday AT OR AFTER AnchorDate (matching idxWork's own "while(isWeekendDate(i))
    /// i++" when wd=1), incrementing once per workday, weekends skipped. Returns 0 (caller treats
    /// as "exclude this occurrence") if TargetDate falls before the effective anchor, which should
    /// not happen in practice since AnchorDate is always this payload's own window start and real
    /// Day Planning lines are only ever queried within that same window.
    /// </summary>
    local procedure CPO_ComputeWorkdayOffset(AnchorDate: Date; TargetDate: Date): Integer
    var
        EffectiveAnchor: Date;
        CurDate: Date;
        OffsetCount: Integer;
    begin
        if (AnchorDate = 0D) or (TargetDate = 0D) then
            exit(0);

        EffectiveAnchor := AnchorDate;
        while Date2DWY(EffectiveAnchor, 1) in [6, 7] do
            EffectiveAnchor += 1;

        if TargetDate < EffectiveAnchor then
            exit(0);

        CurDate := EffectiveAnchor;
        while CurDate <= TargetDate do begin
            if not (Date2DWY(CurDate, 1) in [6, 7]) then
                OffsetCount += 1;
            CurDate += 1;
        end;
        exit(OffsetCount);
    end;

    /// <summary>
    /// Collects every workday-offset recorded for sequence position SeqIndex out of
    /// SeqOffsetKeyOrder (keys shaped "SeqIndex|Offset" - see CPO_BuildPlanningDataJson's pass 2),
    /// sorted ascending via simple insertion (trivial cost - one Work Order's own occurrence count
    /// per sequence is always small). Used by CPO_BuildWorkOrderSequencesArray to build each
    /// sequence's own "workdays[]" in the exact ascending order the reference's own mock data
    /// shape uses.
    /// </summary>
    local procedure CPO_BuildSortedOffsets(var SeqOffsetKeyOrder: List of [Text]; SeqIndex: Integer; var SortedOffsets: List of [Integer])
    var
        KeyTxt: Text;
        PrefixTxt: Text;
        OffsetPart: Text;
        OffsetVal: Integer;
        TempVal: Integer;
        i: Integer;
        j: Integer;
    begin
        Clear(SortedOffsets);
        PrefixTxt := Format(SeqIndex) + '|';
        foreach KeyTxt in SeqOffsetKeyOrder do
            if CopyStr(KeyTxt, 1, StrLen(PrefixTxt)) = PrefixTxt then begin
                OffsetPart := CopyStr(KeyTxt, StrLen(PrefixTxt) + 1);
                if Evaluate(OffsetVal, OffsetPart) then
                    SortedOffsets.Add(OffsetVal);
            end;

        // Simple in-place bubble sort using ONLY Get/Set (both operate on an EXISTING index in
        // [1,Count] and never throw) - deliberately NOT List.Insert (confirmed live to throw "An
        // invalid argument was passed to a 'List' data type method" the moment its target index
        // reaches Count+1, i.e. appending past the current end - a case an insertion-sort's own
        // "biggest value so far" step hits immediately on the very first element). Offset counts
        // per sequence are always tiny (bounded by this one Work Order's own real Day Planning
        // line count), so this O(n^2) pass is trivially cheap.
        for i := 1 to SortedOffsets.Count() do
            for j := 1 to SortedOffsets.Count() - i do
                if SortedOffsets.Get(j) > SortedOffsets.Get(j + 1) then begin
                    TempVal := SortedOffsets.Get(j);
                    SortedOffsets.Set(j, SortedOffsets.Get(j + 1));
                    SortedOffsets.Set(j + 1, TempVal);
                end;
    end;

    /// <summary>
    /// Builds "workOrderSequences[]" - one entry per distinct Skill+Job No.+Job Task No.+Sequence
    /// No. combination, each with "workdays[]" (ascending 1-based workday-offsets relative to this
    /// payload's own StartDate - see CPO_ComputeWorkdayOffset) and "hoursByWorkday" ({offset:
    /// hours}, summed if more than one real line ever lands on the same offset for this sequence,
    /// though normally exactly one Day Planning line per day). This is the ONE field with no direct
    /// real-BC equivalent (BC has no synthetic anchor-relative workday model of its own) - derived
    /// entirely from the real "Plan Date"/"Requested Hours" values already collected in
    /// CPO_BuildPlanningDataJson's pass 2, so the ported JS's evaluateWO/idxWork/workOrderExtra
    /// keep working unchanged even though the underlying source data is real absolute dates.
    /// </summary>
    local procedure CPO_BuildWorkOrderSequencesArray(var SeqOrder: List of [Text]; var SeqSkill: List of [Code[20]]; var SeqJobNo: List of [Code[20]]; var SeqJobTaskNo: List of [Code[20]]; var SeqSequenceNo: List of [Integer]; var SeqLineNo: List of [Integer]; var SeqOffsetKeyOrder: List of [Text]; var SeqOffsetHours: Dictionary of [Text, Decimal]): JsonArray
    var
        SeqArr: JsonArray;
        SeqObj: JsonObject;
        WorkdaysArr: JsonArray;
        HoursObj: JsonObject;
        SortedOffsets: List of [Integer];
        OffsetVal: Integer;
        OffsetKeyTxt: Text;
        si: Integer;
    begin
        for si := 1 to SeqOrder.Count() do begin
            CPO_BuildSortedOffsets(SeqOffsetKeyOrder, si, SortedOffsets);

            Clear(WorkdaysArr);
            Clear(HoursObj);
            foreach OffsetVal in SortedOffsets do begin
                WorkdaysArr.Add(OffsetVal);
                OffsetKeyTxt := Format(si) + '|' + Format(OffsetVal);
                HoursObj.Add(Format(OffsetVal), SeqOffsetHours.Get(OffsetKeyTxt));
            end;

            Clear(SeqObj);
            SeqObj.Add('skill', SeqSkill.Get(si));
            SeqObj.Add('job', SeqJobNo.Get(si));
            SeqObj.Add('task', SeqJobTaskNo.Get(si));
            SeqObj.Add('lineNo', SeqLineNo.Get(si));
            SeqObj.Add('sequenceNo', SeqSequenceNo.Get(si));
            SeqObj.Add('workdays', WorkdaysArr);
            SeqObj.Add('hoursByWorkday', HoursObj);
            SeqArr.Add(SeqObj);
        end;
        exit(SeqArr);
    end;

    /// <summary>Blank-safe "HH:mm" Time formatting - "" (not "00:00") for an unset (0T) time, matching the reference mock data's own convention for a not-yet-scheduled line.</summary>
    local procedure CPO_FormatTimeHHMM(T: Time): Text
    begin
        if T = 0T then
            exit('');
        exit(Format(T, 0, '<Hours24,2>:<Minutes,2>'));
    end;

    /// <summary>
    /// Builds one "dayPlanningLines[]" entry from a Day Planning record, shaped per the reference's
    /// own mock data (DHTMLXtempv112-data.js). "id"/"sequenceLineNo" both derive from this table's
    /// own "Day Line No." (the only directly-analogous real field - the reference's mock "id"/
    /// "sequenceLineNo" are two independent synthetic values with no single real BC equivalent;
    /// reusing one real field for both is a documented simplification, not a fabrication).
    /// "assignedDate" mirrors "requestDate" when Assigned = true (Day Planning has no separate
    /// assigned-date field of its own - an assignment always lands on the same "Plan Date").
    /// "workOrderNo" (2026-09-03 addition - explicit user correction, see CPO_BuildPlanningDataJson's
    /// own Pass 3 doc comment) - dayPlanningLines[] now mixes WorkOrderNo's own rows with every
    /// other Work Order's rows in the same window, so the ported JS needs this real tag to keep
    /// each section scoped to whichever Work Order it is actually supposed to represent.
    /// </summary>
    local procedure CPO_BuildDayPlanningLineObj(var DayPlanning: Record "Day Planning"; InspectedWorkOrderNo: Code[20]; InspectedJobNo: Code[20]; InspectedJobTaskNo: Code[20]): JsonObject
    var
        LineObj: JsonObject;
        EffectiveWorkOrderNo: Code[20];
    begin
        // Normalizes 'workOrderNo' to the INSPECTED Work Order's own No. whenever this line's
        // Job No./Job Task No. matches it (2026-09-03 bug fix companion to
        // CPO_BuildPlanningDataJson's Pass 1/Pass 3 rescoping) - the raw "Work Order No." FIELD
        // can be blank on some of a Work Order's own genuine Day Planning Sequences, which would
        // otherwise make the ported JS's own workOrderNo-based section 2/3 matching wrongly treat
        // them as unaffiliated/foreign demand even though AL now correctly includes them as this
        // WO's own line. Any line that does NOT match (a genuinely other Work Order's line, or one
        // with no Job/Task at all) keeps its raw field value unchanged.
        EffectiveWorkOrderNo := DayPlanning."Work Order No.";
        if (InspectedJobNo <> '') and (DayPlanning."Job No." = InspectedJobNo) and (DayPlanning."Job Task No." = InspectedJobTaskNo) then
            EffectiveWorkOrderNo := InspectedWorkOrderNo;
        LineObj.Add('id', Format(DayPlanning."Day Line No."));
        LineObj.Add('workOrderNo', EffectiveWorkOrderNo);
        LineObj.Add('job', DayPlanning."Job No.");
        LineObj.Add('task', DayPlanning."Job Task No.");
        LineObj.Add('description', DayPlanning.Description);
        LineObj.Add('sequenceLineNo', DayPlanning."Day Line No.");
        LineObj.Add('requestDate', ReqAssign_FormatIsoDate(DayPlanning."Plan Date"));
        LineObj.Add('requestedStartTime', CPO_FormatTimeHHMM(DayPlanning."Start Time Requested"));
        LineObj.Add('requestedEndTime', CPO_FormatTimeHHMM(DayPlanning."End Time Requested"));
        LineObj.Add('requestedHours', DayPlanning."Requested Hours");
        LineObj.Add('requestedSkill', DayPlanning.Skill);
        LineObj.Add('assignedResourceNo', DayPlanning."Assigned Resource No.");
        if DayPlanning.Assigned then
            LineObj.Add('assignedDate', ReqAssign_FormatIsoDate(DayPlanning."Plan Date"))
        else
            LineObj.Add('assignedDate', '');
        LineObj.Add('assignedStartTime', CPO_FormatTimeHHMM(DayPlanning."Start Time Assigned"));
        LineObj.Add('assignedEndTime', CPO_FormatTimeHHMM(DayPlanning."End Time Assigned"));
        LineObj.Add('assignedHours', DayPlanning."Assigned Hours");
        LineObj.Add('sequenceNo', DayPlanning."Sequence No.");
        exit(LineObj);
    end;

    /// <summary>
    /// Every calendar day from StartDate to EndDate inclusive, as "yyyy-MM-dd" ISO strings, in
    /// order - deliberately NOT the Mon-Fri-only convention ReqAssign_BuildWorkdayIndexMap uses,
    /// since this feature's visible window must be a contiguous date range (weekends included)
    /// over one Work Order's own planned-date span, not a workday-only calendar.
    /// </summary>
    local procedure CPO_BuildDateRangeArray(StartDate: Date; EndDate: Date): JsonArray
    var
        DatesArr: JsonArray;
        CurDate: Date;
    begin
        CurDate := StartDate;
        while CurDate <= EndDate do begin
            DatesArr.Add(ReqAssign_FormatIsoDate(CurDate));
            CurDate += 1;
        end;
        exit(DatesArr);
    end;

}