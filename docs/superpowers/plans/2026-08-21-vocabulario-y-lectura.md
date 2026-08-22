# Vocabulario y Lectura del colegio — Plan de Implementación

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:subagent-driven-development (recomendado) o superpowers:executing-plans. Los pasos usan checkbox (`- [ ]`).

**Goal:** agregar dos módulos de estudio — un Vocabulario transversal (~100 palabras) dentro de Lenguaje y una Lectura del colegio (biblioteca; primer libro *El diario de Ana Frank*, camino de tramos de comprensión).

**Architecture:** todo data-driven sobre el motor de quiz existente. Cada módulo es una expedición de `EXPEDICIONES` cuyas etapas usan "OA de apoyo" (`VOC-*`, `AF-T#`) para indexar `POOL`. El contenido son bancos `preguntas.json` nuevos. La UI agrega un módulo "Lectura" (biblioteca) y un landing en Lenguaje. El motor de quiz NO se toca.

**Tech Stack:** HTML/CSS/JS puro (`index.html`), JSON de contenido, Python (PIL/validación) para chequear bancos, preview_start + javascript_tool para verificar en el navegador.

## Global Constraints

- **NO hacer commit hasta que Roberto diga "orden 66"** (regla del proyecto en el CLAUDE.md de kimun). Cada tarea termina en **verificación**, no en commit.
- **Español latino neutro** en todo texto visible.
- **NO reproducir texto de "El diario de Ana Frank"** — solo preguntas de comprensión originales (derechos de autor, edición Nube de Tinta).
- **No tocar el motor de quiz** ni el **rol de profesor**. Los OA de apoyo (`AF-T#`, `VOC-*`) **NO deben entrar al mapa de dominio por OA**.
- Formato de cada pregunta: `{"id","oa","pregunta","opciones":[4],"correcta":<índice 0-3>,"tip","revisada":false}`. **Opciones barajadas** (evitar sesgo de posición). Todo nace `revisada:false`.
- **No hay framework de tests**: verificación = validación de JSON con Python + chequeo en el navegador (preview_start + javascript_tool + consola sin errores).

---

### Task 1: Guard del mapa de dominio (excluir OA de apoyo)

Evita que las preguntas de Vocabulario/Lectura contaminen el mapa de dominio por OA del profesor. Se hace primero para que las pruebas posteriores no ensucien datos.

**Files:**
- Modify: `index.html` (función `registrarOA`, ~línea 2120)

**Interfaces:**
- Produces: `registrarOA(oa, ok)` ignora cualquier `oa` que empiece con `AF-` o `VOC-`.

- [ ] **Step 1: Editar `registrarOA`** — agregar el guard justo tras el `if(!oa) return;`:

```js
function registrarOA(oa, ok){
 if(QA) return;
 if(!oa) return;
 if(/^(AF-|VOC-)/.test(oa)) return;     // OA de apoyo (Vocabulario/Lectura): no van al mapa de dominio
 const d = DOM_BUF[oa] || (DOM_BUF[oa] = {n:0, ok:0});
 d.n++; if(ok) d.ok++;
}
```

- [ ] **Step 2: Verificar en el navegador**

`preview_start` (name: kimun), navegar con `?cb=1`, y en `javascript_tool`:
```js
DOM_BUF={}; registrarOA('AF-T1',true); registrarOA('VOC-HIST',true); registrarOA('HI08 OA 01',true);
JSON.stringify(Object.keys(DOM_BUF));  // esperado: ["HI08 OA 01"] (los AF-/VOC- no entran)
```
Esperado: solo el OA oficial queda en el buffer.

---

### Task 2: Banco de Vocabulario (`contenido/vocabulario/preguntas.json`)

~100 preguntas "¿Qué significa \<palabra\>?" desde todo el curso, generadas con agentes.

**Files:**
- Create: `contenido/vocabulario/preguntas.json`

**Interfaces:**
- Produces: banco con preguntas cuyo `oa` ∈ {`VOC-HIST`,`VOC-CIEN`,`VOC-MATE`,`VOC-LENG`,`VOC-LECT`}.

- [ ] **Step 1: Reunir el material fuente** — leer los `oa.json` (conceptos_clave) y una muestra de `preguntas.json` de historia/ciencias/matematicas/lenguaje, más los tramos de Ana Frank (Task 3) para `VOC-LECT`.

- [ ] **Step 2: Generar con agentes** — despachar 5 agentes en paralelo (uno por origen). Prompt de cada agente (ajustar la asignatura):

