# Plantilla para una nueva expedición

Historia (`contenido/historia-8basico/`) es la **ruta base**. Para crear una
expedición nueva —otra asignatura u otra unidad— se clona este patrón y se
cambia **solo el contenido**. El motor del juego no se toca.

## Receta (3 pasos)

### 1) Crea la carpeta de contenido
Copia esta carpeta `_plantilla/` a `contenido/<tu-asignatura>/` y completa:

- **`oa.json`** — los Objetivos de Aprendizaje (código, eje, texto, conceptos).
- **`preguntas.json`** — el pool de preguntas. Cada una:
  `{ "id", "oa", "pregunta", "opciones":[4], "correcta":<índice 0-3>, "tip", "revisada":false }`

Puedes generarlas y verificarlas con el mismo flujo de Historia
(ver `scripts/consolidar-pool.py` y el tablero `dev/tablero.html`).

### 2) Agrega la portada
Una imagen cuadrada en `assets/portada-<asignatura>.png` (misma línea visual).

### 3) Registra la expedición en el motor
En `index.html`, dentro del arreglo **`EXPEDICIONES`**, agrega un objeto:

```js
{ id:'mate-fracciones', asignatura:'Matemáticas', nivel:'8° Básico · Fracciones',
  portada:'assets/portada-matematicas.png',
  contenido:'contenido/matematicas-8basico/preguntas.json',
  activa:true,
  etapas:[
    {oa:"MA08 OA 01", nombre:"Nombre de la etapa", icono:"➗", n:6},
    {oa:"MA08 OA 02", nombre:"Otra etapa",         icono:"🔢", n:6},
    // ...
    {oa:"BOSS", nombre:"⚡ JEFE FINAL", icono:"🐲", n:8,
     oas:["MA08 OA 01","MA08 OA 02"]},   // el jefe mezcla varios OA
  ]},
```

¡Listo! La expedición aparece jugable en la pantalla de "Expediciones", con su
propio **progreso independiente** (normal y difícil), la misma mecánica (6
preguntas al azar por etapa, 66% para pasar, Modo Difícil, etc.).

## Regla de estructura (acordada)
Toda expedición tiene **4 etapas + 1 jefe final** (5 nodos). Cada etapa mapea
**un OA**; el jefe mezcla los 4 OA de la ruta. (Historia y Ciencias siguen esta
regla.)

## Notas
- Cada etapa mapea **un OA**; el **jefe final** mezcla varios OA (campo `oas`).
- El campo `n` es cuántas preguntas saca la etapa en modo Normal (el Difícil usa 8, jefe 10).
- Mientras una expedición esté `activa:false`, aparece como "🔒 Pronto".
- El progreso se guarda por `id` de expedición, así que rutas distintas no se pisan.
