# Campaña "asignatura completa" (piloto Historia) — Plan de implementación

> **Para quien implemente:** usar superpowers:subagent-driven-development (recomendado) o superpowers:executing-plans, tarea por tarea. Los pasos usan casillas `- [ ]`.

**Goal:** Convertir Historia en una campaña con hilo conductor (5 capítulos + Desafío Extra + Jefe Final multi-fase) y recompensas por completar la asignatura, como capa data-driven sobre el motor actual.

**Architecture:** Capa "Campaña" encima de `EXPEDICIONES`. Los capítulos son expediciones normales (se reusa `activarExpedicion`/`cargarPool`/`renderMapa`/quiz). Se agrega un arreglo `CAMPAÑAS`, dos pantallas nuevas (selección de asignatura → mapa de campaña), una pantalla de Jefe Final, y un sistema de recompensas (skin exclusiva, insignias, corona, bono). Nada de lo publicado se rompe.

**Tech Stack:** HTML/CSS/JS vanilla en `index.html`; contenido en `contenido/historia-8basico/preguntas.json` (ya existe, sin cambios). Sin framework de tests: verificación en el navegador (`preview_start`, `javascript_tool`, `read_page`, screenshots).

**Convenciones del proyecto:**
- **Commits:** NO se commitea durante la implementación. Al terminar (o en checkpoints), Roberto da la **"orden 66"** y ahí se hace commit+push (actualizando bitácora/README). Los pasos "Commit" del plan se agrupan bajo esa orden.
- **Idioma:** todo el texto visible en **español latino neutro**, tratamiento "tú".
- Referencias de código son a `index.html` salvo que se indique otra cosa.

**Referencias del motor actual (para reusar):**
- `EXPEDICIONES` (~línea 556): arreglo de expediciones; cada una `{id,asignatura,nivel,portada,contenido,activa,etapas:[...]}`.
- `activarExpedicion(exp)` + `cargarPool(exp)`: cargan el pool de la expedición activa. `POOL[oa]` = preguntas por OA.
- `buildPreguntas(lvl)` / `nPreguntas(lvl)` / `poolListo(lvl)`: arman el set de una etapa.
- `renderExpediciones()` (~876): pinta las tarjetas; `entrarExpedicion(exp)` (~886) entra a una.
- `renderMapa()`: pinta el mapa de nodos de la expedición activa.
- `go(idPantalla)`: navega entre `<section class="screen">`.
- Estado `S` (~654) + `guardar()` (~747) + `cargar()` (~752); progreso por ruta en `S.rutas[id]`.
- `LOGROS` (~644) + `toast(id)` (~703): logros y avisos.
- Tienda/skins: `AVATARES`/`SKINS` y su render (buscar "tienda"/"skin").
- Handler de respuesta del quiz (~1212) donde se detecta jefe vencido y se desbloquea Difícil.

---

## Fase 1 — Datos: capa Campaña y re-corte de Historia

### Task 1: Definir los catálogos `CAMPAÑAS`, `INSIGNIAS` y skins exclusivas

**Files:** Modify `index.html` (junto a `EXPEDICIONES`, ~línea 556).

- [ ] **Paso 1: Agregar los 5 capítulos + Desafío Extra de Historia a `EXPEDICIONES`.**
  Reemplazar la expedición `hist-europeos` por las rutas de la campaña (mismo `contenido`, distinto agrupamiento de OA). Insertar:

```js
// --- Campaña Historia (capítulos = expediciones) ---
{ id:'hist-cap1', asignatura:'Historia', nivel:'8° Básico · Los inicios de la modernidad',
  portada:'assets/portada-historia.png', mapaImg:'assets/kimun-conquistador.png',
  contenido:'contenido/historia-8basico/preguntas.json', activa:true, campaña:'hist',
  etapas:[
    {oa:"HI08 OA 01",nombre:"El ser humano al centro",icono:"🧑‍🎨",n:6},
    {oa:"HI08 OA 02",nombre:"De lo medieval a lo moderno",icono:"⛪",n:6},
    {oa:"HI08 OA 03",nombre:"El Estado moderno",icono:"👑",n:6},
    {oa:"HI08 OA 04",nombre:"La economía mercantilista",icono:"⚖️",n:6},
    {oa:"BOSS",nombre:"⚡ JEFE: La modernidad",icono:"🐲",n:8,oas:["HI08 OA 01","HI08 OA 02","HI08 OA 03","HI08 OA 04"]},
  ]},
{ id:'hist-cap2', asignatura:'Historia', nivel:'8° Básico · Los europeos llegan a América',
  portada:'assets/portada-historia.png', mapaImg:'assets/kimun-conquistador.png',
  contenido:'contenido/historia-8basico/preguntas.json', activa:true, campaña:'hist',
  etapas:[
    {oa:"HI08 OA 05",nombre:"El encuentro de dos mundos",icono:"🌎",n:6},
    {oa:"HI08 OA 06",nombre:"La rapidez de la conquista",icono:"⚔️",n:6},
    {oa:"HI08 OA 07",nombre:"El impacto en Europa",icono:"🌍",n:6},
    {oa:"HI08 OA 08",nombre:"Ciudades y administración",icono:"🏛️",n:6},
    {oa:"BOSS",nombre:"⚡ JEFE: La conquista",icono:"🐲",n:8,oas:["HI08 OA 05","HI08 OA 06","HI08 OA 07","HI08 OA 08"]},
  ]},
{ id:'hist-cap3', asignatura:'Historia', nivel:'8° Básico · El mundo colonial',
  portada:'assets/portada-historia.png', contenido:'contenido/historia-8basico/preguntas.json',
  activa:true, campaña:'hist',
  etapas:[
    {oa:"HI08 OA 09",nombre:"El barroco colonial",icono:"🎭",n:6},
    {oa:"HI08 OA 10",nombre:"Mercados y comercio atlántico",icono:"⛵",n:6},
    {oa:"HI08 OA 11",nombre:"La sociedad colonial",icono:"👥",n:6},
    {oa:"HI08 OA 12",nombre:"Convivencia y conflictos",icono:"🤝",n:6},
    {oa:"BOSS",nombre:"⚡ JEFE: El mundo colonial",icono:"🐲",n:8,oas:["HI08 OA 09","HI08 OA 10","HI08 OA 11","HI08 OA 12"]},
  ]},
{ id:'hist-cap4', asignatura:'Historia', nivel:'8° Básico · Chile colonial y las nuevas ideas',
  portada:'assets/portada-historia.png', contenido:'contenido/historia-8basico/preguntas.json',
  activa:true, campaña:'hist',
  etapas:[
    {oa:"HI08 OA 13",nombre:"La hacienda",icono:"🌾",n:6},
    {oa:"HI08 OA 14",nombre:"La Ilustración",icono:"💡",n:6},
    {oa:"HI08 OA 15",nombre:"Ideas y revoluciones",icono:"🔥",n:6},
    {oa:"HI08 OA 16",nombre:"Independencia americana",icono:"🏴",n:6},
    {oa:"BOSS",nombre:"⚡ JEFE: Nuevas ideas",icono:"🐲",n:8,oas:["HI08 OA 13","HI08 OA 14","HI08 OA 15","HI08 OA 16"]},
  ]},
{ id:'hist-cap5', asignatura:'Historia', nivel:'8° Básico · Independencia y ciudadanía',
  portada:'assets/portada-historia.png', contenido:'contenido/historia-8basico/preguntas.json',
  activa:true, campaña:'hist',
  etapas:[
    {oa:"HI08 OA 17",nombre:"Legitimidad de la conquista",icono:"⚖️",n:6},
    {oa:"HI08 OA 18",nombre:"Los derechos del hombre",icono:"📜",n:6},
    {oa:"HI08 OA 19",nombre:"Independencia de Chile",icono:"🇨🇱",n:6},
    {oa:"BOSS",nombre:"⚡ JEFE: Independencia",icono:"🐲",n:8,oas:["HI08 OA 17","HI08 OA 18","HI08 OA 19"]},
  ]},
{ id:'hist-desafio', asignatura:'Historia', nivel:'8° Básico · Desafío: Chile hoy',
  portada:'assets/portada-historia.png', contenido:'contenido/historia-8basico/preguntas.json',
  activa:true, campaña:'hist', desafio:true, bonoMult:2,
  etapas:[
    {oa:"HI08 OA 20",nombre:"¿Qué es una región?",icono:"🗺️",n:6},
    {oa:"HI08 OA 21",nombre:"Problemas de las regiones",icono:"⚠️",n:6},
    {oa:"HI08 OA 22",nombre:"Desarrollo y regiones",icono:"📈",n:6},
    {oa:"BOSS",nombre:"⭐ DESAFÍO: Chile hoy",icono:"🌟",n:8,oas:["HI08 OA 20","HI08 OA 21","HI08 OA 22"]},
  ]},
```
  Nota: el `id` antiguo `hist-europeos` desaparece de `EXPEDICIONES` (la migración de progreso se maneja en la Fase 5).

- [ ] **Paso 2: Agregar el arreglo `CAMPAÑAS`** justo después del cierre de `EXPEDICIONES` (antes de `let EXP_ACT=...`):

