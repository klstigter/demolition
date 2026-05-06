codeunit 50661 "Order Intake Kanban Handler"
{
    trigger OnRun()
    begin
    end;

    /// <summary>
    /// Builds the JSON payload consumed by the Kanban board.
    /// Returns a JSON object with two keys:
    ///   "columns" – one entry per Status enum value.
    ///   "cards"   – one entry per Daytask Order Intake record.
    ///
    /// Card JSON shape:
    ///   { "id": "1", "column": "0", "label": "...", "description": "...", "start_date": "YYYY-MM-DD" }
    /// </summary>
    procedure BuildKanbanJson(): Text
    var
        OrderIntake: Record "Daytask Order Intake Opt.";
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
                Card.Add('id', Format(OrderIntake."Entry No."));

                // Map Status enum integer → column id
                Card.Add('column', Format(StatusInt));

                // Card title – use Description; fall back to "Entry <N>"
                if OrderIntake.Description <> '' then
                    Card.Add('label', OrderIntake.Description)
                else
                    Card.Add('label', StrSubstNo('Entry %1', OrderIntake."Entry No."));

                // Coloured top bar: status colour
                Card.Add('color', GetStatusColor(StatusInt));

                // CSS class for description text colouring (status-0 .. status-3)
                Card.Add('css', 'status-' + Format(StatusInt));

                // Description: HH:MM – HH:MM  |  ResourceNo  |  Skill
                // Times come first – most prominent info on the card face
                CardDesc := '';
                TimeLine := '';
                if OrderIntake."Daytask Start" <> 0T then
                    TimeLine := Format(OrderIntake."Daytask Start", 0, '<Hours24,2>:<Minutes,2>');
                if OrderIntake."Daytask End" <> 0T then begin
                    if TimeLine <> '' then TimeLine += ' - ';
                    TimeLine += Format(OrderIntake."Daytask End", 0, '<Hours24,2>:<Minutes,2>');
                end;
                if TimeLine <> '' then
                    CardDesc := TimeLine;
                if OrderIntake."Resource No." <> '' then begin
                    if CardDesc <> '' then CardDesc += '  |  ';
                    CardDesc += OrderIntake."Resource No.";
                end;
                if OrderIntake.Skill <> '' then begin
                    if CardDesc <> '' then CardDesc += '  |  ';
                    CardDesc += 'Skill: ' + OrderIntake.Skill;
                end;
                if CardDesc <> '' then
                    Card.Add('description', CardDesc);

                // Daytask Date displayed as the card date chip
                if OrderIntake."Daytask Date" <> 0D then
                    Card.Add('start_date',
                        Format(OrderIntake."Daytask Date", 0, '<Year4>-<Month,2>-<Day,2>'));

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
    /// Updates the Status of a single Daytask Order Intake record.
    /// Called when the user drags a card to a different column on the board.
    /// </summary>
    /// <param name="EntryNo">Primary key of the record to update.</param>
    /// <param name="NewStatusInt">Integer value of the target Status enum.</param>
    procedure UpdateCardStatus(EntryNo: Integer; NewStatusInt: Integer)
    var
        OrderIntake: Record "Daytask Order Intake Opt.";
        NewStatus: Enum "Daytask Order Intake Status";
    begin
        if not OrderIntake.Get(EntryNo) then
            exit;

        NewStatus := Enum::"Daytask Order Intake Status".FromInteger(NewStatusInt);

        if OrderIntake.Status = NewStatus then
            exit; // No change – nothing to write

        OrderIntake.Status := NewStatus;
        OrderIntake.Modify(true);
    end;
}
