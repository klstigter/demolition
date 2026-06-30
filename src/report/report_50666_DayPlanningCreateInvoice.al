report 50666 "Day Planning Create Invoice"
{
    Caption = 'Day Planning Transfer to Sales Invoice';
    ProcessingOnly = true;
    UsageCategory = None;
    ApplicationArea = Jobs;

    dataset
    {
        dataitem(DayPlanning; "Day Planning")
        {
            RequestFilterFields = "Job No.", "Job Task No.", "Task Date", "Assigned Resource No.";
            DataItemTableView = where(Posted = const(true));

            trigger OnPreDataItem()
            begin
                DayPlanning.SetFilter("Qty. to Transfer to Invoice", '>0');
                if DayPlanning.IsEmpty() then
                    Error(NoBillableLineErr);

                LastJobNo := '';
                HeadersCreated := 0;
                LinesAppended := 0;

                if not CreateNewInvoice then begin
                    if AppendToInvoiceNo = '' then
                        Error(AppendInvoiceNoMissingErr);
                    if not AppendSalesHeader.Get(AppendSalesHeader."Document Type"::Invoice, AppendToInvoiceNo) then
                        Error(InvoiceNotFoundErr, AppendToInvoiceNo);
                    CurrentSalesHeader := AppendSalesHeader;
                    CurrentLineNo := GetNextSalesLineNo(CurrentSalesHeader);
                end;
            end;

            trigger OnAfterGetRecord()
            var
                Job: Record Job;
            begin
                if CreateNewInvoice then begin
                    if DayPlanning."Job No." <> LastJobNo then begin
                        Job.Get(DayPlanning."Job No.");
                        if Job."Bill-to Customer No." = '' then
                            Error(NoBillToCustomerErr, Job."No.");

                        CurrentSalesHeader.Init();
                        CurrentSalesHeader."Document Type" := CurrentSalesHeader."Document Type"::Invoice;
                        CurrentSalesHeader.Validate("Sell-to Customer No.", Job."Bill-to Customer No.");
                        if PostingDate <> 0D then
                            CurrentSalesHeader.Validate("Posting Date", PostingDate);
                        if DocumentDate <> 0D then
                            CurrentSalesHeader."Document Date" := DocumentDate;
                        CurrentSalesHeader.Insert(true);

                        CurrentLineNo := 10000;
                        LastJobNo := DayPlanning."Job No.";
                        HeadersCreated += 1;
                    end;
                end;

                CreateSalesLine();
                UpdateDayPlanning();
            end;

            trigger OnPostDataItem()
            begin
                if CreateNewInvoice then
                    Message(InvoicesCreatedMsg, HeadersCreated)
                else
                    Message(LinesAppendedMsg, LinesAppended, AppendToInvoiceNo);
            end;
        }
    }

    requestpage
    {
        Caption = 'Day Planning Transfer to Sales Invoice';

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';

                    field(CreateNewInvoiceField; CreateNewInvoice)
                    {
                        ApplicationArea = All;
                        Caption = 'Create New Invoice';
                        ToolTip = 'Enable to create a new sales invoice. Disable to append lines to an existing unposted invoice.';

                        trigger OnValidate()
                        begin
                            AppendToInvoiceNo := '';
                            InvoicePostingDate := 0D;
                        end;
                    }
                    field(PostingDateField; PostingDate)
                    {
                        ApplicationArea = All;
                        Caption = 'Posting Date';
                        ToolTip = 'Specifies the posting date for the new sales invoice.';
                        Editable = CreateNewInvoice;
                    }
                    field(DocumentDateField; DocumentDate)
                    {
                        ApplicationArea = All;
                        Caption = 'Document Date';
                        ToolTip = 'Specifies the document date for the new sales invoice.';
                        Editable = CreateNewInvoice;
                    }
                    field(AppendToInvoiceNoField; AppendToInvoiceNo)
                    {
                        ApplicationArea = All;
                        Caption = 'Append to Sales Invoice No.';
                        ToolTip = 'Specifies an existing unposted sales invoice to append lines to. Only used when Create New Invoice is disabled.';
                        Editable = not CreateNewInvoice;
                        TableRelation = "Sales Header"."No." where("Document Type" = const(Invoice));

                        trigger OnValidate()
                        var
                            SalesHeader: Record "Sales Header";
                        begin
                            if (AppendToInvoiceNo <> '') and
                               SalesHeader.Get(SalesHeader."Document Type"::Invoice, AppendToInvoiceNo)
                            then
                                InvoicePostingDate := SalesHeader."Posting Date"
                            else
                                InvoicePostingDate := 0D;
                        end;
                    }
                    field(InvoicePostingDateField; InvoicePostingDate)
                    {
                        ApplicationArea = All;
                        Caption = 'Invoice Posting Date';
                        ToolTip = 'Shows the posting date of the selected existing invoice (read-only).';
                        Editable = false;
                    }
                }
            }
        }

        trigger OnOpenPage()
        begin
            CreateNewInvoice := true;
            PostingDate := WorkDate();
            DocumentDate := WorkDate();
        end;
    }

    var
        AppendSalesHeader: Record "Sales Header";
        CurrentSalesHeader: Record "Sales Header";
        CreateNewInvoice: Boolean;
        PostingDate: Date;
        DocumentDate: Date;
        AppendToInvoiceNo: Code[20];
        InvoicePostingDate: Date;
        LastJobNo: Code[20];
        HeadersCreated: Integer;
        LinesAppended: Integer;
        CurrentLineNo: Integer;
        NoBillableLineErr: Label 'There are no posted day planning lines with a quantity to transfer to invoice.';
        NoBillToCustomerErr: Label 'Job %1 does not have a Bill-to Customer No.', Comment = '%1 = Job No.';
        AppendInvoiceNoMissingErr: Label 'Append to Sales Invoice No. must be filled when Create New Invoice is disabled.';
        InvoiceNotFoundErr: Label 'Sales Invoice %1 does not exist.', Comment = '%1 = Invoice No.';
        InvoicesCreatedMsg: Label '%1 sales invoice(s) have been created.', Comment = '%1 = count';
        LinesAppendedMsg: Label '%1 line(s) appended to Sales Invoice %2.', Comment = '%1 = lines, %2 = invoice no.';

    local procedure CreateSalesLine()
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.Init();
        SalesLine."Document Type" := CurrentSalesHeader."Document Type";
        SalesLine."Document No." := CurrentSalesHeader."No.";
        SalesLine."Line No." := CurrentLineNo;
        SalesLine.Validate(Type, SalesLine.Type::Resource);
        SalesLine.Validate("No.", DayPlanning."Assigned Resource No.");
        if DayPlanning."Work Type Code" <> '' then
            SalesLine.Validate("Work Type Code", DayPlanning."Work Type Code");
        SalesLine.Validate(Quantity, DayPlanning."Qty. to Transfer to Invoice");
        SalesLine."Job No." := DayPlanning."Job No.";
        SalesLine."Job Task No." := DayPlanning."Job Task No.";
        SalesLine."Day Planning Line No." := DayPlanning."Day Line No.";
        SalesLine.Insert(true);
        CurrentLineNo += 10000;
        LinesAppended += 1;
    end;

    local procedure UpdateDayPlanning()
    begin
        DayPlanning."Qty. Transferred to Invoice" += DayPlanning."Qty. to Transfer to Invoice";
        DayPlanning."Qty. to Transfer to Invoice" := 0;
        DayPlanning."Invoice No." := CurrentSalesHeader."No.";
        DayPlanning.Modify();
    end;

    local procedure GetNextSalesLineNo(SalesHeader: Record "Sales Header"): Integer
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        if SalesLine.FindLast() then
            exit(SalesLine."Line No." + 10000);
        exit(10000);
    end;
}
