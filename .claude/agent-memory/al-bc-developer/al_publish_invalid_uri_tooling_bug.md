---
name: al-publish-invalid-uri-tooling-bug
description: al_publish MCP tool failed 5x with "Invalid URI: The format of the URI could not be determined" regardless of params tried (appPath, projectPath, environment, tenant) - looks like broken tooling, not an auth/code problem.
metadata:
  type: project
---

On 2026-08-13, `al_publish` consistently failed with:
`"Invalid URI: The format of the URI could not be determined."` (errorDetails.code:
"UnknownError", retryable: true) across 5 attempts with varying parameter combinations:
default call, explicit `appPath` to the built .app, explicit `projectPath`, explicit
`environmentName`/`environmentType`/`tenant` matching the `NL_Copy20240710` launch.json
config. `al_auth_login` succeeded cleanly against the same environment/tenant immediately
before, ruling out an auth-token problem.

**Why noting this:** Looked at first like a parameter or auth mistake on the agent's part,
but the identical error across every parameter permutation (including ones copied directly
from `.vscode/launch.json`) points to a bug/misconfiguration in the AL MCP tool's own
publish command in this environment, not something fixable by adjusting call arguments.

**How to apply:** If `al_publish` fails with this exact "Invalid URI" error again, don't
burn time retrying parameter variations on the default (build+publish) call — it's very
likely the same underlying tooling issue. See also [[feedback_no_publish_when_told]].

**Working workaround found 2026-08-28:** the bug is specifically in `al_publish`'s own
internal build step, not the deploy step itself. Run `al_build` (onlyErrors:true) as a
separate call first, then call `al_publish` with `skipBuild: true` and an explicit
`appPath` pointing at the just-built .app (e.g.
`C:\Users\Ahmad\OneDrive\x\PROJECT\STRONG\demolition\Optimizers_DailyOptimizer_28.0.0.10.app`,
version/filename matches app.json's current version) plus the usual
`environmentName`/`environmentType`/`tenant`/`forceUpgrade: true`. This succeeded reliably
after 4 straight failures of the combined call in the same session. Try this before falling
back to asking the user to publish manually.
