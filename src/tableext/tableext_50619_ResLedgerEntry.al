tableextension 50619 "Opt. Res. Ledger Entry" extends "Res. Ledger Entry"
{
    // Day Planning traceability fields — populated during posting by EventSubs (codeunit 50603).
    // Applies only when the originating Job Journal Line type is Resource.
    // The "Res. Ledger Entry" is updated (Modify) from within the
    // OnBeforeJobLedgEntryInsert event, at which point "Job Ledger Entry"."Ledger Entry No."
    // already holds the entry no. of this record.
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
        field(50620; Skill; Code[10])
        {
            DataClassification = ToBeClassified;
            tableRelation = "Skill Code";
        }
        field(50621; "Invoice Resource No."; Code[20])
        {
            Caption = 'Invoice Resource No.';
            DataClassification = ToBeClassified;
        }
        field(50622; "Approved Project Manager"; Code[50])
        {
            Caption = 'Approved Project Manager';
            DataClassification = ToBeClassified;
        }
    }
}
