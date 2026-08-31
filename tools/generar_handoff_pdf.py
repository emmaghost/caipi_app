# -*- coding: utf-8 -*-
"""Exporta DOCUMENTACION_HANDOFF_SISTEMA.md a PDF."""
from pathlib import Path
import re

from fpdf import FPDF

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "DOCUMENTACION_HANDOFF_SISTEMA.md"
OUT = ROOT / "DOCUMENTACION_HANDOFF_SISTEMA.pdf"
FONT = Path(r"C:\Windows\Fonts\arial.ttf")
FONT_B = Path(r"C:\Windows\Fonts\arialbd.ttf")


class PDF(FPDF):
    def header(self):
        if self.page_no() == 1:
            return
        self.set_font("ArialCustom", "B", 8)
        self.set_text_color(30, 90, 120)
        self.cell(0, 6, "CAIPI — Documentación handoff del sistema", align="L")
        self.set_font("ArialCustom", "", 8)
        self.set_text_color(120, 120, 120)
        self.cell(0, 6, f"Pág. {self.page_no()}", align="R", new_x="LMARGIN", new_y="NEXT")
        self.set_draw_color(30, 90, 120)
        self.line(12, self.get_y(), 198, self.get_y())
        self.ln(3)

    def footer(self):
        self.set_y(-12)
        self.set_font("ArialCustom", "", 7)
        self.set_text_color(140, 140, 140)
        self.cell(0, 8, "Snapshot técnico · Flutter + Supabase · julio 2026", align="C")


def clean(t: str) -> str:
    t = t.replace("**", "").replace("`", "")
    t = t.replace("—", "-").replace("–", "-").replace("→", "->")
    t = t.replace("✅", "[OK]").replace("⚠️", "[!]").replace("❌", "[X]").replace("🔜", "[>>]")
    return t


