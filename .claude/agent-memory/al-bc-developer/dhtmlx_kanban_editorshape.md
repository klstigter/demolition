---
name: dhtmlx-kanban-editorshape
description: DHTMLX Kanban custom edit-panel fields go in top-level `editorShape`, NOT `cardShape.fields` (silently ignored); built-in `description` drives both mini-card and edit box
metadata:
  type: feedback
---

In the vendored DHTMLX Kanban library (`src/dhx/kanban.js`, minified, no local docs), custom
detail/edit-panel fields must be declared in a **top-level `editorShape` array**, a sibling of
`cardShape` in the Kanban constructor config. A `fields:` array nested inside `cardShape` is
**silently ignored** — no error, nothing renders.

**Why:** verified by grepping the bundle. `_normalizeShapes` destructures
`{cardShape, columnShape, rowShape, readonly, editorShape}` from the init config and calls
`Gd(editorShape, normalizedCardShape)`. A token census of the whole bundle shows only three
occurrences of `fields` — all inside the editor's internal field-list component `_i` and its two
call sites. Nothing ever reads `cardShape.fields`. Two separate fix attempts were burned on this
before it was traced.

Other facts established from the same source, worth not re-deriving:

- **Supplying `editorShape` REPLACES the default**, it does not extend it.
  `Gd(t,e)` is `return (t || jr.filter(n => e[n.key]?.show)).map(...)`. So once you pass
  `editorShape`, every field you want in the panel must be listed explicitly (label, description,
  color, start_date, …) or it disappears.
- **`id` is not required** on entries — `Gd` does `n.id = n.id || Gr()` (auto-generated).
- **Captions render only when `label` is a non-empty string.** The `et` label wrapper does
  `P(f, n, ...)` where `n` is the label getter — a falsy label emits no `<label class="wx-label">`
  at all, producing a bare uncaptioned input.
- **Labels are safe to invent.** They pass through `getGroup("kanban")`, implemented as
  `r => n && n[r] || r`, so an untranslated caption falls back to the literal string.
- **The built-in `description` property is ONE value driving TWO places**: the mini-card subtitle
  (`cardShape.description.show && cardFields.description`) and the edit-panel textarea. You cannot
  show different text in each via that property — put the short/preview text in `description` and
  add the other as a custom `editorShape` field, which renders in the panel only.
- **`board.parse()` preserves config.** `_storeConfig` does `{...this.config, ...serialize(), ...e}`,
  so `cardShape`/`editorShape` survive every data reload.

**How to apply:** whenever adding or debugging fields in any DHTMLX Kanban add-in under
`src/dhx/*kanban*/wrapper.js`. Grep `kanban.js` to confirm before guessing — it is minified but
readable with a small node context-dump script. See also [[project-dailyoptimizer]].
