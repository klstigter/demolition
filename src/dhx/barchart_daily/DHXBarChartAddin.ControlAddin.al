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
    /// ResolveLegendSegmentFromEvent + the contextmenu listener set up in BOOT). Every Skill Code
    /// now renders a Capacity/Requested ("C"/"R") bar PAIR (see codeunit 50608's BuildSkillBuffer/
    /// each page's own RefreshChart) and the legend is series-driven (2026-09-22, matching
    /// src/dhx/barchart_weekly's own legend) - so this stays a plain 2-parameter event, just with
    /// a richer SegmentId now:
    ///   - WholeChart = false (a bar-segment click): SegmentId is that bar's own category text,
    ///     "&lt;SkillCode&gt;|Capacity" or "&lt;SkillCode&gt;|Requested" - codeunit 50608's
    ///     ShowSegmentData splits it back apart.
    ///   - WholeChart = true (a legend-entry click): SegmentId is that series' own name (one of
    ///     the fixed Capacity segment names, the shared "Requested - Assigned" name, or a
    ///     per-skill "&lt;Skill&gt; - Unassigned" name) - codeunit 50608's ShowSegmentData
    ///     resolves which "whole chart" drilldown to broaden to from that name.
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
