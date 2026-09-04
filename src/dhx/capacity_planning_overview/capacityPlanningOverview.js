/// <summary>
/// Parses a "yyyy-MM-dd" string into a local-midnight JS Date.
/// </summary>
function cpoParseDateOnly(value) {
    if (!value) return null;
    if (value instanceof Date) return value;
    const parts = String(value).split('-').map(Number);
    const year = parts[0], month = parts[1], day = parts[2];
    if (!year || !month || !day) return null;
    return new Date(year, month - 1, day);
}

/// <summary>Formats a local-midnight JS Date as "yyyy-MM-dd" - the exact inverse of cpoParseDateOnly above, used by confirmChanges (2026-09-04) to tell AL which occurrence's CURRENT Plan Date to match when persisting a per-occurrence reschedule.</summary>
function cpoFormatDateOnly(date) {
    const y = date.getFullYear();
    const m = String(date.getMonth() + 1).padStart(2, '0');
    const d = String(date.getDate()).padStart(2, '0');
    return y + '-' + m + '-' + d;
}

/// <summary>HTML-escapes a value for safe interpolation into template strings (reference's own "esc").</summary>
function cpoEsc(v) {
    return String(v === undefined || v === null || v === '' ? '\u2014' : v).replace(/[&<>"]/g, function (m) {
        return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[m];
    });
}

function cpoIsWeekend(date) {
    return !!date && (date.getDay() === 0 || date.getDay() === 6);
}

function cpoSameDay(a, b) {
    return !!a && !!b && a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate();
}

/// <summary>Formats a JS Date back to "yyyy-MM-dd".</summary>
function cpoIsoDate(date) {
    if (!date) return '';
    const y = date.getFullYear();
    const m = String(date.getMonth() + 1).padStart(2, '0');
    const d = String(date.getDate()).padStart(2, '0');
    return y + '-' + m + '-' + d;
}

/// <summary>Reference's own "slug" - CSS-class-safe skill code.</summary>
function cpoSlug(s) {
    return String(s).toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');
}

/// <summary>Reference's own "hoursText" - "0" hours renders as an em-dash, everything else as "Nh".</summary>
function cpoHoursText(v) {
    return Number(v) > 0 ? (Math.round(Number(v) * 10) / 10) + 'h' : '\u2014';
}

/// <summary>
/// This add-in's version of the reference prototype's DHTMLXtempv112-app.js (C:\Users\Ahmad\
/// OneDrive\x\PROJECT\KLAAS\CPO_v131). PORTED PER AN EXPLICIT ARCHITECTURE-REVERSAL DECISION
/// (2026-09-02): an earlier pass had this add-in compute shortage/coverage with a simplified
/// AL-side "sum team capacity minus other-WO-assigned-hours" formula, deliberately WITHOUT the
/// reference's own client-side multi-skill max-flow optimizer, to save engineering effort. That
/// simplified formula had a real bug (company-wide resource pools produced 5700%+ coverage
/// numbers) and the user explicitly asked for the real algorithm back - a correctly-implemented
/// max-flow model's achievable coverage is capped by DEMAND, not supply, so it does not have that
/// bug even against a broad resource pool. This file is therefore now a NEAR-VERBATIM port of the
/// reference's own maxFlowDay/evaluateWO/currentPositionShortage/idxWork/workOrderExtra engine and
/// its buildCentralSections/skillDaySummary/taskDaySummary/sequenceDayLines/sequenceDayCellHtml
/// section-4 tree builder and its capParts/dailyCapacityRequestData section-3 daily-bars builder -
/// function names/bodies kept as close to the original as reasonably possible for future
/// maintainability. AL's own job has correspondingly SHRUNK to building one JSON payload shaped
/// like the reference's own mock "window.DHTMLXPlannerData" object (skills[]/resources[]/
/// baseCapacity/externalFree[]/groups[]/dayPlanningLines[]/workOrderSequences[]) from real
/// Business Central data - see codeunit 50604 "DHX Data Handler"'s CPO_BuildPlanningDataJson.
///
/// Deliberate structural deviations from the reference (everything else ported as closely as
/// reasonably possible):
/// 1. The reference reads `const db = window.DHTMLXPlannerData` ONCE at module load (a standalone
///    page). This is a BC control add-in - data arrives asynchronously via SetPlanningData, and can
///    arrive AGAIN (Days-to-show change, Reset position). So `db`/`dates`/`skills`/etc become
///    per-instance fields (this.db, this.dates, ...) rebuilt on every applyPlanningData() call,
///    instead of module-scope consts computed once. The reference's own init() (buildLayout +
///    create every section) is correspondingly split: buildLayout() runs ONCE (constructor, builds
///    the static DOM shell only DHTMLX will not later recreate), everything else re-runs on every
///    applyPlanningData() call.
/// 2. maxFlowDay/evaluateWO/currentPositionShortage are genuinely expensive (Edmonds-Karp-style
///    augmenting-path search) - the reference's own toy dataset (10 resources, 4 skills) never
///    needed caching, but real BC data can have far larger resource pools (this codebase's own
///    project memory notes a demo company seeding 100+ resources for a single skill), and every
///    section-1 day CELL's class+value template calls evaluateWO(idx)/currentPositionShortage()
///    with no memoization of its own in the reference. This port adds per-render-pass caching
///    (this._evalWOCache, this._currentPositionShortageArr/_currentPositionSkillShortageArr,
///    cleared by applyPlanningData()/resetAnchorDependentCaches()) so DHTMLX's own repeated
///    template invocations don't re-run the same max-flow computation many times over. AL's own
///    CPO_MaxResourcesPerSkill cap (15/skill) is the OTHER half of keeping this tractable in a real
///    browser - see that procedure's own doc comment.
/// 3. Section 4 (the Skill/Job-Task/Sequence tree) legitimately does NOT depend on `woAnchor` at
///    all in the reference either (its cells read real calendar dates directly, not anchor-relative
///    offsets) - matching the reference exactly, renderCentralTree() runs once per
///    applyPlanningData() call, never re-run by renderWorkOrder()/moveWorkOrderToDay() the way
///    sections 1/2/3 are.
/// 4. This add-in's own "Days to show" JS-owned input (bindDaysToShowInput) and window-resize
///    section-3 realignment (bindResizeRealign) are UNRELATED to this pivot and kept exactly as
///    they worked before it.
/// 5. CROSS-WORK-ORDER SCOPE (2026-09-03, explicit user correction - see codeunit 50604's own
///    CPO_BuildPlanningDataJson doc comment for the AL-side story): db.dayPlanningLines[] now
///    mixes the inspected Work Order's own rows with every OTHER Work Order's rows in the same
///    visible window, each row tagged with a real "workOrderNo". Section 1/2 and section 3's own
///    "Requested" bar (dailyCapacityRequestData) stay scoped to the inspected Work Order via an
///    explicit `line.workOrderNo === (this.db.workOrder && this.db.workOrder.no)` check; section
///    4's own line-matching (skillDaySummary/taskDaySummary/sequenceDayLines) does the OPPOSITE
///    check (`!==`) since section 4's db.groups[] is now built AL-side from every OTHER Work
///    Order's demand exclusively - "everything else going on in this window, except the one
///    being inspected". section 3's capParts() "assigned"/freeInt total is deliberately NOT
///    workOrderNo-filtered - a resource committed to another WO that day is genuinely unavailable,
///    so that side was already correctly company-wide before this change.
/// </summary>
class CapacityPlanningOverview {
    constructor(containerId) {
        this.containerId = containerId;
        this.db = null;
        this.dates = [];
        this.skills = [];
        this.skillMetaByCode = {};
        this.BASE_CAP = 8;
        this.startDate = null;
        this.endDate = null;
        // Per-OCCURRENCE anchor map (2026-09-04 redesign, replacing the single shared woAnchor,
        // then a per-SEQUENCE-ROW anchor - see occurrenceKey's own doc comment for why sequence
        // granularity still wasn't fine enough) - keyed by occurrenceKey(seq, wd)
        // ('job|task|skill|sequenceNo|workday'), each value is that ONE individual Day Planning
        // occurrence's own day-index. Dragging one bar in section 2 now moves ONLY that bar (see
        // the onEventChanged handler in renderWoScheduler), never any other occurrence of the same
        // sequence, let alone another row - the user explicitly reported anything coarser as a bug
        // ("I want effected on 15 sep only, the others of day plannings should be stay same").
        // Section 3's click-to-relocate (moveWorkOrderToDay) is DELIBERATELY still a bulk action -
        // it sets EVERY occurrence at once (preserving their relative workday spacing via
        // idxWork), unchanged from the old shared-woAnchor behavior (explicit user correction:
        // "Section 3 should relocate the whole group as it does today") - the two input paths are
        // intentionally asymmetric.
        this.occurrenceAnchors = {};
        // Cross-row (Sequence No.) reassignment tracking (2026-09-04) - see moveOccurrenceToSequence's
        // own doc comment for why this is needed on top of occurrenceAnchors alone.
        this.pendingSequenceMoves = {};
        this._bulkAnchorHint = null; // cosmetic only - see renderCapacityBars' own comment on cpo-wo-anchor-day
        this.woSummaryScheduler = null;
        this.woScheduler = null;
        this.centralTreeScheduler = null;
        this._evalWOCache = {};
        this._currentPositionShortageArr = null;
        this._currentPositionSkillShortageArr = null;
        this._baseRequests = null;
        this._baselineWithoutWO = null;
        this._treeSummaryIndex = null;
        this._scrollLock = false;
        this._treeChipTooltipBound = false;
        this._hasUnconfirmedChanges = false;
        this.buildLayout();
    }

    // ================================================================================
    // DOM shell / "Days to show" input / resize realign - unrelated to the max-flow pivot, kept
    // as-is from before it.
    // ================================================================================

    buildLayout() {
        const host = document.getElementById(this.containerId);
        if (!host) return;
        host.innerHTML =
            '<div class="cpo-top-bar">' +
            '<div class="cpo-top-title" id="cpo-title">Capacity Planning Overview</div>' +
            '<button id="cpo-confirm-btn" class="cpo-confirm-btn" type="button" disabled>Confirm changes</button>' +
            '<div class="cpo-inline-loading" id="cpo-bg-loading"><span class="cpo-spinner"></span><span>Loading more data...</span></div>' +
            '<label class="cpo-days-to-show"><span>Days to show</span><input type="number" id="cpo-days-to-show-input" min="1" max="365" step="1"></label>' +
            '</div>' +
            '<div id="cpo-wo-summary" class="cpo-scheduler-host cpo-wo-summary-host"></div>' +
            // Same wrapper-vs-render-target split as section 4 below (see its own comment) -
            // applies equally to DHTMLX's row-squeezing behavior here, just less likely to be
            // visibly triggered when this WO only has a few sequences.
            '<div id="cpo-wo-scheduler-wrap" class="cpo-scheduler-host cpo-wo-scheduler-host">' +
            '<div id="cpo-wo-scheduler" class="cpo-scheduler-host"></div>' +
            '</div>' +
            '<div id="cpo-capacity-bars" class="cpo-capacity-bars"></div>' +
            // Two nested divs, not one: DHTMLX Scheduler reads ITS OWN init-target element's
            // clientHeight and fits rendered row content to exactly that height (shrinking rows
            // rather than overflowing) - confirmed live via getBoundingClientRect()/scrollHeight,
            // this happens even with dy/folder_dy/section_autoheight:false all set. So the actual
            // DHTMLX render target (#cpo-central-tree, still what s.init() points at) must stay
            // height-UNCONSTRAINED (natural rowCount*dy height, can genuinely exceed the wrapper),
            // while THIS outer wrapper (#cpo-central-tree-wrap) carries the MIN/MAX-clamped height
            // + overflow-y:auto that actually clips/scrolls it - the wrapper is what
            // applyCentralTreeHeight below now sizes, not the DHTMLX target itself.
            '<div id="cpo-central-tree-wrap" class="cpo-scheduler-host cpo-central-tree-host">' +
            '<div id="cpo-central-tree" class="cpo-scheduler-host"></div>' +
            '</div>' +
            '<div id="cpo-shared-scroll" class="cpo-shared-scroll"><div id="cpo-shared-scroll-inner" class="cpo-shared-scroll-inner"></div></div>' +
            '<div id="cpo-event-tip" class="cpo-event-tip"></div>' +
            '<div id="cpo-daily-summary-tip" class="cpo-daily-summary-tip"></div>' +
            '<div id="cpo-loading-overlay" class="cpo-loading-overlay"><span class="cpo-spinner"></span></div>';

        if (!host.style.position) host.style.position = 'relative';
        this.bindDaysToShowInput();
        this.bindConfirmButton();
        this.bindResizeRealign();
    }

    bindResizeRealign() {
        const self = this;
        let timer = null;
        window.addEventListener('resize', function () {
            if (timer) clearTimeout(timer);
            timer = setTimeout(function () {
                if (!self.db) return;
                self.measuredColumnWidth = self.measureColumnWidth();
                self.renderCapacityBars(self.db);
            }, 150);
        });
    }

    bindDaysToShowInput() {
        const input = document.getElementById('cpo-days-to-show-input');
        if (!input) return;
        const self = this;
        const commit = function () {
            let n = parseInt(input.value, 10);
            if (!n || n <= 0) n = 30;
            if (typeof Microsoft !== 'undefined') {
                // Re-triggers AL's RefreshData -> full SetPlanningData round-trip, same as the
                // initial load - show the same blocking spinner while it rebuilds.
                self.showLoading();
                Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('OnDaysToShowChanged', [n]);
            }
        };
        input.addEventListener('change', commit);
        input.addEventListener('keydown', function (e) {
            if (e.key === 'Enter') { commit(); input.blur(); }
        });
    }

    /// <summary>
    /// Reschedule (section 2 drag - per-row now, section 3 click-to-relocate - still bulk, see
    /// moveWorkOrderToDay's own comment) is pure client-side simulation (2026-09-04 redesign, per
    /// the user's explicit ask) - moving one or more sequences' own anchors and re-rendering
    /// sections 1-3 from data already in JS needs no BC round-trip at all (profiling the OLD
    /// per-action InvokeExtensibilityMethod('OnRescheduleWorkOrder', ...) call showed the call
    /// itself was near-instant, but firing one on every single drag/click still meant paying real
    /// network latency for nothing useful yet). Now every local move just calls
    /// markUnconfirmedChange() to enable this button instead of touching AL at all; the ONE
    /// deliberate BC round-trip point is this button, clicked once the user is happy with wherever
    /// they've dragged/clicked the schedule to - and (2026-09-04) OnRescheduleWorkOrder now really
    /// does persist it (page 50722's PersistReschedule), no longer a no-op stub.
    /// </summary>
    bindConfirmButton() {
        const self = this;
        const btn = document.getElementById('cpo-confirm-btn');
        if (!btn) return;
        btn.onclick = function () {
            if (!self._hasUnconfirmedChanges) return;
            self.confirmChanges();
        };
    }

    /// <summary>Enables/highlights the Confirm button - called after every local reschedule move (moveWorkOrderToDay, the section 2 drag handler) instead of any AL invoke.</summary>
    markUnconfirmedChange() {
        this._hasUnconfirmedChanges = true;
        this.updateConfirmButtonState();
    }

    updateConfirmButtonState() {
        const btn = document.getElementById('cpo-confirm-btn');
        if (!btn) return;
        btn.disabled = !this._hasUnconfirmedChanges;
        btn.classList.toggle('cpo-confirm-btn-pending', this._hasUnconfirmedChanges);
    }

