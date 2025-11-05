codeunit 50603 "DDSIAEventSubs"
{
    trigger OnRun()
    begin

    end;

    var
    //myInt: Integer;


    // [EventSubscriber(ObjectType::Table, Database::Job, 'OnSellToCustomerNoUpdatedOnAfterTransferFieldsFromCust', '', false, false)]
    // local procedure OnSellToCustomerNoUpdatedOnAfterTransferFieldsFromCust(var Job: Record Job; xJob: Record Job; SellToCustomer: Record Customer)
    // begin
    //     // Reset back for Resource planning
    //     if xJob.Reserve = xJob.Reserve::"Resource Planning" then
    //         JOb.Reserve := xJob.Reserve;
    // end;

    // [EventSubscriber(ObjectType::Page, Page::"Job List", 'OnOpenPageEvent', '', false, false)]
    // local procedure Page_JobList_OnOpenPageEvent(var Rec: Record Job)
    // begin
    //     // Default page filtered on Job Task Type <> Resource Planning
    //     Rec.SetFilter("Job View Type", '<>%1', Rec."Job View Type"::"Resource");
    // end;
}