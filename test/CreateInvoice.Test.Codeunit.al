codeunit 60023 "Create Invoice Tests"
{
    // Tests for:
    //   - Codeunit 50665 "DayPlanning Create Invoice"  (unit tests - pure logic)
    //   - Report    50666 "Day Planning Create Invoice" (integration test - batch report)
    Subtype = Test;
    TestPermissions = Disabled;

    var
        IsInitialized: Boolean;
        TestJobNo: Code[20];
        TestJobTaskNo: Code[20];
        TestResourceNo: Code[20];

    // ─── Shared setup ────────────────────────────────────────────────────────────

    local procedure Initialize()
    var
        Customer: Record Customer;
        Resource: Record Resource;
        Job: Record Job;
        JobTask: Record "Job Task";
    begin
        TestJobNo := 'DPCI-JOB';
        TestJobTaskNo := '1000';

        if IsInitialized then
            exit;

        // Use first available customer — inherits proper posting-group config from the company
        Customer.FindFirst();

        // Use first available resource — has Gen. Prod. Posting Group set
        Resource.FindFirst();
        TestResourceNo := Resource."No.";

        if not Job.Get(TestJobNo) then begin
            Job.Init();
            Job."No." := TestJobNo;
            Job.Description := 'Create Invoice Test Job';
            Job.Insert();
        end;
        Job.Validate("Bill-to Customer No.", Customer."No.");
        Job.Modify(true);

        if not JobTask.Get(TestJobNo, TestJobTaskNo) then begin
            JobTask.Init();
            JobTask."Job No." := TestJobNo;
            JobTask."Job Task No." := TestJobTaskNo;
            JobTask.Description := 'Create Invoice Test Task';
            JobTask."Job Task Type" := JobTask."Job Task Type"::Posting;
            JobTask.Insert();
        end;
        JobTask.PlannedStartDate := 0D;
        JobTask.PlannedEndDate := 0D;
        JobTask.Modify();

        IsInitialized := true;
        Commit();
    end;

    local procedure ClearTestDayPlannings(JobNo: Code[20]; JobTaskNo: Code[20])
    var
        DayPlanning: Record "Day Planning";
    begin
        // al_run_tests does not roll back data between test methods — explicit cleanup required
        DayPlanning.SetRange("Job No.", JobNo);
        DayPlanning.SetRange("Job Task No.", JobTaskNo);
        DayPlanning.DeleteAll();
    end;

    local procedure CreateTestDayPlanning(JobNo: Code[20]; JobTaskNo: Code[20]; ResourceNo: Code[20]; AssignedHours: Decimal; QtyToTransfer: Decimal; IsPosted: Boolean): Integer
    var
        DayPlanning: Record "Day Planning";
        DayLineNo: Integer;
    begin
        DayPlanning.SetRange("Job No.", JobNo);
        DayPlanning.SetRange("Job Task No.", JobTaskNo);
        if DayPlanning.FindLast() then
            DayLineNo := DayPlanning."Day Line No." + 10000
        else
            DayLineNo := 10000;

        DayPlanning.Init();
        DayPlanning."Job No." := JobNo;
        DayPlanning."Job Task No." := JobTaskNo;
        DayPlanning."Day Line No." := DayLineNo;
        DayPlanning."Task Date" := Today();
        DayPlanning."Assigned Resource No." := ResourceNo;
        DayPlanning."Assigned Hours" := AssignedHours;
        DayPlanning."Qty. to Transfer to Invoice" := QtyToTransfer;
        DayPlanning.Posted := IsPosted;
        DayPlanning.Insert();
        exit(DayLineNo);
    end;

    local procedure AssertAreEqual(Expected: Variant; Actual: Variant; ErrMsg: Text)
    var
        ExpectedText: Text;
        ActualText: Text;
    begin
        ExpectedText := Format(Expected);
        ActualText := Format(Actual);
        if ExpectedText <> ActualText then
            Error('%1 Expected: %2, Actual: %3', ErrMsg, ExpectedText, ActualText);
    end;

    local procedure AssertIsTrue(Condition: Boolean; ErrMsg: Text)
    begin
        if not Condition then
            Error(ErrMsg);
    end;

    local procedure AssertExpectedErrorContains(ExpectedText: Text)
    var
        ActualText: Text;
    begin
        ActualText := GetLastErrorText();
        if StrPos(ActualText, ExpectedText) = 0 then
            Error('Expected error containing: "%1", but got: "%2"', ExpectedText, ActualText);
    end;

    // ─── Unit tests: Codeunit 50665 ──────────────────────────────────────────────

    [Test]
    procedure CU_GivenPostedDayPlanning_WhenCreateSalesInvoice_ThenInvoiceCreatedAndFieldsUpdated()
    var
        DayPlanning: Record "Day Planning";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Job: Record Job;
        DayPlanningCreateInvoice: Codeunit "DayPlanning Create Invoice";
        DayLineNo: Integer;
        InvoiceCount: Integer;
    begin
        // [GIVEN] A posted Day Planning line with Assigned Hours = 8 and Qty. to Transfer to Invoice = 8
        Initialize();
        ClearTestDayPlannings(TestJobNo, TestJobTaskNo);
        DayLineNo := CreateTestDayPlanning(TestJobNo, TestJobTaskNo, TestResourceNo, 8, 8, true);
        Commit();

        // [WHEN] Codeunit CreateSalesInvoice is called
        DayPlanning.SetRange("Job No.", TestJobNo);
        DayPlanning.SetRange("Job Task No.", TestJobTaskNo);
        InvoiceCount := DayPlanningCreateInvoice.CreateSalesInvoice(DayPlanning);

        // [THEN] One invoice was created
        AssertAreEqual(1, InvoiceCount, 'CreateSalesInvoice should return invoice count = 1.');

        // [THEN] Day Planning Invoice No. is stamped — use it to look up the exact Sales Header
        DayPlanning.Get(TestJobNo, TestJobTaskNo, DayLineNo);
        AssertIsTrue(DayPlanning."Invoice No." <> '', 'Invoice No. should be set on Day Planning after invoicing.');

        Job.Get(TestJobNo);
        SalesHeader.Get(SalesHeader."Document Type"::Invoice, DayPlanning."Invoice No.");
        AssertAreEqual(Job."Bill-to Customer No.", SalesHeader."Sell-to Customer No.", 'Sales Invoice Sell-to Customer should match Job Bill-to Customer.');

        // [THEN] Sales Line has Type=Resource, correct No., and Qty = 8
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        AssertIsTrue(SalesLine.FindFirst(), 'Expected a Sales Invoice Line to be created.');
        AssertAreEqual(SalesLine.Type::Resource, SalesLine.Type, 'Sales Line Type should be Resource.');
        AssertAreEqual(TestResourceNo, SalesLine."No.", 'Sales Line No. should match the assigned resource.');
        AssertAreEqual(8, SalesLine.Quantity, 'Sales Line Quantity should equal Qty. to Transfer to Invoice (8).');

        // [THEN] Day Planning tracking fields updated correctly
        AssertAreEqual(8, DayPlanning."Qty. Transferred to Invoice", 'Qty. Transferred to Invoice should be 8 after invoicing.');
        AssertAreEqual(0, DayPlanning."Qty. to Transfer to Invoice", 'Qty. to Transfer to Invoice should be reset to 0 after invoicing.');
    end;

    [Test]
    procedure CU_GivenNotPostedDayPlanning_WhenCreateSalesInvoice_ThenNoBillableLinesError()
    var
        DayPlanning: Record "Day Planning";
        DayPlanningCreateInvoice: Codeunit "DayPlanning Create Invoice";
    begin
        // [GIVEN] A Day Planning line that is NOT posted
        Initialize();
        ClearTestDayPlannings(TestJobNo, TestJobTaskNo);
        CreateTestDayPlanning(TestJobNo, TestJobTaskNo, TestResourceNo, 8, 8, false);
        Commit();

        DayPlanning.SetRange("Job No.", TestJobNo);
        DayPlanning.SetRange("Job Task No.", TestJobTaskNo);

        // [WHEN/THEN] Error raised — line is not eligible
        asserterror DayPlanningCreateInvoice.CreateSalesInvoice(DayPlanning);
        AssertExpectedErrorContains('no posted day planning lines');
    end;

    [Test]
    procedure CU_GivenPostedLineWithQtyZero_WhenCreateSalesInvoice_ThenNoBillableLinesError()
    var
        DayPlanning: Record "Day Planning";
        DayPlanningCreateInvoice: Codeunit "DayPlanning Create Invoice";
    begin
        // [GIVEN] Posted Day Planning line but Qty. to Transfer to Invoice = 0 (already fully invoiced)
        Initialize();
        ClearTestDayPlannings(TestJobNo, TestJobTaskNo);
        CreateTestDayPlanning(TestJobNo, TestJobTaskNo, TestResourceNo, 8, 0, true);
        Commit();

        DayPlanning.SetRange("Job No.", TestJobNo);
        DayPlanning.SetRange("Job Task No.", TestJobTaskNo);

        // [WHEN/THEN] Error raised — nothing left to invoice
        asserterror DayPlanningCreateInvoice.CreateSalesInvoice(DayPlanning);
        AssertExpectedErrorContains('no posted day planning lines');
    end;

    [Test]
    procedure CU_GivenJobWithNoBillToCustomer_WhenCreateSalesInvoice_ThenBillToCustomerError()
    var
        DayPlanning: Record "Day Planning";
        Job: Record Job;
        JobTask: Record "Job Task";
        DayPlanningCreateInvoice: Codeunit "DayPlanning Create Invoice";
        NoBillToJobNo: Code[20];
        NoBillToJobTaskNo: Code[20];
    begin
        // [GIVEN] A posted Day Planning for a Job without a Bill-to Customer No.
        Initialize();
        NoBillToJobNo := 'DPCI-JOB2';
        NoBillToJobTaskNo := '1000';

        if not Job.Get(NoBillToJobNo) then begin
            Job.Init();
            Job."No." := NoBillToJobNo;
            Job.Description := 'Create Invoice Test Job (No Customer)';
            Job.Insert();
        end else begin
            Job."Bill-to Customer No." := '';
            Job.Modify();
        end;

        if not JobTask.Get(NoBillToJobNo, NoBillToJobTaskNo) then begin
            JobTask.Init();
            JobTask."Job No." := NoBillToJobNo;
            JobTask."Job Task No." := NoBillToJobTaskNo;
            JobTask."Job Task Type" := JobTask."Job Task Type"::Posting;
            JobTask.Insert();
        end;

        ClearTestDayPlannings(NoBillToJobNo, NoBillToJobTaskNo);
        CreateTestDayPlanning(NoBillToJobNo, NoBillToJobTaskNo, TestResourceNo, 8, 8, true);
        Commit();

        DayPlanning.SetRange("Job No.", NoBillToJobNo);
        DayPlanning.SetRange("Job Task No.", NoBillToJobTaskNo);

        // [WHEN/THEN] Error raised — Job has no Bill-to Customer
        asserterror DayPlanningCreateInvoice.CreateSalesInvoice(DayPlanning);
        AssertExpectedErrorContains('does not have a Bill-to Customer No.');
    end;

    // ─── Integration test: Report 50666 ──────────────────────────────────────────

    [Test]
    [HandlerFunctions('CreateInvoiceReportRequestPageHandler,CreateInvoiceMessageHandler')]
    procedure REP_GivenPostedDayPlanning_WhenRunReport_ThenInvoiceCreatedAndFieldsUpdated()
    var
        DayPlanning: Record "Day Planning";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Job: Record Job;
        DayLineNo: Integer;
    begin
        // [GIVEN] A posted Day Planning line with Qty. to Transfer to Invoice = 8
        Initialize();
        ClearTestDayPlannings(TestJobNo, TestJobTaskNo);
        DayLineNo := CreateTestDayPlanning(TestJobNo, TestJobTaskNo, TestResourceNo, 8, 8, true);
        Commit();

        // [WHEN] The batch report is run (request page auto-accepted by handler)
        DayPlanning.SetRange("Job No.", TestJobNo);
        DayPlanning.SetRange("Job Task No.", TestJobTaskNo);
        REPORT.RunModal(REPORT::"Day Planning Create Invoice", true, false, DayPlanning);

        // [THEN] Day Planning Invoice No. is stamped
        DayPlanning.Get(TestJobNo, TestJobTaskNo, DayLineNo);
        AssertIsTrue(DayPlanning."Invoice No." <> '', 'Invoice No. should be set on Day Planning after running the report.');

        // [THEN] Sales Invoice exists for the Job Bill-to Customer
        Job.Get(TestJobNo);
        SalesHeader.Get(SalesHeader."Document Type"::Invoice, DayPlanning."Invoice No.");
        AssertAreEqual(Job."Bill-to Customer No.", SalesHeader."Sell-to Customer No.", 'Report: Sales Invoice Sell-to should match Job Bill-to Customer.');

        // [THEN] Sales Line has correct resource and quantity
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        AssertIsTrue(SalesLine.FindFirst(), 'Report: Expected a Sales Invoice Line.');
        AssertAreEqual(SalesLine.Type::Resource, SalesLine.Type, 'Report: Sales Line Type should be Resource.');
        AssertAreEqual(TestResourceNo, SalesLine."No.", 'Report: Sales Line No. should match assigned resource.');
        AssertAreEqual(8, SalesLine.Quantity, 'Report: Sales Line Quantity should be 8.');

        // [THEN] Day Planning tracking fields updated
        AssertAreEqual(8, DayPlanning."Qty. Transferred to Invoice", 'Report: Qty. Transferred to Invoice should be 8.');
        AssertAreEqual(0, DayPlanning."Qty. to Transfer to Invoice", 'Report: Qty. to Transfer to Invoice should be 0.');
    end;

    // ─── Handlers ────────────────────────────────────────────────────────────────

    [RequestPageHandler]
    procedure CreateInvoiceReportRequestPageHandler(var RequestPage: TestRequestPage "Day Planning Create Invoice")
    begin
        // Accept defaults — no additional options to set on the request page
        RequestPage.OK().Invoke();
    end;

    [MessageHandler]
    procedure CreateInvoiceMessageHandler(Msg: Text[1024])
    begin
        // Dismiss the "X sales invoice(s) have been created." confirmation message
    end;
}
