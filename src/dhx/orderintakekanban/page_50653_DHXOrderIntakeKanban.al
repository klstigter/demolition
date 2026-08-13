page 50653 "DHX Order Intake Kanban"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Tasks;
    Caption = 'Order Intake Kanban Board';

    layout
    {
        area(content)
        {
            usercontrol(DhxKanban; DHXKanbanAddin)
            {
                ApplicationArea = All;

                // ----------------------------------------------------------------
                // ControlReady – board is initialised; load data from the table.
                // ----------------------------------------------------------------
                trigger ControlReady()
                var
                    KanbanHandler: Codeunit "Order Intake Kanban Handler";
                begin
                    CurrPage.DhxKanban.LoadKanbanData(KanbanHandler.BuildKanbanJson());
                end;

                // ----------------------------------------------------------------
                // OnCardMoved – user dragged a card to a different column.
                // Update the Status field in the database.
                // ----------------------------------------------------------------
                trigger OnCardMoved(EntryNo: Text; NewStatus: Text)
                var
                    KanbanHandler: Codeunit "Order Intake Kanban Handler";
                    NewStatusInt: Integer;
                begin
                    if Evaluate(NewStatusInt, NewStatus) then
                        KanbanHandler.UpdateCardStatus(CopyStr(EntryNo, 1, 20), NewStatusInt);
                end;

                // ----------------------------------------------------------------
                // OnCardUpdated – user edited a card's fields (Short Description
                // and/or Long Description) in the detail panel. Save the new
                // values back to BC. The board already applied the edit locally,
                // so no refresh is needed here.
                // ShortDescription comes from the built-in "description" field,
                // LongDescription from the custom "longDescription" field.
                // ----------------------------------------------------------------
                trigger OnCardUpdated(EntryNo: Text; LongDescription: Text; ShortDescription: Text)
                var
                    KanbanHandler: Codeunit "Order Intake Kanban Handler";
                begin
                    KanbanHandler.UpdateCardDescriptions(CopyStr(EntryNo, 1, 20), LongDescription, ShortDescription);
                end;

                // ----------------------------------------------------------------
                // OnCardSelected – user clicked a card; open the record card.
                // ----------------------------------------------------------------
                trigger OnCardSelected(EntryNo: Text)
                var
                    OrderIntake: Record "Order Intake Header Opt.";
                begin
                    if OrderIntake.Get(CopyStr(EntryNo, 1, 20)) then
                        Page.Run(Page::"Order Intake Opt.", OrderIntake);
                end;

                // ----------------------------------------------------------------
                // OnCardAdded – user submitted "Add new card".
                // Insert a new record in BC and refresh the board.
                // ----------------------------------------------------------------
                trigger OnCardAdded(ColumnId: Text; Label: Text)
                var
                    KanbanHandler: Codeunit "Order Intake Kanban Handler";
                    ColumnIdInt: Integer;
                begin
                    if not Evaluate(ColumnIdInt, ColumnId) then
                        ColumnIdInt := 0;
                    KanbanHandler.InsertCard(ColumnIdInt, Label);
                    CurrPage.DhxKanban.RefreshKanbanData(KanbanHandler.BuildKanbanJson());
                end;

                // ----------------------------------------------------------------
                // OnCardDuplicated – user clicked Duplicate on a card menu.
                // Copy the record in BC and refresh the board.
                // ----------------------------------------------------------------
                trigger OnCardDuplicated(EntryNo: Text; ColumnId: Text)
                var
                    KanbanHandler: Codeunit "Order Intake Kanban Handler";
                begin
                    KanbanHandler.DuplicateCard(CopyStr(EntryNo, 1, 20));
                    CurrPage.DhxKanban.RefreshKanbanData(KanbanHandler.BuildKanbanJson());
                end;

                // ----------------------------------------------------------------
                // OnCardDeleted – user clicked Delete on a card menu.
                // Delete the record from BC and refresh the board.
                // ----------------------------------------------------------------
                trigger OnCardDeleted(EntryNo: Text)
                var
                    KanbanHandler: Codeunit "Order Intake Kanban Handler";
                begin
                    KanbanHandler.DeleteCard(CopyStr(EntryNo, 1, 20));
                    CurrPage.DhxKanban.RefreshKanbanData(KanbanHandler.BuildKanbanJson());
                end;

                // ----------------------------------------------------------------
                // OnOrderIntakeCardRequested – user clicked "Order Intake" on a
                // card's "..." menu. Open the full Order Intake Card page (unlike
                // OnCardSelected, which opens the list page 50651 on double-click).
                // ----------------------------------------------------------------
                trigger OnOrderIntakeCardRequested(EntryNo: Text)
                var
                    OrderIntake: Record "Order Intake Header Opt.";
                begin
                    if OrderIntake.Get(CopyStr(EntryNo, 1, 20)) then
                        Page.Run(Page::"Order Intake Card", OrderIntake);
                end;

                // ----------------------------------------------------------------
                // OnCardCustomerSelected – user picked a Customer in the editor
                // panel's combo. Validate (this also derives the Primary Contact,
                // if any) and push the confirmed values back onto the card.
                // ----------------------------------------------------------------
                trigger OnCardCustomerSelected(EntryNo: Text; CustomerNo: Text)
                var
                    OrderIntake: Record "Order Intake Header Opt.";
                    KanbanHandler: Codeunit "Order Intake Kanban Handler";
                begin
                    if not OrderIntake.Get(CopyStr(EntryNo, 1, 20)) then
                        exit;
                    OrderIntake.Validate("Customer No.", CopyStr(CustomerNo, 1, 20));
                    OrderIntake.Modify(true);
                    CurrPage.DhxKanban.UpdateCardFields(EntryNo, KanbanHandler.BuildCardFieldsJson(OrderIntake));
                end;

                // ----------------------------------------------------------------
                // OnCardContactSelected – user picked a Contact in the editor
                // panel's combo. Validate (this also derives/validates the related
                // Customer) and push the confirmed values back onto the card.
                // Errors naturally (standard BC dialog) if the contact is not
                // related to any customer – UpdateCardFields is then never
                // reached, so the JS side stays untouched by design.
                // ----------------------------------------------------------------
                trigger OnCardContactSelected(EntryNo: Text; ContactNo: Text)
                var
                    OrderIntake: Record "Order Intake Header Opt.";
                    KanbanHandler: Codeunit "Order Intake Kanban Handler";
                begin
                    if not OrderIntake.Get(CopyStr(EntryNo, 1, 20)) then
                        exit;
                    OrderIntake.Validate("Contact No.", CopyStr(ContactNo, 1, 20));
                    OrderIntake.Modify(true);
                    CurrPage.DhxKanban.UpdateCardFields(EntryNo, KanbanHandler.BuildCardFieldsJson(OrderIntake));
                end;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Refresh)
            {
                ApplicationArea = All;
                Caption = 'Refresh';
                Image = Refresh;
                ToolTip = 'Reload all cards from the database.';

                trigger OnAction()
                var
                    KanbanHandler: Codeunit "Order Intake Kanban Handler";
                begin
                    CurrPage.DhxKanban.RefreshKanbanData(KanbanHandler.BuildKanbanJson());
                end;
            }
        }
        area(Promoted)
        {
            actionref(Refresh_Promoted; Refresh) { }
        }
    }
}
