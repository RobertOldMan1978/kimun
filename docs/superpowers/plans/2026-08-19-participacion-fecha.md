# Participación y fecha · Plan de implementación

> **Para quien ejecute este plan:** usa `superpowers:subagent-driven-development`
> (recomendado) o `superpowers:executing-plans`, tarea por tarea. Los pasos usan
> casillas (`- [ ]`) para seguimiento.

**Objetivo:** que el profesor vea, arriba del mapa de avance, cuántos alumnos jugaron esta
semana, cuántos dejaron de entrar y cuántos nunca canjearon su código, para saber a quién
reactivar sin abrir 35 fichas.

**Arquitectura:** una columna `visto` en `perfiles`, sellada dentro de `kimun_xp` (la
sincronización que el juego ya hace en todos los modos), guarda la última vez que el niño
abrió el juego. Una función nueva `kimun_prof_participacion` la lee por curso, con el mismo
aislamiento del resto del panel. El cliente la clasifica en cuatro grupos y la muestra en
un bloque plegado sobre el mapa.

**Tecnología:** Supabase (PostgreSQL), JavaScript sin framework.

**Diseño de referencia:** `docs/superpowers/specs/2026-08-19-participacion-fecha-design.md`

---

## Cómo se verifica en este proyecto

No hay framework de pruebas: es un sitio estático. El SQL se verifica en el SQL Editor de
Supabase (Roberto pega `supabase/schema.sql` **completo**; el archivo es idempotente). El
cliente se verifica en el navegador con `preview_start` + `javascript_tool`, sustituyendo
`SB.rpc` por un banco de datos simulado, porque el panel real necesita credenciales.

## Archivos que se tocan

| Archivo | Responsabilidad |
| --- | --- |
| `supabase/schema.sql` | Modificar: columna `visto`, sello en `kimun_xp`, migración de relleno, función `kimun_prof_participacion` y su permiso |
| `profesor.html` | Modificar: bloque de participación (HTML, carga, clasificación); extraer `grupoFichas` compartido |
| `CLAUDE.md` | Modificar: documentar la vista de participación |
| `README.md` | Modificar: una frase en la descripción del panel |

`index.html` **no se toca**: el juego ya llama a `kimun_xp`, que ahora sella `visto` sin
pedirle nada nuevo al cliente.

---

## Tarea 1: SQL — columna, sello, migración y función

**Archivos:**
- Modificar: `supabase/schema.sql` (columna de `perfiles`, cuerpo de `kimun_xp`, función
  nueva antes del `grant`, línea del `grant`, migración de relleno al final)

- [ ] **Paso 1: Agregar la columna `visto` junto a los otros alter de `perfiles`**

Localiza el bloque de `alter table public.perfiles add column if not exists ...` (la
columna `dificil` es la última del bloque). Debajo de esa línea agrega:

```sql
alter table public.perfiles add column if not exists visto timestamptz;   -- última vez que abrió el juego
```

`timestamptz` sin `not null`: nulo significa "nunca lo hemos visto".

- [ ] **Paso 2: Sellar `visto` dentro de `kimun_xp`**

Reemplaza la única línea `update` de la función `kimun_xp`:

Antes:
```sql
  update public.perfiles set xp = greatest(xp, coalesce(p_xp,0)) where id=mi returning xp into v;
```

Después:
```sql
  update public.perfiles set xp = greatest(xp, coalesce(p_xp,0)), visto = now() where id=mi returning xp into v;
```

No se agrega función nueva del lado del juego: `visto` se cuelga del `update` que ya
existe. Como el juego llama a `kimun_xp` desde `guardar()` cada 15 s y `guardar()` corre
también al abrir el juego, `visto` refleja la entrada aunque el niño no termine nada.

- [ ] **Paso 3: Crear `kimun_prof_participacion` junto a las demás `kimun_prof_dominio_*`**

