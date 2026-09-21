controladdin DHXColorFieldAddin
{
    RequestedHeight = 32;
    MinimumHeight = 32;
    MaximumHeight = 32;
    VerticalShrink = false;
    VerticalStretch = false;

    RequestedWidth = 300;
    MinimumWidth = 200;
    HorizontalStretch = true;
    HorizontalShrink = true;

    Scripts = 'src/dhx/color_field/wrapper.js';

    StartupScript = 'src/dhx/color_field/startupScript.js';

    StyleSheets = 'src/dhx/color_field/custom.css';

    /// <summary>Fired once the DOM is built and the control can receive SetValue calls.</summary>
    event ControlReady();

    /// <summary>Fired when the user clicks the swatch, the hex text or the "..." button. AL is expected to open the color picker and call SetValue again.</summary>
    event OnPickRequested();

    /// <summary>Shows the field label, the colored swatch and the hex text. Empty hex shows a hollow swatch and no text.</summary>
    procedure SetValue(CaptionText: Text; ColorHex: Text);
}