    /// <summary>
    /// The one deliberate BC round-trip point for a reschedule - sends one entry per INDIVIDUALLY-
    /// moved occurrence (2026-09-04: per-occurrence, not per-sequence-row or one shared woAnchor -
    /// see occurrenceAnchors' own doc comment), rather than one call per intermediate drag/click.
    /// Only occurrences actually present in occurrenceAnchors AND whose current day-index differs
    /// from their natural never-moved position (idxWork(0, wd)) are sent - an untouched occurrence,
    /// or one section 3 happened to bulk-relocate back to exactly where it already was, has nothing
    /// to persist. `fromDate` (that natural position's calendar date - i.e. whatever Plan Date this
    /// occurrence currently has IN BC, since occurrenceAnchors is always empty right after a fresh
    /// load) is what lets AL's PersistReschedule find the SPECIFIC Day Planning line among however
    /// many share the same Job/Task/Skill/SequenceNo - `shift` alone (as used by the WO-level and
    /// sequence-level designs this replaced) could no longer disambiguate which of several dates
    /// under one sequence was the one actually dragged. DayShift (the first invoke arg) is sent as
    /// 0 and otherwise unused now; PayloadJsonTxt carries the real data as
    /// {shifts:[{job,task,skill,sequenceNo,fromDate,shift,toSequenceNo},...]}.
    ///
    /// Cross-row moves (2026-09-04, moveOccurrenceToSequence/pendingSequenceMoves) are folded into
    /// this same loop rather than a separate payload shape: for an occurrence with a pending move,
    /// `sequenceNo`/`fromDate` are read from pendingSequenceMoves' TRUE ORIGINAL identity (what's
    /// still actually in BC right now), not from the current seq/wd - which, post-move, is a
    /// synthetic local-only identity (see moveOccurrenceToSequence's own comment). `toSequenceNo`
    /// is only included when a move is pending, so PersistReschedule can tell "just a date shift"
    /// (no such field) apart from "also reassign Sequence No." - and the `newIdx === originalIdx`
    /// early-return below is skipped for a pending move even with zero date delta, since dropping
    /// straight onto a same-day vacant slot in another row is still a real change to persist.
    ///
    /// hideLoading right after the invoke returns matches openCapacityLookup's own stub-invoke
    /// pattern elsewhere in this file - PersistReschedule (page 50722) is synchronous within this
    /// one trigger call and calls RefreshData() itself once done, so by the time this JS call
    /// returns the persist has either already fully happened or errored out natively; there is no
    /// separate async completion callback to wait for.
    /// </summary>
    confirmChanges() {
        this.showLoading();
        if (typeof Microsoft !== 'undefined') {
            const self = this;
            const shifts = [];
            (this.db.workOrderSequences || []).forEach(function (seq) {
                (seq.workdays || []).forEach(function (wd) {
                    const key = self.occurrenceKey(seq, wd);
                    if (!Object.prototype.hasOwnProperty.call(self.occurrenceAnchors, key)) return;
                    const pendingMove = self.pendingSequenceMoves[key];
                    const originalWd = pendingMove ? pendingMove.originalWd : wd;
                    const originalSequenceNo = pendingMove ? pendingMove.originalSequenceNo : seq.sequenceNo;
                    const originalIdx = self.idxWork(0, originalWd);
                    const newIdx = self.occurrenceAnchors[key];
                    if (!pendingMove && newIdx === originalIdx) return;
                    const originalDate = self.dates[originalIdx];
                    if (!originalDate) return;
                    // sequenceNo/toSequenceNo always sent as NUMBERs (0 for blank/unset) - NOT the
                    // `|| ''` fallback used elsewhere in this file for display purposes - so AL's
                    // own "Sequence No." field (Integer) can parse them directly with no separate
                    // string-vs-number branch (see PersistReschedule's own comment).
                    const entry = {
                        job: seq.job, task: seq.task, skill: seq.skill, sequenceNo: Number(originalSequenceNo) || 0,
                        fromDate: cpoFormatDateOnly(originalDate), shift: newIdx - originalIdx
                    };
                    if (pendingMove) entry.toSequenceNo = Number(seq.sequenceNo) || 0;
                    shifts.push(entry);
                });
            });
            Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('OnRescheduleWorkOrder', [0, JSON.stringify({ shifts: shifts })]);
        }
        this._hasUnconfirmedChanges = false;
        this.updateConfirmButtonState();
        this.hideLoading();
    }

    /// <summary>
    /// Full-host blocking spinner (style.css's .cpo-loading-overlay) for a load/reload that
    /// replaces ALL of this WO's data - there is nothing worth interacting with underneath yet, so
    /// blocking it is correct, unlike showBackgroundLoading below. wrapper.js's BOOT shows this at
    /// the earliest point this add-in's own JS runs (well before ControlReady's round-trip
    /// completes); its SetPlanningData hides it right after applyPlanningData finishes rendering -
    /// that hide is the user's actual "processing is done, safe to act" signal. Also
    /// shown/hidden around an OnDaysToShowChanged reload (bindDaysToShowInput below), since that
    /// re-triggers the exact same full RefreshData/SetPlanningData round-trip.
    /// </summary>
    showLoading() {
        const el = document.getElementById('cpo-loading-overlay');
        if (el) el.style.display = 'flex';
        if (typeof window._cpoArmLoadingSafetyTimer === 'function') window._cpoArmLoadingSafetyTimer();
    }
    hideLoading() {
        const el = document.getElementById('cpo-loading-overlay');
        if (el) el.style.display = 'none';
        if (typeof window._cpoClearLoadingSafetyTimer === 'function') window._cpoClearLoadingSafetyTimer();
    }

    /// <summary>
    /// Wraps a synchronous, GENUINELY slow (multi-second) unit of PURE client-side work with the
    /// same showLoading/hideLoading signal used for a full data reload - currently only
    /// setTreeOpenState's Expand/Collapse-all rebuild (bindHierarchyButtons below) qualifies;
    /// moveWorkOrderToDay/the section 2 drag handler's renderWorkOrder call used to be wrapped here
    /// too, but at only ~100-150ms it never needed a spinner and the ~5s+ delay a user could see
    /// from it was this wrapper's OWN double-rAF overhead being starved on a page with an
    /// unrelated, already-bloated DOM (see moveWorkOrderToDay's own comment) - not a real cost of
    /// the render itself, so it was removed from that path rather than kept "just in case".
    /// Calling showLoading() and running heavy synchronous work in the very same tick would never
    /// let the browser get a chance to actually PAINT the overlay before the work blocks the
    /// thread, since nothing in that path ever returns control to the browser on its own - the
    /// double requestAnimationFrame here forces one real paint first; confirmed live via a
    /// MutationObserver on #cpo-loading-overlay's style attribute, the overlay reliably shows and
    /// holds for the full multi-second Expand/Collapse-all rebuild before hiding again. NOT needed
    /// around InvokeExtensibilityMethod itself elsewhere in this file (openCapacityLookup, the
    /// section 4 chip click, confirmChanges) - that call is fire-and-forget from JS's own
    /// perspective (confirmed live: it returns in under a millisecond, well before AL's own trigger
    /// handler finishes running - any real response comes back later through a separate AL-to-JS
    /// call, e.g. SetPlanningData), so showLoading() called right before it already gets a real
    /// paint for free.
    /// </summary>
    runBusy(fn) {
        this.showLoading();
        const self = this;
        requestAnimationFrame(function () {
            requestAnimationFrame(function () {
                try { fn(); } finally { self.hideLoading(); }
            });
        });
    }

    /// <summary>
    /// Toggles the small non-blocking top-bar spinner badge for the OTHER-Work-Order background
    /// pagination task (see style.css's .cpo-inline-loading doc comment for why this must stay
    /// non-blocking, unlike showLoading above) - shown by wrapper.js's
    /// NotifyOtherWorkOrderDataTaskPending when the poll loop starts, hidden once
    /// StopOtherWorkOrderDataPolling fires (a result was delivered, whether or not it actually had
    /// lines to merge - see appendOtherWorkOrderData) or the poll's own 30s ceiling is hit, so the
    /// user sees it disappear exactly when Section 4's "other work orders" totals become complete
    /// (or the load gave up) and it's safe to act.
    /// </summary>
    showBackgroundLoading() {
        const el = document.getElementById('cpo-bg-loading');
        if (el) el.style.display = 'flex';
    }
    hideBackgroundLoading() {
        const el = document.getElementById('cpo-bg-loading');
        if (el) el.style.display = 'none';
    }

    // ================================================================================
    // Data entry point
    // ================================================================================

    applyPlanningData(json) {
        this.db = json || {};
        this.skills = Array.isArray(this.db.skills) ? this.db.skills.map(function (x) { return x.code; }) : [];
        this.skillMetaByCode = {};
        (this.db.skills || []).forEach((s) => { this.skillMetaByCode[s.code] = s; });
        this.BASE_CAP = this.db.baseCapacity || 8;
        this.startDate = cpoParseDateOnly(this.db.startDate);
        this.endDate = cpoParseDateOnly(this.db.endDate);

        this.dates = [];
        if (this.startDate && this.endDate) {
            for (let d = new Date(this.startDate); d <= this.endDate; d = new Date(d.getTime() + 86400000)) this.dates.push(new Date(d));
        }
        // The visible window's own start (dates[0]) doubles as the reference's implicit
        // workday-offset anchor (offset 1 = the first workday at/after StartDate - see codeunit
        // 50604's CPO_ComputeWorkdayOffset) - every occurrence starts un-overridden (empty map, so
        // getOccurrenceDayIndex falls back to its natural idxWork(0, wd) position - exactly
        // wherever AL's fresh workOrderSequences[] currently has it), matching the reference's own
        // `let woAnchor=0` for the exact same reason, just per-occurrence now instead of one shared
        // value (see this class's own constructor comment on occurrenceAnchors).
        this.occurrenceAnchors = {};
        this.pendingSequenceMoves = {};
        this._bulkAnchorHint = null; // cosmetic only - see renderCapacityBars' own comment on cpo-wo-anchor-day
        this._hasUnconfirmedChanges = false; // fresh server data - any earlier unconfirmed local moves are moot

        this._evalWOCache = {};
        this._currentPositionShortageArr = null;
        this._currentPositionSkillShortageArr = null;
        this._baseRequests = this.aggregateRequests();
        this._baselineWithoutWO = this.aggregateOutstandingRequestsWithoutWO();
        this._treeSummaryIndex = null;

        const titleEl = document.getElementById('cpo-title');
        if (titleEl) {
            // The Work Order's OWN description ("Snag List Resolution"), NOT its parent
            // Project's description ("Work Order Demo Data") - the previous version read the
            // wrong field.
            titleEl.textContent = (this.db.workOrder)
                ? 'Workorder ' + this.db.workOrder.no + (this.db.workOrder.description ? (' | ' + this.db.workOrder.description) : '')
                : 'Capacity Planning Overview';
        }

        const daysInput = document.getElementById('cpo-days-to-show-input');
        if (daysInput && this.db.daysToShow) daysInput.value = this.db.daysToShow;

        this.renderWoSummaryScheduler(this.db);
        // renderWoScheduler ends by calling this.renderWorkOrder(), which itself renders section 3
        // once using whatever this.measuredColumnWidth currently is (undefined on first load, so
        // it falls back to the COLUMN_WIDTH constant) - measureColumnWidth() can only read a REAL
        // rendered day-column cell, which does not exist until section 2 has painted at least once.
        this.renderWoScheduler(this.db);
        // Now that section 2 has real cells, measure the actual column width and re-render section
        // 3 once more with the correct value (cheap - see measureColumnWidth's own doc comment for
        // why this can't be done in the other order).
        this.measuredColumnWidth = this.measureColumnWidth();
        this.renderCapacityBars(this.db);
        this.renderCentralTree(this.db);
        this.bindScrollSync();
        this.updateConfirmButtonState(); // fresh server data - clears the Confirm button's pending/enabled look too
        // True last step of every full load/reload cycle (initial ControlReady or a "Days to
        // show" change) - always hide, even on a re-entrant call, so the overlay never gets stuck;
        // this is the user's actual "processing is done, ready for the next action" signal.
        this.hideLoading();
    }

    /// <summary>
    /// Page Background Task pagination companion to applyPlanningData (2026-09-03) - merges a
    /// background-loaded remainder of "dayPlanningLines" (whole Skill+Job No.+Job Task No. groups
    /// that didn't fit RefreshData's first synchronous page, built by codeunit "CPO BG Other WO
    /// Data") into the already-rendered add-in, WITHOUT a full reset.
    ///
    /// Unlike request_assignment's much simpler AppendDayTaskLines (which only needs a tree
    /// rebuild - its board just displays rows, it doesn't derive anything FROM them), CPO's
    /// shortage/coverage engine (maxFlowDay/evaluateWO/currentPositionShortage) and section 3's
    /// capacity bars are COMPUTED from the full company-wide dayPlanningLines set (capParts()'s
    /// "assigned" sum, aggregateOutstandingRequestsWithoutWO()'s baseline) - so every derived cache
    /// must be invalidated and sections 1/3/4 re-rendered once more of that set arrives. Section 2
    /// (this WO's own scheduler) is untouched - its own source (workOrderSequences[]) was always
    /// sent complete on the first SetPlanningData call, never paginated, so appending more OTHER
    /// Work Orders' lines can't add anything Section 2 would show. "groups[]" (Section 4's tree
    /// skeleton - which skills/Job/Task nodes exist) is likewise always already complete from the
    /// first call (a cheap, never-paginated pre-scan AL-side - see codeunit 50604's
    /// CPO_BuildPlanningDataJson_Paged doc comment) - only the LINES (chip-level detail) inside
    /// already-existing groups are what this call backfills, so renderCentralTree() just needs to
    /// re-run against the now-more-complete this.db.dayPlanningLines, no groups[] merge needed.
    /// </summary>
    appendOtherWorkOrderData(rawLines) {
        if (!this.db) return;
        const lines = Array.isArray(rawLines) ? rawLines : [];
        if (!lines.length) return;

        if (!Array.isArray(this.db.dayPlanningLines)) this.db.dayPlanningLines = [];
        this.db.dayPlanningLines.push(...lines);

        // Every cache derived from the (now more complete) dayPlanningLines set is stale -
        // same caches applyPlanningData() itself resets on a full load.
        this._evalWOCache = {};
        this._currentPositionShortageArr = null;
        this._currentPositionSkillShortageArr = null;
        this._baseRequests = this.aggregateRequests();
        this._baselineWithoutWO = this.aggregateOutstandingRequestsWithoutWO();
        this._treeSummaryIndex = null;

        this.renderWoSummaryScheduler(this.db);
        this.renderCapacityBars(this.db);
        this.renderCentralTree(this.db);
        this.bindScrollSync();
    }

    /// <summary>Clears the two sequence-anchor-dependent caches (NOT this._evalWOCache, which is independent of every sequence's own anchor) - call after any anchor change (a single-row drag, or Section 3's bulk click-to-relocate).</summary>
    resetAnchorDependentCaches() {
        this._currentPositionShortageArr = null;
        this._currentPositionSkillShortageArr = null;
    }

    /// <summary>
    /// Reads the ACTUAL rendered day-column pixel width off a real, already-painted
    /// ".dhx_matrix_cell" - DHTMLX's own `column_width` config is just a hint; it auto-stretches
    /// every day column to fill however much width the host div's own CSS gives it whenever that's
    /// wider than column_width*dayCount (always true here), so section 3's plain-HTML day divs must
    /// match that ACTUAL rendered width, not the configured constant, to stay pixel-aligned with
    /// sections 1/2/4's real DHTMLX Scheduler instances.
    /// </summary>
    measureColumnWidth() {
        const cell = document.querySelector('#cpo-wo-scheduler .dhx_matrix_cell') || document.querySelector('#cpo-wo-summary .dhx_matrix_cell');
        const width = cell ? cell.getBoundingClientRect().width : 0;
        return width > 0 ? width : CapacityPlanningOverview.COLUMN_WIDTH;
    }

    /// <summary>Skill metadata lookup (color/textColor/border/dark/light) - reference's own "skillMeta". Falls back to a generic blue if the skill is unknown (defensive - should not happen for any skill AL actually sent).</summary>
    skillMeta(skill) {
        return this.skillMetaByCode[skill] || (this.db.skills && this.db.skills[0]) || { color: '#8fb7ee', border: '#5f8fd8', dark: '#5f8fd8', light: '#dbe8fb', textColor: '#26344e' };
    }
    /// <summary>Alias kept for readability at call sites that specifically want "the color pair for this skill" rather than the full meta object - same data either way.</summary>
    skillColorFor(skill) { return this.skillMeta(skill); }

