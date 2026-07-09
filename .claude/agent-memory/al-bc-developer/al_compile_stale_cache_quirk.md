---
name: al-compile-stale-cache-quirk
description: al_compile/al_getdiagnostics can report stale false-positive "codeunit is missing" errors after several rapid edits, while al_build succeeds cleanly - trust al_build.
metadata:
  type: feedback
---

Observed in this project (2026-07-08): after several back-to-back edits to `codeunit_50602_CreateDemoData.al` and `codeunit_50604_DHXDataHandler.al` in the same session, `mcp__al__al_compile` (and `al_getdiagnostics` scoped by folderPath) repeatedly reported:
- `AL0185 Codeunit 'Create Demo Data' is missing` (in report_50600)
- `AL0118 The name '"Create Demo Data"' does not exist in the current context` (in page_50654)

...even though `al_getdiagnostics` scoped directly at the two edited files individually returned zero errors, and a full `mcp__al__al_build` (which actually generates the .app package) succeeded with 0 errors/0 warnings, repeatedly, with a fresh output timestamp confirming it wasn't serving a cached result.

**Why:** `al_compile` appears to run against an incremental/cached in-memory compiler session that can get stuck referencing a stale project state after rapid consecutive edits across multiple files in one session. `al_build` does a full/cold compile and is authoritative — it's what actually produces the deployable package.

**How to apply:** If `al_compile` or `al_getdiagnostics` reports errors that look inconsistent (e.g. "object X is missing" for an object that demonstrably exists and compiles cleanly on its own), don't trust it blindly — cross-check with a full `al_build`. If `al_build` succeeds cleanly (0 errors/warnings, fresh timestamp), treat the build as ground truth and proceed (report the discrepancy to the user rather than silently chasing a phantom error). Don't burn time re-editing working code to chase an `al_compile`-only error that `al_build` doesn't reproduce. This does NOT excuse skipping `al_getdiagnostics`/`al_compile` as a first-pass check — just don't treat a lone `al_compile` failure as gospel when `al_build` disagrees.
