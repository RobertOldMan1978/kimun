# Cursos y ranking real · Plan de implementación

> **Para quien ejecute este plan:** usa `superpowers:subagent-driven-development`
> (recomendado) o `superpowers:executing-plans`, tarea por tarea. Los pasos usan
> casillas (`- [ ]`) para seguimiento.

**Objetivo:** reemplazar el ranking simulado por un ranking real por curso, con alumnos
inscritos por el adulto y XP sincronizado a Supabase.

**Arquitectura:** el backend gana dos tablas (`cursos`, `vinculos`) y tres columnas en
`perfiles`. La tabla `vinculos` separa la sesión anónima del dispositivo del perfil del
alumno, de modo que un mismo alumno pueda jugar en varios equipos. Todo el acceso pasa por
funciones `SECURITY DEFINER`. En el juego se agregan dos pantallas (administración de
cursos y canje de código) y se reescribe `renderRanking`.

**Tecnología:** Supabase (PostgreSQL + PostgREST), JavaScript sin framework, un solo
`index.html`.

**Diseño de referencia:** `docs/superpowers/specs/2026-08-17-cursos-ranking-real-design.md`

---

## Cómo se verifica en este proyecto

El proyecto **no tiene framework de pruebas**: es un `index.html` estático con contenido en
JSON. Las sesiones anteriores verificaron en el navegador con `preview_start` +
`javascript_tool`. Este plan mantiene ese criterio y define, para cada tarea, una
verificación concreta con su resultado esperado:

- **Backend:** consultas en el SQL Editor de Supabase, con el resultado que debe devolver.
- **Juego:** comandos en la consola del navegador sobre `http://localhost:8765`, con el
  valor esperado.

Cada tarea termina en un commit. El SQL se mantiene en `supabase/schema.sql`, que es
idempotente (`if not exists` / `or replace`): Roberto lo pega completo en el SQL Editor
cada vez que cambia.

## Archivos que se tocan

| Archivo | Responsabilidad |
| --- | --- |
| `supabase/schema.sql` | Modificar: tablas, columnas, funciones nuevas y adaptación de las existentes |
| `index.html` | Modificar: conexión al inicio, canje, sincronización de XP, ranking, panel de cursos |
| `CLAUDE.md` | Modificar: documentar la administración de cursos y la clave |

---

## Fase 1 · Backend

### Tarea 1: Tablas, columnas y cierre del acceso directo

**Archivos:**
- Modificar: `supabase/schema.sql`

- [ ] **Paso 1: Agregar las tablas y columnas nuevas**

Insertar después de la definición de la tabla `duelos` (antes del bloque de RLS):

```sql
-- Cursos (los crea el adulto desde el Modo Admin)
create table if not exists public.cursos (
  id     uuid primary key default gen_random_uuid(),
  nombre text not null,
  codigo text unique not null,            -- CUR-AB12
  creado timestamptz not null default now()
);

-- Columnas nuevas de perfiles
alter table public.perfiles add column if not exists curso_id      uuid references public.cursos(id) on delete set null;
alter table public.perfiles add column if not exists xp            int not null default 0;
alter table public.perfiles add column if not exists codigo_acceso text unique;   -- ALU-XXXX

-- Vínculo dispositivo -> perfil (permite jugar en varios equipos)
create table if not exists public.vinculos (
  auth_uid  uuid primary key,             -- auth.uid() del dispositivo
  perfil_id uuid not null references public.perfiles(id) on delete cascade,
  creado    timestamptz not null default now()
);

-- Clave del Modo Admin, guardada en el servidor (no en el JavaScript)
create table if not exists public.config (
  clave text primary key,
  valor text not null
);
insert into public.config(clave,valor) values ('admin_clave','CAMBIA-ESTA-CLAVE')
  on conflict (clave) do nothing;
```

- [ ] **Paso 2: Cerrar la lectura directa de `perfiles`**

Reemplazar el bloque de RLS actual (las líneas de `alter table ... enable row level
security` y la política `perfiles_select`) por:

```sql
-- RLS: ninguna tabla se lee directo; todo pasa por las funciones SECURITY DEFINER.
alter table public.perfiles enable row level security;
alter table public.duelos   enable row level security;
alter table public.cursos   enable row level security;
alter table public.vinculos enable row level security;
alter table public.config   enable row level security;
drop policy if exists "perfiles_select" on public.perfiles;
```

**Por qué este cambio, que no estaba en el diseño:** hoy existe una política que permite a
cualquiera leer la tabla `perfiles` completa. Al agregar `codigo_acceso` a esa tabla, esa
política dejaría los códigos de acceso de todos los alumnos a la vista de cualquiera que
abriera la consola del navegador, y un niño podría entrar como un compañero. Como el juego
ya obtiene todo por funciones RPC y nunca hace `from('perfiles')`, quitar la política no
rompe nada y cierra el agujero.

- [ ] **Paso 3: Aplicar y verificar**

Pegar `supabase/schema.sql` completo en el SQL Editor de Supabase y ejecutar. Luego:

```sql
select column_name from information_schema.columns
where table_name='perfiles' and column_name in ('curso_id','xp','codigo_acceso');
```

Esperado: 3 filas.

```sql
select count(*) from pg_policies where tablename='perfiles';
```

Esperado: `0`.

- [ ] **Paso 4: Commit**

```bash
git add supabase/schema.sql
git commit -m "Cursos: tablas cursos/vinculos/config y cierre del acceso directo a perfiles"
```

---

### Tarea 2: Identidad por vínculo (`kimun_yo`) y adaptación de las funciones existentes

**Archivos:**
- Modificar: `supabase/schema.sql`

- [ ] **Paso 1: Agregar el helper y los generadores de código**

Insertar después de `kimun_gen_codigo()`:

