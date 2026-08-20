# VULPO — Plataforma de juegos educativos

> **Nota de marca:** el proyecto se llamó **KIMÜN** hasta la Sesión 21. El nombre estaba
> tomado como marca de terceros, incluido el rubro de enseñanza, así que la plataforma pasó
> a llamarse **VULPO** y la mascota **Vulpi**. La bitácora conserva el nombre antiguo porque
> es el registro histórico, y los identificadores internos (claves del navegador, funciones
> de Supabase, archivos de arte) también lo conservan a propósito: cambiarlos borraría el
> progreso de quienes ya juegan. Ver
> `docs/superpowers/specs/2026-08-18-renombre-vulpo-design.md`.

## Descripción del proyecto

VULPO es una plataforma de juegos educativos para escolares chilenos de 15 años
hacia abajo, alineada al currículum del Ministerio de Educación de Chile. La meta
es que estudiar sea entretenido, desafiante y que genere comunidad mediante
competencia sana entre compañeros.

La arquitectura se piensa como un conjunto de "expediciones" independientes, de
modo que cada asignatura y nivel escolar sea un módulo propio reutilizando el
mismo motor de juego.

- **Piloto actual:** Historia de 8° básico, unidad "Los europeos llegan a América".
- **Primera prueba real:** los hijos del autor, desde el celular, vía GitHub Pages.

## Público objetivo

- Estudiantes chilenos de enseñanza básica (hasta ~15 años).
- Uso principal desde teléfono móvil (diseño mobile-first).
- Contenido en español latino neutro, alineado al currículum chileno.

## Estado actual

**Versión 0.99 (candidata a v1)** — completa y jugable de punta a punta; en vuelta
manual antes de coronar la v1 (ver Sesión 17). Publicado en GitHub Pages y en prueba
real. Un `index.html` mobile-first + contenido en JSON (`contenido/<asignatura>/`) +
backend Supabase para el duelo en línea. Historia de v0 al detalle en la Bitácora (abajo).

**Jugable hoy:**
- **Intro de bienvenida (video):** al abrir por primera vez se reproduce una intro
  de ~11 s (`assets/intro.mp4`: el zorro llega desde el espacio con los símbolos de las
  4 asignaturas + fanfarria "Fanfare for Space"; fundido de entrada/salida). Se ve **una
  vez por dispositivo**; `?intro=1` la fuerza. Si el navegador bloquea el autoplay con
  sonido, muestra "▶ Toca para comenzar".
- Inicio con selección **Jugador / Duelo 1v1 / Admin** y el rostro de la mascota
  **Vulpi** (zorro; `assets/kimun.png`, con expresiones por respuesta).
- **Pantalla principal en 2 niveles (Sesión 15):** un **módulo por asignatura**
  (Historia, Matemáticas, Ciencias, Lenguaje); al entrar se abre su campaña o una
  lista de sus mapas (`scr-mapas`). Cada mapa usa su portada propia por convención
  `assets/portada-<id>.png` con fallback a la de la asignatura. **Los 14 capítulos
  tienen arte propio** y se lucen como ilustración en la pantalla de campaña (el
  Jefe Final muestra al villano de la asignatura).
- **Campañas de asignatura completa (Historia, Ciencias y Lenguaje):** cada una se juega
  como **campaña con hilo conductor** — capítulos en orden que cubren todos los OA del año +
  un **Jefe Final multi-fase** (barra de vida, 3 corazones, tema carmesí) que se abre al
  100%, con recompensas (skin exclusiva, insignia, corona y bono +500🪙/+300XP):
  - **Historia:** 5 capítulos (22 OA) + Desafío Extra; villano "El Guardián del Tiempo";
    skin "Vulpi Historiador".
  - **Ciencias:** 4 capítulos (15 OA = las 4 unidades); villano "La Entropía";
    skin "Vulpi Científico".
  - **Lenguaje:** 4 capítulos (15 OA; la U1 "Lectura literaria" partida en 2 —Leer y
    comprender / Mundos literarios— + Textos y medios + Escritura); villano "El Borrón";
    skin "Vulpi Escritor"; insignia "Maestro de las Letras".
  Capa `CAMPAÑAS` data-driven; el motor de campañas es **genérico** (Desafío Extra
  opcional, jefe con título dinámico).
- **Matemáticas · "Reto de Cálculo" (Sesión 15):** al entrar a Matemáticas se abre un
  juego de **cálculo mental rápido** (procedural, alineado al eje Números de 8°), no el
  quiz de álgebra. **5 niveles × 3 etapas** + **Jefe Final "El Autómata"** (vida y
  corazones) + **Modo Sin Fin** con récord. El banco de álgebra queda de reserva.
  En el **Duelo**, Matemáticas ofrece los 5 niveles del Reto (operaciones generadas al
  vuelo), ver Sesión 16.
- Regla de cada capítulo/expedición: **4 etapas + 1 jefe (5 nodos)** (algunos capítulos
  con 3 etapas cuando su unidad tiene 3 OA). Cada asignatura tiene, además, un **banco de
  año completo** (todos sus OA oficiales); con las 4 campañas activas ya casi no queda
  contenido de reserva sin usar.
- Quiz: 6 preguntas al azar/etapa, timer 15 s, pasa con 66%, 3 estrellas. Al
  fallar revela la respuesta correcta + explicación y botón "Continuar". Vulpi
  comenta un dato al iniciar la ruta.
- **Modo Difícil** desbloqueable (8 preguntas, 10 s, 80%, tema oscuro/carmesí).
- Persistencia (localStorage), **tienda de skins** (precios escalonados 80–900;
  emojis baratos de entrada + skins ilustradas premium, incluidas **7 deportivas**:
  karate, fútbol, básquetbol, vóleibol, ciclismo, tenis, skate), animación de subida
  de nivel, logros, ranking (aún simulado).
- **Audio:** efectos procedurales (Web Audio, sin archivos) + **música de fondo**
  opcional por archivos (`assets/audio/`, con fallback si no están); control separado
  🎵 música / 🔊 efectos, persistido.
- **Duelo 1v1:** en el mismo teléfono y **en línea asíncrono (Supabase)** con
  código de amigo, lista de jugadores, bots de práctica y reto de 24h.

**Contenido (bancos de año completo, TODOS revisados):** Historia **663/663** ·
Matemáticas **603/603 (17 OA)** · Ciencias **534/534 (15 OA)** · Lenguaje
**514/514 (15 OA)**. ~2.314 preguntas, **100% marcadas como revisadas** (aprobación
humana de Roberto, ver Sesión 12). Los 3 bancos nuevos se llevaron a cobertura de
año completo desde el currículum oficial (ver Sesión 9) y se enriquecieron con ítems
de mayor orden por revisión pedagógica (ver Sesión 11); solo 4-5 OA de cada uno
están hoy en una expedición jugable, el resto es reserva. **Herramientas dev:** tablero con clave
(`dev/tablero.html`) y scripts (`consolidar-pool`, `aplicar-revisadas`,
`generar-pdf-preguntas` —por asignatura y con `--sin-revisar`—, `generar-tablero`).

## Decisiones de diseño

### Estética
- Paleta oscura violeta con acentos vibrantes (variables CSS en `:root`):
  `--gold #ffc93c`, `--cyan #4dd8ff`, `--green #3ee089`, `--pink #ff4d8d`,
  `--violet #8f6bff`.
- Tipografías: **Titan One** para títulos y **Nunito** para texto.
- Mobile-first, contenedor máximo de 480px, sin zoom del usuario.
- Fondo con estrellas animadas y degradados radiales.

### Mecánicas
- Progresión por etapas desbloqueables con jefe final.
- Refuerzo positivo: partículas, combos, XP, monedas, estrellas y logros.
- Retroalimentación educativa al fallar (no solo penalización).
- Competencia social: ranking de curso (por ahora simulado).

## Roadmap

Orden tentativo, sujeto a prioridad de "verlo funcionar y atractivo" primero:

1. ✅ **Duelo 1v1 en un mismo dispositivo** (HECHO) — por turnos, misma
   pregunta; 5 rondas, se pasa el teléfono, marcador y ganador.
2. ✅ **Tienda de skins con monedas** (HECHO) — 8 avatares premium comprables
   con monedas; equipado persistente.
3. ✅ **Sonidos** (HECHO) — efectos sintetizados con Web Audio (acierto, error,
   combo, subida de nivel, victoria/derrota) + botón de silencio. Sin archivos.
4. ✅ **Animación de subida de nivel** (HECHO) — overlay celebratorio a pantalla
   completa al cruzar 100 XP.
5. ✅ **Separar contenido del motor** (HECHO) — preguntas en
   `contenido/historia-8basico/preguntas.json`; el juego las lee con fetch.
6. ✅ **Persistencia de progreso** (HECHO) — guarda nombre, avatar, XP,
   monedas, estrellas, skins y logros en localStorage; continúa al reabrir.

### Más adelante (fuera del alcance inmediato)
- Login y multiusuario.
- Modelo de negocio.
- Múltiples asignaturas y niveles como expediciones independientes. **Motor
  data-driven listo:** el arreglo `EXPEDICIONES` (en `index.html`) define cada
  ruta (etapas → OA + contenido + portada) con progreso independiente por ruta;
  hay una **plantilla** en `contenido/_plantilla/` para clonar la siguiente.
  **Hecho:** Historia, Matemáticas, Ciencias y Lenguaje ya están generadas y
  activas, cada una con su **banco de año completo** (todos los OA oficiales). Con
  eso, armar nuevas expediciones de esas asignaturas es casi solo cablear
  `EXPEDICIONES` (ya hay preguntas para los OA que faltan). Falta la revisión
  pedagógica humana de los bancos nuevos.

## Reglas de trabajo

- Comunicación siempre en **español latino neutro** (ver instrucciones globales).
- No refactorizar el prototipo hasta que esté publicado tal cual.
- Flujo de trabajo entre oficina y casa sincronizando por **GitHub**.
- **Cierre de sesión:** al pedirlo, actualizar este `CLAUDE.md` con lo avanzado
  y lo pendiente, luego commit y push.

### Regla de commits (importante)

- **"orden 99" = hacer `git pull`** de la rama `main` para traer lo último de
  GitHub. Se usa al empezar a trabajar desde otro PC (típicamente al llegar a casa
  o a la oficina), para sincronizar antes de tocar nada.
- **Durante las sesiones NO se hace commit ni push** hasta que Roberto lo pida
  explícitamente con la orden **"orden 66"**. Claude debe esperar la orden.
- **La "orden 66" SIEMPRE deja todo actualizado antes del commit+push.** Como parte
  del procedimiento, antes de subir hay que: (1) agregar a la bitácora de abajo lo
  avanzado y lo pendiente de la sesión, y (2) revisar que `CLAUDE.md` y `README.md`
  reflejen el estado real (estado, roadmap, decisiones). Recién entonces commit + push.
- **Respaldo automático a las 18:00:** cualquier día en que haya cambios sin
  guardar, una Tarea Programada de Windows ejecuta `scripts/auto-commit.ps1`,
  que hace commit y push solo si detecta cambios. Así no se pierde trabajo
  entre oficina y casa.
- Para activar el respaldo en otro PC, ejecutar una vez
  `scripts/registrar-tarea.ps1`.
- El registro de ejecuciones queda en `scripts/auto-commit.log` (ignorado por git).

## Herramientas de desarrollo

### Parámetros de URL (ocultos)
- **`?qa=1` — Modo QA:** marca la respuesta correcta en todas las preguntas (expedición,
  jefe, duelo, Reto de Cálculo) y **desbloquea todo** (capítulos, jefes, niveles del
  Reto), para probar cualquier parte sin avanzar en orden. Muestra un aviso arriba a la
  izquierda. No afecta el juego normal (sin el parámetro). Implementado con la constante
  global `QA` y la clase CSS `.qa-ok`.
- **`?intro=1`:** fuerza que la intro de bienvenida se reproduzca aunque ya se haya visto
  (por defecto se ve una sola vez por dispositivo; flag `kimun_intro` en localStorage).

### Tablero de avance (`dev/tablero.html`)

Pantalla para el desarrollador (no para estudiantes) que muestra, por asignatura,
qué OA se están trabajando y el **% de avance por cobertura de preguntas**:

    avance_OA = min(100, preguntas_del_OA / meta_por_OA) · meta por defecto: 8

Se genera a partir de los datos con:

    python scripts/generar-tablero.py

Lee `contenido/<asignatura>/oa.json` y `preguntas.json`, y escribe
`dev/tablero.html` (estático y autocontenido, se abre con doble clic). Regenerar
cada vez que se agreguen o etiqueten preguntas. Está preparado para varias
asignaturas: basta con crear otra carpeta en `contenido/` con esos dos archivos.

**Cómo se llega al tablero (Sesión 22):** ya **no** se entra desde el juego. El
tablero se abre desde el panel del administrador en `profesor.html` (botón
"📊 Tablero de avance"), o escribiendo la dirección directamente. Sigue pidiendo su
propia contraseña, definida en la constante `CLAVE_ADMIN` de
`scripts/generar-tablero.py`; al cambiarla hay que volver a generar el tablero.

> Nota: esa contraseña es un **bloqueo suave** para que los niños no entren al
> tablero, NO seguridad real (es un sitio estático; quien sepa mirar el código
> puede saltársela). El acceso a los datos de cursos y alumnos, en cambio, sí es
> seguridad real: lo protege Supabase Auth desde `profesor.html`.

**En el tablero:** al pinchar un OA se despliegan sus preguntas (solo el
enunciado y la respuesta correcta).

**Para probar en local** (el navegador necesita servidor, no `file://` para el
JavaScript): `python -m http.server 8765` y abrir `http://localhost:8765/`.

### Cursos, profesores y ranking real (Sesiones 19 y 22)

El ranking del curso **ya no es simulado**: muestra a los alumnos reales del curso
del jugador, ordenados por XP, con datos de Supabase.

**Los cursos se administran en `profesor.html`**, una página aparte del juego. Se
entra con **correo y contraseña** (cuentas reales de Supabase Auth). Desde el panel
se crea un curso (genera un código `CUR-XXXX`), se inscriben alumnos por nombre
(cada uno recibe un código `ALU-XXXXXXXX`), se ve el XP de cada uno, se corrige y se
eliminan. No hace falta entrar a Supabase para nada de esto.

**Quién ve qué:**
- Un **profesor** ve y administra **solo sus cursos**. Los ajenos no le aparecen y
  las funciones del servidor rechazan cualquier intento de tocarlos.
- Un **administrador** ve **todos** los cursos (incluidos los que quedaron sin
  dueño) y además **autoriza los correos** de los profesores nuevos.

**Una cuenta no basta: hace falta estar autorizado.** Crear un usuario en Supabase
Auth no otorga ningún permiso. Los permisos viven en la tabla `profesores`: **sin
fila ahí, una cuenta no puede hacer nada**. Y solo se consigue esa fila si el
administrador autorizó antes ese correo (tabla `profesores_autorizados`). Por eso el
primer administrador se crea a mano, una sola vez, con el procedimiento comentado en
`supabase/schema.sql`; la lista blanca **no** se siembra en el repositorio, que es
público.

**El juego ya no tiene Modo Admin (Sesión 22).** La pantalla de inicio de
`index.html` ofrece solo **Jugador** y **Duelo 1v1**, más "🎟️ Tengo un código" y
Créditos. El tablero de avance se abre desde el panel del administrador.

> **La clave global de administración desapareció: que nadie la busque.** Antes el
> Modo Admin se abría con una sola contraseña compartida (guardada con hash en la
> tabla `config`, pero replicada en el repositorio a través del tablero) que daba
> acceso total a todos los cursos y alumnos. Ya no existe: ni la fila `admin_clave`,
> ni las funciones `kimun_admin_*`, ni el panel dentro del juego. El único camino es
> una cuenta de profesor autorizada.

**Mantenimiento (en el panel del profesor):**
- **`✎` en cada alumno:** fija su XP. Es la única forma de **bajar** un XP inflado,
  porque la sincronización normal (`kimun_xp`) solo sube.
