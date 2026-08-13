---
name: feedback-summaryview-do-not-modify
description: Page 50626 "Summary View" is reference/template only and must never be edited — build new display variants as standalone new pages instead
metadata:
  type: feedback
---

Page 50626 "Summary View" (`src\page\Pag50626.SummaryView.al`, backed by temp table 50612 "Summary Weekly" in `src\table\table_50612_ResourceWeeklyHours.al`) must NOT be modified, even to add a new procedure. It is reference/template only — other things depend on it and the user wants it left stable.

**Why:** User explicitly corrected an in-progress task where a new `SetSkillHoursView()` procedure had been added to this page to support a new toggle combination; told to revert it and build the new view as a genuinely separate page object instead.

**How to apply:** When asked for a new "view"/display variant of Summary View's matrix (e.g. a different combination of ShowResource/ShowSkillCode/ShowJob/ShowJobTask/ShowYear/ShowWeekNo), do NOT touch Pag50626.SummaryView.al or table 50612. Instead create a new page with its own data-loading procedure (query "Day Planning" directly, group into a local temp buffer with the same shape) and its own display logic. See [[project-skill-hours-summary-page]] for the first page built this way (page 50705), including the period-navigation pattern it borrowed from page 50695 "Capacity Overview" (Previous/Today/Next actions + a read-only "Period" label field, e.g. "Daily: Tue 11 Aug 2026").

This same "don't touch, copy instead" rule likely extends to other objects explicitly called out as reference/template by the user in future requests — treat such labels as a hard constraint, not a style preference.
