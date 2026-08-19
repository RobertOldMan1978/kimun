# Mapa de dominio por OA · Plan de implementación

> **Para quien ejecute este plan:** usa `superpowers:subagent-driven-development`
> (recomendado) o `superpowers:executing-plans`, tarea por tarea. Los pasos usan
> casillas (`- [ ]`) para seguimiento.

**Objetivo:** que el profesor vea, por objetivo de aprendizaje, cómo va su curso y cada
alumno, para saber qué reforzar en clase.

**Arquitectura:** el juego acumula en memoria, mientras se juega una etapa, cuántas
preguntas de cada objetivo respondió el alumno y cuántas acertó; al terminar envía un
resumen agregado. El servidor lo suma en una tabla `dominio` con una fila por alumno y
objetivo. El panel del profesor lee ese acumulado, lo cruza con el texto real de cada
objetivo y lo muestra ordenado de peor a mejor.

**Tecnología:** Supabase (PostgreSQL), JavaScript sin framework.

**Diseño de referencia:** `docs/superpowers/specs/2026-08-18-mapa-dominio-oa-design.md`

---

## Cómo se verifica en este proyecto

No hay framework de pruebas: es un sitio estático con contenido en JSON. Se verifica en el
navegador con `preview_start` + `javascript_tool`, y en el SQL Editor de Supabase. Cada
tarea define su verificación con el resultado esperado.

Roberto aplica el SQL pegando `supabase/schema.sql` **completo** en el SQL Editor; el
archivo es idempotente.

## Archivos que se tocan

| Archivo | Responsabilidad |
| --- | --- |
| `supabase/schema.sql` | Modificar: tabla `dominio` y cuatro funciones |
| `index.html` | Modificar: acumular por objetivo y enviar el resumen al terminar |
| `profesor.html` | Modificar: vista "Ver avance" del curso y del alumno |
| `CLAUDE.md` | Modificar: documentar la herramienta |

## Datos del proyecto que hacen falta

- **Los códigos de objetivo llevan el prefijo de la asignatura:** `HI08` Historia, `MA08`
  Matemática, `CN08` Ciencias, `LE08` Lenguaje. El panel usa ese prefijo para saber qué
  archivo de textos cargar.
- **Los textos están en `contenido/<asignatura>/oa.json`**, bajo la clave `oa`, como
  `{codigo, eje, unidad, texto, conceptos_clave}`.
- **Carpetas:** `historia-8basico`, `matematicas-8basico`, `ciencias-8basico`,
  `lenguaje-8basico`.

---

## Fase 1 · Backend

### Tarea 1: Tabla y registro

**Archivos:**
- Modificar: `supabase/schema.sql`

- [ ] **Paso 1: Agregar la tabla**

Insertar después de la tabla `profesores_autorizados`:

```sql
-- Dominio por objetivo de aprendizaje: una fila por alumno y OA. Se guardan
-- contadores, no respuestas: no queda registro de qué pregunta falló ni cuándo,
-- así que no se puede reconstruir la sesión de un niño.
create table if not exists public.dominio (
  perfil_id   uuid not null references public.perfiles(id) on delete cascade,
  oa          text not null,                    -- "HI08 OA 01"
  respondidas int  not null default 0,
  correctas   int  not null default 0,
  actualizado timestamptz not null default now(),
  primary key (perfil_id, oa)
);
create index if not exists idx_dominio_perfil on public.dominio(perfil_id);
```

- [ ] **Paso 2: Activar RLS**

Agregar al bloque de RLS existente:

```sql
alter table public.dominio enable row level security;
```

- [ ] **Paso 3: Agregar la función de registro**

```sql
-- Suma el resumen de una etapa terminada. Recibe [{"oa":"HI08 OA 04","n":6,"ok":4}].
-- Es acumulativa: cada llamada se suma a lo que ya había.
create or replace function public.kimun_dominio(p_datos jsonb)
returns int language plpgsql security definer set search_path=public as $$
declare mi uuid; fila jsonb; n int := 0; begin
  mi := public.kimun_yo();
  if mi is null then return 0; end if;
  if p_datos is null or jsonb_typeof(p_datos) <> 'array' then return 0; end if;
  for fila in select * from jsonb_array_elements(p_datos) loop
    -- Se ignoran las entradas mal formadas en vez de fallar: esto corre en segundo
    -- plano mientras el niño juega y nunca debe interrumpirlo.
    continue when coalesce(fila->>'oa','') = '';
    continue when coalesce((fila->>'n')::int, 0) <= 0;
    insert into public.dominio(perfil_id, oa, respondidas, correctas)
    values (mi, fila->>'oa',
            greatest(0,(fila->>'n')::int),
            least(greatest(0,coalesce((fila->>'ok')::int,0)), greatest(0,(fila->>'n')::int)))
    on conflict (perfil_id, oa) do update set
      respondidas = public.dominio.respondidas + excluded.respondidas,
      correctas   = public.dominio.correctas   + excluded.correctas,
      actualizado = now();
    n := n + 1;
  end loop;
  return n; end $$;
```

