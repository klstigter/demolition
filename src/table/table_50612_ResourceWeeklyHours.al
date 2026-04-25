table 50612 "Summary Weekly"
{
    TableType = Temporary;
    Caption = 'Summary Weekly';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Resource No."; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Resource No.';
            TableRelation = Resource;

        }
        field(2; "Skill Code"; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Skill Code';
            TableRelation = "Skill Code";
        }
        field(3; "Job No."; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Job No.';
            TableRelation = Job;
        }
        field(4; "Job Task No."; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Job Task No.';
            TableRelation = "Job Task"."Job Task No." where("Job No." = field("Job No."));
        }
        field(5; Year; Integer)
        {
            DataClassification = ToBeClassified;
            Caption = 'Year';
        }
        field(6; "Week No."; Integer)
        {
            DataClassification = ToBeClassified;
            Caption = 'Week No.';
        }
        field(8; "Monday Hours"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Monday';
            DecimalPlaces = 0 : 2;
            BlankZero = true;
        }
        field(9; "Tuesday Hours"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Tuesday';
            DecimalPlaces = 0 : 2;
            BlankZero = true;
        }
        field(10; "Wednesday Hours"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Wednesday';
            DecimalPlaces = 0 : 2;
            BlankZero = true;
        }
        field(11; "Thursday Hours"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Thursday';
            DecimalPlaces = 0 : 2;
            BlankZero = true;
        }
        field(12; "Friday Hours"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Friday';
            DecimalPlaces = 0 : 2;
            BlankZero = true;
        }
        field(13; "Saturday Hours"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Saturday';
            DecimalPlaces = 0 : 2;
            BlankZero = true;
        }
        field(14; "Sunday Hours"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Sunday';
            DecimalPlaces = 0 : 2;
            BlankZero = true;
        }
        field(15; "Total Week Hours"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Total';
            DecimalPlaces = 0 : 2;
            BlankZero = true;
        }
        Field(20; Purpose; Integer)
        {
            DataClassification = ToBeClassified;

        }
    }

    keys
    {
        key(PK; "Resource No.", "Skill Code", "Job No.", "Job Task No.", Year, "Week No.")
        {
            Clustered = true;
        }
    }
    #region "Functions to fill the buffer"
    local procedure GetDayOfWeekIndex(TaskDate: Date): Integer
    begin
        // Returns 1-7 (Monday=1, Sunday=7)
        exit(Date2DWY(TaskDate, 1));
    end;

    local procedure GetWeekStartFromYearWeek(YearValue: Integer; WeekNo: Integer): Date
    var
        Jan4: Date;
        Week1Monday: Date;
    begin
        // ISO 8601: Week 1 is the week with Jan 4th
        Jan4 := DMY2Date(4, 1, YearValue);
        Week1Monday := CalcDate(StrSubstNo('<-%1D>', Date2DWY(Jan4, 1) - 1), Jan4);
        exit(CalcDate(StrSubstNo('<+%1W>', WeekNo - 1), Week1Monday));
    end;


    procedure FillSummaryWithJobFilter(JobNoFilter: Text)
    var
        DayTask: Record "Day Tasks";
    begin
        if JobNoFilter <> '' then
            DayTask.SetFilter("Job No.", JobNoFilter);
        FillSummary(DayTask);
    end;

    procedure FillSummaryWithJobTaskFilter(JobNoFilter: Text; JobTaskNoFilter: Text)
    var
        DayTask: Record "Day Tasks";
    begin
        if JobNoFilter <> '' then
            DayTask.SetFilter("Job No.", JobNoFilter);
        if JobTaskNoFilter <> '' then
            DayTask.SetFilter("Job Task No.", JobTaskNoFilter);
        FillSummary(DayTask);
    end;

    procedure FillSummaryWithResourceFilter(ResourceNoFilter: Text)
    var
        DayTask: Record "Day Tasks";
    begin
        if ResourceNoFilter <> '' then
            DayTask.SetFilter("No.", ResourceNoFilter);
        FillSummary(DayTask);
    end;

    procedure FillSummary(JobNo: Code[20]; JobTaskNo: Code[20])
    var
        DayTask: Record "Day Tasks";
    begin
        DayTask.SetRange("Job No.", JobNo);
        DayTask.SetRange("Job Task No.", JobTaskNo);
        FillSummary(DayTask);
    end;

    procedure FillSummary(ResourceNo: Code[20]; JobNo: Code[20]; JobTaskNo: Code[20])
    var
        DayTask: Record "Day Tasks";
    begin
        if ResourceNo <> '' then
            DayTask.SetRange("No.", ResourceNo);
        DayTask.SetRange("Job No.", JobNo);
        DayTask.SetRange("Job Task No.", JobTaskNo);
        FillSummary(DayTask);
    end;

    Local procedure FillSummary(var DayTask: Record "Day Tasks")
    var
        //TempWeekList: Record "Summary Weekly" temporary;
        DayIndex: Integer;
        YearValue: Integer;
        WeekNoValue: Integer;
        i, n : integer;
        DoInsert: Boolean;
    begin
        // Clear existing records
        Reset();
        DeleteAll();

        // Find all Day Tasks for this Resource/Job/Task
        DayTask.Reset();
        if not DayTask.FindSet() then
            exit;

        // Group by week and distribute hours to weekdays
        repeat
            YearValue := Date2DWY(DayTask."Task Date", 3);
            WeekNoValue := Date2DWY(DayTask."Task Date", 2);
            DayIndex := GetDayOfWeekIndex(DayTask."Task Date");
            //if (DayTask."Requested Hours" > DayTask."Assigned Hours") and (DayTask."Assigned Hours" <> 0) then
            //    n := 2
            //else
            n := 1;

            for i := 1 to n do begin
                if i = 2 then
                    DoInsert := Not rec.Get('', DayTask."Skill", DayTask."Job No.", DayTask."Job Task No.", YearValue, WeekNoValue)
                else
                    DoInsert := not rec.Get(DayTask."No.", DayTask."Skill", DayTask."Job No.", DayTask."Job Task No.", YearValue, WeekNoValue);
                if DoInsert then begin
                    // Create new week record
                    rec.Init();
                    if i = 1 then
                        rec."Resource No." := DayTask."No."
                    else
                        rec."Resource No." := '';
                    rec."Skill Code" := DayTask."Skill";
                    rec."Job No." := DayTask."Job No.";
                    rec."Job Task No." := DayTask."Job Task No.";
                    rec."Week No." := WeekNoValue;
                    rec.Year := YearValue;

                    rec."Total Week Hours" := GetHours(DayIndex, DayTask, rec);
                    rec.Insert();
                end else begin
                    // Update existing week record
                    rec."Total Week Hours" += GetHours(DayIndex, DayTask, rec);
                    rec.Modify();
                end;
            end;

        until DayTask.Next() = 0;
        n := TempDayTask.Count;
        // // Copy from temp to Rec
        // TempWeekList.Reset();
        // if TempWeekList.FindSet() then
        //     repeat
        //         Rec := TempWeekList;
        //         Insert();
        //     until TempWeekList.Next() = 0;
    end;

    Local Procedure GetHours(DayIndex: Integer; DayTask: Record "Day Tasks"; var TempWeekList: Record "Summary Weekly") Hours: Integer
    begin
        if TempWeekList."Resource No." = '' then begin
            case DayIndex of
                1:
                    TempWeekList."Monday Hours" := DayTask."Requested Hours" - DayTask."Assigned Hours";
                2:
                    TempWeekList."Tuesday Hours" := DayTask."Requested Hours" - DayTask."Assigned Hours";
                3:
                    TempWeekList."Wednesday Hours" := DayTask."Requested Hours" - DayTask."Assigned Hours";
                4:
                    TempWeekList."Thursday Hours" := DayTask."Requested Hours" - DayTask."Assigned Hours";
                5:
                    TempWeekList."Friday Hours" := DayTask."Requested Hours" - DayTask."Assigned Hours";
                6:
                    TempWeekList."Saturday Hours" := DayTask."Requested Hours" - DayTask."Assigned Hours";
                7:
                    TempWeekList."Sunday Hours" := DayTask."Requested Hours" - DayTask."Assigned Hours";
            end;
            exit(DayTask."Requested Hours" - DayTask."Assigned Hours");
        end else begin
            case DayIndex of
                1:
                    TempWeekList."Monday Hours" := DayTask."Assigned Hours";
                2:
                    TempWeekList."Tuesday Hours" := DayTask."Assigned Hours";
                3:
                    TempWeekList."Wednesday Hours" := DayTask."Assigned Hours";
                4:
                    TempWeekList."Thursday Hours" := DayTask."Assigned Hours";
                5:
                    TempWeekList."Friday Hours" := DayTask."Assigned Hours";
                6:
                    TempWeekList."Saturday Hours" := DayTask."Assigned Hours";
                7:
                    TempWeekList."Sunday Hours" := DayTask."Assigned Hours";
            end;
            exit(DayTask."Assigned Hours");
        end;

    end;
    #endregion
    var
        TempDayTask: Record "Day Tasks" temporary;
        TempTask: Record "Job Task" temporary;
        TempJob: Record Job temporary;
        TEMPResource: Record "Resource" temporary;
        TempSkill: Record "Skill Code" temporary;
        TempYearWeek: Record Integer temporary;
        TempSummaryWeekly: Record "Summary Weekly" temporary;

    #region "Helper functions to scan Day Tasks and fill temp buffers"

    procedure ScanDayTaskDateFilter(DateFilter: text)
    var
        DayTask: Record "Day Tasks";
    begin
        if DateFilter <> '' then
            DayTask.SetFilter("Task Date", DateFilter);
        ScanTEMPDayTask(DayTask)
    end;

    procedure ScanDayTaskFilter(JobNoFilter: text; TaskNoFilter: text)
    var
        DayTask: Record "Day Tasks";
    begin
        if JobNoFilter <> '' then
            DayTask.SetFilter("Job No.", JobNoFilter);
        if TaskNoFilter <> '' then
            DayTask.SetFilter("Job Task No.", TaskNoFilter);
        ScanTempDayTask(DayTask)
    end;

    procedure ScanDayTaskResource(ResourceFilter: text)
    var
        DayTask: Record "Day Tasks";
    begin
        if ResourceFilter <> '' then
            DayTask.SetFilter("No.", ResourceFilter);
        ScanTEMPDayTask(DayTask)
    end;

    procedure ScanDayTaskSkill(SkillFilter: text)
    var
        DayTask: Record "Day Tasks";
    begin
        if SkillFilter <> '' then
            DayTask.SetFilter("Skill", SkillFilter);
        ScanTEMPDayTask(DayTask)
    end;

    local procedure ScanTempDayTask(var DayTask: Record "Day Tasks")
    var
        DateOld: Date;
        ywOld: Integer;
        ywNew: Integer;
        JobNoOld: Code[20];
        JobTaskNoOld: Code[20];
        SkillOld: Code[20];
        n: Integer;
    begin
        TempYearWeek.Reset();
        TempYearWeek.DeleteAll();

        if DayTask.FindSet() then
            repeat
                TempDayTask := DayTask;
                TempDayTask.Insert();
                if DateOld <> TempDayTask."Task Date" then begin
                    DateOld := TempDayTask."Task Date";
                    ywNew := CreateYW(TempDayTask."Task Date");
                    if ywOld <> ywNew then begin
                        ywOld := ywNew;
                        FillTEMPYearWeek(ywNew);
                    end;
                end;
                if (JobNoOld <> TempDayTask."Job No.") then begin
                    JobNoOld := TempDayTask."Job No.";
                    JobTaskNoOld := '';
                    TryInsertJob(TempDayTask."Job No.");
                end;
                if (JobTaskNoOld <> TempDayTask."Job Task No.") then begin
                    JobTaskNoOld := TempDayTask."Job Task No.";
                    TryInsertTempTask(TempDayTask."Job No.", TempDayTask."Job Task No.");
                end;
                TryInsertTempResource(TempDayTask."No.");
                if (SkillOld <> TempDayTask."Skill") then begin
                    SkillOld := TempDayTask."Skill";
                    TryInsertTempSkill(TempDayTask."Skill");
                end;
            until DayTask.Next() = 0;
        n := TempDayTask.Count;
    end;


    local procedure FillTEMPYearWeek(TaskDate: Date)
    begin
        FillTEMPYearWeek(CreateYW(TempDayTask."Task Date"));
    end;

    local procedure FillTEMPYearWeek(yw: Integer)
    begin
        if yw <= 0 then
            exit;
        TempYearWeek.Reset();
        if not TempYearWeek.Get(yw) then begin
            TempYearWeek.Init();
            TempYearWeek.Number := yw;
            TempYearWeek.Insert();
        end;
        TempYearWeek.Reset();
    end;

    local procedure CreateYW(TaskDate: Date): Integer
    var
        y: Integer;
        w: Integer;
    begin
        if TaskDate = 0D then
            exit(0);

        y := Date2DWY(TaskDate, 3);
        w := Date2DWY(TaskDate, 2);
        exit((y * 100) + w);
    end;

    local procedure TryInsertTempResource(No: Code[20])
    var
        Resource: Record "Resource";
    begin
        if No = '' then
            exit;
        if TEMPResource.Get(No) then
            exit;
        if Resource.Get(No) then begin
            TEMPResource.Copy(Resource);
            TEMPResource.Insert();
        end;
    end;

    local procedure TryInsertTempSkill(Code: Code[20])
    var
        Skill: Record "Skill Code";
    begin
        if Code = '' then
            exit;
        if TempSkill.Get(Code) then
            exit;
        if Skill.Get(Code) then begin
            TempSkill.Copy(Skill);
            TempSkill.Insert();
        end;
    end;

    local procedure TryInsertTempTask(JobNo: Code[20]; No: Code[20])
    var
        Task: Record "Job Task";
    begin
        if No = '' then
            exit;
        if TempTask.Get(JobNo, No) then
            exit;
        if Task.Get(JobNo, No) then begin
            TempTask.Copy(Task);
            TempTask.Insert();
        end;
    end;

    local procedure TryInsertJob(JobNo: Code[20])
    var
        Job: Record Job;
    begin
        if JobNo = '' then
            exit;
        if TempJob.Get(JobNo) then
            exit;
        if Job.Get(JobNo) then begin
            TempJob.Copy(Job);
            TempJob.Insert();
        end;
    end;
    #endregion

    procedure LoadSummary()
    var
        n: Integer;
    begin
        n := TempDayTask.Count;
        FillSummary(TempDayTask); // Copy from temp to Rec
    end;

    procedure LoadSummary(var TempDTask: Record "Day Tasks")
    begin
        FillSummary(TempDTask); // Copy from temp to Rec
    end;


    procedure HandOverTempDayTask(var DayTask: Record "Day Tasks" temporary)
    begin
        if TempDayTask.FindSet() then
            repeat
                DayTask := TempDayTask;
                DayTask.Insert();
            until TempDayTask.Next() = 0;
    end;

    procedure HandOverToPage(Pg: Page "Opti Lookup Job List")
    begin
        PG.SetTempJobs(TempJob);
    end;

    procedure HandOverToPage(Pg: Page "Opti Job Task List TEMP")
    begin
        pg.SetTempJobTasks(TempTask);
    end;

    procedure HandOverToPage(var Pg: Page "Opti Resource List Temp")
    begin
        Pg.SetTempResource(TEMPResource);
    end;

    procedure HandOverToPage(var Pg: Page "Opti Skill Codes")
    begin
        Pg.SetTempSkill(TempSkill);
    end;

}
