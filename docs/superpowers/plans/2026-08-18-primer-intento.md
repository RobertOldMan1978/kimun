# Primer intento · Plan de implementación

> **Para quien ejecute este plan:** usa `superpowers:subagent-driven-development`
> (recomendado) o `superpowers:executing-plans`, tarea por tarea. Los pasos usan
> casillas (`- [ ]`) para seguimiento.

**Objetivo:** que el porcentaje del mapa de dominio signifique "cuántos acertaron la primera
vez que vieron este contenido", en vez de un acumulado que el alumno que menos sabe infla
con sus reintentos.

**Arquitectura:** dos columnas nuevas en la tabla `dominio` que solo se escriben la primera
vez que un alumno toca un objetivo. El juego no cambia: sigue enviando el mismo resumen. Las
funciones de lectura devuelven ambos pares de contadores y el panel muestra el del primer
intento, con los reintentos como dato aparte.

**Tecnología:** Supabase (PostgreSQL), JavaScript sin framework.

**Diseño de referencia:** `docs/superpowers/specs/2026-08-18-primer-intento-design.md`

---

## Cómo se verifica en este proyecto

No hay framework de pruebas: es un sitio estático. Se verifica en el navegador con
`preview_start` + `javascript_tool`, y en el SQL Editor de Supabase. Roberto aplica el SQL
pegando `supabase/schema.sql` **completo**; el archivo es idempotente.

## Archivos que se tocan

| Archivo | Responsabilidad |
| --- | --- |
| `supabase/schema.sql` | Modificar: dos columnas y tres funciones |
| `profesor.html` | Modificar: `filaAvance`, y los dos lugares que la llaman |
| `CLAUDE.md` | Modificar: documentar qué significa el número |

**`index.html` NO se toca.** Es la característica más valiosa de este cambio: el juego sigue
enviando exactamente el mismo resumen.

---

## Fase 1 · Backend

### Tarea 1: Congelar el primer intento

**Archivos:**
- Modificar: `supabase/schema.sql`

- [ ] **Paso 1: Agregar las columnas**

Junto a la definición de la tabla `dominio`:

```sql
-- Primer contacto con el objetivo: se escriben una sola vez y no se vuelven a tocar.
-- Sin esto, el porcentaje queda sesgado: "respondidas" crece con los reintentos, y se
-- reintenta porque no se entendió, así que el alumno que menos sabe pesa más en el
-- promedio del curso.
alter table public.dominio add column if not exists resp_1 int not null default 0;
alter table public.dominio add column if not exists ok_1   int not null default 0;
```

- [ ] **Paso 2: Llenarlas solo al insertar**

En `kimun_dominio`, la sentencia `insert` pasa a incluirlas, y el `on conflict do update`
**no las menciona**. Reemplazar el bloque del insert por:

```sql
    insert into public.dominio(perfil_id, oa, respondidas, correctas, resp_1, ok_1)
    values (mi, fila->>'oa',
            greatest(0,(fila->>'n')::int),
            least(greatest(0,coalesce((fila->>'ok')::int,0)), greatest(0,(fila->>'n')::int)),
            greatest(0,(fila->>'n')::int),
            least(greatest(0,coalesce((fila->>'ok')::int,0)), greatest(0,(fila->>'n')::int)))
    -- El "do update" NO toca resp_1 ni ok_1: esa es toda la idea. La primera vez que un
    -- alumno responde un objetivo es necesariamente un insert, así que quedan congeladas
    -- en su primer contacto.
    on conflict (perfil_id, oa) do update set
      respondidas = dominio.respondidas + excluded.respondidas,
      correctas   = dominio.correctas   + excluded.correctas,
      actualizado = now();
```

- [ ] **Paso 3: Aplicar y verificar el congelado**

Pegar `supabase/schema.sql` completo en el SQL Editor y ejecutar. Después, desde la consola
del juego con un alumno canjeado, la comprobación central de este plan:

```js
// Primer contacto: 6 respondidas, 4 correctas
await SB.rpc('kimun_dominio',{p_datos:[{oa:'HI08 OA 01',n:6,ok:4}]});
// Repetición: 6 más, todas correctas
await SB.rpc('kimun_dominio',{p_datos:[{oa:'HI08 OA 01',n:6,ok:6}]});
```

Y en el SQL Editor:

```sql
select oa, respondidas, correctas, resp_1, ok_1 from public.dominio
 where oa = 'HI08 OA 01' order by actualizado desc limit 1;
```

