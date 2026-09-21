// ============================================================
// DHX Color Field Addin - wrapper.js
// Tiny inline "label + swatch + hex + ..." row that stands in for a Text
// hex-color field. No libraries. AL pushes the value with SetValue and
// listens for OnPickRequested to open its own color picker page.
// ============================================================

var _labelEl = null;
var _swatchEl = null;
var _hexEl = null;

window.BOOT = function () {
    try {
        var addIn = document.getElementById("controlAddIn");
        addIn.className = "cf-root";

        _labelEl = document.createElement("div");
        _labelEl.className = "cf-label";

        var valueEl = document.createElement("div");
        valueEl.className = "cf-value";
        valueEl.addEventListener("click", function () {
            Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("OnPickRequested", []);
        });

        _swatchEl = document.createElement("span");
        _swatchEl.className = "cf-swatch cf-empty";

        _hexEl = document.createElement("span");
        _hexEl.className = "cf-hex";

        var btn = document.createElement("span");
        btn.className = "cf-btn";
        btn.textContent = "...";

        valueEl.appendChild(_swatchEl);
        valueEl.appendChild(_hexEl);
        valueEl.appendChild(btn);
        addIn.appendChild(_labelEl);
        addIn.appendChild(valueEl);

        Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("ControlReady", []);
    } catch (err) {
        console.error("[DHXColorField] BOOT failed:", err);
    }
};

function SetValue(captionText, colorHex) {
    if (!_labelEl) return;
    var hex = colorHex || "";
    _labelEl.textContent = captionText || "";
    _hexEl.textContent = hex;
    if (hex) {
        _swatchEl.className = "cf-swatch";
        _swatchEl.style.background = hex;
    } else {
        _swatchEl.className = "cf-swatch cf-empty";
        _swatchEl.style.background = "";
    }
}
