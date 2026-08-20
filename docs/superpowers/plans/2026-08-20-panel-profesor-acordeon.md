# Panel del profesor con acordeón — Plan de implementación

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reorganizar el panel del profesor (`profesor.html`) en un acordeón: identidad del profesor arriba, cursos plegados con titular de participación, y dentro de cada curso el avance primero y los alumnos plegables.

**Architecture:** Solo cliente. Se reescribe el render de la lista (`pintarLista`) usando `<details>/<summary>` nativos (mismo patrón que las filas de objetivos), se agrega un encabezado de identidad y una carga asíncrona del titular de participación por curso. Cero cambios de esquema o de funciones de Supabase.

**Tech Stack:** HTML/CSS/JS vanilla en un solo archivo (`profesor.html`), cliente `SB` de Supabase ya presente.

**Nota sobre pruebas y commits:** este proyecto no tiene framework de tests; la verificación es **en el navegador** (`preview_start` + `read_page` + `javascript_tool`), como en todas las sesiones. **No se hace commit por tarea**: en este proyecto el commit va con la "orden 66" de Roberto. Cada tarea termina en una verificación de navegador, no en un commit.

**Contexto de archivo (líneas de referencia en `profesor.html`):**
- HTML del panel: `cardPanel` en línea 89, `<h3 id="panelTitulo">` en 90, `<div id="lista">` en 91, `btnSalir` en 93.
- `<style>` con `.cur-head`, `.alu`, `.ico`, `.btn-chip` alrededor de las líneas 38–65.
- `cargarPanel` (275), `pintarLista` (284), `conectarAcciones` (360), `cabeceraAvance` (406), `gruposParticipacion` (439), `cargarParticipacion` (484), `volverAlPanel` (183).

---

## File Structure

Un único archivo cambia: **`profesor.html`**.
- `<style>`: nuevas reglas para `.prof-id`, `.curso`, `.alumnos` y sus `summary`.
- HTML de `cardPanel`: nuevo `<div id="profId">` antes de `panelTitulo`.
- JS: `cargarPanel` (setea la identidad), `pintarLista` (re-muestra identidad + estructura acordeón + dispara titulares), `cabeceraAvance` (oculta identidad), `conectarAcciones` (stopPropagation en 🗑️), y una función nueva `cargarTitularesParticipacion`.

---

## Task 1: Encabezado de identidad del profesor

**Files:**
- Modify: `profesor.html` (HTML de `cardPanel` ~89; `cargarPanel` ~275–282; `pintarLista` ~285; `cabeceraAvance` ~407; `<style>` ~38)

- [ ] **Step 1: Agregar el nodo de identidad en el HTML del panel**

En `profesor.html`, dentro de `<div class="card hide" id="cardPanel">` (línea 89), justo **antes** de `<h3 id="panelTitulo">Mis cursos</h3>`, insertar:

```html
  <div id="profId" class="prof-id hide"></div>
```

- [ ] **Step 2: Estilo de la identidad**

En el `<style>` (junto a las reglas existentes, p. ej. tras `.cur-head`), agregar:

```css
.prof-id{font-weight:900;color:var(--cyan);font-size:14px;margin-bottom:2px}
```

- [ ] **Step 3: Rellenar la identidad al cargar el panel**

En `cargarPanel` (línea ~279–280), después de `$('cardPanel').classList.remove('hide');` y antes de la línea de `panelTitulo`, agregar:

```js
  $('profId').textContent = '👤 ' + (YO.nombre || YO.correo) + ' — ' + (YO.es_admin ? 'Administrador' : 'Profesor');
```

- [ ] **Step 4: Mostrar la identidad al pintar la lista y ocultarla en las vistas de avance**

En `pintarLista`, junto a la línea 285 `$('panelTitulo').classList.remove('hide');`, agregar debajo:

```js
  $('profId').classList.remove('hide');
```

En `cabeceraAvance`, junto a la línea 407 `$('panelTitulo').classList.add('hide');`, agregar debajo:

```js
  $('profId').classList.add('hide');
```

- [ ] **Step 5: Verificar en el navegador**

