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

## Bitácora de sesiones

### Sesión 1 (2026-08-12)
- Renombrado `aventura-historia.html` → `index.html`.
- Creados `CLAUDE.md` y `README.md`.
- Inicializado git y primer commit; conexión con repositorio GitHub y push a `main`.
- Configuración de GitHub Pages para obtener la URL pública.
- **Pendiente:** avanzar el roadmap desde el punto 1 (duelo 1v1).
