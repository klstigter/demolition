controladdin "DHX Gantt Control"
{
    RequestedHeight = 1500;
    MinimumHeight = 600;
    VerticalShrink = true;
    VerticalStretch = true;

    RequestedWidth = 1800;
    MinimumWidth = 700;
    HorizontalStretch = true;
    HorizontalShrink = true;

    Scripts =
        'src\dhx\ganttdemo\wrapper.js',
        'src\dhx\dhtmlxgantt.js';

    StartupScript = 'src\dhx\ganttdemo\startupScript.js';

    StyleSheets = 'src/dhx/ganttdemo/style.css',
                  'src/dhx/dhtmlxgantt.css';

    event ControlReady();
    event OnAfterInit();
    event OnAfterTaskUpdate(id: Text; taskJson: Text);

    procedure Init();
    procedure LoadData(ganttdata: Text);

}