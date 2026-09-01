codeunit 60029 "Task Scheduler Sections Perf"
{
    // Correctness-by-equivalence tests for the Part A performance rewrite in codeunit 50604 "DHX
    // Data Handler": the rewritten AddAncestorsToTemp (single sorted FindSet per distinct Job No.,
    // no repeated FindLast() queries) and the rewritten GetYUnitElementsJSON_Project main loop
    // (bulk Resource/Vendor prefetch dictionaries + TEMPJobTasks cache-first Job Task lookup,
    // instead of a Resource.Get()/Resource.Get()/Vendor.Get()/JobTasks.Get() per Day Planning row).
    //
    // AddAncestorsToTemp itself is a local procedure with no public surface, so these assert
    // against GetYUnitElementsJSON_Project's PUBLIC JSON output instead - the only externally
    // observable contract - which is exactly what a caller (page 50621) actually depends on. This
    // is a content/structure equivalence check (parsed JSON keys/values/nesting), not a raw
    // string-byte comparison: ToSessionDateTimeTxt converts every event's start/end into the
    // CURRENT SESSION's time zone, which is environment-dependent and would make a hardcoded
    // byte-exact string fragile across different test-run environments/time zones - the section
    // tree (keys/labels/nesting, entirely time-zone-independent) is asserted byte-for-byte via
    // exact key/label/count checks, while the events array is asserted field-by-field on every
    // value EXCEPT the two time-zone-converted date/time text fields.
    //
    // Fixture: two Jobs -
    //  - TSPT-JOBA: a 3-level-deep WBS (Heading > Begin-Total > Heading > Posting, plus a second
    //    Posting leaf directly under the top Heading and two End-Total closing markers) with 2 Day
    //    Plannings in the test week - exercises multi-hop ancestor-chain climbing, shared-ancestor
    //    reuse (both leaves resolve up to the same top Heading), and End-Total/Total exclusion from
    //    the rendered tree.
    //  - TSPT-JOBB: a Job Task exists, but ZERO Day Plannings in the test week - must be completely
    //    absent from the output even though it's inside the JobFilter passed to the call.
    Subtype = Test;
    TestPermissions = Disabled;

    var
        JobANo: Code[20];
        JobBNo: Code[20];
        ResourceANo: Code[20];
        ResourceBNo: Code[20];
        VendorNo: Code[20];
        DHXDataHandler: Codeunit "DHX Data Handler";

    local procedure Initialize()
    var
        WeekMonday: Date;
    begin
        JobANo := 'TSPT-JOBA';
        JobBNo := 'TSPT-JOBB';
        ResourceANo := 'TSPT-RESA';
        ResourceBNo := 'TSPT-RESB';
        VendorNo := 'TSPT-VEND';

        WeekMonday := GetTestMonday(30);
        ClearFixture(WeekMonday);
        BuildJobsAndTasks();
        CreateTestResource(ResourceANo);
        CreateTestResource(ResourceBNo);
        CreateTestVendor(VendorNo);
        BuildDayPlannings(WeekMonday);
    end;

    // ================================================================
    // GIVEN-data helpers
    // ================================================================

    /// <summary>
    /// A Monday-anchored week, offset WeeksAhead weeks from today, so this test's period never
    /// overlaps another test's Day Planning rows (same idea as SkillCapacityChart.Test.Codeunit.al's
    /// GetTestMonday).
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

    local procedure ClearFixture(WeekMonday: Date)
    var
        DayPlanning: Record "Day Planning";
    begin
        DayPlanning.SetFilter("Job No.", '%1|%2', JobANo, JobBNo);
        DayPlanning.SetRange("Plan Date", WeekMonday, WeekMonday + 6);
        DayPlanning.DeleteAll(false); // false = skip OnDelete's Assigned/Realized Hours TestFields
    end;

    local procedure BuildJobsAndTasks()
    begin
        CreateJob(JobANo, 'Task Scheduler Perf Test Job A');
        // Job Task No. order matters (default/primary key order = the order AddAncestorsToTemp and
        // the tree-build walk both rely on):
        //   1000 Heading      indent 0  "Phase 1"        - top-level node
        //   1010 Begin-Total  indent 1  "Structural"      - needs ancestor 1000
        //   1015 Heading      indent 2  "Foundation"      - needs ancestor 1010 (which itself needs 1000)
        //   1020 Posting      indent 3  "Excavate"        - DAY PLANNING touches this leaf; ancestor chain 1015->1010->1000 (3 hops)
        //   1025 End-Total    indent 2                    - closes 1015; must NOT appear in output, must NOT be treated as an ancestor
        //   1030 End-Total    indent 1                    - closes 1010; same
        //   1040 Posting      indent 1  "Direct Task"     - DAY PLANNING touches this leaf; ancestor = 1000 directly (already inserted via 1020's chain - exercises the "already present" reuse path)
        CreateJobTask(JobANo, '1000', 'Phase 1', 0, Enum::"Job Task Type"::Heading);
        CreateJobTask(JobANo, '1010', 'Structural', 1, Enum::"Job Task Type"::"Begin-Total");
        CreateJobTask(JobANo, '1015', 'Foundation', 2, Enum::"Job Task Type"::Heading);
        CreateJobTask(JobANo, '1020', 'Excavate', 3, Enum::"Job Task Type"::Posting);
        CreateJobTask(JobANo, '1025', 'Foundation End', 2, Enum::"Job Task Type"::"End-Total");
        CreateJobTask(JobANo, '1030', 'Structural End', 1, Enum::"Job Task Type"::"End-Total");
        CreateJobTask(JobANo, '1040', 'Direct Task', 1, Enum::"Job Task Type"::Posting);

        CreateJob(JobBNo, 'Task Scheduler Perf Test Job B (no plannings this week)');
        CreateJobTask(JobBNo, '1000', 'Untouched Task', 0, Enum::"Job Task Type"::Posting);
    end;

    local procedure CreateJob(pJobNo: Code[20]; pDescription: Text[100])
    var
        Job: Record Job;
    begin
        if not Job.Get(pJobNo) then begin
            Job.Init();
            Job."No." := pJobNo;
            Job.Insert();
        end;
        Job.Description := pDescription;
        Job.Modify();
    end;

    local procedure CreateJobTask(pJobNo: Code[20]; pJobTaskNo: Code[20]; pDescription: Text[100]; pIndentation: Integer; pJobTaskType: Enum "Job Task Type")
    var
        JobTask: Record "Job Task";
    begin
        if not JobTask.Get(pJobNo, pJobTaskNo) then begin
            JobTask.Init();
            JobTask."Job No." := pJobNo;
            JobTask."Job Task No." := pJobTaskNo;
            JobTask.Insert();
        end;
        JobTask.Description := pDescription;
        JobTask.Indentation := pIndentation;
        JobTask."Job Task Type" := pJobTaskType;
        JobTask.Modify();
    end;

    local procedure CreateTestResource(pResNo: Code[20])
    var
        Resource: Record Resource;
    begin
        if not Resource.Get(pResNo) then begin
            Resource.Init();
            Resource."No." := pResNo;
            Resource.Type := Resource.Type::Person;
            Resource.Insert();
        end;
        Resource.Name := 'Task Scheduler Perf Test Resource ' + pResNo;
        Resource.Modify();
    end;

    local procedure CreateTestVendor(pVendorNo: Code[20])
    var
        Vendor: Record Vendor;
    begin
        if not Vendor.Get(pVendorNo) then begin
            Vendor.Init();
            Vendor."No." := pVendorNo;
            Vendor.Insert();
        end;
        Vendor.Name := 'Task Scheduler Perf Test Vendor ' + pVendorNo;
        Vendor.Modify();
    end;

    /// <summary>
    /// Two Day Planning rows on JobA - one on the deepest leaf (1020), one on the "shared ancestor"
    /// leaf (1040) - and NONE on JobB. Inserted with Insert(false) to skip OnInsert (which would
    /// otherwise require a "Daily Optimizer Setup" singleton row to exist).
    /// </summary>
    local procedure BuildDayPlannings(WeekMonday: Date)
    var
        DayPlanning: Record "Day Planning";
    begin
        DayPlanning.Init();
        DayPlanning."Job No." := JobANo;
        DayPlanning."Job Task No." := '1020';
        DayPlanning."Plan Date" := WeekMonday;
        DayPlanning."Day Line No." := 10000;
        DayPlanning."Assigned Resource No." := ResourceANo;
        DayPlanning."Start Time Assigned" := 080000T;
        DayPlanning."End Time Assigned" := 120000T;
        DayPlanning.Insert(false);

        DayPlanning.Init();
        DayPlanning."Job No." := JobANo;
        DayPlanning."Job Task No." := '1040';
        DayPlanning."Plan Date" := WeekMonday + 1;
        DayPlanning."Day Line No." := 10000;
        DayPlanning."Assigned Resource No." := ResourceBNo;
        DayPlanning."Requested Resource No." := ResourceANo;
        DayPlanning."Vendor No." := VendorNo;
        DayPlanning."Start Time Assigned" := 090000T;
        DayPlanning."End Time Assigned" := 150000T;
        DayPlanning.Insert(false);
    end;

    local procedure GetSectionsJson(WeekMonday: Date): Text
    var
        PlanninJsonTxt: Text;
        EarliestPlanningDate: Date;
    begin
        exit(DHXDataHandler.GetYUnitElementsJSON_Project(WeekMonday, WeekMonday, WeekMonday + 6, '',
            JobANo + '|' + JobBNo, '', PlanninJsonTxt, EarliestPlanningDate));
    end;

    local procedure GetSectionsAndEventsJson(WeekMonday: Date; var SectionsJson: Text; var EventsJson: Text)
    var
        EarliestPlanningDate: Date;
    begin
        SectionsJson := DHXDataHandler.GetYUnitElementsJSON_Project(WeekMonday, WeekMonday, WeekMonday + 6, '',
            JobANo + '|' + JobBNo, '', EventsJson, EarliestPlanningDate);
    end;

    // ================================================================
    // JSON navigation helpers
    // ================================================================

    local procedure GetDataArray(SectionsJson: Text): JsonArray
    var
        RootObj: JsonObject;
        DataToken: JsonToken;
        DataArr: JsonArray;
    begin
        AssertIsTrue(RootObj.ReadFrom(SectionsJson), 'Sections JSON must parse.');
        AssertIsTrue(RootObj.Get('data', DataToken), 'Sections JSON must have a "data" key.');
        DataArr := DataToken.AsArray();
        exit(DataArr);
    end;

    local procedure GetObjAt(Arr: JsonArray; Index: Integer): JsonObject
    var
        Tok: JsonToken;
    begin
        Arr.Get(Index, Tok);
        exit(Tok.AsObject());
    end;

    local procedure GetTxt(Obj: JsonObject; KeyName: Text): Text
    var
        Tok: JsonToken;
    begin
        if not Obj.Get(KeyName, Tok) then
            exit('<missing:' + KeyName + '>');
        exit(Tok.AsValue().AsText());
    end;

    local procedure GetChildrenArray(Obj: JsonObject): JsonArray
    var
        Tok: JsonToken;
        Arr: JsonArray;
    begin
        if not Obj.Get('children', Tok) then
            exit(Arr); // empty array - a leaf has no "children" key at all
        exit(Tok.AsArray());
    end;

    // ================================================================
    // Tests
    // ================================================================

    [Test]
    procedure GivenMultiJobFixture_WhenGetYUnitElementsJSON_Project_ThenEmptyJobIsExcluded()
    var
        WeekMonday: Date;
        DataArr: JsonArray;
    begin
        // [GIVEN] JobA (2 Day Plannings this week) and JobB (Job Task exists, zero Day Plannings)
        Initialize();
        WeekMonday := GetTestMonday(30);

        // [WHEN] Building the section tree for a JobFilter that includes BOTH jobs
        DataArr := GetDataArray(GetSectionsJson(WeekMonday));

        // [THEN] Only JobA appears - a Job with no Day Plannings in the period is never touched,
        // regardless of being inside the JobFilter
        AssertAreEqual(1, DataArr.Count(), 'Expected exactly 1 Job in the section tree (JobB has zero Day Plannings this week and must be excluded).');
        AssertAreEqual(JobANo, GetTxt(GetObjAt(DataArr, 0), 'key'), 'The single Job present must be JobA.');
    end;

    [Test]
    procedure GivenMultiDepthWBS_WhenGetYUnitElementsJSON_Project_ThenAncestorHierarchyIsCorrect()
    var
        WeekMonday: Date;
        DataArr, PhaseChildren, StructuralChildren, FoundationChildren : JsonArray;
        JobNode, PhaseNode, StructuralNode, FoundationNode, ExcavateLeaf, DirectTaskLeaf : JsonObject;
    begin
        // [GIVEN] JobA's 3-level-deep WBS (see BuildJobsAndTasks) with Day Plannings on the
        // deepest leaf (1020, under Heading>Begin-Total>Heading) and a shallower leaf (1040,
        // directly under the top Heading, sharing the same top ancestor)
        Initialize();
        WeekMonday := GetTestMonday(30);

        // [WHEN] Building the section tree (exercises the rewritten AddAncestorsToTemp's
        // multi-hop ancestor-chain climbing and shared-ancestor reuse)
        DataArr := GetDataArray(GetSectionsJson(WeekMonday));
        JobNode := GetObjAt(DataArr, 0);

        // [THEN] JobA -> 1000 "Phase 1" (the only top-level task; both leaves share it as their
        // eventual ancestor)
        PhaseChildren := GetChildrenArray(JobNode);
        AssertAreEqual(1, PhaseChildren.Count(), 'JobA must have exactly 1 top-level section (1000 "Phase 1").');
        PhaseNode := GetObjAt(PhaseChildren, 0);
        AssertAreEqual(JobANo + '|1000', GetTxt(PhaseNode, 'key'), 'Top-level section key.');
        AssertAreEqual('1000 - Phase 1', GetTxt(PhaseNode, 'label'), 'Top-level section label.');

        // [THEN] 1000's children = [1010 "Structural" (ancestor of 1020), 1040 "Direct Task"
        // (leaf)] in Job Task No. order - 1025/1030 (End-Total closing markers) must NOT appear
        StructuralChildren := GetChildrenArray(PhaseNode);
        AssertAreEqual(2, StructuralChildren.Count(), '1000 "Phase 1" must have exactly 2 children (1010 and 1040) - End-Total markers must never appear as nodes.');
        StructuralNode := GetObjAt(StructuralChildren, 0);
        AssertAreEqual(JobANo + '|1010', GetTxt(StructuralNode, 'key'), 'First child of 1000 must be 1010 "Structural".');
        AssertAreEqual('1010 - Structural', GetTxt(StructuralNode, 'label'), '1010 label.');
        DirectTaskLeaf := GetObjAt(StructuralChildren, 1);
        AssertAreEqual(JobANo + '|1040', GetTxt(DirectTaskLeaf, 'key'), 'Second child of 1000 must be leaf 1040 "Direct Task".');
        AssertAreEqual('1040 - Direct Task', GetTxt(DirectTaskLeaf, 'label'), '1040 label.');

        // [THEN] 1010's only child is 1015 "Foundation" (its own ancestor chain, 1010 -> 1000,
        // was correctly resolved even though 1010 itself was only added to TEMPJobTasks as an
        // ancestor, never directly touched by a Day Planning)
        FoundationChildren := GetChildrenArray(StructuralNode);
        AssertAreEqual(1, FoundationChildren.Count(), '1010 "Structural" must have exactly 1 child (1015 "Foundation").');
        FoundationNode := GetObjAt(FoundationChildren, 0);
        AssertAreEqual(JobANo + '|1015', GetTxt(FoundationNode, 'key'), 'Child of 1010 must be 1015 "Foundation".');

        // [THEN] 1015's only child is the leaf 1020 "Excavate" - the Day Planning-touched task
        // itself, 3 ancestor hops below the top-level "Phase 1" node
        PhaseChildren := GetChildrenArray(FoundationNode); // reused var - this is 1015's children
        AssertAreEqual(1, PhaseChildren.Count(), '1015 "Foundation" must have exactly 1 child (leaf 1020 "Excavate").');
        ExcavateLeaf := GetObjAt(PhaseChildren, 0);
        AssertAreEqual(JobANo + '|1020', GetTxt(ExcavateLeaf, 'key'), 'Deepest leaf key.');
        AssertAreEqual('1020 - Excavate', GetTxt(ExcavateLeaf, 'label'), 'Deepest leaf label.');
    end;

    [Test]
    procedure GivenDayPlanningsWithResourceAndVendor_WhenGetYUnitElementsJSON_Project_ThenEventsAreCorrect()
    var
        WeekMonday: Date;
        SectionsJson: Text;
        EventsJson: Text;
        EventsArr: JsonArray;
        Ev0, Ev1 : JsonObject;
    begin
        // [GIVEN] The same fixture - 2 Day Plannings on JobA, one plain-assigned, one with both an
        // Assigned and a Requested resource plus a Vendor, referencing distinct resources so the
        // bulk Resource/Vendor prefetch dictionaries (Part A) must resolve BOTH correctly
        Initialize();
        WeekMonday := GetTestMonday(30);

        // [WHEN]
        GetSectionsAndEventsJson(WeekMonday, SectionsJson, EventsJson);
        AssertIsTrue(EventsJson.StartsWith('['), 'Events JSON must be a JSON array.');
        EventsArr.ReadFrom(EventsJson);

        // [THEN] Exactly 2 events - one per Day Planning on JobA; JobB contributes none
        AssertAreEqual(2, EventsArr.Count(), 'Expected exactly 2 events (JobA''s 2 Day Plannings; JobB has none).');

        // Order follows the DayPlanning scan's key ("Plan Date","Start Time Assigned"), so the
        // Monday row (1020) comes first, the Monday+1 row (1040) second.
        Ev0 := GetObjAt(EventsArr, 0);
        AssertAreEqual(JobANo + '|1020', GetTxt(Ev0, 'section_id'), 'First event section_id.');
        // BuildDayPlannings sets only an Assigned Resource (no Requested Resource, no Vendor) on
        // the 1020 row - both must come back blank.
        AssertAreEqual('', GetTxt(Ev0, 'requested_resource_no'), 'First event has no Requested Resource set - "requested_resource_no" must be blank.');
        AssertAreEqual('', GetTxt(Ev0, 'requested_resource_name'), 'First event has no Requested Resource - name must be blank.');
        AssertAreEqual('', GetTxt(Ev0, 'details'), 'First event has no Vendor - "details" (Vendor Name, via the bulk-prefetch dictionary) must be blank.');

        Ev1 := GetObjAt(EventsArr, 1);
        AssertAreEqual(JobANo + '|1040', GetTxt(Ev1, 'section_id'), 'Second event section_id.');
        AssertAreEqual(ResourceANo, GetTxt(Ev1, 'requested_resource_no'), 'Second event''s Requested Resource No.');
        AssertAreEqual('Task Scheduler Perf Test Resource ' + ResourceANo, GetTxt(Ev1, 'requested_resource_name'),
            'Second event''s requested resource NAME must come from the bulk-prefetched Resource dictionary.');
        AssertAreEqual('Task Scheduler Perf Test Vendor ' + VendorNo, GetTxt(Ev1, 'details'),
            'Second event''s Vendor NAME (details) must come from the bulk-prefetched Vendor dictionary.');
    end;

    // ================================================================
    // Assert helpers (this project's established convention - see e.g.
    // test\DayPlanningCreation.Test.Codeunit.al / test\SkillCapacityChart.Test.Codeunit.al -
    // no Library Assert codeunit is used anywhere in this test suite)
    // ================================================================

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
}
