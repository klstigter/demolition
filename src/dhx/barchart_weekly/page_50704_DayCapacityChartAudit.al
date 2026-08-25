page 50704 "Day Capacity Chart Audit"
{
    PageType = List;
    SourceTable = "Day Capacity Chart Audit Buf";
    SourceTableTemporary = true;
    Caption = 'Day Capacity Chart Audit';
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    LinksAllowed = false;

    /// <summary>
    /// Renders the "Chart Audit Trail" FactBox as a pivot-style dhtmlx Suite Grid (see
    /// src/dhx/res_scheduler_weekly_factbox) instead of the old flat AL repeater - one row for
    /// "Capacity" plus one row per active Skill Code, one Requested/Assigned/Sub Total column
    /// group per weekday, and a single Grand Total column. LoadData's public signature is
    /// UNCHANGED (page 50692's RefreshAuditBuffer still calls it exactly as before) - internally
    /// it now builds a grid-ready JSON payload FROM SourceBuffer's own rows (via
    /// BuildGridDataJson) instead of mirroring them into Rec for a repeater to display. Rec is
    /// still populated exactly as before (harmless, and keeps this page's own record in a
    /// well-defined state) even though nothing in the layout binds to it anymore.
    ///
    /// Data mapping (see BuildGridDataJson/AddCapacityGridRow/AddSkillGridRow for the actual
    /// SetRange/CalcSums calls): every number is RESUMMED directly from SourceBuffer's own
    /// already-computed rows - built by codeunit 50662's BuildDayCapacityAuditBuffer moments
    /// earlier - rather than recomputed from Day Planning/Res. Capacity Entry a second time, so
    /// this view can never drift from the audit buffer it is built from:
    ///   - Capacity row, per day: "Assigned" = the buffer's own Bar Type=Capacity/Segment=
    ///     Assigned row (already the day's combined Internal+External assigned total).
    ///     "Requested" = the buffer's Bar Type=Capacity/Segment=Internal + Segment=External rows
    ///     SUMMED (i.e. the day's free/available capacity total - matches what the old flat
    ///     buffer already showed under those two segments).
    ///   - Skill row (one per active Skill Code, i.e. every distinct non-Assigned/Internal/
    ///     External Segment under Bar Type=Requested), per day: "Requested" = the buffer's own
    ///     Bar Type=Requested/Segment=<SkillCode> row (already the day's combined Internal+
    ///     External requested total for that skill - see BuildDayCapacityAuditBuffer's own doc
    ///     comment on why a skill's Internal/External halves share one Segment value). "Assigned"
    ///     is always 0/blank: codeunit 50662 has NO per-skill assigned-hours tracking anywhere
    ///     (Assigned Hours is only ever aggregated at the whole-day level - see that codeunit's
    ///     CalcAssignedSplit) - this is a deliberate gap, not an oversight, and is NOT invented
    ///     here (see AddSkillGridRow).
    ///   - Sub Total = that day's Requested + Assigned. Grand Total = sum of the row's 7 daily
    ///     Sub Totals.
    ///
    /// Drilldown (ShowGridCellDrillDown, fired by the grid's OnCellDrillDown event - see
    /// wrapper.js's ResolveDrillDownTarget for exactly which cells are clickable) reimplements
    /// this page's OLD inline OnDrillDown filter logic against the new (RowId/RowType/
    /// ColumnKind/DayIndex) shape rather than calling into codeunit 50662, matching this page's
    /// own original architecture (all of its drilldown filtering was always inline here, not in
    /// the codeunit) and keeping codeunit 50662 completely untouched by this feature.
    /// </summary>

    layout
    {
        area(Content)
        {
            usercontrol(PivotGrid; DHXGridFactboxAddin)
            {
                ApplicationArea = All;

                trigger ControlReady()
                begin
                    GridReady := true;
                    PushGridData();
                end;

                trigger OnCellDrillDown(RowId: Text; RowType: Text; ColumnKind: Text; DayIndex: Integer; WholeWeek: Boolean)
                begin
                    ShowGridCellDrillDown(RowId, RowType, ColumnKind, DayIndex, WholeWeek);
                end;
            }
        }
    }

    /// <summary>
    /// Replaces the content of this page with the rows of the supplied temporary buffer, and
    /// rebuilds/pushes the pivot grid's JSON payload from those same rows. Public signature
    /// UNCHANGED - see this page's own header comment.
    /// </summary>
    procedure LoadData(var SourceBuffer: Record "Day Capacity Chart Audit Buf" temporary)
    begin
        Rec.Reset();
        Rec.DeleteAll();

        SourceBuffer.Reset();
        if SourceBuffer.FindSet() then
            repeat
                Rec := SourceBuffer;
                Rec.Insert();
            until SourceBuffer.Next() = 0;

        Rec.Reset();
        if Rec.FindFirst() then
            // Line No. 1 is always Monday's first row (BuildDayCapacityAuditBuffer's own
            // insertion order - WeekdayIndex 1, Capacity bar, "Assigned" segment) - so this
            // reconstructs the displayed period's Monday without needing a PeriodStartDate
            // parameter, which LoadData's fixed signature has no room for.
            GridPeriodStartDate := Rec.Day
        else
            GridPeriodStartDate := 0D;

        LastGridDataJson := BuildGridDataJson(SourceBuffer);
        PushGridData();

        CurrPage.Update(false);
    end;

    local procedure PushGridData()
    begin
        if not GridReady then
            exit; // ControlReady hasn't fired in the browser yet - PushGridData runs again from
                  // there once it does, same "cache + push on ready" pattern page 50692 uses for
                  // its own DhxBarChart usercontrol (see that page's ChartReady/RefreshChart).
        CurrPage.PivotGrid.LoadData(LastGridDataJson);
    end;

    /// <summary>
    /// Builds the pivot grid's JSON payload (days[]/rows[], see wrapper.js's RenderGrid for the
    /// exact shape) entirely from SourceBuffer's own already-computed rows - see this page's own
    /// header comment for the full data-mapping rationale.
    /// </summary>
    local procedure BuildGridDataJson(var SourceBuffer: Record "Day Capacity Chart Audit Buf" temporary) GridDataJson: Text
    var
        GridData: JsonObject;
        DaysArray: JsonArray;
        RowsArray: JsonArray;
        DayList: List of [Date];
        SkillList: List of [Code[20]];
        ADate: Date;
        ASkill: Code[20];
        DayOffset: Integer;
    begin
        Clear(GridData);
        Clear(DaysArray);
        Clear(RowsArray);
        Clear(DayList);

        if GridPeriodStartDate <> 0D then
            for DayOffset := 0 to 6 do
                DayList.Add(GridPeriodStartDate + DayOffset);

        foreach ADate in DayList do
            AddGridDayEntry(DaysArray, ADate);

        if DayList.Count() > 0 then begin
            AddCapacityGridRow(RowsArray, SourceBuffer, DayList);

            BuildActiveSkillCodeList(SourceBuffer, SkillList);
            foreach ASkill in SkillList do
                AddSkillGridRow(RowsArray, SourceBuffer, ASkill, DayList);
        end;

        GridData.Add('days', DaysArray);
        GridData.Add('rows', RowsArray);
        GridData.WriteTo(GridDataJson);
    end;

    local procedure AddGridDayEntry(var DaysArray: JsonArray; ADate: Date)
    var
        DayObj: JsonObject;
    begin
        Clear(DayObj);
        DayObj.Add('index', DaysArray.Count() + 1);
        DayObj.Add('label', FormatWeekdayShort(ADate));
        DaysArray.Add(DayObj);
    end;

    /// <summary>
    /// Builds the "Capacity" row: "Assigned" resums the buffer's own Bar Type=Capacity/Segment=
    /// Assigned row, "Requested" resums the buffer's Bar Type=Capacity/Segment=Internal +
    /// Segment=External rows summed - see this page's own header comment.
    /// </summary>
    local procedure AddCapacityGridRow(var RowsArray: JsonArray; var SourceBuffer: Record "Day Capacity Chart Audit Buf" temporary; var DayList: List of [Date])
    var
        RowObj: JsonObject;
        DaysArray: JsonArray;
        DayObj: JsonObject;
        ADate: Date;
        RequestedVal: Decimal;
        AssignedVal: Decimal;
        GrandTotal: Decimal;
    begin
        Clear(DaysArray);
        GrandTotal := 0;
        foreach ADate in DayList do begin
            AssignedVal := SumBufferValue(SourceBuffer, ADate, Enum::"Day Capacity Chart Bar Type"::Capacity, UpperCase(AssignedSegmentTok));
            RequestedVal := SumBufferValue(SourceBuffer, ADate, Enum::"Day Capacity Chart Bar Type"::Capacity, UpperCase(InternalSegmentTok) + '|' + UpperCase(ExternalSegmentTok));

            Clear(DayObj);
            DayObj.Add('req', RequestedVal);
            DayObj.Add('ass', AssignedVal);
            DayObj.Add('sub', RequestedVal + AssignedVal);
            DaysArray.Add(DayObj);

            GrandTotal += RequestedVal + AssignedVal;
        end;

        RowObj.Add('id', CapacityRowIdTok);
        RowObj.Add('label', CapacityRowLabelLbl);
        RowObj.Add('rowType', CapacityRowTypeTok);
        RowObj.Add('d', DaysArray);
        RowObj.Add('grand', GrandTotal);
        RowsArray.Add(RowObj);
    end;

    /// <summary>
    /// Builds one Skill Code row: "Requested" resums the buffer's own Bar Type=Requested/
    /// Segment=&lt;SkillCode&gt; row (already the day's combined Internal+External total for
    /// that skill). "Assigned" is always 0 - codeunit 50662 has no per-skill assigned-hours
    /// tracking anywhere (Assigned Hours is only ever aggregated at the whole-day level, see that
    /// codeunit's CalcAssignedSplit) - deliberately NOT invented here, per the feature spec.
    /// </summary>
    local procedure AddSkillGridRow(var RowsArray: JsonArray; var SourceBuffer: Record "Day Capacity Chart Audit Buf" temporary; SkillCode: Code[20]; var DayList: List of [Date])
    var
        RowObj: JsonObject;
        DaysArray: JsonArray;
        DayObj: JsonObject;
        ADate: Date;
        RequestedVal: Decimal;
        GrandTotal: Decimal;
    begin
        Clear(DaysArray);
        GrandTotal := 0;
        foreach ADate in DayList do begin
            RequestedVal := SumBufferValue(SourceBuffer, ADate, Enum::"Day Capacity Chart Bar Type"::Requested, SkillCode);

            Clear(DayObj);
            DayObj.Add('req', RequestedVal);
            DayObj.Add('ass', 0); // No per-skill assigned tracking exists - see this procedure's own doc comment.
            DayObj.Add('sub', RequestedVal);
            DaysArray.Add(DayObj);

            GrandTotal += RequestedVal;
        end;

        RowObj.Add('id', SkillCode);
        RowObj.Add('label', SkillCode);
        RowObj.Add('rowType', SkillRowTypeTok);
        RowObj.Add('d', DaysArray);
        RowObj.Add('grand', GrandTotal);
        RowsArray.Add(RowObj);
    end;

    /// <summary>
    /// Sums SourceBuffer.Value for one Day + Bar Type + Segment filter (SegmentFilter may be a
    /// single Segment value or a '|'-delimited OR filter, e.g. "INTERNAL|EXTERNAL" - Segment is a
    /// Code field, always stored upper-cased, so callers must UpperCase() their own literal
    /// tokens before passing them in here, same convention this page's old OnDrillDown already
    /// used).
    /// </summary>
    local procedure SumBufferValue(var SourceBuffer: Record "Day Capacity Chart Audit Buf" temporary; ADate: Date; BarType: Enum "Day Capacity Chart Bar Type"; SegmentFilter: Text): Decimal
    begin
        SourceBuffer.Reset();
        SourceBuffer.SetRange(Day, ADate);
        SourceBuffer.SetRange("Bar Type", BarType);
        SourceBuffer.SetFilter(Segment, SegmentFilter);
        SourceBuffer.CalcSums(Value);
        exit(SourceBuffer.Value);
    end;

    /// <summary>
    /// Reconstructs the same active-Skill-Code set BuildActiveSkillList produced when
    /// BuildDayCapacityAuditBuffer was built, by reading the distinct non-Assigned/Internal/
    /// External Segment values under Bar Type=Requested - every active skill has at least one
    /// such row for every weekday (see BuildDayCapacityAuditBuffer's own doc comment), so the
    /// first occurrence in Line No. order (Monday first) reproduces BuildActiveSkillList's own
    /// order exactly.
    /// </summary>
    local procedure BuildActiveSkillCodeList(var SourceBuffer: Record "Day Capacity Chart Audit Buf" temporary; var SkillList: List of [Code[20]])
    var
        SeenSkills: Dictionary of [Code[20], Boolean];
    begin
        Clear(SkillList);
        SourceBuffer.Reset();
        SourceBuffer.SetRange("Bar Type", Enum::"Day Capacity Chart Bar Type"::Requested);
        SourceBuffer.SetFilter(Segment, '<>%1&<>%2&<>%3', UpperCase(AssignedSegmentTok), UpperCase(InternalSegmentTok), UpperCase(ExternalSegmentTok));
        if SourceBuffer.FindSet() then
            repeat
                if not SeenSkills.ContainsKey(SourceBuffer.Segment) then begin
                    SeenSkills.Add(SourceBuffer.Segment, true);
                    SkillList.Add(SourceBuffer.Segment);
                end;
            until SourceBuffer.Next() = 0;
        SourceBuffer.Reset();
    end;

    /// <summary>
    /// Resolves a pivot-grid cell click back to the real Day Planning/Res. Capacity Entry
    /// records that cell's number was built from, and opens the matching list page - the same
    /// role this page's OLD Value-field OnDrillDown played, reimplemented against the grid's
    /// (RowId/RowType/ColumnKind/DayIndex) shape instead of a repeater row. wrapper.js's
    /// ResolveDrillDownTarget only ever fires this for a "req"/"ass" cell that maps to a single
    /// underlying table (never Sub Total/Grand Total, never a skill row's "ass" cell) - the
    /// guards below are defense-in-depth against a stale/malformed control add-in payload, not
    /// the primary gate.
    /// </summary>
    local procedure ShowGridCellDrillDown(RowId: Text; RowType: Text; ColumnKind: Text; DayIndex: Integer; WholeWeek: Boolean)
    var
        DayPlanning: Record "Day Planning";
        ResCapacityEntry: Record "Res. Capacity Entry";
        DrillDate: Date;
    begin
        if WholeWeek or (DayIndex < 1) or (DayIndex > 7) or (GridPeriodStartDate = 0D) then
            exit; // WholeWeek is never actually fired today (Grand Total has no single-table
                  // drilldown target - see wrapper.js's own comment); a malformed/stale DayIndex
                  // likewise has nothing sane to open.

        DrillDate := GridPeriodStartDate + (DayIndex - 1);

        if RowType = SkillRowTypeTok then begin
            // Matches CalcUnassignedSkillRequestedSplit's own filter exactly (same as codeunit
            // 50662's ShowSkillSegment / this page's OLD Skill-segment OnDrillDown branch) -
            // "ass" is never fired for a skill row (see wrapper.js), so ColumnKind is always
            // "req" here; no branch needed.
            DayPlanning.Reset();
            DayPlanning.SetRange("Plan Date", DrillDate);
            DayPlanning.SetRange(Assigned, false);
            DayPlanning.SetRange(Skill, CopyStr(RowId, 1, MaxStrLen(DayPlanning.Skill)));
            Page.Run(Page::"Day Plannings", DayPlanning);
            exit;
        end;

        // Capacity row.
        case ColumnKind of
            AssignedColumnKindTok:
                begin
                    // Combined Internal+External assigned total for the day - same filter as
                    // this page's OLD "Assigned" OnDrillDown branch.
                    DayPlanning.Reset();
                    DayPlanning.SetRange("Plan Date", DrillDate);
                    DayPlanning.SetRange(Assigned, true);
                    Page.Run(Page::"Day Plannings", DayPlanning);
                end;
            RequestedColumnKindTok:
                begin
                    // Combined Internal+External free capacity total for the day. Deliberately a
                    // plain date filter, not narrowed to the exact resource set CalcCapacitySplit
                    // would compute (that math is local/private to codeunit 50662, and this
                    // feature is scoped to leave that codeunit untouched) - every "Res. Capacity
                    // Entry" on this date is a reasonable, low-risk drilldown population for a
                    // cell that itself represents a COMBINED (Internal+External) total. The same
                    // kind of imprecision is already an accepted, documented tradeoff elsewhere in
                    // this feature area (see codeunit 50662's ShowFreeCapacitySegment doc comment).
                    ResCapacityEntry.Reset();
                    ResCapacityEntry.SetRange(Date, DrillDate);
                    Page.Run(Page::"Res. Capacity Entries", ResCapacityEntry);
                end;
        end;
    end;

    local procedure FormatWeekdayShort(ADate: Date): Text
    begin
        exit(Format(ADate, 0, '<Weekday Text,3>'));
    end;

    var
        GridReady: Boolean;
        GridPeriodStartDate: Date;
        LastGridDataJson: Text;
        AssignedSegmentTok: Label 'Assigned', Locked = true;
        InternalSegmentTok: Label 'Internal', Locked = true;
        ExternalSegmentTok: Label 'External', Locked = true;
        CapacityRowIdTok: Label 'CAPACITY', Locked = true;
        CapacityRowLabelLbl: Label 'Capacity';
        CapacityRowTypeTok: Label 'capacity', Locked = true;
        SkillRowTypeTok: Label 'skill', Locked = true;
        AssignedColumnKindTok: Label 'ass', Locked = true;
        RequestedColumnKindTok: Label 'req', Locked = true;
}
