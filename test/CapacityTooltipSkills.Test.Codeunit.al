codeunit 60031 "Capacity Tooltip Skills Tests"
{
    // Tests for the capacity-tooltip "skills" text: GetResourceSkillsTxtCached and the
    // 'skills' field on capacity events from both ResGroupResScheduler_BuildCapacityJson
    // (Resource Group mode) and SkillResScheduler_BuildCapacityJson (Skill mode).
    Subtype = Test;
    TestPermissions = Disabled;

    var
        DHXDataHandler: Codeunit "DHX Data Handler";

    local procedure AssertAreEqual(Expected: Text; Actual: Text; ErrMsg: Text)
    begin
        if Expected <> Actual then
            Error('%1 Expected: %2, Actual: %3', ErrMsg, Expected, Actual);
    end;

    local procedure AssertIsTrue(Condition: Boolean; ErrMsg: Text)
    begin
        if not Condition then
            Error(ErrMsg);
    end;

    local procedure GetTestMonday(WeeksAhead: Integer): Date
    var
        CandidateDate: Date;
    begin
        CandidateDate := CalcDate(StrSubstNo('<+%1W>', WeeksAhead), Today());
        exit(CandidateDate - (Date2DWY(CandidateDate, 1) - 1));
    end;

    local procedure CreateTestResource(ResNo: Code[20])
    var
        Resource: Record Resource;
    begin
        if not Resource.Get(ResNo) then begin
            Resource.Init();
            Resource."No." := ResNo;
            Resource.Type := Resource.Type::Person;
            Resource.Insert();
        end;
        Resource.Name := 'CTST ' + ResNo;
        Resource.Modify();
    end;

    local procedure AddSkill(ResNo: Code[20]; SkillCodeValue: Code[10])
    var
        SkillCode: Record "Skill Code";
        ResourceSkill: Record "Resource Skill";
    begin
        if not SkillCode.Get(SkillCodeValue) then begin
            SkillCode.Init();
            SkillCode.Code := SkillCodeValue;
            SkillCode.Description := 'CTST ' + SkillCodeValue;
            SkillCode.Insert();
        end;
        ResourceSkill.Init();
        ResourceSkill.Type := ResourceSkill.Type::Resource;
        ResourceSkill."No." := ResNo;
        ResourceSkill."Skill Code" := SkillCodeValue;
        ResourceSkill.Insert();
    end;

    local procedure AddCapacity(ResNo: Code[20]; EntryDate: Date; CapacityValue: Decimal)
    var
        ResCapacityEntry: Record "Res. Capacity Entry";
        LastEntry: Record "Res. Capacity Entry";
    begin
        ResCapacityEntry.Init();
        ResCapacityEntry."Resource No." := ResNo;
        ResCapacityEntry.Date := EntryDate;
        ResCapacityEntry.Capacity := CapacityValue;
        if LastEntry.FindLast() then
            ResCapacityEntry."Entry No." := LastEntry."Entry No." + 1
        else
            ResCapacityEntry."Entry No." := 1;
        ResCapacityEntry.Insert(true);
    end;

    /// <summary>Returns the skills text of the first capacity event whose resource_id = ResNo; fails if none.</summary>
    local procedure GetEventSkills(EventsJson: Text; ResNo: Text; var SkillsTxt: Text): Boolean
    var
        Root: JsonObject;
        DataToken: JsonToken;
        EventToken: JsonToken;
        ResToken: JsonToken;
        SkillsToken: JsonToken;
        EventObj: JsonObject;
        EventsArray: JsonArray;
        i: Integer;
    begin
        AssertIsTrue(Root.ReadFrom(EventsJson), 'Events JSON must parse.');
        AssertIsTrue(Root.Get('data', DataToken), 'Events JSON must have data.');
        EventsArray := DataToken.AsArray();
        for i := 0 to EventsArray.Count() - 1 do begin
            EventsArray.Get(i, EventToken);
            EventObj := EventToken.AsObject();
            if EventObj.Get('resource_id', ResToken) then
                if ResToken.AsValue().AsText() = ResNo then begin
                    AssertIsTrue(EventObj.Get('skills', SkillsToken), 'Capacity event must have a skills field.');
                    SkillsTxt := SkillsToken.AsValue().AsText();
                    exit(true);
                end;
        end;
        exit(false);
    end;

    [Test]
    procedure GivenResourceWithNoSkills_WhenGetSkillsTxt_ThenEmpty()
    var
        Cache: Dictionary of [Code[20], Text];
    begin
        // [GIVEN] A resource with no skills
        CreateTestResource('CTSTR0');
        // [WHEN/THEN]
        AssertAreEqual('', DHXDataHandler.GetResourceSkillsTxtCached('CTSTR0', Cache), 'Skills text for no skills.');
    end;

    [Test]
    procedure GivenResourceWithOneSkill_WhenGetSkillsTxt_ThenThatCode()
    var
        Cache: Dictionary of [Code[20], Text];
    begin
        CreateTestResource('CTSTR1');
        AddSkill('CTSTR1', 'CTSTA');
        AssertAreEqual('CTSTA', DHXDataHandler.GetResourceSkillsTxtCached('CTSTR1', Cache), 'Skills text for one skill.');
    end;

    [Test]
    procedure GivenResourceWithManySkills_WhenGetSkillsTxt_ThenJoinedWithPipe()
    var
        Cache: Dictionary of [Code[20], Text];
    begin
        CreateTestResource('CTSTR2');
        AddSkill('CTSTR2', 'CTSTA');
        AddSkill('CTSTR2', 'CTSTB');
        AddSkill('CTSTR2', 'CTSTC');
        AssertAreEqual('CTSTA | CTSTB | CTSTC', DHXDataHandler.GetResourceSkillsTxtCached('CTSTR2', Cache), 'Skills text joined.');
    end;

    [Test]
    procedure GivenCachedResource_WhenCalledAgain_ThenCachedValueReturned()
    var
        Cache: Dictionary of [Code[20], Text];
        First: Text;
    begin
        // [GIVEN] First call populates the cache
        CreateTestResource('CTSTR3');
        AddSkill('CTSTR3', 'CTSTA');
        First := DHXDataHandler.GetResourceSkillsTxtCached('CTSTR3', Cache);
        // [WHEN] A skill is added after, then called again with the same cache
        AddSkill('CTSTR3', 'CTSTB');
        // [THEN] Same cached result is returned (no re-query)
        AssertAreEqual(First, DHXDataHandler.GetResourceSkillsTxtCached('CTSTR3', Cache), 'Cached result must be identical.');
        AssertAreEqual('CTSTA', First, 'First result.');
        AssertIsTrue(Cache.ContainsKey('CTSTR3'), 'Cache must hold the resource.');
    end;

    [Test]
    procedure GivenResourceWithSkills_WhenResourceGroupCapacityJson_ThenEventHasSkills()
    var
        PeriodStart: Date;
        Json: Text;
        SkillsTxt: Text;
    begin
        // [GIVEN] Resource with 2 skills and a capacity entry
        PeriodStart := GetTestMonday(60);
        CreateTestResource('CTSTR4');
        AddSkill('CTSTR4', 'CTSTA');
        AddSkill('CTSTR4', 'CTSTB');
        AddCapacity('CTSTR4', PeriodStart, 8);
        // [WHEN] Resource Group mode capacity JSON is built
        Json := DHXDataHandler.ResGroupResScheduler_BuildCapacityJson('CTSTR4', '', PeriodStart, PeriodStart + 6);
        // [THEN] The event carries the skills
        AssertIsTrue(GetEventSkills(Json, 'CTSTR4', SkillsTxt), 'Capacity event must exist (Resource Group mode).');
        AssertAreEqual('CTSTA | CTSTB', SkillsTxt, 'Resource Group mode skills.');
    end;

    [Test]
    procedure GivenResourceWithSkills_WhenSkillModeCapacityJson_ThenEventHasSkills()
    var
        PeriodStart: Date;
        Json: Text;
        SkillsTxt: Text;
    begin
        // [GIVEN] Resource with 2 skills and a capacity entry
        PeriodStart := GetTestMonday(61);
        CreateTestResource('CTSTR5');
        AddSkill('CTSTR5', 'CTSTA');
        AddSkill('CTSTR5', 'CTSTB');
        AddCapacity('CTSTR5', PeriodStart, 8);
        // [WHEN] Skill mode capacity JSON is built
        Json := DHXDataHandler.SkillResScheduler_BuildCapacityJson('CTSTR5', '', PeriodStart, PeriodStart + 6);
        // [THEN] The event carries both skills (order not asserted)
        AssertIsTrue(GetEventSkills(Json, 'CTSTR5', SkillsTxt), 'Capacity event must exist (Skill mode).');
        AssertIsTrue(StrPos(SkillsTxt, 'CTSTA') > 0, 'Skill mode skills must contain CTSTA, got: ' + SkillsTxt);
        AssertIsTrue(StrPos(SkillsTxt, 'CTSTB') > 0, 'Skill mode skills must contain CTSTB, got: ' + SkillsTxt);
        AssertIsTrue(StrPos(SkillsTxt, ' | ') > 0, 'Skill mode skills must be pipe-joined, got: ' + SkillsTxt);
    end;
}
