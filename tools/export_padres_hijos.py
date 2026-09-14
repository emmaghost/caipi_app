#!/usr/bin/env python3
"""Exporta papá ↔ hijo a Excel (.xlsx) o CSV.

Uso (desde la raíz del repo):
  python tools/export_padres_hijos.py

Requiere red. Usa la URL/anon key públicas del proyecto (solo lectura).
"""

from __future__ import annotations

import csv
import json
import sys
import urllib.parse
import urllib.request
from datetime import datetime
from pathlib import Path

SUPABASE_URL = "https://qxldfqnuwpucptajcazf.supabase.co"
ANON_KEY = (
    "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9."
    "eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF4bGRmcW51d3B1Y3B0YWpjYXpmIiwicm9sZSI6ImFub24i"
    "LCJpYXQiOjE3NzI1NDkxNTQsImV4cCI6MjA4ODEyNTE1NH0."
    "7ruhv9B_DyHwsdsC13EAZa2IVFMyXa5BSjlDY9-GSyE"
)

OUT_DIR = Path(__file__).resolve().parents[1] / "exports"


def _get(path: str, params: dict | None = None) -> list[dict]:
    q = urllib.parse.urlencode(params or {}, doseq=True)
    url = f"{SUPABASE_URL}/rest/v1/{path}"
    if q:
        url = f"{url}?{q}"
    req = urllib.request.Request(
        url,
        headers={
            "apikey": ANON_KEY,
            "Authorization": f"Bearer {ANON_KEY}",
            "Accept": "application/json",
            "Prefer": "count=exact",
        },
    )
    with urllib.request.urlopen(req, timeout=60) as resp:
        return json.loads(resp.read().decode("utf-8"))


def main() -> int:
    # Sin JWT de usuario, RLS puede limitar filas. Preferimos service vía SQL
    # en Dashboard; este script intenta con anon y avisa si viene vacío.
    alumnos = _get(
        "alumnos",
        {
            "select": "id,nombre,apellidos,activo,grado_id,padre_id,grados(nombre)",
            "order": "apellidos.asc,nombre.asc",
            "limit": "2000",
        },
    )
    try:
        vinculos = _get(
            "alumnos_padres",
            {
                "select": "alumno_id,padre_id,es_principal",
                "limit": "5000",
            },
        )
    except Exception:
        vinculos = []

    padres_ids = set()
    for a in alumnos:
        if a.get("padre_id"):
            padres_ids.add(a["padre_id"])
    for v in vinculos:
        if v.get("padre_id"):
            padres_ids.add(v["padre_id"])

    usuarios: dict[str, dict] = {}
    if padres_ids:
        # PostgREST: id=in.(uuid1,uuid2)
        ids = ",".join(padres_ids)
        rows = _get(
            "usuarios",
            {
                "select": "id,nombre,apellidos,email,telefono,whatsapp,rol,activo",
                "id": f"in.({ids})",
                "limit": "2000",
            },
        )
        usuarios = {r["id"]: r for r in rows}

    # Map alumno -> set de (padre_id, es_principal)
    por_alumno: dict[str, dict[str, bool]] = {}
    for a in alumnos:
        aid = a["id"]
        por_alumno.setdefault(aid, {})
        if a.get("padre_id"):
            por_alumno[aid][a["padre_id"]] = True
    for v in vinculos:
        aid = v["alumno_id"]
        pid = v["padre_id"]
        por_alumno.setdefault(aid, {})
        prev = por_alumno[aid].get(pid, False)
        por_alumno[aid][pid] = prev or bool(v.get("es_principal"))

    rows_out: list[dict] = []
    for a in alumnos:
        grado = ""
        g = a.get("grados")
        if isinstance(g, dict):
            grado = g.get("nombre") or ""
        padres = por_alumno.get(a["id"], {})
        if not padres:
            rows_out.append(
                {
                    "grado": grado or "(sin grado)",
                    "alumno": f"{a.get('nombre') or ''} {a.get('apellidos') or ''}".strip(),
                    "alumno_activo": "Sí" if a.get("activo", True) else "No",
                    "padre": "(sin papá vinculado)",
                    "padre_email": "",
                    "padre_telefono": "",
                    "tipo_vinculo": "",
                }
            )
            continue
        for pid, es_prin in sorted(
            padres.items(),
            key=lambda x: (not x[1], x[0]),
        ):
            u = usuarios.get(pid, {})
            if u and u.get("rol") and u.get("rol") != "padre":
                continue
            tel = u.get("whatsapp") or u.get("telefono") or ""
            tipo = "Principal" if es_prin or a.get("padre_id") == pid else "Segundo tutor"
            if a.get("padre_id") == pid:
                tipo = "Principal"
            rows_out.append(
                {
                    "grado": grado or "(sin grado)",
                    "alumno": f"{a.get('nombre') or ''} {a.get('apellidos') or ''}".strip(),
                    "alumno_activo": "Sí" if a.get("activo", True) else "No",
                    "padre": f"{u.get('nombre') or ''} {u.get('apellidos') or ''}".strip()
                    or pid,
                    "padre_email": u.get("email") or "",
                    "padre_telefono": tel,
                    "tipo_vinculo": tipo,
                }
            )

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    stamp = datetime.now().strftime("%Y%m%d_%H%M")
    csv_path = OUT_DIR / f"padres_hijos_{stamp}.csv"
    xlsx_path = OUT_DIR / f"padres_hijos_{stamp}.xlsx"

    fields = [
        "grado",
        "alumno",
        "alumno_activo",
        "padre",
        "padre_email",
        "padre_telefono",
        "tipo_vinculo",
    ]
    with csv_path.open("w", newline="", encoding="utf-8-sig") as f:
        w = csv.DictWriter(f, fieldnames=fields)
        w.writeheader()
        w.writerows(rows_out)

    xlsx_ok = False
    try:
        from openpyxl import Workbook

        wb = Workbook()
        ws = wb.active
        ws.title = "Padres-Hijos"
        ws.append(fields)
        for r in rows_out:
            ws.append([r[c] for c in fields])
        wb.save(xlsx_path)
        xlsx_ok = True
    except ImportError:
        pass

    print(f"Filas: {len(rows_out)}")
    print(f"CSV:  {csv_path}")
    if xlsx_ok:
        print(f"XLSX: {xlsx_path}")
    else:
        print("XLSX: (instala openpyxl para .xlsx: pip install openpyxl)")
        print("      El CSV se abre directo en Excel.")
    if not rows_out or all(r.get("padre") == "(sin papá vinculado)" for r in rows_out[:5]):
        print("")
        print("AVISO: con anon key RLS puede ocultar filas.")
        print("Mejor: corre CONSULTA_PADRES_HIJOS.sql en Supabase y Download CSV.")
        print("O en la app (directora): Padres -> icono Excel.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