- **🧹 Limpiar perfiles de prueba** (solo administrador): borra los perfiles que se
  crean solos al abrir el juego y que nunca canjearon un código de alumno. Cuenta
  primero y pide confirmación. **No borra** bots ni alumnos inscritos, pero sí
  arrastra los duelos de esos perfiles y **no tiene deshacer**. Conviene usarlo
  *después* de que los niños canjeen sus códigos: si se usa antes, un teléfono que
  ya venía jugando pierde su perfil en línea y sus duelos.

**Cómo entra un alumno:** Inicio → **"🎟️ Tengo un código"** → escribe su `ALU-`.
Queda vinculado a ese perfil en ese aparato, y puede repetirlo en otro para jugar
desde varios equipos. Si borra los datos del navegador, vuelve a canjear el mismo
código y recupera su lugar.

**Contraseñas de profesor:** las gestiona Supabase Auth. La **recuperación por
correo necesita SMTP configurado** en el proyecto de Supabase; sin eso, Roberto
restablece la contraseña a mano desde el panel de Supabase. Ojo también con el
servicio de correo integrado: permite **solo 2 correos por hora**, así que las altas
y confirmaciones seguidas se topan con `over_email_send_rate_limit` y hay que
esperar.

**Sesiones separadas:** `profesor.html` usa un cliente de Supabase con su propio
`storageKey` (`kimun-profesor`). Sin eso, que un adulto inicie sesión como profesor
en el teléfono de un niño le borraría al niño su identidad anónima del juego.

**Identidad del alumno:** la tabla `vinculos` separa la sesión anónima del
dispositivo del perfil del alumno. Por eso un mismo alumno puede jugar en el celular
y en el tablet sin duplicarse. Todas las funciones que antes asumían `auth.uid()`
como identidad del jugador resuelven el perfil con `kimun_yo()`.

**Límites conocidos:** el XP lo reporta el teléfono, así que puede falsearse; para
eso existe `kimun_prof_xp_fijar`, que permite al profesor corregirlo (el teléfono
adopta el valor del servidor cuando es menor). El progreso de campañas y las skins
siguen siendo del aparato, no del alumno: en un tablet compartido, dos hermanos
comparten avance aunque tengan XP distinto en el ranking.

Diseño y plan de los cursos y el ranking:
`docs/superpowers/specs/2026-08-17-cursos-ranking-real-design.md` y
`docs/superpowers/plans/2026-08-17-cursos-ranking-real.md`.
Diseño y plan del rol de profesor:
`docs/superpowers/specs/2026-08-18-rol-profesor-design.md` y
`docs/superpowers/plans/2026-08-18-rol-profesor.md`.

### Mapa de dominio por OA (avance del curso y del alumno)

Responde la pregunta que el XP no contesta: **qué entienden los alumnos**, objetivo
por objetivo, para decidir qué reforzar en clase. Vive en `profesor.html`.

**Cómo se usa:** en el panel, **"📊 Ver avance"** junto al nombre de cada curso abre
la tabla del curso completo, y el botón **📊** de cada alumno abre la suya. La tabla
va **de peor a mejor porcentaje**, así que lo que hay que reforzar queda arriba,
muestra el **texto del objetivo** (no su código: `HI08 OA 04` no le dice nada a
nadie; el panel lo carga desde `contenido/<asignatura>/oa.json`) y **cuántos alumnos
respaldan cada porcentaje**. Un objetivo que nadie jugó **no aparece**: mostrarlo como
0% se leería como "no lo entienden" cuando en realidad es "todavía no lo ven".
Matemáticas tampoco aparece, y el panel lo dice, para que su silencio no se lea como
"todo bien": el Reto de Cálculo no tiene objetivos asociados.

**Qué significa el porcentaje: el PRIMER intento** (Sesión 24), no el acumulado del
año. Es decir, cuántos acertaron **la primera vez que vieron ese contenido**. El
acumulado estaba sesgado porque su denominador dependía justo de lo que se quería
medir: `respondidas` crece con los reintentos, y se reintenta porque no se entendió,
así que **el alumno que menos sabe pesaba más en el promedio del curso**. Con el primer
intento la base es pareja (a lo más 6 respuestas por alumno y objetivo), que es lo que
vuelve legítimo ordenar de peor a mejor. Los **reintentos** (`respondidas - resp_1`)
se muestran aparte, como señal de cuánto costó: 62% con pocos reintentos ("les costó
pero lo sacaron") pide algo muy distinto que 62% con cuarenta ("se están estrellando").

**Los colores están calibrados al piso del azar:** con cuatro opciones por pregunta,
responder sin saber ya da 25%, así que un 50% no es "la mitad" sino un tercio de
dominio real. Cortan en **45%** (rojo/ámbar) y **70%** (ámbar/verde), y una nota en
pantalla explica el 25%.

**Cómo se recorre (Sesión 26):** un **encabezado pegado arriba** dice de qué curso o
alumno es la tabla y deja el botón de volver siempre a mano; el texto de cada objetivo se
**recorta a dos líneas** y se abre entero al desplegar la fila; hay **filtro por
asignatura** y un botón flotante para **volver arriba**. Antes cabían tres objetivos por
pantalla y las 60 filas sumaban 8.228 px de desplazamiento.

**Tres bloques en vez de atenuar:** "Para reforzar" (10 alumnos o más, bajo 70%), "Van
bien" (10 o más, 70% o más) y **"Todavía con pocos datos"** (menos de 10 alumnos,
plegado). Menos de diez alumnos son unas 60 respuestas: ±12 puntos de margen, el borde
de lo interpretable. Antes se atenuaban esas filas, pero atenuar y ordenar de peor a
mejor se peleaban entre sí —la posición decía "mira esto primero" y la opacidad "ignora
esto"—, de modo que la primera fila podía ser justo la menos confiable.

> **Comparar objetivos entre sí es el uso menos defendible** de esta tabla: los bancos
> de preguntas no están calibrados entre sí (los escribieron agentes distintos en tandas
> distintas), así que parte de la brecha entre un objetivo en 45% y otro en 87% es que
> un banco es más duro. Comparar un objetivo consigo mismo en el tiempo, o contra un
> umbral fijo, sí es defendible.

**Qué se mide:** solo las **campañas y los jefes finales**. El duelo queda fuera
porque es contra el reloj y se falla por apuro, y el Reto de Cálculo genera sus
operaciones al vuelo, sin objetivo asociado. El **Modo Difícil sí cuenta** (usa las
mismas preguntas del banco) y el **modo QA (`?qa=1`) no registra nada**, para que las
pruebas del desarrollador no ensucien el mapa.

**Qué se guarda:** contadores por alumno y objetivo en la tabla `dominio`, **no las
respuestas**: el acumulado (`respondidas`, `correctas`) y el primer contacto (`resp_1`,
`ok_1`), que se escriben solo al insertar la fila y **nunca se vuelven a tocar** — por
eso quedan congeladas en el primer intento. No queda registro de qué pregunta falló ni de
cuándo, así que no se puede reconstruir la sesión de un niño. El juego acumula en
memoria durante la etapa y envía un resumen al terminarla; si no hay señal, queda
pendiente en el teléfono y se reintenta después, sin interrumpir la partida.

**🔄 Reiniciar mediciones** (por curso, con confirmación) pone los contadores en
cero. Existe porque **acumulan todo el año**: un alumno que falló mucho en marzo y
hoy domina el tema arrastraría un porcentaje bajo. Sirve al empezar una unidad o un
semestre. No borra alumnos ni XP, y no toca los otros cursos. Con el porcentaje de
primer intento es, además, **la única forma de volver a medir** un objetivo: `resp_1`
queda congelada para siempre, así que sin reiniciar el número no se mueve aunque el
curso repase el tema.

> **No sirve para calificar**, y la pantalla lo dice con todas sus letras: el dato lo
> reporta el teléfono del alumno, igual que el XP, así que es falsificable por alguien
> que sepa. Es una brújula para decidir qué repasar, no una nota.

**Participación y fecha (Sesión 26):** arriba del mapa, un bloque plegado responde la otra
pregunta del profesor —quién está jugando— que el porcentaje por objetivo no contesta. El
titular se ve sin abrir nada (*"Participación · 24 de 35 jugaron esta semana"*) y al
desplegar reparte a los alumnos en **cuatro grupos**: jugaron esta semana, hace más de una
semana, **canjearon su código pero no han jugado**, y **nunca canjearon su código**. Esos
dos últimos se separan a propósito: no canjear casi nunca es desinterés (es un papel
perdido, un código mal escrito o un teléfono que no tienen), y la acción es volver a
entregar el código, no insistirle al niño. Nombres como fichas en orden alfabético, **sin
fecha individual ni orden por inactividad**: una lista de menores ordenada por días sin
entrar se leería como lista de asistencia, y quien no tiene teléfono ni internet en casa
quedaría arriba.

Lo que mide es **la última vez que el niño abrió el juego** (columna `visto` en `perfiles`,
sellada dentro de `kimun_xp`), así que cuenta **todos los modos** —campaña, Reto de Cálculo,
duelo, tienda—, no solo las campañas como el mapa. La ventana de "esta semana" son 7 días
móviles. La participación se pide en paralelo con el mapa y **su fallo no impide ver el
avance**; aparece también cuando el curso todavía no tiene datos de dominio, que es justo
cuando más interesa saber quién no entró. **Límite del arranque:** al aplicar el esquema,
`visto` se rellena desde `dominio.actualizado`, así que quien solo jugó Reto de Cálculo
parte sin fecha hasta su próxima entrada. **Caso de borde:** un hermano que canjea otro
código en el mismo teléfono deja al primero como "nunca canjeó" en la siguiente consulta,
por el modelo un-dispositivo-un-vínculo. Y el mismo límite del mapa: **no es asistencia**,
el dato lo reporta el teléfono.

Diseño y plan: `docs/superpowers/specs/2026-08-18-mapa-dominio-oa-design.md` y
`docs/superpowers/plans/2026-08-18-mapa-dominio-oa.md`. El cambio al primer intento:
`docs/superpowers/specs/2026-08-18-primer-intento-design.md` y
`docs/superpowers/plans/2026-08-18-primer-intento.md`.

### Consolidar el pool de preguntas (`scripts/consolidar-pool.py`)

Une los archivos verificados, elimina duplicados, **baraja las opciones** (evita
el sesgo de posición), asigna IDs por OA y escribe `preguntas.json`.

### Flujo de revisión pedagógica (marcar preguntas como "revisadas")

1. En el tablero (Admin), pincha un OA y marca la casilla de las preguntas que
   apruebes. Las marcas se guardan en el navegador.
2. Pulsa **"Exportar revisadas"** → descarga `revisadas.json`.
3. Aplica las marcas al banco: `python scripts/aplicar-revisadas.py` (busca el
   archivo en la raíz o en Descargas; también acepta la ruta como argumento).
4. Regenera el tablero: `python scripts/generar-tablero.py`. La barra rosada
   "Revisadas por ti" reflejará el avance real de revisión.

## Reglas de avance (acordadas)

### Del jugador (juego)
- **Estructura estándar de una expedición: 4 etapas + 1 jefe final (5 nodos).**
  Cada etapa mapea un OA; el jefe mezcla los 4 OA de la ruta. Regla para todas
  las asignaturas (Historia, Ciencias, y las próximas Matemáticas y Lenguaje).
- Cada etapa saca **6 preguntas al azar** del pool (jefe final: 8, mezcla de OA).
- **Pasa con ≥66%** de aciertos (4 de 6). Si no, repite la etapa con preguntas
  nuevas. Estrellas: 3★ = 100%, 2★ ≥ 80%, 1★ ≥ 66%.
- XP, monedas, combos y timer (15 s) se mantienen.
- Expedición piloto "Los europeos llegan a América": etapas OA04, OA05, OA06,
  OA07 + jefe final. El juego lee las preguntas de `preguntas.json` (fetch).

### Modo Difícil (desbloqueable)
- Se **desbloquea** al vencer al Jefe Final en Normal.
- Mismo mapa, pero: **8 preguntas** por etapa (jefe **10**), **10 s** por pregunta,
  se pasa con **≥80%**. Estrellas: 3★ = 100%, 2★ ≥ 90%, 1★ ≥ 80%.
- Progreso y estrellas **separados** del Normal (`S.progresoDificil`); se elige con
  el selector Normal/Difícil del mapa (variable global `MODO`).

### Del tablero (producción)
- Cobertura: `preguntas / 25` por OA.
- Revisión: `revisadas / total` (aprobadas por un humano).

## Backend (Supabase)

El **duelo 1v1 en línea**, el **ranking por curso** y las **cuentas de profesor** usan
Supabase (proyecto en São Paulo). Esquema y funciones en `supabase/schema.sql` (pegar
el archivo **completo** en el SQL Editor; es idempotente y se puede re-ejecutar sin
dañar los datos). Requiere activar el **login anónimo** en Authentication → Sign In /
Providers, y dejar activada la **confirmación de correo** para las cuentas de profesor.

- **Identidad sin contraseñas:** login anónimo → cada dispositivo es un usuario;
  perfil con `nombre`, `avatar` y **código de amigo** (`KIM-XXXX`).
- **Duelos:** se desafía desde una **lista de jugadores** (o por código). Contra
  **bots** (Vale/Nico/Fran/Diego) el resultado es **instantáneo**; contra
  **jugadores reales** es **asíncrono (24h)** y el puntaje del retador queda
  **oculto** hasta que el rival juega (funciones `SECURITY DEFINER`).
- **Seguridad:** RLS activo y **sin políticas de lectura**: ninguna tabla se consulta
  directo, todo pasa por funciones `SECURITY DEFINER`. Esto es importante desde la
  Sesión 19: `perfiles` guarda el `codigo_acceso` de cada alumno, que es su credencial,
  así que dejarla legible expondría los códigos de todos. La publishable key va en
  `index.html` (es pública por diseño; no es secreta).
- **Cursos y ranking (Sesión 19):** tablas `cursos` y `vinculos`; funciones
  `kimun_yo`, `kimun_xp`, `kimun_dificil`, `kimun_ranking` y `kimun_canjear`.
- **Profesores (Sesión 22):** tablas `profesores` (los permisos viven aquí: sin fila,
  una cuenta no puede nada), `profesores_autorizados` (lista blanca de correos) y la
  columna `cursos.profesor_id` (dueño del curso). La familia de funciones
  **`kimun_prof_*`** identifica al profesor por su sesión (`auth.uid()`) y **no recibe
  ninguna clave**; `kimun_prof_es_mio` decide si un curso le pertenece y por eso no se
  otorga a nadie desde afuera. Reemplazaron por completo a las viejas `kimun_admin_*`,
  que fueron eliminadas junto con la clave global. Ver "Cursos, profesores y ranking
  real" en Herramientas de desarrollo.
- **Participación (Sesión 26):** columna `perfiles.visto timestamptz`, sellada dentro de
  `kimun_xp` (la sincronización que el juego ya hace en todos los modos, no solo campañas),
  y la función `kimun_prof_participacion(curso)` que devuelve a cada alumno inscrito con su
  `visto` y si tiene fila en `vinculos`. Una migración al final del esquema rellena `visto`
  desde `max(dominio.actualizado)` la primera vez (idempotente con `where visto is null`).
- **Dominio por OA (Sesión 22):** tabla `dominio` (una fila por alumno y objetivo, con
  contadores; se borra en cascada junto con el alumno), `kimun_dominio` para registrar
  desde el juego y `kimun_prof_dominio`, `kimun_prof_dominio_alumno` y
  `kimun_prof_dominio_reiniciar` para el panel. Desde la Sesión 24 la tabla lleva además
  `resp_1` y `ok_1` (el primer contacto), que `kimun_dominio` escribe **solo en la rama
  `insert`**: el `on conflict do update` no las menciona a propósito, y ese detalle es
  toda la idea. Ver "Mapa de dominio por OA" en Herramientas de desarrollo.
