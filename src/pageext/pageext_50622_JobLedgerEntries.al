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
            field("Opt. Invoice Resource No."; Rec."Invoice Resource No.")
            {
                ApplicationArea = All;
                Caption = 'Invoice Resource No.';
                ToolTip = 'Specifies the Invoice Resource No. that was linked to the originating Project Journal line.';
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
            actionref("Transfer To Planning Lines Opti_Promoted"; "Transfer To Planning Lines Opti")
            {
            }
            actionref("Transfer To Planning Lines Opt._Promoted"; "Transfer To Planning Lines Opt.")
            {
            }
        }
        addafter("Transfer To Planning Lines")
        {
            action("Transfer To Planning Lines Opti")
            {
                ApplicationArea = Jobs;
                Caption = 'Transfer To Planning Lines';
                Ellipsis = true;
                Image = TransferToLines;
                ToolTip = 'Create planning lines from posted project ledger entries. This is useful if you forgot to specify the planning lines that should be created when you posted the project journal lines.';

                trigger OnAction()
                var
                    JobLedgEntry: Record "Job Ledger Entry";
                    JobTransferToPlanningLine: Report "Job Transfer To Planning Lines";
                    JobLedgEntrySelection: Record "Job Ledger Entry";
                    SkippedLines: Integer;
                    ProcessedCount: Integer;
                    Lblmsg: Label '%1 usage entries were processed and %2 usage entries were skipped because they originated from Day Planning and should be processed using the "Create Planning Lines" action instead.';
                begin
                    JobLedgEntrySelection.Copy(Rec);
                    CurrPage.SetSelectionFilter(JobLedgEntrySelection);
                    if JobLedgEntrySelection.FindSet() then
                        repeat
                            JobLedgEntrySelection.TestField("Job No.");
                            JobLedgEntrySelection.TestField("Job Task No.");
                            JobLedgEntrySelection.Testfield("Entry Type", JobLedgEntrySelection."Entry Type"::Usage);
                            if JobLedgEntrySelection."Opt. DayPlanning Line No." = 0 then begin
                                JobLedgEntry := JobLedgEntrySelection;
                                JobLedgEntry.Mark(true);
                                ProcessedCount += 1;
                            end else
                                SkippedLines += 1;
                        until JobLedgEntrySelection.Next() = 0;
                    JobLedgEntry.MarkedOnly(true);

                    Clear(JobTransferToPlanningLine);
                    JobTransferToPlanningLine.GetJobLedgEntry(JobLedgEntry);
                    JobTransferToPlanningLine.RunModal();
                    Clear(JobTransferToPlanningLine);
                    message(Lblmsg, ProcessedCount, SkippedLines);
                end;
            }
            action("Transfer To Planning Lines Opt.")
            {
                ApplicationArea = Jobs;
                Caption = 'Create Planning Lines';
                Ellipsis = true;
                Image = TransferToLines;
                ToolTip = 'Create planning lines from grouped posted project ledger entries. This is a replacement for the native "Transfer To Planning Lines" action, which is hidden when this extension is installed. The replacement action handles posted usage entries that originated from Day Planning differently, grouping them by Skill and creating one planning line per Skill instead of one planning line per usage entry.';

                trigger OnAction()
                var
                    JobLedgEntrySelection: Record "Job Ledger Entry";
                    JobLedgEntryDefault: Record "Job Ledger Entry";
                    JobLedgEntryCustom: Record "Job Ledger Entry";
                    JobTransferToPlanningLine: Report "Job Transfer To Planning Lines";
                    JobPlanningLinesPrepMgt: Codeunit "Job Planning Lines Prep. Mgt.";
                    JobPlanningLine: Record "Job Planning Line";
                    AlreadyLinkedCount: Integer;
                    ProcessedCount: Integer;
                    SkippedLines: Integer;
                    LinesCreated: Integer;
                    msg: Text;
                    Lblmsg: Label 'There are %1 usage entries  skipped because they do not originated from Day Planning and should be processed using the "Transfer to Planning Lines" action instead.\\';
                begin
                    // Default: posted usage NOT originating from Day Planning - unchanged
                    // native flow, scoped to just this subset of the user's selection.
                    JobLedgEntrySelection.Copy(Rec);
                    CurrPage.SetSelectionFilter(JobLedgEntrySelection);
                    if JobLedgEntrySelection.FindSet() then
                        repeat
                            JobLedgEntrySelection.TestField("Job No.");
                            JobLedgEntrySelection.TestField("Job Task No.");
                            JobLedgEntrySelection.Testfield("Entry Type", JobLedgEntrySelection."Entry Type"::Usage);
                            if (JobLedgEntrySelection."Opt. DayPlanning Line No." <> 0) then begin
                                JobLedgEntryCustom := JobLedgEntrySelection;
                                JobLedgEntryCustom.Mark(true);
                                processedCount += 1;
                            end else
                                SkippedLines += 1;
                        until JobLedgEntrySelection.Next() = 0;
                    JobLedgEntryCustom.MarkedOnly(true);

                    if JobLedgEntryCustom.Findset() then begin
                        LinesCreated := JobPlanningLinesPrepMgt.PrepareJobPlanningLinesFromJobLedgerEntry(JobLedgEntryCustom, JobPlanningLine, AlreadyLinkedCount, ProcessedCount);
                        msg := JobPlanningLinesPrepMgt.FormatResultMessage(LinesCreated, ProcessedCount, AlreadyLinkedCount, 0, 0);
                        if SkippedLines > 0 then
                            msg := STRSUBSTNO(Lblmsg, SkippedLines) + msg;
                        Message(msg);
                    end;
                end;
            }
        }
    }
}
