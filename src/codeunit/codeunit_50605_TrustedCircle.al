codeunit 50605 "API Record Exposed Mgt."
{
    trigger OnRun()
    begin
    end;

    var
        DailyOptimizerSetup: Record "Daily Optimizer Setup";

    local procedure GetApiFieldName(APIPageNo: Integer;
                                    TableNo: Integer;
                                    FieldNo: Integer;
                                    var ControlName: Text): Boolean
    var
        PageControlField: Record "Page Control Field";
    begin
        PageControlField.SetRange(PageNo, APIPageNo);
        PageControlField.SetRange(TableNo, TableNo);
        PageControlField.SetRange(FieldNo, FieldNo);
        if not PageControlField.FindFirst() then
            exit(false);
        ControlName := PageControlField.ControlName;
        exit(true);
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"API Record Exposed Opti", 'R')]
    [InherentPermissions(PermissionObjectType::TableData, Database::"Update and Delete Log Opti", 'RI')]
    procedure ModifiedFieldLog(OldRec: Variant;
                               NewRec: Variant;
                               TableID: Integer)
    var
        OldRecRef: RecordRef;
        NewRecRef: RecordRef;
        OldFldRef: FieldRef;
        NewFldRef: FieldRef;
        APIRecordExposed: Record "API Record Exposed Opti";
        PageMetadata: Record "Page Metadata";
        ControlName: Text;
        i: Integer;
    begin
        OldRecRef.GetTable(OldRec);
        NewRecRef.GetTable(NewRec);
        if NewRecRef.IsTemporary() then
            exit;

        APIRecordExposed.SetRange("Table ID", TableID);
        if APIRecordExposed.FindSet() then
            repeat
                // A missing API page must never fail the user's save; skip it.
                if PageMetadata.Get(APIRecordExposed."API Page No.") then
                    for i := 1 to NewRecRef.FieldCount() do begin
                        NewFldRef := NewRecRef.FieldIndex(i);
                        if NewFldRef.Class() = FieldClass::Normal then begin
                            OldFldRef := OldRecRef.Field(NewFldRef.Number());
                            if Format(OldFldRef.Value()) <> Format(NewFldRef.Value()) then
                                if GetApiFieldName(APIRecordExposed."API Page No.", TableID, NewFldRef.Number(), ControlName) then
                                    InsertLog(NewRecRef, PageMetadata.EntitySetName, ControlName, "Update and Delete Log Action"::Modify, NewFldRef.Number(), Format(OldFldRef.Value()), Format(NewFldRef.Value()));
                        end;
                    end;
            until APIRecordExposed.Next() = 0;
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"API Record Exposed Opti", 'R')]
    [InherentPermissions(PermissionObjectType::TableData, Database::"Update and Delete Log Opti", 'RI')]
    procedure DeletedRecordLog(RecRef: RecordRef)
    begin
        if RecRef.IsTemporary() then
            exit;
        LogRecordLevelChange(RecRef, "Update and Delete Log Action"::Delete, '', '');
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"API Record Exposed Opti", 'R')]
    [InherentPermissions(PermissionObjectType::TableData, Database::"Update and Delete Log Opti", 'RI')]
    procedure RenamedRecordLog(RecRef: RecordRef;
                               xRecRef: RecordRef)
    var
        APIRecordExposed: Record "API Record Exposed Opti";
        PageMetadata: Record "Page Metadata";
        KeyRef: KeyRef;
        FldRef: FieldRef;
        xFldRef: FieldRef;
        ControlName: Text;
        i: Integer;
    begin
        if RecRef.IsTemporary() then
            exit;

        // One row per primary-key field (a single-field key gives one row, a composite key gives n),
        // so every Rename row has the same shape: that field's API name (blank when not exposed),
        // its field number and its old/new value.
        KeyRef := RecRef.KeyIndex(1); // primary key
        APIRecordExposed.SetRange("Table ID", RecRef.Number());
        if APIRecordExposed.FindSet() then
            repeat
                if PageMetadata.Get(APIRecordExposed."API Page No.") then
                    for i := 1 to KeyRef.FieldCount() do begin
                        FldRef := KeyRef.FieldIndex(i);
                        xFldRef := xRecRef.Field(FldRef.Number());
                        if not GetApiFieldName(APIRecordExposed."API Page No.", RecRef.Number(), FldRef.Number(), ControlName) then
                            ControlName := '';
                        InsertLog(RecRef, PageMetadata.EntitySetName, ControlName, "Update and Delete Log Action"::Rename, FldRef.Number(), Format(xFldRef.Value()), Format(FldRef.Value()));
                    end;
            until APIRecordExposed.Next() = 0;
    end;

    local procedure LogRecordLevelChange(RecRef: RecordRef;
                                         LogAction: Enum "Update and Delete Log Action";
                                         OldValue: Text;
                                         NewValue: Text)
    var
        APIRecordExposed: Record "API Record Exposed Opti";
        PageMetadata: Record "Page Metadata";
    begin
        APIRecordExposed.SetRange("Table ID", RecRef.Number());
        if APIRecordExposed.FindSet() then
            repeat
                if PageMetadata.Get(APIRecordExposed."API Page No.") then
                    InsertLog(RecRef, PageMetadata.EntitySetName, '', LogAction, 0, OldValue, NewValue);
            until APIRecordExposed.Next() = 0;
    end;

    local procedure InsertLog(RecRef: RecordRef;
                              EntitySetName: Text;
                              FieldName: Text;
                              LogAction: Enum "Update and Delete Log Action";
                              FieldNo: Integer;
                              OldValue: Text;
                              NewValue: Text)
    var
        UpdateAndDeleteLog: Record "Update and Delete Log Opti";
    begin
        UpdateAndDeleteLog.Init();
        UpdateAndDeleteLog.Action := LogAction;
        UpdateAndDeleteLog."Record SystemId" := RecRef.Field(RecRef.SystemIdNo()).Value();
        UpdateAndDeleteLog.EntitySetName := CopyStr(EntitySetName, 1, MaxStrLen(UpdateAndDeleteLog.EntitySetName));
        UpdateAndDeleteLog."API Field Name" := CopyStr(FieldName, 1, MaxStrLen(UpdateAndDeleteLog."API Field Name"));
        UpdateAndDeleteLog."Table No." := RecRef.Number();
        UpdateAndDeleteLog."Field No." := FieldNo;
        UpdateAndDeleteLog."Old Value" := CopyStr(OldValue, 1, MaxStrLen(UpdateAndDeleteLog."Old Value"));
        UpdateAndDeleteLog."New Value" := CopyStr(NewValue, 1, MaxStrLen(UpdateAndDeleteLog."New Value"));
        UpdateAndDeleteLog."Modified At" := CurrentDateTime();
        UpdateAndDeleteLog.Status := UpdateAndDeleteLog.Status::Pending;
        UpdateAndDeleteLog.Insert();
    end;
}
