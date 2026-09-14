// Supabase Edge Function: notifica por FCM cuando hay mensaje de chat o recogida.
// Secrets: FIREBASE_SERVICE_ACCOUNT_JSON (JSON completo de la service account)

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

const FCM_SCOPE = "https://www.googleapis.com/auth/firebase.messaging";

type ServiceAccount = {
  project_id: string;
  client_email: string;
  private_key: string;
};

type WebhookPayload = {
  type?: string;
  table?: string;
  record?: Record<string, unknown>;
  old_record?: Record<string, unknown> | null;
};

Deno.serve(async (req) => {
  try {
    if (req.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: cors() });
    }
    if (req.method !== "POST") {
      return json({ error: "POST only" }, 405);
    }

    const saJson = Deno.env.get("FIREBASE_SERVICE_ACCOUNT_JSON") ??
      (Deno.env.get("FIREBASE_SERVICE_ACCOUNT_B64")
        ? atob(Deno.env.get("FIREBASE_SERVICE_ACCOUNT_B64")!)
        : null);
    if (!saJson) {
      return json({
        error: "Falta secret FIREBASE_SERVICE_ACCOUNT_JSON o FIREBASE_SERVICE_ACCOUNT_B64",
      }, 500);
    }
    const sa = JSON.parse(saJson) as ServiceAccount;

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const admin = createClient(supabaseUrl, serviceKey);

    const body = (await req.json()) as WebhookPayload & {
      title?: string;
      body?: string;
      usuario_ids?: string[];
      tokens?: string[];
      tipo?: string;
      alumno_id?: string;
      quien_recibio?: string;
      fecha?: string;
      notificar_padres?: boolean;
      padre_solicitante_id?: string;
    };

    // Modo entrega: papá(s) + maestra(s) del grupo
    if (body.tipo === "entrega_completada" && body.alumno_id) {
      const result = await handleEntregaCompletada(admin, sa, {
        alumno_id: body.alumno_id,
        quien_recibio: body.quien_recibio,
        fecha: body.fecha,
        notificar_padres: body.notificar_padres !== false,
        padre_solicitante_id: body.padre_solicitante_id,
      });
      return json({ ok: true, ...result });
    }

    // Modo manual: { title, body, usuario_ids } o { tokens }
    if (body.title && (body.tokens?.length || body.usuario_ids?.length)) {
      const tokens = body.tokens?.length
        ? body.tokens
        : await tokensDeUsuarios(admin, body.usuario_ids!);
      const sent = await sendFcm(sa, tokens, body.title, body.body ?? "", {});
      return json({ ok: true, sent });
    }

    // Webhook Database: INSERT en mensajes_chat
    if (body.table === "mensajes_chat" && body.record) {
      const result = await handleChatMessage(admin, sa, body.record);
      return json({ ok: true, ...result });
    }

    // Webhook: INSERT solicitudes_recogida (padre pide al niño)
    if (body.table === "solicitudes_recogida" && body.record) {
      const result = await handleSolicitud(admin, sa, body.record);
      return json({ ok: true, ...result });
    }

    // Webhook: INSERT abonos (pago acreditado → padre imprime recibo)
    if (body.table === "abonos" && body.record) {
      const result = await handleAbono(admin, sa, body.record);
      return json({ ok: true, ...result });
    }

    return json({
      error:
        "Payload no reconocido. Tablas: mensajes_chat | solicitudes_recogida | abonos | tipo=entrega_completada",
    }, 400);
  } catch (e) {
    console.error(e);
    return json({ error: String(e) }, 500);
  }
});

function cors() {
  return {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers":
      "authorization, x-client-info, apikey, content-type",
  };
}

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...cors(), "Content-Type": "application/json" },
  });
}

