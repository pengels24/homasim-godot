"""
Konvertiert Markdown-Handbücher zu PDF via ReportLab.
Encoding: utf-8
"""
import re
from pathlib import Path
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import cm
from reportlab.lib import colors
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, HRFlowable, Preformatted
)
from reportlab.lib.enums import TA_LEFT

GOLD = colors.HexColor("#eab308")
DARK = colors.HexColor("#1a1a2e")
LIGHT_GRAY = colors.HexColor("#f3f4f6")
MID_GRAY = colors.HexColor("#e5e7eb")
BG_YELLOW = colors.HexColor("#fefce8")

styles = getSampleStyleSheet()

def s(name, **kw):
    base = styles[name]
    return ParagraphStyle(name + str(id(kw)), parent=base, **kw)

H1 = s('Heading1', fontSize=20, textColor=DARK, spaceAfter=6, borderPadding=(0,0,4,0))
H2 = s('Heading2', fontSize=14, textColor=DARK, spaceAfter=4, spaceBefore=16)
H3 = s('Heading3', fontSize=11, textColor=colors.HexColor("#374151"), spaceAfter=3, spaceBefore=10)
BODY = s('Normal', fontSize=9.5, leading=14, spaceAfter=4)
NOTE = s('Normal', fontSize=9, leading=13, textColor=colors.HexColor("#374151"),
         backColor=BG_YELLOW, borderPadding=6, spaceAfter=6)
CODE = s('Code', fontSize=8.5, leading=12, fontName='Courier')
BULLET = s('Normal', fontSize=9.5, leading=14, leftIndent=12, spaceAfter=2)

def clean(text):
    """Minimal inline markdown → ReportLab XML + Emoji Fallbacks."""
    # Emojis durch Text ersetzen, da Standard-PDF-Fonts sie nicht unterstützen
    replacements = {
        '🛏': '[Bett]', '🍴': '[Gastro]', '🏠': '[Haus]', '💆': '[Spa]', '💼': '[Büro]',
        '🔨': '[Hammer]', '➕': '[+]', '🟩': '[Grün]', '🟥': '[Rot]', '⚠️': '[!]',
        '💰': '[$]', '📅': '[Tag]', '⏸': '[||]', '▶': '[>]', '▶▶': '[>>]',
        '☆☆☆☆☆': '[Sterne]', '🏨': '', '🎯': '', '🚪': '', '🖥️': '', '💡': 'Tipp:',
        '🚀': '', '❓': '', '🗺️': '', '📋': '', '👤': '[Gast]', '🔧': '[Reparatur]', 
        '🧹': '[Putzen]', '✂': '[Spa]', '☆': '*'
    }
    for k, v in replacements.items():
        text = text.replace(k, v)
        
    text = text.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;')
    text = re.sub(r'\*\*(.+?)\*\*', r'<b>\1</b>', text)
    text = re.sub(r'\*(.+?)\*', r'<i>\1</i>', text)
    text = re.sub(r'`(.+?)`', r'<font name="Courier">\1</font>', text)
    return text

