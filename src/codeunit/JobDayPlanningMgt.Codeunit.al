codeunit 50610 "Day Tasks Mgt."
{

    procedure UnpackAllJobPlanningLines()
    var
        JobPlanningLine: Record "Job Planning Line";
        ConfirmMsg: Label 'This will delete all existing day planning lines and recreate them from job planning lines. Do you want to continue?';
    begin
        if not Confirm(ConfirmMsg, false) then
            exit;

        ClearDayPlanningLines();

        if JobPlanningLine.FindSet() then
            repeat
                UnpackJobPlanningLine(JobPlanningLine, false);
            until JobPlanningLine.Next() = 0;

        Message('Day planning lines have been successfully created.');
    end;

    procedure UnpackJobPlanningLine(JobPlanningLine: Record "Job Planning Line")
    begin
        UnpackJobPlanningLine(JobPlanningLine, true)
    end;

    local procedure UnpackJobPlanningLine(JobPlanningLine: Record "Job Planning Line"; DoDelete: Boolean)
    var
        DayTasks: Record "Day Tasks";
        StartDate: Date;
        EndDate: Date;
        CurrentDate: Date;
        StartDateTime: DateTime;
        EndDateTime: DateTime;
        DayNo: Integer;
        DayStartTime: Time;
        DayEndTime: Time;
    begin
        if DoDelete then
            ClearDayPlanningLines(JobPlanningLine);
        // Get the start and end dates
        StartDate := JobPlanningLine."Planning Date";
        if JobPlanningLine."End Planning Date" <> 0D then
            EndDate := JobPlanningLine."End Planning Date"
        else
            EndDate := StartDate;

        // If no valid date range, skip
        if (StartDate = 0D) then
            exit;

        // Delete existing day planning lines for this job planning line
        DayTasks.SetRange("Job No.", JobPlanningLine."Job No.");
        DayTasks.SetRange("Job Task No.", JobPlanningLine."Job Task No.");
        DayTasks.SetRange("Job Planning Line No.", JobPlanningLine."Line No.");
        DayTasks.DeleteAll();

        // Create day planning lines for each day in the range
        CurrentDate := StartDate;


        while CurrentDate <= EndDate do begin
            Clear(DayTasks);
            DayTasks."Job No." := JobPlanningLine."Job No.";
            DayTasks."Job Task No." := JobPlanningLine."Job Task No.";
            DayTasks."Job Planning Line No." := JobPlanningLine."Line No.";
            DayNo := DATE2DMY(CurrentDate, 3) * 10000 +
             DATE2DMY(CurrentDate, 2) * 100 +
             DATE2DMY(CurrentDate, 1);

            DayTasks."Day No." := DayNo;
            DayTasks."Planning Date" := CurrentDate;

            // Calculate start and end times for this day
            DayStartTime := JobPlanningLine."Start Time";
            DayEndTime := JobPlanningLine."End Time";

            DayTasks."Start Time" := DayStartTime;
            DayTasks."End Time" := DayEndTime;

            // Copy other fields from job planning line
            DayTasks.Type := JobPlanningLine.Type;
            DayTasks."No." := JobPlanningLine."No.";
            DayTasks.Description := JobPlanningLine.Description;
            DayTasks."Unit of Measure Code" := JobPlanningLine."Unit of Measure Code";
            DayTasks."Work Type Code" := JobPlanningLine."Work Type Code";
            DayTasks."Vendor No." := JobPlanningLine."Vendor No.";
            DayTasks.Depth := JobPlanningLine.Depth;
            DayTasks.IsBoor := JobPlanningLine.Isboor;

            // Calculate quantity for this day (proportional distribution)
            DayTasks.Quantity := CalculateDayQuantity(JobPlanningLine, CurrentDate, StartDate, EndDate, DayStartTime, DayEndTime);

            DayTasks.Insert();

            CurrentDate := CalcDate('<+1D>', CurrentDate);

        end;
    end;

    local procedure CalculateDayQuantity(JobPlanningLine: Record "Job Planning Line"; CurrentDate: Date; StartDate: Date; EndDate: Date; DayStartTime: Time; DayEndTime: Time): Decimal
    var
        TotalHours: Decimal;
        DayHours: Decimal;
        TotalSeconds: BigInteger;
        DaySeconds: BigInteger;
        StartDateTime: DateTime;
        EndDateTime: DateTime;
        DayStartDateTime: DateTime;
        DayEndDateTime: DateTime;
    begin
        // If quantity is 0, return 0
        if JobPlanningLine.Quantity = 0 then
            exit(0);

        // Calculate total time span in seconds
        StartDateTime := CreateDateTime(StartDate, JobPlanningLine."Start Time");
        if JobPlanningLine."End Planning Date" <> 0D then
            EndDateTime := CreateDateTime(JobPlanningLine."End Planning Date", JobPlanningLine."End Time")
        else
            EndDateTime := CreateDateTime(StartDate, JobPlanningLine."End Time");

        TotalSeconds := EndDateTime - StartDateTime;

        // Calculate this day's time span in seconds
        DayStartDateTime := CreateDateTime(CurrentDate, DayStartTime);
        DayEndDateTime := CreateDateTime(CurrentDate, DayEndTime);
        DaySeconds := DayEndDateTime - DayStartDateTime;

        // If total time is zero, distribute equally
        if TotalSeconds <= 0 then
            exit(JobPlanningLine.Quantity);

        // Calculate proportional quantity for this day
        exit(Round(JobPlanningLine.Quantity * DaySeconds / TotalSeconds, 0.00001));
    end;

    local procedure ClearDayPlanningLines()
    var
        JobDayPlanningLine: Record "Day Tasks";
    begin
        JobDayPlanningLine.DeleteAll();
    end;

    local procedure ClearDayPlanningLines(JobPlanLine: Record "Job Planning Line")
    var
        JobDayPlanningLine: Record "Day Tasks";
    begin
        JobDayPlanningLine.SetRange("Job No.", JobPlanLine."Job No.");
        JobDayPlanningLine.SetRange("Job Task No.", JobPlanLine."Job Task No.");
        JobDayPlanningLine.SetRange("Job Planning Line No.", JobPlanLine."Line No.");
        JobDayPlanningLine.DeleteAll();
    end;

    procedure UnpackJobPlanningLinesForJob(JobNo: Code[20])
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        JobPlanningLine.SetRange("Job No.", JobNo);
        if JobPlanningLine.FindSet() then
            repeat
                UnpackJobPlanningLine(JobPlanningLine);
            until JobPlanningLine.Next() = 0;
    end;

    procedure UnpackJobPlanningLinesForJobTask(JobNo: Code[20]; JobTaskNo: Code[20])
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        JobPlanningLine.SetRange("Job No.", JobNo);
        JobPlanningLine.SetRange("Job Task No.", JobTaskNo);
        if JobPlanningLine.FindSet() then
            repeat
                UnpackJobPlanningLine(JobPlanningLine);
            until JobPlanningLine.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Job Planning Line", 'OnAfterModifyEvent', '', false, false)]
    local procedure OnAfterModifyJobPlanningLine(var Rec: Record "Job Planning Line"; var xRec: Record "Job Planning Line"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary then
            exit;

        // Check if date/time fields have changed
        if (Rec."Planning Date" <> xRec."Planning Date") or
           (Rec."End Planning Date" <> xRec."End Planning Date") or
           (Rec."Start Time" <> xRec."Start Time") or
           (Rec."End Time" <> xRec."End Time") or
           (Rec.Quantity <> xRec.Quantity)
        then
            UnpackJobPlanningLine(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Job Planning Line", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterInsertJobPlanningLine(var Rec: Record "Job Planning Line"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary then
            exit;

        UnpackJobPlanningLine(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Job Planning Line", 'OnAfterDeleteEvent', '', false, false)]
    local procedure OnAfterDeleteJobPlanningLine(var Rec: Record "Job Planning Line"; RunTrigger: Boolean)
    var
        JobDayPlanningLine: Record "Day Tasks";
    begin
        if Rec.IsTemporary then
            exit;

        // Delete related day planning lines
        JobDayPlanningLine.SetRange("Job No.", Rec."Job No.");
        JobDayPlanningLine.SetRange("Job Task No.", Rec."Job Task No.");
        JobDayPlanningLine.SetRange("Job Planning Line No.", Rec."Line No.");
        JobDayPlanningLine.DeleteAll();
    end;
}
