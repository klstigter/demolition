/// <summary>
/// Role Center dashboard tile variant of CapacityPlanningOverview (2026-09-04) - a thin subclass,
/// NOT a copy, per explicit instruction to reuse src/dhx/capacity_planning_overview's own
/// components as much as possible and avoid any duplicated functions. Loaded AFTER
/// capacityPlanningOverview.js in this controladdin's own Scripts list (DHXCapacityPlanningDashboardAddin),
/// so the base class already exists when this file parses.
///
/// A Role Center has no single "inspected Work Order" context the way page 50722's own Card page
/// does (SetWorkOrderNo before Run()) - there is nothing here to drag/reschedule against, so
/// Section 2 ("the Work Order's own scheduler") is dropped entirely, and the Confirm-changes button
/// (a per-Work-Order reschedule commit point - see the base class's own bindConfirmButton/
/// confirmChanges doc comments) is removed from the DOM too, since it would otherwise sit on the
/// tile permanently disabled with nothing to confirm.
///
/// Sections 1/3/4 are used UNCHANGED (inherited, not overridden) - AL's own
/// CPO_BuildDashboardDataJson_Paged (codeunit 50604) sends an empty "workOrderSequences": [] and no
/// "workOrder" object, which the base class's existing null-checks already handle correctly on
/// their own (title falls back to "Capacity Planning Overview" - overridden below to a dashboard-
/// appropriate caption instead; capParts()/dailyCapacityRequestData/skillDaySummary/etc. all read
/// dayPlanningLines[]/groups[]/resources[] directly, none of which depend on a "workOrder" being
/// present) - so no other base-class method needs touching.
/// </summary>
class CapacityPlanningDashboard extends CapacityPlanningOverview {
    constructor(containerId) {
        super(containerId);

        // BUG FOUND 2026-09-08 (reported live, flagged "dangerous"): Section 1 ("Calculated
        // conclusion" / "Current position shortage" / the "Hours overview" C/R mini-bars) is the
        // base class's evaluateWO()/currentPositionShortage() - see those methods' own doc
        // comments - which measure ONLY the incremental company-wide shortage caused by placing
        // THIS INSPECTED WORK ORDER'S OWN demand (workOrderSequences[]) on top of everyone else's
        // baseline. On this tile there is no inspected Work Order - AL always sends an EMPTY
        // workOrderSequences[] (see codeunit 50604's CPO_BuildDashboardDataJson_Paged) - so the
        // "before" and "after" maxFlowDay() comparison is always identical (adding zero demand),
        // which makes Section 1 render a CONSTANTLY GREEN "100% / no shortage / 0h" for every
        // single day, regardless of how much real demand Section 4's tree shows for that same day.
        // That is a false "all clear" signal on a capacity-planning tool, not a cosmetic glitch -
        // remove Section 1 entirely from this tile rather than show a number that looks real but
        // is structurally guaranteed to always say "fine". Does NOT affect page 50722's own
        // Capacity Planning Overview (the single-Work-Order card page) - that page always has a
        // real, non-empty workOrderSequences[], so evaluateWO()/currentPositionShortage() there
        // compute genuine, day-varying results.
        const woSummary = document.getElementById('cpo-wo-summary');
        if (woSummary) woSummary.remove();

        // Section 2 host never gets populated (renderWoScheduler is a no-op below) - remove it
        // outright rather than leave an empty div taking up layout space.
        const woSchedulerWrap = document.getElementById('cpo-wo-scheduler-wrap');
        if (woSchedulerWrap) woSchedulerWrap.remove();

        // Nothing on this tile is ever draggable/click-to-reschedule against a specific Work Order
        // (see this class's own doc comment) - the button would otherwise sit here permanently
        // disabled. bindConfirmButton() (called from the base constructor's buildLayout()) already
        // ran and found this same node before this constructor got a chance to remove it; that
        // wiring becomes moot once the node itself is gone.
        const confirmBtn = document.getElementById('cpo-confirm-btn');
        if (confirmBtn) confirmBtn.remove();
    }

    /// <summary>
    /// Thin override, not a duplicate - reuses the base class's ENTIRE implementation via super()
    /// and only corrects the title afterward. Needed because the base class's own applyPlanningData
    /// unconditionally sets #cpo-title's text based on `this.db.workOrder` (falls back to
    /// "Capacity Planning Overview" when absent, which it always is on this tile - see this file's
    /// own class-level doc comment) - EVERY call, including the first one from ControlReady, so a
    /// one-time constructor-level title change (tried initially) gets silently overwritten the
    /// moment real data arrives. Fixing it here, once, is simpler than duplicating
    /// applyPlanningData's ~60-line body just to change one string.
    /// </summary>
    applyPlanningData(json) {
        super.applyPlanningData(json);
        const titleEl = document.getElementById('cpo-title');
        if (titleEl) titleEl.textContent = 'Capacity Planning';
    }

    /// <summary>
    /// No-op override - see this class's own doc comment for why Section 2 doesn't exist on this
    /// tile. Safe by construction, not just by omission: the base class's own renderWorkOrder()
    /// (which a real renderWoScheduler() would otherwise populate this.woScheduler through) already
    /// guards itself with `if (!this.woScheduler) return;`, and this.woScheduler is left at its
    /// constructor default of null forever since this override never sets it - so ANY other
    /// base-class code path that still calls renderWorkOrder() directly (e.g. Section 3's own
    /// click-to-relocate, moveWorkOrderToDay - deliberately left wired, matching the base class
    /// unchanged, since AL always sends an empty workOrderSequences[] for this tile so it has
    /// nothing to relocate either way) harmlessly no-ops too, with no null-reference risk.
    /// measureColumnWidth() (used by Section 3) already falls back to Section 1's own rendered
    /// cell when Section 2 never paints - see that method's own doc comment in the base class.
    /// </summary>
    renderWoScheduler(json) {
        // intentionally empty
    }

    /// <summary>
    /// No-op override - see this class's constructor doc comment for why Section 1 is removed
    /// from this tile (it can only ever report "100%/no shortage", a false all-clear, with no
    /// inspected Work Order). Safe by construction: renderWoSummaryScheduler's own s.init() call
    /// targets '#cpo-wo-summary', which the constructor already removed, and the base class's own
    /// callers (applyPlanningData, resetAnchor-style re-renders) call this unconditionally, so the
    /// override must exist rather than rely on the base method failing safely against a missing
    /// element.
    /// </summary>
    renderWoSummaryScheduler(json) {
        // intentionally empty
    }
}
