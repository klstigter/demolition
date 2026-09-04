"""
generate_capacity_planning_overview_doc.py
Regenerates "Capacity Planning Overview - Technical Document.pdf" using reportlab.

No generator script for the original PDF survived in this folder, so this one was
reconstructed from the existing PDF's own extracted text (pdftotext -layout), preserving
every section's content, then updated for the 2026-09-04 session's changes: the
confirm-gated reschedule redesign (no BC round-trip on drag/click, only on the new
"Confirm changes" button), the processing-indicator (loading spinner) UI, the Section 4
scrollbar-sync follow-on fix, and the treeSummaryIndex performance fix. Section 13
("Known Pitfalls") also fixes a pre-existing numbering bug (its entries were labelled
12.1-12.6, reusing section 12's numbers) while adding the new session's findings as
13.7-13.10.

Run:  python generate_capacity_planning_overview_doc.py
Output: Capacity Planning Overview - Technical Document.pdf  (same folder as this script)
"""

from reportlab.lib import colors
from reportlab.lib.pagesizes import LETTER
from reportlab.lib.units import cm
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.enums import TA_LEFT, TA_CENTER
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, PageBreak,
    KeepTogether, HRFlowable
)
from reportlab.pdfgen import canvas
import os

NAVY = colors.HexColor('#1F3964')
NAVY_LIGHT = colors.HexColor('#2F5496')
GOLD = colors.HexColor('#B8860B')
CODE_BG = colors.HexColor('#EDF2F8')
ROW_SHADE = colors.HexColor('#EBF3FB')
CALLOUT_BG = colors.HexColor('#FFF4E5')
CALLOUT_BORDER = colors.HexColor('#D98E04')
FIX_BG = colors.HexColor('#EAF7EE')
FIX_BORDER = colors.HexColor('#2E7D32')
GREY_TEXT = colors.HexColor('#44546A')

OUTPUT_PATH = os.path.join(os.path.dirname(__file__), "Capacity Planning Overview - Technical Document.pdf")

styles = getSampleStyleSheet()

styles.add(ParagraphStyle('CPOTitle', fontSize=26, leading=30, textColor=colors.white,
                           fontName='Helvetica-Bold', alignment=TA_LEFT))
styles.add(ParagraphStyle('CPOKicker', fontSize=12, leading=14, textColor=colors.white,
                           fontName='Helvetica-Bold', alignment=TA_LEFT, spaceAfter=4))
styles.add(ParagraphStyle('CPOSubtitle', fontSize=12, leading=16, textColor=colors.white,
                           fontName='Helvetica-Oblique', alignment=TA_LEFT))
styles.add(ParagraphStyle('CPOMeta', fontSize=9.5, leading=13, textColor=colors.HexColor('#D9E2F3'),
                           fontName='Helvetica', alignment=TA_LEFT))
styles.add(ParagraphStyle('H1', fontSize=15, leading=18, textColor=colors.white,
                           fontName='Helvetica-Bold', spaceBefore=0, spaceAfter=0,
                           leftIndent=6))
styles.add(ParagraphStyle('H2', fontSize=12, leading=15, textColor=NAVY,
                           fontName='Helvetica-Bold', spaceBefore=14, spaceAfter=6))
styles.add(ParagraphStyle('H3', fontSize=10.5, leading=13, textColor=NAVY_LIGHT,
                           fontName='Helvetica-Bold', spaceBefore=10, spaceAfter=4))
styles.add(ParagraphStyle('Body', fontSize=9.5, leading=13.5, textColor=colors.HexColor('#1A1A1A'),
                           fontName='Helvetica', spaceAfter=6, alignment=TA_LEFT))
styles.add(ParagraphStyle('BodySmall', fontSize=8.7, leading=12, textColor=colors.HexColor('#1A1A1A'),
                           fontName='Helvetica', spaceAfter=4, alignment=TA_LEFT))
styles.add(ParagraphStyle('CPOBullet', fontSize=9.5, leading=13.5, textColor=colors.HexColor('#1A1A1A'),
                           fontName='Helvetica', spaceAfter=4, leftIndent=14, bulletIndent=2))
styles.add(ParagraphStyle('TOCEntry1', fontSize=10.3, leading=16, textColor=NAVY,
                           fontName='Helvetica-Bold'))
styles.add(ParagraphStyle('TOCEntry2', fontSize=9.5, leading=14, textColor=colors.HexColor('#333333'),
                           fontName='Helvetica', leftIndent=16))
styles.add(ParagraphStyle('TableHdr', fontSize=8.6, leading=11, textColor=colors.white,
                           fontName='Helvetica-Bold'))
styles.add(ParagraphStyle('TableCell', fontSize=8.6, leading=11.5, textColor=colors.HexColor('#1A1A1A'),
                           fontName='Helvetica'))
styles.add(ParagraphStyle('TableCellB', fontSize=8.6, leading=11.5, textColor=NAVY,
                           fontName='Helvetica-Bold'))
styles.add(ParagraphStyle('CPOCode', fontSize=8.2, leading=11, textColor=NAVY,
                           fontName='Courier', spaceAfter=1))
styles.add(ParagraphStyle('CalloutHdr', fontSize=9.5, leading=12, textColor=CALLOUT_BORDER,
                           fontName='Helvetica-Bold', spaceAfter=3))
styles.add(ParagraphStyle('CalloutBody', fontSize=9, leading=12.5, textColor=colors.HexColor('#1A1A1A'),
                           fontName='Helvetica'))
styles.add(ParagraphStyle('FixHdr', fontSize=9.5, leading=12, textColor=FIX_BORDER,
                           fontName='Helvetica-Bold', spaceAfter=3))
styles.add(ParagraphStyle('Footer', fontSize=8, leading=10, textColor=colors.HexColor('#8A8A8A'),
                           fontName='Helvetica-Oblique', alignment=TA_CENTER))


def P(text, style='Body'):
    return Paragraph(text, styles[style])


def h1(number, title):
    tbl = Table([[P(f'{number}. {title}', 'H1')]], colWidths=[17.4 * cm])
    tbl.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, -1), NAVY),
        ('TOPPADDING', (0, 0), (-1, -1), 7),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 7),
        ('LEFTPADDING', (0, 0), (-1, -1), 8),
    ]))
    return [Spacer(1, 14), tbl, Spacer(1, 8)]


def h2(number, title):
    return [P(f'{number} {title}', 'H2')]


def h3(title):
    return [P(title, 'H3')]


def bullets(items):
    out = []
    for it in items:
        out.append(Paragraph(f'&bull;&nbsp;&nbsp;{it}', styles['CPOBullet']))
    return out


def def_table(headers, rows, col_widths, header_bg=NAVY):
    data = [[Paragraph(h, styles['TableHdr']) for h in headers]]
    for r in rows:
        data.append([Paragraph(str(c), styles['TableCellB'] if i == 0 else styles['TableCell'])
                     for i, c in enumerate(r)])
    tbl = Table(data, colWidths=col_widths, repeatRows=1)
    style = [
        ('BACKGROUND', (0, 0), (-1, 0), header_bg),
        ('GRID', (0, 0), (-1, -1), 0.5, colors.HexColor('#C7D3E8')),
        ('VALIGN', (0, 0), (-1, -1), 'TOP'),
        ('TOPPADDING', (0, 0), (-1, -1), 4),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 4),
        ('LEFTPADDING', (0, 0), (-1, -1), 5),
        ('RIGHTPADDING', (0, 0), (-1, -1), 5),
    ]
    for i in range(1, len(data)):
        if i % 2 == 0:
            style.append(('BACKGROUND', (0, i), (-1, i), ROW_SHADE))
    tbl.setStyle(TableStyle(style))
    return tbl


def callout(header, text, kind='note'):
    bg, border, hdr_style = (FIX_BG, FIX_BORDER, 'FixHdr') if kind == 'fix' else (CALLOUT_BG, CALLOUT_BORDER, 'CalloutHdr')
    inner = [Paragraph(header, styles[hdr_style]), Paragraph(text, styles['CalloutBody'])]
    tbl = Table([[inner]], colWidths=[17.0 * cm])
    tbl.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, -1), bg),
        ('BOX', (0, 0), (-1, -1), 0.75, border),
        ('LINEBEFORE', (0, 0), (0, -1), 3, border),
        ('TOPPADDING', (0, 0), (-1, -1), 7),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 7),
        ('LEFTPADDING', (0, 0), (-1, -1), 10),
        ('RIGHTPADDING', (0, 0), (-1, -1), 10),
    ]))
    return [Spacer(1, 4), tbl, Spacer(1, 6)]


def code_block(lines):
    paras = [Paragraph(l.replace(' ', '&nbsp;') if l.strip() else '&nbsp;', styles['CPOCode']) for l in lines]
    tbl = Table([[paras]], colWidths=[17.0 * cm])
    tbl.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, -1), CODE_BG),
        ('TOPPADDING', (0, 0), (-1, -1), 8),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 8),
        ('LEFTPADDING', (0, 0), (-1, -1), 10),
        ('RIGHTPADDING', (0, 0), (-1, -1), 10),
    ]))
    return [Spacer(1, 3), tbl, Spacer(1, 6)]


def hr():
    return [Spacer(1, 4), HRFlowable(width='100%', thickness=0.6, color=colors.HexColor('#C7D3E8')), Spacer(1, 6)]


# ─── cover page ──────────────────────────────────────────────────────────────