    // ================================================================================
    // Ported date/index helpers - reference's dayIndex/dplDayIndex/assignedDayIndex/
    // resourceAssignedHours/resourceRemaining (DHTMLXtempv112-app.js ~L30-40).
    // ================================================================================

    dayIndex(date) {
        if (!date || !this.startDate) return -1;
        return Math.round((new Date(date.getFullYear(), date.getMonth(), date.getDate()) - this.startDate) / 86400000);
    }
    dplDayIndex(line) { return this.dayIndex(cpoParseDateOnly(line.requestDate)); }
    assignedDayIndex(line) { return line.assignedDate ? this.dayIndex(cpoParseDateOnly(line.assignedDate)) : -1; }
    resourceAssignedHours(resourceName, dayIdx) {
        const lines = this.db.dayPlanningLines || [];
        let sum = 0;
        for (let i = 0; i < lines.length; i++) {
            const l = lines[i];
            if (l.assignedResourceNo === resourceName && this.assignedDayIndex(l) === dayIdx) sum += Number(l.assignedHours) || 0;
        }
        return sum;
    }
    resourceRemaining(r, dayIdx) {
        if (dayIdx < 0 || dayIdx >= this.dates.length || cpoIsWeekend(this.dates[dayIdx])) return 0;
        return Math.max(0, this.BASE_CAP - this.resourceAssignedHours(r.name, dayIdx));
    }

    // ================================================================================
    // Ported demand aggregation - reference's aggregateRequests/selectedWOKeys/
    // aggregateOutstandingRequestsWithoutWO (DHTMLXtempv112-app.js ~L77-102).
    // ================================================================================

    aggregateRequests() {
        const self = this;
        const out = this.dates.map(function () { const o = {}; self.skills.forEach(function (s) { o[s] = 0; }); return o; });
        (this.db.dayPlanningLines || []).forEach((line) => {
            const i = this.dplDayIndex(line);
            if (out[i]) out[i][line.requestedSkill] = (out[i][line.requestedSkill] || 0) + (Number(line.requestedHours) || 0);
        });
        return out;
    }

    selectedWOKeys() {
        const set = {};
        (this.db.workOrderSequences || []).forEach(function (s) { set[s.job + '|' + s.task] = true; });
        return set;
    }

    /// <summary>
    /// "Outstanding demand from every OTHER Job/Task NOT part of this WO's own sequences" - this is
    /// the baseline every day's max-flow "before" comparison is measured against, so evaluateWO's
    /// "added shortage" isolates the marginal effect of THIS Work Order's own demand.
    /// </summary>
    aggregateOutstandingRequestsWithoutWO() {
        const self = this;
        const selected = this.selectedWOKeys();
        const out = this.dates.map(function () { const o = {}; self.skills.forEach(function (s) { o[s] = 0; }); return o; });
        (this.db.dayPlanningLines || []).forEach((line) => {
            if (selected[line.job + '|' + line.task]) return;
            const i = this.dplDayIndex(line);
            if (!out[i]) return;
            const requested = Number(line.requestedHours) || 0;
            const assigned = Math.min(requested, Number(line.assignedHours) || 0);
            const outstanding = Math.max(0, requested - assigned);
            out[i][line.requestedSkill] = (out[i][line.requestedSkill] || 0) + outstanding;
        });
        return out;
    }

    // ================================================================================
    // The max-flow shortage/coverage engine - near-verbatim port of the reference's maxFlowDay/
    // idxWork/workOrderExtra/evaluateWO/currentPositionShortage/currentPositionSkillShortage
    // (DHTMLXtempv112-app.js ~L104-197). Source/resource-nodes/skill-nodes/sink flow network,
    // Edmonds-Karp-style BFS augmenting-path max-flow - same algorithm, same node numbering
    // convention, same edge-capacity rules (resource->skill edges are effectively uncapped at
    // 9999; skill->sink edges carry that day's requested hours for that skill).
    // ================================================================================

    /// <summary>
    /// Computes max-flow for ONE day given a {skill: requestedHours} map, matching resource supply
    /// (this.resourceRemaining) against demand via a flow network: source -> one node per resource
    /// (capacity = that resource's remaining hours that day) -> one node per skill the resource
    /// holds (uncapped) -> sink (capacity = that skill's requested hours). The resulting matched
    /// flow per skill is CAPPED BY DEMAND, not supply - this is the property that makes a broad
    /// real resource pool safe to feed in (unlike the earlier simplified sum-of-capacity formula,
    /// a bigger pool cannot inflate coverage past 100%).
    /// </summary>
    maxFlowDay(dayIdx, requestMap) {
        const dates = this.dates, skills = this.skills, resources = this.db.resources || [];
        if (dayIdx < 0 || dayIdx >= dates.length || cpoIsWeekend(dates[dayIdx])) {
            const bySkill = {};
            skills.forEach(function (s) { bySkill[s] = { requested: 0, matched: 0, shortage: 0, coverage: 100 }; });
            return { totalRequested: 0, totalMatched: 0, totalShortage: 0, bySkill: bySkill };
        }
        const R = resources.length, S = skills.length, source = 0, r0 = 1, s0 = r0 + R, sink = s0 + S, N = sink + 1;
        const cap = []; for (let i = 0; i < N; i++) cap.push(new Array(N).fill(0));
        const orig = []; for (let i = 0; i < N; i++) orig.push(new Array(N).fill(0));
        const add = function (u, v, c) { cap[u][v] += c; orig[u][v] += c; };
        const self = this;
        resources.forEach(function (r, ri) {
            add(source, r0 + ri, self.resourceRemaining(r, dayIdx));
            (r.skills || []).forEach(function (sk) { const si = skills.indexOf(sk); if (si >= 0) add(r0 + ri, s0 + si, 9999); });
        });
        skills.forEach(function (sk, si) { add(s0 + si, sink, requestMap[sk] || 0); });

        let flow = 0;
        while (true) {
            const parent = new Array(N).fill(-1); parent[source] = source;
            const q = [source];
            for (let qi = 0; qi < q.length && parent[sink] === -1; qi++) {
                const u = q[qi];
                for (let v = 0; v < N; v++) if (parent[v] === -1 && cap[u][v] > 1e-9) { parent[v] = u; q.push(v); if (v === sink) break; }
            }
            if (parent[sink] === -1) break;
            let aug = Infinity;
            for (let v = sink; v !== source; v = parent[v]) aug = Math.min(aug, cap[parent[v]][v]);
            for (let v = sink; v !== source; v = parent[v]) { const u = parent[v]; cap[u][v] -= aug; cap[v][u] += aug; }
            flow += aug;
        }

        const bySkill = {};
        let totalRequested = 0;
        skills.forEach(function (sk, si) {
            const requested = requestMap[sk] || 0;
            const matched = orig[s0 + si][sink] - cap[s0 + si][sink];
            const shortage = Math.max(0, requested - matched);
            bySkill[sk] = { requested: requested, matched: matched, shortage: shortage, coverage: requested ? Math.round(matched / requested * 100) : 100 };
            totalRequested += requested;
        });
        return { totalRequested: totalRequested, totalMatched: flow, totalShortage: Math.max(0, totalRequested - flow), bySkill: bySkill };
    }

    /// <summary>Walks forward from day index `start`, landing on the `wd`-th workday (1-based, weekends skipped) - reference's own "idxWork".</summary>
    idxWork(start, wd) {
        const dates = this.dates;
        let i = start;
        while (i < dates.length && cpoIsWeekend(dates[i])) i++;
        let c = 1;
        while (i < dates.length && c < wd) { i++; while (i < dates.length && cpoIsWeekend(dates[i])) i++; c++; }
        return i;
    }
    maxVisibleWOWorkday() {
        let m = 1;
        (this.db.workOrderSequences || []).forEach(function (s) { (s.workdays || []).forEach(function (w) { if (w > m) m = w; }); });
        return m;
    }
    validStart(i) {
        return i >= 0 && i < this.dates.length && !cpoIsWeekend(this.dates[i]) && this.idxWork(i, this.maxVisibleWOWorkday()) < this.dates.length;
    }

    /// <summary>
    /// Stable per-OCCURRENCE identity for occurrenceAnchors (2026-09-04, replacing an earlier
    /// per-SEQUENCE-ROW design) - one sequence row (Skill+Job+Task+SequenceNo) can carry several
    /// individually-dated occurrences (workOrderSequences[].workdays[], each a real Day Planning
    /// line), and the user explicitly corrected that dragging ONE of those must not move the
    /// others: "I want effected on 15 sep only, the others of day plannings should be stay same".
    /// `wd` (the workday number) is part of the key precisely so each occurrence under the same
    /// sequence gets its own independent slot.
    /// </summary>
    occurrenceKey(seq, wd) {
        return (seq.job || '') + '|' + (seq.task || '') + '|' + (seq.skill || '') + '|' + (seq.sequenceNo == null ? '' : seq.sequenceNo) + '|' + wd;
    }
    /// <summary>This occurrence's CURRENT day-index - its own override if it was moved (individually or by section 3's bulk relocate), else its natural, never-moved position (idxWork(0, wd), which is exactly wherever AL's own workOrderSequences[] currently has it, since occurrenceAnchors is empty on every fresh load).</summary>
    getOccurrenceDayIndex(seq, wd) {
        const key = this.occurrenceKey(seq, wd);
        return Object.prototype.hasOwnProperty.call(this.occurrenceAnchors, key) ? this.occurrenceAnchors[key] : this.idxWork(0, wd);
    }
    setOccurrenceDayIndex(seq, wd, dayIndex) {
        this.occurrenceAnchors[this.occurrenceKey(seq, wd)] = dayIndex;
    }

    /// <summary>
    /// Cross-row reassignment (2026-09-04, explicit user request: "as long as same skill, and
    /// there is vacant sequence for a day then user must able to move single day planning from
    /// sequence 2 into sequence 1 in same day") - moves ONE occurrence out of `sourceSeq.workdays`
    /// and into `targetSeq.workdays`, landing at `targetDayIndex`. Deliberately narrower than the
    /// user's literal wording per their own follow-up answer: only allowed between two sequences
    /// that share the same Job No./Job Task No. (just a different Sequence No.) AND the same
    /// Skill, and only onto a genuinely vacant slot (no existing occurrence of targetSeq already
    /// sitting on that exact day) - returns false and mutates nothing on any mismatch, letting the
    /// caller's unconditional renderWorkOrder() snap the dragged bar back to its untouched origin.
    ///
    /// `wd` numbers are otherwise just a per-sequence identity tag (idxWork(0, wd) only matters as
    /// a FALLBACK default position - see getOccurrenceDayIndex), so reusing the source's own `wd`
    /// on the target is fine UNLESS targetSeq already has an unrelated occurrence tagged with that
    /// same number (their identity keys would collide and overwrite each other) - in that case the
    /// smallest free integer above it is used instead.
    ///
    /// pendingSequenceMoves tracks the TRUE original (job/task/skill/sequenceNo/wd - i.e. exactly
    /// what's still persisted in BC right now) for confirmChanges to find later, since after this
    /// move idxWork(0, newWd) under targetSeq no longer corresponds to any real BC date/sequence -
    /// it's a synthetic identity that only exists locally until Confirm. Carries the ORIGINAL
    /// identity forward (not just "whatever it was one move ago") so a same-session move-then-move
    /// (A into B, then B into C, before ever confirming) still traces back to the one real BC
    /// record - see confirmChanges' own doc comment for how this is consumed.
    /// </summary>
    moveOccurrenceToSequence(sourceSeqIndex, wd, targetSeqIndex, targetDayIndex) {
        const sequences = (this.db && this.db.workOrderSequences) || [];
        const sourceSeq = sequences[sourceSeqIndex];
        const targetSeq = sequences[targetSeqIndex];
        if (!sourceSeq || !targetSeq || sourceSeq === targetSeq) return false;
        if (sourceSeq.job !== targetSeq.job || sourceSeq.task !== targetSeq.task || sourceSeq.skill !== targetSeq.skill) return false;
        if (!Array.isArray(sourceSeq.workdays) || sourceSeq.workdays.indexOf(wd) === -1) return false;

        const self = this;
        const targetWorkdays = Array.isArray(targetSeq.workdays) ? targetSeq.workdays : (targetSeq.workdays = []);
        const occupied = targetWorkdays.some(function (existingWd) { return self.getOccurrenceDayIndex(targetSeq, existingWd) === targetDayIndex; });
        if (occupied) return false;

        const oldKey = this.occurrenceKey(sourceSeq, wd);
        const priorMove = this.pendingSequenceMoves[oldKey];
        const trueOriginalSequenceNo = priorMove ? priorMove.originalSequenceNo : sourceSeq.sequenceNo;
        const trueOriginalWd = priorMove ? priorMove.originalWd : wd;
        const hours = sourceSeq.hoursByWorkday ? sourceSeq.hoursByWorkday[wd] : undefined;

        sourceSeq.workdays.splice(sourceSeq.workdays.indexOf(wd), 1);
        if (sourceSeq.hoursByWorkday) delete sourceSeq.hoursByWorkday[wd];
        delete this.occurrenceAnchors[oldKey];
        if (priorMove) delete this.pendingSequenceMoves[oldKey];

        let newWd = wd;
        while (targetWorkdays.indexOf(newWd) !== -1) newWd++;
        targetWorkdays.push(newWd);
        targetWorkdays.sort(function (a, b) { return a - b; });
        if (!targetSeq.hoursByWorkday) targetSeq.hoursByWorkday = {};
        if (hours != null) targetSeq.hoursByWorkday[newWd] = hours;
        this.setOccurrenceDayIndex(targetSeq, newWd, targetDayIndex);

        this.pendingSequenceMoves[this.occurrenceKey(targetSeq, newWd)] = {
            originalSequenceNo: trueOriginalSequenceNo,
            originalWd: trueOriginalWd
        };
        return true;
    }