```sql
-- Código de curso (CUR-AB12) y de alumno (ALU-AB12)
create or replace function public.kimun_gen_codigo_curso() returns text
language plpgsql as $$
declare c text; begin
  loop c := 'CUR-'||upper(substr(md5(gen_random_uuid()::text),1,4));
    exit when not exists (select 1 from public.cursos where codigo=c); end loop;
  return c; end $$;

create or replace function public.kimun_gen_codigo_alumno() returns text
language plpgsql as $$
declare c text; begin
  loop c := 'ALU-'||upper(substr(md5(gen_random_uuid()::text),1,4));
    exit when not exists (select 1 from public.perfiles where codigo_acceso=c); end loop;
  return c; end $$;

-- Perfil de este dispositivo (null si todavía no tiene vínculo)
create or replace function public.kimun_yo() returns uuid
language sql security definer stable set search_path=public as $$
  select perfil_id from public.vinculos where auth_uid = auth.uid();
$$;

-- Migración: los jugadores que ya existen quedan vinculados a sí mismos
insert into public.vinculos(auth_uid, perfil_id)
select id, id from public.perfiles where es_bot = false
on conflict (auth_uid) do nothing;
```

- [ ] **Paso 2: Reemplazar `kimun_perfil`**

```sql
create or replace function public.kimun_perfil(p_nombre text, p_avatar text)
returns public.perfiles language plpgsql security definer set search_path=public as $$
declare r public.perfiles; mi uuid; begin
  mi := public.kimun_yo();
  if mi is null then
    insert into public.perfiles(id,nombre,avatar,codigo)
    values (auth.uid(),coalesce(p_nombre,'Jugador'),coalesce(p_avatar,'🦊'),public.kimun_gen_codigo())
    on conflict (id) do update set nombre=excluded.nombre, avatar=excluded.avatar
    returning * into r;
    insert into public.vinculos(auth_uid,perfil_id) values (auth.uid(), r.id)
      on conflict (auth_uid) do update set perfil_id=excluded.perfil_id;
  else
    select * into r from public.perfiles where id=mi;
    -- A un alumno inscrito por el adulto no se le pisa el nombre con el del teléfono
    if r.codigo_acceso is null then
      update public.perfiles set nombre=coalesce(p_nombre,nombre), avatar=coalesce(p_avatar,avatar)
      where id=mi returning * into r;
    end if;
  end if;
  return r; end $$;
```

- [ ] **Paso 3: Cambiar `auth.uid()` por `public.kimun_yo()` en las cinco funciones restantes**

En `kimun_jugadores`:

```sql
create or replace function public.kimun_jugadores()
returns table(nombre text,avatar text,codigo text,es_bot boolean)
language sql security definer set search_path=public as $$
  select nombre,avatar,codigo,es_bot from public.perfiles
  where id <> coalesce(public.kimun_yo(),'00000000-0000-0000-0000-000000000000'::uuid)
  order by es_bot desc, nombre; $$;
```

En `kimun_crear_duelo`, reemplazar la línea del `insert`:

```sql
  insert into public.duelos(retador_id,retado_codigo,expedicion,preguntas,retador_aciertos,retador_tiempo)
  values (public.kimun_yo(),upper(p_retado_codigo),p_expedicion,p_preguntas,p_aciertos,p_tiempo) returning id into v;
```

En `kimun_pendientes`, reemplazar la condición final:

```sql
  where d.retado_codigo=(select codigo from public.perfiles where id=public.kimun_yo())
    and d.estado='pendiente' and d.expira>now(); $$;
```

En `kimun_responder`, reemplazar las dos referencias:

```sql
  select codigo into mi from public.perfiles where id=public.kimun_yo();
```

```sql
  update public.duelos set retado_id=public.kimun_yo(),retado_aciertos=p_aciertos,retado_tiempo=p_tiempo,estado='completado' where id=p_id;
```

En `kimun_historial`, reemplazar las cinco apariciones de `auth.uid()` por
`public.kimun_yo()` (tres en los `case when`, una en el `where` y la del subselect final).

- [ ] **Paso 4: Aplicar y verificar que la identidad funciona**

Ejecutar el esquema completo. Luego, en el SQL Editor:

```sql
select count(*) from public.vinculos;
```

Esperado: igual al número de perfiles reales (no bots) que ya existían.

- [ ] **Paso 5: Verificar que el duelo no se rompió**

Levantar el juego (`preview_start`), entrar a **Duelo 1v1 → En línea** y comprobar que
aparece el código propio (`KIM-XXXX`) y la lista de rivales con los cuatro bots.
Esperado: sin errores en consola.

- [ ] **Paso 6: Commit**

```bash
git add supabase/schema.sql
git commit -m "Cursos: identidad por vinculo (kimun_yo) y adaptacion de las funciones de duelo"
```

---

### Tarea 3: Funciones del jugador (XP, ranking, canje)

**Archivos:**
- Modificar: `supabase/schema.sql`

- [ ] **Paso 1: Agregar las tres funciones**

Insertar antes del bloque de bots:

```sql
-- Sube mi XP (monótono: nunca baja)
create or replace function public.kimun_xp(p_xp int) returns int
language plpgsql security definer set search_path=public as $$
declare mi uuid; v int; begin
  mi := public.kimun_yo();
  if mi is null then return 0; end if;
  update public.perfiles set xp = greatest(xp, coalesce(p_xp,0)) where id=mi returning xp into v;
  return coalesce(v,0); end $$;

-- Ranking de mi curso (vacío si no tengo curso)
create or replace function public.kimun_ranking()
returns table(nombre text, avatar text, xp int, soy_yo boolean, curso text)
language sql security definer set search_path=public as $$
  select p.nombre, p.avatar, p.xp, (p.id = public.kimun_yo()), c.nombre
  from public.perfiles p
  join public.cursos c on c.id = p.curso_id
  where p.curso_id = (select curso_id from public.perfiles where id = public.kimun_yo())
  order by p.xp desc, p.nombre; $$;

-- Canjea un código de alumno: vincula este dispositivo a ese perfil
create or replace function public.kimun_canjear(p_codigo text)
returns public.perfiles language plpgsql security definer set search_path=public as $$
declare r public.perfiles; begin
  select * into r from public.perfiles where codigo_acceso = upper(trim(p_codigo));
  if r.id is null then raise exception 'codigo_invalido'; end if;
  insert into public.vinculos(auth_uid,perfil_id) values (auth.uid(), r.id)
    on conflict (auth_uid) do update set perfil_id = excluded.perfil_id;
  return r; end $$;
```

