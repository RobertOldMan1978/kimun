# Rol de profesor · Plan de implementación

> **Para quien ejecute este plan:** usa `superpowers:subagent-driven-development`
> (recomendado) o `superpowers:executing-plans`, tarea por tarea. Los pasos usan
> casillas (`- [ ]`) para seguimiento.

**Objetivo:** que existan cuentas de profesor que administren sus propios cursos, con
aislamiento real entre docentes, reemplazando la clave global compartida.

**Arquitectura:** el backend gana `profesores` (una fila por cuenta de Supabase Auth),
`profesores_autorizados` (lista blanca de correos) y `cursos.profesor_id`. Las funciones
nuevas `kimun_prof_*` identifican al profesor por su sesión (`auth.uid()`) y ya no reciben
ninguna clave. La administración se muda a una página propia, `profesor.html`, con un
cliente de Supabase de almacenamiento separado para no pisar la sesión del alumno. El Modo
Admin desaparece del juego.

**Tecnología:** Supabase (PostgreSQL + Auth), JavaScript sin framework.

**Diseño de referencia:** `docs/superpowers/specs/2026-08-18-rol-profesor-design.md`

---

## Cómo se verifica en este proyecto

No hay framework de pruebas: es un sitio estático con contenido en JSON. Se verifica en el
navegador con `preview_start` + `javascript_tool`, y en el SQL Editor de Supabase. Cada
tarea define su verificación con el resultado esperado.

Roberto aplica el SQL pegando `supabase/schema.sql` **completo** en el SQL Editor; el
archivo es idempotente.

**Advertencia de orden:** las tareas 8 a 10 desmontan el acceso actual. Si se ejecutan
antes de que Roberto tenga su cuenta de profesor funcionando, **nadie puede administrar
nada**. No adelantarlas.

## Archivos que se tocan

| Archivo | Responsabilidad |
| --- | --- |
| `supabase/schema.sql` | Modificar: tablas, columna, funciones nuevas; al final, eliminar las de clave |
| `profesor.html` | Crear: ingreso, registro y panel del profesor |
| `index.html` | Modificar: retirar el botón Modo Admin, la pantalla `scr-admin` y su JavaScript |
| `CLAUDE.md` | Modificar: documentar el modelo nuevo y el retiro del anterior |

---

## Fase 1 · Backend

### Tarea 1: Tablas de profesores y dueño de los cursos

**Archivos:**
- Modificar: `supabase/schema.sql`

- [ ] **Paso 1: Agregar las tablas y la columna**

Insertar después de la tabla `config` (alrededor de la línea 65):

```sql
-- Profesores: una fila por cuenta de Supabase Auth. Los permisos viven aquí,
-- no en la cuenta: sin fila en esta tabla, una cuenta no puede hacer nada.
create table if not exists public.profesores (
  id       uuid primary key,                 -- auth.uid() de su cuenta
  correo   text unique not null,
  nombre   text,
  es_admin boolean not null default false,
  creado   timestamptz not null default now()
);

-- Lista blanca: solo estos correos pueden completar su registro.
create table if not exists public.profesores_autorizados (
  correo       text primary key,
  invitado_por uuid references public.profesores(id) on delete set null,
  como_admin   boolean not null default false,   -- la primera alta hereda esta marca
  usado        boolean not null default false,
  creado       timestamptz not null default now()
);

-- Dueño del curso. Nulo = curso huérfano, visible solo para administradores.
alter table public.cursos add column if not exists profesor_id uuid
  references public.profesores(id) on delete set null;

-- Semilla: el correo del dueño de la plataforma, como administrador.
insert into public.profesores_autorizados(correo, como_admin)
values ('thingol25@gmail.com', true)
on conflict (correo) do nothing;
```

> **Confirmar con Roberto** que ese es el correo con el que quiere crear su cuenta de
> administrador. Si prefiere otro, se cambia esa línea antes de aplicar el esquema.

- [ ] **Paso 2: Activar RLS en las tablas nuevas**

Agregar al bloque de RLS existente (donde ya están `perfiles`, `duelos`, `cursos`,
`vinculos` y `config`):

```sql
alter table public.profesores             enable row level security;
alter table public.profesores_autorizados enable row level security;
```

Sin políticas: como el resto del esquema, solo se accede por funciones `SECURITY DEFINER`.
Esto es importante aquí porque `profesores_autorizados` revela qué correos pueden
registrarse.

- [ ] **Paso 3: Aplicar y verificar**

Pegar `supabase/schema.sql` completo en el SQL Editor y ejecutar. Luego:

```sql
select count(*) from public.profesores_autorizados where como_admin;
```

Esperado: `1`.

```sql
select column_name from information_schema.columns
where table_name='cursos' and column_name='profesor_id';
```

Esperado: 1 fila.

- [ ] **Paso 4: Commit**

```bash
git add supabase/schema.sql
git commit -m "Profesores: tablas, lista blanca y dueno de los cursos"
```

---

### Tarea 2: Identidad del profesor

**Archivos:**
- Modificar: `supabase/schema.sql`

- [ ] **Paso 1: Agregar los tres helpers**

Insertar antes del bloque de funciones de administración actual:

```sql
-- Mi fila de profesor, o null si esta cuenta no tiene permisos.
create or replace function public.kimun_prof_yo()
returns public.profesores language sql security definer stable set search_path=public as $$
  select * from public.profesores where id = auth.uid(); $$;

-- Completa el registro. El correo NO se pasa por parámetro: se toma de la sesión,
-- para que nadie pueda registrarse con el correo autorizado de otra persona.
create or replace function public.kimun_prof_alta(p_nombre text)
returns public.profesores language plpgsql security definer set search_path=public as $$
declare mi_correo text; aut public.profesores_autorizados; r public.profesores; begin
  if auth.uid() is null then raise exception 'sin_sesion'; end if;
  select email into mi_correo from auth.users where id = auth.uid();
  if mi_correo is null then raise exception 'sin_correo'; end if;
  select * into aut from public.profesores_autorizados where lower(correo) = lower(mi_correo);
  if aut.correo is null then raise exception 'no_autorizado'; end if;
  insert into public.profesores(id, correo, nombre, es_admin)
  values (auth.uid(), lower(mi_correo), nullif(trim(p_nombre),''), aut.como_admin)
  on conflict (id) do update set nombre = coalesce(excluded.nombre, public.profesores.nombre)
  returning * into r;
  update public.profesores_autorizados set usado = true where lower(correo) = lower(mi_correo);
  return r; end $$;

-- ¿Ese curso es mío? Los administradores pasan siempre.
create or replace function public.kimun_prof_es_mio(p_curso uuid)
returns boolean language sql security definer stable set search_path=public as $$
  select exists(
    select 1 from public.cursos c, public.profesores p
    where p.id = auth.uid() and c.id = p_curso
      and (p.es_admin or c.profesor_id = p.id)); $$;
```

`kimun_prof_alta` consulta `auth.users`, que es accesible porque la función es
`SECURITY DEFINER` y su propietario es el rol que creó el esquema.

- [ ] **Paso 2: Otorgar permisos**

Agregar al `grant execute` final:

```sql
  , public.kimun_prof_yo(), public.kimun_prof_alta(text)
```

`kimun_prof_es_mio` **no** se otorga: solo la usan las otras funciones. Agregarla al
`revoke execute ... from public` existente, junto a `kimun_admin_ok`.

- [ ] **Paso 3: Verificar el rechazo de un correo no autorizado**

En el SQL Editor no hay sesión de usuario, así que esto se comprueba desde la página del
profesor en la Tarea 5. Aquí basta con confirmar que las funciones existen:

```sql
select proname from pg_proc where proname in ('kimun_prof_yo','kimun_prof_alta','kimun_prof_es_mio');
```

Esperado: 3 filas.

- [ ] **Paso 4: Commit**

```bash
git add supabase/schema.sql
git commit -m "Profesores: identidad por sesion (kimun_prof_yo, alta y es_mio)"
```

---

### Tarea 3: Gestión de cursos y alumnos por el profesor

**Archivos:**
- Modificar: `supabase/schema.sql`

- [ ] **Paso 1: Agregar las seis funciones**

```sql
-- Mis cursos con sus alumnos. Un administrador ve todos, incluidos los huérfanos.
create or replace function public.kimun_prof_listar()
returns table(curso text, curso_codigo text, alumno text, avatar text,
              codigo_acceso text, xp int, dificil int)
language plpgsql security definer set search_path=public as $$
declare yo public.profesores; begin
  select * into yo from public.profesores where id = auth.uid();
  if yo.id is null then raise exception 'no_autorizado'; end if;
  return query
    select c.nombre, c.codigo, p.nombre, p.avatar, p.codigo_acceso, p.xp, p.dificil
    from public.cursos c
    left join public.perfiles p on p.curso_id = c.id
    where yo.es_admin or c.profesor_id = yo.id
    order by c.nombre, p.xp desc nulls last, p.nombre;
end $$;

create or replace function public.kimun_prof_curso_crear(p_nombre text)
returns public.cursos language plpgsql security definer set search_path=public as $$
declare yo public.profesores; r public.cursos; begin
  select * into yo from public.profesores where id = auth.uid();
  if yo.id is null then raise exception 'no_autorizado'; end if;
  if coalesce(trim(p_nombre),'') = '' then raise exception 'nombre_vacio'; end if;
  insert into public.cursos(nombre, codigo, profesor_id)
  values (trim(p_nombre), public.kimun_gen_codigo_curso(), yo.id) returning * into r;
  return r; end $$;

-- Elimina un curso mío y sus alumnos (arrastra los duelos de esos alumnos).
create or replace function public.kimun_prof_curso_quitar(p_curso_codigo text)
returns int language plpgsql security definer set search_path=public as $$
declare cid uuid; n int; begin
  select id into cid from public.cursos where codigo = upper(trim(p_curso_codigo));
  if cid is null then raise exception 'curso_invalido'; end if;
  if not public.kimun_prof_es_mio(cid) then raise exception 'no_autorizado'; end if;
  delete from public.perfiles where curso_id = cid;
  get diagnostics n = row_count;
  delete from public.cursos where id = cid;
  return n; end $$;

create or replace function public.kimun_prof_alumno_agregar(p_curso_codigo text, p_nombre text, p_avatar text)
returns public.perfiles language plpgsql security definer set search_path=public as $$
declare cid uuid; r public.perfiles; begin
  if coalesce(trim(p_nombre),'') = '' then raise exception 'nombre_vacio'; end if;
  select id into cid from public.cursos where codigo = upper(trim(p_curso_codigo));
  if cid is null then raise exception 'curso_invalido'; end if;
  if not public.kimun_prof_es_mio(cid) then raise exception 'no_autorizado'; end if;
  insert into public.perfiles(id,nombre,avatar,codigo,curso_id,codigo_acceso)
  values (gen_random_uuid(), trim(p_nombre), coalesce(p_avatar,'🦊'),
          public.kimun_gen_codigo(), cid, public.kimun_gen_codigo_alumno())
  returning * into r;
  return r; end $$;

create or replace function public.kimun_prof_alumno_quitar(p_codigo_acceso text)
returns int language plpgsql security definer set search_path=public as $$
declare cid uuid; n int; begin
  select curso_id into cid from public.perfiles where codigo_acceso = upper(trim(p_codigo_acceso));
  if cid is null then raise exception 'alumno_invalido'; end if;
  if not public.kimun_prof_es_mio(cid) then raise exception 'no_autorizado'; end if;
  delete from public.perfiles where codigo_acceso = upper(trim(p_codigo_acceso));
  get diagnostics n = row_count;
  return n; end $$;

-- Corrige el XP de un alumno mío. kimun_xp solo sube, así que esta es la única
-- forma de bajar un valor inflado desde el teléfono.
create or replace function public.kimun_prof_xp_fijar(p_codigo_acceso text, p_xp int)
returns int language plpgsql security definer set search_path=public as $$
declare cid uuid; v int; begin
  select curso_id into cid from public.perfiles where codigo_acceso = upper(trim(p_codigo_acceso));
  if cid is null then raise exception 'alumno_invalido'; end if;
  if not public.kimun_prof_es_mio(cid) then raise exception 'no_autorizado'; end if;
  update public.perfiles set xp = greatest(0, coalesce(p_xp,0))
  where codigo_acceso = upper(trim(p_codigo_acceso)) returning xp into v;
  return v; end $$;
```

