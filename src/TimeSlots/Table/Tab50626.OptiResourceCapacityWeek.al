table 50626 "Opti Resource Capacity Week"
{
    Caption = 'Resource Capacity Week';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Resource No."; Code[20])
        {
            Caption = 'Resource No.';
            TableRelation = Resource."No.";
        }

        field(2; "Week Start Date"; Date)
        {
            Caption = 'Week Start Date';
        }

        field(3; "Week End Date"; Date)
        {
            Caption = 'Week End Date';
            Editable = false;
        }
        field(4; "Week No."; Integer)
        {
            Caption = 'Week No.';
            Editable = false;
        }

        field(5; "Week Year"; Integer)
        {
            Caption = 'Week Year';
            Editable = false;
        }
        field(6; "Effective Pattern Hash"; Text[64])
        {
            Caption = 'Effective Pattern Hash';
            Editable = false;
        }
        field(7; "Source Week Pattern ID"; Integer)
        {
            Caption = 'Source Week Pattern ID';
            TableRelation = "Opti Week Pattern Header"."Week Pattern ID";
            Editable = false;
        }
        field(8; "Source Week Pattern Hash"; Text[64])
        {
            Caption = 'Source Week Pattern Hash';
            Editable = false;
        }

        field(10; "Monday Date"; Date)
        {
            Caption = 'Monday Date';
            Editable = false;
        }

        field(11; "Tuesday Date"; Date)
        {
            Caption = 'Tuesday Date';
            Editable = false;
        }

        field(12; "Wednesday Date"; Date)
        {
            Caption = 'Wednesday Date';
            Editable = false;
        }

        field(13; "Thursday Date"; Date)
        {
            Caption = 'Thursday Date';
            Editable = false;
        }

        field(14; "Friday Date"; Date)
        {
            Caption = 'Friday Date';
            Editable = false;
        }

        field(15; "Saturday Date"; Date)
        {
            Caption = 'Saturday Date';
            Editable = false;
        }

        field(16; "Sunday Date"; Date)
        {
            Caption = 'Sunday Date';
            Editable = false;
        }

        field(20; "Monday Capacity"; Decimal)
        {
            Caption = 'Monday Capacity';
            FieldClass = FlowField;
            CalcFormula = sum("Opti Capacity Entry"."Capacity Hours"
                where("Resource No." = field("Resource No."),
                      "Capacity Date" = field("Monday Date")));
            DecimalPlaces = 0 : 5;
            Editable = false;
        }

        field(21; "Tuesday Capacity"; Decimal)
        {
            Caption = 'Tuesday Capacity';
            FieldClass = FlowField;
            CalcFormula = sum("Opti Capacity Entry"."Capacity Hours"
                where("Resource No." = field("Resource No."),
                      "Capacity Date" = field("Tuesday Date")));
            DecimalPlaces = 0 : 5;
            Editable = false;
        }

        field(22; "Wednesday Capacity"; Decimal)
        {
            Caption = 'Wednesday Capacity';
            FieldClass = FlowField;
            CalcFormula = sum("Opti Capacity Entry"."Capacity Hours"
                where("Resource No." = field("Resource No."),
                      "Capacity Date" = field("Wednesday Date")));
            DecimalPlaces = 0 : 5;
            Editable = false;
        }

        field(23; "Thursday Capacity"; Decimal)
        {
            Caption = 'Thursday Capacity';
            FieldClass = FlowField;
            CalcFormula = sum("Opti Capacity Entry"."Capacity Hours"
                where("Resource No." = field("Resource No."),
                      "Capacity Date" = field("Thursday Date")));
            DecimalPlaces = 0 : 5;
            Editable = false;
        }

        field(24; "Friday Capacity"; Decimal)
        {
            Caption = 'Friday Capacity';
            FieldClass = FlowField;
            CalcFormula = sum("Opti Capacity Entry"."Capacity Hours"
                where("Resource No." = field("Resource No."),
                      "Capacity Date" = field("Friday Date")));
            DecimalPlaces = 0 : 5;
            Editable = false;
        }

        field(25; "Saturday Capacity"; Decimal)
        {
            Caption = 'Saturday Capacity';
            FieldClass = FlowField;
            CalcFormula = sum("Opti Capacity Entry"."Capacity Hours"
                where("Resource No." = field("Resource No."),
                      "Capacity Date" = field("Saturday Date")));
            DecimalPlaces = 0 : 5;
            Editable = false;
        }

        field(26; "Sunday Capacity"; Decimal)
        {
            Caption = 'Sunday Capacity';
            FieldClass = FlowField;
            CalcFormula = sum("Opti Capacity Entry"."Capacity Hours"
                where("Resource No." = field("Resource No."),
                      "Capacity Date" = field("Sunday Date")));
            DecimalPlaces = 0 : 5;
            Editable = false;
        }


    }

    keys
    {
        key(PK; "Resource No.", "Week Start Date")
        {
            Clustered = true;
        }
        key(WeekDate; "Week Start Date", "Resource No.")
        {
        }
        key(EffectivePatternHash; "Effective Pattern Hash")
        {
        }

        key(SourcePatternHash; "Source Week Pattern Hash")
        {
        }
    }

    trigger OnInsert()
    begin
        SetWeekDates();
        Clear("Effective Pattern Hash");
    end;

    trigger OnModify()
    begin
        if "Week Start Date" <> xRec."Week Start Date" then
            SetWeekDates();
    end;

    procedure SetWeekDates()
    begin
        TestField("Week Start Date");

        "Monday Date" := "Week Start Date";
        "Tuesday Date" := CalcDate('<1D>', "Week Start Date");
        "Wednesday Date" := CalcDate('<2D>', "Week Start Date");
        "Thursday Date" := CalcDate('<3D>', "Week Start Date");
        "Friday Date" := CalcDate('<4D>', "Week Start Date");
        "Saturday Date" := CalcDate('<5D>', "Week Start Date");
        "Sunday Date" := CalcDate('<6D>', "Week Start Date");
        "Week End Date" := "Sunday Date";

        "Week No." := Date2DWY("Week Start Date", 2);
        "Week Year" := Date2DWY("Week Start Date", 3);
    end;

    procedure SetSourceWeekPattern(WeekPatternId: Integer; WeekPatternHash: Text[64])
    begin
        if ("Source Week Pattern ID" = WeekPatternId) and
           ("Source Week Pattern Hash" = WeekPatternHash)
        then
            exit;

        "Source Week Pattern ID" := WeekPatternId;
        "Source Week Pattern Hash" := WeekPatternHash;
        Modify(false);
    end;

    procedure EnsureCapacityWeek(
    ResourceNo: Code[20];
    CapacityDate: Date)
    var
        WeekStartDate: Date;
    begin
        if (ResourceNo = '') or (CapacityDate = 0D) then
            exit;

        WeekStartDate := GetFirstDateOfWeek(CapacityDate);

        if Get(ResourceNo, WeekStartDate) then
            exit;

        Init();
        "Resource No." := ResourceNo;
        "Week Start Date" := WeekStartDate;
        SetWeekDates();
        Insert(true);
    end;

    local procedure GetFirstDateOfWeek(InputDate: Date): Date
    begin
        if InputDate = 0D then
            exit(0D);

        exit(
            InputDate -
            Date2DWY(InputDate, 1) + 1);
    end;

    procedure DeleteIfEmpty(
     ResourceNo: Code[20];
     CapacityDate: Date;
     ExcludedSystemId: Guid)
    var
        CapacityEntry: Record "Opti Capacity Entry";
        WeekStartDate: Date;
        Guid: Guid;
    begin
        if (ResourceNo = '') or (CapacityDate = 0D) then
            exit;

        WeekStartDate := GetFirstDateOfWeek(CapacityDate);

        CapacityEntry.Reset();
        CapacityEntry.SetRange("Resource No.", ResourceNo);
        CapacityEntry.SetRange("Capacity Date", WeekStartDate, WeekStartDate + 6);
        if ExcludedSystemId <> Guid then
            CapacityEntry.SetFilter(SystemId, '<>%1', ExcludedSystemId);

        if not CapacityEntry.IsEmpty() then
            exit;

        if Get(ResourceNo, WeekStartDate) then
            Delete(true);
    end;

    procedure RecalculateWeekHash()
    begin
        RecalculateWeekHashExcludingSystemId(EmptyGuid());
    end;

    procedure RecalculateWeekHashForDate(ResourceNo: Code[20]; CapacityDate: Date)
    begin
        RecalculateWeekHashForDateExcluding(ResourceNo, CapacityDate, EmptyGuid());
    end;

    procedure RecalculateWeekHashForDateExcluding(ResourceNo: Code[20]; CapacityDate: Date; ExcludedSystemId: Guid)
    var
        WeekStartDate: Date;
    begin
        if (ResourceNo = '') or (CapacityDate = 0D) then
            exit;

        WeekStartDate := GetFirstDateOfWeek(CapacityDate);

        if Get(ResourceNo, WeekStartDate) then
            RecalculateWeekHashExcludingSystemId(ExcludedSystemId);
    end;

    procedure RecalculateWeekHashForWeek(ResourceNo: Code[20]; WeekStartDate: Date)
    begin
        RecalculateWeekHashForWeekExcluding(ResourceNo, WeekStartDate, EmptyGuid());
    end;

    procedure RecalculateWeekHashForWeekExcluding(ResourceNo: Code[20]; WeekStartDate: Date; ExcludedSystemId: Guid)
    begin
        if (ResourceNo = '') or (WeekStartDate = 0D) then
            exit;

        if Get(ResourceNo, WeekStartDate) then
            RecalculateWeekHashExcludingSystemId(ExcludedSystemId);
    end;

    local procedure RecalculateWeekHashExcludingSystemId(ExcludedSystemId: Guid)
    var
        CapacityEntry: Record "Opti Capacity Entry";
        DayPattern: Record "Opti Day Time Slots Header";
        CryptographyManagement: Codeunit "Cryptography Management";
        HashAlgorithm: Option MD5,SHA1,SHA256,SHA384,SHA512;
        HashInput: Text;
        GeneratedHash: Text;
        NewHash: Text[64];
        DayPatternHash: Text[64];
        EntryTypeNo: Integer;
        EmptySystemId: Guid;
        SourcePatternInitialized: Boolean;
        SourcePatternMixed: Boolean;
        CandidateSourceWeekPatternId: Integer;
        CandidateSourceWeekPatternHash: Text[64];
        NewSourceWeekPatternId: Integer;
        NewSourceWeekPatternHash: Text[64];
    begin
        TestField("Resource No.");
        TestField("Week Start Date");

        CapacityEntry.Reset();
        CapacityEntry.SetCurrentKey("Resource No.", "Capacity Date", "Line No.");
        CapacityEntry.SetRange("Resource No.", "Resource No.");
        CapacityEntry.SetRange("Capacity Date", "Week Start Date", "Week End Date");
        if ExcludedSystemId <> EmptySystemId then
            CapacityEntry.SetFilter(SystemId, '<>%1', ExcludedSystemId);

        if CapacityEntry.FindSet() then
            repeat
                DayPatternHash := '';

                if CapacityEntry."Day Time Slot Header ID" <> 0 then
                    if DayPattern.Get(CapacityEntry."Day Time Slot Header ID") then
                        DayPatternHash := DayPattern."Pattern Hash";

                if CapacityEntry."Source Week Pattern Hash" <> '' then begin
                    if not SourcePatternInitialized then begin
                        SourcePatternInitialized := true;
                        CandidateSourceWeekPatternId := CapacityEntry."Source Week Pattern ID";
                        CandidateSourceWeekPatternHash := CapacityEntry."Source Week Pattern Hash";
                    end else
                        if (CandidateSourceWeekPatternId <> CapacityEntry."Source Week Pattern ID") or
                           (CandidateSourceWeekPatternHash <> CapacityEntry."Source Week Pattern Hash")
                        then
                            SourcePatternMixed := true;
                end;

                EntryTypeNo := CapacityEntry."Entry Type".AsInteger();

                if HashInput <> '' then
                    HashInput += '|';

                HashInput +=
                    StrSubstNo(
                        '%1;%2;%3;%4;%5;%6',
                        Format(CapacityEntry."Capacity Date", 0, 9),
                        Format(CapacityEntry."Line No.", 0, 9),
                        Format(EntryTypeNo, 0, 9),
                        DayPatternHash,
                        CapacityEntry.Description,
                        Format(CapacityEntry."Capacity Hours", 0, 9));
            until CapacityEntry.Next() = 0;

        if HashInput = '' then
            Clear(NewHash)
        else begin
            GeneratedHash :=
                CryptographyManagement.GenerateHash(
                    HashInput,
                    HashAlgorithm::SHA256);

            NewHash := CopyStr(GeneratedHash, 1, MaxStrLen(NewHash));
        end;

        if SourcePatternInitialized and (not SourcePatternMixed) then begin
            NewSourceWeekPatternId := CandidateSourceWeekPatternId;
            NewSourceWeekPatternHash := CandidateSourceWeekPatternHash;
        end else begin
            NewSourceWeekPatternId := 0;
            Clear(NewSourceWeekPatternHash);
        end;

        if ("Effective Pattern Hash" <> NewHash) or
           ("Source Week Pattern ID" <> NewSourceWeekPatternId) or
           ("Source Week Pattern Hash" <> NewSourceWeekPatternHash)
        then begin
            "Effective Pattern Hash" := NewHash;
            "Source Week Pattern ID" := NewSourceWeekPatternId;
            "Source Week Pattern Hash" := NewSourceWeekPatternHash;
            Modify(false);
        end;
    end;

    local procedure EmptyGuid(): Guid
    var
        BlankGuid: Guid;
    begin
        exit(BlankGuid);
    end;
}