Abrir `profesor.html` (con la cuenta real o el banco simulado del entorno de pruebas). Confirmar:
- Con `read_page`, el `#profId` muestra "👤 &lt;nombre&gt; — Administrador/Profesor" y el subtítulo "Mis cursos"/"Todos los cursos" sigue debajo.
- Al abrir una vista de avance de curso, `#profId` queda oculto (no compite con la cabecera pegada); al volver, reaparece.

---

## Task 2: CSS del acordeón

**Files:**
- Modify: `profesor.html` (`<style>` ~38–65)

- [ ] **Step 1: Agregar las reglas del acordeón**

En el `<style>`, tras las reglas de `.alu*`, agregar:

```css
/* Acordeón de cursos y de alumnos */
.curso{border:1px solid #ffffff22;border-radius:12px;margin-bottom:10px;overflow:hidden}
.curso>summary,.alumnos>summary{cursor:pointer;list-style:none;display:flex;
  align-items:center;gap:8px;flex-wrap:wrap}
.curso>summary{padding:10px}
.curso>summary::-webkit-details-marker,
.alumnos>summary::-webkit-details-marker{display:none}
.cur-chevron{color:var(--dim);font-size:12px;transition:transform .15s}
details[open]>summary>.cur-chevron{transform:rotate(90deg)}
.cur-alu{font-size:12px;color:var(--dim)}
.cur-part{font-size:12px;color:var(--cyan);flex-basis:100%;order:5}
.curso-cuerpo{padding:0 10px 10px}
.alumnos{margin-top:8px;border-top:1px solid #ffffff14}
.alumnos>summary{padding:8px 0;color:var(--cyan);font-size:13px;font-weight:700}
.alumnos-cuerpo{padding-top:4px}
```

La regla `.cur-part{flex-basis:100%;order:5}` hace que el titular de participación salte a su propia línea bajo el nombre/código, para que la cabecera no desborde en móvil. El `::-webkit-details-marker{display:none}` es el fix conocido para que Safari/iOS no muestre su triángulo nativo (usamos `.cur-chevron`).

- [ ] **Step 2: Verificar que no rompe el render actual**

Recargar `profesor.html` en el navegador. La lista todavía usa el HTML viejo (aún no reescrito), así que solo se confirma que la página carga sin errores de consola y los estilos nuevos no afectan lo existente.

---

## Task 3: Reestructurar `pintarLista` a acordeón

**Files:**
- Modify: `profesor.html` (`pintarLista` ~284–327; `conectarAcciones` ~384–387)

- [ ] **Step 1: Reemplazar el `.map` de cursos por la estructura de acordeón**

En `pintarLista`, reemplazar el bloque que arma `$('lista').innerHTML` para los cursos (líneas ~294–321, desde `$('lista').innerHTML = (cursos.length ? cursos.map(...)` hasta el `.join('')` de los cursos, **sin** tocar el fragmento final de "crear curso nuevo") por:

```js
  $('lista').innerHTML = (cursos.length ? cursos.map(([cod,c])=>`
    <details class="curso">
      <summary>
        <span class="cur-chevron" aria-hidden="true">▸</span>
        <b class="cur-nom" style="color:var(--gold)">${esc(c.nombre)}</b>
        <code>${esc(cod)}</code>
        <span class="cur-alu">${c.alumnos.length} alumno${c.alumnos.length===1?'':'s'}</span>
        <span class="cur-part" data-cod="${esc(cod)}">Participación · …</span>
        <button class="ico ico-del delcurso" data-cod="${esc(cod)}" title="Eliminar curso">🗑️</button>
      </summary>
      <div class="curso-cuerpo">
        <button class="btn-chip avance" data-cod="${esc(cod)}" data-nom="${esc(c.nombre)}"
          >📊 Ver avance del curso</button>
        <details class="alumnos">
          <summary><span class="cur-chevron" aria-hidden="true">▸</span>👥 Alumnos (${c.alumnos.length})</summary>
          <div class="alumnos-cuerpo">
            ${c.alumnos.length ? c.alumnos.map(a=>`
              <div class="alu">
                <div class="alu-top">
                  <span>${esc(a.avatar)}</span><b class="alu-nom">${esc(a.alumno)}</b>
                  <button class="ico xp" data-cod="${esc(a.codigo_acceso)}" data-xp="${esc(a.xp)}"
                          title="Fijar XP" style="color:var(--gold)">✎</button>
                  <button class="ico avalum" data-cod="${esc(a.codigo_acceso)}"
                          data-nom="${esc(a.alumno)}" title="Ver avance">📊</button>
                  <button class="ico ico-del del" data-cod="${esc(a.codigo_acceso)}"
                          title="Eliminar alumno">✕</button>
                </div>
                <div class="alu-sub"><code>${esc(a.codigo_acceso)}</code> · ${esc(a.xp)} XP</div>
              </div>`).join('')
             : '<p style="color:var(--dim);font-size:12px">Sin alumnos todavía.</p>'}
            <div style="margin-top:8px">
              <input class="in-alumno" data-curso="${esc(cod)}" placeholder="Nombre del alumno nuevo">
              <button class="btn sec add-alumno" data-curso="${esc(cod)}">+ Agregar alumno</button>
            </div>
          </div>
        </details>
      </div>
    </details>`).join('')
   : '<p style="color:var(--dim);font-size:13px">Aún no tienes cursos.</p>')
   + `<div style="margin-top:10px;border-top:1px solid #ffffff22;padding-top:12px">
        <input id="cursoNombre" placeholder="Nombre del curso nuevo (8° A)">
        <button class="btn sec" id="btnCurso">+ Crear curso</button>
      </div>`;
```

