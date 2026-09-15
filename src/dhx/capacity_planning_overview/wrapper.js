// Safety net for the full-page .cpo-loading-overlay - same role as request_assignment/
// wrapper.js's _loadingSafetyTimer: guards against it staying stuck forever if a load cycle's
// hide call (applyPlanningData's own last step) is somehow never reached.
var _cpoLoadingSafetyTimer = null;
// Exposed on window (rather than a local wrapper.js-only function) so capacityPlanningOverview.js's
// showLoading/hideLoading can (re)arm/clear it on EVERY show/hide, not just BOOT's - a "Days to
// show" reload calls showLoading() again long after BOOT, and needs the same safety net.
window._cpoArmLoadingSafetyTimer = function () {
    if (_cpoLoadingSafetyTimer) clearTimeout(_cpoLoadingSafetyTimer);
    _cpoLoadingSafetyTimer = setTimeout(function () {
        if (window.__cpo) window.__cpo.hideLoading();
    }, 180000);
};
window._cpoClearLoadingSafetyTimer = function () {
    if (_cpoLoadingSafetyTimer) { clearTimeout(_cpoLoadingSafetyTimer); _cpoLoadingSafetyTimer = null; }
};

window.BOOT = function BOOT() {
    const host = document.getElementById("controlAddIn");
    host.style.width = "100%";
    host.style.height = "100%";
    host.style.margin = "0";
    host.style.padding = "0";
    host.id = "cpo-root";

    window.__cpo = new CapacityPlanningOverview("cpo-root");
    // Show immediately - earliest point this add-in's own JS runs, well before
    // ControlReady/SetPlanningData's round-trip ever completes (buildLayout, called from the
    // constructor above, is what actually creates #cpo-loading-overlay).
    window.__cpo.showLoading();
    Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("ControlReady", []);
};

window.SetPlanningData = function (PlanningDataJsonTxt) {
    const parsed = JSON.parse(PlanningDataJsonTxt);
    // TEMP DIAGNOSTIC (remove after confirming) - raw values AL actually sent, for side-by-side
    // comparison against the BC-side Message() in page 50618's CapacityPlanningOverviewAct.
    if (parsed.workOrder) {
        alert('JS received: requestedHoursTotal=' + parsed.workOrder.requestedHoursTotal + ' assignedHoursTotal=' + parsed.workOrder.assignedHoursTotal);
    }
    window.__cpo.applyPlanningData(parsed);
};

window.SetColors = function (ColorsJsonTxt) {
    window.__cpo.applyColors(JSON.parse(ColorsJsonTxt));
};

window.LoadCapacityLookup = function (CapacityLookupJsonTxt) {
    window.__cpo.showCapacityModal(JSON.parse(CapacityLookupJsonTxt));
};

// -------------------------------------------------------
// Page Background Task pagination (2026-09-03) - RefreshData (page 50722) sends only this Work
// Order's own lines plus the first ~50-group page of "every other Work Order" data synchronously
// via SetPlanningData; any remaining groups are built off the interactive request path by
// codeunit "CPO BG Other WO Data" and appended via AppendOtherWorkOrderData below, once ready.
// This poll loop is what pulls that result into the control add-in, via a normal JS-initiated
// synchronous trigger (OnPollOtherWorkOrderDataResult), which AL answers by calling
// AppendOtherWorkOrderData itself - from a normal call stack, not the background-task completion
// trigger. Bounded (not indefinite), same 500ms/60-attempt shape as
// src/dhx/request_assignment/wrapper.js's NotifyDayTaskLinesTaskPending/_dayTaskLinesPollTimer.
// -------------------------------------------------------
var _cpoOtherWorkOrderDataPollTimer = null;
var _cpoOtherWorkOrderDataPollAttempts = 0;
var _cpoOtherWorkOrderDataPollActive = false;
var _cpoOtherWorkOrderDataPollInFlight = false;
var CPO_OTHER_WORK_ORDER_DATA_POLL_INTERVAL_MS = 500;
var CPO_OTHER_WORK_ORDER_DATA_POLL_MAX_ATTEMPTS = 60; // 60 x 500ms = 30s generous ceiling