def cover_page():
    banner = Table([
        [P('TECHNICAL DOCUMENT', 'CPOKicker')],
        [P('Capacity Planning Overview', 'CPOTitle')],
        [P("Business Central Control Add-in &mdash; Architecture, Data Flow &amp; DHTMLX Integration", 'CPOSubtitle')],
    ], colWidths=[17.4 * cm])
    banner.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, -1), NAVY),
        ('TOPPADDING', (0, 0), (-1, 0), 26),
        ('BOTTOMPADDING', (0, -1), (-1, -1), 22),
        ('TOPPADDING', (0, 1), (-1, 1), 6),
        ('TOPPADDING', (0, 2), (-1, 2), 10),
        ('LEFTPADDING', (0, 0), (-1, -1), 22),
        ('RIGHTPADDING', (0, 0), (-1, -1), 22),
    ]))

    meta_rows = [
        'Extension: DailyOptimizer (Optimizers) &mdash; app id range 50600&ndash;60700',
        'Page: 50722 "Capacity Planning Overview" | Controladdin: DHXCapacityPlanningOverviewAddin',
        'Codeunit: 50604 "DHX Data Handler" &mdash; region CPO_',
        'Reference prototype: KLAAS/CPO_v131 (DHTMLXtempv112-app.js / DHTMLXtempv112-data.js)',
        'Folder: src\\dhx\\capacity_planning_overview\\',
        '<b>Document date: 2026-09-04</b> (supersedes the 2026-09-03 revision)',
    ]
    meta = Table([[P(m, 'CPOMeta')] for m in meta_rows], colWidths=[17.4 * cm])
    meta.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, -1), NAVY_LIGHT),
        ('TOPPADDING', (0, 0), (-1, -1), 3),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 3),
        ('LEFTPADDING', (0, 0), (-1, -1), 22),
        ('RIGHTPADDING', (0, 0), (-1, -1), 22),
        ('TOPPADDING', (0, 0), (-1, 0), 12),
        ('BOTTOMPADDING', (0, -1), (-1, -1), 14),
    ]))

    revnote = callout(
        'Revision note (2026-09-04)',
        'This revision documents a same-day follow-up session on top of the 2026-09-03 cross-work-order-scoping/'
        'pagination work already described throughout this document: (1) reschedule (Section 2 drag, Section 3 '
        'click-to-relocate) was redesigned to run <b>entirely client-side, with zero BC round-trips, until the '
        'user clicks a new "Confirm changes" button</b> &mdash; see &sect;3.1; (2) a processing-indicator (loading '
        'spinner) UI was added for every action that genuinely takes time &mdash; see &sect;3.2; (3) Section 4\'s '
        'scrollbar-sync fix (&sect;13.5) had a follow-on bug (&sect;13.7) and a separate, unrelated performance bug '
        '(&sect;13.8), both fixed; (4) an architectural finding about how InvokeExtensibilityMethod actually behaves '
        '(&sect;13.9) that explains why several of these fixes work the way they do; (5) Section 4 now opens fully '
        'collapsed by default (&sect;13.11) after two other performance approaches (DHTMLX Scheduler\'s smart_rendering, '
        'a full swap to the DHTMLX Gantt library) were tried and measured live, then set aside. Every changed section '
        'below is marked <b>(2026-09-04)</b> inline; everything else is unchanged from the prior revision.'
    )

    toc_title = [Spacer(1, 10), P('Table of Contents', 'H2'), Spacer(1, 4)]

    toc_entries = [
        ('1.', 'Overview &amp; Purpose', 1),
        ('2.', 'Architecture &mdash; BOOT / Wrapper / Controladdin Pattern', 1),
        ('2.1', 'File Inventory', 2),
        ('2.2', 'Controladdin Contract', 2),
        ('3.', 'End-to-End Data Flow', 1),
        ('3.1', 'Confirm-Gated Reschedule <b>(2026-09-04)</b>', 2),
        ('3.2', 'Processing Indicators <b>(2026-09-04)</b>', 2),
        ('4.', 'The JSON Payload Contract (window.DHTMLXPlannerData shape)', 1),
        ('5.', 'Section 1 &mdash; Stats Header', 1),
        ('6.', 'Section 2 &mdash; Work Order&rsquo;s Own Day Planning Scheduler', 1),
        ('7.', 'Section 3 &mdash; Capacity vs Requested Daily Bars', 1),
        ('8.', 'Section 4 &mdash; Skill &rarr; Job/Task &rarr; Sequence Tree', 1),
        ('9.', 'The Shortage / Coverage Engine (Max-Flow)', 1),
        ('10.', 'AL-Side Implementation Details', 1),
        ('11.', 'Cross-Work-Order Scoping (2026-09-03 Correction)', 1),
        ('12.', 'Performance &mdash; Page Background Task Pagination', 1),
        ('13.', 'Known Pitfalls, Bugs Found &amp; Fixes Applied', 1),
        ('14.', 'Appendix &mdash; File Reference', 1),
    ]
    toc_rows = []
    for num, title, level in toc_entries:
        style = 'TOCEntry1' if level == 1 else 'TOCEntry2'
        toc_rows.append([Paragraph(f'{num}&nbsp;&nbsp;{title}', styles[style])])

    return [banner, meta, Spacer(1, 12)] + revnote + toc_title + \
        [KeepTogether([r[0] for r in toc_rows[:1]])] + [row[0] for row in toc_rows[1:]] + [PageBreak()]


# ─── section 1 ───────────────────────────────────────────────────────────────

def section_1():
    out = h1('1', 'Overview &amp; Purpose')
    out += [P(
        "The Capacity Planning Overview add-in is a Business Central control add-in that gives a single-screen "
        "view, for one selected Work Order, of: (a) whether that Work Order's own demand can realistically be "
        "covered by the company's resource pool day-by-day, (b) the Work Order's own Day Planning schedule, "
        "(c) a daily capacity-vs-request bar chart, and (d) a tree of every other Work Order's competing demand "
        "in the same visible window."
    )]
    out += [P(
        "It is a faithful, BC-native port of a standalone DHTMLX prototype "
        "(<font face='Courier'>KLAAS\\CPO_v131\\DHTMLXtempv112-app.js</font>), with two deliberate substitutions: "
        "(1) the prototype's trial/evaluation <font face='Courier'>@dhx/trial-scheduler</font> npm package is "
        "replaced by this repository's already-licensed <font face='Courier'>dhtmlxscheduler.js</font>, and "
        "(2) all data is now real Business Central records instead of a static mock JSON file. The prototype's "
        "own client-side algorithms (shortage/coverage max-flow engine, tree builder, daily bar aggregator) are "
        "ported near-verbatim &mdash; Business Central's job is reduced to producing one JSON payload shaped "
        "exactly like the prototype's own mock <font face='Courier'>window.DHTMLXPlannerData</font> object."
    )]
    out += callout(
        'Guiding principle (explicit, non-negotiable project requirement)',
        'A BC control add-in binds exactly one JS component via one wrapper.js. All four visual sections, the '
        'shared header, and the "Days to show" control therefore live inside ONE JS class '
        '(<font face="Courier">CapacityPlanningOverview</font>), not four separate <font face="Courier">usercontrol</font> '
        'blocks. AL/Business Central is treated purely as a data source and event sink &mdash; "consider BC Add-ins '
        'as a browser for JS". The <b>2026-09-04 confirm-gated redesign (&sect;3.1) sharpens this further</b>: AL is now '
        'not even an event sink for every interaction &mdash; it is a data source on load, and an event sink only '
        'for the one action the user deliberately commits to.'
    )
    return out


# ─── section 2 ───────────────────────────────────────────────────────────────

def section_2():
    out = h1('2', 'Architecture &mdash; BOOT / Wrapper / Controladdin Pattern')
    out += [P(
        "This follows the same skeleton every other DHTMLX add-in in this repository uses "
        "(e.g. <font face='Courier'>projectschedule</font>, <font face='Courier'>request_assignment</font>):"
    )]
    out += bullets([
        'BC loads the controladdin\'s <font face="Courier">StartupScript</font>, which calls <font face="Courier">BOOT()</font>.',
        '<font face="Courier">BOOT()</font> (in wrapper.js) finds the host <font face="Courier">&lt;div id="controlAddIn"&gt;</font>, '
        'normalizes it to fill 100% width/height, renames its id to <font face="Courier">cpo-root</font>, instantiates '
        '<font face="Courier">new CapacityPlanningOverview(\'cpo-root\')</font> (stored at <font face="Courier">window.__cpo</font>), '
        'shows the full-page loading overlay (&sect;3.2), and calls '
        '<font face="Courier">Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("ControlReady", [])</font>.',
        'AL\'s <font face="Courier">ControlReady</font> trigger (page 50722) fires, which builds the initial JSON '
        'payload and calls <font face="Courier">CurrPage.DhxCpo.SetPlanningData(json)</font>.',
        '<font face="Courier">SetPlanningData</font> (the controladdin procedure) invokes the JS-side global '
        'function of the same name (in wrapper.js), which parses the JSON and calls '
        '<font face="Courier">window.__cpo.applyPlanningData(json)</font>.',
        '<font face="Courier">applyPlanningData</font> is the single entry point that fans out to every section\'s '
        'own <font face="Courier">render*</font> method, then hides the loading overlay as its true last step '
        '(&sect;3.2) &mdash; the user\'s actual "processing is done, ready for the next action" signal.',
    ])

    out += h2('2.1', 'File Inventory')
    out += [def_table(
        ['File', 'Role'],
        [
            ['DHXCapacityPlanningOverviewAddin.<br/>ControlAddin.al', 'Controladdin declaration: script/stylesheet load order, procedures (AL&rarr;JS), events (JS&rarr;AL), sizing properties. Unchanged in the 2026-09-04 session &mdash; the confirm-gated redesign changed WHEN the JS side calls the existing OnRescheduleWorkOrder event, not the event\'s own signature.'],
            ['page_50722_CapacityPlanningOverview.al', 'Card page hosting the single usercontrol. No SourceTable. Holds GWorkOrderNo / DaysToShow state, rebuilds and pushes the payload via RefreshData(). OnRescheduleWorkOrder\'s stub Message() dialog was removed (2026-09-04, &sect;13.10) &mdash; it is now a true silent no-op stub, matching OnRequestCapacityLookup/OnSequenceChipClick.'],
            ['startupScript.js', 'One line: BOOT();'],
            ['wrapper.js', 'Thin BOOT/binding shell &mdash; instantiates the JS class, exposes the AL-facing globals (SetPlanningData / SetColors / LoadCapacityLookup / AppendOtherWorkOrderData), and (2026-09-04) owns the full-page loading overlay\'s safety timer (&sect;3.2).'],
            ['capacityPlanningOverview.js', 'The single JS component (~1,850 lines). All four sections, the shared header, the shortage/coverage engine, scroll-sync, tooltips, the processing-indicator methods, and (2026-09-04) the Confirm-button / unconfirmed-change state machine.'],
            ['style.css', 'All layout/heat-map/chip/scrollbar CSS for the four sections and shared header, plus (2026-09-04) the spinner/overlay and Confirm-button CSS.'],
            ['codeunit_50604_DHXDataHandler.al', 'Shared data-handler codeunit (also used by other DHX add-ins). Region CPO_ builds the one combined JSON payload.'],
            ['Pag50662.WorkorderCard.al', 'Launching page &mdash; action CapacityPlanningOverviewAct calls SetWorkOrderNo() then Run() (top-level navigation, not a modal dialog).'],
        ],
        [5.2 * cm, 12.2 * cm]
    )]
    out += [Spacer(1, 4), P(
        "Vendor libraries (dhtmlxscheduler.js/.css, suite.js/.css, GlobalFunction.js) are shared, root-level "
        "copies reused by every DHX add-in &mdash; no per-folder vendor duplication.", 'BodySmall'
    )]

    out += h2('2.2', 'Controladdin Contract')
    out += code_block([
        'controladdin DHXCapacityPlanningOverviewAddin',
        '{',
        '    RequestedHeight = 1150; MinimumHeight = 420;   VerticalShrink/Stretch = true;',
        '    RequestedWidth = 1800; MinimumWidth = 900;     HorizontalShrink/Stretch = true;',
        '',
        '    Scripts = dhtmlxscheduler.js, suite.js, GlobalFunction.js,',
        '              capacityPlanningOverview.js,   // component class BEFORE wrapper.js',
        '              wrapper.js;                    // BOOT() references the class - must load last',
        '',
        '    StartupScript = startupScript.js;',
        '    StyleSheets = dhtmlxscheduler.css, suite.css, style.css;',
        '',
        '    procedure SetPlanningData(PlanningDataJsonTxt: Text);',
        '    procedure SetColors(ColorsJsonTxt: Text);',
        '    procedure LoadCapacityLookup(CapacityLookupJsonTxt: Text);',
        '    procedure AppendOtherWorkOrderData(OtherWorkOrderDataJsonTxt: Text);',
        '    procedure NotifyOtherWorkOrderDataTaskPending();',
        '    procedure StopOtherWorkOrderDataPolling();',
        '',
        '    event ControlReady();',
        '    event OnRescheduleWorkOrder(DayShift: Integer; PayloadJsonTxt: Text);   // now fired ONLY by Confirm - see 3.1',
        '    event OnRequestCapacityLookup(FilterJsonTxt: Text);',
        '    event OnSequenceChipClick(PayloadJsonTxt: Text);',
        '    event OnDaysToShowChanged(NumberOfDays: Integer);',
        '    event OnPollOtherWorkOrderDataResult();',
        '}',
    ])
    out += [P(
        "<font face='Courier'>RequestedHeight = 1150</font> is sized to the worst case: section 1 (~104px fixed) "
        "+ section 2 (capped 400px) + section 3 (~180px) + section 4 (capped 420px) + ~40px chrome. "
        "<font face='Courier'>MinimumHeight = 420</font> with <font face='Courier'>VerticalShrink = true</font> "
        "lets a small Work Order shrink the control naturally instead of leaving dead space."
    )]
    return out


