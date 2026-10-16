codeunit 50733 "API Key Mgt Opt."
{
    // Generates a primary key for API inserts when the client omits / blanks the last key field.
    // Numbering: highest existing numeric value under the same parent + 10000 (10000 if none).

    procedure GetNextJobTaskNo(JobNo: Code[20]): Code[20]
    var
        JobTask: Record "Job Task";
        TaskNo: BigInteger;
        MaxNo: BigInteger;
    begin
        JobTask.SetRange("Job No.", JobNo);
        if JobTask.FindSet() then
            repeat
                if Evaluate(TaskNo, JobTask."Job Task No.") then
                    if TaskNo > MaxNo then
                        MaxNo := TaskNo;
            until JobTask.Next() = 0;
        exit(CopyStr(Format(MaxNo + 10000, 0, 9), 1, MaxStrLen(JobTask."Job Task No.")));
    end;

    procedure GetNextDayLineNo(JobNo: Code[20]; JobTaskNo: Code[20]): Integer
    var
        DayPlanning: Record "Day Planning";
    begin
        DayPlanning.SetRange("Job No.", JobNo);
        DayPlanning.SetRange("Job Task No.", JobTaskNo);
        if DayPlanning.FindLast() then
            exit(DayPlanning."Day Line No." + 10000);
        exit(10000);
    end;

    procedure GetNextAbsenceLineNo(): Integer
    var
        RegisterAbsence: Record "Register Absence";
    begin
        if RegisterAbsence.FindLast() then
            exit(RegisterAbsence."Line No." + 10000);
        exit(10000);
    end;
}