Nota sobre `kimun_prof_alumno_quitar` y `kimun_prof_xp_fijar`: un alumno cuyo `curso_id`
sea nulo no pertenece a ningún curso, así que `select curso_id into cid` deja `cid` nulo y
la función responde `alumno_invalido`. Es el comportamiento correcto: nadie puede tocar por
esta vía un perfil que no está en un curso.

- [ ] **Paso 2: Otorgar permisos**

Agregar al `grant execute` final:

```sql
  , public.kimun_prof_listar(), public.kimun_prof_curso_crear(text),
  public.kimun_prof_curso_quitar(text), public.kimun_prof_alumno_agregar(text,text,text),
  public.kimun_prof_alumno_quitar(text), public.kimun_prof_xp_fijar(text,int)
```

- [ ] **Paso 3: Verificar que existen**

```sql
select count(*) from pg_proc where proname like 'kimun_prof_%';
```

Esperado: `9` (los tres de la Tarea 2 más estos seis).

- [ ] **Paso 4: Commit**

```bash
git add supabase/schema.sql
git commit -m "Profesores: gestion de sus cursos y alumnos"
```

---

### Tarea 4: Funciones de administrador

**Archivos:**
- Modificar: `supabase/schema.sql`

- [ ] **Paso 1: Agregar las tres funciones**

```sql
-- Autoriza un correo para que pueda crear su cuenta de profesor.
create or replace function public.kimun_prof_autorizar(p_correo text)
returns public.profesores_autorizados language plpgsql security definer set search_path=public as $$
declare yo public.profesores; r public.profesores_autorizados; begin
  select * into yo from public.profesores where id = auth.uid();
  if yo.id is null or not yo.es_admin then raise exception 'no_autorizado'; end if;
  if coalesce(trim(p_correo),'') !~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$'
    then raise exception 'correo_invalido'; end if;
  insert into public.profesores_autorizados(correo, invitado_por)
  values (lower(trim(p_correo)), yo.id)
  on conflict (correo) do update set invitado_por = excluded.invitado_por
  returning * into r;
  return r; end $$;

-- Lista de profesores y cuántos cursos tiene cada uno.
create or replace function public.kimun_prof_profesores()
returns table(correo text, nombre text, es_admin boolean, cursos int, registrado boolean)
language plpgsql security definer set search_path=public as $$
declare yo public.profesores; begin
  select * into yo from public.profesores where id = auth.uid();
  if yo.id is null or not yo.es_admin then raise exception 'no_autorizado'; end if;
  return query
    select a.correo, p.nombre, coalesce(p.es_admin,false),
           (select count(*)::int from public.cursos c where c.profesor_id = p.id),
           (p.id is not null)
    from public.profesores_autorizados a
    left join public.profesores p on lower(p.correo) = lower(a.correo)
    order by a.creado;
end $$;

-- Reemplaza a kimun_admin_limpiar_pruebas. Cuenta con p_ejecutar=false y borra con true.
create or replace function public.kimun_prof_limpiar_pruebas(p_ejecutar boolean)
returns int language plpgsql security definer set search_path=public as $$
declare yo public.profesores; n int; begin
  select * into yo from public.profesores where id = auth.uid();
  if yo.id is null or not yo.es_admin then raise exception 'no_autorizado'; end if;
  if p_ejecutar then
    delete from public.perfiles where es_bot = false and codigo_acceso is null;
    get diagnostics n = row_count;
  else
    select count(*) into n from public.perfiles where es_bot = false and codigo_acceso is null;
  end if;
  return n; end $$;
```

