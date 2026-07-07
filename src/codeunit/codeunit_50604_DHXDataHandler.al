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
    begin
        PlanninJsonTxt := '';
        //Marking Job based on Day Plannings within the given date range
        DayPlanning.SetCurrentKey("Task Date", "Start Time Assigned");
        DayPlanning.SetRange("Task Date", StartDate, EndDate);
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
                // create event data
                if AnchorDate = 0D then
                    CountToWeekNumber(DayPlanning."Task Date", WeekTemp);

                GetStartEndTxt(DayPlanning, StartDateTxt, EndDateTxt);
                Clear(PlanningObject);
                PlanningObject.Add('id', DayPlanning."Job No." + '|' +
                                         DayPlanning."Job Task No." + '|' +
                                         Format(DayPlanning."Task Date") + '|' +
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
                if ResNo = '' then begin
                    PlanningObject.Add('color', '#3367D1'); //Blue BC Selection
                    PlanningObject.Add('type', 'DayPlanning_0');
                end else begin
                    PlanningObject.Add('color', '#21B36C'); //Green
                    PlanningObject.Add('type', 'DayPlanning_1');
                end;

                if not Ven.Get(DayPlanning."Vendor No.") then
                    Clear(Ven);
                PlanningObject.Add('details', Ven.Name);
                // StrSubstNo(DetailsLabel, Ven."No.", Ven.Name
                // , DayPlanning."Job No.", Jobs.Description
                // , DayPlanning."Job Task No.", JobTasks.Description));

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
        DayPlanning.SetRange("Task Date", FromDate, ToDate);
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
        DayPlanning.SetRange("Task Date", FromDate, ToDate);
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
                    DayPlanning.setrange("Task Date", DateRec."Period Start");
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
                                   var EarliestPlanningDate: Date): Text
    var
        ResCap: Record "Res. Capacity Entry";
        PoolRes: Record Resource;
        WeekTemp: record "Aging Band Buffer" temporary;
        TempResGroup: record "Resource Group" temporary;
        TempPoolRes: record "Aging Band Buffer" temporary;
        ResourceTemp: Record Resource temporary;
        TempPool: record Resource temporary;
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
                            if not Resource.Get(ResCap."Resource No.") then
                                Clear(Resource);
                            section_id := section_id + '|' + Resource."Pool Resource No.";
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
                    DayPlanning.setrange("Task Date", DateRec."Period Start");
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
                    // Vendor and Resource
                    GetUniqueResFromCapacity_Pool(ResourceTemp, TempPool, TempResGroup."No.", StartDate, EndDate);
                    TempPool.Setcurrentkey("Pool Resource No.", "No.");
                    if TempPool.FindSet() then
                        repeat
                            // 2. Vendor
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
                            GroupChildrenArray.Add(InternalExternalObject);
                            Clear(InternalExternalChildrenArray);

                            // 3. Resource
                            ResourceTemp.SetRange("Pool Resource No.", TempPool."No.");
                            if ResourceTemp.FindSet() then begin
                                repeat
                                    if not Resource.Get(ResourceTemp."No.") then
                                        Clear(Resource);
                                    Clear(ResourceObject);
                                    ResourceObject.Add('key', TempResGroup."No." + '|' + ResourceTemp."No." + '|' + Resource."Pool Resource No.");
                                    ResourceObject.Add('label', ResourceTemp.Name);
                                    ResourceObject.Add('category', 'Resource');
                                    InternalExternalChildrenArray.Add(ResourceObject);
                                until ResourceTemp.Next() = 0;
                                InternalExternalObject.Add('children', InternalExternalChildrenArray);
                            end;

                        until TempPool.Next() = 0;
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
        if DayPlanning."Task Date" = 0D then
            exit;

        case true of
            (DayPlanning."Start Time Assigned" <> 0T) and (DayPlanning."End Time Assigned" <> 0T):
                begin
                    StartDateTxt := ToSessionDateTimeTxt(DayPlanning."Task Date", DayPlanning."Start Time Assigned");
                    EndDateTxt := ToSessionDateTimeTxt(DayPlanning."Task Date", DayPlanning."End Time Assigned");
                end;
            (DayPlanning."Start Time Assigned" <> 0T) and (DayPlanning."End Time Assigned" = 0T):
                begin
                    StartDateTxt := ToSessionDateTimeTxt(DayPlanning."Task Date", DayPlanning."Start Time Assigned");
                    EndDateTxt := Format(DayPlanning."Task Date", 0, '<Year4>-<Month,2>-<Day,2>') + ' 23:59:59';
                end;
            (DayPlanning."Start Time Assigned" = 0T) and (DayPlanning."End Time Assigned" <> 0T):
                begin
                    StartDateTxt := Format(DayPlanning."Task Date", 0, '<Year4>-<Month,2>-<Day,2>') + ' 00:00';
                    EndDateTxt := ToSessionDateTimeTxt(DayPlanning."Task Date", DayPlanning."End Time Assigned");
                end;
            (DayPlanning."Start Time Assigned" = 0T) and (DayPlanning."End Time Assigned" = 0T):
                begin
                    StartDateTxt := Format(DayPlanning."Task Date", 0, '<Year4>-<Month,2>-<Day,2>') + ' 00:00';
                    EndDateTxt := Format(DayPlanning."Task Date", 0, '<Year4>-<Month,2>-<Day,2>') + ' 23:59:59';
                end;
        end;
    end;

    procedure GetStartEndTxt(ResCap: Record "Res. Capacity Entry";
                                   Capacity: Decimal;
                                   var StartDateTxt: Text;
                                   var EndDateTxt: Text)
    var
        tm: Time;
        StartDateTime: DateTime;
        EndDateTime: DateTime;
        CapacityDuration: Duration;
    begin
        StartDateTxt := '';
        EndDateTxt := '';
        if ResCap."Date" = 0D then
            exit;

        tm := ResCap."Start Time";
        if tm = 0T then
            tm := 070000T;

        // Convert start date and time to DateTime
        StartDateTime := CreateDateTime(ResCap."Date", tm);
        StartDateTxt := ToSessionDateTimeTxt(ResCap."Date", tm);

        // Calculate capacity as duration in milliseconds
        // Capacity is in hours, so: hours * 60 minutes * 60 seconds * 1000 milliseconds
        CapacityDuration := Capacity * 60 * 60 * 1000;

        // Add capacity duration to start datetime
        EndDateTime := StartDateTime + CapacityDuration;

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
                                ToSessionDateTimeTxt(DayPlanning."Task Date", DayPlanning."Start Time Assigned"),
                                ToSessionDateTimeTxt(DayPlanning."Task Date", DayPlanning."End Time Assigned"),
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
        DayPlanning.SetRange("Job No.", JobNo);
        DayPlanning.SetRange("Job Task No.", TaskNo);
        DayPlanning.SetRange("Task Date", PlanningDate);
        if DayPlanning.FindLast() then
            LineNo := DayPlanning."Day Line No." + 10000;

        DayPlanning.Init();
        DayPlanning."Task Date" := PlanningDate;
        DayPlanning."Day Line No." := LineNo;
        DayPlanning."Job No." := JobNo;
        DayPlanning."Job Task No." := TaskNo;

        DayPlanning."Assigned Resource No." := Res."No.";
        DayPlanning."Start Time Assigned" := StartTime;
        DayPlanning."End Time Assigned" := EndTime;
        DayPlanning.Description := Res.Name;
        UpdateEventIdJsonTxt := StrSubstNo(JsonLbl,
                                            old_eventid,
                                            DayPlanning."Job No.",
                                            DayPlanning."Job Task No.",
                                            format(DayPlanning."Task Date"),
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
        OldDayPlanning."Task Date" := DT2Date(_DateTimeUserZone);
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
                         Format(OldDayPlanning."Task Date"),
                         Format(OldDayPlanning."Day Line No."),
                         NewDayPlanning."Job No.",
                         NewDayPlanning."Job Task No.",
                         Format(NewDayPlanning."Task Date"),
                         Format(NewDayPlanning."Day Line No."));
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
        DayPlanning.SetRange("Task Date", TaskDay);
        //DayPlanning.SetRange("DayLineNo", DayLineNo);
        DayPlanning.SetRange("Job No.", JobNo);
        DayPlanning.SetRange("Job Task No.", TaskNo);
        if DayPlanning.FindFirst() then begin
            DateOfDayPlanning := DayPlanning."Task Date";
            Clear(DayPlannings);
            DayPlannings.SetTableView(DayPlanning);
            DayPlannings.RunModal();
        end else
            Message(MsgLbl, eventId);
        exit(DateOfDayPlanning);
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
                                                                   var EarliestPlanningDate: date): Boolean
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
                                            EarliestPlanningDate);
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

        DayPlannings.SetRange("Task Date", StartDate, EndDate);
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

        DayPlannings.SetRange("Task Date", StartDate, EndDate);
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
                                       EndDate: Date)
    var
        Res: record Resource;
        UniqueResQry: Query "Unique Resource in Capacity";
        ResNo: Code[20];
        PoolNo: Code[20];
    begin
        // Clear the temporary table
        TempRes.Reset();
        TempRes.DeleteAll();

        TempPoolRes.Reset();
        TempPoolRes.DeleteAll();

        // Open the query - it automatically groups by VendorNo giving unique values
        UniqueResQry.SetRange(EntryDateFilter, StartDate, EndDate);
        UniqueResQry.SetRange(Resource_Group_No_, ResGroupNo);
        if UniqueResQry.Open() then begin
            while UniqueResQry.Read() do begin
                PoolNo := '';
                ResNo := UniqueResQry.Resource_No_;
                TempRes.Init();
                TempRes."No." := ResNo;
                if Res.Get(ResNo) then begin
                    TempRes.Name := Res.Name;
                    if res."Pool Resource No." <> '' then
                        PoolNo := res."Pool Resource No.";
                end;
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
            UniqueResQry.Close();
        end;
    end;

    procedure GetUniqueResGroupFromCapacity(var TempResGroup: record "Resource Group" temporary; WithDayPlanning: Boolean; StartDate: Date; EndDate: Date)
    var
        ResGroup: record "Resource Group";
        UniqueGroupQry: Query "Unique Group in Capacity";
        UniqueDayPlanningResGroupQry: Query "Unique ResGrp in DayPlannings";
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

        DayPlanning.SetRange("Task Date", StartDate, EndDate);
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
                        DayPlanningCheck.SetRange("Task Date", StartDate, EndDate);
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
        GetUniqueResFromCapacity_Pool(TempRes,
                                TempPool,
                                ResGroupNo,
                                StartDate,
                                EndDate);
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

    procedure ResScheduler_BuildResourcesJson(ResourceFilter: Text): Text
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
        if DayPlanning."Task Date" = 0D then
            exit;
        if DayPlanning."Start Time Requested" <> 0T then
            ReqStartDateTxt := ToSessionDateTimeTxt(DayPlanning."Task Date", DayPlanning."Start Time Requested");
        if DayPlanning."End Time Requested" <> 0T then
            ReqEndDateTxt := ToSessionDateTimeTxt(DayPlanning."Task Date", DayPlanning."End Time Requested");
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

    procedure ResScheduler_BuildEventsJson(ResourceFilter: Text; StartDate: Date; EndDate: Date): Text
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
            DayPlanning.SetRange("Task Date", StartDate, EndDate);
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

    procedure ResScheduler_BuildCapacityJson(ResourceFilter: Text; StartDate: Date; EndDate: Date): Text
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
    /// Used by the right-click context menu "Open DayPlanning Visual".
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
        DayPlanning.SetRange("Task Date", TaskDay);
        PAGE.Run(PAGE::"Resource Day Plannings", DayPlanning);
    end;
}