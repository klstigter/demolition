codeunit 50661 "Order Intake Kanban Handler"
{
    trigger OnRun()
    begin
    end;

    /// <summary>
    /// Builds the JSON payload consumed by the Kanban board.
    /// Returns a JSON object with two keys:
    ///   "columns" – one entry per Status enum value.
    ///   "cards"   – one entry per DayPlanning Order Intake record.
    ///
    /// Card JSON shape:
    ///   { "id": "1", "column": "0", "label": "...", "description": "...", "start_date": "YYYY-MM-DD" }
    /// </summary>
    procedure BuildKanbanJson(): Text
    var
        OrderIntake: Record "Order Intake Header Opt.";
        Columns: JsonArray;
        Cards: JsonArray;
        Root: JsonObject;
        Col: JsonObject;
        Card: JsonObject;
        CardDesc: Text;
        TimeLine: Text;
        Result: Text;
        StatusInt: Integer;
    begin
        // ---- Columns – one per Status enum value ----
        Clear(Col);
        Col.Add('id', '0');
        Col.Add('label', 'Open');
        Columns.Add(Col);
        Clear(Col);
        Col.Add('id', '1');
        Col.Add('label', 'Ready');
        Columns.Add(Col);
        Clear(Col);
        Col.Add('id', '2');
        Col.Add('label', 'Released');
        Columns.Add(Col);
        Clear(Col);
        Col.Add('id', '3');
        Col.Add('label', 'Done');
        Columns.Add(Col);

        // ---- Cards – one per Order Intake record ----
        if OrderIntake.FindSet() then
            repeat
                Clear(Card);
                StatusInt := OrderIntake.Status.AsInteger();

                // Primary key used as the card ID on the board
                Card.Add('id', Format(OrderIntake."No."));

                // Map Status enum integer → column id
                Card.Add('column', Format(StatusInt));

                // Card shows two lines: No. as title, Short Description as secondary line (blank if empty, no placeholder text)
                Card.Add('label', Format(OrderIntake."No."));
                Card.Add('description', OrderIntake."Short Description");

                // Coloured top bar: status colour
                Card.Add('color', GetStatusColor(StatusInt));

                // CSS class for description text colouring (status-0 .. status-3)
                Card.Add('css', 'status-' + Format(StatusInt));

                // Order Date displayed as the card date chip
                if OrderIntake."Order Date" <> 0D then
                    Card.Add('start_date',
                        Format(OrderIntake."Order Date", 0, '<Year4>-<Month,2>-<Day,2>'));

                Cards.Add(Card);
            until OrderIntake.Next() = 0;

        Root.Add('columns', Columns);
        Root.Add('cards', Cards);
        Root.WriteTo(Result);
        exit(Result);
    end;

    local procedure GetStatusColor(StatusInt: Integer): Text
    begin
        case StatusInt of
            0:
                exit('#22c55e'); // Open     – vivid green
            1:
                exit('#3b82f6'); // Ready    – vivid blue
            2:
                exit('#f59e0b'); // Released – amber
            3:
                exit('#8b5cf6'); // Done     – purple
            else
                exit('#6c757d');
        end;
    end;

    /// <summary>
    /// Updates the Status of a single DayPlanning Order Intake record.
    /// Called when the user drags a card to a different column on the board.
    /// </summary>
    /// <param name="EntryNo">Primary key of the record to update.</param>
    /// <param name="NewStatusInt">Integer value of the target Status enum.</param>
    procedure UpdateCardStatus(EntryNo: Integer; NewStatusInt: Integer)
    var
        OrderIntake: Record "Order Intake Header Opt.";
        NewStatus: Enum "DayPlanning Order Intake Status";
    begin
        if not OrderIntake.Get(EntryNo) then
            exit;

        NewStatus := Enum::"DayPlanning Order Intake Status".FromInteger(NewStatusInt);

        if OrderIntake.Status = NewStatus then
            exit; // No change – nothing to write

        OrderIntake.Status := NewStatus;
        OrderIntake.Modify(true);
    end;

    /// <summary>
    /// Inserts a new DayPlanning Order Intake record from the Kanban "Add new card" action.
    /// </summary>
    /// <param name="ColumnIdInt">Status integer from the target column.</param>
    /// <param name="CardLabel">Card title entered by the user – stored as Description.</param>
    procedure InsertCard(ColumnIdInt: Integer; CardLabel: Text)
    var
        OrderIntake: Record "Order Intake Header Opt.";
    begin
        OrderIntake.Init();
        OrderIntake.Status := Enum::"DayPlanning Order Intake Status".FromInteger(ColumnIdInt);
        OrderIntake."Order Date" := Today();
        OrderIntake.Insert(true);
    end;

    /// <summary>
    /// Duplicates an existing DayPlanning Order Intake record.
    /// The new record inherits all field values from the source; Entry No. is auto-assigned.
    /// </summary>
    /// <param name="SourceEntryNo">Entry No. of the record to copy.</param>
    procedure DuplicateCard(SourceEntryNo: Integer)
    var
        Source: Record "Order Intake Header Opt.";
        New: Record "Order Intake Header Opt.";
    begin
        if not Source.Get(SourceEntryNo) then
            exit;

        New := Source;
        New."No." := ''; // AutoIncrement will assign the next value
        New.Insert(true);
    end;

    /// <summary>
    /// Deletes a DayPlanning Order Intake record.
    /// </summary>
    /// <param name="EntryNo">Primary key of the record to delete.</param>
    procedure DeleteCard(EntryNo: Integer)
    var
        OrderIntake: Record "Order Intake Header Opt.";
    begin
        if OrderIntake.Get(EntryNo) then
            OrderIntake.Delete(true);
    end;
}