- [ ] **Paso 2: Otorgar permisos**

```sql
  , public.kimun_prof_autorizar(text), public.kimun_prof_profesores(),
  public.kimun_prof_limpiar_pruebas(boolean)
```

- [ ] **Paso 3: Aplicar el esquema y verificar**

Pegar el archivo completo y ejecutar. Luego:

```sql
select count(*) from pg_proc where proname like 'kimun_prof_%';
```

Esperado: `12`.

- [ ] **Paso 4: Commit**

```bash
git add supabase/schema.sql
git commit -m "Profesores: funciones de administrador (autorizar, listar, limpiar)"
```

---

## Fase 2 · La página del profesor

### Tarea 5: Ingreso y registro

**Archivos:**
- Crear: `profesor.html`

- [ ] **Paso 1: Crear el archivo con su estructura y el cliente aislado**

La clave de esta tarea es el `storageKey`: sin él, iniciar sesión como profesor borra la
sesión anónima del alumno en ese mismo navegador.

```html
<!doctype html>
<html lang="es">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no">
<title>KIMÜN · Profesores</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Nunito:wght@700;900&family=Titan+One&display=swap" rel="stylesheet">
<script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>
<style>
:root{--gold:#ffc93c;--cyan:#4dd8ff;--green:#3ee089;--pink:#ff4d8d;--violet:#8f6bff;
 --dim:#a89fd6;--panel:#241d4e}
*{box-sizing:border-box}
body{margin:0;background:#140f33;color:#fff;font-family:Nunito,sans-serif;font-weight:800;
 padding:16px;max-width:480px;margin:0 auto}
h1{font-family:'Titan One',cursive;color:var(--gold);font-size:28px;text-align:center;margin:12px 0}
.card{background:var(--panel);border:2px solid #ffffff14;border-radius:16px;padding:16px;margin-bottom:14px}
.card h3{margin:0 0 12px;font-size:16px;color:var(--cyan)}
input{width:100%;padding:12px;border-radius:12px;border:2px solid var(--violet);
 background:#1a1440;color:#fff;font-weight:800;margin-bottom:10px;font-family:inherit}
.btn{width:100%;padding:13px;border:0;border-radius:14px;background:var(--gold);color:#2a1c00;
 font-family:inherit;font-weight:900;font-size:15px;cursor:pointer;margin-bottom:8px}
.btn.sec{background:var(--violet);color:#fff}
.btn:disabled{opacity:.5;cursor:default}
.msg{text-align:center;font-size:13px;margin-top:8px;min-height:18px}
.hide{display:none}
code{color:var(--cyan);font-weight:900}
</style>
</head>
<body>
<h1>KIMÜN · Profesores</h1>

<div class="card" id="cardAuth">
  <h3 id="authTitulo">Ingresar</h3>
  <input id="correo" type="email" placeholder="Correo" autocomplete="email">
  <input id="clave" type="password" placeholder="Contraseña" autocomplete="current-password">
  <input id="nombre" class="hide" placeholder="Tu nombre">
  <button class="btn" id="btnEntrar">Entrar</button>
  <button class="btn sec" id="btnCambiar">Crear mi cuenta</button>
  <p class="msg" id="authMsg"></p>
</div>

<div class="card hide" id="cardPanel">
  <h3 id="panelTitulo">Mis cursos</h3>
  <div id="lista"></div>
  <button class="btn sec" id="btnSalir">Cerrar sesión</button>
</div>

<script>
const SUPA_URL='https://bdgzpjzlqidcexdkjhzy.supabase.co';
const SUPA_KEY='sb_publishable_I3FWEIOQf-_7ni_46PGSSQ_PLD3mQpM';
// storageKey propio: sin esto, la sesión del profesor reemplazaría la del alumno
// que juega en este mismo navegador, y el niño perdería su identidad.
const SB=window.supabase.createClient(SUPA_URL,SUPA_KEY,
  {auth:{storageKey:'kimun-profesor',persistSession:true,autoRefreshToken:true}});
const $=id=>document.getElementById(id);
let MODO='entrar', YO=null;

const ERRORES={
  no_autorizado:'Tu correo no está autorizado. Pídele acceso al administrador.',
  sin_sesion:'La sesión se cerró. Vuelve a entrar.',
  sin_correo:'No se pudo leer tu correo.',
  correo_invalido:'Ese correo no es válido.',
  nombre_vacio:'Escribe un nombre.',
  curso_invalido:'Ese curso no existe.',
  alumno_invalido:'Ese alumno no existe.'
};
function traducir(e){
  const m=(e&&e.message)||'';
  for(const k in ERRORES) if(m.includes(k)) return ERRORES[k];
  if(m.includes('Invalid login')) return 'Correo o contraseña incorrectos.';
  if(m.includes('already registered')) return 'Ese correo ya tiene cuenta. Usa "Entrar".';
  if(m.includes('at least')) return 'La contraseña debe tener al menos 6 caracteres.';
  return 'No se pudo completar la acción. Intenta de nuevo.';
}
function aviso(t,color){ $('authMsg').style.color=color||'var(--pink)'; $('authMsg').textContent=t; }
function esc(t){ return String(t==null?'':t)
  .replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;')
  .replace(/"/g,'&quot;').replace(/'/g,'&#39;'); }

$('btnCambiar').onclick=()=>{
  MODO = MODO==='entrar' ? 'crear' : 'entrar';
  $('authTitulo').textContent = MODO==='entrar' ? 'Ingresar' : 'Crear mi cuenta';
  $('btnEntrar').textContent  = MODO==='entrar' ? 'Entrar' : 'Crear cuenta';
  $('btnCambiar').textContent = MODO==='entrar' ? 'Crear mi cuenta' : '← Ya tengo cuenta';
  $('nombre').classList.toggle('hide', MODO==='entrar');
  aviso('');
};

$('btnEntrar').onclick=async ()=>{
  const correo=($('correo').value||'').trim(), clave=$('clave').value||'';
  if(!correo||!clave){ aviso('Escribe tu correo y tu contraseña.'); return; }
  $('btnEntrar').disabled=true; aviso('Comprobando…','var(--dim)');
  try{
    if(MODO==='crear'){
      const {error}=await SB.auth.signUp({email:correo,password:clave});
      if(error) throw error;
      const {error:e2}=await SB.rpc('kimun_prof_alta',{p_nombre:$('nombre').value||''});
      if(e2) throw e2;
    }else{
      const {error}=await SB.auth.signInWithPassword({email:correo,password:clave});
      if(error) throw error;
    }
    await cargarPanel();
  }catch(e){ aviso(traducir(e)); }
  finally{ $('btnEntrar').disabled=false; }
};

$('btnSalir').onclick=async ()=>{ await SB.auth.signOut(); location.reload(); };

async function cargarPanel(){
  const {data,error}=await SB.rpc('kimun_prof_yo');
  if(error) throw error;
  YO=Array.isArray(data)?data[0]:data;
  if(!YO){ throw new Error('no_autorizado'); }
  $('cardAuth').classList.add('hide');
  $('cardPanel').classList.remove('hide');
  $('panelTitulo').textContent = YO.es_admin ? 'Todos los cursos' : 'Mis cursos';
  await pintarLista();
}

async function pintarLista(){ $('lista').textContent='(la Tarea 6 lo completa)'; }

// Si ya había sesión abierta, entrar directo al panel
(async ()=>{
  const {data:{session}}=await SB.auth.getSession();
  if(session){ try{ await cargarPanel(); }catch(e){ aviso(traducir(e)); } }
})();
</script>
</body>
</html>
```