- **Cuidado al editar el esquema:** `gen_random_uuid()` es nativa de PostgreSQL y no
  necesita nada especial, pero si alguna función vuelve a usar pgcrypto (`crypt`,
  `gen_salt`) necesita `set search_path = public, extensions`, porque en Supabase esa
  extensión no vive en `public`.
- **Pendiente:** notificaciones push.

## Trámites pendientes (fuera del código)

> **Recordar estos dos puntos CADA VEZ que se revisen los pendientes del proyecto.**
> No son tareas de programación, pero bloquean el lanzamiento a producción.

1. **Registrar la marca VULPO en INAPI.** El 2026-08-18 se verificó que estaba
   *disponible*, pero **no está registrada**. Mientras no se inscriba, cualquiera puede
   registrarla primero y el proyecto quedaría en el mismo problema que con KIMÜN. Clases
   relevantes: software y educación. Conviene hacerlo con un abogado de marcas.
   Trámite: https://www.inapi.cl/marcas

2. **Contratar el dominio propio `vulpo.cl`.** Hoy el juego vive en
   `robertoldman1978.github.io/vulpo/`. **GitHub Pages NO redirige las direcciones
   antiguas** —comprobado: la anterior devuelve 404—, así que cualquier cambio de nombre
   del repositorio rompe todos los enlaces que estén circulando. Un dominio propio elimina
   esa dependencia y da una dirección estable para colegios y apoderados.
   Trámite: https://www.nic.cl/

## Bitácora de sesiones

### Sesión 1 (2026-08-12)
- Renombrado `aventura-historia.html` → `index.html`.
- Creados `CLAUDE.md` y `README.md`.
- Inicializado git y primer commit; conexión con repositorio GitHub y push a `main`.
- Configuración de GitHub Pages para obtener la URL pública.
- **Pendiente:** avanzar el roadmap desde el punto 1 (duelo 1v1).

### Sesión 2 (2026-08-12)
- **Recuperación:** el repo local `C:\Proyectos\kimun` estaba vacío; se reclonó
  desde GitHub (nada se había perdido en el remoto).
- **Compañero Kimün (nuevo):** acompañante animado que reacciona en el quiz
  (neutral / feliz / sorprendido en combo / triste al fallar) y en la pantalla de
  resultado (oro / plata / bronce según estrellas, fiesta al vencer al jefe,
  desanimado si no pasa). Animación CSS sobre el sprite real → resuelve el pendiente
  de "animación de Kimün fiel a la marca".
- **Medallón dorado:** todos los sprites de Kimün se muestran dentro de un círculo
  con borde dorado (mismo sello de marca del inicio y la subida de nivel). El marco
  unifica el estilo mixto de las ilustraciones.
- **Estrella fugaz** ocasional cruzando el fondo del juego (cada 8–22 s).
- **Assets:** 18 sprites procesados (expresiones, vestuario de época, podio) + 4
  portadas de asignatura (Historia / Matemáticas / Ciencias / Lenguaje, con fondo).
  Originales crudos de respaldo en `assets/originales/`. Scripts nuevos:
  `scripts/procesar-expresiones.py` y `scripts/procesar-nuevas.py`.
  Nota: `demo-companero.html` es un banco de pruebas local, ignorado por git.
- **Pendientes acordados para próximas sesiones:**
  1. Vestir a Kimün según la época/unidad (piloto = traje de explorador; ya existe
     `assets/kimun-conquistador.png`).
  2. Modo Difícil desbloqueable (mismo mapa, menos tiempo, 8 preguntas/etapa,
     pasar con 80%).
  3. Aprovechar las portadas de asignatura como expediciones futuras.
- **Nota técnica:** el remoto cambió de mayúsculas; URL actualizada a
  `https://github.com/RobertOldMan1978/kimun.git`.

### Sesión 3 (2026-08-12)
Se completaron los tres pendientes que quedaron de la Sesión 2:
- **Vestuario de época:** Kimün conquistador (casco con pluma, capa, armadura) como
  ambientación de la Expedición Historia — en la pantalla de inicio de la expedición
  y en la cabecera del mapa. Usa `assets/kimun-conquistador.png`.
- **Modo Difícil desbloqueable:** se habilita al vencer al Jefe Final en Normal.
  Selector Normal/Difícil en el mapa; etapas de 8 preguntas (jefe 10), 10 s por
  pregunta, se pasa con **80%**. Progreso y estrellas propios del modo (3★=100%,
  2★≥90%, 1★≥80%), separados del Normal. Indicador 🔥 y logro de desbloqueo.
  Estado nuevo: `S.progresoDificil`, `S.dificilDesbloqueado`, variable global `MODO`.
- **Selección de expediciones (multi-asignatura):** nueva pantalla "Elige tu
  expedición" tras pulsar JUGADOR. Historia jugable; Matemáticas, Ciencias y
  Lenguaje con sello "🔒 Pronto" (usan `assets/portada-*.png`). Preparada para
  escalar con `const ASIGNATURAS`.

**Ideas para enriquecer gráficamente la asignatura (próxima sesión):**
- **Mapas:** rediseñar la ruta del mapa con estética de pergamino antiguo (papel
  envejecido, brújula, "X" del tesoro; ruta que se dibuja al avanzar); mapa del
  cruce del Atlántico con carabela.
- **Imágenes de época:** una ilustración de ambientación por etapa/OA (viajes,
  encuentro de dos mundos, conquista, mundo nuevo) como banner/portada del quiz;
  refuerzo visual en la retroalimentación al fallar.
- **Vestuarios/personajes:** más trajes de Kimün por etapa/rol; personajes
  históricos ilustrados como guías; avatares temáticos para la tienda.
- **Íconos y objetos:** reemplazar los emoji de etapa por íconos ilustrados;
  objetos coleccionables (brújula, astrolabio, carabela, cofre) como insignias.
- **A cuidar:** peso en móvil (optimizar cada imagen ~200 KB como los sprites);
  las imágenes las genera Roberto (IA) y Claude las procesa; sensibilidad del tema
  (pueblos originarios) y alineación al currículum chileno.
- Recomendación de partida: ilustración de ambientación por etapa, o el mapa
  tipo pergamino.

### Sesión 4 (2026-08-13)
- **Modo Difícil con look propio (oscuro/intenso):** clase `en-dificil` en el
  `<body>` (se sincroniza en `go()` y en el selector). CSS nuevo: fondo casi negro
  con tinte carmesí, viñeta, orbes color brasa con pulso rojo, estrellas rojizas,
  quiz/HUD/barra inferior tintados en rojo-fuego. En Normal no cambia nada.
- **Motor data-driven — PLANTILLA BASE (importante):** se sacó la ruta y el
  contenido a datos. Antes `const EXPEDICION` + `const ASIGNATURAS` estaban fijos
  en el código; ahora hay un solo arreglo **`EXPEDICIONES`** donde cada expedición
  trae sus `etapas` (OA→etapa), su `contenido` (ruta al `preguntas.json`), portada
  y `activa`. El motor lee la ruta activa desde datos (`activarExpedicion`,
  `cargarPool`). **Progreso independiente por ruta**: se guarda en `S.rutas[<id>]`
  (con migración automática de las partidas antiguas de Historia). Historia juega
  igual que antes, pero clonar la siguiente ruta/asignatura es solo cambiar datos.
- **Plantilla lista:** `contenido/_plantilla/` con `README.md` (receta de 3 pasos),
  `oa.json` y `preguntas.json` de ejemplo con el formato correcto.
- **Aprendizaje al fallar (nuevo):** al equivocarse ya no se avanza solo; se
  **revela la respuesta correcta** (opción en verde), se muestra un panel con
  "Respuesta correcta + 💡 explicación" (usa el campo `tip`) y un botón
  **"Continuar"** para leer sin apuro. Al acertar sigue rápido (1.1 s). Mejora a
  futuro: campo `explicacion` (2-3 frases) por pregunta para un texto más amplio.
- **Comentario de Kimün al iniciar la ruta (nuevo):** burbuja "🦊 Kimün te
  cuenta…" con una pregunta y su respuesta al azar del pool; se cierra con ✕ o
  sola a los ~10 s. Función `datoKimun()` disparada al entrar al mapa.
- **Pendientes:** generar el contenido (OA + pool) de la primera expedición nueva
  y activarla; ideas gráficas de la Sesión 3 (mapa pergamino, ambientación por etapa).

### Sesión 5 (2026-08-13)
- **Regla de estructura fijada:** toda expedición = **4 etapas (1 OA c/u) + 1 jefe
  final (5 nodos)**. Historia y Ciencias la cumplen; Matemáticas y Lenguaje seguirán.
- **Segunda expedición (Ciencias) — estrena la plantilla:** unidad "La célula"
  (`contenido/ciencias-8basico/`), con `oa.json` (los 15 OA de Ciencias 8°) y
  `preguntas.json` con **144 preguntas** de CN08 OA 01–04, generadas y verificadas
  por agentes (opciones barajadas, `revisada:false`). Expedición activa y jugable.
  **Confirmado:** agregarla fue solo datos + contenido, sin tocar el motor.
- **Encabezado del mapa data-driven:** antes el título/imagen del mapa estaban
  fijos en Historia; ahora reflejan la expedición activa (`mapaSub`, `mapaImg` en
  `renderMapa`). Campo opcional `mapaImg` por expedición (Historia mantiene su
  Kimün conquistador; el resto usa su portada).
- **Exportar preguntas a PDF:** `scripts/generar-pdf-preguntas.py` (usa fpdf2)
  genera un PDF por asignatura, agrupado por OA, con la respuesta correcta y la
  explicación, y casilla "Revisada" para revisión pedagógica en papel.
- **Pendientes:** revisión pedagógica de los bancos (Historia y Ciencias); un
  Kimün "científico" para el header de Ciencias; contenido de Matemáticas y Lenguaje.

### Sesión 6 (2026-08-13)
- **Duelo 1v1 EN LÍNEA (backend Supabase) — primer backend del proyecto:** se
  montó Supabase (proyecto en São Paulo) con login anónimo, perfiles con código
  de amigo y duelos asíncronos de 24h. Ver `supabase/schema.sql`.
  - **Asíncrono real:** A desafía, B tiene 24h; el puntaje de A queda **oculto**
    hasta que B juega (funciones `SECURITY DEFINER`, verificado). 8 preguntas, 15 s.
  - **Sin fricción de WhatsApp:** se desafía desde una **lista de jugadores**
    (o por código), no compartiendo enlaces.
  - **Bots de práctica:** rivales dummy (Vale/Nico/Fran/Diego) que **responden al
    instante** según su nivel, para poder jugar sin esperar a nadie.
  - El duelo "en este mismo teléfono" (pásame el celular) sigue disponible.
  - `index.html` carga `@supabase/supabase-js` (CDN) e incluye la publishable key
    (pública). Esto deja puesto el cimiento de **login/multiusuario** del roadmap.
- **Pendientes:** notificaciones push, ranking real (datos ya disponibles);
  revisión pedagógica de las preguntas; Matemáticas y Lenguaje.

### Sesión 7 (2026-08-13)
- **Revisión pedagógica de Historia aplicada:** a partir de un documento de
  revisión (9 observaciones AMARILLAS, 0 ROJAS — solo precisión/redacción, ninguna
  clave errónea) se corrigieron 9 preguntas del banco de Historia (indulgencias,
  absolutismo, cosmovisión, factores de la conquista, epidemias/inmunidad, 1492 y
  encomienda). Todo el banco de **Historia quedó marcado como revisado** (663/663);
  Ciencias sigue sin revisar.
- **Tablero:** ahora ignora las carpetas que empiezan con `_` (la `_plantilla`
  ya no aparece como asignatura).
- **Pendientes:** revisión pedagógica de Ciencias; Matemáticas y Lenguaje;
  notificaciones push y ranking real del duelo.

### Sesión 8 (2026-08-13)
- **Dos expediciones nuevas (clonando la plantilla, solo datos):**
  - **Matemáticas · "Álgebra y ecuaciones"** (`contenido/matematicas-8basico/`):
    OA MA08 06-09 (lenguaje algebraico, expresiones, ecuaciones, inecuaciones).
  - **Lenguaje · "Tipos de texto y medios"** (`contenido/lenguaje-8basico/`):
    OA LE08 01-04 (texto narrativo, textos informativos, medios/publicidad,
    argumentación).
  - Generadas por agentes en paralelo (120 preguntas c/u), activadas en
    `EXPEDICIONES` (`index.html`). El motor NO se tocó. Ya hay **4 expediciones
    jugables** (20 nodos). Probadas en el navegador (pool + mapa OK).
- **Revisión pedagógica externa aplicada a los 3 bancos sin revisar** (Matemáticas,
  Ciencias y Lenguaje). Los documentos (`Recomendaciones_*_8Basico.docx`) NO
  reportaron claves erróneas: pidieron mejoras de composición. Criterio elegido:
  mantener el banco, corregir lo puntual y **agregar ítems de mayor orden**.
  - **Matemáticas → 168:** corregida la representación en recta numérica
    (círculo abierto/cerrado + intervalo); +48 ítems (razonamiento, análisis de
    errores, aplicación con contexto, representación).
  - **Ciencias → 184:** suavizadas formulaciones demasiado absolutas y reducida la
    repetición; +40 ítems (aplicación experimental, análisis, comparación).
  - **Lenguaje → 168:** eliminadas ambigüedades y varias preguntas de memoria
    convertidas a aplicación; +48 ítems (comprensión con fragmento breve,
    inferencia, análisis de publicidad).
  - Los tres siguen **sin revisión humana** (`revisada:false`); la aprobación se
    hace luego con el tablero → `aplicar-revisadas.py`.
- **`scripts/generar-pdf-preguntas.py` generalizado:** funciona por asignatura
  (`python scripts/generar-pdf-preguntas.py <carpeta>`) y con `--sin-revisar`
  exporta un PDF por asignatura con solo lo pendiente. Los PDF quedan en `dev/`
  (ignorados por git; son regenerables).
- **Pendientes:** revisión pedagógica humana de Matemáticas, Ciencias y Lenguaje;
  un Kimün "científico" para el header de Ciencias; probar el duelo en 2 celulares;
  notificaciones push y ranking real; limpiar perfiles de prueba en Supabase.

### Sesión 9 (2026-08-13)
- **Bancos de AÑO COMPLETO para las 3 asignaturas nuevas** (todos los OA oficiales),
  alimentándose del sitio oficial (`curriculumnacional.cl`). Se hizo por fases, en
  secuencia, con agentes en paralelo por eje y consolidación validada:
  - **Ciencias 184 → 459** (15/15 OA): se agregaron OA05-15 (cuerpo humano y salud,
    electricidad y calor, materia y átomo), ~25/OA. Sin conflicto de códigos.
  - **Matemáticas 168 → 518** (17/17 OA): se agregaron Números (OA01-05), Funciones
    (OA07 lineal, OA10 afín), Geometría (OA11-14) y Prob./Estadística (OA15-17).
  - **Lenguaje 168 → 443** (15/15 OA): se agregaron poesía, teatro, epopeya, comedia,
    interpretación, estrategias de comprensión y escritura (OA01,02,04-08,12-15).
- **Re-mapeo a OA oficiales (fidelidad).** Al armar Matemáticas y Lenguaje (Sesión 8)
  se habían usado códigos internos que chocaban con la numeración oficial. Se corrigió:
  - **Matemáticas:** "lenguaje algebraico" + "expresiones" se fundieron en el oficial
    **OA06 (operaciones algebraicas)** y se liberó el **OA07 para función lineal**. La
    expedición pasó a "Álgebra y **funciones**" (OA06-09).
  - **Lenguaje:** los 4 temas se re-etiquetaron a sus códigos reales —narrativo→**OA03**,
    informativos→**OA11**, medios→**OA10**, argumentar→**OA09**— y se recableó la
    expedición. IDs renumerados de forma consistente.
- Cada `oa.json` ahora lista **todos los OA oficiales** con sus textos y `nota_fidelidad`
  (validar redacción literal contra el PDF del MINEDUC).
