codeunit 50665 "DayPlanning Create Invoice"
{
    // Pure business logic — no UI calls. Called by Report 50666 "Day Planning Create Invoice".
    procedure CreateSalesInvoice(var DayPlanning: Record "Day Planning"): Integer
    var
        DayPlanningToUpdate: Record "Day Planning";
        Job: Record Job;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        LastJobNo: Code[20];
        LineNo: Integer;
        InvoiceCount: Integer;
        NoBillableLineErr: Label 'There are no posted day planning lines with a quantity to transfer to invoice.';
        NoBillToCustomerErr: Label 'Job %1 does not have a Bill-to Customer No.', Comment = '%1 = Job No.';
    begin
        DayPlanning.SetRange(Posted, true);
        DayPlanning.SetFilter("Qty. to Transfer to Invoice", '>0');
        if DayPlanning.IsEmpty() then
            Error(NoBillableLineErr);

        LastJobNo := '';
        InvoiceCount := 0;
        DayPlanning.FindSet();
        repeat
            if DayPlanning."Job No." <> LastJobNo then begin
                Job.Get(DayPlanning."Job No.");
                if Job."Bill-to Customer No." = '' then
                    Error(NoBillToCustomerErr, Job."No.");

                SalesHeader.Init();
                SalesHeader."Document Type" := SalesHeader."Document Type"::Invoice;
                SalesHeader.Validate("Sell-to Customer No.", Job."Bill-to Customer No.");
                SalesHeader.Insert(true);

                LineNo := 10000;
                LastJobNo := DayPlanning."Job No.";
                InvoiceCount += 1;
            end;

            SalesLine.Init();
            SalesLine."Document Type" := SalesHeader."Document Type";
            SalesLine."Document No." := SalesHeader."No.";
            SalesLine."Line No." := LineNo;
            SalesLine.Validate(Type, SalesLine.Type::Resource);
            SalesLine.Validate("No.", DayPlanning."Assigned Resource No.");
            if DayPlanning."Work Type Code" <> '' then
                SalesLine.Validate("Work Type Code", DayPlanning."Work Type Code");
            SalesLine.Validate(Quantity, DayPlanning."Qty. to Transfer to Invoice");
            SalesLine."Job No." := DayPlanning."Job No.";
            SalesLine."Job Task No." := DayPlanning."Job Task No.";
            SalesLine.Insert(true);
            LineNo += 10000;

            DayPlanningToUpdate.Get(DayPlanning."Job No.", DayPlanning."Job Task No.", DayPlanning."Day Line No.");
            DayPlanningToUpdate."Qty. Transferred to Invoice" += DayPlanningToUpdate."Qty. to Transfer to Invoice";
            DayPlanningToUpdate."Qty. to Transfer to Invoice" := 0;
            DayPlanningToUpdate."Invoice No." := SalesHeader."No.";
            DayPlanningToUpdate.Modify();

        until DayPlanning.Next() = 0;

        exit(InvoiceCount);
    end;
}
