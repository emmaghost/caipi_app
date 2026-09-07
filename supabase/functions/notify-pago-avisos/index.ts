// Edge Function: avisos de pago programados (cron diario).
// Desplegar: npx supabase functions deploy notify-pago-avisos --no-verify-jwt
// Cron sugerido (Dashboard → Edge Functions → Schedules): 0 15 * * * (9:00 CDMX)

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

const FCM_SCOPE = "https://www.googleapis.com/auth/firebase.messaging";

type ServiceAccount = {
  project_id: string;
  client_email: string;
  private_key: string;
};

Deno.serve(async (req) => {
  try {
    if (req.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: cors() });
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const admin = createClient(supabaseUrl, serviceKey);

    const body = req.method === "POST"
      ? await req.json().catch(() => ({}))
      : {};
    const force = body.force === true;
    const onlyId = body.aviso_id as string | undefined;

    const hoy = new Date();
    // America/Mexico_City approx: UTC-6 (sin DST fino; suficiente para día del mes)
    const mx = new Date(hoy.getTime() - 6 * 60 * 60 * 1000);
    const dia = mx.getUTCDate();
    const ymd = mx.toISOString().slice(0, 10);

    let q = admin
      .from("pago_avisos_programados")
      .select("*")
      .eq("activo", true);
    if (onlyId) q = q.eq("id", onlyId);
    else if (!force) q = q.eq("dia_mes", dia);

    const { data: avisos, error } = await q;
    if (error) return json({ error: error.message }, 500);
    if (!avisos?.length) {
      return json({ ok: true, dia, sent: 0, reason: "sin avisos para hoy" });
    }

    type Fila = {
      padre_id: string;
      alumno_id: string;
      alumno_nombre: string;
      saldo: number;
    };

    async function cargarDestinatarios(tipo: string) {
      const rpc = tipo === "adeudo"
        ? "padres_con_adeudo_vencido_colegiatura"
        : "padres_con_adeudo_colegiatura";
      let { data, error: errA } = await admin.rpc(rpc);
      if (errA && tipo === "adeudo") {
        // fallback si aún no existe la función nueva
        const fb = await admin.rpc("padres_con_adeudo_colegiatura");
        data = fb.data;
        errA = fb.error;
      }
      if (errA) throw new Error(errA.message);
      return (data ?? []) as Fila[];
    }

    const saJson = Deno.env.get("FIREBASE_SERVICE_ACCOUNT_JSON") ??
      (Deno.env.get("FIREBASE_SERVICE_ACCOUNT_B64")
        ? atob(Deno.env.get("FIREBASE_SERVICE_ACCOUNT_B64")!)
        : null);
    const sa = saJson ? JSON.parse(saJson) as ServiceAccount : null;

    let pushSent = 0;
    let padresTotal = 0;
    for (const aviso of avisos) {
      const tipo = String(aviso.tipo ?? "pronto_pago");
      const filas = await cargarDestinatarios(tipo);
      const porPadre = new Map<string, { hijos: string[]; saldo: number }>();
      for (const f of filas) {
        const prev = porPadre.get(f.padre_id);
        if (!prev) {
          porPadre.set(f.padre_id, {
            hijos: [f.alumno_nombre?.trim() || "tu hijo/a"],
            saldo: Number(f.saldo) || 0,
          });
        } else {
          prev.hijos.push(f.alumno_nombre?.trim() || "tu hijo/a");
          prev.saldo += Number(f.saldo) || 0;
        }
      }
      padresTotal += porPadre.size;
      if (aviso.solo_con_adeudo && porPadre.size === 0) continue;

      for (const [padreId, info] of porPadre) {
        if (!aviso.enviar_push || !sa) continue;

        const { data: ya } = await admin
          .from("pago_avisos_envios")
          .select("id")
          .eq("aviso_id", aviso.id)
          .eq("padre_id", padreId)
          .eq("ymd", ymd)
          .eq("canal", "push")
          .maybeSingle();
        if (ya) continue;

        const nombre = info.hijos.length === 1
          ? info.hijos[0]
          : info.hijos.join(", ");
        const saldo = new Intl.NumberFormat("es-MX", {
          style: "currency",
          currency: "MXN",
          minimumFractionDigits: 2,
          maximumFractionDigits: 2,
        }).format(info.saldo);
        const bodyTxt = String(aviso.mensaje)
          .replaceAll("{nombre_hijo}", nombre)
          .replaceAll("{nombres_hijos}", nombre)
          .replaceAll("{saldo}", saldo);

        const { data: tokens } = await admin
          .from("device_tokens")
          .select("token")
          .eq("usuario_id", padreId)
          .eq("activo", true);
        const list = [...new Set((tokens ?? []).map((t) => t.token).filter(Boolean))];
        if (list.length === 0) continue;

        const rawTitle = String(aviso.titulo ?? "Recordatorio de pago");
        const low = rawTitle.toLowerCase();
        const title = (low.startsWith("administración caipi") ||
            low.startsWith("administracion caipi"))
          ? rawTitle
          : `Administración CAIPI informa · ${rawTitle}`;

        const n = await sendFcm(
          sa,
          list,
          title,
          bodyTxt.slice(0, 180),
          { tipo: "aviso_pago", ruta: "/padre" },
        );
        pushSent += n;
        if (n > 0) {
          await admin.from("pago_avisos_envios").upsert({
            aviso_id: aviso.id,
            padre_id: padreId,
            ymd,
            canal: "push",
          }, { onConflict: "aviso_id,padre_id,ymd,canal" });
        }
      }

      await admin.from("pago_avisos_programados").update({
        last_run_ymd: ymd,
        updated_at: new Date().toISOString(),
      }).eq("id", aviso.id);
    }

    return json({
      ok: true,
      dia,
      ymd,
      padres_destinatarios: padresTotal,
      push_sent: pushSent,
      note: "Chat masivo: usar «Enviar ahora» en la app (directora/caja).",
    });
  } catch (e) {
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
    headers: { "Content-Type": "application/json", ...cors() },
  });
}

