controladdin DHXColorPickerAddin
{
    RequestedHeight = 420;
    MinimumHeight = 380;
    VerticalShrink = true;
    VerticalStretch = true;

    RequestedWidth = 300;
    MinimumWidth = 260;
    HorizontalStretch = true;
    HorizontalShrink = true;

    Scripts =
        'src/dhx/suite.js',
        'src/dhx/color_picker/wrapper.js';

    StartupScript = 'src/dhx/color_picker/startupScript.js';

    StyleSheets =
        'src/dhx/suite.css',
        'src/dhx/color_picker/custom.css';

    /// <summary>Fired once the DHTMLX Suite Colorpicker widget is fully initialised and ready to receive SetValue calls.</summary>
    event ControlReady();

    /// <summary>
    /// Fired live on every discrete color pick - a palette swatch click, a committed manual hex
    /// entry, or an AL-driven SetValue call that actually changes focus. Wired to the widget's own
    /// "change" event (see the color_picker project memory for why "change" was chosen over the
    /// deprecated "colorChange" alias and over "apply"/"selectClick", which only fire for the
    /// picker-mode Apply button and would reintroduce a confirm round-trip). ColorHex always
    /// carries the widget's latest committed value, so AL never needs to poll the control for it.
    /// </summary>
    event OnColorChanged(ColorHex: Text);

    /// <summary>Seeds/re-seeds the picker with the given hex color. Call from ControlReady and whenever AL needs to reset the displayed selection (e.g. re-opening the lookup with a different field's current value).</summary>
    procedure SetValue(ColorHex: Text);
}
