codeunit 50618 "WO Item Price Calc."
{
    // Finds the best (lowest) unit price from "Work Order Item Pricing" for a given
    // Work Order Line, using the Order Date from the linked Order Intake Header as
    // the date reference — mirroring the native Sales Price best-price algorithm.

    procedure GetBestPrice(var WorkOrderLine: Record "Work Order Line")
    var
        WorkOrder: Record "Work Order";
        OrderIntake: Record "Order Intake Header Opt.";
        Customer: Record Customer;
        BestPrice: Decimal;
        PriceFound: Boolean;
        CustomerNo: Code[20];
        OrderDate: Date;
    begin
        if WorkOrderLine."Item No." = '' then
            exit;
        if WorkOrderLine."Work Order No." = '' then
            exit;

        // Walk the chain: Work Order Line -> Work Order -> Order Intake Header
        WorkOrder.Get(WorkOrderLine."Work Order No.");
        if WorkOrder."Order Intake No." = '' then
            exit;

        OrderIntake.Get(WorkOrder."Order Intake No.");
        OrderIntake.TestField("Order Date");   // Order Date is mandatory for pricing

        OrderDate := OrderIntake."Order Date";
        CustomerNo := OrderIntake."Customer No.";

        BestPrice := 0;
        PriceFound := false;

        // Priority 1 — Customer-specific price
        SearchPrices(
            WorkOrderLine."Item No.", WorkOrderLine.Quantity, OrderDate,
            "WO Item Price Sales Type"::Customer, CustomerNo,
            BestPrice, PriceFound);

        // Priority 2 — Customer Price Group price
        if Customer.Get(CustomerNo) and (Customer."Customer Price Group" <> '') then
            SearchPrices(
                WorkOrderLine."Item No.", WorkOrderLine.Quantity, OrderDate,
                "WO Item Price Sales Type"::"Customer Price Group",
                Customer."Customer Price Group",
                BestPrice, PriceFound);

        // Priority 3 — All Customers price
        SearchPrices(
            WorkOrderLine."Item No.", WorkOrderLine.Quantity, OrderDate,
            "WO Item Price Sales Type"::"All Customers", '',
            BestPrice, PriceFound);

        if PriceFound then
            WorkOrderLine."Item Price" := BestPrice;
    end;

    local procedure SearchPrices(
        ItemNo: Code[20];
        Quantity: Decimal;
        OrderDate: Date;
        SalesType: Enum "WO Item Price Sales Type";
        SalesCode: Code[20];
        var BestPrice: Decimal;
        var PriceFound: Boolean)
    var
        WOItemPricing: Record "Work Order Item Pricing";
    begin
        WOItemPricing.SetRange("Item No.", ItemNo);
        WOItemPricing.SetRange("Sales Type", SalesType);
        WOItemPricing.SetRange("Sales Code", SalesCode);
        WOItemPricing.SetFilter("Minimum Quantity", '<=%1', Quantity);
        // Starting Date = 0D (no start restriction) OR Starting Date <= OrderDate
        WOItemPricing.SetFilter("Starting Date", '<=%1|%2', OrderDate, 0D);
        // Ending Date = 0D (never expires) OR Ending Date >= OrderDate
        WOItemPricing.SetFilter("Ending Date", '>=%1|%2', OrderDate, 0D);

        if not WOItemPricing.FindSet() then
            exit;

        repeat
            if (not PriceFound) or (WOItemPricing."Unit Price" < BestPrice) then begin
                BestPrice := WOItemPricing."Unit Price";
                PriceFound := true;
            end;
        until WOItemPricing.Next() = 0;
    end;
}
