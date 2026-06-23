page 50677 "Demo Data Log"
{
    Caption = 'Demo Data Log';
    PageType = List;
    SourceTable = "Demo Data Log Entry";
    ApplicationArea = All;
    UsageCategory = Lists;
    Editable = false;
    DeleteAllowed = true;
    InsertAllowed = false;
    ModifyAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Log entry sequence number.';
                }
                field("Table ID"; Rec."Table ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'ID of the table the record belongs to.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Short description of the created record.';
                }
                field("Created At"; Rec."Created At")
                {
                    ApplicationArea = All;
                    ToolTip = 'When this record was created by the demo data run.';
                }
                field("Record ID"; Rec."Record ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'The unique record identifier used to locate and delete the record.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ClearLog)
            {
                Caption = 'Clear Log';
                Image = Delete;
                ApplicationArea = All;
                ToolTip = 'Remove all entries from the log without deleting the actual demo data records.';
                trigger OnAction()
                var
                    LogEntry: Record "Demo Data Log Entry";
                    ConfirmLbl: Label 'Clear the log? This only removes log entries — it does NOT delete the demo data itself. To delete demo data, use the Delete Demo Data action.';
                begin
                    if Confirm(ConfirmLbl, false) then begin
                        LogEntry.DeleteAll();
                        CurrPage.Update(false);
                    end;
                end;
            }
        }
        area(Promoted)
        {
            actionref(ClearLog_Promoted; ClearLog) { }
        }
    }
}
