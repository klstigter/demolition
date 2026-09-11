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

// Page Background Task pagination (NotifyOtherWorkOrderDataTaskPending/
// StopOtherWorkOrderDataPolling/AppendOtherWorkOrderData + the poll-timer machinery that used to
// live here) was REMOVED 2026-09-11 - it existed solely to bound the old per-line "groups[]"/
// "dayPlanningLines[]" build (see codeunit 50604's now-removed CPO_BuildDashboardDataJson_Paged),
// which the new SQL-aggregated "skillDayHours[]" query (query 50713 "Day Planning Skill Day Hours")
// makes small enough company-wide that it never needs paging - see capacityPlanningDashboard.js's
// own header doc comment for the full story. page 50722's own wrapper.js keeps this same mechanism
// unchanged - that page's own Section 4 drilldown still needs it.