    /// <summary>Places this Work Order's own workOrderSequences[] demand at candidate anchor `start`, returning a per-day {skill: hours} map - reference's own "workOrderExtra". Still takes ONE uniform `start` for every sequence - only used by evaluateWO's "if the whole WO were placed starting on day X" per-day scan (section 1's "Calculated conclusion" row), a different, unchanged feature from the per-sequence current-position placement below.</summary>
    workOrderExtra(start) {
        const self = this;
        const extra = this.dates.map(function () { const o = {}; self.skills.forEach(function (s) { o[s] = 0; }); return o; });
        (this.db.workOrderSequences || []).forEach(function (seq) {
            (seq.workdays || []).forEach(function (wd) {
                const idx = self.idxWork(start, wd);
                if (idx < self.dates.length) {
                    const hrs = (seq.hoursByWorkday && seq.hoursByWorkday[wd] != null) ? Number(seq.hoursByWorkday[wd]) : 8;
                    extra[idx][seq.skill] = (extra[idx][seq.skill] || 0) + hrs;
                }
            });
        });
        return extra;
    }
    /// <summary>
    /// Per-OCCURRENCE version of workOrderExtra (2026-09-04) - each individual occurrence is placed
    /// at ITS OWN current day-index (getOccurrenceDayIndex) instead of one shared `start` for the
    /// whole WO. Used by currentPositionShortage/currentPositionSkillShortage (section 1's "Current
    /// position shortage" row) and renderWorkOrder (section 2's own bar placement) - both need
    /// "wherever each occurrence ACTUALLY currently sits", not evaluateWO's uniform hypothetical.
    /// </summary>
    workOrderExtraCurrent() {
        const self = this;
        const extra = this.dates.map(function () { const o = {}; self.skills.forEach(function (s) { o[s] = 0; }); return o; });
        (this.db.workOrderSequences || []).forEach(function (seq) {
            (seq.workdays || []).forEach(function (wd) {
                const idx = self.getOccurrenceDayIndex(seq, wd);
                if (idx >= 0 && idx < self.dates.length) {
                    const hrs = (seq.hoursByWorkday && seq.hoursByWorkday[wd] != null) ? Number(seq.hoursByWorkday[wd]) : 8;
                    extra[idx][seq.skill] = (extra[idx][seq.skill] || 0) + hrs;
                }
            });
        });
        return extra;
    }
    /// <summary>Total company-wide added shortage if this WO's own demand were placed starting at day `start`, plus the resulting coverage % - reference's own "evaluateWO". Cached per `start` for the lifetime of the current payload (see this class's own doc comment on caching).</summary>
    evaluateWO(start) {
        if (Object.prototype.hasOwnProperty.call(this._evalWOCache, start)) return this._evalWOCache[start];
        let result;
        if (!this.validStart(start)) {
            result = null;
        } else {
            const extra = this.workOrderExtra(start);
            let addedShortage = 0, total = 0;
            for (let i = 0; i < this.dates.length; i++) {
                const before = this.maxFlowDay(i, this._baselineWithoutWO[i]);
                const combined = {};
                this.skills.forEach((s) => { combined[s] = (this._baselineWithoutWO[i][s] || 0) + (extra[i][s] || 0); });
                const after = this.maxFlowDay(i, combined);
                addedShortage += Math.max(0, after.totalShortage - before.totalShortage);
                total += this.skills.reduce(function (a, s) { return a + (extra[i][s] || 0); }, 0);
            }
            result = { coverage: total ? Math.round((total - addedShortage) / total * 100) : 100, addedShortage: addedShortage };
        }
        this._evalWOCache[start] = result;
        return result;
    }
    /// <summary>Per-day added shortage caused specifically by this WO's demand at each sequence's CURRENT (independent, 2026-09-04) anchor position - reference's own "currentPositionShortage", now summed from workOrderExtraCurrent() instead of one shared woAnchor. Cached until the next resetAnchorDependentCaches() (any anchor change) or applyPlanningData() call.</summary>
    currentPositionShortage() {
        if (this._currentPositionShortageArr) return this._currentPositionShortageArr;
        const extra = this.workOrderExtraCurrent();
        const out = this.dates.map((d, i) => {
            if (cpoIsWeekend(d)) return null;
            const before = this.maxFlowDay(i, this._baselineWithoutWO[i]);
            const combined = {};
            this.skills.forEach((s) => { combined[s] = (this._baselineWithoutWO[i][s] || 0) + (extra[i][s] || 0); });
            const after = this.maxFlowDay(i, combined);
            return Math.max(0, after.totalShortage - before.totalShortage);
        });
        this._currentPositionShortageArr = out;
        return out;
    }
    /// <summary>Same as currentPositionShortage but broken out per skill - reference's own "currentPositionSkillShortage", used by renderWorkOrder() to allocate each day's shortage across the sequence rows actually contributing to it.</summary>
    currentPositionSkillShortage() {
        if (this._currentPositionSkillShortageArr) return this._currentPositionSkillShortageArr;
        const self = this;
        const extra = this.workOrderExtraCurrent();
        const out = this.dates.map(function () { const o = {}; self.skills.forEach(function (s) { o[s] = 0; }); return o; });
        for (let i = 0; i < this.dates.length; i++) {
            if (cpoIsWeekend(this.dates[i])) continue;
            const before = this.maxFlowDay(i, this._baselineWithoutWO[i]);
            const combined = {};
            this.skills.forEach((s) => { combined[s] = (this._baselineWithoutWO[i][s] || 0) + (extra[i][s] || 0); });
            const after = this.maxFlowDay(i, combined);
            this.skills.forEach(function (s) {
                out[i][s] = Math.max(0, (after.bySkill[s] ? after.bySkill[s].shortage : 0) - (before.bySkill[s] ? before.bySkill[s].shortage : 0));
            });
        }
        this._currentPositionSkillShortageArr = out;
        return out;
    }

    // ================================================================================
    // Shared base Scheduler config / view-teardown - unchanged from before this pivot.
    // ================================================================================

    configureBaseScheduler(s) {
        s.config.drag_create = false;
        s.config.drag_resize = false;
        s.config.details_on_create = false;
        s.config.details_on_dblclick = false;
        s.config.readonly_form = true;
        s.config.header = [];
        if (s.xy) s.xy.nav_height = 0;
    }
    teardownView(s, name) {
        if (s.matrix && s.matrix[name]) {
            if (typeof s.deleteView === 'function') s.deleteView(name);
            delete s.matrix[name];
        }
    }

    // ================================================================================
    // Section 1 - Stats header (2-row synthetic Scheduler timeline, cell_template HTML). Near-
    // verbatim port of the reference's createWorkOrderSummaryScheduler/
    // workordersummary_cell_class/_cell_value (DHTMLXtempv112-app.js ~L211-253) - every cell reads
    // this.evaluateWO(idx)/this.currentPositionShortage()[idx] LIVE at render time instead of a
    // pre-computed AL "statsRows" array.
    // ================================================================================

    renderWoSummaryScheduler(json) {
        if (typeof Scheduler === 'undefined') {
            console.error('CapacityPlanningOverview: DHX Scheduler library not loaded.');
            return;
        }
        if (!this.woSummaryScheduler) this.woSummaryScheduler = Scheduler.getSchedulerInstance();
        const s = this.woSummaryScheduler;
        s.plugins({ timeline: true });
        this.configureBaseScheduler(s);
        this.teardownView(s, 'workordersummary');

        if (this.dates.length === 0) return;

        const self = this;
        const sections = [
            { key: 'fit', section_id: 'fit', label: 'Calculated conclusion' },
            { key: 'shortage', section_id: 'shortage', label: 'Current position shortage' }
        ];

        s.createTimelineView({
            name: 'workordersummary',
            render: 'bar',
            x_unit: 'day',
            x_step: 1,
            x_size: this.dates.length,
            x_date: '%d %M',
            first_hour: 6,
            last_hour: 18,
            y_unit: sections,
            y_property: 'section_id',
            dy: CapacityPlanningOverview.CALC_ROW_HEIGHT,
            section_autoheight: false,
            column_width: CapacityPlanningOverview.COLUMN_WIDTH,
            dx: CapacityPlanningOverview.ROW_LABEL_WIDTH,
            scrollable: true,
            cell_template: true,
            scale_height: CapacityPlanningOverview.SCALE_HEIGHT
        });

        s.date.workordersummary_start = function () { return self.dates[0]; };
        s.templates.workordersummary_scalex_class = function (date) { return cpoIsWeekend(date) ? 'cpo-weekend-scale' : ''; };
        s.templates.workordersummary_row_class = function (section) { return section.key === 'shortage' ? 'cpo-wo-summary-divider' : ''; };
        s.templates.workordersummary_cell_class = function (evs, date, section) {
            const idx = self.dayIndex(date);
            if (cpoIsWeekend(date)) return 'cpo-weekend-cell';
            if (section.key === 'fit') {
                const ev = self.evaluateWO(idx);
                if (!ev) return 'cpo-wo-fit-off';
                return ev.addedShortage === 0 ? 'cpo-wo-fit-good' : (ev.coverage >= 85 ? 'cpo-wo-fit-tight' : 'cpo-wo-fit-bad');
            }
            if (section.key === 'shortage') {
                const val = self.currentPositionShortage()[idx] || 0;
                const cls = val === 0 ? 'cpo-wo-short-good' : (val <= 8 ? 'cpo-wo-short-small' : 'cpo-wo-short-bad');
                return cls + ' cpo-wo-summary-divider-cell';
            }
            return '';
        };
        s.templates.workordersummary_cell_value = function (evs, date, section) {
            const idx = self.dayIndex(date);
            if (idx < 0 || idx >= self.dates.length) return '';
            if (section.key === 'fit') {
                if (cpoIsWeekend(date)) return '<div class="cpo-wo-cell-text"><b>\u2014</b><small>off</small></div>';
                const ev = self.evaluateWO(idx);
                if (!ev) return '<div class="cpo-wo-cell-text"><b>\u2014</b><small>outside</small></div>';
                return '<div class="cpo-wo-cell-text"><b>' + ev.coverage + '%</b><small>' + (ev.addedShortage ? ('+' + ev.addedShortage + 'h shortage') : 'no shortage') + '</small></div>';
            }
            if (section.key === 'shortage') {
                if (cpoIsWeekend(date)) return '<div class="cpo-wo-cell-text"><b>\u2014</b><small>off</small></div>';
                const v = self.currentPositionShortage()[idx] || 0;
                return '<div class="cpo-wo-cell-text"><b>' + v + 'h</b><small>' + (v ? 'caused by WO' : 'no shortage') + '</small></div>';
            }
            return '';
        };

        s.init('cpo-wo-summary', this.dates[0], 'workordersummary');
    }

    // ================================================================================
    // Section 2 - the WO's own Day Planning sequence rows, a REAL Scheduler timeline with native
    // drag. Near-verbatim port of the reference's createWorkOrderScheduler/renderWorkOrder/
    // workOrderAssignmentState (DHTMLXtempv112-app.js ~L255-372) - events are positioned via
    // idxWork(anchor, workday-offset), same as the reference's own idxWork(woAnchor, ...), except
    // `anchor` is now EACH INDIVIDUAL OCCURRENCE's own independent getOccurrenceDayIndex(seq, wd)
    // (2026-09-04), not one shared value for the whole WO, nor even one shared value per sequence
    // row - dragging a bar shifts ONLY that one occurrence and re-renders client-side; nothing
    // reaches AL until the user clicks Confirm (§3.1/§13.1x - see bindConfirmButton/confirmChanges).
    // ================================================================================

    renderWoScheduler(json) {
        if (typeof Scheduler === 'undefined') {
            console.error('CapacityPlanningOverview: DHX Scheduler library not loaded.');
            return;
        }
        if (!this.woScheduler) this.woScheduler = Scheduler.getSchedulerInstance();
        const s = this.woScheduler;
        s.plugins({ timeline: true, tooltip: true });
        this.configureBaseScheduler(s);
        s.config.drag_move = true;
        s.config.drag_resize = false;
        this.teardownView(s, 'workorder');

        const sequences = Array.isArray(json && json.workOrderSequences) ? json.workOrderSequences : [];

        if (this.dates.length === 0) {
            this.applySchedulerContainerHeight(0);
            return;
        }

        const self = this;
        const sections = sequences.map(function (seqObj, i) {
            const meta = self.skillMeta(seqObj.skill);
            return {
                key: 'seq:' + i,
                section_id: 'seq:' + i,
                label: '<span class="cpo-wo-sequence-label" style="color:' + (meta.border || meta.dark) + '">' + cpoEsc(seqObj.job) + ' - ' + cpoEsc(seqObj.task) + ' ' + cpoEsc(seqObj.skill) + ' SeqNo ' + cpoEsc(seqObj.sequenceNo || '') + '</span>',
                skill: seqObj.skill, job: seqObj.job, task: seqObj.task, sequenceNo: seqObj.sequenceNo || '', lineNo: seqObj.lineNo
            };
        });
        if (sections.length === 0) sections.push({ key: 'nodata', section_id: 'nodata', label: 'No Day Planning lines' });
        this.applySchedulerContainerHeight(sections.length);

        s.createTimelineView({
            name: 'workorder',
            render: 'bar',
            x_unit: 'day',
            x_step: 1,
            x_size: this.dates.length,
            x_date: '%d %M',
            first_hour: 6,
            last_hour: 18,
            y_unit: sections,
            y_property: 'section_id',
            dy: CapacityPlanningOverview.ROW_HEIGHT,
            event_dy: CapacityPlanningOverview.ROW_HEIGHT - 8,
            section_autoheight: false,
            column_width: CapacityPlanningOverview.COLUMN_WIDTH,
            dx: CapacityPlanningOverview.ROW_LABEL_WIDTH,
            scrollable: true,
            cell_template: false,
            // Own independent header (2026-09-04) - matches section 4's own long-standing pattern
            // instead of section 1's (see applySchedulerContainerHeight's own comment and this
            // section's updated doc comment for why relying on a SIBLING instance's header was the
            // actual root cause of a user-reported horizontal-scroll visual seam between sections
            // 1 and 2, and why giving each instance its own header removes the need for the two to
            // ever stay pixel-continuous with each other).
            scale_height: CapacityPlanningOverview.SCALE_HEIGHT
        });

        s.date.workorder_start = function () { return self.dates[0]; };
        s.templates.workorder_scalex_class = function (date) { return cpoIsWeekend(date) ? 'cpo-weekend-scale' : ''; };
        s.templates.workorder_cell_class = function (evs, date) { return cpoIsWeekend(date) ? 'cpo-weekend-cell' : ''; };
        s.templates.workorder_cell_value = function () { return ''; };
        s.templates.event_class = function (a, b, e) { return 'cpo-planner-event cpo-wo-request-event cpo-skill-' + cpoSlug(e.skill) + ((Number(e.shortageHours) || 0) > 0 ? ' cpo-wo-capacity-shortage' : ''); };
        s.templates.event_bar_text = function (a, b, e) {
            const meta = self.skillMeta(e.skill);
            const pct = Math.max(0, Math.min(100, Number(e.assignedPct) || 0));
            const shortage = Number(e.shortageHours) || 0;
            const caption = shortage > 0
                ? '<span class="cpo-wo-event-main">' + e.hours + 'h</span><span class="cpo-wo-event-shortage-caption">Shortage ' + shortage + 'h</span>'
                : '<span class="cpo-wo-event-main">' + e.hours + 'h</span>';
            return '<span class="cpo-wo-event-heat" style="background:linear-gradient(to right,' + meta.dark + ' 0 ' + pct + '%,' + meta.light + ' ' + pct + '% 100%)">' + caption + '</span>';
        };
        s.attachEvent('onClick', function (id) {
            const ev = s.getEvent(id);
            self.openCapacityLookup(ev.dayIndex, ev.skill);
            return true;
        });
        // Moves ONLY the dragged bar's own single occurrence (2026-09-04 redesign, per explicit
        // user correction: dragging one date of a multi-date sequence must not move the sequence's
        // OTHER dates) - `ev` already carries the exact job/task/skill/sequenceNo/workday fields
        // occurrenceKey() needs (see renderWorkOrder's own events.push), so no lookup into
        // workOrderSequences[] is needed to identify which occurrence this drag belongs to.
        // Deliberately asymmetric with Section 3's click-to-relocate (moveWorkOrderToDay), which is
        // a bulk action by explicit user request - this is the "single day planning shift" path,
        // that is the "whole group" path. No relative-shift math needed here at all: the drop
        // position IS the new absolute day-index for this one occurrence.
        s.attachEvent('onEventChanged', function (id, ev) {
            const target = self.dayIndex(ev.start_date);
            // Vertical drag onto a DIFFERENT sequence row (2026-09-04, explicit user request: "as
            // long as same skill, and there is vacant sequence for a day then user must able to
            // move single day planning from sequence 2 into sequence 1 in same day") - DHTMLX
            // already writes the DROP TARGET's section_id straight onto `ev` for a units-based
            // timeline view; `ev.seqIndex` (set once in renderWorkOrder's own events.push, never
            // touched by DHTMLX) is still this bar's ORIGINAL row, so comparing the two tells us a
            // row change was attempted. moveOccurrenceToSequence validates same Job/Task/Skill +
            // target-day vacancy itself and is a no-op (returns false, mutates nothing) on any
            // mismatch - the unconditional renderWorkOrder() below then naturally snaps an invalid
            // drop back to its untouched origin, since it always rebuilds purely from
            // workOrderSequences/occurrenceAnchors, never from the DOM's own post-drag state.
            const droppedSeqIndex = parseInt(String(ev.section_id).split(':')[1], 10);
            const rowChanged = !isNaN(droppedSeqIndex) && ev.seqIndex != null && droppedSeqIndex !== ev.seqIndex;
            if (target >= 0 && target < self.dates.length && !cpoIsWeekend(self.dates[target])) {
                if (rowChanged) {
                    self.moveOccurrenceToSequence(ev.seqIndex, ev.workday, droppedSeqIndex, target);
                } else {
                    self.setOccurrenceDayIndex(ev, ev.workday, target);
                }
            }
            // renderWorkOrder() deferred to setTimeout(0) (2026-09-04) - it does a destructive
            // woScheduler.clearAll()+parse() (a full rebuild of every event's DOM), and running
            // that SYNCHRONOUSLY inside onEventChanged (DHTMLX's own drag-completion callback) risks
            // DHTMLX still being mid-way through its own post-drag DOM cleanup for the JUST-DRAGGED
            // element when we rip out the whole event set out from under it - a known category of
            // drag-and-drop bug (leaves a stale/duplicate "ghost" bar behind), reported live: after
            // dragging one occurrence of a two-occurrence sequence row, a third pale/ghost chip
            // appeared at the drop target while both original chips stayed in place. Deferring one
            // tick lets DHTMLX fully finish handling the drop first. Pure client-side simulation
            // either way (2026-09-04 redesign) - no AL round-trip per drag, no runBusy overlay
            // (renderWorkOrder's own cost is a real but small ~100-150ms of synchronous JS, not
            // worth a spinner flash for). markUnconfirmedChange enables the Confirm button instead -
            // see its own/bindConfirmButton's doc comment for the full reasoning on why this moved
            // off a per-action BC call.
            setTimeout(function () {
                self.resetAnchorDependentCaches();
                self.renderWorkOrder();
                self.markUnconfirmedChange();
            }, 0);
            return true;
        });

        s.init('cpo-wo-scheduler', this.dates[0], 'workorder');
        this.attachEventTooltip(s, 'cpo-wo-scheduler');
        this.renderWorkOrder();
    }