```js
const CAMPAÑAS=[{
  id:'hist', asignatura:'Historia', portada:'assets/portada-historia.png',
  intro:'De la Europa moderna al Chile de hoy: cuatro siglos en una aventura.',
  capitulos:['hist-cap1','hist-cap2','hist-cap3','hist-cap4','hist-cap5'],
  desafioExtra:'hist-desafio',
  jefeFinal:{
    villano:'El Guardián del Tiempo', villanoIc:'🐉',
    dialogo:'Nadie ha recorrido toda la historia... ¿crees que tú puedes?',
    vidasJugador:3, nPorFase:4,
    fases:[
      {nombre:'La modernidad',        oas:['HI08 OA 01','HI08 OA 02','HI08 OA 03','HI08 OA 04']},
      {nombre:'La conquista',         oas:['HI08 OA 05','HI08 OA 06','HI08 OA 07','HI08 OA 08']},
      {nombre:'El mundo colonial',    oas:['HI08 OA 09','HI08 OA 10','HI08 OA 11','HI08 OA 12','HI08 OA 13']},
      {nombre:'Independencia y Chile',oas:['HI08 OA 14','HI08 OA 15','HI08 OA 16','HI08 OA 17','HI08 OA 18','HI08 OA 19','HI08 OA 20','HI08 OA 21','HI08 OA 22']},
    ],
  },
  recompensa:{ skin:'kimun-historiador', insignia:'maestro-historia', bonoMonedas:500, bonoXP:300 },
}];
const INSIGNIAS=[
  {id:'maestro-historia', ic:'🏅', tx:'Maestro de Historia', asignatura:'Historia'},
];
function campañaDe(asig){return CAMPAÑAS.find(c=>c.asignatura===asig)||null;}
function campañaPorId(id){return CAMPAÑAS.find(c=>c.id===id)||null;}
```

- [ ] **Paso 3: Registrar la skin exclusiva** en el catálogo de skins/avatares (buscar `AVATARES`/`SKINS`). Agregar una entrada marcada como bloqueada:
```js
// dentro del catálogo de skins comprables, añadir:
{ id:'kimun-historiador', nombre:'Kimün Historiador', img:'assets/kimun-historiador.png',
  bloqueada:true, desbloqueaCon:'hist', precio:null },
```
  Si no existe el asset aún, usar `assets/portada-historia.png` como marcador temporal.

- [ ] **Paso 4 (verificación navegador):** `preview_start` → en consola:
  `EXPEDICIONES.filter(e=>e.campaña==='hist').map(e=>e.id)` debe dar los 6 ids;
  `CAMPAÑAS[0].capitulos.length===5`; `campañaDe('Historia').id==='hist'`.
  Recargar la página no debe arrojar errores en `read_console_messages`.

### Task 2: Estado nuevo en `S` + persistencia

**Files:** Modify `index.html` (`S` ~654, `guardar()` ~747, `cargar()` ~752).

- [ ] **Paso 1:** En la definición de `S`, agregar:
```js
campañasCompletas:new Set(), insignias:new Set(), insigniaActiva:null,
```
- [ ] **Paso 2:** En `guardar()`, incluir en el objeto serializado:
```js
campañasCompletas:[...S.campañasCompletas], insignias:[...S.insignias], insigniaActiva:S.insigniaActiva,
```
- [ ] **Paso 3:** En `cargar()`, rehidratar (tolerante a guardados viejos):
```js
S.campañasCompletas=new Set(d.campañasCompletas||[]);
S.insignias=new Set(d.insignias||[]);
S.insigniaActiva=d.insigniaActiva||null;
```
- [ ] **Paso 4 (verificación):** en consola, `S.campañasCompletas instanceof Set` y tras `guardar();cargar();` los tres campos persisten.

---

## Fase 2 — Pantalla de campaña y desbloqueo secuencial

### Task 3: Helpers de progreso de campaña

**Files:** Modify `index.html` (cerca de `activarExpedicion`/`S.rutas`).

- [ ] **Paso 1:** Agregar helpers puros (una función = una responsabilidad):
```js
// ¿el jefe (último nodo) de esta expedición está vencido en Normal?
function expedicionCompleta(id){
  const st=S.rutas[id]; if(!st||!st.progreso)return false;
  const ult=st.progreso[st.progreso.length-1];
  return !!ult && ult.est==='done';
}
// capítulos completados de una campaña (en orden)
function capsCompletos(camp){return camp.capitulos.filter(expedicionCompleta).length;}
// ¿está desbloqueado el nodo i de la campaña? (0..n-1 capítulos, luego desafío, luego jefe)
function nodoCampDesbloqueado(camp,i){
  if(i===0)return true;                                   // capítulo 1
  if(i<camp.capitulos.length)return expedicionCompleta(camp.capitulos[i-1]); // cap N tras N-1
  return false;
}
function desafioDesbloqueado(camp){return camp.capitulos.every(expedicionCompleta);}
function jefeFinalDesbloqueado(camp){return desafioDesbloqueado(camp)&&expedicionCompleta(camp.desafioExtra);}
function campañaCompleta(camp){return S.campañasCompletas.has(camp.id);}
```
- [ ] **Paso 2 (verificación):** en consola, con `S.rutas` vacío: `nodoCampDesbloqueado(CAMPAÑAS[0],0)===true`, `nodoCampDesbloqueado(CAMPAÑAS[0],1)===false`, `jefeFinalDesbloqueado(CAMPAÑAS[0])===false`.

