# -*- coding: utf-8 -*-
"""
Lote 7: arte de Matematicas (campana + Jefe Final).

  villano-matematicas   -> 512 px  (villano "La Incognita", fondo blanco)
  kimun-matematico      -> 384 px  (skin "Vulpi Matematico", ya viene con alfa)
  portada-mate-numeros  -> 512 px  (medallon circular, fondo blanco)
  portada-mate-geometria-> 512 px
  portada-mate-datos    -> 512 px

Las imagenes con fondo blanco se recortan quitando el fondo por relleno de
inundacion desde las esquinas (mismo metodo del lote 6). La skin ya trae
transparencia, asi que se usa su propio canal alfa.

Uso: python scripts/procesar-lote7.py
"""
import os, shutil
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ASSETS = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "assets"))
ORIG = os.path.join(ASSETS, "originales")
VULPI = os.path.join(os.path.expanduser("~"), "Downloads", "Vulpi")
BLANCO_MIN = 200   # un pixel de fondo no baja de este gris
UMBRAL_FILL = 30   # tolerancia del relleno por inundacion

# (uuid, nombre, tam, margen, modo)
#   modo 'flood' = quitar fondo blanco;  modo 'alfa' = usar la transparencia que ya trae
LOTE = [
    ("ff9b7ce2-880e-4783-8e91-2fe5d65e0b78", "villano-matematicas",    512, 0.06, "flood"),
    ("ffd7c49f-2945-46a0-8ee5-b48500e2e6df", "kimun-matematico",       384, 0.06, "alfa"),
    ("bfdc6724-be17-433b-9490-604f5e2b7f0a", "portada-mate-numeros",   512, 0.02, "flood"),
    ("af65cf76-b89e-4463-9122-4761091af60d", "portada-mate-geometria", 512, 0.02, "flood"),
    ("bacaa323-4d13-4168-877e-ccc789b38863", "portada-mate-datos",     512, 0.02, "flood"),
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


def recortar_y_centrar(im, margen):
    a = np.asarray(im)[:, :, 3]
    ys, xs = np.where(a > 10)
    if len(xs) == 0:
        return im
    im = im.crop((xs.min(), ys.min(), xs.max() + 1, ys.max() + 1))
    lado = max(im.width, im.height)
    m = int(lado * margen)
    lienzo = Image.new("RGBA", (lado + 2 * m, lado + 2 * m), (0, 0, 0, 0))
    lienzo.paste(im, ((lienzo.width - im.width) // 2, (lienzo.height - im.height) // 2), im)
    return lienzo


def main():
    os.makedirs(ORIG, exist_ok=True)
    print("Procesamiento lote 7 (Matematicas)\n" + "=" * 52)
    for uuid, nombre, tam, margen, modo in LOTE:
        src = os.path.join(VULPI, uuid + ".png")
        if not os.path.exists(src):
            print(f"  [!] falta {uuid}.png"); continue
        im = Image.open(src)
        base = quitar_fondo(im) if modo == "flood" else im.convert("RGBA")
        final = recortar_y_centrar(base, margen).resize((tam, tam), Image.LANCZOS)
        dst = os.path.join(ASSETS, nombre + ".png")
        final.save(dst, "PNG", optimize=True)
        shutil.copy2(src, os.path.join(ORIG, uuid + ".png"))
        print(f"  {nombre:24s} {os.path.getsize(src)//1024:5d} KB -> {os.path.getsize(dst)//1024:4d} KB ({tam}px)")
    print("=" * 52 + "\nListo. Originales en assets/originales/")


if __name__ == "__main__":
    main()
