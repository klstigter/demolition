codeunit 60028 "Skill Font/Border Color Tests"
{
    // Tests for codeunit 50609 "Visual Default Settings" - procedures GetSkillFontColor and
    // GetSkillBorderColor (the per-skill Font Color/Border Color resolution added to drive every
    // bar-style visual: scheduler timelines, Gantt chart, bar charts) - and codeunit 50604 "DHX
    // Data Handler"'s BuildSkillFontBorderColorsJson, the shared JSON payload builder several of
    // those add-ins now call. Contract under test:
    //   - Skill Code's own "Font Color"/"Border Color" (tableext 50609, fields 50601/50602) win
    //     when non-blank.
    //   - When blank, GetSkillFontColor falls back to codeunit 50609's own hardcoded default -
    //     NEVER to "Daily Optimizer Setup"."Bar Font Color" (that field is reserved for the
    //     Capacity bar only, per explicit product decision - this is the behavior most worth
    //     regression-testing, since it's easy to accidentally reintroduce a Setup lookup here).
    //   - When blank, GetSkillBorderColor falls back to that same skill's own resolved fill color
    //     (GetSkillBarColor), not a second unrelated constant.
    //   - Both return blank for the synthetic 'CAPACITY' marker, matching GetSkillBarColor's own
    //     convention.
    Subtype = Test;
    TestPermissions = Disabled;

    var
        IsInitialized: Boolean;
        TestSkillCode: Code[10];
        TestSkillCode2: Code[10];

    local procedure Initialize()
    var
        SkillCode: Record "Skill Code";
    begin
        TestSkillCode := 'SFBCTSKL';
        TestSkillCode2 := 'SFBCTSK2';

        if IsInitialized then
            exit;

        if not SkillCode.Get(TestSkillCode) then begin
            SkillCode.Init();
            SkillCode.Code := TestSkillCode;
            SkillCode.Description := 'Skill Font/Border Color Test Skill';
            SkillCode.Insert();
        end;
        if not SkillCode.Get(TestSkillCode2) then begin
            SkillCode.Init();
            SkillCode.Code := TestSkillCode2;
            SkillCode.Description := 'Skill Font/Border Color Test Skill 2';
            SkillCode.Insert();
        end;

        IsInitialized := true;
        Commit();
    end;

    /// <summary>
    /// Resets the test skill's "Bar Color"/"Font Color"/"Border Color" to the given values (blank
    /// = ''), so each test starts from a known state regardless of what a prior test left behind -
    /// al_run_tests does not roll back data between test methods (same convention as the other new
    /// test codeunits in this folder).
    /// </summary>
    local procedure SetSkillColors(SkillCodeVal: Code[10]; BarColor: Text[50]; FontColor: Text[50]; BorderColor: Text[50])
    var
        SkillCode: Record "Skill Code";
    begin
        SkillCode.Get(SkillCodeVal);
        SkillCode."Bar Color" := BarColor;
        SkillCode."Font Color" := FontColor;
        SkillCode."Border Color" := BorderColor;
        SkillCode.Modify();
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
    procedure GivenSkillFontColorSet_WhenGetSkillFontColor_ThenReturnsSkillsOwnValue()
    var
        VisualDefaultSettings: Codeunit "Visual Default Settings";
    begin
        // [GIVEN] A skill with an explicit Font Color
        Initialize();
        SetSkillColors(TestSkillCode, '', '#112233', '');

        // [WHEN] GetSkillFontColor is called [THEN] the skill's own override wins
        AssertAreEqual('#112233', VisualDefaultSettings.GetSkillFontColor(TestSkillCode), 'GetSkillFontColor should return the skill''s own Font Color when set.');
    end;

    [Test]
    procedure GivenSkillFontColorBlank_WhenGetSkillFontColor_ThenReturnsHardcodedDefault_NotDailyOptimizerSetup()
    var
        DailyOptimizerSetup: Record "Daily Optimizer Setup";
        VisualDefaultSettings: Codeunit "Visual Default Settings";
    begin
        // [GIVEN] A skill with NO Font Color set, AND a "Daily Optimizer Setup"."Bar Font Color"
        // deliberately set to a DIFFERENT, distinctive value - if GetSkillFontColor ever
        // accidentally fell back to that setup field instead of its own hardcoded default, this
        // test would catch it immediately (the two expected values are intentionally different).
        Initialize();
        SetSkillColors(TestSkillCode, '', '', '');

        if not DailyOptimizerSetup.Get() then begin
            DailyOptimizerSetup.Init();
            DailyOptimizerSetup.Insert();
        end;
        DailyOptimizerSetup."Bar Font Color" := '#ABCDEF';
        DailyOptimizerSetup.Modify();

        // [WHEN] GetSkillFontColor is called [THEN] it returns codeunit 50609's own hardcoded
        // default (GetDefaultBarFontColor, '#000000'), completely ignoring the Setup field above -
        // that field is reserved for the Capacity bar only (GetBarFontColor), not this procedure.
        AssertAreEqual(VisualDefaultSettings.GetDefaultBarFontColor(), VisualDefaultSettings.GetSkillFontColor(TestSkillCode),
            'GetSkillFontColor with a blank Skill Font Color must fall back to the hardcoded default, never to "Daily Optimizer Setup"."Bar Font Color".');
        AssertAreEqual('#000000', VisualDefaultSettings.GetSkillFontColor(TestSkillCode), 'Sanity check on the actual hardcoded default value.');
    end;

    [Test]
    procedure GivenCapacityMarker_WhenGetSkillFontColor_ThenReturnsBlank()
    var
        VisualDefaultSettings: Codeunit "Visual Default Settings";
    begin
        // [GIVEN/WHEN] The synthetic 'CAPACITY' aggregate-row marker (not a real Skill Code)
        Initialize();

        // [THEN] Blank, same convention as GetSkillBarColor's own CAPACITY guard
        AssertAreEqual('', VisualDefaultSettings.GetSkillFontColor('CAPACITY'), 'GetSkillFontColor must return blank for the CAPACITY marker.');
    end;

    [Test]
    procedure GivenSkillBorderColorSet_WhenGetSkillBorderColor_ThenReturnsSkillsOwnValue()
    var
        VisualDefaultSettings: Codeunit "Visual Default Settings";
    begin
        // [GIVEN] A skill with an explicit Border Color (and, deliberately, a DIFFERENT Bar
        // Color, so a test failure that fell through to the fill-color fallback would be obvious)
        Initialize();
        SetSkillColors(TestSkillCode, '#999999', '', '#445566');

        // [WHEN] GetSkillBorderColor is called [THEN] the skill's own override wins
        AssertAreEqual('#445566', VisualDefaultSettings.GetSkillBorderColor(TestSkillCode, 0), 'GetSkillBorderColor should return the skill''s own Border Color when set.');
    end;

    [Test]
    procedure GivenBorderBlankButBarColorSet_WhenGetSkillBorderColor_ThenFallsBackToBarColor()
    var
        VisualDefaultSettings: Codeunit "Visual Default Settings";
    begin
        // [GIVEN] A skill with Bar Color set but Border Color blank
        Initialize();
        SetSkillColors(TestSkillCode, '#778899', '', '');

        // [WHEN] GetSkillBorderColor is called [THEN] it falls back to the skill's own resolved
        // fill color (GetSkillBarColor), not a second, unrelated hardcoded constant
        AssertAreEqual('#778899', VisualDefaultSettings.GetSkillBorderColor(TestSkillCode, 0), 'GetSkillBorderColor with blank Border Color should fall back to the skill''s own Bar Color.');
    end;

    [Test]
    procedure GivenBorderAndBarColorBothBlank_WhenGetSkillBorderColor_ThenFallsBackToPalette()
    var
        VisualDefaultSettings: Codeunit "Visual Default Settings";
        ExpectedPaletteColor: Text;
    begin
        // [GIVEN] A skill with both Bar Color and Border Color blank
        Initialize();
        SetSkillColors(TestSkillCode, '', '', '');

        // [WHEN] GetSkillBorderColor is called with a specific PaletteIndex [THEN] it falls all
        // the way through to GetSkillBarColor's own 5-colour palette at that same index - proven
        // by cross-checking against GetSkillBarColor directly for the identical skill/index.
        ExpectedPaletteColor := VisualDefaultSettings.GetSkillBarColor(TestSkillCode, 2);
        AssertAreEqual(ExpectedPaletteColor, VisualDefaultSettings.GetSkillBorderColor(TestSkillCode, 2),
            'GetSkillBorderColor with both colors blank should resolve to the exact same palette color GetSkillBarColor itself would return for that index.');
    end;

    [Test]
    procedure GivenCapacityMarker_WhenGetSkillBorderColor_ThenReturnsBlank()
    var
        VisualDefaultSettings: Codeunit "Visual Default Settings";
    begin
        Initialize();
        AssertAreEqual('', VisualDefaultSettings.GetSkillBorderColor('CAPACITY', 0), 'GetSkillBorderColor must return blank for the CAPACITY marker.');
    end;

    [Test]
    procedure GivenTwoSkillsWithDistinctColors_WhenBuildSkillFontBorderColorsJson_ThenEachSkillsEntryMatchesItsOwnGetters()
    var
        DHXDataHandler: Codeunit "DHX Data Handler";
        VisualDefaultSettings: Codeunit "Visual Default Settings";
        ResultJson: Text;
        RootArr: JsonArray;
        SkillToken: JsonToken;
        SkillObj: JsonObject;
        FieldToken: JsonToken;
        CodeTxt: Text;
        FoundFirst: Boolean;
        FoundSecond: Boolean;
    begin
        // [GIVEN] Two skills with distinct, known Font/Border Color overrides
        Initialize();
        SetSkillColors(TestSkillCode, '', '#111111', '#222222');
        SetSkillColors(TestSkillCode2, '', '#333333', '#444444');

        // [WHEN] The shared JSON payload builder (reused by projectschedule/
        // resourceschedule_with_capacity and the bar charts) is called
        ResultJson := DHXDataHandler.BuildSkillFontBorderColorsJson();

        // [THEN] Both test skills' entries carry exactly what their own getters return - proves
        // the JSON wiring (codeunit 50604) stays consistent with the resolution logic (codeunit
        // 50609) rather than duplicating/drifting from it
        RootArr.ReadFrom(ResultJson);
        foreach SkillToken in RootArr do begin
            SkillObj := SkillToken.AsObject();
            SkillObj.Get('code', FieldToken);
            CodeTxt := FieldToken.AsValue().AsText();

            if CodeTxt = TestSkillCode then begin
                FoundFirst := true;
                SkillObj.Get('fontColor', FieldToken);
                AssertAreEqual(VisualDefaultSettings.GetSkillFontColor(TestSkillCode), FieldToken.AsValue().AsText(), 'JSON fontColor for skill 1 should match GetSkillFontColor.');
                SkillObj.Get('borderColor', FieldToken);
                AssertAreEqual(VisualDefaultSettings.GetSkillBorderColor(TestSkillCode, 0), FieldToken.AsValue().AsText(), 'JSON borderColor for skill 1 should match GetSkillBorderColor (PaletteIndex irrelevant here since Border Color is explicitly set).');
            end;
            if CodeTxt = TestSkillCode2 then begin
                FoundSecond := true;
                SkillObj.Get('fontColor', FieldToken);
                AssertAreEqual('#333333', FieldToken.AsValue().AsText(), 'JSON fontColor for skill 2 should match its own explicit override.');
                SkillObj.Get('borderColor', FieldToken);
                AssertAreEqual('#444444', FieldToken.AsValue().AsText(), 'JSON borderColor for skill 2 should match its own explicit override.');
            end;
        end;

        if not FoundFirst then
            Error('Expected an entry for skill "%1" in BuildSkillFontBorderColorsJson''s output, but none was found.', TestSkillCode);
        if not FoundSecond then
            Error('Expected an entry for skill "%1" in BuildSkillFontBorderColorsJson''s output, but none was found.', TestSkillCode2);
    end;
}
