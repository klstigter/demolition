---
name: project-skill-hours-summary-page
description: New page 50705 "Skill Hours Summary" — standalone requested-hours-per-skill-per-week view with daily period navigation, opened from Workorder Card and Work Order Sub
metadata:
  type: project
---

Page 50705 "Skill Hours Summary" (`src\page\page_50705_SkillHoursSummary.al`) is a new, standalone page — created because page 50626 "Summary View" may not be modified, see [[feedback-summaryview-do-not-modify]]. Highest page ID in use before this was 50704 ("Day Capacity Chart Audit"), so 50705 was the next free page ID.

It renders the same grid shape Summary View produces with ShowSkillCode+Requested+ShowYear+ShowWeekNo on / everything else off (Skill Code | Year | Week No | Total | Monday..Sunday, requested hours only), but loads data itself straight from "Day Planning" (own `BuildSkillHoursGrid` procedure grouping by Skill Code/Year/Week No into the temp "Summary Weekly" table) rather than calling into table 50612 or page 50626.

Adds Previous/Today/Next period navigation + a read-only "Period" label (format "Daily: Tue 11 Aug 2026"), copied from page 50695 "Capacity Overview"'s pattern (`CalcMonday`, `FormatFullDayText`-style helpers). The period is a single anchor date; the grid always shows the full Monday-Sunday ISO week containing that date. `LoadContext(JobNo, JobTaskNo)` sets the same Job No./Job Task No. filtering scope Summary View's `LoadDataSet(JobNo, JobTaskNo)` overload uses — call it, then `.Run()`.

Opened from two places, both via an action captioned "Skill Hours Summary" (Image = ResourceGroup):
- `src\page\Pag50662.WorkorderCard.al` — action `ShowSkillHoursSummary`, next to the existing `ShowSummary` action, promoted alongside it.
- `src\page\Pag50656.Workorder.al` (page "Work Order Sub") — action `ShowSkillHoursSummary`, next to the existing `OpenSpecification` action (not promoted, matching that page's existing style).

**Why:** User wanted a "requested hours per skill per day" companion view to the existing per-job/task Summary View drilldowns on those two pages, without risking the reference-only Summary View page.

**How to apply:** Any further tweaks to this specific view (styling, extra columns, drilldown behavior) belong in page 50705, not page 50626. If the period-nav pattern needs reuse a third time, consider whether it's worth extracting — two independent copies (page 50695, page 50705) exist as of this writing.
