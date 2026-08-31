# App CAIPI — Propuesta comercial

**Sistema de gestión escolar para dirección, personal y familias**  
Documento para presentación a escuelas / CAIPI

---

# PARTE 1 — Qué es y qué hace la app

## El problema que resuelve

En muchas escuelas el día a día se reparte entre WhatsApp, Excel, libretas, PDFs sueltos y “avísale a la maestra”. Eso genera:

- Cobros sin historial claro ni recibos formales  
- Padres que no saben qué pasó en el día  
- Dudas de quién puede recoger al niño  
- Información que se pierde cuando cambia el personal  
- Dirección sin reportes rápidos para tomar decisiones  

**CAIPI** concentra todo eso en una sola aplicación móvil, con usuarios por rol y datos en la nube (seguros y accesibles desde el celular o tablet).

---

## ¿Qué es CAIPI?

Es una **app escolar multi-rol**: la misma aplicación la usan la directora, las profesoras y los padres, pero cada quien ve solo lo que le corresponde.

- **Directora:** administra la escuela completa  
- **Profesora:** opera el día a día del grupo  
- **Padre / tutor:** sigue a su hijo, pagos, avisos y comunicación  

Tecnología: app móvil moderna (Flutter) + base de datos en la nube (Supabase).  
Hoy está lista para **Android**; iOS se puede publicar después con cuenta de Apple.

---

## Beneficios en lenguaje simple

| Antes | Con CAIPI |
|--------|-----------|
| Mensajes sueltos en WhatsApp | Chat y anuncios dentro de la app |
| Excel de pagos que se desactualiza | Pagos, abonos y recibos PDF |
| “¿Quién viene por el niño?” | Autorizados + solicitudes de recogida |
| Bitácoras en papel o fotos | Bitácora diaria digital |
| Reportes a mano | Reportes PDF listos para imprimir o compartir |
| Entrevistas en carpetas | Entrevista digital + PDF |

---

## Módulos explicados (qué hace cada uno)

### 1. Acceso seguro por roles
Cada persona entra con su usuario.  
La directora ve todo; la profesora su operación; el padre solo lo de su hijo.  
Incluye cambio de contraseña y control de permisos.

### 2. Alumnos y estructura de la escuela
Alta, edición y seguimiento de alumnos.  
Grados / grupos.  
Relación clara entre alumno y padre/tutor.  
Base ordenada para que el resto de módulos funcione bien.

### 3. Personas autorizadas y recogida
Registro de quién puede recoger al niño.  
Solicitudes de recogida.  
Apoyo con QR temporal para control en puerta.  
Menos confusión en la salida y más seguridad para la escuela.

### 4. Entrevista a padres
Formulario completo de entrevista ligado al alumno.  
Se puede guardar avance y completar después.  
Al terminar, se genera **PDF** para archivo de la escuela.  
Ideal para ingreso, seguimiento o reunificación de información familiar.

### 5. Pagos y cobranza
Generación de pagos según el plan de la escuela (incluye lógica de becas / planes).  
Acreditación de pagos y abonos con folio.  
**Recibo en PDF** para compartir o imprimir.  
Exportación a Excel para administración.  
Historial claro: menos “yo ya pagué” sin evidencia.

### 6. Comunicación escuela–familia
Chat entre padres y escuela.  
Anuncios y eventos.  
Registro de incidentes.  
Notificaciones para que la información llegue a tiempo, sin depender solo de grupos de WhatsApp.

### 7. Bitácora diaria
Registro del día del alumno / grupo (actividad, observaciones, seguimiento).  
Útil para profesoras y para que dirección tenga evidencia de lo ocurrido.  
Base para reportes.

### 8. Bitácora de gastos
Control de gastos de la escuela en un solo lugar.  
Apoya transparencia y reportes administrativos.

### 9. Control de entrada y salida
Registro de ingresos y salidas.  
Complementa el control de recogida y da trazabilidad del movimiento de alumnos.

### 10. Clases extracurriculares
Gestión de actividades fuera del horario regular.  
La escuela puede organizar y dar seguimiento sin hojas sueltas.

### 11. Personal (profesoras y padres)
Alta y administración de cuentas de profesoras.  
Gestión de padres vinculados a alumnos.  
La directora mantiene el directorio vivo desde la app.

### 12. Reportes PDF para dirección
Reportes listos con identidad visual de la escuela:

- Bitácora diaria  
- Gastos  
- Control de entrada / salida (por fechas)  

Para juntas, supervisiones, archivo o entrega a padres cuando aplique.

---

## ¿Para qué tipo de escuela sirve?

Pensada para **escuelas pequeñas y medianas**, CAIPI / preescolar / primaria privada, donde la directora necesita orden operativo sin contratar un sistema empresarial enorme.

Ideal si hoy ya sufren con:

- Cobranza desordenada  
- Comunicación fragmentada  
- Falta de evidencia escrita  
- Control de acceso a la salida  

---

## Qué incluye la entrega del sistema (producto)

- Aplicación instalable en Android  
- Configuración del backend en la nube  
- Roles y módulos operativos descritos arriba  
- Capacitación básica de uso (directora / personal clave)  
- Acompañamiento inicial para poner datos en marcha  

**No incluye por defecto** (se cotizan aparte si se requieren):  
cuenta Apple / publicación iOS, cuota anual de desarrollador Apple, plan de pago de Supabase en producción, personalizaciones muy específicas fuera del alcance actual.

---

## Resumen en una frase

> **CAIPI es el “centro de mando” de la escuela en el celular: alumnos, pagos, comunicación, bitácoras, acceso y reportes, con un perfil distinto para directora, profesora y padre.**

---

# PARTE 2 — Precios (separado a propósito)

> Esta sección es independiente. Primero se entiende el producto; luego se habla de inversión.  
> Los precios están en **pesos mexicanos (MXN)** y son **orientativos de venta**.

---

## Por qué no es “cara” frente a lo que reemplaza

Una escuela pequeña suele gastar, sin notarlo:

| Alternativa informal | Costo aproximado al año |
|----------------------|-------------------------|
| Tiempo de dirección armando Excel / chasing pagos | equivalente a **$30,000 – $80,000** en horas |
| Errores de cobranza / pagos no rastreados | variable, pero caro |
| Impresión / papelería / retrabajo de reportes | **$5,000 – $20,000** |
| Sistemas SaaS escolares comerciales | **$50,000 – $80,000 / año** (y el dato no es tuyo) |

**CAIPI se paga una vez** (modelo licencia) y la escuela queda con su sistema.  
Eso explica por qué el monto de entrada se ve alto: no es una app de catálogo; es un **sistema operativo escolar completo**.

Aun así, abajo hay **opciones más suaves** (paquetes y pagos diferidos), porque entendemos que para una sola escuela el efectivo importa.

---

## Opción A — Compra del sistema (recomendada)

Inversión única por escuela. Incluye app Android + módulos + capacitación básica.

| Paquete | Qué incluye | Precio |
|---------|-------------|--------|
| **Esencial** | App operativa completa (módulos actuales), configuración, capacitación 1 sesión | **$180,000** |
| **Estándar** ★ | Todo lo Esencial + acompañamiento de arranque (2–3 sesiones) + ajustes menores de marca/textos | **$230,000** |
| **Completo** | Todo lo Estándar + 3 meses de soporte correctivo + prioridad en mejoras pequeñas | **$280,000** |

★ **Recomendado para la mayoría:** **$230,000 MXN**

### Forma de pago suave (para que no duela de golpe)

Ejemplo sobre el paquete Estándar ($230,000):

| Esquema | Pagos |
|---------|--------|
| 50 / 50 | $115,000 al firmar · $115,000 al entregar / capacitar |
| 40 / 30 / 30 | $92,000 · $69,000 · $69,000 (inicio / avance / cierre) |
| 3 mensualidades | ~$76,700 × 3 (sujeto a acuerdo) |

Así el cliente no siente “casi un cuarto de millón de un solo golpe”, sino un proyecto por etapas.

---

## Opción B — Renta mensual (si el presupuesto inicial es bajo)

Ideal si la escuela prefiere **no invertir fuerte al inicio**.

| Concepto | Precio |
|----------|--------|
| Implantación / setup (una vez) | **$35,000 – $50,000** |
| Mensualidad | **$4,500 – $5,500 / mes** |

A 12 meses (ej. setup $40,000 + $5,000 × 12 = **$100,000 el primer año**).  
A 24–36 meses el total se acerca o supera la compra: por eso la renta conviene solo si necesitan **caja baja al inicio**.

---

## Opción C — Por alumno (si quieren escalar con matrícula)

