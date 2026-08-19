-- ============================================================
-- KIMÜN · Esquema de Supabase (duelo online asíncrono)
-- Ejecutar en: Supabase → SQL Editor → New query → Run.
-- Además, activar el login anónimo en: Authentication → Sign In / Providers
--   → "Anonymous sign-ins" → Enable.
-- La publishable key va en index.html (es pública; la seguridad la dan las
-- políticas RLS y las funciones SECURITY DEFINER de abajo).
-- ============================================================

create extension if not exists pgcrypto;

-- Perfiles (uno por usuario; los bots tienen es_bot=true y un uuid propio).
create table if not exists public.perfiles (
  id uuid primary key,                 -- usuarios reales: auth.uid(); bots: gen_random_uuid()
  nombre text not null default 'Jugador',
  avatar text not null default '🦊',
  codigo text unique not null,         -- código de amigo (KIM-XXXX)
  es_bot boolean not null default false,
  nivel int not null default 3,        -- dificultad del bot (1-5)
  creado timestamptz not null default now()
);

-- Duelos
create table if not exists public.duelos (
  id uuid primary key default gen_random_uuid(),
  retador_id uuid not null references public.perfiles(id) on delete cascade,
  retado_codigo text not null,
  retado_id uuid references public.perfiles(id) on delete set null,
  expedicion text not null,
  preguntas jsonb not null,            -- set fijo de preguntas (mismo para ambos)
  retador_aciertos int not null,
  retador_tiempo int not null,
  retado_aciertos int,
  retado_tiempo int,
  estado text not null default 'pendiente',  -- pendiente | completado | expirado
  creado timestamptz not null default now(),
  expira timestamptz not null default (now() + interval '24 hours')
);
create index if not exists idx_duelos_codigo on public.duelos(retado_codigo);

-- Cursos (los crea el profesor desde profesor.html)
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
alter table public.perfiles add column if not exists dificil       int not null default 0;  -- asignaturas completadas en Modo Difícil

-- Vínculo dispositivo -> perfil (permite jugar en varios equipos)
create table if not exists public.vinculos (
  auth_uid  uuid primary key,             -- auth.uid() del dispositivo
  perfil_id uuid not null references public.perfiles(id) on delete cascade,
  creado    timestamptz not null default now()
);

-- Ajustes del servidor en pares clave/valor. Aquí vivía la clave global del Modo
-- Admin, que ya no existe: los permisos ahora son por cuenta de profesor. La tabla
-- se conserva por si más adelante hace falta guardar algún ajuste, y al final de
-- este archivo se borra la fila 'admin_clave' de las bases donde quedó.
create table if not exists public.config (
  clave text primary key,
  valor text not null
);

-- ------------------------------------------------------------
-- Profesores. Este es el único modelo de administración: cada profesor entra con
-- su correo y su contraseña (Supabase Auth) y solo obtiene permisos si tiene fila
-- en la tabla "profesores". La antigua clave global compartida fue eliminada.
-- ------------------------------------------------------------

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
create index if not exists idx_cursos_profesor on public.cursos(profesor_id);

-- ------------------------------------------------------------
-- Alta de la primera cuenta de administrador (procedimiento manual)
--
-- Aquí NO se siembra ningún correo en profesores_autorizados, a propósito.
-- Este repositorio es público: una fila con como_admin = true escrita en el
-- archivo publica cuál es el correo del administrador y lo deja como una cuenta
-- esperando a que alguien la reclame. Bastaría con registrarse en Supabase Auth
-- con ese correo y llamar a kimun_prof_alta para quedar como administrador de
-- toda la plataforma. Por eso el primer administrador se crea a mano, una sola
-- vez, y nunca por lista blanca.
--
-- Procedimiento (una sola vez, por Roberto):
--   1. Panel de Supabase → Authentication → Users → "Add user". El usuario
--      creado desde el panel nace con el correo ya confirmado, que es lo que
--      kimun_prof_alta exige para dejar entrar a alguien.
--   2. Ejecutar en el SQL Editor, reemplazando el correo si corresponde:
--
--        insert into public.profesores(id, correo, nombre, es_admin)
--        select id, email, 'Roberto', true from auth.users
--         where email = 'vulpochile.app@gmail.com'
--        on conflict (id) do update set es_admin = true;
--
-- A partir de ahí, los demás profesores se autorizan desde el panel del
-- administrador con kimun_prof_autorizar, que nunca otorga como_admin.
-- ------------------------------------------------------------

