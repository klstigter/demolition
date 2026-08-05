---
name: al-matrix-page-dynamic-column-technique
description: Confirmed-compiling AL technique for a generic-column matrix page (dynamic header text + dynamic visibility per column) using CaptionClass area "3" and named variables — and two things that look plausible but fail to compile.
metadata:
  type: feedback
---

Building a classic BC "matrix" page (fixed rows, dynamic columns bound to a runtime list — e.g. one column per Skill Code, capped at N generic `"Column 1".."Column N"` fields on a temp buffer table) has two traps that only surface at `al_compile`, not by reading the AL docs casually:

1. **`CurrPage.<ControlName>.Caption := ...;` / `CurrPage.<ControlName>.Visible := ...;` from a page-local procedure does NOT resolve for fields declared inside a `repeater()`** — compiler error `AL0118 The name '<ControlName>' does not exist in the current context`, for BOTH `.Caption` and `.Visible` alike (it's not a "Caption isn't settable" error, the identifier itself isn't recognized in that context). Don't reach for this pattern for repeater/matrix columns even though it's a commonly-cited runtime-caption technique for other control types.

2. **Binding `Visible`/`CaptionClass` to an indexed array element (`Visible = ColumnVisible[1];`) fails with `AL0322 Array access is not valid for client expressions. Client expressions can only use simple data types and field references.`** `Visible`, `Editable`, `CaptionClass` etc. are all "client expressions" and only accept a bare identifier (a plain variable or a `Rec` field reference) — no array indexing, no function calls, no concatenation of an array element.

**The pattern that actually compiles clean (zero errors/warnings):** one dedicated pair of page-global scalar variables per generic column (`Column1Caption: Text[50]; Column1Visible: Boolean;` ... through `Column20Caption`/`Column20Visible`), bound directly in the field's properties:
```al
field(Column1; Rec."Column 1")
{
    CaptionClass = '3,' + Column1Caption;
    Visible = Column1Visible;
}
```
`CaptionClass` area `"3"` returns its expression **verbatim** as the caption (confirmed via Microsoft Learn's CaptionClass docs — areas `1`/`2` are base-app-specific lookup classes, `3` is the literal/free-text area, resolved by system Caption Class codeunit 42). Populate the 20 variable-pairs from a runtime list (e.g. an ordered Skill Code list) via a `case ColumnNo of 1: begin Column1Caption := ...; Column1Visible := ...; end; 2: ... end;` fan-out procedure — the `case` is still needed because assigning INTO a named variable from a loop-computed index is ordinary code (arrays are fine there), only the property-binding side is restricted to bare identifiers.

Applied in page 50696 "Capacity Overview Matrix" (`src/capacity_overview/page_50696_CapacityOverviewMatrix.al`), part of the Capacity Overview feature (buffer table 50693, mgt codeunit 50694, card page 50695). See [[project-dailyoptimizer]] for this feature's object IDs and calculation flow.
