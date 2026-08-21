# Camino de aprendizaje de Matemáticas — Plan 1 (cimientos + Unidad 1: Números)

> **Para el trabajador agéntico:** SUB-SKILL REQUERIDA: usa
> superpowers:subagent-driven-development (recomendada) o
> superpowers:executing-plans para ejecutar este plan tarea por tarea. Los pasos
> usan casillas (`- [ ]`) para el seguimiento.

**Objetivo:** convertir Matemáticas en una campaña con un **camino de aprendizaje real**
—mini-clases guiadas con diagramas interactivos dibujados en SVG y práctica que mide
dominio— entregando la **Unidad 1 (Números, OA01–05)** jugable de punta a punta, con el
motor de lecciones y el catálogo de diagramas base ya construidos para reusar.

**Arquitectura:** motor de lecciones por bloques data-driven (enfoque A del spec). Una
lección es datos (`contenido/matematicas-8basico/lecciones.json`); el motor
(`scr-leccion` + `abrirLeccion`/`renderBloque`/`avanzarBloque`) recorre bloques tipados;
los bloques `diagrama` invocan widgets del catálogo `DIAGRAMAS[kind]`; el bloque
`práctica` reusa el motor de quiz existente con un flag `Q.leccion`. Matemáticas se
suma a `CAMPAÑAS` como campaña `'mate'`; completar lecciones de Números desbloquea los
niveles del Reto de Cálculo y registra dominio por OA vía el pipeline existente
(`registrarOA`/`kimun_dominio`).

**Tech stack:** un único `index.html` (HTML + CSS + JS vanilla, sin frameworks), SVG
inline sin librerías, contenido en JSON cargado con `fetch`, Supabase para dominio (ya
existe). Sin framework de tests: **la verificación es en el navegador**
(`preview_start` con la configuración `vulpo` de `.claude/launch.json` +
`read_page`/`javascript_tool`/`read_console_messages`), como en todo el proyecto.

**Regla de commits del proyecto:** NO se commitea hasta que Roberto dé la "orden 66".
Por eso cada tarea termina en un **checkpoint de verificación en navegador**, no en un
commit. No ejecutes `git commit` en ninguna tarea.

**Planes de seguimiento (fuera de este plan):** Cap 2 (Álgebra y funciones, widgets
`algebra`/`funcion`/`plano`), Cap 3 (Geometría, widgets `triangulo`/`transformacion`/
`solido`), Cap 4 (Prob. y estadística, widgets `cajon`/`barras`/`arbol`), y el Jefe
Final de la campaña (villano "La Incógnita" + skin "Vulpi Matemático" + insignia
"Maestro de las Matemáticas"). Cada uno reusa el motor construido aquí.

---

## Estructura de archivos

- **Modificar** `index.html`:
  - Markup: nueva `<section class="screen" id="scr-leccion">` (Tarea 1).
  - Estado: `S.mateLecciones` + persistencia en `guardar()`/`cargar()` (Tarea 1).
  - Nuevo bloque JS: registro `DIAGRAMAS` + `montarDiagrama()` + widgets `recta`,
    `fracciones`, `potencias` (Tareas 2–3).
  - Nuevo bloque JS: motor de lecciones `abrirLeccion`/`renderBloque`/`avanzarBloque`/
    `terminarLeccion` + carga de `lecciones.json` (Tareas 4–6).
  - Quiz: rama `Q.leccion` en `pintaPregunta` y `avanzar` (Tarea 5).
  - Datos: entrada `'mate'` en `CAMPAÑAS`; ramal de campaña (capítulos = lecciones) en
    `renderCampaña`; routing del módulo Matemáticas del menú; `nivelCalcDesbloqueado`
    leyendo `S.mateLecciones` (Tarea 7).
- **Crear** `contenido/matematicas-8basico/lecciones.json`: las 5 lecciones de Números
  (Tarea 6).
- **Modificar** `profesor.html`: ajustar el aviso "Matemáticas no se mide" (Tarea 8).

Todo el JS nuevo se agrupa por responsabilidad: el **catálogo de diagramas** es un bloque
autocontenido (cada widget recibe `params` + nodo de montaje y no depende del resto del
juego); el **motor de lecciones** es otro bloque que solo conoce el catálogo y el quiz.

---

## Tarea 1: Pantalla `scr-leccion` y estado de progreso

**Archivos:**
- Modificar `index.html` (markup tras `scr-calc-res`, ~línea 608; estado `S`;
  `guardar()` ~1515; `cargar()` ~1522)

- [ ] **Paso 1: Agregar el markup de la pantalla**

Tras el cierre de la sección `scr-calc-res` (buscar `id="scr-calc-res"` y su `</section>`),
insertar:

```html
  <!-- ============ LECCIÓN (camino de aprendizaje Matemáticas) ============ -->
  <section class="screen" id="scr-leccion">
    <div class="lec-top">
      <button id="lecSalir" class="btn-ghost">← Salir</button>
      <div class="lec-prog"><div id="lecProgBar"></div></div>
    </div>
    <h2 id="lecTitulo" class="lec-titulo"></h2>
    <div id="lecCuerpo" class="lec-cuerpo"></div>
    <button id="lecCont" class="btn-primary lec-cont">Continuar</button>
  </section>
```

- [ ] **Paso 2: Agregar CSS mínimo de la pantalla**

Junto al resto del CSS (antes de `</style>`), agregar:

```css
#scr-leccion{padding:16px;display:none;flex-direction:column;gap:12px}
.lec-top{display:flex;align-items:center;gap:10px}
.lec-prog{flex:1;height:8px;background:#241a44;border-radius:6px;overflow:hidden}
#lecProgBar{height:100%;width:0;background:linear-gradient(90deg,var(--cyan),var(--violet));transition:width .3s}
.lec-titulo{font-family:'Titan One',sans-serif;font-size:20px;margin:2px 0}
.lec-cuerpo{background:#241a44;border:1px solid #3a2f60;border-radius:16px;padding:16px;min-height:220px}
.lec-cuerpo p{font-size:15px;line-height:1.5}
.lec-cuerpo img{max-width:100%;border-radius:12px;display:block;margin:0 auto}
.lec-diag{width:100%;overflow-x:auto}
.lec-ejemplo-paso{opacity:.35;transition:opacity .3s;margin:6px 0;font-size:15px}
.lec-ejemplo-paso.on{opacity:1}
.lec-cont{width:100%}
```

Nota: `go(id)` alterna `display` por la clase `.screen`; para que el `flex` funcione,
`#scr-leccion.screen` debe respetar el patrón existente. Verifica cómo `scr-calc` maneja
`display` y replica (probablemente `.screen{display:none}` y `.screen.on{display:flex}` o
similar — usa el mismo patrón que las otras secciones para no romper `go()`).

- [ ] **Paso 3: Inicializar el estado de progreso**

En la definición del objeto `S` (estado del juego), agregar la propiedad:

```js
mateLecciones:{},   // { 'ma-oa01': true, ... } lecciones de Matemáticas completadas
```

- [ ] **Paso 4: Persistir en `guardar()`**

En `guardar()` (línea ~1515-1521), agregar `mateLecciones:S.mateLecciones` al objeto que
se serializa (junto a `calc:S.calc, curso:S.curso, ...`):

```js
  calc:S.calc, curso:S.curso, alumno:S.alumno, maestro:S.maestro,
  mateLecciones:S.mateLecciones}));sincronizarXP();}catch(e){}}
```

- [ ] **Paso 5: Restaurar en `cargar()`**

En `cargar()` (tras la línea que restaura `S.calc`, ~1528), agregar:

```js
 if(d.mateLecciones&&typeof d.mateLecciones==='object')S.mateLecciones=d.mateLecciones;
```

- [ ] **Paso 6: Verificar en el navegador**

Levanta el preview (`preview_start` con `{name:"vulpo"}`), abre el juego. En la consola
(`javascript_tool`):

```js
S.mateLecciones                 // -> {} (objeto vacío)
S.mateLecciones['x']=true; guardar(); cargar(); S.mateLecciones  // -> {x:true} tras recargar
document.getElementById('scr-leccion') !== null                  // -> true
```

Esperado: `S.mateLecciones` existe, persiste tras `guardar()`+`cargar()`, y la sección
existe oculta. Sin errores nuevos en `read_console_messages` (los 404 de portadas/audio
son benignos y preexistentes).

---

## Tarea 2: Catálogo de diagramas — motor de montaje + widget `recta`

**Archivos:**
- Modificar `index.html` (nuevo bloque JS; ubícalo cerca del Reto de Cálculo, ~línea 1247,
  antes o después de la sección de cálculo)

- [ ] **Paso 1: Crear el registro y el montador**

Agregar el bloque:

```js
/* ================= CATÁLOGO DE DIAGRAMAS (SVG interactivo) =================
   Cada widget: DIAGRAMAS[kind](params, nodo) dibuja SVG dentro de `nodo`.
   Sin librerías. Limpia sus propios listeners al re-montar (nodo.innerHTML=''). */
const NS='http://www.w3.org/2000/svg';
function svgEl(tag,attrs){const e=document.createElementNS(NS,tag);
 for(const k in attrs)e.setAttribute(k,attrs[k]);return e;}
const DIAGRAMAS={};
function montarDiagrama(kind,params,nodo){
 nodo.innerHTML=''; nodo.className='lec-diag';
 const fn=DIAGRAMAS[kind];
 if(!fn){nodo.textContent='(diagrama no disponible)';return;}
 try{fn(params||{},nodo);}catch(e){console.error('Diagrama',kind,e);nodo.textContent='';}
}
```

- [ ] **Paso 2: Implementar el widget `recta`**

Agregar (mismo bloque):

```js
// recta numérica: marca un punto (arrastrable) e intervalos con círculo abierto/cerrado.
// params: {min=-6,max=6, marca:number, interactivo:bool, intervalo:{desde,tipo:'>'|'>='|...}}
DIAGRAMAS.recta=function(p,nodo){
 const min=p.min??-6,max=p.max??6,x0=24,x1=336,y=54;
 const svg=svgEl('svg',{viewBox:'0 0 360 90',role:'img','aria-label':'Recta numérica'});
 svg.style.touchAction='none';
 const xOf=v=>x0+(v-min)/(max-min)*(x1-x0);
 svg.appendChild(svgEl('line',{x1:x0,y1:y,x2:x1,y2:y,stroke:'#5a4b8f','stroke-width':2}));
 for(let v=min;v<=max;v++){
  svg.appendChild(svgEl('line',{x1:xOf(v),y1:y-4,x2:xOf(v),y2:y+4,stroke:'#5a4b8f','stroke-width':1.5}));
  const t=svgEl('text',{x:xOf(v),y:y+22,'text-anchor':'middle',fill:'#a99fd0','font-size':9});
  t.textContent=v; svg.appendChild(t);
 }
 // intervalo opcional (para inecuaciones): sombra + círculo abierto/cerrado
 if(p.intervalo){const it=p.intervalo, cerrado=/=/.test(it.tipo||''), haciaDer=/>/.test(it.tipo||'');
  const xd=xOf(it.desde), xf=haciaDer?x1:x0;
  svg.appendChild(svgEl('line',{x1:xd,y1:y,x2:xf,y2:y,stroke:'#3ee089','stroke-width':4}));
  svg.appendChild(svgEl('circle',{cx:xd,cy:y,r:6,fill:cerrado?'#3ee089':'#241a44',stroke:'#3ee089','stroke-width':2}));
 }
 // marcador (arrastrable si interactivo)
 let cur=p.marca??0;
 const knob=svgEl('circle',{cy:y,r:11,fill:'#8f6bff',stroke:'#4dd8ff','stroke-width':2.5});
 const lbl=svgEl('text',{y:y-24,'text-anchor':'middle',fill:'#ffc93c','font-family':"'Titan One',sans-serif",'font-size':16});
 function set(v){cur=Math.max(min,Math.min(max,Math.round(v)));const x=xOf(cur);
  knob.setAttribute('cx',x);lbl.setAttribute('x',x);lbl.textContent=(cur>0?'+':'')+cur;}
 svg.appendChild(knob);svg.appendChild(lbl);set(cur);
 if(p.interactivo){
  const toVal=cx=>{const r=svg.getBoundingClientRect();const px=(cx-r.left)/r.width*360;
   return min+(px-x0)/(x1-x0)*(max-min);};
  let drag=false;
  knob.addEventListener('pointerdown',e=>{drag=true;knob.setPointerCapture(e.pointerId);});
  svg.addEventListener('pointermove',e=>{if(drag)set(toVal(e.clientX));});
  svg.addEventListener('pointerup',()=>{drag=false;});
  svg.addEventListener('pointerdown',e=>{if(e.target!==knob)set(toVal(e.clientX));});
 }
 nodo.appendChild(svg);
};
```

