# Expedición para Matemáticas (Opción B)

**Fecha:** 2026-08-22
**Estado:** Diseño aprobado, pendiente de plan de implementación

## Contexto

Matemáticas es hoy la única asignatura sin capa de expedición. Su campaña
(`esLecciones:true`) ofrece lecciones (teoría + práctica) + Reto de Cálculo +
Jefe Final "La Incógnita". Consecuencia: el banco de 603 preguntas
(`contenido/matematicas-8basico/preguntas.json`, 17 OA) queda casi sin uso —solo
la práctica de lección (10 preguntas) y el jefe final— y el niño siente que
Matemáticas "juega distinto" al resto.

Historia, Ciencias y Lenguaje comparten el motor de expedición (etapas por OA +
BOSS + quiz, con Modo Normal/Difícil). Ese motor ya existe y es reutilizable
(`activarExpedicion`, `entrarExpedicion`, `cargarPool`, `renderMapa`, quiz).

Objetivo: darle a Matemáticas una expedición usando el banco de 603, **sin
quitar** el Reto de Cálculo, con el flujo "enseñanza (lecciones) antes del
desafío (expedición + jefes)".

## Decisiones tomadas

1. **Estructura por unidad: enseña → desafío.** Dentro de cada unidad se juegan
   las lecciones; al terminarlas se desbloquea la expedición (quiz por OA + jefe
   de capítulo) de esa misma unidad.
2. **Jefe Final "La Incógnita"** se desbloquea al vencer **las 4 expediciones**
   (que a su vez exigen sus lecciones → aprender todo antes del jefe).
3. **Modo Difícil: paridad total.** Las 4 expediciones se juegan también en
   Difícil, con insignia 🔥 `dif-matematicas` propia.
4. **Maestría Total sin cambios.** Sigue siendo Historia + Ciencias + Lenguaje en
   Difícil + El Autómata. La insignia de Mate en Difícil es un premio extra que
   NO altera el requisito ni el video/skin de cumbre.

## Modelo de datos

### Nuevas expediciones en `EXPEDICIONES`

Cuatro objetos nuevos, campaña `mate`, `contenido:'contenido/matematicas-8basico/preguntas.json'`,
`activa:true`. Etapas = un OA por etapa (n:6) + un BOSS final (n:8) que agrupa
los OA de la unidad. Reutilizan assets existentes.

| id | Unidad | Etapas OA | Portada / mapa | Jefe (img) |
|---|---|---|---|---|
| `mate-exp-numeros`   | Números    | MA08 OA 01-05 | `portada-mate-numeros.png`   | `villano-matematicas.png` |
| `mate-exp-algebra`   | Álgebra    | MA08 OA 06-10 | `portada-mate-algebra.png`   | `villano-matematicas.png` |
| `mate-exp-geometria` | Geometría  | MA08 OA 11-14 | `portada-mate-geometria.png` | `villano-matematicas.png` |
| `mate-exp-datos`     | Datos y azar | MA08 OA 15-17 | `portada-mate-datos.png`   | `villano-matematicas.png` |

Nombres/íconos de etapa: reutilizar los títulos de las lecciones/unidad ya
existentes para mantener coherencia (p. ej. "Lenguaje algebraico", "Ecuaciones",
etc.). El BOSS de cada expedición lleva `oas:[...los OA de la unidad]`.

Banco suficiente: cada OA de Mate tiene ≥30 preguntas (OA06 = 89). Alcanza para
etapas (6) + jefe (8) + práctica de lección (10) sin quedarse corto.

### Campaña `mate` en `CAMPAÑAS`

- Poblar `capitulos: ['mate-exp-numeros','mate-exp-algebra','mate-exp-geometria','mate-exp-datos']`
  (hoy es `[]`). Esto habilita el motor genérico de Difícil / jefe final /
  desbloqueos para Mate.
- Mantener `capitulosMate` (lecciones), `esLecciones:true`, `jefeFinal`
  (La Incógnita) tal cual.

## Mapa de la campaña (`renderCampañaMate`)

Pasar de "4 unidades + Reto + Jefe" a un mapa **intercalado**:

```
Unidad 1 · Números (lecciones)   → Expedición Números   (🔒 hasta terminar sus lecciones)
Unidad 2 · Álgebra (lecciones)   → Expedición Álgebra   (🔒 …)
Unidad 3 · Geometría (lecciones) → Expedición Geometría (🔒 …)
Unidad 4 · Datos (lecciones)     → Expedición Datos     (🔒 …)
Reto de Cálculo                  (sin cambios)
Jefe Final "La Incógnita"        (🔒 hasta vencer las 4 expediciones)
```

