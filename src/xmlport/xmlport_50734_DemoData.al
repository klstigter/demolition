xmlport 50734 DemoData
{
    Caption = 'Demo Data';
    Direction = Both;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(DemoData)
        {
            textelement(MasterData)
            {
                textelement(Calendar)
                {
                    tableelement(BaseCalendar; "Base Calendar")
                    {
                        SourceTableView = where("Code" = const('BASIS'));

                        fieldelement(BaseCalendarCode; BaseCalendar.Code) { }
                        fieldelement(BaseCalendarName; BaseCalendar.Name) { }
                        tableelement(BaseCalendarChange; "Base Calendar Change")
                        {
                            LinkTable = BaseCalendar;
                            LinkFields = "Base Calendar Code" = field(Code);

                            fieldelement(RecurringSystem; BaseCalendarChange."Recurring System") { }
                            fieldelement(Date; BaseCalendarChange.Date) { }
                            fieldelement(Day; BaseCalendarChange.Day) { }
                            fieldelement(Description; BaseCalendarChange.Description) { }
                            fieldelement(Nonworking; BaseCalendarChange.Nonworking) { }
                        }
                    }
                }
                textelement(WorkHour)
                {
                    tableelement(WorkHourTemplate; "Work-Hour Template")
                    {
                        SourceTableView = where("Code" = const('BASIS'));

                        fieldelement(Code; WorkHourTemplate.Code) { }
                        fieldelement(Description; WorkHourTemplate.Description) { }
                        fieldelement(Monday; WorkHourTemplate.Monday) { }
                        fieldelement(Tuesday; WorkHourTemplate.Tuesday) { }
                        fieldelement(Wednesday; WorkHourTemplate.Wednesday) { }
                        fieldelement(Thursday; WorkHourTemplate.Thursday) { }
                        fieldelement(Friday; WorkHourTemplate.Friday) { }
                        fieldelement(Saturday; WorkHourTemplate.Saturday) { }
                        fieldelement(Sunday; WorkHourTemplate.Sunday) { }
                        fieldelement(TotalPerWeek; WorkHourTemplate."Total per week") { }
                    }
                }
                textelement(Skills)
                {
                    tableelement(SkillCode; "Skill Code")
                    {
                        fieldelement(Code; SkillCode.Code) { }
                        fieldelement(Description; SkillCode.Description) { }
                        fieldelement(InvoiceResourceNo; SkillCode."Invoice Resource No.") { }
                        fieldelement(BarColor; SkillCode."Bar Color") { }
                        fieldelement(FontColor; SkillCode."Font Color") { }
                        fieldelement(BorderColor; SkillCode."Border Color") { }
                    }
                }
                textelement(Numbering)
                {
                    tableelement("NoSeries"; "No. Series")
                    {
                        sourcetableview = where("Code" = filter('OI|WO'));

                        fieldelement(Code; NoSeries.Code) { }
                        fieldelement(Description; NoSeries.Description) { }
                        fieldelement(DefaultNos; NoSeries."Default Nos.") { }
                        fieldelement(ManualNos; NoSeries."Manual Nos.") { }
                        fieldelement(DateOrder; NoSeries."Date Order") { }

                        tableelement("NoSeriesLine"; "No. Series Line")
                        {
                            LinkTable = NoSeries;
                            LinkFields = "Series Code" = field(Code);

                            fieldelement(LineNo; NoSeriesLine."Line No.") { }
                            fieldelement(StartingDate; NoSeriesLine."Starting Date") { }
                            fieldelement(StartingNo; NoSeriesLine."Starting No.") { }
                            fieldelement(EndingNo; NoSeriesLine."Ending No.") { }
                            fieldelement(WarningNo; NoSeriesLine."Warning No.") { }
                            fieldelement(IncrementByNo; NoSeriesLine."Increment-by No.") { }
                            fieldelement(LastNoUsed; NoSeriesLine."Last No. Used") { }
                            fieldelement(Open; NoSeriesLine.Open) { }
                            fieldelement(LastDateUsed; NoSeriesLine."Last Date Used") { }
                            fieldelement(Implementation; NoSeriesLine.Implementation) { }
                        }
                    }
                }
                textelement(ProjectTypes)
                {
                    tableelement(ProjectType; "Project Type Opt.")
                    {
                        fieldelement(Code; ProjectType.Code) { }
                        fieldelement(Description; ProjectType.Description) { }
                    }
                }
                textelement(ResourceGroups)
                {
                    tableelement(ResourceGroup; "Resource Group")
                    {
                        fieldelement(No; ResourceGroup."No.") { }
                        fieldelement(Name; ResourceGroup.Name) { }
                    }
                }
                textelement(UoMs)
                {
                    tableelement(UnitOfMeasure; "Unit of Measure")
                    {
                        fieldelement(Code; UnitOfMeasure.Code) { }
                        fieldelement(Description; UnitOfMeasure.Description) { }
                        fieldelement(InternationalStandardCode; UnitOfMeasure."International Standard Code") { }
                        fieldelement(Symbol; UnitOfMeasure.Symbol) { }
                    }
                }
                textelement(GenProd)
                {
                    tableelement(GenProductPostingGroup; "Gen. Product Posting Group")
                    {
                        fieldelement(Code; GenProductPostingGroup.Code) { }
                        fieldelement(Description; GenProductPostingGroup.Description) { }
                        fieldelement(DefVATProdPostingGroup; GenProductPostingGroup."Def. VAT Prod. Posting Group") { }
                        fieldelement(AutoInsertDefault; GenProductPostingGroup."Auto Insert Default") { }
                    }
                }
                textelement(VATProd)
                {
                    tableelement(VATProductPostingGroup; "VAT Product Posting Group")
                    {
                        fieldelement(Code; VATProductPostingGroup.Code) { }
                        fieldelement(Description; VATProductPostingGroup.Description) { }
                    }
                }
                textelement(Customers)
                {
                    tableelement(Customer; Customer)
                    {
                        fieldelement(No; Customer."No.") { }
                        fieldelement(Name; Customer.Name) { }
                        fieldelement(SearchName; Customer."Search Name") { }
                        fieldelement(Name2; Customer."Name 2") { }
                        fieldelement(Address; Customer.Address) { }
                        fieldelement(Address2; Customer."Address 2") { }
                        fieldelement(City; Customer.City) { }
                        fieldelement(Contact; Customer.Contact) { }
                        fieldelement(PhoneNo; Customer."Phone No.") { }
                        fieldelement(TelexNo; Customer."Telex No.") { }
                        fieldelement(DocumentSendingProfile; Customer."Document Sending Profile") { }
                        fieldelement(ShipToCode; Customer."Ship-to Code") { }
                        fieldelement(OurAccountNo; Customer."Our Account No.") { }
                        fieldelement(TerritoryCode; Customer."Territory Code") { }
                        fieldelement(GlobalDimension1Code; Customer."Global Dimension 1 Code") { }
                        fieldelement(GlobalDimension2Code; Customer."Global Dimension 2 Code") { }
                        fieldelement(ChainName; Customer."Chain Name") { }
                        fieldelement(BudgetedAmount; Customer."Budgeted Amount") { }
                        fieldelement(CreditLimitLCY; Customer."Credit Limit (LCY)") { }
                        fieldelement(CustomerPostingGroup; Customer."Customer Posting Group") { }
                        fieldelement(CurrencyCode; Customer."Currency Code") { }
                        fieldelement(CustomerPriceGroup; Customer."Customer Price Group") { }
                        fieldelement(LanguageCode; Customer."Language Code") { }
                        fieldelement(RegistrationNumber; Customer."Registration Number") { }
                        fieldelement(StatisticsGroup; Customer."Statistics Group") { }
                        fieldelement(PaymentTermsCode; Customer."Payment Terms Code") { }
                        fieldelement(FinChargeTermsCode; Customer."Fin. Charge Terms Code") { }
                        fieldelement(SalespersonCode; Customer."Salesperson Code") { }
                        fieldelement(ShipmentMethodCode; Customer."Shipment Method Code") { }
                        fieldelement(ShippingAgentCode; Customer."Shipping Agent Code") { }
                        fieldelement(PlaceOfExport; Customer."Place of Export") { }
                        fieldelement(InvoiceDiscCode; Customer."Invoice Disc. Code") { }
                        fieldelement(CustomerDiscGroup; Customer."Customer Disc. Group") { }
                        fieldelement(CountryRegionCode; Customer."Country/Region Code") { }
                        fieldelement(CollectionMethod; Customer."Collection Method") { }
                        fieldelement(Amount; Customer.Amount) { }
                        fieldelement(Blocked; Customer.Blocked) { }
                        fieldelement(LastStatementNo; Customer."Last Statement No.") { }
                        fieldelement(PrintStatements; Customer."Print Statements") { }
                        fieldelement(BillToCustomerNo; Customer."Bill-to Customer No.") { }
                        fieldelement(Priority; Customer.Priority) { }
                        fieldelement(PaymentMethodCode; Customer."Payment Method Code") { }
                        fieldelement(FormatRegion; Customer."Format Region") { }
                        fieldelement(LastDateModified; Customer."Last Date Modified") { }
                        fieldelement(ApplicationMethod; Customer."Application Method") { }
                        fieldelement(PricesIncludingVAT; Customer."Prices Including VAT") { }
                        fieldelement(LocationCode; Customer."Location Code") { }
                        fieldelement(FaxNo; Customer."Fax No.") { }
                        fieldelement(TelexAnswerBack; Customer."Telex Answer Back") { }
                        fieldelement(VATRegistrationNo; Customer."VAT Registration No.") { }
                        fieldelement(CombineShipments; Customer."Combine Shipments") { }
                        fieldelement(GenBusPostingGroup; Customer."Gen. Bus. Posting Group") { }
                        fieldelement(GLN; Customer.GLN) { }
                        fieldelement(PostCode; Customer."Post Code") { }
                        fieldelement(County; Customer.County) { }
                        fieldelement(EORINumber; Customer."EORI Number") { }
                        fieldelement(UseGLNInElectronicDocument; Customer."Use GLN in Electronic Document") { }
                        fieldelement(EMail; Customer."E-Mail") { }
                        fieldelement(HomePage; Customer."Home Page") { }
                        fieldelement(ReminderTermsCode; Customer."Reminder Terms Code") { }
                        fieldelement(NoSeries; Customer."No. Series") { }
                        fieldelement(TaxAreaCode; Customer."Tax Area Code") { }
                        fieldelement(TaxLiable; Customer."Tax Liable") { }
                        fieldelement(VATBusPostingGroup; Customer."VAT Bus. Posting Group") { }
                        fieldelement(Reserve; Customer.Reserve) { }
                        fieldelement(BlockPaymentTolerance; Customer."Block Payment Tolerance") { }
                        fieldelement(ICPartnerCode; Customer."IC Partner Code") { }
                        fieldelement(PrepaymentPct; Customer."Prepayment %") { }
                        fieldelement(PartnerType; Customer."Partner Type") { }
                        fieldelement(IntrastatPartnerType; Customer."Intrastat Partner Type") { }
                        fieldelement(ExcludeFromPmtPractices; Customer."Exclude from Pmt. Practices") { }
                        fieldelement(PrivacyBlocked; Customer."Privacy Blocked") { }
                        fieldelement(DisableSearchByName; Customer."Disable Search by Name") { }
                        fieldelement(AllowMultiplePostingGroups; Customer."Allow Multiple Posting Groups") { }
                        fieldelement(PreferredBankAccountCode; Customer."Preferred Bank Account Code") { }
                        fieldelement(CashFlowPaymentTermsCode; Customer."Cash Flow Payment Terms Code") { }
                        fieldelement(PrimaryContactNo; Customer."Primary Contact No.") { }
                        fieldelement(ContactType; Customer."Contact Type") { }
                        fieldelement(MobilePhoneNo; Customer."Mobile Phone No.") { }
                        fieldelement(ResponsibilityCenter; Customer."Responsibility Center") { }
                        fieldelement(ShippingAdvice; Customer."Shipping Advice") { }
                        fieldelement(ShippingTime; Customer."Shipping Time") { }
                        fieldelement(ShippingAgentServiceCode; Customer."Shipping Agent Service Code") { }
                        fieldelement(PriceCalculationMethod; Customer."Price Calculation Method") { }
                        fieldelement(AllowLineDisc; Customer."Allow Line Disc.") { }
                        fieldelement(BaseCalendarCode; Customer."Base Calendar Code") { }
                        fieldelement(CopySellToAddrToQteFrom; Customer."Copy Sell-to Addr. to Qte From") { }
                        fieldelement(ValidateEUVatRegNo; Customer."Validate EU Vat Reg. No.") { }
                        fieldelement(CurrencyId; Customer."Currency Id") { }
                        fieldelement(PaymentTermsId; Customer."Payment Terms Id") { }
                        fieldelement(ShipmentMethodId; Customer."Shipment Method Id") { }
                        fieldelement(PaymentMethodId; Customer."Payment Method Id") { }
                        fieldelement(TaxAreaID; Customer."Tax Area ID") { }
                        fieldelement(ContactID; Customer."Contact ID") { }
                        fieldelement(ContactGraphId; Customer."Contact Graph Id") { }
                        fieldelement(TransactionModeCode; Customer."Transaction Mode Code") { }
                    }
                }
                textelement(Vendors)
                {
                    tableelement(Vendor; Vendor)
                    {
                        fieldelement(No; Vendor."No.") { }
                        fieldelement(Name; Vendor.Name) { }
                        fieldelement(SearchName; Vendor."Search Name") { }
                        fieldelement(Name2; Vendor."Name 2") { }
                        fieldelement(Address; Vendor.Address) { }
                        fieldelement(Address2; Vendor."Address 2") { }
                        fieldelement(City; Vendor.City) { }
                        fieldelement(Contact; Vendor.Contact) { }
                        fieldelement(PhoneNo; Vendor."Phone No.") { }
                        fieldelement(TelexNo; Vendor."Telex No.") { }
                        fieldelement(OurAccountNo; Vendor."Our Account No.") { }
                        fieldelement(TerritoryCode; Vendor."Territory Code") { }
                        fieldelement(GlobalDimension1Code; Vendor."Global Dimension 1 Code") { }
                        fieldelement(GlobalDimension2Code; Vendor."Global Dimension 2 Code") { }
                        fieldelement(BudgetedAmount; Vendor."Budgeted Amount") { }
                        fieldelement(VendorPostingGroup; Vendor."Vendor Posting Group") { }
                        fieldelement(CurrencyCode; Vendor."Currency Code") { }
                        fieldelement(LanguageCode; Vendor."Language Code") { }
                        fieldelement(RegistrationNumber; Vendor."Registration Number") { }
                        fieldelement(StatisticsGroup; Vendor."Statistics Group") { }
                        fieldelement(PaymentTermsCode; Vendor."Payment Terms Code") { }
                        fieldelement(FinChargeTermsCode; Vendor."Fin. Charge Terms Code") { }
                        fieldelement(PurchaserCode; Vendor."Purchaser Code") { }
                        fieldelement(ShipmentMethodCode; Vendor."Shipment Method Code") { }
                        fieldelement(ShippingAgentCode; Vendor."Shipping Agent Code") { }
                        fieldelement(InvoiceDiscCode; Vendor."Invoice Disc. Code") { }
                        fieldelement(CountryRegionCode; Vendor."Country/Region Code") { }
                        fieldelement(Blocked; Vendor.Blocked) { }
                        fieldelement(PayToVendorNo; Vendor."Pay-to Vendor No.") { }
                        fieldelement(Priority; Vendor.Priority) { }
                        fieldelement(PaymentMethodCode; Vendor."Payment Method Code") { }
                        fieldelement(FormatRegion; Vendor."Format Region") { }
                        fieldelement(LastDateModified; Vendor."Last Date Modified") { }
                        fieldelement(ApplicationMethod; Vendor."Application Method") { }
                        fieldelement(PricesIncludingVAT; Vendor."Prices Including VAT") { }
                        fieldelement(FaxNo; Vendor."Fax No.") { }
                        fieldelement(TelexAnswerBack; Vendor."Telex Answer Back") { }
                        fieldelement(VATRegistrationNo; Vendor."VAT Registration No.") { }
                        fieldelement(GenBusPostingGroup; Vendor."Gen. Bus. Posting Group") { }
                        fieldelement(GLN; Vendor.GLN) { }
                        fieldelement(PostCode; Vendor."Post Code") { }
                        fieldelement(County; Vendor.County) { }
                        fieldelement(EORINumber; Vendor."EORI Number") { }
                        fieldelement(EMail; Vendor."E-Mail") { }
                        fieldelement(HomePage; Vendor."Home Page") { }
                        fieldelement(NoSeries; Vendor."No. Series") { }
                        fieldelement(TaxAreaCode; Vendor."Tax Area Code") { }
                        fieldelement(TaxLiable; Vendor."Tax Liable") { }
                        fieldelement(VATBusPostingGroup; Vendor."VAT Bus. Posting Group") { }
                        fieldelement(BlockPaymentTolerance; Vendor."Block Payment Tolerance") { }
                        fieldelement(ICPartnerCode; Vendor."IC Partner Code") { }
                        fieldelement(PrepaymentPct; Vendor."Prepayment %") { }
                        fieldelement(PartnerType; Vendor."Partner Type") { }
                        fieldelement(IntrastatPartnerType; Vendor."Intrastat Partner Type") { }
                        fieldelement(ExcludeFromPmtPractices; Vendor."Exclude from Pmt. Practices") { }
                        fieldelement(CompanySizeCode; Vendor."Company Size Code") { }
                        fieldelement(PrivacyBlocked; Vendor."Privacy Blocked") { }
                        fieldelement(DisableSearchByName; Vendor."Disable Search by Name") { }
                        fieldelement(CreditorNo; Vendor."Creditor No.") { }
                        fieldelement(AllowMultiplePostingGroups; Vendor."Allow Multiple Posting Groups") { }
                        fieldelement(SelfBillingAgreement; Vendor."Self-Billing Agreement") { }
                        fieldelement(PreferredBankAccountCode; Vendor."Preferred Bank Account Code") { }
                        fieldelement(CashFlowPaymentTermsCode; Vendor."Cash Flow Payment Terms Code") { }
                        fieldelement(PrimaryContactNo; Vendor."Primary Contact No.") { }
                        fieldelement(MobilePhoneNo; Vendor."Mobile Phone No.") { }
                        fieldelement(ResponsibilityCenter; Vendor."Responsibility Center") { }
                        fieldelement(LocationCode; Vendor."Location Code") { }
                        fieldelement(LeadTimeCalculation; Vendor."Lead Time Calculation") { }
                        fieldelement(PriceCalculationMethod; Vendor."Price Calculation Method") { }
                        fieldelement(BaseCalendarCode; Vendor."Base Calendar Code") { }
                        fieldelement(DocumentSendingProfile; Vendor."Document Sending Profile") { }
                        fieldelement(ValidateEUVatRegNo; Vendor."Validate EU Vat Reg. No.") { }
                        fieldelement(CopyBuyFromAddToQteFrom; Vendor."Copy Buy-from Add. to Qte From") { }
                        fieldelement(CurrencyId; Vendor."Currency Id") { }
                        fieldelement(PaymentTermsId; Vendor."Payment Terms Id") { }
                        fieldelement(PaymentMethodId; Vendor."Payment Method Id") { }
                        fieldelement(OverReceiptCode; Vendor."Over-Receipt Code") { }
                        fieldelement(TransactionModeCode; Vendor."Transaction Mode Code") { }
                        fieldelement(PlanningVendorId; Vendor."Planning Vendor id") { }
                        fieldelement(PlanningVendorName; Vendor."Planning Vendor Name") { }
                    }
                }
                textelement(Resources)
                {
                    tableelement(Resource; Resource)
                    {
                        fieldelement(No; Resource."No.") { }
                        fieldelement(Type; Resource.Type) { }
                        fieldelement(Name; Resource.Name) { }
                        fieldelement(SearchName; Resource."Search Name") { }
                        fieldelement(Name2; Resource."Name 2") { }
                        fieldelement(Address; Resource.Address) { }
                        fieldelement(Address2; Resource."Address 2") { }
                        fieldelement(City; Resource.City) { }
                        fieldelement(SocialSecurityNo; Resource."Social Security No.") { }
                        fieldelement(JobTitle; Resource."Job Title") { }
                        fieldelement(Education; Resource.Education) { }
                        fieldelement(ContractClass; Resource."Contract Class") { }
                        fieldelement(EmploymentDate; Resource."Employment Date") { }
                        fieldelement(ResourceGroupNo; Resource."Resource Group No.") { }
                        fieldelement(GlobalDimension1Code; Resource."Global Dimension 1 Code") { }
                        fieldelement(GlobalDimension2Code; Resource."Global Dimension 2 Code") { }
                        fieldelement(BaseUnitOfMeasure; Resource."Base Unit of Measure") { }
                        fieldelement(DirectUnitCost; Resource."Direct Unit Cost") { }
                        fieldelement(IndirectCostPct; Resource."Indirect Cost %") { }
                        fieldelement(UnitCost; Resource."Unit Cost") { }
                        fieldelement(ProfitPct; Resource."Profit %") { }
                        fieldelement(PriceProfitCalculation; Resource."Price/Profit Calculation") { }
                        fieldelement(UnitPrice; Resource."Unit Price") { }
                        fieldelement(VendorNo; Resource."Vendor No.") { }
                        fieldelement(LastDateModified; Resource."Last Date Modified") { }
                        fieldelement(Blocked; Resource.Blocked) { }
                        fieldelement(GenProdPostingGroup; Resource."Gen. Prod. Posting Group") { }
                        fieldelement(PostCode; Resource."Post Code") { }
                        fieldelement(County; Resource.County) { }
                        fieldelement(AutomaticExtTexts; Resource."Automatic Ext. Texts") { }
                        fieldelement(NoSeries; Resource."No. Series") { }
                        fieldelement(TaxGroupCode; Resource."Tax Group Code") { }
                        fieldelement(VATProdPostingGroup; Resource."VAT Prod. Posting Group") { }
                        fieldelement(CountryRegionCode; Resource."Country/Region Code") { }
                        fieldelement(ICPartnerPurchGLAccNo; Resource."IC Partner Purch. G/L Acc. No.") { }
                        fieldelement(PrivacyBlocked; Resource."Privacy Blocked") { }
                        fieldelement(UseTimeSheet; Resource."Use Time Sheet") { }
                        fieldelement(TimeSheetOwnerUserID; Resource."Time Sheet Owner User ID") { }
                        fieldelement(TimeSheetApproverUserID; Resource."Time Sheet Approver User ID") { }
                        fieldelement(DefaultDeferralTemplateCode; Resource."Default Deferral Template Code") { }
                        fieldelement(PoolResourceNo; Resource."Pool Resource No.") { }
                        fieldelement(IsPoolMember; Resource."Is Pool Member") { }
                        fieldelement(IsExternal; Resource."Is External") { }
                        fieldelement(MandatorySchedulling; Resource."Mandatory Schedulling") { }
                        fieldelement(IsForeman; Resource."Is Foreman") { }
                        fieldelement(IsPool; Resource."Is Pool") { }
                        fieldelement(DefaultForeman; Resource."Default Foreman") { }
                        fieldelement(WorkHourTemplate; Resource."Work Hour Template") { }
                    }
                }
            }
            tableelement(DailyOptimizerSetup; "Daily Optimizer Setup")
            {
                fieldelement(WorkHourTemplate; DailyOptimizerSetup."Work hour Template") { }
                fieldelement(BaseCalendar; DailyOptimizerSetup."Base Calendar") { }
                fieldelement(OrderIntakeNos; DailyOptimizerSetup."Order Intake Nos") { }
                fieldelement(WorkOrderNos; DailyOptimizerSetup."Work Order Nos") { }
                fieldelement(DefaultSkill; DailyOptimizerSetup."Default Skill") { }
                fieldelement(ResourceSchedulerListType; DailyOptimizerSetup."Resource Scheduler - List Type") { }
                fieldelement(FreeCapacityMandatoryColor; DailyOptimizerSetup."Free Capacity-Mandatory Color") { }
                fieldelement(EnvelopeColor; DailyOptimizerSetup."Envelope Color") { }
                fieldelement(EnvelopeBorderColor; DailyOptimizerSetup."Envelope Border Color") { }
                fieldelement(AssignedColor; DailyOptimizerSetup."Assigned Color") { }
                fieldelement(AssignedHighPct; DailyOptimizerSetup."Assigned High (%)") { }
                fieldelement(RequestedHighPct; DailyOptimizerSetup."Requested High (%)") { }
                fieldelement(FreeCapacityColor; DailyOptimizerSetup."Free Capacity Color") { }
                fieldelement(ExternalBorderColor; DailyOptimizerSetup."External Border Color") { }
                fieldelement(CapacityBorderColor; DailyOptimizerSetup."Capacity Border Color") { }
                fieldelement(CapacityFontColor; DailyOptimizerSetup."Capacity Font Color") { }
                fieldelement(BarFontColor; DailyOptimizerSetup."Bar Font Color") { }
                fieldelement(WeekendColor; DailyOptimizerSetup."Weekend Color") { }
                fieldelement(HolidayColor; DailyOptimizerSetup."Holiday Color") { }
                fieldelement(GTBColorNonPosting; DailyOptimizerSetup."GTB Color (non posting)") { }
                fieldelement(GTBColor; DailyOptimizerSetup."GTB Color") { }
                fieldelement(GTBBorderColor; DailyOptimizerSetup."GTB Border Color") { }
                fieldelement(GTBProgressColor; DailyOptimizerSetup."GTB Progress Color") { }
                fieldelement(GTBFontColor; DailyOptimizerSetup."GTB Font Color") { }
                fieldelement(GTBFontSizePx; DailyOptimizerSetup."GTB Font size (px)") { }
                fieldelement(GTBHeightPx; DailyOptimizerSetup."GTB Height (px)") { }
                fieldelement(TooltipBackgroundColor; DailyOptimizerSetup."Tooltip Background Color") { }
                fieldelement(TooltipFontColor; DailyOptimizerSetup."Tooltip Font Color") { }
            }
        }
    }
}
