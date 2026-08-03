// ============================================================
// DHX Order Intake Kanban – wrapper.js
// Follows the same pattern as resourceschedule/wrapper.js
// ============================================================

// ============================================================
// State
// ============================================================
var kanbanBoard   = null;   // Kanban board instance
var kanbanToolbar = null;   // Toolbar instance
var _kanbanReady  = false;  // True once BOOT() completes successfully

// ============================================================
// BOOT – called by startupScript.js once the DOM is ready
// ============================================================
window.BOOT = function () {
    try {
        // ---- Root container ----
        var addIn = document.getElementById("controlAddIn");
        addIn.style.cssText = "width:100%;height:100%;display:flex;flex-direction:column;overflow:hidden;margin:0;padding:0;";

        // Toolbar container
        var toolbarDiv = document.createElement("div");
        toolbarDiv.id = "kanban-toolbar";
        addIn.appendChild(toolbarDiv);

        // Board container
        var boardDiv = document.createElement("div");
        boardDiv.id = "kanban-board";
        boardDiv.style.cssText = "flex:1;overflow:auto;min-height:0;";
        addIn.appendChild(boardDiv);

        // ---- Verify library is present ----
        if (typeof kanban === "undefined") {
            console.error("DHX Kanban library (kanban.js) not found. Ensure it is listed in ControlAddIn Scripts.");
            return;
        }

        var KanbanCtor  = kanban.Kanban;
        var ToolbarCtor = kanban.Toolbar;

        // ---- Default columns – match Status enum values ----
        // Actual data is loaded later via LoadKanbanData() from AL.
        var defaultColumns = [
            { id: "0", label: "Open"     },
            { id: "1", label: "Ready"    },
            { id: "2", label: "Released" },
            { id: "3", label: "Done"     }
        ];

        // ---- Card shape – what is visible on the MINI CARD in the column list ----
        // NOTE: the built-in "description" property is a SINGLE value that drives
        // the mini-card subtitle. The card JSON built in AL therefore puts the
        // *Short Description* in the "description" key (see BuildKanbanJson).
        var cardShape = {
            label:       true,
            description: true,
            // "start_date" shows the DayPlanning Date chip at the bottom of the card
            start_date:  { show: true, label: "Date" },
            end_date:    false,
            menu:        true,
            // Coloured top bar driven by the card's "color" property
            color:       true,
            // Priority badge hidden – status is already shown by the column
            priority:    false
        };

        // ---- Editor shape – what is visible in the DETAIL/EDIT side panel ----
        // IMPORTANT: this is a TOP-LEVEL Kanban option, a sibling of cardShape.
        // A "fields" array nested inside cardShape is silently ignored by the
        // library (kanban.js reads config.editorShape in _normalizeShapes, and
        // never reads cardShape.fields).
        //
        // Supplying editorShape REPLACES the library default
        // (defaultEditorShape.filter(f => cardShape[f.key].show)), so every field
        // we want in the panel must be listed here explicitly.
        //
        // Each entry's "label" is run through the kanban i18n dictionary, which
        // falls back to the literal string when there is no translation – so
        // custom captions like "Long Description" render verbatim. The caption
        // element is only emitted when the label is a non-empty string.
        var editorShape = [
            { key: "label",           type: "text",     label: "Label" },
            // Built-in description key → Short Description (Text[100])
            { key: "description",     type: "textarea", label: "Short Description" },
            // Custom field → Long Description blob. Custom entries only ever
            // render in this panel, never on the mini card – exactly the
            // isolation we need.
            { key: "longDescription", type: "textarea", label: "Long Description" },
            { key: "color",           type: "color",    label: "Color", config: { clear: true } },
            { key: "start_date",      type: "date",     label: "Start date" }
        ];

        // ---- Initialise Kanban board ----
        kanbanBoard = new KanbanCtor("#kanban-board", {
            columns:     defaultColumns,
            cards:       [],
            cardShape:   cardShape,
            editorShape: editorShape
        });

        // ---- Initialise Toolbar ----
        kanbanToolbar = new ToolbarCtor("#kanban-toolbar", {
            api: kanbanBoard.api
        });

        // ---- Card moved (drag & drop) ----
        // Fires when the user moves a card to another column.
        // obj = { id, columnId, rowId, before, source }
        kanbanBoard.api.on("move-card", function (obj) {
            if (obj && obj.id !== undefined && obj.columnId !== undefined) {
                Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("OnCardMoved",
                    [String(obj.id), String(obj.columnId)]);
            }
        });

        // ---- Card double-clicked → navigate to the BC record ----
        // Single click only opens the library's own built-in edit side-panel
        // (automatic library behaviour, driven internally by its "select-card"
        // store action — nothing we need to wire up). Double click is not a
        // first-class Kanban API event, so we listen for the native DOM
        // "dblclick" on the board container and walk up from the click target
        // to find the card element.
        //
        // Verified in kanban.js: the card root <div class="wx-card ..."> is the
        // SAME element that receives the "data-id" attribute (Q(w,"data-id",
        // e.cardFields.id) is called on the same `w` that was created as the
        // wx-card div) - so a single closest(".wx-card") lookup already carries
        // the id; no separate ancestor/descendant walk is needed. Other
        // data-id-bearing elements in the library (column headers, the card
        // context menu, calendar cells, virtual-scroll wrappers) never carry
        // the wx-card class, so gating on ".wx-card" excludes them.
        boardDiv.addEventListener("dblclick", function (e) {
            var cardEl = e.target.closest ? e.target.closest(".wx-card") : null;
            if (!cardEl) return;
            var id = cardEl.getAttribute("data-id");
            if (id) {
                Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("OnCardSelected",
                    [String(id)]);
            }
        });

        // ---- Card updated (detail panel edit) ----
        // Fires when the user edits a card's fields in the detail panel and the
        // change is applied. Use .on() (not .intercept()) so the library's own
        // local update still applies immediately (responsive UI); we just push
        // the change to BC afterward. No board refresh needed.
        // obj = { id, card: {...fullCardObject} }
        //
        // Mapping (must stay in sync with BuildKanbanJson in AL):
        //   card.description     → Short Description  (built-in field)
        //   card.longDescription → Long Description   (custom field)
        kanbanBoard.api.on("update-card", function (obj) {
            if (obj && obj.id !== undefined) {
                var shortDesc = (obj.card && obj.card.description !== undefined) ? String(obj.card.description) : "";
                var longDesc  = (obj.card && obj.card.longDescription !== undefined) ? String(obj.card.longDescription) : "";
                Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("OnCardUpdated", [String(obj.id), longDesc, shortDesc]);
            }
        });

        // ---- Add new card ----
        // Intercept BEFORE the board inserts the card locally.
        // BC creates the record and refreshes the whole board.
        // obj = { columnId, before, rowId, card: { label, ... } }
        kanbanBoard.api.intercept("add-card", function (obj) {
            var colId = (obj && obj.columnId !== undefined) ? String(obj.columnId) : "0";
            var label = (obj && obj.card && obj.card.label) ? String(obj.card.label) : "";
            Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("OnCardAdded", [colId, label]);
            return false; // prevent local board insert – BC will refresh
        });

        // ---- Duplicate card ("Duplicate" in the card menu) ----
        // obj = { id, columnId, before, rowId }
        kanbanBoard.api.intercept("copy-card", function (obj) {
            if (obj && obj.id !== undefined) {
                var colId = (obj.columnId !== undefined) ? String(obj.columnId) : "";
                Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("OnCardDuplicated",
                    [String(obj.id), colId]);
            }
            return false; // prevent local duplicate – BC will refresh
        });

        // ---- Delete card ("Delete" in the card menu) ----
        // obj = { id }
        kanbanBoard.api.intercept("delete-card", function (obj) {
            if (obj && obj.id !== undefined) {
                Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("OnCardDeleted",
                    [String(obj.id)]);
            }
            return false; // prevent local delete – BC will refresh
        });

        _kanbanReady = true;

        // Signal BC: add-in is initialised and ready to receive data.
        Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("ControlReady", []);

    } catch (err) {
        console.error("DHX Kanban BOOT error:", err);
    }
};

