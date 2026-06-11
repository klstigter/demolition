pageextension 50621 "Opt. Job Journal" extends "Job Journal"
{
    // Adds Day Planning Date and Day Planning Line No. to the Project Journal worksheet.
    // Both fields are only editable when Job No. and Job Task No. are filled.
    // Day Planning Line No. additionally requires Day Planning Date to be set first.
    //
    // Editable uses page-level Boolean vars (updated in OnAfterGetCurrRecord)
    // because AL does not allow inline record-field expressions in the Editable property
    // on repeater fields inside a page extension (runtime error: "Not a valid number").
    layout
    {
        addafter("Job Task No.")
        {
            field("Opt. DayPlanning Date"; Rec."Opt. DayPlanning Date")
            {
                ApplicationArea = All;
                Caption = 'Day Planning Date';
                ToolTip = 'Specifies the date of the Day Planning entry linked to this journal line. Requires Project No. and Project Task No. to be filled.';
                Editable = DayPlanningDateEditable;

                trigger OnValidate()
                begin
                    UpdateEditableVars();
                end;
            }
            field("Opt. DayPlanning Line No."; Rec."Opt. DayPlanning Line No.")
            {
                ApplicationArea = All;
                Caption = 'Day Planning Line No.';
                ToolTip = 'Specifies the line number of the Day Planning entry linked to this journal line. Requires Day Planning Date to be set.';
                Editable = DayPlanningLineNoEditable;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        UpdateEditableVars();
    end;

    local procedure UpdateEditableVars()
    begin
        DayPlanningDateEditable := (Rec."Job No." <> '') and (Rec."Job Task No." <> '');
        DayPlanningLineNoEditable := DayPlanningDateEditable and (Rec."Opt. DayPlanning Date" <> 0D);
    end;

    var
        DayPlanningDateEditable: Boolean;
        DayPlanningLineNoEditable: Boolean;
}

