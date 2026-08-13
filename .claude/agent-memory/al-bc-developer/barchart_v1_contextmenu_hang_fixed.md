---
name: barchart_v1_contextmenu_hang_fixed
description: src/dhx/barchart_v1/wrapper.js had the same right-click-hang bug as the live chart (unbounded {once:true} dismiss-listener accumulation) - fixed 2026-08-10 by porting the live chart's tracked-handler pattern
metadata:
  type: project
---

`src/dhx/barchart_v1/wrapper.js`'s `ShowContextMenu`/`HideContextMenu` (the legacy POC chart, page
50681 "Req. vs Capacity Skl Dhx v1") had the exact same root cause as the live chart
(`src/dhx/barchart/wrapper.js`) had before ITS fix earlier the same session: the 4 dismiss
listeners (click/contextmenu/scroll/keydown) were registered on `document` with `{once:true}` and
never tracked/removed explicitly. A run of right-clicks on different bars with no intervening
left-click/scroll/Escape leaves every prior invocation's click/scroll/keydown listeners
permanently attached (only `contextmenu` self-cleans, since the next right-click's own event fires
it) - unbounded growth, one set per right-click.

**Why:** The file's own header comment literally said "Identical to the live barchart wrapper.js's
own ShowContextMenu - kept as its own local copy" - true when it was written, but it was copied
from the live chart's implementation BEFORE that file got its own fix, so the copy carried the bug
forward and then went stale relative to the (now-fixed) original.

**How to apply:** Fixed by porting the exact same pattern now live in
`src/dhx/barchart/wrapper.js`: added a module-level `contextMenuDismissHandlers` var, `HideContextMenu`
explicitly removes the tracked handler set (if any) before clearing `contextMenuEl`, and
`ShowContextMenu` calls `HideContextMenu()` unconditionally as its first line (was already doing
this) so at most one dismiss-listener set is ever live. Verified live via Playwright (NL_Test, BC
28.1) on 2026-08-10: instrumented `HideContextMenu` with a call-count log across 6 rapid
right-clicks on different bars/legend with no intervening dismissal - exactly 1 `HideContextMenu`
call per right-click (linear, not accumulating), `contextMenuDismissHandlers` back to `null` after
the sequence ends (no dangling listeners). "Show Data" smoke-tested afterward (right-click CAPACITY
bar -> click "Show Data") still correctly opens page 224 "Resource Capacity Entries" filtered to
the current week with real data (45 rows) - the fix did not regress the feature.

**Test-methodology gotcha hit while verifying this:** re-running an `page.evaluate` block that
wraps/monkey-patches a page-global function (e.g. `innerWin.HideContextMenu = function(){...
origHide...}`) MULTIPLE times in the same page session (without reloading) compounds - each
evaluate call wraps the ALREADY-wrapped function again, so a single real call cascades into N
nested log entries. Looked exactly like a listener-accumulation bug at first (a burst of 6-7
`HideContextMenu` calls per click) until a fresh page reload + single instrumentation pass showed
the true 1:1 ratio. Always re-navigate before re-instrumenting a page-global for a clean read -
don't layer a second monkey-patch pass over a still-loaded page. Related to
[[barchart_grouped_pair_spacing_and_rightclick_fixes]]'s existing note about monkey-patching
`addEventListener` causing false positives - this is the same family of self-inflicted artifact,
different mechanism (function wrapping instead of listener wrapping).

See [[barchart_v1_wrong_controladdin_bug]] and [[mark_markedonly_pagerun_controladdin_broken]] for
other barchart_v1-specific gotchas, and [[barchart_grouped_pair_spacing_and_rightclick_fixes]] for
the live chart's original version of this same context-menu fix.