- [ ] **Paso 3: Verificar en el navegador**

En la consola:

```js
var n=document.createElement('div');document.body.appendChild(n);
montarDiagrama('recta',{min:-6,max:6,marca:-3,interactivo:true},n);
n.querySelector('svg')!==null   // -> true
```

Debe aparecer una recta con el marcador en -3. Arrástralo (o vía prueba de `set`) y
verifica que la etiqueta muestra el valor con signo. Prueba también el intervalo:

```js
montarDiagrama('recta',{intervalo:{desde:2,tipo:'>='}},n);   // círculo relleno en 2, verde hacia la derecha
```

Sin errores en consola.

---

## Tarea 3: Widgets `fracciones` y `potencias` (los que faltan para Números)

**Archivos:**
- Modificar `index.html` (mismo bloque `DIAGRAMAS`)

- [ ] **Paso 1: Implementar `fracciones`**

```js
// fracciones/%: barra partida en `partes`, con `pintadas` resaltadas.
// params: {partes=4, pintadas=1, etiqueta:'1/4'}
DIAGRAMAS.fracciones=function(p,nodo){
 const partes=Math.max(1,p.partes||4), pint=Math.min(partes,p.pintadas||0);
 const w=320,h=70,x0=20,y0=14,bw=w-40;
 const svg=svgEl('svg',{viewBox:`0 0 ${w} ${h+20}`,role:'img','aria-label':'Fracción'});
 const cw=bw/partes;
 for(let i=0;i<partes;i++){
  svg.appendChild(svgEl('rect',{x:x0+i*cw,y:y0,width:cw-2,height:38,rx:4,
   fill:i<pint?'#8f6bff':'#241a44',stroke:'#5a4b8f','stroke-width':1.5}));
 }
 const t=svgEl('text',{x:w/2,y:h+8,'text-anchor':'middle',fill:'#ffc93c',
  'font-family':"'Titan One',sans-serif",'font-size':16});
 t.textContent=p.etiqueta||`${pint}/${partes}`; svg.appendChild(t);
 nodo.appendChild(svg);
};
```

- [ ] **Paso 2: Implementar `potencias`**

```js
// potencias/raíces: cuadrícula base×base que ilustra un cuadrado (área) o la raíz como lado.
// params: {lado=3, etiqueta:'3² = 9'}
DIAGRAMAS.potencias=function(p,nodo){
 const lado=Math.max(1,Math.min(10,p.lado||3)), cell=24, o=16;
 const size=lado*cell, svg=svgEl('svg',{viewBox:`0 0 ${size+2*o} ${size+2*o+18}`,
  role:'img','aria-label':'Potencia'});
 for(let r=0;r<lado;r++)for(let c=0;c<lado;c++){
  svg.appendChild(svgEl('rect',{x:o+c*cell,y:o+r*cell,width:cell-2,height:cell-2,rx:3,
   fill:'#4dd8ff',opacity:.85,stroke:'#241a44','stroke-width':1}));
 }
 const t=svgEl('text',{x:o+size/2,y:size+2*o+8,'text-anchor':'middle',fill:'#ffc93c',
  'font-family':"'Titan One',sans-serif",'font-size':15});
 t.textContent=p.etiqueta||`${lado}² = ${lado*lado}`; svg.appendChild(t);
 nodo.appendChild(svg);
};
```

- [ ] **Paso 3: Verificar en el navegador**

```js
var n=document.createElement('div');document.body.appendChild(n);
montarDiagrama('fracciones',{partes:4,pintadas:1,etiqueta:'1/4'},n); n.querySelector('svg')!==null; // true
montarDiagrama('potencias',{lado:3,etiqueta:'3² = 9'},n);            n.querySelector('svg')!==null; // true
```

La barra debe mostrar 1 de 4 partes pintadas; la cuadrícula, 3×3=9 celdas. Sin errores.

---

## Tarea 4: Motor de lecciones — recorrer bloques (texto, imagen, diagrama, ejemplo)

**Archivos:**
- Modificar `index.html` (nuevo bloque JS "MOTOR DE LECCIONES", tras el catálogo)

- [ ] **Paso 1: Estado y apertura de una lección**

```js
/* ================= MOTOR DE LECCIONES (camino de aprendizaje) ================= */
let LEC=null;  // {leccion, idx}  idx = bloque actual
function abrirLeccion(leccion){
 LEC={leccion, idx:0};
 $('lecTitulo').textContent=leccion.titulo;
 go('scr-leccion');
 renderBloque();
}
$('lecSalir').onclick=()=>{SND.tap(); volverAlCapituloMate();};
$('lecCont').onclick=()=>{SND.tap(); avanzarBloque();};
```

