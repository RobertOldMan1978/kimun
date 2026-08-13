# -*- coding: utf-8 -*-
"""
KIMUN - Exporta el banco de preguntas a un PDF para revisión pedagógica.

Agrupa por OA, muestra cada pregunta con sus 4 opciones (marca la correcta),
la explicación (tip) y una casilla "Revisada: [   ]" para aprobar en papel.

Uso:
    # Una asignatura (banco completo):
    python scripts/generar-pdf-preguntas.py <carpeta-asignatura> [salida.pdf]
    #   ej: python scripts/generar-pdf-preguntas.py ciencias-8basico

    # Todas las asignaturas con preguntas SIN revisar (un PDF por asignatura):
    python scripts/generar-pdf-preguntas.py --sin-revisar

    # Sin argumentos: banco completo de Historia (compatibilidad).
    python scripts/generar-pdf-preguntas.py [salida.pdf]

Requiere:  pip install fpdf2
"""
import json, os, sys
from pathlib import Path
from collections import OrderedDict
from fpdf import FPDF, XPos, YPos

RAIZ = Path(__file__).resolve().parent.parent
CONTENIDO = RAIZ / "contenido"


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


# Glifos que la fuente Arial no trae; se sustituyen SOLO para el PDF de revisión.
# En el juego (navegador) se muestran correctamente, así que el JSON no se toca.
_SUBS = {ord(a): b for a, b in zip("₀₁₂₃₄₅₆₇₈₉", "0123456789")}


def _pdf_safe(s):
    return (s or "").translate(_SUBS).replace("∛", "raíz cúbica de ")


def carpetas_asignaturas():
    """Carpetas de contenido/ (ignora las que empiezan con '_')."""
    return sorted(d.name for d in CONTENIDO.iterdir()
                  if d.is_dir() and not d.name.startswith("_")
                  and (d / "preguntas.json").exists())


def generar_pdf(carpeta, salida, solo_sin_revisar=False):
    base = CONTENIDO / carpeta
    preg = json.load(open(base / "preguntas.json", encoding="utf-8"))
    oa_path = base / "oa.json"
    oa = json.load(open(oa_path, encoding="utf-8")) if oa_path.exists() else {"oa": []}
    oa_map = {o["codigo"]: o for o in oa.get("oa", [])}

    preguntas = preg["preguntas"]
    if solo_sin_revisar:
        preguntas = [q for q in preguntas if not q.get("revisada", False)]
    if not preguntas:
        return None  # nada que exportar

    reg, bold = fuente()
    pdf = FPDF(format="A4")
    pdf.set_auto_page_break(True, margin=15)
    pdf.add_font("U", "", reg)
    pdf.add_font("U", "B", bold)
    pdf.add_page()

    def mc(h, txt, style="", size=10, rgb=(0, 0, 0)):
        pdf.set_font("U", style, size); pdf.set_text_color(*rgb)
        pdf.multi_cell(0, h, txt, new_x=XPos.LMARGIN, new_y=YPos.NEXT)

    asignatura = preg.get("asignatura", oa.get("asignatura", carpeta))
    nivel = preg.get("nivel", oa.get("nivel", ""))

    # Portada
    mc(10, "KIMÜN — Banco de preguntas", "B", 20)
    mc(8, f"{asignatura} · {nivel}", "", 13)
    etiqueta = "SIN REVISAR" if solo_sin_revisar else "banco completo"
    mc(8, f"Total: {len(preguntas)} preguntas ({etiqueta}) · meta {preg.get('meta_preguntas_por_oa', 25)} por OA", "", 11)
    pdf.ln(2)
    mc(6, "Revisa cada pregunta y marca la casilla [ X ] de las que apruebes. "
          "La opción correcta va en negrita y con '(correcta)'.", "", 10, (80, 80, 80))

    grupos = OrderedDict()
    for q in preguntas:
        grupos.setdefault(q["oa"], []).append(q)

    letras = "ABCD"
    for code in sorted(grupos, key=oa_num):
        o = oa_map.get(code, {})
        pdf.ln(4)
        mc(7, f"{code}  ·  {o.get('eje','')}  ({len(grupos[code])} preguntas)", "B", 13, (20, 20, 120))
        mc(5, o.get("texto", ""), "", 9, (90, 90, 90))
        for i, q in enumerate(grupos[code], 1):
            pdf.ln(1.5)
            mc(5.5, f"{i}. {_pdf_safe(q['pregunta'])}", "B", 10.5)
            for k, op in enumerate(q["opciones"]):
                correcta = (k == q["correcta"])
                mc(5, f"    {letras[k]}) {_pdf_safe(op)}{'  (correcta)' if correcta else ''}",
                   "B" if correcta else "", 10)
            mc(5, f"    Explicación: {_pdf_safe(q.get('tip',''))}", "", 9, (70, 70, 70))
            mc(5, "    Revisada: [   ]", "", 9, (120, 120, 120))

    salida.parent.mkdir(parents=True, exist_ok=True)
    pdf.output(str(salida))
    return len(preguntas)


def main():
    args = sys.argv[1:]

    # Modo: todas las asignaturas con preguntas SIN revisar
    if args and args[0] == "--sin-revisar":
        generados = []
        for carpeta in carpetas_asignaturas():
            salida = RAIZ / "dev" / f"preguntas-sin-revisar-{carpeta}.pdf"
            n = generar_pdf(carpeta, salida, solo_sin_revisar=True)
            if n:
                generados.append((carpeta, n, salida))
        if not generados:
            print("No hay preguntas sin revisar en ninguna asignatura.")
            return
        for carpeta, n, salida in generados:
            print(f"PDF generado: {salida}  ({n} preguntas sin revisar)")
        return

    # Modo: una asignatura concreta (o Historia por compatibilidad)
    if args and (CONTENIDO / args[0]).is_dir():
        carpeta = args[0]
        salida = Path(args[1]) if len(args) > 1 else (RAIZ / "dev" / f"preguntas-{carpeta}.pdf")
    else:
        carpeta = "historia-8basico"
        salida = Path(args[0]) if args else (RAIZ / "dev" / "preguntas-historia-8basico.pdf")

    n = generar_pdf(carpeta, salida)
    print("PDF generado:", salida, f"({n} preguntas)")


if __name__ == "__main__":
    main()