Esto mantiene los mismos `data-*` y clases (`delcurso`, `avance`, `add-alumno`, `in-alumno`, `xp`, `avalum`, `del`) que `conectarAcciones` ya cablea, así que las acciones siguen funcionando sin cambios de timing (todo el HTML existe desde el primer render; el `<details>` solo oculta visualmente).

- [ ] **Step 2: Evitar que el botón 🗑️ alterne el acordeón**

En `conectarAcciones`, la asignación de `.delcurso` (líneas ~384–387) recibe el evento para poder detener la propagación. Reemplazar ese bloque por:

```js
  document.querySelectorAll('.delcurso').forEach(b=>b.onclick=async (ev)=>{
    ev.stopPropagation(); ev.preventDefault();
    if(!confirm('¿Eliminar este curso?\n\nSe borran también todos sus alumnos y sus duelos. No se puede deshacer.')) return;
    await accion(()=>SB.rpc('kimun_prof_curso_quitar',{p_curso_codigo:b.dataset.cod}), 'Curso eliminado');
  });
```

El botón vive dentro del `<summary>`; sin `stopPropagation`/`preventDefault`, pulsarlo abriría o cerraría el curso.

- [ ] **Step 3: Verificar en el navegador**

Recargar y confirmar con `read_page` y clics simulados:
- Los cursos aparecen **plegados**; cada cabecera muestra chevron, nombre, código, "N alumnos", "Participación · …" (placeholder, se rellena en la Task 4) y 🗑️.
- Al abrir un curso: primero "📊 Ver avance del curso", luego el acordeón "👥 Alumnos (N)".
- Al abrir "Alumnos", se ven las filas (avatar, nombre, código, XP, ✎ 📊 ✕) y el campo de agregar.
- Pulsar 🗑️ **no** abre/cierra el curso (sí pide confirmación de borrado).
- Crear curso, agregar/eliminar alumno, fijar XP, ver avance del curso y del alumno: todas responden.

---

## Task 4: Titular de participación por curso (async)

**Files:**
- Modify: `profesor.html` (nueva función tras `cargarParticipacion` ~493; llamada al final de `pintarLista`)

- [ ] **Step 1: Escribir la función que rellena los titulares**

Tras `cargarParticipacion` (línea ~493), agregar:

```js
// Titular de participación en la cabecera plegada de cada curso. Una consulta por curso,
// asíncrona, para no retrasar el render de la lista. El nodo se captura ANTES del await
// (mismo patrón defensivo que cargarParticipacion): si la lista se repinta mientras una
// consulta está en vuelo, la referencia vieja queda huérfana en vez de escribir el titular
// de un curso bajo la cabecera de otro.
function cargarTitularesParticipacion(codigos){
  (codigos||[]).forEach(async cod => {
    const nodo = document.querySelector('.cur-part[data-cod="'+CSS.escape(cod)+'"]');
    if(!nodo) return;
    try{
      const {data,error} = await SB.rpc('kimun_prof_participacion',{p_curso_codigo:cod});
      if(error) throw error;
      const g = gruposParticipacion(data);
      const total = (data||[]).length;
      nodo.textContent = `Participación · ${g.semana.length}/${total} jugaron esta semana`;
    }catch(e){
      nodo.textContent = 'Participación no disponible';
    }
  });
}
```