-- RLS: ninguna tabla se lee directo; todo pasa por las funciones SECURITY DEFINER.
alter table public.perfiles enable row level security;
alter table public.duelos   enable row level security;
alter table public.cursos   enable row level security;
alter table public.vinculos enable row level security;
alter table public.config   enable row level security;
-- Sin políticas, igual que el resto del esquema. Importa especialmente en
-- profesores_autorizados, porque revela qué correos pueden registrarse.
alter table public.profesores             enable row level security;
alter table public.profesores_autorizados enable row level security;
drop policy if exists "perfiles_select" on public.perfiles;

-- Genera un código único tipo KIM-AB12
create or replace function public.kimun_gen_codigo() returns text
language plpgsql as $$
declare c text; begin
  loop c := 'KIM-'||upper(substr(md5(gen_random_uuid()::text),1,4));
    exit when not exists (select 1 from public.perfiles where codigo=c); end loop;
  return c; end $$;

-- Código de curso (CUR-AB12): no es una credencial, basta con 4 caracteres
create or replace function public.kimun_gen_codigo_curso() returns text
language plpgsql as $$
declare c text; begin
  loop c := 'CUR-'||upper(substr(md5(gen_random_uuid()::text),1,4));
    exit when not exists (select 1 from public.cursos where codigo=c); end loop;
  return c; end $$;

-- Código de alumno (ALU-AB12CD34): sí es una credencial (quien lo tenga se
-- apodera del perfil), así que usa 8 caracteres para que no se pueda adivinar
-- probando combinaciones desde un script.
create or replace function public.kimun_gen_codigo_alumno() returns text
language plpgsql as $$
declare c text; begin
  loop c := 'ALU-'||upper(substr(md5(gen_random_uuid()::text),1,8));
    exit when not exists (select 1 from public.perfiles where codigo_acceso=c); end loop;
  return c; end $$;

-- Perfil de este dispositivo (null si todavía no tiene vínculo)
create or replace function public.kimun_yo() returns uuid
language sql security definer stable set search_path=public as $$
  select perfil_id from public.vinculos where auth_uid = auth.uid();
$$;

-- Migración: los jugadores que ya existen quedan vinculados a sí mismos.
-- Solo los perfiles de dispositivo (codigo_acceso is null): los alumnos que
-- inscribe el adulto tienen un id inventado que no corresponde a ningún
-- dispositivo, así que un vínculo para ellos sería una fila basura.
insert into public.vinculos(auth_uid, perfil_id)
select id, id from public.perfiles where es_bot = false and codigo_acceso is null
on conflict (auth_uid) do nothing;

-- Crea/actualiza mi perfil (devuelve el perfil con su código)
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

-- Busca un perfil por código
create or replace function public.kimun_buscar(p_codigo text)
returns table(nombre text, avatar text)
language sql security definer set search_path=public as $$
  select nombre,avatar from public.perfiles where codigo=upper(p_codigo); $$;

-- Lista de jugadores para desafiar (bots primero).
-- Solo aparecen los bots y los perfiles con un vínculo activo: un alumno que el
-- adulto inscribió pero que todavía no canjea su código no debe verse como
-- rival, porque no hay ningún dispositivo que pueda responder ese duelo.
create or replace function public.kimun_jugadores()
returns table(nombre text,avatar text,codigo text,es_bot boolean)
language sql security definer set search_path=public as $$
  select nombre,avatar,codigo,es_bot from public.perfiles p
  where p.id <> coalesce(public.kimun_yo(),'00000000-0000-0000-0000-000000000000'::uuid)
    and (p.es_bot or exists(select 1 from public.vinculos v where v.perfil_id = p.id))
  order by es_bot desc, nombre; $$;

