# -*- coding: utf-8 -*-
"""
KIMUN - Aplica las marcas de "revisada" al banco de preguntas.

Toma un archivo revisadas.json (exportado desde el tablero con el boton
"Exportar revisadas") y sincroniza el campo "revisada" de cada pregunta en
contenido/historia-8basico/preguntas.json:
  - revisada = True  si su id esta en la lista exportada
  - revisada = False si no

Uso:
    python scripts/aplicar-revisadas.py [ruta_a_revisadas.json]

Si no se indica ruta, busca revisadas.json en la raiz del proyecto y, si no,
en la carpeta de Descargas del usuario.

Luego vuelve a generar el tablero:
    python scripts/generar-tablero.py
"""

import json
import sys
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
PREG = RAIZ / "contenido" / "historia-8basico" / "preguntas.json"


def ubicar_revisadas():
    if len(sys.argv) > 1:
        return Path(sys.argv[1])
    cand = RAIZ / "revisadas.json"
    if cand.exists():
        return cand
    descargas = Path.home() / "Downloads" / "revisadas.json"
    if descargas.exists():
        return descargas
    return cand  # inexistente: se reportara el error


def main():
    ruta = ubicar_revisadas()
    if not ruta.exists():
        print(f"No se encontro el archivo de revisadas: {ruta}")
        print("Exporta primero desde el tablero (boton 'Exportar revisadas') o indica la ruta.")
        sys.exit(1)

    data = json.load(open(ruta, encoding="utf-8"))
    ids = set(data.get("revisadas", []))

    d = json.load(open(PREG, encoding="utf-8"))
    cambios = 0
    for q in d["preguntas"]:
        nuevo = q.get("id") in ids
        if bool(q.get("revisada")) != nuevo:
            cambios += 1
        q["revisada"] = nuevo
    d["revisadas"] = sum(1 for q in d["preguntas"] if q.get("revisada"))

    json.dump(d, open(PREG, "w", encoding="utf-8"), ensure_ascii=False, indent=2)
    print(f"Aplicado desde: {ruta}")
    print(f"Revisadas ahora: {d['revisadas']}/{len(d['preguntas'])} (cambios: {cambios})")
    print("Recuerda regenerar el tablero: python scripts/generar-tablero.py")


if __name__ == "__main__":
    main()