# ─── section 3 ───────────────────────────────────────────────────────────────

def section_3():
    out = h1('3', 'End-to-End Data Flow')
    out += code_block([
        'Workorder Card (page 50662)',
        '  action CapacityPlanningOverviewAct',
        '    CPO.SetWorkOrderNo(Rec."Work Order No.")',
        '    CPO.Run()                                    plain top-level nav, NOT RunModal()',
        '',
        'page 50722 "Capacity Planning Overview"',
        '  trigger ControlReady()',
        '    EnsureDaysToShow()                           DaysToShow default = 30',
        '    RefreshData()',
        '',
        '  local procedure RefreshData()',
        '    PlanningDataJson := DHXDataHandler.CPO_BuildPlanningDataJson_Paged(...)',
        '    CurrPage.DhxCpo.SetPlanningData(PlanningDataJson)',
        '                                                  (controladdin procedure -> JS global fn, same name)',
        '',
        'wrapper.js',
        '  window.SetPlanningData(json) { window.__cpo.applyPlanningData(JSON.parse(json)); }',
        '',
        'capacityPlanningOverview.js',
        '  applyPlanningData(json)',
        '    this.db = json; this.dates = [...]; this.woAnchor = 0; this._hasUnconfirmedChanges = false',
        '    this._baseRequests = this.aggregateRequests()',
        '    this._baselineWithoutWO = this.aggregateOutstandingRequestsWithoutWO()',
        '    renderWoSummaryScheduler(db)    Section 1',
        '    renderWoScheduler(db)           Section 2 (ends by calling renderWorkOrder(), which also',
        '                                             does a first-pass render of Section 3)',
        '    measuredColumnWidth = measureColumnWidth()   needs a REAL rendered cell from Section 2',
        '    renderCapacityBars(db)          Section 3 (re-rendered with the correct measured width)',
        '    renderCentralTree(db)           Section 4',
        '    bindScrollSync()                wires the shared horizontal scrollbar to all 4 sections',
        '    updateConfirmButtonState()      resets the Confirm button to disabled - fresh server data',
        '    hideLoading()                   true last step - see 3.2',
    ])
    out += [P('<b>Round-trip back to AL happens on three occasions</b> (updated 2026-09-04 &mdash; was previously two immediate '
               'occasions plus a stub; is now genuinely gated on the two data-changing ones):')]
    out += bullets([
        '"Days to show" changed (JS-owned input, top bar) &rarr; <font face="Courier">OnDaysToShowChanged(NumberOfDays)</font> '
        '&rarr; AL sets DaysToShow and calls RefreshData() again (full round-trip, new payload) &mdash; unchanged; this genuinely '
        'needs new data the client doesn\'t have.',
        '<b>The Confirm button</b> (new, 2026-09-04) &rarr; <font face="Courier">OnRescheduleWorkOrder(woAnchor, payloadJson)</font> '
        '&mdash; the ONE deliberate point any reschedule work (Section 2 drag, Section 3 click-to-relocate) reaches AL at all. '
        'Still a stub server-side (the real transactional Validate("Plan Date", ...) loop is a documented later step) &mdash; see &sect;3.1.',
        'Section 4 chip click &rarr; <font face="Courier">OnSequenceChipClick(payloadJson)</font> &mdash; stub, intended to open '
        '"Day Plannings" filtered to that specific line. Left as an immediate call (explicit 2026-09-04 decision, &sect;3.1) &mdash; '
        'it is a navigate/view action, not a schedule edit, so it is not part of the confirm-gated flow.',
    ])
    out += [P(
        'Section 3\'s Expand / Exp. to Task / Collapse buttons, the Capacity Lookup double-click, Section 2\'s own drag, and '
        'Section 3\'s click-to-relocate are all pure client-side, no AL round-trip per action &mdash; see &sect;3.1 for the two that '
        'changed this session.'
    )]

    out += h2('3.1', 'Confirm-Gated Reschedule <b>(2026-09-04)</b>')
    out += [P(
        'Prior behavior: every single Section 2 drag AND every Section 3 click-to-relocate immediately called '
        '<font face="Courier">InvokeExtensibilityMethod(\'OnRescheduleWorkOrder\', [shift, json])</font> &mdash; one real BC '
        'round-trip per intermediate mouse action, even though the trigger was (and still is) a complete no-op stub, and even '
        'though every value that call needed was already known client-side before it fired.'
    )]
    out += callout(
        'User-driven redesign',
        'Stated directly by the user across a series of messages in the same session: "as long as no confirm data from JS then '
        'you must use in JS calculation/process&hellip; add confirm button in same row of title&hellip; if user clicked that '
        'button then you start round-trip with BC to update data"; confirmed again as "all action in JS must calculated in JS, '
        'do not act round-trip with BC" and "so no more round-trip with bc as long as no clicked on confirmed button". Final '
        'shape, confirmed against all four sections explicitly: Section 1 is a calculated board that always runs in JS; Section 2 '
        'is the Work Order to be modified (shiftable left/right), no round-trip until Confirm; Section 3 is user-driven and drives '
        'Section 2, also no round-trip until Confirm; Section 4 is static existing-data context (excluding this Work Order&rsquo;s '
        'own lines &mdash; &sect;11) and is never touched by reschedule at all.',
        kind='fix'
    )
    out += [P('New client-side state machine (all in capacityPlanningOverview.js):')]
    out += [def_table(
        ['Method', 'Role'],
        [
            ['moveWorkOrderToDay(dayIndex)', 'Section 3 click-to-relocate. Updates woAnchor, resets anchor-dependent caches, calls renderWorkOrder() (Sections 1-3 re-render), then markUnconfirmedChange(). No AL call.'],
            ['onEventChanged (Section 2 drag handler)', 'Same shape &mdash; computes the day-shift from the drop position, updates woAnchor if valid, re-renders, calls markUnconfirmedChange(). No AL call.'],
            ['markUnconfirmedChange()', 'Sets this._hasUnconfirmedChanges = true and calls updateConfirmButtonState() &mdash; the only side effect of any local move.'],
            ['updateConfirmButtonState()', 'Enables/disables #cpo-confirm-btn and toggles its .cpo-confirm-btn-pending CSS class (muted/disabled &rarr; solid blue "click me" look) to match the current flag.'],
            ['bindConfirmButton()', 'Wires the button\'s click handler &mdash; calls confirmChanges() only if there is actually something unconfirmed.'],
            ['confirmChanges()', 'The ONE deliberate BC round-trip point. showLoading(), InvokeExtensibilityMethod(\'OnRescheduleWorkOrder\', [this.woAnchor, json]) with the CURRENT (possibly several-moves-later) woAnchor sent ONCE, then clears the pending flag, updates the button, hideLoading().'],
        ],
        [5.4 * cm, 12.0 * cm]
    )]
    out += [P(
        '<font face="Courier">#cpo-confirm-btn</font> ("Confirm changes") lives in the top bar, same row as the title, right of '
        '<font face="Courier">#cpo-title</font> and left of the "Days to show" input &mdash; per the user\'s explicit placement request. '
        'It starts disabled/muted on every fresh load (<font face="Courier">applyPlanningData</font> resets '
        '<font face="Courier">_hasUnconfirmedChanges</font> to false and calls <font face="Courier">updateConfirmButtonState()</font>), '
        'since a fresh server payload has nothing unconfirmed by definition.'
    )]
    out += [P(
        '<b>Section 1 and Section 4, confirmed unaffected:</b> Section 1 was already pure JS (renderWorkOrder() calls '
        'woSummaryScheduler.setCurrentView(...) to re-read the current woAnchor/caches &mdash; no AL involvement, before or after '
        'this redesign). Section 4 was already never re-rendered by any reschedule path (renderWorkOrder() does not call '
        'renderCentralTree()) &mdash; both facts predate this session and are unchanged by it; this redesign only removed the AL '
        'call that used to sit at the END of the Section 2/3 render paths.'
    )]

    out += h2('3.2', 'Processing Indicators <b>(2026-09-04)</b>')
    out += [P(
        'New UI feedback for every action that genuinely takes time, added on explicit request ("the data load and processing '
        'take a time&hellip; show processing animated"). Both use the same visual language: a ring spinner '
        '(<font face="Courier">.cpo-spinner</font>, a conic-gradient dark arc on a light track, CSS <font face="Courier">@keyframes '
        'cpo-spin</font>), at two sizes/contexts.'
    )]
    out += [def_table(
        ['Indicator', 'Shown for', 'Hidden by'],
        [
            ['#cpo-loading-overlay (full-host, blocking, .cpo-loading-overlay)', 'Initial ControlReady round-trip; a "Days to show" reload; Expand/Collapse-all\'s DHTMLX rebuild (via runBusy).', 'applyPlanningData\'s last step (hideLoading()); a 3-minute safety timer guards against it ever sticking.'],
            ['#cpo-bg-loading ("Loading more data&hellip;", top bar, .cpo-inline-loading, non-blocking)', 'The background other-Work-Order-data pagination poll (&sect;12) while it is still running.', 'StopOtherWorkOrderDataPolling (a result arrived) or the poll\'s own 30s ceiling.'],
        ],
        [8.6 * cm, 5.0 * cm, 3.8 * cm]
    )]
    out += [P(
        '<font face="Courier">runBusy(fn)</font> exists specifically for GENUINELY slow (multi-second) synchronous CPU work with '
        'no natural browser yield point &mdash; today, only setTreeOpenState\'s Expand/Collapse-all rebuild qualifies. It shows the '
        'overlay, waits two <font face="Courier">requestAnimationFrame</font> callbacks (forcing one real paint before the heavy '
        'work runs &mdash; showing the overlay and running the work in the same tick would never let the browser paint it at all), '
        'runs the work, then hides. It is deliberately NOT used around reschedule (moveWorkOrderToDay/the drag handler) any more '
        '&mdash; see &sect;13.9 for why plain showLoading()/hideLoading() around a fire-and-forget InvokeExtensibilityMethod call '
        'never needed this trick, and why reschedule\'s own ~100-150ms local render cost is not worth a spinner flash for at all '
        'now that it has no BC call to wait on.'
    )]
    return out


