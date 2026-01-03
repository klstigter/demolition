codeunit 60013 "Date Span Test Context"
{
    var
        ScenarioCode: Text;
        ShowPasses: Boolean;
        BufOk: List of [Boolean];
        BufMsg: List of [Text];

    procedure Init(NewScenarioCode: Text; NewShowPasses: Boolean)
    begin
        ScenarioCode := NewScenarioCode;
        ShowPasses := NewShowPasses;
        Clear(BufOk);
        Clear(BufMsg);
    end;

    procedure AssertTrue(Condition: Boolean; Message: Text)
    begin
        BufOk.Add(Condition);
        BufMsg.Add(Message);
    end;

    procedure AssertEqualDate(Expected: Date; Actual: Date; Message: Text)
    begin
        AssertTrue(Expected = Actual, StrSubstNo('%1 (Expected=%2, Actual=%3)', Message, Expected, Actual));
    end;

    procedure AssertEqualText(Expected: Text; Actual: Text; Message: Text)
    begin
        AssertTrue(Expected = Actual, StrSubstNo('%1 (Expected=%2, Actual=%3)', Message, Expected, Actual));
    end;

    procedure Next(var Ok: Boolean; var Msg: Text): Boolean
    var
        FirstOk: Boolean;
        FirstMsg: Text;
    begin
        if BufOk.Count() = 0 then
            exit(false);

        FirstOk := BufOk.Get(1);
        FirstMsg := BufMsg.Get(1);

        BufOk.RemoveAt(1);
        BufMsg.RemoveAt(1);

        Ok := FirstOk;
        Msg := FirstMsg;
        exit(true);
    end;
}
