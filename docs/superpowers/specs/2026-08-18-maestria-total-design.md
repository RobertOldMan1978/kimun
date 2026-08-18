# Maestría Total — Diseño

**Fecha:** 2026-08-18
**Objetivo:** una recompensa cumbre por dominar los 4 jefes al máximo, con celebración épica
y cambios visuales permanentes, para incentivar el estudio.

## Hito
**Maestría Total** = completar Historia + Ciencias + Lenguaje **en Modo Difícil** (3 asignaturas)
**y** vencer a **El Autómata** (jefe del Reto de Cálculo). Son los 4 jefes conquistados al máximo.
`esMaestro()` = `asignaturasDificil().length >= 3 && S.calc.jefe`.

## Al lograrlo (al vencer al último, sea cual sea)
1. **Video de celebración** `assets/maestro.mp4` (10 s, zorro rey + música épica "Hero Down"
   de Kevin MacLeod, CC BY). Se reproduce **una vez** (flag `S.maestro`), con sonido (es tras
   una acción del usuario, el navegador lo permite), con botón "Saltar". Overlay `#maestroOverlay`.
2. **Skin "Kimün Maestro" 🏆** — su desbloqueo se mueve de 3 → los 4 (premio cumbre).
3. **Cambios visuales permanentes** mientras `esMaestro()` (clase `body.es-maestro`):
   - **Kimün compañero con aura dorada** (`#kimBuddy`, `#kimBuddyCalc`, `#resKim`).
   - **Avatar/HUD con halo dorado** (`.hud .avatar`).
   - **Marco dorado en el ranking** (`.rk.dif.d4`), superior a los bordes de 4 colores.

## Backend
Sin migración nueva. El conteo `dificil` que ya se sincroniza ahora **suma El Autómata**:
`p_n = asignaturasDificil().length + (S.calc.jefe?1:0)` → rango 0–4. El ranking pinta el
marco dorado si `dificil >= 4`; 1–3 mantienen el borde animado de 4 colores (intensidad).

## Cliente (`index.html`)
- Estado nuevo `S.maestro` (bool) en init/guardar/cargar.
- `esMaestro()`, `aplicarMaestria()` (toggle `body.es-maestro`), `revisarMaestria()` (otorga
  skin + video + aura la primera vez), integrados en `revisarDificil()`.
- `revisarDificil()`: mantiene las 3 insignias por asignatura; sincroniza el conteo 0–4;
  llama a `revisarMaestria()`. Se llama al pasar una etapa en Difícil y en `jefeCalcVictoria`.
- `aplicarMaestria()` al iniciar (aura persistente si ya es maestro).
- Ranking: clase `d`+min(4,dificil); `d4` = marco dorado.
- Créditos: atribución de "Hero Down".

## Fuera de alcance
- Sin tema dorado de menú (Roberto no lo pidió).
- El arte y música ya están (video listo con audio).