-- Crear un duelo. Si el rival es bot, responde al instante y devuelve el resultado;
-- si es un jugador real, queda pendiente (24h).
create or replace function public.kimun_crear_duelo(p_retado_codigo text,p_expedicion text,p_preguntas jsonb,p_aciertos int,p_tiempo int)
returns jsonb language plpgsql security definer set search_path=public as $$
declare v uuid; mi uuid; bot public.perfiles; b_ac int; b_t int; g text; total int; acc numeric; begin
  -- Sin vínculo no hay perfil que pueda retar; se avisa con un error claro en
  -- vez de dejar que falle la restricción not null de retador_id.
  mi := public.kimun_yo();
  if mi is null then raise exception 'sin_perfil'; end if;
  select * into bot from public.perfiles where codigo=upper(p_retado_codigo);
  if bot.id is null then raise exception 'codigo_invalido'; end if;
  total := coalesce(jsonb_array_length(p_preguntas),8);
  insert into public.duelos(retador_id,retado_codigo,expedicion,preguntas,retador_aciertos,retador_tiempo)
  values (mi,upper(p_retado_codigo),p_expedicion,p_preguntas,p_aciertos,p_tiempo) returning id into v;
  if bot.es_bot then
    acc := 0.45 + bot.nivel*0.1;                         -- nivel 1..5 -> 0.55..0.95
    b_ac := least(total, greatest(0, round(total*acc)::int + (floor(random()*3)-1)::int));
    b_t := 20 + floor(random()*40)::int;
    update public.duelos set retado_id=bot.id,retado_aciertos=b_ac,retado_tiempo=b_t,estado='completado' where id=v;
    if p_aciertos>b_ac then g:='yo'; elsif p_aciertos<b_ac then g:='rival';
      elsif p_tiempo<b_t then g:='yo'; elsif p_tiempo>b_t then g:='rival'; else g:='empate'; end if;
    return jsonb_build_object('tipo','bot','rival_nombre',bot.nombre,'rival_avatar',bot.avatar,
      'rival_aciertos',b_ac,'mis_aciertos',p_aciertos,'total',total,'ganador',g);
  end if;
  return jsonb_build_object('tipo','async','id',v);
end $$;

-- Duelos pendientes para mí (SIN revelar el puntaje del retador)
create or replace function public.kimun_pendientes()
returns table(id uuid,retador_nombre text,retador_avatar text,expedicion text,preguntas jsonb,expira timestamptz)
language sql security definer set search_path=public as $$
  select d.id,p.nombre,p.avatar,d.expedicion,d.preguntas,d.expira
  from public.duelos d join public.perfiles p on p.id=d.retador_id
  where d.retado_codigo=(select codigo from public.perfiles where id=public.kimun_yo())
    and d.estado='pendiente' and d.expira>now(); $$;

-- Responder un duelo (guarda mi puntaje, marca completado, devuelve resultado + ganador)
create or replace function public.kimun_responder(p_id uuid,p_aciertos int,p_tiempo int)
returns table(retador_nombre text,retador_avatar text,retador_aciertos int,retador_tiempo int,mis_aciertos int,mi_tiempo int,ganador text)
language plpgsql security definer set search_path=public as $$
declare d public.duelos; mi text; g text; begin
  select codigo into mi from public.perfiles where id=public.kimun_yo();
  select * into d from public.duelos where id=p_id and retado_codigo=mi and estado='pendiente' and expira>now() for update;
  if d.id is null then raise exception 'duelo_no_disponible'; end if;
  update public.duelos set retado_id=public.kimun_yo(),retado_aciertos=p_aciertos,retado_tiempo=p_tiempo,estado='completado' where id=p_id;
  if p_aciertos>d.retador_aciertos then g:='yo';
  elsif p_aciertos<d.retador_aciertos then g:='rival';
  elsif p_tiempo<d.retador_tiempo then g:='yo';
  elsif p_tiempo>d.retador_tiempo then g:='rival';
  else g:='empate'; end if;
  return query select p2.nombre,p2.avatar,d.retador_aciertos,d.retador_tiempo,p_aciertos,p_tiempo,g
    from public.perfiles p2 where p2.id=d.retador_id; end $$;

