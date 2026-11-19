---
name: appsource-technical-validation-prep
description: 2026-11-19 AppSource prep - all objects/fields/controls renamed with "Opti " affix; how to run analyzers (alc.exe, not MCP); what was left
metadata:
  type: project
---

Everything renamed with mandatory affix "Opti" (AppSourceCop.json, NOT yet registered with Microsoft). Object names now "Opti X" (shortened to <=30 chars), tableext fields "Opti X" (field IDs unchanged), pageext controls, tableext procedures "OptiX", profile "OptiPlanning", permission set "OptiDailyOptimizer". Dev DateEngine moved to ../demolition_dev_tools, test/ moved to ../demolition_tests/src/from_main (tests app NOT updated for new names).

**Why:** user wants Microsoft Technical Validation pass.

**How to apply:**
- al_compile / al_getdiagnostics MCP tools do NOT run analyzers and can serve STALE file state after bulk edits (reported phantom errors). Trust alc.exe: `ms-dynamics-smb.al-*/bin/alc.exe /project:<abs> /packagecachepath:.alpackages /out:<scratch> /analyzer:CodeCop.dll /analyzer:UICop.dll /analyzer:AppSourceCop.dll /assemblyprobingpaths:<bin>` (use MSYS_NO_PATHCONV=1 in git bash).
- al_build bumped app.json version to 29.0.0.0 and touched images/logo.png once - avoid al_build, restore version.
- Rename technique that worked: rename definitions, then loop compile -> fix error positions using old->new map; case-insensitive; never fall back to "replace any token on line" (hit same-named fields like Day Planning "Plan Status" vs enum).
- Left deliberately: AS0013 (tableext field IDs 50500-50531/50025 outside range), AS0084 (ID range), AS0003 (no baseline), AS0092 (needs App Insights connection string), AA0101/AA0102 (API camelCase - would break consumers), AA0215 file names.
