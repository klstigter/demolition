codeunit 50603 "EventSubs"
{
    trigger OnRun()
    begin

    end;

    var

    [EventSubscriber(ObjectType::Table, Database::"Job Planning Line", 'OnAfterValidateEvent', "Planned Delivery Date", false, False)]
    local procedure Table_JobPlanningLine_OnAfterValidateEvent(var Rec: Record "Job Planning Line"; var xRec: Record "Job Planning Line")
    begin
        Rec."Start Planning Date" := xRec."Start Planning Date"; //reset back to original
    end;
}