- [ ] **Paso 2: Agregar los permisos**

Reemplazar el bloque `grant execute` final por:

```sql
grant execute on function
  public.kimun_perfil(text,text), public.kimun_buscar(text), public.kimun_jugadores(),
  public.kimun_crear_duelo(text,text,jsonb,int,int), public.kimun_pendientes(),
  public.kimun_responder(uuid,int,int), public.kimun_historial(),
  public.kimun_yo(), public.kimun_xp(int), public.kimun_ranking(), public.kimun_canjear(text)
  to anon, authenticated;
```

- [ ] **Paso 3: Verificar que el XP es monótono**

En el SQL Editor, tomando un perfil real existente:

```sql
-- Simula el dispositivo de ese perfil
select public.kimun_xp(500);   -- primera subida
select public.kimun_xp(300);   -- intento de bajar
select xp from public.perfiles where id = public.kimun_yo();
```

Esperado: el XP final es `500`, no `300`. (Si `kimun_yo()` devuelve null en el SQL Editor
por no haber sesión anónima, verificar en el paso equivalente de la Tarea 7 desde el juego.)

- [ ] **Paso 4: Commit**

```bash
git add supabase/schema.sql
git commit -m "Cursos: funciones de XP, ranking y canje de codigo"
```

---

### Tarea 4: Funciones de administración

**Archivos:**
- Modificar: `supabase/schema.sql`

- [ ] **Paso 1: Agregar las cinco funciones**

```sql
-- Valida la clave del Modo Admin contra la guardada en config
create or replace function public.kimun_admin_ok(p_clave text) returns boolean
language sql security definer stable set search_path=public as $$
  select exists(select 1 from public.config where clave='admin_clave' and valor = p_clave); $$;

create or replace function public.kimun_admin_curso_crear(p_clave text, p_nombre text)
returns public.cursos language plpgsql security definer set search_path=public as $$
declare r public.cursos; begin
  if not public.kimun_admin_ok(p_clave) then raise exception 'clave_invalida'; end if;
  if coalesce(trim(p_nombre),'') = '' then raise exception 'nombre_vacio'; end if;
  insert into public.cursos(nombre,codigo)
  values (trim(p_nombre), public.kimun_gen_codigo_curso()) returning * into r;
  return r; end $$;

create or replace function public.kimun_admin_alumno_agregar(p_clave text, p_curso_codigo text, p_nombre text, p_avatar text)
returns public.perfiles language plpgsql security definer set search_path=public as $$
declare r public.perfiles; c public.cursos; begin
  if not public.kimun_admin_ok(p_clave) then raise exception 'clave_invalida'; end if;
  if coalesce(trim(p_nombre),'') = '' then raise exception 'nombre_vacio'; end if;
  select * into c from public.cursos where codigo = upper(trim(p_curso_codigo));
  if c.id is null then raise exception 'curso_invalido'; end if;
  insert into public.perfiles(id,nombre,avatar,codigo,curso_id,codigo_acceso)
  values (gen_random_uuid(), trim(p_nombre), coalesce(p_avatar,'🦊'),
          public.kimun_gen_codigo(), c.id, public.kimun_gen_codigo_alumno())
  returning * into r;
  return r; end $$;

create or replace function public.kimun_admin_listar(p_clave text)
returns table(curso text, curso_codigo text, alumno text, avatar text, codigo_acceso text, xp int)
language plpgsql security definer set search_path=public as $$
begin
  if not public.kimun_admin_ok(p_clave) then raise exception 'clave_invalida'; end if;
  return query
    select c.nombre, c.codigo, p.nombre, p.avatar, p.codigo_acceso, p.xp
    from public.cursos c
    left join public.perfiles p on p.curso_id = c.id
    order by c.nombre, p.xp desc nulls last, p.nombre;
end $$;

create or replace function public.kimun_admin_alumno_quitar(p_clave text, p_codigo_acceso text)
returns void language plpgsql security definer set search_path=public as $$
begin
  if not public.kimun_admin_ok(p_clave) then raise exception 'clave_invalida'; end if;
  delete from public.perfiles where codigo_acceso = upper(trim(p_codigo_acceso));
end $$;
```

- [ ] **Paso 2: Agregar los permisos**

Añadir al `grant execute` final:

```sql
  , public.kimun_admin_curso_crear(text,text), public.kimun_admin_alumno_agregar(text,text,text,text),
  public.kimun_admin_listar(text), public.kimun_admin_alumno_quitar(text,text)
```

(`kimun_admin_ok` **no** se otorga: solo la usan las otras funciones.)

- [ ] **Paso 3: Fijar la clave real**

La fila `admin_clave` nace con un valor aleatorio cifrado que nadie conoce, de modo que
mientras no se fije una clave el Modo Admin queda **cerrado**, no abierto. Para fijar la
propia, en el SQL Editor:

```sql
update public.config set valor = crypt('<la clave que elija Roberto>', gen_salt('bf'))
where clave='admin_clave';
```

La clave se guarda con hash (bcrypt), nunca en texto plano.

