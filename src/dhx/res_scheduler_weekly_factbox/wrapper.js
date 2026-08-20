// ============================================================
// DHXGridFactboxAddin - wrapper.js
// Renders the "Chart Audit Trail" FactBox as a pivot-style dhtmlx Suite Grid: a frozen label
// column, 7 weekday groups (each Requested/Assigned/Sub Total), and one Grand Total column.
// Replaces the old flat AL repeater on page 50704 - all pivoting/grouping happens client-side
// against the JSON payload AL hands to LoadData (see BuildGridDataJson in page 50704).
//
// Verified DHTMLX Suite 9.3.7 Grid API (grepped directly from src/dhx/suite.js, same
// grep-don't-guess approach this project already uses for the Chart widget - see
// .claude/agent-memory/al-bc-developer/dhtmlx_suite_chart_api.md):
//   - window.dhx.Grid is a thin ProGrid wrapper (suite.js ~line 50522) that constructs a real
//     ExtendedGrid instance and copies its properties/methods onto itself
//     (core_1.extendComponent) - so `new dhx.Grid(container, config)` behaves exactly like the
//     underlying Grid class for every API used here (events, data, destructor, paint).
//   - Multi-row GROUPED headers: each column's `header` property is an ARRAY, one entry per
//     header row, e.g. `header: [{text:"Monday", colspan:3}, {text:"Requested"}]`. Confirmed by
//     grepping BOTH the real (non-export) header-cell renderer (suite.js ~line 21938,
//     `column.header[0].colspan`, used for resizer-grip sizing) and the shared column-
//     normalization pass (suite.js ~line 1363-1417, `countColumns`) that pads every column's
//     `header` array up to the tallest column's row count with blank `{text:""}` entries - so a
//     column that only needs ONE header row (this grid's "label"/"Grand Total" columns) can
//     declare a single-entry `header` array with `rowspan:2` and let the normalizer pad the
//     second row; a plain `{}` object at header-row index 0 hides that cell entirely under the
//     colspan declared on the FIRST column of a 3-column day group.
//   - Frozen/pinned columns: `config.leftSplit = N` pins the first N columns while the rest
//     scroll horizontally (suite.js ~line 1454/18248, `config.leftSplit = config.leftSplit ||
//     config.splitAt`) - used here to pin the "label" column.
//   - Cell click: `grid.events.on("cellClick", function(row, col, e) {...})` fires with the
//     clicked row's DATA object and the clicked COLUMN CONFIG object (suite.js's
//     `handleMouse`/`getHandlers`, ~line 6136-6168) - not a coordinate/index pair, so drilldown
//     resolution here reads `row.id`/`row.rowType` and `col.id` directly rather than doing any
//     DOM hit-testing (unlike the Chart widget's segment/legend resolvers in
//     src/dhx/barchart_weekly/wrapper.js, which need DOM lookups because dhx.Chart's own click
//     event only carries a bare row id).
//   - Per-cell display formatting: `column.template = function(value, row, column) {...}`
//     returns the HTML to render for that cell (suite.js ~line 1579/18926/23090) - used here to
//     format numbers to 2 decimals and to blank out a skill row's "Assigned" column.
// ============================================================

var gridContainer;        // DOM element reference (readiness flag)
var gridInstance = null;  // current dhx.Grid instance (recreated on every LoadData, same "wipe
                           // and rebuild" convention as src/dhx/barchart_weekly/wrapper.js's
                           // RenderChart)

// ============================================================
// BOOT - called by startupScript.js
// ============================================================
window.BOOT = function() {
    try {
        var addin = document.getElementById("controlAddIn");
        // Flex column: the grid area fills all available space, the export-button row below it
        // is a fixed-height strip - same "create persistent DOM scaffold once in BOOT" convention
        // gridContainer itself already follows; RenderGrid only ever touches gridContainer's
        // contents on refresh, never this outer layout.
        addin.style.cssText = "width:100%;height:100%;margin:0;padding:0;overflow:hidden;display:flex;flex-direction:column;";

        gridContainer = document.createElement("div");
        gridContainer.id = "dhx-pivotgrid-container";
        gridContainer.style.cssText = "flex:1 1 auto;min-height:0;width:100%;";
        addin.appendChild(gridContainer);

        addin.appendChild(BuildExportButtonRow());

        // ---- Check library ----
        if (typeof dhx === "undefined" || !dhx.Grid) {
            console.error("DHTMLX Suite library (suite.js) not found, or its Grid widget is missing. Please include it in ControlAddIn Scripts.");
            return;
        }

        // ---- Render an empty grid so the control has something to show immediately ----
        RenderGrid({ days: [], rows: [] });

        Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("ControlReady", []);
    } catch (e) {
        console.warn("BOOT warning:", e);
    }
};

