# Expedición para Matemáticas — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Darle a Matemáticas una capa de expedición (quiz por OA + jefes) usando el banco de 603 preguntas, con flujo enseña→desafío por unidad, sin quitar el Reto de Cálculo.

**Architecture:** Reutilizar el motor de expedición existente (usado por Historia/Ciencias/Lenguaje): se agregan 4 expediciones a `EXPEDICIONES` (una por unidad) y se pobla `capitulos` de la campaña `mate`. `renderCampañaMate` se reescribe para intercalar, por unidad, el nodo de lecciones y el de expedición (bloqueado hasta terminar las lecciones). El Jefe Final pasa a exigir las 4 expediciones. Modo Difícil se hereda del motor; se agrega una insignia propia sin tocar la Maestría Total.

**Tech Stack:** HTML/CSS/JS vanilla en un único archivo `index.html`. Sin build, sin framework, sin test runner. Datos en JSON bajo `contenido/`.

## Global Constraints

- Todo el juego vive en `C:/Proyectos/kimun/index.html` (vanilla JS, sin build ni framework).
- **No hay framework de tests.** La verificación es por navegador: server de preview `kimun-dev` en `http://localhost:8765`, usando las herramientas del Browser pane (`navigate`, `javascript_tool`, `read_page`, `read_console_messages`, `computer`). El modo QA se activa con `?qa=1` (marca respuestas y desbloquea todo; no altera el juego normal).
- Banco de contenido: `contenido/matematicas-8basico/preguntas.json` (603 preguntas, OA `MA08 OA 01`..`MA08 OA 17`; cada OA ≥30 preguntas).
- Reutilizar assets existentes: `portada-mate-numeros.png`, `portada-mate-algebra.png`, `portada-mate-geometria.png`, `portada-mate-datos.png`, `villano-matematicas.png`. **No crear arte nuevo.**
- **Cambios aditivos.** No tocar: Reto de Cálculo, El Autómata, Sin Fin, las lecciones y su práctica de 10 preguntas, las fases del Jefe Final (`cargarPoolMate`/`jefePreguntasFase`).
- **Maestría Total NO cambia:** `DIF_ASIGS` se mantiene en `['Historia','Ciencias','Lenguaje']`; `esMaestro()` no se toca.
- Commits en español, frecuentes, terminando con:
  `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`
- Spec de referencia: `docs/superpowers/specs/2026-08-22-matematicas-expedicion-design.md`.

---

## File Structure

- **Modify** `index.html` únicamente. Cuatro zonas:
  - `EXPEDICIONES` (array, termina en `];` cerca de la línea 1090): agregar 4 objetos.
  - `CAMPAÑAS` → objeto `mate` (`capitulos:[]`, cerca de la línea 1149): poblar `capitulos`.
  - `INSIGNIAS` (línea ~1169) y `LOGROS` (línea ~1220): nueva insignia `dif-matematicas`.
  - `renderCampañaMate` (líneas ~2552-2577) y `revisarDificil` (línea ~3148): lógica.

---

## Task 1: Datos — 4 expediciones de Matemáticas + poblar `capitulos`

**Files:**
- Modify: `index.html` (fin del array `EXPEDICIONES`, antes del `];` ~línea 1090)
- Modify: `index.html` (campaña `mate` en `CAMPAÑAS`, `capitulos:[]` ~línea 1149)

**Interfaces:**
- Consumes: motor existente `EXPEDICIONES`, `CAMPAÑAS`, `campañaPorId(id)`.
- Produces: 4 expediciones con ids `mate-exp-numeros`, `mate-exp-algebra`, `mate-exp-geometria`, `mate-exp-datos`, cada una con `campaña:'mate'` y `contenido` al banco de 603. `campañaPorId('mate').capitulos` = esos 4 ids en orden.

- [ ] **Step 1: Chequeo previo (debe fallar)**

