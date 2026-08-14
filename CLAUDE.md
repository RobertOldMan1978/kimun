# KIMÜN — Plataforma de juegos educativos

## Descripción del proyecto

KIMÜN es una plataforma de juegos educativos para escolares chilenos de 15 años
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

Publicado en GitHub Pages y en prueba real. Un `index.html` mobile-first +
contenido en JSON (`contenido/<asignatura>/`) + backend Supabase para el duelo
en línea. Historia de v0 al detalle en la Bitácora (abajo).

**Jugable hoy:**
- Inicio con selección **Jugador / Duelo 1v1 / Admin** y el rostro de la mascota
  **Kimün** (zorro; `assets/kimun.png`, con expresiones por respuesta).
- **Expediciones data-driven** (arreglo `EXPEDICIONES`, progreso por ruta),
  **4 jugables**: Historia "Los europeos llegan a América" (OA04-07),
  Matemáticas "Álgebra y funciones" (MA08 OA06-09), Ciencias "La célula"
  (CN08 OA01-04) y Lenguaje "Tipos de texto y medios" (LE08 OA03/09/10/11).
  Regla: **4 etapas + 1 jefe (5 nodos)**. Cada asignatura tiene, además, un
  **banco de año completo** (todos sus OA oficiales) como reserva para futuras
  expediciones (ver Sesión 9).
- Quiz: 6 preguntas al azar/etapa, timer 15 s, pasa con 66%, 3 estrellas. Al
  fallar revela la respuesta correcta + explicación y botón "Continuar". Kimün
  comenta un dato al iniciar la ruta.
- **Modo Difícil** desbloqueable (8 preguntas, 10 s, 80%, tema oscuro/carmesí).
- Persistencia (localStorage), tienda de skins, sonidos (Web Audio), animación
  de subida de nivel, logros, ranking (aún simulado).
- **Duelo 1v1:** en el mismo teléfono y **en línea asíncrono (Supabase)** con
  código de amigo, lista de jugadores, bots de práctica y reto de 24h.

**Contenido (bancos de año completo):** Historia **663 (revisadas 663/663;
22 OA)** · Matemáticas **518 (sin revisar; 17/17 OA)** · Ciencias **459 (sin
revisar; 15/15 OA)** · Lenguaje **443 (sin revisar; 15/15 OA)**. ~2.083 preguntas
en total. Las 3 asignaturas nuevas se llevaron a cobertura de año completo desde
el currículum oficial (ver Sesión 9); solo 4-5 OA de cada una están hoy en una
expedición jugable, el resto es reserva. **Herramientas dev:** tablero con clave
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

**Acceso integrado (Jugador / Admin):** la pantalla de inicio de `index.html`
ofrece dos modos. "Jugador" abre el juego (lo que ven los niños). "Modo Admin"
lleva al tablero, protegido por contraseña. La contraseña se define en la
constante `CLAVE_ADMIN` dentro de `scripts/generar-tablero.py`; al cambiarla hay
que volver a generar el tablero.

> Nota: es un **bloqueo suave** para que los niños no entren al panel, NO
> seguridad real (es un sitio estático; quien sepa mirar el código puede
> saltárselo).

**En el tablero:** al pinchar un OA se despliegan sus preguntas (solo el
enunciado y la respuesta correcta).

**Para probar en local** (el navegador necesita servidor, no `file://` para el
JavaScript): `python -m http.server 8765` y abrir `http://localhost:8765/`.

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

El **duelo 1v1 en línea** usa Supabase (proyecto en São Paulo). Esquema y funciones
en `supabase/schema.sql` (pegar en el SQL Editor). Requiere activar el **login
anónimo** en Authentication → Sign In / Providers.

- **Identidad sin contraseñas:** login anónimo → cada dispositivo es un usuario;
  perfil con `nombre`, `avatar` y **código de amigo** (`KIM-XXXX`).
- **Duelos:** se desafía desde una **lista de jugadores** (o por código). Contra
  **bots** (Vale/Nico/Fran/Diego) el resultado es **instantáneo**; contra
  **jugadores reales** es **asíncrono (24h)** y el puntaje del retador queda
  **oculto** hasta que el rival juega (funciones `SECURITY DEFINER`).
- **Seguridad:** RLS activo; a `duelos` solo se accede vía funciones RPC. La
  publishable key va en `index.html` (es pública por diseño; no es secreta).
- **Pendiente:** notificaciones push y ranking real (los datos ya se guardan).

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
