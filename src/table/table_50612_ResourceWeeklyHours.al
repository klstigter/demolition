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
        field(21; "Monday Requested Hours"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Monday Requested';
            DecimalPlaces = 0 : 2;
            BlankZero = true;
        }
        field(22; "Monday Assigned Hours"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Monday Assigned';
            DecimalPlaces = 0 : 2;
            BlankZero = true;
        }
        field(23; "Tuesday Requested Hours"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Tuesday Requested';
            DecimalPlaces = 0 : 2;
            BlankZero = true;
        }
        field(24; "Tuesday Assigned Hours"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Tuesday Assigned';
            DecimalPlaces = 0 : 2;
            BlankZero = true;
        }
        field(25; "Wednesday Requested Hours"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Wednesday Requested';
            DecimalPlaces = 0 : 2;
            BlankZero = true;
        }
        field(26; "Wednesday Assigned Hours"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Wednesday Assigned';
            DecimalPlaces = 0 : 2;
            BlankZero = true;
        }
        field(27; "Thursday Requested Hours"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Thursday Requested';
            DecimalPlaces = 0 : 2;
            BlankZero = true;
        }
        field(28; "Thursday Assigned Hours"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Thursday Assigned';
            DecimalPlaces = 0 : 2;
            BlankZero = true;
        }
        field(29; "Friday Requested Hours"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Friday Requested';
            DecimalPlaces = 0 : 2;
            BlankZero = true;
        }
        field(30; "Friday Assigned Hours"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Friday Assigned';
            DecimalPlaces = 0 : 2;
            BlankZero = true;
        }
        field(31; "Saturday Requested Hours"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Saturday Requested';
            DecimalPlaces = 0 : 2;
            BlankZero = true;
        }
        field(32; "Saturday Assigned Hours"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Saturday Assigned';
            DecimalPlaces = 0 : 2;
            BlankZero = true;
        }
        field(33; "Sunday Requested Hours"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Sunday Requested';
            DecimalPlaces = 0 : 2;
            BlankZero = true;
        }
        field(34; "Sunday Assigned Hours"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Sunday Assigned';
            DecimalPlaces = 0 : 2;
            BlankZero = true;
        }
        field(35; "Total Requested Hours"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Total Requested';
            DecimalPlaces = 0 : 2;
            BlankZero = true;
        }
        field(36; "Total Assigned Hours"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Total Assigned';
            DecimalPlaces = 0 : 2;
            BlankZero = true;
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
        DayIndex: Integer;
        YearValue: Integer;
        WeekNoValue: Integer;
        TaskDate: Date;
        WorkOrder: Record "Work Order";
    begin
        Reset();
        DeleteAll();

        if not DayPlanning.FindSet() then
            exit;

        // Two independent passes per record:
        //   Pass A – Requested Hours credited to the Requested Resource row.
        //   Pass B – Assigned Hours credited to the Assigned Resource row.
        // Rows are the union of all Requested and Assigned resource values.
        repeat
            TaskDate := DayPlanning."Task Date";
            if TaskDate = 0D then begin
                if WorkOrder.Get(DayPlanning."Work Order No.") then
                    TaskDate := WorkOrder."Placeholder Date";
            end;
            if TaskDate = 0D then
                continue;

            YearValue := Date2DWY(TaskDate, 3);
            WeekNoValue := Date2DWY(TaskDate, 2);
            DayIndex := GetDayOfWeekIndex(TaskDate);

            // Pass A: Requested Hours → Requested Resource row
            if not rec.Get(DayPlanning."Requested Resource No.", DayPlanning."Skill", DayPlanning."Job No.", DayPlanning."Job Task No.", YearValue, WeekNoValue) then begin
                rec.Init();
                rec."Resource No." := DayPlanning."Requested Resource No.";
                rec."Skill Code" := DayPlanning."Skill";
                rec."Job No." := DayPlanning."Job No.";
                rec."Job Task No." := DayPlanning."Job Task No.";
                rec."Week No." := WeekNoValue;
                rec.Year := YearValue;
                rec.Insert();
            end;
            AddReqHours(DayIndex, DayPlanning."Requested Hours");
            rec.Modify();

            // Pass B: Assigned Hours → Assigned Resource row
            if not rec.Get(DayPlanning."Assigned Resource No.", DayPlanning."Skill", DayPlanning."Job No.", DayPlanning."Job Task No.", YearValue, WeekNoValue) then begin
                rec.Init();
                rec."Resource No." := DayPlanning."Assigned Resource No.";
                rec."Skill Code" := DayPlanning."Skill";
                rec."Job No." := DayPlanning."Job No.";
                rec."Job Task No." := DayPlanning."Job Task No.";
                rec."Week No." := WeekNoValue;
                rec.Year := YearValue;
                rec.Insert();
            end;
            AddAssHours(DayIndex, DayPlanning."Assigned Hours");
            rec.Modify();

        until DayPlanning.Next() = 0;
    end;

    local procedure AddReqHours(DayIndex: Integer; Hours: Decimal)
    begin
        case DayIndex of
            1:
                begin
                    rec."Monday Requested Hours" += Hours;
                    rec."Monday Hours" += Hours;
                end;
            2:
                begin
                    rec."Tuesday Requested Hours" += Hours;
                    rec."Tuesday Hours" += Hours;
                end;
            3:
                begin
                    rec."Wednesday Requested Hours" += Hours;
                    rec."Wednesday Hours" += Hours;
                end;
            4:
                begin
                    rec."Thursday Requested Hours" += Hours;
                    rec."Thursday Hours" += Hours;
                end;
            5:
                begin
                    rec."Friday Requested Hours" += Hours;
                    rec."Friday Hours" += Hours;
                end;
            6:
                begin
                    rec."Saturday Requested Hours" += Hours;
                    rec."Saturday Hours" += Hours;
                end;
            7:
                begin
                    rec."Sunday Requested Hours" += Hours;
                    rec."Sunday Hours" += Hours;
                end;
        end;
        rec."Total Requested Hours" += Hours;
        rec."Total Week Hours" += Hours;
    end;

    local procedure AddAssHours(DayIndex: Integer; Hours: Decimal)
    begin
        case DayIndex of
            1:
                rec."Monday Assigned Hours" += Hours;
            2:
                rec."Tuesday Assigned Hours" += Hours;
            3:
                rec."Wednesday Assigned Hours" += Hours;
            4:
                rec."Thursday Assigned Hours" += Hours;
            5:
                rec."Friday Assigned Hours" += Hours;
            6:
                rec."Saturday Assigned Hours" += Hours;
            7:
                rec."Sunday Assigned Hours" += Hours;
        end;
        rec."Total Assigned Hours" += Hours;
        rec."Total Week Hours" += Hours;
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
                TryInsertTempResource(TempDayPlanning."Requested Resource No.");
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
