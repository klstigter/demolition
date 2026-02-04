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
                                   var PlanninJsonTxt: Text;
                                   var EarliestPlanningDate: Date): Text
    var
        Jobs: Record Job;
        JobTasks: Record "Job Task";
        PlanningLine: Record "Job Planning Line";
        Daytask: Record "Day Tasks";
        WeekTemp: record "Aging Band Buffer" temporary;
        Resource: record Resource;
        Ven: Record Vendor;

        ResNo: Code[20];
        ResName: Text;

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
                                         Format(Daytask."Job Planning Line No.") + '|' +
                                         Format(Daytask."Day No.") + '|' +
                                         Format(Daytask."DayLineNo") + '|' +
                                         ResNo + '|' +
                                         ResName);
                PlanningObject.Add('start_date', StartDateTxt);
                PlanningObject.Add('end_date', EndDateTxt);
                if Daytask.Description <> '' then
                    PlanningObject.Add('text', Daytask.Description)
                else
                    PlanningObject.Add('text', ResName);

                PlanningObject.Add('section_id', Daytask."Job No." + '|' + Daytask."Job Task No." + '|' + Format(Daytask."Job Planning Line No."));
                if ResNo <> '' then begin
                    if Daytask."Vendor No." <> '' then
                        PlanningObject.Add('color', 'grey')
                    else
                        PlanningObject.Add('color', 'green');
                end else begin // no resource assigned
                    if Daytask."Vendor No." <> '' then
                        PlanningObject.Add('color', 'grey')
                    else
                        PlanningObject.Add('color', 'green');
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
                        TaskObject.Add('open', true);
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
                                PlanningLineObject.Add('open', true);
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
                            if New_section_id = '' then
                                section_id := section_id + '|'
                            else
                                section_id := New_section_id;
                        end;
                        PlanningObject.Add('section_id', section_id);
                        PlanningObject.Add('type', 'capacity');
                        PlanningObject.Add('color', 'lightblue');

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
                                                    Format(Daytask."Job Planning Line No.") + '|' +
                                                    Format(Daytask."Day No.") + '|' +
                                                    Format(Daytask."DayLineNo"));
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
                            if Daytask."Vendor No." = '' then
                                PlanningObject.Add('color', 'green')
                            else
                                PlanningObject.Add('color', 'grey');
                            PlanningObject.Add('type', 'daytask');

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

                            // 3. Resource
                            Clear(InternalExternalChildrenArray);
                            ResourceTemp.Reset();
                            ResourceTemp.Deleteall;
                            GetUniqueResFromCapacity(ResourceTemp, TempResGroup."No.", VenNo, StartDate, EndDate);
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
                    // 3. Resource
                    ResourceTemp.Reset();
                    ResourceTemp.Deleteall;
                    GetUniqueResFromCapacity(ResourceTemp, TempResGroup."No.", StartDate, EndDate);
                    if ResourceTemp.FindSet() then
                        repeat
                            Clear(ResourceObject);
                            ResourceObject.Add('key', TempResGroup."No." + '|' + ResourceTemp."No.");
                            ResourceObject.Add('label', ResourceTemp.Name);
                            GroupChildrenArray.Add(ResourceObject);
                        until ResourceTemp.Next() = 0;
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

    local procedure GetStartEndTxt(ResCap: Record "Res. Capacity Entry";
                                   Capacity: Decimal;
                                   var StartDateTxt: Text;
                                   var EndDateTxt: Text)
    var
        tm: Time;
        EndTime: Time;
    begin
        StartDateTxt := '';
        EndDateTxt := '';
        if ResCap."Date" = 0D then
            exit;
        tm := ResCap."Start Time";
        if tm = 0T then
            tm := 070000T;
        StartDateTxt := ToSessionDateTimeTxt(ResCap."Date", tm);
        EndTime := tm + (Capacity * 60 * 60 * 1000);
        EndDateTxt := ToSessionDateTimeTxt(ResCap."Date", EndTime);
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
        DayTask."Task Date" := PlanningDate;
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

    procedure OnEventChanged_Resource(EventId: Text;
                             EventData: Text;
                             var DateRef: Date)
    var
        OldTask: record "Job Task";
        OldPlanningLIne: record "Job Planning Line";
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
        PlanningLineNo: Integer;
        DayNo: Integer;
        DayLineNo: Integer;
        DateOfDayTask: Date;
    begin
        DateOfDayTask := 0D;
        EventIDList := eventId.Split('|');
        JobNo := EventIDList.Get(1);
        TaskNo := EventIDList.Get(2);
        Evaluate(PlanningLineNo, EventIDList.Get(3));
        Evaluate(DayNo, EventIDList.Get(4));
        Evaluate(DayLineNo, EventIDList.Get(5));
        DayTask.SetRange("Day No.", DayNo);
        //DayTask.SetRange("DayLineNo", DayLineNo);
        DayTask.SetRange("Job No.", JobNo);
        DayTask.SetRange("Job Task No.", TaskNo);
        DayTask.SetRange("Job Planning Line No.", PlanningLineNo);
        if DayTask.FindFirst() then begin
            DateOfDayTask := DayTask."Task Date";
            Clear(DayTasks);
            DayTasks.SetTableView(DayTask);
            DayTasks.RunModal();
        end else
            Message('Day Task not found for Event ID: %1', eventId);
        exit(DateOfDayTask);
    end;

    procedure OpenJobPlanningLineCard(SectionId: Text; SectionData: Text; var StartDate: Date)
    var
        JobPlanningLines: Record "Job Planning Line";
        JobPlanningLineCard: Page "Job Planning Line Card";

        JSonObj: JsonObject;
        JToken: JsonToken;

        EventIDList: List of [Text];
        JobNo: Code[20];
        TaskNo: Code[20];
        PlanningLineNo: Integer;
        DayTaskNo: Integer;
        _DateTime: DateTime;
        _DateTimeUserZone: DateTime;
        EndDate: Date;
    begin
        // Manage SectionData and retuned StartDate
        /*
            SectionData = 
            {
                "sectionId":"JOB00020|100|20000",
                "label":"Design and Review",
                "viewdate":"2026-01-19T00:00:00.000Z",
                "periodStart":"2026-01-18T17:00:00.000Z",
                "periodEnd":"2026-01-25T17:00:00.000Z",
                "eventCount":9
            }
        */
        StartDate := 0D;
        if SectionData <> '' then begin
            JSonObj.ReadFrom(SectionData);
            JSonObj.Get('periodStart', JToken);
            Evaluate(_DateTime, JToken.AsValue().AsText());
            _DateTimeUserZone := ConvertToUserTimeZone(_DateTime);
            StartDate := DT2Date(_DateTimeUserZone);

            //Get End Date
            JSonObj.Get('periodEnd', JToken);
            Evaluate(_DateTime, JToken.AsValue().AsText());
            _DateTimeUserZone := ConvertToUserTimeZone(_DateTime);
            EndDate := DT2Date(_DateTimeUserZone);
        end;

        //JOB00010|1010|30000
        // Implementation to open the Job Planning Line Card based on eventId
        //Message('Event Double Clicked with ID: %1', eventId);
        EventIDList := SectionId.Split('|');
        JobNo := EventIDList.Get(1);
        TaskNo := EventIDList.Get(2);
        Evaluate(PlanningLineNo, EventIDList.Get(3));
        JobPlanningLines.SetRange("Job No.", JobNo);
        JobPlanningLines.SetRange("Job Task No.", TaskNo);
        JobPlanningLines.SetRange("Line No.", PlanningLineNo);
        if JobPlanningLines.FindFirst() then begin
            Clear(JobPlanningLineCard);
            JobPlanningLineCard.SetTableView(JobPlanningLines);
            JobPlanningLineCard.SetRecord(JobPlanningLines);
            JobPlanningLineCard.SetFilterOnDayTasks(StartDate, EndDate);
            JobPlanningLineCard.RunModal();
        end else begin
            Message('Job Planning Line not found for Event ID: %1', SectionId);
        end;
    end;

    procedure OpenResourceCard(SectionId: Text)
    var
        Resource: Record Resource;
        ResGroup: record "Resource Group";
        EventIDList: List of [Text];
        ResNo: Code[20];
        GroupNo: Code[20];
    begin
        // Implementation to open the Resource Card based on SectionId
        // SectionId = ResourceGroupNo|ResourceNo
        EventIDList := SectionId.Split('|');
        case true of
            (EventIDList.Get(1) <> '') and (EventIDList.Get(2) <> ''):
                begin
                    ResNo := EventIDList.Get(2);
                    Resource.SetRange("No.", ResNo);
                    Page.RunModal(Page::"Resource Card", Resource);
                end;
            (EventIDList.Get(1) <> '') and (EventIDList.Get(2) = ''):
                begin
                    GroupNo := EventIDList.Get(1);
                    ResGroup.SetRange("No.", GroupNo);
                    Page.RunModal(0, ResGroup);
                end;
        end;
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

    procedure GetDayTaskAsResourcesAndEventsJSon_Project(TimeLineJSon: Text; var ResouecesJSon: Text; var EventsJSon: Text): Boolean
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
                                                            ResouecesJSon,
                                                            EventsJSon,
                                                            EarliestPlanningDate);
        exit(Rtv);
    end;

    procedure GetDayTaskAsResourcesAndEventsJSon_Project_StartEnd(StartDate: Date; EndDate: Date; var ResouecesJSon: Text; var EventsJSon: Text; var EarliestPlanningDate: date): Boolean
    var
        TimeLineJSonObj: JsonObject;
        JToken: JsonToken;
        _DateTime: DateTime;
        _DateTimeUserZone: DateTime;
    begin
        ResouecesJSon := GetYUnitElementsJSON_Project(StartDate,
                                            StartDate,
                                            EndDate,
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
        if VendorNo = '' then begin
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
                            if Res.Get(ResNo) then
                                TempRes.Name := Res.Name
                            else
                                TempRes.Name := 'Vacant';
                            TempRes.Insert();
                        end;
                end;
                UniqueResQry.Close();
            end;
        end;
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
                    if Res.Get(ResNo) then
                        TempRes.Name := Res.Name
                    else
                        TempRes.Name := 'Vacant';
                    TempRes.Insert();
                end;
            until DayTasks.Next() = 0;
    end;

    procedure GetUniqueResFromCapacity(var TempRes: record "Resource" temporary;
                                       ResGroupNo: Code[20];
                                       StartDate: Date;
                                       EndDate: Date)
    var
        Res: record Resource;
        UniqueResQry: Query "Unique Resource in Capacity";
        ResNo: Code[20];
    begin
        // Clear the temporary table
        TempRes.Reset();
        TempRes.DeleteAll();

        // Open the query - it automatically groups by VendorNo giving unique values
        UniqueResQry.SetRange(EntryDateFilter, StartDate, EndDate);
        UniqueResQry.SetRange(Resource_Group_No_, ResGroupNo);
        if UniqueResQry.Open() then begin
            while UniqueResQry.Read() do begin
                ResNo := UniqueResQry.Resource_No_;
                TempRes.Init();
                TempRes."No." := ResNo;
                if Res.Get(ResNo) then
                    TempRes.Name := Res.Name;
                if TempRes.Insert() then;
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

        if not TempRecord.Get('') then begin
            TempRecord.Init();
            TempRecord."Currency Code" := '';
            TempRecord.Insert();
        end;

    end;

}