Con el server corriendo, navegar a `http://localhost:8765/index.html` y ejecutar en `javascript_tool`:
```js
JSON.stringify({exp: EXPEDICIONES.filter(e=>e.campaña==='mate').length, caps: campañaPorId('mate').capitulos.length})
```
Esperado ANTES: `{"exp":0,"caps":0}`.

- [ ] **Step 2: Insertar las 4 expediciones**

En `index.html`, justo antes del `];` que cierra `EXPEDICIONES` (después del objeto `lect-anafrank`), insertar:
```js
 // --- Campaña Matemáticas (expedición · usa el banco de año completo de 603) ---
 { id:'mate-exp-numeros', asignatura:'Matemáticas', nivel:'8° Básico · Números',
   portada:'assets/portada-mate-numeros.png', contenido:'contenido/matematicas-8basico/preguntas.json', activa:true, campaña:'mate',
   etapas:[
     {oa:"MA08 OA 01", nombre:"Enteros", icono:"🔢", n:6},
     {oa:"MA08 OA 02", nombre:"Fracciones y decimales", icono:"➗", n:6},
     {oa:"MA08 OA 03", nombre:"Potencias", icono:"✖️", n:6},
     {oa:"MA08 OA 04", nombre:"Raíces cuadradas", icono:"√", n:6},
     {oa:"MA08 OA 05", nombre:"Porcentajes", icono:"％", n:6},
     {oa:"BOSS", nombre:"⚡ JEFE: Números", icono:"🧮", n:8, oas:["MA08 OA 01","MA08 OA 02","MA08 OA 03","MA08 OA 04","MA08 OA 05"]},
   ]},
 { id:'mate-exp-algebra', asignatura:'Matemáticas', nivel:'8° Básico · Álgebra y funciones',
   portada:'assets/portada-mate-algebra.png', contenido:'contenido/matematicas-8basico/preguntas.json', activa:true, campaña:'mate',
   etapas:[
     {oa:"MA08 OA 06", nombre:"Lenguaje algebraico", icono:"✏️", n:6},
     {oa:"MA08 OA 07", nombre:"Función lineal", icono:"📈", n:6},
     {oa:"MA08 OA 08", nombre:"Ecuaciones", icono:"⚖️", n:6},
     {oa:"MA08 OA 09", nombre:"Inecuaciones", icono:"🚦", n:6},
     {oa:"MA08 OA 10", nombre:"Función afín", icono:"📉", n:6},
     {oa:"BOSS", nombre:"⚡ JEFE: Álgebra", icono:"🧮", n:8, oas:["MA08 OA 06","MA08 OA 07","MA08 OA 08","MA08 OA 09","MA08 OA 10"]},
   ]},
 { id:'mate-exp-geometria', asignatura:'Matemáticas', nivel:'8° Básico · Geometría',
   portada:'assets/portada-mate-geometria.png', contenido:'contenido/matematicas-8basico/preguntas.json', activa:true, campaña:'mate',
   etapas:[
     {oa:"MA08 OA 11", nombre:"Área y volumen", icono:"📦", n:6},
     {oa:"MA08 OA 12", nombre:"Teorema de Pitágoras", icono:"📐", n:6},
     {oa:"MA08 OA 13", nombre:"Movimientos en el plano", icono:"🔃", n:6},
     {oa:"MA08 OA 14", nombre:"Simetría", icono:"🔷", n:6},
     {oa:"BOSS", nombre:"⚡ JEFE: Geometría", icono:"🧮", n:8, oas:["MA08 OA 11","MA08 OA 12","MA08 OA 13","MA08 OA 14"]},
   ]},
 { id:'mate-exp-datos', asignatura:'Matemáticas', nivel:'8° Básico · Probabilidad y estadística',
   portada:'assets/portada-mate-datos.png', contenido:'contenido/matematicas-8basico/preguntas.json', activa:true, campaña:'mate',
   etapas:[
     {oa:"MA08 OA 15", nombre:"Cuartiles y cajón", icono:"📊", n:6},
     {oa:"MA08 OA 16", nombre:"Gráficos honestos", icono:"📈", n:6},
     {oa:"MA08 OA 17", nombre:"Principio multiplicativo", icono:"🎲", n:6},
     {oa:"BOSS", nombre:"⚡ JEFE: Datos y azar", icono:"🧮", n:8, oas:["MA08 OA 15","MA08 OA 16","MA08 OA 17"]},
   ]},
```

