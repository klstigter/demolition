page 50633 "Opti Job Card"
{
    Caption = 'Opti Job Card';
    PageType = document;
    RefreshOnActivate = true;
    sourceTable = "Job";
    AdditionalSearchTerms = 'Optimized Job Card Planning';

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    Importance = Standard;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                    Visible = NoFieldVisible;

                    trigger OnAssistEdit()
                    begin
                        if Rec.AssistEdit(xRec) then
                            CurrPage.Update();
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies a short description of the project.';
                }
                field("Sell-to Customer No."; Rec."Sell-to Customer No.")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Customer No.';
                    Importance = Additional;
                    NotBlank = true;
                    ToolTip = 'Specifies the number of the customer who will receive the products and be billed by default.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field("Person Responsible"; Rec."Person Responsible")
                {
                    ApplicationArea = Jobs;
                    Importance = Promoted;
                    ToolTip = 'Specifies the person at your company who is responsible for the project.';
                }
                field("Project Manager"; Rec."Project Manager")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the person who is assigned to manage the project.';
                }
                field("No. of Archived Versions"; Rec."No. of Archived Versions")
                {
                    ApplicationArea = Jobs;
                    Importance = Additional;
                    ToolTip = 'Specifies the number of archived versions of this project.';
                }
            }
            part(JobTaskLines; "Opti Job Task Lines Subform")
            {
                ApplicationArea = Jobs;
                Caption = 'Tasks';
                SubPageLink = "Job No." = field("No.");
                SubPageView = sorting("Job Task No.")
                              order(ascending);
                UpdatePropagation = Both;
                Editable = JobTaskLinesEditable;
                Enabled = JobTaskLinesEditable;
            }
        }
    }

    actions
    {

    }


    trigger OnOpenPage()
    var
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
    begin
        SetNoFieldVisible();
        ActivateFields();
        ExtendedPriceEnabled := PriceCalculationMgt.IsExtendedPriceCalculationEnabled();
    end;


    trigger OnAfterGetCurrRecord()
    begin
        if GuiAllowed() then
            SetControlVisibility();
    end;

    trigger OnAfterGetRecord()
    begin
        if GuiAllowed() then
            SetControlVisibility();
        JobTaskLinesEditable := Rec.CalcJobTaskLinesEditable();
        CurrPage.JobTaskLines.Page.SetPerTaskBillingFieldsVisible(Rec."Task Billing Method" = Rec."Task Billing Method"::"Multiple customers");
        CurrPage.Update(false);
    end;

    var
        FormatAddress: Codeunit "Format Address";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        JobArchiveManagement: Codeunit "Job Archive Management";
        EmptyShipToCodeErr: Label 'The Code field can only be empty if you select Custom Address in the Ship-to field.';
        NoFieldVisible: Boolean;
        JobTaskLinesEditable: Boolean;
        ExtendedPriceEnabled: Boolean;
        IsBillToCountyVisible: Boolean;
        IsSellToCountyVisible: Boolean;
        IsShipToCountyVisible: Boolean;
        BillToInformationEditable: Boolean;
        ShouldSearchForCustByName: Boolean;

    local procedure SetNoFieldVisible()
    var
        DocumentNoVisibility: Codeunit DocumentNoVisibility;
    begin
        NoFieldVisible := DocumentNoVisibility.JobNoIsVisible();
    end;

    local procedure ActivateFields()
    begin
        IsBillToCountyVisible := FormatAddress.UseCounty(Rec."Bill-to Country/Region Code");
        IsSellToCountyVisible := FormatAddress.UseCounty(Rec."Sell-to Country/Region Code");
        IsShipToCountyVisible := FormatAddress.UseCounty(Rec."Ship-to Country/Region Code");
    end;

    local procedure SetControlVisibility()
    begin
        ShouldSearchForCustByName := Rec.ShouldSearchForCustomerByName(Rec."Sell-to Customer No.");
    end;


}