El `least`/`greatest` acota los valores: las correctas nunca pueden superar a las
respondidas ni ser negativas, por si llega un dato corrupto desde un cliente manipulado.

- [ ] **Paso 4: Otorgar permiso**

Agregar al `grant execute` final:

```sql
  , public.kimun_dominio(jsonb)
```

- [ ] **Paso 5: Aplicar y verificar**

Pegar `supabase/schema.sql` completo en el SQL Editor y ejecutar. Luego:

```sql
select count(*) from public.dominio;
```

Esperado: `0`, sin error.

- [ ] **Paso 6: Commit**

```bash
git add supabase/schema.sql
git commit -m "Dominio por OA: tabla y funcion de registro"
```

---

### Tarea 2: Lectura desde el panel

**Archivos:**
- Modificar: `supabase/schema.sql`

- [ ] **Paso 1: Agregar las tres funciones**

Insertar junto a las demás `kimun_prof_*`:

```sql
-- Dominio agregado de un curso mío, por objetivo.
create or replace function public.kimun_prof_dominio(p_curso_codigo text)
returns table(oa text, respondidas bigint, correctas bigint, alumnos bigint)
language plpgsql security definer set search_path=public as $$
declare cid uuid; begin
  select id into cid from public.cursos where codigo = upper(trim(p_curso_codigo));
  if cid is null or not public.kimun_prof_es_mio(cid) then raise exception 'no_autorizado'; end if;
  return query
    select d.oa, sum(d.respondidas), sum(d.correctas), count(distinct d.perfil_id)
    from public.dominio d
    join public.perfiles p on p.id = d.perfil_id
    where p.curso_id = cid
    group by d.oa
    order by (sum(d.correctas)::numeric / nullif(sum(d.respondidas),0)) asc nulls last, d.oa;
end $$;

-- Dominio de un alumno mío.
create or replace function public.kimun_prof_dominio_alumno(p_codigo_acceso text)
returns table(oa text, respondidas int, correctas int)
language plpgsql security definer set search_path=public as $$
declare cid uuid; pid uuid; begin
  select id, curso_id into pid, cid from public.perfiles
   where codigo_acceso = upper(trim(p_codigo_acceso));
  if pid is null or cid is null or not public.kimun_prof_es_mio(cid)
    then raise exception 'no_autorizado'; end if;
  return query
    select d.oa, d.respondidas, d.correctas from public.dominio d
    where d.perfil_id = pid
    order by (d.correctas::numeric / nullif(d.respondidas,0)) asc nulls last, d.oa;
end $$;

-- Pone en cero las mediciones de un curso mío. Devuelve cuántas filas borró.
create or replace function public.kimun_prof_dominio_reiniciar(p_curso_codigo text)
returns int language plpgsql security definer set search_path=public as $$
declare cid uuid; n int; begin
  select id into cid from public.cursos where codigo = upper(trim(p_curso_codigo));
  if cid is null or not public.kimun_prof_es_mio(cid) then raise exception 'no_autorizado'; end if;
  delete from public.dominio d
   using public.perfiles p
   where p.id = d.perfil_id and p.curso_id = cid;
  get diagnostics n = row_count;
  return n; end $$;
```

Las tres colapsan "el curso no existe" en `no_autorizado`, igual que el resto de las
funciones de profesor: distinguirlos permitiría descubrir qué códigos existen probándolos.

- [ ] **Paso 2: Otorgar permisos**

```sql
  , public.kimun_prof_dominio(text), public.kimun_prof_dominio_alumno(text),
  public.kimun_prof_dominio_reiniciar(text)
```

- [ ] **Paso 3: Aplicar y verificar el aislamiento**