- [ ] **Step 3: Poblar `capitulos` de la campaña `mate`**

Localizar en el objeto `mate` de `CAMPAÑAS` la línea:
```js
  capitulos:[],   // Matemáticas no usa expediciones; ver capitulosMate
```
Reemplazar por:
```js
  capitulos:['mate-exp-numeros','mate-exp-algebra','mate-exp-geometria','mate-exp-datos'],
```
(No tocar `capitulosMate`, `esLecciones`, `jefeFinal`.)

- [ ] **Step 4: Verificar (debe pasar)**

Recargar `http://localhost:8765/index.html` y ejecutar en `javascript_tool`:
```js
(async()=>{
 const bank=await (await fetch('contenido/matematicas-8basico/preguntas.json?'+Date.now())).json();
 const oas=new Set(bank.preguntas.map(q=>q.oa));
 const exps=EXPEDICIONES.filter(e=>e.campaña==='mate');
 const etapasOk=exps.every(e=>e.etapas.filter(x=>x.oa!=='BOSS').every(x=>oas.has(x.oa)));
 return JSON.stringify({
   exp: exps.length,
   caps: campañaPorId('mate').capitulos.length,
   nEtapas: exps.map(e=>e.etapas.length),
   todosLosOAenBanco: etapasOk
 });
})()
```
Esperado: `{"exp":4,"caps":4,"nEtapas":[6,6,5,4],"todosLosOAenBanco":true}`.

- [ ] **Step 5: Sin errores de consola**

`read_console_messages` con `onlyErrors:true` → sin errores.

- [ ] **Step 6: Commit**

```bash
git add index.html
git commit -m "Mate: 4 expediciones (banco de 603) + capitulos de la campana

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 2: Mapa intercalado enseña→desafío + gate del Jefe Final

**Files:**
- Modify: `index.html` → función `renderCampañaMate` (~líneas 2552-2577)
- Modify: `index.html` → agregar `jefeFinalMateDesbloqueado(c)` (junto a `renderCampañaMate`)

**Interfaces:**
- Consumes (ya existen): `capMateCompleto(cap)`, `expedicionCompleta(id)`, `entrarExpedicion(exp)`, `abrirCapituloMate(cap)`, `nodoCampañaEl(...)`, `portadaMapa(exp)`, `portadaFallback(exp)`, `abrirRetoCalculo()`, `iniciarJefeFinal(c)`, `QA`. Y las expediciones de Task 1 vía `c.capitulos[i]`.
- Produces: `jefeFinalMateDesbloqueado(c)` → `boolean`. El mapa de Mate ahora intercala, por unidad, nodo de lecciones + nodo de expedición.

- [ ] **Step 1: Chequeo previo (debe fallar)**

Navegar a `http://localhost:8765/index.html?qa=1`, ir a la campaña de Matemáticas (Explorar → Matemáticas) y ejecutar:
```js
document.querySelectorAll('#campNodos .camp-nodo').length
```
Esperado ANTES: `6` (4 unidades + Reto + Jefe).

- [ ] **Step 2: Reemplazar `renderCampañaMate` y agregar el gate**