    /// <summary>Per-day/per-sequence assigned%/resource/time summary for the sequence rows' event bars - reference's own "workOrderAssignmentState".</summary>
    workOrderAssignmentState(seq, dayIdx) {
        if (dayIdx < 0 || dayIdx >= this.dates.length) return { pct: 0, resource: '', assignedTime: '\u2014' };
        // workOrderNo equality (2026-09-03 addition) - db.workOrderSequences[] (seq) is always the
        // INSPECTED Work Order's own data, but db.dayPlanningLines now also carries every OTHER
        // Work Order's rows (see this file's own architecture-pivot doc comment) - without this
        // check, an other WO's line that coincidentally shares job/task/skill/sequenceNo with this
        // WO's own sequence would double up into this WO's own assignment stats.
        const woNo = this.db.workOrder && this.db.workOrder.no;
        const lines = (this.db.dayPlanningLines || []).filter((line) =>
            line.workOrderNo === woNo &&
            line.job === seq.job &&
            line.task === seq.task &&
            line.requestedSkill === seq.skill &&
            String(line.sequenceNo == null ? '' : line.sequenceNo) === String(seq.sequenceNo == null ? '' : seq.sequenceNo) &&
            this.dplDayIndex(line) === dayIdx
        );
        const requested = lines.reduce(function (n, line) { return n + (Number(line.requestedHours) || 0); }, 0);
        const assigned = lines.reduce(function (n, line) { return n + Math.min(Number(line.requestedHours) || 0, Number(line.assignedHours) || 0); }, 0);
        const assignedLines = lines.filter(function (line) { return (Number(line.assignedHours) || 0) > 0; });
        const resources = [];
        assignedLines.forEach(function (line) { if (line.assignedResourceNo && resources.indexOf(line.assignedResourceNo) === -1) resources.push(line.assignedResourceNo); });
        const times = [];
        assignedLines.forEach(function (line) {
            if (line.assignedStartTime && line.assignedEndTime) {
                const t = line.assignedStartTime + '\u2013' + line.assignedEndTime;
                if (times.indexOf(t) === -1) times.push(t);
            }
        });
        return {
            pct: requested ? Math.max(0, Math.min(100, assigned / requested * 100)) : 0,
            resource: resources.join(', '),
            assignedTime: times.join(', ') || '\u2014'
        };
    }

    /// <summary>
    /// Rebuilds section 2's events from db.workOrderSequences, each individual OCCURRENCE
    /// positioned at ITS OWN current day-index (getOccurrenceDayIndex, 2026-09-04 - no longer one
    /// shared woAnchor for the whole WO, nor even one anchor per sequence row - see
    /// occurrenceAnchors' own doc comment), allocating each day's currentPositionSkillShortage()
    /// across the sequence cells that actually contribute to it (never double-counted - a running
    /// "remaining" pool per day/skill is depleted as each sequence event claims its share) -
    /// near-verbatim port of the reference's own "renderWorkOrder". Also refreshes section 1
    /// (setCurrentView forces its cell templates to re-read the now-current occurrence
    /// anchors/caches) and re-renders section 3 (its "shortage" figure and, cosmetically, its
    /// single-day highlight both depend on this) - section 4 is deliberately NOT touched here (its
    /// own data has no anchor dependency at all, matching the reference).
    /// </summary>
    renderWorkOrder() {
        if (!this.woScheduler) return;
        const self = this;
        const shortage = this.currentPositionSkillShortage();
        const shortageRemaining = shortage.map((day) => {
            const o = {};
            this.skills.forEach(function (skill) { o[skill] = Number(day && day[skill]) || 0; });
            return o;
        });

        const sequences = Array.isArray(this.db && this.db.workOrderSequences) ? this.db.workOrderSequences : [];
        const events = [];
        let id = 1;
        sequences.forEach(function (seq, seqIndex) {
            (seq.workdays || []).forEach(function (wd) {
                const idx = self.getOccurrenceDayIndex(seq, wd);
                if (idx < 0 || idx >= self.dates.length) return;
                const d = self.dates[idx];
                const start = new Date(d); start.setHours(8, 0, 0, 0);
                const end = new Date(d); end.setHours(16, 0, 0, 0);
                const assignment = self.workOrderAssignmentState(seq, idx);
                const requestedHours = Number((seq.hoursByWorkday && seq.hoursByWorkday[wd] != null) ? seq.hoursByWorkday[wd] : 8);
                const remaining = Number(shortageRemaining[idx] && shortageRemaining[idx][seq.skill]) || 0;
                const shortageHours = Math.max(0, Math.min(requestedHours, remaining));
                if (shortageRemaining[idx]) shortageRemaining[idx][seq.skill] = Math.max(0, remaining - shortageHours);

                events.push({
                    id: 'cpowo' + (id++),
                    start_date: start,
                    end_date: end,
                    text: '',
                    section_id: 'seq:' + seqIndex,
                    seqIndex: seqIndex,
                    skill: seq.skill,
                    hours: requestedHours,
                    requestedHours: requestedHours,
                    assignedHours: Number(assignment.pct) ? Math.round(requestedHours * assignment.pct / 100) : 0,
                    workday: wd,
                    dayIndex: idx,
                    shortageHours: shortageHours,
                    job: seq.job,
                    task: seq.task,
                    lineNo: seq.lineNo,
                    sequenceNo: seq.sequenceNo || '',
                    kind: 'workorder',
                    assignedPct: assignment.pct,
                    assignedResource: assignment.resource,
                    assignedResourceNo: assignment.resource,
                    assignedTime: assignment.assignedTime,
                    planStatus: ''
                });
            });
        });

        this.woScheduler.clearAll();
        this.woScheduler.parse(events, 'json');
        this.woScheduler.setCurrentView(this.dates[0], 'workorder');
        if (this.woSummaryScheduler) this.woSummaryScheduler.setCurrentView(this.dates[0], 'workordersummary');
        this.renderCapacityBars(this.db);
        this.bindScrollSync();
    }

    /// <summary>
    /// Section 3/4 shared "Capacity lookup" entry point - stub extensibility round-trip, matches
    /// page 50722's own currently-stubbed OnRequestCapacityLookup trigger (the shared modal itself
    /// is a later, still out-of-scope build step). showLoading/hideLoading bracket the invoke
    /// itself here (not deferred via runBusy - InvokeExtensibilityMethod is fire-and-forget from
    /// JS's own perspective, confirmed live it returns immediately rather than blocking the thread,
    /// so a plain showLoading() right before it still gets a real paint) so the spinner shows for
    /// this action too - hideLoading is ALSO called from showCapacityModal below, so this stays
    /// correct either way once OnRequestCapacityLookup is wired to real AL logic: a same-call-stack
    /// response hides here first (that later call becomes a harmless no-op), an async
    /// background-task response hides itself when it actually arrives instead.
    /// </summary>
    openCapacityLookup(dayIdx, skillFilter) {
        if (typeof Microsoft !== 'undefined') {
            this.showLoading();
            Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('OnRequestCapacityLookup', [JSON.stringify({ dayIndex: dayIdx, skill: skillFilter || null })]);
            this.hideLoading();
        }
    }

    /// <summary>
    /// Click-to-relocate - reference's own "moveWorkOrderToDay". Pure client-side simulation
    /// (2026-09-04 redesign) - no AL round-trip, no runBusy overlay (renderWorkOrder's own cost is
    /// a real but small ~100-150ms of synchronous JS, not worth a spinner flash for) -
    /// markUnconfirmedChange enables the Confirm button instead, same as the section 2 drag
    /// handler now does; see bindConfirmButton's doc comment for the full reasoning. (A prior
    /// version of this method WAS wrapped in runBusy, and one live measurement showed a ~5s gap
    /// before hideLoading fired despite renderWorkOrder itself only costing ~124ms - traced to a
    /// test session whose DOM was still carrying tens of thousands of nodes from repeated
    /// Expand-all clicks earlier in that same session, which starves requestAnimationFrame; not a
    /// real cost of this action on a normal page, and moot now that this path doesn't call
    /// runBusy/rAF at all.)
    ///
    /// DELIBERATELY still a bulk action (2026-09-04 - explicit, repeated user correction: "leave
    /// section 3 as is, do not change, section 3 should be drive section 2 in a group or whole
    /// sequence") - sets EVERY occurrence of EVERY sequence to idxWork(dayIndex, wd), preserving
    /// each occurrence's relative workday spacing from the others exactly like the old single
    /// shared woAnchor did, unlike the section 2 drag handler above (onEventChanged), which moves
    /// only the one bar actually dragged and nothing else. _bulkAnchorHint is cosmetic-only
    /// bookkeeping for renderCapacityBars' single-day highlight (see its own comment) - never read
    /// by any shortage/positioning math, since once individual occurrences have been dragged
    /// independently there is no longer one single day everything sits on in general.
    /// </summary>
    moveWorkOrderToDay(dayIndex) {
        if (dayIndex < 0 || dayIndex >= this.dates.length || cpoIsWeekend(this.dates[dayIndex])) return;
        const self = this;
        (this.db.workOrderSequences || []).forEach(function (seq) {
            (seq.workdays || []).forEach(function (wd) {
                self.setOccurrenceDayIndex(seq, wd, self.idxWork(dayIndex, wd));
            });
        });
        this._bulkAnchorHint = dayIndex;
        this.resetAnchorDependentCaches();
        this.renderWorkOrder();
        this.markUnconfirmedChange();
    }

    /// <summary>
    /// Applies section 2's own row-count-proportional container height. Same wrapper-vs-render-
    /// target split as applyCentralTreeHeight (see its own comment) - #cpo-wo-scheduler-wrap is the
    /// clamped/scrollable box, #cpo-wo-scheduler (DHTMLX's real init target) gets its full natural
    /// height so DHTMLX never squeezes rows to fit when this WO has more sequences than fit.
    /// </summary>
    applySchedulerContainerHeight(rowCount) {
        const wrapEl = document.getElementById('cpo-wo-scheduler-wrap');
        const containerEl = document.getElementById('cpo-wo-scheduler');
        if (!wrapEl || !containerEl) return;
        // +SCALE_HEIGHT (2026-09-04) - section 2 now renders its own date-header row instead of
        // borrowing section 1's (same reasoning as applyCentralTreeHeight's own +SCALE_HEIGHT for
        // section 4); without this the row list would get squeezed to make room for that header
        // inside a container still sized for rows alone.
        const computedHeight = (Math.max(0, rowCount) * CapacityPlanningOverview.ROW_HEIGHT) + CapacityPlanningOverview.SCHEDULER_HEIGHT_PADDING + CapacityPlanningOverview.SCALE_HEIGHT;
        const finalHeight = Math.max(CapacityPlanningOverview.MIN_SCHEDULER_HEIGHT, Math.min(CapacityPlanningOverview.MAX_SCHEDULER_HEIGHT, computedHeight));
        wrapEl.style.height = finalHeight + 'px';
        containerEl.style.height = Math.max(computedHeight, finalHeight) + 'px';
    }

    // ================================================================================
    // Shared event tooltip - ports the reference's eventTooltipHtml/attachEventTooltip
    // (DHTMLXtempv112-app.js ~L1026-1055, ~L1249-1260), reused by section 2's real Scheduler events
    // AND section 4's chip cells (see attachTreeChipTooltip below).
    // ================================================================================

    eventTooltipHtml(ev) {
        const weekday = ev.start_date.toLocaleDateString('en-GB', { weekday: 'long' });
        const shortDate = ev.start_date.toLocaleDateString('en-GB', { month: 'short', day: 'numeric', year: 'numeric' });
        const reqTime = String(ev.start_date.getHours()).padStart(2, '0') + ':' + String(ev.start_date.getMinutes()).padStart(2, '0') + '\u2013' + String(ev.end_date.getHours()).padStart(2, '0') + ':' + String(ev.end_date.getMinutes()).padStart(2, '0');
        const projectLine = ev.job ? ('<div class="cpo-tip-main"><strong>' + cpoEsc(ev.job) + '</strong></div>') : '';
        const taskLine = ev.task ? ('<div class="cpo-tip-main">' + cpoEsc(ev.task) + (ev.description ? (' \u2014 ' + cpoEsc(ev.description)) : '') + '</div>') : '';
        const seqLabel = ev.sequenceNo ? ('SeqNo ' + cpoEsc(ev.sequenceNo)) : (ev.lineNo ? ('Sqnc ' + cpoEsc(ev.lineNo)) : (ev.description ? cpoEsc(ev.description) : 'Sequence'));
        const shortageNote = (ev.kind === 'workorder' && (Number(ev.shortageHours) || 0) > 0)
            ? ('<div class="cpo-tip-capacity-shortage">Capacity shortage: <b>' + cpoHoursText(ev.shortageHours) + '</b></div>')
            : '';
        return '<div class="cpo-tip-inner">' +
            '<div class="cpo-tip-section-title">Job and Task</div>' +
            (projectLine || '<div class="cpo-tip-main"><strong>\u2014</strong></div>') +
            (taskLine || '<div class="cpo-tip-main">\u2014</div>') +
            '<div class="cpo-tip-rule"></div>' +
            '<div class="cpo-tip-section-title">Skill: ' + cpoEsc(ev.skill || 'Planning') + '</div>' +
            '<div class="cpo-tip-main cpo-tip-muted">' + seqLabel + '</div>' +
            '<div class="cpo-tip-main">' + cpoEsc(weekday) + '</div>' +
            '<div class="cpo-tip-main">' + cpoEsc(shortDate) + '</div>' +
            shortageNote +
            '<div class="cpo-tip-rule"></div>' +
            '<table class="cpo-tip-grid"><thead><tr><th></th><th>Assigned</th><th>Request</th><th>Amount</th></tr></thead><tbody>' +
            '<tr><td>Time</td><td>' + ((ev.assignedTime && ev.assignedTime !== '\u2014') ? cpoEsc(ev.assignedTime) : '<span class="cpo-missing">\u2014</span>') + '</td><td>' + cpoEsc(reqTime) + '</td><td>' + cpoHoursText(ev.requestedHours != null ? ev.requestedHours : (ev.hours || 0)) + '</td></tr>' +
            '<tr><td>Resource</td><td>' + (ev.assignedResource ? cpoEsc(ev.assignedResource) : '<span class="cpo-missing">\u2014</span>') + '</td><td>\u2014</td><td>\u2014</td></tr>' +
            '</tbody></table></div>';
    }

