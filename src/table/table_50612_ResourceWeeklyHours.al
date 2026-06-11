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



    /// <summary>
    /// Extracts the year and ISO week number from an Integer in YYYYWW format.
    /// </summary>
    /// <param name="InputInteger">Integer in YYYYWW format</param>
    /// <param name="Year">Extracted year value</param>
    /// <param name="WeekNo">Extracted week number value</param>
    procedure ExtractYearAndWeek(InputInteger: Integer; var Year: Integer; var WeekNo: Integer)
    begin
        if InputInteger = 0 then begin
            Year := 0;
            WeekNo := 0;
            exit;
        end;

        Year := InputInteger div 100;
        WeekNo := InputInteger mod 100;
    end;


    procedure FillSummaryWithJobFilter(JobNoFilter: Text)
    var
        DayPlanning: Record "Day Planning";
    begin
        if JobNoFilter <> '' then
            DayPlanning.SetFilter("Job No.", JobNoFilter);
        FillSummary(DayPlanning);
    end;

    procedure FillSummaryWithJobTaskFilter(JobNoFilter: Text; JobTaskNoFilter: Text)
    var
        DayPlanning: Record "Day Planning";
    begin
        if JobNoFilter <> '' then
            DayPlanning.SetFilter("Job No.", JobNoFilter);
        if JobTaskNoFilter <> '' then
            DayPlanning.SetFilter("Job Task No.", JobTaskNoFilter);
        FillSummary(DayPlanning);
    end;

    procedure FillSummaryWithResourceFilter(ResourceNoFilter: Text)
    var
        DayPlanning: Record "Day Planning";
    begin
        if ResourceNoFilter <> '' then
            DayPlanning.SetFilter("Assigned Resource No.", ResourceNoFilter);
        FillSummary(DayPlanning);
    end;

    procedure FillSummary(JobNo: Code[20]; JobTaskNo: Code[20])
    var
        DayPlanning: Record "Day Planning";
    begin
        DayPlanning.SetRange("Job No.", JobNo);
        DayPlanning.SetRange("Job Task No.", JobTaskNo);
        FillSummary(DayPlanning);
    end;

    procedure FillSummary(ResourceNo: Code[20]; JobNo: Code[20]; JobTaskNo: Code[20])
    var
        DayPlanning: Record "Day Planning";
    begin
        if ResourceNo <> '' then
            DayPlanning.SetRange("Assigned Resource No.", ResourceNo);
        DayPlanning.SetRange("Job No.", JobNo);
        DayPlanning.SetRange("Job Task No.", JobTaskNo);
        FillSummary(DayPlanning);
    end;

    Local procedure FillSummary(var DayPlanning: Record "Day Planning")
    var
        //TempWeekList: Record "Summary Weekly" temporary;
        DayIndex: Integer;
        YearValue: Integer;
        WeekNoValue: Integer;
        i, n : integer;
        DoInsert: Boolean;
        TaskDate: Date;
        WorkOrder: Record "Work Order";
    begin
        // Clear existing records
        Reset();
        DeleteAll();

        // Find all Day Plannings for this Resource/Job/Task
        DayPlanning.Reset();
        if not DayPlanning.FindSet() then
            exit;

        // Group by week and distribute hours to weekdays
        repeat
            TaskDate := DayPlanning."Task Date";
            if TaskDate = 0D Then Begin
                if WorkOrder.Get(DayPlanning."Work Order No.") then
                    TaskDate := WorkOrder."Placeholder Date";
            End;
            if TaskDate = 0D then
                continue;

            YearValue := Date2DWY(TaskDate, 3);
            WeekNoValue := Date2DWY(TaskDate, 2);
            DayIndex := GetDayOfWeekIndex(TaskDate);
            //if (DayPlanning."Requested Hours" > DayPlanning."Assigned Hours") and (DayPlanning."Assigned Hours" <> 0) then
            //    n := 2
            //else
            n := 1;

            for i := 1 to n do begin
                if i = 2 then
                    DoInsert := Not rec.Get('', DayPlanning."Skill", DayPlanning."Job No.", DayPlanning."Job Task No.", YearValue, WeekNoValue)
                else
                    DoInsert := not rec.Get(DayPlanning."Assigned Resource No.", DayPlanning."Skill", DayPlanning."Job No.", DayPlanning."Job Task No.", YearValue, WeekNoValue);
                if DoInsert then begin
                    // Create new week record
                    rec.Init();
                    if i = 1 then
                        rec."Resource No." := DayPlanning."Assigned Resource No."
                    else
                        rec."Resource No." := '';
                    rec."Skill Code" := DayPlanning."Skill";
                    rec."Job No." := DayPlanning."Job No.";
                    rec."Job Task No." := DayPlanning."Job Task No.";
                    rec."Week No." := WeekNoValue;
                    rec.Year := YearValue;

                    rec."Total Week Hours" := GetHours(DayIndex, DayPlanning, rec);
                    rec.Insert();
                end else begin
                    // Update existing week record
                    rec."Total Week Hours" += GetHours(DayIndex, DayPlanning, rec);
                    rec.Modify();
                end;
            end;

        until DayPlanning.Next() = 0;
        n := TempDayPlanning.Count;
        // // Copy from temp to Rec
        // TempWeekList.Reset();
        // if TempWeekList.FindSet() then
        //     repeat
        //         Rec := TempWeekList;
        //         Insert();
        //     until TempWeekList.Next() = 0;
    end;

    Local Procedure GetHours(DayIndex: Integer; DayPlanning: Record "Day Planning"; var TempWeekList: Record "Summary Weekly") Hours: Integer
    begin
        if (TempWeekList."Resource No." = '') then begin
            case DayIndex of
                1:
                    TempWeekList."Monday Hours" += DayPlanning."Requested Hours";
                2:
                    TempWeekList."Tuesday Hours" += DayPlanning."Requested Hours";
                3:
                    TempWeekList."Wednesday Hours" += DayPlanning."Requested Hours";
                4:
                    TempWeekList."Thursday Hours" += DayPlanning."Requested Hours";
                5:
                    TempWeekList."Friday Hours" += DayPlanning."Requested Hours";
                6:
                    TempWeekList."Saturday Hours" += DayPlanning."Requested Hours";
                7:
                    TempWeekList."Sunday Hours" += DayPlanning."Requested Hours";
            end;
            exit(DayPlanning."Requested Hours");
        end else begin
            case DayIndex of
                1:
                    TempWeekList."Monday Hours" += DayPlanning."Assigned Hours";
                2:
                    TempWeekList."Tuesday Hours" += DayPlanning."Assigned Hours";
                3:
                    TempWeekList."Wednesday Hours" += DayPlanning."Assigned Hours";
                4:
                    TempWeekList."Thursday Hours" += DayPlanning."Assigned Hours";
                5:
                    TempWeekList."Friday Hours" += DayPlanning."Assigned Hours";
                6:
                    TempWeekList."Saturday Hours" += DayPlanning."Assigned Hours";
                7:
                    TempWeekList."Sunday Hours" += DayPlanning."Assigned Hours";
            end;
            exit(DayPlanning."Assigned Hours");
        end;

    end;
    #endregion
    var
        TempDayPlanning: Record "Day Planning" temporary;
        TempTask: Record "Job Task" temporary;
        TempJob: Record Job temporary;
        TEMPResource: Record "Resource" temporary;
        TempSkill: Record "Skill Code" temporary;
        TempYearWeek: Record Integer temporary;
        TempSummaryWeekly: Record "Summary Weekly" temporary;

    #region "Helper functions to scan Day Plannings and fill temp buffers"

    procedure ScanDayPlanningDateFilter(DateFilter: text)
    var
        DayPlanning: Record "Day Planning";
    begin
        if DateFilter <> '' then
            DayPlanning.SetFilter("Task Date", DateFilter);
        ScanTEMPDayPlanning(DayPlanning)
    end;

    procedure ScanDayPlanningFilter(JobNoFilter: text; TaskNoFilter: text)
    var
        DayPlanning: Record "Day Planning";
    begin
        if JobNoFilter <> '' then
            DayPlanning.SetFilter("Job No.", JobNoFilter);
        if TaskNoFilter <> '' then
            DayPlanning.SetFilter("Job Task No.", TaskNoFilter);
        ScanTempDayPlanning(DayPlanning)
    end;

    procedure ScanDayPlanningResource(ResourceFilter: text)
    var
        DayPlanning: Record "Day Planning";
    begin
        if ResourceFilter <> '' then
            DayPlanning.SetFilter("Assigned Resource No.", ResourceFilter);
        ScanTEMPDayPlanning(DayPlanning)
    end;

    procedure ScanDayPlanningSkill(SkillFilter: text)
    var
        DayPlanning: Record "Day Planning";
    begin
        if SkillFilter <> '' then
            DayPlanning.SetFilter("Skill", SkillFilter);
        ScanTEMPDayPlanning(DayPlanning)
    end;

    local procedure ScanTempDayPlanning(var DayPlanning: Record "Day Planning")
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
        TempDayPlanning.reset;
        TempDayPlanning.DeleteAll();

        if DayPlanning.FindSet() then
            repeat
                TempDayPlanning := DayPlanning;
                TempDayPlanning.Insert(true);
                if DateOld <> TempDayPlanning."Task Date" then begin
                    DateOld := TempDayPlanning."Task Date";
                    ywNew := CreateYW(TempDayPlanning."Task Date");
                    if ywOld <> ywNew then begin
                        ywOld := ywNew;
                        FillTEMPYearWeek(ywNew);
                    end;
                end;
                if (JobNoOld <> TempDayPlanning."Job No.") then begin
                    JobNoOld := TempDayPlanning."Job No.";
                    JobTaskNoOld := '';
                    TryInsertJob(TempDayPlanning."Job No.");
                end;
                if (JobTaskNoOld <> TempDayPlanning."Job Task No.") then begin
                    JobTaskNoOld := TempDayPlanning."Job Task No.";
                    TryInsertTempTask(TempDayPlanning."Job No.", TempDayPlanning."Job Task No.");
                end;
                TryInsertTempResource(TempDayPlanning."Assigned Resource No.");
                if (SkillOld <> TempDayPlanning."Skill") then begin
                    SkillOld := TempDayPlanning."Skill";
                    TryInsertTempSkill(TempDayPlanning."Skill");
                end;
            until DayPlanning.Next() = 0;
        n := TempDayPlanning.Count;
    end;


    local procedure FillTEMPYearWeek(TaskDate: Date)
    begin
        FillTEMPYearWeek(CreateYW(TempDayPlanning."Task Date"));
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
        n := TempDayPlanning.Count;
        FillSummary(TempDayPlanning);
    end;

    procedure LoadSummary(var TempDTask: Record "Day Planning")
    begin
        FillSummary(TempDTask);
    end;


    procedure HandOverTempDayPlanning(var DayPlanning: Record "Day Planning" temporary)
    begin
        if TempDayPlanning.FindSet() then
            repeat
                DayPlanning := TempDayPlanning;
                DayPlanning.Insert(true);
            until TempDayPlanning.Next() = 0;
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

    procedure HandOverToPage(var Pg: Page "Week View")
    begin
        Pg.SetTempYearWeek(TempYearWeek);
    end;






}