### Task 4: Selección de asignatura (Nivel 1) con corona

**Files:** Modify `index.html` — `renderExpediciones()` (~876) y `entrarExpedicion()` (~886).

- [ ] **Paso 1:** En `renderExpediciones()`, al construir cada tarjeta, si la asignatura tiene campaña, enrutar a la campaña y mostrar corona si está completa:
```js
EXPEDICIONES.forEach(exp=>{ /* … */ });
// Reemplazar el forEach para agrupar: primero las campañas (una tarjeta por asignatura con campaña),
// luego las expediciones sueltas de asignaturas SIN campaña.
```
  Implementación concreta de `renderExpediciones()`:
```js
function renderExpediciones(){
 const g=$('expGrid'); g.innerHTML='';
 const conCamp=new Set(CAMPAÑAS.map(c=>c.asignatura));
 // 1) tarjeta por campaña
 CAMPAÑAS.forEach(c=>{
   const done=campañaCompleta(c);
   const card=document.createElement('div'); card.className='exp-card';
   card.innerHTML=`<img src="${c.portada}" alt="${c.asignatura}">
     <div class="exp-info"><b>${c.asignatura} ${done?'👑':''}</b><small>Campaña · ${capsCompletos(c)}/${c.capitulos.length} capítulos</small></div>
     <span class="exp-go">▶</span>`;
   card.onclick=()=>{SND.tap(); abrirCampaña(c);};
   g.appendChild(card);
 });
 // 2) expediciones sueltas (asignaturas sin campaña)
 EXPEDICIONES.filter(e=>e.activa&&!e.campaña&&!conCamp.has(e.asignatura)).forEach(exp=>{
   const card=document.createElement('div'); card.className='exp-card';
   card.innerHTML=`<img src="${exp.portada}" alt="${exp.asignatura}"><div class="exp-info"><b>${exp.asignatura}</b><small>${exp.nivel}</small></div><span class="exp-go">▶</span>`;
   card.onclick=()=>{SND.tap(); entrarExpedicion(exp);};
   g.appendChild(card);
 });
}
```
- [ ] **Paso 2 (verificación):** render de `scr-expediciones` muestra **una** tarjeta "Historia" (campaña) + las 3 asignaturas sueltas (Matemáticas/Ciencias/Lenguaje) + las expediciones extra que no son campaña. Screenshot.

### Task 5: Pantalla del mapa de campaña (Nivel 2)

**Files:** Modify `index.html` — agregar `<section class="screen" id="scr-campana">` en el HTML (junto a `scr-expediciones`) y las funciones `abrirCampaña`/`renderCampaña`.

