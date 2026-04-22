tableextension 50617 "Opt. Job Journal Line" extends "Job Journal Line"
{
    // Field 50617 : API-only signal — triggers batch posting from the last JSON line.
    // Fields 50618-50619 : Day Task traceability — carried forward to Job Ledger Entry
    //                      and Res. Ledger Entry during posting via EventSubs (codeunit 50603).
    fields
    {
        field(50617; "Opt. Trigger Post"; Boolean)
        {
            Caption = 'Trigger Post';
            DataClassification = SystemMetadata;
        }

        field(50618; "Opt. Daytask Date"; Date)
        {
            Caption = 'Day Task Date';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if ("Opt. Daytask Date" <> 0D) then begin
                    TestField("Job No.");
                    TestField("Job Task No.");
                end;
                // Reset line no. whenever the date changes
                "Opt. Daytask Line No." := 0;
            end;
        }

        field(50619; "Opt. Daytask Line No."; Integer)
        {
            Caption = 'Day Task Line No.';
            DataClassification = CustomerContent;
            // TableRelation = "Day Tasks"."Day Line No." where(
            //     "Job No." = field("Job No."),
            //     "Job Task No." = field("Job Task No."),
            //     "Task Date" = field("Opt. Daytask Date"));

            trigger OnValidate()
            begin
                if ("Opt. Daytask Line No." <> 0) then begin
                    TestField("Job No.");
                    TestField("Job Task No.");
                    TestField("Opt. Daytask Date");
                end;
            end;
        }
    }
}
