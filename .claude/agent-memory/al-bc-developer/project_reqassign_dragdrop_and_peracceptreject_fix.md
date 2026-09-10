---
name: project_reqassign_dragdrop_and_peraccept_reject_fix
description: Request/Assignment Planner (page 50710) — 2026-09-10 fix for drag-and-drop from Request panel to Assignment panel not working; per-row Accept/Reject in the Assignment panel was already implemented but never visible because of the same bug; FOLLOW-UP same day fixed the per-row Accept/Reject buttons visually bleeding into the NEXT resource row (dy/CSS row-height mismatch). Read alongside [[project_request_assignment_planner]] before touching this add-in again.
metadata:
  type: project
---

**Context:** user reported live (screenshot of page 50710) that dragging a Request-panel bar down
onto a resource row in the Assignment panel did not create/update an assignment, and asked for
per-row Accept/Reject actions in the Assignment panel (not just the existing toolbar Accept
All/Reject All). Per task instructions, verified the whole extension compiles/publishes cleanly
FIRST (it does - `al_build` succeeded, 0 errors) before touching any JS. `al_compile`/
`al_getdiagnostics` (not `al_build`) reported several phantom errors in this session
(`page_50618_JobTaskCard_Project.al` citing "Project No."/"Project Task No." fields that do not
exist anywhere in that file's real disk content, `table_50608_OrderIntakeLine.al` citing a
"Text001" that doesn't exist anywhere in that file either) - textbook match for
[[al_compile_stale_cache_quirk]]'s "diagnostics cite content/line numbers that don't exist on
disk" signature; `al_build` is what actually mattered and it was clean both before and after this
session's edits. Confirmed the Work Order table removal was NOT the cause of either reported bug -
both bugs were pre-existing JS logic defects in `src/dhx/request_assignment/wrapper.js`, unrelated
to the AL-side migration.

## Bug 1a: whole-sequence drag (the "N time slots moving" tooltip drag via the ☰ handle)

**Root cause:** the `.seq-drag` pointerdown handler (drag START, wrapper.js ~line 6123) calls
`activateSkillFilter(sequenceKey, { render: false })` to scope resource-drop-target highlighting to
the sequence's required skill. `render: false` skips `renderResources()`, so the ACTUAL resource
row DOM (still the full unfiltered resource list) falls out of sync with `visibleResources()`
(which immediately starts returning the skill-filtered list, since `activeSkillFilter` is a
synchronous variable write, not gated on rendering). `resourceFromPointer()` - called on every
pointermove/pointerup for the rest of the drag gesture - maps a screen Y coordinate to a resource
by POSITIONAL INDEX into `visibleResources()`, cross-referenced against the DOM row rects from
`getResourceRowElements()`. With the two arrays desynced (different length/order), the index
lookup resolves to the wrong resource or (far more often, since the filtered array is usually much
shorter than the real row count) silently falls out of bounds and returns `null` - so essentially
every whole-sequence drop failed with `dragStatus` = "Drop on a resource row, not on the header.",
even when dropped squarely on a valid, skill-matching resource row. Confirmed by instrumenting
`Microsoft.Dynamics.NAV.InvokeExtensibilityMethod` and a document-level pointerdown/pointerup
listener live in the browser: pointerdown/pointerup both reliably fired and reached the right
target elements, but `resourceFromPointer` never returned a usable id.

The individual (single Day Task Line, non-☰) drag path a few hundred lines below already calls
`activateSkillFilter(draggedLine.sequenceKey, { render: true })` at the equivalent point - i.e. this
was an asymmetry/inconsistency between the two drag paths, not an intentional design choice (no
comment or reason for `render:false` here; the live flyers it's called near are absolutely-
positioned clones in the REQUEST panel, not the resource panel, so a `renderResources()` call at
that point can't disturb them).

**Fix:** `src/dhx/request_assignment/wrapper.js`, the `.seq-drag` pointerdown handler - changed
`activateSkillFilter(sequenceKey, { render: false })` to `{ render: true }` (matches the individual-
drag path). A code comment was added at the call site explaining why `render:true` is load-bearing
here, specifically to stop a future edit from "optimizing" it back to `false`.

## Bug 1b: individual single-line drag (dragging one bar directly, not via ☰)

Found as a SEPARATE bug while isolating bug 1a (this path was ALSO 100% broken, independently of
the render:false issue above - discovered because even after fixing 1a, individual-line drags kept
silently failing until this was also fixed).

**Root cause:** `lineIdFromRequestElement(element)` recovers a Day Task Line's real id from the
DOM by reading the bar element's `dtl-...` CSS class name and stripping the `dtl-` prefix. But that
class name is built by `sch.templates.event_class` as
`` `dtl-${String(event.dayTaskLineId).replace(/[^a-zA-Z0-9_-]/g, "_")}` `` - i.e. it SANITIZES the
real id (which is pipe-separated, `"<Job No.>|<Job Task No.>|<Day Line No.>"` - see
[[project_request_assignment_planner]]) by replacing every "|" with "_", because "|" isn't legal in
a CSS class name. `lineIdFromRequestElement` never reversed that sanitization - it just used the
sanitized (underscore) string AS the id and passed it straight to `findLine(id)`
(`dayTaskLines.find(x => x.id === id)`), which does an exact string match against the REAL
(pipe-separated) `line.id`. `"10000_1080_20000" !== "10000|1080|20000"` always, so `findLine`
ALWAYS returned `undefined`, and the request-bar pointerdown handler's `if (!line) return;` guard
silently aborted the drag before `slotPointer` was ever set - no console error, no status text
change, nothing. This made individual-line dragging appear to do literally nothing at all, for
every single line, unconditionally - a pre-existing bug (not this session's regression), likely
never noticed before because whole-sequence dragging (the ☰ handle) is the primary/demoed workflow.

**Fix:** rewrote `lineIdFromRequestElement` to re-derive the SAME sanitized class name from each
candidate `dayTaskLines[]` entry's real id (the exact inverse operation of how `event_class` built
it) and match on that, instead of trying to un-sanitize the class name itself (which is lossy and
can't be reliably inverted in general).

## Bug 2 ("missing" per-row Accept/Reject) - NOT actually missing, just unreachable

`acceptForResource(resourceId)`/`rejectForResource(resourceId)` (scoped to all of one resource's
currently-pending/provisional sequence assignments - see
[[project_request_assignment_planner]]'s note on `ReqAssign_AcceptSequence` being the only
whole-sequence persistence point) already existed, fully implemented, along with a resource-column
row template (wrapper.js ~line 3038-3087, comment "Stable V1: provisional decision controls") that
renders `.resource-accept-btn`/`.resource-reject-btn` buttons next to a resource's name WHENEVER
`pendingSequencesForResource(section.key).length > 0`, plus a click handler already wired
(~line 6398-6416) and real (non-stub) CSS in `style.css`. None of this needed to be built - it just
had zero chance to ever run, because `pendingSequences` could never become non-empty while bug 1a
made every whole-sequence drop fail. Once 1a was fixed, the per-row Accept/Reject buttons appeared
automatically, with no JS/AL changes of their own required.

**Live-verified (2026-09-10, NL_Copy20240710 sandbox, CRONUS NL company):**
- Dragged "DRILLING - Seq 1" (☰ handle, whole sequence, 3 lines) onto Dianne Buchanan (has DRILLING
  skill) → provisional assignment created, resource panel auto-filtered to DRILLING-skilled
  resources, per-row Accept/Reject buttons appeared next to "Dianne Buchanan".
- Clicked the per-row Accept button → `OnAcceptSequence` fired with the correct payload
  (`sequenceKey`, `resourceId: "DRE001"`, 3 lines w/ startHour=7/durationHours=9) → toolbar Accept
  All/Reject All returned to disabled (0 pending) → reloaded the page fresh (full `SetPlanningData`
  round-trip from AL) → "DRILLING - Seq 1" still shows accepted (✓) and Dianne Buchanan's row still
  shows the green "DRILLING · 1060/1" assignment bar on the correct day - confirms the accept
  genuinely persisted server-side via `ReqAssign_AcceptSequence`, not just client-side state.
- Dragged "DESIGN - Seq 2" onto William Pena (has DESIGN skill) → provisional → clicked the per-row
  Reject button → `resultStatus` = "1 provisional sequence rejected on William Pena.", no console
  errors - matches `ReqAssign_RejectSequence`'s documented no-op-on-AL-side/discard-client-state-
  only semantics.
- Dragged a single unassigned ELEKTR Day Task Line bar (not via ☰) onto Dianne Buchanan → fixed
  `lineIdFromRequestElement` correctly resolved the line → `OnAssignDayTaskLine` fired immediately
  (individual-line assignment commits immediately, unlike whole-sequence which stays provisional
  until Accept - matches existing documented design) with the correct pipe-separated id.
- Console error count stayed at the SAME baseline noise across every test (7-9 errors): a 404 on
  the signed-in user's Graph profile photo and ~6 401s from BC probing OTHER companies
  (UK_HQ/HQ_FR/HQ_DK/HQ_AT/HQ_IT/HQ_DE) it doesn't have access to in this tenant - neither related
  to this add-in; zero NEW errors introduced by either fix.

**Files touched:** `src/dhx/request_assignment/wrapper.js` only (two isolated fixes: the
`.seq-drag` pointerdown handler's `activateSkillFilter` call, and `lineIdFromRequestElement`). No
AL changes were needed for either reported issue - `codeunit_50604_DHXDataHandler.al`'s `ReqAssign_`
region was already correct and unaffected by the Work Order removal (matches the task brief's own
pre-check finding).

## Follow-up fix, same day: per-row Accept/Reject bled into the NEXT resource row

After the fix above shipped, the user tested live and sent a screenshot showing the per-row
Accept/Reject buttons rendering on top of/overlapping the WRONG resource's name - specifically the
row directly below the one actually dropped on (their screenshot: dropped on "Jose Witt", but the
buttons visually collided with "Joe Kirby" underneath). This looked like a floating/absolutely-
positioned overlay, but it is not - there is only ONE Accept/Reject implementation in this file (no
separate floating-tooltip variant exists anywhere), and it genuinely IS generated inside the correct
resource's own row template. The bug is a row-geometry mismatch, not a positioning-model mismatch.

**Root cause:** the resource Timeline view (`sch.createTimelineView({ name: "resources", ... })`,
`wrapper.js` ~line 3016) was configured with `dy: 34` (the row-to-row PITCH DHTMLX uses internally
to place each row, i.e. `row[i].top = i * dy`), while `style.css`'s "DHTMLXtempv028 — compact
Resource rows" section (the last/current row-sizing pass, layered on top of two earlier abandoned
attempts "DHTMLXtempv025"/"DHTMLXtempv026" also still present in the file) FORCES
`#resourceScheduler .resource-cell` / `.dhx_matrix_scell` / `.dhx_matrix_line` to
`height: 48px !important`. DHTMLX's own row placement math never reads that CSS - it only ever used
`dy: 34` - so every row's actual rendered BOX (48px, CSS-forced) was 14px taller than the SPACING
between consecutive rows (34px), making every pair of adjacent resource rows overlap by exactly
14px, confirmed live via `getBoundingClientRect()` on consecutive `.resource-cell` elements
(`row[i].bottom - row[i+1].top === 14` for every row, not just the one with visible buttons). Normal
one-line rows (just a name) never visibly showed this, because 14px of overlap at the very bottom of
a short name/icon row rarely collides with visible content in the row below. But the Accept/Reject
button pair sits low enough in its own row's vertical center that the overlap zone becomes visually
obvious once other content exists there - explaining why this was never noticed before per-row
Accept/Reject started actually rendering (see the drag-drop bug above - before that fix, these
buttons never appeared at all).

Also found and fixed for consistency: `resourceFromPointer`'s row-index fallback (used when the
primary DOM-rect-based row lookup misses) hardcoded a THIRD, different, stale row-height constant
(`const rowHeight = 52;`, with an equally stale comment "resource Timeline was configured with
dy = 52" - never true even before this fix, actual config was 34). Left uncorrected it would have
silently reintroduced a drop-target misdetection edge case once the primary 14px-overlap symptom was
fixed elsewhere. Three different numbers (34 / 48 / 52) had drifted out of sync across the file over
several past CSS-only "compact rows" patches that never touched the JS `dy` or this fallback
constant alongside them - a reminder that if `.resource-cell`'s CSS height is ever changed again, `dy`
(scheduler config) and the `resourceFromPointer` fallback `rowHeight` constant MUST be updated to the
exact same value in the same change, or this class of bug (visual row overlap, and/or drop-target
misdetection) reappears.

**Fix:** `src/dhx/request_assignment/wrapper.js` - changed the resource Timeline's `dy: 34` to
`dy: 48` (matches the CSS-forced row height exactly - zero row spacing/box-height mismatch left) and
`resourceFromPointer`'s fallback `rowHeight` from `52` to `48` (now consistent with the same real
value everywhere). Both changes are commented in place explaining the dy/CSS coupling so a future
edit to one side doesn't silently drift from the other again. No CSS changes were needed - the CSS
side (48px) was already the intended/correct value, it was the JS `dy` (and the unrelated JS
fallback constant) that were stale.

**Live-verified (2026-09-10, same sandbox/company, reproduced with the user's own exact scenario -
Request panel filtered to Job 10000 / Task WO-000014, the DRILLING/ELEKTR/MOLDER Seq 1 sequences
visible in their screenshot):** dragged "ELEKTR - Seq 1" (4 lines - matches their screenshot's "4
time slots moving" tooltip exactly) onto "Jose Witt" → per-row Accept/Reject appeared cleanly inside
Jose Witt's own row. Measured via `getBoundingClientRect()`: every consecutive pair of
`.resource-cell` rows now sits exactly flush (`bottom === next.top`, zero overlap, checked across
all 8 visible rows - Dianne Buchanan/Jose Witt/Jeff Yates/Ben Cantrell/Barbara Sharp/Annie
Cervantes/Katie Graves/Bobbie Joyce); the Accept/Reject button pair's rect (568-591) sits fully
inside Jose Witt's own cell rect (555.5-603.5) with clear margin on both sides, nowhere near "Jeff
Yates" (603.5+) or "Dianne Buchanan" (up to 555.5). Clicking Accept still worked exactly as before
(`resultStatus` → "1 provisional sequence accepted on Jose Witt."). Console error count unchanged
from the established unrelated baseline (multi-company 401 probes, profile-photo 404, an
`fp.measure.office.com` telemetry CORS block) - zero new errors from this fix.

**Unrelated pre-existing compile errors, NOT touched (out of scope, confirmed present via a real
`al_build` before AND after this session - same root cause, Work Order table removal, different
feature area):** none blocked `al_build` this session - full workspace compiled clean. (Contrast
with [[project_cpo_work_order_table_removal_migration]]'s note about `page_50655_OrderIntakeCard.al`
and `Pag50639.DayPlanningPattern.al` - those were apparently already fixed by the time this session
ran, since `al_build` came back 0 errors without touching either file.)
