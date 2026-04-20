page 50623 "Job Journal Line Listpart Opt."
{
    PageType = ListPart;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "Job Journal Line";
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                // field(templateName; Rec."Journal Template Name")
                // {
                //     ApplicationArea = Jobs;
                //     ToolTip = 'Specifies the name of the journal template that the journal line belongs to.';
                // }
                // field(batchName; Rec."Journal Batch Name")
                // {
                //     ApplicationArea = Jobs;
                //     ToolTip = 'Specifies the name of the journal batch that the journal line belongs to.';
                // }
                // field(lineNo; Rec."Line No.")
                // {
                //     ApplicationArea = Jobs;
                //     ToolTip = 'Specifies the line number of the journal line. Line numbers are used to determine the sequence of the lines on the journal.';
                // }
                field(lineType; Rec."Line Type")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the type of planning line to create when a project ledger entry is posted. If the field is empty, no planning lines are created.';
                }
                field(postingDate; Rec."Posting Date")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the posting date you want to assign to each journal line. For more information, see Entering Dates and Times.';
                }
                field(documentDate; Rec."Document Date")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the date when the related document was created.';
                    Visible = false;
                }
                field(documentNo; Rec."Document No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies a document number for the journal line.';
                    ShowMandatory = true;
                }
                field(externalDocumentNo; Rec."External Document No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies a document number that refers to the customer''s or vendor''s numbering system.';
                    Visible = false;
                }
                field(jobNo; Rec."Job No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the number of the project.';

                    trigger OnValidate()
                    begin
                        JobJnlManagement.GetNames(Rec, JobDescription, AccName);
                        Rec.ShowShortcutDimCode(ShortcutDimCode);
                    end;
                }
                field(jobTaskNo; Rec."Job Task No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the number of the related project task.';

                    trigger OnValidate()
                    begin
                        Rec.ShowShortcutDimCode(ShortcutDimCode);
                    end;
                }
                field(type; Rec.Type)
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies an account type for project usage to be posted in the project journal. You can choose from the following options:';

                    trigger OnValidate()
                    begin
                        JobJnlManagement.GetNames(Rec, JobDescription, AccName);
                    end;
                }
                field(priceCalculationMethod; Rec."Price Calculation Method")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the method that will be used for price calculation in the item journal line.';
                }
                field(costCalculationMethod; Rec."Cost Calculation Method")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the method that will be used for cost calculation in the item journal line.';
                }
                field(no; Rec."No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';

                    trigger OnValidate()
                    begin
                        JobJnlManagement.GetNames(Rec, JobDescription, AccName);
                        Rec.ShowShortcutDimCode(ShortcutDimCode);
                    end;
                }
                field(description; Rec.Description)
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the name of the resource, item, or general ledger account to which this entry applies. You can change the description.';
                }
                field(description2; Rec."Description 2")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies information in addition to the description.';
                    Visible = false;
                }
                field(jobPlanningLineNo; Rec."Job Planning Line No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the project planning line number that the usage should be linked to when the project journal is posted. You can only link to project planning lines that have the Apply Usage Link option enabled.';
                    Visible = false;
                }
                field(genBusPostingGroup; Rec."Gen. Bus. Posting Group")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the vendor''s or customer''s trade type to link transactions made for this business partner with the appropriate general ledger account according to the general posting setup.';
                    Visible = false;
                }
                field(genProdPostingGroup; Rec."Gen. Prod. Posting Group")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the item''s product type to link transactions made for this item with the appropriate general ledger account according to the general posting setup.';
                    Visible = false;
                }
                field(variantCode; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the variant of the item on the line.';
                    Visible = false;
                }
                field(locationCode; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies a location code for an item.';
                }
                field(binCode; Rec."Bin Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the bin where the items are picked or put away.';
                }
                field(workTypeCode; Rec."Work Type Code")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies which work type the resource applies to. Prices are updated based on this entry.';
                }
                field(currencyCode; Rec."Currency Code")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the project''s currency code that listed in the Currency Code field in the Project Card. You can only create a Project Journal using this currency code.';
                    Visible = false;

                    trigger OnAssistEdit()
                    var
                        ChangeExchangeRate: Page "Change Exchange Rate";
                    begin
                        ChangeExchangeRate.SetParameter(Rec."Currency Code", Rec."Currency Factor", Rec."Posting Date");
                        if ChangeExchangeRate.RunModal() = ACTION::OK then
                            Rec.Validate("Currency Factor", ChangeExchangeRate.GetParameter());

                        Clear(ChangeExchangeRate);
                    end;
                }
                field(unitOfMeasureCode; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                }
                field(quantity; Rec.Quantity)
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the number of units of the project journal''s No. field, that is, either the resource, item, or G/L account number, that applies. If you later change the value in the No. field, the quantity does not change on the journal line.';
                }
                field(remainingQty; Rec."Remaining Qty.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the quantity of the resource or item that remains to complete a project. The remaining quantity is calculated as the difference between Quantity and Qty. Posted. You can modify this field to indicate the quantity you want to remain on the project planning line after you post usage.';
                    Visible = false;
                }
#if not CLEAN25
                field(quantityToTransferToInvoice; Rec."Qty. to Transfer to Invoice")
                {
                    ApplicationArea = Jobs;
                    Visible = false;
                    ToolTip = 'Specifies the number of units of the project journal''s No. field, that is, either the resource, item, or G/L account number, that applies. If you later change the value in the No. field, the quantity does not change on the journal line.';
                    ObsoleteReason = 'Field Service is moved to Field Service Integration app.';
                    ObsoleteState = Pending;
                    ObsoleteTag = '25.0';
                }
