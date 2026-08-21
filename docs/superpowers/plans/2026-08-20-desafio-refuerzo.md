# Desafío de refuerzo — Plan de implementación

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** El profesor lanza, con un clic, un desafío de refuerzo con los objetivos flojos de una asignatura; el alumno lo ve como banner en el inicio y lo juega como una cadena de preguntas; el profesor ve cuántos lo hicieron y con qué acierto.

**Architecture:** Backend nuevo en Supabase (dos tablas + cinco funciones `SECURITY DEFINER`), un bloque de refuerzo en la vista de avance de `profesor.html`, y en `index.html` un banner en el inicio + un flujo de desafío que **reutiliza el motor de quiz existente** con un flag `Q.desafio`, sin duplicarlo. La medición del desafío se guarda aparte, sin tocar el mapa de dominio (primer intento congelado).

**Tech Stack:** PostgreSQL/PostgREST (Supabase), HTML/CSS/JS vanilla. Cliente `SB` de Supabase.

**Pruebas y commits:** el proyecto no tiene framework de tests; la verificación es **en el navegador** (`preview_start` + `read_page` + `javascript_tool`) y en el **SQL Editor** de Supabase. Roberto aplica el SQL y hace el commit final con la **"orden 66"**. No hay commits por tarea.

**Referencias de código (líneas aproximadas):**
- `index.html`: `INSIGNIAS` 1064, `buildPreguntas` 1099, `pintarInicio` 1220, `startQuiz` 2402, `pintaPregunta` 2408, `responder` 2431, `avanzar` 2517, `terminarNivel` 2518, HTML `scr-rol` 512-524, `EXPEDICIONES` 876+.
- `profesor.html`: `verAvance` 535, `cabeceraAvance` 425, patrón de carga async con captura de nodo (`cargarParticipacion` 516, `conectarFilasOA`).
- `supabase/schema.sql`: `kimun_prof_es_mio`, `kimun_yo` 331-, bloque `grant execute` ~763-776.

---

## File Structure

- **`supabase/schema.sql`** — dos tablas (`desafios`, `desafio_resultados`), cinco funciones, y sus `grant`. Todo idempotente (el archivo se re-pega completo).
- **`profesor.html`** — bloque "Refuerzo" dentro de la vista de avance del curso: sugerencia + lanzar + seguimiento + cerrar. Reutiliza `kimun_prof_dominio` (ya cargado en esa vista) para elegir objetivos.
- **`index.html`** — banner `#bannerDesafio` en `scr-rol`; funciones `revisarDesafio`, `jugarDesafio`, `construirPreguntasDesafio`, `terminarDesafio`; y tres desvíos por `Q.desafio` en `pintaPregunta`, `responder`, `avanzar`. Una entrada nueva en `INSIGNIAS`.

---

## Fase 1 — Backend (Supabase)

### Task 1: Tablas `desafios` y `desafio_resultados`

**Files:**
- Modify: `supabase/schema.sql` (junto a las otras `create table if not exists`, tras `dominio`)

- [ ] **Step 1: Agregar las tablas**

```sql
-- Desafío de refuerzo: a lo más uno activo por curso. Guarda los OA, no las preguntas:
-- cada alumno juega preguntas al azar del pool (es refuerzo, no un examen calificado).
create table if not exists public.desafios (
  id         uuid primary key default gen_random_uuid(),
  curso_id   uuid not null references public.cursos(id) on delete cascade,
  asignatura text not null,
  objetivos  text[] not null,            -- {"HI08 OA 03","HI08 OA 04"}
  activo     boolean not null default true,
  creado     timestamptz not null default now()
);
-- A lo más un desafío activo por curso, garantizado en la base (no solo en el cliente).
create unique index if not exists idx_desafio_activo_curso
  on public.desafios(curso_id) where activo;

-- Resultado de cada alumno en un desafío. El primer intento manda: no se puede "mejorar"
-- reintentando (on conflict do nothing en la función de completar).
create table if not exists public.desafio_resultados (
  desafio_id uuid not null references public.desafios(id) on delete cascade,
  perfil_id  uuid not null references public.perfiles(id) on delete cascade,
  correctas  int  not null,
  total      int  not null,
  completado timestamptz not null default now(),
  primary key (desafio_id, perfil_id)
);
```

