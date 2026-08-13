---
name: mark_markedonly_pagerun_controladdin_broken
description: Record.Mark()+MarkedOnly()+Page.Run() silently opens an EMPTY list when Page.Run() is invoked from a control add-in event trigger (e.g. OnShowSegmentData fired via Microsoft.Dynamics.NAV.InvokeExtensibilityMethod) - confirmed live on this tenant/BC version.
metadata:
  type: project
---

`Record.Mark(true)` + `Record.MarkedOnly(true)` + `Page.Run(PageId, Rec)` - a standard, normally-reliable
AL idiom for opening a list pre-filtered to an ad hoc, non-field-filterable record set - reliably opens
the target page with **zero rows** when the `Page.Run()` call happens inside a control add-in event
trigger (e.g. `usercontrol(...) { trigger OnShowSegmentData(...) }`), itself fired from JS via
`Microsoft.Dynamics.NAV.InvokeExtensibilityMethod`. Confirmed live via Playwright against the actual BC
web client (NL_Test, BC 28.1) on 2026-08-10 while building the barchart "Show Data" right-click
drilldown feature (`src/dhx/barchart/codeunit_50662_SkillCapacityAnalysisMgt.al`).

**Why:** `Page.Run()` invoked from this call path opens the target page at a fresh, bookmarked URL
(confirmed by the browser actually navigating to a new `page=...&filter=...` address) rather than as an
in-session page-stack push. Plain `SetRange`/`SetFilter` field filters survive that round-trip - they
serialize straight into the URL/bookmark - but `Record.Mark()`'s in-memory marked-record list does not.
The symptom is deceptive: the code path that checks `if not AnyMarked then Message(...)` is NOT taken
(marking genuinely found and flagged real records moments earlier in the same call), so the page opens
normally and looks like it worked - it just always shows 0 rows (or, for a page with a "new row" affordance
in edit mode, 1-2 entirely blank placeholder rows that look like real-but-empty data at a glance).

**How to apply:** Never use `Mark()`/`MarkedOnly()`/`Page.Run()` for a page opened from a control add-in
event trigger (or anywhere else `Page.Run()` is known/suspected to do a full bookmarked navigation rather
than an in-session push). Instead build a plain OR-filter string from the resolved key values and use
`SetFilter("Field", '%1|%2|%3', ...)` - the same pattern page 50704's own factbox `OnDrillDown` already
used successfully for an equivalent Internal/External resource classification problem (see its local
`BuildCodeOrFilter` helper: `foreach Value in Values do FilterText += (FilterText='' ? '' : '|') + Value`).
No filter-character escaping is attempted - fine for Code[20] identifiers in this codebase, not a
general-purpose filter builder. See [[project_skillcapacitychart_true_capacity_fix]] and
[[barchart_v1_wrong_controladdin_bug]] for related barchart drilldown work. If you see a "Show Data"/
drilldown feature open the RIGHT page with the RIGHT filter in the URL but display 0 rows (or blank
placeholder rows) despite the chart/factbox showing a nonzero value for that exact segment, suspect this
exact bug before anything else - check for `Mark(`/`MarkedOnly(` upstream of a `Page.Run()` reached via a
control add-in trigger.
