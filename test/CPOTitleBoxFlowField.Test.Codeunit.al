codeunit 60030 "CPO Title Box FlowField Tests"
{
    // Settles a long-running question from the 2026-09-15 Capacity Planning Overview (page 50722)
    // "title-bar audit box" saga (see .claude\agent-memory\al-bc-developer\
    // project_cpo_section3_exclude_flip_2026-09-15.md, section "FIFTH AND FINAL DESIGN"): the box
    // shows "Requested: N hours | Assigned: N hours" for a single Job Task, computed via
    // tableext 50605 "Job Task ext"'s FlowFields "Total Requested Hours" (50691) / "Total Assigned
    // Hours" (50690) - both sum(...) over table 50610 "Day Planning", filtered by the base-app
    // FlowFilter field "Planning Date Filter" on Job Task. Live testing against Job 10000/Task 1080
    // in CRONUS NL always showed 0/0; extensive prior live investigation concluded this was correct
    // for THAT specific test case (its only real demand sits before "today"'s window), but nobody
    // had isolated the FlowFormula/FlowFilter mechanics from that one test case's own data shape.
    // This codeunit builds a dedicated, deterministic dataset (NOT the shared 'DPCT-JOB' test Job/
    // Task used by test\DayPlanningCreation.Test.Codeunit.al) with known Requested/Assigned Hours
    // spread across dates that straddle an arbitrary FlowFilter window on both edges, to prove
    // (or disprove) the FlowField/FlowFilter arithmetic independently of any specific live scenario.
    Subtype = Test;
    TestPermissions = Disabled;

    var
        IsInitialized: Boolean;
        TestJobNo: Code[20];
        TestJobTaskNo: Code[20];

    local procedure Initialize()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
    begin
        TestJobNo := 'CPOTB-JOB';
        TestJobTaskNo := '1000';

        if IsInitialized then
            exit;

        // [GIVEN] A dedicated Job + Job Task, isolated from every other test codeunit's own test data
        if not Job.Get(TestJobNo) then begin
            Job.Init();
            Job."No." := TestJobNo;
            Job.Description := 'CPO Title Box FlowField Test Job';
            Job.Insert();
        end;
        if not JobTask.Get(TestJobNo, TestJobTaskNo) then begin
            JobTask.Init();
            JobTask."Job No." := TestJobNo;
            JobTask."Job Task No." := TestJobTaskNo;
            JobTask.Description := 'CPO Title Box FlowField Test Job Task';
            JobTask."Job Task Type" := JobTask."Job Task Type"::Posting;
            JobTask.Insert();
        end;
        // Wide-open planned dates - not strictly required since this codeunit never calls
        // Validate("Plan Date", ...) (see InsertDayPlanningDirect below), but kept for consistency
        // with this project's established test convention (test\DayPlanningCreation.Test.Codeunit.al)
        // in case a future edit here ever does start validating dates.
        JobTask.PlannedStartDate := 0D;
        JobTask.PlannedEndDate := 0D;
        JobTask.Modify();

        IsInitialized := true;
        Commit();
    end;

    local procedure ClearDayPlanningsFor(JobNo: Code[20]; JobTaskNo: Code[20])
    var
        DayPlanning: Record "Day Planning";
    begin
        // al_run_tests does not appear to roll back data between test methods the way the BC Test
        // Tool does, so each test must clear its own prior-method leftovers explicitly (same
        // convention as test\DayPlanningCreation.Test.Codeunit.al / DayPlanningSequenceNo.Test.Codeunit.al).
        // Plain DeleteAll() (RunTrigger defaults to false) does NOT fire OnDelete, so the
        // TestField("Assigned Hours", 0) / TestField("Realized Hours", 0) guards in that trigger
        // are never hit even though this codeunit deliberately leaves non-zero Assigned Hours on
        // several test lines.
        DayPlanning.SetRange("Job No.", JobNo);
        DayPlanning.SetRange("Job Task No.", JobTaskNo);
        DayPlanning.DeleteAll();
    end;

    /// <summary>
    /// A date guaranteed stable within a single test run (Today() does not change mid-run),
    /// arbitrarily 14 days out so it never collides with "today" itself.
    /// </summary>
    local procedure GetWindowStart(): Date
    begin
        exit(CalcDate('<+14D>', Today()));
    end;

    /// <summary>10-day window: GetWindowStart()..GetWindowEnd(), inclusive both ends.</summary>
    local procedure GetWindowEnd(): Date
    begin
        exit(CalcDate('<+9D>', GetWindowStart()));
    end;

    /// <summary>
    /// Inserts one Day Planning record via plain Init/field-assignment/Insert() - deliberately NOT
    /// Validate() on any field and NOT Insert(true) - so neither "Plan Date"'s OnValidate
    /// (EnsureJobTaskCoversDate, can error if the date falls outside the Job Task's planned range)
    /// nor "Assigned Hours"'s OnValidate (AssignedCheck) nor the table's own OnInsert trigger (which
    /// would Get() the "Daily Optimizer Setup" singleton when Skill is blank, an unrelated
    /// dependency this test has no need to pull in) ever fire. FlowFields read the underlying table
    /// values directly regardless of which triggers ran at insert time, so this is a safe,
    /// deterministic way to seed exactly the Requested/Assigned Hours values under test - the same
    /// pattern test\DayPlanningCreation.Test.Codeunit.al's own doc comments recommend.
    /// </summary>
    local procedure InsertDayPlanningDirect(DayLineNo: Integer; PlanDate: Date; RequestedHours: Decimal; AssignedHours: Decimal)
    var
        DayPlanning: Record "Day Planning";
    begin
        DayPlanning.Init();
        DayPlanning."Job No." := TestJobNo;
        DayPlanning."Job Task No." := TestJobTaskNo;
        DayPlanning."Day Line No." := DayLineNo;
        DayPlanning."Plan Date" := PlanDate;
        DayPlanning."Requested Hours" := RequestedHours;
        DayPlanning."Assigned Hours" := AssignedHours;
        DayPlanning.Insert();
    end;

    /// <summary>
    /// Five lines straddling the GetWindowStart()/GetWindowEnd() window on both edges:
    /// - Day Line No. 10000: WindowStart - 1D (one day BEFORE the window) - Requested 5 / Assigned 3
    /// - Day Line No. 20000: WindowStart itself (start boundary)          - Requested 10 / Assigned 6
    /// - Day Line No. 30000: WindowStart + 5D (comfortably inside)        - Requested 7 / Assigned 4
    /// - Day Line No. 40000: WindowEnd itself (end boundary)              - Requested 8 / Assigned 2
    /// - Day Line No. 50000: WindowEnd + 1D (one day AFTER the window)    - Requested 9 / Assigned 1
    /// In-window sum (boundary + boundary + middle) = 25 Requested / 12 Assigned.
    /// Out-of-window sum (day-before + day-after) = 14 Requested / 10 Assigned - if either FlowField
    /// wrongly included these, the in-window sum assertions below would fail with 39/22 instead.
    /// </summary>
    local procedure CreateStandardTestLines()
    var
        WindowStart: Date;
        WindowEnd: Date;
    begin
        WindowStart := GetWindowStart();
        WindowEnd := GetWindowEnd();
        InsertDayPlanningDirect(10000, CalcDate('<-1D>', WindowStart), 5, 3);
        InsertDayPlanningDirect(20000, WindowStart, 10, 6);
        InsertDayPlanningDirect(30000, CalcDate('<+5D>', WindowStart), 7, 4);
        InsertDayPlanningDirect(40000, WindowEnd, 8, 2);
        InsertDayPlanningDirect(50000, CalcDate('<+1D>', WindowEnd), 9, 1);
    end;

    /// <summary>
    /// Mirrors exactly what tableext 50605's FlowFields are used for in
    /// codeunit_50604_DHXDataHandler.al's CPO_BuildPlanningDataJson_Paged: Get() the Job Task,
    /// SetRange the "Planning Date Filter" FlowFilter, CalcFields both FlowFields.
    /// </summary>
    local procedure GetTaskTotals(WindowStart: Date; WindowEnd: Date; var RequestedHours: Decimal; var AssignedHours: Decimal)
    var
        JobTask: Record "Job Task";
    begin
        JobTask.Get(TestJobNo, TestJobTaskNo);
        JobTask.SetRange("Planning Date Filter", WindowStart, WindowEnd);
        JobTask.CalcFields("Total Requested Hours", "Total Assigned Hours");
        RequestedHours := JobTask."Total Requested Hours";
        AssignedHours := JobTask."Total Assigned Hours";
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

    [Test]
    procedure GivenLinesInsideAndOutsideWindow_WhenCalcFieldsWithFlowFilter_ThenOnlyInWindowLinesSummed()
    var
        RequestedHours: Decimal;
        AssignedHours: Decimal;
    begin
        // [GIVEN] Clean state and 5 lines straddling a 10-day window on both edges
        Initialize();
        ClearDayPlanningsFor(TestJobNo, TestJobTaskNo);
        CreateStandardTestLines();

        // [WHEN] The FlowFilter is set to exactly the 10-day window and both FlowFields are calculated
        GetTaskTotals(GetWindowStart(), GetWindowEnd(), RequestedHours, AssignedHours);

        // [THEN] Only the 3 in-window lines (start boundary + middle + end boundary) are summed;
        // the day-before and day-after lines are excluded
        AssertAreEqual(25, RequestedHours,
            'Total Requested Hours across the 10-day window (boundary+middle+boundary lines only, excluding day-before/day-after).');
        AssertAreEqual(12, AssignedHours,
            'Total Assigned Hours across the 10-day window (boundary+middle+boundary lines only, excluding day-before/day-after).');
    end;

    [Test]
    procedure GivenWindowWithNoMatchingLines_WhenCalcFieldsWithFlowFilter_ThenBothFlowFieldsReturnZero()
    var
        RequestedHours: Decimal;
        AssignedHours: Decimal;
        FarWindowStart: Date;
        FarWindowEnd: Date;
    begin
        // [GIVEN] The same 5 lines as the main test, all dated near GetWindowStart()/GetWindowEnd()
        Initialize();
        ClearDayPlanningsFor(TestJobNo, TestJobTaskNo);
        CreateStandardTestLines();

        // [WHEN] The FlowFilter is set to a window far away from every seeded line
        FarWindowStart := CalcDate('<+1000D>', GetWindowStart());
        FarWindowEnd := CalcDate('<+9D>', FarWindowStart);
        GetTaskTotals(FarWindowStart, FarWindowEnd, RequestedHours, AssignedHours);

        // [THEN] Both FlowFields come back exactly 0 - the legitimately-zero case, not a bug
        AssertAreEqual(0, RequestedHours,
            'Total Requested Hours must be exactly 0 for a window containing none of this Job Task''s Day Planning lines - legitimately-zero, not a bug.');
        AssertAreEqual(0, AssignedHours,
            'Total Assigned Hours must be exactly 0 for a window containing none of this Job Task''s Day Planning lines - legitimately-zero, not a bug.');
    end;

    [Test]
    procedure GivenFlowFilterExactlyOnStartBoundaryDate_WhenCalcFields_ThenOnlyStartBoundaryLineIncluded()
    var
        RequestedHours: Decimal;
        AssignedHours: Decimal;
        WindowStart: Date;
    begin
        // [GIVEN] The same 5 lines, including one exactly on the start boundary and one exactly one day before it
        Initialize();
        ClearDayPlanningsFor(TestJobNo, TestJobTaskNo);
        CreateStandardTestLines();

        // [WHEN] The FlowFilter window is collapsed to a single day: exactly the start boundary date
        WindowStart := GetWindowStart();
        GetTaskTotals(WindowStart, WindowStart, RequestedHours, AssignedHours);

        // [THEN] Only the start-boundary line (Requested 10 / Assigned 6) is included - SetRange is
        // inclusive, so a date exactly ON the window start counts as IN-range - and the day-before
        // line (Requested 5 / Assigned 3) is excluded
        AssertAreEqual(10, RequestedHours,
            'A FlowFilter window collapsed to exactly the start-boundary date must include that date''s line (SetRange is inclusive) and exclude the day-before line.');
        AssertAreEqual(6, AssignedHours,
            'A FlowFilter window collapsed to exactly the start-boundary date must include that date''s line (SetRange is inclusive) and exclude the day-before line.');
    end;

    [Test]
    procedure GivenFlowFilterExactlyOnEndBoundaryDate_WhenCalcFields_ThenOnlyEndBoundaryLineIncluded()
    var
        RequestedHours: Decimal;
        AssignedHours: Decimal;
        WindowEnd: Date;
    begin
        // [GIVEN] The same 5 lines, including one exactly on the end boundary and one exactly one day after it
        Initialize();
        ClearDayPlanningsFor(TestJobNo, TestJobTaskNo);
        CreateStandardTestLines();

        // [WHEN] The FlowFilter window is collapsed to a single day: exactly the end boundary date
        WindowEnd := GetWindowEnd();
        GetTaskTotals(WindowEnd, WindowEnd, RequestedHours, AssignedHours);

        // [THEN] Only the end-boundary line (Requested 8 / Assigned 2) is included - SetRange is
        // inclusive, so a date exactly ON the window end counts as IN-range - and the day-after
        // line (Requested 9 / Assigned 1) is excluded
        AssertAreEqual(8, RequestedHours,
            'A FlowFilter window collapsed to exactly the end-boundary date must include that date''s line (SetRange is inclusive) and exclude the day-after line.');
        AssertAreEqual(2, AssignedHours,
            'A FlowFilter window collapsed to exactly the end-boundary date must include that date''s line (SetRange is inclusive) and exclude the day-after line.');
    end;
}
