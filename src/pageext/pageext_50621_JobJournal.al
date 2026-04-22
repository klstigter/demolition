pageextension 50621 "Opt. Job Journal" extends "Job Journal"
{
    // Adds Day Task Date and Day Task Line No. to the Project Journal worksheet.
    // Both fields are only editable when Job No. and Job Task No. are filled.
    // Day Task Line No. additionally requires Day Task Date to be set first.
    //
    // Editable uses page-level Boolean vars (updated in OnAfterGetCurrRecord)
    // because AL does not allow inline record-field expressions in the Editable property
    // on repeater fields inside a page extension (runtime error: "Not a valid number").
    layout
    {
        addafter("Job Task No.")
        {
            field("Opt. Daytask Date"; Rec."Opt. Daytask Date")
            {
                ApplicationArea = All;
                Caption = 'Day Task Date';
                ToolTip = 'Specifies the date of the Day Task entry linked to this journal line. Requires Project No. and Project Task No. to be filled.';
                Editable = DaytaskDateEditable;

                trigger OnValidate()
                begin
                    UpdateEditableVars();
                end;
            }
            field("Opt. Daytask Line No."; Rec."Opt. Daytask Line No.")
            {
                ApplicationArea = All;
                Caption = 'Day Task Line No.';
                ToolTip = 'Specifies the line number of the Day Task entry linked to this journal line. Requires Day Task Date to be set.';
                Editable = DaytaskLineNoEditable;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        UpdateEditableVars();
    end;

    local procedure UpdateEditableVars()
    begin
        DaytaskDateEditable := (Rec."Job No." <> '') and (Rec."Job Task No." <> '');
        DaytaskLineNoEditable := DaytaskDateEditable and (Rec."Opt. Daytask Date" <> 0D);
    end;

    var
        DaytaskDateEditable: Boolean;
        DaytaskLineNoEditable: Boolean;
}