Pegar el esquema y ejecutar. Desde la consola del juego (sesión anónima, sin permisos):

```js
await SB.rpc('kimun_prof_dominio',{p_curso_codigo:'CUR-XXXX'})
```

Esperado: error `no_autorizado`.

- [ ] **Paso 4: Commit**

```bash
git add supabase/schema.sql
git commit -m "Dominio por OA: lectura por curso y por alumno, con reinicio"
```

---

## Fase 2 · Registro en el juego

### Tarea 3: Acumular y enviar

**Archivos:**
- Modificar: `index.html`

- [ ] **Paso 1: Agregar el acumulador**

Insertar junto a `sincronizarXP()`:

```js
/* ===== Dominio por objetivo de aprendizaje =====
   Se acumula en memoria durante la etapa y se envía un resumen al terminarla.
   El niño no ve nada de esto y nunca se le interrumpe el juego. */
let DOM_BUF = {};                       // { "HI08 OA 04": {n:6, ok:4} }
const DOM_PEND = 'kimun_dom_pend';      // resúmenes que no se pudieron enviar

function registrarOA(oa, ok){
  if(QA) return;                        // el modo QA marca las respuestas: no mide nada
  if(!oa) return;
  const d = DOM_BUF[oa] || (DOM_BUF[oa] = {n:0, ok:0});
  d.n++; if(ok) d.ok++;
}

// Convierte el acumulador en el arreglo que espera el servidor y lo vacía.
function cerrarDominio(){
  const datos = Object.keys(DOM_BUF).map(oa => ({oa, n:DOM_BUF[oa].n, ok:DOM_BUF[oa].ok}));
  DOM_BUF = {};
  return datos;
}

async function enviarDominio(){
  let datos = cerrarDominio();
  // Se suman los resúmenes que quedaron pendientes de un intento anterior.
  try{ const p = JSON.parse(localStorage.getItem(DOM_PEND)||'[]');
       if(Array.isArray(p) && p.length) datos = p.concat(datos); }catch(e){}
  if(!datos.length) return;
  if(!SB || !MI_PERFIL){ guardarPendiente(datos); return; }
  try{
    const {error} = await SB.rpc('kimun_dominio',{p_datos:datos});
    if(error) throw error;
    localStorage.removeItem(DOM_PEND);
  }catch(e){
    console.error('Dominio:', e.message||e);
    guardarPendiente(datos);            // se reintenta al terminar la próxima etapa
  }
}

function guardarPendiente(datos){
  // Se acota para que un teléfono sin conexión durante días no acumule sin límite.
  try{ localStorage.setItem(DOM_PEND, JSON.stringify(datos.slice(-200))); }catch(e){}
}
```

- [ ] **Paso 2: Registrar cada respuesta del quiz**

En `responder(el,ok,P,e)` (`index.html:2383`), agregar como primera línea después de la
guarda de bloqueo:

```js
function responder(el,ok,P,e){
 if(Q.lock)return;Q.lock=true;clearInterval(Q.timer);
 registrarOA(P&&P.oa, ok);
```

- [ ] **Paso 3: Registrar cada respuesta del jefe**

En `responderJefe(el,ok)` (`index.html:1957`), donde `JF.preguntas[JF.idx]` es la pregunta
en curso:

```js
function responderJefe(el,ok){
 if(JF.lock)return; JF.lock=true;
 registrarOA(JF.preguntas[JF.idx] && JF.preguntas[JF.idx].oa, ok);
```

- [ ] **Paso 4: Enviar al terminar la etapa**

En `terminarNivel()` (`index.html:2469`), junto a la línea `refreshHud();guardar();` que
está cerca del final:

```js
 refreshHud();guardar();enviarDominio();
```

- [ ] **Paso 5: Enviar al terminar el jefe**

Buscar la línea `go('scr-jefe-win');` (`index.html:2018`) y agregar antes:

```js
 enviarDominio();
 go('scr-jefe-win');
```

Y en la derrota, para no perder lo que sí respondió. En `responderJefe` la derrota se
dispara en `index.html:1971`:

```js
  if(JF.vidas<=0){ enviarDominio(); return jefeDerrota(); }
```

Nota: `jefeVictoria()` (`index.html:1987`) llama a `renderJefeVictoria()`, que es la que
termina en `go('scr-jefe-win')`. Poner el envío en la línea anterior a ese `go` cubre la
victoria, y esta línea cubre la derrota. Un jefe abandonado a media pelea no envía nada:
es una pérdida aceptable frente a complicar el flujo.

