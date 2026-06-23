codeunit 50602 "Create Demo Data"
{
    trigger OnRun()
    var
        ConfirmLbl: Label 'This will DELETE all existing demo data and recreate it fresh.\n\nContinue?';
    begin
        if not Confirm(ConfirmLbl, true) then
            Error('');
        Initialize();
        DeleteDemoData();
        CreateJobs();
        CreateJobTasks();
        CreateJobTaskLinks();
        LoadResources();
        CreateCapacityAndDayPlanning();
        Message('Demo data created successfully. %1 records logged.', gLogEntryNo);
    end;

    var
        gWorkHoursTemplate: Record "Work-Hour Template";
        gRes: array[6] of Code[20];
        gResCount: Integer;
        gStartDate: Date;
        gEndDate: Date;
        gLogEntryNo: Integer;

    // ──────────────────────────────────────────────────────────────────────────
    // Initialization & Cleanup
    // ──────────────────────────────────────────────────────────────────────────

    local procedure Initialize()
    var
        LogEntry: Record "Demo Data Log Entry";
    begin
        gStartDate := CalcDate('<WD1-1W>', Today());
        gEndDate := CalcDate('+54W', gStartDate);  // covers JOB002 (start+1W+52W) + 1W buffer
        gWorkHoursTemplate.Get('BASIS');
        LogEntry.Reset();
        if LogEntry.FindLast() then
            gLogEntryNo := LogEntry."Entry No."
        else
            gLogEntryNo := 0;
    end;

    local procedure DeleteDemoData()
    var
        LogEntry: Record "Demo Data Log Entry";
        RecRef: RecordRef;
    begin
        // Only delete records that were logged by a previous demo data run.
        // User-created records are never touched.
        LogEntry.Reset();
        if LogEntry.FindLast() then
            repeat
                RecRef.Open(LogEntry."Table ID");
                if RecRef.Get(LogEntry."Record ID") then
                    RecRef.Delete(false);
                RecRef.Close();
            until LogEntry.Next(-1) = 0;
        LogEntry.DeleteAll();
        gLogEntryNo := 0;
    end;

    // ──────────────────────────────────────────────────────────────────────────
    // Jobs
    // ──────────────────────────────────────────────────────────────────────────

    local procedure CreateJobs()
    var
        Job: Record Job;
        Customer: Record Customer;
    begin
        Customer.FindFirst();
        UpsertJob(Job, 'JOB001', 'Radome Repair Project', Customer."No.");
        UpsertJob(Job, 'JOB002', 'ERP System Implementation', Customer."No.");
        UpsertJob(Job, 'JOB003', 'Facility Infrastructure Upgrade', Customer."No.");
    end;

    local procedure UpsertJob(var Job: Record Job; No: Code[20]; Desc: Text[100]; CustNo: Code[20])
    begin
        // Validate("Sell-to Customer No.") triggers BC dimension management which iterates
        // Job Task Dimension rows for this job. If a row references a task that no longer
        // exists (e.g. task '7000' left from an older demo data version), BC throws
        // "Project Task does not exist". Remove any orphan rows first.
        DeleteOrphanJobTaskDimensions(No);
        Job.Init();
        Job."No." := No;
        Job.Description := Desc;
        Job.Validate("Sell-to Customer No.", CustNo);
        if not Job.Insert() then
            Job.Modify();
        LogRecord(Database::Job, Job.RecordId(), No + ' - ' + Desc);
    end;

    local procedure DeleteOrphanJobTaskDimensions(JobNo: Code[20])
    var
        JobTaskDim: Record "Job Task Dimension";
        JobTask: Record "Job Task";
    begin
        JobTaskDim.SetRange("Job No.", JobNo);
        if not JobTaskDim.FindSet() then exit;
        repeat
            if not JobTask.Get(JobTaskDim."Job No.", JobTaskDim."Job Task No.") then
                JobTaskDim.Delete(false);  // suppress OnDelete to avoid the same cascade error
        until JobTaskDim.Next() = 0;
    end;

    // ──────────────────────────────────────────────────────────────────────────
    // Job Tasks
    // ──────────────────────────────────────────────────────────────────────────

    local procedure CreateJobTasks()
    var
        Indent: Codeunit "Job Task Indent";
    begin
        Indent.setHideMessage();
        BuildTasksJOB001(Indent);
        BuildTasksJOB002(Indent);
        BuildTasksJOB003(Indent);
    end;

    local procedure BuildTasksJOB001(var Indent: Codeunit "Job Task Indent")
    var
        JT: Record "Job Task";
        D: Date;
    begin
        D := gStartDate;
        JT."Job No." := 'JOB001';

        // ── 40-week Radome Repair project — each posting task ≥ 3 weeks ───────
        AddTask(JT, '0',    'Radome Repair Project',              D,                      CalcDate('+40W', D),    JT."Job Task Type"::Heading);

        AddTask(JT, '1000', 'Phase 1: Pre-Processing',            D,                      CalcDate('+9W', D),     JT."Job Task Type"::"Begin-Total");
        AddTask(JT, '1010', 'Inbound Receiving & Logging',        D,                      CalcDate('+3W', D),     JT."Job Task Type"::Posting);   // 3W
        AddTask(JT, '1020', 'Condition Assessment',               CalcDate('+2W', D),     CalcDate('+5W', D),     JT."Job Task Type"::Posting);   // 3W
        AddTask(JT, '1030', 'Quote Preparation',                  CalcDate('+4W', D),     CalcDate('+7W', D),     JT."Job Task Type"::Posting);   // 3W
        AddTask(JT, '1040', 'Customer Approval',                  CalcDate('+6W', D),     CalcDate('+9W', D),     JT."Job Task Type"::Posting);   // 3W
        AddTask(JT, '1999', 'Phase 1 Total',                      D,                      CalcDate('+9W', D),     JT."Job Task Type"::"End-Total");

        AddTask(JT, '2000', 'Phase 2: Disassembly & Procurement', CalcDate('+9W', D),     CalcDate('+21W', D),    JT."Job Task Type"::"Begin-Total");
        AddTask(JT, '2010', 'Component Disassembly',              CalcDate('+9W', D),     CalcDate('+12W', D),    JT."Job Task Type"::Posting);   // 3W
        AddTask(JT, '2020', 'Damage Mapping & Analysis',          CalcDate('+10W', D),    CalcDate('+14W', D),    JT."Job Task Type"::Posting);   // 4W
        AddTask(JT, '2030', 'Spare Parts Identification',         CalcDate('+12W', D),    CalcDate('+15W', D),    JT."Job Task Type"::Posting);   // 3W
        AddTask(JT, '2040', 'Parts Procurement',                  CalcDate('+14W', D),    CalcDate('+18W', D),    JT."Job Task Type"::Posting);   // 4W
        AddTask(JT, '2050', 'Procurement Follow-up',              CalcDate('+16W', D),    CalcDate('+21W', D),    JT."Job Task Type"::Posting);   // 5W
        AddTask(JT, '2999', 'Phase 2 Total',                      CalcDate('+9W', D),     CalcDate('+21W', D),    JT."Job Task Type"::"End-Total");

        AddTask(JT, '3000', 'Phase 3: Repair & Assembly',         CalcDate('+21W', D),    CalcDate('+33W', D),    JT."Job Task Type"::"Begin-Total");
        AddTask(JT, '3010', 'Surface Preparation',                CalcDate('+21W', D),    CalcDate('+24W', D),    JT."Job Task Type"::Posting);   // 3W
        AddTask(JT, '3020', 'Structural Repair',                  CalcDate('+23W', D),    CalcDate('+27W', D),    JT."Job Task Type"::Posting);   // 4W
        AddTask(JT, '3030', 'Paint & Coating Application',        CalcDate('+26W', D),    CalcDate('+29W', D),    JT."Job Task Type"::Posting);   // 3W
        AddTask(JT, '3040', 'Component Assembly',                 CalcDate('+28W', D),    CalcDate('+31W', D),    JT."Job Task Type"::Posting);   // 3W
        AddTask(JT, '3050', 'Electrical Fit-out',                 CalcDate('+30W', D),    CalcDate('+33W', D),    JT."Job Task Type"::Posting);   // 3W
        AddTask(JT, '3999', 'Phase 3 Total',                      CalcDate('+21W', D),    CalcDate('+33W', D),    JT."Job Task Type"::"End-Total");

        AddTask(JT, '4000', 'Phase 4: Testing & Delivery',        CalcDate('+33W', D),    CalcDate('+40W', D),    JT."Job Task Type"::"Begin-Total");
        AddTask(JT, '4010', 'Functional Testing',                 CalcDate('+33W', D),    CalcDate('+36W', D),    JT."Job Task Type"::Posting);   // 3W
        AddTask(JT, '4020', 'RF Performance Test',                CalcDate('+35W', D),    CalcDate('+38W', D),    JT."Job Task Type"::Posting);   // 3W
        AddTask(JT, '4030', 'Certification & Documentation',      CalcDate('+36W', D),    CalcDate('+39W', D),    JT."Job Task Type"::Posting);   // 3W
        AddTask(JT, '4040', 'Outbound Packing',                   CalcDate('+37W', D),    CalcDate('+40W', D),    JT."Job Task Type"::Posting);   // 3W
        AddTask(JT, '4050', 'Customer Delivery',                  CalcDate('+38W', D),    CalcDate('+40W', D),    JT."Job Task Type"::Posting);   // 2W (final hand-off, overlap with packing)
        AddTask(JT, '4999', 'Phase 4 Total',                      CalcDate('+33W', D),    CalcDate('+40W', D),    JT."Job Task Type"::"End-Total");

        AddTask(JT, '9999', 'Radome Repair Project Total',        D,                      CalcDate('+40W', D),    JT."Job Task Type"::Total);

        Indent.IndentJobTasks(JT);
    end;

    local procedure BuildTasksJOB002(var Indent: Codeunit "Job Task Indent")
    var
        JT: Record "Job Task";
        D: Date;
    begin
        D := CalcDate('+1W', gStartDate);  // offset 1W so Gantt lanes are visually distinct
        JT."Job No." := 'JOB002';

        // ── 52-week ERP Implementation project — each posting task ≥ 3 weeks ──
        AddTask(JT, '0',    'ERP System Implementation',           D,                      CalcDate('+52W', D),    JT."Job Task Type"::Heading);

        AddTask(JT, '1000', 'Phase 1: Project Initiation',         D,                      CalcDate('+9W', D),     JT."Job Task Type"::"Begin-Total");
        AddTask(JT, '1010', 'Stakeholder Kickoff Meeting',         D,                      CalcDate('+3W', D),     JT."Job Task Type"::Posting);   // 3W
        AddTask(JT, '1020', 'Requirements Workshop',               CalcDate('+2W', D),     CalcDate('+6W', D),     JT."Job Task Type"::Posting);   // 4W
        AddTask(JT, '1030', 'As-Is Process Mapping',               CalcDate('+5W', D),     CalcDate('+8W', D),     JT."Job Task Type"::Posting);   // 3W
        AddTask(JT, '1040', 'Gap Analysis & Sign-off',             CalcDate('+6W', D),     CalcDate('+9W', D),     JT."Job Task Type"::Posting);   // 3W
        AddTask(JT, '1999', 'Phase 1 Total',                       D,                      CalcDate('+9W', D),     JT."Job Task Type"::"End-Total");

        AddTask(JT, '2000', 'Phase 2: Solution Design',            CalcDate('+9W', D),     CalcDate('+22W', D),    JT."Job Task Type"::"Begin-Total");
        AddTask(JT, '2010', 'System Architecture Design',          CalcDate('+9W', D),     CalcDate('+13W', D),    JT."Job Task Type"::Posting);   // 4W
        AddTask(JT, '2020', 'Data Migration Design',               CalcDate('+11W', D),    CalcDate('+15W', D),    JT."Job Task Type"::Posting);   // 4W
        AddTask(JT, '2030', 'Integration Architecture Design',     CalcDate('+13W', D),    CalcDate('+17W', D),    JT."Job Task Type"::Posting);   // 4W
        AddTask(JT, '2040', 'Customization Specification',         CalcDate('+16W', D),    CalcDate('+22W', D),    JT."Job Task Type"::Posting);   // 6W
        AddTask(JT, '2999', 'Phase 2 Total',                       CalcDate('+9W', D),     CalcDate('+22W', D),    JT."Job Task Type"::"End-Total");

        AddTask(JT, '3000', 'Phase 3: Build & Configuration',      CalcDate('+22W', D),    CalcDate('+38W', D),    JT."Job Task Type"::"Begin-Total");
        AddTask(JT, '3010', 'Base System Configuration',           CalcDate('+22W', D),    CalcDate('+25W', D),    JT."Job Task Type"::Posting);   // 3W
        AddTask(JT, '3020', 'Custom Development',                  CalcDate('+23W', D),    CalcDate('+31W', D),    JT."Job Task Type"::Posting);   // 8W
        AddTask(JT, '3030', 'Integration Development',             CalcDate('+26W', D),    CalcDate('+33W', D),    JT."Job Task Type"::Posting);   // 7W
        AddTask(JT, '3040', 'Data Migration Scripts',              CalcDate('+30W', D),    CalcDate('+35W', D),    JT."Job Task Type"::Posting);   // 5W
        AddTask(JT, '3050', 'Unit & Integration Testing',          CalcDate('+34W', D),    CalcDate('+38W', D),    JT."Job Task Type"::Posting);   // 4W
        AddTask(JT, '3999', 'Phase 3 Total',                       CalcDate('+22W', D),    CalcDate('+38W', D),    JT."Job Task Type"::"End-Total");

        AddTask(JT, '4000', 'Phase 4: UAT & Training',             CalcDate('+38W', D),    CalcDate('+47W', D),    JT."Job Task Type"::"Begin-Total");
        AddTask(JT, '4010', 'User Acceptance Testing',             CalcDate('+38W', D),    CalcDate('+42W', D),    JT."Job Task Type"::Posting);   // 4W
        AddTask(JT, '4020', 'Bug Fixing & Retest',                 CalcDate('+41W', D),    CalcDate('+45W', D),    JT."Job Task Type"::Posting);   // 4W
        AddTask(JT, '4030', 'End-User Training',                   CalcDate('+40W', D),    CalcDate('+47W', D),    JT."Job Task Type"::Posting);   // 7W
        AddTask(JT, '4999', 'Phase 4 Total',                       CalcDate('+38W', D),    CalcDate('+47W', D),    JT."Job Task Type"::"End-Total");

        AddTask(JT, '5000', 'Phase 5: Go-Live',                    CalcDate('+47W', D),    CalcDate('+52W', D),    JT."Job Task Type"::"Begin-Total");
        AddTask(JT, '5010', 'Data Migration Execution',            CalcDate('+47W', D),    CalcDate('+50W', D),    JT."Job Task Type"::Posting);   // 3W
        AddTask(JT, '5020', 'Go-Live Cutover',                     CalcDate('+49W', D),    CalcDate('+52W', D),    JT."Job Task Type"::Posting);   // 3W
        AddTask(JT, '5030', 'Hypercare Support',                   CalcDate('+50W', D),    CalcDate('+52W', D),    JT."Job Task Type"::Posting);   // 2W (final sprint, runs parallel to cutover)
        AddTask(JT, '5999', 'Phase 5 Total',                       CalcDate('+47W', D),    CalcDate('+52W', D),    JT."Job Task Type"::"End-Total");

        AddTask(JT, '9999', 'ERP Implementation Total',            D,                      CalcDate('+52W', D),    JT."Job Task Type"::Total);

        Indent.IndentJobTasks(JT);
    end;

    local procedure BuildTasksJOB003(var Indent: Codeunit "Job Task Indent")
    var
        JT: Record "Job Task";
        D: Date;
    begin
        D := CalcDate('+2W', gStartDate);  // offset 2W for Gantt visual separation
        JT."Job No." := 'JOB003';

        // ── 42-week Facility Infrastructure Upgrade — each posting task ≥ 3 weeks
        AddTask(JT, '0',    'Facility Infrastructure Upgrade',      D,                      CalcDate('+42W', D),    JT."Job Task Type"::Heading);

        AddTask(JT, '1000', 'Phase 1: Planning & Survey',           D,                      CalcDate('+9W', D),     JT."Job Task Type"::"Begin-Total");
        AddTask(JT, '1010', 'Site Survey & Condition Assessment',   D,                      CalcDate('+3W', D),     JT."Job Task Type"::Posting);   // 3W
        AddTask(JT, '1020', 'Technical Feasibility Study',          CalcDate('+2W', D),     CalcDate('+5W', D),     JT."Job Task Type"::Posting);   // 3W
        AddTask(JT, '1030', 'Project Schedule & Budget Planning',   CalcDate('+4W', D),     CalcDate('+9W', D),     JT."Job Task Type"::Posting);   // 5W
        AddTask(JT, '1999', 'Phase 1 Total',                        D,                      CalcDate('+9W', D),     JT."Job Task Type"::"End-Total");

        AddTask(JT, '2000', 'Phase 2: Procurement & Preparation',   CalcDate('+9W', D),     CalcDate('+18W', D),    JT."Job Task Type"::"Begin-Total");
        AddTask(JT, '2010', 'Vendor Selection & Contracting',       CalcDate('+9W', D),     CalcDate('+12W', D),    JT."Job Task Type"::Posting);   // 3W
        AddTask(JT, '2020', 'Material & Equipment Procurement',     CalcDate('+11W', D),    CalcDate('+15W', D),    JT."Job Task Type"::Posting);   // 4W
        AddTask(JT, '2030', 'Site Preparation & Logistics',         CalcDate('+14W', D),    CalcDate('+18W', D),    JT."Job Task Type"::Posting);   // 4W
        AddTask(JT, '2999', 'Phase 2 Total',                        CalcDate('+9W', D),     CalcDate('+18W', D),    JT."Job Task Type"::"End-Total");

        AddTask(JT, '3000', 'Phase 3: Installation & Construction',  CalcDate('+18W', D),    CalcDate('+31W', D),    JT."Job Task Type"::"Begin-Total");
        AddTask(JT, '3010', 'Electrical System Installation',        CalcDate('+18W', D),    CalcDate('+22W', D),    JT."Job Task Type"::Posting);   // 4W
        AddTask(JT, '3020', 'HVAC System Installation',              CalcDate('+19W', D),    CalcDate('+23W', D),    JT."Job Task Type"::Posting);   // 4W
        AddTask(JT, '3030', 'Network & IT Infrastructure',           CalcDate('+21W', D),    CalcDate('+26W', D),    JT."Job Task Type"::Posting);   // 5W
        AddTask(JT, '3040', 'Security & Access Control Systems',     CalcDate('+24W', D),    CalcDate('+31W', D),    JT."Job Task Type"::Posting);   // 7W
        AddTask(JT, '3999', 'Phase 3 Total',                         CalcDate('+18W', D),    CalcDate('+31W', D),    JT."Job Task Type"::"End-Total");

        AddTask(JT, '4000', 'Phase 4: Commissioning & Handover',     CalcDate('+31W', D),    CalcDate('+42W', D),    JT."Job Task Type"::"Begin-Total");
        AddTask(JT, '4010', 'System Commissioning & Testing',        CalcDate('+31W', D),    CalcDate('+34W', D),    JT."Job Task Type"::Posting);   // 3W
        AddTask(JT, '4020', 'Integration & Performance Testing',     CalcDate('+33W', D),    CalcDate('+37W', D),    JT."Job Task Type"::Posting);   // 4W
        AddTask(JT, '4030', 'Punch List & Snagging Resolution',      CalcDate('+36W', D),    CalcDate('+39W', D),    JT."Job Task Type"::Posting);   // 3W
        AddTask(JT, '4040', 'Final Inspection & Handover',           CalcDate('+38W', D),    CalcDate('+42W', D),    JT."Job Task Type"::Posting);   // 4W
        AddTask(JT, '4999', 'Phase 4 Total',                         CalcDate('+31W', D),    CalcDate('+42W', D),    JT."Job Task Type"::"End-Total");

        AddTask(JT, '9999', 'Infrastructure Upgrade Total',           D,                      CalcDate('+42W', D),    JT."Job Task Type"::Total);

        Indent.IndentJobTasks(JT);
    end;

    local procedure AddTask(var JT: Record "Job Task"; TaskNo: Code[20]; Desc: Text[100]; StartDate: Date; EndDate: Date; TaskType: Enum "Job Task Type")
    begin
        JT."Job Task No." := TaskNo;
        JT.Description := Desc;
        JT."PlannedStartDate" := StartDate;
        JT.Validate("PlannedEndDate", EndDate);
        JT.Duration := EndDate - StartDate;  // Gantt bar width reads Duration, not PlannedEndDate
        JT."Job Task Type" := TaskType;
        if not JT.Insert() then
            JT.Modify();
        LogRecord(Database::"Job Task", JT.RecordId(), JT."Job No." + '.' + TaskNo + ' ' + Desc);
    end;

    // ──────────────────────────────────────────────────────────────────────────
    // Job Task Links — all four link types with varied lag days
    // ──────────────────────────────────────────────────────────────────────────

    local procedure CreateJobTaskLinks()
    begin
        // ── JOB001: Radome Repair — sequential + parallel with Finish-Start, Start-Start, Finish-Finish
        CreateLink('JOB001', '1010', '1020', Enum::"BCG Gantt Link Type"::"Finish-Start",  0);
        CreateLink('JOB001', '1020', '1030', Enum::"BCG Gantt Link Type"::"Finish-Start",  1);  // 1-day review buffer
        CreateLink('JOB001', '1030', '1040', Enum::"BCG Gantt Link Type"::"Finish-Start",  0);
        CreateLink('JOB001', '1040', '2010', Enum::"BCG Gantt Link Type"::"Finish-Start",  1);  // approval before disassembly
        CreateLink('JOB001', '2010', '2020', Enum::"BCG Gantt Link Type"::"Finish-Start",  0);
        CreateLink('JOB001', '2010', '2030', Enum::"BCG Gantt Link Type"::"Start-Start",   2);  // parts ID starts 2 days after disassembly begins
        CreateLink('JOB001', '2020', '2040', Enum::"BCG Gantt Link Type"::"Finish-Start",  0);
        CreateLink('JOB001', '2030', '2040', Enum::"BCG Gantt Link Type"::"Finish-Start",  1);
        CreateLink('JOB001', '2040', '2050', Enum::"BCG Gantt Link Type"::"Start-Start",   3);  // follow-up starts 3 days after procurement
        CreateLink('JOB001', '2040', '3010', Enum::"BCG Gantt Link Type"::"Finish-Start",  0);  // parts needed before surface prep
        CreateLink('JOB001', '3010', '3020', Enum::"BCG Gantt Link Type"::"Finish-Start",  0);
        CreateLink('JOB001', '3020', '3030', Enum::"BCG Gantt Link Type"::"Finish-Start",  2);  // paint starts 2 days after repair (cure time)
        CreateLink('JOB001', '3030', '3040', Enum::"BCG Gantt Link Type"::"Finish-Start",  1);
        CreateLink('JOB001', '3040', '3050', Enum::"BCG Gantt Link Type"::"Start-Start",   1);  // electrical overlaps assembly
        CreateLink('JOB001', '3050', '4010', Enum::"BCG Gantt Link Type"::"Finish-Start",  0);
        CreateLink('JOB001', '3040', '4010', Enum::"BCG Gantt Link Type"::"Finish-Finish", 2);  // testing finishes 2 days after assembly complete
        CreateLink('JOB001', '4010', '4020', Enum::"BCG Gantt Link Type"::"Finish-Start",  0);
        CreateLink('JOB001', '4020', '4030', Enum::"BCG Gantt Link Type"::"Finish-Start",  0);
        CreateLink('JOB001', '4030', '4040', Enum::"BCG Gantt Link Type"::"Finish-Start",  1);
        CreateLink('JOB001', '4040', '4050', Enum::"BCG Gantt Link Type"::"Finish-Start",  0);

        // ── JOB002: ERP Implementation — complex dependency fan-out with all four link types
        CreateLink('JOB002', '1010', '1020', Enum::"BCG Gantt Link Type"::"Finish-Start",  0);
        CreateLink('JOB002', '1020', '1030', Enum::"BCG Gantt Link Type"::"Start-Start",   1);  // mapping can start while workshop is in progress
        CreateLink('JOB002', '1030', '1040', Enum::"BCG Gantt Link Type"::"Finish-Start",  0);
        CreateLink('JOB002', '1040', '2010', Enum::"BCG Gantt Link Type"::"Finish-Start",  2);  // 2-day buffer after sign-off
        CreateLink('JOB002', '2010', '2020', Enum::"BCG Gantt Link Type"::"Start-Start",   0);  // data design starts with architecture
        CreateLink('JOB002', '2010', '2030', Enum::"BCG Gantt Link Type"::"Start-Start",   2);
        CreateLink('JOB002', '2010', '2040', Enum::"BCG Gantt Link Type"::"Start-Start",   3);
        CreateLink('JOB002', '2020', '3040', Enum::"BCG Gantt Link Type"::"Finish-Start",  0);  // data design feeds migration scripts
        CreateLink('JOB002', '2030', '3030', Enum::"BCG Gantt Link Type"::"Finish-Start",  0);  // integration design feeds dev
        CreateLink('JOB002', '2040', '3020', Enum::"BCG Gantt Link Type"::"Finish-Start",  1);  // spec feeds custom dev
        CreateLink('JOB002', '3010', '3050', Enum::"BCG Gantt Link Type"::"Finish-Start",  0);
        CreateLink('JOB002', '3020', '3050', Enum::"BCG Gantt Link Type"::"Finish-Finish", 2);  // dev must finish before testing ends
        CreateLink('JOB002', '3030', '3050', Enum::"BCG Gantt Link Type"::"Finish-Finish", 1);
        CreateLink('JOB002', '3050', '4010', Enum::"BCG Gantt Link Type"::"Finish-Start",  1);
        CreateLink('JOB002', '4010', '4020', Enum::"BCG Gantt Link Type"::"Finish-Start",  0);
        CreateLink('JOB002', '4010', '4030', Enum::"BCG Gantt Link Type"::"Start-Start",   2);  // training can begin while UAT runs
        CreateLink('JOB002', '4020', '5010', Enum::"BCG Gantt Link Type"::"Finish-Start",  2);
        CreateLink('JOB002', '5010', '5020', Enum::"BCG Gantt Link Type"::"Finish-Start",  1);
        CreateLink('JOB002', '5020', '5030', Enum::"BCG Gantt Link Type"::"Finish-Start",  0);

        // ── JOB003: Infrastructure Upgrade — parallel installs with Finish-Finish convergence
        CreateLink('JOB003', '1010', '1020', Enum::"BCG Gantt Link Type"::"Finish-Start",  0);
        CreateLink('JOB003', '1010', '1030', Enum::"BCG Gantt Link Type"::"Start-Start",   1);  // planning starts 1 day after survey
        CreateLink('JOB003', '1020', '2010', Enum::"BCG Gantt Link Type"::"Finish-Start",  1);
        CreateLink('JOB003', '2010', '2020', Enum::"BCG Gantt Link Type"::"Finish-Start",  2);
        CreateLink('JOB003', '2020', '2030', Enum::"BCG Gantt Link Type"::"Start-Start",   3);  // site prep overlaps procurement
        CreateLink('JOB003', '2030', '3010', Enum::"BCG Gantt Link Type"::"Finish-Start",  0);
        CreateLink('JOB003', '3010', '3020', Enum::"BCG Gantt Link Type"::"Start-Start",   0);  // HVAC starts with electrical
        CreateLink('JOB003', '3020', '3030', Enum::"BCG Gantt Link Type"::"Start-Start",   2);
        CreateLink('JOB003', '3030', '3040', Enum::"BCG Gantt Link Type"::"Start-Start",   1);
        CreateLink('JOB003', '3010', '4010', Enum::"BCG Gantt Link Type"::"Finish-Finish", 3);  // commissioning can end 3 days after electrical
        CreateLink('JOB003', '3020', '4010', Enum::"BCG Gantt Link Type"::"Finish-Finish", 3);
        CreateLink('JOB003', '3030', '4010', Enum::"BCG Gantt Link Type"::"Finish-Finish", 2);
        CreateLink('JOB003', '3040', '4020', Enum::"BCG Gantt Link Type"::"Finish-Start",  0);
        CreateLink('JOB003', '4010', '4020', Enum::"BCG Gantt Link Type"::"Finish-Start",  0);
        CreateLink('JOB003', '4020', '4030', Enum::"BCG Gantt Link Type"::"Finish-Start",  1);
        CreateLink('JOB003', '4030', '4040', Enum::"BCG Gantt Link Type"::"Finish-Start",  0);
    end;

    local procedure CreateLink(JobNo: Code[20]; SrcTask: Code[20]; TgtTask: Code[20]; LinkType: Enum "BCG Gantt Link Type"; LagDays: Integer)
    var
        Link: Record "BCG Gantt Task Link";
    begin
        Link.Init();
        Link."Job No." := JobNo;
        Link."Source Task No." := SrcTask;
        Link."Target Task No." := TgtTask;
        Link."Link Type" := LinkType;
        Link."Lag (Days)" := LagDays;
        if Link.Insert() then
            LogRecord(Database::"BCG Gantt Task Link", Link.RecordId(), JobNo + ' ' + SrcTask + '->' + TgtTask);
        // skip silently on duplicate (same source+target+type already exists)
    end;

    // ──────────────────────────────────────────────────────────────────────────
    // Resources
    // ──────────────────────────────────────────────────────────────────────────

    local procedure LoadResources()
    var
        Resource: Record Resource;
        Idx: Integer;
    begin
        Resource.Reset();
        if not Resource.FindSet() then begin
            Message('No resources found. Create at least 2 resources before generating planning data.');
            exit;
        end;
        repeat
            Idx += 1;
            if Idx <= ArrayLen(gRes) then
                gRes[Idx] := Resource."No.";
        until (Resource.Next() = 0) or (Idx >= ArrayLen(gRes));
        gResCount := Idx;
    end;

    local procedure GetRes(Preference: Integer): Code[20]
    begin
        if gResCount = 0 then exit('');
        if Preference <= gResCount then
            exit(gRes[Preference]);
        // wrap around when fewer resources than preference slots
        exit(gRes[((Preference - 1) mod gResCount) + 1]);
    end;

    // ──────────────────────────────────────────────────────────────────────────
    // Capacity & Day Planning
    // ──────────────────────────────────────────────────────────────────────────

    local procedure CreateCapacityAndDayPlanning()
    var
        i: Integer;
    begin
        if gResCount = 0 then exit;

        // Ensure all loaded resources have capacity across the full demo period
        for i := 1 to gResCount do
            CreateResourceCapacity(gRes[i]);

        // Each job gets a dedicated leader (odd slot) and member (even slot);
        // wrap-around ensures this works with as few as 1 resource.
        BuildDayPlanningsForJob('JOB001', GetRes(1), GetRes(2));
        BuildDayPlanningsForJob('JOB002', GetRes(3), GetRes(4));
        BuildDayPlanningsForJob('JOB003', GetRes(5), GetRes(6));
    end;

    local procedure CreateResourceCapacity(ResNo: Code[20])
    var
        Res: Record Resource;
        ResCap: Record "Res. Capacity Entry";
        DT: Date;
        EntryNo: Integer;
    begin
        if ResNo = '' then exit;
        Res.Get(ResNo);
        ResCap.Reset();
        if ResCap.FindLast() then
            EntryNo := ResCap."Entry No." + 1
        else
            EntryNo := 1;
        for DT := gStartDate to gEndDate do begin
            if not IsWorkingDay(DT) then continue;
            Res.SetRange("Date Filter", DT);
            Res.CalcFields(Capacity);
            if Res.Capacity = 0 then begin
                ResCap.Init();
                ResCap."Entry No." := EntryNo;
                ResCap."Resource No." := ResNo;
                ResCap.Date := DT;
                ResCap.Capacity := 8;
                ResCap."Resource Group No." := Res."Resource Group No.";
                ResCap."Start Time" := 080000T;
                ResCap."End Time" := 160000T;
                ResCap.Insert();
                LogRecord(Database::"Res. Capacity Entry", ResCap.RecordId(), ResNo + ' ' + Format(DT));
                EntryNo += 1;
            end;
        end;
    end;

    local procedure BuildDayPlanningsForJob(JobNo: Code[20]; LeaderRes: Code[20]; MemberRes: Code[20])
    var
        JT: Record "Job Task";
    begin
        JT.SetRange("Job No.", JobNo);
        JT.SetRange("Job Task Type", JT."Job Task Type"::Posting);
        if JT.FindSet() then
            repeat
                BuildDayPlanningsForTask(JT, LeaderRes, MemberRes);
            until JT.Next() = 0;
    end;

    local procedure BuildDayPlanningsForTask(JT: Record "Job Task"; LeaderRes: Code[20]; MemberRes: Code[20])
    var
        DP: Record "Day Planning";
        DT: Date;
        TaskStart: Date;
        TaskEnd: Date;
        PlanSt: Enum "Plan Status";
        DataOwner: Enum "Data Owner Opt.";
        ReqStart: Time;
        ReqEnd: Time;
        AsgnStart: Time;
        AsgnEnd: Time;
        ReqHours: Decimal;
        AsgnHours: Decimal;
        ResGrpLeader: Code[20];
        ResGrpMember: Code[20];
    begin
        TaskStart := JT."PlannedStartDate";
        TaskEnd := JT."PlannedEndDate";
        if TaskStart = 0D then TaskStart := gStartDate;
        if TaskEnd = 0D then TaskEnd := gEndDate;
        if TaskEnd > gEndDate then TaskEnd := gEndDate;
        if TaskStart < gStartDate then TaskStart := gStartDate;
        if TaskEnd < TaskStart then exit;

        ResGrpLeader := GetResGrp(LeaderRes);
        ResGrpMember := GetResGrp(MemberRes);

        for DT := TaskStart to TaskEnd do begin
            if not IsWorkingDay(DT) then continue;

            PlanSt := CalcPlanStatus(DT);
            GetTimeSlot(DT, ReqStart, ReqEnd, AsgnStart, AsgnEnd);
            ReqHours := (ReqEnd - ReqStart) / 3600000;
            AsgnHours := (AsgnEnd - AsgnStart) / 3600000;

            // ── Leader line (every working day) ──────────────────────────────
            if LeaderRes <> '' then begin
                DP.Init();
                DP."Job No." := JT."Job No.";
                DP."Job Task No." := JT."Job Task No.";
                DP."Task Date" := DT;
                DP."Day Line No." := NextDayLineNo(JT."Job No.", JT."Job Task No.");
                DP."Plan Status" := PlanSt;
                DP."Requested Resource No." := LeaderRes;
                DP."Start Time Requested" := ReqStart;
                DP."End Time Requested" := ReqEnd;
                DP."Requested Hours" := ReqHours;
                DP.Leader := true;
                DP."Team Leader" := LeaderRes;
                DP."Data Owner" := "Data Owner Opt."::"TeamLeader";
                DP.Description := 'Leader: ' + JT."Job No." + '-' + JT."Job Task No.";
                if PlanSt <> "Plan Status"::"In Request" then begin
                    DP."Assigned Resource No." := LeaderRes;
                    DP."Resource Group No." := ResGrpLeader;
                    DP."Start Time Assigned" := AsgnStart;
                    DP."End Time Assigned" := AsgnEnd;
                    DP."Assigned Hours" := AsgnHours;
                end;
                DP.Insert(false);
                LogRecord(Database::"Day Planning", DP.RecordId(), JT."Job No." + '.' + JT."Job Task No." + ' ' + Format(DT) + ' L');
            end;

            // ── Member line (every other working day, only if member differs from leader) ─
            if (MemberRes <> '') and (MemberRes <> LeaderRes) and IsEvenDayOfMonth(DT) then begin
                DP.Init();
                DP."Job No." := JT."Job No.";
                DP."Job Task No." := JT."Job Task No.";
                DP."Task Date" := DT;
                DP."Day Line No." := NextDayLineNo(JT."Job No.", JT."Job Task No.");
                DP."Plan Status" := PlanSt;
                DP."Requested Resource No." := MemberRes;
                DP."Start Time Requested" := ReqStart;
                DP."End Time Requested" := ReqEnd;
                DP."Requested Hours" := ReqHours;
                DP.Leader := false;
                DP."Team Leader" := LeaderRes;
                DP."Data Owner" := "Data Owner Opt."::"TeamMember";
                DP.Description := 'Member: ' + JT."Job No." + '-' + JT."Job Task No.";
                if PlanSt <> "Plan Status"::"In Request" then begin
                    DP."Assigned Resource No." := MemberRes;
                    DP."Resource Group No." := ResGrpMember;
                    DP."Start Time Assigned" := AsgnStart;
                    DP."End Time Assigned" := AsgnEnd;
                    DP."Assigned Hours" := AsgnHours;
                end;
                DP.Insert(false);
                LogRecord(Database::"Day Planning", DP.RecordId(), JT."Job No." + '.' + JT."Job Task No." + ' ' + Format(DT) + ' M');
            end;
        end;
    end;

    // ──────────────────────────────────────────────────────────────────────────
    // Helpers
    // ──────────────────────────────────────────────────────────────────────────

    local procedure CalcPlanStatus(DT: Date): Enum "Plan Status"
    begin
        // Historical (>2 weeks ago): Accepted
        // Near-term (within ±2 weeks of today): In Progress
        // Future (>2 weeks from now): In Request
        if DT < CalcDate('-2W', Today()) then
            exit("Plan Status"::Accepted);
        if DT <= CalcDate('+2W', Today()) then
            exit("Plan Status"::"In Progress");
        exit("Plan Status"::"In Request");
    end;

    local procedure GetTimeSlot(DT: Date; var ReqStart: Time; var ReqEnd: Time; var AsgnStart: Time; var AsgnEnd: Time)
    begin
        // Vary hours by day-of-week to show realistic workload variation
        case Date2DWY(DT, 1) of
            1:  // Monday: full day, fully assigned
                begin
                    ReqStart := 080000T; ReqEnd := 160000T;   // 8 h requested
                    AsgnStart := 080000T; AsgnEnd := 160000T;  // 8 h assigned
                end;
            2:  // Tuesday: morning block, fully assigned
                begin
                    ReqStart := 080000T; ReqEnd := 120000T;   // 4 h
                    AsgnStart := 080000T; AsgnEnd := 120000T;
                end;
            3:  // Wednesday: late start, assigned shorter than requested (partial availability)
                begin
                    ReqStart := 090000T; ReqEnd := 170000T;   // 8 h requested
                    AsgnStart := 090000T; AsgnEnd := 130000T;  // 4 h assigned
                end;
            4:  // Thursday: full day requested, slightly under-assigned
                begin
                    ReqStart := 080000T; ReqEnd := 170000T;   // 9 h requested
                    AsgnStart := 080000T; AsgnEnd := 160000T;  // 8 h assigned
                end;
            5:  // Friday: short day
                begin
                    ReqStart := 080000T; ReqEnd := 130000T;   // 5 h
                    AsgnStart := 080000T; AsgnEnd := 130000T;
                end;
            else begin
                    ReqStart := 080000T; ReqEnd := 160000T;
                    AsgnStart := 080000T; AsgnEnd := 160000T;
                end;
        end;
    end;

    local procedure IsEvenDayOfMonth(DT: Date): Boolean
    begin
        exit((Date2DMY(DT, 1) mod 2) = 0);
    end;

    local procedure GetResGrp(ResNo: Code[20]): Code[20]
    var
        Res: Record Resource;
    begin
        if (ResNo <> '') and Res.Get(ResNo) then
            exit(Res."Resource Group No.");
        exit('');
    end;

    local procedure NextDayLineNo(JobNo: Code[20]; TaskNo: Code[20]): Integer
    var
        DP: Record "Day Planning";
    begin
        DP.SetRange("Job No.", JobNo);
        DP.SetRange("Job Task No.", TaskNo);
        if DP.FindLast() then
            exit(DP."Day Line No." + 10000)
        else
            exit(10000);
    end;

    local procedure IsWorkingDay(DT: Date): Boolean
    begin
        case Date2DWY(DT, 1) of
            1: exit(gWorkHoursTemplate.Monday <> 0);
            2: exit(gWorkHoursTemplate.Tuesday <> 0);
            3: exit(gWorkHoursTemplate.Wednesday <> 0);
            4: exit(gWorkHoursTemplate.Thursday <> 0);
            5: exit(gWorkHoursTemplate.Friday <> 0);
            6: exit(gWorkHoursTemplate.Saturday <> 0);
            7: exit(gWorkHoursTemplate.Sunday <> 0);
            else exit(false);
        end;
    end;

    local procedure LogRecord(TableID: Integer; RecID: RecordId; Desc: Text[250])
    var
        LogEntry: Record "Demo Data Log Entry";
    begin
        gLogEntryNo += 1;
        LogEntry.Init();
        LogEntry."Entry No." := gLogEntryNo;
        LogEntry."Table ID" := TableID;
        LogEntry."Record ID" := RecID;
        LogEntry.Description := CopyStr(Desc, 1, MaxStrLen(LogEntry.Description));
        LogEntry."Created At" := CurrentDateTime();
        LogEntry.Insert();
    end;
}