- **Calidad:** corrección verificada por muestra; se detectó y corrigió un problema
  sistemático de tildes en un lote de Matemáticas (~98 correcciones); Ciencias y
  Lenguaje salieron limpios; cero modismos. `generar-pdf-preguntas.py` ahora sanea
  glifos ausentes en la fuente del PDF (subíndices químicos, ∛) sin tocar el JSON.
- Todo sigue **`revisada:false`**. El motor NO se tocó (solo datos + `EXPEDICIONES`).
  Las 4 expediciones jugables se verificaron en el navegador (5 nodos con pool listo).
- **Documentada la "orden 99" (= `git pull`)** en la sección "Regla de commits",
  para que cualquier sesión (p. ej. el PC de casa) la entienda sin explicarla.
- **Pendientes:** revisión pedagógica humana de los bancos; armar nuevas expediciones
  aprovechando los OA de reserva; Kimün "científico"; duelo en 2 celulares; push y
  ranking real; limpiar perfiles de prueba en Supabase.

### Sesión 10 (2026-08-13)
- **Sincronización (orden 99):** `git pull` desde otro PC trajo el trabajo de las
  Sesiones 4-9 (motor data-driven, 3 asignaturas nuevas de año completo, Supabase,
  tablero, PDF). Fast-forward sin conflictos.
- **PDF de revisión generados:** los tres bancos sin revisar —Matemáticas (518),
  Ciencias (459) y Lenguaje (443)— con `generar-pdf-preguntas.py --sin-revisar`,
  para la revisión pedagógica en papel. Quedan en `dev/` (ignorados por git).
- **Pendientes:** sin cambios respecto a la Sesión 9 (revisión pedagógica humana de
  los 3 bancos nuevos; nuevas expediciones con OA de reserva; Kimün "científico";
  duelo en 2 celulares; notificaciones push y ranking real; limpiar perfiles de
  prueba en Supabase).

### Sesión 11 (2026-08-14)
- **Enriquecimiento por revisión pedagógica de los 3 bancos de año completo**
  (Matemática, Ciencias, Lenguaje). Se recibieron dos tandas de documentos externos:
  "recomendaciones_*" (estratégicas) y "revision_detallada_*" (por OA, con números
  de pregunta). **Ninguna aprobó preguntas** (son "previas a aplicación"), así que
  todo sigue **`revisada:false`**. Criterio acordado: **fixes concretos +
  enriquecimiento de mayor orden adaptado al formato de quiz (15 s)**, manteniendo
  los bancos (crecen).
  - **Matemática 518 → 603:** fixes (OA16 eje truncado como *efecto*, no regla
    absoluta —preguntas 2, 5, 15 y 17—; OA15 convención de cuartiles declarada;
    OA17 menos conteo repetido) + 85 ítems (análisis de errores, aplicación,
    interpretación). Se corrigió además un lote de tildes faltantes heredado.
  - **Ciencias 459 → 534:** fixes (excretor sin ambigüedad → riñón; distractor
    absurdo "rueda" reemplazado; OA01 con menos "¿quién descubrió?") + 75 ítems
    (situación experimental, evidencia→modelo, predicción de circuitos).
  - **Lenguaje 443 → 514:** +71 ítems (análisis de fragmentos breves, **efecto** de
    la figura literaria, inferencia con evidencia, emoción en publicidad, decisiones
    de escritura). Sin errores puntuales que corregir (la revisión es metodológica).
- Todo generado con agentes en paralelo (parciales por eje) y consolidado con
  validación (estructura, ids, opciones únicas, barrido de tildes y modismos).
- **`generar-pdf-preguntas.py`:** ahora sanea también superíndices/exponentes
  (`2⁵`→`2^5`, `2⁻¹`→`2^-1`) además de subíndices y ∛, para el PDF de revisión.
- **Límite de formato detectado:** varias recomendaciones (textos fuente + preguntas
  encadenadas; **producción escrita real** en OA13-15; sets sobre un mismo gráfico)
  **no caben en el quiz de 15 s**. Serían un **"modo lectura/evaluación" nuevo**
  (proyecto de motor, no de datos), que queda anotado como pendiente.
- El motor NO se tocó (solo datos + tablero + script). Las 4 expediciones se
  verificaron en el navegador (pool listo).
- **Pendientes:** aprobación humana / curación para la prueba final (las revisiones
  detalladas traen un mapa de "mejores ítems" por OA); eventual "modo lectura +
  escritura"; y los de siempre (nuevas expediciones con OA de reserva, Kimün
  "científico", duelo en 2 celulares, push y ranking real, limpiar Supabase).

### Sesión 12 (2026-08-14)
- **Aprobación humana de los 3 bancos:** Roberto marcó Matemática (603), Ciencias
  (534) y Lenguaje (514) como **revisadas** (`revisada:true` en todas; `revisadas =
  total`). Con Historia (663), el proyecto queda **100% revisado: 2.314/2.314**.
  Tablero regenerado (la barra "Revisadas por ti" marca 100% en las 4 asignaturas).
- Nota: el PDF `--sin-revisar` de esas tres ahora sale vacío (ya no hay pendientes).
- **Pendientes:** sin cambios (curación para la prueba final; eventual "modo lectura +
  escritura"; nuevas expediciones con OA de reserva; Kimün "científico"; duelo en 2
  celulares; push y ranking real; limpiar Supabase).

### Sesión 13 (2026-08-14)
- **Dos expediciones nuevas (OA de reserva, solo datos):** Ciencias "Electricidad y
  calor" (CN08 OA08-11) y Lenguaje "Mundos literarios" (OA04 poesía, OA05 teatro,
  OA06 epopeya, OA07 comedia). Cableadas en `EXPEDICIONES`; **6 expediciones jugables**
  (30 nodos). Verificadas en el navegador (pool + mapa OK). El motor no se tocó.
- **Diseño de la feature "campaña de asignatura completa" (piloto Historia):** se
  usó el flujo brainstorming → spec → plan. Idea: los OA de una asignatura, en orden,
  en capítulos de 4 OA (los sobrantes → "Desafío Extra" con recompensa mayor), un
  **Jefe Final grande** multi-fase (barra de vida, 3 corazones, se abre al 100%,
  puesta en escena épica) y **recompensas** (skin exclusiva bloqueada en tienda,
  insignias coleccionables con selector, corona dorada, bono). Se construye como
  **capa "Campaña" data-driven** sobre el motor actual (fase A), estrenando con
  Historia (fase C). Historia 8° se re-corta en 5 capítulos + Desafío Extra (OA20-22).
  - **Diseño aprobado** (página de revisión: artefacto privado).
  - **Spec:** `docs/superpowers/specs/2026-08-14-campana-historia-design.md`.
  - **Plan (5 fases, 17 tareas):** `docs/superpowers/plans/2026-08-14-campana-historia.md`.
  - **Aún sin implementar:** será la **primera feature de motor** (hasta ahora todo
    fue datos). Se retomará en sesión nueva / worktree aislado, tarea por tarea con
    subagent-driven-development, verificando en el navegador.
- **Pendientes:** implementar la campaña de Historia (plan listo); luego generalizar
  la plantilla a Matemática/Ciencias/Lengua; assets de Roberto (skin "Kimün
  historiador", arte del villano del Jefe Final); y los de siempre (Kimün "científico",
  duelo en 2 celulares, push y ranking real, limpiar Supabase).

### Sesión 14 (2026-08-14)
- **Campaña de Historia IMPLEMENTADA — primera feature de motor del proyecto.** Se
  ejecutó el plan de la Sesión 13 (5 fases, 17 tareas) con `executing-plans`, tarea
  por tarea, verificando cada una en el navegador (`preview_start` + `javascript_tool`
  + `read_page`). Todo el texto visible en español latino neutro; el motor
  data-driven publicado NO se rompió (las otras 3 asignaturas siguen como
  expediciones sueltas).
  - **Fase 1 · Datos:** se reemplazó `hist-europeos` por **6 rutas** de campaña
    (`hist-cap1`…`hist-cap5` + `hist-desafio`) que cubren los **22 OA** (mismo
    `preguntas.json`, distinto agrupamiento). Nuevos catálogos `CAMPAÑAS` (1: Historia)
    e `INSIGNIAS`; helpers `campañaDe`/`campañaPorId`. Estado nuevo en `S`
    (`campañasCompletas`, `insignias`, `insigniaActiva`) con `guardar()`/`cargar()`.
  - **Fase 2 · Pantalla de campaña:** helpers de desbloqueo (`expedicionCompleta`,
    `nodoCampDesbloqueado`, `desafioDesbloqueado`, `jefeFinalDesbloqueado`); tarjeta
    única por asignatura con campaña (+👑 al completar); pantalla `scr-campana` con
    desbloqueo secuencial (cap N tras vencer N-1; Desafío tras los 5 caps; Jefe al
    100%); botón "Volver a la campaña" en el mapa de capítulo.
  - **Fase 3 · Jefe Final multi-fase:** `scr-jefe-intro` (villano "El Guardián del
    Tiempo" 🐉, diálogo, tema carmesí `en-jefe`) + `scr-jefe` (barra de vida =
    fases×nPorFase = **16 aciertos**, **3 corazones**, **4 fases** por época, rótulo e
    indicador). Reusa el markup de opciones del quiz. Derrota → reintento con
    preguntas nuevas; victoria → recompensas + pantalla de celebración.
  - **Fase 4 · Recompensas:** `otorgarRecompensasCampaña` (marca campaña completa,
    desbloquea skin exclusiva, otorga insignia, corona y bono +500🪙/+300XP). Skin
    "Kimün Historiador" **visible-pero-bloqueada** en la tienda (🎓 marcador; el
    modelo real de skins es por emoji, no por imagen). Nueva pantalla de perfil
    (`scr-perfil`, reemplaza el `alert` de logros) con **vitrina de insignias +
    selector**; la insignia activa se luce junto al nombre en HUD, ranking y duelo.
    Pantalla de victoria `scr-jefe-win` con las 4 recompensas.
  - **Fase 5 · Migración:** cortesía en `cargar()` — si existe `hist-europeos` con el
    jefe vencido, se da por completado el Capítulo 1 (abre el Capítulo 2) y se elimina
    la clave vieja; XP/monedas/estrellas/skins/logros intactos. Recorrido real por la
    UI verificado de punta a punta.
- **Desviaciones del plan (justificadas):** reuso de las clases `.opts/.opt` del quiz
  en el Jefe Final; perfil como pantalla real (para el selector de insignias);
  migración marca todo el cap1 como completado (estado de mapa limpio) y solo si no se
  había empezado la campaña.
- **Assets reales integrados (fin de sesión):** Roberto generó (IA) y Claude procesó
  (recorte al contenido, cuadrado con margen, optimizado con paleta) los dos assets de
  la campaña:
  - **Skin "Kimün Historiador"** → `assets/kimun-historiador.png` (384×384, ~52 KB).
    Se cableó la **Opción A**: el sistema de skins (antes solo emoji) ahora soporta
    **skins con imagen** (`img` en `SKINS`, helpers `skinImg`/`avatarHTML`); la
    ilustración se muestra en HUD, tienda, ranking y pantalla de victoria. El emoji
    `🎓` queda solo como respaldo.
  - **Villano "El Guardián del Tiempo"** → `assets/villano-historia.png` (512×512,
    ~93 KB). Campo `villanoImg` en la campaña; se muestra grande en la intro del jefe
    y pequeño en el HUD del duelo, con `🐉` de respaldo.
- **Pendientes:** generalizar la campaña a Matemática/Ciencias/Lengua (plantilla ya
  probada; casi solo datos); y los de siempre (Kimün "científico" para Ciencias, duelo
  en 2 celulares, notificaciones push y ranking real, limpiar perfiles de prueba en
  Supabase).

### Sesión 15 (2026-08-15)
- **Sincronización (orden 99):** pull de las Sesiones 11-14 (campaña de Historia,
  jefe multi-fase, más expediciones sueltas).
- **Pantalla principal reorganizada en 2 niveles (4 módulos):** la pantalla de
  expediciones muestra ahora **un módulo por asignatura** (Historia, Matemáticas,
  Ciencias, Lenguaje) en vez de las expediciones sueltas mezcladas. Al entrar a una
  asignatura con campaña se abre su campaña; a una sin campaña, una nueva pantalla
  `scr-mapas` ("Elige un mapa"). Funciones `renderExpediciones` (nivel 1),
  `abrirAsignatura` (nivel 2), `mapasDe`, `ORDEN_ASIG`.
- **Portada propia por mapa (convención):** cada mapa usa `assets/portada-<id>.png`
  con **fallback** (onerror) a la portada de la asignatura; al crear la imagen aparece
  sola sin tocar código. Genéricas por asignatura en `ASIG_PORTADA`.
- **Ciencias convertida en CAMPAÑA completa (como Historia):** los 15 OA del año en
  **4 capítulos** = las 4 unidades oficiales (La célula, Cuerpo humano y salud,
  Electricidad y calor, La materia y el átomo). Se agregaron `cien-cuerpo` (OA05-07) y
  `cien-materia` (OA12-15); los 2 existentes pasaron a `campaña:'cien'`. **Jefe Final**
  de 4 fases (villano **"La Entropía"** 🌀), recompensa skin **"Kimün Científico"** +
  insignia **"Maestro de Ciencias"** + bono.
- **Motor de campañas generalizado:** estaba atado a Historia. Ahora el **"Desafío
  Extra" es opcional** por campaña, el título del jefe es dinámico
  (`JEFE FINAL DE <asignatura>`) y el jefe se desbloquea sin desafío. → Convertir
  Matemáticas/Lenguaje será casi solo datos.
- **Assets reales integrados (lote 3, `scripts/procesar-lote3.py`):**
  `villano-ciencias.png` (512, ~403 KB), `kimun-cientifico.png` (384, ~215 KB) y 3
  portadas de mapa (`portada-mate-algebra`, `portada-leng-textos`,
  `portada-leng-literarios`, 512, ~450 KB). Originales en `assets/originales/`.
  (Quedó una variante B del villano sin usar en Descargas.)
- **Corrección — nombres en el Duelo:** en "Elige la expedición" (duelo 1v1) cada
  opción mostraba solo la asignatura (6 "Historia" iguales, indistinguibles). Ahora
  muestra el **nombre del tema** en grande y la asignatura como subtítulo (`renderODExp`,
  reusa el helper `nombreMapa`).
- **Prueba con invitados:** el Capítulo 3 de Historia **"El mundo colonial"** queda
  **desbloqueado siempre** (flag `libre:true` en la expedición; `nodoCampDesbloqueado`
  lo respeta), para que los invitados prueben esa unidad sin completar las anteriores.
  Reversible quitando el flag cuando terminen las pruebas.
- **Audio — música de fondo + efectos (enfoque híbrido):** efectos procedurales
  nuevos en `SND` (tic-tac ≤5 s del timer en quiz y duelos; `hit` golpe al jefe;
  `hurt` daño; `unlock` desbloqueo de logro/insignia; `coin` compra en tienda).
  Nuevo objeto `MUSIC`: música de fondo por **archivos ligeros** con loop y volumen,
  cambia según contexto (`menu` para menú/mapa/quiz, `jefe` para el Jefe Final), con
  **fallback**: si el archivo no existe, no suena nada y no rompe (404 benigno).
  Control **separado**: botón 🎵 (música) y 🔊 (efectos), independientes y persistidos
  (`kimun_music`, `kimun_sound`). Las pistas (`assets/audio/musica-menu.mp3` y
  `musica-jefe.mp3`) las genera/consigue Roberto; specs y fuentes libres en
  `assets/audio/README.md`.