- [ ] **Paso 6: Verificar que se acumula bien**

Levantar el servidor (`preview_start` con `{name:"kimun"}`) y, en la consola:

```js
DOM_BUF = {}; registrarOA('HI08 OA 01', true); registrarOA('HI08 OA 01', false);
registrarOA('HI08 OA 02', true); JSON.stringify(cerrarDominio())
```

Esperado: `[{"oa":"HI08 OA 01","n":2,"ok":1},{"oa":"HI08 OA 02","n":1,"ok":1}]`.

- [ ] **Paso 7: Verificar que el modo QA no registra**

Abrir `http://localhost:8765/?qa=1` y en la consola:

```js
DOM_BUF = {}; registrarOA('HI08 OA 01', true); JSON.stringify(DOM_BUF)
```

Esperado: `{}`.

- [ ] **Paso 8: Verificar de punta a punta**

Sin `?qa=1`, jugar una etapa completa de una campaña anotando cuántas se acertaron. Luego,
en el SQL Editor:

```sql
select oa, respondidas, correctas from public.dominio order by actualizado desc limit 5;
```

Esperado: los objetivos de esa etapa con exactamente los números de la partida.

- [ ] **Paso 9: Verificar el reintento sin conexión**

En la consola: `SB.rpc = () => Promise.reject(new Error('offline'));` luego jugar una etapa.
Comprobar que `localStorage.getItem('kimun_dom_pend')` tiene contenido y que el juego no se
interrumpió. Recargar y jugar otra etapa: la tabla debe recibir la suma de ambas.

- [ ] **Paso 10: Commit**

```bash
git add index.html
git commit -m "Dominio por OA: registrar y enviar el resumen de cada etapa"
```

---

## Fase 3 · La vista del profesor

### Tarea 4: Ver avance del curso

**Archivos:**
- Modificar: `profesor.html`

- [ ] **Paso 1: Agregar la carga de textos de objetivos**

Los códigos traen el prefijo de la asignatura, y el texto vive en el `oa.json` de cada
carpeta. Insertar junto a los demás helpers:

```js
/* Textos de los objetivos de aprendizaje. El código HI08 OA 01 no le dice nada a
   nadie: sin el texto real, la tabla es ilegible para un profesor. */
const OA_CARPETA = {HI08:'historia-8basico', MA08:'matematicas-8basico',
                    CN08:'ciencias-8basico', LE08:'lenguaje-8basico'};
const OA_TEXTO = {};        // "HI08 OA 01" -> "Analizar, apoyándose en diversas fuentes…"
const OA_CARGADA = {};      // carpetas ya pedidas

async function cargarTextosOA(codigos){
  const carpetas = [...new Set(codigos.map(c => OA_CARPETA[String(c).slice(0,4)]).filter(Boolean))];
  await Promise.all(carpetas.map(async carpeta => {
    if(OA_CARGADA[carpeta]) return;
    OA_CARGADA[carpeta] = true;
    try{
      const r = await fetch('contenido/'+carpeta+'/oa.json');
      if(!r.ok) return;
      const d = await r.json();
      (d.oa||[]).forEach(o => { if(o && o.codigo) OA_TEXTO[o.codigo] = o.texto || o.codigo; });
    }catch(e){ console.error('OA:', e.message||e); }
  }));
}
```

- [ ] **Paso 2: Agregar el botón en cada curso**

En `pintarLista()`, junto al botón de eliminar curso:

```html
      <button class="mini avance" data-cod="${esc(cod)}"
              style="background:none;border:0;color:var(--cyan);font-weight:900;cursor:pointer">📊 Ver avance</button>
```

- [ ] **Paso 3: Agregar la vista**