-- Historial de mis duelos (para "mis duelos" / ranking futuro)
create or replace function public.kimun_historial()
returns table(id uuid,rol text,rival text,mi_aciertos int,rival_aciertos int,estado text,creado timestamptz)
language sql security definer set search_path=public as $$
  select d.id,
    case when d.retador_id=public.kimun_yo() then 'retador' else 'retado' end,
    case when d.retador_id=public.kimun_yo() then rp.nombre else cp.nombre end,
    case when d.retador_id=public.kimun_yo() then d.retador_aciertos else d.retado_aciertos end,
    case when d.retador_id=public.kimun_yo() then d.retado_aciertos else d.retador_aciertos end,
    case when d.estado='pendiente' and d.expira<now() then 'expirado' else d.estado end,
    d.creado
  from public.duelos d
  left join public.perfiles cp on cp.id=d.retador_id
  left join public.perfiles rp on rp.codigo=d.retado_codigo
  where d.retador_id=public.kimun_yo() or d.retado_codigo=(select codigo from public.perfiles where id=public.kimun_yo()); $$;

-- Sube mi XP (monótono: nunca baja)
create or replace function public.kimun_xp(p_xp int) returns int
language plpgsql security definer set search_path=public as $$
declare mi uuid; v int; begin
  mi := public.kimun_yo();
  if mi is null then return 0; end if;
  update public.perfiles set xp = greatest(xp, coalesce(p_xp,0)) where id=mi returning xp into v;
  return coalesce(v,0); end $$;

-- Sincroniza cuántas asignaturas completó el alumno en Modo Difícil. Solo sube (el estado
-- de Difícil es local del aparato, como el progreso de campañas), igual que kimun_xp.
create or replace function public.kimun_dificil(p_n int) returns int
language plpgsql security definer set search_path=public as $$
declare mi uuid; v int; begin
  mi := public.kimun_yo();
  if mi is null then return 0; end if;
  update public.perfiles set dificil = greatest(dificil, coalesce(p_n,0)) where id=mi returning dificil into v;
  return coalesce(v,0); end $$;

-- Ranking de mi curso (vacío si no tengo curso). Devuelve "dificil" para la marca 🔥.
drop function if exists public.kimun_ranking();
create or replace function public.kimun_ranking()
returns table(nombre text, avatar text, xp int, soy_yo boolean, curso text, dificil int)
language sql security definer set search_path=public as $$
  select p.nombre, p.avatar, p.xp, coalesce(p.id = public.kimun_yo(), false), c.nombre, p.dificil
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

