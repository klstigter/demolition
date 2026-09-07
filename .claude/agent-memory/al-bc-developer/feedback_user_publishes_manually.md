---
name: feedback_user_publishes_manually
description: User now wants to run al_publish themselves rather than having the agent publish - agent should stop after a clean al_compile
metadata:
  type: feedback
---

Starting 2026-09-07, the user wants to control deployment: make code changes, run `al_compile`
(and `al_build` if a `.app` artifact is useful) to confirm the change is clean, then STOP - do not
call `al_publish`. Report back that the change compiles cleanly and is ready for the user to
publish and verify themselves.

**Why:** Told directly mid-session (via the coordinator) after a live debugging loop where the
agent had been publishing repeatedly to test hypotheses on the "Planning Role Center" chart-width
task ([[project_planning_rolecenter_chart_width]]). The user wants that control back.

**How to apply:** For ALL future AL work in this project (not just chart/role-center work) - do not
call `al_publish` unless the user explicitly asks for it again in a given session. If live-BC
verification is needed to confirm a fix actually works, say so explicitly in the final report
("ready to publish; verification is still pending until you publish") rather than publishing to
verify it yourself. This supersedes the general workflow instructions' default build->deploy loop
for this project. Related: [[feedback_skip_publish_verification_on_request]] (a similar one-off
version of this same preference from an earlier session) and [[feedback_no_publish_when_told]].
