controladdin DHXGridFactboxAddin
{
    RequestedHeight = 460;
    MinimumHeight = 300;
    VerticalShrink = true;
    VerticalStretch = true;

    RequestedWidth = 900;
    MinimumWidth = 500;
    HorizontalStretch = true;
    HorizontalShrink = true;

    Scripts =
        'src/dhx/suite.js',
        'src/dhx/res_scheduler_weekly_factbox/wrapper.js';

    StartupScript = 'src/dhx/res_scheduler_weekly_factbox/startupScript.js';

    StyleSheets =
        'src/dhx/suite.css',
        'src/dhx/res_scheduler_weekly_factbox/custom.css';

    /// <summary>Fired once the DHTMLX Suite Grid pivot has been rendered (even with empty data) and is ready to receive LoadData calls.</summary>
    event ControlReady();

    /// <summary>
    /// Fired by wrapper.js's grid "cellClick" handler (see ResolveDrillDownTarget) when the user
    /// clicks a data cell that maps directly to a real underlying record set. RowId is "CAPACITY"
    /// (the fixed Capacity row) or a bare Skill Code; RowType is "capacity"/"skill" (matches the
    /// LoadData JSON's own "rowType" per row). ColumnKind is "req" (Requested) or "ass" (Assigned)
    /// - wrapper.js never fires this event for a Sub Total/Grand Total cell (no single-table
    /// drilldown target) or for a skill row's "ass" cell (always 0/blank - no per-skill assigned
    /// tracking exists). DayIndex is the raw 1..7 weekday index shown in that LoadData payload's
    /// own "days" array, ignored (0) when WholeWeek is true. WholeWeek is currently never fired
    /// (kept for shape parity with this codebase's other control add-in drilldown events, e.g.
    /// DHXBarChartAddin's OnShowSegmentData) since the Grand Total column - the only cell that
    /// would represent "the whole week" - has no single-table drilldown target either.
    /// </summary>
    event OnCellDrillDown(RowId: Text; RowType: Text; ColumnKind: Text; DayIndex: Integer; WholeWeek: Boolean);

    /// <summary>Replaces the grid's rows/columns with the supplied JSON payload - see wrapper.js's RenderGrid for the exact shape.</summary>
    procedure LoadData(GridDataJson: Text);
}
