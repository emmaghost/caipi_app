# -*- coding: utf-8 -*-
"""Guías PDF profesionales CAIPI: papás y directora."""
from pathlib import Path

from fpdf import FPDF

ROOT = Path(__file__).resolve().parents[1]
LOGO = ROOT / "assets" / "images" / "icono_caipi.png"
FONT = Path(r"C:\Windows\Fonts\arial.ttf")
FONT_B = Path(r"C:\Windows\Fonts\arialbd.ttf")
OUT_PADRES = ROOT / "GUIA_PADRES_APP_CAIPI.pdf"
OUT_DIR = ROOT / "GUIA_DIRECTORA_APP_CAIPI.pdf"
OUT_PRES = ROOT / "PRESENTACION_APP_CAIPI.pdf"

MORADO = (109, 40, 217)
ROSA = (233, 30, 99)
AZUL = (21, 101, 140)
OSCURO = (33, 37, 41)
GRIS = (73, 80, 87)
SUAVE = (248, 246, 252)


class GuiaPDF(FPDF):
    def __init__(self, titulo_doc: str, pie: str):
        super().__init__("P", "mm", "A4")
        self.titulo_doc = titulo_doc
        self.pie = pie
        self.set_auto_page_break(auto=True, margin=20)
        self.add_font("CAIPI", "", str(FONT))
        self.add_font("CAIPI", "B", str(FONT_B))
        self.set_margins(16, 22, 16)

    def header(self):
        if self.page_no() == 1:
            return
        if LOGO.exists():
            self.image(str(LOGO), 16, 8, 10)
        self.set_xy(28, 9)
        self.set_font("CAIPI", "B", 9)
        self.set_text_color(*MORADO)
        self.cell(120, 6, self.titulo_doc, align="L")
        self.set_font("CAIPI", "", 8)
        self.set_text_color(140, 140, 140)
        self.cell(0, 6, f"Página {self.page_no()}", align="R")
        self.set_draw_color(*ROSA)
        self.set_line_width(0.4)
        self.line(16, 18, 194, 18)

    def footer(self):
        self.set_y(-14)
        self.set_draw_color(*MORADO)
        self.set_line_width(0.3)
        self.line(16, self.get_y(), 194, self.get_y())
        self.set_y(-12)
        self.set_font("CAIPI", "", 7.5)
        self.set_text_color(130, 130, 130)
        self.cell(0, 8, self.pie, align="C")

    def portada(self, kicker: str, titulo: str, sub: str):
        self.add_page()
        self.set_fill_color(*MORADO)
        self.rect(0, 0, 210, 58, "F")
        self.set_fill_color(*ROSA)
        self.rect(0, 58, 210, 6, "F")
        if LOGO.exists():
            self.image(str(LOGO), 16, 12, 28)
        self.set_xy(50, 16)
        self.set_font("CAIPI", "B", 11)
        self.set_text_color(255, 255, 255)
        self.cell(0, 6, "CENTRO DE ATENCION INFANTIL · CAIPI")
        self.set_xy(50, 24)
        self.set_font("CAIPI", "B", 22)
        self.multi_cell(140, 9, titulo)
        self.set_xy(50, 44)
        self.set_font("CAIPI", "", 11)
        self.set_text_color(255, 230, 240)
        self.cell(0, 6, kicker)
        self.ln(28)
        self.set_font("CAIPI", "", 11)
        self.set_text_color(*GRIS)
        self.multi_cell(0, 6, sub)
        self.ln(4)

    def h2(self, t: str):
        self.ln(3)
        self.set_fill_color(*SUAVE)
        self.set_font("CAIPI", "B", 12)
        self.set_text_color(*MORADO)
        self.cell(0, 8, f"  {t}", fill=True, new_x="LMARGIN", new_y="NEXT")
        self.ln(2)

    def h3(self, t: str):
        self.ln(1)
        self.set_x(self.l_margin)
        self.set_font("CAIPI", "B", 10.5)
        self.set_text_color(*AZUL)
        self.multi_cell(0, 6, t)

    def body(self, t: str):
        self.set_x(self.l_margin)
        self.set_font("CAIPI", "", 10)
        self.set_text_color(*OSCURO)
        self.multi_cell(0, 5.4, t)
        self.ln(1)

    def bullet(self, t: str):
        self.set_x(self.l_margin)
        self.set_font("CAIPI", "", 10)
        self.set_text_color(*OSCURO)
        self.set_x(20)
        self.multi_cell(0, 5.4, f"-  {t}")
        self.set_x(self.l_margin)

    def recuadro(self, titulo: str, lineas: list[str], fill=(255, 243, 224), ink=(120, 60, 20)):
        self.ln(1)
        left = 16
        usable = 178
        self.set_x(left)
        self.set_fill_color(*fill)
        self.set_font("CAIPI", "B", 10)
        self.set_text_color(*ink)
        self.multi_cell(usable, 6, f"  {titulo}", fill=True)
        self.set_font("CAIPI", "", 10)
        self.set_text_color(*OSCURO)
        for ln in lineas:
            self.set_x(left)
            self.set_fill_color(*fill)
            self.multi_cell(usable, 5.5, f"  {ln}", fill=True)
        self.ln(3)

    def paso(self, n: int, titulo: str, texto: str):
        self.set_font("CAIPI", "B", 10)
        self.set_text_color(*ROSA)
        self.cell(10, 6, f"{n}.")
        self.set_text_color(*OSCURO)
        self.cell(0, 6, titulo, new_x="LMARGIN", new_y="NEXT")
        self.set_font("CAIPI", "", 10)
        self.set_text_color(*GRIS)
        self.set_x(26)
        self.multi_cell(0, 5.3, texto)
        self.ln(1.5)