Reutiliza `gruposParticipacion` (que ya clasifica por `visto`/`vinculado`) para contar el grupo "jugaron esta semana" sobre el total de alumnos inscritos que devuelve `kimun_prof_participacion`.

- [ ] **Step 2: Dispararla al final de `pintarLista`**

En `pintarLista`, justo después de `conectarAcciones();` (línea ~327), agregar:

```js
  cargarTitularesParticipacion(cursos.map(([cod])=>cod));
```

- [ ] **Step 3: Verificar en el navegador**

Recargar con un curso que tenga datos de participación (p. ej. `CUR-1939`). Confirmar:
- El titular pasa de "Participación · …" a "Participación · X/N jugaron esta semana" con los números correctos (contrastar con el bloque de participación de la vista de avance de ese curso).
- Con dos cursos, cada cabecera muestra su propio titular (no se cruzan).

- [ ] **Step 4: Verificar la carrera entre cursos (no-cruce)**

En la consola del navegador, simular una respuesta lenta y un repintado intermedio para confirmar que un titular tardío no escribe bajo otro curso:

```js
// Repintar la lista mientras una consulta podría estar en vuelo no debe cruzar titulares.
(async () => {
  await pintarLista();            // repinta #lista con nodos nuevos
  await new Promise(r=>setTimeout(r, 1500));
  return [...document.querySelectorAll('.cur-part')].map(n => ({ cod:n.dataset.cod, txt:n.textContent }));
})()
```

Esperado: cada `.cur-part` tiene el titular de **su** `data-cod` (o "Participación no disponible"), nunca el de otro curso.

---

## Task 5: Verificación integral en móvil

**Files:**
- Ninguno (solo verificación).

- [ ] **Step 1: Revisar a 375 px (móvil)**

Con `resize_window` a 375×812, recargar `profesor.html` y confirmar con `javascript_tool`:

```js
({ scrollW: document.documentElement.scrollWidth, viewport: window.innerWidth })
```

Esperado: `scrollW <= viewport` (sin desborde horizontal), con al menos un curso abierto y su lista de alumnos desplegada.

- [ ] **Step 2: Recorrido funcional completo**

Con la cuenta real o el banco simulado, verificar en un solo recorrido:
- Encabezado con nombre y rol del profesor (Task 1).
- Cursos plegados con titular de participación (Tasks 3 y 4).
- Abrir curso → avance primero, alumnos plegables (Task 3).
- Crear curso, agregar alumno, fijar XP, eliminar alumno, ver avance de curso y de alumno, eliminar curso.
- Como administrador: el bloque de administración (autorizar profesor, lista de profesores, 🧹 limpiar, 📊 tablero) aparece al final e intacto.
- Sin errores en `read_console_messages`.

- [ ] **Step 3: Reporte**

Resumir a Roberto lo verificado (con captura si el pane está disponible) y recordar que el commit queda pendiente de la "orden 66".

---

## Self-review (cobertura del spec)

- **Objetivo 1 (identidad del profesor):** Task 1. ✔
- **Objetivo 2 (cursos plegados con resumen):** Task 3 (estructura) + Task 4 (titular de participación) + Task 2 (CSS). ✔
- **Objetivo 3 (avance primero, alumnos plegables):** Task 3. ✔
- **No-cruce de titulares (captura antes del await):** Task 4, Steps 1 y 4. ✔
- **Fix de Safari (`::-webkit-details-marker`):** Task 2. ✔
- **🗑️ no alterna el acordeón (`stopPropagation`):** Task 3, Step 2. ✔
- **Administración intacta:** Task 5, Step 2. ✔
- **Sin cambios de servidor / esquema:** ninguna tarea toca SQL. ✔
- **Consistencia de nombres:** clase `cur-part` y `data-cod` usadas igual en Task 3 (render) y Task 4 (relleno); función `cargarTitularesParticipacion` definida en Task 4 Step 1 y llamada en Step 2. ✔