`volverAlCapituloMate()` se define en la Tarea 7 (vuelve a la lista de lecciones del
capítulo). Por ahora, para verificar, puedes usar `go('scr-expediciones')` y reemplazarlo
en la Tarea 7.

- [ ] **Paso 2: Renderizar el bloque actual**

```js
function renderBloque(){
 const b=LEC.leccion.bloques[LEC.idx], cuerpo=$('lecCuerpo');
 cuerpo.innerHTML='';
 $('lecProgBar').style.width=(LEC.idx/LEC.leccion.bloques.length*100)+'%';
 if(b.t==='texto'){
  const p=document.createElement('p'); p.textContent=b.md; cuerpo.appendChild(p);
 }else if(b.t==='imagen'){
  const img=document.createElement('img'); img.src=b.src; img.alt=b.alt||'';
  img.onerror=function(){this.onerror=null;this.style.display='none';}; cuerpo.appendChild(img);
  if(b.pie){const p=document.createElement('p');p.textContent=b.pie;p.style.textAlign='center';cuerpo.appendChild(p);}
 }else if(b.t==='diagrama'){
  if(b.intro){const p=document.createElement('p');p.textContent=b.intro;cuerpo.appendChild(p);}
  const d=document.createElement('div'); cuerpo.appendChild(d);
  montarDiagrama(b.kind,b.params,d);
 }else if(b.t==='ejemplo'){
  if(b.intro){const p=document.createElement('p');p.textContent=b.intro;cuerpo.appendChild(p);}
  b.pasos.forEach((paso,i)=>{const el=document.createElement('div');
   el.className='lec-ejemplo-paso'+(i===0?' on':'');el.textContent=paso;cuerpo.appendChild(el);});
  // revelar los pasos uno a uno al tocar el cuerpo
  let vis=1; cuerpo.onclick=()=>{const pasos=cuerpo.querySelectorAll('.lec-ejemplo-paso');
   if(vis<pasos.length){pasos[vis].classList.add('on');vis++;}};
 }
 // el botón "Continuar" cambia a "Practicar" en el bloque previo a la práctica
 const sig=LEC.leccion.bloques[LEC.idx+1];
 $('lecCont').textContent = (sig&&sig.t==='practica') ? 'Practicar ▶'
   : (LEC.idx===LEC.leccion.bloques.length-1?'Terminar':'Continuar');
}
```

- [ ] **Paso 3: Avanzar de bloque**

```js
function avanzarBloque(){
 const sig=LEC.leccion.bloques[LEC.idx+1];
 if(sig&&sig.t==='practica'){ iniciarPracticaLeccion(LEC.leccion); return; }  // Tarea 5
 LEC.idx++;
 if(LEC.idx>=LEC.leccion.bloques.length){ terminarLeccion(); return; }        // Tarea 5
 renderBloque();
}
```

`iniciarPracticaLeccion` y `terminarLeccion` se definen en la Tarea 5. Para verificar
esta tarea, define stubs temporales:

```js
function iniciarPracticaLeccion(l){alert('(práctica: Tarea 5)');}
function terminarLeccion(){alert('(fin: Tarea 5)');volverAlCapituloMate&&volverAlCapituloMate();}
```

- [ ] **Paso 4: Verificar con una lección de prueba**

En la consola:

```js
abrirLeccion({id:'test',oa:'MA08 OA 01',titulo:'Prueba',bloques:[
 {t:'texto',md:'Hola, esto es un texto.'},
 {t:'diagrama',kind:'recta',params:{min:-5,max:5,marca:2,interactivo:true},intro:'Mira la recta:'},
 {t:'ejemplo',intro:'Ejemplo:',pasos:['(-4)·(-3)','Signos iguales → +','= 12']},
 {t:'practica',fromBank:{oa:'MA08 OA 01',n:3}}
]});
```

Recorre con "Continuar": debe verse el texto → la recta interactiva → el ejemplo (los
pasos se revelan al tocar) → al pulsar "Practicar ▶" salta el stub. La barra de progreso
avanza. Sin errores en consola.

---

## Tarea 5: Bloque de práctica — reusar el quiz con el flag `Q.leccion`

**Archivos:**
- Modificar `index.html`: motor de lecciones (definir `iniciarPracticaLeccion`,
  `terminarLeccion`); `pintaPregunta` (~2422); `avanzar` (~2530)

- [ ] **Paso 1: Construir preguntas de un OA desde el banco**

En el motor de lecciones, agregar (reusa el patrón de `construirPreguntasDesafio`,
~línea 2560, pero para un solo OA):

```js
// Toma n preguntas del banco de Matemáticas para un OA. Devuelve el formato del quiz.
async function preguntasDeOA(oa,n){
 const url=contenidoDeAsignatura('Matemáticas'); if(!url) return [];
 let pool=[];
 try{ const d=await (await fetch(url)).json();
      pool=(d.preguntas||[]).filter(q=>q.oa===oa); }catch(e){ return []; }
 return pickN(pool,n).map(q=>({q:q.pregunta,ops:q.opciones,ok:q.correcta,tip:q.tip,oa:q.oa}));
}
```

- [ ] **Paso 2: Iniciar la práctica de la lección**

Reemplazar el stub de la Tarea 4 por:

```js
// Lanza el quiz en modo lección (reusa el motor con el flag Q.leccion).
async function iniciarPracticaLeccion(leccion){
 const bloque=leccion.bloques.find(b=>b.t==='practica')||{};
 const fb=bloque.fromBank||{oa:leccion.oa,n:3};
 const preguntas = await preguntasDeOA(fb.oa, fb.n||3);
 if(!preguntas.length){ terminarLeccion(); return; }  // sin banco: se marca completa igual
 Q={lvl:0,idx:0,aciertos:0,combo:0,comboMax:0,xpGanado:0,timer:null,t:15,lock:false,
    preguntas, leccion:{id:leccion.id, titulo:leccion.titulo}};
 MODO='normal';
 go('scr-quiz'); pintaPregunta();
}
```