| Concepto | Precio orientativo |
|----------|-------------------|
| Setup | **$25,000 – $40,000** |
| Por alumno / mes | **$45 – $70** |

Ejemplo: 80 alumnos × $55 = **$4,400 / mes** + setup.  
Útil si la matrícula crece y quieren alinear el costo con ingresos.

---

## Comparativo rápido (para decidir sin confusión)

| Si la escuela quiere… | Mejor opción | Inversión típica |
|------------------------|--------------|------------------|
| Dueño del sistema y dejar de pagar renta | **Compra Estándar** | **$230,000** (se puede diferir) |
| Empezar ya con poco efectivo | **Renta** | ~$40k setup + ~$5k/mes |
| Cobrar según tamaño | **Por alumno** | setup + $45–70/alumno/mes |

---

## Costos de plataforma (NO son el precio de la app)

Estos los paga la escuela a Apple / Google / Supabase.  
**No están incluidos en los $180k–$280k**, pero hay que presupuestarlos.

### Supabase (base de datos en la nube)
| Plan | Aprox. en MXN |
|------|----------------|
| Pruebas (Free) | $0 (limitado; no ideal en producción) |
| **Producción recomendada (Pro)** | **~$450 – $500 / mes** (~$6,000 / año) |

### Google Play (Android)
| Concepto | Aprox. |
|----------|--------|
| Cuenta de desarrollador | **~$450 – $500 una vez** (USD $25) |

### Apple / iOS / App Store (solo si quieren iPhone)
| Concepto | Aprox. en MXN |
|----------|----------------|
| Apple Developer (obligatorio cada año) | **~$1,800 – $2,100 / año** (USD $99) |
| Trabajo de publicar en App Store (certificados, build, revisión) | **$25,000 – $50,000 una vez** |
| Comisión Apple | Solo si venden algo *dentro* de la app (no aplica a tu colegiatura escolar normal fuera de la tienda) |

**Importante:** se puede vender y usar la app **solo en Android** al inicio.  
iOS se agrega después cuando el presupuesto lo permita.

---

## Ejemplo de presupuesto realista (primer año)

### Solo Android (lo más común al empezar)

| Rubro | Monto |
|-------|--------|
| App paquete Estándar | $230,000 |
| Supabase Pro (12 meses) | ~$6,000 |
| Google Play | ~$500 |
| **Total primer año** | **~$236,500** |

Años siguientes (sin comprar de nuevo la app): ~**$6,000 / año** de nube (+ soporte si lo contratan).

### Android + iOS (si lo quieren completo desde el día 1)

| Rubro | Monto |
|-------|--------|
| App paquete Estándar | $230,000 |
| Publicación iOS | $25,000 – $50,000 |
| Apple Developer | ~$2,000 |
| Supabase | ~$6,000 |
| Google Play | ~$500 |
| **Total primer año** | **~$263,500 – $288,500** |

---

## Cómo explicar el precio en una junta (guion corto)

> “No están comprando una app bonita: están comprando el sistema con el que van a cobrar, comunicar, documentar y controlar la salida de los niños.  
> En el mercado, un desarrollo así se cotiza entre 180 y 400 mil pesos. Nosotros lo dejamos en **230 mil** con forma de pago a plazos, o en renta desde **5 mil al mes** si prefieren no invertir de golpe.  
> Lo de Apple y Supabase son cuotas de tienda y nube: van aparte, como el hosting de un sitio web.”

---

## Recomendación comercial final

1. **Oferta principal:** Paquete **Estándar $230,000** con pago **40/30/30** o **50/50**.  
2. **Si dicen “está caro”:** pasar a **renta** ($40k + $5k/mes) o bajar a **Esencial $180,000**.  
3. **iOS:** dejarlo como **fase 2**, no mezclarlo en el susto del primer número.  
4. **Siempre aclarar** en la cotización: *“Precios de app. Cuentas Apple/Google/Supabase aparte.”*

---

## Contacto / siguientes pasos

1. Demo de 20–30 minutos con datos de ejemplo  
2. Definir paquete (Esencial / Estándar / Completo o Renta)  
3. Acuerdo de pago y fecha de arranque  
4. Capacitación y puesta en marcha  

---

*Documento comercial — App CAIPI · Uso interno / presentación a cliente*  
*Precios orientativos sujetos a alcance final y acuerdo escrito.*
