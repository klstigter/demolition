tableextension 50619 "Opti Res. Ledger Entry" extends "Res. Ledger Entry"
{
    // Day Planning traceability fields — populated during posting by EventSubs (codeunit 50603).
    // Applies only when the originating Job Journal Line type is Resource.
    // The "Res. Ledger Entry" is updated (Modify) from within the
    // OnBeforeJobLedgEntryInsert event, at which point "Job Ledger Entry"."Ledger Entry No."
    // already holds the entry no. of this record.
    fields
    {
        field(50618; "Opti Opt. DayPlanning Date"; Date)
        {
            Caption = 'Day Planning Date';
            DataClassification = CustomerContent;
            Editable = false;
        }

        field(50619; "Opti Opt. DayPlanning Line No."; Integer)
        {
            Caption = 'Day Planning Line No.';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(50620; "Opti Skill"; Code[10])
        {
            Caption = 'Skill';
            DataClassification = CustomerContent;
            tableRelation = "Skill Code";
        }
        field(50621; "Opti Invoice Resource No."; Code[20])
        {
            Caption = 'Invoice Resource No.';
            DataClassification = CustomerContent;
        }
        field(50622; "Opti Approved Project Manager"; Code[50])
        {
            Caption = 'Approved Project Manager';
            DataClassification = EndUserIdentifiableInformation;
        }
    }
}
