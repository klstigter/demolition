// API Integeration for Exposing API Pages
codeunit 50627 "API Record Exposed Triggers"
{
    // Table triggers are enabled only for tables registered in "API Record Exposed Opti".
    // The mask is cached per session, so changes to the setup apply to new sessions.

    [EventSubscriber(ObjectType::Codeunit, Codeunit::GlobalTriggerManagement, 'OnAfterGetGlobalTableTriggerMask', '', false, false)]
    [InherentPermissions(PermissionObjectType::TableData, Database::"API Record Exposed Opti", 'R')]
    local procedure EnableForRegisteredTables(TableID: Integer; var TableTriggerMask: Integer)
    var
        APIRecordExposed: Record "API Record Exposed Opti";
    begin
        APIRecordExposed.SetRange("Table ID", TableID);
        if not APIRecordExposed.IsEmpty() then
            // bits: 1=Insert, 2=Modify, 4=Delete, 8=Rename. Set 2+4+8, leave the Insert bit and higher bits as other subscribers set them.
            TableTriggerMask := (TableTriggerMask div 16) * 16 + 14 + (TableTriggerMask mod 2);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::GlobalTriggerManagement, 'OnAfterOnGlobalModify', '', false, false)]
    local procedure LogModify(RecRef: RecordRef; xRecRef: RecordRef)
    var
        APIRecordExposedMgt: Codeunit "API Record Exposed Mgt.";
    begin
        APIRecordExposedMgt.ModifiedFieldLog(xRecRef, RecRef, RecRef.Number());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::GlobalTriggerManagement, 'OnAfterOnGlobalDelete', '', false, false)]
    local procedure LogDelete(RecRef: RecordRef)
    var
        APIRecordExposedMgt: Codeunit "API Record Exposed Mgt.";
    begin
        APIRecordExposedMgt.DeletedRecordLog(RecRef);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::GlobalTriggerManagement, 'OnAfterOnGlobalRename', '', false, false)]
    local procedure LogRename(RecRef: RecordRef; xRecRef: RecordRef)
    var
        APIRecordExposedMgt: Codeunit "API Record Exposed Mgt.";
    begin
        APIRecordExposedMgt.RenamedRecordLog(RecRef, xRecRef);
    end;
}