- [ ] **Paso 1:** HTML de la pantalla:
```html
<section class="screen" id="scr-campana">
  <div class="topbar"><button class="btn-ghost" id="btnCampBack">← Volver</button></div>
  <div id="campHead"></div>
  <div id="campNodos"></div>
</section>
```
- [ ] **Paso 2:** Funciones:
```js
let CAMP_ACT=null;
function abrirCampaña(c){CAMP_ACT=c; renderCampaña(); go('scr-campana');}
$('btnCampBack').onclick=()=>{SND.tap(); go('scr-expediciones');};
function renderCampaña(){
  const c=CAMP_ACT;
  $('campHead').innerHTML=`<h2>${c.asignatura} ${campañaCompleta(c)?'👑':''}</h2><p class="sub">${c.intro}</p>`;
  const cont=$('campNodos'); cont.innerHTML='';
  // capítulos
  c.capitulos.forEach((id,i)=>{
    const exp=EXPEDICIONES.find(e=>e.id===id);
    const abierto=nodoCampDesbloqueado(c,i), hecho=expedicionCompleta(id);
    cont.appendChild(nodoCampañaEl(`${i+1}`, exp.nivel.split('· ')[1]||exp.nivel, abierto, hecho,
      abierto?()=>entrarExpedicion(exp):null, hecho?'Completado':(abierto?'¡Jugar!':'🔒 Bloqueado')));
  });
  // desafío extra
  const de=EXPEDICIONES.find(e=>e.id===c.desafioExtra);
  const deAb=desafioDesbloqueado(c), deHecho=expedicionCompleta(c.desafioExtra);
  cont.appendChild(nodoCampañaEl('⭐','Desafío Extra: Chile hoy', deAb, deHecho,
    deAb?()=>entrarExpedicion(de):null, deHecho?'Completado':(deAb?'¡Desafío!':'🔒 Termina los 5 capítulos')));
  // jefe final
  const jfAb=jefeFinalDesbloqueado(c), jfHecho=campañaCompleta(c);
  cont.appendChild(nodoCampañaEl('👑','JEFE FINAL DE HISTORIA', jfAb, jfHecho,
    jfAb?()=>iniciarJefeFinal(c):null, jfHecho?'¡Vencido!':(jfAb?'¡Al 100%! Enfréntalo':'🔒 Completa todo')));
}
function nodoCampañaEl(marca,titulo,abierto,hecho,onClick,estado){
  const d=document.createElement('div');
  d.className='camp-nodo'+(abierto?'':' lock')+(hecho?' done':'');
  d.innerHTML=`<div class="cn-circ">${hecho?'✓':marca}</div><div class="cn-body"><b>${titulo}</b><small>${estado}</small></div>`;
  if(onClick) d.onclick=()=>{SND.tap(); onClick();};
  return d;
}
```
- [ ] **Paso 3:** CSS mínimo para `.camp-nodo` (calcar estilo de nodos del mapa; `.lock` atenuado, `.done` con borde verde). Reusar variables `--gold/--green/--violet`.
- [ ] **Paso 4 (verificación):** `abrirCampaña(CAMPAÑAS[0])` muestra 5 capítulos (solo el 1 abierto), el Desafío (bloqueado) y el Jefe Final (bloqueado). Simular en consola completar cap1 (`S.rutas['hist-cap1']={progreso:[{est:'done'}]}` con el largo correcto) → `renderCampaña()` abre el capítulo 2. Screenshot.

### Task 6: Volver al mapa de campaña al terminar una etapa

**Files:** Modify `index.html` — el "Volver" del mapa de expedición (`renderMapa`/botón back del mapa) y el flujo tras vencer un jefe de capítulo.

- [ ] **Paso 1:** Cuando la expedición activa pertenece a una campaña (`EXP_ACT.campaña`), el botón "volver" del mapa debe regresar a `scr-campana` (no a `scr-expediciones`). Ajustar el handler correspondiente:
```js
// donde el mapa hace go('scr-expediciones'):
go(EXP_ACT && EXP_ACT.campaña ? 'scr-campana' : 'scr-expediciones');
```
- [ ] **Paso 2 (verificación):** entrar a un capítulo desde la campaña y volver regresa al mapa de campaña con el progreso reflejado.

---

## Fase 3 — Jefe Final (pantalla multi-fase)

### Task 7: Estado y armado de preguntas del Jefe Final

**Files:** Modify `index.html` — nuevas funciones cerca del quiz.

- [ ] **Paso 1:** Estado del jefe y armado por fase (reusa `pickN` y `POOL`; requiere pool de Historia cargado):
```js
let JF=null; // {camp, fase, idx, preguntas, vidaMax, vida, vidas, lock}
function jefePreguntasFase(camp,faseIdx){
  const f=camp.jefeFinal.fases[faseIdx], n=camp.jefeFinal.nPorFase, per=Math.max(1,Math.ceil(n/f.oas.length));
  let sel=[]; f.oas.forEach(oa=>{sel=sel.concat(pickN(POOL[oa]||[],per));});
  return pickN(sel,n).map(q=>({q:q.pregunta,ops:q.opciones,ok:q.correcta,tip:q.tip}));
}
```
- [ ] **Paso 2:** `iniciarJefeFinal(camp)` — carga el pool de la asignatura de la campaña y entra a la intro:
```js
function iniciarJefeFinal(camp){
  const capExp=EXPEDICIONES.find(e=>e.id===camp.capitulos[0]);
  activarExpedicion(capExp).then(()=>{ // asegura POOL de Historia cargado
    const jf=camp.jefeFinal;
    JF={camp,fase:0,idx:0,preguntas:[],vidaMax:jf.fases.length*jf.nPorFase,vida:jf.fases.length*jf.nPorFase,vidas:jf.vidasJugador,lock:false};
    renderJefeIntro();
  });
}
```
- [ ] **Paso 3 (verificación):** `iniciarJefeFinal(CAMPAÑAS[0])` deja `JF.vidaMax===16`, `JF.vidas===3`, y `jefePreguntasFase(CAMPAÑAS[0],1).length===4` con opciones válidas.

