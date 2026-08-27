---
name: project-request-assignment-planner
description: Object IDs/names for the new "Request/Assignment Planner" DHX control add-in feature (Job>Task>Sequence request tree over Resource capacity/assignment timeline)
metadata:
  type: project
---

New architecturally-significant feature area. AL side built 2026-08-27; two additions (shared workdays index + a reset event) folded in the same day at another session's request. JS side (wrapper.js/style.css/startupScript.js) landed in parallel and is now present on disk - full `al_build` succeeds and produces a real .app, no known outstanding errors.

## Objects
- `query 50609 "Unique Sequences in DayPlan"` - `src/query/query_50609_UniqueSequencesInDayPlan.al`. Single dataitem on Day Planning, filter(PlanDateFilter;"Plan Date"), columns Job No./Job Task No./Skill/Count. Created per spec but NOT currently called by the JSON builder below - sequenceKey grouping falls out naturally while iterating Day Planning rows for dayTaskLines, making a separate query call redundant. Kept as a standalone object since the spec asked for it explicitly (a future page/report might still want a plain "distinct sequences" list).
- `codeunit 50604 "DHX Data Handler"` extended with a new `ReqAssign_` region (`src/codeunit/codeunit_50604_DHXDataHandler.al`, appended at the end of the file) - see "Key procedures" below.
- `controladdin DHXRequestAssignmentAddin` - `src/dhx/request_assignment/DHXRequestAssignmentAddin.ControlAddin.al`. References `src/dhx/dhtmlxscheduler.js` + `src/dhx/GlobalFunction.js` + its own `wrapper.js`/`style.css`/`startupScript.js` (same shared-libs convention as poolresourceschedule/projectschedule/resourceschedule_with_capacity). Full final contract:
  - `procedure SetPlanningData(PlanningDataJsonTxt: Text)`
  - `event ControlReady()`
  - `event OnAcceptSequence(PayloadJsonTxt: Text)`
  - `event OnRejectSequence(PayloadJsonTxt: Text)`
  - `event OnAssignDayTaskLine(PayloadJsonTxt: Text)`
  - `event OnMoveAssignment(PayloadJsonTxt: Text)`
  - `event OnResizeAssignment(PayloadJsonTxt: Text)`
  - `event OnUnassignDayTaskLine(PayloadJsonTxt: Text)`
  - `event OnRequestReset()` - added later: the in-canvas "Reset assignments" button (broken/no-op in the source demo; the port fixes it to discard client-side state and re-request fresh data). No payload - AL side just rebuilds and re-pushes the full 30-workday window, same as Refresh.
  Do not rename any of these - JS side is built against these exact names.
- `page 50710 "DHX Request Assignment Board"` - `src/dhx/request_assignment/page_50710_DHXRequestAssignmentBoard.al`. Hosts the usercontrol; `ControlReady`, the `Refresh` action, and `OnRequestReset` all call one shared local `RefreshPlanningData()` (no duplicated rebuild logic across the three). Default window: Today() to the 30th workday from Today() inclusive (Today counts as day 1 if itself Mon-Fri) - local `GetDefaultWindow`/`IsWorkday`.

## Key procedures (codeunit 50604, `ReqAssign_` prefix)
- `ReqAssign_BuildPlanningDataJson(StartDate; EndDate): Text` - single JSON payload, top-level keys: `workdays`, `resources`, `dayTaskLines`, `capacitySlots`, `skillColors`, `statusColors`.
- `workdays` is the single authoritative 0-based-index array: every Mon-Fri date from StartDate to EndDate inclusive, as `"yyyy-MM-dd"` strings, in order. Built together with the `Dictionary of [Date,Integer]` lookup map in ONE pass by local `ReqAssign_BuildWorkdayIndexMap(StartDate; EndDate; var Map; var WorkdaysArr)` - both `dayTaskLines[].dayIndex` and `capacitySlots[].dayIndex` resolve from that SAME Map (threaded down as a `var` param into `ReqAssign_BuildDayTaskLinesJson` and `ReqAssign_BuildCapacitySlotsJson`), so the two panes can never disagree about what index a date maps to. A `dayTaskLines` row whose Plan Date isn't itself Mon-Fri (not expected, not enforced at the table level) gets `dayIndex = -1` rather than being dropped; a `capacitySlots` row on a non-workday date is dropped entirely (weekend capacity is out of scope for this workday-only calendar).
- Six commit procedures matching six of the seven controladdin events 1:1 (the 7th, `OnRequestReset`, has no AL-side codeunit counterpart - it's handled entirely on the page, see above): `ReqAssign_AssignDayTaskLine`, `ReqAssign_MoveAssignment` (thin wrapper over AssignDayTaskLine - identical payload/handling), `ReqAssign_ResizeAssignment` (times only, no resourceId), `ReqAssign_UnassignDayTaskLine`, `ReqAssign_AcceptSequence` (the ONLY point a whole-sequence drag-drop persists - JS keeps it provisional until Accept), `ReqAssign_RejectSequence` (no-op stub, JS discards state client-side).
- All six always use `Validate()` for "Assigned Resource No."/assigned times (shared local `ReqAssign_ApplyAssignment`), never direct field assignment - hard product requirement so table 50610's cascade (Resource Group/Vendor/Skill) runs.
- "Sequence" has no literal field: `sequenceKey` = `"<Job No.>|<Job Task No.>|<Skill>"`, computed inline per Day Planning row. A "Day Task Line" id = `"<Job No.>|<Job Task No.>|<Day Line No.>"` (parsed back via local `ReqAssign_ParseId`).
- Decimal-hours convention (e.g. 8.5 for 08:30) is this feature's own, via local `ReqAssign_TimeToDecimalHours`/`ReqAssign_DecimalHoursToTime` - distinct from the rest of codeunit 50604's ISO-datetime-string helpers (`ToSessionDateTimeTxt`/`ConvertToUserTimeZone`), which this feature does NOT use.
- `skillColors.backgroundColor` reuses the existing `ColorConstants.GetSkillBarColor` convention (codeunit 50609) - same one `ResolveRequestedColor` already uses. `borderColor`/`textColor` have no existing per-skill convention anywhere (codeunit 50609 only has one *global* `GetBarFontColor` for all bar text) so they're static Label fallbacks (`ReqAssignSkillBorderColorTok`='#5AA6C8', `ReqAssignSkillTextColorTok`='#035B7E'). `statusColors.ok` is likewise a static fallback (`ReqAssignOkStatusBackgroundColorTok`='#DDF2E5'/`ReqAssignOkStatusTextColorTok`='#26613A') - no equivalent named status-colour setting exists yet.

## Compiler behavior note (corrects the original task brief)
`controladdin` `Scripts`/`StyleSheets` file paths ARE validated at `al_compile`/`al_build` time in this environment (confirmed live, 2026-08-27: AL0327 "Missing file 'src/dhx/request_assignment/wrapper.js'" fired while the JS port hadn't landed yet - a real build-blocking error, not a warning). By the time the two additions above were folded in, wrapper.js/style.css/startupScript.js existed on disk (built in parallel) and the error cleared on its own - full `al_build` now produces a real .app. Any future controladdin created ahead of its JS/CSS files will hit the same AL0327 until those files exist - there is no way to stub past this without creating placeholder files.