# ─── section 4 ───────────────────────────────────────────────────────────────

def section_4():
    out = h1('4', 'The JSON Payload Contract')
    out += [P(
        "Built entirely by codeunit 50604.CPO_BuildPlanningDataJson_Paged(WorkOrderNo, NumberOfDays, MaxOtherLines, "
        "out RemainingGroupKeys), shaped to mirror the reference prototype's own mock window.DHTMLXPlannerData object "
        "field-for-field. This is the only data BC ever pushes into the JS component on load &mdash; every section's "
        "render function derives everything else (shortage %, chip layout, bar heights, tree grouping) from this one "
        "object client-side, and (2026-09-04) every subsequent user interaction short of Confirm derives its results "
        "from this same object too, never re-fetching it."
    )]
    out += [def_table(
        ['Field', 'Type', 'Meaning / Source'],
        [
            ['daysToShow / startDate / endDate', 'int / ISO date', 'Echoed back so the JS-owned input can sync to whatever AL actually used. endDate = startDate + daysToShow - 1.'],
            ['workdays[]', 'ISO date[]', 'Every calendar day in range (weekends included, not skipped) &mdash; the reference\'s own convention. Also doubles as the implicit workday-offset anchor for Section 2\'s bars.'],
            ['workOrder.no / .description / .notEarlierThan / .notLaterThan', 'obj', 'The inspected Work Order\'s own header. description feeds the JS title bar directly.'],
            ['project.no / .description', 'obj', 'The Work Order\'s parent Job ("Project No.").'],
            ['skills[]', 'array', 'One entry per distinct Skill demanded (union of the inspected WO\'s own skills + every other WO\'s, &sect;11). Each: code, color, textColor, border, dark, light.'],
            ['resources[]', 'array', 'Every resource holding any demanded skill, capped at 15/skill for max-flow performance. Each: name (= Resource No.), skills[].'],
            ['baseCapacity', 'number', 'Flat 8 (hours/resource/day).'],
            ['externalFree[]', 'number[]', 'One entry per day in range &mdash; summed real "Res. Capacity Entry".Capacity for the capped resource pool with a non-blank Vendor No.'],
            ['groups[]', 'array', 'Section 4\'s tree source. One entry per distinct Skill demanded by every OTHER Work Order in this window. Each has details[] = one entry per distinct Job No./Job Task No.'],
            ['dayPlanningLines[]', 'array', 'Real Day Planning rows: the inspected WO\'s own lines plus every other WO\'s lines in the same window. Each carries a normalized workOrderNo.'],
            ['workOrderSequences[]', 'array', 'Section 2\'s source. One entry per distinct Skill+Job+Task+SequenceNo belonging ONLY to the inspected Work Order, plus a per-(sequence, workday-offset) requested-hours map.'],
        ],
        [4.3 * cm, 1.7 * cm, 11.4 * cm]
    )]
    out += [Spacer(1, 4), P('<b>dayPlanningLines[] &mdash; per-line shape</b>')]
    out += code_block([
        '{',
        '  id, workOrderNo, job, task, description, sequenceLineNo,',
        '  requestDate, requestedStartTime, requestedEndTime, requestedHours, requestedSkill,',
        '  assignedResourceNo, assignedDate, assignedStartTime, assignedEndTime, assignedHours,',
        '  sequenceNo',
        '}',
    ])
    return out


# ─── section 5 ───────────────────────────────────────────────────────────────

def section_5():
    out = h1('5', "Section 1 &mdash; Stats Header")
    out += [P(
        "Function: <font face='Courier'>renderWoSummaryScheduler(json)</font> | Host div: "
        "<font face='Courier'>#cpo-wo-summary</font> | View name: <font face='Courier'>workordersummary</font>"
    )]
    out += [P(
        "A 2-row synthetic <font face='Courier'>Scheduler.getSchedulerInstance()</font> timeline (NOT a real event "
        "calendar &mdash; it has no real events, only <font face='Courier'>cell_template</font>-rendered HTML per cell). "
        "The two rows are \"Calculated conclusion\" (% coverage + added shortage hours) and \"Current position shortage\" "
        "(hours caused specifically by this Work Order's own current schedule position)."
    )]
    out += [def_table(
        ['createTimelineView option', 'Value', 'Note'],
        [
            ['render', "'bar'", 'Standard timeline, not tree.'],
            ['x_unit / x_step / x_size', 'day / 1 / dates.length', 'One column per visible day.'],
            ['y_unit', '2 synthetic sections', "{key:'fit',...}, {key:'shortage',...} &mdash; not real DB rows."],
            ['dy', 'CALC_ROW_HEIGHT = 34px', 'Identical across all 3 Scheduler instances (1/2/4).'],
            ['column_width', 'COLUMN_WIDTH = 92px', 'DHTMLX auto-stretches columns wider than this unless total content already exceeds container width.'],
            ['dx', 'ROW_LABEL_WIDTH = 360px', 'Row-header width &mdash; the shared date-header row sections 1&ndash;3 all align under.'],
            ['scale_height', 'SCALE_HEIGHT = 36px', ''],
            ['cell_template', 'true', "Every cell's class AND value are custom HTML, computed live."],
        ],
        [4.4 * cm, 4.6 * cm, 8.4 * cm]
    )]
    out += [P(
        "Data source: nothing from the payload directly &mdash; every cell calls "
        "<font face='Courier'>this.evaluateWO(dayIndex)</font> / "
        "<font face='Courier'>this.currentPositionShortage()[dayIndex]</font> LIVE at render time (&sect;9), which "
        "read <font face='Courier'>this.db.dayPlanningLines</font>, <font face='Courier'>this.db.resources</font>, "
        "<font face='Courier'>this.db.externalFree</font>, <font face='Courier'>this.db.workOrderSequences</font>. "
        "There is no AL-precomputed \"statsRows\" array."
    )]
    out += callout(
        'Confirmed unaffected by the 2026-09-04 redesign',
        'The user explicitly reconfirmed mid-session: "the section 1 always run in JS as data already in JS". True before '
        'and after &sect;3.1 &mdash; renderWorkOrder() (called by BOTH the drag handler and moveWorkOrderToDay, and by the '
        'Confirm button\'s eventual real AL response once that trigger does real work) always calls '
        'woSummaryScheduler.setCurrentView(...) to force this section\'s cell templates to re-read whatever woAnchor is '
        'current, purely client-side.'
    )
    return out


# ─── section 6 ───────────────────────────────────────────────────────────────

def section_6():
    out = h1('6', "Section 2 &mdash; Work Order's Own Scheduler")
    out += [P(
        "Function: <font face='Courier'>renderWoScheduler(json)</font> &rarr; <font face='Courier'>renderWorkOrder()</font> "
        "| Host: <font face='Courier'>#cpo-wo-scheduler</font> (wrapped by <font face='Courier'>#cpo-wo-scheduler-wrap</font>, "
        "&sect;13.5) | View: <font face='Courier'>workorder</font>"
    )]
    out += [P(
        "A real Scheduler timeline with native drag-move enabled. One row per distinct Skill+Job+Task+SequenceNo "
        "combination the inspected Work Order itself demands (from <font face='Courier'>workOrderSequences[]</font>). "
        "Each row's events are positioned via a workday-offset formula "
        "(<font face='Courier'>idxWork(woAnchor, offset)</font>), not raw calendar \"Plan Date\" placement &mdash; "
        "dragging a bar shifts a single client-side <font face='Courier'>woAnchor</font> integer and re-renders the "
        "whole section instantly (optimistic, pure client-side simulation matching the reference exactly)."
    )]
    out += [def_table(
        ['createTimelineView option', 'Value', 'Note'],
        [
            ['render', "'bar'", ''],
            ['y_unit', 'one section per sequence', 'Built from json.workOrderSequences; falls back to a single "No Day Planning lines" placeholder row if empty.'],
            ['dy / event_dy', '32 / 24px', 'ROW_HEIGHT / ROW_HEIGHT - 8.'],
            ['dx', '360px', 'Same ROW_LABEL_WIDTH as section 1 (shares its date header).'],
            ['scale_height', '0', "Deliberately zero &mdash; shares section 1's header row. DHTMLX's own empty header row is force-hidden via CSS."],
            ['config.drag_move', 'true', 'The only section with native drag.'],
        ],
        [4.4 * cm, 4.2 * cm, 8.8 * cm]
    )]
    out += [P('<b>Events (drag / click) &mdash; updated 2026-09-04:</b>')]
    out += [def_table(
        ['Event', 'Behavior'],
        [
            ['onEventChanged (drag)', 'Computes the day-shift from the drop position, updates woAnchor if valid, resets anchor-dependent caches, re-renders (Sections 1-3), calls markUnconfirmedChange(). <b>No AL call</b> &mdash; was InvokeExtensibilityMethod(\'OnRescheduleWorkOrder\', ...) on every drag before &sect;3.1; the actual BC round-trip now only happens once, from the Confirm button.'],
            ['onClick', 'Opens the (still-stubbed) Capacity Lookup for that event\'s skill/day &mdash; openCapacityLookup(dayIdx, skill). Unaffected by &sect;3.1 (a view action, not a schedule edit &mdash; see &sect;3.1\'s closing note and the user\'s explicit confirmation to leave it as an immediate call).'],
        ],
        [3.6 * cm, 13.8 * cm]
    )]
    out += [P(
        "Data source: <font face='Courier'>json.workOrderSequences[]</font> for row structure; per-cell values pull "
        "from <font face='Courier'>workOrderAssignmentState</font>, which reads <font face='Courier'>dayPlanningLines[]</font> "
        "filtered to <font face='Courier'>line.workOrderNo === inspectedWorkOrderNo</font> (&sect;11/&sect;13.3 for why "
        "this must be the normalized <font face='Courier'>workOrderNo</font>, not always the raw table field)."
    )]
    out += callout(
        'Bug fixed 2026-09-03',
        'This section used to only pick up rows whose raw "Work Order No." table field equalled the inspected WO &mdash; but '
        'some of a Work Order\'s own genuine Day Planning Sequences (e.g. added via the Workorder Card\'s native "New '
        'sequence" button) can carry a blank value in that field. AL now scopes by Job No. = WorkOrder."Project No." AND '
        'Job Task No. = WorkOrder."Project Task No." instead.',
        kind='fix'
    )
    out += [P("NOT DHTMLX &mdash; hand-rolled HTML/CSS", 'BodySmall')]
    return out