- **Matemáticas → "Reto de Cálculo" (nueva mecánica de cálculo mental rápido):** a
  pedido de Roberto, el camino de Matemáticas deja de ser el quiz de álgebra y pasa a
  ser un juego de **agilidad numérica**, alineado al eje Números de 8°. Generador
  **procedural** (`genCalculo`, sin banco, operaciones infinitas) con 5 niveles:
  Calentamiento (fluidez base), Enteros (OA01), Potencias y raíces (OA03-04),
  Fracciones y % (OA02/OA05) y Reto Relámpago (mixto + ecuaciones OA08). Mini-juego
  propio: mapa de niveles con desbloqueo (`scr-calc-mapa`), ronda de 10 operaciones
  con barra de tiempo por operación (10→6 s), combo y opción múltiple (`scr-calc`), y
  resultado con estrellas + XP/monedas (`scr-calc-res`). Progreso en `S.calc`
  (persistido). El módulo Matemáticas del menú abre el Reto; el banco de álgebra sigue
  disponible para el Duelo 1v1. Contenido verificado (respuestas correctas y alineación
  curricular). Ajustables: velocidad, nº de operaciones, dificultad, umbral de estrellas.
- **Reto de Cálculo ampliado (mismo peso que las campañas):** tras probarlo, Roberto
  notó que era corto y fácil comparado con las otras asignaturas. Se profundizó:
  cada nivel pasó a tener **3 sub-etapas** de dificultad creciente (**15 etapas** en
  total); **Jefe Final "El Autómata" 🤖** (se desbloquea al dominar los 5 niveles;
  barra de vida de 15, 3 corazones, 6 s/operación, mezcla de todos los tipos) que
  entrega skin **"Kimün Calculista" 🧮** + insignia **"Maestro del Cálculo" 🎖️** + bono
  (+500🪙/+300XP); y **Modo Sin Fin ♾️** con récord de racha máxima. Estado `S.calc`
  reescrito (`{etapas[5], jefe, record}`). Texto del candado de skins ahora usa `req`
  por skin (antes "Termina Historia" fijo). Dificultad retadora pero justa para 8°.
- **Hotfix (importante):** la reescritura de `S.calc` (estrellas→etapas) dejó una línea
  del menú (`renderExpediciones`, módulo Matemáticas) leyendo `.estrellas`, que ahora es
  `undefined`. Eso rompía `renderExpediciones` y **impedía entrar** (al pulsar JUGADOR no
  navegaba). Corregido a `.etapas.filter(e=>e>=RC_ETAPAS)`. Lección: al cambiar la forma
  de un objeto de estado, reprobar TODOS los flujos que lo leen (incluido el menú), no
  solo la feature nueva.
- **Reto de Cálculo con vida (Kimün + combos):** el Reto ahora tiene al compañero
  **Kimün reaccionando** en cada operación (neutral / feliz al acertar / sorprendido en
  combo / triste al fallar) — `kimReact` se generalizó para animar un elemento por id
  (`kimBuddyCalc`) — y la **animación de combo** ("COMBO x_ 🔥" + sonido) que ya usaba el
  quiz (`comboFx`, overlay global). Aplica en los tres modos (niveles, jefe y sin fin).
- **Assets reales (lote 4, `scripts/procesar-lote4.py`):** 8 imágenes generadas (IA) y
  procesadas. Integradas: skin **"Kimün Calculista"** 🧮 (premio del Reto, con imagen);
  villano **"El Autómata"** 🤖 ahora visible en el mapa del Reto y el HUD del jefe; y
  **4 skins ilustradas para la Tienda** — Astronauta (120🪙), Mago (130), Ninja (140),
  Superhéroe (160) — que dan valor real a las monedas (antes solo emojis). Guardadas para
  la **futura campaña de Lenguaje**: **Kimün Escritor** (`kimun-escritor.png`) y el jefe
  **"El Borrón"** (`villano-lenguaje.png`). Originales en `assets/originales/`; quedó una
  variante alternativa del Calculista sin usar (en Descargas de Roberto).
- **Banda sonora completa (5 pistas, mono 96 kbps, livianas):** Roberto generó los
  temas y Claude los recortó/comprimió con ffmpeg (vía `imageio-ffmpeg`, sin instalar
  nada al sistema). Cada momento suena distinto y `MUSIC.contexto(id)` enruta por
  pantalla: `menu` (menú/mapa/tienda/Reto, 60 s, 704 KB), `aventura` (quiz de
  expedición, 60 s, 704 KB), `jefe` (jefes de campaña, 45 s, 528 KB), `jefeCalc` (jefe
  del Reto "El Autómata", 45 s, 528 KB) y `duelo` (1v1, 43 s, 512 KB). ~2.9 MB en total,
  en loop y descargadas por contexto. Los originales pesaban 3-5 MB c/u (256 kbps
  estéreo) → recortados a loops de 45-60 s. Criterio de Roberto: jefes 45 s, menú ≤60 s.
- **Preview local:** `.claude/launch.json` levanta el servidor estático con
  `preview_start` (`python -m http.server 8765 --directory`, puerto fijo). Antes se
  arrancaba a mano; ahora lo gestiona el harness.
- **Banda sonora curada (Kevin MacLeod) + sección de créditos:** a Roberto no le
  convencieron los primeros temas (salvo el menú, de **Pixabay**). Claude buscó
  candidatas en Incompetech (**Kevin MacLeod**, CC BY 4.0 — FreePD cerró y Pixabay no
  se puede scrapear), le pasó previews de 40 s, y con las elegidas quedó: **Aventura**
  (Carefree / Sneaky Snitch) y **Jefe de campaña** (Death of Kings / Crossing the Chasm)
  que **se alternan al azar** (un contexto de `MUSIC.srcs` puede ser un arreglo; `play`
  elige una); **Autómata** (Digya) y **Duelo** (Severe Tire Damage). Todas mono 96k.
- **Sección de Créditos:** enlace "Créditos" en el inicio → recuadro con atribución
  precisa: música (Kevin MacLeod CC BY 4.0 + Pixabay), tipografías (Google Fonts · SIL
  OFL), contenido (**MINEDUC** de Chile), ilustraciones (IA de ChatGPT — sin atribución
  requerida). Revisión de licencias de todo lo de terceros: solo Kevin MacLeod obliga.
- **Fixes de audio:** (1) **desbloqueo en el primer gesto** del usuario para el autoplay
  en móvil (listener `pointerdown/touchstart/click/keydown` que arranca `MUSIC`); (2) las
  **etapas del Reto de Cálculo** ahora usan la música de `aventura` (antes `menu`, por
  eso "no cambiaba" al entrar al desafío) y el jefe su `jefeCalc`; (3) `MUSIC.play` hace
  `el.load()` al cambiar de pista (cambio de `src` fiable en móvil).
- **Música del Modo Sin Fin:** contexto propio `sinfin` con **"Voxel Revolution"**
  (Kevin MacLeod, electrónica intensa). El Reto quedó con música por modo: etapas
  `aventura`, sin fin `sinfin`, jefe `jefeCalc`.
- **Pendientes:** convertir Lenguaje en campaña (y decidir el enfoque de Matemáticas si
  se quiere además una campaña de álgebra); villano + skin por asignatura;
  portadas propias de los capítulos de Ciencias (opcional); duelo en 2 celulares,
  notificaciones push y ranking real, limpiar perfiles de prueba en Supabase.
  Recordatorio: quitar el `libre:true` de "El mundo colonial" al terminar las pruebas.

### Sesión 16 (2026-08-16)
- **Sincronización (orden 99):** `git pull` de `main` — ya estaba al día (nada nuevo
  que traer desde el otro PC).
- **Duelo 1v1 · "Elige la expedición" en 2 niveles (como la pantalla principal):**
  antes el selector del duelo mostraba **todas** las expediciones activas en una lista
  plana (13 opciones: 6 capítulos de Historia, álgebra, 4 de Ciencias, 2 de Lenguaje),
  difícil de recorrer. Ahora es de **2 niveles**: **nivel 1** = un módulo por asignatura
  (Historia · 6 mapas, Matemáticas · 1 mapa, Ciencias · 4 mapas, Lenguaje · 2 mapas);
  al tocar uno se abren sus mapas (**nivel 2**), cada uno seleccionable, con botón
  **"← Materias"** para volver. Todo dentro del mismo contenedor `#odExpSel` (sin
  pantallas nuevas).
  - **Implementación** (`index.html`): se reescribió `renderODExp()` (nivel 1) y se
    agregó `renderODExpMapas(asig)` (nivel 2) + helper `odExpsDe(asig)`. Reutiliza
    `ORDEN_ASIG`, `ASIG_PORTADA`, `nombreMapa`, `portadaMapa`/`portadaFallback`
    (portada propia por mapa con fallback a la de la asignatura), igual que la pantalla
    principal. Nota: en el duelo, **Matemáticas** usa su expedición de álgebra (no el
    Reto de Cálculo), coherente con que el banco de álgebra vive en el Duelo.
  - Como ya **no viene nada preseleccionado**, se agregó una validación en
    `iniciarDesafio`: si no hay expedición elegida, muestra *"Elige una expedición
    primero."* en vez de fallar. CSS nuevo para el botón `.od-exp-volver` (punteado,
    cian).
  - Verificado en el navegador (`preview_start` + `javascript_tool`): nivel 1 → abrir
    Historia → seleccionar un mapa (queda marcado) → "← Materias" vuelve a las 4
    asignaturas. Sin errores de consola (los 404 son los fallbacks benignos de
    portadas de capítulo y audio).
- **Duelo · Matemáticas ahora muestra el Reto de Cálculo (no "Álgebra y funciones"):**
  a pedido de Roberto, en el duelo Matemáticas debía verse **igual que su mapa** del
  juego principal (los niveles del Reto de Cálculo), no la vieja expedición de álgebra.
  Ahora el nivel 2 de Matemáticas lista los **5 niveles** del Reto (🔥 Calentamiento,
  ➖ Enteros, √ Potencias y raíces, ½ Fracciones y %, ⚡ Reto Relámpago) con su ícono
  emoji, mismo estilo que `renderNivelesCalc`. Al elegir uno, el duelo **genera 8
  operaciones al vuelo** con `genCalculo` (dificultad `RC_BASE[i]+1`), sin repetir, y
  las convierte al formato del duelo (`{pregunta, opciones, correcta, tip}`). Como el
  duelo asíncrono guarda las preguntas generadas, el rival recibe **las mismas
  operaciones**.
  - **Implementación** (`index.html`): helpers `odMapasMate()` (arma los niveles como
    "mapas" del duelo), `odNMapas(asig)` (conteo para el nivel 1) y `odPreguntasCalc(exp)`
    (genera las 8 operaciones); `renderODExpMapas` pinta ícono emoji para Matemáticas y
    portada para el resto; `iniciarDesafio` toma la rama de cálculo (sin `cargarPool`)
    cuando el mapa elegido trae `calc`. CSS nuevo `.od-exp-ic` (caja del emoji, 38×38).
  - **Alcance:** solo los 5 niveles (no el Jefe "El Autómata" ni el Modo Sin Fin, que no
    encajan en el formato de duelo de 8 preguntas). La expedición de álgebra deja de
    aparecer en el duelo. Verificado en el navegador (respuestas correctas, índices
    válidos, otras asignaturas intactas, sin errores de consola).
- **Lenguaje convertido en CAMPAÑA completa (como Historia y Ciencias) — cierra las 4
  asignaturas con campaña + jefe.** Se hizo con el flujo brainstorming → diseño aprobado →
  implementación (solo datos; el motor de campañas ya era genérico desde la Sesión 15).
  Las 2 expediciones sueltas de Lenguaje pasaron a ser **4 capítulos** que cubren los 15 OA
  (la U1 "Lectura literaria", con 8 OA, se partió en dos):
  - **Cap 1 · Leer y comprender** (OA01 hábito lector, OA02 experiencia humana, OA03
    narración, OA08 interpretación).
  - **Cap 2 · Mundos literarios** (OA04 poesía, OA05 teatro, OA06 epopeya, OA07 comedia).
  - **Cap 3 · Textos y medios** (OA09 argumentar, OA10 medios/publicidad, OA11 textos no
    literarios, OA12 estrategias de comprensión).
  - **Cap 4 · Escritura** (OA13 crear, OA14 explicar, OA15 persuadir).
  - **Jefe Final "El Borrón"** ✒️ (`assets/villano-lenguaje.png`), 4 fases (una por
    capítulo, las 15 OA repartidas), 3 corazones. Recompensas: skin **"Kimün Escritor"**
    (`assets/kimun-escritor.png`, visible-pero-bloqueada), insignia **"Maestro de las
    Letras"** ✍️, corona y bono +500🪙/+300XP.
  - **Implementación** (`index.html`, solo datos): las 4 expediciones con `campaña:'leng'`
    (se reusaron los ids `leng-literarios` y `leng-textos` para conservar sus portadas; los
    nuevos `leng-lectura` y `leng-escritura` caen al fallback `portada-lenguaje.png`);
    entrada `'leng'` en `CAMPAÑAS`; insignia en `INSIGNIAS`; skin `kimun-escritor` en
    `SKINS` (con imagen, `desbloqueaCon:'leng'`). El motor NO se tocó.
  - **Verificado en el navegador:** menú muestra Lenguaje como campaña (0/4 capítulos);
    desbloqueo secuencial (Cap 1 jugable, resto 🔒, jefe al 100%); pool carga para los OA
    de cada etapa; intro del jefe muestra a "El Borrón" con su arte; recompensas otorgadas
    OK (skin desbloqueada, insignia ganada, +500🪙). El duelo muestra los 4 capítulos de
    Lenguaje. Únicos 404: `portada-leng-lectura.png` y `portada-leng-escritura.png` (caen
    al fallback; arte propio opcional a futuro). Sin errores de JS.
- **Pendientes:** ¡las 4 asignaturas ya tienen campaña + jefe! Quedan: portadas propias de
  los 2 capítulos nuevos de Lenguaje y de los capítulos de Ciencias (opcional); duelo en 2
  celulares; notificaciones push y ranking real; limpiar perfiles de prueba en Supabase;
  quitar `libre:true` de "El mundo colonial" al terminar las pruebas.

### Sesión 17 (2026-08-16) — Preparación de la v0.99
Cierre de contenido, pulido y una intro. Se decidió etiquetar **v0.99** (candidata) para
dar una vuelta manual antes de la v1. Todo verificado en el navegador, sin errores de JS.
- **Revisión de completitud:** chequeo cruzado (script) de que **todos los assets
  referenciados existen** (31) y de que **cada etapa y jefe tiene preguntas**; los Jefes
  Finales cubren el 100% de los OA de su banco. Smoke test de las 4 campañas + Reto +
  duelo, carga limpia sin errores.
- **Limpieza v0.99:** se eliminó la expedición **`mate-algebra`** (quedaba inalcanzable:
  Matemáticas se juega como Reto de Cálculo y el duelo usa los niveles de cálculo; el banco
  de álgebra queda de reserva). Se quitó el flag **`libre:true`** de "El mundo colonial"
  → desbloqueo secuencial restaurado (probado con jugador nuevo).
- **Modo QA (`?qa=1`):** marca la respuesta correcta en todos los modos y desbloquea todo,
  para pruebas manuales; aviso visible; oculto y sin efecto en el juego normal. (Ver
  "Herramientas de desarrollo".)
- **Economía de la tienda re-escalonada:** los precios iban 40–160 (se compraba lo más caro
  con un capítulo). Ahora **80–900**: emojis de entrada (🦉80 … 👑350) + skins ilustradas
  premium (Astronauta 450, Mago 550, Ninja 700, Superhéroe 900). La tienda ahora muestra el
  **nombre** de las skins que lo tienen.
- **7 skins deportivas nuevas (premium, ilustradas · lote 5):** Karateka, Futbolista,
  Basquetbolista, Voleibolista, Ciclista, Tenista, Skater (🥋⚽🏀🏐🚴🎾🛹, 320–560).
  Roberto generó el arte (IA); Claude lo procesó con `scripts/procesar-lote5.py` (recorte,
  cuadrado, 384 px). En el mismo lote se integraron las **2 portadas** que faltaban de
  Lenguaje (`portada-leng-lectura`, `portada-leng-escritura`, 512 px) → ya no hay 404.