- [ ] **Step 2: Verificar (SQL Editor)**

Pegar el archivo completo y correr:
```sql
select to_regclass('public.desafios') as t1, to_regclass('public.desafio_resultados') as t2;
```
Esperado: ambas columnas no nulas.

### Task 2: Funciones del panel del profesor

**Files:**
- Modify: `supabase/schema.sql` (junto a las `kimun_prof_*`)

- [ ] **Step 1: `kimun_prof_refuerzo_lanzar`**

```sql
create or replace function public.kimun_prof_refuerzo_lanzar(p_curso_codigo text, p_asignatura text, p_objetivos text[])
returns uuid language plpgsql security definer set search_path=public as $$
declare cid uuid; nid uuid; begin
  select id into cid from public.cursos where codigo = upper(trim(p_curso_codigo));
  if cid is null or not public.kimun_prof_es_mio(cid) then raise exception 'no_autorizado'; end if;
  if p_objetivos is null or array_length(p_objetivos,1) is null then raise exception 'sin_objetivos'; end if;
  update public.desafios set activo=false where curso_id=cid and activo;   -- uno por curso
  insert into public.desafios(curso_id, asignatura, objetivos)
  values (cid, p_asignatura, p_objetivos) returning id into nid;
  return nid;
end $$;
```

- [ ] **Step 2: `kimun_prof_refuerzo_cerrar`**

```sql
create or replace function public.kimun_prof_refuerzo_cerrar(p_curso_codigo text)
returns int language plpgsql security definer set search_path=public as $$
declare cid uuid; n int; begin
  select id into cid from public.cursos where codigo = upper(trim(p_curso_codigo));
  if cid is null or not public.kimun_prof_es_mio(cid) then raise exception 'no_autorizado'; end if;
  update public.desafios set activo=false where curso_id=cid and activo;
  get diagnostics n = row_count; return n;
end $$;
```

- [ ] **Step 3: `kimun_prof_refuerzo_estado`**

```sql
drop function if exists public.kimun_prof_refuerzo_estado(text);
create or replace function public.kimun_prof_refuerzo_estado(p_curso_codigo text)
returns table(desafio_id uuid, asignatura text, objetivos text[], creado timestamptz,
              inscritos bigint, completaron bigint, correctas bigint, total bigint,
              pi_ok bigint, pi_resp bigint)
language plpgsql security definer set search_path=public as $$
declare cid uuid; begin
  select id into cid from public.cursos where codigo = upper(trim(p_curso_codigo));
  if cid is null or not public.kimun_prof_es_mio(cid) then raise exception 'no_autorizado'; end if;
  return query
   with d as (select * from public.desafios where curso_id = cid and activo limit 1)
   select d.id, d.asignatura, d.objetivos, d.creado,
     (select count(*) from public.perfiles p where p.curso_id = cid and p.codigo_acceso is not null),
     (select count(*) from public.desafio_resultados r where r.desafio_id = d.id),
     coalesce((select sum(r.correctas) from public.desafio_resultados r where r.desafio_id = d.id),0),
     coalesce((select sum(r.total)     from public.desafio_resultados r where r.desafio_id = d.id),0),
     coalesce((select sum(dm.ok_1)   from public.dominio dm join public.perfiles p on p.id = dm.perfil_id
               where p.curso_id = cid and dm.oa = any(d.objetivos)),0),
     coalesce((select sum(dm.resp_1) from public.dominio dm join public.perfiles p on p.id = dm.perfil_id
               where p.curso_id = cid and dm.oa = any(d.objetivos)),0)
   from d;
end $$;
```

El cliente calcula `acierto_curso = correctas/total` y `primer_intento = pi_ok/pi_resp`.

- [ ] **Step 4: Verificar aislamiento (SQL Editor)**

Con un curso ajeno, en la consola del navegador del profesor de prueba (o simulando el rol):
`kimun_prof_refuerzo_lanzar` sobre un curso que no es suyo debe dar `no_autorizado`. Ver Task 5.

### Task 3: Funciones del juego (alumno)

**Files:**
- Modify: `supabase/schema.sql`

- [ ] **Step 1: `kimun_refuerzo_activo`**