# ─── section 7 ───────────────────────────────────────────────────────────────

def section_7():
    out = h1('7', 'Section 3 &mdash; Capacity vs Requested Daily Bars')
    out += [P(
        "Function: <font face='Courier'>renderCapacityBars(json)</font> | Host: <font face='Courier'>#cpo-capacity-bars</font>"
    )]
    out += [P(
        "This section is deliberately not a DHTMLX widget at all &mdash; it is plain generated HTML/CSS: for each "
        "visible day, a stacked \"C\" (Capacity: Assigned &rarr; Internal free &rarr; External free) column and a "
        "stacked \"R\" (Requested: Assigned &rarr; Unassigned-per-skill) column, plus Totals/Expand/Exp. to Task/"
        "Collapse buttons that control Section 4's tree open state (pure client-side, no AL round-trip). Column "
        "width is measured, not the literal COLUMN_WIDTH constant."
    )]
    out += [def_table(
        ['Data function', 'Reads', 'Produces'],
        [
            ['capParts(dayIndex)', 'dayPlanningLines[] (ALL work orders, unfiltered), resources[].length &times; baseCapacity, externalFree[dayIndex]', '{assigned, freeInt, freeExt} &mdash; the "C" column. Company-wide on purpose.'],
            ['dailyCapacityRequestData()', 'capParts() + dayPlanningLines[] filtered to line.workOrderNo === inspectedWO', 'One row per visible day: assigned, freeInt, freeExt, request, assignedRequest, unassignedBySkill{}, shortage.'],
        ],
        [4.0 * cm, 6.6 * cm, 6.8 * cm]
    )]
    out += callout(
        'Click-to-relocate drives Section 2 &mdash; updated 2026-09-04',
        'Clicking any non-weekend day cell in this section (not a double-click, which opens Capacity Lookup instead) calls '
        '<font face="Courier">moveWorkOrderToDay(dayIndex)</font>: sets woAnchor directly to that day, re-renders Sections 1-3, '
        'and calls markUnconfirmedChange() &mdash; exactly like a Section 2 drag, just reached by a click here instead. As of '
        '&sect;3.1, this is pure client-side with <b>no AL call at all</b> until the user clicks Confirm; before this session it '
        'fired InvokeExtensibilityMethod(\'OnRescheduleWorkOrder\', [dayIndex, ...]) on every click.',
        kind='fix'
    )
    out += [P(
        "Why the \"R\" (Requested) side IS work-order-filtered but the \"C\" (Capacity) side is NOT (&sect;11): Section 3 "
        "answers \"how does this Work Order's own demand sit against the company's real, fully company-wide capacity "
        "picture\" &mdash; the capacity side was already correct before the cross-WO change; only the demand side needed "
        "an explicit filter once dayPlanningLines[] started carrying every other Work Order's rows too."
    )]
    return out


# ─── section 8 ───────────────────────────────────────────────────────────────

def section_8():
    out = h1('8', 'Section 4 &mdash; Skill &rarr; Job/Task &rarr; Sequence Tree')
    out += [P(
        "Function: <font face='Courier'>renderCentralTree(json)</font> | Host: <font face='Courier'>#cpo-central-tree</font> "
        "(wrapped by <font face='Courier'>#cpo-central-tree-wrap</font>, &sect;13.5) | View: <font face='Courier'>centraltree</font>"
    )]
    out += [P(
        "The third real Scheduler instance, using <font face='Courier'>render:'tree'</font> (the treetimeline render "
        "mode). Three levels: Skill (folder) &rarr; Job/Task \"detail\" row (folder) &rarr; Sequence (leaf). Leaf "
        "day-cells can render multiple side-by-side \"chip\" cells when several real Day Planning lines land on the "
        "same day/sequence; parent Skill/Task rows show one aggregated heat-map percentage cell instead."
    )]
    out += [def_table(
        ['createTimelineView option', 'Value', 'Note'],
        [
            ['render', "'tree'", 'Only section using tree mode.'],
            ['y_unit', 'buildCentralSections() output', 'Client-built Skill&rarr;Task&rarr;Sequence hierarchy from groups[] + dayPlanningLines[].'],
            ['dy / folder_dy', 'ROW_HEIGHT = 32px (both)', ''],
            ['section_autoheight', 'false', "Intent: literal row height. In practice DHTMLX still fits total row height to its own init-target element's clientHeight &mdash; &sect;13.5's bug."],
            ['dx / header width', 'TREE_LABEL_WIDTH = 360px (3-column: Skill/Job/Task)', "Wider than sections 1-3's shared row label &mdash; a real 3-column grid header, own independent date row."],
            ['columns[0].template', 'centralTreeLeftColumnHtml(o)', 'Renders the 3-column Skill|Job|Task left panel per row.'],
        ],
        [4.3 * cm, 5.4 * cm, 7.7 * cm]
    )]
    out += [P('<b>Per-row/cell templates:</b>')]
    out += bullets([
        '<font face="Courier">centraltree_cell_value</font> &mdash; Skill rows call <font face="Courier">skillDaySummary()</font>; '
        'Job/Task "detail" rows call <font face="Courier">taskDaySummary()</font> (both render a gradient-filled % heat cell); Sequence '
        'leaf rows call <font face="Courier">sequenceDayCellHtml()</font> (renders the actual chip(s)). As of 2026-09-04 (&sect;13.8), '
        'all three read from a precomputed <font face="Courier">treeSummaryIndex()</font> instead of rescanning dayPlanningLines[] '
        'on every call.',
        'Chips are clickable/hoverable &mdash; <font face="Courier">attachTreeChipTooltip()</font> binds one shared mouseover/click '
        'handler on the whole host div, reusing the same tooltip element Section 2 uses. Click raises '
        '<font face="Courier">OnSequenceChipClick</font> (still an immediate AL call, see &sect;3.1\'s closing note).',
    ])
    out += callout(
        'Bug fixed 2026-09-03 (scope)',
        'groups[] (and therefore this whole tree) is built AL-side exclusively from every OTHER Work Order\'s demand in the '
        'visible window &mdash; the inspected Work Order\'s own data must never appear here. The exclusion criterion had to be '
        'corrected from the raw "Work Order No." field to a Job No./Job Task No. match against the inspected Work Order.',
        kind='fix'
    )
    out += callout(
        'Bug fixed 2026-09-03 &rarr; follow-on fixed 2026-09-04 (V-scrollbar)',
        'The ORIGINAL bug (&sect;13.5): DHTMLX was auto-shrinking every row\'s rendered height to fit its own init-target '
        'element\'s reported height, so a tree with far more rows than fit never actually overflowed and no scrollbar ever '
        'appeared &mdash; fixed by splitting the host into an unconstrained inner div (DHTMLX\'s real render target) wrapped by '
        'an outer div carrying the MIN/MAX-clamped height + overflow-y:auto. <b>The FOLLOW-ON bug found 2026-09-04</b>: that '
        'height was only ever applied ONCE, at the initial render &mdash; collapsing/expanding rows afterward left the wrapper '
        'sized for whatever row count was visible last, so the scrollbar thumb kept spanning the fully-expanded range and a '
        'blank gap appeared below the actual (now shorter) row list. See &sect;13.7 for the fix and live confirmation.',
        kind='fix'
    )
    out += callout(
        'Performance fixed 2026-09-04',
        'skillDaySummary/taskDaySummary/sequenceDayLines each used to rescan the ENTIRE dayPlanningLines[] array on every '
        'single rendered cell, making Expand/Collapse-all multi-second on real data even though nothing round-trips to BC. '
        'See &sect;13.8 for the treeSummaryIndex() fix and live-measured before/after numbers, and &sect;13.11 for why '
        'both skill and Job/Task folders now also start CLOSED on load rather than expanding that cost automatically.',
        kind='fix'
    )
    return out


# ─── section 9 ───────────────────────────────────────────────────────────────

def section_9():
    out = h1('9', 'The Shortage / Coverage Engine (Max-Flow)')
    out += [P(
        "Section 1's two rows and Section 3's implicit \"shortage\" figure are computed by a near-verbatim port of "
        "the reference prototype's own client-side algorithm &mdash; an Edmonds-Karp-style augmenting-path max-flow "
        "model (<font face='Courier'>maxFlowDay</font>), not a simple \"sum capacity vs sum demand\" formula."
    )]
    out += [def_table(
        ['Function', 'Purpose'],
        [
            ['maxFlowDay(dayIndex, demandBySkill)', 'Given one day\'s per-skill demand, computes the maximum achievable coverage across the (skill-scoped, capped) resource pool via flow conservation &mdash; achievable coverage is capped by demand, not supply.'],
            ['evaluateWO(dayIndex)', '"What if this Work Order\'s current schedule position is included?" &mdash; returns {coverage, addedShortage}, the source of Section 1\'s "Calculated conclusion" row.'],
            ['currentPositionShortage() / currentPositionSkillShortage()', 'Before/after delta: maxFlowDay WITHOUT this WO\'s demand vs WITH it, at its current woAnchor position &mdash; the source of Section 1\'s "Current position shortage" row and Section 2\'s per-row shortage badges.'],
        ],
        [5.6 * cm, 11.8 * cm]
    )]
    out += callout(
        'Why the algorithm was reversed back in (2026-09-02 decision)',
        'An earlier, simplified "sum team capacity minus other-WO-assigned-hours" formula had a real bug &mdash; a large '
        'company-wide resource pool produced coverage numbers over 5,700%. The max-flow model doesn\'t have this failure mode '
        'because achievable throughput is fundamentally bounded by demand, never by an oversized supply pool.'
    )
    out += [P(
        "<b>Performance caveat:</b> max-flow is expensive (roughly O(resources&sup2;) per day) and is called from BOTH "
        "Section 1's per-cell templates AND the shortage functions' own per-day loops, with no memoization in the "
        "reference. This port adds per-render-pass caching (<font face='Courier'>this._evalWOCache</font>, "
        "<font face='Courier'>this._currentPositionShortageArr</font>, cleared on every "
        "<font face='Courier'>applyPlanningData()</font> / <font face='Courier'>resetAnchorDependentCaches()</font>) "
        "and AL caps the resource pool at 15 per skill (<font face='Courier'>CPO_MaxResourcesPerSkill</font>) &mdash; "
        "both are deliberate, documented performance trade-offs, not data-completeness bugs. This caching is unaffected "
        "by the 2026-09-04 redesign: resetAnchorDependentCaches() is still called on every local reschedule move, before "
        "or after &sect;3.1 &mdash; only the AL call at the end of that path changed."
    )]
    return out


# ─── section 10 ──────────────────────────────────────────────────────────────

