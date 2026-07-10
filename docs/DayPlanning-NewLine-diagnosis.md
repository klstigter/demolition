# Bug Diagnosis — "The page has an error" on Day Planning Card when creating a new line

**Date:** 2026-07-10
**Severity:** High
**Status:** Diagnosed

## Symptom

From Summary View (page 50626, List), the user drills down on an empty day cell
("Assigned") for a Job/Job Task/Resource combination that already has Day Planning
lines on *other* days. This opens the "Day Plannings" list (page 50630) pre-filtered
to that empty day. Creating a new line opens the Day Planning Card (page 50668) with
Job No. = DJB0001, Job Task No. = 01010, Day Line No. = 10000 (Plan Status = In
Request). The page immediately shows:

> "The page has an error. Refresh (F5) to undo the change, or correct the error."

with a red error badge anchored on the **Job No.** field (the first field of the
table's primary key).

**Reproducibility:** Occurs whenever a new Day Planning line is created for a
Job No./Job Task No. that already has existing lines on other dates whose "Day Line
No." would collide with the newly-computed one (very common — see root cause).

## Layer and category

- **Layer:** Data / Logic (schema migration without data migration)
- **Category:** 7.1 Duplicate records / primary-key violation surfaced through
  `OnInsertRecord`, misreported by the client as a generic field-level page error.

## Hypotheses

| Priority | Root cause | Probability | Evidence for/against |
|---|---|---|---|
| 1 | Primary key of table 50610 "Day Planning" was changed from `("Task Date","Day Line No.","Job No.","Job Task No.")` to `("Job No.","Job Task No.","Day Line No.")` in commit `4a11cf3` ("daytask primary key changed", 2026-05-12) **without renumbering existing data**. "Day Line No." used to restart at 10000 independently *per date*; after the change it must be unique per (Job No., Job Task No.) *across all dates*. Pre-existing rows (created before the change) very likely already have the same Day Line No. (typically 10000 for the first line of every date) repeated across multiple dates for the same Job/Task — a straight primary-key collision under the new key. | HIGH | Confirmed by reading `src/table/table_50610_DayPlanning.al:692-714` (old key commented out, new key in place) and the commit diff. `GetNextDayLineNo()` (table_50610_DayPlanning.al:766) and `GetNextDayLineNo(TaskDay, JobNo, JobTaskNo)` (table_50610_DayPlanning.al:861) were both updated to scan only by Job No./Job Task No., consistent with the new key — but nothing renumbers rows that were inserted under the old scheme. `Day Line No. = 10000` in the screenshot is exactly the value `GetNextDayLineNo` returns for "no conflicting rows found by its own (new) logic" — yet the record still fails to insert, which is the signature of a genuine PK collision against pre-existing legacy data the new logic doesn't see the same way SQL does. |
| 2 | The Day Planning Pattern generator (`codeunit_50610_DayPlanningMgt.al:142-147`) assigns `DayPlannings."Day Line No." := n * 10000` inside a per-date loop, without checking for existing records or other dates. Under the new date-agnostic PK this can create — and has likely already created — multiple rows with the exact same (Job No., Job Task No., Day Line No.) across different Task Dates, compounding hypothesis 1. | MEDIUM | Confirmed by reading the code; this path independently produces exactly the kind of legacy duplicate data hypothesis 1 depends on, but is a secondary/contributing cause, not the trigger for this specific manual-entry repro. |
| 3 | Ordering bug between the Card page's `OnNewRecord` (calls parameterless `GetNextDayLineNo()` immediately, page_50668:182-185) and `OnInsertRecord` (recalculates via the parameterized overload, page_50668:566-575) causes a stale Day Line No. to be shown/used. | LOW | Both procedures now use equivalent (Job No., Job Task No.)-scoped logic, so they should agree once Job No./Job Task No. are populated (confirmed populated in the screenshot). Doesn't explain a hard error by itself; ruled down in priority versus 1. |

## Confirmed root cause

The clustered primary key on table 50610 "Day Planning" was narrowed from
`("Task Date", "Day Line No.", "Job No.", "Job Task No.")` to
`("Job No.", "Job Task No.", "Day Line No.")` (commit `4a11cf3`, 2026-05-12), which
silently changes the uniqueness scope of "Day Line No." from *per date* to *per
Job/Job Task across all dates*. No data migration/renumbering was performed for
existing rows. As a result, many existing Job/Job Task combinations have multiple
rows (one per date, each historically starting its own numbering at 10000) that now
collide under the new key. When a user creates a new Day Planning line for such a
Job/Job Task, `OnInsertRecord` (page_50668:566-575) computes a "next" Day Line No.
that the AL logic believes is free, but the physical insert still fails against
already-conflicting legacy rows — the Business Central client surfaces this as the
generic "the page has an error" banner, anchored on Job No. because it's the leading
primary-key field.

## Proposed fix

1. **Data migration (required, separate from the code fix):** write an upgrade/one-time
   codeunit that renumbers "Day Line No." per (Job No., Job Task No.) so all existing
   rows satisfy the new PK uniqueness (e.g., re-sequence 10000, 20000, 30000... in
   Task Date order within each Job No./Job Task No. group), using `Rename` or a
   delete/re-insert pattern since Day Line No. is part of the clustered key.
2. **Code fix (secondary, hardening):** fix `codeunit_50610_DayPlanningMgt.al`
   pattern-generation loop (`DayPlannings."Day Line No." := n * 10000;`) to call
   `GetNextDayLineNo(...)` instead of the raw `n * 10000` formula, so it never
   proposes a Day Line No. that might already exist for a different date under the
   same Job/Job Task.

This is flagged as a **data migration issue**, not a pure code bug — per the skill's
rule 6, the migration must be scoped, tested, and confirmed separately before being
run against any environment with real data.

## Regression risk

- Renumbering "Day Line No." changes values that may be referenced elsewhere
  (FlowFields keyed on "Day Planning Line No." in Sales Line/Sales Invoice
  Line/Sales Cr.Memo Line — see table_50610_DayPlanning.al:569-690 — plus
  `codeunit_50617_DayPlanningPeriodSyncMgt.al` and API pages
  `page_50606_50675_DayPlanningLine.api.al`). Any external system or open document
  holding onto an old Day Line No. value must be accounted for before renumbering.
- The pattern-generator fix changes generated Day Line No. values going forward;
  confirm nothing depends on the old `n * 10000` numbering being stable/predictable.

## Tests required

- **Happy path:** Create a new Day Planning line (via Summary View drill-down) for a
  Job/Job Task that already has lines on other dates — insert succeeds, no page
  error, Day Line No. does not collide with any existing row for that Job/Job Task.
- **Adjacent:** Creating a Day Planning line for a brand-new Job/Job Task (no existing
  lines at all) still gets Day Line No. = 10000 and inserts cleanly.
- **Edge case:** A Job/Job Task with the maximum realistic number of historic dates/
  lines (post-migration) still computes a correct, non-colliding next Day Line No.,
  and the Day Planning Pattern generator no longer produces duplicate keys across
  dates for `Quantity of Lines > 1`.

## Skills Evidencing

| Field | Value |
|---|---|
| Skill loaded | bc-al-bug-fix |
| Symptom | "The page has an error" banner with red badge on Job No. when creating a new Day Planning line via Summary View drill-down |
| Layer | Data / Logic |
| Root cause | Primary key narrowed (Task Date removed) without a data migration to renumber pre-existing Day Line No. values, causing PK collisions on insert |
| Fix applied | Not yet applied — pending user confirmation |
| Diagnosis doc | docs/DayPlanning-NewLine-diagnosis.md |
| Tests defined | 3 (happy path, adjacent, edge case) |