Cada nodo de lección abre `abrirCapituloMate(cap)` (como hoy). Cada nodo de
expedición abre `entrarExpedicion(exp)` (motor existente). Se reutiliza
`nodoCampañaEl` para pintar ambos.

## Lógica de desbloqueo

- **Expedición de la unidad i:** abierta si `capMateCompleto(unidad_i)` (sus
  lecciones están completas).
- **Lecciones de la unidad i+1:** abiertas si las lecciones de la unidad i están
  completas (regla actual, no se endurece: no bloquea seguir aprendiendo aunque
  no hayas vencido la expedición i).
- **Jefe Final:** abierto si las 4 expediciones están completas en Normal
  (`camp.capitulos.every(expedicionCompleta)`), reemplazando el gate actual por
  lecciones. Nueva función `jefeFinalMateDesbloqueado(c)`.

## Modo Difícil e insignia

- El motor ya soporta Difícil (`nPreguntas`, `tiempoInicial`, `progresoDificil`
  por ruta): las expediciones de Mate lo heredan sin cambios de motor.
- Nueva insignia `dif-matematicas` (🔥 "Matemáticas · Difícil") en `INSIGNIAS` y
  entrada en `LOGROS`, otorgada al completar las 4 expediciones de Mate en
  Difícil.
- **Sin tocar `esMaestro()`:** `DIF_ASIGS` se mantiene en los 3 nombrados
  (Historia, Ciencias, Lenguaje) para que la Maestría no cambie de significado.
  La insignia `dif-matematicas` se otorga con un chequeo propio en
  `revisarDificil` (usando `asignaturaDificilCompleta('Matemáticas')`, que ya
  funciona genéricamente vía `CAMPAÑAS` + `capitulos`), fuera del bucle de los 3
  core, de modo que NO alimente `asignaturasDificil()` ni la Maestría.

## Lo que NO cambia

- Reto de Cálculo, El Autómata, Sin Fin: intactos (incluidos los tiempos
  recién ajustados: 20 s fijos, jefe 15 s).
- Lecciones y su práctica de 10 preguntas: intactas.
- Jefe Final La Incógnita (fases, banco vía `cargarPoolMate`): intacto salvo su
  gate de desbloqueo.
- Persistencia: las expediciones usan `S.rutas[exp.id]` como las demás; no hay
  migración de saves (las rutas nuevas nacen vacías).

## Efecto colateral positivo

Las expediciones registran OA reales (`MA08 OA *`) vía `registrarOA`, así que
Matemáticas **pasa a alimentar el mapa de dominio del profesor** (hoy solo lo
hacían las lecciones). Coherente y deseado. (Vocabulario/Lectura siguen excluidos
por el guard de OA de apoyo `VOC-/AF-`.)

## Riesgos y cuidados

- `asignaturaDificilCompleta` tiene un guard: "una campaña con `capitulos:[]`
  (Matemáticas) no cuenta para Difícil". Al poblar `capitulos`, Mate empieza a
  contar; por eso la Maestría se fija a los 3 nombrados explícitamente (ver
  arriba) para no inflar el requisito.
- Es la feature más grande de la sesión: toca `EXPEDICIONES`, `CAMPAÑAS`,
  `renderCampañaMate`, `INSIGNIAS`, `LOGROS`, `revisarDificil`. Todo aditivo; el
  riesgo se concentra en los desbloqueos.
- Sin arte nuevo: todos los assets ya existen.

## Verificación (navegador)

1. Campaña Matemáticas muestra el mapa intercalado (lección → expedición ×4 +
   Reto + Jefe).
2. La expedición de una unidad está 🔒 hasta completar sus lecciones; al
   completarlas, se abre.
3. Jugar una expedición en Normal la marca como completa; el Jefe Final se
   mantiene 🔒 hasta las 4.
4. Con `?qa=1` (desbloquea todo) verificar que el Jefe Final arranca y toma
   preguntas del banco de 603.
5. Difícil: la expedición se puede jugar en Difícil; al completar las 4 en
   Difícil se otorga `dif-matematicas` y la Maestría NO se dispara solo por eso.
6. Sin errores de consola; el mapa de dominio recibe OA `MA08 OA *` tras jugar.
