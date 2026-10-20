// API Integeration for Exposing API Pages
codeunit 50627 "API Record Exposed Triggers"
{
    // Table triggers are enabled only for tables registered in "API Record Exposed Opti".
    // The setup is cached per session, so changes to the setup apply to new sessions.
    // Modify and Delete use the database-level trigger events (the global-mask Modify/Delete events do not fire);
    // Rename keeps the global event, which does fire.
    SingleInstance = true;

    var
        OldRecRef: RecordRef;
        OldTableNo: Integer;
        OldSystemId: Guid;

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

    // Insert and Rename stay off here: inserts are never logged and Rename is logged through the global event.
    [EventSubscriber(ObjectType::Codeunit, Codeunit::GlobalTriggerManagement, 'OnAfterGetDatabaseTableTriggerSetup', '', false, false)]
    [InherentPermissions(PermissionObjectType::TableData, Database::"API Record Exposed Opti", 'R')]
    local procedure EnableDatabaseTriggers(TableId: Integer; var OnDatabaseInsert: Boolean; var OnDatabaseModify: Boolean; var OnDatabaseDelete: Boolean; var OnDatabaseRename: Boolean)
    var
        APIRecordExposed: Record "API Record Exposed Opti";
    begin
        APIRecordExposed.SetRange("Table ID", TableId);
        if not APIRecordExposed.IsEmpty() then begin
            OnDatabaseModify := true;
            OnDatabaseDelete := true;
        end;
    end;

    // The after-modify event has no xRec, so keep the stored version before it is overwritten.
    [EventSubscriber(ObjectType::Codeunit, Codeunit::GlobalTriggerManagement, 'OnBeforeOnDatabaseModify', '', false, false)]
    local procedure CaptureOldRecord(RecRef: RecordRef)
    begin
        Clear(OldTableNo);
        Clear(OldSystemId);
        if IsThirdPartyCall() then
            exit;
        if ReadOldRecord(RecRef) then begin
            OldTableNo := RecRef.Number();
            OldSystemId := RecRef.Field(RecRef.SystemIdNo()).Value();
        end;
    end;

    [TryFunction]
    local procedure ReadOldRecord(RecRef: RecordRef)
    begin
        if OldRecRef.Number() <> 0 then
            OldRecRef.Close();
        OldRecRef.Open(RecRef.Number());
        OldRecRef.Get(RecRef.RecordId());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::GlobalTriggerManagement, 'OnAfterOnDatabaseModify', '', false, false)]
    local procedure LogModify(RecRef: RecordRef)
    var
        APIRecordExposedMgt: Codeunit "API Record Exposed Mgt.";
        SystemId: Guid;
    begin
        if IsThirdPartyCall() then
            exit;
        SystemId := RecRef.Field(RecRef.SystemIdNo()).Value();
        // only log when the stored old record belongs to this exact record
        if (OldTableNo <> RecRef.Number()) or (OldSystemId <> SystemId) then
            exit;
        Clear(OldTableNo);
        Clear(OldSystemId);
        APIRecordExposedMgt.ModifiedFieldLog(OldRecRef, RecRef, RecRef.Number());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::GlobalTriggerManagement, 'OnAfterOnDatabaseDelete', '', false, false)]
    local procedure LogDelete(RecRef: RecordRef)
    var
        APIRecordExposedMgt: Codeunit "API Record Exposed Mgt.";
    begin
        if IsThirdPartyCall() then
            exit;
        APIRecordExposedMgt.DeletedRecordLog(RecRef);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::GlobalTriggerManagement, 'OnAfterOnGlobalRename', '', false, false)]
    local procedure LogRename(RecRef: RecordRef; xRecRef: RecordRef)
    var
        APIRecordExposedMgt: Codeunit "API Record Exposed Mgt.";
    begin
        if IsThirdPartyCall() then
            exit;
        APIRecordExposedMgt.RenamedRecordLog(RecRef, xRecRef);
    end;

    // Modify/delete/rename made through the API/OData/SOAP endpoints come from the third party itself, so it already has them.
    local procedure IsThirdPartyCall(): Boolean
    begin
        exit(CurrentClientType() in [ClientType::Api, ClientType::ODataV4, ClientType::SOAP]);
    end;
}