- [ ] **Paso 3: Rama de la etiqueta en `pintaPregunta`**

En `pintaPregunta` (~2422), el tag ya distingue `Q.desafio`. Extenderlo para `Q.leccion`:

```js
 $('qTag').textContent = Q.leccion
   ? `📘 ${Q.leccion.titulo} · Pregunta ${Q.idx+1}/${Q.preguntas.length}`
   : Q.desafio
   ? `📣 ${Q.desafio.titulo} · Pregunta ${Q.idx+1}/${Q.preguntas.length}`
   : `${MODO==='dificil'?'🔥 ':''}${N.icono} ${N.nombre} · Pregunta ${Q.idx+1}/${Q.preguntas.length}`;
```

Cuidado: la primera línea de `pintaPregunta` hace `const N=EXPEDICION[Q.lvl]`. En modo
lección `EXPEDICION` puede no estar cableado; `N` solo se usa en la rama sin flag, así que
no rompe. Verifica que no haya otros usos de `N` fuera de esa rama.

Nota: `registrarOA` en `responder` (~2446) ya se dispara cuando `!Q.desafio`. Como
`Q.leccion` **no** es `Q.desafio`, la práctica **sí registra dominio** con `P.oa`
(presente porque `preguntasDeOA` conserva `oa`). No hay que tocar `responder`.

- [ ] **Paso 4: Rama de fin en `avanzar`**

En `avanzar` (~2530):

```js
function avanzar(){Q.idx++;if(Q.idx<Q.preguntas.length)pintaPregunta();
  else if(Q.leccion)finPracticaLeccion();
  else if(Q.desafio)terminarDesafio();else terminarNivel();}
```

- [ ] **Paso 5: Cierre de la práctica y de la lección**

```js
// Al terminar la práctica del quiz: envía dominio y marca la lección completa.
function finPracticaLeccion(){
 clearInterval(Q.timer);
 const id=Q.leccion.id;
 enviarDominio();                    // sube el primer intento por OA (reusa kimun_dominio)
 Q={lvl:0,idx:0,aciertos:0,combo:0,comboMax:0,xpGanado:0,timer:null,t:15,lock:false};
 marcarLeccionCompleta(id);
}
// Marca la lección, revisa el desbloqueo del Reto y vuelve al capítulo.
function marcarLeccionCompleta(id){
 S.mateLecciones[id]=true; guardar(); refreshHud();
 SND.win(); toast('primera');
 volverAlCapituloMate();
}
// terminarLeccion: fin sin práctica (lección solo teórica). Marca completa igual.
function terminarLeccion(){ marcarLeccionCompleta(LEC.leccion.id); }
```

`toast('primera')` reusa un toast existente (verificar que la clave `'primera'` exista en
el catálogo de toasts; si no, usa una clave existente como `'jefe'` o crea una nueva
`'leccion'` en el objeto de toasts junto a las demás). `volverAlCapituloMate` se define en
la Tarea 7; deja el stub `function volverAlCapituloMate(){go('scr-campana');renderCampaña&&renderCampaña();}`
por ahora.

- [ ] **Paso 6: Verificar en el navegador**

Con `?qa=1` para no ensuciar el dominio real:

```js
abrirLeccion({id:'ma-oa01',oa:'MA08 OA 01',titulo:'Multiplicar enteros',bloques:[
 {t:'texto',md:'La regla de los signos.'},
 {t:'practica',fromBank:{oa:'MA08 OA 01',n:3}}
]});
```

Pulsa "Practicar ▶": deben cargar 3 preguntas de MA08 OA 01 con la etiqueta "📘". Responde
las 3. Al terminar, en consola:

```js
S.mateLecciones['ma-oa01']   // -> true
```

Debe volver a la campaña y la lección quedar marcada. Sin `?qa`, además, `enviarDominio`
debe intentar subir (verifica en `read_network_requests` la llamada a `kimun_dominio`, o
que quede pendiente si no hay sesión). Sin errores en consola.

---

## Tarea 6: Contenido — `lecciones.json` de la Unidad 1 (Números)

**Archivos:**
- Crear `contenido/matematicas-8basico/lecciones.json`
- Modificar `index.html` (carga bajo demanda del archivo)

- [ ] **Paso 1: Escribir el archivo con las 5 lecciones de Números**

Crear `contenido/matematicas-8basico/lecciones.json`. Cada lección: `id`, `oa`, `titulo`,
`bloques[]`. La práctica usa `fromBank` (banco de 603 preguntas ya revisadas). El texto
didáctico y los ejemplos se redactan siguiendo los `conceptos_clave` de `oa.json` y las
Bases Curriculares. **Ejemplo COMPLETO de la lección OA01** (usar como plantilla exacta
para las otras cuatro):

```json
{
  "asignatura": "Matemática",
  "unidad": "U1 Números",
  "lecciones": [
    {
      "id": "ma-oa01",
      "oa": "MA08 OA 01",
      "titulo": "Multiplicar y dividir enteros",
      "bloques": [
        {"t":"texto","md":"Los números enteros incluyen los positivos, el cero y los negativos. En la recta numérica, los negativos van a la izquierda del cero."},
        {"t":"diagrama","kind":"recta","params":{"min":-6,"max":6,"marca":-3,"interactivo":true},"intro":"Arrastra el punto: su distancia al 0 es su valor absoluto."},
        {"t":"texto","md":"Al multiplicar o dividir, mira los signos: si son IGUALES el resultado es positivo (+); si son DISTINTOS, es negativo (−)."},
        {"t":"ejemplo","intro":"Sigue el ejemplo paso a paso (toca para avanzar):","pasos":["(−4) · (−3)","Signos iguales → resultado positivo","= 12"]},
        {"t":"ejemplo","intro":"Otro caso:","pasos":["(−15) : (+3)","Signos distintos → resultado negativo","= −5"]},
        {"t":"practica","fromBank":{"oa":"MA08 OA 01","n":3}}
      ]
    }
  ]
}
```

