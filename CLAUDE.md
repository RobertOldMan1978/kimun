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
- **Pantalla principal en 2 niveles (Sesión 15):** un **módulo por asignatura**
  (Historia, Matemáticas, Ciencias, Lenguaje); al entrar se abre su campaña o una
  lista de sus mapas (`scr-mapas`). Cada mapa usa su portada propia por convención
  `assets/portada-<id>.png` con fallback a la de la asignatura.
- **Campañas de asignatura completa (Historia y Ciencias):** cada una se juega como
  **campaña con hilo conductor** — capítulos en orden que cubren todos los OA del año +
  un **Jefe Final multi-fase** (barra de vida, 3 corazones, tema carmesí) que se abre al
  100%, con recompensas (skin exclusiva, insignia, corona y bono +500🪙/+300XP):
  - **Historia:** 5 capítulos (22 OA) + Desafío Extra; villano "El Guardián del Tiempo";
    skin "Kimün Historiador".
  - **Ciencias:** 4 capítulos (15 OA = las 4 unidades); villano "La Entropía";
    skin "Kimün Científico".
  Capa `CAMPAÑAS` data-driven; el motor de campañas es **genérico** (Desafío Extra
  opcional, jefe con título dinámico).
- **Matemáticas · "Reto de Cálculo" (Sesión 15):** al entrar a Matemáticas se abre un
  juego de **cálculo mental rápido** (procedural, alineado al eje Números de 8°), no el
  quiz de álgebra. **5 niveles × 3 etapas** + **Jefe Final "El Autómata"** (vida y
  corazones) + **Modo Sin Fin** con récord. El banco de álgebra queda de reserva y
  sigue en el Duelo.
- **Expediciones sueltas** (aún sin campaña): Lenguaje "Tipos de texto y medios"
  (LE08 OA03/09/10/11) y Lenguaje "Mundos literarios" (LE08 OA04-07). Regla de cada
  capítulo/expedición: **4 etapas + 1 jefe (5 nodos)**. Cada asignatura tiene, además,
  un **banco de año completo** (todos sus OA oficiales) como reserva (ver Sesión 9).
- Quiz: 6 preguntas al azar/etapa, timer 15 s, pasa con 66%, 3 estrellas. Al
  fallar revela la respuesta correcta + explicación y botón "Continuar". Kimün
  comenta un dato al iniciar la ruta.
- **Modo Difícil** desbloqueable (8 preguntas, 10 s, 80%, tema oscuro/carmesí).
- Persistencia (localStorage), tienda de skins, animación de subida de nivel,
  logros, ranking (aún simulado).
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
