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
/// Sections 1/3 are used UNCHANGED (inherited, not overridden) - AL's own
/// CPO_BuildDashboardDataJson (codeunit 50604) sends an empty "workOrderSequences": [] and no
/// "workOrder" object, which the base class's existing null-checks already handle correctly on
/// their own (title falls back to "Capacity Planning Overview" - overridden below to a dashboard-
/// appropriate caption instead; capParts()/dailyCapacityRequestData/etc. all read
/// dayPlanningLines[]/resources[] directly, none of which depend on a "workOrder" being present).
///
/// Section 4 IS overridden (2026-09-11, explicit perf/simplicity request) - the base class's own
/// Skill -> Job/Task -> Sequence drilldown tree (Expand/Exp. to Task/Collapse, buildCentralSections/
/// skillDaySummary/treeSummaryIndex/centralTreeLeftColumnHtml/renderCentralTree) is unnecessary
/// overhead on a company-wide Role Center summary tile and was the tile's actual reported slowness:
/// AL used to build a full per-line "dayPlanningLines[]"/"groups[]" payload (one JSON object per
/// real Day Planning row company-wide, paginated via a background task because it could be huge -
/// see the now-removed CPO_BuildDashboardDataJson_Paged), and the JS side then re-scanned that same
/// huge array per rendered cell (treeSummaryIndex). AL now sends a SQL-aggregated "skillDayHours[]"
/// (codeunit 50604's CPO_BuildDashboardSkillHoursJson, backed by new query 50713 "Day Planning
/// Skill Day Hours" - grouped by Skill + Plan Date, Sum(Requested/Assigned Hours) computed in the
/// database) instead - one row per Skill+Day, not per Day Planning line - so Section 4 is now a
/// FLAT list of Skills only (no Job/Task rows, no expand/collapse, no toolbar buttons - see
/// renderCapacityBars' own override below for why those buttons still had to be removed from
/// Section 3's own DOM). Section 3's own dailyCapacityRequestData() was deliberately NOT touched
/// (out of scope) - it still reads db.dayPlanningLines, which AL's new CPO_BuildDashboardDataJson
/// keeps sending, just reshaped to one row per Skill+Day (see that procedure's own doc comment for
/// the one narrow, documented rounding difference this can introduce).
/// </summary>
class CapacityPlanningDashboard extends CapacityPlanningOverview {
    constructor(containerId) {
        super(containerId);

        // BUG FOUND 2026-09-08 (reported live, flagged "dangerous"): Section 1 ("Calculated
        // conclusion" / "Current position shortage" / the "Hours overview" C/R mini-bars) used to
        // be the base class's evaluateWO()/currentPositionShortage() (both REMOVED 2026-09-15 - see
        // excludingWOFlow's own doc comment), which measured ONLY the incremental company-wide
        // shortage caused by placing THIS INSPECTED WORK ORDER'S OWN demand (workOrderSequences[])
        // on top of everyone else's baseline. On this tile there is no inspected Work Order - AL
        // always sends an EMPTY workOrderSequences[] (see codeunit 50604's
        // CPO_BuildDashboardDataJson) - so that "before"/"after" maxFlowDay() comparison was always
        // identical (adding zero demand), which made Section 1 render a CONSTANTLY GREEN
        // "100% / no shortage / 0h" for every single day, regardless of how much real demand
        // Section 4's tree showed for that same day - a false "all clear" signal on a
        // capacity-planning tool, not a cosmetic glitch, so Section 1 was removed entirely from
        // this tile rather than show a number that looked real but was structurally guaranteed to
        // always say "fine".
        //
        // STALE AS OF 2026-09-15: the base class's Section 1 no longer computes a before/after
        // delta at all - excludingWOFlow() reads maxFlowDay() DIRECTLY against
        // this._baselineWithoutWO (all day planning excluding the selected Job/Task set), which on
        // THIS tile is genuinely non-constant and meaningful (selectedWOKeys() is empty here, so
        // _baselineWithoutWO is simply ALL company-wide demand, unfiltered - the exact same
        // universe Section 4's flat skill list already summarizes). The specific bug this removal
        // fixed (a structurally-guaranteed-constant "100%/no shortage") therefore no longer applies
        // to this tile. Section 1 is STILL removed here, deliberately NOT restored by this pass -
        // re-enabling it is a separate product decision (would need its own DOM/CSS work, e.g. the
        // #cpo-wo-summary node this constructor still removes below), out of scope for the JS-only
        // Section 1 recompute this comment now describes. Flag to the user as a worthwhile
        // follow-up if a company-wide "Calculated conclusion" row would be useful on this tile.
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
    /// and only hides the title afterward (2026-09-17, explicit request to remove the "Capacity
    /// Planning" title text - the tile doesn't need one). Needed because the base class's own
    /// applyPlanningData unconditionally rebuilds #cpo-title's content based on `this.db.workOrder`
    /// (falls back to "Capacity Planning Overview" when absent, which it always is on this tile -
    /// see this file's own class-level doc comment) - EVERY call, including the first one from
    /// ControlReady, so a one-time constructor-level hide (tried initially) gets silently undone
    /// the moment real data arrives. #cpo-title is its own flex item inside .cpo-top-bar, a sibling
    /// of (not a parent of) the "Days to show" input/label and #cpo-bg-loading - hiding just this
    /// element leaves those untouched.
    /// </summary>
    applyPlanningData(json) {
        // Must be cleared BEFORE super.applyPlanningData() runs, not after - super's own
        // applyPlanningData ends by calling this.renderCentralTree(), which (overridden below)
        // reads dashSkillDayIndex() while building each cell - a stale index from the PREVIOUS
        // load would render last refresh's numbers for one frame (or forever, if a skill/day
        // combination present before disappears in the new data - a stale entry would never get
        // overwritten, only new keys would be added on top of it).
        this._dashSkillDayIndex = null;
        super.applyPlanningData(json);
        const titleEl = document.getElementById('cpo-title');
        if (titleEl) titleEl.style.display = 'none';
    }

    /// <summary>
    /// Thin override - reuses the base class's ENTIRE Section 3 rendering via super() (bar
    /// segments, tooltips, scroll-sync, day-click handlers all stay byte-identical - Section 3's
    /// own data/logic is explicitly OUT of scope for this tile's Section-4 simplification, see this
    /// class's own header doc comment) and only removes the Expand/Exp. to Task/Collapse toolbar
    /// afterward. Must run on EVERY call, not just once from the constructor, because the base
    /// class's renderCapacityBars() rebuilds host.innerHTML (including the buttons' own markup)
    /// from scratch on every single data refresh - same "thin override, call super, then patch DOM,
    /// every time" pattern this file's own applyPlanningData override above already uses for the
    /// title. Removing the whole `.cpo-daily-chart-total-actions` wrapper (rather than the 3
    /// buttons individually) matches the base class's own `<div class="cpo-daily-chart-total-
    /// actions">` grouping, so no button can be missed if a future base-class change adds a 4th one
    /// to that same wrapper. The base class's bindHierarchyButtons() still runs (inside super's own
    /// call) and briefly wires onclick handlers to these buttons before they're removed here - that
    /// is harmless (removing a DOM node with bound handlers doesn't error or leak) and not worth an
    /// extra override just to skip.
    /// </summary>
    renderCapacityBars(json) {
        super.renderCapacityBars(json);
        const host = document.getElementById('cpo-capacity-bars');
        const actionsBar = host && host.querySelector('.cpo-daily-chart-total-actions');
        if (actionsBar) actionsBar.remove();
    }

    /// <summary>
    /// Overrides the base class's "Open Day Planning(s)" wording for Section 4's right-click menu
    /// (attachTreeContextMenu, called from this file's own renderCentralTree override above) - same
    /// underlying action (OnOpenDayPlanningList, this tile's cells never produce a chip so the card
    /// branch can't fire here), just presented as "Show Data" to match this tile's own Section 3
    /// bar-chart context menu (attachCapacityBarsContextMenu) and the neighboring Daily/Weekly
    /// Insights charts' identical wording. Page 50722's own Section 4 keeps the base class's default
    /// caption unchanged - explicit instruction not to touch that page's wording.
    /// </summary>
    treeContextMenuCaption() {
        return 'Show Data';
    }

    /// <summary>
    /// Section 4 tree skeleton - flat Skill-only nodes, no Job/Task/Sequence children (see this
    /// class's own header doc comment). Built from `this.skills` (already the exact distinct-skill,
    /// color-ordered list the base class's own applyPlanningData derives from AL's "skills[]" array
    /// - unchanged/shared code, see codeunit 50604's CPO_BuildSkillsArray) rather than from
    /// `this.db.groups`, which AL no longer sends for this tile at all.
    /// </summary>
    buildCentralSections() {
        return this.skills.map(function (skill) {
            return { key: 'skill:' + skill, section_id: 'skill:' + skill, label: skill, skill: skill, type: 'skill' };
        });
    }

    /// <summary>
    /// O(1)-per-cell Skill+Day lookup, built ONCE per render pass straight from AL's own
    /// pre-aggregated "skillDayHours[]" (codeunit 50604's CPO_BuildDashboardSkillHoursJson / query
    /// 50713 "Day Planning Skill Day Hours") - replaces the base class's treeSummaryIndex(), which
    /// scanned the full company-wide "dayPlanningLines[]" array (one entry per real Day Planning
    /// row) to build the same kind of index. skillDayHours[] is already summed server-side in SQL
    /// (one row per Skill+Plan Date), so this index is tiny (skills x days) regardless of how many
    /// real Day Planning rows exist company-wide - this is the actual perf fix this tile needed.
    /// Cleared by applyPlanningData() above on every fresh load, same convention as the base
    /// class's own _treeSummaryIndex.
    /// </summary>
    dashSkillDayIndex() {
        if (this._dashSkillDayIndex) return this._dashSkillDayIndex;
        const idx = {};
        (this.db.skillDayHours || []).forEach((row) => {
            const i = this.dayIndex(cpoParseDateOnly(row.date));
            if (i < 0 || i >= this.dates.length) return;
            idx[row.skill + '|' + i] = { requested: Number(row.requested) || 0, assigned: Number(row.assigned) || 0 };
        });
        this._dashSkillDayIndex = idx;
        return idx;
    }

    /// <summary>
    /// Overrides the base class's dayPlanningLines-scanning version - see dashSkillDayIndex's own
    /// doc comment. Same return shape as the base method (requested/assigned/shortage), so the
    /// shared cell-value rendering logic ported into this class's own renderCentralTree override
    /// below needs no further changes to consume it.
    /// </summary>
    skillDaySummary(skill, idx) {
        const agg = this.dashSkillDayIndex()[skill + '|' + idx] || { requested: 0, assigned: 0 };
        return { requested: agg.requested, assigned: agg.assigned, shortage: Math.max(0, agg.requested - agg.assigned) };
    }

    /// <summary>
    /// Flat single "Skill" left-column cell - overrides the base class's 3-column Skill/Job/Task
    /// grid (`.cpo-central-left-grid`), since every row on this tile is now a skill row (no
    /// 'detail'/'sequence' node types can occur any more, see buildCentralSections above). Uses its
    /// own `.cpo-dash-skill-cell` CSS class (this folder's own style.css) rather than reusing
    /// `.cpo-skill-left-grid` (a 3-span CSS grid) - repurposing a 3-column grid for 1 populated
    /// column would leave dead blank grid space instead of a clean single-column layout.
    /// </summary>
    centralTreeLeftColumnHtml(o) {
        if (!o || o.key === 'nodata') return o && o.label ? cpoEsc(o.label) : '';
        return '<div class="cpo-dash-skill-cell">' + cpoEsc(o.skill || o.label) + '</div>';
    }

    /// <summary>
    /// Whole-method override (2026-09-11), not a smaller hook - the base class's renderCentralTree
    /// hard-codes a 3-column "Skill/Job/Task" columns[] header and a cell-value template with
    /// 'skill'/'detail'/'sequence' branches, and there is no separate overridable method for just
    /// that header/columns config (see this add-in's own project instructions/doc comment on this
    /// method). Kept as close to the base implementation as possible - same Scheduler
    /// plugins/config/teardown calls, same createTimelineView shape, same row-height/height-sync
    /// helpers (applyCentralTreeHeight/bindCentralTreeHeightSync, both inherited unchanged - they
    /// already work off a generic yUnit array and don't care whether nodes have children). The only
    /// real differences from the base method: (1) a single "Skill" column instead of the 3-column
    /// Skill/Job/Task grid, sized with this class's own DASH_TREE_LABEL_WIDTH (140px, see that
    /// constant's own doc comment below the class) instead of the base class's shared
    /// TREE_LABEL_WIDTH (360px - sized for the 3-column grid this tile no longer has), (2) the
    /// cell-value template only ever needs the flat-skill case (no 'detail'/'sequence' branches,
    /// since buildCentralSections() never produces those node types any more), (3)
    /// attachTreeChipTooltip() is NOT called - there are no `.cpo-tree-chip` elements on this tile
    /// any more (no sequence-level leaf rows), so wiring that listener would be dead code.
    /// </summary>
    renderCentralTree(json) {
        if (typeof Scheduler === 'undefined') {
            console.error('CapacityPlanningDashboard: DHX Scheduler library not loaded.');
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
        const yUnit = yUnitBuilt.length > 0 ? yUnitBuilt : [{ key: 'nodata', section_id: 'nodata', label: 'No skill demand in this window', type: 'skill' }];

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
            dx: CapacityPlanningDashboard.DASH_TREE_LABEL_WIDTH,
            scrollable: true,
            columns: [{
                label: '<div class="cpo-central-left-header cpo-dash-central-left-header"><span>Skill</span></div>',
                width: CapacityPlanningDashboard.DASH_TREE_LABEL_WIDTH,
                template: function (o) { return self.centralTreeLeftColumnHtml(o); }
            }],
            cell_template: true,
            scale_height: CapacityPlanningOverview.SCALE_HEIGHT
        });

        s.date.centraltree_start = function () { return self.dates[0]; };
        s.templates.centraltree_scalex_class = function (date) { return cpoIsWeekend(date) ? 'cpo-weekend-scale' : ''; };
        s.templates.centraltree_row_class = function () { return 'cpo-tree-row-skill'; };
        s.templates.centraltree_cell_class = function (evs, date) { return cpoIsWeekend(date) ? 'cpo-weekend-cell' : ''; };
        s.templates.centraltree_cell_value = function (evs, date, section) {
            if (!section || section.key === 'nodata') return '';
            const idx = self.dayIndex(date);
            if (idx < 0 || idx >= self.dates.length || cpoIsWeekend(date)) return '';
            const m = self.skillDaySummary(section.skill, idx);
            if (!m.requested) return '';
            const meta = self.skillMeta(section.skill);
            const pct = m.requested ? Math.max(0, Math.min(100, m.assigned / m.requested * 100)) : 100;
            // Assigned% portion uses the shared "Assigned Color" (meta.assignedColor), not
            // meta.dark (that skill's own border color) - see the base class's identical fix in
            // capacityPlanningOverview.js's own centraltree_cell_value, and CPO_BuildSkillsArray's
            // doc comment (codeunit 50604) for the full root-cause writeup.
            return '<div class="cpo-tree-summary-cell" data-master-skill="' + cpoEsc(section.skill) + '" data-day-index="' + idx + '" style="background:linear-gradient(to right,' + (meta.assignedColor || meta.dark) + ' 0 ' + pct + '%,' + meta.light + ' ' + pct + '% 100%)"><b>' + m.requested + 'h</b></div>';
        };
        s.templates.event_class = function (a, b, e) { return 'cpo-planner-event cpo-skill-' + cpoSlug(e.skill); };
        s.templates.event_bar_text = function (a, b, e) { return e.hours || ''; };

        s.init('cpo-central-tree', this.dates[0], 'centraltree');
        s.clearAll();
        // Right-click "Open Day Planning(s)" (base class's attachTreeContextMenu, added for page
        // 50722's Section 4) - NOT wired automatically here since this whole method is a full
        // override, not a super() call. Safe to reuse unmodified: this tile's summary cells are the
        // exact same .cpo-tree-summary-cell markup (data-master-skill + data-day-index, no
        // data-job/data-task) the base method's "skill" branch already handles - there are no
        // .cpo-tree-chip elements on this tile (see this method's own doc comment on why
        // attachTreeChipTooltip is skipped), so only the summary-cell ("open list") branch can ever
        // fire here, never the single-line card branch.
        this.attachTreeContextMenu();
        this.bindCentralTreeHeightSync(s);
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

/// <summary>
/// Dashboard-only override of the base class's shared TREE_LABEL_WIDTH (2026-09-11 follow-up,
/// explicit layout-tweak request from a live screenshot). CapacityPlanningOverview.TREE_LABEL_WIDTH
/// (360px, see that file's own doc comment at its declaration) is a base-class static shared with
/// page 50722's own Skill/Job/Task 3-column grid - it is NOT changed here, since narrowing it would
/// also narrow page 50722's still-3-column left grid, which genuinely needs the wider width. This
/// tile's own Section 4 is now a flat single "Skill" column (see buildCentralSections/
/// centralTreeLeftColumnHtml above), so it only ever needs to fit one Skill Code value - Skill Code
/// (base table)'s Code field is Code[10] (confirmed via symbol search), and every real skill code
/// in this company's data today (CIVIL/DESIGN/DRILLING/ELEKTR/MECH/MOLDER/SANITAIR/SCRAPING/WELD)
/// is 8 characters or shorter. 140px = ~10 bold 12px uppercase characters (the field's own max
/// length, not just today's longest real value) plus the cell's 10px left padding plus a comfortable
/// right margin - fits the longest existing code with headroom up to what the field could ever hold.
/// Used by this file's own renderCentralTree override (dx + the "Skill" column's width) above.
///
/// Section 3's ".cpo-daily-chart-fixed" ("Totals" header box) shares this same width BY DESIGN
/// (sections 3+4 form one visually-aligned block - see CapacityPlanningOverview's own doc comment
/// on TREE_LABEL_WIDTH), but that box is rendered by the UNCHANGED, inherited base-class
/// renderCapacityBars() (called via super() in this file's own override above) - its width is a
/// hardcoded `CapacityPlanningOverview.TREE_LABEL_WIDTH` inline style, not something this subclass's
/// JS can retarget without duplicating that method's ~40-line template just to swap one number. It
/// is narrowed to the SAME 140px instead via a `!important` CSS rule in this folder's own style.css
/// (loaded last, only for this controladdin), so Sections 3 and 4 keep lining up without touching
/// the base class or page 50722.
/// </summary>
CapacityPlanningDashboard.DASH_TREE_LABEL_WIDTH = 140;