Completar el arreglo `lecciones` con las cuatro restantes, mismos criterios:

- **`ma-oa02` — OA02 "Multiplicar y dividir fracciones y decimales":** bloques `texto`
  (multiplicar fracciones = numerador×numerador / denominador×denominador; dividir =
  multiplicar por el inverso), `diagrama` `fracciones` (`{partes:4,pintadas:1,etiqueta:"1/4"}`
  con intro sobre "una parte de cuatro"), `ejemplo` (2/3 · 3/5 = 6/15 = 2/5), `ejemplo`
  (regla del signo con racionales), `practica` `{oa:"MA08 OA 02",n:3}`.
- **`ma-oa03` — OA03 "Multiplicar y dividir potencias":** `texto` (potencia = base
  multiplicada por sí misma; base y exponente), `diagrama` `potencias`
  (`{lado:3,etiqueta:"3² = 9"}`), `texto` (misma base: se suman/restan los exponentes),
  `ejemplo` (2² · 2³ = 2⁵ = 32), `practica` `{oa:"MA08 OA 03",n:3}`.
- **`ma-oa04` — OA04 "Raíces cuadradas":** `texto` (la raíz cuadrada de un número es el
  lado de un cuadrado cuya área es ese número), `diagrama` `potencias`
  (`{lado:4,etiqueta:"√16 = 4"}` — el cuadrado de área 16 tiene lado 4), `ejemplo`
  (estimar √20: está entre 4 y 5 porque 4²=16 y 5²=25), `practica` `{oa:"MA08 OA 04",n:3}`.
- **`ma-oa05` — OA05 "Variaciones porcentuales":** `texto` (un porcentaje es una fracción
  de 100), `diagrama` `fracciones` (`{partes:10,pintadas:3,etiqueta:"30%"}`), `texto`
  (aumento y descuento porcentual), `ejemplo` (un producto de $2000 con 20% de descuento:
  20% de 2000 = 400; paga 1600), `practica` `{oa:"MA08 OA 05",n:3}`.

**Validación del JSON:** tras escribirlo, córrelo por un validador
(`python -c "import json;json.load(open('contenido/matematicas-8basico/lecciones.json',encoding='utf-8'))"`)
y confirma que cada `fromBank.oa` calza con un código real del banco (formato
`MA08 OA 0X`). Cuida: **sin modismos** y en **español latino neutro** (ver reglas del
proyecto).

- [ ] **Paso 2: Cargar `lecciones.json` bajo demanda**

En `index.html`, agregar (en el motor de lecciones):

```js
let LECCIONES=null;   // cache del archivo
async function cargarLecciones(){
 if(LECCIONES) return LECCIONES;
 try{ const d=await (await fetch('contenido/matematicas-8basico/lecciones.json')).json();
      LECCIONES=d.lecciones||[]; }catch(e){ LECCIONES=[]; }
 return LECCIONES;
}
function leccionPorId(id){ return (LECCIONES||[]).find(l=>l.id===id); }
```

- [ ] **Paso 3: Verificar en el navegador**

```js
await cargarLecciones();                 // -> arreglo de 5 lecciones
LECCIONES.map(l=>l.id)                    // -> ['ma-oa01',...,'ma-oa05']
LECCIONES.every(l=>l.bloques.some(b=>b.t==='practica'))  // -> true
abrirLeccion(leccionPorId('ma-oa02'));    // recorre la lección de fracciones completa
```

Recorre `ma-oa02` de punta a punta (texto → diagrama de fracciones → ejemplos → práctica →
marca completa). Sin errores.

---

## Tarea 7: Campaña `'mate'`, ramal de capítulos-lecciones y desbloqueo del Reto

**Archivos:**
- Modificar `index.html`: `CAMPAÑAS` (~1021); `renderCampaña` (~1924); routing del módulo
  Matemáticas en `renderExpediciones` (~1820); `nivelCalcDesbloqueado` (~1332); definir
  `volverAlCapituloMate`, `abrirCapituloMate`, `renderLeccionesMate`

- [ ] **Paso 1: Agregar la campaña `'mate'` a `CAMPAÑAS`**

Al final del arreglo `CAMPAÑAS` (tras la entrada `'leng'`), agregar:

```js
},{
  id:'mate', asignatura:'Matemáticas', portada:'assets/portada-matematicas.png',
  intro:'Aprende los números, el álgebra, la geometría y los datos… y desafía tu cálculo.',
  // capítulos de Matemáticas = grupos de lecciones (no expediciones). Ver capitulosMate.
  esLecciones:true,
  capitulosMate:[
    {id:'mate-numeros', titulo:'Números', lecciones:['ma-oa01','ma-oa02','ma-oa03','ma-oa04','ma-oa05']},
    {id:'mate-algebra', titulo:'Álgebra y funciones', lecciones:[], proximamente:true},
    {id:'mate-geometria', titulo:'Geometría', lecciones:[], proximamente:true},
    {id:'mate-datos', titulo:'Probabilidad y estadística', lecciones:[], proximamente:true},
  ],
  jefeFinal:{
    villano:'La Incógnita', villanoIc:'❓', villanoImg:'assets/villano-matematicas.png',
    dialogo:'Soy la x que nadie despeja… ¿crees que tus números pueden encontrarme?',
    vidasJugador:3, nPorFase:4,
    fases:[
      {nombre:'Números',        oas:['MA08 OA 01','MA08 OA 02','MA08 OA 03','MA08 OA 04','MA08 OA 05']},
      {nombre:'Álgebra',        oas:['MA08 OA 06','MA08 OA 07','MA08 OA 08','MA08 OA 09','MA08 OA 10']},
      {nombre:'Geometría',      oas:['MA08 OA 11','MA08 OA 12','MA08 OA 13','MA08 OA 14']},
      {nombre:'Datos y azar',   oas:['MA08 OA 15','MA08 OA 16','MA08 OA 17']},
    ],
  },
  recompensa:{ skin:'kimun-matematico', insignia:'maestro-matematica', bonoMonedas:500, bonoXP:300 },
}
```

