# -*- coding: utf-8 -*-
"""Genera PROPUESTA_COMERCIAL_CAIPI.pdf desde el contenido comercial."""
from pathlib import Path

from fpdf import FPDF

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "PROPUESTA_COMERCIAL_CAIPI.pdf"
FONT = Path(r"C:\Windows\Fonts\arial.ttf")
FONT_B = Path(r"C:\Windows\Fonts\arialbd.ttf")


class PDF(FPDF):
    def header(self):
        if self.page_no() == 1:
            return
        self.set_font("ArialCustom", "B", 9)
        self.set_text_color(30, 90, 120)
        self.cell(0, 8, "App CAIPI — Propuesta comercial", align="L")
        self.set_text_color(120, 120, 120)
        self.set_font("ArialCustom", "", 8)
        self.cell(0, 8, f"Página {self.page_no()}", align="R", new_x="LMARGIN", new_y="NEXT")
        self.set_draw_color(30, 90, 120)
        self.line(10, self.get_y(), 200, self.get_y())
        self.ln(4)

    def footer(self):
        self.set_y(-15)
        self.set_font("ArialCustom", "", 8)
        self.set_text_color(140, 140, 140)
        self.cell(0, 10, "Precios orientativos en MXN · Sujetos a acuerdo escrito", align="C")


