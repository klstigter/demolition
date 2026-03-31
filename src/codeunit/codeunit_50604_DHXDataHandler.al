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
        Daytask: Record "Day Tasks";
        WeekTemp: record "Aging Band Buffer" temporary;
        Resource: record Resource;
        Ven: Record Vendor;
        Job: Record Job;

        ResNo: Code[20];
        ResName: Text;
        CurrentJobNo: Code[20];

        JobObject, TaskObject, PlanningLineObject : JsonObject;
        ChildrenArray, ChildrenArray2 : JsonArray;
        PlanningObject, Root : JsonObject;
        PlanningArray, DataArray : JsonArray;
        OutText: Text;

        StartDateTxt: Text;
        EndDateTxt: Text;
        _DummyEndDate: Date;
        DetailsLabel: Label '%1 - %2|%3 - %4|%5 - %6';
    begin
        PlanninJsonTxt := '';
        //Marking Job based on Day Tasks within the given date range
        Daytask.SetCurrentKey("Task Date", "Start Time");
        Daytask.SetRange("Task Date", StartDate, EndDate);
        if JobFilter <> '' then
            Daytask.SetFilter("Job No.", JobFilter)
        else
            Daytask.SetFilter("Job No.", '<>%1', ''); //Exclude blank Job Nos
        if jobTaskFilter <> '' then
            Daytask.SetFilter("Job Task No.", jobTaskFilter)
        else
            Daytask.SetFilter("Job Task No.", '<>%1', ''); //Exclude blank task Nos
        if ResourceFilter <> '' then
            Daytask.Setfilter("No.", ResourceFilter);
        //Daytask.SetRange(Type, Daytask.Type::Resource);
        if Daytask.FindSet() then begin
            repeat
                JobTasks.Get(Daytask."Job No.", Daytask."Job Task No.");
                TEMPJobTasks := JobTasks;
                if not tempjobtasks.get(jobTasks."Job No.", jobTasks."Job Task No.") then begin
                    TEMPJobTasks.insert();
                    GetParentTasks(TEMPJobTasks);
                end;

                // resource data
                clear(Resource);
                ResNo := '';
                ResName := '';
                if (Daytask.Type = Daytask.Type::Resource) and Resource.Get(Daytask."No.") then begin
                    ResNo := Resource."No.";
                    ResName := Resource.Name;
                end;
                // create event data
                if AnchorDate = 0D then
                    CountToWeekNumber(Daytask."Task Date", WeekTemp);

                GetStartEndTxt(Daytask, StartDateTxt, EndDateTxt);
                Clear(PlanningObject);
                PlanningObject.Add('id', Daytask."Job No." + '|' +
                                         Daytask."Job Task No." + '|' +
                                         Format(Daytask."Task Date") + '|' +
                                         Format(Daytask."Day Line No.") + '|' +
                                         ResNo + '|' +
                                         ResName);
                PlanningObject.Add('start_date', StartDateTxt);
                PlanningObject.Add('end_date', EndDateTxt);
                if Daytask.Description <> '' then
                    PlanningObject.Add('text', Daytask.Description)
                else
                    if Daytask."No." <> '' then
                        PlanningObject.Add('text', ResName)
                    else
                        PlanningObject.Add('text', 'vacant');

                PlanningObject.Add('section_id', Daytask."Job No." + '|' + Daytask."Job Task No.");
                // if ResNo <> '' then begin
                //     if Daytask."Vendor No." <> '' then
                //         PlanningObject.Add('color', 'grey')
                //     else
                //         PlanningObject.Add('color', 'green');
                // end else begin // no resource assigned
                //     if Daytask."Vendor No." <> '' then
                //         PlanningObject.Add('color', 'grey')
                //     else
                //         PlanningObject.Add('color', 'green');
                // end;
                if ResNo = '' then begin
                    PlanningObject.Add('color', '#3367D1'); //Blue BC Selection
                    PlanningObject.Add('type', 'daytask_0');
                end else begin
                    PlanningObject.Add('color', '#E9E9E9'); //grey BC
                    PlanningObject.Add('type', 'daytask_1');
                end;

                if not Ven.Get(Daytask."Vendor No.") then
                    Clear(Ven);
                PlanningObject.Add('details', Ven.Name);
                // StrSubstNo(DetailsLabel, Ven."No.", Ven.Name
                // , Daytask."Job No.", Jobs.Description
                // , Daytask."Job Task No.", JobTasks.Description));

                PlanningArray.Add(PlanningObject);
                PlanningArray.WriteTo(PlanninJsonTxt);
            until Daytask.Next() = 0;

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

        if TEMPJobTasks.FindSet() then begin
            Clear(DataArray);
            CurrentJobNo := '';
            repeat
                // One JobObject per unique Job No. — start a new one when the job changes
                if TEMPJobTasks."Job No." <> CurrentJobNo then begin
                    if CurrentJobNo <> '' then begin
                        JobObject.Add('children', ChildrenArray);
                        DataArray.Add(JobObject);
                    end;
                    CurrentJobNo := TEMPJobTasks."Job No.";
                    Clear(JobObject);
                    Clear(ChildrenArray);
                    JobObject.Add('key', CurrentJobNo);
                    if Job.Get(CurrentJobNo) then
                        JobObject.Add('label', StrSubstNo('%1 - %2', CurrentJobNo, Job.Description))
                    else
                        JobObject.Add('label', CurrentJobNo);
                    JobObject.Add('open', true);
                end;
                // Only posting tasks become child section rows (events reference section_id = Job No.|Task No.)
                if TEMPJobTasks."Job Task Type" = TEMPJobTasks."Job Task Type"::Posting then begin
                    Clear(TaskObject);
                    TaskObject.Add('key', TEMPJobTasks."Job No." + '|' + TEMPJobTasks."Job Task No.");
                    TaskObject.Add('label', StrSubstNo('%1 - %2', TEMPJobTasks."Job Task No.", TEMPJobTasks.Description));
                    TaskObject.Add('open', true);
                    ChildrenArray.Add(TaskObject);
                end;
            until TEMPJobTasks.Next() = 0;
            // Flush the last job
            if CurrentJobNo <> '' then begin
                JobObject.Add('children', ChildrenArray);
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

    local procedure GetParentTasks(var TEMPJobTasks: Record "Job Task" temporary)
    var
        jobTasks: Record "Job Task";
    begin
        if TEMPJobTasks.Indentation > 0 then begin
            jobtasks.setrange("Job No.", tempJobTasks."Job No.");
            jobtasks.setfilter("Job Task Type", '<>%1', jobTasks."Job Task Type"::Posting);
            jobtasks.setfilter(jobtasks."Job Task No.", '<%1', TEMPJobTasks."Job Task No.");
            jobtasks.setrange("Indentation", 0, TEMPJobTasks.Indentation - 1);
            if jobtasks.findlast then
                if not TempJobTasks.Get(jobTasks."Job No.", jobTasks."Job Task No.") then begin
                    TEMPJobTasks := jobtasks;
                    TEMPJobTasks.Insert();
                    if tempJobTasks.Indentation > 0 then
                        GetParentTasks(TEMPJobTasks);
                end;
        end

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
        DataArr, ChildArr : JsonArray;
        JobToken, ChildToken, EventToken : JsonToken;
        JobObj, ChildObj, EventObj : JsonObject;
        KeyToken, SectionToken : JsonToken;
        SectionKeys: Dictionary of [Text, Boolean];
        MissingIds: List of [Text];
        SectionId: Text;
        ErrorMsg: Text;
        MissingId: Text;
    begin
        // ── 1. Collect all leaf keys from ResourceJSONTxt ──────────────────────
        if ResourceJSONTxt = '' then
            exit;
        if not RootObj.ReadFrom(ResourceJSONTxt) then
            exit;
        if not RootObj.Get('data', JobToken) then
            exit;
        DataArr := JobToken.AsArray();
        foreach JobToken in DataArr do begin
            JobObj := JobToken.AsObject();
            if JobObj.Get('children', ChildToken) then begin
                ChildArr := ChildToken.AsArray();
                foreach ChildToken in ChildArr do begin
                    ChildObj := ChildToken.AsObject();
                    if ChildObj.Get('key', KeyToken) then
                        SectionKeys.Add(KeyToken.AsValue().AsText(), true);
                end;
            end;
        end;

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

    local procedure GetVendorNoFromDayTask(FromDate: Date; ToDate: Date; ResNo: Code[20]): Text
    var
        Daytask: record "Day Tasks";
        VendorNo: Text;
        rtv: Text;
    begin
        rtv := '';
        Daytask.SetRange("Task Date", FromDate, ToDate);
        Daytask.SetRange(Type, Daytask.Type::Resource);
        Daytask.SetRange("No.", ResNo);
        Daytask.Setfilter("Vendor No.", '<>%1', '');
        if Daytask.FindFirst() then
            rtv := Daytask."Resource Group No." + '|' + Daytask."No." + '|' + Daytask."Vendor No."
        else begin
            Daytask.Setfilter("Vendor No.", '');
            if Daytask.FindFirst() then
                rtv := Daytask."Resource Group No." + '|' + Daytask."No." + '|' + Daytask."Vendor No.";
        end;
        exit(rtv);
    end;

    local procedure GetPoolNoFromDayTask(FromDate: Date; ToDate: Date; ResNo: Code[20]): Text
    var
        Daytask: record "Day Tasks";
        PoolNo: Text;
        rtv: Text;
    begin
        rtv := '';
        Daytask.SetRange("Task Date", FromDate, ToDate);
        Daytask.SetRange(Type, Daytask.Type::Resource);
        Daytask.SetRange("No.", ResNo);
        Daytask.Setfilter("Pool Resource No.", '<>%1', '');
        if Daytask.FindFirst() then
            rtv := Daytask."Resource Group No." + '|' + Daytask."No." + '|' + Daytask."Pool Resource No."
        else begin
            Daytask.Setfilter("Pool Resource No.", '');
            if Daytask.FindFirst() then
                rtv := Daytask."Resource Group No." + '|' + Daytask."No." + '|' + Daytask."Pool Resource No.";
        end;
        exit(rtv);
    end;

    procedure GetYUnitElementsJSON_Resource(AnchorDate: Date;
                                   StartDate: Date;
                                   EndDate: Date;
                                   WithDayTask: Boolean;
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
        Daytask: record "Day Tasks";
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
        //Marking Job based on Day Tasks within the given date range
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
                        if WithDayTask then begin
                            New_section_id := GetVendorNoFromDayTask(StartDate, EndDate, ResCap."Resource No."); //move into seciton id with daytask source no. and posibility has a vendor
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

                //Add Event of Daytask
                if WithDayTask then begin
                    Daytask.setrange(Type, Daytask.Type::Resource);
                    Daytask.setrange("Task Date", DateRec."Period Start");
                    if Daytask.findset then
                        repeat
                            if not Job.Get(Daytask."Job No.") then
                                Clear(Job);
                            if not Task.Get(Daytask."Job No.", Daytask."Job Task No.") then
                                Clear(Task);
                            ResNo := Daytask."No.";
                            if not Resource.Get(ResNo) then
                                Clear(Resource);
                            Clear(PlanningObject);
                            PlanningObject.Add('id', Daytask."Job No." + '|' +
                                                    Daytask."Job Task No." + '|' +
                                                    Format(Daytask."Task Date") + '|' +
                                                    Format(Daytask."Day Line No."));
                            PlanningObject.Add('start_date', StartDateTxt);
                            PlanningObject.Add('end_date', EndDateTxt);
                            if Daytask.Description <> '' then
                                PlanningObject.Add('text', Daytask.Description)
                            else
                                if Daytask."No." <> '' then
                                    PlanningObject.Add('text', Resource.Name)
                                else
                                    PlanningObject.Add('text', 'vacant');
                            PlanningObject.Add('section_id', Daytask."Resource Group No." + '|' + ResNo + '|' + Daytask."Vendor No.");
                            if not Ven.Get(Daytask."Vendor No.") then
                                Clear(Ven);
                            PlanningObject.Add('details', StrSubstNo(DetailsLabel, Ven."No.", Ven.Name
                                                                                     , Daytask."Job No.", Job.Description
                                                                                     , Daytask."Job Task No.", Task.Description));
                            if Daytask."Vendor No." = '' then begin
                                PlanningObject.Add('color', 'green');
                                PlanningObject.Add('type', 'daytask_0');
                            end else begin
                                PlanningObject.Add('color', 'grey');
                                PlanningObject.Add('type', 'daytask_1');
                            end;

                            PlanningArray.Add(PlanningObject);
                        until Daytask.next = 0;
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

        GetUniqueResGroupFromCapacity(TempResGroup, WithDayTask, StartDate, EndDate);
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

                if WithDayTask then begin
                    // 2. Internal / Vendor
                    GetUniqueVendorsFromDayTasks(TempVendor, TempResGroup."No.", StartDate, EndDate);
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
                                   WithDayTask: Boolean;
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
        Daytask: record "Day Tasks";
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
        //Marking Job based on Day Tasks within the given date range
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
                        if WithDayTask then begin
                            if not Resource.Get(ResCap."Resource No.") then
                                Clear(Resource);
                            New_section_id := GetPoolNoFromDayTask(StartDate, EndDate, ResCap."Resource No."); //move into seciton id with daytask source no. and posibility has a vendor
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

                //Add Event of Daytask
                if WithDayTask then begin
                    Daytask.setrange(Type, Daytask.Type::Resource);
                    Daytask.setrange("Task Date", DateRec."Period Start");
                    if Daytask.findset then
                        repeat
                            if not Job.Get(Daytask."Job No.") then
                                Clear(Job);
                            if not Task.Get(Daytask."Job No.", Daytask."Job Task No.") then
                                Clear(Task);
                            ResNo := Daytask."No.";
                            if not Resource.Get(ResNo) then
                                Clear(Resource);
                            Clear(PlanningObject);
                            PlanningObject.Add('id', Daytask."Job No." + '|' +
                                                    Daytask."Job Task No." + '|' +
                                                    Format(Daytask."Task Date") + '|' +
                                                    Format(Daytask."Day Line No."));
                            PlanningObject.Add('start_date', StartDateTxt);
                            PlanningObject.Add('end_date', EndDateTxt);
                            if Daytask.Description <> '' then
                                PlanningObject.Add('text', Daytask.Description)
                            else
                                if Daytask."No." <> '' then
                                    PlanningObject.Add('text', Resource.Name)
                                else
                                    PlanningObject.Add('text', 'vacant');

                            section_id := Daytask."Resource Group No." + '|' + ResNo + '|' + Daytask."Pool Resource No.";
                            if Resource."Pool Resource No." = '' then begin
                                //<<LAGI-2026.02.10
                                //OLD:
                                //section_id := section_id + '|Pool'
                                //NEW:
                                if Daytask."Pool Resource No." = '' then
                                    section_id := section_id + '|Pool'
                                else
                                    section_id := section_id + '|Resource'
                                //>>
                            end else
                                section_id := section_id + '|Resource';
                            PlanningObject.Add('section_id', section_id);

                            if not PoolRes.Get(Daytask."Pool Resource No.") then
                                Clear(PoolRes);
                            PlanningObject.Add('details', StrSubstNo(DetailsLabel, PoolRes."No.", PoolRes.Name
                                                                                     , Daytask."Job No.", Job.Description
                                                                                     , Daytask."Job Task No.", Task.Description));
                            if Daytask."No." = '' then begin
                                PlanningObject.Add('color', '#3367D1'); //Blue BC Selection
                                PlanningObject.Add('type', 'daytask_0');
                            end else begin
                                PlanningObject.Add('color', '#E9E9E9'); //grey BC
                                PlanningObject.Add('type', 'daytask_1');
                            end;


                            PlanningArray.Add(PlanningObject);
                        until Daytask.next = 0;
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

        GetUniqueResGroupFromCapacity(TempResGroup, WithDayTask, StartDate, EndDate);
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

                if WithDayTask then begin
                    // 2. Internal / Pool Resource
                    GetUniquePoolFromDayTasks(ResourceTemp, TempPool, TempResGroup."No.", StartDate, EndDate);
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
                                    //<<LAGI:2026.02.110
                                    //OLD:
                                    //ResourceObject.Add('key', TempResGroup."No." + '|' + ResourceTemp."No." + '|' + Resource."Pool Resource No." + '|Resource');
                                    //NEW:
                                    ResourceObject.Add('key', TempResGroup."No." + '|' + Resource."No." + '|' + ResourceTemp."Pool Resource No." + '|Resource');
                                    //>>
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

    procedure GetStartEndTxt(DayTask: Record "Day Tasks";
                                   var StartDateTxt: Text;
                                   var EndDateTxt: Text)
    var
    begin
        StartDateTxt := '';
        EndDateTxt := '';
        if DayTask."Task Date" = 0D then
            exit;

        case true of
            (DayTask."Start Time" <> 0T) and (DayTask."End Time" <> 0T):
                begin
                    StartDateTxt := ToSessionDateTimeTxt(DayTask."Task Date", DayTask."Start Time");
                    EndDateTxt := ToSessionDateTimeTxt(DayTask."Task Date", DayTask."End Time");
                end;
            (DayTask."Start Time" <> 0T) and (DayTask."End Time" = 0T):
                begin
                    StartDateTxt := ToSessionDateTimeTxt(DayTask."Task Date", DayTask."Start Time");
                    EndDateTxt := Format(DayTask."Task Date", 0, '<Year4>-<Month,2>-<Day,2>') + ' 23:59:59';
                end;
            (DayTask."Start Time" = 0T) and (DayTask."End Time" <> 0T):
                begin
                    StartDateTxt := Format(DayTask."Task Date", 0, '<Year4>-<Month,2>-<Day,2>') + ' 00:00';
                    EndDateTxt := ToSessionDateTimeTxt(DayTask."Task Date", DayTask."End Time");
                end;
            (DayTask."Start Time" = 0T) and (DayTask."End Time" = 0T):
                begin
                    StartDateTxt := Format(DayTask."Task Date", 0, '<Year4>-<Month,2>-<Day,2>') + ' 00:00';
                    EndDateTxt := Format(DayTask."Task Date", 0, '<Year4>-<Month,2>-<Day,2>') + ' 23:59:59';
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
                                ToSessionDateTimeTxt(DayTask."Task Date", DayTask."Start Time"),
                                ToSessionDateTimeTxt(DayTask."Task Date", DayTask."End Time"),
                                DayTask."Job No." + '|' + DayTask."Job Task No.",
                                DayTask."No.",
                                DayTask.Description)
        end;
        exit(rtv);
    end;

    procedure onEventAdded(EventData: Text; var UpdateEventIdJsonTxt: Text): Boolean
    var
        Task: record "Job Task";
        PlanningLine: record "Job Task";
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
        DayTask.SetRange("Task Date", PlanningDate);
        if DayTask.FindLast() then
            LineNo := DayTask."Day Line No." + 10000;

        DayTask.Init();
        DayTask."Task Date" := PlanningDate;
        DayTask."Day Line No." := LineNo;
        DayTask."Job No." := JobNo;
        DayTask."Job Task No." := TaskNo;

        DayTask."No." := Res."No.";
        DayTask."Start Time" := StartTime;
        DayTask."End Time" := EndTime;
        DayTask.Description := Res.Name;
        UpdateEventIdJsonTxt := StrSubstNo(JsonLbl,
                                            old_eventid,
                                            DayTask."Job No.",
                                            DayTask."Job Task No.",
                                            format(DayTask."Task Date"),
                                            format(DayTask."Day Line No."));
        rtv := DayTask.Insert();
        exit(rtv);
    end;

    procedure OnEventChanged_Resource(EventId: Text;
                             EventData: Text;
                             var DateRef: Date)
    var
        OldTask: record "Job Task";
        OldPlanningLIne: record "Job Task";
        OldDayTask: record "Day Tasks";
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
        // OldDayTask.Get(OldDayNo, OldDayLineNo, OldJobNo, OldTaskNo, OldPlanningLineNo);
        // if not OldResource.Get(OldDayTask."No.") then begin
        //     OldResource.Init;
        //     OldResource."No." := OldDayTask."No.";
        // end;
        // if not OldVendor.Get(OldDayTask."Vendor No.") then begin
        //     OldVendor.Init;
        //     OldVendor."No." := OldDayTask."Vendor No.";
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
        //         OldDayTask."No." := NewResource."No.";
        //         OldDayTask.Modify();
        //     end;
        // end;

        // if OldVendor.RecordId <> NewVendor.RecordId then begin
        //     //sift up / down within different task
        //     if VendorCheck.Get(NewVendor."No.") then begin
        //         OldDayTask."Vendor No." := NewVendor."No.";
        //         OldDayTask.Modify();
        //     end;
        // end;

        // //sift left / right to same task
        // EventJSonObj.Get('start_date', JToken);
        // Evaluate(_DateTime, JToken.AsValue().AsText());
        // _DateTimeUserZone := ConvertToUserTimeZone(_DateTime);
        // OldDayTask."Task Date" := DT2Date(_DateTimeUserZone);
        // OldDayTask."Start Time" := DT2Time(_DateTimeUserZone);

        // EventJSonObj.Get('end_date', JToken);
        // Evaluate(_DateTime, JToken.AsValue().AsText());
        // _DateTimeUserZone := ConvertToUserTimeZone(_DateTime);
        // OldDayTask."End Time" := DT2Time(_DateTimeUserZone);

        // EventJSonObj.Get('text', JToken);
        // OldDayTask.Description := JToken.AsValue().AsText();

        // OldDayTask.Modify();

    end;

    procedure OnEventChanged_Project(EventId: Text;
                             EventData: Text;
                             var UpdateEventID: Boolean;
                             var OldDayTask_forUpdate: record "Day Tasks";
                             var NewDayTask_forUpdate: record "Day Tasks")
    var
        OldTask: record "Job Task";
        NewTask: record "Job Task";
        OldPlanningLIne: record "Job Task";
        NewPlanningLIne: record "Job Task";
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
        New_Date := DT2Date(_DateTimeUserZone);
        Evaluate(New_DayNo, Format(New_Date, 0, '<Year4><Month,2><Day,2>'));

        UpdateEventID := false;
        OldDayTask_forUpdate := OldDayTask;
        if OldPlanningLIne.RecordId <> NewPlanningLIne.RecordId then begin
            //sift up / down within different task
            if not DayTaskCheck.Get(New_DayNo, Old_DayLineNo, New_JobNo, New_TaskNo, New_PlanningLineNo) then
                OldDayTask.Rename(New_DayNo, Old_DayLineNo, New_JobNo, New_TaskNo, New_PlanningLineNo)
            else begin
                DayTaskCheck.SetCurrentKey("Job No.", "Job Task No.", "Task Date", "Day Line No.");
                DayTaskCheck.SetRange("Job No.", New_JobNo);
                DayTaskCheck.SetRange("Job Task No.", New_TaskNo);
                DayTaskCheck.SetRange("Task Date", New_Date);
                if DayTaskCheck.FindLast() then
                    OldDayTask.Rename(New_DayNo, DayTaskCheck."Day Line No." + 10000, New_JobNo, New_TaskNo, New_PlanningLineNo)
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
        OldDayTask."Task Date" := DT2Date(_DateTimeUserZone);
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
                         Format(OldDayTask."Task Date"),
                         Format(OldDayTask."Day Line No."),
                         NewDayTask."Job No.",
                         NewDayTask."Job Task No.",
                         Format(NewDayTask."Task Date"),
                         Format(NewDayTask."Day Line No."));
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

    procedure OpenDayTask(eventId: Text): Date
    var
        DayTask: Record "Day Tasks";
        DayTasks: page "Day Tasks";
        EventIDList: List of [Text];
        JobNo: Code[20];
        TaskNo: Code[20];
        //PlanningLineNo: Integer;
        TaskDay: Date;
        DayLineNo: Integer;
        DateOfDayTask: Date;
    begin
        DateOfDayTask := 0D;
        EventIDList := eventId.Split('|');
        JobNo := EventIDList.Get(1);
        TaskNo := EventIDList.Get(2);
        Evaluate(TaskDay, EventIDList.Get(3));
        Evaluate(DayLineNo, EventIDList.Get(4));
        DayTask.SetRange("Task Date", TaskDay);
        //DayTask.SetRange("DayLineNo", DayLineNo);
        DayTask.SetRange("Job No.", JobNo);
        DayTask.SetRange("Job Task No.", TaskNo);
        if DayTask.FindFirst() then begin
            DateOfDayTask := DayTask."Task Date";
            Clear(DayTasks);
            DayTasks.SetTableView(DayTask);
            DayTasks.RunModal();
        end else
            Message('Day Task not found for Event ID: %1', eventId);
        exit(DateOfDayTask);
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

    procedure GetDayTaskAsResourcesAndEventsJSon_Project(TimeLineJSon: Text; ResourceFilter: Text; var ResouecesJSon: Text; var EventsJSon: Text): Boolean
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
        Rtv := GetDayTaskAsResourcesAndEventsJSon_Project_StartEnd(StartDate,
                                                            EndDate,
                                                            ResourceFilter,
                                                            ResouecesJSon,
                                                            EventsJSon,
                                                            EarliestPlanningDate);
        exit(Rtv);
    end;

    procedure GetDayTaskAsResourcesAndEventsJSon_Project_StartEnd(StartDate: Date;
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

    procedure GetDayTaskAsResourcesAndEventsJSon_Project_StartEnd(StartDate: Date;
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

    procedure GetDayTaskAsResourcesAndEventsJSon_Resource(TimeLineJSon: Text;
                                                          WithDayTask: Boolean;
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
        Rtv := GetDayTaskAsResourcesAndEventsJSon_Resource_StartEnd(StartDate,
                                                            EndDate,
                                                            WithDayTask,
                                                            ResouecesJSon,
                                                            EventsJSon,
                                                            EarliestPlanningDate);
        exit(Rtv);
    end;

    procedure GetDayTaskAsResourcesAndEventsJSon_Resource_StartEnd(StartDate: Date;
                                                                   EndDate: Date;
                                                                   WithDayTask: Boolean;
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
                                            WithDayTask,
                                            EventsJSon,
                                            EarliestPlanningDate);
        exit((EventsJSon <> '') and (ResouecesJSon <> ''));
    end;

    procedure GetDayTaskAsResourcesAndEventsJSon_Pool_StartEnd(StartDate: Date;
                                                                   EndDate: Date;
                                                                   WithDayTask: Boolean;
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
                                            WithDayTask,
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
        DayTasks: record "Day Tasks";
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
                if GetVendorNoFromDayTask(StartDate, EndDate, ResNo) = '' then
                    //if <> '' then it does not create section, because it will meet on below next block of codes with daytask source no. and posibility has a vendor
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

        DayTasks.SetRange(Type, DayTasks.Type::Resource);
        DayTasks.SetRange("Task Date", StartDate, EndDate);
        DayTasks.SetRange("Resource Group No.", ResGroupNo);
        DayTasks.SetRange("Vendor No.", VendorNo);
        if DayTasks.FindSet() then
            repeat
                ResNo := DayTasks."No.";
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
            until DayTasks.Next() = 0;

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
        DayTasks: record "Day Tasks";
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
                if GetPoolNoFromDayTask(StartDate, EndDate, ResNo) = '' then
                    //if <> '' then it does not create section, because it will meet on below next block of codes with daytask source no. and posibility has a vendor
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

        DayTasks.SetRange(Type, DayTasks.Type::Resource);
        DayTasks.SetRange("Task Date", StartDate, EndDate);
        DayTasks.SetRange("Resource Group No.", ResGroupNo);
        DayTasks.SetRange("Pool Resource No.", PoolNo);
        if DayTasks.FindSet() then
            repeat
                ResNo := DayTasks."No.";
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
            until DayTasks.Next() = 0;

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

    procedure GetUniqueResGroupFromCapacity(var TempResGroup: record "Resource Group" temporary; WithDayTask: Boolean; StartDate: Date; EndDate: Date)
    var
        ResGroup: record "Resource Group";
        UniqueGroupQry: Query "Unique Group in Capacity";
        UniqueDayTaskResGroupQry: Query "Unique ResGroup in Day Tasks";
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

        if WithDayTask then begin
            UniqueDayTaskResGroupQry.SetRange(TaskDateFilter, StartDate, EndDate);
            if UniqueDayTaskResGroupQry.Open() then begin
                while UniqueDayTaskResGroupQry.Read() do begin
                    ResGroupNo := UniqueDayTaskResGroupQry.Resource_Group_No_;
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
                UniqueDayTaskResGroupQry.Close();
            end;
        end;
    end;

    procedure GetUniqueVendorsFromDayTasks(var TempRecord: record "Aging Band Buffer" temporary;
                                           ResGroupNo: Code[20];
                                           StartDate: Date;
                                           EndDate: Date)
    var
        TempRes: record "Resource" temporary;
        TempVen: record Vendor temporary;
        UniqueVendorsQuery: Query "Unique Vendors in Day Tasks";
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

    procedure GetUniquePoolFromDayTasks(var TempResource: record "Resource" temporary;
                                        var TempPoolRes: record Resource temporary;
                                        ResGroupNo: Code[20];
                                        StartDate: Date;
                                        EndDate: Date)
    var
        DayTask: Record "Day Tasks";
        DayTaskCheck: Record "Day Tasks";
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

        DayTask.SetRange(Type, DayTask.Type::Resource);
        DayTask.SetRange("Task Date", StartDate, EndDate);
        DayTask.SetRange("Resource Group No.", ResGroupNo);
        if DayTask.FindSet() then
            repeat
                PoolNo := '';
                ResNo := DayTask."No.";
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
                end else begin //LAGI:2026.02.10
                    if (ResNo = '') and (DayTask."Pool Resource No." <> '') then begin
                        VacantNo := IncStr(VacantNo);
                        TempResource.Reset();
                        TempResource.Setfilter("No.", '*VACANT*');
                        TempResource.SetRange("Pool Resource No.", DayTask."Pool Resource No.");
                        if not TempResource.FindSet() then begin
                            TempResource.Init();
                            TempResource."No." := VacantNo;
                            TempResource.Name := 'Vacant';
                            TempResource."Pool Resource No." := DayTask."Pool Resource No.";
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
                        DayTaskCheck.SetRange(Type, DayTask.Type::Resource);
                        DayTaskCheck.SetRange("Task Date", StartDate, EndDate);
                        DayTaskCheck.SetRange("Resource Group No.", ResGroupNo);
                        DayTaskCheck.SetRange("No.", '');
                        DayTaskCheck.Setrange("Pool Resource No.", '');
                        AllowInsert := DayTaskCheck.FindFirst();
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
            until DayTask.Next() = 0;



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
        DayTask: Record "Day Tasks";
        StarDateTimeStr: Text;
        EndDateTimeStr: Text;
        JArray: JsonArray;
        JRoot: JsonObject;
        Result: Text;
        eventColor: Text;
    begin
        DayTask.Reset();
        DayTask.SetRange(Type, DayTask.Type::Resource);
        if ResourceFilter <> '' then
            DayTask.SetFilter("No.", ResourceFilter)
        else
            DayTask.SetFilter("No.", '<>%1', '');
        if DayTask.FindSet() then
            repeat
                GetStartEndTxt(DayTask, StarDateTimeStr, EndDateTimeStr);
                if (StarDateTimeStr <> '') and (EndDateTimeStr <> '') then begin
                    eventColor := ResScheduler_GetResourceColor(DayTask."No.", 'daytask');
                    ResScheduler_AddEvent(
                        JArray,
                        Format(DayTask.RecordId),
                        DayTask."No.",
                        eventColor,
                        StarDateTimeStr,
                        EndDateTimeStr,
                        DayTask.Description,
                        'daytask');
                end;
            until DayTask.Next() = 0;
        Clear(JRoot);
        JRoot.Add('data', JArray);
        JRoot.WriteTo(Result);
        exit(Result);
    end;

    procedure ResScheduler_AddEvent(var JArray: JsonArray; RecordId: Text; ResourceId: Text; Classname: Text; StartDate: Text; EndDate: Text; EventText: Text; pType: Text)
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
        JArray.Add(JObj);
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
        if ResColor.Get(ResColor.Type::Resource, pResourceNo, '', '') then begin
            case pColorType of
                'daytask':
                    ColorValue := ResColor."Day Task";
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
        DayTask: Record "Day Tasks";
        StarDateTimeStr: Text;
        EndDateTimeStr: Text;
        JArray: JsonArray;
        JRoot: JsonObject;
        Result: Text;
        eventColor: Text;
    begin
        DayTask.Reset();
        DayTask.SetRange(Type, DayTask.Type::Resource);
        if (StartDate <> 0D) and (EndDate <> 0D) then
            DayTask.SetRange("Task Date", StartDate, EndDate);
        if ResourceFilter <> '' then
            DayTask.SetFilter("No.", ResourceFilter)
        else
            DayTask.SetFilter("No.", '<>%1', '');
        if DayTask.FindSet() then
            repeat
                GetStartEndTxt(DayTask, StarDateTimeStr, EndDateTimeStr);
                if (StarDateTimeStr <> '') and (EndDateTimeStr <> '') then begin
                    eventColor := ResScheduler_GetResourceColor(DayTask."No.", 'daytask');
                    ResScheduler_AddEvent(
                        JArray,
                        Format(DayTask.RecordId),
                        DayTask."No.",
                        eventColor,
                        StarDateTimeStr,
                        EndDateTimeStr,
                        DayTask.Description,
                        'daytask');
                end;
            until DayTask.Next() = 0;
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
    /// Used by the right-click context menu "Open DayTask Visual".
    /// </summary>
    procedure OpenDayTaskVisual(eventId: Text)
    var
        DaytaskScheduler: Page "DHX Scheduler (Project)";
        Parts: List of [Text];
        JobNo: Code[20];
        TaskNo: Code[20];
    begin
        Parts := eventId.Split('|');
        if Parts.Count < 2 then
            exit;
        JobNo := Parts.Get(1);
        TaskNo := Parts.Get(2);
        DaytaskScheduler.SetJobTaskFilter(JobNo, TaskNo);
        DaytaskScheduler.RunModal();
    end;

    /// <summary>
    /// Opens the Resource Day Tasks page filtered to resources assigned to the
    /// job task linked to the given event ID.
    /// Used by the right-click context menu "Show Job Resources".
    /// </summary>
    procedure ShowJobResourcesForEvent(eventId: Text)
    var
        DayTask: Record "Day Tasks";
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
        DayTask.SetRange("Job No.", JobNo);
        DayTask.SetRange("Job Task No.", TaskNo);
        DayTask.SetRange("Task Date", TaskDay);
        PAGE.Run(PAGE::"Resource Day Tasks", DayTask);
    end;
}