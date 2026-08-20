# Diseño · Participación y fecha (quién juega y quién no)

Fecha: 2026-08-19
Estado: aprobado (diseño), pendiente de plan

## Problema

El mapa de dominio dice **qué** contenidos le cuestan al curso, pero no dice **quién
está jugando**. Un profesor no tiene forma de saber, sin abrir las 35 fichas a mano,
quién entró esta semana y quién no ha entrado nunca. Y esas dos preguntas no son de
adorno: un objetivo en 45% significa una cosa si lo jugaron 30 niños y otra muy distinta
si cinco nunca canjearon su código. La participación es el contexto que vuelve legible
el porcentaje.

El dato para responderlo casi existe. `dominio.actualizado` marca cuándo un alumno
terminó una etapa, pero **solo de campaña o jefe**: el Reto de Cálculo no toca esa tabla
(genera las operaciones al vuelo, sin objetivo asociado) y los duelos tampoco. Un niño
que juega Matemáticas todos los días aparecería como "nunca ha entrado". Para una vista
de participación ese sesgo es justo el dato al revés.

## Decisiones tomadas

- **La señal es "la última vez que abrió el juego", no "la última vez que avanzó en una
  campaña".** Se mide con una columna `visto` en `perfiles`, escrita dentro de `kimun_xp`,
  que el juego ya llama desde `guardar()` cada 15 segundos y en cualquier modo. Cubre
  campaña, Reto de Cálculo, duelo y tienda por igual.
- **Se presenta en grupos, no como lista con fecha por alumno.** Una lista de menores
  ordenada por días de inactividad se lee como lista de asistencia, y un niño sin teléfono
  ni internet en casa quedaría arriba de ella. Los grupos responden las dos preguntas
  ("quién esta semana", "quién nunca") sin producir ese artefacto.
- **Cuatro grupos, separando "nunca canjeó su código" de "entró y dejó de jugar".** No
  canjear casi nunca es desinterés: es un papel perdido, un código mal escrito o un
  teléfono que no tienen. La acción es volver a entregar el código, no insistirle al niño.
- **Vive plegada arriba del mapa de avance**, no en un botón aparte, para que la
  participación y los porcentajes se lean juntos.
- **La clasificación en grupos la hace el cliente.** Mover el umbral de "esta semana" no
  debe obligar a volver al SQL Editor.

## Modelo de datos

Columna nueva, idempotente:

```sql
alter table public.perfiles add column if not exists visto timestamptz;
```

Una sola línea se agrega al `update` que `kimun_xp` ya ejecuta:

```sql
update public.perfiles set xp = greatest(xp, coalesce(p_xp,0)), visto = now() where id = mi ...
```

No hay función nueva del lado del juego ni un envío adicional: `visto` se cuelga de la
sincronización de XP que ya existe, con su mismo límite de 15 segundos. Como `guardar()`
corre también al final de `cargar()` —es decir, al abrir el juego—, `visto` refleja la
entrada aunque el niño no llegue a terminar nada.

**Relleno inicial en la migración.** Sin esto, el día que se aplique el esquema el curso
entero aparecería como "nunca ha jugado" hasta que cada niño vuelva a abrir el juego, y el
profesor leería un curso muerto. La migración copia el primer contacto conocido:

```sql
update public.perfiles p
   set visto = d.ult
  from (select perfil_id, max(actualizado) ult from public.dominio group by perfil_id) d
 where d.perfil_id = p.id and p.visto is null;
```

Quien haya jugado campañas arranca con su fecha real. Los que solo jugaron Reto de Cálculo
partirán en blanco hasta su próxima entrada: es una limitación del arranque, no permanente.

## La consulta

Función nueva, con el mismo aislamiento que el resto del panel:

```sql
kimun_prof_participacion(p_curso_codigo text)
  -> table(alumno text, avatar text, visto timestamptz, vinculado boolean)
```

- Resuelve el curso por su código y exige `kimun_prof_es_mio`; responde `no_autorizado`
  ante un curso ajeno o inexistente (los dos casos se responden igual a propósito, para no
  filtrar qué códigos existen).