def guia_padres() -> None:
    pdf = GuiaPDF(
        "CAIPI · Guía para mamás y papás",
        "CAIPI · App familiar  ·  Documento para familias  ·  2026",
    )
    pdf.portada(
        "Guía rápida de la aplicación",
        "Bienvenida a la app CAIPI",
        "Esta guía te explica, en minutos, cómo entrar, ver a tu hijo, revisar "
        "pagos y hablar con la escuela. Guárdala en el teléfono o imprímela.",
    )

    pdf.h2("1. Cómo entrar")
    pdf.paso(1, "Abre la app CAIPI", "Busca el ícono con el logo de la escuela.")
    pdf.paso(2, "Escribe tu correo", "El mismo que diste el día del registro (Gmail, Hotmail, etc.).")
    pdf.paso(
        3,
        "Contraseña inicial",
        "La primera vez usa: Caipi2026   (respeta mayúsculas y el número).",
    )
    pdf.paso(4, "Confirma tu correo si te llegó uno", "Revisa bandeja de entrada y spam. Toca el botón de confirmar.")
    pdf.recuadro(
        "Cambia tu contraseña en el primer acceso",
        [
            "Menú (tres rayas)  →  Cambiar contraseña.",
            "Escríbela dos veces (mínimo 6 caracteres) y guarda.",
            "Si la olvidas: en la pantalla de inicio usa «¿Olvidaste tu contraseña?».",
        ],
    )

    pdf.h2("2. Qué verás al entrar")
    pdf.bullet("Mis hijos: toca la tarjeta de tu niño o niña para ver su ficha.")
    pdf.bullet("Pagos: colegiaturas o cargos. Ahí se acreditan los abonos que reciba la escuela.")
    pdf.bullet("Chat con la escuela: mensajes con dirección / maestras.")
    pdf.bullet("Código QR: para recoger a tu hijo de forma segura cuando la escuela lo pida.")
    pdf.body(
        "Si mamá y papá tienen cada quien su correo, los dos pueden ver al mismo hijo. "
        "Cada uno entra con su cuenta."
    )

    pdf.h2("3. Pagos (papás)")
    pdf.body(
        "En Pagos ves lo pendiente y lo pagado. No hace falta capturar becas ni "
        "planes: eso lo administra la directora. Si hay duda de un cargo, escribe "
        "por el chat o acude a caja."
    )

    pdf.h2("4. Recogida: aviso y QR")
    pdf.h3("Avisar que ya llegaste (tú mismo)")
    pdf.bullet("Entra a la ficha de tu hijo.")
    pdf.bullet("Toca «Estoy en la entrada» / solicitud de recogida.")
    pdf.bullet("La maestra ve el aviso en su pantalla y prepara al niño.")
    pdf.h3("Otra persona (abuela, tío, chofer)")
    pdf.paso(1, "Personas autorizadas", "En la ficha del hijo, abre Personas autorizadas y da de alta nombre y parentesco.")
    pdf.paso(2, "Genera el QR", "Toca Generar QR. Es un pase de 8 caracteres, un solo uso, 24 horas.")
    pdf.paso(3, "Compártelo", "Usa el botón compartir o muestra la pantalla en la puerta.")
    pdf.paso(4, "En la escuela", "Dirección o la maestra escriben el código en Control de entrada/salida. Si es válido, registran la salida.")
    pdf.recuadro(
        "Importante",
        [
            "El QR es de un solo uso: después de validarlo ya no sirve.",
            "Si se vence (24 h), genera otro.",
            "Mamá y papá, cada uno con su correo, pueden avisar y generar QR.",
        ],
    )

    pdf.h2("5. Chat con la escuela")
    pdf.bullet("Menú → Chat con la Escuela.")
    pdf.bullet("Hay horario escolar (por ejemplo lun–vie). Fuera de horario el mensaje no se envía.")
    pdf.bullet("Si mamá y papá tienen cuentas distintas, cada uno tiene su propio chat.")

    pdf.h2("6. Problemas frecuentes")
    pdf.h3("No me llega el correo")
    pdf.bullet("Revisa spam / promociones.")
    pdf.bullet("Puedes entrar con Caipi2026 aunque el correo tarde.")
    pdf.h3("No entra la contraseña")
    pdf.bullet("Sin espacios. Caipi2026 exactamente.")
    pdf.bullet("Usa «¿Olvidaste tu contraseña?» o pide apoyo en la escuela.")
    pdf.h3("No veo a mi hijo")
    pdf.bullet("Confirma que te registraron con tu correo. Si no, avisa en secretaría.")

    pdf.recuadro(
        "Datos de tu primer acceso",
        [
            "App: CAIPI",
            "Correo: el que registraste en la junta",
            "Contraseña inicial: Caipi2026",
            "Luego: Menú → Cambiar contraseña",
        ],
        fill=(236, 230, 255),
        ink=(80, 30, 140),
    )
    pdf.output(str(OUT_PADRES))