- **Intro de bienvenida (video):** `assets/intro.mp4` (~11 s, 9:16, 720×1278, ~1 MB). El
  zorro llega desde el fondo del espacio y orbitan símbolos de las 4 asignaturas (números y
  ÷+, átomo y matraz, pergamino y reloj de arena, pluma y letras) — sin palabras. Roberto
  generó el video (IA, varias iteraciones: sin texto, sin doble cola); Claude lo comprimió
  con ffmpeg (7–8 MB → ~1 MB), le antepuso **1 s de negro** y le puso **fundido de
  entrada/salida** (imagen + audio). **Audio:** "Fanfare for Space" de Kevin MacLeod
  (Incompetech, CC BY), tramo **7–17 s**, mono AAC, fusionado en el mp4 (atribución añadida
  a Créditos). Se reproduce **una vez por dispositivo** (flag `kimun_intro`), con botón
  "Saltar" y "▶ Toca para comenzar" cuando el navegador bloquea el autoplay con sonido;
  respeta `prefers-reduced-motion`; `?intro=1` la fuerza.
- **Documento de resumen (artefacto):** página visual con las 4 campañas y un diagrama de
  todo lo que se puede hacer en Kimün (privada, para compartir cuando Roberto quiera).
- **Pendientes:** dar la vuelta manual y decidir el paso a **v1**; versión del video en
  9:16 de pantalla completa ya lista; sigue opcional el arte de portadas de capítulos de
  Ciencias; y los de siempre (duelo en 2 celulares, push, ranking real, limpiar Supabase).

### Sesión 18 (2026-08-17)
- **Sincronización (orden 99):** `git pull` de `main` trajo las Sesiones 15-17 desde el
  otro PC (campañas de Ciencias y Lenguaje, Reto de Cálculo, banda sonora, intro en
  video, tienda re-escalonada, modo QA). Fast-forward sin conflictos.
- **Arte propio para los 14 capítulos (lote 6) — cierra el pendiente de portadas.**
  Roberto generó las 10 que faltaban (4 de Ciencias + 5 de Historia + el Desafío Extra);
  Claude escribió los prompts uno por uno, calibrados al estilo de las portadas de
  Lenguaje (Kimün de cuerpo entero haciendo la actividad del capítulo, objetos temáticos
  flotando, viñeta circular, paleta violeta/dorado/cian).
  - **Criterio editorial en los capítulos sensibles:** "Los europeos llegan a América" se
    centró en la **travesía** (carabela, brújula, astrolabio; sin armas ni banderas) y "El
    mundo colonial" en la **vida cotidiana y el mestizaje** (mercado, maíz, greda, adobe),
    evitando ilustrar la conquista armada o el trabajo forzado en una portada para niños.
  - **Procesamiento (`scripts/procesar-lote6.py`):** a diferencia del lote 5, estas vinieron
    en **RGB con fondo blanco opaco** (sin alfa), así que recortarlas por canal alfa las
    habría dejado como cuadrados blancos. El script detecta el fondo con **relleno por
    inundación desde las 4 esquinas** (así no borra los blancos interiores: delantal,
    bandera, pergaminos) y lo vuelve transparente con el borde suavizado; luego recorta,
    cuadra con margen y exporta a 512 px. De ~2,2 MB c/u a ~390 KB (3,8 MB en total).
    Originales en `assets/originales/`.
- **Las portadas ahora se lucen en la pantalla de campaña (cambio de motor chico):** antes
  los capítulos eran nodos con un número y las portadas solo se veían como miniaturas de
  ~40 px en el selector del duelo, donde el arte no se apreciaba.
  - `nodoCampañaEl` acepta imagen + respaldo (sin imagen conserva el círculo con la marca,
    compatible hacia atrás); `renderCampaña` pasa la portada de cada capítulo, la del
    Desafío Extra y el **villano de la campaña en el nodo del Jefe Final**.
  - CSS: círculo de 52 → **68 px** con la ilustración dentro, y el número pasó a una
    **insignia** (`.cn-badge`) que muestra número / ✓ / 🔒 según el estado. El gris de
    bloqueado se aplica solo a la ilustración, no a la insignia.
  - **Verificado en el navegador:** las 3 campañas (Historia 7 nodos, Ciencias 5,
    Lenguaje 5) cargan sus 17 imágenes sin caer al respaldo; los tres estados se ven
    correctos (completado verde con ✓, jugable violeta con número, bloqueado en gris con
    🔒). Sin errores de consola. Nota: el panel del navegador se cerró a mitad de la
    verificación, así que la comprobación final fue por DOM y estilos calculados, no por
    captura de pantalla.
- **Pendientes:** dar la vuelta manual y decidir el paso a **v1**; decidir qué hacer con
  los ~22 MB de originales en el repositorio y con el huérfano
  `assets/portada-mate-algebra.png` (la expedición de álgebra se eliminó en la v0.99);
  y los de siempre (duelo en 2 celulares, notificaciones push, ranking real, limpiar
  perfiles de prueba en Supabase).

### Sesión 19 (2026-08-17) — Cursos y ranking real
Cierra el pendiente más antiguo del proyecto: el ranking dejó de ser simulado. Se hizo con
el flujo completo brainstorming → diseño aprobado → plan → ejecución por subagentes, con dos
revisiones independientes del SQL. Diseño y plan en `docs/superpowers/`.
- **El problema de fondo no era el ranking, sino la identidad.** `renderRanking` inventaba
  cuatro nombres fijos, pero además Supabase no guardaba XP y **un jugador solo existía en el
  servidor si entraba al Duelo en línea**. Y la identidad era anónima por dispositivo: al
  limpiar el navegador se perdía todo. Por eso la feature terminó siendo "cursos + identidad
  + ranking", no solo el ranking.
- **Decisiones (Roberto):** el ranking mide **XP total**; se compite **por curso**; los cursos
  y alumnos los crea **el adulto desde el Modo Admin**; cada alumno entra con un **código de
  acceso** que lo vincula a su perfil en cualquier aparato.
- **Backend (`supabase/schema.sql`):** tablas `cursos`, `vinculos` y `config`; columnas `xp`,
  `curso_id` y `codigo_acceso` en `perfiles`. La tabla **`vinculos` separa la sesión anónima
  del dispositivo del perfil del alumno** — esa es la pieza que permite jugar en el celular y
  en el tablet sin duplicarse. Helper `kimun_yo()` y adaptación de las 6 funciones de duelo
  que asumían `auth.uid()`. Funciones nuevas: `kimun_xp`, `kimun_ranking`, `kimun_canjear` y
  cinco de administración.
- **Juego (`index.html`):** el perfil se crea **al abrir el juego** (antes solo en el duelo);
  pantalla de canje "🎟️ Tengo un código"; sincronización del XP enganchada a `guardar()` con
  un límite de 15 s; `renderRanking` reescrita con **tres estados** (con curso, sin curso, sin
  conexión) y caché; y **panel de administración de cursos** dentro del juego (`scr-admin`),
  de modo que ya no hace falta entrar a Supabase para inscribir alumnos.
- **Hallazgos de las revisiones (lo más valioso de la sesión).** El plan original tenía
  defectos que solo aparecieron al revisarlo:
  - **La política RLS de `perfiles` dejaba la tabla legible.** Al agregarle `codigo_acceso`,
    los códigos de todos los alumnos habrían quedado a la vista de cualquiera que abriera la
    consola. Se eliminó la política: ahora nada se lee directo.
  - **La clave de administración por defecto era explotable** (quedaba escrita en el
    repositorio). Ahora nace aleatoria y se guarda con hash bcrypt.
  - **PostgreSQL otorga EXECUTE a PUBLIC por defecto**: omitir una función del `grant` no la
    protege. Hubo que revocar explícitamente `kimun_admin_ok` y los generadores de código.
  - **pgcrypto vive en el esquema `extensions`, no en `public`** (particularidad de Supabase),
    así que `crypt()` no se resolvía dentro de las funciones y el Modo Admin habría muerto con
    un error indescifrable. `gen_random_uuid()` no sufre el problema porque es nativa de
    PostgreSQL desde la versión 13.
  - **`supabase-js` no lanza excepción cuando falla**: devuelve `{data, error}`. Tres
    manejadores del panel ignoraban el error y fallaban en silencio.
  - **El campo del código truncaba a 8 caracteres** cuando el código mide 12: el canje habría
    sido imposible.
  - **El XP corregido por el adulto se deshacía solo**, porque el teléfono volvía a enviar su
    valor local. Ahora el cliente adopta el valor del servidor cuando es menor y lo guarda.
- **Verificado con datos reales:** Roberto creó el curso "8vo csfs" con cuatro alumnos; el
  canje funciona y el ranking los muestra ordenados. Regresiones probadas: el duelo contra
  bots sigue operando con la identidad nueva, el juego no se rompe con Supabase caído, y un
  jugador sin curso ve la invitación a pedir su código en vez de nombres falsos.
- **Límites asumidos (documentados en el diseño):** el XP lo reporta el teléfono y puede
  falsearse —por eso existe `kimun_admin_xp_fijar`—; el progreso de campañas y las skins
  siguen siendo del aparato y no del alumno, así que en un tablet compartido dos hermanos
  comparten avance aunque tengan XP distinto; y la clave de administración sigue siendo un
  bloqueo suave, aunque ya no se puede leer del código fuente.
- **Mantenimiento desde el panel (cierre de la sesión):** se agregaron las dos herramientas
  que faltaban para no volver a depender del SQL Editor. **`✎` por alumno** usa
  `kimun_admin_xp_fijar` (que ya existía sin interfaz) para corregir un XP inflado, lo único
  que la sincronización normal no puede hacer porque solo sube. **🧹 Limpiar perfiles de
  prueba** usa la función nueva `kimun_admin_limpiar_pruebas(clave, ejecutar)`: con
  `ejecutar=false` cuenta y con `true` borra, así el botón informa cuántos son y pide
  confirmación antes de tocar nada. El criterio es "no es bot y no es alumno inscrito", es
  decir los perfiles que cada navegador o teléfono crea solo al abrir el juego.
  **Advertencia registrada:** borrar arrastra los duelos de esos perfiles y no tiene
  deshacer, así que conviene limpiar **después** de que los niños canjeen sus códigos; si se
  hace antes, un teléfono que ya venía jugando pierde su perfil en línea.
- **Pendientes:** probar el canje en los teléfonos de los niños y luego ejecutar la limpieza
  (la lista de rivales del duelo trae 18 entradas, casi todas de pruebas); dar la vuelta
  manual y decidir el paso a **v1**; los ~22 MB de originales y el huérfano
  `portada-mate-algebra.png`; duelo en 2 celulares; notificaciones push.

### Sesión 20 (2026-08-17)
- **Sincronización (orden 99):** llegó desde el otro PC la feature de Cursos y ranking real
  (Sesiones 18-19) + las portadas de capítulo de Historia y Ciencias (lote 6).
- **Botón para eliminar cursos (Modo Admin):** faltaba en el panel de cursos (solo se podían
  crear cursos y agregar/quitar alumnos). Ahora cada curso tiene un botón **🗑️** junto a su
  nombre que, tras confirmar (avisa que borra también sus alumnos y su lugar en el ranking),
  elimina el curso.
  - **Backend (`supabase/schema.sql`):** función nueva `kimun_admin_curso_quitar(clave,
    curso_codigo)` (SECURITY DEFINER, valida la clave con `kimun_admin_ok`): borra los
    `perfiles` con ese `curso_id` (arrastra sus duelos por cascade) y luego el curso;
    devuelve cuántos alumnos borró. Agregada al `grant`. **Roberto la aplicó en Supabase.**
  - **Juego (`index.html`):** botón `.adm-curso-del` en el encabezado de cada curso de
    `admListar`, con confirmación destructiva y refresco de la lista. Reusa el patrón del
    borrado de alumno y el traductor de errores `admError` (usa `curso_invalido`, ya definido).
- **Contraseña de Admin unificada (Cursos + Tablero):** había dos claves distintas —la de
  Cursos (servidor, bcrypt en `config.admin_clave`) y la del Tablero (bloqueo suave
  `CLAVE_ADMIN` en `generar-tablero.py`). Roberto eligió el enfoque **simple: una sola clave**
  para ambos, asumiendo que la de Cursos baja a "bloqueo suave" (queda en el repo vía el
  tablero). Se estandarizó en la que ya usaba el tablero (`112358`); Roberto la fijó en
  Supabase con `update public.config set valor = crypt('112358', gen_salt('bf',10)) where
  clave='admin_clave';`. Sin cambios en el repo (el tablero ya estaba en ese valor). Nota:
  esa clave también permite borrar cursos/alumnos; se puede endurecer cambiando `CLAVE_ADMIN`
  + regenerar el tablero + re-ejecutar el `update` con el nuevo valor.
- **Saludo al alumno en el inicio:** tras canjear su código, la pantalla de inicio muestra
  **"¡Hola, <Nombre>!"** con las mismas letras que KIMÜN (Titan One + degradado
  cian/violeta/rosa). Elemento `#rolNombre` + función `pintarInicio()` (se llama al cargar,
  tras el sync con el servidor, tras canjear y en `go('scr-rol')`). Si hay alumno, el saludo
  reemplaza el subtítulo genérico; si no, se ve el subtítulo normal. Solo `index.html`.
- **Recompensas del Modo Difícil (para motivar a estudiar más):** el Difícil era más difícil y
  rendía MENOS (10 s → menos bono de XP) y no daba recompensa propia. Se hizo con brainstorming →
  spec (`docs/superpowers/specs/2026-08-17-modo-dificil-recompensas-design.md`) → implementación.
  Roberto eligió recompensas de **prestigio/estatus, no inflar el XP** (para no distorsionar el
  ranking). Hito: completar **todos los capítulos de una asignatura en Difícil** (Historia,
  Ciencias, Lenguaje; Matemáticas queda fuera, tiene su propia dificultad).
  - **3 insignias 🔥** (`dif-historia/ciencias/lenguaje`), **skin "Kimün Maestro" 🏆** al completar
    las 3 (bloqueada, emoji hasta que haya arte), y **marca 🔥 social en el ranking** junto a
    cualquier alumno con Difícil, con **borde animado de 4 colores** (las asignaturas) cuya
    intensidad sube con el conteo (d1 borde · d2 +brillo · d3 grueso+brillo). Respeta
    `prefers-reduced-motion`.
  - **Backend (`supabase/schema.sql`, Roberto lo aplicó):** columna `perfiles.dificil`, función
    `kimun_dificil(n)` (sube el conteo, como `kimun_xp`) y `kimun_ranking` ahora devuelve `dificil`.
  - **Cliente (`index.html`):** helpers `asignaturasDificil()` + `revisarDificil()` (otorga
    insignias/skin, sincroniza el conteo; idempotente, retroactivo al iniciar), llamada al pasar
    una etapa en Difícil; marca 🔥 con dedupe (evita doble 🔥 en la fila propia). Best-effort: si el
    backend no está, no rompe (la marca simplemente no aparece).
