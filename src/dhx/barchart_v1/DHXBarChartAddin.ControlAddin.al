controladdin DHXBarChartAddin_v1
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
        'src/dhx/barchart_v1/wrapper.js';

    StartupScript = 'src/dhx/barchart_v1/startupScript.js';

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

    procedure LoadData(ChartDataJson: Text);
}
