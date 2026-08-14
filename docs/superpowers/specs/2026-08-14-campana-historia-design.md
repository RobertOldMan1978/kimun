# Diseño — Campaña "asignatura completa" (piloto: Historia 8°)

**Fecha:** 2026-08-14
**Estado:** aprobado (diseño) · pendiente de implementación
**Página de revisión:** https://claude.ai/code/artifact/0bebdc5a-986f-403e-8b97-b2346503beaa

## 1. Objetivo

Convertir "jugar una asignatura" de un conjunto de expediciones sueltas en una
**campaña con hilo conductor**: los OA de una asignatura, en orden, agrupados en
capítulos, con un **Desafío Extra** para los OA sobrantes, un **Jefe Final grande**
que se desbloquea al 100%, y **recompensas** por completar toda la asignatura.

Historia 8° (22 OA, 100% revisados) es el **piloto** que define la plantilla para
todas las demás.

## 2. Alcance

**Dentro (fase A + C):**
- Capa "Campaña" **data-driven** encima del motor actual (no se rompe lo publicado).
- Campaña completa de **Historia** como piloto (5 capítulos + Desafío Extra + Jefe Final).
- Sistemas nuevos: pantalla de campaña con desbloqueo secuencial; Jefe Final
  multi-fase con barra de vida; recompensas (skin exclusiva, insignias, corona, bono).
- Migración del progreso del piloto `hist-europeos`.

**Fuera (por ahora):**
- Generalizar la campaña a Matemática/Ciencias/Lengua (queda la plantilla lista; se
  hace después, es casi solo datos).
- "Modo lectura/escritura" (pasaje + preguntas encadenadas + producción escrita).
- Arte definitivo del villano y de la skin exclusiva (los genera Roberto; aquí van
  como marcadores).

## 3. Regla general (plantilla para todas las asignaturas)

Cortar los OA **en orden**, en grupos de 4 → cada grupo es un **capítulo**
(expedición de 4 etapas + jefe). Lo que sobra (1–3 OA) se junta en un **Desafío
Extra** (preguntas mezcladas, recompensa mayor). Cierra un **Jefe Final** que mezcla
todos los OA de la asignatura y se desbloquea al completar todo.

| Asignatura | OA | Capítulos | Desafío Extra |
|---|---|---|---|
| Historia | 22 | 5 (4·4 + 1·3) | OA 20–22 |
| Matemática | 17 | 4 (4·4) | OA 17 |
| Ciencias | 15 | 3 (3·4) | OA 13–15 |
| Lengua | 15 | 3 (3·4) | OA 13–15 |

## 4. Estructura de la campaña de Historia

| # | Capítulo | OA | Época / hilo | Nodos |
|---|---|---|---|---|
| 1 | Los inicios de la modernidad | HI08 OA 01–04 | Europa se moderniza (s. XV–XVI) | 4 etapas + jefe |
| 2 | Los europeos llegan a América | HI08 OA 05–08 | La conquista (conserva el nombre del piloto) | 4 etapas + jefe |
| 3 | El mundo colonial | HI08 OA 09–12 | Sociedad colonial, comercio, barroco | 4 etapas + jefe |
| 4 | Chile colonial y las nuevas ideas | HI08 OA 13–16 | Hacienda → Ilustración → independencia americana | 4 etapas + jefe |
| 5 | Independencia y ciudadanía | HI08 OA 17–19 | Legitimidad, derechos del hombre, independencia de Chile | 3 etapas + jefe |
| ⭐ | Desafío Extra: Chile hoy | HI08 OA 20–22 | Geografía: las regiones (capstone al presente) | especial, +recompensa |
| 👑 | Jefe Final de Historia | mezcla de los 22 OA | gran cierre | multi-fase |

El hilo conductor sigue el orden oficial del MINEDUC (así se enseña):
Europa se moderniza → conquista → mundo colonial → independencia → Chile hoy.

## 5. Modelo de datos (data-driven)

Arreglo nuevo `CAMPAÑAS`. Los **capítulos siguen siendo expediciones** (objetos de
`EXPEDICIONES`, 5 nodos), así que se reusa el motor actual (`activarExpedicion`,
`cargarPool`, `buildPreguntas`, `renderMapa`).

```js
const CAMPAÑAS = [{
  id:'hist', asignatura:'Historia', portada:'assets/portada-historia.png',
  capitulos:['hist-cap1','hist-cap2','hist-cap3','hist-cap4','hist-cap5'], // en orden
  desafioExtra:'hist-desafio',        // expedición especial (OA20-22 mezclados, +recompensa)
  jefeFinal:{ fases:[                  // 4 fases por época (mezclan todos los 22 OA)
    {nombre:'La modernidad',       oas:['HI08 OA 01','HI08 OA 02','HI08 OA 03','HI08 OA 04']},
    {nombre:'La conquista',        oas:['HI08 OA 05','HI08 OA 06','HI08 OA 07','HI08 OA 08']},
    {nombre:'El mundo colonial',   oas:['HI08 OA 09','HI08 OA 10','HI08 OA 11','HI08 OA 12','HI08 OA 13']},
    {nombre:'Independencia y Chile',oas:['HI08 OA 14','HI08 OA 15','HI08 OA 16','HI08 OA 17','HI08 OA 18','HI08 OA 19','HI08 OA 20','HI08 OA 21','HI08 OA 22']},
  ], nPorFase:4, vidasJugador:3 },
  recompensa:{ skin:'kimun-historiador', insignia:'maestro-historia' },
}];
```

