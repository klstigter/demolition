"""
generate_resource_absence_management_doc.py
Generates the technical design document for "Resource Absence Management"
(review draft - no code implemented yet) as a Word (.docx) file using python-docx.

Run:  python generate_resource_absence_management_doc.py
Output: Resource Absence Management.docx  (same folder as this script)
"""

from docx import Document
from docx.shared import Pt, Cm, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml.ns import qn
from docx.oxml import OxmlElement
import datetime, os

# ─── helpers ────────────────────────────────────────────────────────────────────

def set_cell_bg(cell, hex_color: str):
    tc = cell._tc
    tcPr = tc.get_or_add_tcPr()
    shd = OxmlElement('w:shd')
    shd.set(qn('w:val'), 'clear')
    shd.set(qn('w:color'), 'auto')
    shd.set(qn('w:fill'), hex_color)
    tcPr.append(shd)


def header_row(table, *texts, bg='1F3964'):
    row = table.rows[0]
    for i, text in enumerate(texts):
        if i >= len(row.cells):
            break
        cell = row.cells[i]
        set_cell_bg(cell, bg)
        p = cell.paragraphs[0]
        run = p.add_run(text)
        run.bold = True
        run.font.color.rgb = RGBColor(0xFF, 0xFF, 0xFF)
        run.font.size = Pt(10)


def data_row(table, *values, shade=False):
    row = table.add_row()
    for i, val in enumerate(values):
        if i >= len(row.cells):
            break
        cell = row.cells[i]
        if shade:
            set_cell_bg(cell, 'EBF3FB')
        p = cell.paragraphs[0]
        p.add_run(str(val)).font.size = Pt(10)
    return row


def add_table(doc, col_widths_cm, *header_texts, bg='1F3964'):
    cols = len(header_texts)
    tbl = doc.add_table(rows=1, cols=cols)
    tbl.style = 'Table Grid'
    header_row(tbl, *header_texts, bg=bg)
    if col_widths_cm:
        for j, w in enumerate(col_widths_cm):
            for row in tbl.rows:
                row.cells[j].width = Cm(w)
    return tbl


def add_code(doc, code: str):
    """Monospace code block with light-blue background."""
    for line in code.split('\n'):
        para = doc.add_paragraph()
        para.style = doc.styles['No Spacing']
        run = para.add_run(line if line else ' ')
        run.font.name = 'Courier New'
        run.font.size = Pt(9)
        run.font.color.rgb = RGBColor(0x1F, 0x39, 0x64)
        pPr = para._p.get_or_add_pPr()
        shd = OxmlElement('w:shd')
        shd.set(qn('w:val'), 'clear')
        shd.set(qn('w:color'), 'auto')
        shd.set(qn('w:fill'), 'EDF2F8')
        pPr.append(shd)
    doc.add_paragraph()


def info_box(doc, text: str, label='Note', color='D6E4F7'):
    tbl = doc.add_table(rows=1, cols=1)
    tbl.style = 'Table Grid'
    cell = tbl.cell(0, 0)
    set_cell_bg(cell, color)
    p = cell.paragraphs[0]
    run = p.add_run(f'{label}\n{text}')
    run.font.size = Pt(10)
    doc.add_paragraph()


def h(doc, text, level=1):
    return doc.add_heading(text, level=level)


def p(doc, text=''):
    return doc.add_paragraph(text)


def bullet(doc, text):
    return doc.add_paragraph(text, style='List Bullet')


# ════════════════════════════════════════════════════════════════════════════════
# BUILD DOCUMENT
# ════════════════════════════════════════════════════════════════════════════════

doc = Document()

for section in doc.sections:
    section.top_margin    = Cm(2.5)
    section.bottom_margin = Cm(2.5)
    section.left_margin   = Cm(2.5)
    section.right_margin  = Cm(2.5)

# ── TITLE PAGE ────────────────────────────────────────────────────────────────

