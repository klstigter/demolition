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
burn time retrying parameter variations — it's very likely the same underlying tooling
issue. Report it as a tooling problem needing investigation outside the AL extension code
itself (e.g. VS Code AL extension state, or the MCP server's environment-URL resolution),
and let the user publish manually via VS Code's own Publish command instead. See also
[[feedback_no_publish_when_told]].
