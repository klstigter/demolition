codeunit 50605 "API Record Exposed Mgt."
{
    trigger OnRun()
    begin
    end;

    var
        DailyOptimizerSetup: Record "Daily Optimizer Setup";

    local procedure IsFieldExposedOnApiPage(APIPageNo: Integer;
                                      TableNo: Integer;
                                      FieldNo: Integer): Boolean
    var
        PageControlField: Record "Page Control Field";
    begin
        PageControlField.SetRange(PageNo, APIPageNo);
        PageControlField.SetRange(TableNo, TableNo);
        PageControlField.SetRange(FieldNo, FieldNo);
        exit(not PageControlField.IsEmpty());
    end;

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
        UpdateAndDeleteLog: Record "Update and Delete Log Opti";
        i: Integer;
    begin
        OldRecRef.GetTable(OldRec);
        NewRecRef.GetTable(NewRec);

        APIRecordExposed.SetRange("Table ID", TableID);
        if APIRecordExposed.FindSet() then
            repeat
                PageMetadata.Get(APIRecordExposed."API Page No.");
                for i := 1 to NewRecRef.FieldCount() do begin
                    NewFldRef := NewRecRef.FieldIndex(i);
                    if NewFldRef.Class() = FieldClass::Normal then begin
                        OldFldRef := OldRecRef.Field(NewFldRef.Number());
                        if Format(OldFldRef.Value()) <> Format(NewFldRef.Value()) then
                            if IsFieldExposedOnApiPage(APIRecordExposed."API Page No.", TableID, NewFldRef.Number()) then begin
                                UpdateAndDeleteLog.Init();
                                UpdateAndDeleteLog."Entry No." := UpdateAndDeleteLog.GetNextEntryNo();
                                UpdateAndDeleteLog."Record SystemId" := NewRecRef.Field(NewRecRef.SystemIdNo()).Value();
                                UpdateAndDeleteLog.EntitySetName := CopyStr(PageMetadata.EntitySetName, 1, MaxStrLen(UpdateAndDeleteLog.EntitySetName));
                                UpdateAndDeleteLog."Table No." := TableID;
                                UpdateAndDeleteLog."Field No." := NewFldRef.Number();
                                UpdateAndDeleteLog."Old Value" := CopyStr(Format(OldFldRef.Value()), 1, MaxStrLen(UpdateAndDeleteLog."Old Value"));
                                UpdateAndDeleteLog."New Value" := CopyStr(Format(NewFldRef.Value()), 1, MaxStrLen(UpdateAndDeleteLog."New Value"));
                                UpdateAndDeleteLog."Modified At" := CurrentDateTime();
                                UpdateAndDeleteLog.Status := UpdateAndDeleteLog.Status::Pending;
                                UpdateAndDeleteLog.Insert();
                            end;
                    end;
                end;
            until APIRecordExposed.Next() = 0;
    end;
}
