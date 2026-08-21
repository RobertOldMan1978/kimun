# Desafío de refuerzo — Diseño

**Fecha:** 2026-08-20
**Archivos afectados:** `supabase/schema.sql` (backend nuevo), `profesor.html` (lanzar + seguimiento),
`index.html` (banner + juego del desafío). Es una feature de motor: toca el juego, no solo datos.

## Problema

El panel del profesor ya dice **qué** contenidos están flojos (mapa de dominio por objetivo) y
**quiénes** necesitan apoyo. Pero ahí se corta: el profesor ve el diagnóstico y no tiene ninguna
palanca dentro de la plataforma para actuar. Lo que pidió Roberto es cerrar el ciclo: que el panel
**oriente por asignatura** (qué repasar) y permita **preparar un desafío que obligue a rehacer una
cadena de preguntas** de esos objetivos, para reforzar, y luego **ver si sirvió**.

## Modelo (decisiones tomadas en el brainstorming)

- **Sugerido por el sistema, lanzado por el profesor** (un clic): el panel ya conoce los objetivos
  flojos; los propone y el profesor los lanza.
- **A todo el curso** (no dirigido por alumno).
- **Cadena de los objetivos flojos de UNA asignatura** (no un objetivo suelto, no mezcla de todas).
- **Banner en el inicio del juego**, insistente (persiste en cada inicio hasta completarlo) pero
  **no bloquea** el resto del juego.
- Recompensa: **XP + monedas + una insignia "Misión del profe"**.
- Seguimiento para el profesor: **quién lo completó + acierto del curso en el desafío**, medido
  **aparte** del mapa de dominio.
- **Uno activo por curso a la vez**.

## No objetivos (v1)

- No se dirige el desafío a alumnos específicos (siempre es el curso completo).
- No se permiten varios desafíos activos por curso.
- El desafío **no** reescribe el primer intento del mapa de dominio (ver "Medición aparte").
- No hay fecha límite automática; el profesor lo cierra a mano (o lo reemplaza al lanzar otro).
- No se guardan las preguntas exactas del desafío: se guardan los **OA**, y cada niño juega
  preguntas al azar del pool (es refuerzo, no un examen calificado).
- Matemáticas (Reto de Cálculo) **no** participa: no tiene OA asociados, igual que en el mapa.

## Arquitectura

### Backend (`supabase/schema.sql`)

**Tabla `desafios`** — el desafío lanzado; a lo más uno activo por curso.
- `id uuid primary key default gen_random_uuid()`
- `curso_id uuid not null references cursos(id) on delete cascade`
- `asignatura text not null` (p. ej. "Historia")
- `objetivos text[] not null` (lista de OA, p. ej. `{"HI08 OA 03","HI08 OA 04"}`)
- `activo boolean not null default true`
- `creado timestamptz not null default now()`
- Índice parcial único: **a lo más un desafío activo por curso**
  (`create unique index on desafios(curso_id) where activo`).

**Tabla `desafio_resultados`** — el resultado de cada alumno en un desafío.
- `desafio_id uuid not null references desafios(id) on delete cascade`
- `perfil_id uuid not null references perfiles(id) on delete cascade`
- `correctas int not null`
- `total int not null`
- `completado timestamptz not null default now()`
- `primary key (desafio_id, perfil_id)` (un resultado por alumno y desafío; el primero manda).

**Funciones del panel (identifican al profesor por sesión; validan `kimun_prof_es_mio(curso)`):**
- `kimun_prof_refuerzo_lanzar(p_curso_codigo text, p_asignatura text, p_objetivos text[])`
  → inserta el desafío; antes marca `activo=false` el desafío activo previo del curso (para
  respetar "uno por curso"). Devuelve el `id`.
- `kimun_prof_refuerzo_cerrar(p_curso_codigo text)` → marca `activo=false` el desafío activo del
  curso.
