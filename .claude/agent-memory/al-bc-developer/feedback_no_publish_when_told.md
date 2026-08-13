---
name: feedback-no-publish-when-told
description: When told not to publish or not to do browser/manual verification, stop at al_compile/al_build and just report - don't call al_publish or attempt Playwright/browser checks.
metadata:
  type: feedback
---

When the user or coordinator explicitly says not to publish and not to do manual/browser
verification, stop the workflow at `al_compile`/`al_build` (fix any compile errors, confirm
a clean build) and then just report back: what was implemented, compile status, and any
uncertainties/assumptions made (e.g. JS-library behavior confirmed via source reading vs.
guessed). Do not call `al_publish`, and do not attempt Playwright/browser-driven verification
even if the task brief originally asked for it — an explicit "don't publish, I'll verify
myself" instruction overrides the default unit-testing/deploy-loop workflow described in the
system prompt.

**Why:** The user wants to control when changes actually land on the sandbox and to do their
own manual click-through verification, rather than having the agent publish preemptively.
This was stated explicitly mid-task on 2026-08-13, overriding an in-progress plan that had
already called for `al_publish` + a "what to click through" verification list.

**How to apply:** Treat "don't publish" / "I'll publish and verify myself" as a standing
override for the rest of that task (and default caution for future tasks in this project
unless told otherwise) — even if a task brief or earlier plan explicitly asked for
`al_publish`. If `al_publish` was already attempted before the instruction arrived, don't
retry it after — just note what happened (success/failure) in the report. See also
[[al_publish_invalid_uri_tooling_bug]] for a separate, unrelated publish-tooling issue
observed in this project.