- [ ] **Paso 2: Verificar que un correo no autorizado queda sin permisos**

Levantar el servidor (`preview_start` con `{name:"kimun"}`) y abrir
`http://localhost:8765/profesor.html`. Pulsar "Crear mi cuenta" y registrarse con un correo
cualquiera que **no** esté autorizado, por ejemplo `prueba-no-autorizada@example.com`, con
una contraseña de al menos 6 caracteres.

Esperado: el mensaje "Tu correo no está autorizado. Pídele acceso al administrador." y el
panel **no** se abre. La cuenta queda creada en Supabase Auth pero sin fila en `profesores`,
que es exactamente el comportamiento del diseño.

- [ ] **Paso 3: Verificar que la sesión del juego no se ve afectada**

Con esa sesión de profesor abierta, ir a `http://localhost:8765/` y comprobar en la consola:

```js
(await SB.auth.getSession()).data.session?.user?.is_anonymous
```

Esperado: `true` — el juego conserva su sesión anónima. Este es el punto del `storageKey`.

- [ ] **Paso 4: Commit**

```bash
git add profesor.html
git commit -m "Profesores: pagina propia con ingreso y registro"
```

---

### Tarea 6: El panel de cursos

**Archivos:**
- Modificar: `profesor.html`

- [ ] **Paso 1: Reemplazar `pintarLista` por la versión real y agregar el formulario**

Sustituir la función provisional por:

```js
async function pintarLista(){
  const {data,error}=await SB.rpc('kimun_prof_listar');
  if(error) throw error;
  const porCurso={};
  (data||[]).forEach(f=>{
    porCurso[f.curso_codigo]=porCurso[f.curso_codigo]||{nombre:f.curso,alumnos:[]};
    if(f.codigo_acceso) porCurso[f.curso_codigo].alumnos.push(f);
  });
  const cursos=Object.entries(porCurso);
  $('lista').innerHTML = (cursos.length ? cursos.map(([cod,c])=>`
    <div style="margin-bottom:16px">
      <b style="color:var(--gold)">${esc(c.nombre)}</b>
      <code> ${esc(cod)}</code>
      ${c.alumnos.length ? c.alumnos.map(a=>`
        <div style="display:flex;align-items:center;gap:8px;padding:6px 0;border-bottom:1px solid #ffffff14">
          <span>${esc(a.avatar)}</span><b style="flex:1">${esc(a.alumno)}</b>
          <code>${esc(a.codigo_acceso)}</code>
          <span style="color:var(--dim)">${esc(a.xp)} XP</span>
        </div>`).join('')
       : '<p style="color:var(--dim);font-size:12px">Sin alumnos todavía.</p>'}
      <div style="margin-top:8px">
        <input class="in-alumno" data-curso="${esc(cod)}" placeholder="Nombre del alumno nuevo">
        <button class="btn sec add-alumno" data-curso="${esc(cod)}">+ Agregar alumno</button>
      </div>
    </div>`).join('')
   : '<p style="color:var(--dim);font-size:13px">Aún no tienes cursos.</p>')
   + `<div style="margin-top:10px;border-top:1px solid #ffffff22;padding-top:12px">
        <input id="cursoNombre" placeholder="Nombre del curso nuevo (8° A)">
        <button class="btn sec" id="btnCurso">+ Crear curso</button>
      </div>`;
  conectarAcciones();
}

function conectarAcciones(){
  $('btnCurso').onclick=async ()=>{
    const n=($('cursoNombre').value||'').trim();
    if(!n){ aviso('Escribe un nombre.'); return; }
    await accion(()=>SB.rpc('kimun_prof_curso_crear',{p_nombre:n}), 'Curso creado');
  };
  document.querySelectorAll('.add-alumno').forEach(b=>b.onclick=async ()=>{
    const campo=document.querySelector('.in-alumno[data-curso="'+b.dataset.curso+'"]');
    const n=(campo.value||'').trim();
    if(!n){ aviso('Escribe un nombre.'); return; }
    await accion(()=>SB.rpc('kimun_prof_alumno_agregar',
      {p_curso_codigo:b.dataset.curso,p_nombre:n,p_avatar:'🦊'}), 'Alumno agregado');
  });
}

// Ejecuta una acción, informa y refresca la lista. Centraliza el manejo de errores:
// supabase-js no lanza excepción cuando la función SQL falla, devuelve {data, error}.
async function accion(fn, exito){
  try{
    const {error}=await fn();
    if(error) throw error;
    await pintarLista();
    aviso(exito,'var(--green)');
  }catch(e){ aviso(traducir(e)); }
}
```

