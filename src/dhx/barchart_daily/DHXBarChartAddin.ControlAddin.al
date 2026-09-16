controladdin DHXBarChartAddin_daily
{
    RequestedHeight = 500;
    MinimumHeight = 300;
    VerticalShrink = true;
    VerticalStretch = true;

    RequestedWidth = 900;
    MinimumWidth = 400;
    HorizontalStretch = true;
    HorizontalShrink = true;

    Scripts =
        'src/dhx/suite.js',
        'src/dhx/barchart_daily/wrapper.js';

    StartupScript = 'src/dhx/barchart_daily/startupScript.js';

    StyleSheets =
        'src/dhx/suite.css';

    event ControlReady();
    event OnDataPointClicked(SkillCode: Text);
    /// <summary>
    /// Fired by wrapper.js's right-click "Show Data" context menu (see ResolveBarSegmentFromEvent/
    /// ResolveLegendSegmentFromEvent + the contextmenu listener set up in BOOT). This chart has no
    /// per-day breakdown and only ever one series ("Requested Hours") - one bar per Skill Code
    /// plus the synthetic "CAPACITY" aggregate bar (see codeunit 50608's BuildSkillBuffer) - so
    /// there is no BarType/DayIndex to resolve, unlike the live barchart's 4-parameter event.
    /// SegmentId is the clicked bar's category text - a bare Skill Code, or the literal 'CAPACITY'
    /// marker - and is ignored when WholeChart is true. WholeChart is true for a legend-origin
    /// click (this chart's one legend entry generalizes over every skill bar at once - see
    /// codeunit 50608's ShowSegmentData doc comment), false for a single-bar click.
    /// </summary>
    event OnShowSegmentData(SegmentId: Text; WholeChart: Boolean);

    /// <summary>
    /// Fired by wrapper.js's own Refresh/Previous/Today/Next toolbar buttons (see BuildToolbar/
    /// UpdateToolbar there) - a JS-rendered replacement for the BC RefreshAction/PreviousAction/
    /// TodayAction/NextAction actions that page 50707 "Requested vs Capacity Daily P" used to
    /// expose via its own actions() area, retired because BC collapses a CardPart's action bar
    /// into a hidden "..." overflow menu once it's embedded in a Role Center. The toolbar itself
    /// is opt-in per page (chartData.showToolbar, sent only by page 50707's own RefreshChart), so
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
