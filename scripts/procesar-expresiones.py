# -*- coding: utf-8 -*-
"""
Procesa las imagenes de expresiones de Kimun:
  1. Recorta el fondo solido (flood fill desde las esquinas) -> PNG transparente.
  2. Recorta el bounding box del zorro y lo centra en un lienzo cuadrado.
  3. Redimensiona a 384 px y guarda comprimido.
  4. Renombra a nombres claros; deja los originales en assets/originales/.

Uso: python scripts/procesar-expresiones.py
"""
import os
import shutil
from collections import deque

import numpy as np
from PIL import Image

ASSETS = os.path.join(os.path.dirname(__file__), "..", "assets")
ASSETS = os.path.abspath(ASSETS)
ORIG = os.path.join(ASSETS, "originales")
TAM = 384          # tamano final del lado del lienzo cuadrado
TOL = 32           # tolerancia de color para considerar "fondo"
MARGEN = 0.06      # margen alrededor del zorro (fraccion del lado)

# UUID original -> nombre claro
MAPA = {
    "9fd6d406-41a6-4e03-b6b1-6e0fbd50dcec": "kimun-feliz",
    "a153512e-335b-4a9f-b30f-9fe9f940531f": "kimun-triste",
    "95bbb2f6-e57f-4970-be13-c745428a4ff0": "kimun-desanimado",
    "fc7fbabe-efd2-41f4-af16-a2764405a696": "kimun-sorprendido",
    "58e1a07f-109e-44a2-8b03-7b530a02e615": "kimun-enojado",
    "14a718d6-8e7f-4c33-8a1b-cab5a537d371": "kimun-oro",
    "51795e5f-6ee2-49dc-87b0-30bac95ebe21": "kimun-plata",
    "1e91d938-cad0-4d0f-96ec-d45fdfbac188": "kimun-bronce",
}


def quitar_fondo(im):
    """Marca como transparente el fondo conectado a los bordes (flood fill)."""
    rgb = im.convert("RGB")
    arr = np.asarray(rgb, dtype=np.int16)
    h, w, _ = arr.shape
    visitado = np.zeros((h, w), dtype=bool)
    es_fondo = np.zeros((h, w), dtype=bool)

    # semillas: las 4 esquinas
    semillas = [(0, 0), (0, w - 1), (h - 1, 0), (h - 1, w - 1)]
    cola = deque()
    for y, x in semillas:
        if not visitado[y, x]:
            visitado[y, x] = True
            cola.append((y, x, arr[y, x].copy()))

    while cola:
        y, x, color = cola.popleft()
        # diferencia con el color de la semilla de su region
        if np.abs(arr[y, x] - color).max() > TOL:
            continue
        es_fondo[y, x] = True
        for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            ny, nx = y + dy, x + dx
            if 0 <= ny < h and 0 <= nx < w and not visitado[ny, nx]:
                if np.abs(arr[ny, nx] - color).max() <= TOL:
                    visitado[ny, nx] = True
                    cola.append((ny, nx, color))

    alpha = np.where(es_fondo, 0, 255).astype(np.uint8)
    out = im.convert("RGBA")
    datos = np.asarray(out).copy()
    datos[:, :, 3] = alpha
    return Image.fromarray(datos, "RGBA")


def recortar_y_centrar(im):
    """Recorta al bounding box de lo opaco y lo centra en un cuadrado."""
    alpha = np.asarray(im)[:, :, 3]
    ys, xs = np.where(alpha > 10)
    if len(xs) == 0:
        return im
    x0, x1 = xs.min(), xs.max()
    y0, y1 = ys.min(), ys.max()
    recorte = im.crop((x0, y0, x1 + 1, y1 + 1))

    lado = max(recorte.width, recorte.height)
    margen = int(lado * MARGEN)
    lienzo = Image.new("RGBA", (lado + 2 * margen, lado + 2 * margen), (0, 0, 0, 0))
    px = (lienzo.width - recorte.width) // 2
    py = (lienzo.height - recorte.height) // 2
    lienzo.paste(recorte, (px, py), recorte)
    return lienzo


def main():
    os.makedirs(ORIG, exist_ok=True)
    print("Procesando expresiones de Kimun\n" + "=" * 40)
    for uuid, nombre in MAPA.items():
        src = os.path.join(ASSETS, uuid + ".png")
        if not os.path.exists(src):
            print(f"  [!] falta {uuid}.png")
            continue

        im = Image.open(src)
        sin_fondo = quitar_fondo(im)
        centrado = recortar_y_centrar(sin_fondo)
        final = centrado.resize((TAM, TAM), Image.LANCZOS)

        dst = os.path.join(ASSETS, nombre + ".png")
        final.save(dst, "PNG", optimize=True)

        # mover el original a la subcarpeta
        shutil.move(src, os.path.join(ORIG, uuid + ".png"))

        kb_o = os.path.getsize(os.path.join(ORIG, uuid + ".png")) // 1024
        kb_n = os.path.getsize(dst) // 1024
        print(f"  {nombre:20s} {kb_o:5d} KB -> {kb_n:4d} KB")

    print("=" * 40 + "\nListo. Originales en assets/originales/")


if __name__ == "__main__":
    main()