def section_10():
    out = h1('10', 'AL-Side Implementation Details')
    out += [P('<b>codeunit 50604 "DHX Data Handler" &mdash; CPO_ region, key procedures</b>')]
    out += [def_table(
        ['Procedure', 'Purpose'],
        [
            ['CPO_BuildPlanningDataJson_Paged(WorkOrderNo, NumberOfDays, MaxOtherLines, out RemainingGroupKeys): Text', 'The one entry point &mdash; assembles the entire payload in the 3-pass + pagination shape described in &sect;12.'],
            ['CPO_BuildDayPlanningLineObj(DayPlanning, InspectedWorkOrderNo, InspectedJobNo, InspectedJobTaskNo): JsonObject', 'One dayPlanningLines[] entry. Normalizes workOrderNo to the inspected WO\'s own No. whenever the line\'s Job No./Job Task No. match it.'],
            ['CPO_BuildSkillsArray / CPO_BuildResourcesArray / CPO_BuildExternalFreeArray / CPO_BuildGroupsArray', 'Build skills[] / resources[] / externalFree[] / groups[] respectively &mdash; &sect;4 for each one\'s exact scope.'],
            ['CPO_BuildWorkOrderSequencesArray', 'Builds workOrderSequences[] from the Pass-1 dedup lists.'],
            ['CPO_ComputeWorkdayOffset / CPO_IndexOfText / CPO_BuildDateRangeArray / CPO_FormatTimeHHMM', 'Small shared helpers (offset math, list lookup, date range, time formatting).'],
            ['CPO_MaxResourcesPerSkill(): Integer', 'Returns 15 &mdash; the max-flow performance cap (&sect;9).'],
        ],
        [6.0 * cm, 11.4 * cm]
    )]
    out += [P('<b>page 50722 "Capacity Planning Overview"</b>')]
    out += bullets([
        'No SourceTable &mdash; a bodiless Card page holding exactly one usercontrol.',
        "Caption = ''; &mdash; blank on purpose (the JS renders its own title bar).",
        'SetWorkOrderNo(pWorkOrderNo) &mdash; filter-setter-before-Run(), called by the launching page before opening.',
        'DaysToShow global var, default 30 (DefaultDaysToShow()) &mdash; page-level state; the reschedule flow\'s pending '
        '"unconfirmed change" state (2026-09-04) lives entirely client-side, NOT mirrored into any AL variable.',
        'RefreshData() &mdash; single shared rebuild-and-push routine called by ControlReady and OnDaysToShowChanged.',
        '<b>OnRescheduleWorkOrder(DayShift, PayloadJsonTxt)</b> &mdash; unchanged signature; 2026-09-04 removed its '
        'Message(\'Reschedule stub: shift=%1\', DayShift) body (&sect;13.10), now a true silent stub matching '
        'OnRequestCapacityLookup/OnSequenceChipClick. Only ever invoked from the Confirm button now (&sect;3.1), not per '
        'drag/click.',
    ])
    out += [P('<b>Pag50662.WorkorderCard.al &mdash; launching action</b>')]
    out += code_block([
        'action(CapacityPlanningOverviewAct)',
        '{',
        '    trigger OnAction()',
        '    var CPO: Page "Capacity Planning Overview";',
        '    begin',
        '        CPO.SetWorkOrderNo(Rec."Work Order No.");',
        '        CPO.Run();          // plain top-level navigation - see 13.6',
        '    end;',
        '}',
    ])
    return out


# ─── section 11 ──────────────────────────────────────────────────────────────

def section_11():
    out = h1('11', 'Cross-Work-Order Scoping (2026-09-03 Correction)')
    out += [P(
        'Explicit product decision, stated by the user in these exact terms: "section 3 for DWO0008 but section 4 for '
        'all day planning data in days time frame except DWO0008", further clarified as scoped "as long as in same time '
        'frame of days" and explicitly including "other WO in other job" (i.e. truly company-wide, not scoped to the '
        'inspected WO\'s own parent Job).'
    )]
    out += [def_table(
        ['Section', 'Scope', 'Rationale'],
        [
            ['Section 1 (stats)', 'Inspected WO only', '"This WO\'s own position." Literally IS the inspected WO\'s own schedule.'],
            ['Section 2 (own scheduler)', 'Inspected WO only', '"This WO\'s own demand."'],
            ['Section 3 &mdash; "R" (Requested)', 'Inspected WO only', 'A resource committed elsewhere that day is genuinely unavailable &mdash; already correct before this change.'],
            ['Section 3 &mdash; "C" (Capacity)', 'Company-wide (unfiltered)', '"Everything else going on in this window, for contention/context."'],
            ['Section 4 (tree)', 'Every OTHER Work Order, ANY Job, same date window', 'Intentionally the opposite of the earlier, narrower behavior ("this WO\'s own tree") &mdash; explicit and permanent.'],
        ],
        [4.6 * cm, 5.0 * cm, 7.8 * cm]
    )]
    out += [P(
        'Still true and unchanged by the 2026-09-04 confirm-gated redesign: nothing about &sect;3.1 alters WHICH data '
        'each section shows, only WHEN (if ever) a reschedule action tells BC about a change &mdash; Section 4\'s scope '
        'in particular is completely untouched, since it was already never re-rendered by any reschedule path.'
    )]
    return out


# ─── section 12 ──────────────────────────────────────────────────────────────

def section_12():
    out = h1('12', 'Performance &mdash; Page Background Task Pagination')
    out += [P(
        "Added 2026-09-03, on explicit user request. As Section 4's cross-Work-Order scope (&sect;11) made the add-in "
        "query every other Work Order's Day Planning demand company-wide for the visible window, real companies with a "
        "large Day Planning volume for that period made JSON generation (AL) and DHTMLX ingest (JS parse + tree/model "
        "build + render) slow enough to notice on first paint. The fix ports this repository's existing Page Background "
        "Task pattern &mdash; already used by request_assignment (codeunit 50721), projectschedule (codeunit 50720), and "
        "ganttdemo2 (codeunit 50713) &mdash; into CPO, following the exact same shape."
    )]

    out += h2('12.1', 'The technique (Business Central Page Background Task)')
    out += [def_table(
        ['API', 'Role'],
        [
            ['CurrPage.EnqueueBackgroundTask(TaskId, Codeunit, Parameters, TimeoutMs, ErrorLevel)', "Starts a child session running the given codeunit's OnRun trigger asynchronously, off the interactive request path. Returns immediately."],
            ['Page.GetBackgroundParameters(): Dictionary of [Text, Text]', 'Read inside the child codeunit\'s OnRun to retrieve the parameters passed at enqueue time.'],
            ['Page.SetBackgroundTaskResult(Dictionary of [Text, Text])', 'Called at the end of the child codeunit\'s OnRun to hand results back to the parent page.'],
            ['trigger OnPageBackgroundTaskCompleted(TaskId, Results)', 'Fires on the parent page when the child session finishes. Cannot safely call the control add-in from here &mdash; must stash the result into a plain AL variable instead.'],
            ['trigger OnPageBackgroundTaskError(TaskId, ErrorCode, ErrorText, ErrorCallStack, var IsHandled)', 'Fires on failure/timeout. Surfaced via a Notification, not a blocking error.'],
        ],
        [6.6 * cm, 10.8 * cm]
    )]
    out += [P(
        "Why results can't be pushed to the control add-in directly from <font face='Courier'>OnPageBackgroundTaskCompleted</font>: "
        "confirmed live across four independent add-ins in this repository &mdash; BC Server rejects a control add-in "
        "callback issued directly from that trigger. The workaround: stash the result into a plain page variable, then "
        "let a JS-initiated poll (a normal synchronous trigger call, safe to answer with a control add-in callback) "
        "pick it up and deliver it."
    )]

    out += h2('12.2', "CPO's architecture (mirrors request_assignment's board exactly)")
    out += code_block([
        'page 50722 RefreshData()',
        '  CPO_BuildPlanningDataJson_Paged(WorkOrderNo, DaysToShow, MaxOtherLines=50, out RemainingGroupKeys)',
        '  CurrPage.DhxCpo.SetPlanningData(json)                 // first paint: fast',
        '  EnqueueOtherWorkOrderDataBackgroundTask(RemainingGroupKeys)',
        '     CurrPage.EnqueueBackgroundTask(.., Codeunit::"CPO BG Other WO Data", params, 30000, ..)',
        '     CurrPage.DhxCpo.NotifyOtherWorkOrderDataTaskPending() // JS starts polling + shows #cpo-bg-loading (3.2)',
        '',
        '(async, off the interactive request path)',
        'codeunit "CPO BG Other WO Data".OnRun()',
        '    CPO_BuildOtherWorkOrderLinesJson_ForKeys(WorkOrderNo, StartDate, EndDate, RemainingGroupKeys)',
        '    Page.SetBackgroundTaskResult({ otherWorkOrderDataJson: json })',
        '',
        'trigger OnPageBackgroundTaskCompleted(TaskId, Results)',
        '    stash Results into PendingOtherWorkOrderDataJson (plain var - no control add-in call here)',
        '',
        'trigger OnPollOtherWorkOrderDataResult()              // JS-initiated, polled every 500ms',
        '    CurrPage.DhxCpo.AppendOtherWorkOrderData(PendingOtherWorkOrderDataJson)',
        '    CurrPage.DhxCpo.StopOtherWorkOrderDataPolling()   // also hides #cpo-bg-loading (3.2)',
    ])

    out += h2('12.3', 'The atomic pagination unit &mdash; whole Skill+Job No.+Job Task No. groups, never split')
    out += [P(
        "Exactly like request_assignment's sequenceKey pagination, CPO never splits a rendering unit across the "
        "synchronous first page and the background remainder. The unit here is a whole group &mdash; Skill+Job "
        "No.+Job Task No., the same combination Section 4's tree groups by."
    )]
    out += [def_table(
        ['Pass', 'Cost', 'Scope', 'Produces'],
        [
            ['CPO_ScanOtherWorkOrderGroups (Pass 3a)', 'Cheap &mdash; key fields only, no per-line JSON', 'ALWAYS full &mdash; every group, never paginated', 'Complete skills[]/resources[]/externalFree[]/groups[] + the group order/line-count needed to decide the page cutoff'],
            ['CPO_BuildOtherWorkOrderLinesForGroups (Pass 3b)', 'Expensive &mdash; lookups, time-to-decimal, full per-line JSON', 'Paginated &mdash; only whichever whole groups are in WantedGroupKeys', 'dayPlanningLines[] entries &mdash; the expensive part, and the only part actually deferred'],
        ],
        [5.0 * cm, 4.6 * cm, 3.8 * cm, 4.0 * cm]
    )]
    out += [P(
        "Practical effect: Section 4's tree skeleton renders complete on first paint, even over a huge dataset. Only "
        "the Sequence-level leaf chips for groups past the first 50 backfill progressively once the background task "
        "delivers them, typically within the same second or two on this demo dataset (confirmed live: 1,388 distinct "
        "groups across 8 skills, 5,042 total Day Planning lines merged successfully with zero console errors)."
    )]

    out += h2('12.4', 'Why Section 1/2/3 are treated differently')
    out += [def_table(
        ['Section', 'Paginated?', 'Reason'],
        [
            ['Section 2 (inspected WO\'s own scheduler)', 'No &mdash; Pass 1/2 unchanged', "Bounded to one Work Order's own lines &mdash; never the actual bottleneck."],
            ['Section 1 (stats) / Section 3 (capacity bars)', 'Indirectly &mdash; provisional until backfill completes', 'Computed from the full company-wide dayPlanningLines[]. Correct for whatever data has arrived so far, self-corrects once the remainder appends.'],
            ['Section 4 (tree)', 'Yes &mdash; the actual target', 'Skeleton always complete; chip-level detail backfills per &sect;12.3.'],
        ],
        [5.4 * cm, 4.6 * cm, 7.4 * cm]
    )]

    out += h2('12.5', "The JS-side append &mdash; why it's more than a tree rebuild")
    out += [P(
        "CPO's shortage/coverage engine (&sect;9) and Section 3's capacity bars are computed from the full "
        "dayPlanningLines[] set, so <font face='Courier'>appendOtherWorkOrderData(rawLines)</font> must: (1) push the "
        "new lines into <font face='Courier'>this.db.dayPlanningLines</font>; (2) invalidate every derived cache "
        "(including, as of 2026-09-04, <font face='Courier'>this._treeSummaryIndex</font> &mdash; &sect;13.8); (3) "
        "re-render Sections 1, 3, and 4 and re-bind the shared scrollbar. Section 2 is not re-rendered &mdash; its own "
        "source data was never paginated."
    )]

    out += h2('12.6', 'New/changed objects (2026-09-03)')
    out += [def_table(
        ['Object', 'Change'],
        [
            ['codeunit 50722 "CPO BG Other WO Data"', 'New. Background task target &mdash; modeled directly on codeunit 50721.'],
            ['codeunit 50604: CPO_BuildPlanningDataJson_Paged', 'New. Paged variant of CPO_BuildPlanningDataJson.'],
            ['codeunit 50604: CPO_ScanOtherWorkOrderGroups', 'New. Pass 3a &mdash; the cheap, always-full pre-scan.'],
            ['codeunit 50604: CPO_BuildOtherWorkOrderLinesForGroups', 'New. Pass 3b.'],
            ['codeunit 50604: CPO_BuildOtherWorkOrderLinesJson_ForKeys', 'New. Background-task companion.'],
            ['page 50722', 'RefreshData() now calls the paged builder + EnqueueOtherWorkOrderDataBackgroundTask; new background-task triggers.'],
            ['Controladdin', 'New procedures/events for the pagination poll.'],
            ['wrapper.js', 'New poll timer + window.AppendOtherWorkOrderData.'],
            ['capacityPlanningOverview.js', 'New appendOtherWorkOrderData(rawLines) method.'],
        ],
        [5.6 * cm, 11.8 * cm]
    )]
    return out