```sql
drop function if exists public.kimun_refuerzo_activo();
create or replace function public.kimun_refuerzo_activo()
returns table(desafio_id uuid, asignatura text, objetivos text[])
language plpgsql security definer set search_path=public as $$
declare mi uuid; cid uuid; begin
  mi := public.kimun_yo(); if mi is null then return; end if;
  select curso_id into cid from public.perfiles where id = mi;
  if cid is null then return; end if;
  return query
   select d.id, d.asignatura, d.objetivos
   from public.desafios d
   where d.curso_id = cid and d.activo
     and not exists (select 1 from public.desafio_resultados r
                     where r.desafio_id = d.id and r.perfil_id = mi)
   limit 1;
end $$;
```

- [ ] **Step 2: `kimun_refuerzo_completar`**

```sql
create or replace function public.kimun_refuerzo_completar(p_desafio_id uuid, p_correctas int, p_total int)
returns void language plpgsql security definer set search_path=public as $$
declare mi uuid; cid uuid; existe boolean; begin
  mi := public.kimun_yo(); if mi is null then return; end if;
  select curso_id into cid from public.perfiles where id = mi;
  select true into existe from public.desafios d
   where d.id = p_desafio_id and d.activo and d.curso_id = cid;
  if not existe then return; end if;   -- ajeno, inactivo o inexistente: no registra
  insert into public.desafio_resultados(desafio_id, perfil_id, correctas, total)
  values (p_desafio_id, mi, greatest(0,coalesce(p_correctas,0)), greatest(1,coalesce(p_total,1)))
  on conflict (desafio_id, perfil_id) do nothing;   -- el primer intento manda
end $$;
```

- [ ] **Step 3: Grant de las cinco funciones**

En el bloque `grant execute ... to anon, authenticated` (junto a las demás `kimun_*`), agregar:

```sql
  , public.kimun_prof_refuerzo_lanzar(text,text,text[])
  , public.kimun_prof_refuerzo_cerrar(text)
  , public.kimun_prof_refuerzo_estado(text)
  , public.kimun_refuerzo_activo()
  , public.kimun_refuerzo_completar(uuid,int,int)
```

- [ ] **Step 4: Aplicar y verificar (Roberto, SQL Editor)**

Pegar el archivo completo. Verificar:
```sql
select proname from pg_proc where proname like 'kimun_%refuerzo%' order by proname;
```
Esperado: las cinco funciones.

### Task 5: Verificación funcional del backend

- [ ] **Step 1: Lanzar y no-duplicar (SQL Editor, como servicio)**

```sql
-- reemplaza CUR-XXXX por un curso real
select public.kimun_prof_refuerzo_lanzar('CUR-XXXX','Historia', array['HI08 OA 03','HI08 OA 04']);
select public.kimun_prof_refuerzo_lanzar('CUR-XXXX','Historia', array['HI08 OA 03']);
select count(*) from public.desafios d join public.cursos c on c.id=d.curso_id
 where c.codigo='CUR-XXXX' and d.activo;   -- esperado: 1 (el segundo cerró al primero)
```

- [ ] **Step 2: Aislamiento (consola del profesor de prueba, curso ajeno)**

```js
await SB.rpc('kimun_prof_refuerzo_lanzar', { p_curso_codigo:'CUR-AJENO', p_asignatura:'Historia', p_objetivos:['HI08 OA 03'] })
```
Esperado: `error` con `no_autorizado` (status 400).

---

## Fase 2 — Panel del profesor (`profesor.html`)

### Task 6: Bloque de refuerzo en la vista de avance

**Files:**
- Modify: `profesor.html` (dentro de `verAvance`, tras pintar el mapa; funciones nuevas junto a `cargarParticipacion`)

- [ ] **Step 1: Umbral y selección de objetivos flojos (helper)**

Junto a las funciones de avance, agregar:

```js
// Objetivos flojos de una asignatura: primer intento < 70% con evidencia (>=4 alumnos),
// peores primero, tope 5. `filas` viene de kimun_prof_dominio (oa, ok_1, resp_1, alumnos_1).
function objetivosFlojos(filas, asignatura){
  const pref = {Historia:'HI08', Ciencias:'CN08', Lenguaje:'LE08'}[asignatura];
  return (filas||[])
    .filter(f => pref && f.oa.startsWith(pref) && f.resp_1 > 0 && f.alumnos_1 >= 4
                 && (f.ok_1 / f.resp_1) < 0.70)
    .sort((a,b) => (a.ok_1/a.resp_1) - (b.ok_1/b.resp_1))
    .slice(0,5);
}
```

