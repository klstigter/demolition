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
        }
    }
}
