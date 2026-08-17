# -*- coding: utf-8 -*-
"""
Lote 6: portadas propias de los capitulos de Ciencias (4) e Historia (6).

A diferencia del lote 5, estas vienen en RGB con fondo blanco opaco (sin alfa).
El fondo exterior se detecta con relleno por inundacion desde las cuatro
esquinas (asi no se borran los blancos interiores del dibujo: delantales,
papeles, nubes) y se vuelve transparente con el borde suavizado.

  Portadas -> 512 px (como las otras portadas de mapa)
Uso: python scripts/procesar-lote6.py
"""
import os, shutil
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ASSETS = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "assets"))
ORIG = os.path.join(ASSETS, "originales")
DESCARGAS = os.path.join(os.path.expanduser("~"), "Downloads")
MARGEN = 0.06
TAM = 512
BLANCO_MIN = 200   # un pixel de fondo no baja de este gris
UMBRAL_FILL = 30   # tolerancia del relleno por inundacion

LOTE = [
    ("9ecdd413-e75e-4443-bce2-475dcfcf9121", "portada-cien-celula"),
    ("2acfe9c0-fa5a-4117-98d1-7d8becec1ca8", "portada-cien-cuerpo"),
    ("b40c9a12-be8b-443f-9df7-e0f8a947f91d", "portada-cien-electricidad"),
    ("66be4164-b4f7-455d-8982-eb49fd3deb40", "portada-cien-materia"),
    ("2ea10080-8fb1-413d-8ace-40a468e12573", "portada-hist-cap1"),
    ("950e0d93-f180-4d1c-8dd8-e7bbe349d9bf", "portada-hist-cap2"),
    ("55c2815d-b535-4a64-bf93-c489b4346377", "portada-hist-cap3"),
    ("335e8960-cdc8-4956-8fc9-e28c6ccde876", "portada-hist-cap4"),
    ("d1696400-f6b8-4f84-8928-9f7b8374fc37", "portada-hist-cap5"),
    ("1253e3a0-da65-4e0c-92bb-402532393048", "portada-hist-desafio"),
]


def quitar_fondo(im):
    """Vuelve transparente el fondo blanco conectado a los bordes."""
    im = im.convert("RGB")
    gris = im.convert("L")
    marca = gris.copy()
    for esquina in [(0, 0), (im.width - 1, 0), (0, im.height - 1), (im.width - 1, im.height - 1)]:
        if gris.getpixel(esquina) >= BLANCO_MIN:
            ImageDraw.floodfill(marca, esquina, 1, thresh=UMBRAL_FILL)
    fondo = (np.asarray(marca) == 1) & (np.asarray(gris) >= BLANCO_MIN)
    alfa = Image.fromarray(np.where(fondo, 0, 255).astype(np.uint8), "L")
    alfa = alfa.filter(ImageFilter.GaussianBlur(0.8))  # suaviza el filo del recorte
    out = im.convert("RGBA")
    out.putalpha(alfa)
    return out


def recortar_y_centrar(im):
    a = np.asarray(im)[:, :, 3]
    ys, xs = np.where(a > 10)
    if len(xs) == 0:
        return im
    im = im.crop((xs.min(), ys.min(), xs.max() + 1, ys.max() + 1))
    lado = max(im.width, im.height)
    m = int(lado * MARGEN)
    lienzo = Image.new("RGBA", (lado + 2 * m, lado + 2 * m), (0, 0, 0, 0))
    lienzo.paste(im, ((lienzo.width - im.width) // 2, (lienzo.height - im.height) // 2), im)
    return lienzo


def main():
    os.makedirs(ORIG, exist_ok=True)
    print("Procesamiento lote 6\n" + "=" * 52)
    for uuid, nombre in LOTE:
        src = os.path.join(DESCARGAS, uuid + ".png")
        if not os.path.exists(src):
            print(f"  [!] falta {uuid}.png"); continue
        final = recortar_y_centrar(quitar_fondo(Image.open(src))).resize((TAM, TAM), Image.LANCZOS)
        dst = os.path.join(ASSETS, nombre + ".png")
        final.save(dst, "PNG", optimize=True)
        shutil.copy2(src, os.path.join(ORIG, uuid + ".png"))
        print(f"  {nombre:26s} {os.path.getsize(src)//1024:5d} KB -> {os.path.getsize(dst)//1024:4d} KB ({TAM}px)")
    print("=" * 52 + "\nListo. Originales en assets/originales/")


if __name__ == "__main__":
    main()