def main() -> None:
    pdf = PDF("P", "mm", "A4")
    pdf.set_auto_page_break(auto=True, margin=18)
    pdf.add_font("ArialCustom", "", str(FONT))
    pdf.add_font("ArialCustom", "B", str(FONT_B))
    pdf.set_margins(14, 14, 14)

    def h1(t: str) -> None:
        pdf.ln(2)
        pdf.set_font("ArialCustom", "B", 16)
        pdf.set_text_color(20, 70, 100)
        pdf.multi_cell(0, 8, t)
        pdf.ln(1)

    def h2(t: str) -> None:
        pdf.ln(3)
        pdf.set_font("ArialCustom", "B", 12)
        pdf.set_text_color(30, 90, 120)
        pdf.multi_cell(0, 7, t)
        pdf.ln(1)

    def h3(t: str) -> None:
        pdf.ln(2)
        pdf.set_font("ArialCustom", "B", 10.5)
        pdf.set_text_color(40, 40, 40)
        pdf.multi_cell(0, 6, t)
        pdf.ln(0.5)

    def body(t: str) -> None:
        pdf.set_font("ArialCustom", "", 10)
        pdf.set_text_color(40, 40, 40)
        pdf.multi_cell(0, 5.5, t)
        pdf.ln(1)

    def bold_body(t: str) -> None:
        pdf.set_font("ArialCustom", "B", 10)
        pdf.set_text_color(40, 40, 40)
        pdf.multi_cell(0, 5.5, t)
        pdf.ln(1)

    def bullet(t: str) -> None:
        pdf.set_font("ArialCustom", "", 10)
        pdf.set_text_color(40, 40, 40)
        pdf.set_x(18)
        pdf.multi_cell(0, 5.5, f"•  {t}")

    def quote(t: str) -> None:
        pdf.set_fill_color(235, 245, 250)
        pdf.set_font("ArialCustom", "B", 10)
        pdf.set_text_color(20, 70, 100)
        pdf.multi_cell(0, 6, t, fill=True)
        pdf.ln(2)

    def simple_table(headers: list[str], rows: list[list[str]], widths: list[float]) -> None:
        pdf.set_font("ArialCustom", "B", 9)
        pdf.set_fill_color(30, 90, 120)
        pdf.set_text_color(255, 255, 255)
        for i, h in enumerate(headers):
            pdf.cell(widths[i], 7, h, border=1, fill=True, align="C")
        pdf.ln()
        pdf.set_text_color(40, 40, 40)
        alt = False
        for row in rows:
            if pdf.get_y() > 265:
                pdf.add_page()
                pdf.set_font("ArialCustom", "B", 9)
                pdf.set_fill_color(30, 90, 120)
                pdf.set_text_color(255, 255, 255)
                for i, h in enumerate(headers):
                    pdf.cell(widths[i], 7, h, border=1, fill=True, align="C")
                pdf.ln()
                pdf.set_text_color(40, 40, 40)
            pdf.set_font("ArialCustom", "", 8.5)
            pdf.set_fill_color(245, 248, 250) if alt else pdf.set_fill_color(255, 255, 255)
            line_h = 5
            max_lines = 1
            for i, c in enumerate(row):
                cw = max(widths[i] - 2, 8)
                sw = pdf.get_string_width(c) if c else 0
                nl = max(1, int(sw / cw) + 1)
                max_lines = max(max_lines, nl)
            h = max(7, max_lines * line_h + 2)
            x = pdf.get_x()
            y = pdf.get_y()
            for i, c in enumerate(row):
                pdf.set_xy(x, y)
                pdf.multi_cell(widths[i], line_h, c, border=1, fill=True)
                x += widths[i]
            pdf.set_xy(14, y + h)
            alt = not alt
        pdf.ln(2)

    # Portada
    pdf.add_page()
    pdf.ln(35)
    pdf.set_font("ArialCustom", "B", 28)
    pdf.set_text_color(20, 70, 100)
    pdf.multi_cell(0, 12, "App CAIPI", align="C")
    pdf.ln(4)
    pdf.set_font("ArialCustom", "B", 14)
    pdf.set_text_color(60, 100, 130)
    pdf.multi_cell(0, 8, "Propuesta comercial", align="C")
    pdf.ln(6)
    pdf.set_draw_color(30, 90, 120)
    pdf.set_line_width(0.6)
    pdf.line(60, pdf.get_y(), 150, pdf.get_y())
    pdf.ln(8)
    pdf.set_font("ArialCustom", "", 12)
    pdf.set_text_color(60, 60, 60)
    pdf.multi_cell(
        0,
        7,
        "Sistema de gestión escolar para\ndirección, personal y familias",
        align="C",
    )
    pdf.ln(20)
    pdf.set_font("ArialCustom", "", 10)
    pdf.set_text_color(100, 100, 100)
    pdf.multi_cell(
        0,
        6,
        "Documento para presentación a escuelas / CAIPI\nPrecios en pesos mexicanos (MXN)",
        align="C",
    )
    pdf.ln(30)
    pdf.set_fill_color(235, 245, 250)
    pdf.set_font("ArialCustom", "", 9)
    pdf.set_text_color(40, 70, 90)
    pdf.multi_cell(
        0,
        5.5,
        "Contenido\n"
        "1. Qué es y qué hace la app (producto)\n"
        "2. Precios e inversión (paquetes, renta y costos de plataforma)",
        align="L",
        fill=True,
    )

    # PARTE 1
    pdf.add_page()
    h1("PARTE 1 — Qué es y qué hace la app")

    h2("El problema que resuelve")
    body(
        "En muchas escuelas el día a día se reparte entre WhatsApp, Excel, "
        "libretas, PDFs sueltos y “avísale a la maestra”. Eso genera:"
    )
    for t in [
        "Cobros sin historial claro ni recibos formales",
        "Padres que no saben qué pasó en el día",
        "Dudas de quién puede recoger al niño",
        "Información que se pierde cuando cambia el personal",
        "Dirección sin reportes rápidos para tomar decisiones",
    ]:
        bullet(t)
    pdf.ln(1)
    bold_body(
        "CAIPI concentra todo eso en una sola aplicación móvil, con usuarios "
        "por rol y datos en la nube (seguros y accesibles desde el celular o tablet)."
    )

    h2("Qué es CAIPI?")
    body(
        "Es una app escolar multi-rol: la misma aplicación la usan la directora, "
        "las profesoras y los padres, pero cada quien ve solo lo que le corresponde."
    )
    bullet("Directora: administra la escuela completa")
    bullet("Profesora: opera el día a día del grupo")
    bullet("Padre / tutor: sigue a su hijo, pagos, avisos y comunicación")
    pdf.ln(1)
    body(
        "Tecnología: app móvil moderna (Flutter) + base de datos en la nube (Supabase). "
        "Hoy está lista para Android; iOS se puede publicar después con cuenta de Apple."
    )

    h2("Beneficios en lenguaje simple")
    simple_table(
        ["Antes", "Con CAIPI"],
        [
            ["Mensajes sueltos en WhatsApp", "Chat y anuncios dentro de la app"],
            ["Excel de pagos que se desactualiza", "Pagos, abonos y recibos PDF"],
            ["¿Quién viene por el niño?", "Autorizados + solicitudes de recogida"],
            ["Bitácoras en papel o fotos", "Bitácora diaria digital"],
            ["Reportes a mano", "Reportes PDF listos para imprimir o compartir"],
            ["Entrevistas en carpetas", "Entrevista digital + PDF"],
        ],
        [91, 91],
    )

    h2("Módulos explicados (qué hace cada uno)")
    mods = [
        (
            "1. Acceso seguro por roles",
            "Cada persona entra con su usuario. La directora ve todo; la profesora "
            "su operación; el padre solo lo de su hijo. Incluye cambio de contraseña "
            "y control de permisos.",
        ),
        (
            "2. Alumnos y estructura de la escuela",
            "Alta, edición y seguimiento de alumnos. Grados / grupos. Relación clara "
            "entre alumno y padre/tutor. Base ordenada para el resto de módulos.",
        ),
        (
            "3. Personas autorizadas y recogida",
            "Registro de quién puede recoger al niño. Solicitudes de recogida. "
            "Apoyo con QR temporal para control en puerta. Más seguridad en la salida.",
        ),
        (
            "4. Entrevista a padres",
            "Formulario completo de entrevista ligado al alumno. Se puede guardar "
            "avance y completar después. Al terminar se genera PDF para archivo.",
        ),
        (
            "5. Pagos y cobranza",
            "Generación de pagos según el plan (incluye becas / planes). Acreditación "
            "y abonos con folio. Recibo en PDF. Exportación a Excel. Historial claro.",
        ),
        (
            "6. Comunicación escuela–familia",
            "Chat entre padres y escuela. Anuncios y eventos. Registro de incidentes. "
            "Notificaciones sin depender solo de grupos de WhatsApp.",
        ),
        (
            "7. Bitácora diaria",
            "Registro del día del alumno / grupo (actividad, observaciones, seguimiento). "
            "Evidencia para dirección y base para reportes.",
        ),
        (
            "8. Bitácora de gastos",
            "Control de gastos de la escuela en un solo lugar. Apoya transparencia "
            "y reportes administrativos.",
        ),
        (
            "9. Control de entrada y salida",
            "Registro de ingresos y salidas. Complementa el control de recogida y "
            "da trazabilidad del movimiento de alumnos.",
        ),
        (
            "10. Clases extracurriculares",
            "Gestión de actividades fuera del horario regular, sin hojas sueltas.",
        ),
        (
            "11. Personal (profesoras y padres)",
            "Alta y administración de cuentas de profesoras y padres vinculados "
            "a alumnos desde la app.",
        ),
        (
            "12. Reportes PDF para dirección",
            "Bitácora diaria, gastos y control de entrada/salida por fechas, "
            "con identidad visual de la escuela.",
        ),
    ]
    for title, desc in mods:
        h3(title)
        body(desc)

    h2("¿Para qué tipo de escuela sirve?")
    body(
        "Pensada para escuelas pequeñas y medianas, CAIPI / preescolar / primaria "
        "privada, donde la directora necesita orden operativo sin un sistema "
        "empresarial enorme."
    )
    body(
        "Ideal si hoy ya sufren con: cobranza desordenada, comunicación fragmentada, "
        "falta de evidencia escrita o control de acceso a la salida."
    )

    h2("Qué incluye la entrega del sistema")
    for t in [
        "Aplicación instalable en Android",
        "Configuración del backend en la nube",
        "Roles y módulos operativos descritos arriba",
        "Capacitación básica de uso (directora / personal clave)",
        "Acompañamiento inicial para poner datos en marcha",
    ]:
        bullet(t)
    pdf.ln(1)
    body(
        "No incluye por defecto (se cotizan aparte): cuenta Apple / publicación iOS, "
        "cuota anual de desarrollador Apple, plan de pago de Supabase en producción, "
        "personalizaciones fuera del alcance actual."
    )

    h2("Resumen en una frase")
    quote(
        "CAIPI es el “centro de mando” de la escuela en el celular: alumnos, pagos, "
        "comunicación, bitácoras, acceso y reportes, con un perfil distinto para "
        "directora, profesora y padre."
    )

    # PARTE 2
    pdf.add_page()
    h1("PARTE 2 — Precios e inversión")
    body(
        "Esta sección va aparte a propósito: primero se entiende el producto; luego "
        "la inversión. Precios en pesos mexicanos (MXN), orientativos de venta."
    )

    h2("Por qué el precio refleja un sistema completo")
    body(
        "No es una app de catálogo: es un sistema operativo escolar (cobranza, "
        "comunicación, documentación y control de acceso). En el mercado mexicano, "
        "desarrollos similares se cotizan típicamente entre $180,000 y $450,000 MXN."
    )
    body("Una escuela pequeña suele gastar sin notarlo:")
    simple_table(
        ["Alternativa informal", "Costo aprox. al año"],
        [
            ["Tiempo de dirección en Excel / chasing pagos", "$30,000 – $80,000 en horas"],
            ["Errores de cobranza / pagos no rastreados", "Variable, pero caro"],
            ["Papelería / retrabajo de reportes", "$5,000 – $20,000"],
            ["SaaS escolares comerciales", "$50,000 – $80,000 / año"],
        ],
        [100, 82],
    )
    body(
        "Con modelo de licencia, CAIPI se paga una vez y la escuela queda con su "
        "sistema. Abajo hay paquetes y formas de pago para facilitar la decisión."
    )

    h2("Opción A — Compra del sistema (recomendada)")
    body("Inversión única por escuela. Incluye app Android + módulos + capacitación básica.")
    simple_table(
        ["Paquete", "Qué incluye", "Precio"],
        [
            ["Esencial", "App completa, configuración, capacitación 1 sesión", "$180,000"],
            [
                "Estándar *",
                "Todo lo Esencial + arranque 2-3 sesiones + ajustes menores",
                "$230,000",
            ],
            [
                "Completo",
                "Todo lo Estándar + 3 meses soporte + prioridad mejoras chicas",
                "$280,000",
            ],
        ],
        [32, 110, 40],
    )
    bold_body("* Recomendado para la mayoría: $230,000 MXN")

    h3("Formas de pago (ejemplo paquete Estándar)")
    simple_table(
        ["Esquema", "Pagos"],
        [
            ["50 / 50", "$115,000 al firmar · $115,000 al entregar / capacitar"],
            ["40 / 30 / 30", "$92,000 · $69,000 · $69,000 (inicio / avance / cierre)"],
            ["3 mensualidades", "~$76,700 x 3 (sujeto a acuerdo)"],
        ],
        [45, 137],
    )

    h2("Opción B — Renta mensual")
    body("Ideal si la escuela prefiere no invertir fuerte al inicio.")
    simple_table(
        ["Concepto", "Precio"],
        [
            ["Implantación / setup (una vez)", "$35,000 – $50,000"],
            ["Mensualidad", "$4,500 – $5,500 / mes"],
        ],
        [100, 82],
    )
    body(
        "Ejemplo a 12 meses: setup $40,000 + $5,000 x 12 = $100,000 el primer año. "
        "A 24–36 meses el total se acerca o supera la compra."
    )

    h2("Opción C — Por alumno")
    simple_table(
        ["Concepto", "Precio orientativo"],
        [
            ["Setup", "$25,000 – $40,000"],
            ["Por alumno / mes", "$45 – $70"],
        ],
        [100, 82],
    )
    body("Ejemplo: 80 alumnos x $55 = $4,400 / mes + setup. Útil si la matrícula crece.")

    h2("Comparativo rápido")
    simple_table(
        ["Si la escuela quiere…", "Mejor opción", "Inversión típica"],
        [
            ["Dueño del sistema", "Compra Estándar", "$230,000 (se puede diferir)"],
            ["Empezar con poco efectivo", "Renta", "~$40k setup + ~$5k/mes"],
            ["Cobrar según tamaño", "Por alumno", "setup + $45–70/alumno/mes"],
        ],
        [70, 52, 60],
    )

    h2("Costos de plataforma (NO son el precio de la app)")
    body(
        "Los paga la escuela a Apple / Google / Supabase. No están incluidos en los "
        "$180k–$280k, pero hay que presupuestarlos."
    )

    h3("Supabase (nube)")
    simple_table(
        ["Plan", "Aprox. en MXN"],
        [
            ["Pruebas (Free)", "$0 (limitado; no ideal en producción)"],
            ["Producción recomendada (Pro)", "~$450 – $500 / mes (~$6,000 / año)"],
        ],
        [90, 92],
    )

    h3("Google Play (Android)")
    simple_table(
        ["Concepto", "Aprox."],
        [["Cuenta de desarrollador", "~$450 – $500 una vez (USD $25)"]],
        [90, 92],
    )

    h3("Apple / iOS / App Store (solo si quieren iPhone)")
    simple_table(
        ["Concepto", "Aprox. en MXN"],
        [
            ["Apple Developer (anual)", "~$1,800 – $2,100 / año (USD $99)"],
            ["Publicar en App Store (trabajo)", "$25,000 – $50,000 una vez"],
            ["Comisión Apple", "Solo si venden algo dentro de la app"],
        ],
        [90, 92],
    )
    body(
        "Se puede vender y usar la app solo en Android al inicio. iOS se agrega "
        "después cuando el presupuesto lo permita."
    )

    h2("Ejemplo de presupuesto (primer año)")
    h3("Solo Android (lo más común al empezar)")
    simple_table(
        ["Rubro", "Monto"],
        [
            ["App paquete Estándar", "$230,000"],
            ["Supabase Pro (12 meses)", "~$6,000"],
            ["Google Play", "~$500"],
            ["Total primer año", "~$236,500"],
        ],
        [100, 82],
    )
    body(
        "Años siguientes (sin comprar de nuevo la app): ~$6,000 / año de nube "
        "(+ soporte si lo contratan)."
    )

    h3("Android + iOS")
    simple_table(
        ["Rubro", "Monto"],
        [
            ["App paquete Estándar", "$230,000"],
            ["Publicación iOS", "$25,000 – $50,000"],
            ["Apple Developer", "~$2,000"],
            ["Supabase", "~$6,000"],
            ["Google Play", "~$500"],
            ["Total primer año", "~$263,500 – $288,500"],
        ],
        [100, 82],
    )

    h2("Recomendación comercial")
    bullet("Oferta principal: Paquete Estándar $230,000 con pago 40/30/30 o 50/50.")
    bullet("Si el presupuesto aprieta: renta (~$40k + $5k/mes) o Esencial $180,000.")
    bullet("iOS: dejarlo como fase 2.")
    bullet('Siempre aclarar: "Precios de app. Cuentas Apple/Google/Supabase aparte."')

    h2("Siguientes pasos")
    bullet("Demo de 20–30 minutos con datos de ejemplo")
    bullet("Definir paquete (Esencial / Estándar / Completo o Renta)")
    bullet("Acuerdo de pago y fecha de arranque")
    bullet("Capacitación y puesta en marcha")

    pdf.ln(6)
    pdf.set_font("ArialCustom", "", 8)
    pdf.set_text_color(120, 120, 120)
    pdf.multi_cell(
        0,
        5,
        "Documento comercial — App CAIPI · Presentación a cliente\n"
        "Precios orientativos sujetos a alcance final y acuerdo escrito.",
    )

    pdf.output(str(OUT))
    print(f"OK: {OUT} ({OUT.stat().st_size} bytes)")


if __name__ == "__main__":
    main()
