# Recompensas del Modo Difícil — Diseño

**Fecha:** 2026-08-17
**Objetivo:** dar una recompensa real que motive a rejugar en Modo Difícil (más estudio).
Hoy el Difícil es más difícil y rinde MENOS (10 s → menos bono de XP) y no da recompensa
propia: es un desincentivo.

## Decisiones (Roberto)
- Recompensas de **prestigio/estatus**, NO inflar el XP (para no distorsionar el ranking).
- Tres recompensas: insignia por asignatura, marca 🔥 en el ranking (social) y skin maestra.
- La marca del ranking es **visible para todos** (se sincroniza al servidor).

## Hito
Completar **todos los capítulos de una asignatura en Modo Difícil** (todas las etapas + los
jefes de capítulo pasados en Difícil). Aplica a **Historia, Ciencias y Lenguaje** (campañas
de quiz). **Matemáticas** (Reto de Cálculo) queda fuera: ya tiene su propia dificultad
(niveles, El Autómata, Modo Sin Fin) y no usa `MODO='dificil'`.

Detección (cliente): una asignatura está "completa en Difícil" si, para cada capítulo de su
campaña (`CAMPAÑAS[x].capitulos`, sin contar el desafío extra), `S.rutas[cap].progresoDificil`
tiene todos sus nodos en `est==='done'`.

## Recompensas
1. **Insignias exclusivas de Difícil** (3, tema 🔥): `dif-historia`, `dif-ciencias`,
   `dif-lenguaje` ("Historia · Difícil", etc.). Se agregan a `INSIGNIAS`; se ganan al
   completar esa asignatura en Difícil; se lucen en el perfil y junto al nombre.
2. **Marca 🔥 en el ranking del curso**: junto a cualquier alumno con `dificil > 0`.
3. **Skin "Kimün Maestro" 🔥**: en `SKINS`, `bloqueada:true`, `req:'Vence las 3 en Difícil'`;
   se desbloquea al completar las 3 asignaturas en Difícil. Emoji de marcador hasta que haya
   arte (`assets/skin-kimun-maestro.png`).

## Backend (Supabase) — migración que ejecuta Roberto
```sql
alter table public.perfiles add column if not exists dificil int not null default 0;

create or replace function public.kimun_dificil(p_n int)
returns int language plpgsql security definer set search_path=public as $$
declare v int; begin
  update public.perfiles set dificil = greatest(dificil, coalesce(p_n,0))
  where id = public.kimun_yo() returning dificil into v;
  return coalesce(v,0); end $$;

-- kimun_ranking pasa a devolver también "dificil" (recrear con el nuevo tipo de retorno).
grant execute on function public.kimun_dificil(int) to anon, authenticated;
```
`kimun_dificil` solo sube (como `kimun_xp`), porque el estado de Difícil es local del aparato.

## Cliente (`index.html`)
- Helper `asignaturasDificilCompletas()` → nº de asignaturas completas en Difícil (0-3) y
  cuáles.
- `revisarDificil()`: se llama al guardar progreso de una etapa/jefe en Difícil (en el
  resultado). Otorga la insignia de cada asignatura recién completada (+ toast), y si van las
  3, desbloquea la skin `kimun-maestro` (+ toast). Sincroniza el conteo con
  `SB.rpc('kimun_dificil', {p_n:conteo})` (best-effort, no bloquea).
- `renderRanking`: muestra `🔥` antes del nombre de cualquier fila con `dificil > 0`.
- Toasts: entradas nuevas en `LOGROS` para reutilizar la UI de aviso.

## Fuera de alcance
- No se toca el motor de quiz ni el flujo Normal.
- No hay "Jefe Final en Difícil" (el hito son los capítulos, no una variante del jefe).
- El arte de la skin maestra lo genera Roberto después (emoji mientras tanto).
