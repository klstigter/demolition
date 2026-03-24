table 50612 "Resource Weekly Hours"
{
    TableType = Temporary;
    Caption = 'Resource Weekly Hours';
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
    }

    keys
    {
        key(PK; "Resource No.", "skill code", "Job No.", "Job Task No.", Year, "Week No.")
        {
            Clustered = true;
        }
    }

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

    procedure FillBuffer(JobNo: Code[20]; JobTaskNo: Code[20])
    begin
        FillBuffer('', JobNo, JobTaskNo);
    end;

    procedure FillBuffer(ResourceNo: Code[20]; JobNo: Code[20]; JobTaskNo: Code[20])
    var
        DayTask: Record "Day Tasks";
        TempWeekList: Record "Resource Weekly Hours" temporary;
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
        if ResourceNo <> '' then
            DayTask.SetRange("No.", ResourceNo);
        DayTask.SetRange("Job No.", JobNo);
        DayTask.SetRange("Job Task No.", JobTaskNo);

        if not DayTask.FindSet() then
            exit;

        // Group by week and distribute hours to weekdays
        repeat
            YearValue := Date2DWY(DayTask."Task Date", 3);
            WeekNoValue := Date2DWY(DayTask."Task Date", 2);
            DayIndex := GetDayOfWeekIndex(DayTask."Task Date");
            ResourceNo := DayTask."No.";
            if (DayTask."Requested Hours" > DayTask."Assigned Hours") and (DayTask."Assigned Hours" <> 0) then
                n := 2
            else
                n := 1;

            for i := 1 to n do begin
                if i = 2 then
                    DoInsert := Not TempWeekList.Get('', DayTask."Skill", DayTask."Job No.", DayTask."Job Task No.", YearValue, WeekNoValue)
                else
                    DoInsert := not TempWeekList.Get(DayTask."No.", DayTask."Skill", DayTask."Job No.", DayTask."Job Task No.", YearValue, WeekNoValue);
                if DoInsert then begin
                    // Create new week record
                    TempWeekList.Init();
                    if i = 1 then
                        TempWeekList."Resource No." := DayTask."No."
                    else
                        TempWeekList."Resource No." := '';
                    TempWeekList."Skill Code" := DayTask."Skill";
                    TempWeekList."Job No." := DayTask."Job No.";
                    TempWeekList."Job Task No." := DayTask."Job Task No.";
                    TempWeekList."Week No." := WeekNoValue;
                    TempWeekList.Year := YearValue;

                    TempWeekList."Total Week Hours" := GetHours(DayIndex, DayTask, TempWeekList);
                    TempWeekList.Insert();
                end else begin
                    // Update existing week record
                    TempWeekList."Total Week Hours" += GetHours(DayIndex, DayTask, TempWeekList);
                    TempWeekList.Modify();
                end;
            end;
        until DayTask.Next() = 0;

        // Copy from temp to Rec
        TempWeekList.Reset();
        if TempWeekList.FindSet() then
            repeat
                Rec := TempWeekList;
                Insert();
            until TempWeekList.Next() = 0;
    end;

    Local Procedure GetHours(DayIndex: Integer; DayTask: Record "Day Tasks"; var TempWeekList: Record "Resource Weekly Hours") Hours: Integer
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
}
