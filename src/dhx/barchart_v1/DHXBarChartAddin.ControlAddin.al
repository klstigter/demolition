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

    procedure LoadData(ChartDataJson: Text);
}
