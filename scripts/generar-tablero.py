# -*- coding: utf-8 -*-
"""
KIMUN - Generador del tablero de desarrollo (Admin).

Genera dev/tablero.html con:
  - Bloqueo suave por contrasena (modo Admin).
  - Acordeon: al pinchar un OA se despliegan sus preguntas (enunciado +
    respuesta correcta) con una casilla para marcarlas como "revisadas".
  - Dos metricas por OA: COBERTURA (cantidad vs meta) y REVISADAS (aprobadas
    por un humano).
  - Boton "Exportar revisadas" (descarga revisadas.json) para luego aplicarlo
    con scripts/aplicar-revisadas.py.
  - Boton para volver al juego.

Uso:
    python scripts/generar-tablero.py

CONTRASENA: cambia CLAVE_ADMIN y vuelve a generar. Bloqueo suave, NO seguridad
real (sitio estatico).
"""

import json
from datetime import datetime
from pathlib import Path
from html import escape

CLAVE_ADMIN = "112358"   # <-- cambia aqui la contrasena del panel Admin

RAIZ = Path(__file__).resolve().parent.parent
CONTENIDO = RAIZ / "contenido"
SALIDA = RAIZ / "dev" / "tablero.html"

COLOR_EJE = {
    "Historia": "var(--gold)",
    "Formación ciudadana": "var(--pink)",
    "Geografía": "var(--cyan)",
}


def djb2(s):
    h = 5381
    for c in s:
        h = ((h * 33) + ord(c)) & 0xFFFFFFFF
    return h


def cargar_json(ruta):
    with open(ruta, encoding="utf-8") as f:
        return json.load(f)


def color_avance(pct):
    if pct <= 0:
        return "var(--dim)"
    if pct >= 100:
        return "var(--green)"
    return "var(--cyan)"


def etiqueta_estado(pct):
    if pct <= 0:
        return "Pendiente"
    if pct >= 100:
        return "Listo"
    return "En progreso"


def barra(pct, alto=10, color=None):
    pct = max(0, min(100, pct))
    col = color or color_avance(pct)
    return (
        f'<div class="track" style="height:{alto}px">'
        f'<div class="fill" style="width:{pct:.0f}%;background:{col}"></div>'
        f"</div>"
    )


def recolectar_asignaturas():
    asignaturas = []
    if not CONTENIDO.exists():
        return asignaturas
    for carpeta in sorted(CONTENIDO.iterdir()):
        oa_path = carpeta / "oa.json"
        if not oa_path.exists():
            continue
        oa_data = cargar_json(oa_path)
        preg_path = carpeta / "preguntas.json"
        preg_data = cargar_json(preg_path) if preg_path.exists() else {"preguntas": [], "meta_preguntas_por_oa": 8}
        asignaturas.append((carpeta.name, oa_data, preg_data))
    return asignaturas


