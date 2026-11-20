pageextension 50624 "Order Intake Kanban Ext" extends "Order Intake Opt."
{
    actions
    {
        addlast(Processing)
        {
            action(OpenKanbanBoard)
            {
                ApplicationArea = All;
                Caption = 'Kanban Board';
                Image = Grid;
                RunObject = page "DHX Order Intake Kanban";
                ToolTip = 'Open the Kanban board to visualise and manage Order Intake items by status.';
            }
        }
        addlast(Promoted)
        {
            actionref(OpenKanbanBoard_Promoted; OpenKanbanBoard) { }
        }
    }
}