- [ ] **Paso 4: Verificar la creación de un curso y un alumno**

```sql
select * from public.kimun_admin_curso_crear('<clave>', 'Curso de prueba');
select * from public.kimun_admin_alumno_agregar('<clave>', '<CUR-XXXX del paso anterior>', 'Prueba', '🦊');
select * from public.kimun_admin_listar('<clave>');
```

Esperado: el curso trae su `CUR-XXXX`, el alumno trae `codigo_acceso` `ALU-XXXX` y
`kimun_admin_listar` muestra la fila con XP 0.

Y con clave equivocada:

```sql
select * from public.kimun_admin_listar('clave-mala');
```

Esperado: error `clave_invalida`.

- [ ] **Paso 5: Commit**

```bash
git add supabase/schema.sql
git commit -m "Cursos: funciones de administracion (crear curso, inscribir y listar alumnos)"
```

---

## Fase 2 · Juego

### Tarea 5: Conectar el perfil desde el inicio

Hoy `conectarKimun()` solo corre al abrir el duelo, así que quien juega campañas nunca
existe en el servidor. Esta tarea lo conecta al arrancar.

**Archivos:**
- Modificar: `index.html` (estado `S`, `cargar()`, arranque)

- [ ] **Paso 1: Agregar el estado del curso**

En la definición del estado inicial `S`, junto a los demás campos, agregar:

```js
 curso:null,        // {nombre} del curso al que pertenece el alumno
 alumno:null,       // nombre del perfil del servidor, si canjeó un código
```

En `guardar()` (`index.html:1434`), agregar los dos campos al objeto que se serializa:

```js
  campañasCompletas:[...S.campañasCompletas], insignias:[...S.insignias], insigniaActiva:S.insigniaActiva,
  calc:S.calc, curso:S.curso, alumno:S.alumno}));}catch(e){}}
```

En `cargar()` (`index.html:1445`), después de la línea de `S.calc`, agregar:

```js
 S.curso=d.curso||null; S.alumno=d.alumno||null;
```

- [ ] **Paso 2: Conectar al arrancar, sin bloquear**

Después de la llamada a `cargar()` del arranque, agregar:

```js
// Perfil en el servidor desde el inicio (antes solo se creaba al entrar al duelo).
// No bloquea: si falla, el juego funciona igual y se reintenta en la próxima sesión.
setTimeout(async ()=>{
  const p = await conectarKimun();
  if(!p) return;
  if(p.codigo_acceso){ S.alumno = p.nombre; S.nombre = p.nombre; S.avatar = p.avatar; }
  await cargarCurso();
  guardar(); refreshHud();
}, 1200);
```

- [ ] **Paso 3: Agregar `cargarCurso()`**

Junto a `conectarKimun()`:

```js
// Guarda el nombre del curso del jugador (o null) leyendo la primera fila del ranking
async function cargarCurso(){
 if(!SB) return null;
 try{
  const {data,error}=await SB.rpc('kimun_ranking');
  if(error) throw error;
  S.curso = (data && data.length) ? {nombre:data[0].curso} : null;
  return S.curso;
 }catch(e){ console.error('Curso:',e.message||e); return null; }
}
```

- [ ] **Paso 4: Verificar**

Abrir el juego, esperar 2 segundos y ejecutar en la consola:

```js
MI_PERFIL
```

Esperado: un objeto con `id`, `nombre`, `codigo` (`KIM-XXXX`) — **sin haber entrado al
duelo**.

- [ ] **Paso 5: Commit**

```bash
git add index.html
git commit -m "Cursos: el perfil se crea al iniciar el juego, no solo en el duelo"
```

---

### Tarea 6: Canje del código de alumno

**Archivos:**
- Modificar: `index.html` (pantalla `scr-rol`, pantalla nueva `scr-canje`)

- [ ] **Paso 1: Agregar el enlace en el inicio**

En `scr-rol`, después del párrafo del botón "Empezar de nuevo" (línea del `btnReset`),
agregar:

```html
    <p style="text-align:center;margin-top:8px">
      <a href="#" id="btnCanje" style="color:var(--cyan);font-weight:800;font-size:13px">🎟️ Tengo un código</a>
    </p>
```

- [ ] **Paso 2: Agregar la pantalla de canje**

Después de la sección `scr-rol`, agregar:

```html
  <section class="screen" id="scr-canje">
    <div class="card">
      <h3>🎟️ Tengo un código</h3>
      <p style="color:var(--dim);font-weight:800;font-size:13px">
        Escribe el código que te dio tu profesor para entrar al ranking de tu curso.
      </p>
      <input id="canjeCodigo" placeholder="ALU-XXXXXXXX" maxlength="12"
             style="width:100%;padding:12px;border-radius:12px;border:2px solid var(--violet);
                    background:#1a1440;color:#fff;font-weight:900;text-align:center;font-size:18px;margin:10px 0">
      <button class="btn" id="btnCanjeOk">Entrar</button>
      <button class="btn sec" id="btnCanjeBack">← Volver</button>
      <p id="canjeMsg" style="text-align:center;font-weight:800;font-size:13px;margin-top:10px"></p>
    </div>
  </section>
```

- [ ] **Paso 3: Agregar la lógica**

Junto a los demás manejadores del inicio:

```js
$('btnCanje').onclick=(e)=>{e.preventDefault();SND.tap();$('canjeMsg').textContent='';
 $('canjeCodigo').value='';go('scr-canje');};
$('btnCanjeBack').onclick=()=>{SND.tap();go('scr-rol');};
$('btnCanjeOk').onclick=async ()=>{
 SND.tap();
 const cod=($('canjeCodigo').value||'').trim().toUpperCase();
 if(!cod){$('canjeMsg').style.color='var(--pink)';$('canjeMsg').textContent='Escribe tu código.';return;}
 if(!SB){$('canjeMsg').style.color='var(--pink)';$('canjeMsg').textContent='Necesitas conexión a internet.';return;}
 $('canjeMsg').style.color='var(--dim)';$('canjeMsg').textContent='Comprobando…';
 try{
  await conectarKimun();                       // asegura sesión anónima
  const {data,error}=await SB.rpc('kimun_canjear',{p_codigo:cod});
  if(error) throw error;
  const p=Array.isArray(data)?data[0]:data;
  MI_PERFIL=p;
  S.alumno=p.nombre; S.nombre=p.nombre; S.avatar=p.avatar;
  await SB.rpc('kimun_xp',{p_xp:S.xp});        // conserva el avance local
  await cargarCurso();
  guardar(); refreshHud();
  $('canjeMsg').style.color='var(--green)';
  $('canjeMsg').textContent='¡Listo, '+p.nombre+'! Ya estás en '+(S.curso?S.curso.nombre:'tu curso')+'.';
  SND.unlock();
  setTimeout(()=>go('scr-rol'),1600);
 }catch(e){
  $('canjeMsg').style.color='var(--pink)';
  $('canjeMsg').textContent=(e.message||'').includes('codigo_invalido')
    ? 'Ese código no existe. Revísalo con tu profesor.'
    : 'No se pudo conectar. Intenta de nuevo.';
 }
};
```

> **Correcciones aplicadas durante la implementación.** El `maxlength` del campo era 8,
> heredado de cuando el código de alumno tenía 4 caracteres; tras subirlo a 8 por seguridad,
> el código completo mide 12 (`ALU-` + 8) y el campo lo truncaba, de modo que **el canje era
> imposible**. Además, el canje ahora pone `_rankUlt=0` y limpia `kimun_rank`: sin eso, el
> limitador de 30 segundos dejaba el ranking mostrando "Pide tu código…" durante medio
> minuto después de un canje exitoso, y podía asomar por un instante el ranking del curso
> anterior si el mismo teléfono canjeaba otro código.

- [ ] **Paso 4: Verificar el caso correcto**

Con el `ALU-XXXX` creado en la Tarea 4: abrir el juego → "Tengo un código" → escribirlo →
Entrar.
Esperado: mensaje verde con el nombre del alumno y, en consola, `S.curso` con el nombre
del curso.

- [ ] **Paso 5: Verificar el caso incorrecto**

Repetir con `ALU-ZZZZ`.
Esperado: "Ese código no existe. Revísalo con tu profesor." y ningún error de JS en consola.

- [ ] **Paso 6: Commit**

```bash
git add index.html
git commit -m "Cursos: canje del codigo de alumno desde el inicio"
```

---

### Tarea 7: Sincronización del XP

**Archivos:**
- Modificar: `index.html` (junto a `cargarCurso`, y los puntos donde se otorga XP)

- [ ] **Paso 1: Agregar el sincronizador con límite de frecuencia**

```js
// Sube el XP al servidor como máximo una vez cada 15 s, con el valor más reciente.
let _xpTimer=null, _xpUlt=0;
function sincronizarXP(){
 if(!SB||!MI_PERFIL) return;
 if(_xpTimer) return;                       // ya hay un envío programado
 const espera = Math.max(0, 15000-(Date.now()-_xpUlt));
 _xpTimer=setTimeout(async ()=>{
  _xpTimer=null; _xpUlt=Date.now();
  try{
   const {data,error}=await SB.rpc('kimun_xp',{p_xp:S.xp});
   if(error) throw error;
   // El servidor manda: si el adulto corrigió un XP inflado, el teléfono lo adopta.
   // Hay que guardar: si no, al reabrir el juego se volvería a enviar el XP viejo
   // desde el disco y la corrección del adulto se desharía sola.
   if(typeof data==='number' && data < S.xp){ S.xp=data; refreshHud(); guardar(); }
  }catch(e){ console.error('XP:',e.message||e); }  // best-effort: no interrumpe el juego
 }, espera);
}
```

**Por qué el cliente adopta el valor del servidor:** `kimun_xp` es monótona, así que un XP
inflado desde la consola sería permanente. El adulto puede corregirlo con
`kimun_admin_xp_fijar`, pero si el teléfono siguiera enviando su XP local inflado, la
corrección se revertiría en el siguiente envío. Adoptando el valor devuelto cuando es
menor, el ajuste del adulto se propaga al teléfono. Esto no impide falsificar el XP —eso
sigue siendo la limitación asumida en el diseño—, pero devuelve el control al adulto.

- [ ] **Paso 2: Llamarlo desde un único punto**

El XP se otorga en cinco lugares distintos (`index.html:1331`, `1347`, `1367`, `1840` y
`2191`), y todos terminan llamando a `guardar()`. En vez de repetir la llamada cinco veces
—y arriesgarse a olvidar una al agregar contenido nuevo—, se engancha en `guardar()`, que
es el único punto por el que pasa todo cambio de estado. El límite de 15 segundos del paso
anterior hace que esto no genere tráfico extra.

En `guardar()` (`index.html:1438`), cambiar la última línea:

```js
  calc:S.calc, curso:S.curso, alumno:S.alumno}));sincronizarXP();}catch(e){}}
```

Queda dentro del `try`, así que si algo fallara no interrumpe el guardado local.

- [ ] **Paso 3: Verificar**

Jugar una etapa completa y luego, en la consola:

```js
S.xp
```

Esperar 15 segundos y consultar en el SQL Editor:

```sql
select nombre, xp from public.perfiles where codigo_acceso is not null order by xp desc;
```

Esperado: el XP del alumno coincide con `S.xp`.

- [ ] **Paso 4: Verificar que es monótono**

