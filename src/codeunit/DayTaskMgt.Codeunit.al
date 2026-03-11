codeunit 50610 "Day Tasks Mgt."
{
    var
        GeneralUtil: Codeunit "General Planning Utilities";
        WorkHoursTemplate: Record "Work-Hour Template";

    procedure CreateDayTask()
    var
        JobTask: Record "Job Task";
        ConfirmMsg: Label 'This will delete all existing day planning lines and recreate them from Job Task. Do you want to continue?';
    begin
        if not Confirm(ConfirmMsg, false) then
            exit;

        ClearDayPlanningLines();

        if JobTask.FindSet() then
            repeat
                Message('under construction');
            //CreateDayTask(JobTask, false);
            until JobTask.Next() = 0;

        Message('Day planning lines have been successfully created.');
    end;

    procedure CreateDayTask(DayTaskGenerator: Record "Day Task Generator")
    begin
        CreateDayTask(DayTaskGenerator, true)
    end;

    local procedure CreateDayTask(DayTaskGenerator: Record "Day Task Generator"; DoDeleteAll: Boolean)
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
        HasOverlap: Boolean;
    begin
        DayTaskGenerator.TestField("Work-Hour Template");
        case true of
            (daytaskgenerator."Resource No." = '') and
            (DayTaskGenerator.SkillsRequired = ''):
                error('Skills Required must be specified');
            DayTaskGenerator."Work-Hour Template" = '':
                error('Work-Hour Template must be specified');
            DayTaskGenerator."Start Date" = 0D:
                Error('Planned Start Date must be specified');
            DayTaskGenerator."End Date" = 0D:
                Error('Planned End Date must be specified');
            (DayTaskGenerator."Start Time" = 0T) or (DayTaskGenerator."End Time" = 0T):
                Error('Start Time and End Time must be specified');
            (DayTaskGenerator."Vendor No." <> ''):
                begin
                    DayTaskGenerator."Quantity of Lines" := 1;
                    DayTaskGenerator.Modify(false);
                end;
        end;
        //TODO: refactor?
        //if DayTaskGenerator.StartEndLimitations(true) then
        //    exit;
        WorkHoursTemplate.get(DayTaskGenerator."Work-Hour Template");
        // Get the start and end dates
        StartDate := DayTaskGenerator."Start Date";
        if DayTaskGenerator."End Date" <> 0D then
            EndDate := DayTaskGenerator."End Date"
        else
            EndDate := StartDate;

        // If no valid date range, skip
        if (StartDate = 0D) then
            exit;

        // Delete existing day planning lines for this job planning line
        if not DoDeleteAll then begin
            DayTasks.SetRange("Job No.", DayTaskGenerator."Job No.");
            DayTasks.SetRange("Job Task No.", DayTaskGenerator."Job Task No.");
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
                DayTasks."Job No." := DayTaskGenerator."Job No.";
                DayTasks."Job Task No." := DayTaskGenerator."Job Task No.";

                DayTasks."Task Date" := NewTaskDate;

                // Calculate start and end times for this day
                if DayTaskGenerator."Start Time" <> 0T then
                    DayStartTime := DayTaskGenerator."Start Time"
                else
                    DayStartTime := WorkHoursTemplate."Default Start Time";
                if DayTaskGenerator."End Time" <> 0T then
                    DayEndTime := DayTaskGenerator."End Time"
                else
                    DayEndTime := WorkHoursTemplate."Default End Time";
                if DayTaskGenerator."Non Working Minutes" <> 0 then
                    NonWorkingHours := DayTaskGenerator."Non Working Minutes"
                else
                    NonWorkingHours := WorkHoursTemplate."Non Working Minutes";

                DayTasks."Start Time" := DayStartTime;
                DayTasks."End Time" := DayEndTime;
                DayTasks.VALIDATE("Non Working Minutes", NonWorkingHours);

                // Calculate working hours
                DayTasks.CalculateWorkingHours();

                // Copy other fields from job planning line
                DayTasks.Type := DayTasks.Type::Resource;
                DayTasks."No." := DayTaskGenerator."Resource No.";
                DayTasks.CalculateWorkingHours();
                //DayTasks.Description := DayTaskGenerator.Description;
                //DayTasks."Unit of Measure Code" := JobTask."Unit of Measure Code";
                DayTasks.Skill := DayTaskGenerator.SkillsRequired;
                //DayTasks."Work Type Code" := JobTask."Work Type Code";
                DayTasks."Vendor No." := DayTaskGenerator."Vendor No.";
                //DayTasks.Depth := DayTaskGenerator.Depth;
                //DayTasks.IsBoor := DayTaskGenerator.Isboor;

                // Calculate quantity for this day (proportional distribution)
                DayTasks.Quantity := CalculateDayQuantity(DayTaskGenerator, NewTaskDate, StartDate, EndDate, DayStartTime, DayEndTime);
                if CheckMayChange(DayTasks) then
                    if DayTasks.Insert() then
                        Counter += 1;
                for n := 2 to DayTaskGenerator."Quantity of Lines" do begin
                    DayTasks."DayLineNo" := n * 10000;
                    if CheckMayChange(DayTasks) then
                        if DayTasks.Insert() then
                            Counter += 1;
                end;
            end;
            NewTaskDate := CalcDate('<+1D>', NewTaskDate);
        END;
        Message('%1 day planning lines created for Job %2, Task %3.', Counter, DayTaskGenerator."Job No.", DayTaskGenerator."Job Task No.");
    END;

    local procedure CheckMayChange(NewDayTask: Record "Day Tasks"): Boolean
    var
        daytask: Record "Day Tasks";
    begin
        if daytask.Get(NewDayTask."Day No.", NewDayTask.DayLineNo, NewDayTask."Job No.", NewDayTask."Job Task No.") then
            Exit(not daytask."Manual Modified");
        exit(true);

    end;

    local procedure CalculateDayQuantity(DayTaskGen: Record "Day Task Generator"; CurrentDate: Date; StartDate: Date; EndDate: Date; DayStartTime: Time; DayEndTime: Time): Decimal
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
        if DayTaskGen."Quantity of Lines" = 0 then
            exit(0);

        // Calculate total time span in seconds
        StartDateTime := CreateDateTime(StartDate, DayTaskGen."Start Time");
        if DayTaskGen."Start Date" <> 0D then
            EndDateTime := CreateDateTime(DayTaskGen."End Date", DayTaskGen."End Time")
        else
            EndDateTime := CreateDateTime(StartDate, DayTaskGen."End Time");

        TotalSeconds := EndDateTime - StartDateTime;

        // Calculate this day's time span in seconds
        DayStartDateTime := CreateDateTime(CurrentDate, DayStartTime);
        DayEndDateTime := CreateDateTime(CurrentDate, DayEndTime);
        DaySeconds := DayEndDateTime - DayStartDateTime;

        // If total time is zero, distribute equally
        //if TotalSeconds <= 0 then
        //    exit(JobTask.Quantity);

        // Calculate proportional quantity for this day
        //exit(Round(JobTask.Quantity * DaySeconds / TotalSeconds, 0.00001));
    end;

    local procedure ClearDayPlanningLines()
    var
        JobDayPlanningLine: Record "Day Task Generator";
    begin
        JobDayPlanningLine.DeleteAll();
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

    procedure GetDateRange(JobNo: Code[20]; var StartDate: Date; var EndDate: Date)
    begin
        GetDateRange(JobNo, '', StartDate, EndDate);
    end;

    procedure GetDateRange(JobNo: Code[20]; JobTaskNo: Code[20]; var StartDate: Date; var EndDate: Date)
    var
        DayTasks: Record "Day Tasks";
    begin
        StartDate := 0D;
        EndDate := 0D;
        DayTasks.SetRange("Job No.", JobNo);
        if JobTaskNo <> '' then
            DayTasks.SetRange("Job Task No.", JobTaskNo);
        if DayTasks.FindFirst() then
            StartDate := DayTasks."Task Date";
        if DayTasks.FindLast() then
            EndDate := DayTasks."Task Date";
    end;

}
