tableextension 50618 "Opt. Job Ledger Entry" extends "Job Ledger Entry"
{
    // Day Planning traceability fields — populated during posting by EventSubs (codeunit 50603)
    // via the OnBeforeJobLedgEntryInsert integration event in "Job Jnl.-Post Line".
    fields
    {
        field(50618; "Opt. DayPlanning Date"; Date)
        {
            Caption = 'Day Planning Date';
            DataClassification = CustomerContent;
            Editable = false;
        }

        field(50619; "Opt. DayPlanning Line No."; Integer)
        {
            Caption = 'Day Planning Line No.';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }
}
