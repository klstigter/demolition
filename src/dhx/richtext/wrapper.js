// ============================================================
// DHX RichText Addin – wrapper.js
// Wraps DHTMLX RichText (SVAR / Svelte build) as a BC Control Add-in.
// Constructor export: richtext.Richtext  (capital R, lowercase t).
//
// The editor fills 100 % of the addin container (VerticalStretch = true
// on the ControlAddin), so collapsing General / Workorder FastTabs
// automatically gives more height to the editor.
//
// Loop-break strategy:
//   _lastSentHtml tracks the last HTML value sent to BC.
//   SetValue() updates _lastSentHtml so the echo from BC's
//   OnAfterGetCurrRecord -> SetValue cycle is silently ignored.
// ============================================================

var _editor        = null;   // richtext.Richtext instance
var _debounceTimer = null;   // save-debounce handle
var _lastSentHtml  = null;   // last HTML sent to BC (loop-break)

// ---------------------------------------------------------------
// BOOT – called by startupScript.js once the iframe DOM is ready
// ---------------------------------------------------------------
window.BOOT = function () {
    try {
        var addIn = document.getElementById("controlAddIn");
        addIn.style.cssText =
            "width:100%;height:100%;display:flex;flex-direction:column;" +
            "overflow:hidden;margin:0;padding:0;box-sizing:border-box;";

        var editorDiv       = document.createElement("div");
        editorDiv.id        = "dhx-richtext-editor";
        editorDiv.style.cssText =
            "width:100%;flex:1;min-height:0;display:flex;flex-direction:column;";
        addIn.appendChild(editorDiv);

        if (typeof richtext === "undefined" || typeof richtext.Richtext !== "function") {
            console.error("[DHXRichText] richtext.Richtext constructor not found. " +
                          "Verify richtext.js is listed in ControlAddIn Scripts.");
            return;
        }

        // Correct constructor: richtext.Richtext  (capital R, lowercase t)
        _editor = new richtext.Richtext(editorDiv, {});

        // ------------------------------------------------------------------
        // Clipboard bridge for cut/copy → OS clipboard.
        //
        // ROOT CAUSE: The SVAR/Svelte editor intercepts Ctrl+X on "keydown",
        // removes the selected text from its internal state, and NEVER fires
        // a browser "cut" event.  So all previous approaches waiting on the
        // "cut" event handler were never called.
        //
        // FIX for cut: in the "keydown" CAPTURE phase (runs before the editor's
        // own keydown handler), the selection is still intact.  We write it
        // directly to the OS clipboard via navigator.clipboard.writeText()
        // right there, before the editor touches anything.
        //
        // FIX for copy: the editor does not clear the selection, so the
        // existing "copy" capture approach (e.clipboardData.setData) still works.
        // ------------------------------------------------------------------

        // Helper: write text to OS clipboard using async API or execCommand fallback.
        function _writeClipboard(text) {
            if (navigator.clipboard && navigator.clipboard.writeText) {
                navigator.clipboard.writeText(text).catch(function () {
                    try { document.execCommand("copy"); } catch (e2) {}
                });
            } else {
                try { document.execCommand("copy"); } catch (e2) {}
            }
        }

        // CUT via keyboard (Ctrl/Cmd+X) – write to OS clipboard on keydown BEFORE
        // the editor's own keydown handler removes the selection.
        document.addEventListener("keydown", function (e) {
            if (!((e.ctrlKey || e.metaKey) && e.key === "x")) return;
            var sel = window.getSelection();
            if (!sel || sel.isCollapsed || !sel.rangeCount) return;
            var text = sel.toString();
            if (!text) return;
            _writeClipboard(text);
        }, true);

        // CUT via context menu (right-click → Cut) – browser fires a "cut" event.
        // In capture phase the selection is still intact; we write to clipboard
        // and do NOT call preventDefault so SVAR can still delete the selection.
        document.addEventListener("cut", function (e) {
            var sel = window.getSelection();
            if (!sel || sel.isCollapsed || !sel.rangeCount) return;
            var text = sel.toString();
            if (!text) return;
            _writeClipboard(text);
            // No preventDefault – let SVAR's own cut handler delete the text.
        }, true);

        // COPY – the editor keeps selection intact so we can use clipboardData
        document.addEventListener("copy", function (e) {
            var sel = window.getSelection();
            if (!sel || sel.isCollapsed || !sel.rangeCount) return;
            var text = sel.toString();
            if (!text) return;
            try {
                var range = sel.getRangeAt(0);
                var div   = document.createElement("div");
                div.appendChild(range.cloneContents());
                e.clipboardData.setData("text/plain", text);
                e.clipboardData.setData("text/html",  div.innerHTML);
            } catch (err) {}
        }, true);

        // Change detection via MutationObserver – catches typing, paste, formatting.
        // Only fires OnTextChanged when content actually differs from _lastSentHtml,
        // which prevents the BC Modify → OnAfterGetCurrRecord → SetValue echo loop.
        var observer = new MutationObserver(function () {
            if (_debounceTimer) clearTimeout(_debounceTimer);
            _debounceTimer = setTimeout(function () {
                var html = _editor.getValue();
                if (html === _lastSentHtml) return; // echo from BC reload – ignore
                _lastSentHtml = html;
                Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("OnTextChanged", [html]);
            }, 800);
        });
        observer.observe(editorDiv, {
            childList: true,
            subtree: true,
            characterData: true
        });

        Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("ControlReady", []);
    } catch (err) {
        console.error("[DHXRichText] BOOT failed:", err);
    }
};

// ---------------------------------------------------------------
// SetValue – called from AL to push content into the editor.
// Updates _lastSentHtml first so the MutationObserver sees no
// meaningful diff when the Svelte DOM settles after setValue().
// ---------------------------------------------------------------
function SetValue(html) {
    if (!_editor) return;
    var safeHtml = html || "";
    if (_debounceTimer) {
        clearTimeout(_debounceTimer);
        _debounceTimer = null;
    }
    _lastSentHtml = safeHtml; // mark as "already known" before mutations fire
    _editor.setValue(safeHtml);
}
