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
    ///   { "id": "1", "column": "0", "label": "...", "description": "[Short Description]",
    ///     "longDescription": "[Long Description]", "start_date": "YYYY-MM-DD" }
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

                // Card shows two lines: No. as title, Short Description as secondary line (blank if empty, no placeholder text).
                // 'description' is the DHTMLX built-in key: it drives BOTH the mini-card
                // subtitle and the "Short Description" box in the edit panel.
                // 'longDescription' is a custom editorShape field – edit panel only.
                Card.Add('label', Format(OrderIntake."No."));
                Card.Add('description', OrderIntake."Short Description");
                Card.Add('longDescription', HtmlToPlainText(OrderIntake.GetDescription()));

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

    local procedure HtmlToPlainText(HtmlText: Text): Text
    var
        Regex: Codeunit Regex;
        TypeHelper: Codeunit "Type Helper";
        PlainText: Text;
    begin
        if HtmlText = '' then
            exit('');

        PlainText := HtmlText;
        // Turn paragraph/line breaks into real newlines before the tags are stripped,
        // so multi-paragraph content stays readable as plain text in the Kanban textarea.
        PlainText := Regex.Replace(PlainText, '</p>\s*<p[^>]*>', TypeHelper.NewLine());
        PlainText := Regex.Replace(PlainText, '<br\s*/?>', TypeHelper.NewLine());
        PlainText := Regex.Replace(PlainText, '<[^>]+>', '');
        PlainText := TypeHelper.HtmlDecode(PlainText);
        exit(PlainText);
    end;

    local procedure PlainTextToHtml(PlainText: Text): Text
    var
        TypeHelper: Codeunit "Type Helper";
        HtmlText: Text;
    begin
        if PlainText = '' then
            exit('');

        HtmlText := TypeHelper.HtmlEncode(PlainText);
        HtmlText := HtmlText.Replace(TypeHelper.CRLFSeparator(), '<br>');
        HtmlText := HtmlText.Replace(TypeHelper.LFSeparator(), '<br>');
        exit('<p>' + HtmlText + '</p>');
    end;

    /// <summary>
    /// Updates the Status of a single DayPlanning Order Intake record.
    /// Called when the user drags a card to a different column on the board.
    /// </summary>
    /// <param name="EntryNo">Primary key of the record to update.</param>
    /// <param name="NewStatusInt">Integer value of the target Status enum.</param>
    procedure UpdateCardStatus(EntryNo: Code[20]; NewStatusInt: Integer)
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
    /// Updates both the Long Description and Short Description of a single Order Intake
    /// record from a Kanban card edit.
    /// </summary>
    /// <param name="EntryNo">Primary key of the record to update.</param>
    /// <param name="NewLongDescription">Value of the custom "longDescription" Kanban field – written to the Description blob.</param>
    /// <param name="NewShortDescription">Value of the built-in "description" Kanban field – written to "Short Description".</param>
    procedure UpdateCardDescriptions(EntryNo: Code[20]; NewLongDescription: Text; NewShortDescription: Text)
    var
        OrderIntake: Record "Order Intake Header Opt.";
    begin
        if not OrderIntake.Get(EntryNo) then
            exit;
        OrderIntake.Validate("Short Description", CopyStr(NewShortDescription, 1, MaxStrLen(OrderIntake."Short Description")));
        OrderIntake.Modify(true);
        OrderIntake.SetDescription(PlainTextToHtml(NewLongDescription));
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
    procedure DuplicateCard(SourceEntryNo: Code[20])
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
    procedure DeleteCard(EntryNo: Code[20])
    var
        OrderIntake: Record "Order Intake Header Opt.";
    begin
        if OrderIntake.Get(EntryNo) then
            OrderIntake.Delete(true);
    end;
}
