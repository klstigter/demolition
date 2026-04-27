codeunit 50601 "Global Session Var Opt."
{
    SingleInstance = True;

    trigger OnRun()
    begin

    end;

    var
        JobNo: Code[20];

    procedure SetJobNo(NewJobNo: Code[20])
    begin
        JobNo := NewJobNo;
    end;

    procedure GetJobNo(): Code[20]
    begin
        exit(JobNo);
    end;
}