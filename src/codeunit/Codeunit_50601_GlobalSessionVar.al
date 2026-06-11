codeunit 50601 "Global Session Var Opt."
{
    SingleInstance = True;

    trigger OnRun()
    begin

    end;

    var
        JobNo: Code[20];
        DayPlanningTemp: Record "Day Planning" temporary;

    procedure SetJobNo(NewJobNo: Code[20])
    begin
        JobNo := NewJobNo;
    end;

    procedure GetJobNo(): Code[20]
    begin
        exit(JobNo);
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