- [ ] **Step 2: Render y carga del bloque de refuerzo**

Agregar la función que pinta el bloque y cablea sus botones (usa el texto del objetivo que la vista de avance ya resuelve desde `oa.json`, disponible en `OA_TEXTO` o equivalente; si no, muestra el código):

```js
// Bloque "Refuerzo" bajo el mapa del curso. Muestra el desafío activo (seguimiento) o,
// si no hay, la sugerencia por asignatura con botón de lanzar. Se cablea aparte para poder
// repintarse tras lanzar/cerrar sin rehacer todo el mapa.
async function cargarRefuerzo(cursoCodigo, filasDominio){
  const cont = document.getElementById('refuerzoBloque');
  if(!cont) return;
  let est=null;
  try{ const {data}=await SB.rpc('kimun_prof_refuerzo_estado',{p_curso_codigo:cursoCodigo});
       est=(data&&data[0])||null; }catch(e){ est=null; }
  if(est){
    const acierto = est.total>0 ? Math.round(est.correctas/est.total*100) : 0;
    const pi = est.pi_resp>0 ? Math.round(est.pi_ok/est.pi_resp*100) : 0;
    cont.innerHTML = `
      <h3 style="color:var(--gold);font-size:15px;margin:0 0 8px">📣 Refuerzo de ${esc(est.asignatura)} · activo</h3>
      <p style="font-size:13px;margin:0 0 8px">Lo completaron <b>${est.completaron}/${est.inscritos}</b> ·
        acierto del curso <b>${acierto}%</b> (primer intento era <b>${pi}%</b>).</p>
      <button class="btn sec" id="refCerrar">Cerrar desafío</button>`;
    document.getElementById('refCerrar').onclick=async ()=>{
      if(!confirm('¿Cerrar el desafío de refuerzo? Dejará de aparecerles a los alumnos.')) return;
      await accion(()=>SB.rpc('kimun_prof_refuerzo_cerrar',{p_curso_codigo:cursoCodigo}),'Desafío cerrado');
      cargarRefuerzo(cursoCodigo, filasDominio);
    };
    return;
  }
  const asigs=['Historia','Ciencias','Lenguaje'];
  const bloques=asigs.map(a=>{
    const objs=objetivosFlojos(filasDominio,a);
    if(!objs.length) return '';
    return `<div style="margin-bottom:10px">
      <p style="font-size:13px;margin:0 0 4px"><b>${a}</b> · ${objs.length} objetivo${objs.length===1?'':'s'} para reforzar</p>
      <button class="btn-chip refLanzar" data-asig="${a}" data-oas="${esc(objs.map(o=>o.oa).join('|'))}"
        >📣 Lanzar desafío de refuerzo de ${a}</button></div>`;
  }).filter(Boolean).join('');
  cont.innerHTML = bloques
    ? `<h3 style="color:var(--gold);font-size:15px;margin:0 0 8px">Refuerzo sugerido</h3>${bloques}`
    : '<p style="color:var(--dim);font-size:12px">No hay objetivos bajo el umbral para reforzar por ahora.</p>';
  cont.querySelectorAll('.refLanzar').forEach(b=>b.onclick=async ()=>{
    const oas=b.dataset.oas.split('|');
    if(!confirm(`¿Lanzar el desafío de refuerzo de ${b.dataset.asig}?\n\nLes aparecerá a todos los alumnos del curso.`)) return;
    await accion(()=>SB.rpc('kimun_prof_refuerzo_lanzar',
      {p_curso_codigo:cursoCodigo,p_asignatura:b.dataset.asig,p_objetivos:oas}),'Desafío lanzado');
    cargarRefuerzo(cursoCodigo, filasDominio);
  });
}
```

- [ ] **Step 3: Insertar el contenedor y llamar la carga en `verAvance`**

En `verAvance`, donde se arma el HTML de la vista, agregar `<div id="refuerzoBloque" style="margin-top:16px;border-top:1px solid #ffffff22;padding-top:12px"></div>` al final del cuerpo, y tras pintar el mapa (donde ya se tienen las filas de `kimun_prof_dominio`, guardadas en una variable — nombrarla `filasDominio` si no lo está) llamar:

```js
  cargarRefuerzo(cursoCodigo, filasDominio);
```

- [ ] **Step 4: Verificar en el navegador (banco simulado)**

Servir `profesor.html` local, stubear `SB.rpc` para `kimun_prof_dominio` (con objetivos flojos), `kimun_prof_refuerzo_estado` (primero vacío, luego activo) y `kimun_prof_refuerzo_lanzar`/`_cerrar`. Confirmar:
- Sin desafío: aparece "Refuerzo sugerido" con las asignaturas que tienen objetivos bajo 70% y su botón.
- Lanzar: el bloque pasa a "activo" con las métricas.
- Cerrar: vuelve a la sugerencia.
- Sin desborde a 375 px; sin errores de consola.

---

## Fase 3 — Juego del alumno (`index.html`)

### Task 7: Insignia y banner en el inicio

**Files:**
- Modify: `index.html` (`INSIGNIAS` 1064; HTML `scr-rol` ~519; `pintarInicio` ~1220)

- [ ] **Step 1: Nueva insignia**

En `INSIGNIAS` (1064), agregar:
```js
  {id:'mision-profe', ic:'📣', tx:'Misión del profe', asignatura:null},
```

- [ ] **Step 2: HTML del banner**

En `scr-rol`, antes de `<div class="card">` (línea ~519), insertar:
```html
    <div id="bannerDesafio" class="banner-desafio" hidden></div>
```

- [ ] **Step 3: CSS del banner**

Junto a los estilos del inicio, agregar:
```css
.banner-desafio{max-width:480px;margin:0 auto 12px;padding:12px 14px;border:2px solid var(--gold);
  border-radius:14px;background:linear-gradient(90deg,#ffc93c22,#ff4d8d22);text-align:center}
.banner-desafio h4{color:var(--gold);font-size:14px;margin:0 0 4px}
.banner-desafio p{color:#fff;font-size:12px;margin:0 0 8px}
.banner-desafio button{background:var(--violet);color:#fff;border:0;border-radius:10px;
  font-family:inherit;font-weight:900;padding:8px 16px;cursor:pointer}
```

- [ ] **Step 4: `revisarDesafio` — mostrar u ocultar el banner**

Junto a `pintarInicio`, agregar:
```js
// Consulta el desafío activo del curso del alumno y muestra el banner en el inicio si no lo
// completó. Best-effort: si el backend no responde, el banner no aparece y el juego sigue igual.
async function revisarDesafio(){
  const cont=$('bannerDesafio'); if(!cont) return;
  cont.hidden=true;
  if(!SB||!MI_PERFIL) return;
  let d=null;
  try{ const {data}=await SB.rpc('kimun_refuerzo_activo'); d=(data&&data[0])||null; }catch(e){ return; }
  if(!d) return;
  cont.innerHTML=`<h4>📣 Desafío de tu profe</h4>
    <p>Refuerzo de ${d.asignatura} · repasa lo que costó</p>
    <button id="btnDesafio">¡Jugar ahora!</button>`;
  $('btnDesafio').onclick=()=>jugarDesafio(d);
  cont.hidden=false;
}
```

- [ ] **Step 5: Llamar `revisarDesafio` donde se pinta el inicio**

Donde ya se llama `pintarInicio()` tras cargar y tras el sync de identidad (buscar las llamadas a `pintarInicio()`), agregar junto a cada una `revisarDesafio();`. También al entrar a `scr-rol` (en el manejador que vuelve al inicio).

- [ ] **Step 6: Verificar el banner (navegador)**

Servir `index.html` local, canjear un alumno de un curso con desafío activo (o stubear `kimun_refuerzo_activo`). Confirmar que el banner aparece en el inicio con la asignatura correcta, y que no aparece si no hay desafío o el alumno ya lo completó.

### Task 8: Jugar el desafío (reutiliza el motor de quiz)

**Files:**
- Modify: `index.html` (funciones nuevas junto a `startQuiz`; desvíos en `pintaPregunta` 2408, `responder` 2431, `avanzar` 2517)

- [ ] **Step 1: Construir las preguntas del desafío**

