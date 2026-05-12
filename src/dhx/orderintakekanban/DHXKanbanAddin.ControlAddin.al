controladdin DHXKanbanAddin
{
    RequestedHeight = 800;
    MinimumHeight = 400;
    VerticalShrink = true;
    VerticalStretch = true;

    RequestedWidth = 1400;
    MinimumWidth = 600;
    HorizontalStretch = true;
    HorizontalShrink = true;

    Scripts =
        'src/dhx/kanban.js',
        'src/dhx/orderintakekanban/wrapper.js';

    StartupScript = 'src/dhx/orderintakekanban/startupScript.js';

    StyleSheets =
        'src/dhx/kanban.css',
        'src/dhx/orderintakekanban/custom.css';

    /// <summary>Fired when the Kanban board is fully initialised and ready to receive data.</summary>
    event ControlReady();

    /// <summary>
    /// Fired when the user drags a card to a different column.
    /// EntryNo  – the Entry No. of the moved record (as text).
    /// NewStatus – the integer value of the new Status column (as text).
    /// </summary>
    event OnCardMoved(EntryNo: Text; NewStatus: Text);

    /// <summary>
    /// Fired when the user clicks/selects a card.
    /// EntryNo – the Entry No. of the selected record (as text).
    /// </summary>
    event OnCardSelected(EntryNo: Text);

    /// <summary>
    /// Fired when the user submits the "Add new card" form.
    /// ColumnId – the target Status column integer (as text).
    /// Label    – the card title entered by the user.
    /// BC should insert the record and refresh the board.
    /// </summary>
    event OnCardAdded(ColumnId: Text; Label: Text);

    /// <summary>
    /// Fired when the user clicks Duplicate on a card menu.
    /// EntryNo  – Entry No. of the source record.
    /// ColumnId – column where the duplicate will appear (same column by default).
    /// BC should copy the record and refresh the board.
    /// </summary>
    event OnCardDuplicated(EntryNo: Text; ColumnId: Text);

    /// <summary>
    /// Fired when the user clicks Delete on a card menu.
    /// EntryNo – Entry No. of the record to delete.
    /// BC should delete the record and refresh the board.
    /// </summary>
    event OnCardDeleted(EntryNo: Text);

    /// <summary>
    /// Loads (or replaces) all board data.
    /// JsonText must be: { "columns": [...], "cards": [...] }
    /// </summary>
    procedure LoadKanbanData(JsonText: Text);

    /// <summary>Refreshes the board by replacing all data. Same effect as LoadKanbanData.</summary>
    procedure RefreshKanbanData(JsonText: Text);

    /// <summary>
    /// Moves a single card to a different column from the AL side
    /// (e.g. after a status change made outside the Kanban board).
    /// EntryNo   – string representation of the Entry No.
    /// NewStatus – string representation of the Status integer value.
    /// </summary>
    procedure UpdateCardStatus(EntryNo: Text; NewStatus: Text);
}
