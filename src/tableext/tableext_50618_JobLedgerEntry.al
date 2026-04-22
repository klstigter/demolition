tableextension 50618 "Opt. Job Ledger Entry" extends "Job Ledger Entry"
{
    // Day Task traceability fields — populated during posting by EventSubs (codeunit 50603)
    // via the OnBeforeJobLedgEntryInsert integration event in "Job Jnl.-Post Line".
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
