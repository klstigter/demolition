pageextension 50623 "Opt. Res. Ledger Entries" extends "Resource Ledger Entries"
{
    // Shows Day Planning traceability fields on the Resource Ledger Entries list.
    // Only populated for entries that originated from a Resource-type Project Journal line.
    // Fields are set during posting by EventSubs (codeunit 50603).
    layout
    {
        addafter("Resource No.")
        {
            field("Opt. DayPlanning Date"; Rec."Opt. DayPlanning Date")
            {
                ApplicationArea = All;
                Caption = 'Day Planning Date';
                ToolTip = 'Specifies the Day Planning date that was linked to the originating Project Journal line (Resource type only).';
                Editable = false;
            }
            field("Opt. DayPlanning Line No."; Rec."Opt. DayPlanning Line No.")
            {
                ApplicationArea = All;
                Caption = 'Day Planning Line No.';
                ToolTip = 'Specifies the Day Planning line number that was linked to the originating Project Journal line (Resource type only).';
                Editable = false;
            }
        }
    }
}
