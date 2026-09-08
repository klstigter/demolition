---
name: project-tooltip-colors-centralized
description: Hover/tooltip popup background+font color centralized in codeunit 50609 across all 14 src/dhx add-ins (2026-09-08)
metadata:
  type: project
---

Every DHX control add-in's hover/tooltip popup now sources its background/font color from two
new codeunit 50609 "Visual Default Settings" getters instead of per-add-in hardcoded hex:
`GetTooltipBackgroundColor()` (default `#FFFFFF`, Tok `TooltipBackgroundColorTok`) and
`GetTooltipFontColor()` (default `#000000`, Tok `TooltipFontColorTok`) - both follow the exact
`GetBarFontColor`/`GetWeekendColor` boolean-context-Get() pattern. Overridable via new table 50605
"Daily Optimizer Setup" fields 86/87 ("Tooltip Background Color"/"Tooltip Font Color"), editable
on page 50654 in a new "Hover / Tooltip Popup" group (AssistEdit -> Color Picker Lookup, same as
every other color field there), wired into ResetToDefault via `GetDefaultTooltipBackgroundColor`/
`GetDefaultTooltipFontColor`.

Deliberately a SEPARATE setting from `GetBarFontColor`/`BarFontColorTok` - that getter's own doc
comment already states it is explicitly NOT used for hover/tooltip text colour.

**Wiring pattern per add-in** (each add-in's own existing color channel was reused, not a new one
invented per add-in): AL page's ControlReady (or the JSON payload it already builds) sends
`tooltipBg`/`tooltipFont` (or a dedicated `SetTooltipColors(bg, font)` / `SetColors(json)`
ControlAddin procedure where no existing channel existed), and wrapper.js applies them as CSS
custom properties `--tooltip-bg-color`/`--tooltip-font-color` (or add-in-local names like CPO's
`--cpo-tooltip-bg`/`--cpo-tooltip-font`) - set on `document.documentElement` when the popup is
appended at `document.body` level (dhtmlXTooltip, most custom fixed-position popups), or on a
scoped root element when the popup is nested inside it (CPO's `.cpo-event-tip`, dayplanning_sequence's
`#dpsTooltip`, request_assignment's 4 tooltips under `#controlAddIn`).

**Full 14-folder status** (src/dhx):
- barchart_daily, barchart_weekly - dhx.Chart's built-in hover tooltip (`.dhx_tooltip`/
  `.dhx_tooltip__text`, Bar series default `tooltip:true` in suite.js) - wired via a new
  `tooltipBg`/`tooltipFont` key on the ChartData JSON (barchart_daily: page 50692 + page 50707;
  barchart_weekly: codeunit 50662's `BuildDayCapacityChartData` only, NOT the unused
  `BuildDayCapacityChartDataForRange` twin) + a new `ApplyTooltipColors` JS helper injecting a
  `<style>` tag (no local style.css exists in either folder - only suite.css is loaded).
- capacity_planning_overview - `.cpo-event-tip`/`.cpo-daily-summary-tip`, was already hardcoded
  white/dark - now driven by the same getters via page 50722's new `SendColors` + the
  previously-stub `applyColors` in capacityPlanningOverview.js.
- color_picker - SKIP, confirmed no hover-popup capability anywhere in suite.js's Colorpicker class.
- dayplanning_sequence - `.dps-tooltip` - new `SetTooltipColors` ControlAddin procedure.
- ganttdemo2 - THREE popups wired: vendored `.gantt_tooltip` (overrides dhtmlxgantt.css's
  `--dhx-gantt-tooltip-background/color`), custom `#bc_DayPlanning_tooltip` (was inline
  `style.background/color`, now `var(...)`; its nested `.dp-tooltip-table` light-on-dark
  rgba(255,255,255,...) accents were also flipped to dark-on-light to stay legible), and the
  `#res-filter-tooltip-popup`/`#gnt-filter-tooltip-popup` pair - all via one new
  `SetTooltipColors` ControlAddin procedure.
- orderintakekanban - SKIP, confirmed no tooltip anywhere in kanban.js/kanban.css.
- poolresourceschedule, resourceschedule_with_capacity - `.dhtmlXTooltip.tooltip` +
  `#res-filter-tooltip-popup` - added `tooltipBg`/`tooltipFont` keys to the existing
  `SetBarColors` JSON channel both already had.
- projectschedule - `.dhtmlXTooltip.tooltip` + `#tsk-filter-tooltip-popup` - same, via its
  existing `SetBarColors`.
- request_assignment - 4 custom tooltips (`.sequence-drag-tooltip`, `.assignment-detail-tooltip`,
  `.resource-skill-warning-tooltip`, `.request-detail-tooltip`) sharing rgba(255,255,255,.97-.99)
  backgrounds - this add-in had NO existing color channel at all, so a brand-new
  `SetColors(ColorsJsonTxt)` ControlAddin procedure was added, scoped to `#controlAddIn`.
- resourceschedule - `.dhtmlXTooltip.tooltip` + `#res-filter-tooltip-popup` - had no existing
  color procedure either (only `SetBarFontColor`), so added a new `SetTooltipColors`.
- res_scheduler_weekly_factbox - SKIP, its `dhx.Grid` explicitly sets `tooltip: false`.
- richtext - SKIP, only toolbar-button `title` tooltips (Undo/Redo/etc, 51 matches in
  richtext.js) - button-hover chrome, not a data hover-popup, explicitly out of scope.

Secondary muted/semantic sub-colors inside each tooltip (labels, dates, status pills, warning red,
mismatch red) were deliberately left untouched everywhere - only the shell
background + primary text color now source from the two getters, matching how
[[project_colorconstants_codeunit_50609]] already scopes each setting narrowly (e.g.
GetSkillFontColor explicitly does NOT fall back to GetBarFontColor).

Compile-only verified clean (al_compile, zero errors) - not published, per
[[feedback_user_publishes_manually]].