# ─── section 13 ──────────────────────────────────────────────────────────────

def pitfall(number, title, body_flowables):
    out = h3(f'13.{number} {title}')
    for item in body_flowables:
        if isinstance(item, list):
            out += item
        else:
            out.append(item)
    return out


def section_13():
    out = h1('13', 'Known Pitfalls, Bugs Found &amp; Fixes Applied (session log)')
    out += [P(
        'Renumbered 2026-09-04 &mdash; this section\'s entries were previously mislabelled 12.1&ndash;12.6 (reusing '
        '&sect;12\'s numbers, a copy-paste artifact of the original document); they are correctly 13.1&ndash;13.6 below, '
        'with the current session\'s findings added as 13.7&ndash;13.11.', 'BodySmall'
    )]

    out += pitfall(1, 'Unterminated CSS comment silently disabled the top bar', [P(
        "style.css had a comment inside #cpo-root {} that opened (/*) but never closed before that block's own }, so "
        "the first real */ the parser then found was ~30 lines later, silently swallowing .cpo-top-bar's and "
        ".cpo-top-title's entire rule bodies as dead comment text. Symptom: the title and \"Days to show\" input "
        "stacked on two plain, unstyled rows instead of one styled row. Fix: add the missing */ immediately after the "
        "intended one-paragraph comment."
    ), callout(
        'Lesson',
        "An unterminated CSS comment doesn't error &mdash; it silently consumes everything until the next literal */ "
        "anywhere later in the file. Always grep for balanced /* / */ pairs when a rule that \"should\" apply visibly doesn't."
    )])

    out += pitfall(2, 'RunModal() vs Run() &mdash; native BC chrome', [P(
        "Opening the page via RunModal() always renders BC's own dialog chrome (bold title bar + command bar + Close "
        "button) regardless of the page's own Caption or field content. Switching to Run() (plain top-level "
        "navigation, the same pattern page 50710 \"DHX Request Assignment Board\" already used) replaces it with just "
        "a back arrow, matching the reference prototype's own minimal chrome."
    )])

    out += pitfall(3, '"Work Order No." field vs Job No./Job Task No. scoping', [P(
        'See &sect;6/&sect;8/&sect;11. The native Workorder Card\'s own "Day Planning Sequence" part filters Day '
        'Planning by Job No./Job Task No., never by the "Work Order No." field. Some genuine Day Planning Sequences '
        'can have that field blank. Any AL query that scopes "this Work Order\'s own data" by the "Work Order No." '
        'field alone will silently miss such rows &mdash; and symmetrically, any exclusion keyed the same way will '
        'wrongly include them as if they belonged to someone else.'
    )])

    out += pitfall(4, 'Flexbox default shrink crushed the shared scrollbar', [P(
        "#cpo-root is a fixed-height display:flex; flex-direction:column container. #cpo-shared-scroll (declared "
        "height:16px) had no flex-shrink override, so whenever the other sections' combined natural height exceeded "
        "#cpo-root's own bounded height, the flex column's default flex-shrink:1 proportionally squashed every child "
        "&mdash; measured live: rendered height collapsed to 1px. Fix: flex: 0 0 16px; (no shrink, no grow, fixed 16px basis)."
    )])

    out += pitfall(5, "DHTMLX auto-fits row height to its container &mdash; scrollbars never appear (original fix)", [P(
        "Even with dy/folder_dy fixed and section_autoheight:false, DHTMLX Scheduler reads its own init-target "
        "element's clientHeight at render time and fits all row content to exactly that height (shrinking rows) "
        "rather than rendering at the literal configured height and overflowing. Fix (Sections 2 and 4): split the "
        "single host div into two nested divs &mdash; DHTMLX initializes into an inner div left height-unconstrained, "
        "while a new outer wrapper div carries the MIN/MAX-clamped height and overflow-y:auto that actually does the "
        "visual clipping/scrolling. See &sect;13.7 for the 2026-09-04 follow-on to this fix."
    )])

    out += pitfall(6, 'Concurrent publish/build collisions', [P(
        "Running multiple al_publish operations from parallel sessions/subagents against the same sandbox environment "
        "can produce a spurious CompilationFailed even when al_getdiagnostics shows zero real errors &mdash; a "
        "file-lock/build collision, not a code defect. Resolved by waiting for the other publish to finish and retrying."
    )])

    out += pitfall(7, 'Section 4 scrollbar drifted from the actual row composition after collapse/expand', [P(
        '<b>New, 2026-09-04.</b> &sect;13.5\'s fix solved the INITIAL scrollbar bug, but applyCentralTreeHeight was only '
        'ever called once, at the initial renderCentralTree pass &mdash; collapsing/expanding rows afterward (via '
        'setTreeOpenState\'s Expand/Collapse-all buttons, or a single row\'s own native fold arrow) never re-ran it, so '
        'the wrapper\'s clip height stayed sized for whatever row count was visible at the LAST full render. Symptom '
        '(reported by the user with a screenshot): collapse all rows, and the scrollbar thumb still spans the '
        'fully-expanded range, leaving a blank scrollable gap below the now-much-shorter row list.'
    ), callout(
        'Fix',
        'bindCentralTreeHeightSync listens for DHTMLX\'s onOptionsLoad event (fired both by setTreeOpenState and by a '
        'single row\'s own native toggle) and re-applies applyCentralTreeHeight against the LIVE tree state every time. '
        'setTreeOpenState additionally pre-applies the height BEFORE firing onOptionsLoad, so DHTMLX\'s own native '
        'redraw already reads the corrected height on its one pass &mdash; no forced second redraw needed (an earlier '
        'attempt added an explicit setCurrentView() call here on the theory that DHTMLX\'s native handler might read a '
        'stale height otherwise; &sect;13.8 explains why that call was removed again).',
        kind='fix'
    ), callout(
        'Confirmed live',
        "Collapse-all shrank the wrapper's scrollHeight from 90,476px to 300px (the MIN_TREE_HEIGHT clamp); a single "
        "row's own toggle correctly produced an intermediate 24,012px; Expand-all scrolled cleanly to the true last "
        "row with no blank gap in all three cases."
    )])

    out += pitfall(8, 'O(rows &times; days &times; dayPlanningLines) per-cell rescans made Expand/Collapse-all multi-second', [P(
        '<b>New, 2026-09-04</b> &mdash; raised by the user as "as Data already in JS, why take long time during expands '
        'and collapse?". skillDaySummary/taskDaySummary/sequenceDayLines each did a full .forEach/.filter scan over '
        'the ENTIRE dayPlanningLines array (this WO\'s lines plus every other WO\'s &mdash; &sect;11) &mdash; and DHTMLX '
        'calls each of these once per RENDERED CELL (every visible row &times; every visible day) during its native '
        'tree redraw. Real cost: O(rows &times; days &times; dayPlanningLines.length) &mdash; genuine, user-visible '
        'latency purely on the client, unrelated to any AL round-trip.'
    ), callout(
        'A wrong first diagnosis, corrected by profiling',
        'The &sect;13.7 fix\'s own earlier draft added an explicit setCurrentView() call on the theory that it was '
        'needed for correctness. When THIS bug was investigated, profiling with that call instrumented (not yet '
        'removed) showed it consuming ~5.4s of a ~5.4s total cost &mdash; but removing it entirely and re-profiling '
        'showed the SAME ~6.3s cost still fell inside DHTMLX\'s own native redraw call, proving the extra call was '
        'never the real bottleneck. Lesson (explicitly worth keeping): attribute a regression to a specific recent '
        'change only after profiling the counterfactual, not by inspection or recency alone.'
    ), callout(
        'Fix',
        'treeSummaryIndex() groups dayPlanningLines ONCE per data load (O(dayPlanningLines.length) total, invalidated '
        'on the same applyPlanningData/appendOtherWorkOrderData calls that already reset the other derived caches, '
        '&sect;9) into skill+day / skill+job+task+day / skill+job+task+sequence+day lookup maps. The three summary '
        'functions became O(1) map lookups.',
        kind='fix'
    ), callout(
        'Confirmed live',
        'On DWO0006\'s real data, Expand-all dropped from ~5.4-6.3s to ~1.7s (&asymp;3.5&times;), with identical output '
        '(same hour totals, no squished/misaligned rows, correct scrollbar behavior per &sect;13.7).'
    )])

    out += pitfall(9, 'InvokeExtensibilityMethod is fire-and-forget from JS\'s own perspective', [P(
        '<b>New finding, 2026-09-04</b> &mdash; discovered while investigating &sect;13.7/&sect;13.8 and directly '
        'informing the &sect;3.1 redesign and &sect;3.2\'s indicator design. Confirmed live by wrapping the call with '
        'performance.now() timing: the JS call itself returns in well under 1ms regardless of what the AL trigger it '
        'targets actually does &mdash; even a genuinely slow AL round-trip (a "Days to show" reload rebuilding '
        'company-wide data took ~82s wall-clock in one measurement) does not block the calling JS thread. The real '
        'response, if any, always arrives later through a SEPARATE AL-to-JS call (SetPlanningData, '
        'AppendOtherWorkOrderData, LoadCapacityLookup), never as a return value from the invoke itself.'
    ), callout(
        'Practical effect on this add-in\'s own design',
        'showLoading() called immediately before InvokeExtensibilityMethod always gets a real paint for free, since '
        'the call yields control back to the browser well before AL finishes &mdash; no requestAnimationFrame '
        'deferral trick needed there (openCapacityLookup, the Section 4 chip click, confirmChanges all rely on this). '
        'That trick (runBusy, &sect;3.2) is needed ONLY around genuinely synchronous CPU-bound client work with no '
        'natural browser yield point &mdash; DHTMLX\'s own tree redraw (&sect;13.8), specifically.'
    )])

    out += pitfall(10, 'Reschedule stub feedback: blocking dialog &rarr; JS notice &rarr; removed entirely for a Confirm button', [P(
        '<b>New, 2026-09-04.</b> OnRescheduleWorkOrder\'s stub originally proved its wiring fired via a native '
        'Message(\'Reschedule stub: shift=%1\', DayShift) dialog. That was reasonable when reschedule was a rare, '
        'deliberate action &mdash; but at the time every single drag/click-to-relocate fired it, interrupting the '
        'user with a mandatory OK click on every intermediate step (screenshot evidence: a dialog stacked directly '
        'over the schedule mid-drag).'
    ), callout(
        'Iteration 1 &mdash; non-blocking JS notice',
        'Removed the AL Message() call, replaced with a small non-blocking JS-rendered notice (a bordered text box in '
        'Section 3\'s fixed left column, auto-hiding after 4s) showing the same "Reschedule stub: shift=N" text, '
        'computed entirely client-side (the shift value was already known in JS before ever invoking AL).'
    ), callout(
        'Iteration 2 (final) &mdash; removed entirely',
        'Once reschedule became fully local-simulation + Confirm-gated (&sect;3.1), the per-action notice\'s whole '
        'reason for existing disappeared too &mdash; there is no longer a per-action AL call to "prove fired". Removed; '
        'the Confirm button\'s own enabled/pending visual state (.cpo-confirm-btn-pending) is what now signals "you '
        'have an unconfirmed move" instead.',
        kind='fix'
    )])

    out += pitfall(11, 'Expand-all still felt slow after &sect;13.8 &mdash; three dead ends before the real fix', [P(
        '<b>New, 2026-09-04</b> &mdash; even after treeSummaryIndex (&sect;13.8) cut Expand-all to ~1.7-2.1s, the user '
        'kept pushing on "it must be faster, data is already in DHTMLX" (fair &mdash; 1.7s still reads as sluggish for '
        'a purely local operation). Three approaches were tried and profiled live before landing on the one that '
        'actually worked.'
    ), callout(
        'Dead end 1 &mdash; DHTMLX Scheduler\'s own smart_rendering option',
        'Scheduler\'s minified bundle ships a viewport-based lazy-render path (_timeline_smart_render.getViewPort). '
        'Enabling smart_rendering: true on the centraltree view was a natural next try &mdash; measured live, it made '
        'Expand-all SLOWER (~8.1s, not faster). Reverted. Likely not effective for render:\'tree\' mode\'s folder '
        'hierarchy the way it is for a flat timeline.'
    ), callout(
        'Dead end 2 &mdash; swap Section 4 to the DHTMLX Gantt library',
        'The Gantt add-in\'s (ganttdemo2) own collapse/expand (gantt.eachTask(t=&gt;t.$open=open); gantt.render()) is '
        'fast because DHTMLX Gantt virtualizes rows natively. Investigated as a full swap; found two real obstacles '
        'first: Gantt\'s LEFT grid/tree panel does not scroll horizontally on its own (only its chart/timeline pane '
        'does), and that chart pane draws task BARS positioned by date range, not arbitrary per-cell HTML the way '
        'Scheduler\'s cell_template does &mdash; Section 4\'s heat-cells/chips would need to become day-wide bars to fit '
        'that model. Surfaced to the user as a scoped decision before any code was written; the user chose to stay on '
        'Scheduler rather than take on that rewrite.'
    ), callout(
        'Dead end 3 &mdash; "copy Task Scheduler\'s mechanism"',
        'The user pointed at Task Scheduler (projectschedule) as an example of fast expand/collapse still on DHTMLX '
        'Scheduler. Reading its actual ToggleCollapseExpandAllSections in projectschedule/wrapper.js showed it is '
        'BYTE-FOR-BYTE the same technique CPO\'s own setTreeOpenState already uses (same y_unit_original mutation, '
        'same _getArrayToDisplay, same onOptionsLoad call) &mdash; CPO\'s own code comment already says it was ported '
        'from that exact function. There was no different mechanism to copy. The real gap is scale: Task Scheduler\'s '
        'tree is Job&rarr;Job Task (scoped, few rows); CPO\'s Section 4 fully expanded to Sequence level, company-wide '
        '(&sect;11), is 2,831 rows &mdash; DHTMLX\'s native redraw cost after onOptionsLoad scales with row count '
        'regardless of which code toggles the open flags.'
    ), callout(
        'Fix &mdash; start collapsed, pay the cost only when asked',
        'buildCentralSections() now sets open: false for BOTH the skill and the Job/Task "detail" level on every '
        'render pass, regardless of AL\'s own groups[].expanded flag (which drove the skill level\'s initial state '
        'before). Expand-all\'s ~1.7-2.1s is real, unavoidable-at-that-scale DOM-construction cost for 2,831 rows '
        '&mdash; the fix is not making that number smaller, it is making sure the user only ever pays it when they '
        'actually click Expand, not on every page open.',
        kind='fix'
    ), callout(
        'Confirmed live',
        'Fresh page load: all 8 skill rows render collapsed instantly (wrapper clientHeight/scrollHeight both 300px, '
        'the MIN_TREE_HEIGHT clamp - no scrollbar needed at all). Expand-all afterward: scrollHeight grows to 90,636px '
        'in ~2.16s (the &sect;13.8-era cost, now opt-in only), and scrolling to the bottom lands exactly at the true '
        'last row with no blank gap - confirming &sect;13.7\'s scrollbar-sync fix still holds with the new default state.'
    )])
    return out