def parse_md(md_text):
    """Very simple MD parser → list of ReportLab flowables."""
    flowables = []
    lines = md_text.splitlines()
    i = 0
    in_table = False
    table_rows = []
    in_code = False
    code_lines = []

    while i < len(lines):
        line = lines[i]

        # Code block
        if line.startswith('```'):
            if in_code:
                pre = Preformatted('\n'.join(code_lines), CODE)
                t = Table([[pre]], colWidths=[A4[0]-5*cm])
                t.setStyle(TableStyle([
                    ('BACKGROUND', (0,0), (-1,-1), colors.HexColor("#1a1a2e")),
                    ('TEXTCOLOR', (0,0), (-1,-1), colors.HexColor("#e5e7eb")),
                    ('LEFTPADDING', (0,0), (-1,-1), 8),
                    ('RIGHTPADDING', (0,0), (-1,-1), 8),
                    ('TOPPADDING', (0,0), (-1,-1), 6),
                    ('BOTTOMPADDING', (0,0), (-1,-1), 6),
                ]))
                flowables.append(t)
                code_lines = []
                in_code = False
            else:
                in_code = True
            i += 1
            continue
        if in_code:
            code_lines.append(line)
            i += 1
            continue

        # Table
        if line.startswith('|'):
            cells = [c.strip() for c in line.strip('|').split('|')]
            if all(re.match(r'^[-: ]+$', c) for c in cells if c):
                i += 1
                continue
            table_rows.append(cells)
            i += 1
            if i >= len(lines) or not lines[i].startswith('|'):
                if table_rows:
                    col_count = max(len(r) for r in table_rows)
                    data = []
                    for ri, row in enumerate(table_rows):
                        while len(row) < col_count:
                            row.append('')
                        data.append([Paragraph(clean(c), s('Normal', fontSize=8.5,
                                     textColor=colors.white if ri==0 else DARK,
                                     leading=12)) for c in row])
                    ts = TableStyle([
                        ('BACKGROUND', (0,0), (-1,0), DARK),
                        ('TEXTCOLOR', (0,0), (-1,0), GOLD),
                        ('FONTNAME', (0,0), (-1,0), 'Helvetica-Bold'),
                        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, LIGHT_GRAY]),
                        ('GRID', (0,0), (-1,-1), 0.5, MID_GRAY),
                        ('LEFTPADDING', (0,0), (-1,-1), 6),
                        ('RIGHTPADDING', (0,0), (-1,-1), 6),
                        ('TOPPADDING', (0,0), (-1,-1), 4),
                        ('BOTTOMPADDING', (0,0), (-1,-1), 4),
                    ])
                    col_w = (A4[0] - 5*cm) / col_count
                    t = Table(data, colWidths=[col_w]*col_count, repeatRows=1)
                    t.setStyle(ts)
                    flowables.append(t)
                    flowables.append(Spacer(1, 6))
                    table_rows = []
            continue

        # HR
        if re.match(r'^-{3,}$', line.strip()):
            flowables.append(HRFlowable(width='100%', thickness=1, color=MID_GRAY,
                                         spaceAfter=6, spaceBefore=6))
            i += 1
            continue

        # Headings
        if line.startswith('### '):
            flowables.append(Paragraph(clean(line[4:]), H3))
            i += 1
            continue
        if line.startswith('## '):
            flowables.append(HRFlowable(width='100%', thickness=1.5, color=GOLD,
                                         spaceAfter=2, spaceBefore=8))
            flowables.append(Paragraph(clean(line[3:]), H2))
            i += 1
            continue
        if line.startswith('# '):
            flowables.append(Paragraph(clean(line[2:]), H1))
            flowables.append(HRFlowable(width='100%', thickness=2, color=GOLD, spaceAfter=8))
            i += 1
            continue

        # Blockquote
        if line.startswith('> '):
            flowables.append(Paragraph(clean(line[2:]), NOTE))
            i += 1
            continue

        # Bullet
        if re.match(r'^[-*] ', line):
            flowables.append(Paragraph('• ' + clean(line[2:]), BULLET))
            i += 1
            continue
        if re.match(r'^\s+[-*] ', line):
            flowables.append(Paragraph('  ◦ ' + clean(line.lstrip('- *')), 
                                        s('Normal', fontSize=9, leading=13, leftIndent=24, spaceAfter=2)))
            i += 1
            continue

        # Numbered list
        m = re.match(r'^(\d+)\. (.*)', line)
        if m:
            flowables.append(Paragraph(f'{m.group(1)}. {clean(m.group(2))}', BULLET))
            i += 1
            continue

        # Empty line
        if not line.strip():
            flowables.append(Spacer(1, 4))
            i += 1
            continue

        # Normal paragraph
        flowables.append(Paragraph(clean(line), BODY))
        i += 1

    return flowables

files = [
    ("wiki/erste_schritte_handbuch.md", "wiki/HO-MA-SIM_Erste_Schritte_DE.pdf"),
    ("wiki/getting_started.md",          "wiki/HO-MA-SIM_Getting_Started_EN.pdf"),
]

for md_path, pdf_path in files:
    text = Path(md_path).read_text(encoding='utf-8')
    doc = SimpleDocTemplate(
        pdf_path,
        pagesize=A4,
        leftMargin=2.5*cm, rightMargin=2.5*cm,
        topMargin=2*cm, bottomMargin=2*cm,
        title=Path(md_path).stem,
    )
    doc.build(parse_md(text))
    print(f"OK: {pdf_path}")

print("Fertig!")