// Builds the fixed-height row (and its Excel-style export button) that sits below the grid.
// Created exactly once in BOOT - never recreated by RenderGrid - since it addresses the grid
// widget as a whole (gridInstance.export), not any one render's row/column set.
function BuildExportButtonRow() {
    var row = document.createElement("div");
    row.id = "dhx-pivotgrid-export-row";
    row.style.cssText = "flex:0 0 auto;width:100%;padding:6px 8px;box-sizing:border-box;" +
        "display:flex;justify-content:flex-end;background:#fff;border-top:1px solid #d0d0d0;";

    var button = document.createElement("button");
    button.id = "dhx-pivotgrid-export-button";
    button.type = "button";
    button.textContent = "Download to Excel";
    button.style.cssText = "background:#217346;color:#ffffff;border:none;border-radius:3px;" +
        "padding:6px 14px;font-size:12px;font-weight:600;cursor:pointer;";
    button.onmouseover = function() { button.style.background = "#1a5c38"; };
    button.onmouseout = function() { button.style.background = "#217346"; };
    button.onclick = ExportToExcel;

    row.appendChild(button);
    return row;
}

// Click handler for the "Download to Excel" button.
//
// Primary path: dhx.Grid's native export module (gridInstance.export, a suite.js `Exporter`
// instance - grepped from suite.js ~line 19963/22744) via .xlsx(). Per suite.js ~line
// 20371-20374, the xlsx encoder is NOT bundled - it lazy-loads a Web Worker script from
// https://cdn.dhtmlx.com/libs/json2excel/next/worker.js?vx at export time. BC control add-ins
// run inside a somewhat locked-down iframe (see this project's own barchart CSP/network notes),
// so that external fetch may be blocked here; there is no way to confirm without a live browser
// test. If the xlsx export promise rejects, OR simply never settles within a few seconds (in
// case the Exporter API doesn't reject cleanly on a blocked/hung network fetch), this falls back
// to .csv() - grepped from suite.js ~line 20376-20394, fully client-side with no network call at
// all, so it is guaranteed to work regardless of CSP/network restrictions.
function ExportToExcel() {
    if (!gridInstance || !gridInstance.export) {
        console.warn("Export: grid is not ready yet.");
        return;
    }

    var settled = false;
    var fallbackToCsv = function(reason) {
        if (settled) return;
        settled = true;
        console.warn("xlsx export unavailable (" + reason + ") - falling back to CSV export.");
        try {
            gridInstance.export.csv({ name: "DayCapacityAudit" });
        } catch (e) {
            console.error("CSV export fallback also failed:", e);
        }
    };

    var timeoutId = setTimeout(function() { fallbackToCsv("timed out after 5s"); }, 5000);

    try {
        var result = gridInstance.export.xlsx({ name: "DayCapacityAudit" });
        if (result && typeof result.then === "function") {
            result.then(function() {
                settled = true;
                clearTimeout(timeoutId);
            }).catch(function(e) {
                clearTimeout(timeoutId);
                fallbackToCsv("rejected: " + e);
            });
        } else {
            // Exporter.xlsx() didn't return a thenable - assume it completed synchronously.
            settled = true;
            clearTimeout(timeoutId);
        }
    } catch (e) {
        clearTimeout(timeoutId);
        fallbackToCsv("threw synchronously: " + e);
    }
}