> Eres profesor de 8° básico en Chile. Genera **20 preguntas de vocabulario** de la asignatura **\<X\>** para 8° básico, en español latino neutro. Toma términos clave de esta lista/currículo: \<conceptos_clave\>. Cada pregunta: campo `oa` = "VOC-\<CODIGO\>", `pregunta` = «¿Qué significa "\<palabra\>"?» (o «¿Qué es \<palabra\>?»), `opciones` = 4 (1 definición correcta breve y clara + 3 distractores plausibles del mismo tema), `correcta` = índice 0-3 **variado** (baraja), `tip` = una frase que refuerza el significado, `revisada` = false, `id` = "voc-\<codigo\>-NNN". Devuelve JSON válido: `[ {...}, ... ]`. NO repitas palabras. Definiciones apropiadas para la edad.

- [ ] **Step 3: Consolidar** — unir los 5 arreglos en `contenido/vocabulario/preguntas.json` con cabecera:
```json
{ "asignatura":"Vocabulario","nivel":"8° básico","total_preguntas":<n>,"revisadas":0,
  "nota":"Palabras de todo el curso (4 asignaturas + lecturas). Apoyo de estudio, no OA oficial.",
  "preguntas":[ ... ] }
```

- [ ] **Step 4: Validar con Python**

```bash
python - <<'PY'
import json,collections
d=json.load(open('contenido/vocabulario/preguntas.json',encoding='utf-8'))
qs=d['preguntas']; print("total",len(qs))
print(collections.Counter(q['oa'] for q in qs))
bad=[q['id'] for q in qs if len(q['opciones'])!=4 or not(0<=q['correcta']<4) or len(set(q['opciones']))!=4]
print("con problemas:", bad or "ninguno")
print("todas revisada:false:", all(q['revisada']==False for q in qs))
PY
```
Esperado: ~100 preguntas, 5 códigos `VOC-*`, sin problemas, todas `revisada:false`.

---

### Task 3: Banco de Ana Frank (`contenido/lectura-anafrank/`)

Metadatos + tramos + preguntas de comprensión, generadas con agentes, **sin texto del libro**.

**Files:**
- Create: `contenido/lectura-anafrank/libro.json`
- Create: `contenido/lectura-anafrank/preguntas.json`

**Interfaces:**
- Produces: `libro.json` con `{titulo, autor, editorial, tramos:[{oa:"AF-T1",titulo,periodo}, ...]}` (6–8 tramos) y `preguntas.json` con preguntas cuyo `oa` ∈ {`AF-T1`…`AF-T8`}.

- [ ] **Step 1: Definir los tramos** — escribir `libro.json` con 8 tramos por período (título + descripción del período), p.ej. T1 "Antes del escondite" … T8 "El final".

- [ ] **Step 2: Generar con agentes** — un agente por tramo (paralelo). Prompt:

> Eres profesor de Lengua y Literatura de 8° básico en Chile. Genera **9 preguntas de comprensión de lectura** sobre el tramo **"\<título del tramo\>"** (\<período\>) de *El diario de Ana Frank*. **NO cites ni reproduzcas texto del libro**: son preguntas de comprensión de autoría propia (conflicto, personajes, hechos, emociones, contexto histórico, inferencia). Español latino neutro, apropiado para la edad. Cada pregunta: `oa`="AF-T\<n\>", `pregunta`, `opciones`=4 (1 correcta + 3 distractores plausibles), `correcta`=índice 0-3 **variado**, `tip`=frase breve que aclara, `revisada`=false, `id`="af-t\<n\>-NNN". Devuelve JSON válido `[ ... ]`.

- [ ] **Step 3: Consolidar** en `preguntas.json` con cabecera análoga (`"asignatura":"Lectura · El diario de Ana Frank"`).

- [ ] **Step 4: Validar con Python** (mismo script que Task 2, apuntando a este archivo; esperado ~72 preguntas, 8 códigos `AF-T#`, sin problemas). Además, un chequeo manual rápido de que ninguna pregunta transcribe frases del libro.

---

### Task 4: Expediciones de Vocabulario y Ana Frank (`EXPEDICIONES`)

**Files:**
- Modify: `index.html` (arreglo `EXPEDICIONES`, ~línea 782+)

**Interfaces:**
- Consumes: los bancos de Task 2 y 3.
- Produces: expediciones `voc-general` (etapas `VOC-*`) y `lect-anafrank` (etapas `AF-T#`), con `contenido:` a sus `preguntas.json`.

- [ ] **Step 1: Agregar la expedición de Vocabulario** al final de `EXPEDICIONES`:

```js
 { id:'voc-general', asignatura:'Vocabulario', nivel:'8° Básico · Vocabulario del curso',
   portada:'assets/portada-lenguaje.png', contenido:'contenido/vocabulario/preguntas.json', activa:true,
   etapas:[
     {oa:"VOC-HIST", nombre:"Palabras de Historia", icono:"📜", n:6},
     {oa:"VOC-CIEN", nombre:"Palabras de Ciencias", icono:"🔬", n:6},
     {oa:"VOC-MATE", nombre:"Palabras de Matemáticas", icono:"🔢", n:6},
     {oa:"VOC-LENG", nombre:"Palabras de Lenguaje", icono:"📚", n:6},
     {oa:"VOC-LECT", nombre:"Palabras de las lecturas", icono:"📖", n:6},
   ]},
```

- [ ] **Step 2: Agregar la expedición de Ana Frank**:

```js
 { id:'lect-anafrank', asignatura:'Lectura', nivel:'El diario de Ana Frank',
   portada:'assets/portada-lectura-anafrank.png', contenido:'contenido/lectura-anafrank/preguntas.json', activa:true,
   etapas:[
     {oa:"AF-T1", nombre:"Antes del escondite", icono:"🏠", n:6},
     {oa:"AF-T2", nombre:"Los primeros meses en el anexo", icono:"🚪", n:6},
     {oa:"AF-T3", nombre:"La convivencia y los roces", icono:"👥", n:6},
     {oa:"AF-T4", nombre:"El miedo y las bombas", icono:"💥", n:6},
     {oa:"AF-T5", nombre:"Crecer encerrada", icono:"🌱", n:6},
     {oa:"AF-T6", nombre:"Peter y la amistad", icono:"💛", n:6},
     {oa:"AF-T7", nombre:"Esperanza y reflexión", icono:"✨", n:6},
     {oa:"AF-T8", nombre:"El final", icono:"🕯️", n:6},
   ]},
```
(Los títulos/íconos deben coincidir con los tramos reales de `libro.json`.)

- [ ] **Step 3: Verificar que los pools cargan** — recargar y en `javascript_tool`:
```js
(async()=>{const out={};
 for(const id of ['voc-general','lect-anafrank']){
   const e=EXPEDICIONES.find(x=>x.id===id); await cargarPool(e);
   out[id]=e.etapas.map(t=>({oa:t.oa,n:(POOL[t.oa]||[]).length}));}
 return JSON.stringify(out);})()
```
Esperado: cada etapa con ≥6 preguntas en su `oa`.

---

### Task 5: Módulo Lectura (biblioteca)

**Files:**
- Modify: `index.html` — nueva pantalla `scr-biblioteca`, arreglo `LIBROS`, tarjeta en `renderExpediciones` (~2333), función `abrirBiblioteca()`.

**Interfaces:**
- Consumes: expedición `lect-anafrank`.
- Produces: tarjeta "📖 Lectura" en el menú → `abrirBiblioteca()` → lista de libros → `activarExpedicion(libro)` → `scr-mapa`.

- [ ] **Step 1: HTML** — agregar la pantalla biblioteca (junto a las otras `.screen`):
```html
  <section class="screen" id="scr-biblioteca">
    <div class="logo"><h1 style="font-size:26px">📖 Lectura</h1><p>Lecturas del colegio</p></div>
    <div class="card"><div class="exp-grid" id="biblioGrid"></div></div>
    <button class="btn sec" id="btnBiblioBack">← Volver</button>
  </section>
```

- [ ] **Step 2: Datos + render** — cerca de `renderExpediciones`:
```js
const LIBROS=[{id:'lect-anafrank', titulo:'El diario de Ana Frank', autor:'Ana Frank', tramos:8}];
function abrirBiblioteca(){
 const g=$('biblioGrid'); g.innerHTML='';
 LIBROS.forEach(lb=>{const exp=EXPEDICIONES.find(e=>e.id===lb.id);
  const card=document.createElement('div'); card.className='exp-card';
  card.innerHTML=`<img src="${exp.portada}" alt="" onerror="this.style.visibility='hidden'"><div class="exp-info"><b>${lb.titulo}</b><small>${lb.autor} · ${lb.tramos} tramos</small></div><span class="exp-go">▶</span>`;
  card.onclick=()=>{SND.tap(); entrarExpedicion(exp);};   // reusa el flujo estándar
  g.appendChild(card);});
 go('scr-biblioteca');
}
$('btnBiblioBack').onclick=()=>{SND.tap();go('scr-expediciones');};
```
(Usar la misma función con la que las asignaturas sin campaña entran a un mapa; en el código actual es la que llama `activarExpedicion`+`scr-mapa`. Verificar el nombre real —p.ej. `entrarExpedicion`— y reusarla.)

- [ ] **Step 3: Tarjeta en el menú** — al final de `renderExpediciones`, tras el `forEach(ORDEN_ASIG)`:
```js
 const bib=document.createElement('div'); bib.className='exp-card';
 bib.innerHTML=`<img src="assets/portada-lenguaje.png" alt="Lectura"><div class="exp-info"><b>📖 Lectura</b><small>Lecturas del colegio · ${LIBROS.length} libro${LIBROS.length===1?'':'s'}</small></div><span class="exp-go">▶</span>`;
 bib.onclick=()=>{SND.tap();abrirBiblioteca();};
 g.appendChild(bib);
```

