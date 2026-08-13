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

## Estado actual (v0)

Prototipo funcional en un solo archivo `index.html` (antes
`aventura-historia.html`), sin dependencias externas salvo Google Fonts.
Incluye:

- Selección de nombre y avatar.
- Mapa de 5 niveles desbloqueables (4 etapas + jefe final).
- Quiz con temporizador, opciones barajadas, partículas al acertar,
  combos x2/x3, vibración en error y retroalimentación educativa al fallar.
- Sistema de XP, subida de nivel, monedas y 1-3 estrellas por etapa.
- Logros con notificaciones (toasts) animadas y ranking de curso simulado.
- 16 preguntas reales de Historia de 8° básico.
- Estética de videojuego: fondo oscuro violeta; acentos dorado, cian, verde
  y rosa; fuentes Titan One + Nunito; diseño mobile-first.

**Nota:** todo el contenido y la lógica están embebidos en el HTML. Aún no se
separa el motor del contenido ni existe persistencia entre sesiones.

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
  hay una **plantilla** en `contenido/_plantilla/` para clonar la siguiente. Falta
  generar el contenido (OA + pool de preguntas) de Matemáticas / Ciencias /
  Lenguaje y activarlas.

## Reglas de trabajo

- Comunicación siempre en **español latino neutro** (ver instrucciones globales).
- No refactorizar el prototipo hasta que esté publicado tal cual.
- Flujo de trabajo entre oficina y casa sincronizando por **GitHub**.
- **Cierre de sesión:** al pedirlo, actualizar este `CLAUDE.md` con lo avanzado
  y lo pendiente, luego commit y push.

### Regla de commits (importante)

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
