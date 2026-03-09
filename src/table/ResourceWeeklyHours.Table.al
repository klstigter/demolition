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
        field(2; "Job No."; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Job No.';
            TableRelation = Job;
        }
        field(3; "Job Task No."; Code[20])
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
        key(PK; "Resource No.", "Job No.", "Job Task No.", Year, "Week No.")
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

            if not TempWeekList.Get(ResourceNo, JobNo, JobTaskNo, YearValue, WeekNoValue) then begin
                // Create new week record
                TempWeekList.Init();
                TempWeekList."Resource No." := ResourceNo;
                TempWeekList."Job No." := JobNo;
                TempWeekList."Job Task No." := JobTaskNo;
                TempWeekList."Week No." := WeekNoValue;
                TempWeekList.Year := YearValue;

                // Initialize all day hours to 0
                TempWeekList."Monday Hours" := 0;
                TempWeekList."Tuesday Hours" := 0;
                TempWeekList."Wednesday Hours" := 0;
                TempWeekList."Thursday Hours" := 0;
                TempWeekList."Friday Hours" := 0;
                TempWeekList."Saturday Hours" := 0;
                TempWeekList."Sunday Hours" := 0;
                TempWeekList."Total Week Hours" := 0;

                // Add hours to appropriate day
                case DayIndex of
                    1:
                        TempWeekList."Monday Hours" := DayTask."Working Hours";
                    2:
                        TempWeekList."Tuesday Hours" := DayTask."Working Hours";
                    3:
                        TempWeekList."Wednesday Hours" := DayTask."Working Hours";
                    4:
                        TempWeekList."Thursday Hours" := DayTask."Working Hours";
                    5:
                        TempWeekList."Friday Hours" := DayTask."Working Hours";
                    6:
                        TempWeekList."Saturday Hours" := DayTask."Working Hours";
                    7:
                        TempWeekList."Sunday Hours" := DayTask."Working Hours";
                end;
                TempWeekList."Total Week Hours" := DayTask."Working Hours";
                TempWeekList.Insert();
            end else begin
                // Update existing week record
                case DayIndex of
                    1:
                        TempWeekList."Monday Hours" += DayTask."Working Hours";
                    2:
                        TempWeekList."Tuesday Hours" += DayTask."Working Hours";
                    3:
                        TempWeekList."Wednesday Hours" += DayTask."Working Hours";
                    4:
                        TempWeekList."Thursday Hours" += DayTask."Working Hours";
                    5:
                        TempWeekList."Friday Hours" += DayTask."Working Hours";
                    6:
                        TempWeekList."Saturday Hours" += DayTask."Working Hours";
                    7:
                        TempWeekList."Sunday Hours" += DayTask."Working Hours";
                end;
                TempWeekList."Total Week Hours" += DayTask."Working Hours";
                TempWeekList.Modify();
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
}
