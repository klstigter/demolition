# Bug Diagnosis — Job Planning Line Unit Price = 0.00 after auto-creation

**Date:** 2026-07-21
**Severity:** N/A — not a code bug (see Correction below)
**Status:** Retracted — root cause is a data/UOM mismatch, not the code path diagnosed below

## Correction (2026-07-21)

The initial diagnosis below assumed the created Job Planning Line's `Unit of Measure Code`
was `UUR` (matching the Price List line) based on the Job Ledger Entry's UOM context, and
concluded the price search was being skipped by a code guard. The user confirmed the actual
`Unit of Measure Code` on the created line is **`DOOS`**, not `UUR` — the Price List line only
has a price for `UUR`. With no Price List line matching `DOOS`, BC's price search correctly
returns `Unit Price = 0.00`; this is expected pricing behavior, not a defect in
`CreateJobPlanningLine`'s validation order or the conditional guard analyzed below.

Per this skill's own rule: *"If the root cause is configuration (missing setup, number series,
posting group), say so and do not propose a code fix."* — no code fix is proposed. The
remaining open question is upstream: why the line was created with `UOMCode = DOOS` in the
first place (traces back to `JobLedgerEntry."Unit of Measure Code"` on the originating posted
usage/Day Planning entry) — that is either intentional (DOOS is genuinely the correct UOM for
that usage, and the Price List is missing a DOOS line) or a separate, upstream data-entry
question, not something this diagnosis covers.

The analysis below is kept for reference but its conclusion does not apply to this symptom.

---

## Symptom

Job Planning Lines created by codeunit 50607 "Job Planning Lines Prep. Mgt." (procedure
`CreateJobPlanningLine`) via the "Create Planning Lines for Invoice" / Optimizer path show
`Unit Price = 0.00` and `Unit Cost = 0.00`, even though the Resource ("SANITAIR") has an
active Price List (S00001, Assign-to Type = All Customers) with a matching line:
`Unit of Measure Code = UUR`, `Minimum Quantity = 0`, `Unit Price = 50.00`.

The created line otherwise looks correct: `No. = SANITAIR`, `Unit of Measure Code = UUR`,
`Quantity = 32`, `Price Calculation Method = Lowest Price`, `Cost Calculation Method = Lowest
Price`.

**Reproducibility:** Always, for this Resource/UOM combination (where the resource's default
Unit of Measure already equals the target UOM read from the Job Ledger Entry — "UUR" is very
likely SANITAIR's own base/default Unit of Measure in this NL-localized company, "uur" =
Dutch for "hour").

## Layer and category

- **Layer:** Logic
- **Category:** 1.3 "Decimal shows 0 after calculation" — root cause #3, "Field not
  validated — Validate not called" (a price-relevant field's `OnValidate` trigger, which
  performs the price search, never actually runs for this record).

## Hypotheses

| Priority | Root cause | Probability | Evidence for/against |
|---|---|---|---|
| 1 | Conditional guard skips the `Unit of Measure Code` `Validate` call when the resource's own default UOM already equals the target UOM, so the `OnValidate("Unit of Measure Code")` trigger — which re-runs BC's Price Calculation search — never fires for this record | HIGH | Line 410-411 of `CreateJobPlanningLine`: `if JobPlanningLine."Unit of Measure Code" <> UOMCode then JobPlanningLine.Validate("Unit of Measure Code", UOMCode);`. Since "UUR" matches the observed final UOM and this is plausibly the resource's own base UOM, the guard is false and the explicit Validate is skipped entirely — the only price search that ran was during `Validate("No.", InvoiceResNo)`, and whatever that returned (0) stands uncorrected. |
| 2 | `"Job No."`/`"Job Task No."` are set via direct field assignment + `Insert(true)` rather than `Validate(...)`, so `OnValidate("Job Task No.")` defaulting logic (which may seed Job Task-level pricing context such as Location Code) never runs before the price search on `Validate("No.", ...)` | MEDIUM | Matches FP-04 (direct assignment instead of Validate) exactly, but there's no direct evidence yet that Job Task-level context is actually required for this specific Price List line (Assign-to Type = All Customers is a broad, Job-independent match) — kept as a fallback hypothesis if the primary fix doesn't fully resolve it. |
| 3 | The extensible Price Calculation module (Lowest Price shown as the method) simply requires an explicit re-trigger/refresh call after all price-relevant fields are final, rather than relying on incremental per-field `OnValidate` side effects | LOW | Consistent with hypothesis 1's mechanism (the missing re-trigger IS the missing `Validate` call) — not a separate cause, just a restatement of the same underlying mechanic. |

