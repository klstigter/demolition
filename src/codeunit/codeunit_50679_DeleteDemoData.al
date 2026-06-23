codeunit 50679 "Delete Demo Data"
{
    trigger OnRun()
    var
        LogEntry: Record "Demo Data Log Entry";
        RecRef: RecordRef;
        ConfirmLbl: Label 'Delete %1 demo data records tracked in the log?\n\nOnly records created by "Create Demo Data" will be removed. User-created data is not affected.';
        NothingLbl: Label 'The demo data log is empty — nothing to delete.';
        DoneLbl: Label 'Done. %1 records deleted and log cleared.';
        EntryCount: Integer;
        Deleted: Integer;
    begin
        LogEntry.Reset();
        EntryCount := LogEntry.Count();
        if EntryCount = 0 then begin
            Message(NothingLbl);
            exit;
        end;

        if not Confirm(ConfirmLbl, false, EntryCount) then
            Error('');

        // Reverse order so child records are deleted before their parents (FK safety)
        if LogEntry.FindLast() then
            repeat
                RecRef.Open(LogEntry."Table ID");
                if RecRef.Get(LogEntry."Record ID") then begin
                    RecRef.Delete(false);
                    Deleted += 1;
                end;
                RecRef.Close();
            until LogEntry.Next(-1) = 0;

        LogEntry.DeleteAll();
        Message(DoneLbl, Deleted);
    end;
}