async function handleChatMessage(
  admin: ReturnType<typeof createClient>,
  sa: ServiceAccount,
  record: Record<string, unknown>,
) {
  const conversacionId = record.conversacion_id as string;
  const remitenteId = record.remitente_id as string;
  const contenido = String(record.contenido ?? "").slice(0, 120);

  const { data: conv } = await admin
    .from("conversaciones")
    .select("padre_id, canal, staff_id")
    .eq("id", conversacionId)
    .maybeSingle();

  if (!conv?.padre_id) return { sent: 0, reason: "sin conversacion" };

  const { data: remitente } = await admin
    .from("usuarios")
    .select("id, nombre, rol")
    .eq("id", remitenteId)
    .maybeSingle();

  const nombre = remitente?.nombre ?? "CAIPI";
  const esPadre = remitente?.rol === "padre";
  const canal = (conv.canal as string | null) ?? "directora";
  const staffId = (conv.staff_id as string | null) ?? null;

  // Destinatarios = solo el otro lado del hilo (no broadcast a todo el staff).
  let destinos: string[] = [];
  if (esPadre) {
    if (staffId) {
      // Papá → miss (o staff concreto del hilo)
      destinos = [staffId];
    } else if (canal === "profesor") {
      // Hilo profe sin staff_id (dato incompleto): no avisar a directora
      return { sent: 0, reason: "hilo profesor sin staff_id" };
    } else {
      // Papá → directora(s) del canal escuela
      const { data: directoras } = await admin
        .from("usuarios")
        .select("id")
        .eq("rol", "directora")
        .eq("activo", true);
      destinos = (directoras ?? []).map((u) => u.id as string);
    }
  } else {
    // Staff → solo el papá de esa conversación
    destinos = [conv.padre_id as string];
  }

  destinos = destinos.filter((id) => id !== remitenteId);
  if (destinos.length === 0) {
    return { sent: 0, reason: "sin destinos", canal, staff_id: staffId };
  }

  const tokens = await tokensDeUsuarios(admin, destinos);
  if (tokens.length === 0) {
    return {
      sent: 0,
      reason: "sin tokens",
      destinos: destinos.length,
      canal,
      staff_id: staffId,
    };
  }

  const title = esPadre ? `Chat: ${nombre}` : `Escuela: ${nombre}`;
  const sent = await sendFcm(sa, tokens, title, contenido || "Nuevo mensaje", {
    tipo: "chat",
    conversacion_id: conversacionId,
    ruta: esPadre ? "/directora/chat" : "/padre/chat",
  });
  return {
    sent,
    destinos: destinos.length,
    tokens: tokens.length,
    canal,
    staff_id: staffId,
  };
}

