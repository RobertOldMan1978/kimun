# Panel del profesor con acordeón — Diseño

**Fecha:** 2026-08-20
**Archivo afectado:** `profesor.html` (solo el cliente; sin cambios de esquema ni de funciones del servidor).

## Problema

El panel del profesor (`pintarLista` en `profesor.html`) pinta **todos los cursos con todos
sus alumnos expandidos a la vez**. Con un profesor de un solo curso pasa desapercibido, pero
apenas tiene dos o más cursos la pantalla se vuelve una lista larguísima de alumnos mezclados,
sin forma de ver "qué cursos tengo" de un vistazo. Además, no se ve **quién** tiene la sesión
abierta.

Este diseño reorganiza la **arquitectura de información** del panel en un acordeón, sin tocar
el backend ni las vistas de avance. Es el primero de dos trabajos; la feature de "orientación
por asignatura + desafío de refuerzo" se diseña por separado.

## Objetivos

1. Mostrar arriba **quién es el profesor** con la sesión abierta.
2. Listar los cursos **plegados**, cada uno con un resumen útil sin abrirlo.
3. Dentro de cada curso, mostrar **primero el avance** y los **alumnos plegables**.

## No objetivos

- No se cambia ninguna función de Supabase ni el esquema.
- No se modifican las vistas de avance del curso (`verAvance`) ni del alumno
  (`verAvanceAlumno`), ni el bloque de participación que ya viven dentro de ellas.
- No se toca `index.html` (el juego).
- No se adelanta la feature de orientación/refuerzo (queda para su propio spec).

## Diseño

### 1. Encabezado del profesor

Arriba del panel (`cardPanel`), una línea de identidad:

> 👤 **&lt;nombre del profesor&gt;** — *Administrador* / *Profesor*

- El nombre sale de `YO.nombre` (de `soyProfesor()`); si viene vacío, se usa `YO.correo`.
- El rol es *Administrador* cuando `YO.es_admin`, si no *Profesor*.
- El título actual (`panelTitulo`: "Mis cursos" / "Todos los cursos") se conserva como
  **subtítulo** bajo esa línea. Las vistas de avance siguen ocultando `panelTitulo` como hoy;
  el encabezado de identidad también se oculta mientras se ve una tabla de avance, para no
  competir con la cabecera pegada de esa vista.

### 2. Cursos como acordeón (plegados por defecto)

Cada curso pasa a ser un `<details>` cerrado — el **mismo patrón** que ya usan las filas de
objetivos (`.oa-fila`) en la vista de avance, para mantener consistencia y accesibilidad.

**Cabecera visible sin abrir** (`<summary>`):

> **8vo Muestra** · `CUR-1939` · 30 alumnos · *Participación · 18/30 jugaron esta semana* · 🗑️

- Nombre del curso (color `--gold`), código, y conteo de alumnos inscritos.
- **Titular de participación**, cargado en segundo plano (ver 2.1).
- Botón 🗑️ eliminar curso (misma acción `.delcurso` de hoy). Va en el `<summary>` pero con
  `stopPropagation` en su click, para que pulsarlo **no** abra/cierre el acordeón.
- Marcador del `<details>` con el fix de Safari: `summary { list-style:none }` +
  `summary::-webkit-details-marker { display:none }`, más un chevron propio dibujado con CSS.

**Comportamiento de apertura:** varios cursos pueden estar abiertos a la vez (no exclusivo).
Se usa el toggle nativo del `<details>`; no se agrega JS para cerrar los demás.

#### 2.1 Carga del titular de participación

Por cada curso se llama `kimun_prof_participacion(curso_codigo)` y se calcula el titular
reutilizando `gruposParticipacion(filas)` (ya existe): "X/N jugaron esta semana", donde N es
el total de alumnos inscritos que devuelve la función y X el grupo "jugaron esta semana".

Reglas de la carga:

