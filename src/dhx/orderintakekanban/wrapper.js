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

        // ---- Card shape – what fields are visible on each card ----
        var cardShape = {
            label:       true,
            description: true,
            // "start_date" shows the Daytask Date chip at the bottom of the card
            start_date:  { show: true, label: "Date" },
            end_date:    false,
            menu:        true,
            // Coloured top bar driven by the card's "color" property
            color:       true,
            // Priority badge hidden – status is already shown by the column
            priority:    false
        };

        // ---- Initialise Kanban board ----
        kanbanBoard = new KanbanCtor("#kanban-board", {
            columns:   defaultColumns,
            cards:     [],
            cardShape: cardShape
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

        // ---- Card selected ----
        // Fires when the user clicks a card.
        // obj = { id }
        kanbanBoard.api.on("select-card", function (obj) {
            if (obj && obj.id !== undefined) {
                Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("OnCardSelected",
                    [String(obj.id)]);
            }
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
//     "cards":   [{ "id": "1", "label": "Description",
//                   "column": "0", "start_date": "2026-05-01",
//                   "description": "Resource: R001 | Skill: SK1" }, ...]
//   }
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
