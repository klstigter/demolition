codeunit 60026 "Resource Capacity Sched Tests"
{
    // Tests for codeunit 50604 "DHX Data Handler" - the "SkillResScheduler_*" procedures
    // backing page 50706 "DHX Scheduler (Res+Capacity)" ("Resource Scheduler (New)"):
    // SkillResScheduler_BuildTreeJson (Skill > Resource left-panel tree) and
    // SkillResScheduler_BuildCapacityJson / SkillResScheduler_BuildDayPlanningJson (the
    // combined Capacity + Day Planning right-panel events). Asserts directly against the
    // returned JSON rather than going through page 50706's UI.
    Subtype = Test;
    TestPermissions = Disabled;

    var
        DHXDataHandler: Codeunit "DHX Data Handler";

    // ================================================================
    // GIVEN-data helpers
    // ================================================================

    /// <summary>A Monday-anchored week, offset WeeksAhead weeks from today so each test uses its own non-overlapping period.</summary>
    local procedure GetTestMonday(WeeksAhead: Integer): Date
    var
        CandidateDate: Date;
        DayOfWeek: Integer;
    begin
        CandidateDate := CalcDate(StrSubstNo('<+%1W>', WeeksAhead), Today());
        DayOfWeek := Date2DWY(CandidateDate, 1); // 1 = Monday .. 7 = Sunday
        exit(CandidateDate - (DayOfWeek - 1));
    end;

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

    local procedure CreateTestResource(ResNo: Code[20]; ResName: Text[100])
    var
        Resource: Record Resource;
    begin
        if not Resource.Get(ResNo) then begin
            Resource.Init();
            Resource."No." := ResNo;
            Resource.Type := Resource.Type::Person;
            Resource.Insert();
        end;
        Resource.Name := ResName;
        Resource.Modify();
    end;

    local procedure CreateTestSkillCode(SkillCodeValue: Code[10])
    var
        SkillCode: Record "Skill Code";
    begin
        if not SkillCode.Get(SkillCodeValue) then begin
            SkillCode.Init();
            SkillCode.Code := SkillCodeValue;
            SkillCode.Description := 'Resource Capacity Sched Test Skill ' + SkillCodeValue;
            SkillCode.Insert();
        end;
    end;

    local procedure AssignResourceSkill(ResNo: Code[20]; SkillCodeValue: Code[10])
    var
        ResourceSkill: Record "Resource Skill";
    begin
        if ResourceSkill.Get(ResourceSkill.Type::Resource, ResNo, SkillCodeValue) then
            exit;
        ResourceSkill.Init();
        ResourceSkill.Type := ResourceSkill.Type::Resource;
        ResourceSkill."No." := ResNo;
        ResourceSkill."Skill Code" := SkillCodeValue;
        ResourceSkill.Insert();
    end;

    /// <summary>Marks ResNo as a placeholder resource (a Skill Code's "Invoice Resource No.") - must be excluded from the tree.</summary>
    local procedure MakePlaceholderResource(SkillCodeValue: Code[10]; ResNo: Code[20])
    var
        SkillCode: Record "Skill Code";
    begin
        SkillCode.Get(SkillCodeValue);
        SkillCode."Invoice Resource No." := ResNo;
        SkillCode.Modify();
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

    /// <summary>Inserts one Day Planning line with independent Requested/Assigned resource + time ranges.</summary>
    local procedure InsertDayPlanningLine(PlanDate: Date; AssignedResourceNo: Code[20]; StartAssigned: Time; EndAssigned: Time; RequestedResourceNo: Code[20]; StartRequested: Time; EndRequested: Time; SkillCodeValue: Code[20])
    var
        DayPlanning: Record "Day Planning";
    begin
        DayPlanning.Init();
        DayPlanning."Job No." := 'RCSTJOB';
        DayPlanning."Job Task No." := '1000';
        DayPlanning."Plan Date" := PlanDate;
        DayPlanning.GetNextDayLineNo();
        DayPlanning.Skill := SkillCodeValue;
        DayPlanning."Assigned Resource No." := AssignedResourceNo;
        DayPlanning."Start Time Assigned" := StartAssigned;
        DayPlanning."End Time Assigned" := EndAssigned;
        DayPlanning."Requested Resource No." := RequestedResourceNo;
        DayPlanning."Start Time Requested" := StartRequested;
        DayPlanning."End Time Requested" := EndRequested;
        DayPlanning.Insert();
    end;

    // ================================================================
    // JSON assertion helpers
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

    /// <summary>Finds the top-level tree node whose "key" = 'SKILL|' + SkillCodeValue. Returns false if not present.</summary>
    local procedure TryFindSkillNode(TreeJson: Text; SkillCodeValue: Text; var SkillNode: JsonObject): Boolean
    var
        Root: JsonObject;
        DataToken: JsonToken;
        DataArray: JsonArray;
        NodeToken: JsonToken;
        KeyToken: JsonToken;
        i: Integer;
        WantedKey: Text;
    begin
        AssertIsTrue(Root.ReadFrom(TreeJson), 'Tree JSON must parse.');
        AssertIsTrue(Root.Get('data', DataToken), 'Tree JSON must have a "data" key.');
        DataArray := DataToken.AsArray();
        WantedKey := 'SKILL|' + SkillCodeValue;
        for i := 0 to DataArray.Count() - 1 do begin
            DataArray.Get(i, NodeToken);
            SkillNode := NodeToken.AsObject();
            if SkillNode.Get('key', KeyToken) then
                if KeyToken.AsValue().AsText() = WantedKey then
                    exit(true);
        end;
        exit(false);
    end;

    /// <summary>True if the Skill node's "children" array contains a Resource leaf with the given key (Resource No.).</summary>
    local procedure SkillNodeHasResourceChild(SkillNode: JsonObject; ResNo: Text): Boolean
    var
        ChildrenToken: JsonToken;
        ChildrenArray: JsonArray;
        ChildToken: JsonToken;
        ChildObj: JsonObject;
        KeyToken: JsonToken;
        i: Integer;
    begin
        if not SkillNode.Get('children', ChildrenToken) then
            exit(false);
        ChildrenArray := ChildrenToken.AsArray();
        for i := 0 to ChildrenArray.Count() - 1 do begin
            ChildrenArray.Get(i, ChildToken);
            ChildObj := ChildToken.AsObject();
            if ChildObj.Get('key', KeyToken) then
                if KeyToken.AsValue().AsText() = ResNo then
                    exit(true);
        end;
        exit(false);
    end;

    /// <summary>True if any top-level node in the tree JSON has this exact "key".</summary>
    local procedure TreeHasNodeWithKey(TreeJson: Text; NodeKey: Text): Boolean
    var
        Root: JsonObject;
        DataToken: JsonToken;
        DataArray: JsonArray;
        NodeToken: JsonToken;
        NodeObj: JsonObject;
        KeyToken: JsonToken;
        i: Integer;
    begin
        AssertIsTrue(Root.ReadFrom(TreeJson), 'Tree JSON must parse.');
        AssertIsTrue(Root.Get('data', DataToken), 'Tree JSON must have a "data" key.');
        DataArray := DataToken.AsArray();
        for i := 0 to DataArray.Count() - 1 do begin
            DataArray.Get(i, NodeToken);
            NodeObj := NodeToken.AsObject();
            if NodeObj.Get('key', KeyToken) then
                if KeyToken.AsValue().AsText() = NodeKey then
                    exit(true);
        end;
        exit(false);
    end;

    /// <summary>Returns the events (JsonArray of JsonObject) in a Capacity/DayPlanning events JSON's "data" array.</summary>
    local procedure GetEventsArray(EventsJson: Text; var EventsArray: JsonArray)
    var
        Root: JsonObject;
        DataToken: JsonToken;
    begin
        AssertIsTrue(Root.ReadFrom(EventsJson), 'Events JSON must parse.');
        AssertIsTrue(Root.Get('data', DataToken), 'Events JSON must have a "data" key.');
        EventsArray := DataToken.AsArray();
    end;

    local procedure TryFindEventBySectionId(EventsJson: Text; SectionId: Text; var EventObj: JsonObject): Boolean
    var
        EventsArray: JsonArray;
        EventToken: JsonToken;
        SecToken: JsonToken;
        i: Integer;
    begin
        GetEventsArray(EventsJson, EventsArray);
        for i := 0 to EventsArray.Count() - 1 do begin
            EventsArray.Get(i, EventToken);
            EventObj := EventToken.AsObject();
            if EventObj.Get('section_id', SecToken) then
                if SecToken.AsValue().AsText() = SectionId then
                    exit(true);
        end;
        exit(false);
    end;

    local procedure GetJsonText(Obj: JsonObject; FieldName: Text): Text
    var
        Tok: JsonToken;
    begin
        if not Obj.Get(FieldName, Tok) then
            exit('');
        if Tok.AsValue().IsNull() then
            exit('');
        exit(Tok.AsValue().AsText());
    end;

    local procedure GetJsonDecimal(Obj: JsonObject; FieldName: Text): Decimal
    var
        Tok: JsonToken;
    begin
        if not Obj.Get(FieldName, Tok) then
            exit(0);
        exit(Tok.AsValue().AsDecimal());
    end;

    // ================================================================
    // Tests - SkillResScheduler_BuildTreeJson
    // ================================================================

    [Test]
    procedure GivenResourceWithSkill_WhenBuildTreeJson_ThenResourceAppearsUnderThatSkillNode()
    var
        TreeJson: Text;
        SkillNode: JsonObject;
    begin
        // [GIVEN] A skill and one real resource assigned to it.
        CreateTestSkillCode('RCSTSKA');
        CreateTestResource('RCSTRA1', 'RCST Test Resource A1');
        AssignResourceSkill('RCSTRA1', 'RCSTSKA');

        // [WHEN] SkillResScheduler_BuildTreeJson is called.
        TreeJson := DHXDataHandler.SkillResScheduler_BuildTreeJson('RCSTRA1', '');

        // [THEN] A "SKILL|RCSTSKA" node exists with RCSTRA1 as a child leaf.
        AssertIsTrue(TryFindSkillNode(TreeJson, 'RCSTSKA', SkillNode), 'Skill node RCSTSKA must exist.');
        AssertIsTrue(SkillNodeHasResourceChild(SkillNode, 'RCSTRA1'), 'Resource RCSTRA1 must be a child of Skill RCSTSKA.');
    end;

    [Test]
    procedure GivenPlaceholderInvoiceResource_WhenBuildTreeJson_ThenPlaceholderIsExcluded()
    var
        TreeJson: Text;
        SkillNode: JsonObject;
    begin
        // [GIVEN] A skill whose "Invoice Resource No." points at a resource, plus one real
        // resource on the same skill.
        CreateTestSkillCode('RCSTSKB');
        CreateTestResource('RCSTRPH', 'RCST Placeholder Resource');
        CreateTestResource('RCSTRA2', 'RCST Test Resource A2');
        AssignResourceSkill('RCSTRA2', 'RCSTSKB');
        MakePlaceholderResource('RCSTSKB', 'RCSTRPH');

        // [WHEN] SkillResScheduler_BuildTreeJson is called (no Resource filter - would include
        // both resources if the placeholder exclusion did not apply).
        TreeJson := DHXDataHandler.SkillResScheduler_BuildTreeJson('RCSTRPH|RCSTRA2', '');

        // [THEN] The placeholder resource never appears as a leaf; the real resource does.
        AssertIsTrue(TryFindSkillNode(TreeJson, 'RCSTSKB', SkillNode), 'Skill node RCSTSKB must exist.');
        AssertIsTrue(not SkillNodeHasResourceChild(SkillNode, 'RCSTRPH'), 'Placeholder Invoice Resource must be excluded from the tree.');
        AssertIsTrue(SkillNodeHasResourceChild(SkillNode, 'RCSTRA2'), 'Real resource must still be included.');
    end;

    [Test]
    procedure GivenBlankNameResource_WhenBuildTreeJson_ThenResourceIsExcluded()
    var
        Resource: Record Resource;
        TreeJson: Text;
        SkillNode: JsonObject;
    begin
        // [GIVEN] A skill with a resource that has a blank Name (a second placeholder shape).
        CreateTestSkillCode('RCSTSKC');
        CreateTestResource('RCSTRBN', 'temp');
        Resource.Get('RCSTRBN');
        Resource.Name := '';
        Resource.Modify();
        AssignResourceSkill('RCSTRBN', 'RCSTSKC');

        // [WHEN] SkillResScheduler_BuildTreeJson is called.
        TreeJson := DHXDataHandler.SkillResScheduler_BuildTreeJson('RCSTRBN', '');

        // [THEN] The skill gets no node at all (its only resource is excluded, so it has zero children).
        AssertIsTrue(not TreeHasNodeWithKey(TreeJson, 'SKILL|RCSTSKC'), 'A skill whose only resource is blank-name must have no tree node.');
    end;

    [Test]
    procedure GivenResourceWithNoSkill_WhenBuildTreeJson_ThenResourceIsBucketedUnderNoSkillNode()
    var
        TreeJson: Text;
        SkillNode: JsonObject;
    begin
        // [GIVEN] A real resource with no Resource Skill row at all.
        CreateTestResource('RCSTRNS', 'RCST No Skill Resource');

        // [WHEN] SkillResScheduler_BuildTreeJson is called.
        TreeJson := DHXDataHandler.SkillResScheduler_BuildTreeJson('RCSTRNS', '');

        // [THEN] It is bucketed under the "SKILL|~NOSKILL~" node.
        AssertIsTrue(TryFindSkillNode(TreeJson, '~NOSKILL~', SkillNode), 'No-Skill node must exist.');
        AssertIsTrue(SkillNodeHasResourceChild(SkillNode, 'RCSTRNS'), 'Resource with no skill must be a child of the No-Skill node.');
    end;

    // ================================================================
    // Tests - SkillResScheduler_BuildCapacityJson
    // ================================================================

    [Test]
    procedure GivenMultipleCapacityEntriesSameDay_WhenBuildCapacityJson_ThenAggregatedIntoOneBarWithSummedHours()
    var
        PeriodStart: Date;
        CapacityJson: Text;
        EventObj: JsonObject;
    begin
        // [GIVEN] Two Res. Capacity Entry rows for the same resource/day.
        PeriodStart := GetTestMonday(30);
        ClearPeriodData(PeriodStart);
        CreateTestResource('RCSTRC1', 'RCST Capacity Resource 1');
        InsertResCapacityEntry('RCSTRC1', PeriodStart, 5);
        InsertResCapacityEntry('RCSTRC1', PeriodStart, 3);

        // [WHEN] SkillResScheduler_BuildCapacityJson is called for the period.
        CapacityJson := DHXDataHandler.SkillResScheduler_BuildCapacityJson('RCSTRC1', '', PeriodStart, PeriodStart + 6);

        // [THEN] A single aggregated bar with the fixed "event-capacity" classname/type and
        // summed hours (5 + 3 = 8).
        AssertIsTrue(TryFindEventBySectionId(CapacityJson, 'RCSTRC1', EventObj), 'Capacity event for RCSTRC1 must exist.');
        AssertAreEqual('event-capacity', GetJsonText(EventObj, 'classname'), 'Capacity classname must be the fixed distinct-color class.');
        AssertAreEqual('capacity', GetJsonText(EventObj, 'type'), 'Capacity type.');
        AssertAreEqual(8, GetJsonDecimal(EventObj, 'hours'), 'Aggregated capacity hours (5 + 3).');
    end;

    [Test]
    procedure GivenNoCapacityInPeriod_WhenBuildCapacityJson_ThenNoEventsReturned()
    var
        PeriodStart: Date;
        CapacityJson: Text;
        EventsArray: JsonArray;
    begin
        // [GIVEN] A resource with no Res. Capacity Entry rows in the period.
        PeriodStart := GetTestMonday(31);
        ClearPeriodData(PeriodStart);
        CreateTestResource('RCSTRC2', 'RCST Capacity Resource 2');

        // [WHEN] SkillResScheduler_BuildCapacityJson is called.
        CapacityJson := DHXDataHandler.SkillResScheduler_BuildCapacityJson('RCSTRC2', '', PeriodStart, PeriodStart + 6);

        // [THEN] The events array is empty.
        GetEventsArray(CapacityJson, EventsArray);
        AssertAreEqual(0, EventsArray.Count(), 'No capacity events expected.');
    end;

    // ================================================================
    // Tests - SkillResScheduler_BuildDayPlanningJson
    // ================================================================

    [Test]
    procedure GivenAssignedAndRequestedDifferentRanges_WhenBuildDayPlanningJson_ThenBothTimeRangesCarriedForProgressSplit()
    var
        PeriodStart: Date;
        EventsJson: Text;
        EventObj: JsonObject;
    begin
        // [GIVEN] A Day Planning line assigned to one resource 08:00-16:00 and requested for
        // that same resource 09:00-12:00 (a real subset, exercising the progress-split shape).
        PeriodStart := GetTestMonday(32);
        ClearPeriodData(PeriodStart);
        CreateTestSkillCode('RCSTSKD');
        CreateTestResource('RCSTRD1', 'RCST DayPlanning Resource D1');
        InsertDayPlanningLine(PeriodStart, 'RCSTRD1', 080000T, 160000T, 'RCSTRD1', 090000T, 120000T, 'RCSTSKD');

        // [WHEN] SkillResScheduler_BuildDayPlanningJson is called.
        EventsJson := DHXDataHandler.SkillResScheduler_BuildDayPlanningJson('RCSTRD1', '', PeriodStart, PeriodStart + 6);

        // [THEN] The event is placed on the resource's row, tagged "event-DayPlanning"/"DayPlanning",
        // and carries the raw Assigned/Requested "HH:mm" times the JS event_bar_text segment math needs.
        AssertIsTrue(TryFindEventBySectionId(EventsJson, 'RCSTRD1', EventObj), 'Day Planning event for RCSTRD1 must exist.');
        AssertAreEqual('event-DayPlanning', GetJsonText(EventObj, 'classname'), 'DayPlanning classname.');
        AssertAreEqual('DayPlanning', GetJsonText(EventObj, 'type'), 'DayPlanning type.');
        AssertAreEqual('08:00', GetJsonText(EventObj, 'start_time_assigned'), 'Assigned start time.');
        AssertAreEqual('16:00', GetJsonText(EventObj, 'end_time_assigned'), 'Assigned end time.');
        AssertAreEqual('09:00', GetJsonText(EventObj, 'start_time_requested'), 'Requested start time.');
        AssertAreEqual('12:00', GetJsonText(EventObj, 'end_time_requested'), 'Requested end time.');
    end;

    [Test]
    procedure GivenUnassignedButRequestedLine_WhenBuildDayPlanningJson_ThenEventPlacedOnRequestedResourceRow()
    var
        PeriodStart: Date;
        EventsJson: Text;
        EventObj: JsonObject;
    begin
        // [GIVEN] A Day Planning line with no Assigned Resource, only a Requested Resource -
        // still needs to be visible somewhere on the tree (on the requested resource's row).
        PeriodStart := GetTestMonday(33);
        ClearPeriodData(PeriodStart);
        CreateTestSkillCode('RCSTSKE');
        CreateTestResource('RCSTRE1', 'RCST Requested-Only Resource E1');
        InsertDayPlanningLine(PeriodStart, '', 0T, 0T, 'RCSTRE1', 100000T, 140000T, 'RCSTSKE');

        // [WHEN] SkillResScheduler_BuildDayPlanningJson is called.
        EventsJson := DHXDataHandler.SkillResScheduler_BuildDayPlanningJson('RCSTRE1', '', PeriodStart, PeriodStart + 6);

        // [THEN] The event's section_id/resource_id is the Requested Resource, with a blank
        // Assigned time pair and a populated Requested time pair.
        AssertIsTrue(TryFindEventBySectionId(EventsJson, 'RCSTRE1', EventObj), 'Day Planning event must fall back to the Requested Resource row.');
        AssertAreEqual('', GetJsonText(EventObj, 'start_time_assigned'), 'No Assigned start time expected.');
        AssertAreEqual('10:00', GetJsonText(EventObj, 'start_time_requested'), 'Requested start time.');
        AssertAreEqual('14:00', GetJsonText(EventObj, 'end_time_requested'), 'Requested end time.');
    end;

    [Test]
    procedure GivenPlanDateOutsidePeriod_WhenBuildDayPlanningJson_ThenLineIsExcluded()
    var
        PeriodStart: Date;
        OutsideDate: Date;
        EventsJson: Text;
        EventsArray: JsonArray;
    begin
        // [GIVEN] A Day Planning line dated a week after the queried period.
        PeriodStart := GetTestMonday(34);
        ClearPeriodData(PeriodStart);
        OutsideDate := PeriodStart + 14;
        CreateTestSkillCode('RCSTSKF');
        CreateTestResource('RCSTRF1', 'RCST Outside-Period Resource F1');
        InsertDayPlanningLine(OutsideDate, 'RCSTRF1', 080000T, 120000T, 'RCSTRF1', 080000T, 120000T, 'RCSTSKF');

        // [WHEN] SkillResScheduler_BuildDayPlanningJson is called for PeriodStart's week only.
        EventsJson := DHXDataHandler.SkillResScheduler_BuildDayPlanningJson('RCSTRF1', '', PeriodStart, PeriodStart + 6);

        // [THEN] No events are returned - the line falls outside the queried date range.
        GetEventsArray(EventsJson, EventsArray);
        AssertAreEqual(0, EventsArray.Count(), 'Line outside the queried period must be excluded.');
    end;

    // ================================================================
    // Tests - SkillFilter (regression: SkillFilter was captured by the page but never actually
    // passed into any of the three Build*Json procedures, so selecting a skill in the filter
    // dialog had zero effect on which bars/tree nodes were returned - confirmed live: filtering
    // by DESIGN still showed an ELEKTR Day Planning bar).
    // ================================================================

    [Test]
    procedure GivenSkillFilterSet_WhenBuildDayPlanningJson_ThenOtherSkillsEventsAreExcluded()
    var
        PeriodStart: Date;
        EventsJson: Text;
        EventsArray: JsonArray;
        EventObj: JsonObject;
    begin
        // [GIVEN] Two Day Planning lines on the same day, different resources, different skills.
        PeriodStart := GetTestMonday(35);
        ClearPeriodData(PeriodStart);
        CreateTestSkillCode('RCSTSKG');
        CreateTestSkillCode('RCSTSKH');
        CreateTestResource('RCSTRG1', 'RCST SkillFilter Resource G1');
        CreateTestResource('RCSTRH1', 'RCST SkillFilter Resource H1');
        InsertDayPlanningLine(PeriodStart, 'RCSTRG1', 080000T, 120000T, 'RCSTRG1', 080000T, 120000T, 'RCSTSKG');
        InsertDayPlanningLine(PeriodStart, 'RCSTRH1', 080000T, 120000T, 'RCSTRH1', 080000T, 120000T, 'RCSTSKH');

        // [WHEN] SkillResScheduler_BuildDayPlanningJson is called with SkillFilter = 'RCSTSKG'.
        EventsJson := DHXDataHandler.SkillResScheduler_BuildDayPlanningJson('', 'RCSTSKG', PeriodStart, PeriodStart + 6);

        // [THEN] Only the RCSTSKG event is returned - the RCSTSKH event must not leak through.
        GetEventsArray(EventsJson, EventsArray);
        AssertAreEqual(1, EventsArray.Count(), 'Only the matching-skill event must be returned.');
        AssertIsTrue(TryFindEventBySectionId(EventsJson, 'RCSTRG1', EventObj), 'Matching-skill (RCSTSKG) event must be present.');
        AssertIsTrue(not TryFindEventBySectionId(EventsJson, 'RCSTRH1', EventObj), 'Other-skill (RCSTSKH) event must be excluded.');
    end;

    [Test]
    procedure GivenSkillFilterSet_WhenBuildCapacityJson_ThenOtherSkillResourcesAreExcluded()
    var
        PeriodStart: Date;
        CapacityJson: Text;
        EventObj: JsonObject;
    begin
        // [GIVEN] Two resources on different skills, each with a Capacity entry the same day.
        PeriodStart := GetTestMonday(36);
        ClearPeriodData(PeriodStart);
        CreateTestSkillCode('RCSTSKI');
        CreateTestSkillCode('RCSTSKJ');
        CreateTestResource('RCSTRI1', 'RCST SkillFilter Capacity I1');
        CreateTestResource('RCSTRJ1', 'RCST SkillFilter Capacity J1');
        AssignResourceSkill('RCSTRI1', 'RCSTSKI');
        AssignResourceSkill('RCSTRJ1', 'RCSTSKJ');
        InsertResCapacityEntry('RCSTRI1', PeriodStart, 4);
        InsertResCapacityEntry('RCSTRJ1', PeriodStart, 4);

        // [WHEN] SkillResScheduler_BuildCapacityJson is called with SkillFilter = 'RCSTSKI'.
        CapacityJson := DHXDataHandler.SkillResScheduler_BuildCapacityJson('', 'RCSTSKI', PeriodStart, PeriodStart + 6);

        // [THEN] Only the RCSTSKI resource's Capacity bar is returned.
        AssertIsTrue(TryFindEventBySectionId(CapacityJson, 'RCSTRI1', EventObj), 'Matching-skill (RCSTSKI) capacity must be present.');
        AssertIsTrue(not TryFindEventBySectionId(CapacityJson, 'RCSTRJ1', EventObj), 'Other-skill (RCSTSKJ) capacity must be excluded.');
    end;

    [Test]
    procedure GivenSkillFilterSet_WhenBuildTreeJson_ThenOnlyMatchingSkillNodeReturned()
    var
        TreeJson: Text;
        SkillNode: JsonObject;
    begin
        // [GIVEN] Two skills, each with one resource.
        CreateTestSkillCode('RCSTSKK');
        CreateTestSkillCode('RCSTSKL');
        CreateTestResource('RCSTRK1', 'RCST SkillFilter Tree K1');
        CreateTestResource('RCSTRL1', 'RCST SkillFilter Tree L1');
        AssignResourceSkill('RCSTRK1', 'RCSTSKK');
        AssignResourceSkill('RCSTRL1', 'RCSTSKL');

        // [WHEN] SkillResScheduler_BuildTreeJson is called with SkillFilter = 'RCSTSKK'.
        TreeJson := DHXDataHandler.SkillResScheduler_BuildTreeJson('', 'RCSTSKK');

        // [THEN] Only the RCSTSKK skill node exists in the tree.
        AssertIsTrue(TryFindSkillNode(TreeJson, 'RCSTSKK', SkillNode), 'Matching-skill node must exist.');
        AssertIsTrue(not TreeHasNodeWithKey(TreeJson, 'SKILL|RCSTSKL'), 'Other-skill node must be excluded.');
    end;
}