Pégala inmediatamente después de la función `kimun_prof_dominio_alumno` (mismo patrón de
resolución de curso y aislamiento que `kimun_prof_dominio`):

```sql
-- Participación del curso: una fila por alumno inscrito, con la última vez que abrió el
-- juego y si alguna vez canjeó su código. El cliente la reparte en grupos.
drop function if exists public.kimun_prof_participacion(text);
create or replace function public.kimun_prof_participacion(p_curso_codigo text)
returns table(alumno text, avatar text, visto timestamptz, vinculado boolean)
language plpgsql security definer set search_path=public as $$
declare cid uuid; begin
  select id into cid from public.cursos where codigo = upper(trim(p_curso_codigo));
  if cid is null or not public.kimun_prof_es_mio(cid) then raise exception 'no_autorizado'; end if;
  return query
    select p.nombre, p.avatar, p.visto,
           exists(select 1 from public.vinculos v where v.perfil_id = p.id)
    from public.perfiles p
    where p.curso_id = cid
    order by p.nombre;   -- alfabético a propósito: por fecha sería un ranking de niños
end $$;
```

Devuelve **a todos los inscritos**, también a los que no tienen fecha ni vínculo: "no
aparece" no puede significar "no lo sé". El `drop function if exists` va antes del `create`
porque es `returns table` (cambiar una columna del returns haría fallar el re-pegado).

- [ ] **Paso 4: Autorizar la función en el `grant`**

Localiza el `grant execute on function` grande (termina con
`public.kimun_prof_dominio_oa(text,text)` en una línea con coma inicial, y luego
`to anon, authenticated;`). Agrega la nueva función siguiendo ese mismo estilo, antes de
`to anon, authenticated;`:

Antes:
```sql
  , public.kimun_prof_dominio_oa(text,text)
  to anon, authenticated;
```

Después:
```sql
  , public.kimun_prof_dominio_oa(text,text)
  , public.kimun_prof_participacion(text)
  to anon, authenticated;
```

- [ ] **Paso 5: Migración de relleno al final del archivo**

Al final de `schema.sql`, después del `delete from public.config where clave = 'admin_clave';`,
agrega:

```sql
-- ------------------------------------------------------------
-- Relleno inicial de "visto" (participación).
--
-- Sin esto, al aplicar la columna por primera vez el curso entero se vería como "nunca ha
-- jugado" hasta que cada niño vuelva a abrir el juego, y el profesor leería un curso
-- muerto. Se copia el último contacto conocido desde "dominio". Quien jugó campañas parte
-- con su fecha real; quien solo jugó Reto de Cálculo parte en nulo hasta su próxima
-- entrada (esa tabla no registra objetivos). El "where visto is null" lo hace idempotente:
-- re-pegar el archivo no pisa las fechas reales ya guardadas.
-- ------------------------------------------------------------
update public.perfiles p
   set visto = d.ult
  from (select perfil_id, max(actualizado) ult from public.dominio group by perfil_id) d
 where d.perfil_id = p.id and p.visto is null;
```

Va al final a propósito: la tabla `dominio` ya existe en ese punto del archivo.

- [ ] **Paso 6: Verificar la idempotencia y la lógica en el SQL Editor (lo hace Roberto)**

Roberto pega `schema.sql` completo. Comprobaciones esperadas:
- No hay error al re-pegar (columna `if not exists`, función con `drop` previo, `update`
  con `where visto is null`).
- Tras aplicar, un alumno que abre el juego (o cualquier acción que dispare `kimun_xp`)
  queda con `visto = now()`.
- La migración deja con fecha a quien tenía filas en `dominio` y en nulo al resto.

- [ ] **Paso 7: Commit**

```bash
git add supabase/schema.sql
git commit -m "Participacion: columna visto sellada en kimun_xp y kimun_prof_participacion"
```

---

## Tarea 2: Cliente — el bloque de participación