Catálogos nuevos:
- `INSIGNIAS = [{id, ic, tx, asignatura}]` (p. ej. `{id:'maestro-historia', ic:'🏅', tx:'Maestro de Historia', asignatura:'Historia'}`).
- Skins exclusivas dentro del catálogo de skins actual, marcadas `bloqueada:true,
  desbloqueaCon:'hist'` (visibles en la tienda pero no comprables).

Estado nuevo en `S` (persistido en localStorage):
- `S.campañasCompletas` — Set de ids de campaña completadas.
- `S.insignias` — Set de insignias ganadas.
- `S.insigniaActiva` — id de la insignia que se luce junto al nombre (o null).

Se conservan intactos `S.xp/nivel/monedas/estrellas/skins/logros` y el progreso por
ruta en `S.rutas[<id>]`.

## 6. Pantalla de campaña y desbloqueo

**Nivel 1 — asignaturas.** Tarjeta por asignatura. La campaña completada muestra
**👑 corona dorada**. Tocar Historia abre su campaña; las asignaturas sin campaña
(por ahora, las otras 3) siguen mostrándose como expedición suelta (compatible).

**Nivel 2 — mapa de campaña.** Los capítulos en orden, el Desafío Extra y el Jefe
Final. Reusa la estética del mapa actual.

**Desbloqueo secuencial:**
- Capítulo 1: abierto de inicio.
- Capítulo N (N>1): se abre al vencer al jefe del capítulo N−1.
- Desafío Extra: se abre al completar el Capítulo 5.
- Jefe Final: se abre al **100%** (los 5 capítulos + el Desafío Extra completados).
- Los bloqueados muestran 🔒 con una pista de qué falta.

"Capítulo completado" = jefe del capítulo vencido en Normal (misma regla actual).

## 7. Jefe Final (pantalla nueva)

Variante del quiz. Reusa el render de preguntas y suma:
- **Barra de vida del jefe.** Baja con cada acierto. Vida total = `fases.length ×
  nPorFase` aciertos (ej. 4 fases × 4 = 16). Al vaciarla se vence.
- **Fases por época.** Se avanza fase por fase; cada fase saca `nPorFase` preguntas
  de sus `oas` (al azar, sin repetir). Indicador de fase (pips) y rótulo
  ("Fase 2 de 4 · La conquista"). Transición entre fases.
- **3 vidas del jugador (corazones).** Cada error quita una vida y el jefe
  "contraataca" (animación/sonido). Si llegan a 0 → derrota; se reintenta desde el
  inicio con preguntas nuevas.
- **Puesta en escena épica.** Pantalla de entrada con arte del villano, nombre y
  diálogo de apertura; sonido especial; animación de victoria al final.
- **Al vencer** → dispara las recompensas de la campaña (sección 8), marca
  `S.campañasCompletas.add('hist')`, guarda.

Timer: se mantiene el del modo (15 s Normal). El Jefe Final se juega en Normal;
el Modo Difícil de la campaña queda fuera de este spec (posible mejora futura).

Assets marcador (los define Roberto): villano ("El Guardián del Tiempo") y su diálogo.

## 8. Recompensas

- **Kimün exclusivo:** aparece en la **tienda, visible y bloqueado** ("🔒 Termina
  Historia"). No comprable. Al vencer al Jefe Final se agrega a `S.skins` y queda
  equipable.
- **Insignia coleccionable:** al completar, se agrega a `S.insignias`. Nueva vitrina
  de insignias (en perfil) con selector de `S.insigniaActiva`; la activa se muestra
  junto al nombre en el HUD y en el duelo.
- **Corona dorada:** en la tarjeta de la asignatura completada (Nivel 1).
- **Bono:** monedas + XP grandes al vencer al Jefe Final. El **Desafío Extra** aplica
  un multiplicador de monedas/XP mayor que una etapa normal.

## 9. Migración y compatibilidad

- **Lo global se preserva:** XP, nivel, monedas, estrellas, skins compradas y logros
  no se tocan (viven aparte del progreso por ruta).
- **Re-corte de Historia:** la ruta `hist-europeos` (OA04–07) se retira; su lugar lo
  toman los 5 capítulos con el mismo contenido de preguntas (fetch al mismo
  `preguntas.json`, solo cambia el agrupamiento de OA por etapa).
- **Cortesía:** al cargar, si existe `S.rutas['hist-europeos']` con el jefe vencido,
  pre-desbloquear el Capítulo 2 (conquista). Luego se puede limpiar la clave antigua.
- **Las otras 3 asignaturas quedan igual** (expediciones sueltas) hasta generalizar.

## 10. Verificación (en el navegador, como el flujo actual)

- El mapa de campaña renderiza; el desbloqueo secuencial funciona (simular completar
  un capítulo abre el siguiente).
- El Desafío Extra se abre tras el Capítulo 5; el Jefe Final se abre al 100%.
- El Jefe Final: la barra de vida baja con aciertos, respeta las 4 fases y los 3
  corazones; derrota y reintento correctos; victoria dispara recompensas.
- Recompensas: skin desbloqueada y equipable en la tienda; insignia agregada y
  seleccionable; corona en la tarjeta; bono aplicado.
- Migración: al cargar un guardado con `hist-europeos`, lo global se conserva y se
  aplica la cortesía del Capítulo 2.

## 11. Preguntas abiertas / dependencias

- **Assets de Roberto:** arte del villano del Jefe Final y arte de la skin exclusiva
  ("Kimün historiador"). Hasta tenerlos, se usan marcadores (emoji/placeholder).
- **Modo Difícil de la campaña:** fuera de alcance por ahora; se puede sumar luego.
- **Duelo:** la insignia activa se muestra también en el duelo (requiere leer
  `S.insigniaActiva` donde se pinta el nombre del jugador).