Esperado: `respondidas = 12`, `correctas = 10`, y **`resp_1 = 6`, `ok_1 = 4`**. Si `resp_1`
subió a 12, el `do update` los está tocando y el cambio no sirve.

- [ ] **Paso 4: Commit**

```bash
git add supabase/schema.sql
git commit -m "Dominio: congelar el primer intento en resp_1 y ok_1"
```

---

### Tarea 2: Devolver el primer intento en las lecturas

**Archivos:**
- Modificar: `supabase/schema.sql`

- [ ] **Paso 1: Reemplazar `kimun_prof_dominio`**

Cambia la lista de columnas, así que necesita el `drop function if exists` que ya lleva
delante. La versión nueva:

```sql
drop function if exists public.kimun_prof_dominio(text);
create or replace function public.kimun_prof_dominio(p_curso_codigo text)
returns table(oa text, respondidas bigint, correctas bigint, alumnos bigint,
              resp_1 bigint, ok_1 bigint, alumnos_1 bigint)
language plpgsql security definer set search_path=public as $$
declare cid uuid; begin
  select id into cid from public.cursos where codigo = upper(trim(p_curso_codigo));
  if cid is null or not public.kimun_prof_es_mio(cid) then raise exception 'no_autorizado'; end if;
  return query
    select d.oa, sum(d.respondidas), sum(d.correctas), count(distinct d.perfil_id),
           sum(d.resp_1), sum(d.ok_1),
           -- Cuántos alumnos aportaron un primer intento: es el número que decide si el
           -- porcentaje es creíble, y no es lo mismo que cuántos hay en el curso.
           count(distinct d.perfil_id) filter (where d.resp_1 > 0)
    from public.dominio d
    join public.perfiles p on p.id = d.perfil_id
    where p.curso_id = cid
    group by d.oa
    order by (sum(d.ok_1)::numeric / nullif(sum(d.resp_1),0)) asc nulls last, d.oa;
end $$;
```

El orden pasa a calcularse sobre el primer intento, que es el número que se muestra.

- [ ] **Paso 2: Reemplazar `kimun_prof_dominio_alumno`**

```sql
drop function if exists public.kimun_prof_dominio_alumno(text);
create or replace function public.kimun_prof_dominio_alumno(p_codigo_acceso text)
returns table(oa text, respondidas int, correctas int, resp_1 int, ok_1 int)
language plpgsql security definer set search_path=public as $$
declare cid uuid; pid uuid; begin
  select id, curso_id into pid, cid from public.perfiles
   where codigo_acceso = upper(trim(p_codigo_acceso));
  if pid is null or cid is null or not public.kimun_prof_es_mio(cid)
    then raise exception 'no_autorizado'; end if;
  return query
    select d.oa, d.respondidas, d.correctas, d.resp_1, d.ok_1 from public.dominio d
    where d.perfil_id = pid
    order by (d.ok_1::numeric / nullif(d.resp_1,0)) asc nulls last, d.oa;
end $$;
```

- [ ] **Paso 3: Aplicar y verificar**

Pegar el esquema y ejecutar. Con la sesión de profesor, en la consola de `profesor.html`:

```js
const {data} = await SB.rpc('kimun_prof_dominio',{p_curso_codigo:'CUR-XXXX'});
console.log(data[0]);
```

Esperado: el objeto trae `respondidas`, `correctas`, `alumnos`, `resp_1`, `ok_1` y
`alumnos_1`.

- [ ] **Paso 4: Commit**

```bash
git add supabase/schema.sql
git commit -m "Dominio: las lecturas devuelven el primer intento y su base de alumnos"
```

---

## Fase 2 · El panel

### Tarea 3: Mostrar el primer intento

**Archivos:**
- Modificar: `profesor.html`

- [ ] **Paso 1: Reemplazar `filaAvance` completa**

La versión actual recibe `(oa, respondidas, correctas)`. La nueva recibe la fila entera,
porque ahora necesita cinco datos:

```js
// Una fila del mapa. El porcentaje es el del PRIMER intento: cuántos acertaron la primera
// vez que vieron ese contenido. El acumulado con reintentos se muestra aparte, como señal
// de cuánto costó, porque mezclarlos sesga el número (quien no entiende reintenta, y así
// pesa más en el promedio del curso).
function filaAvance(f){
  const r1 = Number(f.resp_1)||0, o1 = Number(f.ok_1)||0;
  const total = Number(f.respondidas)||0;
  const alumnos = Number(f.alumnos_1 != null ? f.alumnos_1 : f.alumnos)||0;
  const reintentos = Math.max(0, total - r1);
  const pct = r1 ? Math.round(o1*100/r1) : 0;
  // Cortes calibrados al piso del azar: con 4 opciones, responder sin saber da 25%.
  // Un 50% no es "la mitad": es un tercio de dominio real.
  const color = pct >= 70 ? 'var(--green)' : pct >= 45 ? 'var(--gold)' : 'var(--pink)';
  // En la vista de curso el respaldo son los alumnos; en la de un alumno concreto no hay
  // tal conteo, así que se muestran sus preguntas de primer intento.
  const base = alumnos ? `${alumnos} alumno${alumnos===1?'':'s'}`
             : r1     ? `${r1} pregunta${r1===1?'':'s'}`
             : 'sin primer intento';
  const detalle = base + (reintentos ? ` · ${reintentos} reintento${reintentos===1?'':'s'}` : '');
  return `<div style="padding:8px 0;border-bottom:1px solid #ffffff14">
    <div style="font-size:13px;margin-bottom:4px">${esc(OA_TEXTO[f.oa]||f.oa)}</div>
    <div style="display:flex;align-items:center;gap:8px">
      <div style="flex:1;height:8px;background:#ffffff14;border-radius:4px;overflow:hidden">
        <div style="width:${pct}%;height:100%;background:${color}"></div>
      </div>
      <b style="color:${color};min-width:42px;text-align:right">${pct}%</b>
      <small style="color:var(--dim);min-width:120px;text-align:right">${detalle}</small>
    </div>
  </div>`;
}
```

Nota: ya no lleva `opacity`. La base sale del orden, no de la transparencia — el paso
siguiente explica por qué.

- [ ] **Paso 2: Agrupar en tres bloques**

Agregar junto a `filaAvance`:

```js
// Separa por base en vez de atenuar. Ordenar de peor a mejor y a la vez atenuar las bases
// pequeñas se peleaba: la posición decía "mira esto primero" y la opacidad decía "ignora
// esto", de modo que la primera fila podía ser justo la menos confiable.
function bloquesAvance(data){
  const conBase = data.filter(f => (Number(f.alumnos_1)||0) >= 10);
  const sinBase = data.filter(f => (Number(f.alumnos_1)||0) <  10);
  const pctDe = f => (Number(f.resp_1)||0) ? (Number(f.ok_1)||0)*100/(Number(f.resp_1)||1) : 0;
  const reforzar = conBase.filter(f => pctDe(f) <  70);
  const bien     = conBase.filter(f => pctDe(f) >= 70);
  const seccion = (titulo, filas, plegada) => !filas.length ? '' : `
    <details ${plegada?'':'open'} style="margin-bottom:10px">
      <summary style="color:var(--cyan);font-size:13px;cursor:pointer;padding:6px 0">
        ${titulo} (${filas.length})</summary>
      ${filas.map(filaAvance).join('')}
    </details>`;
  return seccion('Para reforzar', reforzar, false)
       + seccion('Van bien', bien, false)
       + seccion('Todavía con pocos datos', sinBase, true);
}
```

- [ ] **Paso 3: Usar los bloques en las dos vistas**

En `verAvance`, reemplazar la línea que hoy dice
`${data.map(f => filaAvance(f.oa, f.respondidas, f.correctas)).join('')}` por:

```js
      ${bloquesAvance(data)}
```

En `verAvanceAlumno`, como un alumno no tiene "base de alumnos", se listan sus objetivos sin
agrupar, pero con la misma fila:

```js
      ${data.map(filaAvance).join('')}
```

- [ ] **Paso 4: Explicar el número en el aviso**

Reemplazar la constante `AVISO_NO_CALIFICA` por:

```js
const AVISO_NO_CALIFICA = 'El porcentaje es del <b>primer intento</b>: cuántos acertaron la '+
  'primera vez que vieron ese contenido. <b>No sirve para calificar:</b> el dato lo reporta '+
  'el teléfono del alumno. Ten en cuenta que, con cuatro opciones por pregunta, responder '+
  'al azar da 25%.';
```

- [ ] **Paso 5: Advertir que Matemáticas no se mide**

El mapa cubre tres de las cuatro asignaturas: el Reto de Cálculo genera sus operaciones al
vuelo y no tiene objetivos asociados. Un profesor de Matemáticas abriría el panel y no
encontraría nada suyo, y el silencio se lee como "todo bien". Al final de la tabla del curso,
después de `bloquesAvance(data)`:

