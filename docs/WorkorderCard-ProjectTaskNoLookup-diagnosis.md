# Bug Diagnosis — Project Task No. lookup reverts after selection on Workorder Card

**Date:** 2026-07-22
**Severity:** Medium
**Status:** Diagnosed

## Symptom

On `src\page\Pag50662.WorkorderCard.al`, the `field("Project Task No."; Rec."Project Task No.")` control (lines 61-88) opens a custom lookup (page "Job Task List - Project") via its `OnLookup` trigger. The user selects a different task from the list and confirms (LookupOK), but the "Project Task No." field on the card reverts/stays at the old value instead of showing the newly selected task.

**Reproducibility:** Always (confirmed by user), when the field already has a value before the lookup is invoked.

## Layer and category

- **Layer:** UI
- **Category:** 3.3 Action/control on page appears to do nothing / value not reflected (adjacent to "regular field shows wrong value" — the underlying record is updated but the visible field is reverted, not merely stale)

## Hypotheses

| Priority | Root cause | Probability | Evidence for/against |
|---|---|---|---|
| 1 | `OnLookup`'s `var Text: Text` parameter is never assigned. On a field with a custom `OnLookup` returning `true`, the client applies whatever is left in `Text` (the original pre-lookup display text) back onto the field after the trigger returns — silently overwriting the `Rec.Validate` + `CurrPage.Update(true)` that already ran inside the trigger. | HIGH | User confirms the field visibly reverts to the old value, which is the exact symptom of the client re-applying stale `Text` after the trigger body already changed `Rec`. The sibling `"Project No."` field (lines 34-60) has the identical code shape and is not reported broken, but that field is rarely re-picked after initial entry on an existing Work Order — so the same latent bug there has likely just gone unnoticed, not proven absent. |
| 2 | A subpage/part (`Job Planning Lines Part`, SubPageLink on `"Job Task No." = FIELD("Project Task No.")`) fails to re-resolve its filter after `CurrPage.Update(true)` | LOW | Would explain a stale *subpage*, not the field control itself reverting — ruled out by the user's answer that the field itself (not the subpage) shows the old value. |
| 3 | `Rec.Validate("Project Task No.", ...)` throws/no-ops due to the field's `TableRelation` where-clause against `"Project No."` | LOW | Would surface as a runtime error dialog, not a silent revert; no error reported. |

## Confirmed root cause

The `OnLookup` trigger at `Pag50662.WorkorderCard.al:65-87` never sets its `var Text: Text` parameter. It relies solely on `Rec.Validate(...)` + `CurrPage.Update(true)` to reflect the new value, then returns `exit(true)`. When an `OnLookup` trigger returns `true`, the BC client uses the final value of `Text` to (re)apply the field's display value — since `Text` was left unchanged (still holding the value that was in the control before the lookup ran), the client re-writes the old value into the control immediately after the trigger's own `Rec.Validate`/`CurrPage.Update` already set the new one, so the visible field reverts.

There is a second, independent, already-noted defect in the same trigger: the guard `if Rec."Project Task No." = '' then exit(false);` should instead guard on `Rec."Project No." = ''`, since a blank Project Task No. is a normal, valid starting point for opening the lookup (only a blank Project No. makes the task filter/`Get` meaningless).

## Proposed fix

In the `OnLookup` trigger on `"Project Task No."` (`Pag50662.WorkorderCard.al:65-87`):
1. Change the early-exit guard to check `Rec."Project No." = ''` instead of `Rec."Project Task No." = ''`, and only call `Task.Get(...)` when `Rec."Project Task No." <> ''` (so opening the lookup on a blank field no longer requires a pre-existing task).
2. After `Rec.Validate("Project Task No.", Task."Job Task No.")` succeeds, set `Text := Task."Job Task No."` before `exit(true)`, so the client applies the correct final value instead of the stale pre-lookup text.

No changes needed to `page_50617_JobTaskList_Project.al` — the root cause is isolated to the card page's trigger.

## Regression risk

Low — the change only affects this one field's lookup trigger. The sibling `"Project No."` field's `OnLookup` (lines 34-60) has the same latent `Text`-not-set issue; it is not in scope for this fix per the user's report, but is worth a follow-up note since it could exhibit the same revert if a user re-picks an existing Work Order's project.

## Tests required

- **Happy path:** On a Work Order with a Project No. and an existing Project Task No., open the lookup, pick a different task, confirm — the field should now show the newly selected task and stay there (not revert).
- **Adjacent:** On a Work Order with a Project No. set but Project Task No. blank, open the lookup — it should now open (previously blocked by the blank guard) and picking a task should populate the field correctly.
- **Edge case:** Cancel out of the lookup (Esc / Cancel button) in both cases above — the field must remain unchanged (no partial update, no error).