-- ------------------------------------------------------------
-- Funciones del rol de profesor. No reciben ninguna clave: identifican al
-- profesor por su sesión de Supabase Auth (auth.uid()) y consultan la tabla
-- profesores para saber qué puede hacer.
-- ------------------------------------------------------------

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
  -- Defensa en profundidad: solo una cuenta de correo real y confirmada puede
  -- darse de alta. Cada teléfono que abre el juego tiene una sesión anónima, y
  -- desde ella se puede llamar a updateUser({email}); sin estos dos filtros esa
  -- sesión entraría por la misma puerta que un profesor.
  -- Por eso 'sin_correo' cubre ahora tres casos: la sesión no tiene correo,
  -- el correo todavía no está confirmado, o la sesión es anónima.
  select email into mi_correo from auth.users
   where id = auth.uid() and email_confirmed_at is not null
     and coalesce(is_anonymous, false) = false;
  if mi_correo is null then raise exception 'sin_correo'; end if;
  select * into aut from public.profesores_autorizados where lower(correo) = lower(mi_correo);
  if aut.correo is null then raise exception 'no_autorizado'; end if;
  -- Si la cuenta de Auth se borró y se recreó, el correo sigue tomado por un
  -- profesor cuyo id ya no existe. Se libera antes de insertar el nuevo, porque
  -- el "on conflict (id)" de abajo no atrapa ese choque (es contra la
  -- restricción única de correo) y el registro se volvería imposible, con un
  -- error de clave duplicada que en la página se lee como un mensaje genérico.
  -- El "not exists" es imprescindible: sin él, este delete alcanzaría a un
  -- profesor VIVO cuyo correo guardado quedó desalineado del real, lo borraría
  -- y la siguiente alta tomaría la rama del insert, volviendo a leer como_admin
  -- de la lista blanca. Es decir, sería una vía de escalada, no una limpieza.
  -- Consecuencia asumida: cursos.profesor_id tiene "on delete set null", así que
  -- los cursos del profesor borrado quedan huérfanos y pasan a verlos solo los
  -- administradores, hasta reasignarlos con kimun_prof_curso_asignar.
  delete from public.profesores p
   where lower(p.correo) = lower(mi_correo)
     and p.id <> auth.uid()
     and not exists (select 1 from auth.users u where u.id = p.id);
  -- Deliberado: el "do update" toca el nombre y el correo, nunca es_admin.
  -- Marcar como_admin en la lista blanca después del registro NO asciende a
  -- nadie; si lo hiciera, bastaría con volver a llamar a esta función para
  -- escalar permisos. Un ascenso se hace a mano, con un update sobre
  -- public.profesores. El correo sí se sincroniza para que no se desalinee del
  -- de Auth, que es justo la situación que el delete de arriba ya no limpia.
  insert into public.profesores(id, correo, nombre, es_admin)
  values (auth.uid(), lower(mi_correo), nullif(trim(p_nombre),''), aut.como_admin)
  on conflict (id) do update set
    nombre = coalesce(excluded.nombre, public.profesores.nombre),
    correo = excluded.correo
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

-- Mis cursos con sus alumnos. Un administrador ve todos, incluidos los huérfanos.
-- El drop previo es el guardia de idempotencia que ya usa kimun_ranking: al ser
-- "returns table", cambiar cualquier columna del returns haría fallar el
-- re-pegado del archivo con "cannot change return type of existing function".
drop function if exists public.kimun_prof_listar();
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
  -- Un código que no existe y un curso ajeno responden lo mismo a propósito: si
  -- se distinguieran, cualquier profesor podría recorrer los códigos CUR- y
  -- averiguar cuáles existen en la plataforma.
  if cid is null or not public.kimun_prof_es_mio(cid) then raise exception 'no_autorizado'; end if;
  delete from public.perfiles where curso_id = cid;
  get diagnostics n = row_count;
  delete from public.cursos where id = cid;
  return n; end $$;

create or replace function public.kimun_prof_alumno_agregar(p_curso_codigo text, p_nombre text, p_avatar text)
returns public.perfiles language plpgsql security definer set search_path=public as $$
declare cid uuid; r public.perfiles; begin
  if coalesce(trim(p_nombre),'') = '' then raise exception 'nombre_vacio'; end if;
  select id into cid from public.cursos where codigo = upper(trim(p_curso_codigo));
  -- Mismo criterio que en kimun_prof_curso_quitar: no se distingue "no existe"
  -- de "no es tuyo", para no filtrar qué códigos de curso están en uso.
  if cid is null or not public.kimun_prof_es_mio(cid) then raise exception 'no_autorizado'; end if;
  insert into public.perfiles(id,nombre,avatar,codigo,curso_id,codigo_acceso)
  values (gen_random_uuid(), trim(p_nombre), coalesce(p_avatar,'🦊'),
          public.kimun_gen_codigo(), cid, public.kimun_gen_codigo_alumno())
  returning * into r;
  return r; end $$;

