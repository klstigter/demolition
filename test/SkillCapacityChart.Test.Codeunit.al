codeunit 60024 "Skill Capacity Chart Tests"
{
    // Tests for codeunit 50662 "Skill Capacity Analysis Mgt." - procedure
    // BuildDayCapacityChartData(PeriodStartDate).
    // Asserts directly against the returned chart JSON (categories/series with name/values/
    // color/[border]/stacked keys) rather than going through page 50692's UI - see the
    // procedure's own doc comment for the exact contract. Covers the full Monday..Sunday period
    // (7 days), and the "Internal"/"External" free-capacity series on the Capacity bar - true
    // calendar capacity read from "Res. Capacity Entry" net of that day's Day Planning Assigned
    // Hours, NOT a copy of the Requested bar's Assigned/Requested figures.
    //
    // DYNAMIC DAY INCLUSION: a weekday only gets a category pair (and a values-list entry on
    // every series) when it has ANY nonzero data anywhere (Assigned, free Capacity, or any active
    // skill's requested hours) - see DayHasAnyChartData in codeunit 50662. Most single/multi-day
    // tests below only ever populate an EARLIER day (Monday, or Monday..Wednesday) than any day
    // they assert against via GetSeriesValueAtDayBar, so CalcCategoryIndex's day-offset-based
    // index still lines up with the (possibly shorter) actual values list - no day before the one
    // under test is ever omitted in those tests. Tests that specifically exercise omission
    // (GivenFullWeekPeriod_WhenBuildChartData_ThenEmptyDaysAreOmitted and friends, near the end of
    // this file) instead assert directly against the "categories"/"dayLabels" JSON arrays.
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

    /// <summary>
    /// Same as CreateTestResource, but for a Pool Member resource (Is Pool Member = true,
    /// Is External = false) - used to lock in that Pool Member resources bucket as Internal
    /// capacity in CalcCapacitySplit (codeunit 50662), NOT External. Both fields are set via
    /// direct field assignment, never Validate() - table 50603's tableext OnValidate triggers on
    /// "Is Pool"/"Is Pool Member" pop up an interactive Vendor/Resource List lookup page
    /// (VenList.RunModal / ResList.RunModal) when set through Validate(), which would hang a
    /// test run.
    /// </summary>
    local procedure CreateTestPoolMemberResource(ResNo: Code[20])
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
        Resource."Is External" := false;
        Resource."Is Pool Member" := true;
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

    /// <summary>
    /// Same as InsertDayPlanningLine, but also sets "Requested Resource No." - the field
    /// CalcUnassignedSkillRequestedSplit uses to bucket an unassigned line's Requested Hours as
    /// Internal/External (see codeunit 50662).
    /// </summary>
    local procedure InsertDayPlanningLineWithRequestedResource(PlanDate: Date; AssignedResourceNo: Code[20]; AssignedHours: Decimal; SkillCodeValue: Code[20]; RequestedHours: Decimal; RequestedResourceNo: Code[20])
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
        DayPlanning."Requested Resource No." := RequestedResourceNo;
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

    /// <summary>
    /// Categories are bare ("Capacity"/"Requested", no weekday prefix - see
    /// BuildDayCapacityChartData's doc comment), 2 per weekday in fixed Capacity-then-Requested
    /// order, so the index into any series' "values" array can be computed directly from the
    /// day offset and bar type instead of searching "categories" by text.
    /// </summary>
    local procedure CalcCategoryIndex(PeriodStartDate: Date; PlanDate: Date; IsCapacityBar: Boolean): Integer
    var
        BarOffset: Integer;
    begin
        if not IsCapacityBar then
            BarOffset := 1;
        exit((PlanDate - PeriodStartDate) * 2 + BarOffset);
    end;

    local procedure TryGetSeriesValues(ChartDataJson: Text; SeriesName: Text; var Values: List of [Decimal]): Boolean
    begin
        exit(TryGetSeriesValuesOccurrence(ChartDataJson, SeriesName, 0, Values));
    end;

    /// <summary>
    /// Same as TryGetSeriesValues, but selects the Nth (0-based) series matching SeriesName -
    /// needed because every segment (Assigned, each skill) is declared as an internal/external
    /// SERIES PAIR sharing the same "name" (see AddChartSeries callers in
    /// BuildDayCapacityChartData): occurrence 0 is always the internal half (no "border" key),
    /// occurrence 1 is always the external half ("border" key present).
    /// </summary>
    local procedure TryGetSeriesValuesOccurrence(ChartDataJson: Text; SeriesName: Text; Occurrence: Integer; var Values: List of [Decimal]): Boolean
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
        MatchCount: Integer;
    begin
        Clear(Values);
        if not ChartData.ReadFrom(ChartDataJson) then
            exit(false);
        if not ChartData.Get('series', SeriesToken) then
            exit(false);
        SeriesArray := SeriesToken.AsArray();
        MatchCount := 0;
        for i := 0 to SeriesArray.Count() - 1 do begin
            SeriesArray.Get(i, OneSeriesToken);
            OneSeriesObj := OneSeriesToken.AsObject();
            OneSeriesObj.Get('name', NameToken);
            if NameToken.AsValue().AsText() = SeriesName then begin
                if MatchCount = Occurrence then begin
                    OneSeriesObj.Get('values', ValuesToken);
                    ValuesArray := ValuesToken.AsArray();
                    for j := 0 to ValuesArray.Count() - 1 do begin
                        ValuesArray.Get(j, ValueItemToken);
                        Values.Add(ValueItemToken.AsValue().AsDecimal());
                    end;
                    exit(true);
                end;
                MatchCount += 1;
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

    /// <summary>
    /// Reads the top-level "categories" array directly - used by the dynamic-day-inclusion tests,
    /// which need to assert on which days are PRESENT/ABSENT rather than look up a value at a
    /// fixed index (see this file's own top-of-file comment on DYNAMIC DAY INCLUSION).
    /// </summary>
    local procedure GetCategoriesArray(ChartDataJson: Text; var CategoriesArray: JsonArray)
    var
        ChartData: JsonObject;
        CategoriesToken: JsonToken;
    begin
        AssertIsTrue(ChartData.ReadFrom(ChartDataJson), 'Chart JSON must parse.');
        AssertIsTrue(ChartData.Get('categories', CategoriesToken), 'Chart JSON must have a "categories" key.');
        CategoriesArray := CategoriesToken.AsArray();
    end;

    local procedure GetDayLabelsArray(ChartDataJson: Text; var DayLabelsArray: JsonArray)
    var
        ChartData: JsonObject;
        DayLabelsToken: JsonToken;
    begin
        AssertIsTrue(ChartData.ReadFrom(ChartDataJson), 'Chart JSON must parse.');
        AssertIsTrue(ChartData.Get('dayLabels', DayLabelsToken), 'Chart JSON must have a "dayLabels" key.');
        DayLabelsArray := DayLabelsToken.AsArray();
    end;

    /// <summary>True if "categories" contains an entry with exactly this text.</summary>
    local procedure CategoryTextExists(ChartDataJson: Text; CategoryText: Text): Boolean
    var
        CategoriesArray: JsonArray;
        CategoryToken: JsonToken;
        i: Integer;
    begin
        GetCategoriesArray(ChartDataJson, CategoriesArray);
        for i := 0 to CategoriesArray.Count() - 1 do begin
            CategoriesArray.Get(i, CategoryToken);
            if CategoryToken.AsValue().AsText() = CategoryText then
                exit(true);
        end;
        exit(false);
    end;

    /// <summary>
    /// Same weekday-short-text format codeunit 50662's own (local, not callable from here)
    /// FormatWeekdayShort uses - kept in lockstep deliberately so these tests build the exact
    /// same category text the production code emits.
    /// </summary>
    local procedure FormatWeekdayShortForTest(ADate: Date): Text
    begin
        exit(Format(ADate, 0, '<Weekday Text,3>'));
    end;

    local procedure CapacityCategoryText(ADate: Date): Text
    begin
        exit(FormatWeekdayShortForTest(ADate) + '|Capacity');
    end;

    local procedure RequestedCategoryText(ADate: Date): Text
    begin
        exit(FormatWeekdayShortForTest(ADate) + '|Requested');
    end;

    local procedure GetSeriesValueAtDayBar(ChartDataJson: Text; SeriesName: Text; PeriodStartDate: Date; PlanDate: Date; IsCapacityBar: Boolean): Decimal
    begin
        exit(GetSeriesValueAtDayBarOccurrence(ChartDataJson, SeriesName, 0, PeriodStartDate, PlanDate, IsCapacityBar));
    end;

    /// <summary>
    /// Same as GetSeriesValueAtDayBar, but reads the Nth (0-based) series sharing SeriesName -
    /// occurrence 0 = internal half, occurrence 1 = external half (see
    /// TryGetSeriesValuesOccurrence).
    /// </summary>
    local procedure GetSeriesValueAtDayBarOccurrence(ChartDataJson: Text; SeriesName: Text; Occurrence: Integer; PeriodStartDate: Date; PlanDate: Date; IsCapacityBar: Boolean): Decimal
    var
        Values: List of [Decimal];
        CategoryIndex: Integer;
    begin
        CategoryIndex := CalcCategoryIndex(PeriodStartDate, PlanDate, IsCapacityBar);
        AssertIsTrue(TryGetSeriesValuesOccurrence(ChartDataJson, SeriesName, Occurrence, Values), StrSubstNo('Series occurrence not found: %1 (#%2)', SeriesName, Occurrence));
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

    /// <summary>
    /// Same as FindAuditRow, but positions on the Nth (0-based) row sharing (Day, Bar Type,
    /// Segment) - needed for skill segments on the Requested bar, which now always insert TWO
    /// rows per skill (combined total, then always-0) sharing the same Segment text (see
    /// InsertAuditLine callers in BuildDayCapacityAuditBuffer). Occurrence 0 = the combined-total
    /// row, occurrence 1 = the always-0 row.
    /// </summary>
    local procedure FindAuditRowOccurrence(var AuditBuffer: Record "Day Capacity Chart Audit Buf" temporary; RowDate: Date; BarType: Enum "Day Capacity Chart Bar Type"; Segment: Code[20]; Occurrence: Integer): Boolean
    begin
        AuditBuffer.Reset();
        AuditBuffer.SetRange(Day, RowDate);
        AuditBuffer.SetRange("Bar Type", BarType);
        AuditBuffer.SetRange(Segment, Segment);
        if not AuditBuffer.FindSet() then
            exit(false);
        if Occurrence = 0 then
            exit(true);
        exit(AuditBuffer.Next(Occurrence) = Occurrence);
    end;

    // ================================================================
    // Tests
    // ================================================================

    [Test]
    procedure GivenAssignedHours_WhenBuildChartData_ThenAssignedIdenticalOnBothBars()
    var
        PeriodStart: Date;
        ChartDataJson: Text;
    begin
        // [GIVEN] A resource with 6 Assigned Hours on the period's Monday.
        Initialize();
        PeriodStart := GetTestMonday(10);
        ClearPeriodData(PeriodStart);
        CreateTestResource('SCCTRA', false);
        CreateTestSkillCode('SCCTSKA');
        InsertDayPlanningLine(PeriodStart, 'SCCTRA', 6, 'SCCTSKA', 0);

        // [WHEN] BuildDayCapacityChartData is called.
        ChartDataJson := SkillCapacityAnalysisMgt.BuildDayCapacityChartData(PeriodStart);

        // [THEN] The "Assigned" series carries the same value (6) on both the Capacity and
        // Requested bar for that day.
        AssertAreEqual(6, GetSeriesValueAtDayBar(ChartDataJson, 'Assigned Capacity - Internal', PeriodStart, PeriodStart, true), 'Assigned on Capacity bar.');
        AssertAreEqual(6, GetSeriesValueAtDayBar(ChartDataJson, 'Assigned Capacity - Internal', PeriodStart, PeriodStart, false), 'Assigned on Requested bar.');
    end;

    [Test]
    procedure GivenInternalAndExternalAssignedHours_WhenBuildChartData_ThenRequestedBarCollapsesAssignedToCombinedTotal()
    var
        PeriodStart: Date;
        ChartDataJson: Text;
    begin
        // [GIVEN] An internal resource with 6 Assigned Hours and an external resource with 4
        // Assigned Hours, both on the period's Monday.
        Initialize();
        PeriodStart := GetTestMonday(23);
        ClearPeriodData(PeriodStart);
        CreateTestResource('SCCTRAI', false);
        CreateTestResource('SCCTRAE', true);
        CreateTestSkillCode('SCCTSKH');
        InsertDayPlanningLine(PeriodStart, 'SCCTRAI', 6, 'SCCTSKH', 0);
        InsertDayPlanningLine(PeriodStart, 'SCCTRAE', 4, 'SCCTSKH', 0);

        // [WHEN] BuildDayCapacityChartData is called.
        ChartDataJson := SkillCapacityAnalysisMgt.BuildDayCapacityChartData(PeriodStart);

        // [THEN] The Capacity bar keeps the real Internal (6) / External (4) split on its
        // "Assigned" series pair.
        AssertAreEqual(6, GetSeriesValueAtDayBarOccurrence(ChartDataJson, 'Assigned Capacity - Internal', 0, PeriodStart, PeriodStart, true), 'Capacity bar Assigned internal half.');
        AssertAreEqual(4, GetSeriesValueAtDayBarOccurrence(ChartDataJson, 'Assigned Capacity - External', 0, PeriodStart, PeriodStart, true), 'Capacity bar Assigned external half.');

        // [THEN] The Requested bar collapses to a single plain total - the internal series
        // carries the combined value (10), the external series is always 0 (no red border).
        AssertAreEqual(10, GetSeriesValueAtDayBarOccurrence(ChartDataJson, 'Assigned Capacity - Internal', 0, PeriodStart, PeriodStart, false), 'Requested bar Assigned combined total.');
        AssertAreEqual(0, GetSeriesValueAtDayBarOccurrence(ChartDataJson, 'Assigned Capacity - External', 0, PeriodStart, PeriodStart, false), 'Requested bar Assigned external half must be 0.');
    end;

    [Test]
    procedure GivenInternalAndExternalCapacity_WhenBuildChartData_ThenSplitMatchesIsExternal()
    var
        PeriodStart: Date;
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

        // [WHEN] BuildDayCapacityChartData is called.
        ChartDataJson := SkillCapacityAnalysisMgt.BuildDayCapacityChartData(PeriodStart);

        // [THEN] "Internal"/"External" free-capacity segments match each resource's Is External
        // flag, and are only ever nonzero on the Capacity bar (0 on the Requested bar).
        AssertAreEqual(8, GetSeriesValueAtDayBar(ChartDataJson, 'Free Capacity - Internal', PeriodStart, PeriodStart, true), 'Internal free capacity.');
        AssertAreEqual(5, GetSeriesValueAtDayBar(ChartDataJson, 'Free Capacity - External', PeriodStart, PeriodStart, true), 'External free capacity.');
        AssertAreEqual(0, GetSeriesValueAtDayBar(ChartDataJson, 'Free Capacity - Internal', PeriodStart, PeriodStart, false), 'Internal must be 0 on the Requested bar.');
        AssertAreEqual(0, GetSeriesValueAtDayBar(ChartDataJson, 'Free Capacity - External', PeriodStart, PeriodStart, false), 'External must be 0 on the Requested bar.');
    end;

    [Test]
    procedure GivenPoolMemberResourceWithFreeCapacity_WhenBuildChartData_ThenBucketedAsInternal()
    var
        PeriodStart: Date;
        ChartDataJson: Text;
    begin
        // [GIVEN] A Pool Member resource (Is Pool Member = true, Is External = false) with 7
        // Capacity and no Day Planning assignment on the period's Monday. CalcCapacitySplit
        // (codeunit 50662) deliberately buckets Internal/External purely by "Is External" -
        // Pool/Pool Member resources are NOT treated as External there (unlike the legacy, dead
        // CalcFreeCapacity procedure, which still folds Pool/Pool Member into External for the
        // old barchart_v1 page).
        Initialize();
        PeriodStart := GetTestMonday(28);
        ClearPeriodData(PeriodStart);
        CreateTestPoolMemberResource('SCCTRP1');
        InsertResCapacityEntry('SCCTRP1', PeriodStart, 7);

        // [WHEN] BuildDayCapacityChartData is called.
        ChartDataJson := SkillCapacityAnalysisMgt.BuildDayCapacityChartData(PeriodStart);

        // [THEN] The Pool Member's free capacity is bucketed entirely as Internal, not External.
        AssertAreEqual(7, GetSeriesValueAtDayBar(ChartDataJson, 'Free Capacity - Internal', PeriodStart, PeriodStart, true), 'Pool Member free capacity must bucket as Internal.');
        AssertAreEqual(0, GetSeriesValueAtDayBar(ChartDataJson, 'Free Capacity - External', PeriodStart, PeriodStart, true), 'Pool Member free capacity must NOT bucket as External.');
    end;

    [Test]
    procedure GivenAssignedAndUnassignedLineSameSkill_WhenBuildChartData_ThenOnlyUnassignedCounted()
    var
        PeriodStart: Date;
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

        // [WHEN] BuildDayCapacityChartData is called.
        ChartDataJson := SkillCapacityAnalysisMgt.BuildDayCapacityChartData(PeriodStart);

        // [THEN] Only the unassigned line's 4 hours show up in the skill's Requested segment.
        AssertAreEqual(4, GetSeriesValueAtDayBar(ChartDataJson, 'SCCTSKB', PeriodStart, PeriodStart, false), 'Skill Requested segment must only count the unassigned line.');
    end;

    [Test]
    procedure GivenSkillWithInternalAndExternalRequested_WhenBuildChartData_ThenRequestedBarCollapsesSkillToCombinedTotal()
    var
        PeriodStart: Date;
        ChartDataJson: Text;
    begin
        // [GIVEN] Two unassigned Day Planning lines on Monday for the same skill: one with no
        // "Requested Resource No." set (Internal, 5 hours) and one targeting an external
        // resource (External, 3 hours).
        Initialize();
        PeriodStart := GetTestMonday(24);
        ClearPeriodData(PeriodStart);
        CreateTestResource('SCCTRSE', true);
        CreateTestSkillCode('SCCTSKI');
        InsertDayPlanningLine(PeriodStart, '', 0, 'SCCTSKI', 5);
        InsertDayPlanningLineWithRequestedResource(PeriodStart, '', 0, 'SCCTSKI', 3, 'SCCTRSE');

        // [WHEN] BuildDayCapacityChartData is called.
        ChartDataJson := SkillCapacityAnalysisMgt.BuildDayCapacityChartData(PeriodStart);

        // [THEN] The skill never appears on the Capacity bar (both halves 0).
        AssertAreEqual(0, GetSeriesValueAtDayBarOccurrence(ChartDataJson, 'SCCTSKI', 0, PeriodStart, PeriodStart, true), 'Capacity bar skill internal half must be 0.');
        AssertAreEqual(0, GetSeriesValueAtDayBarOccurrence(ChartDataJson, 'SCCTSKI', 1, PeriodStart, PeriodStart, true), 'Capacity bar skill external half must be 0.');

        // [THEN] The Requested bar collapses to a single plain total - the internal series
        // carries the combined value (5 + 3 = 8), the external series is always 0.
        AssertAreEqual(8, GetSeriesValueAtDayBarOccurrence(ChartDataJson, 'SCCTSKI', 0, PeriodStart, PeriodStart, false), 'Requested bar skill combined total.');
        AssertAreEqual(0, GetSeriesValueAtDayBarOccurrence(ChartDataJson, 'SCCTSKI', 1, PeriodStart, PeriodStart, false), 'Requested bar skill external half must be 0.');
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

        // [WHEN] BuildDayCapacityChartData is called.
        ChartDataJson := SkillCapacityAnalysisMgt.BuildDayCapacityChartData(PeriodStart);

        // [THEN] The skill gets no chart series at all - not even a zero-valued one.
        AssertIsTrue(not SeriesExists(ChartDataJson, 'SCCTSKC'), 'A skill with zero unassigned Requested Hours must not appear as a series.');
    end;

    [Test]
    procedure GivenCapacityAndAssignedHoursOnMultipleDays_WhenBuildChartData_ThenEachDayComputedIndependently()
    var
        PeriodStart: Date;
        MondayDate: Date;
        TuesdayDate: Date;
        WednesdayDate: Date;
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

        // [WHEN] BuildDayCapacityChartData is called.
        ChartDataJson := SkillCapacityAnalysisMgt.BuildDayCapacityChartData(PeriodStart);

        // [THEN] Assigned (6) is identical on both bars, every day - unaffected by capacity.
        AssertAreEqual(6, GetSeriesValueAtDayBar(ChartDataJson, 'Assigned Capacity - Internal', PeriodStart, MondayDate, true), 'Monday Assigned (Capacity bar).');
        AssertAreEqual(6, GetSeriesValueAtDayBar(ChartDataJson, 'Assigned Capacity - Internal', PeriodStart, MondayDate, false), 'Monday Assigned (Requested bar).');
        AssertAreEqual(6, GetSeriesValueAtDayBar(ChartDataJson, 'Assigned Capacity - Internal', PeriodStart, TuesdayDate, true), 'Tuesday Assigned (Capacity bar).');
        AssertAreEqual(6, GetSeriesValueAtDayBar(ChartDataJson, 'Assigned Capacity - Internal', PeriodStart, TuesdayDate, false), 'Tuesday Assigned (Requested bar).');
        AssertAreEqual(6, GetSeriesValueAtDayBar(ChartDataJson, 'Assigned Capacity - Internal', PeriodStart, WednesdayDate, true), 'Wednesday Assigned (Capacity bar).');
        AssertAreEqual(6, GetSeriesValueAtDayBar(ChartDataJson, 'Assigned Capacity - Internal', PeriodStart, WednesdayDate, false), 'Wednesday Assigned (Requested bar).');

        // [THEN] Internal free capacity (10 - 6 = 4) and the skill's Requested segment (3) are
        // computed the same, independent way on every day - no day is treated any differently
        // from any other (there is no "closed period" collapsing behavior in this codeunit).
        AssertAreEqual(4, GetSeriesValueAtDayBar(ChartDataJson, 'Free Capacity - Internal', PeriodStart, MondayDate, true), 'Monday Internal free capacity.');
        AssertAreEqual(3, GetSeriesValueAtDayBar(ChartDataJson, 'SCCTSKD', PeriodStart, MondayDate, false), 'Monday skill segment.');
        AssertAreEqual(4, GetSeriesValueAtDayBar(ChartDataJson, 'Free Capacity - Internal', PeriodStart, TuesdayDate, true), 'Tuesday Internal free capacity.');
        AssertAreEqual(3, GetSeriesValueAtDayBar(ChartDataJson, 'SCCTSKD', PeriodStart, TuesdayDate, false), 'Tuesday skill segment.');
        AssertAreEqual(4, GetSeriesValueAtDayBar(ChartDataJson, 'Free Capacity - Internal', PeriodStart, WednesdayDate, true), 'Wednesday Internal free capacity.');
        AssertAreEqual(3, GetSeriesValueAtDayBar(ChartDataJson, 'SCCTSKD', PeriodStart, WednesdayDate, false), 'Wednesday skill segment.');
    end;

    [Test]
    procedure GivenCapacityEntryButNoAssignmentYet_WhenBuildChartData_ThenCapacityBarShowsFullCapacity()
    var
        PeriodStart: Date;
        MondayDate: Date;
        TuesdayDate: Date;
        ChartDataJson: Text;
    begin
        // [GIVEN] Reproduces the reported bug: two internal resources each with 8 hours of real
        // calendar capacity (Res. Capacity Entry) on both Monday and Tuesday, but Day Planning
        // assignments only starting Tuesday - so Monday has real capacity but zero Day Planning
        // activity yet.
        Initialize();
        PeriodStart := GetTestMonday(21);
        ClearPeriodData(PeriodStart);
        MondayDate := PeriodStart;
        TuesdayDate := PeriodStart + 1;

        CreateTestResource('SCCTRM1', false);
        CreateTestResource('SCCTRM2', false);
        CreateTestSkillCode('SCCTSKM');
        InsertResCapacityEntry('SCCTRM1', MondayDate, 8);
        InsertResCapacityEntry('SCCTRM2', MondayDate, 8);
        InsertResCapacityEntry('SCCTRM1', TuesdayDate, 8);
        InsertResCapacityEntry('SCCTRM2', TuesdayDate, 8);
        InsertDayPlanningLine(TuesdayDate, 'SCCTRM1', 8, 'SCCTSKM', 0); // assignments start Tuesday only

        // [WHEN] BuildDayCapacityChartData is called.
        ChartDataJson := SkillCapacityAnalysisMgt.BuildDayCapacityChartData(PeriodStart);

        // [THEN] Monday's Capacity bar shows the full 16 hours of real calendar capacity (no Day
        // Planning assignment yet that day means nothing is subtracted) - NOT near-zero, which is
        // what happened when the Capacity bar was wrongly sourced from Day Planning Assigned
        // Hours instead of "Res. Capacity Entry".
        AssertAreEqual(16, GetSeriesValueAtDayBar(ChartDataJson, 'Free Capacity - Internal', PeriodStart, MondayDate, true), 'Monday Internal capacity must be the full calendar capacity.');
        AssertAreEqual(0, GetSeriesValueAtDayBar(ChartDataJson, 'Assigned Capacity - Internal', PeriodStart, MondayDate, true), 'Monday Assigned must be 0 - no Day Planning yet.');

        // [THEN] Tuesday's Capacity bar reflects the new assignment: free capacity drops to 8
        // (16 total - 8 assigned), Assigned shows 8.
        AssertAreEqual(8, GetSeriesValueAtDayBar(ChartDataJson, 'Free Capacity - Internal', PeriodStart, TuesdayDate, true), 'Tuesday Internal capacity must be net of the new assignment.');
        AssertAreEqual(8, GetSeriesValueAtDayBar(ChartDataJson, 'Assigned Capacity - Internal', PeriodStart, TuesdayDate, true), 'Tuesday Assigned (Capacity bar).');
    end;

    [Test]
    procedure GivenFullWeekPeriod_WhenBuildChartData_ThenEmptyDaysAreOmitted()
    var
        PeriodStart: Date;
        SaturdayDate: Date;
        SundayDate: Date;
        ChartDataJson: Text;
        CategoriesArray: JsonArray;
        DayLabelsArray: JsonArray;
    begin
        // [GIVEN] A period with capacity/requested data only on Monday - Saturday and Sunday are
        // deliberately left with no Res. Capacity Entry and no Day Planning rows at all, matching
        // a normal non-working weekend. Tuesday..Friday are likewise left empty so the whole
        // period only has one day of real data.
        Initialize();
        PeriodStart := GetTestMonday(22);
        ClearPeriodData(PeriodStart);
        SaturdayDate := PeriodStart + 5;
        SundayDate := PeriodStart + 6;

        CreateTestResource('SCCTRW1', false);
        CreateTestSkillCode('SCCTSKW');
        InsertResCapacityEntry('SCCTRW1', PeriodStart, 8);
        InsertDayPlanningLine(PeriodStart, '', 0, 'SCCTSKW', 2);

        // [WHEN] BuildDayCapacityChartData is called for the full 7-day period.
        ChartDataJson := SkillCapacityAnalysisMgt.BuildDayCapacityChartData(PeriodStart);

        // [THEN] Only Monday - the one day with any nonzero data - gets a category pair/day
        // label; every other day (including, but not limited to, Saturday/Sunday) is omitted
        // entirely rather than rendered as an empty/zero-height bar pair.
        GetCategoriesArray(ChartDataJson, CategoriesArray);
        GetDayLabelsArray(ChartDataJson, DayLabelsArray);
        AssertAreEqual(2, CategoriesArray.Count(), 'Only Monday''s Capacity/Requested category pair should be present.');
        AssertAreEqual(1, DayLabelsArray.Count(), 'Only Monday''s day label should be present.');
        AssertIsTrue(CategoryTextExists(ChartDataJson, CapacityCategoryText(PeriodStart)), 'Monday Capacity category must exist.');
        AssertIsTrue(CategoryTextExists(ChartDataJson, RequestedCategoryText(PeriodStart)), 'Monday Requested category must exist.');
        AssertIsTrue(not CategoryTextExists(ChartDataJson, CapacityCategoryText(SaturdayDate)), 'Saturday Capacity category must be omitted.');
        AssertIsTrue(not CategoryTextExists(ChartDataJson, RequestedCategoryText(SaturdayDate)), 'Saturday Requested category must be omitted.');
        AssertIsTrue(not CategoryTextExists(ChartDataJson, CapacityCategoryText(SundayDate)), 'Sunday Capacity category must be omitted.');
        AssertIsTrue(not CategoryTextExists(ChartDataJson, RequestedCategoryText(SundayDate)), 'Sunday Requested category must be omitted.');

        // [THEN] Monday's own values are unaffected by the omission of the other 6 days.
        AssertAreEqual(8, GetSeriesValueAtDayBar(ChartDataJson, 'Free Capacity - Internal', PeriodStart, PeriodStart, true), 'Monday Internal capacity.');
        AssertAreEqual(2, GetSeriesValueAtDayBar(ChartDataJson, 'SCCTSKW', PeriodStart, PeriodStart, false), 'Monday skill Requested segment.');
    end;

    [Test]
    procedure GivenDayWithOnlyUnassignedSkillRequest_WhenBuildChartData_ThenDayIsIncluded()
    var
        PeriodStart: Date;
        MondayDate: Date;
        ChartDataJson: Text;
    begin
        // [GIVEN] A day with NO Assigned Hours and NO Res. Capacity Entry anywhere - the only
        // nonzero data in the whole period is one unassigned skill-requested line on Monday. This
        // exercises the "any active skill's requested hours" branch of the inclusion check on its
        // own, independent of Assigned/Capacity.
        Initialize();
        PeriodStart := GetTestMonday(26);
        ClearPeriodData(PeriodStart);
        MondayDate := PeriodStart;

        CreateTestSkillCode('SCCTSKX');
        InsertDayPlanningLine(MondayDate, '', 0, 'SCCTSKX', 2);

        // [WHEN] BuildDayCapacityChartData is called.
        ChartDataJson := SkillCapacityAnalysisMgt.BuildDayCapacityChartData(PeriodStart);

        // [THEN] Monday is still included - a skill-only nonzero day is not treated as empty.
        AssertIsTrue(CategoryTextExists(ChartDataJson, RequestedCategoryText(MondayDate)), 'A day with only skill-requested hours must still be included.');
        AssertAreEqual(2, GetSeriesValueAtDayBar(ChartDataJson, 'SCCTSKX', PeriodStart, MondayDate, false), 'Skill segment value on the Requested bar.');
    end;

    [Test]
    procedure GivenPeriodWithNoDataAnywhere_WhenBuildChartData_ThenChartRendersEmptyWithoutError()
    var
        PeriodStart: Date;
        ChartDataJson: Text;
        CategoriesArray: JsonArray;
        DayLabelsArray: JsonArray;
    begin
        // [GIVEN] A period with no Day Planning rows and no Res. Capacity Entry rows at all - the
        // edge case where every single one of the 7 days is empty.
        Initialize();
        PeriodStart := GetTestMonday(27);
        ClearPeriodData(PeriodStart);

        // [WHEN] BuildDayCapacityChartData is called.
        ChartDataJson := SkillCapacityAnalysisMgt.BuildDayCapacityChartData(PeriodStart);

        // [THEN] No error is raised, and the chart comes back with empty categories/dayLabels -
        // not 7 days' worth of zero-valued bars.
        GetCategoriesArray(ChartDataJson, CategoriesArray);
        GetDayLabelsArray(ChartDataJson, DayLabelsArray);
        AssertAreEqual(0, CategoriesArray.Count(), 'Categories must be empty when no day in the period has any data.');
        AssertAreEqual(0, DayLabelsArray.Count(), 'DayLabels must be empty when no day in the period has any data.');
    end;

    // ================================================================
    // BuildDayCapacityAuditBuffer (codeunit 50662) - audit trail behind page 50692's
    // "Chart Audit Trail" factbox. Must never drift from BuildDayCapacityChartData's own JSON,
    // since both are built from the same shared per-day helper (CalcDaySegments).
    // ================================================================

    [Test]
    procedure GivenMultiDayCapacity_WhenBuildAuditBuffer_ThenRowsMatchChartData()
    var
        PeriodStart: Date;
        MondayDate: Date;
        TuesdayDate: Date;
        WednesdayDate: Date;
        ChartDataJson: Text;
        AuditBuffer: Record "Day Capacity Chart Audit Buf" temporary;
    begin
        // [GIVEN] Same shape of setup as GivenCapacityAndAssignedHoursOnMultipleDays_WhenBuildChartData_ThenEachDayComputedIndependently:
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
        // the same inputs.
        ChartDataJson := SkillCapacityAnalysisMgt.BuildDayCapacityChartData(PeriodStart);
        SkillCapacityAnalysisMgt.BuildDayCapacityAuditBuffer(AuditBuffer, PeriodStart);

        // [THEN] Specific (Day, Bar Type, Segment) buffer rows match the equivalent chart JSON
        // category/series value.
        AssertIsTrue(FindAuditRow(AuditBuffer, MondayDate, Enum::"Day Capacity Chart Bar Type"::Capacity, 'Assigned'),
            'Monday Capacity/Assigned row must exist.');
        AssertAreEqual(GetSeriesValueAtDayBar(ChartDataJson, 'Assigned Capacity - Internal', PeriodStart, MondayDate, true), AuditBuffer.Value,
            'Monday Capacity/Assigned value must match the chart.');

        AssertIsTrue(FindAuditRow(AuditBuffer, WednesdayDate, Enum::"Day Capacity Chart Bar Type"::Capacity, 'Internal'),
            'Wednesday Capacity/Internal row must exist.');
        AssertAreEqual(GetSeriesValueAtDayBar(ChartDataJson, 'Free Capacity - Internal', PeriodStart, WednesdayDate, true), AuditBuffer.Value,
            'Wednesday Capacity/Internal value must match the chart.');

        AssertIsTrue(FindAuditRow(AuditBuffer, WednesdayDate, Enum::"Day Capacity Chart Bar Type"::Requested, 'SCCTSKE'),
            'Wednesday Requested/SCCTSKE row must exist.');
        AssertAreEqual(GetSeriesValueAtDayBar(ChartDataJson, 'SCCTSKE', PeriodStart, WednesdayDate, false), AuditBuffer.Value,
            'Wednesday Requested/SCCTSKE value must match the chart.');
    end;

    [Test]
    procedure GivenCapacityAndSkillRequest_WhenBuildAuditBuffer_ThenRowsHoldRealValues()
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

        // [WHEN] BuildDayCapacityAuditBuffer is called.
        SkillCapacityAnalysisMgt.BuildDayCapacityAuditBuffer(AuditBuffer, PeriodStart);

        // [THEN] Monday's Capacity/Internal row holds the true free capacity (10 Capacity - 6
        // Assigned Hours = 4), not the Day Planning Assigned Hours figure and not 0.
        AssertIsTrue(FindAuditRow(AuditBuffer, MondayDate, Enum::"Day Capacity Chart Bar Type"::Capacity, 'Internal'),
            'Monday Capacity/Internal row must exist.');
        AssertAreEqual(4, AuditBuffer.Value, 'Monday Capacity/Internal must be net free capacity (10 - 6).');

        // [THEN] Monday's Requested/SCCTSKF row still holds the unassigned Requested Hours (3).
        AssertIsTrue(FindAuditRow(AuditBuffer, MondayDate, Enum::"Day Capacity Chart Bar Type"::Requested, 'SCCTSKF'),
            'Monday Requested/SCCTSKF row must exist.');
        AssertAreEqual(3, AuditBuffer.Value, 'Monday Requested/SCCTSKF must hold the unassigned Requested Hours.');

        // [THEN] Monday's Capacity/Assigned row holds the combined (internal+external) Assigned
        // Hours total (6), matching the chart's "Assigned" series.
        AssertIsTrue(FindAuditRow(AuditBuffer, MondayDate, Enum::"Day Capacity Chart Bar Type"::Capacity, 'Assigned'),
            'Monday Capacity/Assigned row must exist.');
        AssertAreEqual(6, AuditBuffer.Value, 'Monday Capacity/Assigned must hold the combined Assigned Hours total.');
    end;

    [Test]
    procedure GivenSkillWithInternalAndExternalRequested_WhenBuildAuditBuffer_ThenRequestedRowsCollapseToCombinedTotal()
    var
        PeriodStart: Date;
        MondayDate: Date;
        AuditBuffer: Record "Day Capacity Chart Audit Buf" temporary;
    begin
        // [GIVEN] Two unassigned Day Planning lines on Monday for the same skill: one with no
        // "Requested Resource No." set (Internal, 5 hours) and one targeting an external
        // resource (External, 3 hours).
        Initialize();
        PeriodStart := GetTestMonday(25);
        ClearPeriodData(PeriodStart);
        MondayDate := PeriodStart;

        CreateTestResource('SCCTRSF', true);
        CreateTestSkillCode('SCCTSKJ');
        InsertDayPlanningLine(MondayDate, '', 0, 'SCCTSKJ', 5);
        InsertDayPlanningLineWithRequestedResource(MondayDate, '', 0, 'SCCTSKJ', 3, 'SCCTRSF');

        // [WHEN] BuildDayCapacityAuditBuffer is called.
        SkillCapacityAnalysisMgt.BuildDayCapacityAuditBuffer(AuditBuffer, PeriodStart);

        // [THEN] The Requested bar's first SCCTSKJ row holds the combined total (5 + 3 = 8), the
        // second SCCTSKJ row is always 0 - matching the chart's collapse.
        AssertIsTrue(FindAuditRowOccurrence(AuditBuffer, MondayDate, Enum::"Day Capacity Chart Bar Type"::Requested, 'SCCTSKJ', 0),
            'Monday Requested/SCCTSKJ combined-total row must exist.');
        AssertAreEqual(8, AuditBuffer.Value, 'Monday Requested/SCCTSKJ combined-total row must hold 5 + 3.');
        AssertIsTrue(FindAuditRowOccurrence(AuditBuffer, MondayDate, Enum::"Day Capacity Chart Bar Type"::Requested, 'SCCTSKJ', 1),
            'Monday Requested/SCCTSKJ second row must exist.');
        AssertAreEqual(0, AuditBuffer.Value, 'Monday Requested/SCCTSKJ second row must always be 0.');

        // [THEN] Both Capacity-bar SCCTSKJ rows stay 0 (skills never appear on the Capacity bar).
        AssertIsTrue(FindAuditRowOccurrence(AuditBuffer, MondayDate, Enum::"Day Capacity Chart Bar Type"::Capacity, 'SCCTSKJ', 0),
            'Monday Capacity/SCCTSKJ first row must exist.');
        AssertAreEqual(0, AuditBuffer.Value, 'Monday Capacity/SCCTSKJ first row must be 0.');
        AssertIsTrue(FindAuditRowOccurrence(AuditBuffer, MondayDate, Enum::"Day Capacity Chart Bar Type"::Capacity, 'SCCTSKJ', 1),
            'Monday Capacity/SCCTSKJ second row must exist.');
        AssertAreEqual(0, AuditBuffer.Value, 'Monday Capacity/SCCTSKJ second row must be 0.');
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

        // [WHEN] BuildDayCapacityAuditBuffer is called with no filters.
        SkillCapacityAnalysisMgt.BuildDayCapacityAuditBuffer(AuditBuffer, PeriodStart);

        // [THEN] The skill gets no buffer rows at all - not even a zero-valued one - on either
        // bar type.
        AssertIsTrue(not FindAuditRow(AuditBuffer, PeriodStart, Enum::"Day Capacity Chart Bar Type"::Capacity, 'SCCTSKG'),
            'A skill with zero unassigned Requested Hours must have no Capacity-bar row.');
        AssertIsTrue(not FindAuditRow(AuditBuffer, PeriodStart, Enum::"Day Capacity Chart Bar Type"::Requested, 'SCCTSKG'),
            'A skill with zero unassigned Requested Hours must have no Requested-bar row.');
    end;
}