### Task 8: Pantalla de intro épica del jefe

**Files:** Modify `index.html` — `<section id="scr-jefe-intro">` + `renderJefeIntro()`.

- [ ] **Paso 1:** HTML:
```html
<section class="screen" id="scr-jefe-intro">
  <div class="jefe-intro">
    <div id="jiVillano" class="ji-villano"></div>
    <h2 id="jiNombre"></h2>
    <p id="jiDialogo" class="ji-dialogo"></p>
    <button class="btn btn-danger" id="jiStart">¡Que comience el duelo!</button>
  </div>
</section>
```
- [ ] **Paso 2:**
```js
function renderJefeIntro(){
  const jf=JF.camp.jefeFinal;
  $('jiVillano').textContent=jf.villanoIc; $('jiNombre').textContent=jf.villano;
  $('jiDialogo').textContent='"'+jf.dialogo+'"';
  go('scr-jefe-intro');
}
$('jiStart').onclick=()=>{SND.tap(); JF.fase=0; cargarFaseJefe(); go('scr-jefe');};
```
- [ ] **Paso 3:** CSS: villano grande, fondo oscuro/carmesí (reusar look del Modo Difícil), animación de entrada. Respetar `prefers-reduced-motion`.
- [ ] **Paso 4 (verificación):** la intro muestra villano, nombre y diálogo; el botón lleva a `scr-jefe`. Screenshot.

### Task 9: Pantalla del duelo (barra de vida, vidas, fases)

**Files:** Modify `index.html` — `<section id="scr-jefe">` + funciones `cargarFaseJefe`, `renderJefePregunta`, `responderJefe`.

- [ ] **Paso 1:** HTML:
```html
<section class="screen" id="scr-jefe">
  <div class="jefe-hud">
    <div class="jefe-vida"><span id="jvNombre"></span><div class="hpbar"><i id="jvFill"></i></div></div>
    <div class="jefe-sub"><span id="jvVidas" class="jefe-hearts"></span><span id="jvFase" class="jefe-fase"></span></div>
  </div>
  <div id="jefePregunta" class="quiz-body"></div>
</section>
```
- [ ] **Paso 2:** Lógica (reusa el render de opciones del quiz; si existe una función de pintado de pregunta, reusarla; si no, replicar el patrón del quiz):
```js
function cargarFaseJefe(){
  JF.preguntas=jefePreguntasFase(JF.camp,JF.fase); JF.idx=0; renderJefePregunta();
}
function pintarHudJefe(){
  const jf=JF.camp.jefeFinal;
  $('jvNombre').textContent=jf.villano;
  $('jvFill').style.width=Math.max(0,(JF.vida/JF.vidaMax*100))+'%';
  $('jvVidas').textContent='❤️'.repeat(JF.vidas)+'🤍'.repeat(jf.vidasJugador-JF.vidas);
  $('jvFase').textContent='Fase '+(JF.fase+1)+' de '+jf.fases.length+' · '+jf.fases[JF.fase].nombre;
}
function renderJefePregunta(){
  pintarHudJefe();
  const p=JF.preguntas[JF.idx]; const cont=$('jefePregunta');
  cont.innerHTML='<div class="q-text">'+p.q+'</div><div class="q-ops"></div>';
  const ops=cont.querySelector('.q-ops');
  p.ops.forEach((op,k)=>{const b=document.createElement('button');b.className='q-op';b.textContent=op;
    b.onclick=()=>responderJefe(k);ops.appendChild(b);});
  JF.lock=false;
}
function responderJefe(k){
  if(JF.lock)return; JF.lock=true;
  const p=JF.preguntas[JF.idx], ok=(k===p.ok);
  if(ok){ SND.ok(); JF.vida=Math.max(0,JF.vida-1); }
  else { SND.err(); JF.vidas--; }
  pintarHudJefe();
  setTimeout(()=>{
    if(JF.vidas<=0){ return jefeDerrota(); }
    if(JF.vida<=0){ return jefeVictoria(); }
    JF.idx++;
    if(JF.idx>=JF.preguntas.length){ // fin de fase
      JF.fase++;
      if(JF.fase>=JF.camp.jefeFinal.fases.length){ JF.fase=0; } // por si quedara vida; normalmente ya venció
      cargarFaseJefe();
    } else { renderJefePregunta(); }
  }, ok?700:1100);
}
```
  Nota de diseño: la vida total (`fases×nPorFase`) equivale a la cantidad de aciertos necesarios; al vaciarse se gana. Cada fase aporta `nPorFase` preguntas nuevas; si el jugador falla, no baja la vida del jefe pero pierde un corazón.
