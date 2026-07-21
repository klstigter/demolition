tableextension 50617 "Opt. Job Journal Line" extends "Job Journal Line"
{
    // Field 50617 : API-only signal — triggers batch posting from the last JSON line.
    // Fields 50618-50619 : Day Planning traceability — carried forward to Job Ledger Entry
    //                      and Res. Ledger Entry during posting via EventSubs (codeunit 50603).
    fields
    {
        field(50618; "Opt. DayPlanning Date"; Date)
        {
            Caption = 'Day Planning Date';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if ("Opt. DayPlanning Date" <> 0D) then begin
                    TestField("Job No.");
                    TestField("Job Task No.");
                end;
                // Reset line no. whenever the date changes
                "Opt. DayPlanning Line No." := 0;
            end;
        }

        field(50619; "Opt. DayPlanning Line No."; Integer)
        {
            Caption = 'Day Planning Line No.';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if ("Opt. DayPlanning Line No." <> 0) then begin
                    TestField("Job No.");
                    TestField("Job Task No.");
                    TestField("Opt. DayPlanning Date");
                end;
            end;
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
    }
}
