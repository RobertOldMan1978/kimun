# -*- coding: utf-8 -*-
"""
Procesamiento DIFERENCIADO del segundo lote de imagenes de Kimun.

  Grupo A (personaje/vestuario): recorta fondo -> PNG transparente, centrado, 384px.
  Grupo B (fiesta):              recorta fondo y se queda SOLO con el zorro
                                 (componente conectada mas grande), descarta confeti.
  Grupo C (escenas/portadas):    NO recorta. Solo optimiza a 512px cuadrado, con fondo.
  Grupo D (tarjeta social):      NO recorta. Solo optimiza a 512px, con fondo.

Los originales se mueven a assets/originales/.
Uso: python scripts/procesar-nuevas.py
"""
import os
import shutil
from collections import deque

import numpy as np
from PIL import Image
from scipy import ndimage

ASSETS = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "assets"))
ORIG = os.path.join(ASSETS, "originales")
TOL = 32
MARGEN = 0.06

# (uuid, nombre_final, grupo)
LOTE = [
    ("05d5c7fc-0fc7-4b96-a6a0-48b34b7d5234", "kimun-conquistador", "A"),
    ("83be40b1-5e61-4a39-b2a9-02899abb8568", "kimun-historiador",  "A"),
    ("e02f39af-427e-4574-bfe4-b10955886db5", "kimun-clasico",      "A"),
    ("2bb33314-62c8-40c9-bcdd-b3a2ee9c7300", "kimun-neutral",      "A"),
    ("50a9855e-e481-448d-922a-0ba882dcc16e", "kimun-fiesta",       "B"),
    ("469138fb-c908-4a36-ba47-267c663eee1a", "portada-matematicas", "C"),
    ("51ca0011-62c4-49b0-ae69-3638cb9c4943", "portada-historia",    "C"),
    ("5d0c33be-f182-47db-8345-ffdda553538e", "portada-ciencias",    "C"),
    ("a03eeb9d-4685-43cc-b682-66a7cdd40b06", "portada-lenguaje",    "C"),
    ("78a4d860-934d-4349-8165-5429eedd0ae3", "kimun-cumpleanos",    "D"),
]


def quitar_fondo(im):
    """Flood fill desde las 4 esquinas -> alpha=0 en el fondo conectado."""
    arr = np.asarray(im.convert("RGB"), dtype=np.int16)
    h, w, _ = arr.shape
    visitado = np.zeros((h, w), dtype=bool)
    es_fondo = np.zeros((h, w), dtype=bool)
    cola = deque()
    for y, x in ((0, 0), (0, w - 1), (h - 1, 0), (h - 1, w - 1)):
        if not visitado[y, x]:
            visitado[y, x] = True
            cola.append((y, x, arr[y, x].copy()))
    while cola:
        y, x, color = cola.popleft()
        if np.abs(arr[y, x] - color).max() > TOL:
            continue
        es_fondo[y, x] = True
        for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            ny, nx = y + dy, x + dx
            if 0 <= ny < h and 0 <= nx < w and not visitado[ny, nx]:
                if np.abs(arr[ny, nx] - color).max() <= TOL:
                    visitado[ny, nx] = True
                    cola.append((ny, nx, color))
    out = np.asarray(im.convert("RGBA")).copy()
    out[:, :, 3] = np.where(es_fondo, 0, 255).astype(np.uint8)
    return Image.fromarray(out, "RGBA")


def solo_componente_mayor(im):
    """Deja opaca solo la mancha conectada mas grande (el zorro)."""
    alpha = np.asarray(im)[:, :, 3] > 10
    etiquetas, n = ndimage.label(alpha)
    if n <= 1:
        return im
    tamanos = ndimage.sum(np.ones_like(etiquetas), etiquetas, range(1, n + 1))
    mayor = int(np.argmax(tamanos)) + 1
    mascara = etiquetas == mayor
    out = np.asarray(im).copy()
    out[:, :, 3] = np.where(mascara, out[:, :, 3], 0)
    return Image.fromarray(out, "RGBA")


def recortar_y_centrar(im):
    alpha = np.asarray(im)[:, :, 3]
    ys, xs = np.where(alpha > 10)
    if len(xs) == 0:
        return im
    im = im.crop((xs.min(), ys.min(), xs.max() + 1, ys.max() + 1))
    lado = max(im.width, im.height)
    m = int(lado * MARGEN)
    lienzo = Image.new("RGBA", (lado + 2 * m, lado + 2 * m), (0, 0, 0, 0))
    lienzo.paste(im, ((lienzo.width - im.width) // 2, (lienzo.height - im.height) // 2), im)
    return lienzo


def cuadrar_con_fondo(im, tam):
    """Para escenas: centra en cuadrado (rellena con el color de borde) y escala."""
    im = im.convert("RGB")
    lado = max(im.width, im.height)
    # color de fondo tomado de la esquina superior izquierda
    borde = im.getpixel((0, 0))
    lienzo = Image.new("RGB", (lado, lado), borde)
    lienzo.paste(im, ((lado - im.width) // 2, (lado - im.height) // 2))
    return lienzo.resize((tam, tam), Image.LANCZOS)


def main():
    os.makedirs(ORIG, exist_ok=True)
    print("Procesamiento diferenciado (lote 2)\n" + "=" * 46)
    for uuid, nombre, grupo in LOTE:
        src = os.path.join(ASSETS, uuid + ".png")
        if not os.path.exists(src):
            print(f"  [!] falta {uuid}.png")
            continue
        im = Image.open(src)

        if grupo == "A":
            final = recortar_y_centrar(quitar_fondo(im)).resize((384, 384), Image.LANCZOS)
        elif grupo == "B":
            final = recortar_y_centrar(solo_componente_mayor(quitar_fondo(im))).resize((384, 384), Image.LANCZOS)
        else:  # C y D: sin recorte, solo optimizar
            final = cuadrar_con_fondo(im, 512)

        dst = os.path.join(ASSETS, nombre + ".png")
        final.save(dst, "PNG", optimize=True)
        shutil.move(src, os.path.join(ORIG, uuid + ".png"))
        kb_o = os.path.getsize(os.path.join(ORIG, uuid + ".png")) // 1024
        kb_n = os.path.getsize(dst) // 1024
        print(f"  [{grupo}] {nombre:22s} {kb_o:5d} KB -> {kb_n:4d} KB")
    print("=" * 46 + "\nListo. Originales en assets/originales/")


if __name__ == "__main__":
    main()