def guia_directora() -> None:
    pdf = GuiaPDF(
        "CAIPI · Manual operativo para dirección",
        "CAIPI · Uso interno dirección / secretaría  ·  Confidencial  ·  2026",
    )
    pdf.portada(
        "Protocolo de altas en junta · iPad compartido",
        "Manual para la directora",
        "Documento interno. Describe la cuenta de secretaría, qué puede y qué no, "
        "cómo registrar niños con uno o dos papás, y cómo la directora completa beca y pagos después.",
    )

    pdf.h2("1. Cuenta para el iPad (no usar la de Viri)")
    pdf.body(
        "Los papás no deben entrar con la cuenta de la directora. En junta se usa "
        "únicamente la cuenta de secretaría. Así nadie ve ni toca pagos ni becas."
    )
    pdf.recuadro(
        "Acceso secretaría (iPad de junta)",
        [
            "Correo:     secretaria@caipi.com",
            "Contraseña: Caipi2026",
            "Rol:        secretaria (solo altas de alumnos)",
            "Después de entrar: menú → Cambiar contraseña (recomendado).",
        ],
        fill=(236, 230, 255),
        ink=(80, 30, 140),
    )
    pdf.bullet("Cerrar sesión de la directora antes de prestar el iPad.")
    pdf.bullet("Al terminar la junta, cerrar sesión de secretaría.")

    pdf.h2("2. Qué SÍ puede la secretaria")
    pdf.bullet("Ver lista de alumnos y crear / completar ficha del niño.")
    pdf.bullet("Capturar nombre, apellidos, grado, 1 o 2 correos de papás.")
    pdf.bullet("Cambiar su propia contraseña.")
    pdf.body("Al guardar un niño, si el correo del papá no existe, la app ofrece crearlo (Caipi2026).")

    pdf.h2("3. Qué NO puede (a propósito)")
    pdf.bullet("No ve Pagos, costos, reportes, profesoras ni indicadores.")
    pdf.bullet("No ve ni cambia Beca. Ese campo solo aparece con la cuenta de directora.")
    pdf.bullet("No puede borrar alumnos.")
    pdf.bullet("Si intenta abrir Pagos, la app la regresa al inicio.")
    pdf.body(
        "En base de datos la beca queda en 0% al alta. La directora, más tarde, "
        "edita al alumno y asigna el porcentaje. Un usuario que no sea directora no puede pisar esa beca."
    )

    pdf.h2("4. Flujo recomendado en junta")
    pdf.paso(1, "iPad con secretaria@caipi.com", "Pantalla: Nuevo alumno.")
    pdf.paso(2, "Papá/mamá escribe nombre del hijo", "Grado si ya se sabe; si no, «Sin asignar».")
    pdf.paso(3, "Uno o dos correos", "Email papá/mamá 1 y 2. Deben ser distintos. Cada uno tendrá su propia cuenta.")
    pdf.paso(4, "Guardar", "Entregar la guía de papás: correo + Caipi2026 + cambiar contraseña.")
    pdf.paso(5, "Directora (después, en privado)", "Editar alumno → Beca si aplica → revisar plan de pagos / cargos.")

    pdf.h2("5. Dos papás, mismo hijo")
    pdf.body(
        "En la ficha hay dos campos de correo. Los dos tutores ven al niño, cada uno con su login. "
        "El chat es por persona (mamá y papá hablan por separado con la escuela)."
    )
    pdf.body("Primero ejecute en Supabase el SQL ADD_DOS_PADRES_POR_ALUMNO.sql y ADD_SECRETARIA_ALTAS.sql.")

    pdf.h2("6. Planes según grado (recordatorio)")
    pdf.bullet("Sin asignar / Maternal: cobro por clase. No se generan colegiaturas solas.")
    pdf.bullet("Estimulación: sesión o paquetes.")
    pdf.bullet("Kínder: plan 10 / 11 / 12 meses (sí genera colegiaturas).")

    pdf.h2("7. Cómo crea usted otra secretaria")
    pdf.body(
        "Profesoras → Nueva → tipo «Secretaria (altas en junta)». "
        "O use el usuario ya creado: secretaria@caipi.com / Caipi2026."
    )

    pdf.h2("8. Lista de verificación post-junta")
    pdf.bullet("Cerrar sesión del iPad.")
    pdf.bullet("Revisar alumnos nuevos (registro incompleto).")
    pdf.bullet("Completar becas solo usted.")
    pdf.bullet("Confirmar que los papás ya abrieron la app.")

    pdf.h2("9. Dos docentes por grupo (titular + inglés)")
    pdf.body(
        "En un mismo grupo puede haber la maestra titular y otra cuenta de maestra de inglés. "
        "Son dos usuarios distintos."
    )
    pdf.paso(1, "Profesoras → Nueva", "Tipo Profesora.")
    pdf.paso(2, "Elige Maestra de inglés", "Asigna el mismo grupo que la titular. Si da inglés a varios kínder, déjalo sin grupo.")
    pdf.paso(3, "Qué ve ella", "Solo alumnos del grupo y calificaciones de Inglés. Sin bitácora, pagos ni Portage.")
    pdf.bullet("La titular sigue viendo bitácora, chat de su grupo y asistencia.")
    pdf.bullet("Contraseña inicial: Caipi2026.")

    pdf.h2("10. Recogida en la puerta")
    pdf.h3("Aviso del papá («ya llegué»)")
    pdf.bullet("El papá lo envía desde la ficha del hijo. Sale aviso naranja: Padres en la entrada.")
    pdf.bullet("Marca Atendida cuando el niño ya salió. La titular de grupo solo ve a los de su grupo.")
    pdf.h3("QR de persona autorizada")
    pdf.paso(1, "Control Entrada/Salida", "Ícono de QR en la barra superior.")
    pdf.paso(2, "Escribe el código de 8 letras", "Si es válido, abre el registro de salida con el nombre de quien recoge.")
    pdf.paso(3, "Guarda la salida", "El código queda usado y no se puede repetir.")
    pdf.body("Si el SQL de QR no está corrido, la validación falla. Archivos: FIX_SISTEMA_QR_TEMPORAL.sql y FIX_QR_VALIDAR_PUERTA.sql.")

    pdf.h2("11. Chat")
    pdf.bullet("Menú → Chat con Padres. La titular solo ve papás de su grupo (incluye papá y mamá si hay dos cuentas).")
    pdf.bullet("Horario: Configuración → Horario del chat. Fuera de horario el papá no envía; el staff sí puede responder.")
    pdf.bullet("La maestra de inglés no tiene chat (solo calificaciones).")

    pdf.recuadro(
        "Resumen de accesos",
        [
            "Directora: cuenta habitual. Ve todo, incluida beca y pagos.",
            "Secretaría: secretaria@caipi.com  /  Caipi2026  → solo alta de niños.",
            "Papás: su correo  /  Caipi2026  → hijos, pagos propios, chat, aviso de recogida y QR.",
            "Maestra de inglés: otro usuario, mismo grupo, solo calificaciones de Inglés.",
        ],
        fill=(232, 245, 233),
        ink=(27, 94, 32),
    )
    pdf.output(str(OUT_DIR))


