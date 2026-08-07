codeunit 60024 "Skill Capacity Chart Tests"
{
    // Tests for codeunit 50662 "Skill Capacity Analysis Mgt." - procedure
    // BuildDayCapacityChartData(PeriodStartDate; ResourceNoFilter; ScenarioNo).
    // Asserts directly against the returned chart JSON (categories/series with name/values/
    // color/[border]/stacked keys) rather than going through page 50692's UI - see the
    // procedure's own doc comment for the exact contract.
    Subtype = Test;
    TestPermissions = Disabled;

    var
        TestJobNo: Code[20];
        TestJobTaskNo: Code[20];
        SkillCapacityAnalysisMgt: Codeunit "Skill Capacity Analysis Mgt.";

    local procedure Initialize()
    begin
        TestJobNo := 'SCCTJOB';
        TestJobTaskNo := '1000';
    end;

    // ================================================================
    // GIVEN-data helpers
    // ================================================================

    /// <summary>
    /// A Monday-anchored 5-day period, offset WeeksAhead weeks from today so each test can use
    /// its own non-overlapping period (Day Planning's "Day Line No." is unique per Job No./Job
    /// Task No. only, not per date, so distinct periods keep tests from ever needing to share
    /// line numbers or worry about leftover rows from a different test's period).
    /// </summary>
    local procedure GetTestMonday(WeeksAhead: Integer): Date
    var
        CandidateDate: Date;
        DayOfWeek: Integer;
    begin
        CandidateDate := CalcDate(StrSubstNo('<+%1W>', WeeksAhead), Today);
        DayOfWeek := Date2DWY(CandidateDate, 1); // 1 = Monday .. 7 = Sunday
        exit(CandidateDate - (DayOfWeek - 1));
    end;

    /// <summary>
    /// Deletes any Day Planning / Res. Capacity Entry rows already sitting in this period (e.g.
    /// from a previous run of the same test) before a test builds its own GIVEN data.
    /// DeleteAll(false) skips both tables' triggers - Day Planning's OnDelete in particular
    /// TestFields "Assigned Hours"/"Realized Hours" = 0, which most of these test rows
    /// deliberately violate.
    /// </summary>
    local procedure ClearPeriodData(PeriodStartDate: Date)
    var
        DayPlanning: Record "Day Planning";
        ResCapacityEntry: Record "Res. Capacity Entry";
    begin
        DayPlanning.SetRange("Plan Date", PeriodStartDate, PeriodStartDate + 6);
        DayPlanning.DeleteAll(false);

        ResCapacityEntry.SetRange(Date, PeriodStartDate, PeriodStartDate + 6);
        ResCapacityEntry.DeleteAll(false);
    end;

    local procedure CreateTestResource(ResNo: Code[20]; IsExternal: Boolean)
    var
        Resource: Record Resource;
    begin
        if not Resource.Get(ResNo) then begin
            Resource.Init();
            Resource."No." := ResNo;
            Resource.Name := 'Skill Capacity Chart Test Resource ' + ResNo;
            Resource.Type := Resource.Type::Person;
            Resource.Insert();
        end;
        Resource."Is External" := IsExternal;
        Resource.Modify();
    end;

    local procedure CreateTestSkillCode(SkillCodeValue: Code[10])
    var
        SkillCode: Record "Skill Code";
    begin
        if not SkillCode.Get(SkillCodeValue) then begin
            SkillCode.Init();
            SkillCode.Code := SkillCodeValue;
            SkillCode.Description := 'Skill Capacity Chart Test Skill ' + SkillCodeValue;
            SkillCode.Insert();
        end;
    end;

    /// <summary>
    /// Inserts one Day Planning line. AssignedResourceNo blank = unassigned line (the only kind
    /// that can contribute to a skill's "Requested" chart segment - see codeunit 50662).
    /// "Day Line No." is auto-assigned via the table's own GetNextDayLineNo() so callers never
    /// need to coordinate line numbers themselves.
    /// </summary>
    local procedure InsertDayPlanningLine(PlanDate: Date; AssignedResourceNo: Code[20]; AssignedHours: Decimal; SkillCodeValue: Code[20]; RequestedHours: Decimal)
    var
        DayPlanning: Record "Day Planning";
    begin
        DayPlanning.Init();
        DayPlanning."Job No." := TestJobNo;
        DayPlanning."Job Task No." := TestJobTaskNo;
        DayPlanning."Plan Date" := PlanDate;
        DayPlanning.GetNextDayLineNo();
        DayPlanning."Assigned Resource No." := AssignedResourceNo;
        DayPlanning."Assigned Hours" := AssignedHours;
        DayPlanning.Skill := SkillCodeValue;
        DayPlanning."Requested Hours" := RequestedHours;
        DayPlanning.Insert();
    end;

    local procedure InsertResCapacityEntry(ResourceNo: Code[20]; EntryDate: Date; CapacityValue: Decimal)
    var
        ResCapacityEntry: Record "Res. Capacity Entry";
        LastResCapacityEntry: Record "Res. Capacity Entry";
    begin
        ResCapacityEntry.Init();
        ResCapacityEntry."Resource No." := ResourceNo;
        ResCapacityEntry.Date := EntryDate;
        ResCapacityEntry.Capacity := CapacityValue;

        LastResCapacityEntry.Reset();
        if LastResCapacityEntry.FindLast() then
            ResCapacityEntry."Entry No." := LastResCapacityEntry."Entry No." + 1
        else
            ResCapacityEntry."Entry No." := 1;

        ResCapacityEntry.Insert(true);
    end;

    // ================================================================
    // JSON assertion helpers (see BuildDayCapacityChartData's doc comment for the shape)
    // ================================================================

    local procedure BuildCategoryText(PlanDate: Date; Suffix: Text): Text
    begin
        exit(Format(PlanDate, 0, '<Weekday Text,3>') + Suffix);
    end;

    local procedure GetCategories(ChartDataJson: Text; var Categories: List of [Text])
    var
        ChartData: JsonObject;
        CategoriesToken: JsonToken;
        CategoriesArray: JsonArray;
        ItemToken: JsonToken;
        i: Integer;
    begin
        Clear(Categories);
        AssertIsTrue(ChartData.ReadFrom(ChartDataJson), 'Chart data JSON did not parse.');
        AssertIsTrue(ChartData.Get('categories', CategoriesToken), 'Chart data JSON has no "categories" key.');
        CategoriesArray := CategoriesToken.AsArray();
        for i := 0 to CategoriesArray.Count() - 1 do begin
            CategoriesArray.Get(i, ItemToken);
            Categories.Add(ItemToken.AsValue().AsText());
        end;
    end;

    local procedure FindCategoryIndex(Categories: List of [Text]; CategoryText: Text): Integer
    var
        i: Integer;
    begin
        for i := 1 to Categories.Count() do
            if Categories.Get(i) = CategoryText then
                exit(i - 1); // zero-based, matches each series' "values" array indexing
        exit(-1);
    end;

    local procedure TryGetSeriesValues(ChartDataJson: Text; SeriesName: Text; var Values: List of [Decimal]): Boolean
    var
        ChartData: JsonObject;
        SeriesToken: JsonToken;
        SeriesArray: JsonArray;
        OneSeriesToken: JsonToken;
        OneSeriesObj: JsonObject;
        NameToken: JsonToken;
        ValuesToken: JsonToken;
        ValuesArray: JsonArray;
        ValueItemToken: JsonToken;
        i: Integer;
        j: Integer;
    begin
        Clear(Values);
        if not ChartData.ReadFrom(ChartDataJson) then
            exit(false);
        if not ChartData.Get('series', SeriesToken) then
            exit(false);
        SeriesArray := SeriesToken.AsArray();
        for i := 0 to SeriesArray.Count() - 1 do begin
            SeriesArray.Get(i, OneSeriesToken);
            OneSeriesObj := OneSeriesToken.AsObject();
            OneSeriesObj.Get('name', NameToken);
            if NameToken.AsValue().AsText() = SeriesName then begin
                OneSeriesObj.Get('values', ValuesToken);
                ValuesArray := ValuesToken.AsArray();
                for j := 0 to ValuesArray.Count() - 1 do begin
                    ValuesArray.Get(j, ValueItemToken);
                    Values.Add(ValueItemToken.AsValue().AsDecimal());
                end;
                exit(true);
            end;
        end;
        exit(false);
    end;

    local procedure SeriesExists(ChartDataJson: Text; SeriesName: Text): Boolean
    var
        Values: List of [Decimal];
    begin
        exit(TryGetSeriesValues(ChartDataJson, SeriesName, Values));
    end;

    local procedure GetSeriesValueAtCategory(ChartDataJson: Text; SeriesName: Text; CategoryText: Text): Decimal
    var
        Categories: List of [Text];
        Values: List of [Decimal];
        CategoryIndex: Integer;
    begin
        GetCategories(ChartDataJson, Categories);
        CategoryIndex := FindCategoryIndex(Categories, CategoryText);
        AssertIsTrue(CategoryIndex >= 0, StrSubstNo('Category not found: %1', CategoryText));
        AssertIsTrue(TryGetSeriesValues(ChartDataJson, SeriesName, Values), StrSubstNo('Series not found: %1', SeriesName));
        exit(Values.Get(CategoryIndex + 1)); // List.Get() is 1-based
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
    /// Filters AuditBuffer to the (Day, Bar Type, Segment) row and positions on it via FindFirst.
    /// Callers that expect the row to exist should read AuditBuffer.Value immediately afterwards.
    /// </summary>
    local procedure FindAuditRow(var AuditBuffer: Record "Day Capacity Chart Audit Buf" temporary; RowDate: Date; BarType: Enum "Day Capacity Chart Bar Type"; Segment: Code[20]): Boolean
    begin
        AuditBuffer.Reset();
        AuditBuffer.SetRange(Day, RowDate);
        AuditBuffer.SetRange("Bar Type", BarType);
        AuditBuffer.SetRange(Segment, Segment);
        exit(AuditBuffer.FindFirst());
    end;

    // ================================================================
    // Tests
    // ================================================================

    [Test]
    procedure GivenAssignedHours_WhenBuildChartData_ThenAssignedIdenticalOnBothBars()
    var
        PeriodStart: Date;
        MondayFreeCapacity: Text;
        MondayRequested: Text;
        ChartDataJson: Text;
    begin
        // [GIVEN] A resource with 6 Assigned Hours on the period's Monday.
        Initialize();
        PeriodStart := GetTestMonday(10);
        ClearPeriodData(PeriodStart);
        CreateTestResource('SCCTRA', false);
        CreateTestSkillCode('SCCTSKA');
        InsertDayPlanningLine(PeriodStart, 'SCCTRA', 6, 'SCCTSKA', 0);

        MondayFreeCapacity := BuildCategoryText(PeriodStart, ' Capacity');
        MondayRequested := BuildCategoryText(PeriodStart, ' Requested');

        // [WHEN] BuildDayCapacityChartData is called with no filters and no scenario collapse
        ChartDataJson := SkillCapacityAnalysisMgt.BuildDayCapacityChartData(PeriodStart);

        // [THEN] The "Assigned" series carries the same value (6) on both the Capacity and
        // Requested bar for that day.
        AssertAreEqual(6, GetSeriesValueAtCategory(ChartDataJson, 'Assigned', MondayFreeCapacity), 'Assigned on Capacity bar.');
        AssertAreEqual(6, GetSeriesValueAtCategory(ChartDataJson, 'Assigned', MondayRequested), 'Assigned on Requested bar.');
    end;

    [Test]
    procedure GivenInternalAndExternalCapacity_WhenBuildChartData_ThenSplitMatchesIsExternal()
    var
        PeriodStart: Date;
        MondayFreeCapacity: Text;
        MondayRequested: Text;
        ChartDataJson: Text;
    begin
        // [GIVEN] An internal resource with 8 Capacity and an external resource with 5 Capacity
        // on the period's Monday, no Assigned Hours for either.
        Initialize();
        PeriodStart := GetTestMonday(11);
        ClearPeriodData(PeriodStart);
        CreateTestResource('SCCTRI1', false);
        CreateTestResource('SCCTRE1', true);
        InsertResCapacityEntry('SCCTRI1', PeriodStart, 8);
        InsertResCapacityEntry('SCCTRE1', PeriodStart, 5);

        MondayFreeCapacity := BuildCategoryText(PeriodStart, ' Capacity');
        MondayRequested := BuildCategoryText(PeriodStart, ' Requested');

        // [WHEN] BuildDayCapacityChartData is called with no filters and no scenario collapse
        ChartDataJson := SkillCapacityAnalysisMgt.BuildDayCapacityChartData(PeriodStart);

        // [THEN] "Internal"/"External" free-capacity segments match each resource's Is External
        // flag, and are only ever nonzero on the Capacity bar (0 on the Requested bar).
        AssertAreEqual(8, GetSeriesValueAtCategory(ChartDataJson, 'Internal', MondayFreeCapacity), 'Internal free capacity.');
        AssertAreEqual(5, GetSeriesValueAtCategory(ChartDataJson, 'External', MondayFreeCapacity), 'External free capacity.');
        AssertAreEqual(0, GetSeriesValueAtCategory(ChartDataJson, 'Internal', MondayRequested), 'Internal must be 0 on the Requested bar.');
        AssertAreEqual(0, GetSeriesValueAtCategory(ChartDataJson, 'External', MondayRequested), 'External must be 0 on the Requested bar.');
    end;

    [Test]
    procedure GivenAssignedAndUnassignedLineSameSkill_WhenBuildChartData_ThenOnlyUnassignedCounted()
    var
        PeriodStart: Date;
        MondayRequested: Text;
        ChartDataJson: Text;
    begin
        // [GIVEN] Two Day Planning lines on Monday for the same skill: one already assigned
        // (15 Requested Hours, must NOT count) and one still unassigned (4 Requested Hours, must
        // count).
        Initialize();
        PeriodStart := GetTestMonday(12);
        ClearPeriodData(PeriodStart);
        CreateTestResource('SCCTRA2', false);
        CreateTestSkillCode('SCCTSKB');
        InsertDayPlanningLine(PeriodStart, 'SCCTRA2', 0, 'SCCTSKB', 15); // assigned - excluded
        InsertDayPlanningLine(PeriodStart, '', 0, 'SCCTSKB', 4);        // unassigned - counted

        MondayRequested := BuildCategoryText(PeriodStart, ' Requested');

        // [WHEN] BuildDayCapacityChartData is called with no filters and no scenario collapse
        ChartDataJson := SkillCapacityAnalysisMgt.BuildDayCapacityChartData(PeriodStart);

        // [THEN] Only the unassigned line's 4 hours show up in the skill's Requested segment.
        AssertAreEqual(4, GetSeriesValueAtCategory(ChartDataJson, 'SCCTSKB', MondayRequested), 'Skill Requested segment must only count the unassigned line.');
    end;

    [Test]
    procedure GivenSkillOnlyOnAssignedLines_WhenBuildChartData_ThenSkillHasNoSeries()
    var
        PeriodStart: Date;
        ChartDataJson: Text;
    begin
        // [GIVEN] A skill that only ever appears on an already-assigned Day Planning line
        // (7 Requested Hours) - zero unassigned Requested Hours for this skill in the period.
        Initialize();
        PeriodStart := GetTestMonday(13);
        ClearPeriodData(PeriodStart);
        CreateTestResource('SCCTRA3', false);
        CreateTestSkillCode('SCCTSKC');
        InsertDayPlanningLine(PeriodStart, 'SCCTRA3', 0, 'SCCTSKC', 7);

        // [WHEN] BuildDayCapacityChartData is called with no filters and no scenario collapse
        ChartDataJson := SkillCapacityAnalysisMgt.BuildDayCapacityChartData(PeriodStart);

        // [THEN] The skill gets no chart series at all - not even a zero-valued one.
        AssertIsTrue(not SeriesExists(ChartDataJson, 'SCCTSKC'), 'A skill with zero unassigned Requested Hours must not appear as a series.');
    end;

    [Test]
    procedure GivenScenarioTwo_WhenBuildChartData_ThenFirstTwoDaysCollapsedExceptAssigned()
    var
        PeriodStart: Date;
        MondayDate: Date;
        TuesdayDate: Date;
        WednesdayDate: Date;
        MondayFreeCapacity: Text;
        MondayRequested: Text;
        TuesdayFreeCapacity: Text;
        TuesdayRequested: Text;
        WednesdayFreeCapacity: Text;
        WednesdayRequested: Text;
        ChartDataJson: Text;
    begin
        // [GIVEN] Identical setup on Monday, Tuesday, Wednesday: an internal resource with 6
        // Assigned Hours and 10 Capacity (4 free), plus an unassigned skill line with 3
        // Requested Hours.
        Initialize();
        PeriodStart := GetTestMonday(14);
        ClearPeriodData(PeriodStart);
        MondayDate := PeriodStart;
        TuesdayDate := PeriodStart + 1;
        WednesdayDate := PeriodStart + 2;

        CreateTestResource('SCCTRA4', false);
        CreateTestSkillCode('SCCTSKD');

        // Skill is set even on these Assigned-only lines (it plays no part in the Assigned
        // calculation) purely to avoid Day Planning's OnInsert trigger falling back to Daily
        // Optimizer Setup."Default Skill", which would error if that singleton has never been
        // created.
        InsertDayPlanningLine(MondayDate, 'SCCTRA4', 6, 'SCCTSKD', 0);
        InsertDayPlanningLine(TuesdayDate, 'SCCTRA4', 6, 'SCCTSKD', 0);
        InsertDayPlanningLine(WednesdayDate, 'SCCTRA4', 6, 'SCCTSKD', 0);
        InsertResCapacityEntry('SCCTRA4', MondayDate, 10);
        InsertResCapacityEntry('SCCTRA4', TuesdayDate, 10);
        InsertResCapacityEntry('SCCTRA4', WednesdayDate, 10);
        InsertDayPlanningLine(MondayDate, '', 0, 'SCCTSKD', 3);
        InsertDayPlanningLine(TuesdayDate, '', 0, 'SCCTSKD', 3);
        InsertDayPlanningLine(WednesdayDate, '', 0, 'SCCTSKD', 3);

        MondayFreeCapacity := BuildCategoryText(MondayDate, ' Capacity');
        MondayRequested := BuildCategoryText(MondayDate, ' Requested');
        TuesdayFreeCapacity := BuildCategoryText(TuesdayDate, ' Capacity');
        TuesdayRequested := BuildCategoryText(TuesdayDate, ' Requested');
        WednesdayFreeCapacity := BuildCategoryText(WednesdayDate, ' Capacity');
        WednesdayRequested := BuildCategoryText(WednesdayDate, ' Requested');

        // [WHEN] BuildDayCapacityChartData is called with ScenarioNo = 2 (Monday=weekday 1 and
        // Tuesday=weekday 2 are "closed").
        ChartDataJson := SkillCapacityAnalysisMgt.BuildDayCapacityChartData(PeriodStart);

        // [THEN] Assigned is unaffected by the collapse on every day.
        AssertAreEqual(6, GetSeriesValueAtCategory(ChartDataJson, 'Assigned', MondayFreeCapacity), 'Monday Assigned (Capacity bar).');
        AssertAreEqual(6, GetSeriesValueAtCategory(ChartDataJson, 'Assigned', MondayRequested), 'Monday Assigned (Requested bar).');
        AssertAreEqual(6, GetSeriesValueAtCategory(ChartDataJson, 'Assigned', TuesdayFreeCapacity), 'Tuesday Assigned (Capacity bar).');
        AssertAreEqual(6, GetSeriesValueAtCategory(ChartDataJson, 'Assigned', TuesdayRequested), 'Tuesday Assigned (Requested bar).');
        AssertAreEqual(6, GetSeriesValueAtCategory(ChartDataJson, 'Assigned', WednesdayFreeCapacity), 'Wednesday Assigned (Capacity bar).');
        AssertAreEqual(6, GetSeriesValueAtCategory(ChartDataJson, 'Assigned', WednesdayRequested), 'Wednesday Assigned (Requested bar).');

        // [THEN] Monday and Tuesday (closed) have their Internal free-capacity and skill
        // Requested segments zeroed out.
        AssertAreEqual(0, GetSeriesValueAtCategory(ChartDataJson, 'Internal', MondayFreeCapacity), 'Monday Internal must be collapsed to 0.');
        AssertAreEqual(0, GetSeriesValueAtCategory(ChartDataJson, 'SCCTSKD', MondayRequested), 'Monday skill segment must be collapsed to 0.');
        AssertAreEqual(0, GetSeriesValueAtCategory(ChartDataJson, 'Internal', TuesdayFreeCapacity), 'Tuesday Internal must be collapsed to 0.');
        AssertAreEqual(0, GetSeriesValueAtCategory(ChartDataJson, 'SCCTSKD', TuesdayRequested), 'Tuesday skill segment must be collapsed to 0.');

        // [THEN] Wednesday (weekday 3, open) is untouched: Internal free capacity = 10 - 6 = 4,
        // skill segment = 3.
        AssertAreEqual(4, GetSeriesValueAtCategory(ChartDataJson, 'Internal', WednesdayFreeCapacity), 'Wednesday Internal must be untouched.');
        AssertAreEqual(3, GetSeriesValueAtCategory(ChartDataJson, 'SCCTSKD', WednesdayRequested), 'Wednesday skill segment must be untouched.');
    end;

    // ================================================================
    // ScenarioNo boundary coverage (ScenarioNo = 1, 3, 4)
    // ================================================================
    //
    // Shared by the three [Test] procedures below so the GIVEN-data setup (identical across all
    // scenario values) isn't triplicated. Each test only differs in which ScenarioNo it passes
    // and which WeeksAhead offset it uses to keep its period non-overlapping with every other
    // test in this codeunit.
    //
    // Builds Monday..Friday with identical GIVEN data on every weekday: an internal resource with
    // 6 Assigned Hours and 10 Capacity (4 free), plus an unassigned skill line with 3 Requested
    // Hours. It then asserts, for every weekday i = 1 (Monday) .. 5 (Friday), that day i is
    // "closed" (Internal free capacity and skill Requested segment forced to 0, Assigned
    // untouched) exactly when i <= ScenarioNo, and "open" (Internal = 4, skill = 3, Assigned
    // untouched) exactly
    // when i > ScenarioNo - i.e. the closed/open boundary sits precisely at ScenarioNo, checked
    // on every single day rather than only at the boundary itself.

    local procedure RunScenarioBoundaryTest(ScenarioNo: Integer; WeeksAhead: Integer)
    var
        PeriodStart: Date;
        CurrDate: Date;
        ResNo: Code[20];
        SkillCodeValue: Code[10];
        FreeCapacityCategory: Text;
        RequestedCategory: Text;
        ChartDataJson: Text;
        ExpectedInternal: Decimal;
        ExpectedSkill: Decimal;
        WeekdayIndex: Integer;
    begin
        // [GIVEN] Identical setup on all 5 weekdays: an internal resource with 6 Assigned Hours
        // and 10 Capacity (4 free), plus an unassigned skill line with 3 Requested Hours.
        Initialize();
        PeriodStart := GetTestMonday(WeeksAhead);
        ClearPeriodData(PeriodStart);

        ResNo := 'SCCTRS' + Format(ScenarioNo);
        SkillCodeValue := 'SCCTSKS' + Format(ScenarioNo);
        CreateTestResource(ResNo, false);
        CreateTestSkillCode(SkillCodeValue);

        for WeekdayIndex := 1 to 5 do begin
            CurrDate := PeriodStart + (WeekdayIndex - 1);
            // Skill is set even on this Assigned-only line (it plays no part in the Assigned
            // calculation) purely to avoid Day Planning's OnInsert trigger falling back to Daily
            // Optimizer Setup."Default Skill", which would error if that singleton has never
            // been created.
            InsertDayPlanningLine(CurrDate, ResNo, 6, SkillCodeValue, 0);
            InsertResCapacityEntry(ResNo, CurrDate, 10);
            InsertDayPlanningLine(CurrDate, '', 0, SkillCodeValue, 3);
        end;

        // [WHEN] BuildDayCapacityChartData is called with the scenario under test.
        ChartDataJson := SkillCapacityAnalysisMgt.BuildDayCapacityChartData(PeriodStart);

        // [THEN] Every weekday i = 1..5: closed (i <= ScenarioNo) collapses Internal/skill to 0
        // while Assigned stays untouched; open (i > ScenarioNo) leaves Internal/skill untouched
        // too.
        for WeekdayIndex := 1 to 5 do begin
            CurrDate := PeriodStart + (WeekdayIndex - 1);
            FreeCapacityCategory := BuildCategoryText(CurrDate, ' Capacity');
            RequestedCategory := BuildCategoryText(CurrDate, ' Requested');

            AssertAreEqual(6, GetSeriesValueAtCategory(ChartDataJson, 'Assigned', FreeCapacityCategory),
                StrSubstNo('Scenario %1, weekday %2 Assigned (Capacity bar).', WeekdayIndex));
            AssertAreEqual(6, GetSeriesValueAtCategory(ChartDataJson, 'Assigned', RequestedCategory),
                StrSubstNo('Scenario %1, weekday %2 Assigned (Requested bar).', WeekdayIndex));

            if WeekdayIndex <= ScenarioNo then begin
                ExpectedInternal := 0;
                ExpectedSkill := 0;
            end else begin
                ExpectedInternal := 4;
                ExpectedSkill := 3;
            end;

            AssertAreEqual(ExpectedInternal, GetSeriesValueAtCategory(ChartDataJson, 'Internal', FreeCapacityCategory),
                StrSubstNo('Scenario %1, weekday %2 Internal free capacity.', WeekdayIndex));
            AssertAreEqual(ExpectedSkill, GetSeriesValueAtCategory(ChartDataJson, SkillCodeValue, RequestedCategory),
                StrSubstNo('Scenario %1, weekday %2 skill segment.', WeekdayIndex));
        end;
    end;

    [Test]
    procedure GivenScenarioOne_WhenBuildChartData_ThenOnlyMondayCollapsed()
    begin
        // Boundary at ScenarioNo = 1: Monday (weekday 1) closed, Tuesday..Friday (2..5) open.
        RunScenarioBoundaryTest(1, 15);
    end;

    [Test]
    procedure GivenScenarioThree_WhenBuildChartData_ThenFirstThreeDaysCollapsed()
    begin
        // Boundary at ScenarioNo = 3: Monday..Wednesday (1..3) closed, Thursday..Friday (4..5) open.
        RunScenarioBoundaryTest(3, 16);
    end;

    [Test]
    procedure GivenScenarioFour_WhenBuildChartData_ThenOnlyFridayOpen()
    begin
        // Boundary at ScenarioNo = 4: Monday..Thursday (1..4) closed, only Friday (5) open.
        RunScenarioBoundaryTest(4, 17);
    end;

    // ================================================================
    // BuildDayCapacityAuditBuffer (codeunit 50662) - audit trail behind page 50692's
    // "Chart Audit Trail" factbox. Must never drift from BuildDayCapacityChartData's own JSON,
    // since both are built from the same shared per-day helper (CalcDaySegments).
    // ================================================================

    [Test]
    procedure GivenScenarioTwo_WhenBuildAuditBuffer_ThenRowsMatchChartData()
    var
        PeriodStart: Date;
        MondayDate: Date;
        TuesdayDate: Date;
        WednesdayDate: Date;
        ChartDataJson: Text;
        AuditBuffer: Record "Day Capacity Chart Audit Buf" temporary;
    begin
        // [GIVEN] Same shape of setup as GivenScenarioTwo_WhenBuildChartData_ThenFirstTwoDaysCollapsedExceptAssigned:
        // an internal resource with 6 Assigned Hours and 10 Capacity (4 free) on Monday..Wednesday,
        // plus an unassigned skill line with 3 Requested Hours on each day.
        Initialize();
        PeriodStart := GetTestMonday(18);
        ClearPeriodData(PeriodStart);
        MondayDate := PeriodStart;
        TuesdayDate := PeriodStart + 1;
        WednesdayDate := PeriodStart + 2;

        CreateTestResource('SCCTRA5', false);
        CreateTestSkillCode('SCCTSKE');

        InsertDayPlanningLine(MondayDate, 'SCCTRA5', 6, 'SCCTSKE', 0);
        InsertDayPlanningLine(TuesdayDate, 'SCCTRA5', 6, 'SCCTSKE', 0);
        InsertDayPlanningLine(WednesdayDate, 'SCCTRA5', 6, 'SCCTSKE', 0);
        InsertResCapacityEntry('SCCTRA5', MondayDate, 10);
        InsertResCapacityEntry('SCCTRA5', TuesdayDate, 10);
        InsertResCapacityEntry('SCCTRA5', WednesdayDate, 10);
        InsertDayPlanningLine(MondayDate, '', 0, 'SCCTSKE', 3);
        InsertDayPlanningLine(TuesdayDate, '', 0, 'SCCTSKE', 3);
        InsertDayPlanningLine(WednesdayDate, '', 0, 'SCCTSKE', 3);

        // [WHEN] Both BuildDayCapacityChartData and BuildDayCapacityAuditBuffer are called with
        // the same inputs (ScenarioNo = 2: Monday and Tuesday closed).
        ChartDataJson := SkillCapacityAnalysisMgt.BuildDayCapacityChartData(PeriodStart);
        SkillCapacityAnalysisMgt.BuildDayCapacityAuditBuffer(AuditBuffer, PeriodStart);

        // [THEN] Specific (Day, Bar Type, Segment) buffer rows match the equivalent chart JSON
        // category/series value.
        AssertIsTrue(FindAuditRow(AuditBuffer, MondayDate, Enum::"Day Capacity Chart Bar Type"::Capacity, 'Assigned'),
            'Monday Capacity/Assigned row must exist.');
        AssertAreEqual(GetSeriesValueAtCategory(ChartDataJson, 'Assigned', BuildCategoryText(MondayDate, ' Capacity')), AuditBuffer.Value,
            'Monday Capacity/Assigned value must match the chart.');

        AssertIsTrue(FindAuditRow(AuditBuffer, WednesdayDate, Enum::"Day Capacity Chart Bar Type"::Capacity, 'Internal'),
            'Wednesday Capacity/Internal row must exist.');
        AssertAreEqual(GetSeriesValueAtCategory(ChartDataJson, 'Internal', BuildCategoryText(WednesdayDate, ' Capacity')), AuditBuffer.Value,
            'Wednesday Capacity/Internal value must match the chart.');

        AssertIsTrue(FindAuditRow(AuditBuffer, WednesdayDate, Enum::"Day Capacity Chart Bar Type"::Requested, 'SCCTSKE'),
            'Wednesday Requested/SCCTSKE row must exist.');
        AssertAreEqual(GetSeriesValueAtCategory(ChartDataJson, 'SCCTSKE', BuildCategoryText(WednesdayDate, ' Requested')), AuditBuffer.Value,
            'Wednesday Requested/SCCTSKE value must match the chart.');
    end;

    [Test]
    procedure GivenScenarioCollapse_WhenBuildAuditBuffer_ThenCollapsedSegmentRowStillExistsAtZero()
    var
        PeriodStart: Date;
        MondayDate: Date;
        AuditBuffer: Record "Day Capacity Chart Audit Buf" temporary;
    begin
        // [GIVEN] An internal resource with 6 Assigned Hours and 10 Capacity on Monday, plus an
        // unassigned skill line with 3 Requested Hours on Monday.
        Initialize();
        PeriodStart := GetTestMonday(19);
        ClearPeriodData(PeriodStart);
        MondayDate := PeriodStart;

        CreateTestResource('SCCTRA6', false);
        CreateTestSkillCode('SCCTSKF');

        InsertDayPlanningLine(MondayDate, 'SCCTRA6', 6, 'SCCTSKF', 0);
        InsertResCapacityEntry('SCCTRA6', MondayDate, 10);
        InsertDayPlanningLine(MondayDate, '', 0, 'SCCTSKF', 3);

        // [WHEN] BuildDayCapacityAuditBuffer is called with ScenarioNo = 1 (Monday, weekday 1, is
        // closed).
        SkillCapacityAnalysisMgt.BuildDayCapacityAuditBuffer(AuditBuffer, PeriodStart);

        // [THEN] Monday's Capacity/Internal row and Requested/SCCTSKF row - both collapsed to 0
        // by the scenario - still exist in the buffer rather than being omitted.
        AssertIsTrue(FindAuditRow(AuditBuffer, MondayDate, Enum::"Day Capacity Chart Bar Type"::Capacity, 'Internal'),
            'Collapsed Monday Capacity/Internal row must still exist in the buffer.');
        AssertAreEqual(0, AuditBuffer.Value, 'Collapsed Monday Capacity/Internal value must be 0.');

        AssertIsTrue(FindAuditRow(AuditBuffer, MondayDate, Enum::"Day Capacity Chart Bar Type"::Requested, 'SCCTSKF'),
            'Collapsed Monday Requested/SCCTSKF row must still exist in the buffer.');
        AssertAreEqual(0, AuditBuffer.Value, 'Collapsed Monday Requested/SCCTSKF value must be 0.');
    end;

    [Test]
    procedure GivenSkillOnlyOnAssignedLines_WhenBuildAuditBuffer_ThenSkillHasNoRows()
    var
        PeriodStart: Date;
        AuditBuffer: Record "Day Capacity Chart Audit Buf" temporary;
    begin
        // [GIVEN] A skill that only ever appears on an already-assigned Day Planning line (7
        // Requested Hours) - zero unassigned Requested Hours for this skill in the period, so it
        // never makes BuildActiveSkillList's result.
        Initialize();
        PeriodStart := GetTestMonday(20);
        ClearPeriodData(PeriodStart);
        CreateTestResource('SCCTRA7', false);
        CreateTestSkillCode('SCCTSKG');
        InsertDayPlanningLine(PeriodStart, 'SCCTRA7', 0, 'SCCTSKG', 7);

        // [WHEN] BuildDayCapacityAuditBuffer is called with no filters and no scenario collapse.
        SkillCapacityAnalysisMgt.BuildDayCapacityAuditBuffer(AuditBuffer, PeriodStart);

        // [THEN] The skill gets no buffer rows at all - not even a zero-valued one - on either
        // bar type.
        AssertIsTrue(not FindAuditRow(AuditBuffer, PeriodStart, Enum::"Day Capacity Chart Bar Type"::Capacity, 'SCCTSKG'),
            'A skill with zero unassigned Requested Hours must have no Capacity-bar row.');
        AssertIsTrue(not FindAuditRow(AuditBuffer, PeriodStart, Enum::"Day Capacity Chart Bar Type"::Requested, 'SCCTSKG'),
            'A skill with zero unassigned Requested Hours must have no Requested-bar row.');
    end;
}
