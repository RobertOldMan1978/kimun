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

-- Clave del Modo Admin, guardada en el servidor (no en el JavaScript).
-- Se guarda con hash (bcrypt), nunca en texto plano.
create table if not exists public.config (
  clave text primary key,
  valor text not null
);
-- Se siembra con un valor aleatorio que nadie conoce: así, si la clave real no se
-- fija, el Modo Admin queda cerrado en vez de abierto con una clave conocida.
-- Roberto fija la suya con:
--   update public.config set valor = crypt('<su clave>', gen_salt('bf', 10)) where clave='admin_clave';
insert into public.config(clave,valor)
values ('admin_clave', crypt(encode(gen_random_bytes(18),'hex'), gen_salt('bf', 10)))
on conflict (clave) do nothing;

-- Saneamiento: una versión anterior de este archivo guardaba la clave en texto
-- plano, y el "on conflict do nothing" de arriba la conservaría para siempre.
-- Con un valor así la validación nunca acierta y el Modo Admin queda cerrado sin
-- explicación. Esto lo reemplaza por una semilla aleatoria. Solo actúa sobre
-- valores que no son un hash bcrypt (los bcrypt empiezan con "$2"), así que
-- volver a ejecutar el esquema jamás pisa una clave real ya configurada.
update public.config set valor = crypt(encode(gen_random_bytes(18),'hex'), gen_salt('bf', 10))
 where clave = 'admin_clave' and valor not like '$2%';

-- RLS: ninguna tabla se lee directo; todo pasa por las funciones SECURITY DEFINER.
alter table public.perfiles enable row level security;
alter table public.duelos   enable row level security;
alter table public.cursos   enable row level security;
alter table public.vinculos enable row level security;
alter table public.config   enable row level security;
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

-- Ranking de mi curso (vacío si no tengo curso)
create or replace function public.kimun_ranking()
returns table(nombre text, avatar text, xp int, soy_yo boolean, curso text)
language sql security definer set search_path=public as $$
  select p.nombre, p.avatar, p.xp, coalesce(p.id = public.kimun_yo(), false), c.nombre
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
-- Administración de cursos (Modo Admin). La clave viaja en cada
-- llamada y se compara contra la tabla config; nunca vive en el
-- JavaScript del juego.
-- ------------------------------------------------------------

-- Valida la clave del Modo Admin contra el hash guardado en config.
-- El search_path incluye "extensions" a propósito: en Supabase pgcrypto vive en
-- ese esquema, no en public, así que sin él la función no encuentra crypt() y
-- falla con "function crypt(text, text) does not exist". No quitar.
-- (gen_random_uuid(), que usa el resto del archivo, sí es nativa de PostgreSQL y
-- por eso nunca necesitó este ajuste.)
create or replace function public.kimun_admin_ok(p_clave text) returns boolean
language sql security definer stable set search_path = public, extensions as $$
  select exists(select 1 from public.config where clave='admin_clave' and valor = crypt(p_clave, valor)); $$;

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

-- Elimina un alumno. Devuelve cuántas filas borró y avisa si el código no
-- existía, para que un código mal escrito no se vea como un borrado correcto.
-- El drop previo es necesario porque esta función antes devolvía void y
-- "create or replace" no permite cambiar el tipo de retorno.
drop function if exists public.kimun_admin_alumno_quitar(text,text);
create or replace function public.kimun_admin_alumno_quitar(p_clave text, p_codigo_acceso text)
returns int language plpgsql security definer set search_path=public as $$
declare n int; begin
  if not public.kimun_admin_ok(p_clave) then raise exception 'clave_invalida'; end if;
  delete from public.perfiles where codigo_acceso = upper(trim(p_codigo_acceso));
  get diagnostics n = row_count;
  if n = 0 then raise exception 'alumno_invalido'; end if;
  return n; end $$;

-- Corrige el XP de un alumno. kimun_xp solo sube (lo informa el propio juego),
-- así que esta es la única manera de bajar un puntaje inflado a mano.
create or replace function public.kimun_admin_xp_fijar(p_clave text, p_codigo_acceso text, p_xp int)
returns int language plpgsql security definer set search_path=public as $$
declare v int; begin
  if not public.kimun_admin_ok(p_clave) then raise exception 'clave_invalida'; end if;
  update public.perfiles set xp = greatest(0, coalesce(p_xp,0))
  where codigo_acceso = upper(trim(p_codigo_acceso)) returning xp into v;
  if v is null then raise exception 'alumno_invalido'; end if;
  return v; end $$;

-- Cuenta y elimina los perfiles de prueba: los que no son bots y no son alumnos
-- inscritos por el adulto. Son los perfiles que crea cada navegador o teléfono al
-- abrir el juego, y se acumulan con las pruebas. p_ejecutar=false solo cuenta.
-- Ojo: borrar un perfil arrastra sus duelos (on delete cascade) y deja sin progreso
-- en línea a cualquier dispositivo que no haya canjeado un código de alumno.
create or replace function public.kimun_admin_limpiar_pruebas(p_clave text, p_ejecutar boolean)
returns int language plpgsql security definer set search_path=public as $$
declare n int; begin
  if not public.kimun_admin_ok(p_clave) then raise exception 'clave_invalida'; end if;
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
-- kimun_admin_ok se usa solo dentro de las funciones de administración; si
-- quedara expuesta serviría para probar claves una tras otra sin dejar rastro.
-- Los generadores de código tampoco tienen por qué llamarse desde afuera.
revoke execute on function
  public.kimun_admin_ok(text), public.kimun_gen_codigo(),
  public.kimun_gen_codigo_curso(), public.kimun_gen_codigo_alumno()
  from public;

grant execute on function
  public.kimun_perfil(text,text), public.kimun_buscar(text), public.kimun_jugadores(),
  public.kimun_crear_duelo(text,text,jsonb,int,int), public.kimun_pendientes(),
  public.kimun_responder(uuid,int,int), public.kimun_historial(),
  public.kimun_yo(), public.kimun_xp(int), public.kimun_ranking(), public.kimun_canjear(text),
  public.kimun_admin_curso_crear(text,text), public.kimun_admin_alumno_agregar(text,text,text,text),
  public.kimun_admin_listar(text), public.kimun_admin_alumno_quitar(text,text),
  public.kimun_admin_xp_fijar(text,text,int),
  public.kimun_admin_limpiar_pruebas(text,boolean)
  to anon, authenticated;