    attachEventTooltip(schedulerInstance, hostId) {
        const tip = document.getElementById('cpo-event-tip');
        const host = document.getElementById(hostId);
        if (!tip || !host) return;
        const self = this;
        host.addEventListener('mousemove', function (e) {
            const node = e.target.closest('.dhx_cal_event_line,.dhx_cal_event');
            if (!node) { tip.style.display = 'none'; return; }
            const eventId = node.getAttribute('event_id') || node.dataset.eventId;
            let ev = null;
            if (eventId != null) { try { ev = schedulerInstance.getEvent(eventId); } catch (_) { } }
            if (!ev) { tip.style.display = 'none'; return; }
            tip.innerHTML = self.eventTooltipHtml(ev);
            tip.style.display = 'block';
            let x = e.clientX + 12, y = e.clientY + 12;
            const r = tip.getBoundingClientRect();
            if (x + r.width > window.innerWidth - 8) x = e.clientX - r.width - 12;
            if (y + r.height > window.innerHeight - 8) y = e.clientY - r.height - 12;
            tip.style.left = x + 'px'; tip.style.top = y + 'px';
        });
        host.addEventListener('mouseleave', function () { tip.style.display = 'none'; });
    }

    // ================================================================================
    // Section 3 - Capacity vs Requested daily bars, hand-rolled HTML/CSS (not DHTMLX). Now computed
    // ENTIRELY client-side from db.dayPlanningLines/db.resources/db.externalFree, near-verbatim port
    // of the reference's capParts/dailyCapacityRequestData/renderDailyCapacityRequestChart
    // (DHTMLXtempv112-app.js ~L142-148, ~L526-663) - the pre-pivot AL "capacityBars" payload (a
    // forward to codeunit 50662) is gone; this section no longer depends on that codeunit at all.
    // ================================================================================

    /// <summary>Per-day {assigned, freeInt, freeExt} capacity breakdown - reference's own "capParts". freeInt = (resource pool size * BASE_CAP) - hours actually assigned that day (any WO); freeExt comes straight from db.externalFree[i].</summary>
    capParts(i) {
        if (i < 0 || i >= this.dates.length || cpoIsWeekend(this.dates[i])) return { assigned: 0, freeInt: 0, freeExt: 0 };
        const lines = this.db.dayPlanningLines || [];
        let assigned = 0;
        for (let k = 0; k < lines.length; k++) { if (this.assignedDayIndex(lines[k]) === i) assigned += Number(lines[k].assignedHours) || 0; }
        const totalInternal = (this.db.resources || []).length * this.BASE_CAP;
        const freeInt = Math.max(0, totalInternal - assigned);
        const freeExt = (this.db.externalFree && this.db.externalFree[i]) || 0;
        return { assigned: assigned, freeInt: freeInt, freeExt: freeExt };
    }

    /// <summary>One row per this.dates entry - reference's own "dailyCapacityRequestData", minus the reference's separate fixed-30-column "timelineDates"/outOfData padding concept (this add-in's own "Days to show" window already IS the exact display window, so no separate longer horizon is needed).</summary>
    dailyCapacityRequestData() {
        const self = this;
        // "Requested" side stays scoped to the INSPECTED Work Order only (2026-09-03 addition -
        // explicit user correction: "section 3 for DWO0008") - db.dayPlanningLines now ALSO
        // carries every OTHER Work Order's demand in this same window (added so Section 4's tree
        // has real data to show), so this filter is what keeps section 3's own "Requested" bar
        // from silently turning into a company-wide total as a side effect of that. capParts()'s
        // "assigned"/freeInt total, just below, is deliberately NOT filtered this way - a resource
        // assigned to ANOTHER Work Order that day is genuinely unavailable to this one, so that
        // side of the bar was already correctly company-wide before this change.
        const woNo = this.db.workOrder && this.db.workOrder.no;
        return this.dates.map(function (d, i) {
            const weekend = cpoIsWeekend(d);
            const cp = self.capParts(i);
            const unassignedBySkill = {};
            self.skills.forEach(function (sk) { unassignedBySkill[sk] = 0; });
            let assignedRequest = 0, request = 0;
            (self.db.dayPlanningLines || []).forEach(function (line) {
                if (line.workOrderNo !== woNo) return;
                if (self.dplDayIndex(line) !== i) return;
                const req = Number(line.requestedHours) || 0;
                const ass = Math.min(req, Number(line.assignedHours) || 0);
                request += req;
                assignedRequest += ass;
                unassignedBySkill[line.requestedSkill] = (unassignedBySkill[line.requestedSkill] || 0) + Math.max(0, req - ass);
            });
            const total = cp.assigned + cp.freeInt + cp.freeExt;
            return {
                date: d, dayIndex: i, weekend: weekend,
                assigned: cp.assigned, freeInt: cp.freeInt, freeExt: cp.freeExt,
                request: request, assignedRequest: assignedRequest, unassignedBySkill: unassignedBySkill,
                shortage: Math.max(0, request - total)
            };
        });
    }

    dailyCapacityTooltipHtml(x) {
        const total = x.assigned + x.freeInt + x.freeExt;
        const dayLabel = x.date.toLocaleDateString('en-GB', { weekday: 'short', day: 'numeric' });
        return '<div class="cpo-dst-title">' + cpoEsc(dayLabel) + ' \u00b7 Capacity summary</div>' +
            '<div class="cpo-dst-row"><span class="cpo-dst-swatch" style="background:#8fb7ee"></span><span>Free external</span><span class="cpo-dst-value">' + cpoHoursText(x.freeExt) + '</span></div>' +
            '<div class="cpo-dst-row"><span class="cpo-dst-swatch" style="background:#5f8fd8"></span><span>Free internal</span><span class="cpo-dst-value">' + cpoHoursText(x.freeInt) + '</span></div>' +
            '<div class="cpo-dst-row"><span class="cpo-dst-swatch" style="background:#63aa72"></span><span>Assigned</span><span class="cpo-dst-value">' + cpoHoursText(x.assigned) + '</span></div>' +
            '<div class="cpo-dst-rule"></div><div class="cpo-dst-total"><span>Total capacity</span><span>' + cpoHoursText(total) + '</span></div>';
    }

    dailyRequestTooltipHtml(x) {
        const self = this;
        let rows = '';
        this.skills.slice().reverse().forEach(function (sk) {
            const meta = self.skillMeta(sk);
            const value = x.unassignedBySkill[sk] || 0;
            rows += '<div class="cpo-dst-row"><span class="cpo-dst-swatch" style="background:' + meta.color + ';border-color:' + meta.border + '"></span><span>' + cpoEsc(sk) + '</span><span class="cpo-dst-value">' + cpoHoursText(value) + '</span></div>';
        });
        const dayLabel = x.date.toLocaleDateString('en-GB', { weekday: 'short', day: 'numeric' });
        return '<div class="cpo-dst-title">' + cpoEsc(dayLabel) + ' \u00b7 Request summary</div>' +
            '<div class="cpo-dst-row"><span class="cpo-dst-swatch" style="background:#63aa72"></span><span>Assigned</span><span class="cpo-dst-value">' + cpoHoursText(x.assignedRequest) + '</span></div>' +
            rows +
            '<div class="cpo-dst-rule"></div><div class="cpo-dst-total"><span>Total request</span><span>' + cpoHoursText(x.request) + '</span></div>';
    }

    positionDailySummaryTip(tip, e) {
        tip.style.display = 'block';
        let x = e.clientX + 12, y = e.clientY + 12;
        const r = tip.getBoundingClientRect();
        if (x + r.width > window.innerWidth - 8) x = e.clientX - r.width - 12;
        if (y + r.height > window.innerHeight - 8) y = e.clientY - r.height - 12;
        tip.style.left = x + 'px'; tip.style.top = y + 'px';
    }

    renderCapacityBars(json) {
        const host = document.getElementById('cpo-capacity-bars');
        if (!host) return;

        // MEASURED, not the literal COLUMN_WIDTH constant - sections 1/2/4 auto-stretch their
        // columns to fill the host's available width whenever content is narrower than that
        // width (confirmed live), so the ACTUAL rendered column width can differ from the
        // configured constant depending on Days-to-show/viewport size. Since sections 1/2/4 all
        // share the same host width and day count, they auto-stretch IDENTICALLY to each other
        // regardless - section 3 just needs to match whatever that turns out to be.
        const columnWidth = this.measuredColumnWidth || CapacityPlanningOverview.COLUMN_WIDTH;
        if (this.dates.length === 0) { host.innerHTML = ''; return; }

        const self = this;
        const data = this.dailyCapacityRequestData();
        const maxVal = Math.max(8, ...data.filter(function (x) { return !x.weekend; }).map(function (x) { return Math.max(x.assigned + x.freeInt + x.freeExt, x.request); }));
        const maxBarPx = 82;
        const seg = function (value, colorHex) {
            if (!value || value <= 0) return '';
            const h = Math.max(1, Math.round(value / maxVal * maxBarPx));
            return '<div class="cpo-daily-chart-segment" style="height:' + h + 'px;background:' + (colorHex || '#ccc') + ';"></div>';
        };

        const cellsHtml = data.map(function (x) {
            const dayNo = x.date.getDate();
            const dayName = x.date.toLocaleDateString('en-GB', { weekday: 'short' });
            if (x.weekend) {
                return '<div class="cpo-daily-chart-day cpo-weekend" data-day-index="' + x.dayIndex + '" style="width:' + columnWidth + 'px;min-width:' + columnWidth + 'px;">' +
                    '<div class="cpo-daily-chart-date"><b>' + dayNo + '</b><span>' + dayName + '</span></div>' +
                    '<div class="cpo-daily-chart-off">non-workday</div><div class="cpo-daily-chart-value">\u2014</div></div>';
            }
            const cStack = seg(x.assigned, '#63aa72') + seg(x.freeInt, '#5f8fd8') + seg(x.freeExt, '#8fb7ee');
            let rStack = seg(x.assignedRequest, '#63aa72');
            self.skills.forEach(function (sk) { const meta = self.skillMeta(sk); rStack += seg(x.unassignedBySkill[sk], meta.color); });
            // _bulkAnchorHint (2026-09-04) - cosmetic-only, set by moveWorkOrderToDay's bulk
            // relocate (never by an individual section 2 drag) - once rows have been dragged
            // independently there is no longer one single day every row sits on in general, so this
            // simply stops highlighting anything (null) rather than picking one row's anchor
            // arbitrarily.
            const anchor = self._bulkAnchorHint !== null && x.dayIndex === self._bulkAnchorHint ? ' cpo-wo-anchor-day' : '';
            const shortageBar = x.shortage > 0 ? '<div class="cpo-daily-chart-shortage"></div>' : '';
            return '<div class="cpo-daily-chart-day' + anchor + '" data-day-index="' + x.dayIndex + '" style="width:' + columnWidth + 'px;min-width:' + columnWidth + 'px;">' +
                '<div class="cpo-daily-chart-date"><b>' + dayNo + '</b><span>' + dayName + '</span></div>' +
                '<div class="cpo-daily-chart-bars">' + shortageBar +
                '<div class="cpo-daily-chart-col" data-summary-kind="capacity" data-day-index="' + x.dayIndex + '"><div class="cpo-daily-chart-label">C</div><div class="cpo-daily-chart-bar-area"><div class="cpo-daily-chart-stack">' + cStack + '</div></div></div>' +
                '<div class="cpo-daily-chart-col" data-summary-kind="request" data-day-index="' + x.dayIndex + '"><div class="cpo-daily-chart-label">R</div><div class="cpo-daily-chart-bar-area"><div class="cpo-daily-chart-stack">' + rStack + '</div></div></div>' +
                '</div>' +
                '<div class="cpo-daily-chart-value">' + (x.assigned + x.freeInt + x.freeExt) + 'h&nbsp;&nbsp;' + x.request + 'h</div>' +
                '</div>';
        }).join('');

        host.innerHTML =
            // TREE_LABEL_WIDTH (360px), NOT ROW_LABEL_WIDTH (200px) - sections 3+4 form the
            // reference's own "central" block and share ITS wider label width (matching section
            // 4's real 3-column Skill/Job/Task header immediately below), independent of sections
            // 1+2's narrower "workorder" block width above. Confirmed against the user's own
            // reference screenshot: the "Hours overview" box and the Skill/Job/Task header below
            // it are the same width as each other, and BOTH differ from the narrower row-label
            // column sections 1/2 use.
            '<div class="cpo-daily-chart-fixed" style="width:' + CapacityPlanningOverview.TREE_LABEL_WIDTH + 'px;min-width:' + CapacityPlanningOverview.TREE_LABEL_WIDTH + 'px;">' +
            '<div class="cpo-daily-chart-overview-box"><b>Hours overview</b><span>C (Capacity): Assigned \u2192 Internal \u2192 External</span><span>R (Requested): Assigned \u2192 Unassigned per skill</span></div>' +
            '<div class="cpo-daily-chart-total">' +
            '<span class="cpo-daily-chart-total-label">Totals</span>' +
            '<div class="cpo-daily-chart-total-actions">' +
            '<button id="cpo-expand-all" class="cpo-mini-action-btn" type="button" title="Expand all">Expand</button>' +
            '<button id="cpo-expand-to-task" class="cpo-mini-action-btn" type="button" title="Expand to Task">Exp. to Task</button>' +
            '<button id="cpo-collapse-all" class="cpo-mini-action-btn" type="button" title="Collapse all">Collapse</button>' +
            '</div></div></div>' +
            '<div id="cpo-daily-chart-scroll" class="cpo-daily-chart-scroll"><div class="cpo-daily-chart-grid">' + cellsHtml + '</div></div>';

        this.bindHierarchyButtons();

        const tip = document.getElementById('cpo-daily-summary-tip');
        host.querySelectorAll('.cpo-daily-chart-col[data-summary-kind]').forEach(function (col) {
            col.addEventListener('mousemove', function (e) {
                const x = data[Number(col.dataset.dayIndex)];
                if (!x || !tip) return;
                tip.innerHTML = (col.dataset.summaryKind === 'capacity')
                    ? self.dailyCapacityTooltipHtml(x)
                    : self.dailyRequestTooltipHtml(x);
                self.positionDailySummaryTip(tip, e);
            });
            col.addEventListener('mouseleave', function () { if (tip) tip.style.display = 'none'; });
        });

        host.querySelectorAll('.cpo-daily-chart-day:not(.cpo-weekend)').forEach(function (cell) {
            cell.addEventListener('click', function (e) {
                if (e.detail > 1) return;
                self.moveWorkOrderToDay(Number(cell.dataset.dayIndex));
            });
            cell.addEventListener('dblclick', function (e) {
                e.preventDefault(); e.stopPropagation();
                self.openCapacityLookup(Number(cell.dataset.dayIndex), null);
            });
        });

        this.bindScrollSync();
    }

    // ================================================================================
    // Section 4 - Skill -> Job/Task -> Sequence tree+chip panel, a third real Scheduler timeline
    // (render:'tree' + treetimeline). Now built ENTIRELY client-side from db.groups +
    // db.dayPlanningLines - near-verbatim port of the reference's buildCentralSections/
    // skillDaySummary/taskDaySummary/sequenceDayLines/sequenceDayCellHtml/createCentralScheduler
    // (DHTMLXtempv112-app.js ~L374-515) - the pre-pivot AL "treeNodes"/"treeCells" payload (built by
    // codeunit 50604's now-removed CPO_BuildTreeNodesArray/CPO_BuildTreeCellsObj) is gone.
    // ================================================================================

