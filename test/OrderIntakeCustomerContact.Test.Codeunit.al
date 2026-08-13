codeunit 60025 "OI Customer/Contact Tests"
{
    // Tests for table 50604 "Order Intake Header Opt." - the Customer No./Contact No. auto-resolution
    // and cross-validation logic added this session:
    //   - field(20) "Customer No." OnValidate: populates Customer Name / Contact No. from the
    //     selected Customer's "Primary Contact No.", clears both on blank, and guards REPLACEMENT
    //     of an already-set customer via CheckCanChangeCustomer() - but NOT the first-ever
    //     assignment from blank.
    //   - field(26) "Contact No." OnValidate: resolves the Contact's owning Customer via
    //     "Contact Business Relation" (matching on the Person's "Company No." or, for a Company
    //     contact, its own "No.") and pushes the result back into "Customer No."/"Customer Name",
    //     also guarded by CheckCanChangeCustomer() when replacing an existing customer.
    //   - local procedure CheckCanChangeCustomer(): errors if a "Work Order" tied to this Order
    //     Intake (by "Order Intake No.") has related "Day Planning" or "Job Planning Line" rows.
    Subtype = Test;
    TestPermissions = Disabled;

    var
        IsInitialized: Boolean;
        TestCustomerNoA: Code[20];
        TestCustomerNoB: Code[20];
        TestCustomerNoC: Code[20];
        TestCompanyContactNoA: Code[20];
        TestCompanyContactNoB: Code[20];
        TestCompanyContactNoOrphan: Code[20];
        TestPersonContactNoA: Code[20];
        TestPersonContactNoB: Code[20];
        TestPersonContactNoOrphan: Code[20];

    local procedure Initialize()
    begin
        TestCustomerNoA := 'OICTCUSA';
        TestCustomerNoB := 'OICTCUSB';
        TestCustomerNoC := 'OICTCUSC';
        TestCompanyContactNoA := 'OICTCOA';
        TestCompanyContactNoB := 'OICTCOB';
        TestCompanyContactNoOrphan := 'OICTCOO';
        TestPersonContactNoA := 'OICTPERA';
        TestPersonContactNoB := 'OICTPERB';
        TestPersonContactNoOrphan := 'OICTPERO';

        if IsInitialized then
            exit;

        // [GIVEN] Two customers that will each resolve from a Person Contact via a real
        // Contact Business Relation, plus a third Customer used only for the "no Primary
        // Contact" / "clear back to blank" scenarios.
        CreateTestCustomer(TestCustomerNoA, 'OICT Customer A');
        CreateTestCustomer(TestCustomerNoB, 'OICT Customer B');
        CreateTestCustomer(TestCustomerNoC, 'OICT Customer C');

        // [GIVEN] Company Contacts - two properly linked to a Customer via Contact Business
        // Relation, one deliberately left WITHOUT a relation (the "orphan" scenario for test 6).
        CreateCompanyContact(TestCompanyContactNoA, 'OICT Company A');
        CreateCompanyContact(TestCompanyContactNoB, 'OICT Company B');
        CreateCompanyContact(TestCompanyContactNoOrphan, 'OICT Company Orphan');

        // [GIVEN] One Person Contact under each Company Contact.
        CreatePersonContact(TestPersonContactNoA, 'OICT Person A', TestCompanyContactNoA);
        CreatePersonContact(TestPersonContactNoB, 'OICT Person B', TestCompanyContactNoB);
        CreatePersonContact(TestPersonContactNoOrphan, 'OICT Person Orphan', TestCompanyContactNoOrphan);

        CreateContactBusinessRelation(TestCompanyContactNoA, TestCustomerNoA);
        CreateContactBusinessRelation(TestCompanyContactNoB, TestCustomerNoB);
        // TestCompanyContactNoOrphan intentionally gets NO Contact Business Relation row.

        // [GIVEN] Customer A has a Primary Contact (Person A); Customer B/C deliberately don't.
        SetCustomerPrimaryContact(TestCustomerNoA, TestPersonContactNoA);

        IsInitialized := true;
        Commit();
    end;

    local procedure CreateTestCustomer(CustNo: Code[20]; CustName: Text[100])
    var
        Customer: Record Customer;
    begin
        if not Customer.Get(CustNo) then begin
            Customer.Init();
            Customer."No." := CustNo;
            Customer.Insert();
        end;
        Customer.Name := CustName;
        Customer.Modify();
    end;

    local procedure SetCustomerPrimaryContact(CustNo: Code[20]; ContactNo: Code[20])
    var
        Customer: Record Customer;
    begin
        Customer.Get(CustNo);
        Customer."Primary Contact No." := ContactNo;
        Customer.Modify();
    end;

    local procedure CreateCompanyContact(ContactNo: Code[20]; ContactName: Text[100])
    var
        Cont: Record Contact;
    begin
        if Cont.Get(ContactNo) then
            exit;
        Cont.Init();
        Cont."No." := ContactNo;
        Cont.Type := Cont.Type::Company;
        Cont.Name := ContactName;
        Cont.Insert();
    end;

    local procedure CreatePersonContact(ContactNo: Code[20]; ContactName: Text[100]; CompanyContactNo: Code[20])
    var
        Cont: Record Contact;
    begin
        if Cont.Get(ContactNo) then
            exit;
        Cont.Init();
        Cont."No." := ContactNo;
        Cont.Type := Cont.Type::Person;
        Cont.Name := ContactName;
        Cont."Company No." := CompanyContactNo;
        Cont.Insert();
    end;

    /// <summary>
    /// Idempotent create/update of the "Contact Business Relation" row that makes
    /// CompanyContactNo resolve to CustNo (via "Link to Table" = Customer). Uses SetRange +
    /// FindFirst (not Get) since the exact composite-key signature isn't relied upon here - this
    /// mirrors the same lookup idiom table_50604's own "Contact No." OnValidate trigger uses.
    /// </summary>
    local procedure CreateContactBusinessRelation(CompanyContactNo: Code[20]; CustNo: Code[20])
    var
        ContBusRel: Record "Contact Business Relation";
    begin
        ContBusRel.SetRange("Contact No.", CompanyContactNo);
        ContBusRel.SetRange("Link to Table", ContBusRel."Link to Table"::Customer);
        if ContBusRel.FindFirst() then begin
            ContBusRel."No." := CustNo;
            ContBusRel.Modify();
            exit;
        end;
        ContBusRel.Init();
        ContBusRel."Contact No." := CompanyContactNo;
        ContBusRel."Link to Table" := ContBusRel."Link to Table"::Customer;
        ContBusRel."No." := CustNo;
        ContBusRel.Insert();
    end;

    /// <summary>
    /// Builds a "Work Order" (Order Intake No. = OrderIntakeNo) plus one "Day Planning" line tied
    /// to it via "Work Order No." - the minimum data CheckCanChangeCustomer's guard needs to find
    /// via its SetRange("Work Order No.", ...)/IsEmpty() check. No real Job/Job Task is needed
    /// since both rows are built via direct field assignment + untriggered Insert().
    /// </summary>
    local procedure CreateWorkOrderWithDayPlanning(OrderIntakeNo: Code[20]; WorkOrderNo: Code[20])
    var
        WorkOrder: Record "Work Order";
        DayPlanning: Record "Day Planning";
    begin
        ClearWorkOrderAndDayPlanning(WorkOrderNo);

        WorkOrder.Init();
        WorkOrder."Work Order No." := WorkOrderNo;
        WorkOrder."Order Intake No." := OrderIntakeNo;
        WorkOrder.Insert();

        DayPlanning.Init();
        DayPlanning."Job No." := WorkOrderNo;
        DayPlanning."Job Task No." := '1000';
        DayPlanning."Day Line No." := 10000;
        DayPlanning."Work Order No." := WorkOrderNo;
        DayPlanning.Insert();
    end;

    /// <summary>
    /// DeleteAll(false)/Delete(false) skip both tables' triggers deliberately - Day Planning's
    /// OnDelete TestFields "Assigned Hours"/"Realized Hours" = 0 (harmless here, both are blank),
    /// and Work Order's OnDelete otherwise cascades deletes we don't need since this helper already
    /// owns cleanup of both rows. Lets al_run_tests reruns stay idempotent (no PK collisions).
    /// </summary>
    local procedure ClearWorkOrderAndDayPlanning(WorkOrderNo: Code[20])
    var
        WorkOrder: Record "Work Order";
        DayPlanning: Record "Day Planning";
    begin
        DayPlanning.SetRange("Work Order No.", WorkOrderNo);
        DayPlanning.DeleteAll(false);
        if WorkOrder.Get(WorkOrderNo) then
            WorkOrder.Delete(false);
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

    local procedure AssertExpectedErrorContains(ExpectedText: Text)
    var
        ActualText: Text;
    begin
        ActualText := GetLastErrorText();
        if StrPos(ActualText, ExpectedText) = 0 then
            Error('Expected error containing: "%1", but got: "%2"', ExpectedText, ActualText);
    end;

    [Test]
    procedure GivenCustomerWithPrimaryContact_WhenValidateCustomerNo_ThenNameAndContactAutoPopulated()
    var
        OrderIntakeHeader: Record "Order Intake Header Opt.";
        Customer: Record Customer;
    begin
        // [GIVEN] Customer A, which has a Primary Contact (Person A).
        Initialize();
        Customer.Get(TestCustomerNoA);

        // [WHEN] "Customer No." is validated to Customer A on a fresh (blank) header.
        OrderIntakeHeader.Init();
        OrderIntakeHeader.Validate("Customer No.", TestCustomerNoA);

        // [THEN] Customer Name and Contact No. are both auto-populated from the Customer.
        AssertAreEqual(Customer.Name, OrderIntakeHeader."Customer Name", 'Customer Name should be copied from the Customer.');
        AssertAreEqual(TestPersonContactNoA, OrderIntakeHeader."Contact No.", 'Contact No. should be copied from Customer."Primary Contact No.".');
    end;

    [Test]
    procedure GivenCustomerWithNoPrimaryContact_WhenValidateCustomerNo_ThenNameSetContactBlank()
    var
        OrderIntakeHeader: Record "Order Intake Header Opt.";
        Customer: Record Customer;
    begin
        // [GIVEN] Customer C, which has NO Primary Contact set.
        Initialize();
        Customer.Get(TestCustomerNoC);

        // [WHEN] "Customer No." is validated to Customer C on a fresh (blank) header.
        OrderIntakeHeader.Init();
        OrderIntakeHeader.Validate("Customer No.", TestCustomerNoC);

        // [THEN] Customer Name is populated, but Contact No. stays blank.
        AssertAreEqual(Customer.Name, OrderIntakeHeader."Customer Name", 'Customer Name should still be copied from the Customer.');
        AssertAreEqual('', OrderIntakeHeader."Contact No.", 'Contact No. must stay blank when the Customer has no Primary Contact.');
    end;

    [Test]
    procedure GivenCustomerNoSet_WhenValidateCustomerNoToBlank_ThenNameAndContactCleared()
    var
        OrderIntakeHeader: Record "Order Intake Header Opt.";
    begin
        // [GIVEN] A header whose "Customer No." is already set to Customer C (no Work Order
        // attached, so the CheckCanChangeCustomer guard - which also fires on clearing an
        // already-set customer, since that's a "replace with blank" - passes cleanly).
        Initialize();
        OrderIntakeHeader.Init();
        OrderIntakeHeader.Validate("Customer No.", TestCustomerNoC);

        // [WHEN] "Customer No." is validated back to blank.
        OrderIntakeHeader.Validate("Customer No.", '');

        // [THEN] Both Customer Name and Contact No. are cleared.
        AssertAreEqual('', OrderIntakeHeader."Customer Name", 'Customer Name should be cleared.');
        AssertAreEqual('', OrderIntakeHeader."Contact No.", 'Contact No. should be cleared.');
    end;

    [Test]
    procedure GivenBlankCustomerNo_WhenValidateContactNoToPersonWithRelation_ThenCustomerNoAndNameResolved()
    var
        OrderIntakeHeader: Record "Order Intake Header Opt.";
        Customer: Record Customer;
    begin
        // [GIVEN] A fresh header with blank "Customer No.", and Person Contact B, which resolves
        // to Customer B via its owning Company Contact's Contact Business Relation.
        Initialize();
        Customer.Get(TestCustomerNoB);
        OrderIntakeHeader.Init();

        // [WHEN] "Contact No." is validated directly to Person Contact B.
        OrderIntakeHeader.Validate("Contact No.", TestPersonContactNoB);

        // [THEN] "Customer No."/"Customer Name" are resolved and populated, even though
        // "Customer No." started out blank.
        AssertAreEqual(TestCustomerNoB, OrderIntakeHeader."Customer No.", 'Customer No. should resolve via Contact Business Relation.');
        AssertAreEqual(Customer.Name, OrderIntakeHeader."Customer Name", 'Customer Name should be copied from the resolved Customer.');
    end;

    [Test]
    procedure GivenDifferentCustomerAlreadySet_WhenValidateContactNoResolvesDifferentCustomer_ThenCustomerNoAndNameUpdated()
    var
        OrderIntakeHeader: Record "Order Intake Header Opt.";
        Customer: Record Customer;
    begin
        // [GIVEN] A header already carrying Customer A (no Work Order attached, so the guard
        // passes cleanly), and Person Contact B, which resolves to a DIFFERENT customer (B).
        Initialize();
        Customer.Get(TestCustomerNoB);
        OrderIntakeHeader.Init();
        OrderIntakeHeader.Validate("Customer No.", TestCustomerNoA);

        // [WHEN] "Contact No." is validated directly to Person Contact B.
        OrderIntakeHeader.Validate("Contact No.", TestPersonContactNoB);

        // [THEN] "Customer No."/"Customer Name" are updated to the newly resolved customer - the
        // stale Customer A is not kept.
        AssertAreEqual(TestCustomerNoB, OrderIntakeHeader."Customer No.", 'Customer No. should update to the newly resolved customer, not stay on the stale one.');
        AssertAreEqual(Customer.Name, OrderIntakeHeader."Customer Name", 'Customer Name should update to the newly resolved customer.');
    end;

    [Test]
    procedure GivenContactWithNoBusinessRelation_WhenValidateContactNo_ThenErrorRaisedAndCustomerNoUnchanged()
    var
        OrderIntakeHeader: Record "Order Intake Header Opt.";
    begin
        // [GIVEN] A header with Customer No. already set to Customer A (sentinel value, so we can
        // prove it's untouched), and an "orphan" Person Contact with no matching Contact Business
        // Relation.
        Initialize();
        OrderIntakeHeader.Init();
        OrderIntakeHeader.Validate("Customer No.", TestCustomerNoA);

        // [WHEN] "Contact No." is validated to the orphan contact.
        asserterror OrderIntakeHeader.Validate("Contact No.", TestPersonContactNoOrphan);

        // [THEN] An error is raised, and "Customer No." was never touched by this failed attempt
        // (the Error() call happens before any "Customer No." assignment in that code path).
        AssertExpectedErrorContains('is not related to any customer');
        AssertAreEqual(TestCustomerNoA, OrderIntakeHeader."Customer No.", 'Customer No. must remain untouched when Contact No. validation fails.');
    end;

    [Test]
    procedure GivenAnyState_WhenValidateContactNoToBlank_ThenNoErrorAndNoForcedLookup()
    var
        OrderIntakeHeader: Record "Order Intake Header Opt.";
    begin
        // [GIVEN] A header with Customer No./Contact No. already populated via Customer A.
        Initialize();
        OrderIntakeHeader.Init();
        OrderIntakeHeader.Validate("Customer No.", TestCustomerNoA);

        // [WHEN] "Contact No." is validated to blank.
        OrderIntakeHeader.Validate("Contact No.", '');

        // [THEN] No error is raised (implicit - reaching this line proves it), and clearing the
        // Contact No. did not force any relation lookup or touch Customer No./Name.
        AssertAreEqual('', OrderIntakeHeader."Contact No.", 'Contact No. should be blank.');
        AssertAreEqual(TestCustomerNoA, OrderIntakeHeader."Customer No.", 'Customer No. must be untouched by clearing Contact No.');
    end;

    [Test]
    procedure GivenExistingCustomerAndWorkOrderWithDayPlanning_WhenValidateCustomerNoToReplace_ThenErrorRaised()
    var
        OrderIntakeHeader: Record "Order Intake Header Opt.";
        OrderIntakeNo: Code[20];
        WorkOrderNo: Code[20];
    begin
        // [GIVEN] An Order Intake No. with a Work Order attached, which itself has a Day
        // Planning line - and a header that already has Customer A assigned via a first-ever
        // (blank -> A) assignment, which must NOT have triggered the guard.
        Initialize();
        OrderIntakeNo := 'OICTOI08';
        WorkOrderNo := 'OICTWO08';
        CreateWorkOrderWithDayPlanning(OrderIntakeNo, WorkOrderNo);

        OrderIntakeHeader.Init();
        OrderIntakeHeader."No." := OrderIntakeNo;
        OrderIntakeHeader.Validate("Customer No.", TestCustomerNoA);
        AssertAreEqual(TestCustomerNoA, OrderIntakeHeader."Customer No.", 'Pre-condition: first-ever assignment from blank must succeed without error.');

        // [WHEN] "Customer No." is validated again to a DIFFERENT customer (an actual replace).
        asserterror OrderIntakeHeader.Validate("Customer No.", TestCustomerNoB);

        // [THEN] The CheckCanChangeCustomer guard fires because Day Planning lines exist for the
        // linked Work Order.
        AssertExpectedErrorContains('Cannot change the customer');
    end;

    [Test]
    procedure GivenBlankCustomerNoWithExistingWorkOrderAndDayPlanning_WhenValidateCustomerNoFirstTime_ThenNoErrorRaised()
    var
        OrderIntakeHeader: Record "Order Intake Header Opt.";
        Customer: Record Customer;
        OrderIntakeNo: Code[20];
        WorkOrderNo: Code[20];
    begin
        // [GIVEN] An Order Intake No. with a Work Order attached, which itself has a Day
        // Planning line - proving the guard is keyed on REPLACING a customer, not merely on the
        // existence of blocking Work Order/Day Planning data.
        Initialize();
        Customer.Get(TestCustomerNoA);
        OrderIntakeNo := 'OICTOI09';
        WorkOrderNo := 'OICTWO09';
        CreateWorkOrderWithDayPlanning(OrderIntakeNo, WorkOrderNo);

        OrderIntakeHeader.Init();
        OrderIntakeHeader."No." := OrderIntakeNo;

        // [WHEN] "Customer No." is validated for the FIRST TIME (from blank).
        OrderIntakeHeader.Validate("Customer No.", TestCustomerNoA);

        // [THEN] No error is raised (implicit - reaching this line proves it) and Customer No./
        // Name are populated normally - the guard is deliberately skipped on a first-ever
        // assignment from blank.
        AssertAreEqual(TestCustomerNoA, OrderIntakeHeader."Customer No.", 'Customer No. should be set.');
        AssertAreEqual(Customer.Name, OrderIntakeHeader."Customer Name", 'Customer Name should be set.');
    end;
}
