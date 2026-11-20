pageextension 50608 "Job Planning Lines Opt." extends "Job Planning Lines"
{
    // Manual trigger to force BC to re-run its Price Calculation module lookup on
    // existing Job Planning Lines. Job Planning Lines can be auto-created by codeunit
    // 50607 "Job Planning Lines Prep. Mgt." before the correct Resource Price List setup
    // existed (or before the UOM matched at creation time), leaving them stuck at
    // Unit Price = 0.00 forever since nothing re-triggers pricing afterwards.
    //
    // MECHANISM: calls only the public table procedure
    // "Job Planning Line".UpdateAllAmounts() - confirmed by decompiling the actual
    // base-app table source (Microsoft_Base Application_*.app,
    // src/Projects/Project/Planning/JobPlanningLine.Table.al) that UpdateAllAmounts()
    // is itself the correct/complete pipeline: it calls InitRoundingPrecisions() FIRST,
    // then UpdateUnitCost(), then FindPriceAndDiscount(CurrFieldNo) - the extensible
    // Price Calculation module's entry point (backed by interface "Price Calculation" /
    // codeunit "Price Calculation Mgt.") - then UpdateTotalCost(), HandleCostFactor(),
    // UpdateUnitPrice(), UpdateTotalPrice(), UpdateAmountsAndDiscounts() and
    // UpdateRemainingCostsAndAmounts(). The record is persisted with Modify(true).
    //
    // WHY THE EARLIER "CALL FindPriceAndDiscount DIRECTLY, THEN UpdateAllAmounts()"
    // APPROACH CRASHED (live error: "The value of ROUND parameter 2 is outside of the
    // permitted range... current value 0"):
    // FindPriceAndDiscount's Type::Resource branch rounds via
    // ConvertAmountToLCY(Amount, UnitAmountRoundingPrecision), and
    // UnitAmountRoundingPrecision is a record-instance Decimal variable that starts at 0
    // and is ONLY ever populated by the table's own InitRoundingPrecisions() procedure
    // (which reads Currency."Unit-Amount Rounding Precision", falling back to the blank/
    // LCY Currency record when the Job has no Currency Code). Base app NEVER calls
    // FindPriceAndDiscount on its own without InitRoundingPrecisions() having already run
    // first (confirmed: every OnValidate trigger that reaches a rounding-dependent
    // procedure calls InitRoundingPrecisions() explicitly, or goes through
    // UpdateAllAmounts() which calls it internally as its very first step). Calling
    // FindPriceAndDiscount directly, before UpdateAllAmounts() had a chance to run
    // InitRoundingPrecisions(), left UnitAmountRoundingPrecision at 0 -> Round(value, 0)
    // -> the exact runtime error seen. The direct call was also redundant:
    // UpdateAllAmounts() already calls FindPriceAndDiscount(CurrFieldNo) internally, so
    // simply calling UpdateAllAmounts() alone performs the full, correctly-ordered price
    // recalculation with no separate FindPriceAndDiscount call needed here.
    //
    // -----------------------------------------------------------------------------------
    // SECOND ACTION: "Unlink and Delete"
    //
    // Deleting a Job Planning Line created by codeunit 50607 "Job Planning Lines Prep.
    // Mgt." (CreateJobPlanningLine) can fail with the live error "This Project Planning
    // Line cannot be deleted because linked project ledger entries exist." - confirmed by
    // decompiling the actual base-app table source (Microsoft_Base Application_*.app,
    // src/Projects/Project/Planning/JobPlanningLine.Table.al, trigger OnDelete(), ~line
    // 1499-1520):
    //
    //   if "Usage Link" then begin
    //       JobUsageLink.SetRange("Job No.", "Job No.");
    //       JobUsageLink.SetRange("Job Task No.", "Job Task No.");
    //       JobUsageLink.SetRange("Line No.", "Line No.");
    //       ...
    //       if not JobUsageLink.IsEmpty() then
    //           Error(JobUsageLinkErr, TableCaption);
    //   end;
    //
    // i.e. the guard only fires when "Usage Link" = true AND at least one "Job Usage
    // Link" (table 1020) row still exists for that exact Job No./Job Task No./Line No.
    // combination. codeunit 50607 sets "Usage Link" := true (raw field assignment) and
    // inserts one Job Usage Link row per originating Job Ledger Entry, so every line this
    // feature creates is permanently subject to this guard.
    //
    // table 1020 "Job Usage Link"'s primary key (confirmed by decompiling
    // src/Projects/Project/Job/JobUsageLink.Table.al) is "Job No." + "Job Task No." +
    // "Line No." + "Entry No." - there can be MULTIPLE Job Usage Link rows per Job
    // Planning Line (one per originating Job Ledger Entry), so this action filters/
    // deletes by Job No./Job Task No./Line No. only (NOT Entry No.) to remove ALL of
    // them for that line. Table 1020 has no OnDelete trigger (confirmed - the whole
    // table object is just fields + keys + a Create() insert helper), so a plain
    // DeleteAll(false) is safe with no side effects. Once every matching Job Usage Link
    // row is gone, JobUsageLink.IsEmpty() on the subsequent Delete(true) of the Job
    // Planning Line itself returns true and the base-app guard passes cleanly - no need
    // to also clear "Usage Link" back to false first.
    //
    // This is deliberately destructive (removes traceability + deletes data), so the
    // action requires an explicit Confirm() naming the selected count before doing
    // anything, and aborts entirely if declined.
    //
    // WHY THE ORIGINAL "RE-VALIDATE UOM TO ITSELF" APPROACH FAILED:
    // Validate("Unit of Measure Code") internally executes Validate(Quantity) as an
    // explicit step of its own OnValidate trigger body (confirmed by the live AL call
    // stack: "Unit of Measure Code - OnValidate" -> "Quantity - OnValidate" ->
    // UpdateRemainingQuantity -> ControlUsageLink). ControlUsageLink is a local
    // procedure (confirmed absent from the table's exported symbol surface, along with
    // UpdateRemainingQuantity - neither is callable directly either) that errors
    // whenever a line has one or more "Job Usage Link" rows in the database but
    // Line Type <> Budget. That combination is permanent for every line this feature
    // creates: codeunit 50607's CreateJobPlanningLine sets Line Type = Billable and
    // "Usage Link" := true via raw field assignment (not Validate()), then inserts the
    // linked Job Usage Link rows immediately afterwards - so the DB-level invariant
    // ControlUsageLink enforces is violated by design for every line this button will
    // ever run against. Any later Validate() that cascades into Quantity (via "No.",
    // "Unit of Measure Code", or Quantity itself) will always hit this guard.
    // FindPriceAndDiscount is a separate, standalone, publicly exported procedure -
    // Validate(Quantity) is its own explicit statement inside the UOM trigger body, not
    // something FindPriceAndDiscount cascades into - so calling it directly re-runs only
    // the price lookup, without ever touching Quantity, UpdateRemainingQuantity, or
    // ControlUsageLink.
    actions
    {
        addafter("Item Availability by")
        {
            action("Calculate Sales Price")
            {
                ApplicationArea = Jobs;
                Caption = 'Calculate Sales Price';
                Image = Price;
                ToolTip = 'Recalculates Unit Price and Unit Cost for the selected Project Planning Line(s) from the current Resource Price List setup. Use this for lines that were created before the correct price list was in place.';

                trigger OnAction()
                var
                    JobPlanningLineSelection: Record "Job Planning Line";
                    ProcessedCount: Integer;
                    SkippedCount: Integer;
                    ResultMsg: Label '%1 Project Planning Line(s) recalculated. %2 line(s) skipped because they are not Type = Resource.';
                begin
                    JobPlanningLineSelection.Copy(Rec);
                    CurrPage.SetSelectionFilter(JobPlanningLineSelection);
                    if JobPlanningLineSelection.FindSet(true) then
                        repeat
                            if JobPlanningLineSelection.Type = JobPlanningLineSelection.Type::Resource then begin
                                JobPlanningLineSelection.UpdateAllAmounts();
                                JobPlanningLineSelection.Modify(true);
                                ProcessedCount += 1;
                            end else
                                SkippedCount += 1;
                        until JobPlanningLineSelection.Next() = 0;
                    CurrPage.Update(false);
                    Message(ResultMsg, ProcessedCount, SkippedCount);
                end;
            }
            action("Unlink and Delete")
            {
                ApplicationArea = Jobs;
                Caption = 'Unlink and Delete';
                Image = Delete;
                ToolTip = 'Removes the Job Usage Link traceability records for the selected Project Planning Line(s) and then permanently deletes the line(s), bypassing the standard "linked project ledger entries exist" delete guard. This is irreversible - use only for lines created by mistake, wrong grouping, or testing artifacts.';

                trigger OnAction()
                var
                    JobPlanningLineSelection: Record "Job Planning Line";
                    JobUsageLink: Record "Job Usage Link";
                    SelectedCount: Integer;
                    DeletedCount: Integer;
                    ConfirmQst: Label 'This will remove the Job Usage Link traceability records for %1 selected Project Planning Line(s) and then permanently delete them. This action cannot be undone.\\Do you want to continue?';
                    ResultMsg: Label '%1 Project Planning Line(s) unlinked and deleted.';
                begin
                    JobPlanningLineSelection.Copy(Rec);
                    CurrPage.SetSelectionFilter(JobPlanningLineSelection);
                    SelectedCount := JobPlanningLineSelection.Count();
                    if SelectedCount = 0 then
                        exit;

                    if not Confirm(ConfirmQst, false, SelectedCount) then
                        exit;

                    if JobPlanningLineSelection.FindSet(true) then
                        repeat
                            JobUsageLink.SetRange("Job No.", JobPlanningLineSelection."Job No.");
                            JobUsageLink.SetRange("Job Task No.", JobPlanningLineSelection."Job Task No.");
                            JobUsageLink.SetRange("Line No.", JobPlanningLineSelection."Line No.");
                            JobUsageLink.DeleteAll(false);

                            JobPlanningLineSelection.Delete(true);
                            DeletedCount += 1;
                        until JobPlanningLineSelection.Next() = 0;

                    CurrPage.Update(false);
                    Message(ResultMsg, DeletedCount);
                end;
            }
        }
        addafter("Category_Item Availability by")
        {
            actionref("Calculate Sales Price_Promoted"; "Calculate Sales Price")
            {
            }
            actionref("Unlink and Delete_Promoted"; "Unlink and Delete")
            {
            }
        }
    }
}