Y mover el mensaje al panel: agregar `<p class="msg" id="panelMsg"></p>` antes del botón de
cerrar sesión, y en `aviso()` escribir en `panelMsg` cuando el panel esté visible:

```js
function aviso(t,color){
  const el = $('cardPanel').classList.contains('hide') ? $('authMsg') : $('panelMsg');
  el.style.color=color||'var(--pink)'; el.textContent=t;
}
```

- [ ] **Paso 2: Verificar con la cuenta de administrador**

Roberto entra con su correo y su contraseña (Tarea 8 crea esa cuenta; si aún no existe,
posponer esta verificación hasta entonces). Crear un curso "Prueba profesor" y agregarle un
alumno.

Esperado: el curso aparece con su `CUR-XXXX`, el alumno con su `ALU-XXXXXXXX` y `0 XP`.

- [ ] **Paso 3: Commit**

```bash
git add profesor.html
git commit -m "Profesores: panel con cursos, alumnos y alta"
```

---

### Tarea 7: Acciones destructivas, XP y sección de administrador

**Archivos:**
- Modificar: `profesor.html`

- [ ] **Paso 1: Agregar los botones por alumno y por curso**

En `pintarLista`, dentro de la fila de cada alumno, después del XP:

```html
          <button class="mini xp" data-cod="${esc(a.codigo_acceso)}" data-xp="${esc(a.xp)}"
                  style="background:none;border:0;color:var(--gold);font-weight:900;cursor:pointer">✎</button>
          <button class="mini del" data-cod="${esc(a.codigo_acceso)}"
                  style="background:none;border:0;color:var(--pink);font-weight:900;cursor:pointer">✕</button>
```

Y junto al nombre del curso:

```html
      <button class="mini delcurso" data-cod="${esc(cod)}"
              style="background:none;border:0;color:var(--pink);font-weight:900;cursor:pointer">🗑️</button>
```

En `conectarAcciones`, agregar:

```js
  document.querySelectorAll('.xp').forEach(b=>b.onclick=async ()=>{
    const v=prompt('XP de este alumno:', b.dataset.xp);
    if(v===null) return;
    if(!/^\d+$/.test(v.trim())){ aviso('Escribe un número entero de 0 o más.'); return; }
    await accion(()=>SB.rpc('kimun_prof_xp_fijar',
      {p_codigo_acceso:b.dataset.cod,p_xp:parseInt(v,10)}), 'XP actualizado a '+parseInt(v,10));
  });
  document.querySelectorAll('.del').forEach(b=>b.onclick=async ()=>{
    if(!confirm('¿Eliminar a este alumno?\n\nPierde su lugar en el ranking y sus duelos. No se puede deshacer.')) return;
    await accion(()=>SB.rpc('kimun_prof_alumno_quitar',{p_codigo_acceso:b.dataset.cod}), 'Alumno eliminado');
  });
  document.querySelectorAll('.delcurso').forEach(b=>b.onclick=async ()=>{
    if(!confirm('¿Eliminar este curso?\n\nSe borran también todos sus alumnos y sus duelos. No se puede deshacer.')) return;
    await accion(()=>SB.rpc('kimun_prof_curso_quitar',{p_curso_codigo:b.dataset.cod}), 'Curso eliminado');
  });
```

- [ ] **Paso 2: Agregar la sección de administrador**

Al final de `pintarLista`, solo si `YO.es_admin`:

```js
  if(YO.es_admin){
    $('lista').insertAdjacentHTML('beforeend', `
      <div style="margin-top:16px;border-top:2px solid var(--violet);padding-top:12px">
        <h3 style="color:var(--violet);font-size:15px;margin:0 0 10px">Administración</h3>
        <input id="nuevoCorreo" type="email" placeholder="Correo del profesor nuevo">
        <button class="btn sec" id="btnAutorizar">+ Autorizar profesor</button>
        <div id="profes" style="margin:10px 0"></div>
        <button class="btn sec" id="btnLimpiar">🧹 Limpiar perfiles de prueba</button>
        <button class="btn sec" id="btnTablero">📊 Tablero de avance</button>
      </div>`);
    $('btnAutorizar').onclick=async ()=>{
      const c=($('nuevoCorreo').value||'').trim();
      if(!c){ aviso('Escribe un correo.'); return; }
      await accion(()=>SB.rpc('kimun_prof_autorizar',{p_correo:c}), 'Correo autorizado');
    };
    $('btnTablero').onclick=()=>{ window.location.href='dev/tablero.html'; };
    $('btnLimpiar').onclick=limpiarPruebas;
    const {data:profes}=await SB.rpc('kimun_prof_profesores');
    $('profes').innerHTML=(profes||[]).map(p=>
      `<div style="display:flex;gap:8px;padding:4px 0;font-size:13px">
         <span style="flex:1">${esc(p.correo)}</span>
         <span style="color:var(--dim)">${p.registrado?esc(p.nombre||'sin nombre'):'sin registrar'}</span>
         <span style="color:var(--cyan)">${p.cursos} curso${p.cursos===1?'':'s'}</span>
       </div>`).join('');
  }

```

`limpiarPruebas` va **a nivel superior del script**, no dentro de `pintarLista`:

```js
async function limpiarPruebas(){
  try{
    const {data:n,error}=await SB.rpc('kimun_prof_limpiar_pruebas',{p_ejecutar:false});
    if(error) throw error;
    if(!n){ aviso('No hay perfiles de prueba','var(--green)'); return; }
    if(!confirm('Se van a borrar '+n+' perfil'+(n===1?'':'es')+' de prueba.\n\n'+
      'Son los que se crean solos cuando alguien abre el juego y nunca escribió un código de alumno.\n\n'+
      'También se pierden sus duelos. No se borran los alumnos inscritos ni los rivales de práctica.\n\n¿Continuar?')) return;
    const {data:b,error:e2}=await SB.rpc('kimun_prof_limpiar_pruebas',{p_ejecutar:true});
    if(e2) throw e2;
    await pintarLista();
    aviso('Se borraron '+b+' perfil'+(b===1?'':'es')+' de prueba','var(--green)');
  }catch(e){ aviso(traducir(e)); }
}
```

- [ ] **Paso 3: Verificar el aislamiento entre profesores**

Esta es **la verificación más importante del plan**. Con la cuenta de administrador,
autorizar un correo de prueba (por ejemplo `profe-prueba@example.com`), crear con él una
cuenta en otra ventana privada del navegador, y desde esa segunda cuenta crear un curso
propio.

Comprobar, desde la consola de la sesión del profesor de prueba:

```js
await SB.rpc('kimun_prof_listar')            // solo su curso, ninguno de Roberto
await SB.rpc('kimun_prof_curso_quitar',{p_curso_codigo:'CUR-XXXX'})  // el curso de Roberto
```

Esperado: la primera devuelve únicamente sus cursos; la segunda falla con `no_autorizado`.
Repetir con `kimun_prof_alumno_quitar` y `kimun_prof_xp_fijar` usando un `ALU-` de Roberto:
ambas deben fallar igual.

- [ ] **Paso 4: Commit**

```bash
git add profesor.html
git commit -m "Profesores: borrados, correccion de XP y seccion de administrador"
```

---

## Fase 3 · Migración y retiro

### Tarea 8: Crear la cuenta de administrador y adoptar los cursos

**Archivos:** ninguno (operación sobre los datos)

- [ ] **Paso 1: Roberto crea su cuenta**

Abrir `profesor.html`, "Crear mi cuenta", con el correo sembrado en la Tarea 1 y una
contraseña de al menos 6 caracteres.

Esperado: entra al panel y el título dice "Todos los cursos".

- [ ] **Paso 2: Verificar que quedó como administrador**

```sql
select correo, es_admin from public.profesores;
```

Esperado: su correo con `es_admin = true`.

- [ ] **Paso 3: Asignarle los cursos existentes**

```sql
update public.cursos set profesor_id = (select id from public.profesores where es_admin limit 1)
where profesor_id is null;
```

Esperado: el curso "8vo csfs" queda con dueño. Verificar:

```sql
select c.nombre, p.correo from public.cursos c left join public.profesores p on p.id = c.profesor_id;
```

- [ ] **Paso 4: Verificar que los alumnos siguen intactos**

En el panel, comprobar que "8vo csfs" aparece con sus cuatro alumnos y sus códigos.

---

### Tarea 9: Retirar el Modo Admin del juego

**Archivos:**
- Modificar: `index.html`

> No ejecutar hasta que la Tarea 8 esté completa y verificada.

- [ ] **Paso 1: Quitar el botón de la pantalla de inicio**

Eliminar la línea `index.html:523`:

```html
      <button class="btn sec" id="btnAdmin">🔧 Modo Admin</button>
```

Y el párrafo que lo explica, que queda sin sentido:

```html
    <p style="text-align:center;color:var(--dim);font-weight:800;font-size:12px;margin-top:6px">
      El modo Admin es para el desarrollador y pide contraseña.
    </p>
```

- [ ] **Paso 2: Quitar la pantalla completa**

Eliminar el bloque `index.html:536-571`, desde el comentario
`<!-- ============ MODO ADMIN · CURSOS ============ -->` hasta el `</section>` que cierra
`scr-admin`, inclusive.