async function handleEntregaCompletada(
  admin: ReturnType<typeof createClient>,
  sa: ServiceAccount,
  args: {
    alumno_id: string;
    quien_recibio?: string;
    fecha?: string;
    notificar_padres?: boolean;
    padre_solicitante_id?: string;
  },
) {
  const alumnoId = args.alumno_id?.trim();
  if (!alumnoId) return { sent: 0, reason: "sin alumno_id" };

  const { data: alumno } = await admin
    .from("alumnos")
    .select("id, nombre, apellidos, padre_id, grado_id")
    .eq("id", alumnoId)
    .maybeSingle();

  if (!alumno) return { sent: 0, reason: "alumno no encontrado" };

  const nombreAlumno =
    `${alumno.nombre ?? ""} ${alumno.apellidos ?? ""}`.trim() || "el niño/a";
  const notificarPadres = args.notificar_padres !== false;

  const destinos = new Set<string>();
  const padresIds = new Set<string>();

  if (alumno.padre_id) padresIds.add(alumno.padre_id as string);
  try {
    const { data: ap } = await admin
      .from("alumnos_padres")
      .select("padre_id")
      .eq("alumno_id", alumnoId);
    for (const row of ap ?? []) {
      if (row.padre_id) padresIds.add(row.padre_id as string);
    }
  } catch (_) {
    // tabla opcional
  }

  const solicitante = (args.padre_solicitante_id ?? "").trim();
  // Solo el papá de ESTA solicitud, si realmente es tutor de este niño.
  const solicitanteEsTutor = solicitante.length > 0 && padresIds.has(solicitante);

  let quien = "";
  if (solicitanteEsTutor) {
    const { data: u } = await admin
      .from("usuarios")
      .select("nombre, apellidos")
      .eq("id", solicitante)
      .maybeSingle();
    quien = `${u?.nombre ?? ""} ${u?.apellidos ?? ""}`.trim();
  }
  if (!quien) {
    const raw = (args.quien_recibio ?? "").trim();
    if (raw && padresIds.size > 0) {
      const { data: tutores } = await admin
        .from("usuarios")
        .select("nombre, apellidos")
        .in("id", [...padresIds]);
      const nombres = new Set(
        (tutores ?? []).map((u) =>
          `${u.nombre ?? ""} ${u.apellidos ?? ""}`.trim().toLowerCase()
        ),
      );
      if (nombres.has(raw.toLowerCase())) quien = raw;
    } else if (raw && !raw.toLowerCase().startsWith("padre de ")) {
      quien = raw;
    }
  }
  const quienTxt = quien ? ` Lo recogió: ${quien}.` : "";
  const { etiquetaCorta, etiquetaLarga, esHoy } = etiquetaFechaSalida(
    args.fecha,
  );

  if (notificarPadres) {
    for (const id of padresIds) destinos.add(id);
  }

  const gradoId = alumno.grado_id as string | null;
  if (gradoId) {
    const { data: viaLegado } = await admin
      .from("profesores")
      .select("usuario_id")
      .eq("grado_id", gradoId)
      .eq("activo", true);
    for (const row of viaLegado ?? []) {
      if (row.usuario_id) destinos.add(row.usuario_id as string);
    }

    const { data: viaMulti } = await admin
      .from("profesores_grados")
      .select("profesor_id, profesores!inner(usuario_id, activo)")
      .eq("grado_id", gradoId);
    for (const row of viaMulti ?? []) {
      const p = row.profesores as
        | { usuario_id?: string; activo?: boolean }
        | { usuario_id?: string; activo?: boolean }[]
        | null;
      const list = Array.isArray(p) ? p : p ? [p] : [];
      for (const prof of list) {
        if (prof.activo !== false && prof.usuario_id) {
          destinos.add(prof.usuario_id);
        }
      }
    }
  }

  const ids = [...destinos];
  if (ids.length === 0) {
    return {
      sent: 0,
      reason: notificarPadres ? "sin destinatarios" : "sin maestras (padres omitidos)",
      padres: padresIds.size,
    };
  }

  const tokens = await tokensDeUsuarios(admin, ids);
  if (tokens.length === 0) {
    return {
      sent: 0,
      reason: "sin tokens",
      destinos: ids.length,
      padres: padresIds.size,
    };
  }

  const nPadres = padresIds.size;
  const padresTxt = notificarPadres
    ? (nPadres >= 2 ? " (ambos tutores)" : nPadres === 1 ? " (tutor)" : "")
    : "";

  const title = esHoy
    ? `Niño recogido · hoy ${etiquetaCorta}`
    : `Salida del ${etiquetaCorta} (no es de ahora)`;
  const body = esHoy
    ? `${nombreAlumno} ya fue entregado hoy (${etiquetaLarga}).${quienTxt}${padresTxt}`
    : `${nombreAlumno}: registro de salida del ${etiquetaLarga} (día anterior, no es entrega de este momento).${quienTxt}`;

  const sent = await sendFcm(
    sa,
    tokens,
    title,
    body,
    {
      tipo: "entrega",
      alumno_id: alumnoId,
      fecha: args.fecha ?? "",
      notificar_padres: notificarPadres ? "1" : "0",
      ruta: "/directora/entrega-afuera",
    },
  );
  return {
    sent,
    destinos: ids.length,
    tokens: tokens.length,
    padres_notificados: notificarPadres ? nPadres : 0,
  };
}

