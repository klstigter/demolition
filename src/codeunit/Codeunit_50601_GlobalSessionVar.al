codeunit 50601 "Global Session Var Opt."
{
    SingleInstance = True;

    trigger OnRun()
    begin

    end;

    var
        JobNo: Code[20];
        DayTaskTemp: Record "Day Tasks" temporary;

    procedure SetJobNo(NewJobNo: Code[20])
    begin
        JobNo := NewJobNo;
    end;

    procedure GetJobNo(): Code[20]
    begin
        exit(JobNo);
    end;

    procedure ResetDayTaskTemp()
    begin
        DayTaskTemp.Reset();
        DayTaskTemp.DeleteAll();
    end;

    procedure SetDayTaskTemp(DayTask: Record "Day Tasks")
    begin
        DayTaskTemp := DayTask;
        if DayTaskTemp.Insert() then;
    end;

    procedure GetDayTaskTemp(var pDayTaskTemp: Record "Day Tasks" temporary)
    begin
        pDayTaskTemp.Reset();
        pDayTaskTemp.DeleteAll();
        DayTaskTemp.Reset();
        if DayTaskTemp.FindSet() then
            repeat
                pDayTaskTemp := DayTaskTemp;
                if pDayTaskTemp.Insert() then;
            until DayTaskTemp.Next() = 0;
    end;
}