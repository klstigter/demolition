controladdin DHXRichTextAddin
{
    RequestedHeight = 400;
    MinimumHeight = 200;
    VerticalShrink = true;
    VerticalStretch = true;

    RequestedWidth = 800;
    MinimumWidth = 300;
    HorizontalStretch = true;
    HorizontalShrink = true;

    Scripts =
        'src/dhx/richtext.js',
        'src/dhx/richtext/wrapper.js';

    StartupScript = 'src/dhx/richtext/startupScript.js';

    StyleSheets =
        'src/dhx/richtext.css',
        'src/dhx/richtext/custom.css';

    /// <summary>Fired once the DHTMLX RichText editor is fully initialised and ready to receive data.</summary>
    event ControlReady();

    /// <summary>
    /// Fired ~800 ms after the user stops typing (debounced).
    /// Html – the current HTML content of the editor.
    /// AL should persist this value into the blob field.
    /// </summary>
    event OnTextChanged(Html: Text);

    /// <summary>Pushes HTML content into the editor. Call from ControlReady and OnAfterGetCurrRecord.</summary>
    procedure SetValue(Html: Text);
}
