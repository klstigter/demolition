tableextension 50619 "Opt. Res. Ledger Entry" extends "Res. Ledger Entry"
{
    // Day Task traceability fields — populated during posting by EventSubs (codeunit 50603).
    // Applies only when the originating Job Journal Line type is Resource.
    // The "Res. Ledger Entry" is updated (Modify) from within the
    // OnBeforeJobLedgEntryInsert event, at which point "Job Ledger Entry"."Ledger Entry No."
    // already holds the entry no. of this record.
    fields
    {
        field(50618; "Opt. Daytask Date"; Date)
        {
            Caption = 'Day Task Date';
            DataClassification = CustomerContent;
            Editable = false;
        }

        field(50619; "Opt. Daytask Line No."; Integer)
        {
            Caption = 'Day Task Line No.';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }
}
