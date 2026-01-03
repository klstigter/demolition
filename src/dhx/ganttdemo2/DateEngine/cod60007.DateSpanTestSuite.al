codeunit 60007 "Date Span Test Suite"
{

    procedure RunAll(ResetResults: Boolean)
    var
        R: Record "Date Span Test Result";
    begin
        if ResetResults then begin
            R.Reset();
            R.DeleteAll();
        end;

        RunScenario(Codeunit::"DSTS Scenario S01");
        RunScenario(Codeunit::"DSTS Scenario S02");
        RunScenario(Codeunit::"DSTS Scenario S03");
    end;

    procedure RunScenario(ScenarioCuId: Integer)
    var
        Engine: Codeunit "Date Span Engine";
        Nodes: Record "Date Span Node" temporary;
        Msg: Text[2048];
        Passed: Boolean;
        R: Record "Date Span Test Result";
    begin
        Nodes.DeleteAll();
        Clear(Msg);
        Passed := false;

        Passed := TryRunScenario(ScenarioCuId, Engine, Nodes, Msg);

        R.Init();
        //        R."Run At" := Today();
        R."Run DateTime" := CurrentDateTime();
        R."Scenario Code" := GetScenarioName(ScenarioCuId);
        R.Passed := Passed;

        if Msg = '' then begin
            if Passed then
                R.Message := 'OK'
            else
                R.Message := 'FAILED (no message)';
        end else
            R.Message := Msg;

        R.Insert(true);
    end;

    local procedure GetScenarioName(ScenarioCuId: Integer): Code[50]
    begin
        case ScenarioCuId of
            Codeunit::"DSTS Scenario S01":
                exit('S01_TOP_DOWN_UNLOCKED');
            Codeunit::"DSTS Scenario S02":
                exit('S02_MIDDLE_LEVEL_CHANGE');
            Codeunit::"DSTS Scenario S03":
                exit('S03_LOCKS_BLOCK_REQUIRED_EXPANSION');
        end;

        exit(StrSubstNo('SCENARIO_%1', ScenarioCuId));
    end;

    [TryFunction]
    local procedure TryRunScenario(ScenarioCuId: Integer; var Engine: Codeunit "Date Span Engine"; var Nodes: Record "Date Span Node" temporary; var Msg: Text[2048])
    var
        S01: Codeunit "DSTS Scenario S01";
        S02: Codeunit "DSTS Scenario S02";
        S03: Codeunit "DSTS Scenario S03";
    begin
        case ScenarioCuId of
            Codeunit::"DSTS Scenario S01":
                S01.Execute(Engine, Nodes, Msg);

            Codeunit::"DSTS Scenario S02":
                S02.Execute(Engine, Nodes, Msg);

            Codeunit::"DSTS Scenario S03":
                S03.Execute(Engine, Nodes, Msg);

            else
                Error('Unknown scenario codeunit id: %1', ScenarioCuId);
        end;
    end;

    procedure Reset()
    var
        R: Record "Date Span Test Result";
    begin
        R.Reset();
        if not R.IsEmpty() then
            R.DeleteAll();
    end;
}
