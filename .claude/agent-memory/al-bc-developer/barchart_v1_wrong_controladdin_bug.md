---
name: barchart_v1_wrong_controladdin_bug
description: page 50681 "Req. vs Capacity Skl Dhx v1" was referencing the LIVE control add-in DHXBarChartAddin instead of its own DHXBarChartAddin_v1 — fixed 2026-08-10
metadata:
  type: project
---

`src/dhx/barchart_v1/page_50692_RequestedVsCapacitySkillsDhx.al` (page 50681 "Req. vs Capacity
Skl Dhx v1") had `usercontrol(DhxBarChart; DHXBarChartAddin)` — the LIVE barchart's control
add-in object (`src/dhx/barchart/DHXBarChartAddin.ControlAddin.al`), NOT its own
`DHXBarChartAddin_v1` (`src/dhx/barchart_v1/DHXBarChartAddin.ControlAddin.al`). Both add-ins had
identical `ControlReady()`/`OnDataPointClicked(Text)` event signatures, so this compiled silently
— the v1 page was actually loading `src/dhx/barchart/wrapper.js` + `startupScript.js` (the LIVE
chart's JS, via the LIVE controladdin's `Scripts`/`StartupScript` properties), not
`src/dhx/barchart_v1/wrapper.js`, this whole time. Only surfaced when a v1-only event
(`OnShowSegmentData`) was added to `DHXBarChartAddin_v1` with a different signature than the live
one's — AL0284/AL0419 (parameter mismatch) on the page's trigger, because it was binding against
the wrong add-in's event contract.

**Why:** Two separate copies of the same-purpose control add-in exist (live in `barchart/`, legacy
POC in `barchart_v1/`) with historically-identical trigger surfaces, so a copy-paste page reference
to the wrong add-in name produces no compile error until the two add-ins' contracts diverge.

**How to apply:** Fixed to `usercontrol(DhxBarChart; DHXBarChartAddin_v1)`. When touching either
`barchart/` or `barchart_v1/` again, verify every page's `usercontrol(...)` line actually names the
control add-in object living in the SAME folder — don't trust that a clean compile means the right
one is wired up, since a shared-signature subset hides this class of mistake. See
[[project_skillcapacitychart_true_capacity_fix]] for related barchart work.