Junto a `buildPreguntas`, agregar (no toca `POOL`/`EXPEDICION` globales):
```js
// Ruta del preguntas.json de una asignatura (cualquiera de sus expediciones sirve).
function contenidoDeAsignatura(asig){
  const e=EXPEDICIONES.find(x=>x.asignatura===asig&&x.contenido);
  return e?e.contenido:null;
}
// Arma ~12 preguntas de los objetivos del desafío, repartidas por OA. Async: hace su propio
// fetch para no pisar el POOL de la expedición activa.
async function construirPreguntasDesafio(asig, objetivos){
  const url=contenidoDeAsignatura(asig); if(!url) return [];
  const pool={};
  try{ const d=await (await fetch(url)).json();
       (d.preguntas||[]).forEach(q=>{(pool[q.oa]=pool[q.oa]||[]).push(q);}); }
  catch(e){ return []; }
  const per=Math.min(6,Math.max(2,Math.round(12/objetivos.length)));
  let sel=[]; objetivos.forEach(oa=>{ sel=sel.concat(pickN(pool[oa],per)); });
  sel=pickN(sel,12);
  return sel.map(q=>({q:q.pregunta,ops:q.opciones,ok:q.correcta,tip:q.tip,oa:q.oa}));
}
```

- [ ] **Step 2: `jugarDesafio` — arrancar el quiz en modo desafío**

```js
async function jugarDesafio(d){
  const preguntas=await construirPreguntasDesafio(d.asignatura, d.objetivos);
  if(!preguntas.length){ alert('No se pudo cargar el desafío. Intenta más tarde.'); return; }
  Q={lvl:0,idx:0,aciertos:0,combo:0,comboMax:0,xpGanado:0,timer:null,t:15,lock:false,
     preguntas, desafio:{id:d.desafio_id, asignatura:d.asignatura, titulo:'Refuerzo de '+d.asignatura}};
  MODO='normal';
  go('scr-quiz'); pintaPregunta();
}
```

- [ ] **Step 3: Desvío en `pintaPregunta` (el tag)**

En `pintaPregunta` (2411), reemplazar la línea del `qTag` por:
```js
 $('qTag').textContent = Q.desafio
   ? `📣 ${Q.desafio.titulo} · Pregunta ${Q.idx+1}/${Q.preguntas.length}`
   : `${MODO==='dificil'?'🔥 ':''}${EXPEDICION[Q.lvl].icono} ${EXPEDICION[Q.lvl].nombre} · Pregunta ${Q.idx+1}/${Q.preguntas.length}`;
```

- [ ] **Step 4: Desvío en `responder` (no registrar dominio)**

En `responder` (2433), reemplazar `registrarOA(P&&P.oa, ok);` por:
```js
 if(!Q.desafio) registrarOA(P&&P.oa, ok);   // el desafío mide aparte, no toca el mapa de dominio
```

- [ ] **Step 5: Desvío en `avanzar` (terminar en modo desafío)**

En `avanzar` (2517), reemplazar por:
```js
function avanzar(){Q.idx++;if(Q.idx<Q.preguntas.length)pintaPregunta();
  else if(Q.desafio)terminarDesafio();else terminarNivel();}
```

- [ ] **Step 6: `btnBack` del quiz vuelve al inicio en modo desafío**

En el manejador `$('btnBack').onclick` (2406), reemplazar por:
```js
$('btnBack').onclick=()=>{clearInterval(Q.timer);go(Q.desafio?'scr-rol':'scr-mapa');};
```

- [ ] **Step 7: Verificar el flujo de quiz del desafío (navegador)**

Con el banner visible, tocar "¡Jugar ahora!": confirmar que arranca el quiz con ~12 preguntas, el tag dice "📣 Refuerzo de …", se puede responder, y al fallar revela la respuesta (motor normal). El mapa de dominio no debe recibir registros (revisar que `registrarOA` no se llamó: p. ej. `enviarDominio` no acumula del desafío).

### Task 9: Terminar el desafío (resultado + recompensa)

**Files:**
- Modify: `index.html` (función nueva junto a `terminarNivel`)

- [ ] **Step 1: `terminarDesafio`**