```js
// Tabla de dominio, ordenada de peor a mejor: lo que hay que reforzar queda arriba.
async function verAvance(cursoCodigo){
  aviso('Cargando…','var(--dim)');
  try{
    const {data,error} = await SB.rpc('kimun_prof_dominio',{p_curso_codigo:cursoCodigo});
    if(error) throw error;
    if(!data || !data.length){
      $('lista').innerHTML = `<p style="color:var(--dim);font-size:13px">
        Todavía no hay datos de este curso. Aparecen cuando los alumnos juegan las campañas.</p>
        <button class="btn sec" id="btnVolverPanel">← Volver</button>`;
      $('btnVolverPanel').onclick = pintarLista; aviso(''); return;
    }
    await cargarTextosOA(data.map(f => f.oa));
    $('lista').innerHTML = `
      <p style="color:var(--dim);font-size:12px;margin-bottom:10px">
        Porcentaje de acierto por objetivo, de menor a mayor. <b>No sirve para calificar:</b>
        el dato lo reporta el teléfono del alumno. Úsalo para decidir qué reforzar.</p>
      ${data.map(f => filaAvance(f.oa, f.respondidas, f.correctas)).join('')}
      <div style="margin-top:14px">
        <button class="btn sec" id="btnReiniciarMed">🔄 Reiniciar mediciones</button>
        <button class="btn sec" id="btnVolverPanel">← Volver</button>
      </div>`;
    $('btnVolverPanel').onclick = pintarLista;
    $('btnReiniciarMed').onclick = () => reiniciarMediciones(cursoCodigo);
    aviso('');
  }catch(e){ aviso(traducir(e)); }
}

// Una fila: texto del objetivo, barra, porcentaje y cuántas preguntas lo respaldan.
function filaAvance(oa, respondidas, correctas){
  const n = Number(respondidas)||0, ok = Number(correctas)||0;
  const pct = n ? Math.round(ok*100/n) : 0;
  const flojo = n < 10;                       // base pequeña: el porcentaje dice poco
  const color = pct >= 75 ? 'var(--green)' : pct >= 50 ? 'var(--gold)' : 'var(--pink)';
  return `<div style="padding:8px 0;border-bottom:1px solid #ffffff14;opacity:${flojo?0.55:1}">
    <div style="font-size:13px;margin-bottom:4px">${esc(OA_TEXTO[oa]||oa)}</div>
    <div style="display:flex;align-items:center;gap:8px">
      <div style="flex:1;height:8px;background:#ffffff14;border-radius:4px;overflow:hidden">
        <div style="width:${pct}%;height:100%;background:${color}"></div>
      </div>
      <b style="color:${color};min-width:42px;text-align:right">${pct}%</b>
      <small style="color:var(--dim);min-width:96px;text-align:right">${n} pregunta${n===1?'':'s'}</small>
    </div>
  </div>`;
}

async function reiniciarMediciones(cursoCodigo){
  if(!confirm('¿Reiniciar las mediciones de este curso?\n\n'+
    'Los porcentajes vuelven a cero y se empieza a medir de nuevo. Sirve al comenzar una '+
    'unidad o un semestre. No se borra ningún alumno ni su XP, pero las mediciones '+
    'anteriores no se pueden recuperar.')) return;
  try{
    const {error} = await SB.rpc('kimun_prof_dominio_reiniciar',{p_curso_codigo:cursoCodigo});
    if(error) throw error;
    await verAvance(cursoCodigo);
    aviso('Mediciones reiniciadas','var(--green)');
  }catch(e){ aviso(traducir(e)); }
}
```

- [ ] **Paso 4: Conectar el botón**

En `conectarAcciones()`:

```js
  document.querySelectorAll('.avance').forEach(b=>b.onclick=()=>verAvance(b.dataset.cod));
```

- [ ] **Paso 5: Verificar**

Entrar al panel con la cuenta de administrador, pulsar "📊 Ver avance" en un curso donde
algún alumno haya jugado.

Esperado: la tabla con el **texto** de cada objetivo (no el código), ordenada de peor a
mejor, con la barra de color y el número de preguntas. Los objetivos con menos de diez
preguntas se ven atenuados. "← Volver" regresa al panel.

- [ ] **Paso 6: Verificar el curso sin datos**

Crear un curso nuevo y pulsar "Ver avance".
Esperado: el mensaje "Todavía no hay datos de este curso…", sin errores.

- [ ] **Paso 7: Verificar que solo aparecen los objetivos jugados**

En la tabla del curso, contar cuántos objetivos se listan y compararlo con el total de la
asignatura (Historia tiene 22).
Esperado: aparecen **solo** los que algún alumno jugó. Un objetivo sin datos no debe figurar
como 0%, porque se leería como "no lo entienden" cuando en realidad es "no lo han visto".

- [ ] **Paso 8: Verificar que el reinicio no toca otros cursos**

Con dos cursos que tengan datos, reiniciar las mediciones de uno y abrir el avance del otro.
Esperado: el segundo curso conserva sus porcentajes intactos.