Reemplazar la función `renderCampañaMate` completa por:
```js
function renderCampañaMate(c){
 CAP_MATE=null;   // no dejar un capítulo colgante de una visita anterior
 $('campHead').innerHTML=`<h1 style="font-size:26px">${c.asignatura} ${campañaCompleta(c)?'👑':''}</h1><p>${c.intro}</p>`;
 const cont=$('campNodos'); cont.innerHTML='';
 c.capitulosMate.forEach((cap,i)=>{
  const hechas=(cap.lecciones||[]).filter(id=>S.mateLecciones[id]).length;
  const tot=(cap.lecciones||[]).length;
  const lecHecho=tot>0 && hechas===tot;
  const lecAbierto=!cap.proximamente && (i===0 || capMateCompleto(c.capitulosMate[i-1]));
  const lecEstado=cap.proximamente?'🔒 Pronto':(lecHecho?'Completado':(lecAbierto?`${hechas}/${tot} lecciones`:'🔒 Bloqueado'));
  cont.appendChild(nodoCampañaEl(`${i+1}`, cap.titulo, lecAbierto, lecHecho,
    lecAbierto?()=>abrirCapituloMate(cap):null, lecEstado,
    'assets/portada-'+cap.id+'.png', c.portada));
  // Expedición de la unidad: se abre al completar sus lecciones (enseña → desafío)
  const exp=EXPEDICIONES.find(e=>e.id===c.capitulos[i]);
  if(exp){
   const expAb=QA||capMateCompleto(cap), expHecho=expedicionCompleta(exp.id);
   cont.appendChild(nodoCampañaEl('⚔️', 'Expedición · '+cap.titulo, expAb, expHecho,
     expAb?()=>entrarExpedicion(exp):null,
     expHecho?'Completada':(expAb?'¡Al desafío!':'🔒 Termina las lecciones'),
     portadaMapa(exp), portadaFallback(exp)));
  }
 });
 const reto=document.createElement('div');
 reto.className='camp-nodo';
 reto.innerHTML='<div class="cn-marco"><div class="cn-circ">⚡</div></div><div class="cn-body"><b>Reto de Cálculo</b><small>Práctica rápida · se desbloquea al aprender</small></div>';
 reto.onclick=()=>{SND.tap();abrirRetoCalculo();};
 cont.appendChild(reto);
 // Jefe Final "La Incógnita": ahora exige las 4 expediciones vencidas.
 const jfAb=jefeFinalMateDesbloqueado(c), jfHecho=campañaCompleta(c);
 cont.appendChild(nodoCampañaEl('👑','JEFE FINAL DE MATEMÁTICAS', jfAb, jfHecho,
   jfAb?()=>iniciarJefeFinal(c):null,
   jfHecho?'¡Vencido!':(jfAb?'¡Al 100%! Enfréntalo':'🔒 Vence las 4 expediciones'),
   c.jefeFinal.villanoImg||''));
}
function jefeFinalMateDesbloqueado(c){ return QA || (c.capitulos.length>0 && c.capitulos.every(expedicionCompleta)); }
```
Nota: `campañaMateCompleta` queda sin uso tras este cambio; es inofensivo dejarla.

- [ ] **Step 3: Verificar el mapa intercalado en QA (debe pasar)**

Recargar `http://localhost:8765/index.html?qa=1`, entrar a la campaña de Matemáticas y ejecutar:
```js
Array.from(document.querySelectorAll('#campNodos .camp-nodo .cn-body b')).map(b=>b.textContent)
```
Esperado (10 nodos, intercalados):
```
["Números","Expedición · Números","Álgebra y funciones","Expedición · Álgebra y funciones","Geometría","Expedición · Geometría","Probabilidad y estadística","Expedición · Probabilidad y estadística","Reto de Cálculo","JEFE FINAL DE MATEMÁTICAS"]
```

- [ ] **Step 4: Verificar el gate lecciones→expedición SIN QA**

Navegar a `http://localhost:8765/index.html` (sin `?qa=1`), y con un save nuevo simular “sin lecciones” y luego “unidad 1 completa”:
```js
S.mateLecciones={}; CAMP_ACT=campañaPorId('mate'); renderCampaña();
const antes=[...document.querySelectorAll('#campNodos .camp-nodo')][1].className;   // nodo Expedición Números
S.mateLecciones={'ma-oa01':1,'ma-oa02':1,'ma-oa03':1,'ma-oa04':1,'ma-oa05':1};
renderCampaña();
const despues=[...document.querySelectorAll('#campNodos .camp-nodo')][1].className;
JSON.stringify({antes, despues});
```
Esperado: `antes` contiene `lock` (bloqueada) y `despues` NO contiene `lock` (se abrió al completar las lecciones de la unidad). Restaurar recargando la página.

