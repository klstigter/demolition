"""Shared reportlab helpers for the Gantt (page 50620) technical document."""
from reportlab.lib import colors
from reportlab.lib.enums import TA_LEFT
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.platypus import (Paragraph, Spacer, Table, TableStyle, PageBreak,
                                Preformatted, KeepTogether, Flowable)
from reportlab.graphics.shapes import Drawing, Rect, String, Line, Polygon

PAGE_W, PAGE_H = A4
LEFT = RIGHT = 18 * mm
CONTENT_W = PAGE_W - LEFT - RIGHT

NAVY = colors.HexColor("#1f3a5f")
BLUE = colors.HexColor("#2a5daa")
LIGHT = colors.HexColor("#eef3fb")
GREY = colors.HexColor("#f4f5f7")
LINE = colors.HexColor("#c9d1dc")
AMBER = colors.HexColor("#fff6e0")

_base = getSampleStyleSheet()


def _ps(name, **kw):
    return ParagraphStyle(name, parent=_base["Normal"], **kw)


S = {
    "body": _ps("body", fontName="Helvetica", fontSize=9.4, leading=13.2, spaceAfter=5, alignment=TA_LEFT),
    "small": _ps("small", fontName="Helvetica", fontSize=8.2, leading=10.6),
    "cell": _ps("cell", fontName="Helvetica", fontSize=8.0, leading=10.0),
    "cellb": _ps("cellb", fontName="Helvetica-Bold", fontSize=8.0, leading=10.0),
    "cellh": _ps("cellh", fontName="Helvetica-Bold", fontSize=8.0, leading=10.0, textColor=colors.white),
    "code": _ps("code", fontName="Courier", fontSize=7.8, leading=9.6),
    "mono": _ps("mono", fontName="Courier", fontSize=8.0, leading=10.0),
    "h1": _ps("h1", fontName="Helvetica-Bold", fontSize=17, leading=21, textColor=NAVY, spaceBefore=4, spaceAfter=8),
    "h2": _ps("h2", fontName="Helvetica-Bold", fontSize=12.5, leading=16, textColor=BLUE, spaceBefore=10, spaceAfter=5),
    "h3": _ps("h3", fontName="Helvetica-Bold", fontSize=10.2, leading=13, textColor=NAVY, spaceBefore=7, spaceAfter=3),
    "bullet": _ps("bullet", fontName="Helvetica", fontSize=9.2, leading=12.6, leftIndent=12, bulletIndent=2, spaceAfter=2),
    "note": _ps("note", fontName="Helvetica", fontSize=8.8, leading=12, leftIndent=6, rightIndent=6),
    "title": _ps("title", fontName="Helvetica-Bold", fontSize=26, leading=31, textColor=NAVY, spaceAfter=10),
    "subtitle": _ps("subtitle", fontName="Helvetica", fontSize=13, leading=17, textColor=BLUE, spaceAfter=6),
}


