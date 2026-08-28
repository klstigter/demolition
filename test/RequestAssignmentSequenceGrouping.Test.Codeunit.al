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
