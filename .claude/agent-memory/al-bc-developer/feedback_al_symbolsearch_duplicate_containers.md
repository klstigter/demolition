---
name: feedback_al_symbolsearch_duplicate_containers
description: al_symbolsearch can return two different container IDs for the same System Application table even though only one Base/System Application .app is cached in .alpackages
metadata:
  type: feedback
---

`al_symbolsearch` on a System Application table (e.g. "No. Series Line") can return two
result sets with different internal container GUIDs and slightly different field lists
(one had an `Implementation` enum field, no `Allow Gaps in Nos.`; the other had
`Allow Gaps in Nos.`, no `Implementation`) — even though the project's `.alpackages` folder
only contained a single `Microsoft_System Application_28.2.x.app`. Root cause not confirmed
(likely the tool also indexes a broader/global symbol cache outside the project folder).

**Why:** Chased schema ambiguity for `No. Series Line` on the 2026-07-10 EnsureNoSeries fix
before realizing the project's actual `.alpackages` only has one real candidate version.
**How to apply:** Don't trust `al_symbolsearch` result count as proof of multiple live schema
versions. Cross-check against the actual files in the project's `.alpackages` folder
(`ls .alpackages`) to see which version is really in play, and when in doubt write code using
only the fields common to all returned variants, then let `al_compile`/`al_build` be the final
arbiter. See [[al_compile_stale_cache_quirk]] for a related symbol-cache gotcha.