// ============================================================
// Build/replace the pivot grid.
//
// gridData shape (see LoadData below, and page 50704's BuildGridDataJson):
//   { days: [ { index: 1, label: "Mon" }, ... one entry per weekday, Monday..Sunday first ],
//     rows: [
//       { id: "CAPACITY", label: "Capacity", rowType: "capacity",
//         d: [ { req: decimal, ass: decimal, sub: decimal }, ... one entry per "days" index ],
//         grand: decimal },
//       { id: "<SkillCode>", label: "<SkillCode>", rowType: "skill",
//         d: [ ... ], grand: decimal },
//       ... one row per active Skill Code
//     ] }
//
// Column ids follow "d<N>_req" / "d<N>_ass" / "d<N>_sub" (N = 1-based index into `days`, NOT a
// calendar weekday number - matches whatever order `days` arrived in) plus the fixed "label" and
// "grand" columns - ResolveDrillDownTarget below parses these back apart.
// ============================================================
function RenderGrid(gridData) {
    if (!gridContainer) return;

    var days = (gridData && Array.isArray(gridData.days)) ? gridData.days : [];
    var rows = (gridData && Array.isArray(gridData.rows)) ? gridData.rows : [];

    var columns = BuildColumns(days);
    var data = BuildRowData(rows);

    if (gridInstance) {
        try { gridInstance.destructor(); } catch (e) { /* ignore */ }
        gridInstance = null;
    }
    gridContainer.innerHTML = "";

    gridInstance = new dhx.Grid(gridContainer, {
        columns: columns,
        data: data,
        leftSplit: 1,          // pins the "label" column while the day groups scroll horizontally
        headerRowHeight: 32,
        rowHeight: 30,
        autoWidth: false,
        resizable: true,
        selection: false,
        tooltip: false
    });

    // Left-click on a data cell -> BC, when that cell maps to a real underlying record set (see
    // ResolveDrillDownTarget's own comment for which cells qualify). Registered fresh on every
    // RenderGrid call since gridInstance itself is torn down/rebuilt each time (no persistent
    // container-level listener needed here, unlike the Chart widget's right-click handler, which
    // has to survive across LoadData calls because chartContainer - not chartInstance - is what
    // persists there).
    gridInstance.events.on("cellClick", function(row, col) {
        var hit = ResolveDrillDownTarget(row, col);
        if (!hit) return;
        try {
            Microsoft.Dynamics.NAV.InvokeExtensibilityMethod(
                "OnCellDrillDown",
                [hit.rowId, hit.rowType, hit.columnKind, hit.dayIndex, hit.wholeWeek]
            );
        } catch (e) { /* ignore */ }
    });
}

// Builds the column set: "label" (pinned, spans both header rows), one 3-column
// Requested/Assigned/Sub Total group per entry in `days` (day name spans the group's 3 columns
// on header row 1, the sub-label sits on header row 2), then "Grand Total" (spans both header
// rows, no sub-columns - a single value per row, per spec).
function BuildColumns(days) {
    var columns = [];

    columns.push({
        id: "label",
        header: [{ text: "" , rowspan: 2}],
        width: 170,
        minWidth: 120,
        template: function(value) {
            return EscapeHtml(value || "");
        }
    });

    days.forEach(function(day, idx) {
        var n = idx + 1;
        var dayLabel = EscapeHtml((day && day.label) ? String(day.label) : ("Day " + n));

        columns.push({
            id: "d" + n + "_req",
            header: [{ text: dayLabel, colspan: 3 }, { text: "Requested" }],
            width: 72,
            minWidth: 60,
            type: "number",
            template: NumberTemplate
        });
        columns.push({
            id: "d" + n + "_ass",
            header: [{}, { text: "Assigned" }],
            width: 72,
            minWidth: 60,
            type: "number",
            template: AssignedTemplate
        });
        columns.push({
            id: "d" + n + "_sub",
            header: [{}, { text: "Sub Total" }],
            width: 72,
            minWidth: 60,
            type: "number",
            css: "dhx-grid-subtotal-cell",
            template: NumberTemplate
        });
    });

    columns.push({
        id: "grand",
        header: [{ text: "Grand Total", rowspan: 2 }],
        width: 90,
        minWidth: 80,
        type: "number",
        css: "dhx-grid-grandtotal-cell",
        template: NumberTemplate
    });

    return columns;
}