- [ ] **Paso 3:** CSS de `.hpbar/.jefe-hearts/.jefe-fase` (barra rosada que baja, corazones, rótulo de fase). Look carmesí del Modo Difícil.
- [ ] **Paso 4 (verificación):** en consola, forzar `JF` y llamar `responderJefe` con la correcta baja `jvFill`; con incorrecta baja un corazón; a 0 corazones va a derrota; a vida 0 va a victoria.

### Task 10: Derrota y victoria del Jefe Final

**Files:** Modify `index.html` — `jefeDerrota`, `jefeVictoria` (esta última llama a las recompensas de la Fase 4).

- [ ] **Paso 1:**
```js
function jefeDerrota(){
  SND.lose();
  alert('El Guardián del Tiempo te venció esta vez. ¡Inténtalo de nuevo!');
  iniciarJefeFinal(JF.camp); // reintento con preguntas nuevas
}
function jefeVictoria(){
  SND.win();
  otorgarRecompensasCampaña(JF.camp); // Fase 4
  renderJefeVictoria();               // pantalla de celebración
}
```
- [ ] **Paso 2:** `renderJefeVictoria()` — pantalla de celebración que muestra las recompensas y un botón "Volver a la campaña" (`go('scr-campana'); renderCampaña();`). Detalle visual en Fase 4.
- [ ] **Paso 3 (verificación):** forzar victoria → se marca `S.campañasCompletas.has('hist')` y aparece la pantalla de victoria.

---

## Fase 4 — Recompensas

### Task 11: Otorgar recompensas al vencer

**Files:** Modify `index.html` — `otorgarRecompensasCampaña`.

- [ ] **Paso 1:**
```js
function otorgarRecompensasCampaña(camp){
  const r=camp.recompensa;
  S.campañasCompletas.add(camp.id);
  if(r.insignia) S.insignias.add(r.insignia);
  if(r.skin && !S.skins.includes(r.skin)) S.skins.push(r.skin); // desbloquea la skin exclusiva
  S.monedas+=(r.bonoMonedas||0); S.xp+=(r.bonoXP||0);
  if(S.insigniaActiva===null && r.insignia) S.insigniaActiva=r.insignia; // luce la primera por defecto
  guardar(); refreshHud();
}
```
- [ ] **Paso 2 (verificación):** tras llamar, `S.skins` incluye `kimun-historiador`, `S.insignias` incluye `maestro-historia`, monedas/XP suben, y persiste tras `cargar()`.

### Task 12: Skin exclusiva visible-pero-bloqueada en la tienda

**Files:** Modify `index.html` — render de la tienda de skins.

- [ ] **Paso 1:** En el render de la tienda, para cada skin con `bloqueada`:
  - si `S.skins.includes(id)` → mostrarla como equipable (ya desbloqueada).
  - si no → mostrarla con overlay "🔒 Termina Historia" y **sin** botón de compra (no comprable).
```js
// pseudo-integración en el forEach de skins:
if(skin.bloqueada && !S.skins.includes(skin.id)){
  botonCompra.remove();
  card.insertAdjacentHTML('beforeend','<div class="skin-lock">🔒 Termina Historia</div>');
}
```
- [ ] **Paso 2 (verificación):** con la campaña incompleta, la skin aparece bloqueada sin precio; tras `otorgarRecompensasCampaña`, aparece equipable. Screenshot de ambos estados.

### Task 13: Vitrina de insignias + selector, y mostrarla junto al nombre

**Files:** Modify `index.html` — sección de perfil/logros y el HUD (`refreshHud`), y el nombre en el duelo.

- [ ] **Paso 1:** Render de la vitrina (en el panel de perfil actual, ~línea 1093 donde hoy hay un `alert` de logros; reemplazar por una pantalla/section simple o listado):
```js
function renderInsignias(){
  const cont=$('insigniasGrid'); cont.innerHTML='';
  INSIGNIAS.forEach(ins=>{
    const tengo=S.insignias.has(ins.id), activa=S.insigniaActiva===ins.id;
    const d=document.createElement('button');
    d.className='insignia'+(tengo?'':' lock')+(activa?' activa':'');
    d.innerHTML=`<span class="i-ic">${tengo?ins.ic:'🔒'}</span><span>${ins.tx}</span>`;
    if(tengo) d.onclick=()=>{S.insigniaActiva=activa?null:ins.id; guardar(); renderInsignias(); refreshHud();};
    cont.appendChild(d);
  });
}
```
- [ ] **Paso 2:** En `refreshHud()`, mostrar la insignia activa junto al nombre:
```js
const ins=INSIGNIAS.find(i=>i.id===S.insigniaActiva);
$('hudNombre').innerHTML = (ins?ins.ic+' ':'') + S.nombre;
```
- [ ] **Paso 3:** En el duelo, donde se pinta el nombre del jugador, anteponer `ins.ic` si hay `insigniaActiva` (leer igual que en el HUD).
- [ ] **Paso 4 (verificación):** con la insignia ganada, aparece en la vitrina; al seleccionarla se muestra junto al nombre en HUD y duelo; al deseleccionar desaparece. Screenshot.

