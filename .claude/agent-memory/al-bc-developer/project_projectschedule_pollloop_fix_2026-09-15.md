---
name: project_projectschedule_pollloop_fix_2026-09-15
description: Page 50621 Task Scheduler reduced-functionality banner fixed by porting request_assignment's setInterval->setTimeout poll rewrite; ganttdemo2 still has the old pattern (out of scope)
metadata:
  type: project
---

On 2026-09-15, page 50621 "DHX Scheduler (Project)" (Task Scheduler, controladdin
DHXProjectScheduleAddin, src/dhx/projectschedule) was showing BC's "reduced functionality" banner
again, despite the Part A/Part B pagination architecture from commit 42e7bf3 "DA1-T144 Enhance the
Performance of Task Scheduler".

**Root cause**: `wrapper.js`'s `NotifySectionsTaskPending`/`_sectionsPollTimer` (Part B's
"is the background task result ready" poll) used a raw fixed-cadence `setInterval` that fired every
500ms regardless of whether the previous `OnPollSectionsResult` round trip had returned - the exact
anti-pattern Microsoft's control-add-in guidance flags as a trigger for the reduced-functionality
watchdog. This is the SAME bug already fixed on the sibling page 50710 (src/dhx/request_assignment)
on 2026-09-10ish - that fix's own code comments explicitly name `NotifySectionsTaskPending`/
`_sectionsPollTimer` (this file) as a known not-yet-fixed sibling instance, alongside
`src/dhx/ganttdemo2/wrapper.js`'s `NotifyResourcePanelTaskPending`/`_resourcePanelPollTimer` (still
unfixed, intentionally out of scope every time this has come up).

**Fix**: Ported request_assignment's self-rescheduling `setTimeout` + in-flight-guard + 30s/60-attempt
ceiling pattern into projectschedule/wrapper.js 1:1, renamed to the existing `_sections*`/`Sections*`
naming (not `DayTaskLines*`). New helpers `_scheduleSectionsPoll`/`_runSectionsPoll` plus
`_sectionsPollActive`/`_sectionsPollInFlight` flags. `NotifySectionsTaskPending()`,
`StopSectionsPolling()` names/signatures and the AL-facing contract (page
`projectschedule_50621_DHXScheduleBoard.al`'s `OnPollSectionsResult` trigger,
`DHXProjectScheduler.ControlAddin.al`'s procedures/events) were NOT touched - confirmed
unnecessary by reading both files first, this really is poll-loop-shape-only.

**Live reproduction note**: could NOT get the actual "reduced functionality" banner to visibly
render in a short (~1-2 min) fresh Playwright session even with rapid repeated Next-navigation
stress (one stress run did crash the Playwright-launched Chrome instance mid-test, consistent with
resource exhaustion from the bug but not a clean visual repro). The banner appears to be a
session-duration-dependent BC client watchdog signal, not reliably forced in a short scripted
session. Root cause confidence rests primarily on the code-level match to the confirmed-fixed
50710 bug, not on a live before/after screenshot of the banner itself. After the fix + republish,
4 rapid Next clicks (crossing into weeks with multiple Jobs / >50 sections, e.g. DJB0001/DJB0002)
produced no console error growth and rendered correctly - no regression, but also not a positive
banner-gone confirmation since it was never positively reproduced.

**Investigated but did NOT change**: `SectionsPageSize := 50` in `LoadSchedulerSectionsPaginated`
bounds Part A by SECTION count (Job/Job-Task/ancestor rows), not event count -
`GetYUnitElementsJSON_Project_Paged` in codeunit 50604 walks the full period's Day Planning rows
unbounded and only trims at Job boundaries. Confirmed via BC API query: 1053 Day Planning rows
company-wide for a single week (14-20 Sep 2026) - real density, and plausible that Part A's first
page carries a heavy chunk of that. Did NOT add an event-count cap (mirroring
`ReqAssign_BuildPlanningDataJson_Paged`'s `DayTaskLinesPageSize=400` groupwise cap) because no
actual render lag was observed live - only the poll-loop fix was justified by direct evidence. If
the banner recurs after this fix, event-count-bounding Part A is the next thing to try, using the
1053/week figure as a sizing reference.

Related: [[project_request_assignment_planner]] (the sibling page whose fix this was ported from).