async function getGoogleAccessToken(sa: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = btoa(JSON.stringify({ alg: "RS256", typ: "JWT" }))
    .replace(/=+$/, "").replace(/\+/g, "-").replace(/\//g, "_");
  const claim = btoa(JSON.stringify({
    iss: sa.client_email,
    scope: FCM_SCOPE,
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  })).replace(/=+$/, "").replace(/\+/g, "-").replace(/\//g, "_");

  const pem = sa.private_key.replace(/\\n/g, "\n");
  const key = await crypto.subtle.importKey(
    "pkcs8",
    pemToBuf(pem),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const sig = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    new TextEncoder().encode(`${header}.${claim}`),
  );
  const signature = btoa(String.fromCharCode(...new Uint8Array(sig)))
    .replace(/=+$/, "").replace(/\+/g, "-").replace(/\//g, "_");
  const jwt = `${header}.${claim}.${signature}`;

  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });
  const data = await res.json();
  if (!data.access_token) throw new Error("No access_token FCM");
  return data.access_token as string;
}

function pemToBuf(pem: string): ArrayBuffer {
  const b64 = pem.replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "")
    .replace(/\s+/g, "");
  const bin = atob(b64);
  const buf = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) buf[i] = bin.charCodeAt(i);
  return buf.buffer;
}

async function sendFcm(
  sa: ServiceAccount,
  tokens: string[],
  title: string,
  body: string,
  data: Record<string, string>,
): Promise<number> {
  const accessToken = await getGoogleAccessToken(sa);
  let ok = 0;
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
            data,
            android: { priority: "high" },
          },
        }),
      },
    );
    if (res.ok) ok++;
  }
  return ok;
}