t = doc.add_paragraph()
t.alignment = WD_ALIGN_PARAGRAPH.CENTER
r = t.add_run('Resource Absence Management')
r.bold = True; r.font.size = Pt(24); r.font.color.rgb = RGBColor(0x1F, 0x39, 0x64)

s = doc.add_paragraph()
s.alignment = WD_ALIGN_PARAGRAPH.CENTER
s.add_run('DailyOptimizer Extension - Technical Design (Review Draft, no code implemented yet)').font.size = Pt(14)

doc.add_paragraph()
m = doc.add_paragraph()
m.alignment = WD_ALIGN_PARAGRAPH.CENTER
m.add_run(
    f'Extension: DailyOptimizer  |  Publisher: Optimizers  |  Version: 28.0.0.3\n'
    f'BC Runtime: 15.0  |  Generated: {datetime.datetime.now().strftime("%d %B %Y %H:%M")}'
).font.size = Pt(10)

doc.add_paragraph()
info_box(doc,
    'This document is a REVIEW DRAFT. No AL code has been written yet. Section 9 lists '
    'the open questions that should be confirmed before implementation starts.',
    label='Status', color='FFF2CC')

doc.add_page_break()

# ── 1. BACKGROUND & OBJECTIVE ─────────────────────────────────────────────────

h(doc, '1. Background & Objective')
p(doc,
  'Microsoft Dynamics 365 Business Central does not support Absence tracking for '
  'Resources. Absence functionality only exists in the Human Resources module, and is '
  'limited to Employees (table 5202 "Employee Absence", reason table 5206 "Cause of '
  'Absence"). Resources - the entity DailyOptimizer schedules capacity and Day Planning '
  'against - have no equivalent.')
p(doc,
  'Objective: develop a Resource Absence feature so that Resource capacity calculations '
  'account for absence hours, without duplicating or replacing the existing standard '
  'Resource Capacity infrastructure (table 160 "Res. Capacity Entry", the "Update '
  'Resource Capacity" wizard, and the capacity aggregation already used throughout this '
  'extension - see Section 8).')

# ── 2. DESIGN SUMMARY ─────────────────────────────────────────────────────────

h(doc, '2. Design Summary')
p(doc,
  'Table 160 "Res. Capacity Entry" is extended, rather than introducing a parallel '
  'absence table, so that every existing SUM/FlowField/query that already reads '
  '"Res. Capacity Entry".Capacity keeps working with zero code changes - it will simply '
  'net Capacity against Absence automatically, because Absence is stored as a NEGATIVE '
  'value in that same Capacity field.')

tbl = add_table(doc, [4, 13], 'Rule', 'Detail')
rules = [
    ('New "Type" field', 'Enum "Res. Capacity Entry Type": 0 = Capacity, 1 = Absence. All existing rows default to 0 (Capacity) - fully backward compatible.'),
    ('Absence = negative Capacity', 'An Absence entry reuses the standard "Start Time"/"End Time" fields and writes its Hours into the same "Capacity" field, but negated.'),
    ('Existing-capacity guard', 'An Absence row cannot be entered for a Resource/Date that has no Capacity row already - see Section 5.'),
]
for i, r in enumerate(rules):
    data_row(tbl, *r, shade=(i % 2 == 0))
doc.add_paragraph()

h(doc, '2.1  Worked Example', 2)
tbl = add_table(doc, [1.5, 5, 3, 3], '#', 'Date', 'Type', 'Hours')
example = [
    ('1', '1 Aug 2026', 'Capacity', '5'),
    ('2', '1 Aug 2026', 'Capacity', '7'),
    ('3', '1 Aug 2026', 'Absence', '-4'),
]
for i, r in enumerate(example):
    data_row(tbl, *r, shade=(i % 2 == 0))
