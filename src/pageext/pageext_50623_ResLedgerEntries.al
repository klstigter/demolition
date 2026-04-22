pageextension 50623 "Opt. Res. Ledger Entries" extends "Resource Ledger Entries"
{
    // Shows Day Task traceability fields on the Resource Ledger Entries list.
    // Only populated for entries that originated from a Resource-type Project Journal line.
    // Fields are set during posting by EventSubs (codeunit 50603).
    layout
    {
        addafter("Resource No.")
        {
            field("Opt. Daytask Date"; Rec."Opt. Daytask Date")
            {
                ApplicationArea = All;
                Caption = 'Day Task Date';
                ToolTip = 'Specifies the Day Task date that was linked to the originating Project Journal line (Resource type only).';
                Editable = false;
            }
            field("Opt. Daytask Line No."; Rec."Opt. Daytask Line No.")
            {
                ApplicationArea = All;
                Caption = 'Day Task Line No.';
                ToolTip = 'Specifies the Day Task line number that was linked to the originating Project Journal line (Resource type only).';
                Editable = false;
            }
        }
    }
}