Nota: el Jefe Final y su recompensa **no se activan en este plan** (requieren las 4
unidades completas y el arte del villano/skin, que van en el plan de seguimiento). Se
deja la data para no reescribir la entrada después. La skin `kimun-matematico` y la
insignia `maestro-matematica` se registran en ese plan de seguimiento.

- [ ] **Paso 2: Routing del módulo Matemáticas del menú**

En `renderExpediciones` (~1820), la rama `if(asig==='Matemáticas')` hoy hace
`card.onclick=()=>{SND.tap();abrirRetoCalculo();}`. Cambiarla para abrir la campaña:

```js
  if(asig==='Matemáticas'){
   const camp=CAMPAÑAS.find(c=>c.id==='mate');
   const nHechas=(camp.capitulosMate[0].lecciones||[]).filter(id=>S.mateLecciones[id]).length;
   const nTot=camp.capitulosMate[0].lecciones.length;
   card.innerHTML=`<img src="${ASIG_PORTADA['Matemáticas']}" alt="Matemáticas"><div class="exp-info"><b>Matemáticas</b><small>Aprende y practica · Números ${nHechas}/${nTot}</small></div><span class="exp-go">▶</span>`;
   card.onclick=()=>{SND.tap();abrirCampaña(camp);};
   cont.appendChild(card); return;   // conserva el flujo existente (revisa cómo continúa el bucle)
  }
```

Ajusta el `return`/estructura al bucle real (revisa las líneas 1820-1836 para no romper el
recorrido de las demás asignaturas).

- [ ] **Paso 3: Ramal de campaña para Matemáticas en `renderCampaña`**

Al inicio de `renderCampaña` (tras `const c=CAMP_ACT; if(!c)return;`), bifurcar:

```js
 if(c.esLecciones){ renderCampañaMate(c); return; }
```

Y agregar la función (junto a `renderCampaña`):

```js
// Campaña de Matemáticas: capítulos = grupos de lecciones. Además, acceso al Reto.
function renderCampañaMate(c){
 $('campHead').innerHTML=`<h1 style="font-size:26px">${c.asignatura}</h1><p>${c.intro}</p>`;
 const cont=$('campNodos'); cont.innerHTML='';
 c.capitulosMate.forEach((cap,i)=>{
  const hechas=(cap.lecciones||[]).filter(id=>S.mateLecciones[id]).length;
  const tot=(cap.lecciones||[]).length;
  const hecho=tot>0 && hechas===tot;
  const abierto=!cap.proximamente && (i===0 || capMateCompleto(c.capitulosMate[i-1]));
  const estado=cap.proximamente?'🔒 Pronto':(hecho?'Completado':(abierto?`${hechas}/${tot} lecciones`:'🔒 Bloqueado'));
  cont.appendChild(nodoCampañaEl(`${i+1}`, cap.titulo, abierto, hecho,
    abierto?()=>abrirCapituloMate(cap):null, estado,
    'assets/portada-'+cap.id+'.png', c.portada));
 });
 // acceso al Reto de Cálculo (práctica rápida)
 const reto=document.createElement('div');
 reto.className='camp-nodo';
 reto.innerHTML='<div class="cn-marco"><div class="cn-circ">⚡</div></div><div class="cn-body"><b>Reto de Cálculo</b><small>Práctica rápida · se desbloquea al aprender</small></div>';
 reto.onclick=()=>{SND.tap();abrirRetoCalculo();};
 cont.appendChild(reto);
}
function capMateCompleto(cap){ if(!cap||!cap.lecciones||!cap.lecciones.length)return false;
 return cap.lecciones.every(id=>S.mateLecciones[id]); }
```

- [ ] **Paso 4: Lista de lecciones de un capítulo**

Reusa la pantalla de mapa de capítulo o pinta la lista dentro de `scr-campana`. Enfoque
simple: una vista de lista propia dentro de `campNodos`.

```js
let CAP_MATE=null;
function abrirCapituloMate(cap){ CAP_MATE=cap; renderLeccionesMate(); go('scr-campana'); }
function renderLeccionesMate(){
 const cap=CAP_MATE, c=CAMP_ACT;
 $('campHead').innerHTML=`<h1 style="font-size:24px">${cap.titulo}</h1><p>Lecciones de la unidad</p>`;
 const cont=$('campNodos'); cont.innerHTML='';
 (cap.lecciones||[]).forEach((id,i)=>{
  const hecho=!!S.mateLecciones[id];
  const abierto = i===0 || S.mateLecciones[cap.lecciones[i-1]];  // secuencial dentro del capítulo
  cont.appendChild(nodoCampañaEl(`${i+1}`, tituloLeccion(id), abierto, hecho,
    abierto?()=>iniciarLeccionPorId(id):null,
    hecho?'✓ Completada':(abierto?'¡Aprender!':'🔒 Bloqueada'), ''));
 });
 // volver a la campaña
 const volver=document.createElement('div'); volver.className='camp-nodo';
 volver.innerHTML='<div class="cn-marco"><div class="cn-circ">←</div></div><div class="cn-body"><b>Volver a Matemáticas</b></div>';
 volver.onclick=()=>{SND.tap();renderCampaña();};
 cont.appendChild(volver);
}
function tituloLeccion(id){ const l=leccionPorId(id); return l?l.titulo:id; }
async function iniciarLeccionPorId(id){ await cargarLecciones(); const l=leccionPorId(id);
 if(l)abrirLeccion(l); }
function volverAlCapituloMate(){ if(CAP_MATE)renderLeccionesMate(); else renderCampaña(); go('scr-campana'); }
```

