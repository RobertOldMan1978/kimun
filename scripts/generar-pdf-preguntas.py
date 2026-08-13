# -*- coding: utf-8 -*-
"""
KIMUN - Exporta el banco de preguntas a un PDF para revisión pedagógica.

Agrupa por OA, muestra cada pregunta con sus 4 opciones (marca la correcta),
la explicación (tip) y una casilla "Revisada: [   ]" para aprobar en papel.

Uso:
    python scripts/generar-pdf-preguntas.py [ruta_salida.pdf]

Requiere:  pip install fpdf2
"""
import json, os, sys
from pathlib import Path
from collections import OrderedDict
from fpdf import FPDF, XPos, YPos

RAIZ = Path(__file__).resolve().parent.parent
PREG = RAIZ / "contenido" / "historia-8basico" / "preguntas.json"
OA   = RAIZ / "contenido" / "historia-8basico" / "oa.json"


def fuente():
    pares = [("C:/Windows/Fonts/arial.ttf", "C:/Windows/Fonts/arialbd.ttf"),
             ("C:/Windows/Fonts/segoeui.ttf", "C:/Windows/Fonts/segoeuib.ttf")]
    for reg, bold in pares:
        if os.path.exists(reg) and os.path.exists(bold):
            return reg, bold
    raise SystemExit("No se encontró una fuente TTF (Arial/Segoe UI).")


def oa_num(c):
    try: return int(c.split("OA")[-1])
    except Exception: return 999


def main():
    preg = json.load(open(PREG, encoding="utf-8"))
    oa   = json.load(open(OA, encoding="utf-8"))
    oa_map = {o["codigo"]: o for o in oa["oa"]}
    reg, bold = fuente()

    pdf = FPDF(format="A4")
    pdf.set_auto_page_break(True, margin=15)
    pdf.add_font("U", "", reg)
    pdf.add_font("U", "B", bold)
    pdf.add_page()

    def mc(h, txt, style="", size=10, rgb=(0, 0, 0)):
        pdf.set_font("U", style, size); pdf.set_text_color(*rgb)
        pdf.multi_cell(0, h, txt, new_x=XPos.LMARGIN, new_y=YPos.NEXT)

    # Portada
    mc(10, "KIMÜN — Banco de preguntas", "B", 20)
    mc(8, "Historia, Geografía y Ciencias Sociales · 8° básico", "", 13)
    mc(8, f"Total: {len(preg['preguntas'])} preguntas · meta {preg.get('meta_preguntas_por_oa', 25)} por OA", "", 11)
    pdf.ln(2)
    mc(6, "Revisa cada pregunta y marca la casilla [ X ] de las que apruebes. "
          "La opción correcta va en negrita y con '(correcta)'.", "", 10, (80, 80, 80))

    grupos = OrderedDict()
    for q in preg["preguntas"]:
        grupos.setdefault(q["oa"], []).append(q)

    letras = "ABCD"
    for code in sorted(grupos, key=oa_num):
        o = oa_map.get(code, {})
        pdf.ln(4)
        mc(7, f"{code}  ·  {o.get('eje','')}  ({len(grupos[code])} preguntas)", "B", 13, (20, 20, 120))
        mc(5, o.get("texto", ""), "", 9, (90, 90, 90))
        for i, q in enumerate(grupos[code], 1):
            pdf.ln(1.5)
            mc(5.5, f"{i}. {q['pregunta']}", "B", 10.5)
            for k, op in enumerate(q["opciones"]):
                correcta = (k == q["correcta"])
                mc(5, f"    {letras[k]}) {op}{'  (correcta)' if correcta else ''}",
                   "B" if correcta else "", 10)
            mc(5, f"    Explicación: {q.get('tip','')}", "", 9, (70, 70, 70))
            mc(5, "    Revisada: [   ]", "", 9, (120, 120, 120))

    salida = Path(sys.argv[1]) if len(sys.argv) > 1 else (RAIZ / "dev" / "preguntas-historia-8basico.pdf")
    salida.parent.mkdir(parents=True, exist_ok=True)
    pdf.output(str(salida))
    print("PDF generado:", salida)


if __name__ == "__main__":
    main()