- [ ] **Step 5: Verificar que la expedición entra al mapa de etapas**

En `?qa=1`, click en el nodo “Expedición · Números” (vía `computer` o `find`), confirmar con `read_page` que aparece la pantalla del mapa de etapas (`#scr-mapa` visible) con las 5 etapas OA + jefe. `read_console_messages onlyErrors:true` → sin errores.

- [ ] **Step 6: Commit**

```bash
git add index.html
git commit -m "Mate: mapa intercalado leccion->expedicion y jefe final tras las 4 expediciones

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 3: Insignia `dif-matematicas` (Modo Difícil) sin tocar la Maestría

**Files:**
- Modify: `index.html` → `INSIGNIAS` (~línea 1169)
- Modify: `index.html` → `LOGROS` (~línea 1220)
- Modify: `index.html` → `revisarDificil` (~línea 3148)

**Interfaces:**
- Consumes (ya existen): `asignaturaDificilCompleta(asig)`, `S.insignias`, `S.insigniaActiva`, `toast(id)`, `DIF_ASIGS` (se mantiene en 3), `esMaestro()`, `asignaturasDificil()`.
- Produces: insignia `dif-matematicas` otorgada al completar las 4 expediciones de Mate en Difícil, sin alterar `asignaturasDificil()` ni `esMaestro()`.

- [ ] **Step 1: Chequeo previo (debe fallar)**

Navegar a `http://localhost:8765/index.html` y ejecutar:
```js
JSON.stringify({enInsignias: !!INSIGNIAS.find(i=>i.id==='dif-matematicas'), enLogros: !!LOGROS['dif-matematicas']})
```
Esperado ANTES: `{"enInsignias":false,"enLogros":false}`.

- [ ] **Step 2: Agregar la insignia a `INSIGNIAS`**

En el array `INSIGNIAS`, después de la línea de `dif-lenguaje`:
```js
  {id:'dif-lenguaje', ic:'🔥', tx:'Lenguaje · Difícil', asignatura:'Lenguaje'},
```
agregar:
```js
  {id:'dif-matematicas', ic:'🔥', tx:'Matemáticas · Difícil', asignatura:'Matemáticas'},
```

- [ ] **Step 3: Agregar la entrada a `LOGROS`**

En el objeto `LOGROS`, después de la línea de `dif-lenguaje`:
```js
 'dif-lenguaje':{ic:"🔥",tx:"¡Lenguaje en Difícil!"},
```
agregar:
```js
 'dif-matematicas':{ic:"🔥",tx:"¡Matemáticas en Difícil!"},
```

- [ ] **Step 4: Otorgar la insignia en `revisarDificil` (fuera de la Maestría)**

En `revisarDificil`, justo después del bloque `hechas.forEach(...)` y antes de `if(nuevo){guardar();refreshHud();}`, insertar:
```js
 // Matemáticas: insignia propia de Difícil. Se otorga aparte de DIF_ASIGS (3 core),
 // así NO entra en asignaturasDificil() ni altera la Maestría Total.
 if(asignaturaDificilCompleta('Matemáticas') && !S.insignias.has('dif-matematicas')){
  S.insignias.add('dif-matematicas'); if(S.insigniaActiva===null)S.insigniaActiva='dif-matematicas'; toast('dif-matematicas'); nuevo=true;
 }
```
No modificar `DIF_ASIGS` ni `esMaestro()`.

- [ ] **Step 5: Verificar (debe pasar) — insignia sí, Maestría intacta**

