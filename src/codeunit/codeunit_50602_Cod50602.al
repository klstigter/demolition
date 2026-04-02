codeunit 50602 "Create Demo Data"
{
    trigger OnRun()
    var
        job: Record Job;
    begin
        //if not job.get('JOB001') then
        CreateJob();
        CreateJobTask();
        CheckResources();
        CreateCapacityAndDayTask();
    end;

    var
        JobFiltered: Record Job;
        gResNo1: Code[20];
        gResNo2: Code[20];
        gWorkHoursTemplate: Record "Work-Hour Template";

    local procedure CreateJob()
    var
        Job: Record Job;
        customer: Record Customer;
    begin
        //JobTaskDimension;

        customer.FindFirst();
        job."No." := 'JOB001';
        job.Description := 'Radome repair';
        job.validate("Sell-to Customer No.", customer."No.");
        if not job.Insert() then job.Modify();
        JobFiltered.Get(job."No.");
        JobFiltered.Mark(true);

        job."No." := 'JOB002';
        job.Description := 'App Development';
        job.validate("Sell-to Customer No.", customer."No.");
        if not job.Insert() then job.Modify();
        JobFiltered.Get(job."No.");
        JobFiltered.Mark(true);
    end;

    // local procedure JobTaskDimension()
    // var
    //     JobTaskDimension: Record "Job Task Dimension";
    //     JobTaskDimension2: Record "Job Task Dimension";
    //     JobTask: Record "Job Task";
    // begin
    //     JobTaskDimension.Reset();
    //     if JobTaskDimension.FindSet() then
    //         repeat
    //             if not JobTask.Get(JobTaskDimension."Job No.", JobTaskDimension."Job Task No.") then begin
    //                 JobTaskDimension2 := JobTaskDimension;
    //                 JobTaskDimension2.Delete();
    //                 Commit();
    //             end;
    //         until JobTaskDimension.Next() = 0;
    // end;

    Local procedure CreateJobTask()
    var
        JobTask: Record "Job Task";
        Job: Record Job;
        Indent: codeunit "Job Task Indent";
        Date1: date;

    begin
        Indent.setHideMessage();
        JobFiltered.MarkedOnly(true);
        if JobFiltered.FindSet() then
            repeat

                date1 := calcdate('<WD1-1W>', Today);

                Job.get(JobFiltered."No.");

                Case JobFiltered."No." of
                    'JOB001':
                        begin
                            JobTask."Job No." := Job."No.";
                            JobTask."Job Task No." := '0';
                            JobTask.Description := 'Repair Radome';
                            jobtask."PlannedStartDate" := date1;
                            JobTask.Validate("PlannedEndDate", CalcDate('+4W', date1));
                            JobTask."Job Task Type" := JobTask."Job Task Type"::Heading;
                            if not JobTask.Insert() then JobTask.Modify();

                            JobTask."Job Task No." := '1';
                            JobTask.Description := 'Pre Processing Tasks';
                            jobtask."PlannedStartDate" := CalcDate('1D', date1);
                            JobTask.Validate("PlannedEndDate", CalcDate('+2D', date1));
                            JobTask."Job Task Type" := JobTask."Job Task Type"::"Begin-Total";
                            if not JobTask.Insert() then JobTask.Modify();

                            JobTask."Job Task No." := '1010';
                            JobTask.Description := 'Inbound Inspection';
                            jobtask."PlannedStartDate" := CalcDate('2D', date1);
                            JobTask.Validate("PlannedEndDate", CalcDate('3D', date1));
                            JobTask."Job Task Type" := JobTask."Job Task Type"::Posting;
                            if not JobTask.Insert() then JobTask.Modify();

                            JobTask."Job Task No." := '1020';
                            JobTask.Description := 'Quote & Approval';
                            jobtask."PlannedStartDate" := CalcDate('3D', date1);
                            JobTask.Validate("PlannedEndDate", CalcDate('+4D', date1));
                            JobTask."Job Task Type" := JobTask."Job Task Type"::Posting;
                            if not JobTask.Insert() then JobTask.Modify();

                            JobTask."Job Task No." := '1999';
                            JobTask.Description := 'Pre Processing Tasks';
                            jobtask."PlannedStartDate" := CalcDate('1D', date1);
                            JobTask.Validate("PlannedEndDate", CalcDate('+1W', date1));
                            JobTask."Job Task Type" := JobTask."Job Task Type"::"End-Total";
                            if not JobTask.Insert() then JobTask.Modify();

                            JobTask."Job Task No." := '2';
                            JobTask.Description := 'Repair';
                            jobtask."PlannedStartDate" := CalcDate('+1W', date1);
                            JobTask.Validate("PlannedEndDate", CalcDate('+2W+4D', date1));
                            JobTask."Job Task Type" := JobTask."Job Task Type"::"Begin-Total";
                            if not JobTask.Insert() then JobTask.Modify();

                            JobTask."Job Task No." := '2010';
                            JobTask.Description := 'Spare Parts Procurement';
                            jobtask."PlannedStartDate" := CalcDate('+1W+1D', date1);
                            JobTask.Validate("PlannedEndDate", CalcDate('+1W+2D', date1));
                            JobTask."Job Task Type" := JobTask."Job Task Type"::Posting;
                            if not JobTask.Insert() then JobTask.Modify();

                            JobTask."Job Task No." := '2020';
                            JobTask.Description := 'Remove old and install new parts';
                            jobtask."PlannedStartDate" := CalcDate('+1W+2D', date1);
                            JobTask.Validate("PlannedEndDate", CalcDate('+1W+3D', date1));
                            JobTask."Job Task Type" := JobTask."Job Task Type"::Posting;
                            if not JobTask.Insert() then JobTask.Modify();

                            JobTask."Job Task No." := '2030';
                            JobTask.Description := 'Cat and bodywork';
                            jobtask."PlannedStartDate" := CalcDate('+1W+3D', date1);
                            JobTask.Validate("PlannedEndDate", CalcDate('+2W+2D', date1));
                            JobTask."Job Task Type" := JobTask."Job Task Type"::Posting;
                            if not JobTask.Insert() then JobTask.Modify();

                            JobTask."Job Task No." := '2999';
                            JobTask.Description := 'Pre Processing Tasks';
                            jobtask."PlannedStartDate" := CalcDate('1W', date1);
                            JobTask.Validate("PlannedEndDate", CalcDate('+2W+3D', date1));
                            JobTask."Job Task Type" := JobTask."Job Task Type"::"End-Total";
                            if not JobTask.Insert() then JobTask.Modify();

                            JobTask."Job Task No." := '3';
                            JobTask.Description := 'Post Processing Tasks';
                            jobtask."PlannedStartDate" := CalcDate('+2W+3D', date1);
                            JobTask.Validate("PlannedEndDate", CalcDate('+3W+4D+3D', date1));
                            JobTask."Job Task Type" := JobTask."Job Task Type"::"Begin-Total";
                            if not JobTask.Insert() then JobTask.Modify();

                            JobTask."Job Task No." := '3010';
                            JobTask.Description := 'Testing';
                            jobtask."PlannedStartDate" := CalcDate('+2W+4D', date1);
                            JobTask.Validate("PlannedEndDate", CalcDate('+3W', date1));
                            JobTask."Job Task Type" := JobTask."Job Task Type"::Posting;
                            if not JobTask.Insert() then JobTask.Modify();

                            JobTask."Job Task No." := '3020';
                            JobTask.Description := 'Certification';
                            jobtask."PlannedStartDate" := CalcDate('+3W+4D', date1);
                            JobTask.Validate("PlannedEndDate", CalcDate('+4W', date1));
                            JobTask."Job Task Type" := JobTask."Job Task Type"::Posting;
                            if not JobTask.Insert() then JobTask.Modify();

                            JobTask."Job Task No." := '3030';
                            JobTask.Description := 'Outbound Shipping';
                            jobtask."PlannedStartDate" := CalcDate('+4W+1D', date1);
                            JobTask.Validate("PlannedEndDate", CalcDate('+4W+2D', date1));
                            JobTask."Job Task Type" := JobTask."Job Task Type"::Posting;
                            if not JobTask.Insert() then JobTask.Modify();

                            JobTask."Job Task No." := '3999';
                            JobTask.Description := 'Post Processing Tasks';
                            jobtask."PlannedStartDate" := CalcDate('+3W+2D', date1);
                            JobTask.Validate("PlannedEndDate", CalcDate('+3W+2D', date1));
                            JobTask."Job Task Type" := JobTask."Job Task Type"::"End-Total";
                            if not JobTask.Insert() then JobTask.Modify();

                            JobTask."Job Task No." := '6999';
                            JobTask.Description := 'Repair Radome';
                            jobtask."PlannedStartDate" := date1;
                            JobTask.Validate("PlannedEndDate", CalcDate('+3W+2D', date1));
                            JobTask."Job Task Type" := JobTask."Job Task Type"::Total;
                            if not JobTask.Insert() then JobTask.Modify();

                            Indent.IndentJobTasks(JobTask);
                        end;
                    'JOB002':
                        begin
                            // JOB002: Software Development project — completely different scenario
                            // Start 1 week later than JOB001 so dates are visually distinct on the Gantt
                            date1 := CalcDate('+1W', date1);
                            JobTask."Job No." := Job."No.";

                            // ── HEADING ─────────────────────────────────────────────
                            JobTask."Job Task No." := '0';
                            JobTask.Description := 'Software Development';
                            jobtask."PlannedStartDate" := date1;
                            JobTask.Validate("PlannedEndDate", CalcDate('+5W', date1));
                            JobTask."Job Task Type" := JobTask."Job Task Type"::Heading;
                            if not JobTask.Insert() then JobTask.Modify();

                            // ── PHASE 1 : Analysis & Design (1 week) ─────────────
                            JobTask."Job Task No." := '1000';
                            JobTask.Description := 'Analysis & Design';
                            jobtask."PlannedStartDate" := date1;
                            JobTask.Validate("PlannedEndDate", CalcDate('+1W', date1));
                            JobTask."Job Task Type" := JobTask."Job Task Type"::"Begin-Total";
                            if not JobTask.Insert() then JobTask.Modify();

                            JobTask."Job Task No." := '1010';
                            JobTask.Description := 'Requirements Gathering';
                            jobtask."PlannedStartDate" := date1;
                            JobTask.Validate("PlannedEndDate", CalcDate('+2D', date1));
                            JobTask."Job Task Type" := JobTask."Job Task Type"::Posting;
                            if not JobTask.Insert() then JobTask.Modify();

                            JobTask."Job Task No." := '1020';
                            JobTask.Description := 'System Architecture Design';
                            jobtask."PlannedStartDate" := CalcDate('+2D', date1);
                            JobTask.Validate("PlannedEndDate", CalcDate('+4D', date1));
                            JobTask."Job Task Type" := JobTask."Job Task Type"::Posting;
                            if not JobTask.Insert() then JobTask.Modify();

                            JobTask."Job Task No." := '1030';
                            JobTask.Description := 'Design Review & Sign-off';
                            jobtask."PlannedStartDate" := CalcDate('+4D', date1);
                            JobTask.Validate("PlannedEndDate", CalcDate('+1W', date1));
                            JobTask."Job Task Type" := JobTask."Job Task Type"::Posting;
                            if not JobTask.Insert() then JobTask.Modify();

                            JobTask."Job Task No." := '1999';
                            JobTask.Description := 'Analysis & Design';
                            jobtask."PlannedStartDate" := date1;
                            JobTask.Validate("PlannedEndDate", CalcDate('+1W', date1));
                            JobTask."Job Task Type" := JobTask."Job Task Type"::"End-Total";
                            if not JobTask.Insert() then JobTask.Modify();

                            // ── PHASE 2 : Development (2 weeks) ──────────────────
                            JobTask."Job Task No." := '2000';
                            JobTask.Description := 'Development';
                            jobtask."PlannedStartDate" := CalcDate('+1W', date1);
                            JobTask.Validate("PlannedEndDate", CalcDate('+3W', date1));
                            JobTask."Job Task Type" := JobTask."Job Task Type"::"Begin-Total";
                            if not JobTask.Insert() then JobTask.Modify();

                            JobTask."Job Task No." := '2010';
                            JobTask.Description := 'Backend API Development';
                            jobtask."PlannedStartDate" := CalcDate('+1W', date1);
                            JobTask.Validate("PlannedEndDate", CalcDate('+2W', date1));
                            JobTask."Job Task Type" := JobTask."Job Task Type"::Posting;
                            if not JobTask.Insert() then JobTask.Modify();

                            JobTask."Job Task No." := '2020';
                            JobTask.Description := 'Frontend UI Development';
                            jobtask."PlannedStartDate" := CalcDate('+1W+2D', date1);
                            JobTask.Validate("PlannedEndDate", CalcDate('+2W+2D', date1));
                            JobTask."Job Task Type" := JobTask."Job Task Type"::Posting;
                            if not JobTask.Insert() then JobTask.Modify();

                            JobTask."Job Task No." := '2030';
                            JobTask.Description := 'Database Migration';
                            jobtask."PlannedStartDate" := CalcDate('+2W', date1);
                            JobTask.Validate("PlannedEndDate", CalcDate('+2W+3D', date1));
                            JobTask."Job Task Type" := JobTask."Job Task Type"::Posting;
                            if not JobTask.Insert() then JobTask.Modify();

                            JobTask."Job Task No." := '2040';
                            JobTask.Description := 'Integration & Unit Tests';
                            jobtask."PlannedStartDate" := CalcDate('+2W+3D', date1);
                            JobTask.Validate("PlannedEndDate", CalcDate('+3W', date1));
                            JobTask."Job Task Type" := JobTask."Job Task Type"::Posting;
                            if not JobTask.Insert() then JobTask.Modify();

                            JobTask."Job Task No." := '2999';
                            JobTask.Description := 'Development';
                            jobtask."PlannedStartDate" := CalcDate('+1W', date1);
                            JobTask.Validate("PlannedEndDate", CalcDate('+3W', date1));
                            JobTask."Job Task Type" := JobTask."Job Task Type"::"End-Total";
                            if not JobTask.Insert() then JobTask.Modify();

                            // ── PHASE 3 : Testing & Acceptance (1.5 weeks) ───────
                            JobTask."Job Task No." := '3000';
                            JobTask.Description := 'Testing & Acceptance';
                            jobtask."PlannedStartDate" := CalcDate('+3W', date1);
                            JobTask.Validate("PlannedEndDate", CalcDate('+4W+2D', date1));
                            JobTask."Job Task Type" := JobTask."Job Task Type"::"Begin-Total";
                            if not JobTask.Insert() then JobTask.Modify();

                            JobTask."Job Task No." := '3010';
                            JobTask.Description := 'System Integration Testing';
                            jobtask."PlannedStartDate" := CalcDate('+3W', date1);
                            JobTask.Validate("PlannedEndDate", CalcDate('+3W+3D', date1));
                            JobTask."Job Task Type" := JobTask."Job Task Type"::Posting;
                            if not JobTask.Insert() then JobTask.Modify();

                            JobTask."Job Task No." := '3020';
                            JobTask.Description := 'User Acceptance Testing';
                            jobtask."PlannedStartDate" := CalcDate('+3W+3D', date1);
                            JobTask.Validate("PlannedEndDate", CalcDate('+4W+1D', date1));
                            JobTask."Job Task Type" := JobTask."Job Task Type"::Posting;
                            if not JobTask.Insert() then JobTask.Modify();

                            JobTask."Job Task No." := '3030';
                            JobTask.Description := 'Bug Fixing & Retest';
                            jobtask."PlannedStartDate" := CalcDate('+4W+1D', date1);
                            JobTask.Validate("PlannedEndDate", CalcDate('+4W+2D', date1));
                            JobTask."Job Task Type" := JobTask."Job Task Type"::Posting;
                            if not JobTask.Insert() then JobTask.Modify();

                            JobTask."Job Task No." := '3999';
                            JobTask.Description := 'Testing & Acceptance';
                            jobtask."PlannedStartDate" := CalcDate('+3W', date1);
                            JobTask.Validate("PlannedEndDate", CalcDate('+4W+2D', date1));
                            JobTask."Job Task Type" := JobTask."Job Task Type"::"End-Total";
                            if not JobTask.Insert() then JobTask.Modify();

                            // ── PHASE 4 : Deployment & Go-Live (0.5 week) ────────
                            JobTask."Job Task No." := '4000';
                            JobTask.Description := 'Deployment & Go-Live';
                            jobtask."PlannedStartDate" := CalcDate('+4W+2D', date1);
                            JobTask.Validate("PlannedEndDate", CalcDate('+5W', date1));
                            JobTask."Job Task Type" := JobTask."Job Task Type"::"Begin-Total";
                            if not JobTask.Insert() then JobTask.Modify();

                            JobTask."Job Task No." := '4010';
                            JobTask.Description := 'Production Deployment';
                            jobtask."PlannedStartDate" := CalcDate('+4W+2D', date1);
                            JobTask.Validate("PlannedEndDate", CalcDate('+4W+3D', date1));
                            JobTask."Job Task Type" := JobTask."Job Task Type"::Posting;
                            if not JobTask.Insert() then JobTask.Modify();

                            JobTask."Job Task No." := '4020';
                            JobTask.Description := 'Go-Live Support & Monitoring';
                            jobtask."PlannedStartDate" := CalcDate('+4W+3D', date1);
                            JobTask.Validate("PlannedEndDate", CalcDate('+5W', date1));
                            JobTask."Job Task Type" := JobTask."Job Task Type"::Posting;
                            if not JobTask.Insert() then JobTask.Modify();

                            JobTask."Job Task No." := '4999';
                            JobTask.Description := 'Deployment & Go-Live';
                            jobtask."PlannedStartDate" := CalcDate('+4W+2D', date1);
                            JobTask.Validate("PlannedEndDate", CalcDate('+5W', date1));
                            JobTask."Job Task Type" := JobTask."Job Task Type"::"End-Total";
                            if not JobTask.Insert() then JobTask.Modify();

                            // ── TOTAL ────────────────────────────────────────────
                            JobTask."Job Task No." := '9999';
                            JobTask.Description := 'Software Development Total';
                            jobtask."PlannedStartDate" := date1;
                            JobTask.Validate("PlannedEndDate", CalcDate('+5W', date1));
                            JobTask."Job Task Type" := JobTask."Job Task Type"::Total;
                            if not JobTask.Insert() then JobTask.Modify();

                            Indent.IndentJobTasks(JobTask);
                        end;
                End;
            until JobFiltered.Next() = 0;
    end;

    local procedure CheckResources()
    var
        Resource: Record Resource;
        n: Integer;
    begin
        Resource.Reset();
        if not Resource.FindSet() then
            Message('No resources found. Please create minimal 2 resources to be able to use the planning functionality.');
        repeat
            n += 1;
            case n of
                1:
                    gResNo1 := Resource."No.";
                2:
                    gResNo2 := Resource."No.";
            end;
        until Resource.Next() = 0;
    end;

    local procedure CreateCapacityAndDayTask()
    var
        ResNo: Code[20];
        JobNo: Code[20];
        StarDate: Date;
        EndDate: Date;
        n: Integer;
    begin
        // Load work-hour template once — used to skip non-working days
        gWorkHoursTemplate.Get('BASIS');
        StarDate := calcdate('<WD1-1W>', Today);
        EndDate := CalcDate('+5W', StarDate);
        for n := 1 to 2 do begin
            case n of
                1:
                    begin
                        ResNo := gResNo1;
                        JobNo := 'JOB001';
                    end;
                2:
                    begin
                        ResNo := gResNo2;
                        JobNo := 'JOB002';
                    end;
            end;
            CreateResourceCapacity(ResNo, StarDate, EndDate);
            CreateResourceDayTask(JobNo, ResNo, StarDate, EndDate);
        end;
    end;

    local procedure CreateResourceDayTask(JobNo: Code[20]; ResNo: Code[20]; StartDate: Date; EndDate: Date)
    var
        JobTask: Record "Job Task";
        TaskStart: Date;
        TaskEnd: Date;
    begin
        JobTask.SetRange("Job No.", JobNo);
        JobTask.SetRange("Job Task Type", JobTask."Job Task Type"::Posting);
        if JobTask.FindSet() then
            repeat
                // Use each job task's own planned dates so day tasks don't stack on the same day
                TaskStart := JobTask."PlannedStartDate";
                TaskEnd := JobTask."PlannedEndDate";
                if TaskStart = 0D then TaskStart := StartDate;
                if TaskEnd = 0D then TaskEnd := EndDate;
                if TaskStart < StartDate then TaskStart := StartDate;
                if TaskEnd > EndDate then TaskEnd := EndDate;
                if TaskEnd >= TaskStart then
                    CreateDayTask(JobTask."Job No.", JobTask."Job Task No.", ResNo, TaskStart, TaskEnd);
            until JobTask.Next() = 0;
    end;

    local procedure CreateDayTask(JobNo: Code[20]; TaskNo: Code[20]; ResNo: Code[20]; StartDate: Date; EndDate: Date)
    var
        DayTask: Record "Day Tasks";
        DT: Date;
    begin
        For DT := StartDate to EndDate do begin
            // Skip non-working days according to BASIS work-hour template
            if not IsWorkingDay(DT) then
                continue;
            if not DayTask.Get(DT, 10000, JobNo, TaskNo) then begin
                DayTask.Init();
                DayTask."Task Date" := DT;
                DayTask."Day Line No." := 10000;
                DayTask."Job No." := JobNo;
                DayTask."Job Task No." := TaskNo;
                DayTask.Type := DayTask.Type::Resource;
                DayTask.Validate("No.", ResNo);
                DayTask."Start Time" := 080000T;
                DayTask.Description := 'Work on ' + JobNo + '-' + TaskNo;
                DayTask.Validate("End Time", 140000T);
                DayTask."Assigned Hours" := (DayTask."End Time" - DayTask."Start Time") / 3600000;
                DayTask.Insert();
            end else begin
                if DayTask.Type = DayTask.Type::Resource then begin
                    if DayTask."No." = '' then
                        DayTask.Validate("No.", ResNo);
                    if DayTask.Description = '' then
                        DayTask.Description := 'Work on ' + JobNo + '-' + TaskNo;
                    if (DayTask."Start Time" = 0T) OR (DayTask."End Time" = 0T) then begin
                        DayTask."Start Time" := 080000T;
                        DayTask.Validate("End Time", 140000T);
                    end;
                    DayTask."Assigned Hours" := (DayTask."End Time" - DayTask."Start Time") / 3600000;
                    DayTask.Modify();
                end;
            end;
        end;
    end;

    local procedure IsWorkingDay(DateToCheck: Date): Boolean
    begin
        case Date2DWY(DateToCheck, 1) of
            1:
                exit(gWorkHoursTemplate.Monday <> 0);
            2:
                exit(gWorkHoursTemplate.Tuesday <> 0);
            3:
                exit(gWorkHoursTemplate.Wednesday <> 0);
            4:
                exit(gWorkHoursTemplate.Thursday <> 0);
            5:
                exit(gWorkHoursTemplate.Friday <> 0);
            6:
                exit(gWorkHoursTemplate.Saturday <> 0);
            7:
                exit(gWorkHoursTemplate.Sunday <> 0);
            else
                exit(false);
        end;
    end;


    local procedure CreateResourceCapacity(ResNo: Code[20]; StartDate: Date; EndDate: Date)
    var
        Res: Record Resource;
        ResCap: Record "Res. Capacity Entry";
        Dt: Date;
        ResCapEntryNo: Integer;
    begin
        Res.Get(ResNo);
        For DT := StartDate to EndDate do begin
            // Skip non-working days according to BASIS work-hour template
            if not IsWorkingDay(DT) then
                continue;
            Res.SetRange("Date Filter", DT);
            Res.CalcFields(Capacity);
            if Res.Capacity = 0 then begin
                ResCap.Reset();
                if ResCap.FindLast() then
                    ResCapEntryNo := ResCap."Entry No." + 1
                else
                    ResCapEntryNo := 1;
                ResCap.Init();
                ResCap."Entry No." := ResCapEntryNo;
                ResCap."Resource No." := ResNo;
                ResCap.Date := DT;
                ResCap.Capacity := 8;
                ResCap."Resource Group No." := Res."Resource Group No.";
                ResCap."Start Time" := 080000T;
                ResCap."End Time" := 160000T;
                ResCap.Insert();
            end;
        end;
    end;
}