# Camino de aprendizaje de Matemáticas — Diseño

**Fecha:** 2026-08-21
**Estado:** Aprobado (brainstorming), pendiente de plan de implementación.

## Problema

Hoy Matemáticas **no enseña**: el módulo abre directo el **Reto de Cálculo**, un
entrenamiento de cálculo mental procedural (operaciones generadas al vuelo, opción
múltiple contra el reloj). No hay explicaciones, ni ejemplos, ni dibujos, ni banco
conceptual. El niño practica agilidad, pero nadie le enseñó el concepto antes.

Además, el currículum de Matemáticas de 8° está **cargado de contenido visual** que hoy
no vive en ninguna parte del juego: recta numérica, plano cartesiano, gráficos de
función lineal y afín, teorema de Pitágoras, transformaciones isométricas, prismas y
cilindros, diagramas de cajón, gráficos de barras, diagramas de árbol. Todo eso pide
**dibujo y manipulación**, no cálculo rápido.

Y como el Reto genera sus operaciones al vuelo (sin OA asociado), **Matemáticas no
aparece en el mapa de dominio** del profesor: es la única asignatura que el profesor no
puede medir.

## Objetivo

Crear un **camino de aprendizaje real** para Matemáticas —enseñanza con ejemplos
gráficos y dibujos interactivos, alineado al currículum— que cubra el **año completo
(17 OA, 4 unidades)**, **conservando** el Reto de Cálculo como camino de ejercicios.
El aprendizaje va primero; la práctica rápida es la recompensa.

## Decisiones tomadas (brainstorming)

1. **Forma de la lección: mezcla según el tema.** La lección adapta su formato al
   contenido: unos OA se manipulan (plano cartesiano, transformaciones), otros se
   explican (regla de signos, porcentajes). Esto exige una plantilla de lección
   flexible, no un formato único.
2. **Convivencia: aprender desbloquea el Reto.** Cada nivel del Reto de Cálculo se abre
   al completar la lección de su concepto. El Reto se conserva idéntico; solo cambia
   **cómo se abren** sus niveles.
3. **Alcance: año completo (4 unidades / 17 OA).** Matemáticas se vuelve una campaña
   como Historia/Ciencias/Lenguaje. Se construye como **motor de lecciones + contenido
   por unidad**, por fases, para no rehacer nada.
4. **Visuales: diagramas dibujados con código (SVG interactivo) + arte decorativo con
   imágenes de Roberto.** Los diagramas precisos (rectas, planos, triángulos, gráficos,
   árboles) se dibujan con SVG en el juego —exactos, livianos y manipulables—; el arte
   decorativo (Vulpi maestro, portadas) lo genera Roberto, como hasta ahora.
5. **Medición: sí, Matemáticas entra al mapa de dominio.** La práctica de cada lección
   registra primer intento por OA, reusando el pipeline existente. El Reto de Cálculo
   sigue sin medirse (genera al vuelo, sin OA).
6. **Arquitectura: motor de lecciones por bloques** (enfoque A, ver abajo).
7. **Jefe Final: villano nuevo para la campaña; El Autómata se queda en el Reto.** La
   campaña tiene su propio Jefe Final (villano nuevo que mezcla las 4 unidades) con skin
   e insignia nuevas, coherente con las otras tres asignaturas. El Autómata sigue siendo
   el clímax arcade del Reto de Cálculo.

## Enfoque elegido — A: Motor de lecciones por bloques

Descartados: **B** (baraja de tarjetas: mezcla peor los formatos, interactividad pegada
tarjeta por tarjeta) y **C** (plantilla HTML a medida por OA: no data-driven,
inmantenible con 17+ lecciones, rompe el patrón del proyecto).

El enfoque A es el único que entrega la "mezcla según el tema" + interactividad + escala
a 17 OA + encaja con el motor data-driven que ya usa VULPO.

## Arquitectura

### 1. Experiencia del alumno

Matemáticas deja de abrir directo el Reto. Al entrar, el niño ve la **campaña de
Matemáticas** (misma pantalla `scr-campana` que las otras asignaturas) con **4
capítulos = las 4 unidades del año**:

- **Cap 1 · Números** (OA01–05)
- **Cap 2 · Álgebra y funciones** (OA06–10)
- **Cap 3 · Geometría** (OA11–14)
- **Cap 4 · Probabilidad y estadística** (OA15–17)

Cada capítulo contiene **lecciones** (una por OA). Al tocar una lección se abre una
pantalla nueva `scr-leccion`: una **mini-clase guiada** donde el niño avanza con
"Continuar" por una secuencia de bloques cortos —explicación con dibujo, ejemplo
resuelto paso a paso, y al final **práctica** (2–3 preguntas del banco revisado)—. Al
completar la práctica, la lección queda ✓ y, donde corresponde, **desbloquea el nivel
del Reto de Cálculo** asociado. Completar todas las lecciones de un capítulo lo marca
terminado; al 100% se abre el **Jefe Final** de la campaña.

### 2. Motor de lecciones por bloques

Una lección es un objeto de datos con un arreglo de **bloques tipados** que el motor
recorre en orden:

```js
{ id:'ma-oa01', oa:'MA08 OA 01', titulo:'Multiplicar y dividir enteros',
  bloques:[
    {t:'texto',    md:'Cuando multiplicas dos números de igual signo…'},
    {t:'imagen',   src:'assets/mate/oa01-signos.png', alt:'Vulpi con la regla de signos'},
    {t:'diagrama', kind:'recta', params:{min:-6,max:6, marca:-3, interactivo:true}},
    {t:'ejemplo',  pasos:['(-4) · (-3)','Signos iguales → resultado +','= 12']},
    {t:'practica', fromBank:{oa:'MA08 OA 01', n:3}}
  ] }
```

Tipos de bloque:

- **`texto`** — explicación breve (una idea por pantalla).
- **`imagen`** — arte decorativo de Roberto (Vulpi maestro, ilustración de apoyo), con
  fallback si el archivo no está (patrón `onerror` ya usado en el proyecto).
- **`diagrama`** — invoca un widget del catálogo (sección 3) por `kind` + `params`. Aquí
  vive la interactividad.
- **`ejemplo`** — ejemplo resuelto que se revela paso a paso al tocar.
- **`práctica`** — lanza el motor de quiz existente con un flag `Q.leccion` (igual que se
  hizo `Q.desafio`), tomando `n` preguntas del banco por OA (`fromBank`) o preguntas
  propias. Es lo que **registra dominio**.

El motor (`scr-leccion` + `abrirLeccion` / `renderBloque` / `avanzarBloque`) es genérico
y **data-driven**: agregar una lección es agregar datos, nunca tocar el motor. Las
lecciones viven en un archivo nuevo `contenido/matematicas-8basico/lecciones.json`,
cargado con `fetch` como el resto del contenido.

### 3. Catálogo de diagramas interactivos

Un conjunto acotado de **~11 widgets SVG** cubre los 17 OA. Cada widget es una función
`DIAGRAMAS[kind](params, montaje)` que dibuja SVG inline (sin librerías externas,
temática VULPO, respeta el tema claro/oscuro con variables CSS) y engancha interacción
de arrastre donde aplica.

| Widget (`kind`) | Qué dibuja | Interacción | OA que sirve |
|---|---|---|---|
| `recta` | Recta numérica con marcas e intervalos (círculo abierto/cerrado) | Arrastrar el marcador | OA01, OA09 |
| `fracciones` | Barras/círculos partidos; multiplicar/dividir fracciones, % | Cambiar nº de partes | OA02, OA05 |
| `potencias` | Cuadrado/cubo (área y volumen), raíz como lado de un cuadrado | Cambiar exponente/lado | OA03, OA04 |
| `algebra` | Bloques de términos y balanza para ecuaciones | Quitar/agregar a ambos lados | OA06, OA08 |
| `plano` | Plano cartesiano con cuadrícula y puntos | Arrastrar un punto, leer (x,y) | base de OA07/10/13/14 |
| `funcion` | Recta f(x)=ax+b + tabla de valores sincronizada | Deslizadores de pendiente e intercepto | OA07, OA10 |
| `triangulo` | Triángulo rectángulo con cuadrados sobre catetos/hipotenusa (a²+b²=c²) | Arrastrar un vértice | OA12 |
| `transformacion` | Figura y su imagen tras traslación/rotación/reflexión | Mover el vector / elegir tipo | OA13, OA14 |
| `solido` | Prisma/cilindro y su red (desarrollo plano) desplegable | Desplegar la red | OA11 |
| `cajon` + `barras` | Diagrama de cajón (cuartiles); barras/circular con escala | Cambiar escala (ver distorsión) | OA15, OA16 |
| `arbol` | Diagrama de árbol / tabla de doble entrada | Agregar ramas, ver el conteo | OA17 |

Cada widget es autocontenido, liviano y se prueba de forma independiente (recibe
`params`, dibuja dentro del nodo de montaje, no depende del resto del juego).

### 4. Estructura de la campaña

Se agrega una entrada `'mate'` a `CAMPAÑAS`, con 4 capítulos = las 4 unidades. Los
capítulos de Matemáticas **agrupan lecciones** (no etapas de expedición), así que la
pantalla de campaña, al tocar un capítulo de Matemáticas, abre su **lista de lecciones**
en vez de un mapa de etapas. Es un ramal chico y localizado en el render de la campaña;
las otras tres asignaturas no se tocan.

**"Aprender desbloquea el Reto"** — mapeo lección → nivel del Reto (todos de la Unidad 1):

| Nivel del Reto | Se desbloquea al completar |
|---|---|
| 🔥 Calentamiento | disponible desde el inicio |
| ➖ Enteros | lección OA01 |
| √ Potencias y raíces | lecciones OA03 y OA04 |
| ½ Fracciones y % | lecciones OA02 y OA05 |
| ⚡ Reto Relámpago | todas las lecciones de Números |