-- Nota: un alumno sin curso (curso_id nulo) deja "cid" nulo y la función responde
-- alumno_invalido. Es lo correcto: por esta vía nadie toca un perfil sin curso.
create or replace function public.kimun_prof_alumno_quitar(p_codigo_acceso text)
returns int language plpgsql security definer set search_path=public as $$
declare cid uuid; n int; begin
  select curso_id into cid from public.perfiles where codigo_acceso = upper(trim(p_codigo_acceso));
  if cid is null then raise exception 'alumno_invalido'; end if;
  if not public.kimun_prof_es_mio(cid) then raise exception 'no_autorizado'; end if;
  delete from public.perfiles where codigo_acceso = upper(trim(p_codigo_acceso));
  get diagnostics n = row_count;
  -- Puede pasar si otra sesión borró al alumno entre la lectura y el delete. Sin
  -- este aviso, la página informaría un borrado que nunca ocurrió.
  if n = 0 then raise exception 'alumno_invalido'; end if;
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
  -- Igual que arriba: si el alumno desapareció entre la lectura y el update, "v"
  -- queda nulo y la página leería un éxito falso.
  if v is null then raise exception 'alumno_invalido'; end if;
  return v; end $$;

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
-- El join es "full outer" a propósito: si fuera desde profesores_autorizados,
-- un profesor ya registrado cuyo correo se quitó de la lista blanca dejaría de
-- aparecer, y el administrador no tendría cómo verlo ni revocarlo. Así se listan
-- los dos conjuntos: los correos autorizados y los profesores registrados.
-- Mismo guardia de idempotencia que kimun_prof_listar (es "returns table").
drop function if exists public.kimun_prof_profesores();
create or replace function public.kimun_prof_profesores()
returns table(correo text, nombre text, es_admin boolean, cursos int, registrado boolean)
language plpgsql security definer set search_path=public as $$
declare yo public.profesores; begin
  select * into yo from public.profesores where id = auth.uid();
  if yo.id is null or not yo.es_admin then raise exception 'no_autorizado'; end if;
  return query
    select coalesce(a.correo, p.correo), p.nombre, coalesce(p.es_admin,false),
           (select count(*)::int from public.cursos c where c.profesor_id = p.id),
           (p.id is not null)
    from public.profesores_autorizados a
    full outer join public.profesores p on lower(p.correo) = lower(a.correo)
    order by coalesce(a.creado, p.creado);
end $$;

-- Revoca a un profesor: borra su fila de profesores y saca su correo de la lista
-- blanca, para que no pueda volver a registrarse solo. Devuelve cuántos
-- profesores borró (0 si el correo estaba autorizado pero nunca se registró).
-- Sus cursos NO se borran: cursos.profesor_id tiene "on delete set null", así
-- que quedan huérfanos, visibles solo para los administradores, hasta que se
-- reasignen con kimun_prof_curso_asignar.
create or replace function public.kimun_prof_quitar(p_correo text)
returns int language plpgsql security definer set search_path=public as $$
declare yo public.profesores; n int; begin
  select * into yo from public.profesores where id = auth.uid();
  if yo.id is null or not yo.es_admin then raise exception 'no_autorizado'; end if;
  -- Un administrador no puede revocarse a sí mismo: si es el único, la
  -- plataforma quedaría sin nadie que pueda administrarla y solo se recuperaría
  -- con SQL a mano.
  if lower(trim(coalesce(p_correo,''))) = lower(yo.correo) then raise exception 'no_te_puedes_quitar'; end if;
  delete from public.profesores where lower(correo) = lower(trim(coalesce(p_correo,'')));
  get diagnostics n = row_count;
  delete from public.profesores_autorizados where lower(correo) = lower(trim(coalesce(p_correo,'')));
  return n; end $$;

-- Reasigna un curso a un profesor. Es la contraparte de kimun_prof_quitar: sin
-- esto, un curso huérfano no tendría forma de volver a tener dueño.
create or replace function public.kimun_prof_curso_asignar(p_curso_codigo text, p_correo text)
returns public.cursos language plpgsql security definer set search_path=public as $$
declare yo public.profesores; cid uuid; pid uuid; r public.cursos; begin
  select * into yo from public.profesores where id = auth.uid();
  if yo.id is null or not yo.es_admin then raise exception 'no_autorizado'; end if;
  select id into cid from public.cursos where codigo = upper(trim(coalesce(p_curso_codigo,'')));
  if cid is null then raise exception 'curso_invalido'; end if;
  select id into pid from public.profesores where lower(correo) = lower(trim(coalesce(p_correo,'')));
  if pid is null then raise exception 'profesor_invalido'; end if;
  update public.cursos set profesor_id = pid where id = cid returning * into r;
  return r; end $$;

