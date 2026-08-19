# Diseño · Corregir el significado del porcentaje (primer intento)

Fecha: 2026-08-18
Estado: aprobado por Roberto (pendiente de plan de implementación)

## Problema

El mapa de dominio muestra `correctas / respondidas` acumulado de todo el año. Ese número
tiene un defecto de fondo que ninguna mejora de presentación arregla: **el denominador
depende de lo que se quiere medir**. `respondidas` crece con los reintentos, y se reintenta
porque no se entendió, así que **el alumno que menos sabe pesa más en el promedio del
curso**.

Ejemplo con 30 alumnos en un objetivo: 24 pasan a la primera (6 respuestas, 5 correctas,
83%) y 6 reprueban y repiten cuatro veces (24 respuestas, 12 correctas, 50%).

| Forma de calcular | Resultado |
| --- | --- |
| Como hoy: suma de correctas / suma de respondidas | **66,7%** |
| Promedio de los porcentajes de cada alumno | **76,7%** |

Diez puntos de diferencia, y **la mitad de la base la aportó el 20% del curso**. El profesor
lee "66%, 288 preguntas" y cree tener una medición amplia; tiene la voz de seis niños
repetida cuatro veces.

Un segundo problema, independiente: con **cuatro opciones por pregunta, el piso no es 0%
sino 25%**. Un 45% en pantalla equivale a un dominio real de 27%, y la distancia entre 78% y
87% es menor de lo que aparenta.

Ambos hallazgos salieron de una revisión con tres miradas —docente, de datos y de
producto— sobre la herramienta recién construida.

## Decisiones tomadas

| Decisión | Elección |
| --- | --- |
| Qué número se muestra | **El acierto del primer intento**, con los reintentos como dato secundario |
| Cómo se trata el piso del azar | **Se ajustan los colores, no el número** |
| Qué pasa con lo ya acumulado | **Se descarta**: todo lo que hay hoy es de prueba |

Sobre la segunda: mostrar el número corregido por azar (27% donde ocurrió un 45%) es más
riguroso, pero deja de coincidir con algo que el profesor pueda verificar contando las
respuestas de un alumno, y eso mina la confianza en la herramienta. Se muestra lo que
ocurrió, y el color lleva la interpretación.

## Modelo de datos

Dos columnas nuevas en la tabla existente:

```sql
alter table public.dominio add column if not exists resp_1 int not null default 0;
alter table public.dominio add column if not exists ok_1   int not null default 0;
```

`kimun_dominio` las llena **solo en la rama `insert`** y no las toca en el
`on conflict do update`. Como la primera vez que un alumno responde un objetivo es
necesariamente una inserción, quedan congeladas en su primer contacto.

**Cómo se agrega a nivel de curso:** el porcentaje es `suma(ok_1) / suma(resp_1)` sobre los
alumnos del curso, y el conteo de alumnos que se muestra al lado es **cuántos tienen
`resp_1 > 0`** en ese objetivo, no cuántos existen en el curso. Es decir, cuántos aportaron
un primer intento: es el número que decide si el porcentaje es creíble.

**Cero filas nuevas, cero cambios en el juego**: `index.html` sigue enviando exactamente el
mismo resumen. El cambio vive entero en cuatro líneas de SQL.

## Lo que gana el profesor

Un número con un significado que puede decir en voz alta y defender: **"el 58% del curso
acertó la primera vez que vio este contenido"**. El anterior —"el curso está en 47% de un
total acumulado de intentos"— no es una frase que signifique algo.

Y un denominador parejo: como máximo 6 respuestas por alumno y objetivo, unas 180 por curso,
**la misma base para todos los objetivos**. Eso es lo que vuelve legítimo ordenar de peor a
mejor, que es la propuesta de valor de la herramienta.