En consola: `S.xp = 10; sincronizarXP();` y esperar 15 s.
Esperado: el XP del servidor **no baja**; conserva el valor anterior.

- [ ] **Paso 5: Commit**

```bash
git add index.html
git commit -m "Cursos: sincronizacion del XP al servidor (monotona, con limite de frecuencia)"
```

---

### Tarea 8: Ranking real con sus tres estados

**Archivos:**
- Modificar: `index.html:2107-2114` (`renderRanking`)

- [ ] **Paso 1: Reemplazar `renderRanking` completa**

```js
// Ranking real del curso. Tres estados: con curso, sin curso y sin conexión.
let _rankUlt=0;
function renderRanking(){
 const el=$('ranking');
 const cache=JSON.parse(localStorage.getItem('kimun_rank')||'null');
 if(cache) pintarRanking(cache);                       // muestra lo último mientras carga
 if(!SB||!MI_PERFIL){ if(!cache) pintarSinCurso(); return; }
 if(Date.now()-_rankUlt < 30000) return;               // como máximo una consulta cada 30 s
 _rankUlt=Date.now();
 SB.rpc('kimun_ranking').then(({data,error})=>{
  if(error) throw error;
  if(!data||!data.length){ pintarSinCurso(); localStorage.removeItem('kimun_rank'); return; }
  localStorage.setItem('kimun_rank',JSON.stringify(data));
  pintarRanking(data);
 }).catch(e=>{
  console.error('Ranking:',e.message||e);
  if(!cache) el.innerHTML='<p style="color:var(--dim);font-weight:800;font-size:13px;text-align:center">Sin conexión. El ranking se actualizará más tarde.</p>';
 });
}
function pintarRanking(filas){
 $('ranking').innerHTML=filas.map((r,i)=>
  `<div class="rk ${i<1?'top':''} ${r.soy_yo?'me':''}"><div class="pos">${i+1}</div>
   <div class="em">${r.soy_yo?avatarHTML(S.avatar):r.avatar}</div>
   <div>${r.soy_yo?insigniaIc():''}${r.nombre}${r.soy_yo?' (tú)':''}</div>
   <div class="pts">${r.xp} XP</div></div>`).join('');
}
function pintarSinCurso(){
 $('ranking').innerHTML=
  `<p style="color:var(--dim);font-weight:800;font-size:13px;text-align:center;margin-bottom:10px">
     Pide tu código para entrar al ranking de tu curso.</p>
   <button class="btn sec" onclick="go('scr-canje')">🎟️ Tengo un código</button>`;
}
```

- [ ] **Paso 2: Verificar el estado "con curso"**

Con dos alumnos creados y XP distinto (usar `kimun_xp` desde el SQL Editor para darle XP al
segundo), abrir el juego con un código canjeado y mirar el mapa.
Esperado: los dos alumnos ordenados por XP de mayor a menor, con el propio resaltado y sin
rastro de Vale, Nico, Fran ni Diego.

- [ ] **Paso 3: Verificar el estado "sin curso"**

En consola: `localStorage.removeItem('kimun_rank')`, luego borrar el vínculo desde el SQL
Editor (`delete from vinculos where perfil_id = (select id from perfiles where codigo_acceso='ALU-XXXX')`)
y recargar.
Esperado: el mensaje "Pide tu código…" con el botón, sin errores.

- [ ] **Paso 4: Verificar el estado "sin conexión"**

En consola: `SB.rpc = () => Promise.reject(new Error('offline')); renderRanking();`
Esperado: se mantiene el ranking en caché (o el mensaje de sin conexión si no hay caché), y
el juego sigue navegable.

- [ ] **Paso 5: Commit**

```bash
git add index.html
git commit -m "Ranking real: tres estados (curso, sin curso, sin conexion) y fin de los nombres simulados"
```

---

### Tarea 9: Panel de administración de cursos

**Archivos:**
- Modificar: `index.html` (`btnAdmin`, pantalla nueva `scr-admin`)

- [ ] **Paso 1: Agregar la pantalla**

Después de `scr-canje`:

```html
  <section class="screen" id="scr-admin">
    <div class="card">
      <h3>🔧 Modo Admin</h3>
      <input id="admClave" type="password" placeholder="Contraseña"
             style="width:100%;padding:12px;border-radius:12px;border:2px solid var(--violet);
                    background:#1a1440;color:#fff;font-weight:800;margin-bottom:10px">
      <button class="btn" id="btnAdmEntrar">Entrar a Cursos</button>
      <button class="btn sec" id="btnAdmTablero">📊 Tablero de avance</button>
      <button class="btn sec" id="btnAdmBack">← Volver</button>
      <p id="admMsg" style="text-align:center;font-weight:800;font-size:13px;margin-top:8px"></p>
    </div>
    <div class="card" id="admPanel" style="display:none">
      <h3>Cursos</h3>
      <input id="admCursoNombre" placeholder="Nombre del curso (8° A)"
             style="width:100%;padding:10px;border-radius:12px;border:2px solid var(--violet);
                    background:#1a1440;color:#fff;font-weight:800;margin-bottom:8px">
      <button class="btn sec" id="btnAdmCurso">+ Crear curso</button>
      <div style="height:10px"></div>
      <input id="admAlumnoCurso" placeholder="Código del curso (CUR-XXXX)" maxlength="8"
             style="width:100%;padding:10px;border-radius:12px;border:2px solid var(--violet);
                    background:#1a1440;color:#fff;font-weight:800;margin-bottom:8px">
      <input id="admAlumnoNombre" placeholder="Nombre del alumno"
             style="width:100%;padding:10px;border-radius:12px;border:2px solid var(--violet);
                    background:#1a1440;color:#fff;font-weight:800;margin-bottom:8px">
      <button class="btn sec" id="btnAdmAlumno">+ Agregar alumno</button>
      <div id="admLista" style="margin-top:14px"></div>
    </div>
  </section>
```