```js
function terminarDesafio(){
  const tot=Q.preguntas.length, ac=Q.aciertos, ratio=ac/tot;
  const estrellas = ratio>=1?3:(ratio>=0.80?2:(ratio>=0.66?1:0));
  S.monedas += 30;                                   // bono del refuerzo (+ los +5/acierto ya sumados)
  let insigniaNueva=false;
  if(!S.insignias.has('mision-profe')){ S.insignias.add('mision-profe');
    if(!S.insigniaActiva)S.insigniaActiva='mision-profe'; insigniaNueva=true; }
  guardar(); refreshHud();
  if(!QA && SB && MI_PERFIL){                         // en QA no registra, como el dominio
    try{ Promise.resolve(SB.rpc('kimun_refuerzo_completar',
      {p_desafio_id:Q.desafio.id,p_correctas:ac,p_total:tot})).catch(()=>{}); }catch(e){}
  }
  SND.win();
  $('resKim').src='assets/kimun-'+(estrellas>=2?'oro':estrellas===1?'plata':'bronce')+'.png';
  $('resTitle').textContent='¡Refuerzo cumplido!';
  $('resStars').innerHTML=[1,2,3].map(i=>i<=estrellas?'<span class="g">★</span>':'<span class="w">★</span>').join('');
  $('resXp').textContent='+'+Q.xpGanado;
  $('resCoins').textContent='+'+(30+ac*5);
  $('resCombo').textContent='x'+Q.comboMax;
  $('btnNext').style.display='none';
  $('btnMap').textContent='VOLVER AL INICIO';
  $('btnMap').onclick=()=>{revisarDesafio();pintarInicio();go('scr-rol');};   // el banner ya no aparecerá
  if(insigniaNueva) setTimeout(()=>toast('mision-profe'),600);
  particulas(window.innerWidth/2,window.innerHeight/3,['🎉','⭐','✨','📣'],24);
  go('scr-res');
}
```

Nota: `toast('mision-profe')` necesita una entrada en `LOGROS` para el texto del aviso. Agregar en `LOGROS` (1112): `'mision-profe':{ic:"📣",tx:"¡Misión del profe cumplida!"},`.

- [ ] **Step 2: Verificar el cierre (navegador)**

Completar el desafío: confirmar la pantalla de resultado "¡Refuerzo cumplido!", XP y monedas sumados, la insignia otorgada la primera vez (toast + aparece en el perfil), y que al "Volver al inicio" el banner **ya no aparece** (porque `kimun_refuerzo_activo` ya no lo devuelve para ese alumno). En `?qa=1`, jugar no registra (no se inserta en `desafio_resultados`).

- [ ] **Step 3: Verificar el seguimiento del profesor (extremo a extremo)**

Con la cuenta real: lanzar un desafío desde el panel, jugarlo con uno o dos alumnos reales (canje + banner + jugar), y confirmar que el panel muestra "X/N completaron" y el acierto del curso, y la comparación con el primer intento. Confirmar que el **mapa de dominio no cambió** (primer intento intacto).

---

## Self-review (cobertura del spec)

- **Sugerido + lanzar con un clic:** Fase 2, Task 6 (sugerencia por asignatura + botón). ✔
- **A todo el curso:** el desafío es por `curso_id`; `kimun_refuerzo_activo` lo entrega a cualquier alumno del curso. ✔
- **Cadena por asignatura:** `objetivosFlojos` filtra por prefijo de asignatura; `construirPreguntasDesafio` arma la cadena. ✔
- **Banner insistente, no bloquea:** Task 7 (banner en `scr-rol`, resto del juego intacto); reaparece hasta completarlo (`kimun_refuerzo_activo` excluye a quien ya tiene resultado). ✔
- **XP + monedas + insignia única:** Task 9 Step 1 (bono + insignia `mision-profe` la primera vez); XP por acierto en `responder`. ✔
- **Seguimiento (quién + acierto), medición aparte:** `kimun_prof_refuerzo_estado` + Task 6; el desafío no llama `registrarOA` (Task 8 Step 4), así que `dominio` no cambia. ✔
- **Uno por curso:** índice único parcial (Task 1) + cierre del previo en `lanzar` (Task 2). ✔
- **Aislamiento por curso:** `kimun_prof_es_mio` en las tres `kimun_prof_refuerzo_*`. ✔
- **QA no registra:** Task 9 Step 1 (`if(!QA)`). ✔
- **Consistencia de nombres:** `Q.desafio` usado en pintaPregunta/responder/avanzar/terminarDesafio; `mision-profe` en INSIGNIAS/LOGROS/terminarDesafio; funciones RPC con las mismas firmas en backend y cliente. ✔