(Elimina el stub temporal de `volverAlCapituloMate` de la Tarea 5.)

- [ ] **Paso 5: Desbloqueo del Reto según lecciones aprendidas**

Reemplazar `nivelCalcDesbloqueado` (~1332) por la versión que lee `S.mateLecciones`, con
la migración cortés (si el nivel ya estaba dominado, sigue abierto):

```js
// Mapeo lección → nivel del Reto (Sesión: camino de aprendizaje). Migración cortés:
// un nivel ya dominado antes sigue abierto aunque no exista la lección correspondiente.
const RETO_REQUISITO=[
 null,                                   // 0 Calentamiento: siempre
 ['ma-oa01'],                            // 1 Enteros
 ['ma-oa03','ma-oa04'],                  // 2 Potencias y raíces
 ['ma-oa02','ma-oa05'],                  // 3 Fracciones y %
 ['ma-oa01','ma-oa02','ma-oa03','ma-oa04','ma-oa05'], // 4 Reto Relámpago: toda la unidad
];
function nivelCalcDesbloqueado(i){
 if(QA)return true;
 if(i===0)return true;
 if(calcEstado().etapas[i]>=1) return true;             // ya jugado antes → cortesía
 const req=RETO_REQUISITO[i]; if(!req) return true;
 return req.every(id=>S.mateLecciones[id]);
}
```

- [ ] **Paso 6: Verificar el flujo completo en el navegador**

Reinicia el estado (`localStorage.clear()`, recarga). Desde el menú:
1. JUGADOR → Matemáticas: debe abrir la **campaña** (no el Reto directo), con 4 capítulos
   (Números abierto; Álgebra/Geometría/Datos "🔒 Pronto") y el nodo "⚡ Reto de Cálculo".
2. Entra a **Números**: 5 lecciones, la 1 abierta y el resto bloqueadas secuencialmente.
3. Juega **ma-oa01** completa. Al volver, la lección 1 queda ✓ y la 2 se abre.
4. Abre el **Reto de Cálculo**: el nivel **Enteros** debe estar desbloqueado (antes de
   jugar ma-oa01 estaba bloqueado). Confirma en consola:

```js
nivelCalcDesbloqueado(1)   // -> true tras completar ma-oa01
nivelCalcDesbloqueado(2)   // -> false (falta ma-oa03 y ma-oa04)
```

Verifica que **Historia/Ciencias/Lenguaje siguen intactas** (abren su campaña normal, 5/5
nodos). Sin errores en consola.

---

## Tarea 8: Ajustar el aviso "Matemáticas no se mide" en `profesor.html`

**Archivos:**
- Modificar `profesor.html`

- [ ] **Paso 1: Localizar el aviso**

Buscar en `profesor.html` el texto que indica que Matemáticas no aparece en el mapa de
dominio (por ejemplo `Matemáticas` cerca de "no se mide" / "Reto de Cálculo"):

Run: `grep -n "Matemática" profesor.html`

- [ ] **Paso 2: Ajustar el texto**

Cambiar el mensaje para reflejar que **el camino de aprendizaje sí se mide** y solo el
Reto de Cálculo queda fuera. Texto sugerido (adaptar a la redacción existente):

> "El camino de aprendizaje de Matemáticas sí aparece en el mapa. El Reto de Cálculo no
> se mide: genera sus operaciones al vuelo, sin objetivo asociado."

Mantener el tono y el formato del aviso actual (mismo `<p>`/clase). Español latino neutro.

- [ ] **Paso 3: Verificar**

Run: `grep -n "camino de aprendizaje" profesor.html`
Esperado: aparece el texto nuevo. Abrir `profesor.html` en el preview y confirmar que el
aviso se lee bien y no rompe el layout (con el banco simulado de siempre, ya que no se
puede iniciar sesión de profesor desde aquí).

---

## Auto-revisión del plan (hecha)

- **Cobertura del spec:** motor de bloques (T4), catálogo interactivo (T2–T3, subconjunto
  de Números; el resto de widgets van en los planes de seguimiento, declarado en el
  encabezado), campaña `'mate'` + capítulos-lecciones (T7), "aprender desbloquea el Reto"
  (T7 P5), medición por OA (T5 P3, reusa `registrarOA`/`kimun_dominio`), persistencia y
  migración cortés (T1, T7 P5), ajuste del panel del profesor (T8). El Jefe Final, la skin
  y la insignia se declaran como plan de seguimiento (fuera de alcance de este plan,
  explícito en el encabezado y en T7 P1).
- **Sin placeholders:** cada paso trae el código o el comando concreto. El contenido
  didáctico de las 4 lecciones restantes (T6) se especifica con la plantilla completa de
  OA01 + los bloques exactos (tipo, `kind`, `params`, `fromBank`) de cada una: es
  contenido a redactar, no un placeholder de código.
- **Consistencia de nombres:** `S.mateLecciones`, `abrirLeccion`/`renderBloque`/
  `avanzarBloque`/`terminarLeccion`/`finPracticaLeccion`, `Q.leccion`, `DIAGRAMAS`/
  `montarDiagrama`, `cargarLecciones`/`leccionPorId`, `capitulosMate`/`abrirCapituloMate`/
  `renderLeccionesMate`/`volverAlCapituloMate`, `nivelCalcDesbloqueado`/`RETO_REQUISITO`
  se usan igual en todas las tareas.
```