    // Both levels start CLOSED (2026-09-04) regardless of AL's own groups[].expanded flag -
    // fully expanding this tree is expensive (real DOM-construction cost that scales with row
    // count, confirmed live: 2,831 rows fully expanded took ~1.7s even after treeSummaryIndex made
    // every cell lookup O(1) - see that method's own comment), so it should only ever be paid when
    // the user deliberately clicks Expand/Exp. to Task, not on every page open.
    buildCentralSections() {
        const self = this;
        return (this.db.groups || []).map(function (g) {
            return {
                key: 'skill:' + g.skill, section_id: 'skill:' + g.skill, label: g.skill, skill: g.skill, type: 'skill', open: false,
                children: (g.details || []).map(function (det, di) {
                    const lines = (self.db.dayPlanningLines || []).filter(function (line) { return line.requestedSkill === g.skill && line.job === det.job && line.task === det.task; });
                    const seqNos = [];
                    lines.forEach(function (l) { const sn = l.sequenceNo == null ? '' : l.sequenceNo; if (seqNos.indexOf(sn) === -1) seqNos.push(sn); });
                    return {
                        key: 'detail:' + g.skill + ':' + di, section_id: 'detail:' + g.skill + ':' + di,
                        label: det.description || (det.job + ' / ' + det.task), skill: g.skill, type: 'detail', job: det.job, task: det.task,
                        description: det.description || '', open: false,
                        children: seqNos.map(function (sequenceNo, si) {
                            return { key: 'sequence:' + g.skill + ':' + di + ':' + si, section_id: 'sequence:' + g.skill + ':' + di + ':' + si,
                                label: '', skill: g.skill, type: 'sequence', job: det.job, task: det.task, description: det.description || '', sequenceNo: sequenceNo };
                        })
                    };
                })
            };
        });
    }

    // skillDaySummary/taskDaySummary/sequenceDayLines all exclude the INSPECTED Work Order's own
    // lines (2026-09-03 addition) - db.groups[]/db.workOrderSequences' job/task/skill(/sequenceNo)
    // combos legitimately CAN collide between the inspected WO and an unrelated other WO (nothing
    // in the real Business Central data guarantees otherwise), and db.dayPlanningLines now holds
    // both WOs' rows in one array (see this file's own architecture-pivot doc comment) - without
    // this exclusion, a colliding inspected-WO row could double into Section 4's "other work
    // orders" totals, which are meant to be this WO's own schedule's exact complement.
    //
    // All three are called once per RENDERED CELL (DHTMLX's cell_template - one call per visible
    // row x visible day), so a per-call O(dayPlanningLines) scan/filter here means the WHOLE
    // section 4 redraw costs O(rows x days x dayPlanningLines.length) - confirmed live as the
    // actual cost of Expand/Collapse-all on a real multi-work-order dataset (profiled at several
    // real seconds, ALL of it inside DHTMLX's own native redraw calling these repeatedly - not an
    // AL round-trip, the data is already local, see the 2026-09-04 "why does this take so long"
    // question this fixes). buildTreeSummaryIndex groups dayPlanningLines ONCE per render pass
    // (O(dayPlanningLines.length) total) into skill/day, skill+job+task/day, and
    // skill+job+task+sequenceNo/day buckets, turning every one of these into an O(1) lookup - same
    // exclusion/aggregation rules as before, just computed once instead of once per cell.
    treeSummaryIndex() {
        if (this._treeSummaryIndex) return this._treeSummaryIndex;
        const woNo = this.db.workOrder && this.db.workOrder.no;
        const bySkillDay = {};
        const byTaskDay = {};
        const bySeqDay = {};
        (this.db.dayPlanningLines || []).forEach((line) => {
            if (line.workOrderNo === woNo) return;
            const idx = this.dplDayIndex(line);
            const req = Number(line.requestedHours) || 0;
            const assigned = Math.min(req, Number(line.assignedHours) || 0);

            const skillKey = line.requestedSkill + '|' + idx;
            const sAgg = bySkillDay[skillKey] || (bySkillDay[skillKey] = { requested: 0, assigned: 0 });
            sAgg.requested += req; sAgg.assigned += assigned;

            const taskKey = skillKey + '|' + line.job + '|' + line.task;
            const tAgg = byTaskDay[taskKey] || (byTaskDay[taskKey] = { requested: 0, assigned: 0 });
            tAgg.requested += req; tAgg.assigned += assigned;

            const seqKey = taskKey + '|' + (line.sequenceNo == null ? '' : line.sequenceNo);
            (bySeqDay[seqKey] || (bySeqDay[seqKey] = [])).push(line);
        });
        this._treeSummaryIndex = { bySkillDay: bySkillDay, byTaskDay: byTaskDay, bySeqDay: bySeqDay };
        return this._treeSummaryIndex;
    }

    skillDaySummary(skill, idx) {
        const agg = this.treeSummaryIndex().bySkillDay[skill + '|' + idx] || { requested: 0, assigned: 0 };
        return { requested: agg.requested, assigned: agg.assigned, shortage: Math.max(0, agg.requested - agg.assigned) };
    }

    taskDaySummary(section, idx) {
        const key = section.skill + '|' + idx + '|' + section.job + '|' + section.task;
        const agg = this.treeSummaryIndex().byTaskDay[key] || { requested: 0, assigned: 0 };
        return { requested: agg.requested, assigned: agg.assigned, shortage: Math.max(0, agg.requested - agg.assigned) };
    }

    sequenceDayLines(section, idx) {
        const key = section.skill + '|' + idx + '|' + section.job + '|' + section.task + '|' + (section.sequenceNo == null ? '' : section.sequenceNo);
        const lines = this.treeSummaryIndex().bySeqDay[key];
        if (!lines) return [];
        return lines.slice().sort(function (a, b) {
            return String(a.requestedStartTime).localeCompare(String(b.requestedStartTime)) ||
                String(a.requestedEndTime).localeCompare(String(b.requestedEndTime)) ||
                String(a.id).localeCompare(String(b.id));
        });
    }

    sequenceDayCellHtml(section, idx) {
        const lines = this.sequenceDayLines(section, idx);
        if (!lines.length) return '';
        const meta = this.skillMeta(section.skill);
        const chips = lines.map(function (line) {
            const req = Number(line.requestedHours) || 0;
            const ass = Math.min(req, Number(line.assignedHours) || 0);
            const pct = req ? Math.max(0, Math.min(100, ass / req * 100)) : 0;
            return '<span class="cpo-tree-chip" data-line-id="' + cpoEsc(line.id) + '" style="background:linear-gradient(to right,' + meta.dark + ' 0 ' + pct + '%,' + meta.light + ' ' + pct + '% 100%);border-color:' + meta.border + '">' + cpoHoursText(req) + '</span>';
        }).join('');
        return '<div class="cpo-tree-chip-row">' + chips + '</div>';
    }

    centralTreeLeftColumnHtml(o) {
        if (!o || o.key === 'nodata') return o && o.label ? cpoEsc(o.label) : '';
        if (o.type === 'sequence') {
            const text = [o.job, '-', o.task, o.skill, 'SeqNo', o.sequenceNo].filter(Boolean).join(' ');
            return '<div class="cpo-sequence-label-full">' + cpoEsc(text) + '</div>';
        }
        if (o.type === 'skill') {
            return '<div class="cpo-central-left-grid cpo-skill-left-grid"><span>' + cpoEsc(o.skill || o.label) + '</span><span></span><span></span></div>';
        }
        return '<div class="cpo-central-left-grid"><span></span><span>' + cpoEsc(o.job) + '</span><span>' + cpoEsc(o.task) + '</span></div>';
    }

    renderCentralTree(json) {
        if (typeof Scheduler === 'undefined') {
            console.error('CapacityPlanningOverview: DHX Scheduler library not loaded.');
            return;
        }
        if (!this.centralTreeScheduler) this.centralTreeScheduler = Scheduler.getSchedulerInstance();
        const s = this.centralTreeScheduler;
        s.plugins({ timeline: true, treetimeline: true, tooltip: true });
        this.configureBaseScheduler(s);
        s.config.drag_move = false;
        s.config.drag_resize = false;
        this.teardownView(s, 'centraltree');

        if (this.dates.length === 0) return;

        const self = this;
        const yUnitBuilt = this.buildCentralSections();
        const yUnit = yUnitBuilt.length > 0 ? yUnitBuilt : [{ key: 'nodata', section_id: 'nodata', label: 'No skill demand for this Work Order', type: 'skill' }];

        this.applyCentralTreeHeight(yUnit);

        s.createTimelineView({
            name: 'centraltree',
            render: 'tree',
            x_unit: 'day',
            x_step: 1,
            x_size: this.dates.length,
            x_date: '%d %M',
            y_unit: yUnit,
            y_property: 'section_id',
            dy: CapacityPlanningOverview.ROW_HEIGHT,
            folder_dy: CapacityPlanningOverview.ROW_HEIGHT,
            section_autoheight: false,
            fit_events: false,
            column_width: CapacityPlanningOverview.COLUMN_WIDTH,
            dx: CapacityPlanningOverview.TREE_LABEL_WIDTH,
            scrollable: true,
            // Tried smart_rendering: true here (2026-09-04) - DHTMLX Scheduler's own viewport-based lazy-render
            // option, on the theory that Expand-all's real cost (confirmed by profiling: ~218ms of template-callback
            // time out of ~3.4s total - see treeSummaryIndex's own comment) was DHTMLX eagerly building DOM for all
            // 2,831 rows x ~20 workdays at once instead of only the ~420px visible window. Measured LIVE: it made
            // Expand-all slower (~8.1s, not faster) - reverted. Section 4 was rebuilt on the Gantt add-ins' own tree
            // mechanism instead (see buildGanttStyleCentralTree's own comment) rather than pursuing further
            // Scheduler-treetimeline-specific tuning.
            columns: [{
                label: '<div class="cpo-central-left-header"><span>Skill</span><span>Job</span><span>Task</span></div>',
                width: CapacityPlanningOverview.TREE_LABEL_WIDTH,
                template: function (o) { return self.centralTreeLeftColumnHtml(o); }
            }],
            cell_template: true,
            // Section 4 has its OWN date-header row (scale_height nonzero), unlike section 2 -
            // it uses a wider TREE_LABEL_WIDTH (360px) than sections 1-3's ROW_LABEL_WIDTH
            // (200px), so it can't share section 1's header (a shared header assumes a single
            // consistent left-offset). Matches the reference prototype's own layout: its "Central
            // planning grid" block shows its own independent date-number row, at a different
            // left-offset than the Work Order block's header above it.
            scale_height: CapacityPlanningOverview.SCALE_HEIGHT
        });

        s.date.centraltree_start = function () { return self.dates[0]; };
        s.templates.centraltree_scalex_class = function (date) { return cpoIsWeekend(date) ? 'cpo-weekend-scale' : ''; };
        s.templates.centraltree_row_class = function (section) { return section.type === 'skill' ? 'cpo-tree-row-skill' : (section.type === 'detail' ? 'cpo-tree-row-detail' : ''); };
        s.templates.centraltree_cell_class = function (evs, date) { return cpoIsWeekend(date) ? 'cpo-weekend-cell' : ''; };
        s.templates.centraltree_cell_value = function (evs, date, section) {
            if (!section || section.key === 'nodata') return '';
            const idx = self.dayIndex(date);
            if (idx < 0 || idx >= self.dates.length || cpoIsWeekend(date)) return '';
            if (section.type === 'skill') {
                const m = self.skillDaySummary(section.skill, idx);
                if (!m.requested) return '';
                const meta = self.skillMeta(section.skill);
                const pct = m.requested ? Math.max(0, Math.min(100, m.assigned / m.requested * 100)) : 100;
                return '<div class="cpo-tree-summary-cell" data-master-skill="' + cpoEsc(section.skill) + '" data-day-index="' + idx + '" style="background:linear-gradient(to right,' + meta.dark + ' 0 ' + pct + '%,' + meta.light + ' ' + pct + '% 100%)"><b>' + m.requested + 'h</b></div>';
            }
            if (section.type === 'detail') {
                const sm = self.taskDaySummary(section, idx);
                if (!sm.requested) return '';
                const meta = self.skillMeta(section.skill);
                const pct = sm.requested ? Math.max(0, Math.min(100, sm.assigned / sm.requested * 100)) : 100;
                return '<div class="cpo-tree-summary-cell" data-skill="' + cpoEsc(section.skill) + '" data-job="' + cpoEsc(section.job) + '" data-task="' + cpoEsc(section.task) + '" data-day-index="' + idx + '" style="background:linear-gradient(to right,' + meta.dark + ' 0 ' + pct + '%,' + meta.light + ' ' + pct + '% 100%)"><b>' + sm.requested + 'h</b></div>';
            }
            if (section.type === 'sequence') return self.sequenceDayCellHtml(section, idx);
            return '';
        };
        s.templates.event_class = function (a, b, e) { return 'cpo-planner-event cpo-skill-' + cpoSlug(e.skill); };
        s.templates.event_bar_text = function (a, b, e) { return e.hours || ''; };

        s.init('cpo-central-tree', this.dates[0], 'centraltree');
        s.clearAll();
        this.attachTreeChipTooltip();
        this.bindCentralTreeHeightSync(s);
    }

    /// <summary>
    /// Keeps applyCentralTreeHeight's wrapEl/containerEl sizing in sync with the LIVE visible row
    /// count, not just whatever was visible at the last full renderCentralTree call - covers the
    /// user clicking a single row's own native fold/unfold arrow (DHTMLX's treetimeline recomputes
    /// y_unit and fires onOptionsLoad itself for that, before this listener ever runs). Without
    /// this, collapsing rows left the wrapper's clip height (and so its scrollbar range) sized for
    /// whatever row count was visible at the last full render, producing a scrollbar whose thumb
    /// still spans the fully-expanded range and a blank gap below the now-shorter row list when
    /// scrolled down (2026-09-04 bug report).
    ///
    /// This does NOT also force a setCurrentView redraw (an earlier version of this fix did, on the
    /// theory that DHTMLX's own native onOptionsLoad redraw might read a stale container height
    /// otherwise) - profiling that version live showed the EXTRA setCurrentView call wasn't
    /// actually adding meaningful cost on top of DHTMLX's own native redraw; removing it changed
    /// nothing about correctness (no squished/misaligned rows either way - applyCentralTreeHeight
    /// alone only changes the WRAPPER's clip/scroll box, never the already-rendered rows' own
    /// layout) but avoids doing the same redraw work twice for the Expand/Collapse-all button path
    /// specifically, since setTreeOpenState below now pre-applies the height BEFORE firing
    /// onOptionsLoad, so DHTMLX's one native redraw already reads the correct height. The REAL cost
    /// of Expand/Collapse-all (profiled live at several real seconds on this WO's data, prompting
    /// the 2026-09-04 "why does this take so long, the data's already in JS" question) was never
    /// this listener at all - it was skillDaySummary/taskDaySummary/sequenceDayLines each doing an
    /// O(dayPlanningLines) scan PER RENDERED CELL, called by DHTMLX's own native redraw once per
    /// visible row x day; see treeSummaryIndex's own comment for the actual fix.
    /// </summary>
    bindCentralTreeHeightSync(s) {
        if (this._treeHeightSyncBound) return;
        this._treeHeightSyncBound = true;
        const self = this;
        s.attachEvent('onOptionsLoad', function () {
            const yUnit = s.matrix && s.matrix.centraltree && s.matrix.centraltree.y_unit_original;
            if (!yUnit) return;
            self.applyCentralTreeHeight(yUnit);
        });
    }

    dplLineById(id) {
        const lines = this.db.dayPlanningLines || [];
        for (let i = 0; i < lines.length; i++) if (String(lines[i].id) === String(id)) return lines[i];
        return null;
    }

