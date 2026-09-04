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
        this.woAnchor = 0;
        this.woSummaryScheduler = null;
        this.woScheduler = null;
        this.centralTreeScheduler = null;
        this._evalWOCache = {};
        this._currentPositionShortageArr = null;
        this._currentPositionSkillShortageArr = null;
        this._baseRequests = null;
        this._baselineWithoutWO = null;
        this._scrollLock = false;
        this._treeChipTooltipBound = false;
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
            '<div id="cpo-daily-summary-tip" class="cpo-daily-summary-tip"></div>';

        this.bindDaysToShowInput();
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
        const commit = function () {
            let n = parseInt(input.value, 10);
            if (!n || n <= 0) n = 30;
            if (typeof Microsoft !== 'undefined') {
                Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('OnDaysToShowChanged', [n]);
            }
        };
        input.addEventListener('change', commit);
        input.addEventListener('keydown', function (e) {
            if (e.key === 'Enter') { commit(); input.blur(); }
        });
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
        // 50604's CPO_ComputeWorkdayOffset) - initial woAnchor = 0 matches the reference's own
        // `let woAnchor=0` for the exact same reason.
        this.woAnchor = 0;

        this._evalWOCache = {};
        this._currentPositionShortageArr = null;
        this._currentPositionSkillShortageArr = null;
        this._baseRequests = this.aggregateRequests();
        this._baselineWithoutWO = this.aggregateOutstandingRequestsWithoutWO();

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

        this.renderWoSummaryScheduler(this.db);
        this.renderCapacityBars(this.db);
        this.renderCentralTree(this.db);
        this.bindScrollSync();
    }

    /// <summary>Clears the two woAnchor-dependent caches (NOT this._evalWOCache, which is independent of woAnchor) - call after any woAnchor change (drag, click-to-relocate).</summary>
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
    /// <summary>Places this Work Order's own workOrderSequences[] demand at candidate anchor `start`, returning a per-day {skill: hours} map - reference's own "workOrderExtra".</summary>
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
    /// <summary>Per-day added shortage caused specifically by this WO's demand at its CURRENT anchor position (this.woAnchor) - reference's own "currentPositionShortage". Cached until the next resetAnchorDependentCaches() (woAnchor change) or applyPlanningData() call.</summary>
    currentPositionShortage() {
        if (this._currentPositionShortageArr) return this._currentPositionShortageArr;
        const extra = this.workOrderExtra(this.woAnchor);
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
        const extra = this.workOrderExtra(this.woAnchor);
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
    // idxWork(woAnchor, workday-offset), exactly like the reference, instead of the pre-pivot
    // version's real absolute "Plan Date" placement; dragging a bar shifts woAnchor and re-renders
    // client-side (matching the reference's own pure-simulation drag behavior) and ALSO still fires
    // OnRescheduleWorkOrder (page 50722's stub trigger) so that wiring stays exercised.
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
            scale_height: 0
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
        s.attachEvent('onEventChanged', function (id, ev) {
            const movedTo = self.dayIndex(ev.start_date);
            const shift = movedTo - ev.dayIndex;
            let target = self.woAnchor + shift;
            target = Math.max(0, Math.min(self.dates.length - 1, target));
            if (cpoIsWeekend(self.dates[target])) { while (target < self.dates.length && cpoIsWeekend(self.dates[target])) target++; }
            if (self.validStart(target)) self.woAnchor = target;
            self.resetAnchorDependentCaches();
            self.renderWorkOrder();
            if (typeof Microsoft !== 'undefined') {
                Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('OnRescheduleWorkOrder', [shift, JSON.stringify({ woAnchor: self.woAnchor })]);
            }
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
    /// Rebuilds section 2's events from db.workOrderSequences positioned at the CURRENT woAnchor,
    /// allocating each day's currentPositionSkillShortage() across the sequence cells that actually
    /// contribute to it (never double-counted - a running "remaining" pool per day/skill is
    /// depleted as each sequence event claims its share) - near-verbatim port of the reference's own
    /// "renderWorkOrder". Also refreshes section 1 (setCurrentView forces its cell templates to
    /// re-read the now-current woAnchor/caches) and re-renders section 3 (its "shortage"/anchor-
    /// highlight both depend on woAnchor) - section 4 is deliberately NOT touched here (its own data
    /// has no woAnchor dependency, matching the reference).
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
                const idx = self.idxWork(self.woAnchor, wd);
                if (idx >= self.dates.length) return;
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

    /// <summary>Section 3/4 shared "Capacity lookup" entry point - stub extensibility round-trip, matches page 50722's own currently-stubbed OnRequestCapacityLookup trigger (the shared modal itself is a later, still out-of-scope build step).</summary>
    openCapacityLookup(dayIdx, skillFilter) {
        if (typeof Microsoft !== 'undefined') {
            Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('OnRequestCapacityLookup', [JSON.stringify({ dayIndex: dayIdx, skill: skillFilter || null })]);
        }
    }

    /// <summary>Click-to-relocate - moves woAnchor directly to a clicked section-3 day column and re-renders, exactly like a drag - reference's own "moveWorkOrderToDay".</summary>
    moveWorkOrderToDay(dayIndex) {
        if (dayIndex < 0 || dayIndex >= this.dates.length || cpoIsWeekend(this.dates[dayIndex])) return;
        this.woAnchor = dayIndex;
        this.resetAnchorDependentCaches();
        this.renderWorkOrder();
        if (typeof Microsoft !== 'undefined') {
            Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('OnRescheduleWorkOrder', [dayIndex, JSON.stringify({ woAnchor: dayIndex })]);
        }
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
        const computedHeight = (Math.max(0, rowCount) * CapacityPlanningOverview.ROW_HEIGHT) + CapacityPlanningOverview.SCHEDULER_HEIGHT_PADDING;
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
            const anchor = x.dayIndex === self.woAnchor ? ' cpo-wo-anchor-day' : '';
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

    buildCentralSections() {
        const self = this;
        return (this.db.groups || []).map(function (g) {
            return {
                key: 'skill:' + g.skill, section_id: 'skill:' + g.skill, label: g.skill, skill: g.skill, type: 'skill', open: !!g.expanded,
                children: (g.details || []).map(function (det, di) {
                    const lines = (self.db.dayPlanningLines || []).filter(function (line) { return line.requestedSkill === g.skill && line.job === det.job && line.task === det.task; });
                    const seqNos = [];
                    lines.forEach(function (l) { const sn = l.sequenceNo == null ? '' : l.sequenceNo; if (seqNos.indexOf(sn) === -1) seqNos.push(sn); });
                    return {
                        key: 'detail:' + g.skill + ':' + di, section_id: 'detail:' + g.skill + ':' + di,
                        label: det.description || (det.job + ' / ' + det.task), skill: g.skill, type: 'detail', job: det.job, task: det.task,
                        description: det.description || '', open: true,
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
    skillDaySummary(skill, idx) {
        const woNo = this.db.workOrder && this.db.workOrder.no;
        let requested = 0, assigned = 0;
        (this.db.dayPlanningLines || []).forEach((line) => {
            if (line.workOrderNo === woNo) return;
            if (line.requestedSkill !== skill || this.dplDayIndex(line) !== idx) return;
            const req = Number(line.requestedHours) || 0;
            requested += req;
            assigned += Math.min(req, Number(line.assignedHours) || 0);
        });
        return { requested: requested, assigned: assigned, shortage: Math.max(0, requested - assigned) };
    }

    taskDaySummary(section, idx) {
        const woNo = this.db.workOrder && this.db.workOrder.no;
        let requested = 0, assigned = 0;
        (this.db.dayPlanningLines || []).forEach((line) => {
            if (line.workOrderNo === woNo) return;
            if (line.requestedSkill !== section.skill || line.job !== section.job || line.task !== section.task || this.dplDayIndex(line) !== idx) return;
            const req = Number(line.requestedHours) || 0;
            requested += req;
            assigned += Math.min(req, Number(line.assignedHours) || 0);
        });
        return { requested: requested, assigned: assigned, shortage: Math.max(0, requested - assigned) };
    }

    sequenceDayLines(section, idx) {
        const self = this;
        const woNo = this.db.workOrder && this.db.workOrder.no;
        return (this.db.dayPlanningLines || []).filter(function (line) {
            return line.workOrderNo !== woNo &&
                line.requestedSkill === section.skill && line.job === section.job && line.task === section.task &&
                String(line.sequenceNo == null ? '' : line.sequenceNo) === String(section.sequenceNo == null ? '' : section.sequenceNo) &&
                self.dplDayIndex(line) === idx;
        }).slice().sort(function (a, b) {
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
    /// count, not just whatever was visible at the last full renderCentralTree call. DHTMLX's
    /// treetimeline fires onOptionsLoad both when setTreeOpenState's Expand/Collapse-all buttons
    /// recompute y_unit AND when the user clicks a single row's own fold/unfold arrow (same
    /// y_unit-recompute-then-onOptionsLoad sequence, confirmed live) - without this, collapsing
    /// rows left the wrapper's clip height (and so its scrollbar range) sized for whatever row
    /// count was visible at the last full render, producing a scrollbar whose thumb still spans
    /// the fully-expanded range and a blank gap below the now-shorter row list when scrolled down
    /// (2026-09-04 bug report). setCurrentView forces DHTMLX to re-lay-out rows against the
    /// corrected container height, matching the pattern renderWorkOrder already uses elsewhere in
    /// this file to force a post-mutation redraw.
    /// </summary>
    bindCentralTreeHeightSync(s) {
        if (this._treeHeightSyncBound) return;
        this._treeHeightSyncBound = true;
        const self = this;
        s.attachEvent('onOptionsLoad', function () {
            if (self._treeHeightSyncing) return; // re-entrancy guard - setCurrentView below can itself re-trigger onOptionsLoad
            const yUnit = s.matrix && s.matrix.centraltree && s.matrix.centraltree.y_unit_original;
            if (!yUnit) return;
            self.applyCentralTreeHeight(yUnit);
            self._treeHeightSyncing = true;
            try {
                s.setCurrentView(self.dates[0], 'centraltree');
            } finally {
                self._treeHeightSyncing = false;
            }
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
                Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('OnSequenceChipClick', [JSON.stringify({ lineId: line.id, job: line.job, task: line.task, skill: line.requestedSkill, sequenceNo: line.sequenceNo })]);
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

    /// <summary>Ports wrapper.js's own ToggleCollapseExpandAllSections technique verbatim - unchanged from before this pivot.</summary>
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
        s.callEvent('onOptionsLoad', []);
    }

    bindHierarchyButtons() {
        const self = this;
        const expandAll = document.getElementById('cpo-expand-all');
        const expandToTask = document.getElementById('cpo-expand-to-task');
        const collapseAll = document.getElementById('cpo-collapse-all');
        if (expandAll) expandAll.onclick = function () { self.setTreeOpenState(true, true); };
        if (expandToTask) expandToTask.onclick = function () { self.setTreeOpenState(true, false); };
        if (collapseAll) collapseAll.onclick = function () { self.setTreeOpenState(false, false); };
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
                if (self._scrollLock) return;
                self._scrollLock = true;
                self.liveHorizontalOwners().forEach(function (o) {
                    if (o !== owner && Math.abs(o.scrollLeft - owner.scrollLeft) > 0.5) o.scrollLeft = owner.scrollLeft;
                });
                if (bar && Math.abs(bar.scrollLeft - owner.scrollLeft) > 0.5) bar.scrollLeft = owner.scrollLeft;
                self._scrollLock = false;
            }, { passive: true });
        });

        this.refreshSharedScrollbar(bar, owners);
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

                if (self._scrollLock) return;
                self._scrollLock = true;
                self.liveHorizontalOwners().forEach(function (owner) {
                    const ownerMax = Math.max(0, owner.scrollWidth - owner.clientWidth);
                    owner.scrollLeft = Math.min(bar.scrollLeft, ownerMax);
                });
                self._scrollLock = false;

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
        // no-op placeholder - capacity lookup modal comes in a later step.
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