## Confirmed root cause

`src/codeunit/codeunit_50607_JobInvoicePrepMgt.al`, `CreateJobPlanningLine`, lines ~409-411:

```al
JobPlanningLine.Validate("No.", InvoiceResNo);
if JobPlanningLine."Unit of Measure Code" <> UOMCode then
    JobPlanningLine.Validate("Unit of Measure Code", UOMCode);
```

`Validate("No.", InvoiceResNo)` defaults `"Unit of Measure Code"` to the resource's own base
UOM as a side effect of resolving the resource, and — for `Type::Resource` — performs BC's
price search using whatever field values are known *at that point*. The subsequent guard is a
"skip if already equal" micro-optimization: when the resource's default UOM already equals
the caller-supplied `UOMCode` (as is the case here), the explicit `Validate("Unit of Measure
Code", UOMCode)` call — which is what actually re-runs the price search with the line's final
context — is skipped entirely. `Validate()` in AL always re-executes the field's `OnValidate`
trigger regardless of whether the value differs from the current one, so this guard is not
protecting against a no-op re-validate; it is actively *preventing* a price recalculation that
would otherwise happen for free.

## Proposed fix

Remove the conditional guard so `Validate("Unit of Measure Code", UOMCode)` always runs
unconditionally after `Validate("No.", InvoiceResNo)`, regardless of whether the value already
matches. This guarantees the price search re-runs with the line's final `No.`/`Unit of
Measure Code` context every time, fixing the observed case (target UOM coincides with the
resource's default UOM) without changing behavior for the case that already worked (target UOM
differs from the default).

## Regression risk

- Low: the removed guard was purely a micro-optimization (avoid a redundant Validate call);
  removing it makes the code run the *same* Validate call unconditionally instead of
  conditionally — no new fields are touched, no new code paths are introduced.
- The one behavioral change is that `OnValidate("Unit of Measure Code")` now always fires once
  more per created line, even when the value doesn't change. This could theoretically alter
  `Unit Price`/`Unit Cost`/`Line Discount %` if BC's price search returns a *different* result
  than what `Validate("No.", ...)` alone produced — but that different result is precisely the
  correct one (matching what a user would see if they manually cleared and re-entered the UOM
  field), so this is the intended fix, not a side effect to guard against.
- Does not touch hypothesis #2 (Job No./Job Task No. direct assignment) — if testing after this
  fix still shows `Unit Price = 0.00` for some records, that is the next thing to investigate,
  as a separate diagnosis.

## Tests required

- **Happy path:** Create a Job Planning Line via "Create Planning Lines for Invoice" →
  Optimizer for a Resource whose base/default Unit of Measure equals the Day Planning's Unit
  of Measure Code (the exact scenario in the bug report — e.g. SANITAIR / UUR). Confirm `Unit
  Price = 50.00` (from the matching Price List line) instead of `0.00`.
- **Adjacent:** Create a line for a Resource/UOM combination where the target UOM *differs*
  from the resource's default UOM (the guard previously evaluated true and already worked).
  Confirm `Unit Price` is still resolved correctly and unchanged by this fix.
- **Edge case:** A Resource with no matching Price List line at all (price genuinely should be
  0, e.g. no active price list, or quantity below a Minimum Quantity break). Confirm `Unit
  Price` legitimately stays `0.00` in that case — i.e. the fix does not fabricate a price where
  none should exist.
