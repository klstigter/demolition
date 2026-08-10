controladdin DHXBarChartAddin
{
    RequestedHeight = 600;
    MinimumHeight = 400;
    VerticalShrink = true;
    VerticalStretch = true;

    RequestedWidth = 900;
    MinimumWidth = 400;
    HorizontalStretch = true;
    HorizontalShrink = true;

    Scripts =
        'src/dhx/suite.js',
        'src/dhx/barchart/wrapper.js';

    StartupScript = 'src/dhx/barchart/startupScript.js';

    StyleSheets =
        'src/dhx/suite.css';

    event ControlReady();
    event OnDataPointClicked(SkillCode: Text);

    procedure LoadData(ChartDataJson: Text);
}
