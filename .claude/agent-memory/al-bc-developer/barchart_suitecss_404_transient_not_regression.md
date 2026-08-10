---
name: barchart_suitecss_404_transient_not_regression
description: Page 50692 console-error screenshot showed 2x suite.css 404 instead of the known 2x font 404 baseline - reproduced live, confirmed transient/stale-tab artifact, not a regression from wrapper.js grouped-bar/rightclick/legend session work
metadata:
  type: project
---

User reported a screenshot with exactly 8 console errors on page 50692 ("Skill Req./Cap. (New)"):
6x company-switcher 401s (known baseline, unrelated, ignore - see below) + **2x `suite.css` 404**
instead of the previously-established 2x font 404 baseline (`roboto-regular-webfont.woff`/`.woff2`).
Investigated whether this was a NEW regression from this session's `wrapper.js` changes (see
[[barchart_grouped_pair_spacing_and_rightclick_fixes]]).

**Conclusion: NOT a regression, not currently reproducible.** Two independent fresh
`browser_navigate` reloads of page 50692 (fresh tab GUIDs each time, e.g.
`.../tab/362f63f5-.../Resources/ExtractedResources/E414B16A/src/dhx/suite.css?_v=28.0.52916.0`)
both returned **200 OK** for `suite.css`, with the console instead showing the ORIGINAL known
baseline: 2x `src/dhx/fonts/roboto-regular-webfont.woff(2)` 404 + 6x company 401. Evidence ruling
out this session's code:
- `wrapper.js` never requests/injects `suite.css` - grepped, only 2 hits and both are plain code
  COMMENTS referencing suite.css's own CSS class names for reference (`.grid-line`, gray shades),
  not a `createElement('link')`/fetch/import.
- `DHXBarChartAddin.ControlAddin.al`'s `StyleSheets = 'src/dhx/suite.css'` property is untouched
  this session (git log on the file shows no changes touching this).
- `src/dhx/suite.css` exists on disk (155KB, last modified 2026-08-05, before this session's work)
  and is what's actually being served (confirmed 200).

**Why the screenshot differs:** most likely a transient artifact from a stale already-open browser
tab whose `Resources/ExtractedResources/<hash>` path (`E414B16A` in this env) briefly pointed at a
resource set mid-transition around an app republish, OR simply an intermittent/order-dependent
resource-loading race on that one page load - NOT deterministic. Root cause of the font 404s
themselves (separate, pre-existing, out of scope) is that `suite.css` line 13 has an `@font-face`
referencing `fonts/roboto-regular-webfont.woff(2)`, but no `src/dhx/fonts/` directory exists
anywhere in this repo - those font files were never bundled, on any session, unrelated to barchart
work.

**How to apply:** if a future console-error screenshot on this page shows an unexpected 404 that
doesn't match the last-confirmed baseline, don't assume regression from the most recent code
change - reproduce live via 2+ independent fresh navigations first (not just re-reading the same
open tab) before concluding a real bug exists. Check [[mark_markedonly_pagerun_controladdin_broken]]
and [[barchart_grouped_pair_spacing_and_rightclick_fixes]] for other confirmed-vs-artifact
distinctions made this session on the same page.
