# -*- coding: utf-8 -*-
"""
Procesamiento del lote 3: villano y skin de Ciencias + portadas de mapa.

  Grupo A (personaje, ya viene con alfa): recorta al contenido y centra.
        - villano de Ciencias  -> 512 px (como villano-historia)
        - skin Kimün científico -> 384 px (como kimun-historiador)
  Grupo C (portada con fondo crema): NO recorta, solo cuadra/optimiza a 512 px.

Lee los PNG desde la carpeta de Descargas, guarda el original en assets/originales/
y escribe el asset final en assets/ con su nombre definitivo.
Uso: python scripts/procesar-lote3.py
"""
import os, shutil
import numpy as np
from PIL import Image

ASSETS = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "assets"))
ORIG = os.path.join(ASSETS, "originales")
DESCARGAS = os.path.join(os.path.expanduser("~"), "Downloads")
MARGEN = 0.06

# (uuid, nombre_final, grupo, tam)
LOTE = [
    ("a2cad176-3232-4b39-897a-d9d5e8c7d38e", "villano-ciencias",     "A", 512),
    ("b87489cf-faeb-4e70-a53c-9b58164c3c37", "kimun-cientifico",     "A", 384),
    ("018a418f-9abc-42bf-ac98-89fd2c3ac926", "portada-mate-algebra", "C", 512),
    ("8881600e-141b-469b-91f9-4e114725f253", "portada-leng-textos",  "C", 512),
    ("dba10566-5a8b-47d1-a0f1-621082395150", "portada-leng-literarios", "C", 512),
]


def recortar_y_centrar(im):
    """Recorta al contenido (usando el alfa existente) y centra con margen."""
    im = im.convert("RGBA")
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
    im = im.convert("RGB")
    lado = max(im.width, im.height)
    borde = im.getpixel((0, 0))
    lienzo = Image.new("RGB", (lado, lado), borde)
    lienzo.paste(im, ((lado - im.width) // 2, (lado - im.height) // 2))
    return lienzo.resize((tam, tam), Image.LANCZOS)


def main():
    os.makedirs(ORIG, exist_ok=True)
    print("Procesamiento lote 3\n" + "=" * 46)
    for uuid, nombre, grupo, tam in LOTE:
        src = os.path.join(DESCARGAS, uuid + ".png")
        if not os.path.exists(src):
            print(f"  [!] falta {uuid}.png en Descargas")
            continue
        im = Image.open(src)
        if grupo == "A":
            final = recortar_y_centrar(im).resize((tam, tam), Image.LANCZOS)
        else:
            final = cuadrar_con_fondo(im, tam)
        dst = os.path.join(ASSETS, nombre + ".png")
        final.save(dst, "PNG", optimize=True)
        shutil.copy2(src, os.path.join(ORIG, uuid + ".png"))  # respaldo del original
        kb_o = os.path.getsize(src) // 1024
        kb_n = os.path.getsize(dst) // 1024
        print(f"  [{grupo}] {nombre:24s} {kb_o:5d} KB -> {kb_n:4d} KB ({tam}px)")
    print("=" * 46 + "\nListo. Originales respaldados en assets/originales/")


if __name__ == "__main__":
    main()