doc.add_paragraph()
info_box(doc,
    'Total Resource Capacity for 1 Aug 2026 = 5 + 7 + (-4) = 8. No separate "net capacity" '
    'calculation is introduced - the existing SUM(Capacity) already produces this result.',
    label='Result', color='C6EFCE')

# ── 3. DATA MODEL CHANGES ─────────────────────────────────────────────────────

h(doc, '3. Data Model Changes')
p(doc,
  'All new fields are added to the existing table extension 50606 "ResCapacityEntry '
  'Opt" (which already extends table 160 "Res. Capacity Entry" with "Start Time", '
  '"End Time", "Duplicate Id" and the "Requested Hours" FlowField - see the extract in '
  'Section 3.2). No new base table is required for the capacity/absence ledger itself.')

h(doc, '3.1  New Fields on Table Extension 50606', 2)
tbl = add_table(doc, [1.3, 4.8, 4.0, 8.9],
                'Field No.', 'Field Name', 'Type', 'Purpose')
field_rows = [
    ('50605', 'Type', 'Enum "Res. Capacity Entry Type"',
     'Capacity (0, default) or Absence (1). Drives every validation rule in Section 5.'),
    ('50606', 'Absence Reason Code', 'Code[10]',
     'TableRelation to table 5206 "Cause of Absence" (the exact reason table standard '
     'Employee Absence already uses - reused as-is, no new setup table). Mandatory on '
     'Absence rows, blank on Capacity rows.'),
]
for i, r in enumerate(field_rows):
    data_row(tbl, *r, shade=(i % 2 == 0))
doc.add_paragraph()

info_box(doc,
    'No separate "Capacity Entry No." link field is needed. Because Absence rows are '
    'ordinary rows in the same table 160, they are already identified by the standard '
    '"Resource No." + Date (+ "Duplicate Id") combination - the same combination the '
    'existing-capacity guard (Section 5.1) validates against and Query 50604 groups by. '
    'A stored back-reference to the specific Capacity row would be redundant data that '
    'could itself go stale (e.g. if that Capacity row is later deleted/regenerated).',
    label='Simplification', color='C6EFCE')

h(doc, '3.2  Existing Table Extension 50606 (for reference, unchanged fields shown)', 2)
p(doc, 'Current state of src/tableext/tableext_50606_ResourceCapacityEntry.al, which the fields above will be added to:')
add_code(doc,
r"""tableextension 50606 "ResCapacityEntry Opt" extends "Res. Capacity Entry"
{
    fields
    {
        field(50600; "Start Time"; Time) { DataClassification = ToBeClassified; }
        field(50601; "End Time"; Time) { DataClassification = ToBeClassified; }
        field(50602; "Duplicate Id"; Integer)
        {
            DataClassification = ToBeClassified;
            InitValue = 1;
        }
        field(50604; "Requested Hours"; Decimal)
        {
            Editable = false;
            fieldclass = FlowField;
            calcformula = sum("Day Planning"."Assigned Hours"
                where("Assigned Resource No." = field("Resource No."),
                      "Task Date" = field("Date")));
        }

        // --- new fields proposed by this design (50605-50606) ---
    }
}""")

h(doc, '3.3  New Enum 50682 "Res. Capacity Entry Type"', 2)
add_code(doc,
r"""enum 50682 "Res. Capacity Entry Type"
{
    Extensible = true;

    value(0; Capacity) { Caption = 'Capacity'; }
    value(1; Absence) { Caption = 'Absence'; }
}""")

h(doc, '3.4  Base Table 160 "Res. Capacity Entry" (unchanged, for reference)', 2)
p(doc, 'Confirmed via symbol search - the standard fields and keys this design builds on:')
tbl = add_table(doc, [4, 5, 8], 'Key', 'Fields', 'Relevance to this design')
base_keys = [
    ('Key1 (PK)', '"Entry No."', 'Auto-numbered Integer. Absence rows get their own Entry No. like any other row - no separate link field is stored (Section 3.1).'),
    ('Key2', '"Resource No.", Date', 'Used by the existing-capacity guard (Section 5) to find the matching Capacity row.'),
    ('Key3', '"Resource Group No.", Date', 'Unaffected by this design.'),
]
for i, r in enumerate(base_keys):
    data_row(tbl, *r, shade=(i % 2 == 0))