/** Fecha de la salida en español (México). */
function etiquetaFechaSalida(fechaYmd?: string): {
  etiquetaCorta: string;
  etiquetaLarga: string;
  esHoy: boolean;
} {
  const now = new Date();
  // Comparar en zona México (UTC-6 aprox.; sin DST en la mayoría del país desde 2022)
  const fmt = new Intl.DateTimeFormat("en-CA", {
    timeZone: "America/Mexico_City",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  });
  const hoyYmd = fmt.format(now); // YYYY-MM-DD
  const ymd = (fechaYmd && /^\d{4}-\d{2}-\d{2}/.test(fechaYmd))
    ? fechaYmd.slice(0, 10)
    : hoyYmd;
  const esHoy = ymd === hoyYmd;

  // Fecha local mediodía para evitar desfases de zona
  const [y, m, d] = ymd.split("-").map(Number);
  const ref = new Date(Date.UTC(y, m - 1, d, 18, 0, 0));

  const corta = new Intl.DateTimeFormat("es-MX", {
    timeZone: "America/Mexico_City",
    day: "numeric",
    month: "short",
  }).format(ref);
  const larga = new Intl.DateTimeFormat("es-MX", {
    timeZone: "America/Mexico_City",
    weekday: "long",
    day: "numeric",
    month: "long",
  }).format(ref);

  return {
    etiquetaCorta: corta,
    etiquetaLarga: larga,
    esHoy,
  };
}

async function handleSolicitud(
  admin: ReturnType<typeof createClient>,
  sa: ServiceAccount,
  record: Record<string, unknown>,
) {
  if (record.estado && record.estado !== "pendiente") {
    return { sent: 0, reason: "no pendiente" };
  }

  const alumnoId = record.alumno_id as string | undefined;
  let nombreAlumno = "un alumno";
  if (alumnoId) {
    const { data: alumno } = await admin
      .from("alumnos")
      .select("nombre, apellidos")
      .eq("id", alumnoId)
      .maybeSingle();
    if (alumno) {
      nombreAlumno = `${alumno.nombre ?? ""} ${alumno.apellidos ?? ""}`.trim();
    }
  }

  const { data: staff } = await admin
    .from("usuarios")
    .select("id")
    .in("rol", ["directora", "profesor", "profesor_admin"])
    .eq("activo", true);

  const tokens = await tokensDeUsuarios(
    admin,
    (staff ?? []).map((u) => u.id as string),
  );
  if (tokens.length === 0) return { sent: 0, reason: "sin tokens" };

  const sent = await sendFcm(
    sa,
    tokens,
    "Padre en la entrada",
    `Solicitud de recogida: ${nombreAlumno}`,
    { tipo: "recogida", ruta: "/directora/entrega-afuera", alumno_id: alumnoId ?? "" },
  );
  return { sent };
}

async function handleAbono(
  admin: ReturnType<typeof createClient>,
  sa: ServiceAccount,
  record: Record<string, unknown>,
) {
  const pagoId = record.pago_id as string;
  const monto = Number(record.monto ?? 0);
  const folio = record.folio != null ? String(record.folio) : null;

  const { data: pago } = await admin
    .from("pagos")
    .select("id, alumno_id, concepto, mes, estatus")
    .eq("id", pagoId)
    .maybeSingle();

  if (!pago?.alumno_id) return { sent: 0, reason: "pago sin alumno" };

  const { data: alumno } = await admin
    .from("alumnos")
    .select("id, nombre, apellidos, padre_id")
    .eq("id", pago.alumno_id)
    .maybeSingle();

  if (!alumno?.padre_id) return { sent: 0, reason: "alumno sin padre" };

  const tokens = await tokensDeUsuarios(admin, [alumno.padre_id as string]);
  if (tokens.length === 0) return { sent: 0, reason: "padre sin token" };

  const nombreAlumno =
    `${alumno.nombre ?? ""} ${alumno.apellidos ?? ""}`.trim() || "tu hijo/a";
  const concepto = String(pago.concepto ?? pago.mes ?? "pago").slice(0, 60);
  const montoTxt = monto.toLocaleString("es-MX", {
    style: "currency",
    currency: "MXN",
  });
  const folioTxt = folio ? ` Folio ${folio}.` : "";

  const sent = await sendFcm(
    sa,
    tokens,
    "Pago registrado",
    `${montoTxt} de ${concepto} (${nombreAlumno}).${folioTxt} Abre para ver e imprimir tu recibo.`,
    {
      tipo: "pago",
      pago_id: pagoId,
      alumno_id: alumno.id as string,
      abono_id: String(record.id ?? ""),
      ruta: `/padre/hijo/${alumno.id}/pagos`,
    },
  );
  return { sent, padre_id: alumno.padre_id };
}