**Archivos:**
- Modificar: `profesor.html` (extraer `grupoFichas`; agregar `bloqueParticipacion`,
  `gruposParticipacion`, `cargarParticipacion`; insertar el bloque en `verAvance`)

- [ ] **Paso 1: Extraer el helper `grupoFichas` compartido**

Hoy `detalleApoyo` define un `grupo` local que arma un `<details>` con fichas de alumnos.
La participación necesita exactamente lo mismo, así que se extrae a nivel de módulo.

Localiza `function detalleApoyo(filas){` y su `const grupo = (titulo, lista, color, plegado, nota) => ...`.
Justo **antes** de `function detalleApoyo`, agrega el helper de módulo:

```javascript
// Un grupo de alumnos como fichas dentro de un <details>. Compartido por la vista de
// apoyo (por objetivo) y por la de participación (por curso).
function grupoFichas(titulo, lista, color, plegado, nota){
  return !lista.length ? '' : `
    <details ${plegado?'':'open'} style="margin:6px 0 6px 10px">
      <summary style="color:${color};font-size:12px;cursor:pointer;padding:3px 0">
        ${titulo} (${lista.length})</summary>
      <div style="padding:4px 0">${fichasAlumnos(lista)}</div>
      ${nota?`<p style="color:var(--dim);font-size:11px;margin:2px 0 0">${nota}</p>`:''}
    </details>`;
}
```

Luego, dentro de `detalleApoyo`, elimina el `const grupo = ...` local y reemplaza las
llamadas `grupo(...)` por `grupoFichas(...)`. El cuerpo queda:

```javascript
function detalleApoyo(filas){
  const g = gruposApoyo(filas);
  return grupoFichas('Necesitan apoyo', g.apoyo, 'var(--pink)', false, '')
       + grupoFichas('En camino', g.camino, 'var(--gold)', false, '')
       + grupoFichas('Lo lograron', g.logrado, 'var(--green)', true, '')
       + grupoFichas('Todavía sin evidencia', g.sinDatos, 'var(--dim)', true,
               'No lo han jugado, o respondieron muy pocas preguntas para saberlo.');
}
```

- [ ] **Paso 2: Clasificar la participación en cuatro grupos**

Agrégalo junto a las funciones del avance (por ejemplo, después de `filtrosAsignatura`):

```javascript
// Reparte a los alumnos del curso en cuatro grupos por su última entrada. La ventana es
// móvil (7 días hacia atrás), no "desde el lunes", para no depender de la zona horaria del
// servidor. "Nunca canjearon" se separa de "dejaron de jugar" porque la acción es distinta:
// volver a entregar el código, no insistirle al niño.
const PART_DIAS = 7;
function gruposParticipacion(filas){
  const g = {semana:[], viejo:[], sinJugar:[], sinCodigo:[]};
  const corte = Date.now() - PART_DIAS*24*60*60*1000;
  (filas||[]).forEach(f => {
    if(!f.vinculado){ g.sinCodigo.push(f); return; }
    if(!f.visto){ g.sinJugar.push(f); return; }
    (new Date(f.visto).getTime() >= corte ? g.semana : g.viejo).push(f);
  });
  return g;
}
```

- [ ] **Paso 3: Armar el HTML del bloque (placeholder + relleno)**

Agrégalo debajo de `gruposParticipacion`:

```javascript
// El bloque va plegado, con el titular en la línea visible: es el dato que hay que ver sin
// abrir nada. Se pinta primero con "Cargando…" y se rellena aparte, para no retrasar el mapa.
function bloqueParticipacionHTML(){
  return `<details id="partBloque" style="margin-bottom:12px;border:1px solid #ffffff22;
            border-radius:12px;padding:8px 10px">
    <summary style="cursor:pointer;list-style:none;color:var(--cyan);font-size:13px"
             id="partTitular">Participación · cargando…</summary>
    <div id="partCuerpo" style="padding-top:6px"></div>
  </details>`;
}

function pintarParticipacion(filas){
  const g = gruposParticipacion(filas);
  const total = (filas||[]).length;
  $('partTitular').textContent =
    `Participación · ${g.semana.length} de ${total} jugaron esta semana`;
  $('partCuerpo').innerHTML =
      grupoFichas('Jugaron esta semana', g.semana, 'var(--green)', false, '')
    + grupoFichas('Hace más de una semana', g.viejo, 'var(--gold)', false, '')
    + grupoFichas('Canjearon su código pero no han jugado', g.sinJugar, 'var(--dim)', true, '')
    + grupoFichas('Nunca canjearon su código', g.sinCodigo, 'var(--pink)', true,
        'Puede ser un código perdido o mal escrito, o que no tengan teléfono. La acción '
        + 'es volver a entregar el código. El dato lo reporta el teléfono: no es asistencia.')
    + (total ? '' : '<p style="color:var(--dim);font-size:12px">Este curso no tiene alumnos inscritos.</p>');
}
```

- [ ] **Paso 4: Cargar la participación sin bloquear el mapa**

Agrégalo debajo:

```javascript
// Se lanza sin await desde verAvance: el mapa no la espera y su fallo no impide ver el
// avance. Si falla, el bloque lo dice y el mapa queda intacto.
async function cargarParticipacion(cursoCodigo){
  try{
    const {data,error} = await SB.rpc('kimun_prof_participacion',{p_curso_codigo:cursoCodigo});
    if(error) throw error;
    pintarParticipacion(data);
  }catch(e){
    const t = $('partTitular'); if(t) t.textContent = 'Participación · no se pudo cargar';
  }
}
```

- [ ] **Paso 5: Insertar el bloque en `verAvance`, en las dos ramas**

En `verAvance(cursoCodigo, cursoNombre)`, el bloque de participación va **después de la
cabecera** y **antes del párrafo de porcentajes / de "sin datos"**. Debe aparecer también
cuando el curso no tiene datos de dominio: ese es justo el caso donde interesa ver quién no
entró.

Rama **sin datos de dominio** — cambia el `innerHTML`:

Antes:
```javascript
      $('lista').innerHTML = cabeceraAvance(titulo, 'Avance por objetivo') + `
        <p style="color:var(--dim);font-size:13px">
        Todavía no hay datos de este curso. Aparecen cuando los alumnos juegan las campañas.</p>
        <button class="btn sec" id="btnVolverPanel">← Volver</button>`;
      $('btnVolverCab').onclick = volverAlPanel;
      $('btnVolverPanel').onclick = volverAlPanel;
      irArriba(); aviso(''); return;
```

Después:
```javascript
      $('lista').innerHTML = cabeceraAvance(titulo, 'Avance por objetivo')
        + bloqueParticipacionHTML() + `
        <p style="color:var(--dim);font-size:13px">
        Todavía no hay datos de avance de este curso. Aparecen cuando los alumnos juegan las campañas.</p>
        <button class="btn sec" id="btnVolverPanel">← Volver</button>`;
      $('btnVolverCab').onclick = volverAlPanel;
      $('btnVolverPanel').onclick = volverAlPanel;
      cargarParticipacion(cursoCodigo);
      irArriba(); aviso(''); return;
```

Rama **con datos** — agrega el bloque al `innerHTML` y dispara la carga tras cablear los
botones:

Antes:
```javascript
    $('lista').innerHTML = cabeceraAvance(titulo, 'Avance por objetivo') + `
      <p style="color:var(--dim);font-size:12px;margin-bottom:10px">
        Porcentaje de acierto por objetivo, de menor a mayor. ${AVISO_NO_CALIFICA}</p>
      ${filtrosAsignatura(data)}