Como subproducto sin costo, `respondidas - resp_1` pasa a ser una medida propia: **cuánto
costó**. Un objetivo con 62% al primer intento y pocos reintentos ("les costó pero lo
sacaron") pide algo muy distinto que uno con 62% y cuarenta reintentos ("se están
estrellando").

## Presentación

Cada fila muestra el porcentaje del primer intento, cuántos alumnos lo respaldan —dato que
ya viaja del servidor y hoy se descarta— y los reintentos:

```
Analizar la centralidad del ser humano…
████████░░░░  58%  ·  24 alumnos  ·  31 reintentos
```

**Colores calibrados al piso del azar:** rojo bajo 45%, ámbar entre 45% y 70%, verde sobre
70%. Con 25% de piso, un 50% no es "la mitad": es un tercio de dominio real, y el color debe
decirlo sin obligar al profesor a hacer cuentas. Una nota corta explica el piso.

**Tres bloques en lugar de la atenuación actual:**

| Bloque | Criterio |
| --- | --- |
| Para reforzar | 10 alumnos o más, bajo 70% |
| Van bien | 10 alumnos o más, 70% o más |
| Todavía con pocos datos | Menos de 10 alumnos · plegado |

Esto resuelve una contradicción del diseño anterior: ordenar de peor a mejor y a la vez
atenuar las bases pequeñas se peleaban entre sí. La posición es la señal de importancia más
fuerte de una lista, y la opacidad la contradecía, de modo que **lo que la tabla ponía
primero podía ser justo lo que pedía ignorar**. Con la base fuera del orden, arriba queda
solo lo accionable.

El umbral de 10 alumnos equivale a unas 60 respuestas de primer intento, que da un margen de
error cercano a ±12 puntos: ya es el borde de lo interpretable.

## Límites conocidos

- **Primer contacto en un jefe final.** Si un alumno toca un objetivo por primera vez durante
  un jefe —donde se mezclan objetivos y caen una o dos preguntas de cada uno—, su primer
  intento queda con base 1 o 2 en vez de 6. No se corrige: filtrarlo agregaría complejidad
  por un caso poco frecuente, y el agregado del curso lo diluye.
- **Los bancos de preguntas no están calibrados entre sí.** Los escribieron agentes distintos
  en tandas distintas, así que parte de la brecha entre un objetivo en 45% y otro en 87% es
  que un banco es más duro. Comparar un objetivo consigo mismo en el tiempo, o contra un
  umbral fijo, es defendible; **comparar objetivos entre sí lo es mucho menos**, y conviene
  no invitarlo desde la interfaz.
- **Sigue sin servir para calificar**, por lo mismo de siempre: el dato lo reporta el teléfono
  del alumno. El aviso se mantiene.
- **Matemáticas no se mide**, porque el Reto de Cálculo genera operaciones sin objetivo
  asociado. El panel debería decirlo, para que el silencio no se lea como "todo bien".

## Fuera de alcance

- Guardar historial por periodo para comparar antes y después de una clase.
- Estadística por ítem para calibrar los bancos.
- Pasar del objetivo a los nombres de los alumnos.
- Todas las mejoras de presentación que no sean las de este documento (encabezado, filtro por
  asignatura, texto acortado, resumen semanal). Están recogidas en los informes de la
  revisión y se abordarán aparte.

## Verificación

1. Un alumno juega un objetivo por primera vez con 4 de 6: `resp_1 = 6`, `ok_1 = 4`.
2. El mismo alumno repite esa etapa con 6 de 6: `respondidas = 12`, `correctas = 10`, y
   **`resp_1` y `ok_1` siguen en 6 y 4**. Es la comprobación central.
3. El panel muestra el porcentaje del primer intento, no el acumulado, y los reintentos
   aparte.
4. Un objetivo con menos de 10 alumnos cae al bloque plegado y no compite por el primer
   lugar.
5. Los colores cortan en 45% y 70%.
6. Aislamiento intacto: un profesor ajeno sigue recibiendo `no_autorizado`.