- **Maestría Total (recompensa cumbre + celebración):** logro máximo = **los 4 jefes al
  máximo** — Historia + Ciencias + Lenguaje **en Difícil** y vencer a **El Autómata** (Reto de
  Cálculo). `esMaestro()` = `asignaturasDificil().length>=3 && S.calc.jefe`. Diseño en
  `docs/superpowers/specs/2026-08-18-maestria-total-design.md`.
  - **Al lograrlo:** (1) **video de celebración** `assets/maestro.mp4` (zorro rey, 10 s, con
    música épica **"Hero Down"** de Kevin MacLeod, CC BY) — overlay `#maestroOverlay`, una sola
    vez (flag `S.maestro`), con sonido (es tras una acción del usuario) y botón "Saltar";
    (2) **skin "Kimün Maestro" 🏆** (arte real integrado, `skin-kimun-maestro.png`, lote 5-bis)
    — su desbloqueo se movió de 3 → los 4; (3) **cambios visuales permanentes** con la clase
    `body.es-maestro`: **aura dorada** en el compañero Kimün (`#kimBuddy`/`#kimBuddyCalc`/
    `#resKim`) y el logo, **halo dorado** en el avatar/HUD, y **marco dorado** en la fila del
    ranking (`.rk.dif.d4`, sobre los bordes de 4 colores).
  - **Backend:** SIN migración nueva — reutiliza el `dificil` que ya se sincroniza; ahora el
    conteo **suma El Autómata** (0–4) y el ranking pinta el marco dorado si `dificil>=4`.
  - **Bug corregido de paso:** `#maestroOverlay` con `hidden` quedaba visible porque el CSS
    `id + display:flex` anulaba el atributo; se agregó `#maestroOverlay[hidden]{display:none}`.
  - **Video de intro/maestro:** ambos se comprimen con ffmpeg (imageio-ffmpeg) y guardan
    originales en `assets/originales/`. Créditos: añadida atribución de "Hero Down".
  - Verificado en el navegador (los 4 disparan la maestría, no antes; video una sola vez; aura
    persiste; ranking d4; sin errores de consola).
- **Pendientes:** sin cambios respecto a la Sesión 19.

### Sesión 21 (2026-08-18) — Rol de profesor (diseñado) y renombre a VULPO
- **Sincronización (orden 99):** llegó la Sesión 20 desde el otro PC (eliminar cursos,
  clave unificada, saludo al alumno, recompensas del Modo Difícil y Maestría Total).
- **Rol de profesor — diseño y plan, sin implementar.** Roberto pidió cuentas de profesor
  que administren uno o más cursos. El modelo actual no servía: una clave global (que además
  está en el repositorio) daba acceso total a todos los cursos, y `cursos` no tenía dueño.
  Decisiones: profesores de **un colegio real** (no solo gente de confianza), por lo que se
  pasa a **correo y contraseña** con Supabase Auth; **Roberto autoriza cada correo** con una
  lista blanca; cada profesor tiene **autonomía total sobre sus cursos** y nada sobre los
  ajenos; y el acceso es una **página propia** (`profesor.html`) con almacenamiento de sesión
  separado, para que iniciar sesión como profesor no le borre la identidad al niño que juega
  en ese mismo teléfono. **Idea de Roberto que mejoró el diseño:** sacar el Modo Admin del
  juego por completo, de modo que los niños solo vean Jugador y Duelo. Como consecuencia, la
  clave global y el panel de cursos dentro del juego se desmontan.
  Diseño: `docs/superpowers/specs/2026-08-18-rol-profesor-design.md`;
  plan de 11 tareas: `docs/superpowers/plans/2026-08-18-rol-profesor.md`. **Queda en cola.**
- **Renombre de la marca: KIMÜN → VULPO (plataforma) y Vulpi (mascota).** El nombre KIMÜN
  ya existe como marca de terceros, **incluida al menos una del rubro de enseñanza**, lo que
  bloqueaba el lanzamiento a producción. Se eligió una palabra de fantasía derivada de
  *vulpes* (zorro en latín): **Vulpo** para el colegio y los apoderados, **Vulpi** para el
  compañero de juego de los niños. Se descartó *Zorbi* porque ya es una app educativa activa;
  las empresas brasileñas *Vulpi* no bloquean porque las marcas se protegen por país y clase.
  Roberto confirmó la disponibilidad de **Vulpo** antes de ejecutar.
  Diseño: `docs/superpowers/specs/2026-08-18-renombre-vulpo-design.md`.
  - **Hallazgo que redujo el trabajo:** el nombre **nunca estuvo dibujado en el arte** (el
    logo es texto con tipografía web), así que **no hubo que regenerar ninguna ilustración**.
  - **Cambió lo visible:** título, logo, textos de la mascota ("🦊 Vulpi te cuenta…"), los
    nombres de las 17 skins, README, CLAUDE.md y el tablero.
  - **NO cambiaron los identificadores internos, a propósito:** las claves del navegador
    (`kimun_save`, `kimun_intro`…), las ~20 funciones de Supabase (`kimun_*`), los ids de las
    skins (`kimun-historiador`) y los 34 archivos de arte. **Cambiar las claves o los ids
    habría borrado el progreso y las skins compradas** de quien ya juega. Nadie los ve y no
    constituyen uso de marca.
  - **La bitácora conserva el nombre antiguo** porque es el registro histórico; se agregó una
    nota de marca al inicio de `CLAUDE.md` para que nadie lo lea como un descuido.
  - **Verificado:** siete pantallas más los créditos sin rastro del nombre anterior, y el
    progreso guardado (XP, monedas, skins) intacto tras el cambio. Sin errores de consola.
  - **Repositorio renombrado** a `vulpo`; GitHub deja una redirección desde la URL anterior.
- **Pendientes:** implementar el rol de profesor (plan listo); que los niños canjeen sus
  códigos y luego ejecutar la limpieza de perfiles de prueba; considerar un dominio propio
  (`vulpo.cl`) para no depender de la redirección de GitHub; dar la vuelta manual y decidir
  el paso a **v1**; los ~22 MB de originales y el huérfano `portada-mate-algebra.png`; duelo
  en 2 celulares; notificaciones push.

### Sesión 22 (2026-08-18) — Rol de profesor implementado
Se ejecutó el plan de 11 tareas con subagentes (implementador + revisión de seguridad por
separado). El resultado: **la clave global compartida desapareció** y la administración vive
en cuentas reales con aislamiento entre docentes.
- **Backend:** tablas `profesores` y `profesores_autorizados`, columna `cursos.profesor_id` y
  **14 funciones `kimun_prof_*`** que identifican al profesor por su sesión (`auth.uid()`) y
  ya no reciben ninguna clave. Helper `kimun_prof_es_mio` para la comprobación de propiedad.
- **`profesor.html` (nuevo):** ingreso, registro y panel, con un cliente de Supabase de
  **almacenamiento separado** (`storageKey:'kimun-profesor'`). Sin eso, un profesor que
  inicia sesión en el teléfono donde juega su hijo le borraría la identidad al niño.
- **Se retiró del juego:** el botón Modo Admin, la pantalla `scr-admin` y sus 148 líneas de
  JavaScript, más las 8 funciones `kimun_admin_*` y la fila `admin_clave`. **La pantalla de
  inicio quedó con solo Jugador y Duelo**, que era la idea de Roberto.
- **Hallazgos de las revisiones (lo más valioso).** El plan tenía defectos que solo
  aparecieron al revisarlo y ejecutarlo:
  - **La cuenta de administrador era reclamable desde internet.** Sembrar el correo del
    administrador en la lista blanca, con el repositorio público y la confirmación de correo
    desactivada, permitía que cualquiera se registrara con ese correo y quedara como
    administrador. Se eliminó la semilla: el administrador se crea a mano desde Supabase.
  - **La recomendación de desactivar la confirmación de correo era peligrosa** y se revirtió.
    Es lo único que impide registrarse con un correo ajeno.
  - **El `delete` que liberaba registros huérfanos permitía escalar a administrador** y podía
    borrar la cuenta de un profesor vivo. Quedó acotado con `not exists` sobre `auth.users`.
  - **`kimun_prof_yo` no devuelve null** para quien no es profesor, sino una fila de campos
    vacíos, que en JavaScript es un objeto verdadero: **el panel se habría abierto para
    cualquiera**. Se detectó probando contra el servidor real, no leyendo código.
  - **Un profesor no autorizado quedaba encerrado**, viendo "no tienes permiso" en cada
    visita sin poder cerrar sesión, porque el botón vivía dentro del panel oculto. Es el
    camino que recorre todo docente que se registra antes de ser autorizado.
  - **`admEsc` era usada por el ranking**, no solo por el panel: borrar el bloque del Modo
    Admin habría roto el ranking del curso. Se rescató como `escHtml`.
  - Faltaban por completo **revocar a un profesor** y **reasignar un curso huérfano**: sin
    ellas, un docente que deja el colegio conservaba acceso para siempre.
- **Riesgo activo encontrado y cerrado:** la clave `112358` estaba en el repositorio público
  y permitía a cualquiera leer los códigos de acceso de todos los alumnos y borrar cursos.
  Roberto la cambió por una que no está en el repositorio; con el retiro de las funciones
  `kimun_admin_*` el problema queda cerrado de raíz.
- **Límites conocidos:** el correo integrado de Supabase permite **2 envíos por hora**, así
  que para un colegio real hace falta SMTP propio (Resend o Brevo) antes de dar de alta
  varios profesores; sin él, tampoco hay autorrecuperación de contraseña.
- **Aislamiento VERIFICADO con dos cuentas reales.** Roberto creó un profesor de prueba y,
  desde su sesión, llamó directamente a las funciones del servidor saltándose la interfaz:
  `kimun_prof_curso_quitar` sobre el curso del administrador y `kimun_prof_xp_fijar` sobre un
  alumno ajeno. **Ambas respondieron `no_autorizado`** y los datos quedaron intactos. Además,
  el profesor de prueba ve "Mis cursos" en vez de "Todos los cursos", no ve los cursos ajenos
  y no tiene sección de administración.
- **Confusión detectada al probar, y corregida:** el servidor responde `no_autorizado` tanto
  cuando faltan permisos como cuando el curso no existe —es deliberado, separarlos permitiría
  descubrir qué códigos existen probándolos—, pero el panel mostraba "No tienes permiso" a un
  profesor que simplemente había borrado su propio curso en otra pestaña. Ahora el mensaje
  dice "No tienes permiso para esto, o el curso o alumno ya no existe" y la lista se refresca
  sola tras un fallo, para no seguir mostrando algo que ya no está.
- **Nota:** el curso "8vo csfs" y sus cuatro alumnos ya no existían al llegar aquí; se habían
  borrado antes del cambio. Los códigos `ALU-` entregados quedaron sin efecto.
- **Pendientes:** probar el aislamiento con un segundo profesor; crear el curso real de los
  niños y que canjeen sus códigos; los dos trámites (marca en INAPI y dominio `vulpo.cl`);
  configurar SMTP; la vuelta manual para decidir la v1; duelo en 2 celulares; push.

### Sesión 23 (2026-08-18) — Mapa de dominio por OA
Primera herramienta pensada para el **adulto** y no para el niño: el profesor ve, por
objetivo de aprendizaje, cómo va su curso y cada alumno, para decidir qué reforzar. Hecha
con el flujo brainstorming → spec → plan → subagentes, con revisión de seguridad aparte.
- **El problema:** el XP mide cuánto juega un niño, no qué entiende. Cada pregunta ya traía
  su campo `oa`, pero nada de eso subía al servidor.
- **Decisiones (Roberto):** se ve **el curso y también cada alumno**; se guardan
  **contadores por alumno y objetivo** (no cada respuesta, por privacidad y volumen); y solo
  cuentan **campaña y jefes**, no el duelo (contra el reloj, se falla por apuro) ni el Reto
  de Cálculo (operaciones generadas al vuelo, sin OA).
- **Backend:** tabla `dominio` (perfil, oa, respondidas, correctas), `kimun_dominio(jsonb)`
  que suma el resumen de cada etapa, y `kimun_prof_dominio`, `kimun_prof_dominio_alumno` y
  `kimun_prof_dominio_reiniciar` con el aislamiento por curso ya probado.
- **Juego:** acumulador en memoria durante la etapa y envío al terminar; el **modo QA no
  registra**; los envíos fallidos quedan pendientes y se reintentan. Nada interrumpe la
  partida.
- **Panel:** botón "📊 Ver avance" por curso y 📊 por alumno; tabla ordenada de peor a mejor
  con el **texto real del objetivo** (leído de `contenido/<asignatura>/oa.json`), la barra de
  color y **cuántas preguntas respaldan cada porcentaje**; botón de reinicio de mediciones.
- **Dos fallos silenciosos que se atajaron al implementar:**
  - `buildPreguntas` y `jefePreguntasFase` **descartaban el campo `oa`** al armar las
    preguntas. Con el plan tal cual, la tabla habría quedado **vacía para siempre sin ningún
    error visible**. Fue el hallazgo más importante de la sesión.
  - El backend descarta las entradas cuyo código no calce con `^[A-Z]{2}[0-9]{2} OA [0-9]{2}$`.
    La expresión se contrastó contra las **2.314 preguntas y los 69 códigos reales** antes de
    dejarla: un código legítimo que no calzara habría dejado ese objetivo sin medir, también
    en silencio.
  - Además, un cast sin validar podía perder un lote entero y dejarlo reintentándose para
    siempre, y una referencia calificada con esquema en un `ON CONFLICT` podía fallar recién
    en producción (los cuerpos plpgsql no se validan al crearse). Ambas corregidas, la
    segunda también en `kimun_prof_alta`, que ya estaba aplicada.
- **Decisión registrada:** una etapa abandonada a medias **no se descarta**; lo respondido
  viaja con el resumen de la siguiente etapa terminada. Son respuestas reales, y un alumno
  que abandona tras fallar es información útil. El jefe abandonado sí se pierde.
- **Probado con datos reales:** una etapa jugada por la interfaz registró exactamente 6
  respondidas y 4 correctas. Después se simuló un curso completo —**30 alumnos, ~460
  respuestas en 77 registros**— con dificultad distinta por asignatura, para ver el informe
  con contraste.
- **Límite asumido y visible en pantalla:** **no sirve para calificar**; el dato lo reporta
  el teléfono del alumno, igual que el XP.
- **Pendientes:** que Roberto revise el informe con su cuenta; borrar el curso de simulación;
  Matemáticas no aparece en el mapa (habría que mapear los niveles del Reto a los OA de
  Números si se quiere cubrir); los dos trámites (INAPI y `vulpo.cl`); SMTP antes de dar de
  alta profesores reales; la vuelta manual para decidir la v1; duelo en 2 celulares; push.

### Sesión 24 (2026-08-18) — Revisión del informe y corrección del porcentaje
Roberto pidió mejorar el área del profesor y se despacharon **tres agentes con miradas
distintas** —docente de aula, analista de datos y diseñador de producto— sobre la
herramienta recién construida. De ahí salió el trabajo de esta sesión.
- **El hallazgo que obligó a corregir:** el porcentaje era `correctas/respondidas` acumulado,
  y **el denominador dependía de lo que se quería medir**. Se reintenta una etapa cuando no
  se entendió, así que el alumno que menos sabe aporta más respuestas y pesa más en el
  promedio del curso. Ejemplo con 30 alumnos: el panel mostraba 66,7% donde el promedio real
  era 76,7%, con la mitad de la base aportada por seis niños repitiendo.
- **La corrección:** dos columnas `resp_1` y `ok_1` en `dominio`, escritas **solo en la rama
  `insert`** de `kimun_dominio` y jamás en el `on conflict do update`. El porcentaje pasa a
  ser "cuántos acertaron la primera vez que vieron este contenido", con el mismo denominador
  para todos los objetivos. `respondidas - resp_1` queda como señal propia: cuánto costó.
  **Cuatro líneas de SQL, cero cambios en `index.html`.**
- **Verificado contra la base real:** dos partidas sobre un objetivo nuevo (4 de 6 y luego 6
  de 6) dejaron `respondidas=12, correctas=10` y **`resp_1=6, ok_1=4`**. Ese objetivo reporta
  67% en vez del 83% inflado.
- **Otros cambios del panel:** colores calibrados al **piso del azar** (con 4 opciones,
  responder sin saber da 25%, así que los cortes van en 45% y 70%); la atenuación por base
  pequeña se reemplazó por **tres bloques** —Para reforzar, Van bien, Todavía con pocos
  datos— porque ordenar de peor a mejor y atenuar a la vez se peleaban: la posición decía
  "mira esto primero" y la opacidad decía "ignora esto", de modo que la primera fila podía
  ser justo la menos confiable; se muestra el número de alumnos que respaldan cada
  porcentaje (dato que ya viajaba del servidor y se descartaba); y se advierte que
  **Matemáticas no se mide**, para que el silencio no se lea como "todo bien".