- [ ] **Paso 9: Commit**

```bash
git add profesor.html
git commit -m "Panel: ver avance del curso por objetivo de aprendizaje"
```

---

### Tarea 5: Ver avance de un alumno

**Archivos:**
- Modificar: `profesor.html`

- [ ] **Paso 1: Agregar el botón en cada alumno**

En la fila de alumno de `pintarLista()`, junto a los botones ✎ y ✕:

```html
          <button class="mini avalum" data-cod="${esc(a.codigo_acceso)}"
                  style="background:none;border:0;color:var(--cyan);font-weight:900;cursor:pointer">📊</button>
```

- [ ] **Paso 2: Agregar la vista del alumno**

```js
async function verAvanceAlumno(codigoAcceso){
  aviso('Cargando…','var(--dim)');
  try{
    const {data,error} = await SB.rpc('kimun_prof_dominio_alumno',{p_codigo_acceso:codigoAcceso});
    if(error) throw error;
    if(!data || !data.length){
      $('lista').innerHTML = `<p style="color:var(--dim);font-size:13px">
        Este alumno todavía no tiene datos. Aparecen cuando juega las campañas.</p>
        <button class="btn sec" id="btnVolverPanel">← Volver</button>`;
      $('btnVolverPanel').onclick = pintarLista; aviso(''); return;
    }
    await cargarTextosOA(data.map(f => f.oa));
    $('lista').innerHTML = `
      <p style="color:var(--dim);font-size:12px;margin-bottom:10px">
        Objetivos de este alumno, de menor a mayor acierto.</p>
      ${data.map(f => filaAvance(f.oa, f.respondidas, f.correctas)).join('')}
      <button class="btn sec" id="btnVolverPanel" style="margin-top:14px">← Volver</button>`;
    $('btnVolverPanel').onclick = pintarLista;
    aviso('');
  }catch(e){ aviso(traducir(e)); }
}
```

- [ ] **Paso 3: Conectar el botón**

En `conectarAcciones()`:

```js
  document.querySelectorAll('.avalum').forEach(b=>b.onclick=()=>verAvanceAlumno(b.dataset.cod));
```

- [ ] **Paso 4: Verificar**

Pulsar 📊 en un alumno que haya jugado.
Esperado: sus objetivos con sus propios porcentajes, con el mismo formato que el curso.

- [ ] **Paso 5: Verificar el aislamiento**

Desde la sesión de un profesor **distinto**, en la consola:

```js
await SB.rpc('kimun_prof_dominio_alumno',{p_codigo_acceso:'<ALU- de un alumno ajeno>'})
```

Esperado: error `no_autorizado`.

- [ ] **Paso 6: Commit**

```bash
git add profesor.html
git commit -m "Panel: ver avance de un alumno por objetivo"
```

---

### Tarea 6: Documentación

**Archivos:**
- Modificar: `CLAUDE.md`

- [ ] **Paso 1: Documentar la herramienta**

En la sección de cursos y profesores, agregar una subsección **Mapa de dominio por OA** que
explique: que el profesor entra por "📊 Ver avance" en cada curso y por 📊 en cada alumno;
que mide **solo las campañas y los jefes**, no el duelo ni el Reto de Cálculo; que el modo
QA no registra nada; que se guardan contadores por alumno y objetivo, no respuestas; que el
botón de reinicio existe porque los contadores acumulan todo el año; y que **no sirve para
calificar**, porque el dato lo reporta el teléfono del alumno.

- [ ] **Paso 2: Commit**

```bash
git add CLAUDE.md
git commit -m "Documentar el mapa de dominio por OA"
```

---

## Notas para quien ejecute

- **El SQL lo aplica Roberto**, pegando `supabase/schema.sql` completo en el SQL Editor.
- **El orden importa:** sin la Fase 1 aplicada, la Fase 2 no tiene dónde escribir y la Fase 3
  no tiene qué leer.
- **La verificación de punta a punta (Tarea 3, Paso 8) es la que importa.** Que los números
  de la tabla coincidan exactamente con lo jugado es lo único que prueba que la medición
  sirve; el resto son detalles de presentación.
- Este registro corre en segundo plano mientras un niño juega: **nada de lo que se agregue
  aquí puede interrumpir la partida**. Todas las llamadas van dentro de `try`/`catch` y
  fallan en silencio.
