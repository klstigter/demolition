xmlport 50734 DemoData
{
    Caption = 'Demo Data';
    Direction = Both;
    Format = Xml;
    FormatEvaluate = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(DemoData)
        {
            textelement(MasterData)
            {
                MinOccurs = Zero;
                textelement(Calendar)
                {
                    MinOccurs = Zero;
                    tableelement(BaseCalendar; "Base Calendar")
                    {
                        SourceTableView = where("Code" = const('BASIS'));

                        fieldelement(BaseCalendarCode; BaseCalendar.Code) { FieldValidate = No; }
                        fieldelement(BaseCalendarName; BaseCalendar.Name) { FieldValidate = No; }

                        tableelement(BaseCalendarChange; "Base Calendar Change")
                        {
                            MinOccurs = Zero;
                            LinkTable = BaseCalendar;
                            LinkFields = "Base Calendar Code" = field(Code);

                            fieldelement(RecurringSystem; BaseCalendarChange."Recurring System") { FieldValidate = No; }
                            fieldelement(Date; BaseCalendarChange.Date) { FieldValidate = No; }
                            fieldelement(Day; BaseCalendarChange.Day) { FieldValidate = No; }
                            fieldelement(Description; BaseCalendarChange.Description) { FieldValidate = No; }
                            fieldelement(Nonworking; BaseCalendarChange.Nonworking) { FieldValidate = No; }

                            trigger OnBeforeInsertRecord()
                            begin
                                UpsertRecord(BaseCalendarChange);
                                currXMLport.Skip();
                            end;
                        }

                        trigger OnBeforeInsertRecord()
                        begin
                            UpsertRecord(BaseCalendar);
                            currXMLport.Skip();
                        end;
                    }
                }
                textelement(WorkHour)
                {
                    MinOccurs = Zero;
                    tableelement(WorkHourTemplate; "Work-Hour Template")
                    {
                        SourceTableView = where("Code" = const('BASIS'));

                        fieldelement(Code; WorkHourTemplate.Code) { FieldValidate = No; }
                        fieldelement(Description; WorkHourTemplate.Description) { FieldValidate = No; }
                        fieldelement(Monday; WorkHourTemplate.Monday) { FieldValidate = No; }
                        fieldelement(Tuesday; WorkHourTemplate.Tuesday) { FieldValidate = No; }
                        fieldelement(Wednesday; WorkHourTemplate.Wednesday) { FieldValidate = No; }
                        fieldelement(Thursday; WorkHourTemplate.Thursday) { FieldValidate = No; }
                        fieldelement(Friday; WorkHourTemplate.Friday) { FieldValidate = No; }
                        fieldelement(Saturday; WorkHourTemplate.Saturday) { FieldValidate = No; }
                        fieldelement(Sunday; WorkHourTemplate.Sunday) { FieldValidate = No; }
                        fieldelement(TotalPerWeek; WorkHourTemplate."Total per week") { FieldValidate = No; }

                        trigger OnBeforeInsertRecord()
                        begin
                            UpsertRecord(WorkHourTemplate);
                            currXMLport.Skip();
                        end;
                    }
                }
                textelement(Skills)
                {
                    MinOccurs = Zero;
                    tableelement(SkillCode; "Skill Code")
                    {
                        fieldelement(Code; SkillCode.Code) { FieldValidate = No; }
                        fieldelement(Description; SkillCode.Description) { FieldValidate = No; }
                        fieldelement(InvoiceResourceNo; SkillCode."Invoice Resource No.")
                        {
                            FieldValidate = No; // the Resource is imported later in this XML
                        }
                        fieldelement(BarColor; SkillCode."Bar Color") { FieldValidate = No; }
                        fieldelement(FontColor; SkillCode."Font Color") { FieldValidate = No; }
                        fieldelement(BorderColor; SkillCode."Border Color") { FieldValidate = No; }

                        trigger OnBeforeInsertRecord()
                        begin
                            UpsertRecord(SkillCode);
                            currXMLport.Skip();
                        end;
                    }
                }
                textelement(Numbering)
                {
                    MinOccurs = Zero;
                    tableelement("NoSeries"; "No. Series")
                    {
                        sourcetableview = where("Code" = filter('OI|WO'));

                        fieldelement(Code; NoSeries.Code) { FieldValidate = No; }
                        fieldelement(Description; NoSeries.Description) { FieldValidate = No; }
                        fieldelement(DefaultNos; NoSeries."Default Nos.") { FieldValidate = No; }
                        fieldelement(ManualNos; NoSeries."Manual Nos.") { FieldValidate = No; }
                        fieldelement(DateOrder; NoSeries."Date Order") { FieldValidate = No; }


                        tableelement("NoSeriesLine"; "No. Series Line")
                        {
                            MinOccurs = Zero;
                            LinkTable = NoSeries;
                            LinkFields = "Series Code" = field(Code);

                            fieldelement(LineNo; NoSeriesLine."Line No.") { FieldValidate = No; }
                            fieldelement(StartingDate; NoSeriesLine."Starting Date") { FieldValidate = No; }
                            fieldelement(StartingNo; NoSeriesLine."Starting No.") { FieldValidate = No; }
                            fieldelement(EndingNo; NoSeriesLine."Ending No.") { FieldValidate = No; }
                            fieldelement(WarningNo; NoSeriesLine."Warning No.") { FieldValidate = No; }
                            fieldelement(IncrementByNo; NoSeriesLine."Increment-by No.") { FieldValidate = No; }
                            fieldelement(LastNoUsed; NoSeriesLine."Last No. Used") { FieldValidate = No; }
                            fieldelement(Open; NoSeriesLine.Open) { FieldValidate = No; }
                            fieldelement(LastDateUsed; NoSeriesLine."Last Date Used") { FieldValidate = No; }
                            fieldelement(Implementation; NoSeriesLine.Implementation) { FieldValidate = No; }

                            trigger OnBeforeInsertRecord()
                            begin
                                UpsertRecord(NoSeriesLine);
                                currXMLport.Skip();
                            end;
                        }

                        trigger OnBeforeInsertRecord()
                        begin
                            UpsertRecord(NoSeries);
                            currXMLport.Skip();
                        end;
                    }
                }
                textelement(ProjectTypes)
                {
                    MinOccurs = Zero;
                    tableelement(ProjectType; "Project Type Opt.")
                    {
                        fieldelement(Code; ProjectType.Code) { FieldValidate = No; }
                        fieldelement(Description; ProjectType.Description) { FieldValidate = No; }

                        trigger OnBeforeInsertRecord()
                        begin
                            UpsertRecord(ProjectType);
                            currXMLport.Skip();
                        end;
                    }
                }
                textelement(ResourceGroups)
                {
                    MinOccurs = Zero;
                    tableelement(ResourceGroup; "Resource Group")
                    {
                        fieldelement(No; ResourceGroup."No.") { FieldValidate = No; }
                        fieldelement(Name; ResourceGroup.Name) { FieldValidate = No; }

                        trigger OnBeforeInsertRecord()
                        begin
                            UpsertRecord(ResourceGroup);
                            currXMLport.Skip();
                        end;
                    }
                }
                textelement(UoMs)
                {
                    MinOccurs = Zero;
                    tableelement(UnitOfMeasure; "Unit of Measure")
                    {
                        fieldelement(Code; UnitOfMeasure.Code) { FieldValidate = No; }
                        fieldelement(Description; UnitOfMeasure.Description) { FieldValidate = No; }
                        fieldelement(InternationalStandardCode; UnitOfMeasure."International Standard Code") { FieldValidate = No; }
                        fieldelement(Symbol; UnitOfMeasure.Symbol) { FieldValidate = No; }

                        trigger OnBeforeInsertRecord()
                        begin
                            UpsertRecord(UnitOfMeasure);
                            currXMLport.Skip();
                        end;
                    }
                }
                textelement(GenProd)
                {
                    MinOccurs = Zero;
                    tableelement(GenProductPostingGroup; "Gen. Product Posting Group")
                    {
                        fieldelement(Code; GenProductPostingGroup.Code) { FieldValidate = No; }
                        fieldelement(Description; GenProductPostingGroup.Description) { FieldValidate = No; }
                        fieldelement(DefVATProdPostingGroup; GenProductPostingGroup."Def. VAT Prod. Posting Group")
                        {
                            FieldValidate = No; // VAT Product Posting Group is imported later in this XML
                        }
                        fieldelement(AutoInsertDefault; GenProductPostingGroup."Auto Insert Default") { FieldValidate = No; }

                        trigger OnBeforeInsertRecord()
                        begin
                            UpsertRecord(GenProductPostingGroup);
                            currXMLport.Skip();
                        end;
                    }
                }
                textelement(VATProd)
                {
                    MinOccurs = Zero;
                    tableelement(VATProductPostingGroup; "VAT Product Posting Group")
                    {
                        fieldelement(Code; VATProductPostingGroup.Code) { FieldValidate = No; }
                        fieldelement(Description; VATProductPostingGroup.Description) { FieldValidate = No; }

                        trigger OnBeforeInsertRecord()
                        begin
                            UpsertRecord(VATProductPostingGroup);
                            currXMLport.Skip();
                        end;
                    }
                }
                textelement(Customers)
                {
                    MinOccurs = Zero;
                    tableelement(Customer; Customer)
                    {
                        fieldelement(No; Customer."No.") { FieldValidate = No; }
                        fieldelement(Name; Customer.Name) { FieldValidate = No; }
                        fieldelement(SearchName; Customer."Search Name") { FieldValidate = No; }
                        fieldelement(Name2; Customer."Name 2") { FieldValidate = No; }
                        fieldelement(Address; Customer.Address) { FieldValidate = No; }
                        fieldelement(Address2; Customer."Address 2") { FieldValidate = No; }
                        fieldelement(City; Customer.City) { FieldValidate = No; }
                        fieldelement(Contact; Customer.Contact) { FieldValidate = No; }
                        fieldelement(PhoneNo; Customer."Phone No.") { FieldValidate = No; }
                        fieldelement(TelexNo; Customer."Telex No.") { FieldValidate = No; }
                        fieldelement(DocumentSendingProfile; Customer."Document Sending Profile") { FieldValidate = No; }
                        fieldelement(ShipToCode; Customer."Ship-to Code") { FieldValidate = No; }
                        fieldelement(OurAccountNo; Customer."Our Account No.") { FieldValidate = No; }
                        fieldelement(TerritoryCode; Customer."Territory Code") { FieldValidate = No; }
                        fieldelement(GlobalDimension1Code; Customer."Global Dimension 1 Code") { FieldValidate = No; }
                        fieldelement(GlobalDimension2Code; Customer."Global Dimension 2 Code") { FieldValidate = No; }
                        fieldelement(ChainName; Customer."Chain Name") { FieldValidate = No; }
                        fieldelement(BudgetedAmount; Customer."Budgeted Amount") { FieldValidate = No; }
                        fieldelement(CreditLimitLCY; Customer."Credit Limit (LCY)") { }
                        fieldelement(CustomerPostingGroup; Customer."Customer Posting Group") { FieldValidate = No; }
                        fieldelement(CurrencyCode; Customer."Currency Code") { FieldValidate = No; }
                        fieldelement(CustomerPriceGroup; Customer."Customer Price Group") { FieldValidate = No; }
                        fieldelement(LanguageCode; Customer."Language Code") { FieldValidate = No; }
                        fieldelement(RegistrationNumber; Customer."Registration Number") { FieldValidate = No; }
                        fieldelement(StatisticsGroup; Customer."Statistics Group") { FieldValidate = No; }
                        fieldelement(PaymentTermsCode; Customer."Payment Terms Code") { FieldValidate = No; }
                        fieldelement(FinChargeTermsCode; Customer."Fin. Charge Terms Code") { FieldValidate = No; }
                        fieldelement(SalespersonCode; Customer."Salesperson Code") { FieldValidate = No; }
                        fieldelement(ShipmentMethodCode; Customer."Shipment Method Code") { FieldValidate = No; }
                        fieldelement(ShippingAgentCode; Customer."Shipping Agent Code") { FieldValidate = No; }
                        fieldelement(PlaceOfExport; Customer."Place of Export") { FieldValidate = No; }
                        fieldelement(InvoiceDiscCode; Customer."Invoice Disc. Code") { FieldValidate = No; }
                        fieldelement(CustomerDiscGroup; Customer."Customer Disc. Group") { FieldValidate = No; }
                        fieldelement(CountryRegionCode; Customer."Country/Region Code") { FieldValidate = No; }
                        fieldelement(CollectionMethod; Customer."Collection Method") { FieldValidate = No; }
                        fieldelement(Amount; Customer.Amount) { FieldValidate = No; }
                        fieldelement(Blocked; Customer.Blocked) { FieldValidate = No; }
                        fieldelement(LastStatementNo; Customer."Last Statement No.") { FieldValidate = No; }
                        fieldelement(PrintStatements; Customer."Print Statements") { FieldValidate = No; }
                        fieldelement(BillToCustomerNo; Customer."Bill-to Customer No.") { FieldValidate = No; }
                        fieldelement(Priority; Customer.Priority) { FieldValidate = No; }
                        fieldelement(PaymentMethodCode; Customer."Payment Method Code") { FieldValidate = No; }
                        fieldelement(FormatRegion; Customer."Format Region") { FieldValidate = No; }
                        fieldelement(LastDateModified; Customer."Last Date Modified") { FieldValidate = No; }
                        fieldelement(ApplicationMethod; Customer."Application Method") { FieldValidate = No; }
                        fieldelement(PricesIncludingVAT; Customer."Prices Including VAT") { FieldValidate = No; }
                        fieldelement(LocationCode; Customer."Location Code") { FieldValidate = No; }
                        fieldelement(FaxNo; Customer."Fax No.") { FieldValidate = No; }
                        fieldelement(TelexAnswerBack; Customer."Telex Answer Back") { FieldValidate = No; }
                        fieldelement(VATRegistrationNo; Customer."VAT Registration No.") { FieldValidate = No; }
                        fieldelement(CombineShipments; Customer."Combine Shipments") { FieldValidate = No; }
                        fieldelement(GenBusPostingGroup; Customer."Gen. Bus. Posting Group") { FieldValidate = No; }
                        fieldelement(GLN; Customer.GLN) { FieldValidate = No; }
                        fieldelement(PostCode; Customer."Post Code") { FieldValidate = No; }
                        fieldelement(County; Customer.County) { FieldValidate = No; }
                        fieldelement(EORINumber; Customer."EORI Number") { FieldValidate = No; }
                        fieldelement(UseGLNInElectronicDocument; Customer."Use GLN in Electronic Document") { FieldValidate = No; }
                        fieldelement(EMail; Customer."E-Mail") { FieldValidate = No; }
                        fieldelement(HomePage; Customer."Home Page") { FieldValidate = No; }
                        fieldelement(ReminderTermsCode; Customer."Reminder Terms Code") { FieldValidate = No; }
                        fieldelement(NoSeries; Customer."No. Series") { FieldValidate = No; }
                        fieldelement(TaxAreaCode; Customer."Tax Area Code") { FieldValidate = No; }
                        fieldelement(TaxLiable; Customer."Tax Liable") { FieldValidate = No; }
                        fieldelement(VATBusPostingGroup; Customer."VAT Bus. Posting Group") { FieldValidate = No; }
                        fieldelement(Reserve; Customer.Reserve) { FieldValidate = No; }
                        fieldelement(BlockPaymentTolerance; Customer."Block Payment Tolerance") { FieldValidate = No; }
                        fieldelement(ICPartnerCode; Customer."IC Partner Code") { FieldValidate = No; }
                        fieldelement(PrepaymentPct; Customer."Prepayment %") { FieldValidate = No; }
                        fieldelement(PartnerType; Customer."Partner Type") { FieldValidate = No; }
                        fieldelement(IntrastatPartnerType; Customer."Intrastat Partner Type") { FieldValidate = No; }
                        fieldelement(ExcludeFromPmtPractices; Customer."Exclude from Pmt. Practices") { FieldValidate = No; }
                        fieldelement(PrivacyBlocked; Customer."Privacy Blocked") { FieldValidate = No; }
                        fieldelement(DisableSearchByName; Customer."Disable Search by Name") { FieldValidate = No; }
                        fieldelement(AllowMultiplePostingGroups; Customer."Allow Multiple Posting Groups") { FieldValidate = No; }
                        fieldelement(PreferredBankAccountCode; Customer."Preferred Bank Account Code") { FieldValidate = No; }
                        fieldelement(CashFlowPaymentTermsCode; Customer."Cash Flow Payment Terms Code") { FieldValidate = No; }
                        fieldelement(PrimaryContactNo; Customer."Primary Contact No.") { FieldValidate = No; }
                        fieldelement(ContactType; Customer."Contact Type") { FieldValidate = No; }
                        fieldelement(MobilePhoneNo; Customer."Mobile Phone No.") { FieldValidate = No; }
                        fieldelement(ResponsibilityCenter; Customer."Responsibility Center") { FieldValidate = No; }
                        fieldelement(ShippingAdvice; Customer."Shipping Advice") { FieldValidate = No; }
                        fieldelement(ShippingTime; Customer."Shipping Time") { FieldValidate = No; }
                        fieldelement(ShippingAgentServiceCode; Customer."Shipping Agent Service Code") { FieldValidate = No; }
                        fieldelement(PriceCalculationMethod; Customer."Price Calculation Method") { FieldValidate = No; }
                        fieldelement(AllowLineDisc; Customer."Allow Line Disc.") { FieldValidate = No; }
                        fieldelement(BaseCalendarCode; Customer."Base Calendar Code") { FieldValidate = No; }
                        fieldelement(CopySellToAddrToQteFrom; Customer."Copy Sell-to Addr. to Qte From") { FieldValidate = No; }
                        fieldelement(ValidateEUVatRegNo; Customer."Validate EU Vat Reg. No.") { FieldValidate = No; }
                        fieldelement(CurrencyId; Customer."Currency Id") { FieldValidate = No; }
                        fieldelement(PaymentTermsId; Customer."Payment Terms Id") { FieldValidate = No; }
                        fieldelement(ShipmentMethodId; Customer."Shipment Method Id") { FieldValidate = No; }
                        fieldelement(PaymentMethodId; Customer."Payment Method Id") { FieldValidate = No; }
                        fieldelement(TaxAreaID; Customer."Tax Area ID") { FieldValidate = No; }
                        fieldelement(ContactID; Customer."Contact ID") { FieldValidate = No; }
                        fieldelement(ContactGraphId; Customer."Contact Graph Id") { FieldValidate = No; }

                        trigger OnBeforeInsertRecord()
                        begin
                            UpsertRecord(Customer);
                            currXMLport.Skip();
                        end;
                    }
                }
                textelement(Vendors)
                {
                    MinOccurs = Zero;
                    tableelement(Vendor; Vendor)
                    {
                        fieldelement(No; Vendor."No.") { FieldValidate = No; }
                        fieldelement(Name; Vendor.Name) { FieldValidate = No; }
                        fieldelement(SearchName; Vendor."Search Name") { FieldValidate = No; }
                        fieldelement(Name2; Vendor."Name 2") { FieldValidate = No; }
                        fieldelement(Address; Vendor.Address) { FieldValidate = No; }
                        fieldelement(Address2; Vendor."Address 2") { FieldValidate = No; }
                        fieldelement(City; Vendor.City) { FieldValidate = No; }
                        fieldelement(Contact; Vendor.Contact) { FieldValidate = No; }
                        fieldelement(PhoneNo; Vendor."Phone No.") { FieldValidate = No; }
                        fieldelement(TelexNo; Vendor."Telex No.") { FieldValidate = No; }
                        fieldelement(OurAccountNo; Vendor."Our Account No.") { FieldValidate = No; }
                        fieldelement(TerritoryCode; Vendor."Territory Code") { FieldValidate = No; }
                        fieldelement(GlobalDimension1Code; Vendor."Global Dimension 1 Code") { FieldValidate = No; }
                        fieldelement(GlobalDimension2Code; Vendor."Global Dimension 2 Code") { FieldValidate = No; }
                        fieldelement(BudgetedAmount; Vendor."Budgeted Amount") { FieldValidate = No; }
                        fieldelement(VendorPostingGroup; Vendor."Vendor Posting Group") { FieldValidate = No; }
                        fieldelement(CurrencyCode; Vendor."Currency Code") { FieldValidate = No; }
                        fieldelement(LanguageCode; Vendor."Language Code") { FieldValidate = No; }
                        fieldelement(RegistrationNumber; Vendor."Registration Number") { FieldValidate = No; }
                        fieldelement(StatisticsGroup; Vendor."Statistics Group") { FieldValidate = No; }
                        fieldelement(PaymentTermsCode; Vendor."Payment Terms Code") { FieldValidate = No; }
                        fieldelement(FinChargeTermsCode; Vendor."Fin. Charge Terms Code") { FieldValidate = No; }
                        fieldelement(PurchaserCode; Vendor."Purchaser Code") { FieldValidate = No; }
                        fieldelement(ShipmentMethodCode; Vendor."Shipment Method Code") { FieldValidate = No; }
                        fieldelement(ShippingAgentCode; Vendor."Shipping Agent Code") { FieldValidate = No; }
                        fieldelement(InvoiceDiscCode; Vendor."Invoice Disc. Code") { FieldValidate = No; }
                        fieldelement(CountryRegionCode; Vendor."Country/Region Code") { FieldValidate = No; }
                        fieldelement(Blocked; Vendor.Blocked) { FieldValidate = No; }
                        fieldelement(PayToVendorNo; Vendor."Pay-to Vendor No.") { FieldValidate = No; }
                        fieldelement(Priority; Vendor.Priority) { FieldValidate = No; }
                        fieldelement(PaymentMethodCode; Vendor."Payment Method Code") { FieldValidate = No; }
                        fieldelement(FormatRegion; Vendor."Format Region") { FieldValidate = No; }
                        fieldelement(LastDateModified; Vendor."Last Date Modified") { FieldValidate = No; }
                        fieldelement(ApplicationMethod; Vendor."Application Method") { FieldValidate = No; }
                        fieldelement(PricesIncludingVAT; Vendor."Prices Including VAT") { FieldValidate = No; }
                        fieldelement(FaxNo; Vendor."Fax No.") { FieldValidate = No; }
                        fieldelement(TelexAnswerBack; Vendor."Telex Answer Back") { FieldValidate = No; }
                        fieldelement(VATRegistrationNo; Vendor."VAT Registration No.") { FieldValidate = No; }
                        fieldelement(GenBusPostingGroup; Vendor."Gen. Bus. Posting Group") { FieldValidate = No; }
                        fieldelement(GLN; Vendor.GLN) { FieldValidate = No; }
                        fieldelement(PostCode; Vendor."Post Code") { FieldValidate = No; }
                        fieldelement(County; Vendor.County) { FieldValidate = No; }
                        fieldelement(EORINumber; Vendor."EORI Number") { FieldValidate = No; }
                        fieldelement(EMail; Vendor."E-Mail") { FieldValidate = No; }
                        fieldelement(HomePage; Vendor."Home Page") { FieldValidate = No; }
                        fieldelement(NoSeries; Vendor."No. Series") { FieldValidate = No; }
                        fieldelement(TaxAreaCode; Vendor."Tax Area Code") { FieldValidate = No; }
                        fieldelement(TaxLiable; Vendor."Tax Liable") { FieldValidate = No; }
                        fieldelement(VATBusPostingGroup; Vendor."VAT Bus. Posting Group") { FieldValidate = No; }
                        fieldelement(BlockPaymentTolerance; Vendor."Block Payment Tolerance") { FieldValidate = No; }
                        fieldelement(ICPartnerCode; Vendor."IC Partner Code") { FieldValidate = No; }
                        fieldelement(PrepaymentPct; Vendor."Prepayment %") { FieldValidate = No; }
                        fieldelement(PartnerType; Vendor."Partner Type") { FieldValidate = No; }
                        fieldelement(IntrastatPartnerType; Vendor."Intrastat Partner Type") { FieldValidate = No; }
                        fieldelement(ExcludeFromPmtPractices; Vendor."Exclude from Pmt. Practices") { FieldValidate = No; }
                        fieldelement(CompanySizeCode; Vendor."Company Size Code") { FieldValidate = No; }
                        fieldelement(PrivacyBlocked; Vendor."Privacy Blocked") { FieldValidate = No; }
                        fieldelement(DisableSearchByName; Vendor."Disable Search by Name") { FieldValidate = No; }
                        fieldelement(CreditorNo; Vendor."Creditor No.") { FieldValidate = No; }
                        fieldelement(AllowMultiplePostingGroups; Vendor."Allow Multiple Posting Groups") { FieldValidate = No; }
                        fieldelement(SelfBillingAgreement; Vendor."Self-Billing Agreement") { FieldValidate = No; }
                        fieldelement(PreferredBankAccountCode; Vendor."Preferred Bank Account Code") { FieldValidate = No; }
                        fieldelement(CashFlowPaymentTermsCode; Vendor."Cash Flow Payment Terms Code") { FieldValidate = No; }
                        fieldelement(PrimaryContactNo; Vendor."Primary Contact No.") { FieldValidate = No; }
                        fieldelement(MobilePhoneNo; Vendor."Mobile Phone No.") { FieldValidate = No; }
                        fieldelement(ResponsibilityCenter; Vendor."Responsibility Center") { FieldValidate = No; }
                        fieldelement(LocationCode; Vendor."Location Code") { FieldValidate = No; }
                        fieldelement(LeadTimeCalculation; Vendor."Lead Time Calculation") { FieldValidate = No; }
                        fieldelement(PriceCalculationMethod; Vendor."Price Calculation Method") { FieldValidate = No; }
                        fieldelement(BaseCalendarCode; Vendor."Base Calendar Code") { FieldValidate = No; }
                        fieldelement(DocumentSendingProfile; Vendor."Document Sending Profile") { FieldValidate = No; }
                        fieldelement(ValidateEUVatRegNo; Vendor."Validate EU Vat Reg. No.") { FieldValidate = No; }
                        fieldelement(CopyBuyFromAddToQteFrom; Vendor."Copy Buy-from Add. to Qte From") { FieldValidate = No; }
                        fieldelement(CurrencyId; Vendor."Currency Id") { FieldValidate = No; }
                        fieldelement(PaymentTermsId; Vendor."Payment Terms Id") { FieldValidate = No; }
                        fieldelement(PaymentMethodId; Vendor."Payment Method Id") { FieldValidate = No; }
                        fieldelement(OverReceiptCode; Vendor."Over-Receipt Code") { FieldValidate = No; }
                        fieldelement(PlanningVendorId; Vendor."Planning Vendor id") { FieldValidate = No; }
                        fieldelement(PlanningVendorName; Vendor."Planning Vendor Name") { FieldValidate = No; }

                        trigger OnBeforeInsertRecord()
                        begin
                            UpsertRecord(Vendor);
                            currXMLport.Skip();
                        end;
                    }
                }
                textelement(Resources)
                {
                    MinOccurs = Zero;
                    tableelement(Resource; Resource)
                    {
                        fieldelement(No; Resource."No.") { FieldValidate = No; }
                        fieldelement(Type; Resource.Type) { FieldValidate = No; }
                        fieldelement(Name; Resource.Name) { FieldValidate = No; }
                        fieldelement(SearchName; Resource."Search Name") { FieldValidate = No; }
                        fieldelement(Name2; Resource."Name 2") { FieldValidate = No; }
                        fieldelement(Address; Resource.Address) { FieldValidate = No; }
                        fieldelement(Address2; Resource."Address 2") { FieldValidate = No; }
                        fieldelement(City; Resource.City) { FieldValidate = No; }
                        fieldelement(SocialSecurityNo; Resource."Social Security No.") { FieldValidate = No; }
                        fieldelement(JobTitle; Resource."Job Title") { FieldValidate = No; }
                        fieldelement(Education; Resource.Education) { FieldValidate = No; }
                        fieldelement(ContractClass; Resource."Contract Class") { FieldValidate = No; }
                        fieldelement(EmploymentDate; Resource."Employment Date") { FieldValidate = No; }
                        fieldelement(ResourceGroupNo; Resource."Resource Group No.") { FieldValidate = No; }
                        fieldelement(GlobalDimension1Code; Resource."Global Dimension 1 Code") { FieldValidate = No; }
                        fieldelement(GlobalDimension2Code; Resource."Global Dimension 2 Code") { FieldValidate = No; }
                        fieldelement(BaseUnitOfMeasure; Resource."Base Unit of Measure") { FieldValidate = No; }
                        fieldelement(DirectUnitCost; Resource."Direct Unit Cost") { FieldValidate = No; }
                        fieldelement(IndirectCostPct; Resource."Indirect Cost %") { FieldValidate = No; }
                        fieldelement(UnitCost; Resource."Unit Cost") { FieldValidate = No; }
                        fieldelement(ProfitPct; Resource."Profit %") { FieldValidate = No; }
                        fieldelement(PriceProfitCalculation; Resource."Price/Profit Calculation") { FieldValidate = No; }
                        fieldelement(UnitPrice; Resource."Unit Price") { FieldValidate = No; }
                        fieldelement(VendorNo; Resource."Vendor No.") { FieldValidate = No; }
                        fieldelement(LastDateModified; Resource."Last Date Modified") { FieldValidate = No; }
                        fieldelement(Blocked; Resource.Blocked) { FieldValidate = No; }
                        fieldelement(GenProdPostingGroup; Resource."Gen. Prod. Posting Group") { FieldValidate = No; }
                        fieldelement(PostCode; Resource."Post Code") { FieldValidate = No; }
                        fieldelement(County; Resource.County) { FieldValidate = No; }
                        fieldelement(AutomaticExtTexts; Resource."Automatic Ext. Texts") { FieldValidate = No; }
                        fieldelement(NoSeries; Resource."No. Series") { FieldValidate = No; }
                        fieldelement(TaxGroupCode; Resource."Tax Group Code") { FieldValidate = No; }
                        fieldelement(VATProdPostingGroup; Resource."VAT Prod. Posting Group") { FieldValidate = No; }
                        fieldelement(CountryRegionCode; Resource."Country/Region Code") { FieldValidate = No; }
                        fieldelement(ICPartnerPurchGLAccNo; Resource."IC Partner Purch. G/L Acc. No.") { FieldValidate = No; }
                        fieldelement(PrivacyBlocked; Resource."Privacy Blocked") { FieldValidate = No; }
                        fieldelement(UseTimeSheet; Resource."Use Time Sheet") { FieldValidate = No; }
                        fieldelement(TimeSheetOwnerUserID; Resource."Time Sheet Owner User ID") { FieldValidate = No; }
                        fieldelement(TimeSheetApproverUserID; Resource."Time Sheet Approver User ID") { FieldValidate = No; }
                        fieldelement(DefaultDeferralTemplateCode; Resource."Default Deferral Template Code") { FieldValidate = No; }
                        fieldelement(PoolResourceNo; Resource."Pool Resource No.")
                        {
                            FieldValidate = No; // may reference a Resource imported later in this XML
                        }
                        fieldelement(IsPoolMember; Resource."Is Pool Member") { FieldValidate = No; }
                        fieldelement(IsExternal; Resource."Is External") { FieldValidate = No; }
                        fieldelement(MandatorySchedulling; Resource."Mandatory Schedulling") { FieldValidate = No; }
                        fieldelement(IsForeman; Resource."Is Foreman") { FieldValidate = No; }
                        fieldelement(IsPool; Resource."Is Pool") { FieldValidate = No; }
                        fieldelement(DefaultForeman; Resource."Default Foreman")
                        {
                            FieldValidate = No; // may reference a Resource imported later in this XML
                        }
                        fieldelement(WorkHourTemplate; Resource."Work Hour Template") { FieldValidate = No; }

                        textelement(ResourceSkills)
                        {
                            MinOccurs = Zero;
                            tableelement(ResourceSkill; "Resource Skill")
                            {
                                MinOccurs = Zero;
                                LinkTable = Resource;
                                LinkFields = "No." = field("No.");
                                SourceTableView = where(Type = const(Resource));

                                fieldelement(SkillCode; ResourceSkill."Skill Code") { FieldValidate = No; }

                                trigger OnBeforeInsertRecord()
                                begin
                                    // Type and No. are the link/filter fields: set from the parent, not read from the XML.
                                    ResourceSkill.Type := ResourceSkill.Type::Resource;
                                    ResourceSkill."No." := Resource."No.";
                                    UpsertRecord(ResourceSkill);
                                    currXMLport.Skip();
                                end;
                            }
                        }

                        trigger OnBeforeInsertRecord()
                        begin
                            UpsertRecord(Resource);
                            currXMLport.Skip();
                        end;
                    }
                }
            }
            tableelement(DailyOptimizerSetup; "Daily Optimizer Setup")
            {
                MinOccurs = Zero;
                fieldelement(WorkHourTemplate; DailyOptimizerSetup."Work hour Template") { FieldValidate = No; }
                fieldelement(BaseCalendar; DailyOptimizerSetup."Base Calendar") { FieldValidate = No; }
                fieldelement(OrderIntakeNos; DailyOptimizerSetup."Order Intake Nos") { FieldValidate = No; }
                fieldelement(WorkOrderNos; DailyOptimizerSetup."Work Order Nos") { FieldValidate = No; }
                fieldelement(DefaultSkill; DailyOptimizerSetup."Default Skill") { FieldValidate = No; }
                fieldelement(ResourceSchedulerListType; DailyOptimizerSetup."Resource Scheduler - List Type") { FieldValidate = No; }
                fieldelement(FreeCapacityMandatoryColor; DailyOptimizerSetup."Free Capacity-Mandatory Color") { FieldValidate = No; }
                fieldelement(EnvelopeColor; DailyOptimizerSetup."Envelope Color") { FieldValidate = No; }
                fieldelement(EnvelopeBorderColor; DailyOptimizerSetup."Envelope Border Color") { FieldValidate = No; }
                fieldelement(AssignedColor; DailyOptimizerSetup."Assigned Color") { FieldValidate = No; }
                fieldelement(AssignedHighPct; DailyOptimizerSetup."Assigned High (%)") { }
                fieldelement(RequestedHighPct; DailyOptimizerSetup."Requested High (%)") { }
                fieldelement(FreeCapacityColor; DailyOptimizerSetup."Free Capacity Color") { FieldValidate = No; }
                fieldelement(ExternalBorderColor; DailyOptimizerSetup."External Border Color") { FieldValidate = No; }
                fieldelement(CapacityBorderColor; DailyOptimizerSetup."Capacity Border Color") { FieldValidate = No; }
                fieldelement(CapacityFontColor; DailyOptimizerSetup."Capacity Font Color") { FieldValidate = No; }
                fieldelement(BarFontColor; DailyOptimizerSetup."Bar Font Color") { FieldValidate = No; }
                fieldelement(WeekendColor; DailyOptimizerSetup."Weekend Color") { FieldValidate = No; }
                fieldelement(HolidayColor; DailyOptimizerSetup."Holiday Color") { FieldValidate = No; }
                fieldelement(GTBColorNonPosting; DailyOptimizerSetup."GTB Color (non posting)") { }
                fieldelement(GTBColor; DailyOptimizerSetup."GTB Color") { FieldValidate = No; }
                fieldelement(GTBBorderColor; DailyOptimizerSetup."GTB Border Color") { FieldValidate = No; }
                fieldelement(GTBProgressColor; DailyOptimizerSetup."GTB Progress Color") { FieldValidate = No; }
                fieldelement(GTBFontColor; DailyOptimizerSetup."GTB Font Color") { FieldValidate = No; }
                fieldelement(GTBFontSizePx; DailyOptimizerSetup."GTB Font size (px)") { }
                fieldelement(GTBHeightPx; DailyOptimizerSetup."GTB Height (px)") { }
                fieldelement(TooltipBackgroundColor; DailyOptimizerSetup."Tooltip Background Color") { FieldValidate = No; }
                fieldelement(TooltipFontColor; DailyOptimizerSetup."Tooltip Font Color") { FieldValidate = No; }

                trigger OnBeforeInsertRecord()
                begin
                    UpsertRecord(DailyOptimizerSetup);
                    currXMLport.Skip();
                end;
            }
            textelement(Jobs)
            {
                MinOccurs = Zero;
                tableelement(Job; Job)
                {
                    fieldelement(No; Job."No.") { FieldValidate = No; }
                    fieldelement(SearchDescription; Job."Search Description") { FieldValidate = No; }
                    fieldelement(Description; Job.Description) { FieldValidate = No; }
                    fieldelement(Description2; Job."Description 2") { FieldValidate = No; }
                    fieldelement(BillToCustomerNo; Job."Bill-to Customer No.") { FieldValidate = No; }
                    fieldelement(CreationDate; Job."Creation Date") { FieldValidate = No; }
                    fieldelement(StartingDate; Job."Starting Date") { FieldValidate = No; }
                    fieldelement(EndingDate; Job."Ending Date") { FieldValidate = No; }
                    fieldelement(Status; Job.Status) { FieldValidate = No; }
                    fieldelement(PersonResponsible; Job."Person Responsible") { FieldValidate = No; }
                    fieldelement(GlobalDimension1Code; Job."Global Dimension 1 Code") { FieldValidate = No; }
                    fieldelement(GlobalDimension2Code; Job."Global Dimension 2 Code") { FieldValidate = No; }
                    fieldelement(JobPostingGroup; Job."Job Posting Group") { FieldValidate = No; }
                    fieldelement(Blocked; Job.Blocked) { FieldValidate = No; }
                    fieldelement(LastDateModified; Job."Last Date Modified") { FieldValidate = No; }
                    fieldelement(CustomerDiscGroup; Job."Customer Disc. Group") { FieldValidate = No; }
                    fieldelement(CustomerPriceGroup; Job."Customer Price Group") { FieldValidate = No; }
                    fieldelement(LocationCode; Job."Location Code") { FieldValidate = No; }
                    fieldelement(BinCode; Job."Bin Code") { FieldValidate = No; }
                    fieldelement(LanguageCode; Job."Language Code") { FieldValidate = No; }
                    fieldelement(BillToName; Job."Bill-to Name") { FieldValidate = No; }
                    fieldelement(BillToAddress; Job."Bill-to Address") { FieldValidate = No; }
                    fieldelement(BillToAddress2; Job."Bill-to Address 2") { FieldValidate = No; }
                    fieldelement(BillToCity; Job."Bill-to City") { FieldValidate = No; }
                    fieldelement(BillToCounty; Job."Bill-to County") { FieldValidate = No; }
                    fieldelement(BillToPostCode; Job."Bill-to Post Code") { FieldValidate = No; }
                    fieldelement(NoSeries; Job."No. Series") { FieldValidate = No; }
                    fieldelement(BillToCountryRegionCode; Job."Bill-to Country/Region Code") { FieldValidate = No; }
                    fieldelement(BillToName2; Job."Bill-to Name 2") { FieldValidate = No; }
                    fieldelement(TaskBillingMethod; Job."Task Billing Method") { FieldValidate = No; }
                    fieldelement(Reserve; Job.Reserve) { FieldValidate = No; }
                    fieldelement(ShipToPhoneNo; Job."Ship-to Phone No.") { FieldValidate = No; }
                    fieldelement(WIPMethod; Job."WIP Method") { FieldValidate = No; }
                    fieldelement(CurrencyCode; Job."Currency Code") { FieldValidate = No; }
                    fieldelement(BillToContactNo; Job."Bill-to Contact No.") { FieldValidate = No; }
                    fieldelement(BillToContact; Job."Bill-to Contact") { FieldValidate = No; }
                    fieldelement(InvoiceCurrencyCode; Job."Invoice Currency Code") { FieldValidate = No; }
                    fieldelement(ExchCalculationCost; Job."Exch. Calculation (Cost)") { FieldValidate = No; }
                    fieldelement(ExchCalculationPrice; Job."Exch. Calculation (Price)") { FieldValidate = No; }
                    fieldelement(AllowScheduleContractLines; Job."Allow Schedule/Contract Lines") { FieldValidate = No; }
                    fieldelement(Complete; Job.Complete) { FieldValidate = No; }
                    fieldelement(NextInvoiceDate; Job."Next Invoice Date") { FieldValidate = No; }
                    fieldelement(ApplyUsageLink; Job."Apply Usage Link") { FieldValidate = No; }
                    fieldelement(WIPPostingMethod; Job."WIP Posting Method") { FieldValidate = No; }
                    fieldelement(ProjectManager; Job."Project Manager") { FieldValidate = No; }
                    fieldelement(SellToCustomerNo; Job."Sell-to Customer No.") { FieldValidate = No; }
                    fieldelement(SellToCustomerName; Job."Sell-to Customer Name") { FieldValidate = No; }
                    fieldelement(SellToCustomerName2; Job."Sell-to Customer Name 2") { FieldValidate = No; }
                    fieldelement(SellToAddress; Job."Sell-to Address") { FieldValidate = No; }
                    fieldelement(SellToAddress2; Job."Sell-to Address 2") { FieldValidate = No; }
                    fieldelement(SellToCity; Job."Sell-to City") { FieldValidate = No; }
                    fieldelement(SellToContact; Job."Sell-to Contact") { FieldValidate = No; }
                    fieldelement(SellToPostCode; Job."Sell-to Post Code") { FieldValidate = No; }
                    fieldelement(SellToCounty; Job."Sell-to County") { FieldValidate = No; }
                    fieldelement(SellToCountryRegionCode; Job."Sell-to Country/Region Code") { FieldValidate = No; }
                    fieldelement(SellToPhoneNo; Job."Sell-to Phone No.") { FieldValidate = No; }
                    fieldelement(SellToEMail; Job."Sell-to E-Mail") { FieldValidate = No; }
                    fieldelement(SellToContactNo; Job."Sell-to Contact No.") { FieldValidate = No; }
                    fieldelement(ShipToCode; Job."Ship-to Code") { FieldValidate = No; }
                    fieldelement(ShipToName; Job."Ship-to Name") { FieldValidate = No; }
                    fieldelement(ShipToName2; Job."Ship-to Name 2") { FieldValidate = No; }
                    fieldelement(ShipToAddress; Job."Ship-to Address") { FieldValidate = No; }
                    fieldelement(ShipToAddress2; Job."Ship-to Address 2") { FieldValidate = No; }
                    fieldelement(ShipToCity; Job."Ship-to City") { FieldValidate = No; }
                    fieldelement(ShipToContact; Job."Ship-to Contact") { FieldValidate = No; }
                    fieldelement(ShipToPostCode; Job."Ship-to Post Code") { FieldValidate = No; }
                    fieldelement(ShipToCounty; Job."Ship-to County") { FieldValidate = No; }
                    fieldelement(ShipToCountryRegionCode; Job."Ship-to Country/Region Code") { FieldValidate = No; }
                    fieldelement(ExternalDocumentNo; Job."External Document No.") { FieldValidate = No; }
                    fieldelement(PaymentMethodCode; Job."Payment Method Code") { FieldValidate = No; }
                    fieldelement(PaymentTermsCode; Job."Payment Terms Code") { FieldValidate = No; }
                    fieldelement(YourReference; Job."Your Reference") { FieldValidate = No; }
                    fieldelement(PriceCalculationMethod; Job."Price Calculation Method") { FieldValidate = No; }
                    fieldelement(CostCalculationMethod; Job."Cost Calculation Method") { FieldValidate = No; }
                    fieldelement(JobViewType; Job."Job View Type") { FieldValidate = No; }
                    fieldelement(NonActive; Job."Non Active") { FieldValidate = No; }
                    fieldelement(ProjectType; Job."Project Type") { FieldValidate = No; }

                    tableelement(JobTask; "Job Task")
                    {
                        MinOccurs = Zero;
                        LinkTable = Job;
                        LinkFields = "Job No." = field("No.");

                        fieldelement(JobTaskNo; JobTask."Job Task No.") { FieldValidate = No; }
                        fieldelement(Description; JobTask.Description) { FieldValidate = No; }
                        fieldelement(JobTaskType; JobTask."Job Task Type") { FieldValidate = No; }
                        fieldelement(WIPTotal; JobTask."WIP-Total") { FieldValidate = No; }
                        fieldelement(JobPostingGroup; JobTask."Job Posting Group") { FieldValidate = No; }
                        fieldelement(WIPMethod; JobTask."WIP Method") { FieldValidate = No; }
                        fieldelement(Totaling; JobTask.Totaling) { FieldValidate = No; }
                        fieldelement(NewPage; JobTask."New Page") { FieldValidate = No; }
                        fieldelement(NoOfBlankLines; JobTask."No. of Blank Lines") { FieldValidate = No; }
                        fieldelement(Indentation; JobTask.Indentation) { FieldValidate = No; }
                        fieldelement(LocationCode; JobTask."Location Code") { FieldValidate = No; }
                        fieldelement(BinCode; JobTask."Bin Code") { FieldValidate = No; }
                        fieldelement(LanguageCode; JobTask."Language Code") { FieldValidate = No; }
                        fieldelement(GlobalDimension1Code; JobTask."Global Dimension 1 Code") { FieldValidate = No; }
                        fieldelement(GlobalDimension2Code; JobTask."Global Dimension 2 Code") { FieldValidate = No; }
                        fieldelement(StartDate; JobTask."Start Date") { FieldValidate = No; }
                        fieldelement(EndDate; JobTask."End Date") { FieldValidate = No; }
                        fieldelement(BillToCustomerNo; JobTask."Bill-to Customer No.") { FieldValidate = No; }
                        fieldelement(BillToName; JobTask."Bill-to Name") { FieldValidate = No; }
                        fieldelement(BillToAddress; JobTask."Bill-to Address") { FieldValidate = No; }
                        fieldelement(BillToAddress2; JobTask."Bill-to Address 2") { FieldValidate = No; }
                        fieldelement(BillToCity; JobTask."Bill-to City") { FieldValidate = No; }
                        fieldelement(BillToCounty; JobTask."Bill-to County") { FieldValidate = No; }
                        fieldelement(BillToPostCode; JobTask."Bill-to Post Code") { FieldValidate = No; }
                        fieldelement(BillToCountryRegionCode; JobTask."Bill-to Country/Region Code") { FieldValidate = No; }
                        fieldelement(BillToName2; JobTask."Bill-to Name 2") { FieldValidate = No; }
                        fieldelement(BillToContactNo; JobTask."Bill-to Contact No.") { FieldValidate = No; }
                        fieldelement(BillToContact; JobTask."Bill-to Contact") { FieldValidate = No; }
                        fieldelement(SellToCustomerNo; JobTask."Sell-to Customer No.") { FieldValidate = No; }
                        fieldelement(SellToCustomerName; JobTask."Sell-to Customer Name") { FieldValidate = No; }
                        fieldelement(SellToCustomerName2; JobTask."Sell-to Customer Name 2") { FieldValidate = No; }
                        fieldelement(SellToAddress; JobTask."Sell-to Address") { FieldValidate = No; }
                        fieldelement(SellToAddress2; JobTask."Sell-to Address 2") { FieldValidate = No; }
                        fieldelement(SellToCity; JobTask."Sell-to City") { FieldValidate = No; }
                        fieldelement(SellToContact; JobTask."Sell-to Contact") { FieldValidate = No; }
                        fieldelement(SellToPostCode; JobTask."Sell-to Post Code") { FieldValidate = No; }
                        fieldelement(SellToCounty; JobTask."Sell-to County") { FieldValidate = No; }
                        fieldelement(SellToCountryRegionCode; JobTask."Sell-to Country/Region Code") { FieldValidate = No; }
                        fieldelement(SellToContactNo; JobTask."Sell-to Contact No.") { FieldValidate = No; }
                        fieldelement(ShipToCode; JobTask."Ship-to Code") { FieldValidate = No; }
                        fieldelement(ShipToName; JobTask."Ship-to Name") { FieldValidate = No; }
                        fieldelement(ShipToName2; JobTask."Ship-to Name 2") { FieldValidate = No; }
                        fieldelement(ShipToAddress; JobTask."Ship-to Address") { FieldValidate = No; }
                        fieldelement(ShipToAddress2; JobTask."Ship-to Address 2") { FieldValidate = No; }
                        fieldelement(ShipToCity; JobTask."Ship-to City") { FieldValidate = No; }
                        fieldelement(ShipToContact; JobTask."Ship-to Contact") { FieldValidate = No; }
                        fieldelement(ShipToPostCode; JobTask."Ship-to Post Code") { FieldValidate = No; }
                        fieldelement(ShipToCounty; JobTask."Ship-to County") { FieldValidate = No; }
                        fieldelement(ShipToCountryRegionCode; JobTask."Ship-to Country/Region Code") { FieldValidate = No; }
                        fieldelement(ExternalDocumentNo; JobTask."External Document No.") { FieldValidate = No; }
                        fieldelement(PaymentMethodCode; JobTask."Payment Method Code") { FieldValidate = No; }
                        fieldelement(PaymentTermsCode; JobTask."Payment Terms Code") { FieldValidate = No; }
                        fieldelement(YourReference; JobTask."Your Reference") { FieldValidate = No; }
                        fieldelement(PriceCalculationMethod; JobTask."Price Calculation Method") { FieldValidate = No; }
                        fieldelement(InvoiceCurrencyCode; JobTask."Invoice Currency Code") { FieldValidate = No; }
                        fieldelement(ProjectManager; JobTask."Project Manager") { FieldValidate = No; }
                        fieldelement(WorkHourTemplate; JobTask."Work Hour Template") { FieldValidate = No; }
                        fieldelement(DeadlineDate; JobTask."Deadline Date") { FieldValidate = No; }
                        fieldelement(PlaceholderDate; JobTask."Placeholder Date") { FieldValidate = No; }
                        fieldelement(Closed; JobTask.Closed) { FieldValidate = No; }
                        fieldelement(ClosedDate; JobTask."Closed Date") { FieldValidate = No; }
                        fieldelement(ClosedReasonCode; JobTask."Closed Reason Code") { FieldValidate = No; }
                        fieldelement(VisualBarStartDate; JobTask.VisualBarStartDate) { FieldValidate = No; }
                        fieldelement(VisualBarEndDate; JobTask.VisualBarEndDate) { FieldValidate = No; }
                        fieldelement(StartTime; JobTask."Start Time") { FieldValidate = No; }
                        fieldelement(EndTime; JobTask."End Time") { FieldValidate = No; }
                        fieldelement(SchedulingType; JobTask."Scheduling Type") { FieldValidate = No; }
                        fieldelement(EstimatedHours; JobTask."Estimated Hours") { FieldValidate = No; }
                        fieldelement(Duration; JobTask.Duration) { FieldValidate = No; }
                        fieldelement(Progress; JobTask.Progress) { FieldValidate = No; }
                        fieldelement(NonActive; JobTask."Non Active") { FieldValidate = No; }
                        fieldelement(ConstraintType; JobTask."Constraint Type") { FieldValidate = No; }
                        fieldelement(ConstraintDate; JobTask."Constraint Date") { FieldValidate = No; }
                        fieldelement(MaxDuration; JobTask."Max Duration") { FieldValidate = No; }
                        fieldelement(ConstraintCalcStartDate; JobTask."Constraint Calc. - Start Date") { FieldValidate = No; }
                        fieldelement(ConstraintCalcEndDate; JobTask."Constraint Calc. - End Date") { FieldValidate = No; }
                        fieldelement(Depth; JobTask.Depth) { FieldValidate = No; }
                        fieldelement(IsBoor; JobTask.IsBoor) { FieldValidate = No; }

                        trigger OnBeforeInsertRecord()
                        begin
                            // Job No. is the link field: set from the parent, not read from the XML.
                            JobTask."Job No." := Job."No.";
                            UpsertRecord(JobTask);
                            currXMLport.Skip();
                        end;
                    }

                    trigger OnBeforeInsertRecord()
                    begin
                        UpsertRecord(Job);
                        currXMLport.Skip();
                    end;
                }
            }
            textelement(DayPlannings)
            {
                MinOccurs = Zero;
                tableelement(DayPlanning; "Day Planning")
                {
                    UseTemporary = true;
                    fieldelement(JobNo; DayPlanning."Job No.") { FieldValidate = No; }
                    fieldelement(JobTaskNo; DayPlanning."Job Task No.") { FieldValidate = No; }
                    fieldelement(DayLineNo; DayPlanning."Day Line No.") { FieldValidate = No; }
                    fieldelement(PlanDate; DayPlanning."Plan Date") { FieldValidate = No; }
                    fieldelement(PlanStatus; DayPlanning."Plan Status") { FieldValidate = No; }
                    fieldelement(Skill; DayPlanning.Skill) { FieldValidate = No; }
                    fieldelement(SequenceNo; DayPlanning."Sequence No.") { FieldValidate = No; }
                    fieldelement(Description; DayPlanning.Description) { FieldValidate = No; }
                    fieldelement(DataOwner; DayPlanning."Data Owner") { FieldValidate = No; }
                    fieldelement(RequestedResourceNo; DayPlanning."Requested Resource No.") { FieldValidate = No; }
                    fieldelement(RequestedPoolResourceNo; DayPlanning."Requested Pool Resource No.") { FieldValidate = No; }
                    fieldelement(StartTimeRequested; DayPlanning."Start Time Requested") { FieldValidate = No; }
                    fieldelement(EndTimeRequested; DayPlanning."End Time Requested") { FieldValidate = No; }
                    fieldelement(NonWorkingMinutesRequested; DayPlanning."Non Working Minutes Requested") { FieldValidate = No; }
                    fieldelement(RequestedHours; DayPlanning."Requested Hours") { FieldValidate = No; }
                    fieldelement(AssignedResourceNo; DayPlanning."Assigned Resource No.") { FieldValidate = No; }
                    fieldelement(AssignedPoolResourceNo; DayPlanning."Assigned Pool Resource No.") { FieldValidate = No; }
                    fieldelement(StartTimeAssigned; DayPlanning."Start Time Assigned") { FieldValidate = No; }
                    fieldelement(EndTimeAssigned; DayPlanning."End Time Assigned") { FieldValidate = No; }
                    fieldelement(NonWorkingMinutesAssigned; DayPlanning."Non Working Minutes Assigned") { FieldValidate = No; }
                    fieldelement(AssignedHours; DayPlanning."Assigned Hours") { FieldValidate = No; }
                    fieldelement(Assigned; DayPlanning.Assigned) { FieldValidate = No; }

                    trigger OnPreXmlItem()
                    begin
                        if not currXMLport.Import() then
                            LoadDayPlannings();
                    end;

                    trigger OnBeforeInsertRecord()
                    begin
                        ProcessDayPlanning();
                        currXMLport.Skip();
                    end;
                }
            }
            textelement(Capacities)
            {
                MinOccurs = Zero;
                tableelement(Capacity; "Res. Capacity Entry")
                {
                    UseTemporary = true;
                    fieldelement(EntryNo; Capacity."Entry No.") { FieldValidate = No; }
                    fieldelement(ResourceNo; Capacity."Resource No.") { FieldValidate = No; }
                    fieldelement(Date; Capacity.Date) { FieldValidate = No; }
                    fieldelement(StartTime; Capacity."Start Time") { FieldValidate = No; }
                    fieldelement(EndTime; Capacity."End Time") { FieldValidate = No; }
                    fieldelement(Capacity; Capacity.Capacity) { FieldValidate = No; }
                    fieldelement(ResourceGroupNo; Capacity."Resource Group No.") { FieldValidate = No; }

                    trigger OnPreXmlItem()
                    begin
                        if not currXMLport.Import() then
                            LoadCapacities();
                    end;

                    trigger OnBeforeInsertRecord()
                    begin
                        ProcessCapacity();
                        currXMLport.Skip();
                    end;
                }
            }
            textelement(OrderIntakes)
            {
                MinOccurs = Zero;
                tableelement(OrderIntake; "Order Intake Header Opt.")
                {
                    fieldelement(No; OrderIntake."No.") { FieldValidate = No; }
                    fieldelement(OrderDate; OrderIntake."Order Date") { FieldValidate = No; }
                    fieldelement(CustomerNo; OrderIntake."Customer No.") { FieldValidate = No; }
                    fieldelement(CustomerName; OrderIntake."Customer Name") { FieldValidate = No; }
                    fieldelement(ContactNo; OrderIntake."Contact No.") { FieldValidate = No; }
                    fieldelement(ShortDescription; OrderIntake."Short Description") { FieldValidate = No; }
                    fieldelement(Status; OrderIntake.Status) { FieldValidate = No; }
                    fieldelement(NoSeries; OrderIntake."No. Series") { FieldValidate = No; }

                    tableelement(OrderIntakeLine; "Order Intake Line")
                    {
                        MinOccurs = Zero;
                        LinkTable = OrderIntake;
                        LinkFields = "Order Intake No." = field("No.");

                        fieldelement(LineNo; OrderIntakeLine."Line No.") { FieldValidate = No; }
                        fieldelement(Description; OrderIntakeLine.Description) { FieldValidate = No; }
                        fieldelement(ProjectNo; OrderIntakeLine."Project No.") { FieldValidate = No; }
                        fieldelement(ProjectTaskNo; OrderIntakeLine."Project Task No.") { FieldValidate = No; }

                        trigger OnBeforeInsertRecord()
                        begin
                            // Order Intake No. is the link field: set from the parent, not read from the XML.
                            OrderIntakeLine."Order Intake No." := OrderIntake."No.";
                            UpsertRecord(OrderIntakeLine);
                            currXMLport.Skip();
                        end;
                    }

                    trigger OnBeforeInsertRecord()
                    begin
                        UpsertRecord(OrderIntake);
                        currXMLport.Skip();
                    end;
                }
            }
        }
    }

    var
        ScanOnly: Boolean;
        ExportStart: Date;
        ExportEnd: Date;
        MinDate: Date;
        MaxDate: Date;
        ImportedDayPlannings: Integer;
        ImportedCapacities: Integer;
        ImpErrTable: List of [Text];
        ImpErrKey: List of [Text];
        ImpErrText: List of [Text];

    // Export: limit the exported Day Plannings and Capacity entries to this period (blank = no limit).
    procedure SetExportPeriod(NewStartDate: Date; NewEndDate: Date)
    begin
        ExportStart := NewStartDate;
        ExportEnd := NewEndDate;
        if (NewStartDate <> 0D) and (NewEndDate = 0D) then
            ExportEnd := DMY2Date(31, 12, 9999);
    end;

    local procedure LoadDayPlannings()
    var
        RealDayPlanning: Record "Day Planning";
    begin
        DayPlanning.Reset();
        DayPlanning.DeleteAll();
        if (ExportStart <> 0D) or (ExportEnd <> 0D) then
            RealDayPlanning.SetRange("Plan Date", ExportStart, ExportEnd);
        if RealDayPlanning.FindSet() then
            repeat
                DayPlanning := RealDayPlanning;
                DayPlanning.Insert(false);
            until RealDayPlanning.Next() = 0;
    end;

    local procedure LoadCapacities()
    var
        RealCapacity: Record "Res. Capacity Entry";
    begin
        Capacity.Reset();
        Capacity.DeleteAll();
        if (ExportStart <> 0D) or (ExportEnd <> 0D) then
            RealCapacity.SetRange(Date, ExportStart, ExportEnd);
        if RealCapacity.FindSet() then
            repeat
                Capacity := RealCapacity;
                Capacity.Insert(false);
            until RealCapacity.Next() = 0;
    end;

    // Scan only: collect the date range of the Day Planning / Capacity rows without importing anything.
    procedure SetScanOnly()
    begin
        ScanOnly := true;
    end;

    procedure GetDateRange(var StartDate: Date; var EndDate: Date)
    begin
        StartDate := MinDate;
        EndDate := MaxDate;
    end;

    local procedure TrackDate(TestDate: Date)
    begin
        if TestDate = 0D then
            exit;
        if (MinDate = 0D) or (TestDate < MinDate) then
            MinDate := TestDate;
        if TestDate > MaxDate then
            MaxDate := TestDate;
    end;

    procedure GetImportedDayPlannings(): Integer
    begin
        exit(ImportedDayPlannings);
    end;

    procedure GetImportedCapacities(): Integer
    begin
        exit(ImportedCapacities);
    end;

    // Never raises: upserts the imported record (modify if the key exists, else insert) without
    // running any table triggers; a failing record is skipped and recorded in the import error list.
    local procedure UpsertRecord(Imported: Variant)
    var
        RecRef: RecordRef;
    begin
        if ScanOnly then
            exit;
        if TryUpsert(Imported) then
            exit;
        RecRef.GetTable(Imported);
        AddImportError(RecRef.Caption(), Format(RecRef.RecordId()), GetLastErrorText());
    end;

    [TryFunction]
    local procedure TryUpsert(Imported: Variant)
    var
        RecRef: RecordRef;
        Existing: RecordRef;
        KeyRef: KeyRef;
        FldRef: FieldRef;
        ExFldRef: FieldRef;
        PKFields: List of [Integer];
        i: Integer;
    begin
        RecRef.GetTable(Imported);
        Existing.Open(RecRef.Number());
        KeyRef := RecRef.KeyIndex(1);
        for i := 1 to KeyRef.FieldCount() do begin
            FldRef := KeyRef.FieldIndex(i);
            PKFields.Add(FldRef.Number());
            Existing.Field(FldRef.Number()).SetRange(FldRef.Value());
        end;
        EnsureRelatedRecords(RecRef);
        if not Existing.FindFirst() then begin
            RecRef.Insert(false);
            exit;
        end;
        for i := 1 to RecRef.FieldCount() do begin
            FldRef := RecRef.FieldIndex(i);
            if (FldRef.Class() = FieldClass::Normal) and FldRef.Active() and (FldRef.Type() <> FieldType::Blob) and
               (FldRef.Number() < 2000000000) and not PKFields.Contains(FldRef.Number())
            then begin
                ExFldRef := Existing.Field(FldRef.Number());
                ExFldRef.Value := FldRef.Value();
            end;
        end;
        Existing.Modify(false);
    end;

    // Creates a placeholder (key value as Name/Description) for every referenced master record that
    // does not exist yet. Never overwrites an existing record; later XML sections upsert real values.
    local procedure EnsureRelatedRecords(var RecRef: RecordRef)
    var
        FldRef: FieldRef;
        RelTable: Integer;
        i: Integer;
    begin
        for i := 1 to RecRef.FieldCount() do begin
            FldRef := RecRef.FieldIndex(i);
            if (FldRef.Class() = FieldClass::Normal) and FldRef.Active() and (FldRef.Type() in [FieldType::Code, FieldType::Text]) then
                if Format(FldRef.Value()) <> '' then begin
                    RelTable := FldRef.Relation();
                    if (RelTable <> 0) and (RelTable <> RecRef.Number()) and not IsSkippedRelatedTable(RelTable) then
                        if TryCreatePlaceholder(RelTable, Format(FldRef.Value())) then;
                end;
        end;
    end;

    local procedure IsSkippedRelatedTable(TableNo: Integer): Boolean
    begin
        // Customer, Vendor, Contact, Employee, Item, G/L Account, Bank Account, Job, Job Task, User, Dimension, Dimension Value
        exit(TableNo in [18, 23, 5050, 5200, 27, 15, 270, 167, 1001, 2000000120, 348, 349]);
    end;

    [TryFunction]
    local procedure TryCreatePlaceholder(TableNo: Integer; KeyValue: Text)
    var
        RelRef: RecordRef;
        KeyRef: KeyRef;
        KeyFld: FieldRef;
        TxtFld: FieldRef;
        i: Integer;
    begin
        RelRef.Open(TableNo);
        KeyRef := RelRef.KeyIndex(1);
        if KeyRef.FieldCount() <> 1 then
            exit;
        KeyFld := KeyRef.FieldIndex(1);
        if not (KeyFld.Type() in [FieldType::Code, FieldType::Text]) then
            exit;
        KeyFld := RelRef.Field(KeyFld.Number());
        KeyFld.SetRange(CopyStr(KeyValue, 1, KeyFld.Length()));
        if not RelRef.IsEmpty() then
            exit;
        RelRef.Init();
        KeyFld.Value := CopyStr(KeyValue, 1, KeyFld.Length());
        for i := 1 to RelRef.FieldCount() do begin
            TxtFld := RelRef.FieldIndex(i);
            if (TxtFld.Class() = FieldClass::Normal) and (TxtFld.Type() in [FieldType::Code, FieldType::Text]) and
               ((TxtFld.Name() = 'Description') or (TxtFld.Name() = 'Name'))
            then
                TxtFld.Value := CopyStr(KeyValue, 1, TxtFld.Length());
        end;
        RelRef.Insert(false);
    end;

    local procedure ProcessDayPlanning()
    begin
        TrackDate(DayPlanning."Plan Date");
        if ScanOnly then
            exit;
        if TryUpsertDayPlanning() then
            ImportedDayPlannings += 1
        else
            AddImportError(DayPlanning.TableCaption(), StrSubstNo('%1 %2 %3', DayPlanning."Job No.", DayPlanning."Job Task No.", DayPlanning."Day Line No."), GetLastErrorText());
    end;

    [TryFunction]
    local procedure TryUpsertDayPlanning()
    var
        RealDayPlanning: Record "Day Planning";
    begin
        if RealDayPlanning.Get(DayPlanning."Job No.", DayPlanning."Job Task No.", DayPlanning."Day Line No.") then begin
            RealDayPlanning.TransferFields(DayPlanning, false);
            RealDayPlanning.Modify(false);
        end else begin
            RealDayPlanning := DayPlanning;
            RealDayPlanning.Insert(false);
        end;
        EnsureCapacity(DayPlanning."Assigned Resource No.", DayPlanning."Plan Date", DayPlanning."Assigned Hours");
        EnsureCapacity(DayPlanning."Requested Resource No.", DayPlanning."Plan Date", DayPlanning."Requested Hours");
    end;

    // Makes sure the Resource has a capacity entry on the Day Planning date (created only if missing;
    // the Capacities section, when present, still overwrites it with the real values).
    local procedure EnsureCapacity(ResourceNo: Code[20]; CapacityDate: Date; Hours: Decimal)
    var
        Resource: Record Resource;
        RealCap: Record "Res. Capacity Entry";
        LastCap: Record "Res. Capacity Entry";
    begin
        if (ResourceNo = '') or (CapacityDate = 0D) then
            exit;
        RealCap.SetRange("Resource No.", ResourceNo);
        RealCap.SetRange(Date, CapacityDate);
        if not RealCap.IsEmpty() then
            exit;
        if not Resource.Get(ResourceNo) then
            exit;
        RealCap.Init();
        RealCap."Resource No." := ResourceNo;
        RealCap."Resource Group No." := Resource."Resource Group No.";
        RealCap.Date := CapacityDate;
        RealCap.Capacity := Hours;
        if LastCap.FindLast() then
            RealCap."Entry No." := LastCap."Entry No." + 1
        else
            RealCap."Entry No." := 1;
        RealCap.Insert(false);
    end;

    local procedure ProcessCapacity()
    begin
        TrackDate(Capacity.Date);
        if ScanOnly then
            exit;
        if TryUpsertCapacity() then
            ImportedCapacities += 1
        else
            AddImportError(Capacity.TableCaption(), StrSubstNo('%1 %2', Capacity."Resource No.", Capacity.Date), GetLastErrorText());
    end;

    [TryFunction]
    local procedure TryUpsertCapacity()
    var
        RealCap: Record "Res. Capacity Entry";
        LastCap: Record "Res. Capacity Entry";
    begin
        RealCap.SetRange("Resource No.", Capacity."Resource No.");
        RealCap.SetRange(Date, Capacity.Date);
        if RealCap.FindFirst() then begin
            RealCap.Capacity := Capacity.Capacity;
            RealCap."Start Time" := Capacity."Start Time";
            RealCap."End Time" := Capacity."End Time";
            RealCap."Resource Group No." := Capacity."Resource Group No.";
            RealCap.Modify(false);
        end else begin
            RealCap := Capacity;
            if LastCap.FindLast() then
                RealCap."Entry No." := LastCap."Entry No." + 1
            else
                RealCap."Entry No." := 1;
            RealCap.Insert(false);
        end;
    end;

    local procedure AddImportError(TableName: Text; RecordKey: Text; ErrorText: Text)
    begin
        ImpErrTable.Add(TableName);
        ImpErrKey.Add(RecordKey);
        ImpErrText.Add(ErrorText);
    end;

    procedure GetImportErrors(var ErrTables: List of [Text]; var ErrKeys: List of [Text]; var ErrTexts: List of [Text])
    begin
        ErrTables := ImpErrTable;
        ErrKeys := ImpErrKey;
        ErrTexts := ImpErrText;
    end;
}