Recargar y ejecutar en `javascript_tool` (simula las 4 expediciones de Mate completas en Difícil):
```js
(function(){
 const ids=campañaPorId('mate').capitulos;
 ids.forEach(id=>{ const len=EXPEDICIONES.find(e=>e.id===id).etapas.length;
   S.rutas[id]={progreso:[], progresoDificil:Array.from({length:len},()=>({est:'done'}))}; });
 const antesMaestro=esMaestro();
 revisarDificil();
 return JSON.stringify({
   insigniaMate: S.insignias.has('dif-matematicas'),
   mateEnAsignaturasDificil: asignaturasDificil().includes('Matemáticas'),
   maestroSigueIgual: esMaestro()===antesMaestro
 });
})()
```
Esperado: `{"insigniaMate":true,"mateEnAsignaturasDificil":false,"maestroSigueIgual":true}`.
(Recargar la página al terminar para descartar el estado simulado.)

- [ ] **Step 6: Commit**

```bash
git add index.html
git commit -m "Mate: insignia dif-matematicas en Dificil (Maestria Total sin cambios)

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 4: Regresión end-to-end + dominio del profesor

**Files:**
- Ninguno (solo verificación). Si aparece un fallo, volver a la Task correspondiente.

**Interfaces:**
- Consumes: todo lo anterior + `registrarOA`, `cargarPoolMate`, `iniciarJefeFinal`.

- [ ] **Step 1: Jefe Final toma preguntas del banco de 603 (QA)**

Navegar a `http://localhost:8765/index.html?qa=1`, campaña de Matemáticas, abrir “JEFE FINAL DE MATEMÁTICAS” y arrancar. Verificar con `read_page` que aparece el diálogo de La Incógnita y luego la primera pregunta con 4 opciones. `read_console_messages onlyErrors:true` → sin errores.

- [ ] **Step 2: Las expediciones alimentan el mapa de dominio**

En `?qa=1`, entrar a “Expedición · Números”, responder la primera etapa (OA `MA08 OA 01`) y ejecutar tras terminar la etapa:
```js
JSON.stringify(Object.keys(DOM_BUF))
```
Esperado: incluye al menos `"MA08 OA 01"` (los OA reales de Mate ahora registran dominio). Confirmar que `registrarOA` NO filtra `MA08 *` (solo excluye `VOC-`/`AF-`).

- [ ] **Step 3: Regresión de las otras asignaturas y de la Maestría**

En `?qa=1`, abrir las campañas de Historia, Ciencias y Lenguaje: sus mapas se ven igual que antes (capítulos + jefe). Ejecutar:
```js
JSON.stringify({difAsigs: DIF_ASIGS, maestroDef: esMaestro.toString().includes('>=3')})
```
Esperado: `difAsigs` = `["Historia","Ciencias","Lenguaje"]` y `maestroDef` = `true` (la definición de Maestría sigue igual).

- [ ] **Step 4: Sin errores globales**

Recargar la app completa (sin QA), jugar una lección de Matemáticas y luego su expedición en Normal; `read_console_messages onlyErrors:true` → sin errores en todo el flujo.

- [ ] **Step 5: Commit final (si hubo ajustes de regresión)**

Si algún step obligó a un arreglo, commitear con mensaje descriptivo. Si no hubo cambios, no hay commit.

---

## Self-Review (cobertura de la spec)

- Estructura por unidad enseña→desafío → Task 2 (mapa intercalado, expedición bloqueada hasta las lecciones).
- Jefe Final tras las 4 expediciones → Task 2 (`jefeFinalMateDesbloqueado`).
- Modo Difícil paridad total + insignia → Task 3 (motor heredado + `dif-matematicas`).
- Maestría Total sin cambios → Task 3 (DIF_ASIGS y `esMaestro` intactos; verificado en Task 3 Step 5 y Task 4 Step 3).
- Banco de 603 en uso → Task 1 (expediciones) + Task 4 (jefe final).
- Dominio del profesor alimentado por Mate → Task 4 Step 2.
- Sin arte nuevo → Task 1 (assets reutilizados).
- Reto de Cálculo intacto → no se toca; presente en el mapa (Task 2) y sin cambios de código.