- [ ] **Paso 2: Reemplazar el manejador de `btnAdmin`**

Sustituir la línea actual (`index.html:1695`):

```js
$('btnAdmin').onclick=()=>{window.location.href='dev/tablero.html';};
```

por:

```js
$('btnAdmin').onclick=()=>{SND.tap();$('admMsg').textContent='';$('admPanel').style.display='none';
 $('admClave').value='';go('scr-admin');};
$('btnAdmTablero').onclick=()=>{window.location.href='dev/tablero.html';};
$('btnAdmBack').onclick=()=>{SND.tap();go('scr-rol');};
```

- [ ] **Paso 3: Agregar la lógica del panel**

```js
let ADM_CLAVE='';                                   // solo en memoria, nunca se guarda
$('btnAdmEntrar').onclick=async ()=>{
 SND.tap(); ADM_CLAVE=$('admClave').value||'';
 if(!SB){$('admMsg').style.color='var(--pink)';$('admMsg').textContent='Necesitas conexión.';return;}
 try{ await conectarKimun(); await admListar(); $('admPanel').style.display='block';
      $('admMsg').textContent=''; }
 catch(e){ $('admMsg').style.color='var(--pink)';
           $('admMsg').textContent='Contraseña incorrecta.'; $('admPanel').style.display='none'; }
};
async function admListar(){
 const {data,error}=await SB.rpc('kimun_admin_listar',{p_clave:ADM_CLAVE});
 if(error) throw error;
 const porCurso={};
 (data||[]).forEach(f=>{ (porCurso[f.curso_codigo] = porCurso[f.curso_codigo] || {nombre:f.curso, alumnos:[]});
   if(f.codigo_acceso) porCurso[f.curso_codigo].alumnos.push(f); });
 $('admLista').innerHTML=Object.entries(porCurso).map(([cod,c])=>
  `<div style="margin-bottom:14px">
     <b style="color:var(--gold)">${c.nombre}</b>
     <small style="color:var(--cyan);font-weight:900"> ${cod}</small>
     ${c.alumnos.length?c.alumnos.map(a=>
       `<div style="display:flex;align-items:center;gap:8px;padding:6px 0;border-bottom:1px solid #ffffff14">
          <span>${a.avatar}</span><b style="flex:1">${a.alumno}</b>
          <code style="color:var(--cyan);font-weight:900">${a.codigo_acceso}</code>
          <span style="color:var(--dim);font-weight:800">${a.xp} XP</span>
          <button class="adm-del" data-cod="${a.codigo_acceso}"
                  style="background:none;border:none;color:var(--pink);font-weight:900;cursor:pointer">✕</button>
        </div>`).join('')
      :'<p style="color:var(--dim);font-weight:800;font-size:12px">Sin alumnos todavía.</p>'}
   </div>`).join('') || '<p style="color:var(--dim);font-weight:800;font-size:13px">Aún no hay cursos.</p>';
 // Eliminar alumno (el diseño no contempla editar: se borra y se agrega de nuevo)
 $('admLista').querySelectorAll('.adm-del').forEach(b=>b.onclick=async ()=>{
  if(!confirm('¿Eliminar a este alumno? Perderá su lugar en el ranking.')) return;
  try{ await SB.rpc('kimun_admin_alumno_quitar',{p_clave:ADM_CLAVE,p_codigo_acceso:b.dataset.cod});
       await admListar(); }
  catch(e){ alert('No se pudo eliminar.'); }
 });
}
$('btnAdmCurso').onclick=async ()=>{
 SND.tap();
 const n=($('admCursoNombre').value||'').trim();
 if(!n) return;
 try{ await SB.rpc('kimun_admin_curso_crear',{p_clave:ADM_CLAVE,p_nombre:n});
      $('admCursoNombre').value=''; await admListar(); }
 catch(e){ alert('No se pudo crear el curso.'); }
};
$('btnAdmAlumno').onclick=async ()=>{
 SND.tap();
 const c=($('admAlumnoCurso').value||'').trim().toUpperCase();
 const n=($('admAlumnoNombre').value||'').trim();
 if(!c||!n) return;
 try{ await SB.rpc('kimun_admin_alumno_agregar',{p_clave:ADM_CLAVE,p_curso_codigo:c,p_nombre:n,p_avatar:'🦊'});
      $('admAlumnoNombre').value=''; await admListar(); }
 catch(e){ alert('No se pudo agregar al alumno. Revisa el código del curso.'); }
};
```

> **Corrección aplicada durante la implementación.** El código de `btnAdmCurso`,
> `btnAdmAlumno` y el borrado con ✕ que aparece arriba tiene un defecto: `supabase-js`
> **no lanza excepción** cuando la función SQL falla, devuelve `{data, error}`. Como esos
> tres manejadores ignoraban el resultado, un código de curso mal escrito no mostraba
> ningún error: el campo se limpiaba y el alumno no aparecía, sin explicación. La versión
> implementada captura el error (`const {error}=await SB.rpc(...); if(error) throw error;`),
> traduce los mensajes del backend (`clave_invalida`, `curso_invalido`, `nombre_vacio`,
> `alumno_invalido`) a texto entendible en `admMsg`, y desactiva los botones mientras dura
> la llamada, que puede tardar más de seis segundos.

- [ ] **Paso 4: Verificar el flujo completo**

Inicio → Modo Admin → clave correcta → crear "8° A" → agregar "Matías" con el `CUR-XXXX`
que aparece.
Esperado: la lista muestra el curso con Matías, su `ALU-XXXX` y `0 XP`.

- [ ] **Paso 5: Verificar la clave incorrecta**

Repetir con una clave errónea.
Esperado: "Contraseña incorrecta." y el panel no se abre.

