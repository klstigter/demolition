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
var _cardValues   = {};     // { [cardId]: { customer, contact } } - last known-good Customer/
                             // Contact per card, used by the "update-card" interceptor below to
                             // detect which field actually changed. The Form panel's own commit
                             // function (kanban.js: `function E(){e.api.exec("update-card",
                             // {card:{...i()},id:i().id})}`) spreads the ENTIRE current form
                             // state into every update-card call, not just the edited field - so
                             // "obj.card.customer !== undefined" is ALWAYS true (customer is
                             // always present, even when only Contact was edited). Comparing
                             // against the previously-known value per card is what actually
                             // detects a real change. Populated from LoadKanbanData's cards
                             // array and refreshed in UpdateCardFields after BC confirms.
var _editorShape  = null;   // Live reference to the editorShape array passed to the Kanban
                             // constructor. Its "customer"/"contact" combo field ".values"
                             // are populated exactly once, from the "customerOptions"/
                             // "contactOptions" arrays included in the board-load JSON (see
                             // BuildKanbanJson in codeunit 50661) and applied inside
                             // LoadKanbanData below, in the SAME kanbanBoard.parse({...}) call
                             // that already applies columns/cards.
                             //
                             // IMPORTANT: this must NEVER be done on a per-card-open basis.
                             // kanban.js's setConfig() -> this.api.getStores().data.init({...})
                             // unconditionally ends with this._router.init(y);
                             // this.setState({_edit:null, selected:null, ...}) - i.e. ANY call
                             // to kanbanBoard.parse(...), regardless of which keys are passed,
                             // resets the "_edit" state that keeps the editor side-panel open.
                             // An earlier version of this file called parse({ editorShape })
                             // from a "set-edit" listener (fired when the panel opened) to push
                             // fresh combo options per card - that immediately reset _edit back
                             // to null and closed the panel it had just opened. Loading the
                             // options once at board-load time (LoadKanbanData only ever runs
                             // at true (re)load time, never as a side-effect of opening a
                             // panel) avoids ever calling parse() while a panel is open.

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
            // Overriding menu.items with a fixed array (same pattern as
            // columnShape.menu below) to add the custom "Order Intake" entry
            // alongside the library's built-in Duplicate/Delete actions.
            menu: {
                items: [
                    { id: "duplicate-card", icon: "wxi-content-copy", text: "Duplicate" },
                    { id: "delete-card", icon: "wxi-delete-outline", text: "Delete" },
                    {
                        id: "order-intake-card",
                        icon: "wxi-external",
                        text: "Order Intake",
                        onClick: function (ctx) {
                            if (ctx && ctx.card && ctx.card.id !== undefined) {
                                Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("OnOrderIntakeCardRequested",
                                    [String(ctx.card.id)]);
                            }
                        }
                    }
                ]
            },
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
            // Customer / Contact combos – DHTMLX-native "combo" field type (confirmed in
            // kanban.js: the same shape already used by the library's own default "Priority"
            // field). Options come from the field's own "values" array (an array of
            // { id, label } objects – confirmed from kanban.js's option rendering, which
            // reads option.label) and are populated once from the board-load JSON's
            // "customerOptions"/"contactOptions" (see LoadKanbanData below) rather than
            // baked in here. "config: { clear: true }" shows a clear/x button, matching
            // the built-in Priority combo's config.
            { key: "customer",        type: "combo",    label: "Customer", config: { clear: true }, values: [] },
            { key: "contact",         type: "combo",    label: "Contact",  config: { clear: true }, values: [] },
            { key: "color",           type: "color",    label: "Color", config: { clear: true } },
            { key: "start_date",      type: "date",     label: "Order Date" }
        ];
        _editorShape = editorShape; // keep a live reference for populating combo values in LoadKanbanData

        // ---- Column shape – locks down column-STRUCTURE editing ----
        // Columns must always mirror the "DayPlanning Order Intake Status" enum
        // 1:1 (see BuildKanbanJson in codeunit 50661), so the column set itself
        // has to stay read-only: no Add column, no Rename (label would desync
        // from the BC enum caption), no Move left/right (reorder), no Delete.
        // The library's default column "..." menu (see Go() in kanban.js) is
        // { add-card, set-edit(Rename), move-column:left, move-column:right,
        // delete-column }. Overriding menu.items with a fixed array keeps only
        // "Add new card" – a per-card operation, not a column-structure edit,
        // and unrelated to card drag-between-columns (handled separately by
        // the "move-card" event below).
        var columnShape = {
            menu: {
                items: [
                    { id: "add-card", icon: "wxi-plus", text: "Add new card" }
                ]
            }
        };

        // ---- Initialise Kanban board ----
        kanbanBoard = new KanbanCtor("#kanban-board", {
            columns:     defaultColumns,
            cards:       [],
            cardShape:   cardShape,
            columnShape: columnShape,
            editorShape: editorShape
        });

        // ---- Initialise Toolbar ----
        // Explicit "items" list – library default also includes { type: "addColumn" }
        // (the "Add new column" "+" button, see qm() in kanban.js) which is omitted
        // here so no column-add affordance is shown. "addRow" is kept: this board
        // never configures rows/swimlanes (LoadKanbanData never sends "rows"), so
        // it is inert and out of scope for this column-structure lock-down.
        kanbanToolbar = new ToolbarCtor("#kanban-toolbar", {
            api: kanbanBoard.api,
            items: ["search", "spacer", "undo", "redo", "sort", "addRow"]
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
        // Fires when the user edits a card's fields in the detail panel.
        //
        // Description/longDescription still use the original "apply immediately, sync to
        // BC after" flow (the library's own local update applies right away for a
        // responsive UI - see the trailing `return true` below).
        //
        // Customer/Contact are different: picking either one must go through BC's
        // Customer<->Contact relation logic (table 50604 OnValidate), which can derive the
        // OTHER field's value or reject the pick outright (e.g. a Contact with no related
        // Customer). So those two are intercepted and BLOCKED locally (`return false`) until
        // BC calls back with the confirmed values via UpdateCardFields.
        //
        // obj = { id, card: {...fullCardObject}, $meta? }
        //
        // Mapping (must stay in sync with BuildKanbanJson in AL):
        //   card.description     → Short Description  (built-in field)
        //   card.longDescription → Long Description   (custom field)
        //   card.customer        → Customer No.        (custom combo field)
        //   card.contact         → Contact No.          (custom combo field)
        //
        // Confirmed in kanban.js: the intercept chain (`async exec(t,e){const
        // n=this._handlers[t]; ... if(a===!1...) return; ... this._nextHandler.exec(t,e)`)
        // runs every registered interceptor for an action; ONLY a literal `false` return
        // stops the chain (blocking the real local update). Any other return value lets it
        // fall through to the real handler - so the description/longDescription path below
        // can coexist with the blocking customer/contact paths in the same interceptor.
        //
        // IMPORTANT: obj.card is NOT a delta of just the edited field - the Form panel's own
        // commit function spreads the WHOLE current form state into every update-card call
        // (kanban.js: `function E(){e.api.exec("update-card",{card:{...i()},id:i().id})}`).
        // So "obj.card.customer !== undefined" is true on EVERY panel edit, not just when
        // Customer was actually changed - checking for key presence alone mis-routed real
        // Contact picks through the Customer-selected handler (which then no-ops since
        // Customer was unchanged, silently discarding the Contact pick). Comparing against
        // the last known-good value per card (_cardValues) is what actually detects which
        // field the user changed.
        kanbanBoard.api.intercept("update-card", function (obj) {
            if (!obj || obj.id === undefined || !obj.card) return true;

            // Programmatic push FROM BC (see UpdateCardFields) after BC has already
            // validated/derived the final values - apply locally without re-raising
            // OnCardCustomerSelected/OnCardContactSelected (that would just loop back to BC).
            if (obj.$meta && obj.$meta.fromBC) return true;

            var prev = _cardValues[obj.id] || {};
            var customerChanged = obj.card.customer !== undefined &&
                String(obj.card.customer || "") !== String(prev.customer || "");
            var contactChanged = obj.card.contact !== undefined &&
                String(obj.card.contact || "") !== String(prev.contact || "");

            if (customerChanged) {
                Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("OnCardCustomerSelected",
                    [String(obj.id), String(obj.card.customer || "")]);
                return false; // block local apply until BC confirms (and derives Contact / may error)
            }
            if (contactChanged) {
                Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("OnCardContactSelected",
                    [String(obj.id), String(obj.card.contact || "")]);
                return false; // block local apply until BC confirms (and derives Customer / may error)
            }

            var shortDesc = (obj.card.description !== undefined) ? String(obj.card.description) : "";
            var longDesc  = (obj.card.longDescription !== undefined) ? String(obj.card.longDescription) : "";
            Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("OnCardUpdated", [String(obj.id), longDesc, shortDesc]);
            return true; // let the library apply this update locally (unchanged behaviour)
        });

        // ---- "Open Order Intake" button in the editor panel ----
        // The library's editorShape only supports data-bound field types (text/textarea/
        // combo/color/date - confirmed via kanban.js's field-type switch, no "button" type
        // exists), so this is injected directly into the panel's DOM rather than declared as
        // an editorShape entry. It reuses the EXISTING "OnOrderIntakeCardRequested" event/AL
        // trigger already wired up for the card menu's "Order Intake" item - no AL changes
        // needed, just a second UI entry point into the same action.
        //
        // The panel container is `.wx-sidebar` (confirmed in kanban.js). Svelte may tear down
        // and rebuild its contents on every card switch, so a one-shot DOM query right after
        // "set-edit" fires can race the re-render; a MutationObserver on the board container
        // is what reliably (re-)inserts the button whenever the panel's DOM actually changes.
        // ensureOrderIntakeButton() is idempotent (checks for an existing button by id before
        // creating a new one) so the observer firing on our own insertion does not loop.
        var _currentEditCardId = null;

        function ensureOrderIntakeButton() {
            if (!_currentEditCardId) return;
            var sidebar = boardDiv.querySelector(".wx-sidebar");
            if (!sidebar) return;
            var btn = sidebar.querySelector("#order-intake-open-btn");
            if (!btn) {
                btn = document.createElement("button");
                btn.id = "order-intake-open-btn";
                btn.type = "button";
                btn.textContent = "Open Order Intake";
                btn.style.cssText = "margin:12px 16px 0 16px;padding:6px 14px;border:1px solid #3b82f6;" +
                    "border-radius:4px;background:#fff;color:#3b82f6;cursor:pointer;font-size:13px;" +
                    "align-self:flex-start;flex:0 0 auto;";
                sidebar.insertBefore(btn, sidebar.firstChild);
            }
            // Re-bind on every call so the closure always targets the currently-open card,
            // even when the same button element is being reused across card switches.
            btn.onclick = function () {
                Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("OnOrderIntakeCardRequested",
                    [String(_currentEditCardId)]);
            };
        }

        kanbanBoard.api.on("set-edit", function (obj) {
            _currentEditCardId = (obj && obj.cardId !== undefined) ? obj.cardId : null;
            setTimeout(ensureOrderIntakeButton, 0);
        });

        new MutationObserver(function () {
            ensureOrderIntakeButton();
        }).observe(boardDiv, { childList: true, subtree: true });

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
        var data             = JSON.parse(jsonText);
        var columns          = data.columns || [];
        var cards            = data.cards   || [];
        var customerOptions  = data.customerOptions || [];
        var contactOptions   = data.contactOptions  || [];

        // Convert ISO date strings to Date objects for DHTMLX
        cards.forEach(function (c) {
            if (c.start_date && typeof c.start_date === "string")
                c.start_date = new Date(c.start_date);
            if (c.end_date && typeof c.end_date === "string")
                c.end_date = new Date(c.end_date);
        });

        // Refresh the last known-good Customer/Contact per card (see _cardValues comment
        // above) so the "update-card" interceptor can detect real changes after this load.
        _cardValues = {};
        cards.forEach(function (c) {
            if (c.id !== undefined) {
                _cardValues[c.id] = { customer: c.customer || "", contact: c.contact || "" };
            }
        });

        // Populate the Customer/Contact combo "values" in place, once, from this
        // load's payload - see the _editorShape comment above for why this must
        // happen only here (true board load) and never as a side-effect of the
        // editor panel opening.
        if (_editorShape) {
            var customerField = _editorShape.find(function (f) { return f.key === "customer"; });
            if (customerField) customerField.values = customerOptions;
            var contactField = _editorShape.find(function (f) { return f.key === "contact"; });
            if (contactField) contactField.values = contactOptions;
        }

        kanbanBoard.parse({ editorShape: _editorShape, columns: columns, cards: cards });

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

// ============================================================
// UpdateCardFields
// Called from AL: CurrPage.DhxKanban.UpdateCardFields(EntryNo, FieldsJson)
// Pushes BC-confirmed field values (e.g. after Customer/Contact validation) onto a
// single card. Tagged with $meta.fromBC so the "update-card" interceptor above applies
// it locally without re-raising OnCardCustomerSelected/OnCardContactSelected.
// ============================================================
window.UpdateCardFields = function (entryNo, fieldsJson) {
    if (!_kanbanReady || !kanbanBoard) return;
    try {
        var fields = JSON.parse(fieldsJson); // { customer, contact }
        _cardValues[String(entryNo)] = { customer: fields.customer || "", contact: fields.contact || "" };
        kanbanBoard.api.exec("update-card", {
            id: String(entryNo),
            card: fields,
            $meta: { fromBC: true, skipHistory: true }
        });
    } catch (err) {
        console.error("UpdateCardFields error:", err);
    }
};
