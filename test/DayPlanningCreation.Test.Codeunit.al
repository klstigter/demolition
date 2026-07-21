codeunit 60020 "Day Planning Creation Tests"
{
    // Tests for codeunit 50610 "Day Plannings Mgt." - procedure CreateDayPlanning(DayPlanningPattern: Record "Day Planning Pattern")
    // Covers expansion of a Day Planning Pattern (date range + weekday checkboxes + work-hour template)
    // into individual "Day Planning" (table 50610) records.
    Subtype = Test;
    TestPermissions = Disabled;

    var
        IsInitialized: Boolean;
        TestJobNo: Code[20];
        TestJobTaskNo: Code[20];
        TestWorkHourTemplateCode: Code[20];
        TestResourceNo: Code[20];
        TestSkillCode: Code[10];
        TestBaseCalendarCode: Code[10];

    local procedure Initialize()
    var
        OptimizerSetup: Record "Daily Optimizer Setup";
        BaseCalendar: Record "Base Calendar";
        WorkHourTemplate: Record "Work-Hour Template";
        Job: Record Job;
        JobTask: Record "Job Task";
    begin
        TestJobNo := 'DPCT-JOB';
        TestJobTaskNo := '1000';
        TestWorkHourTemplateCode := 'DPCTWHT';
        TestBaseCalendarCode := 'DPCTCAL';

        if IsInitialized then
            exit;

        // [GIVEN] A Base Calendar exists (no Customized Calendar Change entries -> no non-working days excluded)
        if not BaseCalendar.Get(TestBaseCalendarCode) then begin
            BaseCalendar.Init();
            BaseCalendar.Code := TestBaseCalendarCode;
            BaseCalendar.Name := 'Day Planning Test Calendar';
            BaseCalendar.Insert();
        end;

        // [GIVEN] Daily Optimizer Setup singleton points to that Base Calendar
        if not OptimizerSetup.Get() then begin
            OptimizerSetup.Init();
            OptimizerSetup.Insert();
        end;
        OptimizerSetup."Base Calendar" := TestBaseCalendarCode;
        OptimizerSetup.Modify();

        // [GIVEN] A Work-Hour Template with default start/end time, non working minutes, and
        // Monday..Friday active (hours > 0)/Saturday-Sunday inactive (0) - the "normal business
        // hours" default most tests can reuse as-is. IsActiveWorkDay (codeunit 50610) reads these
        // per-weekday hours fields directly - this replaced the old Day 1..Day 7 boolean pattern
        // fields on Day Planning Pattern, which are now gone.
        if not WorkHourTemplate.Get(TestWorkHourTemplateCode) then begin
            WorkHourTemplate.Init();
            WorkHourTemplate.Code := TestWorkHourTemplateCode;
            WorkHourTemplate.Description := 'Day Planning Creation Test WHT';
            WorkHourTemplate.Insert();
        end;
        WorkHourTemplate."Default Start Time" := 080000T;
        WorkHourTemplate."Default End Time" := 170000T;
        WorkHourTemplate."Non Working Minutes" := 30;
        WorkHourTemplate.Monday := 8;
        WorkHourTemplate.Tuesday := 8;
        WorkHourTemplate.Wednesday := 8;
        WorkHourTemplate.Thursday := 8;
        WorkHourTemplate.Friday := 8;
        WorkHourTemplate.Saturday := 0;
        WorkHourTemplate.Sunday := 0;
        WorkHourTemplate.Modify();

        // [GIVEN] A Job + Job Task to attach Day Planning Pattern / Day Planning records to
        if not Job.Get(TestJobNo) then begin
            Job.Init();
            Job."No." := TestJobNo;
            Job.Description := 'Day Planning Creation Test Job';
            Job.Insert();
        end;
        if not JobTask.Get(TestJobNo, TestJobTaskNo) then begin
            JobTask.Init();
            JobTask."Job No." := TestJobNo;
            JobTask."Job Task No." := TestJobTaskNo;
            JobTask.Description := 'Day Planning Creation Test Job Task';
            JobTask."Job Task Type" := JobTask."Job Task Type"::Posting;
            JobTask.Insert();
        end;
        // Wide-open planned dates so the JobTask.PlannedStartDate/PlannedEndDate update at the
        // end of CreateDayPlanning() is observable and never blocked by CheckDayPlanningDateInProjectTaskRange.
        JobTask.PlannedStartDate := 0D;
        JobTask.PlannedEndDate := 0D;
        JobTask.Modify();

        TestResourceNo := CreateTestResource();
        TestSkillCode := CreateTestSkillCode();

        IsInitialized := true;
        Commit();
    end;

    local procedure CreateTestResource(): Code[20]
    var
        Resource: Record Resource;
        ResNo: Code[20];
    begin
        ResNo := 'DPCTRES';
        if not Resource.Get(ResNo) then begin
            Resource.Init();
            Resource."No." := ResNo;
            Resource.Name := 'Day Planning Creation Test Resource';
            Resource.Type := Resource.Type::Person;
            Resource.Insert();
        end;
        exit(ResNo);
    end;

    local procedure CreateTestSkillCode(): Code[10]
    var
        SkillCode: Record "Skill Code";
        Code10: Code[10];
    begin
        Code10 := 'DPCTSKL';
        if not SkillCode.Get(Code10) then begin
            SkillCode.Init();
            SkillCode.Code := Code10;
            SkillCode.Description := 'Day Planning Creation Test Skill';
            SkillCode.Insert();
        end;
        exit(Code10);
    end;

    /// <summary>
    /// A Work-Hour Template with ONLY Monday active (hours > 0), every other weekday 0/blank.
    /// Used by tests that need to prove weekday-exclusivity (only Monday qualifies), which the
    /// shared default TestWorkHourTemplateCode (Mon-Fri all active) can no longer isolate on its own.
    /// </summary>
    local procedure CreateMondayOnlyWorkHourTemplate(): Code[20]
    var
        WorkHourTemplate: Record "Work-Hour Template";
        TemplateCode: Code[20];
    begin
        TemplateCode := 'DPCTWHTMO';
        if not WorkHourTemplate.Get(TemplateCode) then begin
            WorkHourTemplate.Init();
            WorkHourTemplate.Code := TemplateCode;
            WorkHourTemplate.Description := 'Day Planning Creation Test WHT - Monday Only';
            WorkHourTemplate.Insert();
        end;
        WorkHourTemplate."Default Start Time" := 080000T;
        WorkHourTemplate."Default End Time" := 170000T;
        WorkHourTemplate."Non Working Minutes" := 30;
        WorkHourTemplate.Monday := 8;
        WorkHourTemplate.Tuesday := 0;
        WorkHourTemplate.Wednesday := 0;
        WorkHourTemplate.Thursday := 0;
        WorkHourTemplate.Friday := 0;
        WorkHourTemplate.Saturday := 0;
        WorkHourTemplate.Sunday := 0;
        WorkHourTemplate.Modify();
        exit(TemplateCode);
    end;

    /// <summary>
    /// A Work-Hour Template with ONLY Tuesday active (hours > 0), every other weekday - including
    /// Monday - 0/blank. Used by the "day not checked as weekday" test: mirrors the original
    /// "Day 1 (Monday) unchecked / Day 2 (Tuesday) checked but out of range" scenario now that
    /// weekday-activity comes from the template instead of the removed Day 1..Day 7 booleans.
    /// </summary>
    local procedure CreateTuesdayOnlyWorkHourTemplate(): Code[20]
    var
        WorkHourTemplate: Record "Work-Hour Template";
        TemplateCode: Code[20];
    begin
        TemplateCode := 'DPCTWHTTU';
        if not WorkHourTemplate.Get(TemplateCode) then begin
            WorkHourTemplate.Init();
            WorkHourTemplate.Code := TemplateCode;
            WorkHourTemplate.Description := 'Day Planning Creation Test WHT - Tuesday Only';
            WorkHourTemplate.Insert();
        end;
        WorkHourTemplate."Default Start Time" := 080000T;
        WorkHourTemplate."Default End Time" := 170000T;
        WorkHourTemplate."Non Working Minutes" := 30;
        WorkHourTemplate.Monday := 0;
        WorkHourTemplate.Tuesday := 8;
        WorkHourTemplate.Wednesday := 0;
        WorkHourTemplate.Thursday := 0;
        WorkHourTemplate.Friday := 0;
        WorkHourTemplate.Saturday := 0;
        WorkHourTemplate.Sunday := 0;
        WorkHourTemplate.Modify();
        exit(TemplateCode);
    end;

    /// <summary>
    /// Builds a Day Planning Pattern record directly via Init/field-assignment (no Validate calls),
    /// so the "Resource No." OnValidate auto-fill trigger never fires and masks the scenario under test.
    /// Caller still must Modify() any further field changes via SetRange-like direct assignment, then call
    /// DayPlanningPattern.Insert() once fields are final (table has no OnInsert side effects that matter here).
    /// </summary>
    local procedure CreateBaseDayPlanningPattern(var DayPlanningPattern: Record "Day Planning Pattern"; LineNo: Integer)
    begin
        DayPlanningPattern.Init();
        DayPlanningPattern."Job No." := TestJobNo;
        DayPlanningPattern."Job Task No." := TestJobTaskNo;
        DayPlanningPattern."Line No." := LineNo;
        DayPlanningPattern."Resource No." := TestResourceNo;
        DayPlanningPattern.SkillsRequired := TestSkillCode;
        DayPlanningPattern."Work-Hour Template" := TestWorkHourTemplateCode;
        DayPlanningPattern."Quantity of Lines" := 1;
        DayPlanningPattern."Start Time" := 080000T;
        DayPlanningPattern."End Time" := 170000T;
    end;

    local procedure ClearDayPlanningsFor(JobNo: Code[20]; JobTaskNo: Code[20])
    var
        DayPlanning: Record "Day Planning";
        DayPlanningPattern: Record "Day Planning Pattern";
    begin
        // al_run_tests does not appear to roll back data between test methods the way the
        // BC Test Tool does, so each test must clear its own prior-method leftovers explicitly
        // rather than relying on automatic per-test transaction rollback.
        DayPlanning.SetRange("Job No.", JobNo);
        DayPlanning.SetRange("Job Task No.", JobTaskNo);
        DayPlanning.DeleteAll();

        DayPlanningPattern.SetRange("Job No.", JobNo);
        DayPlanningPattern.SetRange("Job Task No.", JobTaskNo);
        DayPlanningPattern.DeleteAll();
    end;

    local procedure AssertAreEqual(Expected: Variant; Actual: Variant; ErrMsg: Text)
    var
        ExpectedText: Text;
        ActualText: Text;
    begin
        ExpectedText := Format(Expected);
        ActualText := Format(Actual);
        if ExpectedText <> ActualText then
            Error('%1 Expected: %2, Actual: %3', ErrMsg, ExpectedText, ActualText);
    end;

    local procedure AssertIsTrue(Condition: Boolean; ErrMsg: Text)
    begin
        if not Condition then
            Error(ErrMsg);
    end;

    [MessageHandler]
    procedure MessageHandler(Msg: Text[1024])
    begin
        // CreateDayPlanning() ends with a confirmation Message() on success - just dismiss it.
    end;

    local procedure AssertExpectedErrorContains(ExpectedText: Text)
    var
        ActualText: Text;
    begin
        ActualText := GetLastErrorText();
        if StrPos(ActualText, ExpectedText) = 0 then
            Error('Expected error containing: "%1", but got: "%2"', ExpectedText, ActualText);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure GivenMondayToFridayPattern_WhenCreateDayPlanning_ThenFiveDayPlanningLinesCreated()
    var
        DayPlanningPattern: Record "Day Planning Pattern";
        DayPlanning: Record "Day Planning";
        DayPlanningsMgt: Codeunit "Day Plannings Mgt.";
        StartDate: Date;
        EndDate: Date;
        DayCount: Integer;
    begin
        // [GIVEN] Clean state and a pattern covering a known Monday..Friday range, using the shared
        // default Work-Hour Template (TestWorkHourTemplateCode) which has Monday..Friday active.
        Initialize();
        ClearDayPlanningsFor(TestJobNo, TestJobTaskNo);

        StartDate := GetKnownMonday();
        EndDate := CalcDate('<+4D>', StartDate); // Mon..Fri

        CreateBaseDayPlanningPattern(DayPlanningPattern, 10000);
        DayPlanningPattern."Start Date" := StartDate;
        DayPlanningPattern."End Date" := EndDate;
        DayPlanningPattern.Insert();

        // [WHEN] CreateDayPlanning is called
        DayPlanningsMgt.CreateDayPlanning(DayPlanningPattern);

        // [THEN] Exactly 5 Day Planning records are created, one per weekday, with correct data copied
        DayPlanning.SetRange("Job No.", TestJobNo);
        DayPlanning.SetRange("Job Task No.", TestJobTaskNo);
        DayCount := DayPlanning.Count();
        AssertAreEqual(5, DayCount, 'Expected exactly 5 Day Planning records for a Mon-Fri pattern with Mon-Fri active in the Work-Hour Template.');

        DayPlanning.SetRange("Work Date", StartDate);
        AssertIsTrue(DayPlanning.FindFirst(), 'Expected a Day Planning record on the pattern start date.');
        AssertAreEqual(TestResourceNo, DayPlanning."Assigned Resource No.", 'Assigned Resource No. should be copied from the pattern.');
        AssertAreEqual(TestSkillCode, DayPlanning.Skill, 'Skill should be copied from the pattern.');
        AssertAreEqual(080000T, DayPlanning."Start Time Assigned", 'Start Time Assigned should match the pattern Start Time.');
        AssertAreEqual(170000T, DayPlanning."End Time Assigned", 'End Time Assigned should match the pattern End Time.');
        AssertAreEqual(10000, DayPlanning."Day Line No.", 'First line of the day should use Day Line No. 10000.');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure GivenQuantityOfLinesTwo_WhenCreateDayPlanning_ThenTwoLinesCreatedForThatDay()
    var
        DayPlanningPattern: Record "Day Planning Pattern";
        DayPlanning: Record "Day Planning";
        DayPlanningsMgt: Codeunit "Day Plannings Mgt.";
        SingleDay: Date;
        DayCount: Integer;
    begin
        // [GIVEN] A pattern for a single qualifying day with Quantity of Lines = 2. Uses a dedicated
        // Monday-only Work-Hour Template so the "single qualifying day" scenario stays isolated
        // (the shared default template now has all of Mon-Fri active).
        Initialize();
        ClearDayPlanningsFor(TestJobNo, TestJobTaskNo);

        SingleDay := GetKnownMonday();

        CreateBaseDayPlanningPattern(DayPlanningPattern, 10000);
        DayPlanningPattern."Work-Hour Template" := CreateMondayOnlyWorkHourTemplate();
        DayPlanningPattern."Start Date" := SingleDay;
        DayPlanningPattern."End Date" := SingleDay;
        DayPlanningPattern."Quantity of Lines" := 2;
        DayPlanningPattern.Insert();

        // [WHEN] CreateDayPlanning is called
        DayPlanningsMgt.CreateDayPlanning(DayPlanningPattern);

        // [THEN] 2 Day Planning lines are created for that date: Day Line No. 10000 and 20000
        DayPlanning.SetRange("Job No.", TestJobNo);
        DayPlanning.SetRange("Job Task No.", TestJobTaskNo);
        DayPlanning.SetRange("Work Date", SingleDay);
        DayCount := DayPlanning.Count();
        AssertAreEqual(2, DayCount, 'Expected exactly 2 Day Planning lines for the single qualifying day with Quantity of Lines = 2.');

        AssertIsTrue(DayPlanning.Get(TestJobNo, TestJobTaskNo, 10000), 'Expected a Day Planning record with Day Line No. 10000.');
        AssertIsTrue(DayPlanning.Get(TestJobNo, TestJobTaskNo, 20000), 'Expected a Day Planning record with Day Line No. 20000.');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure GivenVendorNoSetWithQtyGreaterThanOne_WhenCreateDayPlanning_ThenQtyForcedToOneAndOneLineCreated()
    var
        DayPlanningPattern: Record "Day Planning Pattern";
        DayPlanning: Record "Day Planning";
        DayPlanningsMgt: Codeunit "Day Plannings Mgt.";
        Vendor: Record Vendor;
        SingleDay: Date;
        DayCount: Integer;
    begin
        // [GIVEN] A pattern with Vendor No. set and Quantity of Lines initially > 1
        Initialize();
        ClearDayPlanningsFor(TestJobNo, TestJobTaskNo);

        if not Vendor.Get('DPCTVEND') then begin
            Vendor.Init();
            Vendor."No." := 'DPCTVEND';
            Vendor.Name := 'Day Planning Creation Test Vendor';
            Vendor.Insert();
        end;

        SingleDay := GetKnownMonday();

        CreateBaseDayPlanningPattern(DayPlanningPattern, 10000);
        DayPlanningPattern."Start Date" := SingleDay;
        DayPlanningPattern."End Date" := SingleDay;
        DayPlanningPattern."Quantity of Lines" := 3;
        DayPlanningPattern."Vendor No." := Vendor."No.";
        DayPlanningPattern.Insert();

        // [WHEN] CreateDayPlanning is called
        DayPlanningsMgt.CreateDayPlanning(DayPlanningPattern);

        // [THEN] The pattern's Quantity of Lines is forced to 1
        DayPlanningPattern.Get(TestJobNo, TestJobTaskNo, 10000);
        AssertAreEqual(1, DayPlanningPattern."Quantity of Lines", 'Quantity of Lines should be forced to 1 when Vendor No. is set.');

        // [THEN] Only 1 Day Planning line is created for the qualifying day
        DayPlanning.SetRange("Job No.", TestJobNo);
        DayPlanning.SetRange("Job Task No.", TestJobTaskNo);
        DayPlanning.SetRange("Work Date", SingleDay);
        DayCount := DayPlanning.Count();
        AssertAreEqual(1, DayCount, 'Expected exactly 1 Day Planning line when Vendor No. is set, regardless of original Quantity of Lines.');
        AssertIsTrue(DayPlanning.FindFirst(), 'Expected a Day Planning record to exist for the qualifying day.');
        AssertAreEqual(Vendor."No.", DayPlanning."Vendor No.", 'Vendor No. should be copied from the pattern.');
    end;

    [Test]
    procedure GivenBlankResourceAndSkill_WhenCreateDayPlanning_ThenSkillsRequiredErrorRaised()
    var
        DayPlanningPattern: Record "Day Planning Pattern";
        DayPlanningsMgt: Codeunit "Day Plannings Mgt.";
    begin
        // [GIVEN] A pattern with both Resource No. and SkillsRequired blank, set directly (no Validate call)
        // so the Resource No. OnValidate auto-fill trigger never fires and cannot mask the scenario.
        Initialize();
        ClearDayPlanningsFor(TestJobNo, TestJobTaskNo);

        CreateBaseDayPlanningPattern(DayPlanningPattern, 10000);
        DayPlanningPattern."Resource No." := '';
        DayPlanningPattern.SkillsRequired := '';
        DayPlanningPattern."Start Date" := GetKnownMonday();
        DayPlanningPattern."End Date" := GetKnownMonday();
        DayPlanningPattern.Insert();

        // [WHEN] CreateDayPlanning is called [THEN] it raises the custom 'Skills Required' error
        asserterror DayPlanningsMgt.CreateDayPlanning(DayPlanningPattern);
        AssertExpectedErrorContains('Skills Required must be specified');
    end;

    [Test]
    procedure GivenBlankStartDate_WhenCreateDayPlanning_ThenPlannedStartDateErrorRaised()
    var
        DayPlanningPattern: Record "Day Planning Pattern";
        DayPlanningsMgt: Codeunit "Day Plannings Mgt.";
    begin
        // [GIVEN] A pattern with Start Date = 0D (all other required fields valid)
        Initialize();
        ClearDayPlanningsFor(TestJobNo, TestJobTaskNo);

        CreateBaseDayPlanningPattern(DayPlanningPattern, 10000);
        DayPlanningPattern."Start Date" := 0D;
        DayPlanningPattern."End Date" := GetKnownMonday();
        DayPlanningPattern.Insert();

        // [WHEN] CreateDayPlanning is called [THEN] it raises the custom 'Planned Start Date' error
        asserterror DayPlanningsMgt.CreateDayPlanning(DayPlanningPattern);
        AssertExpectedErrorContains('Planned Start Date must be specified');
    end;

    [Test]
    procedure GivenBlankStartOrEndTime_WhenCreateDayPlanning_ThenStartEndTimeErrorRaised()
    var
        DayPlanningPattern: Record "Day Planning Pattern";
        DayPlanningsMgt: Codeunit "Day Plannings Mgt.";
        SingleDay: Date;
    begin
        // [GIVEN] A pattern with valid dates but Start Time = 0T
        Initialize();
        ClearDayPlanningsFor(TestJobNo, TestJobTaskNo);

        SingleDay := GetKnownMonday();

        CreateBaseDayPlanningPattern(DayPlanningPattern, 10000);
        DayPlanningPattern."Start Date" := SingleDay;
        DayPlanningPattern."End Date" := SingleDay;
        DayPlanningPattern."Start Time" := 0T;
        DayPlanningPattern.Insert();

        // [WHEN] CreateDayPlanning is called [THEN] it raises the custom 'Start Time and End Time' error
        asserterror DayPlanningsMgt.CreateDayPlanning(DayPlanningPattern);
        AssertExpectedErrorContains('Start Time and End Time must be specified');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure GivenSingleDayNotCheckedAsWeekday_WhenCreateDayPlanning_ThenNoDayPlanningLinesCreated()
    var
        DayPlanningPattern: Record "Day Planning Pattern";
        DayPlanning: Record "Day Planning";
        DayPlanningsMgt: Codeunit "Day Plannings Mgt.";
        SingleDay: Date;
    begin
        // [GIVEN] A single-day range whose weekday (Monday) is NOT active in the Work-Hour Template,
        // while Tuesday IS active in that same template. The range covers only the Monday, so even
        // though the template has a qualifying weekday configured (Tuesday), it's out of range, so
        // no day in the range qualifies.
        Initialize();
        ClearDayPlanningsFor(TestJobNo, TestJobTaskNo);

        SingleDay := GetKnownMonday();

        CreateBaseDayPlanningPattern(DayPlanningPattern, 10000);
        DayPlanningPattern."Work-Hour Template" := CreateTuesdayOnlyWorkHourTemplate();
        DayPlanningPattern."Start Date" := SingleDay;
        DayPlanningPattern."End Date" := SingleDay;
        DayPlanningPattern.Insert();

        // [WHEN] CreateDayPlanning is called
        DayPlanningsMgt.CreateDayPlanning(DayPlanningPattern);

        // [THEN] No Day Planning records are created, and no error is raised
        DayPlanning.SetRange("Job No.", TestJobNo);
        DayPlanning.SetRange("Job Task No.", TestJobTaskNo);
        AssertIsTrue(DayPlanning.IsEmpty(), 'Expected no Day Planning records when the only day in range is not a checked weekday.');
    end;

    /// <summary>
    /// Returns a date that is guaranteed to be a Monday, at least one week in the future,
    /// so tests are stable regardless of which day "Today" happens to be when the suite runs.
    /// </summary>
    local procedure GetKnownMonday(): Date
    var
        NextWeek: Date;
        DayOfWeek: Integer;
    begin
        NextWeek := CalcDate('<+7D>', Today);
        DayOfWeek := Date2DWY(NextWeek, 1); // 1 = Monday .. 7 = Sunday
        exit(NextWeek - (DayOfWeek - 1));
    end;
}