- [ ] **Paso 6: Verificar la eliminación de un alumno**

Pulsar la ✕ de un alumno de prueba y confirmar.
Esperado: desaparece de la lista; en el SQL Editor,
`select count(*) from perfiles where codigo_acceso='ALU-XXXX'` devuelve `0`.

- [ ] **Paso 7: Commit**

```bash
git add index.html
git commit -m "Cursos: panel de administracion dentro del juego (crear curso e inscribir alumnos)"
```

---

## Fase 3 · Cierre

### Tarea 10: Regresiones y documentación

**Archivos:**
- Modificar: `CLAUDE.md`

- [ ] **Paso 1: Probar que el duelo sigue funcionando**

Duelo 1v1 → En línea → desafiar a un bot y completar la ronda.
Esperado: resultado inmediato con ganador, sin errores en consola.

- [ ] **Paso 2: Probar el juego sin Supabase**

`SB` es una constante, así que no se puede reasignar a null. Se simula la caída
reemplazando su método:

```js
const rpcReal = SB.rpc.bind(SB);
SB.rpc = () => Promise.reject(new Error('sin conexion simulada'));
// recorrer ranking, guardar, expediciones, tienda, perfil y mapa
SB.rpc = rpcReal;   // restaurar al terminar
```

Esperado: el juego navega normal; el ranking muestra "Sin conexión…" y nada lanza
excepción. En la consola solo deben aparecer los `console.error` controlados
(`Ranking:` y `XP:`).

- [ ] **Paso 3: Probar un jugador nuevo sin curso**

Borrar el almacenamiento del navegador y entrar como jugador nuevo.
Esperado: juega normal, y en el ranking ve "Pide tu código…" en lugar de los nombres
simulados.

- [ ] **Paso 4: Documentar en `CLAUDE.md`**

En "Herramientas de desarrollo", agregar una subsección **Cursos y ranking** que explique:
que el ranking es real y por curso; que los cursos y alumnos se crean desde Inicio → Modo
Admin → Cursos; que la clave se guarda en la tabla `config` de Supabase y se cambia con
`update public.config set valor='…' where clave='admin_clave';`; y que el alumno entra con
"Tengo un código".

- [ ] **Paso 5: Commit**

```bash
git add CLAUDE.md
git commit -m "Documentar cursos y ranking real"
```

---

## Correcciones aplicadas a la Fase 1 tras la revisión de seguridad

La revisión del SQL implementado encontró defectos que el plan original no contemplaba.
Quedaron corregidos en `supabase/schema.sql` y se anotan aquí para que el documento no
mienta respecto del código:

| Corrección | Motivo |
| --- | --- |
| La clave de administración nace aleatoria y se guarda con bcrypt | El valor de relleno quedaba en un repositorio público: sin cambiarlo, cualquiera podía listar y borrar alumnos |
| `revoke execute … from public` sobre `kimun_admin_ok` y los generadores de código | PostgreSQL otorga EXECUTE a PUBLIC por defecto: omitirlas del `grant` **no** las protegía, y `kimun_admin_ok` servía como oráculo para probar claves |
| El código de alumno pasó a 8 caracteres | Con 4 eran 65.536 combinaciones: fuerza bruta en minutos sobre una función expuesta y sin límite de intentos |
| `kimun_crear_duelo` lanza `sin_perfil` si no hay vínculo | Antes producía un error opaco de restricción `not null` |
| `kimun_jugadores` solo lista bots y perfiles con vínculo activo | Tras el canje quedaban dos perfiles con el mismo nombre, y los duelos al perfil viejo no le llegaban a nadie |
| Nueva `kimun_admin_xp_fijar(clave, codigo_acceso, xp)` | El XP es monótono: un XP inflado desde la consola era irreversible, incluso para el adulto |
| La migración de vínculos filtra `codigo_acceso is null` | Al re-ejecutar el esquema creaba una fila basura por cada alumno inscrito |
| `kimun_admin_alumno_quitar` devuelve el número de filas y lanza `alumno_invalido` | Un código mal escrito se veía igual que un borrado correcto |

Una segunda revisión encontró además que `crypt()` no se resolvía dentro de las funciones:
en Supabase pgcrypto vive en el esquema `extensions`, no en `public`, de modo que el
`create extension` del archivo es un no-op y el `search_path` fijado a `public` dejaba la
función sin encontrar. (`gen_random_uuid()` no sufre el problema porque desde PostgreSQL 13
es nativa del núcleo.) Las funciones que usan pgcrypto declaran ahora
`set search_path = public, extensions`.

**Consecuencias para la Fase 2:**

- `kimun_crear_duelo` puede devolver el error `sin_perfil`. La Tarea 5 ya conecta el perfil
  al iniciar el juego, así que no debería ocurrir; si el manejo de errores del duelo muestra
  el mensaje crudo, conviene traducirlo.
- **Antes de canjear conviene no tener duelos pendientes.** Al canjear, el código de amigo
  efectivo del jugador cambia, así que un duelo que estuviera esperando respuesta contra el
  perfil anterior deja de verse y caduca a las 24 horas.

## Notas para quien ejecute

- **El SQL lo aplica Roberto**, pegando `supabase/schema.sql` completo en el SQL Editor. El
  archivo es idempotente: se puede volver a ejecutar sin romper datos.
- **La clave de administración nunca se guarda en el JavaScript**: se escribe cada vez y
  viaja al servidor, que la compara contra `config`. Es una mejora respecto del tablero
  actual, donde la clave está en el código generado.
- **El orden importa**: las tareas 5 a 9 dependen de que el backend (1 a 4) esté aplicado en
  Supabase. Sin eso, las llamadas RPC fallan y las verificaciones no sirven.
- Si una verificación falla, no continuar a la tarea siguiente: el problema se arrastra.