def render_asignatura(oa_data, preg_data):
    meta = int(preg_data.get("meta_preguntas_por_oa", 8))
    preguntas = preg_data.get("preguntas", [])

    conteo = {}
    revis = {}
    preg_por_oa = {}
    for p in preguntas:
        oa = p.get("oa", "")
        conteo[oa] = conteo.get(oa, 0) + 1
        if p.get("revisada"):
            revis[oa] = revis.get(oa, 0) + 1
        preg_por_oa.setdefault(oa, []).append(p)

    oa_por_codigo = {oa["codigo"]: oa for oa in oa_data["oa"]}

    total_oa = len(oa_data["oa"])
    total_preg = len(preguntas)
    total_rev = sum(1 for p in preguntas if p.get("revisada"))
    oa_con_algo = sum(1 for oa in oa_data["oa"] if conteo.get(oa["codigo"], 0) > 0)
    oa_listos = sum(1 for oa in oa_data["oa"] if conteo.get(oa["codigo"], 0) >= meta)
    utiles = sum(min(conteo.get(oa["codigo"], 0), meta) for oa in oa_data["oa"])
    avance_global = (utiles / (meta * total_oa) * 100) if total_oa else 0
    rev_global = (total_rev / total_preg * 100) if total_preg else 0

    partes = []
    partes.append('<section class="asig">')
    partes.append(
        f'<div class="asig-head">'
        f'<div><h2>{escape(oa_data["asignatura"])}</h2>'
        f'<div class="sub">{escape(oa_data["nivel"])} · meta {meta} preguntas por OA</div></div>'
        f'<div class="global"><div class="pct">{avance_global:.0f}%</div>'
        f'<div class="pct-lbl">cobertura</div></div>'
        f"</div>"
    )
    partes.append(barra(avance_global, alto=14))
    partes.append(f'<div class="rev-lbl" style="margin-top:8px">🔍 Revisadas por ti: {total_rev}/{total_preg} ({rev_global:.0f}%)</div>')
    partes.append(barra(rev_global, alto=8, color="var(--pink)"))
    partes.append(
        '<div class="chips">'
        f'<span class="chip">📚 {total_preg} preguntas</span>'
        f'<span class="chip">🎯 {oa_con_algo}/{total_oa} OA con contenido</span>'
        f'<span class="chip ok">✅ {oa_listos} OA listos</span>'
        f'<span class="chip rev2">🔍 {total_rev} revisadas</span>'
        "</div>"
    )

    for u in oa_data["unidades"]:
        codigos = u["oa"]
        u_util = sum(min(conteo.get(c, 0), meta) for c in codigos)
        u_avance = (u_util / (meta * len(codigos)) * 100) if codigos else 0
        u_preg = sum(conteo.get(c, 0) for c in codigos)

        partes.append('<div class="unidad">')
        partes.append(
            f'<div class="u-head"><div class="u-tit">{escape(u["id"])} · {escape(u["titulo"])}</div>'
            f'<div class="u-pct">{u_avance:.0f}%</div></div>'
        )
        partes.append(barra(u_avance, alto=8))
        partes.append(f'<div class="u-sub">{u_preg} preguntas · {len(codigos)} OA</div>')

        partes.append('<div class="oa-list">')
        for c in codigos:
            oa = oa_por_codigo.get(c)
            if not oa:
                continue
            n = conteo.get(c, 0)
            r = revis.get(c, 0)
            pct = min(100, n / meta * 100) if meta else 0
            rpct = (r / n * 100) if n else 0
            eje = oa.get("eje", "")
            col_eje = COLOR_EJE.get(eje, "var(--violet)")

            filas = []
            for j, q in enumerate(preg_por_oa.get(c, []), 1):
                try:
                    resp = q["opciones"][q["correcta"]]
                except Exception:
                    resp = "(respuesta no disponible)"
                qid = q.get("id", "")
                rev = "1" if q.get("revisada") else "0"
                filas.append(
                    f'<div class="pq"><span class="pq-n">{j}.</span>'
                    f'<div class="pq-body"><div class="pq-q">{escape(q.get("pregunta",""))}</div>'
                    f'<div class="pq-a">✔ {escape(resp)}</div></div>'
                    f'<label class="pq-check" title="Marcar como revisada">'
                    f'<input type="checkbox" data-id="{escape(qid)}" data-rev="{rev}"></label>'
                    "</div>"
                )
            panel = f'<div class="oa-preguntas">{"".join(filas)}</div>' if filas else ""
            abrible = " abrible" if filas else ""

            partes.append(
                f'<div class="oa{abrible}">'
                f'<div class="oa-top">'
                f'<span class="caret">{"▸" if filas else ""}</span>'
                f'<span class="oa-cod" style="color:{col_eje}">{escape(c)}</span>'
                f'<span class="oa-badge" style="border-color:{col_eje};color:{col_eje}">{escape(eje)}</span>'
                f'<span class="oa-count">{n}/{meta}</span>'
                f'<span class="oa-estado" style="color:{color_avance(pct)}">{etiqueta_estado(pct)}</span>'
                f"</div>"
                f'<div class="oa-txt">{escape(oa["texto"])}</div>'
                f'{barra(pct, alto=7)}'
                f'<div class="rev-line"><span class="rev-lbl">🔍 revisadas {r}/{n}</span>{barra(rpct, alto=5, color="var(--pink)")}</div>'
                f'{panel}'
                "</div>"
            )
        partes.append("</div>")
        partes.append("</div>")

    partes.append("</section>")
    return "\n".join(partes)