def presentacion() -> None:
    pdf = GuiaPDF(
        "CAIPI · Presentación del sistema",
        "App CAIPI  ·  Documento de presentación  ·  Agosto 2026",
    )
    pdf.portada(
        "Qué hace la app, quién la usa y cómo se trabaja el día a día",
        "Presentación App CAIPI",
        "Documento para dirección, junta y demostración. Resume roles, "
        "pagos, puerta (aviso + QR), chat, dos docentes por grupo y altas en iPad.",
    )

    pdf.h2("1. Qué es")
    pdf.body(
        "Aplicación escolar para un CAIPI / kínder. Un solo sistema: dirección, "
        "maestras, secretaría en junta y mamás/papás en el celular."
    )
    pdf.bullet("Android (APK). iOS queda listo en código cuando haya cuenta de Apple.")
    pdf.bullet("Datos en la nube (Supabase): alumnos, pagos, chat y asistencia en tiempo real.")

    pdf.h2("2. Quién entra y qué ve")
    pdf.h3("Directora")
    pdf.bullet("Alumnos, pagos, becas, profesoras, papás, reportes PDF, bitácora de gastos, Portage, chat, puerta.")
    pdf.h3("Profesora titular")
    pdf.bullet("Su grupo: alumnos, bitácora, chat con esos papás, asistencia, aviso de recogida.")
    pdf.h3("Maestra de inglés")
    pdf.bullet("Otro usuario. Mismo grupo (o varios). Solo calificaciones de Inglés.")
    pdf.h3("Secretaría (iPad de junta)")
    pdf.bullet("secretaria@caipi.com -- solo alta de ni\u00f1os y pap\u00e1s. Sin beca, sin pagos.")
    pdf.h3("Pap\u00e1 / mam\u00e1")
    pdf.bullet("Sus hijos, pagos propios, chat, aviso de llegada, personas autorizadas y QR.")
    pdf.body(
        "Pueden ser dos cuentas por ni\u00f1o (mam\u00e1 y pap\u00e1), cada una con su correo."
    )

    pdf.h2("3. Recorrido de una mañana")
    pdf.paso(1, "Entrada", "La maestra marca asistencia del grupo (Control entrada/salida).")
    pdf.paso(2, "Aviso de recogida", "El papá, desde la ficha del hijo, avisa que está en la puerta. La maestra ve «Padres en la entrada».")
    pdf.paso(3, "Otra persona recoge", "El papá genera un QR de 8 caracteres (24 h, un uso). En puerta se valida el código y se registra la salida.")
    pdf.paso(4, "Chat", "Papás escriben en horario escolar. La titular ve solo su grupo; dirección ve todos.")

    pdf.h2("4. Pagos (solo dirección)")
    pdf.bullet("Kínder: plan 10 / 11 / 12 meses (colegiaturas automáticas).")
    pdf.bullet("Maternal / sin grado: por clase.")
    pdf.bullet("Estimulación: sesión o paquetes.")
    pdf.bullet("Beca: solo la directora la ve y la cambia. Secretaría no.")
    pdf.bullet("Recibos PDF y exportes Excel.")

    pdf.h2("5. Altas en junta")
    pdf.bullet("iPad con secretaria@caipi.com / Caipi2026 (cambiar después).")
    pdf.bullet("Ficha del niño + 1 o 2 correos de papás. Contraseña inicial de papás: Caipi2026.")
    pdf.bullet("Después, en privado, la directora asigna beca y revisa el plan de pago.")

    pdf.h2("6. Dos maestras en el mismo grupo")
    pdf.body(
        "Titular + inglés. Se dan de alta en Profesoras. La de inglés no sustituye a la de grupo: "
        "no ve bitácora ni pagos; captura Inglés."
    )

    pdf.h2("7. Indicadores y reportes")
    pdf.bullet("Portage / indicadores de desarrollo (dirección y titular).")
    pdf.bullet("Calificaciones por materia y periodo.")
    pdf.bullet("Reportes PDF con marca CAIPI.")
    pdf.bullet("Ligas Drive por grado para papás.")

    pdf.h2("8. Accesos de demostración")
    pdf.recuadro(
        "Cuentas (cambiar contraseña tras el primer uso)",
        [
            "Secretaría junta:  secretaria@caipi.com  /  Caipi2026",
            "Papás: correo registrado  /  Caipi2026",
            "Maestras nuevas: mismo patrón Caipi2026",
            "Directora: su cuenta habitual (única que ve beca y caja).",
        ],
        fill=(236, 230, 255),
        ink=(80, 30, 140),
    )

    pdf.h2("9. Documentos que acompañan")
    pdf.bullet("GUIA_PADRES_APP_CAIPI.pdf — se entrega en junta.")
    pdf.bullet("GUIA_DIRECTORA_APP_CAIPI.pdf — uso interno dirección / secretaría.")
    pdf.bullet("Este archivo — presentación general del sistema.")

    pdf.recuadro(
        "Para que QR y recogida funcionen en el servidor",
        [
            "ADD_SOLICITUDES_RECOGIDA.sql",
            "ADD_DOS_PADRES_POR_ALUMNO.sql (si hay dos papás)",
            "FIX_SISTEMA_QR_TEMPORAL.sql + FIX_QR_VALIDAR_PUERTA.sql",
            "ADD_CHAT_PADRES_ESCUELA.sql (si el chat aún no está)",
        ],
        fill=(255, 243, 224),
        ink=(120, 60, 20),
    )
    pdf.output(str(OUT_PRES))


def main() -> None:
    guia_padres()
    guia_directora()
    presentacion()
    print(OUT_PADRES)
    print(OUT_DIR)
    print(OUT_PRES)


if __name__ == "__main__":
    main()
