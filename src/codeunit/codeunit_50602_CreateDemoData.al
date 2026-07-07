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
        CreateBulkJobs();
        CreateDemoResources();
        LoadResources();
        CreateCapacityAndDayPlanning();
        CreateGanttChartSetupDefaults();
        CreateDailyOptimizerSetupDefault();
        Message('Demo data created successfully. %1 records logged.', gLogEntryNo);
    end;

    var
        gWorkHoursTemplate: Record "Work-Hour Template";
        gRes: array[6] of Code[20];
        gResCount: Integer;
        gStartDate: Date;
        gEndDate: Date;
        gLogEntryNo: Integer;
        gVendorNos: List of [Code[20]];
        gSkillCodes: List of [Code[10]];
        gUOMCodes: List of [Code[10]];
        gGenProdPostingGroups: List of [Code[20]];
        gVATProdPostingGroups: List of [Code[20]];
        gResourceGroupNos: List of [Code[20]];
        gForemanNos: List of [Code[20]];
        gBulkJobNos: List of [Code[20]];
        gResDaySlotUsed: Dictionary of [Text, Integer];
        gResourceSkillCache: Dictionary of [Code[20], Code[10]];
        gResourcePoolCache: Dictionary of [Code[20], Code[20]];
        gVendorIdx: Integer;
        gSkillIdx: Integer;
        gUOMIdx: Integer;
        gGenProdIdx: Integer;
        gVATProdIdx: Integer;
        gResGroupIdx: Integer;
        gPoolSeq: Integer;
        gMemberSeq: Integer;
        gExternalSeq: Integer;
        gFirstNames: array[20] of Text[30];
        gLastNames: array[20] of Text[30];

    // ──────────────────────────────────────────────────────────────────────────
    // Initialization & Cleanup
    // ──────────────────────────────────────────────────────────────────────────

    local procedure Initialize()
    var
        LogEntry: Record "Demo Data Log Entry";
    begin
        gStartDate := CalcDate('<WD1-1W>', Today());
        // Covers JOB002 (start+1W+52W) and the 170 bulk jobs (max start offset +9W, 98W span) + buffer
        gEndDate := CalcDate('+110W', gStartDate);
        EnsureWorkHourTemplate('BASIS');
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
        ResCap: Record "Res. Capacity Entry";
        RecRef: RecordRef;
        DeletedCount: Integer;
    begin
        // Demo resource capacity (DRP*/DRM*) is not individually logged — see
        // CreateDemoResourceCapacity — so it's bulk-deleted here by No. prefix instead of via
        // the per-record log loop below, which would otherwise have to process millions of rows.
        ResCap.SetFilter("Resource No.", 'DRP*|DRM*');
        ResCap.DeleteAll(false);

        // Only delete records that were logged by a previous demo data run.
        // User-created records are never touched.
        LogEntry.Reset();
        if LogEntry.FindLast() then
            repeat
                RecRef.Open(LogEntry."Table ID");
                if RecRef.Get(LogEntry."Record ID") then
                    RecRef.Delete(false);
                RecRef.Close();
                DeletedCount += 1;
                // Commit periodically so a large demo data set (tens of thousands of logged
                // records) doesn't hold one long-running transaction/lock for the whole delete.
                if DeletedCount mod 1000 = 0 then
                    Commit();
            until LogEntry.Next(-1) = 0;
        LogEntry.DeleteAll();
        gLogEntryNo := 0;
    end;

    local procedure CreateGanttChartSetupDefaults()
    var
        UserRec: Record User;
        GanttSetup: Record "Gantt Chart Setup";
    begin
        // Backfill the standard Gantt Settings defaults for every user that doesn't have their
        // own record yet. This is a one-time per-user seed, not disposable demo data, so it is
        // intentionally not logged via LogRecord/DeleteDemoData — re-running demo data creation
        // must never wipe out a user's own customized Gantt Settings.
        if UserRec.FindSet() then
            repeat
                if not GanttSetup.Get(UserRec."User Name") then begin
                    GanttSetup.Init();
                    GanttSetup."User ID" := UserRec."User Name";
                    GanttSetup."Date Range Type" := GanttSetup."Date Range Type"::Calculated;
                    Evaluate(GanttSetup."From Data Formula", 'WD1-1W');
                    Evaluate(GanttSetup."To Data Formula", 'WD7+4W');
                    GanttSetup."Load Job Tasks" := true;
                    GanttSetup."Load Resources" := true;
                    GanttSetup."Load Day Plannings" := true;
                    GanttSetup."Show Start Date" := false;
                    GanttSetup."Show Duration" := false;
                    GanttSetup."Show Task Type" := false;
                    GanttSetup.Insert();
                end;
            until UserRec.Next() = 0;
    end;

    local procedure CreateDailyOptimizerSetupDefault()
    var
        Setup: Record "Daily Optimizer Setup";
    begin
        // Global app setting, not disposable demo data: only seed the singleton record if it
        // doesn't exist yet, and never touch it again afterwards (not logged via LogRecord/
        // DeleteDemoData, same reasoning as CreateGanttChartSetupDefaults).
        if Setup.Get() then
            exit;

        EnsureBaseCalendar('BASIS');
        EnsureWorkHourTemplate('BASIS');
        EnsureSkillCode('ELEKTR', 'Electrician');
        EnsureNoSeries('OI', 'Order Intake');
        EnsureNoSeries('WO', 'Work Order');

        Setup.Init();
        Setup."Base Calendar" := 'BASIS';
        Setup."Work hour Template" := 'BASIS';
        Setup."Default Skill" := 'ELEKTR';
        Setup."Order Intake Nos" := 'OI';
        Setup."Work Order Nos" := 'WO';
        Setup.Insert();
    end;

    local procedure EnsureBaseCalendar(CalendarCode: Code[10])
    var
        BaseCalendar: Record "Base Calendar";
    begin
        if BaseCalendar.Get(CalendarCode) then
            exit;
        BaseCalendar.Init();
        BaseCalendar.Code := CalendarCode;
        BaseCalendar.Name := CalendarCode;
        BaseCalendar.Insert();
    end;

    local procedure EnsureWorkHourTemplate(TemplateCode: Code[10])
    var
        WorkHourTemplate: Record "Work-Hour Template";
    begin
        if WorkHourTemplate.Get(TemplateCode) then
            exit;
        WorkHourTemplate.Init();
        WorkHourTemplate.Code := TemplateCode;
        WorkHourTemplate.Description := 'Standard 5-day work week';
        WorkHourTemplate.Monday := 8;
        WorkHourTemplate.Tuesday := 8;
        WorkHourTemplate.Wednesday := 8;
        WorkHourTemplate.Thursday := 8;
        WorkHourTemplate.Friday := 8;
        WorkHourTemplate.Saturday := 0;
        WorkHourTemplate.Sunday := 0;
        WorkHourTemplate.Insert();
    end;

    local procedure EnsureSkillCode(SkillCodeNo: Code[10]; Desc: Text[100])
    var
        SkillCode: Record "Skill Code";
    begin
        if SkillCode.Get(SkillCodeNo) then
            exit;
        SkillCode.Init();
        SkillCode.Code := SkillCodeNo;
        SkillCode.Description := Desc;
        SkillCode.Insert();
    end;

    local procedure EnsureNoSeries(SeriesCode: Code[20]; Desc: Text[100])
    var
        NoSeries: Record "No. Series";
    begin
        if NoSeries.Get(SeriesCode) then
            exit;
        NoSeries.Init();
        NoSeries.Code := SeriesCode;
        NoSeries.Description := Desc;
        NoSeries."Manual Nos." := true;
        NoSeries.Insert();
    end;

    local procedure EnsureResourceGroups()
    var
        ResourceGroup: Record "Resource Group";
    begin
        // A fresh sandbox with zero resource groups blocks all demo resource generation (every
        // resource needs a Resource Group No.), so seed a small default set if none exist at all.
        if not ResourceGroup.IsEmpty() then
            exit;
        EnsureResourceGroup('MECH', 'Mechanical');
        EnsureResourceGroup('ELEKTR', 'Electrical');
        EnsureResourceGroup('CIVIL', 'Civil & Construction');
        EnsureResourceGroup('LOGISTIC', 'Logistics');
        EnsureResourceGroup('GENERAL', 'General Labor');
    end;

    local procedure EnsureResourceGroup(GroupNo: Code[20]; Desc: Text[50])
    var
        ResourceGroup: Record "Resource Group";
    begin
        if ResourceGroup.Get(GroupNo) then
            exit;
        ResourceGroup.Init();
        ResourceGroup."No." := GroupNo;
        ResourceGroup.Name := Desc;
        ResourceGroup.Insert();
    end;

    // ──────────────────────────────────────────────────────────────────────────
    // Jobs
    // ──────────────────────────────────────────────────────────────────────────

    local procedure CreateJobs()
    var
        Job: Record Job;
        Customer: Record Customer;
    begin
        if not Customer.FindFirst() then
            EnsureCustomer(Customer);
        UpsertJob(Job, 'JOB001', 'Radome Repair Project', Customer."No.");
        UpsertJob(Job, 'JOB002', 'ERP System Implementation', Customer."No.");
        UpsertJob(Job, 'JOB003', 'Facility Infrastructure Upgrade', Customer."No.");
    end;

    local procedure EnsureCustomer(var Customer: Record Customer)
    var
        GenBusPostingGroup: Record "Gen. Business Posting Group";
        VATBusPostingGroup: Record "VAT Business Posting Group";
        CustPostingGroup: Record "Customer Posting Group";
    begin
        // No customers exist yet: create one minimal demo customer. Posting group fields are
        // only filled from whatever setup already exists in the system (first record found) —
        // we don't fabricate Gen. Bus./VAT Bus./Customer Posting Group or G/L Accounts from
        // scratch, since those cascade into full financial setup that's out of scope here.
        Customer.Init();
        Customer.Validate("No.", 'DEMOCUST');
        Customer.Validate(Name, 'Demo Customer');
        if GenBusPostingGroup.FindFirst() then
            Customer.Validate("Gen. Bus. Posting Group", GenBusPostingGroup.Code);
        if VATBusPostingGroup.FindFirst() then
            Customer.Validate("VAT Bus. Posting Group", VATBusPostingGroup.Code);
        if CustPostingGroup.FindFirst() then
            Customer.Validate("Customer Posting Group", CustPostingGroup.Code);
        Customer.Insert(true);
        LogRecord(Database::Customer, Customer.RecordId(), Customer."No." + ' ' + Customer.Name);
    end;

    local procedure UpsertJob(var Job: Record Job; No: Code[20]; Desc: Text[100]; CustNo: Code[20])
    begin
        // Validate("Sell-to Customer No.") triggers BC dimension management which iterates
        // Job Task Dimension rows for this job. If a row references a task that no longer
        // exists (e.g. task '7000' left from an older demo data version), BC throws
        // "Project Task does not exist". Remove any orphan rows first.
        DeleteOrphanJobTaskDimensions(No);
        Job.Init();
        // Suppress all base-app validation dialogs on this Job record. The Sell-to Customer
        // validation below fires Job.UpdateJobTaskDimension -> Confirm("You have changed a
        // dimension.\\Do you want to update the lines?"), plus a Sell-to/Bill-to customer-change
        // and empty-email confirm on re-runs. GetHideValidationDialog() gates every one of these
        // (Job.Table.al), so this single call replaces the fragile SingleInstance + global +
        // OnBeforeUpdateJobTaskDimension event-subscriber approach and reliably runs unattended.
        // Safe because CreateJobTasks() rebuilds every Job Task fresh immediately afterward.
        Job.SetHideValidationDialog(true);
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

        Indent.IndentJobTasks(JT, true);
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

        Indent.IndentJobTasks(JT, true);
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

        Indent.IndentJobTasks(JT, true);
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
    // Bulk Jobs — 170 generated jobs x 250 phased job tasks each (volume demo data).
    // Each job: 1 Heading + 31 phases (Begin-Total + 6 Posting + End-Total = 8 tasks) + 1
    // Total = 1 + 31*8 + 1 = 250 tasks. Job Task Nos. are zero-padded to a uniform 5 digits
    // (e.g. '01000', '01010', '31999') so Code-field text sorting stays numeric order across
    // the full range — mixing 4- and 5-digit codes would sort '10000' before '9999'.
    // ──────────────────────────────────────────────────────────────────────────

    local procedure CreateBulkJobs()
    var
        Customer: Record Customer;
        Window: Dialog;
        Idx: Integer;
        JobNo: Code[20];
        JobStart: Date;
        ProgressLbl: Label 'Creating bulk demo jobs...\n#1########## of #2##########';
    begin
        Clear(gBulkJobNos);
        Customer.FindFirst();

        if GuiAllowed() then
            Window.Open(ProgressLbl);
        for Idx := 1 to 170 do begin
            JobNo := 'DJB' + Format(Idx, 0, '<Integer,4><Filler Character,0>');
            JobStart := CalcDate(StrSubstNo('+%1W', Idx mod 10), gStartDate);
            CreateBulkJob(JobNo, Idx, Customer."No.");
            CreateBulkJobTasks(JobNo, JobStart);
            gBulkJobNos.Add(JobNo);
            if GuiAllowed() then begin
                Window.Update(1, Idx);
                Window.Update(2, 170);
            end;
            if Idx mod 10 = 0 then
                Commit();
        end;
        if GuiAllowed() then
            Window.Close();
    end;

    local procedure CreateBulkJob(JobNo: Code[20]; Idx: Integer; CustNo: Code[20])
    var
        Job: Record Job;
        Desc: Text[100];
    begin
        DeleteOrphanJobTaskDimensions(JobNo);
        Job.Init();
        Job.SetHideValidationDialog(true);
        Job."No." := JobNo;
        Desc := 'Demo Bulk Project ' + Format(Idx, 0, '<Integer,4><Filler Character,0>');
        Job.Description := CopyStr(Desc, 1, MaxStrLen(Job.Description));
        Job.Validate("Sell-to Customer No.", CustNo);
        if not Job.Insert() then
            Job.Modify();
        LogRecord(Database::Job, Job.RecordId(), JobNo + ' - ' + Job.Description);
    end;

    local procedure CreateBulkJobTasks(JobNo: Code[20]; JobStart: Date)
    var
        JT: Record "Job Task";
        Indent: Codeunit "Job Task Indent";
        Phase: Integer;
        Task: Integer;
        PhaseStart: Date;
        PhaseEnd: Date;
        PostStart: Date;
        PostEnd: Date;
        JobEnd: Date;
        DurationWeeks: Integer;
    begin
        // Phases start 3 weeks apart; the 8-week phase window is a safe upper bound covering
        // the widest posting stagger (up to 10 days) plus the longest posting duration (6W).
        JobEnd := CalcDate(StrSubstNo('+%1W', (31 - 1) * 3 + 8), JobStart);
        JT."Job No." := JobNo;

        AddTask(JT, '00000', 'Bulk Project', JobStart, JobEnd, JT."Job Task Type"::Heading);

        for Phase := 1 to 31 do begin
            PhaseStart := CalcDate(StrSubstNo('+%1W', (Phase - 1) * 3), JobStart);
            PhaseEnd := CalcDate('+8W', PhaseStart);
            AddTask(JT, PadPhaseNo(Phase * 1000), StrSubstNo('Phase %1', Phase), PhaseStart, PhaseEnd, JT."Job Task Type"::"Begin-Total");

            for Task := 1 to 6 do begin
                PostStart := CalcDate(StrSubstNo('+%1D', (Task - 1) * 2), PhaseStart);
                // Minimum 3-week duration, varied 3-6 weeks so bars aren't all identical.
                DurationWeeks := 3 + ((Phase + Task) mod 4);
                PostEnd := CalcDate(StrSubstNo('+%1W', DurationWeeks), PostStart);
                AddTask(JT, PadPhaseNo(Phase * 1000 + Task * 10), StrSubstNo('Phase %1 Task %2', Phase, Task), PostStart, PostEnd, JT."Job Task Type"::Posting);
            end;

            AddTask(JT, PadPhaseNo(Phase * 1000 + 999), StrSubstNo('Phase %1 Total', Phase), PhaseStart, PhaseEnd, JT."Job Task Type"::"End-Total");
        end;

        AddTask(JT, PadPhaseNo(32000), 'Bulk Project Total', JobStart, JobEnd, JT."Job Task Type"::Total);

        Indent.IndentJobTasks(JT, true);
    end;

    local procedure PadPhaseNo(Value: Integer): Code[20]
    begin
        exit(Format(Value, 0, '<Integer,5><Filler Character,0>'));
    end;

    // ──────────────────────────────────────────────────────────────────────────
    // Demo Resources — Pool / Pool Member / External, x3 varied iterations
    // ──────────────────────────────────────────────────────────────────────────

    local procedure CreateDemoResources()
    var
        Window: Dialog;
        Iteration: Integer;
        ResourcesCreated: Integer;
        ResourcesTotal: Integer;
        NoVendorsLbl: Label 'No vendors found. Skipping demo resource generation — create at least one vendor first.';
        NoSkillsLbl: Label 'No skill codes found. Skipping demo resource generation — create at least one skill code first.';
        NoUOMLbl: Label 'No units of measure found. Skipping demo resource generation — create at least one unit of measure first.';
        NoGenProdLbl: Label 'No Gen. Product Posting Groups found. Skipping demo resource generation — create at least one first.';
        NoVATProdLbl: Label 'No VAT Product Posting Groups found. Skipping demo resource generation — create at least one first.';
        NoResGroupLbl: Label 'No Resource Groups found. Skipping demo resource generation — create at least one resource group first.';
        ProgressLbl: Label 'Creating demo resources...\n#1########## of #2##########';
    begin
        EnsureResourceGroups();
        LoadReferenceData();
        if gVendorNos.Count() = 0 then begin
            Message(NoVendorsLbl);
            exit;
        end;
        if gSkillCodes.Count() = 0 then begin
            Message(NoSkillsLbl);
            exit;
        end;
        if gUOMCodes.Count() = 0 then begin
            Message(NoUOMLbl);
            exit;
        end;
        if gGenProdPostingGroups.Count() = 0 then begin
            Message(NoGenProdLbl);
            exit;
        end;
        if gVATProdPostingGroups.Count() = 0 then begin
            Message(NoVATProdLbl);
            exit;
        end;
        if gResourceGroupNos.Count() = 0 then begin
            Message(NoResGroupLbl);
            exit;
        end;

        EnsureResourceNoSeriesAllowsManualNos();
        InitNameArrays();
        Clear(gForemanNos);
        gPoolSeq := 0;
        gMemberSeq := 0;
        gExternalSeq := 0;
        // Reset round-robin cursors so repeated runs in the same session (SingleInstance
        // codeunit) start from the same rotation instead of drifting further each time.
        gVendorIdx := 0;
        gSkillIdx := 0;
        gUOMIdx := 0;
        gGenProdIdx := 0;
        gVATProdIdx := 0;
        gResGroupIdx := 0;
        ResourcesTotal := 3 * (75 + 75 * 150 + 250);

        if GuiAllowed() then
            Window.Open(ProgressLbl);
        for Iteration := 1 to 3 do
            CreateResourceIterationBatch(Window, ResourcesCreated, ResourcesTotal);
        if GuiAllowed() then
            Window.Close();

        AssignForemanTree();
    end;

    local procedure LoadReferenceData()
    var
        Vendor: Record Vendor;
        SkillCode: Record "Skill Code";
        UOM: Record "Unit of Measure";
        GenProdPostingGroup: Record "Gen. Product Posting Group";
        VATProdPostingGroup: Record "VAT Product Posting Group";
        ResourceGroup: Record "Resource Group";
    begin
        Clear(gVendorNos);
        Vendor.SetLoadFields("No.");
        if Vendor.FindSet() then
            repeat
                gVendorNos.Add(Vendor."No.");
            until Vendor.Next() = 0;

        Clear(gSkillCodes);
        SkillCode.SetLoadFields(Code);
        if SkillCode.FindSet() then
            repeat
                gSkillCodes.Add(SkillCode.Code);
            until SkillCode.Next() = 0;

        Clear(gUOMCodes);
        UOM.SetLoadFields(Code);
        if UOM.FindSet() then
            repeat
                gUOMCodes.Add(UOM.Code);
            until UOM.Next() = 0;

        Clear(gGenProdPostingGroups);
        GenProdPostingGroup.SetLoadFields(Code);
        if GenProdPostingGroup.FindSet() then
            repeat
                gGenProdPostingGroups.Add(GenProdPostingGroup.Code);
            until GenProdPostingGroup.Next() = 0;

        Clear(gVATProdPostingGroups);
        VATProdPostingGroup.SetLoadFields(Code);
        if VATProdPostingGroup.FindSet() then
            repeat
                gVATProdPostingGroups.Add(VATProdPostingGroup.Code);
            until VATProdPostingGroup.Next() = 0;

        Clear(gResourceGroupNos);
        ResourceGroup.SetLoadFields("No.");
        if ResourceGroup.FindSet() then
            repeat
                gResourceGroupNos.Add(ResourceGroup."No.");
            until ResourceGroup.Next() = 0;
    end;

    local procedure EnsureResourceNoSeriesAllowsManualNos()
    var
        ResourcesSetup: Record "Resources Setup";
        NoSeries: Record "No. Series";
    begin
        // Demo resources use fixed DRP/DRM/DRE codes instead of the next series number,
        // so the Resource No. Series (if any) must allow manual entry or Validate("No.", ...) fails.
        if not ResourcesSetup.Get() then
            exit;
        if ResourcesSetup."Resource Nos." = '' then
            exit;
        if not NoSeries.Get(ResourcesSetup."Resource Nos.") then
            exit;
        if not NoSeries."Manual Nos." then begin
            NoSeries."Manual Nos." := true;
            NoSeries.Modify();
        end;
    end;

    local procedure InitNameArrays()
    begin
        gFirstNames[1] := 'James'; gFirstNames[2] := 'Mary'; gFirstNames[3] := 'John'; gFirstNames[4] := 'Patricia';
        gFirstNames[5] := 'Robert'; gFirstNames[6] := 'Jennifer'; gFirstNames[7] := 'Michael'; gFirstNames[8] := 'Linda';
        gFirstNames[9] := 'William'; gFirstNames[10] := 'Elizabeth'; gFirstNames[11] := 'David'; gFirstNames[12] := 'Barbara';
        gFirstNames[13] := 'Richard'; gFirstNames[14] := 'Susan'; gFirstNames[15] := 'Joseph'; gFirstNames[16] := 'Jessica';
        gFirstNames[17] := 'Thomas'; gFirstNames[18] := 'Sarah'; gFirstNames[19] := 'Charles'; gFirstNames[20] := 'Karen';

        gLastNames[1] := 'Smith'; gLastNames[2] := 'Johnson'; gLastNames[3] := 'Williams'; gLastNames[4] := 'Brown';
        gLastNames[5] := 'Jones'; gLastNames[6] := 'Garcia'; gLastNames[7] := 'Miller'; gLastNames[8] := 'Davis';
        gLastNames[9] := 'Rodriguez'; gLastNames[10] := 'Martinez'; gLastNames[11] := 'Hernandez'; gLastNames[12] := 'Lopez';
        gLastNames[13] := 'Gonzalez'; gLastNames[14] := 'Wilson'; gLastNames[15] := 'Anderson'; gLastNames[16] := 'Thomas';
        gLastNames[17] := 'Taylor'; gLastNames[18] := 'Moore'; gLastNames[19] := 'Jackson'; gLastNames[20] := 'Martin';
    end;

    local procedure CreateResourceIterationBatch(var Window: Dialog; var ResourcesCreated: Integer; ResourcesTotal: Integer)
    var
        p: Integer;
        m: Integer;
        e: Integer;
        PoolNo: Code[20];
    begin
        for p := 1 to 75 do begin
            PoolNo := CreatePoolResource();
            gForemanNos.Add(PoolNo);
            for m := 1 to 150 do
                CreateMemberResource(PoolNo);
            ResourcesCreated += 151;
            if GuiAllowed() then begin
                Window.Update(1, ResourcesCreated);
                Window.Update(2, ResourcesTotal);
            end;
            // Commit after each pool group (~151 records) so this ~35,000-record run doesn't
            // hold one long transaction/lock for its whole duration.
            Commit();
        end;
        for e := 1 to 250 do begin
            CreateExternalResource();
            ResourcesCreated += 1;
            if e mod 50 = 0 then
                Commit();
        end;
        if GuiAllowed() then begin
            Window.Update(1, ResourcesCreated);
            Window.Update(2, ResourcesTotal);
        end;
    end;

    local procedure CreatePoolResource() ResNo: Code[20]
    var
        Res: Record Resource;
    begin
        gPoolSeq += 1;
        ResNo := 'DRP' + Format(gPoolSeq, 0, '<Integer,3><Filler Character,0>');
        Res.Init();
        Res.Validate("No.", ResNo);
        Res.Type := Res.Type::Person;
        Res.Validate(Name, GetRandomName());
        Res."Vendor No." := GetNextVendor();
        Res."Pool Resource No." := ResNo;
        Res."Is Pool" := true;
        Res."Is Pool Member" := false;
        Res."Is External" := false;
        SetMandatoryResourceFields(Res);
        Res.Insert(true);
        LogRecord(Database::Resource, Res.RecordId(), ResNo + ' ' + Res.Name);
        AssignResourceSkill(ResNo);
    end;

    local procedure CreateMemberResource(PoolNo: Code[20])
    var
        Res: Record Resource;
        ResNo: Code[20];
    begin
        gMemberSeq += 1;
        ResNo := 'DRM' + Format(gMemberSeq, 0, '<Integer,5><Filler Character,0>');
        Res.Init();
        Res.Validate("No.", ResNo);
        Res.Type := Res.Type::Person;
        Res.Validate(Name, GetRandomName());
        Res."Pool Resource No." := PoolNo;
        Res."Is Pool Member" := true;
        Res."Is Pool" := false;
        Res."Is External" := false;
        SetMandatoryResourceFields(Res);
        Res.Insert(true);
        LogRecord(Database::Resource, Res.RecordId(), ResNo + ' ' + Res.Name);
        AssignResourceSkill(ResNo);
    end;

    local procedure CreateExternalResource()
    var
        Res: Record Resource;
        ResNo: Code[20];
    begin
        gExternalSeq += 1;
        ResNo := 'DRE' + Format(gExternalSeq, 0, '<Integer,3><Filler Character,0>');
        Res.Init();
        Res.Validate("No.", ResNo);
        Res.Type := Res.Type::Person;
        Res.Validate(Name, GetRandomName());
        Res."Vendor No." := GetNextVendor();
        Res."Pool Resource No." := '';
        Res."Is Pool" := false;
        Res."Is Pool Member" := false;
        Res."Is External" := true;
        SetMandatoryResourceFields(Res);
        Res.Insert(true);
        LogRecord(Database::Resource, Res.RecordId(), ResNo + ' ' + Res.Name);
        AssignResourceSkill(ResNo);
    end;

    local procedure SetMandatoryResourceFields(var Res: Record Resource)
    begin
        Res."Base Unit of Measure" := GetNextUOM();
        Res."Gen. Prod. Posting Group" := GetNextGenProdPostingGroup();
        Res."VAT Prod. Posting Group" := GetNextVATProdPostingGroup();
        Res."Resource Group No." := GetNextResourceGroup();
        Res."Work Hour Template" := gWorkHoursTemplate.Code;
        if (not Res."Is Pool") and (not Res."Is External") then
            // ~60% Mandatory Schedulling = true, ~40% = false
            Res."Mandatory Schedulling" := (Random(100) <= 60);
    end;

    local procedure AssignResourceSkill(ResNo: Code[20])
    var
        ResSkill: Record "Resource Skill";
    begin
        ResSkill.Init();
        ResSkill.Type := ResSkill.Type::Resource;
        ResSkill."No." := ResNo;
        ResSkill."Skill Code" := GetNextSkill();
        ResSkill.Insert(true);
        LogRecord(Database::"Resource Skill", ResSkill.RecordId(), ResNo + ' skill ' + ResSkill."Skill Code");
    end;

    local procedure AssignForemanTree()
    var
        Res: Record Resource;
        Member: Record Resource;
        MemberForemanNos: List of [Code[20]];
        ForemanNo: Code[20];
        Idx: Integer;
    begin
        // Foreman tier: a Pool resource ("Is Pool" = true) is a vendor/grouping placeholder,
        // not a real worker, so it must never be the foreman. The first member of each pool
        // becomes that pool's foreman instead, and the remaining members report to that member.
        Res.SetFilter("No.", 'DRP*');
        if Res.FindSet() then
            repeat
                Member.Reset();
                Member.SetRange("Pool Resource No.", Res."No.");
                Member.SetFilter("No.", '<>%1', Res."No.");
                if Member.FindFirst() then begin
                    ForemanNo := Member."No.";
                    Member."Is Foreman" := true;
                    Member.Modify();
                    MemberForemanNos.Add(ForemanNo);

                    Member.Reset();
                    Member.SetRange("Pool Resource No.", Res."No.");
                    Member.SetFilter("No.", '<>%1&<>%2', Res."No.", ForemanNo);
                    if Member.FindSet(true) then
                        repeat
                            Member."Default Foreman" := ForemanNo;
                            Member.Modify();
                            Idx += 1;
                            if Idx mod 1000 = 0 then
                                Commit();
                        until Member.Next() = 0;
                end;
            until Res.Next() = 0;

        // External resources have no pool, so distribute them round-robin across all foremen.
        Idx := 0;
        Res.Reset();
        Res.SetFilter("No.", 'DRE*');
        if Res.FindSet(true) then
            repeat
                Idx += 1;
                if MemberForemanNos.Count() > 0 then
                    Res."Default Foreman" := MemberForemanNos.Get(((Idx - 1) mod MemberForemanNos.Count()) + 1);
                Res.Modify();
                if Idx mod 1000 = 0 then
                    Commit();
            until Res.Next() = 0;
    end;

    local procedure GetNextVendor(): Code[20]
    begin
        if gVendorNos.Count() = 0 then
            exit('');
        gVendorIdx += 1;
        exit(gVendorNos.Get(((gVendorIdx - 1) mod gVendorNos.Count()) + 1));
    end;

    local procedure GetNextSkill(): Code[10]
    begin
        if gSkillCodes.Count() = 0 then
            exit('');
        gSkillIdx += 1;
        exit(gSkillCodes.Get(((gSkillIdx - 1) mod gSkillCodes.Count()) + 1));
    end;

    local procedure GetNextUOM(): Code[10]
    begin
        if gUOMCodes.Count() = 0 then
            exit('');
        gUOMIdx += 1;
        exit(gUOMCodes.Get(((gUOMIdx - 1) mod gUOMCodes.Count()) + 1));
    end;

    local procedure GetNextGenProdPostingGroup(): Code[20]
    begin
        if gGenProdPostingGroups.Count() = 0 then
            exit('');
        gGenProdIdx += 1;
        exit(gGenProdPostingGroups.Get(((gGenProdIdx - 1) mod gGenProdPostingGroups.Count()) + 1));
    end;

    local procedure GetNextVATProdPostingGroup(): Code[20]
    begin
        if gVATProdPostingGroups.Count() = 0 then
            exit('');
        gVATProdIdx += 1;
        exit(gVATProdPostingGroups.Get(((gVATProdIdx - 1) mod gVATProdPostingGroups.Count()) + 1));
    end;

    local procedure GetNextResourceGroup(): Code[20]
    begin
        if gResourceGroupNos.Count() = 0 then
            exit('');
        gResGroupIdx += 1;
        exit(gResourceGroupNos.Get(((gResGroupIdx - 1) mod gResourceGroupNos.Count()) + 1));
    end;

    local procedure GetRandomName(): Text[100]
    begin
        exit(gFirstNames[Random(ArrayLen(gFirstNames))] + ' ' + gLastNames[Random(ArrayLen(gLastNames))]);
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
        BulkIdx: Integer;
        LeaderRes: Code[20];
        MemberRes: Code[20];
    begin
        if gResCount = 0 then exit;

        // Ensure all loaded resources have capacity across the full demo period
        for i := 1 to gResCount do
            CreateResourceCapacity(gRes[i]);

        CreateDemoResourceCapacity();

        // Each job gets a dedicated leader (odd slot) and member (even slot);
        // wrap-around ensures this works with as few as 1 resource.
        BuildDayPlanningsForJob('JOB001', GetRes(1), GetRes(2));
        BuildDayPlanningsForJob('JOB002', GetRes(3), GetRes(4));
        BuildDayPlanningsForJob('JOB003', GetRes(5), GetRes(6));

        // Bulk jobs draw leader/member from the pool of ~225 demo Foreman resources instead of
        // the tiny 6-slot gRes array: 170 jobs sharing only 6 resources would blow straight
        // through the per-resource-per-day cap below and end up with almost no Day Planning
        // at all once those 6 resources' daily slots are exhausted.
        for BulkIdx := 1 to gBulkJobNos.Count() do begin
            GetBulkJobResources(BulkIdx, LeaderRes, MemberRes);
            BuildDayPlanningsForJob(gBulkJobNos.Get(BulkIdx), LeaderRes, MemberRes);
            // Commit periodically: 170 bulk jobs x ~186 posting tasks each can generate a very
            // large number of Day Planning rows, so this must not run as one giant transaction.
            if BulkIdx mod 10 = 0 then
                Commit();
        end;
    end;

    local procedure GetBulkJobResources(BulkIdx: Integer; var LeaderRes: Code[20]; var MemberRes: Code[20])
    var
        Member: Record Resource;
    begin
        if gForemanNos.Count() = 0 then begin
            // Fallback if resource generation was skipped (e.g. missing master data)
            LeaderRes := GetRes(2 * BulkIdx + 5);
            MemberRes := GetRes(2 * BulkIdx + 6);
            exit;
        end;
        LeaderRes := gForemanNos.Get(((BulkIdx - 1) mod gForemanNos.Count()) + 1);
        Member.SetRange("Pool Resource No.", LeaderRes);
        Member.SetFilter("No.", '<>%1', LeaderRes);
        if Member.FindFirst() then
            MemberRes := Member."No."
        else
            MemberRes := '';
    end;

    local procedure TryReserveResourceDaySlot(ResNo: Code[20]; TaskDate: Date): Boolean
    var
        SlotKey: Text;
        UsedCount: Integer;
    begin
        // Hard cap: a resource can have at most 3 Day Planning lines on a single date
        // (3 x 8h = 24h/day). Tracked in-memory across the whole run since every Day
        // Planning row for this run's resources is created by this codeunit.
        if ResNo = '' then
            exit(false);
        SlotKey := ResNo + '|' + Format(TaskDate, 0, 9);
        if gResDaySlotUsed.ContainsKey(SlotKey) then
            UsedCount := gResDaySlotUsed.Get(SlotKey)
        else
            UsedCount := 0;
        if UsedCount >= 3 then
            exit(false);
        gResDaySlotUsed.Set(SlotKey, UsedCount + 1);
        exit(true);
    end;

    local procedure ForceReserveResourceDaySlot(ResNo: Code[20]; TaskDate: Date)
    var
        SlotKey: Text;
        UsedCount: Integer;
    begin
        // Used only for the "at least one Day Planning per week" guarantee: still records the
        // usage (for bookkeeping/consistency) but never refuses, since the weekly guarantee
        // takes priority over the per-day cap in the rare case a resource is fully saturated.
        if ResNo = '' then
            exit;
        SlotKey := ResNo + '|' + Format(TaskDate, 0, 9);
        if gResDaySlotUsed.ContainsKey(SlotKey) then
            UsedCount := gResDaySlotUsed.Get(SlotKey)
        else
            UsedCount := 0;
        gResDaySlotUsed.Set(SlotKey, UsedCount + 1);
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
        // Direct insert, no CalcFields(Capacity) check: this is only called for the small
        // gRes[1..6] set, so the cost of that check was never the bottleneck. Still logged via
        // LogRecord so DeleteDemoData can clean these rows up on the next run — unlike the
        // ~34,000-resource bulk path (CreateDemoResourceCapacity), these resources aren't
        // matched by a No. prefix, so there's no other way to safely remove them on a rerun.
        for DT := gStartDate to gEndDate do
            if IsWorkingDay(DT) then begin
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

    local procedure CreateDemoResourceCapacity()
    var
        Res: Record Resource;
        ResCap: Record "Res. Capacity Entry";
        Window: Dialog;
        ProgressLbl: Label 'Creating demo resource capacity...\n#1########## of #2##########';
        DT: Date;
        EntryNo: Integer;
        Idx: Integer;
        Total: Integer;
    begin
        // Pool leaders (DRP*) and members (DRM*) are the resources actually used for Day
        // Planning assignment, so they need capacity like any other planned resource. External
        // resources (DRE*) are vendor-linked and are not capacity-planned the same way.
        Res.SetFilter("No.", 'DRP*|DRM*');
        Total := Res.Count();
        if Total = 0 then exit;

        // Unlike CreateResourceCapacity (shared with the small pre-existing gRes[1..6] set),
        // these resources were all just created earlier in this same run, so they are
        // guaranteed to have zero existing capacity. Skip the per-day CalcFields(Capacity)
        // check and per-row LogRecord call — at ~34,000 resources x ~550 working days, both
        // turn into tens of millions of extra queries/inserts and make this step extremely
        // slow. Cleanup is handled in bulk by DeleteDemoData via the DRP/DRM No. prefix instead.
        ResCap.Reset();
        if ResCap.FindLast() then
            EntryNo := ResCap."Entry No." + 1
        else
            EntryNo := 1;

        if GuiAllowed() then
            Window.Open(ProgressLbl);
        if Res.FindSet() then
            repeat
                Idx += 1;
                for DT := gStartDate to gEndDate do
                    if IsWorkingDay(DT) then begin
                        ResCap.Init();
                        ResCap."Entry No." := EntryNo;
                        ResCap."Resource No." := Res."No.";
                        ResCap.Date := DT;
                        ResCap.Capacity := 8;
                        ResCap."Resource Group No." := Res."Resource Group No.";
                        ResCap."Start Time" := 080000T;
                        ResCap."End Time" := 160000T;
                        ResCap.Insert();
                        EntryNo += 1;
                    end;
                if GuiAllowed() then begin
                    Window.Update(1, Idx);
                    Window.Update(2, Total);
                end;
                // Each resource can add up to ~550 capacity rows (one per working day across the
                // ~110-week demo window), so commit after every resource to avoid one huge
                // multi-million-row transaction across ~34,000 resources.
                Commit();
            until Res.Next() = 0;
        if GuiAllowed() then
            Window.Close();
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
        DT: Date;
        WeekStart: Date;
        WeekEnd: Date;
        TaskStart: Date;
        TaskEnd: Date;
        ResGrpLeader: Code[20];
        ResGrpMember: Code[20];
        WeekHasDP: Boolean;
        FirstWorkingDayOfWeek: Date;
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

        WeekStart := TaskStart;
        while WeekStart <= TaskEnd do begin
            WeekEnd := CalcDate('+6D', WeekStart);
            if WeekEnd > TaskEnd then
                WeekEnd := TaskEnd;

            WeekHasDP := false;
            FirstWorkingDayOfWeek := 0D;

            for DT := WeekStart to WeekEnd do begin
                if not IsWorkingDay(DT) then continue;
                if FirstWorkingDayOfWeek = 0D then
                    FirstWorkingDayOfWeek := DT;

                // ── Leader line (every working day, max 3 Day Planning lines/resource/day) ──
                if LeaderRes <> '' then
                    if TryReserveResourceDaySlot(LeaderRes, DT) then begin
                        InsertLeaderDayPlanning(JT, LeaderRes, DT, ResGrpLeader, '');
                        WeekHasDP := true;
                    end;

                // ── Member line (every other working day, only if member differs from leader,
                // max 3 Day Planning lines/resource/day) ────────────────────────────────────
                if (MemberRes <> '') and (MemberRes <> LeaderRes) and IsEvenDayOfMonth(DT) then
                    if TryReserveResourceDaySlot(MemberRes, DT) then begin
                        InsertMemberDayPlanning(JT, LeaderRes, MemberRes, DT, ResGrpMember, '');
                        WeekHasDP := true;
                    end;
            end;

            // Guarantee: every posting task gets at least one Day Planning line per week —
            // even "In Request"/"In Progress" ones — regardless of the per-resource-per-day cap.
            // Without this, heavily overlapping tasks (many phases sharing the same leader
            // resource) could saturate that resource's daily slots and leave whole weeks (or
            // whole tasks) with zero Day Planning lines at all.
            if (not WeekHasDP) and (LeaderRes <> '') and (FirstWorkingDayOfWeek <> 0D) then begin
                ForceReserveResourceDaySlot(LeaderRes, FirstWorkingDayOfWeek);
                InsertLeaderDayPlanning(JT, LeaderRes, FirstWorkingDayOfWeek, ResGrpLeader, ' (guaranteed)');
            end;

            WeekStart := CalcDate('+7D', WeekStart);
        end;
    end;

    local procedure InsertLeaderDayPlanning(JT: Record "Job Task"; LeaderRes: Code[20]; DT: Date; ResGrpLeader: Code[20]; DescSuffix: Text)
    var
        DP: Record "Day Planning";
        PlanSt: Enum "Plan Status";
        ReqStart: Time;
        ReqEnd: Time;
        AsgnStart: Time;
        AsgnEnd: Time;
        ReqHours: Decimal;
        AsgnHours: Decimal;
    begin
        PlanSt := CalcPlanStatus(DT);
        GetTimeSlot(DT, ReqStart, ReqEnd, AsgnStart, AsgnEnd);
        ReqHours := (ReqEnd - ReqStart) / 3600000;
        AsgnHours := (AsgnEnd - AsgnStart) / 3600000;

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
        DP.Description := 'Leader: ' + JT."Job No." + '-' + JT."Job Task No." + DescSuffix;
        DP.Skill := GetResourceSkill(LeaderRes);
        if PlanSt <> "Plan Status"::"In Request" then begin
            DP."Assigned Resource No." := LeaderRes;
            DP."Resource Group No." := ResGrpLeader;
            DP."Start Time Assigned" := AsgnStart;
            DP."End Time Assigned" := AsgnEnd;
            DP."Assigned Hours" := AsgnHours;
        end;
        DP."Pool Resource No." := GetResourcePoolNo(DP);
        DP.Insert(false);
        LogRecord(Database::"Day Planning", DP.RecordId(), JT."Job No." + '.' + JT."Job Task No." + ' ' + Format(DT) + ' L' + DescSuffix);
    end;

    local procedure InsertMemberDayPlanning(JT: Record "Job Task"; LeaderRes: Code[20]; MemberRes: Code[20]; DT: Date; ResGrpMember: Code[20]; DescSuffix: Text)
    var
        DP: Record "Day Planning";
        PlanSt: Enum "Plan Status";
        ReqStart: Time;
        ReqEnd: Time;
        AsgnStart: Time;
        AsgnEnd: Time;
        ReqHours: Decimal;
        AsgnHours: Decimal;
    begin
        PlanSt := CalcPlanStatus(DT);
        GetTimeSlot(DT, ReqStart, ReqEnd, AsgnStart, AsgnEnd);
        ReqHours := (ReqEnd - ReqStart) / 3600000;
        AsgnHours := (AsgnEnd - AsgnStart) / 3600000;

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
        DP.Description := 'Member: ' + JT."Job No." + '-' + JT."Job Task No." + DescSuffix;
        DP.Skill := GetResourceSkill(MemberRes);
        if PlanSt <> "Plan Status"::"In Request" then begin
            DP."Assigned Resource No." := MemberRes;
            DP."Resource Group No." := ResGrpMember;
            DP."Start Time Assigned" := AsgnStart;
            DP."End Time Assigned" := AsgnEnd;
            DP."Assigned Hours" := AsgnHours;
        end;
        DP."Pool Resource No." := GetResourcePoolNo(DP);
        DP.Insert(false);
        LogRecord(Database::"Day Planning", DP.RecordId(), JT."Job No." + '.' + JT."Job Task No." + ' ' + Format(DT) + ' M' + DescSuffix);
    end;

    local procedure GetResourceSkill(ResNo: Code[20]): Code[10]
    var
        ResSkill: Record "Resource Skill";
        SkillCode: Code[10];
    begin
        // Memoized: Day Planning generation calls this once per line (potentially hundreds of
        // thousands of times), so cache each resource's skill after the first DB lookup.
        if ResNo = '' then
            exit('');
        if gResourceSkillCache.ContainsKey(ResNo) then
            exit(gResourceSkillCache.Get(ResNo));

        ResSkill.SetRange(Type, ResSkill.Type::Resource);
        ResSkill.SetRange("No.", ResNo);
        if ResSkill.FindFirst() then
            SkillCode := ResSkill."Skill Code"
        else
            SkillCode := '';

        gResourceSkillCache.Set(ResNo, SkillCode);
        exit(SkillCode);
    end;

    local procedure GetResourcePoolNo(DP: Record "Day Planning"): Code[20]
    var
        Res: Record Resource;
        ResNo: Code[20];
        PoolResNo: Code[20];
    begin
        // Assigned Resource No. is more dominant than Requested Resource No.
        if DP."Assigned Resource No." <> '' then
            ResNo := DP."Assigned Resource No."
        else
            ResNo := DP."Requested Resource No.";
        if ResNo = '' then
            exit('');

        // Memoized: Day Planning generation calls this once per line (potentially hundreds of
        // thousands of times), so cache each resource's pool after the first DB lookup.
        if gResourcePoolCache.ContainsKey(ResNo) then
            exit(gResourcePoolCache.Get(ResNo));

        if Res.Get(ResNo) then
            PoolResNo := Res."Pool Resource No."
        else
            PoolResNo := '';

        gResourcePoolCache.Set(ResNo, PoolResNo);
        exit(PoolResNo);
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