- Una fila por **alumno inscrito** (los de `perfiles` con ese `curso_id`), también los que
  no tienen actividad: "no aparece" no puede significar "no lo sé".
- `vinculado` = existe fila en `vinculos` para ese perfil, o sea si alguna vez canjeó su
  código desde un dispositivo.
- **Orden alfabético por nombre.** Por fecha sería un ranking de niños por inactividad.
- `SECURITY DEFINER`, en el `grant` junto a las demás `kimun_prof_*`, con su
  `drop function if exists` antes del `create` (por ser `returns table`).

## Los cuatro grupos (cliente)

| Grupo | Condición | Qué significa |
|---|---|---|
| Jugaron esta semana | `visto` en los últimos 7 días | Al día |
| Hace más de una semana | `visto` más antiguo que 7 días | Entró y dejó de entrar |
| Canjearon su código pero no han jugado | `vinculado` y `visto` nulo | Escribió el código y abandonó |
| Nunca canjearon su código | `vinculado` falso | Papel perdido, código mal escrito o sin teléfono |

Ventana **móvil de 7 días** (`now - visto < 7 días`), no "desde el lunes", para no depender
de la zona horaria del servidor. Nombres como fichas en línea, sin fecha individual, con el
mismo componente que la vista de apoyo del mapa. Un grupo vacío no se dibuja.

## Presentación

Bloque `<details>` plegado arriba del mapa de avance, con el titular en la línea siempre
visible:

> **Participación** · 24 de 35 jugaron esta semana

Se pide junto con el mapa, en paralelo (`Promise.all`), porque ese titular es justo el dato
que hay que ver sin abrir nada. Al desplegar aparecen los cuatro grupos.

Dos avisos en pantalla, breves:
- El mismo límite del XP y el mapa: **el dato lo reporta el teléfono del alumno**.
- **No jugar no es no querer:** puede ser que el niño no tenga teléfono o internet en casa.
  El grupo "nunca canjearon" apunta a volver a entregar el código, no a insistirle al niño.

## Manejo de errores

Si `kimun_prof_participacion` falla, el bloque muestra "no se pudo cargar la participación"
y **el mapa se pinta igual**. La participación nunca debe impedir ver el avance. Como va en
un `Promise.all`, la llamada del mapa y la de participación se resuelven por separado: el
fallo de una no arrastra a la otra.

## Límites conocidos

- **Falsificable:** `visto` lo escribe el teléfono, igual que el XP. No sirve para
  controlar asistencia; es una brújula para saber a quién reactivar.
- **Arranque parcial:** en la migración, quien solo jugó Reto de Cálculo parte sin fecha
  aunque haya jugado mucho. Se corrige solo en su próxima entrada.
- **No distingue modos:** `visto` no dice si el niño jugó campaña o solo abrió y cerró. Esa
  distinción se descartó a propósito (dos fechas por niño en un teléfono es ruido); el mapa
  de dominio ya cubre "avanzó en campaña".

## Fuera de alcance

Fecha individual por alumno, ordenar por inactividad, exportar, notificaciones push y
gráfico de tendencia en el tiempo.

## Verificación

- Esquema idempotente: re-pegar `schema.sql` no falla ni pierde datos; `visto` se agrega
  una sola vez y `kimun_prof_participacion` se recrea con su `drop` previo.
- `kimun_xp` sigue devolviendo el XP y ahora sella `visto`; un alumno que abre el juego
  pasa al grupo "esta semana".
- La migración deja con fecha a quien tenía filas en `dominio` y en nulo al resto.
- Aislamiento: un profesor ajeno recibe `no_autorizado` al pedir la participación de un
  curso que no es suyo (misma prueba que la vista de apoyo).
- Los cuatro grupos reparten a todos los inscritos sin perder ni duplicar a nadie (la suma
  de los cuatro es el total del curso).
- Con un solo curso y datos simulados a 375 px: el bloque no desborda, el titular cuenta
  bien y el mapa se pinta aunque la participación falle.