- [ ] **Step 4: Verificar en el navegador** — recargar; `renderExpediciones()`; confirmar que aparece la tarjeta "Lectura"; abrir biblioteca; abrir el libro; confirmar que carga `scr-mapa` con los 8 tramos. Consola sin errores.

---

### Task 6: Vocabulario dentro de Lenguaje (landing)

**Files:**
- Modify: `index.html` — nueva pantalla `scr-lenguaje` (landing), y el onclick del módulo Lenguaje en `renderExpediciones`.

**Interfaces:**
- Consumes: expedición `voc-general` y la campaña de Lenguaje.
- Produces: al tocar Lenguaje → landing con "Campaña" y "Vocabulario".

- [ ] **Step 1: HTML del landing**:
```html
  <section class="screen" id="scr-lenguaje">
    <div class="logo"><h1 style="font-size:26px">Lenguaje</h1><p>Elige qué practicar</p></div>
    <div class="card">
      <button class="btn" id="btnLengCampana">🗺️ Campaña</button>
      <button class="btn sec" id="btnLengVocab">📚 Vocabulario</button>
    </div>
    <button class="btn sec" id="btnLengBack">← Volver</button>
  </section>
```

- [ ] **Step 2: Wiring** — cambiar el onclick de la tarjeta Lenguaje (en `renderExpediciones`) para abrir el landing en vez de la campaña directa, y cablear los botones:
```js
// en el forEach de renderExpediciones, para Lenguaje:
//   card.onclick=()=>{SND.tap(); abrirLenguaje();};
function abrirLenguaje(){ go('scr-lenguaje'); }
$('btnLengCampana').onclick=()=>{SND.tap(); abrirCampaña(campañaDe('Lenguaje'));};
$('btnLengVocab').onclick=()=>{SND.tap(); entrarExpedicion(EXPEDICIONES.find(e=>e.id==='voc-general'));};
$('btnLengBack').onclick=()=>{SND.tap(); go('scr-expediciones');};
```
(No romper el caso general: solo Lenguaje usa el landing; las demás asignaturas siguen igual.)

- [ ] **Step 3: Verificar** — tocar Lenguaje → aparece el landing; "Campaña" abre la campaña; "Vocabulario" abre `scr-mapa` con las 5 etapas; jugar una etapa (6 preguntas, estrellas/XP). Consola sin errores.

---

### Task 7: Portadas (opcional) + smoke test final

**Files:**
- (Opcional) Create: `assets/portada-lectura-anafrank.png` si Roberto genera el arte (fallback ya cubierto con `onerror`).
- Modify: `contenido/matematicas-8basico/...` — ninguno.

- [ ] **Step 1: Recorrido completo** — jugador nuevo: menú → módulo Lectura → Ana Frank → un tramo completo; menú → Lenguaje → Vocabulario → una etapa completa; y comprobar que la campaña de Lenguaje sigue accesible desde el landing.

- [ ] **Step 2: Dominio no contaminado** — tras jugar Vocab/Lectura, en `javascript_tool`: `cerrarDominio()` no debe incluir `VOC-*` ni `AF-T#`.

- [ ] **Step 3: Consola** — `read_console_messages(onlyErrors)` = sin errores (salvo 404 benignos de portadas inexistentes).

- [ ] **Step 4: Dejar listo para orden 66** — resumen de archivos nuevos/modificados; NO commitear (esperar la orden 66 de Roberto), que incluirá bitácora + `CLAUDE.md`/`README.md`.

---

## Self-Review

- **Cobertura del spec:** Vocabulario (Tasks 2,4,6) · Lectura/biblioteca (Tasks 3,4,5) · sin texto del libro (Task 3 constraint) · fuera del mapa de dominio (Task 1) · contenido con agentes revisada:false (Tasks 2,3) · reuso del motor sin tocarlo (Tasks 4-6). ✅
- **Placeholders:** los prompts de agentes y las validaciones tienen contenido concreto; los títulos de tramos/íconos se anclan a `libro.json`. ✅
- **Consistencia de tipos:** `oa` de apoyo `VOC-*`/`AF-T#` usados igual en guard, bancos y expediciones; `entrarExpedicion`/`activarExpedicion` a verificar por nombre real en Task 5/6 (nota incluida). ✅
- **Nota de ejecución:** confirmar en el código el nombre real de la función que las asignaturas sin campaña usan para entrar a un mapa (se referenció como `entrarExpedicion`) antes de reusarla.