def generar():
    asignaturas = recolectar_asignaturas()
    cuerpo = "\n".join(render_asignatura(oa, pg) for _, oa, pg in asignaturas)
    if not cuerpo:
        cuerpo = '<p class="vacio">Aún no hay contenido en la carpeta <code>contenido/</code>.</p>'
    marca = datetime.now().strftime("%d-%m-%Y %H:%M")
    hash_clave = str(djb2(CLAVE_ADMIN))

    css = """
:root{
  --bg1:#140f33; --bg2:#2a1b5e; --panel:#1e1747; --panel2:#271f56;
  --gold:#ffc93c; --cyan:#4dd8ff; --green:#3ee089; --pink:#ff4d8d; --violet:#8f6bff;
  --txt:#f3f0ff; --dim:#a89fd6; --r:16px;
}
*{margin:0;padding:0;box-sizing:border-box}
body{
  font-family:'Nunito',sans-serif;color:var(--txt);min-height:100vh;
  background:radial-gradient(1200px 800px at 70% -10%, #3b2a7a 0%, transparent 55%),
             linear-gradient(160deg,var(--bg1),var(--bg2));
  padding:20px 16px 60px;
}
.wrap{max-width:900px;margin:0 auto}
h1,h2,.disp{font-family:'Titan One',cursive;letter-spacing:.5px}
.topbar{display:flex;justify-content:space-between;align-items:center;gap:12px;margin-bottom:14px;flex-wrap:wrap}
.volver{display:inline-flex;align-items:center;gap:6px;background:var(--panel2);border:1px solid #ffffff18;
  color:var(--txt);text-decoration:none;font-weight:900;font-size:13px;padding:9px 14px;border-radius:12px}
.tb-right{display:flex;gap:8px;align-items:center;flex-wrap:wrap}
.rev-count{color:var(--dim);font-weight:800;font-size:12px}
.exportar{background:var(--panel2);border:1px solid #4dd8ff55;color:var(--cyan);font-weight:800;font-size:12px;padding:8px 12px;border-radius:12px;cursor:pointer}
.salir{background:none;border:1px solid #ffffff22;color:var(--dim);font-weight:800;font-size:12px;padding:8px 12px;border-radius:12px;cursor:pointer}
.top{text-align:center;margin-bottom:6px}
.top h1{font-size:28px;color:var(--gold)}
.top .lema{color:var(--dim);font-weight:800;margin-top:2px;font-size:14px}
.gen{text-align:center;color:var(--dim);font-size:12px;margin-bottom:22px}
.asig{background:var(--panel);border:1px solid #ffffff18;border-radius:var(--r);padding:20px;margin-bottom:24px;box-shadow:0 10px 30px #0004}
.asig-head{display:flex;justify-content:space-between;align-items:center;gap:16px;margin-bottom:12px}
.asig-head h2{font-size:20px}
.sub{color:var(--dim);font-weight:800;font-size:13px;margin-top:2px}
.global{text-align:center;flex-shrink:0}
.global .pct{font-family:'Titan One',cursive;font-size:38px;line-height:1;color:var(--cyan)}
.pct-lbl{color:var(--dim);font-size:12px;font-weight:800;text-transform:uppercase}
.track{background:#00000038;border-radius:99px;overflow:hidden;width:100%}
.fill{height:100%;border-radius:99px;transition:width .4s}
.chips{display:flex;flex-wrap:wrap;gap:8px;margin:14px 0 6px}
.chip{background:var(--panel2);border:1px solid #ffffff14;border-radius:99px;padding:6px 12px;font-weight:800;font-size:13px}
.chip.ok{color:var(--green)} .chip.rev2{color:var(--pink)}
.unidad{background:var(--panel2);border-radius:14px;padding:14px 14px 6px;margin-top:16px}
.u-head{display:flex;justify-content:space-between;align-items:center;margin-bottom:8px}
.u-tit{font-weight:900;font-size:15px}
.u-pct{font-family:'Titan One',cursive;color:var(--gold);font-size:18px}
.u-sub{color:var(--dim);font-size:12px;font-weight:800;margin:6px 0 10px}
.oa-list{display:flex;flex-direction:column;gap:10px;padding-bottom:8px}
.oa{background:#00000026;border-radius:10px;padding:10px 12px}
.oa.abrible{cursor:pointer}
.oa.abrible:hover{background:#00000038}
.oa-top{display:flex;align-items:center;gap:8px;flex-wrap:wrap;margin-bottom:6px}
.caret{color:var(--dim);font-size:12px;width:12px;display:inline-block;transition:transform .15s}
.oa.abierto .caret{transform:rotate(90deg);color:var(--gold)}
.oa-cod{font-weight:900;font-size:13px}
.oa-badge{font-size:11px;font-weight:800;border:1px solid;border-radius:99px;padding:1px 8px}
.oa-count{margin-left:auto;font-weight:900;font-size:13px;color:var(--txt)}
.oa-estado{font-size:12px;font-weight:800}
.oa-txt{color:var(--dim);font-size:12.5px;line-height:1.35;margin-bottom:8px}
.rev-line{margin-top:7px}
.rev-lbl{font-size:11px;font-weight:800;color:var(--pink);display:block;margin-bottom:3px}
.oa-preguntas{margin-top:10px;border-top:1px dashed #ffffff1f;padding-top:8px;display:none;flex-direction:column;gap:2px}
.oa.abierto .oa-preguntas{display:flex}
.pq{display:flex;gap:8px;align-items:flex-start;padding:7px 4px;border-bottom:1px solid #ffffff0f}
.pq:last-child{border:none}
.pq-n{color:var(--dim);font-weight:900;font-size:12px;min-width:22px;text-align:right}
.pq-body{flex:1}
.pq-q{font-weight:800;font-size:13px;line-height:1.3}
.pq-a{color:var(--green);font-weight:800;font-size:12.5px;margin-top:2px}
.pq-check{display:flex;align-items:center;padding-left:6px}
.pq-check input{width:20px;height:20px;accent-color:var(--green);cursor:pointer}
.vacio{text-align:center;color:var(--dim);padding:40px}
.leyenda{display:flex;gap:16px;justify-content:center;color:var(--dim);font-size:12px;font-weight:800;margin-top:6px;flex-wrap:wrap}
.dot{display:inline-block;width:10px;height:10px;border-radius:50%;margin-right:5px;vertical-align:middle}
.gate{position:fixed;inset:0;z-index:100;display:flex;align-items:center;justify-content:center;padding:20px;
  background:radial-gradient(1000px 700px at 50% 0%, #3b2a7a 0%, transparent 60%), linear-gradient(160deg,var(--bg1),var(--bg2))}
.gate-box{background:var(--panel);border:1px solid #ffffff1f;border-radius:20px;padding:28px 24px;max-width:340px;width:100%;text-align:center;box-shadow:0 20px 50px #0006}
.gate-ic{font-size:48px}
.gate-box h2{font-size:24px;color:var(--gold);margin-top:6px}
.gate-box p{color:var(--dim);font-weight:800;margin:6px 0 16px;font-size:14px}
.gate-box input{width:100%;padding:14px;border-radius:14px;border:2px solid #ffffff1f;background:#00000040;color:var(--txt);
  font-family:'Nunito';font-weight:800;font-size:16px;outline:none;text-align:center}
.gate-box input:focus{border-color:var(--cyan)}
.gate-box button{width:100%;margin-top:12px;padding:14px;border:none;border-radius:14px;cursor:pointer;
  font-family:'Titan One';font-size:16px;color:#2a1400;background:linear-gradient(180deg,var(--gold),#ff9d3c)}
.gate-err{color:var(--pink);font-weight:800;font-size:13px;min-height:18px;margin-top:10px}
.gate-volver{display:inline-block;margin-top:8px;color:var(--dim);font-weight:800;font-size:13px;text-decoration:none}
"""

    js = """
(function(){
  var HASH = __HASH__;
  function djb2(s){var h=5381;for(var i=0;i<s.length;i++){h=((h*33)+s.charCodeAt(i))>>>0;}return h;}
  var gate=document.getElementById('gate');
  var panel=document.getElementById('panel');
  function abrir(){gate.style.display='none';panel.style.display='block';}
  if(sessionStorage.getItem('kimun_admin_ok')==='1'){abrir();}
  function intentar(){
    var v=document.getElementById('gpass').value;
    if(djb2(v)===HASH){sessionStorage.setItem('kimun_admin_ok','1');abrir();}
    else{document.getElementById('gerr').textContent='Contraseña incorrecta';
      document.getElementById('gpass').value='';}
  }
  document.getElementById('gbtn').onclick=intentar;
  document.getElementById('gpass').addEventListener('keydown',function(e){if(e.key==='Enter')intentar();});
  var salir=document.getElementById('salir');
  if(salir)salir.onclick=function(){sessionStorage.removeItem('kimun_admin_ok');location.reload();};

  // Acordeon de OA (no togglear si el clic ocurre dentro del panel de preguntas)
  document.querySelectorAll('.oa.abrible').forEach(function(oa){
    oa.addEventListener('click',function(e){
      if(e.target.closest('.oa-preguntas'))return;
      oa.classList.toggle('abierto');
    });
  });

  // Revisadas: casillas + exportar (persisten en el navegador)
  var LS='kimun_revisadas';
  var ov={};
  try{ov=JSON.parse(localStorage.getItem(LS)||'{}');}catch(e){ov={};}
  function updateCount(){
    var n=document.querySelectorAll('.pq-check input:checked').length;
    var t=document.querySelectorAll('.pq-check input').length;
    var el=document.getElementById('revCount');
    if(el)el.textContent='🔍 '+n+'/'+t+' marcadas';
  }
  document.querySelectorAll('.pq-check input').forEach(function(cb){
    var id=cb.dataset.id, jsonRev=cb.dataset.rev==='1';
    cb.checked=(id in ov)?ov[id]:jsonRev;
    cb.addEventListener('click',function(e){e.stopPropagation();});
    cb.addEventListener('change',function(){ov[id]=cb.checked;localStorage.setItem(LS,JSON.stringify(ov));updateCount();});
  });
  var exp=document.getElementById('exportar');
  if(exp)exp.onclick=function(){
    var ids=[];
    document.querySelectorAll('.pq-check input:checked').forEach(function(cb){ids.push(cb.dataset.id);});
    var blob=new Blob([JSON.stringify({revisadas:ids},null,2)],{type:'application/json'});
    var a=document.createElement('a');a.href=URL.createObjectURL(blob);a.download='revisadas.json';
    document.body.appendChild(a);a.click();a.remove();
  };
  updateCount();
})();
""".replace("__HASH__", hash_clave)

    html = (
        '<!DOCTYPE html>\n<html lang="es">\n<head>\n'
        '<meta charset="UTF-8">\n'
        '<meta name="viewport" content="width=device-width, initial-scale=1.0">\n'
        '<title>KIMÜN · Tablero de desarrollo</title>\n'
        '<link rel="preconnect" href="https://fonts.googleapis.com">\n'
        '<link href="https://fonts.googleapis.com/css2?family=Titan+One&family=Nunito:wght@600;800;900&display=swap" rel="stylesheet">\n'
        "<style>" + css + "</style>\n</head>\n<body>\n"
        '<div class="gate" id="gate">\n'
        '  <div class="gate-box">\n'
        '    <div class="gate-ic">🔒</div>\n'
        '    <h2>Modo Admin</h2>\n'
        '    <p>Ingresa la contraseña para ver el panel</p>\n'
        '    <input id="gpass" type="password" placeholder="Contraseña" autocomplete="off">\n'
        '    <button id="gbtn">Entrar</button>\n'
        '    <div class="gate-err" id="gerr"></div>\n'
        '    <a class="gate-volver" href="../index.html">← Volver al juego</a>\n'
        '  </div>\n'
        '</div>\n'
        '<div class="wrap" id="panel" style="display:none">\n'
        '  <div class="topbar">\n'
        '    <a class="volver" href="../index.html">← Volver al juego</a>\n'
        '    <div class="tb-right">\n'
        '      <span class="rev-count" id="revCount"></span>\n'
        '      <button class="exportar" id="exportar">⬇ Exportar revisadas</button>\n'
        '      <button class="salir" id="salir">🔒 Bloquear</button>\n'
        '    </div>\n'
        '  </div>\n'
        '  <div class="top">\n'
        '    <h1>KIMÜN · Tablero</h1>\n'
        '    <div class="lema">Panel de desarrollo · avance por materia y OA</div>\n'
        '  </div>\n'
        '  <div class="gen">Generado el ' + marca + ' · <code>python scripts/generar-tablero.py</code></div>\n'
        + cuerpo +
        '\n  <div class="leyenda">\n'
        '    <span><span class="dot" style="background:var(--dim)"></span>Pendiente</span>\n'
        '    <span><span class="dot" style="background:var(--cyan)"></span>En progreso</span>\n'
        '    <span><span class="dot" style="background:var(--green)"></span>Listo (meta cumplida)</span>\n'
        '    <span><span class="dot" style="background:var(--pink)"></span>Revisadas por ti</span>\n'
        '  </div>\n'
        '  <div class="gen" style="margin-top:18px">Pincha un OA para ver sus preguntas. Marca la casilla de las que apruebes y usa "Exportar revisadas".</div>\n'
        '</div>\n'
        "<script>" + js + "</script>\n"
        "</body>\n</html>\n"
    )

    SALIDA.parent.mkdir(parents=True, exist_ok=True)
    with open(SALIDA, "w", encoding="utf-8") as f:
        f.write(html)
    print(f"Tablero generado: {SALIDA}")


if __name__ == "__main__":
    generar()