-- Limpieza de perfiles de prueba. Cuenta con p_ejecutar=false y borra con true.
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

-- Rivales dummy (bots) para poder jugar sin esperar a nadie
insert into public.perfiles (id,nombre,avatar,codigo,es_bot,nivel) values
 (gen_random_uuid(),'Vale','🐯','KIM-VALE',true,4),
 (gen_random_uuid(),'Nico','🐼','KIM-NICO',true,3),
 (gen_random_uuid(),'Fran','🦄','KIM-FRAN',true,5),
 (gen_random_uuid(),'Diego','🐸','KIM-DIEG',true,2)
on conflict (codigo) do nothing;

-- PostgreSQL otorga EXECUTE a PUBLIC en toda función nueva, así que no basta con
-- omitirlas del grant de abajo: hay que quitarles el permiso de forma explícita.
-- Los generadores de código no tienen por qué llamarse desde afuera.
-- kimun_prof_es_mio tampoco se otorga: solo la llaman las demás funciones del
-- rol de profesor, que corren como su propietario y por eso siguen pudiendo usarla.
revoke execute on function
  public.kimun_gen_codigo(),
  public.kimun_gen_codigo_curso(), public.kimun_gen_codigo_alumno(),
  public.kimun_prof_es_mio(uuid)
  from public;

grant execute on function
  public.kimun_perfil(text,text), public.kimun_buscar(text), public.kimun_jugadores(),
  public.kimun_crear_duelo(text,text,jsonb,int,int), public.kimun_pendientes(),
  public.kimun_responder(uuid,int,int), public.kimun_historial(),
  public.kimun_yo(), public.kimun_xp(int), public.kimun_dificil(int), public.kimun_ranking(), public.kimun_canjear(text),
  public.kimun_prof_yo(), public.kimun_prof_alta(text),
  public.kimun_prof_listar(), public.kimun_prof_curso_crear(text),
  public.kimun_prof_curso_quitar(text), public.kimun_prof_alumno_agregar(text,text,text),
  public.kimun_prof_alumno_quitar(text), public.kimun_prof_xp_fijar(text,int),
  public.kimun_prof_autorizar(text), public.kimun_prof_profesores(),
  public.kimun_prof_quitar(text), public.kimun_prof_curso_asignar(text,text),
  public.kimun_prof_limpiar_pruebas(boolean)
  to anon, authenticated;

-- ------------------------------------------------------------
-- Retiro del modelo de clave global
--
-- El Modo Admin, que se abría con una sola contraseña compartida, fue
-- reemplazado por las cuentas de profesor (kimun_prof_*). Sus funciones ya no se
-- crean más arriba, pero eso no las quita de las bases donde alguna vez se
-- aplicó este archivo: hay que eliminarlas de verdad. Estos drop son idempotentes
-- (el "if exists" no falla si ya no están) y usan la firma exacta que tenían,
-- porque PostgreSQL identifica una función por sus tipos de parámetros.
-- ------------------------------------------------------------
drop function if exists public.kimun_admin_curso_crear(text,text);
drop function if exists public.kimun_admin_curso_quitar(text,text);
drop function if exists public.kimun_admin_alumno_agregar(text,text,text,text);
drop function if exists public.kimun_admin_listar(text);
drop function if exists public.kimun_admin_alumno_quitar(text,text);
drop function if exists public.kimun_admin_xp_fijar(text,text,int);
drop function if exists public.kimun_admin_limpiar_pruebas(text,boolean);
drop function if exists public.kimun_admin_ok(text);

-- Y la clave misma: ya no la valida nadie, así que no tiene por qué seguir ahí.
delete from public.config where clave = 'admin_clave';
