---
name: project-resource-isexternal-pool-contamination-fixed
description: Fixed 24 resources in NL_Test/CRONUS NL that had impossible Is External=true + Is Pool/Is Pool Member=true combos; root cause and fix pattern documented
metadata:
  type: project
---

Fixed on 2026-08-10: 24 resources in BC sandbox NL_Test (tenant a60762e1-df10-4e4b-8f44-174c51589110, company "CRONUS NL") had `"Is External" = true` simultaneously with `"Is Pool" = true` (16 resources: DRP001-004, DRP010-014, DRP020-024, DRP030-031) or `"Is Pool Member" = true` (8 resources: DRM00007/27/47/61/63/65/67/79) — a combination the OnValidate triggers in `tableext_50603_Resource.al` (fields 50604/50624/50603) are supposed to make impossible.

**Root cause**: `report_50600_RepairDayPlanningResourceGroup.al`'s `MakeInternalResourcesExternal` procedure (a demo-data one-off, run manually in the past) sets `Resource."Is External" := true` via direct field assignment, bypassing the trigger, without checking existing Pool status first.

**Fix**: added a symmetric one-off procedure `UndoMakeInternalResourcesExternal` to the same report file, following its established convention (XML-doc'd, listed as a commented-out call in `OnPreReport()` for future reuse, only briefly uncommented to run once then recommented). It clears `"Is External"` back to false via **direct field assignment + Modify()** — NOT `Validate()`, because field 50604's OnValidate false-branch unconditionally wipes `Vendor No.`, `Pool Resource No.`, `Is Pool`, AND `Is Pool Member` together, which would have destroyed the classification being restored. This direct-assignment-to-undo-a-direct-assignment pattern is worth remembering if similar contamination bugs show up elsewhere in this codebase — any table with an OnValidate cascade that clears sibling fields is not safely undoable via Validate() once contaminated.

Vendor No. handling differed by group: the 16 "Is Pool" resources kept their own pre-existing legitimate pool vendor (DRPnnn→DRVnnn pattern, untouched by the original bug since it only fills Vendor No. when blank); the 8 "Is Pool Member" resources had Vendor No. wrongly set to "10000" (Vendor.FindFirst()'s result, identical across all 8 — confirmed contamination since genuine Pool Member resources always have blank Vendor No.) and that was cleared back to blank.

Verified fixed: both `Is External=Yes AND Is Pool=Yes` and `Is External=Yes AND Is Pool Member=Yes` filters on page 77 now return 0 rows (were 16 and 8). Confirmed no knock-on effect on the Skill Req./Cap. chart: codeunit 50662's `External := Is External OR Is Pool OR Is Pool Member` OR-logic (lines ~113, ~689) means these resources were/are/remain "External" for chart purposes regardless of which flag carries it.

See also [[project_skillcapacitychart_true_capacity_fix]] for the codeunit 50662 chart logic this data cleanup does NOT affect.
