codeunit 50694 "Capacity Overview Mgt."
{
    /// <summary>
    /// Builds the 6-row / dynamic-column "Capacity Overview" matrix buffer (table 50693) for a
    /// given Monday..Sunday period. Columns are: C = "Total Column" (aggregate across all
    /// skills), D:.. = one generic "Column N" per entry in the ordered Skill Code list (see
    /// BuildSkillCodeList), capped at GetMaxMatrixColumns() (20) skills - the table only has that
    /// many generic columns and the matrix subpage (page 50696) only has that many field controls.
    ///
    /// Row-by-row (period = the caller-supplied PeriodStartDate..PeriodEndDate range):
    ///  1. Total Capacity     - C = SUM("Res. Capacity Entry".Capacity), no resource/skill filter.
    ///                          Per-skill columns are 0/blank - deliberately not displayed here.
    ///                          CalcCapacityPerSkill still computes the real per-skill split (each
    ///                          capacity entry's Capacity divided evenly (divide-by-N) across every
    ///                          skill the entry's resource holds, via "Resource Skill" - a resource
    ///                          with no "Resource Skill" rows at all is skipped/ignored entirely,
    ///                          strictly skill-only per spec, no blank-skill bucket), but that
    ///                          result feeds ONLY Row 4's "Capacity" calculation below, not this
    ///                          row's own displayed columns.
    ///  2. Total Request      - C = SUM("Day Planning"."Requested Hours") for all skills.
    ///                          Per-skill columns = same sum filtered to that column's Skill Code.
    ///  3. Assigned Hours     - C = SUM("Day Planning"."Assigned Hours") for all skills.
    ///                          Per-skill columns = same sum filtered to that column's Skill Code.
    ///  4. Capacity           - Row1(new, per-skill Capacity) - Row2 (per-skill Request),
    ///                          computed independently per column (C and every per-skill column).
    ///                          C = TotalCapacity - TotalRequest. Rendered Italic + Red, no bold
    ///                          (StyleExpr = 'Attention') on page 50696.
    ///  5. Request Plan       - Row2 - Row3, computed independently per column, same pattern.
    ///     (not assigned)
    ///  6. Surplus            - C = Row1(C) - Row2(C) (algebraically equal to Row4(C) - Row5(C)).
    ///                          Per-skill columns are 0 - out of scope / unchanged, unlike Row1
    ///                          this row still has no per-skill breakdown.
    /// </summary>

    /// <summary>
    /// Returns the ordered list of EVERY Skill Code record (one entry per code, in "Skill Code"
    /// table order) - deliberately NOT capped at GetMaxMatrixColumns() here. The card page passes
    /// this full list to the matrix subpage (page 50696), which slices out a window of at most
    /// GetMaxMatrixColumns() codes at a time and pages through the rest via its
    /// Previous/Next Set/Column actions when there are more skills than fit in one window.
    /// </summary>
    procedure BuildSkillCodeList(var SkillCodeList: List of [Code[20]])
    var
        SkillCode: Record "Skill Code";
    begin
        Clear(SkillCodeList);
        SkillCode.Reset();
        if SkillCode.FindSet() then
            repeat
                SkillCodeList.Add(SkillCode.Code);
            until SkillCode.Next() = 0;
    end;

    /// <summary>
    /// The generic column cap shared by table 50693 (fields "Column 1".."Column 20"), this
    /// codeunit, and page 50696 (20 field controls). Keep all three in sync if this ever changes.
    /// </summary>
    procedure GetMaxMatrixColumns(): Integer
    begin
        exit(20);
    end;

    /// <summary>
    /// Populates Buffer with the 6 fixed matrix rows for the given period, using the column
    /// order defined by SkillCodeList (see BuildSkillCodeList). SkillCodeList is expected to
    /// already be capped at GetMaxMatrixColumns(); any entries beyond the cap are ignored here
    /// as a safety net.
    /// </summary>
    procedure BuildMatrix(var Buffer: Record "Capacity Overview Buffer" temporary; PeriodStartDate: Date; PeriodEndDate: Date; SkillCodeList: List of [Code[20]])
    var
        ColumnCount: Integer;
        ZeroPerColumn: List of [Decimal];
        CapacityPerColumn: List of [Decimal];
        RequestPerColumn: List of [Decimal];
        AssignedPerColumn: List of [Decimal];
        CapacityPerSkill: Dictionary of [Code[20], Decimal];
        TotalCapacity: Decimal;
        TotalRequest: Decimal;
        TotalAssigned: Decimal;
        i: Integer;
        SkillCode: Code[20];
    begin
        Buffer.Reset();
        Buffer.DeleteAll();

        ColumnCount := SkillCodeList.Count();
        if ColumnCount > GetMaxMatrixColumns() then
            ColumnCount := GetMaxMatrixColumns();

        ZeroPerColumn := BuildZeroList(ColumnCount);

        TotalCapacity := CalcTotalCapacity(PeriodStartDate, PeriodEndDate);

        CalcCapacityPerSkill(PeriodStartDate, PeriodEndDate, CapacityPerSkill);
        Clear(CapacityPerColumn);
        for i := 1 to ColumnCount do begin
            SkillCode := SkillCodeList.Get(i);
            if CapacityPerSkill.ContainsKey(SkillCode) then
                CapacityPerColumn.Add(CapacityPerSkill.Get(SkillCode))
            else
                CapacityPerColumn.Add(0);
        end;

        TotalRequest := CalcRequestedHours(PeriodStartDate, PeriodEndDate, '');
        Clear(RequestPerColumn);
        for i := 1 to ColumnCount do begin
            SkillCode := SkillCodeList.Get(i);
            RequestPerColumn.Add(CalcRequestedHours(PeriodStartDate, PeriodEndDate, SkillCode));
        end;

        TotalAssigned := CalcAssignedHours(PeriodStartDate, PeriodEndDate, '');
        Clear(AssignedPerColumn);
        for i := 1 to ColumnCount do begin
            SkillCode := SkillCodeList.Get(i);
            AssignedPerColumn.Add(CalcAssignedHours(PeriodStartDate, PeriodEndDate, SkillCode));
        end;

        // Per-skill values are deliberately NOT shown here - CapacityPerColumn is calculated for
        // row 40000's "Capacity" (Free Capacity) subtraction only (see A.3 in this codeunit's own
        // doc comment); Total Capacity's own per-skill columns stay blank/zero, same as before
        // CalcCapacityPerSkill existed.
        InsertRow(Buffer, 10000, TotalCapacityRowLbl, TotalCapacity, ZeroPerColumn, ColumnCount, 'Standard');
        InsertRow(Buffer, 20000, TotalRequestRowLbl, TotalRequest, RequestPerColumn, ColumnCount, 'Standard');
        InsertRow(Buffer, 30000, AssignedHoursRowLbl, TotalAssigned, AssignedPerColumn, ColumnCount, 'Standard');
        // 'Attention' renders Italic + Red, no bold - per spec (red + italic, not bold).
        InsertDifferenceRow(Buffer, 40000, FreeCapacityRowLbl, TotalCapacity - TotalRequest, CapacityPerColumn, RequestPerColumn, ColumnCount, 'Attention');
        InsertDifferenceRow(Buffer, 50000, RequestPlanRowLbl, TotalRequest - TotalAssigned, RequestPerColumn, AssignedPerColumn, ColumnCount, 'Standard');
        InsertRow(Buffer, 60000, SurplusRowLbl, TotalCapacity - TotalRequest, ZeroPerColumn, ColumnCount, 'Standard');

        Buffer.Reset();
        if Buffer.FindFirst() then;
    end;

    /// <summary>
    /// Splits every "Res. Capacity Entry" row's Capacity (Date in [PeriodStartDate,
    /// PeriodEndDate], no other filter) evenly (divide-by-N) across every skill the entry's
    /// resource holds, via "Resource Skill". Strictly skill-only, per spec: a resource with zero
    /// "Resource Skill" rows contributes nothing to CapacityPerSkill at all - its capacity is
    /// simply not counted in any per-skill column (not credited to any blank/"None" bucket - there
    /// is no such bucket). An in-procedure ResourceSkillCache avoids re-querying "Resource Skill"
    /// for a resource seen on an earlier entry in the same period.
    /// </summary>
    local procedure CalcCapacityPerSkill(PeriodStartDate: Date; PeriodEndDate: Date; var CapacityPerSkill: Dictionary of [Code[20], Decimal])
    var
        ResCapacityEntry: Record "Res. Capacity Entry";
        ResourceSkillCache: Dictionary of [Code[20], List of [Code[20]]];
        SkillCodesForResource: List of [Code[20]];
        SplitCapacity: Decimal;
        SkillCode: Code[20];
    begin
        Clear(CapacityPerSkill);

        ResCapacityEntry.Reset();
        ResCapacityEntry.SetRange(Date, PeriodStartDate, PeriodEndDate);
        if ResCapacityEntry.FindSet() then
            repeat
                SkillCodesForResource := GetResourceSkillCodes(ResCapacityEntry."Resource No.", ResourceSkillCache);

                if SkillCodesForResource.Count() > 0 then begin
                    SplitCapacity := ResCapacityEntry.Capacity / SkillCodesForResource.Count();
                    foreach SkillCode in SkillCodesForResource do
                        AddToDictionary(CapacityPerSkill, SkillCode, SplitCapacity);
                end;
            until ResCapacityEntry.Next() = 0;
    end;

    /// <summary>
    /// Returns (and caches, in ResourceSkillCache) the list of "Skill Code" values from every
    /// "Resource Skill" row for ResourceNo (Type is ignored - a Resource No. only ever has one
    /// Type in practice, per spec).
    /// </summary>
    local procedure GetResourceSkillCodes(ResourceNo: Code[20]; var ResourceSkillCache: Dictionary of [Code[20], List of [Code[20]]]) SkillCodesForResource: List of [Code[20]]
    var
        ResourceSkill: Record "Resource Skill";
    begin
        if ResourceSkillCache.ContainsKey(ResourceNo) then
            exit(ResourceSkillCache.Get(ResourceNo));

        Clear(SkillCodesForResource);
        ResourceSkill.Reset();
        ResourceSkill.SetRange("No.", ResourceNo);
        if ResourceSkill.FindSet() then
            repeat
                SkillCodesForResource.Add(ResourceSkill."Skill Code");
            until ResourceSkill.Next() = 0;

        ResourceSkillCache.Set(ResourceNo, SkillCodesForResource);
    end;

    /// <summary>
    /// Add-or-initialize accumulation helper, mirroring AddToTotals in
    /// Cod50608.SkillCapacityAnalysisMgtv1.al.
    /// </summary>
    local procedure AddToDictionary(var Dict: Dictionary of [Code[20], Decimal]; DictKey: Code[20]; ValueToAdd: Decimal)
    var
        CurrentValue: Decimal;
    begin
        if Dict.ContainsKey(DictKey) then
            CurrentValue := Dict.Get(DictKey);

        Dict.Set(DictKey, CurrentValue + ValueToAdd);
    end;

    /// <summary>
    /// Sums "Res. Capacity Entry".Capacity for the Date range, with no resource filter and no
    /// skill filter - capacity entries are not broken down by skill (see the codeunit doc
    /// comment), so this is always the single aggregate figure regardless of column.
    /// </summary>
    local procedure CalcTotalCapacity(PeriodStartDate: Date; PeriodEndDate: Date): Decimal
    var
        ResCapacityEntry: Record "Res. Capacity Entry";
    begin
        ResCapacityEntry.Reset();
        ResCapacityEntry.SetRange(Date, PeriodStartDate, PeriodEndDate);
        ResCapacityEntry.CalcSums(Capacity);
        exit(ResCapacityEntry.Capacity);
    end;

    local procedure CalcRequestedHours(PeriodStartDate: Date; PeriodEndDate: Date; SkillCodeFilter: Code[20]): Decimal
    var
        DayPlanning: Record "Day Planning";
    begin
        DayPlanning.Reset();
        DayPlanning.SetRange("Plan Date", PeriodStartDate, PeriodEndDate);
        if SkillCodeFilter <> '' then
            DayPlanning.SetRange(Skill, SkillCodeFilter);
        DayPlanning.CalcSums("Requested Hours");
        exit(DayPlanning."Requested Hours");
    end;

    local procedure CalcAssignedHours(PeriodStartDate: Date; PeriodEndDate: Date; SkillCodeFilter: Code[20]): Decimal
    var
        DayPlanning: Record "Day Planning";
    begin
        DayPlanning.Reset();
        DayPlanning.SetRange("Plan Date", PeriodStartDate, PeriodEndDate);
        if SkillCodeFilter <> '' then
            DayPlanning.SetRange(Skill, SkillCodeFilter);
        DayPlanning.CalcSums("Assigned Hours");
        exit(DayPlanning."Assigned Hours");
    end;

    local procedure BuildZeroList(ColumnCount: Integer) ZeroList: List of [Decimal]
    var
        i: Integer;
    begin
        Clear(ZeroList);
        for i := 1 to ColumnCount do
            ZeroList.Add(0);
    end;

    /// <summary>
    /// Inserts one matrix row: "Total Column" = TotalValue, "Style" = RowStyle (drives page
    /// 50696's StyleExpr), and "Column 1".."Column N" (N = ColumnCount) set from PerColumnValues
    /// in order, via RecordRef/FieldRef since the generic columns cannot be addressed by a
    /// compile-time field name. Field 10 is "Column 1", so "Column i" is field (9 + i) - keep
    /// this offset in sync with table 50693.
    /// </summary>
    local procedure InsertRow(var Buffer: Record "Capacity Overview Buffer" temporary; LineNo: Integer; RowDescription: Text; TotalValue: Decimal; PerColumnValues: List of [Decimal]; ColumnCount: Integer; RowStyle: Text[30])
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
        i: Integer;
    begin
        Buffer.Init();
        Buffer."Line No." := LineNo;
        Buffer.Description := CopyStr(RowDescription, 1, MaxStrLen(Buffer.Description));
        Buffer."Total Column" := TotalValue;
        Buffer.Style := RowStyle;

        RecRef.GetTable(Buffer);
        for i := 1 to ColumnCount do begin
            FldRef := RecRef.Field(9 + i);
            FldRef.Value := PerColumnValues.Get(i);
        end;
        RecRef.SetTable(Buffer);

        Buffer.Insert();
    end;

    /// <summary>
    /// Inserts a matrix row whose values are the column-wise difference of two prior rows'
    /// values (used for "Capacity" = Row1(new, per-skill Capacity) - Row2 (Request) and
    /// "Request Plan (not assigned)" = Row2 - Row3). RowStyle is passed through to InsertRow.
    /// </summary>
    local procedure InsertDifferenceRow(var Buffer: Record "Capacity Overview Buffer" temporary; LineNo: Integer; RowDescription: Text; TotalValue: Decimal; MinuendPerColumn: List of [Decimal]; SubtrahendPerColumn: List of [Decimal]; ColumnCount: Integer; RowStyle: Text[30])
    var
        DiffPerColumn: List of [Decimal];
        i: Integer;
    begin
        Clear(DiffPerColumn);
        for i := 1 to ColumnCount do
            DiffPerColumn.Add(MinuendPerColumn.Get(i) - SubtrahendPerColumn.Get(i));

        InsertRow(Buffer, LineNo, RowDescription, TotalValue, DiffPerColumn, ColumnCount, RowStyle);
    end;

    var
        TotalCapacityRowLbl: Label 'Total Capacity';
        TotalRequestRowLbl: Label 'Total Request';
        AssignedHoursRowLbl: Label 'Assigned Hours';
        FreeCapacityRowLbl: Label 'Capacity';
        RequestPlanRowLbl: Label 'Request Plan (not assigned)';
        SurplusRowLbl: Label 'Surplus';
}
