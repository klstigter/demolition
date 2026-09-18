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
    ///                          Per-skill columns are 0/blank - "Res. Capacity Entry" is not
    ///                          broken down by skill, so there is no meaningful per-skill split.
    ///  2. Total Request      - C = SUM("Day Planning"."Requested Hours") for all skills.
    ///                          Per-skill columns = same sum filtered to that column's Skill Code.
    ///  3. Assigned Hours     - C = SUM("Day Planning"."Assigned Hours") for all skills.
    ///                          Per-skill columns = same sum filtered to that column's Skill Code.
    ///  4. Capacity           - C = TotalCapacity - TotalRequest, same as Row 6 "Surplus".
    ///                          Per-skill columns are 0/blank, same reasoning as Row 1: capacity
    ///                          has no real per-skill breakdown, so a synthetic one (e.g. an even
    ///                          split across a resource's skills) is not shown, since it does not
    ///                          correspond to any real, drillable record set and can go negative
    ///                          for reasons unrelated to actual per-skill demand. Rendered
    ///                          Italic + Red, no bold (StyleExpr = 'Attention') on page 50696.
    ///  5. Request Plan       - Row2 - Row3, computed independently per column, same pattern.
    ///     (not assigned)
    ///  6. Surplus            - C = Row1(C) - Row2(C) (algebraically equal to Row4(C)).
    ///                          Per-skill columns are 0 - out of scope / unchanged, same as Row 1
    ///                          and Row 4, no per-skill breakdown.
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
        RequestPerColumn: List of [Decimal];
        AssignedPerColumn: List of [Decimal];
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

        // Total Capacity's per-skill columns stay blank/zero - "Res. Capacity Entry" has no real
        // per-skill breakdown to show.
        InsertRow(Buffer, 10000, TotalCapacityRowLbl, TotalCapacity, ZeroPerColumn, ColumnCount, 'Standard');
        InsertRow(Buffer, 20000, TotalRequestRowLbl, TotalRequest, RequestPerColumn, ColumnCount, 'Standard');
        InsertRow(Buffer, 30000, AssignedHoursRowLbl, TotalAssigned, AssignedPerColumn, ColumnCount, 'Standard');
        // 'Attention' renders Italic + Red, no bold - per spec (red + italic, not bold). Per-skill
        // columns are blank/zero, same reasoning as row 10000: no real per-skill capacity exists.
        InsertRow(Buffer, 40000, FreeCapacityRowLbl, TotalCapacity - TotalRequest, ZeroPerColumn, ColumnCount, 'Attention');
        InsertDifferenceRow(Buffer, 50000, RequestPlanRowLbl, TotalRequest - TotalAssigned, RequestPerColumn, AssignedPerColumn, ColumnCount, 'Standard');
        InsertRow(Buffer, 60000, SurplusRowLbl, TotalCapacity - TotalRequest, ZeroPerColumn, ColumnCount, 'Standard');

        Buffer.Reset();
        if Buffer.FindFirst() then;
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
    /// values (used for "Request Plan (not assigned)" = Row2 (Request) - Row3 (Assigned)).
    /// The result is floored at zero, both per column and for the total, since "not assigned"
    /// hours can't be negative. RowStyle is passed through to InsertRow.
    /// </summary>
    local procedure InsertDifferenceRow(var Buffer: Record "Capacity Overview Buffer" temporary; LineNo: Integer; RowDescription: Text; TotalValue: Decimal; MinuendPerColumn: List of [Decimal]; SubtrahendPerColumn: List of [Decimal]; ColumnCount: Integer; RowStyle: Text[30])
    var
        DiffPerColumn: List of [Decimal];
        Diff: Decimal;
        i: Integer;
    begin
        Clear(DiffPerColumn);
        for i := 1 to ColumnCount do begin
            Diff := MinuendPerColumn.Get(i) - SubtrahendPerColumn.Get(i);
            if Diff < 0 then
                Diff := 0;
            DiffPerColumn.Add(Diff);
        end;

        if TotalValue < 0 then
            TotalValue := 0;

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