### Task 14: Pantalla de victoria con recompensas

**Files:** Modify `index.html` — `renderJefeVictoria()` + `<section id="scr-jefe-win">`.

- [ ] **Paso 1:** HTML + función que liste: "¡Historia dominada!", la skin desbloqueada, la insignia ganada, la corona y el bono. Botón "Volver a la campaña".
- [ ] **Paso 2 (verificación):** la pantalla muestra las 4 recompensas y vuelve a la campaña (que ahora muestra 👑 en la asignatura y el Jefe Final como "¡Vencido!").

---

## Fase 5 — Migración y verificación integral

### Task 15: Migración del progreso del piloto `hist-europeos`

**Files:** Modify `index.html` — `cargar()`.

- [ ] **Paso 1:** Al final de `cargar()`, aplicar cortesía y limpieza:
```js
if(S.rutas['hist-europeos']){
  const viejo=S.rutas['hist-europeos'];
  const ult=viejo.progreso&&viejo.progreso[viejo.progreso.length-1];
  if(ult&&ult.est==='done'){ // había vencido al piloto → pre-desbloquear Capítulo 2
    S.rutas['hist-cap1']=S.rutas['hist-cap1']||{progreso:nuevoProgreso(5),progresoDificil:nuevoProgreso(5),dificilDesbloqueado:false};
    // marcar cap1 como completado para que el motor abra el cap2
    S.rutas['hist-cap1'].progreso[S.rutas['hist-cap1'].progreso.length-1].est='done';
  }
  delete S.rutas['hist-europeos']; guardar();
}
```
  Nota: XP/monedas/estrellas/skins/logros son globales y no se tocan.
- [ ] **Paso 2 (verificación):** inyectar en localStorage un guardado con `hist-europeos` (jefe done) → recargar → la clave vieja desaparece, el Capítulo 2 queda abierto, y lo global se conserva.

### Task 16: Verificación integral en el navegador

**Files:** — (solo verificación)

- [ ] **Paso 1:** `preview_start`, recorrer: selección → tarjeta Historia (campaña) → mapa con desbloqueo secuencial.
- [ ] **Paso 2:** Simular en consola completar los 5 capítulos + Desafío → el Jefe Final se desbloquea.
- [ ] **Paso 3:** Jugar el Jefe Final: la barra baja con aciertos, los corazones con errores, transición de fases; derrota reintenta; victoria otorga recompensas.
- [ ] **Paso 4:** Recompensas: skin equipable en tienda, insignia en vitrina + junto al nombre, corona en la tarjeta, bono aplicado.
- [ ] **Paso 5:** `read_console_messages` sin errores. Screenshots de: mapa de campaña, intro del jefe, duelo, victoria, tienda con skin desbloqueada.

### Task 17: Cierre (orden 66)

- [ ] **Paso 1:** Con Roberto: dar la **"orden 66"**. Antes de commit: actualizar la bitácora del `CLAUDE.md` (nueva sesión: campaña de Historia) y el README si aplica; incluir el spec y este plan (`docs/superpowers/...`).
- [ ] **Paso 2:** Commit + push (lo ejecuta el flujo de la orden 66).

---

## Assets pendientes (Roberto)
- `assets/kimun-historiador.png` — skin exclusiva (mientras tanto, marcador con la portada de Historia).
- Arte/animación del villano del Jefe Final (mientras tanto, emoji 🐉).

## Notas de auto-revisión
- Cobertura del spec: §4 estructura → Task 1; §5 datos/estado → Tasks 1-2; §6 pantalla/desbloqueo → Tasks 3-6; §7 jefe → Tasks 7-10; §8 recompensas → Tasks 11-14; §9 migración → Task 15; §10 verificación → Task 16. ✔
- Sin framework de tests: cada "verificación" es en el navegador (declarado arriba). Los nombres de funciones/propiedades son consistentes entre tareas (`expedicionCompleta`, `JF`, `otorgarRecompensasCampaña`, `S.campañasCompletas`).
- Los selectores de HUD/tienda/duelo (`$('hudNombre')`, render de skins, nombre en el duelo) deben confirmarse contra el `index.html` real al implementar cada tarea (el plan indica dónde, no asume ids exactos donde no los verifiqué).