# ─── section 14 ──────────────────────────────────────────────────────────────

def section_14():
    out = h1('14', 'Appendix &mdash; File Reference')
    out += [def_table(
        ['Path (relative to repo root)', 'Contents'],
        [
            ['src\\dhx\\capacity_planning_overview\\DHXCapacityPlanningOverviewAddin.ControlAddin.al', 'Controladdin declaration'],
            ['src\\dhx\\capacity_planning_overview\\page_50722_CapacityPlanningOverview.al', 'Host page 50722'],
            ['src\\dhx\\capacity_planning_overview\\startupScript.js', 'BOOT() call'],
            ['src\\dhx\\capacity_planning_overview\\wrapper.js', 'BOOT/binding shell + loading-overlay safety timer (&sect;3.2)'],
            ['src\\dhx\\capacity_planning_overview\\capacityPlanningOverview.js', 'The single JS component (~1,850 lines) &mdash; all 4 sections + shortage engine + Confirm-gated reschedule state machine (&sect;3.1) + processing indicators (&sect;3.2) + treeSummaryIndex (&sect;13.8)'],
            ['src\\dhx\\capacity_planning_overview\\style.css', 'All layout/heat-map/chip/scrollbar/spinner/Confirm-button CSS'],
            ['src\\codeunit\\codeunit_50604_DHXDataHandler.al', 'Shared data-handler codeunit &mdash; CPO_ region builds the payload'],
            ['src\\dhx\\capacity_planning_overview\\codeunit_50722_CPOBGOtherWorkOrderData.al', 'Page Background Task target &mdash; &sect;12'],
            ['src\\page\\Pag50662.WorkorderCard.al', 'Launching action CapacityPlanningOverviewAct'],
            ['src\\dhx\\dhtmlxscheduler.js / .css', 'Shared vendor Scheduler library (root-level, reused by every DHX add-in)'],
            ['src\\dhx\\suite.js / .css', 'Shared vendor Suite library (declared but not currently used by this add-in\'s own modal, which is stubbed)'],
            ['C:\\Users\\Ahmad\\OneDrive\\x\\PROJECT\\KLAAS\\CPO_v131\\DHTMLXtempv112-app.js', 'Reference prototype this add-in is ported from (external to this repo)'],
        ],
        [8.4 * cm, 9.0 * cm]
    )]
    out += [Spacer(1, 10), P('End of document.', 'Footer')]
    return out


def on_page(c: canvas.Canvas, doc):
    c.saveState()
    c.setFont('Helvetica', 7.5)
    c.setFillColor(colors.HexColor('#9AA5B8'))
    c.drawString(1.6 * cm, 1.1 * cm, 'Capacity Planning Overview - Technical Document (2026-09-04)')
    c.drawRightString(LETTER[0] - 1.6 * cm, 1.1 * cm, f'Page {doc.page}')
    c.restoreState()


def build():
    doc = SimpleDocTemplate(
        OUTPUT_PATH, pagesize=LETTER,
        leftMargin=1.6 * cm, rightMargin=1.6 * cm, topMargin=1.5 * cm, bottomMargin=1.6 * cm,
        title='Capacity Planning Overview - Technical Document', author='DailyOptimizer (Optimizers)',
    )
    story = []
    story += cover_page()
    story += section_1()
    story += section_2()
    story += section_3()
    story += section_4()
    story += section_5()
    story += section_6()
    story += section_7()
    story += section_8()
    story += section_9()
    story += section_10()
    story += section_11()
    story += section_12()
    story += section_13()
    story += section_14()
    doc.build(story, onFirstPage=on_page, onLaterPages=on_page)
    print(f'Wrote {OUTPUT_PATH}')


if __name__ == '__main__':
    build()
