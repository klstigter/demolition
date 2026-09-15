---
name: project_cpo_section3_exclude_flip_2026-09-15
description: Capacity Planning Overview (page 50722)/Dashboard (page 50724), 2026-09-15 session — Section 3 exclude-flip + drill-down fix, a CRITICAL background-load-timing gotcha for verifying ANY of this, Section 1's evaluateWO/currentPositionShortage replaced by position-independent excludingWOFlow, and a new title-bar audit-totals box
metadata:
  type: project
---

**This is at least the FOURTH documented scoping-direction correction on
`src\dhx\capacity_planning_overview\capacityPlanningOverview.js`** (see
[[project_cpo_cross_wo_scope_fix]] 2026-09-03, a 2026-09-08 "undefined woNo" bug fix, a 2026-09-14
critical scoping fix, and now this 2026-09-15 flip). **If asked to touch Section 3's scoping again,
re-read the current code — do not trust any older memory's stated direction, including this one,
without re-checking `dailyCapacityRequestData()`'s own filter line.**

**What changed (2026-09-15, explicit user ask):** Section 3's "Hours overview"/"Requested vs
Capacity" daily bar chart's "Requested" side used to be INCLUDE-only — `dailyCapacityRequestData()`
kept ONLY the inspected Work Order's (Job Task's) own `dayPlanningLines[]` entries
(`line.workOrderNo !== woNo` → skip). Flipped to EXCLUDE-only — `line.workOrderNo === woNo` → skip
— so it now shows ALL company-wide day planning demand in the visible window MINUS the inspected
WO's own lines (which Sections 1/2 already show). **This makes Section 3's demand universe and
Section 4's tree (`treeSummaryIndex()`, unchanged, already `===`-exclude since 2026-09-03) byte-
identical** — verified live: both summed to 376h for the same window/DWO0008-equivalent
(10000/1080, "Snag List Resolution", still present in this company as of 2026-09-15 even though
the "Work Order" table itself is gone — see [[project_cpo_work_order_table_removal_migration]]).
Purpose: when the user drags a Section-3 bar to relocate work to a different day, they need to see
how much capacity OTHER work has already claimed that day.

**capParts() (capacity/supply side) and Section 1/2 scoping were explicitly OUT of scope and left
untouched** — capParts() was already company-wide by design (own doc comment), Section 1/2 stay
`===`-include (inspected WO only).

**Drill-down fix, same file (~line 1745-1769), `attachCapacityBarsContextMenu`'s `contextmenu`
listener:** previously, for a REQUEST-column segment right-click when there WAS an inspected WO,
the payload sent `job`/`task` = the inspected WO's own Job No./Job Task No. as an INCLUDE filter to
AL's `CPO_OpenDayPlanningList` (`src\codeunit\codeunit_50604_DHXDataHandler.al` ~line 6564-6617,
called via `CPO_ShowCapacityBarSegment` ~6657+) — which only supports `SetRange` (include), not
exclude. Since the segment now VISUALLY represents "everything EXCEPT the inspected WO", sending
that WO's own job/task as an include filter would open the exact opposite/wrong record set. Fix:
removed the `if (col.dataset.summaryKind === 'request' && hasInspectedWO) {...}` block entirely —
`scopeJob`/`scopeTask` now always stay `''` for request segments on both pages (page 50722 now
matches what page 50724/Dashboard already always sent, since Dashboard has no inspected WO).
Verified live via a stubbed `Microsoft.Dynamics.NAV.InvokeExtensibilityMethod` + a dispatched
`contextmenu` event on a real `.cpo-daily-chart-segment[data-seg="skill:..."]` DOM node on BOTH
pages — payload's `job`/`task` are both `""` in both cases. **Known, accepted minor over-inclusion**
(AL has no exclude-filter mechanism today): "Show Data" on a request segment now opens every
matching skill+date Day Planning company-wide (a slight superset — also includes the inspected WO's
own lines, which the segment itself excludes) — documented inline in both the JS and
`CPO_ShowCapacityBarSegment`'s own AL doc comment, not fixed with a real exclude filter (judged not
worth the AL complexity for a rarely-hit edge case; revisit only if `CPO_OpenDayPlanningList` ever
grows a real exclude-filter capability).

**Doc comments updated (3 places, all previously stale after this flip):**
1. `dailyCapacityRequestData()`'s own comment block (capacityPlanningOverview.js ~1503).
2. Class-level header comment point 5 (capacityPlanningOverview.js ~119-134) — used to describe the
   OLD `===`-include-for-3 vs `!==`-include-for-4 asymmetry; now describes both sections using the
   SAME `===`-exclude direction.
3. AL side: `CPO_BuildPlanningDataJson`'s Pass 3 doc comment (codeunit_50604 ~6948-6956, said
   "keep section 3's own Requested bar scoped to WorkOrderNo" — stale) and
   `CPO_ShowCapacityBarSegment`'s own doc comment (~6630-6637, said job/task are "only ever sent...
   for a REQUEST-bar segment" — stale, now says the JS never populates them anymore).

