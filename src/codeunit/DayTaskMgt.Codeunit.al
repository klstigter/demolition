codeunit 50610 "Day Tasks Mgt."
{
    var
        GeneralUtil: Codeunit "General Planning Utilities";
        WorkHoursTemplate: Record "Work-Hour Template";

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

    local procedure UnpackJobPlanningLine(JobPlanningLine: Record "Job Planning Line"; DoDeleteAll: Boolean)
    var
        DayTasks: Record "Day Tasks";
        StartDate: Date;
        EndDate: Date;
        NewTaskDate: Date;
        TaskWkDay: Integer;
        n: Integer;
        StartDateTime: DateTime;
        EndDateTime: DateTime;
        DayNo: Integer;
        DayStartTime: Time;
        DayEndTime: Time;
        NonWorkingHours: Decimal;
        Counter: Integer;
    begin
        case true of
            JobPlanningLine."Work-Hour Template" = '':
                exit;
            JobPlanningLine."Start Planning Date" = 0D:
                exit;
            JobPlanningLine."End Planning Date" = 0D:
                exit;
            (JobPlanningLine."Quantity of Lines" = 0) and (JobPlanningLine."No." = '') and (JobPlanningLine."Vendor No." = ''):
                exit;
        end;

        WorkHoursTemplate.get(JobPlanningLine."Work-Hour Template");
        if DoDeleteAll then
            ClearDayPlanningLines(JobPlanningLine);
        // Get the start and end dates
        StartDate := JobPlanningLine."Start Planning Date";
        if JobPlanningLine."End Planning Date" <> 0D then
            EndDate := JobPlanningLine."End Planning Date"
        else
            EndDate := StartDate;

        // If no valid date range, skip
        if (StartDate = 0D) then
            exit;

        // Delete existing day planning lines for this job planning line
        if not DoDeleteAll then begin
            DayTasks.SetRange("Job No.", JobPlanningLine."Job No.");
            DayTasks.SetRange("Job Task No.", JobPlanningLine."Job Task No.");
            DayTasks.SetRange("Job Planning Line No.", JobPlanningLine."Line No.");
            DayTasks.DeleteAll();
        end;

        // Create day planning lines for each day in the range
        NewTaskDate := StartDate;


        while NewTaskDate <= EndDate do begin
            // Check if this day is a working day in the template   
            if CheckIsWorkingDay(NewTaskDate) then begin

                Clear(DayTasks);
                DayNo := GeneralUtil.DateToInteger(NewTaskDate);
                DayTasks."Day No." := DayNo;
                DayTasks.DayLineNo := 10000;
                DayTasks."Job No." := JobPlanningLine."Job No.";
                DayTasks."Job Task No." := JobPlanningLine."Job Task No.";
                DayTasks."Job Planning Line No." := JobPlanningLine."Line No.";


                DayTasks."Start Planning Date" := NewTaskDate;

                // Calculate start and end times for this day
                if JobPlanningLine."Start Time" <> 0T then
                    DayStartTime := JobPlanningLine."Start Time"
                else
                    DayStartTime := WorkHoursTemplate."Default Start Time";
                if JobPlanningLine."End Time" <> 0T then
                    DayEndTime := JobPlanningLine."End Time"
                else
                    DayEndTime := WorkHoursTemplate."Default End Time";
                if JobPlanningLine."Non Working Minutes" <> 0 then
                    NonWorkingHours := JobPlanningLine."Non Working Minutes"
                else
                    NonWorkingHours := WorkHoursTemplate."Non Working Minutes";

                DayTasks."Start Time" := DayStartTime;
                DayTasks."End Time" := DayEndTime;
                DayTasks.VALIDATE("Non Working Minutes", NonWorkingHours);

                // Calculate working hours
                DayTasks.CalculateWorkingHours();

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
                DayTasks.Quantity := CalculateDayQuantity(JobPlanningLine, NewTaskDate, StartDate, EndDate, DayStartTime, DayEndTime);
                if CheckMayChange(DayTasks) then
                    if DayTasks.Insert() then
                        Counter += 1;
                for n := 2 to JobPlanningLine."Quantity of Lines" do begin
                    DayTasks."DayLineNo" := n * 10000;
                    if CheckMayChange(DayTasks) then
                        if DayTasks.Insert() then
                            Counter += 1;
                end;
            end;
            NewTaskDate := CalcDate('<+1D>', NewTaskDate);
        END;
        Message('%1 day planning lines created for Job %2, Task %3, Planning Line %4.', Counter, JobPlanningLine."Job No.", JobPlanningLine."Job Task No.", JobPlanningLine."Line No.");
    END;

    local procedure CheckMayChange(NewDayTask: Record "Day Tasks"): Boolean
    var
        daytask: Record "Day Tasks";
    begin
        if daytask.Get(NewDayTask."Day No.", NewDayTask.DayLineNo, NewDayTask."Job No.", NewDayTask."Job Task No.", NewDayTask."Job Planning Line No.") then
            Exit(not daytask."Do Not Change");
        exit(true);

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
        if JobPlanningLine."Quantity of Lines" = 0 then
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
        JobDayPlanningLine.SetRange("Do Not Change", false);
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

    procedure CheckIsWorkingDay(DateToCheck: Date) IsWorkingDay: Boolean
    begin
        case Date2DWY(DateToCheck, 1) of
            1:
                IsWorkingDay := WorkHoursTemplate.Monday <> 0;
            2:
                IsWorkingDay := WorkHoursTemplate.Tuesday <> 0;
            3:
                IsWorkingDay := WorkHoursTemplate.Wednesday <> 0;
            4:
                IsWorkingDay := WorkHoursTemplate.Thursday <> 0;
            5:
                IsWorkingDay := WorkHoursTemplate.Friday <> 0;
            6:
                IsWorkingDay := WorkHoursTemplate.Saturday <> 0;
            7:
                IsWorkingDay := WorkHoursTemplate.Sunday <> 0;
        end;
    end;


    [EventSubscriber(ObjectType::Table, Database::"Job Planning Line", 'OnAfterModifyEvent', '', false, false)]
    local procedure OnAfterModifyJobPlanningLine(var Rec: Record "Job Planning Line"; var xRec: Record "Job Planning Line"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary then
            exit;

        // Check if date/time fields have changed
        if (Rec."Start Planning Date" <> xRec."Start Planning Date") or
           (Rec."End Planning Date" <> xRec."End Planning Date") or
           (Rec."Start Time" <> xRec."Start Time") or
           (Rec."End Time" <> xRec."End Time") or
           (Rec.Quantity <> xRec.Quantity)
        then
            exit;
        //UnpackJobPlanningLine(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Job Planning Line", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterInsertJobPlanningLine(var Rec: Record "Job Planning Line"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary then
            exit;

        //UnpackJobPlanningLine(Rec);
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
        JobDayPlanningLine.SetRange("Do Not Change", false);
        JobDayPlanningLine.DeleteAll();
    end;
}
