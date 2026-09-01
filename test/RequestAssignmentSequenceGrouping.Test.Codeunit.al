codeunit 60027 "Req Assign Seq Grouping Tests"
{
    // Tests for codeunit 50604 "DHX Data Handler" - procedure ReqAssign_BuildPlanningDataJson,
    // specifically the "dayTaskLines" JSON it emits for page 50710 "DHX Request Assignment
    // Board"'s left "Sequences" tree. That tree groups lines client-side purely by the
    // `sequenceKey` string AL sends - as of this feature, that key includes table 50610 "Day
    // Planning"."Sequence No." (field 9) so two independently-created threads sharing the same
    // [Job No., Job Task No., Skill] render as SEPARATE rows (e.g. "Elektrisch - Seq 1" and
    // "- Seq 2"), matching the Day Planning Sequence add-in's own row grouping, instead of
    // collapsing into one row per Skill the way it did before "Sequence No." existed.
    Subtype = Test;
    TestPermissions = Disabled;

    var
        IsInitialized: Boolean;
        TestJobNo: Code[20];
        TestJobTaskNo: Code[20];
        TestSkillCode: Code[10];
        TestOtherSkillCode: Code[10];
        TestThirdSkillCode: Code[10];

    local procedure Initialize()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        SkillCode: Record "Skill Code";
    begin
        TestJobNo := 'RASGT-JOB';
        TestJobTaskNo := '1000';
        TestSkillCode := 'RASGTSKL';
        TestOtherSkillCode := 'RASGTSK2';
        TestThirdSkillCode := 'RASGTSK3';

        if IsInitialized then
            exit;

        if not Job.Get(TestJobNo) then begin
            Job.Init();
            Job."No." := TestJobNo;
            Job.Description := 'Req Assign Seq Grouping Test Job';
            Job.Insert();
        end;
        if not JobTask.Get(TestJobNo, TestJobTaskNo) then begin
            JobTask.Init();
            JobTask."Job No." := TestJobNo;
            JobTask."Job Task No." := TestJobTaskNo;
            JobTask.Description := 'Req Assign Seq Grouping Test Job Task';
            JobTask."Job Task Type" := JobTask."Job Task Type"::Posting;
            JobTask.Insert();
        end;

        if not SkillCode.Get(TestSkillCode) then begin
            SkillCode.Init();
            SkillCode.Code := TestSkillCode;
            SkillCode.Description := 'Req Assign Seq Grouping Test Skill';
            SkillCode.Insert();
        end;
        if not SkillCode.Get(TestOtherSkillCode) then begin
            SkillCode.Init();
            SkillCode.Code := TestOtherSkillCode;
            SkillCode.Description := 'Req Assign Seq Grouping Test Skill 2';
            SkillCode.Insert();
        end;
        if not SkillCode.Get(TestThirdSkillCode) then begin
            SkillCode.Init();
            SkillCode.Code := TestThirdSkillCode;
            SkillCode.Description := 'Req Assign Seq Grouping Test Skill 3';
            SkillCode.Insert();
        end;

        IsInitialized := true;
        Commit();
    end;

    local procedure ClearDayPlanningsFor(JobNo: Code[20]; JobTaskNo: Code[20])
    var
        DayPlanning: Record "Day Planning";
    begin
        DayPlanning.SetRange("Job No.", JobNo);
        DayPlanning.SetRange("Job Task No.", JobTaskNo);
        DayPlanning.DeleteAll();
    end;

    /// <summary>
    /// Inserts one Day Planning record via plain Init/field-assignment/Insert(true) (same
    /// direct-CUD convention as test/DayPlanningSequenceNo.Test.Codeunit.al) with Start/End Time
    /// Requested set, so the line's "requestedDuration" isn't 0 and it's a realistic scheduler
    /// row. "Sequence No." is left at 0 so codeunit 50695's CalcSequence (fired from table 50610's
    /// OnInsert) assigns it - the test observes whatever it actually assigns, exactly like a real
    /// page-driven insert would.
    /// </summary>
    local procedure InsertDayPlanningDirect(DayLineNo: Integer; Skill: Code[10]; PlanDate: Date): Record "Day Planning"
    var
        DayPlanning: Record "Day Planning";
    begin
        DayPlanning.Init();
        DayPlanning."Job No." := TestJobNo;
        DayPlanning."Job Task No." := TestJobTaskNo;
        DayPlanning."Day Line No." := DayLineNo;
        DayPlanning.Skill := Skill;
        DayPlanning."Plan Date" := PlanDate;
        DayPlanning."Start Time Requested" := 080000T;
        DayPlanning."End Time Requested" := 160000T;
        DayPlanning.Insert(true);
        exit(DayPlanning);
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
    /// Finds the "dayTaskLines" entry whose "id" is "JobNo|JobTaskNo|DayLineNo" (same convention
    /// ReqAssign_BuildDayTaskLinesJson itself builds IdTxt with) and returns its "sequenceKey"/
    /// "sequenceNo". Fails the test outright if no such entry exists in PlanningDataJson.
    /// </summary>
    local procedure FindDayTaskLine(PlanningDataJson: Text; DayLineNo: Integer; var SequenceKeyTxt: Text; var SequenceNo: Integer)
    var
        RootObj: JsonObject;
        LinesToken: JsonToken;
        LinesArr: JsonArray;
        LineToken: JsonToken;
        LineObj: JsonObject;
        FieldToken: JsonToken;
        WantedIdTxt: Text;
    begin
        WantedIdTxt := StrSubstNo('%1|%2|%3', TestJobNo, TestJobTaskNo, DayLineNo);

        RootObj.ReadFrom(PlanningDataJson);
        RootObj.Get('dayTaskLines', LinesToken);
        LinesArr := LinesToken.AsArray();

        foreach LineToken in LinesArr do begin
            LineObj := LineToken.AsObject();
            LineObj.Get('id', FieldToken);
            if FieldToken.AsValue().AsText() = WantedIdTxt then begin
                LineObj.Get('sequenceKey', FieldToken);
                SequenceKeyTxt := FieldToken.AsValue().AsText();
                LineObj.Get('sequenceNo', FieldToken);
                SequenceNo := FieldToken.AsValue().AsInteger();
                exit;
            end;
        end;

        Error('Expected a "dayTaskLines" entry with id "%1" in the planning data JSON, but none was found.', WantedIdTxt);
    end;

    [Test]
    procedure GivenTwoIndependentThreadsSameJobTaskSkill_WhenBuildPlanningData_ThenDistinctSequenceKeysAndMatchingSequenceNo()
    var
        FirstLine: Record "Day Planning";
        SecondLine: Record "Day Planning";
        DHXDataHandler: Codeunit "DHX Data Handler";
        PlanDate: Date;
        PlanningDataJson: Text;
        FirstKeyTxt: Text;
        SecondKeyTxt: Text;
        FirstSeqNo: Integer;
        SecondSeqNo: Integer;
    begin
        // [GIVEN] Two Day Planning lines sharing the same [Job No., Job Task No., Skill] and the
        // same Plan Date - CalcSequence (codeunit 50695) assigns them distinct Sequence No.s (1
        // and 2), exactly like two independently-created "Elektrisch" threads on the same day.
        Initialize();
        ClearDayPlanningsFor(TestJobNo, TestJobTaskNo);
        PlanDate := WorkDate();
        FirstLine := InsertDayPlanningDirect(10000, TestSkillCode, PlanDate);
        SecondLine := InsertDayPlanningDirect(20000, TestSkillCode, PlanDate);
        AssertAreEqual(1, FirstLine."Sequence No.", 'Sanity check: first line should get Sequence No. 1.');
        AssertAreEqual(2, SecondLine."Sequence No.", 'Sanity check: second line should get Sequence No. 2.');

        // [WHEN] The Request Assignment Board's planning data is built for a range covering that date
        PlanningDataJson := DHXDataHandler.ReqAssign_BuildPlanningDataJson(PlanDate, PlanDate);

        // [THEN] Each line's "sequenceNo" in the JSON matches its actual Sequence No....
        FindDayTaskLine(PlanningDataJson, 10000, FirstKeyTxt, FirstSeqNo);
        FindDayTaskLine(PlanningDataJson, 20000, SecondKeyTxt, SecondSeqNo);
        AssertAreEqual(1, FirstSeqNo, 'First line''s JSON "sequenceNo" should match its Sequence No. (1).');
        AssertAreEqual(2, SecondSeqNo, 'Second line''s JSON "sequenceNo" should match its Sequence No. (2).');

        // ...and, critically, they get DIFFERENT "sequenceKey" values - two separate rows in the
        // Request Assignment Board's left tree, not one collapsed "Skill" row.
        AssertIsTrue(FirstKeyTxt <> SecondKeyTxt,
            StrSubstNo('Two independent threads sharing the same Job/Task/Skill must get different sequenceKey values so they render as separate rows, but both got "%1".', FirstKeyTxt));

        // Exact expected shape: "JobNo|JobTaskNo|Skill|SequenceNo"
        AssertAreEqual(StrSubstNo('%1|%2|%3|1', TestJobNo, TestJobTaskNo, TestSkillCode), FirstKeyTxt, 'First line''s sequenceKey should end in its own Sequence No.');
        AssertAreEqual(StrSubstNo('%1|%2|%3|2', TestJobNo, TestJobTaskNo, TestSkillCode), SecondKeyTxt, 'Second line''s sequenceKey should end in its own Sequence No.');
    end;

    // ================================================================
    // Part B.2 pagination tests - codeunit 50604's ReqAssign_BuildPlanningDataJson_Paged /
    // ReqAssign_BuildDayTaskLinesJson_Paged / ReqAssign_BuildDayTaskLinesJson_ForKeys. Fixture: 3
    // sequences (each its own Skill, so each independently gets Sequence No. 1 - see
    // InsertPagingFixture) inserted in DEFINITE Day Line No. order so DayPlanning.FindSet()'s
    // primary-key scan always visits them Sequence A (2 lines) -> Sequence B (3 lines) ->
    // Sequence C (2 lines), 7 lines total.
    // ================================================================

    /// <summary>
    /// A fixed far-future date, deliberately NOT WorkDate() - ReqAssign_BuildPlanningDataJson (and
    /// its _Paged/_ForKeys variants) have no Job No. filter by design ("any Job/Task/Skill", see
    /// their own doc comments), so the paging tests' unfiltered id-count assertions need a date
    /// window guaranteed free of real CRONUS NL production Day Plannings - WorkDate() (today) is
    /// squarely inside the real dataset's populated range and collides with it.
    /// </summary>
    local procedure PagingFixtureIsolatedDate(): Date
    begin
        exit(DMY2Date(1, 1, 2050));
    end;

    local procedure InsertPagingFixture(var SeqAKey: Text; var SeqBKey: Text; var SeqCKey: Text)
    var
        PlanDate: Date;
    begin
        Initialize();
        ClearDayPlanningsFor(TestJobNo, TestJobTaskNo);
        PlanDate := PagingFixtureIsolatedDate();

        // Sequence A - Skill 1, 2 distinct dates (each date has only this one row for Skill 1, so
        // CalcSequence independently assigns Sequence No. 1 to both - same Sequence No. across
        // dates is exactly what makes them one "sequence"/row per sequenceKey).
        InsertDayPlanningDirect(10000, TestSkillCode, PlanDate);
        InsertDayPlanningDirect(20000, TestSkillCode, PlanDate + 1);

        // Sequence B - Skill 2, 3 distinct dates.
        InsertDayPlanningDirect(30000, TestOtherSkillCode, PlanDate);
        InsertDayPlanningDirect(40000, TestOtherSkillCode, PlanDate + 1);
        InsertDayPlanningDirect(50000, TestOtherSkillCode, PlanDate + 2);

        // Sequence C - Skill 3, 2 distinct dates.
        InsertDayPlanningDirect(60000, TestThirdSkillCode, PlanDate);
        InsertDayPlanningDirect(70000, TestThirdSkillCode, PlanDate + 1);

        SeqAKey := StrSubstNo('%1|%2|%3|1', TestJobNo, TestJobTaskNo, TestSkillCode);
        SeqBKey := StrSubstNo('%1|%2|%3|1', TestJobNo, TestJobTaskNo, TestOtherSkillCode);
        SeqCKey := StrSubstNo('%1|%2|%3|1', TestJobNo, TestJobTaskNo, TestThirdSkillCode);
    end;

    local procedure GetLinesArrFromPlanningDataJson(PlanningDataJson: Text): JsonArray
    var
        RootObj: JsonObject;
        LinesToken: JsonToken;
    begin
        RootObj.ReadFrom(PlanningDataJson);
        RootObj.Get('dayTaskLines', LinesToken);
        exit(LinesToken.AsArray());
    end;

    local procedure GetLinesArrFromRawArrayJson(ArrJsonTxt: Text): JsonArray
    var
        LinesArr: JsonArray;
    begin
        if ArrJsonTxt = '' then
            exit(LinesArr);
        LinesArr.ReadFrom(ArrJsonTxt);
        exit(LinesArr);
    end;

    /// <summary>
    /// Extracts every "id" value from a "dayTaskLines"-shaped JsonArray, and the count of entries
    /// whose "sequenceKey" equals WantedSequenceKey (so callers can assert both "which ids are
    /// present" and "how many lines of a given sequence made it in", without a second pass).
    /// </summary>
    local procedure GetIdsAndSequenceCount(LinesArr: JsonArray; WantedSequenceKey: Text; var Ids: List of [Text]; var SequenceLineCount: Integer)
    var
        LineTok: JsonToken;
        LineObj: JsonObject;
        FieldTok: JsonToken;
    begin
        Clear(Ids);
        SequenceLineCount := 0;
        foreach LineTok in LinesArr do begin
            LineObj := LineTok.AsObject();
            LineObj.Get('id', FieldTok);
            Ids.Add(FieldTok.AsValue().AsText());
            LineObj.Get('sequenceKey', FieldTok);
            if FieldTok.AsValue().AsText() = WantedSequenceKey then
                SequenceLineCount += 1;
        end;
    end;

    local procedure ListContains(Ids: List of [Text]; WantedId: Text): Boolean
    var
        IdTxt: Text;
    begin
        foreach IdTxt in Ids do
            if IdTxt = WantedId then
                exit(true);
        exit(false);
    end;

    /// <summary>
    /// True iff both lists have the same count and every element of ListA is present in ListB (ids
    /// are unique by construction in this fixture, so this is a genuine set-equality check, not
    /// just "same size").
    /// </summary>
    local procedure ListsAreSetEqual(ListA: List of [Text]; ListB: List of [Text]): Boolean
    var
        IdTxt: Text;
    begin
        if ListA.Count() <> ListB.Count() then
            exit(false);
        foreach IdTxt in ListA do
            if not ListContains(ListB, IdTxt) then
                exit(false);
        exit(true);
    end;

    /// <summary>
    /// Parses RemainingSequenceKeys (a JSON array of strings, as produced by
    /// ReqAssign_BuildDayTaskLinesJson_Paged/ReqAssign_BuildPlanningDataJson_Paged) into a plain
    /// List of [Text].
    /// </summary>
    local procedure ParseRemainingSequenceKeys(RemainingSequenceKeysJson: Text): List of [Text]
    var
        KeysArr: JsonArray;
        KeyTok: JsonToken;
        Keys: List of [Text];
    begin
        if RemainingSequenceKeysJson = '' then
            exit(Keys);
        KeysArr.ReadFrom(RemainingSequenceKeysJson);
        foreach KeyTok in KeysArr do
            Keys.Add(KeyTok.AsValue().AsText());
        exit(Keys);
    end;

    [Test]
    procedure GivenSeqCrossesMaxLinesBoundary_WhenBuildPlanningDataPaged_ThenIncludedWholeAndThirdDeferred()
    var
        DHXDataHandler: Codeunit "DHX Data Handler";
        PlanDate: Date;
        SeqAKey: Text;
        SeqBKey: Text;
        SeqCKey: Text;
        PlanningDataJson: Text;
        RemainingSequenceKeys: Text;
        FirstPageIds: List of [Text];
        RemainingKeysList: List of [Text];
        SeqBLineCountInFirstPage: Integer;
    begin
        // [GIVEN] 3 sequences (A=2 lines, B=3 lines, C=2 lines, visited in that Day Line No. order)
        InsertPagingFixture(SeqAKey, SeqBKey, SeqCKey);
        PlanDate := PagingFixtureIsolatedDate();

        // [WHEN] Building the paged payload with MaxLines=3 - A alone (2 lines) is under the
        // cutoff, but including B (3 more lines, running total 5) is what actually crosses it.
        PlanningDataJson := DHXDataHandler.ReqAssign_BuildPlanningDataJson_Paged(PlanDate, PlanDate + 2, 3, RemainingSequenceKeys);

        // [THEN] The first page still contains B's Sequence WHOLE (all 3 lines) - it must never be
        // split just because the running total crossed MaxLines partway through it.
        GetIdsAndSequenceCount(GetLinesArrFromPlanningDataJson(PlanningDataJson), SeqBKey, FirstPageIds, SeqBLineCountInFirstPage);
        AssertAreEqual(3, SeqBLineCountInFirstPage, 'Sequence B (which the MaxLines=3 cutoff falls inside) must be included WHOLE on the first page (3 lines), never split.');
        AssertAreEqual(5, FirstPageIds.Count(), 'First page must contain exactly Sequence A (2) + Sequence B (3) = 5 lines.');
        AssertIsTrue(ListContains(FirstPageIds, StrSubstNo('%1|%2|10000', TestJobNo, TestJobTaskNo)), 'First page must contain Sequence A''s first line.');
        AssertIsTrue(ListContains(FirstPageIds, StrSubstNo('%1|%2|50000', TestJobNo, TestJobTaskNo)), 'First page must contain Sequence B''s LAST line (50000) too - the whole crossing sequence, not just enough lines to reach MaxLines.');
        AssertIsTrue(not ListContains(FirstPageIds, StrSubstNo('%1|%2|60000', TestJobNo, TestJobTaskNo)), 'First page must NOT contain any of Sequence C - it comes entirely after the crossing point.');

        // [THEN] Sequence C (untouched by the first page) is exactly what's reported as remaining.
        RemainingKeysList := ParseRemainingSequenceKeys(RemainingSequenceKeys);
        AssertAreEqual(1, RemainingKeysList.Count(), 'Exactly one sequenceKey (Sequence C) should remain.');
        AssertIsTrue(ListContains(RemainingKeysList, SeqCKey), 'The remaining sequenceKey must be Sequence C''s.');
    end;

    [Test]
    procedure GivenPagedFirstPagePlusBackgroundRemainder_WhenCombined_ThenSetEqualToNonPagedFullOutput()
    var
        DHXDataHandler: Codeunit "DHX Data Handler";
        PlanDate: Date;
        SeqAKey: Text;
        SeqBKey: Text;
        SeqCKey: Text;
        FullPlanningDataJson: Text;
        PagedPlanningDataJson: Text;
        RemainingSequenceKeys: Text;
        RemainderLinesJson: Text;
        FullIds: List of [Text];
        FirstPageIds: List of [Text];
        RemainderIds: List of [Text];
        CombinedIds: List of [Text];
        IdTxt: Text;
        UnusedCount: Integer;
    begin
        // [GIVEN] The same 3-sequence/7-line fixture
        InsertPagingFixture(SeqAKey, SeqBKey, SeqCKey);
        PlanDate := PagingFixtureIsolatedDate();

        // [WHEN] Building the full non-paged payload (ground truth) ...
        FullPlanningDataJson := DHXDataHandler.ReqAssign_BuildPlanningDataJson(PlanDate, PlanDate + 2);
        GetIdsAndSequenceCount(GetLinesArrFromPlanningDataJson(FullPlanningDataJson), '', FullIds, UnusedCount);
        AssertAreEqual(7, FullIds.Count(), 'Sanity check: the non-paged builder must return all 7 fixture lines.');

        // ... and, separately, the paged first page (MaxLines=3, same as the previous test) plus
        // the background remainder built via ReqAssign_BuildDayTaskLinesJson_ForKeys for whatever
        // sequenceKeys the paged call reported as remaining (mirrors what codeunit "ReqAssign BG
        // Day Task Lines" does for the real Page Background Task).
        PagedPlanningDataJson := DHXDataHandler.ReqAssign_BuildPlanningDataJson_Paged(PlanDate, PlanDate + 2, 3, RemainingSequenceKeys);
        GetIdsAndSequenceCount(GetLinesArrFromPlanningDataJson(PagedPlanningDataJson), '', FirstPageIds, UnusedCount);

        RemainderLinesJson := DHXDataHandler.ReqAssign_BuildDayTaskLinesJson_ForKeys(PlanDate, PlanDate + 2, RemainingSequenceKeys);
        GetIdsAndSequenceCount(GetLinesArrFromRawArrayJson(RemainderLinesJson), '', RemainderIds, UnusedCount);

        // [THEN] First page (5) + remainder (2) = 7, and the combined id SET (order-independent) is
        // exactly the same as the non-paged builder's full output - pagination changes nothing
        // about what data ultimately reaches the client, only when/how it arrives.
        AssertAreEqual(5, FirstPageIds.Count(), 'Sanity check: first page should hold 5 lines (Sequence A + B).');
        AssertAreEqual(2, RemainderIds.Count(), 'Sanity check: remainder should hold 2 lines (Sequence C).');

        foreach IdTxt in FirstPageIds do
            CombinedIds.Add(IdTxt);
        foreach IdTxt in RemainderIds do
            CombinedIds.Add(IdTxt);

        AssertIsTrue(ListsAreSetEqual(CombinedIds, FullIds),
            'Combining the paged first page with the background remainder must be SET-EQUAL to the non-paged builder''s full output.');
    end;

    [Test]
    procedure GivenLinesWithDifferentSkills_WhenBuildPlanningData_ThenDifferentSequenceKeysRegardlessOfSequenceNo()
    var
        SkillALine: Record "Day Planning";
        SkillBLine: Record "Day Planning";
        DHXDataHandler: Codeunit "DHX Data Handler";
        PlanDate: Date;
        PlanningDataJson: Text;
        SkillAKeyTxt: Text;
        SkillBKeyTxt: Text;
        SkillASeqNo: Integer;
        SkillBSeqNo: Integer;
    begin
        // [GIVEN] Two lines on the same date with DIFFERENT skills - each independently gets
        // Sequence No. 1 (dates/skill combos are independent for collision purposes), so this
        // proves the key isn't accidentally collapsing on Sequence No. alone.
        Initialize();
        ClearDayPlanningsFor(TestJobNo, TestJobTaskNo);
        PlanDate := WorkDate();
        SkillALine := InsertDayPlanningDirect(10000, TestSkillCode, PlanDate);
        SkillBLine := InsertDayPlanningDirect(20000, TestOtherSkillCode, PlanDate);
        AssertAreEqual(1, SkillALine."Sequence No.", 'Sanity check: Skill A line should get Sequence No. 1.');
        AssertAreEqual(1, SkillBLine."Sequence No.", 'Sanity check: Skill B line should also get Sequence No. 1 (independent skill).');

        // [WHEN] Planning data is built
        PlanningDataJson := DHXDataHandler.ReqAssign_BuildPlanningDataJson(PlanDate, PlanDate);

        // [THEN] Still two distinct rows, keyed apart by Skill this time
        FindDayTaskLine(PlanningDataJson, 10000, SkillAKeyTxt, SkillASeqNo);
        FindDayTaskLine(PlanningDataJson, 20000, SkillBKeyTxt, SkillBSeqNo);
        AssertIsTrue(SkillAKeyTxt <> SkillBKeyTxt, 'Lines with different Skills must get different sequenceKey values even when both hold Sequence No. 1.');
    end;
}
