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
                    OrderIntake: Record "Daytask Order Intake Opt.";
                    EntryNoInt: Integer;
                begin
                    if Evaluate(EntryNoInt, EntryNo) then
                        if OrderIntake.Get(EntryNoInt) then
                            Page.Run(Page::"Daytask Order Intake Opt.", OrderIntake);
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