def main() -> None:
    text = SRC.read_text(encoding="utf-8")
    pdf = PDF("P", "mm", "A4")
    pdf.set_auto_page_break(auto=True, margin=16)
    pdf.add_font("ArialCustom", "", str(FONT))
    pdf.add_font("ArialCustom", "B", str(FONT_B))
    pdf.set_margins(12, 12, 12)

    # Portada
    pdf.add_page()
    pdf.set_xy(12, 50)
    pdf.set_font("ArialCustom", "B", 22)
    pdf.set_text_color(20, 70, 100)
    pdf.cell(186, 10, "Documentacion Handoff", align="C", new_x="LMARGIN", new_y="NEXT")
    pdf.set_font("ArialCustom", "B", 16)
    pdf.cell(186, 8, "Sistema App CAIPI", align="C", new_x="LMARGIN", new_y="NEXT")
    pdf.ln(6)
    pdf.set_draw_color(30, 90, 120)
    y = pdf.get_y()
    pdf.line(55, y, 155, y)
    pdf.ln(8)
    pdf.set_x(12)
    pdf.set_font("ArialCustom", "", 11)
    pdf.set_text_color(60, 60, 60)
    pdf.multi_cell(
        186,
        6,
        "Arquitectura, modulos, schema, estados,\nbacklog y guia para clonar o continuar el sistema.\n\n"
        "Fuente: DOCUMENTACION_HANDOFF_SISTEMA.md",
        align="C",
    )
    pdf.ln(20)
    pdf.set_x(12)
    pdf.set_fill_color(255, 243, 224)
    pdf.set_font("ArialCustom", "B", 9)
    pdf.set_text_color(120, 70, 20)
    pdf.multi_cell(
        186,
        5,
        "AVISO: Ignorar docs viejos de Firebase/Firestore en el repo.\n"
        "Backend real = Supabase. Ver tambien seccion Roles/Permisos en el informe.",
        fill=True,
    )

    pdf.add_page()
    in_code = False
    left = 12

    def write(style: str, size: float, color: tuple, content: str, indent: float = 0, fill: bool = False) -> None:
        pdf.set_x(left + indent)
        pdf.set_font("ArialCustom", style, size)
        pdf.set_text_color(*color)
        usable = 210 - 12 - left - indent
        pdf.multi_cell(usable, max(3.5, size * 0.45), content, fill=fill)

    for raw in text.splitlines():
        line = raw.rstrip()

        if line.startswith("```"):
            in_code = not in_code
            if in_code:
                pdf.set_fill_color(245, 245, 245)
            pdf.ln(1)
            continue

        if in_code:
            write("", 7.5, (50, 50, 50), clean(line)[:150], fill=True)
            continue

        if not line.strip():
            pdf.ln(1.5)
            continue

        if line.startswith("|") and re.search(r"^\|?\s*-+", line):
            continue
        if line.startswith("|"):
            cells = [c.strip() for c in line.strip("|").split("|")]
            write("", 8, (40, 40, 40), " | ".join(clean(c) for c in cells))
            continue

        if line.startswith("# "):
            pdf.ln(3)
            write("B", 14, (20, 70, 100), clean(line[2:]))
            continue
        if line.startswith("## "):
            pdf.ln(3)
            write("B", 12, (30, 90, 120), clean(line[3:]))
            continue
        if line.startswith("### "):
            pdf.ln(2)
            write("B", 10.5, (40, 40, 40), clean(line[4:]))
            continue

        if line.startswith("> "):
            pdf.set_fill_color(235, 245, 250)
            write("", 9, (30, 70, 90), clean(line[2:]), fill=True)
            continue

        if line.startswith("- ") or line.startswith("* "):
            write("", 9, (40, 40, 40), f"- {clean(line[2:])}", indent=4)
            continue

        if re.match(r"^\d+\.\s", line):
            write("", 9, (40, 40, 40), clean(line), indent=4)
            continue

        if line.startswith("---"):
            pdf.ln(1)
            continue

        write("", 9, (40, 40, 40), clean(line))

    # Anexo: auditoria roles (resumen corto)
    pdf.add_page()
    pdf.set_x(12)
    pdf.set_font("ArialCustom", "B", 14)
    pdf.set_text_color(180, 60, 40)
    pdf.multi_cell(186, 7, "ANEXO - Auditoria Roles y Permisos (julio 2026)")
    pdf.ln(2)
    hallazgos = [
        ("B", "VEREDICTO: el sistema de permisos NO esta bien afinado. Funciona a medias."),
        ("", ""),
        ("B", "Que SI hay:"),
        ("", "- Tablas roles / permisos / roles_permisos / usuarios_permisos"),
        ("", "- RPC usuario_tiene_permiso + PermisosService en Flutter"),
        ("", "- Menu (AppDrawer) oculta secciones segun ver_*"),
        ("", "- Pantalla para otorgar permisos extra a profesoras"),
        ("", "- Directora suele recibir TRUE en la funcion SQL (bypass)"),
        ("", ""),
        ("B", "Problemas graves:"),
        ("", "1) Router: profesor logueado puede ser mandado a /padre."),
        ("", "2) esProfesor solo detecta rol=='profesor', ignora 'profesor_admin'."),
        ("", "3) Permisos SOLO esconden el menu: rutas /directora/* sin guard."),
        ("", "4) SQL conflictivos (columna codigo vs clave en permisos)."),
        ("", "5) Si falla el RPC, drawer da casi todos los ver_* = true."),
        ("", "6) Crear/editar/borrar casi no revisan permiso en pantallas."),
        ("", "7) Seguridad real depende de RLS en Supabase, no del menu."),
        ("", ""),
        ("B", "Recomendacion: afinar en sesion dedicada (router + guards + SQL unico)."),
    ]
    for style, h in hallazgos:
        pdf.set_x(12)
        pdf.set_font("ArialCustom", style, 9)
        pdf.set_text_color(40, 40, 40)
        if h == "":
            pdf.ln(2)
        else:
            pdf.multi_cell(186, 4.5, h)

    pdf.output(str(OUT))
    print(f"OK: {OUT} ({OUT.stat().st_size} bytes)")


if __name__ == "__main__":
    main()