    /// <summary>Builds a section-2-shaped tooltip "event" object out of a real Day Planning line - reference's own "dplTooltipEvent".</summary>
    dplTooltipEvent(line) {
        const i = this.dplDayIndex(line);
        const d = this.dates[i] || cpoParseDateOnly(line.requestDate);
        const start = new Date(d), end = new Date(d);
        const sParts = String(line.requestedStartTime || '07:00').split(':').map(Number);
        const eParts = String(line.requestedEndTime || '15:00').split(':').map(Number);
        start.setHours(sParts[0] || 0, sParts[1] || 0, 0, 0);
        end.setHours(eParts[0] || 0, eParts[1] || 0, 0, 0);
        return {
            start_date: start, end_date: end, skill: line.requestedSkill, job: line.job, task: line.task, description: line.description,
            sequenceNo: line.sequenceNo || '', lineNo: line.sequenceLineNo, assignedResource: line.assignedResourceNo || '',
            assignedTime: (line.assignedStartTime && line.assignedEndTime) ? (line.assignedStartTime + '\u2013' + line.assignedEndTime) : '\u2014',
            requestedHours: Number(line.requestedHours) || 0, hours: Number(line.requestedHours) || 0, kind: 'dayplanning'
        };
    }

    /// <summary>
    /// Reference's shared-tooltip technique for section 4's chips (own mouseover/mouseout/click
    /// handlers on ".cpo-tree-chip", reusing the SAME #cpo-event-tip element/eventTooltipHtml
    /// section 2 already uses) - bound ONCE per centralTreeScheduler instance (idempotent guard,
    /// since renderCentralTree can re-run on every applyPlanningData call but the host div itself is
    /// only ever created once in buildLayout). Chip click raises OnSequenceChipClick (page 50722's
    /// still-stubbed trigger).
    /// </summary>
    attachTreeChipTooltip() {
        if (this._treeChipTooltipBound) return;
        this._treeChipTooltipBound = true;
        const tip = document.getElementById('cpo-event-tip');
        const host = document.getElementById('cpo-central-tree');
        if (!tip || !host) return;
        const self = this;
        host.addEventListener('mousemove', function (e) {
            const chip = e.target.closest('.cpo-tree-chip');
            if (!chip) { tip.style.display = 'none'; return; }
            const line = self.dplLineById(chip.dataset.lineId);
            if (!line) { tip.style.display = 'none'; return; }
            tip.innerHTML = self.eventTooltipHtml(self.dplTooltipEvent(line));
            tip.style.display = 'block';
            let x = e.clientX + 12, y = e.clientY + 12;
            const r = tip.getBoundingClientRect();
            if (x + r.width > window.innerWidth - 8) x = e.clientX - r.width - 12;
            if (y + r.height > window.innerHeight - 8) y = e.clientY - r.height - 12;
            tip.style.left = x + 'px'; tip.style.top = y + 'px';
        });
        host.addEventListener('mouseleave', function () { tip.style.display = 'none'; });
        host.addEventListener('click', function (e) {
            const chip = e.target.closest('.cpo-tree-chip');
            if (!chip) return;
            const line = self.dplLineById(chip.dataset.lineId);
            if (!line) return;
            e.preventDefault(); e.stopPropagation();
            if (typeof Microsoft !== 'undefined') {
                // Same show/hide-around-the-invoke treatment as openCapacityLookup above (see its
                // own comment on why hiding right after a fire-and-forget invoke is correct here) -
                // unlike that one, this trigger has no dedicated JS-callable "result arrived" hook
                // of its own to hide from instead, so this stays the one and only hide point even
                // once OnSequenceChipClick is wired to its real "open Day Plannings" behavior.
                self.showLoading();
                Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('OnSequenceChipClick', [JSON.stringify({ lineId: line.id, job: line.job, task: line.task, skill: line.requestedSkill, sequenceNo: line.sequenceNo })]);
                self.hideLoading();
            }
        });
    }

    /// <summary>Section 4's container height, proportional to its INITIAL visible row count - unchanged from before this pivot.</summary>
    applyCentralTreeHeight(yUnit) {
        // Two different elements get two different heights (see buildLayout's own comment on why):
        // the WRAPPER (#cpo-central-tree-wrap) is what visually clips/scrolls, clamped to
        // MIN/MAX_TREE_HEIGHT; the actual DHTMLX render target (#cpo-central-tree, inside it) gets
        // its full NATURAL/unclamped height so DHTMLX renders every row at its real dy (32px)
        // instead of squeezing all rows to fit a small container - DHTMLX fits row height to
        // whatever clientHeight its OWN init-target element reports, regardless of dy/
        // section_autoheight config (confirmed live), so that element must never be clamped.
        const wrapEl = document.getElementById('cpo-central-tree-wrap');
        const containerEl = document.getElementById('cpo-central-tree');
        if (!wrapEl || !containerEl) return;
        let count = 0;
        const walk = function (nodes) {
            (nodes || []).forEach(function (n) {
                count++;
                if (Array.isArray(n.children) && n.children.length && n.open !== false) walk(n.children);
            });
        };
        walk(yUnit);
        // +SCALE_HEIGHT for section 4's own now-visible date-header row (see renderCentralScheduler's
        // scale_height) - without this, the row list's own rows would get squeezed/clipped to make
        // room for the header inside a container sized for rows alone.
        const computedHeight = (Math.max(1, count) * CapacityPlanningOverview.ROW_HEIGHT) + CapacityPlanningOverview.SCHEDULER_HEIGHT_PADDING + CapacityPlanningOverview.SCALE_HEIGHT;
        const finalHeight = Math.max(CapacityPlanningOverview.MIN_TREE_HEIGHT, Math.min(CapacityPlanningOverview.MAX_TREE_HEIGHT, computedHeight));
        wrapEl.style.height = finalHeight + 'px';
        containerEl.style.height = Math.max(computedHeight, finalHeight) + 'px';
    }

    /// <summary>
    /// Ports wrapper.js's own ToggleCollapseExpandAllSections technique verbatim - unchanged from
    /// before this pivot. applyCentralTreeHeight is called HERE, before firing onOptionsLoad
    /// (2026-09-04) - not left to bindCentralTreeHeightSync's own onOptionsLoad listener to fix up
    /// afterward - so DHTMLX's own native onOptionsLoad handler (which does the real row redraw,
    /// and runs BEFORE any listener attached via attachEvent) already reads the corrected container
    /// height on its one and only pass; see bindCentralTreeHeightSync's own comment for why this
    /// (avoiding one redundant redraw) turned out NOT to be where Expand/Collapse-all's real
    /// multi-second cost was coming from - kept anyway since it's a free, correct micro-saving.
    /// </summary>
    setTreeOpenState(skillOpen, detailOpen) {
        const s = this.centralTreeScheduler;
        if (!s || !s.matrix || !s.matrix.centraltree || !s.matrix.centraltree.y_unit_original) return;
        s.matrix.centraltree.y_unit_original.forEach(function (skillNode) {
            if (Array.isArray(skillNode.children)) {
                skillNode.open = skillOpen;
                skillNode.children.forEach(function (detailNode) {
                    if (Array.isArray(detailNode.children)) detailNode.open = detailOpen;
                });
            }
        });
        s.matrix.centraltree.y_unit = s._getArrayToDisplay(s.matrix.centraltree.y_unit_original);
        this.applyCentralTreeHeight(s.matrix.centraltree.y_unit_original);
        s.callEvent('onOptionsLoad', []);
    }

    bindHierarchyButtons() {
        const self = this;
        const expandAll = document.getElementById('cpo-expand-all');
        const expandToTask = document.getElementById('cpo-expand-to-task');
        const collapseAll = document.getElementById('cpo-collapse-all');
        if (expandAll) expandAll.onclick = function () { self.runBusy(function () { self.setTreeOpenState(true, true); }); };
        if (expandToTask) expandToTask.onclick = function () { self.runBusy(function () { self.setTreeOpenState(true, false); }); };
        if (collapseAll) collapseAll.onclick = function () { self.runBusy(function () { self.setTreeOpenState(false, false); }); };
    }

    // ================================================================================
    // Scroll-sync - ports the reference's liveHorizontalOwners/syncHorizontalScroll idea
    // (DHTMLXtempv112-app.js ~L908-952): scrolling any one of sections 1/2/4's own real Scheduler
    // timeline data wrappers, or section 3's own scroll container, moves all the others together.
    // Deliberately NOT porting the reference's separate always-visible proxy "#sharedScroll" bar -
    // that exists in the reference because ITS section 4 host can end up narrower than its content
    // in its own layout; this add-in's four sections already share real native horizontal scroll
    // containers of their own, so directly syncing those together (without an extra proxy bar) is
    // the simpler equivalent here.
    // ================================================================================

    getScrollOwner(hostId) {
        const el = document.getElementById(hostId);
        return el ? el.querySelector('.dhx_timeline_data_wrapper.dhx_timeline_scrollable_data') : null;
    }
    liveHorizontalOwners() {
        return [
            this.getScrollOwner('cpo-wo-summary'),
            this.getScrollOwner('cpo-wo-scheduler'),
            this.getScrollOwner('cpo-central-tree'),
            document.getElementById('cpo-daily-chart-scroll')
        ].filter(Boolean);
    }
    bindScrollSync() {
        const self = this;
        const bar = document.getElementById('cpo-shared-scroll');
        const owners = this.liveHorizontalOwners();

        owners.forEach(function (owner) {
            if (!owner || owner.dataset.cpoSharedBound === '1') return;
            owner.dataset.cpoSharedBound = '1';
            owner.addEventListener('scroll', function () {
                self._pendingScrollOwner = owner;
                self.scheduleScrollSync();
            }, { passive: true });
        });

        this.refreshSharedScrollbar(bar, owners);
    }

    /// <summary>
    /// Coalesces scroll-sync work to at most once per animation frame (2026-09-04) - a fast native
    /// drag of the shared scrollbar (or any one owner's own native scrollbar) can fire many 'scroll'
    /// events in quick succession, and each one previously wrote scrollLeft synchronously to all 3
    /// OTHER owners immediately - sections 1/2/4 are DHTMLX-managed (a scrollLeft write can trigger
    /// real internal reflow, unlike section 3's plain div), so a burst of events could out-pace the
    /// browser's ability to keep all four in lockstep, producing a visibly torn/ghosted frame where
    /// some sections had caught up to the new scroll position and others hadn't yet (user-reported,
    /// screenshot evidence, mid-drag only - never reproducible at rest, matching this diagnosis).
    /// Reading scrollLeft fresh INSIDE the rAF callback (not at event-fire time) is what makes this
    /// coalesce correctly - many events collapse into one sync of wherever the source owner actually
    /// ended up by the time the browser is ready to paint, instead of replaying every intermediate
    /// position.
    /// </summary>
    scheduleScrollSync() {
        const self = this;
        if (self._scrollSyncRAF) return;
        self._scrollSyncRAF = requestAnimationFrame(function () {
            self._scrollSyncRAF = null;
            const owner = self._pendingScrollOwner;
            if (self._scrollLock || !owner) return;
            self._scrollLock = true;
            const bar = document.getElementById('cpo-shared-scroll');
            self.liveHorizontalOwners().forEach(function (o) {
                if (o !== owner && Math.abs(o.scrollLeft - owner.scrollLeft) > 0.5) o.scrollLeft = owner.scrollLeft;
            });
            if (bar && Math.abs(bar.scrollLeft - owner.scrollLeft) > 0.5) bar.scrollLeft = owner.scrollLeft;
            self._scrollLock = false;
        });
    }

    /// <summary>
    /// Ports the reference's #sharedScroll/refreshSharedScrollbar (DHTMLXtempv112-app.js
    /// ~L925-1009 / DHTMLXtempv112.html .shared-scroll CSS): a single, always-reachable proxy
    /// scrollbar pinned to the bottom of the whole component, driving sections 1/2/3/4's own
    /// native horizontal scroll together - matches the reference's own visible control exactly
    /// (the user asked specifically where this bar was after the initial port omitted it in favor
    /// of syncing the sections' own native scrollbars directly). The native scrollbars stay
    /// functional but hidden (see style.css) - this bar is the only one the user sees/drags, same
    /// as the reference. `cpo-shared-scroll-inner`'s width is set to the widest owner's own
    /// scrollWidth so the bar's thumb size/proportions are correct; re-run every render pass
    /// (day count / row count can change between Work Orders or after Days-to-show changes).
    /// </summary>
    refreshSharedScrollbar(bar, owners) {
        bar = bar || document.getElementById('cpo-shared-scroll');
        owners = owners || this.liveHorizontalOwners();
        const inner = document.getElementById('cpo-shared-scroll-inner');
        if (!bar || !inner || owners.length === 0) return;

        const maxScrollWidth = Math.max.apply(null, owners.map(function (o) { return o.scrollWidth || 0; }));
        inner.style.width = maxScrollWidth + 'px';

        const self = this;
        if (bar.dataset.cpoSharedBound !== '1') {
            bar.dataset.cpoSharedBound = '1';
            bar.addEventListener('scroll', function () {
                self._sharedBarActive = true;
                clearTimeout(self._sharedBarReleaseTimer);

                // rAF-coalesced (2026-09-04, same reasoning as scheduleScrollSync above) - this IS
                // the bar the user actually drags with the mouse (native scrollbars on the 4 owners
                // themselves are hidden, per this method's own doc comment), so a fast drag fires
                // this handler the most out of any scroll listener in the file - the exact case that
                // produced the user-reported torn/ghosted frame mid-drag.
                if (!self._sharedBarSyncRAF) {
                    self._sharedBarSyncRAF = requestAnimationFrame(function () {
                        self._sharedBarSyncRAF = null;
                        if (self._scrollLock) return;
                        self._scrollLock = true;
                        self.liveHorizontalOwners().forEach(function (owner) {
                            const ownerMax = Math.max(0, owner.scrollWidth - owner.clientWidth);
                            owner.scrollLeft = Math.min(bar.scrollLeft, ownerMax);
                        });
                        self._scrollLock = false;
                    });
                }

                self._sharedBarReleaseTimer = setTimeout(function () { self._sharedBarActive = false; }, 140);
            }, { passive: true });
        }

        // Keep the bar's own position in sync with whatever the owners already show (e.g. right
        // after a re-render whose content width changed) without fighting an in-progress bar drag.
        if (!self._sharedBarActive && owners[0] && Math.abs(bar.scrollLeft - owners[0].scrollLeft) > 0.5) {
            bar.scrollLeft = owners[0].scrollLeft;
        }
    }

    // ================================================================================
    // Deferred - unchanged from before this pivot (out of scope for the max-flow-engine rewrite).
    // ================================================================================

    applyColors(json) {
        // no-op placeholder - color wiring comes in a later step.
    }

    showCapacityModal(json) {
        // no-op placeholder - capacity lookup modal comes in a later step. hideLoading() is a
        // no-op if openCapacityLookup's own already fired (today's stub, same call stack) - kept
        // here so this becomes the real hide point with no further change once
        // OnRequestCapacityLookup/LoadCapacityLookup deliver a result asynchronously instead.
        this.hideLoading();
    }
}

// Shared layout geometry constants - ONE set, used identically by all four sections, matching
// the reference's own literal values (DHTMLXtempv112-app.js: dx:360, column_width:92, confirmed
// IDENTICAL across all three of its createTimelineView calls - workordersummary line 223,
// workorder line 273, central line 468). An earlier pass wrongly introduced a separate, wider
// TREE_LABEL_WIDTH for section 4 based on a misreading of a screenshot; the reference has no such
// distinction - kept as an alias below so nothing else needs to change.
CapacityPlanningOverview.ROW_LABEL_WIDTH = 360;
CapacityPlanningOverview.COLUMN_WIDTH = 92;
CapacityPlanningOverview.TREE_LABEL_WIDTH = CapacityPlanningOverview.ROW_LABEL_WIDTH;
CapacityPlanningOverview.SCALE_HEIGHT = 36;
CapacityPlanningOverview.CALC_ROW_HEIGHT = 34;
CapacityPlanningOverview.ROW_HEIGHT = 32;
CapacityPlanningOverview.SCHEDULER_HEIGHT_PADDING = 8;
CapacityPlanningOverview.MIN_SCHEDULER_HEIGHT = 90;
CapacityPlanningOverview.MAX_SCHEDULER_HEIGHT = 400;
CapacityPlanningOverview.MIN_TREE_HEIGHT = 120;
CapacityPlanningOverview.MAX_TREE_HEIGHT = 420;
