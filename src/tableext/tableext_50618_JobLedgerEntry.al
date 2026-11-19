tableextension 50618 "Opti Job Ledger Entry" extends "Job Ledger Entry"
{
    // Day Planning traceability fields — populated during posting by EventSubs (codeunit 50603)
    // via the OnBeforeJobLedgEntryInsert integration event in "Job Jnl.-Post Line".
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
