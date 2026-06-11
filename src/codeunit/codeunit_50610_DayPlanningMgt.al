codeunit 50610 "Day Plannings Mgt."
{
    var
        GeneralUtil: Codeunit "General Planning Utilities";
        WorkHoursTemplate: Record "Work-Hour Template";

    procedure CreateDayPlanning()
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
            //CreateDayPlanning(JobTask, false);
            until JobTask.Next() = 0;

        Message('Day planning lines have been successfully created.');
    end;

    procedure CreateDayPlanning(DayPlanningGenerator: Record "Day Planning Pattern")
    begin
        CreateDayPlanning(DayPlanningGenerator, true)
    end;

    local procedure CreateDayPlanning(DayPlanningGenerator: Record "Day Planning Pattern"; DoDeleteAll: Boolean)
    var
        JobTask: Record "Job Task";
        DayPlannings: Record "Day Planning";
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
        DayPlanningGenerator.TestField("Work-Hour Template");
        case true of
            (DayPlanninggenerator."Resource No." = '') and
            (DayPlanningGenerator.SkillsRequired = ''):
                error('Skills Required must be specified');
            DayPlanningGenerator."Work-Hour Template" = '':
                error('Work-Hour Template must be specified');
            DayPlanningGenerator."Start Date" = 0D:
                Error('Planned Start Date must be specified');
            DayPlanningGenerator."End Date" = 0D:
                Error('Planned End Date must be specified');
            (DayPlanningGenerator."Start Time" = 0T) or (DayPlanningGenerator."End Time" = 0T):
                Error('Start Time and End Time must be specified');
            (DayPlanningGenerator."Vendor No." <> ''):
                begin
                    DayPlanningGenerator."Quantity of Lines" := 1;
                    DayPlanningGenerator.Modify(false);
                end;
        end;
        //TODO: refactor?
        //if DayPlanningGenerator.StartEndLimitations(true) then
        //    exit;
        WorkHoursTemplate.get(DayPlanningGenerator."Work-Hour Template");
        // Get the start and end dates
        StartDate := DayPlanningGenerator."Start Date";
        if DayPlanningGenerator."End Date" <> 0D then
            EndDate := DayPlanningGenerator."End Date"
        else
            EndDate := StartDate;

        // If no valid date range, skip
        if (StartDate = 0D) then
            exit;

        // Delete existing day planning lines for this job planning line
        if not DoDeleteAll then begin
            DayPlannings.SetRange("Job No.", DayPlanningGenerator."Job No.");
            DayPlannings.SetRange("Job Task No.", DayPlanningGenerator."Job Task No.");
            DayPlannings.DeleteAll();
        end;
        // Create day planning lines for each day in the range
        NewTaskDate := StartDate;

        while NewTaskDate <= EndDate do begin
            // Check if this day is a working day in the template   
            if ExpectedWeekDay(DayPlanningGenerator, NewTaskDate, true) then begin

                Clear(DayPlannings);
                DayNo := GeneralUtil.DateToInteger(NewTaskDate);
                DayPlannings."Task Date" := NewTaskDate;
                DayPlannings."Day Line No." := DayPlannings.GetNextDayLineNo(NewTaskDate, DayPlanningGenerator."Job No.", DayPlanningGenerator."Job Task No.");
                DayPlannings."Job No." := DayPlanningGenerator."Job No.";
                DayPlannings."Job Task No." := DayPlanningGenerator."Job Task No.";
                DayPlannings."Work Order No." := DayPlanningGenerator."Work Order No.";

                // Calculate start and end times for this day
                if DayPlanningGenerator."Start Time" <> 0T then
                    DayStartTime := DayPlanningGenerator."Start Time"
                else
                    DayStartTime := WorkHoursTemplate."Default Start Time";
                if DayPlanningGenerator."End Time" <> 0T then
                    DayEndTime := DayPlanningGenerator."End Time"
                else
                    DayEndTime := WorkHoursTemplate."Default End Time";
                if DayPlanningGenerator."Non Working Minutes" <> 0 then
                    NonWorkingHours := DayPlanningGenerator."Non Working Minutes"
                else
                    NonWorkingHours := WorkHoursTemplate."Non Working Minutes";

                DayPlannings."Start Time Assigned" := DayStartTime;
                DayPlannings."End Time Assigned" := DayEndTime;
                DayPlannings."Start Time Requested" := DayStartTime;
                DayPlannings."End Time Requested" := DayEndTime;
                DayPlannings.VALIDATE("Non Working Minutes", NonWorkingHours);

                // Copy other fields from job planning line
                DayPlannings."Assigned Resource No." := DayPlanningGenerator."Resource No.";
                // Calculate working hours
                DayPlannings."Requested Hours" := DayPlanningGenerator."Requested Hours";

                //DayPlannings.Description := DayPlanningGenerator.Description;
                //DayPlannings."Unit of Measure Code" := JobTask."Unit of Measure Code";
                DayPlannings.Skill := DayPlanningGenerator.SkillsRequired;
                //DayPlannings."Work Type Code" := JobTask."Work Type Code";
                DayPlannings."Vendor No." := DayPlanningGenerator."Vendor No.";
                //DayPlannings.Depth := DayPlanningGenerator.Depth;
                //DayPlannings.IsBoor := DayPlanningGenerator.Isboor;

                // Calculate quantity for this day (proportional distribution)
                if CheckMayChange(DayPlannings) then
                    if DayPlannings.Insert(true) then
                        Counter += 1;
                for n := 2 to DayPlanningGenerator."Quantity of Lines" do begin
                    DayPlannings."Day Line No." := n * 10000;
                    if CheckMayChange(DayPlannings) then
                        if DayPlannings.Insert(true) then
                            Counter += 1;
                end;
            end;
            NewTaskDate := CalcDate('<+1D>', NewTaskDate);
        END;

        //Update Job Task Start - End Date
        JobTask.Get(DayPlanningGenerator."Job No.", DayPlanningGenerator."Job Task No.");
        DayPlannings.Reset();
        DayPlannings.SetCurrentKey("Task Date");
        DayPlannings.SetRange("Job No.", JobTask."Job No.");
        DayPlannings.SetRange("Job Task No.", JobTask."Job Task No.");
        if DayPlannings.FindFirst() then
            StartDate := DayPlannings."Task Date";
        if DayPlannings.FindLast() then
            EndDate := DayPlannings."Task Date";

        if (JobTask.PlannedStartDate = 0D) or (StartDate < JobTask.PlannedStartDate) then
            JobTask.PlannedStartDate := StartDate;
        if (JobTask.PlannedEndDate = 0D) or (EndDate > JobTask.PlannedEndDate) then
            JobTask.Validate(PlannedEndDate, EndDate);
        JobTask.Modify();

        Message('%1 day planning lines created for Job %2, Task %3.', Counter, DayPlanningGenerator."Job No.", DayPlanningGenerator."Job Task No.");
    END;

    local procedure CheckMayChange(NewDayPlanning: Record "Day Planning"): Boolean
    var
        DayPlanning: Record "Day Planning";
    begin
        if DayPlanning.Get(NewDayPlanning."Job No.", NewDayPlanning."Job Task No.", NewDayPlanning."Day Line No.") then
            Exit(not DayPlanning."Manual Modified");
        exit(true);

    end;


    local procedure ClearDayPlanningLines()
    var
        JobDayPlanningLine: Record "Day Planning Pattern";
    begin
        JobDayPlanningLine.DeleteAll();
    end;

    local procedure ExpectedWeekDay(DayPlanningGenerator: Record "Day Planning Pattern";
                                    NewTaskDate: Date;
                                    OffOnWeekEndAndPublicHoliday: Boolean): Boolean
    var
        OptimizerSetup: Record "Daily Optimizer Setup";
        BaseCalendar: Record "Base Calendar";
        CustomizedCalendarChange: Record "Customized Calendar Change";
        WeekDaysTemp: Record Integer Temporary;
        CalendarMgt: Codeunit "Calendar Management";
        DayOfWeek: Integer;
        ActiveWeekDay: Boolean;
        IsNonworkingDay: Boolean;
        Rtv: Boolean;
    begin
        OptimizerSetup.Get();
        OptimizerSetup.TestField("Base Calendar");

        GetWeekDaysFromDayPlanningGenerator(DayPlanningGenerator, WeekDaysTemp);

        BaseCalendar.Get(OptimizerSetup."Base Calendar");
        CalendarMgt.SetSource(BaseCalendar, CustomizedCalendarChange);

        DayOfWeek := Date2DWY(NewTaskDate, 1);
        ActiveWeekDay := true;
        if not WeekDaysTemp.IsEmpty() then
            ActiveWeekDay := WeekDaysTemp.Get(DayOfWeek);

        IsNonworkingDay := CalendarMgt.IsNonworkingDay(NewTaskDate, CustomizedCalendarChange);

        /*
        The truth table is now:
        ActiveWeekDay	OffOnWeekEndAndPublicHoliday	IsNonworkingDay	    Rtv
        false	        any	                            any	                false
        true	        false	                        any	                true
        true	        true	                        false	            true
        true	        true	                        true	            false
        - If the day-of-week isn't checked in the generator → skip it.
        - If the day is active but it's a calendar non-working day and we're honouring that flag → skip it.
        - Otherwise → create the task.
        */

        if not ActiveWeekDay then
            Rtv := false
        else if OffOnWeekEndAndPublicHoliday and IsNonworkingDay then
            Rtv := false
        else
            Rtv := true;

        exit(Rtv);
    end;

    local procedure GetWeekDaysFromDayPlanningGenerator(DayPlanningGenerator: Record "Day Planning Pattern"; var WeekDays: Record Integer Temporary)
    begin
        WeekDays.Reset();
        WeekDays.DeleteAll();
        if DayPlanningGenerator."Day 1" then begin
            WeekDays.Init();
            WeekDays.Number := 1;
            WeekDays.Insert();
        end;
        if DayPlanningGenerator."Day 2" then begin
            WeekDays.Init();
            WeekDays.Number := 2;
            WeekDays.Insert();
        end;
        if DayPlanningGenerator."Day 3" then begin
            WeekDays.Init();
            WeekDays.Number := 3;
            WeekDays.Insert();
        end;
        if DayPlanningGenerator."Day 4" then begin
            WeekDays.Init();
            WeekDays.Number := 4;
            WeekDays.Insert();
        end;
        if DayPlanningGenerator."Day 5" then begin
            WeekDays.Init();
            WeekDays.Number := 5;
            WeekDays.Insert();
        end;
        if DayPlanningGenerator."Day 6" then begin
            WeekDays.Init();
            WeekDays.Number := 6;
            WeekDays.Insert();
        end;
        if DayPlanningGenerator."Day 7" then begin
            WeekDays.Init();
            WeekDays.Number := 7;
            WeekDays.Insert();
        end;
    end;

    procedure GetDateRange(JobNo: Code[20]; var StartDate: Date; var EndDate: Date)
    begin
        GetDateRange(JobNo, '', StartDate, EndDate);
    end;

    procedure GetDateRange(JobNo: Code[20]; JobTaskNo: Code[20]; var StartDate: Date; var EndDate: Date)
    var
        DayPlannings: Record "Day Planning";
    begin
        StartDate := 0D;
        EndDate := 0D;
        DayPlannings.SetRange("Job No.", JobNo);
        if JobTaskNo <> '' then
            DayPlannings.SetRange("Job Task No.", JobTaskNo);
        if DayPlannings.FindFirst() then
            StartDate := DayPlannings."Task Date";
        if DayPlannings.FindLast() then
            EndDate := DayPlannings."Task Date";
    end;

}
