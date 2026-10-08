page 50727 "UpdateAndDeleteLogApi Opt"
{
    PageType = API;
    Caption = 'Update and Delete Log API Optimization';
    APIPublisher = 'BC365Optimizer';
    APIGroup = 'Planning';
    APIVersion = 'v1.0';
    EntityName = 'UpdateAndDeleteLog';
    EntitySetName = 'UpdateAndDeleteLogs';
    SourceTable = "Update and Delete Log Opti";
    DelayedInsert = true;
    InsertAllowed = false;
    DeleteAllowed = false;
    ODataKeyFields = SystemId;

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                // id = this log row; systemId = SystemId of the record that was changed.
                field(id; Rec.SystemId)
                {
                    Caption = 'Id';
                    Editable = false;
                }
                field(systemId; Rec."Record SystemId")
                {
                    Caption = 'System Id';
                    Editable = false;
                }
                field(entryNo; Rec."Entry No.")
                {
                    Caption = 'Entry No.';
                    Editable = false;
                }
                field(action; Rec.Action)
                {
                    Caption = 'Action';
                    Editable = false;
                }
                field(entitySetName; Rec.EntitySetName)
                {
                    Caption = 'Entity Set Name';
                    Editable = false;
                }
                field(fieldName; Rec."API Field Name")
                {
                    Caption = 'Field Name';
                    Editable = false;
                }
                field(oldvalue; Rec."Old Value")
                {
                    Caption = 'Old Value';
                    Editable = false;
                }
                field(newvalue; Rec."New Value")
                {
                    Caption = 'New Value';
                    Editable = false;
                }
                field(update_at; Rec."Modified At")
                {
                    Caption = 'Updated At';
                    Editable = false;
                }
                field(date_time_sync; Rec."Synchronized At")
                {
                    Caption = 'Synchronized At';
                    Editable = false;
                }
                field(status; Rec.Status)
                {
                    Caption = 'Status';
                }
            }
        }
    }

    trigger OnModifyRecord(): Boolean
    begin
        // The only writable field is Status; keep Synchronized At in step with it.
        if Rec.Status <> xRec.Status then
            if Rec.Status = Rec.Status::Synchronized then
                Rec."Synchronized At" := CurrentDateTime()
            else
                Rec."Synchronized At" := 0DT;
        exit(true);
    end;
}
