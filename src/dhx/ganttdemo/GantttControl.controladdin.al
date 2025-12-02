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

    Scripts = 'src\dhx\dhtmlxgantt.js',
              'src\dhx\ganttdemo\wrapper.js';

    StartupScript = 'src\dhx\ganttdemo\startupScript.js';

    StyleSheets = 'src/dhx/dhtmlxgantt.css',
                  'src/dhx/ganttdemo/style.css';

    event ControlReady();
    event OnAfterInit();
    event OnAfterTaskUpdate(id: Text; taskJson: Text);
    event OnAfterUndo(id: Text; taskJson: Text);
    event OnAfterRedo(id: Text; taskJson: Text);

    procedure Init();
    procedure LoadData(ganttdata: Text);
    procedure Undo();
    procedure Redo();
}