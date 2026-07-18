pageextension 50622 "Opt. Job Ledger Entries" extends "Job Ledger Entries"
{
    // Shows Day Planning traceability fields on the Project Ledger Entries list.
    // Fields are read-only; they are set during posting by EventSubs (codeunit 50603).
    layout
    {
        addafter("Job Task No.")
        {
            field("Opt. DayPlanning Date"; Rec."Opt. DayPlanning Date")
            {
                ApplicationArea = All;
                Caption = 'Day Planning Date';
                ToolTip = 'Specifies the Day Planning date that was linked to the originating Project Journal line.';
                Editable = false;
            }
            field("Opt. DayPlanning Line No."; Rec."Opt. DayPlanning Line No.")
            {
                ApplicationArea = All;
                Caption = 'Day Planning Line No.';
                ToolTip = 'Specifies the Day Planning line number that was linked to the originating Project Journal line.';
                Editable = false;
            }
            field("Opt. Skill"; Rec."Skill")
            {
                ApplicationArea = All;
                Caption = 'Skill';
                ToolTip = 'Specifies the Skill that was linked to the originating Project Journal line.';
                Editable = false;
            }
            field(WorkTypeCode; Rec."Work Type Code")
            {
                ApplicationArea = All;
                Caption = 'Work Type Code';
                ToolTip = 'Specifies the Work Type Code that was linked to the originating Project Journal line.';
                Editable = false;
            }

        }
    }

    // Day-Planning-to-Invoice (Release 1): the native "Transfer To Planning Lines" action
    // creates one-to-one Budget-type planning lines from posted usage, with no awareness of
    // Day Planning/Skill grouping. Since AL cannot cancel a base-app action's own OnAction
    // (OnBeforeAction/OnAfterAction do not support IsHandled-style suppression), the native
    // action is hidden and replaced with one that fully controls the split BEFORE either
    // path runs - avoiding the cursor-sharing problems of trying to intercept native's own
    // per-entry posting event (codeunit "Job Post-Line"'s OnBeforeInsertPlLineFromLedgEntry;
    // see the now-removed codeunit 50608 for why that approach was abandoned).
    actions
    {
        modify("Transfer To Planning Lines")
        {
            Visible = false;
        }
        addafter("&Navigate_Promoted")
        {
            actionref("Transfer To Planning Lines Opt._Promoted"; "Transfer To Planning Lines Opt.")
            {
            }
        }
        addafter("Transfer To Planning Lines")
        {
            action("Transfer To Planning Lines Opt.")
            {
                ApplicationArea = Jobs;
                Caption = 'Transfer To Planning Lines';
                Ellipsis = true;
                Image = TransferToLines;
                ToolTip = 'Create planning lines from posted project ledger entries. This is useful if you forgot to specify the planning lines that should be created when you posted the project journal lines. note: this is a replacement for the native "Transfer To Planning Lines" action, which is hidden when this extension is installed. The replacement action handles posted usage entries that originated from Day Planning differently, grouping them by Skill and creating one planning line per Skill instead of one planning line per usage entry.';

                trigger OnAction()
                var
                    JobLedgEntryDefault: Record "Job Ledger Entry";
                    JobLedgEntryCustom: Record "Job Ledger Entry";
                    JobTransferToPlanningLine: Report "Job Transfer To Planning Lines";
                    JobPlanningLinesPrepMgt: Codeunit "Job Planning Lines Prep. Mgt.";
                    JobPlanningLine: Record "Job Planning Line";
                    AlreadyLinkedCount: Integer;
                    ProcessedCount: Integer;
                    LinesCreated: Integer;
                begin
                    // Default: posted usage NOT originating from Day Planning - unchanged
                    // native flow, scoped to just this subset of the user's selection.
                    JobLedgEntryDefault.Copy(Rec);
                    CurrPage.SetSelectionFilter(JobLedgEntryDefault);
                    if JobLedgEntryDefault.FindSet() then
                        repeat
                            if not ((JobLedgEntryDefault."Entry Type" = JobLedgEntryDefault."Entry Type"::Usage) and (JobLedgEntryDefault."Opt. DayPlanning Line No." <> 0)) then
                                JobLedgEntryDefault.Mark(true);
                        until JobLedgEntryDefault.Next() = 0;
                    JobLedgEntryDefault.MarkedOnly(true);
                    if not JobLedgEntryDefault.IsEmpty() then begin
                        Clear(JobTransferToPlanningLine);
                        JobTransferToPlanningLine.GetJobLedgEntry(JobLedgEntryDefault);
                        JobTransferToPlanningLine.RunModal();
                        Clear(JobTransferToPlanningLine);
                    end;

                    // Custom: posted usage originating from Day Planning - grouped,
                    // Skill-based Job Planning Line creation via codeunit 50607, instead of
                    // native's one-to-one Budget-line transfer.
                    JobLedgEntryCustom.Copy(Rec);
                    CurrPage.SetSelectionFilter(JobLedgEntryCustom);
                    if JobLedgEntryCustom.FindSet() then
                        repeat
                            if (JobLedgEntryCustom."Entry Type" = JobLedgEntryCustom."Entry Type"::Usage) and (JobLedgEntryCustom."Opt. DayPlanning Line No." <> 0) then
                                JobLedgEntryCustom.Mark(true);
                        until JobLedgEntryCustom.Next() = 0;
                    JobLedgEntryCustom.MarkedOnly(true);
                    if not JobLedgEntryCustom.IsEmpty() then begin
                        LinesCreated := JobPlanningLinesPrepMgt.PrepareJobPlanningLinesFromJobLedgerEntry(JobLedgEntryCustom, JobPlanningLine, AlreadyLinkedCount, ProcessedCount);
                        Message(JobPlanningLinesPrepMgt.FormatResultMessage(LinesCreated, ProcessedCount, AlreadyLinkedCount, 0, 0));
                    end;
                end;
            }
        }
    }
}
