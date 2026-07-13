report 50667 "Day Planning Create Cr. Memo"
{
    Caption = 'Day Planning Transfer to Sales Credit Memo';
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
                DayPlanning.SetFilter("Realized Hours", '>0');
                if DayPlanning.IsEmpty() then
                    Error(NoCreditableLineErr);

                LastJobNo := '';
                HeadersCreated := 0;
                LinesAppended := 0;

                if not CreateNewCreditMemo then begin
                    if AppendToCreditMemoNo = '' then
                        Error(AppendCrMemoNoMissingErr);
                    if not AppendSalesHeader.Get(AppendSalesHeader."Document Type"::"Credit Memo", AppendToCreditMemoNo) then
                        Error(CrMemoNotFoundErr, AppendToCreditMemoNo);
                    CurrentSalesHeader := AppendSalesHeader;
                    CurrentLineNo := GetNextSalesLineNo(CurrentSalesHeader);
                end;
            end;

            trigger OnAfterGetRecord()
            var
                Job: Record Job;
            begin
                if CreateNewCreditMemo then begin
                    if DayPlanning."Job No." <> LastJobNo then begin
                        Job.Get(DayPlanning."Job No.");
                        if Job."Bill-to Customer No." = '' then
                            Error(NoBillToCustomerErr, Job."No.");

                        CurrentSalesHeader.Init();
                        CurrentSalesHeader."Document Type" := CurrentSalesHeader."Document Type"::"Credit Memo";
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

                if not DayPlanning.CanCreateSalesCreditMemo() then
                    CurrReport.Skip();

                CreateCreditMemoLine();
            end;

            trigger OnPostDataItem()
            begin
                if CreateNewCreditMemo then
                    Message(CrMemosCreatedMsg, HeadersCreated)
                else
                    Message(LinesAppendedMsg, LinesAppended, AppendToCreditMemoNo);
            end;
        }
    }

    requestpage
    {
        Caption = 'Day Planning Transfer to Sales Credit Memo';

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';

                    field(CreateNewCreditMemoField; CreateNewCreditMemo)
                    {
                        ApplicationArea = All;
                        Caption = 'Create New Credit Memo';
                        ToolTip = 'Enable to create a new sales credit memo. Disable to append lines to an existing unposted credit memo.';

                        trigger OnValidate()
                        begin
                            AppendToCreditMemoNo := '';
                            CrMemoPostingDate := 0D;
                        end;
                    }
                    field(PostingDateField; PostingDate)
                    {
                        ApplicationArea = All;
                        Caption = 'Posting Date';
                        ToolTip = 'Specifies the posting date for the new sales credit memo.';
                        Editable = CreateNewCreditMemo;
                    }
                    field(DocumentDateField; DocumentDate)
                    {
                        ApplicationArea = All;
                        Caption = 'Document Date';
                        ToolTip = 'Specifies the document date for the new sales credit memo.';
                        Editable = CreateNewCreditMemo;
                    }
                    field(AppendToCreditMemoNoField; AppendToCreditMemoNo)
                    {
                        ApplicationArea = All;
                        Caption = 'Append to Credit Memo No.';
                        ToolTip = 'Specifies an existing unposted sales credit memo to append lines to.';
                        Editable = not CreateNewCreditMemo;
                        TableRelation = "Sales Header"."No." where("Document Type" = const("Credit Memo"));

                        trigger OnValidate()
                        var
                            SalesHeader: Record "Sales Header";
                        begin
                            if (AppendToCreditMemoNo <> '') and
                               SalesHeader.Get(SalesHeader."Document Type"::"Credit Memo", AppendToCreditMemoNo)
                            then
                                CrMemoPostingDate := SalesHeader."Posting Date"
                            else
                                CrMemoPostingDate := 0D;
                        end;
                    }
                    field(CrMemoPostingDateField; CrMemoPostingDate)
                    {
                        ApplicationArea = All;
                        Caption = 'Credit Memo Posting Date';
                        ToolTip = 'Shows the posting date of the selected existing credit memo (read-only).';
                        Editable = false;
                    }
                }
            }
        }

        trigger OnOpenPage()
        begin
            CreateNewCreditMemo := true;
            PostingDate := WorkDate();
            DocumentDate := WorkDate();
        end;
    }

    var
        AppendSalesHeader: Record "Sales Header";
        CurrentSalesHeader: Record "Sales Header";
        CreateNewCreditMemo: Boolean;
        PostingDate: Date;
        DocumentDate: Date;
        AppendToCreditMemoNo: Code[20];
        CrMemoPostingDate: Date;
        LastJobNo: Code[20];
        HeadersCreated: Integer;
        LinesAppended: Integer;
        CurrentLineNo: Integer;
        NoCreditableLineErr: Label 'There are no posted day planning lines with an invoiced quantity to credit.';
        NoBillToCustomerErr: Label 'Job %1 does not have a Bill-to Customer No.', Comment = '%1 = Job No.';
        AppendCrMemoNoMissingErr: Label 'Append to Credit Memo No. must be filled when Create New Credit Memo is disabled.';
        CrMemoNotFoundErr: Label 'Sales Credit Memo %1 does not exist.', Comment = '%1 = Credit Memo No.';
        CrMemosCreatedMsg: Label '%1 sales credit memo(s) have been created.', Comment = '%1 = count';
        LinesAppendedMsg: Label '%1 line(s) appended to Sales Credit Memo %2.', Comment = '%1 = lines, %2 = credit memo no.';

    local procedure CreateCreditMemoLine()
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
        SalesLine.Validate(Quantity, DayPlanning."Qty. Invoiced" - DayPlanning."Qty. Credited");
        SalesLine."Job No." := DayPlanning."Job No.";
        SalesLine."Job Task No." := DayPlanning."Job Task No.";
        SalesLine."Day Planning Line No." := DayPlanning."Day Line No.";
        SalesLine.Insert(true);
        CurrentLineNo += 10000;
        LinesAppended += 1;
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
