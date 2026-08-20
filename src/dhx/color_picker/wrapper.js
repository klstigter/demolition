// ============================================================
// DHX Colorpicker Addin – wrapper.js
// Wraps DHTMLX Suite's Colorpicker widget (dhx.Colorpicker, confirmed via
// direct grep of src/dhx/suite.js - see this app's project memory for the
// full grepped API) as a BC Control Add-in.
//
// This add-in is hosted inline (not as a popup) inside page 50709's own
// StandardDialog modal - the modal itself already provides the OK/Cancel
// chrome, so the picker renders directly into the add-in's own bounds.
//
// Loop-break note: unlike the RichText add-in (src/dhx/richtext/wrapper.js),
// there is no debounce/echo concern here - SetValue() is only ever called
// once, right after ControlReady, to seed the picker with the field's
// current value. Every subsequent user pick flows one-way, JS -> AL, via
// OnColorChanged.
// ============================================================

var _picker = null; // dhx.Colorpicker instance

// ---------------------------------------------------------------
// BOOT – called by startupScript.js once the iframe DOM is ready
// ---------------------------------------------------------------
window.BOOT = function () {
    try {
        var addIn = document.getElementById("controlAddIn");
        addIn.style.cssText =
            "width:100%;height:100%;display:flex;flex-direction:column;" +
            "overflow:auto;margin:0;padding:0;box-sizing:border-box;";

        var pickerDiv = document.createElement("div");
        pickerDiv.id = "dhx-color-picker";
        pickerDiv.style.cssText = "width:100%;";
        addIn.appendChild(pickerDiv);

        if (typeof dhx === "undefined" || typeof dhx.Colorpicker !== "function") {
            console.error("[DHXColorPicker] dhx.Colorpicker constructor not found. " +
                          "Verify suite.js is listed in ControlAddIn Scripts.");
            return;
        }

        // mode: "picker" gives the full hue/saturation/alpha picker plus a manual
        // hex input, rather than "palette" (a fixed swatch grid) - this app's color
        // fields (Unassigned Capacity Color, Envelope Color, Envelope Border Color,
        // Assigned Color, Bar Color) all accept arbitrary hex, so the free-entry
        // picker mode is the right default. transparency: false keeps values to
        // plain 6-digit hex (#RRGGBB), matching every existing field's documented
        // format (e.g. "#7FB3FA") - suite.js's own setValue() truncates an 8-digit
        // value down to 6 when transparency is false, so this is enforced widget-side.
        _picker = new dhx.Colorpicker(pickerDiv, {
            mode: "picker",
            transparency: false
        });

        // "change" fires with the widget's real committed selection on every
        // discrete pick: a palette swatch click, a committed manual hex entry, or a
        // SetValue() call that actually moves focus (see suite.js's own
        // _onColorClick/setValue - both fire "change" with [this._selected]).
        // Deliberately NOT "colorChange" (suite.js marks it "TODO: remove suite_7.0"
        // - a deprecated alias fired alongside "change", not a separate signal) and
        // NOT "apply"/"selectClick" (those only fire from the picker mode's Apply
        // button and would reintroduce the confirm round-trip this feature
        // explicitly avoids - AL should always have the latest picked value cached
        // from "change" alone).
        _picker.events.on("change", function (selectedColor) {
            if (typeof selectedColor !== "string") return;
            Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("OnColorChanged", [selectedColor]);
        });

        Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("ControlReady", []);
    } catch (err) {
        console.error("[DHXColorPicker] BOOT failed:", err);
    }
};

// ---------------------------------------------------------------
// SetValue – called from AL to seed the picker with the field's
// current value. Safe to call before a real hex value exists (blank
// field) - the widget accepts an empty string via clear()-like handling
// in setValue, and simply shows no active selection.
// ---------------------------------------------------------------
function SetValue(colorHex) {
    if (!_picker) return;
    _picker.setValue(colorHex || "");
}