- [ ] **Paso 3: Quitar el JavaScript**

Eliminar las tres líneas de `index.html:1850-1852` (los manejadores `btnAdmin`,
`btnAdmTablero` y `btnAdmBack`) y **todo** el bloque
`/* ===== Modo Admin · cursos y alumnos ===== */`, desde `index.html:1904` hasta el cierre
del manejador de limpieza en la línea 2051 inclusive. El bloque siguiente
(`/* ===== Mapa de campaña (Nivel 2) ===== */`) debe quedar intacto.

- [ ] **Paso 4: Verificar que no quedaron referencias**

```bash
grep -n "btnAdmin\|scr-admin\|ADM_CLAVE\|admListar\|kimun_admin_" index.html
```

Esperado: sin resultados.

- [ ] **Paso 5: Verificar el juego en el navegador**

Abrir `http://localhost:8765/` y comprobar: la pantalla de inicio muestra **solo** JUGADOR y
DUELO 1v1, más "🎟️ Tengo un código" y Créditos. Entrar a JUGADOR, jugar una etapa, abrir la
tienda y el perfil. Sin errores en consola.

- [ ] **Paso 6: Commit**

```bash
git add index.html
git commit -m "El juego queda solo con Jugador y Duelo: se retira el Modo Admin"
```

---

### Tarea 10: Eliminar las funciones con clave global

**Archivos:**
- Modificar: `supabase/schema.sql`

> No ejecutar hasta que las tareas 8 y 9 estén completas.

- [ ] **Paso 1: Eliminar las definiciones**

Borrar del archivo las ocho funciones `kimun_admin_*` (`kimun_admin_ok`,
`kimun_admin_curso_crear`, `kimun_admin_curso_quitar`, `kimun_admin_alumno_agregar`,
`kimun_admin_listar`, `kimun_admin_alumno_quitar`, `kimun_admin_xp_fijar`,
`kimun_admin_limpiar_pruebas`), sus `drop function` previos y sus entradas en el `revoke` y
en el `grant`.

- [ ] **Paso 2: Agregar los drop explícitos**

Como el esquema se re-ejecuta sobre una base donde esas funciones ya existen, hay que
eliminarlas de verdad. Agregar cerca del final:

```sql
-- El modelo de clave global fue reemplazado por cuentas de profesor (kimun_prof_*).
-- Estos drop eliminan las funciones antiguas de las bases donde ya se aplicaron.
drop function if exists public.kimun_admin_curso_crear(text,text);
drop function if exists public.kimun_admin_curso_quitar(text,text);
drop function if exists public.kimun_admin_alumno_agregar(text,text,text,text);
drop function if exists public.kimun_admin_listar(text);
drop function if exists public.kimun_admin_alumno_quitar(text,text);
drop function if exists public.kimun_admin_xp_fijar(text,text,int);
drop function if exists public.kimun_admin_limpiar_pruebas(text,boolean);
drop function if exists public.kimun_admin_ok(text);
delete from public.config where clave = 'admin_clave';
```

- [ ] **Paso 3: Aplicar y verificar**

Pegar el esquema completo y ejecutar. Luego:

```sql
select count(*) from pg_proc where proname like 'kimun_admin_%';
select count(*) from public.config where clave='admin_clave';
```

Esperado: `0` en ambas.

- [ ] **Paso 4: Verificar que el panel del profesor sigue funcionando**

Recargar `profesor.html` y comprobar que los cursos y alumnos siguen visibles y que se puede
crear un curso.

- [ ] **Paso 5: Commit**

```bash
git add supabase/schema.sql
git commit -m "Se elimina la clave global de administracion"
```

---

### Tarea 11: Documentación

**Archivos:**
- Modificar: `CLAUDE.md`

- [ ] **Paso 1: Reescribir la sección "Cursos y ranking real"**

Reemplazar la parte de administración por el modelo nuevo: que los cursos se administran en
`profesor.html`; que las cuentas se crean con correo y contraseña y solo si el correo fue
autorizado por el administrador; que cada profesor ve únicamente sus cursos; que el juego ya
no tiene Modo Admin; y que el tablero de avance se abre desde el panel del administrador.

Documentar también que la clave global desapareció, para que nadie la busque, y que la
recuperación de contraseña requiere configurar SMTP en Supabase.

- [ ] **Paso 2: Actualizar la sección "Backend (Supabase)"**

Agregar las tablas `profesores` y `profesores_autorizados` y la familia `kimun_prof_*`;
quitar la mención a la clave de administración.

- [ ] **Paso 3: Commit**

```bash
git add CLAUDE.md
git commit -m "Documentar el rol de profesor"
```

---

## Notas para quien ejecute

- **El SQL lo aplica Roberto**, pegando `supabase/schema.sql` completo en el SQL Editor.
- **El orden de la Fase 3 no es negociable**: primero la cuenta de administrador (Tarea 8),
  después el retiro del panel del juego (Tarea 9) y por último el borrado de las funciones
  con clave (Tarea 10). Invertirlo deja el sistema sin administración posible.
- **La verificación de aislamiento (Tarea 7, Paso 3) es la que da sentido a la feature.** Si
  un profesor puede tocar el curso de otro, el trabajo no sirve, por más que la interfaz se
  vea bien.
- La recuperación de contraseña necesita SMTP configurado en Supabase. Sin eso, Roberto la
  restablece a mano desde el panel de Supabase.