// Rewritten from a raw setInterval to a self-rescheduling setTimeout that only fires the next
// InvokeExtensibilityMethod once the previous one has actually returned (success or error) - a
// fixed-cadence setInterval that ignores whether the prior round trip completed is the exact
// "wrong way" pattern Microsoft's control add-in performance guidance calls out as a trigger for
// the client's "reduced functionality" / unhealthy-add-in warning (see learn.microsoft.com/
// dynamics365/business-central/dev-itpro/developer/devenv-control-addin-bestpractices). Same fix
// as src/dhx/request_assignment/wrapper.js's NotifyDayTaskLinesTaskPending.
window.NotifyOtherWorkOrderDataTaskPending = function NotifyOtherWorkOrderDataTaskPending() {
    try {
        if (window.__cpo) window.__cpo.showBackgroundLoading();
        if (_cpoOtherWorkOrderDataPollTimer) {
            clearTimeout(_cpoOtherWorkOrderDataPollTimer);
            _cpoOtherWorkOrderDataPollTimer = null;
        }
        _cpoOtherWorkOrderDataPollAttempts = 0;
        _cpoOtherWorkOrderDataPollActive = true;
        _scheduleCpoOtherWorkOrderDataPoll();
    } catch (e) {
        console.error("NotifyOtherWorkOrderDataTaskPending failed:", e);
    }
};

function _scheduleCpoOtherWorkOrderDataPoll() {
    if (!_cpoOtherWorkOrderDataPollActive) return;
    _cpoOtherWorkOrderDataPollTimer = setTimeout(_runCpoOtherWorkOrderDataPoll, CPO_OTHER_WORK_ORDER_DATA_POLL_INTERVAL_MS);
}

function _runCpoOtherWorkOrderDataPoll() {
    _cpoOtherWorkOrderDataPollTimer = null;
    if (!_cpoOtherWorkOrderDataPollActive) return;

    _cpoOtherWorkOrderDataPollAttempts++;
    if (_cpoOtherWorkOrderDataPollAttempts > CPO_OTHER_WORK_ORDER_DATA_POLL_MAX_ATTEMPTS) {
        _cpoOtherWorkOrderDataPollActive = false; // generous 30s ceiling already elapsed - give up
        if (window.__cpo) window.__cpo.hideBackgroundLoading(); // safety net - matches _loadingSafetyTimer's role for the full-page overlay, so a task that never completes doesn't leave the badge stuck forever
        return;
    }
    if (_cpoOtherWorkOrderDataPollInFlight) {
        // Previous round trip hasn't returned yet - reschedule instead of piling another call on
        // top of it.
        _scheduleCpoOtherWorkOrderDataPoll();
        return;
    }

    _cpoOtherWorkOrderDataPollInFlight = true;
    var onSettled = function () {
        _cpoOtherWorkOrderDataPollInFlight = false;
        _scheduleCpoOtherWorkOrderDataPoll();
    };
    try {
        Microsoft.Dynamics.NAV.InvokeExtensibilityMethod(
            "OnPollOtherWorkOrderDataResult",
            [],
            false,
            onSettled,
            function (e) {
                console.error("OnPollOtherWorkOrderDataResult poll failed:", e);
                onSettled();
            }
        );
    } catch (e) {
        console.error("OnPollOtherWorkOrderDataResult poll failed:", e);
        onSettled();
    }
}

// Called by AL (from the OnPollOtherWorkOrderDataResult trigger handler) once a pending result
// was actually delivered - stops the poll burst early instead of waiting out the full timeout.
// Setting _cpoOtherWorkOrderDataPollActive false (not just clearing the timer) also blocks the
// in-flight call's own onSettled callback - which fires after this, from the same round trip -
// from resurrecting the loop.
window.StopOtherWorkOrderDataPolling = function StopOtherWorkOrderDataPolling() {
    _cpoOtherWorkOrderDataPollActive = false;
    if (_cpoOtherWorkOrderDataPollTimer) {
        clearTimeout(_cpoOtherWorkOrderDataPollTimer);
        _cpoOtherWorkOrderDataPollTimer = null;
    }
    if (window.__cpo) window.__cpo.hideBackgroundLoading();
};

// AL-callable. Part-page-2 pagination companion to SetPlanningData - appends a background-loaded
// remainder of "dayPlanningLines" (whole Skill+Job No.+Job Task No. groups that didn't fit
// RefreshData's first synchronous page) into the already-rendered add-in, instead of a full
// reset. OtherWorkOrderDataJsonTxt is a plain JSON array (codeunit 50604's CPO_
// BuildOtherWorkOrderLinesJson_ForKeys output - the same per-line shape SetPlanningData's
// "dayPlanningLines" already uses, just not wrapped in a root object). Delegates the actual
// merge/recompute/re-render to the component instance - see its own appendOtherWorkOrderData for
// why this must re-run the shortage engine and re-render sections 1/3/4 (unlike
// request_assignment's simpler append, which only needs a tree rebuild).
window.AppendOtherWorkOrderData = function AppendOtherWorkOrderData(OtherWorkOrderDataJsonTxt) {
    try {
        if (!window.__cpo) return;
        window.__cpo.appendOtherWorkOrderData(JSON.parse(OtherWorkOrderDataJsonTxt));
    } catch (e) {
        console.error("AppendOtherWorkOrderData failed:", e);
    }
};