# ── 4. OBJECT ID PLAN ─────────────────────────────────────────────────────────

h(doc, '4. New / Changed Object ID Plan')
p(doc,
  'The app''s id range is 50600-60700 (app.json). Highest IDs currently in use top out '
  'around 50681 in the low sub-range, so new objects below take the next free IDs '
  'starting at 50682.')

tbl = add_table(doc, [2.6, 1.6, 5.6, 2.0, 5.3],
                'Object Type', 'Object ID', 'Object Name', 'Status', 'Purpose')
rows = [
    ('Enum',            '50682', 'Res. Capacity Entry Type',   'NEW',      'Capacity / Absence classification (Section 3.3)'),
    ('Table Extension', '50606', 'ResCapacityEntry Opt',       'Modified', '+ 2 fields: Type, Absence Reason Code (Section 3.1)'),
    ('Page (List)',     '50684', 'Resource Absence List',      'NEW',      'Add/Edit/Delete entry point, opened from the Resource Card (Section 6.2)'),
    ('Page (Card)',     '50685', 'Resource Absence Card',      'NEW',      'Data entry form for one absence entry (Section 6.3)'),
    ('Codeunit',        '50686', 'Resource Absence Mgt.',      'NEW',      'Validation + insert/delete logic (Section 5)'),
    ('Page Extension',  '50605', 'ResourceCard Opti',          'Modified', '+ "Absence" action (Section 6.1)'),
    ('Page',            '50629', 'Res. Capacity FactBox Part', 'Modified', '+ "Type" column so Capacity/Absence rows are distinguishable (Section 8.2)'),
    ('Page',            '50627', 'Resource Capacity Settings Opt', 'Modified', '"Update Capacity" wizard - CalcSums(Capacity) must add a Type = Capacity filter (Section 5.7)'),
]
for i, r in enumerate(rows):
    dr = data_row(tbl, *r, shade=(i % 2 == 0))
    if r[3] == 'NEW':
        set_cell_bg(dr.cells[3], 'C6EFCE')
doc.add_paragraph()

# ── 5. VALIDATION & BUSINESS LOGIC ────────────────────────────────────────────

h(doc, '5. Validation & Business Logic - Codeunit 50686 "Resource Absence Mgt."')
p(doc,
  'A single new codeunit owns every Absence business rule below, mirroring the existing '
  '"Resource Handler" (codeunit 50600) pattern already used in this extension for '
  'testable, centralized resource logic. The Absence Card page and the underlying table '
  'triggers both call into this codeunit rather than re-implementing rules locally.')

h(doc, '5.1  Rule: Existing-Capacity Guard', 2)
p(doc,
  'It would not be logical to record an absence without corresponding capacity. On '
  'insert/validate of an Absence row, the codeunit looks up table 160 for '
  '"Resource No." + Date + Type = Capacity + Capacity > 0.')
tbl = add_table(doc, [3, 14], 'Outcome', 'Behavior')
guard_rows = [
    ('Match found', 'The matching row''s "Duplicate Id" is copied onto the new Absence row (Section 5.3); insert proceeds.'),
    ('No match', 'Error: "Resource %1 has no capacity recorded for %2. Register capacity before recording an absence."'),
]
for i, r in enumerate(guard_rows):
    data_row(tbl, *r, shade=(i % 2 == 0))
doc.add_paragraph()

h(doc, '5.2  Rule: Sign Convention', 2)
p(doc,
  'Users think in positive hours ("I was absent for 4 hours"), not negative capacity. '
  'The Absence Card exposes a positive "Hours" field; the codeunit validates Hours > 0 '
  'and writes -Hours into the underlying "Capacity" field on insert. The negative sign '
  'is an implementation detail the user never sees directly.')