**Live verification (2026-09-15, NL_Copy20240710/CRONUS NL, Job 10000/Task 1080 "Snag List
Resolution"):**
- Manually recomputed `dailyCapacityRequestData()`'s expected EXCLUDE totals per day directly from
  `db.dayPlanningLines` in-browser and diffed against the live rows — 0 mismatches across all 30
  visible days, total 376h both ways (vs. what the OLD include-only code would have shown: 24h,
  the inspected WO's own demand only).
- Section 3's total (376h) and Section 4's `treeSummaryIndex()` total (376h) now match exactly —
  confirms both sections read the same universe.
- Dashboard page 50724 (`hasInspectedWO` false) unaffected — 3304h/812h/1419h on 16/17/18 Sep,
  matching the screenshot, matching pre-existing fully-company-wide behavior (nothing to exclude
  when `woNo` is `undefined`, same reasoning as the 2026-09-08 bug fix note this supersedes in
  direction only, not in the undefined-woNo guard logic itself).
- Console errors: baseline pattern present (1x graph.microsoft.com photo 404 on both pages; 6x
  company-switcher 401s — HQ_DE/UK_HQ/HQ_DK/HQ_IT/HQ_AT/HQ_FR — on page 50722 only, none observed on
  50724 this run) PLUS a new-to-this-session cluster of ~12 CORS-blocked Office telemetry beacon
  errors (`*.fp.measure.office.com`, `*.connectivity-test.static.microsoft`, `tr-*-atm.office.com`
  `trans.gif`/`r.gif` calls) on both pages — these hit Microsoft first-party telemetry domains, not
  any file this add-in owns; almost certainly a session/network-specific artifact (proxy or browser
  context CORS policy), not caused by this pass's AL/JS changes. Flagged, not treated as a
  regression, since nothing in the stack traces or URLs references this add-in's own code.

Compile (`al_compile onlyErrors=true`): 0 errors. Build (`al_build onlyErrors=true`): succeeded,
`Optimizers_DailyOptimizer_28.0.0.12.app`, 0 warnings. Publish (`al_publish
projectPath=<repo root> skipBuild=true environmentName=NL_Copy20240710`): succeeded.

---

## CRITICAL FOLLOW-UP CORRECTION (same day, 2026-09-15): the "376h total" verification above was measured on a STILL-LOADING dataset — don't trust it as a magnitude check

The coordinator flagged that 376h summed across 30 days looked far too small next to a real live
figure the user had seen on the Dashboard (page 50724, Wed 16 Sep alone: **3304h**). Investigating
found the root cause exactly as suspected: **this add-in's "other Work Order" data loads via a
SEPARATE, SLOW, single-shot Page Background Task** (`EnqueueOtherWorkOrderDataBackgroundTask` →
codeunit "CPO BG Other WO Data" → `OnPageBackgroundTaskCompleted` → `OnPollOtherWorkOrderDataResult`
→ `AppendOtherWorkOrderData`, all in `page_50722_CapacityPlanningOverview.al`/`wrapper.js`) that
runs AFTER the page's own initial synchronous render. My original same-day verification captured
`db.dayPlanningLines` at **107 lines** (37 own + 70 other) — the FIRST synchronous page only. The
real, fully-loaded company-wide total was **6628 lines** (confirmed live, same session, same
Job 10000/Task 1080/CRONUS NL) — a **62x** under-count. Once fully loaded, Section 3's Wed-16-Sep
figure read **3304h**, Section 4's tree read the same **3304h**, this WO's OWN demand that day was
**0h**, and 3304 + 0 = 3304 = the Dashboard's own real figure for the same day — **exact
reconciliation, confirmed via the live rendered DOM text** (`"2180h  3304h"` under the C/R columns
on BOTH page 50722 and page 50724), not just internal JS state. The EXCLUDE-flip direction itself
was correct all along (0 mismatches against a manual per-day recompute, both with the partial AND
the full dataset) — only the MAGNITUDE claim in the original write-up above was an artifact of
verifying too early.

**Practical consequence for any future verification pass on this add-in (page 50722 specifically —
page 50724/Dashboard has no such background task, its own single query is synchronous and
complete):** after opening the page, poll `document.getElementById('cpo-bg-loading').style.display`
(inline style, set by `showBackgroundLoading()`/`hideBackgroundLoading()` in
capacityPlanningOverview.js) — `'none'` means the background load is done (or was never needed,
i.e. everything fit on the first page); anything else means it is STILL RUNNING and
`db.dayPlanningLines`/anything derived from it (`_baselineWithoutWO`, `excludingWOFlow()`,
`treeSummaryIndex()`, Section 3's own totals) is INCOMPLETE. **Do not treat a "0 mismatches
against Section 4" self-consistency check as sufficient on its own** — both sections read the exact
same (possibly still-partial) array, so they will always agree with each other even when both are
wrong relative to real BC data; only a comparison against an INDEPENDENT source (the Dashboard tile,
or a raw Day Planning query) actually proves completeness.

**This background load is also genuinely SLOW and, this session, somewhat flaky** — observed taking
well over a minute in one run (6628 lines eventually arrived, no errors) and, in a LATER run against
the identical Job Task on the identical page, stalling indefinitely at 107 lines for several minutes
with a real console error logged once (`OnPollOtherWorkOrderDataResult poll failed: undefined`,
`wrapper.js:119`) and no further progress observed within this session's patience budget. This
happened on BOTH the reconciliation pass and, separately, on the Section-1 re-verification pass
after publishing — i.e. reproduced twice. **Not caused by anything touched this session** (no edit
was made to `page_50722_CapacityPlanningOverview.al`, `wrapper.js`, or `codeunit_50722_CPOBGOtherWorkOrderData.al`
in this session) — flagging as a real, pre-existing intermittent reliability gap in the background
pagination plumbing worth a dedicated look if it keeps happening; a future session should expect to
possibly need several minutes of patience (or several fresh page-open attempts) before the full
company-wide dataset is actually available to test against, and should always check
`cpo-bg-loading`'s style before trusting any "total" number, not just this add-in's console for
errors.

---

## Section 1 recompute (same day, 2026-09-15, explicit user request, AFTER the reconciliation above)

User confirmed (direct question, not inferred) that Section 1 ("Calculated conclusion"/"Current
position shortage" stats header, `renderWoSummaryScheduler`) should ALSO report shortage/coverage
for "all day planning in the window excluding this project task" — directly, not via the OLD
before/after MARGINAL-delta design (`evaluateWO(start)`/`currentPositionShortage()`, both REMOVED).

**Key discovery before touching anything:** `this._baselineWithoutWO`
(`aggregateOutstandingRequestsWithoutWO()`) was ALREADY built excluding the inspected WO's own
Job No./Job Task No. (via `selectedWOKeys()`, filtering `line.job+'|'+line.task`) — this has been
true since this baseline was first written, well before this session. The OLD design didn't use that
exclusion directly, though — it ADDED this WO's own demand back on top of that baseline (`extra`,
via `workOrderExtra(start)`/`workOrderExtraCurrent()`), re-ran `maxFlowDay`, and reported the
INCREASE in shortage caused by that addition (a "how much worse does my own demand make things"
metric) — a materially different question than "what does the baseline alone already look like."

**Fix — new method `excludingWOFlow()`** (replaces `evaluateWO`/`currentPositionShortage`/
`workOrderExtra(start)`/`_evalWOCache`/`_currentPositionShortageArr`, all REMOVED; also removed two
now-dead helpers `validStart`/`maxVisibleWOWorkday`, only ever called by the removed `evaluateWO`):
reads `maxFlowDay(i, this._baselineWithoutWO[i])` DIRECTLY, no delta, no add-back. Cached in
`this._excludingWOFlowArr`, reset only by `applyPlanningData()`/`appendOtherWorkOrderData()` (a
fresh `_baselineWithoutWO`) — **deliberately NOT cleared by `resetAnchorDependentCaches()`
anymore** (that method now only clears `_currentPositionSkillShortageArr`, Section 2's own cache,
the one remaining before/after-delta consumer via `workOrderExtraCurrent()` — UNCHANGED, still used
by `renderWorkOrder()` to allocate shortage across Section 2's own sequence-row bars). Both Section
1 rows (`renderWoSummaryScheduler`'s cell_class/cell_value templates) now read the SAME
`excludingWOFlow()[idx]` result — row 1 ("Calculated conclusion") as a coverage %, row 2 ("Current
position shortage") as raw hours — two views of one number, not two independent calculations
anymore.

**Direct, INTENDED consequence, confirmed live via a synthetic drag simulation (not a real
Playwright drag, but the exact same JS calls a drag triggers — `setOccurrenceDayIndex` +
`resetAnchorDependentCaches()`):** `excludingWOFlow()` now returns the LITERAL SAME cached array
object (`before === after`, `===` true) before and after moving an occurrence — Section 1 is now
POSITION-INDEPENDENT, dragging a bar in Section 2 no longer changes Section 1's numbers AT ALL. This
is correct: a number that excludes this task's own demand by definition cannot depend on where that
excluded demand currently sits. Confirmed in the SAME test that Section 2's own
`_currentPositionSkillShortageArr` DOES still get cleared by `resetAnchorDependentCaches()` — its
one remaining consumer is unaffected by this change.

**Dashboard (page 50724) side note — a STALE bug-justification comment fixed, behavior NOT
changed:** `capacityPlanningDashboard.js`'s constructor removes `#cpo-wo-summary` (Section 1) from
the DOM entirely, dating to a 2026-09-08 fix for the OLD design (`workOrderSequences[]` always empty
on this tile → before/after delta always zero → Section 1 rendered a structurally-guaranteed-
constant "100%/no shortage", a false "all clear" signal). **That specific bug no longer applies**
to the new `excludingWOFlow()` — on the Dashboard, `selectedWOKeys()` is empty (no
`workOrderSequences[]`), so `_baselineWithoutWO` is simply ALL company-wide demand unfiltered, which
IS genuinely meaningful there (same universe Section 4's own flat skill list already shows). Section
1 is STILL removed on the Dashboard as of this session — deliberately NOT restored, since
re-enabling it is a separate product/DOM decision out of scope for this pass — but the comment
explaining WHY it's removed has been corrected to say so explicitly, with a note flagging this as a
worthwhile follow-up if the user ever wants a company-wide "Calculated conclusion" row on that tile.

**AL-side stale comments also fixed** (`codeunit_50604_DHXDataHandler.al`, several spots — search
for `excludingWOFlow` in that file to find them all): every doc comment naming
`evaluateWO`/`currentPositionShortage`/`workOrderExtra(start)` as still-live was updated to name
`excludingWOFlow`/`currentPositionSkillShortage`/`workOrderExtraCurrent` instead, including the
`CPO_MaxResourcesPerSkill`/`ApplyPerSkillCap` doc comments (why the 15-resources-per-skill cap
exists) and the "broadening skills[]/resources[]/externalFree[] is safe" reasoning (now explains
TWO independent safety arguments — Section 2's before/after delta-cancellation, unchanged, AND
Section 1's NEW reliance on `maxFlowDay`'s own demand-capping property instead, since there's no
delta left to cancel through).

**Live verification:** ran with the FIRST-page-only (107-line) dataset (see the background-load
timing gotcha above — the full 6628-line set did not finish loading within this session's patience
budget on the re-verification pass). Confirmed: `excludingWOFlow()` runs without error, returns
varying (non-constant) per-day `{coverage, totalShortage, totalRequested}` — e.g. `totalRequested`
0/40/25/26/8/8/0 across the first several visible days, all fully covered (100%/0h) against this
still-partial demand and this demo's large resource pool — sane, data-driven, not the OLD bug's
structurally-guaranteed constant. Did NOT get to observe a genuinely non-zero shortage number live
this session (would need the full company-wide dataset, which never finished loading in the
re-verification pass) — but the reconciliation work above already proved the SAME underlying
`_baselineWithoutWO`/`dayPlanningLines[]` scales to very large real numbers (3304h on one real day)
once fully loaded, computed by the exact same code path `excludingWOFlow()` now reads directly, so
there is strong indirect confidence a real shortage would show once that data is present — just not
independently confirmed live this session. Worth a follow-up spot-check if the background-load
flakiness above is ever resolved.

---

## Title-bar audit-totals box (same day, 2026-09-15, third and final item of this session)

User asked for a bordered box next to the title text, page 50722 only, showing manual cross-check
totals: `"Requested: <N> hours | Assigned: <N> hours"` (exact wording, spelled-out "hours") — scoped
to THIS inspected WO's OWN Day Planning lines only (`db.dayPlanningLines[]` where
`workOrderNo === woNo`) — i.e. deliberately the OPPOSITE scope from Section 3's own exclude-this-WO
universe, so the user can manually add the two back together when eyeballing a day's numbers against
Section 3's bars. "Assigned" is the RAW/uncapped `assignedHours` sum, NOT `Math.min(requested,
assigned)` — can legitimately exceed "Requested".

**Implementation, `capacityPlanningOverview.js`'s `applyPlanningData()`:** `#cpo-title` (previously
a single `.textContent` write) is now a small flex row rebuilt every call —
`<span class="cpo-title-text">` (the existing title string, unchanged) plus, only when
`this.db.workOrder` is truthy, `<span id="cpo-title-audit" class="cpo-title-audit-box">`. Confirmed
via code reading (not just assumed) that this WO's own lines are the AL-side Pass 1 set — always
built IN FULL, unpaginated, on the very first `SetPlanningData` call
(`CPO_BuildPlanningDataJson_Paged`'s own doc comment) — and that `appendOtherWorkOrderData()`'s
later background-loaded lines are, by AL's own Pass 3 query filter, GUARANTEED to never carry
`workOrderNo === woNo` (excluded server-side) — so this total is complete and stable from the first
render; deliberately NOT recomputed inside `appendOtherWorkOrderData()` (documented inline in both
methods' own doc comments, cross-referencing each other).

**CSS, `style.css`:** `.cpo-top-title` is now `display:flex` (was a single text block with its own
ellipsis) — the ellipsis-on-overflow behavior moved to the new `.cpo-title-text` inner span (a flex
container with two children can't itself ellipsize). New `.cpo-title-audit-box` reuses the existing
`#2f6fdb` accent blue (same as `.cpo-confirm-btn-pending`) for its border/text color rather than a
new palette entry. Confirmed both the Dashboard's controladdin (`DHXCapacityPlanningDashboardAddin`)
and page 50722's own controladdin load this SAME shared `style.css` file — safe no-op on the
Dashboard since `this.db.workOrder` is always falsy there, so the audit-box `<span>` is simply never
created on that tile.

**Live verification, FIRST pass (Job 10000/Task 1080, partial 107-line dataset):** rendered box
read **"Requested: 24 hours | Assigned: 0 hours"** — cross-checked by manually filtering
`db.dayPlanningLines` to `workOrderNo === woNo` (37 real lines) — 24/0, an exact match against the
box.

**CORRECTION (same day, coordinator pushback after a fresh screenshot):** the coordinator flagged
24h as implausibly low against the ~12+ visible chips across 6 sequence rows in Section 2 and asked
for ground-truth re-verification before trusting it. Investigation (independent of the JS/AL
pipeline entirely — direct OData queries via `mcp__NL_Copy20240710__List_DayPlanningLines_PAG50675`
and `List_DayPlannings_PAG50606` against Job No. "10000"/Job Task No. "1080" in CRONUS NL) found:
- **The 24h/0h figures were numerically correct as an ALL-TIME total** — ground truth: 37 real
  lines, exactly 3 non-zero (2026-09-08/09/10, ELEKTR sequenceNo 1, 8h each = 24h requested), the
  other 34 genuinely have `Requested Hours = 0` / `Assigned Hours = 0` in the live table itself —
  this is real seeded demo data, not a computation bug. (Also discovered en route: this OData API's
  own `workedHours` field maps to `"Worked Hours"`, NOT `"Assigned Hours"` — a real trap for any
  future ground-truth query on this data; `List_DayPlannings_PAG50606`, not `_PAG50675`, is the one
  that exposes true `"Assigned Hours"` as `assignedHours`.)
- **But a real scope bug WAS found**: the box's `applyPlanningData()` code filtered only by
  `workOrderNo === woNo`, with NO date-window filter — while AL's own Pass 1 query
  (`CPO_BuildPlanningDataJson_Paged`, confirmed by reading the actual AL) is `SetRange("Job No.")`/
  `SetRange("Job Task No.")` ONLY, no `SetRange("Plan Date", ...)` — so `db.dayPlanningLines[]`
  legitimately carries this WO's lines from OUTSIDE the visible "Days to show" window too. The
  user's own stated purpose ("value is based on Day plannings in Project Task in period 30 days
  selected") requires window-scoping, which the code didn't apply. Root cause of the "impossible"
  visual mismatch: the 3 real 8h lines are dated 2026-09-08/09/10, entirely BEFORE this test case's
  visible window (which starts "today" = 2026-09-15) — Section 2 never renders them as bars for the
  identical reason (`getOccurrenceDayIndex()` for a before-window date falls outside `[0,
  dates.length)` too, so they're invisible there as well) — so the "12+ chips" the coordinator saw
  are ALL zero-hour lines, and the real 24h of demand was sitting entirely outside the window,
  invisible in both Section 2 AND (pre-fix) silently included in the audit box despite being outside
  what the box claims to total.
- **Fix applied**: added a `dplDayIndex(line)` bounds check (`>= 0 && < dates.length`) alongside the
  `workOrderNo` filter, matching the exact convention `dailyCapacityRequestData`/`aggregateRequests`
  already use elsewhere in this file for "is this line inside the visible window" — one extra `if`
  inside the existing `forEach`, `self = this` captured beforehand since the callback is a plain
  function. Doc comment above the block corrected (the removed claim that Pass 1 is "already
  date-bounded server-side" was simply wrong — verified directly against the AL source this time,
  not assumed).
- **Live re-verification after the fix (fresh page load, same Job 10000/Task 1080)**: box now reads
  **"Requested: 0 hours | Assigned: 0 hours"** for this specific test case — correct, since every
  one of the 24 in-window lines has 0 requested/assigned hours, and the only real 24h sits outside
  the window. Manually recomputed both the all-time sum (24, matching ground truth) and the
  in-window-only sum (0) directly from live `db.dayPlanningLines` to confirm the split; also
  confirmed 13 lines fall outside the window (including the 3 real 8h ones) vs. 24 inside. Screenshot
  confirmed the box renders as a bordered blue-outlined pill next to the title text, and every visible
  Section 2 bar independently corroborates 0h for every visible day - fully self-consistent now.
  Console errors: same baseline pattern as the rest of this session, zero new errors.

**SECOND CORRECTION, same day — the `dplDayIndex`/date-window fix above was ALSO wrong, and "0/0 is
correct" was a wrong conclusion.** The coordinator pushed back again with a fresh screenshot
(window 15 Sep–05 Oct): the box read "0/0" while Section 2 visibly rendered many chips for this
exact Job Task across 16/17/18/21/22/25/28/29/30 Sep — clearly INSIDE the window. The coordinator
read `renderWorkOrder()` directly (not asked of me first this time) and found the actual root
cause: **Section 2's chips are NOT built from `db.dayPlanningLines[]`'s literal `Plan Date` at all.**
They come from `db.workOrderSequences[].workdays[]`, mapped through
`getOccurrenceDayIndex(seq, wd)` — which repositions every occurrence RELATIVE TO THE CURRENTLY
VISIBLE WINDOW'S OWN START (`this.dates[0]`), independent of whatever real calendar date is stored
in BC — using `seq.hoursByWorkday[wd]` for the hours (defaulting to 8 if AL sent none). This is a
genuinely SEPARATE data path from `dayPlanningLines[]` — a client-side "reschedule preview"
simulation (matches this file's own drag/moveWorkOrderToDay design: no AL round-trip until
Confirm), not a read of the literal stored Plan Date. **Both of my first two fixes filtered
`db.dayPlanningLines[]`** (first with no date check, then with a `dplDayIndex` check) — the WRONG
array either way, since Section 2 never reads that array's dates at all. The ground-truth OData
query (real dates 2026-09-08/09/10, before the window) was checking a fact that was true but
irrelevant to what Section 2 displays.

**Actual fix (this time, matching the user's explicit "must have a common function" requirement,
checked no existing shared helper exists anywhere else in `src\dhx\*` first — none found):**
- `renderWorkOrder()` now stores its own freshly-built `events` array on the instance
  (`this._woEvents = events;`), immediately before handing it to DHTMLX — the literal single source
  of truth for "what Section 2 is showing right now".
- New `computeWorkOrderTotals()`: sums `ev.requestedHours`/`ev.assignedHours` over `this._woEvents`
  — the ONE shared function both Section 2's own rendering and the title box now read from (not two
  parallel re-derivations of "the same" number).
- New `renderTitleAuditBox()`: builds/updates `#cpo-title-audit` from `computeWorkOrderTotals()`.
  Called from the END of `renderWorkOrder()` itself (after `renderCapacityBars`, before
  `bindScrollSync`) — NOT from `applyPlanningData()` anymore — so it re-renders on EVERY reposition
  (drag, Section 3 click-to-relocate/`moveWorkOrderToDay`, and the initial `renderWoScheduler` call
  every full `applyPlanningData()`/`appendOtherWorkOrderData()` pass ends with), matching the box's
  own stated live-audit purpose, not just the initial server payload.
- `applyPlanningData()`'s own title block now ONLY rebuilds the title TEXT span
  (`.cpo-title-text`) — the audit-box-building code was removed from there entirely, since
  `renderWorkOrder()` (called later in the same `applyPlanningData()` pass, via
  `renderWoScheduler`) always re-adds/updates it afterward. `renderTitleAuditBox()` itself is
  idempotent (looks up `#cpo-title-audit` by id and updates it in place if it already exists,
  creates it only if missing) so it works correctly whether the box was just wiped by
  `applyPlanningData()`'s `titleEl.innerHTML = ''` or already exists from a prior
  `renderWorkOrder()`-only call (drag/click-to-relocate).
- Guard for the Dashboard (page 50724): `renderWorkOrder()`'s own pre-existing
  `if (!this.woScheduler) return;` at the top already prevents `renderTitleAuditBox()` from ever
  running there (the Dashboard's `renderWoScheduler` override is a no-op, `this.woScheduler` stays
  `null` forever) — no separate `hasWO` check was needed in the new code.
- Extensive doc comments added to `renderWorkOrder()` itself (a "KNOWN PITFALL" block) and to
  `renderTitleAuditBox()` (documenting BOTH prior wrong fixes in full, not just the final one) —
  explicit ask from the coordinator to flag this prominently since it caused two consecutive wrong
  fixes in one session.

**Lesson for this file specifically, worth remembering (SUPERSEDES the two previous "lessons"
recorded above in this same memory entry — do not trust those, they were written while I still
believed dayPlanningLines[] was the right source):** Section 2's own rendering — and therefore
ANYTHING meant to reconcile against what Section 2 visibly shows, including any FUTURE feature —
must read `this._woEvents` (via `computeWorkOrderTotals()` or directly), never re-derive a
same-looking total from `db.dayPlanningLines[]`/`db.workOrderSequences[]` independently. The two
arrays represent genuinely different concepts (literal stored Plan Date vs. a window-relative
client-side reschedule-preview position) and WILL silently disagree whenever `this.dates[0]`
("today", effectively) differs from whatever real Plan Date is stored on the underlying Day
Planning rows — which is the normal case, not an edge case, for any Work Order whose real schedule
isn't happening to start exactly on today's date.

Note: also attempted to cross-check against Section 2's own per-line bar LABELS as originally
instructed, but the current live UI only shows a single `"<assignedHours>h"` number per bar (not
the `"<assignedHours>/<requestedHours>h"` two-number format referenced in older
instructions/memory) — likely superseded by the 2026-09-11 standard-tooltip unification pass; the
direct raw-data/ground-truth cross-checks above (for the FIRST two, now-superseded fixes) were the
verification relied on at the time.

**Compile/build only for the third (current, correct) fix — NOT published, per explicit
instruction** ("user wants to test the fix manually themselves... don't push this build to the
environment"): `al_compile`/`al_build` both 0 errors/0 warnings. The EARLIER two (now-superseded)
fixes in this same session WERE compiled/built/published (0 errors/0 warnings each time) before this
final correction landed — the currently-published app in `NL_Copy20240710` therefore still has the
SECOND (dplDayIndex-based, "0/0 for this test case") fix live, not the third/correct one, until the
user publishes this session's final code themselves.

---

## Technical documentation updated (same day, 2026-09-15, final item of this session — written TWICE, second pass is the one that matters)

`docs\generate_capacity_planning_overview_doc.py` (the reportlab script generating `docs\Capacity
Planning Overview - Technical Document.pdf`) was updated to fold in this session's real changes,
following the exact precedent the 2026-09-04 session's own update already established in this same
script (revision-note callout on the cover page, inline `(2026-09-15)` tags on changed
subsections/callouts, no rewrite of unrelated content).

**FIRST pass (now superseded — described here only so a reader doesn't wonder if it's still live in
the script; it is NOT, it was overwritten by the second pass below):** wrote &sect;4.1 describing
the `dplDayIndex`-on-`dayPlanningLines[]` "fix" as correct. This was wrong for the same reason the
JS fix it described was wrong (see the title-bar section above) — corrected in the same editing
session before ever being reported as done, so this first pass was never actually shipped/reported
to the user as final.

**SECOND (actual, final) pass — what's really in the script/PDF now:**
- Cover page: document date + revision note, now listing FIVE items (was four) — item (5) added for
  the &sect;13.13 finding below.
- &sect;4.1 "Title-Bar Audit-Totals Box" — REWRITTEN to describe the actual, correct implementation
  (`this._woEvents` / `computeWorkOrderTotals()` / `renderTitleAuditBox()`, called from the end of
  `renderWorkOrder()`), with a callout pointing to &sect;13.13 for the two-wrong-fixes story instead
  of narrating a specific (and by-then-also-wrong) fix inline.
- &sect;5 (Section 1's algorithm, evaluateWO/currentPositionShortage &rarr; excludingWOFlow) —
  unchanged from the first pass, unaffected by the title-box correction.
- &sect;6 (Section 2) — a NEW callout added, cross-referencing &sect;13.13, right after the
  existing 2026-09-03 bug-fix callout — flagging that this section's own events array (and nothing
  else) is authoritative for "what Section 2 shows".
- &sect;7 (Section 3 exclude-flip + drill-down fix) — unchanged from the first pass.
- &sect;11 (scoping table) / &sect;12.4 (pagination cross-reference) — unchanged from the first
  pass.
- &sect;13.12 (background-load-timing gotcha) — unchanged from the first pass.
- NEW &sect;13.13 pitfall: "Section 2's chips are NOT a render of dayPlanningLines[]'s stored Plan
  Date — two consecutive wrong fixes came from assuming they were" — the PROMINENT entry explicitly
  requested by the coordinator, documenting both wrong fixes IN FULL (not just the final correct
  one) plus the generalizable lesson, so a third person (or agent) hitting this exact confusion has
  the full history in one place, not just the answer.
- Section_13's own intro paragraph, TOC (no new entry needed — 13.13 is a pitfall sub-entry, not
  independently TOC-listed), page-footer date, Appendix description — all consistent with 13.12 AND
  13.13 now existing.

Ran `python generate_capacity_planning_overview_doc.py` from the `docs` folder after BOTH passes —
both regenerated cleanly, no errors, "Wrote ...Capacity Planning Overview - Technical Document.pdf"
printed each time. **Only the output of the SECOND run is meaningful** — the first run's PDF was
immediately superseded by the second before this task was reported complete.

**Not published, per explicit instruction this same turn** ("do NOT run al_publish... do NOT do any
Playwright/browser live-verification for this fix... Stop once al_compile/al_build succeeds
clean"). `al_compile`/`al_build` both ran clean (0 errors/0 warnings) for the THIRD (final, correct)
JS fix described in the title-bar section above, but that build was never published — the
currently-published app in `NL_Copy20240710` still has the SECOND (also-wrong,
`dplDayIndex`-based) fix live. The user will publish and test this final version themselves.

---

## FOURTH AND FINAL ATTEMPT (2026-09-15, later same day, separate session) - THIS IS THE ONE THAT IS
## ACTUALLY LIVE AND CONFIRMED CORRECT. Supersedes ALL THREE prior title-box designs above
## (dayPlanningLines[]-no-date-filter, dayPlanningLines[]+dplDayIndex, and the
## `_woEvents`/`computeWorkOrderTotals()`/`renderTitleAuditBox()` design) - none of those three are
## live anymore, none should ever be reintroduced.

After three straight client-side-derivation failures (all three tried to compute the box's numbers
from some flavor of client-side JS state - `db.dayPlanningLines[]` with/without a date check, then
`db.workOrderSequences[]`/`this._woEvents`), the user gave a final, explicit, much simpler design
instead of another JS-side fix: **"create a dedicated function, to get Requested and assigned
hours, params are 4: Job No., Job Task No., start date, and end date... push the value to JS... and
show it."** A plain server-side sum, no simulation, no client-side array at all.

**Two AL implementation sub-attempts within this same pass - only the SECOND is live; do not
reintroduce the first:**
1. First cut: a brand-new procedure `CPO_GetTaskRequestedAssignedHours(JobNo: Code[20]; JobTaskNo:
   Code[20]; StartDate: Date; EndDate: Date; var RequestedHours: Decimal; var AssignedHours:
   Decimal)` - a plain `SetRange`/`SetLoadFields`/`FindSet`/`repeat`/`until` accumulation loop over
   `Record "Day Planning"`. Compiled, built, published, and live-verified (0/0 for the test case
   below) - genuinely worked - but was superseded minutes later in the SAME session before being
   reported to the user as final, per a design-refinement request: **REMOVED entirely, do not
   recreate it.**
2. **Actual final AL implementation**, same session, same `CPO_BuildPlanningDataJson_Paged`
   call site: reuses TWO FlowFields that ALREADY EXISTED on this project's own `tableext_50605_
   JobTask.al` ("Job Task ext", tableextension 50605) BEFORE this task ever started -
   `"Total Requested Hours"` (field 50691) and `"Total Assigned Hours"` (field 50690), both
   `CalcFormula = sum("Day Planning"."Requested/Assigned Hours" where("Job No." = field("Job No."),
   "Job Task No." = field("Job Task No."), "Plan Date" = field("Planning Date Filter")))` -
   `"Planning Date Filter"` itself is a STANDARD BASE-APP FlowFilter field on `Job Task`
   (`Microsoft.Projects.Project.Job` namespace, confirmed via `al_symbolsearch`), not something this
   project added. **Always search for existing FlowFields/FlowFilters on the relevant table before
   writing a manual loop** - a five-minute `al_symbolsearch` on `objectName: "Job Task"` would have
   found this before the first (FindSet) sub-attempt was ever written. Implementation: inside
   `CPO_BuildPlanningDataJson_Paged`, guarded by the same `JobTaskFound` boolean that already gates
   the rest of the Job-Task-scoped block (`JobTask` is already `Get()`'d earlier in that same
   procedure) - `JobTask.SetRange("Planning Date Filter", StartDate, EndDate)` then
   `JobTask.CalcFields("Total Requested Hours", "Total Assigned Hours")`, using the SAME
   `StartDate`/`EndDate` locals the rest of the payload already computes (`StartDate := Today()`,
   `EndDate := StartDate + NumberOfDays - 1`) - no separate date-window logic, no risk of the box
   disagreeing with the payload's own window. Results added as two new JSON fields on the existing
   `workOrder` object: `requestedHoursTotal`/`assignedHoursTotal` (field NAMES unchanged from the
   first sub-attempt, so the JS side needed no further change once already pointed at these names).
   (The non-paged `CPO_BuildPlanningDataJson` sibling procedure, confirmed dead/never called from
   anywhere in `src` - only `CPO_BuildPlanningDataJson_Paged` is wired to page 50722 - was
   deliberately NOT touched, out of scope, in either sub-attempt.)

**JS side (`capacityPlanningOverview.js`):** the ENTIRE third-attempt machinery was deleted per
explicit instruction - `this._woEvents` (constructor init and the assignment inside
`renderWorkOrder()`), `computeWorkOrderTotals()`, and `renderTitleAuditBox()` are all GONE, along
with `renderWorkOrder()`'s own call to `renderTitleAuditBox()` at its end. The title box is now
built entirely inside `applyPlanningData()`'s existing title-block (`#cpo-title` rebuild), reading
`this.db.workOrder.requestedHoursTotal`/`assignedHoursTotal` DIRECTLY - two lines, no derivation, no
dependency on Section 2's own event array. `renderWorkOrder()`'s own "KNOWN PITFALL" doc comment
(about `events`/`db.workOrderSequences[]` being a window-relative reschedule-preview, not the
literal stored Plan Date) was kept - it's still true and still relevant for anything else that might
want to reconcile against Section 2 in the future - but its old cross-reference to
`renderTitleAuditBox` was corrected to explain the title box no longer reads that array at all.

**DELIBERATE, ACCEPTED TRADEOFF** (documented inline in both the AL doc comment and the JS
`applyPlanningData()` doc comment): since the box's numbers now only arrive with a fresh AL payload,
they will NOT live-update during an uncommitted Section 2/3 drag before the user presses Confirm -
the box always reflects what is actually saved in Day Planning right now. This was an explicit,
knowing simplification, not an oversight.

**Live verification of sub-attempt 1 (FindSet loop, since superseded but genuinely worked - not
re-verified again standalone after the switch, since sub-attempt 2 is a straight substitution of
data source with the identical StartDate/EndDate/JobNo/JobTaskNo inputs and identical JSON field
names, so its correctness transfers) - fresh page navigation, NOT a cached view - via Job Task Card
page 50618's own "Capacity Planning Overview" ribbon action, Job 10000/Task 1080 "Snag List
Resolution", CRONUS NL, window 2026-09-15..2026-10-14/"Days to show"=30):**
- Screenshot confirms the title box rendered on screen reads **"Requested: 0 hours | Assigned: 0
  hours"** next to "Workorder 10000 / 1080 | Snag List Resolution".
- Independently cross-checked (NOT via the MCP BC connector, which was still connecting/unavailable
  this session - verified directly against the live BC session itself instead, per the task's own
  fallback instruction): navigated to page 50630 "Day Plannings" filtered to Job No. 10000/Job Task
  No. 1080, then read the real rendered grid DOM programmatically (recursive iframe search + ARIA
  grid row/cell extraction, matching column headers to cell indices) rather than trusting any cached
  reasoning. Found 36 real Day Planning lines for this Job/Task; summing "Requested Hours"/"Assigned
  Hours" for exactly the rows whose "Plan Date" falls in [2026-09-15, 2026-10-14] gives **0/0** -
  bit-for-bit matching the live title box. The only 3 non-zero lines in the whole table (8h
  Requested each, 2026-09-08/09/10, ELEKTR) are confirmed to sit BEFORE the window and were
  correctly excluded by both the AL query and this independent grid read. **0/0 for this specific
  test case is therefore a correct, verified answer, not a bug** - a real non-zero example would
  need a Job Task whose real Day Planning dates fall inside whatever "today"-relative window is
  being viewed (this demo data's few non-zero lines all happen to be dated slightly before "today").
- Console: only the pre-existing baseline pattern (6x `api.businesscentral.dynamics.com/.../Company`
  401s for other companies in the switcher - HQ_AT/UK_HQ/HQ_DE/HQ_FR/HQ_IT/HQ_DK - plus 1x
  `graph.microsoft.com` profile-photo 404) - zero errors attributable to this add-in's own code.

**Live re-verification of sub-attempt 2 (FlowField-based - the one actually live now):** after
recompiling/rebuilding/republishing with the FlowField-based `CPO_BuildPlanningDataJson_Paged`
change (the `CPO_GetTaskRequestedAssignedHours` procedure deleted entirely), repeated the exact same
navigation (fresh Job Task Card page 50618 -> "Capacity Planning Overview" ribbon action -> new
bookmark on page 50722, Job 10000/Task 1080, CRONUS NL) and screenshotted again: title box again
reads **"Requested: 0 hours | Assigned: 0 hours"** - identical output to sub-attempt 1, as expected
(same underlying table, same filter semantics, same window). Console again showed only the same
baseline noise plus a handful of CORS-blocked Office telemetry beacons (`*.fp.measure.office.com`,
`tr-ooc-*.office.com` `trans.gif`/`r.gif`) already flagged elsewhere in this memory file as a
session/network artifact unrelated to this add-in's own code - no new errors from either AL or JS.

---

## SIXTH AND TRULY FINAL ITEM (2026-09-15, later same day, separate session again) - dedicated unit
## test coverage added (codeunit 60030) to settle the "is 0/0 a bug or correct data" question at the
## FlowField-mechanism level, independent of any one live Job/Task's own data shape.

**Context:** a temporary diagnostic `alert()` had been added to `wrapper.js`'s `SetPlanningData`
(logging the raw `requestedHoursTotal`/`assignedHoursTotal` AL sent, before any JS touched them) to
prove whether a live 0/0 for Job 10000/Task 1080 was an AL-side or JS-side issue. It proved AL-side
(the raw payload itself was 0/0) - but every live check up to that point happened to use the SAME
test case (10000/1080), whose only real demand (3 lines, 8h each, 2026-09-08/09/10) sits BEFORE any
"today"-anchored 30-day window, so 0/0 was ambiguous: correct-for-this-task, or a genuine
FlowField/FlowFilter bug nobody had isolated from that one data shape.

**New test codeunit**: `test\CPOTitleBoxFlowField.Test.Codeunit.al`, **codeunit 60030 "CPO Title Box
FlowField Tests"** (next free ID after 60020-60029, all taken). Uses its OWN dedicated Job/Job Task
(`CPOTB-JOB`/`1000`) - deliberately NOT the shared `DPCT-JOB` test fixture `test\
DayPlanningCreation.Test.Codeunit.al` owns. Follows this project's REAL, verified test-assertion
convention: **no `Library Assert` codeunit** - `app.json` has `"dependencies": []`, so that codeunit
isn't even available; grepping `test\*.al` confirms every test file in this suite (including the one
in this same file's own earlier sections' assumptions) uses a local
`AssertAreEqual(Expected: Variant; Actual: Variant; ErrMsg: Text)` / `Format()`-comparison helper
instead - this codeunit does the same. (The earlier `dailyoptimizer-test-framework-setup` memory's
claim that Library Assert/Variable Storage/Any were wired up 2026-06-16 is STALE/was reverted at
some point - don't trust it for future test codeunits; always grep `test\*.al` + `app.json`
`dependencies` first.)

**Data design** (5 `Day Planning` lines inserted via plain `Init()`/direct-field-assignment/`Insert()`
- no `Validate()` calls at all, so neither "Plan Date"'s `EnsureJobTaskCoversDate` nor "Assigned
Hours"'s `AssignedCheck` nor the table's own `OnInsert` (which would `Get()` the "Daily Optimizer
Setup" singleton when Skill is blank - an unrelated dependency avoided entirely by never firing the
trigger) can interfere - straddling an arbitrary 10-day window `[GetWindowStart(), GetWindowEnd()]`
(`Today()+14`..`Today()+23`, stable within one run) on both edges:
- day-before (`WindowStart-1`): Requested 5 / Assigned 3 - must be EXCLUDED
- start boundary (`WindowStart` exactly): Requested 10 / Assigned 6 - must be INCLUDED
- middle (`WindowStart+5`): Requested 7 / Assigned 4 - must be INCLUDED
- end boundary (`WindowEnd` exactly): Requested 8 / Assigned 2 - must be INCLUDED
- day-after (`WindowEnd+1`): Requested 9 / Assigned 1 - must be EXCLUDED

Four `[Test]` methods against `JobTask.SetRange("Planning Date Filter", ...)` +
`JobTask.CalcFields("Total Requested Hours", "Total Assigned Hours")` (the exact same two calls
`CPO_BuildPlanningDataJson_Paged`/page 50618 use):
1. Full 10-day window -> expects exactly **25 Requested / 12 Assigned** (boundary+middle+boundary
   only; if either out-of-window line were wrongly included, this would read 39/22 instead - failure
   here would be unambiguous proof of a real FlowFormula bug).
2. A window 1000+ days away, containing none of the 5 lines -> expects exactly **0/0** (the
   legitimately-zero case, isolated from any specific live Job/Task's own data shape).
3. Window collapsed to a single day exactly on the START boundary -> expects exactly **10/6** (proves
   `SetRange` is inclusive on the start edge, isolated from the day-before line).
4. Window collapsed to a single day exactly on the END boundary -> expects exactly **8/2** (same,
   isolated from the day-after line).

**Compile/build:** `al_compile`/`al_build` both 0 errors, 0 warnings, clean, both before AND after
also reverting the `wrapper.js` diagnostic (see below) -
`Optimizers_DailyOptimizer_28.0.0.12.app`.

**COULD NOT be executed live this session - a genuine, unresolved tool/instruction conflict, not a
tool bug:** `al_run_tests` against codeunit 60030 (env `NL_Copy20240710`, tenant
`a60762e1-df10-4e4b-8f44-174c51589110`) returned `"0 passed, 0 failed, 1 skipped"` / `SKIP (0ms)`
TWICE in a row (second attempt with `noCache=true`) - the exact same signature the
`dailyoptimizer-test-framework-setup` memory already documents as meaning either (a) the test object
genuinely doesn't exist on the server yet (no publish has ever put codeunit 60030 there - it's
brand-new this session), or (b) genuine tool flakiness that has, in the past, only gone away once a
real `al_publish` had actually landed first. Since this session operated under an explicit "do NOT
call al_publish" instruction (cost-sensitive session), root cause (a) could not be ruled out or fixed
without violating that instruction, and no attempt was made to force it. **Practical consequence for
ANY future session writing a brand-new `[Test]` codeunit under a "don't publish" constraint:
`al_run_tests` should be expected to return this exact skip signature until SOMEONE actually
publishes the app at least once** - don't burn time retrying `al_run_tests` itself when this happens
on a never-yet-published object; the fix is a publish (by the user, or by an agent explicitly
authorized to do so that session), not a different `al_run_tests` parameter combination.

**Conclusion on the original "is 0/0 a bug" question - reached WITHOUT this session's own new tests
actually executing, via a combination of (i) the prior sessions' own extensive live ground-truth work
already recorded above in this same file (FOURTH/FIFTH ATTEMPT sections - two independent live
cross-checks, OData query AND live grid DOM read, both already concluded 0/0 is correct for
10000/1080) and (ii) a fresh live OData spot-check this session (see below) showing the FlowFilter
window mechanism behaves exactly as SetRange-inclusive semantics predict for a DIFFERENT real
Job/Task:** **(b) the FlowField logic is correct; 0/0 for Job 10000/Task 1080 was, and remains,
genuinely correct data for that task, not a bug.** This session's new codeunit 60030 is additional,
not yet independently fired, confirmatory scaffolding for that same conclusion at the pure-mechanism
level (synthetic data, no live-task dependency) - a future session with publish permission should run
it once to close the loop, but the conclusion itself does not depend on that run happening.

**Live OData spot-check this session (`mcp__ah_bc_mcp__List_DayPlannings_PAG50606`, NOT
`_PAG50675` - that page's `workedHours` field is still NOT `"Assigned Hours"`, same documented trap
as before) - found an ALTERNATE real Job/Task with genuine non-zero demand inside the
2026-09-15..2026-10-14 window, as the task asked for:**
- **Job No. `10000`, Job Task No. `2030`, description "Phase Handover Documentation A"**
  (plannedStartDate 2026-09-07, plannedEndDate 2026-11-09 - the window sits fully inside this task's
  own planned range). 26 real Day Planning lines in-window (`Leader:`/`Member:` pairs on several
  dates, 2026-09-16 through 2026-10-14), ALL with `requestedHours > 0`, summing to **174 requested
  hours**; ALL 26 have `assignedHours = 0`. Predicted title-box reading for this task at this window:
  **"Requested: 174 hours | Assigned: 0 hours"** - not independently confirmed against the live
  rendered box this session (no Playwright, per the same hard constraint), but directly computed from
  the live underlying table data the FlowFields sum over.
- **Important company-wide finding, not just about this one candidate:** a filtered query for
  ANY `assignedHours gt 0` row anywhere in the company with `taskDate` in
  `[2026-09-15, 2026-10-14]` returned **zero results** (0 of the table's 604 total `assignedHours>0`
  rows fall in that window - the most recent one company-wide is dated 2026-08-25, i.e. also before
  "today"). **So "Assigned: 0 hours" will be true for essentially any Job/Task tested in this
  specific live window right now, company-wide** - this is a seeded-demo-data ceiling (assigned/
  actual-work data simply wasn't generated past late August in this environment), not a per-task or
  per-add-in quirk, and not something any AL fix could change. A future live spot-check wanting a
  non-zero ASSIGNED number in the box would need either a window reaching back before 2026-08-25, or
  freshly-created/assigned Day Planning data.

**wrapper.js diagnostic removed, same session:** `SetPlanningData` in
`src\dhx\capacity_planning_overview\wrapper.js` reverted to the plain
`window.__cpo.applyPlanningData(JSON.parse(PlanningDataJsonTxt));` one-liner - the `alert()` and its
explanatory comment are gone. Its job (proving AL, not JS, was the source of a live 0/0) is done and
was already reflected in the FIFTH-ATTEMPT conclusion above before this diagnostic was even added.

**Not published, per explicit hard instruction this session** ("do NOT call al_publish... Stop once
al_compile/al_build succeed clean"). Both `al_compile` and `al_build` (`onlyErrors=true`) succeeded
with 0 errors both before and after the `wrapper.js` revert. **Net effect: the currently-published
app in `NL_Copy20240710` still only has the FIFTH-DESIGN title-box code (see above) - it does NOT yet
have codeunit 60030 or the `wrapper.js` diagnostic-removal.** Both are complete and clean on disk,
ready for the user's own publish.

**Also fixed as an unrelated prerequisite, same session:** `al_compile`/`al_build` initially failed
with a wall of `AL0197`/`AL0264`/`AL0275`/`AL0155`/`AL0887` "already declared"/"ambiguous reference"
errors, all pointing at pairs of identical paths - one under the real `src\...` tree, one under
`.claude\worktrees\agent-a513b4329cdfddabc\src\...`. Root cause: a PREVIOUS Opus-powered attempt at
this exact task had been launched with `isolation: "worktree"`, hit an API rate limit and died
almost immediately, and never got to clean up its own worktree - it was left behind, locked, still
physically present on disk under the live project folder, so the AL compiler was seeing every object
in the project TWICE. Confirmed the stray worktree had zero uncommitted changes (`git status` -
"nothing to commit, working tree clean") before removing it - `git worktree remove --force` failed
with "Permission denied" (a held file handle), so `git worktree list` unregistered it first and a
PowerShell `Remove-Item -Recurse -Force` deleted the actual directory; `git worktree prune` still
reports a harmless leftover `.git/worktrees/agent-a513b4329cdfddabc` metadata-folder permission
error afterward but `git worktree list` no longer shows it and compilation is clean - not expected
to recur unless another agent run with `isolation: "worktree"` crashes before cleanup again.

**Compile:** 0 errors (both sub-attempts). **Build:** succeeded, 0 warnings, both times,
`Optimizers_DailyOptimizer_28.0.0.12.app`. **Published** to `NL_Copy20240710` twice in this session
(`al_publish` with `projectPath`+`skipBuild=true` - matches this project's known-working publish
invocation; a bare `appPath`-only call failed with a generic `PublishFailed`, and a `projectPath`
call without `skipBuild=true` failed with `ProjectPath is required` - both dead ends, this
combination is the one that works) - once for sub-attempt 1 (FindSet), then again minutes later for
sub-attempt 2 (FlowField) after that design refinement landed. **The FlowField-based sub-attempt 2
is what's currently live in `NL_Copy20240710`** - unlike the third (`_woEvents`) attempt above,
which was left for the user to publish themselves, this whole fourth attempt (both sub-attempts) was
published and live-verified end-to-end in the same session, with the final published state matching
the final code on disk.

---

## FIFTH AND FINAL DESIGN (2026-09-15, later same day, separate session) - SUPERSEDES the 4th
## attempt directly above for WHEN the title-box numbers are computed (not for WHAT computes them -
## the same tableext 50605 FlowFields are reused unchanged). Past this point, ignore the 4th
## attempt's "recomputed on every call/refresh" behavior description - it no longer applies.

**Explicit user design choice, not a bug report:** the 4th design's numbers were a LIVE PER-REFRESH
recompute - `CPO_BuildPlanningDataJson_Paged` ran `JobTask.SetRange("Planning Date Filter",
StartDate, EndDate)`/`CalcFields` itself, against whatever StartDate/EndDate RefreshData currently
had, so the box changed every time the user changed "Days to show" or hit Reset Position inside page
50722. The user asked for this to become a FIXED SNAPSHOT instead: computed ONCE by the CALLER (page
50618 "Opti Job Task Card"'s "Capacity Planning Overview" ribbon action) at the moment it opens page
50722, over a hardcoded 30-day-from-`WorkDate()` window (`WorkDate()`..`WorkDate()+29`) - explicit
user rationale: simplicity over live-recompute. After this change, changing "Days to show"/Reset
Position inside page 50722 does NOT touch this box's numbers anymore - only re-opening the page from
the Job Task Card ribbon action recomputes it.

**Implementation (3 files, all reusing the SAME tableext 50605 FlowFields the 4th design already
used - "Total Requested Hours"/"Total Assigned Hours", fields 50691/50690, `CalcFormula` sum over
`Record "Day Planning"` filtered by the Job Task's own "Planning Date Filter" FlowFilter - no new
AL data structures were needed, only where the CalcFields call happens moved):**

1. **`src\page\page_50618_JobTaskCard_Project.al`**, `CapacityPlanningOverviewAct`'s `OnAction`
   (~line 863): now declares `RequestedHours`/`AssignedHours: Decimal` locals, does
   `Rec.SetRange("Planning Date Filter", WorkDate(), WorkDate() + 29)` +
   `Rec.CalcFields("Total Requested Hours", "Total Assigned Hours")` BEFORE calling
   `CPO.SetJobTask(...)`, then passes both values as two new trailing args. **Found this trigger
   ALREADY partially edited when this session started** (calling `SetJobTask` with 4 args using
   misspelled undeclared locals `RequestedHOurs`/`AssignedHOurs` - a leftover from an earlier,
   apparently-interrupted attempt at this exact same task, never previously reported as done) - fixed
   the typo and added the missing var declarations/computation rather than starting over.

2. **`src\dhx\capacity_planning_overview\page_50722_CapacityPlanningOverview.al`**: `SetJobTask`'s
   signature extended to `SetJobTask(pJobNo: Code[20]; pJobTaskNo: Code[20]; pRequestedHours:
   Decimal; pAssignedHours: Decimal)`, storing into two NEW globals `GRequestedHoursTotal`/
   `GAssignedHoursTotal` (declared next to `GJobNo`/`GJobTaskNo`, ~line 180). **Also found this
   page's `SetJobTask` ALREADY partially edited when this session started** - the 4-arg signature
   and body already existed, but assigning into UNDECLARED globals literally named `RequestedHours`/
   `AssignedHours` (would not have compiled) - renamed to the `G`-prefixed convention this page
   already uses for its other cross-call state (`GJobNo`/`GJobTaskNo`) and added the missing
   declarations. `RefreshData` (~line 260) now forwards `GRequestedHoursTotal`/`GAssignedHoursTotal`
   as two new trailing args on every `CPO_BuildPlanningDataJson_Paged` call - unchanged on every
   subsequent refresh, which is what makes the box stay fixed. Doc comments on both the new globals
   and `SetJobTask` explain the fixed-snapshot design explicitly. Confirmed via grep: page 50618 is
   the ONLY live caller of `SetJobTask` on this page, and this page's own `RefreshData` is the ONLY
   caller of `CPO_BuildPlanningDataJson_Paged` anywhere in `src` - no other call sites needed
   updating.

3. **`src\codeunit\codeunit_50604_DHXDataHandler.al`**, `CPO_BuildPlanningDataJson_Paged`: signature
   gained two new IN params `RequestedHoursTotal: Decimal; AssignedHoursTotal: Decimal`. The 4th
   design's internal `JobTask.SetRange("Planning Date Filter", StartDate, EndDate)`/`CalcFields`
   block and its `TitleBoxRequestedHours`/`TitleBoxAssignedHours` locals were REMOVED entirely - the
   procedure no longer computes these numbers itself at all, it just writes the two new params
   straight into the JSON under the SAME existing keys (`workOrder.requestedHoursTotal`/
   `assignedHoursTotal` - unchanged, confirmed by grep before editing). Doc comments (both the
   procedure's own header and the inline block at the JSON-write site) rewritten to describe the 5th
   design and explicitly reference the 4th design's now-dead behavior so a future reader doesn't
   trust the old "recomputed on every call" wording anywhere in this file.

4. **`src\dhx\capacity_planning_overview\capacityPlanningOverview.js`**: confirmed (not assumed) the
   JS still reads `this.db.workOrder.requestedHoursTotal`/`assignedHoursTotal` directly, unchanged -
   no JS logic edit needed. Only the surrounding doc comment (`applyPlanningData()`, ~line 528) was
   rewritten to describe the 5th design (fixed snapshot from the Job Task Card, not a per-refresh AL
   recompute) instead of the now-stale 4th-design wording.

5. **Page 50724 (Capacity Planning Dashboard)**: confirmed via grep - calls neither `SetJobTask` nor
   `CPO_BuildPlanningDataJson_Paged` anywhere in `src\dhx\capacity_planning_dashboard\` - nothing to
   change there, consistent with prior memory that this box's JS-side `<span>` is never created on
   that tile (`this.db.workOrder` always falsy there).

**Compile:** 0 errors (`al_compile onlyErrors=true` - only pre-existing, unrelated AL0640/AL0269/
AL0659/AL0667 warnings elsewhere in the codebase, none touched by this change). **Build:** succeeded,
0 warnings, `Optimizers_DailyOptimizer_28.0.0.12.app`. **Published** to `NL_Copy20240710`
(`al_publish` `projectPath`+`skipBuild=true` - this project's known-working combination) - the
publish call had already completed successfully before a coordinator cost-control message arrived
mid-task instructing "stop after compile/build, do NOT publish, do NOT live-verify - user is at 24%
token burn on this feature and wants to test manually themselves." **Net result: this fix WAS
published to `NL_Copy20240710` (not something a future session needs to re-publish), but was NOT
live-verified this session** - no Playwright pass, no test-case-A/test-case-B numeric verification,
no confirmation of the "fixed across Days-to-show change" behavior. A future session (or the user
manually) should still do that live verification before fully trusting this design end-to-end - the
compile/build-level correctness is solid (signatures match, only call sites updated, JSON keys
unchanged) but the actual FlowFilter/FlowField arithmetic and the "box stays fixed" UI behavior have
only been reasoned about, not watched live, for this specific 5th design.
