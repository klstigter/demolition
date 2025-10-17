codeunit 50603 "DDSIAEventSubs"
{
    trigger OnRun()
    begin

    end;

    var
    //myInt: Integer;


    [EventSubscriber(ObjectType::Table, Database::Job, 'OnSellToCustomerNoUpdatedOnAfterTransferFieldsFromCust', '', false, false)]
    local procedure OnSellToCustomerNoUpdatedOnAfterTransferFieldsFromCust(var Job: Record Job; xJob: Record Job; SellToCustomer: Record Customer)
    begin
        // Reset back for Resource planning
        if xJob.Reserve = xJob.Reserve::"Resource Planning" then
            JOb.Reserve := xJob.Reserve;
    end;
}