// Thin BOOT/binding shell for the Role Center dashboard tile - same per-add-in wrapper.js
// convention every other DHX add-in in this repo follows (its own small file, never shared), NOT a
// duplication of capacityPlanningOverview.js's own ~2100 lines of rendering/data logic. Instantiates
// CapacityPlanningDashboard (capacityPlanningDashboard.js, a thin subclass of the shared
// CapacityPlanningOverview - see that file's own doc comment) instead of the base class directly.
//
// Safety net for the full-page .cpo-loading-overlay - same role as
// capacity_planning_overview/wrapper.js's identical timer.
var _cpoDashLoadingSafetyTimer = null;
window._cpoArmLoadingSafetyTimer = function () {
    if (_cpoDashLoadingSafetyTimer) clearTimeout(_cpoDashLoadingSafetyTimer);
    _cpoDashLoadingSafetyTimer = setTimeout(function () {
        if (window.__cpoDashboard) window.__cpoDashboard.hideLoading();
    }, 180000);
};
window._cpoClearLoadingSafetyTimer = function () {
    if (_cpoDashLoadingSafetyTimer) { clearTimeout(_cpoDashLoadingSafetyTimer); _cpoDashLoadingSafetyTimer = null; }
};

window.BOOT = function BOOT() {
    const host = document.getElementById("controlAddIn");
    host.style.width = "100%";
    host.style.height = "100%";
    host.style.margin = "0";
    host.style.padding = "0";
    host.id = "cpo-root";

    window.__cpoDashboard = new CapacityPlanningDashboard("cpo-root");
    window.__cpoDashboard.showLoading();
    Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("ControlReady", []);
};

window.SetPlanningData = function (PlanningDataJsonTxt) {
    window.__cpoDashboard.applyPlanningData(JSON.parse(PlanningDataJsonTxt));
};

window.SetColors = function (ColorsJsonTxt) {
    window.__cpoDashboard.applyColors(JSON.parse(ColorsJsonTxt));
};

// -------------------------------------------------------
// Page Background Task pagination - identical mechanism/shape to
// capacity_planning_overview/wrapper.js's own (see that file's doc comment for the full design);
// on this tile EVERY group is "other" (there is no single inspected Work Order to exclude - see
// codeunit 50604's CPO_BuildDashboardDataJson_Paged), so this is what delivers the bulk of the
// dashboard's own data once the first ~50-group synchronous page isn't enough.
// -------------------------------------------------------
var _cpoDashOtherWorkOrderDataPollTimer = null;
var _cpoDashOtherWorkOrderDataPollAttempts = 0;
var CPO_DASH_OTHER_WORK_ORDER_DATA_POLL_INTERVAL_MS = 500;
var CPO_DASH_OTHER_WORK_ORDER_DATA_POLL_MAX_ATTEMPTS = 60; // 60 x 500ms = 30s generous ceiling

window.NotifyOtherWorkOrderDataTaskPending = function NotifyOtherWorkOrderDataTaskPending() {
    try {
        if (window.__cpoDashboard) window.__cpoDashboard.showBackgroundLoading();
        if (_cpoDashOtherWorkOrderDataPollTimer) {
            clearInterval(_cpoDashOtherWorkOrderDataPollTimer);
            _cpoDashOtherWorkOrderDataPollTimer = null;
        }
        _cpoDashOtherWorkOrderDataPollAttempts = 0;
        _cpoDashOtherWorkOrderDataPollTimer = setInterval(function () {
            _cpoDashOtherWorkOrderDataPollAttempts++;
            if (_cpoDashOtherWorkOrderDataPollAttempts > CPO_DASH_OTHER_WORK_ORDER_DATA_POLL_MAX_ATTEMPTS) {
                clearInterval(_cpoDashOtherWorkOrderDataPollTimer);
                _cpoDashOtherWorkOrderDataPollTimer = null;
                if (window.__cpoDashboard) window.__cpoDashboard.hideBackgroundLoading();
                return;
            }
            try {
                Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("OnPollOtherWorkOrderDataResult", []);
            } catch (e) {
                console.error("OnPollOtherWorkOrderDataResult poll failed:", e);
            }
        }, CPO_DASH_OTHER_WORK_ORDER_DATA_POLL_INTERVAL_MS);
    } catch (e) {
        console.error("NotifyOtherWorkOrderDataTaskPending failed:", e);
    }
};

window.StopOtherWorkOrderDataPolling = function StopOtherWorkOrderDataPolling() {
    if (_cpoDashOtherWorkOrderDataPollTimer) {
        clearInterval(_cpoDashOtherWorkOrderDataPollTimer);
        _cpoDashOtherWorkOrderDataPollTimer = null;
    }
    if (window.__cpoDashboard) window.__cpoDashboard.hideBackgroundLoading();
};

window.AppendOtherWorkOrderData = function AppendOtherWorkOrderData(OtherWorkOrderDataJsonTxt) {
    try {
        if (!window.__cpoDashboard) return;
        window.__cpoDashboard.appendOtherWorkOrderData(JSON.parse(OtherWorkOrderDataJsonTxt));
    } catch (e) {
        console.error("AppendOtherWorkOrderData failed:", e);
    }
};