h(doc, '5.3  Rule: "Duplicate Id" Inheritance', 2)
p(doc,
  'Query 50604 "Capacity Per Day Per Resource" (existing, unchanged) sums Capacity '
  'grouped by Date, Resource No. AND Duplicate Id - it does not filter on Type at all, '
  'which is exactly why this design needs no query changes. But that also means an '
  'Absence row MUST carry the same "Duplicate Id" as the Capacity row it offsets, or it '
  'nets against the wrong group (e.g. a resource with two split-shift Capacity rows for '
  'the same day, each with a different Duplicate Id). The codeunit therefore copies '
  '"Duplicate Id" from the matched Capacity row (Section 5.1), never leaves it at the '
  'field''s bare default.')

h(doc, '5.4  Rule: Overshoot Guard (recommended default - confirm in Section 9)', 2)
p(doc,
  'The codeunit blocks an Absence whose Hours exceed the linked Capacity row''s Capacity '
  '- i.e. a single absence line cannot drive that entry''s net below zero. This is a '
  'recommendation, not yet confirmed with the business - see open question 9.1.')

h(doc, '5.5  Rule: Delete Protection', 2)
p(doc,
  'Deleting a Capacity row is blocked while an Absence row still exists for the same '
  '"Resource No." + Date + "Duplicate Id" (Type = Absence) - the same lookup the '
  'existing-capacity guard (Section 5.1) already performs, just run in reverse before a '
  'delete. This prevents an Absence entry from being left behind with no corresponding '
  'Capacity for its date.')

h(doc, '5.6  Backward Compatibility', 2)
info_box(doc,
    '"Type" defaults to Capacity (enum value 0), so every existing INSERT path - the '
    'demo data codeunit and any other current writer of table 160 - continues to work '
    'completely unchanged and needs no code changes.',
    label='Compatibility', color='C6EFCE')

h(doc, '5.7  Required Fix: "Update Capacity" Wizard Must Filter by Type', 2)
p(doc,
  'Unlike a plain insert, page 50627 "Resource Capacity Settings Opt" (this extension''s '
  '"Update Capacity" action on the Resource Capacity Settings card - the actual capacity '
  'generator used day to day, a customized copy of base page 6013) RECALCULATES capacity '
  'by summing existing rows and inserting a delta. Its current logic '
  '(src/page/page_6013_ResourceCapacitySettings.al, "Update Capacity" action):')
add_code(doc,
r"""ResCapacityEntry.SetRange("Resource No.", Rec."No.");
ResCapacityEntry.SetRange(Date, TempDate);
ResCapacityEntry.SetRange("Duplicate Id", LoopCounter);
ResCapacityEntry.CalcSums(Capacity);              // <- no Type filter today
TempCapacity := ResCapacityEntry.Capacity;

ResCapacityEntry2.Capacity := NewCapacity - TempCapacity;   // adjustment row
ResCapacityEntry2.Insert(true);""")
info_box(doc,
    'Without a fix, this is a real bug, not a theoretical one: if a resource has an '
    'Absence row for a date (Capacity = -4, say) and the wizard is re-run for that date '
    'with NewCapacity = 8, CalcSums(Capacity) reads the existing sum as 8 + (-4) = 4, so '
    'the wizard inserts an adjustment of 8 - 4 = 4 - silently cancelling the absence back '
    'to a net 8, with no error and no warning to the user. REQUIRED FIX: add '
    'SetRange(Type, "Res. Capacity Entry Type"::Capacity) alongside the existing '
    '"Duplicate Id" filter, on both CalcSums(Capacity) call sites in that action '
    '(single-duplicate and multi-duplicate branches). This is the one existing object '
    'that genuinely needs a behavioral code change for this feature - not just an '
    'additive UI change - and is called out separately in Section 8.2.',
    label='Risk Found During Design Review', color='F8D7DA')

