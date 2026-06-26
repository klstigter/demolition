page 50681 "Work Order Item Pricing"
{
    PageType = List;
    SourceTable = "Work Order Item Pricing";
    Caption = 'Work Order Item Pricing';
    ApplicationArea = All;
    UsageCategory = Lists;
    DataCaptionFields = "Item No.";

    layout
    {
        area(Content)
        {
            group(Filters)
            {
                Caption = 'General';
                field(SalesTypeFilter; SalesTypeOpt)
                {
                    ApplicationArea = All;
                    Caption = 'Sales Type Filter';
                    ToolTip = 'Filter the list by sales type. Leave blank to show all types.';
                    OptionCaption = ' ,Customer,Customer Price Group,All Customers';

                    trigger OnValidate()
                    begin
                        UpdateFilters();
                    end;
                }
                field(SalesCodeFilter; FilterSalesCode)
                {
                    ApplicationArea = All;
                    Caption = 'Sales Code Filter';
                    ToolTip = 'Filter the list by a specific customer or customer price group code.';

                    trigger OnValidate()
                    begin
                        UpdateFilters();
                    end;
                }
                field(ItemNoFilter; FilterItemNo)
                {
                    ApplicationArea = All;
                    Caption = 'Item No. Filter';
                    ToolTip = 'Filter the list by a specific item number.';
                    TableRelation = Item."No.";

                    trigger OnValidate()
                    begin
                        UpdateFilters();
                    end;
                }
                field(StartingDateFilter; FilterStartingDate)
                {
                    ApplicationArea = All;
                    Caption = 'Starting Date Filter';
                    ToolTip = 'Filter the list to show only prices with this starting date.';

                    trigger OnValidate()
                    begin
                        UpdateFilters();
                    end;
                }
                field(CurrencyCodeFilter; FilterCurrencyCode)
                {
                    ApplicationArea = All;
                    Caption = 'Currency Code Filter';
                    ToolTip = 'Filter the list by currency code.';
                    TableRelation = Currency.Code;

                    trigger OnValidate()
                    begin
                        UpdateFilters();
                    end;
                }
            }
            repeater(PriceLines)
            {
                field("Sales Type"; Rec."Sales Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether the price applies to a specific customer, a customer price group, or all customers.';
                }
                field("Sales Code"; Rec."Sales Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the customer or customer price group code this price applies to. Leave blank for All Customers.';
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the item this price applies to.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a description of the item.';
                    Editable = false;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the unit of measure for which this price is defined.';
                }
                field("Minimum Quantity"; Rec."Minimum Quantity")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the minimum quantity the customer must order to get this price.';
                }
                field("Unit Price"; Rec."Unit Price")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the unit price for the item.';
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the date from which this price is valid. Leave blank for no start restriction.';
                }
                field("Ending Date"; Rec."Ending Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the last date this price is valid. Leave blank for no expiry.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the currency for this price. Leave blank for the local currency.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ClearFilters)
            {
                ApplicationArea = All;
                Caption = 'Clear Filters';
                Image = ClearFilter;
                ToolTip = 'Remove all active filters and show the full price list.';
                trigger OnAction()
                begin
                    SalesTypeOpt    := SalesTypeOpt::" ";
                    FilterSalesCode := '';
                    FilterItemNo    := '';
                    FilterStartingDate := 0D;
                    FilterCurrencyCode := '';
                    UpdateFilters();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';
                actionref(ClearFilters_Ref; ClearFilters) { }
            }
        }
    }

    trigger OnOpenPage()
    begin
        UpdateFilters();
    end;

    var
        SalesTypeOpt: Option " ",Customer,"Customer Price Group","All Customers";
        FilterSalesCode: Code[20];
        FilterItemNo: Code[20];
        FilterStartingDate: Date;
        FilterCurrencyCode: Code[10];

    local procedure UpdateFilters()
    begin
        // Sales Type filter
        case SalesTypeOpt of
            SalesTypeOpt::" ":
                Rec.SetRange("Sales Type");
            SalesTypeOpt::Customer:
                Rec.SetRange("Sales Type", "WO Item Price Sales Type"::Customer);
            SalesTypeOpt::"Customer Price Group":
                Rec.SetRange("Sales Type", "WO Item Price Sales Type"::"Customer Price Group");
            SalesTypeOpt::"All Customers":
                Rec.SetRange("Sales Type", "WO Item Price Sales Type"::"All Customers");
        end;

        if FilterSalesCode <> '' then
            Rec.SetRange("Sales Code", FilterSalesCode)
        else
            Rec.SetRange("Sales Code");

        if FilterItemNo <> '' then
            Rec.SetRange("Item No.", FilterItemNo)
        else
            Rec.SetRange("Item No.");

        if FilterStartingDate <> 0D then
            Rec.SetRange("Starting Date", FilterStartingDate)
        else
            Rec.SetRange("Starting Date");

        if FilterCurrencyCode <> '' then
            Rec.SetRange("Currency Code", FilterCurrencyCode)
        else
            Rec.SetRange("Currency Code");

        CurrPage.Update(false);
    end;
}
