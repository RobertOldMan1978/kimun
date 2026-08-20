# Quiénes necesitan apoyo · Plan de implementación

> **Para quien ejecute este plan:** usa `superpowers:subagent-driven-development`
> (recomendado) o `superpowers:executing-plans`, tarea por tarea. Los pasos usan
> casillas (`- [ ]`) para seguimiento.

**Objetivo:** que al tocar un objetivo del mapa, el profesor vea qué alumnos necesitan
apoyo, cuáles van en camino y cuáles ya lo lograron, para armar un grupo de refuerzo en un
minuto en vez de abrir 35 fichas.

**Arquitectura:** una función de lectura nueva devuelve, por objetivo, a todos los alumnos
inscritos del curso con su primer intento. El panel los clasifica en cuatro grupos y los
muestra como nombres desplegables debajo de la fila del mapa. No se agrega ninguna columna:
la información ya está guardada.

**Tecnología:** Supabase (PostgreSQL), JavaScript sin framework.

**Diseño de referencia:** `docs/superpowers/specs/2026-08-18-quienes-necesitan-apoyo-design.md`

---

## Cómo se verifica en este proyecto

No hay framework de pruebas: es un sitio estático. Se verifica en el navegador con
`preview_start` + `javascript_tool`, y en el SQL Editor de Supabase. Roberto aplica el SQL
pegando `supabase/schema.sql` **completo**; el archivo es idempotente.

## Archivos que se tocan

| Archivo | Responsabilidad |
| --- | --- |
| `supabase/schema.sql` | Modificar: una función nueva y su permiso |
| `profesor.html` | Modificar: `filaAvance` gana el despliegue, y las funciones del detalle |
| `CLAUDE.md` | Modificar: documentar la vista |

`index.html` no se toca.

---

## Tarea 1: La función de lectura

**Archivos:**
- Modificar: `supabase/schema.sql`

- [ ] **Paso 1: Agregar la función**

Junto a las demás `kimun_prof_dominio*`:

```sql
-- Alumnos de un curso mío con su primer intento en UN objetivo, para saber a quiénes
-- reforzar. Devuelve a TODOS los alumnos inscritos, también a los que no lo jugaron:
-- "12 no lo han visto" es información, no un vacío. Ordena por nombre a propósito —un
-- orden por rendimiento convertiría esto en un ranking de niños, que es justo lo que no
-- se quiere.
create or replace function public.kimun_prof_dominio_oa(p_curso_codigo text, p_oa text)
returns table(alumno text, avatar text, resp_1 int, ok_1 int)
language plpgsql security definer set search_path=public as $$
declare cid uuid; begin
  select id into cid from public.cursos where codigo = upper(trim(p_curso_codigo));
  if cid is null or not public.kimun_prof_es_mio(cid) then raise exception 'no_autorizado'; end if;
  return query
    select p.nombre, p.avatar, coalesce(d.resp_1,0), coalesce(d.ok_1,0)
    from public.perfiles p
    left join public.dominio d on d.perfil_id = p.id and d.oa = p_oa
    -- Solo alumnos inscritos: los perfiles sueltos que crea cada teléfono al abrir el
    -- juego no son del curso, igual que en el resto del panel.
    where p.curso_id = cid and p.codigo_acceso is not null
    order by p.nombre;
end $$;
```

- [ ] **Paso 2: Otorgar el permiso**

Agregar al `grant execute` final:

```sql
  , public.kimun_prof_dominio_oa(text,text)
```

- [ ] **Paso 3: Aplicar y verificar el aislamiento**

Pegar `supabase/schema.sql` completo en el SQL Editor y ejecutar. Luego, desde la consola del
juego (sesión anónima, sin permisos):

```js
await SB.rpc('kimun_prof_dominio_oa',{p_curso_codigo:'CUR-XXXX',p_oa:'HI08 OA 01'})
```

