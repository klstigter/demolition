codeunit 60023 "Day Planning Seq No. Tests"
{
    // Tests for table 50610 "Day Planning"'s OnInsert/OnModify triggers wiring into codeunit 50695
    // "Day Planning Sequence Mgt."'s CalcSequence - verifies the contract holds for CUD performed
    // DIRECTLY against the table (Rec.Insert()/Rec.Modify()/Rec.Delete()), exactly as a BC page
    // (Day Plannings list/card, drag-resize on a scheduler) would issue it - NOT via codeunit
    // 50695's own GenerateSequence/RegenerateSequence batch procedures, which have their own
    // coverage elsewhere. Contract under test: "Sequence No." must be non-zero whenever
    // Skill <> '' AND "Plan Date" <> 0D, and must never collide with another line sharing
    // [Job No., Job Task No., Skill, Plan Date].
    Subtype = Test;
    TestPermissions = Disabled;

    var
        IsInitialized: Boolean;
        TestJobNo: Code[20];
        TestJobTaskNo: Code[20];
        TestSkillCode: Code[10];

    local procedure Initialize()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        SkillCode: Record "Skill Code";
    begin
        TestJobNo := 'DPSNT-JOB';
        TestJobTaskNo := '1000';
        TestSkillCode := 'DPSNTSKL';

        if IsInitialized then
            exit;

        // [GIVEN] A Job + Job Task to attach Day Planning records to
        if not Job.Get(TestJobNo) then begin
            Job.Init();
            Job."No." := TestJobNo;
            Job.Description := 'Day Planning Sequence No. Test Job';
            Job.Insert();
        end;
        if not JobTask.Get(TestJobNo, TestJobTaskNo) then begin
            JobTask.Init();
            JobTask."Job No." := TestJobNo;
            JobTask."Job Task No." := TestJobTaskNo;
            JobTask.Description := 'Day Planning Sequence No. Test Job Task';
            JobTask."Job Task Type" := JobTask."Job Task Type"::Posting;
            JobTask.Insert();
        end;

        // [GIVEN] A Skill Code to assign on Day Planning lines
        if not SkillCode.Get(TestSkillCode) then begin
            SkillCode.Init();
            SkillCode.Code := TestSkillCode;
            SkillCode.Description := 'Day Planning Sequence No. Test Skill';
            SkillCode.Insert();
        end;

        IsInitialized := true;
        Commit();
    end;

    local procedure ClearDayPlanningsFor(JobNo: Code[20]; JobTaskNo: Code[20])
    var
        DayPlanning: Record "Day Planning";
    begin
        // al_run_tests does not appear to roll back data between test methods the way the
        // BC Test Tool does, so each test must clear its own prior-method leftovers explicitly
        // rather than relying on automatic per-test transaction rollback (same convention as
        // test/DayPlanningCreation.Test.Codeunit.al's ClearDayPlanningsFor).
        DayPlanning.SetRange("Job No.", JobNo);
        DayPlanning.SetRange("Job Task No.", JobTaskNo);
        DayPlanning.DeleteAll();
    end;

    /// <summary>
    /// Inserts one Day Planning record via plain Init/field-assignment/Insert(true) - deliberately
    /// NOT going through codeunit 50695's GenerateSequence/RegenerateSequence - so the table's own
    /// OnInsert trigger (and therefore CalcSequence) is exercised exactly the way a BC page's
    /// direct CUD would exercise it. SequenceNoIn lets a test pre-seed a specific "Sequence No."
    /// (simulating two independently-created lines that happen to collide) - 0 means "let
    /// CalcSequence assign one from scratch", matching how a page never touches this field itself.
    /// </summary>
    local procedure InsertDayPlanningDirect(DayLineNo: Integer; Skill: Code[10]; PlanDate: Date; SequenceNoIn: Integer): Record "Day Planning"
    var
        DayPlanning: Record "Day Planning";
    begin
        DayPlanning.Init();
        DayPlanning."Job No." := TestJobNo;
        DayPlanning."Job Task No." := TestJobTaskNo;
        DayPlanning."Day Line No." := DayLineNo;
        DayPlanning.Skill := Skill;
        DayPlanning."Plan Date" := PlanDate;
        DayPlanning."Sequence No." := SequenceNoIn;
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
    /// The confirmed contract, asserted generically so every test below re-checks it on every
    /// record it touches, not just the one field the test is nominally about.
    /// </summary>
    local procedure AssertSequenceNoPopulatedWhenApplicable(DayPlanning: Record "Day Planning")
    begin
        if (DayPlanning.Skill <> '') and (DayPlanning."Plan Date" <> 0D) then
            AssertIsTrue(DayPlanning."Sequence No." <> 0,
                StrSubstNo('Sequence No. must not be 0 when Skill (%1) <> '''' and Plan Date (%2) <> 0D. Day Line No. %3.',
                    DayPlanning.Skill, DayPlanning."Plan Date", DayPlanning."Day Line No."));
    end;

    [Test]
    procedure GivenSkillAndPlanDateSet_WhenInsertDirect_ThenSequenceNoIsAssignedNonZero()
    var
        DayPlanning: Record "Day Planning";
    begin
        // [GIVEN] Clean state
        Initialize();
        ClearDayPlanningsFor(TestJobNo, TestJobTaskNo);

        // [WHEN] A Day Planning line is inserted directly (Skill + Plan Date set, Sequence No. left
        // at its default 0 - exactly what a page's New-row flow does, since no page exposes this field)
        DayPlanning := InsertDayPlanningDirect(10000, TestSkillCode, WorkDate(), 0);

        // [THEN] Sequence No. was auto-assigned, non-zero
        AssertSequenceNoPopulatedWhenApplicable(DayPlanning);
        AssertAreEqual(1, DayPlanning."Sequence No.", 'First line for a fresh [Job,Task,Skill,Date] group should get Sequence No. 1.');
    end;

    [Test]
    procedure GivenBlankSkill_WhenInsertDirect_ThenSequenceNoStaysZero()
    var
        DayPlanning: Record "Day Planning";
    begin
        // [GIVEN] Clean state
        Initialize();
        ClearDayPlanningsFor(TestJobNo, TestJobTaskNo);

        // [WHEN] A Day Planning line is inserted directly with Skill left blank (if a Daily
        // Optimizer Setup Default Skill is configured in the environment this runs in, OnInsert
        // auto-fills it - the assertion below checks the actual resulting Skill, not a hardcoded
        // blank, so it stays correct either way)
        DayPlanning := InsertDayPlanningDirect(10000, '', WorkDate(), 0);

        // [THEN] Sequence No. is untouched (still 0) when Skill ended up blank
        if DayPlanning.Skill = '' then
            AssertAreEqual(0, DayPlanning."Sequence No.", 'Sequence No. must stay 0 when Skill is blank.');
    end;

    [Test]
    procedure GivenSkillSetButPlanDateBlank_WhenInsertDirect_ThenSequenceNoStaysZero()
    var
        DayPlanning: Record "Day Planning";
    begin
        // [GIVEN] Clean state
        Initialize();
        ClearDayPlanningsFor(TestJobNo, TestJobTaskNo);

        // [WHEN] A Day Planning line is inserted directly with Skill set but Plan Date left at 0D
        // (e.g. a page's very first Insert on a brand-new row, before the user has typed a date)
        DayPlanning := InsertDayPlanningDirect(10000, TestSkillCode, 0D, 0);

        // [THEN] Sequence No. stays 0 - not required/asserted until Plan Date is also set
        AssertAreEqual(0, DayPlanning."Sequence No.", 'Sequence No. must stay 0 while Plan Date is still 0D, even with Skill set.');
    end;

    [Test]
    procedure GivenPlanDateSetAfterInsert_WhenModifyDirect_ThenSequenceNoBecomesNonZero()
    var
        DayPlanning: Record "Day Planning";
    begin
        // [GIVEN] A line inserted with Skill set but no Plan Date yet (Sequence No. stays 0, per
        // the previous test)
        Initialize();
        ClearDayPlanningsFor(TestJobNo, TestJobTaskNo);
        DayPlanning := InsertDayPlanningDirect(10000, TestSkillCode, 0D, 0);

        // [WHEN] The page later sets Plan Date and saves the row (Rec.Modify(), exactly like a
        // page committing a field edit - a page's "Plan Date" OnValidate only runs
        // EnsureJobTaskCoversDate/AssignedCheck, never CalcSequence directly; the save's Modify()
        // is what this actually relies on)
        DayPlanning."Plan Date" := WorkDate();
        DayPlanning.Modify(true);

        // [THEN] Sequence No. is now assigned, non-zero
        AssertSequenceNoPopulatedWhenApplicable(DayPlanning);
        AssertIsTrue(DayPlanning."Sequence No." <> 0, 'Sequence No. should be assigned once Plan Date is set and the record is saved.');
    end;

    [Test]
    procedure GivenExistingLineOnSameGroup_WhenInsertSecondLineWithCollidingSequenceNo_ThenSecondLineReassigned()
    var
        FirstLine: Record "Day Planning";
        SecondLine: Record "Day Planning";
        PlanDate: Date;
    begin
        // [GIVEN] One existing line already holding Sequence No. 1 for [Job,Task,Skill,Date]
        Initialize();
        ClearDayPlanningsFor(TestJobNo, TestJobTaskNo);
        PlanDate := WorkDate();
        FirstLine := InsertDayPlanningDirect(10000, TestSkillCode, PlanDate, 0);
        AssertAreEqual(1, FirstLine."Sequence No.", 'Sanity check: first line should get Sequence No. 1.');

        // [WHEN] A second, independently-created line for the SAME [Job,Task,Skill,Date] group is
        // inserted, ALSO explicitly pre-set to Sequence No. 1 (simulating two lines created without
        // knowledge of each other that happen to collide)
        SecondLine := InsertDayPlanningDirect(20000, TestSkillCode, PlanDate, 1);

        // [THEN] The second line is reassigned to a different, still non-zero, non-colliding number
        AssertSequenceNoPopulatedWhenApplicable(SecondLine);
        AssertAreEqual(2, SecondLine."Sequence No.", 'Colliding Sequence No. on insert should be reassigned to the next free number.');
        FirstLine.Get(TestJobNo, TestJobTaskNo, 10000);
        AssertAreEqual(1, FirstLine."Sequence No.", 'The pre-existing line must be left untouched by the second insert.');
    end;

    [Test]
    procedure GivenTwoLinesDifferentDates_WhenModifySecondLineDateToCollide_ThenSecondLineReassigned()
    var
        FirstLine: Record "Day Planning";
        SecondLine: Record "Day Planning";
        Date1: Date;
        Date2: Date;
    begin
        // [GIVEN] Two lines on two different dates - each independently gets Sequence No. 1, since
        // dates are independent for collision purposes
        Initialize();
        ClearDayPlanningsFor(TestJobNo, TestJobTaskNo);
        Date1 := WorkDate();
        Date2 := CalcDate('<+1D>', Date1);
        FirstLine := InsertDayPlanningDirect(10000, TestSkillCode, Date1, 0);
        SecondLine := InsertDayPlanningDirect(20000, TestSkillCode, Date2, 0);
        AssertAreEqual(1, FirstLine."Sequence No.", 'Sanity check: first line should get Sequence No. 1.');
        AssertAreEqual(1, SecondLine."Sequence No.", 'Sanity check: second line on a different date should also get Sequence No. 1.');

        // [WHEN] The second line's Plan Date is changed directly (e.g. a drag-move on a scheduler)
        // to land on the SAME date as the first line, and the row is saved (Modify())
        SecondLine."Plan Date" := Date1;
        SecondLine.Modify(true);

        // [THEN] The second line is reassigned off the now-colliding Sequence No. 1
        AssertSequenceNoPopulatedWhenApplicable(SecondLine);
        AssertAreEqual(2, SecondLine."Sequence No.", 'Moving a line onto a date already occupied by Sequence No. 1 should reassign it to the next free number.');
        FirstLine.Get(TestJobNo, TestJobTaskNo, 10000);
        AssertAreEqual(1, FirstLine."Sequence No.", 'The line that stayed on its original date must be left untouched by the other line''s move.');
    end;

    [Test]
    procedure GivenLineHoldingSequenceNo1Deleted_WhenNewLineInsertedForSameGroup_ThenNewLineReusesFreedNumber()
    var
        FirstLine: Record "Day Planning";
        SecondLine: Record "Day Planning";
        ThirdLine: Record "Day Planning";
        PlanDate: Date;
    begin
        // [GIVEN] Two lines on the same [Job,Task,Skill,Date] group - Sequence No. 1 and 2
        Initialize();
        ClearDayPlanningsFor(TestJobNo, TestJobTaskNo);
        PlanDate := WorkDate();
        FirstLine := InsertDayPlanningDirect(10000, TestSkillCode, PlanDate, 0);
        SecondLine := InsertDayPlanningDirect(20000, TestSkillCode, PlanDate, 0);
        AssertAreEqual(1, FirstLine."Sequence No.", 'Sanity check.');
        AssertAreEqual(2, SecondLine."Sequence No.", 'Sanity check.');

        // [WHEN] The line holding Sequence No. 1 is deleted directly (Rec.Delete(true), as a page's
        // delete action would), and a third line is then inserted for the same group
        FirstLine.Delete(true);
        ThirdLine := InsertDayPlanningDirect(30000, TestSkillCode, PlanDate, 0);

        // [THEN] The third line reuses the now-free Sequence No. 1 (lowest-available-slot, not a
        // monotonic counter), and the untouched second line still holds 2
        AssertSequenceNoPopulatedWhenApplicable(ThirdLine);
        AssertAreEqual(1, ThirdLine."Sequence No.", 'Deleting the line holding Sequence No. 1 should free that slot for reuse by the next insert.');
        SecondLine.Get(TestJobNo, TestJobTaskNo, 20000);
        AssertAreEqual(2, SecondLine."Sequence No.", 'The untouched second line must keep its original Sequence No.');
    end;

    [Test]
    procedure GivenLineWithBlankSkill_WhenModifySkillToNonBlankDirect_ThenSequenceNoAssignedOnSave()
    var
        DayPlanning: Record "Day Planning";
        PlanDate: Date;
    begin
        // [GIVEN] A line with a real Plan Date but blank Skill (Sequence No. stays 0)
        Initialize();
        ClearDayPlanningsFor(TestJobNo, TestJobTaskNo);
        PlanDate := WorkDate();
        DayPlanning := InsertDayPlanningDirect(10000, '', PlanDate, 0);
        if DayPlanning.Skill <> '' then
            exit; // a Default Skill is configured in this environment - not the scenario this test targets

        AssertAreEqual(0, DayPlanning."Sequence No.", 'Sanity check: blank-Skill line should have Sequence No. 0.');

        // [WHEN] The page later sets Skill directly on the same row and saves it (Modify())
        DayPlanning.Skill := TestSkillCode;
        DayPlanning.Modify(true);

        // [THEN] Sequence No. is assigned on save, non-zero
        AssertSequenceNoPopulatedWhenApplicable(DayPlanning);
        AssertIsTrue(DayPlanning."Sequence No." <> 0, 'Sequence No. should be assigned once Skill is set (non-blank) and the record is saved.');
    end;
}
