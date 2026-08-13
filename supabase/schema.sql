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

-- RLS: perfiles legible por todos (para la lista de rivales); duelos solo vía RPC.
alter table public.perfiles enable row level security;
alter table public.duelos enable row level security;
drop policy if exists "perfiles_select" on public.perfiles;
create policy "perfiles_select" on public.perfiles for select using (true);

-- Genera un código único tipo KIM-AB12
create or replace function public.kimun_gen_codigo() returns text
language plpgsql as $$
declare c text; begin
  loop c := 'KIM-'||upper(substr(md5(gen_random_uuid()::text),1,4));
    exit when not exists (select 1 from public.perfiles where codigo=c); end loop;
  return c; end $$;

-- Crea/actualiza mi perfil (devuelve el perfil con su código)
create or replace function public.kimun_perfil(p_nombre text, p_avatar text)
returns public.perfiles language plpgsql security definer set search_path=public as $$
declare r public.perfiles; begin
  insert into public.perfiles(id,nombre,avatar,codigo)
  values (auth.uid(),coalesce(p_nombre,'Jugador'),coalesce(p_avatar,'🦊'),public.kimun_gen_codigo())
  on conflict (id) do update set nombre=excluded.nombre, avatar=excluded.avatar
  returning * into r; return r; end $$;

-- Busca un perfil por código
create or replace function public.kimun_buscar(p_codigo text)
returns table(nombre text, avatar text)
language sql security definer set search_path=public as $$
  select nombre,avatar from public.perfiles where codigo=upper(p_codigo); $$;

-- Lista de jugadores para desafiar (bots primero)
create or replace function public.kimun_jugadores()
returns table(nombre text,avatar text,codigo text,es_bot boolean)
language sql security definer set search_path=public as $$
  select nombre,avatar,codigo,es_bot from public.perfiles
  where id <> auth.uid() order by es_bot desc, nombre; $$;

-- Crear un duelo. Si el rival es bot, responde al instante y devuelve el resultado;
-- si es un jugador real, queda pendiente (24h).
create or replace function public.kimun_crear_duelo(p_retado_codigo text,p_expedicion text,p_preguntas jsonb,p_aciertos int,p_tiempo int)
returns jsonb language plpgsql security definer set search_path=public as $$
declare v uuid; bot public.perfiles; b_ac int; b_t int; g text; total int; acc numeric; begin
  select * into bot from public.perfiles where codigo=upper(p_retado_codigo);
  if bot.id is null then raise exception 'codigo_invalido'; end if;
  total := coalesce(jsonb_array_length(p_preguntas),8);
  insert into public.duelos(retador_id,retado_codigo,expedicion,preguntas,retador_aciertos,retador_tiempo)
  values (auth.uid(),upper(p_retado_codigo),p_expedicion,p_preguntas,p_aciertos,p_tiempo) returning id into v;
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
  where d.retado_codigo=(select codigo from public.perfiles where id=auth.uid())
    and d.estado='pendiente' and d.expira>now(); $$;

-- Responder un duelo (guarda mi puntaje, marca completado, devuelve resultado + ganador)
create or replace function public.kimun_responder(p_id uuid,p_aciertos int,p_tiempo int)
returns table(retador_nombre text,retador_avatar text,retador_aciertos int,retador_tiempo int,mis_aciertos int,mi_tiempo int,ganador text)
language plpgsql security definer set search_path=public as $$
declare d public.duelos; mi text; g text; begin
  select codigo into mi from public.perfiles where id=auth.uid();
  select * into d from public.duelos where id=p_id and retado_codigo=mi and estado='pendiente' and expira>now() for update;
  if d.id is null then raise exception 'duelo_no_disponible'; end if;
  update public.duelos set retado_id=auth.uid(),retado_aciertos=p_aciertos,retado_tiempo=p_tiempo,estado='completado' where id=p_id;
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
    case when d.retador_id=auth.uid() then 'retador' else 'retado' end,
    case when d.retador_id=auth.uid() then rp.nombre else cp.nombre end,
    case when d.retador_id=auth.uid() then d.retador_aciertos else d.retado_aciertos end,
    case when d.retador_id=auth.uid() then d.retado_aciertos else d.retador_aciertos end,
    case when d.estado='pendiente' and d.expira<now() then 'expirado' else d.estado end,
    d.creado
  from public.duelos d
  left join public.perfiles cp on cp.id=d.retador_id
  left join public.perfiles rp on rp.codigo=d.retado_codigo
  where d.retador_id=auth.uid() or d.retado_codigo=(select codigo from public.perfiles where id=auth.uid()); $$;

-- Rivales dummy (bots) para poder jugar sin esperar a nadie
insert into public.perfiles (id,nombre,avatar,codigo,es_bot,nivel) values
 (gen_random_uuid(),'Vale','🐯','KIM-VALE',true,4),
 (gen_random_uuid(),'Nico','🐼','KIM-NICO',true,3),
 (gen_random_uuid(),'Fran','🦄','KIM-FRAN',true,5),
 (gen_random_uuid(),'Diego','🐸','KIM-DIEG',true,2)
on conflict (codigo) do nothing;

grant execute on function
  public.kimun_perfil(text,text), public.kimun_buscar(text), public.kimun_jugadores(),
  public.kimun_crear_duelo(text,text,jsonb,int,int), public.kimun_pendientes(),
  public.kimun_responder(uuid,int,int), public.kimun_historial()
  to anon, authenticated;
