codeunit 50679 "Delete Demo Data"
{
    trigger OnRun()
    var
        LogEntry: Record "Demo Data Log Entry";
        RecRef: RecordRef;
        Window: Dialog;
        ConfirmLbl: Label 'Delete %1 demo data records tracked in the log?\n\nOnly records created by "Create Demo Data" will be removed. User-created data is not affected.';
        NothingLbl: Label 'The demo data log is empty — nothing to delete.';
        DoneLbl: Label 'Done. %1 records deleted and log cleared.';
        ProgressLbl: Label 'Deleting demo data...\n#1########## of #2##########';
        EntryCount: Integer;
        Processed: Integer;
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

        if GuiAllowed() then
            Window.Open(ProgressLbl);

        // Reverse order so child records are deleted before their parents (FK safety)
        if LogEntry.FindLast() then
            repeat
                RecRef.Open(LogEntry."Table ID");
                if RecRef.Get(LogEntry."Record ID") then begin
                    RecRef.Delete(false);
                    Deleted += 1;
                end;
                RecRef.Close();
                Processed += 1;
                if GuiAllowed() and (Processed mod 200 = 0) then begin
                    Window.Update(1, Processed);
                    Window.Update(2, EntryCount);
                end;
                // Commit periodically so a large demo data set doesn't hold one long-running
                // transaction/lock for the whole delete.
                if Processed mod 1000 = 0 then
                    Commit();
            until LogEntry.Next(-1) = 0;

        if GuiAllowed() then
            Window.Close();

        LogEntry.DeleteAll();
        Message(DoneLbl, Deleted);
    end;
}
