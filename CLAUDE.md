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

1. **Duelo 1v1 en un mismo dispositivo** — dos jugadores por turnos en el
   mismo teléfono.
2. **Tienda de skins con monedas** — gastar las monedas ganadas en avatares
   o personalizaciones.
3. **Sonidos** — efectos de acierto, error, combo, subida de nivel y música
   de fondo opcional.
4. **Animación de subida de nivel** — celebración visual al subir de nivel.
5. **Separar contenido del motor** — mover las preguntas a archivos
   `JS/JSON` por asignatura, dejando el motor de juego genérico y reutilizable.
6. **Persistencia de progreso** — guardar XP, monedas, estrellas y logros
   (localStorage primero; backend más adelante).

### Más adelante (fuera del alcance inmediato)
- Login y multiusuario.
- Modelo de negocio.
- Múltiples asignaturas y niveles como expediciones independientes.

## Reglas de trabajo

- Comunicación siempre en **español latino neutro** (ver instrucciones globales).
- No refactorizar el prototipo hasta que esté publicado tal cual.
- Flujo de trabajo entre oficina y casa sincronizando por **GitHub**.
- **Cierre de sesión:** al pedirlo, actualizar este `CLAUDE.md` con lo avanzado
  y lo pendiente, luego commit y push.

### Regla de commits (importante)

- **Durante las sesiones NO se hace commit ni push** hasta que Roberto lo pida
  explícitamente. Claude debe esperar la orden.
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