Esperado: error `no_autorizado`.

- [ ] **Paso 4: Verificar que devuelve a todos los alumnos**

Con la sesión de profesor, en la consola de `profesor.html`:

```js
const {data} = await SB.rpc('kimun_prof_dominio_oa',{p_curso_codigo:'CUR-XXXX',p_oa:'HI08 OA 01'});
console.log(data.length, data[0]);
```

Esperado: `data.length` es **el total de alumnos inscritos del curso**, no solo los que
jugaron ese objetivo, y cada elemento trae `alumno`, `avatar`, `resp_1` y `ok_1`.

- [ ] **Paso 5: Commit**

```bash
git add supabase/schema.sql
git commit -m "Dominio: leer los alumnos de un objetivo para armar el refuerzo"
```

---

## Tarea 2: Clasificar y mostrar

**Archivos:**
- Modificar: `profesor.html`

- [ ] **Paso 1: Agregar la clasificación**

Junto a `bloquesAvance`:

```js
// Reparte a los alumnos de un objetivo en cuatro grupos. Los umbrales son los mismos que
// los colores del mapa (45 y 70), que ya están calibrados al piso del azar.
// "Sin evidencia" recoge a quienes no lo jugaron y a quienes tienen menos de 4 preguntas
// de primer intento: con una sola pregunta —caso típico de un jefe final, donde cae una de
// cada objetivo— un alumno queda en 0% o 100%, y mandarlo al refuerzo por eso sería una
// decisión injusta tomada sobre nada.
const APOYO_MIN_PREGUNTAS = 4;
function gruposApoyo(filas){
  const g = {apoyo:[], camino:[], logrado:[], sinDatos:[]};
  (filas||[]).forEach(f => {
    const r1 = Number(f.resp_1)||0, o1 = Number(f.ok_1)||0;
    if(r1 < APOYO_MIN_PREGUNTAS){ g.sinDatos.push(f); return; }
    const pct = o1*100/r1;
    if(pct <  45) g.apoyo.push(f);
    else if(pct < 70) g.camino.push(f);
    else g.logrado.push(f);
  });
  return g;
}
```

- [ ] **Paso 2: Agregar la vista del detalle**

```js
// Los nombres van como fichas en línea: 35 alumnos en columna serían cuatro pantallas
// en un teléfono. Sin porcentaje individual, a propósito: esta vista sirve para armar un
// grupo de refuerzo, no para comparar niños entre sí.
function fichasAlumnos(filas){
  return filas.map(f =>
    `<span style="display:inline-block;background:#ffffff14;border-radius:12px;
                  padding:3px 9px;margin:2px 3px 2px 0;font-size:12px">
       ${esc(f.avatar||'🦊')} ${esc(f.alumno)}</span>`).join('');
}

function detalleApoyo(filas){
  const g = gruposApoyo(filas);
  const grupo = (titulo, lista, color, plegado, nota) => !lista.length ? '' : `
    <details ${plegado?'':'open'} style="margin:6px 0 6px 10px">
      <summary style="color:${color};font-size:12px;cursor:pointer;padding:3px 0">
        ${titulo} (${lista.length})</summary>
      <div style="padding:4px 0">${fichasAlumnos(lista)}</div>
      ${nota?`<p style="color:var(--dim);font-size:11px;margin:2px 0 0">${nota}</p>`:''}
    </details>`;
  return grupo('Necesitan apoyo', g.apoyo, 'var(--pink)', false, '')
       + grupo('En camino', g.camino, 'var(--gold)', false, '')
       + grupo('Lo lograron', g.logrado, 'var(--green)', true, '')
       + grupo('Todavía sin evidencia', g.sinDatos, 'var(--dim)', true,
               'No lo han jugado, o respondieron muy pocas preguntas para saberlo.');
}
```

- [ ] **Paso 3: Colgar el despliegue de cada fila**

