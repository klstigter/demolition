controladdin DHXBarChartAddin
{
    RequestedHeight = 600;
    MinimumHeight = 400;
    VerticalShrink = true;
    VerticalStretch = true;

    RequestedWidth = 1100;
    MinimumWidth = 400;
    HorizontalStretch = true;
    HorizontalShrink = true;

    Scripts =
        'src/dhx/suite.js',
        'src/dhx/barchart_weekly/wrapper.js';

    StartupScript = 'src/dhx/barchart_weekly/startupScript.js';

    StyleSheets =
        'src/dhx/suite.css';

    event ControlReady();
    event OnDataPointClicked(SkillCode: Text);
    /// <summary>
    /// Fired by wrapper.js's right-click "Show Data" context menu (see ResolveBarSegmentFromEvent/
    /// ResolveLegendSegmentFromEvent + the contextmenu listener set up in BOOT). SegmentId is the
    /// series name string that exactly matches one of codeunit 50662's series-name Labels (e.g.
    /// "Assigned Capacity - Internal") or a bare Skill Code. BarType is "Capacity"/"Requested" for
    /// a bar-segment click, or "" (ignored) for a legend click. DayIndex is the raw 1..7 weekday
    /// index (see BuildDayCapacityChartData's "dayIndices" JSON array), 0/ignored when WholeWeek
    /// is true. WholeWeek is true for a legend-origin click (whole displayed week), false for a
    /// bar-segment click (single day, given by DayIndex).
    /// </summary>
    event OnShowSegmentData(SegmentId: Text; BarType: Text; DayIndex: Integer; WholeWeek: Boolean);

    /// <summary>
    /// Fired by wrapper.js's own Refresh/Previous/Today/Next toolbar buttons (see BuildToolbar/
    /// UpdateToolbar there) - a JS-rendered replacement for the BC RefreshAction/PreviousAction/
    /// TodayAction/NextAction actions that page 50708 "Requested vs Capacity Weekly P" used to
    /// expose via its own actions() area, retired because BC collapses a CardPart's action bar
    /// into a hidden "..." overflow menu once it's embedded in a Role Center. The toolbar itself
    /// is opt-in per page (chartData.showToolbar, sent only by page 50708's own RefreshChart), so
    /// these events only ever fire from that page - see wrapper.js's own BuildToolbar comment.
    /// Parameterless, same round-trip the retired BC actions used (JS trigger -> AL local
    /// procedure), no data to carry.
    /// </summary>
    event OnRefreshClicked();
    event OnPreviousClicked();
    event OnTodayClicked();
    event OnNextClicked();

    procedure LoadData(ChartDataJson: Text);
}