El Reto de Cálculo (niveles, El Autómata, Modo Sin Fin) sigue existiendo tal cual; solo
cambia cómo se abren sus niveles. Los capítulos 2, 3 y 4 no tienen Reto que desbloquear:
sus lecciones terminan en su propia práctica.

**Jefe Final:** villano nuevo (nombre de trabajo **"La Incógnita"**, a confirmar cuando
Roberto genere el arte) que mezcla los OA de las 4 unidades por fase, como los otros
jefes. Estructura reusa `jefeFinal` de `CAMPAÑAS` (villano, diálogo, vidas, fases con
sus OA).

**Recompensa** (consistente con las otras campañas): skin exclusiva **"Vulpi
Matemático"** (`kimun-matematico`, nombre de trabajo) + insignia **"Maestro de las
Matemáticas"** (`maestro-matematica`) + corona + bono (+500🪙/+300XP), al vencer el Jefe
Final. Distintos de Vulpi Calculista / Maestro del Cálculo, que siguen siendo del Reto.

### 5. Medición y persistencia

- **Dominio:** cada bloque `práctica` llama a `registrarOA(oa, ok)` con el OA de la
  lección; al terminar la lección se dispara `enviarDominio()`. **Reusa `kimun_dominio`
  tal cual: cero backend nuevo.** El Jefe Final registra dominio por fase, como los
  otros. Hay que **quitar el aviso "Matemáticas no se mide"** de `profesor.html` (o
  ajustarlo: el Reto de Cálculo sigue sin medirse, pero el camino de aprendizaje sí).
- **Progreso:** estado nuevo `S.mateLecciones = {'ma-oa01':true, …}` (persistido en
  `guardar()`/`cargar()`). El desbloqueo de los niveles del Reto pasa a leer este estado
  en vez del "nivel anterior dominado". La campaña completa reusa el sistema
  `S.campañasCompletas` / recompensas que ya existe.
- **Migración cortés:** si un niño ya tenía niveles del Reto dominados, **no se le
  vuelven a bloquear** (los niveles ya abiertos/dominados en `S.calc` se respetan como
  abiertos). Nada de XP/monedas/skins se toca.

## Plan de construcción por fases

Así el "año completo" se construye incremental, sin rehacer:

1. **Motor de lecciones** — `scr-leccion`, `abrirLeccion`, render de bloques, flag
   `Q.leccion` en el quiz, carga de `lecciones.json`. Más los primeros widgets del
   catálogo que necesita el Cap 1.
2. **Cap 1 · Números** completo (5 lecciones OA01–05) + cableado del desbloqueo del Reto
   + entrada `'mate'` en `CAMPAÑAS` con el capítulo 1. **Rebanada vertical entregable y
   verificable de punta a punta.**
3. **Cap 2 · Álgebra y funciones** (widgets `algebra`, `funcion`, `plano`) — 5 lecciones.
4. **Cap 3 · Geometría** (widgets `triangulo`, `transformacion`, `solido`) — 4 lecciones.
5. **Cap 4 · Probabilidad y estadística** (widgets `cajon`, `barras`, `arbol`) — 3
   lecciones.
6. **Jefe Final de la campaña** (villano nuevo, mezcla de las 4 unidades) + recompensa
   (skin/insignia nuevas) + integración del arte de Roberto.

**Contenido de las lecciones:** el texto didáctico, los ejemplos resueltos y los
parámetros de cada diagrama los redacta Claude (con agentes) siguiendo el currículum; la
práctica reusa el banco de 603 preguntas ya revisadas por OA; Roberto revisa cada
unidad, como en el resto del proyecto.

## Qué NO cambia (fuera de alcance)

- El Reto de Cálculo por dentro (niveles, El Autómata, Modo Sin Fin): se conserva
  idéntico; solo cambia el gatillo de desbloqueo de sus niveles.
- Las otras tres campañas (Historia, Ciencias, Lenguaje): intactas.
- El duelo de Matemáticas (sigue usando los niveles del Reto generados al vuelo).
- **Modo Difícil para Matemáticas:** no se agrega. Matemáticas tiene su propia dificultad
  vía el Reto; la definición de "Maestría Total" (3 asignaturas en Difícil + El Autómata)
  no se toca.
- El backend: no se agregan tablas ni funciones. La medición reusa `kimun_dominio`.

## Riesgos y consideraciones

- **Volumen de contenido:** 17 lecciones didácticas + práctica es mucho contenido
  autorado. Mitigación: el plan por fases hace cada unidad un entregable independiente;
  la práctica reusa el banco existente.
- **Fidelidad matemática de los diagramas:** un diagrama con un error (una escala mal, un
  círculo abierto donde va cerrado) enseña mal. Cada widget se prueba de forma aislada
  con casos concretos antes de usarse en una lección.
- **Rendimiento en móvil:** SVG inline es liviano, pero varias lecciones con arrastre
  deben soltar sus listeners al salir de la pantalla (limpieza en `abrirLeccion` /
  cambio de pantalla) para no acumular handlers.
- **Coherencia del render de campaña:** el ramal de Matemáticas (capítulos = lecciones)
  debe quedar bien aislado para no ensuciar el render de las otras tres campañas.