async function tokensDeUsuarios(
  admin: ReturnType<typeof createClient>,
  usuarioIds: string[],
): Promise<string[]> {
  if (usuarioIds.length === 0) return [];
  const { data } = await admin
    .from("device_tokens")
    .select("token")
    .in("usuario_id", usuarioIds)
    .eq("activo", true);
  const set = new Set<string>();
  for (const row of data ?? []) {
    if (row.token) set.add(row.token as string);
  }
  return [...set];
}

async function sendFcm(
  sa: ServiceAccount,
  tokens: string[],
  title: string,
  body: string,
  data: Record<string, string>,
): Promise<number> {
  if (tokens.length === 0) return 0;
  const accessToken = await getGoogleAccessToken(sa);
  let ok = 0;
  // FCM v1: un token por request (simple y fiable)
  for (const token of tokens) {
    const res = await fetch(
      `https://fcm.googleapis.com/v1/projects/${sa.project_id}/messages:send`,
      {
        method: "POST",
        headers: {
          Authorization: `Bearer ${accessToken}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          message: {
            token,
            notification: { title, body },
            data: Object.fromEntries(
              Object.entries(data).map(([k, v]) => [k, String(v)]),
            ),
            android: { priority: "high" },
          },
        }),
      },
    );
    if (res.ok) {
      ok++;
    } else {
      const err = await res.text();
      console.error("FCM error", res.status, err);
    }
  }
  return ok;
}

async function getGoogleAccessToken(sa: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = { alg: "RS256", typ: "JWT" };
  const claim = {
    iss: sa.client_email,
    scope: FCM_SCOPE,
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  };

  const enc = (obj: unknown) =>
    btoa(String.fromCharCode(...new TextEncoder().encode(JSON.stringify(obj))))
      .replace(/=/g, "")
      .replace(/\+/g, "-")
      .replace(/\//g, "_");

  const unsigned = `${enc(header)}.${enc(claim)}`;
  const key = await importPrivateKey(sa.private_key);
  const sigBuf = await crypto.subtle.sign(
    { name: "RSASSA-PKCS1-v1_5" },
    key,
    new TextEncoder().encode(unsigned),
  );
  const sig = btoa(String.fromCharCode(...new Uint8Array(sigBuf)))
    .replace(/=/g, "")
    .replace(/\+/g, "-")
    .replace(/\//g, "_");

  const jwt = `${unsigned}.${sig}`;

  const tokenRes = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });
  if (!tokenRes.ok) {
    throw new Error(`OAuth token: ${await tokenRes.text()}`);
  }
  const tokenJson = await tokenRes.json();
  return tokenJson.access_token as string;
}

async function importPrivateKey(pem: string): Promise<CryptoKey> {
  const pemContents = pem
    .replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "")
    .replace(/\s/g, "");
  const binary = Uint8Array.from(atob(pemContents), (c) => c.charCodeAt(0));
  return await crypto.subtle.importKey(
    "pkcs8",
    binary.buffer,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
}