- **Lo que los tres informes dejaron para más adelante**, sin implementar:
  - **Del objetivo a los nombres:** al tocar una fila, ver quiénes necesitan apoyo. Es el
    vacío que el profesor de aula puso primero, y los datos ya existen.
  - **Participación y fecha:** quién jugó esta semana y quién no ha entrado nunca.
    `dominio.actualizado` ya lo permite sin guardar nada nuevo.
  - **Presentación:** encabezado que diga de qué curso es, salto al inicio al abrir, botón de
    volver arriba, texto a dos líneas, filtro por asignatura. Con textos de 250 caracteres
    caben **tres objetivos por pantalla** y 60 filas son 8.228 px de scroll.
  - **Un defecto de hoy sin corregir:** el botón 📊 por alumno empujó esa fila y provocó
    **scroll horizontal** en móvil; los botones miden 21×25 px y el de borrar quedó a 30 px
    del de ver avance.
  - **Estadística por ítem** (~2.300 filas fijas, sin `perfil_id`) para calibrar los bancos,
    que hoy no lo están: parte de la brecha entre un objetivo en 45% y otro en 87% es que un
    banco es más duro, no que los niños sepan menos.
- **Advertencia registrada:** el riesgo real no es que la herramienta se use poco, sino que
  un colegio la use para **calificar o supervisar docentes**. El dato viene del teléfono del
  alumno: en cuanto tiene consecuencias, el camino corto a un buen número deja de ser
  estudiar. Y la cuenta de administrador —que en un colegio sería UTP— puede abrir el avance
  de cualquier curso.
- **Pendientes:** limpiar el curso de simulación y ver el informe con datos limpios; las
  mejoras listadas arriba; los dos trámites (INAPI y `vulpo.cl`); SMTP; la vuelta manual para
  decidir la v1.

### Sesión 25 (2026-08-18) — Quiénes necesitan apoyo, y el comando Titanic
- **Del objetivo a los nombres.** Era el vacío que el informe pedagógico puso primero: el
  mapa decía *qué* contenido estaba flojo, no *quiénes*. Un objetivo en 45% puede ser el
  curso completo —hay que reenseñar y se pierde una clase— o seis niños que arrastran el
  promedio —basta un grupo de refuerzo—, y distinguirlo exigía abrir 35 fichas a mano.
  - **Función nueva `kimun_prof_dominio_oa(curso, oa)`**: devuelve a **todos** los alumnos
    inscritos con su primer intento en ese objetivo, también a los que no lo jugaron
    ("12 no lo han visto" es información), **ordenados por nombre**. El orden alfabético es
    intencional: por rendimiento sería un ranking de niños.
  - **Cuatro grupos** al desplegar una fila: Necesitan apoyo (bajo 45%), En camino (45-70%),
    Lo lograron (70%+) y **Todavía sin evidencia** (menos de 4 preguntas de primer intento o
    sin jugar). Ese cuarto grupo evita mandar al refuerzo a un niño que falló **una sola
    pregunta** en un jefe final, donde cae una de cada objetivo.
  - **No se muestra el porcentaje individual ni se puede ordenar por rendimiento**, a
    propósito: una lista de menores ordenada por nota, con números al lado, es el artefacto
    que termina proyectado en un consejo o pegado en un libro de notas.
  - **No agrega ni una columna:** la información ya estaba en `dominio`.
  - **Verificado:** la clasificación reparte bien los cinco casos de prueba (incluido el que
    falló su única pregunta, que cae en "sin evidencia"); con 35 alumnos la suma de los
    cuatro grupos da 35, o sea nadie se pierde; no desborda en 375 px; y la función rechaza
    a un anónimo. **Falta que Roberto pruebe el aislamiento entre dos profesores**, que es lo
    que protege los nombres de los alumnos ajenos.
  - Hallazgos del subagente: faltaba el `drop function if exists` de la función nueva —sin
    él, el día que alguien agregue una columna al resultado, re-aplicar el esquema falla—; y
    `list-style:none` no oculta el triángulo del desplegable en Safari, hace falta
    `::-webkit-details-marker`.
- **Comando `/titanic`** (`.claude/skills/titanic/SKILL.md`): genera el prompt de traspaso
  para empezar una sesión nueva sin perder el hilo. Revisa el estado real del repositorio y
  entrega un prompt listo para copiar; **el `/clear` y el pegado son del usuario**. La
  decisión clave: el prompt **no repite lo que ya está en `CLAUDE.md`**, que se carga solo,
  sino el delta de la conversación que se cierra.
- **Pendientes:** probar el aislamiento entre profesores en la vista de apoyo; borrar el
  curso de simulación y generar datos nuevos para ver el mapa con el primer intento; las
  mejoras que dejaron los tres informes (participación y fecha, encabezado del curso, filtro
  por asignatura, el scroll horizontal que introdujo el botón por alumno); los dos trámites
  (INAPI y `vulpo.cl`); SMTP; la vuelta manual para decidir la v1.

### Sesión 26 (2026-08-19) — El mapa se puede recorrer, y participación
Dos trabajos sobre el panel del profesor. Primero, la **presentación del mapa**: tenía la
información correcta pero era incómoda en un teléfono (solo en `profesor.html`, sin tocar el
esquema). Después, una feature nueva, **participación y fecha**, que sí toca el backend.
- **El desborde en móvil no lo causaba el botón 📊.** Ese fue el disparador, pero la causa
  estaba desde antes: el nombre del alumno llevaba `flex:1` **sin `min-width:0`**, y un
  elemento flex no se encoge por debajo del ancho de su contenido salvo que se le diga. Con
  un nombre largo la fila crecía y arrastraba el panel entero: 382 px sobre 375. La fila del
  alumno pasó a **dos líneas** (nombre y botones arriba, código y XP abajo) y los botones de
  **21×25 px a 38×38**, con el de borrar apartado del resto porque es lo único sin deshacer.
  El mismo defecto estaba en la cabecera del curso y en la lista de profesores del
  administrador; los tres se corrigieron igual.
- **El mapa se recorre:** encabezado **pegado arriba** con el nombre del curso o del alumno
  y el botón de volver (el título del panel se oculta mientras tanto: decir "Mis cursos"
  sobre la tabla de un curso confunde); texto del objetivo **recortado a dos líneas**, que
  se abre entero al desplegar la fila —en la vista de un alumno, donde la fila no se
  despliega, va completo desde el principio—; **filtro por asignatura** en las dos vistas,
  que no se dibuja si hay una sola; salto al inicio al abrir cada vista y al cambiar de
  filtro; y botón flotante de **volver arriba** pasados 600 px. De **tres objetivos por
  pantalla a unos diez**.
- **Lo que más riesgo tenía:** el filtro rehace el cuerpo de la tabla, así que los `toggle`
  que cargan "quiénes necesitan apoyo" hay que **volver a cablearlos** en cada repintado. Sin
  eso el desplegable habría quedado mudo justo después de filtrar, que es cuando más se usa.
  Se extrajeron `conectarFilasOA` y `conectarFiltros` para que las dos vistas compartan el
  mismo cableado.
- **Verificado a 375 px con un banco de pruebas** que sustituye el backend (35 alumnos, 52
  objetivos, tres asignaturas), porque el panel real necesita credenciales: `scrollWidth`
  igual al viewport en todas las pantallas, filtro (52 → 22 Historia → 15 Ciencias), el
  desplegable de apoyo cargando después de filtrar, los tres bloques, la vista por alumno,
  el curso sin datos y el panel de administrador. Sin errores de consola. **Falta la
  confirmación con la cuenta real**, aunque las llamadas al servidor no cambiaron.
- **README corregido (primer trabajo):** decía que los cursos se crean "desde el Modo
  Admin", que se retiró en la Sesión 22. Ahora apunta a `profesor.html` y menciona el mapa.

**Participación y fecha (segundo trabajo).** El mapa decía *qué* contenidos costaban, no
*quiénes* están jugando. Se hizo con el flujo completo brainstorming → spec → plan →
subagentes (implementador + revisión de spec + revisión de calidad por separado).
- **El dato no salía de donde parecía.** La primera idea era usar `dominio.actualizado`, que
  ya existía, pero solo se escribe al terminar una etapa de **campaña o jefe**: un niño que
  juega Matemáticas (Reto de Cálculo) todos los días aparecería como "nunca entró". Se eligió
  una columna `visto` en `perfiles`, **sellada dentro de `kimun_xp`** —la sincronización que
  el juego ya hace cada 15 s en cualquier modo, y también al abrir—, así que mide la última
  entrada de verdad. Una línea de SQL, cero envíos nuevos desde el cliente.
- **Cuatro grupos, no una lista con fecha.** Jugaron esta semana / hace más de una semana /
  canjearon su código pero no han jugado / **nunca canjearon su código**. Los dos últimos se
  separan porque la acción es distinta: no canjear casi nunca es desinterés, es un código
  perdido o un teléfono que no tienen, y se resuelve volviendo a entregar el código. Fichas
  alfabéticas, **sin fecha individual ni orden por inactividad**: una lista de menores por
  días sin entrar se leería como lista de asistencia. Va en un bloque plegado arriba del
  mapa, porque la participación es el contexto que hace legible el porcentaje (un 45% no es
  lo mismo con 30 niños jugando que con cinco que nunca entraron).
- **Migración de arranque:** `visto` se rellena desde `max(dominio.actualizado)` al aplicar
  el esquema (idempotente con `where visto is null`). Quien solo jugó Reto de Cálculo parte
  sin fecha hasta su próxima entrada; es una limitación del primer momento, no permanente.
- **Hallazgo de la revisión de calidad (lo más valioso).** `cargarParticipacion` se lanza
  sin `await`; se cargaba con ids fijos, así que cambiar de curso con la consulta en vuelo
  hacía que la respuesta tardía escribiera **los datos de un curso bajo el encabezado de
  otro** —el cruce de identidad que la herramienta se cuida de evitar—. Corregido capturando
  los nodos antes del await, como ya hace `conectarFilasOA`. La revisión también rescató el
  marcador de Safari (`list-style:none` no oculta el triángulo del `<details>` en iOS sin
  `::-webkit-details-marker`, ya sabido desde la Sesión 25).
- **Backend:** columna `perfiles.visto`, `visto = now()` dentro de `kimun_xp`, función
  `kimun_prof_participacion(curso)` con el aislamiento por curso ya probado, y la migración
  de relleno. `index.html` **no se tocó**: el juego ya llama a `kimun_xp`.
- **Verificado a 375 px con backend simulado** (20 alumnos repartidos en los cuatro grupos):
  titular y conteos correctos sin perder a nadie, sin desborde lateral, el fallo de
  participación no tumba el mapa, el bloque aparece aunque el curso no tenga datos de
  dominio, y la carrera de cursos quedó demostrada (A lento no pisa a B). Sin errores de
  consola. Diseño y plan: `docs/superpowers/specs/2026-08-19-participacion-fecha-design.md` y
  `docs/superpowers/plans/2026-08-19-participacion-fecha.md`.
- **Falta por el lado de Roberto:** aplicar el esquema en el SQL Editor (hasta entonces la
  vista corre con datos simulados) y probar el aislamiento de `kimun_prof_participacion`
  entre dos profesores, igual que en la vista de apoyo.
- **Pendientes:** probar el aislamiento entre profesores en las vistas nuevas (apoyo y
  participación) y aplicar el SQL de participación; borrar el curso de simulación y generar
  datos nuevos; los dos trámites (INAPI y `vulpo.cl`); SMTP; la vuelta manual para decidir
  la v1.

### Sesión 27 (2026-08-20) — Se cierra participación y el panel se pliega en acordeón
Tres bloques: se cerró lo que quedaba pendiente de la Sesión 26, se generaron datos limpios
para ver los informes, y se reorganizó el panel del profesor.
- **Participación verificada en producción.** Roberto ya había pegado el esquema; se confirmó
  en el SQL Editor que existen `perfiles.visto` y `kimun_prof_participacion(p_curso_codigo text)`.
  El **aislamiento entre profesores** quedó probado en las dos vistas nuevas: desde la sesión
  del profesor de prueba (`profe-prueba@vulpo.cl`), llamar `kimun_prof_participacion` y
  `kimun_prof_dominio_oa` sobre un curso ajeno (`CUR-A692`, de otra cuenta) devolvió
  **HTTP 400 / `no_autorizado`** (la función hace `raise exception`, que PostgREST traduce a
  400). Cierra las dos pruebas que quedaban desde las Sesiones 25 y 26.
- **Datos limpios en `CUR-1939` (enfoque híbrido).** Se generaron **30 alumnos**: 28 por un
  bloque SQL de simulación (repartidos en los cuatro grupos de participación, con dominio de
  **primer intento** variado sobre los 12 OA de las primeras etapas de las tres campañas) y
  **2 jugados de verdad** desde el juego —**Renata Poblete** y **Simón Valenzuela**—, canjeando
  su código `ALU-` real y registrando por las **mismas funciones del servidor** que usa el
  juego (`kimun_dominio`, `kimun_xp`). Renata además **jugó el Reto de Cálculo por la interfaz**
  (etapa 1 superada), para demostrar que **Matemáticas cuenta para participación y XP** aunque
  —por diseño— no aparezca en el mapa de dominio. Detalle de automatización: el timer de las
  preguntas no deja seguir el ritmo clic a clic desde fuera, así que las etapas de campaña se
  registraron con la función real (idéntico pipeline) y el Reto se resolvió con un script en la
  propia página.
- **Panel del profesor reorganizado en acordeón (solo `profesor.html`, cero SQL).** Antes
  `pintarLista` pintaba **todos los cursos con todos sus alumnos expandidos**, un caos con más
  de un curso. Ahora:
  - **Identidad arriba:** "👤 &lt;nombre&gt; — Administrador/Profesor" (`#profId`), que se
    oculta en las vistas de avance (junto al título) y reaparece al volver.
  - **Cursos plegados** (`<details>`, el mismo patrón que las filas de objetivos): la cabecera
    muestra nombre, código, "N alumnos" y **"Participación · X/N jugaron esta semana"**, cargada
    en segundo plano por `cargarTitularesParticipacion` (una consulta por curso, reusa
    `gruposParticipacion`). El nodo del titular **se captura antes del `await`** para que la
    respuesta tardía de un curso no escriba bajo otro (misma precaución de la Sesión 26).
  - **Dentro del curso:** primero "📊 Ver avance del curso", luego un sub-acordeón
    **"👥 Alumnos (N)"** con las filas y el campo de agregar. El 🗑️ borra el curso **sin**
    alternar el acordeón (`stopPropagation`), y el marcador nativo del `<details>` se oculta con
    `::-webkit-details-marker` (fix de Safari ya conocido).
  - Ajuste sobre el plan: en móvil el nombre del curso se truncaba, así que "N alumnos" y la
    participación pasaron a sus propias líneas para que el nombre respire.
  - Diseño y plan: `docs/superpowers/specs/2026-08-20-panel-profesor-acordeon-design.md` y
    `docs/superpowers/plans/2026-08-20-panel-profesor-acordeon.md`.
- **Verificado a 375 px con un banco simulado** que sustituye el backend (no se puede iniciar
  sesión de profesor desde aquí): identidad y rol, dos cursos plegados con su titular correcto
  (1/3 y 1/2, sin cruce al repintar), avance primero + alumnos plegables, 🗑️ sin alternar,
  nombre completo, sin desborde lateral, bloque de administración intacto y cero errores de
  consola. **Falta la confirmación con la cuenta real** (donde el titular consulta de verdad),
  aunque las llamadas al servidor no cambiaron.
- **Pendientes:** confirmar el acordeón con la cuenta real; **la feature grande que pidió
  Roberto** —orientar por asignatura (qué repasar) y **preparar un desafío que obligue a rehacer
  una cadena de preguntas** para reforzar, con su propio brainstorming (toca panel + backend +
  el juego); borrar el curso de simulación cuando ya no se necesite; los dos trámites (INAPI y
  `vulpo.cl`); SMTP; la vuelta manual para decidir la v1.
