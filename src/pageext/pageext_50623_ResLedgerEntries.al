pageextension 50623 "Opti Res. Ledger Entries" extends "Resource Ledger Entries"
{
    // Shows Day Planning traceability fields on the Resource Ledger Entries list.
    // Only populated for entries that originated from a Resource-type Project Journal line.
    // Fields are set during posting by EventSubs (codeunit 50603).
    layout
    {
        addafter("Resource No.")
        {
            field("Opti Opt. DayPlanning Date"; Rec."Opti Opt. DayPlanning Date")
            {
                ApplicationArea = All;
                Caption = 'Day Planning Date';
                ToolTip = 'Specifies the Day Planning date that was linked to the originating Project Journal line (Resource type only).';
                Editable = false;
            }
            field("Opti Opt. DayPlanning Line No."; Rec."Opti Opt. DayPlanning Line No.")
            {
                ApplicationArea = All;
                Caption = 'Day Planning Line No.';
                ToolTip = 'Specifies the Day Planning line number that was linked to the originating Project Journal line (Resource type only).';
                Editable = false;
            }
            field("Opti Opt. Skill"; Rec."Opti Skill")
            {
                ApplicationArea = All;
                Caption = 'Skill';
                ToolTip = 'Specifies the Skill linked to the originating Project Journal line.';
                Editable = false;
            }
            field("Opti Opt. Invoice Resource No."; Rec."Opti Invoice Resource No.")
            {
                ApplicationArea = All;
                Caption = 'Invoice Resource No.';
                ToolTip = 'Specifies the Invoice Resource No. linked to the originating Project Journal line.';
                Editable = false;
            }
            field("Opti Opt. Approved Project Manager"; Rec."Opti Approved Project Manager")
            {
                ApplicationArea = All;
                Caption = 'Approved Project Manager';
                ToolTip = 'Specifies the Approved Project Manager linked to the originating Project Journal line.';
                Editable = false;
            }
        }
    }
}