// Flattens each AL row object's `d` (per-day) array into the "d<N>_req"/"d<N>_ass"/"d<N>_sub"
// flat keys BuildColumns declared, matching dhx.Grid's own flat-object-per-row data shape.
function BuildRowData(rows) {
    return (rows || []).map(function(r) {
        var row = { id: r.id, label: r.label, rowType: r.rowType, grand: NumOrZero(r.grand) };
        var days = Array.isArray(r.d) ? r.d : [];
        days.forEach(function(d, idx) {
            var n = idx + 1;
            row["d" + n + "_req"] = NumOrZero(d && d.req);
            row["d" + n + "_ass"] = NumOrZero(d && d.ass);
            row["d" + n + "_sub"] = NumOrZero(d && d.sub);
        });
        return row;
    });
}

function NumOrZero(value) {
    return (value === undefined || value === null || value === "") ? 0 : value;
}

// Plain 2-decimal number formatting, shared by every numeric column except a skill row's
// "Assigned" cell (see AssignedTemplate).
function NumberTemplate(value) {
    if (value === undefined || value === null || value === "") return "";
    var n = Number(value);
    if (isNaN(n)) return "";
    return n.toFixed(2);
}

// The "Assigned" column renders blank for a skill row: codeunit 50662 has no per-skill
// assigned-hours tracking anywhere (Assigned Hours is only ever aggregated at the whole-day
// level, see that codeunit's CalcAssignedSplit) - AL always sends 0 for this cell on a skill
// row (see page 50704's AddSkillGridRow), and this template renders it as an intentional blank
// rather than a misleading "0.00", matching the feature spec's explicit "0/blank" instruction.
function AssignedTemplate(value, row) {
    if (row && row.rowType === "skill") return "";
    return NumberTemplate(value);
}

function EscapeHtml(text) {
    return String(text)
        .replace(/&/g, "&amp;")
        .replace(/</g, "&lt;")
        .replace(/>/g, "&gt;");
}

// ============================================================
// Left-click drilldown resolution
// ============================================================

// Resolves a clicked (row, col) pair to the AL-side drilldown call, or null when the cell has no
// single-table drilldown target:
//   - "label" column: never drillable (it is the row's own name, not a value).
//   - "grand" (Grand Total) column: never drillable - it sums 7 days' worth of Sub Totals, which
//     themselves already mix two different record sources for the Capacity row (Day Planning +
//     Res. Capacity Entry) - there is no single table a "Grand Total" click could sensibly open.
//   - "d<N>_sub" (Sub Total) columns: same reasoning as Grand Total, just for one day instead of
//     the whole week - Sub Total = Requested + Assigned, which for the Capacity row means Res.
//     Capacity Entry + Day Planning combined. Not drillable.
//   - "d<N>_ass" on a SKILL row: always 0/blank (see AssignedTemplate) - nothing to drill into.
// Every other "d<N>_req" / "d<N>_ass" cell maps directly to one existing "Day Capacity Chart
// Audit Buf" row (see page 50704's BuildGridDataJson) and IS drillable.
function ResolveDrillDownTarget(row, col) {
    if (!row || !col) return null;
    if (col.id === "label" || col.id === "grand") return null;

    var m = /^d(\d+)_(req|ass|sub)$/.exec(col.id);
    if (!m) return null;

    var dayIndex = parseInt(m[1], 10);
    var kind = m[2];
    if (kind === "sub") return null;
    if (row.rowType === "skill" && kind === "ass") return null;

    return {
        rowId: String(row.id),
        rowType: String(row.rowType),
        columnKind: kind,
        dayIndex: dayIndex,
        wholeWeek: false
    };
}

// ============================================================
// AL-callable: LoadData(gridDataJson)
//   gridDataJson - JSON string, see RenderGrid's comment for the exact shape.
// ============================================================
function LoadData(gridDataJson) {
    try {
        var parsed = ParseJsonTxt(gridDataJson);
        if (!parsed) {
            console.warn("LoadData: could not parse JSON.");
            return;
        }
        RenderGrid(parsed);
    } catch (e) {
        console.error("LoadData error:", e);
    }
}

// ============================================================
// Helpers
// ============================================================
function ParseJsonTxt(txt) {
    if (!txt) return null;
    if (typeof txt === "object") return txt;
    try { return JSON.parse(txt); } catch (e) { return null; }
}
