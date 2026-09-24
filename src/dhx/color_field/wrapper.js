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

        var resetBtn = document.createElement("span");
        resetBtn.className = "cf-reset-btn";
        // Counter-clockwise circular arrow (Fluent "ArrowReset" style)
        resetBtn.innerHTML =
            '<svg viewBox="0 0 16 16" width="16" height="16" fill="none" stroke="currentColor" ' +
            'stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round">' +
            '<path d="M3.5 6.5A5 5 0 1 1 3 9.5"/><path d="M3.2 2.8v3.9h3.9"/></svg>';
        resetBtn.title = "Reset to default";
        resetBtn.addEventListener("click", function (e) {
            e.stopPropagation();
            Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("OnResetRequested", []);
        });

        var clearBtn = document.createElement("span");
        clearBtn.className = "cf-clear-btn";
        // Thin "dismiss" cross (BC standard clear/remove look)
        clearBtn.innerHTML =
            '<svg viewBox="0 0 16 16" width="16" height="16" fill="none" stroke="currentColor" ' +
            'stroke-width="1.2" stroke-linecap="round">' +
            '<path d="M4 4l8 8M12 4l-8 8"/></svg>';
        clearBtn.title = "Clear";
        clearBtn.addEventListener("click", function (e) {
            e.stopPropagation();
            Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("OnClearRequested", []);
        });

        addIn.appendChild(_labelEl);
        addIn.appendChild(valueEl);
        addIn.appendChild(resetBtn);
        addIn.appendChild(clearBtn);

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
