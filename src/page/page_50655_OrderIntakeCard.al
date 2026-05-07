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
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    trigger OnAssistEdit()
                    begin
                        if Rec.AssistEdit(xRec) then
                            CurrPage.Update();
                    end;
                }
                field("Order Date"; Rec."Order Date")
                {
                    ApplicationArea = All;
                }
                field("Status"; Rec."Status")
                {
                    ApplicationArea = All;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    MultiLine = true;
                }
            }
            part(OrderLines; "Order Intake Sub Card")
            {
                ApplicationArea = All;
                SubPageLink = "Document No." = field("No.");
            }
        }
    }

    actions
    {
        area(Processing)
        {
            /// <summary>
            /// Opens the "Generate Pre Daytasks" dialog (page 50657) and, if the
            /// user confirms, invokes codeunit 50613 to insert planning lines into
            /// table 50608 "Order Intake Line Opt." for the current document.
            /// </summary>
            action(GeneratePreDaytasks)
            {
                Caption = 'Generate pre Daytasks';
                ApplicationArea = All;
                Image = Process;
                ToolTip = 'Opens a dialog to configure scheduling parameters and generate preliminary Daytask planning lines for this Order Intake document.';

                trigger OnAction()
                var
                    GenerateDlg: Page "Generate Pre Daytasks";
                    PreDaytaskGen: Codeunit "Pre Daytask Generator";
                    RequestBuf: Record "Pre Daytask Request Buf.";
                    LinesCreated: Integer;
                    SuccessMsg: Label '%1 pre-Daytask line(s) were created for Order Intake %2.', Comment = '%1 = number of lines, %2 = document number';
                begin
                    // Pass document context to the dialog before opening
                    GenerateDlg.SetContext(Rec."No.", Rec.Description);

                    if GenerateDlg.RunModal() = Action::OK then begin
                        // Retrieve the completed request buffer from the dialog
                        GenerateDlg.GetRequestBuffer(RequestBuf);

                        // Execute the generation logic (validates + creates lines)
                        LinesCreated := PreDaytaskGen.GenerateLines(RequestBuf, Rec."No.");

                        // Refresh the subform to show the newly created lines
                        CurrPage.Update(false);

                        Message(SuccessMsg, LinesCreated, Rec."No.");
                    end;
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Actions';
                actionref(Action_ref_1; GeneratePreDaytasks) { }
            }
        }
    }

    var
        myInt: Integer;
}