# -*- coding: utf-8 -*-
"""
Lote 5: skins deportivas de Kimün + portadas de los 2 capítulos nuevos de Lenguaje.
Todas vienen con alfa transparente -> recorta al contenido y centra con margen.
  Skins    -> 384 px (como las demás skins de la tienda)
  Portadas -> 512 px (como las otras portadas de mapa)
Uso: python scripts/procesar-lote5.py
"""
import os, shutil
import numpy as np
from PIL import Image

ASSETS = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "assets"))
ORIG = os.path.join(ASSETS, "originales")
DESCARGAS = os.path.join(os.path.expanduser("~"), "Downloads")
MARGEN = 0.06

LOTE = [
    ("47fbe9d4-1516-4b01-b004-26932d213c51", "skin-kimun-karate",     384),
    ("ad593784-7106-4d03-b31f-b1d32697d9c1", "skin-kimun-futbol",     384),
    ("fc1e9ecc-8d86-4fdf-84a3-71d504f3469b", "skin-kimun-basquetbol", 384),
    ("ffa47677-3c4d-4cb0-9341-9d909351ee55", "skin-kimun-voleibol",   384),
    ("b97f4a01-351b-4c24-90f9-4f40a444c8b7", "skin-kimun-ciclismo",   384),
    ("408926b6-264d-4b6f-8014-533c4e6408d1", "skin-kimun-tenis",      384),
    ("a1032831-7785-458b-867d-3a0cc25cec68", "skin-kimun-skate",      384),
    ("c1529872-68ba-4aae-8e70-f6aa324fe54f", "portada-leng-lectura",  512),
    ("8b5ba331-9e7c-480d-9dcf-22d471ac9236", "portada-leng-escritura",512),
]


def recortar_y_centrar(im):
    im = im.convert("RGBA")
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
    print("Procesamiento lote 5\n" + "=" * 46)
    for uuid, nombre, tam in LOTE:
        src = os.path.join(DESCARGAS, uuid + ".png")
        if not os.path.exists(src):
            print(f"  [!] falta {uuid}.png"); continue
        final = recortar_y_centrar(Image.open(src)).resize((tam, tam), Image.LANCZOS)
        dst = os.path.join(ASSETS, nombre + ".png")
        final.save(dst, "PNG", optimize=True)
        shutil.copy2(src, os.path.join(ORIG, uuid + ".png"))
        print(f"  {nombre:24s} {os.path.getsize(src)//1024:5d} KB -> {os.path.getsize(dst)//1024:4d} KB ({tam}px)")
    print("=" * 46 + "\nListo. Originales en assets/originales/")


if __name__ == "__main__":
    main()