- `kimun_prof_refuerzo_estado(p_curso_codigo text)` → devuelve el desafío activo (o nada) con:
  asignatura, objetivos, `creado`, total de alumnos inscritos, cuántos lo completaron,
  acierto del curso en el desafío (`sum(correctas)/sum(total)`), y el promedio de **primer
  intento** de esos objetivos (leído de `dominio`, para la comparación "era 40% → va en 71%").

**Funciones del juego (identifican al alumno con `kimun_yo()`):**
- `kimun_refuerzo_activo()` → el desafío activo del curso del alumno **si no lo ha completado**
  (para decidir si mostrar el banner). Devuelve asignatura + objetivos, o nada.
- `kimun_refuerzo_completar(p_desafio_id uuid, p_correctas int, p_total int)` → inserta el
  resultado del alumno (`on conflict (desafio_id, perfil_id) do nothing`: el primer intento manda,
  no se puede "mejorar" reintentando). Valida que el desafío pertenezca al curso del alumno y esté
  activo.

**Seguridad:** RLS activo, sin políticas de lectura; todo pasa por funciones `SECURITY DEFINER`,
como el resto del proyecto. Las `kimun_prof_refuerzo_*` rechazan cursos ajenos con
`no_autorizado` (vía `kimun_prof_es_mio`). Las `kimun_refuerzo_*` del juego solo tocan el propio
perfil y su curso. Se otorga `execute` explícito a `anon, authenticated` solo a estas funciones.

### Panel del profesor (`profesor.html`)

En la **vista de avance del curso**, junto al mapa por objetivo, un bloque **"Refuerzo"** por
asignatura:

- **Sin desafío activo:** por cada asignatura con objetivos flojos, un resumen "Refuerzo sugerido ·
  &lt;asignatura&gt;" que lista los objetivos candidatos (ver "Selección de objetivos") y un botón
  **"Lanzar desafío de refuerzo de &lt;asignatura&gt;"**. Al pulsarlo (con confirmación), llama
  `kimun_prof_refuerzo_lanzar` y repinta el bloque como activo.
- **Con desafío activo:** un bloque de **seguimiento** con "Refuerzo de &lt;asignatura&gt; · activo",
  las dos métricas ("Lo completaron X/N", "Acierto del curso Y%"), la frase de comparación con el
  primer intento, y un botón **"Cerrar desafío"** (`kimun_prof_refuerzo_cerrar`).

Los datos del avance por objetivo ya se obtienen con `kimun_prof_dominio`; el bloque de refuerzo
reutiliza esa consulta para elegir los objetivos flojos, y `kimun_prof_refuerzo_estado` para el
seguimiento.

### Juego del alumno (`index.html`)

- **Banner en el inicio (`scr-rol`):** al cargar el juego y tras sincronizar la identidad, se llama
  `kimun_refuerzo_activo()`. Si hay un desafío activo no completado, se pinta un banner destacado
  arriba de los botones Jugador / Duelo: "📣 Desafío de tu profe · Refuerzo de &lt;asignatura&gt;" con
  botón "¡Jugar ahora!". Persiste en cada inicio hasta completarlo. Se integra con `pintarInicio()`.
- **Juego del desafío:** al tocarlo, se arma una **cadena de ~12 preguntas** a partir de los OA del
  desafío (reutiliza el armador de preguntas que ya usa el motor, `buildPreguntas(oa, n)`), con
  `n` por objetivo = `clamp(round(12 / nObjetivos), 2, 6)`. Se juega con el **mismo motor de quiz**
  que una etapa (timer, aciertos, retroalimentación al fallar). El desafío es una **cadena continua**
  de esas preguntas, no etapas separadas.
- **Al completar:** se llama `kimun_refuerzo_completar(desafio_id, correctas, total)`, se otorgan
  **XP + monedas** (como una etapa) y, la **primera vez** que el alumno completa cualquier refuerzo,
  la **insignia "Misión del profe"** (nueva entrada en `INSIGNIAS`, con su marca en `S.insignias`).
  El banner desaparece.