# ── 6. PAGE & ACTION DESIGN ───────────────────────────────────────────────────

h(doc, '6. Page & Action Design')

h(doc, '6.1  Resource Card - New "Absence" Action', 2)
p(doc,
  'Added to page extension 50605 "ResourceCard Opti" (existing), grouped near the '
  'current "Day Plannings (Visual)" action. Opens Resource Absence List (Section 6.2) '
  'pre-filtered to the current resource.')
add_code(doc,
r"""action("Absence")
{
    ApplicationArea = All;
    Caption = 'Absence';
    Image = Absence;
    RunObject = page "Resource Absence List";
    RunPageLink = "Resource No." = field("No."), Type = const(Absence);
    ToolTip = 'View and register absence entries for this resource.';
}""")

h(doc, '6.2  Page 50684 "Resource Absence List" [NEW]', 2)
p(doc,
  'Standard list page, SourceTable "Res. Capacity Entry", SourceTableView filtered to '
  'Type = Absence. Standard New/Edit/Delete actions route to the Card page (Section 6.3). '
  'Read-only columns: Date, Hours (shown positive via a display method or the negated '
  'Capacity value), Absence Reason Code.')

h(doc, '6.3  Page 50685 "Resource Absence Card" [NEW]', 2)
p(doc, 'Fields, in the order given in the original design request:')
tbl = add_table(doc, [4.5, 4.5, 8], 'Field', 'Editable?', 'Notes')
card_fields = [
    ('Resource No.', 'Only on a new record', 'Defaulted from the calling Resource Card and locked once the record exists.'),
    ('Resource Name', 'No', 'Plain page-level lookup (Resource.Get() in OnAfterGetRecord / a page variable) - not a stored table field, since it is display-only.'),
    ('Absence Date', 'Yes', 'Maps to the underlying "Date" field.'),
    ('Absence Reason', 'Yes', 'Maps to "Absence Reason Code"; lookup to table 5206 "Cause of Absence" / page "Causes of Absence".'),
    ('Hours', 'Yes', 'Positive entry; codeunit 50686 negates it into "Capacity" on insert (Section 5.2).'),
]
for i, r in enumerate(card_fields):
    data_row(tbl, *r, shade=(i % 2 == 0))

# ── 7. DATA FLOW ──────────────────────────────────────────────────────────────

h(doc, '7. Data Flow')
add_code(doc,
r"""Resource Card
      |
      |  action "Absence"  (RunPageLink: Resource No. + Type = Absence)
      v
Resource Absence List  (Page 50684, filtered to Type = Absence)
      |
      |  New / Edit
      v
Resource Absence Card  (Page 50685)
      |
      |  user enters: Absence Date, Absence Reason, Hours (positive)
      v
Codeunit 50686 "Resource Absence Mgt."
      |
      |-- 5.1  find matching Capacity row (Resource No. + Date + Type=Capacity)
      |          not found -> Error, stop
      |          found     -> capture its Duplicate Id
      |-- 5.4  Hours <= matched row's Capacity ?  (overshoot guard)
      |-- 5.2  negate Hours -> Capacity field
      v
INSERT into Table 160 "Res. Capacity Entry"
   (Type = Absence, Capacity = -Hours, Duplicate Id = copied from the matched Capacity row)
      |
      v
Existing, UNCHANGED aggregation automatically nets the result:
   - Query 50604 "Capacity Per Day Per Resource"   (SUM Capacity by Date/Resource No./Duplicate Id)
   - Any other existing SUM/FlowField reader of "Res. Capacity Entry".Capacity""")

# ── 8. IMPACTED OBJECTS SUMMARY ───────────────────────────────────────────────

h(doc, '8. Impacted Objects Summary')
p(doc, 'For a reviewer to gauge blast radius at a glance:')