#endif
                field(directUnitCostLCY; Rec."Direct Unit Cost (LCY)")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the cost, in the local currency, of one unit of the selected item or resource.';
                    Visible = false;
                }
                field(unitCost; Rec."Unit Cost")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the cost of one unit of the item or resource on the line.';
                }
                field(unitCostLCY; Rec."Unit Cost (LCY)")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the cost, in LCY, of one unit of the item or resource on the line.';
                }
                field(totalCost; Rec."Total Cost")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the total cost for the journal line. The total cost is calculated based on the project currency, which comes from the Currency Code field on the Project card.';
                }
                field(totalCostLCY; Rec."Total Cost (LCY)")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the total cost for this journal line. The amount is in the local currency.';
                }
                field(unitPrice; Rec."Unit Price")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the price of one unit of the item or resource. You can enter a price manually or have it entered according to the Price/Profit Calculation field on the related card.';
                }
                field(unitPriceLCY; Rec."Unit Price (LCY)")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the price, in LCY, of one unit of the item or resource. You can enter a price manually or have it entered according to the Price/Profit Calculation field on the related card.';
                    Visible = false;
                }
                field(lineAmount; Rec."Line Amount")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the amount that will be posted to the project ledger.';
                }
                field(lineAmountLCY; Rec."Line Amount (LCY)")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the amount in the local currency that will be posted to the project ledger.';
                    Visible = false;
                }
                field(lineDiscountAmount; Rec."Line Discount Amount")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the discount amount that is granted for the item on the line.';
                }
                field(lineDiscountPercentage; Rec."Line Discount %")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the line discount percentage.';
                }
                field(totalPrice; Rec."Total Price")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the total price in the project currency on the journal line.';
                    Visible = false;
                }
                field(totalPriceLCY; Rec."Total Price (LCY)")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the total price for the journal line. The amount is in the local currency.';
                    Visible = false;
                }
                field(appliesToEntry; Rec."Applies-to Entry")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies if the project journal line has of type Item and the usage of the item will be applied to an already-posted item ledger entry. If this is the case, enter the entry number that the usage will be applied to.';
                }
                field(appliesFromEntry; Rec."Applies-from Entry")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the number of the item ledger entry that the journal line costs have been applied from. This should be done when you reverse the usage of an item in a project and you want to return the item to inventory at the same cost as before it was used in the project.';
                    Visible = false;
                }
                field(countryRegionCode; Rec."Country/Region Code")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the country/region of the address.';
                    Visible = false;
                }
                field(transactionType; Rec."Transaction Type")
                {
                    ApplicationArea = BasicEU, BasicNO;
                    ToolTip = 'Specifies the type of transaction that the document represents, for the purpose of reporting to INTRASTAT.';
                    Visible = false;
                }
                field(transportMethod; Rec."Transport Method")
                {
                    ApplicationArea = BasicEU, BasicNO;
                    ToolTip = 'Specifies the transport method, for the purpose of reporting to INTRASTAT.';
                    Visible = false;
                }
                field(timeSheetNo; Rec."Time Sheet No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the number of a time sheet. A number is assigned to each time sheet when it is created. You cannot edit the number.';
                    Visible = false;
                }
                field(timeSheetLineNo; Rec."Time Sheet Line No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the line number for a time sheet.';
                    Visible = false;
                }
                field(timeSheetDate; Rec."Time Sheet Date")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the date that a time sheet is created.';
                    Visible = false;
                }
                field(shortcutDimension1Code; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                }
                field(shortcutDimension2Code; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                }
                field(shortcutDimCode3; ShortcutDimCode[3])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,3';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(3),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(3, ShortcutDimCode[3]);
                    end;
                }
                field(shortcutDimCode4; ShortcutDimCode[4])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,4';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(4),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(4, ShortcutDimCode[4]);
                    end;
                }
                field(shortcutDimCode5; ShortcutDimCode[5])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,5';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(5),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(5, ShortcutDimCode[5]);
                    end;
                }
                field(shortcutDimCode6; ShortcutDimCode[6])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,6';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(6),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(6, ShortcutDimCode[6]);
                    end;
                }
                field(shortcutDimCode7; ShortcutDimCode[7])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,7';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(7),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(7, ShortcutDimCode[7]);
                    end;
                }
                field(shortcutDimCode8; ShortcutDimCode[8])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,8';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(8),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(8, ShortcutDimCode[8]);
                    end;
                }
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        JobJnlLine: Record "Job Journal Line";
    begin
        if Rec."Line No." = 0 then begin
            JobJnlLine.Reset();
            JobJnlLine.SetRange("Journal Template Name", Rec."Journal Template Name");
            JobJnlLine.SetRange("Journal Batch Name", Rec."Journal Batch Name");

            if JobJnlLine.FindLast() then
                Rec."Line No." := JobJnlLine."Line No." + 10000
            else
                Rec."Line No." := 10000;
        end;
    end;

    // trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    // var
    //     JobJnlLine: Record "Job Journal Line";
    // begin
    //     if Rec."Line No." = 0 then begin
    //         JobJnlLine.Reset();
    //         JobJnlLine.SetRange("Journal Template Name", Rec."Journal Template Name");
    //         JobJnlLine.SetRange("Journal Batch Name", Rec."Journal Batch Name");

    //         if JobJnlLine.FindLast() then
    //             Rec."Line No." := JobJnlLine."Line No." + 10000
    //         else
    //             Rec."Line No." := 10000;
    //     end;
    //     // exit(false);
    // end;

    var
        JobJnlManagement: Codeunit JobJnlManagement;
        JobDescription: Text[100];
        AccName: Text[100];
        ShortcutDimCode: array[8] of Code[20];
}