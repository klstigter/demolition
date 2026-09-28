codeunit 50723 "Skip Temp Job Task Insert Opt."
{
    // Bound manually by API page 50674 around its temp Job Task insert, so the standard
    // Job Task.OnInsert (which writes real Job Task Dimension rows) does not run.
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Table, Database::"Job Task", 'OnBeforeOnInsert', '', false, false)]
    local procedure SkipOnInsertForTemp(var JobTask: Record "Job Task"; var IsHandled: Boolean)
    begin
        if JobTask.IsTemporary then
            IsHandled := true;
    end;
}