- **Modo QA (`?qa=1`):** se puede jugar el desafío para probar, pero **no registra** el resultado
  (coherente con que QA no registra dominio).

## Medición aparte (el punto delicado)

El mapa de dominio muestra el **primer intento**, que queda **congelado** a propósito (Sesión 24):
`resp_1`/`ok_1` no se vuelven a tocar. El desafío repite esos objetivos, así que **no puede** haber
un "segundo primer intento". Por eso el resultado del desafío se guarda en `desafio_resultados`,
una medición **independiente**, y **no** llama a `kimun_dominio`. El seguimiento del profesor
compara el acierto del refuerzo (de `desafio_resultados`) contra el primer intento original (de
`dominio`), que el panel ya conoce. El mapa de dominio no se altera.

## Selección de objetivos (sugerencia)

Desde `kimun_prof_dominio` (que devuelve, por OA, `resp_1`, `ok_1`, `alumnos_1`), el panel elige,
para la asignatura, los objetivos con:
- porcentaje de primer intento `ok_1/resp_1 < 0.70`, y
- evidencia suficiente `alumnos_1 >= 4` (mismo piso de credibilidad que la vista de apoyo),

ordenados de peor a mejor, tomando a lo más **5**. Si la asignatura no tiene ninguno bajo el
umbral, no se ofrece refuerzo para ella. El profesor lanza tal cual la sugerencia (v1 no permite
editar la lista a mano; se puede agregar después).

## Recompensa

- **XP + monedas** equivalentes a una etapa (mismos valores que el motor ya usa al terminar una
  etapa), sumados al completar.
- **Insignia "Misión del profe"** (`INSIGNIAS` gana una entrada nueva, con emoji de respaldo), que
  se otorga **la primera vez** que el alumno completa cualquier desafío de refuerzo. Es
  coleccionable y se puede lucir junto al nombre, como las demás.

## Verificación

Con banco simulado (no se puede iniciar sesión de profesor desde el entorno de pruebas) y con la
cuenta real de Roberto:

1. **Backend:** las funciones existen; `kimun_prof_refuerzo_lanzar` sobre un curso ajeno da
   `no_autorizado`; el índice único impide dos desafíos activos por curso (lanzar uno nuevo cierra
   el anterior).
2. **Panel:** con datos flojos, aparece el bloque "Refuerzo sugerido" con los objetivos correctos;
   lanzar crea el desafío y el bloque pasa a seguimiento; cerrar lo desactiva.
3. **Juego:** con un desafío activo, el banner aparece en el inicio; jugarlo arma ~12 preguntas de
   los OA; al completar se registra el resultado, se otorgan XP + monedas + insignia (primera vez) y
   el banner desaparece; en `?qa=1` no registra.
4. **Seguimiento:** tras completar con varios alumnos, `kimun_prof_refuerzo_estado` devuelve
   "X/N completaron" y el acierto del curso, y el panel muestra la comparación con el primer intento.
5. **Medición aparte:** el mapa de dominio (primer intento) **no** cambia después del desafío.
6. Sin desborde a 375 px; sin errores de consola.

## Riesgos y mitigaciones

- **Tocar `index.html` (el motor):** es la parte delicada. El desafío reutiliza el armador de
  preguntas y el motor de quiz existentes en vez de duplicarlos, y se enchufa en el inicio como un
  banner opcional; si el backend no responde, el banner simplemente no aparece y el juego sigue
  igual (best-effort, como el ranking).
- **Un niño sin curso** (perfil suelto) no tiene desafíos: `kimun_refuerzo_activo()` devuelve nada.
- **Preguntas distintas por alumno:** el "acierto del curso" agrega sobre preguntas al azar
  distintas por niño; es una señal de refuerzo, no una nota, y así se comunica (mismo límite que el
  resto del panel: el dato lo reporta el teléfono).
- **Carrera al lanzar/cerrar:** el índice único parcial (`where activo`) garantiza a nivel de base
  que no queden dos activos aunque dos pestañas lancen a la vez.
