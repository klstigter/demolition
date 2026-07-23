codeunit 60022 "Summary View Pair Cols Tests"
{
    // Tests for table 50612 "Summary Weekly" - procedure FillSummary(ResourceNo, JobNo, JobTaskNo)
    // Covers the Requested/Assigned paired-column enhancement used by page 50626 "Summary View":
    // each weekday (and Total) must carry independent Requested and Assigned hour totals on the
    // same buffer row, sourced from "Day Planning"."Requested Hours" / "Assigned Hours".
    Subtype = Test;
    TestPermissions = Disabled;

    var
        IsInitialized: Boolean;
        TestJobNo: Code[20];
        TestJobTaskNo: Code[20];
        TestResourceNo: Code[20];
        TestSkillCode: Code[10];

    local procedure Initialize()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
    begin
        TestJobNo := 'SVPCT-JOB';
        TestJobTaskNo := '1000';

        if IsInitialized then
            exit;

        if not Job.Get(TestJobNo) then begin
            Job.Init();
            Job."No." := TestJobNo;
            Job.Description := 'Summary View Pair Columns Test Job';
            Job.Insert();
        end;
        if not JobTask.Get(TestJobNo, TestJobTaskNo) then begin
            JobTask.Init();
            JobTask."Job No." := TestJobNo;
            JobTask."Job Task No." := TestJobTaskNo;
            JobTask.Description := 'Summary View Pair Columns Test Job Task';
            JobTask."Job Task Type" := JobTask."Job Task Type"::Posting;
            JobTask.Insert();
        end;

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
        ResNo := 'SVPCTRES';
        if not Resource.Get(ResNo) then begin
            Resource.Init();
            Resource."No." := ResNo;
            Resource.Name := 'Summary View Pair Columns Test Resource';
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
        Code10 := 'SVPCTSKL';
        if not SkillCode.Get(Code10) then begin
            SkillCode.Init();
            SkillCode.Code := Code10;
            SkillCode.Description := 'Summary View Pair Columns Test Skill';
            SkillCode.Insert();
        end;
        exit(Code10);
    end;

    local procedure ClearDayPlanningsFor(JobNo: Code[20]; JobTaskNo: Code[20])
    var
        DayPlanning: Record "Day Planning";
    begin
        // al_run_tests does not appear to roll back data between test methods, so each test
        // must clear its own prior-method leftovers explicitly.
        DayPlanning.SetRange("Job No.", JobNo);
        DayPlanning.SetRange("Job Task No.", JobTaskNo);
        DayPlanning.DeleteAll();
    end;

    local procedure CreateDayPlanning(TaskDate: Date; DayLineNo: Integer; AssignedResourceNo: Code[20]; RequestedHours: Decimal; AssignedHours: Decimal)
    var
        DayPlanning: Record "Day Planning";
    begin
        // Fields are assigned directly (no Validate calls) so CalculateWorkingHours() never
        // recomputes/overwrites the Requested/Assigned Hours under test.
        DayPlanning.Init();
        DayPlanning."Job No." := TestJobNo;
        DayPlanning."Job Task No." := TestJobTaskNo;
        DayPlanning."Day Line No." := DayLineNo;
        DayPlanning."Task Date" := TaskDate;
        DayPlanning."Assigned Resource No." := AssignedResourceNo;
        DayPlanning.Skill := TestSkillCode;
        DayPlanning."Requested Hours" := RequestedHours;
        DayPlanning."Assigned Hours" := AssignedHours;
        DayPlanning.Insert();
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

    /// <summary>
    /// Returns a date guaranteed to be a Monday, at least one week in the future, so tests are
    /// stable regardless of which day "Today" happens to be when the suite runs.
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

    [Test]
    procedure GivenAssignedDayPlanning_WhenFillSummary_ThenRequestedAndAssignedColumnsBothPopulatedOnSameRow()
    var
        SummaryWeekly: Record "Summary Weekly";
        Monday: Date;
    begin
        // [GIVEN] A Day Planning assigned to a resource on a known Monday, with different
        // Requested Hours (8) and Assigned Hours (6) so the two columns cannot be confused.
        Initialize();
        ClearDayPlanningsFor(TestJobNo, TestJobTaskNo);

        Monday := GetKnownMonday();
        CreateDayPlanning(Monday, 10000, TestResourceNo, 8, 6);

        // [WHEN] The Summary Weekly buffer is filled for that resource/job/task
        SummaryWeekly.FillSummary(TestResourceNo, TestJobNo, TestJobTaskNo);

        // [THEN] Exactly one row exists for the resource, with Monday Requested/Assigned and
        // Total Requested/Assigned holding their own independent values.
        SummaryWeekly.SetRange("Resource No.", TestResourceNo);
        SummaryWeekly.SetRange("Job No.", TestJobNo);
        SummaryWeekly.SetRange("Job Task No.", TestJobTaskNo);
        AssertAreEqual(1, SummaryWeekly.Count(), 'Expected exactly one Summary Weekly row for the assigned resource.');
        AssertIsTrue(SummaryWeekly.FindFirst(), 'Expected to find the Summary Weekly row.');

        AssertAreEqual(8, SummaryWeekly."Monday Requested Hours", 'Monday Requested Hours should equal the Day Planning Requested Hours.');
        AssertAreEqual(6, SummaryWeekly."Monday Assigned Hours", 'Monday Assigned Hours should equal the Day Planning Assigned Hours.');
        AssertAreEqual(8, SummaryWeekly."Total Requested Hours", 'Total Requested Hours should equal the single day''s Requested Hours.');
        AssertAreEqual(6, SummaryWeekly."Total Assigned Hours", 'Total Assigned Hours should equal the single day''s Assigned Hours.');

        // [THEN] The other weekday pairs remain zero (no bleed into unrelated days).
        AssertAreEqual(0, SummaryWeekly."Tuesday Requested Hours", 'Tuesday Requested Hours should be zero.');
        AssertAreEqual(0, SummaryWeekly."Tuesday Assigned Hours", 'Tuesday Assigned Hours should be zero.');
    end;

    [Test]
    procedure GivenUnassignedDayPlanning_WhenFillSummary_ThenRequestedPopulatedAndAssignedStaysZero()
    var
        SummaryWeekly: Record "Summary Weekly";
        Tuesday: Date;
    begin
        // [GIVEN] A Day Planning with no Assigned Resource No. (open demand), Requested Hours = 5
        // and Assigned Hours = 0, on a known Tuesday.
        Initialize();
        ClearDayPlanningsFor(TestJobNo, TestJobTaskNo);

        Tuesday := CalcDate('<+1D>', GetKnownMonday());
        CreateDayPlanning(Tuesday, 10000, '', 5, 0);

        // [WHEN] The Summary Weekly buffer is filled for the job/task (no resource filter)
        SummaryWeekly.FillSummary('', TestJobNo, TestJobTaskNo);

        // [THEN] The unassigned row (blank Resource No.) shows Requested without Assigned
        SummaryWeekly.SetRange("Resource No.", '');
        SummaryWeekly.SetRange("Job No.", TestJobNo);
        SummaryWeekly.SetRange("Job Task No.", TestJobTaskNo);
        AssertIsTrue(SummaryWeekly.FindFirst(), 'Expected to find the unassigned Summary Weekly row.');

        AssertAreEqual(5, SummaryWeekly."Tuesday Requested Hours", 'Tuesday Requested Hours should equal the open demand''s Requested Hours.');
        AssertAreEqual(0, SummaryWeekly."Tuesday Assigned Hours", 'Tuesday Assigned Hours should remain zero for unassigned demand.');
        AssertAreEqual(5, SummaryWeekly."Total Requested Hours", 'Total Requested Hours should equal the single day''s Requested Hours.');
        AssertAreEqual(0, SummaryWeekly."Total Assigned Hours", 'Total Assigned Hours should remain zero for unassigned demand.');
    end;

    [Test]
    procedure GivenDayPlanningsOnTwoWeekdays_WhenFillSummary_ThenEachDayPairAccumulatesIndependently()
    var
        SummaryWeekly: Record "Summary Weekly";
        Monday: Date;
    begin
        // [GIVEN] Two Day Plannings for the same assigned resource/week: Monday (Requested 4,
        // Assigned 4) and Wednesday (Requested 3, Assigned 2).
        Initialize();
        ClearDayPlanningsFor(TestJobNo, TestJobTaskNo);

        Monday := GetKnownMonday();
        CreateDayPlanning(Monday, 10000, TestResourceNo, 4, 4);
        CreateDayPlanning(CalcDate('<+2D>', Monday), 20000, TestResourceNo, 3, 2);

        // [WHEN] The Summary Weekly buffer is filled for that resource/job/task
        SummaryWeekly.FillSummary(TestResourceNo, TestJobNo, TestJobTaskNo);

        // [THEN] Monday and Wednesday pairs hold their own values, and Totals sum across both days
        SummaryWeekly.SetRange("Resource No.", TestResourceNo);
        SummaryWeekly.SetRange("Job No.", TestJobNo);
        SummaryWeekly.SetRange("Job Task No.", TestJobTaskNo);
        AssertIsTrue(SummaryWeekly.FindFirst(), 'Expected to find the Summary Weekly row.');

        AssertAreEqual(4, SummaryWeekly."Monday Requested Hours", 'Monday Requested Hours mismatch.');
        AssertAreEqual(4, SummaryWeekly."Monday Assigned Hours", 'Monday Assigned Hours mismatch.');
        AssertAreEqual(3, SummaryWeekly."Wednesday Requested Hours", 'Wednesday Requested Hours mismatch.');
        AssertAreEqual(2, SummaryWeekly."Wednesday Assigned Hours", 'Wednesday Assigned Hours mismatch.');
        AssertAreEqual(7, SummaryWeekly."Total Requested Hours", 'Total Requested Hours should sum both days.');
        AssertAreEqual(6, SummaryWeekly."Total Assigned Hours", 'Total Assigned Hours should sum both days.');
    end;
}