```js
      <p style="color:var(--dim);font-size:11px;margin-top:12px">
        Matemáticas no aparece aquí: se juega como Reto de Cálculo, con operaciones que se
        generan al momento y no están asociadas a un objetivo del currículum.</p>
```

- [ ] **Paso 6: Verificar la fila con datos inventados**

Levantar el servidor (`preview_start` con `{name:"kimun"}`), abrir
`http://localhost:8765/profesor.html` y en la consola:

```js
filaAvance({oa:'HI08 OA 01', respondidas:180, correctas:120, resp_1:150, ok_1:87, alumnos_1:25})
```

Esperado: el HTML muestra **58%** (87/150, no 120/180 que sería 67%), color ámbar por estar
entre 45 y 70, y el detalle `25 alumnos · 30 reintentos`.

- [ ] **Paso 7: Verificar los cortes de color**

```js
[{p:44,r:100,o:44},{p:45,r:100,o:45},{p:69,r:100,o:69},{p:70,r:100,o:70}]
  .map(c => filaAvance({oa:'X',respondidas:c.r,correctas:c.o,resp_1:c.r,ok_1:c.o,alumnos_1:20}))
  .map(h => h.match(/var\(--(green|gold|pink)\)/)[1])
```

Esperado: `["pink","gold","gold","green"]`.

- [ ] **Paso 8: Verificar los bloques**

```js
bloquesAvance([
  {oa:'A',resp_1:120,ok_1:50,alumnos_1:20,respondidas:120,correctas:50},   // 42% con base
  {oa:'B',resp_1:120,ok_1:100,alumnos_1:20,respondidas:120,correctas:100}, // 83% con base
  {oa:'C',resp_1:12,ok_1:3,alumnos_1:2,respondidas:12,correctas:3}         // sin base
]).match(/<summary[^>]*>\s*([^(]+)\((\d)\)/g)
```

Esperado: tres secciones, con 1 elemento cada una, y la tercera —"Todavía con pocos
datos"— **sin** el atributo `open`.

- [ ] **Paso 9: Commit**

```bash
git add profesor.html
git commit -m "Panel: mostrar el primer intento, colores calibrados y bloques por base"
```

---

### Tarea 4: Verificar de punta a punta y documentar

**Archivos:**
- Modificar: `CLAUDE.md`

- [ ] **Paso 1: Borrar los datos de prueba**

Los contadores actuales son de la simulación y no tienen primer intento, así que aparecerían
como 0%. En el panel, eliminar el curso **Simulación 8°A** con su botón 🗑️, que arrastra
alumnos y mediciones.

- [ ] **Paso 2: Generar datos nuevos y comprobar el ciclo completo**

Canjear un código de alumno en el juego, jugar una etapa anotando los aciertos, y abrir "Ver
avance" en el panel.

Esperado: el objetivo aparece con el porcentaje de esa partida —si acertó 4 de 6, **67%**— y
el detalle `1 alumno`, sin reintentos. Repetir la misma etapa con otro resultado: el
porcentaje **no cambia** y aparecen los reintentos.

Esa es la prueba de que el cambio funciona: **el porcentaje se mueve con el primer intento y
no con la práctica posterior.**

- [ ] **Paso 3: Documentar en `CLAUDE.md`**

En la subsección del mapa de dominio, dejar dicho: que el porcentaje es del primer intento y
por qué (el acumulado lo sesgan los reintentos, y quien no entiende reintenta más); que los
colores están calibrados al piso del azar de 25%; que los objetivos con menos de 10 alumnos
van a un bloque aparte porque su porcentaje no es interpretable; y que comparar objetivos
entre sí es el uso menos defendible, porque los bancos de preguntas no están calibrados entre
sí.

- [ ] **Paso 4: Commit**

```bash
git add CLAUDE.md
git commit -m "Documentar que el porcentaje del mapa es del primer intento"
```

---

## Notas para quien ejecute

- **El SQL lo aplica Roberto**, pegando `supabase/schema.sql` completo en el SQL Editor.
- **`index.html` no se toca en todo el plan.** Si te ves modificándolo, algo se entendió mal:
  el juego ya envía todo lo necesario.
- **La verificación de la Tarea 1, Paso 3 es la que decide si esto sirve.** Si `resp_1` sube
  al repetir una etapa, el `do update` los está tocando y el cambio no arregla nada, por más
  bien que se vea el panel.
- Las filas creadas antes de este cambio tienen `resp_1 = 0` y se mostrarían como 0%. Por eso
  la Tarea 4 empieza borrando el curso de simulación: son todos datos de prueba.
