"""Generates 'Gantt Page 50620 - Technical Document.pdf' in this folder.

Run from anywhere:  python docs/generate_gantt_50620_doc.py
Content lives in docs/gantt_doc/part1.py .. part3.py (helpers in lib.py). Edit those and re-run;
never hand-edit the PDF.
"""
import os
import sys
import datetime

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)

from reportlab.lib.pagesizes import A4
from reportlab.lib.units import mm
from reportlab.platypus import BaseDocTemplate, PageTemplate, Frame, Paragraph, Spacer, PageBreak, Table, TableStyle
from reportlab.platypus.tableofcontents import TableOfContents
from reportlab.lib.styles import ParagraphStyle

from gantt_doc import lib
from gantt_doc.lib import S, NAVY, BLUE, LIGHT, LINE, CONTENT_W, PAGE_W, PAGE_H, LEFT, RIGHT, _Anchor
from gantt_doc import part1, part2, part3

OUT = os.path.join(HERE, "Gantt Page 50620 - Technical Document.pdf")
TITLE = "Gantt Page 50620 - Technical Document"


class Doc(BaseDocTemplate):
    def __init__(self, fn, **kw):
        super().__init__(fn, pagesize=A4, leftMargin=LEFT, rightMargin=RIGHT, topMargin=20 * mm, bottomMargin=18 * mm,
                         title=TITLE, author="Optimizers - Daily Optimizer", subject="Page 50620 Gantt Demo DHX 2", **kw)
        frame = Frame(self.leftMargin, self.bottomMargin, self.width, self.height, id="f")
        self.addPageTemplates([PageTemplate(id="p", frames=[frame], onPage=self._decor)])

    def _decor(self, canv, doc):
        canv.saveState()
        if doc.page > 1:
            canv.setFont("Helvetica", 7.8)
            canv.setFillColor(colors_grey())
            canv.drawString(LEFT, PAGE_H - 12 * mm, TITLE)
            canv.drawRightString(PAGE_W - RIGHT, PAGE_H - 12 * mm, "Page 50620 'Gantt Demo DHX 2' / DHX Gantt Control 2")
            canv.setStrokeColor(LINE)
            canv.line(LEFT, PAGE_H - 13.5 * mm, PAGE_W - RIGHT, PAGE_H - 13.5 * mm)
            canv.line(LEFT, 13 * mm, PAGE_W - RIGHT, 13 * mm)
            canv.drawRightString(PAGE_W - RIGHT, 8.5 * mm, "Page %d" % doc.page)
        canv.restoreState()

    def afterFlowable(self, fl):
        if isinstance(fl, _Anchor):
            self.notify("TOCEntry", (fl.para.level, fl.para.plain, self.page))


def colors_grey():
    from reportlab.lib import colors
    return colors.HexColor("#666666")


def cover(st):
    st.append(Spacer(1, 55 * mm))
    st.append(Paragraph("Gantt Page 50620", S["title"]))
    st.append(Paragraph("Technical Document", S["title"]))
    st.append(Spacer(1, 4 * mm))
    st.append(Paragraph("How the BC page 'Gantt Demo DHX 2', the control add-in 'DHX Gantt Control 2', wrapper.js and the DHTMLX Gantt component work together", S["subtitle"]))
    st.append(Spacer(1, 12 * mm))
    rows = [
        ["Object", "Page 50620 'Gantt Demo DHX 2' + control add-in 'DHX Gantt Control 2'"],
        ["Scope", "AL page and triggers, add-in contract, wrapper.js (every function and variable), data build in AL, task panel, resource panel, menus, refresh and navigation, settings, actions"],
        ["Source folder", "src/dhx/ganttdemo2/"],
        ["Generated", datetime.date.today().strftime("%d %B %Y")],
        ["Generator", "docs/generate_gantt_50620_doc.py (content in docs/gantt_doc/)"],
    ]
    t = Table([[Paragraph("<b>%s</b>" % a, S["cell"]), Paragraph(lib.rich(b), S["cell"])] for a, b in rows],
              colWidths=[CONTENT_W * 0.2, CONTENT_W * 0.8])
    t.setStyle(TableStyle([("GRID", (0, 0), (-1, -1), 0.3, LINE), ("BACKGROUND", (0, 0), (0, -1), LIGHT),
                           ("VALIGN", (0, 0), (-1, -1), "TOP"), ("TOPPADDING", (0, 0), (-1, -1), 4),
                           ("BOTTOMPADDING", (0, 0), (-1, -1), 4)]))
    st.append(t)
    st.append(PageBreak())


def main():
    st = []
    cover(st)
    st.append(Paragraph("Contents", S["h1"]))
    toc = TableOfContents()
    toc.levelStyles = [
        ParagraphStyle("t0", fontName="Helvetica-Bold", fontSize=9.6, leading=14, leftIndent=0, spaceBefore=3),
        ParagraphStyle("t1", fontName="Helvetica", fontSize=8.6, leading=11.5, leftIndent=12),
        ParagraphStyle("t2", fontName="Helvetica", fontSize=8.0, leading=10.5, leftIndent=24),
    ]
    st.append(toc)
    part1.build(st)
    part2.build(st)
    part3.build(st)
    doc = Doc(OUT)
    lib.Outline.entries = []
    doc.multiBuild(st)
    print("written:", OUT)


if __name__ == "__main__":
    main()