h(doc, '8.1  Touched but NOT code-changed (confirmed by design)', 2)
tbl = add_table(doc, [5, 12], 'Object', 'Why it needs no change')
untouched = [
    ('Query 50604 "Capacity Per Day Per Resource"', 'Sums Capacity with no Type filter - already nets Capacity/Absence automatically (Section 5.3). Read-only aggregation, so unlike page 50627 there is no "recompute and re-insert a delta" step that could be fooled.'),
    ('Codeunit 50602 "CreateDemoData"', 'Plain Insert of Capacity rows - new Type field defaults to Capacity, so demo data generation is unaffected (Section 5.6).'),
]
for i, r in enumerate(untouched):
    data_row(tbl, *r, shade=(i % 2 == 0))
doc.add_paragraph()

h(doc, '8.2  Modified', 2)
tbl = add_table(doc, [5, 12], 'Object', 'Change')
modified = [
    ('Table Extension 50606 "ResCapacityEntry Opt"', '+ 2 fields (Section 3.1).'),
    ('Page Extension 50605 "ResourceCard Opti"', '+ "Absence" action (Section 6.1).'),
    ('Page 50629 "Res. Capacity FactBox Part"', '+ "Type" column, so the factbox on the Resource Card no longer shows an unexplained second row per date once Absence entries exist.'),
    ('Page 50627 "Resource Capacity Settings Opt"', 'BEHAVIORAL fix, not additive: both CalcSums(Capacity) call sites in the "Update Capacity" action need a Type = Capacity filter added, or re-running that wizard silently cancels out recorded absences (Section 5.7).'),
]
for i, r in enumerate(modified):
    data_row(tbl, *r, shade=(i % 2 == 0))

# ── 9. OPEN QUESTIONS ──────────────────────────────────────────────────────────

h(doc, '9. Open Questions / Assumptions for Reviewer')
info_box(doc,
    '9.1  Overshoot guard (Section 5.4) - should the system block an absence that '
    'exceeds that day''s Capacity row, or allow it (net capacity for the day goes '
    'negative)?\n\n'
    '9.2  Multiple absence entries per Resource/Date - should partial-day absences '
    '(e.g. two half-days against the same Capacity row) be allowed, or restricted to '
    'one Absence row per Resource/Date?\n\n'
    '9.3  Should "Hours" on the Absence Card default to the full remaining Capacity for '
    'that date (convenience for the common "absent all day" case), or always start '
    'blank?',
    label='Confirm before implementation', color='FFF2CC')

# ── 10. OBJECT ID QUICK REFERENCE ─────────────────────────────────────────────

h(doc, '10. Object ID Quick Reference')
tbl = add_table(doc, [3, 3, 11], 'Type', 'ID', 'Name')
quick_ref = [
    ('Enum', '50682', 'Res. Capacity Entry Type'),
    ('Table Extension', '50606', 'ResCapacityEntry Opt (extended)'),
    ('Page (List)', '50684', 'Resource Absence List'),
    ('Page (Card)', '50685', 'Resource Absence Card'),
    ('Codeunit', '50686', 'Resource Absence Mgt.'),
    ('Page Extension', '50605', 'ResourceCard Opti (extended)'),
    ('Page', '50629', 'Res. Capacity FactBox Part (extended)'),
    ('Page', '50627', 'Resource Capacity Settings Opt (behavioral fix - Section 5.7)'),
    ('Table (reference, unchanged)', '160', 'Res. Capacity Entry (base app)'),
    ('Table (reference, unchanged)', '5206', 'Cause of Absence (base app)'),
]
for i, r in enumerate(quick_ref):
    dr = data_row(tbl, *r, shade=(i % 2 == 0))
    if r[1] == '50627':
        set_cell_bg(dr.cells[1], 'F8D7DA')

# ── SAVE ───────────────────────────────────────────────────────────────────────

out_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'Resource Absence Management.docx')
doc.save(out_path)
print(f'Saved: {out_path}')
