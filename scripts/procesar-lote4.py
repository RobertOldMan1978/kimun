# -*- coding: utf-8 -*-
"""
Lote 4: skins de Kimün (recompensa y tienda) + villanos de Cálculo y Lenguaje.
Todas vienen con alfa transparente -> recorta al contenido y centra.
  Skins   -> 384 px (como kimun-historiador)
  Villanos-> 512 px (como villano-historia)
Uso: python scripts/procesar-lote4.py
"""
import os, shutil
import numpy as np
from PIL import Image

ASSETS = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "assets"))
ORIG = os.path.join(ASSETS, "originales")
DESCARGAS = os.path.join(os.path.expanduser("~"), "Downloads")
MARGEN = 0.06

LOTE = [
    ("9077c8db-4bde-4d22-8ced-2da812372336", "kimun-calculista",       384),
    ("fa729e6d-99ef-4bf9-9345-a44e6a794a46", "kimun-escritor",         384),
    ("d9ea9416-e8d9-4416-9419-4cf3c48a9637", "skin-kimun-astronauta",  384),
    ("f4c76189-2b37-4300-a3f6-d6ff004450f9", "skin-kimun-mago",        384),
    ("16485839-430c-4ff8-bd8b-5a232f327483", "skin-kimun-ninja",       384),
    ("42c11275-e20b-459b-95ab-d74e3880f573", "skin-kimun-superheroe",  384),
    ("6e8946eb-6822-4027-8b54-f5f6d311ab01", "villano-automata",       512),
    ("c887ef22-066f-4858-a32b-2bdf72453ff4", "villano-lenguaje",       512),
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
    print("Procesamiento lote 4\n" + "=" * 46)
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
