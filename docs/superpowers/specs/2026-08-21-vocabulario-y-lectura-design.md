# Vocabulario y Lectura del colegio — Diseño

**Fecha:** 2026-08-21
**Objetivo:** dos módulos de estudio complementarios al plan: un **Vocabulario** transversal
(~100 palabras de todo el curso) y una **Lectura del colegio** (empezando por *El diario de
Ana Frank*), ambos como apoyo para las pruebas.

## Principio de derechos de autor (importante)
La Lectura **no reproduce el texto del libro**. El alumno lee el libro físico (edición Nube de
Tinta); el juego solo hace **preguntas de comprensión originales** sobre lo leído. Las preguntas
de vocabulario y de comprensión son de autoría propia (generadas con agentes), no extractos.

## Reutilización del motor
Ambos módulos reusan el **motor de quiz existente** (etapas, timer, estrellas, XP), sin tocarlo.
El quiz indexa preguntas por `POOL[oa]`; se usan **códigos de OA "de apoyo"** (no del currículum
oficial) para etiquetar las preguntas:
- Lectura Ana Frank: `AF-T1`…`AF-T8` (uno por tramo).
- Vocabulario: `VOC-HIST`, `VOC-CIEN`, `VOC-MATE`, `VOC-LENG`, `VOC-LECT` (por origen).
Cada módulo es una **expedición** (objeto de `EXPEDICIONES`) con esas etapas; se juega con
`activarExpedicion` → `scr-mapa`, igual que cualquier mapa. Quedan **fuera del mapa de dominio
por OA** (no son OA oficiales): `kimun_dominio` no debe registrarlos.

## Feature A — 📖 Lectura (biblioteca, módulo nuevo)
Pensado como **biblioteca extensible** (hoy 1 libro, luego más).
- **Módulo propio** en la pantalla principal (tarjeta "📖 Lectura", fuera de `ORDEN_ASIG`).
- Al entrar → pantalla **biblioteca** con la lista de libros (data-driven: arreglo `LIBROS`).
  Hoy: *El diario de Ana Frank*.
- Cada libro = **camino de ~6–8 tramos por período** (etapas). Tramos propuestos:
  1. Antes del escondite · 2. Los primeros meses en el anexo · 3. La convivencia y los roces ·
  4. El miedo, las bombas y el encierro · 5. Crecer y cambiar encerrada · 6. Peter y la amistad ·
  7. Esperanza y reflexión · 8. El final. (Se ajusta al escribir el contenido.)
- Cada tramo = etapa con ~6 preguntas de comprensión (`AF-T#`). Sin jefe final (es lectura, no
  campaña), o un "cierre" opcional que mezcla todo.
- Contenido: `contenido/lectura-anafrank/` con `preguntas.json` (preguntas `AF-T#`) y un
  `libro.json` con metadatos y la definición de tramos.
- Portada: `assets/portada-lectura-anafrank.png` (opcional; fallback a un color).

## Feature B — 📚 Vocabulario (dentro de Lenguaje)
- Al tocar el módulo **Lenguaje**, en vez de abrir directo la campaña, se muestra un pequeño
  **landing con dos caminos**: **Campaña** y **Vocabulario**.
- Vocabulario = **quiz de opción múltiple**, ~**100 palabras** sacadas de **todo lo enseñado**:
  las 4 asignaturas **+ los libros de lectura**. Formato: *"¿Qué significa \<palabra\>?"* con 4
  opciones (1 correcta + 3 distractores plausibles).
- **Etapas por origen** (≈20 c/u): Historia, Ciencias, Matemáticas, Lenguaje, Lecturas. Cada
  etapa 6–8 preguntas. Etapa de "repaso" mixta opcional como cierre.
- Contenido: `contenido/vocabulario/preguntas.json` (preguntas `VOC-*`).

## Generación de contenido (con agentes)
- **Vocabulario:** agentes extraen palabras clave desde los `oa.json`/`preguntas.json` de las 4
  asignaturas y desde las lecturas; para cada palabra: definición breve y clara para 8° básico +
  3 distractores. Meta ~100.
- **Ana Frank:** agentes generan preguntas de comprensión por tramo (conflicto, personajes,
  hechos, emociones, contexto histórico), **sin citar el texto**. ~8–10 por tramo.
- Todo nace `revisada:false`; Roberto aprueba con el flujo pedagógico existente (tablero /
  `aplicar-revisadas`). Se barajan las opciones (evitar sesgo de posición).

## Integración (data-driven, sin tocar el motor)
- `EXPEDICIONES`: una expedición para el libro de Ana Frank (etapas `AF-T#`) y una para
  Vocabulario (etapas `VOC-*`), con `contenido:` a sus `preguntas.json`.
- `renderExpediciones`: agregar la tarjeta del módulo **Lectura** (tras las 4 asignaturas) que
  abre la biblioteca; la biblioteca abre el libro con `activarExpedicion`.
- **Lenguaje:** su tarjeta abre un landing (`scr-leng` o similar) con "Campaña" y "Vocabulario";
  Vocabulario abre su expedición con `activarExpedicion`.
- `cargarPool` ya carga cualquier `preguntas.json`; el quiz funciona con los OA de apoyo.

## Fuera de alcance
- No hay lecciones/enseñanza (solo quiz); no se reproduce texto del libro; no alimenta el mapa
  de dominio por OA; no toca el rol de profesor.
- El arte de portadas es opcional (fallback si no existe).

## Verificación
- Menú: aparece el módulo Lectura y, dentro de Lenguaje, el acceso a Vocabulario.
- Se juega un tramo de Ana Frank y una etapa de Vocabulario (pool carga, quiz corre, estrellas/XP).
- Las preguntas no contienen texto del libro; todas `revisada:false` hasta aprobación.
- Sin errores de consola; el resto del juego intacto.