`filaAvance` pasa a envolver su contenido en un `<details>` que carga el detalle al abrirse.
Reemplazar su `return` por:

```js
  // El detalle se pide al abrir, no al cargar la tabla: con 50 objetivos serían 50
  // llamadas por adelantado para algo que casi nunca se mira entero.
  const idOa = String(f.oa).replace(/[^A-Za-z0-9]/g,'');
  return `<details class="oa-fila" data-oa="${esc(f.oa)}" id="oa-${idOa}"
                   style="padding:8px 0;border-bottom:1px solid #ffffff14">
    <summary style="cursor:pointer;list-style:none">
      <div style="font-size:13px;margin-bottom:4px">${esc(OA_TEXTO[f.oa]||f.oa)}</div>
      <div style="display:flex;align-items:center;gap:8px">
        <div style="flex:1;height:8px;background:#ffffff14;border-radius:4px;overflow:hidden">
          <div style="width:${pct}%;height:100%;background:${color}"></div>
        </div>
        <b style="color:${color};min-width:42px;text-align:right">${pct}%</b>
        <small style="color:var(--dim);min-width:120px;text-align:right">${detalle}</small>
      </div>
    </summary>
    <div class="oa-detalle" style="padding-top:6px;color:var(--dim);font-size:12px">Cargando…</div>
  </details>`;
```

- [ ] **Paso 4: Cargar el detalle al abrir**

En `verAvance`, después de pintar la lista y conectar los botones, agregar:

```js
  // Carga perezosa: cada objetivo pide sus alumnos la primera vez que se abre.
  document.querySelectorAll('#lista .oa-fila').forEach(det => det.addEventListener('toggle', async () => {
    if(!det.open || det.dataset.cargado) return;
    det.dataset.cargado = '1';
    const caja = det.querySelector('.oa-detalle');
    try{
      const {data,error} = await SB.rpc('kimun_prof_dominio_oa',
        {p_curso_codigo:cursoCodigo, p_oa:det.dataset.oa});
      if(error) throw error;
      caja.innerHTML = detalleApoyo(data);
    }catch(e){
      det.dataset.cargado = '';          // permite reintentar cerrando y abriendo
      caja.textContent = esNoAutorizado(e)
        ? 'No tienes permiso para esto, o el curso ya no existe.'
        : 'No se pudo cargar. Cierra y vuelve a abrir.';
    }
  }));
```

**El detalle no se carga en la vista de un alumno**: `verAvanceAlumno` llama a `filaAvance`
igual, pero como no conecta este manejador, sus filas se abren mostrando "Cargando…" para
siempre. Para evitarlo, en `verAvanceAlumno` el `<details>` no debe ser desplegable: tras
pintar la lista, agregar:

```js
  document.querySelectorAll('#lista .oa-fila').forEach(det => {
    det.querySelector('summary').style.cursor = 'default';
    det.addEventListener('click', e => e.preventDefault());   // no despliega
    const d = det.querySelector('.oa-detalle'); if(d) d.remove();
  });
```

- [ ] **Paso 5: Verificar la clasificación con datos inventados**

Levantar el servidor (`preview_start` con `{name:"kimun"}`), abrir
`http://localhost:8765/profesor.html` y en la consola:

```js
const g = gruposApoyo([
  {alumno:'Ana',    resp_1:6, ok_1:2},   // 33% -> apoyo
  {alumno:'Bruno',  resp_1:6, ok_1:3},   // 50% -> en camino
  {alumno:'Carla',  resp_1:6, ok_1:5},   // 83% -> logrado
  {alumno:'Diego',  resp_1:1, ok_1:0},   // 1 pregunta -> sin evidencia
  {alumno:'Elena',  resp_1:0, ok_1:0}    // no jugó -> sin evidencia
]);
JSON.stringify({apoyo:g.apoyo.map(x=>x.alumno), camino:g.camino.map(x=>x.alumno),
                logrado:g.logrado.map(x=>x.alumno), sinDatos:g.sinDatos.map(x=>x.alumno)})
```

