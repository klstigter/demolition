pageextension 50622 "Opt. Job Ledger Entries" extends "Job Ledger Entries"
{
    // Shows Day Task traceability fields on the Project Ledger Entries list.
    // Fields are read-only; they are set during posting by EventSubs (codeunit 50603).
    layout
    {
        addafter("Job Task No.")
        {
            field("Opt. Daytask Date"; Rec."Opt. Daytask Date")
            {
                ApplicationArea = All;
                Caption = 'Day Task Date';
                ToolTip = 'Specifies the Day Task date that was linked to the originating Project Journal line.';
                Editable = false;
            }
            field("Opt. Daytask Line No."; Rec."Opt. Daytask Line No.")
            {
                ApplicationArea = All;
                Caption = 'Day Task Line No.';
                ToolTip = 'Specifies the Day Task line number that was linked to the originating Project Journal line.';
                Editable = false;
            }
        }
    }
}