// ============================================================
// LoadKanbanData
// Called from AL: CurrPage.DhxKanban.LoadKanbanData(JsonText)
//
// Expected JSON structure:
//   {
//     "columns": [{ "id": "0", "label": "Open" }, ...],
//     "cards":   [{ "id": "1", "label": "OI0001",
//                   "column": "0", "start_date": "2026-05-01",
//                   "description": "<Short Description>",
//                   "longDescription": "<Long Description blob text>" }, ...]
//   }
//
// "description" is the built-in key – it drives the mini-card subtitle AND the
// "Short Description" box in the edit panel. "longDescription" is our custom
// editorShape field and appears in the edit panel only.
// ============================================================
window.LoadKanbanData = function (jsonText) {
    if (!_kanbanReady || !kanbanBoard) return;
    try {
        var data    = JSON.parse(jsonText);
        var columns = data.columns || [];
        var cards   = data.cards   || [];

        // Convert ISO date strings to Date objects for DHTMLX
        cards.forEach(function (c) {
            if (c.start_date && typeof c.start_date === "string")
                c.start_date = new Date(c.start_date);
            if (c.end_date && typeof c.end_date === "string")
                c.end_date = new Date(c.end_date);
        });

        kanbanBoard.parse({ columns: columns, cards: cards });

    } catch (err) {
        console.error("LoadKanbanData error:", err);
    }
};

// ============================================================
// RefreshKanbanData
// Called from AL: CurrPage.DhxKanban.RefreshKanbanData(JsonText)
// Replaces all board data – same as LoadKanbanData.
// ============================================================
window.RefreshKanbanData = function (jsonText) {
    window.LoadKanbanData(jsonText);
};

// ============================================================
// UpdateCardStatus
// Called from AL: CurrPage.DhxKanban.UpdateCardStatus(EntryNo, NewStatus)
// Moves a single card to the specified column without triggering
// another OnCardMoved event back to BC.
// ============================================================
window.UpdateCardStatus = function (entryNo, newStatus) {
    if (!_kanbanReady || !kanbanBoard) return;
    try {
        kanbanBoard.api.exec("move-card", {
            id:       String(entryNo),
            columnId: String(newStatus)
        });
    } catch (err) {
        console.error("UpdateCardStatus error:", err);
    }
};
