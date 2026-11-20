codeunit 50601 "Global Session Var Opt."
{
    SingleInstance = True;

    trigger OnRun()
    begin

    end;

    var
        JobNo: Code[20];
        DayPlanningTemp: Record "Day Planning" temporary;
        HeaderInsertPending: Boolean;
        PostResults: JsonArray;

    procedure ResetPostResults()
    begin
        Clear(PostResults);
    end;

    procedure AddPostResult(ResultLine: JsonObject)
    begin
        PostResults.Add(ResultLine);
    end;

    procedure GetPostResultsText(ArrayName: Text): Text
    var
        ResultJson: JsonObject;
        ResultText: Text;
    begin
        ResultJson.Add(ArrayName, PostResults);
        ResultJson.WriteTo(ResultText);
        exit(ResultText);
    end;

    procedure SetJobNo(NewJobNo: Code[20])
    begin
        JobNo := NewJobNo;
    end;

    procedure GetJobNo(): Code[20]
    begin
        exit(JobNo);
    end;

    procedure SetHeaderInsertPending(Pending: Boolean)
    begin
        HeaderInsertPending := Pending;
    end;

    procedure IsHeaderInsertPending(): Boolean
    begin
        exit(HeaderInsertPending);
    end;

    procedure ResetDayPlanningTemp()
    begin
        DayPlanningTemp.Reset();
        DayPlanningTemp.DeleteAll();
    end;

    procedure SetDayPlanningTemp(DayPlanning: Record "Day Planning")
    begin
        DayPlanningTemp := DayPlanning;
        if DayPlanningTemp.Insert() then;
    end;

    procedure GetDayPlanningTemp(var pDayPlanningTemp: Record "Day Planning" temporary)
    begin
        pDayPlanningTemp.Reset();
        pDayPlanningTemp.DeleteAll();
        DayPlanningTemp.Reset();
        if DayPlanningTemp.FindSet() then
            repeat
                pDayPlanningTemp := DayPlanningTemp;
                if pDayPlanningTemp.Insert() then;
            until DayPlanningTemp.Next() = 0;
    end;
}