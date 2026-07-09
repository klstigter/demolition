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
        LoadResources();
        CreateDemoResources();
        // Fallback: if the company started with zero pre-existing resources, the first
        // LoadResources() call above found nothing (gResCount stayed 0). Re-scan now that
        // CreateDemoResources() has populated 200 demo resources, so GetRes() still has a pool
        // to draw from instead of returning '' everywhere (JOB001-003, CreateWorkOrderDemoData).
        if gResCount = 0 then
            LoadResources();
        CreateDailyOptimizerSetupDefault();
        CreateCapacityAndDayPlanning();
        CreateGanttChartSetupDefaults();
        CreateWorkOrderDemoData();
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
        gDemoVendorNos: List of [Code[20]];
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
        gDemoVendorIdx: Integer;
        gSkillIdx: Integer;
        gUOMIdx: Integer;
        gGenProdIdx: Integer;
        gVATProdIdx: Integer;
        gResGroupIdx: Integer;
        gPoolSeq: Integer;
        gMemberSeq: Integer;
        gExternalSeq: Integer;
        gFirstNamesList: List of [Text[50]];
        gLastNamesList: List of [Text[50]];
        gNamesLoaded: Boolean;
        gNameCounter: Integer;
        gWorkHourTemplateLoaded: Boolean;
        gBaseCalendar: Record "Base Calendar";
        gCustomizedCalendarChange: Record "Customized Calendar Change";
        gBaseCalendarLoaded: Boolean;
        gJobSiteNames: List of [Text[50]];
        gProjectTypeNames: List of [Text[50]];
        gJobPhaseNames: List of [Text[50]];
        gJobTaskNames: List of [Text[50]];
        gJobNamesLoaded: Boolean;

    // ──────────────────────────────────────────────────────────────────────────
    // Initialization & Cleanup
    // ──────────────────────────────────────────────────────────────────────────

    local procedure Initialize()
    var
        LogEntry: Record "Demo Data Log Entry";
    begin
        GetDemoDateWindow(gStartDate, gEndDate);
        EnsureWorkHourTemplate('BASIS');
        gWorkHoursTemplate.Get('BASIS');
        gWorkHourTemplateLoaded := true;
        LogEntry.Reset();
        if LogEntry.FindLast() then
            gLogEntryNo := LogEntry."Entry No."
        else
            gLogEntryNo := 0;
    end;

    procedure GetDemoDateWindow(var StartDate: Date; var EndDate: Date)
    begin
        // Single source of truth for the demo data date window - reused by the
        // capacity-regeneration repair (RepairDemoResourceCapacityRegenerate in
        // report_50600_RepairDayPlanningResourceGroup.al) so it operates over exactly the same
        // range the generator itself uses, instead of duplicating this formula.
        StartDate := CalcDate('<WD1-1W>', Today());
        // Covers JOB002 (start+1W+52W) and the 170 bulk jobs (max start offset +9W, 98W span) + buffer
        EndDate := CalcDate('+110W', StartDate);
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
        CalendarCode: Code[10];
    begin
        // "Create Demo Data" fully owns and controls this singleton's values every run - always
        // force them to the demo configuration rather than only filling in blanks, so the setup
        // page reliably reflects DEMOCAL/BASIS/ELEKTR/OI/WO immediately after each run regardless
        // of whatever value was left over from a prior run or the page's auto-inserted blank
        // record (page_50654's OnOpenPage silently auto-inserts a blank singleton the first time
        // anyone opens the Daily Optimizer Setup page, before this procedure ever runs).
        CalendarCode := CreateDemoCalendar();
        EnsureWorkHourTemplate('BASIS');
        EnsureSkillCode('ELEKTR', 'Electrician');
        EnsureNoSeries('OI', 'Order Intake');
        EnsureNoSeries('WO', 'Work Order');

        if not Setup.Get() then begin
            Setup.Init();
            Setup.Insert();
        end;

        Setup."Base Calendar" := CalendarCode;
        Setup."Work hour Template" := 'BASIS';
        Setup."Default Skill" := 'ELEKTR';
        Setup."Order Intake Nos" := 'OI';
        Setup."Work Order Nos" := 'WO';
        Setup.Modify();
    end;

    local procedure CreateDemoCalendar(): Code[10]
    var
        BaseCalendar: Record "Base Calendar";
        CalendarCode: Code[10];
    begin
        // Dedicated, clearly-branded demo calendar instead of reusing/creating a generic 'BASIS'
        // code, which risks colliding with whatever calendar setup already exists in the target
        // BC sandbox/company. Logged (unlike the other Ensure* helpers in this file, which are
        // intentionally permanent/unlogged) so DeleteDemoData() removes the previous run's copy
        // and this recreates fresh every run - idempotent insert-or-modify, same shape as
        // CreateDemoVendors/UpsertJob elsewhere in this file.
        CalendarCode := 'DEMOCAL';
        BaseCalendar.Init();
        BaseCalendar.Code := CalendarCode;
        BaseCalendar.Name := 'DEMOPLANNING';
        if not BaseCalendar.Insert() then
            BaseCalendar.Modify();
        LogRecord(Database::"Base Calendar", BaseCalendar.RecordId(), CalendarCode + ' ' + BaseCalendar.Name);
        CreateDemoCalendarChanges(CalendarCode);
        exit(CalendarCode);
    end;

    local procedure CreateDemoCalendarChanges(CalendarCode: Code[10])
    begin
        LoadDutchPublicHolidays(CalendarCode);
        // Custom demo exceptions, relative to the demo date window's start (gStartDate is always
        // a Monday - see GetDemoDateWindow). Repeated at +1 year (Year 2) as explicit dated rows,
        // NOT via "Recurring System" - these are offset from THIS RUN's rolling window start, not
        // a fixed calendar month/day or weekday, so neither Annual nor Weekly Recurring can
        // express "week 2 Tuesday of whatever window this run happens to compute". Nested
        // CalcDate calls (year offset first, then week/day offset) rather than a single combined
        // '+1Y+1W+1D' formula, to keep each individual CalcDate call exactly as simple/proven as
        // the ones already used elsewhere in this file.
        InsertBaseCalendarChange(CalendarCode, CalcDate('+1W+1D', gStartDate), 'Custom Day Off (Wk2 Tue)', CalRecNonRecurring());
        InsertBaseCalendarChange(CalendarCode, CalcDate('+2W+2D', gStartDate), 'Custom Day Off (Wk3 Wed)', CalRecNonRecurring());
        InsertBaseCalendarChange(CalendarCode, CalcDate('+2W+3D', gStartDate), 'Custom Day Off (Wk3 Thu)', CalRecNonRecurring());
        InsertBaseCalendarChange(CalendarCode, CalcDate('+4W', gStartDate), 'Custom Day Off (Wk5 Mon)', CalRecNonRecurring());
        InsertBaseCalendarChange(CalendarCode, CalcDate('+1W+1D', CalcDate('+1Y', gStartDate)), 'Custom Day Off (Wk2 Tue, Yr2)', CalRecNonRecurring());
        InsertBaseCalendarChange(CalendarCode, CalcDate('+2W+2D', CalcDate('+1Y', gStartDate)), 'Custom Day Off (Wk3 Wed, Yr2)', CalRecNonRecurring());
        InsertBaseCalendarChange(CalendarCode, CalcDate('+2W+3D', CalcDate('+1Y', gStartDate)), 'Custom Day Off (Wk3 Thu, Yr2)', CalRecNonRecurring());
        InsertBaseCalendarChange(CalendarCode, CalcDate('+4W', CalcDate('+1Y', gStartDate)), 'Custom Day Off (Wk5 Mon, Yr2)', CalRecNonRecurring());
    end;

    local procedure CalRecNonRecurring(): Integer
    begin
        // "Base Calendar Change"."Recurring System" (Option) values, confirmed by decompiling the
        // actual base-app table source (table 7601, src/Foundation/Calendar/BaseCalendarChange.Table.al):
        // OptionMembers = " ","Annual Recurring","Weekly Recurring" -> 0 = blank/non-recurring,
        // 1 = Annual Recurring, 2 = Weekly Recurring (unused in this codeunit). Exposed as a named
        // helper (rather than a bare 0 literal) so call sites read as intent, matching
        // CalRecAnnualRecurring() below.
        exit(0);
    end;

    local procedure CalRecAnnualRecurring(): Integer
    begin
        exit(1);
    end;

    local procedure LoadDutchPublicHolidays(CalendarCode: Code[10])
    var
        TypeHelper: Codeunit "Type Helper";
        Content: Text;
        Lines: List of [Text];
        Parts: List of [Text];
        Line: Text;
        LineNo: Integer;
        HolidayDate: Date;
        YearInt: Integer;
        MonthInt: Integer;
        DayInt: Integer;
        Desc: Text[30];
        IsRecurring: Boolean;
    begin
        // The CSV covers 2025-2030 for headroom across many future runs, since GetDemoDateWindow
        // is a rolling window relative to Today(). 3rd column ("Recurring", Y/N): N rows (the 6
        // movable-date holidays incl. Koningsdag, which shifts in rare years) only insert if the
        // row's specific date falls inside THIS run's demo window - same as before. Y rows (the 4
        // truly fixed-date holidays: Nieuwjaarsdag/Bevrijdingsdag/Eerste+Tweede Kerstdag) appear
        // just ONCE in the CSV as a single anchor date and insert UNCONDITIONALLY as Annual
        // Recurring, no window filter - they recur every year going forward regardless of which
        // window this particular run computes.
        Content := NavApp.GetResourceAsText('DutchPublicHolidays.csv', TextEncoding::UTF8);
        Lines := Content.Split(TypeHelper.LFSeparator());
        foreach Line in Lines do begin
            LineNo += 1;
            Line := Line.TrimEnd(); // strips any trailing CR left over from CRLF-saved CSVs
            if (LineNo > 1) and (Line <> '') then begin // line 1 is the "Date,Description,Recurring" header row
                Parts := Line.Split(',');
                if Parts.Count() >= 3 then begin
                    // Parse YYYY-MM-DD manually via DMY2Date rather than Evaluate(Date, ...),
                    // which depends on the session's regional date format and could misparse -
                    // this CSV's format is fixed, so parsing it explicitly is unambiguous
                    // regardless of locale.
                    Evaluate(YearInt, CopyStr(Parts.Get(1), 1, 4));
                    Evaluate(MonthInt, CopyStr(Parts.Get(1), 6, 2));
                    Evaluate(DayInt, CopyStr(Parts.Get(1), 9, 2));
                    HolidayDate := DMY2Date(DayInt, MonthInt, YearInt);
                    Desc := CopyStr(Parts.Get(2), 1, 30);
                    IsRecurring := UpperCase(Parts.Get(3)) = 'Y';
                    if IsRecurring then
                        InsertBaseCalendarChange(CalendarCode, HolidayDate, Desc, CalRecAnnualRecurring())
                    else
                        if (HolidayDate >= gStartDate) and (HolidayDate <= gEndDate) then
                            InsertBaseCalendarChange(CalendarCode, HolidayDate, Desc, CalRecNonRecurring());
                end;
            end;
        end;
    end;

    local procedure InsertBaseCalendarChange(CalendarCode: Code[10]; ChangeDate: Date; Desc: Text[30]; RecurringSystem: Integer)
    var
        BaseCalendarChange: Record "Base Calendar Change";
    begin
        // Idempotent Get-then-Insert, logged like everything else so DeleteDemoData() cleans
        // these up and they're recreated fresh every run - consistent with how CreateDemoCalendar()
        // itself is already logged. RecurringSystem is passed as Integer (not the table's own
        // Option type - AL doesn't let an anonymous/foreign Option type cross a procedure
        // boundary the way Enums do) and assigned directly into the Option field, which AL
        // permits without an explicit cast. Day is left at its default (0/blank) - only relevant
        // for Weekly Recurring, not used by this codeunit (see CalRecNonRecurring/CalRecAnnualRecurring).
        if BaseCalendarChange.Get(CalendarCode, RecurringSystem, ChangeDate, 0) then
            exit;
        BaseCalendarChange.Init();
        BaseCalendarChange."Base Calendar Code" := CalendarCode;
        BaseCalendarChange."Recurring System" := RecurringSystem;
        BaseCalendarChange.Date := ChangeDate;
        BaseCalendarChange.Nonworking := true;
        BaseCalendarChange.Description := Desc;
        BaseCalendarChange.Insert();
        LogRecord(Database::"Base Calendar Change", BaseCalendarChange.RecordId(), CalendarCode + ' ' + Format(ChangeDate) + ' ' + Desc);
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
        // 07:00-16:00 with a 1-hour break = 8 working hours/day, matching the Monday..Friday
        // hour counts above. Set directly rather than via Validate() to avoid the
        // "Non Working Minutes" OnValidate (tableextension 50620) zeroing itself back out when
        // "Default End Time" isn't set yet at the point it fires.
        WorkHourTemplate."Default Start Time" := 070000T;
        WorkHourTemplate."Default End Time" := 160000T;
        WorkHourTemplate."Non Working Minutes" := 60;
        WorkHourTemplate."Working Hours" := 8;
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
        AddTask(JT, '0', 'Radome Repair Project', D, CalcDate('+40W', D), JT."Job Task Type"::Heading);

        AddTask(JT, '1000', 'Phase 1: Pre-Processing', D, CalcDate('+9W', D), JT."Job Task Type"::"Begin-Total");
        AddTask(JT, '1010', 'Inbound Receiving & Logging', D, CalcDate('+3W', D), JT."Job Task Type"::Posting);   // 3W
        AddTask(JT, '1020', 'Condition Assessment', CalcDate('+2W', D), CalcDate('+5W', D), JT."Job Task Type"::Posting);   // 3W
        AddTask(JT, '1030', 'Quote Preparation', CalcDate('+4W', D), CalcDate('+7W', D), JT."Job Task Type"::Posting);   // 3W
        AddTask(JT, '1040', 'Customer Approval', CalcDate('+6W', D), CalcDate('+9W', D), JT."Job Task Type"::Posting);   // 3W
        AddTask(JT, '1999', 'Phase 1 Total', D, CalcDate('+9W', D), JT."Job Task Type"::"End-Total");

        AddTask(JT, '2000', 'Phase 2: Disassembly & Procurement', CalcDate('+9W', D), CalcDate('+21W', D), JT."Job Task Type"::"Begin-Total");
        AddTask(JT, '2010', 'Component Disassembly', CalcDate('+9W', D), CalcDate('+12W', D), JT."Job Task Type"::Posting);   // 3W
        AddTask(JT, '2020', 'Damage Mapping & Analysis', CalcDate('+10W', D), CalcDate('+14W', D), JT."Job Task Type"::Posting);   // 4W
        AddTask(JT, '2030', 'Spare Parts Identification', CalcDate('+12W', D), CalcDate('+15W', D), JT."Job Task Type"::Posting);   // 3W
        AddTask(JT, '2040', 'Parts Procurement', CalcDate('+14W', D), CalcDate('+18W', D), JT."Job Task Type"::Posting);   // 4W
        AddTask(JT, '2050', 'Procurement Follow-up', CalcDate('+16W', D), CalcDate('+21W', D), JT."Job Task Type"::Posting);   // 5W
        AddTask(JT, '2999', 'Phase 2 Total', CalcDate('+9W', D), CalcDate('+21W', D), JT."Job Task Type"::"End-Total");

        AddTask(JT, '3000', 'Phase 3: Repair & Assembly', CalcDate('+21W', D), CalcDate('+33W', D), JT."Job Task Type"::"Begin-Total");
        AddTask(JT, '3010', 'Surface Preparation', CalcDate('+21W', D), CalcDate('+24W', D), JT."Job Task Type"::Posting);   // 3W
        AddTask(JT, '3020', 'Structural Repair', CalcDate('+23W', D), CalcDate('+27W', D), JT."Job Task Type"::Posting);   // 4W
        AddTask(JT, '3030', 'Paint & Coating Application', CalcDate('+26W', D), CalcDate('+29W', D), JT."Job Task Type"::Posting);   // 3W
        AddTask(JT, '3040', 'Component Assembly', CalcDate('+28W', D), CalcDate('+31W', D), JT."Job Task Type"::Posting);   // 3W
        AddTask(JT, '3050', 'Electrical Fit-out', CalcDate('+30W', D), CalcDate('+33W', D), JT."Job Task Type"::Posting);   // 3W
        AddTask(JT, '3999', 'Phase 3 Total', CalcDate('+21W', D), CalcDate('+33W', D), JT."Job Task Type"::"End-Total");

        AddTask(JT, '4000', 'Phase 4: Testing & Delivery', CalcDate('+33W', D), CalcDate('+40W', D), JT."Job Task Type"::"Begin-Total");
        AddTask(JT, '4010', 'Functional Testing', CalcDate('+33W', D), CalcDate('+36W', D), JT."Job Task Type"::Posting);   // 3W
        AddTask(JT, '4020', 'RF Performance Test', CalcDate('+35W', D), CalcDate('+38W', D), JT."Job Task Type"::Posting);   // 3W
        AddTask(JT, '4030', 'Certification & Documentation', CalcDate('+36W', D), CalcDate('+39W', D), JT."Job Task Type"::Posting);   // 3W
        AddTask(JT, '4040', 'Outbound Packing', CalcDate('+37W', D), CalcDate('+40W', D), JT."Job Task Type"::Posting);   // 3W
        AddTask(JT, '4050', 'Customer Delivery', CalcDate('+38W', D), CalcDate('+40W', D), JT."Job Task Type"::Posting);   // 2W (final hand-off, overlap with packing)
        AddTask(JT, '4999', 'Phase 4 Total', CalcDate('+33W', D), CalcDate('+40W', D), JT."Job Task Type"::"End-Total");

        AddTask(JT, '9999', 'Radome Repair Project Total', D, CalcDate('+40W', D), JT."Job Task Type"::Total);

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
        AddTask(JT, '0', 'ERP System Implementation', D, CalcDate('+52W', D), JT."Job Task Type"::Heading);

        AddTask(JT, '1000', 'Phase 1: Project Initiation', D, CalcDate('+9W', D), JT."Job Task Type"::"Begin-Total");
        AddTask(JT, '1010', 'Stakeholder Kickoff Meeting', D, CalcDate('+3W', D), JT."Job Task Type"::Posting);   // 3W
        AddTask(JT, '1020', 'Requirements Workshop', CalcDate('+2W', D), CalcDate('+6W', D), JT."Job Task Type"::Posting);   // 4W
        AddTask(JT, '1030', 'As-Is Process Mapping', CalcDate('+5W', D), CalcDate('+8W', D), JT."Job Task Type"::Posting);   // 3W
        AddTask(JT, '1040', 'Gap Analysis & Sign-off', CalcDate('+6W', D), CalcDate('+9W', D), JT."Job Task Type"::Posting);   // 3W
        AddTask(JT, '1999', 'Phase 1 Total', D, CalcDate('+9W', D), JT."Job Task Type"::"End-Total");

        AddTask(JT, '2000', 'Phase 2: Solution Design', CalcDate('+9W', D), CalcDate('+22W', D), JT."Job Task Type"::"Begin-Total");
        AddTask(JT, '2010', 'System Architecture Design', CalcDate('+9W', D), CalcDate('+13W', D), JT."Job Task Type"::Posting);   // 4W
        AddTask(JT, '2020', 'Data Migration Design', CalcDate('+11W', D), CalcDate('+15W', D), JT."Job Task Type"::Posting);   // 4W
        AddTask(JT, '2030', 'Integration Architecture Design', CalcDate('+13W', D), CalcDate('+17W', D), JT."Job Task Type"::Posting);   // 4W
        AddTask(JT, '2040', 'Customization Specification', CalcDate('+16W', D), CalcDate('+22W', D), JT."Job Task Type"::Posting);   // 6W
        AddTask(JT, '2999', 'Phase 2 Total', CalcDate('+9W', D), CalcDate('+22W', D), JT."Job Task Type"::"End-Total");

        AddTask(JT, '3000', 'Phase 3: Build & Configuration', CalcDate('+22W', D), CalcDate('+38W', D), JT."Job Task Type"::"Begin-Total");
        AddTask(JT, '3010', 'Base System Configuration', CalcDate('+22W', D), CalcDate('+25W', D), JT."Job Task Type"::Posting);   // 3W
        AddTask(JT, '3020', 'Custom Development', CalcDate('+23W', D), CalcDate('+31W', D), JT."Job Task Type"::Posting);   // 8W
        AddTask(JT, '3030', 'Integration Development', CalcDate('+26W', D), CalcDate('+33W', D), JT."Job Task Type"::Posting);   // 7W
        AddTask(JT, '3040', 'Data Migration Scripts', CalcDate('+30W', D), CalcDate('+35W', D), JT."Job Task Type"::Posting);   // 5W
        AddTask(JT, '3050', 'Unit & Integration Testing', CalcDate('+34W', D), CalcDate('+38W', D), JT."Job Task Type"::Posting);   // 4W
        AddTask(JT, '3999', 'Phase 3 Total', CalcDate('+22W', D), CalcDate('+38W', D), JT."Job Task Type"::"End-Total");

        AddTask(JT, '4000', 'Phase 4: UAT & Training', CalcDate('+38W', D), CalcDate('+47W', D), JT."Job Task Type"::"Begin-Total");
        AddTask(JT, '4010', 'User Acceptance Testing', CalcDate('+38W', D), CalcDate('+42W', D), JT."Job Task Type"::Posting);   // 4W
        AddTask(JT, '4020', 'Bug Fixing & Retest', CalcDate('+41W', D), CalcDate('+45W', D), JT."Job Task Type"::Posting);   // 4W
        AddTask(JT, '4030', 'End-User Training', CalcDate('+40W', D), CalcDate('+47W', D), JT."Job Task Type"::Posting);   // 7W
        AddTask(JT, '4999', 'Phase 4 Total', CalcDate('+38W', D), CalcDate('+47W', D), JT."Job Task Type"::"End-Total");

        AddTask(JT, '5000', 'Phase 5: Go-Live', CalcDate('+47W', D), CalcDate('+52W', D), JT."Job Task Type"::"Begin-Total");
        AddTask(JT, '5010', 'Data Migration Execution', CalcDate('+47W', D), CalcDate('+50W', D), JT."Job Task Type"::Posting);   // 3W
        AddTask(JT, '5020', 'Go-Live Cutover', CalcDate('+49W', D), CalcDate('+52W', D), JT."Job Task Type"::Posting);   // 3W
        AddTask(JT, '5030', 'Hypercare Support', CalcDate('+50W', D), CalcDate('+52W', D), JT."Job Task Type"::Posting);   // 2W (final sprint, runs parallel to cutover)
        AddTask(JT, '5999', 'Phase 5 Total', CalcDate('+47W', D), CalcDate('+52W', D), JT."Job Task Type"::"End-Total");

        AddTask(JT, '9999', 'ERP Implementation Total', D, CalcDate('+52W', D), JT."Job Task Type"::Total);

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
        AddTask(JT, '0', 'Facility Infrastructure Upgrade', D, CalcDate('+42W', D), JT."Job Task Type"::Heading);

        AddTask(JT, '1000', 'Phase 1: Planning & Survey', D, CalcDate('+9W', D), JT."Job Task Type"::"Begin-Total");
        AddTask(JT, '1010', 'Site Survey & Condition Assessment', D, CalcDate('+3W', D), JT."Job Task Type"::Posting);   // 3W
        AddTask(JT, '1020', 'Technical Feasibility Study', CalcDate('+2W', D), CalcDate('+5W', D), JT."Job Task Type"::Posting);   // 3W
        AddTask(JT, '1030', 'Project Schedule & Budget Planning', CalcDate('+4W', D), CalcDate('+9W', D), JT."Job Task Type"::Posting);   // 5W
        AddTask(JT, '1999', 'Phase 1 Total', D, CalcDate('+9W', D), JT."Job Task Type"::"End-Total");

        AddTask(JT, '2000', 'Phase 2: Procurement & Preparation', CalcDate('+9W', D), CalcDate('+18W', D), JT."Job Task Type"::"Begin-Total");
        AddTask(JT, '2010', 'Vendor Selection & Contracting', CalcDate('+9W', D), CalcDate('+12W', D), JT."Job Task Type"::Posting);   // 3W
        AddTask(JT, '2020', 'Material & Equipment Procurement', CalcDate('+11W', D), CalcDate('+15W', D), JT."Job Task Type"::Posting);   // 4W
        AddTask(JT, '2030', 'Site Preparation & Logistics', CalcDate('+14W', D), CalcDate('+18W', D), JT."Job Task Type"::Posting);   // 4W
        AddTask(JT, '2999', 'Phase 2 Total', CalcDate('+9W', D), CalcDate('+18W', D), JT."Job Task Type"::"End-Total");

        AddTask(JT, '3000', 'Phase 3: Installation & Construction', CalcDate('+18W', D), CalcDate('+31W', D), JT."Job Task Type"::"Begin-Total");
        AddTask(JT, '3010', 'Electrical System Installation', CalcDate('+18W', D), CalcDate('+22W', D), JT."Job Task Type"::Posting);   // 4W
        AddTask(JT, '3020', 'HVAC System Installation', CalcDate('+19W', D), CalcDate('+23W', D), JT."Job Task Type"::Posting);   // 4W
        AddTask(JT, '3030', 'Network & IT Infrastructure', CalcDate('+21W', D), CalcDate('+26W', D), JT."Job Task Type"::Posting);   // 5W
        AddTask(JT, '3040', 'Security & Access Control Systems', CalcDate('+24W', D), CalcDate('+31W', D), JT."Job Task Type"::Posting);   // 7W
        AddTask(JT, '3999', 'Phase 3 Total', CalcDate('+18W', D), CalcDate('+31W', D), JT."Job Task Type"::"End-Total");

        AddTask(JT, '4000', 'Phase 4: Commissioning & Handover', CalcDate('+31W', D), CalcDate('+42W', D), JT."Job Task Type"::"Begin-Total");
        AddTask(JT, '4010', 'System Commissioning & Testing', CalcDate('+31W', D), CalcDate('+34W', D), JT."Job Task Type"::Posting);   // 3W
        AddTask(JT, '4020', 'Integration & Performance Testing', CalcDate('+33W', D), CalcDate('+37W', D), JT."Job Task Type"::Posting);   // 4W
        AddTask(JT, '4030', 'Punch List & Snagging Resolution', CalcDate('+36W', D), CalcDate('+39W', D), JT."Job Task Type"::Posting);   // 3W
        AddTask(JT, '4040', 'Final Inspection & Handover', CalcDate('+38W', D), CalcDate('+42W', D), JT."Job Task Type"::Posting);   // 4W
        AddTask(JT, '4999', 'Phase 4 Total', CalcDate('+31W', D), CalcDate('+42W', D), JT."Job Task Type"::"End-Total");

        AddTask(JT, '9999', 'Infrastructure Upgrade Total', D, CalcDate('+42W', D), JT."Job Task Type"::Total);

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
        CreateLink('JOB001', '1010', '1020', Enum::"BCG Gantt Link Type"::"Finish-Start", 0);
        CreateLink('JOB001', '1020', '1030', Enum::"BCG Gantt Link Type"::"Finish-Start", 1);  // 1-day review buffer
        CreateLink('JOB001', '1030', '1040', Enum::"BCG Gantt Link Type"::"Finish-Start", 0);
        CreateLink('JOB001', '1040', '2010', Enum::"BCG Gantt Link Type"::"Finish-Start", 1);  // approval before disassembly
        CreateLink('JOB001', '2010', '2020', Enum::"BCG Gantt Link Type"::"Finish-Start", 0);
        CreateLink('JOB001', '2010', '2030', Enum::"BCG Gantt Link Type"::"Start-Start", 2);  // parts ID starts 2 days after disassembly begins
        CreateLink('JOB001', '2020', '2040', Enum::"BCG Gantt Link Type"::"Finish-Start", 0);
        CreateLink('JOB001', '2030', '2040', Enum::"BCG Gantt Link Type"::"Finish-Start", 1);
        CreateLink('JOB001', '2040', '2050', Enum::"BCG Gantt Link Type"::"Start-Start", 3);  // follow-up starts 3 days after procurement
        CreateLink('JOB001', '2040', '3010', Enum::"BCG Gantt Link Type"::"Finish-Start", 0);  // parts needed before surface prep
        CreateLink('JOB001', '3010', '3020', Enum::"BCG Gantt Link Type"::"Finish-Start", 0);
        CreateLink('JOB001', '3020', '3030', Enum::"BCG Gantt Link Type"::"Finish-Start", 2);  // paint starts 2 days after repair (cure time)
        CreateLink('JOB001', '3030', '3040', Enum::"BCG Gantt Link Type"::"Finish-Start", 1);
        CreateLink('JOB001', '3040', '3050', Enum::"BCG Gantt Link Type"::"Start-Start", 1);  // electrical overlaps assembly
        CreateLink('JOB001', '3050', '4010', Enum::"BCG Gantt Link Type"::"Finish-Start", 0);
        CreateLink('JOB001', '3040', '4010', Enum::"BCG Gantt Link Type"::"Finish-Finish", 2);  // testing finishes 2 days after assembly complete
        CreateLink('JOB001', '4010', '4020', Enum::"BCG Gantt Link Type"::"Finish-Start", 0);
        CreateLink('JOB001', '4020', '4030', Enum::"BCG Gantt Link Type"::"Finish-Start", 0);
        CreateLink('JOB001', '4030', '4040', Enum::"BCG Gantt Link Type"::"Finish-Start", 1);
        CreateLink('JOB001', '4040', '4050', Enum::"BCG Gantt Link Type"::"Finish-Start", 0);

        // ── JOB002: ERP Implementation — complex dependency fan-out with all four link types
        CreateLink('JOB002', '1010', '1020', Enum::"BCG Gantt Link Type"::"Finish-Start", 0);
        CreateLink('JOB002', '1020', '1030', Enum::"BCG Gantt Link Type"::"Start-Start", 1);  // mapping can start while workshop is in progress
        CreateLink('JOB002', '1030', '1040', Enum::"BCG Gantt Link Type"::"Finish-Start", 0);
        CreateLink('JOB002', '1040', '2010', Enum::"BCG Gantt Link Type"::"Finish-Start", 2);  // 2-day buffer after sign-off
        CreateLink('JOB002', '2010', '2020', Enum::"BCG Gantt Link Type"::"Start-Start", 0);  // data design starts with architecture
        CreateLink('JOB002', '2010', '2030', Enum::"BCG Gantt Link Type"::"Start-Start", 2);
        CreateLink('JOB002', '2010', '2040', Enum::"BCG Gantt Link Type"::"Start-Start", 3);
        CreateLink('JOB002', '2020', '3040', Enum::"BCG Gantt Link Type"::"Finish-Start", 0);  // data design feeds migration scripts
        CreateLink('JOB002', '2030', '3030', Enum::"BCG Gantt Link Type"::"Finish-Start", 0);  // integration design feeds dev
        CreateLink('JOB002', '2040', '3020', Enum::"BCG Gantt Link Type"::"Finish-Start", 1);  // spec feeds custom dev
        CreateLink('JOB002', '3010', '3050', Enum::"BCG Gantt Link Type"::"Finish-Start", 0);
        CreateLink('JOB002', '3020', '3050', Enum::"BCG Gantt Link Type"::"Finish-Finish", 2);  // dev must finish before testing ends
        CreateLink('JOB002', '3030', '3050', Enum::"BCG Gantt Link Type"::"Finish-Finish", 1);
        CreateLink('JOB002', '3050', '4010', Enum::"BCG Gantt Link Type"::"Finish-Start", 1);
        CreateLink('JOB002', '4010', '4020', Enum::"BCG Gantt Link Type"::"Finish-Start", 0);
        CreateLink('JOB002', '4010', '4030', Enum::"BCG Gantt Link Type"::"Start-Start", 2);  // training can begin while UAT runs
        CreateLink('JOB002', '4020', '5010', Enum::"BCG Gantt Link Type"::"Finish-Start", 2);
        CreateLink('JOB002', '5010', '5020', Enum::"BCG Gantt Link Type"::"Finish-Start", 1);
        CreateLink('JOB002', '5020', '5030', Enum::"BCG Gantt Link Type"::"Finish-Start", 0);

        // ── JOB003: Infrastructure Upgrade — parallel installs with Finish-Finish convergence
        CreateLink('JOB003', '1010', '1020', Enum::"BCG Gantt Link Type"::"Finish-Start", 0);
        CreateLink('JOB003', '1010', '1030', Enum::"BCG Gantt Link Type"::"Start-Start", 1);  // planning starts 1 day after survey
        CreateLink('JOB003', '1020', '2010', Enum::"BCG Gantt Link Type"::"Finish-Start", 1);
        CreateLink('JOB003', '2010', '2020', Enum::"BCG Gantt Link Type"::"Finish-Start", 2);
        CreateLink('JOB003', '2020', '2030', Enum::"BCG Gantt Link Type"::"Start-Start", 3);  // site prep overlaps procurement
        CreateLink('JOB003', '2030', '3010', Enum::"BCG Gantt Link Type"::"Finish-Start", 0);
        CreateLink('JOB003', '3010', '3020', Enum::"BCG Gantt Link Type"::"Start-Start", 0);  // HVAC starts with electrical
        CreateLink('JOB003', '3020', '3030', Enum::"BCG Gantt Link Type"::"Start-Start", 2);
        CreateLink('JOB003', '3030', '3040', Enum::"BCG Gantt Link Type"::"Start-Start", 1);
        CreateLink('JOB003', '3010', '4010', Enum::"BCG Gantt Link Type"::"Finish-Finish", 3);  // commissioning can end 3 days after electrical
        CreateLink('JOB003', '3020', '4010', Enum::"BCG Gantt Link Type"::"Finish-Finish", 3);
        CreateLink('JOB003', '3030', '4010', Enum::"BCG Gantt Link Type"::"Finish-Finish", 2);
        CreateLink('JOB003', '3040', '4020', Enum::"BCG Gantt Link Type"::"Finish-Start", 0);
        CreateLink('JOB003', '4010', '4020', Enum::"BCG Gantt Link Type"::"Finish-Start", 0);
        CreateLink('JOB003', '4020', '4030', Enum::"BCG Gantt Link Type"::"Finish-Start", 1);
        CreateLink('JOB003', '4030', '4040', Enum::"BCG Gantt Link Type"::"Finish-Start", 0);
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
    // Bulk Jobs — 170 generated jobs x 30 phased job tasks each (small demo data).
    // Each job: 1 Heading + 4 phases (Begin-Total + 5 Posting + End-Total = 7 tasks) + 1
    // Total = 1 + 4*7 + 1 = 30 tasks, of which 4*5 = 20 are Posting (Project Task) leaves.
    // Job Task Nos. are zero-padded to a uniform 5 digits (e.g. '01000', '01010', '04999') so
    // Code-field text sorting stays numeric order across the full range — mixing 4- and 5-digit
    // codes would sort '10000' before '9999'.
    // ──────────────────────────────────────────────────────────────────────────

    local procedure CreateBulkJobs()
    var
        Customer: Record Customer;
        Window: Dialog;
        Idx: Integer;
        JobNo: Code[20];
        JobName: Text[100];
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
            // Idx - 1 used directly as the sequence number (no new counter needed) keeps this
            // idempotent/stable across reruns - DJB0001 always maps to the same generated name
            // every run, consistent with how UpsertJob treats job numbers as stable identities.
            JobName := GetUniqueDemoJobName(Idx - 1);
            CreateBulkJob(JobNo, JobName, Customer."No.");
            CreateBulkJobTasks(JobNo, JobName, JobStart);
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

    local procedure CreateBulkJob(JobNo: Code[20]; JobName: Text[100]; CustNo: Code[20])
    var
        Job: Record Job;
    begin
        DeleteOrphanJobTaskDimensions(JobNo);
        Job.Init();
        Job.SetHideValidationDialog(true);
        Job."No." := JobNo;
        Job.Description := CopyStr(JobName, 1, MaxStrLen(Job.Description));
        Job.Validate("Sell-to Customer No.", CustNo);
        if not Job.Insert() then
            Job.Modify();
        LogRecord(Database::Job, Job.RecordId(), JobNo + ' - ' + Job.Description);
    end;

    local procedure CreateBulkJobTasks(JobNo: Code[20]; JobName: Text[100]; JobStart: Date)
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
        PhaseCount: Integer;
        TasksPerPhase: Integer;
        PhaseName: Text[100];
    begin
        // Shrunk from 31 phases x 6 posting tasks (186 posting tasks/job) down to 4 phases x 5
        // posting tasks = 20 posting tasks/job, for the small demo dataset. Phase spacing (3 weeks
        // apart) and the 8-week phase window are unchanged - they were already sized to safely
        // contain the widest posting stagger plus the longest posting duration, and that margin
        // still holds here: max stagger (5-1)*2 = 8 days + max duration 6W ≈ 7.1W, still under 8W.
        PhaseCount := 4;
        TasksPerPhase := 5;

        JobEnd := CalcDate(StrSubstNo('+%1W', (PhaseCount - 1) * 3 + 8), JobStart);
        JT."Job No." := JobNo;

        AddTask(JT, '00000', JobName, JobStart, JobEnd, JT."Job Task Type"::Heading);

        for Phase := 1 to PhaseCount do begin
            PhaseStart := CalcDate(StrSubstNo('+%1W', (Phase - 1) * 3), JobStart);
            PhaseEnd := CalcDate('+8W', PhaseStart);
            PhaseName := GetJobPhaseName(Phase);
            AddTask(JT, PadPhaseNo(Phase * 1000), PhaseName, PhaseStart, PhaseEnd, JT."Job Task Type"::"Begin-Total");

            for Task := 1 to TasksPerPhase do begin
                PostStart := CalcDate(StrSubstNo('+%1D', (Task - 1) * 2), PhaseStart);
                // Minimum 3-week duration, varied 3-6 weeks so bars aren't all identical.
                DurationWeeks := 3 + ((Phase + Task) mod 4);
                PostEnd := CalcDate(StrSubstNo('+%1W', DurationWeeks), PostStart);
                AddTask(JT, PadPhaseNo(Phase * 1000 + Task * 10), GetJobTaskName(Phase, Task, TasksPerPhase), PostStart, PostEnd, JT."Job Task Type"::Posting);
            end;

            AddTask(JT, PadPhaseNo(Phase * 1000 + 999), CopyStr(PhaseName + ' Total', 1, 100), PhaseStart, PhaseEnd, JT."Job Task Type"::"End-Total");
        end;

        AddTask(JT, PadPhaseNo((PhaseCount + 1) * 1000), CopyStr(JobName + ' Total', 1, 100), JobStart, JobEnd, JT."Job Task Type"::Total);

        Indent.IndentJobTasks(JT, true);
    end;

    local procedure PadPhaseNo(Value: Integer): Code[20]
    begin
        exit(Format(Value, 0, '<Integer,5><Filler Character,0>'));
    end;

    // ──────────────────────────────────────────────────────────────────────────
    // Demo Resources — Pool / Pool Member / External, single generation pass.
    // 40 pools x 2 members (120) + 80 external = 200 total. Single pass (no repeated
    // iterations) so this total isn't a multiplier away from drifting out of sync - see
    // CreateDemoResources for the exact breakdown and why pool COUNT (not members/pool) was
    // chosen as the lever to keep at 40.
    // ──────────────────────────────────────────────────────────────────────────

    local procedure CreateDemoResources()
    var
        Window: Dialog;
        ResourcesCreated: Integer;
        ResourcesTotal: Integer;
        PoolCount: Integer;
        MembersPerPool: Integer;
        ExternalCount: Integer;
        NoVendorsLbl: Label 'No vendors found. Skipping demo resource generation — create at least one vendor first.';
        NoSkillsLbl: Label 'No skill codes found. Skipping demo resource generation — create at least one skill code first.';
        NoUOMLbl: Label 'No units of measure found. Skipping demo resource generation — create at least one unit of measure first.';
        NoGenProdLbl: Label 'No Gen. Product Posting Groups found. Skipping demo resource generation — create at least one first.';
        NoVATProdLbl: Label 'No VAT Product Posting Groups found. Skipping demo resource generation — create at least one first.';
        NoResGroupLbl: Label 'No Resource Groups found. Skipping demo resource generation — create at least one resource group first.';
        ProgressLbl: Label 'Creating demo resources...\n#1########## of #2##########';
    begin
        EnsureResourceGroups();
        CreateDemoVendors();
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
        EnsureNamesLoaded();
        Clear(gForemanNos);
        gPoolSeq := 0;
        gMemberSeq := 0;
        gExternalSeq := 0;
        // Sequential counter feeding GetNextName()'s collision-free permutation - must not reset
        // between iterations/resource types, only once per full CreateDemoResources run.
        gNameCounter := 0;
        // Reset round-robin cursors so repeated runs in the same session (SingleInstance
        // codeunit) start from the same rotation instead of drifting further each time.
        gVendorIdx := 0;
        gDemoVendorIdx := 0;
        gSkillIdx := 0;
        gUOMIdx := 0;
        gGenProdIdx := 0;
        gVATProdIdx := 0;
        gResGroupIdx := 0;
        // Small demo dataset: 40 pools x 2 members = 120 pool-side resources (40 leaders + 80
        // members) + 80 external = 200 total. Pool COUNT (not members/pool) is what actually
        // controls bulk-job/resource contention later (see GetBulkJobResources - it always maps
        // a bulk job to its pool's first non-leader member via a deterministic FindFirst, so
        // members/pool doesn't spread load, only the number of distinct pools does), so 40 pools
        // was chosen deliberately high within the 200-resource budget rather than defaulting to
        // a "nicer-looking" even split - see the sanity-check note on CreateCapacityAndDayPlanning.
        PoolCount := 40;
        MembersPerPool := 2;
        ExternalCount := 80;
        ResourcesTotal := PoolCount * (1 + MembersPerPool) + ExternalCount; // 40*3 + 80 = 200

        if GuiAllowed() then
            Window.Open(ProgressLbl);
        // Single generation pass - the old 3x-iteration loop was a multiplier that had to stay in
        // sync with ResourcesTotal by hand; at this much smaller scale a single pass is simpler
        // and removes that drift risk entirely.
        CreateResourceIterationBatch(Window, ResourcesCreated, ResourcesTotal, PoolCount, MembersPerPool, ExternalCount);
        if GuiAllowed() then
            Window.Close();

        AssignForemanTree();
    end;

    // ──────────────────────────────────────────────────────────────────────────
    // Demo Vendors — 50 fixed real construction/building-industry company names
    // (DRV001..DRV050), created before LoadReferenceData() so CreateDemoResources()
    // always has vendors to round-robin through regardless of what Vendor records
    // already exist in the company. Idempotent insert-or-modify, same shape as UpsertJob -
    // every logged record is wiped by DeleteDemoData() at the start of the next run anyway.
    // ──────────────────────────────────────────────────────────────────────────

    local procedure CreateDemoVendors()
    var
        Vendor: Record Vendor;
        GenBusPostingGroup: Record "Gen. Business Posting Group";
        VATBusPostingGroup: Record "VAT Business Posting Group";
        VendorPostingGroup: Record "Vendor Posting Group";
        VendorNames: List of [Text[100]];
        VendorName: Text[100];
        VendorNo: Code[20];
        Idx: Integer;
        HasGenBusPostingGroup: Boolean;
        HasVATBusPostingGroup: Boolean;
        HasVendorPostingGroup: Boolean;
    begin
        VendorNames.Add('China State Construction Engineering Corporation');
        VendorNames.Add('China Railway Group');
        VendorNames.Add('China Railway Construction Corporation');
        VendorNames.Add('China Communications Construction Company');
        VendorNames.Add('VINCI Construction');
        VendorNames.Add('Bouygues Construction');
        VendorNames.Add('Hochtief AG');
        VendorNames.Add('Strabag SE');
        VendorNames.Add('Grupo ACS');
        VendorNames.Add('Ferrovial Construction');
        VendorNames.Add('Skanska AB');
        VendorNames.Add('Royal BAM Group');
        VendorNames.Add('Balfour Beatty');
        VendorNames.Add('Laing O''Rourke');
        VendorNames.Add('Multiplex Construction');
        VendorNames.Add('Lendlease Corporation');
        VendorNames.Add('Kier Group');
        VendorNames.Add('Turner Construction Company');
        VendorNames.Add('Bechtel Corporation');
        VendorNames.Add('Kiewit Corporation');
        VendorNames.Add('Fluor Corporation');
        VendorNames.Add('AECOM');
        VendorNames.Add('Jacobs Engineering Group');
        VendorNames.Add('KBR Inc.');
        VendorNames.Add('Whiting-Turner Contracting Company');
        VendorNames.Add('DPR Construction');
        VendorNames.Add('Suffolk Construction');
        VendorNames.Add('Clark Construction Group');
        VendorNames.Add('McCarthy Building Companies');
        VendorNames.Add('Hensel Phelps');
        VendorNames.Add('JE Dunn Construction');
        VendorNames.Add('Gilbane Building Company');
        VendorNames.Add('Mortenson Construction');
        VendorNames.Add('Barton Malow Company');
        VendorNames.Add('Walsh Group');
        VendorNames.Add('Brasfield & Gorrie');
        VendorNames.Add('Austin Industries');
        VendorNames.Add('Swinerton Builders');
        VendorNames.Add('Sundt Construction');
        VendorNames.Add('PCL Constructors');
        VendorNames.Add('EllisDon Corporation');
        VendorNames.Add('Pomerleau Inc.');
        VendorNames.Add('Graham Construction');
        VendorNames.Add('Bird Construction');
        VendorNames.Add('Larsen & Toubro Construction');
        VendorNames.Add('Samsung C&T Corporation');
        VendorNames.Add('Hyundai Engineering & Construction');
        VendorNames.Add('GS Engineering & Construction');
        VendorNames.Add('Obayashi Corporation');
        VendorNames.Add('Kajima Corporation');

        // Borrow the first existing posting groups, same pattern as EnsureCustomer - we don't
        // fabricate Gen. Bus./VAT Bus./Vendor Posting Group setup from scratch, since that
        // cascades into full financial setup that's out of scope here.
        HasGenBusPostingGroup := GenBusPostingGroup.FindFirst();
        HasVATBusPostingGroup := VATBusPostingGroup.FindFirst();
        HasVendorPostingGroup := VendorPostingGroup.FindFirst();

        Clear(gDemoVendorNos);
        Idx := 0;
        foreach VendorName in VendorNames do begin
            Idx += 1;
            VendorNo := 'DRV' + Format(Idx, 0, '<Integer,3><Filler Character,0>');
            Vendor.Init();
            Vendor.Validate("No.", VendorNo);
            Vendor.Validate(Name, VendorName);
            if HasGenBusPostingGroup then
                Vendor.Validate("Gen. Bus. Posting Group", GenBusPostingGroup.Code);
            if HasVATBusPostingGroup then
                Vendor.Validate("VAT Bus. Posting Group", VATBusPostingGroup.Code);
            if HasVendorPostingGroup then
                Vendor.Validate("Vendor Posting Group", VendorPostingGroup.Code);
            if not Vendor.Insert(true) then
                Vendor.Modify(true);
            LogRecord(Database::Vendor, Vendor.RecordId(), VendorNo + ' ' + Vendor.Name);
            // Track the demo vendor codes directly (no need to re-query the Vendor table) so
            // CreatePoolResource() can draw specifically from these 50 construction-company
            // vendors via GetNextDemoVendor(), instead of the general gVendorNos pool which may
            // also contain unrelated pre-existing vendors.
            gDemoVendorNos.Add(VendorNo);
        end;
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

    local procedure EnsureNamesLoaded()
    begin
        // Lazily load once per session (SingleInstance-style reuse across repeated runs); the
        // 635 first names x 1000 last names give 635,000 combinations, comfortably covering the
        // ~34,725 resources CreateDemoResources() creates (see GetNextName()).
        if gNamesLoaded then
            exit;
        // ResourceName is relative to the "src/data" folder declared in app.json's
        // resourceFolders - NOT the project-relative path (that folder prefix is stripped).
        LoadNameList('FirstNames.csv', gFirstNamesList);
        LoadNameList('LastNames.csv', gLastNamesList);
        gNamesLoaded := true;
    end;

    local procedure EnsureJobNamesLoaded()
    begin
        // Lazily load once per session (SingleInstance-style reuse across repeated runs), same
        // pattern as EnsureNamesLoaded() above - job/site/type names for bulk-job generation,
        // plus the fixed phase/task name lists reused identically across all bulk jobs.
        if gJobNamesLoaded then
            exit;
        LoadNameList('JobSiteNames.csv', gJobSiteNames);
        LoadNameList('ProjectTypeNames.csv', gProjectTypeNames);
        LoadNameList('JobPhaseNames.csv', gJobPhaseNames);
        LoadNameList('JobTaskNames.csv', gJobTaskNames);
        gJobNamesLoaded := true;
    end;

    local procedure LoadNameList(ResourceName: Text; var NameList: List of [Text[50]])
    var
        TypeHelper: Codeunit "Type Helper";
        Content: Text;
        Lines: List of [Text];
        Line: Text;
        LineNo: Integer;
    begin
        Clear(NameList);
        Content := NavApp.GetResourceAsText(ResourceName, TextEncoding::UTF8);
        Lines := Content.Split(TypeHelper.LFSeparator());
        foreach Line in Lines do begin
            LineNo += 1;
            Line := Line.TrimEnd(); // strips any trailing CR left over from CRLF-saved CSVs
            if (LineNo > 1) and (Line <> '') then // line 1 is the "Name" header row
                NameList.Add(CopyStr(Line, 1, 50));
        end;
    end;

    local procedure CreateResourceIterationBatch(var Window: Dialog; var ResourcesCreated: Integer; ResourcesTotal: Integer; PoolCount: Integer; MembersPerPool: Integer; ExternalCount: Integer)
    var
        p: Integer;
        m: Integer;
        e: Integer;
        PoolNo: Code[20];
    begin
        for p := 1 to PoolCount do begin
            PoolNo := CreatePoolResource();
            gForemanNos.Add(PoolNo);
            for m := 1 to MembersPerPool do
                CreateMemberResource(PoolNo);
            ResourcesCreated += 1 + MembersPerPool;
            if GuiAllowed() then begin
                Window.Update(1, ResourcesCreated);
                Window.Update(2, ResourcesTotal);
            end;
            // Commit after each pool group so this run doesn't hold one long transaction/lock -
            // cheap at this dataset size, kept mainly for consistency with the larger-scale pattern.
            Commit();
        end;
        for e := 1 to ExternalCount do begin
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
        Vendor: Record Vendor;
        VendorNo: Code[20];
        ResName: Text[100];
    begin
        gPoolSeq += 1;
        ResNo := 'DRP' + Format(gPoolSeq, 0, '<Integer,3><Filler Character,0>');
        // Pool resources draw specifically from the DRV* construction-company demo vendors
        // (GetNextDemoVendor()/gDemoVendorNos), NOT the general vendor pool (GetNextVendor()/
        // gVendorNos) - the general pool may also contain unrelated pre-existing vendors already
        // on file in the company, which would otherwise leak into a Pool resource's Name below.
        VendorNo := GetNextDemoVendor();
        // A Pool resource represents the vendor/company itself, not an individual worker, so its
        // Name should read as the Vendor's company name rather than a random person name.
        // CreateDemoVendors() guarantees 50 demo vendors exist and PoolCount (40) < 50, so this
        // lookup succeeds for every pool with no duplicate names given the round-robin cursor
        // starts fresh each run. GetNextName() is kept only as a defensive fallback (e.g. vendor
        // lookup failing), matching this codeunit's existing style of guarding against missing
        // master data.
        if (VendorNo <> '') and Vendor.Get(VendorNo) then
            ResName := Vendor.Name
        else
            ResName := GetNextName();
        Res.Init();
        Res.Validate("No.", ResNo);
        Res.Type := Res.Type::Person;
        Res.Validate(Name, ResName);
        Res."Vendor No." := VendorNo;
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
        Res.Validate(Name, GetNextName());
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
        Res.Validate(Name, GetNextName());
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

    local procedure GetNextDemoVendor(): Code[20]
    begin
        // Round-robins specifically over the 50 DRV* construction-company demo vendors created
        // by CreateDemoVendors(), NOT the general gVendorNos pool (which may also contain
        // unrelated pre-existing vendors) - used by CreatePoolResource() only.
        if gDemoVendorNos.Count() = 0 then
            exit('');
        gDemoVendorIdx += 1;
        exit(gDemoVendorNos.Get(((gDemoVendorIdx - 1) mod gDemoVendorNos.Count()) + 1));
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

    local procedure GetNextName(): Text[100]
    var
        Name: Text[100];
    begin
        // GetNextName() is just GetUniqueDemoResourceName() fed by the internal auto-incrementing
        // counter - all the permutation math lives in that single reusable procedure so external
        // callers (e.g. the resource-name repair report) can reuse the exact same collision-free
        // mapping without duplicating it here.
        Name := GetUniqueDemoResourceName(gNameCounter);
        gNameCounter += 1;
        exit(Name);
    end;

    procedure GetUniqueDemoResourceName(SequenceNo: Integer): Text[100]
    var
        Counter: BigInteger;
        Multiplier: BigInteger;
        TotalCombos: BigInteger;
        PermutedIndex: BigInteger;
        FirstCount: Integer;
        LastCount: Integer;
        FirstNameIndex: Integer;
        LastNameIndex: Integer;
    begin
        // Deterministic/bijective name assignment - NOT Random(). A pure random draw from even a
        // 635,000-combination pool would still collide well before ~34,725 draws (birthday
        // paradox), so instead every SequenceNo maps to a unique (first name, last name) pair via
        // a permutation, guaranteeing no duplicates for as many resources as CreateDemoResources()
        // actually creates - and, since it's a pure function of SequenceNo, safely callable from
        // outside this codeunit (e.g. a repair routine) with caller-supplied sequence numbers.
        //
        // 392453 is coprime with 635000 (= 635 first names x 1000 last names; 635000 factors as
        // 2^3 * 5^4 * 127, and 392453 is odd and divisible by neither 5 nor 127). Multiplying the
        // sequence number by a value coprime with the modulus and reducing mod TotalCombos is a
        // bijection over [0, TotalCombos) - i.e. as SequenceNo runs 0..TotalCombos-1 every value
        // in that range is hit exactly once - which is what makes the mapping collision-free while
        // still "looking" shuffled instead of sequential (James Aaronson, James Abbott, ... in order).
        EnsureNamesLoaded();

        FirstCount := gFirstNamesList.Count();
        LastCount := gLastNamesList.Count();
        TotalCombos := FirstCount;
        TotalCombos := TotalCombos * LastCount;

        Multiplier := 392453;
        Counter := SequenceNo;

        PermutedIndex := Counter * Multiplier;
        PermutedIndex := PermutedIndex mod TotalCombos;
        FirstNameIndex := PermutedIndex mod FirstCount + 1; // 1-based List<T> indexing
        LastNameIndex := PermutedIndex div FirstCount + 1;

        exit(CopyStr(gFirstNamesList.Get(FirstNameIndex) + ' ' + gLastNamesList.Get(LastNameIndex), 1, 100));
    end;

    procedure GetUniqueDemoJobName(SequenceNo: Integer): Text[100]
    var
        Counter: BigInteger;
        Multiplier: BigInteger;
        TotalCombos: BigInteger;
        PermutedIndex: BigInteger;
        SiteCount: Integer;
        TypeCount: Integer;
        SiteIndex: Integer;
        TypeIndex: Integer;
    begin
        // Same deterministic/bijective technique as GetUniqueDemoResourceName above, applied to
        // bulk-job names instead of resource names - a pure function of SequenceNo, so DJB0001
        // always maps to the same generated name every run (CreateBulkJobs() passes Idx - 1).
        EnsureJobNamesLoaded();

        SiteCount := gJobSiteNames.Count();
        TypeCount := gProjectTypeNames.Count();
        TotalCombos := SiteCount;
        TotalCombos := TotalCombos * TypeCount;

        // 104729 is prime and larger than the current word-list combo count (84*37=3,108), so it
        // is guaranteed coprime with TotalCombos (a prime cannot divide a smaller integer) - this
        // preserves the bijection even if the CSV word lists are expanded later, same reasoning as
        // the 392453 multiplier used by GetUniqueDemoResourceName for the first/last name lists.
        Multiplier := 104729;
        Counter := SequenceNo;
        PermutedIndex := Counter * Multiplier;
        PermutedIndex := PermutedIndex mod TotalCombos;
        SiteIndex := PermutedIndex mod SiteCount + 1;
        TypeIndex := PermutedIndex div SiteCount + 1;

        exit(CopyStr(gJobSiteNames.Get(SiteIndex) + ' ' + gProjectTypeNames.Get(TypeIndex), 1, 100));
    end;

    local procedure GetJobPhaseName(Phase: Integer): Text[50]
    begin
        EnsureJobNamesLoaded();
        exit(gJobPhaseNames.Get(((Phase - 1) mod gJobPhaseNames.Count()) + 1));
    end;

    local procedure GetJobTaskName(Phase: Integer; Task: Integer; TasksPerPhase: Integer): Text[50]
    var
        FlatIndex: Integer;
    begin
        // Defensive mod wraparound only - with the CSV exactly sized at 4 phases x 5 tasks = 20
        // rows matching PhaseCount/TasksPerPhase in CreateBulkJobTasks, this always lands in
        // range, but avoids a crash if PhaseCount/TasksPerPhase changes later without resizing
        // the CSV.
        EnsureJobNamesLoaded();
        FlatIndex := (Phase - 1) * TasksPerPhase + (Task - 1);
        exit(gJobTaskNames.Get((FlatIndex mod gJobTaskNames.Count()) + 1));
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

        // Bulk jobs draw leader/member from the pool of 40 demo Foreman resources (one per demo
        // pool - see PoolCount in CreateDemoResources) instead of the tiny 6-slot gRes array: 170
        // jobs sharing only 6 resources would blow straight through the per-resource-per-day cap
        // below and end up with almost no Day Planning at all once those 6 resources' daily slots
        // are exhausted.
        //
        // NOTE - known residual contention at the smaller 200-resource scale: with only 40 pools,
        // 170 bulk jobs average ~4.25 jobs per foreman (GetBulkJobResources cycles BulkIdx mod
        // gForemanNos.Count()), and for a given foreman GetBulkJobResources always resolves to the
        // exact same (LeaderRes, MemberRes) pair every time (Member.FindFirst() on that pool is
        // deterministic - MembersPerPool doesn't help spread this, since only the first member is
        // ever picked). Pool count was deliberately maximized within the 200-resource budget to
        // keep this ratio as low as practical (see CreateDemoResources), but it isn't eliminated:
        // several bulk jobs per foreman still compete for the same two resources' per-day slots
        // (TryReserveResourceDaySlot's cap), which can leave some bulk jobs with sparse or missing
        // Day Planning rows. If that turns out to matter for this dataset's purpose, the fix would
        // be to rotate GetBulkJobResources' member pick across all of a pool's members (not just
        // the first) using an index derived from the job's position within its foreman's rotation.
        for BulkIdx := 1 to gBulkJobNos.Count() do begin
            GetBulkJobResources(BulkIdx, LeaderRes, MemberRes);
            BuildDayPlanningsForJob(gBulkJobNos.Get(BulkIdx), LeaderRes, MemberRes);
            // Commit periodically so this doesn't run as one giant transaction.
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
                ResCap.Capacity := GetRandomDailyCapacity(ResCap."Start Time", ResCap."End Time");
                ResCap."Resource Group No." := Res."Resource Group No.";
                ResCap.Insert();
                LogRecord(Database::"Res. Capacity Entry", ResCap.RecordId(), ResNo + ' ' + Format(DT));
                EntryNo += 1;
            end;
    end;

    procedure GetRandomDailyCapacity(var StartTime: Time; var EndTime: Time): Decimal
    var
        CapacityHours: Integer;
        StartMs: Integer;
    begin
        // Randomized daily capacity 8..24h inclusive. Start Time is a realistic 07:00 workday
        // start; the Capacity *value* still ranges the full 8..24h, but AL's Time type cannot
        // represent 24:00:00+ (max is 23:59:59.999), so whenever 07:00 + CapacityHours would
        // cross midnight (CapacityHours >= 17), End Time is clamped to 23:59:59 instead of
        // wrapping — Time + Duration silently wraps modulo 24h rather than erroring, which would
        // otherwise produce a bogus short-looking span (e.g. 07:00 + 20h wrapping to 03:00, with
        // End < Start). The displayed span is then shorter than the stored Capacity number for
        // those high values; that mismatch is accepted for demo data rather than crossing days.
        CapacityHours := 8 + Random(17) - 1; // Random(17) = 1..17, so this yields 8..24 inclusive
        StartTime := 070000T;
        StartMs := 25200000; // 07:00:00 in milliseconds since midnight
        if StartMs + (CapacityHours * 3600000) >= 86400000 then
            EndTime := 235959T
        else
            EndTime := StartTime + (CapacityHours * 3600000);
        exit(CapacityHours);
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

        // These resources were all just created earlier in this same run, so they are guaranteed
        // to have zero existing capacity - no CalcFields(Capacity) check needed before inserting.
        // LogRecord IS called per row below: "Delete Demo Data" (codeunit 50679) only removes
        // records tracked in the Demo Data Log — it has no prefix-based fallback for untracked
        // rows — so any capacity entry created here without a matching log entry would survive
        // a "Delete Demo Data" run and become a stale duplicate the next time this codeunit runs
        // for the same resource/date. At the current ~120-resource scale (down from ~34,000) the
        // per-row LogRecord cost is no longer the bottleneck it once was.
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
                        ResCap.Capacity := GetRandomDailyCapacity(ResCap."Start Time", ResCap."End Time");
                        ResCap."Resource Group No." := Res."Resource Group No.";
                        ResCap.Insert();
                        LogRecord(Database::"Res. Capacity Entry", ResCap.RecordId(), Res."No." + ' ' + Format(DT));
                        EntryNo += 1;
                    end;
                if GuiAllowed() then begin
                    Window.Update(1, Idx);
                    Window.Update(2, Total);
                end;
                // Each resource can add up to ~550 capacity rows (one per working day across the
                // ~110-week demo window), so commit periodically rather than one giant transaction.
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
        DP."Assigned Pool Resource No." := GetResourcePoolNo(DP);
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
        DP."Assigned Pool Resource No." := GetResourcePoolNo(DP);
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
    // Work Order Demo Data — one dedicated Job (No. = the shared demo Customer's No., matching
    // this app's real Work-Order-to-Job convention) with 18 Posting tasks in two groups: 10
    // Work-Order-linked tasks (custom exact-hours/span Day Planning, tagged with "Work Order No.")
    // and 8 plain tasks (reuse the existing BuildDayPlanningsForTask weekday-pattern generator).
    // Plus 3 Order Intakes (DOI0001..DOI0003) and 10 Work Orders (DWO0001..DWO0010, round-robin
    // linked to the Order Intakes) tying back to the 10 Work-Order-linked Job Tasks.
    // ──────────────────────────────────────────────────────────────────────────

    local procedure CreateWorkOrderDemoData()
    var
        Customer: Record Customer;
        Job: Record Job;
        JobNo: Code[20];
    begin
        if not Customer.FindFirst() then
            EnsureCustomer(Customer);
        JobNo := Customer."No.";
        UpsertJob(Job, JobNo, 'Work Order Demo Data', Customer."No.");
        BuildWorkOrderDemoTasks(JobNo);
        CreateWorkOrderDemoOrderIntakes(Customer."No.", Customer.Name);
        CreateWorkOrderDemoWorkOrders(JobNo, Customer."No.");
        CreateWorkOrderLinkedDayPlannings(JobNo);
        CreateWorkOrderNonLinkedDayPlannings(JobNo);
    end;

    local procedure BuildWorkOrderDemoTasks(JobNo: Code[20])
    var
        JT: Record "Job Task";
        Indent: Codeunit "Job Task Indent";
        D1010: Date;
        D1020: Date;
        D1030: Date;
        D1040: Date;
        D1050: Date;
        D1060Start: Date;
        D1060End: Date;
        D1070Start: Date;
        D1070End: Date;
        D1080Start: Date;
        D1080End: Date;
        D1090Start: Date;
        D1090End: Date;
        D1100Start: Date;
        D1100End: Date;
        JobEnd: Date;
    begin
        // Single-day/exact-hours candidates and 2-3 day span candidates are all snapped forward
        // to the next actual working day (Work-Hour Template AND DEMOCAL calendar exceptions,
        // via IsWorkingDay()) so no point-in-time task ever lands on a day off. Span End dates
        // are NOT snapped independently - they're simply Start + (span-1) days; the Day Planning
        // generation loop below skips any non-working days that happen to fall inside the span.
        D1010 := NextWorkingDayOnOrAfter(CalcDate('+3D', gStartDate));
        D1020 := NextWorkingDayOnOrAfter(CalcDate('+1W+1D', gStartDate));
        D1030 := NextWorkingDayOnOrAfter(CalcDate('+1W+3D', gStartDate));
        D1040 := NextWorkingDayOnOrAfter(CalcDate('+2W', gStartDate));
        D1050 := NextWorkingDayOnOrAfter(CalcDate('+2W+2D', gStartDate));

        D1060Start := NextWorkingDayOnOrAfter(CalcDate('+3W', gStartDate));
        D1060End := CalcDate('+1D', D1060Start);
        D1070Start := NextWorkingDayOnOrAfter(CalcDate('+3W+3D', gStartDate));
        D1070End := CalcDate('+1D', D1070Start);
        D1080Start := NextWorkingDayOnOrAfter(CalcDate('+4W', gStartDate));
        D1080End := CalcDate('+2D', D1080Start);
        D1090Start := NextWorkingDayOnOrAfter(CalcDate('+4W+4D', gStartDate));
        D1090End := CalcDate('+2D', D1090Start);
        D1100Start := NextWorkingDayOnOrAfter(CalcDate('+5W', gStartDate));
        D1100End := CalcDate('+1D', D1100Start);

        JobEnd := CalcDate('+78W', gStartDate); // covers 2080's end (+62W start + 16W span)
        JT."Job No." := JobNo;

        AddTask(JT, '0', 'Work Order Demo Data', gStartDate, JobEnd, JT."Job Task Type"::Heading);

        AddTask(JT, '1000', 'Work Order Linked Tasks', D1010, D1100End, JT."Job Task Type"::"Begin-Total");
        AddTask(JT, '1010', 'Site Safety Walkthrough', D1010, D1010, JT."Job Task Type"::Posting);
        AddTask(JT, '1020', 'Equipment Inspection', D1020, D1020, JT."Job Task Type"::Posting);
        AddTask(JT, '1030', 'Material Delivery Check', D1030, D1030, JT."Job Task Type"::Posting);
        AddTask(JT, '1040', 'Client Progress Review', D1040, D1040, JT."Job Task Type"::Posting);
        AddTask(JT, '1050', 'Minor Repair Callout', D1050, D1050, JT."Job Task Type"::Posting);
        AddTask(JT, '1060', 'Punch List Walkthrough', D1060Start, D1060End, JT."Job Task Type"::Posting);
        AddTask(JT, '1070', 'Utility Locate & Mark', D1070Start, D1070End, JT."Job Task Type"::Posting);
        AddTask(JT, '1080', 'Snag List Resolution', D1080Start, D1080End, JT."Job Task Type"::Posting);
        AddTask(JT, '1090', 'Subcontractor Coordination', D1090Start, D1090End, JT."Job Task Type"::Posting);
        AddTask(JT, '1100', 'Weather Delay Assessment', D1100Start, D1100End, JT."Job Task Type"::Posting);
        AddTask(JT, '1999', 'Work Order Linked Tasks Total', D1010, D1100End, JT."Job Task Type"::"End-Total");

        AddTask(JT, '2000', 'Extended & Long-Term Tasks', gStartDate, JobEnd, JT."Job Task Type"::"Begin-Total");
        AddTask(JT, '2010', 'Extended Site Monitoring A', gStartDate, CalcDate('+8D', gStartDate), JT."Job Task Type"::Posting);
        AddTask(JT, '2020', 'Extended Site Monitoring B', CalcDate('+2W', gStartDate), CalcDate('+2W+6D', gStartDate), JT."Job Task Type"::Posting);
        AddTask(JT, '2030', 'Phase Handover Documentation A', CalcDate('+4W', gStartDate), CalcDate('+13W', gStartDate), JT."Job Task Type"::Posting);
        AddTask(JT, '2040', 'Phase Handover Documentation B', CalcDate('+8W', gStartDate), CalcDate('+16W', gStartDate), JT."Job Task Type"::Posting);
        AddTask(JT, '2050', 'Extended Warranty Support A', CalcDate('+17W', gStartDate), CalcDate('+30W', gStartDate), JT."Job Task Type"::Posting);
        AddTask(JT, '2060', 'Extended Warranty Support B', CalcDate('+31W', gStartDate), CalcDate('+43W', gStartDate), JT."Job Task Type"::Posting);
        AddTask(JT, '2070', 'Long-Term Maintenance Contract A', CalcDate('+44W', gStartDate), CalcDate('+61W', gStartDate), JT."Job Task Type"::Posting);
        AddTask(JT, '2080', 'Long-Term Maintenance Contract B', CalcDate('+62W', gStartDate), JobEnd, JT."Job Task Type"::Posting);
        AddTask(JT, '2999', 'Extended & Long-Term Tasks Total', gStartDate, JobEnd, JT."Job Task Type"::"End-Total");

        AddTask(JT, '9999', 'Work Order Demo Data Total', gStartDate, JobEnd, JT."Job Task Type"::Total);

        Indent.IndentJobTasks(JT, true);
    end;

    local procedure NextWorkingDayOnOrAfter(CandidateDate: Date): Date
    begin
        // IsWorkingDay() already checks both the Work-Hour Template AND DEMOCAL's calendar
        // exceptions (holidays + custom demo days-off) - see the OnRun() sequencing fix earlier
        // this session - so routing every point-in-time date through this guarantees nothing
        // lands on a day off.
        while not IsWorkingDay(CandidateDate) do
            CandidateDate := CalcDate('+1D', CandidateDate);
        exit(CandidateDate);
    end;

    local procedure CreateWorkOrderDemoOrderIntakes(CustNo: Code[20]; CustName: Text[100])
    begin
        UpsertOrderIntake('DOI0001', CustNo, CustName, gStartDate);
        UpsertOrderIntake('DOI0002', CustNo, CustName, CalcDate('+1D', gStartDate));
        UpsertOrderIntake('DOI0003', CustNo, CustName, CalcDate('+2D', gStartDate));
    end;

    local procedure UpsertOrderIntake(OrderIntakeNo: Code[20]; CustNo: Code[20]; CustName: Text[100]; OrderDate: Date)
    var
        OrderIntake: Record "Order Intake Header Opt.";
    begin
        // Fixed demo code (not NoSeries.GetNextNo()), idempotent insert-or-modify, same shape as
        // CreateDemoVendors/UpsertJob elsewhere in this file. NOTE: table_50604's OnInsert trigger
        // unconditionally sets "Order Date" := Today() whenever it fires (its auto-numbering
        // branch is skipped here since "No." is already non-blank before Insert) - so "Order Date"
        // is deliberately set/overridden AFTER Insert via Modify(), not before.
        if not OrderIntake.Get(OrderIntakeNo) then begin
            OrderIntake.Init();
            OrderIntake."No." := OrderIntakeNo;
            OrderIntake.Insert(true);
        end;
        OrderIntake."Customer No." := CustNo;
        OrderIntake."Customer Name" := CustName;
        OrderIntake."Order Date" := OrderDate;
        OrderIntake.Status := OrderIntake.Status::Open;
        OrderIntake.Modify();
        LogRecord(Database::"Order Intake Header Opt.", OrderIntake.RecordId(), OrderIntakeNo + ' ' + CustName);
    end;

    local procedure CreateWorkOrderDemoWorkOrders(JobNo: Code[20]; CustNo: Code[20])
    var
        JT: Record "Job Task";
        TaskNos: array[10] of Code[20];
        WorkOrderNo: Code[20];
        OrderIntakeNo: Code[20];
        Idx: Integer;
    begin
        TaskNos[1] := '1010';
        TaskNos[2] := '1020';
        TaskNos[3] := '1030';
        TaskNos[4] := '1040';
        TaskNos[5] := '1050';
        TaskNos[6] := '1060';
        TaskNos[7] := '1070';
        TaskNos[8] := '1080';
        TaskNos[9] := '1090';
        TaskNos[10] := '1100';

        for Idx := 1 to 10 do begin
            WorkOrderNo := 'DWO' + Format(Idx, 0, '<Integer,4><Filler Character,0>');
            // Round-robin: WO1-4 -> DOI0001, WO5-7 -> DOI0002, WO8-10 -> DOI0003.
            case true of
                Idx <= 4:
                    OrderIntakeNo := 'DOI0001';
                Idx <= 7:
                    OrderIntakeNo := 'DOI0002';
                else
                    OrderIntakeNo := 'DOI0003';
            end;
            if JT.Get(JobNo, TaskNos[Idx]) then
                UpsertWorkOrder(WorkOrderNo, OrderIntakeNo, CustNo, JT.Description, JobNo, TaskNos[Idx]);
        end;
    end;

    local procedure UpsertWorkOrder(WorkOrderNo: Code[20]; OrderIntakeNo: Code[20]; CustNo: Code[20]; Desc: Text[100]; ProjectNo: Code[20]; ProjectTaskNo: Code[20])
    var
        WorkOrder: Record "Work Order";
    begin
        // Fixed demo code (not NoSeries.GetNextNo()) - idempotent across reruns, same reasoning as
        // every other demo entity in this codeunit. "Work Order NOS" (which No. Series was used)
        // is deliberately left blank since no series was consumed. table_50608's OnInsert trigger
        // only sets audit fields (Created DateTime/By) and testfields "Work Order No." - no
        // destructive field overrides to work around here (unlike Order Intake's OnInsert).
        if not WorkOrder.Get(WorkOrderNo) then begin
            WorkOrder.Init();
            WorkOrder."Work Order No." := WorkOrderNo;
            WorkOrder.Insert(true);
        end;
        WorkOrder."Order Intake No." := OrderIntakeNo;
        WorkOrder.Description := Desc;
        WorkOrder."Customer No." := CustNo;
        WorkOrder."Source Type" := WorkOrder."Source Type"::"Order Intake";
        WorkOrder."Project No." := ProjectNo;
        WorkOrder."Project Task No." := ProjectTaskNo;
        WorkOrder.Modify();
        LogRecord(Database::"Work Order", WorkOrder.RecordId(), WorkOrderNo + ' ' + Desc);
    end;

    local procedure CreateWorkOrderLinkedDayPlannings(JobNo: Code[20])
    var
        JT: Record "Job Task";
        ResNo: Code[20];
        WorkOrderNo: Code[20];
        DT: Date;
        Hours: Decimal;
        Idx: Integer;
        TaskNos: array[10] of Code[20];
    begin
        // Single resource (leader-only, no member) throughout this group, per spec - keeps this
        // custom Work-Order Day Planning generation simple rather than mirroring the full
        // leader/member pattern used by BuildDayPlanningsForTask below.
        ResNo := GetRes(7);
        if ResNo = '' then
            // No resources at all (e.g. gResCount still 0 for some other reason than the
            // zero-pre-existing-resources case OnRun() already falls back for) - skip rather than
            // insert meaningless orphaned-looking rows with a blank Requested/Assigned Resource No.
            exit;
        TaskNos[1] := '1010';
        TaskNos[2] := '1020';
        TaskNos[3] := '1030';
        TaskNos[4] := '1040';
        TaskNos[5] := '1050';
        TaskNos[6] := '1060';
        TaskNos[7] := '1070';
        TaskNos[8] := '1080';
        TaskNos[9] := '1090';
        TaskNos[10] := '1100';

        for Idx := 1 to 10 do begin
            WorkOrderNo := 'DWO' + Format(Idx, 0, '<Integer,4><Filler Character,0>');
            if not JT.Get(JobNo, TaskNos[Idx]) then
                continue;
            case TaskNos[Idx] of
                '1010':
                    Hours := 2;
                '1020':
                    Hours := 3;
                '1030':
                    Hours := 5;
                '1040':
                    Hours := 2;
                '1050':
                    Hours := 3;
                else
                    Hours := 0; // span tasks (1060-1100) use a fixed 8h/working-day below instead
            end;
            if Hours > 0 then begin
                // Single-day/exact-hours group: PlannedStartDate was already snapped to a working
                // day in BuildWorkOrderDemoTasks (NextWorkingDayOnOrAfter), so no further
                // IsWorkingDay check is needed here. TryReserveResourceDaySlot enforces the same
                // "max 3 Day Planning lines/resource/day" cap every other generator in this
                // codeunit respects (matters if GetRes(7) wraps around and collides with a
                // JOB001-003 leader on an overlapping early date) - on the rare cap collision this
                // slot is just silently skipped, same behavior as BuildDayPlanningsForTask's own
                // per-line cap check, no "weekly guarantee" fallback needed here.
                if TryReserveResourceDaySlot(ResNo, JT."PlannedStartDate") then
                    InsertWorkOrderDayPlanning(JT, ResNo, JT."PlannedStartDate", Hours, WorkOrderNo);
            end else
                // 2-3 day span group: PlannedStartDate is snapped, but the span may still cross a
                // non-working day in between (e.g. a DEMOCAL holiday) - skip those explicitly.
                for DT := JT."PlannedStartDate" to JT."PlannedEndDate" do
                    if IsWorkingDay(DT) and TryReserveResourceDaySlot(ResNo, DT) then
                        InsertWorkOrderDayPlanning(JT, ResNo, DT, 8, WorkOrderNo);
        end;
    end;

    local procedure InsertWorkOrderDayPlanning(JT: Record "Job Task"; ResNo: Code[20]; DT: Date; Hours: Decimal; WorkOrderNo: Code[20])
    var
        DP: Record "Day Planning";
        PlanSt: Enum "Plan Status";
        ResGrp: Code[20];
        StartT: Time;
        EndT: Time;
    begin
        PlanSt := CalcPlanStatus(DT);
        ResGrp := GetResGrp(ResNo);
        StartT := 080000T;
        EndT := StartT + (Hours * 3600000);

        DP.Init();
        DP."Job No." := JT."Job No.";
        DP."Job Task No." := JT."Job Task No.";
        DP."Task Date" := DT;
        DP."Day Line No." := NextDayLineNo(JT."Job No.", JT."Job Task No.");
        DP."Plan Status" := PlanSt;
        DP."Requested Resource No." := ResNo;
        DP."Start Time Requested" := StartT;
        DP."End Time Requested" := EndT;
        DP."Requested Hours" := Hours;
        DP.Leader := true;
        DP."Team Leader" := ResNo;
        DP."Data Owner" := "Data Owner Opt."::"TeamLeader";
        DP.Description := 'Work Order ' + WorkOrderNo + ': ' + JT.Description;
        DP.Skill := GetResourceSkill(ResNo);
        DP."Work Order No." := WorkOrderNo;
        if PlanSt <> "Plan Status"::"In Request" then begin
            DP."Assigned Resource No." := ResNo;
            DP."Resource Group No." := ResGrp;
            DP."Start Time Assigned" := StartT;
            DP."End Time Assigned" := EndT;
            DP."Assigned Hours" := Hours;
        end;
        DP."Assigned Pool Resource No." := GetResourcePoolNo(DP);
        DP.Insert(false);
        LogRecord(Database::"Day Planning", DP.RecordId(), JT."Job No." + '.' + JT."Job Task No." + ' ' + Format(DT) + ' WO ' + WorkOrderNo);
    end;

    local procedure CreateWorkOrderNonLinkedDayPlannings(JobNo: Code[20])
    var
        JT: Record "Job Task";
        LeaderRes: Code[20];
        MemberRes: Code[20];
        TaskNos: array[8] of Code[20];
        Idx: Integer;
    begin
        // Reuses the existing weekday-pattern/leader-member/3-per-day-cap/weekly-guarantee
        // generator unmodified (it already routes every date through IsWorkingDay()). Looping
        // over these 8 Job Task Nos individually - rather than calling BuildDayPlanningsForJob for
        // this whole Job - deliberately excludes the 10 Work-Order-linked tasks (1010-1100), which
        // already got their own custom Day Planning rows above and would otherwise be
        // double-generated/conflicted by BuildDayPlanningsForJob's "Job Task Type::Posting" filter.
        LeaderRes := GetRes(8);
        MemberRes := GetRes(9);
        TaskNos[1] := '2010';
        TaskNos[2] := '2020';
        TaskNos[3] := '2030';
        TaskNos[4] := '2040';
        TaskNos[5] := '2050';
        TaskNos[6] := '2060';
        TaskNos[7] := '2070';
        TaskNos[8] := '2080';
        for Idx := 1 to 8 do
            if JT.Get(JobNo, TaskNos[Idx]) then
                BuildDayPlanningsForTask(JT, LeaderRes, MemberRes);
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
                    ReqStart := 080000T;
                    ReqEnd := 160000T;   // 8 h requested
                    AsgnStart := 080000T;
                    AsgnEnd := 160000T;  // 8 h assigned
                end;
            2:  // Tuesday: morning block, fully assigned
                begin
                    ReqStart := 080000T;
                    ReqEnd := 120000T;   // 4 h
                    AsgnStart := 080000T;
                    AsgnEnd := 120000T;
                end;
            3:  // Wednesday: late start, assigned shorter than requested (partial availability)
                begin
                    ReqStart := 090000T;
                    ReqEnd := 170000T;   // 8 h requested
                    AsgnStart := 090000T;
                    AsgnEnd := 130000T;  // 4 h assigned
                end;
            4:  // Thursday: full day requested, slightly under-assigned
                begin
                    ReqStart := 080000T;
                    ReqEnd := 170000T;   // 9 h requested
                    AsgnStart := 080000T;
                    AsgnEnd := 160000T;  // 8 h assigned
                end;
            5:  // Friday: short day
                begin
                    ReqStart := 080000T;
                    ReqEnd := 130000T;   // 5 h
                    AsgnStart := 080000T;
                    AsgnEnd := 130000T;
                end;
            else begin
                ReqStart := 080000T;
                ReqEnd := 160000T;
                AsgnStart := 080000T;
                AsgnEnd := 160000T;
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

    procedure IsDemoWorkingDay(DT: Date): Boolean
    begin
        // Public wrapper so external callers (e.g. the capacity-regeneration repair) can reuse the
        // exact same working-day check the generator uses, without having to run Initialize() /
        // duplicate the BASIS Work-Hour Template lookup first. Lazily loads gWorkHoursTemplate once
        // per codeunit instance, same pattern as gNamesLoaded/EnsureNamesLoaded.
        if not gWorkHourTemplateLoaded then begin
            EnsureWorkHourTemplate('BASIS');
            gWorkHoursTemplate.Get('BASIS');
            gWorkHourTemplateLoaded := true;
        end;
        exit(IsWorkingDay(DT));
    end;

    local procedure IsWorkingDay(DT: Date): Boolean
    var
        CalendarMgt: Codeunit "Calendar Management";
        IsTemplateWorkingDay: Boolean;
    begin
        // Fast path (unchanged behavior): Work-Hour Template weekday flags decide first. Only if
        // the template says this weekday is normally working do we ALSO check DEMOCAL's
        // "Base Calendar Change" exceptions (holidays + custom demo days-off) below - a template
        // non-working day never gets "resurrected" by the calendar.
        case Date2DWY(DT, 1) of
            1:
                IsTemplateWorkingDay := gWorkHoursTemplate.Monday <> 0;
            2:
                IsTemplateWorkingDay := gWorkHoursTemplate.Tuesday <> 0;
            3:
                IsTemplateWorkingDay := gWorkHoursTemplate.Wednesday <> 0;
            4:
                IsTemplateWorkingDay := gWorkHoursTemplate.Thursday <> 0;
            5:
                IsTemplateWorkingDay := gWorkHoursTemplate.Friday <> 0;
            6:
                IsTemplateWorkingDay := gWorkHoursTemplate.Saturday <> 0;
            7:
                IsTemplateWorkingDay := gWorkHoursTemplate.Sunday <> 0;
            else
                IsTemplateWorkingDay := false;
        end;
        if not IsTemplateWorkingDay then
            exit(false);

        EnsureBaseCalendarLoaded();
        exit(not CalendarMgt.IsNonworkingDay(DT, gCustomizedCalendarChange));
    end;

    local procedure EnsureBaseCalendarLoaded()
    var
        OptimizerSetup: Record "Daily Optimizer Setup";
        CalendarMgt: Codeunit "Calendar Management";
    begin
        // Load DEMOCAL's Base Calendar + combined Customized Calendar Change ONCE and reuse it
        // across every IsWorkingDay() call (tens of thousands of calls across the ~2-year demo
        // window x every resource), rather than re-running SetSource per call like
        // codeunit_50610's ExpectedWeekDay does (that procedure is called far less often, so its
        // per-call SetSource cost is negligible - not true here). Verified via al_symbolsearch
        // that Calendar Management.IsNonworkingDay(TargetDate; var CustomizedCalendarChange) only
        // reads/filters the already-combined CustomizedCalendarChange record by date on each call
        // - it is not a cursor/stateful API that advances or gets consumed, so calling SetSource
        // once and reusing the same var record across many IsNonworkingDay calls is the standard,
        // intended BC pattern (same shape used elsewhere in base app, e.g. delivery date/shipping
        // agent calendar lookups that call SetSource once then loop CalcDateBOC/IsNonworkingDay).
        //
        // Same pattern as gWorkHourTemplateLoaded/EnsureWorkHourTemplate caching, gResourceSkillCache,
        // gResourcePoolCache, gNamesLoaded elsewhere in this codeunit.
        if gBaseCalendarLoaded then
            exit;
        gBaseCalendarLoaded := true;
        if not OptimizerSetup.Get() then
            exit;
        if OptimizerSetup."Base Calendar" = '' then
            exit;
        if not gBaseCalendar.Get(OptimizerSetup."Base Calendar") then
            exit;
        CalendarMgt.SetSource(gBaseCalendar, gCustomizedCalendarChange);
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