Esperado: `{"apoyo":["Ana"],"camino":["Bruno"],"logrado":["Carla"],"sinDatos":["Diego","Elena"]}`.

**Diego es la comprobación que importa:** falló su única pregunta y aun así **no** debe caer
en "necesitan apoyo".

- [ ] **Paso 6: Verificar que no se pierde nadie**

```js
const filas = Array.from({length:35}, (_,i) =>
  ({alumno:'A'+i, resp_1: i%7, ok_1: i%4}));
const g = gruposApoyo(filas);
g.apoyo.length + g.camino.length + g.logrado.length + g.sinDatos.length
```

Esperado: **35**. Si da menos, alguien se está perdiendo entre los grupos.

- [ ] **Paso 7: Verificar que no desborda en móvil**

```js
document.getElementById('lista').innerHTML =
  detalleApoyo(Array.from({length:15},(_,i)=>({alumno:'Estudiante '+(i+1),avatar:'🦊',resp_1:6,ok_1:1})));
JSON.stringify({scrollWidth:document.documentElement.scrollWidth, clientWidth:document.documentElement.clientWidth})
```

Esperado: `scrollWidth` **no mayor** que `clientWidth`. Si desborda, las fichas necesitan
`flex-wrap` o un tamaño menor.

- [ ] **Paso 8: Commit**

```bash
git add profesor.html
git commit -m "Panel: al abrir un objetivo, ver quienes necesitan apoyo"
```

---

## Tarea 3: Verificar con datos reales y documentar

**Archivos:**
- Modificar: `CLAUDE.md`

- [ ] **Paso 1: Probar el ciclo completo**

Con la cuenta de profesor, abrir "Ver avance" de un curso con datos y tocar un objetivo.

Esperado: se despliega y aparecen los grupos con los nombres de los alumnos. Los que no
jugaron ese objetivo están en "Todavía sin evidencia". La suma de los cuatro grupos es el
total de alumnos del curso.

- [ ] **Paso 2: Probar el aislamiento con dos cuentas**

Desde la sesión del profesor de prueba, en la consola:

```js
await SB.rpc('kimun_prof_dominio_oa',{p_curso_codigo:'<CUR- de un curso ajeno>',p_oa:'HI08 OA 01'})
```

Esperado: error `no_autorizado`. **Es la comprobación que protege los nombres de los alumnos
de otro profesor.**

- [ ] **Paso 3: Documentar en `CLAUDE.md`**

En la subsección del mapa de dominio, agregar: que al tocar un objetivo se despliegan los
alumnos en cuatro grupos; que **no se muestra el porcentaje individual ni se puede ordenar
por rendimiento**, a propósito, porque una lista de niños ordenada por nota es lo que termina
usándose para calificar; que "Todavía sin evidencia" incluye a quienes no jugaron y a quienes
respondieron menos de cuatro preguntas; y que la clasificación usa el primer intento, así que
un alumno que reforzó por su cuenta sigue apareciendo donde lo dejó su primera vez.

- [ ] **Paso 4: Commit**

```bash
git add CLAUDE.md
git commit -m "Documentar la vista de quienes necesitan apoyo"
```

---

## Notas para quien ejecute

- **El SQL lo aplica Roberto**, pegando `supabase/schema.sql` completo en el SQL Editor.
- **No agregues el porcentaje individual de cada alumno**, por más natural que parezca. Es
  una decisión explícita del diseño: la pantalla debe servir para armar un grupo de refuerzo,
  no para comparar niños.
- **No ordenes por rendimiento.** El orden alfabético viene del servidor y es intencional.
- La comprobación de la Tarea 2, Paso 5 con "Diego" es la que evita una injusticia concreta:
  mandar a un niño al refuerzo por una sola pregunta fallada en un jefe.
