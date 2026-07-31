table 50629 "Opti Effective Week Pattern"
{
    Caption = 'Effective Week Pattern';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Effective Week Pattern ID"; Integer)
        {
            Caption = 'Effective Week Pattern ID';
            AutoIncrement = true;
            Editable = false;
        }
        field(10; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(20; "Pattern Hash"; Text[64])
        {
            Caption = 'Pattern Hash';
            Editable = false;
        }
        field(30; "Source Week Pattern ID"; Integer)
        {
            Caption = 'Source Week Pattern ID';
            TableRelation = "Opti Week Pattern Header"."Week Pattern ID";
            Editable = false;
        }
        field(40; "Source Week Pattern Hash"; Text[64])
        {
            Caption = 'Source Week Pattern Hash';
            Editable = false;
        }
        field(50; "No. of Active Days"; Integer)
        {
            Caption = 'No. of Active Days';
            Editable = false;
        }
        field(60; "Total Capacity Hours"; Decimal)
        {
            Caption = 'Total Capacity Hours';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(70; "Resource No."; Code[20])
        {
            Caption = 'Resource No.';
            TableRelation = Resource."No.";
            Editable = false;
        }
        field(80; "Week Start Date"; Date)
        {
            Caption = 'Week Start Date';
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Effective Week Pattern ID")
        {
            Clustered = true;
        }

        key(PatternHashKey; "Pattern Hash")
        {
        }

        key(WeekInstanceKey; "Resource No.", "Week Start Date")
        {
            Unique = true;
        }
    }

    procedure UpsertForWeek(ResourceNo: Code[20]; WeekStartDate: Date; var TempWeekLine: Record "Opti Eff Week Pattern Line" temporary; SourceWeekPatternId: Integer; SourceWeekPatternHash: Text[64]): Integer
    var
        NewPatternHash: Text[64];
    begin
        NewPatternHash := CalculatePatternHash(TempWeekLine);

        Reset();
        SetRange("Resource No.", ResourceNo);
        SetRange("Week Start Date", WeekStartDate);
        if not FindFirst() then begin
            Init();
            Description := CopyStr(StrSubstNo('Effective %1 %2', ResourceNo, Format(WeekStartDate, 0, 9)), 1, MaxStrLen(Description));
            "Resource No." := ResourceNo;
            "Week Start Date" := WeekStartDate;
            Insert(true);
        end;

        "Pattern Hash" := NewPatternHash;
        "Source Week Pattern ID" := SourceWeekPatternId;
        "Source Week Pattern Hash" := SourceWeekPatternHash;
        Modify(false);

        DeleteLines("Effective Week Pattern ID");

        InsertLinesFromTemp(TempWeekLine);
        RecalculateStatistics();

        exit("Effective Week Pattern ID");
    end;

    procedure DeleteForWeek(ResourceNo: Code[20]; WeekStartDate: Date)
    begin
        Reset();
        SetRange("Resource No.", ResourceNo);
        SetRange("Week Start Date", WeekStartDate);
        if FindFirst() then begin
            DeleteLines("Effective Week Pattern ID");
            Delete(true);
        end;
    end;

    procedure RecalculateStatistics()
    var
        EffectiveWeekPatternLine: Record "Opti Eff Week Pattern Line";
        ActiveDays: Integer;
        CapacityHours: Decimal;
    begin
        TestField("Effective Week Pattern ID");

        EffectiveWeekPatternLine.SetRange("Effective Week Pattern ID", "Effective Week Pattern ID");
        if EffectiveWeekPatternLine.FindSet() then
            repeat
                if EffectiveWeekPatternLine."Entry Count" > 0 then
                    ActiveDays += 1;
                CapacityHours += EffectiveWeekPatternLine."Capacity Hours";
            until EffectiveWeekPatternLine.Next() = 0;

        "No. of Active Days" := ActiveDays;
        "Total Capacity Hours" := CapacityHours;
        Modify(false);
    end;

    local procedure InsertLinesFromTemp(var TempWeekLine: Record "Opti Eff Week Pattern Line" temporary)
    var
        EffectiveWeekPatternLine: Record "Opti Eff Week Pattern Line";
    begin
        TempWeekLine.Reset();
        TempWeekLine.SetCurrentKey("Weekday No.");
        if TempWeekLine.FindSet() then
            repeat
                EffectiveWeekPatternLine.Init();
                EffectiveWeekPatternLine."Effective Week Pattern ID" := "Effective Week Pattern ID";
                EffectiveWeekPatternLine."Weekday No." := TempWeekLine."Weekday No.";
                EffectiveWeekPatternLine."Day Pattern ID" := TempWeekLine."Day Pattern ID";
                EffectiveWeekPatternLine."Day Effective Hash" := TempWeekLine."Day Effective Hash";
                EffectiveWeekPatternLine."Entry Count" := TempWeekLine."Entry Count";
                EffectiveWeekPatternLine."Capacity Hours" := TempWeekLine."Capacity Hours";
                EffectiveWeekPatternLine.Insert(true);
            until TempWeekLine.Next() = 0;
    end;

    local procedure DeleteLines(EffectiveWeekPatternId: Integer)
    var
        EffectiveWeekPatternLine: Record "Opti Eff Week Pattern Line";
    begin
        EffectiveWeekPatternLine.SetRange("Effective Week Pattern ID", EffectiveWeekPatternId);
        EffectiveWeekPatternLine.DeleteAll(true);
    end;

    local procedure CalculatePatternHash(var TempWeekLine: Record "Opti Eff Week Pattern Line" temporary): Text[64]
    var
        CryptographyManagement: Codeunit "Cryptography Management";
        HashAlgorithm: Option MD5,SHA1,SHA256,SHA384,SHA512;
        HashInput: Text;
        GeneratedHash: Text;
    begin
        TempWeekLine.Reset();
        TempWeekLine.SetCurrentKey("Weekday No.");

        if TempWeekLine.FindSet() then
            repeat
                if HashInput <> '' then
                    HashInput += '|';

                HashInput +=
                    StrSubstNo(
                        '%1;%2;%3;%4',
                        Format(TempWeekLine."Weekday No.", 0, 9),
                        TempWeekLine."Day Effective Hash",
                        Format(TempWeekLine."Entry Count", 0, 9),
                        Format(TempWeekLine."Capacity Hours", 0, 9));
            until TempWeekLine.Next() = 0;

        if HashInput = '' then
            exit('');

        GeneratedHash :=
            CryptographyManagement.GenerateHash(
                HashInput,
                HashAlgorithm::SHA256);

        exit(CopyStr(GeneratedHash, 1, 64));
    end;
}
