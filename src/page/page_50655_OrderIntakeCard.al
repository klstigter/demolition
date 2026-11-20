page 50655 "Order Intake Card"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "Order Intake Header Opt.";
    Caption = 'Order Intake';

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                grid(HeaderGrid)
                {
                    GridLayout = Columns;

                    group(Col1)
                    {
                        ShowCaption = false;

                        field("No."; Rec."No.")
                        {
                            ApplicationArea = All;
                            trigger OnAssistEdit()
                            begin
                                if rec.AssistEdit(rec) then
                                    CurrPage.Update();
                            end;
                        }

                        field("Order Date"; Rec."Order Date")
                        {
                            ApplicationArea = All;
                        }
                        field("Short Description"; Rec."Short Description")
                        {
                            ApplicationArea = All;
                        }
                    }

                    group(Col2)
                    {
                        ShowCaption = false;

                        field("Customer No."; Rec."Customer No.")
                        {
                            ApplicationArea = All;

                            trigger OnValidate()
                            begin
                                CurrPage.OrderLines.PAGE.SetEditable(Rec."Customer No." <> '');
                            end;
                        }

                        field(Status; Rec.Status)
                        {
                            ApplicationArea = All;
                        }
                    }

                    group(Col3)
                    {
                        ShowCaption = false;

                        field("Customer Name"; Rec."Customer Name")
                        {
                            ApplicationArea = All;
                        }

                        field("Contact No."; Rec."Contact No.")
                        {
                            ApplicationArea = All;
                        }
                    }
                }
            }
            Group(Description)
            {
                Caption = 'Long Description';
                usercontrol(RichTextEditor; DHXRichTextAddin)
                {
                    ApplicationArea = All;

                    /// <summary>
                    /// Fires once when the DHTMLX RichText editor is ready.
                    /// Load the current record's blob content into the editor.
                    /// </summary>
                    trigger ControlReady()
                    begin
                        AddinReady := true;
                        CurrPage.RichTextEditor.SetValue(Rec.GetDescription());
                    end;

                    /// <summary>
                    /// Fires ~800 ms after the user stops typing (debounced in JS).
                    /// Persist the HTML into the blob field on the record.
                    /// </summary>
                    trigger OnTextChanged(Html: Text)
                    begin
                        Rec.SetDescription(Html);
                    end;
                }
            }
            part(OrderLines; "Project Task Sub")
            {
                ApplicationArea = All;
                SubPageLink = "Order Intake No." = field("No.");
            }
        }
    }

    actions
    {
        area(Processing)
        {

        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Actions';

            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        // Push the blob content into the editor whenever the record changes.
        // Guard with AddinReady: on first load ControlReady fires the initial load.
        if AddinReady then
            CurrPage.RichTextEditor.SetValue(Rec.GetDescription());

        CurrPage.OrderLines.PAGE.SetEditable(Rec."Customer No." <> '');
    end;

    var
        AddinReady: Boolean;
}