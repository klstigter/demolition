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
                    EntryNoInt: Integer;
                    NewStatusInt: Integer;
                begin
                    if Evaluate(EntryNoInt, EntryNo) and Evaluate(NewStatusInt, NewStatus) then
                        KanbanHandler.UpdateCardStatus(EntryNoInt, NewStatusInt);
                end;

                // ----------------------------------------------------------------
                // OnCardSelected – user clicked a card; open the record card.
                // ----------------------------------------------------------------
                trigger OnCardSelected(EntryNo: Text)
                var
                    OrderIntake: Record "Order Intake Header Opt.";
                    EntryNoInt: Integer;
                begin
                    if Evaluate(EntryNoInt, EntryNo) then
                        if OrderIntake.Get(EntryNoInt) then
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
                    EntryNoInt: Integer;
                begin
                    if Evaluate(EntryNoInt, EntryNo) then begin
                        KanbanHandler.DuplicateCard(EntryNoInt);
                        CurrPage.DhxKanban.RefreshKanbanData(KanbanHandler.BuildKanbanJson());
                    end;
                end;

                // ----------------------------------------------------------------
                // OnCardDeleted – user clicked Delete on a card menu.
                // Delete the record from BC and refresh the board.
                // ----------------------------------------------------------------
                trigger OnCardDeleted(EntryNo: Text)
                var
                    KanbanHandler: Codeunit "Order Intake Kanban Handler";
                    EntryNoInt: Integer;
                begin
                    if Evaluate(EntryNoInt, EntryNo) then begin
                        KanbanHandler.DeleteCard(EntryNoInt);
                        CurrPage.DhxKanban.RefreshKanbanData(KanbanHandler.BuildKanbanJson());
                    end;
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