```

Después:
```javascript
    $('lista').innerHTML = cabeceraAvance(titulo, 'Avance por objetivo')
      + bloqueParticipacionHTML() + `
      <p style="color:var(--dim);font-size:12px;margin-bottom:10px">
        Porcentaje de acierto por objetivo, de menor a mayor. ${AVISO_NO_CALIFICA}</p>
      ${filtrosAsignatura(data)}
```

Y justo después de `$('btnReiniciarMed').onclick = () => reiniciarMediciones(cursoCodigo, cursoNombre);`,
agrega:

```javascript
    cargarParticipacion(cursoCodigo);
```

La vista de un alumno (`verAvanceAlumno`) **no** lleva participación: es de un solo niño,
no hay grupos que mostrar.

- [ ] **Paso 6: Verificar la sintaxis**

```bash
sed -n '/^<script>$/,/^<\/script>$/p' profesor.html | sed '1d;$d' > /tmp/prof.js && node --check /tmp/prof.js && echo "SINTAXIS OK"
```
Esperado: `SINTAXIS OK`.

- [ ] **Paso 7: Commit**

```bash
git add profesor.html
git commit -m "Participacion: bloque plegado con cuatro grupos sobre el mapa"
```

---

## Tarea 3: Verificar en el navegador y documentar

**Archivos:**
- Modificar: `CLAUDE.md` (documentar la vista), `README.md` (una frase)

- [ ] **Paso 1: Levantar el preview y montar el banco de datos simulado**

Con `preview_start` (config `kimun`), navega a `http://localhost:8765/profesor.html`,
`resize_window` a `mobile` (375). Sustituye `SB.rpc` para probar sin credenciales. El
simulado debe cubrir los cuatro grupos y la rama con datos de dominio:

```javascript
(function(){
  var NOMBRES=['Ana','Bruno','Carla','Diego','Elena','Fabián','Gala','Hugo','Ivo','Julia',
    'Karen','Luis','Mara','Nico','Olga','Pía','Raúl','Sara','Tomás','Vera'];
  var ahora=Date.now(), dia=86400000;
  // 0-9 esta semana, 10-14 hace tiempo, 15-17 vinculado sin visto, 18-19 sin código.
  var PART=NOMBRES.map(function(n,i){
    var vinc=i<18, visto=null;
    if(i<10) visto=new Date(ahora-2*dia).toISOString();
    else if(i<15) visto=new Date(ahora-20*dia).toISOString();
    return {alumno:n,avatar:'🦊',visto:visto,vinculado:vinc};
  });
  var DOM=[{oa:'HI08 OA 01',respondidas:60,correctas:30,alumnos:10,resp_1:60,ok_1:30,alumnos_1:10},
           {oa:'HI08 OA 02',respondidas:48,correctas:40,alumnos:8,resp_1:48,ok_1:40,alumnos_1:8}];
  SB.rpc=function(fn){
    if(fn==='kimun_prof_yo') return Promise.resolve({data:[{id:'demo',es_admin:false}],error:null});
    if(fn==='kimun_prof_listar') return Promise.resolve({data:NOMBRES.map(function(n,i){return {curso:'8° A',curso_codigo:'CUR-2E9A',alumno:n,avatar:'🦊',codigo_acceso:'ALU-'+String(10000000+i),xp:100+i};}),error:null});
    if(fn==='kimun_prof_dominio') return Promise.resolve({data:DOM,error:null});
    if(fn==='kimun_prof_participacion') return Promise.resolve({data:PART,error:null});
    if(fn==='kimun_prof_dominio_oa') return Promise.resolve({data:[],error:null});
    return Promise.resolve({data:null,error:null});
  };
  return cargarPanel().then(function(){ document.querySelector('.avance').click(); });
})()
```

- [ ] **Paso 2: Comprobar el titular, los grupos y el ancho**

Tras un `setTimeout` corto:

```javascript
JSON.stringify({
  titular: document.getElementById('partTitular').textContent,
  grupos: [...document.querySelectorAll('#partCuerpo details summary')].map(s=>s.textContent.trim()),
  scrollWidth: document.documentElement.scrollWidth
})
```
Esperado: titular `Participación · 10 de 20 jugaron esta semana`; cuatro grupos con conteos
`10 / 5 / 3 / 2`; `scrollWidth` = 375 (sin desborde lateral). Toma una captura con el bloque
desplegado.

- [ ] **Paso 3: Comprobar que un fallo de participación no rompe el mapa**

```javascript
(function(){
  var orig=SB.rpc;
  SB.rpc=function(fn,a){ if(fn==='kimun_prof_participacion') return Promise.resolve({data:null,error:{message:'boom'}}); return orig(fn,a); };
  return verAvance('CUR-2E9A','8° A').then(function(){
    return new Promise(function(r){ setTimeout(function(){
      SB.rpc=orig;
      r(JSON.stringify({
        titular: document.getElementById('partTitular').textContent,
        mapaPintado: document.querySelectorAll('#avCuerpo .oa-fila').length
      }));
    },400); });
  });
})()
```
Esperado: titular `Participación · no se pudo cargar`, y `mapaPintado` > 0 (el mapa se ve
igual). Revisa `read_console_messages` (onlyErrors): sin errores no controlados.

- [ ] **Paso 4: Comprobar la rama sin datos de dominio**

```javascript
(function(){
  var orig=SB.rpc;
  SB.rpc=function(fn,a){ if(fn==='kimun_prof_dominio') return Promise.resolve({data:[],error:null}); return orig(fn,a); };
  return verAvance('CUR-2E9A','8° A').then(function(){
    return new Promise(function(r){ setTimeout(function(){
      SB.rpc=orig;
      r(JSON.stringify({ hayBloque: !!document.getElementById('partBloque'),
                         titular: document.getElementById('partTitular').textContent }));
    },400); });
  });
})()
```
Esperado: `hayBloque` true y el titular con su conteo — la participación aparece aunque no
haya datos de avance.

- [ ] **Paso 5: Documentar en `CLAUDE.md`**

En la sección "Mapa de dominio por OA" (Herramientas de desarrollo), agrega un párrafo que
describa la vista de participación: qué mide (`visto`, la última entrada, sellada en
`kimun_xp`, cualquier modo), los cuatro grupos, por qué "nunca canjearon" se separa, y el
límite (lo reporta el teléfono, no es asistencia; en la migración quien solo jugó Reto de
Cálculo parte sin fecha hasta su próxima entrada). En la sección "Backend (Supabase)"
agrega `visto` y `kimun_prof_participacion` a la descripción de la Sesión correspondiente.

- [ ] **Paso 6: Documentar en `README.md`**

En el párrafo del panel (el que menciona el mapa de dominio), añade una frase: el panel
muestra además quién jugó esta semana y quién no ha entrado.

- [ ] **Paso 7: Commit**

```bash
git add CLAUDE.md README.md
git commit -m "Docs: vista de participacion en el panel del profesor"
```

---

## Notas para quien ejecute

- **El orden importa:** la Tarea 1 (SQL) no rompe nada del cliente actual, así que se puede
  aplicar sola. La Tarea 2 depende de que la función exista en el servidor de Roberto para
  verse con datos reales, pero se verifica con el simulado sin esperar a eso.
- **`index.html` no se toca.** Si aparece la tentación de agregar un envío de "visto" desde
  el juego, no hace falta: `kimun_xp` ya lo sella.
- **El `on conflict` de `kimun_dominio` no entra en este cambio.** No lo toques: sigue sin
  tocar `resp_1`/`ok_1`, que es lo que mantiene honesto el porcentaje del mapa.
- **Un grupo vacío no se dibuja** (lo maneja `grupoFichas` devolviendo `''`), así que un
  curso sano donde todos jugaron muestra solo "Jugaron esta semana".
