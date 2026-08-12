# -*- coding: utf-8 -*-
"""
KIMUN - Consolida el pool verificado de preguntas en preguntas.json.

- Lee los archivos verificados en contenido/historia-8basico/_pool/verificado/
- Conserva las preguntas previas de preguntas.json (si existen)
- Quita duplicados por texto normalizado
- Baraja las opciones de cada pregunta (elimina el sesgo de posición) con
  semilla fija (resultado reproducible)
- Asigna IDs estables por OA (hist8-<oa>-<n>)
- Escribe preguntas.json ordenado por OA

Uso:
    python scripts/consolidar-pool.py
"""

import json
import glob
import random
import unicodedata
from collections import defaultdict, Counter
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
BASE = RAIZ / "contenido" / "historia-8basico"
VERIF = BASE / "_pool" / "verificado"
SALIDA = BASE / "preguntas.json"
META_POR_OA = 25
SEMILLA = 42


def norm(txt):
    t = unicodedata.normalize("NFKD", txt).encode("ascii", "ignore").decode().lower()
    return " ".join(t.split())


def oa_num(codigo):
    try:
        return int(codigo.split("OA")[-1])
    except Exception:
        return 999


def barajar(opciones, correcta, rnd):
    correcta_txt = opciones[correcta]
    mezcladas = opciones[:]
    rnd.shuffle(mezcladas)
    return mezcladas, mezcladas.index(correcta_txt)


def main():
    rnd = random.Random(SEMILLA)

    # 1) Semilla: preguntas previas de preguntas.json (si existen)
    previas = []
    if SALIDA.exists():
        try:
            prev = json.load(open(SALIDA, encoding="utf-8"))
            previas = prev.get("preguntas", [])
        except Exception:
            previas = []

    # 2) Pool verificado
    verificadas = []
    for f in sorted(glob.glob(str(VERIF / "g*.json"))):
        verificadas.extend(json.load(open(f, encoding="utf-8")))

    # 3) Unir + dedupe por texto
    vistos = set()
    combinadas = []
    for q in previas + verificadas:
        clave = norm(q["pregunta"])
        if clave in vistos:
            continue
        vistos.add(clave)
        combinadas.append(q)

    # 4) Barajar opciones + limpiar campos
    por_oa = defaultdict(list)
    for q in combinadas:
        ops, idx = barajar(list(q["opciones"]), int(q["correcta"]), rnd)
        por_oa[q["oa"]].append({
            "oa": q["oa"],
            "pregunta": q["pregunta"].strip(),
            "opciones": ops,
            "correcta": idx,
            "tip": q.get("tip", "").strip(),
        })

    # 5) IDs estables por OA, ordenado
    final = []
    resumen = Counter()
    for oa in sorted(por_oa, key=oa_num):
        for i, q in enumerate(por_oa[oa], 1):
            n = oa_num(oa)
            q["id"] = f"hist8-oa{n:02d}-{i:03d}"
            q_orden = {"id": q["id"], "oa": q["oa"], "pregunta": q["pregunta"],
                       "opciones": q["opciones"], "correcta": q["correcta"], "tip": q["tip"]}
            final.append(q_orden)
            resumen[oa] += 1

    salida = {
        "asignatura": "Historia, Geografía y Ciencias Sociales",
        "nivel": "8° básico",
        "meta_preguntas_por_oa": META_POR_OA,
        "total_preguntas": len(final),
        "nota": "Preguntas originales alineadas a las Bases Curriculares (MINEDUC) de 8° básico. Generadas por agentes y verificadas por agentes revisores (exactitud factual, respuesta correcta, alineación al OA y lenguaje neutro). Opciones barajadas para evitar sesgo de posición.",
        "preguntas": final,
    }
    with open(SALIDA, "w", encoding="utf-8") as fh:
        json.dump(salida, fh, ensure_ascii=False, indent=2)

    print(f"Escrito: {SALIDA}")
    print(f"Total preguntas: {len(final)} | OA: {len(resumen)}")
    bajo = [f"{oa}:{n}" for oa, n in resumen.items() if n < META_POR_OA]
    print("OA bajo la meta:", bajo if bajo else "ninguno")
    # Distribucion de posicion de la respuesta correcta (control de sesgo)
    pos = Counter(q["correcta"] for q in final)
    print("Posicion de la correcta (0..3):", dict(sorted(pos.items())))


if __name__ == "__main__":
    main()