def esc(t):
    return (str(t).replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;"))


def rich(t):
    """Allow **bold** and `code` inline markup on top of escaped text."""
    import re
    t = esc(t)
    t = re.sub(r"\*\*(.+?)\*\*", r"<b>\1</b>", t)
    t = re.sub(r"`(.+?)`", r'<font face="Courier" size="8">\1</font>', t)
    return t


class Outline:
    """Collects headings so the main script can build a table of contents."""
    entries = []


class Heading(Paragraph):
    def __init__(self, text, style, level):
        super().__init__(text, style)
        self.level = level
        self.plain = text


def h1(story, text):
    story.append(PageBreak())
    story.append(_head(text, "h1", 0))


def _head(text, style, level):
    p = Heading(esc(text), S[style], level)
    p._bookmark = "bm_%d" % len(Outline.entries)
    Outline.entries.append((level, text, p._bookmark))
    return _Anchor(p)


class _Anchor(Flowable):
    def __init__(self, para):
        super().__init__()
        self.para = para
        self.keepWithNext = True

    def wrap(self, aw, ah):
        w, h = self.para.wrap(aw, ah)
        self.width, self.height = w, h
        return w, h

    def split(self, aw, ah):
        return [self]

    def draw(self):
        c = self.canv
        c.bookmarkPage(self.para._bookmark)
        c.addOutlineEntry(self.para.plain, self.para._bookmark, level=self.para.level, closed=(self.para.level > 0))
        self.para.drawOn(c, 0, 0)


def h2(story, text):
    story.append(_head(text, "h2", 1))


def h3(story, text):
    story.append(_head(text, "h3", 2))


def p(story, text):
    story.append(Paragraph(rich(text), S["body"]))


def bullets(story, items):
    for it in items:
        story.append(Paragraph(rich(it), S["bullet"], bulletText="•"))
    story.append(Spacer(1, 3))


def numbered(story, items):
    for i, it in enumerate(items, 1):
        story.append(Paragraph(rich(it), S["bullet"], bulletText="%d." % i))
    story.append(Spacer(1, 3))


def note(story, text, kind="note"):
    bg = AMBER if kind == "warn" else LIGHT
    label = "Note: " if kind == "note" else ("Caution: " if kind == "warn" else "")
    t = Table([[Paragraph("<b>%s</b>%s" % (label, rich(text)), S["note"])]], colWidths=[CONTENT_W])
    t.setStyle(TableStyle([("BACKGROUND", (0, 0), (-1, -1), bg),
                           ("BOX", (0, 0), (-1, -1), 0.5, LINE),
                           ("LEFTPADDING", (0, 0), (-1, -1), 6), ("RIGHTPADDING", (0, 0), (-1, -1), 6),
                           ("TOPPADDING", (0, 0), (-1, -1), 4), ("BOTTOMPADDING", (0, 0), (-1, -1), 4)]))
    story.append(t)
    story.append(Spacer(1, 6))


def code(story, text):
    pre = Preformatted(text.strip("\n"), S["code"])
    t = Table([[pre]], colWidths=[CONTENT_W])
    t.setStyle(TableStyle([("BACKGROUND", (0, 0), (-1, -1), GREY), ("BOX", (0, 0), (-1, -1), 0.4, LINE),
                           ("LEFTPADDING", (0, 0), (-1, -1), 6), ("TOPPADDING", (0, 0), (-1, -1), 4),
                           ("BOTTOMPADDING", (0, 0), (-1, -1), 4)]))
    story.append(t)
    story.append(Spacer(1, 6))


def table(story, header, rows, widths, mono_cols=(), bold_first=True, font=None):
    """widths are fractions of CONTENT_W."""
    cw = [CONTENT_W * w for w in widths]
    data = [[Paragraph(esc(h), S["cellh"]) for h in header]]
    for r in rows:
        line = []
        for ci, c in enumerate(r):
            if ci in mono_cols:
                line.append(Paragraph('<font face="Courier" size="7.6">%s</font>' % esc(c), S["cell"]))
            elif ci == 0 and bold_first:
                line.append(Paragraph(rich(c), S["cellb"]))
            else:
                line.append(Paragraph(rich(c), S["cell"]))
        data.append(line)
    t = Table(data, colWidths=cw, repeatRows=1)
    st = [("BACKGROUND", (0, 0), (-1, 0), NAVY),
          ("GRID", (0, 0), (-1, -1), 0.3, LINE),
          ("VALIGN", (0, 0), (-1, -1), "TOP"),
          ("LEFTPADDING", (0, 0), (-1, -1), 4), ("RIGHTPADDING", (0, 0), (-1, -1), 4),
          ("TOPPADDING", (0, 0), (-1, -1), 3), ("BOTTOMPADDING", (0, 0), (-1, -1), 3)]
    for i in range(1, len(data)):
        if i % 2 == 0:
            st.append(("BACKGROUND", (0, i), (-1, i), LIGHT))
    t.setStyle(TableStyle(st))
    story.append(t)
    story.append(Spacer(1, 8))


def flow(story, boxes, title=None, width=CONTENT_W, box_h=30, gap=14):
    """Vertical flow diagram. boxes: list of (label, sublabel)."""
    n = len(boxes)
    h = n * box_h + (n - 1) * gap + 10
    d = Drawing(width, h)
    bw = width * 0.86
    x0 = (width - bw) / 2
    y = h - 5 - box_h
    for i, (a, b) in enumerate(boxes):
        d.add(Rect(x0, y, bw, box_h, rx=4, ry=4, fillColor=LIGHT if i % 2 == 0 else colors.white,
                   strokeColor=BLUE, strokeWidth=0.8))
        d.add(String(x0 + 8, y + box_h - 12, a, fontName="Helvetica-Bold", fontSize=8.4, fillColor=NAVY))
        if b:
            d.add(String(x0 + 8, y + 6, b[:150], fontName="Helvetica", fontSize=7.2, fillColor=colors.HexColor("#333333")))
        if i < n - 1:
            cx = width / 2
            d.add(Line(cx, y, cx, y - gap + 3, strokeColor=BLUE, strokeWidth=1))
            d.add(Polygon([cx - 3, y - gap + 6, cx + 3, y - gap + 6, cx, y - gap + 1], fillColor=BLUE, strokeColor=BLUE))
        y -= box_h + gap
    story.append(d)
    story.append(Spacer(1, 6))


def layers(story):
    """Architecture layer diagram."""
    w = CONTENT_W
    h = 205
    d = Drawing(w, h)

    def box(x, y, bw, bh, title, lines, fill):
        d.add(Rect(x, y, bw, bh, rx=4, ry=4, fillColor=fill, strokeColor=BLUE, strokeWidth=0.9))
        d.add(String(x + 6, y + bh - 12, title, fontName="Helvetica-Bold", fontSize=8.6, fillColor=NAVY))
        yy = y + bh - 24
        for ln in lines:
            d.add(String(x + 6, yy, ln, fontName="Helvetica", fontSize=7.3, fillColor=colors.HexColor("#222222")))
            yy -= 9.6

    box(0, 140, w, 62, "Business Central (AL) - server + web client",
        ["Page 50620 'Gantt Demo DHX 2'  (triggers, actions, page variables)",
         "Codeunits 50613 data handler | 50615 task update | 50616 links | 50617 period sync | 50713 background task",
         "Tables: Job Task, Day Planning, Resource, Gantt Chart Setup (50620), BCG Gantt Task Link"], LIGHT)
    box(0, 78, w, 54, "Control add-in 'DHX Gantt Control 2'  (GantttControl.controladdin.al)",
        ["Contract between AL and JS: 22 events (JS -> AL) and 29 procedures (AL -> JS)",
         "Loads dhtmlxgantt.js, wrapper.js, style.css, dhtmlxgantt.css; StartupScript = BOOT()"], colors.white)
    box(0, 0, w, 70, "Browser iframe  (wrapper.js on top of dhtmlxgantt.js)",
        ["BOOT(): configures dhtmlx Gantt, layout, templates, events, context menus, data stores",
         "Task panel = main grid + timeline | Resource panel = bound grid + custom-rendered timeline layer",
         "Datastores: resourcesStore, DayPlanningsStore | indexes: DayPlanningsByTask, requestJobTaskSet"], LIGHT)
    for x in (w * 0.3, w * 0.7):
        d.add(Line(x, 132, x, 140, strokeColor=BLUE, strokeWidth=1))
        d.add(Line(x, 70, x, 78, strokeColor=BLUE, strokeWidth=1))
    d.add(String(w * 0.3 + 4, 133, "CurrPage.DHXGanttControl2.<Procedure>()", fontName="Helvetica-Oblique", fontSize=6.8, fillColor=BLUE))
    d.add(String(w * 0.7 + 4, 133, "InvokeExtensibilityMethod(<Event>)", fontName="Helvetica-Oblique", fontSize=6.8, fillColor=BLUE))
    story.append(d)
    story.append(Spacer(1, 6))