- Se dispara **después** de pintar la estructura de la lista, no bloquea el render.
- Para cada curso se **captura el nodo destino del titular ANTES del `await`** de su consulta.
  Esto evita el cruce ya conocido (Sesión 26): sin la captura, una respuesta tardía podría
  escribir el titular de un curso en la cabecera de otro. Cada consulta escribe solo en su
  nodo capturado.
- Si la consulta de un curso falla, ese titular queda en un texto neutro
  ("Participación no disponible"); el resto del panel no se ve afectado.
- Estado mientras carga: "Participación · …".

### 3. Contenido al abrir un curso

Al expandir el `<details>` del curso, el contenido aparece **en este orden**:

1. **Avance primero:** botón "📊 Ver avance del curso" (acción `.avance` actual → `verAvance`,
   que abre la tabla a pantalla completa como hoy).
2. **Alumnos plegables:** un segundo `<details>` anidado, con `<summary>` "👥 Alumnos (N)".
   Al abrirlo despliega:
   - La lista de alumnos con las filas actuales (avatar, nombre, código, XP y los botones
     ✎ fijar XP, 📊 ver avance, ✕ eliminar), sin cambios de contenido ni de estilo de fila.
   - El campo "agregar alumno" (input + botón), como hoy.
   - Si el curso no tiene alumnos, el `<summary>` dice "👥 Alumnos (0)" y al abrir muestra
     "Sin alumnos todavía." seguido del campo para agregar.

Debajo de todo, el campo "crear curso nuevo" se mantiene **fuera** de los acordeones, al final
de la lista (como hoy).

### 4. Administración (solo admin)

Sin cambios respecto a hoy: el bloque de administración (autorizar profesor, lista de
profesores, 🧹 limpiar perfiles de prueba, 📊 tablero) se inserta al final, después de la lista
de cursos.

## Notas de implementación

- **Todo el contenido se pinta dentro de los `<details>` ya cerrados** (incluida la lista de
  alumnos). El `<details>` solo oculta visualmente; el HTML está presente en el DOM desde el
  primer render. Por eso `conectarAcciones()` puede cablear todos los botones de una sola vez,
  como hoy, sin recableo perezoso al abrir. La única parte asíncrona es el titular de
  participación (2.1).
- No se agregan dependencias ni librerías; se usa `<details>`/`<summary>` nativos.
- El código de `pintarLista` crece en estructura HTML pero no en responsabilidades: sigue
  siendo "pintar la lista de cursos y cablear sus acciones".

## Riesgos y mitigaciones

- **N consultas de participación** (una por curso): para un profesor real son pocos cursos
  (1–6), y las consultas son livianas y asíncronas, así que no bloquean. No se agrega paginación
  ni caché en esta iteración (YAGNI).
- **Cruce de titulares entre cursos:** mitigado con la captura del nodo antes del `await`
  (2.1).
- **Marcador del `<details>` en Safari/iOS:** mitigado con `::-webkit-details-marker`.
- **El botón 🗑️ dentro del `<summary>`** podría alternar el acordeón al pulsarlo: mitigado con
  `stopPropagation` en su handler.

## Verificación

En el navegador, a 375 px (móvil), con la cuenta real o un banco simulado:

1. El encabezado muestra el nombre y rol del profesor.
2. Con dos o más cursos, la lista se ve plegada; cada cabecera muestra nombre, código,
   nº de alumnos y el titular de participación correcto.
3. Abrir un curso muestra primero "Ver avance del curso" y luego "Alumnos (N)"; abrir ese
   segundo acordeón despliega las filas y el campo de agregar.
4. Crear curso, agregar/eliminar alumno, fijar XP, ver avance del curso y del alumno,
   eliminar curso: todas las acciones existentes siguen funcionando.
5. Sin desborde horizontal (verificar `scrollWidth == viewport`).
6. La respuesta tardía de un curso lento no escribe su titular bajo otro curso (probar el
   cruce con dos cursos).
7. Como administrador, el bloque de administración aparece al final e intacto.
